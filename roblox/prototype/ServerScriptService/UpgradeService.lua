--[[
	UpgradeService.lua
	Manages player upgrades (currently: double jump)

	Features:
	- Tracks which players own upgrades
	- Handles purchase requests
	- Validates with CoinService
	- Persists upgrades across respawns (within same session)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeService = {}

-- Get services
local CoinService = require(script.Parent.CoinService)

-- Upgrade catalog
local UPGRADES = {
	DoubleJump = {
		name = "Double Jump",
		description = "Jump again in mid-air!",
		cost = 100, -- coins
		icon = "rbxassetid://0" -- Placeholder
	}
}

-- Store player upgrades (resets on server restart)
-- Format: { [UserId] = { DoubleJump = true, ... } }
local playerUpgrades = {}

-- Create RemoteEvents folder if it doesn't exist
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteEvents"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvent for purchase requests
local purchaseUpgradeEvent = Instance.new("RemoteEvent")
purchaseUpgradeEvent.Name = "PurchaseUpgrade"
purchaseUpgradeEvent.Parent = remoteFolder

-- Create RemoteFunction for checking upgrade ownership
local hasUpgradeFunction = Instance.new("RemoteFunction")
hasUpgradeFunction.Name = "HasUpgrade"
hasUpgradeFunction.Parent = remoteFolder

-- Create RemoteFunction for getting all owned upgrades
local getUpgradesFunction = Instance.new("RemoteFunction")
getUpgradesFunction.Name = "GetUpgrades"
getUpgradesFunction.Parent = remoteFolder

-- Initialize player
local function initializePlayer(player)
	playerUpgrades[player.UserId] = {}
	print(string.format("[UpgradeService] Initialized %s with no upgrades", player.Name))
end

-- Check if player owns upgrade
function UpgradeService.HasUpgrade(player, upgradeName)
	if not player or not player:IsA("Player") then
		warn("[UpgradeService] Invalid player in HasUpgrade")
		return false
	end

	local upgrades = playerUpgrades[player.UserId]
	return upgrades and upgrades[upgradeName] == true
end

-- Grant upgrade to player
function UpgradeService.GrantUpgrade(player, upgradeName)
	if not player or not player:IsA("Player") then
		warn("[UpgradeService] Invalid player in GrantUpgrade")
		return false
	end

	if not UPGRADES[upgradeName] then
		warn("[UpgradeService] Unknown upgrade:", upgradeName)
		return false
	end

	-- Grant upgrade
	if not playerUpgrades[player.UserId] then
		playerUpgrades[player.UserId] = {}
	end

	playerUpgrades[player.UserId][upgradeName] = true

	print(string.format(
		"[UpgradeService] Granted %s to %s",
		upgradeName,
		player.Name
	))

	return true
end

-- Purchase upgrade
function UpgradeService.PurchaseUpgrade(player, upgradeName)
	if not player or not player:IsA("Player") then
		warn("[UpgradeService] Invalid player in PurchaseUpgrade")
		return false, "Invalid player"
	end

	-- Check if upgrade exists
	local upgradeData = UPGRADES[upgradeName]
	if not upgradeData then
		warn("[UpgradeService] Unknown upgrade:", upgradeName)
		return false, "Unknown upgrade"
	end

	-- Check if already owned
	if UpgradeService.HasUpgrade(player, upgradeName) then
		print(string.format(
			"[UpgradeService] %s already owns %s",
			player.Name,
			upgradeName
		))
		return false, "Already owned"
	end

	-- Check if player can afford
	if not CoinService.CanAfford(player, upgradeData.cost) then
		print(string.format(
			"[UpgradeService] %s cannot afford %s (Cost: %d)",
			player.Name,
			upgradeName,
			upgradeData.cost
		))
		return false, "Insufficient coins"
	end

	-- Deduct coins
	local success = CoinService.RemoveCoins(player, upgradeData.cost)
	if not success then
		warn("[UpgradeService] Failed to remove coins from", player.Name)
		return false, "Transaction failed"
	end

	-- Grant upgrade
	UpgradeService.GrantUpgrade(player, upgradeName)

	print(string.format(
		"[UpgradeService] %s purchased %s for %d coins",
		player.Name,
		upgradeName,
		upgradeData.cost
	))

	return true, "Purchase successful"
end

-- Get all player upgrades
function UpgradeService.GetPlayerUpgrades(player)
	if not player or not player:IsA("Player") then
		warn("[UpgradeService] Invalid player in GetPlayerUpgrades")
		return {}
	end

	return playerUpgrades[player.UserId] or {}
end

-- Get upgrade catalog
function UpgradeService.GetCatalog()
	return UPGRADES
end

-- RemoteEvent: Handle purchase requests
purchaseUpgradeEvent.OnServerEvent:Connect(function(player, upgradeName)
	local success, message = UpgradeService.PurchaseUpgrade(player, upgradeName)

	-- Send result back to client
	purchaseUpgradeEvent:FireClient(player, success, message, upgradeName)
end)

-- RemoteFunction: Check upgrade ownership
hasUpgradeFunction.OnServerInvoke = function(player, upgradeName)
	return UpgradeService.HasUpgrade(player, upgradeName)
end

-- RemoteFunction: Get all owned upgrades
getUpgradesFunction.OnServerInvoke = function(player)
	return UpgradeService.GetPlayerUpgrades(player)
end

-- Player management
local function onPlayerAdded(player)
	initializePlayer(player)
end

local function onPlayerRemoving(player)
	playerUpgrades[player.UserId] = nil
	print(string.format("[UpgradeService] Cleaned up data for: %s", player.Name))
end

-- Initialize service
function UpgradeService.Init()
	print("[UpgradeService] Initializing...")

	-- Setup player management
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("[UpgradeService] Initialization complete!")
	print("[UpgradeService] Available upgrades:")
	for name, data in pairs(UPGRADES) do
		print(string.format("  - %s (%d coins): %s", data.name, data.cost, data.description))
	end
end

-- Auto-initialize
UpgradeService.Init()

return UpgradeService
