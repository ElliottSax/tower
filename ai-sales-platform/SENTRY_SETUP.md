# 🔍 Sentry Setup - AI Sales Platform

## Quick Start

### 1. Get Your Sentry DSN

1. Go to https://sentry.io and create a free account
2. Create a new project:
   - Platform: **Node.js**
   - Project name: **AI Sales Platform**
3. Copy the DSN (looks like: `https://abc123@o456.ingest.sentry.io/789`)

### 2. Add to Environment

Add to your `.env` file:

```bash
SENTRY_DSN=https://your-key-here@o123456.ingest.sentry.io/7890123
```

### 3. Start the Server

```bash
npm run dev
```

You should see:
```
✅ Sentry initialized for error monitoring
```

### 4. Test Error Tracking

Trigger a test error:

```bash
curl -X POST http://localhost:3000/api/agent/execute \
  -H "Content-Type: application/json" \
  -d '{"invalid": "data"}'
```

Check your Sentry dashboard - you should see the error!

## Features Enabled

- ✅ Automatic error capture on all endpoints
- ✅ Performance monitoring with transactions
- ✅ Request context (URL, method, body)
- ✅ Stack traces with source maps
- ✅ User context (when authenticated)
- ✅ Custom tags and breadcrumbs
- ✅ Graceful degradation (works without DSN)

## Usage Examples

### Basic Error Tracking

```typescript
import { captureException } from './lib/sentry';

try {
  await riskyOperation();
} catch (error) {
  captureException(error, {
    operation: 'create-campaign',
    business: { id: businessId }
  });
}
```

### Performance Monitoring

```typescript
import { startTransaction } from './lib/sentry';

const transaction = startTransaction('ai-workflow', 'agent');

try {
  const result = await supervisorAgent.execute(task);
  transaction.setStatus('ok');
  return result;
} finally {
  transaction.finish();
}
```

### Add Context

```typescript
import { addBreadcrumb, setUser } from './lib/sentry';

// Track user actions
addBreadcrumb({
  category: 'business',
  message: 'Created new business',
  data: { name: businessName }
});

// Set user context
setUser({
  id: userId,
  email: userEmail
});
```

## Configuration

Sentry is configured in `src/lib/sentry.ts`:

- **Production**: 10% trace sampling, full error capture
- **Development**: 100% trace sampling, full error capture
- **Privacy**: Cookies and sensitive headers removed automatically

## Dashboard

Visit your Sentry dashboard to see:

- **Issues**: All errors grouped by type
- **Performance**: API endpoint latency and throughput
- **Releases**: Track errors by deployment
- **Alerts**: Get notified of new issues

## Next Steps

1. Set up Slack/email alerts in Sentry
2. Create releases for deployment tracking
3. Add custom tags for better filtering
4. Set up performance budgets

---

**Cost**: FREE up to 5,000 events/month
**Setup time**: 5 minutes
**Value**: Catch bugs before users report them! 🐛
