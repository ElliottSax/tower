# Test Accounts Setup Guide

**Purpose:** Create and configure test accounts for comprehensive testing
**Required Accounts:** 5 (TestUser1 through TestUser5)
**Time to Setup:** 30-45 minutes

---

## Overview

Week 1 testing requires 5 test accounts with different data states to validate all scenarios:
- New players
- Mid-game progression
- Edge cases (max coins, VIP status)
- Various permission levels

---

## Step 1: Create Roblox Accounts

### Account Creation

**Important:** Use a unique email for each account or use email aliases (e.g., yourname+test1@gmail.com)

Create these accounts on Roblox.com:

1. **TestUser1**
   - Email: your-email+test1@domain.com
   - Password: [Use a test password manager]
   - Purpose: New player testing

2. **TestUser2**
   - Email: your-email+test2@domain.com
   - Password: [Same or use password manager]
   - Purpose: Mid-game progression testing

3. **TestUser3**
   - Email: your-email+test3@domain.com
   - Password: [Same or use password manager]
   - Purpose: Coin cap testing (near 1 billion)

4. **TestUser4**
   - Email: your-email+test4@domain.com
   - Password: [Same or use password manager]
   - Purpose: VIP player testing

5. **TestUser5**
   - Email: your-email+test5@domain.com
   - Password: [Same or use password manager]
   - Purpose: VIP late-game testing

### Account Setup Checklist

For each account:
- [ ] Email verified
- [ ] Account restrictions disabled (13+ age)
- [ ] Privacy settings allow game joining
- [ ] Friend list accessible (for multiplayer tests)

---

## Step 2: Configure Test Data

### Option A: Automatic Initialization (Recommended)

Use the TestDataInitializer tool to automatically set up test data when accounts join:

```lua
-- In ServerScriptService, run:
local TestDataInit = require(game.ServerScriptService.test_scripts.tools.TestDataInitializer)

-- Enable auto-initialization
TestDataInit.SetupAutoInitialization()

-- Players will be automatically initialized when they join
```

### Option B: Manual Initialization

If you prefer manual setup:

```lua
-- After test accounts join server:
local TestDataInit = require(game.ServerScriptService.test_scripts.tools.TestDataInitializer)
TestDataInit.InitializeAllTestPlayers()
```

---

## Step 3: Test Account Configurations

### TestUser1: New Player

**Purpose:** Fresh start testing, onboarding, tutorial

**Configuration:**
```lua
{
    Coins = 0,
    Level = 1,
    Experience = 0,
    Checkpoints = {},
    Pets = {},
    UnlockedWorlds = {"World1"},
    VIP = false
}
```

**Test Scenarios:**
- First-time player experience
- Tutorial completion
- Initial coin collection
- First pet hatch
- Level 1-10 progression

---

### TestUser2: Mid-Game Player

**Purpose:** Normal progression testing

**Configuration:**
```lua
{
    Coins = 1000,
    Level = 10,
    Experience = 5000,
    Checkpoints = {["World1"] = 5, ["World2"] = 2},
    Pets = {"BasicPet1", "BasicPet2", "ForestPet1"},
    UnlockedWorlds = {"World1", "World2"},
    VIP = false
}
```

**Test Scenarios:**
- Standard gameplay loops
- World unlocking
- Pet management
- Checkpoint saving
- Level 10-30 progression

---

### TestUser3: Near Max Coins

**Purpose:** Coin cap testing, overflow prevention

**Configuration:**
```lua
{
    Coins = 999999900,  -- 100 below 1 billion cap
    Level = 50,
    Experience = 100000,
    Checkpoints = {["World1"] = 10, ["World2"] = 10, ["World3"] = 10},
    Pets = {"LegendaryPet1", "LegendaryPet2"},
    UnlockedWorlds = {"World1", "World2", "World3", "World4"},
    VIP = false
}
```

**Test Scenarios:**
- Coin cap enforcement (1 billion max)
- Overflow prevention
- UI display of large numbers
- Purchase with max coins
- Coin removal edge cases

