--[[
	GhostService.lua
	Manages ghost racing - racing against recorded runs

	Features:
	- Record player positions during races
	- Save personal best ghosts
	- Replay ghosts as transparent characters
	- Compare against friends/global bests
	- Ghost data compression
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GhostService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local RECORD_INTERVAL = 0.1 -- Record position every 100ms
local MAX_GHOST_DURATION = 600 -- 10 minutes max
local GHOST_TRANSPARENCY = 0.6

-- ============================================================================
-- STATE
-- ============================================================================

-- Active recordings: [UserId] = { dimension, startTime, frames = {} }
GhostService.ActiveRecordings = {}

-- Saved ghosts: [UserId] = { [dimension] = ghostData }
GhostService.PlayerGhosts = {}

-- Active ghost replays: [playerId] = { ghostModel, currentFrame, connection }
GhostService.ActiveReplays = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function GhostService.Init()
	print("[GhostService] Initializing...")

	GhostService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		GhostService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		GhostService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		GhostService.OnPlayerJoin(player)
	end

	print("[GhostService] Initialized")
end

function GhostService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Start/stop ghost
	if not remoteFolder:FindFirstChild("ToggleGhost") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ToggleGhost"
		event.Parent = remoteFolder
	end

	-- Get ghost list
	if not remoteFolder:FindFirstChild("GetGhosts") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetGhosts"
		func.Parent = remoteFolder
	end

	-- Ghost sync (for client-side playback)
	if not remoteFolder:FindFirstChild("GhostSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "GhostSync"
		event.Parent = remoteFolder
	end

	GhostService.Remotes = {
		ToggleGhost = remoteFolder.ToggleGhost,
		GetGhosts = remoteFolder.GetGhosts,
		GhostSync = remoteFolder.GhostSync,
	}

	GhostService.Remotes.ToggleGhost.OnServerEvent:Connect(function(player, dimension, enable)
		if enable then
			GhostService.StartGhostReplay(player, dimension)
		else
			GhostService.StopGhostReplay(player)
		end
	end)

	GhostService.Remotes.GetGhosts.OnServerInvoke = function(player)
		return GhostService.GetPlayerGhostList(player)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function GhostService.OnPlayerJoin(player: Player)
	GhostService.PlayerGhosts[player.UserId] = {}
	GhostService.LoadPlayerGhosts(player)
end

function GhostService.OnPlayerLeave(player: Player)
	-- Stop any active recording
	GhostService.StopRecording(player)

	-- Stop any active replay
	GhostService.StopGhostReplay(player)

	-- Save ghosts
	GhostService.SavePlayerGhosts(player)

	GhostService.PlayerGhosts[player.UserId] = nil
end

function GhostService.LoadPlayerGhosts(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data and data.Ghosts then
		GhostService.PlayerGhosts[player.UserId] = data.Ghosts
	end
end

function GhostService.SavePlayerGhosts(player: Player)
	local ghosts = GhostService.PlayerGhosts[player.UserId]
	if not ghosts then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			Ghosts = ghosts,
		})
	end
end

-- ============================================================================
-- RECORDING
-- ============================================================================

function GhostService.StartRecording(player: Player, dimension: string)
	-- Stop any existing recording
	GhostService.StopRecording(player)

	local character = player.Character
	if not character then return end

	local recording = {
		dimension = dimension,
		startTime = tick(),
		frames = {},
		connection = nil,
	}

	-- Record frames
	recording.connection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			GhostService.StopRecording(player)
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local elapsed = tick() - recording.startTime

		-- Check max duration
		if elapsed > MAX_GHOST_DURATION then
			GhostService.StopRecording(player)
			return
		end

		-- Only record at interval
		local lastFrame = recording.frames[#recording.frames]
		if lastFrame and (elapsed - lastFrame.t) < RECORD_INTERVAL then
			return
		end

		-- Record frame (compressed format)
		table.insert(recording.frames, {
			t = elapsed, -- time
			p = { -- position (rounded to save space)
				math.floor(rootPart.Position.X * 10) / 10,
				math.floor(rootPart.Position.Y * 10) / 10,
				math.floor(rootPart.Position.Z * 10) / 10,
			},
			r = math.floor(math.deg(rootPart.Orientation.Y)), -- rotation (Y only)
		})
	end)

	GhostService.ActiveRecordings[player.UserId] = recording

	print(string.format("[GhostService] Started recording for %s in %s", player.Name, dimension))
end

function GhostService.StopRecording(player: Player): table?
	local recording = GhostService.ActiveRecordings[player.UserId]
	if not recording then return nil end

	if recording.connection then
		recording.connection:Disconnect()
	end

	GhostService.ActiveRecordings[player.UserId] = nil

	local duration = tick() - recording.startTime

	print(string.format("[GhostService] Stopped recording for %s: %d frames, %.2fs",
		player.Name, #recording.frames, duration))

	return {
		dimension = recording.dimension,
		duration = duration,
		frameCount = #recording.frames,
		frames = recording.frames,
	}
end

function GhostService.SaveGhost(player: Player, ghostData: table, time: number)
	local dimension = ghostData.dimension
	local existingGhost = GhostService.PlayerGhosts[player.UserId][dimension]

	-- Only save if it's a new personal best
	if existingGhost and existingGhost.time <= time then
		return false
	end

	GhostService.PlayerGhosts[player.UserId][dimension] = {
		time = time,
		frames = ghostData.frames,
		recordedAt = os.time(),
	}

	print(string.format("[GhostService] Saved ghost for %s in %s: %.2fs",
		player.Name, dimension, time))

	return true
end

-- ============================================================================
-- REPLAY
-- ============================================================================

function GhostService.StartGhostReplay(player: Player, dimension: string)
	-- Stop any existing replay
	GhostService.StopGhostReplay(player)

	local ghostData = GhostService.PlayerGhosts[player.UserId][dimension]
	if not ghostData or not ghostData.frames or #ghostData.frames == 0 then
		warn("[GhostService] No ghost data for " .. dimension)
		return false
	end

	-- Create ghost model
	local ghostModel = GhostService.CreateGhostModel(player, dimension)
	if not ghostModel then return false end

	local replay = {
		ghostModel = ghostModel,
		frames = ghostData.frames,
		startTime = tick(),
		currentFrame = 1,
		connection = nil,
	}

	-- Replay loop
	replay.connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - replay.startTime

		-- Find the right frame
		while replay.currentFrame < #replay.frames do
			local nextFrame = replay.frames[replay.currentFrame + 1]
			if nextFrame and nextFrame.t <= elapsed then
				replay.currentFrame = replay.currentFrame + 1
			else
				break
			end
		end

		local frame = replay.frames[replay.currentFrame]
		if not frame then
			GhostService.StopGhostReplay(player)
			return
		end

		-- Update ghost position
		local rootPart = ghostModel:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.CFrame = CFrame.new(frame.p[1], frame.p[2], frame.p[3])
				* CFrame.Angles(0, math.rad(frame.r), 0)
		end

		-- Check if replay finished
		if replay.currentFrame >= #replay.frames then
			-- Loop or stop
			replay.startTime = tick()
			replay.currentFrame = 1
		end
	end)

	GhostService.ActiveReplays[player.UserId] = replay

	-- Notify client
	GhostService.Remotes.GhostSync:FireClient(player, {
		action = "start",
		dimension = dimension,
		time = ghostData.time,
	})

	print(string.format("[GhostService] Started ghost replay for %s in %s", player.Name, dimension))
	return true
end

function GhostService.StopGhostReplay(player: Player)
	local replay = GhostService.ActiveReplays[player.UserId]
	if not replay then return end

	if replay.connection then
		replay.connection:Disconnect()
	end

	if replay.ghostModel then
		replay.ghostModel:Destroy()
	end

	GhostService.ActiveReplays[player.UserId] = nil

	-- Notify client
	GhostService.Remotes.GhostSync:FireClient(player, {
		action = "stop",
	})

	print(string.format("[GhostService] Stopped ghost replay for %s", player.Name))
end

function GhostService.CreateGhostModel(player: Player, dimension: string): Model?
	-- Create a simple ghost representation
	local ghost = Instance.new("Model")
	ghost.Name = "Ghost_" .. player.Name

	-- Root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = GHOST_TRANSPARENCY
	rootPart.CanCollide = false
	rootPart.Anchored = true
	rootPart.Material = Enum.Material.ForceField
	rootPart.Color = Color3.fromRGB(150, 150, 255)
	rootPart.Parent = ghost

	ghost.PrimaryPart = rootPart

	-- Body parts for visual
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Transparency = GHOST_TRANSPARENCY
	torso.CanCollide = false
	torso.Anchored = true
	torso.Material = Enum.Material.ForceField
	torso.Color = Color3.fromRGB(150, 150, 255)
	torso.Parent = ghost

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Shape = Enum.PartType.Ball
	head.Transparency = GHOST_TRANSPARENCY
	head.CanCollide = false
	head.Anchored = true
	head.Material = Enum.Material.ForceField
	head.Color = Color3.fromRGB(200, 200, 255)
	head.Parent = ghost

	-- Weld parts together
	local torsoWeld = Instance.new("WeldConstraint")
	torsoWeld.Part0 = rootPart
	torsoWeld.Part1 = torso
	torsoWeld.Parent = rootPart

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = rootPart
	headWeld.Part1 = head
	headWeld.Parent = rootPart

	-- Position parts
	torso.Position = rootPart.Position
	head.Position = rootPart.Position + Vector3.new(0, 1.5, 0)

	-- Ghost label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = head
	billboard.Parent = ghost

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(150, 150, 255)
	label.TextStrokeTransparency = 0.5
	label.Text = "GHOST"
	label.Parent = billboard

	-- Parent to workspace
	ghost.Parent = workspace

	return ghost
end

-- ============================================================================
-- API
-- ============================================================================

function GhostService.GetPlayerGhostList(player: Player): table
	local ghosts = GhostService.PlayerGhosts[player.UserId]
	if not ghosts then return {} end

	local list = {}
	for dimension, data in pairs(ghosts) do
		table.insert(list, {
			dimension = dimension,
			time = data.time,
			recordedAt = data.recordedAt,
			frameCount = data.frames and #data.frames or 0,
		})
	end

	return list
end

function GhostService.HasGhost(player: Player, dimension: string): boolean
	local ghosts = GhostService.PlayerGhosts[player.UserId]
	return ghosts and ghosts[dimension] ~= nil
end

function GhostService.GetGhostTime(player: Player, dimension: string): number?
	local ghosts = GhostService.PlayerGhosts[player.UserId]
	if ghosts and ghosts[dimension] then
		return ghosts[dimension].time
	end
	return nil
end

-- ============================================================================
-- RACE INTEGRATION
-- ============================================================================

function GhostService.OnRaceStart(player: Player, dimension: string)
	GhostService.StartRecording(player, dimension)
end

function GhostService.OnRaceComplete(player: Player, time: number)
	local ghostData = GhostService.StopRecording(player)
	if ghostData then
		GhostService.SaveGhost(player, ghostData, time)
	end
end

function GhostService.OnRaceCancel(player: Player)
	GhostService.StopRecording(player)
end

return GhostService
