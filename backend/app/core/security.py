"""Password hashing and JWT token utilities."""

from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings
from app.core.responses import AppError

ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    """Hash a plain-text password using bcrypt."""
    pw_bytes = password.encode("utf-8")
    hashed = bcrypt.hashpw(pw_bytes, bcrypt.gensalt(rounds=12))
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain-text password against a bcrypt hash."""
    pw_bytes = plain_password.encode("utf-8")
    hash_bytes = hashed_password.encode("utf-8")
    return bcrypt.checkpw(pw_bytes, hash_bytes)


def create_access_token(data: dict[str, Any], expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.secret_key, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise AppError(
            code="INVALID_TOKEN",
            message="Could not validate credentials.",
            status_code=401,
        ) from exc
    return payload
