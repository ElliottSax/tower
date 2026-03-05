#!/usr/bin/env python3
"""
Google Analytics 4 Integration
Fetches traffic and conversion data for content monitoring
"""

import json
import os
from typing import Dict, List, Optional
from datetime import datetime, timedelta


class GA4IntegrationGuide:
    """
    Setup guide for Google Analytics 4 integration
    (Implementation requires Google Analytics API credentials)
    """

    @staticmethod
    def get_setup_instructions() -> str:
        return """
# Google Analytics 4 Integration Setup

## What This Does
Connects to your GA4 account to pull:
- Page views per article
- Unique users per article
- Bounce rate per article
- Session duration per article
- Conversion events (email signup, affiliate click)
- Revenue per article

## Prerequisites
1. Google Analytics 4 property created for each site
2. API credentials (service account JSON)
3. Analytics API enabled in Google Cloud

## Step 1: Set Up GA4 Properties

For each site:
1. Go to: https://analytics.google.com
2. Admin → Property → Data Streams
3. Verify JavaScript tracking is enabled
4. Get Property ID (format: 123456789)

Property IDs for your sites:
- cardclassroom.com: [YOUR_PROPERTY_ID_1]
- dividendengines.com: [YOUR_PROPERTY_ID_2]
- thestackguide.com: [YOUR_PROPERTY_ID_3]
- quantengines.com: [YOUR_PROPERTY_ID_4]

## Step 2: Create Google Cloud Service Account

1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Create service account: "ga4-analytics"
3. Download JSON key
4. Enable Analytics API: https://console.cloud.google.com/apis/library/analyticsreporting.googleapis.com

## Step 3: Grant Analytics Access

For each GA4 property:
1. Admin → Property Access Management
2. Add email: [service-account-email]
3. Role: Editor

## Step 4: Store Credentials

```bash
# Set environment variable
export GA4_SERVICE_ACCOUNT='[paste JSON contents]'

# Or save to file
mkdir -p ~/.config/gcp
cp service-account.json ~/.config/gcp/ga4-credentials.json
```

## Step 5: Configure Sites

Create file: `ga4_config.json`

```json
{
  "credit": {
    "domain": "cardclassroom.com",
    "ga_property_id": "123456789"
  },
  "calc": {
    "domain": "dividendengines.com",
    "ga_property_id": "234567890"
  },
  "affiliate": {
    "domain": "thestackguide.com",
    "ga_property_id": "345678901"
  },
  "quant": {
    "domain": "quantengines.com",
    "ga_property_id": "456789012"
  }
}
```

## Step 6: Test Connection

```bash
python3 ga4_integration.py --test
```

## Metrics Collected

### Page Metrics
- Page views: Total views of article
- Unique users: Distinct visitors
- Bounce rate: % who left without interaction
- Avg session duration: Minutes spent on page

### Conversion Metrics
- Email signups: Tracked via event: "email_signup"
- Affiliate clicks: Tracked via event: "affiliate_click"
- Form submissions: Any tracked conversion events

### Revenue Metrics
(If using enhanced e-commerce)
- Revenue per article
- Transactions per article
- Items per transaction

## Custom Events to Track

Add these to your article pages for better monitoring:

```javascript
// Email signup event
gtag('event', 'email_signup', {
  'article_slug': 'article-title',
  'article_title': 'Full Article Title',
  'form_type': 'exit_intent' // or 'inline', 'footer', etc
});

// Affiliate click event
gtag('event', 'affiliate_click', {
  'article_slug': 'article-title',
  'affiliate_network': 'cj', // or 'rakuten', 'impact', etc
  'affiliate_url': '/go/tool-name'
});

// Content engagement
gtag('event', 'scroll_depth', {
  'article_slug': 'article-title',
  'scroll_percent': 50 // or 75, 100, etc
});
```

## Data Refresh Schedule

- Daily: Refresh daily at 2 AM UTC (via GitHub Actions)
- Weekly: Generate summary report (Sundays at 1 AM UTC)
- Monthly: Full analysis and recommendations

## API Rate Limits

- Google Analytics API: 10,000 requests/day per property
- Our usage: ~20-30 requests/day per property
- Well within limits ✅

## Cost

**Free**: Google Analytics 4 is completely free
- No additional charges for API access
- Unlimited data export
- Unlimited custom events

## Troubleshooting

### "Authentication failed"
- Verify service account email added to GA4 with Editor role
- Check JSON credentials are valid
- Verify Analytics API is enabled

### "Property not found"
- Verify Property ID is correct
- Check property has data (give it 24 hours after setup)
- Verify service account has access

### "No data available"
- GA4 can take up to 48 hours to populate
- Verify tracking code is installed and firing
- Check in GA4 Real-Time reports to confirm events

## Next Steps

1. Set up GA4 properties for each site
2. Verify tracking is working (Real-Time reports)
3. Create service account and grant access
4. Update ga4_config.json with Property IDs
5. Run integration test
6. Enable automated daily data pulls
"""

    @staticmethod
    def generate_ga4_config_template() -> Dict:
        """Generate template GA4 config"""
        return {
            "credit": {
                "domain": "cardclassroom.com",
                "ga_property_id": "YOUR_PROPERTY_ID_1",
                "tracking_enabled": False,
                "custom_events": ["email_signup", "affiliate_click"]
            },
            "calc": {
                "domain": "dividendengines.com",
                "ga_property_id": "YOUR_PROPERTY_ID_2",
                "tracking_enabled": False,
                "custom_events": ["email_signup", "affiliate_click", "calculator_used"]
            },
            "affiliate": {
                "domain": "thestackguide.com",
                "ga_property_id": "YOUR_PROPERTY_ID_3",
                "tracking_enabled": False,
                "custom_events": ["email_signup", "affiliate_click", "tool_clicked"]
            },
            "quant": {
                "domain": "quantengines.com",
                "ga_property_id": "YOUR_PROPERTY_ID_4",
                "tracking_enabled": False,
                "custom_events": ["email_signup", "affiliate_click", "backtest_run"]
            }
        }

    @staticmethod
    def generate_tracking_code() -> Dict[str, str]:
        """Generate GA4 tracking codes for each site"""
        return {
            "gtag.js_installation": """
<!-- Google tag (gtag.js) - Place in <head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
""",
            "email_signup_event": """
<!-- Track email signup -->
<script>
document.getElementById('email-form').addEventListener('submit', function(e) {
  gtag('event', 'email_signup', {
    'article_slug': document.body.getAttribute('data-article-slug'),
    'form_type': 'exit_intent'
  });
});
</script>
""",
            "affiliate_click_event": """
<!-- Track affiliate clicks -->
<script>
document.querySelectorAll('a[data-affiliate]').forEach(link => {
  link.addEventListener('click', function(e) {
    gtag('event', 'affiliate_click', {
      'article_slug': document.body.getAttribute('data-article-slug'),
      'affiliate_network': this.getAttribute('data-affiliate-network'),
      'tool_name': this.getAttribute('data-tool-name')
    });
  });
});
</script>
""",
            "scroll_depth_tracking": """
<!-- Track scroll depth -->
<script>
let maxScroll = 0;
window.addEventListener('scroll', function() {
  const scrollPercent = Math.round((window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100);

  // Report at 25%, 50%, 75%, 100%
  if (scrollPercent > maxScroll) {
    if (scrollPercent >= 100 && maxScroll < 100) {
      gtag('event', 'scroll_to_100', {
        'article_slug': document.body.getAttribute('data-article-slug')
      });
    } else if (scrollPercent >= 75 && maxScroll < 75) {
      gtag('event', 'scroll_to_75', {
        'article_slug': document.body.getAttribute('data-article-slug')
      });
    } else if (scrollPercent >= 50 && maxScroll < 50) {
      gtag('event', 'scroll_to_50', {
        'article_slug': document.body.getAttribute('data-article-slug')
      });
    }
    maxScroll = scrollPercent;
  }
});
</script>
"""
        }


def generate_ga4_setup_files():
    """Generate GA4 setup files"""
    guide = GA4IntegrationGuide()

    # Save setup guide
    with open('GA4_SETUP_GUIDE.md', 'w') as f:
        f.write(guide.get_setup_instructions())

    # Save config template
    config = guide.generate_ga4_config_template()
    with open('ga4_config.json', 'w') as f:
        json.dump(config, f, indent=2)

    # Save tracking code snippets
    tracking = guide.generate_tracking_code()
    with open('GA4_TRACKING_CODE.md', 'w') as f:
        f.write("# GA4 Custom Event Tracking Code\n\n")
        for name, code in tracking.items():
            f.write(f"## {name}\n\n```javascript\n{code}\n```\n\n")

    print("✅ Generated GA4 setup files:")
    print("   - GA4_SETUP_GUIDE.md")
    print("   - ga4_config.json")
    print("   - GA4_TRACKING_CODE.md")


if __name__ == '__main__':
    generate_ga4_setup_files()
