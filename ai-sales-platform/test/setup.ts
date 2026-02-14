/**
 * Vitest setup file
 * Runs before all tests - mocks external dependencies
 */

import { beforeAll, afterAll, afterEach, vi } from 'vitest';

// Mock environment variables
beforeAll(() => {
  process.env.NODE_ENV = 'test';
  process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
});

// Clean up after each test - clear pending timers and mocks
afterEach(() => {
  vi.clearAllTimers();
  vi.clearAllMocks();
});

// Cleanup
afterAll(() => {
  vi.restoreAllMocks();
  vi.useRealTimers();
});

// Mock LangChain OpenAI model
// Return invalid JSON so workers use their comprehensive fallback strategies
vi.mock('@langchain/openai', () => ({
  ChatOpenAI: vi.fn().mockImplementation(() => ({
    modelName: 'gpt-4o-mini',
    invoke: vi.fn().mockRejectedValue(new Error('API not available in test')),
  })),
}));

// Mock LangChain Anthropic model
vi.mock('@langchain/anthropic', () => ({
  ChatAnthropic: vi.fn().mockImplementation(() => ({
    modelName: 'claude-sonnet-4-5-20250929',
    invoke: vi.fn().mockRejectedValue(new Error('API not available in test')),
  })),
}));

// Mock LangChain core messages (used by workers)
vi.mock('@langchain/core/messages', () => ({
  HumanMessage: vi.fn().mockImplementation((content) => ({ content, type: 'human' })),
  SystemMessage: vi.fn().mockImplementation((content) => ({ content, type: 'system' })),
  AIMessage: vi.fn().mockImplementation((content) => ({ content, type: 'ai' })),
  BaseMessage: vi.fn(),
}));

// Mock LangGraph (used by orchestrator - prevents heavy module loading)
vi.mock('@langchain/langgraph', () => ({
  StateGraph: vi.fn().mockImplementation(() => ({
    addNode: vi.fn().mockReturnThis(),
    addEdge: vi.fn().mockReturnThis(),
    addConditionalEdges: vi.fn().mockReturnThis(),
    compile: vi.fn().mockReturnValue({
      invoke: vi.fn().mockResolvedValue({}),
    }),
  })),
  END: '__end__',
}));

// Mock LangGraph checkpoint (prevents pg Pool connection attempts)
vi.mock('@langchain/langgraph-checkpoint-postgres', () => ({
  PostgresSaver: vi.fn().mockImplementation(() => ({
    setup: vi.fn().mockResolvedValue(undefined),
  })),
}));

// Mock pg Pool (prevents actual database connections)
vi.mock('pg', () => ({
  Pool: vi.fn().mockImplementation(() => ({
    connect: vi.fn().mockResolvedValue({
      query: vi.fn().mockResolvedValue({ rows: [] }),
      release: vi.fn(),
    }),
    query: vi.fn().mockResolvedValue({ rows: [] }),
    end: vi.fn().mockResolvedValue(undefined),
    on: vi.fn(),
  })),
}));

// Mock Sentry (prevents initialization and background flush timers)
vi.mock('@sentry/node', () => ({
  init: vi.fn(),
  captureException: vi.fn(),
  captureMessage: vi.fn(),
  addBreadcrumb: vi.fn(),
  setUser: vi.fn(),
  setTag: vi.fn(),
  withScope: vi.fn((cb) => cb({ setContext: vi.fn() })),
  close: vi.fn().mockResolvedValue(true),
}));

vi.mock('@sentry/profiling-node', () => ({}));

// Mock axios for external API calls
vi.mock('axios', () => ({
  default: {
    post: vi.fn().mockResolvedValue({ data: {} }),
    get: vi.fn().mockResolvedValue({ data: {} }),
    create: vi.fn().mockReturnValue({
      post: vi.fn().mockResolvedValue({ data: {} }),
      get: vi.fn().mockResolvedValue({ data: {} }),
    }),
  },
}));

// Mock ioredis (prevents Redis connection attempts)
vi.mock('ioredis', () => {
  const RedisMock = vi.fn().mockImplementation(() => ({
    connect: vi.fn().mockResolvedValue(undefined),
    disconnect: vi.fn().mockResolvedValue(undefined),
    quit: vi.fn().mockResolvedValue(undefined),
    get: vi.fn().mockResolvedValue(null),
    set: vi.fn().mockResolvedValue('OK'),
    del: vi.fn().mockResolvedValue(1),
    on: vi.fn(),
    status: 'ready',
  }));
  return { default: RedisMock, Redis: RedisMock };
});

// Mock BullMQ (prevents Redis-backed queue connections)
vi.mock('bullmq', () => ({
  Queue: vi.fn().mockImplementation(() => ({
    add: vi.fn().mockResolvedValue({ id: 'mock-job-id' }),
    close: vi.fn().mockResolvedValue(undefined),
    on: vi.fn(),
  })),
  Worker: vi.fn().mockImplementation(() => ({
    close: vi.fn().mockResolvedValue(undefined),
    on: vi.fn(),
  })),
  QueueScheduler: vi.fn().mockImplementation(() => ({
    close: vi.fn().mockResolvedValue(undefined),
    on: vi.fn(),
  })),
}));

export {};
