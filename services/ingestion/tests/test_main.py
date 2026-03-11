"""Tests for ingestion service."""

from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_health():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "ingestion"}


def test_ingest():
    """Test ingest endpoint."""
    response = client.post("/ingest", json={"source": "test-sensor"})
    assert response.status_code == 200
    assert response.json()["status"] == "accepted"
