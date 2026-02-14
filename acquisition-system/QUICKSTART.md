# Quick Start Guide

Get the Business Acquisition System up and running in 15 minutes.

## Prerequisites

- Python 3.9+ installed
- PostgreSQL database (or Supabase account)
- API keys (see Configuration below)

## Step 1: Initial Setup

```bash
# Clone/navigate to the project
cd acquisition-system

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh

# This will:
# - Create Python virtual environment
# - Install all dependencies
# - Install Playwright browsers
# - Create data directories
# - Copy .env.example to .env
```

## Step 2: Configure API Keys

Edit `config/.env` with your API keys:

```bash
# Required
DATABASE_URL=postgresql://user:password@localhost:5432/acquisition_system
ANTHROPIC_API_KEY=sk-ant-api03-...

# Email automation (choose one)
INSTANTLY_API_KEY=your-instantly-key
# OR
SMARTLEAD_API_KEY=your-smartlead-key

# Optional but recommended
HUNTER_API_KEY=your-hunter-key          # Email enrichment
PROXYCURL_API_KEY=your-proxycurl-key    # LinkedIn data
CA_SOS_API_KEY=your-ca-sos-key          # California businesses
```

### Where to Get API Keys

- **Anthropic (Claude)**: https://console.anthropic.com/
- **Instantly.ai**: https://app.instantly.ai/app/settings/integrations
- **Smartlead.ai**: https://app.smartlead.ai/app/api
- **Hunter.io**: https://hunter.io/api
- **Proxycurl**: https://nubela.co/proxycurl/
- **CA Secretary of State**: https://businesssearch.sos.ca.gov/

## Step 3: Set Up Database

```bash
# Create database
createdb acquisition_system

# Run migrations
psql acquisition_system < database/schema.sql

# Verify
psql acquisition_system -c "\dt"
```

### Using Supabase Instead

If using Supabase:

1. Create project at https://supabase.com
2. Copy SQL from `database/schema.sql` and run in Supabase SQL Editor
3. Update `.env`:
   ```
   DATABASE_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres
   SUPABASE_URL=https://[project].supabase.co
   SUPABASE_SERVICE_KEY=your-service-role-key
   ```

## Step 4: Test the System

```bash
# Activate virtual environment
cd backend
source venv/bin/activate

# Run quick start test
python ../scripts/quick_start.py

# This will:
# - Test the scoring model
# - Generate a sample personalized email
# - Show your configuration status
```

## Step 5: Run Your First Pipeline

```bash
# Scrape businesses (California and Texas)
python cli.py scrape --states CA TX

# Enrich with emails
python cli.py enrich --limit 50

# Score for retirement likelihood
python cli.py score --limit 100

# View statistics
python cli.py stats

# Export hot leads
python cli.py export-leads --output hot_leads.json --limit 50
```

## Step 6: Set Up Email Campaign

```bash
# In your email automation platform (Instantly or Smartlead):
# 1. Create a new campaign
# 2. Set up email warmup (10 emails/day, increase gradually)
# 3. Configure SPF/DKIM/DMARC for your sending domain
# 4. Copy the campaign ID

# Preview personalized message
python cli.py preview --business-id <business-uuid>

# Send outreach (BE CAREFUL - this sends real emails!)
python cli.py outreach --campaign-id <campaign-id> --limit 10
```

## Common Commands

```bash
# Show help
python cli.py --help

# Run full pipeline (scrape → enrich → score)
python cli.py pipeline

# View system statistics
python cli.py stats

# Export hot leads
python cli.py export-leads

# Test email generation (doesn't send)
python cli.py preview --business-id <id>
```

## Scheduling (Production)

### Using Cron

```bash
# Edit crontab
crontab -e

# Add these lines:
0 2 * * * cd /path/to/acquisition-system/backend && source venv/bin/activate && python cli.py scrape
0 3 * * * cd /path/to/acquisition-system/backend && source venv/bin/activate && python cli.py enrich --limit 200
0 4 * * * cd /path/to/acquisition-system/backend && source venv/bin/activate && python cli.py score
0 9 * * 1-5 cd /path/to/acquisition-system/backend && source venv/bin/activate && python cli.py outreach --campaign-id <id> --limit 50
```

### Using Airflow (Advanced)

See `backend/orchestration/` for Airflow DAG examples.

## Troubleshooting

### "No module named X"

```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

### Database connection errors

```bash
# Test connection
psql $DATABASE_URL -c "SELECT 1"

# Check .env file
cat ../config/.env | grep DATABASE_URL
```

### API rate limit errors

- Add delays between requests
- Use proxy (configure in `.env`)
- Check rate limits in provider dashboards

### Playwright browser errors

```bash
playwright install chromium
```

## Next Steps

1. **Customize scoring weights**: Edit `config/.env` feature weights
2. **Train ML model**: Collect historical data and run `models/train_model.py`
3. **Add more states**: Configure additional Secretary of State APIs
4. **Set up monitoring**: Configure Sentry DSN for error tracking
5. **Build dashboard**: See `dashboard/` directory for Next.js UI

## Getting Help

- Read full `README.md` for detailed documentation
- Check `backend/utils/logging.py` for log files
- Review API provider documentation for specific errors
- Open GitHub issue for bugs

## Safety Reminders

⚠️ **Before sending emails**:
- Test with your own email first
- Verify CAN-SPAM compliance
- Set up proper unsubscribe handling
- Start with low volume (10-20/day)
- Monitor bounce rates (<2%)
- Review messages for quality

⚠️ **Data privacy**:
- Respect robots.txt
- Honor opt-outs immediately
- Don't scrape personal data beyond business context
- Follow GDPR for EU contacts

Happy acquiring! 🚀
