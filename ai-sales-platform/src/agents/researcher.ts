import { ChatOpenAI } from '@langchain/openai';
import { HumanMessage, AIMessage } from '@langchain/core/messages';
import { AgentState } from './types';
import { logAgentAction } from '../utils/logging';
import { TavilySearchResults } from '@langchain/community/tools/tavily_search';

/**
 * Researcher Agent - Finds information about leads and companies
 *
 * Capabilities:
 * - Company research (industry, size, recent news)
 * - Person research (role, background, recent activity)
 * - Buying signals detection
 * - Pain point identification
 */

const RESEARCHER_PROMPT = `You are an expert B2B sales researcher. Your job is to find relevant, actionable information about leads and their companies.

When researching, focus on:
1. Company information (industry, size, recent news, growth signals)
2. Person's role and responsibilities
3. Pain points the company might be facing
4. Buying signals (hiring, funding, expansion, technology changes)
5. Recent company news or initiatives

Output your findings in a structured JSON format:
{
  "companyInfo": {
    "industry": "...",
    "size": "...",
    "description": "..."
  },
  "personInfo": {
    "role": "...",
    "responsibilities": "..."
  },
  "recentNews": ["...", "..."],
  "painPoints": ["...", "..."],
  "buyingSignals": ["...", "..."]
}

Be concise but specific. Focus on information that would be useful for personalized outreach.`;

export async function researcherAgent(state: AgentState): Promise<Partial<AgentState>> {
  const startTime = Date.now();

  try {
    // Check if we have enough information to research
    if (!state.lead?.companyName && !state.lead?.companyDomain) {
      return {
        errors: [...(state.errors || []), 'Researcher: No company information to research'],
        nextAgent: 'END',
      };
    }

    const model = new ChatOpenAI({
      modelName: 'gpt-4o-mini',
      temperature: 0.3,
    });

    // Initialize search tool (using Tavily for web search)
    // Note: In production, you'd also integrate with:
    // - LinkedIn Sales Navigator API
    // - Crunchbase API
    // - Company websites
    // - News APIs
    const searchTool = process.env.TAVILY_API_KEY
      ? new TavilySearchResults({ maxResults: 5 })
      : null;

    let searchResults = '';

    if (searchTool) {
      // Search for company information
      const companyQuery = `${state.lead.companyName} company news funding hiring`;
      const results = await searchTool.invoke(companyQuery);
      searchResults = JSON.stringify(results);
    }

    // Build research prompt
    const researchPrompt = `
Research this lead:
- Name: ${state.lead.firstName} ${state.lead.lastName}
- Company: ${state.lead.companyName}
- Job Title: ${state.lead.jobTitle || 'Unknown'}
- Domain: ${state.lead.companyDomain || 'Unknown'}

${searchResults ? `\nWeb search results:\n${searchResults}` : ''}

Provide a structured research report following the JSON format specified.`;

    const response = await model.invoke([
      { role: 'system', content: RESEARCHER_PROMPT },
      { role: 'user', content: researchPrompt },
    ]);

    // Parse the research results
    let research: AgentState['research'];
    try {
      const content = response.content.toString();
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        research = JSON.parse(jsonMatch[0]);
      } else {
        // Fallback: create structured data from text
        research = {
          companyInfo: { description: content.substring(0, 500) },
          painPoints: [],
          buyingSignals: [],
        };
      }
    } catch (parseError) {
      console.error('Failed to parse research results:', parseError);
      research = {
        companyInfo: { description: response.content.toString().substring(0, 500) },
        painPoints: [],
        buyingSignals: [],
      };
    }

    const durationMs = Date.now() - startTime;

    // Log the research
    await logAgentAction({
      tenantId: state.tenantId,
      sessionId: state.sessionId,
      agentType: 'researcher',
      action: 'company_research',
      input: { lead: state.lead, searchQuery: searchResults ? 'web_search' : 'no_search' },
      output: research,
      model: 'gpt-4o-mini',
      durationMs,
    });

    return {
      research,
      messages: [
        ...state.messages,
        new AIMessage(`Research completed for ${state.lead.companyName}. Found ${research.buyingSignals?.length || 0} buying signals.`),
      ],
    };
  } catch (error: any) {
    console.error('Researcher agent error:', error);
    return {
      errors: [...(state.errors || []), `Researcher error: ${error.message}`],
    };
  }
}
