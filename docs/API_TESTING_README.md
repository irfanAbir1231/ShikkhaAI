# ShikkhaAI API Testing Guide

<<<<<<< Updated upstream
Use this guide to test the FastAPI backend with **Postman**, **cURL**, or any HTTP client.
=======
Use this guide to test the FastAPI backend with Postman.
>>>>>>> Stashed changes

## Prerequisites

Start the backend server from the repository root:

```powershell
uv --directory backend run uvicorn app.main:app --reload
```

The API should be running at:

```text
http://127.0.0.1:8000
```

<<<<<<< Updated upstream
Interactive docs (Swagger UI) are available at:

```text
http://127.0.0.1:8000/docs
```

For all `POST` / `PUT` / `PATCH` requests, add this header:
=======
For all `POST` requests, add this header in Postman:
>>>>>>> Stashed changes

```text
Content-Type: application/json
```

<<<<<<< Updated upstream
For **protected endpoints**, you must also add:

```text
Authorization: Bearer <your_access_token_here>
```

---

## Authentication

The backend uses **JWT Bearer tokens** (`HS256`, 24-hour expiry). There are two public endpoints that return a token. All other endpoints require the token.

### Public Endpoints (No Token Required)

- `GET /health`
- `POST /student/register`
- `POST /student/login`

### Protected Endpoints (Bearer Token Required)

- `GET /student/{id}`
- `GET /student/{id}/exams`
- `GET /student/{id}/attempts`
- `GET /student/{id}/weak-topics`
- `POST /exam/generate`
- `POST /exam/submit`
- `GET /exam/{id}/attempts`

> **Tip:** In Postman, create an environment variable `auth_token` and reference it as `{{auth_token}}` in the Authorization header. After login/register, copy the returned `access_token` into that variable.

---

## Generation Modes

The backend resolves which generator to use at request time. Pick the mode that matches how you've set up your env.

### Mode A — Real RAG (ChromaDB retrieval + Gemini)

Returns `source: "rag"`. Requires the `rag` package to be importable in the same environment running the backend (needs `chromadb`, `sentence-transformers`, `torch` — **Python 3.11**, no wheels on 3.14).
=======
## Generation modes

The backend resolves which generator to use at request time. Pick the
mode that matches how you've set up your env.

### Mode A — Real RAG (ChromaDB retrieval + Gemini)

Returns `source: "rag"`. Requires the `rag` package to be importable in
the same environment running the backend (needs `chromadb`,
`sentence-transformers`, `torch` — **Python 3.11**, no wheels on 3.14).
>>>>>>> Stashed changes

Two ways to run it:

**A1. In-process** (one server, no separate RAG service)

```powershell
# from repo root, using a Python 3.11 venv with rag/requirements.txt installed
copy backend\.env.example backend\.env
copy rag\.env.example rag\.env       # put GEMINI_API_KEY here
# MOCK_MODE=false (default in .env.example)
uvicorn app.main:app --reload --app-dir backend
```

<<<<<<< Updated upstream
The backend imports `rag.generate.generate_questions` directly. No port 8100 needed.
=======
The backend imports `rag.generate.generate_questions` directly. No port
8100 needed.
>>>>>>> Stashed changes

**A2. Two-process** (backend on its own env, RAG on a Python 3.11 venv)

```powershell
# Terminal 1 — RAG service (Python 3.11)
py -3.11 -m venv .rag-venv
.rag-venv\Scripts\activate
pip install -r rag/requirements.txt
copy rag\.env.example rag\.env       # put GEMINI_API_KEY here
uvicorn rag_server:app --port 8100
# Smoke test: GET http://localhost:8100/health → {"status":"ok","service":"rag"}

# Terminal 2 — Backend (any Python; rag/ does NOT need to import here)
copy backend\.env.example backend\.env
# backend\.env already has RAG_BASE_URL=http://localhost:8100/rag and MOCK_MODE=false
uv --directory backend run uvicorn app.main:app --reload
```

