# 🏦 FinanceHub - Unified Platform Integration Architecture

**Vision:** Combine `calc` (dividend calculators) and `credit` (credit card platform) into a unified financial tools ecosystem.

**Brand:** FinanceHub - Your Complete Financial Toolkit

---

## 🎯 Strategic Rationale

### Why Integrate?

1. **2x Revenue Streams**
   - Investment affiliate commissions (brokers)
   - Credit card affiliate commissions
   - Cross-sell opportunities

2. **Better User Experience**
   - One account, multiple tools
   - Holistic financial planning
   - Data sharing between tools

3. **Network Effects**
   - User comes for calculator → discovers credit cards
   - User comes for credit cards → discovers investment tools
   - Unified email list for cross-promotion

4. **Technical Efficiency**
   - Shared authentication
   - Unified analytics
   - Single deployment/infrastructure
   - Consolidated database

---

## 🏗️ Technical Architecture

### Option A: Monorepo with Shared Packages (Recommended)

```
financehub/
├── apps/
│   ├── invest/          # calc (dividend calculators)
│   │   ├── app/
│   │   ├── components/
│   │   └── package.json
│   │
│   ├── credit/          # credit card platform
│   │   ├── app/
│   │   ├── components/
│   │   └── package.json
│   │
│   └── web/             # Marketing site (new)
│       ├── app/
│       └── package.json
│
├── packages/
│   ├── ui/              # Shared components
│   ├── auth/            # Shared authentication
│   ├── database/        # Shared Prisma schema
│   ├── analytics/       # Shared analytics
│   ├── config/          # Shared configs
│   └── types/           # Shared TypeScript types
│
├── package.json         # Root package
└── turbo.json          # Turborepo config
```

**Tools:**
- Turborepo for monorepo management
- pnpm for package management
- Shared Next.js configuration

### Option B: Separate Repos with Shared Library

```
@financehub/core  (npm package)
├── auth/
├── analytics/
├── ui/
└── types/

calc (repo) → uses @financehub/core
credit (repo) → uses @financehub/core
```

**Recommendation:** **Option A (Monorepo)** for faster development and better code sharing.

---

## 🔐 Unified Authentication System

### Current State
- **calc:** Supabase Auth
- **credit:** NextAuth (Prisma)

### Target Architecture

```typescript
// packages/auth/index.ts
import NextAuth from 'next-auth';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from '@financehub/database';

export const authConfig = {
  adapter: PrismaAdapter(prisma),
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    }),
    Email({
      server: process.env.EMAIL_SERVER,
      from: process.env.EMAIL_FROM,
    }),
  ],
  callbacks: {
    session({ session, user }) {
      session.user.id = user.id;
      session.user.tier = user.tier; // 'free', 'premium', 'enterprise'
      return session;
    },
  },
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
  },
};
```

**Migration Plan:**
1. Set up NextAuth in `packages/auth`
2. Migrate calc from Supabase → NextAuth
3. Unify user tables in shared database
4. Implement SSO across both platforms

---

## 💾 Unified Database Schema

### Shared Database (PostgreSQL + Prisma)

