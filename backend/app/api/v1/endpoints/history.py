"""
History endpoints — View, retrieve, and manage past analyses.
GET  /api/v1/history       — list all past analyses (summary)
GET  /api/v1/history/{id}  — get full result by ID
DELETE /api/v1/history      — clear all history
DELETE /api/v1/history/{id} — delete single entry
"""

import logging
from fastapi import APIRouter, HTTPException

from app.services.history_service import history_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["History"])


@router.get(
    "/history",
    summary="List analysis history",
    description="Returns a summary list of all past analyses, most recent first.",
)
async def list_history():
    """Get all past analyses (summary view)."""
    entries = history_service.get_all()
    return {
        "total": len(entries),
        "entries": entries,
    }


@router.get(
    "/history/{result_id}",
    summary="Get analysis result by ID",
    description="Returns the full analysis result for a given ID.",
)
async def get_history_entry(result_id: str):
    """Get full result by ID."""
    result = history_service.get_by_id(result_id)
    if result is None:
        raise HTTPException(status_code=404, detail=f"Result {result_id} not found")
    return result


@router.delete(
    "/history",
    summary="Clear all history",
    description="Deletes all stored analysis results.",
)
async def clear_history():
    """Clear all history entries."""
    count = history_service.clear()
    return {"message": f"Cleared {count} entries", "deleted": count}


@router.delete(
    "/history/{result_id}",
    summary="Delete single history entry",
    description="Deletes a specific analysis result by ID.",
)
async def delete_history_entry(result_id: str):
    """Delete a single entry by ID."""
    deleted = history_service.delete_by_id(result_id)
    if not deleted:
        raise HTTPException(status_code=404, detail=f"Result {result_id} not found")
    return {"message": f"Deleted result {result_id}"}
