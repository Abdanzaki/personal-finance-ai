from typing import Any, Dict
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.user import User

router = APIRouter(prefix="/insights", tags=["insights"])


@router.get("")
def get_insights(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    return {
        "status": "active",
        "largest_expense_category": "Housing & Rent",
        "mom_spending_change_pct": -8.0,
        "recommendation": "You spent ₹3,400 less on dining out this week.",
    }
