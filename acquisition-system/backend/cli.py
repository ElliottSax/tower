#!/usr/bin/env python3
"""
Command-line interface for the acquisition system.
"""

import click
from datetime import datetime
from pathlib import Path
import json

from .orchestration.pipeline import AcquisitionPipeline
from .models.retirement_scorer import RetirementScorer
from .outreach.claude_personalization import ClaudePersonalizer
from .utils.config import settings
from .utils.logging import setup_logging


logger = setup_logging(__name__)


@click.group()
def cli():
    """Business Acquisition System CLI."""
    pass


@cli.command()
@click.option('--states', '-s', multiple=True, help='State codes to scrape (e.g., CA, TX)')
@click.option('--all-states', is_flag=True, help='Scrape all states')
def scrape(states, all_states):
    """Scrape business data from Secretary of State and marketplaces."""
    click.echo("Starting scraping job...")

    pipeline = AcquisitionPipeline()

    if all_states:
        states = None  # Pipeline will use default list

    results = pipeline.run_scraping_job(states=list(states) if states else None)

    click.echo(f"\n✓ Scraping complete:")
    click.echo(f"  - Businesses found: {results['businesses_found']}")
    click.echo(f"  - Businesses inserted: {results['businesses_inserted']}")

    if results['errors']:
        click.echo(f"\n⚠ Errors: {len(results['errors'])}")
        for error in results['errors'][:5]:
            click.echo(f"  - {error}")


@cli.command()
@click.option('--limit', '-l', default=100, help='Max businesses to enrich')
def enrich(limit):
    """Enrich business data with emails and firmographics."""
    click.echo(f"Starting enrichment job (limit: {limit})...")

    pipeline = AcquisitionPipeline()
    results = pipeline.run_enrichment_job(limit=limit)

    click.echo(f"\n✓ Enrichment complete:")
    click.echo(f"  - Businesses processed: {results['businesses_processed']}")
    click.echo(f"  - Emails found: {results['emails_found']}")
    click.echo(f"  - Success rate: {(results['emails_found'] / max(results['businesses_processed'], 1)) * 100:.1f}%")


@cli.command()
@click.option('--limit', '-l', default=1000, help='Max businesses to score')
def score(limit):
    """Score businesses for retirement likelihood."""
    click.echo(f"Starting scoring job (limit: {limit})...")

    pipeline = AcquisitionPipeline()
    results = pipeline.run_scoring_job(limit=limit)

    click.echo(f"\n✓ Scoring complete:")
    click.echo(f"  - Businesses scored: {results['businesses_scored']}")
    click.echo(f"  - Hot leads: {results['hot_leads']} (score >= {settings.score_threshold_hot})")
    click.echo(f"  - Warm leads: {results['warm_leads']}")
    click.echo(f"  - Cold leads: {results['cold_leads']}")


@cli.command()
@click.option('--campaign-id', '-c', required=True, help='Email campaign ID')
@click.option('--limit', '-l', default=50, help='Max emails to send')
def outreach(campaign_id, limit):
    """Generate and send outreach emails."""
    click.echo(f"Starting outreach job (campaign: {campaign_id}, limit: {limit})...")

    pipeline = AcquisitionPipeline()
    results = pipeline.run_outreach_job(campaign_id=campaign_id, limit=limit)

    click.echo(f"\n✓ Outreach complete:")
    click.echo(f"  - Emails generated: {results['emails_generated']}")
    click.echo(f"  - Emails sent: {results['emails_sent']}")


@cli.command()
def pipeline():
    """Run full pipeline: scrape → enrich → score → outreach."""
    click.echo("Running full acquisition pipeline...\n")

    pipeline_obj = AcquisitionPipeline()

    # 1. Scraping
    click.echo("STEP 1/4: Scraping...")
    scrape_results = pipeline_obj.run_scraping_job()
    click.echo(f"  ✓ Found {scrape_results['businesses_found']} businesses\n")

    # 2. Enrichment
    click.echo("STEP 2/4: Enriching...")
    enrich_results = pipeline_obj.run_enrichment_job(limit=200)
    click.echo(f"  ✓ Found {enrich_results['emails_found']} emails\n")

    # 3. Scoring
    click.echo("STEP 3/4: Scoring...")
    score_results = pipeline_obj.run_scoring_job()
    click.echo(f"  ✓ Scored {score_results['businesses_scored']} businesses")
    click.echo(f"    - {score_results['hot_leads']} hot leads\n")

    # 4. Outreach (skip for safety - require explicit command)
    click.echo("STEP 4/4: Outreach (skipped)")
    click.echo("  → Run 'python cli.py outreach --campaign-id <id>' to send emails\n")

    click.echo("✓ Pipeline complete!")


