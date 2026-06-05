# from datetime import datetime, timezone
# from typing import Any

# from sqlalchemy import DateTime, Float, ForeignKey, Integer, JSON, String, UniqueConstraint
# from sqlalchemy.orm import Mapped, mapped_column, relationship

# from app.db.base import Base


# def utc_now() -> datetime:
#     return datetime.now(timezone.utc)


# class Student(Base):
#     __tablename__ = "students"

#     id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
#     name: Mapped[str] = mapped_column(String(120), nullable=False)
#     email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
#     grade_level: Mapped[str] = mapped_column(String(50), nullable=False)
#     password: Mapped[str | None] = mapped_column(String(255), nullable=True)
#     created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
#     updated_at: Mapped[datetime] = mapped_column(
#         DateTime(timezone=True),
#         default=utc_now,
#         onupdate=utc_now,
#     )

#     exams: Mapped[list["Exam"]] = relationship(
#         back_populates="student",
#         cascade="all, delete-orphan",
#     )
#     attempts: Mapped[list["Attempt"]] = relationship(
#         back_populates="student",
#         cascade="all, delete-orphan",
#     )
#     topic_performances: Mapped[list["TopicPerformance"]] = relationship(
#         back_populates="student",
#         cascade="all, delete-orphan",
#     )


# class Exam(Base):
#     __tablename__ = "exams"

#     id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
#     student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
#     subject: Mapped[str] = mapped_column(String(100), nullable=False)
#     topic: Mapped[str] = mapped_column(String(150), nullable=False)
#     difficulty: Mapped[str] = mapped_column(String(50), nullable=False)
#     questions: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
#     answer_key: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
#     source: Mapped[str] = mapped_column(String(50), nullable=False)
#     created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

#     student: Mapped[Student] = relationship(back_populates="exams")
#     attempts: Mapped[list["Attempt"]] = relationship(back_populates="exam")


# class Attempt(Base):
#     __tablename__ = "attempts"

#     id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
#     student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
#     exam_id: Mapped[int] = mapped_column(ForeignKey("exams.id"), index=True, nullable=False)
#     answers: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
#     score_percentage: Mapped[float] = mapped_column(Float, nullable=False)
#     mcq_correct: Mapped[int] = mapped_column(Integer, nullable=False)
#     mcq_total: Mapped[int] = mapped_column(Integer, nullable=False)
#     short_answer_feedback: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
#     weak_topics: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False)
#     readiness_score: Mapped[float] = mapped_column(Float, nullable=False)
#     created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

#     student: Mapped[Student] = relationship(back_populates="attempts")
#     exam: Mapped[Exam] = relationship(back_populates="attempts")


# class TopicPerformance(Base):
#     __tablename__ = "topic_performance"
#     __table_args__ = (UniqueConstraint("student_id", "topic", name="uq_topic_performance_student_topic"),)

#     id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
#     student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
#     topic: Mapped[str] = mapped_column(String(150), nullable=False)
#     attempts_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
#     average_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
#     consistency_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
#     last_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
#     updated_at: Mapped[datetime] = mapped_column(
#         DateTime(timezone=True),
#         default=utc_now,
#         onupdate=utc_now,
#     )

#     student: Mapped[Student] = relationship(back_populates="topic_performances")

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


# ─────────────────────────── Existing Models ─────────────────────────────────

class Student(Base):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    grade_level: Mapped[str] = mapped_column(String(50), nullable=False)
    password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )

    exams: Mapped[list["Exam"]] = relationship(back_populates="student", cascade="all, delete-orphan")
    attempts: Mapped[list["Attempt"]] = relationship(back_populates="student", cascade="all, delete-orphan")
    topic_performances: Mapped[list["TopicPerformance"]] = relationship(back_populates="student", cascade="all, delete-orphan")
    notes: Mapped[list["Note"]] = relationship(back_populates="student", cascade="all, delete-orphan")
    study_plans: Mapped[list["StudyPlan"]] = relationship(back_populates="student", cascade="all, delete-orphan")


class Exam(Base):
    __tablename__ = "exams"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), nullable=False)
    class_level: Mapped[str] = mapped_column(String(50), nullable=False, default="8")
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
    __table_args__ = (
        UniqueConstraint("student_id", "subject", "topic", name="uq_topic_performance_student_subject_topic"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(100), nullable=False, default="General")
    topic: Mapped[str] = mapped_column(String(150), nullable=False)
    attempts_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    average_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    consistency_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    last_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )

    student: Mapped[Student] = relationship(back_populates="topic_performances")


# ─────────────────────────── New Models ──────────────────────────────────────

class Note(Base):
    __tablename__ = "notes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    topic: Mapped[str | None] = mapped_column(String(150), nullable=True, index=True)
    subject: Mapped[str | None] = mapped_column(String(100), nullable=True)
    class_level: Mapped[str | None] = mapped_column(String(50), nullable=True)
    source: Mapped[str] = mapped_column(String(50), nullable=False, default="study_companion")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    student: Mapped[Student] = relationship(back_populates="notes")


class StudyPlan(Base):
    __tablename__ = "study_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    exam_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    daily_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now
    )

    student: Mapped[Student] = relationship(back_populates="study_plans")
    tasks: Mapped[list["StudyPlanTask"]] = relationship(
        back_populates="plan", cascade="all, delete-orphan", order_by="StudyPlanTask.scheduled_date"
    )


class StudyPlanTask(Base):
    __tablename__ = "study_plan_tasks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("study_plans.id"), index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False, default="")
    subject: Mapped[str] = mapped_column(String(100), nullable=False)
    topic: Mapped[str] = mapped_column(String(150), nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    actual_minutes_spent: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    type: Mapped[str] = mapped_column(String(50), nullable=False, default="practice")
    scheduled_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    plan: Mapped[StudyPlan] = relationship(back_populates="tasks")


class CurriculumTopic(Base):
    __tablename__ = "curriculum_topics"
    __table_args__ = (
        UniqueConstraint("class_level", "subject", "chapter", "topic", name="uq_curriculum_topic_chapter"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    class_level: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    subject: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    chapter: Mapped[str] = mapped_column(String(150), nullable=False, default="General")
    chapter_number: Mapped[int | None] = mapped_column(Integer, nullable=True)
    topic: Mapped[str] = mapped_column(String(150), nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)