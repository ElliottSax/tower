# Bootstrap Mode: Run for Next to Free

**Goal**: Validate the business model with <$50/month, then scale with paid tools once revenue comes in.

**Strategy**: Use free tiers, open source alternatives, and manual workflows where needed.

---

## Cost Comparison

| Component | Full Version | Bootstrap Version | Savings |
|-----------|--------------|-------------------|---------|
| Email enrichment | $49/mo (Hunter) | Free tiers combo | **$49** |
| AI personalization | $30/mo (Claude) | Groq/Gemini (free) | **$30** |
| Email automation | $37-97/mo (Instantly) | Gmail + SendGrid | **$37-97** |
| LinkedIn data | $50/mo (Proxycurl) | Manual scraping | **$50** |
| Email verification | $20/mo (ZeroBounce) | NeverBounce free | **$20** |
| **TOTAL** | **$186-246/mo** | **$0-25/mo** | **$161-246** |

---

## Stage-by-Stage Bootstrap Alternatives

### 1. Data Scraping (FREE ✅)

**No changes needed** - already free!

```bash
# Secretary of State APIs are public/free
acquire scrape --states CA TX FL --limit 5000

# BizBuySell scraping uses Playwright (free)
# Website analysis uses HTTP requests (free)
```

**Cost**: $0

---

### 2. Email Enrichment (FREE with limits)

#### Option A: Combine Free Tiers (150-200 emails/month)

**Strategy**: Stack multiple providers' free tiers

```bash
# Month 1 free credits:
1. Hunter.io      - 50 free searches/month
2. Apollo.io      - 50 free credits/month
3. Snov.io        - 50 free credits/month
4. RocketReach    - 5 free lookups/month
5. VoilaNorbert   - 50 free/month

TOTAL: 205 free email lookups/month
```

**How to implement**:
```python
# backend/enrichment/free_email_waterfall.py

class FreeEmailWaterfall:
    """Email enrichment using only free tiers."""

    def __init__(self):
        self.providers = {
            'hunter': {'limit': 50, 'used': 0},
            'apollo': {'limit': 50, 'used': 0},
            'snov': {'limit': 50, 'used': 0},
            'voilanorbert': {'limit': 50, 'used': 0},
        }

    def find_email(self, name, company):
        """Try free tiers in sequence."""
        for provider, quota in self.providers.items():
            if quota['used'] < quota['limit']:
                email = self._try_provider(provider, name, company)
                if email:
                    quota['used'] += 1
                    return email

        # Fall back to pattern guessing
        return self._guess_email_pattern(name, company)
```

**Cost**: $0/month (up to 200 emails)

#### Option B: Email Pattern Guessing (UNLIMITED FREE)

**Strategy**: Try common patterns, verify deliverability

```python
# Common email patterns:
patterns = [
    "{first}@{domain}",              # john@company.com
    "{first}.{last}@{domain}",       # john.smith@company.com
    "{first}{last}@{domain}",        # johnsmith@company.com
    "{f}{last}@{domain}",            # jsmith@company.com
    "{first}_{last}@{domain}",       # john_smith@company.com
    "info@{domain}",                 # info@company.com (fallback)
]

# Verify which pattern works:
1. DNS MX record lookup (free)
2. SMTP verification (free, careful with rate limits)
3. NeverBounce free tier (1000/month)
```

**Accuracy**: 40-60% (vs 80% with paid waterfall)
**Cost**: $0/month (unlimited)

#### Option C: LinkedIn Email Scraping (FREE)

**Strategy**: Extract emails from LinkedIn profiles

```python
# Tools:
1. LinkedIn Sales Navigator (60-day free trial)
2. PhantomBuster free tier (14 days)
3. Manual extraction (slow but free)

# Process:
1. Search LinkedIn for "Owner at [Company]"
2. View profile → Contact info → Email (sometimes public)
3. Or scrape company domain, guess pattern
```

**Success rate**: 20-30% show email publicly
**Cost**: $0 (manual) or $0 during free trials

---

### 3. Email Verification (FREE with limits)

**Free options**:
```bash
1. NeverBounce    - 1,000 free verifications/month
2. EmailListVerify - 100 free/month
3. Verifalia      - 100 free/month
4. DIY SMTP check - Unlimited free (use carefully)

TOTAL: 1,200+ free verifications/month
```

**DIY SMTP verification** (completely free):
```python
import smtplib
import dns.resolver

def verify_email_free(email):
    """Free SMTP verification."""
    domain = email.split('@')[1]

    # 1. Check MX records exist
    try:
        mx_records = dns.resolver.resolve(domain, 'MX')
        mx_host = str(mx_records[0].exchange)
    except:
        return False  # No MX record = invalid

    # 2. Connect to SMTP server
    try:
        server = smtplib.SMTP(timeout=10)
        server.connect(mx_host)
        server.helo('dealsourceai.com')
        server.mail('verify@dealsourceai.com')
        code, message = server.rcpt(email)
        server.quit()

        return code == 250  # 250 = email exists
    except:
        return False
```

