import logging
from typing import Any

from fastapi import APIRouter, Depends, Path
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import AppError, success_response
from app.db.models import Attempt, Exam, SavedExam, Student
from app.db.session import get_db
from app.schemas.exam import (
    AttemptResponse,
    ExamGenerateRequest,
    ExamSubmitRequest,
    ExamSummaryResponse,
)
from app.schemas.subtopic import PracticeExamGenerateRequest
from app.services.exam_service import ExamService
from app.services.practice_exam_service import PracticeExamService

logger = logging.getLogger("shikkhaai")
router = APIRouter(prefix="/exam", tags=["exams"])
exam_service = ExamService()
practice_exam_service = PracticeExamService()


def _verify_student_owns_resource(current_student: Student, student_id: int) -> None:
    if current_student.id != student_id:
        logger.warning(
            "Auth mismatch: token student_id=%s != payload student_id=%s",
            current_student.id,
            student_id,
        )
        raise AppError(
            code="FORBIDDEN",
            message="You can only access your own resources.",
            status_code=403,
        )


@router.post("/generate")
def generate_exam(
    payload: ExamGenerateRequest,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    _verify_student_owns_resource(current_student, payload.student_id)
    exam = exam_service.generate_exam(db=db, payload=payload)
    return success_response(exam)


@router.post("/submit")
def submit_exam(
    payload: ExamSubmitRequest,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    _verify_student_owns_resource(current_student, payload.student_id)
    result = exam_service.submit_exam(db=db, payload=payload)
    return success_response(result)


@router.post("/practice/generate")
def generate_practice_exam(
    payload: PracticeExamGenerateRequest,
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    _verify_student_owns_resource(current_student, payload.student_id)
    exam = practice_exam_service.generate_practice_exam(db=db, payload=payload)
    return success_response(exam)


@router.get("/{exam_id}/attempts")
def list_exam_attempts(
    exam_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    exam = db.get(Exam, exam_id)
    if exam is None:
        raise AppError(
            code="EXAM_NOT_FOUND",
            message="Exam was not found.",
            status_code=404,
        )
    _verify_student_owns_resource(current_student, exam.student_id)
    attempts = db.scalars(
        select(Attempt).where(Attempt.exam_id == exam_id).order_by(Attempt.created_at.desc())
    ).all()
    return success_response([_serialize_attempt(a) for a in attempts])


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
        short_answer_feedback=attempt.short_answer_feedback,
        created_at=attempt.created_at.isoformat(),
    ).model_dump()


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


# ── Saved Exams ───────────────────────────────────────────────────────────────

@router.post("/{exam_id}/save")
def save_exam(
    exam_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    exam = db.get(Exam, exam_id)
    if exam is None:
        raise AppError(code="EXAM_NOT_FOUND", message="Exam not found.", status_code=404)

    existing = db.execute(
        select(SavedExam).where(
            SavedExam.student_id == current_student.id,
            SavedExam.exam_id == exam_id,
        )
    ).scalar_one_or_none()

    if existing:
        return success_response({"saved": True, "message": "Exam already saved"})

    saved = SavedExam(student_id=current_student.id, exam_id=exam_id)
    db.add(saved)
    db.commit()
    return success_response({"saved": True})


@router.delete("/{exam_id}/save")
def unsave_exam(
    exam_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    saved = db.execute(
        select(SavedExam).where(
            SavedExam.student_id == current_student.id,
            SavedExam.exam_id == exam_id,
        )
    ).scalar_one_or_none()

    if saved:
        db.delete(saved)
        db.commit()
    return success_response({"saved": False})


@router.post("/{exam_id}/bookmark")
def toggle_exam_bookmark(
    exam_id: int = Path(gt=0),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    saved = db.execute(
        select(SavedExam).where(
            SavedExam.student_id == current_student.id,
            SavedExam.exam_id == exam_id,
        )
    ).scalar_one_or_none()

    if not saved:
        saved = SavedExam(student_id=current_student.id, exam_id=exam_id, bookmarked=True)
        db.add(saved)
    else:
        saved.bookmarked = not saved.bookmarked

    db.commit()
    db.refresh(saved)
    return success_response({"bookmarked": saved.bookmarked})


@router.get("/saved/list")
def list_saved_exams(
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    saved = db.execute(
        select(SavedExam).where(SavedExam.student_id == current_student.id)
    ).scalars().all()

    result = []
    for s in saved:
        exam = db.get(Exam, s.exam_id)
        if exam:
            result.append({
                "id": s.id,
                "exam_id": s.exam_id,
                "subject": exam.subject,
                "topic": exam.topic,
                "difficulty": exam.difficulty,
                "num_questions": len(exam.questions) if isinstance(exam.questions, list) else 0,
                "bookmarked": s.bookmarked,
                "saved_at": s.saved_at.isoformat() if s.saved_at else None,
            })
    return success_response(result)
