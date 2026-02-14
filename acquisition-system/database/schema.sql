-- Business Acquisition System Database Schema
-- PostgreSQL / Supabase

-- =============================================================================
-- Core Business Data
-- =============================================================================

CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Basic info
    name VARCHAR(500) NOT NULL,
    dba_name VARCHAR(500),  -- "Doing Business As"
    entity_type VARCHAR(100),  -- LLC, Corporation, Partnership, etc.
    entity_number VARCHAR(100),  -- State registration number

    -- Dates
    incorporation_date DATE,
    first_scraped_at TIMESTAMP DEFAULT NOW(),
    last_updated_at TIMESTAMP DEFAULT NOW(),

    -- Location
    street_address VARCHAR(500),
    city VARCHAR(200),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    county VARCHAR(100),

    -- Business details
    industry VARCHAR(200),
    naics_code VARCHAR(10),
    sic_code VARCHAR(10),

    -- Estimated metrics
    estimated_revenue DECIMAL(15, 2),
    estimated_revenue_confidence DECIMAL(3, 2),  -- 0.00 to 1.00
    estimated_employees INTEGER,

    -- Online presence
    website_url VARCHAR(1000),
    website_last_updated DATE,
    website_ssl_valid BOOLEAN,
    linkedin_url VARCHAR(500),
    linkedin_followers INTEGER,
    google_rating DECIMAL(2, 1),
    google_review_count INTEGER,

    -- Status
    status VARCHAR(50) DEFAULT 'active',  -- active, dissolved, suspended
    data_quality_score DECIMAL(3, 2),  -- 0.00 to 1.00

    -- Metadata
    data_sources JSONB,  -- {"sos": "CA", "bizbuysell": true, "linkedin": true}
    raw_data JSONB,  -- Store full scraper output

    CONSTRAINT businesses_state_check CHECK (state IN (
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'
    ))
);

CREATE INDEX idx_businesses_state ON businesses(state);
CREATE INDEX idx_businesses_incorporation_date ON businesses(incorporation_date);
CREATE INDEX idx_businesses_industry ON businesses(industry);
CREATE INDEX idx_businesses_status ON businesses(status);
CREATE INDEX idx_businesses_website_url ON businesses(website_url);

-- =============================================================================
-- Contacts (Owners, Officers, Agents)
-- =============================================================================

CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,

    -- Personal info
    first_name VARCHAR(200),
    last_name VARCHAR(200),
    full_name VARCHAR(500) NOT NULL,
    title VARCHAR(200),  -- CEO, President, Registered Agent, etc.

    -- Contact info
    email VARCHAR(500),
    email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    phone VARCHAR(50),
    phone_verified BOOLEAN DEFAULT false,
    linkedin_url VARCHAR(500),

    -- Age estimation (key signal!)
    estimated_age INTEGER,
    estimated_birth_year INTEGER,
    age_confidence DECIMAL(3, 2),

    -- Role details
    role_type VARCHAR(100),  -- owner, officer, agent, director
    ownership_percentage DECIMAL(5, 2),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,

    -- Metadata
    data_sources JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_contacts_business_id ON contacts(business_id);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_estimated_age ON contacts(estimated_age);
CREATE INDEX idx_contacts_is_active ON contacts(is_active);

-- =============================================================================
-- Lead Scoring
-- =============================================================================

CREATE TABLE lead_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,

    -- Overall score
    composite_score DECIMAL(5, 4) NOT NULL,  -- 0.0000 to 1.0000
    score_tier VARCHAR(20),  -- hot, warm, cold

    -- Individual signals (0.00 to 1.00 each)
    signal_marketplace_listing DECIMAL(3, 2) DEFAULT 0,
    signal_owner_age DECIMAL(3, 2) DEFAULT 0,
    signal_business_tenure DECIMAL(3, 2) DEFAULT 0,
    signal_pe_hold_period DECIMAL(3, 2) DEFAULT 0,
    signal_digital_decay DECIMAL(3, 2) DEFAULT 0,
    signal_headcount_decline DECIMAL(3, 2) DEFAULT 0,
    signal_no_succession DECIMAL(3, 2) DEFAULT 0,

    -- Feature values (for debugging/analysis)
    features JSONB,  -- All input features

    -- Model info
    model_version VARCHAR(50),
    model_confidence DECIMAL(3, 2),

    -- Timestamps
    scored_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,  -- Re-score after this date

    CONSTRAINT lead_scores_tier_check CHECK (score_tier IN ('hot', 'warm', 'cold'))
);

