# 24/7 Portfolio Automation Infrastructure

**TRUE 24/7 automation that runs independently after setup**

This infrastructure enables continuous operation of your entire revenue-generating portfolio without manual intervention.

## 🎯 What This Does

### Continuous Services (Run Forever)
1. **BookCLI Generator** - Generates books 24/7 with intelligent throttling
2. **Portfolio Monitor** - Health checks every 5 minutes, reports every 6 hours
3. **Auto-Recovery** - Automatically restarts failed services

### Scheduled Tasks (Cron)
- **Hourly**: Health checks, cost monitoring
- **Every 6 hours**: Status reports, quality optimization
- **Daily**: EPUB generation, KDP uploads, analytics
- **Weekly**: Market research, metadata optimization, backups
- **Monthly**: Portfolio analysis, API key rotation

## 📋 Quick Start

### Option 1: Full Installation (Recommended)

```bash
# Install everything (requires sudo for systemd)
sudo /mnt/e/projects/.automation/INSTALL.sh

# Start services
sudo systemctl start bookcli-generator
sudo systemctl start portfolio-monitor

# Check status
sudo systemctl status bookcli-generator
sudo systemctl status portfolio-monitor

# Enable auto-start on boot
sudo systemctl enable bookcli-generator
sudo systemctl enable portfolio-monitor
```

### Option 2: Background Processes (No sudo needed)

```bash
# Start all services
/mnt/e/projects/.automation/scripts/start_all.sh

# Check status
/mnt/e/projects/.automation/scripts/status.sh

# Stop all services
/mnt/e/projects/.automation/scripts/stop_all.sh
```

### Option 3: Cron Jobs Only

```bash
# Install cron jobs
crontab /mnt/e/projects/.cron/portfolio-crontab

# Or merge with existing crontab
crontab -l > /tmp/my_crontab
cat /mnt/e/projects/.cron/portfolio-crontab >> /tmp/my_crontab
crontab /tmp/my_crontab

# View installed cron jobs
crontab -l
```

## 🗂️ Directory Structure

```
/mnt/e/projects/.automation/
├── INSTALL.sh                  # Installation script
├── README.md                   # This file
├── scripts/                    # Automation scripts
│   ├── bookcli_continuous_generator.py    # 24/7 book generator
│   ├── portfolio_monitor.py               # Health monitoring
│   ├── check_and_restart.py              # Auto-recovery
│   ├── cost_monitor.py                   # Cost tracking
│   ├── start_all.sh                      # Start services
│   ├── stop_all.sh                       # Stop services
│   └── status.sh                         # Check status
├── state/                      # Runtime state
│   ├── generator.pid           # Generator PID
│   ├── monitor.pid             # Monitor PID
│   └── generator_state.json    # Generator stats
└── reports/                    # Generated reports
    ├── latest_status.md        # Latest status report
    └── latest_cost.md          # Latest cost report

/mnt/e/projects/.systemd/
├── bookcli-generator.service   # Generator systemd service
└── portfolio-monitor.service   # Monitor systemd service

/mnt/e/projects/.cron/
└── portfolio-crontab           # Cron job definitions

/mnt/e/projects/.agent-logs/automation/
└── *.log                       # All automation logs
```

## 🔧 Configuration

### Environment Variables

Set in your shell profile (~/.bashrc or ~/.zshrc):

```bash
export BOOKCLI_DAILY_BUDGET=20.0        # Max daily spend ($)
export BOOKCLI_MAX_BOOKS_PER_DAY=100    # Max books per day
```

Or edit the systemd service files directly in `/mnt/e/projects/.systemd/`

### Budget Controls

The generator has built-in cost controls:
- **Daily budget**: Stops when daily cost limit reached
- **Book limit**: Stops when daily book count limit reached
- **Circuit breaker**: Stops after 5 consecutive errors
- **Hourly monitoring**: Tracks and reports costs

### Resource Limits

Set in systemd service files:
- **BookCLI Generator**: 4GB RAM, 80% CPU
- **Portfolio Monitor**: 1GB RAM, 20% CPU

## 📊 Monitoring

### Check Service Status

```bash
# Quick status
/mnt/e/projects/.automation/scripts/status.sh

# Systemd status
sudo systemctl status bookcli-generator
sudo systemctl status portfolio-monitor

# Check if processes are running
ps aux | grep -E "(bookcli_continuous|portfolio_monitor)"
```

### View Logs

