"""Pipeline job management endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db
from ...utils.logging import setup_logging

logger = setup_logging(__name__)

router = APIRouter()


def _run_pipeline_job(job_type: str, **kwargs):
    """Run a pipeline job in the background."""
    from ...orchestration.pipeline import AcquisitionPipeline

    logger.info(f"Background job started: {job_type}")
    pipeline = AcquisitionPipeline()

    runners = {
        'scrape': pipeline.run_scraping_job,
        'enrich': pipeline.run_enrichment_job,
        'score': pipeline.run_scoring_job,
    }

    if job_type in runners:
        result = runners[job_type](**kwargs)
        logger.info(f"Background job completed: {job_type} -> {result}")


@router.post("/run/{job_type}")
def run_job(
    job_type: str,
    background_tasks: BackgroundTasks,
    limit: Optional[int] = None,
):
    """Trigger a pipeline job (runs in background)."""
    valid_jobs = ['scrape', 'enrich', 'score']
    if job_type not in valid_jobs:
        return {"error": f"Invalid job type. Must be one of: {valid_jobs}"}

    kwargs = {}
    if limit:
        kwargs['limit'] = limit

    background_tasks.add_task(_run_pipeline_job, job_type, **kwargs)
    return {"status": "started", "job_type": job_type}


@router.get("/jobs")
def list_jobs(
    job_type: Optional[str] = None,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    """List recent pipeline jobs."""
    query = "SELECT * FROM jobs"
    params = {'limit': limit}

    if job_type:
        query += " WHERE job_type = :type"
        params['type'] = job_type

    query += " ORDER BY created_at DESC LIMIT :limit"

    rows = db.execute(text(query), params).mappings().all()
    return {"jobs": [dict(r) for r in rows]}


@router.get("/jobs/{job_id}")
def get_job(job_id: str, db: Session = Depends(get_db)):
    """Get job details."""
    row = db.execute(
        text("SELECT * FROM jobs WHERE id = :id"),
        {'id': job_id}
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail="Job not found")

    return dict(row)
