from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any
import logging

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.routes_exams import router as exams_router
from app.api.routes_students import router as students_router
from app.core.config import settings
from app.core.logging_config import setup_logging, get_logger
from app.core.responses import (
    AppError,
    app_error_handler,
    http_exception_handler,
    success_response,
    validation_exception_handler,
)
from app.db.session import init_db, close_db

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Startup
    logger.info(f"Starting {settings.app_name} (Environment: {settings.environment})")
    try:
        init_db()
        logger.info("Database initialized successfully")
    except Exception as exc:
        logger.error(f"Failed to initialize database: {exc}", exc_info=True)
        raise

    yield

    # Shutdown
    logger.info("Shutting down application...")
    try:
        close_db()
        logger.info("Database connections closed")
    except Exception as exc:
        logger.error(f"Error closing database: {exc}", exc_info=True)
    logger.info("Application shutdown complete")


setup_logging()
app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
    debug=settings.debug,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)

app.include_router(students_router)
app.include_router(exams_router)


@app.get("/health")
def health_check() -> dict[str, Any]:
    return success_response(
        {
            "status": "ok",
            "environment": settings.environment,
            "mock_mode": settings.mock_mode,
        }
    )


@app.get("/ready")
def readiness_check() -> dict[str, Any]:
    """Readiness check for orchestrators like Kubernetes/Render."""
    return success_response({"ready": True})
