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

<<<<<<< Updated upstream
from sqlalchemy import create_engine, inspect, text
=======
from sqlalchemy import create_engine, event
>>>>>>> Stashed changes
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

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
    pool_pre_ping=True,
    poolclass=poolclass,
    pool_size=20 if settings.environment == "production" else 5,
    max_overflow=40 if settings.environment == "production" else 10,
    pool_recycle=3600,
    pool_timeout=30,
    echo=settings.debug,
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

<<<<<<< Updated upstream
    # SQLite-specific column migrations for tables that existed before new models
    if engine.dialect.name.startswith("sqlite"):
        _sqlite_migrate(engine)


def _sqlite_migrate(engine) -> None:
    """Add missing columns to existing SQLite tables (non-destructive)."""
    inspector = inspect(engine)
    existing_tables = {t for t in inspector.get_table_names()}

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

        # topic_performance.subject (added for per-subject tracking)
        if "topic_performance" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("topic_performance")}
            if "subject" not in cols:
                conn.execute(text("ALTER TABLE topic_performance ADD COLUMN subject VARCHAR(100) DEFAULT 'General'"))
                conn.commit()
                # Populate subject from most recent Attempt + Exam for each (student_id, topic)
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
                # Recreate table with new unique constraint (SQLite cannot drop constraints)
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
=======

def close_db() -> None:
    """Close database connections gracefully."""
    engine.dispose()
>>>>>>> Stashed changes
