# Master Code Review Summary - All Projects
**Date**: 2026-02-11
**Projects Reviewed**: 20 across 9 review groups
**Total Issues Found**: 200+

---

## Portfolio Grades at a Glance

| # | Project | Type | Grade | Critical Issues | Status |
|---|---------|------|-------|-----------------|--------|
| 1 | **Quant** | Python/FastAPI API | **B+** | 1 (Stripe webhook commented out) | Nearest to production |
| 2 | **Credit** | Next.js Affiliate | **B+** | 1 (secrets in .env files) | Strong auth, rate limiting |
| 3 | **MobileGameCore** | Unity C# SDK | **B** | 0 | Reusable, well-architected |
| 4 | **Course Platform** | Next.js LMS | **B-** | 3 (secrets, free enroll, default crypto) | Good patterns, fix auth |
| 5 | **Tower Ascent** | Roblox Lua | **B-** | 5 (_G.PQL, SpendGems, placeholder IDs) | Good architecture, critical exploits |
| 6 | **Acquisition System** | Python/FastAPI | **B-** | 2 (zero API auth, unsigned webhooks) | Feature-complete, needs auth |
| 7 | **Affiliate/TheStackGuide** | Next.js Affiliate | **B-** | 2 (OIDC token, no admin auth) | Clean, needs auth |
| 8 | **Discovery** | Python API | **C+** | 2 (paywall commented out, default DB pw) | Revenue leak |
| 9 | **ContractIQ** | Python RAG | **C+** | 2 (FAISS pickle RCE, settings crash) | Dangerous deserialize |
| 10 | **Calc** | Next.js Affiliate | **C+** | 3 (fake reviews, no auth, TS suppressed) | SEO risk, legal risk |
| 11 | **Pet Quest** | Roblox Lua | **C+** | 3 (broken EquipPet, RemoteEvents never init) | Unfinished |
| 12 | **Toonz** | Python Automation | **C+** | 1 (Etsy tokens world-readable) | Functional |
| 13 | **OYKH** | Python Automation | **C** | 1 (no cost controls) | Works but dangerous |
| 14 | **Back** | React SPA | **C** | 0 | Early stage, no backend |
| 15 | **Pod** | Python Automation | **C-** | 2 (YouTube pickle RCE, API keys exposed) | Security nightmare |
| 16 | **LootStack Mayhem** | Unity C# Mobile | **5.5/10** | 10 (3D physics in 2D, shield resets score) | Won't compile |
| 17 | **Treasure Chase** | Unity C# Mobile | **5/10** | 6 (BinaryFormatter RCE, broken continue) | Won't compile correctly |
| 18 | **Block Blast** | Unity C# Mobile | **5/10** | 5 (duplicate enum, compile errors) | Won't compile |
| 19 | **BookCLI** | Python Automation | **D** | 3 (11+ live API keys, KDP cookies, pickle) | Dangerous to run |
| 20 | **Sports** | Python/Flask API | **D** | 7 (zero auth, wildcard CORS, keys in URLs) | Not deployable |

---

## Top 10 Most Critical Findings (Fix First)

### 1. LIVE API KEYS / SECRETS COMMITTED EVERYWHERE
**Projects**: BookCLI, Pod, OYKH, Toonz, Credit, Affiliate, Course Platform, Calc
**Impact**: Account takeover, financial loss, credential theft
- BookCLI: 11+ API keys (OpenAI, Anthropic, Google, Amazon) in plaintext `.env` and `api_keys.json`
- Course: `.env.production` with real Supabase/Stripe/Redis credentials
- Credit: `.env.vercel` with `NEXTAUTH_SECRET`, `CSRF_SECRET`, `CRON_SECRET`
- Pod: Gemini, Printful, fal.ai, Etsy keys in source
- **ACTION**: Rotate ALL credentials immediately. Delete all .env files from repos. Use vault/dashboard-only secrets.

