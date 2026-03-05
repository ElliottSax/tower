# Google Search Console OAuth2 Auto-Submission Setup

This guide sets up automatic daily sitemap submissions to Google Search Console via OAuth2, eliminating manual work.

**Timeline**: 15-20 minutes
**Cost**: Free (uses Google Cloud free tier)
**Result**: Sitemaps auto-submit daily, indexed content tracked automatically

---

## What This Does

Instead of manually submitting sitemaps through GSC UI each time they update, this system:

- ✅ Automatically runs daily via GitHub Actions
- ✅ Uses OAuth2 to authenticate with Google (service account)
- ✅ Submits updated sitemaps to all 4 sites
- ✅ Provides detailed success/failure reporting
- ✅ Tracks indexed URLs, pending URLs, and crawl errors

---

## Step 1: Create Google Cloud Service Account (5 min)

### 1a. Create Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click project dropdown → **New Project**
3. Name: `SEO-Automation` (or your preference)
4. Click **Create**
5. Wait for project to initialize (2-3 minutes)

### 1b. Enable APIs

1. Go to [APIs Library](https://console.cloud.google.com/apis/library)
2. Search: **Search Console API**
3. Click **Google Search Console API**
4. Click **Enable**

Wait for confirmation (1-2 minutes).

### 1c. Create Service Account

1. Go to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. Click **Create Service Account**
3. Fill in details:
   - **Service Account Name**: `seo-auto-submit`
   - **Service Account ID**: `seo-auto-submit` (auto-filled)
   - Click **Create and Continue**
4. **Grant Roles** (Step 2):
   - Click **Select a Role**
   - Search: **Editor** (gives full access)
   - Click **Editor**
   - Click **Continue**
5. **Create Key** (Step 3):
   - Click **Create Key**
   - Select **JSON** format
   - Click **Create**
   - A JSON file will download: `[PROJECT_ID]-[RANDOM].json`
   - **SAVE THIS FILE** - you'll need it

### 1d. Grant GSC Access to Service Account

1. Copy the service account email from the JSON file:
   - Open the downloaded JSON
   - Find field: `client_email` (looks like `seo-auto-submit@[project].iam.gserviceaccount.com`)
   - Copy the email address

2. Go to [Google Search Console Settings](https://search.google.com/search-console/users)
3. For each of your 4 sites:
   - Click the site
   - Go to **Settings** (⚙️ icon) → **Users and Permissions**
   - Click **Add User**
   - Paste the service account email
   - Select role: **Owner** (allows full access including sitemap submission)
   - Click **Add**
   - Confirm when prompted

**Repeat for all 4 sites:**
- cardclassroom.com
- dividendengines.com
- thestackguide.com
- quantengines.com

---

## Step 2: Store Credentials in GitHub (5 min)

### 2a. Encode Credentials

1. Open the downloaded JSON file in text editor
2. Copy entire contents
3. Go to this repository on GitHub
4. Go to **Settings** → **Secrets and variables** → **Actions**
5. Click **New repository secret**
6. **Name**: `GCP_SERVICE_ACCOUNT`
7. **Value**: Paste entire JSON contents
8. Click **Add secret**

---

## Step 3: Create GitHub Actions Workflow (5 min)

Create workflow file for each site:

**File**: `.github/workflows/gsc-daily-submit.yml`

```yaml
name: Google Search Console Daily Sitemap Submit

on:
  schedule:
    # Run daily at 2 AM UTC (every 24 hours)
    - cron: '0 2 * * *'
  workflow_dispatch:  # Allow manual trigger

jobs:
  submit-sitemaps:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install google-auth google-auth-httplib2 google-auth-oauthlib requests

      - name: Submit sitemaps to Google Search Console
        env:
          GCP_SERVICE_ACCOUNT: ${{ secrets.GCP_SERVICE_ACCOUNT }}
        run: |
          python gsc_auto_submit.py

      - name: Notify on failure
        if: failure()
        run: |
          echo "⚠️ GSC sitemap submission failed. Check GitHub Actions logs."
```

**Instructions:**

1. In your 4 site repositories:
   - `credit/` (cardclassroom.com)
   - `calc/` (dividendengines.com)
   - `affiliate/` (thestackguide.com)
   - `quant/` (quantengines.com)

2. Create: `.github/workflows/gsc-daily-submit.yml`

3. Paste the workflow YAML above

4. Also copy `gsc_auto_submit.py` to the root of each repository:
   - `cp /mnt/e/projects/content-engine/gsc_auto_submit.py credit/`
   - `cp /mnt/e/projects/content-engine/gsc_auto_submit.py calc/`
   - Etc. for affiliate and quant

5. Commit and push:
   ```bash
   git add .github/workflows/gsc-daily-submit.yml gsc_auto_submit.py
   git commit -m "feat(seo): Add daily GSC sitemap auto-submission via OAuth2"
   git push origin master
   ```

---

## Step 4: Test the Setup (2 min)

1. Go to repository on GitHub
2. Go to **Actions** tab
3. Find workflow: **Google Search Console Daily Sitemap Submit**
4. Click **Run workflow** → **Run workflow** (green button)
5. Wait 30 seconds for job to complete
6. Click job to see logs
7. Look for: `✅ All sitemaps submitted successfully!`

If you see errors, check:
- Service account JSON is correctly pasted in GitHub Secrets
- Service account has Owner access in GSC for all 4 sites
- All 4 domains are verified in GSC

---

## Step 5: Verify in Google Search Console (2 min)

For each of your 4 sites:

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Go to **Sitemaps** (left sidebar)
3. Look for entries showing:
   - ✅ Submitted at: [today's date]
   - Status: "Success" or "Submitted"
   - Indexed URLs: [number]
   - Pending URLs: [number]

---

## Monitoring & Troubleshooting

### Check Auto-Submission Status

**GitHub Actions Logs**:
1. Repository → **Actions** tab
2. Click latest workflow run
3. Click `submit-sitemaps` job
4. See full logs with:
   - ✅ Timestamp of submission
   - ✅ URLs submitted
   - ✅ Indexed/pending/error counts

**GSC Dashboard**:
1. For each site, go to **Sitemaps**
2. Click sitemap URL
3. See detailed stats:
   - Last submitted: [timestamp]
   - Indexed: [count]
   - Pending: [count]
   - Errors: [list]

### Common Issues

**Issue**: "No access token available"
- **Cause**: Service account credentials not set in GitHub Secrets
- **Fix**: Go to Settings → Secrets → Verify `GCP_SERVICE_ACCOUNT` is set

**Issue**: "Unauthorized" (403 error)
- **Cause**: Service account not added as Owner in GSC
- **Fix**: Go to each site → Settings → Users & Permissions → Add service account email with Owner role

**Issue**: "404 - Not Found"
- **Cause**: Sitemap URL doesn't exist at that domain
- **Fix**: Verify `/sitemap.xml` is accessible:
  - `curl https://yourdomain.com/sitemap.xml`

---

## Daily Schedule

The workflow runs automatically at **2 AM UTC** every day.

To change schedule, edit `.github/workflows/gsc-daily-submit.yml`:

```yaml
on:
  schedule:
    # Examples:
    - cron: '0 2 * * *'   # 2 AM UTC every day
    - cron: '0 6 * * 0'   # 6 AM UTC every Sunday
    - cron: '0 */12 * * *' # Every 12 hours
```

Reference: [Cron schedule syntax](https://crontab.guru/)

---

## Manual Submission (Backup)

If you ever need to manually trigger submission:

1. Go to GitHub repository
2. Click **Actions** tab
3. Click **Google Search Console Daily Sitemap Submit**
4. Click **Run workflow** (green button)
5. Select branch: **master**
6. Click **Run workflow**

Check logs in 30 seconds for results.

---

## Cleanup (Optional)

If you already submitted sitemaps manually in GSC, the script will:
- ✅ Detect they're already submitted
- ✅ Update their status (indexed/pending counts)
- ✅ Report success

No duplicates are created.

---

## Next Steps

Once this is running:

1. ✅ Sitemaps auto-submit daily
2. ✅ Google crawls new articles automatically
3. ⏳ Monitor GSC Coverage report for indexing progress
4. ⏳ Watch Google Analytics for traffic from new articles
5. ⏳ Check Search Console Performance to see which articles rank

Expected timeline:
- **24-48 hours**: Initial crawl begins
- **7 days**: 50-70% indexed
- **30 days**: 85-95% fully indexed
- **90 days**: Rankings stabilize, traffic increases

---

## Cost

**Free**: Google Cloud Search Console API has generous free tier
- Up to 20,000 free quota units per project per day
- Each sitemap submission = ~1-2 quota units
- 4 sites per day = ~8 quota units
- No additional charges

---

## Questions?

Refer to official docs:
- [Google Search Console API](https://developers.google.com/webmaster-tools)
- [Service Account Setup](https://cloud.google.com/docs/authentication/getting-started)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
