#!/usr/bin/env python3
"""
API Cost Monitoring Script
Tracks API usage and costs across all projects, sends alerts if limits are approached.
"""

import json
from pathlib import Path
from datetime import datetime, timedelta

PROJECTS_DIR = Path("/mnt/e/projects")
STATE_DIR = PROJECTS_DIR / ".automation" / "state"
REPORTS_DIR = PROJECTS_DIR / ".automation" / "reports"

STATE_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)


def log(message: str):
    """Log a message with timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] {message}")


def load_generator_state() -> dict:
    """Load BookCLI generator state."""
    state_file = STATE_DIR / "generator_state.json"
    if state_file.exists():
        try:
            with open(state_file, 'r') as f:
                return json.load(f)
        except:
            pass
    return {}


def calculate_costs(state: dict) -> dict:
    """Calculate cost summary from state."""
    daily_cost = state.get('daily_cost', 0.0)
    books_today = state.get('books_today', 0)
    total_books = state.get('total_books', 0)

    # Estimate total cost (assume $5-10 per book average)
    avg_cost_per_book = daily_cost / books_today if books_today > 0 else 7.5
    estimated_total_cost = total_books * avg_cost_per_book

    return {
        'daily_cost': daily_cost,
        'books_today': books_today,
        'total_books': total_books,
        'avg_cost_per_book': avg_cost_per_book,
        'estimated_total_cost': estimated_total_cost
    }


def check_budget_alerts(costs: dict, daily_budget: float = 20.0) -> list:
    """Check if any budget alerts should be triggered."""
    alerts = []

    # Check daily budget
    usage_pct = (costs['daily_cost'] / daily_budget) * 100 if daily_budget > 0 else 0

    if usage_pct >= 90:
        alerts.append(f"⚠ CRITICAL: Daily budget at {usage_pct:.1f}% (${costs['daily_cost']:.2f} / ${daily_budget:.2f})")
    elif usage_pct >= 75:
        alerts.append(f"⚠ WARNING: Daily budget at {usage_pct:.1f}% (${costs['daily_cost']:.2f} / ${daily_budget:.2f})")
    elif usage_pct >= 50:
        alerts.append(f"ℹ INFO: Daily budget at {usage_pct:.1f}% (${costs['daily_cost']:.2f} / ${daily_budget:.2f})")

    # Check if cost per book is too high
    if costs['avg_cost_per_book'] > 15:
        alerts.append(f"⚠ WARNING: Average cost per book is high: ${costs['avg_cost_per_book']:.2f}")

    return alerts


def generate_cost_report(costs: dict, alerts: list) -> str:
    """Generate a cost monitoring report."""
    lines = [
        "# Cost Monitoring Report",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "## Current Costs",
        "",
        f"- **Today's Cost**: ${costs['daily_cost']:.2f}",
        f"- **Books Generated Today**: {costs['books_today']}",
        f"- **Average Cost per Book**: ${costs['avg_cost_per_book']:.2f}",
        "",
        "## Lifetime Stats",
        "",
        f"- **Total Books**: {costs['total_books']}",
        f"- **Estimated Total Cost**: ${costs['estimated_total_cost']:.2f}",
        "",
    ]

    if alerts:
        lines.extend([
            "## Alerts",
            "",
        ])
        for alert in alerts:
            lines.append(f"- {alert}")
        lines.append("")

    return "\n".join(lines)


def main():
    """Main cost monitoring logic."""
    log("Running cost monitoring check...")

    # Load state
    state = load_generator_state()
    if not state:
        log("No generator state found - nothing to monitor")
        return

    # Calculate costs
    costs = calculate_costs(state)

    log(f"Today's cost: ${costs['daily_cost']:.2f} ({costs['books_today']} books)")
    log(f"Total books: {costs['total_books']}")
    log(f"Avg cost/book: ${costs['avg_cost_per_book']:.2f}")

    # Check for alerts
    alerts = check_budget_alerts(costs)

    if alerts:
        log("ALERTS DETECTED:")
        for alert in alerts:
            log(f"  {alert}")
    else:
        log("✓ No budget alerts")

    # Generate report
    report = generate_cost_report(costs, alerts)

    # Save report
    report_file = REPORTS_DIR / f"cost_{datetime.now():%Y%m%d_%H%M%S}.md"
    with open(report_file, 'w') as f:
        f.write(report)

    # Also save as latest
    latest_file = REPORTS_DIR / "latest_cost.md"
    with open(latest_file, 'w') as f:
        f.write(report)

    log(f"Report saved to {report_file}")


if __name__ == "__main__":
    main()
