--[[
	MatchmakingService.lua
	Handles matchmaking and race queuing

	Features:
	- Queue players for races
	- Party-aware matchmaking
	- Dimension preferences
	- Skill-based matching (optional)
	- Auto-start when enough players
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchmakingService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MIN_PLAYERS = 2
local MAX_PLAYERS = 8
local QUEUE_TIMEOUT = 60 -- Start with fewer if waiting too long
local COUNTDOWN_TIME = 10

-- ============================================================================
-- STATE
-- ============================================================================

-- Queue entries: [userId] = { joinTime, dimension, partyId, skill }
MatchmakingService.Queue = {}

-- Active matches: [matchId] = { players, dimension, status, countdown }
MatchmakingService.ActiveMatches = {}

local nextMatchId = 1
local queueCheckRunning = false

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MatchmakingService.Init()
	print("[MatchmakingService] Initializing...")

	MatchmakingService.CreateRemotes()

	Players.PlayerRemoving:Connect(function(player)
		MatchmakingService.LeaveQueue(player)
	end)

	-- Start queue processor
	task.spawn(function()
		queueCheckRunning = true
		while queueCheckRunning do
			task.wait(1)
			MatchmakingService.ProcessQueue()
			MatchmakingService.UpdateCountdowns()
		end
	end)

	print("[MatchmakingService] Initialized")
end

function MatchmakingService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Join queue
	if not remoteFolder:FindFirstChild("JoinQueue") then
		local event = Instance.new("RemoteEvent")
		event.Name = "JoinQueue"
		event.Parent = remoteFolder
	end

	-- Leave queue
	if not remoteFolder:FindFirstChild("LeaveQueue") then
		local event = Instance.new("RemoteEvent")
		event.Name = "LeaveQueue"
		event.Parent = remoteFolder
	end

	-- Queue status update
	if not remoteFolder:FindFirstChild("QueueStatusUpdate") then
		local event = Instance.new("RemoteEvent")
		event.Name = "QueueStatusUpdate"
		event.Parent = remoteFolder
	end

	-- Match found
	if not remoteFolder:FindFirstChild("MatchFound") then
		local event = Instance.new("RemoteEvent")
		event.Name = "MatchFound"
		event.Parent = remoteFolder
	end

	-- Match countdown
	if not remoteFolder:FindFirstChild("MatchCountdown") then
		local event = Instance.new("RemoteEvent")
		event.Name = "MatchCountdown"
		event.Parent = remoteFolder
	end

	-- Get queue status
	if not remoteFolder:FindFirstChild("GetQueueStatus") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetQueueStatus"
		func.Parent = remoteFolder
	end

	MatchmakingService.Remotes = {
		JoinQueue = remoteFolder.JoinQueue,
		LeaveQueue = remoteFolder.LeaveQueue,
		QueueStatusUpdate = remoteFolder.QueueStatusUpdate,
		MatchFound = remoteFolder.MatchFound,
		MatchCountdown = remoteFolder.MatchCountdown,
		GetQueueStatus = remoteFolder.GetQueueStatus,
	}

	MatchmakingService.Remotes.JoinQueue.OnServerEvent:Connect(function(player, dimension)
		MatchmakingService.JoinQueue(player, dimension)
	end)

	MatchmakingService.Remotes.LeaveQueue.OnServerEvent:Connect(function(player)
		MatchmakingService.LeaveQueue(player)
	end)

	MatchmakingService.Remotes.GetQueueStatus.OnServerInvoke = function(player)
		return MatchmakingService.GetQueueStatus(player)
	end
end

-- ============================================================================
-- QUEUE MANAGEMENT
-- ============================================================================

function MatchmakingService.JoinQueue(player: Player, dimension: string?)
	-- Already in queue?
	if MatchmakingService.Queue[player.UserId] then
		return false
	end

	-- Get player skill (from stats if available)
	local skill = 1000 -- Default MMR
	local DimensionHopper = _G.DimensionHopper
	if DimensionHopper then
		local StatsService = DimensionHopper.GetService("StatsService")
		if StatsService and StatsService.GetPlayerStats then
			local stats = StatsService.GetPlayerStats(player)
			if stats then
				-- Simple skill calculation based on win rate and races
				local races = stats.totalRaces or 0
				local wins = stats.wins or 0
				if races > 0 then
					skill = 1000 + (wins / races) * 500 + math.min(races, 100) * 2
				end
			end
		end
	end

	-- Get party ID if in party
	local partyId = nil
	if DimensionHopper then
		local PartyService = DimensionHopper.GetService("PartyService")
		if PartyService and PartyService.GetPartyId then
			partyId = PartyService.GetPartyId(player)
		end
	end

	MatchmakingService.Queue[player.UserId] = {
		joinTime = os.time(),
		dimension = dimension, -- nil = any dimension
		partyId = partyId,
		skill = skill,
	}

	-- If in party and is leader, queue whole party
	if partyId then
		local PartyService = DimensionHopper.GetService("PartyService")
		if PartyService and PartyService.IsPartyLeader and PartyService.IsPartyLeader(player) then
			local members = PartyService.GetPartyMembers(player)
			for _, member in ipairs(members) do
				if member ~= player and not MatchmakingService.Queue[member.UserId] then
					MatchmakingService.Queue[member.UserId] = {
						joinTime = os.time(),
						dimension = dimension,
						partyId = partyId,
						skill = skill, -- Use leader's skill for party
					}
					MatchmakingService.NotifyQueueStatus(member)
				end
			end
		end
	end

	MatchmakingService.NotifyQueueStatus(player)
	print(string.format("[MatchmakingService] %s joined queue (dimension: %s)", player.Name, dimension or "any"))

	return true
end

function MatchmakingService.LeaveQueue(player: Player)
	if not MatchmakingService.Queue[player.UserId] then
		return
	end

	local queueEntry = MatchmakingService.Queue[player.UserId]
	MatchmakingService.Queue[player.UserId] = nil

	-- If in party and is leader, remove whole party
	if queueEntry.partyId then
		local DimensionHopper = _G.DimensionHopper
		if DimensionHopper then
			local PartyService = DimensionHopper.GetService("PartyService")
			if PartyService and PartyService.IsPartyLeader and PartyService.IsPartyLeader(player) then
				local members = PartyService.GetPartyMembers(player)
				for _, member in ipairs(members) do
					if member ~= player then
						MatchmakingService.Queue[member.UserId] = nil
						MatchmakingService.NotifyQueueStatus(member)
					end
				end
			end
		end
	end

	MatchmakingService.NotifyQueueStatus(player)
	print(string.format("[MatchmakingService] %s left queue", player.Name))
end

function MatchmakingService.NotifyQueueStatus(player: Player)
	local inQueue = MatchmakingService.Queue[player.UserId] ~= nil
	local queueCount = MatchmakingService.GetQueueCount()

	MatchmakingService.Remotes.QueueStatusUpdate:FireClient(player, {
		inQueue = inQueue,
		queueSize = queueCount,
		minPlayers = MIN_PLAYERS,
		maxPlayers = MAX_PLAYERS,
	})
end

function MatchmakingService.GetQueueCount(): number
	local count = 0
	for _ in pairs(MatchmakingService.Queue) do
		count = count + 1
	end
	return count
end

function MatchmakingService.GetQueueStatus(player: Player): table
	local entry = MatchmakingService.Queue[player.UserId]
	return {
		inQueue = entry ~= nil,
		queueSize = MatchmakingService.GetQueueCount(),
		waitTime = entry and (os.time() - entry.joinTime) or 0,
		minPlayers = MIN_PLAYERS,
		maxPlayers = MAX_PLAYERS,
	}
end

-- ============================================================================
-- MATCHMAKING
-- ============================================================================

function MatchmakingService.ProcessQueue()
	local queueCount = MatchmakingService.GetQueueCount()
	if queueCount < MIN_PLAYERS then
		return
	end

	-- Group players by dimension preference
	local dimensionQueues = {
		any = {},
		Gravity = {},
		Tiny = {},
		Void = {},
		Sky = {},
	}

	for userId, entry in pairs(MatchmakingService.Queue) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local dim = entry.dimension or "any"
			if dimensionQueues[dim] then
				table.insert(dimensionQueues[dim], {
					player = player,
					entry = entry,
				})
			else
				table.insert(dimensionQueues.any, {
					player = player,
					entry = entry,
				})
			end
		end
	end

	-- Try to create matches for each dimension
	for dimension, queue in pairs(dimensionQueues) do
		if dimension ~= "any" then
			-- Combine dimension-specific queue with "any" queue
			local combined = {}
			for _, data in ipairs(queue) do
				table.insert(combined, data)
			end
			for _, data in ipairs(dimensionQueues.any) do
				table.insert(combined, data)
			end

			if #combined >= MIN_PLAYERS then
				MatchmakingService.TryCreateMatch(combined, dimension)
			end
		end
	end

	-- Check for timeout - start with fewer players if waiting too long
	local now = os.time()
	for userId, entry in pairs(MatchmakingService.Queue) do
		if now - entry.joinTime > QUEUE_TIMEOUT and queueCount >= 1 then
			-- Force start with available players
			local allPlayers = {}
			for uid, e in pairs(MatchmakingService.Queue) do
				local p = Players:GetPlayerByUserId(uid)
				if p then
					table.insert(allPlayers, { player = p, entry = e })
				end
			end

			if #allPlayers >= 1 then
				local dimension = entry.dimension or MatchmakingService.GetRandomDimension()
				MatchmakingService.CreateMatch(allPlayers, dimension)
			end
			break
		end
	end
end

function MatchmakingService.TryCreateMatch(candidates: table, dimension: string)
	if #candidates < MIN_PLAYERS then
		return false
	end

	-- Sort by skill for better matches (optional)
	table.sort(candidates, function(a, b)
		return a.entry.skill < b.entry.skill
	end)

	-- Take up to MAX_PLAYERS
	local matchPlayers = {}
	local partiesIncluded = {}

	for _, data in ipairs(candidates) do
		if #matchPlayers >= MAX_PLAYERS then
			break
		end

		local partyId = data.entry.partyId

		-- If player is in a party, include whole party
		if partyId and not partiesIncluded[partyId] then
			local DimensionHopper = _G.DimensionHopper
			if DimensionHopper then
				local PartyService = DimensionHopper.GetService("PartyService")
				if PartyService and PartyService.GetPartyMembers then
					local members = PartyService.GetPartyMembers(data.player)
					local canFit = #matchPlayers + #members <= MAX_PLAYERS

					if canFit then
						for _, member in ipairs(members) do
							local found = false
							for _, existing in ipairs(matchPlayers) do
								if existing.player == member then
									found = true
									break
								end
							end
							if not found then
								table.insert(matchPlayers, {
									player = member,
									entry = MatchmakingService.Queue[member.UserId],
								})
							end
						end
						partiesIncluded[partyId] = true
					end
				end
			end
		elseif not partyId then
			-- Solo player
			table.insert(matchPlayers, data)
		end
	end

	if #matchPlayers >= MIN_PLAYERS then
		MatchmakingService.CreateMatch(matchPlayers, dimension)
		return true
	end

	return false
end

function MatchmakingService.CreateMatch(players: table, dimension: string)
	local matchId = tostring(nextMatchId)
	nextMatchId = nextMatchId + 1

	local match = {
		id = matchId,
		dimension = dimension,
		players = {},
		status = "countdown",
		countdown = COUNTDOWN_TIME,
		createdAt = os.time(),
	}

	-- Build player list and remove from queue
	for _, data in ipairs(players) do
		table.insert(match.players, data.player)
		MatchmakingService.Queue[data.player.UserId] = nil
	end

	MatchmakingService.ActiveMatches[matchId] = match

	-- Notify all players
	for _, p in ipairs(match.players) do
		MatchmakingService.Remotes.MatchFound:FireClient(p, {
			matchId = matchId,
			dimension = dimension,
			playerCount = #match.players,
			countdown = COUNTDOWN_TIME,
		})
	end

	local playerNames = {}
	for _, p in ipairs(match.players) do
		table.insert(playerNames, p.Name)
	end
	print(string.format("[MatchmakingService] Match %s created: %s (%s)",
		matchId, dimension, table.concat(playerNames, ", ")))
end

function MatchmakingService.UpdateCountdowns()
	for matchId, match in pairs(MatchmakingService.ActiveMatches) do
		if match.status == "countdown" then
			match.countdown = match.countdown - 1

			-- Notify players
			for _, p in ipairs(match.players) do
				if p.Parent then -- Still in game
					MatchmakingService.Remotes.MatchCountdown:FireClient(p, {
						matchId = matchId,
						countdown = match.countdown,
					})
				end
			end

			if match.countdown <= 0 then
				MatchmakingService.StartMatch(matchId)
			end
		end
	end
end

function MatchmakingService.StartMatch(matchId: string)
	local match = MatchmakingService.ActiveMatches[matchId]
	if not match then return end

	match.status = "starting"

	-- Filter out disconnected players
	local activePlayers = {}
	for _, p in ipairs(match.players) do
		if p.Parent then
			table.insert(activePlayers, p)
		end
	end

	if #activePlayers < 1 then
		-- No players left, cancel match
		MatchmakingService.ActiveMatches[matchId] = nil
		return
	end

	-- Start the race via RaceService
	local DimensionHopper = _G.DimensionHopper
	if DimensionHopper then
		local RaceService = DimensionHopper.GetService("RaceService")
		local DimensionService = DimensionHopper.GetService("DimensionService")

		if DimensionService and DimensionService.LoadDimension then
			-- Load the dimension
			DimensionService.LoadDimension(match.dimension)
		end

		if RaceService and RaceService.StartRace then
			task.delay(1, function()
				RaceService.StartRace(activePlayers)
			end)
		end
	end

	print(string.format("[MatchmakingService] Match %s started with %d players", matchId, #activePlayers))

	-- Clean up match after some time
	task.delay(10, function()
		MatchmakingService.ActiveMatches[matchId] = nil
	end)
end

function MatchmakingService.GetRandomDimension(): string
	local dimensions = { "Gravity", "Tiny", "Void", "Sky" }
	return dimensions[math.random(1, #dimensions)]
end

-- ============================================================================
-- API
-- ============================================================================

function MatchmakingService.IsInQueue(player: Player): boolean
	return MatchmakingService.Queue[player.UserId] ~= nil
end

function MatchmakingService.GetPlayerMatch(player: Player): table?
	for matchId, match in pairs(MatchmakingService.ActiveMatches) do
		for _, p in ipairs(match.players) do
			if p == player then
				return match
			end
		end
	end
	return nil
end

return MatchmakingService
