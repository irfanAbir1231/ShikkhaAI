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

Expected result:

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "mock_mode": true
  },
  "error": null
}
```

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
  "subject": "Mathematics",
  "topic": "Quadratic Equations",
  "difficulty": "medium",
  "num_questions": 5
}
```

Replace `student_id` with the student `id` returned from the register student API.

Allowed difficulty values:

```text
easy
medium
hard
```

Expected result:

```json
{
  "success": true,
  "data": {
    "exam_id": 1,
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
        "prompt": "What is the standard form used in Quadratic Equations?",
        "options": [
          "ax^2 + bx + c = 0",
          "ax + b = 0",
          "a/x + b = 0",
          "x = a + b"
        ],
        "marks": 1
      }
    ]
  },
  "error": null
}
```

The response will include the number of questions requested in `num_questions`. Save the returned `exam_id`.

## 5. Submit Exam

Method:

```text
POST
```

URL:

```text
http://127.0.0.1:8000/exam/submit
```

Body:

```json
{
  "student_id": 1,
  "exam_id": 1,
  "answers": [
    {
      "question_id": "q1",
      "answer": "ax^2 + bx + c = 0"
    },
    {
      "question_id": "q2",
      "answer": "b^2 - 4ac"
    },
    {
      "question_id": "q3",
      "answer": "Two distinct real roots"
    },
    {
      "question_id": "q4",
      "answer": "Identify the known values"
    },
    {
      "question_id": "q5",
      "answer": "A quadratic equation can be solved using factoring, completing the square, or the quadratic formula."
    }
  ]
}
```

Replace `student_id` and `exam_id` with the values returned from previous requests.

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

The default local setup uses `MOCK_MODE=true`, so exam generation uses mock questions instead of an external RAG service.

If the app is using SQLite, data is stored in:

```text
backend/shikkhaai.db
```

If you delete that database file, IDs will reset after the app creates a new database.
