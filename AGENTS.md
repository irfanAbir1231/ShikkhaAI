# AGENTS.md — ShikkhaAI

This file contains everything an AI coding agent needs to know about the ShikkhaAI project. All documentation, comments, and source code in the project are written in English.

---

## 1. Project Overview

ShikkhaAI is an AI-powered education system for Bangladeshi students. It generates curriculum-aligned exam questions using Retrieval-Augmented Generation (RAG), grades student submissions, and tracks topic-level performance and readiness scores.

The project has three main parts:

- **Backend** (`backend/`) — FastAPI JSON API for students, exams, grading, and profiling.
- **RAG Service** (`rag/`) — Standalone FastAPI service that handles PDF ingestion, vector retrieval (ChromaDB), and LLM-based question generation (Google Gemini).
- **Frontend** (`frontend/`) — Cross-platform Flutter app (mobile/web/desktop) for students to register, take exams, chat with a study companion, and view dashboards.

The backend and RAG service can run independently. The backend talks to the RAG service over HTTP or falls back to direct Gemini calls or mock data when the RAG service is unavailable.

---

## 2. Technology Stack

### Backend
- **Framework:** FastAPI (Python >= 3.14.5)
- **Package Manager:** `uv` (workspace member under repo root)
- **Database:** PostgreSQL (production-like) or SQLite (zero-setup dev)
- **ORM:** SQLAlchemy 2.x
- **Validation:** Pydantic 2.x
- **HTTP Client:** `httpx` (for calling the RAG service)
- **Server:** Uvicorn

### RAG Service
- **Framework:** FastAPI (Python 3.11 **only**)
- **Package Manager:** `pip` (separate virtual environment required)
- **Vector DB:** ChromaDB (`chromadb.PersistentClient`)
- **Embeddings:** `sentence-transformers`
- **LLM:** Google Gemini (`gemini-2.5-flash`) via `google-genai` SDK
- **PDF Parsing:** PyMuPDF (`fitz`)
- **Server:** Uvicorn on port 8100

> **Critical:** The RAG service **must** run on Python 3.11 because `torch`, `sentence-transformers`, and `chromadb` do not have wheels for Python 3.14. The repo already contains `.rag-venv` for this purpose.

### Frontend
- **Framework:** Flutter (Dart SDK ^3.9.2)
- **State Management:** `flutter_riverpod` with code generation (`riverpod_generator`)
- **Routing:** `go_router` with `StatefulShellRoute.indexedStack`
- **Networking:** `dio` with custom interceptors
- **Local Storage:** `hive` + `hive_flutter`
- **Serialization:** `freezed` + `json_serializable`
- **Charts:** `fl_chart`
- **Linting:** `flutter_lints` + `custom_lint` / `riverpod_lint`

---

## 3. Project Structure

```
shikkhaai-backend/
├── backend/                  # FastAPI backend (uv workspace member)
│   ├── app/
│   │   ├── main.py           # FastAPI entry point, CORS, exception handlers
│   │   ├── api/              # Route handlers (routes_students.py, routes_exams.py)
│   │   ├── core/             # config.py, responses.py
│   │   ├── db/               # base.py, models.py, session.py
│   │   ├── schemas/          # Pydantic models (student.py, exam.py)
│   │   ├── services/         # Business logic (student, exam, grading, profile)
│   │   ├── external/         # RAG HTTP client (rag_client.py)
│   │   └── utils/            # Shared utilities (reserved for future)
│   ├── pyproject.toml        # Backend deps (requires Python >= 3.14.5)
│   ├── .env.example          # Env template
│   └── shikkhaai.db          # SQLite file (if using SQLite)
├── rag/                      # RAG service (Python 3.11 only)
│   ├── ingest.py             # PDF -> chunks -> embeddings -> ChromaDB
│   ├── retrieve.py           # Query -> ChromaDB -> context chunks
│   ├── generate.py           # Gemini question generator
│   ├── rag_router.py         # FastAPI router for RAG endpoints
│   ├── requirements.txt      # RAG-only deps
│   └── .env.example          # Only GEMINI_API_KEY
├── frontend/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart         # Entry point (Hive init)
│   │   ├── app.dart          # MaterialApp.router, themes
│   │   ├── routing/          # GoRouter, route guards, route names
│   │   ├── theme/            # Color tokens, text themes, widget themes
│   │   ├── core/             # Constants, network (dio), errors, utils, extensions
│   │   ├── common_widgets/   # Atomic design: atoms, molecules, organisms, templates
│   │   ├── features/         # Feature modules
│   │   └── services/         # Connectivity service
│   ├── pubspec.yaml          # Flutter package manifest
│   ├── analysis_options.yaml # Lint rules
│   └── test/                 # Only widget_test.dart exists currently
├── rag_server.py             # Standalone FastAPI app mounting rag_router at /rag
├── docker-compose.yml        # Postgres 16 container
├── pyproject.toml            # Root workspace (includes backend as member)
├── start_backend.bat         # Windows batch: sets PYTHONPATH and runs uvicorn
└── uploads/                  # PDF source files for RAG ingestion
```

