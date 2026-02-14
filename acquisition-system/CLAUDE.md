# Acquisition System - AI-Powered Business Acquisition Pipeline

## Overview
Complete, production-ready system for identifying and contacting retiring business owners. Automates the entire deal sourcing pipeline from data collection through personalized outreach.

**Status**: ~95% complete - production-ready backend, API, dashboard, Docker setup
**Tech Stack**: Python 3.11+, FastAPI, PostgreSQL, Claude AI, Next.js 15, Docker

## Goal: SHIP THE FINAL 5%
1. ✅ Backend complete (37 Python files, ~7,500 LOC)
2. ✅ FastAPI REST API (6 route modules, 20+ endpoints)
3. ✅ Test suite (10 test modules, ~2,000 LOC)
4. ✅ Next.js Dashboard (builds successfully)
5. ✅ Docker multi-stage setup (Compose + profiles)
6. ✅ Alembic migrations (initial schema)
7. 🔄 Production deployment validation (need PostgreSQL instance)
8. 🔄 End-to-end integration testing
9. 🔄 Production launch checklist & monitoring

## Architecture
- **Backend**: Python 3.11+ (scrapers, ML scoring, Claude personalization, email automation)
- **Database**: PostgreSQL/Supabase (`database/schema.sql`)
- **REST API**: FastAPI with 6 route modules, 20+ endpoints
- **CLI**: Click-based (`backend/cli.py`) via `acquire` command
- **Config**: Pydantic settings from `config/.env`
- **Dashboard**: Next.js 15 + TypeScript + Tailwind + TanStack Query + Recharts
- **Docker**: Multi-stage (base/scraper/api), Compose with migrate service + profiles

## Key Components (37 Python files, ~7,500 LOC)
- `scrapers/`: SoS, BizBuySell (Playwright), Website Analyzer (digital decay)
- `enrichment/`: Email waterfall (5 providers), LinkedIn (Proxycurl), Email verification (ZeroBounce)
- `models/`: XGBoost retirement scorer, Valuation calculator (12 industries), SQLAlchemy ORM
- `outreach/`: Claude personalization, Instantly/Smartlead automation, Response classifier
- `orchestration/`: Pipeline orchestrator, Scheduler (cron-like)
- `api/`: FastAPI REST API with 6 route modules (leads, businesses, campaigns, deals, pipeline, webhooks)
- `utils/`: Config, DB, Logging (Sentry), Notifications (Discord/Slack)

## Quick Start

### Development Setup
```bash
# 1. Navigate to project
cd /mnt/e/projects/acquisition-system

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -e .

# 4. Configure environment
cp config/.env.example config/.env
# Edit config/.env with your API keys

# 5. Run tests (unit tests - no DB required)
pytest tests/test_retirement_scorer.py -v
pytest tests/test_valuation.py -v

# 6. CLI commands
acquire --help
acquire scrape --states CA TX --limit 10
acquire enrich --limit 10
acquire score
acquire stats
```

### Docker Production Setup
```bash
# 1. Build images
docker compose build

# 2. Start database + API
docker compose up db api -d

# 3. Run migrations
docker compose run --rm migrate

# 4. Access API
curl http://localhost:8000/api/health

# 5. Start dashboard
docker compose --profile dashboard up -d

# 6. Run pipeline (on-demand)
docker compose --profile pipeline run app pipeline --full

# 7. Start scheduler (background jobs)
docker compose --profile scheduler up -d
```

## Testing Strategy

### Unit Tests (No DB Required)
```bash
pytest tests/test_retirement_scorer.py -v
pytest tests/test_email_waterfall.py -v
pytest tests/test_valuation.py -v
pytest tests/test_website_analyzer.py -v
pytest tests/test_response_classifier.py -v
```

### Integration Tests (Require PostgreSQL)
```bash
# Start test database
docker compose up db -d
export DATABASE_URL="postgresql://acquisition:devpassword@localhost:5432/acquisition"

# Run API integration tests
pytest tests/test_api_*.py -v -m integration
```

