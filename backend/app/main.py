"""
FastAPI Application Entry Point.
Initializes the app, configures middleware, and includes routers.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.v1.router import api_router
from app.models.ml_models import model_manager

# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan: load models at startup, cleanup at shutdown.
    """
    logger.info("=" * 60)
    logger.info(f"  {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"  Mock Mode: {settings.MOCK_MODE}")
    logger.info(f"  GPU: {'Enabled' if settings.USE_GPU else 'Disabled (CPU)'}")
    logger.info("=" * 60)

    # Load ML models
    model_manager.load_all_models()
    logger.info("Application startup complete ✓")

    yield

    # Cleanup
    model_manager.cleanup()
    logger.info("Application shutdown complete")


# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "Multimodal Fake News Detection API. Upload an image of news content "
        "and receive analysis including text extraction, fake/real classification, "
        "source verification, credibility scoring, and AI-generated explanation."
    ),
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — allow Flutter app and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router)


# Root redirect to docs
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint — redirects to API documentation."""
    return {
        "message": f"Welcome to {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "health": "/api/v1/health",
    }
