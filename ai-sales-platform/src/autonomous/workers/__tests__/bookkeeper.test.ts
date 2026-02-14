import { describe, it, expect, beforeEach } from 'vitest';
import { BookkeeperWorker } from '../bookkeeper';
import { BusinessState, Task } from '../../types';

describe('BookkeeperWorker', () => {
  let bookkeeperWorker: BookkeeperWorker;
  let mockState: BusinessState;
  let mockTask: Task;

  beforeEach(() => {
    bookkeeperWorker = new BookkeeperWorker('gpt-4o-mini', 0.5);

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
      estimatedMonthlyCost: 700,
      formation: {
        validated: true,
        legalStructure: 'sole_proprietorship',
        incorporated: false,
        bankingSetup: false,
        paymentsSetup: true,
      },
    };

    mockTask = {
      id: 'task-1',
      type: 'setup_bookkeeping',
      description: 'Setup financial tracking',
      status: 'pending',
    };
  });

  describe('setupBookkeeping', () => {
    it('should setup bookkeeping system in simulation mode', async () => {
      const result = await bookkeeperWorker.setupBookkeeping(mockState, mockTask);

      expect(result.status).toBe('success');
      expect(result.mode).toBe('simulation');
      expect(result.platform).toMatch(/ramp_ai|quickbooks|spreadsheet/);
      expect(result.automationLevel).toBeDefined();
    });

    it('should use free option for early stage businesses', async () => {
      mockState.formation!.incorporated = false;

      const result = await bookkeeperWorker.setupBookkeeping(mockState, mockTask);

      // Early stage should use spreadsheet (free)
      expect(result.monthlyCost).toBeLessThanOrEqual(30);
    });

    it('should generate chart of accounts', async () => {
      const result = await bookkeeperWorker.setupBookkeeping(mockState, mockTask);

      expect(result.accountingSetup).toBeDefined();
      expect(result.accountingSetup.chartOfAccounts).toBeDefined();
      expect(result.accountingSetup.taxStrategy).toBeDefined();
    });

    it('should track revenue and expenses', async () => {
      const result = await bookkeeperWorker.setupBookkeeping(mockState, mockTask);

      expect(result.revenueTracking).toBeDefined();
      expect(result.expenseTracking).toBeDefined();
      expect(result.revenueTracking.sources).toBeDefined();
      expect(result.expenseTracking.categories).toBeDefined();
    });

    it('should include dashboard configuration', async () => {
      const result = await bookkeeperWorker.setupBookkeeping(mockState, mockTask);

      expect(result.dashboards).toBeDefined();
      expect(result.dashboards.metrics).toBeDefined();
    });

    it('should provide next steps', async () => {
      const result = await bookkeeperWorker.setupBookkeeping(mockState, mockTask);

      expect(result.nextSteps).toBeDefined();
      expect(Array.isArray(result.nextSteps)).toBe(true);
      expect(result.nextSteps.length).toBeGreaterThan(0);
    });
  });

  describe('generateReport', () => {
    it('should generate financial report', async () => {
      const startDate = new Date('2026-01-01');
      const endDate = new Date('2026-01-31');

      const result = await bookkeeperWorker.generateReport(startDate, endDate);

      expect(result.period).toBeDefined();
      expect(result.period.start).toBeDefined();
      expect(result.period.end).toBeDefined();
    });

    it('should include financial summary', async () => {
      const result = await bookkeeperWorker.generateReport(
        new Date('2026-01-01'),
        new Date('2026-01-31')
      );

      expect(result.summary).toBeDefined();
      expect(result.summary.totalRevenue).toBeDefined();
      expect(result.summary.totalExpenses).toBeDefined();
      expect(result.summary.netProfit).toBeDefined();
    });

    it('should calculate net profit correctly', async () => {
      const result = await bookkeeperWorker.generateReport(
        new Date('2026-01-01'),
        new Date('2026-01-31')
      );

      expect(result.summary.netProfit).toBe(
        result.summary.totalRevenue - result.summary.totalExpenses
      );
    });

    it('should include cash flow data', async () => {
      const result = await bookkeeperWorker.generateReport(
        new Date('2026-01-01'),
        new Date('2026-01-31')
      );

      expect(result.cashFlow).toBeDefined();
      expect(result.cashFlow.beginning).toBeDefined();
      expect(result.cashFlow.ending).toBeDefined();
      expect(result.cashFlow.change).toBe(
        result.cashFlow.ending - result.cashFlow.beginning
      );
    });
  });
});
