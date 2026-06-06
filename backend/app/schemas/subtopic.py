from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class SubtopicResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: int
    name: str
    summary: str | None
    topic: str
    chapter: str
    subject: str
    class_level: str


class SubtopicPerformanceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    subtopic_id: int
    name: str
    attempts_count: int
    average_score: float
    consistency_score: float
    last_score: float
    mastery_score: float

    @property
    def is_mastered(self) -> bool:
        return self.mastery_score >= 90.0


class WeakSubtopicResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subtopic_id: int
    name: str
    topic: str
    score: float
    reason: str


class SubtopicWeight(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subtopic_id: int
    name: str
    weight_percentage: float


class PracticeExamGenerateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)

    student_id: int = Field(gt=0)
    subject: str = Field(min_length=1, max_length=100)
    class_level: str = Field(default="8", min_length=1, max_length=3)
    difficulty: Literal["easy", "medium", "hard"] = "medium"
    num_questions: int = Field(default=10, ge=1, le=30)
    focus_subtopics: list[int] = Field(default_factory=list)
    mastery_threshold: float = Field(default=90.0, ge=0.0, le=100.0)


class SubtopicAccuracy(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subtopic_id: int
    name: str
    topic: str
    accuracy: float
    is_mastered: bool


class SubtopicAnalyticsData(BaseModel):
    model_config = ConfigDict(extra="forbid")

    subtopic_accuracy: list[SubtopicAccuracy]
    weak_subtopics: list[WeakSubtopicResponse]
    mastered_subtopics: list[SubtopicAccuracy]
    improvement_trend: list[dict[str, float | str]] = Field(default_factory=list)
