"""
SQLAlchemy ORM models matching database schema.
Provides type-safe database operations.
"""

import uuid
from datetime import datetime, date
from typing import Optional, List

from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Date, DateTime, Text,
    ForeignKey, Index, CheckConstraint, Numeric, ARRAY, Enum, func
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import DeclarativeBase, relationship, Mapped, mapped_column


class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass


class Business(Base):
    __tablename__ = 'businesses'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Basic info
    name: Mapped[str] = mapped_column(String(500), nullable=False)
    dba_name: Mapped[Optional[str]] = mapped_column(String(500))
    entity_type: Mapped[Optional[str]] = mapped_column(String(100))
    entity_number: Mapped[Optional[str]] = mapped_column(String(100))

    # Dates
    incorporation_date: Mapped[Optional[date]] = mapped_column(Date)
    first_scraped_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())
    last_updated_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), onupdate=func.now())

    # Location
    street_address: Mapped[Optional[str]] = mapped_column(String(500))
    city: Mapped[Optional[str]] = mapped_column(String(200))
    state: Mapped[Optional[str]] = mapped_column(String(2))
    zip_code: Mapped[Optional[str]] = mapped_column(String(10))
    county: Mapped[Optional[str]] = mapped_column(String(100))

    # Business details
    industry: Mapped[Optional[str]] = mapped_column(String(200))
    naics_code: Mapped[Optional[str]] = mapped_column(String(10))
    sic_code: Mapped[Optional[str]] = mapped_column(String(10))

    # Estimated metrics
    estimated_revenue: Mapped[Optional[float]] = mapped_column(Numeric(15, 2))
    estimated_revenue_confidence: Mapped[Optional[float]] = mapped_column(Numeric(3, 2))
    estimated_employees: Mapped[Optional[int]] = mapped_column(Integer)

    # Online presence
    website_url: Mapped[Optional[str]] = mapped_column(String(1000))
    website_last_updated: Mapped[Optional[date]] = mapped_column(Date)
    website_ssl_valid: Mapped[Optional[bool]] = mapped_column(Boolean)
    linkedin_url: Mapped[Optional[str]] = mapped_column(String(500))
    linkedin_followers: Mapped[Optional[int]] = mapped_column(Integer)
    google_rating: Mapped[Optional[float]] = mapped_column(Numeric(2, 1))
    google_review_count: Mapped[Optional[int]] = mapped_column(Integer)

    # Status
    status: Mapped[str] = mapped_column(String(50), default='active')
    data_quality_score: Mapped[Optional[float]] = mapped_column(Numeric(3, 2))

    # Metadata
    data_sources: Mapped[Optional[dict]] = mapped_column(JSONB)
    raw_data: Mapped[Optional[dict]] = mapped_column(JSONB)

    # Relationships
    contacts: Mapped[List["Contact"]] = relationship(back_populates="business", cascade="all, delete-orphan")
    lead_scores: Mapped[List["LeadScore"]] = relationship(back_populates="business", cascade="all, delete-orphan")
    touches: Mapped[List["Touch"]] = relationship(back_populates="business")
    deals: Mapped[List["Deal"]] = relationship(back_populates="business")

    def __repr__(self):
        return f"<Business(name='{self.name}', state='{self.state}', status='{self.status}')>"

    @property
    def years_in_business(self) -> Optional[float]:
        if self.incorporation_date:
            return (date.today() - self.incorporation_date).days / 365.25
        return None

    @property
    def active_owner(self) -> Optional["Contact"]:
        for contact in self.contacts:
            if contact.role_type == 'owner' and contact.is_active:
                return contact
        return None


