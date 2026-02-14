#!/usr/bin/env python3
"""
Scheduler for automated pipeline execution.
Uses the `schedule` library for cron-like job scheduling.
"""

import time
import signal
import sys
from datetime import datetime, timedelta
from typing import Dict

import schedule

# Add parent to path for imports
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent.parent))

from orchestration.pipeline import AcquisitionPipeline
from utils.config import settings
from utils.logging import setup_logging, log_error
from utils.notifications import get_notifier, NotificationType


logger = setup_logging(__name__, log_file=__import__('pathlib').Path('../../logs/scheduler.log'))


class PipelineScheduler:
    """
    Schedules and runs pipeline jobs automatically.

    Default schedule:
    - 2:00 AM: Scrape Secretary of State data
    - 3:00 AM: Enrich new leads (email lookup)
    - 4:00 AM: Score/re-score businesses
    - 5:00 AM (Sunday): Verify emails
    - 9:00 AM (Mon-Fri): Send outreach emails
    - 6:00 PM: Daily summary notification
    """

    def __init__(self):
        self.pipeline = None
        self.running = True
        self.daily_stats = self._reset_stats()

        # Track active campaign for outreach
        self.active_campaign_id = None

        # Graceful shutdown
        signal.signal(signal.SIGINT, self._shutdown)
        signal.signal(signal.SIGTERM, self._shutdown)

    def _get_pipeline(self) -> AcquisitionPipeline:
        """Lazy-init pipeline to avoid startup errors blocking scheduler."""
        if self.pipeline is None:
            try:
                self.pipeline = AcquisitionPipeline()
            except Exception as e:
                logger.error(f"Failed to initialize pipeline: {e}")
                raise
        return self.pipeline

    def _reset_stats(self) -> Dict:
        return {
            'businesses_scraped': 0,
            'emails_found': 0,
            'leads_scored': 0,
            'hot_leads': 0,
            'emails_sent': 0,
            'responses': 0,
            'interested': 0,
            'errors': 0,
        }

    def _shutdown(self, signum, frame):
        """Handle graceful shutdown."""
        logger.info("Shutdown signal received, stopping scheduler...")
        self.running = False

    def setup_schedule(self):
        """Configure the job schedule."""
        logger.info("Setting up job schedule...")

        # Daily scraping job - 2:00 AM
        schedule.every().day.at("02:00").do(self.run_scraping)

        # Daily enrichment job - 3:00 AM
        schedule.every().day.at("03:00").do(self.run_enrichment)

        # Daily scoring job - 4:00 AM
        schedule.every().day.at("04:00").do(self.run_scoring)

        # Weekly email verification - Sunday 5:00 AM
        schedule.every().sunday.at("05:00").do(self.run_email_verification)

        # Weekday outreach - 9:00 AM Mon-Fri
        schedule.every().monday.at("09:00").do(self.run_outreach)
        schedule.every().tuesday.at("09:00").do(self.run_outreach)
        schedule.every().wednesday.at("09:00").do(self.run_outreach)
        schedule.every().thursday.at("09:00").do(self.run_outreach)
        schedule.every().friday.at("09:00").do(self.run_outreach)

        # Check for responses - every 2 hours during business hours
        schedule.every(2).hours.do(self.check_responses)

        # Daily summary - 6:00 PM
        schedule.every().day.at("18:00").do(self.send_daily_summary)

        # Reset daily stats at midnight
        schedule.every().day.at("00:00").do(self._reset_daily_stats)

        # Website analysis - weekly on Saturday
        schedule.every().saturday.at("03:00").do(self.run_website_analysis)

        logger.info("Schedule configured:")
        for job in schedule.get_jobs():
            logger.info(f"  {job}")

    def run_scraping(self):
        """Execute scraping job."""
        logger.info("Running scheduled scraping job")

        try:
            pipeline = self._get_pipeline()
            results = pipeline.run_scraping_job()

            self.daily_stats['businesses_scraped'] += results.get('businesses_found', 0)

            logger.info(f"Scraping complete: {results.get('businesses_found', 0)} found")

        except Exception as e:
            self._handle_error("scraping", e)

    def run_enrichment(self):
        """Execute enrichment job."""
        logger.info("Running scheduled enrichment job")

        try:
            pipeline = self._get_pipeline()
            results = pipeline.run_enrichment_job(limit=200)

            self.daily_stats['emails_found'] += results.get('emails_found', 0)

            logger.info(f"Enrichment complete: {results.get('emails_found', 0)} emails found")

        except Exception as e:
            self._handle_error("enrichment", e)

    def run_scoring(self):
        """Execute scoring job."""
        logger.info("Running scheduled scoring job")

        try:
            pipeline = self._get_pipeline()
            results = pipeline.run_scoring_job(limit=2000)

            self.daily_stats['leads_scored'] += results.get('businesses_scored', 0)
            new_hot = results.get('hot_leads', 0)
            self.daily_stats['hot_leads'] += new_hot

            # Notify about new hot leads
            if new_hot > 0:
                notifier = get_notifier()
                notifier.notify(
                    NotificationType.HOT_LEAD,
                    f"{new_hot} New Hot Leads Detected",
                    f"Scoring identified **{new_hot}** new hot leads ready for outreach.",
                    fields={
                        "Total Scored": str(results.get('businesses_scored', 0)),
                        "Hot": str(new_hot),
                        "Warm": str(results.get('warm_leads', 0)),
                    },
                    color="orange"
                )

            logger.info(f"Scoring complete: {results.get('businesses_scored', 0)} scored, {new_hot} hot")

        except Exception as e:
            self._handle_error("scoring", e)

    def run_outreach(self):
        """Execute outreach job."""
        if not self.active_campaign_id:
            logger.info("No active campaign configured, skipping outreach")
            return

        logger.info("Running scheduled outreach job")

        try:
            pipeline = self._get_pipeline()
            results = pipeline.run_outreach_job(
                campaign_id=self.active_campaign_id,
                limit=50
            )

            self.daily_stats['emails_sent'] += results.get('emails_sent', 0)

            logger.info(f"Outreach complete: {results.get('emails_sent', 0)} emails sent")

        except Exception as e:
            self._handle_error("outreach", e)

    def run_email_verification(self):
        """Execute email verification job."""
        logger.info("Running scheduled email verification job")

        try:
            from enrichment.email_verification import EmailVerifier
            from utils.database import execute_query

            verifier = EmailVerifier()

            # Get unverified emails
            query = """
                SELECT email FROM contacts
                WHERE email IS NOT NULL
                  AND (email_verified = false OR email_verified_at < NOW() - INTERVAL '90 days')
                LIMIT 500
            """
            contacts = execute_query(query)
            emails = [c['email'] for c in contacts if c['email']]

            if emails:
                results = verifier.verify_batch(emails)
                verifier.update_database(results)

                valid = sum(1 for r in results if r.is_valid)
                logger.info(f"Verification complete: {valid}/{len(emails)} valid")

        except Exception as e:
            self._handle_error("email_verification", e)

    def run_website_analysis(self):
        """Analyze websites for digital decay signals."""
        logger.info("Running scheduled website analysis")

        try:
            from scrapers.website_analyzer import WebsiteAnalyzer
            from utils.database import execute_query, get_db

            analyzer = WebsiteAnalyzer()

            # Get businesses with websites not analyzed recently
            query = """
                SELECT id, website_url FROM businesses
                WHERE website_url IS NOT NULL
                  AND (website_last_updated IS NULL OR website_last_updated < NOW() - INTERVAL '30 days')
                LIMIT 200
            """
            businesses = execute_query(query)

            for business in businesses:
                try:
                    result = analyzer.analyze(business['website_url'])

                    with get_db() as db:
                        from sqlalchemy import text
                        db.execute(text("""
                            UPDATE businesses
                            SET website_ssl_valid = :ssl_valid,
                                website_last_updated = :analyzed_date,
                                last_updated_at = NOW()
                            WHERE id = :id
                        """), {
                            'ssl_valid': result.ssl_valid,
                            'analyzed_date': datetime.now().date(),
                            'id': business['id'],
                        })

                except Exception as e:
                    logger.debug(f"Website analysis failed for {business['website_url']}: {e}")
                    continue

            logger.info(f"Website analysis complete: {len(businesses)} sites analyzed")

        except Exception as e:
            self._handle_error("website_analysis", e)

    def check_responses(self):
        """Check for new email responses."""
        try:
            pipeline = self._get_pipeline()
            automation = pipeline.email_automation
            since = datetime.now() - timedelta(hours=2)

            responses = automation.check_responses(since=since)

            if responses:
                self.daily_stats['responses'] += len(responses)

                # Classify responses
                from outreach.response_classifier import ResponseClassifier
                classifier = ResponseClassifier()
                notifier = get_notifier()

                for resp in responses:
                    result = classifier.classify(
                        response_text=resp.get('body', ''),
                    )

                    if result.sentiment.value == 'interested':
                        self.daily_stats['interested'] += 1

                        notifier.notify_response(
                            business_name=resp.get('business_name', 'Unknown'),
                            owner_name=resp.get('lead_email', 'Unknown'),
                            sentiment=result.sentiment.value,
                            summary=result.summary
                        )

                logger.info(f"Processed {len(responses)} new responses")

        except Exception as e:
            logger.debug(f"Response check failed: {e}")

    def send_daily_summary(self):
        """Send daily summary notification."""
        try:
            notifier = get_notifier()
            notifier.notify_daily_summary(**self.daily_stats)
            logger.info("Daily summary sent")

        except Exception as e:
            logger.error(f"Failed to send daily summary: {e}")

    def _reset_daily_stats(self):
        """Reset daily statistics."""
        self.daily_stats = self._reset_stats()
        logger.info("Daily stats reset")

    def _handle_error(self, job_name: str, error: Exception):
        """Handle job error with logging and notification."""
        self.daily_stats['errors'] += 1
        log_error(logger, error, {'job': job_name})

        try:
            notifier = get_notifier()
            notifier.notify_error(
                error_type=f"Job Failed: {job_name}",
                error_message=str(error),
                context={'job': job_name, 'time': datetime.now().isoformat()}
            )
        except Exception:
            pass  # Don't let notification failure crash the scheduler

    def run(self):
        """Start the scheduler loop."""
        self.setup_schedule()

        logger.info("Scheduler started. Press Ctrl+C to stop.")
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Scheduler running. Jobs:")
        for job in schedule.get_jobs():
            print(f"  - {job}")
        print("\nPress Ctrl+C to stop.\n")

        while self.running:
            try:
                schedule.run_pending()
                time.sleep(30)  # Check every 30 seconds
            except Exception as e:
                logger.error(f"Scheduler error: {e}")
                time.sleep(60)

        logger.info("Scheduler stopped")


def main():
    """Entry point for scheduler."""
    import argparse

    parser = argparse.ArgumentParser(description='Acquisition System Scheduler')
    parser.add_argument('--campaign-id', help='Active campaign ID for outreach')
    parser.add_argument('--run-now', choices=['scrape', 'enrich', 'score', 'outreach', 'verify', 'websites', 'all'],
                       help='Run a specific job immediately instead of scheduling')
    args = parser.parse_args()

    scheduler = PipelineScheduler()

    if args.campaign_id:
        scheduler.active_campaign_id = args.campaign_id

    if args.run_now:
        # Run specific job immediately
        jobs = {
            'scrape': scheduler.run_scraping,
            'enrich': scheduler.run_enrichment,
            'score': scheduler.run_scoring,
            'outreach': scheduler.run_outreach,
            'verify': scheduler.run_email_verification,
            'websites': scheduler.run_website_analysis,
        }

        if args.run_now == 'all':
            for name, job in jobs.items():
                print(f"\nRunning {name}...")
                job()
        else:
            jobs[args.run_now]()
    else:
        # Start scheduled execution
        scheduler.run()


if __name__ == "__main__":
    main()
