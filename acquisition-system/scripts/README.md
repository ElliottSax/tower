# DealSourceAI Automation Scripts

**Location:** `/scripts/`

All scripts are executable and ready to use. Run them from anywhere.

---

## 🚀 Quick Start

### Master Launch Script (Start Here!)
```bash
./scripts/launch.sh
```

Interactive menu with all options:
- Start dashboard
- Deploy landing page
- Extract targets
- Setup tools
- View summaries
- Generate emails

---

## 📜 Available Scripts

### 1. `launch.sh` - Master Launch Assistant
**What it does:** Interactive menu for all common tasks

**Usage:**
```bash
cd /mnt/e/projects/acquisition-system
./scripts/launch.sh
```

**Options:**
1. Start dashboard
2. Deploy landing page
3. Extract targets
4. Setup tools
5. View project summary
6. Generate outreach email
7. Full dev environment
8. Exit

---

### 2. `start-dashboard.sh` - Start Next.js Dashboard
**What it does:** Starts the client dashboard on http://localhost:3000

**Usage:**
```bash
./scripts/start-dashboard.sh
```

**Features:**
- Auto-installs dependencies if needed
- Kills existing processes on port 3000
- Shows all available URLs
- Displays startup logs

**URLs:**
- http://localhost:3000/client - Dashboard
- http://localhost:3000/client/leads - Leads
- http://localhost:3000/client/campaigns - Campaigns
- http://localhost:3000/client/responses - Responses
- http://localhost:3000/client/analytics - Analytics
- http://localhost:3000/client/settings - Settings

---

### 3. `deploy-landing-page.sh` - Deploy Landing Page
**What it does:** Deploys landing page to Vercel, Netlify, or manual

**Usage:**
```bash
./scripts/deploy-landing-page.sh
```

**Options:**
1. Vercel (recommended) - Auto-deploy with CLI
2. Netlify - Auto-deploy with CLI
3. Manual - Shows step-by-step instructions
4. Cancel

**Requirements:**
- Vercel: `npm install -g vercel`
- Netlify: `npm install -g netlify-cli`

---

### 4. `extract-targets.sh` - Extract Target Prospects
**What it does:** Exports prospects from TARGET_LIST.md to CSV

**Usage:**
```bash
./scripts/extract-targets.sh
```

**Options:**
1. Top 50 search funds (Tier 1 priority)
2. Top 50 PE firms (VP Corp Dev)
3. Top 50 independent sponsors
4. Custom keyword search
5. Cancel

**Output:**
- CSV files in `/go-to-market/target-customers/extracted/`
- Headers: Name, Contact, LinkedIn, Focus, etc.
- Ready for import to CRM or email enrichment

**Next Steps:**
1. Upload CSV to Hunter.io for email enrichment
2. Import enriched data to HubSpot CRM
3. Use outreach templates to send emails

---

### 5. `setup-tools.sh` - Setup Required Tools
**What it does:** Interactive setup for all required business tools

**Usage:**
```bash
./scripts/setup-tools.sh
```

**Tools Configured:**
1. Domain registration (dealsourceai.com)
2. Email setup (Google Workspace)
3. Calendar scheduling (Calendly)
4. CRM setup (HubSpot)
5. Email enrichment (Hunter.io/Apollo)

**Output:**
- Configuration saved to `.env.tools`
- Checklist of completed items
- Cost summary (~$180/month)

---

## 🎯 Common Workflows

### Workflow 1: First-Time Setup
```bash
# 1. Setup tools
./scripts/setup-tools.sh

# 2. Deploy landing page
./scripts/deploy-landing-page.sh

# 3. Extract targets
./scripts/extract-targets.sh

# 4. Start dashboard for demos
./scripts/start-dashboard.sh
```

### Workflow 2: Daily Operations
```bash
# Quick launch
./scripts/launch.sh
# Select: 1 (Start Dashboard)
```

### Workflow 3: Sales Campaign
```bash
# 1. Extract 50 search funds
./scripts/extract-targets.sh
# Select: 1

# 2. Enrich emails (manual step)
# Upload CSV to Hunter.io

# 3. Use outreach templates
cat go-to-market/target-customers/OUTREACH_TEMPLATES.md

# 4. Send emails via your email client
```

---

## 📂 Script Locations

```
scripts/
├── README.md                  ← This file
├── launch.sh                  ← Master launch menu
├── start-dashboard.sh         ← Start Next.js
├── deploy-landing-page.sh     ← Deploy website
├── extract-targets.sh         ← Export prospects
└── setup-tools.sh             ← Configure tools
```

---

## 🔧 Troubleshooting

### Dashboard won't start
```bash
# Kill existing processes
pkill -f "next dev"

# Re-run
./scripts/start-dashboard.sh
```

### Port 3000 already in use
```bash
# Find and kill process
lsof -ti:3000 | xargs kill -9

# Or use different port
PORT=3001 npm run dev
```

### Deployment fails
```bash
# Install CLI tools
npm install -g vercel     # For Vercel
npm install -g netlify-cli # For Netlify

# Re-run deployment
./scripts/deploy-landing-page.sh
```

---

## 💡 Tips

### Run from anywhere
```bash
# These work from any directory
/mnt/e/projects/acquisition-system/scripts/launch.sh
~/acquisition-system/scripts/start-dashboard.sh
```

### Add to PATH (optional)
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/mnt/e/projects/acquisition-system/scripts"

# Then run from anywhere
launch.sh
start-dashboard.sh
```

### Background mode
```bash
# Run dashboard in background
nohup ./scripts/start-dashboard.sh > /tmp/dashboard.log 2>&1 &

# View logs
tail -f /tmp/dashboard.log
```

---

## 🎓 Examples

### Example 1: Full Launch
```bash
$ ./scripts/launch.sh

What would you like to do?
1) Start Dashboard
...
Select option: 1

🚀 Starting DealSourceAI Dashboard...
✓ URL: http://localhost:3000/client
```

### Example 2: Extract Targets
```bash
$ ./scripts/extract-targets.sh

Extract targets for:
1) Top 50 Search Funds
Select option: 1

✅ Extracted 50 search funds to:
   extracted/top-50-search-funds.csv
```

### Example 3: Deploy Landing Page
```bash
$ ./scripts/deploy-landing-page.sh

Choose deployment method:
1) Vercel
Select option: 1

🔷 Deploying to Vercel...
✅ Deployed! https://dealsourceai.com
```

---

## 📊 Script Comparison

| Script | Purpose | Interactive | Output |
|--------|---------|-------------|--------|
| `launch.sh` | Master menu | ✅ Yes | Various |
| `start-dashboard.sh` | Start Next.js | ❌ No | URL |
| `deploy-landing-page.sh` | Deploy site | ✅ Yes | URL |
| `extract-targets.sh` | Export CSV | ✅ Yes | CSV file |
| `setup-tools.sh` | Configure tools | ✅ Yes | .env file |

---

## ✅ Next Steps

**After running scripts:**

1. **Dashboard running?** Take screenshots for sales deck
2. **Landing page deployed?** Share URL with prospects
3. **Targets extracted?** Import to CRM and enrich emails
4. **Tools setup?** Start sending outreach emails

**Ready to launch?** Start with `./scripts/launch.sh`

---

**All scripts are production-ready and safe to run.** 🚀
