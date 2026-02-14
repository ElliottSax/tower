/**
 * Test the Multi-Cloud Orchestrator with working AI platforms
 *
 * Tests automatic provider selection and task routing
 */

const Orchestrator = require('./src/orchestrator');
const config = require('./config');

console.log('🎯 TESTING MULTI-CLOUD ORCHESTRATOR\n');
console.log('═'.repeat(60));

async function testOrchestrator() {
  // Initialize orchestrator
  const orchestrator = new Orchestrator(config);

  console.log('\n📋 Initialized Providers:');
  const stats = orchestrator.getStats();
  console.log(`   Total: ${stats.providers.length} providers`);
  stats.providers.forEach(p => console.log(`   - ${p}`));

  // Test 1: Code Generation (should route to DeepSeek or Groq)
  console.log('\n\n1️⃣  CODE GENERATION TEST');
  console.log('─'.repeat(60));

  const codeJob = await orchestrator.submit({
    type: 'code-generation',
    payload: {
      prompt: 'Write a function to calculate factorial in Python'
    }
  });

  console.log(`   Job submitted: ${codeJob.id}`);
  console.log(`   Provider: ${codeJob.provider}`);

  try {
    const codeResult = await orchestrator.waitFor(codeJob.id, 30000);
    console.log(`   ✅ Result: ${codeResult.text?.substring(0, 100)}...`);
    console.log(`   Cost: $${codeJob.cost.toFixed(6)}`);
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}`);
  }

  // Test 2: Chat/Conversation (should route to Groq for speed)
  console.log('\n\n2️⃣  CHAT TEST (Ultra-fast)');
  console.log('─'.repeat(60));

  const chatJob = await orchestrator.submit({
    type: 'chat',
    payload: {
      messages: [
        { role: 'user', content: 'What is the capital of France?' }
      ]
    },
    requirements: {
      latency: 'low'
    }
  });

  console.log(`   Job submitted: ${chatJob.id}`);
  console.log(`   Provider: ${chatJob.provider}`);

  try {
    const chatResult = await orchestrator.waitFor(chatJob.id, 30000);
    console.log(`   ✅ Result: ${chatResult.text}`);
    const duration = chatJob.completedAt - chatJob.startedAt;
    console.log(`   Duration: ${duration}ms`);
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}`);
  }

  // Test 3: Batch Processing
  console.log('\n\n3️⃣  BATCH PROCESSING TEST');
  console.log('─'.repeat(60));

  const batchTasks = [
    { type: 'text-generation', payload: { prompt: 'Write a haiku about clouds' } },
    { type: 'summarization', payload: { text: 'Cloud computing allows organizations to access computing resources over the internet without maintaining physical infrastructure.' } },
    { type: 'chat', payload: { messages: [{ role: 'user', content: 'Count to 5' }] } }
  ];

  const batchJobs = await orchestrator.submitBatch(batchTasks);
  console.log(`   Submitted ${batchJobs.length} jobs`);

  let completed = 0;
  let failed = 0;

  for (const job of batchJobs) {
    try {
      await orchestrator.waitFor(job.id, 30000);
      completed++;
      console.log(`   ✅ Job ${job.id}: ${job.provider}`);
    } catch (error) {
      failed++;
      console.log(`   ❌ Job ${job.id}: ${error.message}`);
    }
  }

  console.log(`\n   Completed: ${completed}/${batchJobs.length}`);
  if (failed > 0) console.log(`   Failed: ${failed}`);

  // Test 4: Cost Analysis
  console.log('\n\n4️⃣  COST ANALYSIS');
  console.log('─'.repeat(60));

  const costs = await orchestrator.getCosts();
  console.log(`   Total Cost: $${costs.total.toFixed(6)}`);
  console.log(`   Total Jobs: ${costs.jobs}`);
  console.log('\n   Cost Breakdown:');
  for (const [provider, cost] of Object.entries(costs.breakdown)) {
    console.log(`   - ${provider}: $${cost.toFixed(6)}`);
  }

  // Final Statistics
  console.log('\n\n═'.repeat(60));
  console.log('📊 FINAL STATISTICS\n');

  const finalStats = orchestrator.getStats();
  console.log(`Total Jobs: ${finalStats.totalJobs}`);
  console.log(`Completed: ${finalStats.completedJobs}`);
  console.log(`Failed: ${finalStats.failedJobs}`);
  console.log(`Success Rate: ${((finalStats.completedJobs / finalStats.totalJobs) * 100).toFixed(1)}%`);
  console.log(`Total Cost: $${finalStats.totalCost.toFixed(6)}`);
  console.log(`Avg Cost/Job: $${finalStats.avgCostPerJob.toFixed(6)}`);

  console.log('\n\nProvider Statistics:');
  for (const [provider, stats] of Object.entries(finalStats.providerStats)) {
    if (stats.jobs > 0) {
      console.log(`\n${provider}:`);
      console.log(`  Jobs: ${stats.jobs}`);
      console.log(`  Failures: ${stats.failures}`);
      console.log(`  Success Rate: ${((stats.jobs - stats.failures) / stats.jobs * 100).toFixed(1)}%`);
      console.log(`  Total Cost: $${stats.cost.toFixed(6)}`);
      console.log(`  Avg Latency: ${stats.avgLatency.toFixed(0)}ms`);
    }
  }

  console.log('\n\n🎉 ORCHESTRATOR TEST COMPLETE!\n');
  console.log('Your multi-cloud AI infrastructure is operational!\n');

  await orchestrator.shutdown();
}

testOrchestrator().catch(console.error);
