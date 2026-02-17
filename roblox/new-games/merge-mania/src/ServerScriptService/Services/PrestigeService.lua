--[[
	PrestigeService.lua - Merge Mania
	Rebirth/Prestige system - reset grid and generators for permanent multipliers

	Prestige resets: Grid, Generators, Coins, Unlocked Paths (except Weapons)
	Prestige keeps: Collections, Highest Tiers, Game Passes, Prestige Rewards, Settings
	Each prestige level grants +30% earnings permanently.
	Specific prestige milestones unlock new generators, features, and bonuses.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PrestigeService = {}
PrestigeService.DataService = nil
PrestigeService.MergeService = nil
PrestigeService.EarningsService = nil
PrestigeService.GeneratorService = nil
PrestigeService.SecurityManager = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PrestigeService.Init()
	print("[PrestigeService] Initializing...")

	PrestigeService.DataService = require(ServerScriptService.Services.DataService)
	PrestigeService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	PrestigeService.SetupRemotes()

	print("[PrestigeService] Initialized")
end

function PrestigeService.LateInit()
	PrestigeService.MergeService = require(ServerScriptService.Services.MergeService)
	PrestigeService.EarningsService = require(ServerScriptService.Services.EarningsService)
	PrestigeService.GeneratorService = require(ServerScriptService.Services.GeneratorService)
end

function PrestigeService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("Prestige").OnServerEvent:Connect(function(player)
		local allowed = PrestigeService.SecurityManager.CheckRateLimit(player, "Prestige")
		if not allowed then return end

		PrestigeService.DoPrestige(player)
	end)

	remoteEvents:WaitForChild("GetPrestigeInfo").OnServerEvent:Connect(function(player)
		PrestigeService.SendPrestigeInfo(player)
	end)
end

-- ============================================================================
-- PRESTIGE EXECUTION
-- ============================================================================

function PrestigeService.DoPrestige(player)
	local data = PrestigeService.DataService.GetFullData(player)
	if not data then return false, "No data" end

	local currentLevel = data.PrestigeLevel or 0
	if currentLevel >= GameConfig.Prestige.MaxLevel then
		PrestigeService.Notify(player, "Max prestige level reached!", GameConfig.Theme.WarningColor)
		return false, "Max prestige"
	end

	-- Check coin requirement (scales with level)
	local requiredCoins = PrestigeService.GetRequiredCoins(currentLevel)
	if data.Coins < requiredCoins then
		PrestigeService.Notify(player,
			"Need " .. GameConfig.FormatNumber(requiredCoins) .. " coins to prestige!",
			GameConfig.Theme.ErrorColor
		)
		return false, "Not enough coins"
	end

	-- === PERFORM PRESTIGE ===
	local newLevel = currentLevel + 1

	-- RESET: Coins
	data.Coins = 500 -- Starting coins

	-- RESET: Grid
	data.Grid = {}

	-- RESET: Generators
	data.OwnedGenerators = {}

	-- RESET: Unlocked paths (keep only Weapons)
	data.UnlockedPaths = { "Weapons" }

	-- KEEP: Collections, HighestTiers, _DiscoveredTiers
	-- KEEP: GamePasses, Settings
	-- KEEP: DailyRewards state
	-- KEEP: Statistics (TotalMerges, etc.)

	-- INCREMENT: Prestige level
	data.PrestigeLevel = newLevel
	data.TotalPrestiges = (data.TotalPrestiges or 0) + 1

	-- Clear active boosts (they don't persist through prestige)
	data.ActiveBoosts = {}

	-- Reset offline tracking
	data.LastOnlineTime = os.time()
	data.OfflineEarningsCollected = true

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then coinsValue.Value = data.Coins end
		local prestigeValue = leaderstats:FindFirstChild("Prestige")
		if prestigeValue then prestigeValue.Value = newLevel end
	end

	-- Reset service states
	if PrestigeService.MergeService then
		PrestigeService.MergeService.SetupPlayer(player)
	end
	if PrestigeService.GeneratorService then
		PrestigeService.GeneratorService.SetupPlayer(player)
	end
	if PrestigeService.EarningsService then
		PrestigeService.EarningsService.RecalculateEarnings(player)
	end

	-- Get prestige reward (if any)
	local reward = GameConfig.Prestige.Rewards[newLevel]

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local prestigeComplete = remoteEvents:FindFirstChild("PrestigeComplete")
		if prestigeComplete then
			prestigeComplete:FireClient(player, {
				NewLevel = newLevel,
				Multiplier = 1 + (newLevel * GameConfig.Prestige.Multiplier),
				RequiredForNext = newLevel < GameConfig.Prestige.MaxLevel and PrestigeService.GetRequiredCoins(newLevel) or nil,
				Reward = reward,
			})
		end
	end

	print("[PrestigeService]", player.Name, "prestiged to level", newLevel,
		"| New multiplier:", string.format("%.1fx", 1 + newLevel * GameConfig.Prestige.Multiplier))

	return true
end

-- ============================================================================
-- PRESTIGE INFO
-- ============================================================================

function PrestigeService.SendPrestigeInfo(player)
	local data = PrestigeService.DataService.GetFullData(player)
	if not data then return end

	local currentLevel = data.PrestigeLevel or 0
	local requiredCoins = PrestigeService.GetRequiredCoins(currentLevel)

	-- Build rewards list with unlock status
	local rewards = {}
	for level, reward in pairs(GameConfig.Prestige.Rewards) do
		rewards[level] = {
			Level = level,
			Type = reward.Type,
			Name = reward.Name,
			Description = reward.Description,
			Unlocked = currentLevel >= level,
		}
	end

	local info = {
		CurrentLevel = currentLevel,
		MaxLevel = GameConfig.Prestige.MaxLevel,
		CurrentMultiplier = 1 + (currentLevel * GameConfig.Prestige.Multiplier),
		NextMultiplier = 1 + ((currentLevel + 1) * GameConfig.Prestige.Multiplier),
		RequiredCoins = math.floor(requiredCoins),
		CurrentCoins = data.Coins,
		CanPrestige = data.Coins >= requiredCoins and currentLevel < GameConfig.Prestige.MaxLevel,
		Rewards = rewards,
		TotalPrestiges = data.TotalPrestiges or 0,
	}

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local prestigeInfo = remoteEvents:FindFirstChild("PrestigeInfo")
		if prestigeInfo then
			prestigeInfo:FireClient(player, info)
		end
	end
end

-- ============================================================================
-- HELPERS
-- ============================================================================

function PrestigeService.GetRequiredCoins(currentLevel)
	return math.floor(GameConfig.Prestige.RequiredCoins * math.pow(GameConfig.Prestige.ScalingFactor, currentLevel))
end

function PrestigeService.Notify(player, text, color)
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local notif = remoteEvents:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Text = text, Color = color })
		end
	end
end

return PrestigeService
