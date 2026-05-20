


"""
generate.py — Gemini question generator
"""

import argparse
import json
import os
import re
from pathlib import Path

from google import genai

from .retrieve import build_rag_context



GEMINI_MODEL = "gemini-2.5-flash"

MOCK_OUTPUT_DIR = "./shared/mock_data"
MOCK_OUTPUT_FILE = f"{MOCK_OUTPUT_DIR}/exam.json"


DIFFICULTY_TOPIC_MAP = {
    "easy": "basic definitions and facts",
    "medium": "application and understanding",
    "hard": "analysis and problem solving",
}



_client: "genai.Client | None" = None


def _get_client() -> "genai.Client":
    """Lazily build the Gemini client so the service can import/start
    even when GEMINI_API_KEY is not set; the error surfaces only on a
    real generation call."""
    global _client
    if _client is None:
        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            raise RuntimeError(
                "GEMINI_API_KEY is not set. Add it to rag/.env "
                "(see rag/.env.example)."
            )
        _client = genai.Client(api_key=api_key)
    return _client



SYSTEM_PROMPT = """
You are ShikkhaAI, an exam question generator for Bangladeshi students.

You generate questions STRICTLY based on the provided curriculum context.

You MUST respond with valid JSON only.

No markdown.
No explanation.
No extra text.
"""


def build_prompt(
    context: str,
    subject: str,
    class_level: str,
    difficulty: str,
    count: int,
    topic: str = None,
) -> str:

    focus = DIFFICULTY_TOPIC_MAP.get(
        difficulty,
        "general understanding"
    )

    topic_block = (
        f"\nTOPIC (STRICT):\n"
        f"Every question MUST be about \"{topic}\". "
        f"Do NOT generate questions on other topics even if the curriculum "
        f"context covers them. Use the context only as background knowledge "
        f"about \"{topic}\"; if context lacks coverage of \"{topic}\", "
        f"still constrain questions to \"{topic}\" using standard "
        f"Class {class_level} {subject.title()} knowledge.\n"
        if topic else ""
    )

    topic_field_hint = (
        f'"{topic}"' if topic else "<specific topic from context>"
    )

    return f"""
CURRICULUM CONTEXT:
{context}
{topic_block}
TASK:
Generate {count} exam questions for Class {class_level} {subject.title()}{f' on the topic "{topic}"' if topic else ''}.

Difficulty:
{difficulty} ({focus})

Mix:
mostly MCQ, 1-2 short answer.

STRICT JSON FORMAT:

{{
  "questions": [
    {{
      "id": 1,
      "type": "mcq",
      "topic": {topic_field_hint},
      "difficulty": "{difficulty}",
      "question": "<question text>",
      "options": [
        "A. ...",
        "B. ...",
        "C. ...",
        "D. ..."
      ],
      "answer": "A"
    }}
  ]
}}

Rules:
- MCQ must have exactly 4 options
- answer field for MCQ is ONLY A/B/C/D
- short_answer options must be []
- every question.topic field must equal {topic_field_hint}
- output JSON ONLY
"""


def extract_json(text: str) -> dict:

    text = re.sub(r"```json|```", "", text).strip()

    return json.loads(text)




def generate_questions(
    subject: str,
    class_level: str,
    difficulty: str = "medium",
    count: int = 7,
    query_override: str = None,
):

    query = (
        query_override
        or f"{subject} class {class_level} {difficulty} questions"
    )

    context = build_rag_context(
        query,
        subject=subject,
        class_level=class_level,
    )

    if not context:
        print("[!] No RAG context found.")
        return {"questions": []}

    prompt = build_prompt(
        context,
        subject,
        class_level,
        difficulty,
        count,
        topic=query_override,
    )

    print(
        f"[+] Generating {count} questions..."
    )

    response = _get_client().models.generate_content(
        model=GEMINI_MODEL,
        contents=SYSTEM_PROMPT + "\n\n" + prompt,
    )

    raw = response.text

    result = extract_json(raw)

    for i, q in enumerate(
        result.get("questions", []),
        1
    ):
        q["id"] = i

    return result



def save_mock(data: dict):

    Path(MOCK_OUTPUT_DIR).mkdir(
        parents=True,
        exist_ok=True,
    )

    with open(
        MOCK_OUTPUT_FILE,
        "w",
        encoding="utf-8",
    ) as f:

        json.dump(
            data,
            f,
            ensure_ascii=False,
            indent=2,
        )

    print(f"[✓] Saved to {MOCK_OUTPUT_FILE}")



if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--subject",
        required=True
    )

    parser.add_argument(
        "--class_level",
        required=True
    )

    parser.add_argument(
        "--difficulty",
        default="medium",
        choices=["easy", "medium", "hard"]
    )

    parser.add_argument(
        "--count",
        default=7,
        type=int,
    )

    parser.add_argument(
        "--query",
        default=None,
    )

    args = parser.parse_args()

    result = generate_questions(
        subject=args.subject,
        class_level=args.class_level,
        difficulty=args.difficulty,
        count=args.count,
        query_override=args.query,
    )

    print(
        json.dumps(
            result,
            indent=2,
            ensure_ascii=False,
        )
    )

    save_mock(result)