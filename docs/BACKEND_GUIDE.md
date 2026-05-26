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
| `/exam/generate` | POST | Bearer | Generates exam via RAG / Gemini / Mock fallback (ownership enforced) |
| `/exam/submit` | POST | Bearer | Submits answers, grades MCQ + short-answer via Gemini, computes readiness (ownership enforced) |
| `/exam/{id}/attempts` | GET | Bearer | Lists attempts for a specific exam (ownership enforced) |

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
| No `GET /student/{id}/dashboard` | Dashboard screen has no data source |
| No `GET /student/{id}/analytics` | Analytics screen has no data source |
| No `POST /study-companion/ask` | Study Companion chat returns mock text |
| No `POST /study-plan/generate` | Study Plan is locally generated only |
| No `CurriculumTopic` catalog | Topics tab cannot show remaining unattempted topics |
| No `GET /student/{id}/topics` | Topics tab has no data source |
| No `POST /rag/ask` on RAG service | Study Companion cannot retrieve curriculum book context |
| No library endpoints | Library feature is a shell |
| `POST /weak-topics` missing on RAG service | RAG-side weak topic enrichment never runs |
| No idempotency on exam submission | Double-submit creates duplicate attempts |
| No database migrations | Schema changes require manual DB wipe |
| No tests | Zero test coverage |
| No rate limiting | No protection against abuse |
| No input size validation on JSON blobs | Malformed upstream JSON can crash serialization |

---

## New API Requirements (For Analytics & Personalized Learning)

Based on the frontend analytics flow, the following backend endpoints are needed:

### 1. Dashboard Endpoint

**`GET /student/{id}/dashboard`**

Returns a consolidated snapshot for the dashboard screen:

```json
{
  "success": true,
  "data": {
    "readiness": {
      "overall": 74.0,
      "trend": 5.2,
      "breakdown": {"Conceptual": 78, "Problem Solving": 65}
    },
    "weak_subjects": [
      {"name": "Physics", "accuracy": 52.0, "color": "#6366F1", "icon": "science"}
    ],
    "streak": {
      "current_streak": 12,
      "longest_streak": 18,
      "weekly_activity": [true, true, false, true, true, true, false],
      "last_study_date": "2026-05-22"
    },
    "improvement": [
      {"week": "W1", "score": 58.0}
    ],
    "topic_accuracy": [
      {"topic": "Algebra", "accuracy": 82.0, "total_questions": 45}
    ],
    "recent_quizzes": [
      {"id": "1", "title": "Class 8 Science Mid-Term", "subject": "Science", "score": 18, "total": 25, "date": "2026-05-22", "time_taken": "14 min"}
    ],
    "recommendations": [
      {"id": "r1", "title": "Master Newton's Laws", "description": "...", "type": "study", "priority": "high"}
    ]
  }
}
```

**Implementation notes:**
- Derive `readiness` from latest attempt's `readiness_score` + `TopicPerformance` consistency.
- Derive `weak_subjects` from `TopicPerformance` rows where `average_score < 60`.
- Derive `recent_quizzes` from the student's `Attempt` + `Exam` history.
- `recommendations` can be rule-based for MVP (e.g., if weak in X, recommend X practice).

### 2. Analytics Endpoint

**`GET /student/{id}/analytics`**

Returns comprehensive weakness analytics:

```json
{
  "success": true,
  "data": {
    "topic_accuracy": [
      {
        "topic": "Force & Motion",
        "chapter": "Newton's Laws",
        "subject": "Physics",
        "accuracy": 85.0,
        "total_questions": 40,
        "correct_answers": 34,
        "trend": 5.0,
        "last_attempted": "2026-05-27"
      }
    ],
    "weak_chapters": [
      {
        "chapter_name": "Trigonometry",
        "subject": "Mathematics",
        "accuracy": 35.0,
        "weakness_rank": 1,
        "related_topics": ["Sine/Cosine", "Identities"],
        "suggested_action": "Focus on basic trig ratios first...",
        "trend": -10.0,
        "time_spent_minutes": 45
      }
    ],
    "improvement_history": [
      {
        "date": "2026-04-27",
        "overall_score": 45.0,
        "topic_scores": {"Force & Motion": 60.0},
        "exam_id": "exam_001"
      }
    ],
    "streak_data": {
      "current_streak": 12,
      "longest_streak": 18,
      "last_30_days": [
        {"date": "2026-04-27", "is_active": true, "performance_score": 65.0, "questions_answered": 20, "study_minutes": 45}
      ]
    },
    "practice_suggestions": [
      {
        "id": "sugg_1",
        "title": "Trig Identity Drills",
        "description": "Master fundamental identities...",
        "topic": "Trigonometry",
        "type": "quickPractice",
        "difficulty": "medium",
        "estimated_minutes": 15,
        "potential_impact": 85.0,
        "subject": "Mathematics"
      }
    ],
    "average_accuracy": 62.5,
    "total_questions_attempted": 342,
    "total_study_minutes": 1280
  }
}
```

