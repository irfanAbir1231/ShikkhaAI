from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StrictRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class ExamGenerateRequest(StrictRequestModel):
    student_id: int = Field(gt=0)
    subject: str = Field(min_length=1, max_length=100)
    topic: str = Field(min_length=1, max_length=150)
    chapter: str = Field(default="", max_length=150)
    class_level: str = Field(default="8", min_length=1, max_length=3)
    difficulty: Literal["easy", "medium", "hard"] = "medium"
    num_questions: int = Field(default=5, ge=1, le=20)
    subtopic_ids: list[int] = Field(default_factory=list)
    mastery_threshold: float = Field(default=90.0, ge=0.0, le=100.0)

    @field_validator("subject", "topic")
    @classmethod
    def strip_required_text(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("must not be blank")
        return stripped


class ExamQuestion(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    type: Literal["mcq", "short_answer"]
    topic: str
    subtopics: list[str] = Field(default_factory=list)
    prompt: str
    options: list[str] = Field(default_factory=list)
    marks: int = Field(default=1, ge=1)
    correct_answer: str = ""
    explanation: str = ""


class ExamResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    exam_id: int
    student_id: int
    subject: str
    topic: str
    difficulty: str
    source: Literal["rag", "mock", "gemini"]
    questions: list[ExamQuestion]


_MAX_ANSWER_CHARS = 4000
_MAX_ANSWERS_COUNT = 50


class AnswerSubmission(StrictRequestModel):
    question_id: str = Field(min_length=1, max_length=80)
    answer: str = Field(min_length=0, max_length=_MAX_ANSWER_CHARS)

    @field_validator("question_id")
    @classmethod
    def strip_question_id(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("must not be blank")
        return stripped


class ExamSubmitRequest(StrictRequestModel):
    student_id: int = Field(gt=0)
    exam_id: int = Field(gt=0)
    answers: list[AnswerSubmission] = Field(min_length=1)
    tab_switches: int = Field(default=0, ge=0)

    @field_validator("answers")
    @classmethod
    def limit_answer_count(cls, value: list[AnswerSubmission]) -> list[AnswerSubmission]:
        if len(value) > _MAX_ANSWERS_COUNT:
            raise ValueError(f"too many answers (max {_MAX_ANSWERS_COUNT})")
        return value


class ShortAnswerFeedback(BaseModel):
    model_config = ConfigDict(extra="forbid")

    question_id: str
    status: str
    feedback: str
    awarded_marks: float


class WeakTopic(BaseModel):
    model_config = ConfigDict(extra="forbid")

    topic: str
    reason: str
    score: float | None = None


class McqFeedback(BaseModel):
    model_config = ConfigDict(extra="forbid")

    question_id: str
    correct: bool
    correct_answer: str = ""
    submitted_answer: str = ""


class GeneratedNote(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: int
    title: str
    content: str
    topic: str | None
    subject: str | None
    class_level: str | None
    source: str
    created_at: datetime
    updated_at: datetime | None


class WeakSubtopic(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subtopic_id: int
    name: str
    topic: str
    score: float
    reason: str


class ExamSubmitResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    attempt_id: int
    student_id: int
    exam_id: int
    score_percentage: float
    mcq_correct: int
    mcq_total: int
    weak_topics: list[WeakTopic]
    weak_subtopics: list[WeakSubtopic] = Field(default_factory=list)
    readiness_score: float
    short_answer_feedback: list[ShortAnswerFeedback]
    mcq_feedback: list[McqFeedback] = Field(default_factory=list)
    generated_notes: list[GeneratedNote] = Field(default_factory=list)


# ─── History Response Schemas ────────────────────────────────────────────────


class ExamSummaryResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    exam_id: int
    student_id: int
    subject: str
    topic: str
    difficulty: str
    num_questions: int
    source: str
    created_at: str


class AttemptResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    attempt_id: int
    exam_id: int
    student_id: int
    score_percentage: float
    mcq_correct: int
    mcq_total: int
    readiness_score: float
    weak_topics: list[WeakTopic]
    short_answer_feedback: list[ShortAnswerFeedback]
    created_at: str