CREATE INDEX idx_lead_scores_business_id ON lead_scores(business_id);
CREATE INDEX idx_lead_scores_composite_score ON lead_scores(composite_score DESC);
CREATE INDEX idx_lead_scores_score_tier ON lead_scores(score_tier);
CREATE INDEX idx_lead_scores_scored_at ON lead_scores(scored_at DESC);

-- =============================================================================
-- Outreach Campaigns
-- =============================================================================

CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(500) NOT NULL,
    description TEXT,
    campaign_type VARCHAR(100),  -- cold_email, warm_email, nurture, follow_up

    -- Targeting
    target_score_min DECIMAL(5, 4),
    target_score_max DECIMAL(5, 4),
    target_industries TEXT[],
    target_states VARCHAR(2)[],

    -- Messaging
    message_template TEXT,  -- Can include {{variables}}
    subject_template TEXT,
    use_ai_personalization BOOLEAN DEFAULT true,

    -- Settings
    daily_send_limit INTEGER DEFAULT 50,
    send_window_start TIME DEFAULT '09:00',
    send_window_end TIME DEFAULT '17:00',
    send_days INTEGER[] DEFAULT ARRAY[1,2,3,4,5],  -- Mon-Fri

    -- Status
    status VARCHAR(50) DEFAULT 'draft',  -- draft, active, paused, completed

    -- Stats
    total_sent INTEGER DEFAULT 0,
    total_delivered INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    total_replied INTEGER DEFAULT 0,
    total_interested INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    CONSTRAINT campaigns_status_check CHECK (status IN ('draft', 'active', 'paused', 'completed'))
);

-- =============================================================================
-- Individual Outreach Touches
-- =============================================================================

CREATE TABLE touches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,

    -- Touch details
    touch_number INTEGER,  -- 1st touch, 2nd touch, etc.
    channel VARCHAR(50),  -- email, phone, linkedin

    -- Message
    subject TEXT,
    message_body TEXT,
    personalized_intro TEXT,  -- AI-generated opening

    -- Sending
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,

    -- Response tracking
    delivered_at TIMESTAMP,
    opened_at TIMESTAMP,
    clicked_at TIMESTAMP,
    replied_at TIMESTAMP,

    response_sentiment VARCHAR(50),  -- interested, not_interested, neutral
    response_text TEXT,

    -- Status
    status VARCHAR(50) DEFAULT 'scheduled',  -- scheduled, sent, delivered, opened, replied, bounced, failed
    error_message TEXT,

    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT touches_channel_check CHECK (channel IN ('email', 'phone', 'linkedin', 'other')),
    CONSTRAINT touches_status_check CHECK (status IN (
        'scheduled', 'sent', 'delivered', 'opened', 'replied', 'bounced', 'failed', 'unsubscribed'
    ))
);

CREATE INDEX idx_touches_campaign_id ON touches(campaign_id);
CREATE INDEX idx_touches_business_id ON touches(business_id);
CREATE INDEX idx_touches_status ON touches(status);
CREATE INDEX idx_touches_scheduled_at ON touches(scheduled_at);
CREATE INDEX idx_touches_sent_at ON touches(sent_at DESC);

-- =============================================================================
-- Deal Pipeline
-- =============================================================================

CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID REFERENCES businesses(id) ON DELETE SET NULL,

    -- Deal basics
    name VARCHAR(500) NOT NULL,
    description TEXT,

    -- Pipeline stage
    stage VARCHAR(100) DEFAULT 'lead',  -- lead, contacted, qualified, loi_sent, due_diligence, closing, closed_won, closed_lost
    stage_changed_at TIMESTAMP DEFAULT NOW(),

    -- Valuation
    asking_price DECIMAL(15, 2),
    estimated_sde DECIMAL(15, 2),
    estimated_revenue DECIMAL(15, 2),
    valuation_multiple DECIMAL(5, 2),

    -- Deal structure
    proposed_structure TEXT,  -- Notes on financing structure
    seller_financing_pct DECIMAL(5, 2),
    earnout_pct DECIMAL(5, 2),

    -- Probability & value
    win_probability DECIMAL(3, 2),  -- 0.00 to 1.00
    expected_value DECIMAL(15, 2),  -- asking_price * win_probability

    -- Dates
    first_contact_date DATE,
    loi_sent_date DATE,
    loi_accepted_date DATE,
    due_diligence_start_date DATE,
    expected_close_date DATE,
    actual_close_date DATE,

    -- Source tracking
    source VARCHAR(200),  -- How we found this deal
    source_campaign_id UUID REFERENCES campaigns(id),

    -- Owner/assignment
    assigned_to VARCHAR(200),

    -- Status
    is_active BOOLEAN DEFAULT true,
    lost_reason TEXT,

    -- Metadata
    notes TEXT,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT deals_stage_check CHECK (stage IN (
        'lead', 'contacted', 'qualified', 'loi_sent', 'due_diligence',
        'closing', 'closed_won', 'closed_lost'
    ))
);

