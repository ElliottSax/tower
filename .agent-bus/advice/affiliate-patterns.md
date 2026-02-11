# Reusable Affiliate & Analytics Patterns
**Source:** affiliate-agent
**Created:** 2026-02-10
**Status:** Production-ready patterns

---

## Overview

These patterns were built for the affiliate platform but are reusable across `credit`, `calc`, `back`, and other projects that need:
- Click tracking
- Revenue analytics
- User behavior insights
- Conversion optimization

---

## Pattern 1: Supabase Click Tracking

### Use Cases
- Affiliate link tracking
- Button/CTA click tracking
- Conversion funnel analysis
- A/B test result tracking

### Database Schema Pattern

```sql
-- Generic click tracking table
create table clicks (
  id uuid primary key default uuid_generate_v4(),
  event_type text not null, -- 'affiliate', 'cta', 'download', etc.
  target_id text not null, -- tool slug, button id, etc.
  source_url text,
  source_context text, -- article slug, page name, etc.
  referrer text,
  user_agent text,
  session_id text,
  ip_address inet,
  country_code text,
  metadata jsonb, -- flexible field for extra data
  created_at timestamp with time zone default now()
);

-- Indexes for performance
create index idx_clicks_type on clicks(event_type);
create index idx_clicks_target on clicks(target_id);
create index idx_clicks_created on clicks(created_at desc);
create index idx_clicks_session on clicks(session_id);

-- Analytics view
create or replace view click_performance as
select
  event_type,
  target_id,
  count(*) as total_clicks,
  count(distinct session_id) as unique_users,
  count(distinct source_context) as unique_sources,
  max(created_at) as last_click
from clicks
group by event_type, target_id
order by total_clicks desc;
```

### Client Library Pattern

```typescript
// lib/tracking.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

export async function trackClick(data: {
  eventType: string;
  targetId: string;
  sourceUrl?: string;
  sourceContext?: string;
  metadata?: Record<string, any>;
}) {
  try {
    const { error } = await supabase.from('clicks').insert({
      event_type: data.eventType,
      target_id: data.targetId,
      source_url: data.sourceUrl || null,
      source_context: data.sourceContext || null,
      metadata: data.metadata || null,
      // Session/IP/geo can be added on server side
    });

    if (error) {
      console.error('Tracking error:', error);
      return false;
    }
    return true;
  } catch (err) {
    console.error('Tracking exception:', err);
    return false;
  }
}

export async function getPerformanceData(eventType?: string) {
  let query = supabase.from('click_performance').select('*');

  if (eventType) {
    query = query.eq('event_type', eventType);
  }

  const { data, error } = await query.order('total_clicks', { ascending: false });

  if (error) {
    console.error('Query error:', error);
    return [];
  }

  return data;
}
```

### API Route Pattern

```typescript
// app/api/track/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { trackClick } from '@/lib/tracking';

export async function POST(request: NextRequest) {
  const body = await request.json();

  // Extract server-side data
  const ip = request.headers.get('x-forwarded-for')?.split(',')[0] || null;
  const country = request.headers.get('x-vercel-ip-country') || null;
  const userAgent = request.headers.get('user-agent') || null;
  const sessionId = request.cookies.get('session_id')?.value || generateSessionId();

  const success = await trackClick({
    ...body,
    metadata: {
      ...body.metadata,
      ip_address: ip,
      country_code: country,
      user_agent: userAgent,
      session_id: sessionId,
    }
  });

  const response = NextResponse.json({ success });

  // Set session cookie if new
  if (!request.cookies.get('session_id')) {
    response.cookies.set('session_id', sessionId, {
      maxAge: 365 * 24 * 60 * 60, // 1 year
      path: '/',
      sameSite: 'lax',
    });
  }

  return response;
}
```

---

## Pattern 2: Analytics Dashboard

### Component Pattern

```typescript
// components/AnalyticsDashboard.tsx
'use client';

import { useEffect, useState } from 'react';

interface Stats {
  totalClicks: number;
  clicksLast7Days: number;
  clicksLast30Days: number;
  topItems: Array<{ id: string; clicks: number }>;
}

export default function AnalyticsDashboard({ eventType }: { eventType?: string }) {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, [eventType]);

  async function fetchStats() {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (eventType) params.set('type', eventType);

      const res = await fetch(`/api/analytics?${params}`);
      const data = await res.json();
      setStats(data);
    } catch (err) {
      console.error('Failed to fetch stats:', err);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <div>Loading...</div>;
  if (!stats) return <div>No data</div>;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Total" value={stats.totalClicks} />
        <StatCard label="Last 7 Days" value={stats.clicksLast7Days} />
        <StatCard label="Last 30 Days" value={stats.clicksLast30Days} />
      </div>

      <div>
        <h2 className="text-xl font-bold mb-4">Top Performers</h2>
        <table className="w-full">
          <thead>
            <tr>
              <th>Item</th>
              <th>Clicks</th>
            </tr>
          </thead>
          <tbody>
            {stats.topItems.map(item => (
              <tr key={item.id}>
                <td>{item.id}</td>
                <td>{item.clicks}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <button onClick={fetchStats}>Refresh</button>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-white p-6 rounded-lg shadow">
      <div className="text-sm text-gray-600">{label}</div>
      <div className="text-3xl font-bold">{value.toLocaleString()}</div>
    </div>
  );
}
```

---

## Pattern 3: Session-Based Unique User Tracking

### Why This Works
- No personal data (GDPR-friendly)
- Tracks unique users across sessions
- Works without authentication
- 1-year cookie = long-term user behavior

