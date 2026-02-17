--[[
	LeaderboardService.lua - Grow a World
	Global leaderboards using OrderedDataStores
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local LeaderboardService = {}
LeaderboardService.DataService = nil
LeaderboardService.Stores = {}
LeaderboardService.CachedBoards = {}

local LEADERBOARD_NAMES = {
	"TotalCoinsEarned",
	"PlantsHarvested",
	"PrestigeLevel",
}

local UPDATE_INTERVAL = 120 -- seconds
local MAX_ENTRIES = 50

function LeaderboardService.Init()
	print("[LeaderboardService] Initializing...")
	LeaderboardService.DataService = require(ServerScriptService.Services.DataService)

	for _, name in ipairs(LEADERBOARD_NAMES) do
		LeaderboardService.Stores[name] = DataStoreService:GetOrderedDataStore("LB_" .. name)
		LeaderboardService.CachedBoards[name] = {}
	end

	LeaderboardService.SetupRemotes()
	LeaderboardService.StartUpdateLoop()
	print("[LeaderboardService] Initialized with", #LEADERBOARD_NAMES, "leaderboards")
end

function LeaderboardService.SetupRemotes()
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player, boardName)
		LeaderboardService.SendLeaderboard(player, boardName)
	end)
end

function LeaderboardService.UpdatePlayer(player)
	local data = LeaderboardService.DataService.GetFullData(player)
	if not data then return end

	for _, name in ipairs(LEADERBOARD_NAMES) do
		local value = data[name]
		if value and type(value) == "number" and value > 0 then
			local store = LeaderboardService.Stores[name]
			if store then
				pcall(function()
					store:SetAsync(tostring(player.UserId), math.floor(value))
				end)
			end
		end
	end
end

function LeaderboardService.FetchLeaderboard(boardName)
	local store = LeaderboardService.Stores[boardName]
	if not store then return {} end

	local success, pages = pcall(function()
		return store:GetSortedAsync(false, MAX_ENTRIES)
	end)

	if not success or not pages then return {} end

	local entries = {}
	local data = pages:GetCurrentPage()

	for rank, entry in ipairs(data) do
		local userId = tonumber(entry.key)
		local value = entry.value
		local playerName = "[Unknown]"

		pcall(function()
			playerName = Players:GetNameFromUserIdAsync(userId)
		end)

		table.insert(entries, {
			Rank = rank,
			UserId = userId,
			Name = playerName,
			Value = value,
		})
	end

	return entries
end

function LeaderboardService.StartUpdateLoop()
	task.spawn(function()
		while true do
			-- Update all player scores
			for _, player in ipairs(Players:GetPlayers()) do
				LeaderboardService.UpdatePlayer(player)
			end

			-- Fetch fresh leaderboard data
			for _, name in ipairs(LEADERBOARD_NAMES) do
				LeaderboardService.CachedBoards[name] = LeaderboardService.FetchLeaderboard(name)
			end

			task.wait(UPDATE_INTERVAL)
		end
	end)
end

function LeaderboardService.SendLeaderboard(player, boardName)
	local entries = LeaderboardService.CachedBoards[boardName]
	if not entries then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local lbRemote = remoteEvents:FindFirstChild("LeaderboardData")
		if lbRemote then
			lbRemote:FireClient(player, boardName, entries)
		end
	end
end

return LeaderboardService
