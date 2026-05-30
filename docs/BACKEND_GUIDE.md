# Backend Completion Guide

## Overview

The ShikkhaAI backend is a **FastAPI** application that handles student registration, exam generation, answer submission, grading, and performance profiling. It is architected as a clean layered system:

```
Client → Routes → Schemas → Services → DB / External Clients
```

The backend is a **solid MVP scaffold** — the core happy path (register → generate exam → submit → grade MCQ + short-answer → compute readiness → detect weak topics) works. JWT authentication has been implemented, protecting all exam and student-data endpoints.

---

## Current State

### ✅ What Works

| Endpoint | Method | Auth | Status |
|----------|--------|------|--------|
| `/health` | GET | Public | Returns `status` and `mock_mode` flag |
| `/student/register` | POST | Public | Validates email, hashes password with bcrypt, returns student + JWT token |
| `/student/login` | POST | Public | Verifies bcrypt password, returns JWT token + student |
| `/student/{id}` | GET | Bearer | Fetches student by ID (ownership enforced) |
| `/student/{id}/exams` | GET | Bearer | Lists all exams for a student (ownership enforced) |
| `/student/{id}/attempts` | GET | Bearer | Lists all attempts for a student (ownership enforced) |
| `/student/{id}/weak-topics` | GET | Bearer | Returns weak topics for a student (ownership enforced) |
| `/student/{id}/dashboard` | GET | Bearer | Returns dashboard snapshot: readiness, weak subjects, streak, recent quizzes, recommendations |
| `/student/{id}/analytics` | GET | Bearer | Returns comprehensive analytics: topic accuracy, weak chapters, improvement history, streak data, practice suggestions |
| `/student/{id}/topics` | GET | Bearer | Returns curriculum topics grouped by subject with completion percentages |
| `/exam/generate` | POST | Bearer | Generates exam via RAG / Gemini / Mock fallback (ownership enforced) |
| `/exam/submit` | POST | Bearer | Submits answers, grades MCQ + short-answer via Gemini, computes readiness, auto-generates notes for weak topics (ownership enforced) |
| `/exam/{id}/attempts` | GET | Bearer | Lists attempts for a specific exam (ownership enforced) |
| `/notes` | POST | Bearer | Creates a new note (ownership enforced) |
| `/notes` | GET | Bearer | Lists notes with optional `topic` / `source` filters (ownership enforced) |
| `/notes/{id}` | GET | Bearer | Fetches a single note (ownership enforced) |
| `/notes/{id}` | DELETE | Bearer | Deletes a note (ownership enforced) |

### ✅ Already Implemented (Previously Listed as To-Do)

| Item | File | Notes |
|------|------|-------|
| Dedicated `SECRET_KEY` for JWT | `app/core/config.py` | `secret_key` field with safe default; `security.py` uses it |
| `RAG_TIMEOUT_SECONDS` default | `app/core/config.py` | Defaults to `60.0` |
| `MOCK_MODE` default | `app/core/config.py` | Defaults to `False` |
| Transaction safety | `app/db/transactions.py` | `safe_commit()` wraps all commits with rollback |
| Short-answer LLM grading | `app/services/grading_service.py` | Real Gemini-based grading with partial credit and feedback |
| Structured logging | Routes & services | `logging.getLogger("shikkhaai")` used throughout |

### ⚠️ Partially Working

- **Weak-topic detection**: Computes local weak topics correctly from `TopicPerformance`, but the RAG HTTP fallback (`POST /weak-topics`) is **unimplemented on the RAG service side** (`rag/rag_router.py`), so it silently falls back to local-only logic.
- **RAG client fallback chain**: Well-architected 4-tier cascade (Mock → In-process RAG → Direct Gemini → HTTP RAG). Works when configured.

### ❌ Missing / Broken

| Issue | Impact |
|-------|--------|
| No `POST /study-companion/ask` | Study Companion chat returns mock text |
| No `POST /study-plan/generate` | Study Plan is locally generated only |
| No `POST /rag/ask` on RAG service | Study Companion cannot retrieve curriculum book context |
| `POST /weak-topics` missing on RAG service | RAG-side weak topic enrichment never runs |
| No idempotency on exam submission | Double-submit creates duplicate attempts |
| No database migrations | Schema changes require manual DB wipe |
| No tests | Zero test coverage |
| No rate limiting | No protection against abuse |
| No input size validation on JSON blobs | Malformed upstream JSON can crash serialization |

