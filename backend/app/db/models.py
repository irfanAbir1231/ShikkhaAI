from datetime import datetime, timezone
from typing import Any

from sqlalchemy import DateTime, Float, ForeignKey, Integer, JSON, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class Student(Base):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    grade_level: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        onupdate=utc_now,
    )

    exams: Mapped[list["Exam"]] = relationship(back_populates="student")
    attempts: Mapped[list["Attempt"]] = relationship(back_populates="student")
    topic_performances: Mapped[list["TopicPerformance"]] = relationship(
        back_populates="student",
        cascade="all, delete-orphan",
    )


class Exam(Base):
    __tablename__ = "exams"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), nullable=False)
    topic: Mapped[str] = mapped_column(String(150), nullable=False)
    difficulty: Mapped[str] = mapped_column(String(50), nullable=False)
    questions: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
    answer_key: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
    source: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    student: Mapped[Student] = relationship(back_populates="exams")
    attempts: Mapped[list["Attempt"]] = relationship(back_populates="exam")


class Attempt(Base):
    __tablename__ = "attempts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    exam_id: Mapped[int] = mapped_column(ForeignKey("exams.id"), index=True, nullable=False)
    answers: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
    score_percentage: Mapped[float] = mapped_column(Float, nullable=False)
    mcq_correct: Mapped[int] = mapped_column(Integer, nullable=False)
    mcq_total: Mapped[int] = mapped_column(Integer, nullable=False)
    short_answer_feedback: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
    weak_topics: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
    readiness_score: Mapped[float] = mapped_column(Float, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    student: Mapped[Student] = relationship(back_populates="attempts")
    exam: Mapped[Exam] = relationship(back_populates="attempts")


class TopicPerformance(Base):
    __tablename__ = "topic_performance"
    __table_args__ = (UniqueConstraint("student_id", "topic", name="uq_topic_performance_student_topic"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    topic: Mapped[str] = mapped_column(String(150), nullable=False)
    attempts_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    average_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    consistency_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    last_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utc_now,
        onupdate=utc_now,
    )

    student: Mapped[Student] = relationship(back_populates="topic_performances")
