# Architecture Overview

Detailed technical architecture of the Business Acquisition System.

## System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Collection                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Secretary of State    BizBuySell      LinkedIn        Web      │
│      Scrapers         Marketplace      (Proxycurl)   Scraping   │
│         │                  │               │            │        │
│         └──────────────────┴───────────────┴────────────┘        │
│                              ↓                                   │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Data Enrichment                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│       Email Waterfall         Firmographics      Age/LinkedIn   │
│   (Prospeo → Hunter →       (Clearbit, etc)     Estimation      │
│    Apollo → others)                                              │
│         │                         │                   │          │
│         └─────────────────────────┴───────────────────┘          │
│                              ↓                                   │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                       ML Scoring Engine                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Feature Engineering  →  XGBoost Model  →  Score (0-1)         │
│                                                                  │
│   • Owner age                           Hot:   ≥ 0.70           │
│   • Business tenure                     Warm:  0.45-0.70        │
│   • Marketplace listing                 Cold:  < 0.45           │
│   • Digital decay                                               │
│   • PE hold period                                              │
│   • Headcount trends                                            │
│                              ↓                                   │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                    AI Personalization                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│           Claude Sonnet 4.5 (Anthropic API)                     │
│                                                                  │
│   Context: Business details, owner info, industry               │
│   Output: Personalized email (subject + body)                   │
│                                                                  │
│   Features:                                                      │
│   • Specific observations (genuine research)                    │
│   • Stewardship language                                        │
│   • Individual buyer positioning (NOT PE)                       │
│   • Soft call-to-action                                         │
│                              ↓                                   │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Email Automation                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│        Instantly.ai or Smartlead.ai                              │
│                                                                  │
│   • Campaign management                                          │
│   • Email warmup (10 → 50/day)                                  │
│   • Deliverability monitoring                                   │
│   • Response tracking                                           │
│   • Follow-up sequences                                         │
│                              ↓                                   │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Deal Pipeline                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Lead → Contacted → Qualified → LOI Sent → Due Diligence       │
│      → Closing → Closed Won/Lost                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Collection Phase

**Inputs**: State registries, marketplace listings, public web data

**Process**:
- `MultiStateSoSScraper` queries Secretary of State APIs/aggregators
- `BizBuySellScraper` (Playwright) extracts active business listings
- Rate limiting: 0.5 req/sec (configurable)
- Proxy support for large-scale operations

**Outputs**: `BusinessRecord` objects → Database

### 2. Enrichment Phase

**Inputs**: Business records lacking contact/firmographic data

**Process**:
- `EmailEnrichmentWaterfall` tries providers sequentially:
  1. Prospeo (first_name + last_name + domain)
  2. DropContact (name + company)
  3. Datagma (LinkedIn URL)
  4. Hunter.io (name + domain)
  5. Apollo (name + company/domain)
- Stops at first successful result
- Typical hit rate: 40% → 80%+ with waterfall

**Outputs**: Enriched contact data → Database

### 3. Scoring Phase

**Inputs**: Businesses with complete data

**Process**:
- `RetirementScorer.extract_features()` creates feature vector
- Features include:
  - Owner age (normalized 0-1)
  - Business tenure (years)
  - Marketplace listing (binary)
  - Digital decay metrics
  - Headcount trends
  - PE hold period
  - Succession planning status

**Model Options**:
- **Rule-based** (default): Weighted feature sum using configured weights
- **XGBoost** (trained): Gradient boosting classifier on historical data

**Outputs**:
- Composite score (0.0000-1.0000)
- Individual signal breakdown
- Tier assignment (hot/warm/cold)

### 4. Personalization Phase

**Inputs**: Hot/warm leads with owner contact info

**Process**:
- `ClaudePersonalizer.generate_cold_email()` constructs prompt with:
  - Business context (industry, size, tenure, location)
  - Owner information (name, age if known)
  - Signals (why they were scored highly)
  - Tone preference (professional, consultative, friendly)

