--[[
	CoinService.lua
	Manages player currency (coins)

	Features:
	- Add/remove coins (server-authoritative)
	- Integrates with DataService for persistence
	- RemoteEvents for client UI updates
	- Transaction validation
	- Coin source tracking (analytics)
	- Max coin limit enforcement

	Architecture:
	- Server stores coins in DataService (permanent via ProfileService)
	- Client receives updates via RemoteEvent
	- All transactions validated server-side

	Week 2: Full implementation
	Week 3: Add transaction history, analytics
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
local ServiceLocator = require(ServerScriptService.Utilities.ServiceLocator)

local CoinService = {}

-- ============================================================================
-- REMOTE EVENTS (SECURE)
-- ============================================================================

CoinService.RemoteEvents = {}

local function setupRemoteEvents()
	-- Get pre-initialized secure remotes
	CoinService.RemoteEvents.CoinUpdate = RemoteEventsInit.GetRemote("CoinUpdate")
	CoinService.RemoteEvents.GetCoins = RemoteEventsInit.GetRemote("GetCoins")

	-- Setup secure callback for GetCoins
	CoinService.RemoteEvents.GetCoins:OnServerInvoke(function(player)
		return CoinService.GetCoins(player)
	end)

	print("[CoinService] RemoteEvents setup complete (using SecureRemotes)")
end

-- ============================================================================
-- COIN OPERATIONS
-- ============================================================================

function CoinService.AddCoins(player: Player, amount: number, source: string?): boolean
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in AddCoins")
		return false
	end

	if amount <= 0 then
		warn("[CoinService] Invalid amount in AddCoins:", amount)
		return false
	end

	-- Get DataService early to check max coins
	local DataService = require(script.Parent.DataService)
	local currentCoins = DataService.GetCoins(player)

	-- Early return if already at max (better UX)
	if currentCoins >= GameConfig.Progression.MaxCoins then
		warn(string.format(
			"[CoinService] %s already at max coins (%d)",
			player.Name,
			GameConfig.Progression.MaxCoins
		))
		return false
	end

	-- Calculate space remaining for coins
	local spaceRemaining = GameConfig.Progression.MaxCoins - currentCoins

	-- WEEK 12: Apply VIP multiplier (2x coins for VIP players)
	-- Use pcall to safely handle VIPService in case it's not initialized
	local success, VIPService = pcall(function()
		return require(script.Parent.Monetization.VIPService)
	end)

	local multiplier = 1
	if success and VIPService and VIPService.GetCoinMultiplier then
		multiplier = VIPService.GetCoinMultiplier(player)

		-- SECURITY: Validate multiplier is reasonable (prevent malicious VIPService)
		if type(multiplier) ~= "number" or multiplier ~= multiplier then
			warn("[CoinService] Invalid multiplier from VIPService:", multiplier)
			multiplier = 1
		end

		-- Clamp multiplier to reasonable range (1x to 10x)
		multiplier = math.clamp(multiplier, 1, 10)
	end

	-- Apply multiplier and clamp to space remaining
	local baseAmount = amount
	amount = math.floor(baseAmount * multiplier)
	amount = math.min(amount, spaceRemaining) -- Clamp to available space

	-- Log VIP bonus if multiplier was applied
	if multiplier > 1 then
		print(string.format(
			"[CoinService] VIP bonus: %s earned %d coins (base %d × %.1fx, clamped to space: %d)",
			player.Name,
			amount,
			baseAmount,
			multiplier,
			spaceRemaining
		))
	end

	-- Add coins via DataService
	local success = DataService.AddCoins(player, amount)

	if success then
		-- Recalculate actual total after successful add (in case of rounding)
		local actualNewTotal = DataService.GetCoins(player)

		print(string.format(
			"[CoinService] Added %d coins to %s (Source: %s, Total: %d)",
			amount,
			player.Name,
			source or "Unknown",
			actualNewTotal
		))

		-- Notify client with actual total
		CoinService.RemoteEvents.CoinUpdate.Remote:FireClient(player, actualNewTotal, amount, "add")

		-- Track source (for analytics)
		if source then
			CoinService.TrackCoinSource(player, source, amount)
		end

		-- Visual & audio feedback for larger coin gains (Week 4)
		if amount >= 10 then
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				-- Safe require of optional services
				local success, ParticleService = pcall(function()
					return require(script.Parent.ParticleService)
				end)
				if success and ParticleService and ParticleService.SpawnParticle then
					ParticleService.SpawnParticle("CoinPickup", character.HumanoidRootPart.Position, player)
				end

				local success2, SoundService = pcall(function()
					return require(script.Parent.SoundService)
				end)
				if success2 and SoundService and SoundService.PlaySound then
					SoundService.PlaySound("CoinPickup", character.HumanoidRootPart.Position, player)
				end
			end
		end

		return true
	end

	return false
end

function CoinService.RemoveCoins(player: Player, amount: number, reason: string?): boolean
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in RemoveCoins")
		return false
	end

	if amount <= 0 then
		warn("[CoinService] Invalid amount in RemoveCoins:", amount)
		return false
	end

	-- Get DataService
	local DataService = require(script.Parent.DataService)
	local currentCoins = DataService.GetCoins(player)

	-- Check if player has enough coins
	if currentCoins < amount then
		warn(string.format(
			"[CoinService] %s doesn't have enough coins (Has: %d, Needs: %d)",
			player.Name,
			currentCoins,
			amount
		))
		return false
	end

	-- Remove coins via DataService
	local success = DataService.RemoveCoins(player, amount)

	if success then
		local newTotal = currentCoins - amount

		print(string.format(
			"[CoinService] Removed %d coins from %s (Reason: %s, Remaining: %d)",
			amount,
			player.Name,
			reason or "Unknown",
			newTotal
		))

		-- Notify client
		CoinService.RemoteEvents.CoinUpdate.Remote:FireClient(player, newTotal, amount, "remove")

		return true
	end

	return false
end

function CoinService.GetCoins(player: Player): number
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in GetCoins")
		return 0
	end

	local DataService = require(script.Parent.DataService)
	return DataService.GetCoins(player)
end

function CoinService.SetCoins(player: Player, amount: number): boolean
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in SetCoins")
		return false
	end

	if amount < 0 then
		warn("[CoinService] Invalid amount in SetCoins:", amount)
		return false
	end

	-- Clamp to max
	if amount > GameConfig.Progression.MaxCoins then
		amount = GameConfig.Progression.MaxCoins
	end

	local DataService = require(script.Parent.DataService)
	local currentCoins = DataService.GetCoins(player)

	if amount > currentCoins then
		-- Add difference
		return CoinService.AddCoins(player, amount - currentCoins, "SetCoins")
	elseif amount < currentCoins then
		-- Remove difference
		return CoinService.RemoveCoins(player, currentCoins - amount, "SetCoins")
	end

	return true -- No change needed
end

function CoinService.CanAfford(player: Player, amount: number): boolean
	local currentCoins = CoinService.GetCoins(player)
	return currentCoins >= amount
end

-- ============================================================================
-- COIN SOURCE TRACKING (ANALYTICS)
-- ============================================================================

CoinService.CoinSources = {}

function CoinService.TrackCoinSource(player: Player, source: string, amount: number)
	-- Track for analytics (Week 3+)
	local userId = player.UserId

	if not CoinService.CoinSources[userId] then
		CoinService.CoinSources[userId] = {}
	end

	if not CoinService.CoinSources[userId][source] then
		CoinService.CoinSources[userId][source] = {
			totalCoins = 0,
			transactionCount = 0,
		}
	end

	local sourceData = CoinService.CoinSources[userId][source]
	sourceData.totalCoins = sourceData.totalCoins + amount
	sourceData.transactionCount = sourceData.transactionCount + 1
end

function CoinService.GetCoinSourceStats(player: Player): {}
	return CoinService.CoinSources[player.UserId] or {}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function CoinService.OnPlayerAdded(player: Player)
	-- Sync initial coins to client
	task.wait(1) -- Wait for DataService to load profile

	local coins = CoinService.GetCoins(player)
	CoinService.RemoteEvents.CoinUpdate.Remote:FireClient(player, coins, 0, "init")

	print(string.format("[CoinService] Synced %d coins to %s", coins, player.Name))
end

function CoinService.OnPlayerRemoving(player: Player)
	-- Cleanup analytics data
	CoinService.CoinSources[player.UserId] = nil
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function CoinService.Init()
	print("[CoinService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Player management
	Players.PlayerAdded:Connect(function(player)
		CoinService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CoinService.OnPlayerRemoving(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(CoinService.OnPlayerAdded, player)
	end

	print("[CoinService] Initialized")
end

-- ============================================================================
-- TESTING UTILITIES
-- ============================================================================

function CoinService.AdminAddCoins(player: Player, amount: number)
	-- Admin command for testing
	return CoinService.AddCoins(player, amount, "Admin")
end

function CoinService.AdminSetCoins(player: Player, amount: number)
	-- Admin command for testing
	return CoinService.SetCoins(player, amount)
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return CoinService
