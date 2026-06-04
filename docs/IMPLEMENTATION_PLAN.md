# ShikkhaAI — Team Implementation Plan (3 Developers, Parallel)

**Team Structure:**
- **Frontend Developer** — Flutter app (exam config, topics tab, gamification, spaces, teacher, admin)
- **Backend Developer** — FastAPI (new APIs, DB models, services, auth)
- **RAG Developer** — RAG service (retrieval, generation, space-scoped collections)

**Workflow:**
1. **Phase 0 (Day 1):** All 3 agree on API contracts and data models.
2. **Phase 1 (Days 2-10):** All 3 work in parallel on their layers using mocks/stubs.
3. **Phase 2 (Days 11-12):** Backend integrates with RAG (HTTP calls, testing).
4. **Phase 3 (Days 13-15):** Frontend integrates with Backend (end-to-end testing).

---

## Phase 0: Contract Definition (Day 1 — All 3 Developers)

Before writing any code, the team must agree on the following contracts. Each developer works against these contracts independently.

### Contract 1: Curriculum API (Backend ↔ Frontend)

```
GET /curriculum/{class_level}/{subject}/chapters
Response: { "success": true, "data": [
  { "name": "Structure of Matter", "order": 1 },
  { "name": "Force and Motion", "order": 2 }
]}

GET /curriculum/{class_level}/{subject}/topics?chapter={chapter}&search={query}
Response: { "success": true, "data": [
  { "id": 1, "topic": "Atom and Molecule", "chapter": "Structure of Matter",
    "chapter_order": 1, "display_order": 1 }
]}
```

### Contract 2: Modified Exam Generation (Frontend → Backend → RAG)

```
# Frontend → Backend
POST /exam/generate
Body: {
  "student_id": 1,
  "subject": "science",
  "chapter": "Light",           // NEW optional field
  "topic": "Reflection of Light",
  "class_level": "8",
  "difficulty": "medium",
  "num_questions": 5
}

# Backend → RAG (HTTP)
POST {RAG_BASE_URL}/rag/generate-exam
Body: {
  "student_id": 1,
  "subject": "science",
  "class_level": "8",
  "chapter": "Light",           // NEW optional field
  "topic": "Reflection of Light",
  "difficulty": "medium",
  "count": 5
}

# RAG → Backend → Frontend
Response: {
  "questions": [
    {
      "id": "1", "type": "mcq", "topic": "Reflection of Light",
      "subtopic": "Laws of Reflection",  // NEW optional field
      "prompt": "...", "options": [...],
      "answer": "A", "marks": 1
    }
  ]
}
```

### Contract 3: Modified Topics Endpoint (Backend → Frontend)

```
GET /student/{id}/topics
Response: {
  "success": true,
  "data": {
    "subjects": [
      {
        "subject": "science",
        "icon_name": "science",
        "total_topics": 50,
        "completed_topics": 12,
        "overall_completion_percentage": 24.0,
        "chapters": [              // NEW: nested chapter grouping
          {
            "chapter_name": "Structure of Matter",
            "chapter_order": 1,
            "total_topics": 6,
            "completed_topics": 2,
            "overall_completion_percentage": 33.3,
            "topics": [
              {
                "id": "topic_1",
                "name": "Atom and Molecule",
                "completion_percentage": 75.0,
                "attempts_count": 3,
                "last_score": 80.0,
                "last_attempted": "2026-06-01",
                "is_completed": true,
                "is_attempted": true
              }
            ]
          }
        ]
      }
    ],
    "total_topics": 50,
    "completed_topics": 12
  }
}
```

### Contract 4: Gamification API (Backend ↔ Frontend)

