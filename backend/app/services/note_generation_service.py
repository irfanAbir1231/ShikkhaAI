import json
import logging
import re
from typing import Any

from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models import Note, NoteVersion, utc_now
from app.db.transactions import safe_commit

logger = logging.getLogger("shikkhaai")


class NoteGenerationService:
    """
    Generates personalized study notes for a student's weak topics
    immediately after exam submission, using Gemini.

    One Note row is created per weak topic. If a note for that
    (student_id, topic) already exists from a previous attempt it is
    UPDATED so the library doesn't fill up with duplicates.
    """

    def generate_notes_for_weak_topics(
        self,
        db: Session,
        student_id: int,
        weak_topics: list[dict[str, Any]],
        subject: str,
        class_level: str,
    ) -> list[Note]:
        if not weak_topics:
            return []

        if not settings.gemini_api_key:
            logger.warning(
                "GEMINI_API_KEY not set — skipping automatic note generation"
            )
            return []

        generated: list[Note] = []
        for wt in weak_topics:
            topic = str(wt.get("topic") or "").strip()
            score = wt.get("score")
            if not topic:
                continue
            try:
                note = self._generate_and_save(
                    db=db,
                    student_id=student_id,
                    topic=topic,
                    subject=subject,
                    class_level=class_level,
                    score=score,
                    source="practice",
                )
                generated.append(note)
            except Exception:
                # Never let note generation crash the exam submit response
                logger.exception(
                    "Failed to generate note for student_id=%s topic=%s",
                    student_id,
                    topic,
                )

        return generated

    def generate_notes_for_weak_subtopics(
        self,
        db: Session,
        student_id: int,
        weak_subtopics: list[dict[str, Any]],
        subject: str,
        class_level: str,
    ) -> list[Note]:
        """Generate focused notes grouped by parent topic, covering only weak subtopics."""
        if not weak_subtopics:
            return []

        if not settings.gemini_api_key:
            logger.warning(
                "GEMINI_API_KEY not set — skipping automatic focused note generation"
            )
            return []

        # Group weak subtopics by parent topic
        from collections import defaultdict
        grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for ws in weak_subtopics:
            topic = str(ws.get("topic") or "General").strip()
            grouped[topic].append(ws)

        generated: list[Note] = []
        for topic, subtopics in grouped.items():
            if not topic:
                continue
            try:
                note = self._generate_focused_note(
                    db=db,
                    student_id=student_id,
                    topic=topic,
                    weak_subtopics=subtopics,
                    subject=subject,
                    class_level=class_level,
                )
                generated.append(note)
            except Exception:
                logger.exception(
                    "Failed to generate focused note for student_id=%s topic=%s",
                    student_id,
                    topic,
                )

        return generated

    # ── public on-demand generation ───────────────────────────────────────────

    def generate_note_for_topic(
        self,
        db: Session,
        student_id: int,
        topic: str,
        subject: str,
        class_level: str,
    ) -> Note:
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY not configured")

        content = self._call_gemini_for_topic(
            topic=topic,
            subject=subject,
            class_level=class_level,
        )

        from sqlalchemy import select

        existing = db.scalar(
            select(Note).where(
                Note.student_id == student_id,
                Note.topic == topic,
                Note.subject == subject,
                Note.source == "topic_notes",
            )
        )

        if existing:
            existing.content = content
            existing.updated_at = utc_now()
            note = existing
            logger.info(
                "Updated topic note id=%s student_id=%s topic=%s",
                note.id,
                student_id,
                topic,
            )
        else:
            note = Note(
                student_id=student_id,
                title=f"Study Notes: {topic}",
                content=content,
                topic=topic,
                subject=subject,
                class_level=class_level,
                source="topic_notes",
            )
            db.add(note)
            logger.info(
                "Created topic note student_id=%s topic=%s", student_id, topic
            )

        safe_commit(db)
        db.refresh(note)
        return note

    # ── internals ─────────────────────────────────────────────────────────────

    def _generate_and_save(
        self,
        db: Session,
        student_id: int,
        topic: str,
        subject: str,
        class_level: str,
        score: float | None,
        source: str = "practice",
    ) -> Note:
        content = self._call_gemini(
            topic=topic,
            subject=subject,
            class_level=class_level,
            score=score,
        )

        # Upsert: update existing note for same student+topic+source, or create new
        from sqlalchemy import select
        existing = db.scalar(
            select(Note).where(
                Note.student_id == student_id,
                Note.topic == topic,
                Note.subject == subject,
                Note.source == source,
            )
        )

        if existing:
            # Auto-version: save old content before overwriting
            self._create_version(db, existing)
            existing.content = content
            existing.updated_at = utc_now()
            note = existing
            logger.info(
                "Updated note id=%s student_id=%s topic=%s", note.id, student_id, topic
            )
        else:
            score_str = f"{round(score, 1)}%" if score is not None else "low"
            note = Note(
                student_id=student_id,
                title=f"Study Notes: {topic}",
                content=content,
                topic=topic,
                subject=subject,
                class_level=class_level,
                source=source,
            )
            db.add(note)
            logger.info(
                "Created note student_id=%s topic=%s score=%s", student_id, topic, score_str
            )

        safe_commit(db)
        db.refresh(note)
        return note

    def _generate_focused_note(
        self,
        db: Session,
        student_id: int,
        topic: str,
        weak_subtopics: list[dict[str, Any]],
        subject: str,
        class_level: str,
    ) -> Note:
        """Generate a focused note covering only weak subtopics under a parent topic."""
        content = self._call_gemini_for_subtopics(
            topic=topic,
            weak_subtopics=weak_subtopics,
            subject=subject,
            class_level=class_level,
        )

        from sqlalchemy import select
        existing = db.scalar(
            select(Note).where(
                Note.student_id == student_id,
                Note.topic == topic,
                Note.subject == subject,
                Note.source == "focused_practice",
            )
        )

        if existing:
            self._create_version(db, existing)
            existing.content = content
            existing.updated_at = utc_now()
            note = existing
        else:
            note = Note(
                student_id=student_id,
                title=f"Focused Notes: {topic}",
                content=content,
                topic=topic,
                subject=subject,
                class_level=class_level,
                source="focused_practice",
            )
            db.add(note)

        safe_commit(db)
        db.refresh(note)
        return note

    def _create_version(self, db: Session, note: Note) -> None:
        """Save current note content as a new version before updating."""
        if not note.content:
            return
        latest_version = 1
        from sqlalchemy import select, func
        result = db.scalar(
            select(func.max(NoteVersion.version)).where(NoteVersion.note_id == note.id)
        )
        if result:
            latest_version = int(result) + 1

        version = NoteVersion(
            note_id=note.id,
            version=latest_version,
            content=note.content,
            generated_at=note.updated_at or note.created_at,
        )
        db.add(version)
        db.flush()
        logger.info("Created note version %s for note_id=%s", latest_version, note.id)

    def _call_gemini(
        self,
        topic: str,
        subject: str,
        class_level: str,
        score: float | None,
    ) -> str:
        from google import genai

        score_context = (
            f"The student scored {round(score, 1)}% on this topic."
            if score is not None
            else "The student struggled with this topic."
        )

        prompt = f"""You are ShikkhaAI, a helpful tutor for Bangladeshi Class {class_level} students.

A student just finished an exam and performed poorly on the topic: **{topic}** ({subject}).
{score_context}

Generate clear, concise study notes to help them improve. Structure the response as markdown with these sections:

## Key Concepts
(3-5 bullet points of the most important ideas)

## Common Mistakes
(2-3 mistakes students typically make on this topic and how to avoid them)

## Key Formulas / Facts
(relevant formulas, definitions, or facts to memorise — skip if not applicable)

## Quick Practice Tips
(2-3 actionable tips the student can do right now)

Keep the language simple and suitable for a Class {class_level} student.
Write in English. Be concise — aim for under 300 words total.
Output markdown ONLY. No preamble."""

        client = genai.Client(api_key=settings.gemini_api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        return response.text.strip()

    def _call_gemini_for_topic(
        self,
        topic: str,
        subject: str,
        class_level: str,
    ) -> str:
        from google import genai

        prompt = f"""You are ShikkhaAI, a helpful tutor for Bangladeshi Class {class_level} students.

Generate clear, comprehensive study notes on the topic: **{topic}** ({subject}).

Structure the response as markdown with these sections:

## Key Concepts
(4-5 bullet points of the most important ideas)

## Important Details
(Formulas, definitions, or key facts to memorise — skip if not applicable)

## Common Mistakes
(2-3 mistakes students typically make and how to avoid them)

## Quick Practice Tips
(2-3 actionable tips the student can do right now)

Keep the language simple and suitable for a Class {class_level} student.
Write in English. Be concise but thorough — aim for 300-500 words.
Output markdown ONLY. No preamble."""

        client = genai.Client(api_key=settings.gemini_api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        return response.text.strip()

    def _call_gemini_for_subtopics(
        self,
        topic: str,
        weak_subtopics: list[dict[str, Any]],
        subject: str,
        class_level: str,
    ) -> str:
        from google import genai

        subtopic_list = "\n".join(
            f"- {ws.get('name')} (score: {round(ws.get('score', 0), 1)}%)"
            for ws in weak_subtopics
        )

        prompt = f"""You are ShikkhaAI, a helpful tutor for Bangladeshi Class {class_level} students.

A student performed poorly on these specific subtopics under **{topic}** ({subject}):

{subtopic_list}

Generate focused study notes that cover ONLY these weak subtopics. For each subtopic, create a section:

## [Subtopic Name]
- Key concepts (2-3 bullet points)
- Common mistakes and how to avoid them
- Quick practice tip

Keep each section concise (under 100 words).
Write in English. Output markdown ONLY. No preamble."""

        client = genai.Client(api_key=settings.gemini_api_key)
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        return response.text.strip()