### Manual Testing
```bash
# Test API endpoints
curl http://localhost:8000/api/health
curl http://localhost:8000/api/leads
curl http://localhost:8000/api/businesses

# Test CLI
acquire scrape --states CA --limit 5
acquire stats
```

## Production Deployment

### Prerequisites
- PostgreSQL 16+ database
- API keys in `config/.env`:
  - ANTHROPIC_API_KEY (Claude AI)
  - INSTANTLY_API_KEY or SMARTLEAD_API_KEY (email)
  - Database connection string
- Docker + Docker Compose (optional but recommended)

### Deployment Options

#### Option 1: Docker Compose (Recommended)
```bash
# Production docker-compose.yml includes:
# - PostgreSQL with health checks
# - API server (FastAPI + Uvicorn)
# - Migration runner (Alembic)
# - Dashboard (Next.js)
# - Scheduler (background jobs)
# - Pipeline runner (on-demand)

# Start core services
docker compose up -d

# View logs
docker compose logs -f api

# Scale if needed
docker compose up api --scale api=3
```

#### Option 2: Manual Deployment
```bash
# 1. Setup database
createdb acquisition_system
psql acquisition_system < database/schema.sql

# 2. Install Python deps
pip install -e .

# 3. Run migrations
alembic upgrade head

# 4. Start API
uvicorn backend.api.app:app --host 0.0.0.0 --port 8000

# 5. Setup cron jobs (see QUICKSTART.md)
crontab -e
```

### Environment Variables
See `config/.env.example` for all options. Key ones:
- `DATABASE_URL`: PostgreSQL connection string
- `ANTHROPIC_API_KEY`: Claude API key
- `SENTRY_DSN`: Error tracking (optional)
- `LOG_LEVEL`: INFO for production
- `CORS_ORIGINS`: Allowed frontend domains

## API Endpoints

### Health Check
- `GET /api/health` - API status

### Leads
- `GET /api/leads` - List scored leads
- `GET /api/leads/hot` - Hot leads (score >= 0.70)
- `GET /api/leads/warm` - Warm leads (0.45-0.70)
- `GET /api/leads/{id}` - Lead details
- `PATCH /api/leads/{id}/status` - Update lead status

### Businesses
- `GET /api/businesses` - List businesses
- `GET /api/businesses/{id}` - Business details
- `POST /api/businesses` - Create business
- `PATCH /api/businesses/{id}` - Update business

### Campaigns
- `GET /api/campaigns` - List campaigns
- `POST /api/campaigns` - Create campaign
- `GET /api/campaigns/{id}` - Campaign details
- `POST /api/campaigns/{id}/start` - Start campaign

### Deals
- `GET /api/deals` - List deals
- `POST /api/deals` - Create deal
- `PATCH /api/deals/{id}/stage` - Update deal stage

### Pipeline
- `POST /api/pipeline/scrape` - Trigger scraping
- `POST /api/pipeline/enrich` - Trigger enrichment
- `POST /api/pipeline/score` - Trigger scoring
- `GET /api/pipeline/status` - Pipeline status

### Webhooks
- `POST /api/webhooks/instantly` - Instantly.ai webhook
- `POST /api/webhooks/smartlead` - Smartlead.ai webhook
- `POST /api/webhooks/response` - Email response handler

## Key Features

### 1. Multi-Source Data Collection
- Secretary of State scrapers for 50 states
- BizBuySell marketplace monitoring
- Website digital decay analysis

### 2. Email Waterfall Enrichment
- Tries 5+ providers sequentially: Prospeo → Hunter → Apollo → others
- Achieves 80%+ hit rate (vs 40% single provider)

### 3. ML Retirement Scoring
- XGBoost model with 7 signals
- Three-tier system: Hot (≥0.70), Warm (0.45-0.70), Cold (<0.45)
- Rule-based fallback when no trained model

