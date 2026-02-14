"""Shared database utilities."""

from typing import AsyncGenerator, Generator
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session


def create_async_db_engine(database_url: str, **kwargs):
    """Create an async database engine.

    Args:
        database_url: PostgreSQL connection string (must use asyncpg driver)
        **kwargs: Additional engine arguments (pool_size, max_overflow, etc.)

    Returns:
        AsyncEngine instance
    """
    return create_async_engine(
        database_url,
        pool_pre_ping=True,
        **kwargs,
    )


def create_sync_db_engine(database_url: str, **kwargs):
    """Create a sync database engine (for Celery tasks).

    Args:
        database_url: PostgreSQL connection string
        **kwargs: Additional engine arguments

    Returns:
        Engine instance
    """
    # Convert asyncpg URL to psycopg2 if needed
    sync_url = database_url.replace("+asyncpg", "")
    return create_engine(
        sync_url,
        pool_pre_ping=True,
        **kwargs,
    )


def create_async_session_factory(engine) -> async_sessionmaker[AsyncSession]:
    """Create an async session factory.

    Args:
        engine: AsyncEngine instance

    Returns:
        async_sessionmaker instance
    """
    return async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )


def create_sync_session_factory(engine) -> sessionmaker:
    """Create a sync session factory.

    Args:
        engine: Engine instance

    Returns:
        sessionmaker instance
    """
    return sessionmaker(
        bind=engine,
        expire_on_commit=False,
    )


__all__ = [
    "create_async_db_engine",
    "create_sync_db_engine",
    "create_async_session_factory",
    "create_sync_session_factory",
]
