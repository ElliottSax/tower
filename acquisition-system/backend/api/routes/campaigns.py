"""Campaign management endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db

router = APIRouter()


class CampaignCreate(BaseModel):
    name: str
    description: Optional[str] = None
    campaign_type: str = "cold_email"
    target_score_min: Optional[float] = 0.70
    target_score_max: Optional[float] = 1.0
    target_industries: Optional[list] = None
    target_states: Optional[list] = None
    daily_send_limit: int = 50
    use_ai_personalization: bool = True


@router.get("")
def list_campaigns(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """List all campaigns."""
    query = "SELECT * FROM campaigns"
    params = {}

    if status:
        query += " WHERE status = :status"
        params['status'] = status

    query += " ORDER BY created_at DESC"

    rows = db.execute(text(query), params).mappings().all()
    return {"campaigns": [dict(r) for r in rows]}


@router.post("")
def create_campaign(data: CampaignCreate, db: Session = Depends(get_db)):
    """Create a new campaign."""
    result = db.execute(text("""
        INSERT INTO campaigns (name, description, campaign_type,
            target_score_min, target_score_max, daily_send_limit,
            use_ai_personalization)
        VALUES (:name, :description, :type, :min, :max, :limit, :ai)
        RETURNING id
    """), {
        'name': data.name,
        'description': data.description,
        'type': data.campaign_type,
        'min': data.target_score_min,
        'max': data.target_score_max,
        'limit': data.daily_send_limit,
        'ai': data.use_ai_personalization,
    })
    db.commit()

    campaign_id = result.scalar()
    return {"id": str(campaign_id), "status": "created"}


@router.get("/stats")
def campaign_stats(db: Session = Depends(get_db)):
    """Get campaign performance stats."""
    rows = db.execute(text("""
        SELECT id, name, status, total_sent, total_delivered,
               total_opened, total_replied, total_interested,
               CASE WHEN total_delivered > 0
                    THEN ROUND((total_opened::numeric / total_delivered) * 100, 1)
                    ELSE 0 END as open_rate,
               CASE WHEN total_sent > 0
                    THEN ROUND((total_replied::numeric / total_sent) * 100, 1)
                    ELSE 0 END as reply_rate
        FROM campaigns
        ORDER BY created_at DESC
    """)).mappings().all()

    return {"campaigns": [dict(r) for r in rows]}


@router.get("/{campaign_id}")
def get_campaign(campaign_id: str, db: Session = Depends(get_db)):
    """Get campaign details with touch history."""
    campaign = db.execute(
        text("SELECT * FROM campaigns WHERE id = :id"),
        {'id': campaign_id}
    ).mappings().first()

    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")

    result = dict(campaign)

    # Recent touches
    touches = db.execute(text("""
        SELECT t.*, b.name as business_name, c.full_name as contact_name
        FROM touches t
        LEFT JOIN businesses b ON t.business_id = b.id
        LEFT JOIN contacts c ON t.contact_id = c.id
        WHERE t.campaign_id = :id
        ORDER BY t.created_at DESC
        LIMIT 50
    """), {'id': campaign_id}).mappings().all()
    result['touches'] = [dict(t) for t in touches]

    return result


@router.patch("/{campaign_id}/status")
def update_campaign_status(
    campaign_id: str,
    status: str = Query(..., regex="^(active|paused|completed)$"),
    db: Session = Depends(get_db),
):
    """Update campaign status."""
    db.execute(text("""
        UPDATE campaigns SET status = :status,
            started_at = CASE WHEN :status = 'active' AND started_at IS NULL
                         THEN NOW() ELSE started_at END,
            completed_at = CASE WHEN :status = 'completed'
                           THEN NOW() ELSE completed_at END
        WHERE id = :id
    """), {'status': status, 'id': campaign_id})
    db.commit()

    return {"id": campaign_id, "status": status}
