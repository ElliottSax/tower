# Roblox Games Launch Prioritization Roadmap
*Strategic launch plan for 17 game portfolio*

## Executive Summary

**Goal:** Launch games in order of readiness and revenue potential
**Timeline:** 6-month phased rollout
**Success Metrics:** Player retention, monetization, bug reports

---

## Launch Waves

### 🚀 Wave 1 - Immediate Launch (Month 1-2)
*Production-ready after critical fixes*

#### 1. Tower Ascent Game ⭐ FLAGSHIP
**Status:** 95% Ready
**Estimated Work:** 8-12 hours
**Launch Date:** Week 2
**Revenue Potential:** HIGH

**Critical Fixes:**
- [ ] Verify `GameConfig.Debug.Enabled = false`
- [ ] Add `SecurityManager.IsAuthenticated()` method
- [ ] Fix VIP race condition (cache status in DataStore)
- [ ] Add coin underflow protection in `RemoveCoins()`
- [ ] Update all monetization product IDs (currently placeholder 0)

**Launch Checklist:**
- [ ] Deploy to test server (50 players)
- [ ] Run 48-hour stress test
- [ ] Monitor error logs
- [ ] Verify all DataStore saves succeed
- [ ] Test all game passes work
- [ ] Verify VIP status persists

**Post-Launch Monitoring:**
- Track CCU (Concurrent Users)
- Monitor ban escalation system
- Watch for exploit attempts
- Check DataStore budget usage

---

#### 2. Speed Run Universe ⭐ COMPETITIVE
**Status:** 90% Ready
**Estimated Work:** 12-16 hours
**Launch Date:** Week 3
**Revenue Potential:** MEDIUM-HIGH

**Critical Fixes:**
- [ ] Implement `SecurityManager.ValidateSpeedrunTime()` (currently missing)
- [ ] Add `Players.PlayerRemoving` cleanup for ActiveRuns
- [ ] Compress ghost data before DataStore save
- [ ] Add ghost data size limits (prevent DataStore quota issues)
- [ ] Implement leaderboard integration error handling

**Optimization Tasks:**
- [ ] Reduce ghost frame rate from 10 FPS to 5 FPS (bandwidth)
- [ ] Add ghost data compression (reduce save size by 60-80%)
- [ ] Implement data pruning (delete ghosts older than 30 days)

**Launch Checklist:**
- [ ] Test ghost recording with 20+ concurrent runs
- [ ] Verify leaderboard updates correctly
- [ ] Test split time accuracy
- [ ] Verify personal best tracking
- [ ] Test ghost playback with 10+ ghosts

**Monetization:**
- Cosmetic trails
- Ghost slots (3 free, +5 for Robux)
- Premium leaderboard badges
- Custom finish effects

---

### 🎯 Wave 2 - Quick Wins (Month 2-3)
*Good foundation, moderate fixes needed*

#### 3. Adventure Story Obby
**Status:** 85% Ready
**Estimated Work:** 16-20 hours
**Launch Date:** Week 5
**Revenue Potential:** MEDIUM

**Critical Fixes:**
- [ ] Fix checkpoint CFrame validation (security critical)
- [ ] Add coin cap validation
- [ ] Fix collectible animation memory leak
- [ ] Remove `_G` global in production mode
- [ ] Implement proper ban duration calculation

**Feature Additions:**
- [ ] Mobile UI support (50% of Roblox traffic)
- [ ] Add tutorial level
- [ ] Implement daily login rewards

---

#### 4. Merge Mania
**Status:** 80% Ready
**Estimated Work:** 20-24 hours
**Launch Date:** Week 7
**Revenue Potential:** HIGH

**Critical Fixes:**
- [ ] Include ProfileService library dependency
- [ ] Verify all merge operations are server-authoritative
- [ ] Add checksums for grid state validation
- [ ] Implement anti-cheat for golden item generation
- [ ] Add bounds checking on grid operations

**Polish:**
- Excellent UI already implemented
- Add more particle effects
- Implement prestige path visuals

---

### 🔧 Wave 3 - Moderate Rework (Month 3-4)
*Needs significant security and stability work*

