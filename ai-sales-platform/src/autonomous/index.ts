/**
 * Autonomous Business Platform - Main Entry Point
 *
 * This module exports the autonomous business orchestrator and provides
 * a simple API for launching and managing AI-powered businesses.
 */

export * from './types';
export * from './orchestrator';
export { ceoAgent } from './agents/ceo';
export { formationAdvisorAgent } from './agents/formation-advisor';
export { productManagerAgent } from './agents/product-manager';
export { marketingManagerAgent } from './agents/marketing-manager';
export { operationsManagerAgent } from './agents/operations-manager';
export { financeManagerAgent } from './agents/finance-manager';

/**
 * Quick start example:
 *
 * ```typescript
 * import { createOrchestrator } from './autonomous';
 *
 * const orchestrator = createOrchestrator(process.env.DATABASE_URL);
 *
 * const result = await orchestrator.launchBusiness({
 *   tenantId: 'user-123',
 *   idea: {
 *     description: 'AI-powered meal planning app for busy professionals',
 *     targetMarket: 'Urban professionals aged 25-45 with household income >$75K',
 *     problemSolved: 'Save time on meal planning and grocery shopping',
 *     monetizationModel: 'Freemium SaaS - $9.99/month for premium features'
 *   },
 *   businessName: 'MealMaster AI'
 * });
 *
 * console.log('Business launched!', result);
 * ```
 */
