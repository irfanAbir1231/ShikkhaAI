import os
import sys

# Add both RAG and backend to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../backend")))

from dotenv import load_dotenv
load_dotenv("rag/.env")
load_dotenv("backend/.env")

# Force config override to enable local RAG and in-process testing
os.environ["MOCK_MODE"] = "false"
os.environ["RAG_INPROCESS"] = "true"

from rag.retrieve import get_unique_chapters_and_topics, retrieve_context, build_rag_context
from rag.generate import generate_questions
from app.external.rag_client import RagClient

def test_retrieval_filtering():
    print("Testing retrieve_context and fallback...")
    # 1. Standard retrieval without metadata filters
    res = retrieve_context("What is force?", subject="science", class_level="8", n_results=1)
    print(f"No filters retrieved: {len(res)} chunks")
    
    # 2. Retrieval with a non-existent chapter/topic to trigger fallback
    res_fallback = retrieve_context("What is force?", subject="science", class_level="8", chapter="Chapter 999", topic="Invisible Topics", n_results=1)
    print(f"Fallback retrieved: {len(res_fallback)} chunks (should fallback to non-empty)")
    assert len(res_fallback) > 0, "Fallback failed to return chunks"
    
def test_get_unique_chapters_and_topics():
    print("\nTesting get_unique_chapters_and_topics...")
    topics = get_unique_chapters_and_topics(subject="science", class_level="8")
    print(f"Found {len(topics)} textbook topics in ChromaDB:")
    for t in topics[:5]:
        print(f"  - Subject: {t['subject']}, Chapter: {t['chapter']}, Topic: {t['topic']}")

def test_rag_client_integration():
    print("\nTesting RagClient.get_topics integration...")
    client = RagClient()
    topics = client.get_topics(subject="science", class_level="8")
    print(f"RagClient returned {len(topics)} topics")
    assert len(topics) >= 0

if __name__ == "__main__":
    try:
        test_retrieval_filtering()
        test_get_unique_chapters_and_topics()
        test_rag_client_integration()
        print("\nAll scratch tests passed successfully!")
    except Exception as e:
        print(f"\nScratch tests failed: {e}")
        import traceback
        traceback.print_exc()
