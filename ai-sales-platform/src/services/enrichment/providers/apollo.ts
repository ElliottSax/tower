import axios from 'axios';
import { EnrichmentProvider, EnrichmentResult } from '../../../agents/types';

/**
 * Apollo.io Provider
 *
 * Pros:
 * - Generous free tier (10K credits/month)
 * - Good coverage for US companies
 * - $0.47 per verified contact (with verification)
 * - Fast API response times
 *
 * Cons:
 * - Data quality issues reported (especially outside US)
 * - Phone numbers less reliable than email
 *
 * API: https://apolloio.github.io/apollo-api-docs/
 */

export class ApolloProvider implements EnrichmentProvider {
  name = 'apollo';
  cost = 0.47; // Per verified contact
  priority = 1; // Highest priority (lowest cost, good coverage)

  private apiKey: string;
  private baseUrl = 'https://api.apollo.io/v1';

  constructor() {
    this.apiKey = process.env.APOLLO_API_KEY || '';
  }

  isConfigured(): boolean {
    return !!this.apiKey;
  }

  async lookup(email: string, domain?: string): Promise<EnrichmentResult | null> {
    if (!email && !domain) {
      return null;
    }

    try {
      // Apollo's enrichment endpoint
      const response = await axios.post(
        `${this.baseUrl}/people/match`,
        {
          email: email || undefined,
          domain: domain || undefined,
          reveal_personal_emails: true,
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
            'X-Api-Key': this.apiKey,
          },
        }
      );

      const person = response.data.person;

      if (!person) {
        return null;
      }

      // Map Apollo's data format to our standard format
      const result: EnrichmentResult = {
        source: 'apollo',
        confidence: this.calculateConfidence(person),
        data: {
          email: person.email,
          firstName: person.first_name,
          lastName: person.last_name,
          jobTitle: person.title,
          phoneNumber: person.phone_numbers?.[0]?.raw_number,
          companyName: person.organization?.name,
          companyDomain: person.organization?.website_url,
          companySize: person.organization?.estimated_num_employees?.toString(),
          companyIndustry: person.organization?.industry,
          linkedinUrl: person.linkedin_url,
          city: person.city,
          state: person.state,
          country: person.country,
        },
      };

      return result;
    } catch (error: any) {
      if (error.response?.status === 404) {
        // Not found is not an error - just no data
        return null;
      }

      console.error('[Apollo] Lookup error:', error.message);
      throw new Error(`Apollo API error: ${error.message}`);
    }
  }

  /**
   * Calculate confidence score based on data completeness
   */
  private calculateConfidence(person: any): number {
    let score = 0;

    // Core fields (60 points)
    if (person.email) score += 20;
    if (person.first_name && person.last_name) score += 20;
    if (person.title) score += 20;

    // Additional fields (40 points)
    if (person.phone_numbers?.length) score += 15;
    if (person.linkedin_url) score += 10;
    if (person.organization?.name) score += 10;
    if (person.organization?.website_url) score += 5;

    return Math.min(score, 100);
  }
}
