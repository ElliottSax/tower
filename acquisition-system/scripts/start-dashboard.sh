#!/bin/bash

# DealSourceAI Dashboard Startup Script
# Starts the Next.js dashboard with proper error handling

set -e

DASHBOARD_DIR="/mnt/e/projects/acquisition-system/dashboard"
PORT=3000

echo "🚀 Starting DealSourceAI Dashboard..."
echo ""

# Check if we're in the right directory
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "❌ Error: Dashboard directory not found at $DASHBOARD_DIR"
    exit 1
fi

cd "$DASHBOARD_DIR"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Kill any existing process on port 3000
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  Port $PORT is already in use. Killing existing process..."
    kill -9 $(lsof -ti:$PORT) 2>/dev/null || true
    sleep 2
fi

# Start the dev server
echo "🎨 Starting Next.js dev server..."
echo "📍 URL: http://localhost:$PORT/client"
echo ""
echo "Pages available:"
echo "  • http://localhost:$PORT/client           - Dashboard Home"
echo "  • http://localhost:$PORT/client/leads     - Leads"
echo "  • http://localhost:$PORT/client/campaigns - Campaigns"
echo "  • http://localhost:$PORT/client/responses - Responses"
echo "  • http://localhost:$PORT/client/analytics - Analytics"
echo "  • http://localhost:$PORT/client/settings  - Settings"
echo ""
echo "Press Ctrl+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start Next.js
npm run dev