```prisma
// packages/database/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================
// USERS & AUTH
// ============================================

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String?
  image         String?
  emailVerified DateTime?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  // Subscription
  tier          UserTier  @default(FREE)
  stripeCustomerId String?
  subscriptionId   String?
  subscriptionEndsAt DateTime?

  // Platform usage
  calcCalculations Int @default(0)
  creditComparisons Int @default(0)
  lastActiveAt     DateTime?

  // Referral system
  referralCode  String? @unique
  referredById  String?
  referredBy    User?   @relation("Referrals", fields: [referredById], references: [id])
  referrals     User[]  @relation("Referrals")

  // Relations
  accounts          Account[]
  sessions          Session[]
  calculatorSaves   CalculatorSave[]
  watchlist         WatchlistItem[]
  creditComparisons CreditCardComparison[]
  affiliateClicks   AffiliateClick[]
  events            AnalyticsEvent[]
}

enum UserTier {
  FREE
  PREMIUM
  ENTERPRISE
}

// NextAuth tables
model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// ============================================
// INVESTMENT PLATFORM (calc)
// ============================================

model CalculatorSave {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  type      CalculatorType
  inputs    Json
  results   Json
  name      String?

  isPublic  Boolean  @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

enum CalculatorType {
  DRIP
  RETIREMENT
  DIVIDEND_GROWTH
  YIELD_ON_COST
  COFFEE
}

model WatchlistItem {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  ticker    String
  addedAt   DateTime @default(now())
  notes     String?

  @@unique([userId, ticker])
}

// ============================================
// CREDIT PLATFORM
// ============================================

model CreditCard {
  id          String   @id @default(cuid())
  slug        String   @unique
  name        String
  issuer      String

  annualFee   Float
  aprMin      Float
  aprMax      Float

  rewards     Json     // Rewards structure
  signUpBonus Json?

  affiliateLink   String
  commissionRate  Float

  isActive    Boolean  @default(true)
  isFeatured  Boolean  @default(false)

  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  comparisons CreditCardComparison[]
  clicks      AffiliateClick[]
}

model CreditCardComparison {
  id        String   @id @default(cuid())
  userId    String?
  user      User?    @relation(fields: [userId], references: [id], onDelete: SetNull)

  cardIds   String[] // Array of card IDs compared
  criteria  Json     // Comparison criteria used

  createdAt DateTime @default(now())
}

// ============================================
// AFFILIATE TRACKING (Shared)
// ============================================

model AffiliateClick {
  id          String   @id @default(cuid())
  userId      String?
  user        User?    @relation(fields: [userId], references: [id], onDelete: SetNull)

  platform    Platform
  merchantId  String   // Broker ID or Credit Card ID
  merchantName String
  category    String   // 'broker', 'credit-card', etc.

  placement   String   // Where on site the click happened

  // Tracking
  clickedAt   DateTime @default(now())
  ipAddress   String?
  userAgent   String?
  referrer    String?

  // Attribution
  conversionId String? @unique
  conversion   Conversion? @relation(fields: [conversionId], references: [id])

  @@index([userId])
  @@index([merchantId])
  @@index([clickedAt])
}

model Conversion {
  id          String   @id @default(cuid())
  clickId     String   @unique
  click       AffiliateClick @relation

  platform    Platform
  merchantId  String

  // Commission
  commissionAmount Float
  commissionType   String // 'CPA', 'CPS', 'RevShare'
  commissionStatus String @default("pending") // pending, approved, paid

  // Tracking
  convertedAt DateTime @default(now())
  approvedAt  DateTime?
  paidAt      DateTime?

  @@index([merchantId])
  @@index([convertedAt])
}

enum Platform {
  INVEST  // calc
  CREDIT  // credit
}

// ============================================
// ANALYTICS (Shared)
// ============================================

model AnalyticsEvent {
  id        String   @id @default(cuid())
  userId    String?
  user      User?    @relation(fields: [userId], references: [id], onDelete: SetNull)

  platform  Platform
  eventType String
  properties Json

  sessionId String?
  timestamp DateTime @default(now())

  @@index([userId])
  @@index([eventType])
  @@index([timestamp])
}

// ============================================
// EMAIL & MARKETING
// ============================================

model EmailSubscriber {
  id          String   @id @default(cuid())
  email       String   @unique

  source      String   // Which platform/page they subscribed from
  tags        String[] // Segmentation tags

  isActive    Boolean  @default(true)
  subscribedAt DateTime @default(now())
  unsubscribedAt DateTime?
}
```

---

## 🎨 Unified Brand & Design System

### Domain Strategy

**Option 1: Separate Subdomains**
```
www.financehub.com       → Marketing site
invest.financehub.com    → calc (calculators)
credit.financehub.com    → credit (cards)
app.financehub.com       → Unified dashboard (future)
```

**Option 2: Path-based Routing**
```
financehub.com/         → Marketing
financehub.com/invest   → Calculators
financehub.com/credit   → Credit cards
financehub.com/app      → Dashboard
```

**Recommendation:** Option 2 (Path-based) for better SEO and simpler infrastructure.

### Shared Design Tokens

```typescript
// packages/ui/theme.ts
export const theme = {
  colors: {
    primary: {
      50: '#eff6ff',
      500: '#3b82f6',
      900: '#1e3a8a',
    },
    secondary: {
      50: '#faf5ff',
      500: '#a855f7',
      900: '#581c87',
    },
  },
  typography: {
    fontFamily: {
      sans: ['Inter', 'sans-serif'],
      display: ['Cal Sans', 'sans-serif'],
    },
  },
  // ... more tokens
};
```

---

## 📊 Cross-Platform Analytics

### Unified Analytics Dashboard

```typescript
// packages/analytics/index.ts

export interface FinanceHubEvent {
  userId?: string;
  platform: 'invest' | 'credit';
  event: string;
  properties?: Record<string, any>;
  timestamp: Date;
}

export async function trackEvent(event: FinanceHubEvent) {
  // Send to multiple analytics platforms
  await Promise.all([
    trackGoogleAnalytics(event),
    trackMixpanel(event),
    trackPostHog(event),
    saveToDatabase(event),
  ]);
}

// Unified metrics
export async function getUnifiedMetrics(userId: string) {
  return {
    invest: {
      calculationsCompleted: await getCalcMetrics(userId),
      brokerSignups: await getBrokerConversions(userId),
    },
    credit: {
      comparisonsViewed: await getCreditMetrics(userId),
      cardApplications: await getCardConversions(userId),
    },
    combined: {
      totalRevenue: await getTotalRevenue(userId),
      ltv: await calculateLTV(userId),
    },
  };
}
```

---

## 🔄 Cross-Promotion Strategy

### In-App Cross-Promotion

