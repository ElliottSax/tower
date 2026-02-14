# Pattern: API Key Authentication for Admin Endpoints

## Problem It Solves
Admin/monitoring endpoints expose sensitive data (system metrics, analytics, business data) without authentication. Need lightweight auth for internal tools without full user auth system.

## Source Project
**Calc** (C+ → B) -- `/mnt/e/projects/calc/lib/auth-admin.ts`

## When to Use
- Monitoring/metrics endpoints that expose system internals
- Admin dashboards without user auth
- Internal API endpoints (not for end users)
- Serverless environments where API keys are simpler than sessions
- Projects without NextAuth/Supabase Auth yet

## When NOT to Use
- Public endpoints (use OAuth/NextAuth)
- Multi-user systems with roles (use NextAuth + RBAC)
- Endpoints requiring per-user permissions (use session-based auth)

## Dependencies
```bash
# None! Pure Next.js/TypeScript
# Already have: next, typescript
```

## Code Template

### `lib/auth-admin.ts` -- Admin authentication utilities

```typescript
import { NextRequest, NextResponse } from 'next/server'

const ADMIN_API_KEY = process.env.ADMIN_API_KEY

export function isAdminAuthConfigured(): boolean {
  return !!ADMIN_API_KEY && ADMIN_API_KEY.length >= 32
}

export function isAdminAuthenticated(request: NextRequest): boolean {
  if (!ADMIN_API_KEY) {
    console.error('ADMIN_API_KEY not configured in environment')
    return false
  }

  const authHeader = request.headers.get('authorization')
  const apiKeyHeader = request.headers.get('x-api-key')
  const providedKey = authHeader?.replace(/^Bearer\s+/i, '') || apiKeyHeader

  if (!providedKey) return false

  // Constant-time comparison to prevent timing attacks
  return timingSafeEqual(providedKey, ADMIN_API_KEY)
}

export function requireAdminAuth(request: NextRequest): NextResponse | null {
  if (!isAdminAuthConfigured()) {
    return NextResponse.json(
      {
        error: 'Admin authentication not configured',
        message: 'ADMIN_API_KEY environment variable must be set',
      },
      { status: 500 }
    )
  }

  if (!isAdminAuthenticated(request)) {
    return NextResponse.json(
      {
        error: 'Unauthorized',
        message: 'Valid API key required. Provide via Authorization: Bearer <key> or X-API-Key: <key> header',
      },
      {
        status: 401,
        headers: { 'WWW-Authenticate': 'Bearer realm="Admin API"' },
      }
    )
  }

  return null
}

function timingSafeEqual(a: string, b: string): boolean {
  const aLen = a.length
  const bLen = b.length
  const maxLen = Math.max(aLen, bLen)
  let result = aLen === bLen ? 0 : 1

  for (let i = 0; i < maxLen; i++) {
    const aChar = i < aLen ? a.charCodeAt(i) : 0
    const bChar = i < bLen ? b.charCodeAt(i) : 0
    result |= aChar ^ bChar
  }

  return result === 0
}

// Optional: IP allowlist for additional security
export function isIpAllowed(request: NextRequest): boolean {
  const allowedIps = process.env.ADMIN_ALLOWED_IPS?.split(',').map(ip => ip.trim())
  if (!allowedIps || allowedIps.length === 0) return true

  const forwarded = request.headers.get('x-forwarded-for')
  const clientIp = forwarded ? forwarded.split(',')[0].trim() : request.headers.get('x-real-ip') || 'unknown'

  return allowedIps.includes(clientIp)
}

export function requireAdminAuthWithIp(request: NextRequest): NextResponse | null {
  if (!isIpAllowed(request)) {
    return NextResponse.json(
      { error: 'Forbidden', message: 'Access denied from your IP address' },
      { status: 403 }
    )
  }
  return requireAdminAuth(request)
}
```

### Usage in API Routes

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireAdminAuth } from '@/lib/auth-admin'

// Admin-only endpoint
export async function GET(request: NextRequest) {
  const authError = requireAdminAuth(request)
  if (authError) return authError

  // Your protected logic here
  return NextResponse.json({
    systemMetrics: {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      // ... sensitive data
    }
  })
}
```

### Environment Setup

`.env.example`:
```bash
# Generate with: openssl rand -hex 32
ADMIN_API_KEY=your-64-char-hex-key-here

# Optional: IP allowlist (comma-separated)
ADMIN_ALLOWED_IPS=203.0.113.42,198.51.100.10
```

Generate key:
```bash
openssl rand -hex 32
```

### Client Usage Examples

**curl**:
```bash
# Option 1: Bearer token
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.example.com/admin/metrics

