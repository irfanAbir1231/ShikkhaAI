import logging
from typing import Any

from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import success_response
from app.db.models import Student
from app.db.session import get_db
from app.core.responses import AppError
from app.schemas.note import NoteCreate, NoteGenerateRequest, NoteResponse
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