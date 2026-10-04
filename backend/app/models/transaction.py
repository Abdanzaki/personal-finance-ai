import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Index, Numeric, String, Uuid, func
from sqlalchemy.orm import relationship
from app.db.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    account_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("accounts.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    type = Column(String(20), nullable=False)  # income, expense, transfer
    amount = Column(Numeric(14, 2), nullable=False)
    description = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False, index=True)
    date = Column(DateTime(timezone=True), nullable=False, index=True)
    payment_method = Column(String(50), default="UPI", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    user = relationship("User", back_populates="transactions")
    account = relationship("Account", back_populates="transactions")

    __table_args__ = (
        Index("ix_transactions_user_date", "user_id", "date"),
        Index("ix_transactions_user_category", "user_id", "category"),
    )
