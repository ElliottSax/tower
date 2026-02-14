#!/bin/bash
#
# Deploy all GCP Cloud Functions
#

set -e

echo "Deploying all GCP Cloud Functions..."
echo ""

REGION=${REGION:-us-central1}
RUNTIME=${RUNTIME:-nodejs20}

echo "Configuration:"
echo "  Region: $REGION"
echo "  Runtime: $RUNTIME"
echo ""

# Deploy computeHash
echo "1/4 Deploying computeHash..."
gcloud functions deploy computeHash \
  --runtime $RUNTIME \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point computeHash \
  --source . \
  --region $REGION \
  --memory 512MB \
  --timeout 30s

echo "✓ computeHash deployed"
echo ""

# Deploy analyzeText
echo "2/4 Deploying analyzeText..."
gcloud functions deploy analyzeText \
  --runtime $RUNTIME \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point analyzeText \
  --source . \
  --region $REGION \
  --memory 512MB \
  --timeout 30s

echo "✓ analyzeText deployed"
echo ""

# Deploy transformData
echo "3/4 Deploying transformData..."
gcloud functions deploy transformData \
  --runtime $RUNTIME \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point transformData \
  --source . \
  --region $REGION \
  --memory 512MB \
  --timeout 30s

echo "✓ transformData deployed"
echo ""

# Deploy heavyCompute
echo "4/4 Deploying heavyCompute..."
gcloud functions deploy heavyCompute \
  --runtime $RUNTIME \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point heavyCompute \
  --source . \
  --region $REGION \
  --memory 1GB \
  --timeout 60s

echo "✓ heavyCompute deployed"
echo ""

echo "========================================="
echo "All functions deployed successfully!"
echo "========================================="
echo ""
echo "Get function URLs with:"
echo "  gcloud functions list --region $REGION"
echo ""
