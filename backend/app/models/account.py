import uuid
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Numeric, String, Uuid, func
from sqlalchemy.orm import relationship
from app.db.database import Base


class Account(Base):
    __tablename__ = "accounts"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(100), nullable=False)
    account_type = Column(String(50), default="bank", nullable=False)  # bank, cash, credit_card, investment
    opening_balance = Column(Numeric(14, 2), default=0.0, nullable=False)
    current_balance = Column(Numeric(14, 2), default=0.0, nullable=False)
    currency = Column(String(10), default="INR", nullable=False)
    is_primary = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account")
