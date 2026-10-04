# Deployment Guide — Personal Finance AI

This guide documents production deployment procedures for the **Personal Finance AI** full-stack system.

---

## 1. Frontend Web Deployment (Vercel)

The Flutter web application can be deployed directly to Vercel.

### Vercel Project Settings

| Setting | Value |
| :--- | :--- |
| **Framework Preset** | Other |
| **Root Directory** | `.` |
| **Build Command** | `cd app && flutter build web --release` |
| **Output Directory** | `app/build/web` |
| **Install Command** | (If building in CI without pre-installed Flutter, install Flutter SDK via setup script or pre-build locally and deploy static assets) |

### Environment Variables on Vercel

| Key | Value | Purpose |
| :--- | :--- | :--- |
| `API_BASE_URL` | `https://your-backend-service.onrender.com/api/v1` | Production backend API entrypoint |

### SPA Routing Configuration (`vercel.json`)

Single-Page Application (SPA) routing is handled by [`vercel.json`](./vercel.json) at the repo root:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "cleanUrls": true,
  "outputDirectory": "app/build/web",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

---

## 2. Backend & Database Deployment (Render Free Tier)

### Step 1: Create Managed PostgreSQL on Render

1. Log into your [Render Dashboard](https://dashboard.render.com).
2. Click **New +** $\to$ **PostgreSQL**.
3. Configure the database:
   - **Name:** `finance-db`
   - **Database Name:** `finance_db`
   - **User:** `finance_user`
   - **Plan:** Free
4. Click **Create Database**.
5. Once provisioned, copy the **Internal Database URL** (if deploying the web service on Render) or **External Database URL**.

### Step 2: Deploy FastAPI Web Service on Render

1. From the Render Dashboard, click **New +** $\to$ **Web Service**.
2. Connect your GitHub repository `Abdanzaki/personal-finance-ai`.
3. Configure the web service settings:
   - **Name:** `personal-finance-ai-backend`
   - **Root Directory:** `backend`
   - **Runtime:** Python 3
   - **Build Command:**
     ```bash
     pip install -r requirements.txt && alembic upgrade head
     ```
   - **Start Command:**
     ```bash
     uvicorn app.main:app --host 0.0.0.0 --port $PORT
     ```
   - **Plan:** Free
4. Add the following **Environment Variables**:
   - `DATABASE_URL`: Your Render PostgreSQL connection string (e.g., `postgresql+psycopg://finance_user:password@hostname/finance_db`)
   - `JWT_SECRET_KEY`: A secure random 64-character hex string (generate via `openssl rand -hex 32`)
   - `GEMINI_API_KEY`: Your Google Gemini API Key from Google AI Studio
   - `CORS_ORIGINS`: Comma-separated list of allowed frontend origins (e.g. `https://your-app.vercel.app`)
5. Click **Create Web Service**.

Once deployed, your API will be accessible at:
- Base: `https://personal-finance-ai-backend.onrender.com/api/v1`
- Swagger Docs: `https://personal-finance-ai-backend.onrender.com/docs`

---

## 3. Android APK & Play Store Distribution

### Local Release APK Build

Ensure Android SDK and Java 17+ are installed:

```bash
cd app
flutter build apk --release
```

Output binary: `app/build/app/outputs/flutter-apk/app-release.apk`

### Play Store App Bundle (.aab) & Keystore Signing

1. **Generate a signing keystore**:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **Configure `app/android/key.properties`**:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=/path/to/upload-keystore.jks
   ```
   *(Note: `key.properties` and `*.keystore` are gitignored).*
3. **Build the production App Bundle**:
   ```bash
   cd app
   flutter build appbundle --release
   ```
4. Upload `app/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
