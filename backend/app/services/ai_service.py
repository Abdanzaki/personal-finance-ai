from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.account import Account
from app.models.budget import Budget
from app.models.goal import SavingsGoal
from app.models.transaction import Transaction
from app.models.user import User


SYSTEM_INSTRUCTION = """You are Personal Finance AI, an intelligent, objective, and privacy-conscious financial co-pilot.
Your goal is to provide helpful, concise, and accurate financial insights based exclusively on the user's verified financial records.

CRITICAL GROUNDING RULES:
1. You MUST use ONLY the exact numbers, categories, calculations, budgets, and goals provided below under COMPUTED FINANCIAL FACTS.
2. DO NOT perform arithmetic or calculate sums/percentages yourself. All arithmetic and comparisons have been pre-computed by the Python backend.
3. NEVER invent, extrapolate, or hallucinate transactions, balances, dates, or financial figures.
4. If the user asks about data or time periods not provided in the facts (for example, missing categories, unrecorded months, or future unstated income), you must clearly and politely state: "I don't have that data in your financial records."
5. Format all monetary values in Indian Rupees (₹) using Indian numbering conventions where appropriate.
6. Keep answers concise, actionable, and friendly. Highlight budget warnings or savings milestones when relevant to the user's question.
"""

SUGGESTED_QUESTIONS = [
    "Where did most of my money go this month?",
    "How much did I spend on food?",
    "Compare this month vs last month",
    "Which categories could I reduce?",
    "Am I exceeding any budgets?",
    "Help me create a monthly savings plan",
]


def format_inr(val: Any) -> str:
    """Format decimal/float into INR currency string."""
    try:
        num = float(val)
        return f"₹{num:,.2f}"
    except (ValueError, TypeError):
        return f"₹{val}"


def to_naive_utc(dt: Optional[datetime]) -> Optional[datetime]:
    """Convert offset-aware or naive datetime to naive UTC datetime for uniform comparison."""
    if dt is None:
        return None
    if dt.tzinfo is not None:
        return dt.astimezone(timezone.utc).replace(tzinfo=None)
    return dt


