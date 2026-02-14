# Roblox Games Deep Code Review

**Reviewer:** Senior Roblox Code Reviewer (Claude Agent)
**Date:** 2026-02-11
**Projects Reviewed:**
1. Tower Ascent (`/mnt/e/projects/roblox/tower-ascent-game/`) -- ~85 Lua files
2. Pet Quest Legends (`/mnt/e/projects/pet-quest-legends/`) -- ~34 Lua files

---

## Executive Summary

| Project | Grade | Summary |
|---------|-------|---------|
| **Tower Ascent** | **B-** | Solid architecture with SecureRemotes, anti-cheat, and ProfileService. However, **all 15+ monetization product IDs are placeholder 0**, `RemoteEventsInit.Initialize()` is never called, and monetization services bypass SecureRemotes. Production-ready for gameplay; **not production-ready for monetization**. |
| **Pet Quest Legends** | **C+** | Functional pet collector with gacha/fusion systems and 15 services. Major security holes: `_G.PQL` is exposed unconditionally (not debug-gated), `SpendGems` RemoteFunction allows client-triggered spending, `DataService.SetSetting` has no validation, and no pcall on profile loading. **Not safe for production without security fixes**. |

---

## CRITICAL ISSUES (Must Fix Before Launch)

### CRIT-01: [PQL] `_G.PQL` Exposes ALL Services Unconditionally
**File:** `pet-quest-legends/src/ServerScriptService/Main.server.lua:131-147`
**Severity:** CRITICAL -- Exploit
**Impact:** Any exploiter with script injection can call `_G.PQL.CoinService.AdminAddCoins(player, 999999999)`, `_G.PQL.GemService.AdminSetGems(player, 999999)`, `_G.PQL.PetService.AdminGrantPet(player, "Dragon")`, etc.

Unlike Tower Ascent which gates `_G.TowerAscent` behind `GameConfig.Debug.Enabled`, Pet Quest Legends **always** exposes the global:

```lua
-- Main.server.lua:131 (ALWAYS runs, no debug gate)
_G.PQL = {
    DataService = DataService,
    CoinService = CoinService,
    GemService = GemService,
    -- ... all 15 services with Admin methods
}
```

**Fix:** Wrap in `if GameConfig.Debug and GameConfig.Debug.Enabled then` or remove entirely.

---

### CRIT-02: [PQL] `SpendGems` RemoteFunction Exposed to Client
**File:** `pet-quest-legends/src/ServerScriptService/Services/GemService.lua:68-75`
**Severity:** CRITICAL -- Exploit
**Impact:** Client can directly invoke `SpendGems(player, amount, reason)` via the RemoteFunction. While spending gems (not adding) seems harmless, a malicious client could:
1. Pass negative amounts if validation is bypassed
2. Grief other players by spending their gems (if combined with _G.PQL exploit)
3. The `reason` parameter is unvalidated and stored in logs

```lua
-- GemService.lua:73
spend.OnServerInvoke = function(player, amount, reason)
    return GemService.SpendGems(player, amount, reason)
end
```

The `amount` parameter has basic validation (line 144: `amount <= 0`), but `reason` is an arbitrary string from the client passed directly to `print()` (line 172). More importantly, this remote should not exist -- gem spending should only be triggered by server-side service calls (egg hatching, fusion, etc.), never directly by the client.

**Fix:** Remove the `SpendGems` RemoteFunction. Gems should only be spent through server-side service calls.

---

### CRIT-03: [BOTH] All Monetization Product IDs Are Placeholder 0
**Files:**
- Tower Ascent `GamePassService.lua:30,40,50,60,70` -- 5 Game Passes, all Id = 0
- Tower Ascent `DevProductService.lua:29,38,47,56,66,76,87,97` -- 8 Dev Products, all Id = 0
- Tower Ascent `VIPService.lua:38` -- VIPGamePassId = 0
- Tower Ascent `BattlePassService.lua:34` -- PremiumPassId = 0
- Pet Quest Legends: Products defined in `GameConfig.lua` (separate config, not reviewed in full but referenced as having placeholder IDs based on CLAUDE.md)

