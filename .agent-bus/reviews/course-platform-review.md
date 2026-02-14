# Course Platform (CourseFlow) - Deep Code Review

**Reviewer**: Senior Fullstack Code Reviewer (Payment-Processing Specialist)
**Date**: 2026-02-11
**Codebase**: `/mnt/e/projects/course/courseflow/`
**Stack**: Next.js 16, React 19, TypeScript, Drizzle ORM, PostgreSQL, Stripe, Supabase Auth, Cloudflare Stream

---

## 1. Executive Summary

**Overall Grade: B-**

CourseFlow is a well-architected course marketplace with solid security foundations. The `createApiHandler` pattern provides consistent auth, CSRF, rate limiting, and input validation across endpoints. Stripe webhook handling is properly implemented with signature verification and idempotent enrollment. However, there are **several critical issues that MUST be fixed before processing real money**, including exposed production credentials on disk, a free enrollment bypass that skips payment, missing CSRF token propagation to the frontend, default secrets used in crypto operations, and calls to a non-existent `ApiResponse.error()` method.

**Risk Assessment**: HIGH - The platform handles real money and user PII. The credential exposure is a showstopper. The free enrollment bypass means users can enroll without paying. Two endpoints will crash at runtime due to calling a method that does not exist.

---

## 2. Code Quality: 7/10

**Strengths**: Clean TypeScript, consistent patterns via `createApiHandler`, proper Drizzle ORM usage, comprehensive schema design with indexes and constraints, well-structured file organization following Next.js App Router conventions, Zod validation on nearly all endpoints, good separation of concerns.

**Weaknesses**: Two distinct CSRF implementations creating confusion, unused SQL injection-prone helper function left exported, multiple calls to `ApiResponse.error()` which does not exist (will throw at runtime), `setInterval` side effects at module scope that are incompatible with serverless, broken template literal in a critical UI component, frontend forms do not send CSRF tokens despite backend requiring them.

---

## 3. CRITICAL Issues (MUST FIX Before Launch)

### CRITICAL-1: Production Secrets on Disk
**Severity**: P0 - EMERGENCY
**File**: `/mnt/e/projects/course/courseflow/.env.production` (lines 1-42)

The `.env.production` file contains **real production credentials** on disk:
- Supabase database URL with password: `postgresql://postgres:the_generated_password$a!GKcpidWjC6$K@db.opwcqdrvtjginwwupemo.supabase.co`
- Supabase anon key and service role key (JWTs with project reference `opwcqdrvtjginwwupemo`)
- Stripe test secret key: `sk_test_51SXvH1Fuvrk...`
- Stripe publishable key
- Upstash Redis credentials
- Sentry DSN

While these files are not tracked in git (verified via `git ls-files` and `.gitignore`), having real credentials on disk in a known filename is risky. If the repo is ever misconfigured or the `.gitignore` is modified, these credentials would be exposed.

**Impact**: Anyone with filesystem access has full database admin access, can create Stripe charges, and can impersonate any user via the service role key.

**Fix**:
1. Immediately rotate ALL exposed credentials (Supabase, Stripe, Upstash, Sentry)
2. Remove `.env.production` from the filesystem entirely
3. Use Vercel environment variables or a dedicated secrets manager (e.g., Doppler, Vault)
4. Add `.env.production` to `.gitignore` (already present, but verify)
5. Audit git history to confirm these files were never committed

---

### CRITICAL-2: Free Enrollment Bypass - Enrollment Without Payment
**Severity**: P0 - FINANCIAL LOSS
**File**: `/mnt/e/projects/course/courseflow/app/api/courses/[id]/enroll/route.ts` (lines 9-61)

The `POST /api/courses/[id]/enroll` endpoint creates an enrollment **without requiring payment**. It only checks that the course is published and the user is not already enrolled. There is no payment verification.

```typescript
// Line 40-48: Direct enrollment with no payment check
const [enrollment] = await db
  .insert(enrollments)
  .values({
    userId: user.id,
    courseId: id,
    status: 'active',
  })
  .returning()
```

Meanwhile, the paid flow goes through `POST /api/payments/create-intent` -> Stripe checkout -> webhook -> enrollment. But any authenticated user can simply `POST /api/courses/{id}/enroll` to get free access.

**Impact**: Users bypass payment entirely. Revenue loss from day one.

