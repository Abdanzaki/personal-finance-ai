def test_cross_user_transaction_isolation(client, auth_headers_user_a, auth_headers_user_b):
    # User A creates a transaction
    tx_resp = client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "2500.00",
            "description": "User A Private Expense",
            "category": "Shopping",
            "date": "2025-03-10T12:00:00Z",
            "payment_method": "Credit Card",
        },
        headers=auth_headers_user_a,
    )
    assert tx_resp.status_code == 201
    tx_a_id = tx_resp.json()["id"]

    # User B attempts to GET User A's transaction -> MUST return 404 (never 403)
    get_resp = client.get(f"/api/v1/transactions/{tx_a_id}", headers=auth_headers_user_b)
    assert get_resp.status_code == 404, "Cross-user read must return 404 to avoid leaking existence"

    # User B attempts to UPDATE User A's transaction -> MUST return 404
    put_resp = client.put(
        f"/api/v1/transactions/{tx_a_id}",
        json={"amount": "100.00", "description": "Hacked Transaction"},
        headers=auth_headers_user_b,
    )
    assert put_resp.status_code == 404, "Cross-user update must return 404"

    # User B attempts to DELETE User A's transaction -> MUST return 404
    del_resp = client.delete(f"/api/v1/transactions/{tx_a_id}", headers=auth_headers_user_b)
    assert del_resp.status_code == 404, "Cross-user delete must return 404"

    # Verify User A's transaction is still completely intact
    verify_resp = client.get(f"/api/v1/transactions/{tx_a_id}", headers=auth_headers_user_a)
    assert verify_resp.status_code == 200
    assert float(verify_resp.json()["amount"]) == 2500.00
    assert verify_resp.json()["description"] == "User A Private Expense"


def test_cross_user_budget_isolation(client, auth_headers_user_a, auth_headers_user_b):
    # User A creates a budget
    b_resp = client.post(
        "/api/v1/budgets",
        json={"category": "Healthcare", "limit_amount": "5000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )
    assert b_resp.status_code == 201
    budget_a_id = b_resp.json()["id"]

    # User B attempts to GET User A's budget -> MUST return 404 (never 403)
    get_resp = client.get(f"/api/v1/budgets/{budget_a_id}", headers=auth_headers_user_b)
    assert get_resp.status_code == 404, "Cross-user budget read must return 404"

    # User B attempts to UPDATE User A's budget -> MUST return 404
    put_resp = client.put(
        f"/api/v1/budgets/{budget_a_id}",
        json={"limit_amount": "100.00"},
        headers=auth_headers_user_b,
    )
    assert put_resp.status_code == 404, "Cross-user budget update must return 404"

    # User B attempts to DELETE User A's budget -> MUST return 404
    del_resp = client.delete(f"/api/v1/budgets/{budget_a_id}", headers=auth_headers_user_b)
    assert del_resp.status_code == 404, "Cross-user budget delete must return 404"

    # Verify User A's budget remains unchanged
    verify_resp = client.get(f"/api/v1/budgets/{budget_a_id}", headers=auth_headers_user_a)
    assert verify_resp.status_code == 200
    assert float(verify_resp.json()["limit_amount"]) == 5000.00


def test_list_transactions_strict_user_scoping(client, auth_headers_user_a, auth_headers_user_b):
    # User A creates 3 transactions
    for i in range(3):
        client.post(
            "/api/v1/transactions",
            json={
                "type": "expense",
                "amount": f"{100 * (i + 1)}.00",
                "description": f"User A Item {i+1}",
                "category": "Personal",
                "date": f"2025-03-0{i+1}T10:00:00Z",
            },
            headers=auth_headers_user_a,
        )

    # User B creates 2 transactions
    for i in range(2):
        client.post(
            "/api/v1/transactions",
            json={
                "type": "income",
                "amount": f"{500 * (i + 1)}.00",
                "description": f"User B Salary {i+1}",
                "category": "Salary",
                "date": f"2025-03-0{i+1}T10:00:00Z",
            },
            headers=auth_headers_user_b,
        )

    # User A listing must only see 3 transactions
    list_a = client.get("/api/v1/transactions", headers=auth_headers_user_a).json()
    assert list_a["total"] == 3
    for item in list_a["items"]:
        assert "User A Item" in item["description"]

    # User B listing must only see 2 transactions
    list_b = client.get("/api/v1/transactions", headers=auth_headers_user_b).json()
    assert list_b["total"] == 2
    for item in list_b["items"]:
        assert "User B Salary" in item["description"]


def test_same_budget_category_distinct_users(client, auth_headers_user_a, auth_headers_user_b):
    # Both users create a budget for "Groceries" in "2025-03" — should NOT conflict
    resp_a = client.post(
        "/api/v1/budgets",
        json={"category": "Groceries", "limit_amount": "12000.00", "period_month": "2025-03"},
        headers=auth_headers_user_a,
    )
    assert resp_a.status_code == 201

    resp_b = client.post(
        "/api/v1/budgets",
        json={"category": "Groceries", "limit_amount": "8000.00", "period_month": "2025-03"},
        headers=auth_headers_user_b,
    )
    assert resp_b.status_code == 201

    # Verify User A sees their own limit 12,000
    list_a = client.get("/api/v1/budgets?month=2025-03", headers=auth_headers_user_a).json()
    assert len(list_a["items"]) == 1
    assert float(list_a["items"][0]["limit_amount"]) == 12000.00

    # Verify User B sees their own limit 8,000
    list_b = client.get("/api/v1/budgets?month=2025-03", headers=auth_headers_user_b).json()
    assert len(list_b["items"]) == 1
    assert float(list_b["items"][0]["limit_amount"]) == 8000.00
