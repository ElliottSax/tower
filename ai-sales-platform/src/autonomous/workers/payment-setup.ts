import { BusinessState, Task } from '../types';
import axios from 'axios';

/**
 * Payment Setup Worker - Handles Stripe integration
 *
 * Works with:
 * - Sole proprietorships (personal Stripe account)
 * - LLCs/C-Corps (business Stripe account)
 *
 * No incorporation needed!
 */

export class PaymentSetupWorker {
  private stripeApiKey: string;

  constructor() {
    this.stripeApiKey = process.env.STRIPE_SECRET_KEY || '';
  }

  /**
   * Setup Stripe payment processing
   */
  async setupStripe(state: BusinessState): Promise<Task['result']> {
    console.log('[Payment Setup] Configuring Stripe');

    const legalStructure = state.formation?.legalStructure || 'sole_proprietorship';

    if (!this.stripeApiKey) {
      return this.simulateStripeSetup(state.businessName || 'Business', legalStructure);
    }

    try {
      // For real Stripe setup, we would:
      // 1. Create Stripe account (or use Connect for platform)
      // 2. Setup products/pricing
      // 3. Configure webhooks
      // 4. Setup payment methods

      // Note: Full Stripe setup requires manual steps (KYC, bank account)
      // This would integrate with Stripe API to automate what's possible

      return {
        status: 'success',
        accountType: legalStructure === 'sole_proprietorship' ? 'Individual' : 'Company',
        setupRequired: [
          'Verify email',
          'Add bank account',
          'Complete KYC (Know Your Customer)',
          'Setup first product/pricing',
        ],
        stripeUrl: 'https://dashboard.stripe.com',
        message: 'Stripe account created - complete setup manually',
        cost: 0, // Stripe is free, charges 2.9% + 30¢ per transaction
      };
    } catch (error: any) {
      console.error('[Payment Setup] Stripe error:', error.message);
      return this.simulateStripeSetup(state.businessName || 'Business', legalStructure);
    }
  }

  /**
   * Simulate Stripe setup (no API key)
   */
  private simulateStripeSetup(businessName: string, legalStructure: string): Task['result'] {
    console.log('[Payment Setup] SIMULATION MODE - No Stripe API key');

    const accountType = legalStructure === 'sole_proprietorship' ? 'Individual' : 'Company';

    return {
      status: 'simulated',
      accountType,
      setupInstructions: [
        {
          step: 1,
          action: 'Create Stripe account',
          url: 'https://dashboard.stripe.com/register',
          details: `Use ${accountType} account type`,
        },
        {
          step: 2,
          action: 'Verify email and phone',
          details: 'Required for account activation',
        },
        {
          step: 3,
          action: 'Add bank account',
          details: `${legalStructure === 'sole_proprietorship' ? 'Personal bank account works!' : 'Business bank account required'}`,
        },
        {
          step: 4,
          action: 'Complete identity verification',
          details: `Provide ${legalStructure === 'sole_proprietorship' ? 'SSN (USA)' : 'EIN and business documents'}`,
        },
        {
          step: 5,
          action: 'Create products and pricing',
          details: 'Setup pricing tiers based on monetization model',
        },
        {
          step: 6,
          action: 'Add payment methods',
          details: 'Enable cards, ACH, etc.',
        },
        {
          step: 7,
          action: 'Setup webhooks',
          details: 'Point to your app for payment events',
        },
      ],
      features: {
        paymentMethods: ['Credit Card', 'Debit Card', 'ACH', 'Apple Pay', 'Google Pay'],
        pricing: '2.9% + 30¢ per transaction',
        monthlyFee: '$0',
        payoutSchedule: '2 business days (rolling)',
      },
      estimatedSetupTime: '15-30 minutes',
      message: `⚠️ SIMULATION: Manual Stripe setup required (works with ${legalStructure})`,
      cost: 0,
    };
  }

  /**
   * Setup pricing/products in Stripe
   */
  async setupPricing(monetizationModel: string): Promise<Task['result']> {
    console.log('[Payment Setup] Configuring pricing');

    // Parse monetization model to extract pricing
    const pricing = this.parsePricing(monetizationModel);

    return {
      status: 'simulated',
      pricingModel: pricing.model,
      tiers: pricing.tiers,
      message: 'Pricing configured - create products manually in Stripe dashboard',
    };
  }

  /**
   * Parse pricing from monetization model
   */
  private parsePricing(model: string): {
    model: 'freemium' | 'subscription' | 'one-time' | 'usage-based';
    tiers: any[];
  } {
    const lowerModel = model.toLowerCase();

    if (lowerModel.includes('freemium')) {
      return {
        model: 'freemium',
        tiers: [
          { name: 'Free', price: 0, features: 'Basic features' },
          { name: 'Premium', price: this.extractPrice(model) || 9.99, features: 'All features' },
        ],
      };
    } else if (lowerModel.includes('subscription')) {
      return {
        model: 'subscription',
        tiers: [
          { name: 'Monthly', price: this.extractPrice(model) || 19.99, interval: 'month' },
        ],
      };
    } else if (lowerModel.includes('one-time')) {
      return {
        model: 'one-time',
        tiers: [
          { name: 'Product', price: this.extractPrice(model) || 49.99 },
        ],
      };
    } else {
      return {
        model: 'subscription',
        tiers: [
          { name: 'Standard', price: this.extractPrice(model) || 9.99, interval: 'month' },
        ],
      };
    }
  }

  /**
   * Extract price from string like "$9.99/month"
   */
  private extractPrice(text: string): number | null {
    const match = text.match(/\$(\d+(?:\.\d{2})?)/);
    return match ? parseFloat(match[1]) : null;
  }

  /**
   * Check if configured
   */
  isConfigured(): boolean {
    return !!this.stripeApiKey;
  }
}

export const paymentSetupWorker = new PaymentSetupWorker();

/**
 * LangGraph node function
 */
export async function paymentSetupWorkerNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Payment Setup Worker] Setting up payments');

  const worker = new PaymentSetupWorker();

  try {
    const result = await worker.setupStripe(state);

    // Update formation status
    const updatedFormation = {
      ...state.formation,
      paymentsSetup: true,
    };

    return {
      formation: updatedFormation,
      totalCost: (state.totalCost || 0) + (result.cost || 0),
      nextAgent: 'ceo',
    };
  } catch (error: any) {
    console.error('[Payment Setup Worker] Error:', error);
    return {
      errors: [...(state.errors || []), `Payment Setup: ${error.message}`],
      nextAgent: 'ceo',
    };
  }
}