#### 5. Dimension Hopper
**Estimated Work:** 32-40 hours
**Launch Date:** Week 10
**Revenue Potential:** MEDIUM

**Major Fixes:**
- [ ] Fix memory leaks in level generator (critical)
- [ ] Implement anti-cheat system
- [ ] Add server-side speed validation
- [ ] Fix race position validation
- [ ] Implement session locking

---

#### 6. Grow a World
**Estimated Work:** 24-32 hours
**Launch Date:** Week 11
**Revenue Potential:** MEDIUM-HIGH

**Critical Fixes:**
- [ ] Fix ProfileService `Release()` bug (CRITICAL - causes data loss)
- [ ] Include ProfileService package
- [ ] Implement proper save without releasing session
- [ ] Add server-side plant growth validation
- [ ] Balance multiplier stacking

**Unique Selling Point:** Best data management pattern in portfolio

---

#### 7. Pet Collector Sim
**Estimated Work:** 40-48 hours
**Launch Date:** Week 12
**Revenue Potential:** HIGH

**Critical Fixes:**
- [ ] Fix negative coin exploit (use `RemoveCoins()` not `AddCoins(-x)`)
- [ ] Complete trading system implementation or disable it
- [ ] Integrate SecureRemotes into all services
- [ ] Add input validation throughout
- [ ] Fix ProfileService timeout handler

**Trading System Decision:**
- Option A: Complete implementation (24 hours)
- Option B: Disable trading until post-launch (0 hours)
- **Recommendation:** Disable, launch, add later

---

### 🏗️ Wave 4 - Heavy Development (Month 4-5)
*Requires significant rework before launch*

#### 8. Multiplication Game
**Estimated Work:** 48-60 hours
**Launch Date:** Week 15

**Critical Fixes:**
- [ ] Add comprehensive remote validation
- [ ] Fix race conditions in currency
- [ ] Implement transaction locking
- [ ] Add object cleanup and limits
- [ ] Fix memory leaks
- [ ] Add admin IDs to config

---

#### 9. Anime Training Simulator
**Estimated Work:** 40-48 hours
**Launch Date:** Week 16

**Critical Fixes:**
- [ ] Implement server-side validation for training gains
- [ ] Add session locking
- [ ] Fix monetization bug (InstantRebirth gives 999M coins)
- [ ] Validate all stat gain calculations
- [ ] Add comprehensive anti-cheat

---

#### 10. Dungeon Doors
**Estimated Work:** 32-40 hours
**Launch Date:** Week 17

**Critical Fixes:**
- [ ] Add save retry logic
- [ ] Validate shop purchases server-side
- [ ] Add rate limiting to door voting
- [ ] Implement PlayerRemoving cleanup
- [ ] Add floor progression validation

---

### ⚠️ Wave 5 - Major Rework Required (Month 5-6)
*Consider rebuild vs. fix decision*

#### 11-13. Pet Kingdom Tycoon, Treasure Hunt Islands, Battle Royale Legends
**Combined Estimated Work:** 80-120 hours
**Launch Date:** Week 19-21

**Strategy:**
- Standardize on security patterns from Wave 1-2 games
- Share code between similar games
- Consider merging features into stronger games

**Decision Point:**
- Fix vs. Rebuild analysis needed
- ROI calculation vs. development time
- May be better to focus on new games

---

### 🔴 Wave 6 - Not Recommended for Launch
*Fundamental issues, recommend sunset or complete rebuild*

#### 14. Escape the Factory
**Status:** Critical bugs, minimal security
**Recommendation:** **Sunset or complete rebuild**

**Issues:**
- Severe table deep copy bug
- No security manager
- Abbreviated code (unmaintainable)
- Estimated 60+ hours to make production-ready

---

#### 15. Restaurant Empire
**Status:** Critical timing exploit
**Recommendation:** **Sunset or complete rebuild**

**Issues:**
- Client controls cooking timing (critical exploit)
- Abbreviated code (unmaintainable)
- Minimal validation
- Estimated 50+ hours to make production-ready

---

## Launch Timeline

