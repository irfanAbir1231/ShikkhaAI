from collections.abc import Generator

from sqlalchemy import create_engine
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
    from app.db import models  # noqa: F401

    Base.metadata.create_all(bind=engine)
    _migrate_add_password_column(engine)


def _migrate_add_password_column(engine) -> None:
    """Add password column to students table if missing (SQLite compat)."""
    from sqlalchemy import inspect, text

    if not engine.dialect.name.startswith("sqlite"):
        return

    inspector = inspect(engine)
    columns = {col["name"] for col in inspector.get_columns("students")}
    if "password" not in columns:
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE students ADD COLUMN password VARCHAR(255)"))
            conn.commit()
