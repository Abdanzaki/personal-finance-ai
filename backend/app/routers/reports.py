import csv
import io
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.database import get_db
from app.models.transaction import Transaction
from app.models.user import User

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/summary")
def get_reports_summary(
    timeframe: str = Query("monthly"),
    month: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return {
        "timeframe": timeframe,
        "month": month,
        "audit_ready": True,
        "tax_80c_limit": 150000.0,
        "tax_80c_utilized": 150000.0,
    }


@router.get("/export")
def export_transactions_csv(
    format: str = Query("csv", pattern="^(csv)$"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == current_user.id)
        .order_by(Transaction.date.desc())
        .all()
    )

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Date", "Type", "Category", "Description", "Payment Method", "Amount (INR)"])

    for tx in transactions:
        writer.writerow([
            tx.date.strftime("%Y-%m-%d %H:%M:%S"),
            tx.type,
            tx.category,
            tx.description,
            tx.payment_method,
            f"{tx.amount:.2f}",
        ])

    csv_data = output.getvalue()
    filename = f"finance_ledger_{datetime.now().strftime('%Y%m%d')}.csv"

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
