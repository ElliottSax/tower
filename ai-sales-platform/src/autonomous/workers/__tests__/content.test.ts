import { describe, it, expect, beforeEach } from 'vitest';
import { ContentWorker } from '../content';
import { BusinessState } from '../../types';

describe('ContentWorker', () => {
  let worker: ContentWorker;
  let mockState: BusinessState;

  beforeEach(() => {
    worker = new ContentWorker('gpt-4o-mini', 0.7);

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
      businessName: 'MealMaster AI',
    };
  });

  describe('generateLandingPage', () => {
    it('should generate landing page content', async () => {
      const result = await worker.generateLandingPage(mockState);

      expect(result.status).toBeDefined();
      expect(result.content).toBeDefined();
    });

    it('should include landing page structure', async () => {
      const result = await worker.generateLandingPage(mockState);

      expect(result.content.landingPage).toBeDefined();
    });

    it('should track cost', async () => {
      const result = await worker.generateLandingPage(mockState);

      expect(result.cost).toBeDefined();
      expect(typeof result.cost).toBe('number');
    });
  });

  describe('generateBlogPosts', () => {
    it('should generate requested number of blog posts', async () => {
      const count = 3;
      const result = await worker.generateBlogPosts(mockState, count);

      expect(result.status).toBeDefined();
      expect(result.posts).toBeDefined();
      expect(Array.isArray(result.posts)).toBe(true);
    });

    it('should include post outlines', async () => {
      const result = await worker.generateBlogPosts(mockState, 2);

      expect(result.posts.length).toBeGreaterThan(0);
      result.posts.forEach((post: any) => {
        expect(post.title).toBeDefined();
      });
    });

    it('should default to 3 posts', async () => {
      const result = await worker.generateBlogPosts(mockState);

      expect(result.posts.length).toBe(3);
    });
  });
});
