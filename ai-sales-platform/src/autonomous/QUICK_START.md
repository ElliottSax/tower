# Quick Start - Launch Your First Business in 30 Minutes

**No incorporation needed!** Most businesses can start as sole proprietorships.

## Prerequisites

- Node.js 20+
- Docker (for PostgreSQL)
- OpenAI or Anthropic API key
- 30 minutes

## Step 1: Setup (5 minutes)

```bash
# Clone or navigate to project
cd /mnt/e/projects/ai-sales-platform

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Add your API key to .env
# Minimum needed:
# OPENAI_API_KEY=sk-... OR ANTHROPIC_API_KEY=sk-ant-...
# DATABASE_URL=postgresql://localhost:5432/ai_sales_platform
nano .env

# Start database
docker-compose up -d
```

## Step 2: Run Demo (5 minutes)

```bash
npm run autonomous:demo
```

**What happens:**
1. CEO Agent validates business idea
2. **Formation Advisor** decides: Incorporate or skip?
3. Product Manager plans MVP development
4. Marketing Manager creates strategy
5. Operations Manager plans support setup
6. Finance Manager sets up tracking

**Output:**
```
🚀 Launching Autonomous Business Platform
Idea: AI-powered meal planning app

[Formation Advisor] Analyzing legal structure needs
✅ Recommendation: sole_proprietorship
   Reasoning: SaaS business with low liability
   Cost: $0 (can incorporate later if needed)

[Product Manager] Planning MVP development
   Tech stack: Next.js + Supabase + Vercel
   Estimated: 5 days, $500

[Marketing Manager] Creating strategy
   Channels: SEO, Meta Ads, Content
   Budget: $650/month

✅ Business Launch Workflow Completed
   Phase: product
   Total Cost: $0 (demo mode)
   Est. Monthly: $700
```

## Step 3: Understand the Decision (5 minutes)

### Why No Incorporation?

For most businesses (SaaS, apps, digital products):
- ✅ Lower liability risk
- ✅ Can use Stripe with personal entity
- ✅ Simpler taxes (Schedule C on personal return)
- ✅ Save $399 incorporation cost
- ✅ Start immediately (no 1-3 day wait)

**You can always incorporate later when profitable!**

### When You SHOULD Incorporate

The Formation Advisor will recommend LLC/C-Corp if:
- Physical products (liability risk)
- Multiple founders (equity structure needed)
- Raising venture capital (C-Corp required)
- Hiring employees
- Expected revenue > $50K/year

## Step 4: Customize for Your Business (10 minutes)

Edit `src/autonomous/example.ts`:

```typescript
const idea: BusinessIdea = {
  description: 'YOUR BUSINESS IDEA HERE',
  targetMarket: 'WHO ARE YOUR CUSTOMERS?',
  problemSolved: 'WHAT PROBLEM DO YOU SOLVE?',
  monetizationModel: 'HOW WILL YOU MAKE MONEY?',
};

const businessName = 'YOUR BUSINESS NAME';
```

Run again:
```bash
npm run autonomous:demo
```

## Step 5: Next Steps (5 minutes)

### Option A: Go Live (Real Launch)

To actually launch your business:

1. **Get API keys** (see `.env.example`):
   - Replit Agent (code generation) - $500/project
   - Meta Business API (ads) - Free to setup
   - Stripe (payments) - Free, 2.9% + 30¢ per transaction

2. **Update workers** from placeholders to real integrations:
   ```typescript
   // In src/autonomous/orchestrator.ts
   // Replace placeholder workers with real implementations
   workflow.addNode('developer_worker', replitAgentWorker);
   ```

3. **Run for real**:
   ```bash
   npm run autonomous:launch
   ```

### Option B: Keep Testing

- Try different business ideas
- Test the Formation Advisor recommendations
- Understand the cost model
- Review agent decisions

## Cost Breakdown

### Launch Costs (One-Time)

| Item | Cost |
|------|------|
| Legal (skip for most!) | $0 |
| MVP Development (Replit) | $500 |
| Initial Marketing | $500 |
| **Total** | **$1,000** |

