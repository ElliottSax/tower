"""Test data factory functions for creating database records."""

import uuid
from datetime import datetime, timedelta
from sqlalchemy import text


def create_business(db, **overrides):
    """Insert a business record and return its data."""
    defaults = {
        "id": str(uuid.uuid4()),
        "name": "Test HVAC Company",
        "industry": "HVAC",
        "city": "Austin",
        "state": "TX",
        "status": "active",
        "estimated_revenue": 2500000,
        "estimated_employees": 15,
        "website_url": "https://testhvac.com",
    }
    defaults.update(overrides)
    db.execute(text("""
        INSERT INTO businesses (id, name, industry, city, state, status,
                               estimated_revenue, estimated_employees, website_url)
        VALUES (:id, :name, :industry, :city, :state, :status,
                :estimated_revenue, :estimated_employees, :website_url)
    """), defaults)
    db.flush()
    return defaults


def create_contact(db, business_id, **overrides):
    """Insert a contact record and return its data."""
    defaults = {
        "id": str(uuid.uuid4()),
        "business_id": business_id,
        "first_name": "John",
        "last_name": "Smith",
        "full_name": "John Smith",
        "email": "john@testhvac.com",
        "role_type": "owner",
        "is_active": True,
        "estimated_age": 65,
    }
    defaults.update(overrides)
    db.execute(text("""
        INSERT INTO contacts (id, business_id, first_name, last_name, full_name,
                             email, role_type, is_active, estimated_age)
        VALUES (:id, :business_id, :first_name, :last_name, :full_name,
                :email, :role_type, :is_active, :estimated_age)
    """), defaults)
    db.flush()
    return defaults


def create_lead_score(db, business_id, **overrides):
    """Insert a lead score record and return its data."""
    defaults = {
        "id": str(uuid.uuid4()),
        "business_id": business_id,
        "composite_score": 0.75,
        "score_tier": "hot",
        "signal_marketplace_listing": 0.0,
        "signal_owner_age": 0.8,
        "signal_digital_decay": 0.6,
        "signal_headcount_decline": 0.3,
    }
    defaults.update(overrides)
    db.execute(text("""
        INSERT INTO lead_scores (id, business_id, composite_score, score_tier,
                                signal_marketplace_listing, signal_owner_age,
                                signal_digital_decay, signal_headcount_decline)
        VALUES (:id, :business_id, :composite_score, :score_tier,
                :signal_marketplace_listing, :signal_owner_age,
                :signal_digital_decay, :signal_headcount_decline)
    """), defaults)
    db.flush()
    return defaults


def create_campaign(db, **overrides):
    """Insert a campaign record and return its data."""
    defaults = {
        "id": str(uuid.uuid4()),
        "name": "Q1 Cold Outreach",
        "campaign_type": "cold_email",
        "status": "active",
        "target_score_min": 0.70,
        "target_score_max": 1.0,
        "daily_send_limit": 50,
        "use_ai_personalization": True,
        "total_sent": 100,
        "total_delivered": 95,
        "total_opened": 40,
        "total_replied": 8,
        "total_interested": 3,
    }
    defaults.update(overrides)
    db.execute(text("""
        INSERT INTO campaigns (id, name, campaign_type, status,
                              target_score_min, target_score_max,
                              daily_send_limit, use_ai_personalization,
                              total_sent, total_delivered, total_opened,
                              total_replied, total_interested)
        VALUES (:id, :name, :campaign_type, :status,
                :target_score_min, :target_score_max,
                :daily_send_limit, :use_ai_personalization,
                :total_sent, :total_delivered, :total_opened,
                :total_replied, :total_interested)
    """), defaults)
    db.flush()
    return defaults


def create_deal(db, business_id=None, **overrides):
    """Insert a deal record and return its data."""
    defaults = {
        "id": str(uuid.uuid4()),
        "business_id": business_id,
        "name": "Test HVAC Acquisition",
        "stage": "lead",
        "asking_price": 1500000,
        "estimated_sde": 350000,
        "estimated_revenue": 2500000,
        "is_active": True,
        "win_probability": 0.2,
        "source": "cold_email",
    }
    defaults.update(overrides)
    db.execute(text("""
        INSERT INTO deals (id, business_id, name, stage, asking_price,
                          estimated_sde, estimated_revenue, is_active,
                          win_probability, source)
        VALUES (:id, :business_id, :name, :stage, :asking_price,
                :estimated_sde, :estimated_revenue, :is_active,
                :win_probability, :source)
    """), defaults)
    db.flush()
    return defaults


def create_touch(db, campaign_id, business_id, contact_id, **overrides):
    """Insert a touch record and return its data."""
    defaults = {
        "id": str(uuid.uuid4()),
        "campaign_id": campaign_id,
        "business_id": business_id,
        "contact_id": contact_id,
        "touch_number": 1,
        "channel": "email",
        "subject": "Quick question about your business",
        "status": "sent",
        "sent_at": datetime.utcnow(),
    }
    defaults.update(overrides)
    db.execute(text("""
        INSERT INTO touches (id, campaign_id, business_id, contact_id,
                            touch_number, channel, subject, status, sent_at)
        VALUES (:id, :campaign_id, :business_id, :contact_id,
                :touch_number, :channel, :subject, :status, :sent_at)
    """), defaults)
    db.flush()
    return defaults
