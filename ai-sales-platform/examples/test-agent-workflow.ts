/**
 * Example: Testing the AI Agent Workflow
 *
 * This script demonstrates how to use the AI orchestration system
 * to process a lead from research to personalized email.
 *
 * Run with: npx tsx examples/test-agent-workflow.ts
 */

import { supervisorAgent } from '../src/agents/supervisor';
import { config, validateConfig } from '../src/config';

async function main() {
  console.log('🤖 AI Sales Platform - Agent Workflow Test\n');

  // Validate environment
  try {
    validateConfig();
  } catch (error) {
    console.error('❌ Configuration error:', error.message);
    console.log('\nMake sure you have:');
    console.log('1. Copied .env.example to .env');
    console.log('2. Added your OPENAI_API_KEY');
    process.exit(1);
  }

  // Example lead to process
  const testLead = {
    firstName: 'Sarah',
    lastName: 'Johnson',
    email: 'sarah.johnson@techstartup.com',
    jobTitle: 'VP of Sales',
    companyName: 'TechStartup Inc',
    companyDomain: 'techstartup.com',
  };

  console.log('📋 Test Lead:');
  console.log(JSON.stringify(testLead, null, 2));
  console.log('\n' + '='.repeat(60) + '\n');

  // Execute the AI workflow
  console.log('▶️  Starting AI agent workflow...\n');

  const startTime = Date.now();

  try {
    const result = await supervisorAgent.execute({
      tenantId: 'demo-tenant-123',
      task: {
        type: 'personalize',
        input: {
          customInstructions: 'We help sales teams automate their outreach with AI, saving 10+ hours per week per rep.',
        },
      },
      lead: testLead,
    });

    const duration = Date.now() - startTime;

    console.log('\n' + '='.repeat(60) + '\n');
    console.log('✅ Workflow Complete!\n');
    console.log(`⏱️  Duration: ${(duration / 1000).toFixed(2)}s\n`);

    // Display results
    if (result.research) {
      console.log('📊 Research Results:');
      console.log('-------------------');
      console.log('Company Info:', JSON.stringify(result.research.companyInfo, null, 2));
      if (result.research.buyingSignals?.length) {
        console.log('\nBuying Signals:');
        result.research.buyingSignals.forEach(signal => console.log(`  • ${signal}`));
      }
      console.log();
    }

    if (result.enrichment) {
      console.log('💎 Enrichment Results:');
      console.log('---------------------');
      console.log(`Source: ${result.enrichment.sources.join(', ')}`);
      console.log(`Confidence: ${result.enrichment.confidence}%`);
      console.log(`Fields Found: ${Object.keys(result.enrichment.data).length}`);
      console.log();
    }

    if (result.personalization) {
      console.log('✉️  Generated Email:');
      console.log('-------------------');
      console.log(`Subject: ${result.personalization.subject}\n`);
      console.log('Body:');
      console.log(result.personalization.body);
      console.log();
      console.log('Reasoning:');
      console.log(result.personalization.reasoning);
      console.log();
    }

    // Show any errors
    if (result.errors && result.errors.length > 0) {
      console.log('⚠️  Errors:');
      result.errors.forEach(error => console.log(`  • ${error}`));
      console.log();
    }

    // Cost estimation
    const estimatedCost =
      0.01 + // Research
      0.47 + // Enrichment (Apollo)
      0.04;  // Email generation

    console.log('💰 Estimated Cost:');
    console.log(`  Research: $0.01`);
    console.log(`  Enrichment: $0.47`);
    console.log(`  Personalization: $0.04`);
    console.log(`  Total: ~$${estimatedCost.toFixed(2)}\n`);

    console.log('🎉 Test successful!\n');
  } catch (error) {
    console.error('\n❌ Workflow failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the test
main().catch(console.error);
