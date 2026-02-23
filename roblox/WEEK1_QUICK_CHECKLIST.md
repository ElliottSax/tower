# Week 1 Testing - Quick Reference Checklist

**Start Date:** 2026-02-22
**Estimated Time:** 16-20 hours
**Status:** Ready to Begin

---

## Pre-Flight Checklist

### Setup (15 minutes)
- [ ] Roblox Studio installed and updated
- [ ] All 5 games opened in Studio
- [ ] Test scripts folder created in each game
- [ ] Test accounts created (TestUser1-5)
- [ ] WEEK1_TESTING_PROGRESS.md opened for tracking
- [ ] TESTING_GUIDE.md reviewed

---

## Daily Testing Schedule

### Day 1: Tower Ascent + Speed Run Universe (8-10 hours)

**Morning Session (4-5 hours):**
- [ ] Tower Ascent - Fix #1: Debug Mode (1h)
  - Run test_debug_mode.lua
  - Check _G.TowerAscent in Studio vs Production
  - Document results

- [ ] Tower Ascent - Fix #2: Authentication (1h)
  - Run test_authentication.lua
  - Test with valid/nil players
  - Document results

- [ ] Tower Ascent - Fix #3: VIP Race (2h)
  - Run test_vip_race.lua
  - Manual VIP multiplier testing
  - Check VIP caching
  - Document results

- [ ] Tower Ascent - Fix #4: Coin Underflow (1h)
  - Run test_coin_underflow.lua
  - Test underflow protection
  - Verify leaderstats
  - Document results

**Afternoon Session (4-5 hours):**
- [ ] Tower Ascent - Fix #5: Monetization (3h)
  - Run test_monetization.lua
  - Validate product IDs
  - Manual purchase testing (if budget allows)
  - Document results

- [ ] Speed Run Universe - Fix #1: Speedrun Validation (2h)
  - Test valid speedrun times
  - Attempt impossible times (0.1s)
  - Submit backwards checkpoints
  - Verify anti-cheat working
  - Document results

**End of Day:**
- [ ] Update WEEK1_TESTING_PROGRESS.md
- [ ] Log any bugs found
- [ ] Calculate progress (expect ~25% complete)

---

### Day 2: Speed Run Universe (6-8 hours)

**Morning Session (4 hours):**
- [ ] Speed Run - Fix #2: Player Cleanup (1h)
  - Test ActiveRuns cleanup on leave
  - Verify ghost recording saved
  - Join/leave 100 times, check memory
  - Document results

- [ ] Speed Run - Fix #3: Ghost Compression (2h)
  - Complete 5-min speedrun
  - Verify ghost <100KB
  - Test decompression accuracy
  - Check playback smoothness
  - Document results

- [ ] Speed Run - Fix #4: Size Limits (1h)
  - Test 10-minute recording limit
  - Verify 6000 frame limit
  - Check DataStore save succeeds
  - Document results

**Afternoon Session (2-4 hours):**
- [ ] Speed Run - Fix #5: Leaderboard Error Handling (2h)
  - Test normal leaderboard fetch
  - Mock DataStore failure
  - Verify stale cache fallback
  - Check client UI shows correct data
  - Document results

- [ ] Integration: Speed Run full playthrough (2h)
  - Complete end-to-end speedrun
  - Race against ghost
  - Check leaderboard
  - Verify all fixes working together

**End of Day:**
- [ ] Update WEEK1_TESTING_PROGRESS.md
- [ ] Log any bugs found
- [ ] Calculate progress (expect ~50% complete)

---

### Day 3: Adventure Story Obby + Pet Collector Sim (6-8 hours)

**Morning Session (3-4 hours):**
- [ ] Adventure - Fix #1: Checkpoint Validation (2h)
  - Set valid checkpoint
  - Attempt distant checkpoint (should fail)
  - Send invalid checkpoint ID
  - Verify exploiter flagged
  - Document results

- [ ] Adventure - Fix #2: Coin Cap (1h)
  - Normal coin collection
  - Collect near cap (999,999,900)
  - Collect at cap (1,000,000,000)
  - Document results

