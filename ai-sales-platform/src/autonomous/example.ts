/**
 * Example: Launch an Autonomous Business
 *
 * This demonstrates the complete flow from business idea to operational business.
 *
 * Run with: tsx src/autonomous/example.ts
 */

import dotenv from 'dotenv';
import { createOrchestrator } from './orchestrator';
import { BusinessIdea } from './types';

dotenv.config();

async function main() {
  // Business idea input
  const idea: BusinessIdea = {
    description: 'AI-powered meal planning and grocery delivery app for busy professionals',
    targetMarket: 'Urban professionals aged 25-45, household income >$75K, value convenience',
    problemSolved: 'Save 5+ hours per week on meal planning, recipe search, and grocery shopping',
    monetizationModel: 'Freemium SaaS - Free basic plan, $9.99/month premium with AI personalization',
  };

  const businessName = 'MealMaster AI';
  const tenantId = 'demo-user-001';

  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║   Autonomous Business Platform - Demo                          ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  console.log('📋 Business Idea:');
  console.log(`   ${idea.description}\n`);
  console.log('🎯 Target Market:');
  console.log(`   ${idea.targetMarket}\n`);
  console.log('💰 Monetization:');
  console.log(`   ${idea.monetizationModel}\n`);

  console.log('🚀 Initializing autonomous business platform...\n');

  // Validate environment
  if (!process.env.DATABASE_URL) {
    console.error('❌ Error: DATABASE_URL not set in environment');
    console.error('Please set DATABASE_URL in your .env file');
    process.exit(1);
  }

  if (!process.env.OPENAI_API_KEY && !process.env.ANTHROPIC_API_KEY) {
    console.error('❌ Error: No AI API key found');
    console.error('Please set OPENAI_API_KEY or ANTHROPIC_API_KEY in your .env file');
    process.exit(1);
  }

  // Create orchestrator
  const orchestrator = createOrchestrator(process.env.DATABASE_URL);

  try {
    console.log('⏳ Launching business (this may take a few minutes)...\n');

    const startTime = Date.now();

    // Launch the business!
    const result = await orchestrator.launchBusiness({
      tenantId,
      idea,
      businessName,
    });

    const durationSeconds = Math.round((Date.now() - startTime) / 1000);

    console.log('\n╔════════════════════════════════════════════════════════════════╗');
    console.log('║   Business Launch Summary                                      ║');
    console.log('╚════════════════════════════════════════════════════════════════╝\n');

    console.log(`✅ Status: ${result.currentPhase.toUpperCase()}`);
    console.log(`⏱️  Duration: ${durationSeconds} seconds`);
    console.log(`📊 Completed Tasks: ${result.completedTasks?.length || 0}`);
    console.log(`⏳ Pending Tasks: ${result.pendingTasks?.length || 0}`);
    console.log(`💰 Total Cost: $${(result.totalCost || 0).toFixed(2)}`);
    console.log(`📈 Est. Monthly Cost: $${(result.estimatedMonthlyCost || 700).toFixed(2)}`);

    if (result.formation) {
      console.log('\n🏢 Company Formation:');
      console.log(`   Validated: ${result.formation.validated ? '✅' : '❌'}`);
      console.log(`   Incorporated: ${result.formation.incorporated ? '✅' : '❌'}`);
      console.log(`   Banking: ${result.formation.bankingSetup ? '✅' : '❌'}`);
      console.log(`   Payments: ${result.formation.paymentsSetup ? '✅' : '❌'}`);
    }

    if (result.product) {
      console.log('\n💻 Product Development:');
      console.log(`   Specifications: ${result.product.specificationsDefined ? '✅' : '❌'}`);
      console.log(`   MVP Built: ${result.product.mvpBuilt ? '✅' : '❌'}`);
      console.log(`   Deployed: ${result.product.deployed ? '✅' : '❌'}`);
      if (result.product.productUrl) {
        console.log(`   URL: ${result.product.productUrl}`);
      }
    }

    if (result.marketing) {
      console.log('\n📢 Marketing:');
      console.log(`   Strategy: ${result.marketing.strategyDefined ? '✅' : '❌'}`);
      console.log(`   Content: ${result.marketing.contentCreated ? '✅' : '❌'}`);
      console.log(`   Ads: ${result.marketing.adsLaunched ? '✅' : '❌'}`);
      console.log(`   SEO: ${result.marketing.seoOptimized ? '✅' : '❌'}`);
    }

    if (result.operations) {
      console.log('\n⚙️  Operations:');
      console.log(`   Support: ${result.operations.supportSetup ? '✅' : '❌'}`);
      console.log(`   Analytics: ${result.operations.analyticsSetup ? '✅' : '❌'}`);
      console.log(`   Monitoring: ${result.operations.monitoringSetup ? '✅' : '❌'}`);
    }

    if (result.finance) {
      console.log('\n💳 Finance:');
      console.log(`   Bookkeeping: ${result.finance.bookkeepingSetup ? '✅' : '❌'}`);
      console.log(`   Revenue Tracking: ${result.finance.revenueTracking ? '✅' : '❌'}`);
      console.log(`   Expense Tracking: ${result.finance.expenseTracking ? '✅' : '❌'}`);
    }

    if (result.errors && result.errors.length > 0) {
      console.log('\n⚠️  Errors:');
      result.errors.forEach((error, i) => {
        console.log(`   ${i + 1}. ${error}`);
      });
    }

    console.log('\n📝 Session ID:', result.sessionId);
    console.log('   (Use this to resume or check status)\n');

    console.log('╔════════════════════════════════════════════════════════════════╗');
    console.log('║   Next Steps                                                   ║');
    console.log('╚════════════════════════════════════════════════════════════════╝\n');

    if (result.nextAgent === 'human') {
      console.log('⏸️  Workflow paused for human decision');
      console.log('   Review the tasks and resume when ready');
    } else if (result.nextAgent === 'END') {
      console.log('🎉 Workflow completed!');
      console.log('   Your autonomous business is ready to operate');
    } else {
      console.log('🔄 Workflow in progress');
      console.log(`   Next agent: ${result.nextAgent}`);
    }

    console.log('\n📊 To check status:');
    console.log(`   orchestrator.getBusinessState('${result.sessionId}')`);
    console.log('\n🔄 To resume:');
    console.log(`   orchestrator.resumeWorkflow('${result.sessionId}')`);

    console.log('\n');

  } catch (error: any) {
    console.error('\n❌ Error launching business:', error);
    console.error(error.stack);
    process.exit(1);
  } finally {
    // Cleanup
    await orchestrator.shutdown();
  }
}

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}

export { main as runExample };
