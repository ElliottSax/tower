import { StateGraph, END } from '@langchain/langgraph';
import { PostgresSaver } from '@langchain/langgraph-checkpoint-postgres';
import { Pool } from 'pg';
import { BaseMessage } from '@langchain/core/messages';
import { BusinessState, AgentType, BusinessPhase } from './types';
import { ceoAgentNode } from './agents/ceo';
import { formationAdvisorNode } from './agents/formation-advisor';
import { productManagerNode } from './agents/product-manager';
import { marketingManagerNode } from './agents/marketing-manager';
import { operationsManagerNode } from './agents/operations-manager';
import { financeManagerNode } from './agents/finance-manager';
import { developerWorkerNode } from './workers/developer';
import { paymentSetupWorkerNode } from './workers/payment-setup';
import { contentWorkerNode } from './workers/content';
import { adsWorker } from './workers/ads';
import { supportWorker } from './workers/support';
import { bookkeeperWorker } from './workers/bookkeeper';

/**
 * Autonomous Business Platform Orchestrator
 *
 * Multi-agent system with hierarchical architecture:
 * CEO → Managers (Product, Marketing, Operations, Finance) → Workers
 *
 * Features:
 * - PostgreSQL checkpointing (survives crashes)
 * - Time-travel debugging
 * - Human-in-the-loop at critical decisions
 * - Cost tracking and limits
 */

export class AutonomousBusinessOrchestrator {
  private graph: StateGraph<BusinessState>;
  private checkpointer: PostgresSaver;
  private pool: Pool;

  constructor(databaseUrl: string) {
    this.pool = new Pool({ connectionString: databaseUrl });
    this.checkpointer = new PostgresSaver(this.pool);
    this.graph = this.buildGraph();
  }

  /**
   * Build the LangGraph workflow with all agents
   */
  private buildGraph(): StateGraph<BusinessState> {
    const workflow = new StateGraph<BusinessState>({
      channels: {
        messages: {
          value: (left: BaseMessage[], right: BaseMessage[]) => left.concat(right),
          default: () => [],
        },
        tenantId: null,
        sessionId: null,
        idea: null,
        businessName: null,
        formation: null,
        product: null,
        marketing: null,
        operations: null,
        finance: null,
        currentPhase: null,
        nextAgent: null,
        completedTasks: {
          value: (left: string[], right: string[]) => left.concat(right),
          default: () => [],
        },
        pendingTasks: {
          value: (left: any[], right: any[]) => {
            // Merge tasks, preferring right (newer) status if IDs match
            const taskMap = new Map();
            [...left, ...right].forEach(task => {
              taskMap.set(task.id, task);
            });
            return Array.from(taskMap.values());
          },
          default: () => [],
        },
        errors: {
          value: (left: string[], right: string[]) => left.concat(right),
          default: () => [],
        },
        totalCost: {
          value: (left: number, right: number) => (left || 0) + (right || 0),
          default: () => 0,
        },
        estimatedMonthlyCost: {
          value: (_left: number, right: number) => right, // Use latest estimate
          default: () => 700,
        },
      },
    });

    // ===== Add all agent nodes =====

    // Strategic layer
    workflow.addNode('ceo', ceoAgentNode);
    workflow.addNode('formation_advisor', formationAdvisorNode);

    // Manager layer
    workflow.addNode('product_manager', productManagerNode);
    workflow.addNode('marketing_manager', marketingManagerNode);
    workflow.addNode('operations_manager', operationsManagerNode);
    workflow.addNode('finance_manager', financeManagerNode);

    // Worker layer (all real implementations!)
    workflow.addNode('developer_worker', developerWorkerNode);
    workflow.addNode('payment_setup_worker', paymentSetupWorkerNode);
    workflow.addNode('content_worker', contentWorkerNode);
    workflow.addNode('ads_worker', this.createAdsWorkerNode());
    workflow.addNode('support_worker', this.createSupportWorkerNode());
    workflow.addNode('bookkeeper_worker', this.createBookkeeperWorkerNode());

    // ===== Define routing logic =====

    // CEO routes to managers, formation advisor, or END
    workflow.addConditionalEdges(
      'ceo',
      (state: BusinessState) => state.nextAgent || 'END',
      {
        formation_advisor: 'formation_advisor',
        product_manager: 'product_manager',
        marketing_manager: 'marketing_manager',
        operations_manager: 'operations_manager',
        finance_manager: 'finance_manager',
        human: END, // Human intervention pauses the workflow
        END: END,
      }
    );

    // Formation advisor reports back to CEO
    workflow.addEdge('formation_advisor', 'ceo');

    // Managers route to workers or back to CEO
    const managerEdges = {
      developer_worker: 'developer_worker',
      payment_setup_worker: 'payment_setup_worker',
      content_worker: 'content_worker',
      ads_worker: 'ads_worker',
      support_worker: 'support_worker',
      bookkeeper_worker: 'bookkeeper_worker',
      ceo: 'ceo',
      END: END,
    };

    workflow.addConditionalEdges('product_manager', (state) => state.nextAgent || 'ceo', managerEdges);
    workflow.addConditionalEdges('marketing_manager', (state) => state.nextAgent || 'ceo', managerEdges);
    workflow.addConditionalEdges('operations_manager', (state) => state.nextAgent || 'ceo', managerEdges);
    workflow.addConditionalEdges('finance_manager', (state) => state.nextAgent || 'ceo', managerEdges);

    // Workers report back (some to managers, some to CEO)
    workflow.addEdge('developer_worker', 'product_manager');
    workflow.addEdge('payment_setup_worker', 'ceo'); // Payment setup reports to CEO
    workflow.addEdge('content_worker', 'marketing_manager');
    workflow.addEdge('ads_worker', 'marketing_manager');
    workflow.addEdge('support_worker', 'operations_manager');
    workflow.addEdge('bookkeeper_worker', 'finance_manager');

    // Set entry point
    workflow.setEntryPoint('ceo');

    return workflow;
  }

