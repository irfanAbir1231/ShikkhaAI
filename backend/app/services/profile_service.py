from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import TopicPerformance, utc_now
from app.external.rag_client import RagClient


class ProfileService:
    def update_topic_performance(
        self,
        db: Session,
        student_id: int,
        question_results: list[dict[str, Any]],
    ) -> list[str]:
        topic_scores: dict[str, list[float]] = {}
        for result in question_results:
            topic = str(result.get("topic") or "General")
            topic_scores.setdefault(topic, []).append(float(result.get("score") or 0.0) * 100.0)

        touched_topics: list[str] = []
        for topic, scores in topic_scores.items():
            topic_score = round(sum(scores) / len(scores), 2)
            performance = db.scalar(
                select(TopicPerformance).where(
                    TopicPerformance.student_id == student_id,
                    TopicPerformance.topic == topic,
                )
            )

            if performance is None:
                performance = TopicPerformance(
                    student_id=student_id,
                    topic=topic,
                    attempts_count=1,
                    average_score=topic_score,
                    consistency_score=topic_score,
                    last_score=topic_score,
                )
                db.add(performance)
            else:
                previous_count = performance.attempts_count
                consistency_sample = max(0.0, 100.0 - abs(performance.last_score - topic_score))
                performance.attempts_count = previous_count + 1
                performance.average_score = round(
                    ((performance.average_score * previous_count) + topic_score)
                    / performance.attempts_count,
                    2,
                )
                performance.consistency_score = round(
                    ((performance.consistency_score * previous_count) + consistency_sample)
                    / performance.attempts_count,
                    2,
                )
                performance.last_score = topic_score
                performance.updated_at = utc_now()

            touched_topics.append(topic)

        db.flush()
        return touched_topics

    def detect_weak_topics(
        self,
        db: Session,
        student_id: int,
        touched_topics: list[str],
        rag_client: RagClient,
    ) -> list[dict[str, Any]]:
        performances = self._load_topic_performances(db, student_id, touched_topics)
        topic_payload = [
            {
                "topic": performance.topic,
                "score": performance.average_score,
                "consistency_score": performance.consistency_score,
                "last_score": performance.last_score,
            }
            for performance in performances
        ]

        local_weak_topics = [
            {
                "topic": item["topic"],
                "reason": "Low topic average or inconsistent recent performance",
                "score": round(float(item["score"]), 2),
            }
            for item in topic_payload
            if float(item["score"]) < 60.0
            or float(item["consistency_score"]) < 50.0
            or float(item["last_score"]) < 50.0
        ]
        rag_weak_topics = rag_client.detect_weak_topics(
            {
                "student_id": student_id,
                "topics": topic_payload,
            }
        )
        return self._merge_weak_topics(local_weak_topics, rag_weak_topics)

    def compute_readiness_score(
        self,
        db: Session,
        student_id: int,
        exam_score: float,
        touched_topics: list[str],
    ) -> float:
        performances = self._load_topic_performances(db, student_id, touched_topics)
        if performances:
            consistency = sum(item.consistency_score for item in performances) / len(performances)
        else:
            consistency = exam_score

        readiness = (0.60 * exam_score) + (0.40 * consistency)
        return round(max(0.0, min(readiness, 100.0)), 2)

    def _load_topic_performances(
        self,
        db: Session,
        student_id: int,
        touched_topics: list[str],
    ) -> list[TopicPerformance]:
        statement = select(TopicPerformance).where(TopicPerformance.student_id == student_id)
        if touched_topics:
            statement = statement.where(TopicPerformance.topic.in_(touched_topics))
        return list(db.scalars(statement).all())

    def _merge_weak_topics(
        self,
        local_weak_topics: list[dict[str, Any]],
        rag_weak_topics: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        merged: dict[str, dict[str, Any]] = {}
        for item in local_weak_topics + rag_weak_topics:
            topic = str(item.get("topic") or "Unknown")
            if topic not in merged:
                merged[topic] = {
                    "topic": topic,
                    "reason": str(item.get("reason") or "Weak topic detected"),
                    "score": item.get("score"),
                }
        return list(merged.values())