---

## 4. Build & Run Commands

### Prerequisites
- **Backend:** Python 3.14.5 + `uv`
- **RAG:** Python 3.11 + `pip`
- **Frontend:** Flutter SDK
- **Database:** Either SQLite (no setup) or Docker for PostgreSQL

### PostgreSQL (optional)
```bash
docker-compose up -d postgres
```

### Backend
```bash
# From repo root
uv --directory backend run uvicorn app.main:app --reload

# Or from backend/ directory
cd backend
uv run uvicorn app.main:app --reload
```
Backend runs on `http://127.0.0.1:8000`.

### RAG Service (Mode A2 — two-process)
```bash
# Terminal 1 — RAG service (Python 3.11 venv)
. .rag-venv/bin/activate   # or .rag-venv\Scripts\activate on Windows
uvicorn rag_server:app --host 0.0.0.0 --port 8100

# Terminal 2 — Backend
uv --directory backend run uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

### Windows Batch Script
```bash
start_backend.bat
```
Sets `PYTHONPATH` to repo root and runs backend uvicorn on port 8000, logging to `server.log`.
> **Note:** The batch file contains hardcoded absolute Windows paths. It will not work on other machines or paths without editing.

---

## 5. Environment Configuration

### Backend (`backend/.env`)
Copy from `backend/.env.example`:
```dotenv
APP_NAME=ShikkhaAI Backend
GEMINI_API_KEY=your-gemini-api-key-here
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai
# DATABASE_URL=sqlite:///./shikkhaai.db
RAG_BASE_URL=http://localhost:8100/rag
RAG_TIMEOUT_SECONDS=60
MOCK_MODE=false
CORS_ORIGINS=*
```

### RAG (`rag/.env`)
Copy from `rag/.env.example`:
```dotenv
GEMINI_API_KEY=your-gemini-api-key-here
```

### Generation Modes
The backend resolves which generator to use at request time:

| Mode | Condition | `source` field |
|------|-----------|---------------|
| **Real RAG** | `MOCK_MODE=false`, `rag` package importable (Python 3.11) | `"rag"` |
| **Direct Gemini** | `MOCK_MODE=false`, `rag` not importable, `GEMINI_API_KEY` set | `"gemini"` |
| **Mock** | `MOCK_MODE=true` | `"mock"` |
| **HTTP RAG** | `MOCK_MODE=false`, in-process import fails, `GEMINI_API_KEY` **unset**, `RAG_BASE_URL` reachable | `"rag"` |

> **Note:** ChromaDB currently contains **only class 8 science**. For real RAG retrieval, use `subject: "science"`, `class_level: "8"`.

---

## 6. Code Organization & Architecture

### Backend — Layered Architecture
```
Client -> FastAPI Routes -> Schemas -> Services -> DB / External Clients
```

- **Routes** (`app/api/`) must remain thin. Delegate all logic to services.
- **Schemas** (`app/schemas/`) define strict Pydantic request/response contracts.
- **Services** (`app/services/`) contain all business logic:
  - `student_service.py` — registration and lookup
  - `exam_service.py` — orchestrates generation and submission
  - `grading_service.py` — exact-match MCQ grading, short-answer placeholder
  - `profile_service.py` — topic performance, weak topics, readiness scoring
- **External** (`app/external/`) — only `rag_client.py` knows about RAG HTTP endpoints.
- **DB** (`app/db/`) — SQLAlchemy engine, session, ORM models.

### Frontend — Feature-First Clean Architecture
```
lib/
  core/          # Shared infrastructure (network, errors, utils, constants)
  common_widgets/# Atomic design widget hierarchy
  features/      # One directory per feature
    auth/
    dashboard/
    study_companion/
    exam/
    upload/
    library/
    settings/
    onboarding/
    splash/
    home/
  routing/       # GoRouter configuration
  theme/         # Design system tokens
