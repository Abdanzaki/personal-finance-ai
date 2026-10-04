from datetime import datetime
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class AIChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000, description="User question or financial query")
    conversation_id: Optional[str] = Field(None, description="Optional conversation identifier")


class AIChatResponse(BaseModel):
    answer: str = Field(..., description="Grounded AI response")
    facts_used: List[str] = Field(default_factory=list, description="Computed financial facts injected into prompt")
    conversation_id: Optional[str] = Field(None, description="Conversation session ID")


class AIChatMessageOut(BaseModel):
    id: UUID
    role: str
    content: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AISuggestionsResponse(BaseModel):
    suggestions: List[str]
