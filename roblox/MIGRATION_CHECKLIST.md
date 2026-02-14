# Migration Checklist - Code Review Fixes

This checklist helps you migrate existing code or create new services using the improved patterns.

---

## 📋 For Existing Services (Migration)

### Step 1: Update Service Initialization

**Before:**
```lua
-- Old pattern
_G.TowerAscent = _G.TowerAscent or {}
_G.TowerAscent.MyService = MyService
```

**After:**
```lua
-- New pattern
local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)

function MyService.Initialize()
    -- Do initialization work...

    -- Register with ServiceLocator (last step)
    if ServiceLocator then
        ServiceLocator.Register("MyService", MyService)
    end
end
```

**Action Items:**
- [ ] Remove `_G.TowerAscent.MyService = MyService` lines
- [ ] Add ServiceLocator require at top of file
- [ ] Register service in Initialize() function
- [ ] Call Initialize() from init.server.lua

---

### Step 2: Update Service Dependencies

**Before:**
```lua
-- Old pattern
local DataService = _G.TowerAscent and _G.TowerAscent.DataService
if DataService then
    DataService.GetCoins(player)
end
```

**After:**
```lua
-- New pattern
local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)

local DataService = ServiceLocator and ServiceLocator.Get("DataService")
if DataService and DataService.GetCoins then
    DataService.GetCoins(player)
end
```

**Action Items:**
- [ ] Find all `_G.TowerAscent` references
- [ ] Replace with `ServiceLocator.Get("ServiceName")`
- [ ] Add nil check AND function existence check
- [ ] Update requires at top of file

---

### Step 3: Migrate RemoteEvents

**Before:**
```lua
-- Old pattern
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "MyRemote"
remoteEvent.Parent = ReplicatedStorage

remoteEvent.OnServerEvent:Connect(function(player, ...)
    -- Handle event
end)
```

**After:**
```lua
-- Step 1: Add to RemoteEventsInit.lua
-- In RemoteEventsInit.Initialize():
local myRemote = SecureRemotes.CreateRemoteEvent("MyRemote", {
    MaxCallsPerSecond = 5,
    TypeSchema = {"string", "number"}
})
RemoteEventsInit.Remotes.MyRemote = myRemote

-- Step 2: Use in your service
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
local myRemote = RemoteEventsInit.GetRemote("MyRemote")

myRemote:OnServerEvent(function(player, stringArg, numberArg)
    -- Handle event (arguments already validated!)
end)
```

**Action Items:**
- [ ] List all RemoteEvents and RemoteFunctions
- [ ] Add each to RemoteEventsInit.lua with security config
- [ ] Update service to use RemoteEventsInit.GetRemote()
- [ ] Remove old Instance.new() code

---

### Step 4: Add Safe Requires for Optional Dependencies

**Before:**
```lua
local ParticleService = require(script.Parent.ParticleService)
ParticleService.SpawnParticle(...)
```

**After:**
```lua
local success, ParticleService = pcall(function()
    return require(script.Parent.ParticleService)
end)

if success and ParticleService and ParticleService.SpawnParticle then
    ParticleService.SpawnParticle(...)
end
```

**Action Items:**
- [ ] Identify optional dependencies (Particle, Sound, Theme, etc.)
- [ ] Wrap requires in pcall
- [ ] Add nil checks before using
- [ ] Keep required dependencies without pcall

---

### Step 5: Extract CONFIG Tables

**Before:**
```lua
task.delay(5, function()
    -- Magic number: what is 5?
end)

if coins > 1000 then
    -- Magic number: why 1000?
end
```

**After:**
```lua
local CONFIG = {
    RefreshDelay = 5, -- Seconds between refreshes
    MaxCoins = 1000, -- Maximum coins allowed
}

task.delay(CONFIG.RefreshDelay, function()
    -- Clear what this does
end)

if coins > CONFIG.MaxCoins then
    -- Self-documenting
end
```

