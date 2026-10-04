# Personal Finance AI — Smart Money Management App

> Intelligent, bank-grade personal finance co-pilot tailored for India. Built with Flutter, FastAPI, PostgreSQL, and Google Gemini AI.

---

## Overview

**Personal Finance AI** is an end-to-end financial intelligence platform designed to help users track cash flows, manage monthly category budgets, achieve savings goals, and consult an AI financial assistant strictly grounded in real ledger data.

- **Frontend:** Single-codebase Flutter application supporting Web, Android, and iOS with responsive layouts (Desktop sidebar, mobile bottom navigation, tablet adaptive) styled strictly according to Google Stitch specifications.
- **Backend:** High-performance Python FastAPI service with strict per-user authorization, JWT authentication (access + refresh tokens), and transactional ledger integrity.
- **Database:** PostgreSQL (with SQLite support for lightweight local development), structured relational schemas, compound indices, and Alembic migrations.
- **AI Intelligence:** Context-grounded Gemini 2.5 Flash assistant via a secure backend proxy. All arithmetic (balances, category shares, budget headroom, savings rates, MoM trends) is pre-calculated deterministically in Python before invoking Gemini.
- **Localization:** All figures formatted in Indian Rupee (₹) using Indian numbering conventions (Lakhs and Crores).

---

## Architecture

```text
┌────────────────────────────────────────────────────────┐
│                   Flutter Client                       │
│    (Web, Android, iOS — Riverpod, GoRouter, fl_chart)  │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / Bearer JWT
                            ▼
┌────────────────────────────────────────────────────────┐
│                 FastAPI Backend                        │
│ ┌───────────────┬───────────────────┬────────────────┐ │
│ │  Auth & Users │ Ledger & Budgets  │  Reports & CSV │ │
│ └───────────────┴───────────────────┴────────────────┘ │
│                           │                            │
│                           ▼                            │
│           Deterministic Python Grounding Engine        │
│    (Sums, MoM deltas, category shares, budget checks)  │
│                           │                            │
│                           ▼                            │
│                   Google Gemini SDK                    │
│           (gemini-2.5-flash with Grounding Rules)      │
└───────────────────────────┬────────────────────────────┘
                            │ SQLAlchemy 2.0 / Alembic
                            ▼
┌────────────────────────────────────────────────────────┐
│             PostgreSQL / SQLite Database               │
│  (users, transactions, budgets, goals, chat_history)   │
└────────────────────────────────────────────────────────┘
```

---

## Verified Test & Quality Summary

- **Backend Pytest Suite:** **51 / 51 tests passed** (100% green in `tests/` covering authentication, transaction CRUD, budgets, goals, reports, user isolation, suggestions, 503 unconfigured error handling, and Gemini grounding).
- **Flutter Analyzer:** **Zero issues found (`flutter analyze` — 0 errors, 0 warnings, 0 lints)**.
- **Flutter Widget Tests:** **All passed** (`flutter test`).
- **Flutter Web Build:** **Succeeded** (`flutter build web --release`, 3.3MB JS bundle, icons tree-shaken with >99% reduction).
- **Secrets Audit:** **Clean** (No real API keys, secrets, or passwords committed; `.env` and `.db` files strictly gitignored).

---

## Local Development Setup

