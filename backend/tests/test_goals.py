def test_create_savings_goal(client, auth_headers_user_a):
    response = client.post(
        "/api/v1/goals",
        json={
            "title": "Emergency Fund",
            "category": "Safety Net",
            "target_amount": "300000.00",
            "initial_deposit": "50000.00",
            "target_date": "2026-12-31",
        },
        headers=auth_headers_user_a,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Emergency Fund"
    assert float(data["target_amount"]) == 300000.00
    assert float(data["current_amount"]) == 50000.00
    assert data["progress_percentage"] == round((50000.0 / 300000.0) * 100, 2)
    assert data["is_completed"] is False


def test_list_goals(client, auth_headers_user_a):
    # Create two goals
    client.post(
        "/api/v1/goals",
        json={
            "title": "Vacation Goa",
            "category": "Travel",
            "target_amount": "50000.00",
            "initial_deposit": "10000.00",
            "target_date": "2025-11-30",
        },
        headers=auth_headers_user_a,
    )
    client.post(
        "/api/v1/goals",
        json={
            "title": "MacBook Pro",
            "category": "Electronics",
            "target_amount": "200000.00",
            "initial_deposit": "50000.00",
            "target_date": "2026-03-31",
        },
        headers=auth_headers_user_a,
    )

    response = client.get("/api/v1/goals", headers=auth_headers_user_a)
    assert response.status_code == 200
    data = response.json()
    assert float(data["total_saved"]) >= 60000.00
    assert float(data["total_target"]) >= 250000.00
    assert len(data["goals"]) >= 2


def test_goal_contributions_and_completion(client, auth_headers_user_a):
    create_resp = client.post(
        "/api/v1/goals",
        json={
            "title": "Bike Upgrade",
            "category": "Vehicle",
            "target_amount": "20000.00",
            "initial_deposit": "10000.00",
            "target_date": "2025-06-30",
        },
        headers=auth_headers_user_a,
    )
    assert create_resp.status_code == 201
    goal_id = create_resp.json()["id"]

    # Add contribution
    contrib_resp = client.post(
        f"/api/v1/goals/{goal_id}/contributions",
        json={
            "amount": "10000.00",
            "date": "2025-04-01T10:00:00Z",
            "note": "Bonus allocation",
        },
        headers=auth_headers_user_a,
    )
    assert contrib_resp.status_code == 201
    contrib_data = contrib_resp.json()
    assert float(contrib_data["amount"]) == 10000.00

    # Verify goal is now completed
    goal_resp = client.get(f"/api/v1/goals/{goal_id}", headers=auth_headers_user_a)
    assert goal_resp.status_code == 200
    goal_data = goal_resp.json()
    assert float(goal_data["current_amount"]) == 20000.00
    assert goal_data["is_completed"] is True
    assert goal_data["progress_percentage"] == 100.0


def test_goal_isolation(client, auth_headers_user_a, auth_headers_user_b):
    # User A creates a goal
    create_resp = client.post(
        "/api/v1/goals",
        json={
            "title": "Secret Goal A",
            "category": "Private",
            "target_amount": "100000.00",
            "target_date": "2026-01-01",
        },
        headers=auth_headers_user_a,
    )
    goal_id = create_resp.json()["id"]

    # User B cannot GET goal
    assert client.get(f"/api/v1/goals/{goal_id}", headers=auth_headers_user_b).status_code == 404

    # User B cannot contribute to User A's goal
    contrib_attempt = client.post(
        f"/api/v1/goals/{goal_id}/contributions",
        json={"amount": "5000.00", "date": "2025-05-01T10:00:00Z"},
        headers=auth_headers_user_b,
    )
    assert contrib_attempt.status_code == 404

    # User B cannot DELETE User A's goal
    assert client.delete(f"/api/v1/goals/{goal_id}", headers=auth_headers_user_b).status_code == 404
