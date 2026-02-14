FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy shared package first (must be within build context)
# When building, use the parent directory as context:
#   docker build -f quant-discovery/Dockerfile -t discovery .
# Or mount quant-shared via docker-compose volumes (see docker-compose.yml)
COPY quant-shared /app/quant-shared
RUN pip install -e /app/quant-shared

# Copy discovery service
COPY quant-discovery/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY quant-discovery/discovery /app/discovery
COPY quant-discovery/alembic /app/alembic
COPY quant-discovery/alembic.ini /app/

# Set Python path
ENV PYTHONPATH=/app

# Default command (overridden in docker-compose)
CMD ["celery", "-A", "discovery.tasks.celery_app", "worker", "--loglevel=info"]
