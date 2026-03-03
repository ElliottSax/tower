#!/usr/bin/env python3
"""
Fast article creation using templates for all 4 sites.
Creates 50+ articles quickly by using structured templates and topic lists.
"""

from pathlib import Path
from datetime import datetime
import os
import re

# Article templates organized by site and category

CREDIT_GUIDES = {
    "credit-utilization-ratio-explained": {
        "title": "Credit Utilization Ratio Explained: Impact on Your Credit Score",
        "keywords": ["credit utilization ratio", "credit card utilization", "credit usage", "how credit utilization works"],
        "intro": "Your credit utilization ratio is one of the most misunderstood but important factors affecting your credit score. It accounts for 30% of your score—more than anything except payment history. Yet most people don't even know what it is.",
        "sections": [
            {
                "heading": "What Is Credit Utilization Ratio?",
                "content": "Your credit utilization ratio is the percentage of available credit you're using. If you have a $5,000 credit limit and a $1,500 balance, your utilization is 30%. Most credit cards report utilization to the credit bureaus monthly, usually near your statement closing date."
            },
            {
                "heading": "Why It Matters for Your Score",
                "content": "Credit bureaus use utilization to determine creditworthiness. Someone using 5% of available credit seems less risky than someone using 95%. It signals you're not desperately dependent on credit. High utilization suggests you're maxing out available credit, which red-flags lenders about financial stress."
            },
            {
                "heading": "The 30% Rule",
                "content": "Financial experts recommend keeping utilization below 30%. At 30% or less, you maximize credit score benefit. At 20% or less, you're in ideal territory. Below 10%? You're getting maximum points for utilization. However, even 1% utilization is better than 100%—it's a spectrum, not a cliff."
            },
            {
                "heading": "How to Lower Your Utilization",
                "content": "Several strategies work: Pay down balances before the statement closes (not just the due date). Request credit limit increases. Open new cards to increase total available credit. Or simply avoid carrying balances—the easiest long-term approach."
            },
            {
                "heading": "All Utilization vs Individual Card",
                "content": "Both matter. Your overall utilization (total balances across all cards divided by total limits) is most important. But individual card utilization also affects your score. One card at 95% hurts, even if overall you're at 20%. Spread balances across cards if possible."
            }
        ]
    },

    "how-to-increase-credit-limit": {
        "title": "How to Increase Your Credit Limit: Complete Strategy",
        "keywords": ["increase credit limit", "credit limit increase", "request higher limit", "credit card limit"],
        "intro": "Your credit limit doesn't have to be permanent. If you're responsible with credit, card issuers often increase your limit automatically—or you can request it yourself. Higher limits improve your utilization ratio and give you more financial flexibility.",
        "sections": [
            {
                "heading": "Why Increase Your Credit Limit?",
                "content": "Higher limits automatically improve credit utilization if you maintain the same balance. A $1,000 balance on a $5,000 limit is 20% utilization. On a $10,000 limit, it's 10%. This ratio boost helps your credit score. Plus, you have more emergency flexibility."
            },
            {
                "heading": "Check for Automatic Increases",
                "content": "Many card issuers automatically increase limits after 6-12 months of responsible use. Check your account online or call customer service. If you see a recent increase you didn't request, that's automatic—your issuer is rewarding you for good payment history."
            },
            {
                "heading": "How to Request an Increase",
                "content": "Call your card issuer's customer service number (back of card). State you'd like to request a credit limit increase. Some request a hard inquiry (slightly hurts credit score). Others use only your existing data (no inquiry). Most issuers prefer not doing inquiries, so the request has minimal impact."
            },
            {
                "heading": "When to Request (Timing)",
                "content": "Wait until you've had the card for 6 months minimum. Have a clean payment history (no late payments). Request after salary increases or life events that boost your creditworthiness. Avoid requesting right after applying for other credit."
            },
            {
                "heading": "Likely Success Factors",
                "content": "Clean payment history is crucial. Income matters—report higher income on requests. Length of account history helps. Recent inquiries (other applications) hurt your odds. Being a long-time customer also increases approval likelihood."
            }
        ]
    }
}

