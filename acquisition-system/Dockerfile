# Stage 1: Base - shared Python dependencies (no Playwright, no dev tools)
FROM python:3.11-slim AS base

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY backend/ ./backend/

RUN pip install --no-cache-dir -e .

RUN mkdir -p /app/data/training /app/data/models /app/data/exports

COPY config/ ./config/
COPY database/ ./database/
COPY scripts/ ./scripts/
COPY alembic.ini ./

# Stage 2: Scraper - adds Playwright for web scraping (app + scheduler)
FROM base AS scraper

RUN playwright install --with-deps chromium

ENTRYPOINT ["acquire"]
CMD ["--help"]

# Stage 3: API - lightweight, no Playwright needed
FROM base AS api

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

CMD ["uvicorn", "backend.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