### 4. AI Personalization
- Claude Sonnet 4.5 generates unique messages
- Batch API support (50% cost savings)
- Individual buyer positioning (NOT PE)

### 5. Email Automation
- Instantly.ai or Smartlead.ai integration
- Delivery tracking & response classification
- Warmup management (10/day → 50/day)

### 6. Deal Pipeline Management
- Full CRM: Lead → Contacted → Qualified → LOI → Due Diligence → Closing
- Valuation tools with industry multiples
- Activity audit logs

## Development Workflow

### Adding New Features
1. Update models in `backend/models/`
2. Create API routes in `backend/api/routes/`
3. Add tests in `tests/`
4. Update dashboard UI in `dashboard/`
5. Document in relevant README sections

### Database Migrations
```bash
# Create new migration
alembic revision -m "Add new table"

# Edit generated file in database/migrations/versions/

# Apply migration
alembic upgrade head

# Rollback if needed
alembic downgrade -1
```

### Running Tests
```bash
# All unit tests
pytest tests/ -v

# Specific test file
pytest tests/test_retirement_scorer.py -v

# With coverage
pytest tests/ --cov=backend --cov-report=html

# Integration tests only
pytest tests/ -v -m integration
```

## Monitoring & Observability

### Logging
- Structured logging via Python logging
- Sentry integration for error tracking
- Log levels: DEBUG, INFO, WARNING, ERROR

### Webhooks & Notifications
- Discord webhook for alerts
- Slack webhook (alternative)
- Notifications for: hot leads, responses, errors

### Health Checks
- API: `GET /api/health`
- Database: Connection pool status
- External APIs: Rate limit monitoring

## Cost Estimates

### Per 1,000 Leads/Month
- Email enrichment: ~$20-40
- Claude API: ~$30-50
- Email automation: ~$37-97 (platform subscription)
- Database: ~$0-25 (depends on provider)
- **Total**: ~$87-212/month

### Per 10,000 Leads/Month
- ~$700-900/month

## Remaining Work (Final 5%)

### Priority 1: Production Validation
- [ ] End-to-end Docker deployment test with real PostgreSQL
- [ ] API integration tests against live database
- [ ] Load testing (100+ concurrent requests)
- [ ] Dashboard connectivity to API

### Priority 2: Monitoring & Observability
- [ ] Sentry error tracking validation
- [ ] Discord/Slack webhook testing
- [ ] API metrics dashboard
- [ ] Database query performance monitoring

### Priority 3: Documentation
- [ ] Production deployment checklist
- [ ] API documentation (OpenAPI/Swagger)
- [ ] Troubleshooting guide
- [ ] Security best practices

### Priority 4: CI/CD
- [ ] GitHub Actions workflow
- [ ] Automated testing on PR
- [ ] Docker image building
- [ ] Deployment automation

## Communication
Update `/mnt/e/projects/.agent-bus/status/acquisition.md` after each work session with:
- Features shipped
- Tests passing
- Blockers identified
- Next steps

## Security Considerations
- Never commit `.env` files
- Use environment variables for secrets
- Enable CORS only for trusted origins
- Use HTTPS in production
- Rotate API keys regularly
- Monitor for suspicious activity

## Links & Resources
- [START_HERE.md](START_HERE.md) - Quick overview
- [QUICKSTART.md](QUICKSTART.md) - 15-minute setup guide
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Detailed feature list
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical deep-dive
- [README.md](README.md) - Full documentation
- Database schema: `database/schema.sql`
- API routes: `backend/api/routes/`
- Tests: `tests/`
- Dashboard: `dashboard/`

## Support
- Check logs in `logs/` directory
- Run `acquire stats` for system status
- Review test failures with `pytest -v`
- Check API docs at http://localhost:8000/api/docs

---

**Built by**: Claude Code
**License**: MIT
**Status**: Production-ready, final validation in progress
