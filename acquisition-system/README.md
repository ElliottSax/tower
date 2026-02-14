# Business Acquisition System

AI-powered system to identify, score, and acquire businesses from retiring owners.

## Architecture

- **Backend**: Python (scraping, ML scoring, enrichment, outreach)
- **Database**: PostgreSQL/Supabase (lead tracking, pipeline management)
- **Dashboard**: Next.js + TypeScript (management UI)
- **ML**: XGBoost (retirement likelihood scoring)
- **AI**: Claude API (personalized messaging)
- **Email**: Instantly.ai/Smartlead integration

## Quick Start

```bash
# 1. Set up environment
cp config/.env.example config/.env
# Edit config/.env with your credentials

# 2. Install Python dependencies
cd backend
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt

# 3. Set up database
cd ../database
# Run migrations (instructions below)

# 4. Start backend services
cd ../backend
python orchestration/scheduler.py

# 5. Start dashboard
cd ../dashboard
pnpm install
pnpm dev
```

## System Components

### 1. Data Collection (`backend/scrapers/`)
- Secretary of State business registry scraping
- BizBuySell marketplace monitoring
- Website metadata extraction
- LinkedIn company data (via Proxycurl)

### 2. Lead Scoring (`backend/models/`)
- XGBoost classifier for retirement likelihood
- Multi-signal feature engineering:
  - Owner age (55+)
  - Business tenure (15+ years)
  - Digital presence decay
  - Marketplace activity
  - PE hold period timing

### 3. Data Enrichment (`backend/enrichment/`)
- Waterfall email enrichment (Prospeo → Hunter → Apollo)
- Phone number lookup
- Company firmographics
- Technology stack detection

### 4. Outreach Automation (`backend/outreach/`)
- Claude API for personalized messaging
- Email automation (Instantly.ai/Smartlead)
- Response tracking
- Follow-up sequencing

### 5. Dashboard (`dashboard/`)
- Lead pipeline management
- Scoring visualization
- Outreach campaign management
- Deal tracking
- Analytics & reporting

## Data Flow

```
1. Scrapers → Raw data (companies, officers, metadata)
2. Enrichment → Email, phone, firmographics
3. Scoring Model → Retirement likelihood score (0-1)
4. Segmentation → Hot (0.70+) / Warm (0.45-0.70) / Cold (<0.45)
5. Personalization → Claude generates custom messages
6. Outreach → Email automation sends campaigns
7. Tracking → Responses tracked in pipeline
8. Dashboard → Manage leads through acquisition process
```

## Database Schema

Core tables:
- `businesses` - Company information
- `contacts` - Owner/officer details
- `lead_scores` - Scoring history with factor breakdown
- `campaigns` - Outreach campaigns
- `touches` - Individual outreach attempts
- `deals` - Active acquisition pipeline

## Configuration

See `config/.env.example` for all required environment variables:
- Secretary of State API credentials
- Proxycurl API key
- Claude API key (Anthropic)
- Email service credentials (Instantly.ai/Smartlead)
- Database connection string
- Webhook URLs for notifications

## Development

```bash
# Run scrapers manually
python backend/scrapers/secretary_of_state.py --state CA

# Train scoring model
python backend/models/train_model.py

# Test enrichment
python backend/enrichment/test_waterfall.py

# Generate personalized message
python backend/outreach/generate_message.py --business_id 123

# Run full pipeline
python backend/orchestration/run_pipeline.py
```

## Production Deployment

- Backend: Docker containers on AWS ECS / GCP Cloud Run
- Database: Supabase / AWS RDS PostgreSQL
- Dashboard: Vercel / Netlify
- Orchestration: Airflow on AWS MWAA / GCP Composer
- Monitoring: Sentry + CloudWatch

## Compliance Notes

- Respect robots.txt and rate limits
- CAN-SPAM compliance for email outreach
- GDPR considerations for EU contacts
- FTC disclosure requirements for acquisition attempts

## License

MIT