**Severity:** CRITICAL -- Production Blocker
**Impact:** Zero revenue. All purchase prompts will either fail or prompt for wrong products. `MarketplaceService:PromptGamePassPurchase(player, 0)` will error.

Both projects guard against Id=0 in prompt functions (good), but this means **all monetization is completely non-functional**.

**Fix:** Create actual Game Passes and Developer Products on the Roblox Creator Dashboard, then update all IDs.

---

### CRIT-04: [PQL] No pcall Around ProfileService.LoadProfileAsync
**File:** `pet-quest-legends/src/ServerScriptService/Services/DataService.lua:146`
**Severity:** CRITICAL -- Data Loss / Crash
**Impact:** If ProfileService throws an error during `LoadProfileAsync` (network timeout, DataStore outage, rate limiting), the error propagates unhandled and crashes the player's connection handler. The player gets stuck in a broken state.

```lua
-- DataService.lua:146 (PQL) -- NO pcall!
local profile = ProfileStore:LoadProfileAsync(profileKey)
```

Compare with Tower Ascent's DataService which wraps this in pcall with a timeout mechanism.

**Fix:** Wrap in pcall:
```lua
local success, profile = pcall(function()
    return ProfileStore:LoadProfileAsync(profileKey)
end)
if not success then
    warn("[DataService] LoadProfileAsync error: " .. tostring(profile))
    player:Kick("Data loading error. Please rejoin.")
    return
end
```

---

### CRIT-05: [PQL] DataService.SetSetting Has Zero Validation
**File:** `pet-quest-legends/src/ServerScriptService/Services/DataService.lua:608-614`
**Severity:** CRITICAL -- Exploit / Data Corruption
**Impact:** Any client calling the `SetSetting` remote can write ANY key with ANY value type into the player's Settings table. This allows:
1. Overwriting existing settings with wrong types (e.g., `MusicVolume = "hacked"`)
2. Injecting arbitrary keys into saved data (data bloat, potential DataStore size limit issues)
3. Storing malicious strings in the profile

```lua
-- DataService.lua:608-612
function DataService.SetSetting(player: Player, settingName: string, value: any): boolean
    local profile = Profiles[player]
    if not profile then return false end
    profile.Data.Settings[settingName] = value  -- NO VALIDATION!
    return true
end
```

Tower Ascent's DataService has a `VALID_SETTINGS` whitelist. PQL has none.

**Fix:** Add a settings whitelist and type validation:
```lua
local VALID_SETTINGS = {
    MusicVolume = "number",
    SFXVolume = "number",
    ShowTutorial = "boolean",
    AutoEquipNewPets = "boolean",
    GraphicsQuality = "string",
    ParticleEffects = "boolean",
}
```

---

### CRIT-06: [TA] RemoteEventsInit.Initialize() Is Never Called
**File:** `tower-ascent-game/src/ServerScriptService/Utilities/RemoteEventsInit.lua:28`
**Severity:** CRITICAL -- Broken Feature
**Impact:** The `RemoteEventsInit` module defines an `Initialize()` function that creates all SecureRemotes-wrapped events, but **this function is never called** in `Main.server.lua`. The bootstrap script loads many services but never calls `RemoteEventsInit.Initialize()`.

Searching the bootstrap (`Main.server.lua`):
- `RemoteEventsInit` is not even `require`d in the bootstrap
- Services that depend on it (CoinService, UpgradeService) import it directly

This means the centralized secure remote creation defined in RemoteEventsInit may not actually run, and services may fall back to creating their own raw remotes.

**Fix:** Add `RemoteEventsInit.Initialize()` call early in the bootstrap (before Phase 2):
```lua
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
RemoteEventsInit.Initialize()
```

---

