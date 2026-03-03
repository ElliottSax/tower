# Poll - Political Polling Aggregator (MVP)

## 🎯 Core Mission
Build a **clean, fast, beautiful** RealClearPolitics clone focused on polling data aggregation and visualization.

## MVP Scope (Core Features Only)

### 1. Polling Data Ingestion ✅
- Scrape public polling sources (RCP, FiveThirtyEight)
- Parse and normalize poll data
- Store in PostgreSQL/Supabase

### 2. Weighted Polling Averages ✅
- Calculate averages by pollster rating
- Weight by recency and sample size
- Display polling trends over time

### 3. Interactive Charts & Maps ✅
- Responsive trend charts (Recharts)
- Electoral maps (D3/Mapbox)
- Race-by-race visualizations

### 4. Race Pages ✅
- Presidential races
- Senate races
- Governor races
- House races
- Clean, fast-loading detail pages

### 5. Pollster Ratings ✅
- Pollster accuracy scores
- Methodology pages
- Transparency ratings

### 6. Beautiful UI ✅
- Professional, clean design
- Fast page loads
- Mobile-responsive
- Dark/light theme support

### 7. SEO Optimization 🚧
- Political keyword optimization
- Meta tags and descriptions
- Sitemap generation

### 8. Production Deployment 🚧
- Vercel (frontend)
- Supabase (database)
- Simple, cost-effective hosting

## Technology Stack

**Frontend:**
- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Recharts/D3 for visualizations
- React Query for data fetching

**Backend:**
- Fastify API
- Prisma ORM
- PostgreSQL/Supabase
- Axios + Cheerio for scraping

**Infrastructure:**
- Vercel deployment
- Supabase managed PostgreSQL
- No Redis, no WebSockets, no job queues (keep it simple!)

## What's NOT in MVP

❌ User accounts and authentication
❌ Candidate-specific trackers (Trump tracker, etc.)
❌ Scenario modeling ("what-if" features)
❌ Real-time WebSocket updates
❌ Email notifications
❌ Background job queues
❌ Admin panels
❌ Performance monitoring dashboards

**These features are archived in `archive/full-platform` branch for future consideration.**

## Development Commands

```bash
# Install dependencies
npm install

# Run API in development
cd apps/api && npm run dev

# Run web app in development
cd apps/web && npm run dev

# Build for production
npm run build

# Run tests
npm test
```

## Project Structure

```
poll/
├── apps/
│   ├── api/          # Fastify backend
│   │   ├── src/
│   │   │   ├── routes/       # API endpoints
│   │   │   ├── services/     # Business logic
│   │   │   ├── middleware/   # Error handling, logging
│   │   │   └── utils/        # Helpers
│   │   └── package.json
│   └── web/          # Next.js frontend
│       ├── app/              # App router pages
│       ├── components/       # React components
│       └── lib/              # Utilities
└── packages/
    └── database/     # Prisma schema
```

## API Endpoints (Core Only)

- `GET /health` - Health check
- `GET /api/races` - List all races
- `GET /api/races/:slug` - Race details
- `GET /api/polls` - List polls with filters
- `GET /api/polls/:id` - Poll details
- `GET /api/pollsters` - List pollsters
- `GET /api/pollsters/:slug` - Pollster details
- `GET /api/forecasts/presidential` - Presidential forecast
- `GET /api/forecasts/senate` - Senate forecast

## Success Criteria

1. ✅ Clean, professional UI matching RCP quality
2. ✅ Fast page loads (<2s initial, <500ms navigations)
3. 🚧 Accurate polling averages
4. 🚧 SEO-optimized for political keywords
5. 🚧 Mobile-responsive across all pages
6. 🚧 Deployed and live in production
7. 🚧 Zero runtime errors in production

## Next Steps

1. **Polish UI** - Ensure all pages look professional
2. **Improve SEO** - Add meta tags, sitemaps
3. **Test thoroughly** - Cross-browser, mobile testing
4. **Deploy** - Get it live on Vercel + Supabase
5. **Gather feedback** - Real users, real data
6. **Iterate** - Add features based on actual usage

## Communication

- Update `/mnt/e/projects/.agent-bus/status/poll.md` each cycle
- Keep CLAUDE.md focused on MVP scope only
- No feature creep - stay disciplined!

---

**Remember:** Ship the MVP first. Add features based on real user feedback, not speculation.
