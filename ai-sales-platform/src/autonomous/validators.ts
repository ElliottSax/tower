/**
 * Validation utilities for autonomous business platform
 */

import { BusinessState, BusinessIdea, Task } from './types';

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Validate business idea completeness
 */
export function validateBusinessIdea(idea: BusinessIdea): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Required fields
  if (!idea.description || idea.description.trim().length < 10) {
    errors.push('Business description must be at least 10 characters');
  }

  if (!idea.targetMarket || idea.targetMarket.trim().length < 5) {
    errors.push('Target market must be specified');
  }

  if (!idea.problemSolved || idea.problemSolved.trim().length < 10) {
    errors.push('Problem solved must be clearly described');
  }

  // Warnings for optional fields
  if (!idea.monetizationModel) {
    warnings.push('No monetization model specified - will default to generic pricing');
  }

  // Check for clarity
  if (idea.description.length > 200) {
    warnings.push('Description is very long - consider simplifying');
  }

  // Check for vague terms
  const vagueTerms = ['app', 'platform', 'solution', 'system'];
  const hasVagueTerms = vagueTerms.some(term =>
    idea.description.toLowerCase().includes(term) &&
    idea.description.split(' ').length < 10
  );

  if (hasVagueTerms) {
    warnings.push('Description may be too vague - add more specific details');
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate business state consistency
 */
export function validateBusinessState(state: BusinessState): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check idea is present
  if (!state.idea) {
    errors.push('Business idea is missing');
  }

  // Check phase progression
  if (state.currentPhase === 'product' && !state.formation?.validated) {
    warnings.push('Product phase started before formation validation');
  }

  if (state.currentPhase === 'marketing' && !state.product?.specificationsDefined) {
    warnings.push('Marketing phase started before product specifications');
  }

  // Check cost tracking
  if (state.totalCost && state.totalCost < 0) {
    errors.push('Total cost cannot be negative');
  }

  if (state.totalCost && state.totalCost > 10000) {
    warnings.push(`High total cost: $${state.totalCost} - review for accuracy`);
  }

  // Check task consistency
  const completedTaskIds = new Set(state.completedTasks || []);
  const pendingTasks = state.pendingTasks || [];

  pendingTasks.forEach((task, index) => {
    // Check task has required fields
    if (!task.id) {
      errors.push(`Task at index ${index} missing ID`);
    }

    if (!task.type) {
      errors.push(`Task ${task.id} missing type`);
    }

    if (!task.description) {
      warnings.push(`Task ${task.id} missing description`);
    }

    // Check for duplicate IDs
    if (completedTaskIds.has(task.id)) {
      errors.push(`Task ${task.id} marked as both pending and completed`);
    }

    // Check dependencies
    if (task.dependencies) {
      task.dependencies.forEach(depId => {
        const depExists = pendingTasks.some(t => t.id === depId) ||
                         completedTaskIds.has(depId);
        if (!depExists) {
          warnings.push(`Task ${task.id} depends on non-existent task ${depId}`);
        }
      });
    }
  });

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate environment configuration
 */
export function validateEnvironment(): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check required environment variables
  if (!process.env.DATABASE_URL) {
    errors.push('DATABASE_URL not set - PostgreSQL required for checkpointing');
  }

  // Check AI providers
  const hasOpenAI = !!process.env.OPENAI_API_KEY;
  const hasAnthropic = !!process.env.ANTHROPIC_API_KEY;

  if (!hasOpenAI && !hasAnthropic) {
    warnings.push('No AI API key found - some features will be limited');
  }

  // Check optional but recommended
  const recommendedKeys = [
    'REDIS_URL',
    'STRIPE_SECRET_KEY',
  ];

  recommendedKeys.forEach(key => {
    if (!process.env[key]) {
      warnings.push(`${key} not set - some features may not work`);
    }
  });

  // Check Phase 2+ integration keys
  const phase2Keys = [
    'REPLIT_API_KEY',
    'VERCEL_TOKEN',
    'META_ACCESS_TOKEN',
  ];

  const missingPhase2 = phase2Keys.filter(key => !process.env[key]);
  if (missingPhase2.length > 0) {
    warnings.push(`Phase 2+ integrations not configured: ${missingPhase2.join(', ')}`);
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate task can be executed
 */
export function validateTask(task: Task, state: BusinessState): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check task status
  if (task.status === 'completed') {
    warnings.push('Task already completed');
  }

  if (task.status === 'failed') {
    warnings.push('Task previously failed');
  }

  // Check dependencies
  if (task.dependencies && task.dependencies.length > 0) {
    const completedTaskIds = new Set(state.completedTasks || []);
    const unmetDeps = task.dependencies.filter(depId => !completedTaskIds.has(depId));

    if (unmetDeps.length > 0) {
      errors.push(`Task has unmet dependencies: ${unmetDeps.join(', ')}`);
    }
  }

  // Check assignment
  if (!task.assignedTo) {
    warnings.push('Task not assigned to any agent');
  }

  // Check estimated cost
  if (task.estimatedCost && task.estimatedCost > 1000) {
    warnings.push(`High cost task: $${task.estimatedCost} - may require human approval`);
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Estimate launch cost based on business idea
 */
export function estimateLaunchCost(idea: BusinessIdea): {
  oneTime: number;
  monthly: number;
  breakdown: Record<string, number>;
} {
  const breakdown: Record<string, number> = {};

  // Base costs
  breakdown['MVP Development'] = 500;
  breakdown['Initial Marketing'] = 500;

  // Check if incorporation needed (heuristic)
  const description = idea.description.toLowerCase();
  const needsIncorporation =
    description.includes('physical') ||
    description.includes('hardware') ||
    description.includes('vc') ||
    description.includes('venture');

  if (needsIncorporation) {
    breakdown['Incorporation (LLC)'] = 399;
  }

  // Calculate totals
  const oneTime = Object.values(breakdown).reduce((sum, cost) => sum + cost, 0);

  // Monthly costs
  const monthly = 700; // Base operating cost

  return {
    oneTime,
    monthly,
    breakdown,
  };
}

/**
 * Check if business state is ready for next phase
 */
export function canProgressToPhase(
  currentPhase: BusinessState['currentPhase'],
  state: BusinessState
): { canProgress: boolean; reason?: string } {
  switch (currentPhase) {
    case 'validation':
      if (!state.formation?.validated) {
        return { canProgress: false, reason: 'Idea not validated' };
      }
      return { canProgress: true };

    case 'formation':
      if (!state.formation?.paymentsSetup) {
        return { canProgress: false, reason: 'Payments not configured' };
      }
      return { canProgress: true };

    case 'product':
      if (!state.product?.deployed) {
        return { canProgress: false, reason: 'MVP not deployed' };
      }
      return { canProgress: true };

    case 'marketing':
      if (!state.marketing?.strategyDefined) {
        return { canProgress: false, reason: 'Marketing strategy not defined' };
      }
      return { canProgress: true };

    case 'operations':
      if (!state.operations?.supportSetup) {
        return { canProgress: false, reason: 'Support not configured' };
      }
      return { canProgress: true };

    case 'optimization':
      return { canProgress: true };

    case 'completed':
      return { canProgress: false, reason: 'Already completed' };

    default:
      return { canProgress: false, reason: 'Unknown phase' };
  }
}

/**
 * Get health check for business state
 */
export function getBusinessHealth(state: BusinessState): {
  score: number; // 0-100
  status: 'healthy' | 'warning' | 'critical';
  issues: string[];
  recommendations: string[];
} {
  let score = 100;
  const issues: string[] = [];
  const recommendations: string[] = [];

  // Check error count
  if (state.errors && state.errors.length > 0) {
    score -= state.errors.length * 10;
    issues.push(`${state.errors.length} errors encountered`);
    recommendations.push('Review and resolve errors before proceeding');
  }

  // Check cost overruns
  if (state.totalCost && state.totalCost > 5000) {
    score -= 20;
    issues.push('Costs exceeding budget');
    recommendations.push('Review expenses and consider optimizations');
  }

  // Check stuck tasks
  const pendingCount = state.pendingTasks?.length || 0;
  const completedCount = state.completedTasks?.length || 0;

  if (pendingCount > completedCount * 2) {
    score -= 15;
    issues.push('Many tasks pending relative to completed');
    recommendations.push('Check for blocked tasks or dependencies');
  }

  // Check phase completion
  const phaseProgress = getPhaseProgress(state);
  if (phaseProgress < 50) {
    score -= 10;
    issues.push('Phase progress below 50%');
  }

  // Determine status
  let status: 'healthy' | 'warning' | 'critical';
  if (score >= 80) {
    status = 'healthy';
  } else if (score >= 60) {
    status = 'warning';
  } else {
    status = 'critical';
  }

  return {
    score: Math.max(0, Math.min(100, score)),
    status,
    issues,
    recommendations,
  };
}

/**
 * Get progress percentage for current phase
 */
export function getPhaseProgress(state: BusinessState): number {
  switch (state.currentPhase) {
    case 'validation':
      return state.formation?.validated ? 100 : 50;

    case 'formation':
      let formationProgress = 0;
      if (state.formation?.validated) formationProgress += 25;
      if (state.formation?.paymentsSetup) formationProgress += 50;
      if (state.formation?.bankingSetup) formationProgress += 25;
      return formationProgress;

    case 'product':
      let productProgress = 0;
      if (state.product?.specificationsDefined) productProgress += 33;
      if (state.product?.mvpBuilt) productProgress += 33;
      if (state.product?.deployed) productProgress += 34;
      return productProgress;

    case 'marketing':
      let marketingProgress = 0;
      if (state.marketing?.strategyDefined) marketingProgress += 25;
      if (state.marketing?.contentCreated) marketingProgress += 25;
      if (state.marketing?.adsLaunched) marketingProgress += 25;
      if (state.marketing?.seoOptimized) marketingProgress += 25;
      return marketingProgress;

    case 'operations':
      let opsProgress = 0;
      if (state.operations?.supportSetup) opsProgress += 33;
      if (state.operations?.analyticsSetup) opsProgress += 33;
      if (state.operations?.monitoringSetup) opsProgress += 34;
      return opsProgress;

    case 'optimization':
      return 75; // Ongoing

    case 'completed':
      return 100;

    default:
      return 0;
  }
}
