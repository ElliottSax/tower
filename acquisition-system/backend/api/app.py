"""FastAPI application factory."""

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routes import leads, businesses, campaigns, deals, pipeline, webhooks


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Acquisition System API",
        description="AI-powered business acquisition pipeline",
        version="0.1.0",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
    )

    # CORS - configurable via CORS_ORIGINS env var
    origins = os.environ.get(
        "CORS_ORIGINS", "http://localhost:3000,http://localhost:8000"
    ).split(",")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in origins],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["*"],
    )

    # API routes
    app.include_router(leads.router, prefix="/api/leads", tags=["Leads"])
    app.include_router(businesses.router, prefix="/api/businesses", tags=["Businesses"])
    app.include_router(campaigns.router, prefix="/api/campaigns", tags=["Campaigns"])
    app.include_router(deals.router, prefix="/api/deals", tags=["Deals"])
    app.include_router(pipeline.router, prefix="/api/pipeline", tags=["Pipeline"])
    app.include_router(webhooks.router, prefix="/api/webhooks", tags=["Webhooks"])

    @app.get("/api/health")
    def health():
        return {"status": "ok", "version": "0.1.0"}

    return app


app = create_app()
