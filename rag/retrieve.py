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

    Args:
        query: Search query
        subject: Subject filter
        class_level: Class level filter
        chapter: Optional chapter name to filter results
        topic: Optional topic name to filter results
        n_results: Number of results to return
    """
    collection = get_collection()

    total = collection.count()

    if total == 0:
        return []

    query_embedding = list(model.embed([query]))[0].tolist()

    where = None

    if subject and class_level:
        where = {"$and": [{"subject": subject.lower()}, {"class": str(class_level)}]}

    elif subject:
        where = {"subject": subject.lower()}

    elif class_level:
        where = {"class": str(class_level)}

    # Add chapter filter if provided
    if chapter:
        if where:
            where = {"$and": [where, {"chapter": chapter}]}
        else:
            where = {"chapter": chapter}

    # Add topic filter if provided
    if topic:
        if where:
            where = {"$and": [where, {"topic": topic}]}
        else:
            where = {"topic": topic}

    kwargs = {
        "query_embeddings": [query_embedding],
        "n_results": min(n_results, total),
        "include": ["documents", "metadatas", "distances"],
    }

    if where:
        kwargs["where"] = where

    results = collection.query(**kwargs)

    # Fallback logic: if no results and we filtered by chapter or topic, try querying without chapter/topic filters
    docs = results["documents"][0] if results and results["documents"] else []
    if not docs and (chapter or topic):
        fallback_where = None
        if subject and class_level:
            fallback_where = {"$and": [{"subject": subject.lower()}, {"class": str(class_level)}]}
        elif subject:
            fallback_where = {"subject": subject.lower()}
        elif class_level:
            fallback_where = {"class": str(class_level)}

        if fallback_where:
            kwargs["where"] = fallback_where
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
    """
    Build RAG context string from retrieved chunks with optional chapter/topic filtering.
    """
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
            f"Ch.{c['chapter']} "
            f"Topic:{c['topic']}]\n"
            f"{c['text']}"
        )

    return "\n\n".join(parts)


def get_unique_chapters_and_topics(
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
) -> list[dict]:
    """
    Retrieve all unique chapters and topics from ChromaDB.
    Returns a list of dicts: [{"subject": "...", "chapter": "...", "topic": "..."}]
    """
    collection = get_collection()
    total = collection.count()
    if total == 0:
        return []

    # Get all metadatas
    where = None
    if subject and class_level:
        where = {"$and": [{"subject": subject.lower()}, {"class": str(class_level)}]}
    elif subject:
        where = {"subject": subject.lower()}
    elif class_level:
        where = {"class": str(class_level)}

    kwargs = {"include": ["metadatas"]}
    if where:
        kwargs["where"] = where

    results = collection.get(**kwargs)
    metas = results.get("metadatas", [])
    if not metas:
        return []

    seen = set()
    output = []
    for meta in metas:
        subj = meta.get("subject", "").lower()
        chap = meta.get("chapter", "")
        top = meta.get("topic", "")
        if not subj or not chap or not top:
            continue
        key = (subj, chap, top)
        if key not in seen:
            seen.add(key)
            output.append({
                "subject": subj,
                "chapter": chap,
                "topic": top
            })

    output.sort(key=lambda x: (x["subject"], x["chapter"], x["topic"]))
    return output
