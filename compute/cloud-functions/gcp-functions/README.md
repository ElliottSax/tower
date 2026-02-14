# Google Cloud Functions - Compute Workers

Real Google Cloud Functions for cloud compute offloading.

## Features

- ✅ **Real Cloud Functions** - Deploy to actual GCP infrastructure
- ✅ **HTTP triggers** - RESTful API endpoints
- ✅ **Auto-scaling** - Scales from 0 to thousands of instances
- ✅ **Pay per use** - Only pay for invocations and compute time
- ✅ **Global deployment** - Deploy to regions worldwide
- ✅ **CORS enabled** - Call from any domain

## Quick Start

### 1. Install gcloud CLI

If not already installed:

```bash
# Download and install
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize
gcloud init
```

### 2. Install Dependencies

```bash
cd /mnt/e/projects/compute/cloud-functions/gcp-functions
npm install
```

### 3. Configure GCP Project

```bash
# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Enable Cloud Functions API
gcloud services enable cloudfunctions.googleapis.com

# Enable Cloud Build API (required for deployments)
gcloud services enable cloudbuild.googleapis.com
```

### 4. Deploy Functions

#### Deploy All Functions

```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

#### Deploy Individual Functions

```bash
# Hash function
gcloud functions deploy computeHash \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point computeHash \
  --source . \
  --region us-central1

# Text analysis
gcloud functions deploy analyzeText \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point analyzeText \
  --source . \
  --region us-central1

# Data transform
gcloud functions deploy transformData \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point transformData \
  --source . \
  --region us-central1

# Heavy compute
gcloud functions deploy heavyCompute \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point heavyCompute \
  --source . \
  --region us-central1 \
  --memory 1GB \
  --timeout 60s
```

### 5. Get Function URLs

```bash
gcloud functions list --region us-central1
```

You'll see output like:

```
NAME            STATUS  TRIGGER       REGION        URL
computeHash     ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/computeHash
analyzeText     ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/analyzeText
transformData   ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/transformData
heavyCompute    ACTIVE  HTTP Trigger  us-central1   https://us-central1-PROJECT.cloudfunctions.net/heavyCompute
```

## Testing Functions

### Test Hash Function

```bash
curl -X POST https://REGION-PROJECT.cloudfunctions.net/computeHash \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, GCP!"}'
```

### Test Text Analysis

```bash
curl -X POST https://REGION-PROJECT.cloudfunctions.net/analyzeText \
  -H "Content-Type: application/json" \
  -d '{"text": "The quick brown fox jumps over the lazy dog."}'
```

### Test Data Transform

```bash
curl -X POST https://REGION-PROJECT.cloudfunctions.net/transformData \
  -H "Content-Type: application/json" \
  -d '{"data": [5, 2, 8, 1, 9], "operation": "sort"}'
```

### Test Heavy Compute

```bash
curl -X POST https://REGION-PROJECT.cloudfunctions.net/heavyCompute \
  -H "Content-Type: application/json" \
  -d '{"iterations": 100000, "operation": "mixed"}'
```

## Available Functions

### 1. computeHash
- **Entry Point:** `computeHash`
- **Input:** `{ "text": "string" }`
- **Output:** SHA-256 hash
- **Memory:** 512 MB
- **Timeout:** 30s

### 2. analyzeText
- **Entry Point:** `analyzeText`
- **Input:** `{ "text": "string" }`
- **Output:** Comprehensive text statistics
- **Memory:** 512 MB
- **Timeout:** 30s

### 3. transformData
- **Entry Point:** `transformData`
- **Input:** `{ "data": [], "operation": "sort|sum|average|median|reverse|dedupe" }`
- **Output:** Transformed data
- **Memory:** 512 MB
- **Timeout:** 30s

### 4. heavyCompute
- **Entry Point:** `heavyCompute`
- **Input:** `{ "iterations": number, "operation": "mixed|sqrt|trig|prime" }`
- **Output:** Computation result and performance stats
- **Memory:** 1 GB
- **Timeout:** 60s

## Deployment Options

### Deploy to Different Regions

```bash
# US Central
gcloud functions deploy computeHash --region us-central1 ...

