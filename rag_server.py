"""
rag_server.py — standalone RAG service.

Runs member1's RAG router as its own FastAPI app on its own (Python 3.11)
environment, separate from the backend. The backend talks to it over HTTP
via RAG_BASE_URL.

Run:
    cd <repo root>
    # in the RAG venv (see rag/requirements.txt):
    uvicorn rag_server:app --host 0.0.0.0 --port 8100

Then point the backend at it:
    RAG_BASE_URL=http://localhost:8100/rag
"""

from dotenv import load_dotenv

# Load rag/.env (GEMINI_API_KEY) before the router imports generate.py.
load_dotenv("rag/.env")

from fastapi import FastAPI  # noqa: E402

from rag.rag_router import router as rag_router  # noqa: E402

app = FastAPI(title="ShikkhaAI RAG Service", version="0.1.0")
app.include_router(rag_router, prefix="/rag")


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "rag"}
