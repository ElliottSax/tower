import { describe, it, expect, beforeEach } from 'vitest';
import { SupportWorker } from '../support';
import { BusinessState, Task } from '../../types';

describe('SupportWorker', () => {
  let supportWorker: SupportWorker;
  let mockState: BusinessState;
  let mockTask: Task;

  beforeEach(() => {
    supportWorker = new SupportWorker('gpt-4o-mini', 0.7);

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
      currentPhase: 'operations',
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
      type: 'setup_support',
      description: 'Setup customer support',
      status: 'pending',
    };
  });

  describe('setupSupport', () => {
    it('should setup support system in simulation mode', async () => {
      const result = await supportWorker.setupSupport(mockState, mockTask);

      expect(result.status).toBe('success');
      expect(result.mode).toBe('simulation');
      expect(result.platform).toMatch(/fin_ai|chatwoot/);
      expect(result.automationRate).toBeGreaterThan(0);
      expect(result.knowledgeBase).toBeDefined();
    });

    it('should generate knowledge base articles', async () => {
      const result = await supportWorker.setupSupport(mockState, mockTask);

      expect(result.knowledgeBase.status).toBeDefined();
      expect(result.knowledgeBase.articleCount).toBeGreaterThan(0);
    });

    it('should provide chatbot configuration', async () => {
      const result = await supportWorker.setupSupport(mockState, mockTask);

      expect(result.chatbot).toBeDefined();
      expect(result.chatbot.status).toBe('configured');
      expect(result.chatbot.intents).toBeGreaterThan(0);
    });

    it('should have reasonable monthly cost', async () => {
      const result = await supportWorker.setupSupport(mockState, mockTask);

      expect(result.monthlyCost).toBeGreaterThanOrEqual(0);
      expect(result.monthlyCost).toBeLessThan(500);
    });

    it('should include next steps', async () => {
      const result = await supportWorker.setupSupport(mockState, mockTask);

      expect(result.nextSteps).toBeDefined();
      expect(Array.isArray(result.nextSteps)).toBe(true);
      expect(result.nextSteps.length).toBeGreaterThan(0);
    });

    it('should include platform setup details', async () => {
      const result = await supportWorker.setupSupport(mockState, mockTask);

      expect(result.platformSetup).toBeDefined();
      expect(result.platformSetup.status).toBeDefined();
    });
  });

  describe('getMetrics', () => {
    it('should return support metrics', async () => {
      const result = await supportWorker.getMetrics();

      expect(result.automationRate).toBeDefined();
      expect(result.avgResponseTime).toBeDefined();
      expect(result.satisfactionScore).toBeDefined();
      expect(result.ticketVolume).toBeDefined();
    });

    it('should return realistic metric values', async () => {
      const result = await supportWorker.getMetrics();

      expect(result.automationRate).toBeGreaterThan(0);
      expect(result.automationRate).toBeLessThanOrEqual(100);
      expect(result.satisfactionScore).toBeGreaterThan(0);
      expect(result.satisfactionScore).toBeLessThanOrEqual(5);
    });
  });
});