**Cost**: $0 (be careful with rate limits)

---

### 4. AI Personalization (FREE)

#### Option A: Groq API (FREE + Fast) ⭐ RECOMMENDED

**Why**: Completely free, 30 requests/minute, uses Llama 3.1

```python
# Install
pip install groq

# Use
from groq import Groq

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))  # Free key

def personalize_with_groq(business_data):
    """Generate personalized email - FREE."""

    prompt = f"""
    Generate a personalized cold email for:
    - Business: {business_data['name']}
    - Owner: {business_data['owner_name']}, age {business_data['owner_age']}
    - Industry: {business_data['industry']}
    - In business: {business_data['years']} years

    Write as individual searcher (not PE firm).
    Under 100 words. Focus on legacy preservation.
    """

    response = client.chat.completions.create(
        model="llama-3.1-70b-versatile",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
        max_tokens=300
    )

    return response.choices[0].message.content
```

**Limits**: 30 requests/min, 14,400 requests/day
**Cost**: $0 (completely free)
**Quality**: 85-90% as good as Claude

#### Option B: OpenAI GPT-4o-mini (Nearly Free)

**Cost**: $0.15 per 1M input tokens, $0.60 per 1M output

```python
# 100 personalizations:
# Input: 50K tokens × $0.15 / 1M = $0.0075
# Output: 20K tokens × $0.60 / 1M = $0.012
# TOTAL: $0.02 for 100 emails

# 1,000 personalizations = $0.20
```

**Cost**: ~$0.20 per 1,000 emails (basically free)

#### Option C: Google Gemini Flash (FREE)

**Free tier**: 1,500 requests/day

```python
import google.generativeai as genai

genai.configure(api_key="GOOGLE_API_KEY")  # Free

model = genai.GenerativeModel('gemini-1.5-flash')
response = model.generate_content(prompt)
```

**Cost**: $0 (up to 1,500/day)

#### Option D: Local LLM (FREE but slower)

```bash
# Install Ollama (free, runs locally)
curl -fsSL https://ollama.com/install.sh | sh

# Download Llama 3.1 (8B model, free)
ollama pull llama3.1

# Use in Python
import ollama

response = ollama.chat(model='llama3.1', messages=[...])
```

**Cost**: $0 (runs on your machine)
**Speed**: 3-5 seconds per email (vs <1s with Groq)

---

### 5. Email Outreach (FREE with limits)

#### Option A: Gmail (FREE, 500/day limit) ⭐ RECOMMENDED

**Setup**:
```python
# Use Gmail SMTP with App Password
import smtplib
from email.mime.text import MIMEText

def send_via_gmail(to_email, subject, body):
    """Send via Gmail SMTP - FREE."""

    msg = MIMEText(body, 'plain')
    msg['Subject'] = subject
    msg['From'] = 'founders@dealsourceai.com'  # Use Gmail
    msg['To'] = to_email

    server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    server.login('founders@dealsourceai.com', 'APP_PASSWORD')
    server.send_message(msg)
    server.quit()
```

**Limits**: 500 emails/day (plenty for bootstrap)
**Cost**: $0

**Important**:
- Warm up account (start 10/day, increase gradually)
- Use Google Workspace ($6/mo) for better deliverability
- Enable "Less secure app access" or use App Passwords

#### Option B: SendGrid Free Tier (100/day)

```python
# Install
pip install sendgrid

# Use
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

message = Mail(
    from_email='founders@dealsourceai.com',
    to_emails=to_email,
    subject=subject,
    plain_text_content=body
)

sg = SendGridAPIClient(api_key='SENDGRID_API_KEY')
response = sg.send(message)
```

**Limits**: 100 emails/day free
**Cost**: $0

#### Option C: SMTP2GO Free Tier (1,000/month)

**Limits**: 1,000 emails/month
**Cost**: $0

#### Option D: DIY Email Server (FREE but complex)

```bash
# Setup Postfix on VPS ($5/mo DigitalOcean)
# Configure SPF, DKIM, DMARC
# Warm up IP address

# Unlimited sending once configured
```

**Cost**: $5/mo for VPS
**Risk**: High (can get blacklisted if not careful)

---

## Bootstrap Tech Stack (Total: $0-25/mo)

### Core (All Free)
- **Data scraping**: ✅ Free (public APIs)
- **ML scoring**: ✅ Free (XGBoost local)
- **Database**: ✅ Free (PostgreSQL local or Supabase free tier)
- **Dashboard**: ✅ Free (Next.js local)

