import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { AIMessage } from '@langchain/core/messages';
import { AgentState } from './types';
import { logAgentAction } from '../utils/logging';

/**
 * Writer Agent - Creates personalized outreach messages
 *
 * Uses AI to generate highly personalized emails based on:
 * - Research findings (pain points, buying signals)
 * - Enrichment data (role, company info)
 * - Campaign context
 *
 * Key principles:
 * - Temperature 0.3-0.4 for focused but natural output
 * - Never invent facts - only use verified data
 * - Focus on value, not features
 * - Keep it concise (< 150 words)
 */

const WRITER_PROMPT = `You are an expert B2B sales copywriter. Your emails consistently achieve 40%+ open rates and 8%+ reply rates.

Key principles:
1. NEVER invent facts. Only use information provided.
2. Be specific, not generic. Reference actual details about their company.
3. Lead with value, not your product.
4. Keep it under 150 words.
5. End with a clear, low-friction CTA.
6. No "Hope you're well" or other clichés.
7. Use a conversational, professional tone.

Bad example:
"Hi John, I hope this email finds you well. I wanted to reach out about our amazing product..."

Good example:
"Hi John, noticed you're hiring 4 new SDRs this quarter. Onboarding that many reps while maintaining quality can be tough - we helped Acme Corp cut ramp time by 40% when they scaled from 5 to 20 reps last year. Worth a quick chat?"

Output format (JSON):
{
  "subject": "...",
  "body": "...",
  "reasoning": "Why this approach will resonate..."
}`;

export async function writerAgent(state: AgentState): Promise<Partial<AgentState>> {
  const startTime = Date.now();

  try {
    // Check if we have enough context to write
    if (!state.lead?.firstName || !state.lead?.companyName) {
      return {
        errors: [...(state.errors || []), 'Writer: Missing basic lead information (name, company)'],
      };
    }

    // Determine which model to use (can be configured per campaign)
    const modelName = state.task?.input?.aiModel || 'gpt-4o';
    const temperature = 0.35; // Sweet spot for creative but focused output

    let model: ChatOpenAI | ChatAnthropic;

    if (modelName.startsWith('claude')) {
      model = new ChatAnthropic({
        modelName,
        temperature,
      });
    } else {
      model = new ChatOpenAI({
        modelName,
        temperature,
      });
    }

    // Build context from research and enrichment
    const context = {
      lead: {
        name: `${state.lead.firstName} ${state.lead.lastName || ''}`.trim(),
        title: state.lead.jobTitle || 'Unknown',
        company: state.lead.companyName,
      },
      research: state.research || {},
      enrichment: state.enrichment?.data || {},
    };

    const prompt = `
Write a personalized cold email for this lead:

LEAD INFO:
${JSON.stringify(context, null, 2)}

CAMPAIGN CONTEXT:
${state.task?.input?.customInstructions || 'Standard B2B sales outreach'}

Remember: Only use facts from the data above. Be specific, valuable, and concise.

Provide your output as JSON with subject, body, and reasoning fields.`;

    const response = await model.invoke([
      { role: 'system', content: WRITER_PROMPT },
      { role: 'user', content: prompt },
    ]);

    // Parse the email
    let personalization: AgentState['personalization'];
    try {
      const content = response.content.toString();
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        personalization = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('No JSON found in response');
      }
    } catch (parseError) {
      console.error('Failed to parse email:', parseError);
      // Fallback: extract from text
      const content = response.content.toString();
      personalization = {
        subject: 'Quick question about your team',
        body: content.substring(0, 500),
        reasoning: 'Fallback due to parsing error',
      };
    }

    const durationMs = Date.now() - startTime;

    // Log the writing
    await logAgentAction({
      tenantId: state.tenantId,
      sessionId: state.sessionId,
      agentType: 'writer',
      action: 'email_generation',
      input: { context },
      output: personalization,
      model: modelName,
      durationMs,
    });

    // Validate the email quality
    const wordCount = personalization.body.split(/\s+/).length;
    if (wordCount > 200) {
      console.warn(`Email too long: ${wordCount} words. Target: <150 words.`);
    }

    return {
      personalization,
      messages: [
        ...state.messages,
        new AIMessage(
          `Email generated. Subject: "${personalization.subject}". ` +
          `Body: ${wordCount} words. Model: ${modelName}.`
        ),
      ],
    };
  } catch (error: any) {
    console.error('Writer agent error:', error);
    return {
      errors: [...(state.errors || []), `Writer error: ${error.message}`],
    };
  }
}
