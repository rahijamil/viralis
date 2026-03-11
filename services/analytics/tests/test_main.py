"""Tests for analytics service."""

from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_health():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "analytics"}


def test_stats():
    """Test stats endpoint."""
    response = client.get("/stats")
    assert response.status_code == 200
    assert "stats" in response.json()
