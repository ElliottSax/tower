# Quick Credentials Setup

Get all cloud platforms running in 15 minutes!

## 1. Cloudflare Workers (2 minutes)

```bash
# Get API token
# 1. Go to: https://dash.cloudflare.com/profile/api-tokens
# 2. Click "Create Token"
# 3. Use "Edit Cloudflare Workers" template
# 4. Copy the token

# Set token
export CLOUDFLARE_API_TOKEN=your_token_here

# Deploy
cd /mnt/e/projects/my-first-worker
npm run deploy
```

## 2. AWS Lambda (5 minutes)

```bash
# Install AWS CLI (if not installed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS
aws configure
# Enter when prompted:
#   AWS Access Key ID: (from AWS IAM)
#   AWS Secret Access Key: (from AWS IAM)
#   Default region: us-east-1
#   Default output: json

# Get AWS credentials:
# 1. Go to: https://console.aws.amazon.com/iam/
# 2. Users → Your user → Security credentials
# 3. Create access key → CLI
# 4. Copy Access Key ID and Secret Access Key

# Install Serverless Framework
npm install -g serverless

# Deploy
cd /mnt/e/projects/compute/cloud-functions/aws-lambda
npm install
npm run deploy:prod
```

## 3. Google Cloud Functions (5 minutes)

```bash
# Authenticate (opens browser)
gcloud auth login

# Create project
gcloud projects create my-compute-workers --name="Compute Workers"

# Set project
gcloud config set project my-compute-workers

# Enable billing (required for Cloud Functions)
# Go to: https://console.cloud.google.com/billing
# Link billing account to project

# Enable APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Deploy
cd /mnt/e/projects/compute/cloud-functions/gcp-functions
npm install
./deploy-all.sh
```

## 4. Hugging Face (1 minute)

```bash
# Get API key:
# 1. Sign up: https://huggingface.co/
# 2. Go to: https://huggingface.co/settings/tokens
# 3. Create new token with "Inference API" permission
# 4. Copy token

# Add to config
# Edit compute/multi-cloud-orchestrator/config.js:
huggingface: {
  enabled: true,
  apiKey: 'hf_YOUR_TOKEN_HERE'
}
```

## 5. DeepSeek (1 minute)

```bash
# Get API key:
# 1. Sign up: https://platform.deepseek.com/
# 2. Go to API keys section
# 3. Create new API key
# 4. Copy key

# Add to config
# Edit compute/multi-cloud-orchestrator/config.js:
deepseek: {
  enabled: true,
  apiKey: 'sk_YOUR_KEY_HERE'
}
```

## 6. Replit (1 minute)

```bash
# Deploy via web:
# 1. Go to: https://replit.com/
# 2. Click "Create Repl"
# 3. Choose "Node.js"
# 4. Name it "compute-worker"
# 5. Copy files from: compute/cloud-functions/replit/compute-worker/
# 6. Paste into Repl
# 7. Click "Run"
# 8. Click "Deploy" → "Autoscale deployment"
# 9. Copy deployment URL

# Add to config
# Edit compute/multi-cloud-orchestrator/config.js:
replit: {
  enabled: true,
  endpoints: {
    'hash': 'https://YOUR-REPL.username.repl.co/compute/hash'
  }
}
```

## All-in-One Deploy Script

Once credentials are set up:

```bash
cd /mnt/e/projects/compute
./deploy-all.sh
```

## Quick Test

After deployment:

```bash
# Test Cloudflare
curl -X POST "https://my-first-worker.elliottsaxton.workers.dev/compute/hash" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" \
  -H "Content-Type: application/json" \
  -d '{"text": "test"}'

# Test orchestrator with all platforms
node compute/multi-cloud-orchestrator/examples/test-all.js
```

## Cost Tracking

After deploying, monitor costs:

- **Cloudflare**: https://dash.cloudflare.com/
- **AWS**: https://console.aws.amazon.com/billing/
- **GCP**: https://console.cloud.google.com/billing
- **Hugging Face**: https://huggingface.co/pricing
- **DeepSeek**: https://platform.deepseek.com/usage
- **Replit**: https://replit.com/account

## Free Tiers

Stay within free limits for testing:

- **Cloudflare**: 100,000 req/day
- **AWS Lambda**: 1M req/month + 400k GB-sec
- **GCP Functions**: 2M req/month + 400k GB-sec
- **Hugging Face**: 30,000 characters/month
- **DeepSeek**: Check current free tier
- **Replit**: Hacker plan ($7/month) needed for deployments

## Troubleshooting

### Cloudflare
**Error**: "API token not set"
**Fix**: `export CLOUDFLARE_API_TOKEN=your_token`

### AWS
**Error**: "Unable to locate credentials"
**Fix**: `aws configure` and enter credentials

### GCP
**Error**: "Project not set"
**Fix**: `gcloud config set project PROJECT_ID`

**Error**: "Billing not enabled"
**Fix**: Enable billing in console

### All Platforms
**Error**: "Rate limit exceeded"
**Fix**: Wait or upgrade to paid tier