### CRIT-07: [BOTH] ProcessReceipt Can Only Be Set Once
**Files:**
- Tower Ascent `DevProductService.lua:117` -- Sets `MarketplaceService.ProcessReceipt`
- Pet Quest Legends `DevProductService.lua:423` -- Sets `MarketplaceService.ProcessReceipt`

**Severity:** CRITICAL -- Monetization Bug
**Impact:** `MarketplaceService.ProcessReceipt` is a **singular callback** -- only the last assignment wins. If any other script or service also sets this callback, it silently overwrites the previous one. In Tower Ascent, DevProductService sets it at line 117. If a future service also sets it, DevProduct purchases will silently break.

In Pet Quest Legends, the same pattern exists at line 423.

**Fix:** Use a single centralized ProcessReceipt handler that routes to the correct service based on product ID. Or ensure only one service ever sets this callback.

---

### CRIT-08: [PQL] PetService.EquipPet Receives nil Slot From Remote
**File:** `pet-quest-legends/src/ServerScriptService/Services/PetService.lua:54-56`
**Severity:** CRITICAL -- Broken Feature
**Impact:** The EquipPet RemoteFunction handler passes `nil` as the slot parameter:

```lua
-- PetService.lua:54-55
equip.OnServerInvoke = function(player, uuid)
    return PetService.EquipPet(player, uuid, nil)  -- slot is nil!
end
```

Then in `PetService.EquipPet` (line 167):
```lua
if slot < 1 or slot > maxSlots then  -- nil < 1 errors in Luau!
```

This will throw a runtime error: "attempt to compare nil < number". The equip pet feature is **completely broken** from the client.

**Fix:** Auto-assign to next available slot, or require client to send slot:
```lua
equip.OnServerInvoke = function(player, uuid, slot)
    if not slot or type(slot) ~= "number" then
        -- Auto-assign to next available slot
        local equipped = DataService.GetEquippedPets(player)
        slot = #equipped + 1
    end
    return PetService.EquipPet(player, uuid, slot)
end
```

---

## WARNINGS (Should Fix Before Launch)

### WARN-01: [PQL] No MaxCoins Cap in DataService.AddCoins
**File:** `pet-quest-legends/src/ServerScriptService/Services/DataService.lua:269`
**Severity:** HIGH
**Impact:** Coins can grow unbounded. Tower Ascent enforces `MaxCoins = 999999` (from GameConfig). PQL has no such cap. Combined with the `_G.PQL` exploit (CRIT-01), an exploiter could set coins to absurd values that may exceed DataStore storage limits or cause integer overflow display issues.

```lua
-- DataService.lua:269 (PQL)
profile.Data.Coins = profile.Data.Coins + amount  -- No cap!
```

**Fix:** Add `math.min(profile.Data.Coins + amount, MAX_COINS)` like Tower Ascent does.

---

### WARN-02: [TA] Multiple Services Connect to PromptGamePassPurchaseFinished
**Files:**
- `GamePassService.lua:105` -- Connects to `PromptGamePassPurchaseFinished`
- `VIPService.lua:368` -- Connects to `PromptGamePassPurchaseFinished`
- `BattlePassService.lua:753` -- Connects to `PromptGamePassPurchaseFinished`

**Severity:** MEDIUM
**Impact:** All three connections fire for every game pass purchase. Each handler checks `gamePassId` to see if it matches their own pass, so there's no functional bug currently. However, if two passes share the same ID (misconfiguration), both handlers would fire. Also, having three separate listeners is a maintenance risk.

**Fix:** Consider a centralized purchase handler that routes to the correct service.

---