---

## API Reference

### Implemented Endpoints

The following endpoints are **fully implemented** and wired to the frontend:

#### 1. Dashboard Endpoint ✅

**`GET /student/{id}/dashboard`**

Returns a consolidated snapshot for the dashboard screen:

```json
{
  "success": true,
  "data": {
    "readiness": { "overall": 74.0, "trend": 5.2, "breakdown": {"Conceptual": 78} },
    "weak_subjects": [{"name": "Physics", "accuracy": 52.0, "color": "#6366F1", "icon": "science"}],
    "streak": { "current_streak": 12, "longest_streak": 18, "weekly_activity": [...], "last_study_date": "2026-05-22" },
    "improvement": [{"week": "W1", "score": 58.0}],
    "topic_accuracy": [{"topic": "Algebra", "accuracy": 82.0, "total_questions": 45}],
    "recent_quizzes": [{"id": "1", "title": "Class 8 Science Mid-Term", "subject": "Science", "score": 18, "total": 25, "date": "2026-05-22", "time_taken": "14 min"}],
    "recommendations": [{"id": "r1", "title": "Master Newton's Laws", "description": "...", "type": "study", "priority": "high"}]
  }
}
```

**Implementation:** `backend/app/services/dashboard_service.py` — derives all metrics from `Attempt` + `TopicPerformance` tables.

#### 2. Analytics Endpoint ✅

**`GET /student/{id}/analytics`**

Returns comprehensive weakness analytics:

```json
{
  "success": true,
  "data": {
    "topic_accuracy": [{"topic": "Force & Motion", "chapter": "Newton's Laws", "subject": "Physics", "accuracy": 85.0, "total_questions": 40, "correct_answers": 34, "trend": 5.0, "last_attempted": "2026-05-27"}],
    "weak_chapters": [{"chapter_name": "Trigonometry", "subject": "Mathematics", "accuracy": 35.0, "weakness_rank": 1, "related_topics": [...], "suggested_action": "...", "trend": -10.0, "time_spent_minutes": 45}],
    "improvement_history": [{"date": "2026-04-27", "overall_score": 45.0, "topic_scores": {"Force & Motion": 60.0}, "exam_id": "exam_001"}],
    "streak_data": {"current_streak": 12, "longest_streak": 18, "last_30_days": [{"date": "2026-04-27", "is_active": true, "performance_score": 65.0, "questions_answered": 20, "study_minutes": 45}]},
    "practice_suggestions": [{"id": "sugg_1", "title": "Trig Identity Drills", "description": "...", "topic": "Trigonometry", "type": "quickPractice", "difficulty": "medium", "estimated_minutes": 15, "potential_impact": 85.0, "subject": "Mathematics"}],
    "average_accuracy": 62.5,
    "total_questions_attempted": 342,
    "total_study_minutes": 1280
  }
}
```

**Implementation:** `backend/app/services/analytics_service.py`.

#### 3. Topics Endpoint ✅

**`GET /student/{id}/topics`**

Returns all curriculum topics for the student's class level, grouped by subject, with per-topic completion status derived from `TopicPerformance`.

```json
{
  "success": true,
  "data": {
    "subjects": [
      {
        "subject": "Science",
        "icon_name": "science",
        "total_topics": 15,
        "completed_topics": 8,
        "overall_completion_percentage": 53.3,
        "topics": [
          {"id": "topic_001", "name": "Force and Motion", "completion_percentage": 85.0, "attempts_count": 3, "last_score": 90.0, "last_attempted": "2026-05-20", "is_completed": true}
        ]
      }
    ],
    "total_topics": 42,
    "completed_topics": 15
  }
}
```

**Implementation:** `backend/app/services/analytics_service.py` — queries `CurriculumTopic` and left-joins with `TopicPerformance`. Falls back to attempt history if no curriculum is seeded.

