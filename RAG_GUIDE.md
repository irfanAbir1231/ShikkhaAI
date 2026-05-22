# RAG System Completion Guide

## Overview

The RAG (Retrieval-Augmented Generation) service is a **standalone FastAPI application** that:

1. **Ingests** PDF curriculum documents → chunks → embeddings → ChromaDB
2. **Retrieves** relevant context chunks based on a query
3. **Generates** curriculum-aligned exam questions using Google Gemini, augmented with retrieved context

It runs **independently** from the backend on port `8100`. The backend can call it over HTTP, or fall back to direct Gemini calls if the RAG service is unavailable.

> **Critical Constraint:** The RAG service **must** run on **Python 3.11** because `torch`, `sentence-transformers`, and `chromadb` do not have wheels for Python 3.14. A pre-configured virtual environment (`.rag-venv`) is already in the repo.

---

## Current State

### ✅ What Works

| Component | Status | Notes |
|-----------|--------|-------|
| `ingest.py` (active code) | ✅ | Chunks PDFs, embeds with `paraphrase-multilingual-MiniLM-L12-v2`, stores in ChromaDB with metadata |
| `generate.py` | ✅ | Calls Gemini (`gemini-2.5-flash`) with structured prompt, returns JSON questions |
| `rag_router.py` | ✅ | Exposes `/generate-exam`, `/retrieve`, `/context` endpoints |
| `rag_server.py` | ✅ | Standalone entry point with `/health` |
| Duplicate detection | ✅ | MD5-based, prevents re-ingesting identical files |
| Metadata filtering | ✅ | `subject` and `class` filters work in retrieval |

### ⚠️ Partially Working

- **Context assembly**: The `retrieve.py` → `generate.py` pipeline works, but retrieval quality is degraded due to the embedding model mismatch.

### ❌ Critical Issues

| Issue | Severity | Details |
|-------|----------|---------|
| **Embedding model mismatch** | 🔴 Critical | `ingest.py` uses `paraphrase-multilingual-MiniLM-L12-v2`; `retrieve.py` uses `paraphrase-MiniLM-L3-v2`. These are completely different models. Retrieval similarity is meaningless. |
| **`POST /weak-topics` missing** | 🟡 High | Backend calls this endpoint and always gets 404, falling back to local-only weak-topic logic. |
| **`MAX_PAGES = 15`** | 🟡 High | Only the first 15 pages of any PDF are ingested. Full textbooks are truncated. |
| **`get_collection()` crash** | 🟡 Medium | `retrieve.py` uses `get_collection()` instead of `get_or_create_collection()`. If ChromaDB is empty, the RAG service crashes on first query. |
| **Only one PDF ingested** | 🟡 Medium | Only `class_8_science_eng.pdf` exists in `uploads/`. No other subjects or classes. |
| **Retrieve model loaded at import** | 🟢 Low | Slows down RAG service startup. |
| **Old commented code in `ingest.py`** | 🟢 Low | Lines 1–236 are dead code. |

---

## Step-by-Step Completion Plan

### Phase 1: Critical Fixes (Do These First)

#### 1.1 Fix Embedding Model Mismatch

**File:** `rag/retrieve.py` (line 19)

```python
# BEFORE
EMBED_MODEL = "sentence-transformers/paraphrase-MiniLM-L3-v2"

# AFTER
EMBED_MODEL = "paraphrase-multilingual-MiniLM-L12-v2"
```

This is a **single-line change** but it is the most important fix in the entire RAG system. Both ingestion and retrieval must use the exact same model.

#### 1.2 Fix Collection Creation

**File:** `rag/retrieve.py` (around line 39)

```python
# BEFORE
collection = client.get_collection(name=COLLECTION_NAME)

# AFTER
collection = client.get_or_create_collection(
    name=COLLECTION_NAME,
    metadata={"hnsw:space": "cosine"}
)
```

This prevents crashes when the ChromaDB is fresh or the collection was deleted.

#### 1.3 Increase / Remove PDF Page Limit

**File:** `rag/ingest.py` (around line 280)

```python
# BEFORE
MAX_PAGES = 15

# AFTER
MAX_PAGES = None  # or a very high number like 500
```

If you keep a limit, document why and make it configurable via environment variable.

---

### Phase 2: Add Missing `/weak-topics` Endpoint

**File:** `rag/rag_router.py`

Add a new endpoint that analyzes a student's topic performance and returns enhanced weak-topic recommendations:

```python
from pydantic import BaseModel
from typing import List, Dict

class WeakTopicsRequest(BaseModel):
    student_id: int
    subject: str
    class_level: str
    topic_performances: List[Dict]  # { topic, average_score, consistency_score, last_score }

class WeakTopicsResponse(BaseModel):
    weak_topics: List[str]
    recommendations: List[Dict]  # { topic, reason, suggested_resources }

@router.post("/weak-topics", response_model=WeakTopicsResponse)
def weak_topics(req: WeakTopicsRequest):
    # Strategy: Combine rule-based filtering with LLM-enhanced recommendations
    weak = [t["topic"] for t in req.topic_performances if t["average_score"] < 60 or t["last_score"] < 50]

    # Optionally call Gemini for richer recommendations
    if weak:
        prompt = f"""
A student in class {req.class_level} is weak in these topics: {', '.join(weak)}.
For each topic, suggest 1-2 specific study strategies or resources.
Respond in JSON: {{ "recommendations": [{{ "topic": "...", "reason": "...", "suggested_resources": "..." }}] }}
"""
        # ... call Gemini, parse JSON ...

    return WeakTopicsResponse(weak_topics=weak, recommendations=recommendations)
```

Even a simple rule-based version is better than the current 404.

