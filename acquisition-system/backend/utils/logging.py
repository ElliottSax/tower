"""
Logging configuration with Sentry integration.
"""

import logging
import sys
from pathlib import Path
from typing import Optional

try:
    import sentry_sdk
    from sentry_sdk.integrations.logging import LoggingIntegration
    SENTRY_AVAILABLE = True
except ImportError:
    SENTRY_AVAILABLE = False

from .config import settings


def setup_logging(
    name: str = "acquisition_system",
    log_file: Optional[Path] = None,
    level: Optional[str] = None
) -> logging.Logger:
    """
    Configure logging with console and optional file output.

    Args:
        name: Logger name
        log_file: Optional path to log file
        level: Log level (DEBUG, INFO, WARNING, ERROR)

    Returns:
        Configured logger instance
    """
    level = level or settings.log_level

    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, level.upper()))

    # Remove existing handlers
    logger.handlers.clear()

    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.DEBUG if settings.debug else logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # File handler (optional)
    if log_file:
        log_file.parent.mkdir(parents=True, exist_ok=True)
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.DEBUG)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    # Initialize Sentry if configured
    if settings.sentry_dsn and SENTRY_AVAILABLE:
        sentry_logging = LoggingIntegration(
            level=logging.INFO,
            event_level=logging.ERROR
        )

        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.sentry_environment,
            traces_sample_rate=settings.sentry_traces_sample_rate,
            integrations=[sentry_logging],
        )
        logger.info(f"Sentry initialized for environment: {settings.sentry_environment}")

    return logger


def log_error(logger: logging.Logger, error: Exception, context: Optional[dict] = None):
    """
    Log an error with optional context and send to Sentry.

    Args:
        logger: Logger instance
        error: Exception to log
        context: Optional dict with additional context
    """
    logger.error(f"{error.__class__.__name__}: {str(error)}", exc_info=True)

    if context:
        logger.error(f"Context: {context}")

    if SENTRY_AVAILABLE and settings.sentry_dsn:
        with sentry_sdk.push_scope() as scope:
            if context:
                for key, value in context.items():
                    scope.set_context(key, value)
            sentry_sdk.capture_exception(error)
