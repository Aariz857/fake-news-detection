"""
AI Explainer Service — Generates human-readable explanations.
MVP: Template-based explanations.
Phase 2: ChatGPT API integration for richer explanations.
"""

import logging
from typing import Dict

from app.core.config import settings

logger = logging.getLogger(__name__)


class ExplainerService:
    """Generates explanation text for analysis results."""

    def __init__(self):
        self.mock_mode = settings.MOCK_MODE or not settings.OPENAI_API_KEY
        logger.info(
            f"Explainer Service initialized "
            f"({'MOCK' if self.mock_mode else 'LIVE'} mode)"
        )

    async def generate_explanation(
        self,
        extracted_text: str,
        prediction: Dict,
        sources: Dict,
        credibility_score: Dict,
        image_analysis: Dict,
    ) -> str:
        """
        Generate a human-readable explanation of the analysis.
        
        Returns:
            str: Explanation text
        """
        if self.mock_mode:
            return self._generate_template_explanation(
                extracted_text, prediction, sources, credibility_score, image_analysis
            )
        
        return await self._generate_gpt_explanation(
            extracted_text, prediction, sources, credibility_score, image_analysis
        )

    def _generate_template_explanation(
        self,
        extracted_text: str,
        prediction: Dict,
        sources: Dict,
        credibility_score: Dict,
        image_analysis: Dict,
    ) -> str:
        """Generate explanation using templates (no API needed)."""
        
        label = prediction.get("label", "UNKNOWN")
        confidence = prediction.get("confidence", 0)
        total_sources = sources.get("total_found", 0)
        trusted = sources.get("trusted_sources", 0)
        score = credibility_score.get("score", 50)
        content_type = image_analysis.get("content_type", "unknown")
        
        # Build explanation parts
        parts = []
        
        # Opening statement
        if label == "FAKE":
            if confidence > 0.8:
                parts.append(
                    f"⚠️ Our analysis strongly suggests this content is likely FAKE "
                    f"(confidence: {confidence:.0%})."
                )
            else:
                parts.append(
                    f"⚠️ Our analysis indicates this content may be FAKE, "
                    f"though with moderate confidence ({confidence:.0%})."
                )
        elif label == "REAL":
            if confidence > 0.8:
                parts.append(
                    f"✅ Our analysis indicates this content appears to be REAL "
                    f"(confidence: {confidence:.0%})."
                )
            else:
                parts.append(
                    f"✅ This content appears to be real, though we recommend "
                    f"further verification (confidence: {confidence:.0%})."
                )
        else:
            parts.append(
                "⚪ We could not make a confident determination about this content."
            )

        # Source analysis
        if total_sources > 0:
            parts.append(
                f"\n\n📰 We found {total_sources} related article(s) online, "
                f"of which {trusted} come from highly trusted sources."
            )
            if trusted >= 3:
                parts.append(
                    "The strong coverage from reputable outlets increases confidence "
                    "in the credibility of this story."
                )
            elif trusted == 0:
                parts.append(
                    "However, none of the sources found are from top-tier "
                    "trusted outlets, which may warrant caution."
                )
        else:
            parts.append(
                "\n\n📰 No related articles were found from major news sources. "
                "This lack of coverage could indicate the story is not widely "
                "reported or verified."
            )

        # Image analysis
        if content_type == "screenshot":
            parts.append(
                "\n\n🖼️ The image appears to be a screenshot, which is commonly "
                "used to share news content on social media."
            )
        elif content_type == "meme":
            parts.append(
                "\n\n🖼️ The image appears to be a meme or graphic. Such content "
                "is more frequently associated with misinformation."
            )
        elif content_type == "text_heavy":
            parts.append(
                "\n\n🖼️ The image contains significant text, suggesting it may "
                "be a news article or social media post."
            )

        # Final recommendation
        parts.append(
            f"\n\n📊 Overall Credibility Score: {score}/100 "
            f"({'High' if score >= 70 else 'Medium' if score >= 40 else 'Low'} "
            f"confidence)."
        )
        parts.append(
            "\n\n💡 Tip: Always cross-reference news with multiple trusted sources "
            "before sharing. Check official fact-checking websites like "
            "Snopes, PolitiFact, or Reuters Fact Check."
        )

        return "".join(parts)

    async def _generate_gpt_explanation(
        self,
        extracted_text: str,
        prediction: Dict,
        sources: Dict,
        credibility_score: Dict,
        image_analysis: Dict,
    ) -> str:
        """
        Generate explanation using OpenAI ChatGPT API.
        Activated when OPENAI_API_KEY is configured.
        """
        try:
            import httpx

            prompt = f"""You are a fact-checking AI assistant. Analyze the following information and provide a clear, 
concise explanation of why the news content is likely real or fake. Be objective and cite specific evidence.

EXTRACTED TEXT FROM IMAGE:
{extracted_text[:500]}

AI PREDICTION: {prediction.get('label')} (confidence: {prediction.get('confidence', 0):.0%})

NEWS SOURCES FOUND: {sources.get('total_found', 0)} total, {sources.get('trusted_sources', 0)} from trusted outlets

CREDIBILITY SCORE: {credibility_score.get('score', 0)}/100

IMAGE TYPE: {image_analysis.get('content_type', 'unknown')}

Provide a 3-4 paragraph explanation covering:
1. Why the content appears real or fake
2. What the source coverage tells us
3. A recommendation for the reader"""

            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "gpt-3.5-turbo",
                        "messages": [
                            {
                                "role": "system",
                                "content": "You are a professional fact-checker providing analysis of news content.",
                            },
                            {"role": "user", "content": prompt},
                        ],
                        "max_tokens": 500,
                        "temperature": 0.7,
                    },
                    timeout=30.0,
                )

                if response.status_code == 200:
                    data = response.json()
                    return data["choices"][0]["message"]["content"]
                else:
                    logger.error(f"OpenAI API error: {response.status_code}")
                    return self._generate_template_explanation(
                        extracted_text, prediction, sources,
                        credibility_score, image_analysis,
                    )

        except Exception as e:
            logger.error(f"GPT explanation failed: {e}")
            return self._generate_template_explanation(
                extracted_text, prediction, sources,
                credibility_score, image_analysis,
            )


# Singleton
explainer_service = ExplainerService()
