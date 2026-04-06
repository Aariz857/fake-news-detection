"""
OCR Service — Extracts text from images using Tesseract OCR.
Includes image preprocessing for improved accuracy.
"""

import io
import logging
from PIL import Image, ImageFilter, ImageEnhance
import pytesseract

from app.core.config import settings

logger = logging.getLogger(__name__)


class OCRService:
    """Handles text extraction from images using Tesseract OCR."""

    def __init__(self):
        if settings.TESSERACT_CMD:
            pytesseract.pytesseract.tesseract_cmd = settings.TESSERACT_CMD
        logger.info("OCR Service initialized")

    def _preprocess_image(self, image: Image.Image) -> Image.Image:
        """
        Preprocess image for better OCR accuracy.
        Steps: resize → grayscale → contrast enhance → sharpen → threshold
        """
        # Resize if too small (OCR works better with larger text)
        width, height = image.size
        if width < 800:
            ratio = 800 / width
            image = image.resize(
                (int(width * ratio), int(height * ratio)),
                Image.Resampling.LANCZOS
            )

        # Convert to grayscale
        gray = image.convert("L")

        # Enhance contrast
        enhancer = ImageEnhance.Contrast(gray)
        gray = enhancer.enhance(2.0)

        # Sharpen
        gray = gray.filter(ImageFilter.SHARPEN)

        # Apply adaptive threshold (binarization)
        gray = gray.point(lambda x: 0 if x < 140 else 255, "1")

        return gray

    def extract_text(self, image_bytes: bytes) -> dict:
        """
        Extract text from image bytes.
        
        Returns:
            dict with 'text', 'confidence', 'language', 'word_count'
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))

            # Try raw extraction first
            raw_text = pytesseract.image_to_string(image, lang="eng")

            # If raw extraction is poor, try with preprocessing
            if len(raw_text.strip()) < 10:
                processed = self._preprocess_image(image)
                raw_text = pytesseract.image_to_string(processed, lang="eng")

            # Clean up extracted text
            cleaned_text = self._clean_text(raw_text)

            # Get confidence data
            try:
                data = pytesseract.image_to_data(
                    image, output_type=pytesseract.Output.DICT
                )
                confidences = [
                    int(c) for c in data["conf"] if str(c).isdigit() and int(c) > 0
                ]
                avg_confidence = (
                    sum(confidences) / len(confidences) if confidences else 0
                )
            except Exception:
                avg_confidence = 50.0

            word_count = len(cleaned_text.split()) if cleaned_text else 0

            logger.info(
                f"OCR extracted {word_count} words with "
                f"{avg_confidence:.1f}% confidence"
            )

            return {
                "text": cleaned_text,
                "confidence": round(avg_confidence, 2),
                "language": "en",
                "word_count": word_count,
            }

        except Exception as e:
            logger.error(f"OCR extraction failed: {str(e)}")
            return {
                "text": "",
                "confidence": 0.0,
                "language": "en",
                "word_count": 0,
                "error": str(e),
            }

    def _clean_text(self, text: str) -> str:
        """Clean OCR output: remove artifacts, normalize whitespace."""
        if not text:
            return ""

        # Remove common OCR artifacts
        import re

        # Normalize whitespace
        text = re.sub(r"\s+", " ", text)
        # Remove isolated single characters (OCR noise)
        text = re.sub(r"\b[^aAiI\d]\b", "", text)
        # Remove excessive punctuation
        text = re.sub(r"[^\w\s.,!?;:'\"-]", "", text)
        # Final trim
        text = text.strip()

        return text


# Singleton instance
ocr_service = OCRService()
