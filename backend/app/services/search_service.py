"""
News Search Service — Fetches related articles from news APIs.
MVP: Returns mock data when API keys are not configured.
Production: Uses NewsAPI + Google Custom Search for verification.
"""

import logging
import random
from typing import List, Dict
from datetime import datetime, timedelta

from app.core.config import settings

logger = logging.getLogger(__name__)

# Predefined trusted sources with credibility tiers
TRUSTED_SOURCES = {
    "high": [
        "Reuters", "Associated Press", "BBC News", "The New York Times",
        "The Washington Post", "The Guardian", "CNN", "Al Jazeera",
        "NPR", "PBS NewsHour", "Bloomberg", "The Economist",
    ],
    "medium": [
        "Fox News", "MSNBC", "The Hill", "Politico", "USA Today",
        "Daily Mail", "The Independent", "Times of India",
        "NDTV", "The Hindu", "Hindustan Times",
    ],
    "low": [
        "BuzzFeed News", "Vice News", "The Sun", "New York Post",
        "Daily Mirror", "InfoWars", "Breitbart",
    ],
}


def get_credibility_tier(source_name: str) -> str:
    """Get credibility tier for a news source."""
    for tier, sources in TRUSTED_SOURCES.items():
        if any(s.lower() in source_name.lower() for s in sources):
            return tier
    return "unknown"


class SearchService:
    """Handles news search and verification against external sources."""

    def __init__(self):
        self.mock_mode = settings.MOCK_MODE or not settings.NEWSAPI_KEY
        if self.mock_mode:
            logger.info("Search Service initialized in MOCK mode")
        else:
            logger.info("Search Service initialized with live APIs")

    async def search_news(self, query: str, extracted_text: str = "") -> dict:
        """
        Search for related news articles.
        
        Args:
            query: Search query (keywords from extracted text)
            extracted_text: Full extracted text for similarity comparison
            
        Returns:
            dict with total_found, trusted_sources, articles list
        """
        if self.mock_mode:
            return self._generate_mock_results(query)

        # TODO: Phase 2 — Live API integration
        return await self._search_live(query, extracted_text)

    def _generate_mock_results(self, query: str) -> dict:
        """Generate realistic mock search results for development."""
        # Extract keywords for mock relevance
        keywords = query.split()[:5] if query else ["news"]
        topic = " ".join(keywords[:3])

        # Generate variable number of mock articles
        num_articles = random.randint(2, 8)

        mock_articles = []
        all_sources = []
        for tier_sources in TRUSTED_SOURCES.values():
            all_sources.extend(tier_sources)

        selected_sources = random.sample(
            all_sources, min(num_articles, len(all_sources))
        )

        for i, source in enumerate(selected_sources):
            tier = get_credibility_tier(source)
            days_ago = random.randint(0, 7)
            pub_date = (
                datetime.utcnow() - timedelta(days=days_ago)
            ).isoformat() + "Z"

            mock_articles.append({
                "title": f"{topic.title()}: {source} Reports on Developing Story",
                "source": source,
                "url": f"https://example.com/{source.lower().replace(' ', '-')}/article-{i+1}",
                "published_at": pub_date,
                "credibility_tier": tier,
                "similarity_score": round(random.uniform(0.4, 0.95), 2),
            })

        # Sort by similarity score
        mock_articles.sort(key=lambda x: x["similarity_score"], reverse=True)

        trusted_count = sum(
            1 for a in mock_articles if a["credibility_tier"] == "high"
        )

        result = {
            "total_found": len(mock_articles),
            "trusted_sources": trusted_count,
            "articles": mock_articles,
            "search_query": topic,
            "is_mock": True,
        }

        logger.info(
            f"Mock search: {len(mock_articles)} articles, "
            f"{trusted_count} trusted sources"
        )
        return result

    async def _search_live(self, query: str, extracted_text: str) -> dict:
        """
        Search using real APIs (NewsAPI + Google Custom Search).
        Activated when API keys are configured.
        """
        import httpx

        articles = []

        # --- NewsAPI ---
        if settings.NEWSAPI_KEY:
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(
                        "https://newsapi.org/v2/everything",
                        params={
                            "q": query,
                            "apiKey": settings.NEWSAPI_KEY,
                            "sortBy": "relevancy",
                            "pageSize": 10,
                            "language": "en",
                        },
                        timeout=10.0,
                    )
                    if response.status_code == 200:
                        data = response.json()
                        for article in data.get("articles", []):
                            source_name = article.get("source", {}).get("name", "Unknown")
                            articles.append({
                                "title": article.get("title", ""),
                                "source": source_name,
                                "url": article.get("url", ""),
                                "published_at": article.get("publishedAt", ""),
                                "credibility_tier": get_credibility_tier(source_name),
                                "similarity_score": 0.5,  # TODO: compute actual similarity
                            })
            except Exception as e:
                logger.error(f"NewsAPI search failed: {e}")

        # --- Google Custom Search ---
        if settings.GOOGLE_API_KEY and settings.GOOGLE_CX_ID:
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(
                        "https://www.googleapis.com/customsearch/v1",
                        params={
                            "key": settings.GOOGLE_API_KEY,
                            "cx": settings.GOOGLE_CX_ID,
                            "q": f"{query} fact check",
                            "num": 5,
                        },
                        timeout=10.0,
                    )
                    if response.status_code == 200:
                        data = response.json()
                        for item in data.get("items", []):
                            source_name = item.get("displayLink", "Unknown")
                            articles.append({
                                "title": item.get("title", ""),
                                "source": source_name,
                                "url": item.get("link", ""),
                                "published_at": "",
                                "credibility_tier": get_credibility_tier(source_name),
                                "similarity_score": 0.5,
                            })
            except Exception as e:
                logger.error(f"Google CSE search failed: {e}")

        trusted_count = sum(
            1 for a in articles if a["credibility_tier"] == "high"
        )

        return {
            "total_found": len(articles),
            "trusted_sources": trusted_count,
            "articles": articles[:10],  # Cap at 10
            "search_query": query,
            "is_mock": False,
        }


# Singleton
search_service = SearchService()
