#!/usr/bin/env python3
"""
Portfolio Monitoring Service
Monitors all revenue systems, tracks health, generates reports, restarts on failures.
"""

import os
import sys
import time
import json
import signal
import logging
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional

# Configuration
PROJECTS_DIR = Path("/mnt/e/projects")
LOG_DIR = PROJECTS_DIR / ".agent-logs" / "automation"
STATE_DIR = PROJECTS_DIR / ".automation" / "state"
REPORTS_DIR = PROJECTS_DIR / ".automation" / "reports"
PID_FILE = STATE_DIR / "monitor.pid"

# Ensure directories exist
LOG_DIR.mkdir(parents=True, exist_ok=True)
STATE_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / f"monitor_{datetime.now():%Y%m%d}.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("Portfolio.Monitor")

# Global shutdown flag
shutdown_requested = False


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    global shutdown_requested
    signal_name = signal.Signals(signum).name
    logger.info(f"Received {signal_name}, initiating graceful shutdown...")
    shutdown_requested = True


class ProjectMonitor:
    """Monitor for a single project."""

    def __init__(self, name: str, path: Path, check_commands: List[str]):
        self.name = name
        self.path = path
        self.check_commands = check_commands
        self.status_file = STATE_DIR / f"{name}_status.json"
        self.consecutive_failures = 0
        self.last_check = None
        self.last_success = None
        self.last_failure = None

    def check_health(self) -> Dict:
        """Check project health and return status."""
        self.last_check = datetime.now()
        status = {
            'name': self.name,
            'timestamp': self.last_check.isoformat(),
            'healthy': True,
            'checks': [],
            'errors': []
        }

        for cmd in self.check_commands:
            try:
                # Run health check command
                result = subprocess.run(
                    cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=30,
                    cwd=self.path
                )

                check_passed = result.returncode == 0
                status['checks'].append({
                    'command': cmd,
                    'passed': check_passed,
                    'output': result.stdout[-200:] if check_passed else result.stderr[-200:]
                })

                if not check_passed:
                    status['healthy'] = False
                    status['errors'].append(f"Check failed: {cmd}")

            except subprocess.TimeoutExpired:
                status['healthy'] = False
                status['checks'].append({
                    'command': cmd,
                    'passed': False,
                    'output': 'TIMEOUT'
                })
                status['errors'].append(f"Check timeout: {cmd}")
            except Exception as e:
                status['healthy'] = False
                status['checks'].append({
                    'command': cmd,
                    'passed': False,
                    'output': str(e)
                })
                status['errors'].append(f"Check error: {cmd} - {e}")

        # Update counters
        if status['healthy']:
            self.consecutive_failures = 0
            self.last_success = self.last_check
        else:
            self.consecutive_failures += 1
            self.last_failure = self.last_check

        # Save status
        try:
            with open(self.status_file, 'w') as f:
                json.dump(status, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save status for {self.name}: {e}")

        return status


class PortfolioMonitor:
    """Main monitoring service for all projects."""

    def __init__(self):
        self.monitors = self._initialize_monitors()
        self.check_interval = 300  # 5 minutes
        self.report_interval = 21600  # 6 hours

        # Write PID file
        with open(PID_FILE, 'w') as f:
            f.write(str(os.getpid()))

    def __del__(self):
        """Cleanup on exit."""
        if PID_FILE.exists():
            PID_FILE.unlink()

    def _initialize_monitors(self) -> List[ProjectMonitor]:
        """Initialize monitors for all projects."""
        monitors = []

        # BookCLI Monitor
        if (PROJECTS_DIR / "bookcli").exists():
            monitors.append(ProjectMonitor(
                name="bookcli",
                path=PROJECTS_DIR / "bookcli",
                check_commands=[
                    "test -d .venv",  # Virtual env exists
                    "test -f autonomous_pipeline.py",  # Main script exists
                    "find output/fiction -type f -name '*.json' -mtime -1 | head -1 | grep -q .",  # Recent activity
                ]
            ))

        # POD System Monitor
        if (PROJECTS_DIR / "pod").exists():
            monitors.append(ProjectMonitor(
                name="pod",
                path=PROJECTS_DIR / "pod",
                check_commands=[
                    "test -d designs",  # Designs directory exists
                    "ls designs/*.png 2>/dev/null | wc -l | grep -v '^0$'",  # Has designs
                ]
            ))

        # Quant Platform Monitor
        if (PROJECTS_DIR / "quant").exists():
            monitors.append(ProjectMonitor(
                name="quant",
                path=PROJECTS_DIR / "quant",
                check_commands=[
                    "test -f backend/main.py",  # Backend exists
                    "test -f frontend/package.json",  # Frontend exists
                ]
            ))

        # Affiliate System Monitor
        if (PROJECTS_DIR / "affiliate").exists():
            monitors.append(ProjectMonitor(
                name="affiliate",
                path=PROJECTS_DIR / "affiliate",
                check_commands=[
                    "test -d content",  # Content directory exists
                    "find content -name '*.md' | wc -l | grep -v '^0$'",  # Has articles
                ]
            ))

        # BOM Study Tools Monitor
        if (PROJECTS_DIR / "bom").exists():
            monitors.append(ProjectMonitor(
                name="bom",
                path=PROJECTS_DIR / "bom",
                check_commands=[
                    "test -f docker-compose.yml",  # Docker setup exists
                    "test -d packages/mobile",  # Mobile app exists
                ]
            ))

        logger.info(f"Initialized {len(monitors)} project monitors")
        return monitors

    def check_all_projects(self) -> Dict:
        """Check health of all projects."""
        logger.info("Running health checks on all projects...")
        results = {
            'timestamp': datetime.now().isoformat(),
            'projects': {},
            'healthy_count': 0,
            'unhealthy_count': 0
        }

        for monitor in self.monitors:
            logger.info(f"Checking {monitor.name}...")
            status = monitor.check_health()

            results['projects'][monitor.name] = status

            if status['healthy']:
                results['healthy_count'] += 1
                logger.info(f"✓ {monitor.name} is healthy")
            else:
                results['unhealthy_count'] += 1
                logger.warning(f"✗ {monitor.name} has issues: {status['errors']}")

                # Auto-restart if too many failures
                if monitor.consecutive_failures >= 3:
                    logger.error(f"!!! {monitor.name} has {monitor.consecutive_failures} consecutive failures")
                    self.attempt_restart(monitor)

        return results

    def attempt_restart(self, monitor: ProjectMonitor):
        """Attempt to restart a failed project."""
        logger.info(f"Attempting to restart {monitor.name}...")

        restart_commands = {
            'bookcli': [
                "pkill -f 'bookcli_continuous_generator'",
                f"{PROJECTS_DIR}/.automation/scripts/bookcli_continuous_generator.py &"
            ],
        }

        if monitor.name in restart_commands:
            for cmd in restart_commands[monitor.name]:
                try:
                    subprocess.run(cmd, shell=True, timeout=30)
                    logger.info(f"Restart command executed: {cmd}")
                except Exception as e:
                    logger.error(f"Restart command failed: {cmd} - {e}")

            # Reset consecutive failures after restart attempt
            monitor.consecutive_failures = 0

    def generate_report(self) -> str:
        """Generate a comprehensive portfolio status report."""
        logger.info("Generating portfolio status report...")

        report_lines = [
            "# Portfolio Status Report",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "## Project Health Summary",
            ""
        ]

        # Check all projects
        results = self.check_all_projects()

        # Summary
        report_lines.extend([
            f"**Total Projects**: {len(self.monitors)}",
            f"**Healthy**: {results['healthy_count']} ✓",
            f"**Unhealthy**: {results['unhealthy_count']} ✗",
            "",
            "## Individual Project Status",
            ""
        ])

        # Individual project details
        for name, status in results['projects'].items():
            health_icon = "✓" if status['healthy'] else "✗"
            report_lines.extend([
                f"### {name} {health_icon}",
                f"- **Status**: {'Healthy' if status['healthy'] else 'UNHEALTHY'}",
                f"- **Last Check**: {status['timestamp']}",
                ""
            ])

            if status['errors']:
                report_lines.append("**Errors**:")
                for error in status['errors']:
                    report_lines.append(f"- {error}")
                report_lines.append("")

        # Load generator state if available
        generator_state_file = STATE_DIR / "generator_state.json"
        if generator_state_file.exists():
            try:
                with open(generator_state_file, 'r') as f:
                    gen_state = json.load(f)

                report_lines.extend([
                    "## BookCLI Generation Stats",
                    "",
                    f"- **Total Books Generated**: {gen_state.get('total_books', 0)}",
                    f"- **Books Today**: {gen_state.get('books_today', 0)}",
                    f"- **Daily Cost**: ${gen_state.get('daily_cost', 0):.2f}",
                    f"- **Total Errors**: {gen_state.get('total_errors', 0)}",
                    f"- **Last Success**: {gen_state.get('last_success', 'N/A')}",
                    ""
                ])
            except Exception as e:
                logger.error(f"Failed to load generator state: {e}")

        # Save report
        report_content = "\n".join(report_lines)
        report_file = REPORTS_DIR / f"status_{datetime.now():%Y%m%d_%H%M%S}.md"

        try:
            with open(report_file, 'w') as f:
                f.write(report_content)
            logger.info(f"Report saved to {report_file}")

            # Also save as latest
            latest_file = REPORTS_DIR / "latest_status.md"
            with open(latest_file, 'w') as f:
                f.write(report_content)

        except Exception as e:
            logger.error(f"Failed to save report: {e}")

        return report_content

    def run(self):
        """Main monitoring loop."""
        logger.info("Portfolio Monitor starting...")
        logger.info(f"PID: {os.getpid()}")
        logger.info(f"Check interval: {self.check_interval}s")
        logger.info(f"Report interval: {self.report_interval}s")

        last_report = datetime.now()

        while not shutdown_requested:
            try:
                # Run health checks
                self.check_all_projects()

                # Generate report if interval has passed
                if (datetime.now() - last_report).total_seconds() >= self.report_interval:
                    self.generate_report()
                    last_report = datetime.now()

                # Sleep until next check
                logger.info(f"Next check in {self.check_interval}s...")
                time.sleep(self.check_interval)

            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}", exc_info=True)
                time.sleep(60)  # Brief pause before retrying

        logger.info("Shutdown complete. Monitor stopped.")


def main():
    """Main entry point."""
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Check if already running
    if PID_FILE.exists():
        try:
            with open(PID_FILE, 'r') as f:
                old_pid = int(f.read().strip())

            # Check if process is still running
            try:
                os.kill(old_pid, 0)
                logger.error(f"Monitor already running with PID {old_pid}")
                sys.exit(1)
            except OSError:
                logger.warning(f"Removing stale PID file for process {old_pid}")
                PID_FILE.unlink()
        except Exception as e:
            logger.warning(f"Error checking PID file: {e}")

    # Start monitor
    monitor = PortfolioMonitor()
    monitor.run()


if __name__ == "__main__":
    main()