@cli.command()
@click.option('--business-id', '-b', required=True, help='Business ID')
def preview(business_id):
    """Preview personalized message for a business."""
    from .utils.database import execute_query

    # Get business data
    query = """
        SELECT b.*, c.full_name as owner_name, ls.composite_score
        FROM businesses b
        LEFT JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner'
        LEFT JOIN lead_scores ls ON b.id = ls.business_id
        WHERE b.id = :business_id
    """

    businesses = execute_query(query, {'business_id': business_id})

    if not businesses:
        click.echo(f"Business {business_id} not found")
        return

    business = businesses[0]

    click.echo(f"\nBusiness: {business['name']}")
    click.echo(f"Owner: {business['owner_name']}")
    click.echo(f"Score: {business['composite_score']:.4f}\n")

    click.echo("Generating personalized message...\n")

    personalizer = ClaudePersonalizer()
    message = personalizer.generate_cold_email(
        business_name=business['name'],
        owner_name=business['owner_name'],
        industry=business['industry'],
        business_details=business
    )

    click.echo("=" * 60)
    click.echo(f"SUBJECT: {message.subject}")
    click.echo("=" * 60)
    click.echo(message.body)
    click.echo("=" * 60)
    click.echo(f"\nTokens used: {message.metadata['tokens_used']}")


@cli.command()
@click.option('--output', '-o', default='hot_leads.json', help='Output file')
@click.option('--limit', '-l', default=100, help='Max leads to export')
def export_leads(output, limit):
    """Export hot leads to JSON."""
    from .utils.database import execute_query

    query = """
        SELECT
            b.name, b.industry, b.city, b.state,
            c.full_name as owner_name, c.email,
            ls.composite_score
        FROM hot_leads hl
        JOIN businesses b ON hl.id = b.id
        LEFT JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner'
        JOIN lead_scores ls ON b.id = ls.business_id
        ORDER BY ls.composite_score DESC
        LIMIT :limit
    """

    leads = execute_query(query, {'limit': limit})

    output_path = Path(output)
    with open(output_path, 'w') as f:
        json.dump(leads, f, indent=2, default=str)

    click.echo(f"✓ Exported {len(leads)} hot leads to {output_path}")


@cli.command()
def stats():
    """Show system statistics."""
    from .utils.database import execute_query

    # Total businesses
    total = execute_query("SELECT COUNT(*) as count FROM businesses")[0]['count']

    # By status
    active = execute_query("SELECT COUNT(*) as count FROM businesses WHERE status = 'active'")[0]['count']

    # By score tier
    hot = execute_query("SELECT COUNT(*) as count FROM lead_scores WHERE score_tier = 'hot'")[0]['count']
    warm = execute_query("SELECT COUNT(*) as count FROM lead_scores WHERE score_tier = 'warm'")[0]['count']
    cold = execute_query("SELECT COUNT(*) as count FROM lead_scores WHERE score_tier = 'cold'")[0]['count']

    # Contacts with email
    with_email = execute_query("SELECT COUNT(*) as count FROM contacts WHERE email IS NOT NULL")[0]['count']

    # Recent activity
    recent_scrapes = execute_query("""
        SELECT COUNT(*) as count FROM businesses
        WHERE first_scraped_at > NOW() - INTERVAL '7 days'
    """)[0]['count']

    recent_scores = execute_query("""
        SELECT COUNT(*) as count FROM lead_scores
        WHERE scored_at > NOW() - INTERVAL '7 days'
    """)[0]['count']

    # Deal pipeline
    deals_active = execute_query("SELECT COUNT(*) as count FROM deals WHERE is_active = true")[0]['count']

    # Outreach stats
    total_sent = execute_query("SELECT COUNT(*) as count FROM touches WHERE status != 'scheduled'")[0]['count']
    total_replied = execute_query("SELECT COUNT(*) as count FROM touches WHERE replied_at IS NOT NULL")[0]['count']

    click.echo("\n" + "=" * 50)
    click.echo("ACQUISITION SYSTEM STATISTICS")
    click.echo("=" * 50)
    click.echo(f"\nBusinesses:")
    click.echo(f"  Total:        {total:,}")
    click.echo(f"  Active:       {active:,}")
    click.echo(f"\nLead Scores:")
    click.echo(f"  Hot (>=0.70): {hot:,}")
    click.echo(f"  Warm (>=0.45):{warm:,}")
    click.echo(f"  Cold (<0.45): {cold:,}")
    click.echo(f"\nData Quality:")
    click.echo(f"  With email:   {with_email:,} ({(with_email/max(total,1))*100:.1f}%)")
    click.echo(f"\nOutreach:")
    click.echo(f"  Emails sent:  {total_sent:,}")
    click.echo(f"  Replies:      {total_replied:,} ({(total_replied/max(total_sent,1))*100:.1f}%)")
    click.echo(f"\nDeals:")
    click.echo(f"  Active:       {deals_active:,}")
    click.echo(f"\nRecent Activity (7 days):")
    click.echo(f"  New scrapes:  {recent_scrapes:,}")
    click.echo(f"  New scores:   {recent_scores:,}")
    click.echo("=" * 50 + "\n")


