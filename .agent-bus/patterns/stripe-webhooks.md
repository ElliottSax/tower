# Pattern: Stripe Webhook Verification + Idempotent Processing

## Problem It Solves
Securely receiving and processing Stripe payment events. Without signature verification, anyone can send fake webhook events to your endpoint and get free access. Without idempotent processing, webhook retries can create duplicate enrollments/orders.

## Source Project
**Course Platform** (B-) -- `/mnt/e/projects/course/courseflow/app/api/webhooks/stripe/route.ts`

## When to Use
- Any project that accepts payments via Stripe
- Subscription management
- Order fulfillment after payment

## Dependencies
```bash
npm install stripe
```

---

## Next.js Pattern (App Router)

### `app/api/webhooks/stripe/route.ts`
```typescript
import { NextResponse } from 'next/server';
import { headers } from 'next/headers';
import Stripe from 'stripe';
import { db } from '@/lib/db';
import { logger } from '@/lib/logger';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-12-15.clover',
});

/**
 * IMPORTANT: This route does NOT use standard auth middleware because:
 * 1. Stripe uses signature verification, not session auth
 * 2. The body must be read as raw text for signature verification
 * 3. Rate limiting is handled by Stripe's retry mechanism
 */
export async function POST(request: Request) {
  try {
    // Step 1: Read raw body (MUST be text, not JSON)
    const body = await request.text();
    const headersList = await headers();
    const signature = headersList.get('stripe-signature');

    if (!signature) {
      return NextResponse.json({ error: 'No signature' }, { status: 400 });
    }

    if (!process.env.STRIPE_WEBHOOK_SECRET) {
      throw new Error('STRIPE_WEBHOOK_SECRET is not set');
    }

    // Step 2: Verify signature
    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(
        body,
        signature,
        process.env.STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      logger.error('Webhook signature verification failed', err);
      return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
    }

    // Step 3: Handle events
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        const { userId, courseId } = paymentIntent.metadata;

        if (!userId || !courseId) {
          logger.error('Missing metadata in payment intent', {
            paymentIntentId: paymentIntent.id,
          });
          break;
        }

        // Step 4: IDEMPOTENT insert (handles webhook retries safely)
        const result = await db
          .insert(enrollments)
          .values({ userId, courseId, status: 'active' })
          .onConflictDoNothing({
            target: [enrollments.userId, enrollments.courseId],
          })
          .returning();

        if (result.length === 0) {
          // Duplicate -- webhook retry, enrollment already exists
          logger.info('Enrollment already exists (webhook retry)', {
            userId, courseId,
          });
          break;
        }

        // Only runs on first successful insert
        logger.info('Enrollment created', { userId, courseId });
        // Send confirmation email, award XP, etc.
        break;
      }

      case 'payment_intent.payment_failed': {
        const failed = event.data.object as Stripe.PaymentIntent;
        logger.warn('Payment failed', {
          paymentIntentId: failed.id,
          error: failed.last_payment_error?.message,
        });
        // Send failure notification email
        break;
      }

      default:
        logger.debug('Unhandled event type', { type: event.type });
    }

    // Step 5: Always return 200 (Stripe retries on non-2xx)
    return NextResponse.json({ received: true });
  } catch (error) {
    logger.error('Webhook handler failed', error);
    return NextResponse.json({ error: 'Webhook handler failed' }, { status: 500 });
  }
}
```

### `next.config.js` -- Disable body parsing for webhook route
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Note: Next.js App Router handles raw body automatically
  // No special config needed (unlike Pages Router)
};
```

---

## FastAPI / Python Pattern

### `app/api/webhooks/stripe.py`
```python
"""Stripe webhook handler for FastAPI."""
import stripe
from fastapi import APIRouter, Request, HTTPException, Header
from sqlalchemy.dialects.postgresql import insert
import os

router = APIRouter()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

@router.post("/webhooks/stripe")
async def stripe_webhook(
    request: Request,
    stripe_signature: str = Header(None, alias="stripe-signature"),
):
    if not stripe_signature:
        raise HTTPException(status_code=400, detail="No signature")

    if not webhook_secret:
        raise HTTPException(status_code=500, detail="Webhook secret not configured")

    # Read raw body
    body = await request.body()

    # Verify signature
    try:
        event = stripe.Webhook.construct_event(
            payload=body,
            sig_header=stripe_signature,
            secret=webhook_secret,
        )
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle events
    if event["type"] == "payment_intent.succeeded":
        payment_intent = event["data"]["object"]
        user_id = payment_intent["metadata"].get("userId")
        product_id = payment_intent["metadata"].get("productId")

        if user_id and product_id:
            # Idempotent upsert
            stmt = insert(orders).values(
                user_id=user_id,
                product_id=product_id,
                status="completed",
                stripe_payment_id=payment_intent["id"],
            ).on_conflict_do_nothing(
                index_elements=["user_id", "product_id", "stripe_payment_id"]
            )
            await db.execute(stmt)

    return {"received": True}
```

## Critical Design Decisions

1. **Raw body for signature** -- MUST read body as text/bytes before any JSON parsing. If you parse to JSON first, the signature check will always fail.
2. **Idempotent inserts** -- Use `ON CONFLICT DO NOTHING` or equivalent. Stripe retries webhooks up to 3 days, so your handler WILL be called multiple times.
3. **Always return 200** -- Even for unhandled event types. Non-2xx causes Stripe to retry, potentially flooding your endpoint.
4. **Metadata for context** -- Store userId, courseId, etc. in PaymentIntent metadata at checkout time. The webhook only has the PaymentIntent object.
5. **No standard auth** -- Webhook routes use Stripe signature verification instead of session/JWT auth.
6. **Separate duplicate handling** -- Check `result.length === 0` to distinguish "already processed" from "newly created" and skip side effects (emails, XP) on duplicates.

## Projects That Need This Pattern
- **Quant** (B+) -- Stripe webhook verification is COMMENTED OUT (critical!)
- **Course Platform** (B-) -- Already has it (source), but free enrollment bypass exists
- **Discovery** (C+) -- Premium paywall commented out, needs webhook for subscription
