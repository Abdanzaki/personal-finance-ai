from datetime import datetime, timezone


def test_create_transaction_success(client, auth_headers_user_a):
    tx_data = {
        "type": "expense",
        "amount": "1250.50",
        "description": "Weekly Groceries at Blinkit",
        "category": "Groceries",
        "date": "2025-03-15T10:30:00Z",
        "payment_method": "UPI",
    }
    resp = client.post("/api/v1/transactions", json=tx_data, headers=auth_headers_user_a)
    assert resp.status_code == 201
    data = resp.json()
    assert data["type"] == "expense"
    assert float(data["amount"]) == 1250.50
    assert data["description"] == "Weekly Groceries at Blinkit"
    assert data["category"] == "Groceries"
    assert "id" in data
    assert "created_at" in data


def test_create_transaction_income(client, auth_headers_user_a):
    tx_data = {
        "type": "income",
        "amount": "85000.00",
        "description": "Monthly Salary",
        "category": "Salary",
        "date": "2025-03-01T09:00:00Z",
        "payment_method": "Bank Transfer",
    }
    resp = client.post("/api/v1/transactions", json=tx_data, headers=auth_headers_user_a)
    assert resp.status_code == 201
    assert resp.json()["type"] == "income"
    assert float(resp.json()["amount"]) == 85000.00


def test_create_transaction_negative_amount_rejected(client, auth_headers_user_a):
    tx_data = {
        "type": "expense",
        "amount": "-500.00",
        "description": "Invalid Negative Amount",
        "category": "Shopping",
        "date": "2025-03-15T10:30:00Z",
    }
    resp = client.post("/api/v1/transactions", json=tx_data, headers=auth_headers_user_a)
    assert resp.status_code == 422


def test_create_transaction_zero_amount_rejected(client, auth_headers_user_a):
    tx_data = {
        "type": "expense",
        "amount": "0.00",
        "description": "Zero Amount",
        "category": "Shopping",
        "date": "2025-03-15T10:30:00Z",
    }
    resp = client.post("/api/v1/transactions", json=tx_data, headers=auth_headers_user_a)
    assert resp.status_code == 422


def test_create_transaction_invalid_type_rejected(client, auth_headers_user_a):
    tx_data = {
        "type": "invalid_type",
        "amount": "100.00",
        "description": "Bad Type",
        "category": "Other",
        "date": "2025-03-15T10:30:00Z",
    }
    resp = client.post("/api/v1/transactions", json=tx_data, headers=auth_headers_user_a)
    assert resp.status_code == 422


def test_list_transactions_pagination(client, auth_headers_user_a):
    # Create 5 transactions
    for i in range(5):
        client.post(
            "/api/v1/transactions",
            json={
                "type": "expense",
                "amount": f"{100 + i}.00",
                "description": f"Tx {i}",
                "category": "General",
                "date": f"2025-03-0{i+1}T10:00:00Z",
            },
            headers=auth_headers_user_a,
        )

    # First page: limit 2, skip 0
    resp1 = client.get("/api/v1/transactions?skip=0&limit=2", headers=auth_headers_user_a)
    assert resp1.status_code == 200
    data1 = resp1.json()
    assert data1["total"] == 5
    assert len(data1["items"]) == 2
    assert data1["page"] == 1

    # Second page: limit 2, skip 2
    resp2 = client.get("/api/v1/transactions?skip=2&limit=2", headers=auth_headers_user_a)
    assert resp2.status_code == 200
    data2 = resp2.json()
    assert len(data2["items"]) == 2
    assert data2["page"] == 2


def test_list_transactions_filter_category_and_type(client, auth_headers_user_a):
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "300.00",
            "description": "Starbucks Coffee",
            "category": "Food & Dining",
            "date": "2025-03-10T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "1500.00",
            "description": "Electricity Bill",
            "category": "Utilities",
            "date": "2025-03-11T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    # Filter by category Food & Dining
    resp = client.get("/api/v1/transactions?category=Food", headers=auth_headers_user_a)
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 1
    assert items[0]["category"] == "Food & Dining"

    # Filter by type
    resp_exp = client.get("/api/v1/transactions?type=expense", headers=auth_headers_user_a)
    assert resp_exp.status_code == 200
    assert len(resp_exp.json()["items"]) == 2


def test_list_transactions_search(client, auth_headers_user_a):
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "450.00",
            "description": "Netflix Subscription Monthly",
            "category": "Entertainment",
            "date": "2025-03-05T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "120.00",
            "description": "Spotify Family",
            "category": "Entertainment",
            "date": "2025-03-06T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )

    resp = client.get("/api/v1/transactions?search=Netflix", headers=auth_headers_user_a)
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 1
    assert items[0]["description"] == "Netflix Subscription Monthly"


def test_get_and_update_transaction(client, auth_headers_user_a):
    create_resp = client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "500.00",
            "description": "Swiggy Order",
            "category": "Food",
            "date": "2025-03-12T19:00:00Z",
        },
        headers=auth_headers_user_a,
    )
    tx_id = create_resp.json()["id"]

    # Get single transaction
    get_resp = client.get(f"/api/v1/transactions/{tx_id}", headers=auth_headers_user_a)
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == tx_id

    # Update transaction
    update_resp = client.put(
        f"/api/v1/transactions/{tx_id}",
        json={"amount": "650.00", "description": "Swiggy Dinner with dessert"},
        headers=auth_headers_user_a,
    )
    assert update_resp.status_code == 200
    updated_data = update_resp.json()
    assert float(updated_data["amount"]) == 650.00
    assert updated_data["description"] == "Swiggy Dinner with dessert"
    assert updated_data["category"] == "Food"  # Unchanged


def test_delete_transaction(client, auth_headers_user_a):
    create_resp = client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "100.00",
            "description": "To be deleted",
            "category": "Other",
            "date": "2025-03-12T10:00:00Z",
        },
        headers=auth_headers_user_a,
    )
    tx_id = create_resp.json()["id"]

    # Delete
    del_resp = client.delete(f"/api/v1/transactions/{tx_id}", headers=auth_headers_user_a)
    assert del_resp.status_code == 200

    # Ensure it no longer exists
    get_resp = client.get(f"/api/v1/transactions/{tx_id}", headers=auth_headers_user_a)
    assert get_resp.status_code == 404
