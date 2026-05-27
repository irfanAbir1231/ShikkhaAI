import logging
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.db.models import Note, utc_now
from app.db.transactions import safe_commit
from app.schemas.note import NoteCreate

logger = logging.getLogger("shikkhaai")


class NoteService:
    def create_note(self, db: Session, student_id: int, payload: NoteCreate) -> Note:
        note = Note(
            student_id=student_id,
            title=payload.title,
            content=payload.content,
            topic=payload.topic,
            subject=payload.subject,
            class_level=payload.class_level,
            source=payload.source,
        )
        db.add(note)
        safe_commit(db)
        db.refresh(note)
        logger.info("Created note id=%s student_id=%s", note.id, student_id)
        return note

    def list_notes(
        self,
        db: Session,
        student_id: int,
        topic: str | None = None,
        source: str | None = None,
    ) -> list[Note]:
        stmt = select(Note).where(Note.student_id == student_id).order_by(Note.created_at.desc())
        if topic:
            stmt = stmt.where(Note.topic == topic)
        if source:
            stmt = stmt.where(Note.source == source)
        return list(db.scalars(stmt).all())

    def get_note(self, db: Session, student_id: int, note_id: int) -> Note:
        note = db.get(Note, note_id)
        if note is None or note.student_id != student_id:
            raise AppError(code="NOTE_NOT_FOUND", message="Note not found.", status_code=404)
        return note

    def delete_note(self, db: Session, student_id: int, note_id: int) -> None:
        note = self.get_note(db, student_id, note_id)
        db.delete(note)
        safe_commit(db)
        logger.info("Deleted note id=%s student_id=%s", note_id, student_id)