**Action Items:**
- [ ] Create CONFIG table at top of file
- [ ] Find all magic numbers in code
- [ ] Move to CONFIG with descriptive names
- [ ] Add comments explaining each value

---

### Step 6: Add Input Validation

**Before:**
```lua
function MyService.ProcessData(player, amount, itemId)
    -- No validation!
    local data = DataService.GetData(player)
    data.Coins = data.Coins + amount
end
```

**After:**
```lua
function MyService.ProcessData(player: Player, amount: number, itemId: string): boolean
    -- 1. Validate player
    if not player or not player:IsA("Player") then
        warn("[MyService] Invalid player")
        return false
    end

    -- 2. Validate amount
    if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
        warn("[MyService] Invalid amount:", amount)
        return false
    end

    -- 3. Clamp to safe range
    amount = math.clamp(amount, 1, 999999)

    -- 4. Validate string
    if type(itemId) ~= "string" or #itemId > 64 then
        warn("[MyService] Invalid itemId")
        return false
    end

    -- Now safe to use
    local data = DataService.GetData(player)
    data.Coins = data.Coins + amount
    return true
end
```

**Action Items:**
- [ ] Add validation to all public functions
- [ ] Check player validity
- [ ] Validate number types (NaN, Infinity, range)
- [ ] Validate string types (length, content)
- [ ] Return success/failure instead of crashing

---

### Step 7: Add Webhook Logging

**Before:**
```lua
-- Only console logging
warn("[MyService] Security violation:", player.Name)
```

**After:**
```lua
local WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)

-- Console AND webhook
warn("[MyService] Security violation:", player.Name)

if WebhookLogger then
    WebhookLogger.LogSecurityEvent("MY_VIOLATION", {
        Player = player.Name,
        UserId = player.UserId,
        Details = "Additional context"
    })
end
```

**Action Items:**
- [ ] Add WebhookLogger require
- [ ] Log security violations
- [ ] Log critical errors
- [ ] Log significant events

---

## 📋 For New Services (Creation)

Use `ExampleService.lua` as a template:

### Checklist for New Service

- [ ] **1. File Structure**
  - [ ] Copy ExampleService.lua template
  - [ ] Rename service and update comments
  - [ ] Keep section structure (Requires → Config → State → Functions)

- [ ] **2. Dependencies**
  - [ ] Required deps: regular require()
  - [ ] Optional deps: pcall() wrapper
  - [ ] Import ServiceLocator, WebhookLogger, RemoteEventsInit

- [ ] **3. Configuration**
  - [ ] Create CONFIG table
  - [ ] Extract ALL magic numbers
  - [ ] Add descriptive comments

- [ ] **4. Remote Events**
  - [ ] Add remotes to RemoteEventsInit.lua FIRST
  - [ ] Get remotes via RemoteEventsInit.GetRemote()
  - [ ] Setup callbacks with validation

- [ ] **5. Functions**
  - [ ] Public functions: PascalCase
  - [ ] Private functions: camelCase
  - [ ] Add type annotations
  - [ ] Validate ALL inputs
  - [ ] Return success/error values

- [ ] **6. Integration**
  - [ ] Use ServiceLocator.Get() for dependencies
  - [ ] Check service AND function existence
  - [ ] Handle missing dependencies gracefully

- [ ] **7. Logging**
  - [ ] Print statements for debugging
  - [ ] Webhook logging for critical events
  - [ ] Consistent log format: "[ServiceName] Message"

- [ ] **8. Initialization**
  - [ ] Create Initialize() function
  - [ ] Setup connections
  - [ ] Register with ServiceLocator (LAST!)
  - [ ] Add to init.server.lua

---

## 🔍 Code Search Patterns

Use these patterns to find code that needs migration:

### Find _G Usage
```
_G.TowerAscent
```

### Find Unsafe Requires
```
local.*Service = require
```
(Check if wrapped in pcall)

