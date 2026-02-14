# Pattern Library Index

**Generated**: 2026-02-11
**Source**: Code review of 20 projects at `/mnt/e/projects/`
**Location**: `/mnt/e/projects/.agent-bus/patterns/`

---

## Available Patterns

| # | Pattern | File | Source Project | Stack |
|---|---------|------|---------------|-------|
| 1 | [Auth (NextAuth)](#1-auth-nextauth) | `auth-nextjs.md` | Credit (B+) | Next.js / TypeScript |
| 2 | [Rate Limiting](#2-rate-limiting) | `rate-limiting.md` | Credit (B+), Course (B-) | Next.js + FastAPI |
| 3 | [Security Headers](#3-security-headers) | `security-headers.md` | Quant (B+), Credit (B+), Course (B-) | Next.js + FastAPI |
| 4 | [Stripe Webhooks](#4-stripe-webhooks) | `stripe-webhooks.md` | Course (B-) | Next.js + FastAPI |
| 5 | [Input Validation](#5-input-validation) | `input-validation.md` | Credit (B+), Course (B-), Acquisition (B-) | Zod + Pydantic |
| 6 | [LLM Orchestration](#6-llm-orchestration) | `llm-orchestration.md` | BookCLI | Python |

---

## When to Use Each Pattern

### 1. Auth (NextAuth)
**Use when**: Your Next.js project needs user login, registration, or role-based access control.
- Credentials (email/password) + OAuth (Google)
- JWT sessions with role in token
- Prisma adapter for user storage

### 2. Rate Limiting
**Use when**: Any endpoint faces the public internet. Start with these tier defaults:
- **Auth endpoints**: 5 requests per 15 minutes (brute-force prevention)
- **API endpoints**: 60-100 requests per minute (general abuse prevention)
- **Payment endpoints**: 10 requests per hour (fraud prevention)
- **Search/AI endpoints**: 30 requests per minute (cost control)

### 3. Security Headers
**Use when**: Always. Every HTTP response should have these headers. There is no valid reason to skip this pattern. Apply it as middleware so it covers all routes automatically.

### 4. Stripe Webhooks
**Use when**: Your project accepts payments via Stripe. The three critical requirements:
1. Signature verification (prevents fake events)
2. Idempotent processing (handles webhook retries)
3. Raw body reading (signature fails if body is pre-parsed)

### 5. Input Validation
**Use when**: Any endpoint that accepts user input (which is all of them). Two sub-patterns:
- **Request validation**: Zod schemas (TS) or Pydantic models (Python) on every endpoint
- **Environment validation**: Validate env vars at startup, crash immediately if missing

### 6. LLM Orchestration
**Use when**: Your project calls LLM APIs and you need:
- High availability (failover across providers)
- Cost control (daily budget caps)
- Performance (response caching)
- Stability (circuit breakers prevent cascading failures)

---

## Pattern Application Priority

### Tier 1: Apply Immediately (security-critical)
1. **Security Headers** -- zero effort, maximum protection
2. **Input Validation** -- prevents injection and crashes
3. **Auth** -- if project has no authentication

### Tier 2: Apply Before Deploy (abuse prevention)
4. **Rate Limiting** -- prevents resource exhaustion
5. **Stripe Webhooks** -- if accepting payments

### Tier 3: Apply for Production Quality (operational excellence)
6. **LLM Orchestration** -- if using AI APIs

---

## Related Files
- **Gap Analysis**: `GAPS.md` -- which projects need which patterns
- **Code Reviews**: `/mnt/e/projects/.agent-bus/reviews/` -- detailed per-project findings
- **Master Summary**: `/mnt/e/projects/.agent-bus/reviews/MASTER_REVIEW_SUMMARY.md`