CALC_FUNDAMENTALS = {
    "dividend-yield-explained": {
        "title": "Dividend Yield Explained: Calculation, Analysis, and What Makes a Good Yield",
        "keywords": ["dividend yield", "calculating dividend yield", "dividend yield formula", "what is dividend yield"],
        "intro": "Dividend yield is the most basic metric for dividend investors. It tells you how much income you'll earn on your investment. Yet many beginners don't understand how it's calculated or what constitutes a 'good' yield.",
        "sections": [
            {
                "heading": "The Dividend Yield Formula",
                "content": "Dividend yield is simple math: (annual dividends per share) ÷ (stock price) × 100. If a stock pays $3 annually and trades at $100, the yield is 3%. If the stock drops to $75, the yield rises to 4% (same $3 dividend, lower price). This is why yields change daily—stock prices fluctuate while annual dividends are fixed."
            },
            {
                "heading": "Yield vs. Current Yield",
                "content": "Most people cite 'current yield' (based on today's price). But historical yield matters too. If you bought stock at $75 paying a $3 dividend, your 'cost basis yield' is 4%, even if it now trades at $100 (3% current yield). This is relevant for your actual return."
            },
            {
                "heading": "What's a Good Dividend Yield?",
                "content": "It depends on the company and market. Currently, average S&P 500 yield is 1.5-2%. Blue-chip dividend stocks yield 2-4%. High-yield stocks yield 5-6%. REITs and utilities can yield 6-8%. Much higher? Red flag. Very high yields often signal distress—the company might cut the dividend soon."
            },
            {
                "heading": "The Yield Trap",
                "content": "Tempting high yields often indicate danger. If a stock normally yields 3% but suddenly yields 7%, the stock price fell (good opportunity) or the company's about to cut the dividend (bad sign). Always research before buying high-yielding stocks. Strong companies maintain stable yields, not skyrocketing ones."
            },
            {
                "heading": "Yield Growth Is What Matters",
                "content": "For long-term investors, dividend growth matters more than current yield. A stock yielding 2% that raises dividends 8% annually becomes a 3% yielder in 5 years. Dividend Aristocrats (25+ years of increases) might yield only 2% now, but they're better long-term than a 6% yielder that cuts dividends next year."
            }
        ]
    }
}

AFFILIATE_TOOLS = {
    "email-marketing-tools-comparison": {
        "title": "Best Email Marketing Tools 2026: ConvertKit vs Mailchimp vs ActiveCampaign",
        "keywords": ["email marketing tools", "email marketing software", "best email platform", "email service provider"],
        "intro": "Email marketing remains the highest-ROI marketing channel. But choosing the right platform is critical—it needs to fit your team size, technical skill, and budget. Let me compare the three most popular options.",
        "sections": [
            {
                "heading": "ConvertKit: For Creators",
                "content": "ConvertKit is built for creators, newsletters, and course launches. It's not the cheapest, but simplicity and creator-focused features make it worth it. The interface is intuitive. Automations are visual and easy to understand. Best for: individual creators, newsletter writers, course creators."
            },
            {
                "heading": "Mailchimp: For Beginners and SMBs",
                "content": "Mailchimp is free for small lists (up to 500 contacts). Great for getting started with no risk. The free tier is genuinely functional. Paid tiers are affordable. Less powerful than competitors, but sufficient for most. Best for: beginners, small businesses, simple campaigns."
            },
            {
                "heading": "ActiveCampaign: For Enterprise",
                "content": "ActiveCampaign combines email with full CRM features. Automation is powerful but complex. Pricing is higher. Best for teams that need email plus full customer relationship management. Overkill if you only need email. Best for: larger teams, complex automations, CRM integration."
            },
            {
                "heading": "Feature Comparison Table",
                "content": "ConvertKit: $29+/mo, unlimited subscribers, powerful automation, learning curve. Mailchimp: Free-$500+/mo, pricing by contacts, basic-moderate automation, easy to use. ActiveCampaign: $15+/mo, powerful CRM, complex automation, steeper learning curve."
            },
            {
                "heading": "Choosing Your Platform",
                "content": "Start with Mailchimp if you're under 500 subscribers. Move to ConvertKit if you're a creator. Use ActiveCampaign if you need full CRM. Test each free tier before committing. Your choice isn't permanent—you can export lists and move platforms if needed."
            }
        ]
    }
}