**Implementation notes:**
- `topic_accuracy` → aggregate from `Attempt` + `Exam` question-level results.
- `weak_chapters` → derived from `TopicPerformance` where `average_score < 60` or `consistency_score < 50`.
- `improvement_history` → one point per attempt, tracking `score_percentage` over time.
- `streak_data` → derived from attempt dates; `last_30_days` should have one entry per day.
- `practice_suggestions` → can be rule-based or generated by Gemini for MVP.

### 3. Topic-Specific Practice Quiz Generation

**`POST /practice/generate`** *(or reuse `/exam/generate` with `practice_mode: true`)*

When a student clicks "Practice Now" on a weak chapter, generate a short focused quiz:

```json
// Request
{
  "student_id": 1,
  "subject": "Mathematics",
  "topic": "Trigonometry",
  "class_level": "8",
  "difficulty": "easy",
  "num_questions": 5,
  "practice_mode": true
}

// Response — same shape as /exam/generate
{
  "success": true,
  "data": {
    "exam_id": 42,
    "questions": [...],
    "source": "rag"
  }
}
```

**Implementation notes:**
- Can reuse the existing `ExamService.generate_exam()` logic.
- If adding `practice_mode`, store it on the `Exam` model or treat it the same as a regular exam.
- The frontend will then navigate to the existing exam session screen.

### 4. Topic Notes / Suggestions Endpoint

**`POST /study-companion/topic-notes`**

Returns AI-generated study notes or suggestions for a weak topic:

```json
// Request
{
  "student_id": 1,
  "topic": "Trigonometry",
  "subject": "Mathematics",
  "class_level": "8"
}

// Response
{
  "success": true,
  "data": {
    "notes": "Trigonometry is about relationships between angles and sides...",
    "key_formulas": ["sin²θ + cos²θ = 1", "tanθ = sinθ/cosθ"],
    "common_mistakes": ["Confusing sin and cos", "Forgetting to check quadrant"],
    "suggested_resources": ["Practice problems on identities", "Video: Basic trig ratios"]
  }
}
```

**Implementation notes:**
- Call Gemini with a structured prompt to generate notes for the given topic/class level.
- Alternatively, extend the `GET /student/{id}/analytics` response to include `topic_notes` per weak chapter.

### 5. Study Companion Chat Endpoint (RAG-Powered)

**`POST /study-companion/ask`**

The Study Companion must use the **RAG system** so students can ask questions about the curriculum book (e.g., Class 8 Science) already stored in ChromaDB. When a student uploads a PDF, the extracted text is included so Gemini can cross-reference the PDF with the book.

```json
// Request
{
  "student_id": 1,
  "message": "solve the maths of this pdf",
  "mode": "easyEnglish",
  "subject": "science",
  "class_level": "8",
  "pdf_context": "The uploaded PDF contains: 1. A triangle ABC with sides..."
}

// Response
{
  "success": true,
  "data": {
    "response": "Here is the step-by-step solution using the Pythagorean theorem from your book...",
    "sources": [
      {"source": "class_8_science_eng.pdf", "page": 12, "relevance_score": 0.92}
    ]
  }
}
```

**Implementation notes:**
- Backend calls `rag_client.ask(payload)` which proxies to the RAG service (`POST /rag/ask`).
- The RAG service retrieves relevant chunks from the curriculum book, then prompts Gemini with:
  - Retrieved book chunks (formulas, concepts)
  - Uploaded PDF text (if `pdf_context` provided)
  - Explanation mode instructions
- Do not expose the Gemini API key to the frontend.
- Return `sources` so the frontend can show "📖 Class 8 Science — Page 12" citations.

### 6. Study Plan Generation Endpoint

**`POST /study-plan/generate`**

Generates a personalized study plan using Gemini, based on the student's weak topics, exam date, and daily study budget.