```
GET /gamification/me
Response: {
  "total_points": 1200,
  "coins": 120,
  "current_streak_days": 5,
  "longest_streak_days": 12,
  "current_plant": "Sunflower",
  "plant_growth_stage": 3,
  "plants_unlocked": ["Sunflower", "Rose"]
}

POST /gamification/focus-session/start
Body: { "subject": "science", "topic": "Light", "planned_minutes": 25 }
Response: { "session_id": 42 }

POST /gamification/focus-session/{id}/complete
Body: { "actual_minutes": 25, "tab_switches": 0 }
Response: {
  "points_earned": 100,
  "total_points": 1300,
  "coins": 130,
  "current_streak": 6,
  "plant_growth": 4,
  "session_completed": true
}
```

### Contract 5: Study Spaces API (Backend ↔ Frontend)

```
POST /spaces
Body: { "name": "Physics Tutor", "subject": "physics", "class_level": "8",
        "description": "All my physics books" }
Response: { "id": 1, "name": "Physics Tutor" }

GET /spaces
Response: { "data": [{ "id": 1, "name": "Physics Tutor", "subject": "physics",
                       "document_count": 3 }] }

POST /spaces/{id}/upload        # multipart/form-data
File: <binary PDF>
Response: { "id": 5, "filename": "physics_guide.pdf", "is_indexed": false }

GET /spaces/{id}/documents
Response: { "data": [{ "id": 5, "original_name": "physics_guide.pdf",
                       "file_size_bytes": 2048000, "is_indexed": true }] }

# Study companion scoped to space
POST /study-companion/ask
Body: { "query": "...", "mode": "easyEnglish", "subject": "physics",
        "class_level": "8", "space_id": 1 }
```

### Contract 6: RAG Service API (Backend ↔ RAG)

```
POST /rag/generate-exam
Body: {
  "student_id": 1,
  "subject": "science",
  "class_level": "8",
  "chapter": "Light",        // NEW
  "topic": "Reflection of Light",
  "difficulty": "medium",
  "count": 5,
  "space_id": null           // NEW optional
}

POST /rag/ask
Body: {
  "query": "...",
  "mode": "easyEnglish",
  "subject": "science",
  "class_level": "8",
  "space_id": 1,             // NEW optional
  "pdf_context": null
}

POST /rag/retrieve
Body: { "query": "...", "subject": "science", "class_level": "8", "chapter": "Light" }
Response: { "chunks": [{ "text": "...", "subject": "science", "class": "8",
                         "chapter": "Light", "distance": 0.12 }] }
```

---

## Phase 1: Parallel Development (Days 2-10)

### Frontend Developer Tasks

**Day 1-2: Exam Config Redesign**
1. Update `ExamConfig` model to add `chapter` field.
2. Create `curriculum_provider.dart` with `chaptersProvider` and `topicsProvider`.
3. Redesign `exam_config_screen.dart`:
   - Keep subject + class selectors.
   - Add chapter `DropdownButtonFormField` (watches `chaptersProvider`).
   - Replace topic `TextField` with `Autocomplete<String>` (watches `topicsProvider`).
4. **Mock data:** Since backend isn't ready yet, create a local mock list of chapters/topics for testing UI.

**Day 3-4: Topics Tab Chapter Grouping**
1. Update `topic_models.dart`: add `ChapterTopics`, update `SubjectTopics` to hold chapters.
2. Update `SubjectTopicsCard` to show `ExpansionTile` for each chapter.
3. Create `TopicListTile` with visual status indicators (green/orange/grey).
4. **Mock data:** Use hardcoded mock `TopicsOverview` with nested chapters.

**Day 5-6: Focus Garden & Gamification UI**
1. Create `gamification_provider.dart` with mock gamification state.
2. Build `FocusGardenWidget` (plant growth, points, streak, coins).
3. Build `FocusSessionScreen`:
   - Full-screen countdown timer.
   - `WidgetsBindingObserver` for app lifecycle (track pauses).
   - Animated plant widget that grows with progress.
   - WillPopScope to confirm exit.
4. Add `FocusGardenWidget` to the study plan screen.

**Day 7: Exam Anti-Cheat**
1. Add `WidgetsBindingObserver` to `ExamSessionScreen`.
2. Track tab switch count.
3. Show warning dialog on 1st/2nd switch.
4. Auto-submit on 3rd switch.

