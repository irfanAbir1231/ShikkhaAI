from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class NoteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str = Field(min_length=1, max_length=255)
    content: str = Field(min_length=1)
    topic: str | None = Field(default=None, max_length=150)
    subject: str | None = Field(default=None, max_length=100)
    class_level: str | None = Field(default=None, max_length=50)
    source: Literal["study_companion", "practice", "topic_notes"] = "study_companion"


class NoteResponse(BaseModel):
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