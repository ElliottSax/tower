# AWS Lambda Compute Workers

Real AWS Lambda functions for cloud compute offloading.

## Features

- ✅ **Real Lambda functions** - Deploy to actual AWS infrastructure
- ✅ **Multiple compute types** - Hash, text analysis, data transform, heavy compute, image processing
- ✅ **Batch orchestration** - Process multiple tasks in parallel
- ✅ **HTTP API** - RESTful endpoints via API Gateway
- ✅ **CORS enabled** - Call from any domain
- ✅ **Auto-scaling** - Lambda scales automatically
- ✅ **Pay per use** - Only pay for actual compute time

## Quick Start

### 1. Install Dependencies

```bash
cd /mnt/e/projects/compute/cloud-functions/aws-lambda
npm install
```

### 2. Configure AWS Credentials

```bash
# Install AWS CLI if not already installed
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# sudo ./aws/install

# Configure credentials
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json
```

### 3. Deploy to AWS

```bash
# Install Serverless Framework
npm install -g serverless

# Deploy to dev environment
npm run deploy:dev

# Or deploy to production
npm run deploy:prod
```

### 4. Get Endpoint URLs

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

Save these URLs - you'll use them in the orchestrator!

## Testing Functions

### Test Hash Function

```bash
curl -X POST https://YOUR-API-URL/dev/compute/hash \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, AWS Lambda!"}'
```

### Test Text Analysis

```bash
curl -X POST https://YOUR-API-URL/dev/compute/text-analysis \
  -H "Content-Type: application/json" \
  -d '{"text": "The quick brown fox jumps over the lazy dog. This is a test."}'
```

### Test Data Transform

```bash
curl -X POST https://YOUR-API-URL/dev/compute/data-transform \
  -H "Content-Type: application/json" \
  -d '{"data": [5, 2, 8, 1, 9], "operation": "sort"}'
```

### Test Heavy Compute

```bash
curl -X POST https://YOUR-API-URL/dev/compute/heavy \
  -H "Content-Type: application/json" \
  -d '{"iterations": 100000, "operation": "mixed"}'
```

### Test Batch Processing

```bash
curl -X POST https://YOUR-API-URL/dev/batch \
  -H "Content-Type: application/json" \
  -d '{
    "tasks": [
      {"type": "hash", "payload": {"text": "test1"}},
      {"type": "hash", "payload": {"text": "test2"}},
      {"type": "data-transform", "payload": {"data": [1,2,3], "operation": "sum"}}
    ]
  }'
```

## Available Functions

### 1. computeHash
- **Path:** `/compute/hash`
- **Input:** `{ "text": "string" }`
- **Output:** SHA-256 hash
- **Memory:** 512 MB
- **Timeout:** 30s

### 2. analyzeText
- **Path:** `/compute/text-analysis`
- **Input:** `{ "text": "string" }`
- **Output:** Comprehensive text statistics
- **Memory:** 512 MB
- **Timeout:** 30s

### 3. transformData
- **Path:** `/compute/data-transform`
- **Input:** `{ "data": [], "operation": "sort|sum|average|..." }`
- **Output:** Transformed data
- **Memory:** 512 MB
- **Timeout:** 30s
- **Operations:** sum, average, median, sort, reverse, dedupe, filter, map, reduce

### 4. heavyCompute
- **Path:** `/compute/heavy`
- **Input:** `{ "iterations": number, "operation": "mixed|sqrt|trig|prime|fibonacci" }`
- **Output:** Computation result and performance stats
- **Memory:** 1024 MB
- **Timeout:** 60s

### 5. processImage
- **Path:** `/compute/image`
- **Input:** `{ "url": "string" OR "base64": "string", "operation": "resize|thumbnail|..." }`
- **Output:** Processed image (base64) and metadata
- **Memory:** 2048 MB
- **Timeout:** 120s
- **Operations:** resize, thumbnail, format, optimize, grayscale, blur

### 6. batchOrchestrator
- **Path:** `/batch`
- **Input:** `{ "tasks": [{"type": "...", "payload": {...}}] }`
- **Output:** Results from all tasks
- **Memory:** 512 MB
- **Timeout:** 30s

## Cost Estimation

AWS Lambda pricing (us-east-1):
- **Requests:** $0.20 per 1M requests
- **Duration:** $0.0000166667 per GB-second

**Example costs:**

| Function | Memory | Avg Duration | Cost per 1000 calls |
|----------|--------|--------------|---------------------|
| computeHash | 512 MB | 50ms | $0.20 + $0.004 = **$0.204** |
| analyzeText | 512 MB | 100ms | $0.20 + $0.008 = **$0.208** |
| transformData | 512 MB | 80ms | $0.20 + $0.007 = **$0.207** |
| heavyCompute | 1024 MB | 500ms | $0.20 + $0.083 = **$0.283** |
| processImage | 2048 MB | 1000ms | $0.20 + $0.333 = **$0.533** |

**Monthly free tier:**
- 1M requests per month
- 400,000 GB-seconds of compute time

## Monitoring

### View Logs

```bash
# View logs for a specific function
serverless logs -f computeHash -t

# View logs from last 5 minutes
serverless logs -f analyzeText --startTime 5m
```

### CloudWatch Metrics

View in AWS Console:
1. Go to CloudWatch
2. Select "Metrics"
3. Choose "Lambda"
4. View invocations, errors, duration, etc.

## Local Development

Test functions locally without deploying:

```bash
# Start offline mode
npm run offline

# Test locally
curl -X POST http://localhost:3000/dev/compute/hash \
  -H "Content-Type: application/json" \
  -d '{"text": "local test"}'
```

## Deployment Options

### Deploy Individual Function

```bash
serverless deploy function -f computeHash
```

### Deploy to Different Stages

```bash
# Development
serverless deploy --stage dev

# Staging
serverless deploy --stage staging

# Production
serverless deploy --stage prod
```

### Deploy to Different Regions

```bash
serverless deploy --region us-west-2
serverless deploy --region eu-west-1
serverless deploy --region ap-southeast-1
```

## Integration with Orchestrator

Update your orchestrator config:

```javascript
const orchestrator = new Orchestrator({
  aws: {
    enabled: true,
    endpoints: {
      hash: 'https://YOUR-API/dev/compute/hash',
      textAnalysis: 'https://YOUR-API/dev/compute/text-analysis',
      dataTransform: 'https://YOUR-API/dev/compute/data-transform',
      heavyCompute: 'https://YOUR-API/dev/compute/heavy',
      image: 'https://YOUR-API/dev/compute/image',
      batch: 'https://YOUR-API/dev/batch'
    }
  }
});
```

## Cleanup

Remove all deployed functions:

```bash
serverless remove
```

## Troubleshooting

### Permission Denied

Make sure your AWS credentials have the necessary permissions:
- Lambda: Full access
- API Gateway: Full access
- CloudWatch Logs: Write access
- IAM: Create/update roles

### Function Timeout

Increase timeout in `serverless.yml`:

```yaml
functions:
  myFunction:
    timeout: 120  # Max 900 seconds (15 minutes)
```

### Memory Issues

Increase memory in `serverless.yml`:

```yaml
functions:
  myFunction:
    memorySize: 3008  # Max 10240 MB
```

## Next Steps

1. ✅ Deploy functions to AWS
2. ✅ Test each endpoint
3. ✅ Update orchestrator with real endpoints
4. ✅ Monitor costs and performance
5. ✅ Scale to production workloads
