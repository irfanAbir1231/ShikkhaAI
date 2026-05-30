import logging
from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import AppError, success_response
from app.db.models import Student
from app.db.session import get_db
from app.external.rag_client import RagClient
from app.schemas.study_companion import StudyCompanionAskRequest

logger = logging.getLogger("shikkhaai")
router = APIRouter(prefix="/study-companion", tags=["study-companion"])
rag_client = RagClient()


@router.post("/ask")
def ask(
    payload: StudyCompanionAskRequest,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != payload.student_id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only send messages as yourself.",
            status_code=403,
        )

    try:
        result = rag_client.ask(
            {
                "student_id": payload.student_id,
                "message": payload.message,
                "mode": payload.mode,
                "subject": payload.subject,
                "class_level": payload.class_level,
                "pdf_context": payload.pdf_context,
            }
        )
    except RuntimeError as exc:
        logger.exception("Study companion ask failed")
        raise AppError(
            code="COMPANION_ASK_FAILED",
            message=str(exc),
            status_code=503,
        ) from exc

    return success_response(result)
