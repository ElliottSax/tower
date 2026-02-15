#!/bin/bash
# Check status of all automation services

PROJECTS_DIR="/mnt/e/projects"
STATE_DIR="$PROJECTS_DIR/.automation/state"

echo "==================================================="
echo "Portfolio Automation Status"
echo "==================================================="
echo ""

# Function to check service status
check_service() {
    local pid_file=$1
    local service_name=$2

    echo -n "$service_name: "

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")

        if kill -0 "$pid" 2>/dev/null; then
            echo "✓ RUNNING (PID: $pid)"

            # Show resource usage
            ps -p "$pid" -o %cpu,%mem,etime --no-headers | while read cpu mem time; do
                echo "  CPU: $cpu%  MEM: $mem%  Uptime: $time"
            done
        else
            echo "✗ NOT RUNNING (stale PID file)"
        fi
    else
        echo "✗ NOT RUNNING"
    fi
}

# Check services
check_service "$STATE_DIR/generator.pid" "BookCLI Generator"
check_service "$STATE_DIR/monitor.pid" "Portfolio Monitor"

echo ""
echo "==================================================="
echo "Recent Activity"
echo "==================================================="
echo ""

# Show generator stats if available
if [ -f "$STATE_DIR/generator_state.json" ]; then
    echo "BookCLI Generator Stats:"
    python3 << 'EOF'
import json
from pathlib import Path

state_file = Path("/mnt/e/projects/.automation/state/generator_state.json")
if state_file.exists():
    with open(state_file) as f:
        state = json.load(f)
    print(f"  Total Books: {state.get('total_books', 0)}")
    print(f"  Books Today: {state.get('books_today', 0)}")
    print(f"  Daily Cost: ${state.get('daily_cost', 0):.2f}")
    print(f"  Consecutive Errors: {state.get('consecutive_errors', 0)}")
    print(f"  Last Success: {state.get('last_success', 'N/A')}")
EOF
    echo ""
fi

# Show recent logs
echo "Recent Logs (last 10 lines):"
echo "---"
tail -n 10 "$PROJECTS_DIR/.agent-logs/automation/"*generator*.log 2>/dev/null | head -n 10
echo ""
