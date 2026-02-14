#!/usr/bin/env python3
"""
Quick start script for testing the acquisition system.
Runs a mini-pipeline on sample data.
"""

import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from models.retirement_scorer import RetirementScorer
from outreach.claude_personalization import ClaudePersonalizer
from enrichment.email_waterfall import EmailEnrichmentWaterfall
from utils.config import settings


def print_section(title):
    """Print section header."""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")


def test_scoring():
    """Test the retirement likelihood scoring model."""
    print_section("Testing Retirement Likelihood Scoring")

    scorer = RetirementScorer()

    # Sample businesses
    businesses = [
        {
            'name': 'Smith HVAC Services',
            'owner_age': 67,
            'incorporation_date': '2005-03-15',
            'bizbuysell_listing': False,
            'website_last_updated': '2022-06-01',
            'website_ssl_valid': True,
            'estimated_revenue': 2_500_000,
            'current_employees': 15,
            'employees_1_year_ago': 18,
            'industry': 'HVAC',
            'entity_type': 'LLC',
            'has_succession_plan': False
        },
        {
            'name': 'Johnson Plumbing Inc',
            'owner_age': 72,
            'incorporation_date': '1998-01-10',
            'bizbuysell_listing': True,  # Active listing!
            'website_last_updated': '2024-11-01',
            'website_ssl_valid': True,
            'estimated_revenue': 1_800_000,
            'current_employees': 12,
            'employees_1_year_ago': 12,
            'industry': 'Plumbing',
            'entity_type': 'S-Corporation',
            'has_succession_plan': False
        },
        {
            'name': 'Tech Startup LLC',
            'owner_age': 35,
            'incorporation_date': '2020-06-01',
            'bizbuysell_listing': False,
            'website_last_updated': '2026-01-15',
            'website_ssl_valid': True,
            'estimated_revenue': 500_000,
            'current_employees': 5,
            'employees_1_year_ago': 3,
            'industry': 'Software',
            'entity_type': 'LLC',
            'has_succession_plan': False
        }
    ]

    for business in businesses:
        features = scorer.extract_features(business)
        score, signals = scorer.calculate_score(features)

        # Determine tier
        if score >= 0.70:
            tier = "🔥 HOT"
            color = "\033[91m"  # Red
        elif score >= 0.45:
            tier = "🌡️  WARM"
            color = "\033[93m"  # Yellow
        else:
            tier = "❄️  COLD"
            color = "\033[94m"  # Blue
        reset = "\033[0m"

        print(f"{color}{tier}{reset} - {business['name']}")
        print(f"  Score: {score:.4f}")
        print(f"  Key signals:")
        for signal, value in signals.items():
            if value > 0.1:  # Only show significant signals
                print(f"    - {signal}: {value:.2f}")
        print()


def test_personalization():
    """Test Claude AI personalization."""
    print_section("Testing AI-Powered Personalization")

    try:
        personalizer = ClaudePersonalizer()

        business_details = {
            'years_in_business': 18,
            'estimated_revenue': 2_500_000,
            'current_employees': 15,
            'city': 'Austin',
            'state': 'TX',
            'website_url': 'https://smith-hvac.com',
            'owner_age': 67,
            'notes': 'Family-owned, excellent reputation in local community'
        }

        print("Generating personalized cold email...\n")

        message = personalizer.generate_cold_email(
            business_name="Smith HVAC Services",
            owner_name="John Smith",
            industry="HVAC",
            business_details=business_details,
            tone="professional"
        )

        print(f"SUBJECT: {message.subject}\n")
        print(f"{'='*60}")
        print(message.body)
        print(f"{'='*60}\n")

        print(f"Key talking points:")
        for i, point in enumerate(message.key_talking_points, 1):
            print(f"  {i}. {point}")

        print(f"\nCall to action: {message.call_to_action}")
        print(f"Tokens used: {message.metadata['tokens_used']}")

    except ValueError as e:
        print(f"⚠ Skipping personalization test: {e}")
        print("  → Configure ANTHROPIC_API_KEY in config/.env to enable")


def test_enrichment():
    """Test email enrichment waterfall."""
    print_section("Testing Email Enrichment Waterfall")

    try:
        enricher = EmailEnrichmentWaterfall()

        if not enricher.providers:
            print("⚠ No enrichment providers configured")
            print("  Configure one or more in config/.env:")
            print("    - PROSPEO_API_KEY")
            print("    - HUNTER_API_KEY")
            print("    - APOLLO_API_KEY")
            return

        print(f"Configured providers: {list(enricher.providers.keys())}\n")

        # This is a demo - won't actually query without valid APIs
        print("Email enrichment waterfall:")
        print("  1. Try Prospeo")
        print("  2. If not found, try DropContact")
        print("  3. If not found, try Datagma")
        print("  4. If not found, try Hunter")
        print("  5. If not found, try Apollo")
        print("\nConfigure API keys to test live enrichment")

    except Exception as e:
        print(f"⚠ Error: {e}")


def show_config():
    """Show current configuration."""
    print_section("Configuration Status")

    config_status = [
        ("Database", bool(settings.database_url), "DATABASE_URL"),
        ("Claude AI", bool(settings.anthropic_api_key), "ANTHROPIC_API_KEY"),
        ("Email Automation", bool(settings.instantly_api_key or settings.smartlead_api_key), "INSTANTLY_API_KEY or SMARTLEAD_API_KEY"),
        ("Email Enrichment", bool(settings.get_enrichment_providers()), "Email provider API keys"),
        ("Secretary of State", bool(settings.ca_sos_api_key or settings.cobalt_api_key), "SoS API keys"),
    ]

    for name, configured, key in config_status:
        status = "✓" if configured else "✗"
        color = "\033[92m" if configured else "\033[91m"
        reset = "\033[0m"
        print(f"{color}{status}{reset} {name:20s} {'[Configured]' if configured else f'[Configure {key}]'}")

    print(f"\nEdit config/.env to update configuration")


def main():
    """Run quick start tests."""
    print("\n" + "="*60)
    print("  BUSINESS ACQUISITION SYSTEM - QUICK START")
    print("="*60)

    show_config()
    test_scoring()

    # Only test personalization if API key is configured
    if settings.anthropic_api_key:
        test_personalization()
    else:
        print_section("AI Personalization")
        print("⚠ Skipped - Configure ANTHROPIC_API_KEY to test")

    test_enrichment()

    print_section("Next Steps")
    print("1. Configure missing API keys in config/.env")
    print("2. Set up database: createdb acquisition_system")
    print("3. Run migrations: psql acquisition_system < database/schema.sql")
    print("4. Use CLI tools:")
    print("   - python cli.py scrape --states CA TX")
    print("   - python cli.py enrich --limit 100")
    print("   - python cli.py score --limit 1000")
    print("   - python cli.py stats")
    print("\nSee README.md for full documentation")
    print()


if __name__ == "__main__":
    main()
