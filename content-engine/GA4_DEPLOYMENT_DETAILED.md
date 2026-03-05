# GA4 Tracking Deployment - Detailed Instructions

Deploy tracking code to all 4 sites in 10 minutes.

---

## Prerequisites

Before deploying, you must create GA4 properties:

1. Go to: https://analytics.google.com
2. Click **Admin** (⚙️ bottom left)
3. Click **Create Property** (in "Property" column)
4. For each site:
   - Property name: `[Site Name] - 2026`
   - Website URL: `cardclassroom.com` (or your domain)
   - Click **Create**
   - Copy the **Measurement ID** (format: `G-XXXXXXXXXX`)

**Save these 4 IDs:**
```
CREDIT:    G-_____________
CALC:      G-_____________
AFFILIATE: G-_____________
QUANT:     G-_____________
```

---

## Site 1: CREDIT (cardclassroom.com)

**File**: `/mnt/e/projects/credit/app/layout.tsx`

### Step 1: Find the `<head>` section

Open the file and locate the opening `<head>` tag. Should look like:

```tsx
<head>
  {/* Other meta tags and scripts */}
</head>
```

### Step 2: Add GA4 tracking code

Add this after the last script in `<head>` but before `</head>`:

```tsx
{/* Google Analytics 4 */}
<script
  async
  src="https://www.googletagmanager.com/gtag/js?id=G-YOUR_CREDIT_ID"
></script>
<script>
  {`
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-YOUR_CREDIT_ID');

    // Track email signup
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
  `}
</script>
```

**Replace `G-YOUR_CREDIT_ID`** with your actual Measurement ID.

### Step 3: Add event tracking to buttons

Find email signup buttons and add click handler:

```tsx
<button
  onClick={() => window.trackEmailSignup('exit_intent')}
  type="submit"
>
  Sign Up Free
</button>
```

Find affiliate links and add click handler:

```tsx
<a
  href="/go/tool-name"
  onClick={() => window.trackAffiliateClick('cj', 'hubspot')}
>
  Learn More →
</a>
```

### Step 4: Commit and push

```bash
cd /mnt/e/projects/credit
git add app/layout.tsx
git commit -m "feat(analytics): Add Google Analytics 4 tracking"
git push origin master
```

---

## Site 2: CALC (dividendengines.com)

**File**: `/mnt/e/projects/calc/app/layout.tsx`

Repeat the same process as CREDIT:

1. Open `app/layout.tsx`
2. Add GA4 tracking code to `<head>` section
3. Replace `G-YOUR_CALC_ID` with your Calc Measurement ID
4. Add event tracking to buttons
5. Commit and push

```bash
cd /mnt/e/projects/calc
git add app/layout.tsx
git commit -m "feat(analytics): Add Google Analytics 4 tracking"
git push origin main
```

---

## Site 3: AFFILIATE (thestackguide.com)

**File**: `/mnt/e/projects/affiliate/thestackguide/src/app/layout.tsx`

Note: This site uses `src/app/` instead of `app/`

1. Open `src/app/layout.tsx`
2. Add GA4 tracking code to `<head>` section
3. Replace `G-YOUR_AFFILIATE_ID` with your Affiliate Measurement ID
4. Add event tracking to buttons
5. Commit and push

```bash
cd /mnt/e/projects/affiliate/thestackguide
git add src/app/layout.tsx
git commit -m "feat(analytics): Add Google Analytics 4 tracking"
git push origin master
```

---

## Site 4: QUANT (quantengines.com)

**File**: `/mnt/e/projects/quant/quant/frontend/src/app/layout.tsx`

Note: This site has a deeper structure

1. Open `frontend/src/app/layout.tsx`
2. Add GA4 tracking code to `<head>` section
3. Replace `G-YOUR_QUANT_ID` with your Quant Measurement ID
4. Add event tracking to buttons (for backtest runs, etc.)
5. Commit and push

```bash
cd /mnt/e/projects/quant/quant/frontend
git add src/app/layout.tsx
git commit -m "feat(analytics): Add Google Analytics 4 tracking"
git push origin main
```

---

## Verification (5 minutes)

### Step 1: Check Real-time Reports

1. Go to: https://analytics.google.com
2. For each property, click on it
3. Go to **Reporting** → **Real-time**
4. You should see these events:
   - `session_start`
   - `page_view`

### Step 2: Visit Your Sites

