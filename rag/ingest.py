"""
ingest.py — PDF ingestion + chunking + ChromaDB embedding

Usage:
    python ingest.py
    python ingest.py --file uploads/class_8_science_eng.pdf

PDF naming convention:
    class_8_science_eng.pdf   →  class=8, subject=science
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

EMBED_MODEL = "BAAI/bge-small-en-v1.5"

CHUNK_SIZE = 1000
CHUNK_OVERLAP = 120

EMBED_BATCH = 128

# ─────────────────────────────────────────────────────────────
# CHAPTER DETECTION
# ─────────────────────────────────────────────────────────────

CHAPTER_PATTERN = re.compile(
    r"Chapter\s+(Fourteen|Thirteen|Twelve|Eight|Eleven|Three|Seven|One|Two|Four|Five|Six|Nine|Ten|[0-9]+)\b",
    re.IGNORECASE,
)

WORD_TO_NUM = {
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
    "thirteen": 13,
    "fourteen": 14,
}

# Only ingest these chapters (set to None for all)
CHAPTERS_TO_INGEST = None


def detect_chapters(path: str) -> list[dict]:
    """
    Scan PDF and return list of chapter dicts:
    {start_page, end_page, chapter_num, chapter_title}
    """
    doc = fitz.open(path)
    starts = []

    for i in range(len(doc)):
        text = doc[i].get_text("text")
        m = CHAPTER_PATTERN.search(text)
        if m:
            word = m.group(1).lower()
            num = WORD_TO_NUM.get(word, int(word) if word.isdigit() else 0)
            after = text[m.end() : m.end() + 200]
            title_lines = [l.strip() for l in after.split("\n") if l.strip()]
            title = title_lines[0] if title_lines else ""
            starts.append((i, num, title))

    chapters = []
    for idx, (start, num, title) in enumerate(starts):
        end = starts[idx + 1][0] - 1 if idx + 1 < len(starts) else len(doc) - 1
        chapters.append(
            {
                "start_page": start,
                "end_page": end,
                "chapter_num": num,
                "chapter_title": title,
            }
        )

    doc.close()

    return chapters


# ─────────────────────────────────────────────────────────────
# MODEL + DB
# ─────────────────────────────────────────────────────────────


def load_model() -> TextEmbedding:
    print("[1/5] Loading embedding model...")
    print(f"      model : {EMBED_MODEL}")
    t = time.time()
    model = TextEmbedding(model_name=EMBED_MODEL)
    print(f"      backend: ONNX (fastembed)")
    print(f"      loaded in {time.time() - t:.1f}s\n")
    return model


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
        return {"class": m.group(1), "subject": m.group(2)}

    return {"class": "unknown", "subject": name}


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

        # The final chunk must terminate the loop. Without this guard, a
        # short tail (shorter than CHUNK_OVERLAP) advances by one character
        # at a time and can explode one page into hundreds of duplicates.
        if end >= text_len:
            break

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


def extract_pages(path: str, chapter_filter: set[int] | None = None) -> list[tuple[str, int, int]]:
    """
    Extract text from PDF pages, optionally filtering by chapter.
    Returns list of (text, chapter_num, pdf_page_index).
    """

    doc = fitz.open(path)
    chapters = detect_chapters(path)

    # Build page -> chapter lookup
    page_chapter = {}
    for ch in chapters:
        for p in range(ch["start_page"], ch["end_page"] + 1):
            page_chapter[p] = ch["chapter_num"]

    pages = []

    for i in range(len(doc)):
        ch_num = page_chapter.get(i)

        if chapter_filter is not None and ch_num not in chapter_filter:
            continue

        text = doc[i].get_text("text")

        # Pages before the first detected chapter are normally the table of
        # contents/front matter. Excluding them prevents generic TOC chunks
        # from outranking real curriculum content during retrieval.
        if text.strip() and ch_num is not None and ch_num > 0:
            pages.append((text, ch_num, i))

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

    print("\n[3/5] Detecting chapters & extracting PDF pages...")

    t = time.time()

    pages = extract_pages(path, chapter_filter=CHAPTERS_TO_INGEST)

    if not pages:
        print("      No pages matched the chapter filter.\n")
        return 0

    chapter_counts = {}
    for _, ch_num, _ in pages:
        chapter_counts[ch_num] = chapter_counts.get(ch_num, 0) + 1

    print(f"      pages extracted: {len(pages)}")
    print(f"      chapters: {dict(sorted(chapter_counts.items()))}")
    print(f"      extraction time : {time.time() - t:.1f}s")

    # ─────────────────────────────
    # chunk + segment by topics
    # ─────────────────────────────

    print("\n[4/5] Chunking text...")

    t = time.time()

    all_chunks = []
    all_ids = []
    all_metas = []

    chunk_counter = 0

    for page_text, ch_num, pdf_page_idx in pages:

        chunks = chunk_text(page_text)

        print(f"      page {pdf_page_idx}: ch={ch_num} | {len(chunks)} chunks")

        for chunk_i, chunk in enumerate(chunks):

            chunk_id = f"{stem}_p{pdf_page_idx}_c{chunk_i}_ch{ch_num}"

            all_chunks.append(chunk)

            all_ids.append(chunk_id)

            all_metas.append(
                {
                    "source": filename,
                    "class": meta["class"],
                    "subject": meta["subject"],
                    "chapter": str(ch_num),
                    "page": pdf_page_idx + 1,
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

    MAX_BATCH = 5000
    total = len(all_chunks)
    for i in range(0, total, MAX_BATCH):
        end = min(i + MAX_BATCH, total)
        col.upsert(
            ids=all_ids[i:end],
            documents=all_chunks[i:end],
            embeddings=embeddings[i:end].tolist(),
            metadatas=all_metas[i:end],
        )
        print(f"      stored {end}/{total}", end="\r")

    print()
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
