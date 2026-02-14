--[[
	ExampleService.lua
	Template service demonstrating all code review best practices

	This is a REFERENCE IMPLEMENTATION showing how to:
	✅ Use ServiceLocator instead of _G
	✅ Create secure RemoteEvents
	✅ Safe requires for optional dependencies
	✅ Input validation on all functions
	✅ Extract magic numbers to CONFIG
	✅ Use consistent naming conventions
	✅ Integrate with WebhookLogger

	Copy this template when creating new services!

	Created: 2025-12-17
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- SAFE REQUIRES (ALWAYS AT TOP)
-- ============================================================================

-- Required dependencies (will error if missing)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Optional dependencies (safe to fail)
local ServiceLocator = nil
local WebhookLogger = nil
local RemoteEventsInit = nil

pcall(function()
	ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)
	WebhookLogger = require(ServerScriptService.Utilities.WebhookLogger)
	RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
end)

local ExampleService = {}

-- ============================================================================
-- CONFIGURATION (EXTRACT ALL MAGIC NUMBERS HERE!)
-- ============================================================================

local CONFIG = {
	-- Feature settings
	MaxItemsPerPlayer = 100,
	ItemCostMultiplier = 1.5,
	RefreshInterval = 60, -- seconds

	-- Validation limits
	MaxStringLength = 256,
	MaxQuantity = 999,
	MinQuantity = 1,

	-- Rate limiting
	MaxPurchasesPerMinute = 10,
}

-- ============================================================================
-- STATE
-- ============================================================================

ExampleService.PlayerData = {} -- [UserId] = { items = {}, lastPurchase = tick() }
ExampleService.RemoteEvents = {}

-- ============================================================================
-- REMOTE EVENTS (USE SECURE WRAPPERS!)
-- ============================================================================

local function setupRemoteEvents()
	if not RemoteEventsInit then
		warn("[ExampleService] RemoteEventsInit not available")
		return
	end

	-- Get pre-initialized secure remote
	-- (Add this to RemoteEventsInit.lua first!)
	local purchaseItemRemote = RemoteEventsInit.GetRemote("PurchaseItem")
	if purchaseItemRemote then
		ExampleService.RemoteEvents.PurchaseItem = purchaseItemRemote

		-- Setup secure callback
		purchaseItemRemote:OnServerInvoke(function(player, itemId, quantity)
			return ExampleService.PurchaseItem(player, itemId, quantity)
		end)

		print("[ExampleService] RemoteEvents setup complete")
	else
		warn("[ExampleService] PurchaseItem remote not found - add to RemoteEventsInit!")
	end
end

-- ============================================================================
-- INPUT VALIDATION (CRITICAL!)
-- ============================================================================

local function validatePlayer(player: Player): boolean
	if not player or not player:IsA("Player") then
		warn("[ExampleService] Invalid player object")
		return false
	end
	return true
end

local function validateString(input: string, maxLength: number?): (boolean, string?)
	if type(input) ~= "string" then
		return false, "Not a string"
	end

	local limit = maxLength or CONFIG.MaxStringLength
	if #input > limit then
		return false, string.format("String too long (max %d)", limit)
	end

	-- Check for malicious content
	local SecurityManager = ServiceLocator and ServiceLocator.Get("SecurityManager")
	if SecurityManager and SecurityManager.SanitizeString then
		local sanitized = SecurityManager.SanitizeString(input)
		if not sanitized then
			return false, "Contains malicious content"
		end
	end

	return true, nil
end

local function validateNumber(input: number, min: number?, max: number?): (boolean, string?)
	if type(input) ~= "number" then
		return false, "Not a number"
	end

	-- Check for NaN and Infinity
	if input ~= input then
		return false, "Number is NaN"
	end

	if input == math.huge or input == -math.huge then
		return false, "Number is infinite"
	end

	-- Check range
	if min and input < min then
		return false, string.format("Below minimum (%d)", min)
	end

	if max and input > max then
		return false, string.format("Above maximum (%d)", max)
	end

	return true, nil
end

-- ============================================================================
-- CORE FUNCTIONALITY
-- ============================================================================

function ExampleService.PurchaseItem(player: Player, itemId: string, quantity: number): (boolean, string)
	-- 1. VALIDATE INPUTS
	if not validatePlayer(player) then
		return false, "Invalid player"
	end

	local validItemId, itemIdError = validateString(itemId, 64)
	if not validItemId then
		warn(string.format("[ExampleService] Invalid itemId from %s: %s", player.Name, itemIdError))
		return false, "Invalid item ID"
	end

	local validQuantity, quantityError = validateNumber(quantity, CONFIG.MinQuantity, CONFIG.MaxQuantity)
	if not validQuantity then
		warn(string.format("[ExampleService] Invalid quantity from %s: %s", player.Name, quantityError))
		return false, "Invalid quantity"
	end

	-- 2. RATE LIMITING (Check via ServiceLocator)
	local SecurityManager = ServiceLocator and ServiceLocator.Get("SecurityManager")
	if SecurityManager and SecurityManager.CheckRateLimit then
		if not SecurityManager.CheckRateLimit(player, "PurchaseItem") then
			warn(string.format("[ExampleService] Rate limit exceeded: %s", player.Name))

			-- Log to webhook
			if WebhookLogger then
				WebhookLogger.LogSecurityEvent("RATE_LIMIT_EXCEEDED", {
					Player = player.Name,
					UserId = player.UserId,
					Action = "PurchaseItem"
				})
			end

			return false, "Rate limit exceeded"
		end
	end

	-- 3. BUSINESS LOGIC
	local cost = math.floor(quantity * CONFIG.ItemCostMultiplier)

	-- Get DataService via ServiceLocator (NOT _G!)
	local DataService = ServiceLocator and ServiceLocator.Get("DataService")
	if not DataService then
		warn("[ExampleService] DataService not available")
		return false, "Service unavailable"
	end

	-- Check if player can afford
	local coins = DataService.GetCoins(player)
	if coins < cost then
		return false, string.format("Insufficient coins (need %d, have %d)", cost, coins)
	end

	-- Deduct coins
	local CoinService = ServiceLocator and ServiceLocator.Get("CoinService")
	if not CoinService then
		warn("[ExampleService] CoinService not available")
		return false, "Service unavailable"
	end

	local success = CoinService.RemoveCoins(player, cost, "PurchaseItem")
	if not success then
		return false, "Transaction failed"
	end

	-- Grant item
	ExampleService.GrantItem(player, itemId, quantity)

	-- 4. LOGGING
	print(string.format("[ExampleService] %s purchased %dx %s for %d coins",
		player.Name, quantity, itemId, cost))

	-- Log significant purchases to webhook
	if WebhookLogger and cost > 1000 then
		WebhookLogger.LogEvent(
			"💰 Large Purchase",
			string.format("%s purchased %dx %s", player.Name, quantity, itemId),
			"INFO",
			{
				{name = "Player", value = player.Name, inline = true},
				{name = "Item", value = itemId, inline = true},
				{name = "Quantity", value = tostring(quantity), inline = true},
				{name = "Cost", value = tostring(cost) .. " coins", inline = true}
			}
		)
	end

	return true, "Purchase successful"
end

function ExampleService.GrantItem(player: Player, itemId: string, quantity: number)
	if not validatePlayer(player) then
		return
	end

	local userId = player.UserId

	-- Initialize player data
	if not ExampleService.PlayerData[userId] then
		ExampleService.PlayerData[userId] = {
			items = {},
			lastPurchase = tick()
		}
	end

	local playerData = ExampleService.PlayerData[userId]

	-- Add item
	playerData.items[itemId] = (playerData.items[itemId] or 0) + quantity
	playerData.lastPurchase = tick()

	print(string.format("[ExampleService] Granted %dx %s to %s", quantity, itemId, player.Name))
end

-- ============================================================================
-- OPTIONAL SERVICE INTEGRATION
-- ============================================================================

function ExampleService.PlayPurchaseEffect(player: Player)
	-- Safe require pattern for optional services
	local success1, ParticleService = pcall(function()
		return require(ServerScriptService.Services.ParticleService)
	end)

	if success1 and ParticleService and ParticleService.SpawnParticle then
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			ParticleService.SpawnParticle("Purchase", character.HumanoidRootPart.Position, player)
		end
	end

	local success2, SoundService = pcall(function()
		return require(ServerScriptService.Services.SoundService)
	end)

	if success2 and SoundService and SoundService.PlaySound then
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			SoundService.PlaySound("Purchase", character.HumanoidRootPart.Position, player)
		end
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function ExampleService.OnPlayerAdded(player: Player)
	-- Initialize player data
	ExampleService.PlayerData[player.UserId] = {
		items = {},
		lastPurchase = 0
	}

	print(string.format("[ExampleService] Initialized player: %s", player.Name))
end

function ExampleService.OnPlayerRemoving(player: Player)
	-- Cleanup
	ExampleService.PlayerData[player.UserId] = nil

	print(string.format("[ExampleService] Cleaned up player: %s", player.Name))
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ExampleService.Initialize()
	print("[ExampleService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Player management
	Players.PlayerAdded:Connect(function(player)
		ExampleService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ExampleService.OnPlayerRemoving(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		ExampleService.OnPlayerAdded(player)
	end

	-- Register with ServiceLocator (LAST STEP!)
	if ServiceLocator then
		ServiceLocator.Register("ExampleService", ExampleService)
		print("[ExampleService] Registered with ServiceLocator")
	else
		warn("[ExampleService] ServiceLocator not available - service not registered")
	end

	print("[ExampleService] ✅ Initialized")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Export all public functions
-- Use PascalCase for public API
ExampleService.Init = ExampleService.Initialize

-- ============================================================================
-- EXPORT
-- ============================================================================

return ExampleService
