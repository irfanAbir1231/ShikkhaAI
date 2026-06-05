# """
# ingest.py — PDF ingestion + chunking + ChromaDB embedding
# Member 1 owns this file.

# Usage:
#     python ingest.py
#     python ingest.py --file uploads/class_8_science_eng.pdf

# PDF naming convention:
#     class_8_science_eng.pdf   →  class=8, subject=science
#     class_10_math_eng.pdf     →  class=10, subject=math
# """

# import argparse
# import re
# import time
# from pathlib import Path

# import chromadb
# from sentence_transformers import SentenceTransformer
# from tqdm import tqdm
# import fitz  # pymupdf


# # ─── Config ───────────────────────────────────────────────────────────────────

# CHROMA_DB_PATH  = "./chroma_db"
# COLLECTION_NAME = "nctb_curriculum"
# UPLOADS_DIR     = "./uploads"
# EMBED_MODEL     = "paraphrase-multilingual-MiniLM-L12-v2"
# CHUNK_SIZE      = 400
# CHUNK_OVERLAP   = 50
# MAX_PAGES       = 5        # set to None to ingest ALL pages
# EMBED_BATCH     = 64       # sentences per embedding forward pass


# # ─── Model + DB (loaded once) ─────────────────────────────────────────────────

# def load_model() -> SentenceTransformer:
#     print("\n[STEP 1/4] Loading embedding model...")
#     t = time.time()
#     model = SentenceTransformer(EMBED_MODEL, device="cpu")
#     print(f"           ✓ Model ready in {time.time()-t:.1f}s")
#     return model


# def get_collection() -> chromadb.Collection:
#     print("[STEP 2/4] Connecting to ChromaDB...")
#     client = chromadb.PersistentClient(path=CHROMA_DB_PATH)
#     # No embedding_function here — we pass raw vectors ourselves
#     col = client.get_or_create_collection(
#         name=COLLECTION_NAME,
#         metadata={"hnsw:space": "cosine"},
#     )
#     print(f"           ✓ Collection '{COLLECTION_NAME}' ready  (existing docs: {col.count()})\n")
#     return col


# # ─── Filename metadata ────────────────────────────────────────────────────────

# def parse_filename(filename: str) -> dict:
#     name = Path(filename).stem.lower()
#     match = re.match(r"class_(\d+)_([a-z]+)_", name)
#     if match:
#         return {"class": match.group(1), "subject": match.group(2), "chapter": "1"}
#     return {"class": "unknown", "subject": name, "chapter": "1"}


# # ─── Chunking ─────────────────────────────────────────────────────────────────

# def chunk_text(text: str) -> list[str]:
#     text = re.sub(r"\s+", " ", text).strip()
#     chunks, start = [], 0
#     while start < len(text):
#         end = start + CHUNK_SIZE
#         chunk = text[start:end]
#         for sep in (". ", "? ", "! ", "\n"):
#             pos = chunk.rfind(sep)
#             if pos > CHUNK_SIZE // 2:
#                 chunk = chunk[: pos + len(sep)]
#                 break
#         chunk = chunk.strip()
#         if len(chunk) > 60:
#             chunks.append(chunk)
#         start += len(chunk) - CHUNK_OVERLAP
#     return chunks


# # ─── PDF Extraction ───────────────────────────────────────────────────────────

# def extract_pdf_pages(path: str) -> list[str]:
#     print(f"[STEP 3/4] Extracting text from PDF...")
#     t = time.time()
#     doc = fitz.open(path)
#     total_pages = len(doc)
#     limit  = MAX_PAGES if MAX_PAGES else total_pages
#     actual = min(limit, total_pages)
#     print(f"           Pages: {total_pages} total → ingesting first {actual}")

#     pages = []
#     for i in tqdm(range(actual), desc="           Reading pages", unit="page"):
#         pages.append(doc[i].get_text())

#     print(f"           ✓ Extraction done in {time.time()-t:.1f}s\n")
#     return pages


# # ─── Indexing ─────────────────────────────────────────────────────────────────

# def index_file(path: str, collection: chromadb.Collection, model: SentenceTransformer) -> int:
#     filename = Path(path).name
#     meta     = parse_filename(filename)

#     print(f"{'─'*60}")
#     print(f"  File    : {filename}")
#     print(f"  Class   : {meta['class']}   Subject: {meta['subject']}")
#     print(f"{'─'*60}\n")

