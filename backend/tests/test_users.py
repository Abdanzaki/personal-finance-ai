def test_get_user_profile(client, auth_headers_user_a):
    response = client.get("/api/v1/users/me", headers=auth_headers_user_a)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "user_a@example.com"
    assert data["full_name"] == "User Alpha"
    assert data["currency"] == "INR"


def test_get_user_profile_unauthorized(client):
    response = client.get("/api/v1/users/me")
    assert response.status_code == 401


def test_patch_user_profile(client, auth_headers_user_a):
    response = client.patch(
        "/api/v1/users/me",
        json={
            "full_name": "User Alpha Renamed",
            "phone": "+919988776655",
            "monthly_income_target": "95000.00",
            "monthly_savings_target": "30000.00",
        },
        headers=auth_headers_user_a,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["full_name"] == "User Alpha Renamed"
    assert data["phone"] == "+919988776655"
    assert float(data["monthly_income_target"]) == 95000.00
    assert float(data["monthly_savings_target"]) == 30000.00

    # Verify persistent via GET
    get_resp = client.get("/api/v1/users/me", headers=auth_headers_user_a)
    assert get_resp.status_code == 200
    assert get_resp.json()["full_name"] == "User Alpha Renamed"
