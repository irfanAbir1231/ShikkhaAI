<!-- AGENTS.md — ShikkhaAI -->
# AGENTS.md — ShikkhaAI

This file contains everything an AI coding agent needs to know about the ShikkhaAI project. All documentation, comments, and source code in the project are written in English.

---

## 1. Project Overview

ShikkhaAI is an AI-powered adaptive learning platform for Bangladeshi students. It generates curriculum-aligned exam questions using Retrieval-Augmented Generation (RAG), grades student submissions (MCQ + short-answer), tracks topic-level performance, detects weak topics, and provides personalized study notes, dashboards, analytics, a study companion chatbot, and study plans.

The project has three main parts:

- **Backend** (`backend/`) — FastAPI JSON API for students, exams, grading, profiling, notes, dashboard, analytics, study companion, and study plans.
- **RAG Service** (`rag/`) — Standalone FastAPI service that handles PDF ingestion, vector retrieval (ChromaDB), and LLM-based question generation and Q&A (Google Gemini).
- **Frontend** (`frontend/`) — Cross-platform Flutter app (mobile/web/desktop) for students to register, take exams, chat with a study companion, view dashboards, manage study plans, and browse a library of notes.

The backend and RAG service can run independently. The backend talks to the RAG service over HTTP, or falls back to direct Gemini calls or mock data when the RAG service is unavailable.

---

## 2. Technology Stack

### Backend
- **Framework:** FastAPI (Python >= 3.11 per `pyproject.toml`; `.python-version` pins 3.14.5 for local dev; Render uses 3.12.7)
- **Package Manager:** `uv` (workspace member under repo root). `backend/requirements.txt` also exists for Render `pip` builds.
- **Database:** PostgreSQL (production) or SQLite (zero-setup dev)
- **ORM:** SQLAlchemy 2.x (`Mapped` / `mapped_column` style)
- **Validation:** Pydantic 2.x
- **HTTP Client:** `httpx` (for calling the RAG service)
- **Authentication:** JWT (`python-jose[cryptography]`) + bcrypt password hashing (`passlib[bcrypt]`)
- **Server:** Uvicorn

### RAG Service
- **Framework:** FastAPI (Python 3.11 **only**)
- **Package Manager:** `pip` (separate virtual environment required)
- **Vector DB:** ChromaDB (`chromadb.PersistentClient`)
- **Embeddings:** `sentence-transformers` (`paraphrase-multilingual-MiniLM-L12-v2`)
- **LLM:** Google Gemini (`gemini-2.5-flash`) via `google-genai` SDK (the **new** SDK, not `google-generativeai`)
- **PDF Parsing:** PyMuPDF (`fitz`)
- **Server:** Uvicorn on port 8100

> **Critical:** The RAG service **must** run on Python 3.11 because `torch`, `sentence-transformers`, and `chromadb` do not have reliable wheels for Python 3.14. The repo already contains `.rag-venv` for this purpose.

### Frontend
- **Framework:** Flutter (Dart SDK ^3.9.2)
- **State Management:** `flutter_riverpod` with code generation (`riverpod_generator`)
- **Routing:** `go_router` with `StatefulShellRoute.indexedStack`
- **Networking:** `dio` with custom interceptors
- **Local Storage:** `hive` + `hive_flutter`
- **Serialization:** `freezed` + `json_serializable` (code generation required)
- **Charts:** `fl_chart`
- **Localization:** ARB files (`lib/l10n/app_en.arb`, `app_bn.arb`) for English + Bengali
- **Linting:** `flutter_lints` + `custom_lint` / `riverpod_lint`

---

## 3. Project Structure

