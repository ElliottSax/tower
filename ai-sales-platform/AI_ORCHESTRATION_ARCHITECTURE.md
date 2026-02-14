# AI Orchestration Architecture

Deep dive into the multi-agent AI system powering the platform.

## Overview

The AI orchestration layer is the **core differentiator** of this platform. Unlike competitors that use simple templates or single-model generation, we implement a **multi-agent system** using LangGraph's supervisor pattern.

### Why Multi-Agent vs. Single Model?

| Approach | Pros | Cons |
|----------|------|------|
| **Single Model** | Simple, fast, cheap | Limited context, no specialization, hallucinations |
| **Multi-Agent** | Specialized expertise, better quality, modular | More complex, slower, higher cost |

Our choice: **Multi-agent for quality**, with optimization for cost.

---

## Architecture: Supervisor Pattern

```
                    ┌─────────────────┐
                    │   SUPERVISOR    │
                    │     Agent       │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
       ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
       │RESEARCHER│     │ENRICHER │     │ WRITER  │
       │  Agent  │     │  Agent  │     │  Agent  │
       └─────────┘     └─────────┘     └─────────┘
            │                │                │
            └────────────────┴────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Shared State   │
                    │  (AgentState)   │
                    └─────────────────┘
```

### Supervisor Agent

**Role:** Orchestrates the workflow by routing tasks to specialized agents.

**How it works:**
1. Receives high-level task (e.g., "Find and personalize outreach for this lead")
2. Analyzes current state (what data do we have?)
3. Decides which agent should act next
4. Routes to that agent
5. Receives result
6. Repeats until task complete

**Decision Logic:**
```typescript
function decidNextAgent(state: AgentState): AgentType {
  // Need company/person info? → RESEARCHER
  if (needsResearch(state)) return 'researcher';

  // Have basic info but need contacts? → ENRICHER
  if (needsEnrichment(state)) return 'enricher';

  // Have all data, need email? → WRITER
  if (needsPersonalization(state)) return 'writer';

  // Uncertain decision? → HUMAN
  if (needsHumanInput(state)) return 'human';

  // Done!
  return 'END';
}
```

**Key Code:** `src/agents/supervisor.ts`

### Researcher Agent

**Role:** Finds information about leads and companies.

**Data Sources:**
- Web search (via Tavily API)
- Company websites
- News APIs
- LinkedIn (when available)
- Crunchbase API
- Recent funding/hiring data

**What it finds:**
```typescript
interface ResearchResult {
  companyInfo: {
    industry: string;
    size: string;
    description: string;
  };
  personInfo: {
    role: string;
    responsibilities: string[];
  };
  recentNews: string[];         // "TechCorp raised $10M Series A"
  painPoints: string[];          // "Scaling from 5 to 20 SDRs"
  buyingSignals: string[];       // "Hiring 4 new sales reps"
}
```

**Model Configuration:**
- Model: GPT-4o-mini (cost-effective for research)
- Temperature: 0.3 (focused, factual)
- Max tokens: 1000

**Cost per research:** ~$0.01

**Key Code:** `src/agents/researcher.ts`

### Enricher Agent

**Role:** Finds accurate contact details through waterfall enrichment.

**How it works:**
```typescript
// Try providers in priority order (cost-effectiveness)
async function enrich(lead) {
  // 1. Try Apollo first ($0.47, good coverage)
  const apolloResult = await apollo.lookup(lead);
  if (isValid(apolloResult)) return apolloResult;

  // 2. Try Clearbit ($0.71, high accuracy)
  const clearbitResult = await clearbit.lookup(lead);
  if (isValid(clearbitResult)) return clearbitResult;

  // 3. Try ZoomInfo ($0.85, premium data)
  const zoomInfoResult = await zoomInfo.lookup(lead);
  if (isValid(zoomInfoResult)) return zoomInfoResult;

  // 4. Last resort: web scraping
  const scrapedResult = await scraper.lookup(lead);
  return scrapedResult;
}
```

**Coverage by provider:**
- Apollo alone: 40-50%
- Apollo + Clearbit: 70-75%
- Apollo + Clearbit + ZoomInfo: 80-85%
- + Web scraping: 90%+

**Cost optimization:**
- 80% of leads found via Apollo ($0.47 avg)
- 15% require Clearbit ($0.71 avg)
- 5% require ZoomInfo ($0.85 avg)
- **Weighted average: $0.53 per enriched lead**

