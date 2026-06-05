"""Seed Bangladesh NCTB curriculum chapters and topics.

Run automatically on startup if the curriculum_topics table is empty
or does not contain the expected Class 8 Science entries.
"""

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.models import CurriculumTopic


def _expected_entries() -> list[dict]:
    """Return the canonical curriculum data that should be in the DB."""
    entries: list[dict] = []
    order = 0

    def add(class_level: str, subject: str, chapter: str, chapter_num: int, topics: list[str]) -> None:
        nonlocal order
        for t in topics:
            entries.append({
                "class_level": class_level,
                "subject": subject.lower(),
                "chapter": chapter,
                "chapter_number": chapter_num,
                "topic": t,
                "display_order": order,
            })
            order += 1

    # Only Class 8 Science is seeded because that is the only textbook currently
    # ingested into the RAG vector database.
    add("8", "science", "Food and Nutrition", 1, [
        "Classes of Food", "Balanced Diet", "Food Preservation",
    ])
    add("8", "science", "Life Processes", 2, [
        "Photosynthesis", "Respiration", "Excretion",
    ])
    add("8", "science", "Force and Motion", 3, [
        "Newton's Laws of Motion", "Gravitation", "Work, Energy and Power",
    ])
    add("8", "science", "Light and Sound", 4, [
        "Reflection of Light", "Refraction", "Properties of Sound",
    ])
    add("8", "science", "Matter", 5, [
        "Atomic Structure", "Chemical Reactions", "Metals and Non-metals",
    ])
    add("8", "science", "Environment and Conservation", 6, [
        "Ecosystem", "Biodiversity", "Conservation of Nature",
    ])

    return entries


def seed_curriculum(db: Session) -> int:
    """Ensure the curriculum table contains exactly the expected data.

    If the table is empty, missing expected rows, or contains unexpected rows,
    it is cleared and re-seeded.
    """
    expected = _expected_entries()
    expected_count = len(expected)

    # Check current state
    total_rows = db.query(CurriculumTopic).count()
    class8_science_rows = (
        db.query(CurriculumTopic)
        .filter(CurriculumTopic.class_level == "8", CurriculumTopic.subject == "science")
        .count()
    )

    # If the table looks correct, skip
    if total_rows == expected_count and class8_science_rows == expected_count:
        return 0

    # Otherwise clear and re-seed
    db.execute(text("DELETE FROM curriculum_topics"))
    db.commit()

    for e in expected:
        db.add(CurriculumTopic(**e))

    db.commit()
    return expected_count