def calculate_user_financial_facts(db: Session, user: User) -> Tuple[Dict[str, Any], List[str]]:
    """
    Deterministically computes user financial facts from database records.
    Never lets the LLM perform arithmetic.
    Returns (raw_facts_dict, list_of_facts_used).
    """
    facts_used: List[str] = []

    # 1. Accounts & Total Balance
    accounts = db.query(Account).filter(Account.user_id == user.id).all()
    total_balance = sum((Decimal(str(a.current_balance or 0.0)) for a in accounts), Decimal("0.0"))
    facts_used.append(f"Total Bank & Account Balance: {format_inr(total_balance)}")

    # 2. Determine Analysis Month Range
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    all_txs = (
        db.query(Transaction)
        .filter(Transaction.user_id == user.id)
        .order_by(Transaction.date.desc())
        .all()
    )

    # Determine anchor date: if user has txs in current calendar month use today,
    # otherwise if user has historical txs use the latest tx month, else today.
    curr_cal_start = datetime(now.year, now.month, 1)
    curr_cal_has_txs = any(to_naive_utc(t.date) >= curr_cal_start for t in all_txs)

    if curr_cal_has_txs or not all_txs:
        anchor_year = now.year
        anchor_month = now.month
    else:
        latest_date = to_naive_utc(all_txs[0].date)
        anchor_year = latest_date.year
        anchor_month = latest_date.month

    # Current period
    current_start = datetime(anchor_year, anchor_month, 1)
    if anchor_month == 12:
        current_end = datetime(anchor_year + 1, 1, 1)
    else:
        current_end = datetime(anchor_year, anchor_month + 1, 1)

    # Previous period
    if anchor_month == 1:
        prev_start = datetime(anchor_year - 1, 12, 1)
        prev_end = current_start
    else:
        prev_start = datetime(anchor_year, anchor_month - 1, 1)
        prev_end = current_start

    period_name = current_start.strftime("%B %Y")
    prev_period_name = prev_start.strftime("%B %Y")
    facts_used.append(f"Active Analysis Period: {period_name} (Compared against {prev_period_name})")

    # 3. Income & Outflow Aggregations
    curr_txs = [t for t in all_txs if current_start <= to_naive_utc(t.date) < current_end]
    prev_txs = [t for t in all_txs if prev_start <= to_naive_utc(t.date) < prev_end]

    curr_income = sum((Decimal(str(t.amount)) for t in curr_txs if t.type == "income"), Decimal("0.0"))
    curr_expense = sum((Decimal(str(t.amount)) for t in curr_txs if t.type == "expense"), Decimal("0.0"))
    curr_net_savings = curr_income - curr_expense
    curr_savings_rate = float((curr_net_savings / curr_income) * 100) if curr_income > 0 else 0.0

    prev_income = sum((Decimal(str(t.amount)) for t in prev_txs if t.type == "income"), Decimal("0.0"))
    prev_expense = sum((Decimal(str(t.amount)) for t in prev_txs if t.type == "expense"), Decimal("0.0"))
    prev_net_savings = prev_income - prev_expense
    prev_savings_rate = float((prev_net_savings / prev_income) * 100) if prev_income > 0 else 0.0

    mom_expense_diff = curr_expense - prev_expense
    mom_expense_pct = float((mom_expense_diff / prev_expense) * 100) if prev_expense > 0 else 0.0

    facts_used.append(f"{period_name} Total Income: {format_inr(curr_income)}")
    facts_used.append(f"{period_name} Total Expenses: {format_inr(curr_expense)}")
    facts_used.append(
        f"{period_name} Net Savings: {format_inr(curr_net_savings)} (Savings Rate: {curr_savings_rate:.1f}%)"
    )
    if prev_expense > 0:
        sign = "+" if mom_expense_diff >= 0 else ""
        facts_used.append(
            f"Month-over-Month Expense Change: {sign}{format_inr(mom_expense_diff)} ({sign}{mom_expense_pct:.1f}% vs {prev_period_name} of {format_inr(prev_expense)})"
        )
    else:
        facts_used.append(f"{prev_period_name} Total Expenses: {format_inr(prev_expense)} (No previous month baseline)")

    # 4. Category Breakdowns
    curr_cat_expenses: Dict[str, Decimal] = defaultdict(Decimal)
    for t in curr_txs:
        if t.type == "expense":
            curr_cat_expenses[t.category] += Decimal(str(t.amount))

    prev_cat_expenses: Dict[str, Decimal] = defaultdict(Decimal)
    for t in prev_txs:
        if t.type == "expense":
            prev_cat_expenses[t.category] += Decimal(str(t.amount))

    sorted_categories = sorted(curr_cat_expenses.items(), key=lambda x: x[1], reverse=True)
    if sorted_categories:
        top_cat, top_amt = sorted_categories[0]
        top_pct = float((top_amt / curr_expense) * 100) if curr_expense > 0 else 0.0
        facts_used.append(f"Top Expense Category: {top_cat} at {format_inr(top_amt)} ({top_pct:.1f}% of total monthly expenses)")

        for cat, amt in sorted_categories:
            pct = float((amt / curr_expense) * 100) if curr_expense > 0 else 0.0
            prev_amt = prev_cat_expenses.get(cat, Decimal("0.0"))
            delta = amt - prev_amt
            delta_str = f" (vs {format_inr(prev_amt)} last month: {'+' if delta >= 0 else ''}{format_inr(delta)})" if prev_amt > 0 else ""
            facts_used.append(f"Category '{cat}': {format_inr(amt)} ({pct:.1f}%){delta_str}")
    else:
        facts_used.append(f"No expenses recorded yet for {period_name}.")

    # 5. Budgets Status
    budgets = db.query(Budget).filter(Budget.user_id == user.id).all()
    if budgets:
        for b in budgets:
            limit = Decimal(str(b.limit_amount))
            # Match case-insensitively
            spent = sum(
                (amt for cat, amt in curr_cat_expenses.items() if cat.lower() == b.category.lower()),
                Decimal("0.0"),
            )
            remaining = limit - spent
            pct_used = float((spent / limit) * 100) if limit > 0 else 0.0
            if spent > limit:
                status_str = f"EXCEEDED by {format_inr(spent - limit)} ({pct_used:.1f}% used)"
            elif pct_used >= 80:
                status_str = f"WARNING at {pct_used:.1f}% ({format_inr(remaining)} remaining)"
            else:
                status_str = f"On Track ({format_inr(remaining)} remaining / {pct_used:.1f}% used)"
            facts_used.append(f"Budget '{b.category}': Limit {format_inr(limit)}, Spent {format_inr(spent)} -> {status_str}")
    else:
        facts_used.append("No active monthly budgets configured.")

    # 6. Savings Goals Status
    goals = db.query(SavingsGoal).filter(SavingsGoal.user_id == user.id).all()
    if goals:
        for g in goals:
            target = Decimal(str(g.target_amount))
            current = Decimal(str(g.current_amount))
            gap = max(Decimal("0.0"), target - current)
            pct_achieved = float((current / target) * 100) if target > 0 else 0.0
            target_date_str = f", Target Date: {g.target_date.strftime('%Y-%m-%d')}" if g.target_date else ""
            facts_used.append(
                f"Goal '{g.title}': Saved {format_inr(current)} of {format_inr(target)} ({pct_achieved:.1f}% achieved, {format_inr(gap)} remaining{target_date_str})"
            )
    else:
        facts_used.append("No savings goals currently configured.")

    # 7. Recent Transactions (last 10)
    if all_txs:
        recent_samples = all_txs[:10]
        tx_lines = [
            f"{t.date.strftime('%Y-%m-%d')}: {t.description} ({t.category}) - {t.type.upper()} {format_inr(t.amount)} [{t.payment_method}]"
            for t in recent_samples
        ]
        facts_used.append(f"Recent Transactions ({len(tx_lines)}): " + "; ".join(tx_lines))

    raw_data = {
        "period_name": period_name,
        "total_balance": float(total_balance),
        "curr_income": float(curr_income),
        "curr_expense": float(curr_expense),
        "curr_net_savings": float(curr_net_savings),
        "curr_savings_rate": curr_savings_rate,
        "prev_expense": float(prev_expense),
        "mom_expense_diff": float(mom_expense_diff),
        "top_category": sorted_categories[0][0] if sorted_categories else None,
        "budgets_count": len(budgets),
        "goals_count": len(goals),
        "transactions_count": len(all_txs),
    }

    return raw_data, facts_used