**Fix**: Either remove this endpoint entirely (let only the Stripe webhook create enrollments), or add a price check (only allow free enrollment if `course.price === 0`).

---

### CRITICAL-3: Default Encryption Secrets in Production Code
**Severity**: P0 - CRYPTOGRAPHIC FAILURE
**Files**:
- `/mnt/e/projects/course/courseflow/lib/session-manager.ts` (line 299-301) - `SESSION_SECRET || 'default-secret-change-in-production'`
- `/mnt/e/projects/course/courseflow/lib/csrf.ts` (line 96) - `CSRF_SECRET || 'default-secret-change-in-production'`
- `/mnt/e/projects/course/courseflow/lib/request-signer.ts` (line 447) - `SIGNING_SECRET || 'default-signing-secret-change-in-production'`

These fallback defaults mean that if env vars are missing in production, all session encryption, CSRF tokens, and request signatures use a publicly known key.

```typescript
// session-manager.ts:299 - Encrypts session cookies with known default
const key = Buffer.from(
  process.env.SESSION_SECRET || 'default-secret-change-in-production',
  'utf8'
).slice(0, 32)
```

**Impact**: An attacker can forge session cookies, CSRF tokens, and signed admin requests if these env vars are not set. The `.env.production` file does NOT include `SESSION_SECRET`, `CSRF_SECRET`, or `SIGNING_SECRET`.

**Fix**: Remove the defaults entirely. Throw a startup error if these env vars are missing in production:
```typescript
if (!process.env.SESSION_SECRET && process.env.NODE_ENV === 'production') {
  throw new Error('SESSION_SECRET must be set in production')
}
```

---

### CRITICAL-4: Stripe Placeholder Key Allows Build with Invalid Credentials
**Severity**: P1 - SECURITY
**File**: `/mnt/e/projects/course/courseflow/lib/stripe.ts` (line 4)

```typescript
const stripeKey = process.env.STRIPE_SECRET_KEY || 'sk_test_placeholder_key_for_build'
```

This fallback means the app can start without a valid Stripe key. If the env var is missing, all payment operations silently fail or throw confusing errors at runtime instead of failing at startup.

**Fix**: In production, throw if `STRIPE_SECRET_KEY` is missing. Only use the placeholder during `next build` (check `process.env.NEXT_PHASE === 'phase-production-build'`).

---

### CRITICAL-5: CSRF Token Not Sent in Frontend API Calls
**Severity**: P1 - CSRF PROTECTION BROKEN
**Files**:
- `/mnt/e/projects/course/courseflow/components/checkout/payment-form.tsx` (lines 105-111)
- `/mnt/e/projects/course/courseflow/app/(auth)/login/page.tsx`
- `/mnt/e/projects/course/courseflow/app/(auth)/register/page.tsx`

The payment form's `fetch` call does not include a CSRF token:

```typescript
const response = await fetch('/api/payments/create-intent', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    // Missing: 'x-csrf-token': csrfToken
  },
  body: JSON.stringify({ courseId }),
})
```

The `createApiHandler` has `csrf: true` for the payment intent endpoint. This means all POST requests to this endpoint will be rejected with 403 "CSRF token not provided in request" unless the client sends the `x-csrf-token` header. The same issue affects the login and registration forms.

**Impact**: In production with CSRF enforcement enabled, checkout, login, and registration will all fail for every user. If CSRF is disabled to work around this, the protection is moot.

**Fix**: Read the `__Host-csrf` cookie and include it in the `x-csrf-token` header for all state-changing requests. The `CSRFClient.getHeaders()` helper already exists in `lib/csrf.ts` (lines 242-245) but is never used in components. Create a shared `useFetch` hook or utility that automatically includes the CSRF token.

---

### CRITICAL-6: Video Delete Endpoint Lacks Authorization Check
**Severity**: P1 - UNAUTHORIZED ACCESS
**File**: `/mnt/e/projects/course/courseflow/app/api/videos/[videoId]/route.ts` (lines 49-53)

```typescript
// Note: In production, you should verify the user owns this video
// by checking the video metadata or your database

await deleteVideo(videoId)
```

Any authenticated user can delete any video by ID. The code even has a comment acknowledging this is incomplete.

**Impact**: A malicious user can delete all course videos, causing content loss for all instructors.

