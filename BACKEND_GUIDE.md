# Backend Completion Guide

## Overview

The ShikkhaAI backend is a **FastAPI** application that handles student registration, exam generation, answer submission, grading, and performance profiling. It is architected as a clean layered system:

```
Client → Routes → Schemas → Services → DB / External Clients
```

The backend is a **solid MVP scaffold** — the core happy path (register → generate exam → submit → grade MCQ → compute readiness) works. However, several critical gaps must be closed before the system is production-ready.

---

## Current State

### ✅ What Works

| Endpoint | Method | Status |
|----------|--------|--------|
| `/health` | GET | Returns `status` and `mock_mode` flag |
| `/student/register` | POST | Validates email, creates student |
| `/student/{id}` | GET | Fetches student by ID |
| `/exam/generate` | POST | Generates exam via RAG / Gemini / Mock fallback |
| `/exam/submit` | POST | Submits answers, grades MCQ, computes readiness |

### ⚠️ Partially Working

- **Short-answer grading**: Always returns a placeholder (0 marks, static message).
- **Weak-topic detection**: Computes local weak topics correctly, but the RAG HTTP fallback (`POST /weak-topics`) is unimplemented on the RAG service side, so it silently falls back to local-only logic.
- **RAG client fallback chain**: Well-architected 4-tier cascade (Mock → In-process RAG → Direct Gemini → HTTP RAG), but `MOCK_MODE` defaults to `True`, so most deployments never reach real generation.

### ❌ Missing / Broken

| Issue | Impact |
|-------|--------|
| No authentication / authorization | Anyone can call any endpoint |
| No exam/attempt history endpoints | Frontend cannot show past exams |
| No short-answer LLM grading | Short-answer questions are always scored 0 |
| No database migrations | Schema changes require manual DB wipe |
| No structured logging | Impossible to debug production issues |
| `RAG_TIMEOUT_SECONDS` defaults to 5s | LLM calls time out constantly |
| `MOCK_MODE` defaults to `True` | Backend uses fake data unless explicitly configured |
| No input sanitization on JSON blobs | Malformed upstream JSON can crash serialization |
| No idempotency on exam submission | Double-submit creates duplicate attempts |
| No tests | Zero test coverage |

---

## Step-by-Step Completion Plan

### Phase 1: Critical Fixes (Do These First)

#### 1.1 Fix Default Configuration

**File:** `backend/app/core/config.py`

- Change `RAG_TIMEOUT_SECONDS` default from `5.0` to `60.0`.
- Change `MOCK_MODE` default from `True` to `False`.
- Tighten `CORS_ORIGINS` for production (keep `*` only for dev).

```python
# BEFORE
rag_timeout_seconds: float = _as_float(getenv("RAG_TIMEOUT_SECONDS"), 5.0)
mock_mode: bool = _as_bool(getenv("MOCK_MODE"), True)

# AFTER
rag_timeout_seconds: float = _as_float(getenv("RAG_TIMEOUT_SECONDS"), 60.0)
mock_mode: bool = _as_bool(getenv("MOCK_MODE"), False)
```

#### 1.2 Add Structured Logging

Add `logging` configuration to `backend/app/main.py`:

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("shikkhaai")
```

Then instrument all services to log key events (exam generation source, RAG fallback triggers, grading results, errors).

#### 1.3 Fix Backend Dependency Declaration

**File:** `backend/pyproject.toml`

Add `google-genai` to backend dependencies (it is currently only in the root workspace manifest):

```toml
dependencies = [
    "fastapi>=0.115.0",
    "httpx>=0.28.0",
    "psycopg2-binary>=2.9.10",
    "pydantic>=2.11.0",
    "python-dotenv>=1.1.0",
    "sqlalchemy>=2.0.40",
    "uvicorn>=0.34.0",
    "google-genai>=1.0.0",  # <-- ADD THIS
]
```

#### 1.4 Add Transaction Safety

Wrap all `db.commit()` calls in services with `try/except/rollback`:

```python
from sqlalchemy.exc import SQLAlchemyError

try:
    db.commit()
except SQLAlchemyError:
    db.rollback()
    raise AppError(status_code=500, message="Database error, changes rolled back.")
```

---

### Phase 2: Core Features

#### 2.1 Implement Short-Answer LLM Grading

**File:** `backend/app/services/grading_service.py`

Replace the `grade_short_answers()` placeholder with a real implementation:

1. Build a prompt containing the question, expected answer, student answer, and max marks.
2. Call Google Gemini via `google-genai` SDK (model: `gemini-2.5-flash`).
3. Parse the response to extract `awarded_marks` and `feedback`.
4. Return structured `ShortAnswerResult` objects.

**Prompt template:**

```
You are an expert Bangladeshi school teacher grading a student answer.

Question: {question}
Expected Answer: {expected_answer}
Student Answer: {student_answer}
Maximum Marks: {max_marks}

Grade the student answer and respond in this exact JSON format:
{
  "awarded_marks": <float>,
  "feedback": "<constructive feedback in English or Bengali>"
}

Be fair: award partial credit for partially correct answers.
```

#### 2.2 Add Exam / Attempt History Endpoints

**File:** `backend/app/api/routes_exams.py`

Add these endpoints:

```python
@router.get("/student/{student_id}/exams", response_model=List[ExamSummaryResponse])
def list_student_exams(student_id: int, db: Session = Depends(get_db)):
    ...

@router.get("/exam/{exam_id}/attempts", response_model=List[AttemptResponse])
def list_exam_attempts(exam_id: int, db: Session = Depends(get_db)):
    ...