```
Month 1-2: WAVE 1
├─ Week 1: Tower Ascent fixes
├─ Week 2: Tower Ascent LAUNCH 🚀
├─ Week 3: Speed Run Universe LAUNCH 🚀
└─ Week 4: Monitor & optimize Wave 1

Month 2-3: WAVE 2
├─ Week 5: Adventure Story Obby LAUNCH 🚀
├─ Week 6: Monitor & optimize
├─ Week 7: Merge Mania LAUNCH 🚀
└─ Week 8: Monitor & optimize

Month 3-4: WAVE 3
├─ Week 9: Wave 3 development sprint
├─ Week 10: Dimension Hopper LAUNCH 🚀
├─ Week 11: Grow a World LAUNCH 🚀
└─ Week 12: Pet Collector Sim LAUNCH 🚀

Month 4-5: WAVE 4
├─ Week 13-14: Wave 4 development
├─ Week 15: Multiplication Game LAUNCH 🚀
├─ Week 16: Anime Training Sim LAUNCH 🚀
└─ Week 17: Dungeon Doors LAUNCH 🚀

Month 5-6: WAVE 5
├─ Week 18: Wave 5 development
├─ Week 19-21: Remaining games LAUNCH 🚀
└─ Week 22-24: Portfolio optimization

Month 6+: OPERATIONS
├─ Monitor all live games
├─ Content updates
├─ Event planning
└─ New game development
```

---

## Revenue Projections

### High Revenue Potential
1. **Tower Ascent** - Premium placement, competitive, replayable
2. **Pet Collector Sim** - Proven pet game formula, high engagement
3. **Merge Mania** - Idle mechanics, high retention
4. **Grow a World** - Progression mechanics, prestige system

### Medium Revenue Potential
5. **Speed Run Universe** - Competitive niche, smaller audience
6. **Adventure Story Obby** - Casual audience, lower monetization
7. **Dimension Hopper** - Unique concept, unproven market

### Low Revenue Potential
8. **Educational/Niche Games** - Smaller audience, harder to monetize

---

## Resource Allocation

### Development Team Priorities

**Phase 1 (Weeks 1-4):** 100% on Wave 1
- Full team on Tower Ascent & Speed Run Universe
- Goal: Perfect launches with zero critical bugs

**Phase 2 (Weeks 5-8):** 70% Wave 2, 30% Wave 1 support
- Main team on new launches
- Support team on live ops

**Phase 3 (Weeks 9-12):** 60% Wave 3, 40% live games
- Balance new development with live game support
- Start content updates for Wave 1 games

**Phase 4+:** 50/50 split
- Half team on new launches
- Half team on updates and events

---

## Success Metrics

### Per-Game KPIs

**Week 1 Post-Launch:**
- [ ] CCU > 10 players
- [ ] Average session > 10 minutes
- [ ] Zero critical bugs
- [ ] DataStore success rate > 99%

**Month 1 Post-Launch:**
- [ ] Day 7 retention > 20%
- [ ] Monetization > $100
- [ ] Exploit reports = 0
- [ ] Average rating > 70%

**Month 3 Post-Launch:**
- [ ] Day 30 retention > 10%
- [ ] Monthly revenue > $500
- [ ] Active community (Discord/group)
- [ ] Content update deployed

---

## Risk Mitigation

### High-Risk Items

**Tower Ascent VIP Bug:**
- Risk: VIP players lose 2x multiplier
- Impact: HIGH (refund requests, bad reviews)
- Mitigation: Cache VIP status in DataStore, test thoroughly

**Data Loss in Any Game:**
- Risk: ProfileService misconfiguration
- Impact: CRITICAL (player trust, refunds)
- Mitigation: Test server saves, implement retry logic, 48-hour stress test

**Exploit Discovery Post-Launch:**
- Risk: Exploiters find vulnerability
- Impact: HIGH (economy ruined, player exodus)
- Mitigation: Security audit, anti-cheat monitoring, fast response plan

---

## Go/No-Go Criteria

### Before ANY Launch:

**Security:**
- [ ] All remote events have validation
- [ ] Rate limiting implemented
- [ ] Anti-cheat active (if competitive game)
- [ ] DataStore retry logic in place
- [ ] Session locking working

