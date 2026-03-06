# 🔗 AFFILIATE LINK DEPLOYMENT GUIDE
**Time to Deploy**: 30 minutes (once approvals received)
**Location**: `/mnt/e/projects/affiliate/thestackguide/src/lib/affiliateLinks.ts`

---

## WORKFLOW: From Approval → Live in 30 Minutes

### Step 1: Receive Approval Email (1 min)
You'll get an email with:
- Affiliate ID / Referral Code
- Tracking URL / Short Link
- Dashboard access info

**Save all of these** in a notes file.

---

### Step 2: Update affiliateLinks.ts (10 min)

Open the file:
```bash
nano /mnt/e/projects/affiliate/thestackguide/src/lib/affiliateLinks.ts
```

Find the section you're updating. Replace placeholder with real link:

#### BEFORE:
```typescript
// ⏳ PENDING APPROVALS - Create Dub links when approved
'convertkit': 'https://thestackguide.com/convertkit',
'jasper': 'https://thestackguide.com/jasper',
```

#### AFTER (Example - Replace with YOUR actual links):
```typescript
// ✅ LIVE - Real affiliate links
'convertkit': 'https://app.convertkit.com/referrals/l/123abc456', // ConvertKit referral
'jasper': 'https://www.shareasale.com/r.cfm?b=1234567&u=1234567&m=66456', // ShareASale
```

---

### Step 3: Update Dub.co Short Links (10 min)

If using Dub.co for tracking:

1. **Log in**: https://dub.co/dashboard
2. **Find link**: e.g., `thestackguide.com/convertkit`
3. **Click Edit**
4. **Update "Destination URL"** to the real affiliate URL
5. **Save**

Repeat for each program.

---

### Step 4: Deploy to Production (5 min)

```bash
cd /mnt/e/projects/affiliate/thestackguide

# Build to verify no errors
npm run build

# Deploy (Vercel)
npm run deploy
# OR
vercel deploy --prod
```

---

### Step 5: Verify in Analytics (5 min)

1. Visit your site: https://thestackguide.com
2. Click on an affiliate link
3. Check `/admin/analytics` dashboard
4. Should see the click tracked with program name

---

## 📋 AFFILIATE LINKS MASTER LIST

As you get approvals, fill in this table:

| Program | Approval Date | Affiliate ID | Real Link | Status |
|---------|---|---|---|---|
| ConvertKit | ⏳ | ⏳ | ⏳ | 🔴 |
| Jasper | ⏳ | ⏳ | ⏳ | 🔴 |
| Ahrefs | ⏳ | ⏳ | ⏳ | 🔴 |
| SEMrush | ⏳ | ⏳ | ⏳ | 🔴 |
| Zapier | ⏳ | ⏳ | ⏳ | 🔴 |
| ActiveCampaign | ⏳ | ⏳ | ⏳ | 🔴 |
| HubSpot | ⏳ | ⏳ | ⏳ | 🔴 |
| Shopify | ⏳ | ⏳ | ⏳ | 🔴 |
| Stripe | ⏳ | ⏳ | ⏳ | 🔴 |
| Grammarly | ⏳ | ⏳ | ⏳ | 🔴 |

Legend: 🔴 Pending | 🟡 Approved, Link Received | 🟢 Live & Tracking

---

## 🔍 VERIFY TRACKING WORKS

After deploying, test each link:

1. **Click from different browser** (to avoid same-session issues)
2. **Check `/admin/analytics`** dashboard
3. **Should show**:
   - Program name
   - Timestamp
   - IP address
   - Session ID

If not showing, check:
- Is Supabase connected? (`DATABASE_URL` env var set)
- Did you save the code and redeploy?
- Are you looking at the right analytics page?

---

## 📊 MONITORING CHECKLIST

After each deployment:

- [ ] No build errors (`npm run build` passes)
- [ ] Site loads at https://thestackguide.com
- [ ] Clicking link works (no 404)
- [ ] Click tracked in `/admin/analytics`
- [ ] Affiliate program dashboard shows incoming traffic

---

## 🚀 RAPID DEPLOYMENT EXAMPLE

**Day 5: ConvertKit Approval Arrives**

1. Copy approval email with referral link
2. Open affiliateLinks.ts
3. Replace ConvertKit placeholder:
   ```typescript
   'convertkit': 'https://app.convertkit.com/referrals/l/YOUR_ID'
   ```
4. Run `npm run build && vercel deploy --prod`
5. Done! Live in 5 minutes

**Day 6: See first ConvertKit click in analytics**

---

## COMMON ISSUES & FIXES

### Issue: Link redirects to affiliate site but no tracking
**Fix**: Ensure DATABASE_URL env var is set in Vercel environment

### Issue: Deploy succeeds but old link still live
**Fix**: Vercel may cache. Use `vercel deploy --prod --skip-build`

### Issue: Can't find real affiliate link from program
**Fix**: Check spam folder, request resend, or find in program dashboard under "Links" or "Resources"

### Issue: Multiple approval emails from same program
**Fix**: Usually one is admin confirmation, one is partner portal. Use the partner portal link.

---

## 💡 NEXT: Content Optimization

Once links are live, add CTAs to articles:

```markdown
## Getting Started with [Tool]

[2-3 paragraph explanation]

**Ready to try it?** [Tool Name] offers a free trial.
→ [Get Started with [Tool]](/go/tool-name)
```

This converts readers to affiliate clicks within days.

---

## 📞 SUPPORT

Questions about a specific program?
- Check their affiliate FAQ/documentation
- Email their affiliate manager
- Check partner portal help section

For TheStackGuide tracking issues:
- Check Supabase dashboard (https://supabase.com)
- Verify DATABASE_URL is correct
- Check `/admin/analytics` for recent clicks
