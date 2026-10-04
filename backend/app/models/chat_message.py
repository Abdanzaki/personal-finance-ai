import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Index, String, Text, Uuid, func
from sqlalchemy.orm import relationship
from app.db.database import Base


class AIChatMessage(Base):
    __tablename__ = "ai_chat_messages"

    id = Column(Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    role = Column(String(20), nullable=False)  # 'user' | 'assistant'
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="ai_chat_messages")

    __table_args__ = (
        Index("ix_ai_chat_messages_user_created", "user_id", "created_at"),
    )
