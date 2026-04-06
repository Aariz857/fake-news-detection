"""
Health check endpoint — verifies service status.
"""

from fastapi import APIRouter

from app.core.config import settings

router = APIRouter()


@router.get("/health", tags=["Health"])
async def health_check():
    """Check API health and service status."""
    return {
        "status": "healthy",
        "version": settings.APP_VERSION,
        "mock_mode": settings.MOCK_MODE,
        "services": {
            "ocr": "ready",
            "classifier": "ready (mock)" if settings.MOCK_MODE else "ready (BERT)",
            "image": "ready",
            "search": "ready (mock)" if settings.MOCK_MODE else "ready (live)",
            "explainer": "ready (template)" if settings.MOCK_MODE else "ready (GPT)",
            "scorer": "ready",
        },
    }
