from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.account import Account
from app.models.transaction import Transaction
from app.models.user import User

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary")
def get_dashboard_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    # Calculate real total net balance from accounts
    total_balance_val = (
        db.query(func.coalesce(func.sum(Account.current_balance), 0))
        .filter(Account.user_id == current_user.id)
        .scalar()
    )
    total_balance = Decimal(str(total_balance_val or 0.0))

    # Calculate current month's income and expenses
    now = datetime.now(timezone.utc)
    start_of_month = datetime(now.year, now.month, 1, tzinfo=timezone.utc)

    monthly_in_val = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == current_user.id,
            Transaction.type == "income",
            Transaction.date >= start_of_month,
        )
        .scalar()
    )
    monthly_in = Decimal(str(monthly_in_val or 0.0))

    monthly_out_val = (
        db.query(func.coalesce(func.sum(Transaction.amount), 0))
        .filter(
            Transaction.user_id == current_user.id,
            Transaction.type == "expense",
            Transaction.date >= start_of_month,
        )
        .scalar()
    )
    monthly_out = Decimal(str(monthly_out_val or 0.0))

    net_savings = monthly_in - monthly_out
    savings_rate = float((net_savings / monthly_in) * 100) if monthly_in > 0 else 0.0

    recent_txs = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.date.desc())
        .limit(5)
        .all()
    )

    return {
        "total_balance": total_balance,
        "primary_account": "HDFC Bank •• 4912",
        "monthly_in": monthly_in,
        "monthly_out": monthly_out,
        "net_savings": net_savings,
        "savings_rate_pct": round(savings_rate, 2),
        "recent_transactions": [
            {
                "id": str(tx.id),
                "title": tx.description,
                "amount": tx.amount,
                "type": tx.type,
                "category": tx.category,
                "date": tx.date.isoformat(),
            }
            for tx in recent_txs
        ],
        "ai_pulse": {
            "title": "AI Intelligence Pulse",
            "message": "Deterministic financial telemetry active and calculated from actual ledger records.",
        },
    }