  /**
   * Create Ads Worker node (Meta + Google Ads)
   */
  private createAdsWorkerNode() {
    return async (state: BusinessState): Promise<Partial<BusinessState>> => {
      const relevantTasks = state.pendingTasks?.filter(
        task => task.assignedTo === 'ads_worker' && task.status === 'pending'
      ) || [];

      if (relevantTasks.length === 0) {
        return { nextAgent: 'marketing_manager' };
      }

      const task = relevantTasks[0];

      try {
        const result = await adsWorker.launchCampaigns(state, task);

        const updatedTasks = state.pendingTasks?.map(t =>
          t.id === task.id
            ? { ...t, status: 'completed' as const, result }
            : t
        ) || [];

        return {
          pendingTasks: updatedTasks,
          completedTasks: [...(state.completedTasks || []), task.id],
          totalCost: (state.totalCost || 0) + (result.estimatedCost || 0),
          marketing: {
            ...state.marketing,
            adsLaunched: true,
          },
          nextAgent: 'marketing_manager',
        };
      } catch (error: any) {
        console.error('[Ads Worker] Error:', error);
        return {
          errors: [...(state.errors || []), `Ads Worker error: ${error.message}`],
          nextAgent: 'marketing_manager',
        };
      }
    };
  }

  /**
   * Create Support Worker node (Fin AI / Chatwoot)
   */
  private createSupportWorkerNode() {
    return async (state: BusinessState): Promise<Partial<BusinessState>> => {
      const relevantTasks = state.pendingTasks?.filter(
        task => task.assignedTo === 'support_worker' && task.status === 'pending'
      ) || [];

      if (relevantTasks.length === 0) {
        return { nextAgent: 'operations_manager' };
      }

      const task = relevantTasks[0];

      try {
        const result = await supportWorker.setupSupport(state, task);

        const updatedTasks = state.pendingTasks?.map(t =>
          t.id === task.id
            ? { ...t, status: 'completed' as const, result }
            : t
        ) || [];

        return {
          pendingTasks: updatedTasks,
          completedTasks: [...(state.completedTasks || []), task.id],
          totalCost: (state.totalCost || 0) + (result.monthlyCost || 0),
          operations: {
            ...state.operations,
            supportSetup: true,
          },
          nextAgent: 'operations_manager',
        };
      } catch (error: any) {
        console.error('[Support Worker] Error:', error);
        return {
          errors: [...(state.errors || []), `Support Worker error: ${error.message}`],
          nextAgent: 'operations_manager',
        };
      }
    };
  }

