--[[
	RoundService.lua
	Manages game rounds, timers, and tower regeneration

	Round Flow:
	1. Intermission (20 seconds) - Wait for players
	2. Starting (5 seconds) - Countdown
	3. InProgress (8 minutes) - Players climb
	4. Ended (5 seconds) - Show winners, cleanup
	5. Repeat

	Features:
	- 8-minute rounds with timer
	- Auto-regenerates tower each round
	- Tracks completion order (1st, 2nd, 3rd place)
	- Awards bonus coins for top 3
	- Minimum player check (configurable)
	- Integrates with Generator, MemoryManager

	Week 2: Full implementation
	Week 3: Add difficulty voting, team modes
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Services (require at top to avoid race conditions)
local Generator = require(script.Parent.ObbyService.Generator)
local MemoryManager = require(script.Parent.ObbyService.MemoryManager)
local CheckpointService = require(script.Parent.CheckpointService)
local MovingPlatformService = require(script.Parent.MovingPlatformService)
local ThemeService = require(script.Parent.ThemeService)
local DataService = require(script.Parent.DataService)

local RoundService = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local ROUND_TIME = GameConfig.Round.RoundTime
local INTERMISSION_TIME = GameConfig.Round.IntermissionTime
local START_COUNTDOWN = GameConfig.Round.StartCountdown
local MIN_PLAYERS = GameConfig.Round.MinPlayers
local AUTO_START = GameConfig.Round.AutoStart

-- Round states
local RoundState = {
	INTERMISSION = "Intermission",
	STARTING = "Starting",
	IN_PROGRESS = "InProgress",
	ENDED = "Ended",
}

-- ============================================================================
-- STATE
-- ============================================================================

RoundService.CurrentState = RoundState.INTERMISSION
RoundService.TimeRemaining = INTERMISSION_TIME
RoundService.RoundNumber = 0
RoundService.CurrentTower = nil
RoundService.CurrentGenerator = nil
RoundService.CurrentMemoryManager = nil

-- Round tracking
RoundService.CompletionOrder = {} -- Players who finished, in order
RoundService.RoundStartTime = 0
RoundService.RoundEndTime = 0

-- State values (for client replication)
RoundService.StateValue = nil
RoundService.TimerValue = nil
RoundService.RoundNumberValue = nil

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local function setupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- State replication values
	RoundService.StateValue = Instance.new("StringValue")
	RoundService.StateValue.Name = "RoundState"
	RoundService.StateValue.Value = RoundState.INTERMISSION
	RoundService.StateValue.Parent = remoteFolder

	RoundService.TimerValue = Instance.new("IntValue")
	RoundService.TimerValue.Name = "RoundTimer"
	RoundService.TimerValue.Value = INTERMISSION_TIME
	RoundService.TimerValue.Parent = remoteFolder

	RoundService.RoundNumberValue = Instance.new("IntValue")
	RoundService.RoundNumberValue.Name = "RoundNumber"
	RoundService.RoundNumberValue.Value = 0
	RoundService.RoundNumberValue.Parent = remoteFolder
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

function RoundService.SetState(newState: string)
	RoundService.CurrentState = newState
	RoundService.StateValue.Value = newState

	print(string.format("[RoundService] State changed: %s", newState))

	-- Fire state change event
	if RoundService.StateChanged then
		RoundService.StateChanged:Fire(newState)
	end
end

function RoundService.SetTimer(seconds: number)
	RoundService.TimeRemaining = seconds
	RoundService.TimerValue.Value = math.floor(seconds)
end

-- ============================================================================
-- TOWER MANAGEMENT
-- ============================================================================

function RoundService.GenerateNewTower()
	print("[RoundService] Generating new tower...")

	-- Cleanup old tower connections (prevents memory leaks)
	if RoundService.CurrentTower then
		CheckpointService.CleanupTower()
		RoundService.CurrentTower:Destroy()
	end

	if RoundService.CurrentMemoryManager then
		RoundService.CurrentMemoryManager:Stop()
	end

	-- Generate new tower with true random seed (prevents predictability)
	-- Using explicit value to avoid potential integer overflow on some systems
	local seed = math.random(1, 2147483647)
	RoundService.CurrentGenerator = Generator.new(seed, "Normal")
	RoundService.CurrentTower = RoundService.CurrentGenerator:GenerateTower()

	-- Start memory management
	RoundService.CurrentMemoryManager = MemoryManager.new(RoundService.CurrentTower)
	RoundService.CurrentMemoryManager:Start()

	-- Initialize moving platforms (Week 7)
	MovingPlatformService.OnNewTower(RoundService.CurrentTower)

	-- Apply environmental themes (Week 8)
	ThemeService.OnNewTower(RoundService.CurrentTower)

	print(string.format(
		"[RoundService] Tower generated (Seed: %d, Sections: %d)",
		seed,
		GameConfig.Tower.SectionsPerTower
	))

	return RoundService.CurrentTower
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function RoundService.TeleportPlayersToStart()
	local startPosition = Vector3.new(0, GameConfig.Tower.StartHeight + 5, 0)

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.CFrame = CFrame.new(startPosition)

				-- Reset leaderstats Stage
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local stage = leaderstats:FindFirstChild("Stage")
					if stage then
						stage.Value = 0
					end
				end

				-- No need to mark respawn - CheckpointService tracks this server-side
			end
		end
	end

	print("[RoundService] Teleported all players to start")
end

function RoundService.GetPlayerCount(): number
	return #Players:GetPlayers()
end

-- ============================================================================
-- COMPLETION TRACKING
-- ============================================================================

function RoundService.OnPlayerFinished(player: Player)
	-- Check if already finished
	for _, finisher in ipairs(RoundService.CompletionOrder) do
		if finisher == player then
			return -- Already recorded
		end
	end

	-- Add to completion order
	table.insert(RoundService.CompletionOrder, player)

	local place = #RoundService.CompletionOrder
	local timeElapsed = tick() - RoundService.RoundStartTime

	print(string.format(
		"[RoundService] %s finished in place #%d (Time: %.1fs)",
		player.Name,
		place,
		timeElapsed
	))

	-- Award bonus coins for top 3 (values from config)
	local placementBonuses = GameConfig.Round.PlacementBonuses
	local bonusCoins = placementBonuses[place] or 0

	if bonusCoins > 0 then
		DataService.AddCoins(player, bonusCoins)
		print(string.format(
			"[RoundService] Awarded %d bonus coins to %s (Place #%d)",
			bonusCoins,
			player.Name,
			place
		))
	end
end

-- ============================================================================
-- ROUND LOOP
-- ============================================================================

function RoundService.RunRound()
	while true do
		-- INTERMISSION
		RoundService.SetState(RoundState.INTERMISSION)
		RoundService.SetTimer(INTERMISSION_TIME)

		print(string.format(
			"[RoundService] Intermission started (%d seconds)",
			INTERMISSION_TIME
		))

		-- Wait for intermission (using while loop to properly handle player count check)
		local intermissionTimer = INTERMISSION_TIME
		while intermissionTimer > 0 do
			RoundService.SetTimer(intermissionTimer)

			-- Check if enough players
			local hasEnoughPlayers = RoundService.GetPlayerCount() >= MIN_PLAYERS

			if AUTO_START and hasEnoughPlayers then
				-- Enough players, continue countdown
				intermissionTimer = intermissionTimer - 1
			elseif not AUTO_START then
				-- Manual start (future feature)
				intermissionTimer = intermissionTimer - 1
			else
				-- Not enough players, reset timer and wait
				if intermissionTimer <= 1 then
					intermissionTimer = INTERMISSION_TIME
					print("[RoundService] Not enough players, restarting intermission")
				else
					intermissionTimer = intermissionTimer - 1
				end
			end

			task.wait(1)
		end

		-- STARTING
		RoundService.SetState(RoundState.STARTING)
		RoundService.SetTimer(START_COUNTDOWN)

		print(string.format(
			"[RoundService] Round starting in %d seconds...",
			START_COUNTDOWN
		))

		-- Generate tower
		RoundService.GenerateNewTower()

		-- Countdown
		for i = START_COUNTDOWN, 1, -1 do
			RoundService.SetTimer(i)
			task.wait(1)
		end

		-- Teleport players to start
		RoundService.TeleportPlayersToStart()

		-- IN PROGRESS
		RoundService.RoundNumber = RoundService.RoundNumber + 1
		RoundService.RoundNumberValue.Value = RoundService.RoundNumber
		RoundService.CompletionOrder = {}
		RoundService.RoundStartTime = tick()

		RoundService.SetState(RoundState.IN_PROGRESS)
		RoundService.SetTimer(ROUND_TIME)

		print(string.format(
			"[RoundService] Round #%d started! (%d minutes)",
			RoundService.RoundNumber,
			ROUND_TIME / 60
		))

		-- Run round timer
		for i = ROUND_TIME, 0, -1 do
			RoundService.SetTimer(i)

			-- Check if all players finished (early end)
			if #RoundService.CompletionOrder >= RoundService.GetPlayerCount() and RoundService.GetPlayerCount() > 0 then
				print("[RoundService] All players finished, ending round early")
				break
			end

			task.wait(1)
		end

		-- ENDED
		RoundService.RoundEndTime = tick()
		RoundService.SetState(RoundState.ENDED)

		local roundDuration = RoundService.RoundEndTime - RoundService.RoundStartTime

		print(string.format(
			"[RoundService] Round #%d ended (Duration: %.1fs, Finishers: %d/%d)",
			RoundService.RoundNumber,
			roundDuration,
			#RoundService.CompletionOrder,
			RoundService.GetPlayerCount()
		))

		-- Show results
		if #RoundService.CompletionOrder > 0 then
			print("[RoundService] Round Results:")
			for i, player in ipairs(RoundService.CompletionOrder) do
				print(string.format("  #%d: %s", i, player.Name))
			end
		else
			print("[RoundService] No players finished this round")
		end

		-- Wait before next round
		task.wait(5)
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function RoundService.Init()
	print("[RoundService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Create state changed event
	RoundService.StateChanged = Instance.new("BindableEvent")

	-- Start round loop
	task.spawn(function()
		RoundService.RunRound()
	end)

	print("[RoundService] Initialized")
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function RoundService.GetCurrentState(): string
	return RoundService.CurrentState
end

function RoundService.GetTimeRemaining(): number
	return RoundService.TimeRemaining
end

function RoundService.GetRoundNumber(): number
	return RoundService.RoundNumber
end

function RoundService.IsRoundInProgress(): boolean
	return RoundService.CurrentState == RoundState.IN_PROGRESS
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return RoundService
