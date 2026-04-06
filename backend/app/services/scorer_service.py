"""
Credibility Scoring Service — Combines multiple signals into a final trust score.

Scoring Weights:
  - AI Prediction (40%): BERT model confidence
  - Source Coverage (30%): Number of sources covering the story  
  - Source Quality (20%): Credibility tier of found sources
  - Image Analysis (10%): Image content type assessment
"""

import logging
from typing import Dict

logger = logging.getLogger(__name__)


class ScorerService:
    """Calculates the final credibility score from multiple analysis signals."""

    # Scoring weights
    WEIGHT_AI = 0.40
    WEIGHT_COVERAGE = 0.30
    WEIGHT_QUALITY = 0.20
    WEIGHT_IMAGE = 0.10

    def calculate_score(
        self,
        prediction: Dict,
        sources: Dict,
        image_analysis: Dict,
    ) -> Dict:
        """
        Calculate overall credibility score (0-100).
        
        Args:
            prediction: Model prediction results
            sources: Search results with source info
            image_analysis: Image classification results
            
        Returns:
            dict with score, level, and breakdown
        """
        try:
            # Component scores (each 0-100 scale, then weighted)
            ai_score = self._score_prediction(prediction)
            coverage_score = self._score_coverage(sources)
            quality_score = self._score_quality(sources)
            image_score = self._score_image(image_analysis)

            # Weighted combination
            final_score = (
                ai_score * self.WEIGHT_AI
                + coverage_score * self.WEIGHT_COVERAGE
                + quality_score * self.WEIGHT_QUALITY
                + image_score * self.WEIGHT_IMAGE
            )

            # Clamp to 0-100
            final_score = max(0, min(100, round(final_score)))

            # Determine confidence level
            if final_score >= 70:
                level = "HIGH"
            elif final_score >= 40:
                level = "MEDIUM"
            else:
                level = "LOW"

            breakdown = {
                "ai_prediction": round(ai_score * self.WEIGHT_AI, 1),
                "source_coverage": round(coverage_score * self.WEIGHT_COVERAGE, 1),
                "source_quality": round(quality_score * self.WEIGHT_QUALITY, 1),
                "image_analysis": round(image_score * self.WEIGHT_IMAGE, 1),
            }

            logger.info(
                f"Credibility score: {final_score}/100 ({level}) — "
                f"AI:{breakdown['ai_prediction']}, "
                f"Cov:{breakdown['source_coverage']}, "
                f"Qual:{breakdown['source_quality']}, "
                f"Img:{breakdown['image_analysis']}"
            )

            return {
                "score": final_score,
                "level": level,
                "breakdown": breakdown,
            }

        except Exception as e:
            logger.error(f"Scoring failed: {e}")
            return {
                "score": 50,
                "level": "MEDIUM",
                "breakdown": {
                    "ai_prediction": 20.0,
                    "source_coverage": 15.0,
                    "source_quality": 10.0,
                    "image_analysis": 5.0,
                },
            }

    def _score_prediction(self, prediction: Dict) -> float:
        """
        Score based on AI model prediction (0-100).
        Higher score = more likely REAL.
        """
        label = prediction.get("label", "UNKNOWN")
        confidence = prediction.get("confidence", 0.5)
        real_prob = prediction.get("real_probability", 0.5)

        if label == "UNKNOWN":
            return 50.0

        # Scale real probability to 0-100
        return real_prob * 100

    def _score_coverage(self, sources: Dict) -> float:
        """
        Score based on number of sources covering the story (0-100).
        More sources = higher credibility.
        """
        total = sources.get("total_found", 0)

        if total == 0:
            return 10.0  # No coverage is suspicious
        elif total == 1:
            return 30.0
        elif total <= 3:
            return 50.0
        elif total <= 5:
            return 70.0
        elif total <= 8:
            return 85.0
        else:
            return 95.0

    def _score_quality(self, sources: Dict) -> float:
        """
        Score based on credibility of sources found (0-100).
        More trusted sources = higher score.
        """
        articles = sources.get("articles", [])
        if not articles:
            return 20.0

        tier_scores = {"high": 100, "medium": 60, "low": 30, "unknown": 40}

        total_score = sum(
            tier_scores.get(a.get("credibility_tier", "unknown"), 40)
            for a in articles
        )

        return min(total_score / len(articles), 100)

    def _score_image(self, image_analysis: Dict) -> float:
        """
        Score based on image content type (0-100).
        Screenshots and text-heavy images are neutral.
        Memes/graphics are slightly lower credibility.
        """
        content_type = image_analysis.get("content_type", "unknown")
        
        type_scores = {
            "photo": 70.0,
            "screenshot": 60.0,
            "text_heavy": 55.0,
            "meme": 30.0,
            "graphic": 40.0,
            "unknown": 50.0,
        }

        return type_scores.get(content_type, 50.0)

    def generate_verdict(self, score: int, prediction: Dict) -> str:
        """Generate a human-readable verdict string."""
        label = prediction.get("label", "UNKNOWN")
        confidence = prediction.get("confidence", 0)

        if score >= 80:
            return "HIGHLY CREDIBLE"
        elif score >= 65:
            return "LIKELY REAL"
        elif score >= 45:
            return "UNCERTAIN — VERIFY INDEPENDENTLY"
        elif score >= 25:
            return "LIKELY FAKE"
        else:
            return "HIGHLY SUSPICIOUS"


# Singleton
scorer_service = ScorerService()
