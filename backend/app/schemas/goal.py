from datetime import date, datetime
from decimal import Decimal
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class ContributionBase(BaseModel):
    amount: Decimal = Field(..., gt=0)
    date: datetime
    note: Optional[str] = None


class ContributionCreate(ContributionBase):
    pass


class ContributionResponse(ContributionBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    goal_id: UUID
    user_id: UUID
    created_at: datetime


class SavingsGoalBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=150)
    category: str = Field(..., min_length=1, max_length=100)
    target_amount: Decimal = Field(..., gt=0)
    target_date: date
    image_url: Optional[str] = None


class SavingsGoalCreate(SavingsGoalBase):
    initial_deposit: Optional[Decimal] = Field(default=None, ge=0)


class SavingsGoalUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    target_amount: Optional[Decimal] = Field(default=None, gt=0)
    target_date: Optional[date] = None
    image_url: Optional[str] = None
    is_completed: Optional[bool] = None


class SavingsGoalResponse(SavingsGoalBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    current_amount: Decimal
    is_completed: bool
    progress_percentage: float = 0.0
    created_at: datetime
    updated_at: datetime


class SavingsGoalListResponse(BaseModel):
    total_saved: Decimal
    total_target: Decimal
    active_goals_count: int
    goals: List[SavingsGoalResponse]