vs. using only ZoomInfo: $0.85 per lead ❌

**Key Code:** `src/services/enrichment/waterfall.ts`

### Writer Agent

**Role:** Creates highly personalized outreach emails.

**Input:**
- Lead info (name, title, company)
- Research findings (buying signals, pain points)
- Enrichment data (verified contact info)
- Campaign context (product, value prop)

**Output:**
```typescript
interface EmailOutput {
  subject: string;
  body: string;
  reasoning: string;  // Why this approach
}
```

**Model Selection by Complexity:**

```typescript
// 80% of emails → GPT-4o-mini ($0.003 each)
const simplePersonalization = {
  model: 'gpt-4o-mini',
  use: 'Standard outreach with basic personalization',
  cost: 0.003,
};

// 15% of emails → GPT-4o ($0.08 each)
const complexPersonalization = {
  model: 'gpt-4o',
  use: 'High-value accounts, complex value props',
  cost: 0.08,
};

// 5% of emails → Claude Opus ($0.40 each)
const premiumPersonalization = {
  model: 'claude-opus',
  use: 'Enterprise deals, creative approaches',
  cost: 0.40,
};

// Average cost per email: $0.04
```

**Quality Assurance:**
```typescript
function validateEmail(email: EmailOutput): QualityScore {
  const checks = {
    wordCount: email.body.split(/\s+/).length,      // Target: 100-150
    hasPersonalization: containsLeadDetails(email), // Must: true
    noHallucinations: factsAreVerified(email),      // Must: true
    hasCTA: containsCallToAction(email),            // Must: true
    toneAppropriate: analyzeTone(email),            // Check: professional
  };

  return calculateScore(checks); // 0-100
}
```

**Prompt Engineering:**
```typescript
const WRITER_PROMPT = `
You are an expert B2B sales copywriter.
Your emails achieve 40%+ open rates and 8%+ reply rates.

Key principles:
1. NEVER invent facts. Only use provided information.
2. Be specific, not generic. Reference actual details.
3. Lead with value, not your product.
4. Keep it under 150 words.
5. End with a clear, low-friction CTA.
6. No clichés ("hope you're well").

Bad example:
"Hi John, hope this email finds you well..."

Good example:
"Hi John, saw you're hiring 4 new SDRs. Onboarding
that many reps while maintaining quality is tough -
we helped Acme cut ramp time 40% when they scaled
from 5 to 20 reps. Worth a quick chat?"
`;
```

**Key Code:** `src/agents/writer.ts`

---

## State Management

All agents share a common state object that flows through the system.

```typescript
interface AgentState {
  // Conversation history
  messages: BaseMessage[];

  // Context
  tenantId: string;
  sessionId: string;

  // Current task
  task?: {
    type: 'research' | 'enrich' | 'personalize';
    input: any;
  };

  // Data being processed
  lead?: {
    email?: string;
    firstName?: string;
    // ... other fields
  };

  // Results from each agent
  research?: ResearchResult;
  enrichment?: EnrichmentResult;
  personalization?: EmailOutput;

  // Routing
  nextAgent?: 'researcher' | 'enricher' | 'writer' | 'END';

  // Error handling
  errors?: string[];

  // Cost tracking
  tokensUsed?: number;
}
```

**State updates are immutable:**
```typescript
// ❌ Bad: mutating state
state.lead.email = "new@email.com";

// ✅ Good: returning new state
return {
  ...state,
  lead: {
    ...state.lead,
    email: "new@email.com"
  }
};
```

**State persistence:**
- In-memory during execution
- Saved to `agent_logs` table after completion
- Enables debugging and transparency

---

## LangGraph Implementation

### Graph Construction

```typescript
import { StateGraph } from '@langchain/langgraph';

const workflow = new StateGraph<AgentState>({
  channels: {
    messages: {
      value: (left, right) => left.concat(right),
      default: () => [],
    },
    // ... other channels
  },
});

// Add nodes (agents)
workflow.addNode('supervisor', supervisorNode);
workflow.addNode('researcher', researcherNode);
workflow.addNode('enricher', enricherNode);
workflow.addNode('writer', writerNode);

// Define edges (routing)
workflow.addConditionalEdges(
  'supervisor',
  (state) => state.nextAgent,
  {
    researcher: 'researcher',
    enricher: 'enricher',
    writer: 'writer',
    END: END,
  }
);

// After each agent, return to supervisor
workflow.addEdge('researcher', 'supervisor');
workflow.addEdge('enricher', 'supervisor');
workflow.addEdge('writer', 'supervisor');

// Set entry point
workflow.setEntryPoint('supervisor');

const app = workflow.compile();
```

