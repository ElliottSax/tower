-- Initialize database with extensions and RLS

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- For encryption

-- Create custom types
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('owner', 'admin', 'member');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE campaign_status AS ENUM ('draft', 'active', 'paused', 'completed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE lead_status AS ENUM ('new', 'researching', 'enriched', 'contacted', 'replied', 'converted', 'disqualified');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE credit_transaction_type AS ENUM ('grant', 'burn', 'expire', 'refund');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug VARCHAR(50) NOT NULL UNIQUE,
  stripe_customer_id TEXT,
  subscription_status TEXT DEFAULT 'trial',
  subscription_ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  role user_role DEFAULT 'member' NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS users_tenant_id_idx ON users(tenant_id);
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);

-- Enable RLS on users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_users ON users
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Credit ledger
CREATE TABLE IF NOT EXISTS credit_ledger (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  type credit_transaction_type NOT NULL,
  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  description TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS credit_ledger_tenant_id_idx ON credit_ledger(tenant_id);
CREATE INDEX IF NOT EXISTS credit_ledger_created_at_idx ON credit_ledger(created_at);

-- Campaigns table
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  status campaign_status DEFAULT 'draft' NOT NULL,

  -- Targeting
  target_company_size VARCHAR(50),
  target_industries JSONB,
  target_job_titles JSONB,
  target_locations JSONB,

  -- AI configuration
  personalization_level VARCHAR(20) DEFAULT 'medium',
  ai_model VARCHAR(50) DEFAULT 'gpt-4o-mini',
  custom_instructions TEXT,

  -- Email templates
  email_subject_template TEXT,
  email_body_template TEXT,
  follow_up_sequence JSONB,

  -- Statistics
  leads_count INTEGER DEFAULT 0,
  emails_sent INTEGER DEFAULT 0,
  emails_opened INTEGER DEFAULT 0,
  emails_replied INTEGER DEFAULT 0,

  -- Email account rotation
  last_account_index INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS campaigns_tenant_id_idx ON campaigns(tenant_id);
CREATE INDEX IF NOT EXISTS campaigns_status_idx ON campaigns(status);
CREATE INDEX IF NOT EXISTS campaigns_user_id_idx ON campaigns(user_id);

ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_campaigns ON campaigns
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Leads table
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,

  -- Contact info
  email VARCHAR(255) NOT NULL,
  first_name TEXT,
  last_name TEXT,
  full_name TEXT,
  job_title TEXT,
  linkedin_url TEXT,
  phone_number VARCHAR(50),

  -- Company info
  company_name TEXT,
  company_domain TEXT,
  company_size VARCHAR(50),
  company_industry TEXT,
  company_linkedin_url TEXT,

  -- Enrichment metadata
  enrichment_sources JSONB,
  enrichment_score INTEGER,
  last_enriched_at TIMESTAMPTZ,

  -- AI research
  ai_research JSONB,
  personalization_data JSONB,

  -- Status
  status lead_status DEFAULT 'new' NOT NULL,
  last_contacted_at TIMESTAMPTZ,
  last_replied_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS leads_tenant_id_idx ON leads(tenant_id);
CREATE INDEX IF NOT EXISTS leads_campaign_id_idx ON leads(campaign_id);
CREATE INDEX IF NOT EXISTS leads_email_idx ON leads(email);
CREATE INDEX IF NOT EXISTS leads_status_idx ON leads(status);
CREATE INDEX IF NOT EXISTS leads_company_domain_idx ON leads(company_domain);

-- Trigram index for fuzzy search
CREATE INDEX IF NOT EXISTS leads_company_name_trgm_idx ON leads USING gin(company_name gin_trgm_ops);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_leads ON leads
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Email accounts table
CREATE TABLE IF NOT EXISTS email_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  email VARCHAR(255) NOT NULL UNIQUE,
  provider VARCHAR(50) NOT NULL,

  -- Connection details (encrypted)
  api_key TEXT,
  smtp_host VARCHAR(255),
  smtp_port INTEGER,
  smtp_username TEXT,
  smtp_password TEXT,

  -- Warmup configuration
  is_warming_up BOOLEAN DEFAULT true,
  warmup_started_at TIMESTAMPTZ,
  warmup_stage VARCHAR(20) DEFAULT 'new',
  daily_limit INTEGER DEFAULT 50,
  current_daily_sent INTEGER DEFAULT 0,
  last_reset_at TIMESTAMPTZ DEFAULT now(),

  -- Deliverability metrics
  delivery_rate DECIMAL(5, 2),
  spam_rate DECIMAL(5, 2),
  bounce_rate DECIMAL(5, 2),

  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS email_accounts_tenant_id_idx ON email_accounts(tenant_id);
CREATE INDEX IF NOT EXISTS email_accounts_is_active_idx ON email_accounts(is_active) WHERE is_active = true;

ALTER TABLE email_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_email_accounts ON email_accounts
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Email messages table
CREATE TABLE IF NOT EXISTS email_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  email_account_id UUID NOT NULL REFERENCES email_accounts(id),

  subject TEXT NOT NULL,
  body TEXT NOT NULL,

  -- Tracking
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  replied_at TIMESTAMPTZ,
  bounced_at TIMESTAMPTZ,
  spam_reported_at TIMESTAMPTZ,

  -- Metadata
  provider_message_id TEXT,
  error TEXT,

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS email_messages_tenant_id_idx ON email_messages(tenant_id);
CREATE INDEX IF NOT EXISTS email_messages_lead_id_idx ON email_messages(lead_id);
CREATE INDEX IF NOT EXISTS email_messages_sent_at_idx ON email_messages(sent_at);
CREATE INDEX IF NOT EXISTS email_messages_campaign_id_idx ON email_messages(campaign_id);

ALTER TABLE email_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_email_messages ON email_messages
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Agent logs table (for AI transparency)
CREATE TABLE IF NOT EXISTS agent_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  session_id UUID NOT NULL,
  agent_type VARCHAR(50) NOT NULL,
  action TEXT NOT NULL,
  input JSONB,
  output JSONB,
  model VARCHAR(50),
  tokens_used INTEGER,
  duration_ms INTEGER,
  error TEXT,

  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS agent_logs_tenant_id_idx ON agent_logs(tenant_id);
CREATE INDEX IF NOT EXISTS agent_logs_session_id_idx ON agent_logs(session_id);
CREATE INDEX IF NOT EXISTS agent_logs_created_at_idx ON agent_logs(created_at);

ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS tenant_isolation_agent_logs ON agent_logs
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_email_accounts_updated_at BEFORE UPDATE ON email_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to reset daily email counters
CREATE OR REPLACE FUNCTION reset_daily_email_counters()
RETURNS void AS $$
BEGIN
  UPDATE email_accounts
  SET current_daily_sent = 0,
      last_reset_at = now()
  WHERE last_reset_at < now() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- Initial seed data (for development)
INSERT INTO tenants (id, name, slug) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Demo Tenant', 'demo-tenant')
ON CONFLICT DO NOTHING;

INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, role) VALUES
  (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'demo@example.com',
    '$2b$10$K7L1OJ45/4Y2nIvhRVpCe.FSmhDdWoXehVzJptJ/op0lSsvqNu/1u', -- password: 'demo123'
    'Demo',
    'User',
    'owner'
  )
ON CONFLICT DO NOTHING;