**Critical Tests:**
- Collect 200 coins → Should cap at 1,000,000,000
- Purchase item → Should not cause underflow
- Display in leaderboards → Should show correctly

---

### TestUser4: VIP Player (Mid-Game)

**Purpose:** VIP benefits testing, 2x multiplier

**Configuration:**
```lua
{
    Coins = 500,
    Level = 15,
    Experience = 7500,
    Checkpoints = {["World1"] = 10, ["World2"] = 5},
    Pets = {"VIPPet1", "BasicPet1", "BasicPet2"},
    UnlockedWorlds = {"World1", "World2", "VIPWorld"},
    VIP = true
}
```

**Test Scenarios:**
- VIP Game Pass purchase validation
- 2x coin multiplier
- VIP-exclusive content access
- VIP status caching
- VIP race condition (pending state)

**Required Setup:**
- Purchase VIP Game Pass (or mock in test environment)
- Verify IsVIP attribute set to true

---

### TestUser5: VIP Player (Late-Game)

**Purpose:** VIP + high-level testing

**Configuration:**
```lua
{
    Coins = 10000,
    Level = 99,
    Experience = 500000,
    Checkpoints = {["World1"] = 10, ["World2"] = 10, ["World3"] = 10, ["World4"] = 10},
    Pets = {"LegendaryPet1", "LegendaryPet2", "VIPPet1", "FirePet1", "CrystalPet1"},
    UnlockedWorlds = {"World1", "World2", "World3", "World4", "VIPWorld"},
    VIP = true
}
```

**Test Scenarios:**
- End-game content
- VIP with maxed progression
- Pet inventory management (5+ pets)
- All worlds unlocked
- High-level balance testing

---

## Step 4: VIP Game Pass Setup

### For Monetization Testing

**Option A: Test Environment (Recommended)**
1. Create test Game Pass in Roblox Creator Hub
2. Set price to 0 Robux for testing
3. Grant to TestUser4 and TestUser5
4. Update product IDs in GameConfig

**Option B: Real Purchases (Expensive)**
1. Purchase VIP Game Pass with TestUser4
2. Purchase VIP Game Pass with TestUser5
3. Costs real Robux - not recommended for testing

**Option C: Mock VIP Status (Quickest)**
```lua
-- Manually set VIP status for testing
local player = game.Players:FindFirstChild("TestUser4")
if player then
    player:SetAttribute("IsVIP", true)
end
```

---

## Step 5: Verification

### Verify Account Setup

Run this verification script for each test account:

```lua
-- Verification Script
local function verifyTestAccount(player, expectedConfig)
    local DataService = require(game.ServerScriptService.Services.DataService)

    print(string.format("Verifying %s:", player.Name))

    local coins = DataService.GetPlayerData(player, "Coins")
    local level = DataService.GetPlayerData(player, "Level")
    local vip = player:GetAttribute("IsVIP")

    local checks = {
        {Name = "Coins", Expected = expectedConfig.Coins, Actual = coins},
        {Name = "Level", Expected = expectedConfig.Level, Actual = level},
        {Name = "VIP", Expected = expectedConfig.VIP, Actual = vip}
    }

    for _, check in ipairs(checks) do
        local passed = check.Expected == check.Actual
        print(string.format("  %s %s: Expected %s, Got %s",
            passed and "✅" or "❌",
            check.Name,
            tostring(check.Expected),
            tostring(check.Actual)))
    end
end

-- Run for all test users
for _, player in ipairs(game.Players:GetPlayers()) do
    if string.match(player.Name, "^TestUser%d$") then
        verifyTestAccount(player, expectedConfigs[player.Name])
    end
end
```

---

## Step 6: Password Management

### Secure Password Storage

**Recommended:** Use a password manager (1Password, LastPass, Bitwarden)

**Store:**
- Account name
- Email address
- Password
- Purpose/Notes

**Example Entry:**
```
Name: TestUser1 (Roblox Test)
Username: TestUser1
Email: yourname+test1@gmail.com
Password: [Generated Password]
URL: https://www.roblox.com
Notes: New player testing account for Week 1 QA
```