CREATE INDEX idx_deals_business_id ON deals(business_id);
CREATE INDEX idx_deals_stage ON deals(stage);
CREATE INDEX idx_deals_expected_close_date ON deals(expected_close_date);
CREATE INDEX idx_deals_is_active ON deals(is_active);

-- =============================================================================
-- Activity Log
-- =============================================================================

CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    entity_type VARCHAR(50),  -- business, contact, deal, campaign
    entity_id UUID NOT NULL,

    activity_type VARCHAR(100),  -- email_sent, phone_call, meeting, note, status_change
    description TEXT NOT NULL,

    performed_by VARCHAR(200),  -- user or 'system'

    metadata JSONB,  -- Additional structured data

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activities_entity ON activities(entity_type, entity_id);
CREATE INDEX idx_activities_created_at ON activities(created_at DESC);

-- =============================================================================
-- System Jobs & Monitoring
-- =============================================================================

CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    job_type VARCHAR(100) NOT NULL,  -- sos_sync, enrichment, scoring, outreach
    job_status VARCHAR(50) DEFAULT 'pending',  -- pending, running, completed, failed

    -- Execution details
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    duration_seconds INTEGER,

    -- Results
    records_processed INTEGER DEFAULT 0,
    records_success INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,

    error_message TEXT,

    metadata JSONB,

    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT jobs_status_check CHECK (job_status IN ('pending', 'running', 'completed', 'failed'))
);

CREATE INDEX idx_jobs_job_type ON jobs(job_type);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);

-- =============================================================================
-- Views for Quick Analytics
-- =============================================================================

-- Hot leads ready for outreach
CREATE VIEW hot_leads AS
SELECT
    b.id,
    b.name,
    b.state,
    b.industry,
    b.website_url,
    ls.composite_score,
    c.full_name as owner_name,
    c.email,
    c.estimated_age
FROM businesses b
JOIN lead_scores ls ON b.id = ls.business_id
LEFT JOIN contacts c ON b.id = c.business_id AND c.role_type = 'owner' AND c.is_active = true
WHERE ls.score_tier = 'hot'
    AND b.status = 'active'
    AND ls.scored_at > NOW() - INTERVAL '30 days'
ORDER BY ls.composite_score DESC;

-- Campaign performance summary
CREATE VIEW campaign_stats AS
SELECT
    c.id,
    c.name,
    c.status,
    c.total_sent,
    CASE WHEN c.total_sent > 0 THEN (c.total_delivered::FLOAT / c.total_sent) * 100 ELSE 0 END as delivery_rate,
    CASE WHEN c.total_delivered > 0 THEN (c.total_opened::FLOAT / c.total_delivered) * 100 ELSE 0 END as open_rate,
    CASE WHEN c.total_sent > 0 THEN (c.total_replied::FLOAT / c.total_sent) * 100 ELSE 0 END as reply_rate,
    CASE WHEN c.total_replied > 0 THEN (c.total_interested::FLOAT / c.total_replied) * 100 ELSE 0 END as interest_rate
FROM campaigns c;

-- Pipeline overview
CREATE VIEW pipeline_overview AS
SELECT
    stage,
    COUNT(*) as deal_count,
    SUM(asking_price) as total_value,
    SUM(expected_value) as weighted_value,
    AVG(win_probability) as avg_win_probability
FROM deals
WHERE is_active = true
GROUP BY stage
ORDER BY
    CASE stage
        WHEN 'lead' THEN 1
        WHEN 'contacted' THEN 2
        WHEN 'qualified' THEN 3
        WHEN 'loi_sent' THEN 4
        WHEN 'due_diligence' THEN 5
        WHEN 'closing' THEN 6
    END;

-- =============================================================================
-- Functions
-- =============================================================================

-- Auto-update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER businesses_updated_at BEFORE UPDATE ON businesses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER contacts_updated_at BEFORE UPDATE ON contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER deals_updated_at BEFORE UPDATE ON deals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-set score tier based on composite score
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

CREATE TRIGGER lead_scores_tier BEFORE INSERT OR UPDATE ON lead_scores
    FOR EACH ROW EXECUTE FUNCTION set_score_tier();
