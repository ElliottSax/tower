import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, AIMessage } from '@langchain/core/messages';
import { BusinessState, AgentDecision, Task } from '../types';

/**
 * Product Manager Agent
 *
 * Responsibilities:
 * - Define product specifications from business idea
 * - Delegate MVP development to Developer Worker (Replit Agent)
 * - Manage deployment and infrastructure
 * - Ensure product quality and functionality
 */

const PRODUCT_MANAGER_PROMPT = `You are the Product Manager Agent responsible for building and deploying the MVP.

## Your Responsibilities:
1. **Define Specifications**: Convert business idea into detailed product specs
2. **Delegate Development**: Assign tasks to Developer Worker (Replit Agent, GitHub Copilot)
3. **Deploy Product**: Coordinate deployment to Vercel/production
4. **Setup Infrastructure**: Provision databases, APIs, hosting

## Available Worker Agents:
- **Replit Agent**: Generates full-stack applications (3-7 days, ~$500)
- **GitHub Copilot Agent**: Code generation and bug fixes
- **SWE-Agent**: Automated bug fixing and testing

## Technology Stack Preferences:
- Frontend: Next.js, React, Tailwind CSS
- Backend: Node.js, TypeScript, Express/NestJS
- Database: PostgreSQL via Supabase (auto-provisioned)
- Deployment: Vercel (auto-deploy)
- APIs: RESTful with OpenAPI docs

## Decision Criteria:
- **Speed over perfection**: MVP should launch in 3-7 days
- **Use proven patterns**: Don't reinvent the wheel
- **Leverage AI tools**: Replit Agent can generate 80% of code
- **Focus on core features**: No nice-to-haves in v1

## Cost Constraints:
- Development budget: $500-$1,500
- Monthly hosting: $50-$100
- Prefer serverless/auto-scaling solutions

## Response Format (JSON):
{
  "action": "delegate" | "execute" | "report",
  "nextAgent": "developer_worker" | "ceo",
  "reasoning": "Why this approach?",
  "tasks": [
    {
      "type": "define_specifications" | "generate_code" | "deploy_mvp",
      "description": "Detailed task description",
      "assignedTo": "developer_worker",
      "estimatedCost": 500,
      "dependencies": ["task_id"]
    }
  ],
  "specifications": {
    "features": ["Feature 1", "Feature 2"],
    "techStack": "Next.js + Supabase + Vercel",
    "estimatedDevelopmentDays": 5
  }
}`;

export class ProductManagerAgent {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'claude-sonnet-4.5', temperature: number = 0.4) {
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
      console.log(`[Product Manager] Planning MVP for: ${state.idea.description}`);

      const decision = await this.makeProductDecision(state);

      const updates: Partial<BusinessState> = {
        messages: [...state.messages, new AIMessage(JSON.stringify(decision))],
      };

      // Update product status if specifications were defined
      if (decision.specifications) {
        updates.product = {
          specificationsDefined: true,
          mvpBuilt: false,
          deployed: false,
          ...state.product,
        };
      }

      // Add tasks if delegating
      if (decision.tasks && decision.tasks.length > 0) {
        const newTasks = decision.tasks.map(t => ({
          ...t,
          id: crypto.randomUUID(),
          status: 'pending' as const,
        }));
        updates.pendingTasks = [...(state.pendingTasks || []), ...newTasks];
      }

      // Route back to CEO or to worker
      if (decision.action === 'delegate') {
        updates.nextAgent = decision.nextAgent;
      } else {
        updates.nextAgent = 'ceo'; // Report back to CEO
      }

      return updates;
    } catch (error: any) {
      console.error('Product Manager error:', error);
      return {
        errors: [...(state.errors || []), `Product Manager error: ${error.message}`],
        nextAgent: 'ceo',
      };
    }
  }

  private async makeProductDecision(state: BusinessState): Promise<AgentDecision & { specifications?: any }> {
    const context = {
      idea: state.idea,
      currentPhase: state.currentPhase,
      productStatus: state.product,
      pendingTasks: state.pendingTasks?.filter(t =>
        t.type.includes('specification') ||
        t.type.includes('code') ||
        t.type.includes('deploy')
      ),
    };

    const messages = [
      new SystemMessage(PRODUCT_MANAGER_PROMPT),
      new HumanMessage(`Business context:\n${JSON.stringify(context, null, 2)}\n\nWhat's your product plan?`),
    ];

    const response = await this.model.invoke(messages);
    const content = response.content.toString();

    try {
      return this.parseDecision(content);
    } catch (error) {
      return this.fallbackPlan(state);
    }
  }

  private parseDecision(content: string): AgentDecision & { specifications?: any } {
    const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                     content.match(/(\{[\s\S]*\})/);

    if (!jsonMatch) {
      throw new Error('No JSON found in response');
    }

    return JSON.parse(jsonMatch[1]);
  }

  private fallbackPlan(state: BusinessState): AgentDecision & { specifications?: any } {
    // Default plan: Define specs → Generate code → Deploy
    const isSpecsDone = state.product?.specificationsDefined;
    const isMVPBuilt = state.product?.mvpBuilt;

    if (!isSpecsDone) {
      return {
        action: 'execute',
        nextAgent: 'ceo',
        reasoning: 'Defining product specifications based on business idea',
        specifications: {
          features: this.extractFeatures(state.idea.description),
          techStack: 'Next.js + Supabase + Vercel',
          estimatedDevelopmentDays: 5,
        },
      };
    } else if (!isMVPBuilt) {
      return {
        action: 'delegate',
        nextAgent: 'developer_worker',
        reasoning: 'Delegating MVP development to Replit Agent',
        tasks: [{
          type: 'generate_code',
          description: `Build MVP for: ${state.idea.description}`,
          assignedTo: 'developer_worker',
          estimatedCost: 500,
        }],
      };
    } else {
      return {
        action: 'delegate',
        nextAgent: 'developer_worker',
        reasoning: 'Deploying MVP to production',
        tasks: [{
          type: 'deploy_mvp',
          description: 'Deploy application to Vercel',
          assignedTo: 'developer_worker',
          estimatedCost: 50,
        }],
      };
    }
  }

  private extractFeatures(description: string): string[] {
    // Simple feature extraction - in production, would use more sophisticated NLP
    const features = [
      'User authentication',
      'Core functionality for: ' + description.substring(0, 100),
      'Basic UI/UX',
      'Database integration',
      'API endpoints',
    ];
    return features;
  }
}

export const productManagerAgent = new ProductManagerAgent();

export async function productManagerNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Product Manager] Planning product development');
  const startTime = Date.now();
  const result = await productManagerAgent.plan(state);
  console.log(`[Product Manager] Completed in ${Date.now() - startTime}ms`);
  return result;
}