---

### Phase 3: Expand Curriculum Coverage

#### 3.1 Add More PDFs

Place properly named PDFs in `uploads/` following the convention:

```
class_8_science_eng.pdf
class_8_math_eng.pdf
class_8_bangla_eng.pdf
class_9_science_eng.pdf
class_9_math_eng.pdf
...
```

The filename parser expects: `class_{N}_{subject}_*.pdf`

#### 3.2 Re-ingest After Adding PDFs

```bash
# Activate Python 3.11 venv
. .rag-venv/Scripts/activate  # Windows
# . .rag-venv/bin/activate   # Linux/Mac

# Run ingestion
python -c "from rag.ingest import ingest_pdf; ingest_pdf('uploads/class_8_science_eng.pdf')"
```

Or create a batch script to ingest all PDFs in `uploads/`.

#### 3.3 Make `MAX_PAGES` Configurable

**File:** `rag/ingest.py`

```python
import os
MAX_PAGES = int(os.getenv("RAG_MAX_PAGES", "0")) or None  # 0 means no limit
```

---

### Phase 4: Performance & Robustness

#### 4.1 Lazy-Load Embedding Model

**File:** `rag/retrieve.py`

Move model loading from module level into a function with caching:

```python
from functools import lru_cache

@lru_cache(maxsize=1)
def get_embedder():
    return SentenceTransformer(EMBED_MODEL)

def retrieve_context(query, ...):
    embedder = get_embedder()
    ...
```

#### 4.2 Clean Up `ingest.py`

Delete the commented-out code (lines 1–236) or move it to a `rag/ingest_legacy.py` file. Keep only the active optimized ingestion logic.

#### 4.3 Add Request Validation

In `rag_router.py`, validate that `subject` and `class_level` in generation requests match ingested data. Return a clear error if no chunks exist for the requested subject/class:

```python
# Inside generate-exam endpoint
chunks = retrieve_context(subject=req.subject, class_level=req.class_level, ...)
if not chunks:
    raise HTTPException(404, f"No curriculum data found for {req.subject} class {req.class_level}. Please ingest the PDF first.")
```

---

### Phase 5: Integration Testing

#### 5.1 Test the Full Pipeline

```bash
# 1. Start RAG service
. .rag-venv/Scripts/activate
uvicorn rag_server:app --host 0.0.0.0 --port 8100

# 2. Test health
curl http://localhost:8100/health

# 3. Test retrieval
curl -X POST http://localhost:8100/rag/retrieve \
  -H "Content-Type: application/json" \
  -d '{"query": "photosynthesis", "subject": "science", "class_level": "8"}'

# 4. Test generation
curl -X POST http://localhost:8100/rag/generate-exam \
  -H "Content-Type: application/json" \
  -d '{"subject": "science", "class_level": "8", "num_questions": 5}'
```

#### 5.2 Verify Embedding Model Consistency

```python
# Quick check in Python
from sentence_transformers import SentenceTransformer
print(SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2").encode("test").shape)
# Should match the model used in both ingest.py and retrieve.py
```

---

## Environment Setup

### 1. Create / Activate Python 3.11 Virtual Environment

```bash
# If .rag-venv doesn't exist:
py -3.11 -m venv .rag-venv

# Activate (Windows)
. .rag-venv/Scripts/activate

# Activate (Linux/Mac)
. .rag-venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r rag/requirements.txt
```

### 3. Configure Environment

Copy `rag/.env.example` to `rag/.env`:

```dotenv
GEMINI_API_KEY=your-gemini-api-key-here
```

### 4. Ingest Curriculum PDFs

```bash
python -c "
from rag.ingest import ingest_pdf
import os
for f in os.listdir('uploads'):
    if f.endswith('.pdf'):
        ingest_pdf(os.path.join('uploads', f))
"
```

### 5. Start the RAG Service

```bash
uvicorn rag_server:app --host 0.0.0.0 --port 8100
```

---

## Running in Two-Process Mode (Recommended)

The backend and RAG service should run as separate processes:

```bash
# Terminal 1 — RAG service (Python 3.11)
. .rag-venv/Scripts/activate
uvicorn rag_server:app --host 0.0.0.0 --port 8100

# Terminal 2 — Backend (Python 3.14+)
cd backend
uv run uvicorn app.main:app --reload
```

The backend will discover the RAG service at `RAG_BASE_URL=http://localhost:8100/rag`.

---

## File Reference

| File | Purpose | Lines of Active Code |
|------|---------|---------------------|
| `rag/ingest.py` | PDF → chunks → embeddings → ChromaDB | ~150 (after removing commented code) |
| `rag/retrieve.py` | Query → embedding → ChromaDB search → context chunks | ~60 |
| `rag/generate.py` | Context + prompt → Gemini → JSON questions | ~120 |
| `rag/rag_router.py` | FastAPI router for RAG endpoints | ~80 |
| `rag_server.py` | Standalone FastAPI app mounting the router | ~30 |

---

## Completion Checklist

- [ ] Fix `retrieve.py` to use `paraphrase-multilingual-MiniLM-L12-v2`
- [ ] Change `get_collection()` to `get_or_create_collection()`
- [ ] Remove or relocate commented code in `ingest.py`
- [ ] Increase / make configurable `MAX_PAGES`
- [ ] Implement `POST /rag/weak-topics` endpoint
- [ ] Add empty-collection validation in `generate-exam`
- [ ] Lazy-load embedding model in `retrieve.py`
- [ ] Ingest all curriculum PDFs for supported classes/subjects
- [ ] Add integration tests for the full pipeline
- [ ] Document PDF naming convention (`class_{N}_{subject}_*.pdf`)
