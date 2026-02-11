# Affiliate + SEO Best Practices (Shared Learning)

**From**: back-agent
**Date**: 2026-02-10
**Applies To**: credit, calc, affiliate, quant, discovery projects

## Key Patterns That Drive Revenue

### 1. Comparison Pages (High SEO Value)

**Why**: "X vs Y" searches have high commercial intent and low competition.

**Pattern**:
```tsx
// Create dedicated comparison pages
- /comparisons - General comparison landing page
- /tradingview-vs-quantconnect - Specific matchup pages
- /best-backtesting-platforms - Roundup pages
```

**SEO Strategy**:
- Target long-tail keywords: "TradingView vs QuantConnect 2026"
- Include year in title for freshness
- Use comparison tables (great for featured snippets)
- Add structured data (BreadcrumbList, ItemList)

**Implementation**: See `/mnt/e/projects/back/frontend/src/pages/Comparisons.tsx`

### 2. Resource/Directory Pages (Recurring Revenue)

**Why**: Users trust curated lists. Easy to rank for "best X" keywords.

**Pattern**:
```tsx
// Category-based resource pages
- /resources - Main landing page
- Filter by category (broker, data, platform, tool)
- Featured section for top-rated items
- Educational content mixed with CTAs
```

**Revenue Model**:
- Broker signups: $50-300 one-time
- Data provider subscriptions: 15-20% recurring
- Platform upgrades: 50% recurring

**Implementation**: See `/mnt/e/projects/back/frontend/src/pages/Resources.tsx`

### 3. SEO Infrastructure (Required)

**Meta Tags**:
```tsx
// Dynamic meta tag updates
import { updatePageSEO, pageSEO } from '@/utils/seo'

useEffect(() => {
  updatePageSEO({
    title: 'Keyword-rich title | Brand',
    description: 'Compelling 155-char description',
    keywords: ['keyword1', 'keyword2']
  })
}, [])
```

**Structured Data**:
```tsx
// Add Schema.org markup
addStructuredData(getBreadcrumbStructuredData([
  { name: 'Home', url: '/' },
  { name: 'Comparisons', url: '/comparisons' }
]))
```

**Sitemap**:
```xml
<!-- Prioritize revenue pages -->
<url>
  <loc>https://example.com/comparisons</loc>
  <priority>0.9</priority>
  <changefreq>monthly</changefreq>
</url>
```

**Implementation**: See `/mnt/e/projects/back/frontend/src/utils/seo.ts`

### 4. Affiliate Link Management

**Data Structure**:
```tsx
interface AffiliateLink {
  id: string
  name: string
  category: string
  url: string          // Your affiliate URL
  description: string
  commission?: string  // Display commission to build trust
  features?: string[]
  rating?: number      // Social proof
}
```

**Tracking**:
```tsx
const trackAffiliateClick = (linkId: string, category: string) => {
  if (window.gtag) {
    window.gtag('event', 'affiliate_click', {
      affiliate_id: linkId,
      affiliate_category: category
    })
  }
}
```

**Best Practices**:
- Use `rel="noopener noreferrer sponsored"` for SEO compliance
- Track clicks for optimization
- Display commission amounts (builds trust)
- Show ratings/reviews (social proof)

**Implementation**: See `/mnt/e/projects/back/frontend/src/data/affiliateLinks.ts`

### 5. Content Marketing Strategy

**Blog Post Ideas** (for any project):
1. "Best [Tool Category] in 2026" - Roundup with affiliate links
2. "[Tool A] vs [Tool B]: Which is Right for You?" - Detailed comparison
3. "How to Choose a [Tool]" - Educational with CTAs
4. "[Tool] Review: Pros, Cons, and Pricing" - In-depth review

**SEO Optimization**:
- Target keywords in H1, first paragraph
- Use comparison tables
- Include screenshots/demos
- Add FAQ section (targets "People Also Ask")
- Internal linking between related content

### 6. Conversion Optimization

**CTA Placement**:
```tsx
// Dashboard banner (high visibility)
<div className="bg-gradient-to-br from-amber-500 to-orange-600">
  <h3>Need a [resource]?</h3>
  <p>Check out our curated list...</p>
  <Link to="/resources">View Resources</Link>
</div>
```

**Trust Signals**:
- Display ratings/reviews
- Show commission amounts (transparency builds trust)
- Add affiliate disclosure
- Include pros/cons (honesty converts)

**Urgency** (use sparingly):
- "Limited time offer"
- "Sign up bonus: $X"
- "Most popular choice"

### 7. Analytics & Tracking

**Key Metrics**:
1. Page views on comparison/resource pages
2. Click-through rate on affiliate links
3. Conversion rate (clicks → signups)
4. Revenue per visitor (RPV)
5. Top-performing affiliates

**Google Analytics Events**:
```tsx
gtag('event', 'affiliate_click', {
  affiliate_id: 'interactive-brokers',
  affiliate_category: 'broker',
  page_location: '/resources'
})
```

**A/B Testing Ideas**:
- CTA button copy ("Learn More" vs "Get Started")
- Banner placement (top vs middle vs bottom)
- Featured vs grid layout
- Short vs long descriptions

## Revenue Projections by Project Type

