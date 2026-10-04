# Personal Finance AI — Smart Money Management App

Full-stack build. All code written by Antigravity CLI (`agy`); designs from
Google Stitch; coordinator orchestrates, verifies, pushes to GitHub, deploys.

## Stack
- **Design:** Google Stitch (visual source of truth; export Flutter code where possible)
- **Frontend:** Flutter + Dart — single codebase for Android, iOS, and web
- **Backend:** Python FastAPI
- **Database:** PostgreSQL (migrations, indexes, per-user authorization)
- **Auth:** token-based (JWT), secure password hashing, password reset
- **AI:** Gemini API via secure backend endpoint (key in backend env only)
- **Charts:** fl_chart (or equivalent)
- **Web hosting:** Vercel (Flutter web build)
- **Backend hosting:** TBD — Render/Railway/Fly.io free tier (needs user account decision)
- **VCS:** GitHub

## Currency/format
INR (₹) everywhere, Indian numbering format (lakh/crore grouping).

## App modules
1. Auth — signup, login/logout, password reset, protected routes
2. Dashboard — total balance (from tracked opening balances/transfers, NOT
   net income−expenses mislabeled), income, expenses, net savings, savings
   rate, income-vs-expense chart, category chart, recent transactions, budget
   cards, goal progress, AI insights; weekly/monthly/yearly/custom filters
3. Transactions — full CRUD, search, filter (category/date/type), sort;
   fields: id, user_id, type, amount, description, category, date,
   payment_method, created_at, updated_at
4. Budgets — monthly + per-category, CRUD, spent/remaining/% used, 80%/100%
   warnings; computed from real expense transactions
5. Savings goals — CRUD, target amount/date, contributions, progress
6. AI assistant — real backend endpoint: auth → fetch user's records →
   compute exact totals in backend → summarized data + question → Gemini →
   answer; suggested questions, history, loading/error states; never invent
   numbers; graceful "not configured" state if no API key
7. Insights — deterministic backend calculations (largest category, MoM
   change, near-limit budgets, savings opportunities, goal progress) + AI
   explanations; facts vs estimates clearly separated
8. Reports — monthly/yearly income/expense, category breakdown, savings
   trends, MoM comparison, filters, CSV export
9. Settings — profile, currency (INR default), monthly income/savings targets,
   theme, notifications, account, logout

## Design language (from user)
Dark navy navigation, white/light-gray content, green accents for positive
values, rounded cards, polished charts, subtle animations; responsive:
desktop sidebar+topbar, mobile bottom nav, tablet adaptive. Accessible
contrast. Stitch designs are the visual source of truth.

## API surface (FastAPI)
- `POST /auth/signup`, `/auth/login`, `/auth/refresh`, `/auth/logout`,
  `/auth/password-reset`
- CRUD `/transactions`, `/budgets`, `/goals` (+ `/goals/:id/contributions`)
- `GET /dashboard/summary`, `/reports/*`, `/insights`
- `POST /ai/chat`
All protected endpoints enforce user-level authorization (users can only
touch their own rows). Parameterized queries/ORM, input validation,
env-based config, no secrets in client or git.

## Build phases
1. **Design** — Stitch: generate all screens (auth, dashboard, transactions,
   budgets, goals, AI chat, reports, settings) in mobile + desktop layouts;
   export designs/Flutter code into `designs/`.
2. **Flutter shell** — project scaffold, design system (theme, colors,
   typography, components from Stitch), responsive navigation, auth screens.
3. **Backend** — FastAPI app, Postgres schema + migrations, JWT auth,
   user-scoped CRUD endpoints.
4. **Features** — transactions, budgets, goals, dashboard summaries, reports
   + CSV export, insights endpoints; wire Flutter UI to real API (no
   hardcoded data; demo seed clearly labeled and separate).
5. **AI** — `/ai/chat` endpoint + chat UI; backend-computed totals passed to
   Gemini; missing-key handling.
6. **Test** — `flutter pub get`, `flutter analyze`, `flutter build web`;
   backend tests (auth, authorization isolation, CRUD, budget math, AI
   endpoint); fix all issues. No false "tested" claims (esp. iOS).
7. **Ship** — GitHub repo `Abdanzaki/personal-finance-ai` (public),
   `.gitignore`, README, `.env.example` (placeholders only); Vercel deploy
   of Flutter web build with SPA fallback + backend URL config; backend +
   Postgres deploy docs (and deploy if a free-tier account is available).

## Constraints
- No secrets/API keys/passwords in code or git — ever.
- Flutter SDK must be installed on the build machine (not present initially).
- Android APK build: attempt `flutter build apk`; full Play Store release
  needs the user's keystore — document it.
- Gemini API key: user must supply; backend must run in degraded
  "AI not configured" mode without it — never fake AI responses.
- Backend hosting choice needs the user (account/billing) — default to
  documenting Render free-tier steps; deploy only with user approval.
