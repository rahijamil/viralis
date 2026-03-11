"""Tests for crawler service."""

from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_health():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "crawler"}


def test_crawl():
    """Test crawl endpoint."""
    response = client.post("/crawl?url=http://example.com")
    assert response.status_code == 200
    assert response.json()["status"] == "crawling"

    response = client.post("/crawl?url=invalid")
    assert response.status_code == 200
    assert response.json()["status"] == "error"
