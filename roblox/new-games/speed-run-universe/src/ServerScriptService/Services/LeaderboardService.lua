--[[
	LeaderboardService.lua - Speed Run Universe
	Global speedrun leaderboards using OrderedDataStore.
	Supports per-stage times, per-world times, total coins, and tournament rankings.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local LeaderboardService = {}
LeaderboardService.DataService = nil
LeaderboardService.SecurityManager = nil

-- ============================================================================
-- DATA STORES (one OrderedDataStore per leaderboard category + key)
-- ============================================================================
-- Times are stored as integers (milliseconds) since OrderedDataStore only supports integers.
-- Lower time = better, so we store as-is (ascending sort).
-- For coins/stages (higher = better), we store raw values (descending sort).

local LeaderboardCache = {} -- cacheKey -> { Data = entries, LastUpdate = tick() }
local CACHE_DURATION = GameConfig.Leaderboards.UpdateInterval or 30

-- ============================================================================
-- INIT
-- ============================================================================
function LeaderboardService.Init()
	LeaderboardService.DataService = require(ServerScriptService.Services.DataService)
	LeaderboardService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Client requests leaderboard data
	re:WaitForChild("RequestLeaderboard").OnServerEvent:Connect(function(player, data)
		LeaderboardService.HandleLeaderboardRequest(player, data)
	end)

	-- Setup RemoteFunction for synchronous queries
	local rf = ReplicatedStorage:WaitForChild("RemoteFunctions")
	rf:WaitForChild("GetWorldTimes").OnServerInvoke = function(player, worldId)
		return LeaderboardService.GetWorldTimes(player, worldId)
	end

	-- Periodically refresh in-game leaderboard display
	task.spawn(function()
		while true do
			task.wait(60)
			LeaderboardService._RefreshInGameLeaderboard()
		end
	end)

	print("[LeaderboardService] Initialized")
end

-- ============================================================================
-- SUBMIT TIME
-- ============================================================================
function LeaderboardService.SubmitTime(player, category, key, timeSeconds)
	-- Convert seconds to milliseconds (integer)
	local timeMs = math.floor(timeSeconds * 1000)

	-- For time leaderboards, lower is better.
	-- OrderedDataStore sorts ascending by default when using GetSortedAsync(true).
	local storeName = "LB_" .. category .. "_" .. key
	local entryKey = tostring(player.UserId)

	local success, err = pcall(function()
		local store = DataStoreService:GetOrderedDataStore(storeName)
		-- Only update if new time is better (lower)
		local currentBest = nil
		pcall(function()
			currentBest = store:GetAsync(entryKey)
		end)

		if currentBest == nil or timeMs < currentBest then
			store:SetAsync(entryKey, timeMs)
		end
	end)

	if not success then
		warn("[LeaderboardService] Failed to submit time:", err)
	end

	-- Invalidate cache
	LeaderboardCache[storeName] = nil
end

-- ============================================================================
-- SUBMIT STAT (coins, stages - higher is better)
-- ============================================================================
function LeaderboardService.SubmitStat(player, category, value)
	local storeName = "LB_" .. category
	local entryKey = tostring(player.UserId)

	local success, err = pcall(function()
		local store = DataStoreService:GetOrderedDataStore(storeName)
		store:SetAsync(entryKey, math.floor(value))
	end)

	if not success then
		warn("[LeaderboardService] Failed to submit stat:", err)
	end

	LeaderboardCache[storeName] = nil
end

-- ============================================================================
-- FETCH LEADERBOARD
-- ============================================================================
function LeaderboardService.FetchLeaderboard(category, key, ascending, maxEntries)
	ascending = ascending ~= false -- default true (for time boards)
	maxEntries = maxEntries or GameConfig.Leaderboards.MaxEntries

	local storeName
	if key then
		storeName = "LB_" .. category .. "_" .. key
	else
		storeName = "LB_" .. category
	end

	-- Check cache
	local cached = LeaderboardCache[storeName]
	if cached and (tick() - cached.LastUpdate) < CACHE_DURATION then
		return cached.Data, true -- Return cached data + cache hit flag
	end

	local entries = {}

	-- CRITICAL FIX: Enhanced error handling with retry logic
	local MAX_RETRIES = 2
	local success, err

	for attempt = 1, MAX_RETRIES do
		success, err = pcall(function()
			local store = DataStoreService:GetOrderedDataStore(storeName)
			local pages = store:GetSortedAsync(ascending, maxEntries)
			local currentPage = pages:GetCurrentPage()

			for rank, entry in ipairs(currentPage) do
				local userId = tonumber(entry.key)
				if not userId then
					warn("[LeaderboardService] Invalid userId in leaderboard:", entry.key)
					continue
				end

				local playerName = "Player_" .. userId

				-- Try to get player name (with timeout)
				local nameSuccess, name = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if nameSuccess and name then
					playerName = name
				end

				table.insert(entries, {
					Rank = rank,
					UserId = userId,
					PlayerName = playerName,
					Value = entry.value,
				})
			end
		end)

		if success then
			break -- Success, exit retry loop
		else
			warn(string.format("[LeaderboardService] Leaderboard fetch attempt %d/%d failed: %s",
				attempt, MAX_RETRIES, tostring(err)))

			if attempt < MAX_RETRIES then
				task.wait(1) -- Wait before retry
			end
		end
	end

	if not success then
		warn("[LeaderboardService] All leaderboard fetch attempts failed:", err)

		-- CRITICAL FIX: Return cached data even if expired (graceful degradation)
		if cached then
			warn("[LeaderboardService] Returning stale cached data as fallback")
			return cached.Data, false -- Stale cache
		end

		return {}, false -- Empty with failure flag
	end

	-- Cache the results
	LeaderboardCache[storeName] = {
		Data = entries,
		LastUpdate = tick(),
	}

	return entries, true -- Fresh data
end

-- ============================================================================
-- CLIENT REQUEST HANDLER
-- ============================================================================
function LeaderboardService.HandleLeaderboardRequest(player, data)
	if not LeaderboardService.SecurityManager.CheckRateLimit(player, "RequestLeaderboard") then return end
	if not data or not data.Category then return end

	local category = data.Category
	local key = data.Key
	local ascending = true
	local maxEntries = data.MaxEntries or 50

	-- Time-based leaderboards are ascending (lower is better)
	-- Stat-based leaderboards are descending (higher is better)
	if category == "TotalCoins" or category == "StagesCompleted" or category == "TournamentWins" then
		ascending = false
	end

	local entries = LeaderboardService.FetchLeaderboard(category, key, ascending, maxEntries)

	-- Find player's own rank
	local playerRank = nil
	local playerValue = nil
	for _, entry in ipairs(entries) do
		if entry.UserId == player.UserId then
			playerRank = entry.Rank
			playerValue = entry.Value
			break
		end
	end

	-- If player not in top entries, get their data separately
	if not playerRank then
		local playerData = LeaderboardService.DataService.GetFullData(player)
		if playerData then
			if category == "WorldBestTime" and key then
				local pb = playerData.PersonalBests[key]
				if pb then
					playerValue = math.floor(pb * 1000)
				end
			elseif category == "StageBestTime" and key then
				local pb = playerData.PersonalBests[key]
				if pb then
					playerValue = math.floor(pb * 1000)
				end
			elseif category == "TotalCoins" then
				playerValue = playerData.TotalCoinsEarned
			elseif category == "StagesCompleted" then
				playerValue = playerData.TotalStagesCompleted
			end
		end
	end

	-- Send to client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local lbEvent = re:FindFirstChild("LeaderboardData")
		if lbEvent then
			lbEvent:FireClient(player, {
				Category = category,
				Key = key,
				Entries = entries,
				PlayerRank = playerRank,
				PlayerValue = playerValue,
			})
		end
	end
end

-- ============================================================================
-- GET WORLD TIMES (RemoteFunction - synchronous from client)
-- ============================================================================
function LeaderboardService.GetWorldTimes(player, worldId)
	local playerData = LeaderboardService.DataService.GetFullData(player)
	if not playerData then return {} end

	local times = {}
	local worldConfig = GameConfig.WorldById[worldId]
	if not worldConfig then return {} end

	-- Get per-stage times
	for stageNum = 1, worldConfig.StageCount do
		local key = worldId .. "_" .. tostring(stageNum)
		times["Stage_" .. stageNum] = playerData.PersonalBests[key]
	end

	-- Get world total time
	times["World"] = playerData.PersonalBests[worldId .. "_World"]

	return times
end

-- ============================================================================
-- IN-GAME LEADERBOARD DISPLAY (physical SurfaceGui on workspace parts)
-- ============================================================================
function LeaderboardService._RefreshInGameLeaderboard()
	-- Look for leaderboard display parts in workspace
	local leaderboardFolder = workspace:FindFirstChild("LeaderboardDisplays")
	if not leaderboardFolder then return end

	for _, display in ipairs(leaderboardFolder:GetChildren()) do
		local category = display:GetAttribute("Category") or "WorldBestTime"
		local key = display:GetAttribute("Key") or "Grass_World"
		local ascending = display:GetAttribute("Ascending") ~= false

		local entries = LeaderboardService.FetchLeaderboard(category, key, ascending, 10)

		-- Update SurfaceGui
		local surfaceGui = display:FindFirstChild("SurfaceGui")
		if surfaceGui then
			local list = surfaceGui:FindFirstChild("EntryList")
			if list then
				-- Clear existing entries
				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("TextLabel") then child:Destroy() end
				end

				-- Add entries
				for _, entry in ipairs(entries) do
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 0, 20)
					label.BackgroundTransparency = 1
					label.TextColor3 = Color3.fromRGB(255, 255, 255)
					label.TextSize = 14
					label.Font = Enum.Font.GothamMedium

					if category == "WorldBestTime" or category == "StageBestTime" then
						local seconds = entry.Value / 1000
						label.Text = string.format("#%d  %s  %.2fs", entry.Rank, entry.PlayerName, seconds)
					else
						label.Text = string.format("#%d  %s  %s", entry.Rank, entry.PlayerName, tostring(entry.Value))
					end

					label.Parent = list
				end
			end
		end
	end
end

-- ============================================================================
-- TOURNAMENT SUPPORT
-- ============================================================================
function LeaderboardService.SubmitTournamentTime(player, worldId, timeSeconds)
	local timeMs = math.floor(timeSeconds * 1000)
	local weekId = os.date("%Y-W%W")
	local storeName = "LB_Tournament_" .. weekId .. "_" .. worldId

	local success = pcall(function()
		local store = DataStoreService:GetOrderedDataStore(storeName)
		local current = nil
		pcall(function() current = store:GetAsync(tostring(player.UserId)) end)

		if current == nil or timeMs < current then
			store:SetAsync(tostring(player.UserId), timeMs)
		end
	end)

	return success
end

function LeaderboardService.GetTournamentLeaderboard(worldId, maxEntries)
	local weekId = os.date("%Y-W%W")
	return LeaderboardService.FetchLeaderboard("Tournament_" .. weekId, worldId, true, maxEntries or 20)
end

return LeaderboardService