<<<<<<< Updated upstream
In A2 the backend will only hit the HTTP service if in-process import fails AND no `GEMINI_API_KEY` is set in `backend/.env`. To force the HTTP path, leave `GEMINI_API_KEY` unset in `backend/.env`.

### Mode B — Direct Gemini, no retrieval

Returns `source: "gemini"`. Triggers when `MOCK_MODE=false`, the in-process `rag` import fails (e.g., backend running on Python 3.14), and `GEMINI_API_KEY` is set in `backend/.env`. No ChromaDB context — Gemini generates from the topic/subject/difficulty alone.

### Mode C — Mock (offline)

Returns `source: "mock"`. Set `MOCK_MODE=true` in `backend\.env`. No LLM/RAG calls — built-in templates. Useful for offline testing and CI.

Current data coverage: ChromaDB only contains **class 8 science**. For real RAG, use `subject: "science"`, `class_level: "8"`. Other subject/class combos will return empty retrieval context and the RAG pipeline will respond with `{"questions": []}`.

---
=======
In A2 the backend will only hit the HTTP service if in-process import
fails AND no `GEMINI_API_KEY` is set in `backend/.env`. To force the
HTTP path, leave `GEMINI_API_KEY` unset in `backend/.env`.

### Mode B — Direct Gemini, no retrieval

Returns `source: "gemini"`. Triggers when `MOCK_MODE=false`, the in-process
`rag` import fails (e.g., backend running on Python 3.14), and
`GEMINI_API_KEY` is set in `backend/.env`. No ChromaDB context — Gemini
generates from the topic/subject/difficulty alone.

### Mode C — Mock (offline)

Returns `source: "mock"`. Set `MOCK_MODE=true` in `backend\.env`. No
LLM/RAG calls — built-in templates. Useful for offline testing and CI.

Current data coverage: ChromaDB only contains **class 8 science**. For
real RAG, use `subject: "science"`, `class_level: "8"`. Other
subject/class combos will return empty retrieval context and the RAG
pipeline will respond with `{"questions": []}`.
>>>>>>> Stashed changes

## Testing Order

Run the requests in this order:

1. Health check
<<<<<<< Updated upstream
2. Register student (get token)
3. Generate exam (use token)
4. Submit exam (use token)
5. Get student exams (use token)
6. Get student attempts (use token)
7. Get weak topics (use token)
8. Login (alternative to register, also returns token)

Save the returned `student_id`, `exam_id`, and `access_token` because later requests need them.

---

## 1. Health Check

**Method:** `GET`

**URL:**
=======
2. Register student
3. Get student
4. Generate exam
5. Submit exam

Save the returned `student_id` and `exam_id` values because later requests need them.

## 1. Health Check

Method:

```text
GET
```

URL:
>>>>>>> Stashed changes

```text
http://127.0.0.1:8000/health
```

<<<<<<< Updated upstream
**Headers:** None required.

**Body:** None.

**Expected result:**
=======
Body:

```text
No body required.
```

Expected result (default — real RAG enabled):
>>>>>>> Stashed changes

```json
{
  "success": true,
  "data": {
    "status": "ok",
<<<<<<< Updated upstream
    "mock_mode": true
=======
    "mock_mode": false
>>>>>>> Stashed changes
  },
  "error": null
}
```

<<<<<<< Updated upstream
`mock_mode` reflects the `MOCK_MODE` env var. `false` means the backend will call the real RAG pipeline (ChromaDB retrieval + Gemini) or fall back to direct Gemini if the `rag` package is not importable. `true` means built-in mock questions are returned with no LLM/RAG calls.

---

## 2. Register Student

**Method:** `POST`

**URL:**
=======
`mock_mode` reflects the `MOCK_MODE` env var. `false` means the backend
will call the real RAG pipeline (ChromaDB retrieval + Gemini) or fall
back to direct Gemini if the `rag` package is not importable. `true`
means built-in mock questions are returned with no LLM/RAG calls.

## 2. Register Student

Method:

```text
POST
```

URL:
>>>>>>> Stashed changes

