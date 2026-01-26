--[[
	UpgradeService.lua
	Manages player upgrades (double jump, speed boost, etc.)

	Features:
	- Purchase upgrades with coins
	- Validate purchases server-side
	- Track upgrade levels (some upgrades have multiple levels)
	- Integrate with CoinService and DataService
	- RemoteEvents for client requests

	Upgrades:
	- DoubleJump (1 level) - 100 coins
	- SpeedBoost (5 levels) - 150 coins/level
	- AirDash (1 level) - 250 coins
	- WallGrip (3 levels) - 200 coins/level

	Week 2: Full implementation
	Week 3+: Add more upgrades, skill trees
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

local UpgradeService = {}

-- ============================================================================
-- UPGRADE CATALOG
-- ============================================================================

UpgradeService.Upgrades = GameConfig.Upgrades

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

UpgradeService.RemoteEvents = {}

local function setupRemoteEvents()
	-- Use centralized RemoteEventsInit (single source of truth for all remotes)
	UpgradeService.RemoteEvents.PurchaseUpgrade = RemoteEventsInit.GetRemote("PurchaseUpgrade")
	UpgradeService.RemoteEvents.HasUpgrade = RemoteEventsInit.GetRemote("HasUpgrade")
	UpgradeService.RemoteEvents.GetUpgradeLevel = RemoteEventsInit.GetRemote("GetUpgradeLevel")
	UpgradeService.RemoteEvents.GetAllUpgrades = RemoteEventsInit.GetRemote("GetAllUpgrades")
	UpgradeService.RemoteEvents.GetUpgradeCost = RemoteEventsInit.GetRemote("GetUpgradeCost")

	-- Setup callbacks using SecureRemotes API
	local purchaseRemote = UpgradeService.RemoteEvents.PurchaseUpgrade
	if purchaseRemote and purchaseRemote.Remote then
		purchaseRemote.Remote.OnServerEvent:Connect(function(player, upgradeName)
			UpgradeService.OnPurchaseRequest(player, upgradeName)
		end)
	end

	local hasUpgradeRemote = UpgradeService.RemoteEvents.HasUpgrade
	if hasUpgradeRemote and hasUpgradeRemote.OnServerInvoke then
		hasUpgradeRemote:OnServerInvoke(function(player, upgradeName)
			return UpgradeService.HasUpgrade(player, upgradeName)
		end)
	end

	local getUpgradeLevelRemote = UpgradeService.RemoteEvents.GetUpgradeLevel
	if getUpgradeLevelRemote and getUpgradeLevelRemote.OnServerInvoke then
		getUpgradeLevelRemote:OnServerInvoke(function(player, upgradeName)
			return UpgradeService.GetUpgradeLevel(player, upgradeName)
		end)
	end

	local getAllUpgradesRemote = UpgradeService.RemoteEvents.GetAllUpgrades
	if getAllUpgradesRemote and getAllUpgradesRemote.OnServerInvoke then
		getAllUpgradesRemote:OnServerInvoke(function(player)
			return UpgradeService.GetAllUpgrades(player)
		end)
	end

	local getUpgradeCostRemote = UpgradeService.RemoteEvents.GetUpgradeCost
	if getUpgradeCostRemote and getUpgradeCostRemote.OnServerInvoke then
		getUpgradeCostRemote:OnServerInvoke(function(player, upgradeName, level)
			-- Validate inputs
			if type(upgradeName) ~= "string" then
				return 0
			end
			if level ~= nil and type(level) ~= "number" then
				return 0
			end
			return UpgradeService.GetUpgradeCost(upgradeName, level)
		end)
	end

	print("[UpgradeService] RemoteEvents setup complete (using RemoteEventsInit)")
end

-- ============================================================================
-- UPGRADE OPERATIONS
-- ============================================================================

function UpgradeService.PurchaseUpgrade(player: Player, upgradeName: string): (boolean, string)
	if not player or not player:IsA("Player") then
		return false, "Invalid player"
	end

	-- Validate upgrade exists
	local upgradeData = UpgradeService.Upgrades[upgradeName]
	if not upgradeData then
		warn(string.format("[UpgradeService] Unknown upgrade: %s", upgradeName))
		return false, "Unknown upgrade"
	end

	-- Get current level
	local DataService = require(script.Parent.DataService)
	local currentLevel = DataService.GetUpgradeLevel(player, upgradeName)

	-- Check if already at max level
	if currentLevel >= upgradeData.MaxLevel then
		print(string.format(
			"[UpgradeService] %s already has max level of %s",
			player.Name,
			upgradeName
		))
		return false, "Already at max level"
	end

	-- Get cost (some upgrades have level-based costs)
	local cost = UpgradeService.GetUpgradeCost(upgradeName, currentLevel + 1)

	-- Check if player can afford
	local CoinService = require(script.Parent.CoinService)
	if not CoinService.CanAfford(player, cost) then
		print(string.format(
			"[UpgradeService] %s cannot afford %s (Cost: %d, Has: %d)",
			player.Name,
			upgradeName,
			cost,
			CoinService.GetCoins(player)
		))
		return false, "Insufficient coins"
	end

	-- Remove coins
	local success = CoinService.RemoveCoins(player, cost, "Upgrade: " .. upgradeName)
	if not success then
		warn("[UpgradeService] Failed to remove coins from", player.Name)
		return false, "Transaction failed"
	end

	-- Grant upgrade
	local newLevel = currentLevel + 1
	DataService.GrantUpgrade(player, upgradeName, newLevel)

	-- Visual & audio feedback (Week 4)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		-- Safe require with pcall (services may not be loaded)
		local success1, ParticleService = pcall(function()
			return require(script.Parent.ParticleService)
		end)
		if success1 and ParticleService and ParticleService.SpawnParticle then
			ParticleService.SpawnParticle("UpgradePurchased", character.HumanoidRootPart.Position, player)
		end

		local success2, SoundService = pcall(function()
			return require(script.Parent.SoundService)
		end)
		if success2 and SoundService and SoundService.PlaySound then
			SoundService.PlaySound("UpgradePurchased", character.HumanoidRootPart.Position, player)
		end
	end

	print(string.format(
		"[UpgradeService] %s purchased %s level %d for %d coins",
		player.Name,
		upgradeName,
		newLevel,
		cost
	))

	return true, "Purchase successful"
end

function UpgradeService.OnPurchaseRequest(player: Player, upgradeName: string)
	local success, message = UpgradeService.PurchaseUpgrade(player, upgradeName)

	-- Send result to client using SecureRemotes API
	local purchaseRemote = UpgradeService.RemoteEvents.PurchaseUpgrade
	if purchaseRemote and purchaseRemote.Remote then
		purchaseRemote.Remote:FireClient(player, success, message, upgradeName)
	end
end

function UpgradeService.HasUpgrade(player: Player, upgradeName: string): boolean
	if not player or not player:IsA("Player") then
		return false
	end

	local DataService = require(script.Parent.DataService)
	return DataService.HasUpgrade(player, upgradeName)
end

function UpgradeService.GetUpgradeLevel(player: Player, upgradeName: string): number
	if not player or not player:IsA("Player") then
		return 0
	end

	local DataService = require(script.Parent.DataService)
	return DataService.GetUpgradeLevel(player, upgradeName)
end

function UpgradeService.GetAllUpgrades(player: Player): {}
	if not player or not player:IsA("Player") then
		return {}
	end

	local DataService = require(script.Parent.DataService)
	local profile = DataService.GetProfile(player)

	if profile and profile.Data then
		return profile.Data.Upgrades
	end

	return {}
end

-- ============================================================================
-- UPGRADE COST CALCULATION
-- ============================================================================

function UpgradeService.GetUpgradeCost(upgradeName: string, level: number?): number
	local upgradeData = UpgradeService.Upgrades[upgradeName]
	if not upgradeData then
		return 0
	end

	local targetLevel = level or 1

	-- Some upgrades have flat cost, others scale with level
	if upgradeName == "SpeedBoost" then
		-- SpeedBoost costs more per level: 150, 300, 450, 600, 750
		return upgradeData.Cost * targetLevel
	elseif upgradeName == "WallGrip" then
		-- WallGrip costs more per level: 200, 400, 600
		return upgradeData.Cost * targetLevel
	else
		-- Flat cost (DoubleJump, AirDash)
		return upgradeData.Cost
	end
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function UpgradeService.AdminGrantUpgrade(player: Player, upgradeName: string, level: number?): boolean
	if not player or not player:IsA("Player") then
		return false
	end

	local upgradeData = UpgradeService.Upgrades[upgradeName]
	if not upgradeData then
		return false
	end

	local targetLevel = level or upgradeData.MaxLevel

	local DataService = require(script.Parent.DataService)
	return DataService.GrantUpgrade(player, upgradeName, targetLevel)
end

function UpgradeService.AdminResetUpgrades(player: Player): boolean
	if not player or not player:IsA("Player") then
		return false
	end

	local DataService = require(script.Parent.DataService)
	local profile = DataService.GetProfile(player)

	if profile and profile.Data then
		-- Reset all upgrades to 0
		for upgradeName, _ in pairs(UpgradeService.Upgrades) do
			profile.Data.Upgrades[upgradeName] = 0
		end
		return true
	end

	return false
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function UpgradeService.Init()
	print("[UpgradeService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Log available upgrades
	print("[UpgradeService] Available upgrades:")
	for name, data in pairs(UpgradeService.Upgrades) do
		print(string.format(
			"  - %s (Cost: %d, Max Level: %d): %s",
			data.Name,
			data.Cost,
			data.MaxLevel,
			data.Description
		))
	end

	print("[UpgradeService] Initialized")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return UpgradeService
