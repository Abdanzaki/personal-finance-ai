from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class BudgetBase(BaseModel):
    category: str = Field(..., min_length=1, max_length=100)
    limit_amount: Decimal = Field(..., gt=0, description="Monthly budget limit must be strictly positive")
    period_month: str = Field(
        ...,
        pattern=r"^\d{4}-(0[1-9]|1[0-2])$",
        description="Billing month in YYYY-MM format (e.g. 2025-03)",
    )


class BudgetCreate(BudgetBase):
    pass


class BudgetUpdate(BaseModel):
    limit_amount: Decimal = Field(..., gt=0)


class BudgetResponse(BudgetBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    spent_amount: Decimal = Decimal("0.00")
    remaining_amount: Decimal = Decimal("0.00")
    percentage_used: float = 0.0
    is_warning: bool = False
    is_exceeded: bool = False
    created_at: datetime
    updated_at: datetime


class BudgetListResponse(BaseModel):
    month: str
    total_budget: Decimal
    total_spent: Decimal
    items: List[BudgetResponse]
