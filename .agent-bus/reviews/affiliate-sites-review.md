# Affiliate Sites Code Review (Updated)

**Reviewer:** Senior Code Review Agent (Claude Opus 4.6)
**Date:** 2026-02-11
**Scope:** Full security, quality, and production-readiness review of 4 affiliate site projects
**Prior Review:** Incorporates and expands on earlier review from same date

---

## Executive Summary

| Project | Grade | Stack | Production Ready? |
|---------|-------|-------|-------------------|
| **Credit** | **B+** (7/10) | Next.js 14, Prisma, NextAuth, Upstash | Nearly - fix secrets leak + fake metrics |
| **Calc** | **C+** (5/10) | Next.js 15, Supabase, Recharts | No - fake reviews, no auth on APIs, TS errors suppressed |
| **Back** | **C** (5/10) | Vite + React SPA, React Router, Zustand | No - SPA kills SEO, no real affiliate links |
| **Affiliate** | **B-** (6/10) | Next.js 14.1, Supabase, Markdown CMS | Close - fix auth, XSS, and token leak |

**None of the four projects can generate revenue today.** All affiliate links are placeholder URLs pointing to generic homepages without tracking parameters. This is the single most important business blocker.

---

## Project 1: Credit Card Affiliate Site (`/mnt/e/projects/credit/`)

**Stack:** Next.js 14 + TypeScript + Prisma + NextAuth + Tailwind + Upstash Redis

### Critical Issues

**CRIT-1: Vercel OIDC Token and Production Secrets in Files**
- `/mnt/e/projects/credit/.env.local` line 2 -- Contains full Vercel OIDC JWT token exposing team ID `team_0G0YO0SMviyf6mdqW6xGkFm3`, project ID `prj_4Vhoy96r2ewAMKdZ8k8LoG18EU9O`
- `/mnt/e/projects/credit/.env.vercel` -- Contains `NEXTAUTH_SECRET`, `CSRF_SECRET`, `CRON_SECRET` in plaintext
- While `.gitignore` covers `.env*` patterns, these files exist in the working directory and the parent repo (`/mnt/e/projects/`) shows them as untracked. If the parent repo ever does `git add -A`, all secrets are committed.
- **Action**: Rotate all secrets immediately. Delete `.env.local` and `.env.vercel`. Store secrets in Vercel dashboard only.

**CRIT-2: Fabricated Social Proof Statistics**
- `/mnt/e/projects/credit/app/page.tsx` lines 254-258 -- Claims "50K+ Happy Users", "200+ Cards Compared", "$10M+ Total Savings"
- These statistics are fabricated for a site that has not launched. This violates FTC guidelines for affiliate sites and could undermine credibility if discovered.
- **Action**: Replace with honest metrics or remove entirely.

**CRIT-3: Placeholder Verification Codes in Production Metadata**
- `/mnt/e/projects/credit/lib/metadata.ts` lines 80-82 -- `google: 'your-google-site-verification-code'` is a literal string shipped in metadata
- **Action**: Either set real verification codes or remove the field.

### Warnings

1. **Client-Side Blog Rendering Hurts SEO** -- `/mnt/e/projects/credit/app/blog/[slug]/page.tsx` is a `'use client'` component with a custom `renderMarkdown()` function. Blog content is not server-rendered, which means Google may not fully index it. For a content-driven affiliate site, this is a significant SEO loss.

2. **Missing NEXTAUTH_SECRET in `.env`** -- The main `.env` file does not contain `NEXTAUTH_SECRET`. Without it, NextAuth falls back to an insecure default. It is in `.env.vercel` but that file should be deleted (see CRIT-1).

3. **Custom SQL Sanitizer is Dangerous** -- `/mnt/e/projects/credit/lib/api/validation.ts` contains `sanitizeSQL()` using simple string replacement (`replace(/'/g, "''")`). The comment says "use parameterized queries instead!" Since Prisma uses parameterized queries, this function should be deleted to prevent misuse.

4. **Email Unsubscribe Without Auth** -- `/mnt/e/projects/credit/app/api/email/capture/route.ts` DELETE handler allows unsubscribing by email or token without authentication. An attacker could mass-unsubscribe users.

5. **Error Messages Leak Implementation Details** -- `/mnt/e/projects/credit/app/api/email/capture/route.ts` line 200 returns `error.message` to clients, potentially exposing Prisma/database errors.

6. **Prisma 5.7.1 is Outdated** -- `/mnt/e/projects/credit/package.json` pins Prisma at 5.7.1 (current is 6.x). Security patches may be missing.

7. **`socket.io-client` Unused** -- Listed in package.json but no WebSocket usage found in codebase.

