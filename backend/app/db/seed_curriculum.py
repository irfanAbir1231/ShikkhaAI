"""Seed Bangladesh NCTB curriculum chapters and topics.

Run automatically on startup if the curriculum_topics table is empty
or does not contain the expected entries.
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

    # Class 8 Science (English Medium) — 14 chapters from NCTB textbook
    add("8", "science", "Classification of Animal World", 1, [
        "Classification of Invertebrate Animals",
        "Classification of Vertebrate Animals",
        "Necessity of Classification",
    ])
    add("8", "science", "Growth and Heredity of Living Organism", 2, [
        "Types of Cell Division",
        "The Process of Mitosis Cell Division",
        "Meiosis",
        "Growth and Development",
    ])
    add("8", "science", "Diffusion, Osmosis and Transpiration", 3, [
        "Diffusion",
        "Osmosis",
        "Importance of Osmosis",
        "Absorption of Water and Mineral Salts",
        "Transpiration",
    ])
    add("8", "science", "Reproduction in Plants", 4, [
        "Reproduction",
        "Sexual Reproduction",
        "Pollination",
        "Structure of Seeds and its Germination",
    ])
    add("8", "science", "Co-ordination and Secretion", 5, [
        "Co-ordination in Plants",
        "Nervous System",
        "Brain",
        "Spinal Cord",
        "Excretory System",
    ])
    add("8", "science", "The Structure of Atoms", 6, [
        "Evolution of the Idea of Atoms",
        "Atomic Number, Mass Number and Isotopes",
        "Properties and Application of Isotopes",
        "Electron Distribution in Atoms",
        "Cation and Anion",
    ])
    add("8", "science", "The Earth and Gravitation", 7, [
        "Gravitation",
        "Gravity and Acceleration due to Gravity",
        "Mass and Weight",
        "Relation between Mass and Weight",
    ])
    add("8", "science", "Chemical Reaction", 8, [
        "Symbol, Formula and Valency",
        "Addition Reaction",
        "Combustion Reaction",
        "Substitution or Displacement Reaction",
        "Transformation of Energy through Chemical Reaction",
    ])
    add("8", "science", "Electric Circuits and Current Electricity", 9, [
        "Electric Potential and Electric Current",
        "Different Types of Current Flow",
        "Resistance",
        "Electric Circuit",
        "Ammeter and Voltmeter",
    ])
    add("8", "science", "Acid, Base and Salt", 10, [
        "Acid, Base and Indicators",
        "Use of Acids and Bases",
        "Properties of Acid and Alkali",
        "Acid, Alkali and Salt Identification",
    ])
    add("8", "science", "Light", 11, [
        "Refraction of Light",
        "Laws of Refraction of Light",
        "Practical Application of Refraction",
        "Total Internal Reflection and Critical Angle",
        "Optical Fibre and Magnifying Glass",
    ])
    add("8", "science", "The Outer Space and Satellites", 12, [
        "The Outer Space",
        "The Universe",
        "Natural Planet or Satellite",
        "Artificial Satellites",
        "Motion of an Artificial Satellite",
    ])
    add("8", "science", "Food and Nutrition", 13, [
        "Nutrition, Nutrition Value and Food Elements",
        "Carbohydrate and Protein",
        "Lipids",
        "Vitamins",
    ])
    add("8", "science", "Environment and Ecosystem", 14, [
        "Ecosystem",
        "Components of Ecosystem",
        "Types of Ecosystem",
        "Food Chain and Food Web",
        "Energy Flow in the Ecosystem",
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