**Day 8-9: Study Spaces UI**
1. Create `features/spaces/` feature module.
2. Build `SpacesListScreen` (grid of cards).
3. Build `CreateSpaceScreen` (form: name, subject, class, description).
4. Build `SpaceDetailScreen` (document list + upload button + chat CTA).
5. **Mock data:** Local mock spaces and documents.

**Day 10: Teacher Module UI (Stubs)**
1. Create `features/teacher/` feature module.
2. Build `TeacherLoginScreen` stub.
3. Build `ClassroomDetailScreen` stub with heatmap placeholder.
4. Connect to mock teacher service.

### Backend Developer Tasks

**Day 1-2: Database Schema + Seed Data**
1. Modify `CurriculumTopic` model: add `chapter`, `chapter_order` fields.
2. Add `chapter` to `Exam` and `TopicPerformance` models.
3. Create `scripts/seed_curriculum.py` with NCTB Class 8 Science data.
4. Run seed script and verify data in DB.
5. Add ad-hoc migration in `session.py` for existing deployments.

**Day 3-4: Curriculum API + Modified Topics Endpoint**
1. Create `routes_curriculum.py`:
   - `GET /curriculum/{class}/{subject}/chapters`
   - `GET /curriculum/{class}/{subject}/topics`
2. Update `analytics_service.get_topics()` to group by chapter.
3. Test both endpoints with seeded data.

**Day 5-6: Gamification Backend**
1. Create `StudentGamification` and `FocusSession` models.
2. Create `gamification_service.py`:
   - Points calculation, streak logic, plant growth.
3. Create `routes_gamification.py`:
   - `GET /gamification/me`
   - `POST /gamification/focus-session/start`
   - `POST /gamification/focus-session/{id}/complete`
4. Add `StudentGamification` row creation on student registration.

**Day 7: Study Spaces Backend**
1. Create `StudySpace` and `SpaceDocument` models.
2. Create `study_space_service.py`:
   - Space CRUD, file upload with size/hash validation.
3. Create `routes_study_spaces.py`:
   - `POST /spaces`, `GET /spaces`
   - `POST /spaces/{id}/upload`, `GET /spaces/{id}/documents`
4. Ensure upload directory exists and is writable.

**Day 8-9: Teacher Module Backend**
1. Create `Teacher`, `Classroom`, `ClassroomEnrollment` models.
2. Create `teacher_service.py`:
   - Registration, login, classroom creation, dashboard data.
3. Create `routes_teachers.py`:
   - `POST /teacher/register`, `POST /teacher/login`
   - `POST /teacher/classrooms`, `GET /teacher/classrooms/{id}/dashboard`
4. Add `role` claim to JWT tokens.

**Day 10: Admin Panel Backend (Stubs)**
1. Create `Admin` model.
2. Create `routes_admin.py` with stub endpoints for curriculum CRUD.
3. Create `get_current_admin` dependency.

### RAG Developer Tasks

**Day 1-2: Chapter-Aware Retrieval**
1. Update `retrieve_context()` in `rag/retrieve.py`:
   - Accept optional `chapter` parameter.
   - Add chapter to ChromaDB `where` filter.
2. Update `build_rag_context()` to pass `chapter` through.
3. Test retrieval with chapter filter using existing ChromaDB data.

**Day 3-4: Chapter-Aware Generation**
1. Update `generate_questions()` in `rag/generate.py`:
   - Accept optional `chapter` parameter.
   - Add `CHAPTER` block to prompt.
   - Add `subtopic` field to question JSON schema.
2. Update `build_prompt()` with chapter and subtopic constraints.
3. Update `rag/rag_router.py`:
   - Add `chapter` to `GenerateRequest`.
   - Pass `chapter` to `generate_questions()`.
4. Test generation with chapter parameter.

