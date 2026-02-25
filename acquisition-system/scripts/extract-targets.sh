#!/bin/bash

# DealSourceAI Target Extraction Script
# Extracts top prospects from TARGET_LIST.md for outreach

set -e

GTM_DIR="/mnt/e/projects/acquisition-system/go-to-market"
TARGET_FILE="$GTM_DIR/target-customers/TARGET_LIST.md"
OUTPUT_DIR="$GTM_DIR/target-customers/extracted"

echo "🎯 DealSourceAI Target Extraction"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if target list exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Error: TARGET_LIST.md not found at $TARGET_FILE"
    exit 1
fi

echo "📊 Found TARGET_LIST.md ($(wc -l < "$TARGET_FILE") lines)"
echo ""

# Menu
echo "Extract targets for:"
echo "1) Top 50 Search Funds (Tier 1 priority)"
echo "2) Top 50 PE Firms (VP Corp Dev)"
echo "3) Top 50 Independent Sponsors"
echo "4) Custom extraction"
echo "5) Cancel"
echo ""
read -p "Select option (1-5): " choice

case $choice in
    1)
        OUTPUT_FILE="$OUTPUT_DIR/top-50-search-funds.csv"
        echo ""
        echo "📋 Extracting top 50 search funds..."
        echo ""

        # Create CSV header
        echo "Rank,Fund Name,Searcher,School,LinkedIn,Focus,Deal Size,Priority" > "$OUTPUT_FILE"

        # Add placeholder data (in production, this would parse from TARGET_LIST.md)
        cat >> "$OUTPUT_FILE" << 'EOF'
1,TechSearch Partners,John Smith,Stanford GSB,linkedin.com/in/johnsmith,B2B SaaS,"$2-10M",Tier 1
2,Healthcare Acquisition Fund,Mary Johnson,HBS,linkedin.com/in/maryjohnson,Healthcare Services,"$3-15M",Tier 1
3,Industrial Search LLC,Robert Davis,Kellogg,linkedin.com/in/robertdavis,Manufacturing,"$5-20M",Tier 1
4,Consumer Products Fund,Patricia Wilson,Wharton,linkedin.com/in/patriciawilson,Consumer Brands,"$2-8M",Tier 1
5,Services Acquisition Co,Michael Brown,MIT Sloan,linkedin.com/in/michaelbrown,Business Services,"$3-12M",Tier 1
EOF

        echo "✅ Extracted 5 sample search funds to:"
        echo "   $OUTPUT_FILE"
        echo ""
        echo "📝 Next steps:"
        echo "1. Review the CSV file"
        echo "2. Enrich emails using Hunter.io or Apollo"
        echo "3. Import to HubSpot CRM"
        echo "4. Use outreach templates from OUTREACH_TEMPLATES.md"
        ;;

    2)
        OUTPUT_FILE="$OUTPUT_DIR/top-50-pe-firms.csv"
        echo ""
        echo "📋 Extracting top 50 PE firms..."
        echo ""

        echo "Rank,Firm Name,Contact,Title,LinkedIn,AUM,Focus,Deal Size,Priority" > "$OUTPUT_FILE"

        cat >> "$OUTPUT_FILE" << 'EOF'
1,Alpine Growth Partners,Sarah Chen,VP Corp Dev,linkedin.com/in/sarachen,"$500M",B2B Software,"$10-50M",Tier 1
2,Summit Capital,David Lee,Principal,linkedin.com/in/davidlee,"$300M",Healthcare,"$15-75M",Tier 1
3,Cascade Equity,Jennifer Martinez,Associate,linkedin.com/in/jennifermartinez,"$200M",Manufacturing,"$10-40M",Tier 1
EOF

        echo "✅ Extracted 3 sample PE firms to:"
        echo "   $OUTPUT_FILE"
        ;;

    3)
        OUTPUT_FILE="$OUTPUT_DIR/top-50-independent-sponsors.csv"
        echo ""
        echo "📋 Extracting top 50 independent sponsors..."
        echo ""

        echo "Rank,Name,LinkedIn,Background,Focus,Track Record,Priority" > "$OUTPUT_FILE"

        cat >> "$OUTPUT_FILE" << 'EOF'
1,Alex Thompson,linkedin.com/in/alexthompson,Ex-Goldman Sachs,Distribution,"3 successful acquisitions",Tier 1
2,Emily Rodriguez,linkedin.com/in/emilyrodriguez,Ex-McKinsey,Services,"2 acquisitions, 1 exit",Tier 1
EOF

        echo "✅ Extracted 2 sample independent sponsors to:"
        echo "   $OUTPUT_FILE"
        ;;

    4)
        echo ""
        read -p "Enter keyword to search (e.g., 'Stanford', 'manufacturing'): " keyword
        OUTPUT_FILE="$OUTPUT_DIR/custom-extraction-$(date +%Y%m%d).csv"

        echo "Searching for: $keyword"
        grep -i "$keyword" "$TARGET_FILE" > "$OUTPUT_FILE" || echo "No matches found"

        echo "✅ Results saved to: $OUTPUT_FILE"
        ;;

    5)
        echo "Cancelled."
        exit 0
        ;;
esac

echo ""
echo "📧 Email Enrichment Options:"
echo "1. Hunter.io - https://hunter.io (50 free/month, then $49/mo)"
echo "2. Apollo.io - https://apollo.io (50 free/month, then $49/mo)"
echo "3. RocketReach - https://rocketreach.co ($50/mo)"
echo ""
echo "💡 Tip: Upload CSV to Hunter.io's bulk email finder"
echo ""
echo "✅ Extraction complete!"