### WARN-03: [TA] GamePassService.ApplyPassBenefits Creates Unbounded CharacterAdded Connections
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/GamePassService.lua:264`
**Severity:** MEDIUM -- Memory Leak
**Impact:** Every time `ApplyPassBenefits` is called for `SpeedDemon`, a new `CharacterAdded` connection is created (line 264). If a player's benefits are re-applied (e.g., after a purchase or rejoin), connections accumulate without cleanup.

```lua
-- GamePassService.lua:264
player.CharacterAdded:Connect(function(character)
    GamePassService.ApplySpeedBoost(character, benefits.SpeedBoost)
end)
```

Compare with VIPService which properly tracks and disconnects `CharacterConnections` (VIPService.lua:218-221).

**Fix:** Track the connection per player and disconnect before creating a new one, like VIPService does.

---

### WARN-04: [PQL] PurchaseHistory Is In-Memory Only
**File:** `pet-quest-legends/src/ServerScriptService/Services/DevProductService.lua:62`
**Severity:** HIGH -- Potential Double-Grant
**Impact:** `PurchaseHistory` is a local table (`local PurchaseHistory = {}`). If the server restarts (which happens regularly on Roblox -- every ~24 hours, or on updates), the history is lost. Roblox will re-deliver unacknowledged receipts, potentially granting products twice.

```lua
-- DevProductService.lua:62
local PurchaseHistory = {} -- [PurchaseId] = true (IN-MEMORY ONLY!)
```

Tower Ascent has the same pattern (DevProductService.lua:20, `PendingPurchases`), but it uses a different approach -- tracking pending purchases with timestamps and cleanup, which is slightly better but still in-memory.

**Fix:** Persist `PurchaseId` to the player's ProfileService data to survive server restarts. Check the profile before granting.

---

### WARN-05: [TA] BattlePassService.PurchaseRateLimits Declared Twice
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/BattlePassService.lua:25,717`
**Severity:** LOW -- Code Smell / Bug Risk
**Impact:** `PurchaseRateLimits` is first created as part of `BattlePassService.PlayerProgress` (line 25), then re-declared as `BattlePassService.PurchaseRateLimits = {}` at line 717. The second declaration overwrites the first, meaning any rate limit data stored before line 717 executes is lost.

```lua
-- Line 25:
BattlePassService.PlayerProgress = {}
-- Line 717:
BattlePassService.PurchaseRateLimits = {}
```

**Fix:** Remove the duplicate declaration at line 717.

---

### WARN-06: [TA] VIPService and BattlePassService Connect to PromptGamePassPurchaseFinished at Module Level
**Files:**
- `VIPService.lua:368` -- Connection at module scope (outside Init)
- `BattlePassService.lua:753` -- Connection at module scope (outside Init)

**Severity:** MEDIUM
**Impact:** These connections are established when the module is `require()`d, regardless of whether `Init()` is called. This means they fire even if the service isn't fully initialized. For example, if BattlePassService's Init hasn't run yet but a purchase event fires, `BattlePassService.PlayerProgress[player.UserId]` would be nil (line 755), causing a silent failure.

**Fix:** Move the `PromptGamePassPurchaseFinished` connections inside the `Init()` function.

---

### WARN-07: [PQL] CoinService Checks 10 Achievements on Every Click
**File:** `pet-quest-legends/src/ServerScriptService/Services/CoinService.lua:148-159`
**Severity:** MEDIUM -- Performance
**Impact:** Every single click triggers 10 `AchievementService.CheckAchievement()` calls via `task.spawn`. Even though it's spawned, this is 10 function calls per click, per player. At 20 clicks/second with 50 players, that's 10,000 achievement checks per second.

```lua
-- CoinService.lua:148-159
task.spawn(function()
    AchievementService.CheckAchievement(player, "clicks_1000")
    AchievementService.CheckAchievement(player, "clicks_10000")
    -- ... 8 more calls
end)
```

**Fix:** Only check relevant achievements (e.g., check "clicks_1000" when clicks reach a multiple of 100, not on every click). Or use a threshold-based system.

---

