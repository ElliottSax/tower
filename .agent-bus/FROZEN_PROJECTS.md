# Frozen Projects - Portfolio Cleanup Report

**Date**: 2026-02-11
**Author**: Portfolio Architect
**Action**: Freeze 5 projects per architect directive
**Rationale**: Stop wasting effort on projects with fatal flaws, focus resources on 15 viable projects

---

## Executive Summary

Per the portfolio-wide system analysis in `/mnt/e/projects/.agent-bus/advice/architect-directive.md`, **5 projects have been frozen** to eliminate waste and refocus development resources.

### Projects Frozen
1. **Sports Analytics** (Grade D) - 10 critical security issues, superseded by Quant
2. **LootStack Mayhem** (Grade 5.5/10) - Will not compile, gameplay-breaking bugs
3. **Block Blast Evolved** (Grade 5/10) - Will not compile, redundant architecture
4. **Treasure Chase** (Grade 5/10) - Security vulnerabilities, keyboard-only on mobile
5. **Back** (Grade C) - SPA architecture incompatible with affiliate SEO

### Hours Saved
- **Immediate**: 0 hours (no ongoing work to halt)
- **Prevented waste**: 300-340 hours of debugging and fixes
- **Future maintenance**: 40-60 hours per year eliminated
- **Total estimated savings**: 340-400+ hours over next 12 months

### What Was Preserved
- **Sports betting algorithms** extracted to patterns library
- **MobileGameCore SDK** already extracted from mobile games
- **Lessons learned** documented for future projects

---

## 1. Sports Analytics (FROZEN)

**Location**: `/mnt/e/projects/sports/`
**Grade**: D (4/10)
**Frozen Date**: 2026-02-11
**Status**: Left in place with FROZEN markers

### Why Frozen
Quant platform (B+) provides everything Sports does but with production-grade security. Sports has **10 critical security issues** requiring 80+ hours to fix:
- Zero authentication on any endpoint
- Default secrets hardcoded
- API keys in query parameters
- Wildcard CORS
- Plaintext API key storage in database
- No authentication on payment endpoints
- Werkzeug dev server in production
- No rate limiting
- No CSRF protection
- Auth bypass when env var is empty

### What Was Saved
**Algorithms extracted** to `/mnt/e/projects/.agent-bus/patterns/sports-betting-algorithms.md`:
- **Arbitrage detection** - Formula, stake distribution, 2-way and 3-way markets
- **Kelly Criterion** - Optimal bet sizing with fractional Kelly
- **Expected Value (EV) calculator** - +EV opportunity identification
- **Sharp money detection** - Steam moves, line movement tracking
- **Odds conversion utilities** - American ↔ Decimal ↔ Implied Probability

These are domain-agnostic mathematical formulas that can be integrated into **Quant** as a sports betting module if that vertical is pursued.

### What Supersedes It
**Quant Platform** (`/mnt/e/projects/quant/`)
- Grade: B+
- Security: Production-ready (2FA, token rotation, 22K LOC tests)
- Architecture: FastAPI with proper async, validation, OpenAPI
- Status: 4-8 hours from deployable revenue

### Hours Saved
- **Fix effort avoided**: 80 hours of security fixes
- **Ongoing maintenance**: 20 hours/year
- **Total**: 80+ hours

### If Unfreezing
**Option A** (Recommended): Merge algorithms into Quant as sports betting module (20-30 hours)
**Option B** (Not Recommended): Rewrite from scratch in FastAPI like Quant (80+ hours)

---

## 2. LootStack Mayhem (FROZEN)

**Location**: `/mnt/e/projects/LootStackMayhem/`
**Grade**: 5.5/10
**Frozen Date**: 2026-02-11
**Status**: Left in place with FROZEN markers

### Why Frozen
**Will not compile correctly**. Has **10 critical bugs** that would require 60+ hours to fix:
- IAPManager method/event name collision (compilation error)
- GameManager API mismatch with AnalyticsManager (compilation error)
- SaveSystem.Initialize() doesn't exist (compilation error)
- MagnetPowerUp uses 3D physics in 2D game (never works)
- ShieldPowerUp resets player score to 0 (destroys run progress)
- RewardedAdController "Continue" resets score (same bug)
- Battle Pass starts at Season 2 (off-by-one error)
- Battle Pass purchases are free (no IAP integration)
- Placeholder ad game IDs ($0 ad revenue)
- Default hash salt unchanged (save data security)

Plus **performance issues** for mobile:
- No object pooling (GC spikes)
- 50+ draw calls per particle emitter
- PerformanceProfiler creates textures every frame (memory leak)
- Real-time lights on every collectable

