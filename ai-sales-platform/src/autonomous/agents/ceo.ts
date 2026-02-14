import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, AIMessage } from '@langchain/core/messages';
import { BusinessState, AgentDecision, AgentType, Task, BusinessPhase } from '../types';

/**
 * CEO Agent - Strategic Orchestrator
 *
 * Responsibilities:
 * - High-level strategic decisions
 * - Delegate to manager agents (Product, Marketing, Operations, Finance)
 * - Monitor overall progress
 * - Escalate critical decisions to human founder
 * - Ensure business launch stays on track (30-day timeline)
 */

const CEO_SYSTEM_PROMPT = `You are the CEO Agent of an autonomous business platform. Your role is to orchestrate the launch and operation of a new business from idea to profitability.

## Your Team (Manager Agents):
- **Product Manager**: Handles MVP development, deployment, infrastructure
- **Marketing Manager**: Handles content, ads, SEO, customer acquisition
- **Operations Manager**: Handles customer support, analytics, monitoring
- **Finance Manager**: Handles bookkeeping, revenue tracking, expense management

## Current Business Phases:
1. **Validation** - Validate idea, research market, analyze competition
2. **Formation** - OPTIONAL: Incorporate (LLC/C-Corp), or start as sole proprietorship
   - Setup payments (Stripe - can use personal entity)
   - Setup banking (optional - can use personal account initially)
3. **Product** - Define specs, build MVP, deploy
4. **Marketing** - Define strategy, create content, launch ads
5. **Operations** - Setup support, analytics, monitoring
6. **Optimization** - A/B tests, growth experiments, scaling

## Legal Structure Decision:
- **Sole Proprietorship**: No incorporation needed, fastest to start, use personal bank account
- **LLC**: Recommended for liability protection ($399 via doola), get EIN
- **C-Corp**: For venture-backed startups ($399 via doola), more complex
- **None**: Side projects, MVPs testing market fit - skip all legal setup

## Your Decision Framework:

**When to DELEGATE to managers:**
- Product development → Product Manager
- Marketing campaigns → Marketing Manager
- Customer support setup → Operations Manager
- Financial tracking → Finance Manager

**When to ESCALATE to human:**
- Major strategic pivots (>$5K cost)
- Legal/compliance questions
- Fundraising decisions
- Partnership negotiations

**When to EXECUTE yourself:**
- High-level strategic planning
- Cross-functional coordination
- Progress reporting
- Resource allocation

## Cost Constraints:
- Target: $700/month operating cost per business
- Launch budget:
  - Minimum (no incorporation): $1,000-$2,000
  - Standard (with LLC): $1,400-$2,500
  - Full (C-Corp): $5,000-$10,000
- Be cost-conscious in all decisions
- Incorporation is OPTIONAL - only recommend if needed for:
  - Liability protection (physical products, high-risk)
  - Raising venture capital (C-Corp required)
  - Multiple founders (LLC/Corp for equity split)
  - Otherwise: Start as sole proprietorship, incorporate later when profitable

## Timeline Constraints:
- Target: Idea → Launch in 30 days
- Minimum viable scope (don't over-engineer)
- Parallel execution when possible

## Decision Format:
Respond with JSON:
{
  "action": "delegate" | "execute" | "escalate" | "complete",
  "nextAgent": "product_manager" | "marketing_manager" | "operations_manager" | "finance_manager" | "human" | "END",
  "reasoning": "Why this decision?",
  "tasks": [
    {
      "type": "task_type",
      "description": "What needs to be done",
      "assignedTo": "agent_type",
      "estimatedCost": 100
    }
  ],
  "requiresHumanApproval": true | false
}`;