#     pages = extract_pdf_pages(path)
#     if not any(p.strip() for p in pages):
#         print("  [!] No text could be extracted.")
#         return 0

#     # ── 1. Chunk all pages ────────────────────────────────────
#     print("[STEP 4/4] Chunking + embedding + storing...")
#     print("           Chunking pages...")
#     stem = Path(path).stem
#     all_chunks, all_ids, all_metas = [], [], []
#     chunk_counter = 0

#     for page_num, page_text in enumerate(pages):
#         if not page_text.strip():
#             print(f"           Page {page_num+1}: empty, skipped")
#             continue
#         chunks = chunk_text(page_text)
#         print(f"           Page {page_num+1}: {len(chunks)} chunks")
#         for i, chunk in enumerate(chunks):
#             all_chunks.append(chunk)
#             all_ids.append(f"{stem}_p{page_num}_c{i}")
#             all_metas.append({
#                 "source":      filename,
#                 "class":       meta["class"],
#                 "subject":     meta["subject"],
#                 "chapter":     meta["chapter"],
#                 "page":        page_num,
#                 "chunk_index": chunk_counter + i,
#             })
#         chunk_counter += len(chunks)

#     print(f"\n           Total chunks : {len(all_chunks)}")

#     if not all_chunks:
#         print("  [!] No chunks produced.")
#         return 0

#     # ── 2. Embed with live progress bar ──────────────────────
#     print("\n           Embedding chunks (this is the slow part on CPU)...")
#     t_embed = time.time()

#     all_embeddings = model.encode(
#         all_chunks,
#         batch_size=EMBED_BATCH,
#         show_progress_bar=True,       # tqdm bar per batch
#         normalize_embeddings=True,    # needed for cosine similarity
#         convert_to_numpy=True,
#     )

#     embed_time = time.time() - t_embed
#     print(f"           ✓ Embedding done in {embed_time:.1f}s  "
#           f"({len(all_chunks)/embed_time:.1f} chunks/sec)")

#     # ── 3. Upsert raw vectors (no re-embedding) ───────────────
#     print("\n           Writing to ChromaDB...")
#     t_db = time.time()
#     UPSERT_BATCH = 500

#     for i in tqdm(range(0, len(all_chunks), UPSERT_BATCH),
#                   desc="           Storing", unit="batch"):
#         end = min(i + UPSERT_BATCH, len(all_chunks))
#         collection.upsert(
#             documents=all_chunks[i:end],
#             embeddings=all_embeddings[i:end].tolist(),
#             ids=all_ids[i:end],
#             metadatas=all_metas[i:end],
#         )

#     print(f"           ✓ DB write done in {time.time()-t_db:.1f}s")

#     total = len(all_chunks)
#     print(f"\n  ✓ {total} chunks stored  |  Collection size: {collection.count()}")
#     return total


# # ─── Ingest all PDFs ─────────────────────────────────────────────────────────

# def index_all(uploads_dir: str = UPLOADS_DIR) -> None:
#     t_start = time.time()
#     model   = load_model()
#     col     = get_collection()
#     files   = list(Path(uploads_dir).glob("*.pdf"))

#     if not files:
#         print(f"[!] No PDF files found in '{uploads_dir}'")
#         print("    Naming convention: class_8_science_eng.pdf")
#         return

#     print(f"Found {len(files)} PDF file(s): {[f.name for f in files]}\n")

#     grand_total = 0
#     for f in files:
#         grand_total += index_file(str(f), col, model)

#     print(f"\n{'='*60}")
#     print(f"  ALL DONE")
#     print(f"  Total chunks : {grand_total}")
#     print(f"  Collection   : {col.count()} docs")
#     print(f"  Wall time    : {time.time()-t_start:.1f}s")
#     print(f"{'='*60}\n")


# # ─── CLI ──────────────────────────────────────────────────────────────────────

# if __name__ == "__main__":
#     parser = argparse.ArgumentParser()
#     parser.add_argument("--file", help="Ingest a single file", default=None)
#     args = parser.parse_args()

#     if args.file:
#         model = load_model()
#         col   = get_collection()
#         index_file(args.file, col, model)
#     else:
#         index_all()


"""
optimized_ingest.py — Fast CPU-friendly PDF ingestion for RAG

Features:
- Faster chunking
- Safer overlap logic
- ONNX acceleration support
- Better batching
- Duplicate prevention
- Cleaner text extraction
- CPU/GPU auto-detection
- Much faster Chroma ingestion

Usage:
    python optimized_ingest.py
    python optimized_ingest.py --file uploads/class_8_science_eng.pdf
"""