# ======================================================================
# New Commands: Valuation, Website Analysis, Response Classification
# ======================================================================

@cli.command()
@click.option('--industry', '-i', required=True, help='Industry (hvac, plumbing, electrical, etc.)')
@click.option('--net-income', required=True, type=float, help='Net income')
@click.option('--owner-salary', default=0, type=float, help='Owner salary')
@click.option('--owner-benefits', default=0, type=float, help='Owner benefits (health, 401k, etc.)')
@click.option('--interest', default=0, type=float, help='Interest expense')
@click.option('--depreciation', default=0, type=float, help='Depreciation expense')
@click.option('--revenue', default=None, type=float, help='Annual revenue (for cross-check)')
@click.option('--owner-dependent', is_flag=True, help='High owner dependency')
def valuate(industry, net_income, owner_salary, owner_benefits, interest, depreciation, revenue, owner_dependent):
    """Calculate business valuation using SDE methodology."""
    from .models.valuation import ValuationCalculator

    calc = ValuationCalculator()

    # Calculate SDE
    sde_calc = calc.calculate_sde(
        net_income=net_income,
        owner_salary=owner_salary,
        owner_benefits=owner_benefits,
        interest=interest,
        depreciation=depreciation,
    )

    # Get adjustments
    adjustments = calc.get_standard_adjustments(
        owner_dependent=owner_dependent,
        revenue_millions=(revenue / 1_000_000) if revenue else 0,
    )

    # Valuate
    result = calc.valuate(
        business_name="Target Business",
        industry=industry,
        sde=sde_calc.sde,
        revenue=revenue,
        adjustments=adjustments,
    )

    click.echo(f"\n{'='*50}")
    click.echo(f"BUSINESS VALUATION")
    click.echo(f"{'='*50}")
    click.echo(f"\nSDE Calculation:")
    click.echo(f"  Net Income:        ${net_income:>12,.0f}")
    for ab in sde_calc.add_backs:
        click.echo(f"  + {ab.category:20s} ${ab.amount:>10,.0f}")
    click.echo(f"  {'─'*42}")
    click.echo(f"  Total SDE:         ${sde_calc.sde:>12,.0f}")
    click.echo(f"\nMultiple Range ({industry}):")
    click.echo(f"  {result.sde_multiple_low:.2f}x - {result.sde_multiple_mid:.2f}x - {result.sde_multiple_high:.2f}x")
    click.echo(f"\nValuation Range:")
    click.echo(f"  Low:               ${result.valuation_low:>12,.0f}")
    click.echo(f"  Mid:               ${result.valuation_mid:>12,.0f}")
    click.echo(f"  High:              ${result.valuation_high:>12,.0f}")

    if result.revenue:
        click.echo(f"\nRevenue Cross-Check:")
        click.echo(f"  Low:               ${result.revenue_valuation_low:>12,.0f}")
        click.echo(f"  Mid:               ${result.revenue_valuation_mid:>12,.0f}")
        click.echo(f"  High:              ${result.revenue_valuation_high:>12,.0f}")

    if result.adjustments:
        click.echo(f"\nAdjustments Applied:")
        for adj in result.adjustments:
            sign = '+' if adj['pct'] > 0 else ''
            click.echo(f"  {sign}{adj['pct']}% {adj['name']}")

    if result.suggested_structure:
        s = result.suggested_structure
        click.echo(f"\nSuggested Deal Structure:")
        click.echo(f"  Buyer Equity:      ${s.get('buyer_equity', 0):>10,.0f} ({s.get('buyer_equity_pct', 0)}%)")
        if s.get('sba_loan'):
            click.echo(f"  SBA Loan:          ${s.get('sba_loan', 0):>10,.0f} ({s.get('sba_loan_pct', 0)}%)")
        if s.get('senior_debt'):
            click.echo(f"  Senior Debt:       ${s.get('senior_debt', 0):>10,.0f} ({s.get('senior_debt_pct', 0)}%)")
        click.echo(f"  Seller Note:       ${s.get('seller_note', 0):>10,.0f} ({s.get('seller_note_pct', 0)}%)")
        if s.get('earnout'):
            click.echo(f"  Earnout:           ${s.get('earnout', 0):>10,.0f} ({s.get('earnout_pct', 0)}%)")

    click.echo(f"\n{'='*50}\n")


