/**
 * Multi-Cloud Orchestrator Demo
 *
 * Demonstrates intelligent routing across multiple cloud providers
 */

const Orchestrator = require('../src/orchestrator');
const config = require('../config');

async function main() {
  console.log('╔═══════════════════════════════════════════════════════════╗');
  console.log('║   Multi-Cloud Compute Orchestrator Demo                  ║');
  console.log('╚═══════════════════════════════════════════════════════════╝\n');

  // Initialize orchestrator with provider configurations
  const orchestrator = new Orchestrator({
    cloudflare: {
      enabled: true,
      priority: 10,
      apiUrl: config.cloudflare.apiUrl,
      apiKey: config.cloudflare.apiKey
    },
    aws: {
      enabled: true,
      priority: 8,
      region: 'us-east-1'
    },
    gcp: {
      enabled: true,
      priority: 7,
      projectId: 'my-project'
    },
    local: {
      enabled: true,
      priority: 1 // Lowest priority - only use as fallback
    }
  });

  // Set up event listeners
  orchestrator.on('job:submitted', (job) => {
    console.log(`✓ Job ${job.id} submitted to ${job.provider}`);
  });

  orchestrator.on('job:completed', (job) => {
    const duration = job.completedAt - job.startedAt;
    console.log(`✓ Job ${job.id} completed in ${duration}ms (cost: $${job.cost.toFixed(6)})`);
  });

  orchestrator.on('job:failed', (job) => {
    console.log(`✗ Job ${job.id} failed: ${job.error}`);
  });

  console.log('Demo 1: Hash Computation (Low Latency)\n');
  console.log('Submitting hash computation tasks...');
  const hashJob = await orchestrator.submit({
    type: 'hash',
    payload: { text: 'Hello, Multi-Cloud World!' },
    requirements: {
      latency: 'low',
      cost: 'balanced'
    }
  });

  const hashResult = await orchestrator.waitFor(hashJob.id);
  console.log(`Hash: ${hashResult.hash}`);
  console.log(`Provider: ${hashResult.provider || hashJob.provider}\n`);

  console.log('─'.repeat(60) + '\n');

  console.log('Demo 2: Text Analysis (Balanced)\n');
  console.log('Analyzing text across multiple providers...');

  const texts = [
    'Cloud computing enables unprecedented scalability.',
    'Edge computing brings processing closer to users.',
    'Serverless functions execute code on demand.'
  ];

  const analysisJobs = await Promise.all(
    texts.map(text => orchestrator.submit({
      type: 'text-analysis',
      payload: { text },
      requirements: { cost: 'balanced' }
    }))
  );

  const analysisResults = await Promise.all(
    analysisJobs.map(job => orchestrator.waitFor(job.id))
  );

  analysisResults.forEach((result, i) => {
    console.log(`\nText ${i + 1}:`);
    console.log(`  Words: ${result.words}, Sentences: ${result.sentences}`);
    console.log(`  Provider: ${result.provider || analysisJobs[i].provider}`);
  });

  console.log('\n' + '─'.repeat(60) + '\n');

  console.log('Demo 3: Data Transformation (Cost Optimized)\n');
  console.log('Processing data with cost optimization...');

  const dataJob = await orchestrator.submit({
    type: 'data-transform',
    payload: {
      data: [45, 12, 78, 23, 90, 34, 67, 15, 89, 56],
      operation: 'sort'
    },
    requirements: {
      cost: 'minimize'
    }
  });

  const dataResult = await orchestrator.waitFor(dataJob.id);
  console.log(`Sorted: ${JSON.stringify(dataResult.result)}`);
  console.log(`Provider: ${dataResult.provider || dataJob.provider}\n`);

  console.log('─'.repeat(60) + '\n');

  console.log('Demo 4: Heavy Compute (Performance Priority)\n');
  console.log('Running CPU-intensive computation...');

  const computeJob = await orchestrator.submit({
    type: 'heavy-compute',
    payload: { iterations: 100000 },
    requirements: {
      cost: 'performance'
    }
  });

  const computeResult = await orchestrator.waitFor(computeJob.id);
  console.log(`Result: ${computeResult.result}`);
  console.log(`Iterations: ${computeResult.iterations}`);
  console.log(`Provider: ${computeResult.provider || computeJob.provider}\n`);

  console.log('─'.repeat(60) + '\n');

  console.log('Demo 5: Batch Processing\n');
  console.log('Submitting batch of tasks in parallel...');

  const batchTasks = Array.from({ length: 10 }, (_, i) => ({
    type: 'hash',
    payload: { text: `Batch item ${i + 1}` }
  }));

  const startTime = Date.now();
  const batchJobs = await orchestrator.submitBatch(batchTasks, { parallelism: 5 });
  const batchResults = await Promise.all(
    batchJobs.map(job => orchestrator.waitFor(job.id))
  );
  const batchTime = Date.now() - startTime;

  console.log(`Processed ${batchResults.length} items in ${batchTime}ms`);
  console.log(`Average: ${(batchTime / batchResults.length).toFixed(2)}ms per item\n`);

  console.log('─'.repeat(60) + '\n');

  // Show statistics
  const stats = orchestrator.getStats();
  console.log('Overall Statistics:\n');
  console.log(`Total Jobs: ${stats.totalJobs}`);
  console.log(`Completed: ${stats.completedJobs}`);
  console.log(`Failed: ${stats.failedJobs}`);
  console.log(`Total Cost: $${stats.totalCost.toFixed(6)}`);
  console.log(`Avg Cost/Job: $${stats.avgCostPerJob.toFixed(6)}\n`);

  console.log('Provider Breakdown:');
  for (const [provider, providerStats] of Object.entries(stats.providerStats)) {
    if (providerStats.jobs > 0) {
      console.log(`  ${provider}:`);
      console.log(`    Jobs: ${providerStats.jobs}`);
      console.log(`    Cost: $${providerStats.cost.toFixed(6)}`);
      console.log(`    Avg Latency: ${providerStats.avgLatency.toFixed(2)}ms`);
      console.log(`    Failures: ${providerStats.failures}`);
    }
  }

  console.log('\n' + '─'.repeat(60) + '\n');

  // Cost analysis
  const costs = await orchestrator.getCosts();
  console.log('Cost Analysis:\n');
  console.log(`Total: $${costs.total.toFixed(6)}`);
  console.log('Breakdown:');
  for (const [provider, cost] of Object.entries(costs.breakdown)) {
    const percentage = ((cost / costs.total) * 100).toFixed(1);
    console.log(`  ${provider}: $${cost.toFixed(6)} (${percentage}%)`);
  }

  console.log('\n╔═══════════════════════════════════════════════════════════╗');
  console.log('║   Demo Complete - Orchestrator Successfully Distributed  ║');
  console.log('║   Tasks Across Multiple Cloud Providers!                 ║');
  console.log('╚═══════════════════════════════════════════════════════════╝\n');

  await orchestrator.shutdown();
}

main().catch(console.error);
