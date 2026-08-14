import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Attempt, Exam, Student, TopicPerformance

logger = logging.getLogger("shikkhaai")

# Colour palette for weak subjects (cycles through these)
_SUBJECT_COLORS = ["#6366F1", "#EC4899", "#F59E0B", "#10B981", "#3B82F6", "#EF4444"]
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


class DashboardService:
    def get_dashboard(self, db: Session, student: Student) -> dict[str, Any]:
        attempts = db.scalars(
            select(Attempt)
            .where(Attempt.student_id == student.id)
            .order_by(Attempt.created_at.desc())
        ).all()

        exams_by_id: dict[int, Exam] = {}
        if attempts:
            exam_ids = list({a.exam_id for a in attempts})
            exams = db.scalars(select(Exam).where(Exam.id.in_(exam_ids))).all()
            exams_by_id = {e.id: e for e in exams}

        performances = db.scalars(
            select(TopicPerformance).where(TopicPerformance.student_id == student.id)
        ).all()

        return {
            "readiness": self._build_readiness(attempts, performances),
            "weak_subjects": self._build_weak_subjects(performances),
            "streak": self._build_streak(attempts),
            "improvement": self._build_improvement(attempts),
            "topic_accuracy": self._build_topic_accuracy(performances),
            "recent_quizzes": self._build_recent_quizzes(attempts, exams_by_id),
            "recommendations": self._build_recommendations(performances),
        }

    # ── Readiness ────────────────────────────────────────────────────────────

    def _build_readiness(self, attempts: list, performances: list) -> dict[str, Any]:
        if not attempts:
            return {"overall": 0.0, "trend": 0.0, "breakdown": {}}

        latest = attempts[0].readiness_score
        prev = attempts[1].readiness_score if len(attempts) > 1 else latest
        trend = round(latest - prev, 2)

        # breakdown: group topics into broad categories
        conceptual, problem_solving = [], []
        for p in performances:
            name = p.topic.lower()
            if any(kw in name for kw in ["law", "theory", "concept", "definition", "principle"]):
                conceptual.append(p.average_score)
            else:
                problem_solving.append(p.average_score)

        breakdown: dict[str, float] = {}
        if conceptual:
            breakdown["Conceptual"] = round(sum(conceptual) / len(conceptual), 1)
        if problem_solving:
            breakdown["Problem Solving"] = round(sum(problem_solving) / len(problem_solving), 1)

        return {"overall": round(latest, 1), "trend": trend, "breakdown": breakdown}

    # ── Weak subjects ────────────────────────────────────────────────────────

    def _build_weak_subjects(self, performances: list) -> list[dict[str, Any]]:
        subject_scores: dict[str, list[float]] = {}
        for p in performances:
            subject = p.subject.title()
            subject_scores.setdefault(subject, []).append(p.average_score)

        weak = []
        for i, (subj, scores) in enumerate(subject_scores.items()):
            avg = round(sum(scores) / len(scores), 1)
            if avg < 60.0:
                weak.append({
                    "name": subj,
                    "accuracy": avg,
                    "color": _SUBJECT_COLORS[i % len(_SUBJECT_COLORS)],
                    "icon": _icon_for(subj),
                })
        return sorted(weak, key=lambda x: x["accuracy"])[:5]

    # ── Streak ───────────────────────────────────────────────────────────────

    def _build_streak(self, attempts: list) -> dict[str, Any]:
        if not attempts:
            return {
                "current_streak": 0,
                "longest_streak": 0,
                "weekly_activity": [False] * 7,
                "last_study_date": None,
            }

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
        prev_date: date | None = None
        for d in sorted(study_dates):
            if prev_date is None or d == prev_date + timedelta(days=1):
                run += 1
            else:
                run = 1
            longest = max(longest, run)
            prev_date = d

        # Weekly activity (Mon–Sun of current week)
        today = date.today()
        monday = today - timedelta(days=today.weekday())
        weekly = [(monday + timedelta(days=i)) in study_dates for i in range(7)]

        return {
            "current_streak": current,
            "longest_streak": longest,
            "weekly_activity": weekly,
            "last_study_date": sorted_dates[0].isoformat() if sorted_dates else None,
        }

    # ── Improvement ──────────────────────────────────────────────────────────

    def _build_improvement(self, attempts: list) -> list[dict[str, Any]]:
        if not attempts:
            return []
        # Group by ISO week, average score per week
        weekly: dict[str, list[float]] = {}
        for a in attempts:
            iso_week = a.created_at.strftime("W%W")
            weekly.setdefault(iso_week, []).append(a.score_percentage)
        return [
            {"week": week, "score": round(sum(scores) / len(scores), 1)}
            for week, scores in sorted(weekly.items())
        ][-8:]  # last 8 weeks

    # ── Topic accuracy ───────────────────────────────────────────────────────

    def _build_topic_accuracy(self, performances: list) -> list[dict[str, Any]]:
        return [
            {
                "topic": p.topic,
                "accuracy": round(p.average_score, 1),
                "total_questions": p.attempts_count,
            }
            for p in sorted(performances, key=lambda x: x.average_score)
        ]

    # ── Recent quizzes ───────────────────────────────────────────────────────

    def _build_recent_quizzes(self, attempts: list, exams_by_id: dict) -> list[dict[str, Any]]:
        result = []
        for a in attempts[:5]:
            exam = exams_by_id.get(a.exam_id)
            if not exam:
                continue
            result.append({
                "id": str(a.id),
                "title": f"{exam.subject.title()} — {exam.topic}",
                "subject": exam.subject.title(),
                "score": a.mcq_correct,
                "total": a.mcq_total,
                "date": a.created_at.strftime("%Y-%m-%d"),
                "time_taken": "—",
            })
        return result

    # ── Recommendations ──────────────────────────────────────────────────────

    def _build_recommendations(self, performances: list) -> list[dict[str, Any]]:
        recommendations = []
        weak = [p for p in performances if p.average_score < 60.0]
        weak_sorted = sorted(weak, key=lambda x: x.average_score)

        for i, p in enumerate(weak_sorted[:3]):
            recommendations.append({
                "id": f"r{i + 1}",
                "title": f"Improve on {p.topic}",
                "description": (
                    f"Your average score in {p.topic} is {round(p.average_score, 1)}%. "
                    "Practice more questions to strengthen this topic."
                ),
                "type": "study",
                "priority": "high" if p.average_score < 40 else "medium",
            })

        if not recommendations:
            recommendations.append({
                "id": "r1",
                "title": "Keep up the great work!",
                "description": "All your topics are above 60%. Try harder difficulty levels.",
                "type": "challenge",
                "priority": "low",
            })
        return recommendations