```
shikkhaai-backend/
├── backend/                  # FastAPI backend (uv workspace member)
│   ├── app/
│   │   ├── main.py           # FastAPI entry point, CORS, exception handlers, router mounting
│   │   ├── api/              # Route handlers
│   │   │   ├── routes_students.py    # POST /student/register, /login, /{id}, /exams, /attempts, /weak-topics
│   │   │   ├── routes_exams.py       # POST /exam/generate, /submit, GET /exam/{id}/attempts
│   │   │   ├── routes_analytics.py   # GET /student/{id}/dashboard, /analytics, /topics
│   │   │   ├── routes_notes.py       # CRUD /notes + on-demand generate
│   │   │   └── routes_study_companion.py  # POST /study-companion/ask
│   │   ├── core/             # config.py, responses.py, security.py, logging_config.py
│   │   ├── db/               # base.py, models.py, session.py, transactions.py
│   │   ├── schemas/          # Pydantic request/response models
│   │   │   ├── student.py
│   │   │   ├── exam.py
│   │   │   ├── note.py
│   │   │   ├── analytics.py
│   │   │   └── study_companion.py
│   │   ├── services/         # Business logic
│   │   │   ├── student_service.py
│   │   │   ├── exam_service.py
│   │   │   ├── grading_service.py
│   │   │   ├── profile_service.py
│   │   │   ├── dashboard_service.py
│   │   │   ├── analytics_service.py
│   │   │   ├── note_service.py
│   │   │   └── note_generation_service.py
│   │   ├── external/         # RAG HTTP client (rag_client.py)
│   │   └── utils/            # Shared utilities (reserved)
│   ├── tests/                # pytest tests (conftest.py, test_app.py, test_config.py)
│   ├── pyproject.toml        # Backend deps + pytest config
│   ├── requirements.txt      # Pip-compatible deps for Render deployment
│   ├── .env.example          # Env template
│   └── shikkhaai.db          # SQLite file (if using SQLite)
├── rag/                      # RAG service (Python 3.11 only)
│   ├── ingest.py             # PDF -> chunks -> embeddings -> ChromaDB
│   ├── retrieve.py           # Query -> ChromaDB -> context chunks
│   ├── generate.py           # Gemini question generator + study-companion answer generator
│   ├── rag_router.py         # FastAPI router for RAG endpoints
│   ├── requirements.txt      # RAG-only deps
│   └── .env.example          # Only GEMINI_API_KEY
├── frontend/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart         # Entry point (Hive init)
│   │   ├── app.dart          # MaterialApp.router, themes, localization
│   │   ├── l10n/             # ARB localization files + generated AppLocalizations
│   │   ├── routing/          # GoRouter, route guards, route names
│   │   ├── theme/            # Color tokens, text themes, widget themes, decorations
│   │   ├── core/             # Constants, network (dio), errors, utils, extensions
│   │   ├── common_widgets/   # Atomic design: atoms, molecules, organisms, templates
│   │   └── features/         # Feature modules
│   │       ├── auth/
│   │       ├── dashboard/
│   │       ├── analytics/
│   │       ├── exam/
│   │       ├── library/
│   │       ├── study_companion/
│   │       ├── study_plan/
│   │       ├── topics/
│   │       ├── home/
│   │       ├── onboarding/
│   │       ├── splash/
│   │       └── settings/
│   ├── pubspec.yaml          # Flutter package manifest
│   ├── analysis_options.yaml # Lint rules
│   └── test/                 # widget_test.dart (smoke test)
├── chroma_db/                # Committed ChromaDB vector store (class 8 science only)
├── uploads/                  # PDF source files for RAG ingestion
├── docs/                     # Human-readable guides (BACKEND_GUIDE, FRONTEND_GUIDE, RAG_GUIDE, etc.)
├── rag_server.py             # Standalone FastAPI app mounting rag_router at /rag
├── docker-compose.yml        # Postgres 16 container only
├── render.yaml               # Render Blueprint for backend + RAG + Postgres
├── Procfile                  # Backend start command for Heroku/Render-style platforms
├── pyproject.toml            # Root workspace (includes backend as member)
├── start_backend.bat         # Windows batch: hardcoded paths, runs backend uvicorn
├── DEPLOYMENT.md             # Render deployment guide
└── STARTUP_GUIDE.md          # Local multi-terminal startup instructions
```

---

## 4. Build & Run Commands

### Prerequisites
- **Backend:** Python 3.11+ (`.python-version` pins 3.14.5) + `uv`
- **RAG:** Python 3.11 + `pip`
- **Frontend:** Flutter SDK ^3.9.2
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

### RAG Service (two-process mode)
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

> **Code generation:** If `build_runner` generated files (`.g.dart`, `.freezed.dart`) are missing, run:
> ```bash
> cd frontend
> flutter pub run build_runner build --delete-conflicting-outputs
> ```
> Currently these generated files are **not** committed to the repo.

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
ENVIRONMENT=development
GEMINI_API_KEY=your-gemini-api-key-here
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai
# DATABASE_URL=sqlite:///./shikkhaai.db
RAG_BASE_URL=http://localhost:8100/rag
RAG_TIMEOUT_SECONDS=60
RAG_INPROCESS=false
MOCK_MODE=false
SECRET_KEY=change-me-to-a-long-random-secret
ACCESS_TOKEN_EXPIRE_MINUTES=60
CORS_ORIGINS=*
DEBUG=true
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

