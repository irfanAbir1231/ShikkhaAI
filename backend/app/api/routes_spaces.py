import logging
from typing import Any

from fastapi import APIRouter, Depends, File, Path, UploadFile
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import AppError, success_response
from app.db.models import Student
from app.db.session import get_db
from app.schemas.space import (
    SpaceAskRequest,
    SpaceAskResponse,
    SpaceCreate,
    SpaceDetailResponse,
    SpaceDocumentResponse,
    SpaceResponse,
    SpaceUpdate,
)
from app.services.space_service import SpaceService

logger = logging.getLogger("shikkhaai")

router = APIRouter(prefix="/spaces", tags=["spaces"])
space_service = SpaceService()

_ALLOWED_MIME_TYPES = {"application/pdf"}
_MAX_FILE_SIZE_BYTES = 20 * 1024 * 1024  # 20 MB


# ── Helpers ───────────────────────────────────────────────────────────────────

def _space_to_response(space) -> dict[str, Any]:
    return SpaceResponse(
        id=space.id,
        student_id=space.student_id,
        name=space.name,
        subject=space.subject,
        class_level=space.class_level,
        description=space.description,
        document_count=len(space.documents),
        created_at=space.created_at,
        updated_at=space.updated_at,
    ).model_dump(mode="json")


def _space_to_detail(space) -> dict[str, Any]:
    return SpaceDetailResponse(
        id=space.id,
        student_id=space.student_id,
        name=space.name,
        subject=space.subject,
        class_level=space.class_level,
        description=space.description,
        documents=[SpaceDocumentResponse.model_validate(d) for d in space.documents],
        created_at=space.created_at,
        updated_at=space.updated_at,
    ).model_dump(mode="json")


# ── Space CRUD ────────────────────────────────────────────────────────────────

@router.post("", status_code=201)
def create_space(
    payload: SpaceCreate,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    space = space_service.create_space(
        db=db, student_id=current_student.id, payload=payload
    )
    return success_response(_space_to_response(space))


@router.get("")
def list_spaces(
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    try:
        spaces = space_service.list_spaces(db=db, student_id=current_student.id)
        return success_response([_space_to_response(s) for s in spaces])
    except Exception as exc:
        logger.exception("Failed to list spaces for student_id=%s: %s", current_student.id, exc)
        raise AppError(
            code="SPACE_LIST_FAILED",
            message="Could not load study spaces. The database may still be initializing.",
            status_code=503,
        ) from exc


@router.get("/{space_id}")
def get_space(
    space_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    space = space_service.get_space(
        db=db, student_id=current_student.id, space_id=space_id
    )
    return success_response(_space_to_detail(space))


@router.patch("/{space_id}")
def update_space(
    payload: SpaceUpdate,
    space_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    space = space_service.update_space(
        db=db, student_id=current_student.id, space_id=space_id, payload=payload
    )
    return success_response(_space_to_response(space))


@router.delete("/{space_id}")
def delete_space(
    space_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    space_service.delete_space(
        db=db, student_id=current_student.id, space_id=space_id
    )
    return success_response({"deleted": True, "space_id": space_id})


# ── Document upload / delete ──────────────────────────────────────────────────

@router.post("/{space_id}/documents", status_code=201)
async def upload_document(
    space_id: int = Path(gt=0),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if file.content_type not in _ALLOWED_MIME_TYPES:
        raise AppError(
            code="INVALID_FILE_TYPE",
            message="Only PDF files are supported.",
            status_code=415,
        )

    pdf_bytes = await file.read()

    if len(pdf_bytes) > _MAX_FILE_SIZE_BYTES:
        raise AppError(
            code="FILE_TOO_LARGE",
            message="File exceeds the 20 MB limit.",
            status_code=413,
        )
    if len(pdf_bytes) == 0:
        raise AppError(
            code="EMPTY_FILE",
            message="Uploaded file is empty.",
            status_code=400,
        )

    filename = (file.filename or "upload.pdf").strip()

    doc = space_service.add_document(
        db=db,
        student_id=current_student.id,
        space_id=space_id,
        filename=filename,
        pdf_bytes=pdf_bytes,
    )
    return success_response(
        SpaceDocumentResponse.model_validate(doc).model_dump(mode="json")
    )


@router.delete("/{space_id}/documents/{document_id}")
def delete_document(
    space_id: int = Path(gt=0),
    document_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    space_service.delete_document(
        db=db,
        student_id=current_student.id,
        space_id=space_id,
        document_id=document_id,
    )
    return success_response({"deleted": True, "document_id": document_id})


# ── Space-scoped RAG chat ─────────────────────────────────────────────────────

@router.post("/{space_id}/ask")
def ask(
    payload: SpaceAskRequest,
    space_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    # Verify ownership and get space metadata
    space = space_service.get_space(
        db=db, student_id=current_student.id, space_id=space_id
    )

    if not space.documents:
        raise AppError(
            code="NO_DOCUMENTS",
            message="Upload at least one PDF before asking questions.",
            status_code=400,
        )

    result = space_service.ask(
        space_id=space_id,
        message=payload.message,
        mode=payload.mode,
        subject=space.subject,
        class_level=current_student.grade_level,
    )

    return success_response(
        SpaceAskResponse(
            response=result.get("response", ""),
            sources=result.get("sources", []),
            space_id=space_id,
            documents_used=len(space.documents),
        ).model_dump()
    )