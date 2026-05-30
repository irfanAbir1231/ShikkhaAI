# import logging
# from collections.abc import AsyncIterator
# from contextlib import asynccontextmanager
# from typing import Any

# from fastapi import FastAPI
# from fastapi.exceptions import RequestValidationError
# from fastapi.middleware.cors import CORSMiddleware
# from starlette.exceptions import HTTPException as StarletteHTTPException

# from app.api.routes_exams import router as exams_router
# from app.api.routes_students import router as students_router
# from app.core.config import settings
# from app.core.responses import (
#     AppError,
#     app_error_handler,
#     http_exception_handler,
#     success_response,
#     validation_exception_handler,
# )
# from app.db.session import init_db

# logging.basicConfig(
#     level=logging.INFO,
#     format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
# )
# logger = logging.getLogger("shikkhaai")


# @asynccontextmanager
# async def lifespan(app: FastAPI) -> AsyncIterator[None]:
#     logger.info("ShikkhaAI backend starting up — mock_mode=%s", settings.mock_mode)
#     init_db()
#     yield
#     logger.info("ShikkhaAI backend shutting down")


# app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=settings.cors_origins,
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# app.add_exception_handler(AppError, app_error_handler)
# app.add_exception_handler(RequestValidationError, validation_exception_handler)
# app.add_exception_handler(StarletteHTTPException, http_exception_handler)

# app.include_router(students_router)
# app.include_router(exams_router)


# @app.get("/health")
# def health_check() -> dict[str, Any]:
#     return success_response(
#         {
#             "status": "ok",
#             "mock_mode": settings.mock_mode,
#         }
#     )


import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.routes_analytics import router as analytics_router
from app.api.routes_exams import router as exams_router
from app.api.routes_notes import router as notes_router
from app.api.routes_students import router as students_router
from app.api.routes_study_companion import router as study_companion_router
from app.core.config import settings, validate_settings
from app.core.responses import (
    AppError,
    app_error_handler,
    http_exception_handler,
    success_response,
    unhandled_exception_handler,
    validation_exception_handler,
)
from app.db.session import init_db

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("shikkhaai")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    logger.info("ShikkhaAI backend starting up — mock_mode=%s", settings.mock_mode)
    for warning in validate_settings(settings):
        logger.warning("CONFIG: %s", warning)
    try:
        init_db()
    except Exception:
        logger.exception("Database initialization failed during startup")
        raise
    yield
    logger.info("ShikkhaAI backend shutting down")


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

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
app.include_router(notes_router)       # GET|POST|DELETE /notes
app.include_router(study_companion_router)  # POST /study-companion/ask


@app.get("/health")
def health_check() -> dict[str, Any]:
    return success_response({"status": "ok", "mock_mode": settings.mock_mode})