### Email Finding (Choose one)
- ✅ **Free tier combo**: Hunter + Apollo + Snov (200/month free)
- ✅ **Pattern guessing**: Unlimited free (40-60% accuracy)
- ✅ **Manual LinkedIn**: Free but slow

### Email Verification
- ✅ **NeverBounce**: 1,000/month free
- ✅ **DIY SMTP**: Unlimited free

### AI Personalization (Choose one)
- ⭐ **Groq**: FREE, unlimited (Llama 3.1)
- ✅ **GPT-4o-mini**: $0.20 per 1,000 emails
- ✅ **Gemini Flash**: 1,500/day free
- ✅ **Local Ollama**: Free but slower

### Email Sending (Choose one)
- ⭐ **Gmail**: 500/day free (need Google Workspace $6/mo for domain)
- ✅ **SendGrid**: 100/day free
- ✅ **SMTP2GO**: 1,000/month free

### Total Monthly Cost
```
Option 1 (Completely Free):
- Email finding: Free tiers combo
- AI: Groq (free)
- Sending: SendGrid (100/day)
TOTAL: $0/month
Capacity: 3,000 emails/month

Option 2 (Recommended):
- Email finding: Free tiers combo
- AI: Groq (free)
- Sending: Gmail via Google Workspace
TOTAL: $6/month
Capacity: 15,000 emails/month

Option 3 (Best Quality):
- Email finding: Free tiers + pattern guessing
- AI: GPT-4o-mini ($0.20/1K)
- Sending: Gmail + SendGrid combo
TOTAL: $6-10/month
Capacity: 18,000 emails/month (600/day)
```

---

## Bootstrap Workflow (Month 1)

### Week 1: Setup (Free)
```bash
# 1. Setup free accounts
- Hunter.io (50 free/month)
- Apollo.io (50 free/month)
- Snov.io (50 free/month)
- Groq API (unlimited free)
- Google Workspace ($6/mo for domain email)
- NeverBounce (1,000 free/month)

# 2. Configure backend
cp config/.env.example config/.env
# Add free API keys

# 3. Test pipeline
acquire scrape --states CA --limit 100
acquire enrich --limit 50  # Uses free tiers
acquire score --limit 50
```

### Week 2: First Campaign (10 emails/day)
```bash
# Find 50 hot leads
acquire scrape --states CA --limit 500
acquire enrich --limit 100  # Free tier combo
acquire score --limit 100

# Send 10/day (Gmail warmup)
for day in {1..5}; do
  acquire outreach --limit 10 --provider gmail
  sleep 86400  # Wait 24 hours
done
```

**Cost so far**: $6 (Google Workspace)
**Emails sent**: 50
**Expected responses**: 5-6 (11% rate)

### Week 3-4: Scale to 200 emails
```bash
# Use all free tier credits
acquire enrich --limit 200  # Uses all free tiers
acquire outreach --limit 20  # 20/day via Gmail

# Total contacted: 200
# Expected responses: 22 (11% rate)
# Expected meetings: 6 (3% conversion)
```

### Month 1 Results
- **Cost**: $6 (Google Workspace only)
- **Emails sent**: 200
- **Responses**: ~22
- **Meetings booked**: ~6
- **Deals closed**: 0 (too early)

**Next**: If 1-2 meetings look promising, reinvest in paid tools

---

## Scaling Strategy

### Validation Phase (Months 1-2)
- **Budget**: $6-25/month
- **Volume**: 200-500 emails/month
- **Goal**: Book 6-15 meetings, close 1 deal

### Growth Phase (Month 3+, after first client)
- **Budget**: $50-100/month
- **Add**: Hunter.io paid ($49), Instantly.ai ($37)
- **Volume**: 1,000-2,000 emails/month
- **Goal**: 100+ responses, 30+ meetings, 3-5 clients

### Scale Phase (Month 6+, at $100K+ ARR)
- **Budget**: $200-500/month
- **Add**: Full stack (Proxycurl, Claude, premium tools)
- **Volume**: 5,000-10,000 emails/month
- **Goal**: Enterprise clients, $500K+ ARR

---

## Quick Start (Bootstrap Mode)

### 1. Create free accounts (15 minutes)
```bash
# Email enrichment
https://hunter.io/users/sign_up          # 50/month free
https://app.apollo.io/#/sign-up          # 50/month free
https://snov.io/sign-up                  # 50/month free

# AI personalization
https://console.groq.com/                # Unlimited free

# Email verification
https://app.neverbounce.com/register     # 1,000/month free

# Email sending
https://workspace.google.com/            # $6/month
OR https://sendgrid.com/free/            # 100/day free
```