**Fix**: Verify the user is the instructor of the course that owns the video, or require admin role.

---

### CRITICAL-7: `ApiResponse.error()` Method Does Not Exist - Runtime Crash
**Severity**: P1 - RUNTIME ERROR
**Files**:
- `/mnt/e/projects/course/courseflow/app/api/health/route.ts` (line 70): `ApiResponse.error('Service unhealthy', 503, checks)`
- `/mnt/e/projects/course/courseflow/app/api/videos/[videoId]/signed-url/route.ts` (line 83): `ApiResponse.error('Video signing not configured. Contact support.', 503)`

The `ApiResponse` object defined in `/mnt/e/projects/course/courseflow/lib/api-handler.ts` (lines 311-397) provides the following methods: `ok`, `created`, `noContent`, `badRequest`, `unauthorized`, `forbidden`, `notFound`, `conflict`, `tooManyRequests`, `serverError`. There is **no `error()` method**.

Both the health endpoint and the signed-url endpoint call `ApiResponse.error()`, which will throw a `TypeError: ApiResponse.error is not a function` at runtime when those code paths are hit.

**Impact**: The health endpoint returns a 500 error instead of a 503 when the database is unhealthy (defeating the purpose of the health check). The signed-url endpoint crashes instead of returning a graceful 503 when Cloudflare signing keys are not configured.

**Fix**: Either add a generic `error(message, status, data?)` method to `ApiResponse`, or replace the calls with `serverError()` or construct `NextResponse.json()` directly with the appropriate status code.

---

## 4. Warnings (Should Fix Before Launch)

### WARN-1: SQL Injection Risk in `buildSearchCondition` Helper
**Severity**: HIGH
**File**: `/mnt/e/projects/course/courseflow/lib/db/helpers.ts` (lines 146-163)

```typescript
export function buildSearchCondition(
  searchTerm: string,
  columns: string[]
): string {
  const sanitized = searchTerm
    .replace(/[^\w\s]/gi, '')
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .join(' & ')

  if (!sanitized) return ''

  const columnList = columns.join(` || ' ' || `)
  return `to_tsvector('english', ${columnList}) @@ to_tsquery('english', '${sanitized}')`
}
```

