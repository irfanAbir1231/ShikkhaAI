from dataclasses import dataclass
from functools import lru_cache
from os import getenv

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


@dataclass(frozen=True, slots=True)
class Settings:
    app_name: str
    database_url: str
    rag_base_url: str | None
    rag_timeout_seconds: float
    mock_mode: bool
    cors_origins: list[str]
    gemini_api_key: str | None
    secret_key: str
    access_token_expire_minutes: float


@lru_cache
def get_settings() -> Settings:
    rag_base_url = getenv("RAG_BASE_URL")
    return Settings(
        app_name=getenv("APP_NAME", "ShikkhaAI Backend"),
        database_url=getenv(
            "DATABASE_URL",
            "postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai",
        ),
        rag_base_url=rag_base_url.rstrip("/") if rag_base_url else None,
        rag_timeout_seconds=_as_float(getenv("RAG_TIMEOUT_SECONDS"), 60.0),
        mock_mode=_as_bool(getenv("MOCK_MODE"), False),
        cors_origins=_as_list(getenv("CORS_ORIGINS"), ["*"]),
        gemini_api_key=getenv("GEMINI_API_KEY"),
        secret_key=getenv("SECRET_KEY", "shikkhaai-dev-secret-change-in-production"),
        access_token_expire_minutes=_as_float(getenv("ACCESS_TOKEN_EXPIRE_MINUTES"), 60.0),
    )


settings = get_settings()
