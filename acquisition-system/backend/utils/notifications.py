"""
Notification system for Discord and Slack webhooks.
Alerts on hot leads, responses, and system errors.
"""

import json
from typing import Optional, Dict, List
from datetime import datetime
from enum import Enum

import requests

from .config import settings
from .logging import setup_logging, log_error


logger = setup_logging(__name__)


class NotificationType(Enum):
    """Types of notifications."""
    HOT_LEAD = "hot_lead"
    RESPONSE_RECEIVED = "response_received"
    INTERESTED_RESPONSE = "interested_response"
    DEAL_STAGE_CHANGE = "deal_stage_change"
    PIPELINE_COMPLETE = "pipeline_complete"
    SYSTEM_ERROR = "system_error"
    DAILY_SUMMARY = "daily_summary"


class NotificationService:
    """
    Sends notifications via Discord and Slack webhooks.
    """

    # Notification type → emoji mapping
    EMOJIS = {
        NotificationType.HOT_LEAD: "🔥",
        NotificationType.RESPONSE_RECEIVED: "📬",
        NotificationType.INTERESTED_RESPONSE: "🎯",
        NotificationType.DEAL_STAGE_CHANGE: "📈",
        NotificationType.PIPELINE_COMPLETE: "✅",
        NotificationType.SYSTEM_ERROR: "🚨",
        NotificationType.DAILY_SUMMARY: "📊",
    }

    def __init__(self):
        self.discord_url = settings.discord_webhook_url
        self.slack_url = settings.slack_webhook_url

        if not self.discord_url and not self.slack_url:
            logger.warning("No notification webhooks configured")

    def notify(
        self,
        notification_type: NotificationType,
        title: str,
        message: str,
        fields: Optional[Dict[str, str]] = None,
        color: Optional[str] = None
    ):
        """
        Send notification to all configured channels.

        Args:
            notification_type: Type of notification
            title: Notification title
            message: Main message text
            fields: Optional key-value pairs for structured data
            color: Optional hex color for embed
        """
        # Check if this notification type is enabled
        if not self._should_notify(notification_type):
            return

        emoji = self.EMOJIS.get(notification_type, "📌")

        if self.discord_url:
            self._send_discord(emoji, title, message, fields, color)

        if self.slack_url:
            self._send_slack(emoji, title, message, fields)

    def _should_notify(self, notification_type: NotificationType) -> bool:
        """Check if notification type is enabled."""
        if notification_type in (NotificationType.HOT_LEAD, NotificationType.INTERESTED_RESPONSE):
            return settings.notify_new_hot_leads

        if notification_type == NotificationType.RESPONSE_RECEIVED:
            return settings.notify_responses

        if notification_type == NotificationType.SYSTEM_ERROR:
            return settings.notify_errors

        return True

    def _send_discord(
        self,
        emoji: str,
        title: str,
        message: str,
        fields: Optional[Dict[str, str]] = None,
        color: Optional[str] = None
    ):
        """Send Discord webhook notification."""
        # Color mapping
        color_map = {
            'red': 0xFF0000, 'green': 0x00FF00, 'blue': 0x0000FF,
            'yellow': 0xFFFF00, 'orange': 0xFF8C00, 'purple': 0x800080,
        }

        embed_color = color_map.get(color, 0x5865F2)  # Default Discord blue

        embed = {
            "title": f"{emoji} {title}",
            "description": message,
            "color": embed_color,
            "timestamp": datetime.utcnow().isoformat(),
            "footer": {"text": "Acquisition System"}
        }

        if fields:
            embed["fields"] = [
                {"name": k, "value": str(v), "inline": True}
                for k, v in fields.items()
            ]

        payload = {"embeds": [embed]}

        try:
            response = requests.post(
                self.discord_url,
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            logger.debug(f"Discord notification sent: {title}")

        except Exception as e:
            logger.error(f"Discord notification failed: {e}")

    def _send_slack(
        self,
        emoji: str,
        title: str,
        message: str,
        fields: Optional[Dict[str, str]] = None
    ):
        """Send Slack webhook notification."""
        blocks = [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": f"{emoji} {title}"}
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": message}
            },
        ]

        if fields:
            field_blocks = []
            for k, v in fields.items():
                field_blocks.append({"type": "mrkdwn", "text": f"*{k}*\n{v}"})

            # Slack allows max 10 fields per section
            for i in range(0, len(field_blocks), 10):
                blocks.append({
                    "type": "section",
                    "fields": field_blocks[i:i+10]
                })

        blocks.append({
            "type": "context",
            "elements": [{"type": "mrkdwn", "text": f"Acquisition System | {datetime.now().strftime('%Y-%m-%d %H:%M')}"}]
        })

        payload = {"blocks": blocks}

        try:
            response = requests.post(
                self.slack_url,
                json=payload,
                timeout=10
            )
            response.raise_for_status()
            logger.debug(f"Slack notification sent: {title}")

        except Exception as e:
            logger.error(f"Slack notification failed: {e}")

    # === Convenience Methods ===

    def notify_hot_lead(self, business_name: str, score: float, industry: str, state: str, owner_name: Optional[str] = None):
        """Notify about a new hot lead."""
        fields = {
            "Score": f"{score:.4f}",
            "Industry": industry,
            "State": state,
        }
        if owner_name:
            fields["Owner"] = owner_name

        self.notify(
            NotificationType.HOT_LEAD,
            f"New Hot Lead: {business_name}",
            f"**{business_name}** scored **{score:.2f}** and is ready for outreach.",
            fields=fields,
            color="orange"
        )

    def notify_response(self, business_name: str, owner_name: str, sentiment: str, summary: str):
        """Notify about an email response."""
        notification_type = (
            NotificationType.INTERESTED_RESPONSE
            if sentiment == "interested"
            else NotificationType.RESPONSE_RECEIVED
        )

        color = "green" if sentiment == "interested" else "blue"

        self.notify(
            notification_type,
            f"Response from {owner_name} ({business_name})",
            f"**Sentiment:** {sentiment}\n**Summary:** {summary}",
            fields={"Business": business_name, "Owner": owner_name, "Sentiment": sentiment},
            color=color
        )

    def notify_deal_update(self, deal_name: str, old_stage: str, new_stage: str, value: Optional[float] = None):
        """Notify about deal stage change."""
        fields = {
            "Previous Stage": old_stage,
            "New Stage": new_stage,
        }
        if value:
            fields["Deal Value"] = f"${value:,.0f}"

        self.notify(
            NotificationType.DEAL_STAGE_CHANGE,
            f"Deal Update: {deal_name}",
            f"**{deal_name}** moved from **{old_stage}** → **{new_stage}**",
            fields=fields,
            color="green" if new_stage in ('loi_sent', 'closing', 'closed_won') else "blue"
        )

    def notify_error(self, error_type: str, error_message: str, context: Optional[Dict] = None):
        """Notify about system error."""
        fields = {"Error Type": error_type}
        if context:
            for k, v in list(context.items())[:5]:
                fields[k] = str(v)

        self.notify(
            NotificationType.SYSTEM_ERROR,
            f"System Error: {error_type}",
            f"```{error_message[:500]}```",
            fields=fields,
            color="red"
        )

    def notify_daily_summary(
        self,
        businesses_scraped: int = 0,
        emails_found: int = 0,
        leads_scored: int = 0,
        hot_leads: int = 0,
        emails_sent: int = 0,
        responses: int = 0,
        interested: int = 0
    ):
        """Send daily pipeline summary."""
        fields = {
            "Scraped": str(businesses_scraped),
            "Emails Found": str(emails_found),
            "Leads Scored": str(leads_scored),
            "Hot Leads": str(hot_leads),
            "Emails Sent": str(emails_sent),
            "Responses": str(responses),
            "Interested": str(interested),
        }

        self.notify(
            NotificationType.DAILY_SUMMARY,
            f"Daily Pipeline Summary",
            f"**{hot_leads}** new hot leads | **{responses}** responses | **{interested}** interested",
            fields=fields,
            color="purple"
        )


# Singleton
_notifier = None


def get_notifier() -> NotificationService:
    """Get global notification service instance."""
    global _notifier
    if _notifier is None:
        _notifier = NotificationService()
    return _notifier