1. Open each site in a browser:
   - https://cardclassroom.com
   - https://dividendengines.com
   - https://thestackguide.com
   - https://quantengines.com

2. In GA4 Real-time, you should see:
   - Your session appear within 5 seconds
   - Page title and URL
   - Location and device info

### Step 3: Test Event Tracking

1. Click an email signup button
   - Event `email_signup` should appear in Real-time

2. Click an affiliate link
   - Event `affiliate_click` should appear in Real-time

3. Scroll to 50%, 75%, 100% of an article
   - Events `scroll_to_50`, `scroll_to_75`, `scroll_to_100` should appear

### Step 4: Verify in Console

Open DevTools (F12) and run:

```javascript
// Check dataLayer
console.log(window.dataLayer)

// Should show: [['js', Date], ['config', 'G-XXXXX']]
// Indicates GA4 is loaded
```

---

## Troubleshooting

### "No data in Real-time"

1. **Verify tracking code is installed**:
   - Open DevTools → Console
   - Run: `console.log(window.dataLayer)`
   - Should show an array with GA4 config

2. **Check for JavaScript errors**:
   - DevTools → Console tab
   - Should see NO red errors
   - If errors, fix the code syntax

3. **Verify Measurement ID is correct**:
   - Should be format: `G-XXXXXXXXXX`
   - Check you're using the right ID for each site

4. **Wait and refresh**:
   - GA4 can take 5-10 seconds to populate
   - Try refreshing the page and GA4 report

### "Events not firing"

1. **Check button click handlers are added**:
   - Should have `onClick={() => window.trackEmailSignup(...)}`
   - Not all buttons need it, just the important ones

2. **Verify function exists**:
   - DevTools → Console
   - Run: `typeof window.trackEmailSignup`
   - Should return: `"function"`

3. **Test manually in console**:
   ```javascript
   gtag('event', 'test_event', {'test': 'value'})
   // Should appear in GA4 within 2 seconds
   ```

### "Wrong site appears"

- Verify you're using the correct Measurement ID for each site
- Each site should have its own G-XXXXXXX ID
- Double-check IDs match in tracking code

---

## Dashboard Setup (Optional, 5 min)

After tracking is live, create a dashboard:

### Option A: Google Sheets (Easiest)

1. Go to Google Sheets
2. Create new sheet
3. Click **Extensions** → **Get Add-ons**
4. Search: "Google Analytics Connector"
5. Install and authorize
6. Create report with these metrics:
   - Page title and URL
   - Pageviews
   - Users
   - Bounce rate
   - Email signups (custom event)
   - Affiliate clicks (custom event)

### Option B: Looker Studio (Better)

1. Go to: https://datastudio.google.com
2. Create → Report
3. Add data source: Google Analytics 4
4. Select each property
5. Create charts:
   - **Card**: Total pageviews
   - **Table**: Top pages
   - **Time chart**: Daily pageviews
   - **Pie**: Event breakdown

---

## What Gets Tracked Automatically

### Page Views
- Every page view to each site
- Device (desktop/mobile/tablet)
- Browser and OS
- Approximate location
- Duration on page

### Custom Events

| Event | When | Data Collected |
|-------|------|---|
| `email_signup` | Email form submitted | Form type, article |
| `affiliate_click` | Affiliate link clicked | Network, tool name, article |
| `scroll_to_50` | User scrolls 50% | Article slug |
| `scroll_to_75` | User scrolls 75% | Article slug |
| `scroll_to_100` | User scrolls 100% | Article slug |

---

## Next Steps

1. ✅ Add GA4 tracking code to all 4 sites
2. ✅ Verify in Real-time reports
3. ⏳ Monitor for 24 hours
4. ⏳ Create dashboard (optional)
5. ⏳ Start analyzing data weekly

---

## Expected Timeline

```
Hour 1:  Tracking active, first data in Real-time
Day 1:   Pageviews accumulating
Day 2:   Trends starting to show
Week 1:  Patterns visible
Month 1: Performance tiers calculated
```

---

## Files Reference

- **Tracking code**: `ga4_tracking_code.tsx` (copy to each site)
- **Config**: `ga4_config.json` (already in all 4 sites)
- **Dashboard setup**: Follow options A or B above

---

## Support

If tracking isn't working:
1. Check console for JavaScript errors
2. Verify Measurement ID is correct
3. Wait 5-10 seconds and refresh GA4
4. Check network tab for googletagmanager.com requests

**All 4 sites ready to track!** 🎯
