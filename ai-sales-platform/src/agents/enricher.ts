import { AIMessage } from '@langchain/core/messages';
import { AgentState, EnrichmentProvider, EnrichmentResult } from './types';
import { logAgentAction } from '../utils/logging';
import { waterfallEnrich } from '../services/enrichment/waterfall';

/**
 * Enricher Agent - Finds contact details through waterfall enrichment
 *
 * Uses waterfall pattern to query multiple data providers:
 * 1. Apollo (low cost, good coverage)
 * 2. Clearbit (medium cost, high accuracy)
 * 3. ZoomInfo (high cost, premium data)
 * 4. Web scraping (fallback)
 *
 * Stops as soon as valid data is found.
 */

export async function enricherAgent(state: AgentState): Promise<Partial<AgentState>> {
  const startTime = Date.now();

  try {
    // Check if we have enough information to enrich
    if (!state.lead?.email && !state.lead?.companyDomain) {
      return {
        errors: [...(state.errors || []), 'Enricher: No email or domain to enrich'],
      };
    }

    // Run waterfall enrichment
    const enrichmentResult = await waterfallEnrich({
      email: state.lead.email,
      domain: state.lead.companyDomain,
      firstName: state.lead.firstName,
      lastName: state.lead.lastName,
    });

    if (!enrichmentResult) {
      return {
        errors: [...(state.errors || []), 'Enricher: No data found from any provider'],
        enrichment: {
          sources: [],
          confidence: 0,
          data: {},
        },
      };
    }

    const durationMs = Date.now() - startTime;

    // Log the enrichment
    await logAgentAction({
      tenantId: state.tenantId,
      sessionId: state.sessionId,
      agentType: 'enricher',
      action: 'waterfall_enrichment',
      input: {
        email: state.lead.email,
        domain: state.lead.companyDomain,
      },
      output: {
        source: enrichmentResult.source,
        confidence: enrichmentResult.confidence,
        fieldsFound: Object.keys(enrichmentResult.data).length,
      },
      model: 'n/a',
      durationMs,
    });

    // Merge enrichment data with existing lead data
    const enrichedLead = {
      ...state.lead,
      ...enrichmentResult.data,
    };

    return {
      lead: enrichedLead,
      enrichment: {
        sources: [enrichmentResult.source],
        confidence: enrichmentResult.confidence,
        data: enrichmentResult.data,
      },
      messages: [
        ...state.messages,
        new AIMessage(
          `Enrichment completed via ${enrichmentResult.source}. ` +
          `Confidence: ${enrichmentResult.confidence}%. ` +
          `Found ${Object.keys(enrichmentResult.data).length} data fields.`
        ),
      ],
    };
  } catch (error: any) {
    console.error('Enricher agent error:', error);
    return {
      errors: [...(state.errors || []), `Enricher error: ${error.message}`],
    };
  }
}
