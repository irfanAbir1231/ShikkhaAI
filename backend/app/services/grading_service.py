import json
import logging
import re
from dataclasses import dataclass
from typing import Any

from app.core.config import settings

logger = logging.getLogger("shikkhaai")


@dataclass(frozen=True, slots=True)
class GradeResult:
    score_percentage: float
    mcq_correct: int
    mcq_total: int
    question_results: list[dict[str, Any]]
    mcq_feedback: list[dict[str, Any]]


class GradingService:
    def grade_mcq(
        self,
        answer_key: list[dict[str, Any]],
        answers: list[dict[str, str]],
    ) -> GradeResult:
        submitted_answers = {
            str(answer["question_id"]): str(answer["answer"])
            for answer in answers
        }
        mcq_items = [item for item in answer_key if item.get("type") == "mcq"]

        correct = 0
        question_results: list[dict[str, Any]] = []
        mcq_feedback: list[dict[str, Any]] = []
        for item in mcq_items:
            question_id = str(item.get("question_id"))
            expected = str(item.get("correct_answer") or "")
            submitted = submitted_answers.get(question_id)
            is_correct = self._is_mcq_correct(expected, submitted)
            if is_correct:
                correct += 1

            question_results.append(
                {
                    "question_id": question_id,
                    "topic": str(item.get("topic") or "General"),
                    "subtopics": item.get("subtopics") or [],
                    "subtopic_ids": item.get("subtopic_ids") or [],
                    "is_correct": is_correct,
                    "score": 1.0 if is_correct else 0.0,
                }
            )

            mcq_feedback.append(
                {
                    "question_id": question_id,
                    "correct": is_correct,
                    "correct_answer": expected,
                    "submitted_answer": submitted or "",
                }
            )

        total = len(mcq_items)
        score_percentage = round((correct / total) * 100, 2) if total else 0.0
        return GradeResult(
            score_percentage=score_percentage,
            mcq_correct=correct,
            mcq_total=total,
            question_results=question_results,
            mcq_feedback=mcq_feedback,
        )

    @staticmethod
    def _is_mcq_correct(expected: str, submitted: str | None) -> bool:
        """Check if a submitted MCQ answer matches the expected answer.

        Handles two formats:
        - Mock mode: expected is the full option text (exact match).
        - RAG/Gemini mode: expected is a single letter (A/B/C/D) but the
          frontend may submit the full option text (e.g. "A. Bangladesh").
        """
        if submitted is None:
            return False

        expected_stripped = expected.strip()
        submitted_stripped = submitted.strip()

        # Exact match first (covers mock mode and letter-only submissions)
        if submitted_stripped == expected_stripped:
            return True

        # If expected is a single letter A-D, also accept submissions that
        # start with that letter followed by a period or space.
        if len(expected_stripped) == 1 and expected_stripped.upper() in {"A", "B", "C", "D"}:
            if (
                submitted_stripped.startswith(expected_stripped + ".")
                or submitted_stripped.startswith(expected_stripped + " ")
            ):
                return True

        return False

    def grade_short_answers(
        self,
        answer_key: list[dict[str, Any]],
        answers: list[dict[str, str]],
        questions: list[dict[str, Any]] | None = None,
    ) -> list[dict[str, Any]]:
        submitted_map = {
            str(answer["question_id"]): str(answer["answer"])
            for answer in answers
        }
        feedback: list[dict[str, Any]] = []

        short_items = [item for item in answer_key if item.get("type") == "short_answer"]

        for item in short_items:
            question_id = str(item.get("question_id"))
            student_answer = submitted_map.get(question_id, "")
            expected_answer = str(item.get("correct_answer") or "")
            max_marks = int(item.get("marks") or 1)

            # Build question prompt from questions list if available
            question_prompt = ""
            if questions:
                for q in questions:
                    if str(q.get("id")) == question_id:
                        question_prompt = str(q.get("prompt") or q.get("question") or "")
                        break

            result = self._grade_single_short_answer(
                question=question_prompt,
                expected_answer=expected_answer,
                student_answer=student_answer,
                max_marks=max_marks,
            )
            feedback.append(
                {
                    "question_id": question_id,
                    "status": result["status"],
                    "feedback": result["feedback"],
                    "awarded_marks": result["awarded_marks"],
                }
            )

        return feedback

    def _grade_single_short_answer(
        self,
        question: str,
        expected_answer: str,
        student_answer: str,
        max_marks: int,
    ) -> dict[str, Any]:
        """Grade a single short-answer using Gemini LLM."""
        if not student_answer.strip():
            return {
                "status": "unanswered",
                "feedback": "No answer provided.",
                "awarded_marks": 0.0,
            }

        api_key = settings.gemini_api_key
        if not api_key:
            logger.warning("GEMINI_API_KEY not set; short-answer grading disabled")
            return {
                "status": "placeholder",
                "feedback": "Short-answer LLM grading is not configured for this MVP.",
                "awarded_marks": 0.0,
            }

        try:
            from google import genai

            prompt = f"""You are an expert Bangladeshi school teacher grading a student answer.

Question: {question}
Expected Answer: {expected_answer}
Student Answer: {student_answer}
Maximum Marks: {max_marks}

Grade the student answer and respond in this exact JSON format:
{{
  "awarded_marks": <float>,
  "feedback": "<constructive feedback in English or Bengali>"
}}

Be fair: award partial credit for partially correct answers.
Output JSON ONLY. No markdown, no explanation."""

            client = genai.Client(api_key=api_key)
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
            )
            raw = re.sub(r"```json|```", "", response.text).strip()
            parsed = json.loads(raw)

            awarded = float(parsed.get("awarded_marks", 0.0))
            awarded = max(0.0, min(awarded, float(max_marks)))

            return {
                "status": "graded",
                "feedback": str(parsed.get("feedback", "Graded by AI.")).strip(),
                "awarded_marks": round(awarded, 2),
            }
        except Exception as exc:
            logger.exception("Short-answer LLM grading failed for question: %s", question)
            return {
                "status": "error",
                "feedback": f"Grading error: {exc}",
                "awarded_marks": 0.0,
            }
