# ⚡ PARALLEL E-E-A-T EXECUTION PLAN
**Target**: All 4 sites in 16-20 hours
**Approach**: Work on each site simultaneously
**Focus**: Expertise signals, remove salesy content, no team bios

---

## PHASE 1: SEARCH & REMOVE (Hours 1-3)

### Credit Site (creditrewardsmax.com)
**Search for & comment out:**
```
1. grep -r "Featured Credit Cards" /mnt/e/projects/credit
2. grep -r "Popular picks" /mnt/e/projects/credit
3. grep -r "Get Started\|Apply Now\|Limited Time" /mnt/e/projects/credit
4. Find exit-intent modals in components/
5. Find broker recommendation CTAs
```

**Comment out:**
- [ ] /app/page.tsx - Featured Credit Cards section
- [ ] ExitIntentModal.tsx - Comment out entire component usage
- [ ] Card comparison CTAs - "Get" → "Learn"
- [ ] Any "Limited offer" language

### Affiliate Site (theStackGuide.com)
**Search for & comment out:**
```
1. grep -r "discount\|partner offer" /mnt/e/projects/affiliate/thestackguide
2. grep -r "Try.*affiliate" --include="*.tsx"
3. grep -r "Get [0-9]%" (discount mentions)
4. Find commission/affiliate language
```

**Comment out:**
- [ ] Discount CTAs
- [ ] "Limited time partner offer" sections
- [ ] Affiliate program mentions
- [ ] Commission-based language

### Calc Site (calc)
**Search for & comment out:**
```
1. grep -r "broker\|open account" /mnt/e/projects/calc
2. grep -r "Ready to.*start" --include="*.tsx"
3. Find broker recommendation tables
```

**Comment out:**
- [ ] Broker comparison CTAs
- [ ] "Open Account" buttons
- [ ] Broker recommendation sections
- [ ] "Get Started" investment CTAs

### Quant Site (quant)
**Search for & comment out:**
```
1. grep -r "sign up\|get started\|join" /mnt/e/projects/quant
2. grep -r "exclusive\|premium" --include="*.tsx"
```

**Comment out:**
- [ ] "Join" CTAs
- [ ] Premium/exclusive messaging
- [ ] Signup pushes
- [ ] Any sales-y language

---

## PHASE 2: ADD METHODOLOGY (Hours 4-8)

### Credit Site
**Create/Update:**
- [ ] `/methodology` page - Card review criteria
- [ ] `/data-sources` - Issuer websites, databases used
- [ ] `/corrections-policy` - Error reporting
- [ ] Add to each article:
  - Data update date
  - Sources used
  - How card was evaluated

**File locations:**
- `app/methodology/page.tsx` (create)
- `app/data-sources/page.tsx` (create)
- `app/corrections/page.tsx` (create)
- `app/blog/[slug]/page.tsx` (add metadata)

### Affiliate Site
**Create/Update:**
- [ ] `/testing-methodology` - How we test tools
- [ ] `/sources` - Tool verification sources
- [ ] `/corrections-policy` - Error reporting
- [ ] Add to each tool review:
  - Last tested date
  - Testing methodology
  - Verification sources

**File locations:**
- `app/testing-methodology/page.tsx` (create)
- `app/sources/page.tsx` (create)
- `app/corrections/page.tsx` (create)
- Tool pages - add metadata

### Calc Site
**Create/Update:**
- [ ] `/calculator-methodology` - Formula + sources
- [ ] `/data-sources` - IRS, Treasury, market data
- [ ] `/corrections-policy` - Error reporting
- [ ] Add to each calculator:
  - Data sources
  - Last verified date
  - Calculation assumptions

**File locations:**
- `app/methodology/page.tsx` (create)
- `app/data-sources/page.tsx` (create)
- `app/corrections/page.tsx` (create)
- Calculator pages - add schema

### Quant Site
**Create/Update:**
- [ ] `/strategy-validation` - Backtesting methodology
- [ ] `/research-references` - Academic citations
- [ ] `/corrections-policy` - Error reporting
- [ ] Add to each strategy:
  - Research papers cited
  - Backtesting details
  - Risk disclosure

**File locations:**
- `app/methodology/page.tsx` (create)
- `app/research/page.tsx` (create)
- `app/corrections/page.tsx` (create)
- Strategy pages - add citations

---

## PHASE 3: SCHEMA MARKUP (Hours 9-12)

### All Sites - Organization Schema
Add to `app/layout.tsx`:
```typescript
const organizationSchema = {
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": "[domain]",
  "name": "[Site Name]",
  "url": "[domain]",
  "sameAs": ["https://twitter.com/handle"],
  "contactPoint": {
    "@type": "ContactPoint",
    "email": "contact@[domain]"
  }
};
```

### Credit Site - Review Schema
Per article:
```json
{
  "@context": "https://schema.org",
  "@type": "Review",
  "reviewRating": {"@type": "Rating", "ratingValue": "4.5"},
  "author": {"@type": "Organization", "name": "Credit Rewards Max"},
  "datePublished": "2026-03-03"
}
```

