"""
space_ingest.py — PDF ingestion for student Study Spaces

Mirrors ingest.py but stores chunks in the same ChromaDB collection
(nctb_curriculum) with an extra `space_id` metadata field so retrieval
can filter to a specific space.

Key differences from ingest.py:
  - No filename-based subject/class parsing — caller supplies space_id
  - Existing chunks for the same (space_id, file_hash) are deleted before
    re-indexing so re-uploads don't duplicate
  - Chapter detection is best-effort; chunks always carry space_id
"""

import hashlib
import re
import time
from pathlib import Path

import chromadb
import fitz
import numpy as np
from fastembed import TextEmbedding

CHROMA_DB_PATH = str(Path(__file__).resolve().parent.parent / "chroma_db")
COLLECTION_NAME = "nctb_curriculum"

EMBED_MODEL = "BAAI/bge-small-en-v1.5"

CHUNK_SIZE = 1000
CHUNK_OVERLAP = 120
EMBED_BATCH = 128

# Shared lazy-loaded model (reuse the one already loaded in retrieve.py if possible)
_model: "TextEmbedding | None" = None


def _get_model() -> TextEmbedding:
    global _model
    if _model is None:
        _model = TextEmbedding(model_name=EMBED_MODEL)
    return _model


def _get_collection():
    client = chromadb.PersistentClient(path=CHROMA_DB_PATH)
    return client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )


# ── Helpers (duplicated from ingest.py to keep this module self-contained) ────

CHAPTER_PATTERN = re.compile(
    r"Chapter\s+(Fourteen|Thirteen|Twelve|Eight|Eleven|Three|Seven|One|Two|Four|Five|Six|Nine|Ten|[0-9]+)\b",
    re.IGNORECASE,
)
WORD_TO_NUM = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
}


