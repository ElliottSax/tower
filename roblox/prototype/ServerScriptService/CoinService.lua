--[[
	CoinService.lua
	Manages player currency (coins)

	Features:
	- Stores coins per player (in-memory, resets on server restart)
	- AddCoins / RemoveCoins / GetCoins API
	- RemoteEvents for client-server communication
	- Validates transactions server-side
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinService = {}

-- Store player coins (resets on server restart)
-- Format: { [UserId] = coinAmount }
local playerCoins = {}

-- Create RemoteEvents folder if it doesn't exist
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteEvents"
	remoteFolder.Parent = ReplicatedStorage
end

-- Create RemoteEvent for coin updates
local coinUpdateEvent = Instance.new("RemoteEvent")
coinUpdateEvent.Name = "CoinUpdate"
coinUpdateEvent.Parent = remoteFolder

-- Create RemoteFunction for getting coins
local getCoinFunction = Instance.new("RemoteFunction")
getCoinFunction.Name = "GetCoins"
getCoinFunction.Parent = remoteFolder

-- Initialize player
local function initializePlayer(player)
	playerCoins[player.UserId] = 0 -- Start with 0 coins
	print(string.format("[CoinService] Initialized %s with 0 coins", player.Name))

	-- Send initial coin count to client
	coinUpdateEvent:FireClient(player, 0)
end

-- Add coins to player
function CoinService.AddCoins(player, amount)
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in AddCoins")
		return false
	end

	if amount <= 0 then
		warn("[CoinService] Invalid coin amount:", amount)
		return false
	end

	-- Add coins
	playerCoins[player.UserId] = (playerCoins[player.UserId] or 0) + amount

	print(string.format(
		"[CoinService] Added %d coins to %s (Total: %d)",
		amount,
		player.Name,
		playerCoins[player.UserId]
	))

	-- Notify client
	coinUpdateEvent:FireClient(player, playerCoins[player.UserId])

	return true
end

-- Remove coins from player
function CoinService.RemoveCoins(player, amount)
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in RemoveCoins")
		return false
	end

	if amount <= 0 then
		warn("[CoinService] Invalid coin amount:", amount)
		return false
	end

	local currentCoins = playerCoins[player.UserId] or 0

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

	-- Remove coins
	playerCoins[player.UserId] = currentCoins - amount

	print(string.format(
		"[CoinService] Removed %d coins from %s (Remaining: %d)",
		amount,
		player.Name,
		playerCoins[player.UserId]
	))

	-- Notify client
	coinUpdateEvent:FireClient(player, playerCoins[player.UserId])

	return true
end

-- Get player's coin count
function CoinService.GetCoins(player)
	if not player or not player:IsA("Player") then
		warn("[CoinService] Invalid player in GetCoins")
		return 0
	end

	return playerCoins[player.UserId] or 0
end

-- Check if player can afford something
function CoinService.CanAfford(player, amount)
	local currentCoins = CoinService.GetCoins(player)
	return currentCoins >= amount
end

-- RemoteFunction callback for clients to get their coins
getCoinFunction.OnServerInvoke = function(player)
	return CoinService.GetCoins(player)
end

-- Player management
local function onPlayerAdded(player)
	initializePlayer(player)
end

local function onPlayerRemoving(player)
	playerCoins[player.UserId] = nil
	print(string.format("[CoinService] Cleaned up data for: %s", player.Name))
end

-- Initialize service
function CoinService.Init()
	print("[CoinService] Initializing...")

	-- Setup player management
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("[CoinService] Initialization complete!")
end

-- Auto-initialize
CoinService.Init()

return CoinService
