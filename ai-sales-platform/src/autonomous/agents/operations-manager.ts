import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, AIMessage } from '@langchain/core/messages';
import { BusinessState, AgentDecision } from '../types';

/**
 * Operations Manager Agent
 *
 * Responsibilities:
 * - Setup customer support (Fin AI - 70% automation)
 * - Configure analytics (PostHog, Mixpanel)
 * - Implement monitoring (Sentry, error tracking)
 * - Manage operations infrastructure
 */

const OPERATIONS_MANAGER_PROMPT = `You are the Operations Manager Agent responsible for smooth business operations.

## Your Responsibilities:
1. **Customer Support**: Setup Fin AI chatbot (70%+ automation rate)
2. **Analytics**: Configure PostHog/Mixpanel for product analytics
3. **Monitoring**: Setup Sentry for error tracking, uptime monitoring
4. **Performance**: Ensure <2s page load, 99.9% uptime

## Available Worker Agents:
- **Support Worker**: Configures Fin AI chatbot
- **Analytics Worker**: Sets up PostHog, tracking events
- **Monitoring Worker**: Configures Sentry, uptime checks

## Tools & Services:
- **Fin AI**: 65-80% support automation, $150/month
- **Chatwoot**: Open source alternative (free)
- **PostHog**: Product analytics, $50/month
- **Sentry**: Error tracking, free tier available
- **BetterStack**: Uptime monitoring, $20/month

## Operational Targets:
- Support response time: <5 minutes (AI), <2 hours (human)
- Support automation rate: >70%
- Error rate: <0.1%
- Uptime: >99.9%
- Page load: <2 seconds

## Cost Budget:
- Total operations tools: $200-$300/month
- Prioritize high automation, low cost

## Response Format (JSON):
{
  "action": "delegate" | "execute" | "report",
  "nextAgent": "support_worker" | "ceo",
  "reasoning": "Operations rationale",
  "tasks": [
    {
      "type": "setup_support" | "setup_analytics" | "monitor_performance",
      "description": "Task details",
      "assignedTo": "support_worker",
      "estimatedCost": 150
    }
  ]
}`;

export class OperationsManagerAgent {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'gpt-4o-mini', temperature: number = 0.3) {
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
      console.log('[Operations Manager] Planning operations setup');

      const decision = await this.makeOperationsDecision(state);

      const updates: Partial<BusinessState> = {
        messages: [...state.messages, new AIMessage(JSON.stringify(decision))],
      };

      // Update operations status
      if (decision.tasks) {
        const updatedOps = { ...state.operations };

        decision.tasks.forEach(task => {
          if (task.type === 'setup_support') updatedOps.supportSetup = true;
          if (task.type === 'setup_analytics') updatedOps.analyticsSetup = true;
          if (task.type === 'monitor_performance') updatedOps.monitoringSetup = true;
        });

        updates.operations = updatedOps;
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
      console.error('Operations Manager error:', error);
      return {
        errors: [...(state.errors || []), `Operations Manager error: ${error.message}`],
        nextAgent: 'ceo',
      };
    }
  }

  private async makeOperationsDecision(state: BusinessState): Promise<AgentDecision> {
    const context = {
      productStatus: state.product,
      operationsStatus: state.operations,
      productUrl: state.product?.productUrl,
    };

    const messages = [
      new SystemMessage(OPERATIONS_MANAGER_PROMPT),
      new HumanMessage(`Business context:\n${JSON.stringify(context, null, 2)}\n\nWhat operations need to be setup?`),
    ];

    const response = await this.model.invoke(messages);
    const content = response.content.toString();

    try {
      return this.parseDecision(content);
    } catch (error) {
      return this.fallbackPlan(state);
    }
  }

  private parseDecision(content: string): AgentDecision {
    const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                     content.match(/(\{[\s\S]*\})/);
    if (!jsonMatch) throw new Error('No JSON found');
    return JSON.parse(jsonMatch[1]);
  }

  private fallbackPlan(state: BusinessState): AgentDecision {
    const ops = state.operations;

    if (!ops?.supportSetup) {
      return {
        action: 'delegate',
        nextAgent: 'support_worker',
        reasoning: 'Setting up AI customer support',
        tasks: [{
          type: 'setup_support',
          description: 'Configure Fin AI chatbot for automated support',
          assignedTo: 'support_worker',
          estimatedCost: 150,
        }],
      };
    } else if (!ops?.analyticsSetup) {
      return {
        action: 'execute',
        nextAgent: 'ceo',
        reasoning: 'Setting up analytics tracking',
        tasks: [{
          type: 'setup_analytics',
          description: 'Configure PostHog for product analytics',
          estimatedCost: 50,
        }],
      };
    } else {
      return {
        action: 'execute',
        nextAgent: 'ceo',
        reasoning: 'Operations setup complete',
      };
    }
  }
}

export const operationsManagerAgent = new OperationsManagerAgent();

export async function operationsManagerNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Operations Manager] Planning operations');
  const startTime = Date.now();
  const result = await operationsManagerAgent.plan(state);
  console.log(`[Operations Manager] Completed in ${Date.now() - startTime}ms`);
  return result;
}