---

## Step 7: Multi-Account Login

### Browser Profiles (Recommended)

Create separate browser profiles for each test account:

**Chrome:**
1. Settings → Profiles → Add Profile
2. Name: "Roblox - TestUser1"
3. Sign in to Roblox with that account
4. Repeat for each test account

**Benefits:**
- Stay logged in to all accounts
- Quick switching between accounts
- No need to log in/out repeatedly

### Incognito Mode (Alternative)

Use incognito/private browsing for quick one-off tests

---

## Step 8: Quick Reference

### Test Account Quick Reference Card

```
┌────────────────────────────────────────────────────────────┐
│ Test Accounts Quick Reference                              │
├────────────────────────────────────────────────────────────┤
│ TestUser1: New Player (0 coins, Level 1, No VIP)          │
│ TestUser2: Mid-Game (1K coins, Level 10, No VIP)          │
│ TestUser3: Near Max (999.9M coins, Level 50, No VIP)      │
│ TestUser4: VIP Mid (500 coins, Level 15, VIP)             │
│ TestUser5: VIP Late (10K coins, Level 99, VIP)            │
└────────────────────────────────────────────────────────────┘
```

### Common Commands

```lua
-- Initialize all test accounts
TestDataInitializer.InitializeAllTestPlayers()

-- Reset specific account
TestDataInitializer.ResetPlayer(player)

-- Create stress test data
TestDataInitializer.CreateStressTestData(player)

-- Verify account setup
TestDataInitializer.PrintGuide()
```

---

## Troubleshooting

### Account Creation Issues

**Problem:** Email already in use
- **Solution:** Use email aliases (+test1, +test2, etc.)

**Problem:** Age restriction
- **Solution:** Set birthdate to 13+ years ago

**Problem:** Can't join games
- **Solution:** Check privacy settings, enable friend requests

### Data Initialization Issues

**Problem:** Data not saving
- **Solution:** Check DataStore configuration, ensure ProfileService loaded

**Problem:** VIP status not applying
- **Solution:** Manually set IsVIP attribute via script

**Problem:** Wrong data loaded
- **Solution:** Reset account with TestDataInitializer.ResetPlayer()

---

## Security & Privacy

### Important Notes

**DO NOT:**
- ❌ Share test account passwords publicly
- ❌ Use personal passwords for test accounts
- ❌ Link test accounts to personal payment methods
- ❌ Store sensitive data in test accounts

**DO:**
- ✅ Use unique passwords for test accounts
- ✅ Use password manager
- ✅ Use test/disposable email addresses
- ✅ Delete test accounts after testing complete (optional)

---

## Maintenance

### Periodic Reset

Reset test accounts weekly to maintain clean state:

```lua
-- Reset all test accounts to baseline
for _, player in ipairs(game.Players:GetPlayers()) do
    if string.match(player.Name, "^TestUser%d$") then
        TestDataInitializer.ResetPlayer(player)
    end
end
```

### Data Cleanup

After testing sessions, clean up test data:
- Clear temporary DataStore entries
- Remove test pets/items
- Reset coin balances
- Clear checkpoints

---

## Testing Checklist

### Setup Verification

Before beginning Week 1 testing:

- [ ] All 5 test accounts created
- [ ] Email addresses verified
- [ ] Browser profiles set up
- [ ] TestDataInitializer run successfully
- [ ] All accounts verified with correct data
- [ ] VIP status set for TestUser4 and TestUser5
- [ ] Password manager configured
- [ ] Quick reference card printed/saved

---

## Support

**Issues with setup?**
- Check TESTING_GUIDE.md for troubleshooting
- Review TestDataInitializer.lua source code
- Run TestDataInitializer.PrintGuide() for configuration details

**Need to modify configurations?**
- Edit TEST_ACCOUNTS array in TestDataInitializer.lua
- Re-run initialization after changes

---

**Last Updated:** 2026-02-22
**Version:** 1.0
**Status:** Ready for Week 1 Testing
