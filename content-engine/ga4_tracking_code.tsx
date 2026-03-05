/**
 * Google Analytics 4 Tracking Code
 * Add this to your layout.tsx <head> section
 *
 * Instructions:
 * 1. Replace GA_MEASUREMENT_ID with your actual ID (format: G-XXXXXXXXXX)
 * 2. Add to <head> section of app/layout.tsx or similar
 * 3. Add event tracking to buttons (see examples below)
 */

// Copy this entire block into your <head>:
// =====================================================

<script
  async
  src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"
></script>
<script>
  {`
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'GA_MEASUREMENT_ID', {
      send_page_view: true,
      anonymize_ip: false
    });

    // Track email signup events
    window.trackEmailSignup = (formType = 'inline') => {
      gtag('event', 'email_signup', {
        article_slug: document.body.getAttribute('data-article-slug') || 'unknown',
        form_type: formType,
        timestamp: new Date().toISOString()
      });
    };

    // Track affiliate clicks
    window.trackAffiliateClick = (network, toolName) => {
      gtag('event', 'affiliate_click', {
        article_slug: document.body.getAttribute('data-article-slug') || 'unknown',
        affiliate_network: network,
        tool_name: toolName,
        timestamp: new Date().toISOString()
      });
    };

    // Track calculator usage
    window.trackCalculatorUsed = (calculatorName) => {
      gtag('event', 'calculator_used', {
        article_slug: document.body.getAttribute('data-article-slug') || 'unknown',
        calculator_name: calculatorName,
        timestamp: new Date().toISOString()
      });
    };

    // Track scroll depth
    let maxScroll = 0;
    window.addEventListener('scroll', () => {
      const scrollPercent = Math.round((window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100);

      if (scrollPercent >= 100 && maxScroll < 100) {
        gtag('event', 'scroll_to_100', {
          article_slug: document.body.getAttribute('data-article-slug') || 'unknown'
        });
        maxScroll = 100;
      } else if (scrollPercent >= 75 && maxScroll < 75) {
        gtag('event', 'scroll_to_75', {
          article_slug: document.body.getAttribute('data-article-slug') || 'unknown'
        });
        maxScroll = 75;
      } else if (scrollPercent >= 50 && maxScroll < 50) {
        gtag('event', 'scroll_to_50', {
          article_slug: document.body.getAttribute('data-article-slug') || 'unknown'
        });
        maxScroll = 50;
      }
    });
  `}
</script>

// =====================================================
// HOW TO USE:
// =====================================================

// 1. EMAIL SIGNUP TRACKING
// Add to email form submit button:
<button
  type="submit"
  onClick={() => window.trackEmailSignup('exit_intent')}
>
  Sign Up Free
</button>

// 2. AFFILIATE CLICK TRACKING
// Add to affiliate links:
<a
  href="/go/tool-name"
  onClick={() => window.trackAffiliateClick('cj', 'tool-name')}
>
  Try Tool →
</a>

// 3. CALCULATOR TRACKING
// Add to calculator submit:
<button
  onClick={() => {
    window.trackCalculatorUsed('retirement-calculator');
    // ... calculate logic
  }}
>
  Calculate
</button>

// 4. SCROLL DEPTH (Automatic)
// Automatically tracks when users scroll to 50%, 75%, 100%
// No action needed - works automatically

// =====================================================
// TROUBLESHOOTING
// =====================================================

// Check if GA4 is loaded:
// Open DevTools Console and run:
// console.log(window.dataLayer)
// If array with events exists, GA4 is working!

// Verify tracking code installed:
// DevTools → Network → Filter "analytics"
// Should see requests to googletagmanager.com

// Test event tracking:
// Open Console and run:
// gtag('event', 'test_event', { 'test': 'value' })
// Should appear in GA4 within seconds
