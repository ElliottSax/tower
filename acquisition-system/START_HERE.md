# 🚀 START HERE

## What You Have

A complete, production-ready **AI-powered business acquisition system** that automates finding and contacting retiring business owners.

## Quick Links

| Document | Purpose | Time |
|----------|---------|------|
| **[QUICKSTART.md](QUICKSTART.md)** | Get running in 15 minutes | ⏱️ 15 min |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | System overview & features | 📖 5 min |
| **[README.md](README.md)** | Full documentation | 📚 20 min |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Technical deep-dive | 🔧 30 min |

## 15-Minute Quick Start

```bash
# 1. Run setup script
cd /mnt/e/projects/acquisition-system
chmod +x scripts/setup.sh
./scripts/setup.sh

# 2. Add your API keys
nano config/.env
# Add at minimum:
#   - ANTHROPIC_API_KEY (for Claude AI)
#   - INSTANTLY_API_KEY or SMARTLEAD_API_KEY (for email)
#   - DATABASE_URL (PostgreSQL connection)

# 3. Set up database
createdb acquisition_system
psql acquisition_system < database/schema.sql

# 4. Test the system
cd backend
source venv/bin/activate
python ../scripts/quick_start.py

# 5. Run your first pipeline
python cli.py scrape --states CA TX --limit 100
python cli.py enrich --limit 50
python cli.py score
python cli.py stats
```

## What This System Does

```
1. SCRAPES businesses from state registries & marketplaces
           ↓
2. ENRICHES with owner emails, phone numbers, firmographics
           ↓
3. SCORES retirement likelihood using machine learning (0-1)
           ↓
4. PERSONALIZES outreach messages using Claude AI
           ↓
5. AUTOMATES email campaigns with delivery tracking
           ↓
6. MANAGES deal pipeline from first contact to close
```

## Key Features

- ✅ **Multi-source data collection** (Secretary of State, BizBuySell, web)
- ✅ **Email waterfall enrichment** (40% → 80%+ hit rate)
- ✅ **ML retirement scoring** (XGBoost model with 7 signals)
- ✅ **AI personalization** (Claude Sonnet 4.5 for unique messages)
- ✅ **Professional email automation** (Instantly/Smartlead integration)
- ✅ **Full pipeline tracking** (PostgreSQL database with audit logs)

## Three-Tier Scoring System

- 🔥 **Hot Leads** (score ≥ 0.70): Ready for immediate outreach
- 🌡️ **Warm Leads** (0.45-0.70): Enter nurture campaigns
- ❄️ **Cold Leads** (< 0.45): Monitor for signal changes

## Common Commands

```bash
# View all commands
python cli.py --help

# Scrape specific states
python cli.py scrape --states CA TX FL

# Find emails for 100 businesses
python cli.py enrich --limit 100

# Score all businesses
python cli.py score

# View system statistics
python cli.py stats

# Export hot leads to JSON
python cli.py export-leads --output hot_leads.json

# Preview personalized message (doesn't send)
python cli.py preview --business-id <uuid>

# Send outreach emails (BE CAREFUL - sends real emails!)
python cli.py outreach --campaign-id <id> --limit 10
```

## Project Structure

```
acquisition-system/
├── README.md                  ← Full documentation
├── QUICKSTART.md             ← 15-minute setup guide
├── PROJECT_SUMMARY.md        ← System overview
├── ARCHITECTURE.md           ← Technical architecture
│
├── backend/                  ← Python application
│   ├── cli.py               ← Command-line interface
│   ├── scrapers/            ← Data collection
│   ├── enrichment/          ← Email/data enrichment
│   ├── models/              ← ML scoring model
│   ├── outreach/            ← AI personalization & email
│   ├── orchestration/       ← Pipeline coordination
│   └── utils/               ← Config, database, logging
│
├── database/                ← Database schema
│   └── schema.sql           ← PostgreSQL/Supabase schema
│
├── config/                  ← Configuration
│   └── .env.example         ← Environment variables template
│
├── data/                    ← Data storage
│   ├── raw/                 ← Scraped data
│   ├── processed/           ← Enriched data
│   └── models/              ← Trained ML models
│
└── scripts/                 ← Utility scripts
    ├── setup.sh             ← Automated setup
    └── quick_start.py       ← Quick demo/test
```

## Required API Keys

### Essential (Required)
- **Anthropic**: Claude AI for message personalization
  - Get: https://console.anthropic.com/
  - Cost: ~$0.03-0.05 per message