### Affiliate Site - Product Comparison Schema
Per tool:
```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "[Tool Name]",
  "review": {
    "@type": "Review",
    "reviewBody": "[Review text]",
    "datePublished": "[Date]"
  }
}
```

### Calc Site - WebApplication Schema
```json
{
  "@context": "https://schema.org",
  "@type": "WebApplication",
  "name": "[Calculator]",
  "dateModified": "2026-03-03",
  "applicationCategory": "FinanceApplication"
}
```

### Quant Site - ScholarlyArticle Schema
Per strategy:
```json
{
  "@context": "https://schema.org",
  "@type": "ScholarlyArticle",
  "author": {"@type": "Organization", "name": "Quant Platform"},
  "cite": {
    "@type": "ScholarlyArticle",
    "name": "[Academic paper]",
    "author": "[Author]",
    "datePublished": "[Year]"
  }
}
```

---

## PHASE 4: CONTENT FRESHNESS (Hours 13-16)

### All Sites - Add Update Metadata
```typescript
// Add to article/product pages
const contentMeta = {
  datePublished: "2026-01-15",
  dateModified: "2026-03-03",
  dataVerified: "2026-03-03",
  nextReview: "2026-06-03"
};
```

### All Sites - Footer Widget
```tsx
<div className="content-freshness">
  <p>✓ Last Updated: March 3, 2026</p>
  <p>✓ Data Verified: March 3, 2026</p>
  <p>✓ Next Review: June 3, 2026</p>
  <a href="/corrections">Report an error</a>
</div>
```

### All Sites - Update Dates on Top
Add to article headers:
```
Updated: March 3, 2026 | Verified: March 3, 2026 | Next Review: June 3, 2026
```

---

## EXECUTION CHECKLIST

### Credit Site ✓
- [ ] Remove Featured Credit Cards section (comment out)
- [ ] Remove "Get Started" CTAs
- [ ] Comment out exit-intent modals
- [ ] Create `/methodology` page
- [ ] Create `/data-sources` page
- [ ] Create `/corrections-policy` page
- [ ] Add schema markup to 20 articles
- [ ] Add update dates to 10 articles
- [ ] Add sources list to 10 articles

### Affiliate Site ✓
- [ ] Remove discount/partner offer language
- [ ] Change "Try [Tool]" → "Learn about [Tool]"
- [ ] Comment out commission mentions
- [ ] Create `/testing-methodology` page
- [ ] Create `/sources` page
- [ ] Create `/corrections-policy` page
- [ ] Add "Last Tested" dates to 10 tools
- [ ] Add testing methodology to 5 comparisons
- [ ] Add schema markup to 10 tools

### Calc Site ✓
- [ ] Remove broker CTAs
- [ ] Comment out "Open Account" buttons
- [ ] Remove "Ready to Start" investment language
- [ ] Create `/calculator-methodology` page
- [ ] Create `/data-sources` page
- [ ] Create `/corrections-policy` page
- [ ] Add formula/sources to 3 calculators
- [ ] Add risk disclosure to 2 strategies
- [ ] Add schema markup to calculators

### Quant Site ✓
- [ ] Remove sign-up/exclusive messaging
- [ ] Comment out "Join" CTAs
- [ ] Create `/strategy-validation` page
- [ ] Create `/research-references` page
- [ ] Create `/corrections-policy` page
- [ ] Add research citations to 5 strategies
- [ ] Add backtesting details to 5 strategies
- [ ] Add risk disclosure to 5 strategies
- [ ] Add schema markup to strategies

### Cross-Site ✓
- [ ] Organization schema added to all 4
- [ ] Update dates visible on all articles
- [ ] Corrections policies created (all 4)
- [ ] Data sources documented (all 4)
- [ ] No team bios added (anywhere)
- [ ] All salesy CTAs commented out

---

## TIME ALLOCATION

```
Phase 1: Remove Salesy Content (3 hours)
  Credit:    1 hour
  Affiliate: 45 min
  Calc:      45 min
  Quant:     30 min

Phase 2: Add Methodology (5 hours)
  Credit:    1.5 hours
  Affiliate: 1.5 hours
  Calc:      1 hour
  Quant:     1 hour

Phase 3: Schema Markup (4 hours)
  All Sites Parallel: 4 hours

Phase 4: Content Freshness (3 hours)
  All Sites Parallel: 3 hours

Verification: 1 hour
```

---

## PRIORITY ORDER

**Must Do First:**
1. Comment out salesy CTAs (non-negotiable)
2. Create methodology pages (builds credibility)
3. Add schema markup (helps Google understand)
4. Add update dates (freshness signals)

**Then Do:**
5. Add data sources
6. Create corrections policies
7. Add academic citations

---

## SUCCESS CRITERIA

✅ All salesy language commented out
✅ 4 methodology pages created
✅ All core pages have schema markup
✅ Update dates visible on key content
✅ No team bios added (anywhere)
✅ Data sources documented
✅ Google sees expertise signals

---

**Status**: Ready to execute in parallel
**Estimated Duration**: 16-20 hours
**Recommended Approach**: Work on all 4 sites simultaneously
