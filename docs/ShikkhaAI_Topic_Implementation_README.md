# ShikkhaAI Topic Availability Feature

This README explains how to implement the missing **chapter/topic extraction workflow** so the frontend can show which topics are currently available for a student to generate an exam.

The key idea is:
1. Extract textbook content.
2. Split the content into **chapters** and **topics/sections**.
3. Store those topic sections in ChromaDB with metadata.
4. Expose an API that returns the available topics for a student.
5. Connect that API to the Flutter frontend topic screen.

---

## 1) What already exists

### 1.1 Frontend topic screen already exists
The Flutter app already has a real topic UI under:

- `frontend/lib/features/topics/presentation/screens/topics_shell_screen.dart`
- `frontend/lib/features/topics/presentation/providers/topics_provider.dart`
- `frontend/lib/features/topics/data/datasources/topics_remote_datasource.dart`
- `frontend/lib/features/topics/domain/repositories/topics_repository.dart`

The frontend already expects topic data from a backend endpoint and renders a subject/topic overview screen.

### 1.2 Backend topic overview endpoint already exists
The backend already exposes:

- `GET /student/{student_id}/topics`

This route is defined in:

- `backend/app/api/routes_analytics.py`

The current implementation uses curriculum topic records and topic performance data.

### 1.3 RAG service already exists
The RAG module already contains:

- `rag/ingest.py`
- `rag/retrieve.py`
- `rag/generate.py`
- `rag/rag_router.py`

The RAG router already exposes routes such as:

- `POST /rag/generate-exam`
- `POST /rag/retrieve`
- `POST /rag/context`
- `POST /rag/ask`
- `POST /rag/weak-topics`

---

## 2) What is missing

The repo currently does **not** clearly implement the following textbook-topic segmentation workflow:

- detect sections/topics inside extracted textbook text,
- assign those topics to a chapter,
- store topic-level metadata in ChromaDB,
- expose those extracted topics in the API,
- use those topic labels in the frontend exam/topic availability screen.

So the existing `/student/{student_id}/topics` endpoint is good for curriculum analytics, but it is not yet the same thing as “topics extracted from textbook content.”

---

## 3) Recommended algorithm for chapter/topic extraction

Use a **hybrid segmentation algorithm**.

### Stage A — structural parsing
In the file that ingests textbooks, detect:
- chapter titles,
- section headings,
- subheadings,
- paragraph boundaries,
- page numbers.

Suggested heuristics:
- numbering patterns like `1.`, `1.1`, `Chapter 3`, `3.2.1`,
- capitalized heading lines,
- font-size or layout cues if PDF parsing preserves them,
- line spacing and punctuation patterns.

### Stage B — topic boundary detection
Split each chapter into topics using lexical cohesion / semantic similarity.
A practical approach is:
- create windows of consecutive paragraphs,
- compute similarity between windows,
- mark a boundary when similarity drops sharply,
- merge very small segments.

### Stage C — topic labeling
After a segment is detected:
- derive a topic label from the heading if one exists,
- otherwise create a label from the most representative keywords,
- optionally use Gemini to generate a short human-readable topic title.

### Stage D — metadata storage
Store each extracted topic as a ChromaDB record with metadata such as:
- `book_id`
- `chapter_id`
- `chapter_title`
- `topic_title`
- `topic_order`
- `page_start`
- `page_end`
- `subject`
- `class_level`
- `chunk_ids`

This allows the backend to return topic availability and also retrieve a precise topic context for exam generation.

---

## 4) File-by-file implementation plan

### 4.1 Add topic extraction logic
Create a new service file:

- `rag/topic_segmenter.py`

Responsibilities:
- accept extracted textbook text,
- split it into chapters and topics,
- produce structured topic records,
- return metadata ready for ChromaDB insertion.

Recommended functions:
- `extract_chapter_structure(...)`
- `segment_topics(...)`
- `label_topic_segment(...)`
- `build_topic_documents(...)`

### 4.2 Update the ingestion pipeline
Modify:

- `rag/ingest.py`

Responsibilities:
- call `rag/topic_segmenter.py`,
- store chapter and topic metadata in ChromaDB,
- keep the old chunk-level retrieval behavior,
- also index extracted topics as first-class records.

### 4.3 Update retrieval and generation
Modify:

- `rag/retrieve.py`
- `rag/generate.py`

Responsibilities:
- retrieve topic-aware context,
- allow filtering by `chapter_title` and `topic_title`,
- prefer topic-level chunks when a topic is selected in the frontend.

### 4.4 Expose the topic extraction API in the RAG router
Modify:

- `rag/rag_router.py`

Add a new endpoint such as:
- `POST /rag/extract-topics`

This endpoint should:
- accept textbook reference / book id / chapter text,
- call `rag/topic_segmenter.py`,
- return structured chapter-topic JSON.

