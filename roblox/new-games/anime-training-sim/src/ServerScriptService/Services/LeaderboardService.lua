--[[
	LeaderboardService.lua - Anime Training Simulator
	Global leaderboards for power, PvP rating, rebirth level
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LeaderboardService = {}
LeaderboardService.DataService = nil

local BOARDS = { "TotalPower", "PvPRating", "RebirthLevel" }
local CachedBoards = {}
local CACHE_DURATION = 120

function LeaderboardService.Init()
	print("[LeaderboardService] Initializing...")
	LeaderboardService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GetLeaderboard").OnServerEvent:Connect(function(player, boardName)
		LeaderboardService.SendLeaderboard(player, boardName)
	end)

	-- Update boards periodically
	task.spawn(function()
		while true do
			LeaderboardService.UpdateAllBoards()
			task.wait(CACHE_DURATION)
		end
	end)

	print("[LeaderboardService] Initialized")
end

function LeaderboardService.UpdateAllBoards()
	for _, boardName in ipairs(BOARDS) do
		pcall(function()
			local store = DataStoreService:GetOrderedDataStore("LB_" .. boardName)

			-- Update current players
			for _, player in ipairs(Players:GetPlayers()) do
				local data = LeaderboardService.DataService.GetFullData(player)
				if data then
					local value = 0
					if boardName == "TotalPower" then
						value = LeaderboardService.DataService.GetTotalPower(player)
					elseif boardName == "PvPRating" then
						value = data.PvPRating or 0
					elseif boardName == "RebirthLevel" then
						value = data.RebirthLevel or 0
					end
					if value > 0 then
						store:SetAsync(tostring(player.UserId), value)
					end
				end
			end

			-- Fetch top 50
			local pages = store:GetSortedAsync(false, 50)
			local topPage = pages:GetCurrentPage()

			local entries = {}
			for rank, entry in ipairs(topPage) do
				local userId = tonumber(entry.key)
				local name = "Player"
				pcall(function()
					name = Players:GetNameFromUserIdAsync(userId)
				end)
				table.insert(entries, { Name = name, Value = entry.value, Rank = rank })
			end

			CachedBoards[boardName] = { Entries = entries, UpdatedAt = os.time() }
		end)
	end
end

function LeaderboardService.SendLeaderboard(player, boardName)
	if type(boardName) ~= "string" then return end

	local validBoard = false
	for _, b in ipairs(BOARDS) do
		if b == boardName then validBoard = true; break end
	end
	if not validBoard then return end

	local cached = CachedBoards[boardName]
	local entries = cached and cached.Entries or {}

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local lbData = remoteEvents:FindFirstChild("LeaderboardData")
		if lbData then
			lbData:FireClient(player, { Board = boardName, Entries = entries })
		end
	end
end

return LeaderboardService
