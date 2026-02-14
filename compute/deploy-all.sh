#!/bin/bash
#
# Deploy to ALL Cloud Platforms
# This script deploys to Cloudflare, AWS, GCP, and Replit
#

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  DEPLOYING TO ALL CLOUD PLATFORMS                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found"
        return 1
    fi
}

# Check tools
MISSING=0
check_command node || MISSING=1
check_command npm || MISSING=1
check_command wrangler || MISSING=1
check_command aws || MISSING=1
check_command gcloud || MISSING=1
check_command serverless || MISSING=1

echo ""

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}⚠${NC}  Some tools are missing. Installing..."

    # Install serverless if missing
    if ! command -v serverless &> /dev/null; then
        echo "Installing Serverless Framework..."
        npm install -g serverless
    fi

    echo ""
fi

# Check credentials
echo "Checking cloud credentials..."
echo ""

# Cloudflare
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${YELLOW}⚠${NC}  CLOUDFLARE_API_TOKEN not set"
    echo "   Get token: https://dash.cloudflare.com/profile/api-tokens"
    echo "   Then: export CLOUDFLARE_API_TOKEN=your_token"
    CLOUDFLARE_READY=0
else
    echo -e "${GREEN}✓${NC} Cloudflare credentials found"
    CLOUDFLARE_READY=1
fi

# AWS
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS credentials configured"
    AWS_READY=1
else
    echo -e "${YELLOW}⚠${NC}  AWS credentials not configured"
    echo "   Run: aws configure"
    AWS_READY=0
fi

# GCP
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
    echo -e "${GREEN}✓${NC} GCP credentials configured"
    GCP_READY=1
else
    echo -e "${YELLOW}⚠${NC}  GCP not authenticated"
    echo "   Run: gcloud auth login"
    GCP_READY=0
fi

echo ""
echo "═════════════════════════════════════════════════════════"
echo ""

# 1. Deploy Cloudflare Worker
if [ $CLOUDFLARE_READY -eq 1 ]; then
    echo "1/3 Deploying Cloudflare Worker..."
    cd /mnt/e/projects/my-first-worker
    npm run deploy
    echo -e "${GREEN}✓${NC} Cloudflare Worker deployed"
    echo ""
else
    echo -e "${YELLOW}⊘${NC} Skipping Cloudflare (no credentials)"
    echo ""
fi

# 2. Deploy AWS Lambda
if [ $AWS_READY -eq 1 ]; then
    echo "2/3 Deploying AWS Lambda functions..."
    cd /mnt/e/projects/compute/cloud-functions/aws-lambda

    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi

    npm run deploy:prod
    echo -e "${GREEN}✓${NC} AWS Lambda deployed"
    echo ""

    # Save endpoints
    echo "AWS Lambda endpoints have been deployed!"
    echo "Copy the URLs from above and update your orchestrator config."
    echo ""
else
    echo -e "${YELLOW}⊘${NC} Skipping AWS Lambda (no credentials)"
    echo ""
fi

# 3. Deploy GCP Functions
if [ $GCP_READY -eq 1 ]; then
    echo "3/3 Deploying GCP Cloud Functions..."
    cd /mnt/e/projects/compute/cloud-functions/gcp-functions

    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi

    # Check if project is set
    PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT" ]; then
        echo -e "${YELLOW}⚠${NC}  No GCP project set"
        echo "   Run: gcloud config set project YOUR_PROJECT_ID"
        echo -e "${YELLOW}⊘${NC} Skipping GCP deployment"
    else
        echo "Deploying to project: $PROJECT"

        # Enable APIs
        echo "Enabling required APIs..."
        gcloud services enable cloudfunctions.googleapis.com --quiet 2>/dev/null || true
        gcloud services enable cloudbuild.googleapis.com --quiet 2>/dev/null || true

        # Deploy functions
        chmod +x deploy-all.sh
        ./deploy-all.sh

        echo -e "${GREEN}✓${NC} GCP Functions deployed"
        echo ""

        # Show URLs
        echo "GCP Function URLs:"
        gcloud functions list --region us-central1 --format="value(name,httpsTrigger.url)"
        echo ""
    fi
else
    echo -e "${YELLOW}⊘${NC} Skipping GCP (not authenticated)"
    echo ""
fi

echo "═════════════════════════════════════════════════════════"
echo ""
echo "Deployment Summary:"
echo ""

if [ $CLOUDFLARE_READY -eq 1 ]; then
    echo -e "${GREEN}✓${NC} Cloudflare Worker"
else
    echo -e "${YELLOW}⊘${NC} Cloudflare Worker (credentials needed)"
fi

if [ $AWS_READY -eq 1 ]; then
    echo -e "${GREEN}✓${NC} AWS Lambda"
else
    echo -e "${YELLOW}⊘${NC} AWS Lambda (credentials needed)"
fi

if [ $GCP_READY -eq 1 ]; then
    echo -e "${GREEN}✓${NC} GCP Functions"
else
    echo -e "${YELLOW}⊘${NC} GCP Functions (authentication needed)"
fi

echo ""
echo "Next steps:"
echo ""
echo "1. For API-only services:"
echo "   - Hugging Face: Get API key at https://huggingface.co/settings/tokens"
echo "   - DeepSeek: Get API key at https://platform.deepseek.com/"
echo ""
echo "2. For Replit:"
echo "   - Go to https://replit.com/"
echo "   - Create new Node.js Repl"
echo "   - Copy files from compute/cloud-functions/replit/compute-worker/"
echo "   - Click Deploy"
echo ""
echo "3. Update orchestrator config with all endpoints"
echo "   Edit: compute/multi-cloud-orchestrator/config.js"
echo ""
echo "4. Test everything:"
echo "   node compute/multi-cloud-orchestrator/examples/test-all.js"
echo ""
echo "═════════════════════════════════════════════════════════"
