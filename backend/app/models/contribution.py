import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String, Uuid, func
from sqlalchemy.orm import relationship
from app.db.database import Base


class GoalContribution(Base):
    __tablename__ = "goal_contributions"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("savings_goals.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    amount = Column(Numeric(14, 2), nullable=False)
    date = Column(DateTime(timezone=True), nullable=False)
    note = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    goal = relationship("SavingsGoal", back_populates="contributions")
    user = relationship("User", back_populates="contributions")
