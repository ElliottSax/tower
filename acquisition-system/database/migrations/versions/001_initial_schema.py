"""Initial schema - all core tables.

Revision ID: 001
Revises: None
Create Date: 2026-02-05
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB

revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

US_STATES = (
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
)


def upgrade() -> None:
    # === businesses ===
    op.create_table(
        'businesses',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('name', sa.String(500), nullable=False),
        sa.Column('dba_name', sa.String(500)),
        sa.Column('entity_type', sa.String(100)),
        sa.Column('entity_number', sa.String(100)),
        sa.Column('incorporation_date', sa.Date),
        sa.Column('first_scraped_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('last_updated_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('street_address', sa.String(500)),
        sa.Column('city', sa.String(200)),
        sa.Column('state', sa.String(2)),
        sa.Column('zip_code', sa.String(10)),
        sa.Column('county', sa.String(100)),
        sa.Column('industry', sa.String(200)),
        sa.Column('naics_code', sa.String(10)),
        sa.Column('sic_code', sa.String(10)),
        sa.Column('estimated_revenue', sa.Numeric(15, 2)),
        sa.Column('estimated_revenue_confidence', sa.Numeric(3, 2)),
        sa.Column('estimated_employees', sa.Integer),
        sa.Column('website_url', sa.String(1000)),
        sa.Column('website_last_updated', sa.Date),
        sa.Column('website_ssl_valid', sa.Boolean),
        sa.Column('linkedin_url', sa.String(500)),
        sa.Column('linkedin_followers', sa.Integer),
        sa.Column('google_rating', sa.Numeric(2, 1)),
        sa.Column('google_review_count', sa.Integer),
        sa.Column('status', sa.String(50), server_default='active'),
        sa.Column('data_quality_score', sa.Numeric(3, 2)),
        sa.Column('data_sources', JSONB),
        sa.Column('raw_data', JSONB),
        sa.CheckConstraint(f"state IN {US_STATES}", name='businesses_state_check'),
    )
    op.create_index('idx_businesses_state', 'businesses', ['state'])
    op.create_index('idx_businesses_incorporation_date', 'businesses', ['incorporation_date'])
    op.create_index('idx_businesses_industry', 'businesses', ['industry'])
    op.create_index('idx_businesses_status', 'businesses', ['status'])
    op.create_index('idx_businesses_website_url', 'businesses', ['website_url'])

    # === contacts ===
    op.create_table(
        'contacts',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('business_id', UUID(as_uuid=True), sa.ForeignKey('businesses.id', ondelete='CASCADE')),
        sa.Column('first_name', sa.String(200)),
        sa.Column('last_name', sa.String(200)),
        sa.Column('full_name', sa.String(500), nullable=False),
        sa.Column('title', sa.String(200)),
        sa.Column('email', sa.String(500)),
        sa.Column('email_verified', sa.Boolean, server_default='false'),
        sa.Column('email_verified_at', sa.DateTime),
        sa.Column('phone', sa.String(50)),
        sa.Column('phone_verified', sa.Boolean, server_default='false'),
        sa.Column('linkedin_url', sa.String(500)),
        sa.Column('estimated_age', sa.Integer),
        sa.Column('estimated_birth_year', sa.Integer),
        sa.Column('age_confidence', sa.Numeric(3, 2)),
        sa.Column('role_type', sa.String(100)),
        sa.Column('ownership_percentage', sa.Numeric(5, 2)),
        sa.Column('start_date', sa.Date),
        sa.Column('end_date', sa.Date),
        sa.Column('is_active', sa.Boolean, server_default='true'),
        sa.Column('data_sources', JSONB),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime, server_default=sa.text('NOW()')),
    )
    op.create_index('idx_contacts_business_id', 'contacts', ['business_id'])
    op.create_index('idx_contacts_email', 'contacts', ['email'])
    op.create_index('idx_contacts_estimated_age', 'contacts', ['estimated_age'])
    op.create_index('idx_contacts_is_active', 'contacts', ['is_active'])

    # === lead_scores ===
    op.create_table(
        'lead_scores',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('business_id', UUID(as_uuid=True), sa.ForeignKey('businesses.id', ondelete='CASCADE')),
        sa.Column('composite_score', sa.Numeric(5, 4), nullable=False),
        sa.Column('score_tier', sa.String(20)),
        sa.Column('signal_marketplace_listing', sa.Numeric(3, 2), server_default='0'),
        sa.Column('signal_owner_age', sa.Numeric(3, 2), server_default='0'),
        sa.Column('signal_business_tenure', sa.Numeric(3, 2), server_default='0'),
        sa.Column('signal_pe_hold_period', sa.Numeric(3, 2), server_default='0'),
        sa.Column('signal_digital_decay', sa.Numeric(3, 2), server_default='0'),
        sa.Column('signal_headcount_decline', sa.Numeric(3, 2), server_default='0'),
        sa.Column('signal_no_succession', sa.Numeric(3, 2), server_default='0'),
        sa.Column('features', JSONB),
        sa.Column('model_version', sa.String(50)),
        sa.Column('model_confidence', sa.Numeric(3, 2)),
        sa.Column('scored_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('expires_at', sa.DateTime),
        sa.CheckConstraint("score_tier IN ('hot', 'warm', 'cold')", name='lead_scores_tier_check'),
    )
    op.create_index('idx_lead_scores_business_id', 'lead_scores', ['business_id'])
    op.create_index('idx_lead_scores_composite_score', 'lead_scores', ['composite_score'], postgresql_ops={'composite_score': 'DESC'})
    op.create_index('idx_lead_scores_score_tier', 'lead_scores', ['score_tier'])
    op.create_index('idx_lead_scores_scored_at', 'lead_scores', ['scored_at'], postgresql_ops={'scored_at': 'DESC'})

    # === campaigns ===
    op.create_table(
        'campaigns',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('name', sa.String(500), nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('campaign_type', sa.String(100)),
        sa.Column('target_score_min', sa.Numeric(5, 4)),
        sa.Column('target_score_max', sa.Numeric(5, 4)),
        sa.Column('target_industries', sa.ARRAY(sa.Text)),
        sa.Column('target_states', sa.ARRAY(sa.String(2))),
        sa.Column('message_template', sa.Text),
        sa.Column('subject_template', sa.Text),
        sa.Column('use_ai_personalization', sa.Boolean, server_default='true'),
        sa.Column('daily_send_limit', sa.Integer, server_default='50'),
        sa.Column('send_window_start', sa.String(5), server_default="'09:00'"),
        sa.Column('send_window_end', sa.String(5), server_default="'17:00'"),
        sa.Column('status', sa.String(50), server_default="'draft'"),
        sa.Column('total_sent', sa.Integer, server_default='0'),
        sa.Column('total_delivered', sa.Integer, server_default='0'),
        sa.Column('total_opened', sa.Integer, server_default='0'),
        sa.Column('total_replied', sa.Integer, server_default='0'),
        sa.Column('total_interested', sa.Integer, server_default='0'),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('started_at', sa.DateTime),
        sa.Column('completed_at', sa.DateTime),
        sa.CheckConstraint("status IN ('draft', 'active', 'paused', 'completed')", name='campaigns_status_check'),
    )

    # === touches ===
    op.create_table(
        'touches',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('campaign_id', UUID(as_uuid=True), sa.ForeignKey('campaigns.id', ondelete='CASCADE')),
        sa.Column('business_id', UUID(as_uuid=True), sa.ForeignKey('businesses.id', ondelete='CASCADE')),
        sa.Column('contact_id', UUID(as_uuid=True), sa.ForeignKey('contacts.id', ondelete='CASCADE')),
        sa.Column('touch_number', sa.Integer),
        sa.Column('channel', sa.String(50)),
        sa.Column('subject', sa.Text),
        sa.Column('message_body', sa.Text),
        sa.Column('personalized_intro', sa.Text),
        sa.Column('scheduled_at', sa.DateTime),
        sa.Column('sent_at', sa.DateTime),
        sa.Column('delivered_at', sa.DateTime),
        sa.Column('opened_at', sa.DateTime),
        sa.Column('clicked_at', sa.DateTime),
        sa.Column('replied_at', sa.DateTime),
        sa.Column('response_sentiment', sa.String(50)),
        sa.Column('response_text', sa.Text),
        sa.Column('status', sa.String(50), server_default="'scheduled'"),
        sa.Column('error_message', sa.Text),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.CheckConstraint("channel IN ('email', 'phone', 'linkedin', 'other')", name='touches_channel_check'),
        sa.CheckConstraint(
            "status IN ('scheduled', 'sent', 'delivered', 'opened', 'replied', 'bounced', 'failed', 'unsubscribed')",
            name='touches_status_check',
        ),
    )
    op.create_index('idx_touches_campaign_id', 'touches', ['campaign_id'])
    op.create_index('idx_touches_business_id', 'touches', ['business_id'])
    op.create_index('idx_touches_status', 'touches', ['status'])
    op.create_index('idx_touches_scheduled_at', 'touches', ['scheduled_at'])
    op.create_index('idx_touches_sent_at', 'touches', ['sent_at'], postgresql_ops={'sent_at': 'DESC'})

    # === deals ===
    op.create_table(
        'deals',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('business_id', UUID(as_uuid=True), sa.ForeignKey('businesses.id', ondelete='SET NULL')),
        sa.Column('name', sa.String(500), nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('stage', sa.String(100), server_default="'lead'"),
        sa.Column('stage_changed_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('asking_price', sa.Numeric(15, 2)),
        sa.Column('estimated_sde', sa.Numeric(15, 2)),
        sa.Column('estimated_revenue', sa.Numeric(15, 2)),
        sa.Column('valuation_multiple', sa.Numeric(5, 2)),
        sa.Column('proposed_structure', sa.Text),
        sa.Column('seller_financing_pct', sa.Numeric(5, 2)),
        sa.Column('earnout_pct', sa.Numeric(5, 2)),
        sa.Column('win_probability', sa.Numeric(3, 2)),
        sa.Column('expected_value', sa.Numeric(15, 2)),
        sa.Column('first_contact_date', sa.Date),
        sa.Column('loi_sent_date', sa.Date),
        sa.Column('loi_accepted_date', sa.Date),
        sa.Column('due_diligence_start_date', sa.Date),
        sa.Column('expected_close_date', sa.Date),
        sa.Column('actual_close_date', sa.Date),
        sa.Column('source', sa.String(200)),
        sa.Column('source_campaign_id', UUID(as_uuid=True), sa.ForeignKey('campaigns.id')),
        sa.Column('assigned_to', sa.String(200)),
        sa.Column('is_active', sa.Boolean, server_default='true'),
        sa.Column('lost_reason', sa.Text),
        sa.Column('notes', sa.Text),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.CheckConstraint(
            "stage IN ('lead', 'contacted', 'qualified', 'loi_sent', 'due_diligence', 'closing', 'closed_won', 'closed_lost')",
            name='deals_stage_check',
        ),
    )
    op.create_index('idx_deals_business_id', 'deals', ['business_id'])
    op.create_index('idx_deals_stage', 'deals', ['stage'])
    op.create_index('idx_deals_expected_close_date', 'deals', ['expected_close_date'])
    op.create_index('idx_deals_is_active', 'deals', ['is_active'])

    # === activities ===
    op.create_table(
        'activities',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('entity_type', sa.String(50)),
        sa.Column('entity_id', UUID(as_uuid=True), nullable=False),
        sa.Column('activity_type', sa.String(100)),
        sa.Column('description', sa.Text, nullable=False),
        sa.Column('performed_by', sa.String(200)),
        sa.Column('metadata', JSONB),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()')),
    )
    op.create_index('idx_activities_entity', 'activities', ['entity_type', 'entity_id'])
    op.create_index('idx_activities_created_at', 'activities', ['created_at'], postgresql_ops={'created_at': 'DESC'})

    # === jobs ===
    op.create_table(
        'jobs',
        sa.Column('id', UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('job_type', sa.String(100), nullable=False),
        sa.Column('job_status', sa.String(50), server_default="'pending'"),
        sa.Column('started_at', sa.DateTime),
        sa.Column('completed_at', sa.DateTime),
        sa.Column('duration_seconds', sa.Integer),
        sa.Column('records_processed', sa.Integer, server_default='0'),
        sa.Column('records_success', sa.Integer, server_default='0'),
        sa.Column('records_failed', sa.Integer, server_default='0'),
        sa.Column('error_message', sa.Text),
        sa.Column('metadata', JSONB),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()')),
        sa.CheckConstraint("job_status IN ('pending', 'running', 'completed', 'failed')", name='jobs_status_check'),
    )
    op.create_index('idx_jobs_job_type', 'jobs', ['job_type'])
    op.create_index('idx_jobs_created_at', 'jobs', ['created_at'], postgresql_ops={'created_at': 'DESC'})

    # === Triggers (raw SQL) ===
    op.execute("""
        CREATE OR REPLACE FUNCTION update_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)

    op.execute("CREATE TRIGGER businesses_updated_at BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION update_updated_at();")
    op.execute("CREATE TRIGGER contacts_updated_at BEFORE UPDATE ON contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at();")
    op.execute("CREATE TRIGGER deals_updated_at BEFORE UPDATE ON deals FOR EACH ROW EXECUTE FUNCTION update_updated_at();")

    op.execute("""
        CREATE OR REPLACE FUNCTION set_score_tier()
        RETURNS TRIGGER AS $$
        BEGIN
            IF NEW.composite_score >= 0.70 THEN
                NEW.score_tier = 'hot';
            ELSIF NEW.composite_score >= 0.45 THEN
                NEW.score_tier = 'warm';
            ELSE
                NEW.score_tier = 'cold';
            END IF;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)

    op.execute("CREATE TRIGGER lead_scores_tier BEFORE INSERT OR UPDATE ON lead_scores FOR EACH ROW EXECUTE FUNCTION set_score_tier();")


def downgrade() -> None:
    op.drop_table('jobs')
    op.drop_table('activities')
    op.drop_table('deals')
    op.drop_table('touches')
    op.drop_table('campaigns')
    op.drop_table('lead_scores')
    op.drop_table('contacts')
    op.drop_table('businesses')
    op.execute("DROP FUNCTION IF EXISTS update_updated_at() CASCADE;")
    op.execute("DROP FUNCTION IF EXISTS set_score_tier() CASCADE;")
