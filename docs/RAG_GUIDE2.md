# RAG Guide 2 — Planned Features Implementation

## 1. Chapter-Aware Retrieval

### Updated `retrieve_context()`
```python
def retrieve_context(
    query: str,
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
    chapter: Optional[str] = None,
    n_results: int = 3,
) -> list[dict]:
    filters = []
    if subject: filters.append({"subject": subject})
    if class_level: filters.append({"class": class_level})
    if chapter: filters.append({"chapter": chapter})

    where = {"$and": filters} if len(filters) > 1 else (filters[0] if filters else None)
```

### Prompt Update
When `chapter` is provided, the prompt includes:
```
CHAPTER:
Generate questions from the chapter "{chapter}".
```

## 2. Space-Scoped Collections

Each study space gets its own ChromaDB collection:
```python
collection_name = f"space_{space_id}"
col = get_collection(collection_name)
```

When indexing a space document:
```python
# In ingest.py
index_file(path, col, model, meta_override={
    "space_id": str(space_id),
    "source": filename,
})
```

### Retrieval by Space
```python
def retrieve_from_space(query: str, space_id: int, n_results: int = 3):
    collection = get_collection(f"space_{space_id}")
    # ... encode and query
```

## 3. Subtopic Generation

Updated prompt in `generate.py`:
```python
"""
Each question MUST include a "subtopic" field that is more specific than the main topic.
Example: if topic is "Reflection of Light", subtopic could be "Laws of Reflection".
"""
```

The backend uses this `subtopic` field to update `SubtopicPerformance` after grading.

## 4. Re-ingesting PDFs with Chapter Metadata

For existing PDFs to support chapter filtering, re-ingest with proper chapter metadata:

```python
# manual_chapter_mapping = {
#     "class_8_science_eng.pdf": {
#         "pages_1_15": "Structure of Matter",
#         "pages_16_30": "Force and Motion",
#         # ... etc
#     }
# }
```

Since `MAX_PAGES = 15`, the current ingestion only covers the first 15 pages (roughly Chapter 1). To support all chapters, increase `MAX_PAGES` or ingest chapter-by-chapter.

For now, chapter filtering at the ChromaDB level will return all chunks (since all have `chapter="1"`). The prompt-based chapter constraint still works.

## 5. RAG Service Environment

The RAG service runs on Python 3.11 only:
```bash
. .rag-venv/bin/activate
uvicorn rag_server:app --host 0.0.0.0 --port 8100
```

New dependencies (if any) go in `rag/requirements.txt`.

## 6. Testing RAG Endpoints

```bash
# Test chapter-aware generation
curl -X POST http://localhost:8100/rag/generate-exam \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": 1,
    "subject": "science",
    "class_level": "8",
    "chapter": "Light",
    "topic": "Reflection of Light",
    "difficulty": "medium",
    "count": 5
  }'

# Test space-scoped retrieval
curl -X POST http://localhost:8100/rag/retrieve \
  -H "Content-Type: application/json" \
  -d '{"query": "force", "subject": "science", "class_level": "8"}'
```

## 7. Fallback when Space Collection is Empty

If a space has no indexed documents, return:
```python
{"response": "No documents found in this space. Please upload PDFs first.", "sources": []}
```

## 8. Running the RAG Service

```bash
. .rag-venv/bin/activate  # or .rag-venv\Scripts\activate on Windows
uvicorn rag_server:app --host 0.0.0.0 --port 8100 --reload
```
