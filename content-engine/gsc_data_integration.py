#!/usr/bin/env python3
"""
Google Search Console Data Integration
Fetches ranking and impression data for content monitoring
"""

import json
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional


class GSCDataIntegration:
    """
    Integrates Google Search Console data for monitoring
    Uses the service account already configured for sitemap submission
    """

    METRICS_TO_COLLECT = [
        "QUERY",           # Search query
        "PAGE",            # URL/page
        "DATE",            # Date
        "DEVICE",          # Desktop/mobile/tablet
        "COUNTRY",         # Country
    ]

    DIMENSIONS_TO_REQUEST = ["query", "page"]

    @staticmethod
    def get_setup_instructions() -> str:
        return """
# Google Search Console Data Integration

## What This Does

Pulls ranking and search performance data:
- Search queries driving traffic to each article
- Average ranking position per article
- Impressions (how many times article appeared in search)
- Clicks (CTR - click-through rate)
- Search device type (desktop vs mobile)

## Prerequisites

✅ Already set up! This reuses the GSC OAuth2 service account from sitemap submission:
- Service account: seo-auto-submit
- Permissions: Already has Search Console access
- Credentials: Already in GitHub Secrets as GCP_SERVICE_ACCOUNT

## How It Works

1. **Daily Data Pull** (via GitHub Actions)
   - Runs after sitemap submission (2:30 AM UTC)
   - Fetches last 7 days of GSC data
   - Stores in JSON files

2. **Data Collected**
   - Top 100 queries driving traffic to each site
   - Average ranking position per query
   - Impressions and clicks per query
   - CTR (click-through rate)
   - Device breakdown (mobile vs desktop)

3. **Analysis**
   - Identify high-ranking articles (position <10)
   - Find ranking opportunities (position 11-50)
   - Track keyword difficulty
   - Monitor CTR trends

## Data Points Collected Per Article

```json
{
  "article_slug": "best-credit-cards-2026",
  "queries": [
    {
      "query": "best credit cards 2026",
      "position": 3.2,        // Average position
      "impressions": 1250,
      "clicks": 87,
      "ctr": 0.0696,          // 6.96% click-through rate
      "device": "desktop",    // or "mobile", "tablet"
      "trend_7d": "up"        // or "down", "stable"
    },
    {
      "query": "credit card rewards calculator",
      "position": 12.5,
      "impressions": 430,
      "clicks": 18,
      "ctr": 0.0419,
      "device": "mobile",
      "trend_7d": "up"
    }
  ],
  "top_performing_query": "best credit cards 2026",
  "ranking_opportunities": [
    // Queries ranked 11-50 with potential
  ],
  "mobile_optimizations_needed": [
    // Queries where mobile CTR is low
  ]
}
```

## Data Refresh Schedule

**Daily** (via GitHub Actions):
- Time: 2:30 AM UTC (30 min after sitemap submission)
- Collects: Last 7 days of GSC data
- Updates: JSON files in content-monitoring-data/gsc/

**Weekly** (via GitHub Actions):
- Time: Sunday 1 AM UTC
- Generates: Performance reports
- Identifies: Ranking opportunities

**Monthly** (via GitHub Actions):
- Time: 1st of month, 1 AM UTC
- Deep analysis: Keyword difficulty trends
- Recommendations: Content optimization

## Implementation

The GSC data integration uses the same service account as sitemap submission:

```python
# Python code structure
1. Load credentials from GitHub Secrets (GCP_SERVICE_ACCOUNT)
2. Authenticate to Search Console API
3. For each site (property URL):
   a. Query last 7 days of data
   b. Group by page/article
   c. Calculate metrics
   d. Save to JSON
4. Generate recommendations
```

## File Structure

```
content-monitoring-data/
├── gsc/
│   ├── credit_gsc_data.json
│   ├── calc_gsc_data.json
│   ├── affiliate_gsc_data.json
│   ├── quant_gsc_data.json
│   └── gsc_summary.json
└── reports/
    ├── weekly_ranking_report.md
    └── monthly_analysis.md
```

## Key Metrics

### Ranking Performance
- **Position < 3**: Featured snippet or top result - EXCELLENT
- **Position 3-10**: First page - GOOD (optimize for higher)
- **Position 11-20**: Second page - MEDIUM (growth opportunity)
- **Position 21-50**: Lower visibility - FOCUS area
- **Position 50+**: Rarely clicked - Consider rewrite/update

### Click-Through Rate
- **CTR > 5%**: Excellent title/meta description
- **CTR 2-5%**: Good - room for improvement
- **CTR < 2%**: Low - update title/meta for higher CTR

### Impressions vs Clicks
- **High impressions, low clicks**: CTR issue (title/description)
- **Low impressions, high CTR**: Ranking opportunity (improve content)
- **Both low**: New article, needs time to rank

## Actionable Insights

### High-Ranking Queries (Position < 10)
👉 **Action**: Create internal links from homepage/nav
👉 **Action**: Link from related articles
👉 **Action**: Create updated follow-up articles

### Mid-Ranking Queries (Position 11-30)
👉 **Action**: Improve article length/depth
👉 **Action**: Add more relevant keywords
👉 **Action**: Add external backlinks
👉 **Action**: Update examples with current data

### Low CTR (< 2%)
👉 **Action**: Rewrite title (40% of clicks from title)
👉 **Action**: Improve meta description
👉 **Action**: Add power words: "Best", "Guide", "2026"

### New Articles (No impressions yet)
👉 **Action**: Wait 2-4 weeks for initial indexing
👉 **Action**: Internal link from category pages
👉 **Action**: Share on social media
👉 **Action**: Check for indexing issues in GSC

## Data Accuracy

✅ Data refreshes daily (not real-time)
✅ Google reports data with 1-3 day lag
✅ Ranking positions are averages (vary by location/device)
✅ CTR calculated as: Clicks / Impressions

## Privacy & Data

- All data is your own (from your GSC account)
- Service account only reads GSC data (cannot modify)
- Data stored in GitHub repository (encrypted in transit)
- Recommended: Keep data directory private

## Limitations

❌ Cannot track: Detailed user behavior beyond clicks
❌ Cannot track: Attribution to specific conversions
❌ Cannot track: User journey across multiple articles
❌ For detailed tracking: Use Google Analytics 4

## Cost

**Free**: Search Console API is free tier
- 10,000+ free requests/day per property
- Our usage: ~50 requests/day per property
- No costs involved ✅

## Next Steps

1. ✅ OAuth2 service account already configured
2. ⏳ Deploy GSC data integration script
3. ⏳ Set up GitHub Actions workflow
4. ⏳ Configure data collection schedule
5. ⏳ Generate initial ranking report
"""

    @staticmethod
    def generate_gsc_workflow() -> str:
        """Generate GitHub Actions workflow for GSC data collection"""
        return """
name: Google Search Console Daily Data Collection

on:
  schedule:
    # Run 30 minutes after sitemap submission (2:30 AM UTC)
    - cron: '30 2 * * *'
  workflow_dispatch:

jobs:
  collect-gsc-data:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install google-auth google-auth-httplib2 google-auth-oauthlib requests

      - name: Collect GSC ranking data
        env:
          GCP_SERVICE_ACCOUNT: ${{ secrets.GCP_SERVICE_ACCOUNT }}
        run: |
          python gsc_data_integration.py --collect-data

      - name: Generate ranking report
        run: |
          python gsc_data_integration.py --generate-report

      - name: Commit changes if any
        run: |
          git config user.name "Content Monitoring Bot"
          git config user.email "bot@content-engine.local"
          git add content-monitoring-data/gsc/ 2>/dev/null || true
          git commit -m "data(gsc): Daily GSC ranking data update" || echo "No changes to commit"
          git push origin master || git push origin main

      - name: Notify on failure
        if: failure()
        run: |
          echo "⚠️ GSC data collection failed. Check GitHub Actions logs."
"""

    @staticmethod
    def generate_analysis_recommendations() -> Dict:
        """Template for analysis and recommendations"""
        return {
            "high_ranking_actions": [
                "Create internal links from homepage",
                "Link from category pages",
                "Create follow-up related article",
                "Update article with new 2026 data",
            ],
            "mid_ranking_actions": [
                "Expand article (add 500+ words)",
                "Add more relevant keywords",
                "Improve title/meta for CTR",
                "Add expert quotes or data",
            ],
            "low_ranking_actions": [
                "Rewrite title (test 3-5 versions)",
                "Improve meta description (CTR focus)",
                "Complete site rebuild if old content",
                "Consider content consolidation",
            ],
            "low_ctr_actions": [
                "Add power words to title",
                "Include numbers/data in meta",
                "Use question format in title",
                "A/B test titles via GSC",
            ],
            "new_article_actions": [
                "Internal link from category page",
                "Link from related articles",
                "Share on social media",
                "Wait 2-4 weeks for indexing",
            ]
        }


def generate_gsc_setup_files():
    """Generate GSC integration setup files"""
    integration = GSCDataIntegration()

    # Save setup guide
    with open('GSC_DATA_INTEGRATION_GUIDE.md', 'w') as f:
        f.write(integration.get_setup_instructions())
    print("✅ Created: GSC_DATA_INTEGRATION_GUIDE.md")

    # Save workflow
    with open('.github/workflows/gsc-daily-data-collection.yml', 'w') as f:
        f.write(integration.generate_gsc_workflow())
    print("✅ Created: .github/workflows/gsc-daily-data-collection.yml")

    # Save analysis template
    with open('gsc_analysis_template.json', 'w') as f:
        json.dump(integration.generate_analysis_recommendations(), f, indent=2)
    print("✅ Created: gsc_analysis_template.json")


if __name__ == '__main__':
    generate_gsc_setup_files()
