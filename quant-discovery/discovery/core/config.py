"""Configuration for discovery service."""

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    """Discovery service settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Service Info
    SERVICE_NAME: str = "quant-discovery"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"

    # Database (SHARED with main app)
    DATABASE_URL: str = "postgresql+asyncpg://user:pass@localhost:5432/quant"
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_ECHO: bool = False

    # Redis (for Celery)
    REDIS_URL: str = "redis://localhost:6379/0"

    # MLFlow
    MLFLOW_TRACKING_URI: str = "http://localhost:5000"
    MLFLOW_EXPERIMENT_NAME: str = "quant-discovery"

    # Discovery Settings
    DISCOVERY_MODE: str = "production"  # or 'development'
    ENABLE_ALERTS: bool = True
    ALERT_EMAIL: str | None = None
    ALERT_WEBHOOK: str | None = None

    # Resource Limits
    MAX_WORKERS: int = 5
    WORKER_MEMORY_LIMIT: str = "8GB"
    ENABLE_GPU: bool = False

    # Analysis Parameters
    MIN_TRADES_FOR_ANALYSIS: int = 100
    PATTERN_CONFIDENCE_THRESHOLD: float = 0.7
    ANOMALY_SEVERITY_THRESHOLD: float = 0.8
    NETWORK_CORRELATION_THRESHOLD: float = 0.5

    # Scheduling
    SCAN_ALL_POLITICIANS_HOUR: int = 2  # Run at 2 AM
    NETWORK_ANALYSIS_INTERVAL_HOURS: int = 6
    ANOMALY_HUNTING_INTERVAL_HOURS: int = 4

    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"  # or 'text'


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