8. **No Content Security Policy Headers** -- No middleware CSP configuration found (though the prior review mentions one exists in middleware.ts -- verify this is active).

### Positive Findings

- Excellent auth implementation (NextAuth + Prisma adapter, bcrypt hashing)
- Comprehensive rate limiting (Upstash Redis with in-memory fallback)
- Strong input validation (Zod schemas on all API inputs)
- Affiliate fraud detection (duplicate click detection, IP flood detection)
- PII redaction for non-admin users on click details
- GDPR cookie consent component
- Skip-to-content accessibility link
- Legal compliance pages (privacy, terms, advertiser disclosure)
- Environment variable validation with Zod at startup (`/mnt/e/projects/credit/lib/env.ts`)

### Code Quality: 7/10

---

## Project 2: Dividend Calculator Affiliate Site (`/mnt/e/projects/calc/`)

**Stack:** Next.js 15 + TypeScript + Tailwind + Radix UI + Supabase + Recharts

### Critical Issues

**CRIT-1: Fabricated Structured Data / Fake Reviews**
- `/mnt/e/projects/calc/app/layout.tsx` lines 206-239
- Contains `aggregateRating` claiming 4.9/5 from "12,847" ratings and "3,456" reviews, plus fabricated review quotes
- Google explicitly penalizes fabricated review markup. This could result in a manual action penalty, destroying all SEO value for months.
- **Action**: Remove immediately. This is the highest-risk issue across all projects.

**CRIT-2: In-Memory Conversion Tracking (Data Loss)**
- `/mnt/e/projects/calc/app/api/track-conversion/route.ts` line 19
- `const conversions: ConversionData[] = []` -- Module-level array lost on every Vercel cold start
- All conversion data is ephemeral. Zero revenue attribution is possible.
- **Action**: Replace with Supabase or PostgreSQL storage.

**CRIT-3: TypeScript/ESLint Errors Suppressed**
- `/mnt/e/projects/calc/next.config.js` lines 81-87
- `typescript: { ignoreBuildErrors: true }` and `eslint: { ignoreDuringBuilds: true }`
- Type errors in financial calculators could produce incorrect results, leading to bad financial decisions.
- **Action**: Fix underlying errors and remove these flags.

**CRIT-4: Unprotected Monitoring/Analytics Endpoints**
- `/mnt/e/projects/calc/app/api/track-conversion/route.ts` lines 111-175 -- GET endpoint returns all conversion data including IP addresses, user agents with zero auth
- `/mnt/e/projects/calc/app/api/monitoring/metrics/route.ts` -- Exposes `process.memoryUsage()`, `process.cpuUsage()`, `process.uptime()`
- **Action**: Add authentication to all monitoring/admin endpoints.

**CRIT-5: SEO Title Uses Wrong Year**
- `/mnt/e/projects/calc/app/layout.tsx` line 22 -- `'... | 2025'` and keyword `'best dividend stocks 2025'` (line 50)
- **Action**: Update to 2026.

### Warnings

1. **`maximumScale: 1` Prevents Zooming** -- `/mnt/e/projects/calc/app/layout.tsx` line 16 -- Accessibility violation (WCAG 1.4.4).

2. **`force-dynamic` on Home Page** -- `/mnt/e/projects/calc/app/page.tsx` line 15 -- Disables static generation unnecessarily, increasing costs.

3. **Cookie Parsing Without Try/Catch** -- `/mnt/e/projects/calc/app/api/track-conversion/route.ts` line 43 -- `JSON.parse(affiliateData.value)` will crash on malformed cookies.

4. **Missing `vitest` Dependency** -- package.json references `vitest run` in test script but vitest is not in devDependencies.

5. **No Rate Limiting on Any Endpoint** -- Subscribe, errors, logs, metrics endpoints are all completely unprotected.

6. **GA ID Injection via Template Literal** -- `/mnt/e/projects/calc/app/layout.tsx` lines 305-318 -- Uses `dangerouslySetInnerHTML` for GA script. Server-controlled value but suboptimal pattern (Affiliate project uses safer `next/script` approach).

### Positive Findings

- Comprehensive SEO metadata (aside from fake reviews)
- Honeypot + timing bot protection on subscribe endpoint
- Proper error boundary with user-friendly UI
- Dynamic imports for code splitting
- Web Vitals monitoring
- Pino structured logger

### Code Quality: 5/10

---

## Project 3: Backtesting Affiliate Site (`/mnt/e/projects/back/`)

**Stack:** Vite + React 18 + TypeScript + React Router + Zustand + Tailwind (Client-side SPA)

### Critical Issues

