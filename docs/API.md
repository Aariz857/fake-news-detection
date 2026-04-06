# API Documentation

## Base URL
- **Local**: `http://localhost:8000`
- **Production**: `https://your-domain.run.app`

## Authentication
Currently no authentication required (MVP). For production, add API key or JWT authentication.

---

## Endpoints

### `GET /`
Root endpoint — returns API info.

**Response:**
```json
{
  "message": "Welcome to Fake News Detector API",
  "version": "1.0.0",
  "docs": "/docs",
  "health": "/api/v1/health"
}
```

---

### `GET /api/v1/health`
Health check — returns service status.

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "mock_mode": false,
  "services": {
    "ocr": "ready",
    "classifier": "ready (BERT)",
    "search": "ready (mock)",
    "explainer": "ready (template)",
    "scorer": "ready"
  }
}
```

---

### `POST /api/v1/analyze`
**Main endpoint** — Upload an image and receive full fake news analysis.

**Request:**
- Content-Type: `multipart/form-data`
- Body: `image` (File) — JPEG, PNG, WebP, or BMP, max 10MB

**Example (curl):**
```bash
curl -X POST "http://localhost:8000/api/v1/analyze" \
  -H "accept: application/json" \
  -F "image=@news_screenshot.jpg"
```

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-04-06T12:00:00Z",
  "status": "success",
  "extracted_text": "Breaking: Major climate report reveals...",
  "text_language": "en",
  "image_analysis": {
    "content_type": "screenshot",
    "confidence": 0.75,
    "description": "Appears to be a screenshot with text content"
  },
  "prediction": {
    "label": "REAL",
    "confidence": 0.87,
    "real_probability": 0.87,
    "fake_probability": 0.13,
    "model_used": "jy46604790/Fake-News-Bert-Detect"
  },
  "sources": {
    "total_found": 5,
    "trusted_sources": 3,
    "articles": [
      {
        "title": "Climate Report: Reuters Reports on Developing Story",
        "source": "Reuters",
        "url": "https://example.com/reuters/article-1",
        "published_at": "2026-04-05T10:00:00Z",
        "credibility_tier": "high",
        "similarity_score": 0.89
      }
    ]
  },
  "credibility_score": {
    "score": 72,
    "level": "HIGH",
    "breakdown": {
      "ai_prediction": 34.8,
      "source_coverage": 21.0,
      "source_quality": 13.2,
      "image_analysis": 6.0
    }
  },
  "explanation": "✅ Our analysis indicates this content appears to be REAL...",
  "verdict": "LIKELY REAL"
}
```

**Error Responses:**

| Status | Description |
|--------|-------------|
| 400 | Invalid file type, file too large, or empty file |
| 500 | Internal processing error |

---

## Pipeline Stages

The `/api/v1/analyze` endpoint runs these stages sequentially:

| Stage | Service | Description |
|-------|---------|-------------|
| 1 | OCR Service | Extract text using Tesseract with preprocessing |
| 2 | Image Service | Classify image type (screenshot, photo, meme) |
| 3 | Classifier | BERT model predicts REAL vs FAKE probability |
| 4 | Search Service | Find related articles from news APIs |
| 5 | Scorer | Combine signals into 0-100 credibility score |
| 6 | Explainer | Generate human-readable analysis explanation |

## Scoring Weights

| Component | Weight | Max Score |
|-----------|--------|-----------|
| AI Prediction | 40% | 40 |
| Source Coverage | 30% | 30 |
| Source Quality | 20% | 20 |
| Image Analysis | 10% | 10 |
| **Total** | **100%** | **100** |

## Verdict Mapping

| Score Range | Verdict |
|-------------|---------|
| 80-100 | HIGHLY CREDIBLE |
| 65-79 | LIKELY REAL |
| 45-64 | UNCERTAIN — VERIFY INDEPENDENTLY |
| 25-44 | LIKELY FAKE |
| 0-24 | HIGHLY SUSPICIOUS |