### 1. Prerequisites
- **Python:** 3.12+
- **Flutter SDK:** 3.24+ (Dart 3.5+)
- **PostgreSQL 16+** (or SQLite for dev testing)
- **Google Gemini API Key** (from [Google AI Studio](https://aistudio.google.com/))

### 2. Backend Setup

```bash
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
cp .env.example .env
# Edit .env with your configuration:
# DATABASE_URL=postgresql://finance:finance_dev_pw@localhost:5432/finance_db
# (or sqlite:///./finance_dev.db for local file-based testing)
# JWT_SECRET_KEY=generate-a-strong-random-key
# GEMINI_API_KEY=your_gemini_api_key_here

# Run database migrations
alembic upgrade head

# Start local backend server
uvicorn app.main:app --reload --port 8000
```

Interactive API documentation will be available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### 3. Frontend Setup (Flutter)

```bash
cd app

# Fetch dependencies
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# To specify a custom API base URL:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

---

## Gemini AI Assistant Configuration

The assistant uses Google's `google-genai` SDK (`gemini-2.5-flash`).

### How Grounding Works
1. When a user asks a question via `POST /api/v1/ai/chat`, the backend queries only the authenticated user's records.
2. Exact sums, category distributions, budget limits vs spent, and savings rates are computed deterministically in Python.
3. The model is provided with a strict system instruction:
   - Must use ONLY the computed facts provided in the prompt.
   - Forbids doing arithmetic or guessing figures.
   - Responds "I don't have that data in your financial records" if information is missing.
   - Formats currency in INR (₹).
4. If `GEMINI_API_KEY` is missing or invalid, the backend returns `HTTP 503` with code `"ai_not_configured"`. The frontend displays a guidance card rather than fabricating fake AI replies.

### Obtaining a Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/).
2. Click **Get API key** $\to$ **Create API key**.
3. Add it to `backend/.env`:
   ```bash
   GEMINI_API_KEY=AIzaSy...your_key_here
   ```

---

## Production Deployment

### 1. Backend & Database (Render Free Tier)

Full step-by-step instructions are provided in [`DEPLOY.md`](./DEPLOY.md).

1. **Create Managed PostgreSQL on Render:**
   - Name: `finance-db`, User: `finance_user`, Plan: Free.
   - Copy the Internal / External Database URL.
2. **Deploy FastAPI Web Service:**
   - Connect repository `Abdanzaki/personal-finance-ai`.
   - Root Directory: `backend`
   - Build Command: `pip install -r requirements.txt && alembic upgrade head`
   - Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - Environment Variables:
     - `DATABASE_URL`: Your Render PostgreSQL URL
     - `JWT_SECRET_KEY`: Random 64-char hex string (`openssl rand -hex 32`)
     - `GEMINI_API_KEY`: Your Gemini API Key
     - `CORS_ORIGINS`: Your Vercel frontend URL

### 2. Frontend Web (Vercel)

The repository includes a [`vercel.json`](./vercel.json) configured for Single-Page Application (SPA) routing with `app/build/web` as the output directory:

```bash
cd app
flutter build web --release
```

Deploy via Vercel CLI or Git integration with:
- **Build Command:** `cd app && flutter build web --release`
- **Output Directory:** `app/build/web`
- **Environment Variable:** `API_BASE_URL=https://your-backend.onrender.com/api/v1`

---

## Android Build & Play Store Distribution

### 1. Build Local Release APK
```bash
cd app
flutter build apk --release
```
Output: `app/build/app/outputs/flutter-apk/app-release.apk`

*(Note: Requires Android SDK and Java 17+ installed on the build machine).*

### 2. Play Store App Bundle (.aab) & Keystore Signing
1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Configure `app/android/key.properties`:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=/path/to/upload-keystore.jks
   ```
3. Build the signed bundle:
   ```bash
   cd app
   flutter build appbundle --release
   ```
4. Upload `app/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

---

## Environment Variables (`backend/.env.example`)

| Variable | Description | Required | Example |
| :--- | :--- | :--- | :--- |
| `DATABASE_URL` | SQLAlchemy PostgreSQL or SQLite connection string | Yes | `postgresql://finance:finance_dev_pw@localhost:5432/finance_db` |
| `JWT_SECRET_KEY` | Secret key used to sign JWT access and refresh tokens | Yes | Random 64-character hex string |
| `JWT_ALGORITHM` | JWT signing algorithm | No (default `HS256`) | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Access token lifespan in minutes | No (default `60`) | `60` |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Refresh token lifespan in days | No (default `30`) | `30` |
| `GEMINI_API_KEY` | Google Gemini API key for live AI assistant | Optional (returns 503 guide if unset) | `AIzaSy...` |
| `CORS_ORIGINS` | Comma-separated list of allowed CORS origins | No (default `*`) | `https://your-app.vercel.app` |

---

## What Needs Manual Configuration (Honest Disclosures)

1. **Google Gemini API Key:** You must register an API key at [Google AI Studio](https://aistudio.google.com/) and provide it in `GEMINI_API_KEY`. Without it, all standard financial tracking functions operate normally, but the AI chat screen explicitly shows an "AI Not Configured" guidance banner.
2. **Backend & Cloud Database Hosting:** For remote multi-user usage, the FastAPI service and PostgreSQL database must be provisioned on a cloud provider like Render or Railway as documented in [`DEPLOY.md`](./DEPLOY.md).
3. **Google Play Store Signing:** To publish on the Play Store, an Android developer account ($25 one-time fee) and a production upload keystore (`upload-keystore.jks`) must be generated by the account owner.
4. **Android Build Toolchain:** Local APK generation requires Android SDK Command-line Tools and JDK 17+ on the host system.

---

## License

Private repository — All rights reserved.