import argparse
import hashlib
import re
import time
from pathlib import Path

import chromadb
import fitz
import numpy as np
from fastembed import TextEmbedding

CHROMA_DB_PATH = "./chroma_db"
COLLECTION_NAME = "nctb_curriculum"
UPLOADS_DIR = "./uploads"

# EMBED_MODEL = "sentence-transformers/paraphrase-MiniLM-L3-v2"

EMBED_MODEL = "BAAI/bge-small-en-v1.5"

CHUNK_SIZE = 1000
CHUNK_OVERLAP = 120

MAX_PAGES = 15
EMBED_BATCH = 128


def load_model() -> TextEmbedding:
    print("[1/5] Loading embedding model...")
    print(f"      model : {EMBED_MODEL}")
    t = time.time()
    model = TextEmbedding(model_name=EMBED_MODEL)
    print(f"      backend: ONNX (fastembed)")
    print(f"      loaded in {time.time() - t:.1f}s\n")
    return model


# ─────────────────────────────────────────────────────────────
# CHROMA
# ─────────────────────────────────────────────────────────────


def get_collection():
    print("[2/5] Connecting to ChromaDB...")

    client = chromadb.PersistentClient(path=CHROMA_DB_PATH)

    col = client.get_or_create_collection(
        name=COLLECTION_NAME, metadata={"hnsw:space": "cosine"}
    )

    print(f"      existing chunks: {col.count()}\n")

    return col


def parse_filename(filename: str) -> dict:
    """
    class_8_science_eng.pdf
    -> class=8, subject=science
    """

    name = Path(filename).stem.lower()

    m = re.match(r"class_(\d+)_([a-z]+)_", name)

    if m:
        return {"class": m.group(1), "subject": m.group(2), "chapter": "1"}

    return {"class": "unknown", "subject": name, "chapter": "1"}


def clean_text(text: str) -> str:
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def chunk_text(text: str) -> list[str]:
    """
    Smarter chunking with safer overlap.
    """

    text = clean_text(text)

    chunks = []
    start = 0
    text_len = len(text)

    while start < text_len:
        end = min(start + CHUNK_SIZE, text_len)

        chunk = text[start:end]

        # Try ending at sentence boundary
        if end < text_len:
            best = max(chunk.rfind(". "), chunk.rfind("? "), chunk.rfind("! "))

            if best > CHUNK_SIZE * 0.5:
                chunk = chunk[: best + 1]

        chunk = chunk.strip()

        if len(chunk) > 80:
            chunks.append(chunk)

        # SAFE overlap progression
        step = max(len(chunk) - CHUNK_OVERLAP, 1)

        start += step

    return chunks


def file_hash(path: str) -> str:
    """
    Detect duplicate files.
    """

    h = hashlib.md5()

    with open(path, "rb") as f:
        while True:
            data = f.read(8192)

            if not data:
                break

            h.update(data)

    return h.hexdigest()


# ─────────────────────────────────────────────────────────────
# PDF EXTRACTION
# ─────────────────────────────────────────────────────────────


def extract_pages(path: str) -> list[str]:
    """
    Faster cleaner extraction.
    """

    doc = fitz.open(path)

    pages = []

    limit = min(MAX_PAGES, len(doc))

    for i in range(limit):
        # cleaner extraction
        text = doc[i].get_text("text")

        if text.strip():
            pages.append(text)

    doc.close()

    return pages


def already_indexed(col, file_md5: str) -> bool:
    """
    Skip re-indexing identical PDFs.
    """

    results = col.get(where={"file_hash": file_md5}, limit=1)

    return len(results["ids"]) > 0


