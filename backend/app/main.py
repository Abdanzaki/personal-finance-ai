from datetime import datetime, timezone
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import (
    ai_router,
    auth_router,
    budgets_router,
    dashboard_router,
    goals_router,
    insights_router,
    reports_router,
    transactions_router,
    users_router,
)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API v1 Routers
api_v1_prefix = settings.API_V1_STR
app.include_router(auth_router, prefix=api_v1_prefix)
app.include_router(users_router, prefix=api_v1_prefix)
app.include_router(transactions_router, prefix=api_v1_prefix)
app.include_router(budgets_router, prefix=api_v1_prefix)
app.include_router(goals_router, prefix=api_v1_prefix)
app.include_router(dashboard_router, prefix=api_v1_prefix)
app.include_router(reports_router, prefix=api_v1_prefix)
app.include_router(insights_router, prefix=api_v1_prefix)
app.include_router(ai_router, prefix=api_v1_prefix)

# Also mount auth and primary routers directly without prefix for ergonomic client routing
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(transactions_router)
app.include_router(budgets_router)


@app.get("/health", tags=["system"])
@app.get("/", tags=["system"])
def health_check():
    return {
        "status": "healthy",
        "app": settings.PROJECT_NAME,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": "1.0.0",
    }
