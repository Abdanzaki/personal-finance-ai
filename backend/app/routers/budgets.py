from calendar import monthrange
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional, Tuple
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.budget import Budget
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.budget import (
    BudgetCreate,
    BudgetListResponse,
    BudgetResponse,
    BudgetUpdate,
)

router = APIRouter(prefix="/budgets", tags=["budgets"])


def get_month_date_range(period_month: str) -> Tuple[datetime, datetime]:
    """Parse YYYY-MM into start and end UTC datetime bounds."""
    year, month = map(int, period_month.split("-"))
    start_date = datetime(year, month, 1, 0, 0, 0, tzinfo=timezone.utc)
    _, last_day = monthrange(year, month)
    end_date = datetime(year, month, last_day, 23, 59, 59, 999999, tzinfo=timezone.utc)
    return start_date, end_date


def calculate_budget_metrics(budget: Budget, db: Session) -> BudgetResponse:
    """Calculate actual spent, remaining, and threshold warning states from real expense transactions."""
    start_date, end_date = get_month_date_range(budget.period_month)

    # Compute spent amount from user's actual expense transactions in this category & date window
    spent_query = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
        Transaction.user_id == budget.user_id,
        Transaction.type == "expense",
        func.lower(Transaction.category) == func.lower(budget.category),
        Transaction.date >= start_date,
        Transaction.date <= end_date,
    )
    spent_val = spent_query.scalar() or Decimal("0.00")
    spent_amount = Decimal(str(spent_val))

    limit_amount = Decimal(str(budget.limit_amount))
    remaining_amount = max(Decimal("0.00"), limit_amount - spent_amount)

    percentage_used = float((spent_amount / limit_amount) * 100) if limit_amount > 0 else 0.0
    is_warning = percentage_used >= 80.0
    is_exceeded = percentage_used >= 100.0

    return BudgetResponse(
        id=budget.id,
        user_id=budget.user_id,
        category=budget.category,
        limit_amount=limit_amount,
        period_month=budget.period_month,
        spent_amount=spent_amount,
        remaining_amount=remaining_amount,
        percentage_used=round(percentage_used, 2),
        is_warning=is_warning,
        is_exceeded=is_exceeded,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
    )


@router.get("", response_model=BudgetListResponse)
def list_budgets(
    month: Optional[str] = Query(None, pattern=r"^\d{4}-(0[1-9]|1[0-2])$"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    target_month = month or datetime.now(timezone.utc).strftime("%Y-%m")

    budgets = (
        db.query(Budget)
        .filter(
            Budget.user_id == current_user.id,
            Budget.period_month == target_month,
        )
        .order_by(Budget.category.asc())
        .all()
    )

    items = [calculate_budget_metrics(b, db) for b in budgets]
    total_budget = sum((item.limit_amount for item in items), Decimal("0.00"))
    total_spent = sum((item.spent_amount for item in items), Decimal("0.00"))

    return BudgetListResponse(
        month=target_month,
        total_budget=total_budget,
        total_spent=total_spent,
        items=items,
    )


@router.post("", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
def create_budget(
    budget_in: BudgetCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    clean_category = budget_in.category.strip()

    # Check for existing budget in the same category & month
    existing = (
        db.query(Budget)
        .filter(
            Budget.user_id == current_user.id,
            func.lower(Budget.category) == clean_category.lower(),
            Budget.period_month == budget_in.period_month,
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Budget for '{clean_category}' already exists in {budget_in.period_month}",
        )

    budget = Budget(
        user_id=current_user.id,
        category=clean_category,
        limit_amount=budget_in.limit_amount,
        period_month=budget_in.period_month,
    )
    db.add(budget)
    db.commit()
    db.refresh(budget)

    return calculate_budget_metrics(budget, db)


@router.get("/{id}", response_model=BudgetResponse)
def get_budget(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    budget = (
        db.query(Budget)
        .filter(
            Budget.id == id,
            Budget.user_id == current_user.id,
        )
        .first()
    )
    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found",
        )

    return calculate_budget_metrics(budget, db)


@router.put("/{id}", response_model=BudgetResponse)
def update_budget(
    id: UUID,
    budget_update: BudgetUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    budget = (
        db.query(Budget)
        .filter(
            Budget.id == id,
            Budget.user_id == current_user.id,
        )
        .first()
    )
    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found",
        )

    budget.limit_amount = budget_update.limit_amount
    db.commit()
    db.refresh(budget)

    return calculate_budget_metrics(budget, db)


@router.delete("/{id}", response_model=MessageResponse)
def delete_budget(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    budget = (
        db.query(Budget)
        .filter(
            Budget.id == id,
            Budget.user_id == current_user.id,
        )
        .first()
    )
    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found",
        )

    db.delete(budget)
    db.commit()

    return MessageResponse(message="Budget deleted successfully")
