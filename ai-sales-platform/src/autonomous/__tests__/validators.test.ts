import { describe, it, expect } from 'vitest';
import {
  BusinessState,
  BusinessIdea,
  Task,
} from '../types';

describe('BusinessState types', () => {
  const mockIdea: BusinessIdea = {
    description: 'AI-powered meal planning app',
    targetMarket: 'Busy professionals aged 25-45',
    problemSolved: 'Save 5+ hours per week on meal planning',
    monetizationModel: 'Freemium - $9.99/month premium',
  };

  it('should create a valid BusinessIdea', () => {
    expect(mockIdea.description).toBeDefined();
    expect(mockIdea.targetMarket).toBeDefined();
    expect(mockIdea.problemSolved).toBeDefined();
  });

  it('should create a valid BusinessState', () => {
    const state: BusinessState = {
      messages: [],
      tenantId: 'tenant-1',
      sessionId: 'session-1',
      idea: mockIdea,
      currentPhase: 'validation',
      completedTasks: [],
      pendingTasks: [],
    };

    expect(state.tenantId).toBe('tenant-1');
    expect(state.currentPhase).toBe('validation');
    expect(state.completedTasks).toHaveLength(0);
  });

  it('should track formation status', () => {
    const state: BusinessState = {
      messages: [],
      tenantId: 'tenant-1',
      sessionId: 'session-1',
      idea: mockIdea,
      currentPhase: 'formation',
      completedTasks: [],
      pendingTasks: [],
      formation: {
        validated: true,
        legalStructure: 'sole_proprietorship',
        incorporated: false,
        bankingSetup: false,
        paymentsSetup: false,
      },
    };

    expect(state.formation?.validated).toBe(true);
    expect(state.formation?.legalStructure).toBe('sole_proprietorship');
    expect(state.formation?.incorporated).toBe(false);
  });

  it('should track product status', () => {
    const state: BusinessState = {
      messages: [],
      tenantId: 'tenant-1',
      sessionId: 'session-1',
      idea: mockIdea,
      currentPhase: 'product',
      completedTasks: [],
      pendingTasks: [],
      product: {
        specificationsDefined: true,
        mvpBuilt: false,
        deployed: false,
      },
    };

    expect(state.product?.specificationsDefined).toBe(true);
    expect(state.product?.mvpBuilt).toBe(false);
  });

  it('should track cost information', () => {
    const state: BusinessState = {
      messages: [],
      tenantId: 'tenant-1',
      sessionId: 'session-1',
      idea: mockIdea,
      currentPhase: 'marketing',
      completedTasks: [],
      pendingTasks: [],
      totalCost: 1020,
      estimatedMonthlyCost: 700,
    };

    expect(state.totalCost).toBe(1020);
    expect(state.estimatedMonthlyCost).toBe(700);
  });

  it('should support task management', () => {
    const task: Task = {
      id: 'task-1',
      type: 'generate_code',
      description: 'Build MVP',
      assignedTo: 'developer_worker',
      status: 'pending',
      estimatedCost: 500,
    };

    expect(task.id).toBe('task-1');
    expect(task.type).toBe('generate_code');
    expect(task.assignedTo).toBe('developer_worker');
    expect(task.status).toBe('pending');
  });

  it('should track all business phases', () => {
    const phases = [
      'validation', 'formation', 'product',
      'marketing', 'operations', 'optimization', 'completed',
    ];

    phases.forEach(phase => {
      const state: BusinessState = {
        messages: [],
        tenantId: 'tenant-1',
        sessionId: 'session-1',
        idea: mockIdea,
        currentPhase: phase as any,
        completedTasks: [],
        pendingTasks: [],
      };
      expect(state.currentPhase).toBe(phase);
    });
  });

  it('should track errors', () => {
    const state: BusinessState = {
      messages: [],
      tenantId: 'tenant-1',
      sessionId: 'session-1',
      idea: mockIdea,
      currentPhase: 'validation',
      completedTasks: [],
      pendingTasks: [],
      errors: ['Error 1', 'Error 2'],
    };

    expect(state.errors).toHaveLength(2);
    expect(state.errors?.[0]).toBe('Error 1');
  });
});
