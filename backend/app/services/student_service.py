import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.core.security import hash_password, verify_password
from app.db.models import Student
from app.db.transactions import safe_commit
from app.schemas.student import StudentCreate

logger = logging.getLogger("shikkhaai")


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
            password=hash_password(payload.password),
        )
        db.add(student)
        safe_commit(db)
        db.refresh(student)
        logger.info("Registered student id=%s email=%s", student.id, student.email)
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

    def authenticate_student(self, db: Session, email: str, password: str) -> Student:
        student = db.scalar(select(Student).where(Student.email == email))
        if student is None:
            raise AppError(
                code="INVALID_CREDENTIALS",
                message="Incorrect email or password.",
                status_code=401,
            )
        if student.password is None or not verify_password(password, student.password):
            raise AppError(
                code="INVALID_CREDENTIALS",
                message="Incorrect email or password.",
                status_code=401,
            )
        return student
