--[[
	SpeedrunService.lua - Speed Run Universe
	Manages speedrun timers, personal bests, split times, and ghost recording.
	All timing is authoritative on the server to prevent exploits.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SpeedrunService = {}
SpeedrunService.DataService = nil
SpeedrunService.SecurityManager = nil
SpeedrunService.LeaderboardService = nil

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================
-- Active speedrun sessions: userId -> session data
local ActiveRuns = {}

-- Ghost recording buffers: userId -> { stageKey -> [frames] }
local GhostRecordings = {}

-- ============================================================================
-- SESSION STRUCTURE
-- ============================================================================
--[[
	ActiveRun = {
		PlayerId = userId,
		WorldId = "Grass",
		StartStage = 1,
		CurrentStage = 1,
		IsWorldRun = true/false,   -- full world or single stage
		StartTime = tick(),
		StageStartTime = tick(),   -- start of current stage
		SplitTimes = {},           -- { [stageNum] = seconds }
		TotalTime = 0,
		Paused = false,
		DeathCount = 0,
		CoinsCollected = 0,
	}
]]

-- ============================================================================
-- INIT
-- ============================================================================
function SpeedrunService.Init()
	SpeedrunService.DataService = require(ServerScriptService.Services.DataService)
	SpeedrunService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Client requests to start a speedrun
	re:WaitForChild("StartSpeedrun").OnServerEvent:Connect(function(player, data)
		SpeedrunService.StartRun(player, data)
	end)

	-- Client reports finishing (server validates timing)
	re:WaitForChild("StopSpeedrun").OnServerEvent:Connect(function(player)
		SpeedrunService.StopRun(player)
	end)

	-- Start the tick loop for active runs
	task.spawn(function()
		while true do
			task.wait(0.1)
			SpeedrunService._TickActiveRuns()
		end
	end)

	print("[SpeedrunService] Initialized")
end

-- Deferred init for services that may not be ready at Init time
function SpeedrunService._EnsureLeaderboardService()
	if not SpeedrunService.LeaderboardService then
		local ok, svc = pcall(function()
			return require(ServerScriptService.Services.LeaderboardService)
		end)
		if ok then SpeedrunService.LeaderboardService = svc end
	end
end

-- ============================================================================
-- START RUN
-- ============================================================================
function SpeedrunService.StartRun(player, options)
	if not SpeedrunService.DataService.IsLoaded(player) then return end

	options = options or {}
	local worldId = options.WorldId or "Grass"
	local stageNum = options.StageNum or 1
	local isWorldRun = options.IsWorldRun ~= false -- default true

	-- Validate world is unlocked
	if not SpeedrunService.DataService.HasUnlockedWorld(player, worldId) then
		SpeedrunService._Notify(player, "World is locked!")
		return
	end

	-- Cancel any existing run
	if ActiveRuns[player.UserId] then
		SpeedrunService._EndRun(player.UserId, false)
	end

	local now = tick()

	-- Create session
	ActiveRuns[player.UserId] = {
		PlayerId = player.UserId,
		WorldId = worldId,
		StartStage = stageNum,
		CurrentStage = stageNum,
		IsWorldRun = isWorldRun,
		StartTime = now,
		StageStartTime = now,
		SplitTimes = {},
		TotalTime = 0,
		Paused = false,
		DeathCount = 0,
		CoinsCollected = 0,
	}

	-- Start ghost recording
	SpeedrunService._StartGhostRecording(player, worldId, stageNum)

	-- Notify client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local update = re:FindFirstChild("SpeedrunUpdate")
		if update then
			update:FireClient(player, {
				Action = "Started",
				WorldId = worldId,
				Stage = stageNum,
				IsWorldRun = isWorldRun,
				Time = 0,
			})
		end
	end

	print("[SpeedrunService]", player.Name, "started run in", worldId, "stage", stageNum)
end

-- ============================================================================
-- STAGE COMPLETE (called by StageService when checkpoint/finish is reached)
-- ============================================================================
function SpeedrunService.OnStageComplete(player, worldId, stageNum)
	local run = ActiveRuns[player.UserId]
	if not run then return end
	if run.WorldId ~= worldId then return end

	local now = tick()
	local stageTime = now - run.StageStartTime
	run.SplitTimes[stageNum] = stageTime

	-- Validate the time
	local valid, reason = SpeedrunService.SecurityManager.ValidateSpeedrunTime(
		player, worldId, stageNum, stageTime
	)

	if not valid then
		warn("[SpeedrunService] Invalid time from", player.Name, ":", reason)
		SpeedrunService._EndRun(player.UserId, false)
		return
	end

	-- Save ghost recording for this stage
	SpeedrunService._StopGhostRecording(player, worldId, stageNum)

	-- Check for personal best on this stage
	local stageKey = worldId .. "_" .. tostring(stageNum)
	local isPB = SpeedrunService.DataService.SetPersonalBest(player, stageKey, stageTime)

	if isPB then
		-- Save the ghost data for the PB
		local ghostData = SpeedrunService._GetGhostRecording(player, worldId, stageNum)
		if ghostData then
			SpeedrunService.DataService.SaveGhostData(player, stageKey, ghostData)
		end

		-- Notify new PB
		local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if re then
			local pbEvent = re:FindFirstChild("NewPersonalBest")
			if pbEvent then
				pbEvent:FireClient(player, {
					StageKey = stageKey,
					Time = stageTime,
					PreviousBest = SpeedrunService.DataService.GetPersonalBest(player, stageKey),
				})
			end
		end

		-- Submit to leaderboard
		SpeedrunService._EnsureLeaderboardService()
		if SpeedrunService.LeaderboardService then
			SpeedrunService.LeaderboardService.SubmitTime(player, "StageBestTime", stageKey, stageTime)
		end
	end

	-- Check if this was the last stage in a world run
	local worldConfig = GameConfig.WorldById[worldId]
	if run.IsWorldRun and stageNum >= worldConfig.StageCount then
		-- World run complete
		SpeedrunService._CompleteWorldRun(player, run)
	else
		-- Move to next stage
		run.CurrentStage = stageNum + 1
		run.StageStartTime = now

		-- Start ghost recording for next stage
		SpeedrunService._StartGhostRecording(player, worldId, stageNum + 1)

		-- Send split update
		local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if re then
			local update = re:FindFirstChild("SpeedrunUpdate")
			if update then
				update:FireClient(player, {
					Action = "StageSplit",
					WorldId = worldId,
					Stage = stageNum,
					StageTime = stageTime,
					IsPB = isPB,
					TotalTime = now - run.StartTime,
					NextStage = run.CurrentStage,
				})
			end
		end
	end
end

-- ============================================================================
-- WORLD RUN COMPLETE
-- ============================================================================
function SpeedrunService._CompleteWorldRun(player, run)
	local worldId = run.WorldId
	local totalTime = tick() - run.StartTime

	-- Validate total world time
	local valid, reason = SpeedrunService.SecurityManager.ValidateSpeedrunTime(
		player, worldId, nil, totalTime
	)

	if not valid then
		warn("[SpeedrunService] Invalid world time from", player.Name, ":", reason)
		SpeedrunService._EndRun(player.UserId, false)
		return
	end

	-- Check personal best for world
	local worldKey = worldId .. "_World"
	local isPB = SpeedrunService.DataService.SetPersonalBest(player, worldKey, totalTime)

	-- Submit to leaderboard
	SpeedrunService._EnsureLeaderboardService()
	if SpeedrunService.LeaderboardService then
		SpeedrunService.LeaderboardService.SubmitTime(player, "WorldBestTime", worldKey, totalTime)
	end

	-- Award coins
	local worldConfig = GameConfig.WorldById[worldId]
	local coinReward = worldConfig.CompletionReward
	-- Bonus for beating par time
	if totalTime < worldConfig.ParTimeSeconds then
		coinReward = coinReward * 2
	end
	SpeedrunService.DataService.AddCoins(player, coinReward)

	-- Notify client
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local complete = re:FindFirstChild("SpeedrunComplete")
		if complete then
			complete:FireClient(player, {
				WorldId = worldId,
				TotalTime = totalTime,
				SplitTimes = run.SplitTimes,
				IsPB = isPB,
				CoinsEarned = coinReward,
				DeathCount = run.DeathCount,
				UnderPar = totalTime < worldConfig.ParTimeSeconds,
			})
		end
	end

	-- Clean up run
	SpeedrunService._EndRun(player.UserId, true)

	print("[SpeedrunService]", player.Name, "completed", worldId, "in", string.format("%.2f", totalTime), "s", isPB and "(NEW PB!)" or "")
end

-- ============================================================================
-- STOP / CANCEL RUN
-- ============================================================================
function SpeedrunService.StopRun(player)
	SpeedrunService._EndRun(player.UserId, false)
end

function SpeedrunService._EndRun(userId, completed)
	local run = ActiveRuns[userId]
	if not run then return end

	-- Clean up ghost recordings for incomplete runs
	if not completed then
		GhostRecordings[userId] = nil
	end

	ActiveRuns[userId] = nil
end

-- ============================================================================
-- DEATH HANDLING (called by StageService)
-- ============================================================================
function SpeedrunService.OnPlayerDeath(player)
	local run = ActiveRuns[player.UserId]
	if not run then return end

	run.DeathCount = run.DeathCount + 1

	-- Update data stats
	local data = SpeedrunService.DataService.GetFullData(player)
	if data then
		data.TotalDeaths = data.TotalDeaths + 1
	end
end

-- ============================================================================
-- TICK LOOP (send timer updates to clients)
-- ============================================================================
function SpeedrunService._TickActiveRuns()
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not re then return end
	local update = re:FindFirstChild("SpeedrunUpdate")
	if not update then return end

	for userId, run in pairs(ActiveRuns) do
		if run.Paused then continue end

		local player = Players:GetPlayerByUserId(userId)
		if not player then
			SpeedrunService._EndRun(userId, false)
			continue
		end

		local now = tick()
		local totalTime = now - run.StartTime
		local stageTime = now - run.StageStartTime

		update:FireClient(player, {
			Action = "Tick",
			TotalTime = totalTime,
			StageTime = stageTime,
			Stage = run.CurrentStage,
			WorldId = run.WorldId,
			DeathCount = run.DeathCount,
		})

		-- Record ghost frame
		SpeedrunService._RecordGhostFrame(player, run.WorldId, run.CurrentStage)
	end
end

-- ============================================================================
-- GHOST RECORDING
-- ============================================================================
function SpeedrunService._StartGhostRecording(player, worldId, stageNum)
	local userId = player.UserId
	if not GhostRecordings[userId] then
		GhostRecordings[userId] = {}
	end

	local key = worldId .. "_" .. tostring(stageNum)
	GhostRecordings[userId][key] = {
		Frames = {},
		StartTime = tick(),
		WorldId = worldId,
		StageNum = stageNum,
	}
end

function SpeedrunService._RecordGhostFrame(player, worldId, stageNum)
	local userId = player.UserId
	local recordings = GhostRecordings[userId]
	if not recordings then return end

	local key = worldId .. "_" .. tostring(stageNum)
	local recording = recordings[key]
	if not recording then return end

	-- Check max duration
	local elapsed = tick() - recording.StartTime
	if elapsed > GameConfig.GhostSettings.MaxRecordDuration then return end

	-- Only record at the configured interval
	local frameCount = #recording.Frames
	if frameCount > 0 and elapsed - (frameCount * GameConfig.GhostSettings.RecordInterval) < GameConfig.GhostSettings.RecordInterval then
		return
	end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Store compact frame data
	local pos = hrp.Position
	local cf = hrp.CFrame
	table.insert(recording.Frames, {
		T = elapsed,
		X = math.floor(pos.X * 100) / 100,
		Y = math.floor(pos.Y * 100) / 100,
		Z = math.floor(pos.Z * 100) / 100,
		RY = math.floor(math.deg(select(2, cf:ToEulerAnglesYXZ())) * 10) / 10,
	})
end

function SpeedrunService._StopGhostRecording(player, worldId, stageNum)
	-- Recording stays in buffer; saved to datastore if it's a PB
end

function SpeedrunService._GetGhostRecording(player, worldId, stageNum)
	local userId = player.UserId
	local recordings = GhostRecordings[userId]
	if not recordings then return nil end

	local key = worldId .. "_" .. tostring(stageNum)
	local recording = recordings[key]
	if not recording then return nil end

	return {
		Frames = recording.Frames,
		WorldId = worldId,
		StageNum = stageNum,
		PlayerName = player.Name,
		TotalTime = tick() - recording.StartTime,
	}
end

-- ============================================================================
-- CLIENT GHOST REQUEST
-- ============================================================================
function SpeedrunService.HandleGhostRequest(player, stageKey)
	if not SpeedrunService.SecurityManager.CheckRateLimit(player, "RequestGhost") then return end

	local ghostData = SpeedrunService.DataService.LoadGhostData(player, stageKey)

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local ghostEvent = re:FindFirstChild("GhostData")
		if ghostEvent then
			ghostEvent:FireClient(player, {
				StageKey = stageKey,
				GhostData = ghostData,
			})
		end
	end
end

-- ============================================================================
-- QUERIES
-- ============================================================================
function SpeedrunService.GetActiveRun(player)
	return ActiveRuns[player.UserId]
end

function SpeedrunService.IsInRun(player)
	return ActiveRuns[player.UserId] ~= nil
end

-- ============================================================================
-- UTILITY
-- ============================================================================
function SpeedrunService._Notify(player, message)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local notif = re:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Message = message })
		end
	end
end

return SpeedrunService
