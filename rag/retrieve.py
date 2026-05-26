"""
retrieve.py — fast retrieval from ChromaDB
"""

from pathlib import Path
from typing import Optional

import chromadb
from sentence_transformers import SentenceTransformer

# Resolve relative to the repo root (rag/ is a package), so retrieval works
# regardless of the directory uvicorn is launched from.
CHROMA_DB_PATH = str(Path(__file__).resolve().parent.parent / "chroma_db")
COLLECTION_NAME = "nctb_curriculum"

# MUST MATCH INGEST MODEL
EMBED_MODEL = "paraphrase-multilingual-MiniLM-L12-v2"


# ─────────────────────────────────────────────────────────────
# LOAD MODEL
# ─────────────────────────────────────────────────────────────

model = SentenceTransformer(EMBED_MODEL)


# ─────────────────────────────────────────────────────────────
# CHROMA
# ─────────────────────────────────────────────────────────────


def get_collection():

    client = chromadb.PersistentClient(path=CHROMA_DB_PATH)

    return client.get_collection(COLLECTION_NAME)


def retrieve_context(
    query: str,
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
    n_results: int = 3,
) -> list[dict]:

    collection = get_collection()

    total = collection.count()

    if total == 0:
        return []

    query_embedding = model.encode(query, normalize_embeddings=True).tolist()

    where = None

    if subject and class_level:
        where = {"$and": [{"subject": subject}, {"class": class_level}]}

    elif subject:
        where = {"subject": subject}

    elif class_level:
        where = {"class": class_level}

    kwargs = {
        "query_embeddings": [query_embedding],
        "n_results": min(n_results, total),
        "include": ["documents", "metadatas", "distances"],
    }

    if where:
        kwargs["where"] = where

    results = collection.query(**kwargs)

    output = []

    docs = results["documents"][0]
    metas = results["metadatas"][0]
    dists = results["distances"][0]

    for doc, meta, dist in zip(docs, metas, dists):

        output.append(
            {
                "text": doc,
                "subject": meta.get("subject", ""),
                "class": meta.get("class", ""),
                "chapter": meta.get("chapter", ""),
                "source": meta.get("source", ""),
                "distance": round(float(dist), 4),
            }
        )

    return output


def build_rag_context(
    query: str,
    subject: Optional[str] = None,
    class_level: Optional[str] = None,
) -> str:

    chunks = retrieve_context(
        query,
        subject=subject,
        class_level=class_level,
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
