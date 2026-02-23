# Roblox Code Templates & Patterns
*Production-ready code templates for common scenarios*

## Table of Contents
1. [Service Template](#service-template)
2. [Secure Remote Events](#secure-remote-events)
3. [DataStore with ProfileService](#datastore-with-profileservice)
4. [Currency System](#currency-system)
5. [Inventory System](#inventory-system)
6. [Rate Limiter](#rate-limiter)
7. [Anti-Cheat](#anti-cheat)
8. [Validation Utilities](#validation-utilities)
9. [Event Bus](#event-bus)
10. [Object Pooling](#object-pooling)

---

## Service Template

### Standard Service Structure

```lua
--[[
    ServiceName.lua

    Description: Brief description of service purpose
    Dependencies: List required services
    Public API: List main functions

    Author: Your Name
    Created: 2026-02-22
    Version: 1.0
]]

local ServiceName = {}
ServiceName.__index = ServiceName

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module Dependencies
local Utilities = ServerScriptService.Utilities
local ServiceLocator = require(Utilities.ServiceLocator)

-- Constants
local CONSTANT_NAME = 100
local CONFIG = {
    Setting1 = true,
    Setting2 = 50,
}

-- Private State
local PlayerData = {}
local ActiveSessions = {}
local Connections = {}

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ServiceRemote = nil

--[[
    Initializes the service
    Called once on server start
]]
function ServiceName.Initialize()
    print("[ServiceName] Initializing...")

    -- Create remote events
    ServiceRemote = Instance.new("RemoteEvent")
    ServiceRemote.Name = "ServiceNameEvent"
    ServiceRemote.Parent = RemoteEvents

    -- Connect events
    ServiceName.ConnectEvents()

    -- Start loops
    ServiceName.StartUpdateLoop()

    print("[ServiceName] Initialized successfully")
end

--[[
    Connects all event listeners
]]
function ServiceName.ConnectEvents()
    -- Player added
    Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        ServiceName.OnPlayerAdded(player)
    end)

    -- Player removing
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        ServiceName.OnPlayerRemoving(player)
    end)

    -- Remote events
    ServiceRemote.OnServerEvent:Connect(function(player, action, ...)
        ServiceName.HandleRemoteEvent(player, action, ...)
    end)
end

--[[
    Handles player joining
    @param player Player - The player who joined
]]
function ServiceName.OnPlayerAdded(player: Player)
    PlayerData[player.UserId] = {
        Player = player,
        Data = {},
        Timestamp = tick()
    }

    print("[ServiceName] Player added: " .. player.Name)
end

--[[
    Handles player leaving - CRITICAL for cleanup
    @param player Player - The player who left
]]
function ServiceName.OnPlayerRemoving(player: Player)
    -- Cleanup player data
    if PlayerData[player.UserId] then
        PlayerData[player.UserId] = nil
    end

    -- Cleanup active sessions
    if ActiveSessions[player.UserId] then
        ActiveSessions[player.UserId] = nil
    end

    print("[ServiceName] Player removed: " .. player.Name)
end

--[[
    Handles remote events from client
    @param player Player
    @param action string
    @param ... any additional arguments
]]
function ServiceName.HandleRemoteEvent(player: Player, action: string, ...)
    -- Validate action
    if type(action) ~= "string" then
        warn("[ServiceName] Invalid action type from " .. player.Name)
        return
    end

    -- Route to handlers
    if action == "Action1" then
        ServiceName.HandleAction1(player, ...)
    elseif action == "Action2" then
        ServiceName.HandleAction2(player, ...)
    else
        warn("[ServiceName] Unknown action: " .. action)
    end
end

--[[
    Main update loop
]]
function ServiceName.StartUpdateLoop()
    task.spawn(function()
        while true do
            task.wait(1) -- Update interval

            local success, err = pcall(function()
                ServiceName.Update()
            end)

            if not success then
                warn("[ServiceName] Update error: " .. tostring(err))
            end
        end
    end)
end

--[[
    Update logic called each loop
]]
function ServiceName.Update()
    -- Update logic here
    for userId, data in pairs(PlayerData) do
        -- Process each player
    end
end

--[[
    Cleanup and shutdown
]]
function ServiceName.Cleanup()
    print("[ServiceName] Cleaning up...")

    -- Disconnect all connections
    for name, connection in pairs(Connections) do
        connection:Disconnect()
    end

    -- Clear data
    PlayerData = {}
    ActiveSessions = {}

    print("[ServiceName] Cleanup complete")
end

-- Public API
return ServiceName
```

---

## Secure Remote Events

### SecureRemoteEvent Wrapper

```lua
local SecureRemoteEvent = {}
SecureRemoteEvent.__index = SecureRemoteEvent

local RateLimits = {}
local Validators = require(script.Parent.Validators)

function SecureRemoteEvent.new(name: string, config: {})
    local self = setmetatable({}, SecureRemoteEvent)

    self.Name = name
    self.Config = config or {}

    -- Create remote
    self.Remote = Instance.new("RemoteEvent")
    self.Remote.Name = name
    self.Remote.Parent = game.ReplicatedStorage.RemoteEvents

    -- Rate limit settings
    self.MaxCalls = config.RateLimit and config.RateLimit.MaxCalls or 60
    self.TimeWindow = config.RateLimit and config.RateLimit.Window or 60

    -- Validation schema
    self.Schema = config.Schema or {}
    self.AllowedValues = config.AllowedValues or {}

    return self
end

function SecureRemoteEvent:OnServerEvent(callback)
    self.Remote.OnServerEvent:Connect(function(player, ...)
        -- Check rate limit
        if not self:CheckRateLimit(player) then
            warn(string.format("[SecureRemote] Rate limit exceeded: %s by %s",
                self.Name, player.Name))
            return
        end

        -- Validate arguments
        local args = {...}
        if not self:ValidateArgs(args) then
            warn(string.format("[SecureRemote] Invalid args: %s by %s",
                self.Name, player.Name))
            return
        end

        -- Call original callback
        local success, err = pcall(callback, player, ...)
        if not success then
            warn(string.format("[SecureRemote] Error in %s: %s",
                self.Name, tostring(err)))
        end
    end)
end

function SecureRemoteEvent:CheckRateLimit(player: Player): boolean
    local key = player.UserId .. "_" .. self.Name
    local now = tick()

    if not RateLimits[key] then
        RateLimits[key] = {}
    end

    local calls = RateLimits[key]

    -- Remove old calls outside time window
    local validCalls = {}
    for _, timestamp in ipairs(calls) do
        if now - timestamp < self.TimeWindow then
            table.insert(validCalls, timestamp)
        end
    end
    RateLimits[key] = validCalls

    -- Check limit
    if #validCalls >= self.MaxCalls then
        return false
    end

    -- Add this call
    table.insert(RateLimits[key], now)
    return true
end

function SecureRemoteEvent:ValidateArgs(args: {}): boolean
    -- Check argument count
    if #args ~= #self.Schema then
        return false
    end

    -- Check types
    for i, expectedType in ipairs(self.Schema) do
        if type(args[i]) ~= expectedType then
            return false
        end
    end

    -- Check allowed values
    for i, allowedSet in ipairs(self.AllowedValues) do
        if allowedSet.Values then
            local found = false
            for _, allowedValue in ipairs(allowedSet.Values) do
                if args[i] == allowedValue then
                    found = true
                    break
                end
            end
            if not found then
                return false
            end
        end
    end

    return true
end

-- Usage Example:
--[[
local purchaseRemote = SecureRemoteEvent.new("PurchaseItem", {
    RateLimit = {
        MaxCalls = 10,
        Window = 60
    },
    Schema = {"string", "number"},
    AllowedValues = {
        {Values = {"Sword", "Shield", "Potion"}},
        nil -- No restriction on second arg
    }
})

purchaseRemote:OnServerEvent(function(player, itemId, quantity)
    ShopService.Purchase(player, itemId, quantity)
end)
]]

return SecureRemoteEvent
```

---

## DataStore with ProfileService

### Complete ProfileService Setup

```lua
local DataService = {}

local ProfileService = require(game.ReplicatedStorage.Packages.ProfileService)
local Players = game:GetService("Players")

-- Profile store
local ProfileStore = ProfileService.GetProfileStore(
    "PlayerData_V2", -- Version your store!
    {
        -- Default player data
        Coins = 0,
        Level = 1,
        XP = 0,
        Inventory = {},
        Equipped = {},
        Settings = {
            Music = true,
            SFX = true,
            Notifications = true
        },
        Stats = {
            TotalPlayTime = 0,
            LastLogin = 0,
            CreatedAt = 0
        },
        Achievements = {},

        -- Metadata
        Version = 2,
        LastSave = 0
    }
)

-- Active profiles
local Profiles = {}

--[[
    Loads player profile
    @param player Player
    @return Profile? - Returns nil if load failed
]]
function DataService.LoadProfile(player: Player)
    local profile = ProfileStore:LoadProfileAsync(
        "Player_" .. player.UserId,
        "ForceLoad" -- Kick player from other servers
    )

    if not profile then
        player:Kick("Failed to load data. Please rejoin.")
        return nil
    end

    -- GDPR compliance
    profile:AddUserId(player.UserId)

    -- Fill missing fields from template
    profile:Reconcile()

    -- Handle session conflicts
    profile:ListenToRelease(function()
        Profiles[player] = nil
        player:Kick("Profile released (joined from another device)")
    end)

    -- Check if player still in game
    if not player:IsDescendantOf(Players) then
        profile:Release()
        return nil
    end

    -- Store profile
    Profiles[player] = profile

    -- Initialize first-time data
    if profile.Data.Stats.CreatedAt == 0 then
        profile.Data.Stats.CreatedAt = os.time()
    end
    profile.Data.Stats.LastLogin = os.time()

    -- Create leaderstats
    DataService.CreateLeaderstats(player, profile)

    return profile
end

--[[
    Creates leaderstats folder
]]
function DataService.CreateLeaderstats(player: Player, profile)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = profile.Data.Coins
    coins.Parent = leaderstats

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = profile.Data.Level
    level.Parent = leaderstats
end

--[[
    Gets player profile
    @param player Player
    @return Profile?
]]
function DataService.GetProfile(player: Player)
    return Profiles[player]
end

--[[
    Adds coins with validation
    @param player Player
    @param amount number
    @return boolean success
]]
function DataService.AddCoins(player: Player, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end

    -- Validation
    if type(amount) ~= "number" or amount <= 0 then
        return false
    end

    if amount ~= amount or amount == math.huge then
        return false
    end

    -- Cap check
    local MAX_COINS = 999999999
    local newTotal = profile.Data.Coins + amount

    if newTotal > MAX_COINS then
        amount = MAX_COINS - profile.Data.Coins
        if amount <= 0 then return false end
        newTotal = MAX_COINS
    end

    -- Update
    profile.Data.Coins = newTotal

    -- Update leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Value = newTotal
        end
    end

    return true
end

--[[
    Removes coins with validation
    @param player Player
    @param amount number
    @return boolean success
]]
function DataService.RemoveCoins(player: Player, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end

    -- Validation
    if type(amount) ~= "number" or amount <= 0 then
        return false
    end

    -- Force positive
    amount = math.abs(amount)

    -- Check sufficient funds
    if profile.Data.Coins < amount then
        return false
    end

    -- Update
    local newTotal = math.max(0, profile.Data.Coins - amount)
    profile.Data.Coins = newTotal

    -- Update leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Value = newTotal
        end
    end

    return true
end

--[[
    Player cleanup
]]
Players.PlayerRemoving:Connect(function(player)
    local profile = Profiles[player]
    if profile then
        -- Update play time
        profile.Data.Stats.TotalPlayTime = profile.Data.Stats.TotalPlayTime +
            (os.time() - profile.Data.Stats.LastLogin)

        -- Release profile (auto-saves)
        profile:Release()
        Profiles[player] = nil
    end
end)

--[[
    Server shutdown handling
]]
game:BindToClose(function()
    print("[DataService] Server shutting down, saving all profiles...")

    -- Release all profiles
    for player, profile in pairs(Profiles) do
        profile:Release()
    end

    -- Wait for saves (ProfileService auto-waits)
    task.wait(2)

    print("[DataService] All profiles saved")
end)

return DataService
```

---

## Currency System

### Atomic Currency Operations

```lua
local CurrencyService = {}

-- Transaction locks to prevent race conditions
local TransactionLocks = {}

--[[
    Executes an atomic currency transaction
    @param player Player
    @param operation function - Function to execute
    @return boolean success
    @return any? result
]]
function CurrencyService.ExecuteTransaction(player: Player, operation: (any) -> any)
    local userId = player.UserId

    -- Wait for existing transaction to complete
    while TransactionLocks[userId] do
        task.wait(0.01)
    end

    -- Acquire lock
    TransactionLocks[userId] = true

    -- Execute operation
    local success, result = pcall(operation)

    -- Release lock
    TransactionLocks[userId] = nil

    return success, result
end

--[[
    Safe purchase operation
    @param player Player
    @param itemId string
    @param price number
    @return boolean success
    @return string? message
]]
function CurrencyService.Purchase(player: Player, itemId: string, price: number)
    return CurrencyService.ExecuteTransaction(player, function()
        -- Get DataService
        local DataService = require(game.ServerScriptService.Services.DataService)
        local profile = DataService.GetProfile(player)

        if not profile then
            return false, "No profile"
        end

        -- Check funds
        if profile.Data.Coins < price then
            return false, "Insufficient coins"
        end

        -- Remove coins
        if not DataService.RemoveCoins(player, price) then
            return false, "Failed to remove coins"
        end

        -- Give item
        table.insert(profile.Data.Inventory, {
            Id = itemId,
            PurchasedAt = os.time()
        })

        return true, "Purchase successful"
    end)
end

--[[
    Safe sell operation
    @param player Player
    @param itemInstanceId string
    @param sellPrice number
    @return boolean success
]]
function CurrencyService.Sell(player: Player, itemInstanceId: string, sellPrice: number)
    return CurrencyService.ExecuteTransaction(player, function()
        local DataService = require(game.ServerScriptService.Services.DataService)
        local profile = DataService.GetProfile(player)

        if not profile then
            return false
        end

        -- Find and remove item
        local itemFound = false
        for i, item in ipairs(profile.Data.Inventory) do
            if item.InstanceId == itemInstanceId then
                table.remove(profile.Data.Inventory, i)
                itemFound = true
                break
            end
        end

        if not itemFound then
            return false
        end

        -- Add coins
        DataService.AddCoins(player, sellPrice)

        return true
    end)
end

return CurrencyService
```

---

## Inventory System

### Scalable Inventory Management

```lua
local InventoryService = {}

local HttpService = game:GetService("HttpService")

-- Item definitions
local ItemCatalog = require(game.ReplicatedStorage.Shared.ItemCatalog)

--[[
    Adds item to player inventory
    @param player Player
    @param itemId string
    @param quantity number?
    @return boolean success
    @return string? itemInstanceId
]]
function InventoryService.AddItem(player: Player, itemId: string, quantity: number?)
    local DataService = require(game.ServerScriptService.Services.DataService)
    local profile = DataService.GetProfile(player)

    if not profile then
        return false
    end

    quantity = quantity or 1

    -- Check if item exists in catalog
    local itemData = ItemCatalog.GetItem(itemId)
    if not itemData then
        warn("[Inventory] Unknown item: " .. itemId)
        return false
    end

    -- Check inventory limit
    local MAX_INVENTORY = 500
    if #profile.Data.Inventory >= MAX_INVENTORY then
        return false, nil
    end

    -- Check if stackable
    if itemData.Stackable then
        -- Find existing stack
        for _, item in ipairs(profile.Data.Inventory) do
            if item.Id == itemId then
                item.Quantity = item.Quantity + quantity
                return true, item.InstanceId
            end
        end
    end

    -- Create new item instance
    local itemInstance = {
        InstanceId = HttpService:GenerateGUID(false),
        Id = itemId,
        Quantity = quantity,
        AddedAt = os.time(),
        Metadata = {}
    }

    table.insert(profile.Data.Inventory, itemInstance)

    return true, itemInstance.InstanceId
end

--[[
    Removes item from inventory
    @param player Player
    @param itemInstanceId string
    @param quantity number?
    @return boolean success
]]
function InventoryService.RemoveItem(player: Player, itemInstanceId: string, quantity: number?): boolean
    local DataService = require(game.ServerScriptService.Services.DataService)
    local profile = DataService.GetProfile(player)

    if not profile then
        return false
    end

    quantity = quantity or 1

    -- Find item
    for i, item in ipairs(profile.Data.Inventory) do
        if item.InstanceId == itemInstanceId then
            if item.Quantity and item.Quantity > quantity then
                -- Remove partial quantity
                item.Quantity = item.Quantity - quantity
                return true
            else
                -- Remove entire item
                table.remove(profile.Data.Inventory, i)
                return true
            end
        end
    end

    return false
end

--[[
    Checks if player has item
    @param player Player
    @param itemId string
    @param quantity number?
    @return boolean hasItem
]]
function InventoryService.HasItem(player: Player, itemId: string, quantity: number?): boolean
    local DataService = require(game.ServerScriptService.Services.DataService)
    local profile = DataService.GetProfile(player)

    if not profile then
        return false
    end

    quantity = quantity or 1
    local totalQuantity = 0

    for _, item in ipairs(profile.Data.Inventory) do
        if item.Id == itemId then
            totalQuantity = totalQuantity + (item.Quantity or 1)
        end
    end

    return totalQuantity >= quantity
end

--[[
    Gets all items of a specific type
    @param player Player
    @param itemType string
    @return {any} items
]]
function InventoryService.GetItemsByType(player: Player, itemType: string): {any}
    local DataService = require(game.ServerScriptService.Services.DataService)
    local profile = DataService.GetProfile(player)

    if not profile then
        return {}
    end

    local results = {}

    for _, item in ipairs(profile.Data.Inventory) do
        local itemData = ItemCatalog.GetItem(item.Id)
        if itemData and itemData.Type == itemType then
            table.insert(results, item)
        end
    end

    return results
end

return InventoryService
```

---

## Rate Limiter

### Flexible Rate Limiting System

```lua
local RateLimiter = {}
RateLimiter.__index = RateLimiter

local PlayerLimits = {}

--[[
    Creates a new rate limiter
    @param maxRequests number - Maximum requests allowed
    @param windowSeconds number - Time window in seconds
    @param burstAllowance number? - Extra burst capacity
    @return RateLimiter
]]
function RateLimiter.new(maxRequests: number, windowSeconds: number, burstAllowance: number?)
    local self = setmetatable({}, RateLimiter)

    self.MaxRequests = maxRequests
    self.WindowSeconds = windowSeconds
    self.BurstAllowance = burstAllowance or 0
    self.Penalties = {}

    return self
end

--[[
    Checks if request is allowed
    @param player Player
    @return boolean allowed
    @return number? remainingRequests
]]
function RateLimiter:CheckLimit(player: Player): (boolean, number?)
    local userId = player.UserId
    local now = tick()

    -- Initialize player data
    if not PlayerLimits[userId] then
        PlayerLimits[userId] = {
            Requests = {},
            Violations = 0,
            PenaltyUntil = 0
        }
    end

    local data = PlayerLimits[userId]

    -- Check if under penalty
    if data.PenaltyUntil > now then
        return false, 0
    end

    -- Clean old requests
    local validRequests = {}
    for _, timestamp in ipairs(data.Requests) do
        if now - timestamp < self.WindowSeconds then
            table.insert(validRequests, timestamp)
        end
    end
    data.Requests = validRequests

    -- Calculate remaining requests
    local used = #data.Requests
    local limit = self.MaxRequests + self.BurstAllowance
    local remaining = limit - used

    -- Check limit
    if used >= limit then
        data.Violations = data.Violations + 1

        -- Progressive penalties
        if data.Violations >= 20 then
            player:Kick("Excessive rate limit violations")
        elseif data.Violations >= 10 then
            -- 60 second penalty
            data.PenaltyUntil = now + 60
            warn(string.format("[RateLimit] %s penalized for 60s", player.Name))
        elseif data.Violations >= 5 then
            -- 10 second penalty
            data.PenaltyUntil = now + 10
            warn(string.format("[RateLimit] %s penalized for 10s", player.Name))
        end

        return false, 0
    end

    -- Allow request
    table.insert(data.Requests, now)

    -- Reset violations on good behavior
    if data.Violations > 0 and #data.Requests < self.MaxRequests * 0.5 then
        data.Violations = math.max(0, data.Violations - 1)
    end

    return true, remaining - 1
end

--[[
    Resets rate limit for a player
    @param player Player
]]
function RateLimiter:Reset(player: Player)
    PlayerLimits[player.UserId] = nil
end

-- Cleanup on player leave
game.Players.PlayerRemoving:Connect(function(player)
    PlayerLimits[player.UserId] = nil
end)

-- Usage Example:
--[[
local purchaseLimiter = RateLimiter.new(10, 60, 5) -- 10/min + 5 burst

RemoteEvents.Purchase.OnServerEvent:Connect(function(player, itemId)
    local allowed, remaining = purchaseLimiter:CheckLimit(player)

    if not allowed then
        -- Optionally notify client
        RemoteEvents.RateLimited:FireClient(player)
        return
    end

    -- Process purchase
    ShopService.Purchase(player, itemId)
end)
]]

return RateLimiter
```

---

## Anti-Cheat

### Comprehensive Anti-Cheat System

```lua
local AntiCheat = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player tracking
local PlayerData = {}
local ViolationLog = {}

-- Constants
local MAX_SPEED = 16 -- Default WalkSpeed
local TELEPORT_THRESHOLD = 100 -- studs
local FLY_TIME_THRESHOLD = 3 -- seconds airborne
local CHECK_INTERVAL = 0.5 -- seconds

--[[
    Initializes anti-cheat system
]]
function AntiCheat.Initialize()
    print("[AntiCheat] Initializing...")

    -- Track players
    Players.PlayerAdded:Connect(function(player)
        AntiCheat.InitializePlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        AntiCheat.CleanupPlayer(player)
    end)

    -- Start validation loop
    AntiCheat.StartValidationLoop()

    print("[AntiCheat] Initialized")
end

--[[
    Initializes tracking for a player
]]
function AntiCheat.InitializePlayer(player: Player)
    PlayerData[player.UserId] = {
        LastPosition = nil,
        LastUpdate = tick(),
        LastGroundContact = tick(),
        Violations = {
            Speed = 0,
            Teleport = 0,
            Fly = 0,
            NoClip = 0
        },
        MaxSpeed = MAX_SPEED,
        Exemptions = {} -- For special abilities
    }

    player.CharacterAdded:Connect(function(character)
        AntiCheat.OnCharacterAdded(player, character)
    end)

    ViolationLog[player.UserId] = {}
end

--[[
    Handles character spawning
]]
function AntiCheat.OnCharacterAdded(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local data = PlayerData[player.UserId]
    if not data then return end

    -- Update tracking
    data.LastPosition = rootPart.Position
    data.LastUpdate = tick()
    data.LastGroundContact = tick()
    data.MaxSpeed = humanoid.WalkSpeed

    -- Monitor humanoid state changes
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed or
           newState == Enum.HumanoidStateType.Running then
            data.LastGroundContact = tick()
        end
    end)
end

--[[
    Updates max allowed speed (for power-ups)
]]
function AntiCheat.SetPlayerMaxSpeed(player: Player, speed: number)
    local data = PlayerData[player.UserId]
    if data then
        data.MaxSpeed = speed
    end
end

--[[
    Grants exemption from specific checks
]]
function AntiCheat.GrantExemption(player: Player, checkType: string, duration: number)
    local data = PlayerData[player.UserId]
    if not data then return end

    data.Exemptions[checkType] = tick() + duration
end

--[[
    Main validation loop
]]
function AntiCheat.StartValidationLoop()
    task.spawn(function()
        while true do
            task.wait(CHECK_INTERVAL)

            pcall(function()
                AntiCheat.ValidateAllPlayers()
            end)
        end
    end)
end

--[[
    Validates all players
]]
function AntiCheat.ValidateAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not rootPart then continue end

        -- Run checks
        AntiCheat.CheckSpeed(player, humanoid, rootPart)
        AntiCheat.CheckTeleport(player, rootPart)
        AntiCheat.CheckFly(player, humanoid, rootPart)
        AntiCheat.CheckNoClip(player, rootPart)
    end
end

--[[
    Checks for speed hacking
]]
function AntiCheat.CheckSpeed(player: Player, humanoid: Humanoid, rootPart: BasePart)
    local data = PlayerData[player.UserId]
    if not data or not data.LastPosition then return end

    -- Check exemption
    if data.Exemptions.Speed and tick() < data.Exemptions.Speed then
        return
    end

    local now = tick()
    local deltaTime = now - data.LastUpdate

    if deltaTime < 0.1 then return end -- Too soon

    local distance = (rootPart.Position - data.LastPosition).Magnitude
    local speed = distance / deltaTime

    -- Calculate max allowed speed (with tolerance)
    local maxAllowed = data.MaxSpeed * 1.5

    if speed > maxAllowed then
        data.Violations.Speed = data.Violations.Speed + 1

        AntiCheat.LogViolation(player, "Speed", {
            Speed = speed,
            MaxAllowed = maxAllowed,
            Position = rootPart.Position
        })

        if data.Violations.Speed >= 3 then
            AntiCheat.PunishPlayer(player, "Speed hacking detected")
        else
            -- Teleport back
            rootPart.CFrame = CFrame.new(data.LastPosition)
        end
    end

    -- Update tracking
    data.LastPosition = rootPart.Position
    data.LastUpdate = now
end

--[[
    Checks for teleportation
]]
function AntiCheat.CheckTeleport(player: Player, rootPart: BasePart)
    local data = PlayerData[player.UserId]
    if not data or not data.LastPosition then return end

    -- Check exemption
    if data.Exemptions.Teleport and tick() < data.Exemptions.Teleport then
        return
    end

    local distance = (rootPart.Position - data.LastPosition).Magnitude
    local deltaTime = tick() - data.LastUpdate

    -- Instant large distance = teleport
    if distance > TELEPORT_THRESHOLD and deltaTime < 1 then
        data.Violations.Teleport = data.Violations.Teleport + 1

        AntiCheat.LogViolation(player, "Teleport", {
            Distance = distance,
            DeltaTime = deltaTime,
            Position = rootPart.Position
        })

        if data.Violations.Teleport >= 2 then
            AntiCheat.PunishPlayer(player, "Teleportation detected")
        else
            -- Teleport back
            rootPart.CFrame = CFrame.new(data.LastPosition)
        end
    end
end

--[[
    Checks for flying
]]
function AntiCheat.CheckFly(player: Player, humanoid: Humanoid, rootPart: BasePart)
    local data = PlayerData[player.UserId]
    if not data then return end

    -- Check exemption
    if data.Exemptions.Fly and tick() < data.Exemptions.Fly then
        return
    end

    -- Check if airborne too long
    local airborneTime = tick() - data.LastGroundContact

    if airborneTime > FLY_TIME_THRESHOLD and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        data.Violations.Fly = data.Violations.Fly + 1

        AntiCheat.LogViolation(player, "Fly", {
            AirborneTime = airborneTime,
            State = humanoid:GetState().Name,
            Position = rootPart.Position
        })

        if data.Violations.Fly >= 3 then
            AntiCheat.PunishPlayer(player, "Flying detected")
        end
    end
end

--[[
    Checks for noclip
]]
function AntiCheat.CheckNoClip(player: Player, rootPart: BasePart)
    -- Raycast downward to check for ground
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local rayResult = workspace:Raycast(
        rootPart.Position,
        Vector3.new(0, -10, 0),
        rayParams
    )

    -- Additional noclip detection logic here
end

--[[
    Logs a violation
]]
function AntiCheat.LogViolation(player: Player, violationType: string, details: {})
    local log = ViolationLog[player.UserId]
    if not log then return end

    table.insert(log, {
        Type = violationType,
        Details = details,
        Timestamp = os.time(),
        Tick = tick()
    })

    -- Limit log size
    while #log > 100 do
        table.remove(log, 1)
    end

    warn(string.format("[AntiCheat] %s violation by %s: %s",
        violationType,
        player.Name,
        game:GetService("HttpService"):JSONEncode(details)
    ))
end

--[[
    Punishes a player
]]
function AntiCheat.PunishPlayer(player: Player, reason: string)
    print(string.format("[AntiCheat] Kicking %s: %s", player.Name, reason))
    player:Kick(reason)
end

--[[
    Cleanup on player leave
]]
function AntiCheat.CleanupPlayer(player: Player)
    PlayerData[player.UserId] = nil
    ViolationLog[player.UserId] = nil
end

return AntiCheat
```

---

## Validation Utilities

### Comprehensive Input Validators

```lua
local Validators = {}

--[[
    Validates a string input
]]
function Validators.String(value: any, maxLength: number?, pattern: string?): string?
    if type(value) ~= "string" then
        return nil
    end

    if maxLength and #value > maxLength then
        return nil
    end

    -- Remove control characters
    value = value:gsub("%c", "")

    -- Check pattern if provided
    if pattern and not value:match(pattern) then
        return nil
    end

    return value
end

--[[
    Validates a number input
]]
function Validators.Number(value: any, min: number?, max: number?): number?
    if type(value) ~= "number" then
        return nil
    end

    -- NaN check
    if value ~= value then
        return nil
    end

    -- Infinity check
    if value == math.huge or value == -math.huge then
        return nil
    end

    -- Range check
    if min and value < min then
        return nil
    end

    if max and value > max then
        return nil
    end

    return value
end

--[[
    Validates an integer
]]
function Validators.Integer(value: any, min: number?, max: number?): number?
    local num = Validators.Number(value, min, max)
    if not num then return nil end

    return math.floor(num)
end

--[[
    Validates an enum value
]]
function Validators.Enum(value: any, validValues: {string}): string?
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

--[[
    Validates a Vector3
]]
function Validators.Vector3(value: any, maxMagnitude: number?): Vector3?
    if typeof(value) ~= "Vector3" then
        return nil
    end

    if maxMagnitude and value.Magnitude > maxMagnitude then
        return nil
    end

    -- Check for NaN
    if value.X ~= value.X or value.Y ~= value.Y or value.Z ~= value.Z then
        return nil
    end

    return value
end

--[[
    Validates a player is valid
]]
function Validators.Player(value: any): Player?
    if not value or not value:IsA("Player") then
        return nil
    end

    if not value:IsDescendantOf(game.Players) then
        return nil
    end

    return value
end

--[[
    Validates a UserId
]]
function Validators.UserId(value: any): number?
    local num = Validators.Integer(value, 1, 9999999999)
    return num
end

--[[
    Validates a table structure
]]
function Validators.Table(value: any, schema: {}): table?
    if type(value) ~= "table" then
        return nil
    end

    for key, validator in pairs(schema) do
        if not value[key] or not validator(value[key]) then
            return nil
        end
    end

    return value
end

return Validators
```

---

## Event Bus

### Decoupled Event System

```lua
local EventBus = {}

local Events = {}

--[[
    Subscribes to an event
    @param eventName string
    @param callback function
    @return function - Unsubscribe function
]]
function EventBus.Subscribe(eventName: string, callback: (any) -> nil)
    if not Events[eventName] then
        Events[eventName] = {}
    end

    table.insert(Events[eventName], callback)

    -- Return unsubscribe function
    return function()
        for i, cb in ipairs(Events[eventName]) do
            if cb == callback then
                table.remove(Events[eventName], i)
                break
            end
        end
    end
end

--[[
    Publishes an event
    @param eventName string
    @param data any
]]
function EventBus.Publish(eventName: string, data: any)
    if not Events[eventName] then
        return
    end

    for _, callback in ipairs(Events[eventName]) do
        task.spawn(function()
            pcall(callback, data)
        end)
    end
end

-- Usage Example:
--[[
-- Service A publishes
EventBus.Publish("PlayerLevelUp", {
    Player = player,
    NewLevel = 5,
    OldLevel = 4
})

-- Service B subscribes
EventBus.Subscribe("PlayerLevelUp", function(data)
    print(data.Player.Name .. " reached level " .. data.NewLevel)
end)
]]

return EventBus
```

---

## Object Pooling

### Efficient Instance Pooling

```lua
local ObjectPool = {}
ObjectPool.__index = ObjectPool

--[[
    Creates a new object pool
    @param template Instance - Template to clone
    @param initialSize number - Initial pool size
    @return ObjectPool
]]
function ObjectPool.new(template: Instance, initialSize: number)
    local self = setmetatable({}, ObjectPool)

    self.Template = template
    self.Available = {}
    self.InUse = {}

    -- Pre-populate pool
    for i = 1, initialSize do
        local object = template:Clone()
        object.Parent = nil
        table.insert(self.Available, object)
    end

    return self
end

--[[
    Gets an object from the pool
    @return Instance
]]
function ObjectPool:Get(): Instance
    local object

    if #self.Available > 0 then
        -- Reuse existing
        object = table.remove(self.Available)
    else
        -- Create new
        object = self.Template:Clone()
    end

    table.insert(self.InUse, object)
    return object
end

--[[
    Returns an object to the pool
    @param object Instance
]]
function ObjectPool:Return(object: Instance)
    -- Remove from in-use
    for i, obj in ipairs(self.InUse) do
        if obj == object then
            table.remove(self.InUse, i)
            break
        end
    end

    -- Reset and return to pool
    object.Parent = nil
    object:ClearAllChildren()

    table.insert(self.Available, object)
end

--[[
    Clears the entire pool
]]
function ObjectPool:Clear()
    for _, object in ipairs(self.Available) do
        object:Destroy()
    end

    for _, object in ipairs(self.InUse) do
        object:Destroy()
    end

    self.Available = {}
    self.InUse = {}
end

-- Usage Example:
--[[
local particleTemplate = Instance.new("Part")
particleTemplate.Size = Vector3.new(1, 1, 1)
particleTemplate.Anchored = true

local particlePool = ObjectPool.new(particleTemplate, 50)

-- Get particle
local particle = particlePool:Get()
particle.Position = Vector3.new(0, 10, 0)
particle.Parent = workspace

-- Return after use
task.wait(1)
particlePool:Return(particle)
]]

return ObjectPool
```

---

**Version:** 1.0
**Last Updated:** 2026-02-22
**Usage:** Copy templates and customize for your specific needs
