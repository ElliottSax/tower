"""Webhook handlers for email platform events."""

import hmac
import hashlib
from typing import Optional
from fastapi import APIRouter, Request, Header
from sqlalchemy import text

from ..deps import get_db
from ...utils.logging import setup_logging, log_error
from ...utils.config import settings

logger = setup_logging(__name__)

router = APIRouter()


@router.post("/instantly")
async def instantly_webhook(request: Request):
    """
    Handle Instantly.ai webhook events.

    Events: email_sent, email_opened, email_clicked, email_replied, email_bounced
    """
    try:
        payload = await request.json()
        event_type = payload.get('event', 'unknown')
        email = payload.get('email', '')
        campaign_id = payload.get('campaign_id', '')

        logger.info(f"Instantly webhook: {event_type} for {email}")

        db = next(get_db())
        try:
            _process_email_event(db, event_type, email, payload)
            db.commit()
        finally:
            db.close()

        return {"status": "ok", "event": event_type}

    except Exception as e:
        log_error(logger, e, {'source': 'instantly_webhook'})
        return {"status": "error", "message": str(e)}


@router.post("/smartlead")
async def smartlead_webhook(request: Request):
    """
    Handle Smartlead.ai webhook events.

    Events: EMAIL_SENT, EMAIL_OPENED, EMAIL_CLICKED, EMAIL_REPLIED, EMAIL_BOUNCED
    """
    try:
        payload = await request.json()
        event_type = payload.get('event_type', 'unknown').lower()
        email = payload.get('to_email', '')

        logger.info(f"Smartlead webhook: {event_type} for {email}")

        # Normalize event names
        event_map = {
            'email_sent': 'sent',
            'email_opened': 'opened',
            'email_clicked': 'clicked',
            'email_replied': 'replied',
            'email_bounced': 'bounced',
        }
        normalized = event_map.get(event_type, event_type)

        db = next(get_db())
        try:
            _process_email_event(db, normalized, email, payload)
            db.commit()
        finally:
            db.close()

        return {"status": "ok", "event": event_type}

    except Exception as e:
        log_error(logger, e, {'source': 'smartlead_webhook'})
        return {"status": "error", "message": str(e)}


@router.post("/email-reply")
async def email_reply_webhook(request: Request):
    """
    Handle inbound email reply webhooks.

    Classifies the reply sentiment and triggers follow-up logic.
    """
    try:
        payload = await request.json()
        from_email = payload.get('from_email', '')
        reply_text = payload.get('body', payload.get('text', ''))

        logger.info(f"Email reply received from {from_email}")

        db = next(get_db())
        try:
            # Find the touch record
            touch = db.execute(text("""
                SELECT t.id, t.business_id, t.contact_id, t.campaign_id,
                       b.name as business_name, c.full_name as owner_name
                FROM touches t
                JOIN contacts c ON t.contact_id = c.id
                JOIN businesses b ON t.business_id = b.id
                WHERE c.email = :email
                ORDER BY t.sent_at DESC LIMIT 1
            """), {'email': from_email}).mappings().first()

            if touch:
                # Update touch with reply
                db.execute(text("""
                    UPDATE touches SET
                        replied_at = NOW(),
                        response_text = :reply,
                        status = 'replied'
                    WHERE id = :id
                """), {'reply': reply_text, 'id': touch['id']})

                # Classify the response
                try:
                    from ...outreach.response_classifier import ResponseClassifier
                    classifier = ResponseClassifier()
                    classification = classifier.classify(
                        response_text=reply_text,
                        business_name=touch.get('business_name'),
                        owner_name=touch.get('owner_name'),
                    )

                    db.execute(text("""
                        UPDATE touches SET response_sentiment = :sentiment
                        WHERE id = :id
                    """), {
                        'sentiment': classification.sentiment.value,
                        'id': touch['id'],
                    })

                    # Update campaign stats
                    db.execute(text("""
                        UPDATE campaigns SET
                            total_replied = total_replied + 1,
                            total_interested = total_interested +
                                CASE WHEN :sentiment = 'interested' THEN 1 ELSE 0 END
                        WHERE id = :campaign_id
                    """), {
                        'sentiment': classification.sentiment.value,
                        'campaign_id': touch['campaign_id'],
                    })

                    # Notify on hot responses
                    if classification.sentiment.value == 'interested':
                        from ...utils.notifications import get_notifier
                        notifier = get_notifier()
                        if notifier:
                            notifier.notify_response(
                                business_name=touch.get('business_name', ''),
                                sentiment=classification.sentiment.value,
                                summary=classification.summary,
                            )

                except Exception as e:
                    log_error(logger, e, {'from_email': from_email})

                db.commit()

            return {"status": "ok", "classified": touch is not None}

        finally:
            db.close()

    except Exception as e:
        log_error(logger, e, {'source': 'email_reply_webhook'})
        return {"status": "error", "message": str(e)}


def _process_email_event(db, event_type: str, email: str, payload: dict):
    """Process a standard email event (sent/opened/clicked/bounced)."""
    field_map = {
        'sent': 'sent_at',
        'delivered': 'delivered_at',
        'opened': 'opened_at',
        'clicked': 'clicked_at',
        'bounced': None,
    }

    timestamp_field = field_map.get(event_type)

    if event_type == 'bounced':
        db.execute(text("""
            UPDATE touches SET status = 'bounced',
                error_message = :error
            WHERE contact_id IN (
                SELECT id FROM contacts WHERE email = :email
            ) AND status IN ('scheduled', 'sent')
        """), {
            'email': email,
            'error': payload.get('bounce_reason', 'bounced'),
        })
    elif timestamp_field:
        status = event_type if event_type != 'opened' else 'opened'
        db.execute(text(f"""
            UPDATE touches SET {timestamp_field} = NOW(),
                status = CASE WHEN status IN ('scheduled', 'sent', 'delivered')
                         THEN :status ELSE status END
            WHERE contact_id IN (
                SELECT id FROM contacts WHERE email = :email
            )
        """), {'email': email, 'status': status})

        # Update campaign counters
        if event_type in ('delivered', 'opened'):
            counter = f"total_{event_type}"
            db.execute(text(f"""
                UPDATE campaigns SET {counter} = {counter} + 1
                WHERE id IN (
                    SELECT campaign_id FROM touches
                    WHERE contact_id IN (SELECT id FROM contacts WHERE email = :email)
                )
            """), {'email': email})
