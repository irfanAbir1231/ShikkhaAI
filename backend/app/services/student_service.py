from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.db.models import Student
from app.schemas.student import StudentCreate


class StudentService:
    def register_student(self, db: Session, payload: StudentCreate) -> Student:
        existing_student = db.scalar(select(Student).where(Student.email == payload.email))
        if existing_student is not None:
            raise AppError(
                code="STUDENT_EMAIL_EXISTS",
                message="A student with this email already exists.",
                status_code=409,
            )

        student = Student(
            name=payload.name,
            email=payload.email,
            grade_level=payload.grade_level,
        )
        db.add(student)
        db.commit()
        db.refresh(student)
        return student

    def fetch_student(self, db: Session, student_id: int) -> Student:
        student = db.get(Student, student_id)
        if student is None:
            raise AppError(
                code="STUDENT_NOT_FOUND",
                message="Student was not found.",
                status_code=404,
            )
        return student
