def test_dashboard_summary(client, auth_headers_user_a):
    response = client.get("/api/v1/dashboard/summary", headers=auth_headers_user_a)
    assert response.status_code == 200
    data = response.json()
    assert "total_balance" in data
    assert "monthly_in" in data
    assert "monthly_out" in data
    assert "net_savings" in data
    assert "savings_rate_pct" in data
    assert "recent_transactions" in data
    assert "ai_pulse" in data


def test_reports_summary_and_export(client, auth_headers_user_a):
    # Add a transaction first
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "1200.00",
            "description": "Book purchase",
            "category": "Education",
            "date": "2025-03-15T10:00:00Z",
            "payment_method": "UPI",
        },
        headers=auth_headers_user_a,
    )

    # Summary
    summary_resp = client.get("/api/v1/reports/summary", headers=auth_headers_user_a)
    assert summary_resp.status_code == 200
    summary_data = summary_resp.json()
    assert summary_data["audit_ready"] is True
    assert summary_data["tax_80c_limit"] == 150000.0

    # CSV Export
    export_resp = client.get("/api/v1/reports/export?format=csv", headers=auth_headers_user_a)
    assert export_resp.status_code == 200
    assert "text/csv" in export_resp.headers["content-type"]
    assert "Book purchase" in export_resp.text
    assert "Education" in export_resp.text


def test_insights(client, auth_headers_user_a):
    response = client.get("/api/v1/insights", headers=auth_headers_user_a)
    assert response.status_code == 200
    data = response.json()
    assert "largest_expense_category" in data
    assert "mom_spending_change_pct" in data


def test_ai_chat_unconfigured_mode(client, auth_headers_user_a):
    response = client.post(
        "/api/v1/ai/chat",
        json={"message": "What is my top category this month?"},
        headers=auth_headers_user_a,
    )
    assert response.status_code == 503
    data = response.json()
    assert data["detail"]["code"] == "ai_not_configured"
    assert "not configured" in data["detail"]["message"].lower()