### Find Magic Numbers
```
task.delay\(\d
task.wait\(\d
if.*> \d{2,}
if.*< \d{2,}
```

### Find Unvalidated Functions
```
function.*\(player,
```
(Check if validation exists)

### Find Manual Remote Creation
```
Instance.new\("Remote
```

---

## ✅ Validation

After migration, verify:

- [ ] Run SecurityValidation.RunAllTests()
- [ ] Check console for errors
- [ ] Test with missing optional services
- [ ] Verify ServiceLocator.GetServiceNames() shows your service
- [ ] Test RemoteEvents from client
- [ ] Verify webhook logging works

---

## 🚨 Common Mistakes

### ❌ Don't Do This

```lua
-- BAD: Assumes service exists
local DataService = ServiceLocator.Get("DataService")
DataService.GetCoins(player) -- CRASH if DataService is nil!
```

### ✅ Do This Instead

```lua
-- GOOD: Checks existence
local DataService = ServiceLocator.Get("DataService")
if DataService and DataService.GetCoins then
    DataService.GetCoins(player)
end
```

---

### ❌ Don't Do This

```lua
-- BAD: Magic numbers
if coins > 1000 then
    task.delay(5, function() ... end)
end
```

### ✅ Do This Instead

```lua
-- GOOD: CONFIG table
local CONFIG = {
    CoinThreshold = 1000,
    RewardDelay = 5,
}

if coins > CONFIG.CoinThreshold then
    task.delay(CONFIG.RewardDelay, function() ... end)
end
```

---

### ❌ Don't Do This

```lua
-- BAD: No validation
function ProcessPurchase(player, itemId, quantity)
    -- Use directly - DANGEROUS!
    grantItem(player, itemId, quantity)
end
```

### ✅ Do This Instead

```lua
-- GOOD: Full validation
function ProcessPurchase(player: Player, itemId: string, quantity: number): boolean
    if not player or not player:IsA("Player") then
        return false
    end

    if type(itemId) ~= "string" or #itemId > 64 then
        return false
    end

    if type(quantity) ~= "number" or quantity <= 0 or quantity ~= quantity then
        return false
    end

    quantity = math.clamp(quantity, 1, 100)

    grantItem(player, itemId, quantity)
    return true
end
```

---

## 📊 Migration Progress Tracker

Track your migration progress:

### Core Services
- [ ] DataService
- [ ] CoinService ✅ (Already migrated)
- [ ] CheckpointService ✅ (Already migrated)
- [ ] UpgradeService
- [ ] RoundService

### Security Services
- [ ] SecurityManager ✅ (Already migrated)
- [ ] AntiExploit ✅ (Already migrated)
- [ ] SecureRemotes ✅ (Already migrated)

### Optional Services
- [ ] ParticleService
- [ ] SoundService
- [ ] ThemeService
- [ ] WeatherService
- [ ] VIPService

### Client Scripts
- [ ] DoubleJump.lua ✅ (Already migrated)
- [ ] CoinDisplay.lua
- [ ] UpgradeUI.lua

---

## 🎯 Quick Win Migrations

Start with these for maximum impact:

1. **High Priority** (Do First)
   - [ ] Migrate RemoteEvents to RemoteEventsInit
   - [ ] Add input validation to all RemoteFunctions
   - [ ] Replace _G with ServiceLocator in security systems

2. **Medium Priority** (Do Next)
   - [ ] Add safe requires for optional dependencies
   - [ ] Extract CONFIG tables in core services
   - [ ] Add webhook logging for critical events

3. **Low Priority** (Polish)
   - [ ] Standardize naming conventions
   - [ ] Add type annotations
   - [ ] Update comments and documentation

---

## 📞 Need Help?

- Review `ExampleService.lua` for complete reference implementation
- Check `QUICK_START_GUIDE.md` for usage examples
- Read `CODE_REVIEW_FIXES_SUMMARY.md` for detailed explanations

**Last Updated:** 2025-12-17
