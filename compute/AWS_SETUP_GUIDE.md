# 🚀 AWS Lambda Deployment Guide

Get your AWS Lambda functions deployed and operational in 5 minutes.

---

## 📋 Prerequisites

You'll need:
- AWS Account (free tier available)
- Access to run `sudo` commands
- 5 minutes

---

## ⚡ QUICK START (3 Steps)

### Step 1: Install AWS CLI (1 minute)

Run these commands in your WSL terminal:

```bash
# Install unzip
sudo apt-get update && sudo apt-get install -y unzip

# Download and install AWS CLI
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

**Expected output:** `aws-cli/2.x.x ...`

---

### Step 2: Get AWS Credentials (2 minutes)

#### Option A: Use Existing Credentials
If you already have AWS credentials, skip to Step 3.

#### Option B: Create New Credentials

1. Go to: https://console.aws.amazon.com/iam/
2. Click "Users" → "Create user"
3. User name: `lambda-deploy`
4. Click "Next"
5. Select "Attach policies directly"
6. Search and select:
   - `AWSLambdaFullAccess`
   - `IAMFullAccess` (for role creation)
   - `CloudFormationFullAccess`
7. Click "Next" → "Create user"
8. Click on the user → "Security credentials" tab
9. Click "Create access key"
10. Select "Command Line Interface (CLI)"
11. Check the confirmation box
12. Click "Create access key"
13. **Save both keys** (you'll need them in Step 3)

---

### Step 3: Configure AWS CLI (1 minute)

```bash
aws configure
```

Enter when prompted:
```
AWS Access Key ID: [YOUR_ACCESS_KEY_ID]
AWS Secret Access Key: [YOUR_SECRET_ACCESS_KEY]
Default region name: us-east-1
Default output format: json
```

**Test it:**
```bash
aws sts get-caller-identity
```

If you see your account info, you're ready!

---

## 🚀 Deploy Lambda Functions (Automated)

Once AWS CLI is configured, I'll deploy automatically:

```bash
cd /mnt/e/projects/compute/cloud-functions/aws-lambda
npm run deploy
```

This deploys **6 Lambda functions:**
1. `computeHash` - SHA-256 hashing
2. `processData` - Data transformation
3. `imageResize` - Image processing
4. `batchProcess` - Batch operations
5. `queueWorker` - Queue processing
6. `scheduler` - Scheduled tasks

---

## 📊 What You'll Get

After deployment, you'll have:

✅ **6 Lambda function endpoints**
```
https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/hash
https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/process
https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/resize
https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/batch
https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/queue
https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/schedule
```

✅ **Integrated with orchestrator** (automatic routing)

✅ **Cost:** $0.20 per 1M requests (first 1M free)

---

## 🔧 Alternative: Serverless Framework (If AWS CLI fails)

If you have issues with AWS CLI, use Serverless Framework directly:

```bash
cd /mnt/e/projects/compute/cloud-functions/aws-lambda

# Set credentials as environment variables
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1

# Deploy with Serverless
npx serverless deploy
```

---

## ✅ Verify Deployment

After deployment:

```bash
# List deployed functions
aws lambda list-functions --region us-east-1

# Test a function
aws lambda invoke \
  --function-name aws-lambda-compute-workers-prod-computeHash \
  --payload '{"text":"Hello"}' \
  response.json

cat response.json
```

---

## 💰 Cost Estimate

**AWS Lambda Free Tier:**
- 1M requests/month FREE
- 400,000 GB-seconds compute FREE

**After free tier:**
- $0.20 per 1M requests
- $0.0000166667 per GB-second

**Your estimated cost:** ~$0 - $5/month (depending on usage)

---

## 🎯 Next Steps

Once deployed:

1. **Test endpoints:**
   ```bash
   curl -X POST https://YOUR_ENDPOINT/prod/hash \
     -H "Content-Type: application/json" \
     -d '{"text":"Testing AWS Lambda"}'
   ```

2. **Integrate with orchestrator:**
   The orchestrator will automatically detect and use AWS Lambda

3. **Monitor:**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Invocations \
     --dimensions Name=FunctionName,Value=computeHash \
     --start-time 2026-01-29T00:00:00Z \
     --end-time 2026-01-29T23:59:59Z \
     --period 3600 \
     --statistics Sum
   ```

---

## 🆘 Troubleshooting

### Issue: "Command 'aws' not found"
**Fix:** AWS CLI not installed properly. Re-run Step 1.

### Issue: "Could not connect to the endpoint URL"
**Fix:** Check region in `aws configure` (should be us-east-1)

### Issue: "Access Denied"
**Fix:** IAM user needs Lambda, IAM, and CloudFormation permissions

### Issue: "sudo: unable to resolve host"
**Fix:** This is a WSL warning, ignore it or add your hostname to `/etc/hosts`

---

## 📁 Files

**Handlers:** `/mnt/e/projects/compute/cloud-functions/aws-lambda/handlers/`
- `hash.js`
- `process.js`
- `resize.js`
- `batch.js`
- `queue.js`
- `schedule.js`

**Config:** `serverless.yml`
**Package:** `package.json`

---

## 🎉 Summary

**Time:** 5 minutes total
**Cost:** Free (with AWS free tier)
**Result:** 6 Lambda functions + orchestrator integration

**After setup, your orchestrator will have:**
- 6 AI platforms (OpenRouter, Groq, DeepSeek, Cerebras, Replicate, Together)
- 6 AWS Lambda functions
- 1 Local provider
- **Total: 13 compute providers!**

---

**Ready? Run the commands in Step 1 and let me know when done!**
