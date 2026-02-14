# Troubleshooting Guide

Common issues and solutions for the Acquisition System.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Database Issues](#database-issues)
- [API Issues](#api-issues)
- [Scraping Issues](#scraping-issues)
- [Email Issues](#email-issues)
- [Performance Issues](#performance-issues)
- [Docker Issues](#docker-issues)

---

## Installation Issues

### Issue: `pip install` fails with externally-managed-environment error

**Error:**
```
error: externally-managed-environment
```

**Solution:**
Always use a virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -e .
```

### Issue: Playwright browsers not installed

**Error:**
```
playwright._impl._api_types.Error: Executable doesn't exist
```

**Solution:**
```bash
playwright install chromium
# Or install all browsers
playwright install
```

### Issue: Missing system dependencies on Ubuntu/Debian

**Error:**
```
error: command 'gcc' failed
```

**Solution:**
```bash
sudo apt-get update
sudo apt-get install -y \
  python3-dev \
  build-essential \
  libpq-dev \
  curl \
  git
```

### Issue: WSL2 slow npm install

**Symptom:** npm install takes 15+ minutes on /mnt/e

**Solution:**
Develop on Linux filesystem instead:
```bash
# Move project to Linux filesystem
cp -r /mnt/e/projects/acquisition-system ~/projects/
cd ~/projects/acquisition-system/dashboard
npm install  # Much faster
```

---

## Database Issues

### Issue: Connection refused to PostgreSQL

**Error:**
```
psycopg2.OperationalError: could not connect to server: Connection refused
```

**Diagnosis:**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check if port is open
nc -zv localhost 5432

# Check DATABASE_URL
echo $DATABASE_URL
```

**Solution:**
```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Or using Docker
docker compose up db -d

# Verify connection
psql $DATABASE_URL -c "SELECT 1"
```

### Issue: Database does not exist

**Error:**
```
psycopg2.OperationalError: FATAL:  database "acquisition_system" does not exist
```

**Solution:**
```bash
# Create database
createdb acquisition_system

# Or in psql
psql -U postgres
CREATE DATABASE acquisition_system;
\q

# Run migrations
alembic upgrade head
```

### Issue: Migration fails

**Error:**
```
alembic.util.exc.CommandError: Target database is not up to date.
```

**Solution:**
```bash
# Check current version
alembic current

# Check migration history
alembic history

# Downgrade if needed
alembic downgrade -1

# Then upgrade
alembic upgrade head

# If migrations are corrupted, recreate from schema
psql acquisition_system < database/schema.sql
```

### Issue: Slow database queries

**Diagnosis:**
```sql
-- Check slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Check missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
ORDER BY abs(correlation) DESC;
```

**Solution:**
```sql
-- Add indexes for commonly queried columns
CREATE INDEX idx_businesses_retirement_score ON businesses(retirement_score);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_touches_sent_at ON touches(sent_at);
```

---

## API Issues

### Issue: API returns 404 for all routes

**Symptom:** All endpoints return 404 Not Found

**Diagnosis:**
```bash
# Check if API is running
curl http://localhost:8000/api/health

# Check logs
docker compose logs api
# Or
tail -f logs/api.log
```

**Solution:**
- Verify API prefix is `/api` in URLs
- Check CORS configuration
- Restart API server:
```bash
docker compose restart api
# Or
uvicorn backend.api.app:app --reload
```

### Issue: CORS errors in browser

**Error:**
```
Access to fetch at 'http://localhost:8000/api/leads' from origin 'http://localhost:3000'
has been blocked by CORS policy
```

**Solution:**
Update `.env`:
```bash
CORS_ORIGINS=http://localhost:3000,http://localhost:8000,https://your-domain.com
```

Restart API:
```bash
docker compose restart api
```

### Issue: API timeouts

**Symptom:** Requests take >30 seconds or timeout

**Diagnosis:**
```bash
# Check API logs
docker compose logs api | grep -i "slow\|timeout\|error"

# Monitor database connections
psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"
```

**Solution:**
- Increase timeout in Uvicorn:
```bash
uvicorn backend.api.app:app --timeout-keep-alive 65
```
- Add database indexes (see Database Issues)
- Scale API horizontally:
```bash
docker compose up api --scale api=3
```

### Issue: 500 Internal Server Error

**Diagnosis:**
```bash
# Check API logs
docker compose logs api | tail -50

# Check Sentry (if configured)
# Visit your Sentry dashboard

# Enable debug logging
LOG_LEVEL=DEBUG docker compose up api
```

**Common Causes:**
1. Missing environment variables
2. Database connection issues
3. API key errors (Anthropic, email providers)
4. Unhandled exceptions

---

## Scraping Issues

### Issue: Secretary of State scraper fails

**Error:**
```
requests.exceptions.HTTPError: 403 Forbidden
```

**Solution:**
- Add delays between requests:
```python
SCRAPER_RATE_LIMIT=0.5  # 2 seconds between requests
```
- Use proxies:
```python
PROXY_URL=http://proxy-provider.com
PROXY_USERNAME=your-username
PROXY_PASSWORD=your-password
```
- Rotate user agents:
```python
SCRAPER_USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
```

### Issue: BizBuySell scraper crashes

**Error:**
```
playwright._impl._api_types.TimeoutError: Timeout 30000ms exceeded
```

**Solution:**
- Increase timeout:
```python
browser.goto(url, timeout=60000)  # 60 seconds
```
- Check if website structure changed
- Use headless mode:
```python
browser = playwright.chromium.launch(headless=True)
```

### Issue: Website analyzer fails SSL verification

**Error:**
```
ssl.SSLCertVerificationError: certificate verify failed
```

**Solution:**
```python
# In website_analyzer.py, add:
response = requests.get(url, verify=False, timeout=10)

# Or update SSL certificates
pip install --upgrade certifi
```

---

## Email Issues

### Issue: Email enrichment returns no results

**Symptom:** Email waterfall returns None for all providers

**Diagnosis:**
```bash
# Test each provider
acquire enrich --limit 1 --debug

# Check API keys
echo $HUNTER_API_KEY
echo $PROSPEO_API_KEY
```

**Solution:**
- Verify API keys are valid
- Check rate limits in provider dashboards
- Ensure billing is current
- Try different providers in waterfall order

### Issue: Emails not sending

**Error:**
```
instantly.api.error: Campaign not found
```

**Diagnosis:**
```bash
# Check email automation credentials
echo $INSTANTLY_API_KEY
echo $INSTANTLY_CAMPAIGN_ID

# Test API connection
curl https://api.instantly.ai/api/v1/campaigns \
  -H "Authorization: Bearer $INSTANTLY_API_KEY"
```

**Solution:**
- Verify campaign ID exists
- Check campaign is active (not paused)
- Ensure email warmup is complete
- Test with small batch first:
```bash
acquire outreach --campaign-id <id> --limit 1
```

### Issue: High bounce rate (>5%)

**Symptom:** Many emails bouncing

**Solution:**
1. Enable email verification:
```bash
ZEROBOUNCE_API_KEY=your-key
```

2. Verify emails before sending:
```bash
acquire verify-emails --limit 100
```

3. Review email list quality
4. Check SPF/DKIM/DMARC records:
```bash
dig txt your-domain.com
```

### Issue: Low deliverability (<90%)

**Diagnosis:**
- Check sender reputation: mxtoolbox.com
- Review bounce reasons in Instantly/Smartlead
- Check spam folder delivery

**Solution:**
1. Slow down sending (10/day max initially)
2. Warm up domain:
   - Week 1: 10/day
   - Week 2: 20/day
   - Week 3: 30/day
3. Improve email content:
   - Remove spam trigger words
   - Add unsubscribe link
   - Include physical address
4. Set up SPF/DKIM/DMARC properly

---

## Performance Issues

### Issue: CLI commands are slow

**Symptom:** Commands take minutes instead of seconds

**Diagnosis:**
```bash
# Profile the command
python -m cProfile -o profile.stats backend/cli.py stats
python -c "import pstats; pstats.Stats('profile.stats').sort_stats('time').print_stats(20)"
```

**Solution:**
- Add database indexes
- Use pagination/limits:
```bash
acquire enrich --limit 100  # Instead of all
```
- Optimize database queries
- Use caching for repeated data

### Issue: Memory usage is high

**Symptom:** Process uses >2GB RAM

**Diagnosis:**
```bash
# Monitor memory
docker stats

# Or
ps aux | grep python | awk '{print $6/1024 " MB\t" $11}'
```

**Solution:**
- Process data in batches
- Use generators instead of lists
- Clear caches periodically:
```python
from cachetools import TTLCache
cache.clear()
```

### Issue: Scraping is slow

**Symptom:** Takes hours to scrape 1000 businesses

**Solution:**
- Increase concurrency (carefully):
```python
# In scraper config
MAX_CONCURRENT_REQUESTS = 5  # Instead of 1
```
- Use async/await for I/O operations
- Distribute across multiple workers
- Cache results to avoid re-scraping

---

## Docker Issues

### Issue: Cannot connect to Docker daemon

**Error:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
```bash
# Start Docker daemon
sudo systemctl start docker

# Add user to docker group (requires logout/login)
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker compose up
```

### Issue: Port already in use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8000: bind: address already in use
```

**Solution:**
```bash
# Find process using port
lsof -i :8000
# Or
netstat -tulpn | grep 8000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "8001:8000"  # Use 8001 instead
```

### Issue: Docker build fails

**Error:**
```
ERROR [internal] load metadata for docker.io/library/python:3.11-slim
```

**Solution:**
```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
docker compose build --no-cache

# Check disk space
df -h
```

### Issue: Container exits immediately

**Symptom:** Container starts then stops

**Diagnosis:**
```bash
# Check logs
docker compose logs api

# Run container interactively
docker compose run --rm api /bin/bash
```

**Solution:**
- Fix missing environment variables
- Check database connectivity
- Review entrypoint/command configuration

---

## Getting Help

### Debug Mode

Enable verbose logging:
```bash
LOG_LEVEL=DEBUG python backend/cli.py <command>
```

### Logs

Check log files:
```bash
# Application logs
tail -f logs/app.log

# API logs
docker compose logs -f api

# All logs
find logs/ -name "*.log" -mtime -1 -exec tail -f {} +
```

### Health Checks

```bash
# API health
curl http://localhost:8000/api/health

# Database health
psql $DATABASE_URL -c "SELECT 1"

# System stats
acquire stats
```

### Community Support

- GitHub Issues: https://github.com/your-repo/issues
- Documentation: See README.md, QUICKSTART.md
- Logs: Always include relevant log excerpts when asking for help

---

## Emergency Procedures

### System is Down

1. Check API health:
```bash
curl http://localhost:8000/api/health
```

2. Check database:
```bash
psql $DATABASE_URL -c "SELECT 1"
```

3. Restart services:
```bash
docker compose restart
```

4. Check logs for errors:
```bash
docker compose logs --tail=100
```

### Data Loss

1. Stop all services:
```bash
docker compose down
```

2. Restore from backup:
```bash
# Restore database
psql $DATABASE_URL < backup.sql

# Restore data directory
cp -r /backup/data ./data
```

3. Verify data integrity:
```bash
acquire stats
```

4. Restart services:
```bash
docker compose up -d
```

### Security Incident

1. Immediately rotate all API keys
2. Review access logs
3. Check for unauthorized data access
4. Update passwords
5. Review Sentry errors
6. Contact security team

---

## Preventive Maintenance

### Weekly

- Review error logs
- Check disk space
- Monitor API response times
- Review bounce rates

### Monthly

- Update dependencies: `pip install --upgrade -r requirements.txt`
- Review and optimize database
- Analyze conversion metrics
- Update documentation

### Quarterly

- Security audit
- Performance review
- Backup restore test
- API key rotation
