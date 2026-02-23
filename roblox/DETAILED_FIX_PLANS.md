# Detailed Fix Plans for Priority Games
*Step-by-step remediation guides*

## Table of Contents
1. [Tower Ascent Game (Wave 1)](#tower-ascent-game)
2. [Speed Run Universe (Wave 1)](#speed-run-universe)
3. [Adventure Story Obby (Wave 2)](#adventure-story-obby)
4. [Pet Collector Sim (Wave 3)](#pet-collector-sim)
5. [Dimension Hopper (Wave 3)](#dimension-hopper)

---

## Tower Ascent Game
**Priority:** P0 - FLAGSHIP LAUNCH
**Estimated Time:** 8-12 hours
**Target Launch:** Week 2

### Critical Fix #1: Debug Mode Protection (2 hours)

**File:** `/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Main.server.lua`

**Current Issue (Lines 274-333):**
```lua
if GameConfig.Debug.Enabled then
    _G.TowerAscent = {
        Generator = generator,
        DataService = DataService,
        AntiCheat = antiCheat,
        -- ... all services exposed
    }
end
```

**Fix Steps:**

1. **Add Runtime Validation**
```lua
-- Add after line 273
local function validateDebugMode()
    -- NEVER allow debug in published games
    if not game:GetService("RunService"):IsStudio() then
        if GameConfig.Debug.Enabled then
            warn("⚠️ DEBUG MODE ENABLED IN PRODUCTION - AUTO-DISABLING")
            GameConfig.Debug.Enabled = false

            -- Alert to webhook
            if WebhookLogger then
                WebhookLogger.LogEvent(
                    "🚨 CRITICAL SECURITY ALERT",
                    "Debug mode was enabled in production build - auto-disabled",
                    "CRITICAL",
                    {}
                )
            end
        end
    end
end

validateDebugMode()
```

2. **Add Whitelist for Debug Access (Optional)**
```lua
-- Replace lines 274-333 with:
if GameConfig.Debug.Enabled then
    local AUTHORIZED_DEBUG_USERS = {
        game.CreatorId,
        -- Add trusted developer UserIds
    }

    -- Only expose to authorized users
    game.Players.PlayerAdded:Connect(function(player)
        for _, userId in ipairs(AUTHORIZED_DEBUG_USERS) do
            if player.UserId == userId then
                -- Create player-specific debug table
                _G["Debug_" .. player.UserId] = {
                    GetService = function(name)
                        return ServiceLocator.Get(name)
                    end
                }

                print("🔧 Debug access granted to " .. player.Name)
            end
        end
    end)
end
```

**Testing:**
- [ ] Verify `_G.TowerAscent` is nil in Studio with debug disabled
- [ ] Verify services work without `_G` exposure
- [ ] Test in published game (test server)
- [ ] Confirm webhook alert fires if debug accidentally enabled

---

### Critical Fix #2: Add SecurityManager.IsAuthenticated() (1 hour)

**File:** `/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Security/SecurityManager.lua`

**Current Issue:** Method called on line 118 of SecureRemotes.lua but not defined

**Fix Steps:**

Add after line 107 (after `Initialize()` function):

```lua
--[[
    Checks if a player has been authenticated by the security system
    @param player Player - The player to check
    @return boolean - True if authenticated
]]
function SecurityManager.IsAuthenticated(player: Player): boolean
    if not player or not player:IsA("Player") then
        return false
    end

    -- Check if player has valid authorization record
    local auth = SecurityManager.Authorizations[player.UserId]
    if not auth then
        return false
    end

    -- Check if authorization is still valid (not expired)
    if auth.Validated ~= true then
        return false
    end

    -- Check if player is banned
    if SecurityManager.IsBanned(player.UserId) then
        return false
    end

    return true
end
```

**Testing:**
- [ ] Add print statement in SecureRemotes.lua to verify auth checks work
- [ ] Test with banned player (should return false)
- [ ] Test with new player (should return true after auth)
- [ ] Test with nil player (should return false)

---

### Critical Fix #3: VIP Race Condition (3 hours)

**File:** `/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Services/Monetization/VIPService.lua`

**Current Issue (Lines 154-182):**
```lua
-- Default to non-VIP immediately (prevents blocking)
VIPService.VIPPlayers[player.UserId] = false
player:SetAttribute("IsVIP", false)

-- Check VIP status asynchronously
task.spawn(function()
    -- ... async check ...
end)
```

**Fix Steps:**

1. **Replace lines 154-200 with:**
```lua
function VIPService.CheckVIPStatus(player: Player)
    if not player or not player:IsDescendantOf(game.Players) then
        return
    end

    local userId = player.UserId

    -- Set pending state
    VIPService.VIPPlayers[userId] = nil -- pending
    player:SetAttribute("IsVIP", nil) -- pending
    player:SetAttribute("VIPCheckPending", true)

    -- Try to load from cache first
    local cacheKey = "VIPCache_" .. userId
    local cachedStatus = nil
    local cacheAge = math.huge

    if VIPService.VIPCache[userId] then
        cachedStatus = VIPService.VIPCache[userId].IsVIP
        cacheAge = tick() - VIPService.VIPCache[userId].Timestamp
    end

    -- Use cache if fresh (< 5 minutes)
    if cachedStatus ~= nil and cacheAge < 300 then
        VIPService.VIPPlayers[userId] = cachedStatus
        player:SetAttribute("IsVIP", cachedStatus)
        player:SetAttribute("VIPCheckPending", false)

        print(string.format("[VIP] Loaded from cache for %s: %s",
            player.Name, tostring(cachedStatus)))
        return
    end

    -- Check asynchronously
    task.spawn(function()
        local success, isVIP = pcall(function()
            return game:GetService("MarketplaceService"):UserOwnsGamePassAsync(
                userId,
                CONFIG.VIPGamePassId
            )
        end)

        if not success then
            warn("[VIP] Failed to check VIP status for " .. player.Name .. ": " .. tostring(isVIP))
            -- Default to non-VIP on error
            isVIP = false
        end

        -- Verify player still in game
        if not player or not player:IsDescendantOf(game.Players) then
            return
        end

        -- Update status
        VIPService.VIPPlayers[userId] = isVIP
        player:SetAttribute("IsVIP", isVIP)
        player:SetAttribute("VIPCheckPending", false)

        -- Cache the result
        VIPService.VIPCache[userId] = {
            IsVIP = isVIP,
            Timestamp = tick()
        }

        -- Save to DataStore for next session
        if DataService then
            task.spawn(function()
                pcall(function()
                    DataService.SetPlayerData(player, "VIPStatus", {
                        IsVIP = isVIP,
                        LastCheck = os.time()
                    })
                end)
            end)
        end

        print(string.format("[VIP] Status verified for %s: %s",
            player.Name, tostring(isVIP)))
    end)
end
```

2. **Add cache table at top of file (after line 10):**
```lua
VIPService.VIPCache = {}
```

3. **Update CoinService to respect pending state:**

**File:** `/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Services/CoinService.lua`

Find where VIP multiplier is applied and add:

```lua
-- Before applying VIP multiplier
local vipPending = player:GetAttribute("VIPCheckPending")
if vipPending == true then
    -- Wait for VIP check to complete (max 3 seconds)
    for i = 1, 30 do
        if player:GetAttribute("VIPCheckPending") == false then
            break
        end
        task.wait(0.1)
    end
end

local isVIP = player:GetAttribute("IsVIP")
if isVIP == true then
    amount = amount * 2
end
```

**Testing:**
- [ ] Test VIP player joins - verify 2x multiplier active immediately
- [ ] Test non-VIP player - verify no multiplier
- [ ] Test with MarketplaceService down (mock failure)
- [ ] Test rapid join/leave cycles
- [ ] Verify cache persists across sessions

---

### Critical Fix #4: Coin Underflow Protection (1 hour)

**File:** `/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Services/DataService.lua`

**Current Issue (Lines 323-359):**
```lua
function DataService.RemoveCoins(player: Player, amount: number): boolean
    -- ... existing validation ...

    profile.Data.Coins = profile.Data.Coins - amount

    -- No check for negative overflow!
```

**Fix Steps:**

Replace lines 350-357 with:

```lua
-- Calculate new value
local newCoins = profile.Data.Coins - amount

-- SECURITY: Prevent negative underflow
if newCoins < 0 then
    warn(string.format("[DataService] Coin underflow prevented for %s: %d - %d",
        player.Name, profile.Data.Coins, amount))
    newCoins = 0
end

profile.Data.Coins = newCoins

-- Update leaderstats
local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
    local coinsValue = leaderstats:FindFirstChild("Coins")
    if coinsValue then
        coinsValue.Value = profile.Data.Coins
    end
end

return true
```

**Testing:**
- [ ] Test removing more coins than player has
- [ ] Test removing exactly the amount player has
- [ ] Test removing negative amount (should fail validation)
- [ ] Verify leaderstats updates correctly

---

### Critical Fix #5: Monetization Product IDs (2 hours)

**Files:**
- `GameConfig.lua`
- `MonetizationService.lua`

**Current Issue:** All product IDs are placeholder 0

**Fix Steps:**

1. **Upload Products to Roblox**
   - Go to Create > Game > Monetization
   - Create Game Passes:
     - VIP Pass
     - Speed Boost
     - Double Jump
     - Air Dash
   - Create Developer Products:
     - 1000 Coins Pack
     - 5000 Coins Pack
     - 10000 Coins Pack

2. **Update GameConfig.lua (Lines 90-120)**
```lua
-- Replace with actual IDs from Roblox
GamePasses = {
    VIP = 123456789, -- REPLACE WITH ACTUAL ID
    SpeedBoost = 123456790,
    DoubleJump = 123456791,
    AirDash = 123456792,
}

DeveloperProducts = {
    Coins1000 = 123456793, -- REPLACE WITH ACTUAL ID
    Coins5000 = 123456794,
    Coins10000 = 123456795,
}
```

3. **Add Validation Check**

Add to Main.server.lua after services load:

```lua
-- Verify monetization configured
local function validateMonetization()
    local placeholderFound = false

    for name, id in pairs(GameConfig.Monetization.GamePasses) do
        if id == 0 then
            warn("⚠️ Game Pass not configured: " .. name)
            placeholderFound = true
        end
    end

    for name, id in pairs(GameConfig.Monetization.DeveloperProducts) do
        if id == 0 then
            warn("⚠️ Developer Product not configured: " .. name)
            placeholderFound = true
        end
    end

    if placeholderFound then
        warn("⚠️ MONETIZATION NOT FULLY CONFIGURED")
        if not game:GetService("RunService"):IsStudio() then
            -- Alert via webhook
            if WebhookLogger then
                WebhookLogger.LogEvent(
                    "⚠️ Monetization Warning",
                    "Some monetization products not configured",
                    "WARNING",
                    {}
                )
            end
        end
    end
end

validateMonetization()
```

**Testing:**
- [ ] Test purchasing each Game Pass in test server
- [ ] Test purchasing each Developer Product
- [ ] Verify coins are granted correctly
- [ ] Test purchase failure handling
- [ ] Verify receipt processing

---

### Additional Recommended Fixes (Optional - 3 hours)

#### Fix #6: AirDash Anti-Cheat False Positive

**File:** `AntiCheat.lua` (Lines 306-327)

```lua
-- Add AirDash to speed calculation
local speedBoostLevel = getDataService().GetUpgradeLevel(player, "SpeedBoost")
local hasAirDash = getDataService().HasUpgrade(player, "AirDash")

local maxAllowedSpeed = MAX_SPEED * (1 + (speedBoostLevel * 0.1))

-- Account for AirDash burst (80 studs/s)
if hasAirDash then
    maxAllowedSpeed = maxAllowedSpeed + 30 -- Allow burst velocity
end
```

#### Fix #7: Optimize Debounce Cleanup

**File:** `CheckpointService.lua` (Line 589)

```lua
-- Reduce cleanup interval
task.wait(10) -- Changed from 30 to 10 seconds
```

---

### Launch Checklist for Tower Ascent

**Pre-Launch (Day Before):**
- [ ] All 5 critical fixes completed
- [ ] Code reviewed by second developer
- [ ] All product IDs configured
- [ ] Test server stress tested (50 players, 2 hours)
- [ ] Error logging verified working
- [ ] Discord webhook alerts tested
- [ ] Backup plan documented

**Launch Day:**
- [ ] Deploy to production
- [ ] Monitor error logs (every 30 min for first 4 hours)
- [ ] Watch player feedback in-game
- [ ] Monitor DataStore success rate
- [ ] Track CCU growth
- [ ] Be ready to rollback if critical issues found

**Post-Launch (Week 1):**
- [ ] Daily error log review
- [ ] Player feedback analysis
- [ ] Exploit monitoring
- [ ] Performance metrics tracking
- [ ] Plan first content update

---

## Speed Run Universe
**Priority:** P0 - WAVE 1 LAUNCH
**Estimated Time:** 12-16 hours
**Target Launch:** Week 3

### Critical Fix #1: Implement ValidateSpeedrunTime() (4 hours)

**File:** `SecurityManager.lua`

**Current Issue:** Function referenced but not implemented

**Fix Steps:**

Add to SecurityManager.lua:

```lua
--[[
    Validates a speedrun completion time against expected values
    @param player Player
    @param mapId string
    @param completionTime number
    @param checkpointTimes table
    @return boolean isValid
    @return string? reason
]]
function SecurityManager.ValidateSpeedrunTime(
    player: Player,
    mapId: string,
    completionTime: number,
    checkpointTimes: {number}
): (boolean, string?)

    -- Basic validation
    if type(completionTime) ~= "number" then
        return false, "Invalid time type"
    end

    if completionTime <= 0 or completionTime ~= completionTime then
        return false, "Invalid time value"
    end

    -- Get map data
    local mapConfig = MapConfigs[mapId]
    if not mapConfig then
        return false, "Unknown map"
    end

    -- Check if time is physically possible
    local worldRecord = mapConfig.WorldRecord or 30 -- seconds
    local minimumPossibleTime = worldRecord * 0.5 -- 50% of WR is threshold

    if completionTime < minimumPossibleTime then
        return false, string.format(
            "Time too fast (%.2fs < %.2fs minimum)",
            completionTime,
            minimumPossibleTime
        )
    end

    -- Validate checkpoint times are monotonically increasing
    if checkpointTimes and #checkpointTimes > 0 then
        local lastTime = 0
        for i, cpTime in ipairs(checkpointTimes) do
            if cpTime <= lastTime then
                return false, "Checkpoint times not increasing"
            end
            lastTime = cpTime
        end

        -- Final time must match or exceed last checkpoint
        if completionTime < lastTime then
            return false, "Completion time less than last checkpoint"
        end
    end

    -- Check for known cheater patterns
    local playerHistory = SecurityManager.PlayerHistory[player.UserId]
    if playerHistory then
        -- Sudden improvement (>50% faster) is suspicious
        if playerHistory.BestTime then
            local improvement = (playerHistory.BestTime - completionTime) / playerHistory.BestTime
            if improvement > 0.5 then
                warn(string.format(
                    "[Security] Suspicious improvement for %s: %.1f%%",
                    player.Name,
                    improvement * 100
                ))
                -- Flag but don't reject (could be legitimate)
            end
        end
    end

    return true
end
```

**Testing:**
- [ ] Test with valid speedrun
- [ ] Test with impossible time (0.1 seconds)
- [ ] Test with non-monotonic checkpoints
- [ ] Test with completion < last checkpoint
- [ ] Test with NaN/infinity values

---

### Critical Fix #2: PlayerRemoving Cleanup (2 hours)

**File:** `RaceService.lua` or main service file

**Fix Steps:**

Add cleanup handler:

```lua
-- Add after service initialization
game.Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId

    -- Clean up active runs
    if RaceService.ActiveRuns[userId] then
        print("[RaceService] Cleaning up active run for " .. player.Name)
        RaceService.ActiveRuns[userId] = nil
    end

    -- Clean up ghost recordings in progress
    if GhostService.RecordingGhosts[userId] then
        print("[GhostService] Saving ghost recording for " .. player.Name)

        -- Save partial ghost before cleanup
        local ghost = GhostService.RecordingGhosts[userId]
        if #ghost.Frames > 10 then -- Only save if meaningful progress
            task.spawn(function()
                pcall(function()
                    GhostService.SaveGhost(player, ghost)
                end)
            end)
        end

        GhostService.RecordingGhosts[userId] = nil
    end

    -- Clean up leaderboard subscriptions
    if LeaderboardService.Subscriptions[userId] then
        LeaderboardService.Subscriptions[userId] = nil
    end
end)
```

**Testing:**
- [ ] Start run, leave immediately - verify cleanup
- [ ] Start ghost recording, leave mid-run - verify save
- [ ] Monitor memory usage over 100 join/leave cycles

---

### Critical Fix #3: Ghost Data Compression (4 hours)

**File:** `GhostService.lua`

**Current Issue:** Ghost frames stored uncompressed

**Fix Steps:**

1. **Add compression utility:**

```lua
local GhostCompression = {}

function GhostCompression.CompressGhost(frames: {{}}): string
    -- Convert frames to delta encoding
    local compressed = {}
    local lastPos = Vector3.new(0, 0, 0)
    local lastRot = CFrame.new()

    for i, frame in ipairs(frames) do
        if i == 1 then
            -- First frame: store full data
            table.insert(compressed, {
                T = frame.Time,
                P = {frame.Position.X, frame.Position.Y, frame.Position.Z},
                R = {frame.Rotation:ToEulerAnglesYXZ()}
            })
        else
            -- Delta encoding: store difference from last frame
            local deltaPos = frame.Position - lastPos
            local deltaTime = frame.Time - frames[i-1].Time

            -- Only store if changed significantly (optimization)
            if deltaPos.Magnitude > 0.1 or deltaTime > 0.2 then
                table.insert(compressed, {
                    DT = deltaTime,
                    DP = {deltaPos.X, deltaPos.Y, deltaPos.Z}
                })
            end
        end

        lastPos = frame.Position
        lastRot = frame.Rotation
    end

    -- Convert to JSON
    return game:GetService("HttpService"):JSONEncode(compressed)
end

function GhostCompression.DecompressGhost(data: string): {{}}
    local compressed = game:GetService("HttpService"):JSONDecode(data)
    local frames = {}
    local currentPos = Vector3.new(0, 0, 0)
    local currentTime = 0

    for i, frame in ipairs(compressed) do
        if frame.P then
            -- Full frame
            currentPos = Vector3.new(unpack(frame.P))
            currentTime = frame.T
        else
            -- Delta frame
            currentPos = currentPos + Vector3.new(unpack(frame.DP))
            currentTime = currentTime + frame.DT
        end

        table.insert(frames, {
            Time = currentTime,
            Position = currentPos,
            Rotation = CFrame.new() -- Simplified
        })
    end

    return frames
end
```

2. **Update SaveGhost function:**

```lua
function GhostService.SaveGhost(player: Player, ghostData: {}): boolean
    -- Compress before saving
    local compressed = GhostCompression.CompressGhost(ghostData.Frames)

    -- Check size limit (DataStore max: 4MB, recommend < 100KB)
    if #compressed > 100000 then
        warn(string.format(
            "[Ghost] Ghost too large for %s: %d bytes",
            player.Name,
            #compressed
        ))
        return false
    end

    local saveData = {
        PlayerId = player.UserId,
        PlayerName = player.Name,
        MapId = ghostData.MapId,
        CompletionTime = ghostData.CompletionTime,
        FramesCompressed = compressed,
        RecordedAt = os.time()
    }

    -- Save to DataStore
    -- ... existing save logic ...
end
```

**Testing:**
- [ ] Compare compressed vs uncompressed size (expect 60-80% reduction)
- [ ] Test compression/decompression round-trip
- [ ] Verify ghost playback looks correct
- [ ] Test with very long ghosts (>5 minute runs)

---

### Additional Fixes (6 hours)

#### Fix #4: Add Ghost Size Limits
```lua
local MAX_GHOST_DURATION = 600 -- 10 minutes max
local MAX_GHOST_FRAMES = 6000 -- 10 min at 10 FPS

function GhostService.RecordFrame(player: Player, frame: {})
    local ghost = GhostService.RecordingGhosts[player.UserId]
    if not ghost then return end

    -- Check limits
    if #ghost.Frames >= MAX_GHOST_FRAMES then
        warn("[Ghost] Frame limit reached for " .. player.Name)
        GhostService.StopRecording(player)
        return
    end

    table.insert(ghost.Frames, frame)
end
```

#### Fix #5: Reduce Recording Frame Rate
```lua
-- Change from 10 FPS to 5 FPS
local RECORD_INTERVAL = 0.2 -- 5 FPS (was 0.1)
```

---

## Adventure Story Obby
**Priority:** P1 - WAVE 2 LAUNCH
**Estimated Time:** 16-20 hours
**Target Launch:** Week 5

### Critical Fix #1: Checkpoint CFrame Validation (3 hours)

**File:** `WorldService.lua` (Line 305)

**Current Issue:** Client-provided CFrame accepted without validation

**Fix Steps:**

Replace SetCheckpoint function (lines 280-310):

```lua
function WorldService.SetCheckpoint(player: Player, checkpointId: number, checkpointCFrame: CFrame)
    -- Validate player
    if not player or not player.Character then
        return
    end

    local checkpoint = PlayerCheckpoints[player]
    if not checkpoint then
        warn("[WorldService] No checkpoint data for " .. player.Name)
        return
    end

    -- SECURITY: Validate checkpoint exists in world
    local levelKey = string.format("World%d_Level%d", checkpoint.WorldId, checkpoint.LevelId)
    local levelFolder = Workspace.Levels:FindFirstChild(levelKey)

    if not levelFolder then
        warn("[WorldService] Invalid level: " .. levelKey)
        return
    end

    -- Find the actual checkpoint part
    local checkpointPart = levelFolder:FindFirstChild("Checkpoint" .. checkpointId)

    if not checkpointPart or not checkpointPart:IsA("BasePart") then
        warn(string.format("[WorldService] Invalid checkpoint %d in %s",
            checkpointId, levelKey))
        return
    end

    -- SECURITY: Use SERVER position, not client-provided position
    local serverCFrame = checkpointPart.CFrame + Vector3.new(0, 5, 0) -- Spawn above checkpoint

    -- Validate player is close to checkpoint (anti-cheat)
    local character = player.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if rootPart then
        local distance = (rootPart.Position - checkpointPart.Position).Magnitude

        -- Must be within 50 studs to set checkpoint
        if distance > 50 then
            warn(string.format(
                "[WorldService] Checkpoint too far for %s: %.1f studs",
                player.Name,
                distance
            ))
            return
        end
    end

    -- Update checkpoint (using SERVER position)
    checkpoint.CheckpointId = checkpointId
    checkpoint.SpawnCFrame = serverCFrame -- Server-determined position

    -- Persist to DataStore
    if DataService then
        task.spawn(function()
            pcall(function()
                DataService.UpdateCheckpoint(player, checkpoint.WorldId, checkpoint.LevelId, checkpointId)
            end)
        end)
    end

    print(string.format("[WorldService] Checkpoint %d set for %s", checkpointId, player.Name))
end
```

**Update Remote Call (Line 305):**

```lua
setCheckpointRemote.Remote.OnServerEvent:Connect(function(player, checkpointId)
    -- Remove checkpointCFrame parameter - server determines position
    WorldService.SetCheckpoint(player, checkpointId)
end)
```

**Testing:**
- [ ] Test setting checkpoint normally
- [ ] Test client sending fake checkpointId
- [ ] Test client far from checkpoint (should reject)
- [ ] Verify respawn uses server-determined position

---

### Critical Fix #2: Coin Cap Validation (2 hours)

**File:** `DataService.lua` (Lines 291-359)

**Fix Steps:**

Add coin cap constant (after line 40):

```lua
local MAX_COINS = 999999999 -- 999 million cap
```

Update AddCoins function (lines 291-321):

```lua
function DataService.AddCoins(player: Player, amount: number, source: string?): boolean
    local profile = Profiles[player]

    if not profile then
        warn("[DataService] No profile for " .. player.Name)
        return false
    end

    -- Validate amount
    if type(amount) ~= "number" or amount <= 0 then
        warn("[DataService] Invalid coin amount: " .. tostring(amount))
        return false
    end

    -- Check for NaN/infinity
    if amount ~= amount or math.abs(amount) == math.huge then
        warn("[DataService] Invalid coin value (NaN/Inf)")
        return false
    end

    -- Calculate new total
    local newTotal = profile.Data.Coins + amount

    -- SECURITY: Enforce maximum coin cap
    if newTotal > MAX_COINS then
        local actualAmount = MAX_COINS - profile.Data.Coins
        if actualAmount <= 0 then
            return false -- Already at cap
        end

        warn(string.format("[DataService] Coin cap reached for %s", player.Name))
        amount = actualAmount
        newTotal = MAX_COINS
    end

    profile.Data.Coins = newTotal

    -- Update leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coinsValue = leaderstats:FindFirstChild("Coins")
        if coinsValue then
            coinsValue.Value = profile.Data.Coins
        end
    end

    return true
end
```

**Testing:**
- [ ] Test adding coins normally
- [ ] Test adding coins that would exceed cap
- [ ] Test player at cap trying to earn coins
- [ ] Verify leaderstats updates correctly

---

### Critical Fix #3: Collectible Animation Memory Leak (3 hours)

**File:** `CollectibleService.lua` (Lines 127-133)

**Current Issue:** Infinite loops for each collectible

**Fix Steps:**

1. **Replace animation loops with Heartbeat connections:**

```lua
local CollectibleConnections = {} -- Add at top of file

function CollectibleService.SpawnCollectible(collectibleType: string, position: Vector3)
    -- ... existing spawn code ...

    -- Create rotation value attribute
    collectible:SetAttribute("RotationValue", 0)

    -- Use Heartbeat connection instead of loop
    local rotationConnection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Check if collectible still exists
        if not collectible.Parent or not collectible:IsDescendantOf(Workspace) then
            rotationConnection:Disconnect()
            CollectibleConnections[collectible] = nil
            return
        end

        -- Rotate (60 degrees per second)
        local currentRotation = collectible:GetAttribute("RotationValue") or 0
        currentRotation = currentRotation + (deltaTime * 60)
        collectible:SetAttribute("RotationValue", currentRotation)

        collectible.CFrame = collectible.CFrame * CFrame.Angles(0, math.rad(deltaTime * 60), 0)
    end)

    -- Store connection for cleanup
    CollectibleConnections[collectible] = rotationConnection

    -- ... existing touch handler ...
end
```

2. **Add cleanup when collected:**

```lua
function CollectibleService.CollectCollectible(player: Player, collectible: Instance)
    -- Disconnect rotation before destroying
    if CollectibleConnections[collectible] then
        CollectibleConnections[collectible]:Disconnect()
        CollectibleConnections[collectible] = nil
    end

    -- ... existing collection logic ...

    collectible:Destroy()
end
```

3. **Add global cleanup:**

```lua
-- Cleanup on service shutdown
function CollectibleService.Cleanup()
    for collectible, connection in pairs(CollectibleConnections) do
        connection:Disconnect()
    end
    CollectibleConnections = {}
end
```

**Testing:**
- [ ] Monitor thread count before/after spawning 100 collectibles
- [ ] Verify collectibles stop rotating after collection
- [ ] Test server with 1000+ collectibles over 30 minutes
- [ ] Check memory usage doesn't grow

---

## Pet Collector Sim
**Priority:** P1 - WAVE 3 LAUNCH
**Estimated Time:** 40-48 hours
**Target Launch:** Week 12

### Critical Fix #1: Negative Coin Exploit (2 hours)

**File:** `PetService.lua` (Line 119)

**Current Issue:**
```lua
PetService.DataService.AddCoins(player, -eggData.Cost)
```

**Fix Steps:**

Replace line 119 with:

```lua
-- Use RemoveCoins instead of AddCoins with negative value
if not PetService.DataService.RemoveCoins(player, eggData.Cost) then
    return false, "Insufficient coins"
end
```

**Also update other locations:**

Search entire file for `AddCoins(player, -` patterns and replace with `RemoveCoins(player, abs(amount))`.

**Testing:**
- [ ] Test hatching egg normally
- [ ] Test hatching with insufficient coins
- [ ] Test rapid-clicking hatch button
- [ ] Verify coins deducted correctly

---

### Critical Fix #2: Trading System Decision (24-48 hours)

**Option A: Complete Trading System (48 hours)**

**Files:** `TradingService.lua` (Lines 394-407)

Complete the ExchangePets function:

```lua
function TradingService.ExchangePets(
    senderData: {},
    receiverData: {},
    petsToGive: {string},
    petsToReceive: {string}
)
    -- Remove pets from sender
    for _, petInstanceId in ipairs(petsToGive) do
        for i, pet in ipairs(senderData.Pets) do
            if pet.InstanceId == petInstanceId then
                table.remove(senderData.Pets, i)
                break
            end
        end
    end

    -- ADD PETS TO RECEIVER (MISSING!)
    for _, petInstanceId in ipairs(petsToReceive) do
        -- Find pet in sender's inventory
        local petData = nil
        for _, pet in ipairs(receiverData.Pets) do
            if pet.InstanceId == petInstanceId then
                petData = TradingService.DeepCopy(pet)
                break
            end
        end

        if petData then
            -- Generate new instance ID for receiver
            petData.InstanceId = HttpService:GenerateGUID(false)
            table.insert(senderData.Pets, petData)
        end
    end
end
```

Additional work:
- [ ] Add trade validation (both players have pets)
- [ ] Add trade logging
- [ ] Add anti-duplication checksums
- [ ] Add rollback on failure
- [ ] Comprehensive testing

**Option B: Disable Trading (0 hours)**

**Recommended approach:**

```lua
-- In TradingService.lua, disable all trade functions
function TradingService.SendTradeRequest(...)
    return false, "Trading temporarily disabled"
end

function TradingService.AcceptTrade(...)
    return false, "Trading temporarily disabled"
end

-- Add UI message
```

**Launch with Option B, implement Option A post-launch**

---

### Critical Fix #3: Integrate SecureRemotes (8 hours)

**File:** All service files

**Current Pattern:**
```lua
remoteEvents.HatchEgg.OnServerEvent:Connect(function(player, eggType)
    PetService.HatchEgg(player, eggType)
end)
```

**Fix to:**

```lua
local SecureRemotes = require(ServerScriptService.Security.SecureRemotes)

local hatchEggRemote = SecureRemotes.CreateRemoteEvent("HatchEgg", {
    RateLimit = {
        MaxCalls = 20,
        Window = 60
    },
    Schema = {"string"}, -- eggType must be string
    AllowedValues = {
        {Values = {"Basic", "Rare", "Epic", "Legendary"}} -- Valid egg types
    }
})

hatchEggRemote.OnServerEvent:Connect(function(player, eggType)
    PetService.HatchEgg(player, eggType)
end)
```

Apply to all RemoteEvents:
- [ ] HatchEgg
- [ ] EquipPet
- [ ] FusePets
- [ ] SellPet
- [ ] PurchaseUpgrade
- [ ] ClaimReward

---

## Dimension Hopper
**Priority:** P1 - WAVE 3 LAUNCH
**Estimated Time:** 32-40 hours
**Target Launch:** Week 10

### Critical Fix #1: Fragment Animation Memory Leak (4 hours)

**File:** `LevelGenerator.lua` (Lines 262-270)

**Current Issue:** Infinite loops for each fragment

**Fix Steps:**

```lua
-- Store connections at module level
local FragmentConnections = {}

-- Replace animation code
local startY = position.Y
local startTime = tick()

local floatConnection = RunService.Heartbeat:Connect(function()
    if not fragment.Parent then
        floatConnection:Disconnect()
        FragmentConnections[fragment] = nil
        return
    end

    local elapsed = tick() - startTime
    float.Position = Vector3.new(
        position.X,
        startY + math.sin(elapsed * 2) * 0.5,
        position.Z
    )
end)

-- Store for cleanup
FragmentConnections[fragment] = floatConnection

-- Cleanup when collected
fragment.Touched:Connect(function(hit)
    -- ... collection logic ...

    if FragmentConnections[fragment] then
        FragmentConnections[fragment]:Disconnect()
        FragmentConnections[fragment] = nil
    end
end)
```

**Testing:**
- [ ] Monitor memory usage over 30 minutes
- [ ] Spawn 200+ fragments, verify cleanup
- [ ] Test dimension unload

---

### Summary of Effort

| Game | Critical Fixes | Hours | Additional Work | Total |
|------|---------------|-------|-----------------|-------|
| Tower Ascent | 5 fixes | 8-12h | Testing, deployment | 12-16h |
| Speed Run Universe | 5 fixes | 12-16h | Polish, testing | 16-20h |
| Adventure Story Obby | 3 fixes | 8-12h | Mobile UI, testing | 16-20h |
| Pet Collector Sim | 3 fixes | 12-16h | Integration, testing | 40-48h |
| Dimension Hopper | 4 fixes | 16-20h | Anti-cheat, testing | 32-40h |

**Total Estimated Time for Wave 1-3:** 116-144 hours (3-4 weeks of full-time work)

---

**Version:** 1.0
**Last Updated:** 2026-02-22