### Monthly Operating Costs

| Category | Cost |
|----------|------|
| AI (Claude + GPT-4o) | $300 |
| Hosting (Vercel + Supabase) | $50 |
| Marketing (SEO + Ads) | $350 |
| Support (Fin AI or Chatwoot) | $150 |
| Analytics (PostHog) | $50 |
| **Total** | **$900/month** |

**Note**: Can reduce to $700/month with optimizations:
- Use more GPT-4o Mini (cheaper)
- Chatwoot instead of Fin AI (free, open source)
- Prompt caching (90% savings)

## Understanding Each Agent

### CEO Agent
- **Role**: Strategic orchestrator
- **Decides**: Which manager to delegate to
- **Budget**: Enforces $700/month limit
- **Escalates**: Decisions >$5K to human

### Formation Advisor
- **Role**: Legal structure advisor
- **Decides**: Incorporate or skip?
- **Recommendation**: Sole proprietorship for 80% of businesses
- **Saves**: $399 incorporation cost

### Product Manager
- **Role**: MVP development
- **Delegates to**: Replit Agent (code generation)
- **Output**: Deployed app on Vercel
- **Timeline**: 3-7 days

### Marketing Manager
- **Role**: Customer acquisition
- **Delegates to**: SEObot (content), Meta AI (ads)
- **Channels**: SEO, Meta Ads, Google Ads
- **Budget**: $650/month

### Operations Manager
- **Role**: Support & monitoring
- **Delegates to**: Fin AI or Chatwoot
- **Target**: 70% support automation
- **Budget**: $200/month

### Finance Manager
- **Role**: Bookkeeping & tracking
- **Tools**: Stripe dashboard initially, Ramp AI when scaling
- **Tracks**: Revenue, expenses, burn rate
- **Budget**: $0-100/month

## Common Questions

### Do I really not need to incorporate?

For digital businesses (SaaS, apps, services): **No, you don't!**
- Use Stripe with personal entity
- File taxes on Schedule C
- Get liability insurance if needed ($500/year)
- Incorporate later when profitable

### When should I incorporate?

The Formation Advisor will tell you, but generally:
- After first $10K revenue
- Before hiring employees
- Before raising money from investors
- If building physical products

### Can I incorporate later?

**Yes!** It's easy to transfer:
1. Incorporate via doola ($399)
2. Transfer Stripe account to LLC
3. Update contracts to new entity
4. Takes 1-2 days

### What if I already have an LLC?

Perfect! You can:
- Use existing EIN for Stripe
- Skip the incorporation step
- Still use all the AI automation

### Is this really fully autonomous?

**Phase 1**: Agents make decisions, workers are placeholders
**Phase 2-6**: Real API integrations for full automation
**Human-in-the-loop**: For critical decisions (always)

## Troubleshooting

### "No API key found"
```bash
# Add to .env:
OPENAI_API_KEY=sk-...
# OR
ANTHROPIC_API_KEY=sk-ant-...
```

### "Database connection failed"
```bash
# Start PostgreSQL:
docker-compose up -d

# Check it's running:
docker-compose ps
```

### "Demo shows $0 cost"
That's correct! Demo uses placeholder workers (no real API calls).
To see real costs, add API keys and run actual integrations.

### "Agent decision doesn't make sense"
The LLM might hallucinate. This is Phase 1 - real integrations coming in Phase 2-6.

## Next Reading

- [Full Documentation](./README.md)
- [Why Incorporation is Optional](../../INCORPORATION_OPTIONAL.md)
- [Implementation Details](../../AUTONOMOUS_PLATFORM_IMPLEMENTATION.md)
- [Complete Architecture](../../AUTONOMOUS_BUSINESS_PLATFORM.md)

## Support

Questions? Check:
- `src/autonomous/example.ts` - Working code
- `.env.example` - All API keys needed
- `INCORPORATION_OPTIONAL.md` - Legal structure FAQ

---

**You're ready to launch!** 🚀

Most businesses don't need incorporation. Start lean, validate the idea, incorporate when profitable.