**Day 5-6: Space-Scoped Collections**
1. Update `get_collection()` to accept `collection_name` parameter.
2. Modify `index_file()` in `rag/ingest.py` to support custom collections.
3. Create helper `index_space_document(space_id, file_path)`.
4. Update `retrieve_context()` to accept `space_id` and query space-specific collection.
5. Update `rag/rag_router.py`:
   - Add `space_id` to `GenerateRequest` and `AskRequest`.
6. Test with a dummy space collection.

**Day 7-8: Subtopic Generation**
1. Update prompt in `generate_questions()` to require `subtopic` field.
2. Add subtopic validation in `extract_json()` or post-processing.
3. Update `rag/rag_router.py` response to include subtopics.
4. Test that generated questions contain subtopic fields.

**Day 9-10: RAG Integration Testing**
1. Ensure all RAG endpoints work standalone.
2. Document any API changes for backend developer.
3. Test edge cases: no context, empty chapter, invalid space_id.

---

## Phase 2: Backend-RAG Integration (Days 11-12)

### Backend Developer + RAG Developer Collaboration

**Day 11: Connect Exam Generation to RAG**
1. Backend: Update `rag_client.py`:
   - Add `chapter` parameter to `generate_exam()`.
   - Add `space_id` parameter to `ask()`.
2. Backend: Update `exam_service.py` to pass `chapter` to RAG client.
3. RAG: Ensure `rag_server.py` is running and reachable.
4. Test: `Backend → RAG /rag/generate-exam` with chapter.
5. Test: `Backend → RAG /rag/ask` with space_id.

**Day 12: Integration Testing & Bug Fixes**
1. Test full flow: Frontend config → Backend → RAG → Backend → DB.
2. Test space-scoped retrieval: upload PDF → index → query.
3. Test chapter filtering: verify RAG returns chapter-relevant chunks.
4. Fix any contract mismatches between Backend and RAG.

---

## Phase 3: Frontend-Backend Integration (Days 13-15)

### Frontend Developer + Backend Developer Collaboration

**Day 13: Connect Frontend to Real APIs (Part 1)**
1. Remove mock data from `curriculum_provider.dart`.
2. Connect to real `GET /curriculum/{class}/{subject}/chapters` and `/topics`.
3. Test exam config: chapter dropdown + topic autocomplete.
4. Remove mock from `topics_provider.dart`.
5. Connect to real `GET /student/{id}/topics`.
6. Test topics tab: chapter-wise grouping with real data.

**Day 14: Connect Frontend to Real APIs (Part 2)**
1. Connect `gamification_provider.dart` to real `/gamification/me`.
2. Test focus session: start → timer → complete → points update.
3. Connect `spaces_provider.dart` to real `/spaces` endpoints.
4. Test space creation, upload, and document listing.
5. Update study companion to send `space_id` when chatting from a space.

**Day 15: End-to-End Testing & Polish**
1. Full exam flow: Config → Generate → Take → Submit → Results.
2. Test tab switch detection in real exam session.
3. Test Focus Garden: session completion → plant growth → streak update.
4. Test teacher module login and dashboard (if time permits).
5. Fix UI bugs, loading states, error handling.

---

## File Checklist by Developer

### Frontend Developer Files

**New files:**
- `frontend/lib/features/exam/presentation/providers/curriculum_provider.dart`
- `frontend/lib/features/topics/data/models/chapter_models.dart` (update existing)
- `frontend/lib/features/topics/widgets/topic_list_tile.dart`
- `frontend/lib/features/topics/widgets/chapter_topics_card.dart`
- `frontend/lib/features/study_plan/presentation/widgets/focus_garden_widget.dart`
- `frontend/lib/features/study_plan/presentation/screens/focus_session_screen.dart`
- `frontend/lib/features/study_plan/presentation/providers/gamification_provider.dart`
- `frontend/lib/features/spaces/data/models/space_model.dart`
- `frontend/lib/features/spaces/presentation/providers/spaces_provider.dart`
- `frontend/lib/features/spaces/presentation/screens/spaces_list_screen.dart`
- `frontend/lib/features/spaces/presentation/screens/space_detail_screen.dart`
- `frontend/lib/features/spaces/presentation/screens/create_space_screen.dart`
- `frontend/lib/features/teacher/presentation/screens/teacher_login_screen.dart`
- `frontend/lib/features/teacher/presentation/screens/classroom_detail_screen.dart`