### What Was Saved
**MobileGameCore SDK** (Grade B) was already extracted to `/mnt/e/projects/MobileGameCore/`:
- 17 production-ready systems (AdManager, IAPManager, EconomyManager, SaveSystem, AnalyticsManager, ATTManager, etc.)
- Zero critical issues
- Clean, reusable architecture
- Used by future mobile games

### What Supersedes It
**MobileGameCore SDK** - Use this for all future mobile games instead of fixing LootStack.

### Hours Saved
- **Fix effort avoided**: 60-64 hours of bug fixes
- **Alternative approach**: Start new game with MobileGameCore (40-60 hours total) vs fixing (60+ hours)
- **Total**: 60-64 hours saved by not debugging

### If Unfreezing
**Option A** (Recommended): Start new mobile game with MobileGameCore SDK (40-60 hours)
**Option B** (Not Recommended): Fix all bugs in LootStack (60-64 hours)

---

## 3. Block Blast Evolved (FROZEN)

**Location**: `/mnt/e/projects/block-blast-evolved/`
**Grade**: 5/10
**Frozen Date**: 2026-02-11
**Status**: Left in place with FROZEN markers

### Why Frozen
**Will not compile**. Has **critical compilation errors and architectural redundancy**:
- Duplicate `BlockType` enum in two namespaces (type mismatch)
- `ScoreManager.GetHighScore()` method doesn't exist
- **Triple-redundant hero data** - Three separate systems (Hero class, HeroTemplate ScriptableObject, HeroData ScriptableObject) created in parallel, only one used
- IAPManager.OnPurchaseFailed name collision
- Client-side only IAP validation (hackable)
- **Hero abilities are stubs** - All 5 abilities only log messages, don't execute
- Free hero unlock bypass
- Wrong game-over logic (10% threshold instead of "can blocks fit")
- Material memory leaks
- Shader.Find() will fail in builds

### What Was Saved
**Nothing unique.** Uses same MobileGameCore SDK extracted from LootStack.

### What Supersedes It
**MobileGameCore SDK** + proper planning (avoid triple-redundant data architectures)

### Hours Saved
- **Fix effort avoided**: 60-70 hours of fixes
- **Better alternative**: New puzzle game with MobileGameCore (40-60 hours)
- **Total**: 60-70 hours

### If Unfreezing
**Option A** (Recommended): New puzzle game with MobileGameCore, simpler design (40-60 hours)
**Option B** (Not Recommended): Fix all compilation errors and implement stub abilities (60-70 hours)

---

## 4. Treasure Chase (FROZEN)

**Location**: `/mnt/e/projects/treasure-chase/`
**Grade**: 5/10
**Frozen Date**: 2026-02-11
**Status**: Left in place with FROZEN markers

### Why Frozen
**Critical security vulnerabilities + broken monetization**:
- **BinaryFormatter RCE vulnerability** - Remote code execution via crafted .dat files
- **Zero IAP receipt validation** - Jailbreak exploit, free premium content
- **All monetization in PlayerPrefs** - Plaintext XML, trivially hackable
- **Placeholder ad game IDs** - $0 ad revenue
- **Duplicate stub systems** - VehicleUnlockSystem and BattlePassSystem stubs that do nothing
- **Continue-after-ad is broken** - Players watch ad, game stays frozen
- **Interstitial ads never show** - Invoke broken by Time.timeScale = 0
- **Shield power-up doesn't work** - External call path broken
- **Keyboard-only controls** - Unplayable on mobile devices

### What Was Saved
**Game design patterns** (not code):
- VehicleUnlockSystem progression curve (0 → 100 → 250 → 500 → 1K → 2.5K → 5K → 10K coins)
- DailyRewardSystem 7-day calendar with streak bonuses
- Lesson: Good game design + poor production engineering

### What Supersedes It
**MobileGameCore SDK** with proper security from day one.

### Hours Saved
- **Fix effort avoided**: 60-64 hours of security fixes + mobile input
- **Better alternative**: New endless runner with secure architecture (40-60 hours)
- **Total**: 60-64 hours

### If Unfreezing
**Option A** (Recommended): New endless runner with MobileGameCore + secure design (40-60 hours)
**Option B** (Not Recommended): Fix BinaryFormatter, IAP validation, mobile input, continue flow (60-64 hours)

---

## 5. Back - Backtesting Affiliate (FROZEN)

**Location**: `/mnt/e/projects/back/`
**Grade**: C (5/10)
**Frozen Date**: 2026-02-11
**Status**: Left in place with FROZEN markers

### Why Frozen
**SPA architecture is fundamentally incompatible with affiliate SEO**:
- Vite + React SPA renders all content client-side
- Search engines see empty `<div id="root"></div>`
- Google may or may not execute JavaScript
- Competitors (NerdWallet, Investopedia) use server-side rendering
- For competitive finance keywords, SPAs cannot rank

