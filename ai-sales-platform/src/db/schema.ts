import { pgTable, uuid, text, timestamp, integer, boolean, jsonb, varchar, decimal, index, pgEnum } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// Enums
export const userRoleEnum = pgEnum('user_role', ['owner', 'admin', 'member']);
export const campaignStatusEnum = pgEnum('campaign_status', ['draft', 'active', 'paused', 'completed']);
export const leadStatusEnum = pgEnum('lead_status', ['new', 'researching', 'enriched', 'contacted', 'replied', 'converted', 'disqualified']);
export const creditTransactionTypeEnum = pgEnum('credit_transaction_type', ['grant', 'burn', 'expire', 'refund']);

// Tenants (Organizations)
export const tenants = pgTable('tenants', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  slug: varchar('slug', { length: 50 }).notNull().unique(),
  stripeCustomerId: text('stripe_customer_id'),
  subscriptionStatus: text('subscription_status').default('trial'),
  subscriptionEndsAt: timestamp('subscription_ends_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Users
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),
  email: varchar('email', { length: 255 }).notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  firstName: text('first_name'),
  lastName: text('last_name'),
  role: userRoleEnum('role').default('member').notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  lastLoginAt: timestamp('last_login_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('users_tenant_id_idx').on(table.tenantId),
}));

// Credit Ledger (for transparent usage tracking)
export const creditLedger = pgTable('credit_ledger', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  type: creditTransactionTypeEnum('type').notNull(),
  amount: integer('amount').notNull(),
  balanceAfter: integer('balance_after').notNull(),
  description: text('description').notNull(),
  metadata: jsonb('metadata'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('credit_ledger_tenant_id_idx').on(table.tenantId),
  createdAtIdx: index('credit_ledger_created_at_idx').on(table.createdAt),
}));

// Campaigns
export const campaigns = pgTable('campaigns', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  status: campaignStatusEnum('status').default('draft').notNull(),

  // Targeting criteria
  targetCompanySize: varchar('target_company_size', { length: 50 }),
  targetIndustries: jsonb('target_industries').$type<string[]>(),
  targetJobTitles: jsonb('target_job_titles').$type<string[]>(),
  targetLocations: jsonb('target_locations').$type<string[]>(),

  // AI configuration
  personalizationLevel: varchar('personalization_level', { length: 20 }).default('medium'),
  aiModel: varchar('ai_model', { length: 50 }).default('gpt-4o-mini'),
  customInstructions: text('custom_instructions'),

  // Email configuration
  emailSubjectTemplate: text('email_subject_template'),
  emailBodyTemplate: text('email_body_template'),
  followUpSequence: jsonb('follow_up_sequence'),

  // Statistics
  leadsCount: integer('leads_count').default(0),
  emailsSent: integer('emails_sent').default(0),
  emailsOpened: integer('emails_opened').default(0),
  emailsReplied: integer('emails_replied').default(0),

  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('campaigns_tenant_id_idx').on(table.tenantId),
  statusIdx: index('campaigns_status_idx').on(table.status),
}));

// Leads
export const leads = pgTable('leads', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),
  campaignId: uuid('campaign_id').references(() => campaigns.id, { onDelete: 'cascade' }),

  // Contact information
  email: varchar('email', { length: 255 }).notNull(),
  firstName: text('first_name'),
  lastName: text('last_name'),
  fullName: text('full_name'),
  jobTitle: text('job_title'),
  linkedinUrl: text('linkedin_url'),
  phoneNumber: varchar('phone_number', { length: 50 }),

  // Company information
  companyName: text('company_name'),
  companyDomain: text('company_domain'),
  companySize: varchar('company_size', { length: 50 }),
  companyIndustry: text('company_industry'),
  companyLinkedinUrl: text('company_linkedin_url'),

  // Enrichment metadata
  enrichmentSources: jsonb('enrichment_sources').$type<string[]>(),
  enrichmentScore: integer('enrichment_score'), // 0-100
  lastEnrichedAt: timestamp('last_enriched_at'),

  // AI research data
  aiResearch: jsonb('ai_research'), // Store AI-generated insights
  personalizationData: jsonb('personalization_data'),

  // Status and engagement
  status: leadStatusEnum('status').default('new').notNull(),
  lastContactedAt: timestamp('last_contacted_at'),
  lastRepliedAt: timestamp('last_replied_at'),

  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('leads_tenant_id_idx').on(table.tenantId),
  campaignIdIdx: index('leads_campaign_id_idx').on(table.campaignId),
  emailIdx: index('leads_email_idx').on(table.email),
  statusIdx: index('leads_status_idx').on(table.status),
}));

