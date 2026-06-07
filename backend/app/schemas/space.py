from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class SpaceCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str = Field(min_length=1, max_length=120)
    subject: str | None = Field(default=None, max_length=100)
    class_level: str | None = Field(default=None, max_length=50)
    description: str | None = Field(default=None, max_length=500)


class SpaceUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    name: str | None = Field(default=None, min_length=1, max_length=120)
    subject: str | None = Field(default=None, max_length=100)
    class_level: str | None = Field(default=None, max_length=50)
    description: str | None = Field(default=None, max_length=500)


class SpaceAskRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    message: str = Field(min_length=1, max_length=4000)
    mode: str = Field(default="explain", max_length=50)


class SpaceDocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")
    id: int
    space_id: int
    filename: str
    size_bytes: int
    page_count: int
    chunks_count: int
    created_at: datetime


class SpaceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")
    id: int
    student_id: int
    name: str
    subject: str | None
    class_level: str | None
    description: str | None
    document_count: int
    created_at: datetime
    updated_at: datetime


class SpaceDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")
    id: int
    student_id: int
    name: str
    subject: str | None
    class_level: str | None
    description: str | None
    documents: list[SpaceDocumentResponse]
    created_at: datetime
    updated_at: datetime


class SpaceAskResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    response: str
    sources: list[str]
    space_id: int
    documents_used: int