**Other issues**:
- All affiliate links are placeholders
- `trackAffiliateClick()` only does `console.log`
- No backend (no tracking, no database)
- Deployed to production despite being broken
- Client-side SEO utilities are waste (manipulating DOM at runtime doesn't help crawlers)

### What Was Saved
**Nothing unique.** Standard React patterns (stores/, hooks/, services/) are well-known. Affiliate partner database has only placeholder data.

### What Supersedes It
**Affiliate/StackGuide** (`/mnt/e/projects/affiliate/`)
- Grade: B-
- Architecture: Next.js with proper SSR
- Can add backtesting content as new section

**Credit** (`/mnt/e/projects/credit/`)
- Grade: B+
- Architecture: Next.js with SSR
- Already covers finance affiliate niche

### Hours Saved
- **Rewrite effort avoided**: 60+ hours to rebuild in Next.js
- **Better alternative**: Merge content into existing Affiliate site (16-24 hours)
- **Total**: 40-50 hours by not maintaining third affiliate site

### If Unfreezing
**Option A** (Recommended): Merge backtesting content into Affiliate/StackGuide site (16-24 hours)
**Option B** (Not Recommended): Rewrite from scratch in Next.js (60+ hours)
**Option C** (Best): Freeze and focus on higher priorities (Quant, Discovery, Credit)

---

## Summary Table

| Project | Grade | Reason Frozen | Hours to Fix | Hours Saved | Active Alternative |
|---------|-------|--------------|-------------|-------------|-------------------|
| **Sports** | D | 10 security issues | 80 hours | 80+ hours | Quant (B+) |
| **LootStack** | 5.5/10 | Won't compile, gameplay bugs | 60 hours | 60-64 hours | MobileGameCore SDK (B) |
| **Block Blast** | 5/10 | Won't compile, redundant arch | 60 hours | 60-70 hours | MobileGameCore SDK (B) |
| **Treasure Chase** | 5/10 | Security vulns, no mobile input | 60 hours | 60-64 hours | MobileGameCore SDK (B) |
| **Back** | C | SPA architecture fatal flaw | 60 hours | 40-50 hours | Affiliate (B-), Credit (B+) |
| **TOTAL** | | | **320 hours** | **300-340 hours** | |

---

## What Was Extracted and Preserved

### 1. Sports Betting Algorithms
**File**: `/mnt/e/projects/.agent-bus/patterns/sports-betting-algorithms.md`

Extracted mathematical formulas and reference implementations:
- Arbitrage detection (2-way and 3-way markets)
- Kelly Criterion (optimal bet sizing)
- Expected Value calculator
- Sharp money detection (steam moves)
- Odds conversion utilities

**Reuse potential**: Can be integrated into Quant platform if sports betting vertical is pursued.

### 2. MobileGameCore SDK
**Location**: `/mnt/e/projects/MobileGameCore/`
**Grade**: B

Already extracted before this freeze. Contains 17 production-ready systems:
- Monetization (AdManager, IAPManager)
- Persistence (SaveSystem, EconomyManager)
- Analytics (AnalyticsManager, ATTManager)
- Polish (AudioManager, CameraController, GameFeelManager)
- Utilities (InputManager, TransitionManager, PerformanceProfiler)

**Reuse potential**: Foundation for all future mobile games.

### 3. Game Design Patterns (Lessons)
Documented in individual FROZEN.md files:
- **Vehicle progression curve** (Treasure Chase) - Well-balanced unlock costs
- **Daily reward calendar** (Treasure Chase) - 7-day streak with grace period
- **Hero RPG mechanics** (Block Blast) - Level progression, abilities, rarities

**Reuse potential**: Apply design patterns to future games with secure implementation.

---

## Which Active Projects Supersede Them

### Sports → Quant
- **Quant** (B+) has everything Sports was meant to provide
- Better security (2FA, token rotation, 22K LOC tests)
- Better architecture (FastAPI vs Flask)
- Closer to revenue (4-8 hours vs 80+ hours)
- Congressional trading + options flow > sports betting for MVP

### LootStack/Block Blast/Treasure Chase → MobileGameCore SDK
- **MobileGameCore** (B) is the production-ready foundation
- Zero critical issues (vs 10+ per mobile game)
- Reusable across all future mobile games
- 20-30 hours per game saved on IAP/ads/analytics boilerplate

### Back → Affiliate + Credit
- **Affiliate/StackGuide** (B-) can host backtesting content
- **Credit** (B+) already covers finance affiliate niche
- Both use correct SSR architecture (Next.js)
- No need for third affiliate site with SPA architecture

---

## Estimated Total Hours Saved

### Immediate Savings (Prevented Waste)
- Sports security fixes: **80 hours**
- LootStack bug fixes: **60 hours**
- Block Blast fixes: **60 hours**
- Treasure Chase security + mobile: **60 hours**
- Back Next.js rewrite: **60 hours**
- **Subtotal**: **320 hours of fixes avoided**

### Ongoing Maintenance Eliminated
- 5 codebases no longer maintained: **40-60 hours/year**

### Better Alternatives
- Merge sports algorithms into Quant: **20-30 hours** (vs 80 hours fixing)
- New mobile game with MobileGameCore: **40-60 hours** (vs 60+ hours fixing each)
- Merge backtesting into Affiliate: **16-24 hours** (vs 60 hours rewriting)

### Net Total Saved
**340-400+ hours over next 12 months** by:
1. Not fixing unfixable architectures
2. Not maintaining redundant codebases
3. Reusing extracted components (MobileGameCore, algorithms)
4. Focusing on 15 viable projects instead of 20

---

## Portfolio Focus Areas (Post-Freeze)

### PRIORITY 1: Deploy Revenue Projects (4-16 hours)
- **Quant** - Uncomment Stripe, remove SQL admin, deploy (4-8 hours)
- **Discovery** - Uncomment paywall, fix pickle, deploy (8-16 hours)
- **Expected result**: First revenue within 1-2 weeks

### PRIORITY 2: Secure Credentials (2-4 hours)
- Rotate all exposed API keys (BookCLI, Pod, OYKH, Credit)
- Delete .env files from repos
- Verify git history for secrets

### PRIORITY 3: Fix High-Value Projects (16-40 hours)
- **Credit** - Rotate secrets, get real affiliate links, deploy (16-24 hours)
- **Course** - Fix payment bypass, deploy (8-16 hours)
- **Affiliate** - Fix XSS, add admin auth (16-24 hours)

### PRIORITY 4 (Optional): Mobile Games
- If pursuing mobile games, **focus on ONE** using MobileGameCore
- Pet Quest Legends is most complete (if code is better than the frozen 3)
- Or start fresh with simpler design
- **Do not** unfreeze LootStack, Block Blast, or Treasure Chase

---

## Archive Strategy

### Left in Place (with FROZEN markers)
All 5 projects remain at original locations:
- `/mnt/e/projects/sports/` + `FROZEN.md`
- `/mnt/e/projects/LootStackMayhem/` + `FROZEN.md`
- `/mnt/e/projects/block-blast-evolved/` + `FROZEN.md`
- `/mnt/e/projects/treasure-chase/` + `FROZEN.md`
- `/mnt/e/projects/back/` + `FROZEN.md`

**Reason**: Full codebases preserved for reference. Algorithms/SDK already extracted. Projects clearly marked as frozen to prevent accidental resumption.

### Patterns Library Updated
- `/mnt/e/projects/.agent-bus/patterns/sports-betting-algorithms.md` (NEW)
- `/mnt/e/projects/MobileGameCore/` (already existed)

### CLAUDE.md Files Updated
Each project's `CLAUDE.md` now has **FROZEN status at the top** with link to detailed `FROZEN.md` explanation.

---

## Final Recommendations

### DO
1. **Deploy Quant and Discovery** (highest ROI, closest to revenue)
2. **Secure all credentials** (prevent future leaks)
3. **Apply to affiliate programs** (long lead time for Credit revenue)
4. **Use MobileGameCore for ONE mobile game** (if pursuing that vertical)
5. **Merge backtesting into Affiliate** (if that content is valuable)

### DON'T
1. **Unfreeze these 5 projects** without extraordinary justification
2. **Iterate on SPA architecture for SEO sites** (always use SSR)
3. **Mark projects "production-ready" without compiling** (test builds!)
4. **Build multiple games in parallel** (focus on one at a time)
5. **Skip security for monetization** (IAP validation, receipt checks are mandatory)

---

## Success Metrics

This freeze is successful if:
1. **Zero hours spent** on frozen projects in next 3 months
2. **Quant and Discovery deployed** within 1 week
3. **First revenue generated** within 2 weeks
4. **Credit deployed** within 1 month
5. **MobileGameCore used** for any future mobile games (not frozen ones)

---

## Revision History

| Date | Change | Author |
|------|--------|--------|
| 2026-02-11 | Initial freeze of 5 projects | Portfolio Architect |
| 2026-02-11 | Extracted sports algorithms to patterns | Portfolio Architect |
| 2026-02-11 | Created FROZEN.md for each project | Portfolio Architect |
| 2026-02-11 | Updated CLAUDE.md files with FROZEN status | Portfolio Architect |

---

**Status**: FROZEN - 5 projects archived, 320+ hours of waste prevented, focus shifted to 15 viable projects.
