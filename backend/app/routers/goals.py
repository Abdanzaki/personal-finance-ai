from decimal import Decimal
from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.contribution import GoalContribution
from app.models.goal import SavingsGoal
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.goal import (
    ContributionCreate,
    ContributionResponse,
    SavingsGoalCreate,
    SavingsGoalListResponse,
    SavingsGoalResponse,
    SavingsGoalUpdate,
)

router = APIRouter(prefix="/goals", tags=["goals"])


def build_goal_response(goal: SavingsGoal) -> SavingsGoalResponse:
    target = Decimal(str(goal.target_amount))
    current = Decimal(str(goal.current_amount))
    pct = float((current / target) * 100) if target > 0 else 0.0

    return SavingsGoalResponse(
        id=goal.id,
        user_id=goal.user_id,
        title=goal.title,
        category=goal.category,
        target_amount=target,
        current_amount=current,
        target_date=goal.target_date,
        image_url=goal.image_url,
        is_completed=goal.is_completed,
        progress_percentage=round(pct, 2),
        created_at=goal.created_at,
        updated_at=goal.updated_at,
    )


@router.get("", response_model=SavingsGoalListResponse)
def list_goals(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goals = db.query(SavingsGoal).filter(SavingsGoal.user_id == current_user.id).all()
    items = [build_goal_response(g) for g in goals]
    total_saved = sum((g.current_amount for g in items), Decimal("0.00"))
    total_target = sum((g.target_amount for g in items), Decimal("0.00"))

    return SavingsGoalListResponse(
        total_saved=total_saved,
        total_target=total_target,
        active_goals_count=len([g for g in items if not g.is_completed]),
        goals=items,
    )


@router.post("", response_model=SavingsGoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(
    goal_in: SavingsGoalCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    initial = goal_in.initial_deposit or Decimal("0.00")
    goal = SavingsGoal(
        user_id=current_user.id,
        title=goal_in.title.strip(),
        category=goal_in.category.strip(),
        target_amount=goal_in.target_amount,
        current_amount=initial,
        target_date=goal_in.target_date,
        image_url=goal_in.image_url,
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)

    return build_goal_response(goal)


@router.get("/{id}", response_model=SavingsGoalResponse)
def get_goal(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == id,
        SavingsGoal.user_id == current_user.id,
    ).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Savings goal not found")
    return build_goal_response(goal)


@router.put("/{id}", response_model=SavingsGoalResponse)
def update_goal(
    id: UUID,
    goal_update: SavingsGoalUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == id,
        SavingsGoal.user_id == current_user.id,
    ).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Savings goal not found")

    for field, value in goal_update.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(goal, field, value)

    db.commit()
    db.refresh(goal)
    return build_goal_response(goal)


@router.delete("/{id}", response_model=MessageResponse)
def delete_goal(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == id,
        SavingsGoal.user_id == current_user.id,
    ).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Savings goal not found")

    db.delete(goal)
    db.commit()
    return MessageResponse(message="Savings goal deleted successfully")


@router.post("/{id}/contributions", response_model=ContributionResponse, status_code=status.HTTP_201_CREATED)
def add_contribution(
    id: UUID,
    contrib_in: ContributionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == id,
        SavingsGoal.user_id == current_user.id,
    ).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Savings goal not found")

    contrib = GoalContribution(
        goal_id=goal.id,
        user_id=current_user.id,
        amount=contrib_in.amount,
        date=contrib_in.date,
        note=contrib_in.note,
    )
    db.add(contrib)
    goal.current_amount += contrib_in.amount
    if goal.current_amount >= goal.target_amount:
        goal.is_completed = True

    db.commit()
    db.refresh(contrib)
    return ContributionResponse.model_validate(contrib)


@router.get("/{id}/contributions", response_model=List[ContributionResponse])
def list_contributions(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = db.query(SavingsGoal).filter(
        SavingsGoal.id == id,
        SavingsGoal.user_id == current_user.id,
    ).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Savings goal not found")

    contributions = (
        db.query(GoalContribution)
        .filter(GoalContribution.goal_id == id)
        .order_by(GoalContribution.date.desc())
        .all()
    )
    return [ContributionResponse.model_validate(c) for c in contributions]
