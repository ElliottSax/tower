# Project Scope Separation Guide

**Last Updated**: 2026-02-12
**Purpose**: Clear rules for when to use each project to prevent scope creep

## Quick Decision Tree

```
Need to create a product?
│
├─ Is it a BOOK?
│  ├─ Amazon KDP → /amazon/
│  ├─ General book generation → /bookcli/
│  └─ Coloring/activity books → /amazon/ (KDP)
│
├─ Is it for AMAZON MERCH by Amazon?
│  └─ T-shirts, hoodies on Merch platform → /amazon/merch/
│
├─ Is it for GENERIC POD platforms?
│  ├─ Etsy → /pod/
│  ├─ Printful → /pod/
│  ├─ Printify → /pod/
│  ├─ Redbubble → /pod/
│  └─ TeeSpring → /pod/
│
└─ Other
   ├─ Affiliate marketing → /affiliate/
   ├─ Course creation → /course/
   └─ Custom projects → Create new project
```

## Project Boundaries

### /amazon/

**Owns**:
- Amazon KDP book publishing (coloring books, journals, planners)
- Amazon Merch by Amazon (CSV-based t-shirt/apparel uploads)
- Amazon FBA (if added)
- Amazon-specific SEO (A9/A10 algorithm)

**Key Files**:
- `/amazon/merch/amazon_merch_client.py` - Merch CSV generation
- `/amazon/merch/seo_optimization.py` - Amazon-specific SEO
- `/amazon/kdp-quality-pipeline/` - KDP book generation

**Platform Characteristics**:
- CSV-based uploads (no REST API for Merch)
- Strict character limits (50-char titles)
- Tier-based restrictions (T10, T100, T1000)
- Royalty-based pricing model
- 4500x5400 PNG design requirements

**When to use**: Creating products that will be sold specifically on Amazon Merch or KDP.

---

### /pod/

**Owns**:
- Etsy product listings (OAuth API + CSV)
- Printful integration (fulfillment partner)
- Printify integration (fulfillment partner)
- Redbubble listings (web automation)
- TeeSpring listings
- Generic POD platform abstraction layer

**Key Files**:
- `/pod/app/platforms/platforms.py` - Platform enum (Printful, Printify, Etsy, Redbubble)
- `/pod/app/platforms/seo_generator.py` - Generic POD SEO (Etsy, Redbubble)
- `/pod/app/services/etsy_oauth_client.py` - Etsy API integration
- `/pod/app/services/printful_client.py` - Printful API integration
- `/pod/app/services/printify_client.py` - Printify API integration

**Platform Characteristics**:
- REST APIs available (Etsy, Printful, Printify, TeeSpring)
- Longer title limits (Etsy: 140 chars, Amazon generic: 200 chars)
- Flexible design requirements
- Wholesale + margin pricing model
- Multi-platform sync capabilities

**When to use**: Creating products for Etsy, Printful, Printify, Redbubble, or any generic POD marketplace (NOT Amazon Merch).

---

### /bookcli/

**Owns**:
- Book content generation (fiction, non-fiction)
- Writing assistance
- Book formatting
- General publishing tools

**When to use**: Generating book content (text), not necessarily publishing to Amazon.

---

### /affiliate/

**Owns**:
- Affiliate marketing campaigns
- Product reviews
- Comparison content
- Link tracking

**When to use**: Promoting other people's products for commissions.

---

## Why This Matters

### The Problem (Before Separation)

**Scope Creep Example**: Amazon Merch code was in the POD project because "it's print-on-demand apparel, so it belongs with other POD platforms."

**Why This Was Wrong**:
1. **Different Workflows**: Amazon Merch uses CSV upload, POD platforms use REST APIs
2. **Different SEO**: Amazon uses A9/A10 (keyword-first), Etsy uses descriptive long-tail
3. **Different Pricing**: Amazon uses royalties + tiers, POD uses wholesale + markup
4. **Different Constraints**: Amazon has strict 50-char titles, POD platforms allow 100-200 chars
5. **Different Design Specs**: Amazon requires 4500x5400 PNG, POD is flexible

**Result**: Code became confusing with Amazon-specific edge cases scattered throughout generic POD logic.

### The Solution (After Separation)

Each project has **ONE clear purpose**:
- `/amazon/` = Everything Amazon-specific (Merch, KDP, FBA)
- `/pod/` = Everything generic POD (Etsy, Printful, Printify, Redbubble)

**Benefits**:
- Clear mental model: "Amazon stuff goes in /amazon/, POD stuff goes in /pod/"
- No platform-specific edge cases in wrong places
- Can import Amazon module into POD when needed: `from amazon.merch import AmazonMerchClient`
- Easier for new developers to understand codebase structure

