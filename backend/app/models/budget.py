import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String, UniqueConstraint, Uuid, func
from sqlalchemy.orm import relationship
from app.db.database import Base


class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    category = Column(String(100), nullable=False)
    limit_amount = Column(Numeric(14, 2), nullable=False)
    period_month = Column(String(7), nullable=False, index=True)  # YYYY-MM e.g. 2025-03
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    user = relationship("User", back_populates="budgets")

    __table_args__ = (
        UniqueConstraint("user_id", "category", "period_month", name="uq_user_category_month"),
    )
