from typing import Any, Dict, List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.chat_message import AIChatMessage
from app.models.user import User
from app.schemas.ai import AIChatMessageOut, AIChatRequest, AIChatResponse, AISuggestionsResponse
from app.services.ai_service import SUGGESTED_QUESTIONS, generate_grounded_ai_response

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/chat", response_model=AIChatResponse)
def chat_with_assistant(
    request_data: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AIChatResponse:
    """
    Submits user query to Gemini grounded strictly in deterministic Python-computed financial facts.
    Persists user query and assistant response in conversation history.
    """
    answer, facts_used = generate_grounded_ai_response(
        db=db,
        user=current_user,
        user_message=request_data.message,
        conversation_id=request_data.conversation_id,
    )

    # Persist user message
    user_msg = AIChatMessage(
        user_id=current_user.id,
        role="user",
        content=request_data.message,
    )
    db.add(user_msg)

    # Persist assistant response
    assistant_msg = AIChatMessage(
        user_id=current_user.id,
        role="assistant",
        content=answer,
    )
    db.add(assistant_msg)
    db.commit()

    return AIChatResponse(
        answer=answer,
        facts_used=facts_used,
        conversation_id=request_data.conversation_id,
    )


@router.get("/history", response_model=List[AIChatMessageOut])
def get_chat_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> List[AIChatMessageOut]:
    """
    Retrieves chronological chat history for the authenticated user.
    Strictly isolated per user.
    """
    messages = (
        db.query(AIChatMessage)
        .filter(AIChatMessage.user_id == current_user.id)
        .order_by(AIChatMessage.created_at.asc())
        .all()
    )
    return messages


@router.delete("/history")
def clear_chat_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Dict[str, str]:
    """
    Clears all chat history for the authenticated user.
    """
    db.query(AIChatMessage).filter(AIChatMessage.user_id == current_user.id).delete()
    db.commit()
    return {"detail": "Chat history cleared successfully"}


@router.get("/suggestions", response_model=AISuggestionsResponse)
def get_suggested_questions() -> AISuggestionsResponse:
    """
    Returns curated quick suggestion prompts for financial inquiries.
    """
    return AISuggestionsResponse(suggestions=SUGGESTED_QUESTIONS)