```text
http://127.0.0.1:8000/student/register
```

<<<<<<< Updated upstream
**Headers:**

```text
Content-Type: application/json
```

**Body:**
=======
Body:
>>>>>>> Stashed changes

```json
{
  "name": "Irfan Hakim",
  "email": "irfan.test@example.com",
<<<<<<< Updated upstream
  "grade_level": "8",
  "password": "securepass123"
}
```

| Field | Type | Constraints |
|-------|------|-------------|
| `name` | string | 1–120 chars, not blank |
| `email` | string | Valid email format, unique |
| `grade_level` | string | 1–50 chars, not blank |
| `password` | string | 6–128 chars |

**Expected result:**

```json
{
  "success": true,
  "data": {
    "student": {
      "id": 1,
      "name": "Irfan Hakim",
      "email": "irfan.test@example.com",
      "grade_level": "8"
    },
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
  },
  "error": null
}
```

> **Save the `access_token`!** Copy it into your Postman environment variable `auth_token`. This token is required for all subsequent protected requests.

**Duplicate email error:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "STUDENT_EMAIL_EXISTS",
    "message": "A student with this email already exists."
  }
}
```

---

## 3. Login

Use this if you already have an account instead of registering again.

**Method:** `POST`

**URL:**

```text
http://127.0.0.1:8000/student/login
```

**Headers:**

```text
Content-Type: application/json
```

**Body:**

```json
{
  "email": "irfan.test@example.com",
  "password": "securepass123"
}
```

**Expected result:**

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer",
    "student": {
      "id": 1,
      "name": "Irfan Hakim",
      "email": "irfan.test@example.com",
      "grade_level": "8"
    }
  },
  "error": null
}
```

**Invalid credentials:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Incorrect email or password."
  }
}
```

---

## 4. Get Student (Protected)

**Method:** `GET`

**URL:**

```text
http://127.0.0.1:8000/student/1
```

**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

Replace `1` with the student `id` returned from register/login.

**Expected result:**
=======
  "grade_level": "8"
}
```

Expected result:
>>>>>>> Stashed changes

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Irfan Hakim",
    "email": "irfan.test@example.com",
    "grade_level": "8"
  },
  "error": null
}
```

<<<<<<< Updated upstream
**Ownership enforcement:** If you request a different student's ID (e.g., `/student/2` when your token is for student 1):

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "FORBIDDEN",
    "message": "You can only view your own profile."
  }
}
```

**No token:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_REQUIRED",
    "message": "Not authenticated."
  }
}
```

---

## 5. Generate Exam (Protected)

**Method:** `POST`

**URL:**
=======
Important:

If you run this request more than once with the same email, the API will return a duplicate email error. Change the email value to test again, for example:

```json
{
  "name": "Irfan Hakim",
  "email": "irfan.test2@example.com",
  "grade_level": "8"
}
```

## 3. Get Student

Method:

```text
GET
```

URL:

```text
http://127.0.0.1:8000/student/1
```

Body:

```text
No body required.
```

Replace `1` with the student `id` returned from the register student API.

Expected result:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Irfan Hakim",
    "email": "irfan.test@example.com",
    "grade_level": "8"
  },
  "error": null
}
```

## 4. Generate Exam

Method:

```text
POST
```

URL:
>>>>>>> Stashed changes

```text
http://127.0.0.1:8000/exam/generate
```

<<<<<<< Updated upstream
**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

**Body:**
=======
Body:
>>>>>>> Stashed changes

```json
{
  "student_id": 1,
  "subject": "science",
  "topic": "Photosynthesis",
  "class_level": "8",
  "difficulty": "medium",
  "num_questions": 5
}
```

<<<<<<< Updated upstream
| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `student_id` | int | ✅ | — | > 0, must match token's student ID |
| `subject` | string | ✅ | — | 1–100 chars, not blank |
| `topic` | string | ✅ | — | 1–150 chars, not blank |
| `class_level` | string | ❌ | `"8"` | 1–3 chars |
| `difficulty` | string | ❌ | `"medium"` | `"easy"`, `"medium"`, or `"hard"` |
| `num_questions` | int | ❌ | `5` | 1–20 |

