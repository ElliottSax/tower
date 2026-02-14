# Pattern: Input Validation (Zod for TypeScript + Pydantic for Python)

## Problem It Solves
Unvalidated input leads to crashes, injection attacks, data corruption, and security vulnerabilities. Every API endpoint should validate and sanitize all incoming data before processing.

## Source Projects
- **Credit** (B+) -- `/mnt/e/projects/credit/lib/api/validation.ts` (Zod schemas)
- **Credit** (B+) -- `/mnt/e/projects/credit/lib/env.ts` (Zod environment validation)
- **Course Platform** (B-) -- `/mnt/e/projects/course/courseflow/lib/validators.ts` (Zod UUID + pagination)
- **Course Platform** (B-) -- `/mnt/e/projects/course/courseflow/lib/api-handler.ts` (createApiHandler with auto-validation)
- **Acquisition System** (B-) -- `/mnt/e/projects/acquisition-system/backend/utils/config.py` (Pydantic settings)

## When to Use
- Every API endpoint that accepts user input
- Environment variable validation at startup
- Form submissions
- URL parameter parsing

---

## TypeScript Pattern (Zod)

### Dependencies
```bash
npm install zod
```

### `lib/validation.ts` -- Reusable schemas
```typescript
import { z } from 'zod';
import { NextResponse } from 'next/server';

// === Common Schemas ===

export const uuidSchema = z.string().uuid();

export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(10),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['asc', 'desc']).default('asc'),
});

export const emailSchema = z.string().email().toLowerCase().max(255);

// === Domain-specific Schemas (customize per project) ===

export const createUserSchema = z.object({
  email: emailSchema,
  name: z.string().min(1).max(100).trim(),
  password: z.string().min(8).max(128),
});

export const createProductSchema = z.object({
  title: z.string().min(3).max(200).trim(),
  price: z.number().int().min(0).max(999999),  // cents
  description: z.string().max(5000).optional(),
});

// === Generic Response Schemas ===

export const apiResponseSchema = <T extends z.ZodType>(dataSchema: T) =>
  z.object({
    success: z.boolean(),
    data: dataSchema.optional(),
    error: z.string().optional(),
    timestamp: z.string().datetime(),
  });

export const paginatedResponseSchema = <T extends z.ZodType>(itemSchema: T) =>
  z.object({
    items: z.array(itemSchema),
    pagination: z.object({
      page: z.number(),
      limit: z.number(),
      total: z.number(),
      totalPages: z.number(),
      hasNext: z.boolean(),
      hasPrev: z.boolean(),
    }),
  });

// === Validation Helper ===

export function validateRequest<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): { success: true; data: T } | { success: false; errors: z.ZodError } {
  const result = schema.safeParse(data);
  if (result.success) return { success: true, data: result.data };
  return { success: false, errors: result.error };
}

// === Input Sanitization ===

export function sanitizeInput(input: string, maxLength = 1000): string {
  if (!input || typeof input !== 'string') return '';
  return input
    .replace(/<[^>]*>/g, '')            // Strip HTML tags
    .replace(/javascript:/gi, '')        // Remove javascript: protocol
    .replace(/on\w+\s*=/gi, '')         // Remove event handlers
    .replace(/\0/g, '')                 // Remove null bytes
    .trim()
    .slice(0, maxLength);
}
```

### `lib/env.ts` -- Environment validation (runs at startup)
```typescript
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  NEXT_PUBLIC_APP_URL: z.string().url().optional(),
  UPSTASH_REDIS_REST_URL: z.string().url().optional(),
  UPSTASH_REDIS_REST_TOKEN: z.string().optional(),
  STRIPE_SECRET_KEY: z.string().optional(),
  STRIPE_WEBHOOK_SECRET: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;

let cachedEnv: Env | null = null;

export function getEnv(): Env {
  if (!cachedEnv) {
    try {
      cachedEnv = envSchema.parse(process.env);
    } catch (error) {
      if (error instanceof z.ZodError) {
        console.error('Environment validation failed:');
        error.errors.forEach((err) => {
          console.error(`  - ${err.path.join('.')}: ${err.message}`);
        });
        throw new Error('Invalid environment configuration');
      }
      throw error;
    }
  }
  return cachedEnv;
}
```

### `lib/api-handler.ts` -- Unified handler with auto-validation
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

