from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.responses import success_response
from app.db.session import get_db
from app.schemas.exam import ExamGenerateRequest, ExamSubmitRequest
from app.services.exam_service import ExamService

router = APIRouter(prefix="/exam", tags=["exams"])
exam_service = ExamService()


@router.post("/generate")
def generate_exam(
    payload: ExamGenerateRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    exam = exam_service.generate_exam(db=db, payload=payload)
    return success_response(exam)


@router.post("/submit")
def submit_exam(
    payload: ExamSubmitRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    result = exam_service.submit_exam(db=db, payload=payload)
    return success_response(result)
