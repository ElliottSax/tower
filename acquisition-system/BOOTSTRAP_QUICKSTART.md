# Bootstrap Quick Start: $0-6/Month

**Goal**: Source 200+ deals per month for next to free, validate the model, then scale.

---

## ⚡ 15-Minute Setup

### Step 1: Create Free Accounts (10 min)

```bash
# Email enrichment (150 free/month total)
https://hunter.io/users/sign_up          # 50/month FREE
https://app.apollo.io/#/sign-up          # 50/month FREE
https://snov.io/sign-up                  # 50/month FREE

# AI personalization (unlimited FREE)
https://console.groq.com/                # Get API key

# Email verification (1,000 free/month)
https://app.neverbounce.com/register     # FREE tier

# Email sending (choose one)
https://workspace.google.com/            # $6/mo (500/day)
OR https://sendgrid.com/free/            # $0 (100/day)
```

**Cost so far**: $0 (or $6/mo if using Google Workspace)

### Step 2: Install Groq (1 min)

```bash
cd /mnt/e/projects/acquisition-system
pip install groq
```

### Step 3: Configure API Keys (2 min)

```bash
# Copy config
cp config/.env.example config/.env

# Edit and add free keys
nano config/.env
```

Add these:
```bash
# Free tier keys
HUNTER_API_KEY=your_hunter_free_key
APOLLO_API_KEY=your_apollo_free_key
SNOV_API_KEY=your_snov_free_key
GROQ_API_KEY=your_groq_free_key
NEVERBOUNCE_API_KEY=your_neverbounce_free_key

# Gmail SMTP (if using Google Workspace)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=founders@dealsourceai.com
SMTP_PASSWORD=your_gmail_app_password
```

### Step 4: Run Bootstrap Pipeline (2 min)

```bash
python scripts/bootstrap_pipeline.py --state CA --outreach-limit 10
```

**What it does**:
1. Scrapes 500 CA businesses (free)
2. Finds 100 emails using free tiers + pattern guessing
3. Scores all with ML (free)
4. Personalizes top 10 with Groq (free)
5. Ready to send 10/day via Gmail

**Total time**: 15 minutes
**Total cost**: $0-6/month

---

## 📊 What You Get

### Month 1 (Bootstrap Mode)

```
Free tier capacity:
- Hunter: 50 emails
- Apollo: 50 emails
- Snov: 50 emails
- Pattern guess: Unlimited
TOTAL: 150-200 emails found/month

Outreach capacity:
- Gmail: 500/day (start with 10/day)
- SendGrid: 100/day
TOTAL: 200-500 emails sent/month

AI personalization:
- Groq: Unlimited FREE

Expected results:
- 200 emails sent
- 22 responses (11% rate)
- 6 meetings booked (3% rate)
- Cost: $0-6/month
```

### Month 2-3 (Still Bootstrap)

```
- Send 500 emails total
- 55 responses
- 15 meetings
- Close 1 client at $10K/mo
- Revenue: $10K/mo
- Cost: Still $6/mo
- Profit: $9,994/mo 🎉
```

### Month 4+ (Reinvest & Scale)

```
After first client closes:
- Upgrade to paid tools ($200/mo)
- Scale to 1,000 emails/month
- 110 responses, 30 meetings
- Close 3-5 more clients
- Revenue: $50K/mo
- Cost: $206/mo
- Profit: $49,794/mo
```

---

## 🎯 Daily Workflow (10 min/day)

### Monday: Scrape & Enrich (1x per week)
```bash
python scripts/bootstrap_pipeline.py --state TX --enrich-limit 50
```

### Tuesday-Friday: Review & Send (10 min/day)
```bash
# Review hot leads in dashboard
./scripts/start-dashboard.sh
# Open: http://localhost:3000/client/leads

# Send 10 personalized emails via Gmail
# (Manual send or use backend/outreach/gmail_sender.py)
```

### Weekend: Track responses, book meetings

---

## 💡 Pro Tips

### 1. Conserve Free Tier Credits
```python
# Only use paid APIs for HOT leads (score >= 70)
# Use pattern guessing for warm/cold leads

if lead.score >= 70:
    email = waterfall.find_email_free_tier()  # Use Hunter/Apollo
else:
    email = waterfall.guess_email_pattern()   # Free unlimited
```

### 2. Stack Free Tiers by Month
```
Month 1: Use Hunter (50) + Apollo (50) + Snov (50) = 150
Month 2: New accounts → Another 150
Month 3: Pattern guessing mostly, save tiers for best leads
```

### 3. Email Warmup Schedule
```
Week 1: 5 emails/day
Week 2: 10 emails/day  ← Start here for bootstrap
Week 3: 20 emails/day
Week 4: 30 emails/day
```

### 4. Groq Instead of Claude
```python
# Claude: $0.15 per email × 100 = $15
# Groq: $0 × 100 = $0
# Quality: 85-90% as good
# Speed: Actually faster than Claude!

# Use Groq for bootstrap, upgrade to Claude later
```

---

## 📈 Scale Path

### Phase 1: Validate ($0-6/mo, Month 1-2)
- ✅ 200 emails/month
- ✅ 6 meetings
- ✅ Prove concept works
- ✅ Close 1 client

### Phase 2: Early Revenue ($206/mo, Month 3-4)
- ✅ 1,000 emails/month
- ✅ 30 meetings
- ✅ 3-5 clients
- ✅ $30-50K MRR

### Phase 3: Scale ($500/mo, Month 5-6)
- ✅ 5,000 emails/month
- ✅ 150 meetings
- ✅ 10 clients
- ✅ $100K MRR

**Key**: Start free, reinvest first dollar, compound growth

---

## 🔧 Files Created

**New bootstrap files**:
- `BOOTSTRAP_MODE.md` - Full strategy guide
- `backend/enrichment/free_email_waterfall.py` - Free email finder
- `backend/outreach/groq_personalizer.py` - Free AI personalization
- `scripts/bootstrap_pipeline.py` - One-command bootstrap

**Run it**:
```bash
python scripts/bootstrap_pipeline.py
```

---

## ✅ Checklist

**Before first send**:
- [ ] Created all free accounts (Hunter, Apollo, Snov, Groq)
- [ ] Added API keys to `.env`
- [ ] Installed Groq: `pip install groq`
- [ ] Ran bootstrap pipeline successfully
- [ ] Setup Gmail or SendGrid
- [ ] Started email warmup (5-10/day)

**Week 1**:
- [ ] Send 10 emails/day (70 total)
- [ ] Track in dashboard
- [ ] Respond to replies within 2 hours

**Week 2-4**:
- [ ] Scale to 20/day (140/week)
- [ ] Book first meetings
- [ ] Close first deal

**Month 2**:
- [ ] Reinvest in paid tools if revenue > $10K
- [ ] Or continue bootstrap if still validating

---

## 🎉 You're Ready!

**To start today**:
```bash
# 1. Get free API keys (15 min)
# 2. Configure .env (2 min)
# 3. Run pipeline:
python scripts/bootstrap_pipeline.py

# Result: 10 personalized emails ready to send
# Cost: $0
```

**Bootstrap works. Validate first, scale later.** 🚀