class Contact(Base):
    __tablename__ = 'contacts'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey('businesses.id', ondelete='CASCADE'))

    # Personal info
    first_name: Mapped[Optional[str]] = mapped_column(String(200))
    last_name: Mapped[Optional[str]] = mapped_column(String(200))
    full_name: Mapped[str] = mapped_column(String(500), nullable=False)
    title: Mapped[Optional[str]] = mapped_column(String(200))

    # Contact info
    email: Mapped[Optional[str]] = mapped_column(String(500))
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    email_verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    phone: Mapped[Optional[str]] = mapped_column(String(50))
    phone_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    linkedin_url: Mapped[Optional[str]] = mapped_column(String(500))

    # Age estimation
    estimated_age: Mapped[Optional[int]] = mapped_column(Integer)
    estimated_birth_year: Mapped[Optional[int]] = mapped_column(Integer)
    age_confidence: Mapped[Optional[float]] = mapped_column(Numeric(3, 2))

    # Role details
    role_type: Mapped[Optional[str]] = mapped_column(String(100))
    ownership_percentage: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    start_date: Mapped[Optional[date]] = mapped_column(Date)
    end_date: Mapped[Optional[date]] = mapped_column(Date)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Metadata
    data_sources: Mapped[Optional[dict]] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    business: Mapped["Business"] = relationship(back_populates="contacts")
    touches: Mapped[List["Touch"]] = relationship(back_populates="contact")

    def __repr__(self):
        return f"<Contact(name='{self.full_name}', role='{self.role_type}', email='{self.email}')>"


class LeadScore(Base):
    __tablename__ = 'lead_scores'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey('businesses.id', ondelete='CASCADE'))

    # Overall score
    composite_score: Mapped[float] = mapped_column(Numeric(5, 4), nullable=False)
    score_tier: Mapped[Optional[str]] = mapped_column(String(20))

    # Individual signals
    signal_marketplace_listing: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    signal_owner_age: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    signal_business_tenure: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    signal_pe_hold_period: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    signal_digital_decay: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    signal_headcount_decline: Mapped[float] = mapped_column(Numeric(3, 2), default=0)
    signal_no_succession: Mapped[float] = mapped_column(Numeric(3, 2), default=0)

    # Feature values
    features: Mapped[Optional[dict]] = mapped_column(JSONB)

    # Model info
    model_version: Mapped[Optional[str]] = mapped_column(String(50))
    model_confidence: Mapped[Optional[float]] = mapped_column(Numeric(3, 2))

    # Timestamps
    scored_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    # Relationships
    business: Mapped["Business"] = relationship(back_populates="lead_scores")

    def __repr__(self):
        return f"<LeadScore(score={self.composite_score}, tier='{self.score_tier}')>"


class Campaign(Base):
    __tablename__ = 'campaigns'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    name: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    campaign_type: Mapped[Optional[str]] = mapped_column(String(100))

    # Targeting
    target_score_min: Mapped[Optional[float]] = mapped_column(Numeric(5, 4))
    target_score_max: Mapped[Optional[float]] = mapped_column(Numeric(5, 4))
    target_industries: Mapped[Optional[list]] = mapped_column(ARRAY(Text))
    target_states: Mapped[Optional[list]] = mapped_column(ARRAY(String(2)))

    # Messaging
    message_template: Mapped[Optional[str]] = mapped_column(Text)
    subject_template: Mapped[Optional[str]] = mapped_column(Text)
    use_ai_personalization: Mapped[bool] = mapped_column(Boolean, default=True)

    # Settings
    daily_send_limit: Mapped[int] = mapped_column(Integer, default=50)
    send_window_start: Mapped[Optional[str]] = mapped_column(String(5))
    send_window_end: Mapped[Optional[str]] = mapped_column(String(5))

    # Status
    status: Mapped[str] = mapped_column(String(50), default='draft')

    # Stats
    total_sent: Mapped[int] = mapped_column(Integer, default=0)
    total_delivered: Mapped[int] = mapped_column(Integer, default=0)
    total_opened: Mapped[int] = mapped_column(Integer, default=0)
    total_replied: Mapped[int] = mapped_column(Integer, default=0)
    total_interested: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    # Relationships
    touches: Mapped[List["Touch"]] = relationship(back_populates="campaign")

    def __repr__(self):
        return f"<Campaign(name='{self.name}', status='{self.status}', sent={self.total_sent})>"

    @property
    def open_rate(self) -> float:
        return (self.total_opened / self.total_delivered * 100) if self.total_delivered > 0 else 0

    @property
    def reply_rate(self) -> float:
        return (self.total_replied / self.total_sent * 100) if self.total_sent > 0 else 0


