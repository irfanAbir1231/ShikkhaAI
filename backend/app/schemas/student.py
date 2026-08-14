from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StrictRequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class StudentCreate(StrictRequestModel):
    name: str = Field(min_length=1, max_length=120)
    email: str = Field(min_length=3, max_length=255)
    grade_level: str = Field(min_length=1, max_length=50)
    password: str = Field(min_length=6, max_length=128)

    @field_validator("name", "grade_level")
    @classmethod
    def strip_required_text(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("must not be blank")
        return stripped

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        email = value.strip().lower()
        if "@" not in email or "." not in email.rsplit("@", maxsplit=1)[-1]:
            raise ValueError("must be a valid email address")
        return email


class StudentUpdate(StrictRequestModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    grade_level: Optional[str] = Field(default=None, min_length=1, max_length=50)

    @field_validator("name", "grade_level")
    @classmethod
    def strip_optional_text(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        if not stripped:
            raise ValueError("must not be blank")
        return stripped


class StudentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: int
    name: str
    email: str
    grade_level: str


class LoginRequest(StrictRequestModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return value.strip().lower()


class TokenResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    access_token: str
    token_type: str = "bearer"