// Email Accounts (for multi-mailbox rotation)
export const emailAccounts = pgTable('email_accounts', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),

  email: varchar('email', { length: 255 }).notNull().unique(),
  provider: varchar('provider', { length: 50 }).notNull(), // 'sendgrid', 'resend', 'gmail', etc.

  // Connection details (encrypted)
  apiKey: text('api_key'),
  smtpHost: varchar('smtp_host', { length: 255 }),
  smtpPort: integer('smtp_port'),
  smtpUsername: text('smtp_username'),
  smtpPassword: text('smtp_password'),

  // Warmup and limits
  isWarmingUp: boolean('is_warming_up').default(true),
  warmupStartedAt: timestamp('warmup_started_at'),
  dailyLimit: integer('daily_limit').default(50),
  currentDailySent: integer('current_daily_sent').default(0),
  lastResetAt: timestamp('last_reset_at').defaultNow(),

  // Deliverability metrics
  deliveryRate: decimal('delivery_rate', { precision: 5, scale: 2 }),
  spamRate: decimal('spam_rate', { precision: 5, scale: 2 }),

  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('email_accounts_tenant_id_idx').on(table.tenantId),
}));

// Email Messages
export const emailMessages = pgTable('email_messages', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),
  campaignId: uuid('campaign_id').references(() => campaigns.id, { onDelete: 'cascade' }),
  leadId: uuid('lead_id').notNull().references(() => leads.id, { onDelete: 'cascade' }),
  emailAccountId: uuid('email_account_id').notNull().references(() => emailAccounts.id),

  subject: text('subject').notNull(),
  body: text('body').notNull(),

  // Tracking
  sentAt: timestamp('sent_at'),
  deliveredAt: timestamp('delivered_at'),
  openedAt: timestamp('opened_at'),
  clickedAt: timestamp('clicked_at'),
  repliedAt: timestamp('replied_at'),
  bouncedAt: timestamp('bounced_at'),
  spamReportedAt: timestamp('spam_reported_at'),

  // Metadata
  providerMessageId: text('provider_message_id'),
  error: text('error'),

  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('email_messages_tenant_id_idx').on(table.tenantId),
  leadIdIdx: index('email_messages_lead_id_idx').on(table.leadId),
  sentAtIdx: index('email_messages_sent_at_idx').on(table.sentAt),
}));

// AI Agent Logs (for transparency and debugging)
export const agentLogs = pgTable('agent_logs', {
  id: uuid('id').primaryKey().defaultRandom(),
  tenantId: uuid('tenant_id').notNull().references(() => tenants.id, { onDelete: 'cascade' }),

  sessionId: uuid('session_id').notNull(), // Groups related agent actions
  agentType: varchar('agent_type', { length: 50 }).notNull(), // 'supervisor', 'researcher', 'enricher', 'writer'
  action: text('action').notNull(),
  input: jsonb('input'),
  output: jsonb('output'),
  model: varchar('model', { length: 50 }),
  tokensUsed: integer('tokens_used'),
  durationMs: integer('duration_ms'),
  error: text('error'),

  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (table) => ({
  tenantIdIdx: index('agent_logs_tenant_id_idx').on(table.tenantId),
  sessionIdIdx: index('agent_logs_session_id_idx').on(table.sessionId),
  createdAtIdx: index('agent_logs_created_at_idx').on(table.createdAt),
}));

// Relations
export const tenantsRelations = relations(tenants, ({ many }) => ({
  users: many(users),
  campaigns: many(campaigns),
  leads: many(leads),
}));

export const usersRelations = relations(users, ({ one, many }) => ({
  tenant: one(tenants, {
    fields: [users.tenantId],
    references: [tenants.id],
  }),
  campaigns: many(campaigns),
}));

export const campaignsRelations = relations(campaigns, ({ one, many }) => ({
  tenant: one(tenants, {
    fields: [campaigns.tenantId],
    references: [tenants.id],
  }),
  user: one(users, {
    fields: [campaigns.userId],
    references: [users.id],
  }),
  leads: many(leads),
}));

export const leadsRelations = relations(leads, ({ one, many }) => ({
  tenant: one(tenants, {
    fields: [leads.tenantId],
    references: [tenants.id],
  }),
  campaign: one(campaigns, {
    fields: [leads.campaignId],
    references: [campaigns.id],
  }),
  emailMessages: many(emailMessages),
}));