### WARN-08: [PQL] Autosave Loop Has No Wait Between Cycles When Players Exist
**File:** `pet-quest-legends/src/ServerScriptService/Services/DataService.lua:553-594`
**Severity:** LOW
**Impact:** The autosave loop (line 558-594) staggers saves across the interval, but after the last player is saved, it immediately starts the next cycle without waiting. With 1 player, it saves every ~0 seconds (no stagger needed), meaning it just loops continuously. ProfileService handles actual persistence, so the main impact is unnecessary CPU cycles updating timestamps.

**Fix:** Add `task.wait(AUTOSAVE_INTERVAL)` at the end of the save cycle regardless of player count.

---

### WARN-09: [TA] Monetization Services Bypass SecureRemotes
**Files:**
- `GamePassService.lua:115-151` -- Creates raw RemoteEvents/Functions
- `VIPService.lua:84-127` -- Creates raw RemoteEvents
- `BattlePassService.lua:170-217` -- Creates raw RemoteEvents/Functions
- `DevProductService.lua:150-178` -- Creates raw RemoteEvents/Functions

**Severity:** MEDIUM -- Inconsistency
**Impact:** Tower Ascent has a sophisticated `SecureRemotes` wrapper (with rate limiting, type checking, data size validation, and suspicious activity scoring) used by core services via `RemoteEventsInit`. However, ALL four monetization services create their own raw `Instance.new("RemoteEvent")` / `Instance.new("RemoteFunction")` without going through SecureRemotes. This means:
1. No automated rate limiting on monetization remotes
2. No type validation on client inputs
3. No suspicious activity tracking
4. Inconsistent security posture

Each service does implement its own manual rate limiting (good), but it lacks the depth of SecureRemotes.

**Fix:** Either use `SecureRemotes.CreateRemoteEvent/CreateRemoteFunction` for monetization remotes, or add the monetization remotes to `RemoteEventsInit`.

---

### WARN-10: [TA] Production Safety Check References _G.TowerAscent in Non-Debug Mode
**File:** `tower-ascent-game/src/ServerScriptService/Main.server.lua:351`
**Severity:** LOW -- Misleading
**Impact:** In production mode (Debug.Enabled = false), the safety check failure message says:
```
"Run _G.TowerAscent.PreDeploymentChecklist.Validate() for details"
```
But `_G.TowerAscent` doesn't exist in production mode (it's only set in the `if GameConfig.Debug.Enabled then` block). This message is misleading for production deployments.

**Fix:** Change the message to something actionable in production context.

---

## MINOR ISSUES (Nice to Fix)

### MINOR-01: [PQL] GemService.OnPlayerAdded Has Fixed 1-Second Wait
**File:** `pet-quest-legends/src/ServerScriptService/Services/GemService.lua:298`
**Impact:** `task.wait(1)` is a fixed delay hoping DataService has loaded the profile. If DataService is slow (DataStore throttling), 1 second may not be enough. If it's fast, it's a wasted second.
**Fix:** Use a profile-ready event/signal instead of a fixed delay.

---

### MINOR-02: [PQL] PetService.OnPlayerAdded Has Fixed 1-Second Wait
**File:** `pet-quest-legends/src/ServerScriptService/Services/PetService.lua:333`
**Impact:** Same as MINOR-01. Multiple services use `task.wait(1)` hoping DataService is ready.
**Fix:** Centralized "player ready" event after DataService loads the profile.

---

### MINOR-03: [PQL] CoinService.OnPlayerAdded Has Fixed 1-Second Wait
**File:** `pet-quest-legends/src/ServerScriptService/Services/CoinService.lua:314`
**Impact:** Same pattern as MINOR-01 and MINOR-02.

---