interface ApiHandlerOptions {
  requireAuth?: boolean;
  requireRole?: string[];
  rateLimit?: 'auth' | 'api' | 'payment' | false;
  schema?: z.ZodSchema;    // Auto-validates request body
  logging?: boolean;
}

export function createApiHandler(
  handler: (request: NextRequest) => Promise<NextResponse>,
  options: ApiHandlerOptions = {}
) {
  return async (request: NextRequest): Promise<NextResponse> => {
    try {
      // Auto-validate body if schema provided
      if (options.schema && ['POST', 'PUT', 'PATCH'].includes(request.method)) {
        const body = await request.json();
        const result = options.schema.safeParse(body);

        if (!result.success) {
          return NextResponse.json(
            {
              error: 'Validation failed',
              details: result.error.errors.map((e) => ({
                field: e.path.join('.'),
                message: e.message,
              })),
            },
            { status: 400 }
          );
        }

        (request as any).validatedBody = result.data;
      }

      return await handler(request);
    } catch (error) {
      console.error('API error:', error);
      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 }
      );
    }
  };
}

// Usage:
// export const POST = createApiHandler(
//   async (req) => {
//     const data = (req as any).validatedBody;
//     // data is already validated and typed
//     return NextResponse.json({ data });
//   },
//   { schema: createProductSchema, requireAuth: true }
// );
```

---

## Python Pattern (Pydantic)

### Dependencies
```bash
pip install pydantic pydantic-settings
```

### `app/schemas.py` -- Request/Response schemas
```python
"""API request/response validation schemas."""
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator, EmailStr
from datetime import datetime
from enum import Enum

class SortOrder(str, Enum):
    asc = "asc"
    desc = "desc"

class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1)
    limit: int = Field(default=10, ge=1, le=100)
    sort_by: Optional[str] = None
    sort_order: SortOrder = SortOrder.asc

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)
    password: str = Field(..., min_length=8, max_length=128)

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return v.strip()

class CreateProductRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    price: int = Field(..., ge=0, le=999999)  # cents
    description: Optional[str] = Field(None, max_length=5000)

class ApiResponse(BaseModel):
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class PaginatedResponse(BaseModel):
    items: List[dict]
    page: int
    limit: int
    total: int
    total_pages: int
    has_next: bool
    has_prev: bool
```

### `app/config.py` -- Environment validation
```python
"""Validated configuration using pydantic-settings."""
from typing import Optional
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Required
    database_url: str = Field(..., description="PostgreSQL connection string")
    secret_key: str = Field(..., min_length=32)

    # Optional with defaults
    environment: str = Field(default="development")
    debug: bool = Field(default=False)
    log_level: str = Field(default="INFO")

    # Optional integrations
    stripe_secret_key: Optional[str] = None
    stripe_webhook_secret: Optional[str] = None
    redis_url: Optional[str] = None

    @field_validator("environment")
    @classmethod
    def validate_environment(cls, v: str) -> str:
        allowed = {"development", "staging", "production", "test"}
        if v not in allowed:
            raise ValueError(f"environment must be one of {allowed}")
        return v

settings = Settings()
```

### Usage in FastAPI route:
```python
from fastapi import APIRouter
from app.schemas import CreateProductRequest, ApiResponse

router = APIRouter()

@router.post("/products", response_model=ApiResponse)
async def create_product(request: CreateProductRequest):
    # request.title, request.price are already validated
    # Pydantic raises 422 automatically if validation fails
    product = await db.create_product(
        title=request.title,
        price=request.price,
    )
    return ApiResponse(success=True, data=product.dict())
```

## Key Design Decisions
1. **Validate at the boundary** -- never trust anything from the client, even "trusted" internal APIs
2. **Fail fast with clear errors** -- return field-level error messages so the client can fix input
3. **Environment validation at startup** -- crash immediately if config is wrong, not on the first request 10 minutes later
4. **Coerce where safe** -- `z.coerce.number()` and `z.coerce.boolean()` handle query parameter strings gracefully
5. **Sanitize after validation** -- validate structure first, then sanitize content (strip HTML, etc.)

## Projects That Need This Pattern
- **Sports** (D) -- no input validation at all
- **Calc** (C+) -- TypeScript errors suppressed throughout
- **Back** (C) -- no backend validation
- **Pod** (C-) -- no input validation
- **OYKH** (C) -- no input validation
- **ContractIQ** (C+) -- settings crash on invalid input