def _file_hash(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def _detect_page_chapter(text: str) -> int:
    m = CHAPTER_PATTERN.search(text)
    if not m:
        return 0
    word = m.group(1).lower()
    return WORD_TO_NUM.get(word, int(word) if word.isdigit() else 0)


def _clean_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _chunk_text(text: str) -> list[str]:
    text = _clean_text(text)
    chunks = []
    start = 0
    text_len = len(text)
    while start < text_len:
        end = min(start + CHUNK_SIZE, text_len)
        chunk = text[start:end]
        if end < text_len:
            best = max(chunk.rfind(". "), chunk.rfind("? "), chunk.rfind("! "))
            if best > CHUNK_SIZE * 0.5:
                chunk = chunk[: best + 1]
        chunk = chunk.strip()
        if len(chunk) > 80:
            chunks.append(chunk)
        step = max(len(chunk) - CHUNK_OVERLAP, 1)
        start += step
    return chunks


def _extract_pages(pdf_bytes: bytes) -> list[tuple[str, int, int]]:
    """Return list of (page_text, chapter_num, page_index)."""
    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    pages = []
    for i in range(len(doc)):
        text = doc[i].get_text("text")
        if text.strip():
            ch_num = _detect_page_chapter(text)
            pages.append((text, ch_num, i))
    doc.close()
    return pages


# ── Public API ────────────────────────────────────────────────────────────────

def delete_space_document(space_id: int, filename: str) -> int:
    """
    Remove all ChromaDB chunks for a specific document in a space.
    Returns the number of IDs deleted.
    """
    col = _get_collection()
    results = col.get(
        where={"$and": [{"space_id": str(space_id)}, {"source": filename}]},
        include=[],
    )
    ids = results.get("ids", [])
    if ids:
        col.delete(ids=ids)
    return len(ids)


def delete_space_all_documents(space_id: int) -> int:
    """Remove all ChromaDB chunks for an entire space."""
    col = _get_collection()
    results = col.get(
        where={"space_id": str(space_id)},
        include=[],
    )
    ids = results.get("ids", [])
    if ids:
        col.delete(ids=ids)
    return len(ids)


def ingest_space_document(
    space_id: int,
    filename: str,
    pdf_bytes: bytes,
    subject: str | None = None,
    class_level: str | None = None,
) -> dict:
    """
    Ingest a PDF into ChromaDB scoped to a space_id.

    Args:
        space_id:    The numeric space ID (stored as string in metadata)
        filename:    Original filename (used as source metadata + dedup key)
        pdf_bytes:   Raw PDF bytes
        subject:     Optional subject hint stored in metadata
        class_level: Optional class level stored in metadata

    Returns:
        {"chunks_added": int, "pages": int, "file_hash": str}
    """
    col = _get_collection()
    model = _get_model()

    md5 = _file_hash(pdf_bytes)

    # Remove any existing chunks for this exact file in this space
    # (handles re-upload / replacement)
    existing = col.get(
        where={"$and": [{"space_id": str(space_id)}, {"file_hash": md5}]},
        include=[],
    )
    if existing.get("ids"):
        col.delete(ids=existing["ids"])

    # Extract text pages
    pages = _extract_pages(pdf_bytes)
    if not pages:
        return {"chunks_added": 0, "pages": 0, "file_hash": md5}

    stem = Path(filename).stem

    all_chunks: list[str] = []
    all_ids: list[str] = []
    all_metas: list[dict] = []
    chunk_counter = 0

    for page_text, ch_num, pdf_page_idx in pages:
        chunks = _chunk_text(page_text)
        for chunk_i, chunk in enumerate(chunks):
            chunk_id = f"space{space_id}_{stem}_p{pdf_page_idx}_c{chunk_i}_ch{ch_num}"
            all_chunks.append(chunk)
            all_ids.append(chunk_id)
            all_metas.append(
                {
                    # Space scope — primary filter key
                    "space_id": str(space_id),
                    # Optional curriculum metadata (may be empty string)
                    "subject": (subject or "").lower(),
                    "class": str(class_level or ""),
                    "chapter": str(ch_num),
                    "page": pdf_page_idx + 1,
                    "source": filename,
                    "file_hash": md5,
                    "chunk_index": chunk_counter,
                }
            )
            chunk_counter += 1

    if not all_chunks:
        return {"chunks_added": 0, "pages": len(pages), "file_hash": md5}

    # Embed in batches
    embeddings_list = []
    for i in range(0, len(all_chunks), EMBED_BATCH):
        batch = all_chunks[i: i + EMBED_BATCH]
        vecs = np.array(list(model.embed(batch)))
        embeddings_list.append(vecs)
    embeddings = np.vstack(embeddings_list)

    # Store in ChromaDB
    MAX_BATCH = 5000
    for i in range(0, len(all_chunks), MAX_BATCH):
        end = min(i + MAX_BATCH, len(all_chunks))
        col.upsert(
            ids=all_ids[i:end],
            documents=all_chunks[i:end],
            embeddings=embeddings[i:end].tolist(),
            metadatas=all_metas[i:end],
        )

    return {
        "chunks_added": len(all_chunks),
        "pages": len(pages),
        "file_hash": md5,
    }


def retrieve_space_context(
    query: str,
    space_id: int,
    n_results: int = 5,
) -> str:
    """
    Retrieve and assemble RAG context scoped strictly to a space_id.
    Returns a formatted context string ready for the Gemini prompt.
    """
    col = _get_collection()
    total = col.count()
    if total == 0:
        return ""

    from fastembed import TextEmbedding as _TE
    _model = _get_model()
    query_embedding = list(_model.embed([query]))[0].tolist()

    results = col.query(
        query_embeddings=[query_embedding],
        n_results=min(n_results, total),
        where={"space_id": str(space_id)},
        include=["documents", "metadatas", "distances"],
    )

    docs = results["documents"][0] if results and results["documents"] else []
    metas = results["metadatas"][0] if results and results["metadatas"] else []

    if not docs:
        return ""

    parts = []
    for i, (doc, meta) in enumerate(zip(docs, metas), 1):
        source = meta.get("source", "document")
        chapter = meta.get("chapter", "")
        page = meta.get("page", "")
        label_parts = [f"Source: {source}"]
        if chapter and chapter != "0":
            label_parts.append(f"Ch.{chapter}")
        if page:
            label_parts.append(f"p.{page}")
        parts.append(f"[{' | '.join(label_parts)}]\n{doc}")

    return "\n\n".join(parts)