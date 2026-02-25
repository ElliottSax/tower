#!/bin/bash

# DealSourceAI Landing Page Deployment Script
# Deploys to Vercel or Netlify

set -e

LANDING_PAGE_DIR="/mnt/e/projects/acquisition-system/landing-page"
DOMAIN="dealsourceai.com"

echo "🚀 DealSourceAI Landing Page Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$LANDING_PAGE_DIR"

# Check if landing page exists
if [ ! -f "index.html" ]; then
    echo "❌ Error: index.html not found"
    exit 1
fi

echo "📄 Landing page found: index.html ($(wc -c < index.html | numfmt --to=iec-i)B)"
echo ""

# Menu for deployment options
echo "Choose deployment method:"
echo "1) Vercel (recommended)"
echo "2) Netlify"
echo "3) Manual (show instructions)"
echo "4) Cancel"
echo ""
read -p "Select option (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🔷 Deploying to Vercel..."
        echo ""

        # Check if Vercel CLI is installed
        if ! command -v vercel &> /dev/null; then
            echo "📦 Vercel CLI not found. Installing..."
            npm install -g vercel
        fi

        echo "Running: vercel --prod"
        vercel --prod

        echo ""
        echo "✅ Deployed to Vercel!"
        echo "🌐 Your site should be live at: https://$DOMAIN"
        echo ""
        echo "Next steps:"
        echo "1. Go to vercel.com/dashboard"
        echo "2. Add custom domain: $DOMAIN"
        echo "3. Update DNS records at your domain registrar"
        ;;

    2)
        echo ""
        echo "🟢 Deploying to Netlify..."
        echo ""

        # Check if Netlify CLI is installed
        if ! command -v netlify &> /dev/null; then
            echo "📦 Netlify CLI not found. Installing..."
            npm install -g netlify-cli
        fi

        echo "Running: netlify deploy --prod"
        netlify deploy --prod --dir=.

        echo ""
        echo "✅ Deployed to Netlify!"
        echo "🌐 Your site should be live at: https://$DOMAIN"
        ;;

    3)
        echo ""
        echo "📋 Manual Deployment Instructions"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Option A: Vercel (Easiest)"
        echo "1. Go to vercel.com and sign up"
        echo "2. Click 'Add New Project'"
        echo "3. Upload this file: $LANDING_PAGE_DIR/index.html"
        echo "4. Deploy and add custom domain: $DOMAIN"
        echo ""
        echo "Option B: Netlify"
        echo "1. Go to netlify.com and sign up"
        echo "2. Drag and drop the landing-page folder"
        echo "3. Add custom domain: $DOMAIN"
        echo ""
        echo "Option C: GitHub Pages"
        echo "1. Create a GitHub repo: dealsourceai-landing"
        echo "2. Push index.html to main branch"
        echo "3. Enable GitHub Pages in repo settings"
        echo "4. Add custom domain: $DOMAIN"
        echo ""
        echo "File to deploy: $LANDING_PAGE_DIR/index.html"
        ;;

    4)
        echo "Cancelled."
        exit 0
        ;;

    *)
        echo "Invalid option. Cancelled."
        exit 1
        ;;
esac

echo ""
echo "✅ Deployment complete!"
