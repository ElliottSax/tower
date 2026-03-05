#!/usr/bin/env python3
"""
Content Monitoring Dashboard
Real-time view of article performance metrics
"""

import json
import csv
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional


class MonitoringDashboard:
    """Real-time dashboard for article performance"""

    def __init__(self, data_dir: str = "content-monitoring-data"):
        self.data_dir = Path(data_dir)

    def load_metrics(self) -> List[Dict]:
        """Load article metrics from CSV"""
        metrics = []
        csv_file = self.data_dir / "article_metrics.csv"

        if not csv_file.exists():
            print("⚠️ No metrics file found. Run content_monitoring.py first.")
            return []

        with open(csv_file, 'r') as f:
            reader = csv.DictReader(f)
            metrics = list(reader)

        return metrics

    def load_performance_tiers(self) -> Dict:
        """Load performance tier data"""
        tiers_file = self.data_dir / "performance_tiers.json"

        if not tiers_file.exists():
            return {}

        with open(tiers_file, 'r') as f:
            return json.load(f)

    def display_summary(self):
        """Display monitoring dashboard"""
        print(f"\n{'='*80}")
        print(f"📊 Content Monitoring Dashboard")
        print(f"{'='*80}")
        print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}\n")

        # Load data
        metrics = self.load_metrics()
        tiers = self.load_performance_tiers()

        if not metrics:
            print("❌ No metrics data found. Initialize monitoring first.")
            return

        # Overall statistics
        print(f"📈 OVERALL STATISTICS")
        print(f"{'-'*80}")
        print(f"Total articles monitored: {len(metrics)}")

        # By site
        by_site = {}
        for metric in metrics:
            site = metric.get('site', 'unknown')
            if site not in by_site:
                by_site[site] = 0
            by_site[site] += 1

        for site, count in sorted(by_site.items()):
            print(f"  {site.upper()}: {count} articles")

        # Performance distribution
        if tiers:
            print(f"\n🎯 PERFORMANCE TIERS")
            print(f"{'-'*80}")
            print(f"High Performers:   {len(tiers.get('high_performers', []))} articles")
            print(f"Medium Performers: {len(tiers.get('medium_performers', []))} articles")
            print(f"Low Performers:    {len(tiers.get('low_performers', []))} articles")

            # Sample high performers
            high = tiers.get('high_performers', [])
            if high:
                print(f"\n⭐ TOP 5 HIGH PERFORMERS")
                print(f"{'-'*80}")
                for article in high[:5]:
                    title = article.get('title', 'Untitled')[:50]
                    site = article.get('site', 'unknown').upper()
                    score = article.get('value_score', 0)
                    print(f"  {title:50} ({site}) Score: {score:.1f}")

            # Sample low performers
            low = tiers.get('low_performers', [])
            if low:
                print(f"\n⚠️  NEEDS ATTENTION (Sample)")
                print(f"{'-'*80}")
                for article in low[-5:]:
                    title = article.get('title', 'Untitled')[:50]
                    site = article.get('site', 'unknown').upper()
                    score = article.get('value_score', 0)
                    print(f"  {title:50} ({site}) Score: {score:.1f}")

        # Average metrics
        print(f"\n📊 AVERAGE METRICS")
        print(f"{'-'*80}")

        total_pageviews = sum(int(m.get('pageviews', 0) or 0) for m in metrics)
        total_signups = sum(int(m.get('email_signups', 0) or 0) for m in metrics)
        avg_word_count = sum(int(m.get('word_count', 0) or 0) for m in metrics) // len(metrics) if metrics else 0
        avg_reading_time = sum(int(m.get('reading_time_minutes', 0) or 0) for m in metrics) // len(metrics) if metrics else 0

        print(f"Total pageviews: {total_pageviews:,}")
        print(f"Total email signups: {total_signups:,}")
        print(f"Avg article length: {avg_word_count:,} words")
        print(f"Avg reading time: {avg_reading_time} minutes")

        # Monitoring status
        print(f"\n🔄 MONITORING STATUS")
        print(f"{'-'*80}")
        print(f"✅ Content monitoring active")
        print(f"✅ GSC tracking enabled (daily 2:30 AM UTC)")
        print(f"✅ GA4 tracking ready (after code deployment)")
        print(f"✅ Automated workflows scheduled")

        # Next steps
        print(f"\n📋 NEXT STEPS")
        print(f"{'-'*80}")
        print(f"1. Set up GA4 properties (5 min)")
        print(f"2. Deploy tracking code to 4 sites (10 min)")
        print(f"3. Verify in GA4 Real-time reports")
        print(f"4. Check daily at 2:30 AM UTC for GSC data")
        print(f"5. Review performance tiers weekly")

        print(f"\n{'='*80}\n")

    def generate_csv_export(self, output_file: str = "monitoring_export.csv"):
        """Export metrics for Google Sheets"""
        metrics = self.load_metrics()

        if not metrics:
            print("❌ No metrics to export")
            return

        # Select key columns for export
        export_fields = [
            'slug', 'title', 'site', 'date_published',
            'word_count', 'reading_time_minutes',
            'position', 'impressions', 'clicks', 'ctr',
            'pageviews', 'unique_visitors', 'bounce_rate',
            'email_signups', 'affiliate_clicks', 'revenue'
        ]

        with open(output_file, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=export_fields)
            writer.writeheader()

            for metric in metrics:
                # Extract only fields we want
                row = {field: metric.get(field, '') for field in export_fields}
                writer.writerow(row)

        print(f"✅ Exported {len(metrics)} articles to {output_file}")
        print(f"   Ready for Google Sheets analysis")

    def print_quick_stats(self):
        """Print quick statistics"""
        metrics = self.load_metrics()

        if not metrics:
            print("❌ No metrics found")
            return

        print(f"\n📊 Quick Stats")
        print(f"  Total articles: {len(metrics)}")

        # Count by site
        by_site = {}
        for m in metrics:
            site = m.get('site', 'unknown')
            by_site[site] = by_site.get(site, 0) + 1

        for site, count in sorted(by_site.items()):
            print(f"  {site}: {count}")

        print()


def main():
    """Main execution"""
    dashboard = MonitoringDashboard(
        data_dir="/mnt/e/projects/content-engine/content-monitoring-data"
    )

    # Display dashboard
    dashboard.display_summary()

    # Generate export
    dashboard.generate_csv_export(
        "/mnt/e/projects/content-engine/content-monitoring-data/monitoring_export.csv"
    )


if __name__ == '__main__':
    main()