#### 4. Notes CRUD Endpoints ✅

**`POST /notes`**, **`GET /notes`**, **`GET /notes/{id}`**, **`DELETE /notes/{id}`**

All note endpoints require Bearer token authentication. Ownership is enforced.

**Implementation files:**
- `backend/app/schemas/note.py` — `NoteCreate`, `NoteResponse`
- `backend/app/services/note_service.py` — CRUD operations
- `backend/app/api/routes_notes.py` — FastAPI router

**Auto-generation on exam submit:**
After `POST /exam/submit`, the `ExamService` automatically calls `NoteGenerationService.generate_notes_for_weak_topics()` to create personalized study notes for each weak topic using Gemini. These notes are saved with `source="practice"` and appear in the student's library.

---

## Still To Implement

### 5. Topic-Specific Practice Quiz Generation

**`POST /practice/generate`** *(or reuse `/exam/generate` with `practice_mode: true`)*

When a student clicks "Practice Now" on a weak chapter, generate a short focused quiz.

### 6. Topic Notes / Suggestions Endpoint

**`POST /study-companion/topic-notes`**

Returns AI-generated study notes or suggestions for a weak topic.

### 7. Study Companion Chat Endpoint (RAG-Powered)

**`POST /study-companion/ask`**

The Study Companion must use the **RAG system** so students can ask questions about the curriculum book already stored in ChromaDB.

### 8. Study Plan Generation Endpoint

**`POST /study-plan/generate`**

Generates a personalized study plan using Gemini, based on the student's weak topics, exam date, and daily study budget.

### 9. RAG Service Endpoints

**`POST /rag/weak-topics`** and **`POST /rag/ask`** *(in `rag/rag_router.py`)*

The RAG service needs endpoints for weak topic enrichment and curriculum-aware Q&A.

---

---

## Database Schema Reference

```
Student
  id (PK)
  name
  email (unique)
  grade_level
  password (nullable — existing pre-auth records have NULL)
  created_at
  updated_at

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
  source
  created_at

Attempt
  id (PK)
  student_id (FK → Student)
  exam_id (FK → Exam)
  answers (JSON)
  score_percentage
  mcq_correct
  mcq_total
  short_answer_feedback (JSON)
  weak_topics (JSON)
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

Note
  id (PK)
  student_id (FK → Student)
  title
  content (markdown text)
  topic (grouping key)
  subject
  class_level
  source ('study_companion' | 'practice' | 'topic_notes')
  created_at
  updated_at

StudyPlan
  id (PK)
  student_id (FK → Student)
  title
  exam_date (date)
  daily_minutes (int)
  is_active (bool, default true)
  created_at
  updated_at

StudyPlanTask
  id (PK)
  plan_id (FK → StudyPlan)
  title
  description
  subject
  topic
  duration_minutes (int)          -- planned time
  actual_minutes_spent (int, default 0)  -- actual time recorded by timer
  type ('reading' | 'practice' | 'revision' | 'mockTest')
  scheduled_date (date)
  is_completed (bool, default false)
  completed_at (datetime, nullable)
  created_at

CurriculumTopic
  id (PK)
  class_level
  subject
  topic
  display_order (int, default 0)
  unique: (class_level, subject, topic)
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
SECRET_KEY=your-strong-random-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

**Production checklist:**
- [ ] `MOCK_MODE=false`
- [ ] `GEMINI_API_KEY` is set
- [ ] `SECRET_KEY` is set to a strong random string (for JWT signing)
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

### Public Endpoints (No Authentication)

```
GET  /health
POST /student/register       { name, email, grade_level, password }
POST /student/login          { email, password }
```

### Protected Endpoints (Bearer Token Required)

```
GET  /student/{id}
GET  /student/{id}/exams
GET  /student/{id}/attempts
GET  /student/{id}/weak-topics
GET  /student/{id}/dashboard          { readiness, weak_subjects, streak, improvement, topic_accuracy, recent_quizzes, recommendations }
GET  /student/{id}/analytics          { topic_accuracy, weak_chapters, improvement_history, streak_data, practice_suggestions, average_accuracy, total_questions_attempted, total_study_minutes }
GET  /student/{id}/topics             { subjects[], total_topics, completed_topics }
POST /exam/generate                   { student_id, subject, class_level, topic?, difficulty?, num_questions? }
POST /exam/submit                     { student_id, exam_id, answers } → grades + auto-generates study notes for weak topics
GET  /exam/{id}/attempts
POST /practice/generate               ← NEW (or reuse /exam/generate)
POST /study-companion/ask             ← NEW
POST /study-companion/topic-notes     ← NEW
POST /study-plan/generate             ← NEW
GET  /study-plan/{id}                 ← NEW
DELETE /study-plan/{id}               ← NEW
PUT  /study-plan/tasks/{task_id}/progress  ← NEW (optional)
GET  /notes                           { title, content, topic, subject, class_level, source }
POST /notes                           { title, content, topic, subject, class_level, source }
GET  /notes/{id}
DELETE /notes/{id}
```

### RAG Service Endpoints (No Authentication — Internal Only)

```
GET  /rag/health
POST /rag/generate-exam
POST /rag/retrieve
POST /rag/context
POST /rag/weak-topics                 ← NEW
POST /rag/ask                         ← NEW
```

All protected endpoints verify the `Authorization: Bearer <token>` header. The token's `sub` claim (student ID) must match the resource being accessed. Cross-student access returns `403 FORBIDDEN`.

---

## Authentication Details

### JWT Configuration

| Setting | Value |
|---------|-------|
| Algorithm | `HS256` |
| Expiry | 60 minutes (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`) |
| Secret Key | `SECRET_KEY` env var (dedicated, does NOT fall back to Gemini key) |
| Token Type | `Bearer` |
| Payload | `{ "sub": "<student_id>", "exp": <timestamp> }` |

