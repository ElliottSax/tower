# Roblox Security Hardening Guide
*Comprehensive security patterns for production-ready games*

## Table of Contents
1. [Remote Event Security](#remote-event-security)
2. [DataStore Best Practices](#datastore-best-practices)
3. [Anti-Cheat Implementation](#anti-cheat-implementation)
4. [Input Validation](#input-validation)
5. [Rate Limiting](#rate-limiting)
6. [Session Management](#session-management)
7. [Security Checklist](#security-checklist)

---

## Remote Event Security

### ❌ BAD: Trust Client Data
```lua
-- VULNERABLE
RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId, price)
    -- Client controls price!
    CurrencyService.RemoveCoins(player, price)
    InventoryService.AddItem(player, itemId)
end)
```

### ✅ GOOD: Server Authority
```lua
-- SECURE
local ITEM_PRICES = {
    Sword = 1000,
    Shield = 500,
    Potion = 100
}

RemoteEvents.PurchaseItem.OnServerEvent:Connect(function(player, itemId)
    -- Validate input
    if type(itemId) ~= "string" or #itemId > 50 then
        warn("[Security] Invalid itemId from " .. player.Name)
        return
    end

    -- Server determines price
    local price = ITEM_PRICES[itemId]
    if not price then
        warn("[Security] Unknown item " .. itemId)
        return
    end

    -- Check can afford
    if not CurrencyService.HasCoins(player, price) then
        return
    end

    -- Atomic transaction
    if CurrencyService.RemoveCoins(player, price) then
        InventoryService.AddItem(player, itemId)
    end
end)
```

---

## Input Validation

### Universal Validation Function
```lua
local Validator = {}

function Validator.ValidateString(value: any, maxLength: number?): string?
    if type(value) ~= "string" then
        return nil
    end

    if maxLength and #value > maxLength then
        return nil
    end

    -- Remove control characters
    value = value:gsub("%c", "")

    return value
end

function Validator.ValidateNumber(value: any, min: number?, max: number?): number?
    if type(value) ~= "number" then
        return nil
    end

    if value ~= value then -- NaN check
        return nil
    end

    if value == math.huge or value == -math.huge then
        return nil
    end

    if min and value < min then
        return nil
    end

    if max and value > max then
        return nil
    end

    return value
end

function Validator.ValidateEnum(value: any, validValues: {string}): string?
    if type(value) ~= "string" then
        return nil
    end

    for _, valid in ipairs(validValues) do
        if value == valid then
            return value
        end
    end

    return nil
end

function Validator.ValidateUserId(value: any): number?
    local num = Validator.ValidateNumber(value, 1, 9999999999)
    if not num then
        return nil
    end

    return math.floor(num)
end

return Validator
```

### Usage Example
```lua
local Validator = require(ReplicatedStorage.Shared.Validator)

RemoteEvents.EquipItem.OnServerEvent:Connect(function(player, itemId, slot)
    -- Validate all inputs
    itemId = Validator.ValidateString(itemId, 50)
    slot = Validator.ValidateNumber(slot, 1, 10)

    if not itemId or not slot then
        warn("[Security] Invalid input from " .. player.Name)
        return
    end

    -- Safe to use
    EquipmentService.Equip(player, itemId, slot)
end)
```

---

## Rate Limiting

### Rate Limiter Module
```lua
local RateLimiter = {}
RateLimiter.__index = RateLimiter

-- Track requests per player
local playerRequests = {}

function RateLimiter.new(maxRequests: number, windowSeconds: number)
    local self = setmetatable({}, RateLimiter)
    self.MaxRequests = maxRequests
    self.WindowSeconds = windowSeconds
    return self
end

function RateLimiter:CheckLimit(player: Player): boolean
    local userId = player.UserId
    local now = tick()

    -- Initialize player data
    if not playerRequests[userId] then
        playerRequests[userId] = {
            Requests = {},
            Violations = 0
        }
    end

    local data = playerRequests[userId]

    -- Clean old requests
    local validRequests = {}
    for _, timestamp in ipairs(data.Requests) do
        if now - timestamp < self.WindowSeconds then
            table.insert(validRequests, timestamp)
        end
    end
    data.Requests = validRequests

    -- Check limit
    if #data.Requests >= self.MaxRequests then
        data.Violations = data.Violations + 1

        -- Progressive penalties
        if data.Violations >= 10 then
            player:Kick("Rate limit exceeded - suspected spam/exploit")
        elseif data.Violations >= 5 then
            warn("[RateLimit] High violation count for " .. player.Name)
        end

        return false
    end

    -- Allow request
    table.insert(data.Requests, now)
    return true
end

-- Cleanup on player leave
game.Players.PlayerRemoving:Connect(function(player)
    playerRequests[player.UserId] = nil
end)

return RateLimiter
```

### Usage Example
```lua
local RateLimiter = require(ServerScriptService.Utilities.RateLimiter)

-- 10 requests per 60 seconds
local purchaseLimiter = RateLimiter.new(10, 60)

RemoteEvents.Purchase.OnServerEvent:Connect(function(player, itemId)
    if not purchaseLimiter:CheckLimit(player) then
        return -- Rate limited
    end

    -- Process purchase
end)
```

---

## DataStore Best Practices

### ❌ BAD: SetAsync with No Protection
```lua
function DataService.SaveData(player: Player)
    local data = PlayerData[player.UserId]
    DataStore:SetAsync("Player_" .. player.UserId, data)
end
```

### ✅ GOOD: UpdateAsync with Retry Logic
```lua
function DataService.SaveData(player: Player): boolean
    local userId = player.UserId
    local data = PlayerData[userId]
    if not data then return false end

    local MAX_RETRIES = 3
    local RETRY_DELAY = 1

    for attempt = 1, MAX_RETRIES do
        local success, err = pcall(function()
            DataStore:UpdateAsync("Player_" .. userId, function(oldData)
                -- Prevent data rollback
                if oldData and oldData.LastSave then
                    if oldData.LastSave > data.LastSave then
                        warn("[DataStore] Prevented rollback for " .. player.Name)
                        return oldData
                    end
                end

                -- Update timestamp
                data.LastSave = os.time()
                return data
            end)
        end)

        if success then
            return true
        else
            warn(string.format("[DataStore] Save attempt %d/%d failed: %s",
                attempt, MAX_RETRIES, tostring(err)))

            if attempt < MAX_RETRIES then
                task.wait(RETRY_DELAY * attempt) -- Exponential backoff
            end
        end
    end

    -- Save failed - add to retry queue
    table.insert(DataService.FailedSaves, {
        UserId = userId,
        Data = DataService.DeepCopy(data),
        Timestamp = tick()
    })

    return false
end
```

### ProfileService Template
```lua
local ProfileService = require(ReplicatedStorage.Packages.ProfileService)

local ProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    {
        -- Default data structure
        Coins = 0,
        Level = 1,
        Inventory = {},
        Settings = {
            Music = true,
            SFX = true
        }
    }
)

function DataService.LoadProfile(player: Player)
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

    if not profile then
        player:Kick("Failed to load data. Please rejoin.")
        return
    end

    profile:AddUserId(player.UserId) -- GDPR compliance

    profile:Reconcile() -- Fill missing fields

    profile:ListenToRelease(function()
        Profiles[player] = nil
        player:Kick("Session conflict detected")
    end)

    if player:IsDescendantOf(game.Players) then
        Profiles[player] = profile
        return profile
    else
        profile:Release()
    end
end

game.Players.PlayerRemoving:Connect(function(player)
    local profile = Profiles[player]
    if profile then
        profile:Release()
    end
end)

game:BindToClose(function()
    for player, profile in pairs(Profiles) do
        profile:Release()
    end
    task.wait(5) -- Give time for saves
end)
```

---

## Anti-Cheat Implementation

### Server-Side Movement Validation
```lua
local AntiCheat = {}

local PlayerData = {}
local MAX_SPEED = 16 -- Default walkspeed
local TELEPORT_THRESHOLD = 100 -- studs

function AntiCheat.Initialize()
    -- Track player positions
    game.Players.PlayerAdded:Connect(function(player)
        PlayerData[player.UserId] = {
            LastPosition = nil,
            LastUpdate = tick(),
            Violations = 0,
            MaxSpeed = MAX_SPEED
        }

        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            local rootPart = character:WaitForChild("HumanoidRootPart")

            PlayerData[player.UserId].LastPosition = rootPart.Position
            PlayerData[player.UserId].MaxSpeed = humanoid.WalkSpeed
        end)
    end)

    -- Validate every 0.5 seconds
    task.spawn(function()
        while true do
            task.wait(0.5)
            AntiCheat.ValidateAllPlayers()
        end
    end)
end

function AntiCheat.ValidateAllPlayers()
    for _, player in ipairs(game.Players:GetPlayers()) do
        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then continue end

        local data = PlayerData[player.UserId]
        if not data or not data.LastPosition then continue end

        local now = tick()
        local deltaTime = now - data.LastUpdate
        local distance = (rootPart.Position - data.LastPosition).Magnitude
        local speed = distance / deltaTime

        -- Check for speed hacking (with tolerance)
        local maxAllowed = data.MaxSpeed * 1.5 -- 50% tolerance
        if speed > maxAllowed and deltaTime > 0.1 then
            data.Violations = data.Violations + 1

            warn(string.format("[AntiCheat] %s speed violation: %.1f (max: %.1f)",
                player.Name, speed, maxAllowed))

            if data.Violations >= 3 then
                player:Kick("Abnormal movement detected")
            end
        end

        -- Check for teleportation
        if distance > TELEPORT_THRESHOLD and deltaTime < 1 then
            data.Violations = data.Violations + 1

            warn(string.format("[AntiCheat] %s teleport violation: %.1f studs",
                player.Name, distance))

            if data.Violations >= 2 then
                player:Kick("Teleportation detected")
            end
        end

        -- Update tracking
        data.LastPosition = rootPart.Position
        data.LastUpdate = now
    end
end

-- Update max speed when changed
function AntiCheat.SetPlayerSpeed(player: Player, newSpeed: number)
    local data = PlayerData[player.UserId]
    if data then
        data.MaxSpeed = newSpeed
    end
end

return AntiCheat
```

---

## Session Management

### Prevent Multi-Server Sessions
```lua
local SessionManager = {}
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")

local SessionStore = DataStoreService:GetDataStore("PlayerSessions")
local LOCK_TIMEOUT = 600 -- 10 minutes

function SessionManager.AcquireLock(player: Player): boolean
    local userId = player.UserId
    local jobId = game.JobId

    local success, result = pcall(function()
        return SessionStore:UpdateAsync("Session_" .. userId, function(oldData)
            local now = os.time()

            -- Check existing lock
            if oldData and oldData.JobId then
                local lockAge = now - (oldData.Timestamp or 0)

                -- Lock still valid
                if lockAge < LOCK_TIMEOUT and oldData.JobId ~= jobId then
                    -- Notify other server to release
                    pcall(function()
                        MessagingService:PublishAsync("SessionRelease", {
                            UserId = userId,
                            JobId = oldData.JobId
                        })
                    end)

                    return nil -- Reject lock acquisition
                end
            end

            -- Acquire lock
            return {
                JobId = jobId,
                Timestamp = now,
                PlayerName = player.Name
            }
        end)
    end)

    return success and result ~= nil
end

function SessionManager.ReleaseLock(player: Player)
    local userId = player.UserId

    pcall(function()
        SessionStore:RemoveAsync("Session_" .. userId)
    end)
end

-- Listen for release requests
MessagingService:SubscribeAsync("SessionRelease", function(message)
    if message.Data.JobId == game.JobId then
        local player = game.Players:GetPlayerByUserId(message.Data.UserId)
        if player then
            player:Kick("You joined another server")
        end
    end
end)

return SessionManager
```

---

## Security Checklist

### Pre-Launch Security Audit

#### Remote Events
- [ ] All RemoteEvents have input validation
- [ ] All parameters have type checking
- [ ] All parameters have range/length limits
- [ ] Server determines all prices/rewards
- [ ] Rate limiting on all player actions
- [ ] No client-controlled timing

#### Data Stores
- [ ] Using UpdateAsync for currency
- [ ] Retry logic with exponential backoff
- [ ] Session locking implemented
- [ ] GDPR compliance (AddUserId)
- [ ] Data reconciliation for missing fields
- [ ] BindToClose saves all data

#### Anti-Cheat
- [ ] Server-side speed validation
- [ ] Teleport detection
- [ ] Position validation
- [ ] Inventory validation
- [ ] Stat gain validation
- [ ] Timing validation for races/speedruns

#### General Security
- [ ] FilteringEnabled verified
- [ ] No _G global pollution
- [ ] No client-side Instance creation
- [ ] Admin commands protected
- [ ] Webhook URLs validated
- [ ] Sensitive data not logged

#### Memory Management
- [ ] PlayerRemoving cleanup
- [ ] Connection cleanup
- [ ] Debounce table cleanup
- [ ] Active session cleanup
- [ ] Ghost data pruning

---

## Common Exploit Patterns

### 1. Negative Number Exploit
```lua
-- VULNERABLE
function AddCoins(player, amount)
    if amount <= 0 then return end
    coins = coins + amount
end

-- Exploiter calls:
RemoveCoins(player, -1000) -- Adds coins!

-- FIX
function AddCoins(player, amount)
    if type(amount) ~= "number" or amount <= 0 then return end
    coins = coins + amount
end

function RemoveCoins(player, amount)
    if type(amount) ~= "number" or amount <= 0 then return end
    amount = math.abs(amount) -- Force positive
    coins = coins - amount
end
```

### 2. Race Condition Exploit
```lua
-- VULNERABLE
function Purchase(player, itemId)
    if HasCoins(player, 100) then
        -- Exploiter spams purchase here
        RemoveCoins(player, 100)
        GiveItem(player, itemId)
    end
end

-- FIX
local purchaseLocks = {}

function Purchase(player, itemId)
    if purchaseLocks[player.UserId] then
        return -- Already purchasing
    end

    purchaseLocks[player.UserId] = true

    if HasCoins(player, 100) then
        if RemoveCoins(player, 100) then
            GiveItem(player, itemId)
        end
    end

    purchaseLocks[player.UserId] = nil
end
```

### 3. Client Timing Exploit
```lua
-- VULNERABLE
RemoteEvents.CompleteObby.OnServerEvent:Connect(function(player, completionTime)
    -- Client controls time!
    Leaderboard.UpdateTime(player, completionTime)
end)

-- FIX
local playerStartTimes = {}

function StartObby(player)
    playerStartTimes[player.UserId] = tick()
end

RemoteEvents.CompleteObby.OnServerEvent:Connect(function(player)
    local startTime = playerStartTimes[player.UserId]
    if not startTime then return end

    local completionTime = tick() - startTime
    Leaderboard.UpdateTime(player, completionTime)

    playerStartTimes[player.UserId] = nil
end)
```

---

## Emergency Response

### If You Discover an Active Exploit

1. **Immediate Actions**
   ```lua
   -- Disable affected feature
   RemoteEvents.VulnerableFeature.OnServerEvent:Connect(function()
       return -- Disabled temporarily
   end)
   ```

2. **Log Exploit Attempts**
   ```lua
   local ExploitLog = DataStoreService:GetDataStore("ExploitLog")

   function LogExploit(player, exploitType, details)
       pcall(function()
           ExploitLog:SetAsync(
               string.format("%d_%d", player.UserId, os.time()),
               {
                   PlayerName = player.Name,
                   UserId = player.UserId,
                   ExploitType = exploitType,
                   Details = details,
                   Timestamp = os.time(),
                   JobId = game.JobId
               }
           )
       end)
   end
   ```

3. **Ban Known Exploiters**
   ```lua
   -- Add to ban list
   local KNOWN_EXPLOITERS = {1234567, 8901234}

   game.Players.PlayerAdded:Connect(function(player)
       for _, userId in ipairs(KNOWN_EXPLOITERS) do
           if player.UserId == userId then
               player:Kick("Banned for exploitation")
           end
       end
   end)
   ```

4. **Notify Team**
   - Update Discord webhook
   - Create incident report
   - Document exploit method
   - Plan fix deployment

---

## Additional Resources

- **Roblox DevHub Security**: https://create.roblox.com/docs/scripting/security
- **ProfileService**: https://madstudioroblox.github.io/ProfileService/
- **FilteringEnabled**: Must be enabled (default since 2018)
- **Anti-Cheat Patterns**: Server authority, validation, monitoring

---

## Version History
- v1.0 (2026-02-22): Initial comprehensive security guide
