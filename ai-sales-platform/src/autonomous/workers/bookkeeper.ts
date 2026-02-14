import { ChatOpenAI } from '@langchain/openai';
import { ChatAnthropic } from '@langchain/anthropic';
import { HumanMessage, SystemMessage } from '@langchain/core/messages';
import { BusinessState, Task } from '../types';
import axios from 'axios';

/**
 * Bookkeeper Worker - Manages financial tracking and bookkeeping
 *
 * Supports:
 * - Ramp AI (Automated expense management + bookkeeping)
 * - Manual tracking (Spreadsheet templates)
 * - Revenue tracking
 * - Expense categorization
 * - Tax preparation support
 */

const BOOKKEEPING_STRATEGY_PROMPT = `You are a financial management expert specializing in automated bookkeeping for startups.

## Your Task:
Set up a bookkeeping system that tracks revenue, expenses, and prepares for taxes with minimal manual work.

## Platform Options:

### Option 1: Ramp AI - Premium (Recommended for $10K+/month revenue)
- **Best for**: Growing startups, venture-backed
- **Cost**: Free card + bookkeeping, $0 monthly (earn cashback!)
- **Features**: AI expense categorization, receipt matching, accounting sync
- **Automation**: 90%+ of transactions auto-categorized
- **Setup time**: 30 minutes
- **Requirements**: Business bank account or EIN

### Option 2: QuickBooks + AI - Mid-tier
- **Best for**: Small businesses, solo proprietorships
- **Cost**: $30-90/month
- **Features**: Invoicing, expense tracking, tax prep
- **Automation**: 60-70% with AI features
- **Setup time**: 1-2 hours

### Option 3: Spreadsheet + Stripe Dashboard - Free
- **Best for**: MVPs, pre-revenue, side projects
- **Cost**: $0
- **Features**: Manual tracking, simple reports
- **Automation**: 20% (Stripe auto-tracks revenue)
- **Setup time**: 30 minutes
- **Good for**: < $5K/month revenue

## Key Metrics to Track:
1. **Revenue**: Monthly recurring revenue (MRR), one-time sales
2. **Expenses**: By category (hosting, marketing, tools, etc.)
3. **Profit**: Revenue - Expenses
4. **Cash runway**: Months of expenses you can cover
5. **Burn rate**: Monthly net cash outflow

## Expense Categories:
- Software & Tools (Stripe, hosting, AI APIs)
- Marketing & Advertising (Meta Ads, Google Ads)
- Professional Services (legal, accounting)
- Infrastructure (AWS, Vercel, database)
- Other Operating Expenses

## Tax Preparation:
- Track all deductible expenses
- Separate personal and business expenses
- Save receipts digitally
- For sole proprietorship: Use Schedule C (1040)
- For LLC/C-Corp: More complex, consider CPA

## Response Format (JSON):
{
  "recommendation": {
    "platform": "ramp_ai" | "quickbooks" | "spreadsheet",
    "reasoning": "Why this platform?",
    "monthlyCost": 0,
    "automationLevel": 90,
    "setupTime": "30 minutes"
  },
  "accountingSetup": {
    "chartOfAccounts": [
      {
        "category": "Revenue",
        "accounts": ["Product Sales", "Subscription Revenue"]
      },
      {
        "category": "Expenses",
        "accounts": ["Software & Tools", "Marketing", "Infrastructure"]
      }
    ],
    "taxStrategy": {
      "structure": "sole_proprietorship" | "llc" | "c_corp",
      "taxForm": "Schedule C" | "1120" | "1120S",
      "quarterlyEstimates": true,
      "deductions": ["home office", "software", "marketing", "travel"]
    }
  },
  "revenueTracking": {
    "sources": ["stripe", "paypal", "other"],
    "metrics": ["MRR", "ARR", "churn rate", "LTV"],
    "goals": {
      "month1": 1000,
      "month3": 5000,
      "month6": 15000
    }
  },
  "expenseTracking": {
    "categories": [
      {
        "name": "Software & Tools",
        "estimatedMonthly": 200,
        "items": ["Stripe", "Vercel", "AI APIs"]
      },
      {
        "name": "Marketing",
        "estimatedMonthly": 300,
        "items": ["Meta Ads", "Google Ads", "SEO tools"]
      }
    ],
    "totalMonthlyExpenses": 700
  },
  "dashboards": {
    "metrics": ["revenue", "expenses", "profit", "cash balance", "burn rate"],
    "frequency": "daily" | "weekly" | "monthly"
  }
}`;

