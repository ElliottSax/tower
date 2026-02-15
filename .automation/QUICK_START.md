# Quick Start Guide - 24/7 Automation

**Get running in 5 minutes**

## Step 1: Choose Your Method

### Option A: Systemd (Best for servers, auto-start on boot)

```bash
# Install services
sudo /mnt/e/projects/.automation/INSTALL.sh

# Start services
sudo systemctl start bookcli-generator portfolio-monitor

# Enable auto-start on boot
sudo systemctl enable bookcli-generator portfolio-monitor

# Check status
sudo systemctl status bookcli-generator
```

### Option B: Background Processes (No sudo needed)

```bash
# Start all
/mnt/e/projects/.automation/scripts/start_all.sh

# Check status
/mnt/e/projects/.automation/scripts/status.sh

# Stop all
/mnt/e/projects/.automation/scripts/stop_all.sh
```

### Option C: Supervisord (Alternative process manager)

```bash
# Install supervisor (if not installed)
sudo apt-get install supervisor   # Ubuntu/Debian
# or
sudo yum install supervisor        # CentOS/RHEL

# Copy config
sudo cp /mnt/e/projects/.automation/supervisord.conf /etc/supervisor/conf.d/portfolio.conf

# Reload and start
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start portfolio-automation:*

# Check status
sudo supervisorctl status
```

## Step 2: Install Cron Jobs (Optional but Recommended)

```bash
# View cron jobs that will be installed
cat /mnt/e/projects/.cron/portfolio-crontab

# Install them
crontab /mnt/e/projects/.cron/portfolio-crontab

# Verify installation
crontab -l
```

## Step 3: Monitor

```bash
# Quick status check
/mnt/e/projects/.automation/scripts/status.sh

# View logs in real-time
tail -f /mnt/e/projects/.agent-logs/automation/*.log

# View latest report
cat /mnt/e/projects/.automation/reports/latest_status.md
```

## What's Running?

Once started, you'll have:

- **BookCLI Generator** - Creates books 24/7
  - Budget: $20/day (configurable)
  - Limit: 100 books/day (configurable)
  - Auto-restarts on errors
  - Stops when budget reached

- **Portfolio Monitor** - Health checks every 5 minutes
  - Generates reports every 6 hours
  - Auto-restarts failed services
  - Tracks all project health

- **Cron Jobs** (if installed)
  - Hourly: Cost monitoring, health checks
  - Every 6h: Quality optimization, reports
  - Daily: EPUB generation, analytics
  - Weekly: Market research, backups
  - Monthly: Portfolio analysis, API rotation

## Common Commands

```bash
# View current status
/mnt/e/projects/.automation/scripts/status.sh

# View generator state
cat /mnt/e/projects/.automation/state/generator_state.json | python3 -m json.tool

# View latest cost report
cat /mnt/e/projects/.automation/reports/latest_cost.md

# View all logs
ls -lh /mnt/e/projects/.agent-logs/automation/

# Check what's running
ps aux | grep -E "(bookcli_continuous|portfolio_monitor)"

# Restart services (systemd)
sudo systemctl restart bookcli-generator portfolio-monitor

# Restart services (background)
/mnt/e/projects/.automation/scripts/stop_all.sh
/mnt/e/projects/.automation/scripts/start_all.sh

# Restart services (supervisor)
sudo supervisorctl restart portfolio-automation:*
```

## Configuration

Edit budget and limits:

```bash
# For systemd: Edit service file
sudo nano /mnt/e/projects/.systemd/bookcli-generator.service
# Change Environment variables
sudo systemctl daemon-reload
sudo systemctl restart bookcli-generator

# For background processes: Set environment variables
export BOOKCLI_DAILY_BUDGET=10.0
export BOOKCLI_MAX_BOOKS_PER_DAY=50
/mnt/e/projects/.automation/scripts/start_all.sh

# For supervisor: Edit config
sudo nano /etc/supervisor/conf.d/portfolio.conf
sudo supervisorctl reread && sudo supervisorctl update
```

## Troubleshooting

### Services won't start

```bash
# Check Python is available
python3 --version

# Check scripts are executable
ls -lh /mnt/e/projects/.automation/scripts/*.py

# Check logs for errors
tail -100 /mnt/e/projects/.agent-logs/automation/*error.log
```

### Generator keeps stopping

```bash
# Check budget/limits
cat /mnt/e/projects/.automation/state/generator_state.json

# Check for errors
tail -50 /mnt/e/projects/.agent-logs/automation/bookcli-generator.log

# Reset state (clears consecutive errors)
rm /mnt/e/projects/.automation/state/generator_state.json
```

### High costs

```bash
# Lower daily budget
export BOOKCLI_DAILY_BUDGET=5.0

# Reduce book limit
export BOOKCLI_MAX_BOOKS_PER_DAY=10

# Restart with new limits
```

## Success Indicators

After 1 hour:
- ✅ New books appearing in `/mnt/e/projects/bookcli/output/fiction/`
- ✅ Generator state file updating with stats
- ✅ Logs showing successful generations
- ✅ No consecutive errors in state

After 6 hours:
- ✅ First status report generated
- ✅ Multiple books completed
- ✅ Cost tracking working
- ✅ Health monitoring active

After 24 hours:
- ✅ 10-20 books generated (depending on budget)
- ✅ All cron jobs executed
- ✅ No manual intervention needed
- ✅ Auto-recovery from any failures

## That's It!

Your portfolio is now running 24/7 independently. No further action needed.

View README.md for full documentation.
