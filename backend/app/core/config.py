from dataclasses import dataclass
from functools import lru_cache
from os import getenv
from typing import Literal

from dotenv import load_dotenv

load_dotenv()


def _as_bool(value: str | None, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _as_float(value: str | None, default: float) -> float:
    if value is None:
        return default
    try:
        return float(value)
    except ValueError:
        return default


def _as_list(value: str | None, default: list[str]) -> list[str]:
    if value is None or value.strip() == "":
        return default
    if value.strip() == "*":
        return ["*"]
    return [item.strip() for item in value.split(",") if item.strip()]


def _get_environment() -> Literal["development", "production", "testing"]:
    """Determine the environment from ENVIRONMENT variable."""
    env = getenv("ENVIRONMENT", "development").lower()
    if env in {"prod", "production"}:
        return "production"
    elif env in {"test", "testing"}:
        return "testing"
    return "development"


@dataclass(frozen=True, slots=True)
class Settings:
    app_name: str
    database_url: str
    rag_base_url: str | None
    rag_timeout_seconds: float
    mock_mode: bool
    cors_origins: list[str]
    gemini_api_key: str | None
<<<<<<< Updated upstream
    secret_key: str
    access_token_expire_minutes: float
=======
    environment: Literal["development", "production", "testing"]
    debug: bool

    def validate(self) -> None:
        """Validate critical settings at startup."""
        if not self.database_url:
            raise ValueError(
                "DATABASE_URL environment variable is required and cannot be empty"
            )

        if self.environment == "production":
            if self.cors_origins == ["*"]:
                raise ValueError(
                    "CORS_ORIGINS cannot be '*' in production. "
                    "Set CORS_ORIGINS to specific domains (e.g., 'https://example.com')"
                )

            if not self.gemini_api_key and not self.rag_base_url:
                raise ValueError(
                    "In production, either GEMINI_API_KEY or RAG_BASE_URL must be set "
                    "for exam generation to work"
                )

        if self.database_url.startswith("sqlite"):
            if self.environment == "production":
                raise ValueError(
                    "SQLite database is not suitable for production. "
                    "Please use PostgreSQL by setting DATABASE_URL to a postgresql:// URI"
                )
>>>>>>> Stashed changes


@lru_cache
def get_settings() -> Settings:
    rag_base_url = getenv("RAG_BASE_URL")
    environment = _get_environment()
    debug = _as_bool(getenv("DEBUG"), environment != "production")
    cors_origins = _as_list(
        getenv("CORS_ORIGINS"),
        ["http://localhost:3000", "http://localhost:5173"]
        if environment == "development"
        else [],
    )

    settings = Settings(
        app_name=getenv("APP_NAME", "ShikkhaAI Backend"),
        database_url=getenv(
            "DATABASE_URL",
            "postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai",
        ),
        rag_base_url=rag_base_url.rstrip("/") if rag_base_url else None,
        rag_timeout_seconds=_as_float(getenv("RAG_TIMEOUT_SECONDS"), 60.0),
<<<<<<< Updated upstream
        mock_mode=_as_bool(getenv("MOCK_MODE"), False),
        cors_origins=_as_list(getenv("CORS_ORIGINS"), ["*"]),
        gemini_api_key=getenv("GEMINI_API_KEY"),
        secret_key=getenv("SECRET_KEY", "shikkhaai-dev-secret-change-in-production"),
        access_token_expire_minutes=_as_float(getenv("ACCESS_TOKEN_EXPIRE_MINUTES"), 60.0),
=======
        mock_mode=_as_bool(getenv("MOCK_MODE"), environment == "development"),
        cors_origins=cors_origins,
        gemini_api_key=getenv("GEMINI_API_KEY"),
        environment=environment,
        debug=debug,
>>>>>>> Stashed changes
    )

    settings.validate()
    return settings


settings = get_settings()
