import logging
from typing import Any

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import AppError, success_response
from app.db.models import Student
from app.db.session import get_db
from app.services.analytics_service import AnalyticsService
from app.services.dashboard_service import DashboardService
from app.services.student_service import StudentService

logger = logging.getLogger("shikkhaai")
router = APIRouter(prefix="/student", tags=["analytics"])

dashboard_service = DashboardService()
analytics_service = AnalyticsService()
student_service = StudentService()


def _check_ownership(current_student: Student, student_id: int) -> None:
    if current_student.id != student_id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only view your own data.",
            status_code=403,
        )


@router.get("/{student_id}/dashboard")
def get_dashboard(
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    _check_ownership(current_student, student_id)
    student = student_service.fetch_student(db=db, student_id=student_id)
    data = dashboard_service.get_dashboard(db=db, student=student)
    return success_response(data)


@router.get("/{student_id}/analytics")
def get_analytics(
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    _check_ownership(current_student, student_id)
    student = student_service.fetch_student(db=db, student_id=student_id)
    data = analytics_service.get_analytics(db=db, student=student)
    return success_response(data)


@router.get("/{student_id}/topics")
def get_topics(
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    _check_ownership(current_student, student_id)
    student = student_service.fetch_student(db=db, student_id=student_id)
    data = analytics_service.get_topics(db=db, student=student)
    return success_response(data)