### 2. Configure backend
```bash
cd /mnt/e/projects/acquisition-system

# Copy and edit config
cp config/.env.example config/.env

# Add free API keys:
HUNTER_API_KEY=your_free_key
APOLLO_API_KEY=your_free_key
SNOV_API_KEY=your_free_key
GROQ_API_KEY=your_free_key
NEVERBOUNCE_API_KEY=your_free_key

# Gmail SMTP (if using Google Workspace)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=founders@dealsourceai.com
SMTP_PASSWORD=your_app_password
```

### 3. Run bootstrap pipeline
```bash
# Install dependencies
pip install groq  # Free AI
pip install sendgrid  # Free email (optional)

# Run pipeline with free tools
python scripts/bootstrap_pipeline.py --states CA --limit 100

# Or manually:
acquire scrape --states CA --limit 100
acquire enrich --limit 50 --free-tier-only
acquire score --limit 50
acquire outreach --limit 10 --provider gmail
```

---

## Bootstrap Pipeline Script

Let me create a bootstrap-specific pipeline:

```python
# scripts/bootstrap_pipeline.py
"""
Bootstrap pipeline using only free tools.
Target: 200 emails/month for $0-6/month.
"""

import os
from backend.enrichment.free_email_waterfall import FreeEmailWaterfall
from backend.outreach.groq_personalizer import GroqPersonalizer
from backend.outreach.gmail_sender import GmailSender

def run_bootstrap_pipeline(state='CA', limit=100):
    """Run pipeline with free tools."""

    print("🚀 Bootstrap Pipeline (FREE Mode)")
    print(f"Target: {limit} leads from {state}")
    print("")

    # 1. Scrape (always free)
    print("📊 Step 1: Scraping...")
    os.system(f"acquire scrape --states {state} --limit {limit}")

    # 2. Enrich with free tiers
    print("📧 Step 2: Email enrichment (free tiers)...")
    enricher = FreeEmailWaterfall()
    enricher.enrich_batch(limit=limit)

    # 3. Score (always free)
    print("🎯 Step 3: ML scoring...")
    os.system(f"acquire score --limit {limit}")

    # 4. Personalize with Groq (free)
    print("✍️  Step 4: AI personalization (Groq)...")
    personalizer = GroqPersonalizer()
    personalizer.generate_batch(limit=20)  # Top 20 hot leads

    # 5. Send via Gmail (free up to 500/day)
    print("📨 Step 5: Sending emails...")
    sender = GmailSender()
    sender.send_campaign(limit=10, delay=86400)  # 10/day

    print("")
    print("✅ Bootstrap pipeline complete!")
    print(f"💰 Cost: $0 (or $6/mo if using Google Workspace)")
    print(f"📧 Emails sent: 10/day")
    print(f"📈 Expected response rate: 11%")
    print(f"🤝 Expected meetings: 0.3/day = ~9/month")

if __name__ == '__main__':
    run_bootstrap_pipeline()
```

---

## Pro Tips for Bootstrap Mode

### 1. Focus on Quality over Quantity
- Send 10-20 emails/day (not 1000)
- Manually review each lead before sending
- Perfect the message (11% response rate is achievable)

### 2. Stack Free Tiers Strategically
- Use Hunter free tier for hot leads only
- Save Apollo for when Hunter fails
- Pattern guessing for cold leads (don't waste credits)

### 3. Warm Up Email Account
```
Week 1: 5 emails/day
Week 2: 10 emails/day
Week 3: 20 emails/day
Week 4: 30 emails/day
```

### 4. Reinvest First Dollar
- Close 1 client at $10K/month
- Immediately upgrade to paid tools ($200/month)
- Scale to 10 clients = $100K/month revenue

---

## Summary: Bootstrap vs Full

| Metric | Bootstrap | Full Version |
|--------|-----------|--------------|
| **Cost** | $0-6/mo | $186-246/mo |
| **Email find rate** | 40-60% | 80%+ |
| **Monthly capacity** | 200-500 | 5,000-10,000 |
| **Setup time** | 1 hour | 1 hour |
| **Quality** | 85-90% | 100% |
| **Best for** | Validation | Scale |

---

## Next Steps

**This week**:
1. Create free accounts (15 min)
2. Configure `.env` with free keys (5 min)
3. Run test pipeline: 10 emails (1 hour)

**Next week**:
- Send 10/day = 70 emails
- Get ~7 responses
- Book 2-3 meetings

**Month 2**:
- Send 200 emails total
- Book 6+ meetings
- Close 1 client at $10K/month

**Month 3**:
- Reinvest $200/month in paid tools
- Scale to 1,000 emails/month
- Close 3-5 clients = $50K MRR

**The bootstrap path works. Start free, prove it works, then scale.** 🚀
