# 🔍 Sentry Integration Guide - Both Projects

**Date**: February 3, 2026
**Projects**: AI Sales Platform + Church Website
**Status**: ✅ Configuration Complete - Awaiting Environment Variables

---

## 🎯 Overview

Sentry has been integrated into both projects to provide:
- **Error Monitoring**: Automatic capture and tracking of errors
- **Performance Monitoring**: Transaction tracing and performance metrics
- **User Context**: Track which users experience issues
- **Breadcrumbs**: Detailed debugging context
- **Release Tracking**: Track errors by deployment version

---

## 📦 What Was Installed

### AI Sales Platform
```bash
@sentry/node             # Node.js SDK
@sentry/profiling-node   # Performance profiling
```

### Church Website
```bash
@sentry/nextjs          # Next.js SDK (includes browser + server)
```

---

## 📁 Files Created

### AI Sales Platform

**Configuration:**
- `src/lib/sentry.ts` - Sentry initialization and utilities

**Modified:**
- `src/index.ts` - Added Sentry initialization and error tracking
- `.env.example` - Added SENTRY_DSN variable

### Church Website

**Configuration:**
- `sentry.client.config.ts` - Browser-side configuration
- `sentry.server.config.ts` - Server-side configuration
- `sentry.edge.config.ts` - Edge runtime configuration
- `instrumentation.ts` - Next.js instrumentation hook
- `lib/sentry.ts` - Helper utilities

**Modified:**
- `next.config.js` - Added Sentry webpack configuration
- `.env.local.example` - Added Sentry environment variables

---

## 🔧 Setup Instructions

### Step 1: Create Sentry Account

1. Go to https://sentry.io
2. Sign up for free account (5,000 events/month free)
3. Create a new project

**AI Platform:**
- Choose "Node.js" as platform
- Name: "AI Sales Platform"

**Church Website:**
- Choose "Next.js" as platform
- Name: "Church Website"

### Step 2: Get DSN Keys

After creating each project, Sentry will show you a DSN (Data Source Name).

Example format:
```
https://1234567890abcdef@o123456.ingest.sentry.io/7890123
```

### Step 3: Configure Environment Variables

#### AI Sales Platform

Add to `.env`:
```bash
SENTRY_DSN=https://your-dsn-here@sentry.io/project-id
```

#### Church Website

Add to `.env.local`:
```bash
# Server-side (required)
SENTRY_DSN=https://your-dsn-here@sentry.io/project-id

# Client-side (required)
NEXT_PUBLIC_SENTRY_DSN=https://your-dsn-here@sentry.io/project-id

# Optional: For source map uploads
SENTRY_ORG=your-org-name
SENTRY_PROJECT=church-website
SENTRY_AUTH_TOKEN=your-auth-token
```

### Step 4: Verify Installation

#### AI Platform

```bash
cd /mnt/e/projects/ai-sales-platform

# Start the server
npm run dev

# Test error tracking
curl -X POST http://localhost:3000/api/agent/execute \
  -H "Content-Type: application/json" \
  -d '{}'

# Should see error in Sentry dashboard
```

#### Church Website

```bash
cd /mnt/e/projects/church

# Start the dev server
npm run dev

# Visit http://localhost:3000
# Any errors will be captured by Sentry
```

---

## 💡 Usage Examples

### AI Sales Platform

#### Automatic Error Tracking

All errors in API routes are automatically captured:

```typescript
// src/index.ts
app.post('/api/agent/execute', async (req, res) => {
  const transaction = startTransaction('agent.execute', 'http');

  try {
    const result = await supervisorAgent.execute(req.body);
    res.json(result);
    transaction.setStatus('ok');
  } catch (error) {
    // Automatically captured by Sentry
    captureException(error, {
      task: req.body.task,
      lead: req.body.lead?.email,
    });
    transaction.setStatus('internal_error');
    res.status(500).json({ error: error.message });
  } finally {
    transaction.finish();
  }
});
```

#### Manual Error Tracking

