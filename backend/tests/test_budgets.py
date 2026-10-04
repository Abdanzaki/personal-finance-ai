def test_create_budget_success(client, auth_headers_user_a):
    budget_data = {
        "category": "Dining Out",
        "limit_amount": "8000.00",
        "period_month": "2025-03",
    }
    resp = client.post("/api/v1/budgets", json=budget_data, headers=auth_headers_user_a)
    assert resp.status_code == 201
    data = resp.json()
    assert data["category"] == "Dining Out"
    assert float(data["limit_amount"]) == 8000.00
    assert data["period_month"] == "2025-03"
    assert float(data["spent_amount"]) == 0.00
    assert float(data["remaining_amount"]) == 8000.00
    assert data["percentage_used"] == 0.0
    assert not data["is_warning"]
    assert not data["is_exceeded"]


def test_create_duplicate_budget_rejected(client, auth_headers_user_a):
    budget_data = {
        "category": "Dining Out",
        "limit_amount": "8000.00",
        "period_month": "2025-03",
    }
    resp1 = client.post("/api/v1/budgets", json=budget_data, headers=auth_headers_user_a)
    assert resp1.status_code == 201

    # Attempt to create duplicate for same category and month
    resp2 = client.post("/api/v1/budgets", json=budget_data, headers=auth_headers_user_a)
    assert resp2.status_code == 400
    assert "already exists" in resp2.json()["detail"].lower()


def test_budget_spent_calculation_and_thresholds(client, auth_headers_user_a):
    # Create budget for Groceries: limit 10,000 for 2025-03
    b_resp = client.post(
        "/api/v1/budgets",
        json={"category": "Groceries", "limit_amount": "10000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )
    assert b_resp.status_code == 201
    budget_id = b_resp.json()["id"]

    # 1. Under 80%: spent 5,000 (50%)
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "5000.00",
            "description": "Mid-month bulk grocery",
            "category": "Groceries",
            "date": "2025-03-05T12:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    get1 = client.get(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    assert get1.status_code == 200
    d1 = get1.json()
    assert float(d1["spent_amount"]) == 5000.00
    assert float(d1["remaining_amount"]) == 5000.00
    assert d1["percentage_used"] == 50.0
    assert not d1["is_warning"]
    assert not d1["is_exceeded"]

    # 2. At or over 80%: add 3,200 (total 8,200 = 82% -> is_warning True, is_exceeded False)
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "3200.00",
            "description": "Weekly organic store",
            "category": "Groceries",
            "date": "2025-03-15T14:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    get2 = client.get(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    d2 = get2.json()
    assert float(d2["spent_amount"]) == 8200.00
    assert float(d2["remaining_amount"]) == 1800.00
    assert d2["percentage_used"] == 82.0
    assert d2["is_warning"] is True
    assert d2["is_exceeded"] is False

    # 3. Exceeded (>=100%): add 2,000 (total 10,200 = 102% -> is_warning True, is_exceeded True)
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "2000.00",
            "description": "Special dinner ingredients",
            "category": "Groceries",
            "date": "2025-03-25T18:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    get3 = client.get(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    d3 = get3.json()
    assert float(d3["spent_amount"]) == 10200.00
    assert float(d3["remaining_amount"]) == 0.00
    assert d3["percentage_used"] == 102.0
    assert d3["is_warning"] is True
    assert d3["is_exceeded"] is True

    # 4. Ensure income transaction in Groceries does NOT increase spent_amount
    client.post(
        "/api/v1/transactions",
        json={
            "type": "income",
            "amount": "500.00",
            "description": "Grocery refund cashback",
            "category": "Groceries",
            "date": "2025-03-26T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    get4 = client.get(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    assert float(get4.json()["spent_amount"]) == 10200.00

    # 5. Ensure expense in a different month (e.g. 2025-02) does NOT affect 2025-03 budget
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "4000.00",
            "description": "February grocery",
            "category": "Groceries",
            "date": "2025-02-15T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    get5 = client.get(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    assert float(get5.json()["spent_amount"]) == 10200.00


def test_list_budgets_by_month(client, auth_headers_user_a):
    client.post(
        "/api/v1/budgets",
        json={"category": "Transport", "limit_amount": "5000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )
    client.post(
        "/api/v1/budgets",
        json={"category": "Utilities", "limit_amount": "3000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )

    resp = client.get("/api/v1/budgets?month=2025-03", headers=auth_headers_user_a)
    assert resp.status_code == 200
    data = resp.json()
    assert data["month"] == "2025-03"
    assert float(data["total_budget"]) == 8000.00
    assert len(data["items"]) == 2


def test_update_budget_limit(client, auth_headers_user_a):
    b_resp = client.post(
        "/api/v1/budgets",
        json={"category": "Shopping", "limit_amount": "10000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )
    budget_id = b_resp.json()["id"]

    # Update limit to 15000
    update_resp = client.put(
        f"/api/v1/budgets/{budget_id}",
        json={"limit_amount": "15000.00"},
        headers=auth_headers_user_a,
    )
    assert update_resp.status_code == 200
    assert float(update_resp.json()["limit_amount"]) == 15000.00


def test_delete_budget(client, auth_headers_user_a):
    b_resp = client.post(
        "/api/v1/budgets",
        json={"category": "Subscriptions", "limit_amount": "2000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )
    budget_id = b_resp.json()["id"]

    del_resp = client.delete(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    assert del_resp.status_code == 200

    get_resp = client.get(f"/api/v1/budgets/{budget_id}", headers=auth_headers_user_a)
    assert get_resp.status_code == 404
