import logging
from typing import Any

from sqlalchemy.orm import Session

from app.db.models import SubtopicPerformance
from app.schemas.exam import ExamGenerateRequest, ExamResponse
from app.schemas.subtopic import PracticeExamGenerateRequest
from app.services.exam_service import ExamService
from app.services.subtopic_service import SubtopicService

logger = logging.getLogger("shikkhaai")


class PracticeExamService:
    def __init__(self) -> None:
        self.exam_service = ExamService()
        self.subtopic_service = SubtopicService()

    def generate_practice_exam(
        self,
        db: Session,
        payload: PracticeExamGenerateRequest,
    ) -> dict[str, Any]:
        """Generate an adaptive practice exam focused on weak subtopics."""
        student_id = payload.student_id
        subject = payload.subject
        class_level = payload.class_level
        difficulty = payload.difficulty
        num_questions = payload.num_questions
        mastery_threshold = payload.mastery_threshold

        # Determine focus subtopics
        focus_subtopic_ids = list(payload.focus_subtopics or [])

        if not focus_subtopic_ids:
            # Auto-select weak subtopics
            weak_subtopics = self.subtopic_service.get_weak_subtopics_for_student(
                db, student_id, threshold=mastery_threshold
            )
            focus_subtopic_ids = [ws["subtopic_id"] for ws in weak_subtopics]

        if not focus_subtopic_ids:
            # No weak subtopics found — fall back to all subtopics for the subject
            logger.info("[practice] No weak subtopics found for student %s, using topic-level exam", student_id)
            exam_req = ExamGenerateRequest(
                student_id=student_id,
                subject=subject,
                topic="General Practice",
                class_level=class_level,
                difficulty=difficulty,
                num_questions=num_questions,
            )
            return self.exam_service.generate_exam(db=db, payload=exam_req)

        # Compute question distribution proportional to weakness
        distributions = self._compute_distribution(db, focus_subtopic_ids, num_questions, mastery_threshold)

        # For simplicity, we pass all focus_subtopic_ids to the exam generator
        # and let the RAG/Gemini distribute questions among them.
        # The distribution is used for logging and future fine-grained control.
        logger.info("[practice] Distribution for student %s: %s", student_id, distributions)

        exam_req = ExamGenerateRequest(
            student_id=student_id,
            subject=subject,
            topic="Adaptive Practice",
            class_level=class_level,
            difficulty=difficulty,
            num_questions=num_questions,
            subtopic_ids=focus_subtopic_ids,
            mastery_threshold=mastery_threshold,
        )

        return self.exam_service.generate_exam(db=db, payload=exam_req)

    def _compute_distribution(
        self,
        db: Session,
        subtopic_ids: list[int],
        total_questions: int,
        mastery_threshold: float,
    ) -> list[dict[str, Any]]:
        """Compute question count per subtopic proportional to weakness.
        
        Weakness = (mastery_threshold - mastery_score), clamped at 0.
        More weakness = more questions.
        """
        if not subtopic_ids:
            return []

        weaknesses: list[tuple[int, str, float]] = []
        total_weakness = 0.0

        for sid in subtopic_ids:
            perf = db.get(SubtopicPerformance, sid)
            if perf:
                mastery = perf.average_score
                weakness = max(0.0, mastery_threshold - mastery)
            else:
                # No performance data = maximum weakness
                weakness = mastery_threshold

            subtopic = db.get(Subtopic, sid)
            name = subtopic.name if subtopic else "Unknown"
            weaknesses.append((sid, name, weakness))
            total_weakness += weakness

        if total_weakness == 0:
            # All mastered — equal distribution
            per_topic = total_questions // len(subtopic_ids)
            remainder = total_questions % len(subtopic_ids)
            distributions = []
            for i, (sid, name, _) in enumerate(weaknesses):
                count = per_topic + (1 if i < remainder else 0)
                distributions.append({
                    "subtopic_id": sid,
                    "name": name,
                    "questions": count,
                    "weight_percentage": round(100 / len(subtopic_ids), 1),
                })
            return distributions

        distributions = []
        allocated = 0
        for sid, name, weakness in weaknesses:
            ratio = weakness / total_weakness
            count = int(round(ratio * total_questions))
            # Ensure at least 1 question per weak subtopic if total allows
            if count == 0 and total_questions >= len(subtopic_ids):
                count = 1
            allocated += count
            distributions.append({
                "subtopic_id": sid,
                "name": name,
                "questions": count,
                "weight_percentage": round(ratio * 100, 1),
            })

        # Adjust for rounding errors
        diff = total_questions - allocated
        if diff != 0:
            # Add/subtract from the weakest subtopic
            distributions.sort(key=lambda x: x["weight_percentage"], reverse=(diff > 0))
            for i in range(abs(diff)):
                idx = i % len(distributions)
                distributions[idx]["questions"] += (1 if diff > 0 else -1)

        return distributions
