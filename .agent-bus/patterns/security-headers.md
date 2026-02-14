# Pattern: Security Headers (Next.js + FastAPI)

## Problem It Solves
Missing security headers expose applications to clickjacking, XSS, MIME sniffing, protocol downgrade, and information leakage attacks. Every HTTP response should include a standard set of security headers.

## Source Projects
- **Quant** (B+) -- `/mnt/e/projects/quant/quant/backend/app/middleware/security_headers.py` (FastAPI)
- **Credit** (B+) -- `/mnt/e/projects/credit/middleware.ts` (Next.js Edge Middleware)
- **Course Platform** (B-) -- `/mnt/e/projects/course/courseflow/lib/security-headers.ts` (Next.js)

## When to Use
- **Every project that serves HTTP responses.** There is no reason to skip this.

---

## Next.js Pattern (Edge Middleware)

### `middleware.ts`
```typescript
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // === Security Headers (always apply) ===
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('X-XSS-Protection', '1; mode=block');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=(), interest-cohort=()'
  );

  // === Content Security Policy ===
  const isDev = process.env.NODE_ENV === 'development';
  const csp = [
    "default-src 'self'",
    `script-src 'self' ${isDev ? "'unsafe-eval'" : ''} https://www.googletagmanager.com`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https: blob:",
    "font-src 'self' data:",
    "connect-src 'self' https://www.google-analytics.com",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    isDev ? '' : 'upgrade-insecure-requests',
  ].filter(Boolean).join('; ');

  response.headers.set('Content-Security-Policy', csp);

  // === HSTS (production only) ===
  if (!isDev) {
    response.headers.set(
      'Strict-Transport-Security',
      'max-age=31536000; includeSubDomains; preload'
    );
  }

  // === CORS (for API routes only) ===
  if (request.nextUrl.pathname.startsWith('/api')) {
    const origin = request.headers.get('origin');
    const allowedOrigins = (process.env.ALLOWED_ORIGINS || '').split(',').filter(Boolean);

    if (allowedOrigins.length > 0 && origin && allowedOrigins.includes(origin)) {
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Access-Control-Allow-Credentials', 'true');
    }
    // No wildcard CORS in production -- if origin not in list, no CORS headers = blocked

    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    response.headers.set('Access-Control-Max-Age', '86400');

    // API-specific cache prevention
    response.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate');
  }

  // === Request ID for tracing ===
  response.headers.set('x-request-id', crypto.randomUUID());

  return response;
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)',
  ],
};
```

---

## FastAPI / Python Pattern (Starlette Middleware)

### `app/middleware/security_headers.py`
```python
"""Security headers middleware for FastAPI."""
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import os

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add OWASP security headers to all responses."""

    def __init__(self, app):
        super().__init__(app)
        self.is_production = os.getenv("ENVIRONMENT", "development") == "production"
        self.csp_policy = self._build_csp()

    def _build_csp(self) -> str:
        policies = [
            "default-src 'self'",
            "script-src 'self'",
            "style-src 'self' 'unsafe-inline'",
            "img-src 'self' data: https:",
            "font-src 'self' data:",
            "connect-src 'self'",
            "frame-src 'none'",
            "object-src 'none'",
            "base-uri 'self'",
            "form-action 'self'",
            "frame-ancestors 'none'",
        ]
        if self.is_production:
            policies.append("upgrade-insecure-requests")
        return "; ".join(policies)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)

        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=(), "
            "interest-cohort=(), payment=(), usb=()"
        )
        response.headers["Content-Security-Policy"] = self.csp_policy

        if self.is_production:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains; preload"
            )

        return response
```

### Register in FastAPI app:
```python
from app.middleware.security_headers import SecurityHeadersMiddleware

app = FastAPI()
app.add_middleware(SecurityHeadersMiddleware)
```

---

## Complete Header Reference

| Header | Value | Prevents |
|--------|-------|----------|
| `X-Frame-Options` | `DENY` | Clickjacking |
| `X-Content-Type-Options` | `nosniff` | MIME confusion attacks |
| `X-XSS-Protection` | `1; mode=block` | Reflected XSS (older browsers) |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Referrer leakage |
| `Permissions-Policy` | `camera=(), microphone=()...` | Unwanted feature access |
| `Content-Security-Policy` | (see above) | XSS, injection, data exfil |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | Protocol downgrade |

## Key Design Decisions
1. **CSP varies by environment** -- `unsafe-eval` only in development (for HMR)
2. **HSTS only in production** -- prevents localhost issues during development
3. **No wildcard CORS** -- explicit allowlist of origins in production
4. **API routes get no-cache headers** -- prevents sensitive data caching

## Projects That Need This Pattern
- **Sports** (D) -- wildcard CORS, no security headers at all
- **Calc** (C+) -- missing most security headers
- **Back** (C) -- no security headers
- **Affiliate** (B-) -- partial headers only
- **Acquisition System** (B-) -- no security headers on API
- **Discovery** (C+) -- no security headers
- **Pod** (C-) -- no security headers
- **OYKH** (C) -- no security headers
- **Toonz** (C+) -- no security headers