### Execution Flow

```typescript
// 1. Initialize state
const initialState: AgentState = {
  messages: [new HumanMessage('Personalize outreach for this lead')],
  tenantId: 'abc123',
  sessionId: 'session-xyz',
  task: { type: 'personalize', input: { ... } },
  lead: { email: 'john@example.com', ... },
};

// 2. Execute graph
const result = await app.invoke(initialState);

// 3. Result contains final state
console.log(result.personalization);
// {
//   subject: "Quick question about your SDR team",
//   body: "Hi John...",
//   reasoning: "..."
// }
```

### Human-in-the-Loop

```typescript
workflow.addConditionalEdges(
  'supervisor',
  (state) => {
    // Check if decision needs human approval
    if (state.enrichment.confidence < 70) {
      return 'human'; // Pause workflow, wait for approval
    }
    return state.nextAgent;
  },
  {
    human: END,  // Wait for human input
    // ... other routes
  }
);
```

When paused for human input:
```typescript
// Get paused state
const pausedState = await getSessionState(sessionId);

// Show user the data for review
UI.showDataReview(pausedState.enrichment);

// User approves → resume workflow
const resumedState = {
  ...pausedState,
  nextAgent: 'writer', // Continue to writer
};

await app.invoke(resumedState);
```

---

## Cost Optimization Strategies

### 1. Model Routing

Route requests to cheaper models when possible:

```typescript
function selectModel(task: Task): ModelConfig {
  if (task.complexity === 'simple') {
    return { model: 'gpt-4o-mini', cost: 0.003 };
  } else if (task.value > 10000) {
    return { model: 'claude-opus', cost: 0.40 };
  } else {
    return { model: 'gpt-4o', cost: 0.08 };
  }
}
```

**Savings:** 75% cost reduction vs. always using GPT-4o

### 2. Prompt Caching

Cache common system prompts:

```typescript
// Claude supports prompt caching
const cachedPrompt = {
  system: WRITER_PROMPT,  // Cached (81% discount)
  user: leadSpecificData, // Not cached
};

// First request: $0.40
// Subsequent requests: $0.08 (cached portion)
```

**Savings:** 81% on cached tokens

### 3. Batch Processing

Process multiple leads in parallel:

```typescript
const leads = await getUnprocessedLeads(100);

// Process in batches of 10
for (let i = 0; i < leads.length; i += 10) {
  const batch = leads.slice(i, i + 10);

  await Promise.all(
    batch.map(lead => processLead(lead))
  );
}
```

**Savings:** Reduced API overhead, faster completion

### 4. Result Caching

Cache enrichment results:

```typescript
// Check cache first
const cached = await redis.get(`enrich:${email}`);
if (cached) return JSON.parse(cached);

// Not cached → enrich
const result = await waterfallEnrich({ email });

// Cache for 30 days
await redis.setex(`enrich:${email}`, 86400 * 30, JSON.stringify(result));

return result;
```

**Savings:** $0.50 per cached lookup

### 5. Selective Enrichment

Only enrich high-scoring leads:

```typescript
const score = await scoreLeadQuality(lead);

if (score < 50) {
  // Low quality → skip enrichment
  return { skipped: true, reason: 'low_quality' };
}

// High quality → proceed with full enrichment
return await waterfallEnrich(lead);
```

**Savings:** 30-40% of enrichment costs

---

## Error Handling

### Agent-Level Errors

```typescript
async function enricherAgent(state: AgentState) {
  try {
    const result = await waterfallEnrich(state.lead);
    return { enrichment: result };
  } catch (error) {
    // Don't crash - log error and continue
    return {
      errors: [...state.errors, `Enricher: ${error.message}`],
    };
  }
}
```

### Retry Logic

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3
): Promise<T> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;

      // Exponential backoff
      await sleep(Math.pow(2, i) * 1000);
    }
  }
}

