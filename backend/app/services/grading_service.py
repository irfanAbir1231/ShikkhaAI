from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True, slots=True)
class GradeResult:
    score_percentage: float
    mcq_correct: int
    mcq_total: int
    question_results: list[dict[str, Any]]


class GradingService:
    def grade_mcq(
        self,
        answer_key: list[dict[str, Any]],
        answers: list[dict[str, str]],
    ) -> GradeResult:
        submitted_answers = {
            str(answer["question_id"]): str(answer["answer"]) for answer in answers
        }
        mcq_items = [item for item in answer_key if item.get("type") == "mcq"]

        correct = 0
        question_results: list[dict[str, Any]] = []
        for item in mcq_items:
            question_id = str(item.get("question_id"))
            expected = str(item.get("correct_answer") or "")
            submitted = submitted_answers.get(question_id)
            is_correct = submitted is not None and submitted.strip() == expected.strip()
            if is_correct:
                correct += 1

            question_results.append(
                {
                    "question_id": question_id,
                    "topic": str(item.get("topic") or "General"),
                    "is_correct": is_correct,
                    "score": 1.0 if is_correct else 0.0,
                }
            )

        total = len(mcq_items)
        score_percentage = round((correct / total) * 100, 2) if total else 0.0
        return GradeResult(
            score_percentage=score_percentage,
            mcq_correct=correct,
            mcq_total=total,
            question_results=question_results,
        )

    def grade_short_answers(
        self,
        answer_key: list[dict[str, Any]],
        answers: list[dict[str, str]],
    ) -> list[dict[str, Any]]:
        submitted_ids = {str(answer["question_id"]) for answer in answers}
        feedback: list[dict[str, Any]] = []

        for item in answer_key:
            if item.get("type") != "short_answer":
                continue
            question_id = str(item.get("question_id"))
            if question_id not in submitted_ids:
                continue
            feedback.append(
                {
                    "question_id": question_id,
                    "status": "placeholder",
                    "feedback": "Short-answer LLM grading is not configured for this MVP.",
                    "awarded_marks": 0.0,
                }
            )

        return feedback
