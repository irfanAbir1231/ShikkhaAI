from pydantic import BaseModel


class StudyCompanionAskRequest(BaseModel):
    student_id: int
    message: str
    mode: str
    subject: str
    class_level: str
    pdf_context: str | None = None


class StudyCompanionAskResponse(BaseModel):
    response: str
    sources: list[str]
