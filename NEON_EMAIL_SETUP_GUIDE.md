# Neon Email Capture Setup - All 4 Sites

**Last Updated**: March 3, 2026
**Status**: In Progress - Path fixes applied, builds validating

---

## Current Status

### ✅ Completed
- [x] Fixed affiliate site path alias issue (import from relative path)
- [x] Identified Neon requirements for all 4 sites
- [x] Drafted setup guide

### 🔄 In Progress
- [ ] Validate all 4 builds (credit, affiliate, quant, calc)
- [ ] Set up Neon PostgreSQL project
- [ ] Configure DATABASE_URL env vars
- [ ] Run Prisma migrations
- [ ] Test email capture endpoints

### ⏳ Pending
- [ ] Quant platform email capture setup (no email capture currently)

---

## Email Capture Architecture Overview

### Sites Using Prisma + Email Capture:
| Site | Database | Email Capture | Status |
|------|----------|---------------|--------|
| **Credit** | Prisma + SQLite (local) | ✅ Comprehensive | Need Neon migration |
| **Affiliate** | Prisma + Supabase | ✅ Basic capture | Fixed import error |
| **Calc** | Prisma (needs config) | ✅ Basic capture | Need Neon setup |
| **Quant** | ❌ None | ❌ None | Needs implementation |

---

## STEP 1: Create Neon PostgreSQL Project

### Option A: Single Neon Project for All 4 Sites (Recommended)
```
Project: multi-site-email-lists
Database: multi_site_emails
Branch: main

Connection String Pattern:
postgresql://user:password@ep-example.us-east-1.neon.tech/multi_site_emails
```

### Option B: Separate Neon Projects per Site
- `credit-cardclassroom`
- `affiliate-thestackguide`
- `calc-dividend`
- `quant-platform`

### Steps:
1. Go to https://console.neon.tech
2. Create new project (name: `multi-site-email-lists`)
3. Select PostgreSQL 16
4. Copy connection string: `postgresql://...`

---

## STEP 2: Update .env Files

### Credit Site (`/mnt/e/projects/credit/.env`)
```env
# Replace current SQLite with Neon
DATABASE_URL="postgresql://user:password@ep-example.us-east-1.neon.tech/multi_site_emails"

# Keep existing email config
SENDGRID_API_KEY=SG.xxxxxxxxxxxxx
FROM_EMAIL=noreply@cardclassroom.com
```

### Affiliate Site (`/mnt/e/projects/affiliate/thestackguide/.env.local`)
```env
DATABASE_URL="postgresql://user:password@ep-example.us-east-1.neon.tech/multi_site_emails"

# Email provider (optional - currently using ConvertKit API)
# Configure later for direct email sending
```

### Calc Site (`/mnt/e/projects/calc/.env.local`)
```env
DATABASE_URL="postgresql://user:password@ep-example.us-east-1.neon.tech/multi_site_emails"

# Email provider
SENDGRID_API_KEY=SG.xxxxxxxxxxxxx  # or other provider
FROM_EMAIL=noreply@calc.com
```

### Quant Site (`/mnt/e/projects/quant/quant/.env.local`)
```env
# Will add after email capture is implemented
DATABASE_URL="postgresql://user:password@ep-example.us-east-1.neon.tech/multi_site_emails"
```

---

## STEP 3: Prisma Schema Setup

All 4 sites need consistent email schema in `prisma/schema.prisma`:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model EmailSubscriber {
  id                String    @id @default(cuid())
  email             String
  emailHash         String
  site              String    // 'credit', 'affiliate', 'calc', 'quant'
  source            String?   // 'footer', 'exit-intent', 'popup', etc.
  preferences       Json?     // Optional: tracking preferences per site
  consentedAt       DateTime
  verifiedAt        DateTime?
  verificationToken String?
  verified          Boolean   @default(false)
  status            String    @default("active") // active, unsubscribed
  sessionId         String?
  ipAddress         String?
  unsubscribedAt    DateTime?
  updatedAt         DateTime  @updatedAt
  createdAt         DateTime  @default(now())

  @@unique([email, site]) // One subscription per email per site
  @@index([site])
  @@index([createdAt])
}
```

---

## STEP 4: Run Prisma Migrations

### For each site:
```bash
cd /mnt/e/projects/[site]

# Generate Prisma client
npm run prisma generate

# Create migration
npx prisma migrate dev --name init

