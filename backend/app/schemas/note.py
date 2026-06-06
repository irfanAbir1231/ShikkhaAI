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


class NoteGenerateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    topic: str = Field(min_length=1, max_length=150)
    subject: str = Field(min_length=1, max_length=100)


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
    version_count: int = 0


class NoteVersionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: int
    version: int
    content: str
    generated_at: datetime


class SavedNoteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: int
    note_id: int
    title: str
    topic: str | None
    bookmarked: bool
    saved_at: datetime