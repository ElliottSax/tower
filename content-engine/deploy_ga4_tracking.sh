#!/bin/bash
# GA4 Tracking Deployment Script
# Deploys GA4 tracking code to all 4 sites

set -e

echo "🚀 GA4 Tracking Deployment Script"
echo "=================================="
echo ""
echo "This script deploys GA4 tracking code to all 4 sites."
echo "IMPORTANT: You must have created GA4 properties first!"
echo ""
echo "Steps:"
echo "1. Go to: https://analytics.google.com"
echo "2. Create 4 properties (one per site)"
echo "3. Copy the Measurement IDs (G-XXXXXXXXXX)"
echo "4. Run this script and enter the IDs when prompted"
echo ""

# Function to prompt for ID
get_property_id() {
    local site=$1
    local domain=$2
    local default=$3

    echo ""
    read -p "Enter Measurement ID for $site ($domain) [default: $default]: " id
    id=${id:-$default}
    echo $id
}

# Get IDs from user (or use defaults for testing)
CREDIT_ID=$(get_property_id "CREDIT" "cardclassroom.com" "G-PLACEHOLDER1")
CALC_ID=$(get_property_id "CALC" "dividendengines.com" "G-PLACEHOLDER2")
AFFILIATE_ID=$(get_property_id "AFFILIATE" "thestackguide.com" "G-PLACEHOLDER3")
QUANT_ID=$(get_property_id "QUANT" "quantengines.com" "G-PLACEHOLDER4")

echo ""
echo "Deploying tracking code..."
echo ""

# Create tracking code template
create_tracking_code() {
    local id=$1
    cat <<EOF
{/* Google Analytics 4 Tracking */}
<script async src="https://www.googletagmanager.com/gtag/js?id=${id}"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', '${id}');

  // Track email signup events
  window.trackEmailSignup = (formType) => {
    gtag('event', 'email_signup', {
      'article_slug': document.body.getAttribute('data-article-slug'),
      'form_type': formType
    });
  };

  // Track affiliate clicks
  window.trackAffiliateClick = (network, toolName) => {
    gtag('event', 'affiliate_click', {
      'article_slug': document.body.getAttribute('data-article-slug'),
      'affiliate_network': network,
      'tool_name': toolName
    });
  };
</script>
EOF
}

# Save tracking codes
echo "✅ Created tracking code for CREDIT"
create_tracking_code "$CREDIT_ID" > /tmp/credit_tracking.txt

echo "✅ Created tracking code for CALC"
create_tracking_code "$CALC_ID" > /tmp/calc_tracking.txt

echo "✅ Created tracking code for AFFILIATE"
create_tracking_code "$AFFILIATE_ID" > /tmp/affiliate_tracking.txt

echo "✅ Created tracking code for QUANT"
create_tracking_code "$QUANT_ID" > /tmp/quant_tracking.txt

echo ""
echo "Tracking codes created. You can now:"
echo "1. View codes in: /tmp/*_tracking.txt"
echo "2. Add to each site's layout file"
echo "3. Or run: bash deploy_ga4_to_sites.sh"
echo ""
echo "To use sample codes (testing): bash deploy_ga4_sample.sh"
