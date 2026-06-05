"""
retrieve.py — fast retrieval from ChromaDB
"""

from pathlib import Path
from typing import Optional

import chromadb
from fastembed import TextEmbedding

# Resolve relative to the repo root (rag/ is a package), so retrieval works
# regardless of the directory uvicorn is launched from.
CHROMA_DB_PATH = str(Path(__file__).resolve().parent.parent / "chroma_db")
COLLECTION_NAME = "nctb_curriculum"

# MUST MATCH INGEST MODEL
EMBED_MODEL = "BAAI/bge-small-en-v1.5"


# ─────────────────────────────────────────────────────────────
# LOAD MODEL
# ─────────────────────────────────────────────────────────────

model = TextEmbedding(model_name=EMBED_MODEL)


# ─────────────────────────────────────────────────────────────
# CHROMA
# ─────────────────────────────────────────────────────────────


def get_collection():

    client = chromadb.PersistentClient(path=CHROMA_DB_PATH)

    return client.get_or_create_collection(COLLECTION_NAME)


def retrieve_context(
    query: str,
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
    chapter: Optional[str] = None,
    topic: Optional[str] = None,
    n_results: int = 3,
) -> list[dict]:
    """
    Retrieve context from ChromaDB with optional chapter and topic filtering.
    """

    collection = get_collection()

    total = collection.count()

    if total == 0:
        return []

    query_embedding = list(model.embed([query]))[0].tolist()

    where_clauses = []

    if subject:
        where_clauses.append({"subject": subject.lower()})
    if class_level:
        where_clauses.append({"class": str(class_level)})
    if chapter:
        where_clauses.append({"chapter": chapter})
    if topic:
        where_clauses.append({"topic": topic})

    if len(where_clauses) == 1:
        where = where_clauses[0]
    elif len(where_clauses) > 1:
        where = {"$and": where_clauses}
    else:
        where = None

    kwargs = {
        "query_embeddings": [query_embedding],
        "n_results": min(n_results, total),
        "include": ["documents", "metadatas", "distances"],
    }

    if where:
        kwargs["where"] = where

    results = collection.query(**kwargs)

    # Fallback: if no results with chapter/topic filters, retry without them
    docs = results["documents"][0] if results and results["documents"] else []
    if not docs and (chapter or topic):
        fallback_clauses = []
        if subject:
            fallback_clauses.append({"subject": subject.lower()})
        if class_level:
            fallback_clauses.append({"class": str(class_level)})

        if len(fallback_clauses) == 1:
            kwargs["where"] = fallback_clauses[0]
        elif len(fallback_clauses) > 1:
            kwargs["where"] = {"$and": fallback_clauses}
        else:
            kwargs.pop("where", None)

        results = collection.query(**kwargs)

    output = []

    docs = results["documents"][0] if results and results["documents"] else []
    metas = results["metadatas"][0] if results and results["metadatas"] else []
    dists = results["distances"][0] if results and results["distances"] else []

    for doc, meta, dist in zip(docs, metas, dists):
        output.append(
            {
                "text": doc,
                "subject": meta.get("subject", ""),
                "class": meta.get("class", ""),
                "chapter": meta.get("chapter", ""),
                "topic": meta.get("topic", ""),
                "source": meta.get("source", ""),
                "distance": round(float(dist), 4),
            }
        )

    return output


def build_rag_context(
    query: str,
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
    chapter: Optional[str] = None,
    topic: Optional[str] = None,
) -> str:

    chunks = retrieve_context(
        query,
        subject=subject,
        class_level=class_level,
        chapter=chapter,
        topic=topic,
    )

    if not chunks:
        return ""

    parts = []

    for i, c in enumerate(chunks, 1):
        parts.append(
            f"[Chunk {i} | "
            f"{c['subject'].title()} "
            f"Class {c['class']} "
            f"Ch.{c['chapter']}]\n"
            f"{c['text']}"
        )

    return "\n\n".join(parts)


def get_unique_chapters(
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
) -> list[dict]:
    """
    Retrieve all unique chapters from ChromaDB.
    Returns a list of dicts: [{"subject": "...", "chapter": "..."}]
    """
    collection = get_collection()
    total = collection.count()
    if total == 0:
        return []

    where_clauses = []
    if subject:
        where_clauses.append({"subject": subject.lower()})
    if class_level:
        where_clauses.append({"class": str(class_level)})

    kwargs = {"include": ["metadatas"]}
    if len(where_clauses) == 1:
        kwargs["where"] = where_clauses[0]
    elif len(where_clauses) > 1:
        kwargs["where"] = {"$and": where_clauses}

    results = collection.get(**kwargs)
    metas = results.get("metadatas", [])
    if not metas:
        return []

    seen = set()
    output = []
    for meta in metas:
        subj = meta.get("subject", "").lower()
        chap = meta.get("chapter", "")
        if not subj or not chap:
            continue
        key = (subj, chap)
        if key not in seen:
            seen.add(key)
            output.append({"subject": subj, "chapter": chap})

    output.sort(key=lambda x: (x["subject"], x["chapter"]))
    return output