**Ownership check:** The `student_id` in the body must match the token's student. Otherwise:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "FORBIDDEN",
    "message": "You can only access your own resources."
  }
}
```

**Expected result (mock mode — `source: "mock"`):**

```json
{
  "success": true,
  "data": {
    "exam_id": 1,
    "student_id": 1,
    "subject": "science",
    "topic": "Photosynthesis",
    "difficulty": "medium",
    "source": "mock",
    "questions": [
      {
        "id": "q1",
        "type": "mcq",
        "topic": "Quadratic Equations",
        "prompt": "What is the standard form of a quadratic equation?",
        "options": [
          "A. ax + b = 0",
          "B. ax^2 + bx + c = 0",
          "C. a/x + b = 0",
          "D. x^3 + ax^2 + b = 0"
        ],
        "marks": 1
      }
    ]
  },
  "error": null
}
```

**Expected result (real RAG — `source: "rag"` or `"gemini"`):**
=======
Replace `student_id` with the student `id` returned from the register student API.

`class_level` is optional and defaults to `"8"`. With the real RAG service
the ChromaDB only contains **class 8 science**, so use `subject: "science"`.
The backend lowercases `subject` and forwards `topic` to RAG as the
retrieval hint automatically.

When `source` is `"rag"`, MCQ correct answers are the **letter only**
(`"A"`, `"B"`, `"C"`, `"D"`) — submit the letter, not the option text, in
the Submit Exam step.

Allowed difficulty values:

```text
easy
medium
hard
```

Expected result (real RAG — `source: "rag"`, or `"gemini"` fallback):
>>>>>>> Stashed changes

```json
{
  "success": true,
  "data": {
    "exam_id": 13,
    "student_id": 2,
    "subject": "science",
    "topic": "Photosynthesis",
    "difficulty": "medium",
    "source": "rag",
    "questions": [
      {
        "id": "1",
        "type": "mcq",
        "topic": "Photosynthesis",
        "prompt": "Which gas is absorbed by plants during photosynthesis?",
        "options": [
          "A. Oxygen",
          "B. Carbon dioxide",
          "C. Nitrogen",
          "D. Hydrogen"
        ],
        "marks": 1
      }
    ]
  },
  "error": null
}
```

**Question ID format depends on `source`:**

| `source` | `id` values | Where set |
|----------|-------------|-----------|
| `"rag"` | `"1"`, `"2"`, `"3"`, ... (numeric strings) | `rag/generate.py` |
| `"gemini"` | `"1"`, `"2"`, `"3"`, ... (numeric strings) | `_generate_via_gemini` fallback |
| `"mock"` | `"q1"`, `"q2"`, `"q3"`, ... | `_mock_exam` |

<<<<<<< Updated upstream
Question text/options vary every call — Gemini generates fresh content from retrieved curriculum chunks (or the topic alone in the `"gemini"` fallback). `source` is `"rag"` when ChromaDB retrieval + Gemini ran, `"gemini"` when the `rag` package was not importable and the backend fell back to direct Gemini (no retrieval), and `"mock"` only if `MOCK_MODE=true`.

> **Critical:** Save the returned `exam_id` AND `student_id` — both are needed for the submit step. The response includes exactly `num_questions` items.

---

## 6. Submit Exam (Protected)

**Method:** `POST`

**URL:**
=======
Question text/options vary every call — Gemini generates fresh content
from retrieved curriculum chunks (or the topic alone in the `"gemini"`
fallback). `source` is `"rag"` when ChromaDB retrieval + Gemini ran,
`"gemini"` when the `rag` package was not importable and the backend
fell back to direct Gemini (no retrieval), and `"mock"` only if
`MOCK_MODE=true`.

**If you get `"gemini"` and want real RAG:** install
`rag/requirements.txt` into the backend environment (Python 3.11), or
run the two-process setup (Mode A2) with `GEMINI_API_KEY` **unset** in
`backend/.env` so the HTTP path is reached.

Save the returned `exam_id` AND `student_id` — both are needed for the
submit step. The response includes exactly `num_questions` items.

## 5. Submit Exam

Method:

```text
POST
```

URL:
>>>>>>> Stashed changes

```text
http://127.0.0.1:8000/exam/submit
```

<<<<<<< Updated upstream
**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

**Critical:** Copy `student_id`, `exam_id`, AND every `question_id` straight from the Generate Exam response. Reusing stale IDs (e.g. `exam_id: 1` when you just generated `exam_id: 13`) scores you against the wrong exam.

**Body — real RAG / Gemini** (`source: "rag"` or `"gemini"`). Question IDs are numeric strings (`"1"`, `"2"`, ...). MCQ answer is the letter only (`A`/`B`/`C`/`D`):

```json
{
  "student_id": 1,
=======
**Critical:** copy `student_id`, `exam_id`, AND every `question_id`
straight from the Generate Exam response. Reusing stale IDs (e.g.
`exam_id: 1` when you just generated `exam_id: 13`) scores you against
the wrong exam — you'll see another exam's `weak_topics` (e.g.
`"Quadratic Equations"`) in the result, which is the giveaway.

Body — **real RAG / Gemini** (`source: "rag"` or `"gemini"`). Question
IDs are numeric strings (`"1"`, `"2"`, ...). MCQ answer is the letter
only (`A`/`B`/`C`/`D`):

```json
{
  "student_id": 2,
>>>>>>> Stashed changes
  "exam_id": 13,
  "answers": [
    { "question_id": "1",  "answer": "B" },
    { "question_id": "2",  "answer": "C" },
    { "question_id": "3",  "answer": "D" },
    { "question_id": "4",  "answer": "C" },
<<<<<<< Updated upstream
    { "question_id": "5",  "answer": "B" }
=======
    { "question_id": "5",  "answer": "B" },
    { "question_id": "6",  "answer": "B" },
    { "question_id": "7",  "answer": "C" },
    { "question_id": "8",  "answer": "C" },
    { "question_id": "9",  "answer": "Photosynthesis produces oxygen that animals breathe and glucose that forms the base of nearly every food chain." },
    { "question_id": "10", "answer": "Carbon dioxide is absorbed through stomata on the leaf surface, and water is absorbed by the roots from the soil and transported up through the xylem." }
>>>>>>> Stashed changes
  ]
}
```

<<<<<<< Updated upstream
**Body — mock mode only** (`MOCK_MODE=true`, `source: "mock"`). Question IDs are `"q1"`, `"q2"`, ... and MCQ answer is the full option text, not the letter:
=======
Body — **mock mode only** (`MOCK_MODE=true`, `source: "mock"`). Question
IDs are `"q1"`, `"q2"`, ... and MCQ answer is the full option text, not
the letter:
>>>>>>> Stashed changes

```json
{
  "student_id": 1,
  "exam_id": 1,
  "answers": [
    { "question_id": "q1", "answer": "ax^2 + bx + c = 0" },
    { "question_id": "q2", "answer": "b^2 - 4ac" },
    { "question_id": "q3", "answer": "Two distinct real roots" },
    { "question_id": "q4", "answer": "Identify the known values" },
    { "question_id": "q5", "answer": "A short explanation in your own words." }
  ]
}
```

<<<<<<< Updated upstream
| Field | Type | Constraints |
|-------|------|-------------|
| `student_id` | int | > 0, must match token's student ID |
| `exam_id` | int | > 0, must exist in DB |
| `answers` | array | 1–50 items. Each item has `question_id` (string) and `answer` (string, max 4000 chars) |

**Expected result:**
=======
For real RAG/Gemini runs, choose each correct letter yourself by reading
the question — questions are fresh per call, so there's no static
answer key in the API response.

Expected result:
>>>>>>> Stashed changes

```json
{
  "success": true,
  "data": {
    "attempt_id": 1,
    "student_id": 1,
    "exam_id": 1,
    "score_percentage": 100.0,
    "mcq_correct": 4,
    "mcq_total": 4,
    "weak_topics": [],
    "readiness_score": 100.0,
    "short_answer_feedback": [
      {
        "question_id": "q5",
        "status": "placeholder",
        "feedback": "Short-answer LLM grading is not configured for this MVP.",
        "awarded_marks": 0.0
      }
    ]
  },
  "error": null
}
```

<<<<<<< Updated upstream
---

## 7. List Student Exams (Protected)

Returns all exams generated by a student, ordered newest first.

**Method:** `GET`

**URL:**

```text
http://127.0.0.1:8000/student/1/exams
```

**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

**Expected result:**

```json
{
  "success": true,
  "data": [
    {
      "exam_id": 2,
      "student_id": 1,
      "subject": "science",
      "topic": "Cell Structure",
      "difficulty": "easy",
      "num_questions": 5,
      "source": "mock",
      "created_at": "2026-05-25T14:30:00+00:00"
    },
    {
      "exam_id": 1,
      "student_id": 1,
      "subject": "science",
      "topic": "Photosynthesis",
      "difficulty": "medium",
      "num_questions": 5,
      "source": "mock",
      "created_at": "2026-05-25T14:15:00+00:00"
    }
  ],
  "error": null
}
```

---

## 8. List Student Attempts (Protected)

Returns all exam submissions by a student, ordered newest first.

**Method:** `GET`

**URL:**

```text
http://127.0.0.1:8000/student/1/attempts
```

**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

**Expected result:**

```json
{
  "success": true,
  "data": [
    {
      "attempt_id": 3,
      "exam_id": 2,
      "student_id": 1,
      "score_percentage": 80.0,
      "mcq_correct": 4,
      "mcq_total": 5,
      "readiness_score": 78.5,
      "weak_topics": [
        {
          "topic": "Cell Organelles",
          "reason": "Low topic average or inconsistent recent performance",
          "score": 45.0
        }
      ],
      "short_answer_feedback": [],
      "created_at": "2026-05-25T14:45:00+00:00"
    }
  ],
  "error": null
}
```

---

## 9. Get Student Weak Topics (Protected)

Returns topics where the student has scored below thresholds (< 60% average, < 50% consistency, or < 50% last score).

**Method:** `GET`

**URL:**

```text
http://127.0.0.1:8000/student/1/weak-topics
```

**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

**Expected result (after at least one exam submission):**

```json
{
  "success": true,
  "data": [
    {
      "topic": "Photosynthesis",
      "reason": "Low topic average or inconsistent recent performance",
      "score": 42.5
    }
  ],
  "error": null
}
```

If the student has no attempts yet, the array will be empty.

---

## 10. List Exam Attempts (Protected)

Returns all attempts for a specific exam.

**Method:** `GET`

**URL:**

```text
http://127.0.0.1:8000/exam/1/attempts
```

**Headers:**

```text
Content-Type: application/json
Authorization: Bearer {{auth_token}}
```

**Expected result:**

```json
{
  "success": true,
  "data": [
    {
      "attempt_id": 1,
      "exam_id": 1,
      "student_id": 1,
      "score_percentage": 100.0,
      "mcq_correct": 4,
      "mcq_total": 4,
      "readiness_score": 100.0,
      "weak_topics": [],
      "short_answer_feedback": [],
      "created_at": "2026-05-25T14:20:00+00:00"
    }
  ],
  "error": null
}
```

**Exam not found:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "EXAM_NOT_FOUND",
    "message": "Exam was not found."
  }
}
```

---

## Postman Collection Quick Setup

### Environment Variables

Create a Postman environment with these variables:

| Variable | Initial Value | Description |
|----------|--------------|-------------|
| `base_url` | `http://127.0.0.1:8000` | Backend URL |
| `auth_token` | *(empty)* | Filled after login/register |
| `student_id` | *(empty)* | Filled after login/register |

