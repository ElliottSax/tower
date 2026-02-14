"""
Main orchestration pipeline.
Coordinates scraping, enrichment, scoring, and outreach.
"""

from typing import List, Dict, Optional
from datetime import datetime, timedelta
from urllib.parse import urlparse
import json
from pathlib import Path

from ..scrapers.secretary_of_state import MultiStateSoSScraper, BusinessRecord
from ..scrapers.bizbuysell import BizBuySellScraper
from ..enrichment.email_waterfall import EmailEnrichmentWaterfall
from ..models.retirement_scorer import RetirementScorer
from ..outreach.claude_personalization import ClaudePersonalizer
from ..outreach.email_automation import get_email_automation
from ..utils.config import settings
from ..utils.database import get_db, execute_query, execute_many
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


class AcquisitionPipeline:
    """
    Main orchestration pipeline for the acquisition system.

    Workflow:
    1. Scrape businesses (SoS, BizBuySell)
    2. Enrich data (emails, firmographics)
    3. Score retirement likelihood
    4. Generate personalized messages
    5. Schedule outreach
    6. Track responses
    """

    def __init__(self):
        """Initialize pipeline components."""
        self.sos_scraper = MultiStateSoSScraper()
        self.email_enricher = EmailEnrichmentWaterfall()
        self.scorer = RetirementScorer()
        self.personalizer = ClaudePersonalizer()
        self.email_automation = get_email_automation()

        # Load trained model if available
        model_path = settings.model_output_path / "retirement_scorer.pkl"
        if model_path.exists():
            self.scorer.load_model(model_path)
            logger.info("Loaded trained scoring model")
        else:
            logger.warning("No trained model found, using rule-based scoring")

    def run_scraping_job(
        self,
        states: Optional[List[str]] = None,
        industries: Optional[List[str]] = None
    ) -> Dict:
        """
        Run scraping job to collect new businesses.

        Args:
            states: List of state codes to scrape (default: all)
            industries: Filter by industries (optional)

        Returns:
            Dict with job results
        """
        logger.info("Starting scraping job")
        start_time = datetime.now()

        # Track results
        results = {
            'businesses_found': 0,
            'businesses_inserted': 0,
            'businesses_updated': 0,
            'errors': []
        }

        try:
            # 1. Scrape Secretary of State data
            logger.info("Scraping Secretary of State data")

            if not states:
                states = ['CA', 'TX', 'FL', 'NY', 'IL']  # Top 5 states by default

            sos_businesses = self.sos_scraper.bulk_scrape(states, limit_per_state=1000)
            results['businesses_found'] += len(sos_businesses)

            # Insert into database
            for business in sos_businesses:
                try:
                    self._upsert_business(business.to_dict())
                    results['businesses_inserted'] += 1
                except Exception as e:
                    results['errors'].append(str(e))
                    continue

            # 2. Scrape BizBuySell (active marketplace listings)
            if settings.bizbuysell_scraper_enabled:
                logger.info("Scraping BizBuySell marketplace")

                with BizBuySellScraper() as bizbuysell:
                    for state in states:
                        try:
                            listings = bizbuysell.scrape(state=state, max_pages=5)
                            results['businesses_found'] += len(listings)

                            # Mark as hot leads (active listing = strong signal)
                            for listing in listings:
                                self._upsert_marketplace_listing(listing.to_dict())
                                results['businesses_inserted'] += 1

                        except Exception as e:
                            log_error(logger, e, {'state': state})
                            results['errors'].append(f"BizBuySell {state}: {str(e)}")
                            continue

        except Exception as e:
            log_error(logger, e)
            results['errors'].append(str(e))

        duration = (datetime.now() - start_time).seconds
        logger.info(f"Scraping job completed in {duration}s: {results['businesses_found']} found, {results['businesses_inserted']} inserted")

        return results

    def run_enrichment_job(self, limit: Optional[int] = None) -> Dict:
        """
        Enrich businesses that lack email/firmographic data.

        Args:
            limit: Max number of businesses to enrich

        Returns:
            Dict with job results
        """
        logger.info("Starting enrichment job")
        start_time = datetime.now()

        results = {
            'businesses_processed': 0,
            'emails_found': 0,
            'errors': []
        }

        try:
            # Get businesses without email data
            query = """
                SELECT b.id, b.name, c.full_name, c.first_name, c.last_name,
                       b.website_url, c.linkedin_url
                FROM businesses b
                LEFT JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner' AND c.is_active = true
                WHERE c.email IS NULL OR c.email_verified = false
                ORDER BY b.last_updated_at ASC
                LIMIT :limit
            """

            businesses = execute_query(query, {'limit': limit or 100})

            for business in businesses:
                try:
                    # Extract domain from website
                    domain = None
                    if business['website_url']:
                        domain = urlparse(business['website_url']).netloc

                    # Find email
                    email_result = self.email_enricher.find_email(
                        first_name=business.get('first_name'),
                        last_name=business.get('last_name'),
                        full_name=business.get('full_name'),
                        company_name=business['name'],
                        domain=domain,
                        linkedin_url=business.get('linkedin_url')
                    )

                    if email_result and email_result.email:
                        # Update contact with email
                        update_query = """
                            UPDATE contacts
                            SET email = :email,
                                email_verified = :verified,
                                email_verified_at = :verified_at,
                                updated_at = NOW()
                            WHERE business_id = :business_id
                        """

                        execute_query(update_query, {
                            'email': email_result.email,
                            'verified': email_result.verified,
                            'verified_at': datetime.now() if email_result.verified else None,
                            'business_id': business['id']
                        })

                        results['emails_found'] += 1
                        logger.info(f"Found email for {business['name']}: {email_result.email}")

                    results['businesses_processed'] += 1

                except Exception as e:
                    log_error(logger, e, {'business_id': business['id']})
                    results['errors'].append(str(e))
                    continue

        except Exception as e:
            log_error(logger, e)
            results['errors'].append(str(e))

        duration = (datetime.now() - start_time).seconds
        logger.info(f"Enrichment job completed in {duration}s: {results['emails_found']} emails found")

        # Log provider stats
        logger.info(f"Enrichment stats: {self.email_enricher.get_stats()}")

        return results

    def run_scoring_job(self, limit: Optional[int] = None) -> Dict:
        """
        Score/re-score businesses for retirement likelihood.

        Args:
            limit: Max number of businesses to score

        Returns:
            Dict with job results
        """
        logger.info("Starting scoring job")
        start_time = datetime.now()

        results = {
            'businesses_scored': 0,
            'hot_leads': 0,
            'warm_leads': 0,
            'cold_leads': 0,
            'errors': []
        }

        try:
            # Get businesses needing (re)scoring
            query = """
                SELECT b.*, c.estimated_age as owner_age
                FROM businesses b
                LEFT JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner'
                LEFT JOIN lead_scores ls ON b.id = ls.business_id
                WHERE ls.id IS NULL
                   OR ls.scored_at < NOW() - INTERVAL '30 days'
                ORDER BY b.last_updated_at DESC
                LIMIT :limit
            """

            businesses = execute_query(query, {'limit': limit or 1000})

            for business in businesses:
                try:
                    # Extract features and calculate score
                    features = self.scorer.extract_features(business)
                    score, signals = self.scorer.calculate_score(features)

                    # Insert/update score
                    score_query = """
                        INSERT INTO lead_scores (
                            business_id, composite_score,
                            signal_marketplace_listing, signal_owner_age,
                            signal_business_tenure, signal_pe_hold_period,
                            signal_digital_decay, signal_headcount_decline,
                            signal_no_succession, features,
                            model_version, scored_at
                        ) VALUES (
                            :business_id, :composite_score,
                            :sig_marketplace, :sig_owner_age,
                            :sig_tenure, :sig_pe, :sig_decay,
                            :sig_headcount, :sig_succession,
                            :features, :model_version, NOW()
                        )
                        ON CONFLICT (business_id) DO UPDATE SET
                            composite_score = EXCLUDED.composite_score,
                            signal_marketplace_listing = EXCLUDED.signal_marketplace_listing,
                            signal_owner_age = EXCLUDED.signal_owner_age,
                            signal_business_tenure = EXCLUDED.signal_business_tenure,
                            signal_pe_hold_period = EXCLUDED.signal_pe_hold_period,
                            signal_digital_decay = EXCLUDED.signal_digital_decay,
                            signal_headcount_decline = EXCLUDED.signal_headcount_decline,
                            signal_no_succession = EXCLUDED.signal_no_succession,
                            features = EXCLUDED.features,
                            model_version = EXCLUDED.model_version,
                            scored_at = NOW()
                    """

                    execute_query(score_query, {
                        'business_id': business['id'],
                        'composite_score': score,
                        'sig_marketplace': signals['marketplace_listing'],
                        'sig_owner_age': signals['owner_age'],
                        'sig_tenure': signals['business_tenure'],
                        'sig_pe': signals['pe_hold_period'],
                        'sig_decay': signals['digital_decay'],
                        'sig_headcount': signals['headcount_decline'],
                        'sig_succession': signals['no_succession_plan'],
                        'features': json.dumps(features),
                        'model_version': self.scorer.model_version
                    })

                    results['businesses_scored'] += 1

                    # Count by tier
                    if score >= settings.score_threshold_hot:
                        results['hot_leads'] += 1
                    elif score >= settings.score_threshold_warm:
                        results['warm_leads'] += 1
                    else:
                        results['cold_leads'] += 1

                except Exception as e:
                    log_error(logger, e, {'business_id': business['id']})
                    results['errors'].append(str(e))
                    continue

        except Exception as e:
            log_error(logger, e)
            results['errors'].append(str(e))

        duration = (datetime.now() - start_time).seconds
        logger.info(f"Scoring job completed in {duration}s: {results['businesses_scored']} scored")
        logger.info(f"  Hot: {results['hot_leads']}, Warm: {results['warm_leads']}, Cold: {results['cold_leads']}")

        return results

    def run_outreach_job(self, campaign_id: str, limit: int = 50) -> Dict:
        """
        Generate and send outreach emails to hot leads.

        Args:
            campaign_id: Email campaign ID
            limit: Max emails to send today

        Returns:
            Dict with job results
        """
        logger.info("Starting outreach job")
        start_time = datetime.now()

        results = {
            'emails_generated': 0,
            'emails_sent': 0,
            'errors': []
        }

        try:
            # Get hot leads not yet contacted
            query = """
                SELECT b.*, c.full_name as owner_name, c.email,
                       ls.composite_score
                FROM hot_leads hl
                JOIN businesses b ON hl.id = b.id
                JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner'
                JOIN lead_scores ls ON b.id = ls.business_id
                WHERE c.email IS NOT NULL
                  AND NOT EXISTS (
                      SELECT 1 FROM touches t
                      WHERE t.business_id = b.id
                  )
                ORDER BY ls.composite_score DESC
                LIMIT :limit
            """

            leads = execute_query(query, {'limit': limit})

            for lead in leads:
                try:
                    # Generate personalized message
                    message = self.personalizer.generate_cold_email(
                        business_name=lead['name'],
                        owner_name=lead['owner_name'],
                        industry=lead['industry'],
                        business_details=lead
                    )

                    # Schedule email
                    touch = self.email_automation.send_email(
                        campaign_id=campaign_id,
                        recipient_email=lead['email'],
                        recipient_name=lead['owner_name'],
                        subject=message.subject,
                        body=message.body
                    )

                    # Record in database
                    insert_query = """
                        INSERT INTO touches (
                            campaign_id, business_id, contact_id,
                            subject, message_body, personalized_intro,
                            scheduled_at, status
                        ) VALUES (
                            :campaign_id, :business_id, :contact_id,
                            :subject, :body, :intro,
                            :scheduled_at, 'scheduled'
                        )
                    """

                    execute_query(insert_query, {
                        'campaign_id': campaign_id,
                        'business_id': lead['id'],
                        'contact_id': lead['contact_id'],
                        'subject': message.subject,
                        'body': message.body,
                        'intro': message.personalized_intro,
                        'scheduled_at': touch.scheduled_at
                    })

                    results['emails_generated'] += 1
                    results['emails_sent'] += 1

                    logger.info(f"Scheduled email to {lead['name']} ({lead['email']})")

                except Exception as e:
                    log_error(logger, e, {'business_id': lead['id']})
                    results['errors'].append(str(e))
                    continue

        except Exception as e:
            log_error(logger, e)
            results['errors'].append(str(e))

        duration = (datetime.now() - start_time).seconds
        logger.info(f"Outreach job completed in {duration}s: {results['emails_sent']} emails sent")

        return results

    def _upsert_business(self, business_data: Dict):
        """Insert or update business record in database."""
        with get_db() as db:
            from sqlalchemy import text

            # Check if business already exists by entity number + state
            check = db.execute(
                text("SELECT id FROM businesses WHERE entity_number = :num AND state = :state"),
                {'num': business_data.get('entity_number'), 'state': business_data.get('state')}
            ).fetchone()

            if check:
                # Update existing
                db.execute(text("""
                    UPDATE businesses SET
                        name = :name,
                        status = :status,
                        street_address = :street_address,
                        city = :city,
                        zip_code = :zip_code,
                        raw_data = :raw_data,
                        data_sources = COALESCE(data_sources, '{}'::jsonb) || :data_sources,
                        last_updated_at = NOW()
                    WHERE entity_number = :entity_number AND state = :state
                """), {
                    'name': business_data.get('name'),
                    'status': business_data.get('status', 'active'),
                    'street_address': business_data.get('street_address'),
                    'city': business_data.get('city'),
                    'zip_code': business_data.get('zip_code'),
                    'raw_data': json.dumps(business_data.get('raw_data', {})),
                    'data_sources': json.dumps({'sos': business_data.get('state')}),
                    'entity_number': business_data.get('entity_number'),
                    'state': business_data.get('state'),
                })
                business_id = check[0]
            else:
                # Insert new business
                result = db.execute(text("""
                    INSERT INTO businesses (
                        name, entity_number, entity_type, incorporation_date,
                        status, state, street_address, city, zip_code,
                        raw_data, data_sources
                    ) VALUES (
                        :name, :entity_number, :entity_type, :incorporation_date,
                        :status, :state, :street_address, :city, :zip_code,
                        :raw_data, :data_sources
                    ) RETURNING id
                """), {
                    'name': business_data.get('name'),
                    'entity_number': business_data.get('entity_number'),
                    'entity_type': business_data.get('entity_type'),
                    'incorporation_date': business_data.get('incorporation_date'),
                    'status': business_data.get('status', 'active'),
                    'state': business_data.get('state'),
                    'street_address': business_data.get('street_address'),
                    'city': business_data.get('city'),
                    'zip_code': business_data.get('zip_code'),
                    'raw_data': json.dumps(business_data.get('raw_data', {})),
                    'data_sources': json.dumps({'sos': business_data.get('state')}),
                })
                business_id = result.fetchone()[0]

            # Upsert officers as contacts
            for officer in business_data.get('officers', []):
                if not officer.get('full_name'):
                    continue

                db.execute(text("""
                    INSERT INTO contacts (business_id, full_name, title, role_type, is_active)
                    VALUES (:business_id, :full_name, :title, :role_type, true)
                    ON CONFLICT DO NOTHING
                """), {
                    'business_id': business_id,
                    'full_name': officer.get('full_name'),
                    'title': officer.get('title'),
                    'role_type': officer.get('role_type', 'other'),
                })

    def _upsert_marketplace_listing(self, listing_data: Dict):
        """Insert marketplace listing and flag as active seller."""
        with get_db() as db:
            from sqlalchemy import text

            # Parse location into city/state
            location = listing_data.get('location', '')
            city, state = None, None
            if ',' in location:
                parts = [p.strip() for p in location.rsplit(',', 1)]
                city = parts[0]
                state = parts[1][:2].upper() if len(parts) > 1 else None

            # Insert or update business from listing
            result = db.execute(text("""
                INSERT INTO businesses (
                    name, industry, city, state,
                    estimated_revenue, status,
                    data_sources, raw_data
                ) VALUES (
                    :name, :industry, :city, :state,
                    :revenue, 'active',
                    :data_sources, :raw_data
                ) RETURNING id
            """), {
                'name': listing_data.get('title'),
                'industry': listing_data.get('industry'),
                'city': city,
                'state': state,
                'revenue': listing_data.get('revenue'),
                'data_sources': json.dumps({
                    'bizbuysell': True,
                    'listing_id': listing_data.get('listing_id'),
                    'listing_url': listing_data.get('listing_url'),
                }),
                'raw_data': json.dumps(listing_data),
            })
            business_id = result.fetchone()[0]

            # Auto-score marketplace listings as hot (active listing = 0.30 weight)
            db.execute(text("""
                INSERT INTO lead_scores (
                    business_id, composite_score,
                    signal_marketplace_listing,
                    model_version, scored_at
                ) VALUES (
                    :business_id, :score, 1.0,
                    'marketplace_auto', NOW()
                )
                ON CONFLICT (business_id) DO UPDATE SET
                    composite_score = GREATEST(lead_scores.composite_score, EXCLUDED.composite_score),
                    signal_marketplace_listing = 1.0,
                    scored_at = NOW()
            """), {
                'business_id': business_id,
                'score': 0.30,  # Marketplace listing weight alone
            })

            logger.info(f"Inserted marketplace listing: {listing_data.get('title')}")


# Example usage
if __name__ == "__main__":
    pipeline = AcquisitionPipeline()

    # Run full pipeline
    print("1. Scraping...")
    scrape_results = pipeline.run_scraping_job(states=['CA', 'TX'])
    print(f"   Found: {scrape_results['businesses_found']}")

    print("\n2. Enriching...")
    enrich_results = pipeline.run_enrichment_job(limit=100)
    print(f"   Emails found: {enrich_results['emails_found']}")

    print("\n3. Scoring...")
    score_results = pipeline.run_scoring_job(limit=1000)
    print(f"   Hot leads: {score_results['hot_leads']}")

    print("\n4. Outreach...")
    # outreach_results = pipeline.run_outreach_job(campaign_id='123', limit=50)
    # print(f"   Emails sent: {outreach_results['emails_sent']}")
