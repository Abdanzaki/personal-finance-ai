from app.routers.auth import router as auth_router
from app.routers.users import router as users_router
from app.routers.transactions import router as transactions_router
from app.routers.budgets import router as budgets_router
from app.routers.goals import router as goals_router
from app.routers.dashboard import router as dashboard_router
from app.routers.reports import router as reports_router
from app.routers.insights import router as insights_router
from app.routers.ai import router as ai_router

__all__ = [
    "auth_router",
    "users_router",
    "transactions_router",
    "budgets_router",
    "goals_router",
    "dashboard_router",
    "reports_router",
    "insights_router",
    "ai_router",
]