// Usage
const result = await withRetry(() =>
  apollo.lookup(email)
);
```

### Fallback Strategies

```typescript
// Primary: GPT-4o
let email;
try {
  email = await generateWithGPT4(lead);
} catch (error) {
  // Fallback: Use template
  email = applyTemplate(lead, emailTemplate);
}
```

---

## Monitoring & Observability

### Agent Logging

Every agent action is logged for transparency:

```typescript
await logAgentAction({
  tenantId,
  sessionId,
  agentType: 'writer',
  action: 'email_generation',
  input: { lead, research },
  output: { email },
  model: 'gpt-4o-mini',
  tokensUsed: 850,
  durationMs: 1250,
});
```

### Metrics to Track

```typescript
const metrics = {
  // Performance
  avgExecutionTime: 15000,        // 15s per workflow
  p95ExecutionTime: 30000,        // 30s at P95
  successRate: 0.95,              // 95% success

  // Quality
  avgEmailQuality: 8.2,           // 0-10 scale
  avgEnrichmentConfidence: 78,    // 0-100
  hallcinationRate: 0.01,         // 1% (target: <2%)

  // Cost
  avgCostPerLead: 0.57,           // $0.57 total
  tokensPerLead: 12000,           // 12K tokens avg
  enrichmentCoverage: 0.82,       // 82% enriched

  // Errors
  errorRate: 0.05,                // 5% errors
  timeoutRate: 0.02,              // 2% timeouts
};
```

### Debugging Tools

```typescript
// Get full execution log for a session
const logs = await getSessionLogs(sessionId);

logs.forEach(log => {
  console.log(`[${log.agentType}] ${log.action}`);
  console.log('Input:', log.input);
  console.log('Output:', log.output);
  console.log('Duration:', log.durationMs, 'ms');
  console.log('---');
});
```

---

## Testing the AI System

### Unit Tests (Individual Agents)

```typescript
describe('Writer Agent', () => {
  it('generates personalized email', async () => {
    const state = {
      lead: {
        firstName: 'John',
        companyName: 'Acme Corp',
      },
      research: {
        buyingSignals: ['Hiring 4 SDRs'],
      },
    };

    const result = await writerAgent(state);

    expect(result.personalization).toBeDefined();
    expect(result.personalization.subject).toContain('SDR');
    expect(result.personalization.body.length).toBeLessThan(1000);
  });
});
```

### Integration Tests (Full Workflow)

```typescript
describe('Full AI Workflow', () => {
  it('processes lead end-to-end', async () => {
    const result = await supervisorAgent.execute({
      tenantId: 'test',
      task: { type: 'personalize' },
      lead: {
        email: 'test@example.com',
        firstName: 'Test',
        companyName: 'Test Corp',
      },
    });

    expect(result.research).toBeDefined();
    expect(result.enrichment).toBeDefined();
    expect(result.personalization).toBeDefined();
    expect(result.errors.length).toBe(0);
  });
});
```

### Manual Testing

See QUICK_START.md for curl commands to test each endpoint.

---

## Future Enhancements

### 1. Learning from Outcomes

```typescript
// Track which emails get replies
const repliedEmails = await db
  .select()
  .from(emailMessages)
  .where(isNotNull(emailMessages.repliedAt));

// Analyze patterns
const successPatterns = await analyzeSuccessfulEmails(repliedEmails);

// Feed back into writer prompt
const enhancedPrompt = `
${WRITER_PROMPT}

Patterns from successful emails:
${successPatterns}
`;
```

### 2. Multi-Touch Sequences

```typescript
// Agent decides entire sequence
const sequence = await sequenceAgent.plan({
  lead,
  research,
  goalReplies: 1,
});

// Returns:
// [
//   { day: 0, type: 'intro', ... },
//   { day: 3, type: 'value', ... },
//   { day: 7, type: 'case_study', ... },
// ]
```

### 3. A/B Test Orchestration

```typescript
const variants = [
  { strategy: 'pain_point_focus', agent: writerAgentV1 },
  { strategy: 'value_prop_focus', agent: writerAgentV2 },
];

// Supervisor routes to different agents
const variant = selectVariant(campaign);
const result = await variant.agent(state);
```

---

## Conclusion

The AI orchestration layer is complex but provides significant advantages:

**Quality:**
- Specialized agents > single model
- Research + enrichment > AI guessing
- Structured output > unstructured generation

**Cost:**
- Smart routing reduces costs 75%
- Caching reduces costs 80%+
- Waterfall reduces enrichment costs 30%

**Transparency:**
- Every decision logged
- Full audit trail
- Debuggable workflows

**Flexibility:**
- Easy to add new agents
- Easy to swap models
- Easy to customize per customer

This architecture is the foundation for a world-class AI sales platform.
