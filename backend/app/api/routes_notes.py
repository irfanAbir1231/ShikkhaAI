import logging
from typing import Any

from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import success_response
from app.db.models import Student
from app.db.session import get_db
from app.core.responses import AppError
from app.schemas.note import (
    NoteCreate,
    NoteGenerateRequest,
    NoteResponse,
    NoteVersionResponse,
    SavedNoteResponse,
)
from app.services.note_service import NoteService

logger = logging.getLogger("shikkhaai")
router = APIRouter(prefix="/notes", tags=["notes"])
note_service = NoteService()


@router.post("")
def create_note(
    payload: NoteCreate,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    note = note_service.create_note(db=db, student_id=current_student.id, payload=payload)
    return success_response(NoteResponse.model_validate(note).model_dump())


@router.post("/generate")
def generate_note(
    payload: NoteGenerateRequest,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    from app.services.note_generation_service import NoteGenerationService

    gen_service = NoteGenerationService()
    try:
        note = gen_service.generate_note_for_topic(
            db=db,
            student_id=current_student.id,
            topic=payload.topic,
            subject=payload.subject,
            class_level=current_student.grade_level,
        )
    except RuntimeError as exc:
        raise AppError(
            code="NOTE_GENERATION_FAILED",
            message=str(exc),
            status_code=503,
        ) from exc
    return success_response(NoteResponse.model_validate(note).model_dump())


@router.get("")
def list_notes(
    topic: str | None = Query(default=None),
    source: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    notes = note_service.list_notes(
        db=db, student_id=current_student.id, topic=topic, source=source
    )
    return success_response([NoteResponse.model_validate(n).model_dump() for n in notes])


@router.get("/{note_id}")
def get_note(
    note_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    note = note_service.get_note(db=db, student_id=current_student.id, note_id=note_id)
    return success_response(NoteResponse.model_validate(note).model_dump())


@router.delete("/{note_id}")
def delete_note(
    note_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    note_service.delete_note(db=db, student_id=current_student.id, note_id=note_id)
    return success_response({"deleted": True, "note_id": note_id})


# ── Versions ──────────────────────────────────────────────────────────────────

@router.get("/{note_id}/versions")
def list_note_versions(
    note_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    versions = note_service.get_note_versions(db=db, student_id=current_student.id, note_id=note_id)
    return success_response([NoteVersionResponse.model_validate(v).model_dump() for v in versions])


@router.get("/{note_id}/versions/{version}")
def get_note_version(
    note_id: int = Path(gt=0),
    version: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    v = note_service.get_note_version(db=db, student_id=current_student.id, note_id=note_id, version=version)
    return success_response(NoteVersionResponse.model_validate(v).model_dump())


# ── Saved Notes ───────────────────────────────────────────────────────────────

@router.post("/{note_id}/save")
def save_note(
    note_id: int = Path(gt=0),
    bookmarked: bool = False,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    saved = note_service.save_note(db=db, student_id=current_student.id, note_id=note_id, bookmarked=bookmarked)
    return success_response(SavedNoteResponse.model_validate(saved).model_dump())


@router.delete("/{note_id}/save")
def unsave_note(
    note_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    note_service.unsave_note(db=db, student_id=current_student.id, note_id=note_id)
    return success_response({"unsaved": True, "note_id": note_id})


@router.post("/{note_id}/bookmark")
def toggle_bookmark(
    note_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    saved = note_service.toggle_bookmark(db=db, student_id=current_student.id, note_id=note_id)
    return success_response(SavedNoteResponse.model_validate(saved).model_dump())


@router.get("/saved/list")
def list_saved_notes(
    bookmarked_only: bool = False,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    saved = note_service.list_saved_notes(db=db, student_id=current_student.id, bookmarked_only=bookmarked_only)
    # Enrich with note titles
    result = []
    for s in saved:
        note = note_service.get_note(db=db, student_id=current_student.id, note_id=s.note_id)
        result.append({
            "id": s.id,
            "note_id": s.note_id,
            "title": note.title,
            "topic": note.topic,
            "bookmarked": s.bookmarked,
            "saved_at": s.saved_at.isoformat(),
        })
    return success_response(result)