class Touch(Base):
    __tablename__ = 'touches'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    campaign_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey('campaigns.id', ondelete='CASCADE'))
    business_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey('businesses.id', ondelete='CASCADE'))
    contact_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey('contacts.id', ondelete='CASCADE'))

    # Touch details
    touch_number: Mapped[Optional[int]] = mapped_column(Integer)
    channel: Mapped[Optional[str]] = mapped_column(String(50))

    # Message
    subject: Mapped[Optional[str]] = mapped_column(Text)
    message_body: Mapped[Optional[str]] = mapped_column(Text)
    personalized_intro: Mapped[Optional[str]] = mapped_column(Text)

    # Sending
    scheduled_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    sent_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    # Response tracking
    delivered_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    opened_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    clicked_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    replied_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    response_sentiment: Mapped[Optional[str]] = mapped_column(String(50))
    response_text: Mapped[Optional[str]] = mapped_column(Text)

    # Status
    status: Mapped[str] = mapped_column(String(50), default='scheduled')
    error_message: Mapped[Optional[str]] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())

    # Relationships
    campaign: Mapped["Campaign"] = relationship(back_populates="touches")
    business: Mapped["Business"] = relationship(back_populates="touches")
    contact: Mapped["Contact"] = relationship(back_populates="touches")

    def __repr__(self):
        return f"<Touch(business='{self.business_id}', status='{self.status}', channel='{self.channel}')>"


class Deal(Base):
    __tablename__ = 'deals'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    business_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), ForeignKey('businesses.id', ondelete='SET NULL'))

    # Deal basics
    name: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)

    # Pipeline stage
    stage: Mapped[str] = mapped_column(String(100), default='lead')
    stage_changed_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())

    # Valuation
    asking_price: Mapped[Optional[float]] = mapped_column(Numeric(15, 2))
    estimated_sde: Mapped[Optional[float]] = mapped_column(Numeric(15, 2))
    estimated_revenue: Mapped[Optional[float]] = mapped_column(Numeric(15, 2))
    valuation_multiple: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))

    # Deal structure
    proposed_structure: Mapped[Optional[str]] = mapped_column(Text)
    seller_financing_pct: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    earnout_pct: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))

    # Probability
    win_probability: Mapped[Optional[float]] = mapped_column(Numeric(3, 2))
    expected_value: Mapped[Optional[float]] = mapped_column(Numeric(15, 2))

    # Dates
    first_contact_date: Mapped[Optional[date]] = mapped_column(Date)
    loi_sent_date: Mapped[Optional[date]] = mapped_column(Date)
    loi_accepted_date: Mapped[Optional[date]] = mapped_column(Date)
    due_diligence_start_date: Mapped[Optional[date]] = mapped_column(Date)
    expected_close_date: Mapped[Optional[date]] = mapped_column(Date)
    actual_close_date: Mapped[Optional[date]] = mapped_column(Date)

    # Source tracking
    source: Mapped[Optional[str]] = mapped_column(String(200))
    source_campaign_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), ForeignKey('campaigns.id'))

    # Owner/assignment
    assigned_to: Mapped[Optional[str]] = mapped_column(String(200))

    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    lost_reason: Mapped[Optional[str]] = mapped_column(Text)
    notes: Mapped[Optional[str]] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    business: Mapped[Optional["Business"]] = relationship(back_populates="deals")

    def __repr__(self):
        return f"<Deal(name='{self.name}', stage='{self.stage}', value={self.asking_price})>"


class Activity(Base):
    __tablename__ = 'activities'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    entity_type: Mapped[Optional[str]] = mapped_column(String(50))
    entity_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)

    activity_type: Mapped[Optional[str]] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text, nullable=False)

    performed_by: Mapped[Optional[str]] = mapped_column(String(200))

    extra_data: Mapped[Optional[dict]] = mapped_column("metadata", JSONB)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())

    def __repr__(self):
        return f"<Activity(type='{self.activity_type}', entity='{self.entity_type}:{self.entity_id}')>"


class Job(Base):
    __tablename__ = 'jobs'

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    job_type: Mapped[str] = mapped_column(String(100), nullable=False)
    job_status: Mapped[str] = mapped_column(String(50), default='pending')

    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    duration_seconds: Mapped[Optional[int]] = mapped_column(Integer)

    records_processed: Mapped[int] = mapped_column(Integer, default=0)
    records_success: Mapped[int] = mapped_column(Integer, default=0)
    records_failed: Mapped[int] = mapped_column(Integer, default=0)

    error_message: Mapped[Optional[str]] = mapped_column(Text)
    extra_data: Mapped[Optional[dict]] = mapped_column("metadata", JSONB)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=func.now())

    def __repr__(self):
        return f"<Job(type='{self.job_type}', status='{self.job_status}')>"