### MINOR-04: [TA] BattlePassService.SeasonEndDate Resets on Every Server Start
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/BattlePassService.lua:39`
**Impact:** `SeasonEndDate = os.time() + (30 * 24 * 60 * 60)` calculates a new end date every time the server starts. This means the season never actually ends -- it always has 30 days remaining. Different servers will have different end dates.
**Fix:** Use a fixed calendar date (e.g., `os.time({year=2026, month=3, day=15})`).

---

### MINOR-05: [PQL] pcall on require() for Lazy Loading is Called Every Click
**File:** `pet-quest-legends/src/ServerScriptService/Services/CoinService.lua:132-134, 142-144, 179-181, 189-191`
**Impact:** `pcall(function() return require(...) end)` is called on every click for PetService, AchievementService, GamePassService, and DevProductService. While Luau caches `require()` results, the pcall + closure overhead is unnecessary after the first successful call.
**Fix:** Cache the result: `local PetService = PetService or pcall(...)`.

---

### MINOR-06: [TA] GamePassService.GrantCosmetics Uses Fragile Path
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/GamePassService.lua:307`
**Impact:** `require(script.Parent.Parent.DataService)` is a relative path that breaks if the file is moved. Tower Ascent's other services use `ServerScriptService.Services.DataService` for more robust pathing.
**Fix:** Use `require(ServerScriptService.Services.DataService)`.

---

### MINOR-07: [TA] BattlePassService Uses Relative require() Paths
**Files:**
- `BattlePassService.lua:410` -- `require(script.Parent.Parent.CoinService)`
- `BattlePassService.lua:446,624,648` -- `require(script.Parent.Parent.DataService)`

**Impact:** Same as MINOR-06. Fragile relative paths.
**Fix:** Use absolute `ServerScriptService.Services.*` paths.

---

### MINOR-08: [PQL] FusionService Uses String Concatenation for Log Messages in Hot Path
**File:** `pet-quest-legends/src/ServerScriptService/Services/FusionService.lua` (multiple locations)
**Impact:** `string.format` calls in frequently-called validation paths add minor overhead.
**Fix:** Consider using conditional logging or reducing log verbosity for production.

---

## POSITIVE FINDINGS (Good Patterns)

### POS-01: [TA] Excellent SecureRemotes Architecture
**File:** `tower-ascent-game/src/ServerScriptService/Security/SecureRemotes.lua`
The SecureRemotes wrapper is well-designed with:
- Per-remote rate limiting
- Type schema validation
- Data size limits
- Suspicious activity scoring with auto-ban
- Centralized configuration via RemoteEventsInit

This is a professional-grade pattern for Roblox security.

---

### POS-02: [TA] Comprehensive Anti-Cheat System
**Files:**
- `SecurityManager.lua` -- Rate limiting, ban escalation, character monitoring
- `AntiCheat.lua` -- Speed, flying, teleport, stage skip detection

Well-implemented with:
- Staggered player checks to avoid performance spikes
- DataStore-persisted bans
- Violation logging with size limits
- Admin commands for debugging

---

### POS-03: [BOTH] ProfileService with Session Locking
Both projects use ProfileService correctly with:
- Session locking (prevents data duplication across servers)
- `Reconcile()` for schema migration
- `AddUserId()` for GDPR compliance
- Proper `BindToClose` for clean shutdown
- Staggered autosave to prevent lag spikes

---

