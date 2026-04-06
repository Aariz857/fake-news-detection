"""
Tests for health endpoint.
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


class TestHealthEndpoint:
    """Tests for GET /api/v1/health."""

    def test_health_returns_200(self):
        """Health endpoint should return 200 OK."""
        response = client.get("/api/v1/health")
        assert response.status_code == 200

    def test_health_status_is_healthy(self):
        """Health response should indicate healthy status."""
        response = client.get("/api/v1/health")
        data = response.json()
        assert data["status"] == "healthy"

    def test_health_has_version(self):
        """Health response should include version string."""
        response = client.get("/api/v1/health")
        data = response.json()
        assert "version" in data
        assert isinstance(data["version"], str)
        assert len(data["version"]) > 0

    def test_health_has_services(self):
        """Health response should list all service statuses."""
        response = client.get("/api/v1/health")
        data = response.json()
        assert "services" in data
        services = data["services"]
        expected_services = ["ocr", "classifier", "image", "search", "explainer"]
        for svc in expected_services:
            assert svc in services, f"Missing service: {svc}"

    def test_health_has_mock_mode(self):
        """Health response should indicate mock mode status."""
        response = client.get("/api/v1/health")
        data = response.json()
        assert "mock_mode" in data
        assert isinstance(data["mock_mode"], bool)