# US East
gcloud functions deploy computeHash --region us-east1 ...

# Europe West
gcloud functions deploy computeHash --region europe-west1 ...

# Asia Northeast
gcloud functions deploy computeHash --region asia-northeast1 ...
```

### Adjust Memory and Timeout

```bash
gcloud functions deploy myFunction \
  --memory 2GB \
  --timeout 300s \
  ...
```

Memory options: 128MB, 256MB, 512MB, 1GB, 2GB, 4GB, 8GB

### Private Functions (Require Authentication)

```bash
gcloud functions deploy myFunction \
  --no-allow-unauthenticated \
  ...
```

## Cost Estimation

Google Cloud Functions pricing:

- **Invocations:** $0.40 per 1M invocations
- **Compute Time:**
  - 128MB: $0.000000231 per 100ms
  - 256MB: $0.000000463 per 100ms
  - 512MB: $0.000000925 per 100ms
  - 1GB: $0.000001650 per 100ms
  - 2GB: $0.000002900 per 100ms

**Example costs:**

| Function | Memory | Avg Duration | Cost per 1000 calls |
|----------|--------|--------------|---------------------|
| computeHash | 512MB | 50ms | $0.40 + $0.046 = **$0.446** |
| analyzeText | 512MB | 100ms | $0.40 + $0.093 = **$0.493** |
| transformData | 512MB | 80ms | $0.40 + $0.074 = **$0.474** |
| heavyCompute | 1GB | 500ms | $0.40 + $0.825 = **$1.225** |

**Monthly free tier:**
- 2M invocations
- 400,000 GB-seconds
- 200,000 GHz-seconds

## Monitoring

### View Logs

```bash
# View logs for a function
gcloud functions logs read computeHash --region us-central1

# Follow logs in real-time
gcloud functions logs read computeHash --region us-central1 --limit 50 --follow
```

### Cloud Console Monitoring

1. Go to https://console.cloud.google.com/functions
2. Click on a function
3. View "Metrics" tab for:
   - Invocations per second
   - Execution time
   - Memory usage
   - Error rate

## Local Development

Test functions locally:

```bash
# Install Functions Framework
npm install -g @google-cloud/functions-framework

# Run locally
functions-framework --target=computeHash --port=8080

# Test locally
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"text": "local test"}'
```

## Integration with Orchestrator

Update your orchestrator config:

```javascript
const orchestrator = new Orchestrator({
  gcp: {
    enabled: true,
    endpoints: {
      hash: 'https://REGION-PROJECT.cloudfunctions.net/computeHash',
      textAnalysis: 'https://REGION-PROJECT.cloudfunctions.net/analyzeText',
      dataTransform: 'https://REGION-PROJECT.cloudfunctions.net/transformData',
      heavyCompute: 'https://REGION-PROJECT.cloudfunctions.net/heavyCompute'
    }
  }
});
```

## Cleanup

Delete all functions:

```bash
gcloud functions delete computeHash --region us-central1
gcloud functions delete analyzeText --region us-central1
gcloud functions delete transformData --region us-central1
gcloud functions delete heavyCompute --region us-central1
```

Or delete them all at once:

```bash
for func in computeHash analyzeText transformData heavyCompute; do
  gcloud functions delete $func --region us-central1 --quiet
done
```

## Troubleshooting

### Permission Denied

Enable required APIs:

```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Function Not Found

Make sure you're using the correct region:

```bash
gcloud functions list --regions us-central1
```

### Memory Limit Exceeded

Increase memory allocation:

```bash
gcloud functions deploy myFunction --memory 2GB ...
```

## Next Steps

1. ✅ Deploy functions to GCP
2. ✅ Test each endpoint
3. ✅ Update orchestrator with real URLs
4. ✅ Monitor costs and performance
5. ✅ Scale to production