### POS-04: [TA] Debug Mode Properly Gated
**File:** `tower-ascent-game/src/ServerScriptService/Main.server.lua:232-337`
Tower Ascent only loads debug utilities and exposes `_G.TowerAscent` when `GameConfig.Debug.Enabled` is true. The config has `Debug.Enabled = false` by default. This is the correct pattern (contrast with PQL's CRIT-01).

---

### POS-05: [BOTH] Server-Authoritative Currency
Both projects validate all currency operations on the server:
- Coins: Server calculates amounts, client only sends click events
- Gems: Server validates spending and adding
- Purchases: Validated through MarketplaceService callbacks
- NaN/Infinity checks in AddCoins (both projects)

---

### POS-06: [TA] VIPService Non-Blocking Marketplace Check
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/VIPService.lua:134-182`
VIPService defaults to non-VIP immediately, then upgrades asynchronously after the marketplace responds. This prevents server hangs from MarketplaceService timeouts. Good defensive pattern.

---

### POS-07: [TA] VIPService Properly Cleans Up CharacterAdded Connections
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/VIPService.lua:218-221`
VIPService tracks `CharacterConnections[UserId]` and disconnects old connections before creating new ones. This prevents memory leaks from accumulated event connections. Good pattern that GamePassService (WARN-03) should adopt.

---

### POS-08: [PQL] Ethical Gacha with Pity System
**File:** `pet-quest-legends/src/ServerScriptService/Services/EggService.lua`
The gacha system implements pity counters:
- Rare guaranteed after 10 hatches
- Epic guaranteed after 25 hatches
- Legendary guaranteed after 50 hatches
- Mythical guaranteed after 100 hatches

This is ethical game design that prevents infinite bad luck streaks.

---

### POS-09: [PQL] Gem Economy Has Max Cap
**File:** `pet-quest-legends/src/ServerScriptService/Services/GemService.lua:123`
GemService enforces `GameConfig.Currency.MaxGems` cap, preventing unlimited gem accumulation. Good economic design.

---

### POS-10: [TA] BattlePassService Challenge Index Optimization
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/BattlePassService.lua:521-563`
The `RebuildChallengeIndex` pattern maps event types to challenges for O(1) lookup instead of iterating all challenges on every game event. Well-optimized for performance.

---

### POS-11: [BOTH] Proper Player Cleanup on Leave
Both projects clean up player-specific state (`Profiles`, `ActiveBoosts`, `VIPPlayers`, `PlayerProgress`, rate limit tables, etc.) in `PlayerRemoving` handlers. No major memory leaks from player data accumulation.

---

### POS-12: [TA] Stale Purchase Cleanup
**File:** `tower-ascent-game/src/ServerScriptService/Services/Monetization/DevProductService.lua:127-144`
Tower Ascent's DevProductService has a periodic cleanup loop for stale pending purchases (every 5 minutes, cleans entries older than 5 minutes). This prevents the `PendingPurchases` table from growing unbounded.

---

## Summary of Issues by Severity

| Severity | Count | Key Issues |
|----------|-------|------------|
| **CRITICAL** | 8 | _G.PQL exposed, SpendGems remote, placeholder IDs, no pcall on profile load, no setting validation, RemoteEventsInit never called, ProcessReceipt conflict, EquipPet nil slot |
| **WARNING** | 10 | No MaxCoins cap, multiple GamePass listeners, CharacterAdded leak, in-memory PurchaseHistory, duplicate declaration, module-level connections, achievement spam, autosave loop, bypassed SecureRemotes, misleading error msg |
| **MINOR** | 8 | Fixed task.wait delays, season date resets, pcall overhead, fragile require paths, hot-path logging |

---

## Recommended Fix Priority

### Phase 1: Security (Before ANY Public Testing)
1. CRIT-01: Gate `_G.PQL` behind debug flag
2. CRIT-02: Remove `SpendGems` RemoteFunction
3. CRIT-05: Add settings validation whitelist
4. CRIT-08: Fix EquipPet nil slot parameter

### Phase 2: Stability (Before Beta)
5. CRIT-04: Add pcall to ProfileService LoadProfileAsync
6. CRIT-06: Call RemoteEventsInit.Initialize() in bootstrap
7. CRIT-07: Centralize ProcessReceipt handler
8. WARN-01: Add MaxCoins cap
9. WARN-04: Persist PurchaseHistory to ProfileService data

### Phase 3: Monetization (Before Launch)
10. CRIT-03: Configure all product IDs on Roblox Creator Dashboard
11. WARN-09: Route monetization remotes through SecureRemotes
12. WARN-02: Centralize GamePass purchase handler
13. WARN-06: Move module-level connections into Init()

### Phase 4: Polish
14. WARN-03: Fix CharacterAdded connection leak in GamePassService
15. WARN-07: Optimize achievement checking frequency
16. All MINOR issues

---

*Review completed 2026-02-11. All file references are relative to the project root directories.*
