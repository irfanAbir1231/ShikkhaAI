from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Subtopic, SubtopicPerformance, utc_now


class SubtopicService:
    def update_subtopic_performance(
        self,
        db: Session,
        student_id: int,
        question_results: list[dict[str, Any]],
        subject: str,
    ) -> list[int]:
        """Groups question_results by subtopic, computes average score per subtopic,
        upserts SubtopicPerformance rows. Returns list of touched subtopic_ids."""
        subtopic_scores: dict[int, list[float]] = {}
        subtopic_names: dict[int, str] = {}

        for result in question_results:
            # question_results may contain subtopic_ids from grading
            subtopic_ids = result.get("subtopic_ids") or []
            if not subtopic_ids:
                # Fallback: try to match by subtopic name(s)
                subtopic_names = result.get("subtopics") or []
                if not isinstance(subtopic_names, list):
                    subtopic_names = [str(subtopic_names)] if subtopic_names else []
                for subtopic_name in subtopic_names:
                    subtopic = db.scalar(
                        select(Subtopic).where(Subtopic.name == subtopic_name)
                    )
                    if subtopic:
                        subtopic_ids.append(subtopic.id)

            score = float(result.get("score") or 0.0) * 100.0
            for sid in subtopic_ids:
                sid = int(sid)
                subtopic_scores.setdefault(sid, []).append(score)
                if sid not in subtopic_names:
                    st = db.get(Subtopic, sid)
                    if st:
                        subtopic_names[sid] = st.name

        touched_subtopic_ids: list[int] = []
        for subtopic_id, scores in subtopic_scores.items():
            subtopic_score = round(sum(scores) / len(scores), 2)
            performance = db.scalar(
                select(SubtopicPerformance).where(
                    SubtopicPerformance.student_id == student_id,
                    SubtopicPerformance.subtopic_id == subtopic_id,
                )
            )

            if performance is None:
                performance = SubtopicPerformance(
                    student_id=student_id,
                    subtopic_id=subtopic_id,
                    subject=subject,
                    attempts_count=1,
                    average_score=subtopic_score,
                    consistency_score=subtopic_score,
                    last_score=subtopic_score,
                )
                db.add(performance)
            else:
                previous_count = performance.attempts_count
                consistency_sample = max(0.0, 100.0 - abs(performance.last_score - subtopic_score))
                performance.attempts_count = previous_count + 1
                performance.average_score = round(
                    ((performance.average_score * previous_count) + subtopic_score)
                    / performance.attempts_count,
                    2,
                )
                performance.consistency_score = round(
                    ((performance.consistency_score * previous_count) + consistency_sample)
                    / performance.attempts_count,
                    2,
                )
                performance.last_score = subtopic_score
                performance.updated_at = utc_now()

            touched_subtopic_ids.append(subtopic_id)

        db.flush()
        return touched_subtopic_ids

    def detect_weak_subtopics(
        self,
        db: Session,
        student_id: int,
        touched_subtopic_ids: list[int] | None = None,
        threshold: float = 60.0,
    ) -> list[dict[str, Any]]:
        """Returns subtopics where average_score < threshold OR consistency_score < 50 OR last_score < 50."""
        statement = select(SubtopicPerformance).where(
            SubtopicPerformance.student_id == student_id
        )
        if touched_subtopic_ids:
            statement = statement.where(SubtopicPerformance.subtopic_id.in_(touched_subtopic_ids))

        performances = list(db.scalars(statement).all())
        weak_subtopics = []
        for perf in performances:
            if (
                perf.average_score < threshold
                or perf.consistency_score < 50.0
                or perf.last_score < 50.0
            ):
                subtopic = db.get(Subtopic, perf.subtopic_id)
                topic_name = subtopic.curriculum_topic.topic if subtopic and subtopic.curriculum_topic else "General"
                weak_subtopics.append({
                    "subtopic_id": perf.subtopic_id,
                    "name": subtopic.name if subtopic else "Unknown",
                    "topic": topic_name,
                    "score": round(perf.average_score, 2),
                    "reason": "Low subtopic average or inconsistent recent performance",
                })
        return weak_subtopics

    def get_subtopic_performance(
        self,
        db: Session,
        student_id: int,
    ) -> list[dict[str, Any]]:
        """Returns full subtopic performance table for a student."""
        performances = db.scalars(
            select(SubtopicPerformance).where(SubtopicPerformance.student_id == student_id)
        ).all()

        results = []
        for perf in performances:
            subtopic = db.get(Subtopic, perf.subtopic_id)
            if not subtopic:
                continue
            mastery = perf.average_score
            results.append({
                "subtopic_id": perf.subtopic_id,
                "name": subtopic.name,
                "attempts_count": perf.attempts_count,
                "average_score": perf.average_score,
                "consistency_score": perf.consistency_score,
                "last_score": perf.last_score,
                "mastery_score": mastery,
            })
        return results

    def get_weak_subtopics_for_student(
        self,
        db: Session,
        student_id: int,
        threshold: float = 60.0,
    ) -> list[dict[str, Any]]:
        """Get all weak subtopics for a student (not just recently touched)."""
        return self.detect_weak_subtopics(db, student_id, threshold=threshold)
