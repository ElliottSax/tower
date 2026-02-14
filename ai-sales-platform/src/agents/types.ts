import { BaseMessage } from '@langchain/core/messages';

// Agent state shared across all agents
export interface AgentState {
  messages: BaseMessage[];
  tenantId: string;
  sessionId: string;

  // Current task context
  task?: {
    type: 'research' | 'enrich' | 'personalize' | 'analyze';
    input: any;
  };

  // Lead data being processed
  lead?: {
    email?: string;
    firstName?: string;
    lastName?: string;
    companyName?: string;
    companyDomain?: string;
    jobTitle?: string;
    linkedinUrl?: string;
  };

  // Research results from researcher agent
  research?: {
    companyInfo?: any;
    personInfo?: any;
    recentNews?: string[];
    painPoints?: string[];
    buyingSignals?: string[];
  };

  // Enrichment results from enricher agent
  enrichment?: {
    sources: string[];
    confidence: number;
    data: any;
  };

  // Personalization from writer agent
  personalization?: {
    subject: string;
    body: string;
    reasoning: string;
  };

  // Agent routing
  nextAgent?: 'researcher' | 'enricher' | 'writer' | 'human' | 'END';

  // Error handling
  errors?: string[];

  // Token usage tracking
  tokensUsed?: number;
}

// Configuration for AI models
export interface ModelConfig {
  modelName: string;
  temperature: number;
  maxTokens?: number;
}

// Enrichment provider interface
export interface EnrichmentProvider {
  name: string;
  lookup(email: string, domain?: string): Promise<EnrichmentResult | null>;
  cost: number; // Cost per lookup
  priority: number; // Lower = higher priority
  isConfigured?(): boolean; // Whether provider has API keys configured
}

export interface EnrichmentResult {
  source: string;
  confidence: number;
  data: {
    email?: string;
    firstName?: string;
    lastName?: string;
    jobTitle?: string;
    phoneNumber?: string;
    companyName?: string;
    companySize?: string;
    companyIndustry?: string;
    linkedinUrl?: string;
    [key: string]: any;
  };
}

// Agent tool definitions
export interface AgentTool {
  name: string;
  description: string;
  execute: (input: any) => Promise<any>;
}
