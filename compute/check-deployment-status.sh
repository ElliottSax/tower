#!/bin/bash
#
# Check deployment status for all platforms
#

echo "╔════════════════════════════════════════════════════════╗"
echo "║  CLOUD PLATFORM DEPLOYMENT STATUS                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 1. Cloudflare
echo "1. CLOUDFLARE WORKERS"
echo "   Testing live deployment..."
RESPONSE=$(curl -s -X POST "https://my-first-worker.elliottsaxton.workers.dev/health" \
  -H "X-API-Key: SECRET_API_KEY_c7a3b8e2d1f0" 2>&1)

if echo "$RESPONSE" | grep -q "healthy"; then
    echo "   ✅ LIVE and responding"
    echo "   URL: https://my-first-worker.elliottsaxton.workers.dev"
else
    echo "   ⚠️  Response: $RESPONSE"
fi
echo ""

# 2. AWS Lambda
echo "2. AWS LAMBDA"
if command -v aws &> /dev/null; then
    echo "   ✅ AWS CLI installed"
    if aws sts get-caller-identity &> /dev/null; then
        echo "   ✅ AWS credentials configured"
        echo "   → Ready to deploy: cd cloud-functions/aws-lambda && npm run deploy:prod"
    else
        echo "   ⚠️  AWS credentials not configured"
        echo "   → Run: aws configure"
    fi
else
    echo "   ⚙️  AWS CLI installing..."
fi
echo ""

# 3. GCP Functions
echo "3. GOOGLE CLOUD FUNCTIONS"
if command -v gcloud &> /dev/null; then
    echo "   ✅ gcloud CLI installed"

    PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$PROJECT" ]; then
        echo "   ✅ Project: $PROJECT"

        # Check if any functions are deployed
        FUNCTIONS=$(gcloud functions list --project=$PROJECT 2>/dev/null | grep -c "computeHash" || echo "0")
        if [ "$FUNCTIONS" -gt "0" ]; then
            echo "   ✅ Functions deployed!"
            gcloud functions list --project=$PROJECT --format="table(name,httpsTrigger.url)" 2>/dev/null | head -5
        else
            echo "   🔄 Deployment in progress..."
            echo "   → Check: gcloud functions list --project=$PROJECT"
        fi
    else
        echo "   ⚠️  No project set"
    fi
fi
echo ""

# 4. Hugging Face
echo "4. HUGGING FACE"
echo "   📋 API-only service"
echo "   → Get API key: https://huggingface.co/settings/tokens"
echo "   → Add to orchestrator config"
echo ""

# 5. DeepSeek
echo "5. DEEPSEEK"
echo "   📋 API-only service"
echo "   → Get API key: https://platform.deepseek.com/"
echo "   → Add to orchestrator config"
echo ""

# 6. Replit
echo "6. REPLIT"
echo "   🌐 Web deployment"
echo "   → Deploy at: https://replit.com/"
echo "   → Use files from: cloud-functions/replit/compute-worker/"
echo ""

echo "═══════════════════════════════════════════════════════"
echo ""
echo "Tools Status:"
echo ""

check_tool() {
    if command -v $1 &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -1)
        echo "  ✅ $1: $VERSION"
    else
        echo "  ⚠️  $1: Not installed"
    fi
}

check_tool node
check_tool npm
check_tool wrangler
check_tool gcloud
check_tool serverless

if command -v aws &> /dev/null; then
    check_tool aws
else
    echo "  ⚙️  aws: Installing..."
fi

echo ""
echo "Next steps:"
echo "  1. Wait for GCP deployment (check with: gcloud functions list)"
echo "  2. Configure AWS: aws configure"
echo "  3. Get API keys for Hugging Face and DeepSeek"
echo "  4. Deploy to Replit via web"
echo ""
