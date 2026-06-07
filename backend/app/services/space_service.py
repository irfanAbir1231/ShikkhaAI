import logging
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.responses import AppError
from app.db.models import utc_now
from app.db.transactions import safe_commit
from app.schemas.space import SpaceCreate, SpaceUpdate

logger = logging.getLogger("shikkhaai")

# ── RAG service calls ─────────────────────────────────────────────────────────

def _rag_post(path: str, **kwargs) -> dict:
    """POST to the RAG service. Raises RuntimeError on failure."""
    if not settings.rag_base_url:
        raise RuntimeError("RAG_BASE_URL is not configured.")
    try:
        with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
            resp = client.post(f"{settings.rag_base_url}{path}", **kwargs)
            resp.raise_for_status()
            return resp.json()
    except httpx.ConnectError as exc:
        raise RuntimeError(
            f"RAG service at {settings.rag_base_url} is not reachable."
        ) from exc
    except httpx.HTTPError as exc:
        raise RuntimeError(f"RAG service error: {exc}") from exc


def _rag_delete(path: str, json: dict) -> dict:
    if not settings.rag_base_url:
        raise RuntimeError("RAG_BASE_URL is not configured.")
    try:
        with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
            resp = client.request(
                "DELETE",
                f"{settings.rag_base_url}{path}",
                json=json,
            )
            resp.raise_for_status()
            return resp.json()
    except httpx.HTTPError as exc:
        # Non-fatal — log and continue (chunk cleanup should not block user operations)
        logger.warning("RAG delete failed (%s): %s", path, exc)
        return {}


def _ingest_to_rag(
    space_id: int,
    filename: str,
    pdf_bytes: bytes,
    subject: str | None,
    class_level: str | None,
) -> dict:
    """Send the PDF to the RAG service for ingestion into ChromaDB."""
    data: dict[str, Any] = {"space_id": str(space_id)}
    if subject:
        data["subject"] = subject.lower()
    if class_level:
        data["class_level"] = str(class_level)

    files = {"file": (filename, pdf_bytes, "application/pdf")}
    return _rag_post("/ingest-space-document", data=data, files=files)


# ── SpaceService ──────────────────────────────────────────────────────────────

