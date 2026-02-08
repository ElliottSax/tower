"""Deal pipeline endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db

router = APIRouter()

DEAL_STAGES = [
    'lead', 'contacted', 'qualified', 'loi_sent',
    'due_diligence', 'closing', 'closed_won', 'closed_lost',
]


class DealCreate(BaseModel):
    business_id: Optional[str] = None
    name: str
    description: Optional[str] = None
    asking_price: Optional[float] = None
    estimated_sde: Optional[float] = None
    estimated_revenue: Optional[float] = None
    source: Optional[str] = None


@router.get("")
def list_deals(
    stage: Optional[str] = None,
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    """List deals in the pipeline."""
    query = """
        SELECT d.*, b.name as business_name, b.industry, b.state
        FROM deals d
        LEFT JOIN businesses b ON d.business_id = b.id
        WHERE 1=1
    """
    params = {}

    if active_only:
        query += " AND d.is_active = true"
    if stage:
        query += " AND d.stage = :stage"
        params['stage'] = stage

    query += " ORDER BY d.stage_changed_at DESC"

    rows = db.execute(text(query), params).mappings().all()
    return {"deals": [dict(r) for r in rows]}


@router.post("")
def create_deal(data: DealCreate, db: Session = Depends(get_db)):
    """Create a new deal."""
    result = db.execute(text("""
        INSERT INTO deals (business_id, name, description,
            asking_price, estimated_sde, estimated_revenue, source)
        VALUES (:biz_id, :name, :desc, :price, :sde, :rev, :source)
        RETURNING id
    """), {
        'biz_id': data.business_id,
        'name': data.name,
        'desc': data.description,
        'price': data.asking_price,
        'sde': data.estimated_sde,
        'rev': data.estimated_revenue,
        'source': data.source,
    })
    db.commit()

    return {"id": str(result.scalar()), "status": "created"}


@router.get("/pipeline")
def pipeline_overview(db: Session = Depends(get_db)):
    """Get pipeline funnel overview."""
    rows = db.execute(text("""
        SELECT stage, COUNT(*) as count,
               COALESCE(SUM(asking_price), 0) as total_value,
               COALESCE(SUM(expected_value), 0) as weighted_value,
               COALESCE(AVG(win_probability), 0) as avg_probability
        FROM deals
        WHERE is_active = true
        GROUP BY stage
    """)).mappings().all()

    # Order by stage progression
    stage_order = {s: i for i, s in enumerate(DEAL_STAGES)}
    pipeline = sorted(
        [dict(r) for r in rows],
        key=lambda x: stage_order.get(x['stage'], 99)
    )

    return {"pipeline": pipeline, "stages": DEAL_STAGES}


@router.patch("/{deal_id}/stage")
def advance_deal(
    deal_id: str,
    stage: str,
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Move deal to a new stage."""
    if stage not in DEAL_STAGES:
        raise HTTPException(status_code=400, detail=f"Invalid stage. Must be one of: {DEAL_STAGES}")

    db.execute(text("""
        UPDATE deals SET
            stage = :stage,
            stage_changed_at = NOW(),
            is_active = :active,
            notes = CASE WHEN :notes IS NOT NULL
                    THEN COALESCE(notes, '') || E'\\n' || :notes
                    ELSE notes END
        WHERE id = :id
    """), {
        'stage': stage,
        'active': stage not in ('closed_won', 'closed_lost'),
        'notes': notes,
        'id': deal_id,
    })
    db.commit()

    # Log activity
    db.execute(text("""
        INSERT INTO activities (entity_type, entity_id, activity_type, description, performed_by)
        VALUES ('deal', :deal_id, 'status_change', :desc, 'system')
    """), {
        'deal_id': deal_id,
        'desc': f"Stage changed to {stage}" + (f": {notes}" if notes else ""),
    })
    db.commit()

    return {"id": deal_id, "stage": stage}
