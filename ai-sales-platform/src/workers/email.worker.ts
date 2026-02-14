/**
 * Email Worker
 *
 * Processes background jobs for sending emails with proper rate limiting
 * and deliverability tracking.
 */

import { Worker, Job, UnrecoverableError } from 'bullmq';
import IORedis from 'ioredis';
import { db } from '../utils/db';
import { emailAccounts, emailMessages, leads, campaigns } from '../db/schema';
import { eq, and, sql } from 'drizzle-orm';
import { sendEmail, SendEmailParams } from '../services/email/sender';

const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', {
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
});

interface EmailJobData {
  leadId: string;
  campaignId: string;
  tenantId: string;
  subject: string;
  body: string;
  priority?: 'low' | 'medium' | 'high';
}

interface EmailJobResult {
  leadId: string;
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Select an email account for sending
 */
async function selectEmailAccount(campaignId: string, tenantId: string) {
  // Get campaign to check last used account index
  const [campaign] = await db
    .select()
    .from(campaigns)
    .where(eq(campaigns.id, campaignId))
    .limit(1);

  if (!campaign) {
    throw new UnrecoverableError('Campaign not found');
  }

  // Get all warm, active accounts for this tenant
  // isWarmingUp === false means the account is fully warmed up and ready to send
  const accounts = await db
    .select()
    .from(emailAccounts)
    .where(and(
      eq(emailAccounts.tenantId, tenantId),
      eq(emailAccounts.isActive, true),
      eq(emailAccounts.isWarmingUp, false)
    ));

  if (accounts.length === 0) {
    throw new Error('No warm email accounts available. Please configure email accounts.');
  }

  // Filter accounts that haven't hit daily limit
  const availableAccounts = accounts.filter(
    account => account.currentDailySent < account.dailyLimit
  );

  if (availableAccounts.length === 0) {
    throw new Error('All email accounts have reached their daily limit. Try again tomorrow.');
  }

  // Round-robin selection based on emailsSent count
  const accountIndex = (campaign.emailsSent || 0) % availableAccounts.length;
  const selectedAccount = availableAccounts[accountIndex];

  return selectedAccount;
}

/**
 * Main job processor
 */
async function processEmail(job: Job<EmailJobData>): Promise<EmailJobResult> {
  const { leadId, campaignId, tenantId, subject, body, priority = 'medium' } = job.data;

  console.log(`[Email Worker] Processing email for lead ${leadId} (Priority: ${priority})`);

  try {
    // 1. Fetch lead
    const [lead] = await db
      .select()
      .from(leads)
      .where(eq(leads.id, leadId))
      .limit(1);

    if (!lead) {
      throw new UnrecoverableError(`Lead ${leadId} not found`);
    }

    if (!lead.email) {
      throw new UnrecoverableError(`Lead ${leadId} has no email address`);
    }

    // 2. Select email account
    const account = await selectEmailAccount(campaignId, tenantId);

    console.log(`[Email Worker] Using account ${account.email} to send email`);

    // 3. Send email
    const params: SendEmailParams = {
      from: account.email,
      to: lead.email,
      subject,
      html: body,
      accountId: account.id,
      provider: account.provider as any,
    };

    const result = await sendEmail(params);

    // 4. Create email message record
    const [message] = await db
      .insert(emailMessages)
      .values({
        tenantId,
        campaignId,
        leadId,
        emailAccountId: account.id,
        subject,
        body,
        sentAt: new Date(),
        providerMessageId: result.messageId,
      })
      .returning();

    // 5. Update email account counter
    await db
      .update(emailAccounts)
      .set({ currentDailySent: account.currentDailySent + 1 })
      .where(eq(emailAccounts.id, account.id));

    // 6. Update lead status
    await db
      .update(leads)
      .set({
        status: 'contacted',
        lastContactedAt: new Date(),
      })
      .where(eq(leads.id, leadId));

    // 7. Update campaign statistics
    await db
      .update(campaigns)
      .set({ emailsSent: sql`${campaigns.emailsSent} + 1` })
      .where(eq(campaigns.id, campaignId));

    console.log(`[Email Worker] Successfully sent email to ${lead.email} (Message ID: ${result.messageId})`);

    return {
      leadId,
      success: true,
      messageId: result.messageId,
    };

  } catch (error: any) {
    if (error instanceof UnrecoverableError) {
      console.error(`[Email Worker] Unrecoverable error for lead ${leadId}:`, error.message);
      throw error;
    }

    console.error(`[Email Worker] Error sending email to lead ${leadId}:`, error.message);
    throw error; // Will retry
  }
}

/**
 * Create and start the worker
 */
export function startEmailWorker() {
  const worker = new Worker<EmailJobData, EmailJobResult>(
    'email',
    processEmail,
    {
      connection,
      concurrency: 3, // Send 3 emails in parallel
      settings: {
        backoffStrategy: (attemptsMade) => {
          // Exponential backoff for email sending
          return Math.min(Math.pow(2, attemptsMade) * 2000, 120000); // Max 2 minutes
        },
      },
      limiter: {
        max: 50,       // Max 50 emails
        duration: 60000, // Per minute (to avoid provider rate limits)
      },
    }
  );

  worker.on('completed', (job, result) => {
    console.log(`[Email Worker] Job ${job.id} completed for lead ${result.leadId}`);
  });

  worker.on('failed', (job, error) => {
    console.error(
      `[Email Worker] Job ${job?.id} failed after ${job?.attemptsMade} attempts:`,
      error.message
    );
  });

  worker.on('error', (error) => {
    console.error('[Email Worker] Worker error:', error);
  });

  console.log('[Email Worker] Started with concurrency 3');

  return worker;
}

// Start worker if running as standalone script
if (require.main === module) {
  console.log('Starting email worker...');
  startEmailWorker();
}