**Request Flow:**
1. Fetch student's `TopicPerformance` rows to enrich the prompt with actual scores.
2. Fetch student's `Attempt` history to include recent weak topics.
3. Call `GET /student/{id}/weak-topics` logic internally to get the definitive weak topic list.
4. Construct a detailed prompt for Gemini with Bangladeshi curriculum context.
5. Parse Gemini's JSON response into a structured plan.
6. Persist the plan to `StudyPlan` + `StudyPlanTask` tables.
7. Return the full plan to the frontend.

```json
// Request
{
  "student_id": 1,
  "exam_date": "2026-06-15",
  "daily_minutes": 60,
  "weak_subjects": ["Algebra", "Photosynthesis"],
  "class_level": "8",
  "subject": "Mathematics"
}

// Response
{
  "success": true,
  "data": {
    "plan_id": "plan_001",
    "title": "Exam Prep Plan",
    "exam_date": "2026-06-15",
    "daily_minutes": 60,
    "days": [
      {
        "date": "2026-05-27",
        "tasks": [
          {
            "id": "t1",
            "title": "Algebra basics",
            "description": "Solve 10 linear equation problems",
            "subject": "Mathematics",
            "topic": "Algebra",
            "duration_minutes": 30,
            "type": "practice",
            "is_completed": false,
            "actual_minutes_spent": 0
          }
        ],
        "is_rest_day": false
      }
    ]
  }
}
```

**Gemini Prompt Structure:**

```
You are a Bangladeshi academic advisor. Create a study plan for a Class {class_level} student preparing for a {subject} exam on {exam_date}.

Student Profile:
- Daily study budget: {daily_minutes} minutes
- Weak topics (with scores): {weak_topics_with_scores}
- Days until exam: {days_left}

Requirements:
1. Distribute weak topics across available days before the exam.
2. Every 7th day should be a rest day (is_rest_day = true, no tasks).
3. Every 6th day (after first week) should include a mock test task.
4. Each task must have: title, description, topic, subject, duration_minutes (must sum to <= daily_minutes), type (reading|practice|revision|mockTest).
5. Tasks should progressively increase in difficulty.
6. Return ONLY valid JSON matching this shape:

{
  "days": [
    {
      "date": "YYYY-MM-DD",
      "is_rest_day": false,
      "tasks": [
        {"title": "...", "description": "...", "topic": "...", "subject": "...", "duration_minutes": 30, "type": "practice"}
      ]
    }
  ]
}
```

**Implementation notes:**
- Use `google-genai` SDK (`gemini-2.5-flash`) via the root workspace dependency.
- Backend must validate Gemini output: check JSON validity, date continuity, duration sums.
- Fallback: if Gemini fails or returns invalid JSON, use template-based generation (similar to `MockStudyPlanService` logic) as a safe fallback.
- Store generated plan in `StudyPlan` + `StudyPlanTask` tables (see Section 7.1).
- The `actual_minutes_spent` field is initialized to `0` and updated by the frontend via `PUT /study-plan/tasks/{task_id}/progress`.

**`PUT /study-plan/tasks/{task_id}/progress`** *(Optional for MVP — timer is local-only)*

Records actual time spent and completion status for a task. Called by the frontend when the user finishes a study session.

```json
// Request
{
  "actual_minutes_spent": 45,
  "is_completed": true
}

// Response
{
  "success": true,
  "data": {
    "task_id": "t1",
    "actual_minutes_spent": 45,
    "is_completed": true,
    "completed_at": "2026-05-27T11:45:00Z"
  }
}
```

**`GET /study-plan/{id}`**

Fetch a generated plan by ID, including all days and tasks. Ownership-enforced.

**`DELETE /study-plan/{id}`**

Delete a plan and all its tasks. Ownership-enforced.

