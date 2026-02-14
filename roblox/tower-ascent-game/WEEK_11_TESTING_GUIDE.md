# Week 11: Testing & Polish - Testing Guide

**Date:** November 30, 2025
**Status:** ✅ **TESTING INFRASTRUCTURE READY**
**Tools:** DebugUtilities extended with Week 9-10 system tests

---

## 🧪 Overview

Week 11 testing infrastructure provides comprehensive automated testing for all Tower Ascent systems implemented in Weeks 1-10.

### Available Test Suites

1. **Section Templates** - All 50 section templates (Easy, Medium, Hard, Expert)
2. **Tower Validation** - Generated tower integrity checks
3. **Moving Platforms** - Platform detection and motion validation
4. **Theme System** - Theme application and transitions
5. **Hazard System** *(NEW - Week 11)* - All 8 hazard types across 24 sections
6. **Weather System** *(NEW - Week 11)* - 4 weather types and theme integration
7. **Comprehensive Test** *(NEW - Week 11)* - All tests in sequence

---

## 🚀 Quick Start

### Run All Tests

```lua
-- Server console
_G.TowerAscent.DebugUtilities.RunComprehensiveTests(_G.TowerAscent.Tower)
```

**Output:** Complete system validation with pass/fail for all systems

---

### Run Individual Test Suites

**1. Test Section Templates:**
```lua
_G.TowerAscent.DebugUtilities.TestAllSections()
```
- Tests all 50 section templates
- Validates build integrity
- Checks for missing components

---

**2. Validate Tower:**
```lua
_G.TowerAscent.DebugUtilities.ValidateTower(_G.TowerAscent.Tower)
```
- Checks tower exists in workspace
- Validates all sections
- Verifies finish line
- Counts platforms

---

**3. Test Moving Platforms:**
```lua
_G.TowerAscent.DebugUtilities.TestMovingPlatforms(_G.TowerAscent.Tower)
```
- Finds all moving platforms
- Validates attributes (StartPosition, EndPosition, Speed)
- Checks MovingPlatformService tracking

---

**4. Test Themes:**
```lua
_G.TowerAscent.DebugUtilities.TestThemes(_G.TowerAscent.Tower)
```
- Validates theme application (Grasslands, Desert, Snow, Volcano)
- Tests theme detection by section number
- Checks theme distribution

---

**5. Test Hazards** *(NEW - Week 11)*:
```lua
_G.TowerAscent.DebugUtilities.TestHazards(_G.TowerAscent.Tower)
```

**What It Tests:**
- **Hazard Detection** - Finds all hazards by HazardType attribute
- **Hazard Counts** - Validates expected counts (Lava: 6, Spikes: 8, etc.)
- **Attribute Validation** - Checks required attributes per hazard type:
  - Lava: Damage attribute
  - Spikes: Damage = 40
  - Ice: FrictionMultiplier
  - WindZone: WindDirection, WindForce
  - Quicksand: SpeedMultiplier
  - RotatingObstacle: RotationSpeed
  - PoisonGas: DamagePerSecond = 10
  - FallingPlatform: CollapseTime

**Expected Results:**
```
Total hazards found (40) ✓ PASS
Lava hazards (6 found) ✓ PASS
Spikes hazards (8 found) ✓ PASS
Ice hazards (6 found) ✓ PASS
WindZone hazards (5 found) ✓ PASS
Quicksand hazards (3 found) ✓ PASS
RotatingObstacle hazards (4 found) ✓ PASS
PoisonGas hazards (3 found) ✓ PASS
FallingPlatform hazards (5 found) ✓ PASS
Lava count validation (expected 6) ✓ PASS
Spikes count validation (expected 8) ✓ PASS
... (all validations)
```

---

**6. Test Weather** *(NEW - Week 11)*:
```lua
_G.TowerAscent.DebugUtilities.TestWeather()
```