```typescript
import { captureException, addBreadcrumb } from './lib/sentry';

// Add breadcrumb for context
addBreadcrumb({
  category: 'ai-agent',
  message: 'Starting worker execution',
  level: 'info',
  data: { worker: 'ads', task: 'create-campaign' }
});

try {
  await worker.execute();
} catch (error) {
  // Capture with additional context
  captureException(error, {
    worker: 'ads',
    business: { id: businessId, name: businessName }
  });
}
```

#### Performance Monitoring

```typescript
import { startTransaction } from './lib/sentry';

const transaction = startTransaction('waterfall-enrichment', 'data');

try {
  // Enrich lead data
  const result = await waterfallEnrich(email);
  transaction.setStatus('ok');
  return result;
} catch (error) {
  transaction.setStatus('internal_error');
  throw error;
} finally {
  transaction.finish();
}
```

### Church Website

#### API Routes

```typescript
// app/api/donations/route.ts
import { withSentry, captureException } from '@/lib/sentry';

export const POST = withSentry(async (req: Request) => {
  try {
    const body = await req.json();
    const result = await processDonation(body);
    return NextResponse.json(result);
  } catch (error) {
    captureException(error, {
      donation: body,
      stripe_customer: customerId
    });
    throw error;
  }
});
```

#### Server Actions

```typescript
// app/actions/prayer-requests.ts
'use server'

import { withServerAction } from '@/lib/sentry';

export const submitPrayerRequest = withServerAction(async (formData: FormData) => {
  const name = formData.get('name');
  const request = formData.get('request');

  // Your logic here
  await savePrayerRequest({ name, request });

  return { success: true };
});
```

#### React Components

```typescript
// components/DonationForm.tsx
'use client'

import { captureException, addBreadcrumb } from '@/lib/sentry';

export function DonationForm() {
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    addBreadcrumb({
      category: 'donation',
      message: 'User initiated donation',
      data: { amount: formData.amount }
    });

    try {
      await submitDonation(formData);
    } catch (error) {
      captureException(error, {
        donation: formData,
        user: { id: user.id }
      });
    }
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

#### User Context

```typescript
// app/api/auth/[...nextauth]/route.ts
import { setUser, clearUser } from '@/lib/sentry';

// On login
callbacks: {
  async signIn({ user }) {
    setUser({
      id: user.id,
      email: user.email,
      username: user.name
    });
    return true;
  },

  async signOut() {
    clearUser();
    return true;
  }
}
```

---

## 📊 Sentry Dashboard Features

### 1. Issues Tab
- View all errors grouped by type
- See frequency, last occurrence, affected users
- Stack traces with source maps
- User feedback and comments

### 2. Performance Tab
- Transaction traces
- Slowest endpoints
- Database query performance
- API latency

### 3. Releases Tab
- Track errors by deployment version
- Compare error rates between releases
- Automatic regression detection

### 4. Alerts
- Set up email/Slack alerts for:
  - New errors
  - Error spike detection
  - Performance degradation
  - Custom conditions

---

## 🎯 Best Practices

### 1. Add Context to Errors

Always include relevant context:
```typescript
captureException(error, {
  user: { id: userId, email: userEmail },
  business: { id: businessId, name: businessName },
  operation: 'create-campaign',
  metadata: { budget: 1000, channels: ['facebook', 'google'] }
});
```

### 2. Use Breadcrumbs

Add breadcrumbs before operations:
```typescript
addBreadcrumb({
  category: 'navigation',
  message: 'User navigated to donations page'
});

