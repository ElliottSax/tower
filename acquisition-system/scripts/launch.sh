#!/bin/bash

# DealSourceAI Master Launch Script
# One-command launch for the entire platform

set -e

PROJECT_ROOT="/mnt/e/projects/acquisition-system"

echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║        🚀 DEALSOURCEAI LAUNCH ASSISTANT               ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "What would you like to do?"
echo ""
echo "1) 🎨 Start Dashboard (http://localhost:3000/client)"
echo "2) 🌐 Deploy Landing Page (Vercel/Netlify)"
echo "3) 🎯 Extract Target Prospects (CSV export)"
echo "4) 🛠️  Setup Tools (CRM, email, calendar)"
echo "5) 📊 View Project Summary"
echo "6) 📧 Generate Outreach Email"
echo "7) 🔧 Full Development Environment"
echo "8) ❌ Exit"
echo ""
read -p "Select option (1-8): " choice

case $choice in
    1)
        echo ""
        bash "$PROJECT_ROOT/scripts/start-dashboard.sh"
        ;;

    2)
        echo ""
        bash "$PROJECT_ROOT/scripts/deploy-landing-page.sh"
        ;;

    3)
        echo ""
        bash "$PROJECT_ROOT/scripts/extract-targets.sh"
        ;;

    4)
        echo ""
        bash "$PROJECT_ROOT/scripts/setup-tools.sh"
        ;;

    5)
        echo ""
        cat "$PROJECT_ROOT/COMPLETE_SUMMARY.md" | less
        ;;

    6)
        echo ""
        echo "📧 Outreach Email Generator"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        read -p "Prospect type (search-fund/pe-firm/sponsor): " type
        read -p "Company name: " company
        read -p "Contact name: " name
        read -p "Industry focus: " industry

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📧 GENERATED EMAIL"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Subject: Off-market deal sourcing for $company"
        echo ""
        echo "Hi $name,"
        echo ""
        echo "I saw you're searching for $industry businesses to acquire through $company."
        echo ""
        echo "Quick question: How much time are you spending on deal sourcing vs. actually"
        echo "evaluating good opportunities?"
        echo ""
        echo "We built DealSourceAI to solve this: AI-powered sourcing that finds retiring"
        echo "business owners BEFORE they list with brokers."
        echo ""
        echo "Would you be open to a 15-min demo?"
        echo ""
        echo "Best,"
        echo "[Your Name]"
        echo ""
        echo "P.S. - We're offering 50% off (\$10K/month vs \$15K) for our first 2 clients."
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "✅ Email generated!"
        echo "📋 Copy the text above and personalize further"
        ;;

    7)
        echo ""
        echo "🔧 Starting Full Development Environment..."
        echo ""

        # Start dashboard in background
        cd "$PROJECT_ROOT/dashboard"
        npm run dev &
        DASH_PID=$!

        echo "✅ Dashboard starting (PID: $DASH_PID)"
        echo "   URL: http://localhost:3000/client"
        echo ""
        echo "📂 Project structure:"
        echo "   • Backend: $PROJECT_ROOT/backend/"
        echo "   • Dashboard: $PROJECT_ROOT/dashboard/"
        echo "   • GTM: $PROJECT_ROOT/go-to-market/"
        echo "   • Landing: $PROJECT_ROOT/landing-page/"
        echo ""
        echo "Press Ctrl+C to stop all services"
        echo ""

        wait $DASH_PID
        ;;

    8)
        echo "Goodbye!"
        exit 0
        ;;

    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Quick Commands:"
echo "   ./scripts/launch.sh          - Run this menu again"
echo "   ./scripts/start-dashboard.sh - Start dashboard only"
echo "   cat COMPLETE_SUMMARY.md      - View master plan"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