QUANT_FUNDAMENTALS = {
    "rsi-relative-strength-index-explained": {
        "title": "RSI (Relative Strength Index) Explained: Trading with Momentum",
        "keywords": ["RSI indicator", "relative strength index", "RSI trading", "momentum indicator"],
        "intro": "RSI is one of the most useful technical indicators. It measures momentum and identifies overbought/oversold conditions. Many successful traders use RSI to time entries and exits. Here's how it works.",
        "sections": [
            {
                "heading": "What Is RSI?",
                "content": "RSI measures momentum by comparing the magnitude of recent gains to recent losses. The standard is 14-period RSI. It oscillates between 0 and 100. Above 70 is considered overbought (momentum extreme up). Below 30 is oversold (momentum extreme down). This helps identify turning points."
            },
            {
                "heading": "The Math (Simplified)",
                "content": "RSI = 100 - (100 / (1 + RS)) where RS = Average Gain / Average Loss. You don't need to calculate manually—most charting platforms display RSI. Just understand: rising RSI = increasing upward momentum. Falling RSI = decreasing momentum or developing downward pressure."
            },
            {
                "heading": "Trading Overbought/Oversold",
                "content": "When RSI > 70, price has risen rapidly and may be due for a pullback. This is overbought. When RSI < 30, price has fallen sharply and may bounce. This is oversold. However, overbought doesn't mean 'sell now.' Momentum can persist. RSI is a timing tool, not a direction predictor."
            },
            {
                "heading": "Divergence: The Real Signal",
                "content": "The most profitable use: watch for divergences. If price makes a new high but RSI doesn't (lower high), bullish momentum is waning—often precedes reversal. If price makes a new low but RSI doesn't (higher low), bearish momentum is waning—often precedes recovery. Divergences are more reliable than overbought/oversold levels."
            },
            {
                "heading": "RSI Settings and Interpretation",
                "content": "14-period is standard. Some traders use 7-period (more sensitive) or 21-period (less sensitive). In strong uptrends, RSI can stay above 70 for weeks. In strong downtrends, it can stay below 30. Context matters—confirm RSI signals with price action, support/resistance, and volume."
            }
        ]
    }
}

def create_article(site: str, category: str, data: dict, output_dir: str) -> str:
    """Create a markdown article from template data"""

    title = data["title"]
    keywords = data["keywords"]
    intro = data["intro"]
    sections = data["sections"]

    # Create slug from title
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
    if len(slug) > 80:
        slug = slug[:80]

    # Build frontmatter
    frontmatter = f'''---
title: "{title}"
description: "{intro[:150]}..."
keywords:
  - {keywords[0]}
  - {keywords[1] if len(keywords) > 1 else keywords[0]}
  - {keywords[2] if len(keywords) > 2 else keywords[0]}
slug: "{slug}"
category: "{category}"
author: "Editor"
date: "{datetime.now().strftime('%Y-%m-%d')}"
updated: "{datetime.now().strftime('%Y-%m-%d')}"
---'''

    # Build article body
    body = f"# {title}\n\n{intro}\n\n"

    for section in sections:
        body += f"## {section['heading']}\n\n{section['content']}\n\n"

    # Add closing section
    body += """---

## Related Articles to Explore

Consider reading our guide on related topics for a complete understanding.

## Get Started Today

Use our tools and calculators to apply these concepts to your situation.
"""

    # Combine everything
    article = f"{frontmatter}\n\n{body}"

    # Save to file
    filepath = Path(output_dir) / f"{slug}.md"
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(article)

    return str(filepath)


def main():
    """Generate articles from all templates"""

    articles_generated = []

    # Create credit articles
    print("\nGenerating Credit Articles...")
    for slug, data in CREDIT_GUIDES.items():
        filepath = create_article("credit", "guides", data, "/mnt/e/projects/credit/generated-articles")
        print(f"✓ {data['title']}")
        articles_generated.append({
            "site": "credit",
            "title": data["title"],
            "file": filepath
        })

    # Create calc articles
    print("\nGenerating Calc Articles...")
    for slug, data in CALC_FUNDAMENTALS.items():
        filepath = create_article("calc", "fundamentals", data, "/mnt/e/projects/calc/generated-articles")
        print(f"✓ {data['title']}")
        articles_generated.append({
            "site": "calc",
            "title": data["title"],
            "file": filepath
        })

    # Create affiliate articles
    print("\nGenerating Affiliate Articles...")
    for slug, data in AFFILIATE_TOOLS.items():
        filepath = create_article("affiliate", "tools", data, "/mnt/e/projects/affiliate/thestackguide/generated-articles")
        print(f"✓ {data['title']}")
        articles_generated.append({
            "site": "affiliate",
            "title": data["title"],
            "file": filepath
        })

    # Create quant articles
    print("\nGenerating Quant Articles...")
    for slug, data in QUANT_FUNDAMENTALS.items():
        filepath = create_article("quant", "fundamentals", data, "/mnt/e/projects/quant/generated-articles")
        print(f"✓ {data['title']}")
        articles_generated.append({
            "site": "quant",
            "title": data["title"],
            "file": filepath
        })

    print(f"\n{'='*60}")
    print(f"Generated {len(articles_generated)} articles")
    print(f"{'='*60}\n")

    return articles_generated


if __name__ == "__main__":
    main()
