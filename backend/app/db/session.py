# from collections.abc import Generator

# from sqlalchemy import create_engine
# from sqlalchemy.orm import Session, sessionmaker

# from app.core.config import settings
# from app.db.base import Base

# connect_args: dict[str, object] = {}
# if settings.database_url.startswith("sqlite"):
#     connect_args["check_same_thread"] = False

# engine = create_engine(
#     settings.database_url,
#     connect_args=connect_args,
#     pool_pre_ping=True,
# )
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# def get_db() -> Generator[Session]:
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()


# def init_db() -> None:
#     from app.db import models  # noqa: F401

#     Base.metadata.create_all(bind=engine)
#     _migrate_add_password_column(engine)


# def _migrate_add_password_column(engine) -> None:
#     """Add password column to students table if missing (SQLite compat)."""
#     from sqlalchemy import inspect, text

#     if not engine.dialect.name.startswith("sqlite"):
#         return

#     inspector = inspect(engine)
#     columns = {col["name"] for col in inspector.get_columns("students")}
#     if "password" not in columns:
#         with engine.connect() as conn:
#             conn.execute(text("ALTER TABLE students ADD COLUMN password VARCHAR(255)"))
#             conn.commit()


from collections.abc import Generator
from typing import Any

from sqlalchemy import create_engine, event, inspect, text
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import NullPool, QueuePool

from app.core.config import settings
from app.db.base import Base

connect_args: dict[str, object] = {}
if settings.database_url.startswith("sqlite"):
    connect_args["check_same_thread"] = False
    poolclass = NullPool
else:
    poolclass = QueuePool

engine_kwargs: dict[str, Any] = {
    "connect_args": connect_args,
    "pool_pre_ping": True,
    "poolclass": poolclass,
    "pool_recycle": 3600,
    "echo": settings.debug,
}
if poolclass is not NullPool:
    engine_kwargs["pool_size"] = 20 if settings.environment == "production" else 5
    engine_kwargs["max_overflow"] = 40 if settings.environment == "production" else 10
    engine_kwargs["pool_timeout"] = 30

engine = create_engine(
    settings.database_url,
    **engine_kwargs
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn: object, connection_record: object) -> None:
    """Configure database connection on connect."""
    if not settings.database_url.startswith("sqlite"):
        try:
            dbapi_conn.isolation_level
        except AttributeError:
            pass


def get_db() -> Generator[Session]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    from app.db import models  # noqa: F401 — registers all models with Base

    # create_all is idempotent — safe to call on every startup
    Base.metadata.create_all(bind=engine)

    # Run schema migrations for all dialects (PostgreSQL on Render, SQLite locally)
    _migrate_schema(engine)

    # Seed curriculum data if empty
    from app.db.seed_curriculum import seed_curriculum

    with SessionLocal() as db:
        count = seed_curriculum(db)
        if count:
            print(f"[seed] Inserted {count} curriculum entries")
        db.close()


def _migrate_schema(engine):
    """Add missing columns and constraints to existing tables (non-destructive, dialect-aware)."""
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    is_sqlite = engine.dialect.name.startswith("sqlite")

    with engine.connect() as conn:
        # students.password (pre-auth records)
        if "students" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("students")}
            if "password" not in cols:
                conn.execute(text("ALTER TABLE students ADD COLUMN password VARCHAR(255)"))
                conn.commit()

        # exams.class_level (added after initial schema creation)
        if "exams" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("exams")}
            if "class_level" not in cols:
                conn.execute(text("ALTER TABLE exams ADD COLUMN class_level VARCHAR(50)"))
                conn.commit()

        # curriculum_topics.chapter / chapter_number (added for chapter/topic hierarchy)
        if "curriculum_topics" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("curriculum_topics")}
            if "chapter" not in cols:
                conn.execute(text("ALTER TABLE curriculum_topics ADD COLUMN chapter VARCHAR(150) DEFAULT 'General'"))
                conn.commit()
            if "chapter_number" not in cols:
                conn.execute(text("ALTER TABLE curriculum_topics ADD COLUMN chapter_number INTEGER"))
                conn.commit()

            # If the table contains data for classes other than 8 or subjects other than
            # science, clear it so seed_curriculum can re-seed with the correct subset.
            result = conn.execute(text(
                "SELECT COUNT(*) FROM curriculum_topics WHERE class_level != '8' OR LOWER(subject) != 'science'"
            )).fetchone()
            if result and result[0] > 0:
                conn.execute(text("DELETE FROM curriculum_topics"))
                conn.commit()

        # topic_performance.subject + unique constraint migration
        if "topic_performance" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("topic_performance")}
            if "subject" not in cols:
                conn.execute(text("ALTER TABLE topic_performance ADD COLUMN subject VARCHAR(100) DEFAULT 'General'"))
                conn.commit()
                # Populate subject from most recent Attempt + Exam for each student
                conn.execute(text("""
                    UPDATE topic_performance
                    SET subject = COALESCE((
                        SELECT e.subject
                        FROM attempts a
                        JOIN exams e ON e.id = a.exam_id
                        WHERE a.student_id = topic_performance.student_id
                        ORDER BY a.created_at DESC
                        LIMIT 1
                    ), 'General')
                """))
                conn.commit()

                if is_sqlite:
                    # SQLite: recreate table (cannot drop constraints)
                    conn.execute(text("""
                        CREATE TABLE topic_performance_new (
                            id INTEGER NOT NULL PRIMARY KEY,
                            student_id INTEGER NOT NULL,
                            subject VARCHAR(100) NOT NULL DEFAULT 'General',
                            topic VARCHAR(150) NOT NULL,
                            attempts_count INTEGER NOT NULL DEFAULT 0,
                            average_score FLOAT NOT NULL DEFAULT 0.0,
                            consistency_score FLOAT NOT NULL DEFAULT 0.0,
                            last_score FLOAT NOT NULL DEFAULT 0.0,
                            updated_at DATETIME,
                            CONSTRAINT uq_topic_performance_student_subject_topic UNIQUE (student_id, subject, topic)
                        )
                    """))
                    conn.commit()
                    conn.execute(text("""
                        INSERT INTO topic_performance_new
                        (id, student_id, subject, topic, attempts_count, average_score, consistency_score, last_score, updated_at)
                        SELECT id, student_id, subject, topic, attempts_count, average_score, consistency_score, last_score, updated_at
                        FROM topic_performance
                    """))
                    conn.commit()
                    conn.execute(text("DROP TABLE topic_performance"))
                    conn.commit()
                    conn.execute(text("ALTER TABLE topic_performance_new RENAME TO topic_performance"))
                    conn.commit()
                    conn.execute(text("CREATE INDEX ix_topic_performance_student_id ON topic_performance (student_id)"))
                    conn.commit()
                else:
                    # PostgreSQL: drop old constraint if present, add new one if absent
                    conn.execute(text(
                        "ALTER TABLE topic_performance DROP CONSTRAINT IF EXISTS uq_topic_performance_student_topic"
                    ))
                    conn.commit()
                    result = conn.execute(text(
                        "SELECT 1 FROM pg_constraint WHERE conname = 'uq_topic_performance_student_subject_topic'"
                    )).fetchone()
                    if not result:
                        conn.execute(text(
                            "ALTER TABLE topic_performance ADD CONSTRAINT uq_topic_performance_student_subject_topic "
                            "UNIQUE (student_id, subject, topic)"
                        ))
                        conn.commit()


def close_db() -> None:
    """Close database connections gracefully."""
    engine.dispose()
