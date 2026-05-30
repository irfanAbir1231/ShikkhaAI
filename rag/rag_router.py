"""
rag_router.py — FastAPI router exposing RAG endpoints
Member 2 includes it in main.py with:
    from rag.rag_router import router as rag_router
    app.include_router(rag_router, prefix="/rag")
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from .retrieve import retrieve_context, build_rag_context
from .generate import generate_questions, generate_answer

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


class WeakTopicsRequest(BaseModel):
    student_id: int
    topics: list[dict]


class AskRequest(BaseModel):
    query: str
    mode: str
    subject: str
    class_level: str
    pdf_context: Optional[str] = None


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


@router.post("/ask")
def ask(req: AskRequest):
    """
    Study-companion Q&A endpoint.
    Retrieves curriculum context and generates a mode-specific answer.
    """
    try:
        result = generate_answer(
            query=req.query,
            mode=req.mode,
            subject=req.subject,
            class_level=req.class_level,
            pdf_context=req.pdf_context,
        )
        return result
    except RuntimeError as exc:
        # Gemini API errors (quota, key invalid, etc.) — propagate clearly
        err_msg = str(exc)
        if "Gemini generation failed" in err_msg or "RESOURCE_EXHAUSTED" in err_msg:
            raise HTTPException(
                status_code=503,
                detail=f"Gemini API unavailable: {err_msg}. Please wait a few minutes and retry.",
            )
        raise HTTPException(status_code=500, detail=err_msg)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/weak-topics")
def weak_topics(req: WeakTopicsRequest):
    """
    Returns weak topics based on performance data.
    Mirrors the backend's local weak-topic heuristic so the RAG service
    can be used as a drop-in replacement for the mock fallback.
    """
    weak: list[dict] = []
    for item in req.topics:
        score = float(item.get("score") or 0.0)
        consistency_score = float(item.get("consistency_score") or 0.0)
        last_score = float(item.get("last_score") or 0.0)
        if score < 60.0 or consistency_score < 50.0 or last_score < 50.0:
            weak.append(
                {
                    "topic": str(item.get("topic") or "Unknown"),
                    "reason": "Low topic average or inconsistent recent performance",
                    "score": round(score, 2),
                }
            )
    return {"weak_topics": weak}
