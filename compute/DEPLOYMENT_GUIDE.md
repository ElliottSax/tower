# Cloud Workers Deployment Guide

This guide walks you through deploying **actual cloud infrastructure** to offload compute from your local machine.

## Overview

You'll deploy real serverless functions to:
- ✅ **Cloudflare Workers** - Already deployed at edge locations worldwide
- ✅ **AWS Lambda** - Deploy to AWS infrastructure
- ✅ **Google Cloud Functions** - Deploy to GCP infrastructure

## Prerequisites

Before you begin, ensure you have:

1. **Cloud accounts**:
   - [Cloudflare account](https://dash.cloudflare.com/sign-up) (already set up)
   - [AWS account](https://aws.amazon.com/)
   - [Google Cloud account](https://cloud.google.com/)

2. **Command-line tools**:
   - Node.js 20+ (`node --version`)
   - npm or yarn
   - Git

## Part 1: Cloudflare Workers (Already Deployed)

### Status: ✅ READY TO USE

The Cloudflare Worker is already deployed and live!

**URL:** `https://my-first-worker.elliottsaxton.workers.dev`
**API Key:** `SECRET_API_KEY_c7a3b8e2d1f0`

### Test It Now

```bash
# Health check
curl "https://my-first-worker.elliottsaxton.workers.dev/health" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0"

# Compute hash
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/compute/hash" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"text": "Testing real cloud worker!"}'

# Submit async job
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/jobs" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"type": "text-analysis", "payload": {"text": "The quick brown fox"}}'

# Get job status (use jobId from previous response)
curl "https://my-first-worker.elliottsaxton.workers.dev/jobs/YOUR_JOB_ID" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0"
```

### Update Deployment (Optional)

If you want to redeploy with updates:

```bash
cd /mnt/e/projects/my-first-worker

# Set Cloudflare API token
export CLOUDFLARE_API_TOKEN=your_token_here

# Deploy
npm run deploy
```

## Part 2: AWS Lambda Functions

### Step 1: Install AWS CLI

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### Step 2: Configure AWS Credentials

```bash
aws configure
```

You'll need:
- **AWS Access Key ID** (from AWS IAM Console)
- **AWS Secret Access Key**
- **Default region:** us-east-1
- **Default output format:** json

### Step 3: Install Serverless Framework

```bash
npm install -g serverless
```

### Step 4: Deploy Functions

```bash
cd /mnt/e/projects/compute/cloud-functions/aws-lambda

# Install dependencies
npm install

# Deploy to dev environment
npm run deploy:dev

# Or deploy to production
npm run deploy:prod
```

### Step 5: Save Endpoint URLs

After deployment, you'll see output like:

```
endpoints:
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/dev/compute/hash
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/dev/compute/text-analysis
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/dev/compute/data-transform
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/dev/compute/heavy
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/dev/compute/image
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/dev/batch
```

**Save these URLs** - you'll need them for the orchestrator!

### Step 6: Test AWS Functions

```bash
# Test hash function
curl -X POST https://YOUR-AWS-URL/dev/compute/hash \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello AWS Lambda!"}'

# Test text analysis
curl -X POST https://YOUR-AWS-URL/dev/compute/text-analysis \
  -H "Content-Type: application/json" \
  -d '{"text": "Testing AWS Lambda serverless functions."}'

# Test heavy compute
curl -X POST https://YOUR-AWS-URL/dev/compute/heavy \
  -H "Content-Type: application/json" \
  -d '{"iterations": 100000, "operation": "mixed"}'
```

## Part 3: Google Cloud Functions

### Step 1: Install gcloud CLI

```bash
# Download and install
curl https://sdk.cloud.google.com | bash

# Restart shell
exec -l $SHELL

# Initialize
gcloud init
```

### Step 2: Create/Select GCP Project

```bash
# Create new project (or select existing)
gcloud projects create my-compute-workers --name="Compute Workers"

# Set active project
gcloud config set project my-compute-workers

# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Step 3: Deploy Functions

```bash
cd /mnt/e/projects/compute/cloud-functions/gcp-functions

# Install dependencies
npm install

# Deploy all functions
chmod +x deploy-all.sh
./deploy-all.sh

# Or deploy individually
npm run deploy:hash
npm run deploy:text
npm run deploy:data
npm run deploy:heavy
```

### Step 4: Get Function URLs

```bash
gcloud functions list --region us-central1
```

Output will show:

```
NAME            STATUS  TRIGGER       REGION        URL
computeHash     ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/computeHash
analyzeText     ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/analyzeText
transformData   ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/transformData
heavyCompute    ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/heavyCompute
```

### Step 5: Test GCP Functions

```bash
# Test hash function
curl -X POST https://us-central1-PROJECT.cloudfunctions.net/computeHash \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello GCP!"}'

# Test data transform
curl -X POST https://us-central1-PROJECT.cloudfunctions.net/transformData \
  -H "Content-Type: application/json" \
  -d '{"data": [5, 2, 8, 1], "operation": "sort"}'
```

## Part 4: Configure the Orchestrator

Now that you have real cloud functions deployed, update the orchestrator to use them!

### Create Configuration File

```bash
cd /mnt/e/projects/compute/multi-cloud-orchestrator
```

Create `config.js`:

```javascript
module.exports = {
  cloudflare: {
    enabled: true,
    priority: 10,
    apiUrl: 'https://my-first-worker.elliottsaxton.workers.dev',
    apiKey: 'SECRET_API_KEY_c7a3b8e2d1f0'
  },

  aws: {
    enabled: true,
    priority: 8,
    region: 'us-east-1',
    endpoints: {
      hash: 'https://YOUR-AWS-URL/dev/compute/hash',
      textAnalysis: 'https://YOUR-AWS-URL/dev/compute/text-analysis',
      dataTransform: 'https://YOUR-AWS-URL/dev/compute/data-transform',
      heavyCompute: 'https://YOUR-AWS-URL/dev/compute/heavy',
      image: 'https://YOUR-AWS-URL/dev/compute/image',
      batch: 'https://YOUR-AWS-URL/dev/batch'
    }
  },

  gcp: {
    enabled: true,
    priority: 7,
    projectId: 'my-compute-workers',
    region: 'us-central1',
    endpoints: {
      hash: 'https://us-central1-PROJECT.cloudfunctions.net/computeHash',
      textAnalysis: 'https://us-central1-PROJECT.cloudfunctions.net/analyzeText',
      dataTransform: 'https://us-central1-PROJECT.cloudfunctions.net/transformData',
      heavyCompute: 'https://us-central1-PROJECT.cloudfunctions.net/heavyCompute'
    }
  },

  local: {
    enabled: true,
    priority: 1  // Lowest priority - only use as fallback
  }
};
```

### Update Orchestrator to Use Real Providers

Edit `src/orchestrator.js` to import real providers:

```javascript
const CloudflareProvider = require('./providers/cloudflare-real');
const AWSProvider = require('./providers/aws-real');
const GCPProvider = require('./providers/gcp-real');
const LocalProvider = require('./providers/local');
```

### Test the Orchestrator

Create `test-real-cloud.js`:

```javascript
const Orchestrator = require('./src/orchestrator');
const config = require('./config');

async function main() {
  const orchestrator = new Orchestrator(config);

  console.log('Testing real cloud workers...\n');

  // Test 1: Hash with Cloudflare
  console.log('1. Testing Cloudflare Worker (edge compute)...');
  const hashJob = await orchestrator.submit({
    type: 'hash',
    payload: { text: 'Hello from real cloud!' }
  });
  const hashResult = await orchestrator.waitFor(hashJob.id);
  console.log(`✓ Hash: ${hashResult.hash.substring(0, 16)}...`);
  console.log(`  Provider: ${hashJob.provider}\n`);

  // Test 2: Heavy compute with AWS
  console.log('2. Testing AWS Lambda (heavy compute)...');
  const computeJob = await orchestrator.submit({
    type: 'heavy-compute',
    payload: { iterations: 50000, operation: 'mixed' },
    provider: 'aws'  // Force AWS
  });
  const computeResult = await orchestrator.waitFor(computeJob.id);
  console.log(`✓ Result: ${computeResult.result}`);
  console.log(`  Duration: ${computeResult.meta?.duration || 'N/A'}ms`);
  console.log(`  Provider: ${computeJob.provider}\n`);

  // Test 3: Text analysis with GCP
  console.log('3. Testing GCP Functions (text analysis)...');
  const textJob = await orchestrator.submit({
    type: 'text-analysis',
    payload: { text: 'The quick brown fox jumps over the lazy dog.' },
    provider: 'gcp'  // Force GCP
  });
  const textResult = await orchestrator.waitFor(textJob.id);
  console.log(`✓ Words: ${textResult.text?.words || textResult.words || 'N/A'}`);
  console.log(`  Sentences: ${textResult.text?.sentences || textResult.sentences || 'N/A'}`);
  console.log(`  Provider: ${textJob.provider}\n`);

  // Show statistics
  const stats = orchestrator.getStats();
  console.log('Overall Statistics:');
  console.log(`  Total jobs: ${stats.totalJobs}`);
  console.log(`  Completed: ${stats.completedJobs}`);
  console.log(`  Failed: ${stats.failedJobs}`);
  console.log(`  Total cost: $${stats.totalCost.toFixed(6)}\n`);

  await orchestrator.shutdown();
}

main().catch(console.error);
```

Run it:

```bash
node test-real-cloud.js
```

## Part 5: Production Usage

### Use in Your Applications

```javascript
const Orchestrator = require('./compute/multi-cloud-orchestrator/src/orchestrator');
const config = require('./compute/multi-cloud-orchestrator/config');

const orchestrator = new Orchestrator(config);

// Offload computation to cloud
const result = await orchestrator.submit({
  type: 'text-analysis',
  payload: { text: myLargeDocument }
});

const analysis = await orchestrator.waitFor(result.id);
console.log(analysis);
```

### Monitor Costs

```javascript
// Get cost breakdown
const costs = await orchestrator.getCosts({
  startDate: '2026-01-01',
  endDate: '2026-01-31'
});

console.log(`Total: $${costs.total}`);
console.log('By provider:');
for (const [provider, cost] of Object.entries(costs.breakdown)) {
  console.log(`  ${provider}: $${cost.toFixed(6)}`);
}
```

## Cost Summary

Actual costs for real cloud workers:

| Provider | Per Request | Per Compute (100ms) | Free Tier |
|----------|-------------|---------------------|-----------|
| **Cloudflare** | $0.0000005 | Included | 100k req/day |
| **AWS Lambda** | $0.0000002 | ~$0.000002 | 1M req/month |
| **GCP Functions** | $0.0000004 | ~$0.000001 | 2M req/month |

**Example monthly costs** (10,000 requests/month):
- Cloudflare: $0.005 (essentially free)
- AWS: $0.002 + compute = ~$0.022
- GCP: $0.004 + compute = ~$0.014

**You can process 10,000 tasks/month for less than $0.05!**

## Monitoring

### Cloudflare Dashboard
- https://dash.cloudflare.com/
- View Workers → Analytics

### AWS CloudWatch
- https://console.aws.amazon.com/cloudwatch/
- View Lambda metrics, logs, costs

### GCP Console
- https://console.cloud.google.com/functions
- View function metrics, logs, costs

## Cleanup

### Remove AWS Functions

```bash
cd /mnt/e/projects/compute/cloud-functions/aws-lambda
serverless remove
```

### Remove GCP Functions

```bash
cd /mnt/e/projects/compute/cloud-functions/gcp-functions
for func in computeHash analyzeText transformData heavyCompute; do
  gcloud functions delete $func --region us-central1 --quiet
done
```

### Keep Cloudflare Worker
The Cloudflare Worker is already deployed and costs almost nothing - keep it running!

## Troubleshooting

### AWS: Permission Denied
- Ensure your IAM user has Lambda, API Gateway, and CloudWatch permissions
- Use AdministratorAccess policy for testing (restrict in production)

### GCP: API Not Enabled
```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Cloudflare: Need API Token
- Go to https://dash.cloudflare.com/profile/api-tokens
- Create token with "Edit Cloudflare Workers" permissions
- Set: `export CLOUDFLARE_API_TOKEN=your_token`

## Next Steps

1. ✅ Test each cloud provider individually
2. ✅ Run the orchestrator with real endpoints
3. ✅ Monitor costs in each cloud console
4. ✅ Integrate into your applications
5. ✅ Scale to production workloads

## Success!

You now have **real cloud infrastructure** offloading compute from your local machine!

- **Zero local CPU** usage for heavy tasks
- **Automatic scaling** from 0 to thousands of concurrent requests
- **Global distribution** via edge networks
- **Pay only for what you use** - often just pennies per month
