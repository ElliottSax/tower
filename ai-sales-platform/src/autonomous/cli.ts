#!/usr/bin/env node

/**
 * Autonomous Business Platform CLI
 *
 * Interactive command-line interface for launching businesses
 */

import dotenv from 'dotenv';
import { createOrchestrator } from './orchestrator';
import { BusinessIdea } from './types';
import * as readline from 'readline';

dotenv.config();

// Terminal colors
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

function log(message: string, color: string = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function header(message: string) {
  console.log('\n' + '='.repeat(70));
  log(message, colors.bright + colors.blue);
  console.log('='.repeat(70) + '\n');
}

function success(message: string) {
  log(`✅ ${message}`, colors.green);
}

function warning(message: string) {
  log(`⚠️  ${message}`, colors.yellow);
}

function error(message: string) {
  log(`❌ ${message}`, colors.red);
}

function info(message: string) {
  log(`ℹ️  ${message}`, colors.cyan);
}

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function question(prompt: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(`${colors.cyan}${prompt}${colors.reset} `, resolve);
  });
}

async function gatherBusinessIdea(): Promise<{ idea: BusinessIdea; businessName: string }> {
  header('💡 Tell Me About Your Business Idea');

  const description = await question('What does your business do? (1 sentence)');
  const targetMarket = await question('Who is your target customer?');
  const problemSolved = await question('What problem do you solve?');
  const monetizationModel = await question('How will you make money? (e.g., "$9.99/month subscription")');
  const businessName = await question('What\'s your business name?');

  return {
    idea: {
      description,
      targetMarket,
      problemSolved,
      monetizationModel,
    },
    businessName: businessName || undefined,
  };
}

async function confirmLaunch(cost: number): Promise<boolean> {
  console.log('\n');
  info(`Estimated launch cost: $${cost}`);
  info('This is a simulation - no real costs will be incurred');

  const answer = await question('Ready to launch? (yes/no)');
  return answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y';
}

async function displayProgress(sessionId: string) {
  log('\n🚀 Launching your business...', colors.bright);
  log(`Session ID: ${sessionId}\n`, colors.cyan);

  // This would show real-time progress in production
  // For now, just show we're working
  const spinner = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  let i = 0;

  const interval = setInterval(() => {
    process.stdout.write(`\r${spinner[i]} Processing... `);
    i = (i + 1) % spinner.length;
  }, 100);

  return () => clearInterval(interval);
}

async function displayResults(result: any) {
  console.log('\n');
  header('📊 Launch Summary');

  // Formation status
  console.log('\n📋 Legal Structure:');
  if (result.formation) {
    const structure = result.formation.legalStructure || 'not set';
    success(`Structure: ${structure}`);

    if (structure === 'sole_proprietorship' || structure === 'none') {
      success('No incorporation needed - save $399! ✨');
    } else {
      info(`Incorporation required: ${structure.toUpperCase()}`);
    }
  }

  // Product status
  if (result.product) {
    console.log('\n💻 Product:');
    if (result.product.specificationsDefined) success('Specifications defined');
    if (result.product.mvpBuilt) success('MVP built');
    if (result.product.deployed) success('Deployed to production');
    if (result.product.productUrl) info(`URL: ${result.product.productUrl}`);
  }

  // Marketing status
  if (result.marketing) {
    console.log('\n📢 Marketing:');
    if (result.marketing.strategyDefined) success('Strategy defined');
    if (result.marketing.contentCreated) success('Content created');
    if (result.marketing.adsLaunched) success('Ads launched');
    if (result.marketing.seoOptimized) success('SEO optimized');
  }

  // Operations status
  if (result.operations) {
    console.log('\n⚙️  Operations:');
    if (result.operations.supportSetup) success('Support setup');
    if (result.operations.analyticsSetup) success('Analytics configured');
    if (result.operations.monitoringSetup) success('Monitoring active');
  }

  // Finance status
  if (result.finance) {
    console.log('\n💰 Finance:');
    if (result.finance.bookkeepingSetup) success('Bookkeeping automated');
    if (result.finance.revenueTracking) success('Revenue tracking');
    if (result.finance.expenseTracking) success('Expense tracking');
  }

  // Cost summary
  console.log('\n💵 Costs:');
  info(`Total spent: $${(result.totalCost || 0).toFixed(2)}`);
  info(`Monthly operating: $${(result.estimatedMonthlyCost || 700).toFixed(2)}`);

  // Tasks summary
  console.log('\n✅ Progress:');
  info(`Completed tasks: ${result.completedTasks?.length || 0}`);
  info(`Pending tasks: ${result.pendingTasks?.length || 0}`);
  info(`Current phase: ${result.currentPhase}`);

  // Next steps
  console.log('\n🎯 Next Steps:');
  if (result.nextAgent === 'human') {
    warning('Paused for human review');
    info('Review the plan and resume when ready');
  } else if (result.nextAgent === 'END') {
    success('Launch workflow complete!');
  } else {
    info(`Next: ${result.nextAgent}`);
  }

  // Errors
  if (result.errors && result.errors.length > 0) {
    console.log('\n⚠️  Errors:');
    result.errors.forEach((err: string) => error(err));
  }
}

async function main() {
  console.clear();

  header('🤖 Autonomous Business Platform CLI');

  log('Launch businesses autonomously with AI', colors.bright);
  log('From idea to profitable reality in 30 days\n');

  // Check environment
  if (!process.env.DATABASE_URL) {
    error('DATABASE_URL not set in environment');
    info('Run: docker-compose up -d');
    info('Then add DATABASE_URL to .env file');
    process.exit(1);
  }

  if (!process.env.OPENAI_API_KEY && !process.env.ANTHROPIC_API_KEY) {
    warning('No AI API key found');
    info('Add OPENAI_API_KEY or ANTHROPIC_API_KEY to .env');
    info('Continuing in simulation mode...\n');
  }

  try {
    // Gather business idea
    const { idea, businessName } = await gatherBusinessIdea();

    // Estimate cost
    const estimatedCost = 1000; // Base estimate

    // Confirm launch
    const confirmed = await confirmLaunch(estimatedCost);
    if (!confirmed) {
      log('\n👋 Launch cancelled. Come back when you\'re ready!', colors.yellow);
      process.exit(0);
    }

    // Create orchestrator
    const orchestrator = createOrchestrator(process.env.DATABASE_URL!);

    // Start progress display
    const stopProgress = await displayProgress('generating...');

    // Launch business
    const result = await orchestrator.launchBusiness({
      tenantId: 'cli-user',
      idea,
      businessName,
    });

    // Stop progress display
    stopProgress();

    // Display results
    await displayResults(result);

    // Save session ID for resume
    console.log('\n📝 Session ID:', result.sessionId);
    info('Save this ID to resume later!');

    console.log('\n');
    success('Done! Check the summary above for details.');

    // Cleanup
    await orchestrator.shutdown();

  } catch (err: any) {
    error(`\nError: ${err.message}`);
    console.error(err.stack);
    process.exit(1);
  } finally {
    rl.close();
  }
}

// Handle exit
process.on('SIGINT', () => {
  log('\n\n👋 Goodbye!', colors.yellow);
  rl.close();
  process.exit(0);
});

// Run if called directly
if (require.main === module) {
  main().catch((err) => {
    error(err.message);
    process.exit(1);
  });
}

export { main };