```

Each feature typically contains:
- `data/` — models, local/remote datasources, repositories
- `presentation/` — providers (Riverpod), screens, widgets

### RAG Pipeline
```
PDF (uploads/) -> ingest.py (chunk + embed) -> ChromaDB
Query -> retrieve.py (embed + search) -> context chunks
Context + prompt -> generate.py (Gemini) -> JSON questions
```

---

## 7. Code Style Guidelines

### Python (Backend & RAG)
- Use type hints everywhere (function signatures, variables where helpful).
- Import style: use absolute imports within packages (`from app.db.session import init_db`).
- Config lives in `app/core/config.py` as a frozen dataclass; never hardcode env-dependent values.
- Responses use the unified envelope: `{"success": bool, "data": ..., "error": ...}`.
- Custom exceptions extend `AppError` in `app/core/responses.py`.
- Use `sqlalchemy` 2.x style (ORM mapped classes, `session.get()`, etc.).
- RAG service uses `from google import genai` (the **new** `google-genai` SDK), not the older `google-generativeai`.

### Dart / Flutter
- `analysis_options.yaml` enforces:
  - Single quotes for strings
  - No `print` statements
  - Prefer `const` constructors and literals
  - Use `SizedBox` for whitespace, avoid unnecessary `Container`
- Naming: files use `snake_case.dart`, classes use `PascalCase`, providers use `camelCaseProvider`.
- State: use `AsyncNotifier` / `StateNotifier` with Riverpod code generation.
- UI: prefer atomic-design widget hierarchy (`atoms/`, `molecules/`, `organisms/`).
- Network: all API calls go through the central `Dio` instance in `core/network/dio_client.dart`.
- The Dio base URL defaults to `http://10.0.2.2:8000` (Android emulator default) but can be overridden via the `API_BASE_URL` environment variable at compile time.

---

## 8. Testing Strategy

### Current State
- **Backend:** No tests exist yet. No `pytest` configuration.
- **Frontend:** Only `frontend/test/widget_test.dart` exists — a minimal smoke test that verifies the app launches.
- **Planned but not implemented:** The frontend README describes `test/unit/`, `test/widget/`, `test/integration/`, `test/mocks/`, `test/fixtures/` — these directories do not exist.

### Recommended Additions
- **Backend:** Add `pytest` and `httpx` (for FastAPI `TestClient`). Test routes, services, and the RAG client fallback logic.
- **Frontend:** Add widget tests for screens and golden tests for the design system. Use `mockito` or manual mocks for repositories.

---

## 9. Deployment

- **Docker:** Only `docker-compose.yml` exists, and it only defines a PostgreSQL container. There is no Docker setup for the backend, RAG service, or frontend.
- **Backend Deployment:** Manual uvicorn execution or process manager (e.g., systemd, PM2). The `start_backend.bat` script is Windows-only and contains hardcoded paths.
- **Frontend Deployment:** Standard Flutter build for target platforms (`flutter build web`, `flutter build apk`, etc.).
- **RAG Deployment:** Must run on a Python 3.11 environment with the packages from `rag/requirements.txt` installed.

---

## 10. Security Considerations

