"""Lead management endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db

router = APIRouter()


@router.get("")
def list_leads(
    tier: Optional[str] = Query(None, regex="^(hot|warm|cold)$"),
    state: Optional[str] = Query(None, max_length=2),
    industry: Optional[str] = None,
    limit: int = Query(50, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """List scored leads with filters."""
    query = """
        SELECT b.id, b.name, b.industry, b.city, b.state, b.website_url,
               b.estimated_revenue, b.estimated_employees,
               ls.composite_score, ls.score_tier, ls.scored_at,
               ls.signal_marketplace_listing, ls.signal_owner_age,
               ls.signal_digital_decay, ls.signal_headcount_decline,
               c.full_name as owner_name, c.email, c.estimated_age
        FROM businesses b
        JOIN lead_scores ls ON b.id = ls.business_id
        LEFT JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner' AND c.is_active = true
        WHERE b.status = 'active'
    """
    params = {}

    if tier:
        query += " AND ls.score_tier = :tier"
        params['tier'] = tier
    if state:
        query += " AND b.state = :state"
        params['state'] = state.upper()
    if industry:
        query += " AND b.industry ILIKE :industry"
        params['industry'] = f"%{industry}%"

    query += " ORDER BY ls.composite_score DESC LIMIT :limit OFFSET :offset"
    params['limit'] = limit
    params['offset'] = offset

    rows = db.execute(text(query), params).mappings().all()
    return {"leads": [dict(r) for r in rows], "count": len(rows)}


@router.get("/stats")
def lead_stats(db: Session = Depends(get_db)):
    """Get lead scoring statistics."""
    stats = {}

    # Tier counts
    rows = db.execute(text(
        "SELECT score_tier, COUNT(*) as count FROM lead_scores GROUP BY score_tier"
    )).mappings().all()
    stats['by_tier'] = {r['score_tier']: r['count'] for r in rows}

    # Top industries
    rows = db.execute(text("""
        SELECT b.industry, COUNT(*) as count, AVG(ls.composite_score) as avg_score
        FROM businesses b
        JOIN lead_scores ls ON b.id = ls.business_id
        WHERE b.industry IS NOT NULL
        GROUP BY b.industry
        ORDER BY count DESC
        LIMIT 10
    """)).mappings().all()
    stats['top_industries'] = [dict(r) for r in rows]

    # Top states
    rows = db.execute(text("""
        SELECT b.state, COUNT(*) as count,
               SUM(CASE WHEN ls.score_tier = 'hot' THEN 1 ELSE 0 END) as hot_count
        FROM businesses b
        JOIN lead_scores ls ON b.id = ls.business_id
        WHERE b.state IS NOT NULL
        GROUP BY b.state
        ORDER BY hot_count DESC
        LIMIT 10
    """)).mappings().all()
    stats['top_states'] = [dict(r) for r in rows]

    # Score distribution (histogram buckets)
    rows = db.execute(text("""
        SELECT
            WIDTH_BUCKET(composite_score, 0, 1, 10) as bucket,
            COUNT(*) as count
        FROM lead_scores
        GROUP BY bucket
        ORDER BY bucket
    """)).mappings().all()
    stats['score_distribution'] = [dict(r) for r in rows]

    return stats


@router.get("/{lead_id}")
def get_lead(lead_id: str, db: Session = Depends(get_db)):
    """Get detailed lead information."""
    row = db.execute(text("""
        SELECT b.*, ls.composite_score, ls.score_tier, ls.scored_at,
               ls.signal_marketplace_listing, ls.signal_owner_age,
               ls.signal_business_tenure, ls.signal_pe_hold_period,
               ls.signal_digital_decay, ls.signal_headcount_decline,
               ls.signal_no_succession, ls.features
        FROM businesses b
        JOIN lead_scores ls ON b.id = ls.business_id
        WHERE b.id = :id
    """), {'id': lead_id}).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail="Lead not found")

    lead = dict(row)

    # Get contacts
    contacts = db.execute(text(
        "SELECT * FROM contacts WHERE business_id = :id ORDER BY role_type"
    ), {'id': lead_id}).mappings().all()
    lead['contacts'] = [dict(c) for c in contacts]

    # Get outreach history
    touches = db.execute(text(
        "SELECT * FROM touches WHERE business_id = :id ORDER BY created_at DESC"
    ), {'id': lead_id}).mappings().all()
    lead['touches'] = [dict(t) for t in touches]

    return lead