- Claude Sonnet generates:
  - Personalized subject line (<60 chars)
  - Opening paragraph with specific observation
  - Body emphasizing stewardship/legacy
  - Soft call-to-action

**Cost**: ~$0.02-0.05 per message (Sonnet 4.5)
- Use Batch API for 50% savings on non-urgent requests

**Outputs**: `PersonalizedMessage` objects

### 5. Outreach Phase

**Inputs**: Personalized messages for scored leads

**Process**:
- `EmailAutomation` (Instantly or Smartlead) schedules sends
- Respects daily limits (default: 50/day)
- Send window: 9am-5pm local time, Mon-Fri
- Email warmup: Start 10/day, increase gradually

**Tracking**:
- Delivery status
- Open tracking
- Click tracking
- Reply detection

**Outputs**: Touch records → Database

## Database Schema

### Core Tables

- **businesses**: Company records
  - Basic info (name, entity type, incorporation date)
  - Location (address, city, state)
  - Metrics (revenue, employees)
  - Online presence (website, LinkedIn, ratings)

- **contacts**: Officers/owners
  - Personal info (name, title, role)
  - Contact details (email, phone, LinkedIn)
  - Age estimation
  - Verification status

- **lead_scores**: Retirement likelihood scores
  - Composite score (0-1)
  - Individual signal scores
  - Feature vector (JSONB)
  - Model version & timestamp

- **campaigns**: Outreach campaigns
  - Configuration (targeting, limits, schedule)
  - Stats (sent, delivered, opened, replied)

- **touches**: Individual outreach attempts
  - Message content
  - Delivery tracking
  - Response capture

- **deals**: Acquisition pipeline
  - Stage tracking (lead → closing)
  - Valuation data (price, SDE, multiples)
  - Dates and probabilities

### Views

- `hot_leads`: Pre-filtered hot prospects (score ≥ 0.70)
- `campaign_stats`: Aggregated campaign metrics
- `pipeline_overview`: Deal funnel visualization

## Orchestration

### Scheduled Jobs (Cron)

```
0 2 * * *      → Scrape Secretary of State data
0 3 * * *      → Enrich new leads (email lookup)
0 4 * * *      → Score/re-score businesses
0 5 * * 0      → Verify emails (weekly)
0 9 * * 1-5    → Send outreach emails (weekdays)
0 6 1 */3 *    → Re-verify data (quarterly)
```

### Pipeline Execution

```python
pipeline = AcquisitionPipeline()

# Step 1: Scraping
pipeline.run_scraping_job(states=['CA', 'TX', 'FL'])

# Step 2: Enrichment
pipeline.run_enrichment_job(limit=200)

# Step 3: Scoring
pipeline.run_scoring_job(limit=1000)

# Step 4: Outreach
pipeline.run_outreach_job(campaign_id='xyz', limit=50)
```

## Technology Stack

### Backend (Python)

- **Web Scraping**: Playwright (JS-heavy sites), Requests + BeautifulSoup (static)
- **ML**: XGBoost, scikit-learn, pandas, numpy
- **AI**: Anthropic Python SDK (Claude API)
- **Database**: SQLAlchemy + psycopg2 (PostgreSQL)
- **Async**: asyncio for concurrent operations
- **Validation**: Pydantic (data models + settings)

### Infrastructure

- **Database**: PostgreSQL 15+ (or Supabase)
- **Caching**: Redis (optional, for rate limiting)
- **Storage**: Local filesystem or S3 for raw data
- **Monitoring**: Sentry for error tracking
- **Logging**: Python logging + file rotation

### APIs & Services

- **Data Sources**:
  - Secretary of State APIs (state-specific + aggregators)
  - BizBuySell (web scraping)
  - Proxycurl (LinkedIn data)

- **Enrichment**:
  - Prospeo, Hunter, Apollo, DropContact, Datagma (email)
  - Clearbit (firmographics)

- **AI & Automation**:
  - Anthropic (Claude Sonnet 4.5)
  - Instantly.ai or Smartlead.ai (email automation)

