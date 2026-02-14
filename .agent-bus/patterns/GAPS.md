# Pattern Gap Analysis

**Generated**: 2026-02-11
**Purpose**: Identifies which projects are missing which patterns and the priority order for applying them.

---

## Gap Matrix

| Project | Grade | Auth | Rate Limit | Security Headers | Stripe Webhooks | Input Validation | LLM Orchestration |
|---------|-------|------|------------|------------------|-----------------|------------------|-------------------|
| Quant | B+ | HAS | HAS | HAS | BROKEN* | HAS | n/a |
| Credit | B+ | HAS | HAS | HAS | n/a | HAS | n/a |
| MobileGameCore | B | n/a | n/a | n/a | n/a | n/a | n/a |
| Course Platform | B- | HAS | HAS | HAS | HAS | HAS | n/a |
| Tower Ascent | B- | n/a | n/a | n/a | n/a | NEEDS | n/a |
| Acquisition System | B- | **NEEDS** | **NEEDS** | **NEEDS** | n/a | PARTIAL | n/a |
| Affiliate | B- | **NEEDS** | **NEEDS** | PARTIAL | n/a | PARTIAL | n/a |
| Discovery | C+ | **NEEDS** | **NEEDS** | **NEEDS** | NEEDS | **NEEDS** | n/a |
| ContractIQ | C+ | PARTIAL | **NEEDS** | **NEEDS** | n/a | **NEEDS** | n/a |
| Calc | C+ | **NEEDS** | **NEEDS** | **NEEDS** | n/a | **NEEDS** | n/a |
| Toonz | C+ | n/a | n/a | **NEEDS** | n/a | **NEEDS** | n/a |
| Pet Quest | C+ | n/a | n/a | n/a | n/a | NEEDS | n/a |
| OYKH | C | n/a | n/a | **NEEDS** | n/a | **NEEDS** | **NEEDS** |
| Back | C | **NEEDS** | **NEEDS** | **NEEDS** | n/a | **NEEDS** | n/a |
| Pod | C- | n/a | n/a | **NEEDS** | n/a | **NEEDS** | **NEEDS** |
| BookCLI | D | n/a | n/a | n/a | n/a | **NEEDS** | HAS |
| Sports | D | **NEEDS** | **NEEDS** | **NEEDS** | n/a | **NEEDS** | n/a |
| LootStack | 5.5/10 | n/a | n/a | n/a | n/a | n/a | n/a |
| Treasure Chase | 5/10 | n/a | n/a | n/a | n/a | n/a | n/a |
| Block Blast | 5/10 | n/a | n/a | n/a | n/a | n/a | n/a |

**Legend**:
- **HAS** = Pattern is implemented
- **NEEDS** = Pattern is missing and needed (bolded = high priority)
- **BROKEN*** = Pattern exists but is commented out / non-functional
- **PARTIAL** = Incomplete implementation
- **n/a** = Pattern does not apply to this project type

---

## Priority-Ordered Fix Plan

### CRITICAL PRIORITY (Revenue / Security at Risk)

#### 1. Quant -- Uncomment Stripe webhook verification
- **Pattern**: `stripe-webhooks.md`
- **File**: Stripe webhook handler (signature verification is commented out)
- **Impact**: Anyone can spoof payment events -- free premium access
- **Effort**: 5 minutes (literally uncomment code)
- **Risk if skipped**: Revenue loss from spoofed payments

#### 2. Sports -- Full security stack
- **Patterns needed**: auth, rate-limiting, security-headers, input-validation
- **Impact**: Zero authentication on all endpoints + wildcard CORS + API keys in URLs
- **Effort**: 4-6 hours
- **Risk if skipped**: Complete data exposure, API key theft
- **Apply order**:
  1. Security headers (15 min)
  2. Input validation (1 hour)
  3. Auth middleware (2-3 hours)
  4. Rate limiting (1 hour)

#### 3. Acquisition System -- Auth + Security headers
- **Patterns needed**: auth (or API key middleware), rate-limiting, security-headers
- **Impact**: 20+ FastAPI endpoints with zero authentication
- **Effort**: 3-4 hours
- **Risk if skipped**: All lead data, business data, campaign data is public
- **Apply order**:
  1. Security headers middleware (15 min)
  2. API key/Bearer token auth middleware (2 hours)
  3. Rate limiting middleware (1 hour)

