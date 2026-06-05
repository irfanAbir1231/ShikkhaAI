import logging
from typing import Any

from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.routes_students import get_current_student
from app.core.responses import AppError, success_response
from app.db.models import CurriculumTopic, Student
from app.db.session import get_db

logger = logging.getLogger("shikkhaai")
router = APIRouter(prefix="/curriculum", tags=["curriculum"])


@router.get("/{class_level}/{subject}/chapters")
def get_chapters(
    class_level: str = Path(min_length=1, max_length=10),
    subject: str = Path(min_length=1, max_length=100),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    """Return distinct chapters for a given class level and subject."""
    rows = db.scalars(
        select(CurriculumTopic)
        .where(
            CurriculumTopic.class_level == class_level,
            CurriculumTopic.subject == subject.lower(),
        )
        .order_by(CurriculumTopic.chapter_number, CurriculumTopic.display_order)
    ).all()

    # Distinct chapters preserving order
    seen: set[str] = set()
    chapters: list[dict[str, Any]] = []
    for row in rows:
        key = row.chapter
        if key not in seen:
            seen.add(key)
            chapters.append({
                "id": key,
                "name": key,
                "chapter_number": row.chapter_number,
            })

    return success_response(chapters)


@router.get("/{class_level}/{subject}/topics")
def get_topics(
    class_level: str = Path(min_length=1, max_length=10),
    subject: str = Path(min_length=1, max_length=100),
    chapter: str = Query(..., min_length=1),
    search: str = Query("", max_length=100),
    db: Session = Depends(get_db),
    current_student: Student = Depends(get_current_student),
) -> dict[str, Any]:
    """Return topics for a given class level, subject, and chapter."""
    stmt = (
        select(CurriculumTopic)
        .where(
            CurriculumTopic.class_level == class_level,
            CurriculumTopic.subject == subject.lower(),
            CurriculumTopic.chapter == chapter,
        )
        .order_by(CurriculumTopic.display_order)
    )

    rows = db.scalars(stmt).all()

    topics: list[dict[str, Any]] = []
    for row in rows:
        if search and search.lower() not in row.topic.lower():
            continue
        topics.append({
            "id": f"topic_{row.id}",
            "name": row.topic,
        })

    return success_response(topics)
