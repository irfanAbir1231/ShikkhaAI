"""Seed Bangladesh NCTB curriculum chapters and topics.

Run automatically on startup if the curriculum_topics table is empty.
"""

from sqlalchemy.orm import Session

from app.db.models import CurriculumTopic


def seed_curriculum(db: Session) -> int:
    """Insert default curriculum data if none exists. Returns count inserted."""
    existing = db.query(CurriculumTopic).first()
    if existing:
        return 0

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
    # ingested into the RAG vector database. Expand this list as more PDFs are
    # processed (see rag/ingest.py).
    # ── Class 8 Science ────────────────────────────────────────────────────────
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

    for e in entries:
        db.add(CurriculumTopic(**e))

    db.commit()
    return len(entries)
