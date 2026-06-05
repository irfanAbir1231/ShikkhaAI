import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.routes_analytics import router as analytics_router
from app.api.routes_curriculum import router as curriculum_router
from app.api.routes_exams import router as exams_router
from app.api.routes_notes import router as notes_router
from app.api.routes_students import router as students_router
from app.api.routes_study_companion import router as study_companion_router
from app.core.config import settings, validate_settings
from app.core.logging_config import setup_logging, get_logger
from app.core.responses import (
    AppError,
    app_error_handler,
    http_exception_handler,
    success_response,
    unhandled_exception_handler,
    validation_exception_handler,
)
from app.db.session import init_db, close_db

setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Startup
    logger.info(f"Starting {settings.app_name} (Environment: {settings.environment})")
    for warning in validate_settings(settings):
        logger.warning("CONFIG: %s", warning)
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


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
    debug=settings.debug,
)

# allow_credentials cannot be combined with the "*" wildcard — browsers reject
# the response. Only enable credentials when explicit origins are configured.
_allow_credentials = "*" not in settings.cors_origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(students_router)
app.include_router(exams_router)
app.include_router(analytics_router)   # GET /student/{id}/dashboard|analytics|topics
app.include_router(curriculum_router)  # GET /curriculum/{class}/{subject}/chapters|topics
app.include_router(notes_router)       # GET|POST|DELETE /notes
app.include_router(study_companion_router)  # POST /study-companion/ask

# Mount RAG router if dependencies are available (monorepo dev mode)
try:
    import sys
    from pathlib import Path

    # Add repo root to path so `rag` package is importable when uvicorn
    # is launched from inside backend/
    repo_root = Path(__file__).resolve().parent.parent.parent
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))

    from rag.rag_router import router as rag_router

    app.include_router(rag_router, prefix="/rag")
    logger.info("RAG router mounted at /rag")
except Exception as exc:
    logger.warning("RAG router not mounted: %s", exc)


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
