# Strategic Decision Matrix

> One-page visual summary for go/no-go decision

## 🎯 Three Options

### Option A: Pure Obby (Current Plan)
**Status:** ❌ **NOT RECOMMENDED**

| Metric | Rating | Notes |
|--------|--------|-------|
| Market Viability | 🔴 2/10 | Declining genre, saturated |
| Competition | 🔴 1/10 | Tower of Hell dominates (26.6B visits) |
| Differentiation | 🔴 1/10 | No unique value prop |
| Platform Fit (2025) | 🔴 2/10 | Misses Party, Moments, Subscriptions |
| Revenue Potential | 🟡 4/10 | $600-4,800/year realistic |
| Success Probability | 🔴 10-15% | Reach 100 CCU sustained |
| Dev Time | 🟢 16-20 weeks | Baseline |

**TOTAL SCORE:** 13/70 = **19%**

---

### Option B: Roguelike Obby
**Status:** ✅ **RECOMMENDED**

| Metric | Rating | Notes |
|--------|--------|-------|
| Market Viability | 🟢 8/10 | Blue ocean, no major competitor |
| Competition | 🟢 9/10 | Unique positioning |
| Differentiation | 🟢 9/10 | Meta-progression, permadeath, dailies |
| Platform Fit (2025) | 🟢 8/10 | Battle pass, Moments-ready |
| Revenue Potential | 🟢 7/10 | $1,000-6,000/year realistic |
| Success Probability | 🟢 30-40% | Reach 300+ CCU |
| Dev Time | 🟡 20-24 weeks | +4 weeks vs baseline |

**TOTAL SCORE:** 58/70 = **83%**

---

### Option C: Social Co-op Obby
**Status:** 🟡 **VIABLE ALTERNATIVE**

| Metric | Rating | Notes |
|--------|--------|-------|
| Market Viability | 🟢 7/10 | Social games trending |
| Competition | 🟡 5/10 | Moderate (team obbies exist) |
| Differentiation | 🟡 6/10 | Party API integration new |
| Platform Fit (2025) | 🟢 9/10 | Party, voice chat, Moments |
| Revenue Potential | 🟢 8/10 | $1,500-8,000/year realistic |
| Success Probability | 🟢 25-35% | Reach 500+ CCU |
| Dev Time | 🟡 19-23 weeks | +3 weeks vs baseline |

**TOTAL SCORE:** 50/70 = **71%**

---

## 📊 Expected Value Analysis

```
Pure Obby:
  Best case: $4,800 × 15% = $720 EV

Roguelike Obby:
  Best case: $6,000 × 35% = $2,100 EV  ← WINNER

Social Co-op:
  Best case: $8,000 × 30% = $2,400 EV  ← Close second
```

**Winner (Risk-Adjusted):** Social Co-op Obby
**Winner (Innovation):** Roguelike Obby
**Loser:** Pure Obby (current plan)

---

## 🔥 Critical Market Data

### Obby Genre Trends (2024-2025)
- ❌ Traditional obbies: **Declining**
- ✅ Hybrid mechanics: **Growing**
- ✅ Social co-op: **Dominant**
- ✅ Roguelike elements: **15.2% CAGR**

### Platform Changes (Must-Use)
- **Dec 2024:** Party system (up to 6 friends)
- **Q1 2025:** Party API for developers
- **Beta 2025:** Roblox Moments (viral video discovery)
- **2024:** Subscriptions >> Game passes
- **2024:** Public UGC selling

### Monetization Shift
- **Old:** One-time game passes
- **New:** Subscriptions + battle passes
- **Impact:** 3-5x better LTV

---

## ⚡ Quick Decision Guide

### Choose **ROGUELIKE OBBY** if:
- ✅ You want unique market position
- ✅ You're willing to add 4 weeks dev time
- ✅ You like meta-progression mechanics
- ✅ You want best differentiation
- ✅ You're comfortable with higher complexity

### Choose **SOCIAL CO-OP OBBY** if:
- ✅ You want to leverage Party API (Q1 2025)
- ✅ You prioritize social retention
- ✅ You want faster time-to-market
- ✅ You're okay with moderate differentiation
- ✅ You want highest revenue ceiling

### Choose **PURE OBBY** (current plan) if:
- ✅ This is a learning project (not commercial)
- ✅ You have existing audience to launch to
- ✅ You have unique IP/theme
- ❌ **Otherwise: DON'T CHOOSE THIS**

