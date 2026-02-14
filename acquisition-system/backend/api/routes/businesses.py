"""Business management endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db

router = APIRouter()


@router.get("")
def list_businesses(
    state: Optional[str] = None,
    status: Optional[str] = Query("active"),
    search: Optional[str] = None,
    limit: int = Query(50, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """List businesses with search and filters."""
    query = "SELECT * FROM businesses WHERE 1=1"
    params = {}

    if state:
        query += " AND state = :state"
        params['state'] = state.upper()
    if status:
        query += " AND status = :status"
        params['status'] = status
    if search:
        query += " AND (name ILIKE :search OR industry ILIKE :search)"
        params['search'] = f"%{search}%"

    query += " ORDER BY last_updated_at DESC LIMIT :limit OFFSET :offset"
    params['limit'] = limit
    params['offset'] = offset

    rows = db.execute(text(query), params).mappings().all()

    # Get total count
    count_query = "SELECT COUNT(*) as total FROM businesses WHERE 1=1"
    count_params = {k: v for k, v in params.items() if k not in ('limit', 'offset')}
    if state:
        count_query += " AND state = :state"
    if status:
        count_query += " AND status = :status"
    if search:
        count_query += " AND (name ILIKE :search OR industry ILIKE :search)"

    total = db.execute(text(count_query), count_params).mappings().first()['total']

    return {"businesses": [dict(r) for r in rows], "total": total}


@router.get("/overview")
def overview(db: Session = Depends(get_db)):
    """Get system overview statistics."""
    stats = {}

    stats['total_businesses'] = db.execute(
        text("SELECT COUNT(*) as c FROM businesses")
    ).scalar()

    stats['active_businesses'] = db.execute(
        text("SELECT COUNT(*) as c FROM businesses WHERE status = 'active'")
    ).scalar()

    stats['with_email'] = db.execute(
        text("SELECT COUNT(*) as c FROM contacts WHERE email IS NOT NULL")
    ).scalar()

    stats['scored'] = db.execute(
        text("SELECT COUNT(*) as c FROM lead_scores")
    ).scalar()

    stats['hot_leads'] = db.execute(
        text("SELECT COUNT(*) as c FROM lead_scores WHERE score_tier = 'hot'")
    ).scalar()

    stats['emails_sent'] = db.execute(
        text("SELECT COUNT(*) as c FROM touches WHERE status != 'scheduled'")
    ).scalar()

    stats['replies'] = db.execute(
        text("SELECT COUNT(*) as c FROM touches WHERE replied_at IS NOT NULL")
    ).scalar()

    stats['active_deals'] = db.execute(
        text("SELECT COUNT(*) as c FROM deals WHERE is_active = true")
    ).scalar()

    stats['recent_scrapes_7d'] = db.execute(
        text("SELECT COUNT(*) as c FROM businesses WHERE first_scraped_at > NOW() - INTERVAL '7 days'")
    ).scalar()

    return stats


@router.get("/{business_id}")
def get_business(business_id: str, db: Session = Depends(get_db)):
    """Get full business details."""
    row = db.execute(
        text("SELECT * FROM businesses WHERE id = :id"),
        {'id': business_id}
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail="Business not found")

    business = dict(row)

    contacts = db.execute(
        text("SELECT * FROM contacts WHERE business_id = :id"),
        {'id': business_id}
    ).mappings().all()
    business['contacts'] = [dict(c) for c in contacts]

    scores = db.execute(
        text("SELECT * FROM lead_scores WHERE business_id = :id ORDER BY scored_at DESC LIMIT 1"),
        {'id': business_id}
    ).mappings().first()
    business['lead_score'] = dict(scores) if scores else None

    return business