> **Note:** ChromaDB currently contains **only class 8 science** (from `uploads/class_8_science_eng.pdf`). For real RAG retrieval, use `subject: "science"`, `class_level: "8"`.

---

## 6. Code Organization & Architecture

### Backend — Layered Architecture
```
Client -> FastAPI Routes -> Schemas -> Services -> DB / External Clients
```

- **Routes** (`app/api/`) must remain thin. Delegate all logic to services.
- **Schemas** (`app/schemas/`) define strict Pydantic request/response contracts.
- **Services** (`app/services/`) contain all business logic:
  - `student_service.py` — registration, lookup, authentication
  - `exam_service.py` — orchestrates generation and submission
  - `grading_service.py` — exact-match MCQ grading, Gemini-based short-answer grading with partial credit
  - `profile_service.py` — topic performance, weak topics, readiness scoring
  - `dashboard_service.py` — readiness, streak, recent quizzes, recommendations
  - `analytics_service.py` — topic accuracy, weak chapters, improvement history, practice suggestions
  - `note_service.py` — CRUD for student notes
  - `note_generation_service.py` — auto-generates study notes for weak topics via Gemini
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
    analytics/
    exam/
    library/
    study_companion/
    study_plan/
    topics/
    home/
    onboarding/
    splash/
    settings/
  routing/       # GoRouter configuration
  theme/         # Design system tokens
```

Each feature typically contains:
- `data/` — models, local/remote datasources, repositories
- `domain/` — repository interfaces
- `presentation/` — providers (Riverpod), screens, widgets

### RAG Pipeline
```
PDF (uploads/) -> ingest.py (chunk + embed) -> ChromaDB
Query -> retrieve.py (embed + search) -> context chunks
Context + prompt -> generate.py (Gemini) -> JSON questions / markdown answers
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
- The Dio base URL defaults to `http://10.52.75.70:8000` but can be overridden via the `API_BASE_URL` environment variable at compile time (`--dart-define=API_BASE_URL=...`).

---

## 8. Testing Strategy

### Backend Tests
Tests exist in `backend/tests/` and are configured in `backend/pyproject.toml`:

```toml
[dependency-groups]
dev = ["pytest>=8.0"]

[tool.pytest.ini_options]
pythonpath = ["."]
testpaths = ["tests"]
```

Run with:
```bash
cd backend
uv run pytest tests/ -q
# or: python -m pytest tests/ -q
```