If the extracted topics are already stored during ingestion, the endpoint can also be a read endpoint such as:
- `GET /rag/topics/{book_id}`

### 4.5 Mount the RAG router in the backend app
Modify:

- `backend/app/main.py`

Add the router import and mount it explicitly:
- `from rag.rag_router import router as rag_router`
- `app.include_router(rag_router, prefix="/rag")`

This is the place where the backend actually exposes the RAG endpoints to the application.

### 4.6 Extend backend topic API if extracted topics should be shown
Modify:

- `backend/app/api/routes_analytics.py`
- `backend/app/services/analytics_service.py`

Current behavior:
- `routes_analytics.py` already exposes `GET /student/{student_id}/topics`
- `analytics_service.py` already assembles topic availability from curriculum/performance data

New behavior to add:
- optionally merge extracted textbook-topic availability with curriculum topics,
- optionally add a new endpoint such as:
  - `GET /student/{student_id}/available-topics`
  - or `GET /student/{student_id}/topics/from-textbooks`

If a new endpoint is added, it should live in:
- `backend/app/api/routes_analytics.py`

and call a new service function in:
- `backend/app/services/analytics_service.py`

or a new file such as:
- `backend/app/services/topic_availability_service.py`

### 4.7 Connect the frontend to the final backend response
Modify:

- `frontend/lib/features/topics/data/datasources/topics_remote_datasource.dart`
- `frontend/lib/features/topics/domain/repositories/topics_repository.dart`
- `frontend/lib/features/topics/presentation/providers/topics_provider.dart`
- `frontend/lib/features/topics/presentation/screens/topics_shell_screen.dart`

Current behavior:
- `topics_remote_datasource.dart` already calls `GET /student/{studentId}/topics`
- `topics_provider.dart` already wires the UI state
- `topics_shell_screen.dart` already renders the topic cards

What to change:
- If the backend response format changes, update the parser in `topics_remote_datasource.dart`.
- If a new endpoint is created, add a new remote method there.
- If the UI needs a new filter for textbook-derived topics, add it in `topics_shell_screen.dart`.

---

## 5) Suggested API contract

### 5.1 Extract topic structure from a chapter
`POST /rag/extract-topics`

Example request:
```json
{
  "book_id": "science_grade_8",
  "chapter_title": "Force and Motion",
  "chapter_text": "...full chapter text...",
  "subject": "Science",
  "class_level": 8
}
```

Example response:
```json
{
  "book_id": "science_grade_8",
  "chapter_title": "Force and Motion",
  "topics": [
    {
      "topic_title": "Types of Force",
      "topic_order": 1,
      "page_start": 12,
      "page_end": 14,
      "chunk_ids": ["..."]
    }
  ]
}
```

### 5.2 Get available topics for a student
`GET /student/{student_id}/topics`

Keep this endpoint if the frontend already depends on it.

If extracted textbook topics are required separately, add:
- `GET /student/{student_id}/available-topics`

### 5.3 Use a topic in exam generation
`POST /rag/generate-exam`

The request may include:
- `topic`
- `chapter_title`
- `subject`
- `difficulty`
- `count`

The RAG generator should use the selected topic as a retrieval filter.

---

## 6) Acceptance criteria

The implementation is complete when:

1. `rag/topic_segmenter.py` can split one chapter into multiple topic sections.
2. `rag/ingest.py` stores those topic sections in ChromaDB.
3. `rag/rag_router.py` exposes a topic extraction endpoint.
4. `backend/app/main.py` mounts the RAG router.
5. `backend/app/api/routes_analytics.py` returns topic availability in a stable API.
6. `frontend/lib/features/topics/data/datasources/topics_remote_datasource.dart` reads the API successfully.
7. `frontend/lib/features/topics/presentation/screens/topics_shell_screen.dart` shows the available topics to the student.
8. Exam generation can optionally filter context by selected topic.

---

## 7) Practical implementation order

1. Add the segmentation logic in `rag/topic_segmenter.py`.
2. Update `rag/ingest.py` to store chapter-topic metadata.
3. Add or extend the API in `rag/rag_router.py`.
4. Mount the router in `backend/app/main.py`.
5. Extend `backend/app/api/routes_analytics.py` and `backend/app/services/analytics_service.py` if needed.
6. Update `frontend/lib/features/topics/data/datasources/topics_remote_datasource.dart`.
7. Confirm the UI in `frontend/lib/features/topics/presentation/screens/topics_shell_screen.dart`.

---

## 8) Notes

- Keep the existing curriculum-based topic logic intact unless the new textbook-topic model fully replaces it.
- A chapter should not be treated as a single topic; it should be segmented into smaller readable sections.
- Store chapter-level and topic-level metadata separately so exam generation can use either granularity.
- Make the API response deterministic and stable so the frontend can cache it safely.
