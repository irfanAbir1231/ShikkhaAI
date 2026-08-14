from typing import Any

from fastapi import APIRouter, Depends, Path, Request
from fastapi.security import HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.responses import AppError, success_response
from app.core.security import create_access_token, decode_access_token
from app.db.models import Attempt, Exam, Student, TopicPerformance
from app.db.session import get_db
from app.schemas.exam import AttemptResponse, ExamSummaryResponse, WeakTopic
from app.schemas.student import LoginRequest, StudentCreate, StudentResponse, StudentUpdate, TokenResponse
from app.services.student_service import StudentService

router = APIRouter(prefix="/student", tags=["students"])
student_service = StudentService()
security = HTTPBearer(auto_error=False)


def get_current_student(
    request: Request,
    db: Session = Depends(get_db),
) -> Student:
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        raise AppError(
            code="AUTH_REQUIRED",
            message="Not authenticated.",
            status_code=401,
        )
    token = auth[7:].strip()
    payload = decode_access_token(token)
    student_id = payload.get("sub")
    if student_id is None:
        raise AppError(
            code="AUTH_REQUIRED",
            message="Invalid token payload.",
            status_code=401,
        )
    try:
        student_id_int = int(student_id)
    except (ValueError, TypeError) as exc:
        raise AppError(
            code="AUTH_REQUIRED",
            message="Invalid token payload.",
            status_code=401,
        ) from exc
    student = db.get(Student, student_id_int)
    if student is None:
        raise AppError(
            code="AUTH_REQUIRED",
            message="Student not found.",
            status_code=401,
        )
    return student


@router.post("/register")
def register_student(
    payload: StudentCreate,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    student = student_service.register_student(db=db, payload=payload)
    access_token = create_access_token(data={"sub": str(student.id)})
    return success_response(
        {
            "student": StudentResponse.model_validate(student).model_dump(),
            "access_token": access_token,
            "token_type": "bearer",
        }
    )


@router.post("/login")
def login_student(
    payload: LoginRequest,
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    student = student_service.authenticate_student(
        db=db, email=payload.email, password=payload.password
    )
    access_token = create_access_token(data={"sub": str(student.id)})
    return success_response(
        {
            "access_token": access_token,
            "token_type": "bearer",
            "student": StudentResponse.model_validate(student).model_dump(),
        }
    )


@router.get("/{id}")
def get_student(
    id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only view your own profile.",
            status_code=403,
        )
    student = student_service.fetch_student(db=db, student_id=id)
    return success_response(StudentResponse.model_validate(student))


@router.patch("/{student_id}")
def update_student(
    payload: StudentUpdate,
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != student_id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only update your own profile.",
            status_code=403,
        )
    student = student_service.update_student(db=db, student_id=student_id, payload=payload)
    return success_response(StudentResponse.model_validate(student))


@router.get("/{student_id}/exams")
def list_student_exams(
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != student_id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only view your own exams.",
            status_code=403,
        )
    student_service.fetch_student(db=db, student_id=student_id)
    exams = db.scalars(
        select(Exam).where(Exam.student_id == student_id).order_by(Exam.created_at.desc())
    ).all()
    return success_response([_serialize_exam(e) for e in exams])


@router.get("/{student_id}/attempts")
def list_student_attempts(
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != student_id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only view your own attempts.",
            status_code=403,
        )
    student_service.fetch_student(db=db, student_id=student_id)
    attempts = db.scalars(
        select(Attempt).where(Attempt.student_id == student_id).order_by(Attempt.created_at.desc())
    ).all()
    return success_response([_serialize_attempt(a) for a in attempts])


@router.get("/{student_id}/weak-topics")
def get_student_weak_topics(
    student_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    if current_student.id != student_id:
        raise AppError(
            code="FORBIDDEN",
            message="You can only view your own weak topics.",
            status_code=403,
        )
    student_service.fetch_student(db=db, student_id=student_id)
    performances = db.scalars(
        select(TopicPerformance).where(TopicPerformance.student_id == student_id)
    ).all()
    weak_topics = [
        WeakTopic(
            topic=p.topic,
            reason="Low topic average or inconsistent recent performance",
            score=round(p.average_score, 2),
        )
        for p in performances
        if p.average_score < 60.0
        or p.consistency_score < 50.0
        or p.last_score < 50.0
    ]
    return success_response([t.model_dump() for t in weak_topics])


def _serialize_exam(exam: Exam) -> dict[str, Any]:
    return ExamSummaryResponse(
        exam_id=exam.id,
        student_id=exam.student_id,
        subject=exam.subject,
        topic=exam.topic,
        difficulty=exam.difficulty,
        num_questions=len(exam.questions) if isinstance(exam.questions, list) else 0,
        source=exam.source,
        created_at=exam.created_at.isoformat(),
    ).model_dump()


def _serialize_attempt(attempt: Attempt) -> dict[str, Any]:
    return AttemptResponse(
        attempt_id=attempt.id,
        exam_id=attempt.exam_id,
        student_id=attempt.student_id,
        score_percentage=attempt.score_percentage,
        mcq_correct=attempt.mcq_correct,
        mcq_total=attempt.mcq_total,
        readiness_score=attempt.readiness_score,
        weak_topics=attempt.weak_topics,
        weak_subtopics=attempt.weak_subtopics or [],
        generated_notes=attempt.generated_notes or [],
        short_answer_feedback=attempt.short_answer_feedback,
        created_at=attempt.created_at.isoformat(),
    ).model_dump()