addBreadcrumb({
  category: 'action',
  message: 'Form submitted',
  data: { amount: 100 }
});
```

### 3. Set User Context

Always set user context after authentication:
```typescript
setUser({
  id: user.id,
  email: user.email,
  username: user.name
});
```

### 4. Tag Errors

Use tags for filtering:
```typescript
setTag('feature', 'payment');
setTag('provider', 'stripe');
setTag('environment', 'production');
```

### 5. Monitor Performance

Wrap critical operations:
```typescript
const transaction = startTransaction('critical-operation', 'task');
try {
  await performOperation();
  transaction.setStatus('ok');
} finally {
  transaction.finish();
}
```

---

## 🔒 Security & Privacy

### Data Sanitization

Both configurations automatically:
- Remove cookies from requests
- Redact authorization headers
- Filter sensitive query parameters
- Remove passwords and tokens

### Additional Filters

```typescript
// In sentry config
beforeSend(event) {
  // Remove sensitive data
  if (event.request) {
    delete event.request.cookies;
    delete event.request.headers?.authorization;
  }

  // Sanitize user data
  if (event.user?.email) {
    event.user.email = event.user.email.replace(/./g, '*');
  }

  return event;
}
```

---

## 📈 Sample Rates

### Development
- Traces: 100% (all transactions)
- Replays: 10% (session replay)

### Production
- Traces: 10% (10% of transactions)
- Replays: 1% (minimize performance impact)

Adjust in config files:
```typescript
tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
```

---

## 🚀 Next Steps

### 1. Configure Environment Variables
- [ ] Add SENTRY_DSN to AI Platform `.env`
- [ ] Add SENTRY_DSN to Church `.env.local`
- [ ] Add NEXT_PUBLIC_SENTRY_DSN to Church `.env.local`

### 2. Test Error Tracking
- [ ] Trigger test error in AI Platform
- [ ] Trigger test error in Church website
- [ ] Verify errors appear in Sentry dashboard

### 3. Set Up Alerts
- [ ] Configure email alerts for new issues
- [ ] Set up Slack integration (optional)
- [ ] Configure performance alerts

### 4. Source Maps (Church Only)
- [ ] Get Sentry auth token
- [ ] Add SENTRY_AUTH_TOKEN to `.env.local`
- [ ] Test production build with source maps

### 5. Releases
- [ ] Set up CI/CD to create releases
- [ ] Tag deploys in Sentry
- [ ] Enable release health monitoring

---

## 📝 Quick Reference

### AI Platform Commands
```bash
# Check Sentry initialization
npm run dev | grep "Sentry"

# Test error tracking
npm run test

# View logs
tail -f logs/error.log
```

### Church Commands
```bash
# Check Sentry config
npm run build

# Test in development
npm run dev

# Test production build
npm run build && npm start
```

---

## 🐛 Troubleshooting

### Sentry Not Capturing Errors

1. **Check DSN is set:**
   ```bash
   echo $SENTRY_DSN
   ```

2. **Check initialization:**
   - AI Platform: Look for "Sentry initialized" log
   - Church: Check browser console for Sentry logs

3. **Check sample rate:**
   - Errors: Always 100%
   - Performance: May be sampled

### Source Maps Not Working (Church)

1. Ensure auth token is set
2. Check `SENTRY_ORG` and `SENTRY_PROJECT`
3. Verify build logs show "Uploading source maps"

### Performance Issues

1. Reduce sample rates in production
2. Disable session replay if needed
3. Use `beforeSend` to filter noisy errors

---

## 📞 Support Resources

- **Sentry Docs**: https://docs.sentry.io
- **Node.js Guide**: https://docs.sentry.io/platforms/node/
- **Next.js Guide**: https://docs.sentry.io/platforms/javascript/guides/nextjs/
- **Community**: https://discord.gg/sentry

---

## ✅ Status

**AI Sales Platform:**
- ✅ Configuration complete
- ✅ Error tracking integrated
- ✅ Performance monitoring added
- ⏳ Awaiting SENTRY_DSN environment variable

**Church Website:**
- ✅ Configuration complete
- ✅ Client/Server/Edge configs created
- ✅ Helper utilities added
- ✅ Instrumentation hook set up
- ⏳ Awaiting SENTRY_DSN environment variables

---

## 🎉 Summary

Both projects now have production-ready error monitoring and performance tracking with Sentry. Simply add the DSN environment variables to start capturing errors and monitoring performance in real-time!

**Total time to integrate**: ~15 minutes per project
**Monthly cost**: FREE (5,000 events/month)
**Value**: Priceless (catch bugs before users report them)

---

**Built with care, monitored with Sentry.** 🔍✨
