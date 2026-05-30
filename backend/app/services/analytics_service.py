import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Attempt, CurriculumTopic, Exam, Student, TopicPerformance

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

        return {
            "topic_accuracy": self._build_topic_accuracy(performances, exams_by_id, attempts),
            "weak_chapters": self._build_weak_chapters(performances),
            "improvement_history": self._build_improvement_history(attempts, exams_by_id),
            "streak_data": self._build_streak_data(attempts),
            "practice_suggestions": self._build_practice_suggestions(db, student.id, performances),
            "average_accuracy": avg_accuracy,
            "total_questions_attempted": total_questions,
            "total_study_minutes": total_questions * 2,  # rough estimate: 2 min/question
        }

    # ── Topic accuracy detail ─────────────────────────────────────────────────

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
        curriculum_topics = db.scalars(
            select(CurriculumTopic)
            .where(CurriculumTopic.class_level == student.grade_level)
            .order_by(CurriculumTopic.subject, CurriculumTopic.display_order)
        ).all()

        performances = db.scalars(
            select(TopicPerformance).where(TopicPerformance.student_id == student.id)
        ).all()
        perf_by_key: dict[tuple[str, str], TopicPerformance] = {
            (p.subject, p.topic): p for p in performances
        }

        # Group by subject
        subjects_map: dict[str, list] = {}
        for ct in curriculum_topics:
            subjects_map.setdefault(ct.subject, []).append(ct)

        subjects_data = []
        total_topics = 0
        total_completed = 0

        for subject, topics in subjects_map.items():
            topic_items = []
            subj_completed = 0
            for ct in topics:
                perf = perf_by_key.get((ct.subject, ct.topic))
                completion = round(perf.average_score, 1) if perf else 0.0
                is_done = completion >= 60.0
                if is_done:
                    subj_completed += 1
                last_attempted = (
                    perf.updated_at.strftime("%Y-%m-%d") if (perf and perf.updated_at) else None
                )
                topic_items.append({
                    "id": f"topic_{ct.id}",
                    "name": ct.topic,
                    "completion_percentage": completion,
                    "attempts_count": perf.attempts_count if perf else 0,
                    "last_score": round(perf.last_score, 1) if perf else None,
                    "last_attempted": last_attempted,
                    "is_completed": is_done,
                })
            n = len(topics)
            pct = round(subj_completed / n * 100, 1) if n else 0.0
            subjects_data.append({
                "subject": subject,
                "icon_name": _icon_for(subject),
                "total_topics": n,
                "completed_topics": subj_completed,
                "overall_completion_percentage": pct,
                "topics": topic_items,
            })
            total_topics += n
            total_completed += subj_completed

        # If no curriculum seeded yet — fall back to TopicPerformance data
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
                if is_done:
                    subj_completed += 1
                last_attempted = p.updated_at.strftime("%Y-%m-%d") if p.updated_at else None
                topic_items.append({
                    "id": f"topic_perf_{p.id}",
                    "name": p.topic,
                    "completion_percentage": completion,
                    "attempts_count": p.attempts_count,
                    "last_score": round(p.last_score, 1),
                    "last_attempted": last_attempted,
                    "is_completed": is_done,
                })
            n = len(subj_perfs)
            pct = round(subj_completed / n * 100, 1) if n else 0.0
            subjects_data.append({
                "subject": subject,
                "icon_name": _icon_for(subject),
                "total_topics": n,
                "completed_topics": subj_completed,
                "overall_completion_percentage": pct,
                "topics": topic_items,
            })

        return subjects_data