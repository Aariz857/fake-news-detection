"""
Tests for history endpoints and service.
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services.history_service import history_service

client = TestClient(app)


def _create_mock_result(result_id: str = "test-123") -> dict:
    """Create a mock analysis result dict."""
    return {
        "id": result_id,
        "timestamp": "2026-04-06T12:00:00Z",
        "status": "success",
        "extracted_text": "Test news content for testing purposes",
        "text_language": "en",
        "image_analysis": {
            "content_type": "screenshot",
            "confidence": 0.85,
            "description": "test image",
        },
        "prediction": {
            "label": "FAKE",
            "confidence": 0.78,
            "real_probability": 0.22,
            "fake_probability": 0.78,
            "model_used": "mock",
        },
        "sources": {
            "total_found": 3,
            "trusted_sources": 1,
            "articles": [],
        },
        "credibility_score": {
            "score": 35,
            "level": "LOW",
            "breakdown": {
                "ai_prediction": 10,
                "source_coverage": 12,
                "source_quality": 8,
                "image_analysis": 5,
            },
        },
        "explanation": "Test explanation",
        "verdict": "LIKELY FAKE",
    }


class TestHistoryService:
    """Unit tests for the HistoryService."""

    def setup_method(self):
        """Clear history before each test."""
        history_service.clear()

    def test_save_and_retrieve(self):
        """Should save a result and retrieve it by ID."""
        result = _create_mock_result("svc-001")
        history_service.save_result(result)

        retrieved = history_service.get_by_id("svc-001")
        assert retrieved is not None
        assert retrieved["id"] == "svc-001"

    def test_get_all_returns_summaries(self):
        """get_all should return entries without full_result."""
        history_service.save_result(_create_mock_result("svc-002"))
        entries = history_service.get_all()
        assert len(entries) == 1
        assert "full_result" not in entries[0]
        assert entries[0]["id"] == "svc-002"

    def test_most_recent_first(self):
        """History should be ordered most recent first."""
        history_service.save_result(_create_mock_result("older"))
        history_service.save_result(_create_mock_result("newer"))
        entries = history_service.get_all()
        assert entries[0]["id"] == "newer"
        assert entries[1]["id"] == "older"

    def test_delete_by_id(self):
        """Should delete a specific entry."""
        history_service.save_result(_create_mock_result("del-001"))
        assert history_service.count == 1
        history_service.delete_by_id("del-001")
        assert history_service.count == 0

    def test_clear(self):
        """Should clear all entries."""
        for i in range(5):
            history_service.save_result(_create_mock_result(f"clr-{i}"))
        assert history_service.count == 5
        history_service.clear()
        assert history_service.count == 0

    def test_max_capacity(self):
        """Should evict oldest entries when exceeding max capacity."""
        for i in range(55):
            history_service.save_result(_create_mock_result(f"cap-{i}"))
        assert history_service.count == 50

    def test_get_nonexistent_id(self):
        """Should return None for nonexistent ID."""
        result = history_service.get_by_id("does-not-exist")
        assert result is None


class TestHistoryEndpoints:
    """Tests for history REST endpoints."""

    def setup_method(self):
        """Clear history before each test."""
        client.delete("/api/v1/history")

    def test_list_empty_history(self):
        """Should return empty list when no history."""
        response = client.get("/api/v1/history")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert data["entries"] == []

    def test_list_history_after_save(self):
        """Should list saved entries."""
        history_service.save_result(_create_mock_result("api-001"))
        response = client.get("/api/v1/history")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["entries"][0]["id"] == "api-001"

    def test_get_by_id(self):
        """Should return full result by ID."""
        history_service.save_result(_create_mock_result("api-002"))
        response = client.get("/api/v1/history/api-002")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "api-002"
        assert data["verdict"] == "LIKELY FAKE"

    def test_get_nonexistent_id_returns_404(self):
        """Should return 404 for nonexistent ID."""
        response = client.get("/api/v1/history/nonexistent")
        assert response.status_code == 404

    def test_delete_single_entry(self):
        """Should delete a specific entry."""
        history_service.save_result(_create_mock_result("api-003"))
        response = client.delete("/api/v1/history/api-003")
        assert response.status_code == 200

        # Verify it's gone
        check = client.get("/api/v1/history/api-003")
        assert check.status_code == 404

    def test_delete_nonexistent_returns_404(self):
        """Should return 404 when deleting nonexistent entry."""
        response = client.delete("/api/v1/history/nonexistent")
        assert response.status_code == 404

    def test_clear_all(self):
        """Should clear all history."""
        for i in range(3):
            history_service.save_result(_create_mock_result(f"api-clr-{i}"))
        response = client.delete("/api/v1/history")
        assert response.status_code == 200
        assert response.json()["deleted"] == 3

        # Verify empty
        check = client.get("/api/v1/history")
        assert check.json()["total"] == 0
