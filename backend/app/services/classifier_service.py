"""
Fake News Classifier Service — ML-based text classification.
MVP: Returns mock predictions based on text heuristics.
Phase 2: Loads BERT model from HuggingFace for real inference.
"""

import logging
import random
import re
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)

# Fake news indicator keywords (heuristic for MVP)
FAKE_INDICATORS = [
    "breaking", "shocking", "you won't believe", "secret",
    "they don't want you to know", "exposed", "hoax", "scam",
    "conspiracy", "cover-up", "mainstream media won't",
    "share before deleted", "wake up", "sheeple", "bombshell",
    "must see", "urgent", "100% proof", "confirmed dead",
    "miracle cure", "doctors hate", "one weird trick",
]

REAL_INDICATORS = [
    "according to", "officials say", "report finds",
    "study shows", "data indicates", "sources confirm",
    "press release", "statement from", "investigation reveals",
    "peer-reviewed", "published in", "researchers found",
]


class ClassifierService:
    """Classifies text as real or fake news."""

    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.mock_mode = settings.MOCK_MODE
        logger.info(
            f"Classifier Service initialized "
            f"({'MOCK' if self.mock_mode else 'LIVE'} mode)"
        )

    def load_model(self):
        """
        Load the BERT model for real inference.
        Called during app startup if not in mock mode.
        """
        if self.mock_mode:
            logger.info("Skipping model load (mock mode)")
            return

        try:
            from transformers import (
                AutoTokenizer,
                AutoModelForSequenceClassification,
            )

            logger.info(f"Loading model: {settings.BERT_MODEL_NAME}")
            self.tokenizer = AutoTokenizer.from_pretrained(
                settings.BERT_MODEL_NAME
            )
            self.model = AutoModelForSequenceClassification.from_pretrained(
                settings.BERT_MODEL_NAME
            )
            self.model.eval()  # Set to evaluation mode
            logger.info("BERT model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load BERT model: {e}")
            logger.info("Falling back to mock mode")
            self.mock_mode = True

    def predict(self, text: str) -> dict:
        """
        Classify text as real or fake.
        
        Args:
            text: The text to classify
            
        Returns:
            dict with label, confidence, real_probability, fake_probability, model_used
        """
        if not text or len(text.strip()) < 10:
            return {
                "label": "UNKNOWN",
                "confidence": 0.0,
                "real_probability": 0.5,
                "fake_probability": 0.5,
                "model_used": "insufficient_text",
            }

        if self.mock_mode or self.model is None:
            return self._mock_predict(text)

        return self._model_predict(text)

    def _mock_predict(self, text: str) -> dict:
        """
        Heuristic-based mock prediction for MVP.
        Counts fake/real indicator words to generate a plausible score.
        """
        text_lower = text.lower()

        fake_score = 0
        real_score = 0

        for indicator in FAKE_INDICATORS:
            if indicator in text_lower:
                fake_score += 1

        for indicator in REAL_INDICATORS:
            if indicator in text_lower:
                real_score += 1

        # Check for excessive punctuation (fake news indicator)
        exclamation_count = text.count("!")
        caps_ratio = sum(1 for c in text if c.isupper()) / max(len(text), 1)

        if exclamation_count > 3:
            fake_score += 2
        if caps_ratio > 0.4:
            fake_score += 2

        # Calculate probabilities
        total = fake_score + real_score + 1  # +1 to avoid division by zero

        # Add some controlled randomness for realistic demo
        noise = random.uniform(-0.1, 0.1)

        fake_prob = min(max((fake_score / total) + 0.3 + noise, 0.05), 0.95)
        real_prob = 1.0 - fake_prob

        # If no strong indicators, lean towards uncertain
        if fake_score == 0 and real_score == 0:
            fake_prob = round(random.uniform(0.35, 0.65), 2)
            real_prob = round(1.0 - fake_prob, 2)

        label = "FAKE" if fake_prob > 0.5 else "REAL"
        confidence = max(fake_prob, real_prob)

        return {
            "label": label,
            "confidence": round(confidence, 4),
            "real_probability": round(real_prob, 4),
            "fake_probability": round(fake_prob, 4),
            "model_used": "heuristic_mock_v1",
        }

    def _model_predict(self, text: str) -> dict:
        """
        Real BERT model inference (CPU-optimized).
        Activated when model is loaded and mock_mode is False.
        """
        try:
            import torch

            # Tokenize input
            inputs = self.tokenizer(
                text,
                return_tensors="pt",
                truncation=True,
                max_length=512,
                padding=True,
            )

            # Run inference (no gradient computation for speed)
            with torch.no_grad():
                outputs = self.model(**inputs)
                probabilities = torch.softmax(outputs.logits, dim=-1)

            probs = probabilities[0].tolist()

            # Model outputs: [real_prob, fake_prob] or [fake_prob, real_prob]
            # Adjust based on model's label mapping
            id2label = self.model.config.id2label
            
            real_prob = 0.5
            fake_prob = 0.5
            
            for idx, prob in enumerate(probs):
                label = id2label.get(idx, "").upper()
                if "REAL" in label or "TRUE" in label or "RELIABLE" in label:
                    real_prob = prob
                elif "FAKE" in label or "FALSE" in label or "UNRELIABLE" in label:
                    fake_prob = prob

            # Normalize
            total = real_prob + fake_prob
            if total > 0:
                real_prob /= total
                fake_prob /= total

            label = "FAKE" if fake_prob > 0.5 else "REAL"
            confidence = max(real_prob, fake_prob)

            return {
                "label": label,
                "confidence": round(confidence, 4),
                "real_probability": round(real_prob, 4),
                "fake_probability": round(fake_prob, 4),
                "model_used": settings.BERT_MODEL_NAME,
            }

        except Exception as e:
            logger.error(f"Model inference failed: {e}")
            return self._mock_predict(text)


# Singleton
classifier_service = ClassifierService()
