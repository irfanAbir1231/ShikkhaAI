import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select, or_
from sqlalchemy.orm import Session

from app.db.models import Attempt, CurriculumTopic, Exam, Student, Subtopic, SubtopicPerformance, TopicPerformance

logger = logging.getLogger("shikkhaai")

_SUBJECT_ICONS = {
    "science": "science",
    "math": "calculate",
    "mathematics": "calculate",
    "english": "translate",
    "bangla": "translate",
    "history": "history_edu",
    "geography": "public",
    "physics": "bolt",
    "chemistry": "science",
    "biology": "biotech",
}


def _icon_for(subject: str) -> str:
    return _SUBJECT_ICONS.get(subject.lower(), "menu_book")


class AnalyticsService:

    # ── Main analytics endpoint ───────────────────────────────────────────────

    def get_analytics(self, db: Session, student: Student) -> dict[str, Any]:
        attempts = db.scalars(
            select(Attempt)
            .where(Attempt.student_id == student.id)
            .order_by(Attempt.created_at.asc())
        ).all()

        exams_by_id: dict[int, Exam] = {}
        if attempts:
            exam_ids = list({a.exam_id for a in attempts})
            exams = db.scalars(select(Exam).where(Exam.id.in_(exam_ids))).all()
            exams_by_id = {e.id: e for e in exams}

        performances = db.scalars(
            select(TopicPerformance).where(TopicPerformance.student_id == student.id)
        ).all()

        total_questions = sum(a.mcq_total for a in attempts)
        avg_accuracy = (
            round(sum(a.score_percentage for a in attempts) / len(attempts), 1)
            if attempts else 0.0
        )

        # Subtopic analytics
        subtopic_performances = db.scalars(
            select(SubtopicPerformance).where(SubtopicPerformance.student_id == student.id)
        ).all()
        subtopic_accuracy = self._build_subtopic_accuracy(db, subtopic_performances)
        weak_subtopics = [s for s in subtopic_accuracy if not s["is_mastered"]]
        mastered_subtopics = [s for s in subtopic_accuracy if s["is_mastered"]]

        return {
            "topic_accuracy": self._build_topic_accuracy(performances, exams_by_id, attempts),
            "weak_chapters": self._build_weak_chapters(performances),
            "improvement_history": self._build_improvement_history(attempts, exams_by_id),
            "streak_data": self._build_streak_data(attempts),
            "practice_suggestions": self._build_practice_suggestions(db, student.id, performances),
            "average_accuracy": avg_accuracy,
            "total_questions_attempted": total_questions,
            "total_study_minutes": total_questions * 2,  # rough estimate: 2 min/question
            "subtopic_accuracy": subtopic_accuracy,
            "weak_subtopics": weak_subtopics,
            "mastered_subtopics": mastered_subtopics,
        }

    # ── Topic accuracy detail ─────────────────────────────────────────────────

    def _build_subtopic_accuracy(
        self,
        db: Session,
        subtopic_performances: list,
    ) -> list[dict[str, Any]]:
        result = []
        for p in subtopic_performances:
            subtopic = db.get(Subtopic, p.subtopic_id)
            if not subtopic:
                continue
            ct = subtopic.curriculum_topic
            correct = round(p.average_score / 100 * p.attempts_count)
            trend = round(p.last_score - p.average_score, 1)
            last_attempted = p.updated_at.strftime("%Y-%m-%d") if p.updated_at else None
            result.append({
                "subtopic_id": p.subtopic_id,
                "name": subtopic.name,
                "topic": ct.topic if ct else "General",
                "chapter": ct.chapter if ct else "General",
                "subject": p.subject.title(),
                "accuracy": round(p.average_score, 1),
                "total_questions": p.attempts_count,
                "correct_answers": correct,
                "trend": trend,
                "last_attempted": last_attempted,
                "is_mastered": p.average_score >= 90.0,
            })
        return result

    def _build_topic_accuracy(
        self,
        performances: list,
        exams_by_id: dict,
        attempts: list,
    ) -> list[dict[str, Any]]:
        result = []
        for p in sorted(performances, key=lambda x: x.average_score):
            correct = round(p.average_score / 100 * p.attempts_count)
            trend = round(p.last_score - p.average_score, 1)
            last_attempted = p.updated_at.strftime("%Y-%m-%d") if p.updated_at else None
            result.append({
                "topic": p.topic,
                "chapter": p.topic,
                "subject": p.subject.title(),
                "accuracy": round(p.average_score, 1),
                "total_questions": p.attempts_count,
                "correct_answers": correct,
                "trend": trend,
                "last_attempted": last_attempted,
            })
        return result

    # ── Weak chapters ─────────────────────────────────────────────────────────

    def _build_weak_chapters(self, performances: list) -> list[dict[str, Any]]:
        weak = [
            p for p in performances
            if p.average_score < 60.0 or p.consistency_score < 50.0
        ]
        weak_sorted = sorted(weak, key=lambda x: x.average_score)

        result = []
        for rank, p in enumerate(weak_sorted, 1):
            trend = round(p.last_score - p.average_score, 1)
            result.append({
                "chapter_name": p.topic,
                "subject": p.subject.title(),
                "accuracy": round(p.average_score, 1),
                "weakness_rank": rank,
                "related_topics": [p.topic],
                "suggested_action": (
                    f"Focus on foundational concepts in {p.topic}. "
                    "Practice at least 10 questions before attempting harder levels."
                ),
                "trend": trend,
                "time_spent_minutes": p.attempts_count * 5,  # rough estimate
            })
        return result

    # ── Improvement history ───────────────────────────────────────────────────

    def _build_improvement_history(
        self, attempts: list, exams_by_id: dict
    ) -> list[dict[str, Any]]:
        result = []
        for a in attempts:
            exam = exams_by_id.get(a.exam_id)
            topic_scores: dict[str, float] = {}
            for wt in (a.weak_topics or []):
                if isinstance(wt, dict):
                    t = wt.get("topic")
                    s = wt.get("score")
                    if t and s is not None:
                        topic_scores[t] = float(s)
            result.append({
                "date": a.created_at.strftime("%Y-%m-%d"),
                "overall_score": round(a.score_percentage, 1),
                "topic_scores": topic_scores,
                "exam_id": str(a.exam_id),
            })
        return result

    # ── Streak data ───────────────────────────────────────────────────────────

    def _build_streak_data(self, attempts: list) -> dict[str, Any]:
        if not attempts:
            return {"current_streak": 0, "longest_streak": 0, "last_30_days": []}

        study_dates: set[date] = {
            a.created_at.astimezone(timezone.utc).date() for a in attempts
        }
        sorted_dates = sorted(study_dates, reverse=True)

        # Current streak
        current = 0
        check = date.today()
        for d in sorted_dates:
            if d == check or d == check - timedelta(days=1):
                current += 1
                check = d - timedelta(days=1)
            else:
                break

        # Longest streak
        longest = 0
        run = 0
        prev_d: date | None = None
        for d in sorted(study_dates):
            run = run + 1 if prev_d and d == prev_d + timedelta(days=1) else 1
            longest = max(longest, run)
            prev_d = d

        # Per-day stats for last 30 days
        today = date.today()
        date_to_attempts: dict[date, list] = {}
        for a in attempts:
            d = a.created_at.astimezone(timezone.utc).date()
            date_to_attempts.setdefault(d, []).append(a)

        last_30: list[dict[str, Any]] = []
        for i in range(29, -1, -1):
            d = today - timedelta(days=i)
            day_attempts = date_to_attempts.get(d, [])
            is_active = len(day_attempts) > 0
            perf = (
                round(sum(a.score_percentage for a in day_attempts) / len(day_attempts), 1)
                if day_attempts else 0.0
            )
            questions = sum(a.mcq_total for a in day_attempts)
            last_30.append({
                "date": d.isoformat(),
                "is_active": is_active,
                "performance_score": perf if day_attempts else None,
                "questions_answered": questions,
                "study_minutes": questions * 2,
            })

        return {
            "current_streak": current,
            "longest_streak": longest,
            "last_30_days": last_30,
        }

    # ── Practice suggestions ──────────────────────────────────────────────────

    def _build_practice_suggestions(
        self,
        db: Session,
        student_id: int,
        performances: list,
    ) -> list[dict[str, Any]]:
        weak = sorted(
            [p for p in performances if p.average_score < 65.0],
            key=lambda x: x.average_score,
        )[:5]

        # Look up pre-generated notes for weak topics
        from app.db.models import Note

        topics = [p.topic for p in weak]
        note_map: dict[str, int | None] = {t: None for t in topics}
        if topics:
            notes = db.scalars(
                select(Note).where(
                    Note.student_id == student_id,
                    Note.topic.in_(topics),
                    Note.source == "practice",
                )
            ).all()
            for note in notes:
                if note.topic in note_map and note_map[note.topic] is None:
                    note_map[note.topic] = note.id

        suggestions = []
        for i, p in enumerate(weak):
            difficulty = "easy" if p.average_score < 40 else "medium"
            impact = round(min(100.0, p.average_score + 25.0), 1)
            suggestions.append({
                "id": f"sugg_{i + 1}",
                "title": f"{p.topic} Practice",
                "description": (
                    f"Strengthen your understanding of {p.topic}. "
                    f"Current accuracy: {round(p.average_score, 1)}%."
                ),
                "topic": p.topic,
                "type": "quickPractice",
                "difficulty": difficulty,
                "estimated_minutes": 15,
                "potential_impact": impact,
                "subject": p.subject.title(),
                "note_id": note_map.get(p.topic),
            })
        return suggestions

    # ── Topics by curriculum ──────────────────────────────────────────────────

    def get_topics(self, db: Session, student: Student) -> dict[str, Any]:
        # 1. Fetch curriculum topics from database (ordered by chapter, then display_order)
        curriculum_topics = db.scalars(
            select(CurriculumTopic)
            .where(CurriculumTopic.class_level == student.grade_level)
            .order_by(CurriculumTopic.subject, CurriculumTopic.chapter_number, CurriculumTopic.display_order)
        ).all()

        # 2. Fetch student topic performance
        performances = db.scalars(
            select(TopicPerformance).where(TopicPerformance.student_id == student.id)
        ).all()
        perf_by_key: dict[tuple[str, str], TopicPerformance] = {
            (p.subject.lower(), p.topic.lower()): p for p in performances
        }

        # 3. Fetch weak subtopics for this student (joined with Subtopic to get topic names)
        weak_subtopic_results = db.execute(
            select(Subtopic, SubtopicPerformance)
            .join(SubtopicPerformance, Subtopic.id == SubtopicPerformance.subtopic_id)
            .where(SubtopicPerformance.student_id == student.id)
            .where(
                or_(
                    SubtopicPerformance.average_score < 60.0,
                    SubtopicPerformance.consistency_score < 50.0,
                    SubtopicPerformance.last_score < 50.0,
                )
            )
        ).all()

        logger.info(
            "get_topics: student_id=%s weak_subtopic_results_count=%s",
            student.id,
            len(weak_subtopic_results),
        )

        topic_to_weak_subtopics: dict[str, list[int]] = {}
        for subtopic, perf in weak_subtopic_results:
            topic_name = subtopic.curriculum_topic.topic if subtopic.curriculum_topic else "General"
            topic_to_weak_subtopics.setdefault(topic_name, []).append(subtopic.id)

        logger.info(
            "get_topics: student_id=%s topic_to_weak_subtopics=%s",
            student.id,
            topic_to_weak_subtopics,
        )

        # 4. Build nested structure: subject → chapter → topics
        # Group curriculum topics by (subject, chapter)
        chapters_map: dict[tuple[str, str], list[CurriculumTopic]] = {}
        for ct in curriculum_topics:
            key = (ct.subject.lower(), ct.chapter)
            chapters_map.setdefault(key, []).append(ct)

        subjects_data = []
        total_topics = 0
        total_completed = 0

        # Collect subjects in order of first appearance
        seen_subjects: list[str] = []
        for ct in curriculum_topics:
            subj_title = ct.subject.title()
            if subj_title not in seen_subjects:
                seen_subjects.append(subj_title)

        for subject in seen_subjects:
            subj_key = subject.lower()
            # Get chapters for this subject in order of first appearance
            seen_chapters: list[str] = []
            chapter_numbers: dict[str, int | None] = {}
            for ct in curriculum_topics:
                if ct.subject.lower() == subj_key:
                    if ct.chapter not in seen_chapters:
                        seen_chapters.append(ct.chapter)
                        chapter_numbers[ct.chapter] = ct.chapter_number

            chapters_data = []
            subj_completed = 0
            subj_total = 0

            for chapter_name in seen_chapters:
                key = (subj_key, chapter_name)
                cts = chapters_map.get(key, [])
                topic_items = []
                chapter_total = 0
                chapter_completed = 0

                for ct in cts:
                    topic_name = ct.topic
                    perf = perf_by_key.get((subj_key, topic_name.lower()))
                    completion = round(perf.average_score, 1) if perf else 0.0
                    attempts = perf.attempts_count if perf else 0
                    is_done = completion >= 60.0
                    is_attempted = attempts > 0
                    is_weak = is_attempted and completion < 60.0
                    if is_done:
                        chapter_completed += 1
                        subj_completed += 1
                    chapter_total += 1
                    subj_total += 1

                    last_attempted = (
                        perf.updated_at.strftime("%Y-%m-%d") if (perf and perf.updated_at) else None
                    )
                    weak_ids = topic_to_weak_subtopics.get(topic_name, [])

                    topic_items.append({
                        "id": f"topic_{ct.id}",
                        "name": topic_name,
                        "chapter": chapter_name,
                        "chapter_number": ct.chapter_number,
                        "completion_percentage": completion,
                        "attempts_count": attempts,
                        "last_score": round(perf.last_score, 1) if perf else None,
                        "last_attempted": last_attempted,
                        "is_completed": is_done,
                        "is_attempted": is_attempted,
                        "is_weak": is_weak,
                        "weak_subtopic_ids": weak_ids,
                        "subject": subject,
                    })

                chapter_pct = round(chapter_completed / chapter_total * 100, 1) if chapter_total else 0.0
                chapters_data.append({
                    "chapter_name": chapter_name,
                    "chapter_number": chapter_numbers.get(chapter_name),
                    "overall_completion_percentage": chapter_pct,
                    "topics": topic_items,
                })

            subj_pct = round(subj_completed / subj_total * 100, 1) if subj_total else 0.0
            subjects_data.append({
                "subject": subject,
                "icon_name": _icon_for(subject),
                "total_topics": subj_total,
                "completed_topics": subj_completed,
                "overall_completion_percentage": subj_pct,
                "chapters": chapters_data,
            })
            total_topics += subj_total
            total_completed += subj_completed

        # If no curriculum topics found — fall back to TopicPerformance data
        if not subjects_data:
            subjects_data = self._fallback_topics_from_performance(db, student.id, performances)
            total_topics = sum(s["total_topics"] for s in subjects_data)
            total_completed = sum(s["completed_topics"] for s in subjects_data)

        return {
            "subjects": subjects_data,
            "total_topics": total_topics,
            "completed_topics": total_completed,
        }

    def _fallback_topics_from_performance(
        self, db: Session, student_id: int, performances: list
    ) -> list[dict[str, Any]]:
        """When CurriculumTopic table is empty, group by subject stored on TopicPerformance."""
        if not performances:
            return []

        # Group performances by their stored subject
        subject_topics: dict[str, list] = {}
        for p in performances:
            subj = p.subject.title()
            subject_topics.setdefault(subj, []).append(p)

        subjects_data = []
        for subject, subj_perfs in subject_topics.items():
            topic_items = []
            subj_completed = 0
            for p in subj_perfs:
                completion = round(p.average_score, 1)
                is_done = completion >= 60.0
                is_attempted = p.attempts_count > 0
                is_weak = is_attempted and completion < 60.0
                if is_done:
                    subj_completed += 1
                last_attempted = p.updated_at.strftime("%Y-%m-%d") if p.updated_at else None
                topic_items.append({
                    "id": f"topic_perf_{p.id}",
                    "name": p.topic,
                    "chapter": "General",
                    "completion_percentage": completion,
                    "attempts_count": p.attempts_count,
                    "last_score": round(p.last_score, 1),
                    "last_attempted": last_attempted,
                    "is_completed": is_done,
                    "is_attempted": is_attempted,
                    "is_weak": is_weak,
                    "weak_subtopic_ids": [],
                })
            n = len(subj_perfs)
            pct = round(subj_completed / n * 100, 1) if n else 0.0

            # Group into a single "General" chapter
            subjects_data.append({
                "subject": subject,
                "icon_name": _icon_for(subject),
                "total_topics": n,
                "completed_topics": subj_completed,
                "overall_completion_percentage": pct,
                "chapters": [
                    {
                        "chapter_name": "General",
                        "overall_completion_percentage": pct,
                        "topics": topic_items,
                    }
                ],
            })

        return subjects_data
