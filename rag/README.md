# RAG System — Integration Guide for Member 2

---

## What is built

The RAG system does three things:
1. Reads the NCTB science PDF and stores it in ChromaDB
2. Retrieves relevant chunks for a given topic/query
3. Calls Gemini to generate exam questions based on those chunks


---

## For Member 2 (Backend)

### How to plug in the RAG router

In your main.py, add these two lines:

```python
from rag.rag_router import router as rag_router
app.include_router(rag_router, prefix="/rag")
```

That exposes three endpoints you can call internally:

POST /rag/generate-exam
POST /rag/retrieve
POST /rag/context

### The important one: /rag/generate-exam

Request body:
```json
{
  "student_id": 1,
  "subject": "science",
  "class_level": "8",
  "difficulty": "medium",
  "count": 7
}
```

Response:
```json
{
  "questions": [
    {
      "id": 1,
      "type": "mcq",
      "topic": "Photosynthesis",
      "difficulty": "medium",
      "question": "What is the main function of chlorophyll?",
      "options": ["A. Absorb sunlight", "B. Store water", "C. Produce seeds", "D. Break down glucose"],
      "answer": "A"
    },
    {
      "id": 2,
      "type": "short_answer",
      "topic": "Cell Division",
      "difficulty": "medium",
      "question": "What is mitosis?",
      "options": [],
      "answer": "Mitosis is the process of cell division that produces two identical daughter cells."
    }
  ]
}
```



### Important rules

- subject must be lowercase: "science" not "Science"
- class_level must be a string: "8" not 8
- difficulty must be one of: "easy", "medium", "hard"
- count is optional, defaults to 7

### For grading short answers

Call Gemini directly from your grading module. Pass the question, expected answer, and student answer. Do not call the RAG router for grading.

---
