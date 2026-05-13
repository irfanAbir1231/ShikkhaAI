# ShikkhaAI Backend Design

## 1. System Architecture

ShikkhaAI is a production-oriented JSON API backend for an AI-powered education system. The backend is responsible for student lifecycle management, exam orchestration, answer submission, grading, student profile updates, topic weakness detection, and readiness scoring.

The backend does not implement retrieval augmented generation (RAG) internally. Instead, it integrates with an external RAG service through a small HTTP client. The rest of the application can run in mock-first mode so frontend and backend teams can develop independently while the RAG service is unavailable or incomplete.

### Primary Responsibilities

- Register and fetch students.
- Request generated exams from an external RAG service.
- Fall back to deterministic mock exams when the external RAG service is unavailable.
- Accept exam submissions as JSON.
- Grade MCQ answers locally using exact-match scoring.
- Provide a short-answer grading hook that can later call an LLM grading service.
- Store exam attempts and topic-level performance.
- Detect weak topics using topic performance and optional RAG feedback.
- Compute readiness scores from exam performance and topic consistency.

### Layered Architecture

```text
Client / Frontend
  |
  | JSON over HTTP
  v
FastAPI Routes
  |
  | validate request / shape response
  v
Service Layer
  |
  | business logic, scoring, profiling
  v
Database Layer          External Clients
PostgreSQL + SQLAlchemy RAG HTTP API via httpx
```

### Runtime Components

- **FastAPI application**: API entrypoint, router registration, CORS, startup hooks.
- **API routers**: Thin route handlers for student and exam endpoints.
- **Schemas**: Pydantic request and response contracts with strict JSON validation.
- **Services**: Business logic for students, exams, grading, profiles, and readiness.
- **Database models**: SQLAlchemy ORM models for PostgreSQL persistence.
- **External clients**: HTTP clients for external AI/RAG services with mock fallback.
- **Core configuration**: Environment-driven app settings.

## 2. Folder Structure

The implementation lives inside the `backend/` uv project.

```text
backend/
  pyproject.toml
  uv.lock
  .venv/
  .env.example
  README.md
  app/
    __init__.py
    main.py
    api/
      __init__.py
      routes_students.py
      routes_exams.py
    core/
      __init__.py
      config.py
      responses.py
    db/
      __init__.py
      base.py
      session.py
      models.py
    schemas/
      __init__.py
      student.py
      exam.py
    services/
      __init__.py
      student_service.py
      exam_service.py
      grading_service.py
      profile_service.py
    external/
      __init__.py
      rag_client.py
    utils/
      __init__.py
```

### Folder Responsibilities

- `app/main.py`: Creates the FastAPI app, enables CORS, initializes database tables, and includes routers.
- `app/api/`: HTTP route definitions. Routes should remain thin and delegate logic to services.
- `app/core/`: Configuration and shared response helpers.
- `app/db/`: SQLAlchemy engine/session setup and ORM models.
- `app/schemas/`: Pydantic input/output contracts.
- `app/services/`: Business logic and orchestration.
- `app/external/`: External API integrations, including the RAG client.
- `app/utils/`: Shared utility functions reserved for future small helpers.

## 3. Database Schema

Database: PostgreSQL  
ORM: SQLAlchemy  
Primary key type: integer identity columns for MVP simplicity.

### `students`

Stores registered student profile basics.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | Integer PK | Yes | Auto-incrementing student ID |
| `name` | String(120) | Yes | Student full name |
| `email` | String(255) | Yes | Unique email |
| `grade_level` | String(50) | Yes | Example: `Class 10`, `HSC`, `Grade 8` |
| `created_at` | DateTime | Yes | UTC creation timestamp |
| `updated_at` | DateTime | Yes | UTC update timestamp |

Relationships:

- One student has many exam attempts.
- One student has many topic performance rows.

### `exams`

Stores generated exams and their answer keys.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | Integer PK | Yes | Auto-incrementing exam ID |
| `student_id` | Integer FK | Yes | References `students.id` |
| `subject` | String(100) | Yes | Exam subject |
| `topic` | String(150) | Yes | Main requested topic |
| `difficulty` | String(50) | Yes | Example: `easy`, `medium`, `hard` |
| `questions` | JSON | Yes | Generated question payload |
| `answer_key` | JSON | Yes | Answer key used for grading |
| `source` | String(50) | Yes | `rag` or `mock` |
| `created_at` | DateTime | Yes | UTC creation timestamp |