# (or push schema directly to existing database)
npx prisma db push
```

### Commands by site:
```bash
# Credit
cd /mnt/e/projects/credit
npx prisma migrate dev --name init

# Affiliate
cd /mnt/e/projects/affiliate/thestackguide
npx prisma migrate dev --name init

# Calc
cd /mnt/e/projects/calc
npx prisma migrate dev --name init

# Quant - after implementing email capture
cd /mnt/e/projects/quant/quant
npx prisma migrate dev --name init
```

---

## STEP 5: Test Email Capture Endpoints

### Credit - Test endpoint:
```bash
curl -X POST http://localhost:3000/api/email/capture \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "source": "test",
    "preferences": {"creditCards": true},
    "consentToMarketing": true
  }'
```

### Affiliate - Test endpoint:
```bash
curl -X POST http://localhost:3000/api/email/capture \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "source": "footer"
  }'
```

### Calc - Test endpoint:
```bash
curl -X POST http://localhost:3000/api/email/capture \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "source": "footer"
  }'
```

### Verify in Neon:
```sql
SELECT id, email, site, source, created_at FROM EmailSubscriber ORDER BY created_at DESC;
```

---

## STEP 6: Quant Email Capture Implementation

Quant currently has NO email capture. Create simple endpoint:

### Create `/app/api/email/capture/route.ts`:
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import crypto from 'crypto';

export async function POST(request: NextRequest) {
  try {
    const { email, source } = await request.json();

    if (!email) {
      return NextResponse.json({ error: 'Email required' }, { status: 400 });
    }

    const emailHash = crypto
      .createHash('sha256')
      .update(email.toLowerCase())
      .digest('hex');

    const existingEmail = await prisma.emailSubscriber.findFirst({
      where: {
        email: email.toLowerCase(),
        site: 'quant',
      },
    });

    if (existingEmail) {
      return NextResponse.json({
        success: true,
        message: 'Already subscribed',
        isNew: false,
      });
    }

    const subscriber = await prisma.emailSubscriber.create({
      data: {
        email: email.toLowerCase(),
        emailHash,
        site: 'quant',
        source: source || 'signup',
        consentedAt: new Date(),
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Subscribed!',
      isNew: true,
    });
  } catch (error) {
    console.error('Email error:', error);
    return NextResponse.json({ error: 'Failed' }, { status: 500 });
  }
}
```

---

## Build Status & Known Issues

### ✅ Affiliate Site
- **Error Found**: Path alias mismatch (`@/lib/prisma` → `../../../lib/prisma`)
- **Fixed**: Updated import to relative path
- **Status**: Re-building for validation

### 🔄 Credit Site
- **Status**: Building
- **Expected**: Should pass (has comprehensive email setup)
- **Issue**: SQLite only, needs Neon migration

### 🔄 Calc Site
- **Status**: Building
- **Expected**: Should pass (has email capture code)
- **Issue**: Needs Neon connection string

### 🔄 Quant Site
- **Status**: Building
- **Issue**: No email capture, needs implementation

---

## Implementation Checklist

- [ ] Create Neon project at https://console.neon.tech
- [ ] Copy connection string
- [ ] Update .env for all 4 sites
- [ ] Validate all builds pass
- [ ] Run `npx prisma migrate dev` for each site
- [ ] Test email capture endpoints
- [ ] Verify data in Neon console
- [ ] Deploy to production
- [ ] Monitor email list growth

---

## Monitoring Dashboard

Query to monitor subscriptions:
```sql
SELECT site, COUNT(*) as total, COUNT(DISTINCT email) as unique
FROM EmailSubscriber
WHERE status = 'active'
GROUP BY site;
```

Monitor growth by day:
```sql
SELECT
  site,
  DATE(created_at) as date,
  COUNT(*) as new_subscribers
FROM EmailSubscriber
GROUP BY site, DATE(created_at)
ORDER BY date DESC;
```

---

## Estimated Timeline

- **Neon Setup**: 5 min
- **Update .env**: 10 min
- **Prisma Migrations**: 10 min
- **Testing**: 10 min
- **Quant Implementation**: 15 min
- **Deployment**: 30 min

**Total**: ~80 minutes (1.5 hours)

---

## Next: SEO Expansion & Growth Strategy

Once Neon is live:
1. Email list capture for all sites
2. Reduce salesy messaging (growth focus)
3. Expand content by 30-50% per site
4. Focus on organic traffic before affiliate push