### 7. Topics Endpoint

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
          {
            "id": "topic_001",
            "name": "Force and Motion",
            "completion_percentage": 85.0,
            "attempts_count": 3,
            "last_score": 90.0,
            "last_attempted": "2026-05-20",
            "is_completed": true
          },
          {
            "id": "topic_002",
            "name": "Acids, Bases and Salts",
            "completion_percentage": 0.0,
            "attempts_count": 0,
            "last_score": null,
            "last_attempted": null,
            "is_completed": false
          }
        ]
      }
    ],
    "total_topics": 42,
    "completed_topics": 15
  }
}
```

**Implementation Notes:**
1. Look up the student's `grade_level` from the `Student` table.
2. Query `CurriculumTopic` where `class_level = student.grade_level` to get the full topic catalog.
3. Left-join with `TopicPerformance` on `(student_id, topic)` to get attempt stats.
4. Compute `completion_percentage`:
   - If `TopicPerformance` exists: `TopicPerformance.average_score`
   - If no attempts: `0.0`
5. `is_completed` = `completion_percentage >= 60.0` (matches the existing weak-topic threshold).
6. Group by `subject` and compute aggregates (`total_topics`, `completed_topics`, `overall_completion_percentage`).
7. Ownership-enforced: only return data for the authenticated student.

#### 7.1 Curriculum Topic Catalog

The backend needs a predefined list of topics per subject and class level so it can report "remaining" (unattempted) topics.

**Add a `CurriculumTopic` model:**

```python
class CurriculumTopic(Base):
    __tablename__ = "curriculum_topics"
    id = Column(Integer, primary_key=True)
    class_level = Column(String, nullable=False, index=True)
    subject = Column(String, nullable=False, index=True)
    topic = Column(String, nullable=False)
    display_order = Column(Integer, default=0)
    __table_args__ = (UniqueConstraint("class_level", "subject", "topic"),)
```

**Seeding the catalog:**

Create a management script (`scripts/seed_curriculum.py`) that calls Gemini to generate the initial topic list:

```python
prompt = f"""
List all topics covered in the Class {class_level} Bangladeshi {subject} curriculum.
Return ONLY a JSON array of topic names:
["Topic 1", "Topic 2", ...]
"""
```

Store the results in `CurriculumTopic`. Run this script once per new class/subject combination.

Alternative: store curriculum topics as static JSON files (`data/curriculum/class_8_science.json`) and load them at startup. Simpler but less flexible for dynamic updates.

---

### 8. RAG Service Weak Topics Endpoint

**`POST /rag/weak-topics`** *(in `rag/rag_router.py`)*

The backend's `RagClient.detect_weak_topics()` already calls this, but the endpoint is missing:

```python
@router.post("/weak-topics")
def detect_weak_topics(payload: dict):
    # Accepts {"student_id": 1, "topics": [{"topic": "...", "score": 45, ...}]}
    # Returns {"weak_topics": [{"topic": "...", "reason": "...", "score": ...}]}
    # Can be a simple pass-through or enriched with RAG context
```

---

### 9. RAG Service Ask Endpoint

**`POST /rag/ask`** *(in `rag/rag_router.py`)*

The RAG service must expose a new endpoint for curriculum-aware Q&A:

```json
// Request
{
  "query": "solve the maths of this pdf",
  "subject": "science",
  "class_level": "8",
  "explanation_mode": "easyEnglish",
  "pdf_context": "The uploaded PDF contains..."
}

// Response
{
  "answer": "Here is the step-by-step solution...",
  "sources": [
    {"source": "class_8_science_eng.pdf", "page": 12, "relevance_score": 0.92, "snippet": "Pythagorean theorem: a² + b² = c²"}
  ]
}
```

**Implementation notes:**
1. Embed the `query` and retrieve top-5 chunks from ChromaDB filtered by `subject` + `class`.
2. Build a system prompt that includes:
   - Retrieved book chunks
   - `pdf_context` (if provided)
   - Explanation mode instruction (see mode mapping below)
3. Call Gemini `gemini-2.5-flash` with the assembled prompt.
4. Return the generated answer + source metadata.

**Explanation Mode → Prompt Mapping:**

| `explanation_mode` | Prompt Instruction |
|-------------------|-------------------|
| `easyBengali` | "Answer in simple Bengali (Bangla) that a Class 8 student can understand." |
| `easyEnglish` | "Answer in simple English that a Class 8 student can understand." |
| `explainLike10` | "Explain as if talking to a 10-year-old child." |
| `summary` | "Provide a concise summary with bullet points." |
| `importantQuestions` | "Frame the answer around likely exam questions and their answers." |
| `commonMistakes` | "Highlight common mistakes students make on this topic and how to avoid them." |
| `examTips` | "Focus on exam preparation tips, shortcuts, and scoring strategies." |

---

### 10. Notes CRUD Endpoints

**`POST /notes`**

Create a new saved note for the authenticated student.

```json
// Request
{
  "title": "Newton's Laws Summary",
  "content": "## First Law\nAn object remains at rest or in uniform motion unless acted upon by a force...",
  "topic": "Force & Motion",
  "subject": "Physics",
  "class_level": "8",
  "source": "study_companion"
}

