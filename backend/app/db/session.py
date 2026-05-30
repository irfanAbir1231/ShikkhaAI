from collections.abc import Generator

from sqlalchemy import create_engine, event
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
    from app.db import models  # noqa: F401

    Base.metadata.create_all(bind=engine)


def close_db() -> None:
    """Close database connections gracefully."""
    engine.dispose()
