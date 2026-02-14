// Database imports - uncomment when enabling production logging
// import { db } from './db';
// import { agentLogs } from '../db/schema';

/**
 * Agent Action Logging
 *
 * Provides full transparency into AI agent behavior:
 * - What action was taken
 * - What input was provided
 * - What output was generated
 * - Which model was used
 * - How many tokens were consumed
 * - How long it took
 *
 * This transparency is a key differentiator vs. competitors.
 */

export interface LogAgentActionParams {
  tenantId: string;
  sessionId: string;
  agentType: 'supervisor' | 'researcher' | 'enricher' | 'writer';
  action: string;
  input: any;
  output: any;
  model: string;
  tokensUsed?: number;
  durationMs: number;
  error?: string;
}

export async function logAgentAction(params: LogAgentActionParams): Promise<void> {
  try {
    // In production, this would insert into the database
    // For now, we'll just console log with structured format
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      type: 'agent_action',
      ...params,
    }, null, 2));

    /* In production:
    await db.insert(agentLogs).values({
      tenantId: params.tenantId,
      sessionId: params.sessionId,
      agentType: params.agentType,
      action: params.action,
      input: params.input,
      output: params.output,
      model: params.model,
      tokensUsed: params.tokensUsed,
      durationMs: params.durationMs,
      error: params.error,
    });
    */
  } catch (error) {
    console.error('Failed to log agent action:', error);
    // Don't throw - logging failures shouldn't break the app
  }
}

/**
 * Get agent logs for a session (for debugging and transparency UI)
 */
export async function getSessionLogs(sessionId: string): Promise<any[]> {
  // In production:
  // return db.select().from(agentLogs).where(eq(agentLogs.sessionId, sessionId));

  return [];
}