// Response
{
  "success": true,
  "data": {
    "id": 1,
    "title": "Newton's Laws Summary",
    "content": "## First Law\nAn object remains at rest...",
    "topic": "Force & Motion",
    "subject": "Physics",
    "class_level": "8",
    "source": "study_companion",
    "created_at": "2026-05-27T10:00:00Z",
    "updated_at": null
  }
}
```

**`GET /notes`**

List all notes for the authenticated student. Supports filtering:

```
GET /notes?topic=Force%20%26%20Motion&source=study_companion
```

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Newton's Laws Summary",
      "content": "## First Law...",
      "topic": "Force & Motion",
      "subject": "Physics",
      "class_level": "8",
      "source": "study_companion",
      "created_at": "2026-05-27T10:00:00Z",
      "updated_at": null
    }
  ]
}
```

**`GET /notes/{id}`**

Fetch a single note by ID. Returns `404 NOT_FOUND` if the note does not exist or belongs to another student.

**`DELETE /notes/{id}`**

Delete a note by ID. Returns `404 NOT_FOUND` if the note does not exist or belongs to another student.

**Implementation notes:**
- All note endpoints require Bearer token authentication.
- Ownership is enforced — students can only access their own notes.
- `source` values: `study_companion`, `practice`, `topic_notes`.
- `topic` is the primary grouping key used by the frontend Library screen.
- Content is stored as markdown (the same markdown returned by Study Companion or generated by topic notes).

**New files to create:**
- `backend/app/schemas/note.py` — `NoteCreate`, `NoteUpdate`, `NoteResponse`
- `backend/app/services/note_service.py` — `create_note()`, `list_notes()`, `get_note()`, `delete_note()`
- `backend/app/api/routes_notes.py` — FastAPI router with the four endpoints above
- Update `backend/app/main.py` — mount `notes_router` at `/notes`
- Update `backend/app/db/models.py` — add `Note` SQLAlchemy model

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
GET  /student/{id}/dashboard          ← NEW
GET  /student/{id}/analytics          ← NEW
POST /exam/generate                   { student_id, subject, class_level, topic?, difficulty?, num_questions? }
POST /exam/submit                     { student_id, exam_id, answers }
GET  /exam/{id}/attempts
POST /practice/generate               ← NEW (or reuse /exam/generate)
POST /study-companion/ask             ← NEW
POST /study-companion/topic-notes     ← NEW
POST /study-plan/generate             ← NEW
GET  /study-plan/{id}                 ← NEW
DELETE /study-plan/{id}               ← NEW
PUT  /study-plan/tasks/{task_id}/progress  ← NEW (optional)
GET  /student/{id}/topics             ← NEW
GET  /notes                           ← NEW
POST /notes                           ← NEW
GET  /notes/{id}                      ← NEW
DELETE /notes/{id}                    ← NEW
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
- [ ] Add `GET /student/{id}/dashboard` endpoint
- [ ] Add `GET /student/{id}/analytics` endpoint
- [ ] Add `POST /practice/generate` (or `practice_mode` flag on `/exam/generate`)
- [ ] Add `POST /study-companion/ask` endpoint (RAG-powered with `pdf_context`)
- [ ] Add `POST /study-companion/topic-notes` endpoint
- [ ] Add `POST /study-plan/generate` endpoint (Gemini-powered with weak topic context)
- [ ] Add `StudyPlan` + `StudyPlanTask` models to `backend/app/db/models.py`
- [ ] Add `GET /study-plan/{id}` and `DELETE /study-plan/{id}` endpoints
- [ ] Add `PUT /study-plan/tasks/{task_id}/progress` endpoint (optional for MVP)
- [ ] Add `CurriculumTopic` model to `backend/app/db/models.py`
- [ ] Create seed script to populate `CurriculumTopic` via Gemini (`scripts/seed_curriculum.py`)
- [ ] Implement `GET /student/{id}/topics` endpoint
- [ ] Add `Note` model to `backend/app/db/models.py`
- [ ] Add `POST /notes`, `GET /notes`, `GET /notes/{id}`, `DELETE /notes/{id}` endpoints
- [ ] Add `NoteService` with ownership-enforced CRUD
- [ ] Implement `POST /rag/ask` on RAG service (retrieval + Gemini Q&A)
- [ ] Implement `POST /rag/weak-topics` on RAG service
- [ ] Add idempotency key to exam submission
- [ ] Set up Alembic migrations
- [ ] Write pytest suite
- [ ] Add input size validation
- [ ] Add rate limiting
- [ ] Tighten CORS for production
