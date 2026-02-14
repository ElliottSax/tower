--[[
	StatisticsService.lua
	Tracks detailed player statistics

	Features:
	- Session statistics (current play session)
	- All-time statistics (persistent via DataService)
	- Tracks:
	  * Total playtime
	  * Total jumps
	  * Total deaths (already in DataService)
	  * Rounds played
	  * Average completion time
	  * Best completion time
	  * Double jumps used
	  * Air dashes used
	  * Distance traveled
	- RemoteFunction for client queries
	- Updates DataService for persistence

	Week 3: Full implementation
	Week 4+: Add achievements, milestones, analytics dashboard
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

local StatisticsService = {}

-- ============================================================================
-- SESSION DATA
-- ============================================================================

StatisticsService.SessionData = {}

-- Format: [player.UserId] = { session stats }
local function createSessionData()
	return {
		-- Session stats (reset on join)
		SessionStartTime = tick(),
		SessionPlaytime = 0,
		SessionJumps = 0,
		SessionDeaths = 0,
		SessionRoundsPlayed = 0,
		SessionCoinsEarned = 0,
		SessionHighestStage = 0,

		-- Tracking variables
		LastPosition = nil,
		TotalDistanceTraveled = 0,
	}
end

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

StatisticsService.RemoteEvents = {}

local function setupRemoteEvents()
	-- Use centralized RemoteEventsInit (single source of truth for all remotes)
	StatisticsService.RemoteEvents.GetStatistics = RemoteEventsInit.GetRemote("GetStatistics")

	-- Setup callback using SecureRemotes API
	local getStatisticsRemote = StatisticsService.RemoteEvents.GetStatistics
	if getStatisticsRemote and getStatisticsRemote.OnServerInvoke then
		getStatisticsRemote:OnServerInvoke(function(player)
			return StatisticsService.GetStatistics(player)
		end)
	end

	print("[StatisticsService] RemoteEvents setup complete (using RemoteEventsInit)")
end

-- ============================================================================
-- STATISTICS TRACKING
-- ============================================================================

function StatisticsService.TrackJump(player: Player)
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then return end

	sessionData.SessionJumps = sessionData.SessionJumps + 1

	-- Update all-time stats (via DataService)
	local DataService = require(script.Parent.DataService)
	local profile = DataService.GetProfile(player)

	if profile and profile.Data and profile.Data.Stats then
		profile.Data.Stats.TotalJumps = (profile.Data.Stats.TotalJumps or 0) + 1
	end
end

function StatisticsService.TrackDeath(player: Player)
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then return end

	sessionData.SessionDeaths = sessionData.SessionDeaths + 1

	-- DataService.IncrementDeaths already handles all-time tracking
end

function StatisticsService.TrackRoundPlayed(player: Player)
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then return end

	sessionData.SessionRoundsPlayed = sessionData.SessionRoundsPlayed + 1

	-- Update all-time stats
	local DataService = require(script.Parent.DataService)
	local profile = DataService.GetProfile(player)

	if profile and profile.Data and profile.Data.Stats then
		profile.Data.Stats.RoundsPlayed = (profile.Data.Stats.RoundsPlayed or 0) + 1
	end
end

function StatisticsService.TrackCoinEarned(player: Player, amount: number)
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then return end

	sessionData.SessionCoinsEarned = sessionData.SessionCoinsEarned + amount

	-- DataService.AddCoins already handles all-time tracking
end

function StatisticsService.TrackStageReached(player: Player, stage: number)
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then return end

	if stage > sessionData.SessionHighestStage then
		sessionData.SessionHighestStage = stage
	end

	-- DataService.UpdateHighestStage already handles all-time tracking
end

function StatisticsService.TrackDistance(player: Player, deltaTime: number)
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local currentPosition = rootPart.Position

	if sessionData.LastPosition then
		local distance = (currentPosition - sessionData.LastPosition).Magnitude
		sessionData.TotalDistanceTraveled = sessionData.TotalDistanceTraveled + distance
	end

	sessionData.LastPosition = currentPosition
end

-- ============================================================================
-- GET STATISTICS
-- ============================================================================

function StatisticsService.GetStatistics(player: Player): {}
	local sessionData = StatisticsService.SessionData[player.UserId]
	if not sessionData then
		return {}
	end

	-- Get all-time stats from DataService
	local DataService = require(script.Parent.DataService)
	local profile = DataService.GetProfile(player)

	local allTimeStats = {
		TotalPlaytime = 0,
		TotalJumps = 0,
		TotalDeaths = 0,
		RoundsPlayed = 0,
		HighestStage = 0,
		TowersCompleted = 0,
		TotalCoinsEarned = 0,
	}

	if profile and profile.Data and profile.Data.Stats then
		allTimeStats.TotalPlaytime = profile.Data.Stats.TotalPlaytime or 0
		allTimeStats.TotalJumps = profile.Data.Stats.TotalJumps or 0
		allTimeStats.TotalDeaths = profile.Data.Stats.Deaths or 0
		allTimeStats.RoundsPlayed = profile.Data.Stats.RoundsPlayed or 0
		allTimeStats.HighestStage = profile.Data.Stats.HighestStage or 0
		allTimeStats.TowersCompleted = profile.Data.Stats.TowersCompleted or 0
		allTimeStats.TotalCoinsEarned = profile.Data.Stats.TotalCoinsEarned or profile.Data.Coins
	end

	-- Calculate session playtime
	local currentSessionPlaytime = tick() - sessionData.SessionStartTime

	return {
		-- Session stats
		Session = {
			Playtime = currentSessionPlaytime,
			Jumps = sessionData.SessionJumps,
			Deaths = sessionData.SessionDeaths,
			RoundsPlayed = sessionData.SessionRoundsPlayed,
			CoinsEarned = sessionData.SessionCoinsEarned,
			HighestStage = sessionData.SessionHighestStage,
			DistanceTraveled = sessionData.TotalDistanceTraveled,
		},

		-- All-time stats
		AllTime = allTimeStats,
	}
end

-- ============================================================================
-- PLAYTIME TRACKING
-- ============================================================================

-- Playtime update interval in seconds (must match the task.wait in StartPlaytimeLoop)
local PLAYTIME_UPDATE_INTERVAL = 60

function StatisticsService.UpdatePlaytime()
	-- Update playtime for all online players
	local DataService = require(script.Parent.DataService)

	for _, player in ipairs(Players:GetPlayers()) do
		local sessionData = StatisticsService.SessionData[player.UserId]
		if sessionData then
			-- Update DataService (all-time playtime)
			local profile = DataService.GetProfile(player)
			if profile and profile.Data and profile.Data.Stats then
				-- Add the actual interval time, not 1 second
				profile.Data.Stats.TotalPlaytime = (profile.Data.Stats.TotalPlaytime or 0) + PLAYTIME_UPDATE_INTERVAL
			end
		end
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function StatisticsService.OnPlayerAdded(player: Player)
	-- Initialize session data
	StatisticsService.SessionData[player.UserId] = createSessionData()

	print(string.format("[StatisticsService] Initialized stats for %s", player.Name))
end

function StatisticsService.OnPlayerRemoving(player: Player)
	-- Save final session playtime
	local sessionData = StatisticsService.SessionData[player.UserId]
	if sessionData then
		local DataService = require(script.Parent.DataService)
		local profile = DataService.GetProfile(player)

		if profile and profile.Data and profile.Data.Stats then
			local sessionPlaytime = tick() - sessionData.SessionStartTime
			profile.Data.Stats.TotalPlaytime = (profile.Data.Stats.TotalPlaytime or 0) + sessionPlaytime
		end
	end

	-- Cleanup
	StatisticsService.SessionData[player.UserId] = nil

	print(string.format("[StatisticsService] Cleaned up stats for %s", player.Name))
end

-- ============================================================================
-- INTEGRATION WITH OTHER SERVICES
-- ============================================================================

-- Called by CheckpointService when player reaches checkpoint
function StatisticsService.OnCheckpointReached(player: Player, stage: number)
	StatisticsService.TrackStageReached(player, stage)
end

-- Called by CheckpointService when player dies
function StatisticsService.OnPlayerDied(player: Player)
	StatisticsService.TrackDeath(player)
end

-- Called by RoundService when round starts
function StatisticsService.OnRoundStarted()
	for _, player in ipairs(Players:GetPlayers()) do
		StatisticsService.TrackRoundPlayed(player)
	end
end

-- Called by CoinService when player earns coins
function StatisticsService.OnCoinsEarned(player: Player, amount: number)
	StatisticsService.TrackCoinEarned(player, amount)
end

-- ============================================================================
-- DISTANCE TRACKING LOOP
-- ============================================================================

-- Track active player UserIds for efficient iteration (avoids Players:GetPlayers() every frame)
local TrackedPlayerIds = {}

local function onPlayerAddedForTracking(player)
	TrackedPlayerIds[player.UserId] = true
end

local function onPlayerRemovingForTracking(player)
	TrackedPlayerIds[player.UserId] = nil
end

function StatisticsService.StartDistanceTracking()
	-- Setup efficient player tracking
	Players.PlayerAdded:Connect(onPlayerAddedForTracking)
	Players.PlayerRemoving:Connect(onPlayerRemovingForTracking)

	-- Add existing players
	for _, player in ipairs(Players:GetPlayers()) do
		TrackedPlayerIds[player.UserId] = true
	end

	-- Track distance traveled every frame using cached player list
	RunService.Heartbeat:Connect(function(deltaTime)
		for userId in pairs(TrackedPlayerIds) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				StatisticsService.TrackDistance(player, deltaTime)
			end
		end
	end)

	print("[StatisticsService] Distance tracking started (optimized)")
end

-- ============================================================================
-- PLAYTIME UPDATE LOOP
-- ============================================================================

function StatisticsService.StartPlaytimeLoop()
	task.spawn(function()
		while true do
			task.wait(PLAYTIME_UPDATE_INTERVAL) -- Update every minute
			StatisticsService.UpdatePlaytime()
		end
	end)

	print("[StatisticsService] Playtime tracking started")
end

-- ============================================================================
-- SESSION DATA CLEANUP
-- ============================================================================

function StatisticsService.CleanupOrphanedSessionData()
	-- Clean up session data for players who disconnected without triggering OnPlayerRemoving
	-- This can happen due to network errors or crashes
	local activePlayers = {}
	for _, player in ipairs(Players:GetPlayers()) do
		activePlayers[player.UserId] = true
	end

	local cleanedCount = 0
	for userId in pairs(StatisticsService.SessionData) do
		if not activePlayers[userId] then
			StatisticsService.SessionData[userId] = nil
			cleanedCount = cleanedCount + 1
		end
	end

	if cleanedCount > 0 then
		print(string.format("[StatisticsService] Cleaned up %d orphaned session entries", cleanedCount))
	end
end

function StatisticsService.StartCleanupLoop()
	task.spawn(function()
		while true do
			task.wait(300) -- Every 5 minutes
			StatisticsService.CleanupOrphanedSessionData()
		end
	end)

	print("[StatisticsService] Cleanup loop started")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function StatisticsService.Init()
	print("[StatisticsService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Player management
	Players.PlayerAdded:Connect(function(player)
		StatisticsService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		StatisticsService.OnPlayerRemoving(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		StatisticsService.OnPlayerAdded(player)
	end

	-- Start tracking loops
	StatisticsService.StartDistanceTracking()
	StatisticsService.StartPlaytimeLoop()
	StatisticsService.StartCleanupLoop()

	print("[StatisticsService] Initialized")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return StatisticsService