# Option 2: X-API-Key header
curl -H "X-API-Key: YOUR_API_KEY" \
  https://api.example.com/admin/metrics
```

**JavaScript/TypeScript**:
```typescript
const response = await fetch('/api/admin/metrics', {
  headers: {
    'Authorization': `Bearer ${process.env.ADMIN_API_KEY}`
  }
})
```

**Python**:
```python
import os
import requests

headers = {'Authorization': f'Bearer {os.getenv("ADMIN_API_KEY")}'}
response = requests.get('https://api.example.com/admin/metrics', headers=headers)
```

## Key Design Decisions

1. **Timing-safe comparison** -- Prevents timing attacks on API key comparison
2. **Multiple header formats** -- Supports both `Authorization: Bearer` and `X-API-Key`
3. **Environment-based config** -- Keys stored in env vars, never in code
4. **Optional IP allowlist** -- Add second layer of security when needed
5. **Clear error messages** -- 401 with instructions on how to authenticate
6. **No external dependencies** -- Pure TypeScript, works in Edge runtime

## Security Considerations

### ✅ DO
- Generate keys with `openssl rand -hex 32` (256-bit)
- Store keys in environment variables
- Use HTTPS only (never HTTP)
- Rotate keys every 90 days
- Monitor 401 errors for attack attempts
- Use different keys per environment (dev/staging/prod)

### ❌ DON'T
- Hard-code keys in source code
- Share keys in public repos
- Use short/weak keys (<32 chars)
- Send keys in URL query params
- Reuse keys across projects
- Log API keys (even partially)

## Testing

```bash
# Test unauthorized access (should fail)
curl https://api.example.com/admin/metrics
# Expected: 401 Unauthorized

# Test authorized access (should succeed)
curl -H "Authorization: Bearer YOUR_KEY" \
  https://api.example.com/admin/metrics
# Expected: 200 OK with data
```

## Complementary Patterns

Use together with:
- **Rate Limiting** (`rate-limit.ts`) -- Prevent brute force attacks
- **Security Headers** (`security-headers.md`) -- Defense in depth
- **Logging** (`logger.ts`) -- Audit trail of admin access

## Upgrade Path

For projects that outgrow simple API keys:

1. **NextAuth** (`auth-nextjs.md`) -- Full user authentication
2. **Role-Based Access Control** -- Different admin permission levels
3. **API Key Rotation** -- Automated key rotation with grace periods
4. **2FA** -- Two-factor authentication for admin users
5. **OAuth** -- Integrate with Google/GitHub for admin login

## Projects That Need This Pattern

- **Sports** (D) -- Zero auth on admin endpoints
- **Acquisition System** (B-) -- 20+ endpoints, zero auth
- **Back** (C) -- Admin dashboard exposed
- **Affiliate/TheStackGuide** (B-) -- Admin panel publicly accessible
- **Discovery** (C+) -- Premium features not enforced
- **Pod** (C-) -- Internal APIs exposed
- **OYKH** (C) -- Admin routes not protected

## Real-World Example

From Calc project - protecting monitoring endpoints:

**Before** (CRIT-5 vulnerability):
```typescript
export async function GET(request: Request) {
  return NextResponse.json({
    health: getSystemHealth(), // 🚨 Exposed to anyone!
    memoryUsage: process.memoryUsage().heapUsed,
    cpuUsage: process.cpuUsage().user,
  })
}
```

**After** (secured):
```typescript
export async function GET(request: NextRequest) {
  const authError = requireAdminAuth(request)
  if (authError) return authError // ✅ Protected!

  return NextResponse.json({
    health: getSystemHealth(),
    memoryUsage: process.memoryUsage().heapUsed,
    cpuUsage: process.cpuUsage().user,
  })
}
```

## Performance

- **Auth check**: < 1ms (constant-time comparison)
- **Memory overhead**: Negligible (just env var read)
- **Network overhead**: +1 header (~50 bytes)
- **Works in Edge runtime**: Yes (no Node.js APIs)

## References

- OWASP API Security Top 10: https://owasp.org/www-project-api-security/
- RFC 6750 (Bearer Token): https://tools.ietf.org/html/rfc6750
- Timing Attack Prevention: https://codahale.com/a-lesson-in-timing-attacks/

---

**Pattern Grade**: A-
**Complexity**: Low
**Setup Time**: 5 minutes
**Maintenance**: Low (rotate keys quarterly)