- [ ] Adventure - Fix #3: Collectible Memory (2h)
  - Spawn 10 collectibles, collect all
  - Rapid collection stress test (100 in 10s)
  - Long-running server test (30 min)
  - Monitor memory usage
  - Document results

**Afternoon Session (3-4 hours):**
- [ ] Pet Collector - Fix #1: Negative Coins (1h)
  - Hatch with sufficient coins
  - Attempt hatch with insufficient coins
  - Unlock world with coins
  - Verify RemoveCoins used
  - Document results

- [ ] Pet Collector - Fix #2: Trading Disabled (30 min)
  - Attempt to initiate trade
  - Check client notification
  - Verify TRADING_ENABLED = false
  - Document results

- [ ] Pet Collector - Fix #3: SecureRemotes (2h)
  - Spam hatch egg 25x (rate limit test)
  - Send invalid egg type
  - Send wrong data types
  - Test delete rate limit
  - Document results

**End of Day:**
- [ ] Update WEEK1_TESTING_PROGRESS.md
- [ ] Log any bugs found
- [ ] Calculate progress (expect ~80% complete)

---

### Day 4: Dimension Hopper + Final Validation (4-6 hours)

**Morning Session (2-3 hours):**
- [ ] Dimension - Fix #1: Fragment Memory (2h)
  - Spawn 10 fragments, collect all
  - Stress test 100 fragments
  - Long-running server test (2 hours) - run in background
  - Check dimension unload cleanup
  - Monitor memory throughout
  - Document results

**Afternoon Session (2-3 hours):**
- [ ] Integration Testing (2h)
  - Run MasterTestRunner.lua on all games
  - Verify overall pass rate
  - Re-test any failed tests
  - Document final results

- [ ] Final Documentation (1h)
  - Complete WEEK1_TESTING_PROGRESS.md
  - Create summary report
  - List all bugs found (P0/P1/P2/P3)
  - Calculate final statistics

**End of Day:**
- [ ] Update WEEK1_TESTING_PROGRESS.md with final status
- [ ] Create bug priority list
- [ ] Plan Week 2: Load & Performance Testing
- [ ] Calculate progress (expect 100% complete)

---

## Quick Stats Tracking

After each session, update these stats:

**Current Progress:**
- Tests Completed: ___/60
- Tests Passed: ___
- Tests Failed: ___
- Tests Skipped: ___
- Manual Tests Pending: ___
- Bugs Found (P0): ___
- Bugs Found (P1): ___
- Bugs Found (P2): ___
- Bugs Found (P3): ___
- Hours Spent: ___
- Hours Remaining: ___

---

## Critical Path

**Must Complete Before Moving to Week 2:**
1. ✅ All automated tests run and documented
2. ✅ All manual tests executed
3. ✅ All P0 bugs fixed and verified
4. ✅ All P1 bugs triaged (fix or defer)
5. ✅ Test summary report created
6. ✅ Sign-off from QA lead

---

## Emergency Contacts

**Blockers:**
- Can't run test scripts → Check TESTING_GUIDE.md
- Test keeps failing → Document as bug, continue
- No access to test environment → Use Studio mode
- Need help → Check MASTER_TESTING_SUITE.md

**Escalation:**
- P0 bug found → Stop testing, fix immediately
- P1 bug found → Document, continue testing
- P2/P3 bug found → Document, fix later

---

## Success Criteria

**Week 1 Complete When:**
- [ ] All 60 test cases executed
- [ ] 90%+ pass rate achieved
- [ ] No P0 bugs remaining
- [ ] P1 bugs triaged with fix plan
- [ ] Performance baselines established
- [ ] Documentation complete

---

## Notes Section

**Use this space for daily notes:**

### Day 1 Notes:


### Day 2 Notes:


### Day 3 Notes:


### Day 4 Notes:


---

**Last Updated:** 2026-02-22
**Next Review:** Daily at end of each testing session
