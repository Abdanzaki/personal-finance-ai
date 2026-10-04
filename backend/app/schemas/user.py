from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, EmailStr


class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    currency: str = "INR"
    monthly_income_target: Optional[Decimal] = None
    monthly_savings_target: Optional[Decimal] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    currency: str
    monthly_income_target: Optional[Decimal] = None
    monthly_savings_target: Optional[Decimal] = None
    is_active: bool
    created_at: datetime


class UserUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    currency: Optional[str] = None
    monthly_income_target: Optional[Decimal] = None
    monthly_savings_target: Optional[Decimal] = None