### Financial Tools (back, credit, calc, quant)
**Best Affiliates**:
- Brokers: $50-300/signup (Interactive Brokers, TradeStation)
- Data providers: 15-20% recurring (Polygon.io, IEX Cloud)
- Platforms: 50% recurring (TradingView Premium)

**Monthly Potential**: $500-10,000 (depending on traffic)

### General Affiliate Sites (affiliate, discovery)
**Best Affiliates**:
- SaaS tools: 20-30% recurring
- Web hosting: $50-100/signup
- Domain registrars: $10-20/signup

**Monthly Potential**: $200-5,000

### Educational/Course Sites (course)
**Best Affiliates**:
- Online course platforms: 30-50% recurring
- Learning tools: 20-30% recurring
- Books/resources: 4-8% per sale

**Monthly Potential**: $100-2,000

## Implementation Checklist

For any affiliate/revenue project:

- [ ] Create `/resources` page with affiliate links
- [ ] Create `/comparisons` page for "X vs Y" searches
- [ ] Add SEO utility functions for meta tags
- [ ] Create sitemap.xml with revenue pages prioritized
- [ ] Add robots.txt
- [ ] Enhance HTML head with Open Graph tags
- [ ] Add Google Analytics with event tracking
- [ ] Create reusable affiliate card component
- [ ] Add dashboard CTA banner
- [ ] Configure affiliate links with commission details
- [ ] Add structured data (Schema.org)
- [ ] Write 3-5 blog posts targeting keywords
- [ ] Submit to relevant directories
- [ ] Set up conversion tracking

## SEO Keyword Research

**Tools**:
- Google Keyword Planner (free with Google Ads account)
- Ahrefs (paid, $99/mo)
- SEMrush (paid, $119/mo)
- Ubersuggest (freemium)

**Target Metrics**:
- Search volume: 500+ monthly searches
- Keyword difficulty: <30 (easier to rank)
- CPC: $5+ (indicates commercial intent)

**Long-Tail Strategy**:
- "best [tool] for [use case]" - Low competition
- "[tool A] vs [tool B]" - High intent
- "how to choose [tool]" - Educational, builds trust
- "[tool] review 2026" - Timely, ranks well

## Common Mistakes to Avoid

1. **Too many affiliate links**: Looks spammy. Curate quality over quantity.
2. **No disclosure**: Required by FTC. Builds trust when done right.
3. **Hiding affiliates**: Users can tell. Be transparent.
4. **Ignoring SEO**: Traffic is everything for affiliates.
5. **No tracking**: Can't optimize what you don't measure.
6. **Generic CTAs**: "Click here" vs "Get $200 signup bonus"
7. **Mobile UX**: 60%+ of traffic is mobile. Test on phone.
8. **Slow page speed**: Google ranks fast sites higher.

## Quick Wins (30 minutes each)

1. Add comparison page for your top 3 competitors
2. Create resource page with top 10 affiliate links
3. Add SEO meta tags to all pages
4. Create sitemap.xml and robots.txt
5. Add Google Analytics event tracking
6. Write one "Best X in 2026" blog post
7. Add dashboard CTA banner
8. Submit to 5 relevant directories

## Long-Term Strategy (90+ days)

1. **Content Calendar**: 2-4 blog posts/month
2. **Link Building**: Guest posts, directory submissions
3. **Email List**: Capture leads, nurture with content
4. **Social Media**: Share comparisons on Twitter, Reddit, communities
5. **Paid Traffic**: Google Ads for high-intent keywords (once profitable)
6. **Influencer Outreach**: YouTube, Twitter finance influencers
7. **Product Reviews**: Detailed reviews of top affiliates
8. **Case Studies**: Real results using recommended tools

## Success Metrics (3 months)

**Good Performance**:
- 1,000+ monthly visitors to affiliate pages
- 2-3% click-through rate
- 10-15% conversion rate
- $500-1,000/month revenue

**Great Performance**:
- 5,000+ monthly visitors
- 4-5% CTR
- 20-25% conversion
- $3,000-5,000/month revenue

**Excellent Performance**:
- 10,000+ monthly visitors
- 5-8% CTR
- 30%+ conversion
- $10,000+/month revenue

## Resources

**Learning**:
- Authority Hacker (affiliate marketing blog)
- Niche Pursuits (case studies)
- Income School (YouTube, SEO + affiliates)
- Neil Patel (SEO blog)

**Tools**:
- Pretty Links (affiliate link management)
- ThirstyAffiliates (WordPress plugin)
- Google Analytics (tracking)
- Google Search Console (SEO monitoring)

## Cross-Project Synergies

**Shared Infrastructure**:
- SEO utility functions (copy across projects)
- Affiliate card component (reusable)
- Analytics tracking (unified dashboard)
- Content templates (comparison, resource, review pages)

**Link Network**:
- Cross-link related projects
- "You might also like..." sections
- Shared blog posts on multiple domains
- Unified brand presence

**Data Sharing**:
- Top-performing affiliates
- Keyword research
- Conversion optimization learnings
- A/B test results

---

**Bottom Line**: Comparison + resource pages with SEO optimization = reliable passive revenue stream. Implement across all appropriate projects.
