"""
Application configuration using Pydantic BaseSettings.
Reads from environment variables and .env file.
"""

from pydantic_settings import BaseSettings
from typing import List, Optional
import os


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # --- App ---
    APP_NAME: str = "Fake News Detector API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # --- CORS ---
    CORS_ORIGINS: List[str] = ["*"]

    # --- API Keys (optional for MVP — mock mode if not set) ---
    NEWSAPI_KEY: Optional[str] = None
    GOOGLE_API_KEY: Optional[str] = None
    GOOGLE_CX_ID: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None

    # --- Model Paths ---
    BERT_MODEL_NAME: str = "jy46604790/Fake-News-Bert-Detect"
    USE_GPU: bool = False  # CPU-only mode

    # --- Tesseract ---
    TESSERACT_CMD: Optional[str] = None  # Auto-detect if None

    # --- Mock Mode ---
    MOCK_MODE: bool = True  # Use mock responses when API keys are missing

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Singleton settings instance
settings = Settings()

# Auto-detect Tesseract path on Windows
if settings.TESSERACT_CMD is None:
    default_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.path.exists(default_path):
        settings.TESSERACT_CMD = default_path
