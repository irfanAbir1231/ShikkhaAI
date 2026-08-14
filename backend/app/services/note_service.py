import logging
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.db.models import Note, NoteVersion, SavedNote, utc_now
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

    # ── Versioning ─────────────────────────────────────────────────────────────

    def get_note_versions(self, db: Session, student_id: int, note_id: int) -> list[NoteVersion]:
        note = self.get_note(db, student_id, note_id)
        return list(db.scalars(
            select(NoteVersion).where(NoteVersion.note_id == note.id).order_by(NoteVersion.version.desc())
        ).all())

    def get_note_version(self, db: Session, student_id: int, note_id: int, version: int) -> NoteVersion:
        note = self.get_note(db, student_id, note_id)
        version_row = db.scalar(
            select(NoteVersion).where(
                NoteVersion.note_id == note.id,
                NoteVersion.version == version,
            )
        )
        if version_row is None:
            raise AppError(code="VERSION_NOT_FOUND", message="Note version not found.", status_code=404)
        return version_row

    # ── Saved Notes ────────────────────────────────────────────────────────────

    def save_note(self, db: Session, student_id: int, note_id: int, bookmarked: bool = False) -> SavedNote:
        note = self.get_note(db, student_id, note_id)
        existing = db.scalar(
            select(SavedNote).where(
                SavedNote.student_id == student_id,
                SavedNote.note_id == note_id,
            )
        )
        if existing:
            existing.bookmarked = bookmarked
            db.flush()
            return existing

        saved = SavedNote(student_id=student_id, note_id=note_id, bookmarked=bookmarked)
        db.add(saved)
        safe_commit(db)
        db.refresh(saved)
        return saved

    def unsave_note(self, db: Session, student_id: int, note_id: int) -> None:
        saved = db.scalar(
            select(SavedNote).where(
                SavedNote.student_id == student_id,
                SavedNote.note_id == note_id,
            )
        )
        if saved:
            db.delete(saved)
            safe_commit(db)

    def list_saved_notes(self, db: Session, student_id: int, bookmarked_only: bool = False) -> list[SavedNote]:
        stmt = select(SavedNote).where(SavedNote.student_id == student_id).order_by(SavedNote.saved_at.desc())
        if bookmarked_only:
            stmt = stmt.where(SavedNote.bookmarked == True)
        return list(db.scalars(stmt).all())

    def toggle_bookmark(self, db: Session, student_id: int, note_id: int) -> SavedNote:
        saved = db.scalar(
            select(SavedNote).where(
                SavedNote.student_id == student_id,
                SavedNote.note_id == note_id,
            )
        )
        if saved:
            saved.bookmarked = not saved.bookmarked
            safe_commit(db)
            return saved
        return self.save_note(db, student_id, note_id, bookmarked=True)
