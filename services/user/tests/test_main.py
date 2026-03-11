"""Tests for user service."""

from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_health():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "user"}


def test_get_user():
    """Test get user endpoint."""
    response = client.get("/users/123")
    assert response.status_code == 200
    assert response.json()["user_id"] == "123"