- **API Keys:** `GEMINI_API_KEY` must never be committed. Both `rag/.env` and `backend/.env` are ignored by `.gitignore`.
- **CORS:** Default is `CORS_ORIGINS=*` (permissive). Tighten this for production.
- **Database URLs:** `backend/.env` contains credentials. Use secrets management in production.
- **SQLite:** `backend/shikkhaai.db` and root `shikkhaai.db` contain local data; do not commit them.
- **No Authentication:** The API has no auth layer (no JWT, no API keys). Anyone with network access can call endpoints. This is acceptable for MVP but must be addressed before production.
- **File Uploads:** The `uploads/` directory holds PDFs. There is no upload API endpoint in the current codebase; files are added manually for ingestion.
- **Mock Mode:** `MOCK_MODE=true` bypasses all LLM calls. Ensure it is `false` in production if real RAG is desired.

---

## 11. Known Issues & Important Gotchas

1. **Embedding Model Mismatch (Critical)**
   - `rag/ingest.py` (active code, below the commented block) uses `paraphrase-multilingual-MiniLM-L12-v2`
   - `rag/retrieve.py` uses `sentence-transformers/paraphrase-MiniLM-L3-v2`
   - These are **different models**. Retrieval will produce broken results until both files use the **exact same model**.

2. **Missing `/weak-topics` Endpoint**
   - `rag/rag_router.py` does **not** implement `POST /weak-topics`.
   - The backend's `RagClient.detect_weak_topics()` tries to call it and silently falls back to mock data every time.

3. **PDF Page Limit**
   - `ingest.py` only reads the first `MAX_PAGES = 15` pages of each PDF. Full curriculum ingestion requires increasing this constant.

4. **Mock-First Default**
   - `backend/app/core/config.py` defaults `MOCK_MODE=True`. The backend will **not** call the RAG service or Gemini unless explicitly configured otherwise.

5. **Python Version Split**
   - Backend needs Python >= 3.14.5.
   - RAG needs Python 3.11.
   - Do not try to install `rag/requirements.txt` into the backend's `.venv` unless the backend is also running on Python 3.11.

6. **Question ID Format Depends on Source**
   - `"rag"` / `"gemini"`: numeric strings (`"1"`, `"2"`, ...)
   - `"mock"`: prefixed strings (`"q1"`, `"q2"`, ...)
   - MCQ answer format also differs: letter-only (`A`/`B`/`C`/`D`) for real RAG/Gemini, full option text for mock mode.

7. **Frontend Feature Completeness**
   - `exam/` has substantial implementation: config, session, result, history screens, and many widgets. It is **not** just a shell.
   - `upload/` and `library/` are still mostly shell screens awaiting implementation.
   - `dashboard/` and `study_companion/` have fairly complete UIs but rely on mock services, not the backend API.

8. **No Offline Sync Queue**
   - The frontend README describes an offline-first sync strategy, but it is not implemented in code.

9. **ingest.py File Structure**
   - The first ~236 lines of `rag/ingest.py` are commented-out old code. The active optimized ingestion logic starts at line 237.

10. **Backend Dependency Note**
    - `backend/pyproject.toml` does not list `google-genai`, but the root `pyproject.toml` does. The backend imports it in `rag_client.py` for the direct Gemini fallback. `uv` workspace resolution makes this work because the root is the workspace manifest.

---

## 12. Quick Reference — API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check + `mock_mode` status |
| POST | `/student/register` | Register a new student |
| GET | `/student/{id}` | Fetch student by ID |
| POST | `/exam/generate` | Generate an exam (RAG / Gemini / Mock) |
| POST | `/exam/submit` | Submit answers, grade, get readiness score |

| Method | RAG Endpoint | Description |
|--------|--------------|-------------|
| GET | `/health` | RAG service health |
| POST | `/rag/generate-exam` | Generate questions with retrieval |
| POST | `/rag/retrieve` | Debug: raw ChromaDB chunks |
| POST | `/rag/context` | Debug: assembled context string |

---

*Last updated: 2026-05-22*
