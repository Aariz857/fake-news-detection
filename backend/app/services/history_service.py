"""
History Service — Stores analysis results in memory.
Thread-safe with a max capacity of 50 entries (oldest evicted).
"""

import logging
import threading
from typing import List, Optional, Dict
from datetime import datetime

logger = logging.getLogger(__name__)

MAX_HISTORY = 50


class HistoryService:
    """In-memory storage for analysis history."""

    def __init__(self):
        self._history: List[Dict] = []
        self._lock = threading.Lock()
        logger.info("History Service initialized (in-memory, max=%d)", MAX_HISTORY)

    def save_result(self, result: Dict) -> str:
        """
        Save an analysis result to history.

        Args:
            result: Serialized analysis result dict

        Returns:
            The result ID
        """
        with self._lock:
            # Ensure we have an ID and timestamp
            result_id = result.get("id", "unknown")

            # Build a summary entry for listing
            entry = {
                "id": result_id,
                "timestamp": result.get("timestamp", datetime.utcnow().isoformat() + "Z"),
                "verdict": result.get("verdict", "UNKNOWN"),
                "score": result.get("credibility_score", {}).get("score", 0),
                "level": result.get("credibility_score", {}).get("level", "UNKNOWN"),
                "prediction_label": result.get("prediction", {}).get("label", "UNKNOWN"),
                "prediction_confidence": result.get("prediction", {}).get("confidence", 0),
                "extracted_text_preview": (result.get("extracted_text", "") or "")[:150],
                "full_result": result,  # Store full result for detail view
            }

            # Insert at beginning (most recent first)
            self._history.insert(0, entry)

            # Evict oldest if over capacity
            if len(self._history) > MAX_HISTORY:
                self._history = self._history[:MAX_HISTORY]

            logger.info(
                "Saved result %s to history (total: %d)",
                result_id, len(self._history)
            )
            return result_id

    def get_all(self) -> List[Dict]:
        """Get all history entries (summary view, without full_result)."""
        with self._lock:
            return [
                {k: v for k, v in entry.items() if k != "full_result"}
                for entry in self._history
            ]

    def get_by_id(self, result_id: str) -> Optional[Dict]:
        """Get full result by ID."""
        with self._lock:
            for entry in self._history:
                if entry["id"] == result_id:
                    return entry.get("full_result")
            return None

    def delete_by_id(self, result_id: str) -> bool:
        """Delete a single entry by ID."""
        with self._lock:
            before = len(self._history)
            self._history = [e for e in self._history if e["id"] != result_id]
            deleted = len(self._history) < before
            if deleted:
                logger.info("Deleted result %s from history", result_id)
            return deleted

    def clear(self) -> int:
        """Clear all history. Returns count of deleted entries."""
        with self._lock:
            count = len(self._history)
            self._history.clear()
            logger.info("Cleared %d entries from history", count)
            return count

    @property
    def count(self) -> int:
        """Get current history count."""
        with self._lock:
            return len(self._history)


# Singleton
history_service = HistoryService()
