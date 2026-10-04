# Personal Finance AI — Backend Service

FastAPI-powered RESTful API with PostgreSQL, SQLAlchemy 2.0, Alembic migrations, and JWT authentication.

---

## Tech Stack
- **Framework:** FastAPI 0.115.0
- **ASGI Server:** Uvicorn 0.31.0
- **Database Engine & ORM:** SQLAlchemy 2.0.35 + psycopg 3.2.3 (PostgreSQL) / SQLite (Test/Dev)
- **Migrations:** Alembic 1.13.3
- **Validation & Serialization:** Pydantic v2.9.2 & pydantic-settings 2.5.2
- **Authentication:** Bcrypt password hashing + PyJWT HS256 tokens
- **Testing:** Pytest 8.3.3 + pytest-asyncio + HTTPX TestClient

---

## Quickstart

### 1. Virtual Environment & Dependencies
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Key configuration items:
- `DATABASE_URL`: `postgresql://finance:finance_dev_pw@localhost:5432/finance_db` or `sqlite:///./finance_dev.db`
- `JWT_SECRET_KEY`: Set to a strong random 32-byte secret (e.g. via `openssl rand -hex 32`)
- `GEMINI_API_KEY`: Google Gemini API key (optional; system runs in degraded mode if unset)

### 3. Database Migrations
Run Alembic migrations to build or upgrade the schema:
```bash
alembic upgrade head
```
To rollback:
```bash
alembic downgrade base
```

### 4. Running the Development Server
```bash
uvicorn app.main:app --reload --port 8000
```
Interactive API docs:
- **Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc:** [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

## Testing & Cross-User Security Verification

Run all unit, integration, and security isolation tests:
```bash
pytest tests/ -v
```

The test suite validates:
- **Auth:** Signup password strength, duplicate email prevention, JSON & OAuth2 password form login, token refresh, and logout.
- **Transactions CRUD:** Positive amount validation, type constraints, pagination (`skip`/`limit`), category & date filtering, search query matching.
- **Budgets:** Limit validation, duplicate category prevention per month, spent amount aggregation from actual expense transactions, and 80% warning / 100% exceeded thresholds.
- **Cross-User Isolation:** Ensures user A cannot read, modify, or delete user B's records, returning strict `404 Not Found` (never `403 Forbidden`) to prevent resource existence leakage.
