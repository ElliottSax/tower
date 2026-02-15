#!/usr/bin/env python3
"""
BookCLI Continuous Generation Daemon
Runs 24/7, continuously generating books with intelligent throttling and error recovery.
"""

import os
import sys
import time
import json
import signal
import logging
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional, Dict

# Configuration
BOOKCLI_DIR = Path("/mnt/e/projects/bookcli")
SCRIPT_DIR = Path(__file__).parent
LOG_DIR = SCRIPT_DIR.parent.parent / ".agent-logs" / "automation"
STATE_FILE = SCRIPT_DIR.parent / "state" / "generator_state.json"
PID_FILE = SCRIPT_DIR.parent / "state" / "generator.pid"

# Ensure directories exist
LOG_DIR.mkdir(parents=True, exist_ok=True)
STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / f"generator_{datetime.now():%Y%m%d}.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("BookCLI.Daemon")

# Global shutdown flag
shutdown_requested = False


def signal_handler(signum, frame):
    """Handle shutdown signals gracefully."""
    global shutdown_requested
    signal_name = signal.Signals(signum).name
    logger.info(f"Received {signal_name}, initiating graceful shutdown...")
    shutdown_requested = True


class GeneratorState:
    """Persistent state management for the generator."""

    def __init__(self, state_file: Path):
        self.state_file = state_file
        self.state = self.load()

    def load(self) -> Dict:
        """Load state from disk."""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Failed to load state: {e}")

        return {
            'started_at': datetime.now().isoformat(),
            'total_books': 0,
            'total_errors': 0,
            'last_success': None,
            'last_error': None,
            'daily_cost': 0.0,
            'cost_reset_date': datetime.now().date().isoformat(),
            'consecutive_errors': 0,
            'books_today': 0
        }

    def save(self):
        """Save state to disk."""
        try:
            with open(self.state_file, 'w') as f:
                json.dump(self.state, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save state: {e}")

    def reset_daily_counters(self):
        """Reset daily counters if it's a new day."""
        today = datetime.now().date().isoformat()
        if self.state['cost_reset_date'] != today:
            logger.info("New day - resetting daily counters")
            self.state['daily_cost'] = 0.0
            self.state['books_today'] = 0
            self.state['cost_reset_date'] = today
            self.save()

    def record_success(self, cost: float = 0.0):
        """Record a successful book generation."""
        self.reset_daily_counters()
        self.state['total_books'] += 1
        self.state['books_today'] += 1
        self.state['daily_cost'] += cost
        self.state['last_success'] = datetime.now().isoformat()
        self.state['consecutive_errors'] = 0
        self.save()
        logger.info(f"Success recorded. Total books: {self.state['total_books']}, Today: {self.state['books_today']}")

    def record_error(self):
        """Record a generation error."""
        self.state['total_errors'] += 1
        self.state['consecutive_errors'] += 1
        self.state['last_error'] = datetime.now().isoformat()
        self.save()
        logger.warning(f"Error recorded. Consecutive errors: {self.state['consecutive_errors']}")

    def should_continue(self, daily_budget: float = 20.0, max_books_per_day: int = 100) -> tuple[bool, str]:
        """Check if we should continue generating."""
        self.reset_daily_counters()

        # Check daily cost limit
        if self.state['daily_cost'] >= daily_budget:
            return False, f"Daily budget reached: ${self.state['daily_cost']:.2f} / ${daily_budget:.2f}"

        # Check daily book limit
        if self.state['books_today'] >= max_books_per_day:
            return False, f"Daily book limit reached: {self.state['books_today']} / {max_books_per_day}"

        # Check consecutive errors (circuit breaker)
        if self.state['consecutive_errors'] >= 5:
            return False, f"Circuit breaker: {self.state['consecutive_errors']} consecutive errors"

        return True, "OK"


class BookCLIDaemon:
    """Main daemon for continuous book generation."""

    def __init__(self):
        self.state = GeneratorState(STATE_FILE)
        self.daily_budget = float(os.getenv('BOOKCLI_DAILY_BUDGET', '20.0'))
        self.max_books_per_day = int(os.getenv('BOOKCLI_MAX_BOOKS_PER_DAY', '100'))
        self.error_backoff = [60, 300, 900, 1800, 3600]  # Exponential backoff in seconds

        # Write PID file
        with open(PID_FILE, 'w') as f:
            f.write(str(os.getpid()))

    def __del__(self):
        """Cleanup on exit."""
        if PID_FILE.exists():
            PID_FILE.unlink()

    def generate_book(self) -> tuple[bool, float]:
        """
        Generate a single book using BookCLI.
        Returns: (success: bool, cost: float)
        """
        try:
            import subprocess

            # Change to BookCLI directory
            os.chdir(BOOKCLI_DIR)

            # Activate virtual environment and run generator
            venv_python = BOOKCLI_DIR / ".venv" / "bin" / "python3"

            if not venv_python.exists():
                logger.error(f"Virtual environment not found: {venv_python}")
                return False, 0.0

            # Run the autonomous pipeline
            logger.info("Starting book generation...")
            result = subprocess.run(
                [str(venv_python), "autonomous_pipeline.py", "--single"],
                capture_output=True,
                text=True,
                timeout=3600  # 1 hour timeout
            )

            if result.returncode == 0:
                logger.info("Book generation completed successfully")
                logger.debug(f"Output: {result.stdout[-500:]}")  # Last 500 chars

                # Try to extract cost from output (if available)
                cost = 0.0
                if "cost:" in result.stdout.lower():
                    # Parse cost from output
                    try:
                        cost_line = [line for line in result.stdout.split('\n') if 'cost:' in line.lower()][0]
                        cost = float(cost_line.split('$')[1].split()[0])
                    except:
                        cost = 5.0  # Default estimate
                else:
                    cost = 5.0  # Default estimate

                return True, cost
            else:
                logger.error(f"Book generation failed with code {result.returncode}")
                logger.error(f"Error: {result.stderr[-500:]}")  # Last 500 chars
                return False, 0.0

        except subprocess.TimeoutExpired:
            logger.error("Book generation timed out after 1 hour")
            return False, 0.0
        except Exception as e:
            logger.error(f"Exception during book generation: {e}", exc_info=True)
            return False, 0.0

    def run(self):
        """Main daemon loop."""
        logger.info("BookCLI Continuous Generator Daemon starting...")
        logger.info(f"Daily budget: ${self.daily_budget}")
        logger.info(f"Max books per day: {self.max_books_per_day}")
        logger.info(f"PID: {os.getpid()}")
        logger.info(f"State file: {STATE_FILE}")

        error_count = 0

        while not shutdown_requested:
            # Check if we should continue
            can_continue, reason = self.state.should_continue(
                daily_budget=self.daily_budget,
                max_books_per_day=self.max_books_per_day
            )

            if not can_continue:
                logger.info(f"Pausing generation: {reason}")

                # If it's a daily limit, wait until next day
                if "Daily" in reason:
                    # Calculate sleep time until next day
                    now = datetime.now()
                    tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
                    sleep_seconds = (tomorrow - now).total_seconds()
                    logger.info(f"Sleeping until next day ({sleep_seconds/3600:.1f} hours)...")

                    # Sleep in chunks to allow for shutdown
                    while sleep_seconds > 0 and not shutdown_requested:
                        chunk = min(sleep_seconds, 300)  # 5 minute chunks
                        time.sleep(chunk)
                        sleep_seconds -= chunk

                    continue

                # For circuit breaker, wait and retry
                if "Circuit breaker" in reason:
                    logger.info("Circuit breaker triggered - waiting 1 hour before retry...")
                    time.sleep(3600)
                    # Reset consecutive errors after waiting
                    self.state.state['consecutive_errors'] = 0
                    self.state.save()
                    continue

            # Generate a book
            logger.info("=" * 80)
            logger.info(f"Starting book generation (Total: {self.state.state['total_books']}, Today: {self.state.state['books_today']})")

            success, cost = self.generate_book()

            if success:
                self.state.record_success(cost)
                error_count = 0

                # Brief pause between successful generations
                logger.info("Pausing 60 seconds before next generation...")
                time.sleep(60)
            else:
                self.state.record_error()
                error_count += 1

                # Exponential backoff on errors
                backoff_index = min(error_count - 1, len(self.error_backoff) - 1)
                backoff_seconds = self.error_backoff[backoff_index]
                logger.warning(f"Error occurred. Backing off for {backoff_seconds} seconds...")
                time.sleep(backoff_seconds)

        logger.info("Shutdown complete. Daemon stopped.")


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
                os.kill(old_pid, 0)  # Signal 0 just checks if process exists
                logger.error(f"Daemon already running with PID {old_pid}")
                sys.exit(1)
            except OSError:
                # Process doesn't exist, remove stale PID file
                logger.warning(f"Removing stale PID file for process {old_pid}")
                PID_FILE.unlink()
        except Exception as e:
            logger.warning(f"Error checking PID file: {e}")

    # Start daemon
    daemon = BookCLIDaemon()
    daemon.run()


if __name__ == "__main__":
    main()
