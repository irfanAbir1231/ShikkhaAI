import logging
from typing import Any

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("shikkhaai")


class AppError(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400) -> None:
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(message)


def _serialize(data: Any) -> Any:
    if isinstance(data, BaseModel):
        return data.model_dump(mode="json")
    if isinstance(data, list):
        return [_serialize(item) for item in data]
    if isinstance(data, dict):
        return {key: _serialize(value) for key, value in data.items()}
    return data


def success_response(data: Any) -> dict[str, Any]:
    return {
        "success": True,
        "data": _serialize(data),
        "error": None,
    }


def error_response(code: str, message: str) -> dict[str, Any]:
    return {
        "success": False,
        "data": None,
        "error": {
            "code": code,
            "message": message,
        },
    }


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=error_response(code=exc.code, message=exc.message),
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    first_error = exc.errors()[0] if exc.errors() else {}
    location = ".".join(str(part) for part in first_error.get("loc", []))
    message = first_error.get("msg", "Invalid request payload")
    if location:
        message = f"{location}: {message}"
    return JSONResponse(
        status_code=422,
        content=error_response(code="VALIDATION_ERROR", message=message),
    )


async def http_exception_handler(
    request: Request,
    exc: StarletteHTTPException,
) -> JSONResponse:
    detail = exc.detail if isinstance(exc.detail, str) else "HTTP request failed"
    return JSONResponse(
        status_code=exc.status_code,
        content=error_response(code="HTTP_ERROR", message=detail),
    )


async def unhandled_exception_handler(
    request: Request,
    exc: Exception,
) -> JSONResponse:
    """Catch-all so unexpected errors never leak a stack trace to the client."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content=error_response(
            code="INTERNAL_ERROR",
            message="An internal error occurred. Please try again later.",
        ),
    )
