# ShikkhaAI

AI-powered education system with a FastAPI backend and Flutter frontend.

## Project Structure

```
shikkhaai-backend/
  backend/        # FastAPI backend (students, exams, grading)
  rag/            # RAG service integration
  frontend/       # Flutter app (mobile/web)
  docker-compose.yml
```

## Quick Start

### Backend
```bash
cd backend
uv sync
uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
flutter run
```
