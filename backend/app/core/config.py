import logging
from dataclasses import dataclass, field
from functools import lru_cache
from os import getenv

from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("shikkhaai")


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


def _normalize_database_url(url: str) -> str:
    """Render/Heroku Postgres add-ons expose DATABASE_URL with the legacy
    `postgres://` scheme, which SQLAlchemy 2.x rejects. Rewrite it to the
    driver-qualified `postgresql+psycopg2://` form."""
    if url.startswith("postgres://"):
        return "postgresql+psycopg2://" + url[len("postgres://"):]
    if url.startswith("postgresql://"):
        return "postgresql+psycopg2://" + url[len("postgresql://"):]
    return url


def _parse_gemini_keys(value: str | None) -> list[str]:
    """GEMINI_API_KEY may hold a single key or a comma-separated pool of keys
    (for quota rotation). Return a clean list; empty if unset."""
    if not value:
        return []
    return [k.strip() for k in value.split(",") if k.strip()]


@dataclass(frozen=True, slots=True)
class Settings:
    app_name: str
    database_url: str
    rag_base_url: str | None
    rag_timeout_seconds: float
    rag_inprocess: bool
    mock_mode: bool
    cors_origins: list[str]
    gemini_api_keys: list[str] = field(default_factory=list)
    secret_key: str = "shikkhaai-dev-secret-change-in-production"
    access_token_expire_minutes: float = 60.0

    @property
    def gemini_api_key(self) -> str | None:
        """Primary Gemini key (first in the pool). None if no key configured."""
        return self.gemini_api_keys[0] if self.gemini_api_keys else None


@lru_cache
def get_settings() -> Settings:
    rag_base_url = getenv("RAG_BASE_URL")
    return Settings(
        app_name=getenv("APP_NAME", "ShikkhaAI Backend"),
        database_url=_normalize_database_url(
            getenv("DATABASE_URL", "sqlite:///./shikkhaai.db")
        ),
        rag_base_url=rag_base_url.rstrip("/") if rag_base_url else None,
        rag_timeout_seconds=_as_float(getenv("RAG_TIMEOUT_SECONDS"), 60.0),
        # In-process RAG couples the backend to the heavy RAG deps (chromadb,
        # sentence-transformers). Off by default so a standalone backend deploy
        # talks to the RAG service over HTTP (RAG_BASE_URL) only.
        rag_inprocess=_as_bool(getenv("RAG_INPROCESS"), False),
        mock_mode=_as_bool(getenv("MOCK_MODE"), False),
        cors_origins=_as_list(getenv("CORS_ORIGINS"), ["*"]),
        gemini_api_keys=_parse_gemini_keys(getenv("GEMINI_API_KEY")),
        secret_key=getenv("SECRET_KEY", "shikkhaai-dev-secret-change-in-production"),
        access_token_expire_minutes=_as_float(getenv("ACCESS_TOKEN_EXPIRE_MINUTES"), 60.0),
    )


def validate_settings(s: Settings) -> list[str]:
    """Startup validation. Returns a list of human-readable warnings.
    Fatal misconfigurations raise RuntimeError."""
    warnings: list[str] = []

    if not s.mock_mode and not s.gemini_api_keys and not s.rag_base_url:
        warnings.append(
            "Neither GEMINI_API_KEY nor RAG_BASE_URL is set and MOCK_MODE is "
            "off — exam generation and study companion will fail at request time."
        )

    if s.secret_key == "shikkhaai-dev-secret-change-in-production":
        warnings.append(
            "SECRET_KEY is the insecure default — set a strong SECRET_KEY in production."
        )

    if "*" in s.cors_origins:
        warnings.append(
            "CORS_ORIGINS is '*' — credentialed requests are disabled. "
            "Set explicit origins to allow cookies/Authorization with credentials."
        )

    if s.database_url.startswith("sqlite"):
        warnings.append(
            "DATABASE_URL is SQLite — data is ephemeral on Render's filesystem. "
            "Use a managed Postgres database for production."
        )

    return warnings


settings = get_settings()
