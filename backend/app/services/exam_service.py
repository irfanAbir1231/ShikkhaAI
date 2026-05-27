# import logging

# from sqlalchemy.orm import Session

# from app.core.responses import AppError
# from app.db.models import Attempt, Exam
# from app.db.transactions import safe_commit
# from app.external.rag_client import RagClient
# from app.schemas.exam import ExamGenerateRequest, ExamResponse, ExamSubmitRequest, ExamSubmitResponse
# from app.services.grading_service import GradingService
# from app.services.profile_service import ProfileService
# from app.services.student_service import StudentService

# logger = logging.getLogger("shikkhaai")


# class ExamService:
#     def __init__(self) -> None:
#         self.rag_client = RagClient()
#         self.student_service = StudentService()
#         self.grading_service = GradingService()
#         self.profile_service = ProfileService()

#     def generate_exam(self, db: Session, payload: ExamGenerateRequest) -> ExamResponse:
#         self.student_service.fetch_student(db=db, student_id=payload.student_id)
#         rag_exam = self.rag_client.generate_exam(payload.model_dump())
#         logger.info(
#             "Generated exam for student_id=%s subject=%s source=%s",
#             payload.student_id,
#             payload.subject,
#             rag_exam.get("source"),
#         )

#         exam = Exam(
#             student_id=payload.student_id,
#             subject=payload.subject,
#             topic=payload.topic,
#             difficulty=payload.difficulty,
#             questions=rag_exam["questions"],
#             answer_key=rag_exam["answer_key"],
#             source=rag_exam["source"],
#         )
#         db.add(exam)
#         safe_commit(db)
#         db.refresh(exam)

#         return ExamResponse(
#             exam_id=exam.id,
#             student_id=exam.student_id,
#             subject=exam.subject,
#             topic=exam.topic,
#             difficulty=exam.difficulty,
#             source=exam.source,
#             questions=exam.questions,
#         )

#     def submit_exam(self, db: Session, payload: ExamSubmitRequest) -> ExamSubmitResponse:
#         self.student_service.fetch_student(db=db, student_id=payload.student_id)
#         exam = db.get(Exam, payload.exam_id)
#         if exam is None or exam.student_id != payload.student_id:
#             raise AppError(
#                 code="EXAM_NOT_FOUND",
#                 message="Exam was not found for this student.",
#                 status_code=404,
#             )

#         answers = [answer.model_dump() for answer in payload.answers]
#         grade_result = self.grading_service.grade_mcq(
#             answer_key=exam.answer_key,
#             answers=answers,
#         )
#         short_answer_feedback = self.grading_service.grade_short_answers(
#             answer_key=exam.answer_key,
#             answers=answers,
#             questions=exam.questions,
#         )

#         touched_topics = self.profile_service.update_topic_performance(
#             db=db,
#             student_id=payload.student_id,
#             question_results=grade_result.question_results,
#         )
#         weak_topics = self.profile_service.detect_weak_topics(
#             db=db,
#             student_id=payload.student_id,
#             touched_topics=touched_topics,
#             rag_client=self.rag_client,
#         )
#         readiness_score = self.profile_service.compute_readiness_score(
#             db=db,
#             student_id=payload.student_id,
#             exam_score=grade_result.score_percentage,
#             touched_topics=touched_topics,
#         )

#         attempt = Attempt(
#             student_id=payload.student_id,
#             exam_id=payload.exam_id,
#             answers=answers,
#             score_percentage=grade_result.score_percentage,
#             mcq_correct=grade_result.mcq_correct,
#             mcq_total=grade_result.mcq_total,
#             short_answer_feedback=short_answer_feedback,
#             weak_topics=weak_topics,
#             readiness_score=readiness_score,
#         )
#         db.add(attempt)
#         safe_commit(db)
#         db.refresh(attempt)

#         logger.info(
#             "Submitted exam_id=%s student_id=%s score=%s%% readiness=%s",
#             payload.exam_id,
#             payload.student_id,
#             grade_result.score_percentage,
#             readiness_score,
#         )

#         return ExamSubmitResponse(
#             attempt_id=attempt.id,
#             student_id=attempt.student_id,
#             exam_id=attempt.exam_id,
#             score_percentage=attempt.score_percentage,
#             mcq_correct=attempt.mcq_correct,
#             mcq_total=attempt.mcq_total,
#             weak_topics=attempt.weak_topics,
#             readiness_score=attempt.readiness_score,
#             short_answer_feedback=attempt.short_answer_feedback,
#             mcq_feedback=grade_result.mcq_feedback,
#         )


import logging
from typing import Any

from sqlalchemy.orm import Session

