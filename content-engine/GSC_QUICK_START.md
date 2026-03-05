# OAuth2 Auto-Submission - Quick Start (15 min)

## 5 Steps to Automate Sitemap Submissions

### Step 1: Google Cloud Setup (5 min)

```bash
# Visit these in order:
1. https://console.cloud.google.com/iam-admin/serviceaccounts
2. Create Service Account → "seo-auto-submit"
3. Create JSON Key → Download & Save
4. Copy client_email from JSON
```

### Step 2: Grant GSC Access (3 min)

```bash
# For each site (cardclassroom.com, dividendengines.com, thestackguide.com, quantengines.com):
1. https://search.google.com/search-console/settings/users
2. Add User → Paste service account email
3. Role: Owner → Save
```

### Step 3: Store in GitHub (2 min)

```bash
# 1. Copy entire contents of downloaded JSON
# 2. Go to: Settings → Secrets and variables → Actions
# 3. New secret → Name: GCP_SERVICE_ACCOUNT → Paste JSON
# 4. Save
```

### Step 4: Add Workflow & Script (3 min)

**Copy these files to each repository:**

**File 1: `.github/workflows/gsc-daily-submit.yml`**
```yaml
name: Google Search Console Daily Sitemap Submit

on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  submit-sitemaps:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install google-auth google-auth-httplib2 google-auth-oauthlib requests
      - env:
          GCP_SERVICE_ACCOUNT: ${{ secrets.GCP_SERVICE_ACCOUNT }}
        run: python gsc_auto_submit.py
```

**File 2: `gsc_auto_submit.py`**
```bash
# Copy from content-engine:
cp /mnt/e/projects/content-engine/gsc_auto_submit.py ./
```

**Push changes:**
```bash
git add .github/workflows/gsc-daily-submit.yml gsc_auto_submit.py
git commit -m "feat(seo): Add daily GSC auto-submission"
git push
```

### Step 5: Test (2 min)

```bash
# Go to GitHub repository:
1. Actions tab
2. Google Search Console Daily Sitemap Submit
3. Run workflow → Run workflow
4. Wait 30s → Check logs for ✅
```

---

## Deploy to All 4 Sites

Run these commands in each repository:

```bash
# CREDIT (cardclassroom.com)
cd /mnt/e/projects/credit
cp /mnt/e/projects/content-engine/gsc_auto_submit.py .
# Create .github/workflows/gsc-daily-submit.yml with template above
git add .github/workflows/gsc-daily-submit.yml gsc_auto_submit.py
git commit -m "feat(seo): Add daily GSC auto-submission"
git push

# CALC (dividendengines.com)
cd /mnt/e/projects/calc
cp /mnt/e/projects/content-engine/gsc_auto_submit.py .
# Create .github/workflows/gsc-daily-submit.yml with template above
git add .github/workflows/gsc-daily-submit.yml gsc_auto_submit.py
git commit -m "feat(seo): Add daily GSC auto-submission"
git push

# AFFILIATE (thestackguide.com)
cd /mnt/e/projects/affiliate/thestackguide
cp /mnt/e/projects/content-engine/gsc_auto_submit.py .
# Create .github/workflows/gsc-daily-submit.yml with template above
git add .github/workflows/gsc-daily-submit.yml gsc_auto_submit.py
git commit -m "feat(seo): Add daily GSC auto-submission"
git push

# QUANT (quantengines.com)
cd /mnt/e/projects/quant/quant
cp /mnt/e/projects/content-engine/gsc_auto_submit.py .
# Create .github/workflows/gsc-daily-submit.yml with template above
git add .github/workflows/gsc-daily-submit.yml gsc_auto_submit.py
git commit -m "feat(seo): Add daily GSC auto-submission"
git push
```

---

## What Happens Next

✅ Every day at 2 AM UTC:
- GitHub Actions runs automatically
- Python script authenticates with Google Cloud
- Submits sitemap for all 4 sites
- Tracks indexed URLs and errors
- Reports success/failure

✅ In Google Search Console:
- You'll see "Last submitted: Today" on each sitemap
- Indexed URL counts update automatically
- No more manual submissions needed

---

## Troubleshoot

| Error | Fix |
|-------|-----|
| "No access token available" | Check GitHub Secrets has GCP_SERVICE_ACCOUNT |
| "Unauthorized (403)" | Add service account as Owner in GSC for all 4 sites |
| "404 - Not Found" | Verify /sitemap.xml exists: `curl yourdomain.com/sitemap.xml` |
| "Request failed" | Check internet connection, verify JSON is valid |

---

## Full Documentation

See `GSC_OAUTH2_SETUP.md` for detailed walkthrough with screenshots.

---

## Timeline

- **Minutes 1-5**: Create Google Cloud service account
- **Minutes 6-8**: Grant GSC access (4 sites)
- **Minutes 9-11**: Store credentials in GitHub
- **Minutes 12-14**: Deploy workflow to 4 repositories
- **Minute 15**: Run test workflow

✅ **Done!** Sitemaps now auto-submit daily.
