import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, AIMessage } from '@langchain/core/messages';
import { BusinessState, AgentDecision } from '../types';

/**
 * Finance Manager Agent
 *
 * Responsibilities:
 * - Setup automated bookkeeping (Ramp AI - 95% accuracy)
 * - Track revenue and expenses
 * - Monitor burn rate and runway
 * - Generate financial reports
 */

const FINANCE_MANAGER_PROMPT = `You are the Finance Manager Agent responsible for financial health and tracking.

## Your Responsibilities:
1. **Bookkeeping**: Setup Ramp AI (95% accuracy, auto-categorization)
2. **Revenue Tracking**: Monitor MRR, ARR, growth rate
3. **Expense Tracking**: Track burn rate, cost per customer
4. **Financial Reports**: Weekly/monthly reports to CEO

## Available Worker Agents:
- **Bookkeeper Worker**: Configures Ramp AI, syncs bank accounts
- **Reporting Worker**: Generates financial dashboards

## Tools & Services:
- **Ramp AI**: Automated expense management, $0 (free with Ramp card)
- **Stripe**: Payment processing, 2.9% + 30¢ per transaction
- **Mercury**: Business banking, $0 monthly fee
- **Apideck**: Unified accounting API, $99/month

## Financial Metrics to Track:
- Monthly Recurring Revenue (MRR)
- Customer Acquisition Cost (CAC)
- Lifetime Value (LTV)
- Burn rate (monthly expenses)
- Runway (months until cash runs out)
- Gross margin
- Cash balance

## Cost Targets:
- Operating costs: <$700/month per business
- CAC: <$50
- LTV:CAC ratio: >3:1
- Gross margin: >70%

## Response Format (JSON):
{
  "action": "delegate" | "execute" | "report",
  "nextAgent": "bookkeeper_worker" | "ceo",
  "reasoning": "Financial rationale",
  "tasks": [
    {
      "type": "setup_bookkeeping" | "track_revenue" | "track_expenses",
      "description": "Task details",
      "assignedTo": "bookkeeper_worker",
      "estimatedCost": 0
    }
  ],
  "financialSummary": {
    "monthlyRevenue": 0,
    "monthlyExpenses": 700,
    "burnRate": 700,
    "runway": "12 months (if $8,400 cash)"
  }
}`;

export class FinanceManagerAgent {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'gpt-4o-mini', temperature: number = 0.2) {
    if (modelName.startsWith('claude')) {
      this.model = new ChatAnthropic({
        modelName,
        temperature,
        maxTokens: 3000,
      });
    } else {
      this.model = new ChatOpenAI({
        modelName,
        temperature,
        maxTokens: 3000,
      });
    }
  }

  async plan(state: BusinessState): Promise<Partial<BusinessState>> {
    try {
      console.log('[Finance Manager] Planning financial setup');

      const decision = await this.makeFinanceDecision(state);

      const updates: Partial<BusinessState> = {
        messages: [...state.messages, new AIMessage(JSON.stringify(decision))],
      };

      // Update finance status
      if (decision.tasks) {
        const updatedFinance = { ...state.finance };

        decision.tasks.forEach(task => {
          if (task.type === 'setup_bookkeeping') updatedFinance.bookkeepingSetup = true;
          if (task.type === 'track_revenue') updatedFinance.revenueTracking = true;
          if (task.type === 'track_expenses') updatedFinance.expenseTracking = true;
        });

        updates.finance = updatedFinance;
      }

      // Add tasks
      if (decision.tasks && decision.tasks.length > 0) {
        const newTasks = decision.tasks.map(t => ({
          ...t,
          id: crypto.randomUUID(),
          status: 'pending' as const,
        }));
        updates.pendingTasks = [...(state.pendingTasks || []), ...newTasks];
      }

      updates.nextAgent = decision.action === 'delegate' ? decision.nextAgent : 'ceo';

      return updates;
    } catch (error: any) {
      console.error('Finance Manager error:', error);
      return {
        errors: [...(state.errors || []), `Finance Manager error: ${error.message}`],
        nextAgent: 'ceo',
      };
    }
  }

  private async makeFinanceDecision(state: BusinessState): Promise<AgentDecision & { financialSummary?: any }> {
    const context = {
      formationStatus: state.formation,
      financeStatus: state.finance,
      totalCost: state.totalCost,
      estimatedMonthlyCost: state.estimatedMonthlyCost,
    };

    const messages = [
      new SystemMessage(FINANCE_MANAGER_PROMPT),
      new HumanMessage(`Business context:\n${JSON.stringify(context, null, 2)}\n\nWhat financial setup is needed?`),
    ];

    const response = await this.model.invoke(messages);
    const content = response.content.toString();

    try {
      return this.parseDecision(content);
    } catch (error) {
      return this.fallbackPlan(state);
    }
  }

  private parseDecision(content: string): AgentDecision & { financialSummary?: any } {
    const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                     content.match(/(\{[\s\S]*\})/);
    if (!jsonMatch) throw new Error('No JSON found');
    return JSON.parse(jsonMatch[1]);
  }

  private fallbackPlan(state: BusinessState): AgentDecision & { financialSummary?: any } {
    const finance = state.finance;

    if (!finance?.bookkeepingSetup) {
      return {
        action: 'delegate',
        nextAgent: 'bookkeeper_worker',
        reasoning: 'Setting up automated bookkeeping',
        tasks: [{
          type: 'setup_bookkeeping',
          description: 'Configure Ramp AI for automated expense categorization',
          assignedTo: 'bookkeeper_worker',
          estimatedCost: 0,
        }],
      };
    } else {
      return {
        action: 'report',
        nextAgent: 'ceo',
        reasoning: 'Financial tracking active',
        financialSummary: {
          monthlyRevenue: state.finance?.monthlyRevenue || 0,
          monthlyExpenses: state.estimatedMonthlyCost || 700,
          burnRate: state.estimatedMonthlyCost || 700,
        },
      };
    }
  }
}

export const financeManagerAgent = new FinanceManagerAgent();

export async function financeManagerNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Finance Manager] Planning financial operations');
  const startTime = Date.now();
  const result = await financeManagerAgent.plan(state);
  console.log(`[Finance Manager] Completed in ${Date.now() - startTime}ms`);
  return result;
}
