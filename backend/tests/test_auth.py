def test_signup_success(client):
    payload = {
        "email": "newuser@example.com",
        "password": "SecurePassword1!",
        "full_name": "New Test User",
        "phone": "+919876543210",
    }
    response = client.post("/api/v1/auth/signup", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "newuser@example.com"
    assert data["user"]["full_name"] == "New Test User"
    assert data["user"]["currency"] == "INR"


def test_signup_duplicate_email(client, user_a_data):
    # First signup
    resp1 = client.post("/api/v1/auth/signup", json=user_a_data)
    assert resp1.status_code == 201

    # Duplicate signup attempt
    resp2 = client.post("/api/v1/auth/signup", json=user_a_data)
    assert resp2.status_code == 400
    assert "already registered" in resp2.json()["detail"].lower()


def test_signup_weak_password_rejected(client):
    # Too short (< 8 chars)
    resp = client.post(
        "/api/v1/auth/signup",
        json={"email": "short@example.com", "password": "123", "full_name": "Short Pw"},
    )
    assert resp.status_code in (400, 422)

    # Missing letter
    resp = client.post(
        "/api/v1/auth/signup",
        json={"email": "noletter@example.com", "password": "1234567890", "full_name": "No Letter"},
    )
    assert resp.status_code == 400
    assert "letter" in resp.json()["detail"].lower()

    # Missing digit
    resp = client.post(
        "/api/v1/auth/signup",
        json={"email": "nodigit@example.com", "password": "abcdefghijkl", "full_name": "No Digit"},
    )
    assert resp.status_code == 400
    assert "digit" in resp.json()["detail"].lower()


def test_signup_invalid_email(client):
    resp = client.post(
        "/api/v1/auth/signup",
        json={"email": "not-an-email", "password": "Password123!", "full_name": "Bad Email"},
    )
    assert resp.status_code == 422


def test_login_json_success(client, user_a_data):
    # Signup
    client.post("/api/v1/auth/signup", json=user_a_data)

    # Login with JSON
    response = client.post(
        "/api/v1/auth/login",
        json={"email": user_a_data["email"], "password": user_a_data["password"]},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == user_a_data["email"]


def test_login_form_success(client, user_a_data):
    # Signup
    client.post("/api/v1/auth/signup", json=user_a_data)

    # Login with OAuth2 form-data (username/password)
    response = client.post(
        "/api/v1/auth/login",
        data={"username": user_a_data["email"], "password": user_a_data["password"]},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_invalid_password(client, user_a_data):
    client.post("/api/v1/auth/signup", json=user_a_data)

    response = client.post(
        "/api/v1/auth/login",
        json={"email": user_a_data["email"], "password": "WrongPassword!"},
    )
    assert response.status_code == 401
    assert "incorrect email or password" in response.json()["detail"].lower()


def test_login_nonexistent_user(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "nonexistent@example.com", "password": "Password123!"},
    )
    assert response.status_code == 401


def test_token_refresh(client, user_a_data):
    signup_resp = client.post("/api/v1/auth/signup", json=user_a_data)
    refresh_token = signup_resp.json()["refresh_token"]

    resp = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_token_refresh_with_invalid_token(client):
    resp = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "totally.invalid.jwt"},
    )
    assert resp.status_code == 401


def test_token_refresh_with_access_token_rejected(client, user_a_data):
    signup_resp = client.post("/api/v1/auth/signup", json=user_a_data)
    access_token = signup_resp.json()["access_token"]

    # Passing an access token to the refresh endpoint must fail
    resp = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": access_token},
    )
    assert resp.status_code == 401
    assert "token type" in resp.json()["detail"].lower()


def test_get_current_user_me(client, auth_headers_user_a, user_a_data):
    resp = client.get("/api/v1/auth/me", headers=auth_headers_user_a)
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == user_a_data["email"]
    assert data["full_name"] == user_a_data["full_name"]
    assert "hashed_password" not in data


def test_get_me_unauthorized(client):
    resp = client.get("/api/v1/auth/me")
    assert resp.status_code == 401


def test_password_reset_request(client, user_a_data):
    client.post("/api/v1/auth/signup", json=user_a_data)

    # Registered user
    resp = client.post(
        "/api/v1/auth/password-reset",
        json={"email": user_a_data["email"]},
    )
    assert resp.status_code == 200
    assert "instructions" in resp.json()["message"].lower()

    # Unregistered user (no leak, same message format)
    resp2 = client.post(
        "/api/v1/auth/password-reset",
        json={"email": "nobody@example.com"},
    )
    assert resp2.status_code == 200
    assert "instructions" in resp2.json()["message"].lower()


def test_logout(client, auth_headers_user_a):
    resp = client.post("/api/v1/auth/logout", headers=auth_headers_user_a)
    assert resp.status_code == 200
    assert "successfully logged out" in resp.json()["message"].lower()