  /**
   * Create Bookkeeper Worker node (Ramp AI)
   */
  private createBookkeeperWorkerNode() {
    return async (state: BusinessState): Promise<Partial<BusinessState>> => {
      const relevantTasks = state.pendingTasks?.filter(
        task => task.assignedTo === 'bookkeeper_worker' && task.status === 'pending'
      ) || [];

      if (relevantTasks.length === 0) {
        return { nextAgent: 'finance_manager' };
      }

      const task = relevantTasks[0];

      try {
        const result = await bookkeeperWorker.setupBookkeeping(state, task);

        const updatedTasks = state.pendingTasks?.map(t =>
          t.id === task.id
            ? { ...t, status: 'completed' as const, result }
            : t
        ) || [];

        return {
          pendingTasks: updatedTasks,
          completedTasks: [...(state.completedTasks || []), task.id],
          totalCost: (state.totalCost || 0) + (result.monthlyCost || 0),
          finance: {
            ...state.finance,
            bookkeepingSetup: true,
          },
          nextAgent: 'finance_manager',
        };
      } catch (error: any) {
        console.error('[Bookkeeper Worker] Error:', error);
        return {
          errors: [...(state.errors || []), `Bookkeeper Worker error: ${error.message}`],
          nextAgent: 'finance_manager',
        };
      }
    };
  }

  /**
   * Launch a new business from idea to operation
   */
  async launchBusiness(input: {
    tenantId: string;
    idea: BusinessState['idea'];
    businessName?: string;
  }): Promise<BusinessState> {
    const sessionId = crypto.randomUUID();

    console.log(`\n${'='.repeat(60)}`);
    console.log(`🚀 Launching Autonomous Business Platform`);
    console.log(`Session ID: ${sessionId}`);
    console.log(`Idea: ${input.idea.description}`);
    console.log(`${'='.repeat(60)}\n`);

    const initialState: BusinessState = {
      messages: [],
      tenantId: input.tenantId,
      sessionId,
      idea: input.idea,
      businessName: input.businessName,
      currentPhase: 'validation',
      completedTasks: [],
      pendingTasks: [],
      estimatedMonthlyCost: 700,
      totalCost: 0,
    };

    try {
      // Compile graph with PostgreSQL checkpointing
      const app = this.graph.compile({ checkpointer: this.checkpointer });

      // Execute workflow with checkpointing
      const config = {
        configurable: {
          thread_id: sessionId,
        },
      };

      const result = await app.invoke(initialState, config);

      console.log(`\n${'='.repeat(60)}`);
      console.log(`✅ Business Launch Workflow Completed`);
      console.log(`Phase: ${result.currentPhase}`);
      console.log(`Completed Tasks: ${result.completedTasks?.length || 0}`);
      console.log(`Total Cost: $${result.totalCost || 0}`);
      console.log(`${'='.repeat(60)}\n`);

      return result as BusinessState;
    } catch (error: any) {
      console.error('Orchestrator error:', error);
      return {
        ...initialState,
        errors: [`Orchestration error: ${error.message}`],
        nextAgent: 'END',
      };
    }
  }

  /**
   * Resume a paused workflow (e.g., after human approval)
   */
  async resumeWorkflow(sessionId: string, humanDecision?: any): Promise<BusinessState> {
    console.log(`\n📋 Resuming workflow: ${sessionId}`);

    try {
      const app = this.graph.compile({ checkpointer: this.checkpointer });

      const config = {
        configurable: {
          thread_id: sessionId,
        },
      };

      // Get current state from checkpoint
      const state = await app.getState(config);

      if (!state) {
        throw new Error(`No checkpoint found for session: ${sessionId}`);
      }

      // Add human decision to state if provided
      const updates: Partial<BusinessState> = {};
      if (humanDecision) {
        updates.messages = [...(state.values.messages || [])];
        updates.nextAgent = 'ceo'; // Resume from CEO
      }

      // Resume execution
      const result = await app.invoke(updates, config);

      console.log(`✅ Workflow resumed successfully`);

      return result as BusinessState;
    } catch (error) {
      console.error('Resume error:', error);
      throw error;
    }
  }

  /**
   * Get current state of a business workflow
   */
  async getBusinessState(sessionId: string): Promise<BusinessState | null> {
    try {
      const app = this.graph.compile({ checkpointer: this.checkpointer });

      const config = {
        configurable: {
          thread_id: sessionId,
        },
      };

      const state = await app.getState(config);

      return state ? (state.values as BusinessState) : null;
    } catch (error) {
      console.error('Get state error:', error);
      return null;
    }
  }

  /**
   * Close database connections
   */
  async shutdown(): Promise<void> {
    await this.pool.end();
  }
}

/**
 * Create and export singleton instance
 */
export function createOrchestrator(databaseUrl: string): AutonomousBusinessOrchestrator {
  return new AutonomousBusinessOrchestrator(databaseUrl);
}
