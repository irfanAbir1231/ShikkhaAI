"""Seed Bangladesh NCTB curriculum chapters and topics.

Run automatically on startup if the curriculum_topics table is empty
or does not contain the expected entries.
"""

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.models import CurriculumTopic, Subtopic


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


def _subtopic_entries() -> list[dict]:
    """Return subtopic data mapped by (class_level, subject, chapter, topic)."""
    return {
        # Chapter 1: Classification of Animal World
        ("8", "science", "Classification of Animal World", "Classification of Invertebrate Animals"): [
            "Characteristics of Invertebrates", "Phylum Porifera and Cnidaria", "Phylum Arthropoda and Mollusca",
        ],
        ("8", "science", "Classification of Animal World", "Classification of Vertebrate Animals"): [
            "Characteristics of Vertebrates", "Classes of Vertebrates", "Features of Mammals and Birds",
        ],
        ("8", "science", "Classification of Animal World", "Necessity of Classification"): [
            "Importance of Classification", "Basis of Classification", "Taxonomic Hierarchy",
        ],
        # Chapter 2: Growth and Heredity
        ("8", "science", "Growth and Heredity of Living Organism", "Types of Cell Division"): [
            "Mitosis Division", "Meiosis Division", "Differences between Mitosis and Meiosis",
        ],
        ("8", "science", "Growth and Heredity of Living Organism", "The Process of Mitosis Cell Division"): [
            "Prophase, Metaphase, Anaphase, Telophase", "Significance of Mitosis", "Cell Cycle",
        ],
        ("8", "science", "Growth and Heredity of Living Organism", "Meiosis"): [
            "Stages of Meiosis", "Significance of Meiosis", "Crossing Over",
        ],
        ("8", "science", "Growth and Heredity of Living Organism", "Growth and Development"): [
            "Factors Affecting Growth", "Stages of Development", "Heredity and Variation",
        ],
        # Chapter 3: Diffusion, Osmosis and Transpiration
        ("8", "science", "Diffusion, Osmosis and Transpiration", "Diffusion"): [
            "Definition and Process", "Factors Affecting Diffusion", "Examples in Daily Life",
        ],
        ("8", "science", "Diffusion, Osmosis and Transpiration", "Osmosis"): [
            "Definition and Types", "Osmotic Pressure", "Hypertonic and Hypotonic Solutions",
        ],
        ("8", "science", "Diffusion, Osmosis and Transpiration", "Importance of Osmosis"): [
            "Osmosis in Plant Cells", "Osmosis in Animal Cells", "Osmosis in Food Preservation",
        ],
        ("8", "science", "Diffusion, Osmosis and Transpiration", "Absorption of Water and Mineral Salts"): [
            "Root Hair Function", "Process of Absorption", "Transport in Xylem",
        ],
        ("8", "science", "Diffusion, Osmosis and Transpiration", "Transpiration"): [
            "Process of Transpiration", "Factors Affecting Transpiration", "Importance of Transpiration",
        ],
        # Chapter 4: Reproduction in Plants
        ("8", "science", "Reproduction in Plants", "Reproduction"): [
            "Asexual Reproduction", "Sexual Reproduction", "Vegetative Propagation",
        ],
        ("8", "science", "Reproduction in Plants", "Sexual Reproduction"): [
            "Flower Structure", "Male and Female Gametes", "Fertilization Process",
        ],
        ("8", "science", "Reproduction in Plants", "Pollination"): [
            "Types of Pollination", "Agents of Pollination", "Significance of Pollination",
        ],
        ("8", "science", "Reproduction in Plants", "Structure of Seeds and its Germination"): [
            "Seed Structure", "Conditions for Germination", "Stages of Germination",
        ],
        # Chapter 5: Co-ordination and Secretion
        ("8", "science", "Co-ordination and Secretion", "Co-ordination in Plants"): [
            "Tropism", "Nastic Movements", "Plant Hormones",
        ],
        ("8", "science", "Co-ordination and Secretion", "Nervous System"): [
            "Components of Nervous System", "Neuron Structure", "Reflex Action",
        ],
        ("8", "science", "Co-ordination and Secretion", "Brain"): [
            "Parts of the Brain", "Functions of Cerebrum", "Functions of Cerebellum",
        ],
        ("8", "science", "Co-ordination and Secretion", "Spinal Cord"): [
            "Structure of Spinal Cord", "Spinal Nerves", "Reflex Arc",
        ],
        ("8", "science", "Co-ordination and Secretion", "Excretory System"): [
            "Organs of Excretion", "Structure of Kidney", "Process of Urine Formation",
        ],
        # Chapter 6: The Structure of Atoms
        ("8", "science", "The Structure of Atoms", "Evolution of the Idea of Atoms"): [
            "Dalton's Atomic Theory", "Thomson's Model", "Rutherford's Experiment",
        ],
        ("8", "science", "The Structure of Atoms", "Atomic Number, Mass Number and Isotopes"): [
            "Atomic Number", "Mass Number", "Isotopes and Isobars",
        ],
        ("8", "science", "The Structure of Atoms", "Properties and Application of Isotopes"): [
            "Radioactive Isotopes", "Uses in Medicine", "Uses in Industry",
        ],
        ("8", "science", "The Structure of Atoms", "Electron Distribution in Atoms"): [
            "Electron Shells", "Valence Electrons", "Octet Rule",
        ],
        ("8", "science", "The Structure of Atoms", "Cation and Anion"): [
            "Formation of Cations", "Formation of Anions", "Ionic Bonds",
        ],
        # Chapter 7: The Earth and Gravitation
        ("8", "science", "The Earth and Gravitation", "Gravitation"): [
            "Newton's Law of Gravitation", "Gravitational Force", "Universal Gravitation Constant",
        ],
        ("8", "science", "The Earth and Gravitation", "Gravity and Acceleration due to Gravity"): [
            "Acceleration due to Gravity", "Value of g", "Factors Affecting g",
        ],
        ("8", "science", "The Earth and Gravitation", "Mass and Weight"): [
            "Definition of Mass", "Definition of Weight", "Difference between Mass and Weight",
        ],
        ("8", "science", "The Earth and Gravitation", "Relation between Mass and Weight"): [
            "W = mg Formula", "SI Units", "Practical Examples",
        ],
        # Chapter 8: Chemical Reaction
        ("8", "science", "Chemical Reaction", "Symbol, Formula and Valency"): [
            "Chemical Symbols", "Writing Formulas", "Calculating Valency",
        ],
        ("8", "science", "Chemical Reaction", "Addition Reaction"): [
            "Definition and Examples", "Conditions for Addition", "Products of Addition",
        ],
        ("8", "science", "Chemical Reaction", "Combustion Reaction"): [
            "Requirements for Combustion", "Types of Combustion", "Products of Combustion",
        ],
        ("8", "science", "Chemical Reaction", "Substitution or Displacement Reaction"): [
            "Single Displacement", "Double Displacement", "Activity Series",
        ],
        ("8", "science", "Chemical Reaction", "Transformation of Energy through Chemical Reaction"): [
            "Exothermic Reactions", "Endothermic Reactions", "Energy Conservation",
        ],
        # Chapter 9: Electric Circuits
        ("8", "science", "Electric Circuits and Current Electricity", "Electric Potential and Electric Current"): [
            "Electric Potential Difference", "Unit of Current", "Conventional Current",
        ],
        ("8", "science", "Electric Circuits and Current Electricity", "Different Types of Current Flow"): [
            "Direct Current (DC)", "Alternating Current (AC)", "Comparison of DC and AC",
        ],
        ("8", "science", "Electric Circuits and Current Electricity", "Resistance"): [
            "Ohm's Law", "Factors Affecting Resistance", "Resistors in Series and Parallel",
        ],
        ("8", "science", "Electric Circuits and Current Electricity", "Electric Circuit"): [
            "Components of Circuit", "Open and Closed Circuits", "Short Circuit",
        ],
        ("8", "science", "Electric Circuits and Current Electricity", "Ammeter and Voltmeter"): [
            "Function of Ammeter", "Function of Voltmeter", "How to Connect Them",
        ],
        # Chapter 10: Acid, Base and Salt
        ("8", "science", "Acid, Base and Salt", "Acid, Base and Indicators"): [
            "Natural Indicators", "Synthetic Indicators", "pH Scale",
        ],
        ("8", "science", "Acid, Base and Salt", "Use of Acids and Bases"): [
            "Acids in Daily Life", "Bases in Daily Life", "Neutralization Reaction",
        ],
        ("8", "science", "Acid, Base and Salt", "Properties of Acid and Alkali"): [
            "Physical Properties", "Chemical Properties", "Reaction with Metals",
        ],
        ("8", "science", "Acid, Base and Salt", "Acid, Alkali and Salt Identification"): [
            "Laboratory Tests", "Reaction with Carbonates", "Conductivity Test",
        ],
        # Chapter 11: Light
        ("8", "science", "Light", "Refraction of Light"): [
            "Definition of Refraction", "Refractive Index", "Real and Apparent Depth",
        ],
        ("8", "science", "Light", "Laws of Refraction of Light"): [
            "First Law", "Second Law (Snell's Law)", "Experimental Verification",
        ],
        ("8", "science", "Light", "Practical Application of Refraction"): [
            "Lenses", "Camera", "Human Eye",
        ],
        ("8", "science", "Light", "Total Internal Reflection and Critical Angle"): [
            "Conditions for TIR", "Critical Angle", "Applications of TIR",
        ],
        ("8", "science", "Light", "Optical Fibre and Magnifying Glass"): [
            "Structure of Optical Fibre", "Uses of Optical Fibre", "Working of Magnifying Glass",
        ],
        # Chapter 12: The Outer Space and Satellites
        ("8", "science", "The Outer Space and Satellites", "The Outer Space"): [
            "Atmosphere Layers", "Exosphere and Space", "Astronomy Basics",
        ],
        ("8", "science", "The Outer Space and Satellites", "The Universe"): [
            "Galaxies", "Stars and Planets", "Big Bang Theory",
        ],
        ("8", "science", "The Outer Space and Satellites", "Natural Planet or Satellite"): [
            "Moon as Natural Satellite", "Phases of Moon", "Tides",
        ],
        ("8", "science", "The Outer Space and Satellites", "Artificial Satellites"): [
            "Types of Artificial Satellites", "Launching Process", "Uses of Satellites",
        ],
        ("8", "science", "The Outer Space and Satellites", "Motion of an Artificial Satellite"): [
            "Orbital Velocity", "Geostationary Orbit", "Escape Velocity",
        ],
        # Chapter 13: Food and Nutrition
        ("8", "science", "Food and Nutrition", "Nutrition, Nutrition Value and Food Elements"): [
            "Balanced Diet", "Nutritional Components", "Food Pyramid",
        ],
        ("8", "science", "Food and Nutrition", "Carbohydrate and Protein"): [
            "Sources of Carbohydrates", "Sources of Proteins", "Functions in Body",
        ],
        ("8", "science", "Food and Nutrition", "Lipids"): [
            "Types of Lipids", "Sources of Lipids", "Functions of Lipids",
        ],
        ("8", "science", "Food and Nutrition", "Vitamins"): [
            "Fat-Soluble Vitamins", "Water-Soluble Vitamins", "Deficiency Diseases",
        ],
        # Chapter 14: Environment and Ecosystem
        ("8", "science", "Environment and Ecosystem", "Ecosystem"): [
            "Definition of Ecosystem", "Natural Ecosystem", "Artificial Ecosystem",
        ],
        ("8", "science", "Environment and Ecosystem", "Components of Ecosystem"): [
            "Biotic Components", "Abiotic Components", "Producers and Consumers",
        ],
        ("8", "science", "Environment and Ecosystem", "Types of Ecosystem"): [
            "Terrestrial Ecosystem", "Aquatic Ecosystem", "Marine Ecosystem",
        ],
        ("8", "science", "Environment and Ecosystem", "Food Chain and Food Web"): [
            "Trophic Levels", "Food Chain Types", "Food Web Complexity",
        ],
        ("8", "science", "Environment and Ecosystem", "Energy Flow in the Ecosystem"): [
            "10% Energy Law", "Pyramid of Energy", "Ecological Pyramids",
        ],
    }


def seed_subtopics(db: Session) -> int:
    """Ensure subtopics are seeded for all curriculum topics."""
    from sqlalchemy import select

    subtopic_map = _subtopic_entries()
    total_inserted = 0

    # Get all curriculum topics
    curriculum_topics = db.scalars(select(CurriculumTopic)).all()

    for ct in curriculum_topics:
        key = (ct.class_level, ct.subject, ct.chapter, ct.topic)
        subtopic_names = subtopic_map.get(key, [])

        if not subtopic_names:
            continue

        # Check if subtopics already exist for this topic
        existing = db.scalars(
            select(Subtopic).where(Subtopic.curriculum_topic_id == ct.id)
        ).all()

        if existing:
            continue  # Already seeded

        for idx, name in enumerate(subtopic_names):
            db.add(Subtopic(
                curriculum_topic_id=ct.id,
                name=name,
                summary=f"Key concepts about {name} under {ct.topic}.",
                display_order=idx,
            ))
            total_inserted += 1

    if total_inserted:
        db.commit()
    return total_inserted