@router.get("/student/{student_id}/attempts", response_model=List[AttemptResponse])
def list_student_attempts(student_id: int, db: Session = Depends(get_db)):
    ...
```

Also add `GET /student/{id}/weak-topics` to return the current weak topics without requiring an exam submission.

#### 2.3 Add Idempotency to Exam Submission

Modify `POST /exam/submit` to accept an optional `idempotency_key` in the request body. Store it in the `Attempt` model (add column `idempotency_key` with `unique=True`). Before creating a new attempt, check if one already exists with the same key and return the existing result.

---

### Phase 3: Authentication (Required Before Production)

#### 3.1 JWT-Based Auth

1. Add `python-jose` and `passlib[bcrypt]` to dependencies.
2. Create `backend/app/core/security.py` with password hashing and JWT encode/decode.
3. Add `POST /student/login` endpoint that returns an access token.
4. Add `POST /student/login` to `routes_students.py`.
5. Create a FastAPI `Depends(get_current_student)` dependency that validates the JWT from the `Authorization: Bearer <token>` header.
6. Protect all exam endpoints with this dependency.

**Note:** The frontend already has an `AuthInterceptor` that reads `auth_token` from Hive — you only need to start returning and validating real tokens.

---

### Phase 4: Database Migrations

#### 4.1 Add Alembic

```bash
cd backend
uv add alembic
alembic init alembic
```

Configure `alembic.ini` and `alembic/env.py` to use the same `DATABASE_URL` from your config. Generate the initial migration:

```bash
alembic revision --autogenerate -m "Initial schema"
alembic upgrade head
```

Document the migration workflow in this README.

---

### Phase 5: Testing

#### 5.1 Add pytest

```bash
cd backend
uv add pytest httpx
```

Create `backend/tests/` with:

| Test File | What to Test |
|-----------|-------------|
| `test_health.py` | `/health` returns 200 and correct shape |
| `test_students.py` | Register, fetch, duplicate email rejection |
| `test_exams.py` | Generate exam (mock mode), submit exam, grade correctness |
| `test_grading.py` | Exact-match MCQ grading edge cases |
| `test_rag_client.py` | Fallback chain order, mock fallback on failure |

Use FastAPI's `TestClient` for integration tests.

---

### Phase 6: Polish

#### 6.1 Input Validation

- Add a maximum size check on JSON blob fields (`questions`, `answer_key`, `answers`) to prevent abuse.
- Use Pydantic validators on schema fields (e.g., `num_questions` must be between 1 and 50).

#### 6.2 Cascade Deletes

**File:** `backend/app/db/models.py`

Add `cascade="all, delete-orphan"` to `Student.exams` and `Student.attempts` relationships so deleting a student cleans up their data.

#### 6.3 Rate Limiting

Add `slowapi` or a custom middleware to limit exam generation and submission rates per IP / student.

---

## Database Schema Reference

```
Student
  id (PK)
  name
  email (unique)
  grade_level
  created_at

Exam
  id (PK)
  student_id (FK → Student)
  subject
  class_level
  topic
  difficulty
  num_questions
  questions (JSON)
  answer_key (JSON)
  created_at

Attempt
  id (PK)
  student_id (FK → Student)
  exam_id (FK → Exam)
  answers (JSON)
  mcq_score
  mcq_total
  short_score
  short_total
  score_percentage
  weak_topics (JSON)
  short_answer_feedback (JSON)
  readiness_score
  created_at

TopicPerformance
  id (PK)
  student_id (FK → Student)
  topic (unique together with student_id)
  average_score
  consistency_score
  last_score
  attempts_count
  updated_at
```

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and configure:

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

**Production checklist:**
- [ ] `MOCK_MODE=false`
- [ ] `GEMINI_API_KEY` is set
- [ ] `RAG_BASE_URL` points to a running RAG service (or is unset if using direct Gemini)
- [ ] `CORS_ORIGINS` is restricted to actual frontend domains
- [ ] `DATABASE_URL` uses PostgreSQL, not SQLite

---

## Running the Backend

```bash
# From repo root
uv --directory backend run uvicorn app.main:app --reload

# Or from backend/ directory
cd backend
uv run uvicorn app.main:app --reload
```

Backend runs on `http://127.0.0.1:8000`.

**For Windows:**
```bash
start_backend.bat
```

---

## API Contract Summary

### Already Implemented

```
GET  /health
POST /student/register       { name, email, grade_level }
GET  /student/{id}
POST /exam/generate          { student_id, subject, class_level, topic?, difficulty?, num_questions? }
POST /exam/submit            { student_id, exam_id, answers }
```

### To Be Added (per this guide)

```
POST /student/login          { email, password }
GET  /student/{id}/exams
GET  /student/{id}/attempts
GET  /student/{id}/weak-topics
GET  /exam/{id}/attempts
```

---

## Completion Checklist

- [ ] Fix `RAG_TIMEOUT_SECONDS` default to `60.0`
- [ ] Fix `MOCK_MODE` default to `False`
- [ ] Add `google-genai` to `backend/pyproject.toml`
- [ ] Add structured logging
- [ ] Add transaction rollback safety
- [ ] Implement short-answer LLM grading
- [ ] Add exam / attempt history endpoints
- [ ] Add idempotency key to exam submission
- [ ] Implement JWT authentication
- [ ] Set up Alembic migrations
- [ ] Write pytest suite
- [ ] Add cascade deletes on Student relationships
- [ ] Add input size validation
- [ ] Add rate limiting
- [ ] Tighten CORS for production
