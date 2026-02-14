import { describe, it, expect, beforeEach } from 'vitest';
import { PaymentSetupWorker } from '../payment-setup';
import { BusinessState } from '../../types';

describe('PaymentSetupWorker', () => {
  let worker: PaymentSetupWorker;
  let mockState: BusinessState;

  beforeEach(() => {
    worker = new PaymentSetupWorker();

    mockState = {
      messages: [],
      tenantId: 'test-tenant',
      sessionId: 'test-session',
      idea: {
        description: 'AI-powered meal planning app',
        targetMarket: 'Busy professionals',
        problemSolved: 'Save time on meal planning',
        monetizationModel: 'Freemium - $9.99/month premium',
      },
      currentPhase: 'formation',
      completedTasks: [],
      pendingTasks: [],
      businessName: 'MealMaster AI',
      formation: {
        validated: true,
        legalStructure: 'sole_proprietorship',
        incorporated: false,
        bankingSetup: false,
        paymentsSetup: false,
      },
    };
  });

  describe('setupStripe', () => {
    it('should simulate Stripe setup without API key', async () => {
      const result = await worker.setupStripe(mockState);

      expect(result.status).toBe('simulated');
      expect(result.setupInstructions).toBeDefined();
      expect(Array.isArray(result.setupInstructions)).toBe(true);
    });

    it('should determine account type from legal structure', async () => {
      const result = await worker.setupStripe(mockState);

      expect(result.accountType).toBe('Individual');
    });

    it('should use Company type for LLC', async () => {
      mockState.formation!.legalStructure = 'llc';

      const result = await worker.setupStripe(mockState);

      expect(result.accountType).toBe('Company');
    });

    it('should provide setup steps', async () => {
      const result = await worker.setupStripe(mockState);

      expect(result.setupInstructions.length).toBeGreaterThan(0);
      result.setupInstructions.forEach((step: any) => {
        expect(step.step).toBeDefined();
        expect(step.action).toBeDefined();
      });
    });

    it('should include payment features info', async () => {
      const result = await worker.setupStripe(mockState);

      expect(result.features).toBeDefined();
      expect(result.features.paymentMethods).toBeDefined();
      expect(result.features.pricing).toBeDefined();
    });

    it('should set cost to 0', async () => {
      const result = await worker.setupStripe(mockState);

      expect(result.cost).toBe(0);
    });
  });

  describe('setupPricing', () => {
    it('should parse freemium pricing', async () => {
      const result = await worker.setupPricing('Freemium - $9.99/month premium');

      expect(result.pricingModel).toBe('freemium');
      expect(result.tiers.length).toBe(2);
      expect(result.tiers[0].price).toBe(0);
      expect(result.tiers[1].price).toBe(9.99);
    });

    it('should parse subscription pricing', async () => {
      const result = await worker.setupPricing('Subscription $19.99/month');

      expect(result.pricingModel).toBe('subscription');
    });

    it('should handle unknown pricing models', async () => {
      const result = await worker.setupPricing('Custom pricing model');

      expect(result.pricingModel).toBeDefined();
      expect(result.tiers.length).toBeGreaterThan(0);
    });
  });

  describe('isConfigured', () => {
    it('should return false without API key', () => {
      expect(worker.isConfigured()).toBe(false);
    });
  });
});
