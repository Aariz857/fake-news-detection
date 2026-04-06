# ============================================
# Dockerfile — Fake News Detection Backend
# Multi-stage build for optimized production image
# ============================================

FROM python:3.11-slim AS base

# Install system dependencies (Tesseract OCR + image libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
    tesseract-ocr-eng \
    libtesseract-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first (for Docker layer caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set Tesseract path
ENV TESSERACT_CMD=/usr/bin/tesseract

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import httpx; r = httpx.get('http://localhost:8000/api/v1/health'); assert r.status_code == 200"

# Run with Uvicorn — uses PORT env var (Render sets this to 10000)
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1