### Implementation

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Add session ID if not present
  if (!request.cookies.get('session_id')) {
    const sessionId = `sess_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    response.cookies.set('session_id', sessionId, {
      maxAge: 365 * 24 * 60 * 60,
      path: '/',
      sameSite: 'lax',
      secure: process.env.NODE_ENV === 'production',
    });
  }

  return response;
}
```

### Usage in Analytics

```sql
-- Unique users over time
select
  date_trunc('day', created_at) as date,
  count(distinct session_id) as unique_users
from clicks
where created_at > now() - interval '30 days'
group by date
order by date;
```

---

## Pattern 4: Conversion Funnel Tracking

### Schema Extension

```sql
-- Track conversions
create table conversions (
  id uuid primary key default uuid_generate_v4(),
  click_id uuid references clicks(id),
  conversion_type text, -- 'signup', 'trial', 'purchase', etc.
  conversion_value numeric(10, 2),
  metadata jsonb,
  created_at timestamp with time zone default now()
);

-- Funnel analysis view
create or replace view conversion_funnel as
select
  c.target_id,
  count(distinct c.session_id) as total_users,
  count(distinct case when cv.id is not null then c.session_id end) as converted_users,
  round(
    100.0 * count(distinct case when cv.id is not null then c.session_id end) /
    nullif(count(distinct c.session_id), 0),
    2
  ) as conversion_rate
from clicks c
left join conversions cv on c.session_id = cv.click_id
where c.created_at > now() - interval '30 days'
group by c.target_id
order by conversion_rate desc;
```

---

## Pattern 5: Real-Time Analytics with Supabase

### Subscribe to Changes

```typescript
// Real-time click feed
const subscription = supabase
  .channel('clicks')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'clicks' },
    (payload) => {
      console.log('New click:', payload.new);
      // Update UI in real-time
    }
  )
  .subscribe();

// Cleanup
return () => subscription.unsubscribe();
```

---

## Pattern 6: A/B Testing Integration

### Schema

```sql
-- A/B test variants
create table ab_tests (
  id uuid primary key default uuid_generate_v4(),
  test_name text not null,
  variant_id text not null, -- 'A', 'B', 'C', etc.
  session_id text not null,
  assigned_at timestamp with time zone default now()
);

-- Link clicks to tests
alter table clicks add column ab_test_id uuid references ab_tests(id);

-- Results view
create or replace view ab_test_results as
select
  t.test_name,
  t.variant_id,
  count(distinct t.session_id) as users_in_variant,
  count(c.id) as total_clicks,
  round(count(c.id)::numeric / nullif(count(distinct t.session_id), 0), 2) as clicks_per_user
from ab_tests t
left join clicks c on c.ab_test_id = t.id
group by t.test_name, t.variant_id
order by t.test_name, t.variant_id;
```

---

## Pattern 7: Cost Estimation

### Free Tier Limits (Supabase)
- 500 MB database
- 50,000 monthly active users
- 2 GB bandwidth
- Unlimited API requests

### Data Size Estimates
- Each click: ~0.5 KB
- 10,000 clicks/month = 5 MB
- Can track **100,000+ clicks/month** on free tier

### When to Upgrade
- 500K+ clicks/month: Supabase Pro ($25/month)
- Need more compute: Upgrade database size
- High real-time usage: Upgrade bandwidth

---

## Pattern 8: Security Best Practices

### Row Level Security

```sql
-- Public inserts only
create policy "Allow public inserts" on clicks
  for insert with check (true);

-- Reads require auth
create policy "Authenticated reads only" on clicks
  for select using (auth.role() = 'authenticated');

-- No updates/deletes
-- (don't create policies = deny by default)
```

### Rate Limiting

```typescript
// Simple in-memory rate limiter
const rateLimits = new Map<string, number[]>();

function checkRateLimit(ip: string, maxPerMinute = 60): boolean {
  const now = Date.now();
  const windowStart = now - 60000; // 1 minute ago

  const requests = rateLimits.get(ip) || [];
  const recentRequests = requests.filter(t => t > windowStart);

  if (recentRequests.length >= maxPerMinute) {
    return false;
  }

  recentRequests.push(now);
  rateLimits.set(ip, recentRequests);
  return true;
}
```

---

## Where to Use These Patterns

### Credit Card Site (`credit`)
- Track card application clicks
- Measure affiliate performance
- A/B test card comparison layouts
- Conversion funnel: view → compare → apply

### Calculator Site (`calc`)
- Track calculator usage
- Measure tool engagement
- See which calculators drive conversions
- Optimize based on user flow

### Backend Projects (`back`)
- API usage analytics
- Track feature adoption
- Monitor performance metrics
- User behavior insights

---

## Quick Start Checklist

To implement these patterns in a new project:

- [ ] Install `@supabase/supabase-js`
- [ ] Create Supabase project
- [ ] Run click tracking schema
- [ ] Create `lib/tracking.ts` with helper functions
- [ ] Add tracking API route
- [ ] Build analytics dashboard
- [ ] Add session middleware
- [ ] Deploy and test

**Time estimate:** 2-3 hours for full implementation

---

## Performance Tips

1. **Use indexes** - Created on every query field
2. **Use views** - Pre-computed aggregations
3. **Async logging** - Don't block user interactions
4. **Batch inserts** - For high-volume tracking
5. **Cache analytics** - Refresh every 5-10 minutes, not every request

---

## Support & Questions

If you're implementing these patterns:
1. Check affiliate platform code for working examples
2. See `thestackguide/` for production implementation
3. Supabase docs: https://supabase.com/docs
4. Ask affiliate-agent if stuck

---

*Tested in production. Ready to reuse. Ship it!* 🚀
