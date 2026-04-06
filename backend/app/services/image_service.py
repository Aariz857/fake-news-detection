"""
Image Analysis Service — Simplified image understanding for MVP.
Uses basic image analysis (no heavy deep learning model yet).
Phase 2 will add ResNet-50 feature extraction.
"""

import io
import logging
from PIL import Image
import hashlib

logger = logging.getLogger(__name__)


class ImageService:
    """Analyzes image properties and content type."""

    def __init__(self):
        logger.info("Image Service initialized (MVP mode)")

    def analyze_image(self, image_bytes: bytes) -> dict:
        """
        Analyze image to determine content type and properties.
        
        MVP: Uses heuristics (aspect ratio, color distribution, etc.)
        Phase 2: Will use ResNet-50 for proper image classification.
        
        Returns:
            dict with 'content_type', 'confidence', 'description', 'metadata'
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))
            width, height = image.size
            aspect_ratio = width / height if height > 0 else 1.0
            mode = image.mode

            # Determine content type based on heuristics
            content_type, confidence, description = self._classify_content(
                image, width, height, aspect_ratio
            )

            # Generate image hash for deduplication
            img_hash = hashlib.md5(image_bytes).hexdigest()

            result = {
                "content_type": content_type,
                "confidence": round(confidence, 2),
                "description": description,
                "metadata": {
                    "width": width,
                    "height": height,
                    "aspect_ratio": round(aspect_ratio, 2),
                    "format": image.format or "unknown",
                    "mode": mode,
                    "file_size_kb": round(len(image_bytes) / 1024, 1),
                    "hash": img_hash,
                },
            }

            logger.info(f"Image analysis: {content_type} ({confidence:.0%})")
            return result

        except Exception as e:
            logger.error(f"Image analysis failed: {str(e)}")
            return {
                "content_type": "unknown",
                "confidence": 0.0,
                "description": "Failed to analyze image",
                "metadata": {},
                "error": str(e),
            }

    def _classify_content(
        self, image: Image.Image, width: int, height: int, aspect_ratio: float
    ) -> tuple:
        """
        Classify image content type using heuristics.
        Returns (content_type, confidence, description)
        """
        # Check if it looks like a screenshot (common phone/desktop ratios)
        is_screenshot_ratio = (
            (0.4 < aspect_ratio < 0.65)  # Phone portrait
            or (1.5 < aspect_ratio < 1.85)  # Desktop landscape
            or (0.7 < aspect_ratio < 0.8)  # Tablet
        )

        # Analyze color distribution for text-heavy detection
        gray = image.convert("L")
        histogram = gray.histogram()
        total_pixels = width * height

        # Check for high contrast (text on background)
        dark_pixels = sum(histogram[:50]) / total_pixels
        light_pixels = sum(histogram[200:]) / total_pixels
        is_text_heavy = (dark_pixels > 0.3 and light_pixels > 0.3) or (
            dark_pixels > 0.5 or light_pixels > 0.5
        )

        # Check for limited color palette (meme/graphic indicator)
        colors = image.convert("RGB")
        try:
            unique_colors = len(set(list(colors.getdata())[:10000]))
        except Exception:
            unique_colors = 1000

        is_graphic = unique_colors < 500

        # Classification logic
        if is_text_heavy and is_screenshot_ratio:
            return ("screenshot", 0.75, "Appears to be a screenshot with text content")
        elif is_text_heavy:
            return (
                "text_heavy",
                0.70,
                "Image contains significant text content",
            )
        elif is_graphic:
            return (
                "meme",
                0.60,
                "Image appears to be a graphic or meme with limited colors",
            )
        elif is_screenshot_ratio:
            return ("screenshot", 0.55, "Image has screenshot-like dimensions")
        else:
            return ("photo", 0.50, "Image appears to be a photograph")


# Singleton
image_service = ImageService()
