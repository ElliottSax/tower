#!/usr/bin/env python3
"""
Health check and auto-restart script.
Checks if critical processes are running and restarts them if needed.
"""

import os
import sys
import signal
import subprocess
from pathlib import Path
from datetime import datetime

PROJECTS_DIR = Path("/mnt/e/projects")
STATE_DIR = PROJECTS_DIR / ".automation" / "state"
LOG_DIR = PROJECTS_DIR / ".agent-logs" / "automation"

LOG_DIR.mkdir(parents=True, exist_ok=True)


def log(message: str):
    """Log a message with timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] {message}")


def is_process_running(pid_file: Path) -> bool:
    """Check if a process is running based on its PID file."""
    if not pid_file.exists():
        return False

    try:
        with open(pid_file, 'r') as f:
            pid = int(f.read().strip())

        # Check if process exists
        os.kill(pid, 0)
        return True
    except (OSError, ValueError):
        # Process doesn't exist or PID file is invalid
        if pid_file.exists():
            pid_file.unlink()
        return False


def start_process(script_path: Path, name: str) -> bool:
    """Start a process in the background."""
    try:
        log(f"Starting {name}...")
        subprocess.Popen(
            [sys.executable, str(script_path)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
        log(f"✓ {name} started")
        return True
    except Exception as e:
        log(f"✗ Failed to start {name}: {e}")
        return False


def main():
    """Main health check and restart logic."""
    log("Running health checks...")

    # Check BookCLI Generator
    generator_pid = STATE_DIR / "generator.pid"
    generator_script = PROJECTS_DIR / ".automation" / "scripts" / "bookcli_continuous_generator.py"

    if not is_process_running(generator_pid):
        log("⚠ BookCLI Generator is not running")
        if generator_script.exists():
            start_process(generator_script, "BookCLI Generator")
        else:
            log(f"✗ Script not found: {generator_script}")
    else:
        log("✓ BookCLI Generator is running")

    # Check Portfolio Monitor
    monitor_pid = STATE_DIR / "monitor.pid"
    monitor_script = PROJECTS_DIR / ".automation" / "scripts" / "portfolio_monitor.py"

    if not is_process_running(monitor_pid):
        log("⚠ Portfolio Monitor is not running")
        if monitor_script.exists():
            start_process(monitor_script, "Portfolio Monitor")
        else:
            log(f"✗ Script not found: {monitor_script}")
    else:
        log("✓ Portfolio Monitor is running")

    log("Health checks complete")


if __name__ == "__main__":
    main()