@cli.command()
def industries():
    """List all available industry categories with multiples."""
    from .models.valuation import ValuationCalculator, INDUSTRY_MULTIPLES

    click.echo(f"\n{'Industry':<25} {'SDE Low':>8} {'SDE Mid':>8} {'SDE High':>9} {'Rev Mid':>8} {'Median Price':>13}")
    click.echo("─" * 75)

    for key, data in INDUSTRY_MULTIPLES.items():
        if key == 'default':
            continue
        click.echo(
            f"{key:<25} {data['sde_multiple_low']:>7.2f}x {data['sde_multiple_mid']:>7.2f}x "
            f"{data['sde_multiple_high']:>8.2f}x {data['revenue_multiple_mid']:>7.2f}x "
            f"${data['median_sale_price']:>11,.0f}"
        )

    click.echo("─" * 75)
    click.echo(f"\nSource: BizBuySell 2024-2025 data\n")


@cli.command('analyze-website')
@click.option('--url', '-u', required=True, help='Website URL to analyze')
def analyze_website(url):
    """Analyze a website for digital decay signals."""
    from .scrapers.website_analyzer import WebsiteAnalyzer

    click.echo(f"Analyzing {url}...\n")

    analyzer = WebsiteAnalyzer()
    result = analyzer.analyze(url)

    click.echo(f"{'='*50}")
    click.echo(f"WEBSITE ANALYSIS: {result.url}")
    click.echo(f"{'='*50}")
    click.echo(f"\nAvailability:")
    click.echo(f"  Reachable:          {'Yes' if result.is_reachable else 'No'}")
    click.echo(f"  HTTP Status:        {result.http_status or 'N/A'}")
    click.echo(f"\nSecurity:")
    click.echo(f"  SSL Valid:          {'Yes' if result.ssl_valid else 'No'}")
    if result.ssl_expiry_date:
        click.echo(f"  SSL Expires:        {result.ssl_expiry_date} ({result.ssl_days_remaining} days)")
    click.echo(f"\nFreshness:")
    click.echo(f"  Copyright Year:     {result.copyright_year or 'Not found'}")
    click.echo(f"  CMS:                {result.cms or 'Unknown'}")
    click.echo(f"  Mobile Responsive:  {'Yes' if result.mobile_responsive else 'No'}")
    click.echo(f"  Has Analytics:      {'Yes' if result.has_analytics else 'No'}")
    click.echo(f"  Has Blog:           {'Yes' if result.has_blog else 'No'}")
    if result.blog_last_post_date:
        click.echo(f"  Blog Last Post:     {result.blog_last_post_date}")
    click.echo(f"\nSocial Links:")
    if result.social_links:
        for platform, link in result.social_links.items():
            click.echo(f"  {platform:15s} {link}")
    else:
        click.echo(f"  None found")
    click.echo(f"\nDecay Score: {result.decay_score:.2f} (0=fresh, 1=decayed)")
    if result.decay_factors:
        click.echo(f"Decay Factors:")
        for factor, value in result.decay_factors.items():
            bar = "█" * int(value * 20) + "░" * (20 - int(value * 20))
            click.echo(f"  {factor:25s} {bar} {value:.2f}")
    click.echo()


