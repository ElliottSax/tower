import { EnrichmentProvider, EnrichmentResult } from '../../agents/types';
import { ApolloProvider } from './providers/apollo';
import { ClearbitProvider } from './providers/clearbit';
import { ZoomInfoProvider } from './providers/zoominfo';
import { ScraperProvider } from './providers/scraper';

/**
 * Waterfall Enrichment - Core Pattern
 *
 * Sequential routing through prioritized providers until valid data is found.
 * This achieves 80%+ coverage vs. 40% from a single provider.
 *
 * Provider priority (ordered by cost-effectiveness):
 * 1. Apollo (lowest cost, good coverage)
 * 2. Clearbit (medium cost, high accuracy)
 * 3. ZoomInfo (highest cost, premium data)
 * 4. Web scraping (free but slow, fallback only)
 *
 * Key features:
 * - Stops at first valid result (cost optimization)
 * - Validates data quality before returning
 * - Normalizes data across providers
 * - Logs failures for provider reliability tracking
 */

interface EnrichmentInput {
  email?: string;
  domain?: string;
  firstName?: string;
  lastName?: string;
}

// Initialize providers in priority order
const providers: EnrichmentProvider[] = [
  new ApolloProvider(),
  new ClearbitProvider(),
  new ZoomInfoProvider(),
  new ScraperProvider(),
].sort((a, b) => a.priority - b.priority); // Ensure correct ordering

/**
 * Validates if enrichment result is usable
 */
function isValidResult(result: EnrichmentResult | null): boolean {
  if (!result) return false;

  const { data } = result;

  // Must have at least one of these key fields
  const hasMinimumData =
    !!data.email ||
    !!data.phoneNumber ||
    !!data.linkedinUrl;

  // Confidence threshold
  const hasGoodConfidence = result.confidence >= 50;

  return hasMinimumData && hasGoodConfidence;
}

/**
 * Normalizes data format across providers
 */
function normalizeData(result: EnrichmentResult): EnrichmentResult {
  const { data } = result;

  return {
    ...result,
    data: {
      // Clean email
      email: data.email?.toLowerCase().trim(),

      // Normalize names
      firstName: data.firstName?.trim(),
      lastName: data.lastName?.trim(),

      // Clean phone (remove spaces, dashes)
      phoneNumber: data.phoneNumber?.replace(/[\s-]/g, ''),

      // Ensure URLs are complete
      linkedinUrl: data.linkedinUrl?.startsWith('http')
        ? data.linkedinUrl
        : data.linkedinUrl
        ? `https://linkedin.com${data.linkedinUrl}`
        : undefined,

      // Pass through other fields
      ...data,
    },
  };
}

/**
 * Main waterfall enrichment function
 */
export async function waterfallEnrich(
  input: EnrichmentInput
): Promise<EnrichmentResult | null> {
  // Validate input
  if (!input.email && !input.domain) {
    throw new Error('Either email or domain is required for enrichment');
  }

  console.log(`[Waterfall] Starting enrichment for ${input.email || input.domain}`);

  // Track which providers we tried
  const attemptedProviders: string[] = [];
  const failedProviders: Array<{ name: string; error: string }> = [];

  // Try each provider in order
  for (const provider of providers) {
    // Skip if provider is not configured
    if (!provider.isConfigured?.()) {
      console.log(`[Waterfall] Skipping ${provider.name} - not configured`);
      continue;
    }

    attemptedProviders.push(provider.name);

    try {
      console.log(`[Waterfall] Trying ${provider.name}...`);

      const result = await provider.lookup(
        input.email || '',
        input.domain
      );

      if (isValidResult(result)) {
        const normalized = normalizeData(result!);

        console.log(
          `[Waterfall] ✓ Success via ${provider.name}. ` +
          `Confidence: ${normalized.confidence}%. ` +
          `Cost: $${provider.cost}`
        );

        return normalized;
      } else {
        console.log(`[Waterfall] ${provider.name} returned insufficient data`);
        failedProviders.push({
          name: provider.name,
          error: 'Insufficient data quality',
        });
      }
    } catch (error: any) {
      console.error(`[Waterfall] ${provider.name} error:`, error.message);
      failedProviders.push({
        name: provider.name,
        error: error.message,
      });
      // Continue to next provider
      continue;
    }
  }

  // No provider returned valid data
  console.warn(
    `[Waterfall] ✗ Failed to enrich ${input.email || input.domain}. ` +
    `Tried: ${attemptedProviders.join(', ')}`
  );

  return null;
}

/**
 * Batch enrichment with concurrency control
 */
export async function batchEnrich(
  inputs: EnrichmentInput[],
  options: {
    concurrency?: number;
    onProgress?: (completed: number, total: number) => void;
  } = {}
): Promise<Array<EnrichmentResult | null>> {
  const { concurrency = 5, onProgress } = options;
  const results: Array<EnrichmentResult | null> = [];
  let completed = 0;

  // Process in batches
  for (let i = 0; i < inputs.length; i += concurrency) {
    const batch = inputs.slice(i, i + concurrency);

    const batchResults = await Promise.all(
      batch.map((input) =>
        waterfallEnrich(input).catch((error) => {
          console.error('Batch enrichment error:', error);
          return null;
        })
      )
    );

    results.push(...batchResults);
    completed += batch.length;

    if (onProgress) {
      onProgress(completed, inputs.length);
    }
  }

  return results;
}

/**
 * Get provider status (for monitoring/debugging)
 */
export function getProviderStatus(): Array<{
  name: string;
  configured: boolean;
  priority: number;
  cost: number;
}> {
  return providers.map((p) => ({
    name: p.name,
    configured: p.isConfigured?.() ?? true,
    priority: p.priority,
    cost: p.cost,
  }));
}
