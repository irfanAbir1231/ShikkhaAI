from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.routes_exams import router as exams_router
from app.api.routes_students import router as students_router
from app.core.config import settings
from app.core.responses import (
    AppError,
    app_error_handler,
    http_exception_handler,
    success_response,
    validation_exception_handler,
)
from app.db.session import init_db


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    init_db()
    yield


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

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
            "mock_mode": settings.mock_mode,
        }
    )
