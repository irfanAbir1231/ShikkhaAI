from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StrictRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class ExamGenerateRequest(StrictRequestModel):
    student_id: int = Field(gt=0)
    subject: str = Field(min_length=1, max_length=100)
    topic: str = Field(min_length=1, max_length=150)
    class_level: str = Field(default="8", min_length=1, max_length=3)
    difficulty: Literal["easy", "medium", "hard"] = "medium"
    num_questions: int = Field(default=5, ge=1, le=20)

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
    prompt: str
    options: list[str] = Field(default_factory=list)
    marks: int = Field(default=1, ge=1)


class ExamResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    exam_id: int
    student_id: int
    subject: str
    topic: str
    difficulty: str
    source: Literal["rag", "mock", "gemini"]
    questions: list[ExamQuestion]


class AnswerSubmission(StrictRequestModel):
    question_id: str = Field(min_length=1, max_length=80)
    answer: str = Field(min_length=0, max_length=4000)

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


class ExamSubmitResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    attempt_id: int
    student_id: int
    exam_id: int
    score_percentage: float
    mcq_correct: int
    mcq_total: int
    weak_topics: list[WeakTopic]
    readiness_score: float
    short_answer_feedback: list[ShortAnswerFeedback]