### Password Hashing

- Algorithm: `bcrypt` via `passlib`
- Cost factor: default (12 rounds)
- Storage: `password` column on `Student` model

### Ownership Enforcement

Every protected endpoint checks that the authenticated student's ID matches the requested resource:

```python
# In routes_students.py
if current_student.id != id:
    raise AppError(code="FORBIDDEN", status_code=403, message="You can only view your own profile.")

# In routes_exams.py
_verify_student_owns_resource(current_student, payload.student_id)
```

---

## Completion Checklist

### Done ✅
- [x] Implement JWT authentication (`python-jose` + `passlib[bcrypt]`)
- [x] Add `POST /student/login` endpoint
- [x] Protect all exam and student-data endpoints with Bearer token
- [x] Enforce ownership checks (students can only access their own data)
- [x] Return token on registration
- [x] Add `password` to Student model
- [x] Add dedicated `SECRET_KEY` config (does not reuse Gemini key)
- [x] Add structured logging
- [x] Fix `RAG_TIMEOUT_SECONDS` default to `60.0`
- [x] Fix `MOCK_MODE` default to `False`
- [x] Add transaction rollback safety (`safe_commit`)
- [x] Implement short-answer LLM grading via Gemini

### Still To Do
- [ ] Add `POST /practice/generate` (or `practice_mode` flag on `/exam/generate`)
- [ ] Add `POST /study-companion/ask` endpoint (RAG-powered with `pdf_context`)
- [ ] Add `POST /study-companion/topic-notes` endpoint
- [ ] Add `POST /study-plan/generate` endpoint (Gemini-powered with weak topic context)
- [ ] Add `GET /study-plan/{id}` and `DELETE /study-plan/{id}` endpoints
- [ ] Add `PUT /study-plan/tasks/{task_id}/progress` endpoint (optional for MVP)
- [ ] Create seed script to populate `CurriculumTopic` via Gemini (`scripts/seed_curriculum.py`)
- [ ] Implement `POST /rag/ask` on RAG service (retrieval + Gemini Q&A)
- [ ] Implement `POST /rag/weak-topics` on RAG service
- [ ] Add idempotency key to exam submission
- [ ] Set up Alembic migrations
- [ ] Write pytest suite
- [ ] Add input size validation
- [ ] Add rate limiting
- [ ] Tighten CORS for production
