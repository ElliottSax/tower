#!/bin/bash
# Stop all automation services

set -e

PROJECTS_DIR="/mnt/e/projects"
STATE_DIR="$PROJECTS_DIR/.automation/state"

echo "==================================================="
echo "Stopping Portfolio Automation Services"
echo "==================================================="
echo ""

# Function to stop a service by PID file
stop_service() {
    local pid_file=$1
    local service_name=$2

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        echo "Stopping $service_name (PID: $pid)..."

        if kill -0 "$pid" 2>/dev/null; then
            # Send SIGTERM for graceful shutdown
            kill -TERM "$pid"

            # Wait up to 30 seconds for graceful shutdown
            local count=0
            while kill -0 "$pid" 2>/dev/null && [ $count -lt 30 ]; do
                sleep 1
                count=$((count + 1))
            done

            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠ Force killing $service_name..."
                kill -KILL "$pid"
            fi

            echo "✓ $service_name stopped"
        else
            echo "⚠ $service_name not running (stale PID file)"
            rm "$pid_file"
        fi
    else
        echo "ℹ $service_name not running (no PID file)"
    fi
}

# Stop services
stop_service "$STATE_DIR/generator.pid" "BookCLI Generator"
stop_service "$STATE_DIR/monitor.pid" "Portfolio Monitor"

echo ""
echo "==================================================="
echo "All services stopped"
echo "==================================================="
echo ""
