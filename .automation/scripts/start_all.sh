#!/bin/bash
# Start all automation services

set -e

PROJECTS_DIR="/mnt/e/projects"
SCRIPTS_DIR="$PROJECTS_DIR/.automation/scripts"
LOG_DIR="$PROJECTS_DIR/.agent-logs/automation"

mkdir -p "$LOG_DIR"

echo "==================================================="
echo "Starting Portfolio Automation Services"
echo "==================================================="
echo ""

# Function to start a Python script as a daemon
start_daemon() {
    local script_name=$1
    local display_name=$2

    echo "Starting $display_name..."

    if python3 "$SCRIPTS_DIR/$script_name" &
    then
        echo "✓ $display_name started (PID: $!)"
    else
        echo "✗ Failed to start $display_name"
        return 1
    fi
}

# Start BookCLI Generator
start_daemon "bookcli_continuous_generator.py" "BookCLI Generator"
sleep 2

# Start Portfolio Monitor
start_daemon "portfolio_monitor.py" "Portfolio Monitor"
sleep 2

echo ""
echo "==================================================="
echo "All services started successfully!"
echo "==================================================="
echo ""
echo "To check status:"
echo "  python3 $SCRIPTS_DIR/status.sh"
echo ""
echo "To stop all services:"
echo "  $SCRIPTS_DIR/stop_all.sh"
echo ""
echo "Logs available at: $LOG_DIR"
echo ""