**Modified files:**
- `frontend/lib/features/exam/data/models/exam_config_model.dart`
- `frontend/lib/features/exam/presentation/screens/exam_config_screen.dart`
- `frontend/lib/features/exam/presentation/screens/exam_session_screen.dart`
- `frontend/lib/features/topics/data/models/topic_models.dart`
- `frontend/lib/features/topics/presentation/screens/topics_shell_screen.dart`
- `frontend/lib/features/topics/widgets/subject_topics_card.dart`
- `frontend/lib/features/study_companion/presentation/screens/study_companion_screen.dart` (add space_id)

### Backend Developer Files

**New files:**
- `backend/app/db/migrations/curriculum_chapter.py` (ad-hoc migration script)
- `backend/scripts/seed_curriculum.py`
- `backend/app/api/routes_curriculum.py`
- `backend/app/api/routes_gamification.py`
- `backend/app/api/routes_study_spaces.py`
- `backend/app/api/routes_teachers.py`
- `backend/app/api/routes_admin.py`
- `backend/app/services/gamification_service.py`
- `backend/app/services/study_space_service.py`
- `backend/app/services/teacher_service.py`
- `backend/app/services/adaptive_practice_service.py` (Sprint 2)
- `backend/app/schemas/curriculum.py`
- `backend/app/schemas/gamification.py`
- `backend/app/schemas/study_space.py`
- `backend/app/schemas/teacher.py`

**Modified files:**
- `backend/app/db/models.py` (add chapter to CurriculumTopic, Exam, TopicPerformance; new models)
- `backend/app/db/session.py` (add migration logic)
- `backend/app/schemas/exam.py` (add chapter, subtopic)
- `backend/app/api/routes_exams.py` (pass chapter to service)
- `backend/app/api/routes_analytics.py` (no change, service handles it)
- `backend/app/api/routes_study_companion.py` (accept space_id)
- `backend/app/services/exam_service.py` (pass chapter to RAG client)
- `backend/app/services/analytics_service.py` (group by chapter)
- `backend/app/services/grading_service.py` (track subtopic performance)
- `backend/app/external/rag_client.py` (add chapter, space_id params)
- `backend/app/main.py` (register new routers)

### RAG Developer Files

**Modified files:**
- `rag/retrieve.py` (chapter filter, space_id collection)
- `rag/generate.py` (chapter prompt, subtopic field)
- `rag/rag_router.py` (chapter in GenerateRequest, space_id in requests)
- `rag/ingest.py` (support custom collection names for spaces)

---

## Daily Standup Questions

Each day, all 3 developers should answer:
1. What contract/interface did you work against today?
2. Are there any contract changes needed?
3. Are you blocked waiting for another developer?

If any developer needs to change a contract, they must notify the others immediately and update the shared contract documentation (this plan file, Section "Phase 0").

---

## Risk Mitigation for Parallel Development

| Risk | Mitigation |
|------|-----------|
| Frontend blocked waiting for backend API | Frontend uses mock providers that match the contract exactly. Switch to real APIs by changing one line. |
| Backend blocked waiting for RAG changes | Backend implements mock RAG responses in `rag_client.py` for missing features. |
| Contract mismatch discovered late | Daily standups + strict contract-first approach. Changes require team notification. |
| ChromaDB chapter metadata all "1" | RAG developer adds prompt-based chapter constraint as fallback. Re-ingestion happens after initial integration. |
| Flutter build_runner issues | Frontend developer commits generated `.g.dart` files during integration week to avoid conflicts. |
| File upload size issues | Backend validates 50MB limit. Frontend shows progress indicator and validates before upload. |