**What It Tests:**
- **WeatherService Loading** - Verifies service exists in _G.TowerAscent
- **Weather Type Switching** - Tests all 4 types (Clear, Sandstorm, Blizzard, Volcanic Ash)
- **Active Weather Verification** - Confirms weather changes correctly
- **Theme-to-Weather Mapping** - Tests theme integration:
  - Grasslands → Clear
  - Desert → Sandstorm
  - Snow → Blizzard
  - Volcano → Volcanic Ash
- **Weather Event Triggering** - Tests manual event trigger
- **GetStatus Function** - Validates status API

**Expected Results:**
```
WeatherService loaded ✓ PASS
Set weather: Clear ✓ PASS
Active weather is Clear ✓ PASS
Set weather: Sandstorm ✓ PASS
Active weather is Sandstorm ✓ PASS
Set weather: Blizzard ✓ PASS
Active weather is Blizzard ✓ PASS
Set weather: VolcanicAsh ✓ PASS
Active weather is VolcanicAsh ✓ PASS
Theme Grasslands → Weather ✓ PASS
Theme Grasslands maps to Clear ✓ PASS
... (all theme mappings)
Trigger weather event ✓ PASS
GetStatus function ✓ PASS
Status has ActiveWeather ✓ PASS
Status has IntensityLevel ✓ PASS
Status has EventCooldown ✓ PASS
Status has HasEvents ✓ PASS
```

---

## 📊 Test Result Format

### Pass/Fail Output

```
✓ PASS: Test name
✗ FAIL: Test name - Error message
```

### Test Summary

```
============================================================
TEST SUMMARY
============================================================
Total Tests: 91
Passed: 91 (100.0%)
Failed: 0 (0.0%)
============================================================
```

### Error Reporting

If tests fail:
```
ERRORS:
  1. Test name: Error description
  2. Another test: Another error
  ...
```

---

## 🔧 Performance Profiling

### Tower Generation Profiling

```lua
_G.TowerAscent.DebugUtilities.ProfileTowerGeneration()
```

**Output:**
```
Tower generation time: 1.234 seconds
Sections: 50
Average time per section: 0.0247 seconds
```

**Performance Targets:**
- Total generation time: <5 seconds
- Average per section: <0.1 seconds

---

### Stress Testing

```lua
_G.TowerAscent.DebugUtilities.StressTest(10) -- 10 iterations
```

**What It Does:**
- Generates multiple towers
- Validates each tower
- Measures total/average generation time
- Detects memory leaks

**Performance Targets:**
- All iterations pass
- Average generation time stable (<5 seconds)
- No memory leaks (stable memory usage)

---

## 📋 Diagnostic Reports

### Full Diagnostic Report

```lua
_G.TowerAscent.DebugUtilities.GenerateFullReport(_G.TowerAscent.Tower)
```

**Output Example:**
```
=== TOWER ASCENT DIAGNOSTIC REPORT ===
Generated: 2025-11-30 15:30:00

=== SYSTEM STATUS ===
SectionLoader templates: 50
  - Easy: 10
  - Medium: 15
  - Hard: 15
  - Expert: 10

=== TOWER STATUS ===
Name: Tower_1732998600
Seed: 1732998600
Parent: Workspace
Sections: 50
Moving platforms: 18

=== MOVING PLATFORM SERVICE ===
Active platforms: 18

=== THEME SERVICE ===
Current theme: Grasslands

=== END REPORT ===
```

---

## 🐛 Bug Reporting

### Test Failure Investigation

When a test fails:

1. **Note the test name** - Example: "Spikes #3 attributes"
2. **Check error message** - Example: "Expected 40 damage, got 30"
3. **Locate the issue** - Find Section with Spikes #3
4. **Reproduce manually** - Visit section in-game, test hazard
5. **Fix the issue** - Update section template
6. **Re-run test** - Verify fix

### Common Test Failures

**"Template not found in ServerStorage"**
- **Cause:** Section template missing from ServerStorage/Sections folder
- **Fix:** Run SectionLoader to rebuild templates

