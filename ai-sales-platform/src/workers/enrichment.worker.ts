/**
 * Enrichment Worker
 *
 * Processes background jobs for lead enrichment using BullMQ.
 * Implements retry strategies and error handling patterns from research.
 */

import { Worker, Job, UnrecoverableError } from 'bullmq';
import IORedis from 'ioredis';
import { waterfallEnrich } from '../services/enrichment/waterfall';
import { db } from '../utils/db';
import { leads } from '../db/schema';
import { eq } from 'drizzle-orm';

// Redis connection with recommended settings
const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', {
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
});

interface EnrichmentJobData {
  leadId: string;
  tenantId: string;
  priority?: 'low' | 'medium' | 'high';
}

interface EnrichmentJobResult {
  leadId: string;
  success: boolean;
  enrichmentData?: any;
  source?: string;
  confidence?: number;
  error?: string;
}

/**
 * Custom backoff strategy
 * - First retry: 1 second
 * - Second retry: 4 seconds
 * - Third retry: 16 seconds
 */
function enrichmentBackoffStrategy(attemptsMade: number): number {
  // Exponential backoff: 2^(attempts) * 1000ms
  const delay = Math.pow(2, attemptsMade) * 1000;

  // Max 1 minute delay
  return Math.min(delay, 60000);
}

/**
 * Main job processor
 */
async function processEnrichment(job: Job<EnrichmentJobData>): Promise<EnrichmentJobResult> {
  const { leadId, tenantId, priority = 'medium' } = job.data;

  console.log(`[Enrichment Worker] Processing lead ${leadId} (Priority: ${priority})`);

  try {
    // 1. Fetch lead from database
    const [lead] = await db
      .select()
      .from(leads)
      .where(eq(leads.id, leadId))
      .limit(1);

    if (!lead) {
      // Unrecoverable error - lead doesn't exist
      throw new UnrecoverableError(`Lead ${leadId} not found`);
    }

    // Validate lead has required data for enrichment
    if (!lead.email && !lead.companyDomain) {
      throw new UnrecoverableError('Lead has no email or company domain for enrichment');
    }

    // 2. Check if already enriched recently (within 7 days)
    if (lead.lastEnrichedAt) {
      const daysSinceEnrichment =
        (Date.now() - lead.lastEnrichedAt.getTime()) / (1000 * 60 * 60 * 24);

      if (daysSinceEnrichment < 7 && lead.enrichmentScore && lead.enrichmentScore > 70) {
        console.log(`[Enrichment Worker] Lead ${leadId} recently enriched, skipping`);
        return {
          leadId,
          success: true,
          enrichmentData: lead.enrichmentSources,
        };
      }
    }

    // 3. Run waterfall enrichment
    const enrichmentResult = await waterfallEnrich({
      email: lead.email,
      domain: lead.companyDomain || undefined,
      firstName: lead.firstName || undefined,
      lastName: lead.lastName || undefined,
    });

    if (!enrichmentResult) {
      // No data found - not an error, just no results
      console.log(`[Enrichment Worker] No enrichment data found for lead ${leadId}`);

      // Update lead to mark enrichment attempt
      await db
        .update(leads)
        .set({
          lastEnrichedAt: new Date(),
          enrichmentScore: 0,
        })
        .where(eq(leads.id, leadId));

      return {
        leadId,
        success: false,
        error: 'No enrichment data found',
      };
    }

    // 4. Update lead with enrichment data
    await db
      .update(leads)
      .set({
        // Update contact fields
        firstName: enrichmentResult.data.firstName || lead.firstName,
        lastName: enrichmentResult.data.lastName || lead.lastName,
        fullName: enrichmentResult.data.firstName && enrichmentResult.data.lastName
          ? `${enrichmentResult.data.firstName} ${enrichmentResult.data.lastName}`
          : lead.fullName,
        jobTitle: enrichmentResult.data.jobTitle || lead.jobTitle,
        phoneNumber: enrichmentResult.data.phoneNumber || lead.phoneNumber,
        linkedinUrl: enrichmentResult.data.linkedinUrl || lead.linkedinUrl,

        // Update company fields
        companyName: enrichmentResult.data.companyName || lead.companyName,
        companyDomain: enrichmentResult.data.companyDomain || lead.companyDomain,
        companySize: enrichmentResult.data.companySize || lead.companySize,
        companyIndustry: enrichmentResult.data.companyIndustry || lead.companyIndustry,

        // Update enrichment metadata
        enrichmentSources: [enrichmentResult.source],
        enrichmentScore: enrichmentResult.confidence,
        lastEnrichedAt: new Date(),
        status: 'enriched',
      })
      .where(eq(leads.id, leadId));

    console.log(
      `[Enrichment Worker] Successfully enriched lead ${leadId} via ${enrichmentResult.source} ` +
      `(Confidence: ${enrichmentResult.confidence}%)`
    );

    return {
      leadId,
      success: true,
      enrichmentData: enrichmentResult.data,
      source: enrichmentResult.source,
      confidence: enrichmentResult.confidence,
    };

  } catch (error: any) {
    // Check if it's an unrecoverable error
    if (error instanceof UnrecoverableError) {
      console.error(`[Enrichment Worker] Unrecoverable error for lead ${leadId}:`, error.message);
      throw error; // Don't retry
    }

    // Recoverable error - will be retried
    console.error(`[Enrichment Worker] Error enriching lead ${leadId}:`, error.message);
    throw error; // Will trigger retry with backoff
  }
}

/**
 * Create and start the worker
 */
export function startEnrichmentWorker() {
  const worker = new Worker<EnrichmentJobData, EnrichmentJobResult>(
    'enrichment',
    processEnrichment,
    {
      connection,
      concurrency: 5, // Process 5 jobs in parallel
      settings: {
        backoffStrategy: enrichmentBackoffStrategy,
      },
      limiter: {
        max: 10,      // Max 10 jobs processed
        duration: 1000, // Per second
      },
    }
  );

  // Event listeners
  worker.on('completed', (job, result) => {
    console.log(
      `[Enrichment Worker] Job ${job.id} completed for lead ${result.leadId} ` +
      `(Success: ${result.success})`
    );
  });

  worker.on('failed', (job, error) => {
    console.error(
      `[Enrichment Worker] Job ${job?.id} failed after ${job?.attemptsMade} attempts:`,
      error.message
    );
  });

  worker.on('error', (error) => {
    console.error('[Enrichment Worker] Worker error:', error);
  });

  console.log('[Enrichment Worker] Started with concurrency 5');

  return worker;
}

// Start worker if running as standalone script
if (require.main === module) {
  console.log('Starting enrichment worker...');
  startEnrichmentWorker();
}
