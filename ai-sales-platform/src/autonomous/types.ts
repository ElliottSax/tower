import { BaseMessage } from '@langchain/core/messages';

/**
 * Autonomous Business Platform - Type Definitions
 *
 * Hierarchical Multi-Agent System:
 * CEO Agent → Manager Agents (Product, Marketing, Operations, Finance) → Worker Agents
 */

// ===== Business State =====

export interface BusinessIdea {
  description: string;
  targetMarket: string;
  problemSolved: string;
  monetizationModel?: string;
}

export interface BusinessState {
  messages: BaseMessage[];
  tenantId: string;
  sessionId: string;

  // Business context
  idea: BusinessIdea;
  businessName?: string;

  // Formation status
  formation?: {
    validated: boolean;
    legalStructure?: 'sole_proprietorship' | 'llc' | 'c_corp' | 's_corp' | 'none';
    incorporated: boolean; // Optional - only if legalStructure requires it
    bankingSetup: boolean;
    paymentsSetup: boolean;
    companyId?: string;
    ein?: string;
  };

  // Product status
  product?: {
    specificationsDefined: boolean;
    mvpBuilt: boolean;
    deployed: boolean;
    productUrl?: string;
    repositoryUrl?: string;
  };

  // Marketing status
  marketing?: {
    strategyDefined: boolean;
    contentCreated: boolean;
    adsLaunched: boolean;
    seoOptimized: boolean;
  };

  // Operations status
  operations?: {
    supportSetup: boolean;
    analyticsSetup: boolean;
    monitoringSetup: boolean;
  };

  // Finance status
  finance?: {
    bookkeepingSetup: boolean;
    revenueTracking: boolean;
    expenseTracking: boolean;
    monthlyRevenue?: number;
    monthlyExpenses?: number;
  };

  // Execution tracking
  currentPhase: BusinessPhase;
  nextAgent?: AgentType;
  completedTasks: string[];
  pendingTasks: Task[];

  // Error handling
  errors?: string[];

  // Cost tracking
  totalCost?: number;
  estimatedMonthlyCost?: number;
}

export type BusinessPhase =
  | 'validation'       // Idea validation
  | 'formation'        // Company incorporation & banking
  | 'product'          // MVP development
  | 'marketing'        // Marketing launch
  | 'operations'       // Support & analytics
  | 'optimization'     // Growth & optimization
  | 'completed';

export type AgentType =
  | 'ceo'
  | 'product_manager'
  | 'marketing_manager'
  | 'operations_manager'
  | 'finance_manager'
  | 'developer_worker'
  | 'content_worker'
  | 'ads_worker'
  | 'support_worker'
  | 'bookkeeper_worker'
  | 'human'
  | 'END';

// ===== Task Management =====

export interface Task {
  id: string;
  type: TaskType;
  description: string;
  assignedTo?: AgentType;
  status: 'pending' | 'in_progress' | 'completed' | 'failed';
  dependencies?: string[]; // IDs of tasks that must complete first
  result?: any;
  error?: string;
  estimatedCost?: number;
  actualCost?: number;
}

export type TaskType =
  // Validation
  | 'validate_idea'
  | 'research_market'
  | 'analyze_competition'

  // Formation
  | 'incorporate_company'
  | 'setup_banking'
  | 'setup_payments'

  // Product
  | 'define_specifications'
  | 'generate_code'
  | 'deploy_mvp'
  | 'setup_infrastructure'

  // Marketing
  | 'define_marketing_strategy'
  | 'create_content'
  | 'launch_ads'
  | 'optimize_seo'

  // Operations
  | 'setup_support'
  | 'setup_analytics'
  | 'monitor_performance'

  // Finance
  | 'setup_bookkeeping'
  | 'track_revenue'
  | 'track_expenses'
  | 'generate_reports';

// ===== Agent Configuration =====

export interface AgentConfig {
  name: string;
  role: AgentType;
  systemPrompt: string;
  modelName: string;
  temperature: number;
  maxTokens?: number;
  tools?: AgentTool[];
}

export interface AgentTool {
  name: string;
  description: string;
  execute: (input: any, state: BusinessState) => Promise<any>;
  estimatedCost?: number;
}

// ===== Manager Agent Capabilities =====

export interface ManagerCapabilities {
  canDelegate: boolean;
  subordinates: AgentType[];
  maxConcurrentTasks: number;
  decisionAuthority: 'strategic' | 'tactical' | 'operational';
}

// ===== External Service Integrations =====

export interface DoolaIntegration {
  incorporateCompany(businessName: string, state: string): Promise<{
    companyId: string;
    ein: string;
    status: string;
    cost: number;
  }>;
}

export interface MercuryIntegration {
  setupBanking(companyId: string, ein: string): Promise<{
    accountId: string;
    accountNumber: string;
    routingNumber: string;
  }>;
}

export interface ReplitIntegration {
  generateApp(specifications: string): Promise<{
    repositoryUrl: string;
    deploymentUrl?: string;
    estimatedCompletionDays: number;
  }>;
}

export interface MetaAIIntegration {
  createAdCampaign(product: any, budget: number): Promise<{
    campaignId: string;
    estimatedReach: number;
    cost: number;
  }>;
}

export interface FinAIIntegration {
  setupSupport(productUrl: string): Promise<{
    chatbotUrl: string;
    expectedAutomationRate: number;
  }>;
}

export interface RampAIIntegration {
  setupBookkeeping(companyId: string): Promise<{
    dashboardUrl: string;
    expectedAccuracy: number;
  }>;
}

// ===== Checkpointing & Persistence =====

export interface Checkpoint {
  sessionId: string;
  timestamp: Date;
  state: BusinessState;
  agentType: AgentType;
  action: string;
}

// ===== Agent Response Types =====

export interface AgentDecision {
  action: 'delegate' | 'execute' | 'escalate' | 'complete';
  nextAgent?: AgentType;
  tasks?: Task[];
  reasoning: string;
  estimatedCost?: number;
  estimatedDuration?: string;
  requiresHumanApproval?: boolean;
}

// ===== Metrics & Monitoring =====

export interface BusinessMetrics {
  timeToIncorporation?: number; // days
  timeToMVP?: number; // days
  timeToFirstCustomer?: number; // days
  timeToRevenue?: number; // days
  totalCostToLaunch?: number;
  monthlyOperatingCost?: number;
  monthlyRevenue?: number;
  customerCount?: number;
  automationRate?: number; // percentage of tasks automated
}
