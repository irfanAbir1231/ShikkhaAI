# Backend Guide 2 — Planned Features Implementation

## 1. Database Migrations

Since the project uses `Base.metadata.create_all()` without Alembic:

### Development (SQLite)
Simply delete `shikkhaai.db` and restart — tables are recreated.

### Production (PostgreSQL on Render)
Add ad-hoc ALTER statements in `session.py` inside `init_db()`:

```python
def init_db():
    Base.metadata.create_all(bind=engine)
    _run_migrations(engine)

def _run_migrations(engine):
    from sqlalchemy import text, inspect
    inspector = inspect(engine)
    cols = [c["name"] for c in inspector.get_columns("curriculum_topics")]
    with engine.connect() as conn:
        if "chapter" not in cols:
            conn.execute(text("ALTER TABLE curriculum_topics ADD COLUMN chapter VARCHAR(150) NOT NULL DEFAULT 'General'"))
        if "chapter_order" not in cols:
            conn.execute(text("ALTER TABLE curriculum_topics ADD COLUMN chapter_order INTEGER NOT NULL DEFAULT 0"))
        conn.commit()
```

## 2. Seeding Curriculum Data

```bash
cd backend
uv run python scripts/seed_curriculum.py
```

This populates `CurriculumTopic` with NCTB Class 8 Science chapters and topics.

Verify:
```bash
sqlite3 shikkhaai.db "SELECT chapter, topic FROM curriculum_topics WHERE class_level='8' AND subject='science' LIMIT 10;"
```

## 3. New Service Pattern

All new features follow the existing pattern:
```
Route (api/routes_*.py) → Service (services/*.py) → Model (db/models.py)
```

Example: `routes_gamification.py` → `gamification_service.py` → `StudentGamification`

## 4. Mock RAG Client

During Phase 1, if RAG endpoints are not ready, implement mock responses:

```python
# In rag_client.py
def generate_exam(self, payload: dict) -> dict:
    if settings.mock_mode or not settings.rag_base_url:
        return self._mock_generate_exam(payload)
    # ... real HTTP call
```

## 5. File Upload

Study spaces use `UploadFile` from FastAPI:
```python
from fastapi import UploadFile, File

@router.post("/{space_id}/upload")
async def upload(space_id: int, file: UploadFile = File(...)):
    content = await file.read()
    if len(content) > 50 * 1024 * 1024:
        raise HTTPException(413, "File too large")
    # ... save and hash
```

Max file size: 50 MB per file.
Max files per space: 20.

## 6. Teacher Authentication

Teachers use the same JWT pattern as students but with a separate secret or role claim:
```python
# In the JWT payload, add a "role" claim
token = create_access_token({"sub": str(teacher.id), "role": "teacher"})
```

`get_current_teacher` dependency checks the role claim:
```python
async def get_current_teacher(token: str = Depends(oauth2_scheme)):
    payload = decode_token(token)
    if payload.get("role") != "teacher":
        raise HTTPException(403, "Not a teacher")
    # ... lookup teacher
```

## 7. RAG Client Updates

When calling the RAG service, pass `chapter` and `space_id`:
```python
rag_client.generate_exam({
    "subject": "science",
    "class_level": "8",
    "chapter": "Light",
    "topic": "Reflection of Light",
    "space_id": 5,  # optional
})
```

## 8. Testing New Endpoints

```bash
cd backend
uv run pytest tests/ -q -k "test_curriculum or test_gamification"
```

Add new test files:
- `tests/test_curriculum.py`
- `tests/test_gamification.py`
- `tests/test_study_spaces.py`
- `tests/test_teacher.py`

## 9. New Router Registration

In `app/main.py`:
```python
from app.api.routes_curriculum import router as curriculum_router
from app.api.routes_gamification import router as gamification_router
from app.api.routes_study_spaces import router as spaces_router
from app.api.routes_teachers import router as teacher_router

app.include_router(curriculum_router)
app.include_router(gamification_router)
app.include_router(spaces_router)
app.include_router(teacher_router)
```

## 10. Render Deployment Notes

The `render.yaml` Blueprint provisions:
- Backend web service (Python 3.12)
- RAG web service (Python 3.11, `plan: starter` for 512MB+ RAM)
- Managed PostgreSQL

New environment variables needed:
```
ADMIN_SECRET_KEY=...          # For admin JWT signing
MAX_UPLOAD_SIZE_MB=50
SPACES_UPLOAD_DIR=/tmp/spaces
```
