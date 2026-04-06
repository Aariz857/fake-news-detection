"""
Pydantic schemas for analysis request/response validation.
"""

from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import uuid


class SourceInfo(BaseModel):
    """Individual news source details."""
    title: str = Field(..., description="Article headline")
    source: str = Field(..., description="News source name")
    url: str = Field(..., description="Article URL")
    published_at: Optional[str] = Field(None, description="Publication date")
    credibility_tier: str = Field(
        "unknown", description="Source credibility: high, medium, low, unknown"
    )
    similarity_score: float = Field(
        0.0, description="Semantic similarity to extracted text (0-1)"
    )


class ImageAnalysis(BaseModel):
    """Image content analysis results."""
    content_type: str = Field(
        "unknown", description="Type: screenshot, photo, meme, graphic, text_heavy"
    )
    confidence: float = Field(0.0, description="Classification confidence")
    description: str = Field("", description="Brief image description")


class PredictionResult(BaseModel):
    """ML model prediction output."""
    label: str = Field(..., description="REAL or FAKE")
    confidence: float = Field(..., description="Model confidence (0-1)")
    real_probability: float = Field(..., description="Probability of being real")
    fake_probability: float = Field(..., description="Probability of being fake")
    model_used: str = Field("mock", description="Model identifier")


class ScoreBreakdown(BaseModel):
    """Detailed scoring breakdown."""
    ai_prediction: float = Field(0.0, description="Score from AI model (0-40)")
    source_coverage: float = Field(0.0, description="Score from source count (0-30)")
    source_quality: float = Field(0.0, description="Score from source credibility (0-20)")
    image_analysis: float = Field(0.0, description="Score from image analysis (0-10)")


class CredibilityScore(BaseModel):
    """Final credibility assessment."""
    score: int = Field(..., description="Overall credibility score (0-100)")
    level: str = Field(..., description="HIGH, MEDIUM, or LOW")
    breakdown: ScoreBreakdown


class AnalysisResponse(BaseModel):
    """Complete analysis response returned to the client."""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: str = Field(
        default_factory=lambda: datetime.utcnow().isoformat() + "Z"
    )
    status: str = Field("success", description="Processing status")

    # OCR
    extracted_text: str = Field("", description="Text extracted from image via OCR")
    text_language: str = Field("en", description="Detected language")

    # Image Analysis
    image_analysis: ImageAnalysis = Field(default_factory=ImageAnalysis)

    # ML Prediction
    prediction: PredictionResult

    # Sources
    sources: dict = Field(default_factory=lambda: {
        "total_found": 0,
        "trusted_sources": 0,
        "articles": []
    })

    # Credibility
    credibility_score: CredibilityScore

    # Explanation
    explanation: str = Field("", description="AI-generated explanation")

    # Final Verdict
    verdict: str = Field("UNKNOWN", description="Final verdict string")


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "healthy"
    version: str = ""
    mock_mode: bool = True
    services: dict = Field(default_factory=dict)