def generate_grounded_ai_response(
    db: Session,
    user: User,
    user_message: str,
    conversation_id: Optional[str] = None,
) -> Tuple[str, List[str]]:
    """
    Validates Gemini configuration, computes deterministic facts, invokes Gemini with grounding rules,
    and returns (answer, facts_used).
    """
    # 1. Check API Key configuration
    api_key = settings.GEMINI_API_KEY
    if not api_key or not api_key.strip():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "ai_not_configured",
                "message": "Gemini AI is not configured on the server. Please add GEMINI_API_KEY to your server environment or backend/.env file.",
            },
        )

    # 2. Calculate Grounded Facts in Python
    _, facts_used = calculate_user_financial_facts(db, user)

    facts_text = "\n".join([f"- {fact}" for fact in facts_used])
    prompt_content = (
        f"COMPUTED FINANCIAL FACTS (Strictly ground your answer on these):\n"
        f"{facts_text}\n\n"
        f"USER QUESTION:\n{user_message}"
    )

    # 3. Invoke Gemini (with retries for transient provider hiccups)
    try:
        from google import genai
        from google.genai import types
        from google.genai.errors import APIError, ClientError
        import time

        client = genai.Client(api_key=api_key)
        last_err: Exception | None = None
        for attempt in range(3):
            try:
                response = client.models.generate_content(
                    model="gemini-3.8-flash",
                    contents=prompt_content,
                    config=types.GenerateContentConfig(
                        system_instruction=SYSTEM_INSTRUCTION,
                        temperature=0.2,
                    ),
                )
                answer = response.text or "I reviewed your financial records, but could not produce a response."
                return answer.strip(), facts_used
            except (ClientError, APIError) as e:
                err_str = str(e).lower()
                err_code = getattr(e, "code", None)
                # Transient overload / rate limit — back off and retry.
                if (
                    err_code in (429, 500, 502, 503)
                    or "unavailable" in err_str
                    or "overloaded" in err_str
                    or "resource_exhausted" in err_str
                ):
                    last_err = e
                    time.sleep(2 * (attempt + 1))
                    continue
                raise
        # Retries exhausted — let the handlers below report the last error.
        assert last_err is not None
        raise last_err

    except (ClientError, APIError) as e:
        err_str = str(e).lower()
        err_code = getattr(e, "code", None)
        # Authentication / API key invalid
        if "api_key_invalid" in err_str or "invalid api key" in err_str or "forbidden" in err_str or err_code in (400, 401, 403):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail={
                    "code": "ai_not_configured",
                    "message": "Invalid Gemini API key configured on server. Please verify GEMINI_API_KEY in backend/.env.",
                },
            )
        # Rate limits
        if "resource_exhausted" in err_str or err_code == 429:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "code": "rate_limited",
                    "message": "AI service is currently rate limited or quota exceeded. Please wait a moment and try again.",
                },
            )
        # Other provider errors
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "code": "ai_provider_error",
                "message": "Gemini AI provider encountered an error. Please try again shortly.",
            },
        )
    except TimeoutError:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail={
                "code": "ai_timeout",
                "message": "The AI assistant request timed out while analyzing your data. Please try again.",
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "code": "ai_provider_error",
                "message": f"AI service unexpected error: {str(e)}",
            },
        )
