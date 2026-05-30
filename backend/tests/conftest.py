"""Test bootstrap — force a self-contained config (SQLite + mock RAG) before
any app module imports and reads settings."""
import os
import tempfile

os.environ.setdefault("MOCK_MODE", "true")
os.environ.setdefault(
    "DATABASE_URL", f"sqlite:///{os.path.join(tempfile.gettempdir(), 'shikkhaai_test.db')}"
)
os.environ.setdefault("SECRET_KEY", "test-secret-key-not-for-production")
os.environ.setdefault("CORS_ORIGINS", "*")
os.environ.pop("RAG_BASE_URL", None)

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture(scope="session")
def client() -> TestClient:
    with TestClient(app) as c:
        yield c