export class CEOAgent {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'claude-sonnet-4.5', temperature: number = 0.3) {
    if (modelName.startsWith('claude')) {
      this.model = new ChatAnthropic({
        modelName,
        temperature,
        maxTokens: 4096,
      });
    } else {
      this.model = new ChatOpenAI({
        modelName,
        temperature,
        maxTokens: 4096,
      });
    }
  }

  /**
   * Main decision-making function
   */
  async makeDecision(state: BusinessState): Promise<Partial<BusinessState>> {
    try {
      const decision = await this.analyzeAndDecide(state);

      // Update state based on decision
      const updates: Partial<BusinessState> = {
        messages: [...state.messages, new AIMessage(JSON.stringify(decision))],
      };

      if (decision.action === 'delegate' && decision.nextAgent) {
        updates.nextAgent = decision.nextAgent;
      } else if (decision.action === 'complete') {
        updates.nextAgent = 'END';
        updates.currentPhase = 'completed';
      } else if (decision.action === 'escalate') {
        updates.nextAgent = 'human';
      }

      // Add any new tasks
      if (decision.tasks && decision.tasks.length > 0) {
        const newTasks = decision.tasks.map(t => ({
          ...t,
          id: crypto.randomUUID(),
          status: 'pending' as const,
        }));
        updates.pendingTasks = [...(state.pendingTasks || []), ...newTasks];
      }

      return updates;
    } catch (error: any) {
      console.error('CEO Agent error:', error);
      return {
        errors: [...(state.errors || []), `CEO error: ${error.message}`],
        nextAgent: 'human',
      };
    }
  }

  /**
   * Analyze current state and make strategic decision
   */
  private async analyzeAndDecide(state: BusinessState): Promise<AgentDecision> {
    const stateContext = this.buildStateContext(state);

    const messages = [
      new SystemMessage(CEO_SYSTEM_PROMPT),
      new HumanMessage(`Current business state:\n${stateContext}\n\nWhat is your decision?`),
    ];

    const response = await this.model.invoke(messages);
    const content = response.content.toString();

    // Parse JSON response
    try {
      const decision = this.parseDecision(content);
      return decision;
    } catch (parseError) {
      // Fallback to simple parsing
      return this.fallbackParsing(content, state);
    }
  }

  /**
   * Build context string from current state
   */
  private buildStateContext(state: BusinessState): string {
    const context = {
      currentPhase: state.currentPhase,
      idea: state.idea,
      businessName: state.businessName,

      // Progress summary
      progress: {
        formation: this.getFormationProgress(state),
        product: this.getProductProgress(state),
        marketing: this.getMarketingProgress(state),
        operations: this.getOperationsProgress(state),
        finance: this.getFinanceProgress(state),
      },

      // Pending and completed tasks
      pendingTasks: state.pendingTasks?.length || 0,
      completedTasks: state.completedTasks?.length || 0,

      // Cost tracking
      totalCost: state.totalCost || 0,
      estimatedMonthlyCost: state.estimatedMonthlyCost || 0,

      // Errors
      hasErrors: (state.errors?.length || 0) > 0,
      errorCount: state.errors?.length || 0,
    };

    return JSON.stringify(context, null, 2);
  }

  private getFormationProgress(state: BusinessState): string {
    if (!state.formation) return 'Not started';
    const { validated, incorporated, bankingSetup, paymentsSetup } = state.formation;
    if (validated && incorporated && bankingSetup && paymentsSetup) return 'Complete';
    if (validated && incorporated) return 'In progress (50%)';
    if (validated) return 'Started (25%)';
    return 'Not started';
  }

  private getProductProgress(state: BusinessState): string {
    if (!state.product) return 'Not started';
    const { specificationsDefined, mvpBuilt, deployed } = state.product;
    if (specificationsDefined && mvpBuilt && deployed) return 'Complete';
    if (specificationsDefined && mvpBuilt) return 'In progress (66%)';
    if (specificationsDefined) return 'Started (33%)';
    return 'Not started';
  }

  private getMarketingProgress(state: BusinessState): string {
    if (!state.marketing) return 'Not started';
    const { strategyDefined, contentCreated, adsLaunched, seoOptimized } = state.marketing;
    const completedCount = [strategyDefined, contentCreated, adsLaunched, seoOptimized].filter(Boolean).length;
    if (completedCount === 4) return 'Complete';
    if (completedCount > 0) return `In progress (${completedCount}/4)`;
    return 'Not started';
  }

  private getOperationsProgress(state: BusinessState): string {
    if (!state.operations) return 'Not started';
    const { supportSetup, analyticsSetup, monitoringSetup } = state.operations;
    const completedCount = [supportSetup, analyticsSetup, monitoringSetup].filter(Boolean).length;
    if (completedCount === 3) return 'Complete';
    if (completedCount > 0) return `In progress (${completedCount}/3)`;
    return 'Not started';
  }

  private getFinanceProgress(state: BusinessState): string {
    if (!state.finance) return 'Not started';
    const { bookkeepingSetup, revenueTracking, expenseTracking } = state.finance;
    const completedCount = [bookkeepingSetup, revenueTracking, expenseTracking].filter(Boolean).length;
    if (completedCount === 3) return 'Complete';
    if (completedCount > 0) return `In progress (${completedCount}/3)`;
    return 'Not started';
  }

  /**
   * Parse JSON decision from model response
   */
  private parseDecision(content: string): AgentDecision {
    // Extract JSON from markdown code blocks if present
    const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                     content.match(/(\{[\s\S]*\})/);

    if (!jsonMatch) {
      throw new Error('No JSON found in response');
    }

    const decision = JSON.parse(jsonMatch[1]);
    return decision as AgentDecision;
  }

  /**
   * Fallback parsing when JSON parsing fails
   */
  private fallbackParsing(content: string, state: BusinessState): AgentDecision {
    const lowerContent = content.toLowerCase();

    // Determine action
    let action: AgentDecision['action'] = 'execute';
    let nextAgent: AgentType | undefined;

    if (lowerContent.includes('delegate to product') || lowerContent.includes('product manager')) {
      action = 'delegate';
      nextAgent = 'product_manager';
    } else if (lowerContent.includes('delegate to marketing') || lowerContent.includes('marketing manager')) {
      action = 'delegate';
      nextAgent = 'marketing_manager';
    } else if (lowerContent.includes('delegate to operations') || lowerContent.includes('operations manager')) {
      action = 'delegate';
      nextAgent = 'operations_manager';
    } else if (lowerContent.includes('delegate to finance') || lowerContent.includes('finance manager')) {
      action = 'delegate';
      nextAgent = 'finance_manager';
    } else if (lowerContent.includes('escalate') || lowerContent.includes('human')) {
      action = 'escalate';
      nextAgent = 'human';
    } else if (lowerContent.includes('complete') || lowerContent.includes('done')) {
      action = 'complete';
      nextAgent = 'END';
    }

    return {
      action,
      nextAgent,
      reasoning: content,
      requiresHumanApproval: action === 'escalate',
    };
  }
}

// Export singleton instance
export const ceoAgent = new CEOAgent();

/**
 * LangGraph node function for CEO Agent
 */
export async function ceoAgentNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log(`\n[CEO Agent] Making strategic decision for phase: ${state.currentPhase}`);

  const startTime = Date.now();
  const result = await ceoAgent.makeDecision(state);
  const durationMs = Date.now() - startTime;

  console.log(`[CEO Agent] Decision made in ${durationMs}ms - Next: ${result.nextAgent}`);

  return result;
}