export class BookkeeperWorker {
  private model: ChatOpenAI | ChatAnthropic;
  private rampApiKey?: string;
  private simulationMode: boolean = true;

  constructor(modelName: string = 'gpt-4o-mini', temperature: number = 0.5) {
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

    // Check for API keys
    this.rampApiKey = process.env.RAMP_API_KEY;
    this.simulationMode = !this.rampApiKey;

    if (this.simulationMode) {
      console.log('[Bookkeeper Worker] Running in SIMULATION mode (no API keys found)');
    }
  }

  /**
   * Setup bookkeeping system
   */
  async setupBookkeeping(state: BusinessState, task: Task): Promise<any> {
    console.log('[Bookkeeper Worker] Setting up financial tracking');

    // Step 1: Generate bookkeeping strategy using AI
    const strategy = await this.generateBookkeepingStrategy(state);

    // Step 2: Setup platform (Ramp, QuickBooks, or Spreadsheet)
    const platformSetup = await this.setupPlatform(strategy.recommendation, state);

    // Step 3: Create chart of accounts
    const accountingSetup = await this.setupAccounting(strategy.accountingSetup, state);

    // Step 4: Configure tracking
    const trackingSetup = await this.configureTracking(
      strategy.revenueTracking,
      strategy.expenseTracking,
      state
    );

    return {
      status: 'success',
      mode: this.simulationMode ? 'simulation' : 'production',
      platform: strategy.recommendation.platform,
      automationLevel: strategy.recommendation.automationLevel,
      accountingSetup,
      revenueTracking: strategy.revenueTracking,
      expenseTracking: strategy.expenseTracking,
      platformSetup,
      dashboards: strategy.dashboards,
      monthlyCost: strategy.recommendation.monthlyCost,
      nextSteps: this.getNextSteps(strategy.recommendation.platform, state),
    };
  }

  /**
   * Generate bookkeeping strategy using AI
   */
  private async generateBookkeepingStrategy(state: BusinessState): Promise<any> {
    const context = {
      business: state.idea.description,
      legalStructure: state.formation?.legalStructure || 'sole_proprietorship',
      hasEIN: !!state.formation?.ein,
      estimatedMonthlyRevenue: this.estimateRevenue(state),
      estimatedMonthlyExpenses: state.estimatedMonthlyCost || 700,
      currentPhase: state.currentPhase,
    };

    const messages = [
      new SystemMessage(BOOKKEEPING_STRATEGY_PROMPT),
      new HumanMessage(
        `Design a bookkeeping system for:\n${JSON.stringify(context, null, 2)}\n\nOptimize for automation and tax compliance.`
      ),
    ];

    try {
      const response = await this.model.invoke(messages);
      const content = response.content.toString();

      return this.parseJSON(content);
    } catch (error) {
      console.error('[Bookkeeper Worker] Error generating strategy:', error);
      return this.getFallbackStrategy(state);
    }
  }

  /**
   * Setup bookkeeping platform
   */
  private async setupPlatform(recommendation: any, state: BusinessState): Promise<any> {
    console.log('[Bookkeeper Worker] Setting up', recommendation.platform);

    if (recommendation.platform === 'ramp_ai') {
      return await this.setupRampAI(state);
    } else if (recommendation.platform === 'quickbooks') {
      return await this.setupQuickBooks(state);
    } else if (recommendation.platform === 'spreadsheet') {
      return await this.setupSpreadsheet(state);
    }

    return { status: 'unknown_platform' };
  }

