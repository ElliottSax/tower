import axios from 'axios';
import { EnrichmentProvider, EnrichmentResult } from '../../../agents/types';

/**
 * Clearbit Provider
 *
 * Pros:
 * - High data accuracy (85%+)
 * - Good for US and European companies
 * - Clean, well-structured data
 *
 * Cons:
 * - More expensive than Apollo
 * - Smaller database
 * - $0.71 per verified contact
 *
 * API: https://clearbit.com/docs
 */

export class ClearbitProvider implements EnrichmentProvider {
  name = 'clearbit';
  cost = 0.71;
  priority = 2; // Second choice (higher cost, but high quality)

  private apiKey: string;
  private baseUrl = 'https://person.clearbit.com/v2';

  constructor() {
    this.apiKey = process.env.CLEARBIT_API_KEY || '';
  }

  isConfigured(): boolean {
    return !!this.apiKey;
  }

  async lookup(email: string, domain?: string): Promise<EnrichmentResult | null> {
    if (!email) {
      return null; // Clearbit requires email
    }

    try {
      const response = await axios.get(`${this.baseUrl}/combined/find`, {
        params: { email },
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
        },
      });

      const data = response.data;
      const person = data.person;
      const company = data.company;

      if (!person) {
        return null;
      }

      const result: EnrichmentResult = {
        source: 'clearbit',
        confidence: this.calculateConfidence(person, company),
        data: {
          email: person.email,
          firstName: person.name?.givenName,
          lastName: person.name?.familyName,
          jobTitle: person.employment?.title,
          phoneNumber: person.phone,
          companyName: company?.name,
          companyDomain: company?.domain,
          companySize: company?.metrics?.employees?.toString(),
          companyIndustry: company?.category?.industry,
          linkedinUrl: person.linkedin?.handle
            ? `https://linkedin.com/in/${person.linkedin.handle}`
            : undefined,
          city: person.geo?.city,
          state: person.geo?.state,
          country: person.geo?.country,
          bio: person.bio,
        },
      };

      return result;
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }

      console.error('[Clearbit] Lookup error:', error.message);
      throw new Error(`Clearbit API error: ${error.message}`);
    }
  }

  private calculateConfidence(person: any, company: any): number {
    let score = 0;

    // Clearbit data is generally high quality
    if (person.email) score += 25;
    if (person.name?.givenName && person.name?.familyName) score += 25;
    if (person.employment?.title) score += 20;
    if (person.linkedin?.handle) score += 15;
    if (company?.name) score += 10;
    if (company?.domain) score += 5;

    return Math.min(score, 100);
  }
}
