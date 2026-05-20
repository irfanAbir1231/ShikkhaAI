# ShikkhaAI API Testing Guide

Use this guide to test the FastAPI backend with Postman.

## Prerequisites

Start the backend server from the repository root:

```powershell
uv --directory backend run uvicorn app.main:app --reload
```

The API should be running at:

```text
http://127.0.0.1:8000
```

For all `POST` requests, add this header in Postman:

```text
Content-Type: application/json
```

## Generation modes

The backend resolves which generator to use at request time. Pick the
mode that matches how you've set up your env.

### Mode A — Real RAG (ChromaDB retrieval + Gemini)

Returns `source: "rag"`. Requires the `rag` package to be importable in
the same environment running the backend (needs `chromadb`,
`sentence-transformers`, `torch` — **Python 3.11**, no wheels on 3.14).

Two ways to run it:

**A1. In-process** (one server, no separate RAG service)

```powershell
# from repo root, using a Python 3.11 venv with rag/requirements.txt installed
copy backend\.env.example backend\.env
copy rag\.env.example rag\.env       # put GEMINI_API_KEY here
# MOCK_MODE=false (default in .env.example)
uvicorn app.main:app --reload --app-dir backend
```

The backend imports `rag.generate.generate_questions` directly. No port
8100 needed.

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

## Testing Order

Run the requests in this order:

1. Health check
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

```text
http://127.0.0.1:8000/health
```

Body:

```text
No body required.
```

Expected result (default — real RAG enabled):

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "mock_mode": false
  },
  "error": null
}
```

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

```text
http://127.0.0.1:8000/student/register
```

Body:

```json
{
  "name": "Irfan Hakim",
  "email": "irfan.test@example.com",
  "grade_level": "8"
}
```

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

```text
http://127.0.0.1:8000/exam/generate
```

Body:

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

```text
http://127.0.0.1:8000/exam/submit
```

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
  "exam_id": 13,
  "answers": [
    { "question_id": "1",  "answer": "B" },
    { "question_id": "2",  "answer": "C" },
    { "question_id": "3",  "answer": "D" },
    { "question_id": "4",  "answer": "C" },
    { "question_id": "5",  "answer": "B" },
    { "question_id": "6",  "answer": "B" },
    { "question_id": "7",  "answer": "C" },
    { "question_id": "8",  "answer": "C" },
    { "question_id": "9",  "answer": "Photosynthesis produces oxygen that animals breathe and glucose that forms the base of nearly every food chain." },
    { "question_id": "10", "answer": "Carbon dioxide is absorbed through stomata on the leaf surface, and water is absorbed by the roots from the soil and transported up through the xylem." }
  ]
}
```

Body — **mock mode only** (`MOCK_MODE=true`, `source: "mock"`). Question
IDs are `"q1"`, `"q2"`, ... and MCQ answer is the full option text, not
the letter:

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

For real RAG/Gemini runs, choose each correct letter yourself by reading
the question — questions are fresh per call, so there's no static
answer key in the API response.

Expected result:

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

## Common Error Responses

Duplicate student email:

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

Student not found:

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

Validation error:

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

## Notes

`backend/.env.example` ships with `MOCK_MODE=false` and `RAG_BASE_URL`
pointed at the local RAG service (port 8100), so the default
configuration runs the **real RAG pipeline** (Mode A above) when the
`rag` package is importable. If it isn't, the backend falls through to
direct Gemini (Mode B) as long as `GEMINI_API_KEY` is set. Set
`MOCK_MODE=true` to bypass everything and use built-in templates (Mode C).
The `mock_mode` field in the health check reflects whichever value is
active.

If the app is using SQLite, data is stored in:

```text
backend/shikkhaai.db
```

If you delete that database file, IDs will reset after the app creates a new database.