### Collection Structure

```
ShikkhaAI API
├── 🌐 Public
│   ├── Health Check        GET  {{base_url}}/health
│   ├── Register Student    POST {{base_url}}/student/register
│   └── Login               POST {{base_url}}/student/login
├── 🔒 Student (Protected)
│   ├── Get Student         GET  {{base_url}}/student/{{student_id}}
│   ├── List Exams          GET  {{base_url}}/student/{{student_id}}/exams
│   ├── List Attempts       GET  {{base_url}}/student/{{student_id}}/attempts
│   └── Weak Topics         GET  {{base_url}}/student/{{student_id}}/weak-topics
├── 🔒 Exam (Protected)
│   ├── Generate Exam       POST {{base_url}}/exam/generate
│   ├── Submit Exam         POST {{base_url}}/exam/submit
│   └── List Attempts       GET  {{base_url}}/exam/:exam_id/attempts
```

For all **Protected** requests, set the Authorization header to:

```text
Bearer {{auth_token}}
```

### Test Scripts (Postman)

Add this to the **Tests** tab of Register and Login requests to auto-save the token:

```javascript
// Parse response
const jsonData = pm.response.json();
if (jsonData.success && jsonData.data) {
    const token = jsonData.data.access_token;
    const student = jsonData.data.student;
    if (token) {
        pm.environment.set("auth_token", token);
    }
    if (student && student.id) {
        pm.environment.set("student_id", student.id);
    }
}
```

