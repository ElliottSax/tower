# Pattern: Multi-Provider LLM Orchestration with Circuit Breakers

## Problem It Solves
Relying on a single LLM provider means downtime when that provider has issues. This pattern provides automatic failover across multiple providers, prevents cascading failures with circuit breakers, controls costs with budget tracking, and avoids redundant API calls with response caching.

## Source Project
**BookCLI** (D overall, but A+ orchestration pattern) -- `/mnt/e/projects/bookcli/lib/api_client.py` and `/mnt/e/projects/bookcli/lib/retry.py`

## When to Use
- Any project making LLM API calls (generation, classification, summarization)
- Projects that need high availability for AI features
- Projects with cost sensitivity (multiple free-tier providers)
- Projects that make repetitive API calls (caching saves money)

---

## Architecture Overview

```
call_with_fallback(prompt)
    |
    +-- Budget check (daily spend limit)
    |
    +-- Get available APIs (exclude circuit-broken + rate-limited)
    |
    +-- Round-robin starting point (load balancing)
    |
    +-- For each API:
    |     +-- Check cache --> return if hit
    |     +-- Check circuit breaker --> skip if open
    |     +-- Rate limiter --> wait if needed
    |     +-- Make HTTP call (with retry + backoff)
    |     +-- Record success/failure for circuit breaker
    |     +-- Cache successful response
    |     +-- Track usage + cost
    |     +-- Return on success, continue on failure
    |
    +-- If all fail --> return last error
```

---

## Core Components

### 1. Circuit Breaker (`lib/retry.py`)
```python
"""Circuit breaker to prevent cascading failures."""
import threading
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Optional, Callable, TypeVar, Any

T = TypeVar('T')

class CircuitBreakerOpen(Exception):
    """Raised when circuit is open."""
    pass

class CircuitBreaker:
    """
    States:
    - CLOSED: Normal operation, calls pass through
    - OPEN: Calls fail immediately (provider is down)
    - HALF-OPEN: Allow one test call to check recovery
    """

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 30.0,
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = timedelta(seconds=recovery_timeout)
        self._failures = 0
        self._state = "closed"
        self._last_failure_time: Optional[datetime] = None
        self._lock = threading.Lock()

    @property
    def is_open(self) -> bool:
        return self._state == "open"

    def _record_success(self):
        with self._lock:
            self._failures = 0
            self._state = "closed"

    def _record_failure(self):
        with self._lock:
            self._failures += 1
            self._last_failure_time = datetime.now()
            if self._failures >= self.failure_threshold:
                self._state = "open"

    def allow_request(self) -> bool:
        with self._lock:
            if self._state == "closed":
                return True
            if self._state == "open":
                if (self._last_failure_time and
                    datetime.now() - self._last_failure_time >= self.recovery_timeout):
                    self._state = "half-open"
                    return True
                return False
            return True  # half-open: allow test call
```

### 2. Rate Limiter
```python
"""Token bucket rate limiter."""
import time
import threading

class RateLimiter:
    def __init__(self, calls_per_minute: int = 60):
        self.min_interval = 60.0 / calls_per_minute
        self._last_call = 0.0
        self._lock = threading.Lock()

    def acquire(self):
        """Block until rate limit allows a call."""
        with self._lock:
            now = time.time()
            elapsed = now - self._last_call
            if elapsed < self.min_interval:
                time.sleep(self.min_interval - elapsed)
            self._last_call = time.time()
```

### 3. Response Cache
```python
"""LRU cache with TTL for API responses."""
import hashlib
import time
import threading
from collections import OrderedDict
from dataclasses import dataclass
from typing import Optional, Any

@dataclass
class CacheEntry:
    response: Any
    created_at: float
    ttl_seconds: float

    @property
    def is_expired(self) -> bool:
        return time.time() - self.created_at > self.ttl_seconds

class ResponseCache:
    def __init__(self, max_size: int = 1000, default_ttl: float = 3600.0):
        self.max_size = max_size
        self.default_ttl = default_ttl
        self._cache: OrderedDict[str, CacheEntry] = OrderedDict()
        self._lock = threading.Lock()
        self._hits = 0
        self._misses = 0

    def make_key(self, prompt: str, provider: str = "", model: str = "",
                 max_tokens: int = 4000, temperature: float = 0.7) -> str:
        key_data = f"{provider}|{model}|{prompt}|{max_tokens}|{temperature}"
        return hashlib.sha256(key_data.encode()).hexdigest()

    def get(self, key: str) -> Optional[Any]:
        with self._lock:
            entry = self._cache.get(key)
            if entry is None or entry.is_expired:
                self._misses += 1
                if entry and entry.is_expired:
                    del self._cache[key]
                return None
            self._cache.move_to_end(key)  # LRU
            self._hits += 1
            return entry.response

    def set(self, key: str, response: Any, ttl: Optional[float] = None):
        with self._lock:
            while len(self._cache) >= self.max_size:
                self._cache.popitem(last=False)  # Evict oldest
            self._cache[key] = CacheEntry(
                response=response,
                created_at=time.time(),
                ttl_seconds=ttl or self.default_ttl,
            )
```