## Migration History

### 2026-02-12: Amazon Merch Extraction

**Moved**:
- `/pod/app/services/amazon_merch_client.py` → `/amazon/merch/amazon_merch_client.py`
- Amazon-specific SEO code → `/amazon/merch/seo_optimization.py`

**Updated**:
- Removed `PlatformType.MERCH_BY_AMAZON` from `/pod/app/platforms/platforms.py`
- Updated `/pod/CLAUDE.md` with scope boundaries
- Updated `/amazon/CLAUDE.md` to document merch subsystem

**Files Created**:
- `/amazon/merch/__init__.py` - Module initialization
- `/amazon/merch/README.md` - Module documentation
- `/amazon/merch/SETUP.md` - Usage guide
- `/projects/SCOPE_SEPARATION.md` - This file

**Reason**: Amazon Merch has fundamentally different requirements and workflows from generic POD platforms.

## Common Questions

### Q: Can I use Amazon Merch code from the POD project?

**A**: Yes! Import it:
```python
# In /pod/ project
from amazon.merch import AmazonMerchClient

# Generate Amazon Merch products
merch_client = AmazonMerchClient()
csv_file = merch_client.generate_bulk_csv(products)
```

### Q: Where does Amazon generic marketplace belong (not Merch)?

**A**: That's tricky. If you're using Amazon's generic seller API for non-Merch products:
- Physical products via FBA → `/amazon/` (Amazon-specific)
- POD products through Amazon's marketplace (not Merch) → Could go in either, but likely `/amazon/` since it uses Amazon's ecosystem

### Q: What about Shopify + Printful integration?

**A**: `/pod/` - Shopify is a generic e-commerce platform, and Printful is already in POD.

### Q: What about Walmart Marketplace?

**A**: Create new project `/walmart/` - it's a major platform with its own API and requirements.

### Q: Can one project depend on another?

**A**: Yes, but keep it one-directional:
- ✅ POD can import from Amazon: `from amazon.merch import AmazonMerchClient`
- ✅ Amazon can import utilities from POD: `from pod.utils import image_optimizer`
- ❌ Avoid circular dependencies (Amazon imports POD, POD imports Amazon)

### Q: How do I know if scope creep is happening?

**Signs of scope creep**:
- "We need to add just one Amazon-specific feature to the POD platform module"
- "Let's add an if-statement for Amazon Merch edge cases"
- "This function has platform-specific branches for 5 different platforms"

**Solution**: Extract to platform-specific module or project.

## Best Practices

### 1. Check Project CLAUDE.md First

Every project has a `CLAUDE.md` file with:
- **IN SCOPE**: What belongs in this project
- **OUT OF SCOPE**: What belongs elsewhere

**Before adding a feature**, check if it's in scope.

### 2. Use Platform Abstraction Carefully

**Good abstraction** (similar platforms):
```python
class BasePODPlatform(ABC):
    """Base for Printful, Printify, Redbubble - all use REST APIs"""
    @abstractmethod
    def create_listing(self, design, products, pricing): pass
```

**Bad abstraction** (different workflows):
```python
class BasePlatform(ABC):
    """Base for EVERYTHING including Amazon Merch"""
    @abstractmethod
    def create_listing(self, design):
        if platform == "amazon_merch":
            return self.generate_csv()  # ❌ Edge case in base class
        else:
            return self.api_call()  # ✅ Normal flow
```

### 3. Separate When Workflows Differ

**Same workflow** → Same project:
- Etsy + Printful both use REST APIs → POD project ✅

**Different workflow** → Different projects:
- Amazon Merch uses CSV upload → Amazon project ✅
- Etsy uses REST API → POD project ✅

### 4. Document Separations

When you extract code to a new project:
1. Update `CLAUDE.md` in BOTH projects
2. Add entry to this `SCOPE_SEPARATION.md`
3. Create README in new module explaining why it's separate
4. Update any affected code with import paths

## Template for New Separations

```markdown
### [DATE]: [Feature] Extraction

**Moved**:
- `/old/path/file.py` → `/new/path/file.py`

**Updated**:
- [List of files updated with new import paths]

**Files Created**:
- [List of new documentation files]

**Reason**: [Brief explanation of why separation was needed]
```

## Summary

**Golden Rule**: If a platform has fundamentally different workflows, constraints, or APIs, it probably deserves its own project or module.

**Use this file** when you're unsure where to put new code. If your case isn't covered, add it to this document after making a decision.

**Keep projects focused**. A project that does ONE thing well is better than a project that does MANY things poorly.
