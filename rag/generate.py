


"""
generate.py — Gemini question generator
"""

import argparse
import json
import os
import re
from pathlib import Path

from google import genai

from retrieve import build_rag_context



GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]

GEMINI_MODEL = "gemini-2.0-flash"

MOCK_OUTPUT_DIR = "./shared/mock_data"
MOCK_OUTPUT_FILE = f"{MOCK_OUTPUT_DIR}/exam.json"


DIFFICULTY_TOPIC_MAP = {
    "easy": "basic definitions and facts",
    "medium": "application and understanding",
    "hard": "analysis and problem solving",
}



client = genai.Client(api_key=GEMINI_API_KEY)



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
) -> str:

    focus = DIFFICULTY_TOPIC_MAP.get(
        difficulty,
        "general understanding"
    )

    return f"""
CURRICULUM CONTEXT:
{context}

TASK:
Generate {count} exam questions for Class {class_level} {subject.title()}.

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
      "topic": "<specific topic from context>",
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
- topic must come from context
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
    )

    print(
        f"[+] Generating {count} questions..."
    )

    response = client.models.generate_content(
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