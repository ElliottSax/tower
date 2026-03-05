#!/usr/bin/env python3
"""
Content Monitoring System
Tracks article performance: rankings, traffic, conversions, email captures
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import csv
from dataclasses import dataclass, asdict, field


@dataclass
class ArticleMetrics:
    """Metrics for a single article"""
    slug: str
    title: str
    date_published: str
    site: str

    # Search performance
    keyword: str = ""
    position: float = 0.0  # Average ranking position
    impressions: int = 0
    clicks: int = 0
    ctr: float = 0.0  # Click-through rate

    # Traffic metrics
    pageviews: int = 0
    unique_visitors: int = 0
    bounce_rate: float = 0.0
    avg_session_duration: float = 0.0
    pages_per_session: float = 0.0

    # Conversion metrics
    email_signups: int = 0
    affiliate_clicks: int = 0
    affiliate_conversions: int = 0
    revenue: float = 0.0

    # Content quality
    word_count: int = 0
    reading_time_minutes: int = 0
    grade_score: float = 0.0

    # Derived metrics
    revenue_per_pageview: float = 0.0
    conversion_rate: float = 0.0
    value_score: float = 0.0  # Composite score

    last_updated: str = field(default_factory=lambda: datetime.now().isoformat())


class ContentMonitor:
    """Monitors and analyzes article performance across all sites"""

    def __init__(self, data_dir: str = "content-monitoring-data"):
        """Initialize monitor"""
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(exist_ok=True)
        self.metrics_file = self.data_dir / "article_metrics.csv"
        self.summary_file = self.data_dir / "summary_report.json"
        self.performance_tiers_file = self.data_dir / "performance_tiers.json"

    def load_articles_from_directories(self) -> Dict[str, List[Dict]]:
        """
        Load article metadata from all 4 sites
        Returns: {site_name: [articles]}
        """
        articles = {}

        sites_config = {
            'credit': '/mnt/e/projects/credit/app/blog',
            'calc': '/mnt/e/projects/calc/app/blog',
            'affiliate': '/mnt/e/projects/affiliate/thestackguide/app/blog',
            'quant': '/mnt/e/projects/quant/quant/frontend/src/app/blog'
        }

        for site_name, blog_dir in sites_config.items():
            site_articles = []
            blog_path = Path(blog_dir)

            if not blog_path.exists():
                print(f"⚠️  {site_name}: Directory not found - {blog_dir}")
                continue

            # Find all markdown files
            md_files = list(blog_path.glob("*.md"))

            for md_file in md_files:
                try:
                    with open(md_file, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Extract frontmatter
                    if content.startswith('---'):
                        parts = content.split('---', 2)
                        if len(parts) >= 2:
                            frontmatter_str = parts[1]
                            body = parts[2] if len(parts) > 2 else ""

                            # Parse YAML-like frontmatter
                            article_data = self._parse_frontmatter(frontmatter_str)
                            article_data['slug'] = md_file.stem
                            article_data['site'] = site_name
                            article_data['file_path'] = str(md_file)
                            article_data['word_count'] = len(body.split())
                            article_data['reading_time_minutes'] = max(1, article_data['word_count'] // 200)

                            site_articles.append(article_data)

                except Exception as e:
                    print(f"⚠️  Error reading {md_file}: {e}")

            articles[site_name] = site_articles
            print(f"✅ {site_name}: Found {len(site_articles)} articles")

        return articles

    def _parse_frontmatter(self, frontmatter_str: str) -> Dict:
        """Parse YAML frontmatter into dictionary"""
        data = {}
        for line in frontmatter_str.strip().split('\n'):
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip().lower()
                value = value.strip().strip("'\"")
                data[key] = value
        return data

    def create_initial_metrics(self, articles_by_site: Dict[str, List[Dict]]) -> List[ArticleMetrics]:
        """Create initial metrics for all articles"""
        metrics_list = []

        for site, articles in articles_by_site.items():
            for article in articles:
                metric = ArticleMetrics(
                    slug=article.get('slug', 'unknown'),
                    title=article.get('title', 'Untitled'),
                    date_published=article.get('date', datetime.now().isoformat()),
                    site=site,
                    word_count=article.get('word_count', 0),
                    reading_time_minutes=article.get('reading_time_minutes', 0),
                )
                metrics_list.append(metric)

        return metrics_list

    def save_metrics_csv(self, metrics: List[ArticleMetrics]):
        """Save metrics to CSV for spreadsheet analysis"""
        if not metrics:
            return

        # Convert to dicts for CSV writing
        rows = [asdict(m) for m in metrics]

        with open(self.metrics_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=asdict(metrics[0]).keys())
            writer.writeheader()
            writer.writerows(rows)

        print(f"✅ Saved metrics to: {self.metrics_file}")

    def generate_summary_report(self, metrics: List[ArticleMetrics]) -> Dict:
        """Generate high-level summary statistics"""
        if not metrics:
            return {}

        # Group by site
        by_site = {}
        for metric in metrics:
            if metric.site not in by_site:
                by_site[metric.site] = []
            by_site[metric.site].append(metric)

        # Calculate per-site stats
        site_stats = {}
        for site, site_metrics in by_site.items():
            site_stats[site] = {
                'total_articles': len(site_metrics),
                'total_pageviews': sum(m.pageviews for m in site_metrics),
                'total_clicks': sum(m.clicks for m in site_metrics),
                'total_email_signups': sum(m.email_signups for m in site_metrics),
                'total_affiliate_clicks': sum(m.affiliate_clicks for m in site_metrics),
                'total_revenue': sum(m.revenue for m in site_metrics),
                'avg_position': sum(m.position for m in site_metrics if m.position > 0) / max(1, len([m for m in site_metrics if m.position > 0])),
                'avg_bounce_rate': sum(m.bounce_rate for m in site_metrics) / len(site_metrics) if site_metrics else 0,
            }

        # Overall stats
        overall = {
            'generated_at': datetime.now().isoformat(),
            'total_articles': len(metrics),
            'total_pageviews': sum(m.pageviews for m in metrics),
            'total_clicks': sum(m.clicks for m in metrics),
            'total_email_signups': sum(m.email_signups for m in metrics),
            'total_affiliate_revenue': sum(m.revenue for m in metrics),
            'by_site': site_stats,
        }

        return overall

    def identify_performance_tiers(self, metrics: List[ArticleMetrics]) -> Dict:
        """Segment articles into performance tiers"""
        if not metrics:
            return {}

        # Calculate value_score for each article
        for metric in metrics:
            # Composite score: (traffic * 0.4) + (conversions * 0.3) + (engagement * 0.3)
            traffic_score = min(metric.pageviews / 100, 10)  # 0-10 scale
            conversion_score = (metric.email_signups + metric.affiliate_clicks) * 2  # Weighted
            engagement_score = (100 - metric.bounce_rate) / 10 if metric.bounce_rate < 100 else 0  # 0-10 scale

            metric.value_score = (traffic_score * 0.4) + (conversion_score * 0.3) + (engagement_score * 0.3)

        # Sort by value score
        sorted_metrics = sorted(metrics, key=lambda m: m.value_score, reverse=True)

        # Divide into tiers
        total = len(sorted_metrics)
        tier_size = max(1, total // 3)

        tiers = {
            'high_performers': sorted_metrics[:tier_size],
            'medium_performers': sorted_metrics[tier_size:2*tier_size],
            'low_performers': sorted_metrics[2*tier_size:],
        }

        # Convert to serializable format
        result = {}
        for tier_name, tier_articles in tiers.items():
            result[tier_name] = [
                {
                    'slug': m.slug,
                    'title': m.title,
                    'site': m.site,
                    'value_score': m.value_score,
                    'pageviews': m.pageviews,
                    'email_signups': m.email_signups,
                    'affiliate_clicks': m.affiliate_clicks,
                }
                for m in tier_articles
            ]

        return result

    def generate_action_items(self, tiers: Dict) -> List[str]:
        """Generate actionable recommendations based on performance"""
        recommendations = []

        # High performers - amplify
        if tiers.get('high_performers'):
            count = len(tiers['high_performers'])
            recommendations.append(f"✅ {count} HIGH PERFORMERS - Amplify these:")
            for article in tiers['high_performers'][:3]:
                recommendations.append(f"   • {article['title']} ({article['site']}) - Score: {article['value_score']:.1f}")
            recommendations.append("")

        # Medium performers - optimize
        if tiers.get('medium_performers'):
            recommendations.append("🔄 MEDIUM PERFORMERS - Optimize these:")
            recommendations.append("   • Add internal links from high performers")
            recommendations.append("   • Update with fresh data and examples")
            recommendations.append("   • Add email capture CTAs")
            recommendations.append("")

        # Low performers - investigate
        if tiers.get('low_performers'):
            count = len(tiers['low_performers'])
            recommendations.append(f"⚠️  {count} LOW PERFORMERS - Investigate:")
            recommendations.append("   • Check keyword difficulty (may be too competitive)")
            recommendations.append("   • Verify article is indexable in GSC")
            recommendations.append("   • Improve title/meta description for CTR")
            recommendations.append("   • Consider consolidating with similar topics")

        return recommendations


def main():
    """Main execution"""
    print(f"\n{'='*70}")
    print(f"📊 Content Monitoring System - Initial Setup")
    print(f"{'='*70}\n")

    monitor = ContentMonitor(data_dir="/mnt/e/projects/content-engine/content-monitoring-data")

    # Step 1: Load articles
    print("Step 1: Loading articles from all 4 sites...")
    articles = monitor.load_articles_from_directories()

    # Step 2: Create initial metrics
    print("\nStep 2: Creating initial metrics for all articles...")
    metrics = monitor.create_initial_metrics(articles)
    print(f"✅ Created metrics for {len(metrics)} articles")

    # Step 3: Save metrics
    print("\nStep 3: Saving metrics to CSV...")
    monitor.save_metrics_csv(metrics)

    # Step 4: Generate summary
    print("\nStep 4: Generating summary report...")
    summary = monitor.generate_summary_report(metrics)
    with open(monitor.summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    print(f"✅ Saved summary to: {monitor.summary_file}")
    print(f"\nInitial Statistics:")
    print(f"  Total articles: {summary.get('total_articles', 0)}")
    for site, stats in summary.get('by_site', {}).items():
        print(f"  {site.upper()}: {stats['total_articles']} articles")

    # Step 5: Create performance tiers (baseline)
    print("\nStep 5: Creating performance tier structure...")
    tiers = monitor.identify_performance_tiers(metrics)
    with open(monitor.performance_tiers_file, 'w') as f:
        json.dump(tiers, f, indent=2)
    print(f"✅ Saved performance tiers to: {monitor.performance_tiers_file}")

    # Step 6: Generate recommendations
    print("\nStep 6: Initial Recommendations:")
    recommendations = monitor.generate_action_items(tiers)
    for rec in recommendations:
        print(rec)

    print(f"\n{'='*70}")
    print(f"✅ Content Monitoring initialized successfully")
    print(f"{'='*70}")
    print(f"\nNext steps:")
    print(f"1. Integrate Google Search Console data (track rankings)")
    print(f"2. Integrate Google Analytics 4 (track traffic)")
    print(f"3. Set up conversion tracking (email signups, affiliate clicks)")
    print(f"4. Create automated weekly reports")


if __name__ == '__main__':
    main()
