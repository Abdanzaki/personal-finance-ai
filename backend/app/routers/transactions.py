from datetime import datetime
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.account import Account
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.transaction import (
    TransactionCreate,
    TransactionListResponse,
    TransactionResponse,
    TransactionUpdate,
)

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("", response_model=TransactionListResponse)
def list_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    category: Optional[str] = None,
    type: Optional[str] = None,
    search: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    sort: str = Query("date_desc", pattern="^(date_desc|date_asc|amount_desc|amount_asc)$"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(Transaction).filter(Transaction.user_id == current_user.id)

    if category:
        query = query.filter(Transaction.category.ilike(f"%{category.strip()}%"))
    if type:
        query = query.filter(Transaction.type == type.strip().lower())
    if search:
        search_term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Transaction.description.ilike(search_term),
                Transaction.category.ilike(search_term),
                Transaction.payment_method.ilike(search_term),
            )
        )
    if start_date:
        query = query.filter(Transaction.date >= start_date)
    if end_date:
        query = query.filter(Transaction.date <= end_date)

    # Sorting
    if sort == "date_asc":
        query = query.order_by(Transaction.date.asc())
    elif sort == "amount_desc":
        query = query.order_by(Transaction.amount.desc())
    elif sort == "amount_asc":
        query = query.order_by(Transaction.amount.asc())
    else:  # date_desc default
        query = query.order_by(Transaction.date.desc())

    total = query.count()
    items = query.offset(skip).limit(limit).all()

    page = (skip // limit) + 1 if limit > 0 else 1

    return TransactionListResponse(
        items=[TransactionResponse.model_validate(tx) for tx in items],
        total=total,
        page=page,
        size=limit,
    )


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    tx_in: TransactionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Verify account ownership if provided
    account_id = tx_in.account_id
    if account_id:
        account = db.query(Account).filter(
            Account.id == account_id,
            Account.user_id == current_user.id,
        ).first()
        if not account:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Account not found",
            )
    else:
        # Default to primary account if available
        primary_account = db.query(Account).filter(
            Account.user_id == current_user.id,
            Account.is_primary.is_(True),
        ).first()
        account_id = primary_account.id if primary_account else None

    transaction = Transaction(
        user_id=current_user.id,
        account_id=account_id,
        type=tx_in.type,
        amount=tx_in.amount,
        description=tx_in.description.strip(),
        category=tx_in.category.strip(),
        date=tx_in.date,
        payment_method=tx_in.payment_method.strip(),
    )
    db.add(transaction)

    # Update account balance if account exists
    if account_id:
        acc = db.query(Account).filter(Account.id == account_id).first()
        if acc:
            if tx_in.type == "income":
                acc.current_balance += tx_in.amount
            elif tx_in.type == "expense":
                acc.current_balance -= tx_in.amount

    db.commit()
    db.refresh(transaction)

    return TransactionResponse.model_validate(transaction)


@router.get("/{id}", response_model=TransactionResponse)
def get_transaction(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Strictly isolated: returns 404 for other users' transactions (never leaks existence with 403)
    transaction = db.query(Transaction).filter(
        Transaction.id == id,
        Transaction.user_id == current_user.id,
    ).first()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found",
        )

    return TransactionResponse.model_validate(transaction)


@router.put("/{id}", response_model=TransactionResponse)
def update_transaction(
    id: UUID,
    tx_update: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transaction = db.query(Transaction).filter(
        Transaction.id == id,
        Transaction.user_id == current_user.id,
    ).first()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found",
        )

    update_data = tx_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if value is not None:
            if isinstance(value, str):
                setattr(transaction, field, value.strip())
            else:
                setattr(transaction, field, value)

    db.commit()
    db.refresh(transaction)

    return TransactionResponse.model_validate(transaction)


@router.delete("/{id}", response_model=MessageResponse)
def delete_transaction(
    id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transaction = db.query(Transaction).filter(
        Transaction.id == id,
        Transaction.user_id == current_user.id,
    ).first()

    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found",
        )

    db.delete(transaction)
    db.commit()

    return MessageResponse(message="Transaction deleted successfully")
