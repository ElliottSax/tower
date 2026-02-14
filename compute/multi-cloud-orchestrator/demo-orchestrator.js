/**
 * Comprehensive Orchestrator Demonstration
 * Shows real-world usage of multi-cloud AI routing
 */

const Orchestrator = require('./src/orchestrator');
const config = require('./config');

console.log('🚀 COMPREHENSIVE ORCHESTRATOR DEMO\n');
console.log('═'.repeat(60));

async function demo() {
  const orchestrator = new Orchestrator(config);

  console.log('\n📋 Initialized with', orchestrator.providers.size, 'providers\n');

  // Demo 1: Quick chat response
  console.log('1️⃣  QUICK CHAT (Auto-routing to fastest)');
  console.log('─'.repeat(60));

  const chatJob = await orchestrator.submit({
    type: 'chat',
    payload: {
      messages: [
        { role: 'user', content: 'Explain quantum computing in one sentence' }
      ]
    },
    requirements: { latency: 'low' }
  });

  console.log(`   Job: ${chatJob.id}`);
  console.log(`   Routed to: ${chatJob.provider}`);

  try {
    const chatResult = await orchestrator.waitFor(chatJob.id, 20000);
    console.log(`   ✅ Response: ${chatResult.text}`);
    const duration = chatJob.completedAt - chatJob.startedAt;
    console.log(`   Duration: ${duration}ms`);
    console.log(`   Cost: $${chatJob.cost.toFixed(6)}`);
  } catch (error) {
    console.log(`   ⚠️  ${error.message}`);
  }

  // Demo 2: Code generation
  console.log('\n\n2️⃣  CODE GENERATION (Auto-routing to specialist)');
  console.log('─'.repeat(60));

  const codeJob = await orchestrator.submit({
    type: 'chat',
    payload: {
      messages: [
        { role: 'user', content: 'Write a Python function to reverse a string' }
      ]
    }
  });

  console.log(`   Job: ${codeJob.id}`);
  console.log(`   Routed to: ${codeJob.provider}`);

  try {
    const codeResult = await orchestrator.waitFor(codeJob.id, 20000);
    console.log(`   ✅ Response: ${codeResult.text.substring(0, 100)}...`);
    const duration = codeJob.completedAt - codeJob.startedAt;
    console.log(`   Duration: ${duration}ms`);
  } catch (error) {
    console.log(`   ⚠️  ${error.message}`);
  }

  // Demo 3: Multiple requests in parallel
  console.log('\n\n3️⃣  PARALLEL REQUESTS (Load balancing)');
  console.log('─'.repeat(60));

  const parallelTasks = [
    { type: 'chat', payload: { messages: [{ role: 'user', content: 'What is AI?' }] } },
    { type: 'chat', payload: { messages: [{ role: 'user', content: 'What is ML?' }] } },
    { type: 'chat', payload: { messages: [{ role: 'user', content: 'What is deep learning?' }] } }
  ];

  console.log(`   Submitting ${parallelTasks.length} tasks in parallel...`);
  const parallelJobs = await orchestrator.submitBatch(parallelTasks);

  let completed = 0;
  for (const job of parallelJobs) {
    try {
      await orchestrator.waitFor(job.id, 15000);
      completed++;
      const duration = job.completedAt - job.startedAt;
      console.log(`   ✅ Job ${job.id.substring(0, 20)}... (${job.provider}, ${duration}ms)`);
    } catch (error) {
      console.log(`   ❌ Job failed: ${error.message.substring(0, 50)}`);
    }
  }

  console.log(`\n   Completed: ${completed}/${parallelTasks.length}`);

  // Demo 4: Provider comparison
  console.log('\n\n4️⃣  PROVIDER COMPARISON (Same task, different providers)');
  console.log('─'.repeat(60));

  const testPrompt = 'Count from 1 to 5';

  // Force specific providers
  const providers = ['groq', 'cerebras'];

  for (const providerName of providers) {
    if (!orchestrator.providers.has(providerName)) {
      console.log(`   ⊘  ${providerName} not available`);
      continue;
    }

    const job = await orchestrator.submit({
      type: 'chat',
      payload: { messages: [{ role: 'user', content: testPrompt }] },
      provider: providerName
    });

    try {
      const result = await orchestrator.waitFor(job.id, 15000);
      const duration = job.completedAt - job.startedAt;
      console.log(`   ${providerName.toUpperCase()}: ${duration}ms - "${result.text.substring(0, 30)}..."`);
    } catch (error) {
      console.log(`   ${providerName.toUpperCase()}: Failed - ${error.message.substring(0, 40)}`);
    }
  }

  // Final stats
  console.log('\n\n═'.repeat(60));
  console.log('📊 SESSION STATISTICS\n');

  const stats = orchestrator.getStats();
  console.log(`Total Jobs: ${stats.totalJobs}`);
  console.log(`Completed: ${stats.completedJobs}`);
  console.log(`Failed: ${stats.failedJobs}`);
  console.log(`Success Rate: ${((stats.completedJobs / stats.totalJobs) * 100).toFixed(1)}%`);
  console.log(`Total Cost: $${stats.totalCost.toFixed(6)}`);
  console.log(`Avg Cost/Job: $${stats.avgCostPerJob.toFixed(6)}`);

  console.log('\n\nProvider Performance:');
  for (const [provider, providerStats] of Object.entries(stats.providerStats)) {
    if (providerStats.jobs > 0) {
      const successRate = ((providerStats.jobs - providerStats.failures) / providerStats.jobs * 100).toFixed(1);
      console.log(`\n${provider.toUpperCase()}:`);
      console.log(`  Jobs: ${providerStats.jobs}`);
      console.log(`  Success Rate: ${successRate}%`);
      console.log(`  Avg Latency: ${providerStats.avgLatency.toFixed(0)}ms`);
      console.log(`  Total Cost: $${providerStats.cost.toFixed(6)}`);
    }
  }

  // Cost comparison
  const costs = await orchestrator.getCosts();
  console.log('\n\nCost Breakdown:');
  for (const [provider, cost] of Object.entries(costs.breakdown)) {
    console.log(`  ${provider}: $${cost.toFixed(6)}`);
  }

  console.log('\n\n🎉 DEMO COMPLETE!\n');
  console.log('Key Insights:');
  console.log('  • Groq: Best for speed (free, ultra-fast)');
  console.log('  • DeepSeek: Best for code (specialized)');
  console.log('  • Orchestrator: Automatically routes to optimal provider');
  console.log('  • Total cost: Pennies for hundreds of requests\n');

  await orchestrator.shutdown();
}

demo().catch(console.error);
