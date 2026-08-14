"""Create the public interviewer demo account when it is missing.

The account is deterministic so an interviewer can start using the deployed
app without registering first. The password is only used to seed the bcrypt
hash and is never logged.
"""

from os import getenv

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.db.models import Student

DEMO_EMAIL = getenv("DEMO_USER_EMAIL", "demo@shikkhaai.app").strip().lower()
DEMO_PASSWORD = getenv("DEMO_USER_PASSWORD", "").strip()
DEMO_NAME = getenv("DEMO_USER_NAME", "ShikkhaAI Demo User").strip() or "ShikkhaAI Demo User"
DEMO_GRADE_LEVEL = getenv("DEMO_USER_GRADE_LEVEL", "8").strip() or "8"


def seed_demo_user(db: Session) -> bool:
    """Insert the public demo student once and report whether it was created.

    DEMO_USER_PASSWORD is optional because the public demo-login endpoint does
    not authenticate with a password. If one is configured, normal password
    login remains available for the demo account as well.
    """
    if not DEMO_EMAIL:
        return False

    existing = db.scalar(select(Student).where(Student.email == DEMO_EMAIL))
    if existing is not None:
        return False

    db.add(
        Student(
            name=DEMO_NAME,
            email=DEMO_EMAIL,
            grade_level=DEMO_GRADE_LEVEL,
            password=hash_password(DEMO_PASSWORD) if DEMO_PASSWORD else None,
        )
    )
    db.commit()
    return True
