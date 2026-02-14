/**
 * Node.js Client for Cloud Compute Worker
 *
 * This client demonstrates how to offload compute tasks from your local
 * Node.js application to Cloudflare Workers edge network.
 *
 * Usage:
 *   node node-client.js
 */

const BASE_URL = 'https://my-first-worker.elliottsaxton.workers.dev';
const API_KEY = 'SECRET_API_KEY_c7a3b8e2d1f0';

class CloudComputeClient {
  constructor(baseUrl = BASE_URL, apiKey = API_KEY) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const response = await fetch(url, {
      ...options,
      headers: {
        'X-API-Key': this.apiKey,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`API Error: ${error.error || response.statusText}`);
    }

    return response.json();
  }

  // Immediate compute operations
  async hash(text) {
    return this.request('/compute/hash', {
      method: 'POST',
      body: JSON.stringify({ text }),
    });
  }

  async base64Encode(input) {
    return this.request('/compute/base64', {
      method: 'POST',
      body: JSON.stringify({ operation: 'encode', input }),
    });
  }

  async base64Decode(input) {
    return this.request('/compute/base64', {
      method: 'POST',
      body: JSON.stringify({ operation: 'decode', input }),
    });
  }

  async transformJson(data, transform = 'flatten') {
    return this.request('/compute/json-transform', {
      method: 'POST',
      body: JSON.stringify({ data, transform }),
    });
  }

  // Async job operations
  async submitJob(type, payload) {
    return this.request('/jobs', {
      method: 'POST',
      body: JSON.stringify({ type, payload }),
    });
  }

  async getJob(jobId) {
    return this.request(`/jobs/${jobId}`);
  }

  async listJobs() {
    return this.request('/jobs');
  }

  async waitForJob(jobId, pollInterval = 1000, timeout = 30000) {
    const startTime = Date.now();

    while (Date.now() - startTime < timeout) {
      const job = await this.getJob(jobId);

      if (job.status === 'completed') {
        return job.result;
      } else if (job.status === 'failed') {
        throw new Error(`Job failed: ${job.error}`);
      }

      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }

    throw new Error('Job timeout');
  }

  // High-level convenience methods
  async analyzeText(text) {
    const { jobId } = await this.submitJob('text-analysis', { text });
    return this.waitForJob(jobId);
  }

  async transformData(data, operation) {
    const { jobId } = await this.submitJob('data-transform', { data, operation });
    return this.waitForJob(jobId);
  }

  async heavyCompute(iterations) {
    const { jobId } = await this.submitJob('heavy-compute', { iterations });
    return this.waitForJob(jobId);
  }
}

// Example usage
async function main() {
  const client = new CloudComputeClient();

  console.log('=== Cloud Compute Worker Examples ===\n');

  // Example 1: Hash generation
  console.log('1. Hash Generation:');
  const hashResult = await client.hash('Hello, World!');
  console.log(`   Hash: ${hashResult.hash}\n`);

  // Example 2: Base64 encoding
  console.log('2. Base64 Encoding:');
  const encoded = await client.base64Encode('Cloud computing is awesome!');
  console.log(`   Encoded: ${encoded.result}\n`);

  // Example 3: JSON transformation
  console.log('3. JSON Transformation:');
  const flattened = await client.transformJson({
    user: { name: 'John', address: { city: 'NYC', zip: '10001' } }
  }, 'flatten');
  console.log(`   Flattened:`, flattened.result, '\n');

  // Example 4: Text analysis (async job)
  console.log('4. Text Analysis (Async Job):');
  const textStats = await client.analyzeText(
    'The quick brown fox jumps over the lazy dog. This is a test sentence.'
  );
  console.log(`   Stats:`, textStats, '\n');

  // Example 5: Data transformation (async job)
  console.log('5. Data Transformation (Async Job):');
  const sorted = await client.transformData([5, 2, 8, 1, 9, 3], 'sort');
  console.log(`   Sorted:`, sorted, '\n');

  // Example 6: Heavy compute
  console.log('6. Heavy Compute (100k iterations):');
  const computeStart = Date.now();
  const heavyResult = await client.heavyCompute(100000);
  const computeTime = Date.now() - computeStart;
  console.log(`   Result: ${heavyResult.result}`);
  console.log(`   Time: ${computeTime}ms\n`);

  // Example 7: List recent jobs
  console.log('7. Recent Jobs:');
  const { jobs } = await client.listJobs();
  console.log(`   Total jobs: ${jobs.length}`);
  jobs.slice(0, 3).forEach(job => {
    console.log(`   - ${job.id}: ${job.type} (${job.status})`);
  });
}

// Run examples if executed directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = CloudComputeClient;
