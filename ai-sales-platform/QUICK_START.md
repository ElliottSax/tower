# Quick Start Guide

Get the AI Sales Platform running in 10 minutes.

## Prerequisites

- Node.js 18+ installed
- PostgreSQL 14+ running
- Redis 6+ running (optional for now)
- OpenAI API key
- Apollo API key (optional, for enrichment)

## Installation

### 1. Install Dependencies

```bash
cd /mnt/e/projects/ai-sales-platform
npm install
```

### 2. Set Up Environment

```bash
cp .env.example .env
```

Edit `.env` with your keys:

```env
# Required
DATABASE_URL=postgresql://user:password@localhost:5432/ai_sales_platform
JWT_SECRET=your-secret-key-change-this
OPENAI_API_KEY=sk-...

# Optional (for full functionality)
APOLLO_API_KEY=...
CLEARBIT_API_KEY=...
REDIS_URL=redis://localhost:6379
```

### 3. Set Up Database

```bash
# Create database
createdb ai_sales_platform

# Run migrations (once we create them)
npm run db:migrate
```

For now, you can manually create tables by copying SQL from `src/db/schema.ts`.

### 4. Start the Server

```bash
npm run dev
```

You should see:

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🤖  AI Sales Platform - Running  🚀              ║
║                                                           ║
║  Port:        3000                                        ║
║  Environment: development                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

## Try It Out

### Test 1: Health Check

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0"
}
```

### Test 2: AI Agent Workflow

```bash
curl -X POST http://localhost:3000/api/agent/execute \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "type": "personalize",
      "input": {
        "customInstructions": "We help sales teams automate outreach"
      }
    },
    "lead": {
      "firstName": "Jane",
      "lastName": "Smith",
      "email": "jane@techcorp.com",
      "jobTitle": "VP of Sales",
      "companyName": "TechCorp",
      "companyDomain": "techcorp.com"
    }
  }'
```

This will:
1. Research TechCorp (using web search if configured)
2. Enrich Jane's contact details (if Apollo is configured)
3. Generate a personalized email using AI

Expected response:
```json
{
  "success": true,
  "sessionId": "uuid-here",
  "result": {
    "research": {
      "companyInfo": { ... },
      "buyingSignals": [ ... ]
    },
    "enrichment": {
      "source": "apollo",
      "confidence": 85,
      "data": { ... }
    },
    "personalization": {
      "subject": "Quick question about your SDR team",
      "body": "Hi Jane...",
      "reasoning": "..."
    },
    "errors": []
  }
}
```

### Test 3: Lead Enrichment Only

```bash
curl -X POST http://localhost:3000/api/leads/enrich \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "domain": "example.com"
  }'
```

### Test 4: Email Generation Only

```bash
curl -X POST http://localhost:3000/api/emails/generate \
  -H "Content-Type: application/json" \
  -d '{
    "lead": {
      "firstName": "John",
      "lastName": "Doe",
      "jobTitle": "CTO",
      "companyName": "Example Corp"
    },
    "customInstructions": "Focus on technical benefits"
  }'
```

## Project Structure

```
ai-sales-platform/
├── src/
│   ├── agents/              # AI agent implementations ⭐
│   │   ├── supervisor.ts    # Main orchestrator
│   │   ├── researcher.ts    # Lead research
│   │   ├── enricher.ts      # Data enrichment
│   │   └── writer.ts        # Email personalization
│   ├── services/
│   │   └── enrichment/      # Waterfall enrichment ⭐
│   │       ├── waterfall.ts
│   │       └── providers/
│   ├── db/
│   │   └── schema.ts        # Database schema
│   ├── config/
│   │   └── index.ts         # Configuration
│   └── index.ts             # API server
├── package.json
├── tsconfig.json
├── README.md
├── IMPLEMENTATION_PLAN.md   # Full implementation guide
└── .env.example
```

## Common Issues

### "Module not found" errors

```bash
npm install
npm run build
```

### Database connection errors

Make sure PostgreSQL is running:
```bash
# On macOS
brew services start postgresql

# On Linux
sudo systemctl start postgresql

# Check connection
psql -h localhost -U postgres
```

### "OPENAI_API_KEY not set"

The API will warn you but still start. Some features won't work without API keys:
- Research agent needs OPENAI_API_KEY
- Enricher needs APOLLO_API_KEY or CLEARBIT_API_KEY
- Writer agent needs OPENAI_API_KEY or ANTHROPIC_API_KEY

## Next Steps

1. **Read the Implementation Plan:** See `IMPLEMENTATION_PLAN.md` for the full roadmap
2. **Explore the AI Agents:** Check out `src/agents/` to understand the orchestration
3. **Set Up Database:** Create migrations for the schema
4. **Add Authentication:** Implement JWT middleware
5. **Test with Real Data:** Try with your own leads

## Development Workflow

```bash
# Start dev server with hot reload
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run tests (once we add them)
npm test

# Lint code
npm run lint
```

## API Documentation

Once running, the available endpoints are:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /health | Health check |
| POST | /api/agent/execute | Run full AI workflow |
| POST | /api/leads/enrich | Enrich a lead |
| POST | /api/emails/generate | Generate personalized email |

For detailed API docs, see the main README.md.

## Getting Help

- **Documentation:** See README.md and IMPLEMENTATION_PLAN.md
- **Architecture:** See AI_ORCHESTRATION_ARCHITECTURE.md
- **Issues:** Check console logs for detailed error messages

## Production Deployment

When ready to deploy:

1. Set NODE_ENV=production
2. Use a real database (not local)
3. Set up Redis for queues
4. Configure proper secrets
5. Enable monitoring (Sentry, DataDog)
6. Set up backups
7. Configure load balancer

See IMPLEMENTATION_PLAN.md Phase 3 for deployment checklist.
