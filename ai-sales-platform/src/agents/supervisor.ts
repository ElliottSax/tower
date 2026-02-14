import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage, BaseMessage } from '@langchain/core/messages';
import { StateGraph, END } from '@langchain/langgraph';
import { AgentState, ModelConfig } from './types';
import { researcherAgent } from './researcher';
import { enricherAgent } from './enricher';
import { writerAgent } from './writer';
import { logAgentAction } from '../utils/logging';

/**
 * Supervisor Agent - Routes tasks to specialized agents
 *
 * This is the main orchestrator that:
 * 1. Receives high-level tasks (e.g., "Find and personalize outreach for this lead")
 * 2. Breaks them down into subtasks
 * 3. Routes to specialized agents (researcher, enricher, writer)
 * 4. Combines results and returns final output
 */

const SUPERVISOR_PROMPT = `You are a sales automation supervisor coordinating a team of specialized AI agents.

Your team consists of:
- RESEARCHER: Finds information about leads, companies, and buying signals
- ENRICHER: Looks up contact details and company data from multiple sources
- WRITER: Creates personalized outreach messages

Based on the current task and state, decide which agent should act next.

Current state:
{state}

Rules:
1. If we need to find information about a company or person, route to RESEARCHER
2. If we have basic info but need full contact details, route to ENRICHER
3. If we have all necessary data and need to write a message, route to WRITER
4. If task is complete or we have errors, route to END
5. If you need human input for a decision, route to HUMAN

Respond with ONLY the agent name: RESEARCHER, ENRICHER, WRITER, HUMAN, or END`;

export class SupervisorAgent {
  private model: ChatOpenAI | ChatAnthropic;
  private graph: StateGraph<AgentState>;

  constructor(config: ModelConfig = {
    modelName: 'gpt-4o-mini',
    temperature: 0.3,
  }) {
    // Initialize the LLM
    if (config.modelName.startsWith('claude')) {
      this.model = new ChatAnthropic({
        modelName: config.modelName,
        temperature: config.temperature,
      });
    } else {
      this.model = new ChatOpenAI({
        modelName: config.modelName,
        temperature: config.temperature,
      });
    }

    // Build the agent graph
    this.graph = this.buildGraph();
  }

  /**
   * Main supervisor logic - decides which agent to route to next
   */
  private async supervisorNode(state: AgentState): Promise<Partial<AgentState>> {
    const startTime = Date.now();

    try {
      // Prepare state summary for the supervisor
      const stateSummary = JSON.stringify({
        task: state.task,
        hasLead: !!state.lead,
        hasResearch: !!state.research,
        hasEnrichment: !!state.enrichment,
        hasPersonalization: !!state.personalization,
        errors: state.errors,
      }, null, 2);

      const prompt = SUPERVISOR_PROMPT.replace('{state}', stateSummary);

      const messages = [
        new SystemMessage(prompt),
        ...state.messages,
      ];

      const response = await this.model.invoke(messages);
      const content = response.content.toString().trim().toUpperCase();

      // Parse the response to determine next agent
      let nextAgent: AgentState['nextAgent'] = 'END';

      if (content.includes('RESEARCHER')) {
        nextAgent = 'researcher';
      } else if (content.includes('ENRICHER')) {
        nextAgent = 'enricher';
      } else if (content.includes('WRITER')) {
        nextAgent = 'writer';
      } else if (content.includes('HUMAN')) {
        nextAgent = 'human';
      } else {
        nextAgent = 'END';
      }

      const durationMs = Date.now() - startTime;

      // Log the decision
      await logAgentAction({
        tenantId: state.tenantId,
        sessionId: state.sessionId,
        agentType: 'supervisor',
        action: 'route_decision',
        input: { stateSummary },
        output: { nextAgent, reasoning: content },
        model: (this.model as any).modelName,
        durationMs,
      });

      return {
        nextAgent,
        messages: [...state.messages, response],
      };
    } catch (error: any) {
      console.error('Supervisor error:', error);
      return {
        nextAgent: 'END',
        errors: [...(state.errors || []), `Supervisor error: ${error.message}`],
      };
    }
  }

  /**
   * Builds the LangGraph workflow
   */
  private buildGraph(): StateGraph<AgentState> {
    const workflow = new StateGraph<AgentState>({
      channels: {
        messages: {
          value: (left: BaseMessage[], right: BaseMessage[]) => left.concat(right),
          default: () => [],
        },
        tenantId: null,
        sessionId: null,
        task: null,
        lead: null,
        research: null,
        enrichment: null,
        personalization: null,
        nextAgent: null,
        errors: {
          value: (left: string[], right: string[]) => left.concat(right),
          default: () => [],
        },
        tokensUsed: {
          value: (left: number, right: number) => (left || 0) + (right || 0),
          default: () => 0,
        },
      },
    });

    // Add all agent nodes
    workflow.addNode('supervisor', (state) => this.supervisorNode(state));
    workflow.addNode('researcher', researcherAgent);
    workflow.addNode('enricher', enricherAgent);
    workflow.addNode('writer', writerAgent);

    // Define routing logic
    workflow.addConditionalEdges(
      'supervisor',
      (state: AgentState) => state.nextAgent || 'END',
      {
        researcher: 'researcher',
        enricher: 'enricher',
        writer: 'writer',
        human: END, // Human intervention ends the automated flow
        END: END,
      }
    );

    // After each specialist agent, go back to supervisor
    workflow.addEdge('researcher', 'supervisor');
    workflow.addEdge('enricher', 'supervisor');
    workflow.addEdge('writer', 'supervisor');

    // Set the entry point
    workflow.setEntryPoint('supervisor');

    return workflow;
  }

  /**
   * Execute a task through the multi-agent system
   */
  async execute(input: {
    tenantId: string;
    task: AgentState['task'];
    lead?: AgentState['lead'];
  }): Promise<AgentState> {
    const sessionId = crypto.randomUUID();

    const initialState: AgentState = {
      messages: [new HumanMessage(`Task: ${JSON.stringify(input.task)}`)],
      tenantId: input.tenantId,
      sessionId,
      task: input.task,
      lead: input.lead,
    };

    try {
      const app = this.graph.compile();
      const result = await app.invoke(initialState);

      return result as AgentState;
    } catch (error: any) {
      console.error('Agent execution error:', error);
      return {
        ...initialState,
        nextAgent: 'END',
        errors: [`Execution error: ${error.message}`],
      };
    }
  }
}

// Export singleton instance
export const supervisorAgent = new SupervisorAgent();
