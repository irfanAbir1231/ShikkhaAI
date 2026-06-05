"""
topic_segmenter.py — Chapter and topic extraction from textbook text

This module segments textbook content into logical chapters and topics
based on headers, section markers, and content patterns.
"""

import re
from typing import NamedTuple


class TopicChunk(NamedTuple):
    """A chunk of text with its detected topic/chapter."""

    topic: str
    chapter: str
    text: str
    page: int | None = None


# Common section header patterns in textbooks
CHAPTER_PATTERNS = [
    r"(?i)^([Cc]hapter\s*\d+[\.\-\s]+.+)$",
    r"(?i)^(unit\s*\d+[\.\-\s]+.+)$",
    r"(?i)^(lesson\s*\d+[\.\-\s]+.+)$",
]

TOPIC_PATTERNS = [
    r"(?i)^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)$",  # Title case headings
    r"(?i)^(\d+\.\s+[A-Z][a-z]+.*)$",  # Numbered sections like "1. Introduction"
    r"(?i)^(Key Concepts?|Summary|Exercise|Questions?)$",  # Standard sections
]


def detect_chapter_header(line: str) -> str | None:
    """Detect if a line is a chapter header."""
    for pattern in CHAPTER_PATTERNS:
        match = re.match(pattern, line.strip())
        if match:
            return match.group(1).strip()
    return None


def detect_topic_header(line: str) -> str | None:
    """Detect if a line is a topic/section header."""
    # Skip very short lines or pure punctuation
    stripped = line.strip()
    if len(stripped) < 5 or len(stripped) > 100:
        return None

    # Check topic patterns
    for pattern in TOPIC_PATTERNS:
        match = re.match(pattern, stripped)
        if match:
            return match.group(1).strip()

    # Alternative: lines that are clearly section headings
    # (all caps, or title case with specific keywords)
    keywords = [
        "introduction",
        "overview",
        "concept",
        "theory",
        "principle",
        "definition",
        "example",
        "application",
        "calculation",
        "problem",
        "diagram",
        "experiment",
        "observation",
        "fact",
        "law",
        "rule",
    ]

    # Title case with lowercase words check
    if re.match(r"^[A-Z][a-z]+(?:\s+[a-z]+)*$", stripped):
        # Has some lowercase words (not all caps), likely a section header
        return stripped

    return None


def segment_text_by_headers(
    text: str,
    chapter_prefix: str | None = None,
    default_topic: str = "General",
) -> list[TopicChunk]:
    """
    Segment text into topics based on header detection.

    Args:
        text: Raw textbook text
        chapter_prefix: Optional prefix to prepend to chapter names
        default_topic: Fallback topic name when none detected

    Returns:
        List of TopicChunk objects
    """
    lines = text.splitlines()

    chunks: list[TopicChunk] = []
    current_chapter = chapter_prefix or "Chapter 1"
    current_topic = default_topic
    chunk_lines: list[str] = []

    def flush_chunk():
        if chunk_lines:
            chunk_text = "\n".join(chunk_lines).strip()
            if len(chunk_text) > 50:  # Minimum content threshold
                chunks.append(
                    TopicChunk(
                        topic=current_topic,
                        chapter=current_chapter,
                        text=chunk_text,
                    )
                )
            chunk_lines.clear()

    for line in lines:
        # Empty line - might end a chunk
        if not line.strip():
            if chunk_lines:
                flush_chunk()
            continue

        # Check for chapter header
        chapter_match = detect_chapter_header(line)
        if chapter_match:
            flush_chunk()
            current_chapter = chapter_match
            current_topic = default_topic
            continue

        # Check for topic header
        topic_match = detect_topic_header(line)
        if topic_match and len(chunk_lines) > 10:  # Only switch if we have content
            flush_chunk()
            current_topic = topic_match
            chunk_lines.append(line.strip())
            continue

        # Regular content line
        chunk_lines.append(line)

    # Flush remaining content
    flush_chunk()

    return chunks


def segment_page_text(
    page_text: str,
    page_num: int,
    chapter_prefix: str | None = None,
) -> list[TopicChunk]:
    """
    Segment text from a single page, with page number tracking.
    """
    # Normalize whitespace
    text = re.sub(r"\s+", " ", page_text.strip())

    # Try to find sections
    return segment_text_by_headers(
        text,
        chapter_prefix=chapter_prefix,
        default_topic="Page Content",
    )


def estimate_topic_count(text: str, avg_chunk_size: int = 500) -> int:
    """Estimate how many topics/chunks the text will produce."""
    clean_text = re.sub(r"\s+", " ", text).strip()
    if not clean_text:
        return 0
    # Rough estimate based on length and section markers
    section_markers = len(re.findall(r"^[A-Z].*:$", clean_text, re.MULTILINE))
    word_count = len(clean_text.split())
    return max(1, min(section_markers + 1, word_count // avg_chunk_size))


def clean_chunk_text(text: str) -> str:
    """Clean up a chunk's text for embedding."""
    # Remove excessive whitespace
    text = re.sub(r"\s+", " ", text)
    # Remove standalone numbers (likely page numbers)
    text = re.sub(r"\b\d+\b(?=\s|$)", "", text)
    return text.strip()
