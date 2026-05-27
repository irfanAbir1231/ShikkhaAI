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

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings
from app.db.base import Base

connect_args: dict[str, object] = {}
if settings.database_url.startswith("sqlite"):
    connect_args["check_same_thread"] = False

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
    pool_pre_ping=True,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


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