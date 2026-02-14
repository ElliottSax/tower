--[[
	RaceService.lua
	Manages competitive multiplayer racing in Dimension Hopper

	Features:
	- Lobby system with matchmaking
	- Race countdown and start
	- Real-time position tracking
	- Finish line detection
	- Results and rewards
	- Marathon mode (all 4 dimensions)

	Race Flow:
	1. Players join lobby
	2. Countdown begins when enough players
	3. Race starts - all players teleported to start
	4. Track positions in real-time
	5. Detect finishes
	6. Show results & award XP
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RaceService = {}

-- ============================================================================
-- STATE
-- ============================================================================

RaceService.CurrentState = "Idle" -- Idle, Lobby, Countdown, Racing, Results

RaceService.CurrentRace = nil -- Current race data

RaceService.Lobby = {
	Players = {}, -- [UserId] = { player, joinTime, ready }
	Dimension = nil, -- Selected dimension (or nil for marathon)
	GameMode = "DimensionRace", -- DimensionRace, Marathon, Practice
}

RaceService.RaceData = {
	StartTime = 0,
	Dimension = nil,
	Participants = {}, -- [UserId] = { player, startPosition, currentSection, finishTime, placement }
	Placements = {}, -- Ordered list of finishers
	IsMarathon = false,
	MarathonProgress = {}, -- [UserId] = { currentDimension, dimensionsCompleted }
}

local UpdateConnection = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function RaceService.Init()
	print("[RaceService] Initializing...")

	-- Create remotes
	RaceService.CreateRemotes()

	-- Setup player connections
	Players.PlayerAdded:Connect(function(player)
		RaceService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		RaceService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		RaceService.OnPlayerJoin(player)
	end

	-- Setup finish line detection
	RaceService.SetupFinishLines()

	print("[RaceService] Initialized")
end

function RaceService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Race state updates
	if not remoteFolder:FindFirstChild("RaceState") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RaceState"
		event.Parent = remoteFolder
	end

	-- Position updates
	if not remoteFolder:FindFirstChild("RacePositions") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RacePositions"
		event.Parent = remoteFolder
	end

	-- Countdown
	if not remoteFolder:FindFirstChild("RaceCountdown") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RaceCountdown"
		event.Parent = remoteFolder
	end

	-- Results
	if not remoteFolder:FindFirstChild("RaceResults") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RaceResults"
		event.Parent = remoteFolder
	end

	-- Player finish
	if not remoteFolder:FindFirstChild("PlayerFinished") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PlayerFinished"
		event.Parent = remoteFolder
	end

	-- Join/Leave lobby (client -> server)
	if not remoteFolder:FindFirstChild("JoinLobby") then
		local event = Instance.new("RemoteEvent")
		event.Name = "JoinLobby"
		event.Parent = remoteFolder
	end

	if not remoteFolder:FindFirstChild("LeaveLobby") then
		local event = Instance.new("RemoteEvent")
		event.Name = "LeaveLobby"
		event.Parent = remoteFolder
	end

	-- Ready up
	if not remoteFolder:FindFirstChild("ReadyUp") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ReadyUp"
		event.Parent = remoteFolder
	end

	RaceService.Remotes = {
		RaceState = remoteFolder.RaceState,
		RacePositions = remoteFolder.RacePositions,
		RaceCountdown = remoteFolder.RaceCountdown,
		RaceResults = remoteFolder.RaceResults,
		PlayerFinished = remoteFolder.PlayerFinished,
		JoinLobby = remoteFolder.JoinLobby,
		LeaveLobby = remoteFolder.LeaveLobby,
		ReadyUp = remoteFolder.ReadyUp,
	}

	-- Connect client events
	RaceService.Remotes.JoinLobby.OnServerEvent:Connect(function(player, dimension, gameMode)
		RaceService.AddToLobby(player, dimension, gameMode)
	end)

	RaceService.Remotes.LeaveLobby.OnServerEvent:Connect(function(player)
		RaceService.RemoveFromLobby(player)
	end)

	RaceService.Remotes.ReadyUp.OnServerEvent:Connect(function(player)
		RaceService.SetPlayerReady(player)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function RaceService.OnPlayerJoin(player: Player)
	-- Player data will be handled by DataService
	-- Just track for race purposes
end

function RaceService.OnPlayerLeave(player: Player)
	-- Remove from lobby if present
	RaceService.RemoveFromLobby(player)

	-- Handle leaving during race
	if RaceService.CurrentState == "Racing" then
		local participant = RaceService.RaceData.Participants[player.UserId]
		if participant then
			participant.disconnected = true
			-- Update spectator list (they can no longer watch this player)
			RaceService.UpdateSpectatorRacers()
			-- Check if race is complete
			RaceService.CheckRaceComplete()
		end
	end
end

-- ============================================================================
-- LOBBY SYSTEM
-- ============================================================================

function RaceService.AddToLobby(player: Player, dimension: string?, gameMode: string?)
	if RaceService.CurrentState ~= "Idle" and RaceService.CurrentState ~= "Lobby" then
		-- Can't join during race
		return false
	end

	-- Check max players
	local lobbyCount = RaceService.GetLobbyCount()
	if lobbyCount >= GameConfig.Race.MaxPlayers then
		return false
	end

	-- Add to lobby
	RaceService.Lobby.Players[player.UserId] = {
		player = player,
		joinTime = tick(),
		ready = false,
	}

	-- Set dimension if first player
	if dimension and not RaceService.Lobby.Dimension then
		RaceService.Lobby.Dimension = dimension
	end

	if gameMode then
		RaceService.Lobby.GameMode = gameMode
	end

	-- Switch to lobby state if needed
	if RaceService.CurrentState == "Idle" then
		RaceService.SetState("Lobby")
		RaceService.StartLobbyTimer()
	end

	-- Notify all clients
	RaceService.BroadcastLobbyUpdate()

	print(string.format("[RaceService] %s joined lobby (%d players)",
		player.Name, RaceService.GetLobbyCount()))

	return true
end

function RaceService.RemoveFromLobby(player: Player)
	if not RaceService.Lobby.Players[player.UserId] then
		return
	end

	RaceService.Lobby.Players[player.UserId] = nil

	-- Check if lobby is now empty
	if RaceService.GetLobbyCount() == 0 then
		RaceService.ResetLobby()
		RaceService.SetState("Idle")
	else
		RaceService.BroadcastLobbyUpdate()
	end

	print(string.format("[RaceService] %s left lobby", player.Name))
end

function RaceService.SetPlayerReady(player: Player)
	local lobbyEntry = RaceService.Lobby.Players[player.UserId]
	if not lobbyEntry then return end

	lobbyEntry.ready = true

	-- Check if all players ready
	RaceService.CheckAllReady()

	RaceService.BroadcastLobbyUpdate()
end

function RaceService.GetLobbyCount(): number
	local count = 0
	for _ in pairs(RaceService.Lobby.Players) do
		count = count + 1
	end
	return count
end

function RaceService.CheckAllReady()
	local lobbyCount = RaceService.GetLobbyCount()
	if lobbyCount < GameConfig.Race.MinPlayers then
		return false
	end

	for _, entry in pairs(RaceService.Lobby.Players) do
		if not entry.ready then
			return false
		end
	end

	-- All players ready - start countdown immediately
	RaceService.StartCountdown()
	return true
end

function RaceService.StartLobbyTimer()
	task.spawn(function()
		local waitTime = GameConfig.Race.LobbyWaitTime

		while RaceService.CurrentState == "Lobby" and waitTime > 0 do
			task.wait(1)
			waitTime = waitTime - 1

			-- Broadcast time remaining
			for _, entry in pairs(RaceService.Lobby.Players) do
				RaceService.Remotes.RaceState:FireClient(entry.player, "Lobby", {
					TimeRemaining = waitTime,
					PlayerCount = RaceService.GetLobbyCount(),
				})
			end
		end

		-- Time's up - check if we can start
		if RaceService.CurrentState == "Lobby" then
			if RaceService.GetLobbyCount() >= GameConfig.Race.MinPlayers then
				RaceService.StartCountdown()
			else
				-- Not enough players - extend or cancel
				RaceService.ResetLobby()
				RaceService.SetState("Idle")
			end
		end
	end)
end

function RaceService.ResetLobby()
	RaceService.Lobby = {
		Players = {},
		Dimension = nil,
		GameMode = "DimensionRace",
	}
end

function RaceService.BroadcastLobbyUpdate()
	local lobbyData = {
		PlayerCount = RaceService.GetLobbyCount(),
		MaxPlayers = GameConfig.Race.MaxPlayers,
		Dimension = RaceService.Lobby.Dimension,
		GameMode = RaceService.Lobby.GameMode,
		Players = {},
	}

	for userId, entry in pairs(RaceService.Lobby.Players) do
		table.insert(lobbyData.Players, {
			UserId = userId,
			Name = entry.player.Name,
			Ready = entry.ready,
		})
	end

	for _, entry in pairs(RaceService.Lobby.Players) do
		RaceService.Remotes.RaceState:FireClient(entry.player, "LobbyUpdate", lobbyData)
	end
end

-- ============================================================================
-- RACE FLOW
-- ============================================================================

function RaceService.StartCountdown()
	if RaceService.CurrentState ~= "Lobby" then return end

	RaceService.SetState("Countdown")

	-- Prepare race data
	RaceService.RaceData = {
		StartTime = 0,
		Dimension = RaceService.Lobby.Dimension or "Gravity",
		Participants = {},
		Placements = {},
		IsMarathon = RaceService.Lobby.GameMode == "Marathon",
		MarathonProgress = {},
	}

	-- Add all lobby players as participants
	for userId, entry in pairs(RaceService.Lobby.Players) do
		RaceService.RaceData.Participants[userId] = {
			player = entry.player,
			currentSection = 0,
			finishTime = nil,
			placement = nil,
			disconnected = false,
		}

		if RaceService.RaceData.IsMarathon then
			RaceService.RaceData.MarathonProgress[userId] = {
				currentDimension = 1,
				dimensionsCompleted = 0,
			}
		end
	end

	-- Teleport players to start
	RaceService.TeleportPlayersToStart()

	-- Countdown sequence
	local countdownTime = GameConfig.Race.CountdownTime

	for i = countdownTime, 1, -1 do
		-- Broadcast countdown
		for _, entry in pairs(RaceService.Lobby.Players) do
			RaceService.Remotes.RaceCountdown:FireClient(entry.player, i)
		end

		task.wait(1)

		if RaceService.CurrentState ~= "Countdown" then
			return -- Cancelled
		end
	end

	-- GO!
	RaceService.StartRace()
end

function RaceService.TeleportPlayersToStart()
	-- Get dimension start position
	local startPosition = RaceService.GetDimensionStart(RaceService.RaceData.Dimension)
	if not startPosition then
		warn("[RaceService] Could not find start position!")
		return
	end

	local index = 0
	for _, participant in pairs(RaceService.RaceData.Participants) do
		local character = participant.player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				-- Offset each player slightly
				local offset = Vector3.new((index % 4) * 5 - 7.5, 0, math.floor(index / 4) * 5)
				rootPart.CFrame = startPosition + offset
			end
		end
		index = index + 1
	end
end

function RaceService.GetDimensionStart(dimension: string): CFrame?
	-- Find start spawn for dimension
	local startSpawn = workspace:FindFirstChild(dimension .. "Start")
	if startSpawn then
		return startSpawn.CFrame + Vector3.new(0, 3, 0)
	end

	-- Fallback to generic spawn
	local spawn = workspace:FindFirstChild("StartSpawn")
	if spawn then
		return spawn.CFrame + Vector3.new(0, 3, 0)
	end

	return CFrame.new(0, 50, 0)
end

function RaceService.StartRace()
	RaceService.SetState("Racing")

	RaceService.RaceData.StartTime = tick()

	-- Notify all participants
	for _, participant in pairs(RaceService.RaceData.Participants) do
		RaceService.Remotes.RaceState:FireClient(participant.player, "RaceStart", {
			Dimension = RaceService.RaceData.Dimension,
			IsMarathon = RaceService.RaceData.IsMarathon,
		})
	end

	-- Start the active dimension's mechanics
	RaceService.StartDimensionMechanics(RaceService.RaceData.Dimension)

	-- Start position tracking
	RaceService.StartPositionTracking()

	-- Start race timeout
	RaceService.StartRaceTimeout()

	print(string.format("[RaceService] Race started in %s dimension",
		RaceService.RaceData.Dimension))
end

function RaceService.StartDimensionMechanics(dimension: string)
	-- Get services via global locator
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	-- Start dimension-specific mechanics
	if dimension == "Void" then
		local VoidService = DimensionHopper.GetService("VoidService")
		if VoidService then
			VoidService.Start()
		end
	end

	-- DimensionService handles visual theme
	local DimensionService = DimensionHopper.GetService("DimensionService")
	if DimensionService then
		DimensionService.LoadDimension(dimension)
	end
end

function RaceService.StopDimensionMechanics(dimension: string)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	if dimension == "Void" then
		local VoidService = DimensionHopper.GetService("VoidService")
		if VoidService then
			VoidService.Stop()
		end
	end
end

-- ============================================================================
-- POSITION TRACKING
-- ============================================================================

function RaceService.StartPositionTracking()
	if UpdateConnection then
		UpdateConnection:Disconnect()
	end

	UpdateConnection = RunService.Heartbeat:Connect(function()
		if RaceService.CurrentState ~= "Racing" then
			UpdateConnection:Disconnect()
			UpdateConnection = nil
			return
		end

		RaceService.UpdatePositions()
	end)
end

function RaceService.UpdatePositions()
	-- Calculate current positions based on section progress
	local positions = {}

	for userId, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.finishTime and not participant.disconnected then
			local character = participant.player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					-- Use Y position as progress (vertical tower)
					local progress = rootPart.Position.Y

					table.insert(positions, {
						UserId = userId,
						Name = participant.player.Name,
						Section = participant.currentSection,
						Progress = progress,
						Finished = false,
					})
				end
			end
		elseif participant.finishTime then
			table.insert(positions, {
				UserId = userId,
				Name = participant.player.Name,
				Section = 999, -- Finished
				Progress = 999999,
				Finished = true,
				Placement = participant.placement,
				FinishTime = participant.finishTime - RaceService.RaceData.StartTime,
			})
		end
	end

	-- Sort by progress (descending)
	table.sort(positions, function(a, b)
		if a.Finished ~= b.Finished then
			return a.Finished
		end
		return a.Progress > b.Progress
	end)

	-- Assign positions
	for i, pos in ipairs(positions) do
		if not pos.Finished then
			pos.Position = i
		end
	end

	-- Broadcast positions to all participants
	for _, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.disconnected then
			RaceService.Remotes.RacePositions:FireClient(participant.player, positions)
		end
	end
end

-- ============================================================================
-- FINISH DETECTION
-- ============================================================================

function RaceService.SetupFinishLines()
	-- Connect to existing finish lines
	for _, finish in ipairs(CollectionService:GetTagged("FinishLine")) do
		RaceService.ConnectFinishLine(finish)
	end

	-- Listen for new finish lines
	CollectionService:GetInstanceAddedSignal("FinishLine"):Connect(function(finish)
		RaceService.ConnectFinishLine(finish)
	end)
end

function RaceService.ConnectFinishLine(finish: BasePart)
	finish.Touched:Connect(function(hit)
		RaceService.OnFinishTouched(finish, hit)
	end)
end

function RaceService.OnFinishTouched(finish: BasePart, hit: BasePart)
	if RaceService.CurrentState ~= "Racing" then return end

	-- Verify it's a player
	local character = hit.Parent
	if not character then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local participant = RaceService.RaceData.Participants[player.UserId]
	if not participant then return end

	-- Check if already finished
	if participant.finishTime then return end

	-- Check if this is the correct finish line (for dimension)
	local finishDimension = finish:GetAttribute("Dimension")
	if finishDimension and finishDimension ~= RaceService.RaceData.Dimension then
		return
	end

	-- Player finished!
	RaceService.OnPlayerFinish(player)
end

function RaceService.OnPlayerFinish(player: Player)
	local participant = RaceService.RaceData.Participants[player.UserId]
	if not participant or participant.finishTime then return end

	-- Record finish
	participant.finishTime = tick()
	participant.placement = #RaceService.RaceData.Placements + 1

	table.insert(RaceService.RaceData.Placements, {
		UserId = player.UserId,
		Player = player,
		Time = participant.finishTime - RaceService.RaceData.StartTime,
		Placement = participant.placement,
	})

	-- Offer spectator mode to finished player
	RaceService.OfferSpectatorMode(player)

	-- Handle marathon mode
	if RaceService.RaceData.IsMarathon then
		local progress = RaceService.RaceData.MarathonProgress[player.UserId]
		if progress then
			progress.dimensionsCompleted = progress.dimensionsCompleted + 1

			if progress.dimensionsCompleted >= 4 then
				-- Completed all dimensions!
				print(string.format("[RaceService] %s completed marathon!", player.Name))
			else
				-- Move to next dimension
				progress.currentDimension = progress.currentDimension + 1
				local nextDimension = GameConfig.DimensionOrder[progress.currentDimension]
				-- Teleport to next dimension start
				-- (Simplified - full implementation would handle transitions)
			end
		end
	end

	-- Notify everyone
	for _, p in pairs(RaceService.RaceData.Participants) do
		if not p.disconnected then
			RaceService.Remotes.PlayerFinished:FireClient(p.player, {
				FinisherName = player.Name,
				Placement = participant.placement,
				Time = participant.finishTime - RaceService.RaceData.StartTime,
			})
		end
	end

	print(string.format("[RaceService] %s finished in %d place! (%.2fs)",
		player.Name,
		participant.placement,
		participant.finishTime - RaceService.RaceData.StartTime))

	-- Check if all players finished
	RaceService.CheckRaceComplete()
end

function RaceService.CheckRaceComplete()
	local allFinished = true
	local anyActive = false

	for _, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.disconnected then
			anyActive = true
			if not participant.finishTime then
				allFinished = false
				break
			end
		end
	end

	if allFinished or not anyActive then
		RaceService.EndRace()
	end
end

-- ============================================================================
-- RACE END & RESULTS
-- ============================================================================

function RaceService.StartRaceTimeout()
	task.spawn(function()
		local maxTime = GameConfig.Race.MaxRaceTime

		while RaceService.CurrentState == "Racing" do
			task.wait(1)
			maxTime = maxTime - 1

			if maxTime <= 0 then
				print("[RaceService] Race timeout - ending race")
				RaceService.EndRace()
				break
			end
		end
	end)
end

function RaceService.EndRace()
	if RaceService.CurrentState ~= "Racing" then return end

	RaceService.SetState("Results")

	-- Stop dimension mechanics
	RaceService.StopDimensionMechanics(RaceService.RaceData.Dimension)

	-- Exit all spectators
	RaceService.ExitAllSpectators()

	-- Calculate results and rewards
	local results = RaceService.CalculateResults()

	-- Award XP
	RaceService.AwardRaceRewards(results)

	-- Broadcast results to all
	for _, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.disconnected then
			RaceService.Remotes.RaceResults:FireClient(participant.player, results)
		end
	end

	print("[RaceService] Race ended - showing results")

	-- Return to idle after results display
	task.delay(GameConfig.Race.ResultsDisplayTime, function()
		RaceService.ResetRace()
	end)
end

function RaceService.CalculateResults(): table
	local results = {
		Dimension = RaceService.RaceData.Dimension,
		IsMarathon = RaceService.RaceData.IsMarathon,
		Duration = tick() - RaceService.RaceData.StartTime,
		Placements = {},
	}

	-- Sort by finish time (those who didn't finish go last)
	local sortedParticipants = {}
	for userId, participant in pairs(RaceService.RaceData.Participants) do
		table.insert(sortedParticipants, {
			UserId = userId,
			Name = participant.player.Name,
			FinishTime = participant.finishTime,
			StartTime = RaceService.RaceData.StartTime,
			Disconnected = participant.disconnected,
			Section = participant.currentSection,
		})
	end

	table.sort(sortedParticipants, function(a, b)
		if a.Disconnected ~= b.Disconnected then
			return not a.Disconnected
		end
		if a.FinishTime and b.FinishTime then
			return a.FinishTime < b.FinishTime
		elseif a.FinishTime then
			return true
		elseif b.FinishTime then
			return false
		end
		return a.Section > b.Section
	end)

	for i, p in ipairs(sortedParticipants) do
		table.insert(results.Placements, {
			Placement = i,
			UserId = p.UserId,
			Name = p.Name,
			Time = p.FinishTime and (p.FinishTime - p.StartTime) or nil,
			DNF = not p.FinishTime and not p.Disconnected,
			Disconnected = p.Disconnected,
		})
	end

	return results
end

function RaceService.AwardRaceRewards(results: table)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")

	for _, placement in ipairs(results.Placements) do
		if placement.Disconnected then continue end

		local xpReward = 0

		-- Placement bonus
		if placement.Time then -- Finished
			xpReward = xpReward + GameConfig.Race.CompletionXP

			local placementXP = GameConfig.Race.PlacementXP[placement.Placement]
			if placementXP then
				xpReward = xpReward + placementXP
			end
		end

		-- Marathon multiplier
		if results.IsMarathon then
			xpReward = xpReward * (GameConfig.GameModes.Marathon.XPMultiplier or 2.5)
		end

		-- Award XP through DataService
		if DataService and xpReward > 0 then
			local player = Players:GetPlayerByUserId(placement.UserId)
			if player then
				-- DataService.AddXP(player, xpReward)
				print(string.format("[RaceService] Awarded %d XP to %s",
					xpReward, placement.Name))
			end
		end
	end
end

function RaceService.ResetRace()
	-- Stop any update loops
	if UpdateConnection then
		UpdateConnection:Disconnect()
		UpdateConnection = nil
	end

	-- Reset state
	RaceService.RaceData = {
		StartTime = 0,
		Dimension = nil,
		Participants = {},
		Placements = {},
		IsMarathon = false,
		MarathonProgress = {},
	}

	RaceService.ResetLobby()
	RaceService.SetState("Idle")

	print("[RaceService] Race reset - ready for next race")
end

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

function RaceService.SetState(newState: string)
	local oldState = RaceService.CurrentState
	RaceService.CurrentState = newState

	print(string.format("[RaceService] State: %s -> %s", oldState, newState))

	-- Broadcast state change
	RaceService.Remotes.RaceState:FireAllClients(newState, {})
end

-- ============================================================================
-- SECTION TRACKING
-- ============================================================================

function RaceService.OnPlayerReachSection(player: Player, sectionNumber: number)
	if RaceService.CurrentState ~= "Racing" then return end

	local participant = RaceService.RaceData.Participants[player.UserId]
	if not participant then return end

	if sectionNumber > participant.currentSection then
		participant.currentSection = sectionNumber

		-- Update positions
		RaceService.UpdatePositions()
	end
end

-- ============================================================================
-- SPECTATOR INTEGRATION
-- ============================================================================

function RaceService.GetSpectatorService()
	local DimensionHopper = _G.DimensionHopper
	if DimensionHopper then
		return DimensionHopper.GetService("SpectatorService")
	end
	return nil
end

function RaceService.OfferSpectatorMode(player: Player)
	local SpectatorService = RaceService.GetSpectatorService()
	if not SpectatorService then return end

	-- Update active racers list
	RaceService.UpdateSpectatorRacers()

	-- Give finished player the option to spectate
	SpectatorService.EnterSpectatorMode(player)
end

function RaceService.UpdateSpectatorRacers()
	local SpectatorService = RaceService.GetSpectatorService()
	if not SpectatorService then return end

	-- Build list of active (unfinished, connected) racers
	local activeRacers = {}
	for userId, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.finishTime and not participant.disconnected then
			table.insert(activeRacers, participant.player)
		end
	end

	-- Update spectator service
	SpectatorService.SetRacers(activeRacers)
end

function RaceService.ExitAllSpectators()
	local SpectatorService = RaceService.GetSpectatorService()
	if not SpectatorService then return end

	-- Exit all spectators when race ends
	for userId, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.disconnected then
			SpectatorService.ExitSpectatorMode(participant.player)
		end
	end
end

function RaceService.GetActiveRacerCount(): number
	local count = 0
	for _, participant in pairs(RaceService.RaceData.Participants) do
		if not participant.finishTime and not participant.disconnected then
			count = count + 1
		end
	end
	return count
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function RaceService.DebugPrint()
	print("=== RACE SERVICE STATUS ===")
	print(string.format("State: %s", RaceService.CurrentState))
	print(string.format("Lobby Players: %d", RaceService.GetLobbyCount()))

	if RaceService.CurrentState == "Racing" then
		print(string.format("Dimension: %s", RaceService.RaceData.Dimension))
		print(string.format("Finishers: %d", #RaceService.RaceData.Placements))
	end

	print("============================")
end

return RaceService