- **Database**: PostgreSQL or Supabase
  - PostgreSQL: Local install or AWS RDS
  - Supabase: https://supabase.com (has free tier)

- **Email Automation**: Instantly.ai OR Smartlead.ai
  - Instantly: https://instantly.ai ($37-97/month)
  - Smartlead: https://smartlead.ai ($39-94/month)

### Recommended (High Value)
- **Hunter.io**: Email enrichment
  - Get: https://hunter.io/api
  - Cost: 50 free/month, then $49-399/month

- **Proxycurl**: LinkedIn data extraction
  - Get: https://nubela.co/proxycurl/
  - Cost: $0.01 per profile

### Optional (Nice to Have)
- **Prospeo, Apollo, DropContact**: Additional email providers
- **Clearbit**: Firmographic enrichment
- **CA Secretary of State**: California business data API

## Cost Estimates

| Scale | Monthly Cost |
|-------|--------------|
| 100 leads/month | ~$50 |
| 1,000 leads/month | ~$187 |
| 10,000 leads/month | ~$700-900 |

## Safety Checklist Before Sending Emails

⚠️ **Important**: Before running `python cli.py outreach`:

- [ ] Test email to yourself first
- [ ] Verify CAN-SPAM compliance (unsubscribe link, physical address)
- [ ] Set up email warmup (start with 10/day, increase gradually)
- [ ] Configure SPF/DKIM/DMARC for your sending domain
- [ ] Review messages for quality (use `preview` command)
- [ ] Start with low volume (10-20/day)
- [ ] Monitor bounce rates (<2%)
- [ ] Track deliverability in email platform

## Getting Help

1. **Read the docs**: Start with QUICKSTART.md
2. **Check logs**: See `logs/` directory for error details
3. **Test components**: Use `quick_start.py` to verify setup
4. **Review code**: All files have detailed docstrings
5. **Check configuration**: Run `python cli.py stats` to see system status

## What to Do First

### Day 1: Setup & Testing
1. Run `scripts/setup.sh`
2. Configure `config/.env` with API keys
3. Set up database
4. Run `scripts/quick_start.py` to test
5. Scrape 100 sample businesses
6. Review results with `cli.py stats`

### Day 2: Data Collection
1. Scrape your target states (1,000-5,000 businesses)
2. Run enrichment to find emails
3. Calculate retirement scores
4. Export hot leads to review

### Day 3: Outreach Preparation
1. Set up email automation account (Instantly/Smartlead)
2. Configure sending domain (SPF/DKIM/DMARC)
3. Start email warmup
4. Preview generated messages with `cli.py preview`

### Week 2: Launch
1. Send test batch (10 emails to yourself)
2. Verify deliverability
3. Start real outreach (10-20/day)
4. Monitor responses
5. Gradually increase volume

## Expected Results

Based on benchmarks from the research:

- **Delivery rate**: 95%+ (with proper warmup)
- **Open rate**: 25-40% (personalized cold email)
- **Reply rate**: 8-12% (vs 6% for generic emails)
- **Interested rate**: 20-30% of replies
- **Conversation rate**: 2-4 per 100 emails sent

### Example Math (1,000 emails)
- 950 delivered
- 285 opened (30%)
- 95 replies (10%)
- 24 interested (25% of replies)
- 6 qualified conversations

## Success Stories from Research

The approach implemented here is based on proven techniques:

- **Personalization impact**: 3x reply rate vs generic (18% vs 6%)
- **Deep research**: One searcher achieved 40% response rate on 50 highly-targeted outreach
- **Waterfall enrichment**: Clay users routinely achieve 80%+ email discovery (vs 40% single provider)
- **AI messaging**: Claude generates unique, high-quality messages at scale

## Next Steps

**Right now:**
1. Open [QUICKSTART.md](QUICKSTART.md)
2. Follow the 15-minute setup
3. Run your first test

**This week:**
1. Collect your first 1,000 businesses
2. Score and identify hot leads
3. Set up email automation

**This month:**
1. Launch outreach campaigns
2. Track and refine messaging
3. Start conversations with sellers

## You're Ready! 🎯

Everything you need is built and documented. Time to start sourcing deals.

**Next step**: Open [QUICKSTART.md](QUICKSTART.md) and follow the setup guide.

Questions? Check the other docs or review the code - everything is commented.

---

Built by Claude Code based on your comprehensive acquisition playbook.

Ready to capitalize on the $10 trillion baby boomer retirement wave? Let's go! 🚀
