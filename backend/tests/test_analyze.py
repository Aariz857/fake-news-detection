"""
Tests for the analysis endpoint.
"""

import io
import pytest
from fastapi.testclient import TestClient
from PIL import Image

from app.main import app

client = TestClient(app)


def _create_test_image(
    width: int = 200,
    height: int = 200,
    color: str = "white",
    text: str = None,
    fmt: str = "PNG",
) -> bytes:
    """Create a simple test image as bytes."""
    img = Image.new("RGB", (width, height), color)
    if text:
        try:
            from PIL import ImageDraw
            draw = ImageDraw.Draw(img)
            draw.text((10, 10), text, fill="black")
        except Exception:
            pass
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    buf.seek(0)
    return buf.read()


class TestAnalyzeEndpoint:
    """Tests for POST /api/v1/analyze."""

    def test_analyze_with_valid_image(self):
        """Should return 200 and full analysis result for a valid image."""
        image_bytes = _create_test_image(text="Breaking News: Test Story")
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("test.png", image_bytes, "image/png")},
        )
        assert response.status_code == 200
        data = response.json()

        # Verify top-level fields
        assert "id" in data
        assert "timestamp" in data
        assert data["status"] == "success"
        assert "extracted_text" in data
        assert "prediction" in data
        assert "credibility_score" in data
        assert "explanation" in data
        assert "verdict" in data

    def test_analyze_response_prediction_structure(self):
        """Prediction should have label, confidence, and probability fields."""
        image_bytes = _create_test_image()
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("test.png", image_bytes, "image/png")},
        )
        data = response.json()
        prediction = data["prediction"]

        assert "label" in prediction
        assert prediction["label"] in ("REAL", "FAKE", "UNKNOWN")
        assert "confidence" in prediction
        assert 0.0 <= prediction["confidence"] <= 1.0
        assert "real_probability" in prediction
        assert "fake_probability" in prediction
        assert "model_used" in prediction

    def test_analyze_response_credibility_structure(self):
        """Credibility score should have score, level, and breakdown."""
        image_bytes = _create_test_image()
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("test.png", image_bytes, "image/png")},
        )
        data = response.json()
        score = data["credibility_score"]

        assert "score" in score
        assert 0 <= score["score"] <= 100
        assert "level" in score
        assert score["level"] in ("HIGH", "MEDIUM", "LOW")
        assert "breakdown" in score
        breakdown = score["breakdown"]
        assert "ai_prediction" in breakdown
        assert "source_coverage" in breakdown
        assert "source_quality" in breakdown
        assert "image_analysis" in breakdown

    def test_analyze_response_sources_structure(self):
        """Sources should have total_found, trusted_sources, articles."""
        image_bytes = _create_test_image()
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("test.png", image_bytes, "image/png")},
        )
        data = response.json()
        sources = data["sources"]

        assert "total_found" in sources
        assert "trusted_sources" in sources
        assert "articles" in sources
        assert isinstance(sources["articles"], list)

    def test_analyze_rejects_empty_file(self):
        """Should return 400 for an empty file."""
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("empty.png", b"", "image/png")},
        )
        assert response.status_code == 400

    def test_analyze_rejects_invalid_content_type(self):
        """Should return 400 for unsupported file types."""
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("doc.pdf", b"fake pdf content", "application/pdf")},
        )
        assert response.status_code == 400

    def test_analyze_with_jpeg_image(self):
        """Should accept JPEG images."""
        image_bytes = _create_test_image(fmt="JPEG")
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("test.jpg", image_bytes, "image/jpeg")},
        )
        assert response.status_code == 200
        assert response.json()["status"] == "success"

    def test_analyze_saves_to_history(self):
        """Analysis result should be saved to history."""
        # Clear history first
        client.delete("/api/v1/history")

        image_bytes = _create_test_image()
        response = client.post(
            "/api/v1/analyze",
            files={"image": ("test.png", image_bytes, "image/png")},
        )
        assert response.status_code == 200
        result_id = response.json()["id"]

        # Check history
        history = client.get("/api/v1/history")
        entries = history.json()["entries"]
        assert any(e["id"] == result_id for e in entries)