**CRIT-1: SPA Architecture Fundamentally Breaks SEO**
- The entire site is a client-side SPA. Search engines see an empty `<div id="root">` HTML shell.
- SEO utilities at `/mnt/e/projects/back/frontend/src/utils/seo.ts` manipulate the DOM at runtime using `document.title` and `document.querySelector` -- Google may not reliably execute this JavaScript.
- Client-side structured data injection (`addStructuredData()` at line 108) creates JSON-LD scripts at runtime which Google may not parse.
- For an affiliate site targeting competitive finance keywords, this architecture will never rank.
- **Action**: Migrate to Next.js or Astro for server-side rendering.

**CRIT-2: No Real Affiliate Tracking URLs**
- `/mnt/e/projects/back/frontend/src/data/affiliateLinks.ts` -- All URLs are generic homepages
- `trackAffiliateClick()` at line 208 only does `console.log` and an optional `window.gtag` call
- No server-side tracking, no click persistence, no conversion attribution
- **Action**: Register for affiliate programs, replace URLs, add server-side tracking.

### Warnings

1. **`FeatureFlagsDebugPanel` Renders Unconditionally** -- `/mnt/e/projects/back/frontend/src/App.tsx` line 38 -- Debug panel may be visible in production, exposing internal feature flag state.

2. **No Error Tracking in Production** -- ErrorBoundary at `/mnt/e/projects/back/frontend/src/components/ErrorBoundary.tsx` line 41 has a TODO comment for Sentry but nothing is configured.

3. **No Security Headers or CSP** -- Vite SPA has no middleware for security headers.

4. **No Privacy Policy or Terms Pages** -- Legal compliance pages are missing.

5. **No HTTPS Enforcement** -- No redirect configuration from HTTP to HTTPS.

6. **XSS in HTML Transformer** (Affiliate) -- `/mnt/e/projects/affiliate/thestackguide/src/lib/htmlTransformer.ts:114` -- `data.ctaHref` is injected into HTML without escaping. Malicious href could inject arbitrary HTML/JS.

### Positive Findings

- Clean component architecture with proper separation (stores/, hooks/, services/, pages/)
- Well-designed analytics service class supporting multiple providers
- Comprehensive TypeScript typing throughout
- Feature flags provider for controlled rollout
- Error boundary wrapping all routes
- Form validation with Zod + react-hook-form

### Code Quality: 5/10

---

## Project 4: The Stack Guide (`/mnt/e/projects/affiliate/thestackguide/`)

**Stack:** Next.js 14.1 + TypeScript + Tailwind + Supabase + Markdown CMS

### Critical Issues

**CRIT-1: XSS Vulnerability in Article Content Rendering**
- `/mnt/e/projects/affiliate/thestackguide/src/components/ArticleContent.tsx` line 17
- `dangerouslySetInnerHTML={{ __html: html }}` renders article HTML without sanitization
- `/mnt/e/projects/affiliate/thestackguide/src/lib/htmlTransformer.ts` line 114: `buildVerdictBox()` injects `data.ctaHref` directly into an HTML attribute: `href="${data.ctaHref}"` without escaping
- If a markdown file's CTA href contained `" onclick="alert(1)`, this would execute arbitrary JavaScript
- **Action**: Add DOMPurify or sanitize-html before rendering. Escape all dynamic values in htmlTransformer.ts.

**CRIT-2: Admin Analytics Dashboard Has Zero Authentication**
- `/mnt/e/projects/affiliate/thestackguide/src/app/admin/analytics/page.tsx` -- Publicly accessible
- `/mnt/e/projects/affiliate/thestackguide/src/app/api/analytics/route.ts` -- Both GET and POST are unprotected
- Exposes PII (IP addresses, user agents, session IDs, country codes) and business intelligence
- **Action**: Add authentication middleware, even basic auth or a shared secret.

**CRIT-3: All Affiliate Links Are Generic Placeholders**
- `/mnt/e/projects/affiliate/thestackguide/src/lib/affiliateLinks.ts` -- All 40+ destinations point to homepages without referral IDs
- Zero revenue will be generated from any clicks
- **Action**: Join affiliate programs and replace URLs.

### Warnings

1. **Next.js 14.1.0 is Outdated** -- `/mnt/e/projects/affiliate/thestackguide/package.json` line 14 -- Multiple security patches since this version.

2. **Fallback Pattern Defaults to Jasper** -- `/mnt/e/projects/affiliate/thestackguide/src/lib/affiliateLinks.ts` lines 112-113 -- `[/Try .+ Free/i, 'jasper']` means any unmatched "Try X Free" link incorrectly redirects to Jasper.