  /**
   * Setup Ramp AI
   */
  private async setupRampAI(state: BusinessState): Promise<any> {
    if (this.simulationMode) {
      console.log('[Bookkeeper Worker] SIMULATING Ramp setup');
      return {
        platform: 'ramp_ai',
        status: 'simulated',
        accountId: `sim_ramp_${Date.now()}`,
        instructions: [
          '1. Apply at https://ramp.com (requires business bank account or EIN)',
          '2. Get approved (usually 1-2 business days)',
          '3. Receive corporate card',
          '4. Download Ramp mobile app',
          '5. Connect your accounting software (QuickBooks/Xero)',
          '6. Set spending limits and policies',
          '7. Add team members if needed',
          '8. AI will auto-categorize expenses (90%+ accuracy)',
        ],
        features: [
          'Corporate card with 1.5% cashback',
          'AI-powered expense categorization',
          'Receipt matching (just text a photo)',
          'Accounting software sync',
          'Real-time spending insights',
          'Bill pay automation',
        ],
        monthlyCost: 0, // Free!
        automationLevel: 90,
        setupTime: '30 minutes (+ approval time)',
        note: 'Requires business entity or EIN. Best for businesses doing $10K+/month',
      };
    }

    // Real Ramp API integration
    try {
      if (!this.rampApiKey) {
        throw new Error('RAMP_API_KEY not configured');
      }

      const response = await this.callRampAPI();
      return response;
    } catch (error) {
      console.error('[Bookkeeper Worker] Ramp API error:', error);
      throw error;
    }
  }

  /**
   * Setup QuickBooks
   */
  private async setupQuickBooks(state: BusinessState): Promise<any> {
    if (this.simulationMode) {
      console.log('[Bookkeeper Worker] SIMULATING QuickBooks setup');
      return {
        platform: 'quickbooks',
        status: 'simulated',
        accountId: `sim_qb_${Date.now()}`,
        instructions: [
          '1. Sign up at https://quickbooks.intuit.com',
          '2. Choose "Simple Start" plan ($30/month)',
          '3. Complete business profile',
          '4. Connect bank account (for auto-import)',
          '5. Connect Stripe for revenue tracking',
          '6. Set up expense categories',
          '7. Enable receipt capture (mobile app)',
          '8. Schedule quarterly tax estimate reminders',
        ],
        features: [
          'Income and expense tracking',
          'Invoice creation',
          'Receipt capture via mobile',
          'Bank account sync',
          'Tax preparation reports',
          'P&L and balance sheet',
        ],
        monthlyCost: 30,
        automationLevel: 60,
        setupTime: '1-2 hours',
        note: 'Good for sole proprietorships and small LLCs',
      };
    }

    return {
      platform: 'quickbooks',
      status: 'pending_implementation',
      message: 'QuickBooks API integration coming in Phase 2',
    };
  }

  /**
   * Setup Spreadsheet tracking
   */
  private async setupSpreadsheet(state: BusinessState): Promise<any> {
    console.log('[Bookkeeper Worker] Creating spreadsheet template');

    const template = this.generateSpreadsheetTemplate(state);

    return {
      platform: 'spreadsheet',
      status: 'template_created',
      template,
      instructions: [
        '1. Copy the provided template to Google Sheets or Excel',
        '2. Use Stripe Dashboard for revenue (automatic)',
        '3. Manually log expenses weekly',
        '4. Review profit/loss monthly',
        '5. Save receipts in a folder',
        '6. Upgrade to Ramp/QuickBooks when doing $5K+/month',
      ],
      features: [
        'Simple revenue and expense tracking',
        'Profit/loss calculation',
        'Basic cash flow monitoring',
        'Receipt checklist',
      ],
      monthlyCost: 0,
      automationLevel: 20,
      setupTime: '30 minutes',
      note: 'Perfect for MVPs and pre-revenue businesses. Upgrade when you hit $5K/month.',
    };
  }

  /**
   * Setup accounting (chart of accounts)
   */
  private async setupAccounting(accountingSetup: any, state: BusinessState): Promise<any> {
    console.log('[Bookkeeper Worker] Setting up chart of accounts');

    return {
      status: 'configured',
      chartOfAccounts: accountingSetup.chartOfAccounts,
      taxStrategy: accountingSetup.taxStrategy,
      note: 'Review with a CPA for tax optimization',
    };
  }

