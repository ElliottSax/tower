import { describe, it, expect, beforeEach } from 'vitest';
import { DeveloperWorker } from '../developer';
import { BusinessState } from '../../types';

describe('DeveloperWorker', () => {
  let worker: DeveloperWorker;
  let mockState: BusinessState;

  beforeEach(() => {
    worker = new DeveloperWorker();

    mockState = {
      messages: [],
      tenantId: 'test-tenant',
      sessionId: 'test-session',
      idea: {
        description: 'AI-powered meal planning app with search and auth',
        targetMarket: 'Busy professionals',
        problemSolved: 'Save time on meal planning',
        monetizationModel: 'Freemium - $9.99/month',
      },
      currentPhase: 'product',
      completedTasks: [],
      pendingTasks: [],
      businessName: 'MealMaster AI',
    };
  });

  describe('generateCode', () => {
    it('should simulate code generation without API key', async () => {
      const result = await worker.generateCode(
        'Build a meal planning app with auth and database',
        'MealMaster AI'
      );

      expect(result.status).toBe('simulated');
      expect(result.repositoryUrl).toBeDefined();
      expect(result.deploymentUrl).toBeDefined();
      expect(result.techStack).toBeDefined();
    });

    it('should extract features from specifications', async () => {
      const result = await worker.generateCode(
        'Build an app with auth, payment, dashboard, and search functionality',
        'Test App'
      );

      expect(result.features).toBeDefined();
      expect(Array.isArray(result.features)).toBe(true);
      expect(result.features.length).toBeGreaterThan(0);
    });

    it('should sanitize project name for URLs', async () => {
      const result = await worker.generateCode(
        'Build something',
        'My Cool App 2026!!'
      );

      expect(result.repositoryUrl).not.toContain(' ');
      expect(result.deploymentUrl).not.toContain(' ');
    });

    it('should set cost to 0 in simulation mode', async () => {
      const result = await worker.generateCode('Build an app', 'TestApp');

      expect(result.cost).toBe(0);
    });
  });

  describe('deployToVercel', () => {
    it('should simulate deployment without API key', async () => {
      const result = await worker.deployToVercel(
        'https://github.com/user/repo',
        'MealMaster AI'
      );

      expect(result.status).toBe('simulated');
      expect(result.deploymentUrl).toBeDefined();
      expect(result.cost).toBe(0);
    });
  });

  describe('setupInfrastructure', () => {
    it('should return infrastructure configuration', async () => {
      const result = await worker.setupInfrastructure('MealMaster AI');

      expect(result.status).toBe('success');
      expect(result.services).toBeDefined();
      expect(result.services.database).toBeDefined();
      expect(result.cost).toBe(0);
    });
  });

  describe('isConfigured', () => {
    it('should return false without API keys', () => {
      expect(worker.isConfigured()).toBe(false);
    });
  });
});
