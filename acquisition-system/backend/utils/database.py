"""
Database connection and utilities.
"""

from contextlib import contextmanager
from typing import Generator
from sqlalchemy import create_engine, text as sa_text
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import NullPool

from .config import settings


# Create engine
engine = create_engine(
    settings.database_url,
    poolclass=NullPool if settings.debug else None,
    echo=settings.debug,
    pool_pre_ping=True,  # Verify connections before using
)

# Create session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


@contextmanager
def get_db() -> Generator[Session, None, None]:
    """
    Context manager for database sessions.

    Usage:
        with get_db() as db:
            result = db.execute(query)
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def execute_query(query: str, params: dict = None) -> list:
    """
    Execute a raw SQL query and return results.

    Args:
        query: SQL query string (with :param style placeholders)
        params: Query parameters

    Returns:
        List of result rows as dicts
    """
    with get_db() as db:
        result = db.execute(sa_text(query), params or {})
        try:
            return [dict(row._mapping) for row in result]
        except Exception:
            return []


def execute_many(query: str, data: list[dict]) -> int:
    """
    Execute a query with multiple parameter sets (bulk insert/update).

    Args:
        query: SQL query string with :param placeholders
        data: List of parameter dicts

    Returns:
        Number of rows affected
    """
    with get_db() as db:
        stmt = sa_text(query)
        for params in data:
            db.execute(stmt, params)
        return len(data)
