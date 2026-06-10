"""rag_router.py — FastAPI router exposing RAG endpoints"""

import traceback

from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional

from .retrieve import retrieve_context, build_rag_context
from .generate import generate_questions, generate_answer, _gemini_generate, GEMINI_MODEL, SYSTEM_PROMPT, MODE_PROMPTS
from .topic_segmenter import segment_text_by_headers, TopicChunk

from .space_ingest import (
    ingest_space_document,
    delete_space_document,
    delete_space_all_documents,
    retrieve_space_context,
)

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


class SpaceAskRequest(BaseModel):
    query: str
    mode: str
    space_id: int
    subject: Optional[str] = None
    class_level: Optional[str] = None


class DeleteSpaceDocumentRequest(BaseModel):
    space_id: int
    filename: str


class DeleteSpaceRequest(BaseModel):
    space_id: int


# ─── Endpoints ────────────────────────────────────────────────────────────────


@router.post("/generate-exam")
def generate_exam(req: GenerateRequest):
    """
    Called by Member 2's /generate-exam endpoint after student profile lookup.
    Returns questions matching the API contract.

    If topic or chapter is provided, generates topic-aware exam questions
    filtered to that specific topic or chapter.
    """
    print(
        f"[/generate-exam] subject={req.subject!r} class={req.class_level!r} "
        f"difficulty={req.difficulty!r} count={req.count} "
        f"topic={req.topic!r} chapter={req.chapter!r}"
    )
    try:
        result = generate_questions(
            subject=req.subject,
            class_level=req.class_level,
            difficulty=req.difficulty,
            count=req.count,
            query_override=req.topic or None,
            chapter=req.chapter or None,
        )
        q_count = len(result.get("questions", []))
        is_fallback = result.get("_fallback", False)
        print(f"[/generate-exam] OK — {q_count} questions returned (fallback={is_fallback})")
        return result
    except RuntimeError as exc:
        err_msg = str(exc)
        print(f"[/generate-exam] RuntimeError: {err_msg}")
        traceback.print_exc()
        if "RESOURCE_EXHAUSTED" in err_msg:
            raise HTTPException(
                status_code=503,
                detail="Gemini API quota exceeded. Please wait a few minutes and retry.",
            )
        raise HTTPException(status_code=500, detail=err_msg)
    except Exception as exc:
        print(f"[/generate-exam] Unhandled exception: {exc}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(exc))


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


# ── Space ingestion endpoints ─────────────────────────────────────────────────

@router.post("/ingest-space-document")
async def ingest_space_document_endpoint(
    space_id: int = Form(...),
    subject: Optional[str] = Form(default=None),
    class_level: Optional[str] = Form(default=None),
    file: UploadFile = File(...),
):
    """
    Ingest a student-uploaded PDF into ChromaDB, tagged with space_id.
    Called by the backend SpaceService after the file passes validation.
    """
    pdf_bytes = await file.read()
    if not pdf_bytes:
        raise HTTPException(status_code=400, detail="Empty file.")

    try:
        result = ingest_space_document(
            space_id=space_id,
            filename=file.filename or "upload.pdf",
            pdf_bytes=pdf_bytes,
            subject=subject,
            class_level=class_level,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {exc}")

    return result


@router.delete("/space-document")
def delete_space_document_endpoint(req: DeleteSpaceDocumentRequest):
    """Remove all ChromaDB chunks for one document in a space."""
    deleted = delete_space_document(space_id=req.space_id, filename=req.filename)
    return {"deleted_chunks": deleted}


@router.delete("/space-documents")
def delete_space_documents_endpoint(req: DeleteSpaceRequest):
    """Remove ALL ChromaDB chunks for a space (called when space is deleted)."""
    deleted = delete_space_all_documents(space_id=req.space_id)
    return {"deleted_chunks": deleted}


# ── Space-scoped ask ──────────────────────────────────────────────────────────

@router.post("/ask-space")
def ask_space(req: SpaceAskRequest):
    """
    Study-companion Q&A scoped to a space_id.
    Retrieves only chunks belonging to that space from ChromaDB,
    then generates a Gemini answer grounded in those documents.
    """
    context = retrieve_space_context(
        query=req.query,
        space_id=req.space_id,
        n_results=5,
    )

    if not context:
        return {
            "response": (
                "I couldn't find relevant information in your uploaded documents. "
                "Make sure you have uploaded PDFs to this space, or try rephrasing your question."
            ),
            "sources": [],
        }

    mode_instruction = MODE_PROMPTS.get(
        req.mode,
        "Give a clear, helpful explanation based on the provided documents.",
    )

    class_level = req.class_level or "8"
    subject_label = (req.subject or "the subject").title()

    prompt = f"""You are ShikkhaAI, a helpful tutor for {subject_label} students.

DOCUMENT CONTEXT (from student's uploaded files):
{context}

STUDENT QUESTION:
{req.query}

INSTRUCTIONS:
{mode_instruction}

CRITICAL RULES:
- Answer STRICTLY based on the DOCUMENT CONTEXT provided above.
- If the documents do NOT contain enough information, say: "I don't have enough information about that in your uploaded documents."
- Do NOT use outside knowledge not present in the context.
- Output markdown ONLY. No preamble.
- Do NOT wrap your answer in JSON."""

    try:
        response = _gemini_generate(
            contents=SYSTEM_PROMPT + "\n\n" + prompt,
        )
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Gemini generation failed: {exc}")

    return {
        "response": (response.text or "").strip(),
        "sources": [],
    }