- **Verification**:
  - ZeroBounce or NeverBounce (email validation)

## Scalability Considerations

### Current Capacity

- **Scraping**: 1,000-10,000 businesses/day
- **Enrichment**: 1,000-5,000 emails/day (API limits)
- **Scoring**: Unlimited (local computation)
- **Outreach**: 50-100 emails/day (email warmup constraints)

### Bottlenecks

1. **Email enrichment**: API rate limits & costs
   - Solution: Cache results, batch processing, multiple providers

2. **Email deliverability**: Too many emails = spam folder
   - Solution: Gradual warmup, rotate sending domains, quality over quantity

3. **Claude API costs**: ~$0.03-0.05 per personalized message
   - Solution: Use Batch API (50% savings), cache common templates

### Horizontal Scaling

- **Scraping**: Distribute by state across workers
- **Enrichment**: Queue-based processing (Celery/RQ)
- **Scoring**: Batch scoring, pre-compute for all businesses
- **Database**: Read replicas for analytics, write to primary

## Security & Compliance

### Data Protection

- API keys in environment variables (never in code)
- Database credentials via connection strings
- Encrypted connections (TLS) for all APIs
- Minimal PII storage (business context only)

### Compliance

- **CAN-SPAM**: Unsubscribe handling, physical address in emails
- **GDPR**: Right to deletion, data portability
- **Scraping ethics**: Respect robots.txt, rate limits, ToS

### Rate Limiting

- Configurable delays between requests
- Exponential backoff on errors
- Provider-specific limits (Hunter: 50/month free, etc.)

## Monitoring & Observability

### Metrics

- Scraping: Businesses found, success rate, errors
- Enrichment: Hit rate by provider, API costs
- Scoring: Distribution by tier, model drift
- Outreach: Delivery rate, open rate, reply rate

### Logging

- Structured logging (JSON)
- Log levels: DEBUG (dev), INFO (prod), ERROR (alerts)
- Sentry integration for exception tracking

### Alerting

- Discord/Slack webhooks for:
  - New hot leads discovered
  - Email responses received
  - System errors/failures

## Future Enhancements

### Phase 2
- Web dashboard (Next.js + Supabase)
- Response classification (interested vs not interested)
- Automated follow-up sequences based on behavior

### Phase 3
- Voice outreach (Twilio integration)
- Deal management CRM features
- Valuation calculator & comps database

### Phase 4
- Multi-tenant SaaS platform
- Marketplace for trained models
- White-label for M&A advisors

## Cost Estimates

### Monthly Operating Costs (1,000 leads/month)

| Service | Usage | Cost |
|---------|-------|------|
| Claude API | 1,000 messages × $0.04 | $40 |
| Email enrichment | 1,000 lookups × $0.02 | $20 |
| Instantly.ai | Unlimited mailboxes | $97 |
| Proxycurl | 500 profiles × $0.01 | $5 |
| Database | Supabase Pro | $25 |
| **Total** | | **$187** |

### Scaling to 10,000 leads/month: ~$700-900/month

## Performance Benchmarks

- **Scraping**: 100-500 businesses/hour (rate limit dependent)
- **Enrichment**: 50-200 emails/hour (API dependent)
- **Scoring**: 10,000 businesses/minute (local ML)
- **Personalization**: 60 messages/minute (Claude API)

## Development Workflow

```bash
# Local development
git checkout -b feature/new-scraper
# ... make changes ...
pytest backend/tests/
python cli.py scrape --states CA --limit 10  # Test with small dataset
git commit -m "Add new scraper"
git push origin feature/new-scraper
```

## Production Deployment

1. Set up VPS/cloud instance (AWS EC2, DigitalOcean, etc.)
2. Clone repository
3. Run `scripts/setup.sh`
4. Configure `.env` with production credentials
5. Set up database (RDS, Supabase, etc.)
6. Configure cron jobs or Airflow
7. Set up monitoring (Sentry, CloudWatch)
8. Start services

---

For implementation details, see source code in `backend/` directory.
