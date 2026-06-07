import logging
import time
from typing import Any, Optional

import httpx

from app.core.config import settings

logger = logging.getLogger("shikkhaai")


class RagClient:
    def generate_exam(self, payload: dict[str, Any]) -> dict[str, Any]:
        if settings.mock_mode:
            return self._mock_exam(payload)

        # Optional in-process call (monorepo dev only). Disabled by default so a
        # standalone backend deploy never imports the heavy RAG deps and instead
        # talks to the RAG service over HTTP (RAG_BASE_URL).
        if settings.rag_inprocess:
            try:
                from dotenv import load_dotenv
                load_dotenv("rag/.env")
                from rag.generate import generate_questions  # noqa: PLC0415

                req = self._to_rag_request(payload)
                result = generate_questions(
                    subject=req["subject"],
                    class_level=req["class_level"],
                    difficulty=req["difficulty"],
                    count=req["count"],
                    query_override=req.get("topic"),
                )
                data = self._adapt_rag_response(result)
                logger.info("Using in-process RAG for exam generation")
                return self._normalize_exam(data=data, request_payload=payload, source="rag")
            except ImportError:
                pass  # RAG module not in path — fall through to HTTP
            except Exception as exc:
                raise RuntimeError(f"RAG generation failed: {exc}") from exc

        # HTTP RAG service: preferred when running separately on RAG_BASE_URL
        if settings.rag_base_url:
            try:
                with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
                    response = client.post(
                        f"{settings.rag_base_url}/generate-exam",
                        json=self._to_rag_request(payload),
                    )
                    response.raise_for_status()
                    data = self._adapt_rag_response(response.json())
                logger.info("Using HTTP RAG service at %s", settings.rag_base_url)
                return self._normalize_exam(data=data, request_payload=payload, source="rag")
            except httpx.ConnectError as exc:
                logger.warning(
                    "RAG server at %s is not reachable. Falling back to direct Gemini.",
                    settings.rag_base_url,
                )
                # Fall through to Gemini below instead of hard-failing
            except ValueError as exc:
                error_msg = str(exc)
                if "did not include questions" in error_msg:
                    logger.warning(
                        "RAG service returned empty questions (subject=%s, topic=%s). "
                        "Falling back to mock exam.",
                        payload.get("subject"),
                        payload.get("topic"),
                    )
                    return self._mock_exam(payload)
                logger.warning("RAG HTTP call failed: %s. Falling back to direct Gemini.", error_msg)
            except (httpx.HTTPError, TypeError, KeyError) as exc:
                logger.warning("RAG HTTP call failed: %s. Falling back to direct Gemini.", exc)

        # Direct Gemini fallback: no RAG retrieval context, just Gemini generation
        if settings.gemini_api_key:
            logger.info("Falling back to direct Gemini for exam generation")
            return self._generate_via_gemini(payload)

        raise RuntimeError(
            "No GEMINI_API_KEY, RAG module not importable, and RAG_BASE_URL not set."
        )

    def _generate_via_gemini(self, payload: dict[str, Any]) -> dict[str, Any]:
        import json
        import re
        from google import genai

        req = self._to_rag_request(payload)
        subject = req["subject"]
        class_level = req["class_level"]
        difficulty = req["difficulty"]
        count = req["count"]
        topic = req.get("topic") or subject

        difficulty_focus = {
            "easy": "basic definitions and facts",
            "medium": "application and understanding",
            "hard": "analysis and problem solving",
        }.get(difficulty, "general understanding")

        prompt = f"""You are ShikkhaAI, an exam question generator for Bangladeshi students.
Generate {count} exam questions for Class {class_level} {subject.title()} on the topic: {topic}.
Difficulty: {difficulty} ({difficulty_focus})
Mix: mostly MCQ, 1-2 short answer.

Respond with valid JSON only. No markdown.

{{
  "questions": [
    {{
      "id": 1,
      "type": "mcq",
      "topic": "{topic}",
      "difficulty": "{difficulty}",
      "question": "<question text>",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "answer": "A",
      "explanation": "<1-2 sentences explaining why the correct answer is right>"
    }}
  ]
}}

Rules:
- MCQ must have exactly 4 options
- answer field for MCQ is ONLY A/B/C/D
- explanation: 1-2 sentences explaining the correct answer
- short_answer options must be []
- output JSON ONLY"""

        client = genai.Client(api_key=settings.gemini_api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        raw = re.sub(r"```json|```", "", response.text).strip()
        result = json.loads(raw)
        for i, q in enumerate(result.get("questions", []), 1):
            q["id"] = i
        data = self._adapt_rag_response(result)
        return self._normalize_exam(data=data, request_payload=payload, source="gemini")

    def _ask_via_gemini(self, payload: dict[str, Any]) -> dict[str, Any]:
        import json
        from google import genai

        message = payload.get("message", "")
        mode = payload.get("mode", "simple")
        subject = payload.get("subject", "science")
        class_level = payload.get("class_level", "8")

        mode_instructions = {
            "simple": "Explain in very simple, easy-to-understand language suitable for a young student.",
            "detailed": "Provide a detailed, thorough explanation with examples and depth.",
            "exam_style": "Frame the answer as an exam-style response with key points, definitions, and examples a student would write in an exam.",
            "analogy": "Use creative analogies and real-life comparisons to make the concept memorable.",
        }.get(mode, "Explain clearly and simply.")

        prompt = (
            f"You are ShikkhaAI, a helpful AI tutor for Bangladeshi students.\n\n"
            f"A Class {class_level} student asks about {subject}:\n"
            f'"""{message}"""\n\n'
            f"Instructions:\n"
            f"- {mode_instructions}\n"
            f"- Keep the answer accurate and curriculum-relevant.\n"
            f"- Use Bangladeshi educational context where appropriate.\n"
            f"- Respond in a friendly, encouraging tone.\n"
            f"- Format with markdown-style headers, bullet points, and bold text for readability.\n\n"
            f"Respond with a JSON object ONLY (no markdown code blocks):\n"
            f'{{\n  "response": "Your complete answer here with markdown formatting escaped for JSON"\n}}'
        )

        client = genai.Client(api_key=settings.gemini_api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        raw = response.text.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1].rsplit("\n```", 1)[0] if "\n" in raw else raw.strip("`")
            if raw.startswith("json"):
                raw = raw[4:].strip()
        try:
            data = json.loads(raw)
            answer = data.get("response", raw)
        except json.JSONDecodeError:
            answer = raw

        return {
            "response": answer,
            "sources": [],
        }

    def _to_rag_request(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Map the backend ExamGenerateRequest shape to member1's RAG
        /generate-exam contract (subject lowercase, class_level string,
        count instead of num_questions, topic as a retrieval hint)."""
        return {
            "student_id": payload.get("student_id"),
            "subject": str(payload.get("subject") or "").strip().lower(),
            "class_level": str(payload.get("class_level") or "8"),
            "difficulty": payload.get("difficulty") or "medium",
            "count": int(payload.get("num_questions") or 7),
            "topic": payload.get("topic"),
            "chapter": payload.get("chapter"),
        }

    def _adapt_rag_response(self, data: Any) -> dict[str, Any]:
        """Member1's RAG embeds the correct answer inside each question and
        does not return a separate answer_key. _normalize_exam reads correct
        answers only from answer_key, so synthesize it here."""
        if not isinstance(data, dict):
            raise ValueError("RAG response must be an object")

        questions = data.get("questions")
        if not isinstance(questions, list):
            raise ValueError("RAG response did not include questions")

        answer_key: list[dict[str, Any]] = []
        for index, question in enumerate(questions, start=1):
            if not isinstance(question, dict):
                continue
            question_id = str(question.get("id") or f"q{index}")
            answer_key.append(
                {
                    "question_id": question_id,
                    "type": question.get("type"),
                    "correct_answer": question.get("answer", ""),
                }
            )

        return {"questions": questions, "answer_key": answer_key}

    def ask(self, payload: dict[str, Any]) -> dict[str, Any]:
        if settings.mock_mode:
            return self._mock_ask(payload)

        # Optional in-process call (monorepo dev only); see generate_exam.
        if settings.rag_inprocess:
            try:
                from dotenv import load_dotenv
                load_dotenv("rag/.env")
                from rag.generate import generate_answer  # noqa: PLC0415

                result = generate_answer(
                    query=payload["message"],
                    mode=payload["mode"],
                    subject=payload["subject"],
                    class_level=payload["class_level"],
                    pdf_context=payload.get("pdf_context"),
                )
                return {"response": result.get("response", ""), "sources": result.get("sources", [])}
            except ImportError:
                pass
            except Exception as exc:
                logger.warning("In-process RAG ask failed: %s", exc)

        # HTTP RAG service with Gemini fallback
        if settings.rag_base_url:
            max_retries = 2
            for attempt in range(max_retries + 1):
                try:
                    with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
                        response = client.post(
                            f"{settings.rag_base_url}/ask",
                            json={
                                "query": payload["message"],
                                "mode": payload["mode"],
                                "subject": payload["subject"],
                                "class_level": payload["class_level"],
                                "pdf_context": payload.get("pdf_context"),
                            },
                        )
                        response.raise_for_status()
                        data = response.json()
                    return {
                        "response": data.get("response", ""),
                        "sources": data.get("sources", []),
                    }
                except httpx.HTTPStatusError as exc:
                    if exc.response.status_code in (429, 503) and attempt < max_retries:
                        delay = 2 * (attempt + 1)
                        logger.warning(
                            "RAG server returned %d (attempt %d/%d). Retrying in %ds...",
                            exc.response.status_code,
                            attempt + 1,
                            max_retries + 1,
                            delay,
                        )
                        time.sleep(delay)
                        continue
                    logger.warning(
                        "RAG ask failed with status %d. Falling back to Gemini.",
                        exc.response.status_code,
                    )
                    break
                except httpx.ConnectError as exc:
                    logger.warning(
                        "RAG server at %s is not reachable (%s). Falling back to Gemini.",
                        settings.rag_base_url,
                        exc,
                    )
                    break
                except (httpx.HTTPError, TypeError, KeyError) as exc:
                    logger.warning("RAG HTTP ask failed: %s. Falling back to Gemini.", exc)
                    break

        # Direct Gemini fallback when RAG is unavailable
        if settings.gemini_api_key:
            logger.info("Falling back to direct Gemini for study companion")
            return self._ask_via_gemini(payload)

        raise RuntimeError(
            "Study companion is temporarily unavailable. The RAG service is not reachable "
            "and no Gemini API key is configured. Please try again in a moment."
        )

    def detect_weak_topics(self, payload: dict[str, Any]) -> list[dict[str, Any]]:
        if settings.mock_mode:
            return self._mock_weak_topics(payload)

        if not settings.rag_base_url:
            # No HTTP endpoint — fall back gracefully (weak topic detection is non-critical)
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

    def get_topics(self, subject: Optional[str] = None, class_level: Optional[str] = None) -> list[dict[str, Any]]:
        if settings.mock_mode:
            return []

        # RAG inprocess fallback
        if settings.rag_inprocess:
            try:
                from dotenv import load_dotenv
                load_dotenv("rag/.env")
                from rag.retrieve import get_unique_chapters_and_topics  # noqa: PLC0415
                logger.info("Using in-process RAG for get_topics")
                return get_unique_chapters_and_topics(subject=subject, class_level=class_level)
            except ImportError:
                pass
            except Exception as exc:
                logger.warning("In-process get_topics failed: %s", exc)

        # HTTP RAG service call
        if settings.rag_base_url:
            try:
                params = {}
                if subject:
                    params["subject"] = subject
                if class_level:
                    params["class_level"] = class_level
                with httpx.Client(timeout=settings.rag_timeout_seconds) as client:
                    response = client.get(
                        f"{settings.rag_base_url}/topics",
                        params=params,
                    )
                    response.raise_for_status()
                    data = response.json()
                logger.info("Using HTTP RAG service for get_topics")
                return data.get("topics", [])
            except Exception as exc:
                logger.warning("RAG HTTP get_topics failed: %s. Returning empty list.", exc)

        return []

    def _mock_ask(self, payload: dict[str, Any]) -> dict[str, Any]:
        return {
            "response": f"[Mock mode] You asked: **{payload.get('message', '')}**\n\n"
            "This is a mock response. Enable real RAG by setting MOCK_MODE=false.",
            "sources": [],
        }

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

            key_item = answer_by_id.get(question_id, {})
            correct_answer = key_item.get("correct_answer") or key_item.get("answer") or ""
            explanation = str(question.get("explanation") or "")

            # Map letter answer (A/B/C/D) to full option text so frontend comparison works
            str_options = [str(option) for option in options]
            letter = str(correct_answer).strip().upper()
            if letter in {"A", "B", "C", "D"} and str_options:
                option_map = {chr(65 + i): opt for i, opt in enumerate(str_options)}
                correct_answer = option_map.get(letter, letter)

            normalized_questions.append(
                {
                    "id": question_id,
                    "type": question_type,
                    "topic": topic,
                    "prompt": prompt,
                    "options": str_options,
                    "marks": int(question.get("marks") or 1),
                    "correct_answer": str(correct_answer),
                    "explanation": explanation,
                }
            )

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
                    "correct_answer": template["answer"],
                    "explanation": "",
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
