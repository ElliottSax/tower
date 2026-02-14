import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, AIMessage } from '@langchain/core/messages';
import { BusinessState, AgentDecision } from '../types';

/**
 * Marketing Manager Agent
 *
 * Responsibilities:
 * - Define marketing strategy
 * - Delegate content creation to Content Worker (SEObot)
 * - Launch ad campaigns via Ads Worker (Meta AI, Google Ads)
 * - Optimize SEO and conversions
 */

const MARKETING_MANAGER_PROMPT = `You are the Marketing Manager Agent responsible for customer acquisition and growth.

## Your Responsibilities:
1. **Define Strategy**: Create marketing plan based on target market
2. **Content Creation**: Delegate to SEObot for blog posts, landing pages
3. **Ad Campaigns**: Launch Meta AI and Google Ads campaigns
4. **SEO Optimization**: Ensure discoverability

## Available Worker Agents:
- **SEObot**: Autonomous SEO content creation (14% better conversions)
- **Meta AI Agent**: Automated Facebook/Instagram ads
- **Content Worker**: Blog posts, email sequences, social media
- **Bika.ai**: Social media automation

## Marketing Channels (Priority Order):
1. **SEO** - Long-term, low cost ($50/month)
2. **Meta Ads** - Fast validation ($300/month starting budget)
3. **Google Ads** - High intent traffic ($200/month)
4. **Content Marketing** - Builds authority (SEObot automation)
5. **Social Media** - Brand awareness (Bika.ai automation)

## Budget Allocation (for typical SaaS):
- SEO tools: $50/month
- Ad spend: $500/month (Meta + Google)
- Content tools: $100/month
- Total: ~$650/month

## Success Metrics:
- Target: 100 signups in first 30 days
- Cost per acquisition: <$50
- Conversion rate: >2% (landing page)
- SEO: Rank for 3-5 keywords within 90 days

## Response Format (JSON):
{
  "action": "delegate" | "execute" | "report",
  "nextAgent": "content_worker" | "ads_worker" | "ceo",
  "reasoning": "Marketing rationale",
  "tasks": [
    {
      "type": "define_marketing_strategy" | "create_content" | "launch_ads",
      "description": "Task details",
      "assignedTo": "content_worker" | "ads_worker",
      "estimatedCost": 300
    }
  ],
  "strategy": {
    "targetAudience": "Who we're targeting",
    "channels": ["SEO", "Meta Ads"],
    "budget": 650,
    "expectedCAC": 40
  }
}`;

export class MarketingManagerAgent {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'claude-sonnet-4.5', temperature: number = 0.5) {
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

  async plan(state: BusinessState): Promise<Partial<BusinessState>> {
    try {
      console.log('[Marketing Manager] Creating marketing strategy');

      const decision = await this.makeMarketingDecision(state);

      const updates: Partial<BusinessState> = {
        messages: [...state.messages, new AIMessage(JSON.stringify(decision))],
      };

      // Update marketing status
      if (decision.strategy) {
        updates.marketing = {
          strategyDefined: true,
          contentCreated: false,
          adsLaunched: false,
          seoOptimized: false,
          ...state.marketing,
        };
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

      // Route
      updates.nextAgent = decision.action === 'delegate' ? decision.nextAgent : 'ceo';

      return updates;
    } catch (error: any) {
      console.error('Marketing Manager error:', error);
      return {
        errors: [...(state.errors || []), `Marketing Manager error: ${error.message}`],
        nextAgent: 'ceo',
      };
    }
  }

  private async makeMarketingDecision(state: BusinessState): Promise<AgentDecision & { strategy?: any }> {
    const context = {
      idea: state.idea,
      productStatus: state.product,
      marketingStatus: state.marketing,
      businessName: state.businessName,
    };

    const messages = [
      new SystemMessage(MARKETING_MANAGER_PROMPT),
      new HumanMessage(`Business context:\n${JSON.stringify(context, null, 2)}\n\nWhat's the marketing plan?`),
    ];

    const response = await this.model.invoke(messages);
    const content = response.content.toString();

    try {
      return this.parseDecision(content);
    } catch (error) {
      return this.fallbackPlan(state);
    }
  }

  private parseDecision(content: string): AgentDecision & { strategy?: any } {
    const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                     content.match(/(\{[\s\S]*\})/);
    if (!jsonMatch) throw new Error('No JSON found');
    return JSON.parse(jsonMatch[1]);
  }

  private fallbackPlan(state: BusinessState): AgentDecision & { strategy?: any } {
    const isStrategyDefined = state.marketing?.strategyDefined;

    if (!isStrategyDefined) {
      return {
        action: 'execute',
        nextAgent: 'ceo',
        reasoning: 'Defining marketing strategy',
        strategy: {
          targetAudience: state.idea.targetMarket,
          channels: ['SEO', 'Meta Ads', 'Content'],
          budget: 650,
          expectedCAC: 40,
        },
      };
    } else {
      return {
        action: 'delegate',
        nextAgent: 'content_worker',
        reasoning: 'Creating SEO-optimized content',
        tasks: [{
          type: 'create_content',
          description: 'Generate landing page and blog posts',
          assignedTo: 'content_worker',
          estimatedCost: 100,
        }],
      };
    }
  }
}

export const marketingManagerAgent = new MarketingManagerAgent();

export async function marketingManagerNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Marketing Manager] Planning marketing strategy');
  const startTime = Date.now();
  const result = await marketingManagerAgent.plan(state);
  console.log(`[Marketing Manager] Completed in ${Date.now() - startTime}ms`);
  return result;
}
