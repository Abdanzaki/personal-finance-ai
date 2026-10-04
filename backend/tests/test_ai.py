from unittest.mock import MagicMock, patch
import pytest
from app.core.config import settings
from google.genai.errors import ClientError


def test_ai_suggestions(client):
    response = client.get("/api/v1/ai/suggestions")
    assert response.status_code == 200
    data = response.json()
    assert "suggestions" in data
    assert len(data["suggestions"]) == 6
    assert "Where did most of my money go this month?" in data["suggestions"]
    assert "Am I exceeding any budgets?" in data["suggestions"]


def test_ai_chat_missing_api_key(client, auth_headers_user_a, monkeypatch):
    monkeypatch.setattr(settings, "GEMINI_API_KEY", None)

    response = client.post(
        "/api/v1/ai/chat",
        json={"message": "Where did most of my money go this month?"},
        headers=auth_headers_user_a,
    )
    assert response.status_code == 503
    data = response.json()
    assert data["detail"]["code"] == "ai_not_configured"
    assert "not configured" in data["detail"]["message"].lower()


def test_ai_chat_invalid_api_key(client, auth_headers_user_a, monkeypatch):
    monkeypatch.setattr(settings, "GEMINI_API_KEY", "invalid_test_api_key")

    with patch("google.genai.Client") as mock_client_cls:
        mock_instance = MagicMock()
        mock_instance.models.generate_content.side_effect = ClientError(
            code=400,
            response_json={"error": {"message": "API key not valid. Please pass a valid API key."}},
        )
        mock_client_cls.return_value = mock_instance

        response = client.post(
            "/api/v1/ai/chat",
            json={"message": "How much did I spend on food?"},
            headers=auth_headers_user_a,
        )
        assert response.status_code == 503
        data = response.json()
        assert data["detail"]["code"] == "ai_not_configured"
        assert "invalid" in data["detail"]["message"].lower()


def test_ai_chat_grounded_answer(client, auth_headers_user_a, monkeypatch):
    monkeypatch.setattr(settings, "GEMINI_API_KEY", "dummy_valid_test_key")

    # Seed User A transactions
    client.post(
        "/api/v1/transactions",
        json={
            "type": "income",
            "amount": "60000.00",
            "description": "Tech Corp Salary",
            "category": "Salary",
            "date": "2025-03-01T09:00:00Z",
            "payment_method": "Bank Transfer",
        },
        headers=auth_headers_user_a,
    )
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "18000.00",
            "description": "Flat Rent",
            "category": "Housing & Rent",
            "date": "2025-03-02T10:00:00Z",
            "payment_method": "UPI",
        },
        headers=auth_headers_user_a,
    )
    client.post(
        "/api/v1/transactions",
        json={
            "type": "expense",
            "amount": "7500.00",
            "description": "Weekly Groceries",
            "category": "Food & Dining",
            "date": "2025-03-10T12:00:00Z",
            "payment_method": "Card",
        },
        headers=auth_headers_user_a,
    )

    # Seed User A budget
    b_resp = client.post(
        "/api/v1/budgets",
        json={
            "category": "Food & Dining",
            "limit_amount": "8000.00",
            "period_month": "2025-03",
        },
        headers=auth_headers_user_a,
    )
    assert b_resp.status_code == 201

    # Seed User A goal
    g_resp = client.post(
        "/api/v1/goals",
        json={
            "title": "Emergency Fund",
            "target_amount": "100000.00",
            "initial_deposit": "25000.00",
            "target_date": "2025-12-31",
            "category": "Emergency",
        },
        headers=auth_headers_user_a,
    )
    assert g_resp.status_code == 201

    captured_prompt = {}

    with patch("google.genai.Client") as mock_client_cls:
        mock_instance = MagicMock()

        def fake_generate_content(model, contents, config=None):
            captured_prompt["contents"] = contents
            captured_prompt["system"] = config.system_instruction if config else None
            mock_resp = MagicMock()
            mock_resp.text = "In March 2025, your highest spending category was Housing & Rent at ₹18,000.00. You also spent ₹7,500.00 on Food & Dining."
            return mock_resp

        mock_instance.models.generate_content.side_effect = fake_generate_content
        mock_client_cls.return_value = mock_instance

        response = client.post(
            "/api/v1/ai/chat",
            json={"message": "Where did most of my money go this month?"},
            headers=auth_headers_user_a,
        )

        assert response.status_code == 200
        data = response.json()
        assert "answer" in data
        assert "facts_used" in data
        assert len(data["facts_used"]) > 0

        # Verify that pre-calculated arithmetic was passed to the model
        prompt_text = captured_prompt["contents"]
        assert "Housing & Rent at ₹18,000.00" in prompt_text
        assert "₹25,500.00" in prompt_text  # Total expense = 18000 + 7500
        assert "₹34,500.00" in prompt_text  # Net savings = 60000 - 25500
        assert "Budget 'Food & Dining'" in prompt_text
        assert "Emergency Fund" in prompt_text

        # Verify model answer
        assert "₹18,000.00" in data["answer"]


def test_ai_chat_cross_user_isolation(client, auth_headers_user_a, auth_headers_user_b, monkeypatch):
    monkeypatch.setattr(settings, "GEMINI_API_KEY", "dummy_valid_test_key")

    with patch("google.genai.Client") as mock_client_cls:
        mock_instance = MagicMock()

        def fake_generate(model, contents, config=None):
            mock_resp = MagicMock()
            mock_resp.text = f"Mocked reply for prompt: {contents[-30:]}"
            return mock_resp

        mock_instance.models.generate_content.side_effect = fake_generate
        mock_client_cls.return_value = mock_instance

        # User A sends a message
        resp_a = client.post(
            "/api/v1/ai/chat",
            json={"message": "User A secret financial query"},
            headers=auth_headers_user_a,
        )
        assert resp_a.status_code == 200

        # User B sends a message
        resp_b = client.post(
            "/api/v1/ai/chat",
            json={"message": "User B distinct question"},
            headers=auth_headers_user_b,
        )
        assert resp_b.status_code == 200

    # User A gets history
    hist_a = client.get("/api/v1/ai/history", headers=auth_headers_user_a)
    assert hist_a.status_code == 200
    msgs_a = hist_a.json()
    assert len(msgs_a) == 2  # user + assistant
    assert msgs_a[0]["content"] == "User A secret financial query"
    assert not any("User B" in m["content"] for m in msgs_a)

    # User B gets history
    hist_b = client.get("/api/v1/ai/history", headers=auth_headers_user_b)
    assert hist_b.status_code == 200
    msgs_b = hist_b.json()
    assert len(msgs_b) == 2
    assert msgs_b[0]["content"] == "User B distinct question"
    assert not any("User A" in m["content"] for m in msgs_b)

    # User A clears history
    del_resp = client.delete("/api/v1/ai/history", headers=auth_headers_user_a)
    assert del_resp.status_code == 200

    # User A history is now empty
    hist_a_after = client.get("/api/v1/ai/history", headers=auth_headers_user_a)
    assert len(hist_a_after.json()) == 0

    # User B history is still intact!
    hist_b_after = client.get("/api/v1/ai/history", headers=auth_headers_user_b)
    assert len(hist_b_after.json()) == 2