Relationships:

- One exam belongs to one student.
- One exam can have many attempts.

### `attempts`

Stores submitted answers and grading results.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | Integer PK | Yes | Auto-incrementing attempt ID |
| `student_id` | Integer FK | Yes | References `students.id` |
| `exam_id` | Integer FK | Yes | References `exams.id` |
| `answers` | JSON | Yes | Student submitted answers |
| `score_percentage` | Float | Yes | Final score from 0 to 100 |
| `mcq_correct` | Integer | Yes | Number of correct MCQs |
| `mcq_total` | Integer | Yes | Total MCQs graded |
| `short_answer_feedback` | JSON | Yes | Placeholder grading feedback |
| `weak_topics` | JSON | Yes | Weak topics returned to client |
| `readiness_score` | Float | Yes | Weighted readiness score from 0 to 100 |
| `created_at` | DateTime | Yes | UTC creation timestamp |

Relationships:

- One attempt belongs to one student.
- One attempt belongs to one exam.

### `topic_performance`

Tracks topic-level performance over time.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | Integer PK | Yes | Auto-incrementing row ID |
| `student_id` | Integer FK | Yes | References `students.id` |
| `topic` | String(150) | Yes | Topic name |
| `attempts_count` | Integer | Yes | Number of attempts touching the topic |
| `average_score` | Float | Yes | Rolling average score from 0 to 100 |
| `consistency_score` | Float | Yes | Stability score from 0 to 100 |
| `last_score` | Float | Yes | Most recent score for the topic |
| `updated_at` | DateTime | Yes | UTC update timestamp |

Relationships:

- One row belongs to one student.

## 4. API Contracts

All endpoints return JSON only. The standard response envelope is:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

Error responses use:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

### POST `/student/register`

Registers a new student.

Request:

```json
{
  "name": "Ayesha Rahman",
  "email": "ayesha@example.com",
  "grade_level": "Class 10"
}
```

Success response:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ayesha Rahman",
    "email": "ayesha@example.com",
    "grade_level": "Class 10"
  },
  "error": null
}
```

### GET `/student/{id}`

Fetches one student by ID.

Success response:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ayesha Rahman",
    "email": "ayesha@example.com",
    "grade_level": "Class 10"
  },
  "error": null
}
```

### POST `/exam/generate`

Generates an exam through the external RAG service. If the RAG service is unavailable, returns a static mock exam.

Request:

```json
{
  "student_id": 1,
  "subject": "Mathematics",
  "topic": "Quadratic Equations",
  "difficulty": "medium",
  "num_questions": 5
}
```

Success response:

```json
{
  "success": true,
  "data": {
    "exam_id": 10,
    "student_id": 1,
    "subject": "Mathematics",
    "topic": "Quadratic Equations",
    "difficulty": "medium",
    "source": "mock",
    "questions": [
      {
        "id": "q1",
        "type": "mcq",
        "topic": "Quadratic Equations",
        "prompt": "What is the standard form of a quadratic equation?",
        "options": ["ax^2 + bx + c = 0", "ax + b = 0", "a/x + b = 0", "x = a + b"],
        "marks": 1
      }
    ]
  },
  "error": null
}
```

### POST `/exam/submit`

Submits answers, grades the attempt, updates the student profile, detects weak topics, and returns readiness.

Request:

```json
{
  "student_id": 1,
  "exam_id": 10,
  "answers": [
    {
      "question_id": "q1",
      "answer": "ax^2 + bx + c = 0"
    }
  ]
}
```

Success response:

```json
{
  "success": true,
  "data": {
    "attempt_id": 22,
    "student_id": 1,
    "exam_id": 10,
    "score_percentage": 100.0,
    "mcq_correct": 1,
    "mcq_total": 1,
    "weak_topics": [],
    "readiness_score": 100.0,
    "short_answer_feedback": []
  },
  "error": null
}
```

## 5. Data Flow Diagrams

### Student Registration

```text
Client
  -> POST /student/register
  -> StudentCreate schema validation
  -> student_service.register_student
  -> SQLAlchemy session inserts students row
  -> StudentResponse returned in JSON envelope
```

### Exam Generation