@cli.command('classify-response')
@click.option('--text', '-t', required=True, help='Response text to classify')
@click.option('--business', '-b', default=None, help='Business name')
@click.option('--owner', '-o', default=None, help='Owner name')
def classify_response(text, business, owner):
    """Classify an email response using AI."""
    from .outreach.response_classifier import ResponseClassifier

    click.echo("Classifying response...\n")

    classifier = ResponseClassifier()
    result = classifier.classify(
        response_text=text,
        business_name=business,
        owner_name=owner,
    )

    # Color-code sentiment
    colors = {
        'interested': '\033[92m',      # Green
        'not_interested': '\033[91m',   # Red
        'not_now': '\033[93m',          # Yellow
        'price_objection': '\033[93m',
        'identity_objection': '\033[93m',
        'information_request': '\033[94m', # Blue
        'hostile': '\033[91m',
        'auto_reply': '\033[90m',       # Gray
        'unsubscribe': '\033[91m',
    }
    reset = '\033[0m'
    color = colors.get(result.sentiment.value, '')

    click.echo(f"Sentiment:    {color}{result.sentiment.value}{reset} (confidence: {result.confidence:.2f})")
    click.echo(f"Summary:      {result.summary}")
    click.echo(f"Urgency:      {result.urgency}")
    click.echo(f"Action:       {result.suggested_action}")

    if result.key_concerns:
        click.echo(f"\nKey Concerns:")
        for concern in result.key_concerns:
            click.echo(f"  - {concern}")

    follow_up = classifier.should_follow_up(result)
    click.echo(f"\nFollow up:    {'Yes' if follow_up else 'No'}")
    if follow_up:
        delay = classifier.get_follow_up_delay_days(result)
        click.echo(f"Delay:        {delay} days")

    if result.follow_up_message:
        click.echo(f"\nDraft Follow-Up:")
        click.echo(f"{'─'*50}")
        click.echo(result.follow_up_message)
        click.echo(f"{'─'*50}")


@cli.command('verify-emails')
@click.option('--limit', '-l', default=100, help='Max emails to verify')
def verify_emails(limit):
    """Verify emails using ZeroBounce/NeverBounce."""
    from .enrichment.email_verification import EmailVerifier
    from .utils.database import execute_query

    click.echo(f"Verifying emails (limit: {limit})...\n")

    verifier = EmailVerifier()

    # Check credits
    credits = verifier.get_credits_remaining()
    for provider, remaining in credits.items():
        click.echo(f"  {provider} credits: {remaining}")

    # Get unverified emails
    query = """
        SELECT email FROM contacts
        WHERE email IS NOT NULL AND email_verified = false
        LIMIT :limit
    """
    contacts = execute_query(query, {'limit': limit})
    emails = [c['email'] for c in contacts if c['email']]

    if not emails:
        click.echo("\nNo unverified emails found.")
        return

    click.echo(f"\nVerifying {len(emails)} emails...")
    results = verifier.verify_batch(emails)
    verifier.update_database(results)

    valid = sum(1 for r in results if r.is_valid)
    invalid = sum(1 for r in results if not r.is_valid)

    click.echo(f"\nResults:")
    click.echo(f"  Valid:   {valid} ({valid/len(results)*100:.1f}%)")
    click.echo(f"  Invalid: {invalid} ({invalid/len(results)*100:.1f}%)")


@cli.command()
@click.option('--host', '-h', default='0.0.0.0', help='Host to bind')
@click.option('--port', '-p', default=8000, type=int, help='Port to bind')
@click.option('--reload', is_flag=True, help='Enable auto-reload for development')
def server(host, port, reload):
    """Start the FastAPI web server."""
    import uvicorn
    click.echo(f"Starting API server on {host}:{port}...")
    click.echo(f"  Docs: http://localhost:{port}/api/docs")
    click.echo(f"  Dashboard: http://localhost:{port}/")
    uvicorn.run(
        "backend.api.app:app",
        host=host,
        port=port,
        reload=reload,
    )


@cli.command()
@click.option('--campaign-id', '-c', default=None, help='Active campaign ID')
@click.option('--run-now', type=click.Choice(['scrape', 'enrich', 'score', 'outreach', 'verify', 'websites', 'all']),
              help='Run a job immediately instead of scheduling')
def scheduler(campaign_id, run_now):
    """Start the automated pipeline scheduler."""
    from .orchestration.scheduler import PipelineScheduler

    sched = PipelineScheduler()

    if campaign_id:
        sched.active_campaign_id = campaign_id

    if run_now:
        jobs = {
            'scrape': sched.run_scraping,
            'enrich': sched.run_enrichment,
            'score': sched.run_scoring,
            'outreach': sched.run_outreach,
            'verify': sched.run_email_verification,
            'websites': sched.run_website_analysis,
        }

        if run_now == 'all':
            for name, job in jobs.items():
                click.echo(f"\nRunning {name}...")
                job()
        else:
            jobs[run_now]()
    else:
        sched.run()


if __name__ == '__main__':
    cli()