This constructs raw SQL with string interpolation. While the `sanitized` search term has special characters stripped via regex, and `column` values come from code (not user input), this is a fragile pattern. The regex `[^\w\s]` does strip most SQL injection characters, but this function is exported and could be used with less careful inputs later. Fortunately, this function does not appear to be called anywhere in the current codebase (the search route uses Drizzle's `ilike` instead).

**Fix**: Delete this unused function, or rewrite it to use parameterized queries via Drizzle's `sql` template tag.

---

### WARN-2: Rate Limiter Fails Open
**Severity**: HIGH
**File**: `/mnt/e/projects/course/courseflow/lib/rate-limit.ts` (line 49)

```typescript
// Fail open - allow request but log error
return { success: true, limit: maxRequests, remaining: maxRequests, reset: resetTime }
```

If Redis is unreachable, all rate limits are bypassed. This means if Upstash goes down (or credentials are wrong), brute-force attacks on auth endpoints are unimpeded.

**Fix**: Consider fail-closed for critical endpoints (auth, payment). At minimum, fall back to the in-memory limiter rather than disabling limits entirely.

---

### WARN-3: In-Memory CSRF Token Store Does Not Work Across Serverless Instances
**Severity**: HIGH
**File**: `/mnt/e/projects/course/courseflow/lib/csrf-protection.ts` (line 36)

```typescript
private tokens: Map<string, { userId: string; timestamp: number }> = new Map()
```

The `CSRFProtection` class stores tokens in an in-memory `Map`. In a serverless environment (Vercel), each request may hit a different instance. Tokens generated on one instance will not be found on another, causing CSRF validation to fail intermittently.

Note: The simpler CSRF implementation in `lib/csrf.ts` (used by the `createApiHandler`) uses the double-submit cookie pattern which IS stateless and works correctly across instances. The `csrf-protection.ts` module appears to be an older, unused implementation.

**Fix**: Remove `lib/csrf-protection.ts` entirely to avoid confusion. Ensure only the stateless double-submit cookie pattern from `lib/csrf.ts` is active.

---

### WARN-4: Session Fingerprinting Will Break on CDNs/Proxies
**Severity**: MEDIUM
**File**: `/mnt/e/projects/course/courseflow/lib/session-manager.ts` (lines 119-139)

Session fingerprinting hashes `x-forwarded-for` + `user-agent`. If a user is behind a CDN or corporate proxy that rotates IPs, their sessions will be destroyed as "session hijacking" false positives.

**Fix**: Consider making fingerprinting configurable or using a more stable fingerprint (user-agent only, or drop fingerprinting in favor of Supabase's built-in session management).

---

### WARN-5: No Refund Handling - Access Not Revoked on Stripe Refunds
**Severity**: MEDIUM (Financial)
**File**: `/mnt/e/projects/course/courseflow/app/api/webhooks/stripe/route.ts`

The webhook only handles `payment_intent.succeeded` and `payment_intent.payment_failed`. It does not handle:
- `charge.refunded` - No access revocation on refund
- `charge.dispute.created` - No action on chargebacks
- `customer.subscription.deleted` - Not relevant yet but will be if subscriptions are added

**Impact**: If you refund a customer through the Stripe dashboard, they retain full course access forever.

**Fix**: Add `charge.refunded` webhook handler that updates the enrollment status to `cancelled`.

---

### WARN-6: Course Deletion Does Not Handle Active Enrollments
**Severity**: MEDIUM
**File**: `/mnt/e/projects/course/courseflow/app/api/courses/[id]/route.ts` (lines 160-161)

```typescript
await db.delete(courses).where(eq(courses.id, id))
```

Deleting a course with active enrollments means paying customers lose access with no refund. The `enrollments` table has a FK to `courses` but does NOT have `onDelete: 'cascade'`, so this may fail with a FK constraint error, or if it succeeds, leave orphaned enrollment records.

**Fix**: Check for active enrollments before deletion. If enrolled students exist, either prevent deletion or archive the course instead.

---

### WARN-7: CSP Allows `'unsafe-inline'` for Scripts
**Severity**: MEDIUM
**File**: `/mnt/e/projects/course/courseflow/lib/security-headers.ts` (line 32)

```typescript
`script-src 'self' 'unsafe-inline' ${isDevelopment ? "'unsafe-eval'" : ''} https://*.stripe.com`
```

`'unsafe-inline'` in production defeats much of the XSS protection that CSP provides. While this may be necessary for Next.js's inline scripts, consider using nonces or hashes instead.

---

### WARN-8: Missing `requireRole` on Course PATCH Endpoint
**Severity**: MEDIUM
**File**: `/mnt/e/projects/course/courseflow/app/api/courses/[id]/route.ts` (lines 128-141)

The PATCH endpoint uses `requireAuth: true` but not `requireRole`. While it does have an inline authorization check (`if (existingCourse.instructorId !== user.id && user.role !== 'admin')`), this means a student user hits the database to fetch the course before being rejected. Using `requireRole: ['instructor', 'admin']` would be more efficient and consistent with the POST endpoint.

---

### WARN-9: Broken Template Literal in Course Detail Page
**Severity**: MEDIUM (UX Bug)
**File**: `/mnt/e/projects/course/courseflow/app/(public)/courses/[id]/page.tsx` (line 122)

```tsx
<Link href="/login?redirect=/courses/${params.id}">
```

This uses regular quotes (`"`) instead of backticks, so the redirect URL will literally be `/courses/${params.id}` instead of the actual course ID. Users who click "Sign in to Enroll" will be redirected to a non-existent page after login.

**Fix**: Change to backtick template literal:
```tsx
<Link href={`/login?redirect=/courses/${params.id}`}>
```

---

### WARN-10: Checkout Page Does Not Validate `params.id` as UUID
**Severity**: LOW-MEDIUM
**File**: `/mnt/e/projects/course/courseflow/app/(public)/courses/[id]/checkout/page.tsx` (line 51)

```typescript
const course = await getCourse(params.id)
```

The `params.id` is passed directly to a database query without UUID validation. While Drizzle/PostgreSQL will reject invalid UUIDs, this could cause noisy errors in logs.

---

## 5. Minor Issues (Nice to Fix)

### MINOR-1: Duplicate CSRF Module Implementations
**Files**: `/mnt/e/projects/course/courseflow/lib/csrf.ts` AND `/mnt/e/projects/course/courseflow/lib/csrf-protection.ts`

Two separate CSRF implementations exist. `csrf.ts` is the one used by `createApiHandler` (double-submit cookie pattern, stateless). `csrf-protection.ts` is a stateful in-memory implementation (312 lines). Having both creates confusion and maintenance burden.

**Fix**: Remove `csrf-protection.ts` and consolidate on `csrf.ts`.

---

### MINOR-2: `request.user` Type Safety via `any` Cast
**File**: `/mnt/e/projects/course/courseflow/lib/api-handler.ts` (lines 194-197)

```typescript
;(request as any).user = user
;(request as any).validatedBody = sanitizedBody
```

Attaching properties via `any` cast loses type safety. While the `getUser()` and `getValidatedBody()` helpers exist, the `request.user` pattern at `/mnt/e/projects/course/courseflow/app/api/courses/[id]/route.ts` (line 36) accesses it directly without these helpers.

---

### MINOR-3: Email Templates Include Unsanitized User Data
**File**: `/mnt/e/projects/course/courseflow/lib/email.ts` (lines 72, 157)

```html
<p>Hi ${data.userName},</p>
...
${data.errorMessage ? `<div class="alert-box"><strong>Error:</strong> ${data.errorMessage}</div>` : ''}
```

`userName` (derived from email prefix) and `errorMessage` (from Stripe) are interpolated directly into HTML email templates without escaping. While email clients generally sanitize HTML, this is still XSS-adjacent and could be exploited in some email clients.

**Fix**: HTML-escape all interpolated values in email templates.

---

### MINOR-4: `setInterval` Side Effects in Module Scope
**Files**:
- `/mnt/e/projects/course/courseflow/lib/csrf-protection.ts` (line 41)
- `/mnt/e/projects/course/courseflow/lib/rate-limit.ts` (line 62)
- `/mnt/e/projects/course/courseflow/lib/request-signer.ts` (line 31)

Multiple modules create `setInterval` timers at module load time. In serverless environments, these timers may prevent cold-start cleanup and will not persist between invocations anyway.

---

### MINOR-5: `__tests__` Inside `app/api/` Directory
**Files**: `app/api/auth/__tests__/`, `app/api/courses/__tests__/`, `app/api/payments/__tests__/`, `app/api/webhooks/__tests__/`

Test files inside the `app` directory may be picked up by Next.js routing. Move them to the top-level `__tests__` directory or configure `pageExtensions` in `next.config.js` to exclude test files.

---

### MINOR-6: Lesson Content Rendering
**File**: `/mnt/e/projects/course/courseflow/app/(learning)/courses/[courseId]/lessons/[lessonId]/page.tsx` (lines 195-198)

```tsx
<p className="text-muted-foreground whitespace-pre-wrap">
  {currentLesson.content}
</p>
```

Lesson content is rendered as text content (not `dangerouslySetInnerHTML`), so this is safe from XSS. However, if the rich HTML content feature is used, this won't render formatting. This is a UX issue, not a security one.

---

### MINOR-7: Hardcoded Webhook Placeholder
**File**: `/mnt/e/projects/course/courseflow/.env.production` (line 28)

```
STRIPE_WEBHOOK_SECRET=whsec_placeholder_will_set_after_deployment
```

The webhook secret is a placeholder. If deployed without updating, webhook signature verification will fail (safe, but webhooks won't work -- meaning no enrollment after payment).

---

### MINOR-8: Course Detail Page Fetches Its Own API via HTTP
**File**: `/mnt/e/projects/course/courseflow/app/(public)/courses/[id]/page.tsx`

The server component fetches data from its own `/api/courses/[id]` endpoint via HTTP rather than calling the database directly. This adds unnecessary network overhead and latency for server-rendered pages. In Next.js App Router, server components should query the database directly or use shared data-fetching functions.

---

## 6. Positive Findings

### POSITIVE-1: Excellent `createApiHandler` Pattern
**File**: `/mnt/e/projects/course/courseflow/lib/api-handler.ts`

The centralized API handler provides consistent security across all endpoints:
- Automatic rate limiting with configurable tiers
- CSRF protection for state-changing methods
- Role-based authentication
- Zod schema validation
- Input sanitization with configurable levels (strict, basic, rich)
- Structured logging with duration tracking
- Centralized error handling

This is genuinely well-designed and eliminates an entire class of "forgot to add auth" bugs.

### POSITIVE-2: Idempotent Stripe Webhook Processing
**File**: `/mnt/e/projects/course/courseflow/app/api/webhooks/stripe/route.ts` (lines 89-110)

```typescript
.onConflictDoNothing({
  target: [enrollments.userId, enrollments.courseId]
})
```

The webhook handler correctly uses `onConflictDoNothing` with the unique constraint, making it safe for Stripe webhook retries. It also skips XP awards and emails on duplicates.

### POSITIVE-3: Proper Stripe Webhook Signature Verification
**File**: `/mnt/e/projects/course/courseflow/app/api/webhooks/stripe/route.ts` (lines 58-70)

Uses `stripe.webhooks.constructEvent()` with the raw body and signature header. This is the correct, secure implementation.

### POSITIVE-4: Server-Side Price Enforcement
**File**: `/mnt/e/projects/course/courseflow/app/api/payments/create-intent/route.ts` (line 73)

```typescript
amount: course.price,  // Price from database, not from client
```

The payment amount is read from the database, not from the client request. This prevents price manipulation attacks.

### POSITIVE-5: Comprehensive XSS Sanitization
**File**: `/mnt/e/projects/course/courseflow/lib/sanitize.ts`

DOMPurify with three configurable levels (strict, basic, rich) and URL sanitization. Applied consistently in `createApiHandler` via the `sanitize` option.

### POSITIVE-6: Proper Security Headers
**File**: `/mnt/e/projects/course/courseflow/lib/security-headers.ts`

Includes CSP, HSTS, X-Frame-Options DENY, X-Content-Type-Options nosniff, Referrer-Policy, and Permissions-Policy. Applied via middleware to all routes.

### POSITIVE-7: Database Schema Design
**File**: `/mnt/e/projects/course/courseflow/lib/db/schema.ts`

- Unique constraint on `(userId, courseId)` in enrollments prevents duplicates
- Proper indexes for common query patterns
- UUID primary keys
- Cascade deletes on lessons when courses are deleted
- Enum types for status fields

### POSITIVE-8: Admin Role Change Protection
**File**: `/mnt/e/projects/course/courseflow/app/api/admin/users/role/route.ts`

- Requires admin role
- Requires signed request (HMAC)
- Prevents self-role-change
- Prevents removing the last admin
- Full audit logging

### POSITIVE-9: Signed Video URLs
**File**: `/mnt/e/projects/course/courseflow/lib/cloudflare.ts` (lines 191-254)

Video playback requires signed tokens with expiration. The signing implementation uses proper RSA-SHA256 JWT tokens via Web Crypto API.

### POSITIVE-10: Enrollment Check Before Video Access
**File**: `/mnt/e/projects/course/courseflow/app/api/videos/[videoId]/signed-url/route.ts` (lines 29-53)

The signed URL endpoint verifies enrollment via a JOIN query before generating a playback token. Non-enrolled users cannot access video content.

---

## 7. Architecture Assessment

**Overall Architecture**: Well-structured Next.js App Router application with clear separation of concerns. The `lib/` directory provides shared utilities (auth, db, stripe, security), the `app/api/` directory handles REST endpoints, and the `app/(public)/`, `app/(auth)/`, `app/(learning)/`, `app/(dashboard)/` route groups organize pages by access level.

**Database Layer**: Drizzle ORM is used consistently with parameterized queries (with the exception of the unused `buildSearchCondition` helper). Schema design is solid with proper constraints, indexes, and relationships.

**Authentication**: Supabase SSR auth with JWT-based sessions. Middleware handles session refresh and route protection. The `requireAuth` and `requireRole` options in `createApiHandler` provide consistent enforcement.

**Payment Flow**: Well-implemented Stripe integration with server-side price enforcement, webhook signature verification, and idempotent enrollment processing. The main gap is the free enrollment bypass (CRITICAL-2) and missing refund handling (WARN-5).

**Security Layers**: Multiple defense layers (CSRF, rate limiting, input sanitization, security headers, audit logging). The `createApiHandler` pattern ensures these are applied consistently. However, the CSRF layer is broken because the frontend never sends the token (CRITICAL-5).

**Scalability Concerns**: The in-memory fallbacks for rate limiting and CSRF (in the unused module) won't work across serverless instances. The `setInterval` timers in module scope are incompatible with serverless cold starts.

---

## 8. Payment Flow Review

### Payment Flow (Happy Path):
1. User clicks "Enroll" on course page
2. `POST /api/payments/create-intent` creates Stripe PaymentIntent with server-side price
3. Stripe Elements collects card info (PCI-compliant, card data never touches our server)
4. Stripe processes payment
5. Stripe sends `payment_intent.succeeded` webhook
6. Webhook handler verifies signature, creates enrollment with `onConflictDoNothing`
7. Sends confirmation email via Resend

### Payment Flow Issues:
- **CRITICAL**: Free enrollment bypass via `POST /api/courses/[id]/enroll` (CRITICAL-2)
- **CRITICAL**: CSRF token not included in payment form fetch (CRITICAL-5) -- will cause 403 errors
- **WARNING**: No refund/dispute handling (WARN-5) -- refunded users keep access
- **WARNING**: Placeholder webhook secret in `.env.production` (MINOR-7) -- webhooks won't work until updated
- **POSITIVE**: Server-side price enforcement prevents manipulation
- **POSITIVE**: Idempotent webhook processing handles retries correctly
- **POSITIVE**: Proper signature verification on webhooks

---

## 9. Summary of Issues by Priority

| Priority | Count | Category |
|----------|-------|----------|
| P0 - Emergency | 3 | Exposed credentials, free enrollment bypass, default crypto secrets |
| P1 - Critical | 4 | Stripe placeholder, broken CSRF in frontend, video delete authz, ApiResponse.error() crash |
| P2 - Warning | 10 | SQL injection helper, rate limit fail-open, no refund handling, broken template literal, etc. |
| P3 - Minor | 8 | Duplicate modules, type safety, email escaping, test file location, etc. |

**Total issues found**: 25

---

## 10. Recommendations for Launch

### Before Processing Any Real Money:
1. **Rotate all exposed credentials immediately** (CRITICAL-1)
2. **Remove or gate the free enrollment endpoint** (CRITICAL-2)
3. **Add required env var checks for crypto secrets** (CRITICAL-3)
4. **Fix Stripe placeholder to only apply during build** (CRITICAL-4)
5. **Fix CSRF token propagation to frontend** (CRITICAL-5)
6. **Add authorization to video delete** (CRITICAL-6)
7. **Add `ApiResponse.error()` method or fix call sites** (CRITICAL-7)
8. **Fix broken template literal in course detail page** (WARN-9)

### Before Scaling:
1. Fix rate limiter fail-open behavior (WARN-2)
2. Remove unused CSRF module (WARN-3 / MINOR-1)
3. Add `charge.refunded` and `charge.dispute.created` webhook handlers (WARN-5)
4. Consider nonce-based CSP instead of `unsafe-inline` (WARN-7)
5. Delete unused `buildSearchCondition` function (WARN-1)

### Testing Gaps:
- No end-to-end payment flow test with real Stripe test mode
- No test for enrollment-without-payment bypass
- No test for CSRF enforcement in frontend
- No test for video authorization
- No test for `ApiResponse.error()` call sites (would have caught CRITICAL-7)

---

## 11. Overall Assessment

CourseFlow demonstrates strong engineering fundamentals -- the `createApiHandler` pattern, proper Stripe webhook implementation, comprehensive security headers, and well-designed database schema show a team that understands production concerns. The codebase is clean, well-organized, and uses TypeScript effectively.

However, the platform is **not ready to process real money** in its current state. The free enrollment bypass (CRITICAL-2) is a direct revenue loss vector. The broken CSRF propagation (CRITICAL-5) means checkout, login, and registration forms will all fail in production. The `ApiResponse.error()` crash (CRITICAL-7) means the health check and video signing error paths are broken. These issues suggest insufficient end-to-end testing of the actual user flows.

The good news is that the architecture is sound and these issues are fixable. With 2-3 days of focused work on the critical issues and a proper end-to-end test suite, this platform could be production-ready.

**Estimated time to fix critical issues**: 2-3 days
**Estimated time to fix all warnings**: 1-2 additional weeks
**Recommended before first sale**: Fix all P0 and P1 issues, add end-to-end payment flow test

---

*Review conducted on 2026-02-11. All file paths are absolute. Line numbers reference the current state of the codebase.*
