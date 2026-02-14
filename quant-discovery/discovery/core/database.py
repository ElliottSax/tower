"""Database connection - connects to SHARED database with main app."""

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import create_engine
from typing import AsyncGenerator

from discovery.core.config import settings

# Import shared models
from quant_shared.models import Base, Politician, Trade, PatternDiscovery, AnomalyDetection


# Async engine for async operations
async_engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    echo=settings.DB_ECHO,
    pool_pre_ping=True,
)

# Session factory
AsyncSessionLocal = async_sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# Sync engine for Celery tasks (Celery doesn't support async well)
sync_engine = create_engine(
    settings.DATABASE_URL.replace("+asyncpg", ""),  # Use psycopg2
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    echo=settings.DB_ECHO,
    pool_pre_ping=True,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get async database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


def get_sync_db():
    """Get sync database session for Celery tasks."""
    from sqlalchemy.orm import sessionmaker

    SessionLocal = sessionmaker(bind=sync_engine)
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


async def init_db():
    """Initialize database (create tables if needed)."""
    async with async_engine.begin() as conn:
        # This creates ONLY the discovery-specific tables
        # Assumes politicians and trades tables already exist from main app
        await conn.run_sync(Base.metadata.create_all)


async def close_db():
    """Close database connections."""
    await async_engine.dispose()
