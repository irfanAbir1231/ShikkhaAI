"""Config / startup-validation unit tests — no DB or network needed."""
from app.core.config import (
    Settings,
    _normalize_database_url,
    _parse_gemini_keys,
    validate_settings,
)


def test_normalize_render_postgres_scheme():
    # Render/Heroku expose the legacy postgres:// scheme.
    assert _normalize_database_url("postgres://u:p@host:5432/db") == (
        "postgresql+psycopg2://u:p@host:5432/db"
    )
    assert _normalize_database_url("postgresql://u:p@host/db") == (
        "postgresql+psycopg2://u:p@host/db"
    )


def test_normalize_passthrough():
    assert _normalize_database_url("sqlite:///./x.db") == "sqlite:///./x.db"
    already = "postgresql+psycopg2://u:p@host/db"
    assert _normalize_database_url(already) == already


def test_parse_gemini_keys_pool():
    assert _parse_gemini_keys("a, b ,c") == ["a", "b", "c"]
    assert _parse_gemini_keys("") == []
    assert _parse_gemini_keys(None) == []


def test_gemini_primary_key_property():
    s = _settings(gemini_api_keys=["k1", "k2"])
    assert s.gemini_api_key == "k1"
    assert _settings(gemini_api_keys=[]).gemini_api_key is None


def test_validate_flags_missing_ai_backend():
    s = _settings(mock_mode=False, gemini_api_keys=[], rag_base_url=None)
    assert any("GEMINI_API_KEY" in w for w in validate_settings(s))


def test_validate_flags_default_secret_and_wildcard_cors():
    s = _settings()  # default insecure secret + "*" cors
    warns = validate_settings(s)
    assert any("SECRET_KEY" in w for w in warns)
    assert any("CORS_ORIGINS" in w for w in warns)


def _settings(**overrides) -> Settings:
    base = dict(
        app_name="t",
        database_url="sqlite:///./t.db",
        rag_base_url=None,
        rag_timeout_seconds=60.0,
        rag_inprocess=False,
        mock_mode=True,
        cors_origins=["*"],
        gemini_api_keys=[],
    )
    base.update(overrides)
    return Settings(**base)
