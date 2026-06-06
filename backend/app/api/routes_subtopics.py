from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import success_response
from app.db.models import Student
from app.db.session import get_db
from app.schemas.subtopic import (
    SubtopicPerformanceResponse,
    WeakSubtopicResponse,
)
from app.services.subtopic_service import SubtopicService

router = APIRouter(prefix="/subtopics", tags=["subtopics"])
subtopic_service = SubtopicService()


@router.get("/weak/{student_id}")
def list_weak_subtopics(
    student_id: int,
    threshold: float = 60.0,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != student_id:
        return success_response([])
    weak = subtopic_service.get_weak_subtopics_for_student(db, student_id, threshold=threshold)
    return success_response(weak)


@router.get("/performance/{student_id}")
def list_subtopic_performance(
    student_id: int,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != student_id:
        return success_response([])
    performance = subtopic_service.get_subtopic_performance(db, student_id)
    return success_response(performance)
