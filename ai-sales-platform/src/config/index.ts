import dotenv from 'dotenv';

dotenv.config();

export const config = {
  // Server
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  databaseUrl: process.env.DATABASE_URL || '',

  // Redis
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',

  // Authentication
  jwtSecret: process.env.JWT_SECRET || 'change-me-in-production',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',

  // AI Providers
  openaiApiKey: process.env.OPENAI_API_KEY || '',
  anthropicApiKey: process.env.ANTHROPIC_API_KEY || '',

  // Data Enrichment
  apolloApiKey: process.env.APOLLO_API_KEY || '',
  clearbitApiKey: process.env.CLEARBIT_API_KEY || '',
  zoomInfoApiKey: process.env.ZOOMINFO_API_KEY || '',

  // Email
  sendgridApiKey: process.env.SENDGRID_API_KEY || '',
  resendApiKey: process.env.RESEND_API_KEY || '',

  // Stripe
  stripeSecretKey: process.env.STRIPE_SECRET_KEY || '',
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '',

  // Rate Limiting
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
  rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),

  // Email Sending Limits
  emailDailyLimit: 50, // Per inbox
  emailWarmupDuration: 42, // Days to fully warm up an inbox
  emailSpamThreshold: 0.003, // 0.3% spam rate limit

  // AI Configuration
  defaultModel: 'gpt-4o-mini',
  defaultTemperature: 0.35,

  // Enrichment Configuration
  enrichmentTimeout: 5000, // 5 seconds per provider
  enrichmentBatchSize: 10, // Process 10 leads at a time
};

// Validate required environment variables
export function validateConfig(): void {
  const required = [
    'DATABASE_URL',
    'JWT_SECRET',
  ];

  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}\n` +
      'Copy .env.example to .env and fill in the values.'
    );
  }

  // Warn about missing optional but recommended configs
  const recommended = [
    'OPENAI_API_KEY',
    'APOLLO_API_KEY',
  ];

  const missingRecommended = recommended.filter((key) => !process.env[key]);

  if (missingRecommended.length > 0) {
    console.warn(
      `Warning: Missing recommended environment variables: ${missingRecommended.join(', ')}\n` +
      'Some features may not work without these.'
    );
  }
}