---

## 🚨 Red Flags for Current Plan

1. **Tower of Hell Dominance**
   - 26.6B visits over 5 years
   - 330 sections vs your 20
   - Impossible to compete head-on

2. **Declining Genre**
   - DevForum: "Declining popularity"
   - Developers pivoting away
   - Players demand hybrid mechanics

3. **Missed Platform Features**
   - No Party integration
   - No subscription model
   - Not built for Roblox Moments
   - No UGC selling

4. **Weak Retention**
   - No social hooks
   - No meta-progression
   - No seasonal events planned
   - 20 sections = 2-3 hours content

5. **Outdated Monetization**
   - Game passes (2020 model)
   - One-time revenue
   - Low LTV

---

## 💡 Recommended Path Forward

### **WEEK 0 (NOW):**

**Day 1-2: Prototype Both**
```bash
# Roguelike prototype:
- Build simple coin collection
- Test meta-upgrade shop
- Feel the permadeath loop

# Co-op prototype:
- Test Party API (if early access available)
- Mock team checkpoints
- Test racing friends
```

**Day 3: Decision**
- Which prototype feels better?
- Team size? (Roguelike = solo OK, Co-op = need friends)
- Risk tolerance? (Roguelike = higher, Co-op = moderate)

**Day 4-5: Revise Docs**
- Update all implementation guides
- Add new systems (meta-progression OR Party)
- Revise timeline

**Day 6-7: Start Week 1**
- Follow updated implementation plan

---

### **IF UNDECIDED:**

**Compromise: "Roguelike + Social" Hybrid**

Core modes:
1. **Solo Runs** - Pure roguelike (meta-progression)
2. **Party Runs** - 2-6 friends, shared tower
3. **Daily Challenge** - Specific seed, leaderboard

Best of both worlds:
- ✅ Unique mechanics (roguelike)
- ✅ Social retention (Party API)
- ✅ Viral potential (Roblox Moments)
- ✅ Modern monetization (battle pass)

Trade-off:
- ⚠️ +6 weeks dev time (26 total)
- ⚠️ Highest complexity
- ✅ Best market positioning

---

## 📋 Implementation Changes Required

### For Roguelike Pivot:

**Add:**
- Currency system (coins during runs)
- Meta-progression shop (permanent upgrades)
- Daily challenge system (seed + leaderboard)
- Run validation (anti-cheat for permadeath)
- Battle pass (seasonal rewards)

**Remove:**
- ProfileService checkpoint saves (ephemeral runs)

**Modify:**
- Generator (no checkpoints)
- DataService (track runs, unlocks, not stages)
- Analytics (track runs, not stage completions)

**Time: +4 weeks**

---

### For Social Co-op Pivot:

**Add:**
- Party API integration (Q1 2025)
- Team checkpoint sync
- Team leaderboards
- Voice chat support
- Racing mechanics

**Modify:**
- Generator (team spawn points)
- CheckpointService (team-based)
- Analytics (track team performance)

**Time: +3 weeks**

---

## 🎯 Final Recommendation

```
IF (experience = beginner)
  → Co-op Obby (safer, proven social retention)

ELSE IF (want_unique_positioning)
  → Roguelike Obby (blue ocean)

ELSE IF (learning_project)
  → Pure Obby (keep current plan)

ELSE
  → Roguelike + Social Hybrid (best but hardest)
```

**My Vote: ROGUELIKE OBBY**
- Best risk/reward ratio
- Unique market position
- Modern retention mechanics
- Worth +4 weeks dev time

---

## 📞 Next Action

**RIGHT NOW:**
1. Read [STRATEGIC_EVALUATION.md](./STRATEGIC_EVALUATION.md) (full analysis)
2. Choose: Roguelike / Co-op / Pure / Abort
3. If Roguelike or Co-op: Spend 2 days prototyping
4. Make final decision by end of week
5. Update all docs if pivoting

**DON'T:**
- ❌ Start Week 1 implementation without deciding
- ❌ Proceed with current plan blindly
- ❌ Ignore market data

**DO:**
- ✅ Prototype both options (2 days)
- ✅ Research Party API access
- ✅ Make informed decision
- ✅ Revise docs if pivoting

---

**Last Updated:** 2025-01-27
**Decision Deadline:** End of Week 0 (before implementation starts)
