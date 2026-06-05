"""rag_router.py — FastAPI router exposing RAG endpoints"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from .retrieve import retrieve_context, build_rag_context
from .generate import generate_questions, generate_answer
from .topic_segmenter import segment_text_by_headers, TopicChunk

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
    # Optional chapter filter for topic-aware exam generation
    chapter: Optional[str] = None


class RetrieveRequest(BaseModel):
    query: str
    subject: Optional[str] = None
    class_level: Optional[str] = None
    chapter: Optional[str] = None


class WeakTopicsRequest(BaseModel):
    student_id: int
    topics: list[dict]


class ExtractTopicsRequest(BaseModel):
    """Request for topic/chapter extraction from textbook text."""
    text: str
    chapter_prefix: Optional[str] = None


class ExtractedTopic(BaseModel):
    """A detected topic/chapter from the text."""
    topic: str
    chapter: str
    text_snippet: str
    text_length: int


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

    If topic or chapter is provided, generates topic-aware exam questions
    filtered to that specific topic or chapter.
    """
    try:
        result = generate_questions(
            subject=req.subject,
            class_level=req.class_level,
            difficulty=req.difficulty,
            count=req.count,
            query_override=req.topic or None,
            chapter=req.chapter or None,
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
        chapter=req.chapter,
    )
    return {"chunks": chunks}


@router.post("/extract-topics")
def extract_topics(req: ExtractTopicsRequest):
    """
    Extract topics and chapters from textbook text.

    Segments the input text by detecting chapter headers, section headers,
    and topic boundaries. Returns a list of extracted topic chunks with
    their associated chapter names.
    """
    try:
        chunks: list[TopicChunk] = segment_text_by_headers(
            text=req.text,
            chapter_prefix=req.chapter_prefix,
            default_topic="General Content",
        )

        result = [
            ExtractedTopic(
                topic=c.topic,
                chapter=c.chapter,
                text_snippet=c.text[:200] + "..." if len(c.text) > 200 else c.text,
                text_length=len(c.text),
            )
            for c in chunks
        ]

        return {
            "total_chunks": len(result),
            "chunks": result,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/context")
def context(req: RetrieveRequest):
    """
    Returns assembled context string for a query.
    """
    ctx = build_rag_context(
        query=req.query,
        subject=req.subject,
        class_level=req.class_level,
        chapter=req.chapter,
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


@router.get("/topics")
def get_topics(subject: Optional[str] = None, class_level: Optional[str] = None):
    """
    Get all unique chapters stored in ChromaDB.
    """
    try:
        from .retrieve import get_unique_chapters
        topics = get_unique_chapters(subject=subject, class_level=class_level)
        return {"topics": topics}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
