ShikkhaAI FastAPI backend.

## Local setup

The backend needs a database during application startup because `init_db()`
creates the SQLAlchemy tables.

For the quickest local run, copy the example environment file and use SQLite:

```powershell
Copy-Item .env.example .env
```

Then set this in `.env`:

```dotenv
DATABASE_URL=sqlite:///./shikkhaai.db
```

Run the API from this directory with:

```bash
uv run uvicorn app.main:app --reload
```

From the repository root, use:

```bash
uv --directory backend run uvicorn app.main:app --reload
```

## Local Postgres

To use the default Postgres URL instead, start the bundled Compose service from
the repository root:

```powershell
docker compose up -d postgres
```

Keep this value in `backend/.env`:

```dotenv
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/shikkhaai
```
