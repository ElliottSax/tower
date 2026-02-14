"""Shared API dependencies."""

from typing import Generator
from sqlalchemy.orm import Session

from ..utils.database import SessionLocal


def get_db() -> Generator[Session, None, None]:
    """Database session dependency for FastAPI."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