---

## Common Error Responses

### Authentication Errors

**Missing token:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_REQUIRED",
    "message": "Not authenticated."
  }
}
```

**Invalid/expired token:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "AUTH_REQUIRED",
    "message": "Invalid token payload."
  }
}
```

**Accessing another student's data:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "FORBIDDEN",
    "message": "You can only view your own profile."
  }
}
```

### Resource Errors

**Duplicate student email:**
=======
## Common Error Responses

Duplicate student email:
>>>>>>> Stashed changes

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "STUDENT_EMAIL_EXISTS",
    "message": "A student with this email already exists."
  }
}
```

<<<<<<< Updated upstream
**Student not found:**
=======
Student not found:
>>>>>>> Stashed changes

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "STUDENT_NOT_FOUND",
    "message": "Student was not found."
  }
}
```

<<<<<<< Updated upstream
**Exam not found:**

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "EXAM_NOT_FOUND",
    "message": "Exam was not found."
  }
}
```

### Validation Errors
=======
Validation error:
>>>>>>> Stashed changes

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "body.student_id: Input should be greater than 0"
  }
}
```

<<<<<<< Updated upstream
---

## Notes

`backend/.env.example` ships with `MOCK_MODE=false` and `RAG_BASE_URL` pointed at the local RAG service (port 8100), so the default configuration runs the **real RAG pipeline** (Mode A above) when the `rag` package is importable. If it isn't, the backend falls through to direct Gemini (Mode B) as long as `GEMINI_API_KEY` is set. Set `MOCK_MODE=true` to bypass everything and use built-in templates (Mode C). The `mock_mode` field in the health check reflects whichever value is active.
=======
## Notes

`backend/.env.example` ships with `MOCK_MODE=false` and `RAG_BASE_URL`
pointed at the local RAG service (port 8100), so the default
configuration runs the **real RAG pipeline** (Mode A above) when the
`rag` package is importable. If it isn't, the backend falls through to
direct Gemini (Mode B) as long as `GEMINI_API_KEY` is set. Set
`MOCK_MODE=true` to bypass everything and use built-in templates (Mode C).
The `mock_mode` field in the health check reflects whichever value is
active.
>>>>>>> Stashed changes

If the app is using SQLite, data is stored in:

```text
backend/shikkhaai.db
```

If you delete that database file, IDs will reset after the app creates a new database.
<<<<<<< Updated upstream

**Students created before JWT auth was added** have `password_hash = NULL` and cannot log in. They must re-register, or you can wipe the database.
=======
>>>>>>> Stashed changes
