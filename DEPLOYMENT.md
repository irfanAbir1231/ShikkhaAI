# ShikkhaAI — Render Deployment Guide

The system deploys as **two independent Render web services** plus a managed
Postgres database:

| Service             | Root      | Start command                                        | Python  |
|---------------------|-----------|------------------------------------------------------|---------|
| `shikkhaai-backend` | `backend` | `uvicorn app.main:app --host 0.0.0.0 --port $PORT`   | 3.12.7  |
| `shikkhaai-rag`     | `.`       | `uvicorn rag_server:app --host 0.0.0.0 --port $PORT` | 3.11.9  |

They communicate over HTTP only: the backend calls the RAG service at
`RAG_BASE_URL`. No shared code or filesystem is required at runtime.

A `render.yaml` Blueprint at the repo root provisions all three. Apply it via
**Render Dashboard → New → Blueprint**, or create the services manually with the
settings below.

---

## 1. Backend service

- **Build:** `pip install -r requirements.txt`
- **Start:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- **Health check:** `/health`
- **Root directory:** `backend`

### Environment variables

| Variable                      | Required | Notes |
|-------------------------------|----------|-------|
| `DATABASE_URL`                | yes      | From the managed Postgres. Legacy `postgres://` scheme is auto-rewritten. |
| `GEMINI_API_KEY`              | yes\*    | Single key or comma-separated pool. Secret — set in dashboard. |
| `RAG_BASE_URL`                | yes\*    | Public RAG URL **with** `/rag` suffix, e.g. `https://shikkhaai-rag.onrender.com/rag`. |
| `SECRET_KEY`                  | yes      | Strong random value for JWT signing (`generateValue` in Blueprint). |
| `RAG_TIMEOUT_SECONDS`         | no       | Default `60`. |
| `RAG_INPROCESS`               | no       | Keep `false` on Render (HTTP separation). |
| `MOCK_MODE`                   | no       | `true` runs without RAG/Gemini (built-in mock questions). |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | no       | Default `60`. |
| `CORS_ORIGINS`                | no       | Comma-separated origins or `*`. With `*`, credentialed CORS is disabled. |

\* At least one AI path is needed: `GEMINI_API_KEY` (direct Gemini fallback),
`RAG_BASE_URL` (RAG service), or `MOCK_MODE=true`. Study-companion (`/study-companion/ask`)
requires `RAG_BASE_URL`.

---

## 2. RAG service

- **Build:** `pip install -r rag/requirements.txt`
- **Start:** `uvicorn rag_server:app --host 0.0.0.0 --port $PORT`
- **Health check:** `/health`
- **Root directory:** `.` (repo root — needs `rag_server.py`, `rag/`, and `chroma_db/`)

### Environment variables

| Variable         | Required | Notes |
|------------------|----------|-------|
| `GEMINI_API_KEY` | yes      | Single key or comma-separated pool. Secret. |

### Resource & storage requirements

- **Memory:** pulls `torch` + `sentence-transformers`; the embedding model
  (`paraphrase-multilingual-MiniLM-L12-v2`, ~400 MB) downloads on first start.
  The free 512 MB plan can OOM during load — use **Starter (512 MB→ upgrade)** or
  higher. `render.yaml` sets `plan: starter`.
- **Vector store:** `chroma_db/` is committed in the repo and read at runtime
  (retrieval only). No persistent disk is needed unless you re-ingest. To rebuild
  the index, run `python -m rag.ingest` and commit the regenerated `chroma_db/`.
- **Cold start:** first request after deploy is slow (model load). Health checks
  may need a generous timeout.

---

## 3. Local development

```bash
# Backend (Python 3.12)
cd backend
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env          # fill GEMINI_API_KEY etc.
uvicorn app.main:app --reload --port 8000

# RAG (separate Python 3.11 venv — heavy deps)
py -3.11 -m venv .rag-venv && .rag-venv\Scripts\activate
pip install -r rag/requirements.txt
copy rag\.env.example rag\.env  # fill GEMINI_API_KEY
uvicorn rag_server:app --port 8100
# then set backend RAG_BASE_URL=http://localhost:8100/rag
```

SQLite (`DATABASE_URL=sqlite:///./shikkhaai.db`) works for zero-setup local dev.
Do **not** use SQLite in production — Render's filesystem is ephemeral.

---

## 4. Tests

```bash
cd backend
pip install pytest
python -m pytest tests/ -q
```

`tests/` covers startup, `/health`, OpenAPI registration, the
register→login→generate-exam flow, auth rejection, and config validation
(DATABASE_URL normalization, Gemini key parsing, startup warnings).

---

## 5. Health checks

| Service | URL                                  | Expected |
|---------|--------------------------------------|----------|
| Backend | `GET /health`                        | `{"success":true,"data":{"status":"ok",...}}` |
| RAG     | `GET /health`                        | `{"status":"ok","service":"rag"}` |
