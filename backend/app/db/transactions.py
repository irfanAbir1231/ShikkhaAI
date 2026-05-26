from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.responses import AppError


def safe_commit(db: Session) -> None:
    """Commit the current session, rolling back on any SQLAlchemy error."""
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        raise AppError(
            code="DATABASE_ERROR",
            message="Database error, changes rolled back.",
            status_code=500,
        ) from exc
