import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, AIMessage } from '@langchain/core/messages';
import { BusinessState } from '../types';

/**
 * Formation Advisor Agent
 *
 * Decides whether incorporation is necessary based on business type.
 * Many businesses can start without incorporation!
 */

const FORMATION_ADVISOR_PROMPT = `You are a Formation Advisor helping founders decide if they need to incorporate.

## Your Role:
Determine the minimum viable legal structure for a business idea.

## Key Principle:
**Most businesses DON'T need incorporation at launch!**

## When to SKIP incorporation (sole proprietorship):
✅ Digital products (SaaS, apps, content)
✅ Service businesses (consulting, freelance, agencies)
✅ Low liability risk
✅ Solo founder or equal partners
✅ Not raising venture capital
✅ Testing market fit / MVP stage
✅ Revenue < $50K/year expected

**Benefits**:
- Save $399 incorporation cost
- Start immediately (no waiting)
- Use personal bank account + Stripe
- File taxes on personal return (simpler)
- Can incorporate later when profitable

## When to INCORPORATE (LLC):
- Physical products (liability risk)
- Multiple founders (need equity structure)
- Employees/contractors (professional image)
- Raising money from investors (angel/seed)
- Revenue > $50K/year expected
- Want liability protection

**Cost**: $399 (doola) + $50-200/year state fees

## When to do C-CORP:
- Raising venture capital (VCs require C-Corp)
- Planning for IPO
- Offering employee stock options
- Expected revenue > $1M/year

**Cost**: $399 (doola) + $800-2000/year (accounting/tax complexity)

## Decision Format (JSON):
{
  "recommendation": "sole_proprietorship" | "llc" | "c_corp" | "none",
  "reasoning": "Why this structure?",
  "canStartImmediately": true | false,
  "estimatedCost": 0 | 399,
  "alternatives": [
    {
      "structure": "llc",
      "whenToConsider": "After first $10K revenue or 6 months"
    }
  ]
}`;

export class FormationAdvisorAgent {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'gpt-4o-mini', temperature: number = 0.2) {
    if (modelName.startsWith('claude')) {
      this.model = new ChatAnthropic({
        modelName,
        temperature,
        maxTokens: 2000,
      });
    } else {
      this.model = new ChatOpenAI({
        modelName,
        temperature,
        maxTokens: 2000,
      });
    }
  }

  async analyze(state: BusinessState): Promise<Partial<BusinessState>> {
    try {
      console.log('[Formation Advisor] Analyzing legal structure needs');

      const decision = await this.makeFormationDecision(state);

      const updates: Partial<BusinessState> = {
        messages: [...state.messages, new AIMessage(JSON.stringify(decision))],
        formation: {
          validated: true,
          legalStructure: decision.recommendation,
          incorporated: decision.recommendation !== 'sole_proprietorship' && decision.recommendation !== 'none',
          bankingSetup: false,
          paymentsSetup: false,
        },
      };

      // Update cost based on incorporation decision
      if (decision.estimatedCost) {
        updates.totalCost = (state.totalCost || 0) + decision.estimatedCost;
      }

      return updates;
    } catch (error: any) {
      console.error('Formation Advisor error:', error);
      return {
        errors: [...(state.errors || []), `Formation Advisor error: ${error.message}`],
      };
    }
  }

  private async makeFormationDecision(state: BusinessState): Promise<{
    recommendation: 'sole_proprietorship' | 'llc' | 'c_corp' | 'none';
    reasoning: string;
    canStartImmediately: boolean;
    estimatedCost: number;
    alternatives?: any[];
  }> {
    const context = {
      idea: state.idea.description,
      targetMarket: state.idea.targetMarket,
      monetization: state.idea.monetizationModel,
    };

    const messages = [
      new SystemMessage(FORMATION_ADVISOR_PROMPT),
      new HumanMessage(`Business context:\n${JSON.stringify(context, null, 2)}\n\nWhat legal structure do you recommend?`),
    ];

    const response = await this.model.invoke(messages);
    const content = response.content.toString();

    try {
      return this.parseDecision(content);
    } catch (error) {
      // Fallback: Default to sole proprietorship for most cases
      return this.fallbackDecision(state);
    }
  }

  private parseDecision(content: string): any {
    const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                     content.match(/(\{[\s\S]*\})/);
    if (!jsonMatch) throw new Error('No JSON found');
    return JSON.parse(jsonMatch[1]);
  }

  private fallbackDecision(state: BusinessState): any {
    const description = state.idea.description.toLowerCase();

    // Heuristics for decision
    const isPhysicalProduct = description.includes('product') ||
                             description.includes('hardware') ||
                             description.includes('device');

    const isVCBacked = description.includes('venture') ||
                      description.includes('raise capital') ||
                      description.includes('vc');

    const isServiceBusiness = description.includes('saas') ||
                             description.includes('app') ||
                             description.includes('software') ||
                             description.includes('service');

    if (isVCBacked) {
      return {
        recommendation: 'c_corp',
        reasoning: 'Venture-backed businesses require C-Corp structure',
        canStartImmediately: false,
        estimatedCost: 399,
      };
    } else if (isPhysicalProduct) {
      return {
        recommendation: 'llc',
        reasoning: 'Physical products have liability risk - LLC recommended for protection',
        canStartImmediately: false,
        estimatedCost: 399,
      };
    } else {
      return {
        recommendation: 'sole_proprietorship',
        reasoning: 'Digital/service business with low liability - start as sole proprietorship, incorporate later if needed',
        canStartImmediately: true,
        estimatedCost: 0,
        alternatives: [{
          structure: 'llc',
          whenToConsider: 'After first $10K revenue or when hiring employees'
        }],
      };
    }
  }
}

export const formationAdvisorAgent = new FormationAdvisorAgent();

export async function formationAdvisorNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Formation Advisor] Determining legal structure needs');
  const startTime = Date.now();
  const result = await formationAdvisorAgent.analyze(state);
  console.log(`[Formation Advisor] Completed in ${Date.now() - startTime}ms`);
  return result;
}