**Test files:**
- `conftest.py` — Forces `MOCK_MODE=true`, SQLite temp DB, and test `SECRET_KEY` before any app imports. Provides a session-scoped `TestClient` fixture.
- `test_app.py` — Smoke tests for `/health`, OpenAPI registration, a full register→login→generate-exam flow, and unauthorized request rejection.
- `test_config.py` — Unit tests for config helpers: `DATABASE_URL` normalization (Render's legacy `postgres://` scheme), Gemini key pool parsing, and startup validation warnings.

### Frontend Tests
- Only `frontend/test/widget_test.dart` exists — a minimal smoke test that verifies the app launches.
- **Planned but not implemented:** The frontend README describes `test/unit/`, `test/widget/`, `test/integration/`, `test/mocks/`, `test/fixtures/` — these directories do not exist.

### Recommended Additions
- **Backend:** Add `httpx` (for FastAPI `TestClient`) and test the RAG client fallback logic.
- **Frontend:** Add widget tests for screens. Use `mockito` or manual mocks for repositories. Run `flutter test`.

---

## 9. Deployment

### Render (Primary Target)
A `render.yaml` Blueprint at the repo root provisions:
- **Managed Postgres** (`shikkhaai-db`)
- **Backend web service** (`shikkhaai-backend`) — Python 3.12.7, rootDir `backend`, build `pip install -r requirements.txt`, start `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- **RAG web service** (`shikkhaai-rag`) — Python 3.11.9, rootDir `.`, build `pip install -r rag/requirements.txt`, start `uvicorn rag_server:app --host 0.0.0.0 --port $PORT`

Apply via **Render Dashboard → New → Blueprint**.

Key Render notes:
- `chroma_db/` is committed in the repo and read at runtime (retrieval only). No persistent disk is needed unless you re-ingest.
- The RAG service pulls `torch` + `sentence-transformers`; the embedding model (~400MB) downloads on first start. The free 512MB plan can OOM — the Blueprint sets `plan: starter` for the RAG service.
- `RAG_BASE_URL` on the backend must include the `/rag` suffix, e.g. `https://shikkhaai-rag.onrender.com/rag`.
- `SECRET_KEY` is auto-generated by Render on first deploy.

### Local Production-like
```bash
docker-compose up -d postgres
# Then set DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai
```

### Frontend Deployment
Standard Flutter build for target platforms:
```bash
flutter build web
flutter build apk
flutter build ios
```

---

## 10. Security Considerations

- **API Keys:** `GEMINI_API_KEY` must never be committed. Both `rag/.env` and `backend/.env` are ignored by `.gitignore`.
- **CORS:** Default is `CORS_ORIGINS=*` (permissive). Tighten this for production — the config validator raises a fatal error if `*` is used in production.
- **Database URLs:** `backend/.env` contains credentials. Use secrets management in production.
- **SQLite:** `backend/shikkhaai.db` and root `shikkhaai.db` contain local data; do not commit them.
- **Authentication:** JWT authentication is implemented. All student-data and exam endpoints require a valid `Authorization: Bearer <token>` header. Ownership is enforced — students can only access their own data.
- **Password Hashing:** bcrypt via `passlib` with 12 rounds.
- **SECRET_KEY:** Used for JWT signing. Do NOT reuse the Gemini API key. A default insecure secret is present in dev; production validation rejects it.
- **File Uploads:** The `uploads/` directory holds PDFs. There is no upload API endpoint in the current codebase; files are added manually for ingestion.
- **Mock Mode:** `MOCK_MODE=true` bypasses all LLM calls. Ensure it is `false` in production if real RAG is desired.
- **No Rate Limiting:** The API currently has no rate limiting. Add before production.
- **No Database Migrations:** Schema changes rely on `Base.metadata.create_all()` and ad-hoc SQLite ALTER migrations in `session.py`. Alembic is recommended for production.

---

## 11. Known Issues & Important Gotchas

1. **Python Version Split**
   - Backend `pyproject.toml` requires `>=3.11`. `.python-version` pins `3.14.5` for local dev. Render deploys on `3.12.7`.
   - RAG needs Python 3.11.
   - Do not try to install `rag/requirements.txt` into the backend's `.venv` unless the backend is also running on Python 3.11.

2. **Git Merge Conflicts in `session.py`**
   - `backend/app/db/session.py` contains unresolved merge conflict markers (`<<<<<<< Updated upstream`, `=======`, `>>>>>>> Stashed changes`) around lines 53–189. This file will fail to import and will crash the backend on startup. It must be cleaned up before the app can run.

3. **PDF Page Limit**
   - `rag/ingest.py` only reads the first `MAX_PAGES = 15` pages of each PDF. Full curriculum ingestion requires increasing this constant.

4. **`ingest.py` File Structure**
   - The first ~236 lines of `rag/ingest.py` are commented-out old code. The active optimized ingestion logic starts at line 237.

5. **Question ID Format Depends on Source**
   - `"rag"` / `"gemini"`: numeric strings (`"1"`, `"2"`, ...)
   - `"mock"`: prefixed strings (`"q1"`, `"q2"`, ...)
   - MCQ answer format also differs: letter-only (`A`/`B`/`C`/`D`) for real RAG/Gemini, full option text for mock mode.

6. **Frontend Code Generation**
   - `freezed`, `json_serializable`, and `riverpod_generator` are configured in `pubspec.yaml`, but the generated `.g.dart` and `.freezed.dart` files are **not committed**. Running `flutter pub run build_runner build` is required after cloning.

7. **Frontend Feature Completeness**
   - `exam/` has substantial implementation: config, session, result, history screens, and many widgets.
   - `dashboard/`, `analytics/`, `topics/`, and `library/` are wired to real backend APIs.
   - `study_companion/` and `study_plan/` have complete UIs but still use mock services for some operations (study companion chat is not yet fully RAG-powered; study plan is locally generated).
   - `upload/` is still mostly a shell screen awaiting implementation.

8. **No Offline Sync Queue**
   - The frontend README describes an offline-first sync strategy, but it is not implemented in code. `syncQueueBox` is defined but never used.

9. **ChromaDB Collection Creation**
   - `rag/retrieve.py` uses `get_collection()`. If the collection does not exist, the RAG service will crash on the first query. Ensure ingestion has been run at least once, or change to `get_or_create_collection()`.

10. **Backend Dependency Note**
    - `backend/pyproject.toml` does not list `google-genai`, but the root `pyproject.toml` does. The backend imports it in `rag_client.py` for the direct Gemini fallback. `uv` workspace resolution makes this work because the root is the workspace manifest.

11. **RAG Service Weak-Topics Endpoint**
    - `rag/rag_router.py` implements `POST /weak-topics` as a simple rule-based filter (score < 60 or consistency < 50 or last_score < 50). It mirrors the backend's local heuristic.

12. **Study Companion Endpoint**
    - `POST /study-companion/ask` exists on both the backend (`routes_study_companion.py`) and the RAG service (`rag_router.py` `/rag/ask`). The backend's `RagClient.ask()` tries in-process RAG first, then HTTP RAG. There is no direct Gemini fallback for the study companion.

13. **Frontend API Base URL**
    - `ApiConstants.baseUrl` defaults to `http://10.52.75.70:8000`. It can be overridden at compile time with `--dart-define=API_BASE_URL=...`.

14. **Study Companion Hardcoded Subject**
    - The frontend study companion provider hardcodes `subject = 'science'` because ChromaDB currently only contains class 8 science data.

15. **Commented Legacy Code**
    - `backend/app/db/models.py` lines 1–97 contain a large block of commented-out old model code.
    - `backend/app/services/exam_service.py` lines 1–131 contain a large block of commented-out old service code.

16. **RAG Model Load at Import Time**
    - `rag/retrieve.py` loads the `SentenceTransformer` model at module import time, making the RAG service slow to start and difficult to test without the heavy model.

17. **Broken `easyBengali` Prompt**
    - `rag/generate.py` line 190 says `"Class student"` instead of `"Class {class_level} student"`. The `class_level` variable is not interpolated.

---

## 12. Quick Reference — API Endpoints

### Backend Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health` | Public | Health check + `mock_mode` status |
| GET | `/ready` | Public | Readiness check for orchestrators |
| POST | `/student/register` | Public | Register a new student (returns JWT) |
| POST | `/student/login` | Public | Login (returns JWT) |
| GET | `/student/{id}` | Bearer | Fetch student by ID (ownership enforced) |
| GET | `/student/{id}/exams` | Bearer | List student's exams |
| GET | `/student/{id}/attempts` | Bearer | List student's attempts |
| GET | `/student/{id}/weak-topics` | Bearer | Weak topics from performance data |
| GET | `/student/{id}/dashboard` | Bearer | Dashboard snapshot |
| GET | `/student/{id}/analytics` | Bearer | Comprehensive analytics |
| GET | `/student/{id}/topics` | Bearer | Curriculum topics with completion |
| POST | `/exam/generate` | Bearer | Generate an exam (RAG / Gemini / Mock) |
| POST | `/exam/submit` | Bearer | Submit answers, grade, get readiness + auto-notes |
| GET | `/exam/{id}/attempts` | Bearer | List attempts for a specific exam |
| POST | `/notes` | Bearer | Create a note |
| POST | `/notes/generate` | Bearer | On-demand generate a study note |
| GET | `/notes` | Bearer | List notes (filters: topic, source) |
| GET | `/notes/{id}` | Bearer | Get a single note |
| DELETE | `/notes/{id}` | Bearer | Delete a note |
| POST | `/study-companion/ask` | Bearer | Study companion Q&A (RAG-powered) |

### RAG Service Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | RAG service health |
| POST | `/rag/generate-exam` | Generate questions with retrieval |
| POST | `/rag/retrieve` | Debug: raw ChromaDB chunks |
| POST | `/rag/context` | Debug: assembled context string |
| POST | `/rag/ask` | Study-companion Q&A with curriculum context |
| POST | `/rag/weak-topics` | Rule-based weak topic filter |

---

*Last updated: 2026-06-05*