### 2. ZERO AUTHENTICATION ON PRODUCTION APIs
**Projects**: Sports (all endpoints), Acquisition System (all endpoints), Calc (monitoring/logs/metrics), Affiliate (admin dashboard)
**Impact**: Anyone can read/write all data
- Sports: No auth whatsoever on dashboard or API. API key accepted as query parameter.
- Acquisition System: 20+ FastAPI endpoints, zero auth middleware
- Calc: `/api/monitoring/metrics` exposes `process.memoryUsage()`, CPU, uptime
- Affiliate: `/admin/analytics` shows all click data, IPs, revenue to public
- **ACTION**: Add authentication middleware before any deployment

### 3. UNSAFE DESERIALIZATION (RCE VECTORS)
**Projects**: Treasure Chase (BinaryFormatter), BookCLI (pickle), Pod (pickle), ContractIQ (FAISS pickle)
**Impact**: Remote Code Execution
- Treasure Chase `GhostRecorder`: `BinaryFormatter.Deserialize()` - Microsoft explicitly warns this is dangerous
- BookCLI/Pod: `pickle.load()` for YouTube OAuth tokens
- ContractIQ: `allow_dangerous_deserialization=True` for FAISS
- **ACTION**: Replace BinaryFormatter with JsonSerializer. Replace pickle with json. Verify FAISS sources.

### 4. CLIENT-SIDE-ONLY IAP / MONETIZATION
**Projects**: Block Blast, Treasure Chase, LootStack Mayhem, Pet Quest
**Impact**: All in-app purchases can be bypassed for free
- Block Blast: `PlayerPrefs.SetInt("ads_removed", 1)` - edit one value to get everything free
- Treasure Chase: No server-side receipt validation
- LootStack: Battle pass purchases free (no IAP verification)
- Pet Quest: `SpendGems` RemoteFunction exposed to client
- **ACTION**: Add server-side receipt validation (Apple/Google). Move gem spending server-side.

### 5. REVENUE-DESTROYING BUGS
**Projects**: Discovery, Quant, Course Platform, Treasure Chase, LootStack
**Impact**: Direct revenue loss
- Discovery: Premium paywall check is **commented out** - all premium content free
- Quant: Stripe webhook signature verification **commented out** - payments can be spoofed
- Course: Free enrollment endpoint bypasses payment entirely
- Treasure Chase: `ContinueRun()` after ad view freezes game (ad watches wasted)
- LootStack: Rewarded ad continue resets score to 0 (defeats the purpose)
- **ACTION**: Uncomment security checks. Fix game-freezing bugs.

### 6. SHELL INJECTION / COMMAND INJECTION
**Projects**: BookCLI (platform_publisher.py)
**Impact**: Arbitrary code execution on host
- `subprocess.run()` with `shell=True` and unsanitized user input at line 198-200
- **ACTION**: Use `shell=False` with argument list, or `shlex.quote()`.

### 7. PLACEHOLDER/ZERO PRODUCT IDS
**Projects**: Tower Ascent (all 15+ Roblox product IDs = 0), All mobile games (ad unit IDs), Back, Affiliate
**Impact**: Zero revenue even if everything else works
- Tower Ascent: Every `MarketplaceService:PromptPurchase` uses product ID `0`
- Mobile games: All ad IDs are Unity test IDs / placeholders
- Back/Affiliate: All affiliate URLs have no tracking parameters
- **ACTION**: Register real product IDs, ad units, and affiliate accounts.

### 8. MOBILE GAMES WON'T COMPILE
**Projects**: Block Blast, LootStack Mayhem, Treasure Chase
**Impact**: Cannot build, cannot ship
- Block Blast: Duplicate `BlockType` enum, missing `GetHighScore()` method
- LootStack: `IAPManager` event/method name collision, GameManager API mismatches
- Treasure Chase: Multiple API mismatches between managers
- **ACTION**: Fix compile errors before any other work.

### 9. GAME-BREAKING LOGIC BUGS
**Projects**: LootStack (MagnetPowerUp, ShieldPowerUp), Treasure Chase (ContinueRun, stub systems)
**Impact**: Core features don't work
- LootStack: `MagnetPowerUp` uses `Physics.OverlapSphere()` (3D) in a 2D game - literally does nothing
- LootStack: `ShieldPowerUp` calls `StartGame()` which resets score to 0
- Treasure Chase: $4.99 VehicleUnlockSystem and BattlePassSystem are stubs - take money, do nothing
- Treasure Chase: Keyboard-only controls (no touch input for mobile game)
- **ACTION**: Fix physics API, decouple shield from game reset, implement purchased systems.