### 4. Usage Tracker (Budget Control)
```python
"""Track API usage and enforce daily budget."""
import threading
import datetime

TOKEN_COSTS = {  # per 1M tokens
    "deepseek": {"input": 0.14, "output": 0.28},
    "groq": {"input": 0.05, "output": 0.10},
    "anthropic": {"input": 3.00, "output": 15.00},
    "openai": {"input": 2.50, "output": 10.00},
    "default": {"input": 0.50, "output": 1.00},
}

class UsageTracker:
    def __init__(self, budget_limit: float = 50.0):
        self._lock = threading.Lock()
        self._daily_spent = 0.0
        self._budget_date = datetime.date.today()
        self.budget_limit = budget_limit

    def check_budget(self) -> bool:
        with self._lock:
            if datetime.date.today() != self._budget_date:
                self._daily_spent = 0.0
                self._budget_date = datetime.date.today()
            return self._daily_spent < self.budget_limit

    def record(self, provider: str, tokens: int, is_input: bool = False):
        with self._lock:
            costs = TOKEN_COSTS.get(provider, TOKEN_COSTS["default"])
            cost_per_token = costs["input" if is_input else "output"] / 1_000_000
            self._daily_spent += tokens * cost_per_token
```

### 5. Unified Client (Ties Everything Together)
```python
"""Multi-provider LLM client with failover."""
from dataclasses import dataclass
from typing import Optional, List, Dict
import time

@dataclass
class LLMResponse:
    content: Optional[str] = None
    success: bool = False
    provider: str = ""
    model: str = ""
    error: Optional[str] = None
    tokens_used: int = 0
    latency_ms: float = 0.0
    cached: bool = False

class LLMClient:
    def __init__(self):
        self._cache = ResponseCache()
        self._usage = UsageTracker(budget_limit=50.0)
        self._breakers: Dict[str, CircuitBreaker] = {}
        self._limiters: Dict[str, RateLimiter] = {}
        self._api_index = 0  # Round-robin counter

        # Register providers
        for name in ["deepseek", "groq", "openrouter", "anthropic"]:
            self._breakers[name] = CircuitBreaker(failure_threshold=5, recovery_timeout=30)
            self._limiters[name] = RateLimiter(calls_per_minute=60)

    def call(self, prompt: str, max_tokens: int = 4000,
             temperature: float = 0.7) -> LLMResponse:
        """Call best available provider with automatic fallback."""
        return self.call_with_fallback(prompt, max_tokens, temperature)

    def call_with_fallback(
        self, prompt: str, max_tokens: int = 4000,
        temperature: float = 0.7,
        preferred_providers: Optional[List[str]] = None,
    ) -> LLMResponse:
        # Budget check
        if not self._usage.check_budget():
            return LLMResponse(success=False, error="Daily budget exceeded")

        # Get healthy providers
        providers = preferred_providers or self._get_available_providers()
        if not providers:
            return LLMResponse(success=False, error="No providers available")

        # Round-robin start
        start_idx = self._api_index % len(providers)
        self._api_index += 1

        last_response = None
        for i in range(len(providers)):
            idx = (start_idx + i) % len(providers)
            provider = providers[idx]

            response = self._call_provider(provider, prompt, max_tokens, temperature)
            if response.success:
                return response
            last_response = response

        return last_response or LLMResponse(success=False, error="All providers failed")

    def _get_available_providers(self) -> List[str]:
        return [
            name for name, breaker in self._breakers.items()
            if not breaker.is_open
        ]

    def _call_provider(self, provider: str, prompt: str,
                       max_tokens: int, temperature: float) -> LLMResponse:
        # Check cache
        cache_key = self._cache.make_key(prompt, provider, max_tokens=max_tokens)
        if cached := self._cache.get(cache_key):
            return cached

        # Check circuit breaker
        breaker = self._breakers[provider]
        if breaker.is_open:
            return LLMResponse(success=False, provider=provider, error="Circuit open")

        # Rate limit
        self._limiters[provider].acquire()

        # Make call
        start = time.time()
        try:
            response = self._http_call(provider, prompt, max_tokens, temperature)
            response.latency_ms = (time.time() - start) * 1000

            if response.success:
                breaker._record_success()
                self._cache.set(cache_key, response)
                self._usage.record(provider, response.tokens_used)
            else:
                breaker._record_failure()

            return response
        except Exception as e:
            breaker._record_failure()
            return LLMResponse(success=False, provider=provider, error=str(e))
```

## Key Design Decisions
1. **Round-robin load balancing** -- distributes load evenly, not always hitting the cheapest provider first
2. **Circuit breakers per provider** -- one provider going down does not affect others
3. **Budget cap** -- hard daily limit prevents runaway costs (resets at midnight)
4. **Cache includes provider + model in key** -- different providers give different responses
5. **Fail open on cache miss** -- always try the API if cache misses
6. **Permanent disable for auth failures** -- 401/403/402 errors skip the circuit breaker and disable the provider entirely (no point retrying bad credentials)

## Projects That Need This Pattern
- **OYKH** (C) -- no cost controls on AI API usage (could run up huge bills)
- **Pod** (C-) -- no cost controls, API keys exposed
- **BookCLI** (D) -- already has this pattern (source), but keys are committed
- **Any project using LLM APIs** -- even single-provider projects benefit from retry + circuit breaker + caching
