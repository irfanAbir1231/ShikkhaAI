# ShikkhaAI Backend

FastAPI-based backend for ShikkhaAI exam generation and student profiling system.

## Quick Start

### Prerequisites
- Python 3.12+
- PostgreSQL 12+ (for production) or SQLite (for development)
- Gemini API key (optional, for exam generation)

### Local Development Setup

1. **Copy environment file**:
```bash
cp .env.example .env
```

2. **For quickest setup (SQLite)**:
Edit `.env` and set:
```dotenv
DATABASE_URL=sqlite:///./shikkhaai.db
MOCK_MODE=true
ENVIRONMENT=development
```

3. **For production-like setup (PostgreSQL)**:
```bash
docker compose up -d postgres
```

Keep `.env` with:
```dotenv
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai
MOCK_MODE=false
ENVIRONMENT=development
```

4. **Run the backend**:

From backend directory:
```bash
uv run uvicorn app.main:app --reload
```

Or from repository root:
```bash
uv --directory backend run uvicorn app.main:app --reload
```

5. **Access the API**:
- API: http://localhost:8000
- Docs: http://localhost:8000/docs (interactive Swagger UI)
- ReDoc: http://localhost:8000/redoc (alternative docs)

## Environment Variables

### Required
- `DATABASE_URL` - PostgreSQL connection string (production) or SQLite path (development)
- `GEMINI_API_KEY` - Gemini API key for exam generation (get from https://ai.google.dev)

### Optional
- `ENVIRONMENT` - `development`, `production`, or `testing` (default: development)
- `DEBUG` - Enable debug logging (default: true in development, false in production)
- `RAG_BASE_URL` - URL to RAG service for AI-powered exam generation
- `RAG_TIMEOUT_SECONDS` - Timeout for RAG requests (default: 60)
- `MOCK_MODE` - Use mock exam data instead of real generation (default: true in development)
- `CORS_ORIGINS` - Comma-separated list of allowed origins (default: localhost:3000,5173 in dev)

See `.env.example` for detailed documentation.

## Database

### Local Development
For quickest setup, use SQLite:
```bash
DATABASE_URL=sqlite:///./shikkhaai.db
```

### Local Production-like Setup
Run PostgreSQL via Docker:
```bash
docker compose up -d postgres
```

### Remote PostgreSQL
Set connection string:
```bash
DATABASE_URL=postgresql+psycopg2://user:password@host:5432/dbname
```

## Project Structure

```
backend/
├── app/
│   ├── api/              # API routes
│   │   ├── routes_students.py
│   │   └── routes_exams.py
│   ├── core/             # Configuration and core utilities
│   │   ├── config.py     # Settings with validation
│   │   ├── logging_config.py
│   │   └── responses.py  # Standard response schemas
│   ├── db/               # Database layer
│   │   ├── base.py
│   │   ├── models.py     # SQLAlchemy models
│   │   └── session.py    # Database session management
│   ├── schemas/          # Pydantic request/response models
│   ├── services/         # Business logic
│   ├── external/         # External service clients (RAG, Gemini)
│   ├── utils/            # Utility functions
│   └── main.py           # FastAPI application entry point
├── requirements.txt      # Python dependencies
├── .env.example          # Environment variables template
└── README.md             # This file
```

## API Endpoints

### Health & Status
- `GET /health` - Health check
- `GET /ready` - Readiness check (for orchestrators)

### Students
- `POST /student/register` - Register a new student
- `GET /student/{id}` - Get student profile

### Exams
- `POST /exam/generate` - Generate an exam
- `POST /exam/submit` - Submit exam answers

See Swagger UI at `/docs` for detailed endpoint documentation.

## Architecture

### Components
1. **FastAPI** - Async web framework
2. **SQLAlchemy** - ORM for database operations
3. **Pydantic** - Request/response validation
4. **Uvicorn** - ASGI server

### External Services
- **Gemini API** - AI-powered exam generation
- **RAG Service** - Optional context-aware exam generation
- **PostgreSQL** - Production database

### Data Models
- **Student** - Student profile and performance tracking
- **Exam** - Generated exams with questions and answer keys
- **Attempt** - Student exam submission and grading results
- **TopicPerformance** - Per-student topic performance metrics

## Development

### Running Tests
```bash
pytest
```

### Code Quality
```bash
ruff check .
ruff format .
```

### Type Checking
```bash
mypy app/
```

## Production Deployment

### Via Render (Recommended)
See [RENDER_DEPLOYMENT.md](../RENDER_DEPLOYMENT.md) for step-by-step guide.

Key points:
- PostgreSQL database required
- Set `ENVIRONMENT=production`
- Set specific `CORS_ORIGINS` (no wildcards)
- Enable `GEMINI_API_KEY` or `RAG_BASE_URL`
- Disable `DEBUG` and `MOCK_MODE`

### Via Docker
```bash
docker build -t shikkhaai-backend .
docker run -p 8000:8000 -e DATABASE_URL=postgresql://... shikkhaai-backend
```

### Configuration Checklist
- [ ] `ENVIRONMENT=production`
- [ ] `DATABASE_URL` points to PostgreSQL (not SQLite)
- [ ] `CORS_ORIGINS` set to specific domains
- [ ] `GEMINI_API_KEY` is set and valid
- [ ] `MOCK_MODE=false`
- [ ] `DEBUG=false`
- [ ] Database is initialized and accessible
- [ ] All dependencies installed

## Common Issues

### "DATABASE_URL is required"
Missing or empty DATABASE_URL environment variable. Set it in `.env` or environment.

### "CORS_ORIGINS cannot be '*' in production"
Production mode doesn't allow wildcard CORS. Set specific domain: `CORS_ORIGINS=https://example.com`

### "GEMINI_API_KEY or RAG_BASE_URL must be set"
One of these is required for exam generation. Get Gemini key from https://ai.google.dev

### "Too many connections" database error
Increase connection pool size or reduce number of workers. Check `max_overflow` in `session.py`.

### Slow startup with SQLite
SQLite is only for development. Use PostgreSQL for production.

## Performance Tips

1. **Use PostgreSQL** - SQLite not suitable for concurrent requests
2. **Enable connection pooling** - Configured automatically in `session.py`
3. **Use uvloop** - Faster event loop (included in Procfile)
4. **Configure multiple workers** - 4+ in production (set in Procfile)
5. **Add caching** - Consider Redis for frequently accessed data
6. **Monitor logs** - Set `DEBUG=true` temporarily to diagnose slowness

## Monitoring & Logs

### Logs Location
- Development: Console output
- Production (Render): Service logs dashboard

### Important Log Messages
- `Database initialized successfully` - DB setup complete
- `ERROR` - Application errors
- `WARNING` - Potential issues to investigate

### Health Monitoring
```bash
# Periodic health checks
curl https://your-service.onrender.com/health
```

## Support & Resources

- **Documentation**: https://fastapi.tiangolo.com
- **Database**: https://sqlalchemy.org
- **Deployment**: See RENDER_DEPLOYMENT.md
- **API Schema**: Visit `/docs` or `/redoc` endpoints

## License

See LICENSE file in repository root.