from app.core.responses import AppError
from app.db.models import Attempt, Exam
from app.db.transactions import safe_commit
from app.external.rag_client import RagClient
from app.schemas.exam import ExamGenerateRequest, ExamResponse, ExamSubmitRequest, ExamSubmitResponse
from app.services.grading_service import GradingService
from app.services.note_generation_service import NoteGenerationService
from app.services.profile_service import ProfileService
from app.services.student_service import StudentService

logger = logging.getLogger("shikkhaai")


class ExamService:
    def __init__(self) -> None:
        self.rag_client = RagClient()
        self.student_service = StudentService()
        self.grading_service = GradingService()
        self.profile_service = ProfileService()
        self.note_generation_service = NoteGenerationService()

    def generate_exam(self, db: Session, payload: ExamGenerateRequest) -> ExamResponse:
        self.student_service.fetch_student(db=db, student_id=payload.student_id)
        rag_exam = self.rag_client.generate_exam(payload.model_dump())
        logger.info(
            "Generated exam for student_id=%s subject=%s source=%s",
            payload.student_id,
            payload.subject,
            rag_exam.get("source"),
        )

        exam = Exam(
            student_id=payload.student_id,
            subject=payload.subject,
            class_level=payload.class_level,
            topic=payload.topic,
            difficulty=payload.difficulty,
            questions=rag_exam["questions"],
            answer_key=rag_exam["answer_key"],
            source=rag_exam["source"],
        )
        db.add(exam)
        safe_commit(db)
        db.refresh(exam)

        return ExamResponse(
            exam_id=exam.id,
            student_id=exam.student_id,
            subject=exam.subject,
            topic=exam.topic,
            difficulty=exam.difficulty,
            source=exam.source,
            questions=exam.questions,
        )

    def submit_exam(self, db: Session, payload: ExamSubmitRequest) -> ExamSubmitResponse:
        self.student_service.fetch_student(db=db, student_id=payload.student_id)
        exam = db.get(Exam, payload.exam_id)
        if exam is None or exam.student_id != payload.student_id:
            raise AppError(
                code="EXAM_NOT_FOUND",
                message="Exam was not found for this student.",
                status_code=404,
            )

        # ── Grade ──────────────────────────────────────────────────────────────
        answers = [answer.model_dump() for answer in payload.answers]
        grade_result = self.grading_service.grade_mcq(
            answer_key=exam.answer_key,
            answers=answers,
        )
        short_answer_feedback = self.grading_service.grade_short_answers(
            answer_key=exam.answer_key,
            answers=answers,
            questions=exam.questions,
        )

        # ── Profile update ─────────────────────────────────────────────────────
        touched_topics = self.profile_service.update_topic_performance(
            db=db,
            student_id=payload.student_id,
            question_results=grade_result.question_results,
        )
        weak_topics = self.profile_service.detect_weak_topics(
            db=db,
            student_id=payload.student_id,
            touched_topics=touched_topics,
            rag_client=self.rag_client,
        )
        readiness_score = self.profile_service.compute_readiness_score(
            db=db,
            student_id=payload.student_id,
            exam_score=grade_result.score_percentage,
            touched_topics=touched_topics,
        )

        # ── Persist attempt ────────────────────────────────────────────────────
        attempt = Attempt(
            student_id=payload.student_id,
            exam_id=payload.exam_id,
            answers=answers,
            score_percentage=grade_result.score_percentage,
            mcq_correct=grade_result.mcq_correct,
            mcq_total=grade_result.mcq_total,
            short_answer_feedback=short_answer_feedback,
            weak_topics=weak_topics,
            readiness_score=readiness_score,
        )
        db.add(attempt)
        safe_commit(db)
        db.refresh(attempt)

        logger.info(
            "Submitted exam_id=%s student_id=%s score=%s%% readiness=%s weak_topics=%s",
            payload.exam_id,
            payload.student_id,
            grade_result.score_percentage,
            readiness_score,
            [wt.get("topic") for wt in weak_topics],
        )

        # ── Auto-generate notes for weak topics ────────────────────────────────
        # Runs after attempt is saved — failure here never breaks the response
        if weak_topics:
            generated_notes = self.note_generation_service.generate_notes_for_weak_topics(
                db=db,
                student_id=payload.student_id,
                weak_topics=weak_topics,
                subject=exam.subject,
                class_level=exam.class_level,
            )
            if generated_notes:
                logger.info(
                    "Auto-generated %d note(s) for student_id=%s weak topics",
                    len(generated_notes),
                    payload.student_id,
                )

        return ExamSubmitResponse(
            attempt_id=attempt.id,
            student_id=attempt.student_id,
            exam_id=attempt.exam_id,
            score_percentage=attempt.score_percentage,
            mcq_correct=attempt.mcq_correct,
            mcq_total=attempt.mcq_total,
            weak_topics=attempt.weak_topics,
            readiness_score=attempt.readiness_score,
            short_answer_feedback=attempt.short_answer_feedback,
            mcq_feedback=grade_result.mcq_feedback,
        )