from typing import Any

from fastapi import APIRouter, Depends, Path
from sqlalchemy.orm import Session

from app.core.responses import success_response
from app.db.session import get_db
from app.schemas.student import StudentCreate, StudentResponse
from app.services.student_service import StudentService

router = APIRouter(prefix="/student", tags=["students"])
student_service = StudentService()


@router.post("/register")
def register_student(
    payload: StudentCreate,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    student = student_service.register_student(db=db, payload=payload)
    return success_response(StudentResponse.model_validate(student))


@router.get("/{id}")
def get_student(
    id: int = Path(gt=0),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    student = student_service.fetch_student(db=db, student_id=id)
    return success_response(StudentResponse.model_validate(student))