```text
Client
  -> POST /exam/generate
  -> ExamGenerateRequest schema validation
  -> exam_service.generate_exam
  -> student_service verifies student exists
  -> rag_client.generate_exam
       -> external RAG POST /generate-exam
       -> if timeout/error/unavailable, build mock exam
  -> SQLAlchemy session inserts exams row
  -> ExamResponse returned in JSON envelope
```

### Exam Submission and Grading

```text
Client
  -> POST /exam/submit
  -> ExamSubmitRequest schema validation
  -> exam_service.submit_exam
  -> grading_service.grade_mcq exact-match scoring
  -> grading_service.grade_short_answers placeholder hook
  -> profile_service.update_topic_performance
  -> profile_service.detect_weak_topics
       -> local topic performance check
       -> optional rag_client.detect_weak_topics with mock fallback
  -> profile_service.compute_readiness_score
       -> 60% exam performance
       -> 40% topic consistency
  -> SQLAlchemy session inserts attempts row
  -> ExamSubmitResponse returned in JSON envelope
```

### Mock-First RAG Integration

```text
exam_service
  -> rag_client
       -> use RAG_BASE_URL when configured and reachable
       -> otherwise return mock exam / mock weak topics
  -> services continue normally
  -> API contract remains stable for frontend
```

## 6. Module Interaction

- `main.py` owns app construction and includes API routers.
- Route modules receive JSON requests, depend on a database session, and call services.
- Pydantic schemas validate all inbound and outbound API data.
- `student_service` owns student registration and lookup.
- `exam_service` orchestrates exam generation and submission. It coordinates the RAG client, grading, profile updates, and attempt persistence.
- `grading_service` contains deterministic grading logic and the future short-answer LLM hook.
- `profile_service` maintains topic performance, weak-topic detection, and readiness scoring.
- `rag_client` is the only module that knows about external RAG HTTP endpoints.
- Database models are shared by services only; route handlers should not contain persistence logic.

## 7. Mock-First Integration Strategy

Mock-first mode is mandatory because the frontend, backend, and RAG teams may work in parallel.

### Goals

- Keep API contracts stable before the external RAG service is complete.
- Allow frontend exam flows to run end-to-end.
- Avoid blocking grading/profile work on AI service availability.
- Make local development reliable without network access.

### Behavior

- `RAG_BASE_URL` is optional.
- If `RAG_BASE_URL` is missing, the RAG client immediately returns mock JSON.
- If the external RAG request times out, fails, or returns invalid data, the RAG client returns mock JSON.
- Mock responses use the same shape as RAG responses so services do not branch heavily.
- API responses include `source: "mock"` or `source: "rag"` for exam generation transparency.

### Mock Exam Shape

Mock exams include:

- Stable question IDs.
- MCQ questions with options.
- Answer keys for local grading.
- Topic metadata for profile updates.
- Optional short-answer placeholders for future LLM grading.

### Parallel Development Contract

The RAG service should eventually implement:

- `POST /generate-exam`
- `POST /weak-topics`

The backend will send JSON payloads and expects JSON responses matching the documented internal shape. Until that service is available, the backend remains fully usable.

## 8. uv Usage

This project uses `uv` for Python project initialization, virtual environments, dependency management, and command execution. `pip` is not used.

Target Python version:

```text
Python 3.14.5
```

### Project Setup Commands

From the repository root:

```bash
uv init backend
cd backend
uv venv --python 3.14.5
uv add fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-dotenv httpx
```

If Python 3.14.5 is already available on the machine, uv will create `.venv/` using that interpreter. If not, the developer should install Python 3.14.5 or configure uv-managed Python support according to the local environment policy.

### Running the API

From `backend/`:

```bash
uv run uvicorn app.main:app --reload
```

If `backend/` is initialized inside an existing uv workspace, the shared `uv.lock` may live at the repository root. In that case, this equivalent root-level command is useful:

```bash
uv --directory backend run uvicorn app.main:app --reload
```

### Useful uv Commands

```bash
uv add <package>
uv remove <package>
uv sync
uv run python --version
uv run uvicorn app.main:app --reload
```

### Environment Variables

Expected local environment variables:

```text
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai
RAG_BASE_URL=
RAG_TIMEOUT_SECONDS=5
MOCK_MODE=true
```

`MOCK_MODE=true` forces mock responses from the RAG client. When `MOCK_MODE=false` and `RAG_BASE_URL` is configured, the backend attempts the external RAG service first and falls back to mock data on failure.
