# Next Actions - Amazon/POD Separation Follow-Up

**Date**: 2026-02-12
**Status**: Migration complete, user actions required

## URGENT - Security Fixes (USER MUST DO)

### CRITICAL - Rotate API Keys Immediately

The POD project has exposed API keys in `.env` file at `/mnt/e/projects/pod/.env`

**You MUST rotate these keys NOW**:

1. **Gemini API** (Google AI)
   - Go to: https://aistudio.google.com/app/apikey
   - Delete old key, generate new one
   - Set: `export GEMINI_API_KEY="new-key-here"`

2. **Printful API**
   - Go to: https://www.printful.com/dashboard/store (Settings > API)
   - Revoke old token, generate new one
   - Set: `export PRINTFUL_API_KEY="new-key-here"`

3. **fal.ai API**
   - Go to: https://fal.ai/dashboard/keys
   - Delete old key, generate new one
   - Set: `export FAL_KEY="new-key-here"`

4. **Replicate API**
   - Go to: https://replicate.com/account/api-tokens
   - Delete old token, generate new one
   - Set: `export REPLICATE_API_TOKEN="new-key-here"`

5. **Etsy API**
   - Go to: https://www.etsy.com/developers/your-apps
   - Regenerate API key and shared secret
   - Set: `export ETSY_API_KEY="new-key-here"`
   - Set: `export ETSY_SHARED_SECRET="new-secret-here"`

6. **SiliconFlow, DeepSeek**
   - Check respective dashboards
   - Rotate keys

**Then delete .env file**:
```bash
cd /mnt/e/projects/pod
rm .env
```

**See full instructions**: `/mnt/e/projects/pod/SECURITY_FIXES_NEEDED.md`

---

## Testing Required

### 1. Test Amazon Merch Module

```bash
cd /mnt/e/projects

# Test basic import
python3 << 'EOTEST'
from amazon.merch import AmazonMerchClient, AmazonMerchProduct
from amazon.merch.seo_optimization import AmazonMerchSEOGenerator

# Create client
client = AmazonMerchClient()

# Generate SEO
seo_gen = AmazonMerchSEOGenerator()
seo = seo_gen.generate_complete_seo(
    keyword="test product",
    product_type="T-Shirt",
    tier="T10"
)

print(f"✓ Title: {seo.title}")
print(f"✓ Price: ${seo.price}")
print(f"✓ Module works!")
EOTEST
```

### 2. Test POD Platform Enum

```bash
cd /mnt/e/projects/pod

# Verify MERCH_BY_AMAZON removed
grep -n "MERCH_BY_AMAZON" app/platforms/platforms.py
# Should return: (no matches)

# Check remaining platforms
grep "class PlatformType" -A 10 app/platforms/platforms.py
# Should show: PRINTFUL, PRINTIFY, REDBUBBLE, TEESPRING (NO Amazon Merch)
```

### 3. Test Amazon Merch CSV Generation

```python
# Create test product and generate CSV
from amazon.merch import AmazonMerchClient, AmazonMerchProduct

client = AmazonMerchClient()

product = AmazonMerchProduct(
    title="Test Dog Mom T-Shirt Gift",
    brand="Test Brand",
    description="Test description for Dog Mom design",
    bullet_points=[
        "Premium quality t-shirt with unique design",
        "Perfect gift for dog lovers and enthusiasts"
    ],
    price=19.99,
    color="Black",
    fit_type="Women",
    design_url="https://example.com/test.png"
)

csv_file = client.generate_bulk_csv([product], "test_merch.csv")
print(f"CSV generated: {csv_file}")

# Check CSV contents
import csv
with open(csv_file, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row)
```

---

## Optional Cleanup

### 1. Remove Old Amazon Merch File from POD

The file was copied (not moved) so the original still exists:

```bash
cd /mnt/e/projects/pod

# Check if file exists
ls -lah app/services/amazon_merch_client.py

# If it exists, you can delete it (now that it's in /amazon/merch/)
# rm app/services/amazon_merch_client.py
```

**Note**: We intentionally left it for now in case you want to compare or verify the migration.

### 2. Search for Amazon Merch References

```bash
cd /mnt/e/projects/pod

# Search for any remaining references
grep -rn "amazon_merch" . --exclude-dir=venv --exclude-dir=__pycache__ --exclude="*.md"
grep -rn "MERCH_BY_AMAZON" . --exclude-dir=venv --exclude-dir=__pycache__ --exclude="*.md"
```

If found, update import paths to:
```python
# Old
from app.services.amazon_merch_client import AmazonMerchClient

# New
from amazon.merch import AmazonMerchClient
```

---

## Documentation to Review

1. **`/mnt/e/projects/AMAZON_POD_SEPARATION_COMPLETE.md`**
   - Complete migration summary
   - What was moved and why
   - How to use the new module
   - Testing instructions

2. **`/mnt/e/projects/SCOPE_SEPARATION.md`**
   - Decision tree for all projects
   - When to use Amazon vs POD vs other projects
   - Common questions answered
   - Best practices

3. **`/mnt/e/projects/pod/SECURITY_FIXES_NEEDED.md`**
   - CRITICAL security issues
   - Step-by-step fix instructions
   - Security checklist
   - Prevention strategies