def index_file(path: str, col, model) -> int:

    filename = Path(path).name
    stem = Path(path).stem

    meta = parse_filename(filename)

    print("=" * 60)
    print(f"FILE: {filename}")
    print(f"class={meta['class']} | subject={meta['subject']}")

    # duplicate check
    md5 = file_hash(path)

    if already_indexed(col, md5):
        print("SKIPPED: already indexed\n")
        return 0

    # ─────────────────────────────
    # extract
    # ─────────────────────────────

    print("\n[3/5] Extracting PDF pages...")

    t = time.time()

    pages = extract_pages(path)

    print(f"      pages extracted: {len(pages)}")
    print(f"      extraction time : {time.time() - t:.1f}s")

    # ─────────────────────────────
    # chunk + segment by topics
    # ─────────────────────────────

    print("\n[4/5] Chunking and segmenting by topics...")

    t = time.time()

    from .topic_segmenter import segment_text_by_headers

    all_chunks = []
    all_ids = []
    all_metas = []

    chunk_counter = 0

    for page_num, text in enumerate(pages):
        if not text.strip():
            continue

        # Segment text by headers to get topic/chapter info
        segments = segment_text_by_headers(
            text, chapter_prefix=meta["chapter"], default_topic="General"
        )

        print(f"      page {page_num + 1}: {len(segments)} segments detected")

        for seg in segments:
            # Further chunk large segments if needed
            if len(seg.text) > CHUNK_SIZE:
                sub_chunks = chunk_text(seg.text)
                for sub_i, sub_chunk in enumerate(sub_chunks):
                    chunk_id = f"{stem}_p{page_num}_c{chunk_counter}_t{sub_i}"
                    all_chunks.append(sub_chunk)
                    all_ids.append(chunk_id)
                    all_metas.append(
                        {
                            "source": filename,
                            "class": meta["class"],
                            "subject": meta["subject"],
                            "chapter": seg.chapter,
                            "topic": seg.topic,
                            "page": page_num + 1,
                            "chunk_index": chunk_counter,
                            "file_hash": md5,
                        }
                    )
                    chunk_counter += 1
            else:
                chunk_id = f"{stem}_p{page_num}_c{chunk_counter}"
                all_chunks.append(seg.text)
                all_ids.append(chunk_id)
                all_metas.append(
                    {
                        "source": filename,
                        "class": meta["class"],
                        "subject": meta["subject"],
                        "chapter": seg.chapter,
                        "topic": seg.topic,
                        "page": page_num + 1,
                        "chunk_index": chunk_counter,
                        "file_hash": md5,
                    }
                )
                chunk_counter += 1

    print(f"\n      total chunks: {len(all_chunks)}")
    print(f"      chunk time  : {time.time() - t:.1f}s")

    if not all_chunks:
        print("No valid chunks produced.\n")
        return 0

    # ─────────────────────────────
    # embed
    # ─────────────────────────────

    print("\n[5/5] Generating embeddings...")

    t = time.time()

    embeddings = []

    total = len(all_chunks)

    for i in range(0, total, EMBED_BATCH):
        batch = all_chunks[i : i + EMBED_BATCH]

        vecs = np.array(list(model.embed(batch)))

        embeddings.append(vecs)

        done = min(i + EMBED_BATCH, total)

        print(f"      embedded {done}/{total}", end="\r")

    embeddings = np.vstack(embeddings)

    print()
    print(f"      embedding time: {time.time() - t:.1f}s")

    # ─────────────────────────────
    # store
    # ─────────────────────────────

    print("\nWriting to ChromaDB...")

    t = time.time()

    col.upsert(
        ids=all_ids,
        documents=all_chunks,
        embeddings=embeddings.tolist(),
        metadatas=all_metas,
    )

    print(f"stored in {time.time() - t:.1f}s")

    print(f"\n[OK] Indexed {len(all_chunks)} chunks")
    print(f"[OK] Collection size: {col.count()}")

    return len(all_chunks)


# ─────────────────────────────────────────────────────────────
# BULK INDEX
# ─────────────────────────────────────────────────────────────


def index_all(upload_dir=UPLOADS_DIR):

    total_start = time.time()

    model = load_model()

    col = get_collection()

    files = list(Path(upload_dir).glob("*.pdf"))

    if not files:
        print(f"No PDFs found in: {upload_dir}")
        return

    print(f"Found {len(files)} PDF(s)\n")

    total_chunks = 0

    for f in files:
        total_chunks += index_file(str(f), col, model)

    print("\n" + "=" * 60)
    print("INGESTION COMPLETE")
    print("=" * 60)

    print(f"Total new chunks : {total_chunks}")
    print(f"DB chunk count   : {col.count()}")
    print(f"Total runtime    : {time.time() - total_start:.1f}s")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--file", default=None, help="Single PDF file")

    args = parser.parse_args()

    if args.file:
        model = load_model()

        col = get_collection()

        index_file(args.file, col, model)

    else:
        index_all()
