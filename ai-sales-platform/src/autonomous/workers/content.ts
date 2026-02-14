import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';
import { BusinessState, Task } from '../types';

/**
 * Content Worker - Creates marketing content
 *
 * Uses AI to generate:
 * - Landing page copy
 * - Blog posts (SEO-optimized)
 * - Social media content
 * - Email sequences
 */

const CONTENT_GENERATOR_PROMPT = `You are an expert copywriter creating marketing content.

## Your Task:
Generate high-converting, SEO-optimized content for a business.

## Tone & Style:
- Clear and concise
- Benefit-focused (not feature-focused)
- Action-oriented CTAs
- SEO keywords naturally integrated
- Mobile-friendly formatting

## Response Format (JSON):
{
  "landingPage": {
    "headline": "Compelling headline addressing pain point",
    "subheadline": "Supporting benefit",
    "heroSection": "1-2 sentences",
    "features": ["Benefit 1", "Benefit 2", "Benefit 3"],
    "cta": "Action-oriented CTA",
    "socialProof": "Trust element"
  },
  "blogPost": {
    "title": "SEO-optimized title",
    "outline": ["Section 1", "Section 2", "Section 3"],
    "keywords": ["keyword1", "keyword2"]
  },
  "socialMedia": {
    "linkedin": "Professional post",
    "twitter": "Concise tweet",
    "facebook": "Engaging post"
  }
}`;

export class ContentWorker {
  private model: ChatOpenAI | ChatAnthropic;

  constructor(modelName: string = 'gpt-4o-mini', temperature: number = 0.7) {
    if (modelName.startsWith('claude')) {
      this.model = new ChatAnthropic({
        modelName,
        temperature,
        maxTokens: 4000,
      });
    } else {
      this.model = new ChatOpenAI({
        modelName,
        temperature,
        maxTokens: 4000,
      });
    }
  }

  /**
   * Generate landing page content
   */
  async generateLandingPage(state: BusinessState): Promise<any> {
    console.log('[Content Worker] Generating landing page copy');

    const context = {
      business: state.idea.description,
      targetMarket: state.idea.targetMarket,
      problemSolved: state.idea.problemSolved,
      monetization: state.idea.monetizationModel,
    };

    const messages = [
      new SystemMessage(CONTENT_GENERATOR_PROMPT),
      new HumanMessage(`Generate landing page content for:\n${JSON.stringify(context, null, 2)}`),
    ];

    try {
      const response = await this.model.invoke(messages);
      const content = response.content.toString();

      // Parse JSON response
      const parsed = this.parseContent(content);

      return {
        status: 'success',
        content: parsed,
        aiGenerated: true,
        model: (this.model as any).modelName,
        cost: 0.01, // Approximate cost
      };
    } catch (error: any) {
      console.error('[Content Worker] Error:', error.message);
      return this.fallbackContent(state);
    }
  }

  /**
   * Generate blog post outlines (for SEO)
   */
  async generateBlogPosts(state: BusinessState, count: number = 3): Promise<any> {
    console.log(`[Content Worker] Generating ${count} blog post outlines`);

    const topic = state.idea.description;
    const audience = state.idea.targetMarket;

    const messages = [
      new SystemMessage(`You are an SEO expert creating blog post outlines.

Generate ${count} blog post ideas that will:
1. Rank for relevant keywords
2. Attract the target audience
3. Drive conversions

For each post, provide:
- SEO-optimized title
- Target keywords
- Outline (H2 sections)
- Estimated word count

Return as JSON array.`),
      new HumanMessage(`Topic: ${topic}\nAudience: ${audience}\n\nGenerate ${count} blog post outlines.`),
    ];

    try {
      const response = await this.model.invoke(messages);
      const content = response.content.toString();

      return {
        status: 'success',
        posts: this.parseBlogPosts(content, count),
        cost: 0.02,
      };
    } catch (error: any) {
      return this.fallbackBlogPosts(state, count);
    }
  }