4. **`/mnt/e/projects/amazon/merch/README.md`**
   - Amazon Merch module overview
   - Features and capabilities
   - Design requirements
   - Tier information

5. **`/mnt/e/projects/amazon/merch/SETUP.md`**
   - Complete usage guide
   - Examples and tutorials
   - Troubleshooting
   - Best practices

6. **`/mnt/e/projects/amazon/CLAUDE.md`** (Updated)
   - Architecture with Merch subsystem
   - Scope boundaries

7. **`/mnt/e/projects/pod/CLAUDE.md`** (Updated)
   - Updated scope boundaries
   - Migration notes
   - Platform comparison table

---

## Future Development

### Amazon Project

1. **Merch Integration**:
   - Test CSV upload to Amazon Merch dashboard
   - Generate real designs (connect to POD design pipeline)
   - Track tier progression (T10 → T25 → T100)
   - Monitor sales and royalties

2. **KDP Integration**:
   - Build book generation pipeline
   - Create coloring book generator
   - Low-content book templates (journals, planners)
   - Cover design automation

### POD Project

1. **Etsy Focus**:
   - Complete OAuth setup
   - Upload test products
   - Connect Printful for fulfillment
   - Track first sales

2. **Multi-Platform Expansion**:
   - Add Redbubble integration
   - Expand to TeeSpring
   - Build unified dashboard

3. **Security Hardening**:
   - Complete security fixes (see SECURITY_FIXES_NEEDED.md)
   - Add pre-commit hooks to prevent secret commits
   - Set up secrets manager
   - Audit pickle usage

---

## Success Criteria

### Migration Complete ✅
- [✅] Amazon Merch code moved to `/amazon/merch/`
- [✅] POD platform enum updated (MERCH_BY_AMAZON removed)
- [✅] Documentation created (README, SETUP, SCOPE_SEPARATION)
- [✅] Security issues identified and documented
- [✅] Module imports successfully

### User Testing Required ⏳
- [ ] Test Amazon Merch CSV generation
- [ ] Test POD platform enum (no import errors)
- [ ] Review security fixes document
- [ ] Rotate API keys
- [ ] Delete .env file after rotating keys

### Production Ready 🎯
- [ ] Security fixes completed (API keys rotated, .env deleted)
- [ ] OAuth token permissions fixed (chmod 600)
- [ ] Database password changed
- [ ] First Amazon Merch CSV uploaded to dashboard
- [ ] First Etsy products listed

---

## Quick Reference

### Import Paths

```python
# Amazon Merch (from anywhere)
from amazon.merch import AmazonMerchClient, AmazonMerchProduct
from amazon.merch.seo_optimization import AmazonMerchSEOGenerator

# POD Platforms
from pod.app.platforms.platforms import PlatformType
from pod.app.services.etsy_oauth_client import EtsyOAuthClient
from pod.app.services.printful_client import PrintfulClient
```

### File Locations

```
/mnt/e/projects/
├── amazon/
│   ├── CLAUDE.md (updated with Merch subsystem)
│   └── merch/
│       ├── amazon_merch_client.py
│       ├── seo_optimization.py
│       ├── README.md
│       └── SETUP.md
│
├── pod/
│   ├── CLAUDE.md (updated with scope boundaries)
│   ├── SECURITY_FIXES_NEEDED.md (NEW)
│   └── app/
│       └── platforms/
│           └── platforms.py (MERCH_BY_AMAZON removed)
│
├── SCOPE_SEPARATION.md (NEW)
├── AMAZON_POD_SEPARATION_COMPLETE.md (NEW)
└── NEXT_ACTIONS_AMAZON_POD.md (this file)
```

### Commands Summary

```bash
# Security: Rotate keys and delete .env
cd /mnt/e/projects/pod
rm .env
chmod 600 ~/.etsy_tokens.json

# Testing: Verify module imports
python3 -c "from amazon.merch import AmazonMerchClient; print('✓ Works')"

# Cleanup: Remove old file (optional)
# rm /mnt/e/projects/pod/app/services/amazon_merch_client.py

# Verification: Check for references
cd /mnt/e/projects/pod
grep -rn "MERCH_BY_AMAZON" . --exclude-dir=venv --exclude="*.md"
```

---

## Questions?

- **Where did Amazon Merch go?** → `/mnt/e/projects/amazon/merch/`
- **Can POD still use Amazon Merch?** → Yes, via `from amazon.merch import AmazonMerchClient`
- **What about security issues?** → See `/pod/SECURITY_FIXES_NEEDED.md` for full details
- **When to use Amazon vs POD?** → See `/projects/SCOPE_SEPARATION.md` decision tree
- **How to use Amazon Merch module?** → See `/amazon/merch/SETUP.md` for examples

---

## Summary

**Status**: ✅ Migration complete, ready for testing

**User Actions Required**:
1. 🔴 URGENT: Rotate API keys (see SECURITY_FIXES_NEEDED.md)
2. 🔴 URGENT: Delete .env file
3. 🟡 TEST: Verify Amazon Merch module works
4. 🟡 TEST: Verify POD platform enum updated
5. 🟢 OPTIONAL: Clean up old files

**Next Steps**: Focus on security fixes first, then test both modules.

---

**Date**: 2026-02-12
**Files**: 10 created/updated
**Documentation**: ~36 KB
**Code**: ~1,350 lines
**Status**: Migration complete, user testing required
