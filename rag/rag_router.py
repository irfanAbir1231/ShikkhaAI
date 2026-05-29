"""
rag_router.py — FastAPI router exposing RAG endpoints
Member 2 includes it in main.py with:
    from rag.rag_router import router as rag_router
    app.include_router(rag_router, prefix="/rag")
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional

from .retrieve import retrieve_context, build_rag_context
from .generate import generate_questions

router = APIRouter()


class GenerateRequest(BaseModel):
    student_id: int
    subject: str
    class_level: str
    difficulty: Optional[str] = "medium"
    count: Optional[int] = 7
    # Optional retrieval hint. Backend passes the exam topic here so the
    # curriculum context is fetched for that topic instead of a generic query.
    topic: Optional[str] = None


class RetrieveRequest(BaseModel):
    query: str
    subject: Optional[str] = None
    class_level: Optional[str] = None


class WeakTopicInput(BaseModel):
    topic: str
    score: float = 0.0
    consistency_score: float = 0.0
    last_score: float = 0.0


class WeakTopicsRequest(BaseModel):
    student_id: int
    topics: list[WeakTopicInput] = Field(default_factory=list)


class WeakTopicResponse(BaseModel):
    topic: str
    reason: str
    score: Optional[float] = None


# ─── Endpoints ────────────────────────────────────────────────────────────────


@router.post("/generate-exam")
def generate_exam(req: GenerateRequest):
    """
    Called by Member 2's /generate-exam endpoint after student profile lookup.
    Returns questions matching the API contract.
    """
    try:
        result = generate_questions(
            subject=req.subject,
            class_level=req.class_level,
            difficulty=req.difficulty,
            count=req.count,
            query_override=req.topic or None,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/retrieve")
def retrieve(req: RetrieveRequest):
    """
    Debug endpoint — returns raw retrieved chunks.
    """
    chunks = retrieve_context(
        query=req.query,
        subject=req.subject,
        class_level=req.class_level,
    )
    return {"chunks": chunks}


@router.post("/context")
def context(req: RetrieveRequest):
    """
    Returns assembled context string for a query.
    """
    ctx = build_rag_context(
        query=req.query,
        subject=req.subject,
        class_level=req.class_level,
    )
    return {"context": ctx}


@router.post("/weak-topics")
def weak_topics(req: WeakTopicsRequest):
    """
    Returns weak topics based on topic averages and consistency, matching the
    backend profile service thresholds.
    """

    merged: dict[str, WeakTopicResponse] = {}
    for topic in req.topics:
        if (
            topic.score < 60.0
            or topic.consistency_score < 50.0
            or topic.last_score < 50.0
        ):
            name = topic.topic.strip() or "Unknown"
            merged.setdefault(
                name,
                WeakTopicResponse(
                    topic=name,
                    reason="Low topic average or inconsistent recent performance",
                    score=round(topic.score, 2),
                ),
            )

    return {"weak_topics": [item.model_dump() for item in merged.values()]}