### 10. FAKE STRUCTURED DATA (LEGAL RISK)
**Projects**: Calc
**Impact**: Google manual penalty, potential FTC violation
- Fabricated 12,847 ratings, 3,456 reviews, fake author names
- Unsubstantiated "Used by 10,000+ investors" claims
- Google explicitly penalizes fake review structured data
- **ACTION**: Remove all fabricated data immediately.

---

## Cross-Cutting Patterns

| Pattern | Count | Projects |
|---------|-------|----------|
| Hardcoded/committed secrets | 8 | BookCLI, Pod, OYKH, Toonz, Credit, Affiliate, Course, Calc |
| Missing authentication | 5 | Sports, Acquisition, Calc, Affiliate, Discovery |
| Client-side-only security | 4 | Block Blast, Treasure Chase, LootStack, Pet Quest |
| Unsafe deserialization | 4 | Treasure Chase, BookCLI, Pod, ContractIQ |
| Placeholder product/ad IDs | 5 | Tower Ascent, Block Blast, LootStack, Treasure Chase, Back |
| Commented-out security checks | 3 | Discovery, Quant, Sports |
| Compile/build errors | 3 | Block Blast, LootStack, Treasure Chase |
| No rate limiting | 4 | Sports, Calc, Affiliate, Back |
| No cost controls (AI APIs) | 3 | OYKH, BookCLI, Pod |
| Wildcard CORS | 2 | Sports, Credit (dev mode) |

---

## Recommended Fix Priority

### Phase 1: Emergency (Today)
1. Rotate ALL committed secrets across all 8 affected projects
2. Delete all `.env`, `.env.local`, `.env.vercel`, `.env.production` files from repos
3. Remove fake structured data from Calc

### Phase 2: Before Any Deploy (This Week)
4. Add authentication to Sports, Acquisition System, Calc monitoring, Affiliate admin
5. Uncomment Stripe webhook verification in Quant
6. Uncomment premium paywall in Discovery
7. Fix Course Platform free enrollment bypass
8. Replace `BinaryFormatter` and `pickle.load()` with safe alternatives
9. Fix shell injection in BookCLI

### Phase 3: Before Revenue (Next 2 Weeks)
10. Fix mobile game compile errors (Block Blast, LootStack, Treasure Chase)
11. Add server-side IAP receipt validation to all mobile games
12. Register real product IDs for Tower Ascent
13. Register real ad unit IDs for mobile games
14. Sign up for affiliate programs and get real tracked URLs
15. Fix game-breaking logic bugs (MagnetPowerUp, ShieldPowerUp, ContinueRun)

### Phase 4: Polish (Ongoing)
16. Add rate limiting everywhere
17. Add cost controls to AI automation tools
18. Fix accessibility issues
19. Add error monitoring (Sentry)
20. Add privacy policies where missing

---

## Review Files

All detailed reviews are in `/mnt/e/projects/.agent-bus/reviews/`:
1. `course-platform-review.md` - Course Platform (B-)
2. `roblox-games-review.md` - Tower Ascent (B-) + Pet Quest (C+)
3. `api-backends-review.md` - Sports (D) + Discovery (C+) + Quant (B+)
4. `infrastructure-review.md` - Acquisition (B-) + ContractIQ (C+) + MobileGameCore (B)
5. `automation-review.md` - BookCLI (D) + Pod (C-) + OYKH (C) + Toonz (C+)
6. `block-blast-review.md` - Block Blast (5/10)
7. `treasure-chase-review.md` - Treasure Chase (5/10)
8. `lootstack-review.md` - LootStack Mayhem (5.5/10)
9. `affiliate-sites-review.md` - Credit (B+) + Calc (C+) + Back (C) + Affiliate (B-)