  /**
   * Parse content from AI response
   */
  private parseContent(content: string): any {
    try {
      const jsonMatch = content.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/) ||
                       content.match(/(\{[\s\S]*\})/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[1]);
      }
    } catch (e) {
      // Fallback parsing
    }

    // Return basic structure if parsing fails
    return {
      landingPage: {
        headline: content.split('\n')[0] || 'Transform Your Business',
        cta: 'Get Started Free',
      },
    };
  }

  /**
   * Parse blog posts from AI response
   */
  private parseBlogPosts(content: string, count: number): any[] {
    try {
      const jsonMatch = content.match(/```(?:json)?\s*(\[[\s\S]*?\])\s*```/) ||
                       content.match(/(\[[\s\S]*\])/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[1]);
      }
    } catch (e) {
      // Fallback
    }

    // Return placeholder posts
    return Array.from({ length: count }, (_, i) => ({
      title: `Blog Post ${i + 1}`,
      keywords: ['keyword1', 'keyword2'],
      outline: ['Introduction', 'Main Content', 'Conclusion'],
    }));
  }

  /**
   * Fallback content (if AI fails)
   */
  private fallbackContent(state: BusinessState): any {
    return {
      status: 'fallback',
      content: {
        landingPage: {
          headline: `${state.businessName || 'Your Business'} - ${state.idea.problemSolved}`,
          subheadline: `Built for ${state.idea.targetMarket}`,
          heroSection: state.idea.description,
          features: [
            'Easy to use',
            'Save time and money',
            'Trusted by customers',
          ],
          cta: 'Get Started Free',
          socialProof: 'Join thousands of satisfied customers',
        },
      },
      cost: 0,
    };
  }

  /**
   * Fallback blog posts
   */
  private fallbackBlogPosts(state: BusinessState, count: number): any {
    return {
      status: 'fallback',
      posts: Array.from({ length: count }, (_, i) => ({
        title: `How to ${state.idea.problemSolved} - Guide ${i + 1}`,
        keywords: state.idea.description.split(' ').slice(0, 3),
        outline: ['Introduction', 'Benefits', 'How It Works', 'Get Started'],
        estimatedWords: 1500,
      })),
      cost: 0,
    };
  }
}

export const contentWorker = new ContentWorker();

/**
 * LangGraph node function
 */
export async function contentWorkerNode(state: BusinessState): Promise<Partial<BusinessState>> {
  console.log('[Content Worker] Creating marketing content');

  const worker = new ContentWorker();

  // Find pending content tasks
  const contentTasks = state.pendingTasks?.filter(
    task => task.assignedTo === 'content_worker' && task.status === 'pending'
  ) || [];

  if (contentTasks.length === 0) {
    return { nextAgent: 'marketing_manager' };
  }

  const task = contentTasks[0];

  try {
    let result: any;

    if (task.type === 'create_content' || task.description.toLowerCase().includes('landing')) {
      result = await worker.generateLandingPage(state);

      // Update marketing status
      const updatedMarketing = {
        ...state.marketing,
        contentCreated: true,
      };

      // Mark task complete
      const updatedTasks = state.pendingTasks?.map(t =>
        t.id === task.id
          ? { ...t, status: 'completed' as const, result }
          : t
      ) || [];

      return {
        marketing: updatedMarketing,
        pendingTasks: updatedTasks,
        completedTasks: [...(state.completedTasks || []), task.id],
        totalCost: (state.totalCost || 0) + (result.cost || 0),
        nextAgent: 'marketing_manager',
      };
    }

    return { nextAgent: 'marketing_manager' };
  } catch (error: any) {
    console.error('[Content Worker] Error:', error);

    const updatedTasks = state.pendingTasks?.map(t =>
      t.id === task.id
        ? { ...t, status: 'failed' as const, error: error.message }
        : t
    ) || [];

    return {
      pendingTasks: updatedTasks,
      errors: [...(state.errors || []), `Content Worker: ${error.message}`],
      nextAgent: 'marketing_manager',
    };
  }
}