3. **Session Cookie Not HttpOnly** -- `/mnt/e/projects/affiliate/thestackguide/src/app/go/[tool]/route.ts` lines 95-100 -- Missing `httpOnly: true` on `aff_session` cookie, allowing JavaScript to read session IDs.

4. **1-Year Session Cookie Expiry** -- 365-day session cookie is excessive; 30-90 days is standard for affiliate attribution.

5. **Supabase Anon Key Used for Server-Side Inserts** -- `/mnt/e/projects/affiliate/thestackguide/src/lib/supabase.ts` lines 4-5 -- `NEXT_PUBLIC_` prefix exposes key to browser. Verify RLS policies are active.

6. **No Rate Limiting on API Endpoints** -- Both analytics and subscribe endpoints lack rate limiting.

7. **Console Logging PII** -- `/mnt/e/projects/affiliate/thestackguide/src/app/go/[tool]/route.ts` lines 73-82 -- Logs IP, referrer, country to console in production (GDPR risk if logs retained).

8. **No robots.txt Disallow for Admin** -- Should disallow `/admin/*` and `/api/*`.

### Positive Findings

- Clean `/go/[tool]` affiliate redirect system with 302, noindex, no-cache headers
- Supabase-backed click tracking with session, IP, country, referrer
- Static content generation with markdown processing pipeline
- Proper SEO metadata generation per article
- Structured data (article schema, breadcrumbs)
- Affiliate disclosure page (FTC compliance)
- Category system, comparison pages, search functionality
- Tool quiz recommendation engine

### Code Quality: 6/10

---

## Cross-Project Comparison

| Issue | Credit | Calc | Back | Affiliate |
|-------|--------|------|------|-----------|
| Real affiliate links | Placeholder | Placeholder | Placeholder | Placeholder |
| Authentication on admin | Partial | **None** | N/A | **None** |
| XSS vulnerabilities | Low risk | Low risk | Low risk | **Medium risk** |
| SEO readiness | Good (except blog) | **Broken** (fake data) | **Broken** (SPA) | Good |
| Error handling | Good | Good | Good | Acceptable |
| Fabricated metrics | **Yes** | **Yes** | No | No |
| Production database | SQLite (dev only) | In-memory (loses data) | N/A | Supabase (if configured) |
| Leaked secrets | **OIDC token + keys** | No | No | OIDC token |
| Rate limiting | Yes (Upstash) | **None** | N/A | **None** |
| Input validation | Zod (comprehensive) | Zod (partial) | Zod | Basic regex |
| SSR/SSG for SEO | Yes | Yes | **No (SPA)** | Yes |
| Legal pages | Complete | Partial | **Missing** | Partial |

---

## Priority Fix Order (All Projects)

### Immediate (Before Any Deploy)
1. **Rotate all secrets** in Credit `.env.vercel` and `.env.local` -- they are compromised
2. **Delete** `.env.local` and `.env.vercel` from Credit and Affiliate working directories
3. **Remove fabricated reviews/ratings** from Calc structured data (`layout.tsx` lines 206-239)
4. **Remove fabricated user statistics** from Credit home page (`page.tsx` lines 254-258)
5. **Add authentication** to Affiliate admin dashboard and analytics API
6. **Add authentication** to Calc monitoring/conversion/error/log endpoints

### Before Launch
7. Fix TypeScript errors in Calc (remove `ignoreBuildErrors`)
8. Add HTML sanitization to Affiliate ArticleContent component
9. Add rate limiting to all Calc and Affiliate API routes
10. Replace placeholder affiliate URLs with actual tracked links (all projects)
11. Set `httpOnly: true` on Affiliate session cookie
12. Delete the `sanitizeSQL` function from Credit
13. Fix email unsubscribe to require auth token (Credit)
14. Update "2025" to "2026" in Calc metadata
15. Add privacy policy to Back and Affiliate projects

### Architecture Changes (Post-Launch)
16. Migrate Back project from SPA to Next.js/Astro for SSR
17. Convert Credit blog pages to server-side rendering
18. Replace Calc in-memory conversion storage with database
19. Add error monitoring (Sentry) to Calc and Affiliate
20. Upgrade Next.js versions across all projects

---

## Revenue Readiness Assessment

| Project | Can Generate Revenue Today? | Primary Blocker |
|---------|---------------------------|-----------------|
| Credit | **No** | No real affiliate links, SQLite only, secrets need rotation |
| Calc | **No** | No real affiliate links, fake reviews risk Google penalty, in-memory tracking |
| Back | **No** | No real affiliate links, SPA won't rank in search |
| Affiliate | **No** | No real affiliate links, unprotected admin, no Supabase configured |

**The single most important action across all projects is joining actual affiliate programs and replacing placeholder URLs with tracked links.**