class SpaceService:

    # ── Space CRUD ────────────────────────────────────────────────────────────

    def create_space(self, db: Session, student_id: int, payload: SpaceCreate):
        from app.db.models import Space

        space = Space(
            student_id=student_id,
            name=payload.name.strip(),
            subject=payload.subject.strip() if payload.subject else None,
            class_level=payload.class_level.strip() if payload.class_level else None,
            description=payload.description.strip() if payload.description else None,
        )
        db.add(space)
        safe_commit(db)
        db.refresh(space)
        logger.info(
            "Created space id=%s student_id=%s name=%r", space.id, student_id, space.name
        )
        return space

    def list_spaces(self, db: Session, student_id: int):
        from app.db.models import Space

        return list(
            db.scalars(
                select(Space)
                .where(Space.student_id == student_id)
                .order_by(Space.updated_at.desc())
            ).all()
        )

    def get_space(self, db: Session, student_id: int, space_id: int):
        from app.db.models import Space

        space = db.get(Space, space_id)
        if space is None or space.student_id != student_id:
            raise AppError(
                code="SPACE_NOT_FOUND",
                message="Space not found.",
                status_code=404,
            )
        return space

    def update_space(
        self, db: Session, student_id: int, space_id: int, payload: SpaceUpdate
    ):
        space = self.get_space(db, student_id, space_id)
        if payload.name is not None:
            space.name = payload.name.strip()
        if payload.subject is not None:
            space.subject = payload.subject.strip() or None
        if payload.class_level is not None:
            space.class_level = payload.class_level.strip() or None
        if payload.description is not None:
            space.description = payload.description.strip() or None
        space.updated_at = utc_now()
        safe_commit(db)
        db.refresh(space)
        return space

    def delete_space(self, db: Session, student_id: int, space_id: int) -> None:
        space = self.get_space(db, student_id, space_id)
        db.delete(space)
        safe_commit(db)
        # Best-effort: remove all ChromaDB chunks for this space
        try:
            _rag_delete("/space-documents", json={"space_id": space_id})
        except Exception as exc:
            logger.warning("Failed to clean up RAG chunks for space_id=%s: %s", space_id, exc)
        logger.info("Deleted space id=%s student_id=%s", space_id, student_id)

    # ── Document management ───────────────────────────────────────────────────

    def add_document(
        self,
        db: Session,
        student_id: int,
        space_id: int,
        filename: str,
        pdf_bytes: bytes,
    ):
        from app.db.models import Space, SpaceDocument

        space = self.get_space(db, student_id, space_id)

        # Check for duplicate filename within the same space
        existing = db.scalar(
            select(SpaceDocument).where(
                SpaceDocument.space_id == space_id,
                SpaceDocument.filename == filename,
            )
        )
        if existing:
            raise AppError(
                code="DOCUMENT_EXISTS",
                message=f"A document named '{filename}' already exists in this space. "
                         "Delete it first to re-upload.",
                status_code=409,
            )

        # Ingest into ChromaDB via RAG service
        try:
            rag_result = _ingest_to_rag(
                space_id=space_id,
                filename=filename,
                pdf_bytes=pdf_bytes,
                subject=space.subject,
                class_level=None,  # not available here; RAG stores it as ""
            )
        except RuntimeError as exc:
            raise AppError(
                code="INGESTION_FAILED",
                message=f"Document ingestion failed: {exc}",
                status_code=503,
            ) from exc

        page_count = rag_result.get("pages", 0)

        # Store document record in Postgres (metadata only — no text content)
        doc = SpaceDocument(
            space_id=space_id,
            filename=filename,
            size_bytes=len(pdf_bytes),
            page_count=page_count,
            chunks_count=rag_result.get("chunks_added", 0),
        )
        db.add(doc)
        space.updated_at = utc_now()
        safe_commit(db)
        db.refresh(doc)
        logger.info(
            "Added document id=%s space_id=%s filename=%r pages=%d chunks=%d",
            doc.id,
            space_id,
            filename,
            page_count,
            doc.chunks_count,
        )
        return doc

    def delete_document(
        self, db: Session, student_id: int, space_id: int, document_id: int
    ) -> None:
        from app.db.models import SpaceDocument

        self.get_space(db, student_id, space_id)

        doc = db.get(SpaceDocument, document_id)
        if doc is None or doc.space_id != space_id:
            raise AppError(
                code="DOCUMENT_NOT_FOUND",
                message="Document not found.",
                status_code=404,
            )

        filename = doc.filename
        db.delete(doc)
        safe_commit(db)

        # Best-effort: remove ChromaDB chunks for this document
        try:
            _rag_delete(
                "/space-document",
                json={"space_id": space_id, "filename": filename},
            )
        except Exception as exc:
            logger.warning(
                "Failed to clean up RAG chunks for space_id=%s filename=%r: %s",
                space_id,
                filename,
                exc,
            )
        logger.info("Deleted document id=%s space_id=%s", document_id, space_id)

    # ── Space-scoped RAG chat ─────────────────────────────────────────────────

    def ask(
        self,
        space_id: int,
        message: str,
        mode: str,
        subject: str | None,
        class_level: str | None,
    ) -> dict:
        """
        Forward a question to the RAG service's /ask-space endpoint,
        which retrieves chunks scoped to this space_id from ChromaDB.
        """
        payload: dict[str, Any] = {
            "query": message,
            "mode": mode,
            "space_id": space_id,
        }
        if subject:
            payload["subject"] = subject
        if class_level:
            payload["class_level"] = class_level

        try:
            result = _rag_post("/ask-space", json=payload)
        except RuntimeError as exc:
            raise AppError(
                code="SPACE_ASK_FAILED",
                message=str(exc),
                status_code=503,
            ) from exc

        return result