**"Missing Start attachment"**
- **Cause:** Section template missing Start or Next attachment
- **Fix:** Update SectionBuilder to add attachments

**"No hazards found in tower"**
- **Cause:** HazardService not initialized or hazards not created
- **Fix:** Check init.server.lua Phase 7, verify HazardService.Init(tower)

**"WeatherService not found"**
- **Cause:** WeatherService not in _G.TowerAscent
- **Fix:** Check init.server.lua Phase 8, verify initialization order

---

## 📈 Testing Metrics

### Week 11 Testing Goals

| Category | Test Cases | Target Coverage | Status |
|----------|------------|-----------------|--------|
| **Section Templates** | 50 | 100% | ✅ Ready |
| **Tower Validation** | 10 | 100% | ✅ Ready |
| **Moving Platforms** | 6 | 100% | ✅ Ready |
| **Theme System** | 54 | 100% | ✅ Ready |
| **Hazard System** | 40+ | 100% | ✅ Ready |
| **Weather System** | 20+ | 100% | ✅ Ready |
| **TOTAL** | **180+** | **100%** | ✅ **Ready** |

---

## 🎯 Testing Checklist

### Pre-Launch Testing

**Core Systems:**
- [ ] Run `TestAllSections()` - All 50 sections pass
- [ ] Run `ValidateTower(tower)` - Tower validates correctly
- [ ] Run `TestMovingPlatforms(tower)` - All platforms detected
- [ ] Run `TestThemes(tower)` - All themes applied correctly

**Week 9-10 Systems:**
- [ ] Run `TestHazards(tower)` - All 40 hazards validated
- [ ] Run `TestWeather()` - All 4 weather types functional

**Performance:**
- [ ] Run `ProfileTowerGeneration()` - <5 seconds
- [ ] Run `StressTest(10)` - All pass, stable memory

**Comprehensive:**
- [ ] Run `RunComprehensiveTests(tower)` - ALL TESTS PASS

**Result:** ✅ Production ready OR ❌ Review failures

---

## 🔍 Manual Testing Procedures

### 1. Hazard Manual Testing

**For each hazard type, test:**

**Lava:**
1. Teleport to section with lava
2. Touch lava
3. Expected: Instant death, respawn at checkpoint
4. Verify: Health reset, position changed

**Spikes:**
1. Teleport to section with spikes
2. Touch spikes
3. Expected: 40 HP damage, damage cooldown
4. Verify: Health reduced by 40, can't spam damage

**Ice:**
1. Teleport to section with ice
2. Walk on ice surface
3. Expected: Slippery movement (reduced friction)
4. Verify: Harder to stop, slides more

**WindZone:**
1. Teleport to section with wind zone
2. Jump through wind zone
3. Expected: Force applied in wind direction
4. Verify: Character pushed sideways/direction

**Quicksand:**
1. Teleport to section with quicksand
2. Walk on quicksand
3. Expected: 70% speed reduction
4. Verify: Slow movement, visual sinking

**RotatingObstacle:**
1. Teleport to section with rotating obstacle
2. Wait for obstacle to rotate
3. Touch obstacle
4. Expected: Knockback + 20 HP damage
5. Verify: Character pushed, health reduced

**PoisonGas:**
1. Teleport to section with poison gas
2. Enter gas zone
3. Expected: 10 DPS (damage per second)
4. Verify: Health decreases over time

**FallingPlatform:**
1. Teleport to section with falling platform
2. Stand on platform
3. Expected: Platform shakes, becomes transparent, falls in 0.5-0.6s
4. Verify: Platform disappears, respawns after time

---

### 2. Weather Manual Testing

**For each weather type, test:**

**Clear (Grasslands):**
1. Run: `_G.TowerAscent.WeatherService.AdminSetWeather("Clear")`
2. Expected: Bright lighting, peaceful nature sounds, no particles
3. Verify: Brightness 2, fog 500 studs, audio playing