  /**
   * Configure revenue and expense tracking
   */
  private async configureTracking(
    revenueTracking: any,
    expenseTracking: any,
    state: BusinessState
  ): Promise<any> {
    console.log('[Bookkeeper Worker] Configuring tracking systems');

    return {
      status: 'configured',
      revenue: {
        sources: revenueTracking.sources,
        metrics: revenueTracking.metrics,
        goals: revenueTracking.goals,
      },
      expenses: {
        categories: expenseTracking.categories,
        totalMonthly: expenseTracking.totalMonthlyExpenses,
      },
    };
  }

  /**
   * Call Ramp API (Real implementation for Phase 2)
   */
  private async callRampAPI(): Promise<any> {
    if (!this.rampApiKey) {
      throw new Error('RAMP_API_KEY not configured');
    }

    // Ramp API endpoint
    const apiUrl = 'https://api.ramp.com/v1/business';

    try {
      const response = await axios.get(apiUrl, {
        headers: {
          Authorization: `Bearer ${this.rampApiKey}`,
        },
      });

      return {
        platform: 'ramp_ai',
        businessId: response.data.id,
        status: 'connected',
        dashboardUrl: 'https://app.ramp.com',
      };
    } catch (error: any) {
      console.error('[Bookkeeper Worker] Ramp API error:', error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Generate spreadsheet template
   */
  private generateSpreadsheetTemplate(state: BusinessState): any {
    return {
      name: 'Simple Bookkeeping Template',
      sheets: [
        {
          name: 'Revenue',
          columns: ['Date', 'Source', 'Description', 'Amount', 'Notes'],
          sampleData: [
            ['2026-02-01', 'Stripe', 'Subscription payment', '$29.99', 'Customer ABC'],
            ['2026-02-05', 'Stripe', 'One-time purchase', '$49.99', 'Customer XYZ'],
          ],
        },
        {
          name: 'Expenses',
          columns: ['Date', 'Category', 'Vendor', 'Amount', 'Receipt?'],
          sampleData: [
            ['2026-02-01', 'Software', 'Vercel', '$20.00', 'Yes'],
            ['2026-02-03', 'Marketing', 'Meta Ads', '$150.00', 'Yes'],
            ['2026-02-05', 'Software', 'OpenAI', '$50.00', 'Yes'],
          ],
        },
        {
          name: 'Summary',
          calculations: [
            'Total Revenue: SUM(Revenue!D:D)',
            'Total Expenses: SUM(Expenses!D:D)',
            'Profit/Loss: Revenue - Expenses',
            'Profit Margin %: (Profit / Revenue) * 100',
          ],
        },
      ],
      instructions:
        'Update weekly. Copy to Google Sheets. Backup monthly. Upgrade to Ramp when doing $5K+/month.',
    };
  }

  /**
   * Estimate revenue
   */
  private estimateRevenue(state: BusinessState): number {
    // Simple heuristic based on monetization model
    const model = state.idea.monetizationModel?.toLowerCase() || '';

    if (model.includes('free')) return 0;
    if (model.includes('$9.99')) return 500; // Assume 50 users
    if (model.includes('$19.99')) return 1000;
    if (model.includes('$49.99')) return 2500;

    // Default to modest estimate
    return 1000;
  }

  /**
   * Get next steps
   */
  private getNextSteps(platform: string, state: BusinessState): string[] {
    const baseSteps = [
      'Review the bookkeeping setup',
      'Connect Stripe for automatic revenue tracking',
      'Set up expense tracking (weekly updates)',
      'Review financials monthly',
      'Consult CPA before tax season',
    ];

    if (platform === 'ramp_ai') {
      return [
        'Apply for Ramp (requires EIN or business bank account)',
        'Wait for approval (1-2 days)',
        'Connect accounting software',
        'Start using corporate card for business expenses',
        'AI will auto-categorize 90%+ of transactions',
        'Review monthly reports',
      ];
    } else if (platform === 'quickbooks') {
      return [
        'Sign up for QuickBooks Simple Start',
        'Connect bank account and Stripe',
        'Categorize initial transactions',
        ...baseSteps,
      ];
    } else if (platform === 'spreadsheet') {
      return [
        'Copy the spreadsheet template',
        'Log all expenses weekly',
        'Check Stripe Dashboard for revenue',
        'Calculate profit/loss monthly',
        'Save all receipts digitally',
        'Upgrade to Ramp when revenue hits $5K/month',
      ];
    }

    return baseSteps;
  }

  /**
   * Parse JSON from AI response
   */
  private parseJSON(content: string): any {
    try {
      const cleaned = content
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();

      return JSON.parse(cleaned);
    } catch (error) {
      console.error('[Bookkeeper Worker] JSON parse error:', error);
      return this.getFallbackStrategy({} as BusinessState);
    }
  }

  /**
   * Fallback strategy if AI fails
   */
  private getFallbackStrategy(state: BusinessState): any {
    const isEarlyStage = !state.formation?.incorporated;

    return {
      recommendation: {
        platform: isEarlyStage ? 'spreadsheet' : 'ramp_ai',
        reasoning: isEarlyStage
          ? 'Start simple with spreadsheet, upgrade when profitable'
          : 'Ramp AI offers best automation for growing businesses',
        monthlyCost: isEarlyStage ? 0 : 0, // Both are free!
        automationLevel: isEarlyStage ? 20 : 90,
        setupTime: '30 minutes',
      },
      accountingSetup: {
        chartOfAccounts: [
          {
            category: 'Revenue',
            accounts: ['Product Sales', 'Subscription Revenue', 'Other Income'],
          },
          {
            category: 'Expenses',
            accounts: [
              'Software & Tools',
              'Marketing & Advertising',
              'Infrastructure & Hosting',
              'Professional Services',
              'Other Operating Expenses',
            ],
          },
        ],
        taxStrategy: {
          structure: state.formation?.legalStructure || 'sole_proprietorship',
          taxForm: 'Schedule C',
          quarterlyEstimates: true,
          deductions: ['home office', 'software', 'marketing', 'education', 'internet'],
        },
      },
      revenueTracking: {
        sources: ['stripe', 'paypal'],
        metrics: ['MRR', 'total revenue', 'growth rate'],
        goals: {
          month1: 1000,
          month3: 5000,
          month6: 15000,
        },
      },
      expenseTracking: {
        categories: [
          {
            name: 'Software & Tools',
            estimatedMonthly: 200,
            items: ['Stripe fees', 'Vercel hosting', 'AI APIs', 'Domain'],
          },
          {
            name: 'Marketing',
            estimatedMonthly: 300,
            items: ['Meta Ads', 'Google Ads', 'SEO tools'],
          },
          {
            name: 'Infrastructure',
            estimatedMonthly: 100,
            items: ['Database', 'CDN', 'Email service'],
          },
        ],
        totalMonthlyExpenses: 600,
      },
      dashboards: {
        metrics: ['revenue', 'expenses', 'profit', 'cash balance', 'burn rate', 'runway'],
        frequency: 'weekly',
      },
    };
  }

  /**
   * Generate financial report
   */
  async generateReport(startDate: Date, endDate: Date): Promise<any> {
    console.log('[Bookkeeper Worker] Generating financial report');

    // In production, fetch real data from platform API
    return {
      period: {
        start: startDate.toISOString(),
        end: endDate.toISOString(),
      },
      summary: {
        totalRevenue: 3450,
        totalExpenses: 1820,
        netProfit: 1630,
        profitMargin: 47.2,
      },
      revenue: {
        subscriptions: 2800,
        oneTimeSales: 650,
        other: 0,
      },
      expenses: {
        software: 420,
        marketing: 900,
        infrastructure: 350,
        other: 150,
      },
      cashFlow: {
        beginning: 5000,
        ending: 6630,
        change: 1630,
      },
    };
  }
}

// Export singleton instance
export const bookkeeperWorker = new BookkeeperWorker();
