# Production Deployment Checklist

Complete this checklist before launching the acquisition system to production.

## Pre-Deployment

### Infrastructure Setup
- [ ] PostgreSQL 16+ database provisioned
  - [ ] Database created
  - [ ] User credentials configured
  - [ ] Connection tested from application server
  - [ ] Backup strategy implemented (daily minimum)
  - [ ] Point-in-time recovery enabled

- [ ] Application server provisioned
  - [ ] Python 3.11+ installed
  - [ ] Docker + Docker Compose installed (if using containers)
  - [ ] Sufficient resources (min: 2 CPU, 4GB RAM)
  - [ ] Disk space for data storage (10GB+ recommended)

- [ ] Domain & SSL
  - [ ] Domain purchased and configured
  - [ ] SSL certificate installed (Let's Encrypt or commercial)
  - [ ] DNS records configured
  - [ ] HTTPS working and redirecting from HTTP

### Configuration

- [ ] Environment variables configured
  - [ ] `config/.env` created from `.env.example`
  - [ ] All required API keys added
  - [ ] Database URL set
  - [ ] CORS origins configured for production domains
  - [ ] Log level set to INFO or WARNING
  - [ ] Sentry DSN configured (optional but recommended)

- [ ] Required API keys obtained and tested
  - [ ] **ANTHROPIC_API_KEY** - Claude AI (REQUIRED)
    - API key working
    - Billing configured
    - Rate limits understood ($0.03-0.05/message)
  - [ ] **Email Automation** (REQUIRED - choose one)
    - [ ] INSTANTLY_API_KEY configured
    - [ ] OR SMARTLEAD_API_KEY configured
    - Campaign created
    - Sending domain verified
  - [ ] **Email Enrichment** (RECOMMENDED)
    - [ ] HUNTER_API_KEY configured
    - [ ] PROSPEO_API_KEY configured (optional)
    - [ ] APOLLO_API_KEY configured (optional)
  - [ ] **Optional APIs**
    - [ ] PROXYCURL_API_KEY (LinkedIn data)
    - [ ] CLEARBIT_API_KEY (company enrichment)
    - [ ] CA_SOS_API_KEY (California businesses)

### Email Infrastructure

- [ ] Email sending domain configured
  - [ ] Domain purchased (use separate domain from main business)
  - [ ] DNS records configured:
    - [ ] SPF record added
    - [ ] DKIM configured and verified
    - [ ] DMARC policy set
  - [ ] Email warmup plan prepared
    - Start: 10 emails/day
    - Ramp: Increase by 10 every 3 days
    - Target: 50 emails/day within 2-4 weeks

- [ ] CAN-SPAM compliance
  - [ ] Unsubscribe mechanism implemented
  - [ ] Physical address in email signature
  - [ ] Company name in email
  - [ ] Accurate "From" field
  - [ ] Clear subject lines

### Security

- [ ] Secrets management
  - [ ] `.env` file NOT in git (verify with `git status`)
  - [ ] `.gitignore` includes `.env`, `*.key`, `secrets/`
  - [ ] API keys rotated from defaults
  - [ ] Database password is strong (16+ characters)

- [ ] Network security
  - [ ] Firewall configured
  - [ ] Only necessary ports open (80, 443, 22)
  - [ ] SSH key-based authentication only
  - [ ] Database not publicly accessible
  - [ ] HTTPS enforced

- [ ] Application security
  - [ ] CORS configured for production domains only
  - [ ] Rate limiting enabled on API
  - [ ] SQL injection protection (using SQLAlchemy ORM)
  - [ ] Input validation on all endpoints

### Database

- [ ] Schema deployed
  - [ ] Initial migration applied: `alembic upgrade head`
  - [ ] All tables created and verified
  - [ ] Indexes created for performance
  - [ ] Constraints enforced

- [ ] Monitoring configured
  - [ ] Connection pool monitoring
  - [ ] Query performance tracking
  - [ ] Disk space alerts

## Deployment

### Option A: Docker Deployment

- [ ] Docker images built
  ```bash
  docker compose build
  ```

- [ ] Services started
  ```bash
  # Start core services
  docker compose up -d db api

  # Run migrations
  docker compose run --rm migrate

  # Start dashboard
  docker compose --profile dashboard up -d
  ```

- [ ] Health checks passing
  ```bash
  curl https://your-domain.com/api/health
  # Should return: {"status": "ok", "version": "0.1.0"}
  ```

### Option B: Manual Deployment

- [ ] Application code deployed
  ```bash
  git clone <repo>
  cd acquisition-system
  python3 -m venv venv
  source venv/bin/activate
  pip install -e .
  ```

- [ ] Database migrations applied
  ```bash
  alembic upgrade head
  ```

- [ ] API server started
  ```bash
  # Using systemd, supervisord, or pm2
  uvicorn backend.api.app:app --host 0.0.0.0 --port 8000
  ```

- [ ] Process manager configured
  - [ ] API server restarts on failure
  - [ ] Scheduler runs (if using cron or systemd timers)
  - [ ] Logs captured

## Testing

### Smoke Tests

- [ ] API health check
  ```bash
  curl https://your-domain.com/api/health
  ```

- [ ] Database connectivity
  ```bash
  # From API container/server
  psql $DATABASE_URL -c "SELECT 1"
  ```

- [ ] API endpoints responding
  ```bash
  curl https://your-domain.com/api/leads
  curl https://your-domain.com/api/businesses
  curl https://your-domain.com/api/campaigns
  ```

- [ ] Dashboard accessible
  - Visit: https://your-dashboard-domain.com
  - Verify API connection working
  - Check data loading

### Functional Tests

- [ ] Run unit tests
  ```bash
  pytest tests/test_retirement_scorer.py -v
  pytest tests/test_valuation.py -v
  pytest tests/test_website_analyzer.py -v
  ```

- [ ] Run integration tests (if database available)
  ```bash
  pytest tests/test_api_*.py -v
  ```

- [ ] Test CLI commands
  ```bash
  acquire --help
  acquire stats
  ```

### Email Tests

- [ ] Test email generation (preview mode)
  ```bash
  acquire preview --business-id <test-business-id>
  ```

- [ ] Send test email to yourself
  - Create test business in database
  - Generate personalized message
  - Send to your email
  - Verify deliverability

- [ ] Verify email tracking
  - Check Instantly/Smartlead dashboard
  - Confirm email delivered
  - Test open tracking
  - Test link tracking

## Monitoring

### Error Tracking

- [ ] Sentry configured and receiving events
  - Test error sent successfully
  - Alert channels configured
  - Team members invited

- [ ] Log aggregation
  - [ ] Logs being written to `/app/logs` or stdout
  - [ ] Log rotation configured
  - [ ] Critical errors trigger alerts

### Application Metrics

- [ ] API response time monitoring
- [ ] Database query performance
- [ ] External API call success rates
- [ ] Email delivery rates

### Alerts Configured

- [ ] Discord webhook working
  - [ ] New hot leads notifications
  - [ ] Error notifications
  - [ ] Response notifications

- [ ] Slack webhook working (if using)

- [ ] Critical alerts
  - [ ] API down
  - [ ] Database connection lost
  - [ ] Disk space low
  - [ ] High error rate

## Data & Compliance

### Data Privacy

- [ ] Privacy policy prepared
- [ ] Data retention policy defined
- [ ] GDPR compliance checklist completed (if serving EU)
  - [ ] Right to deletion implemented
  - [ ] Data export capability
  - [ ] Consent tracking

- [ ] PII handling
  - [ ] Only business-context data collected
  - [ ] Sensitive data encrypted at rest
  - [ ] Database backups encrypted

### Legal & Compliance

- [ ] CAN-SPAM compliance verified
  - [ ] Unsubscribe links working
  - [ ] Unsubscribe requests processed within 10 days
  - [ ] Physical address in all emails

- [ ] Terms of Service prepared
- [ ] Acceptable Use Policy defined

## Performance

### Load Testing

- [ ] API load tested
  ```bash
  # Using Apache Bench, k6, or similar
  ab -n 1000 -c 10 https://your-domain.com/api/health
  ```

- [ ] Database query performance verified
  - [ ] Slow query log reviewed
  - [ ] Indexes optimized
  - [ ] Connection pool sized appropriately

### Optimization

- [ ] Caching configured (if using Redis)
- [ ] CDN configured for dashboard (optional)
- [ ] Database indexes on frequently queried columns
- [ ] API response times < 500ms for most endpoints

## Backup & Recovery

### Backups

- [ ] Database backups automated
  - [ ] Daily full backups
  - [ ] Point-in-time recovery enabled
  - [ ] Backups stored off-site
  - [ ] Backup retention policy (30 days minimum)

- [ ] Application data backups
  - [ ] `/data` directory backed up
  - [ ] Trained ML models backed up
  - [ ] Configuration backed up

### Disaster Recovery

- [ ] Recovery procedures documented
  - [ ] Database restore process
  - [ ] Application deployment process
  - [ ] Configuration restore process

- [ ] Recovery tested
  - [ ] Test database restore
  - [ ] Verify data integrity
  - [ ] Measure time to recover

## Maintenance

### Scheduled Jobs

- [ ] Cron jobs configured (if not using Docker scheduler)
  ```
  0 2 * * * scrape new businesses
  0 3 * * * enrich with emails
  0 4 * * * calculate scores
  0 9 * * 1-5 send outreach emails (M-F)
  ```

- [ ] Scheduler service running (if using Docker)
  ```bash
  docker compose --profile scheduler up -d
  ```

### Updates & Patches

- [ ] Update process documented
  - [ ] Backup before update
  - [ ] Test in staging first
  - [ ] Migration rollback plan

- [ ] Security updates
  - [ ] OS security patches scheduled
  - [ ] Python dependency updates tracked
  - [ ] Docker base image updates

## Documentation

- [ ] Production documentation complete
  - [ ] Deployment steps documented
  - [ ] Configuration documented
  - [ ] API endpoints documented (see `/api/docs`)
  - [ ] Troubleshooting guide prepared

- [ ] Runbooks created
  - [ ] Common issues and fixes
  - [ ] Emergency procedures
  - [ ] Contact information

- [ ] Team training
  - [ ] Operations team trained
  - [ ] On-call rotation defined
  - [ ] Escalation procedures documented

## Launch

### Soft Launch

- [ ] Start with small batch (10-20 emails/day)
- [ ] Monitor deliverability closely
  - Bounce rate < 2%
  - Spam complaint rate < 0.1%
  - Open rate > 20%

- [ ] Collect initial feedback
- [ ] Iterate on messaging

### Ramp Up

- [ ] Gradually increase volume
  - Week 1: 10/day
  - Week 2: 20/day
  - Week 3: 30/day
  - Week 4: 50/day

- [ ] Monitor key metrics
  - Delivery rate > 95%
  - Open rate 25-40%
  - Reply rate 8-12%
  - Interested rate 20-30% of replies

### Full Production

- [ ] All systems nominal
- [ ] Monitoring dashboards reviewed daily
- [ ] Response handling process established
- [ ] Deal pipeline being managed

## Post-Launch

### Week 1

- [ ] Daily monitoring of all metrics
- [ ] Review all errors in Sentry
- [ ] Verify email deliverability
- [ ] Check response classification accuracy

### Week 2-4

- [ ] Weekly performance review
- [ ] Analyze conversion funnel
- [ ] Optimize messaging based on responses
- [ ] Refine scoring model if needed

### Ongoing

- [ ] Monthly metrics review
- [ ] Quarterly security audit
- [ ] Continuous optimization
- [ ] Feature enhancements based on usage

---

## Emergency Contacts

- **Technical Issues**: [Your contact]
- **Email Deliverability**: [Email provider support]
- **Database Issues**: [DBA or provider support]
- **Security Incidents**: [Security team contact]

## Sign-Off

- [ ] Technical lead approval: _________________ Date: _________
- [ ] Security review passed: _________________ Date: _________
- [ ] Legal compliance verified: _________________ Date: _________
- [ ] Operations team ready: _________________ Date: _________

**Production Go-Live Date**: _________________

---

**Note**: This checklist should be adapted to your specific infrastructure and requirements. Not all items may apply to every deployment scenario.
