import { describe, it, expect, beforeEach, vi } from 'vitest';
import { AdsWorker } from '../ads';
import { BusinessState, Task } from '../../types';

// The AI model is mocked globally in test/setup.ts, so the worker
// will fall back to its hardcoded fallback strategy (JSON parse will fail on '{}')

describe('AdsWorker', () => {
  let adsWorker: AdsWorker;
  let mockState: BusinessState;
  let mockTask: Task;

  beforeEach(() => {
    adsWorker = new AdsWorker('gpt-4o-mini', 0.7);

    mockState = {
      messages: [],
      tenantId: 'test-tenant',
      sessionId: 'test-session',
      idea: {
        description: 'AI-powered meal planning app',
        targetMarket: 'Busy professionals aged 25-45',
        problemSolved: 'Save 5+ hours per week on meal planning',
        monetizationModel: 'Freemium - $9.99/month premium',
      },
      currentPhase: 'marketing',
      completedTasks: [],
      pendingTasks: [],
      product: {
        specificationsDefined: true,
        mvpBuilt: true,
        deployed: true,
        productUrl: 'https://example.com',
      },
    };

    mockTask = {
      id: 'task-1',
      type: 'launch_ads',
      description: 'Launch ad campaigns',
      status: 'pending',
    };
  });

  describe('launchCampaigns', () => {
    it('should create ad campaigns in simulation mode', async () => {
      const result = await adsWorker.launchCampaigns(mockState, mockTask);

      expect(result.status).toBe('success');
      expect(result.mode).toBe('simulation');
      expect(result.strategy).toBeDefined();
      expect(result.campaigns).toBeDefined();
      expect(result.estimatedCost).toBeGreaterThan(0);
    });

    it('should have valid strategy with budget and channels', async () => {
      const result = await adsWorker.launchCampaigns(mockState, mockTask);

      expect(result.strategy.dailyBudget).toBeGreaterThan(0);
      expect(result.strategy.primaryChannel).toMatch(/meta|google|both/);
      expect(result.strategy.targetCAC).toBeGreaterThan(0);
    });

    it('should include campaign data', async () => {
      const result = await adsWorker.launchCampaigns(mockState, mockTask);

      // At least one of meta or google should be present
      const hasCampaign = result.campaigns.meta || result.campaigns.google;
      expect(hasCampaign).toBeTruthy();
    });

    it('should provide next steps for simulation mode', async () => {
      const result = await adsWorker.launchCampaigns(mockState, mockTask);

      expect(result.nextSteps).toBeDefined();
      expect(Array.isArray(result.nextSteps)).toBe(true);
      expect(result.nextSteps.length).toBeGreaterThan(0);
    });

    it('should calculate monthly cost as dailyBudget * 30', async () => {
      const result = await adsWorker.launchCampaigns(mockState, mockTask);

      expect(result.estimatedCost).toBe(result.strategy.dailyBudget * 30);
    });

    it('should include A/B test configurations', async () => {
      const result = await adsWorker.launchCampaigns(mockState, mockTask);

      expect(result.abTests).toBeDefined();
      expect(Array.isArray(result.abTests)).toBe(true);
    });
  });

  describe('optimizeCampaigns', () => {
    it('should return optimization results', async () => {
      const campaignIds = ['campaign1', 'campaign2'];
      const result = await adsWorker.optimizeCampaigns(campaignIds);

      expect(result.status).toBe('optimized');
      expect(result.actions).toBeDefined();
      expect(Array.isArray(result.actions)).toBe(true);
      expect(result.improvements).toBeDefined();
    });

    it('should include improvement metrics', async () => {
      const result = await adsWorker.optimizeCampaigns(['c1']);

      expect(result.improvements.ctrIncrease).toBeDefined();
      expect(result.improvements.cpcDecrease).toBeDefined();
      expect(result.improvements.conversionRateIncrease).toBeDefined();
    });
  });
});