#### 4. Discovery -- Auth + Paywall enforcement
- **Patterns needed**: auth, rate-limiting, security-headers, input-validation
- **Impact**: Premium paywall is commented out -- all premium content is free
- **Effort**: 3-4 hours
- **Risk if skipped**: Zero revenue from premium features

### HIGH PRIORITY (Should Fix Before Deploy)

#### 5. Calc -- Auth for monitoring + Security headers
- **Patterns needed**: auth (at least for monitoring), rate-limiting, security-headers, input-validation
- **Impact**: Monitoring/metrics endpoints expose system info publicly
- **Effort**: 2-3 hours
- **Apply order**:
  1. Security headers (15 min)
  2. Rate limiting (1 hour)
  3. Auth on monitoring endpoints (1 hour)
  4. Input validation (1 hour)

#### 6. Affiliate/TheStackGuide -- Admin auth + Rate limiting
- **Patterns needed**: auth (admin dashboard), rate-limiting, security-headers (complete)
- **Impact**: Admin dashboard with click data, IPs, revenue is publicly accessible
- **Effort**: 2-3 hours

#### 7. Back -- Full security stack
- **Patterns needed**: auth, rate-limiting, security-headers, input-validation
- **Impact**: Early stage but has no security foundation
- **Effort**: 3-4 hours

### MEDIUM PRIORITY (Operational Excellence)

#### 8. ContractIQ -- Auth + Input validation
- **Patterns needed**: auth (complete), security-headers, input-validation
- **Impact**: FAISS pickle deserialization is a bigger issue, but validation would help
- **Effort**: 2-3 hours
- **Note**: Also needs FAISS `allow_dangerous_deserialization=True` replaced

#### 9. OYKH -- LLM cost controls + Input validation
- **Patterns needed**: llm-orchestration (cost controls), security-headers, input-validation
- **Impact**: No budget cap on AI API calls -- could run up unlimited costs
- **Effort**: 2-3 hours

#### 10. Pod -- LLM cost controls + Input validation
- **Patterns needed**: llm-orchestration (cost controls), security-headers, input-validation
- **Impact**: No cost controls + API keys exposed in source
- **Effort**: 2-3 hours (after fixing API key exposure)

#### 11. Toonz -- Security headers + Input validation
- **Patterns needed**: security-headers, input-validation
- **Impact**: Etsy tokens are world-readable
- **Effort**: 1-2 hours

### LOW PRIORITY (Nice to Have / Game Projects)

#### 12. Tower Ascent -- Input validation
- **Pattern needed**: input-validation (Lua equivalent -- validate RemoteEvent args)
- **Impact**: Client can send arbitrary data via RemoteEvents
- **Effort**: 2-3 hours

#### 13. BookCLI -- Input validation
- **Pattern needed**: input-validation (already has LLM orchestration)
- **Impact**: Shell injection vulnerability in platform_publisher.py
- **Effort**: 1 hour

#### 14. Pet Quest / Mobile Games -- Server-side validation
- These need server-side receipt validation (Apple/Google), not web patterns
- **Effort**: Substantial (different pattern entirely)

---

## Effort Summary

| Priority | Projects | Total Effort | Patterns Applied |
|----------|----------|-------------|------------------|
| Critical | 4 projects | 10-15 hours | All 6 patterns |
| High | 3 projects | 7-10 hours | Auth, Rate Limit, Headers, Validation |
| Medium | 4 projects | 8-11 hours | Headers, Validation, LLM Orchestration |
| Low | 3 projects | 4-6 hours | Validation |
| **Total** | **14 projects** | **29-42 hours** | |

---

## Quick Wins (Under 30 Minutes Each)

These can be done immediately with near-zero risk:

1. **Quant**: Uncomment Stripe webhook signature verification (5 min)
2. **All Python APIs**: Add `SecurityHeadersMiddleware` to FastAPI app (15 min each)
   - Acquisition System, Discovery, Sports, ContractIQ
3. **All Next.js projects**: Add security headers to `middleware.ts` (15 min each)
   - Calc, Affiliate, Back
4. **Discovery**: Uncomment premium paywall check (5 min)

**Total quick wins**: 8 changes, ~2 hours, dramatically improves security posture.
