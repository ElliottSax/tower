# Infrastructure Verification Checklist

Run this checklist to verify the automation infrastructure is complete and ready.

## File Verification

### Core Services
- [x] `/mnt/e/projects/.automation/scripts/bookcli_continuous_generator.py`
- [x] `/mnt/e/projects/.automation/scripts/portfolio_monitor.py`

### Automation Scripts
- [x] `/mnt/e/projects/.automation/scripts/check_and_restart.py`
- [x] `/mnt/e/projects/.automation/scripts/cost_monitor.py`
- [x] `/mnt/e/projects/.automation/scripts/generate_initial_report.py`

### Management Scripts
- [x] `/mnt/e/projects/.automation/scripts/start_all.sh`
- [x] `/mnt/e/projects/.automation/scripts/stop_all.sh`
- [x] `/mnt/e/projects/.automation/scripts/status.sh`

### Service Configurations
- [x] `/mnt/e/projects/.systemd/bookcli-generator.service`
- [x] `/mnt/e/projects/.systemd/portfolio-monitor.service`
- [x] `/mnt/e/projects/.automation/supervisord.conf`

### Scheduled Tasks
- [x] `/mnt/e/projects/.cron/portfolio-crontab`

### Documentation
- [x] `/mnt/e/projects/.automation/INDEX.md`
- [x] `/mnt/e/projects/.automation/README.md`
- [x] `/mnt/e/projects/.automation/QUICK_START.md`
- [x] `/mnt/e/projects/.automation/DEPLOYMENT_COMPLETE.md`
- [x] `/mnt/e/projects/.automation/INSTALL.sh`

### Summary Documents
- [x] `/mnt/e/projects/AUTOMATION_INFRASTRUCTURE_DEPLOYED.md`

## Permission Verification

Run these commands to verify files are executable:

```bash
# Check Python scripts
ls -l /mnt/e/projects/.automation/scripts/*.py | grep -E "^-rwx"

# Check shell scripts
ls -l /mnt/e/projects/.automation/scripts/*.sh | grep -E "^-rwx"

# Check installer
ls -l /mnt/e/projects/.automation/INSTALL.sh | grep -E "^-rwx"
```

Expected: All files should show execute permission (x)

## Functionality Verification

### Test Python Scripts
```bash
# Test generator script imports
python3 -c "import sys; sys.path.insert(0, '/mnt/e/projects/.automation/scripts'); import bookcli_continuous_generator"

# Test monitor script imports
python3 -c "import sys; sys.path.insert(0, '/mnt/e/projects/.automation/scripts'); import portfolio_monitor"
```

### Test Shell Scripts
```bash
# Test status script
/mnt/e/projects/.automation/scripts/status.sh

# Should show services are not running (expected before start)
```

## Directory Structure Verification

```bash
# Check directories exist
ls -ld /mnt/e/projects/.automation
ls -ld /mnt/e/projects/.automation/scripts
ls -ld /mnt/e/projects/.systemd
ls -ld /mnt/e/projects/.cron

# Check auto-created directories (may not exist yet)
ls -ld /mnt/e/projects/.automation/state 2>/dev/null || echo "Will be created on first run"
ls -ld /mnt/e/projects/.automation/reports 2>/dev/null || echo "Will be created on first run"
```

## Documentation Verification

```bash
# Count documentation words
wc -w /mnt/e/projects/.automation/*.md

# Should show ~10,000 words total
```

## Ready to Deploy

If all checks pass:
- [x] All files created
- [x] All scripts executable
- [x] All documentation present
- [x] Directory structure correct

## Next Action

Choose deployment method and start services:

### Option 1: Systemd
```bash
sudo /mnt/e/projects/.automation/INSTALL.sh
sudo systemctl start bookcli-generator portfolio-monitor
```

### Option 2: Background
```bash
/mnt/e/projects/.automation/scripts/start_all.sh
```

### Option 3: Supervisor
```bash
sudo apt-get install supervisor
sudo cp /mnt/e/projects/.automation/supervisord.conf /etc/supervisor/conf.d/
sudo supervisorctl start portfolio-automation:*
```

## Post-Start Verification

After starting services:

```bash
# Check services are running
/mnt/e/projects/.automation/scripts/status.sh

# Check logs are being created
ls -lh /mnt/e/projects/.agent-logs/automation/

# Check state files created
ls -lh /mnt/e/projects/.automation/state/

# Monitor live logs
tail -f /mnt/e/projects/.agent-logs/automation/*.log
```

## Success Criteria

After 1 hour:
- [ ] Services running (PID files exist)
- [ ] Logs showing activity
- [ ] State file updating
- [ ] New books appearing in `/mnt/e/projects/bookcli/output/fiction/`

After 6 hours:
- [ ] First status report generated
- [ ] Cost report generated
- [ ] 2-5 books completed
- [ ] No consecutive errors > 0

---

**Infrastructure Version**: 1.0.0
**Last Updated**: 2026-02-14
