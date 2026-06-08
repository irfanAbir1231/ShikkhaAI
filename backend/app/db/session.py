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


import logging
from collections.abc import Generator
from typing import Any

from sqlalchemy import create_engine, event, inspect, text

logger = logging.getLogger("shikkhaai")
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
    from app.db.seed_curriculum import seed_curriculum, seed_subtopics

    with SessionLocal() as db:
        count = seed_curriculum(db)
        if count:
            logger.info("[seed] Inserted %d curriculum entries", count)
        else:
            logger.info("[seed] Curriculum table already seeded correctly")

        subtopic_count = seed_subtopics(db)
        if subtopic_count:
            logger.info("[seed] Inserted %d subtopic entries", subtopic_count)
        else:
            logger.info("[seed] Subtopics already seeded correctly")
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
                logger.info("[migrate] Added chapter column to curriculum_topics")
            if "chapter_number" not in cols:
                conn.execute(text("ALTER TABLE curriculum_topics ADD COLUMN chapter_number INTEGER"))
                conn.commit()
                logger.info("[migrate] Added chapter_number column to curriculum_topics")

            # If the table contains data for classes other than 8 or subjects other than
            # science, clear it so seed_curriculum can re-seed with the correct subset.
            result = conn.execute(text(
                "SELECT COUNT(*) FROM curriculum_topics WHERE class_level != '8' OR LOWER(subject) != 'science'"
            )).fetchone()
            if result and result[0] > 0:
                logger.info("[migrate] Clearing %d old curriculum rows", result[0])
                conn.execute(text("DELETE FROM curriculum_topics"))
                conn.commit()
            else:
                row_count = conn.execute(text("SELECT COUNT(*) FROM curriculum_topics")).fetchone()
                logger.info("[migrate] curriculum_topics has %d rows (no stale data found)", row_count[0] if row_count else 0)

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

        # attempts.weak_subtopics / generated_notes (persisted submit-time data)
        if "attempts" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("attempts")}
            col_types = {c["name"]: str(c.get("type", "")).lower() for c in inspector.get_columns("attempts")}

            # Add missing columns as JSON (PostgreSQL) / TEXT (SQLite)
            json_type = "JSON" if not is_sqlite else "TEXT"
            json_default = "'[]'::json" if not is_sqlite else "'[]'"

            if "weak_subtopics" not in cols:
                conn.execute(text(f"ALTER TABLE attempts ADD COLUMN weak_subtopics {json_type} DEFAULT {json_default}"))
                conn.commit()
                logger.info("[migrate] Added weak_subtopics column to attempts")
            elif not is_sqlite and col_types.get("weak_subtopics", "") == "text":
                # Migrate existing TEXT column to JSON
                conn.execute(text("ALTER TABLE attempts ALTER COLUMN weak_subtopics TYPE JSON USING weak_subtopics::JSON"))
                conn.commit()
                logger.info("[migrate] Migrated weak_subtopics from TEXT to JSON")

            if "generated_notes" not in cols:
                conn.execute(text(f"ALTER TABLE attempts ADD COLUMN generated_notes {json_type} DEFAULT {json_default}"))
                conn.commit()
                logger.info("[migrate] Added generated_notes column to attempts")
            elif not is_sqlite and col_types.get("generated_notes", "") == "text":
                # Migrate existing TEXT column to JSON
                conn.execute(text("ALTER TABLE attempts ALTER COLUMN generated_notes TYPE JSON USING generated_notes::JSON"))
                conn.commit()
                logger.info("[migrate] Migrated generated_notes from TEXT to JSON")

        # spaces.class_level (added after initial schema creation)
        if "spaces" in existing_tables:
            cols = {c["name"] for c in inspector.get_columns("spaces")}
            if "class_level" not in cols:
                conn.execute(text("ALTER TABLE spaces ADD COLUMN class_level VARCHAR(50)"))
                conn.commit()
                logger.info("[migrate] Added class_level column to spaces")

        # Create new tables if they don't exist (non-destructive)
        _create_new_tables(conn, inspector, is_sqlite)


