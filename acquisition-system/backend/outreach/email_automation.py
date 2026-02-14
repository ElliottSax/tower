"""
Email automation integration with Instantly.ai and Smartlead.ai.
Handles campaign management, email sending, and response tracking.
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
import time

from ..scrapers.base import APIScraper
from ..utils.config import settings
from ..utils.logging import setup_logging, log_error


logger = setup_logging(__name__)


@dataclass
class EmailCampaign:
    """Email campaign configuration."""
    id: str
    name: str
    status: str  # draft, active, paused, completed
    total_sent: int = 0
    total_delivered: int = 0
    total_opened: int = 0
    total_replied: int = 0


@dataclass
class EmailTouch:
    """Individual email touch/send."""
    id: str
    campaign_id: str
    recipient_email: str
    recipient_name: str
    subject: str
    body: str
    scheduled_at: datetime
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    opened_at: Optional[datetime] = None
    replied_at: Optional[datetime] = None
    status: str = "scheduled"  # scheduled, sent, delivered, opened, replied, bounced, failed


class EmailAutomation:
    """Base class for email automation."""

    def __init__(self):
        self.provider = None
        self.api = None

    def create_campaign(self, name: str, settings_dict: Dict) -> EmailCampaign:
        """Create new email campaign."""
        raise NotImplementedError

    def send_email(
        self,
        campaign_id: str,
        recipient_email: str,
        recipient_name: str,
        subject: str,
        body: str,
        schedule_at: Optional[datetime] = None
    ) -> EmailTouch:
        """Schedule/send email."""
        raise NotImplementedError

    def get_campaign_stats(self, campaign_id: str) -> Dict:
        """Get campaign statistics."""
        raise NotImplementedError

    def check_responses(self, since: Optional[datetime] = None) -> List[Dict]:
        """Check for new email responses."""
        raise NotImplementedError


class InstantlyAutomation(EmailAutomation):
    """Instantly.ai email automation."""

    def __init__(self):
        super().__init__()

        if not settings.instantly_api_key:
            raise ValueError("INSTANTLY_API_KEY not configured")

        self.api = APIScraper(
            api_key=settings.instantly_api_key,
            base_url="https://api.instantly.ai/api/v1"
        )
        self.provider = "instantly"

        logger.info("Initialized Instantly.ai automation")

    def create_campaign(self, name: str, settings_dict: Dict) -> EmailCampaign:
        """Create campaign in Instantly."""
        try:
            response = self.api.api_post("campaign/create", data={
                "name": name,
                "from_name": settings.outreach_from_name,
                "from_email": settings.outreach_from_email,
                "reply_to": settings.outreach_from_email,
                "daily_limit": settings_dict.get('daily_limit', settings.warmup_daily_limit_max),
                "schedule": settings_dict.get('schedule', {
                    "start_hour": 9,
                    "end_hour": 17,
                    "days": [1, 2, 3, 4, 5]  # Mon-Fri
                })
            })

            return EmailCampaign(
                id=response['campaign_id'],
                name=name,
                status='draft'
            )

        except Exception as e:
            log_error(logger, e, {'name': name})
            raise

    def send_email(
        self,
        campaign_id: str,
        recipient_email: str,
        recipient_name: str,
        subject: str,
        body: str,
        schedule_at: Optional[datetime] = None
    ) -> EmailTouch:
        """Add lead to campaign (Instantly handles sending)."""
        try:
            # Add lead to campaign
            response = self.api.api_post("lead/add", data={
                "campaign_id": campaign_id,
                "email": recipient_email,
                "first_name": recipient_name.split()[0] if recipient_name else "",
                "last_name": " ".join(recipient_name.split()[1:]) if len(recipient_name.split()) > 1 else "",
                "custom_variables": {
                    "personalized_subject": subject,
                    "personalized_body": body
                }
            })

            touch = EmailTouch(
                id=response.get('lead_id', ''),
                campaign_id=campaign_id,
                recipient_email=recipient_email,
                recipient_name=recipient_name,
                subject=subject,
                body=body,
                scheduled_at=schedule_at or datetime.now(),
                status='scheduled'
            )

            logger.info(f"Added lead to Instantly campaign: {recipient_email}")
            return touch

        except Exception as e:
            log_error(logger, e, {
                'campaign_id': campaign_id,
                'recipient': recipient_email
            })
            raise

    def get_campaign_stats(self, campaign_id: str) -> Dict:
        """Get campaign statistics from Instantly."""
        try:
            response = self.api.api_get(f"campaign/{campaign_id}/analytics")

            return {
                'total_sent': response.get('sent', 0),
                'total_delivered': response.get('delivered', 0),
                'total_opened': response.get('opened', 0),
                'total_clicked': response.get('clicked', 0),
                'total_replied': response.get('replied', 0),
                'total_bounced': response.get('bounced', 0),
                'open_rate': response.get('open_rate', 0),
                'reply_rate': response.get('reply_rate', 0)
            }

        except Exception as e:
            log_error(logger, e, {'campaign_id': campaign_id})
            return {}

    def check_responses(self, since: Optional[datetime] = None) -> List[Dict]:
        """Check for new responses."""
        try:
            params = {}
            if since:
                params['since'] = since.isoformat()

            response = self.api.api_get("campaign/replies", params=params)

            replies = []
            for reply in response.get('data', []):
                replies.append({
                    'lead_email': reply['email'],
                    'subject': reply['subject'],
                    'body': reply['body'],
                    'replied_at': reply['timestamp'],
                    'campaign_id': reply.get('campaign_id')
                })

            return replies

        except Exception as e:
            log_error(logger, e)
            return []


class SmartleadAutomation(EmailAutomation):
    """Smartlead.ai email automation."""

    def __init__(self):
        super().__init__()

        if not settings.smartlead_api_key:
            raise ValueError("SMARTLEAD_API_KEY not configured")

        self.api = APIScraper(
            api_key=settings.smartlead_api_key,
            base_url="https://server.smartlead.ai/api/v1"
        )
        self.provider = "smartlead"

        logger.info("Initialized Smartlead.ai automation")

    def create_campaign(self, name: str, settings_dict: Dict) -> EmailCampaign:
        """Create campaign in Smartlead."""
        try:
            response = self.api.api_post("campaigns", data={
                "name": name,
                "client_id": 1,
                "from_name": settings.outreach_from_name,
                "from_email": settings.outreach_from_email
            })

            return EmailCampaign(
                id=str(response['id']),
                name=name,
                status='draft'
            )

        except Exception as e:
            log_error(logger, e, {'name': name})
            raise

    def send_email(
        self,
        campaign_id: str,
        recipient_email: str,
        recipient_name: str,
        subject: str,
        body: str,
        schedule_at: Optional[datetime] = None
    ) -> EmailTouch:
        """Add lead to Smartlead campaign."""
        try:
            response = self.api.api_post(f"campaigns/{campaign_id}/leads", data={
                "lead_email": recipient_email,
                "first_name": recipient_name.split()[0] if recipient_name else "",
                "last_name": " ".join(recipient_name.split()[1:]) if len(recipient_name.split()) > 1 else "",
                "custom_fields": {
                    "personalized_subject": subject,
                    "personalized_body": body
                }
            })

            touch = EmailTouch(
                id=str(response.get('id', '')),
                campaign_id=campaign_id,
                recipient_email=recipient_email,
                recipient_name=recipient_name,
                subject=subject,
                body=body,
                scheduled_at=schedule_at or datetime.now(),
                status='scheduled'
            )

            logger.info(f"Added lead to Smartlead campaign: {recipient_email}")
            return touch

        except Exception as e:
            log_error(logger, e, {
                'campaign_id': campaign_id,
                'recipient': recipient_email
            })
            raise

    def get_campaign_stats(self, campaign_id: str) -> Dict:
        """Get campaign statistics."""
        try:
            response = self.api.api_get(f"campaigns/{campaign_id}/analytics")

            return {
                'total_sent': response.get('sent', 0),
                'total_delivered': response.get('delivered', 0),
                'total_opened': response.get('opened', 0),
                'total_replied': response.get('replied', 0),
                'open_rate': response.get('open_rate', 0),
                'reply_rate': response.get('reply_rate', 0)
            }

        except Exception as e:
            log_error(logger, e, {'campaign_id': campaign_id})
            return {}

    def check_responses(self, since: Optional[datetime] = None) -> List[Dict]:
        """Check for new responses."""
        try:
            params = {}
            if since:
                params['after'] = since.isoformat()

            response = self.api.api_get("campaigns/replies", params=params)

            replies = []
            for reply in response.get('data', []):
                replies.append({
                    'lead_email': reply['lead_email'],
                    'subject': reply['subject'],
                    'body': reply['body_text'],
                    'replied_at': reply['replied_at'],
                    'campaign_id': reply.get('campaign_id')
                })

            return replies

        except Exception as e:
            log_error(logger, e)
            return []


def get_email_automation() -> EmailAutomation:
    """
    Factory function to get configured email automation provider.

    Returns:
        EmailAutomation instance (Instantly or Smartlead)
    """
    if settings.instantly_api_key:
        return InstantlyAutomation()
    elif settings.smartlead_api_key:
        return SmartleadAutomation()
    else:
        raise ValueError("No email automation provider configured (INSTANTLY_API_KEY or SMARTLEAD_API_KEY)")


# Example usage
if __name__ == "__main__":
    automation = get_email_automation()

    # Create campaign
    campaign = automation.create_campaign(
        name="Q1 2026 HVAC Outreach",
        settings_dict={'daily_limit': 50}
    )

    print(f"Created campaign: {campaign.id}")

    # Add lead
    touch = automation.send_email(
        campaign_id=campaign.id,
        recipient_email="owner@example.com",
        recipient_name="John Smith",
        subject="Quick question about Smith HVAC",
        body="Hi John,\n\nI came across Smith HVAC and was impressed by..."
    )

    print(f"Added lead: {touch.recipient_email}")

    # Get stats
    time.sleep(5)
    stats = automation.get_campaign_stats(campaign.id)
    print(f"Campaign stats: {stats}")
