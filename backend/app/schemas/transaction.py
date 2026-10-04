from datetime import datetime
from decimal import Decimal
from typing import List, Literal, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


TransactionType = Literal["income", "expense", "transfer"]


class TransactionBase(BaseModel):
    type: TransactionType
    amount: Decimal = Field(..., gt=0, description="Amount must be strictly positive")
    description: str = Field(..., min_length=1, max_length=255)
    category: str = Field(..., min_length=1, max_length=100)
    date: datetime
    payment_method: str = Field(default="UPI", max_length=50)
    account_id: Optional[UUID] = None


class TransactionCreate(TransactionBase):
    pass


class TransactionUpdate(BaseModel):
    type: Optional[TransactionType] = None
    amount: Optional[Decimal] = Field(default=None, gt=0)
    description: Optional[str] = Field(default=None, min_length=1, max_length=255)
    category: Optional[str] = Field(default=None, min_length=1, max_length=100)
    date: Optional[datetime] = None
    payment_method: Optional[str] = Field(default=None, max_length=50)
    account_id: Optional[UUID] = None


class TransactionResponse(TransactionBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime


class TransactionListResponse(BaseModel):
    items: List[TransactionResponse]
    total: int
    page: int
    size: int