**Testing:**
- [ ] 48-hour test server successful
- [ ] Load tested with 50+ players
- [ ] Zero critical bugs in past 24 hours
- [ ] All monetization products tested
- [ ] Mobile compatibility verified

**Operations:**
- [ ] Error logging configured
- [ ] Discord webhook for alerts
- [ ] Backup plan for rollback
- [ ] Support team briefed
- [ ] Emergency contact list ready

**Business:**
- [ ] Monetization products uploaded
- [ ] Game description written
- [ ] Thumbnail and icon ready
- [ ] Marketing plan prepared (if applicable)

---

## Post-Launch Playbook

### Week 1 After Launch

**Daily Tasks:**
- Monitor error logs every 4 hours
- Check DataStore success rates
- Review player feedback
- Watch for exploit reports
- Track CCU and retention

**Weekly Tasks:**
- Analyze retention funnel
- Review monetization data
- Plan content update
- Update roadmap
- Team retrospective

### Month 1 After Launch

**Content Updates:**
- New levels/content
- Balance adjustments
- Bug fixes
- QOL improvements
- Event planning

**Community:**
- Discord server setup
- Social media presence
- Influencer outreach
- Player surveys

---

## Adonis Plugins Timeline

**Deployment:** Week 1 (before Tower Ascent launch)

**Critical Fixes (4-6 hours):**
- [ ] Sanitize webhook inputs
- [ ] Validate webhook URLs
- [ ] Fix BanHistory API
- [ ] Add command rate limiting

**Deploy With:** Tower Ascent (they're designed for it)

---

## Sunset Recommendations

### Games to Sunset (Not Launch)

1. **Escape the Factory**
   - Reason: Critical bugs, unmaintainable code
   - Estimated fix: 60+ hours
   - ROI: Low
   - Decision: Archive, reuse assets in other games

2. **Restaurant Empire**
   - Reason: Fundamental timing exploit
   - Estimated fix: 50+ hours
   - ROI: Low
   - Decision: Archive or complete rebuild

### Asset Salvage
- Reuse UI components from Restaurant Empire
- Reuse security patterns for other games
- Archive for future reference

---

## Success Stories (Projected)

### Tower Ascent - Flagship Success
- **Month 1:** 1,000 CCU, $2,000 revenue
- **Month 3:** 2,500 CCU, $8,000/month
- **Month 6:** 5,000 CCU, $15,000/month
- Feature in Roblox discover page

### Speed Run Universe - Competitive Hub
- **Month 1:** 500 CCU, $800 revenue
- **Month 3:** 1,200 CCU, $2,500/month
- **Month 6:** 2,000 CCU, $5,000/month
- Host competitive tournaments

### Pet Collector Sim - Whale Magnet
- **Month 1:** 800 CCU, $1,500 revenue
- **Month 3:** 1,800 CCU, $6,000/month
- **Month 6:** 3,000 CCU, $12,000/month
- High monetization per player

---

## Quarterly Reviews

**Q1 (Month 1-3):**
- Review Wave 1 & 2 performance
- Adjust Wave 3 plans based on learnings
- Identify breakout successes
- Sunset underperformers

**Q2 (Month 4-6):**
- Scale successful games
- Cut losses on poor performers
- Plan major updates for top games
- Evaluate new game concepts

**Q3 (Month 7-9):**
- Focus on top 3-5 games
- Major content expansions
- Seasonal events
- Influencer partnerships

---

## Final Recommendations

### Priority Focus:
1. **Tower Ascent** - Your best game, make it perfect
2. **Speed Run Universe** - Unique, competitive, ready
3. **Pet Collector Sim** - High revenue potential after fixes

### Quick Wins:
- Launch Tower Ascent Week 2
- Launch Speed Run Universe Week 3
- Double down on these two for Month 1

### Strategic Decisions:
- Sunset Escape Factory & Restaurant Empire
- Delay or cancel Wave 5 games
- Focus resources on top performers
- New games > fixing broken games

### Team Allocation:
- 50% on Wave 1 perfection
- 30% on Wave 2 preparation
- 20% on live ops planning

---

**Version:** 1.0
**Last Updated:** 2026-02-22
**Next Review:** After Wave 1 launches
