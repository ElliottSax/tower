import axios from 'axios';
import { EnrichmentProvider, EnrichmentResult } from '../../../agents/types';

/**
 * ZoomInfo Provider
 *
 * Pros:
 * - Largest B2B database
 * - Best phone number accuracy ("gold standard")
 * - Excellent for large companies (10,000+ employees)
 *
 * Cons:
 * - Very expensive ($15K-$50K+/year)
 * - Aggressive sales/renewal practices
 * - Requires enterprise contract
 *
 * API: https://api-docs.zoominfo.com/
 */

export class ZoomInfoProvider implements EnrichmentProvider {
  name = 'zoominfo';
  cost = 0.85; // Approximate per-lookup cost with enterprise contract
  priority = 3; // Last choice (highest cost, but premium data)

  private apiKey: string;
  private baseUrl = 'https://api.zoominfo.com';

  constructor() {
    this.apiKey = process.env.ZOOMINFO_API_KEY || '';
  }

  isConfigured(): boolean {
    return !!this.apiKey;
  }

  async lookup(email: string, domain?: string): Promise<EnrichmentResult | null> {
    // ZoomInfo requires OAuth authentication
    // This is a simplified implementation
    // In production, you'd need to:
    // 1. Get OAuth token
    // 2. Handle token refresh
    // 3. Implement proper rate limiting

    if (!email && !domain) {
      return null;
    }

    try {
      // First, get OAuth token (cached in production)
      const token = await this.getAccessToken();

      // Search for contact
      const response = await axios.post(
        `${this.baseUrl}/lookup/contact`,
        {
          matchPersonInput: [
            {
              emailAddress: email || undefined,
              companyDomain: domain || undefined,
            },
          ],
        },
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      const contact = response.data?.data?.[0];

      if (!contact) {
        return null;
      }

      const result: EnrichmentResult = {
        source: 'zoominfo',
        confidence: this.calculateConfidence(contact),
        data: {
          email: contact.email,
          firstName: contact.firstName,
          lastName: contact.lastName,
          jobTitle: contact.jobTitle,
          phoneNumber: contact.directPhoneNumber || contact.mobilePhoneNumber,
          companyName: contact.companyName,
          companyDomain: contact.companyWebsite,
          companySize: contact.companyEmployeeCount?.toString(),
          companyIndustry: contact.companyIndustry,
          linkedinUrl: contact.linkedInUrl,
          city: contact.city,
          state: contact.state,
          country: contact.country,
        },
      };

      return result;
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }

      console.error('[ZoomInfo] Lookup error:', error.message);
      throw new Error(`ZoomInfo API error: ${error.message}`);
    }
  }

  private async getAccessToken(): Promise<string> {
    // In production, cache this token (it's valid for 60 minutes)
    const response = await axios.post(`${this.baseUrl}/authenticate`, {
      username: process.env.ZOOMINFO_USERNAME,
      password: process.env.ZOOMINFO_PASSWORD,
    });

    return response.data.jwt;
  }

  private calculateConfidence(contact: any): number {
    let score = 0;

    // ZoomInfo data is premium quality
    if (contact.email) score += 25;
    if (contact.firstName && contact.lastName) score += 25;
    if (contact.jobTitle) score += 20;
    if (contact.directPhoneNumber || contact.mobilePhoneNumber) score += 20;
    if (contact.linkedInUrl) score += 10;

    return Math.min(score, 100);
  }
}
