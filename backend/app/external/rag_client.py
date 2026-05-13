from typing import Any

import httpx

from app.core.config import settings


class RagClient:
    def generate_exam(self, payload: dict[str, Any]) -> dict[str, Any]:
        if settings.mock_mode or not settings.rag_base_url:
            return self._mock_exam(payload)

        try:
            with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
                response = client.post(
                    f"{settings.rag_base_url}/generate-exam",
                    json=payload,
                )
                response.raise_for_status()
                data = response.json()
            return self._normalize_exam(data=data, request_payload=payload, source="rag")
        except (httpx.HTTPError, ValueError, TypeError, KeyError):
            return self._mock_exam(payload)

    def detect_weak_topics(self, payload: dict[str, Any]) -> list[dict[str, Any]]:
        if settings.mock_mode or not settings.rag_base_url:
            return self._mock_weak_topics(payload)

        try:
            with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
                response = client.post(
                    f"{settings.rag_base_url}/weak-topics",
                    json=payload,
                )
                response.raise_for_status()
                data = response.json()
            weak_topics = data.get("weak_topics", [])
            if not isinstance(weak_topics, list):
                raise ValueError("weak_topics must be a list")
            return [self._normalize_weak_topic(topic) for topic in weak_topics]
        except (httpx.HTTPError, ValueError, TypeError, KeyError):
            return self._mock_weak_topics(payload)

    def _normalize_exam(
        self,
        data: dict[str, Any],
        request_payload: dict[str, Any],
        source: str,
    ) -> dict[str, Any]:
        questions = data.get("questions")
        if not isinstance(questions, list) or not questions:
            raise ValueError("RAG exam response did not include questions")

        answer_key = data.get("answer_key", [])
        if not isinstance(answer_key, list):
            raise ValueError("RAG exam response answer_key must be a list")

        normalized_questions: list[dict[str, Any]] = []
        normalized_answer_key: list[dict[str, Any]] = []
        answer_by_id = {
            str(item.get("question_id") or item.get("id")): item
            for item in answer_key
            if isinstance(item, dict)
        }

        for index, question in enumerate(questions, start=1):
            if not isinstance(question, dict):
                raise ValueError("Each question must be an object")

            question_id = str(question.get("id") or f"q{index}")
            raw_question_type = str(question.get("type") or "mcq").lower()
            question_type = "short_answer" if raw_question_type in {"short", "short-answer", "short_answer"} else "mcq"
            topic = str(question.get("topic") or request_payload.get("topic") or "General")
            prompt = str(question.get("prompt") or question.get("question") or "")
            if not prompt:
                raise ValueError("Question prompt is required")

            options = question.get("options", [])
            if not isinstance(options, list):
                options = []

            normalized_questions.append(
                {
                    "id": question_id,
                    "type": question_type,
                    "topic": topic,
                    "prompt": prompt,
                    "options": [str(option) for option in options],
                    "marks": int(question.get("marks") or 1),
                }
            )

            key_item = answer_by_id.get(question_id, {})
            correct_answer = key_item.get("correct_answer") or key_item.get("answer") or ""
            normalized_answer_key.append(
                {
                    "question_id": question_id,
                    "type": question_type,
                    "correct_answer": str(correct_answer),
                    "topic": topic,
                    "marks": int(question.get("marks") or 1),
                }
            )

        return {
            "source": source,
            "questions": normalized_questions,
            "answer_key": normalized_answer_key,
        }

    def _mock_exam(self, payload: dict[str, Any]) -> dict[str, Any]:
        topic = str(payload.get("topic") or "Core Topic")
        requested_count = int(payload.get("num_questions") or 5)
        question_count = max(1, min(requested_count, 20))
        templates = [
            {
                "type": "mcq",
                "prompt": f"What is the standard form used in {topic}?",
                "options": [
                    "ax^2 + bx + c = 0",
                    "ax + b = 0",
                    "a/x + b = 0",
                    "x = a + b",
                ],
                "answer": "ax^2 + bx + c = 0",
            },
            {
                "type": "mcq",
                "prompt": f"Which expression is commonly used as a discriminant in {topic}?",
                "options": ["b^2 - 4ac", "2a + b", "a^2 + c", "4ab - c"],
                "answer": "b^2 - 4ac",
            },
            {
                "type": "mcq",
                "prompt": f"What does a positive discriminant usually indicate in {topic}?",
                "options": [
                    "Two distinct real roots",
                    "No real roots",
                    "Exactly one variable",
                    "A constant function",
                ],
                "answer": "Two distinct real roots",
            },
            {
                "type": "mcq",
                "prompt": f"Which step is usually helpful when solving problems in {topic}?",
                "options": [
                    "Identify the known values",
                    "Ignore coefficients",
                    "Remove all variables",
                    "Change the topic",
                ],
                "answer": "Identify the known values",
            },
            {
                "type": "short_answer",
                "prompt": f"Briefly explain one key idea from {topic}.",
                "options": [],
                "answer": f"A clear explanation of a key idea from {topic}.",
            },
        ]

        questions: list[dict[str, Any]] = []
        answer_key: list[dict[str, Any]] = []
        for index in range(question_count):
            template = templates[index % len(templates)]
            question_id = f"q{index + 1}"
            questions.append(
                {
                    "id": question_id,
                    "type": template["type"],
                    "topic": topic,
                    "prompt": template["prompt"],
                    "options": template["options"],
                    "marks": 1,
                }
            )
            answer_key.append(
                {
                    "question_id": question_id,
                    "type": template["type"],
                    "correct_answer": template["answer"],
                    "topic": topic,
                    "marks": 1,
                }
            )

        return {
            "source": "mock",
            "questions": questions,
            "answer_key": answer_key,
        }

    def _mock_weak_topics(self, payload: dict[str, Any]) -> list[dict[str, Any]]:
        topics = payload.get("topics", [])
        weak_topics: list[dict[str, Any]] = []
        if not isinstance(topics, list):
            return weak_topics

        for topic in topics:
            if not isinstance(topic, dict):
                continue
            score = float(topic.get("score") or 0.0)
            consistency_score = float(topic.get("consistency_score") or 0.0)
            if score < 60.0 or consistency_score < 50.0:
                weak_topics.append(
                    {
                        "topic": str(topic.get("topic") or "Unknown"),
                        "reason": "Low recent score or inconsistent performance",
                        "score": round(score, 2),
                    }
                )
        return weak_topics

    def _normalize_weak_topic(self, topic: Any) -> dict[str, Any]:
        if isinstance(topic, str):
            return {"topic": topic, "reason": "Flagged by RAG service", "score": None}
        if isinstance(topic, dict):
            return {
                "topic": str(topic.get("topic") or topic.get("name") or "Unknown"),
                "reason": str(topic.get("reason") or "Flagged by RAG service"),
                "score": topic.get("score"),
            }
        return {"topic": "Unknown", "reason": "Flagged by RAG service", "score": None}
