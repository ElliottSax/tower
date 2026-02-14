/**
 * Batch Processing Example
 *
 * This example demonstrates how to offload batch processing tasks
 * to the cloud, processing multiple items in parallel.
 *
 * Usage:
 *   node batch-processor.js
 */

const CloudComputeClient = require('./node-client');

class BatchProcessor {
  constructor(client, maxConcurrent = 5) {
    this.client = client;
    this.maxConcurrent = maxConcurrent;
  }

  async processBatch(items, processFn) {
    const results = [];
    const chunks = this.chunkArray(items, this.maxConcurrent);

    for (const chunk of chunks) {
      const chunkResults = await Promise.all(
        chunk.map(item => processFn(item))
      );
      results.push(...chunkResults);
      console.log(`Processed ${results.length}/${items.length} items`);
    }

    return results;
  }

  chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }
}

async function example1_batchHashing() {
  console.log('\n=== Example 1: Batch Hash Generation ===\n');

  const client = new CloudComputeClient();
  const processor = new BatchProcessor(client, 10);

  const items = Array.from({ length: 50 }, (_, i) => `Item ${i + 1}`);

  const startTime = Date.now();
  const results = await processor.processBatch(
    items,
    async (item) => {
      const result = await client.hash(item);
      return { item, hash: result.hash.substring(0, 16) + '...' };
    }
  );

  const elapsed = Date.now() - startTime;

  console.log(`\nCompleted in ${elapsed}ms`);
  console.log(`Average: ${(elapsed / items.length).toFixed(2)}ms per item`);
  console.log('\nFirst 5 results:');
  results.slice(0, 5).forEach(r => {
    console.log(`  ${r.item}: ${r.hash}`);
  });
}

async function example2_batchTextAnalysis() {
  console.log('\n=== Example 2: Batch Text Analysis ===\n');

  const client = new CloudComputeClient();

  const documents = [
    'The quick brown fox jumps over the lazy dog.',
    'Cloud computing enables scalable infrastructure.',
    'Edge computing brings processing closer to users.',
    'Serverless functions execute code on demand.',
    'Distributed systems provide fault tolerance.',
  ];

  console.log(`Analyzing ${documents.length} documents...`);

  // Submit all jobs
  const jobIds = await Promise.all(
    documents.map(async (doc) => {
      const result = await client.submitJob('text-analysis', { text: doc });
      return result.jobId;
    })
  );

  console.log(`Submitted ${jobIds.length} jobs`);

  // Wait for all jobs to complete
  const results = await Promise.all(
    jobIds.map(jobId => client.waitForJob(jobId))
  );

  console.log('\nResults:');
  results.forEach((result, i) => {
    console.log(`\nDocument ${i + 1}:`);
    console.log(`  Words: ${result.words}`);
    console.log(`  Sentences: ${result.sentences}`);
    console.log(`  Avg word length: ${result.avgWordLength.toFixed(2)}`);
  });
}

async function example3_dataTransformation() {
  console.log('\n=== Example 3: Batch Data Transformation ===\n');

  const client = new CloudComputeClient();

  const datasets = [
    [5, 2, 8, 1, 9, 3, 7, 4, 6],
    [15, 22, 8, 11, 19, 3, 17, 24, 6],
    [50, 20, 80, 10, 90, 30, 70, 40, 60],
  ];

  console.log(`Processing ${datasets.length} datasets...`);

  const operations = ['sort', 'sum', 'average'];

  for (const operation of operations) {
    console.log(`\n${operation.toUpperCase()}:`);

    const results = await Promise.all(
      datasets.map(async (data, i) => {
        const result = await client.transformData(data, operation);
        return { dataset: i + 1, result };
      })
    );

    results.forEach(r => {
      console.log(`  Dataset ${r.dataset}: ${JSON.stringify(r.result)}`);
    });
  }
}

async function example4_parallelCompute() {
  console.log('\n=== Example 4: Parallel Heavy Compute ===\n');

  const client = new CloudComputeClient();

  const tasks = [
    { id: 1, iterations: 50000 },
    { id: 2, iterations: 100000 },
    { id: 3, iterations: 150000 },
    { id: 4, iterations: 200000 },
  ];

  console.log(`Starting ${tasks.length} compute tasks in parallel...`);
  const startTime = Date.now();

  // Submit all tasks
  const jobIds = await Promise.all(
    tasks.map(async (task) => {
      const result = await client.submitJob('heavy-compute', {
        iterations: task.iterations
      });
      return { taskId: task.id, jobId: result.jobId, iterations: task.iterations };
    })
  );

  // Wait for all to complete
  const results = await Promise.all(
    jobIds.map(async (job) => {
      const result = await client.waitForJob(job.jobId);
      return { ...job, result };
    })
  );

  const elapsed = Date.now() - startTime;

  console.log(`\nAll tasks completed in ${elapsed}ms\n`);
  results.forEach(r => {
    console.log(`Task ${r.taskId} (${r.iterations} iterations): ${r.result.result.toFixed(2)}`);
  });

  console.log(`\nBenefit: All ${tasks.length} tasks ran in parallel on edge servers!`);
}

async function main() {
  console.log('Cloud Compute Worker - Batch Processing Examples');
  console.log('=================================================');

  try {
    await example1_batchHashing();
    await example2_batchTextAnalysis();
    await example3_dataTransformation();
    await example4_parallelCompute();

    console.log('\n=== All Examples Completed ===\n');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = BatchProcessor;