def _create_new_tables(conn, inspector, is_sqlite):
    """Create new subtopic and note versioning tables if they don't exist."""
    existing_tables = set(inspector.get_table_names())

    if "subtopics" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE subtopics (
                id INTEGER NOT NULL PRIMARY KEY,
                curriculum_topic_id INTEGER NOT NULL,
                name VARCHAR(150) NOT NULL,
                summary TEXT,
                display_order INTEGER NOT NULL DEFAULT 0,
                created_at DATETIME,
                CONSTRAINT uq_subtopic_curriculum_name UNIQUE (curriculum_topic_id, name)
            )
        """ if is_sqlite else """
            CREATE TABLE subtopics (
                id SERIAL PRIMARY KEY,
                curriculum_topic_id INTEGER NOT NULL,
                name VARCHAR(150) NOT NULL,
                summary TEXT,
                display_order INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT uq_subtopic_curriculum_name UNIQUE (curriculum_topic_id, name)
            )
        """))
        conn.execute(text("CREATE INDEX ix_subtopics_curriculum_topic_id ON subtopics (curriculum_topic_id)"))
        conn.commit()
        logger.info("[migrate] Created subtopics table")

    if "subtopic_performance" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE subtopic_performance (
                id INTEGER NOT NULL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                subtopic_id INTEGER NOT NULL,
                subject VARCHAR(100) NOT NULL DEFAULT 'General',
                attempts_count INTEGER NOT NULL DEFAULT 0,
                average_score FLOAT NOT NULL DEFAULT 0.0,
                consistency_score FLOAT NOT NULL DEFAULT 0.0,
                last_score FLOAT NOT NULL DEFAULT 0.0,
                updated_at DATETIME,
                CONSTRAINT uq_subtopic_performance_student_subtopic UNIQUE (student_id, subtopic_id)
            )
        """ if is_sqlite else """
            CREATE TABLE subtopic_performance (
                id SERIAL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                subtopic_id INTEGER NOT NULL,
                subject VARCHAR(100) NOT NULL DEFAULT 'General',
                attempts_count INTEGER NOT NULL DEFAULT 0,
                average_score FLOAT NOT NULL DEFAULT 0.0,
                consistency_score FLOAT NOT NULL DEFAULT 0.0,
                last_score FLOAT NOT NULL DEFAULT 0.0,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT uq_subtopic_performance_student_subtopic UNIQUE (student_id, subtopic_id)
            )
        """))
        conn.execute(text("CREATE INDEX ix_subtopic_performance_student_id ON subtopic_performance (student_id)"))
        conn.execute(text("CREATE INDEX ix_subtopic_performance_subtopic_id ON subtopic_performance (subtopic_id)"))
        conn.commit()
        logger.info("[migrate] Created subtopic_performance table")

    if "note_versions" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE note_versions (
                id INTEGER NOT NULL PRIMARY KEY,
                note_id INTEGER NOT NULL,
                version INTEGER NOT NULL DEFAULT 1,
                content TEXT NOT NULL,
                generated_at DATETIME
            )
        """ if is_sqlite else """
            CREATE TABLE note_versions (
                id SERIAL PRIMARY KEY,
                note_id INTEGER NOT NULL,
                version INTEGER NOT NULL DEFAULT 1,
                content TEXT NOT NULL,
                generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """))
        conn.execute(text("CREATE INDEX ix_note_versions_note_id ON note_versions (note_id)"))
        conn.commit()
        logger.info("[migrate] Created note_versions table")

    if "saved_notes" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE saved_notes (
                id INTEGER NOT NULL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                note_id INTEGER NOT NULL,
                bookmarked INTEGER NOT NULL DEFAULT 0,
                saved_at DATETIME,
                CONSTRAINT uq_saved_note_student_note UNIQUE (student_id, note_id)
            )
        """ if is_sqlite else """
            CREATE TABLE saved_notes (
                id SERIAL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                note_id INTEGER NOT NULL,
                bookmarked BOOLEAN NOT NULL DEFAULT FALSE,
                saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT uq_saved_note_student_note UNIQUE (student_id, note_id)
            )
        """))
        conn.execute(text("CREATE INDEX ix_saved_notes_student_id ON saved_notes (student_id)"))
        conn.execute(text("CREATE INDEX ix_saved_notes_note_id ON saved_notes (note_id)"))
        conn.commit()
        logger.info("[migrate] Created saved_notes table")

    if "saved_exams" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE saved_exams (
                id INTEGER NOT NULL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                exam_id INTEGER NOT NULL,
                bookmarked INTEGER NOT NULL DEFAULT 0,
                saved_at DATETIME,
                CONSTRAINT uq_saved_exam_student_exam UNIQUE (student_id, exam_id)
            )
        """ if is_sqlite else """
            CREATE TABLE saved_exams (
                id SERIAL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                exam_id INTEGER NOT NULL,
                bookmarked BOOLEAN NOT NULL DEFAULT FALSE,
                saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT uq_saved_exam_student_exam UNIQUE (student_id, exam_id)
            )
        """))
        conn.execute(text("CREATE INDEX ix_saved_exams_student_id ON saved_exams (student_id)"))
        conn.execute(text("CREATE INDEX ix_saved_exams_exam_id ON saved_exams (exam_id)"))
        conn.commit()
        logger.info("[migrate] Created saved_exams table")

    if "spaces" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE spaces (
                id INTEGER NOT NULL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                name VARCHAR(120) NOT NULL,
                subject VARCHAR(100),
                class_level VARCHAR(50),
                description VARCHAR(500),
                created_at DATETIME,
                updated_at DATETIME
            )
        """ if is_sqlite else """
            CREATE TABLE spaces (
                id SERIAL PRIMARY KEY,
                student_id INTEGER NOT NULL,
                name VARCHAR(120) NOT NULL,
                subject VARCHAR(100),
                class_level VARCHAR(50),
                description VARCHAR(500),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """))
        conn.execute(text("CREATE INDEX ix_spaces_student_id ON spaces (student_id)"))
        conn.commit()
        logger.info("[migrate] Created spaces table")

    if "space_documents" not in existing_tables:
        conn.execute(text("""
            CREATE TABLE space_documents (
                id INTEGER NOT NULL PRIMARY KEY,
                space_id INTEGER NOT NULL,
                filename VARCHAR(255) NOT NULL,
                size_bytes INTEGER NOT NULL DEFAULT 0,
                page_count INTEGER NOT NULL DEFAULT 0,
                chunks_count INTEGER NOT NULL DEFAULT 0,
                created_at DATETIME,
                CONSTRAINT uq_space_document_space_filename UNIQUE (space_id, filename)
            )
        """ if is_sqlite else """
            CREATE TABLE space_documents (
                id SERIAL PRIMARY KEY,
                space_id INTEGER NOT NULL,
                filename VARCHAR(255) NOT NULL,
                size_bytes INTEGER NOT NULL DEFAULT 0,
                page_count INTEGER NOT NULL DEFAULT 0,
                chunks_count INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                CONSTRAINT uq_space_document_space_filename UNIQUE (space_id, filename)
            )
        """))
        conn.execute(text("CREATE INDEX ix_space_documents_space_id ON space_documents (space_id)"))
        conn.commit()
        logger.info("[migrate] Created space_documents table")


def close_db() -> None:
    """Close database connections gracefully."""
    engine.dispose()
