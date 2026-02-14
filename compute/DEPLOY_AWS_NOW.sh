#!/bin/bash
#
# AWS Lambda Quick Deploy Script
# Run this after: aws configure
#

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  AWS LAMBDA DEPLOYMENT                                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found!"
    echo ""
    echo "Install with:"
    echo "  sudo apt-get update && sudo apt-get install -y unzip"
    echo "  cd /tmp"
    echo "  curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip"
    echo "  unzip awscliv2.zip"
    echo "  sudo ./aws/install"
    echo ""
    exit 1
fi

echo "✅ AWS CLI found: $(aws --version)"
echo ""

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured!"
    echo ""
    echo "Run: aws configure"
    echo ""
    echo "You'll need:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Region: us-east-1"
    echo "  - Output: json"
    echo ""
    exit 1
fi

echo "✅ AWS credentials configured"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "   Account: $ACCOUNT"
echo ""

# Navigate to Lambda directory
cd /mnt/e/projects/compute/cloud-functions/aws-lambda

echo "📦 Installing dependencies..."
npm install --silent
echo "✅ Dependencies installed"
echo ""

# Deploy with Serverless
echo "🚀 Deploying Lambda functions..."
echo "   This may take 2-3 minutes..."
echo ""

npx serverless deploy

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  DEPLOYMENT COMPLETE!                                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# List deployed functions
echo "📋 Deployed Functions:"
aws lambda list-functions --region us-east-1 --query "Functions[?contains(FunctionName, 'aws-lambda-compute')].FunctionName" --output table

echo ""
echo "🎉 Your AWS Lambda functions are live!"
echo ""
echo "Test an endpoint:"
echo "  aws lambda invoke --function-name aws-lambda-compute-workers-prod-computeHash --payload '{\"text\":\"Hello\"}' response.json && cat response.json"
echo ""
