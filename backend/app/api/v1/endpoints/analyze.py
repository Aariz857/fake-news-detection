"""
Main analysis endpoint — orchestrates the full fake news detection pipeline.
POST /api/v1/analyze: Upload image → OCR → Classify → Search → Score → Explain
"""

import logging
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.concurrency import run_in_threadpool

from app.services.ocr_service import ocr_service
from app.services.image_service import image_service
from app.services.classifier_service import classifier_service
from app.services.search_service import search_service
from app.services.scorer_service import scorer_service
from app.services.explainer_service import explainer_service
from app.services.history_service import history_service
from app.schemas.analysis import AnalysisResponse, PredictionResult, CredibilityScore, ScoreBreakdown, ImageAnalysis

logger = logging.getLogger(__name__)

router = APIRouter()

# Maximum file size: 10MB
MAX_FILE_SIZE = 10 * 1024 * 1024
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/jpg", "image/webp", "image/bmp"}


@router.post(
    "/analyze",
    response_model=AnalysisResponse,
    summary="Analyze an image for fake news",
    description="Upload an image of news content. The system will extract text, "
    "analyze the image, classify it as real/fake, search for related articles, "
    "calculate a credibility score, and generate an explanation.",
    tags=["Analysis"],
)
async def analyze_image(
    image: UploadFile = File(..., description="Image file (JPEG, PNG, WebP, BMP)")
):
    """
    Full multimodal fake news analysis pipeline.
    
    1. Extract text from image (OCR)
    2. Analyze image content type
    3. Classify text as real/fake
    4. Search for related news articles
    5. Calculate credibility score
    6. Generate AI explanation
    """
    # --- Validate input ---
    if image.content_type and image.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {image.content_type}. "
            f"Allowed: {', '.join(ALLOWED_TYPES)}",
        )

    # Read image bytes
    image_bytes = await image.read()

    if len(image_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Maximum size: {MAX_FILE_SIZE // (1024*1024)}MB",
        )

    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    logger.info(
        f"Processing image: {image.filename} "
        f"({len(image_bytes) / 1024:.1f} KB, {image.content_type})"
    )

    try:
        # --- Stage 1: OCR (CPU-bound, run in thread pool) ---
        logger.info("Stage 1: OCR text extraction...")
        ocr_result = await run_in_threadpool(ocr_service.extract_text, image_bytes)
        extracted_text = ocr_result.get("text", "")

        # --- Stage 2: Image Analysis (CPU-bound) ---
        logger.info("Stage 2: Image analysis...")
        img_analysis = await run_in_threadpool(
            image_service.analyze_image, image_bytes
        )

        # --- Stage 3: Fake News Classification ---
        logger.info("Stage 3: Fake news classification...")
        prediction = await run_in_threadpool(
            classifier_service.predict, extracted_text
        )

        # --- Stage 4: Internet Verification ---
        logger.info("Stage 4: Internet verification...")
        # Extract keywords for search query
        search_query = _extract_search_query(extracted_text)
        sources = await search_service.search_news(search_query, extracted_text)

        # --- Stage 5: Credibility Scoring ---
        logger.info("Stage 5: Credibility scoring...")
        score_result = scorer_service.calculate_score(
            prediction, sources, img_analysis
        )

        # --- Stage 6: Generate Verdict ---
        verdict = scorer_service.generate_verdict(
            score_result["score"], prediction
        )

        # --- Stage 7: AI Explanation ---
        logger.info("Stage 6: Generating explanation...")
        explanation = await explainer_service.generate_explanation(
            extracted_text, prediction, sources, score_result, img_analysis
        )

        # --- Build Response ---
        response = AnalysisResponse(
            status="success",
            extracted_text=extracted_text,
            text_language=ocr_result.get("language", "en"),
            image_analysis=ImageAnalysis(
                content_type=img_analysis.get("content_type", "unknown"),
                confidence=img_analysis.get("confidence", 0),
                description=img_analysis.get("description", ""),
            ),
            prediction=PredictionResult(
                label=prediction["label"],
                confidence=prediction["confidence"],
                real_probability=prediction["real_probability"],
                fake_probability=prediction["fake_probability"],
                model_used=prediction["model_used"],
            ),
            sources={
                "total_found": sources["total_found"],
                "trusted_sources": sources["trusted_sources"],
                "articles": sources["articles"],
            },
            credibility_score=CredibilityScore(
                score=score_result["score"],
                level=score_result["level"],
                breakdown=ScoreBreakdown(**score_result["breakdown"]),
            ),
            explanation=explanation,
            verdict=verdict,
        )

        logger.info(
            f"Analysis complete: {verdict} "
            f"(score: {score_result['score']}/100, "
            f"prediction: {prediction['label']})"
        )

        # Save to history
        try:
            history_service.save_result(response.model_dump())
        except Exception as e:
            logger.warning(f"Failed to save to history: {e}")

        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"Analysis pipeline failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed: {str(e)}",
        )


def _extract_search_query(text: str) -> str:
    """
    Extract meaningful search keywords from OCR text.
    Takes the first meaningful sentence or first N words.
    """
    if not text:
        return "news"

    # Clean and split
    import re

    # Remove URLs
    text = re.sub(r"http\S+", "", text)
    # Take first 100 chars (roughly a headline)
    snippet = text[:150].strip()

    # Split into words and take first meaningful ones
    words = snippet.split()
    # Filter short/noise words
    meaningful = [w for w in words if len(w) > 2]

    # Return first 8 keywords
    query = " ".join(meaningful[:8])
    return query if query else "news"
