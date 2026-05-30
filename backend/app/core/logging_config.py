import logging
import sys
from typing import Any

from app.core.config import settings


def setup_logging() -> None:
    """Configure structured logging for the application."""
    log_level = logging.DEBUG if settings.debug else logging.INFO
    log_format = (
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        if settings.debug
        else "%(asctime)s - %(levelname)s - %(message)s"
    )

    logging.basicConfig(
        level=log_level,
        format=log_format,
        stream=sys.stdout,
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Configure uvicorn loggers
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)
    logging.getLogger("uvicorn").setLevel(log_level)

    # Suppress overly verbose loggers
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool").setLevel(logging.WARNING)

    logger = logging.getLogger(__name__)
    logger.info(
        f"Logging initialized | Environment: {settings.environment} | Debug: {settings.debug}"
    )


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance with the given name."""
    return logging.getLogger(name)