**Sandstorm (Desert):**
1. Run: `_G.TowerAscent.WeatherService.AdminSetWeather("Sandstorm")`
2. Expected: Sandy haze, blowing sand particles, wind howling
3. Verify: Fog 200 studs (tan color), particles visible, audio playing
4. Wait for event (20-45s)
5. Expected: 2x particles, 1.5x sound (8 seconds)

**Blizzard (Snow):**
1. Run: `_G.TowerAscent.WeatherService.AdminSetWeather("Blizzard")`
2. Expected: Overcast lighting, heavy snowfall, wind sounds
3. Verify: Fog 150 studs (white), snow particles falling, audio playing
4. Wait for event
5. Expected: 2x particles, 1.5x sound

**Volcanic Ash (Volcano):**
1. Run: `_G.TowerAscent.WeatherService.AdminSetWeather("VolcanicAsh")`
2. Expected: Dark atmosphere, ash + embers, rumbling sounds
3. Verify: Fog 180 studs (dark), dual particles (ash + embers), audio playing
4. Verify: Embers float upward, have light emission
5. Wait for event
6. Expected: 2x particles, 1.5x sound

---

### 3. Theme Transition Testing

**Test automatic weather changes:**

1. Teleport to Section 15 (last Grasslands)
2. Verify: Clear weather
3. Teleport to Section 16 (first Desert)
4. Expected: Weather changes to Sandstorm (smooth transition)
5. Verify: Lighting tweens (3 seconds), particles swap, audio crossfade

Repeat for:
- Section 30 → 31 (Desert → Snow = Sandstorm → Blizzard)
- Section 40 → 41 (Snow → Volcano = Blizzard → Volcanic Ash)

---

## 📝 Testing Best Practices

### Automated Testing

**When to use:**
- Regression testing (ensure no breakage)
- Initial validation (new tower generation)
- Pre-commit checks (before pushing code)
- Performance profiling (generation time)

**How often:**
- After every major change
- Before every commit
- Daily during active development

---

### Manual Testing

**When to use:**
- Player experience validation (does it feel good?)
- Edge case discovery (unusual player behavior)
- Balance tuning (is it too hard/easy?)
- Visual/audio polish (does it look/sound good?)

**How often:**
- Weekly full tower playthrough
- After hazard/weather changes
- Before launch/major releases

---

### Performance Testing

**When to use:**
- After adding new systems (hazards, weather)
- When FPS drops are reported
- Before launch (stress test)
- After optimization changes

**How often:**
- Weekly profiling
- Before/after performance changes
- Pre-launch stress tests (100+ iterations)

---

## 🎓 Advanced Testing

### Custom Test Cases

**Add custom tests to DebugUtilities:**

```lua
function DebugUtilities.TestCustomFeature(): boolean
    print("\n[DebugUtilities] Testing custom feature...")
    resetTestResults()

    -- Your test logic here
    local success = true
    recordTest("Custom test 1", success)

    return printTestSummary()
end
```

---

### CI/CD Integration (Future)

**Automated testing on commit:**
1. Pre-commit hook runs `TestAllSections()`
2. If any fail, commit blocked
3. Developer fixes issues
4. Re-run tests, commit allowed

---

## ✅ Week 11 Testing Infrastructure Complete

**Delivered:**
- ✅ Extended DebugUtilities with hazard testing
- ✅ Extended DebugUtilities with weather testing
- ✅ Comprehensive test suite (RunComprehensiveTests)
- ✅ 180+ automated test cases
- ✅ Complete testing documentation

**Ready For:**
- Full system validation
- Bug identification
- Performance profiling
- Pre-launch testing

---

**Usage Command:**
```lua
-- Run all tests
_G.TowerAscent.DebugUtilities.RunComprehensiveTests(_G.TowerAscent.Tower)
```

**Expected Result:** ✅ ALL TESTS PASSED - PRODUCTION READY

---

**Week 11 Testing Infrastructure:** ✅ **COMPLETE**
**Next:** Run tests, identify bugs, tune balance, apply polish
