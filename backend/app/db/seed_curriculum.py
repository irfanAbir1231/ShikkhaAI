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

    # ── Class 6 ────────────────────────────────────────────────────────────────
    add("6", "science", "The Natural Environment", 1, [
        "Our Environment", "Natural Resources", "Environmental Balance",
    ])
    add("6", "science", "Life and Living Things", 2, [
        "Characteristics of Living Things", "Cells and Tissues", "Growth and Reproduction",
    ])
    add("6", "science", "The Human Body", 3, [
        "Digestive System", "Respiratory System", "Circulatory System",
    ])
    add("6", "science", "Force and Motion", 4, [
        "Types of Force", "Motion and Rest", "Friction",
    ])
    add("6", "science", "Energy", 5, [
        "Sources of Energy", "Forms of Energy", "Energy Transformation",
    ])

    add("6", "math", "Natural Numbers and Fractions", 1, [
        "Natural Numbers", "Prime and Composite Numbers", "Fractions",
    ])
    add("6", "math", "Ratio and Percentage", 2, [
        "Ratio", "Proportion", "Percentage",
    ])
    add("6", "math", "Integers", 3, [
        "Introduction to Integers", "Addition and Subtraction", "Multiplication and Division",
    ])
    add("6", "math", "Algebraic Expressions", 4, [
        "Variables and Constants", "Algebraic Terms", "Simple Equations",
    ])
    add("6", "math", "Geometry", 5, [
        "Lines and Angles", "Triangles", "Quadrilaterals",
    ])

    add("6", "english", "Reading Comprehension", 1, [
        "Understanding Main Ideas", "Identifying Details", "Making Inferences",
    ])
    add("6", "english", "Grammar", 2, [
        "Parts of Speech", "Tenses", "Sentence Structure",
    ])
    add("6", "english", "Writing Skills", 3, [
        "Paragraph Writing", "Letter Writing", "Story Writing",
    ])
    add("6", "english", "Vocabulary", 4, [
        "Word Meaning", "Synonyms and Antonyms", "Idioms and Phrases",
    ])

    add("6", "bangla", "পড়া ও বোঝা", 1, [
        "গদ্য পাঠ", "পদ্য পাঠ", "ব্যাখ্যা লেখা",
    ])
    add("6", "bangla", "ব্যাকরণ", 2, [
        "ধ্বনি ও বর্ণ", "শব্দ", "পদ প্রকরণ",
    ])
    add("6", "bangla", "রচনা", 3, [
        "চিঠি লেখা", "প্রবন্ধ রচনা", "সারাংশ লেখা",
    ])

    # ── Class 7 ────────────────────────────────────────────────────────────────
    add("7", "science", "Earth and Universe", 1, [
        "Solar System", "Earth's Structure", "Day and Night",
    ])
    add("7", "science", "Living Organisms", 2, [
        "Classification of Animals", "Classification of Plants", "Microorganisms",
    ])
    add("7", "science", "Human Health", 3, [
        "Nutrition and Diet", "Diseases and Prevention", "Immunity",
    ])
    add("7", "science", "Physical Science", 4, [
        "Sound", "Light", "Heat",
    ])
    add("7", "science", "Chemistry Basics", 5, [
        "States of Matter", "Mixtures and Solutions", "Acids and Bases",
    ])

    add("7", "math", "Rational Numbers", 1, [
        "Fractions and Decimals", "Operations on Rational Numbers", "Number Line",
    ])
    add("7", "math", "Commercial Arithmetic", 2, [
        "Profit and Loss", "Simple Interest", "Discount",
    ])
    add("7", "math", "Algebra", 3, [
        "Algebraic Expressions", "Linear Equations", "Inequalities",
    ])
    add("7", "math", "Geometry and Measurement", 4, [
        "Angles and Parallel Lines", "Congruence", "Perimeter and Area",
    ])
    add("7", "math", "Data Handling", 5, [
        "Mean, Median, Mode", "Bar Graphs", "Probability Basics",
    ])

    add("7", "english", "Literature", 1, [
        "Poetry Appreciation", "Short Stories", "Drama",
    ])
    add("7", "english", "Advanced Grammar", 2, [
        "Active and Passive Voice", "Reported Speech", "Conditional Sentences",
    ])
    add("7", "english", "Composition", 3, [
        "Essay Writing", "Dialogue Writing", "Summary Writing",
    ])
    add("7", "english", "Communication", 4, [
        "Formal and Informal Language", "Email Writing", "Presentation Skills",
    ])

    add("7", "bangla", "পড়া ও বোঝা", 1, [
        "নাটক পাঠ", "উপন্যাস", "ব্যাখ্যা ও সারাংশ",
    ])
    add("7", "bangla", "ব্যাকরণ", 2, [
        "বাক্য", "প্রকৃতি ও প্রত্যয়", "সমাস",
    ])
    add("7", "bangla", "রচনা", 3, [
        "অনুচ্ছেদ রচনা", "আবেদন পত্র", "প্রতিবেদন লেখা",
    ])

    # ── Class 8 ────────────────────────────────────────────────────────────────
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

    add("8", "math", "Real Numbers", 1, [
        "Rational and Irrational Numbers", "Laws of Exponents", "Scientific Notation",
    ])
    add("8", "math", "Algebraic Formulae", 2, [
        "Algebraic Identities", "Factorization", "Simplification",
    ])
    add("8", "math", "Equations", 3, [
        "Linear Equations in One Variable", "Simultaneous Linear Equations", "Quadratic Equations",
    ])
    add("8", "math", "Geometry", 4, [
        "Quadrilaterals", "Polygons", "Circle Theorems",
    ])
    add("8", "math", "Trigonometry Basics", 5, [
        "Trigonometric Ratios", "Sine and Cosine Rules", "Height and Distance",
    ])
    add("8", "math", "Statistics", 6, [
        "Frequency Distribution", "Histograms", "Pie Charts",
    ])

    add("8", "english", "Prose and Poetry", 1, [
        "Comprehension Passages", "Poetic Devices", "Themes in Literature",
    ])
    add("8", "english", "Grammar", 2, [
        "Clauses and Phrases", "Direct and Indirect Speech", "Modal Verbs",
    ])
    add("8", "english", "Writing", 3, [
        "Descriptive Essays", "Narrative Essays", "Argumentative Essays",
    ])
    add("8", "english", "Vocabulary and Usage", 4, [
        "Collocations", "Phrasal Verbs", "Word Formation",
    ])

    add("8", "bangla", "পড়া ও বোঝা", 1, [
        "গল্প পাঠ", "কবিতা পাঠ", "ব্যাখ্যা ও সারাংশ",
    ])
    add("8", "bangla", "ব্যাকরণ", 2, [
        "বাক্য রূপান্তর", "প্রত্যয়", "সমাস ও অর্থ পরিবর্তন",
    ])
    add("8", "bangla", "রচনা", 3, [
        "প্রবন্ধ রচনা", "সারাংশ লেখা", "পত্র লেখা",
    ])

    # ── Class 9 ────────────────────────────────────────────────────────────────
    add("9", "science", "Physics - Motion", 1, [
        "Equations of Motion", "Graphical Analysis", "Projectile Motion",
    ])
    add("9", "science", "Physics - Force", 2, [
        "Newton's Laws", "Momentum", "Friction and Gravity",
    ])
    add("9", "science", "Chemistry - Structure of Matter", 3, [
        "Atomic Models", "Periodic Table", "Chemical Bonding",
    ])
    add("9", "science", "Biology - Cell Biology", 4, [
        "Cell Structure", "Cell Division", "Cell Transport",
    ])
    add("9", "science", "Biology - Human Physiology", 5, [
        "Nervous System", "Endocrine System", "Reproductive System",
    ])
    add("9", "science", "Environment", 6, [
        "Natural Resources", "Pollution", "Climate Change",
    ])

    add("9", "math", "Algebra", 1, [
        "Sets", "Logarithms", "Algebraic Expressions",
    ])
    add("9", "math", "Equations and Inequalities", 2, [
        "Linear Equations", "Quadratic Equations", "Inequalities",
    ])
    add("9", "math", "Geometry", 3, [
        "Similarity", "Pythagoras Theorem", "Circle Properties",
    ])
    add("9", "math", "Trigonometry", 4, [
        "Trigonometric Ratios", "Trigonometric Identities", "Applications",
    ])
    add("9", "math", "Coordinate Geometry", 5, [
        "Distance Formula", "Section Formula", "Area of Triangle",
    ])
    add("9", "math", "Statistics and Probability", 6, [
        "Mean, Median, Mode", "Standard Deviation", "Basic Probability",
    ])

    add("9", "english", "Reading Skills", 1, [
        "Skimming and Scanning", "Critical Reading", "Inferential Comprehension",
    ])
    add("9", "english", "Advanced Grammar", 2, [
        "Complex Sentences", "Subjunctive Mood", "Gerunds and Infinitives",
    ])
    add("9", "english", "Writing Skills", 3, [
        "Formal Letters", "Reports", "Creative Writing",
    ])
    add("9", "english", "Literature", 4, [
        "Shakespeare Basics", "Modern Poetry", "Bangladeshi English Writers",
    ])

    add("9", "bangla", "পড়া ও বোঝা", 1, [
        "বিভিন্ন ধরনের গদ্য", "কবিতার বিশ্লেষণ", "নাটক পাঠ",
    ])
    add("9", "bangla", "ব্যাকরণ", 2, [
        "বাক্য বিশ্লেষণ", "প্রত্যয় ও সমাস", "ভাব-সম্প্রসারণ",
    ])
    add("9", "bangla", "রচনা", 3, [
        "প্রবন্ধ", "সারাংশ ও সারমর্ম", "আবেদন ও চিঠি",
    ])

    # ── Class 10 ───────────────────────────────────────────────────────────────
    add("10", "science", "Physics - Mechanics", 1, [
        "Kinematics", "Dynamics", "Energy and Power",
    ])
    add("10", "science", "Physics - Waves and Optics", 2, [
        "Wave Motion", "Reflection and Refraction", "Lenses",
    ])
    add("10", "science", "Chemistry - Organic Chemistry", 3, [
        "Hydrocarbons", "Functional Groups", "Organic Reactions",
    ])
    add("10", "science", "Chemistry - Inorganic Chemistry", 4, [
        "Metallurgy", "Acids, Bases and Salts", "Electrochemistry",
    ])
    add("10", "science", "Biology - Genetics", 5, [
        "Mendel's Laws", "DNA and RNA", "Genetic Engineering",
    ])
    add("10", "science", "Biology - Evolution and Environment", 6, [
        "Theory of Evolution", "Adaptation", "Environmental Conservation",
    ])

    add("10", "math", "Algebra", 1, [
        "Sets and Functions", "Relations", "Binomial Theorem",
    ])
    add("10", "math", "Geometry", 2, [
        "Triangles and Circles", "Constructions", "Trigonometric Applications",
    ])
    add("10", "math", "Mensuration", 3, [
        "Area and Volume", "Surface Area", "Real-life Applications",
    ])
    add("10", "math", "Statistics", 4, [
        "Data Representation", "Measures of Central Tendency", "Probability",
    ])

    add("10", "english", "Advanced Comprehension", 1, [
        "Unseen Passages", "Critical Analysis", "Author's Purpose",
    ])
    add("10", "english", "Grammar and Usage", 2, [
        "Advanced Tenses", "Causative Verbs", "Emphatic Structures",
    ])
    add("10", "english", "Composition", 3, [
        "Essays for Exams", "Article Writing", "Speech Writing",
    ])
    add("10", "english", "Literature Studies", 4, [
        "Poetry Analysis", "Drama Study", "Novel Study",
    ])

    add("10", "bangla", "পড়া ও বোঝা", 1, [
        "গদ্য বিশ্লেষণ", "কবিতা বিশ্লেষণ", "নাটক ও উপন্যাস",
    ])
    add("10", "bangla", "ব্যাকরণ", 2, [
        "বাক্য সংকোচন", "ভাব-সম্প্রসারণ", "প্রবাদ-প্রবচন",
    ])
    add("10", "bangla", "রচনা", 3, [
        "প্রবন্ধ রচনা", "অনুচ্ছেদ রচনা", "পত্র ও আবেদন",
    ])

    for e in entries:
        db.add(CurriculumTopic(**e))

    db.commit()
    return len(entries)
