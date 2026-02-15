#!/bin/bash
# Install automation infrastructure
# This sets up 24/7 automation for the entire portfolio

set -e

PROJECTS_DIR="/mnt/e/projects"
AUTOMATION_DIR="$PROJECTS_DIR/.automation"
SYSTEMD_DIR="$PROJECTS_DIR/.systemd"
CRON_DIR="$PROJECTS_DIR/.cron"
SCRIPTS_DIR="$AUTOMATION_DIR/scripts"

echo "==================================================="
echo "Portfolio 24/7 Automation Infrastructure Installer"
echo "==================================================="
echo ""

# Check if running as root (needed for systemd)
if [ "$EUID" -eq 0 ]; then
    INSTALL_SYSTEMD=true
    echo "Running as root - will install systemd services"
else
    INSTALL_SYSTEMD=false
    echo "Not running as root - will skip systemd installation"
    echo "You can still use background processes and cron jobs"
fi

echo ""
echo "Step 1: Make scripts executable"
echo "---------------------------------------------------"
chmod +x "$SCRIPTS_DIR"/*.py
chmod +x "$SCRIPTS_DIR"/*.sh
echo "✓ Scripts are now executable"
echo ""

if [ "$INSTALL_SYSTEMD" = true ]; then
    echo "Step 2: Install systemd services"
    echo "---------------------------------------------------"

    # Copy service files to systemd directory
    cp "$SYSTEMD_DIR"/*.service /etc/systemd/system/

    # Reload systemd
    systemctl daemon-reload

    # Enable services to start on boot
    systemctl enable bookcli-generator.service
    systemctl enable portfolio-monitor.service

    echo "✓ Systemd services installed and enabled"
    echo ""

    echo "To start services now:"
    echo "  sudo systemctl start bookcli-generator"
    echo "  sudo systemctl start portfolio-monitor"
    echo ""
else
    echo "Step 2: Systemd installation (SKIPPED - not root)"
    echo "---------------------------------------------------"
    echo "To install systemd services later, run:"
    echo "  sudo $AUTOMATION_DIR/INSTALL.sh"
    echo ""
fi

echo "Step 3: Install cron jobs"
echo "---------------------------------------------------"
echo "To install cron jobs, run:"
echo "  crontab $CRON_DIR/portfolio-crontab"
echo ""
echo "Or to merge with existing crontab:"
echo "  crontab -l > /tmp/my_crontab"
echo "  cat $CRON_DIR/portfolio-crontab >> /tmp/my_crontab"
echo "  crontab /tmp/my_crontab"
echo ""

echo "Step 4: Test installation"
echo "---------------------------------------------------"

# Test Python dependencies
echo "Checking Python dependencies..."
python3 -c "import sys; assert sys.version_info >= (3, 8)" && echo "✓ Python 3.8+ available" || echo "✗ Python 3.8+ required"

# Test script execution
if python3 "$SCRIPTS_DIR/check_and_restart.py" --help > /dev/null 2>&1 || true; then
    echo "✓ Scripts are executable"
else
    echo "⚠ Warning: Scripts may have issues"
fi

echo ""
echo "==================================================="
echo "Installation Complete!"
echo "==================================================="
echo ""
echo "🎯 NEXT STEPS:"
echo ""
echo "Option A: Use systemd services (recommended for servers)"
if [ "$INSTALL_SYSTEMD" = true ]; then
    echo "  sudo systemctl start bookcli-generator"
    echo "  sudo systemctl start portfolio-monitor"
else
    echo "  (Run this script with sudo first)"
fi
echo ""
echo "Option B: Use background processes (works anywhere)"
echo "  cd $SCRIPTS_DIR"
echo "  ./start_all.sh"
echo ""
echo "Option C: Install cron jobs for scheduled tasks"
echo "  crontab $CRON_DIR/portfolio-crontab"
echo ""
echo "Check status:"
echo "  $SCRIPTS_DIR/status.sh"
echo ""
echo "View logs:"
echo "  tail -f $PROJECTS_DIR/.agent-logs/automation/*.log"
echo ""
echo "==================================================="
echo ""
