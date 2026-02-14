# Pattern: Rate Limiting (Next.js + FastAPI)

## Problem It Solves
Prevents API abuse, brute-force attacks, and resource exhaustion by limiting requests per client. Without rate limiting, a single user or bot can take down your entire service.

## Source Projects
- **Credit** (B+) -- `/mnt/e/projects/credit/lib/middleware/rateLimit.ts` (Upstash/Next.js)
- **Course Platform** (B-) -- `/mnt/e/projects/course/courseflow/lib/rate-limit.ts` (Redis + in-memory fallback)

## When to Use
- Any API that faces the public internet
- Authentication endpoints (prevent brute-force)
- Payment endpoints (prevent fraud)
- Search/AI endpoints (prevent cost runaway)

---

## Next.js Pattern (Upstash Redis)

### Dependencies
```bash
npm install @upstash/ratelimit @upstash/redis
```

### `lib/middleware/rateLimit.ts`
```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';
import { NextRequest, NextResponse } from 'next/server';

// Initialize Redis client (null if not configured)
const redis = process.env.UPSTASH_REDIS_REST_URL
  ? new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL,
      token: process.env.UPSTASH_REDIS_REST_TOKEN!,
    })
  : null;

// Different rate limits for different endpoint types
const rateLimiters = {
  api: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(60, '1 m'),  // 60 req/min
        analytics: true,
        prefix: '@myapp/ratelimit/api',
      })
    : null,
  auth: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(5, '15 m'),  // 5 attempts/15min
        analytics: true,
        prefix: '@myapp/ratelimit/auth',
      })
    : null,
  payment: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(10, '1 h'),  // 10/hour
        analytics: true,
        prefix: '@myapp/ratelimit/payment',
      })
    : null,
};

function getClientIP(request: NextRequest): string {
  return (
    request.headers.get('cf-connecting-ip') ||       // Cloudflare
    request.headers.get('x-forwarded-for')?.split(',')[0] ||
    request.headers.get('x-real-ip') ||
    'unknown'
  );
}

export async function rateLimitMiddleware(
  request: NextRequest,
  type: keyof typeof rateLimiters = 'api'
): Promise<NextResponse | null> {
  const limiter = rateLimiters[type];

  // Fail open in dev (no Redis = no rate limiting)
  if (!limiter) return null;

  const identifier = getClientIP(request);

  try {
    const { success, limit, reset, remaining } = await limiter.limit(identifier);

    if (!success) {
      return NextResponse.json(
        { error: 'Too many requests', retryAfter: Math.ceil((reset - Date.now()) / 1000) },
        {
          status: 429,
          headers: {
            'X-RateLimit-Limit': limit.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': new Date(reset).toISOString(),
            'Retry-After': Math.ceil((reset - Date.now()) / 1000).toString(),
          },
        }
      );
    }

    return null; // Request allowed
  } catch (error) {
    console.error('[Rate Limit] Error:', error);
    return null; // Fail open
  }
}

// Higher-order function wrapper for route handlers
export function withRateLimit(
  handler: (req: NextRequest) => Promise<NextResponse>,
  type: keyof typeof rateLimiters = 'api'
) {
  return async (req: NextRequest) => {
    const blocked = await rateLimitMiddleware(req, type);
    if (blocked) return blocked;
    return handler(req);
  };
}
```

---

## FastAPI / Python Pattern (In-Memory + Redis)

### Dependencies
```bash
pip install redis aioredis
```

### `app/middleware/rate_limit.py`
```python
"""Rate limiting middleware for FastAPI."""
import time
from collections import defaultdict
from typing import Optional, Callable
from fastapi import Request, Response, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

class InMemoryRateLimiter:
    """Simple in-memory rate limiter for single-process deployments."""

    def __init__(self):
        self._requests: dict[str, list[float]] = defaultdict(list)

    def is_allowed(self, key: str, max_requests: int, window_seconds: int) -> bool:
        now = time.time()
        cutoff = now - window_seconds

        # Clean old entries
        self._requests[key] = [t for t in self._requests[key] if t > cutoff]

        if len(self._requests[key]) >= max_requests:
            return False

        self._requests[key].append(now)
        return True


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limiting middleware for FastAPI."""

    LIMITS = {
        "/api/auth": (5, 900),       # 5 per 15 min
        "/api/payment": (10, 3600),  # 10 per hour
        "/api/": (100, 60),          # 100 per min (default)
    }

    def __init__(self, app):
        super().__init__(app)
        self.limiter = InMemoryRateLimiter()

    def _get_client_ip(self, request: Request) -> str:
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return request.client.host if request.client else "unknown"

    def _get_limit(self, path: str) -> tuple[int, int]:
        for prefix, limit in self.LIMITS.items():
            if path.startswith(prefix):
                return limit
        return (100, 60)  # default

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        client_ip = self._get_client_ip(request)
        max_requests, window = self._get_limit(request.url.path)
        key = f"{client_ip}:{request.url.path}"

        if not self.limiter.is_allowed(key, max_requests, window):
            raise HTTPException(
                status_code=429,
                detail="Too many requests. Please try again later.",
                headers={"Retry-After": str(window)},
            )

        response = await call_next(request)
        return response
```

### Register in FastAPI app:
```python
from app.middleware.rate_limit import RateLimitMiddleware

app = FastAPI()
app.add_middleware(RateLimitMiddleware)
```

## Key Design Decisions
1. **Fail open** -- if Redis is down, allow requests (don't break the app)
2. **Sliding window** -- smoother than fixed window, prevents burst at window edges
3. **Per-endpoint limits** -- auth endpoints need much stricter limits than read endpoints
4. **IP-based identification** -- supports Cloudflare, X-Forwarded-For, X-Real-IP
5. **Standard headers** -- always return X-RateLimit-Limit/Remaining/Reset for client visibility

## Projects That Need This Pattern
- **Sports** (D) -- zero rate limiting, wildcard CORS
- **Calc** (C+) -- monitoring endpoints fully exposed
- **Affiliate** (B-) -- no rate limiting on any endpoint
- **Back** (C) -- no rate limiting
- **Acquisition System** (B-) -- all 20+ endpoints unprotected
- **Discovery** (C+) -- no rate limiting