#### calc → credit
```tsx
// After calculator result
<CrossPromoCard>
  <h3>Maximize Your Investment Contributions</h3>
  <p>Use a cashback credit card to earn 2-5% on everyday spending, then invest the rewards!</p>
  <Button href="/credit/investing-cards">
    Find the Best Card for Investors →
  </Button>
</CrossPromoCard>
```

#### credit → calc
```tsx
// After card comparison
<CrossPromoCard>
  <h3>Invest Your Credit Card Rewards</h3>
  <p>See how your cashback earnings could grow with dividend investing</p>
  <Button href="/invest/calculators/cashback-to-dividends">
    Calculate Your Potential →
  </Button>
</CrossPromoCard>
```

### Email Cross-Promotion

```typescript
// Smart segmentation
const segments = {
  calcUsersNoCreditVisit: {
    condition: 'Used calculator but never visited credit',
    email: 'credit-cards-for-investors.html',
    cta: 'Earn rewards on your contributions',
  },
  creditUsersNoCalcVisit: {
    condition: 'Compared cards but never used calculator',
    email: 'invest-your-rewards.html',
    cta: 'See what your cashback could become',
  },
};
```

---

## 💰 Unified Monetization

### Revenue Tracking Across Platforms

```typescript
interface UnifiedRevenue {
  invest: {
    brokerCommissions: number;
    premiumSubscriptions: number;
  };
  credit: {
    cardCommissions: number;
    leadGeneration: number;
  };
  crossPlatform: {
    bundleSubscriptions: number; // Premium access to both platforms
    enterpriseDeals: number;
  };
}
```

### Premium Tier Bundling

**Current:**
- calc Premium: $9.99/mo
- credit Premium: $9.99/mo

**New FinanceHub Premium:**
```
Free:
- 5 calculations/month
- Basic card comparisons
- Standard features

Premium ($14.99/mo):
- Unlimited calculations
- Advanced credit card analytics
- Both platforms included
- Save $5/mo vs separate
```

---

## 🚀 Migration Plan

### Phase 1: Foundation (Week 1-2)
- [ ] Set up monorepo structure
- [ ] Create shared packages (auth, database, ui)
- [ ] Set up unified database
- [ ] Configure Turborepo

### Phase 2: Authentication (Week 3-4)
- [ ] Implement NextAuth in packages/auth
- [ ] Migrate calc from Supabase
- [ ] Unify user tables
- [ ] Test SSO across platforms

### Phase 3: Database Consolidation (Week 5-6)
- [ ] Migrate calc data to unified schema
- [ ] Merge credit data
- [ ] Set up data sync scripts
- [ ] Test data integrity

### Phase 4: Cross-Platform Features (Week 7-10)
- [ ] Build unified dashboard
- [ ] Implement cross-promotion components
- [ ] Unified analytics setup
- [ ] Shared affiliate tracking

### Phase 5: Launch (Week 11-12)
- [ ] Deploy to financehub.com
- [ ] Set up redirects from old domains
- [ ] Launch marketing campaign
- [ ] Monitor and optimize

---

## 📈 Expected Impact

### Traffic
- Combined SEO authority
- Cross-platform internal linking
- 2x content library

### Conversion
- Cross-sell opportunities
- Bundled premium offering
- Better user retention

### Revenue (Year 1)
```
Current (Separate):
- calc: $10K MRR
- credit: $15K MRR
Total: $25K MRR

Integrated (FinanceHub):
- Invest platform: $15K MRR (+50% from cross-sell)
- Credit platform: $20K MRR (+33% from cross-sell)
- Bundle subscriptions: $5K MRR (new)
Total: $40K MRR (+60% increase)
```

---

## ⚠️ Risks & Mitigation

### Technical Risks
**Risk:** Complex migration breaks existing features
**Mitigation:**
- Gradual migration, one feature at a time
- Maintain old systems in parallel
- Comprehensive testing

### Brand Risks
**Risk:** Users don't understand combined platform
**Mitigation:**
- Clear messaging: "Two powerful tools, one platform"
- Separate landing pages initially
- Gradual integration

### SEO Risks
**Risk:** Domain migration loses rankings
**Mitigation:**
- Use 301 redirects
- Keep same URL structure where possible
- Submit new sitemap immediately

---

## 💡 Key Success Factors

1. **Maintain Quality** - Don't sacrifice features for integration
2. **User Communication** - Clearly explain benefits of combination
3. **Gradual Rollout** - Don't change everything at once
4. **Measure Everything** - Track impact of every change
5. **Preserve What Works** - Keep successful features from both platforms

---

## 🎯 Next Actions

**This Week:**
1. ✅ Set up monorepo structure
2. ✅ Create shared packages
3. ✅ Design unified database schema
4. ✅ Plan authentication migration

**This Month:**
1. Implement NextAuth integration
2. Build unified dashboard MVP
3. Create cross-promotion components
4. Test with beta users

**This Quarter:**
1. Full platform migration
2. Launch FinanceHub brand
3. Unified premium offering
4. Cross-platform growth campaigns

---

**Remember:** Integration is a marathon, not a sprint. Focus on maintaining current revenue while building for the future.