```bash
# Real-time logs
tail -f /mnt/e/projects/.agent-logs/automation/*.log

# Generator logs
tail -f /mnt/e/projects/.agent-logs/automation/bookcli-generator.log

# Monitor logs
tail -f /mnt/e/projects/.agent-logs/automation/portfolio-monitor.log

# Systemd logs
sudo journalctl -u bookcli-generator -f
sudo journalctl -u portfolio-monitor -f
```

### View Reports

```bash
# Latest status report
cat /mnt/e/projects/.automation/reports/latest_status.md

# Latest cost report
cat /mnt/e/projects/.automation/reports/latest_cost.md

# All reports
ls -lh /mnt/e/projects/.automation/reports/
```

## 🚨 Troubleshooting

### Services Won't Start

1. Check Python is available:
   ```bash
   python3 --version  # Should be 3.8+
   ```

2. Check scripts are executable:
   ```bash
   chmod +x /mnt/e/projects/.automation/scripts/*.py
   chmod +x /mnt/e/projects/.automation/scripts/*.sh
   ```

3. Check logs for errors:
   ```bash
   tail -50 /mnt/e/projects/.agent-logs/automation/*error.log
   ```

### Generator Keeps Stopping

1. Check budget limits:
   ```bash
   cat /mnt/e/projects/.automation/state/generator_state.json
   ```

2. Check for consecutive errors (circuit breaker):
   - If `consecutive_errors` >= 5, service will pause
   - Fix underlying issue and reset: `rm /mnt/e/projects/.automation/state/generator_state.json`

3. Check API credentials:
   - Ensure BookCLI has valid API keys in `/mnt/e/projects/bookcli/.env`

### High Costs

1. Lower daily budget:
   ```bash
   export BOOKCLI_DAILY_BUDGET=10.0
   # Or edit systemd service file
   ```

2. Reduce book limit:
   ```bash
   export BOOKCLI_MAX_BOOKS_PER_DAY=20
   ```

3. Monitor costs hourly:
   ```bash
   cat /mnt/e/projects/.automation/reports/latest_cost.md
   ```

## 🔄 Updates and Maintenance

### Update Scripts

```bash
# Stop services
/mnt/e/projects/.automation/scripts/stop_all.sh

# Update scripts (edit as needed)
nano /mnt/e/projects/.automation/scripts/bookcli_continuous_generator.py

# Restart services
/mnt/e/projects/.automation/scripts/start_all.sh
```

### Reload Systemd Services

```bash
# After editing service files
sudo systemctl daemon-reload
sudo systemctl restart bookcli-generator
sudo systemctl restart portfolio-monitor
```

### Update Cron Jobs

```bash
# Edit cron jobs
crontab -e

# Or reinstall from file
crontab /mnt/e/projects/.cron/portfolio-crontab
```

## 📈 Scaling

### Add More Workers

To run multiple generators in parallel:

1. Copy generator script with new name
2. Create new systemd service file
3. Ensure different PID files used
4. Start new service

### Cloud Deployment

These scripts work on any Linux server:
- AWS EC2
- Google Cloud Compute
- Digital Ocean Droplets
- Oracle Cloud (free tier)
- Your local WSL2

Just ensure Python 3.8+ is installed and run INSTALL.sh.

## 🎯 What Runs Independently

Once installed, these run 24/7 WITHOUT any intervention:

✅ **BookCLI Generator** - Continuous book generation
✅ **Portfolio Monitor** - Health checks and reporting
✅ **Cost Monitor** - Hourly budget tracking (via cron)
✅ **Auto-Restart** - Hourly recovery checks (via cron)
✅ **Quality Optimization** - Every 6 hours (via cron)
✅ **EPUB Generation** - Daily at 4:00 AM (via cron)
✅ **Analytics Reports** - Daily at 11:00 PM (via cron)
✅ **Market Research** - Weekly on Sundays (via cron)

## 📞 Support

For issues:
1. Check logs: `/mnt/e/projects/.agent-logs/automation/`
2. Check status: `/mnt/e/projects/.automation/scripts/status.sh`
3. Review state: `/mnt/e/projects/.automation/state/generator_state.json`

## 🔐 Security Notes

- PID files prevent duplicate processes
- Graceful shutdown on SIGTERM/SIGINT
- Budget limits prevent runaway costs
- Circuit breaker prevents error loops
- All logs are local (not uploaded anywhere)
- API keys should be in .env files (never in code)

## 🎉 Success Metrics

After 24 hours of running, you should see:
- Books generated continuously (check `/mnt/e/projects/bookcli/output/fiction/`)
- Hourly cost reports in `/mnt/e/projects/.automation/reports/`
- Zero manual intervention needed
- Automatic recovery from transient failures

**This is TRUE 24/7 automation. Set it up once, runs forever.**
