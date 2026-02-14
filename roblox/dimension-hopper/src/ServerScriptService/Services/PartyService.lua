--[[
	PartyService.lua
	Manages player parties for playing with friends

	Features:
	- Create/join/leave parties
	- Party leader controls
	- Party chat
	- Queue as a party
	- Party invites
	- Max party size limits
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MAX_PARTY_SIZE = 4
local INVITE_TIMEOUT = 60 -- seconds

-- ============================================================================
-- STATE
-- ============================================================================

-- [partyId] = { leader, members = {userId}, invites = {userId = expireTime}, createdAt }
PartyService.Parties = {}

-- [userId] = partyId
PartyService.PlayerParties = {}

-- [userId] = { fromUserId = expireTime }
PartyService.PendingInvites = {}

local nextPartyId = 1

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PartyService.Init()
	print("[PartyService] Initializing...")

	PartyService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		PartyService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PartyService.OnPlayerLeave(player)
	end)

	-- Clean up expired invites periodically
	task.spawn(function()
		while true do
			task.wait(10)
			PartyService.CleanupExpiredInvites()
		end
	end)

	print("[PartyService] Initialized")
end

function PartyService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create party
	if not remoteFolder:FindFirstChild("CreateParty") then
		local event = Instance.new("RemoteEvent")
		event.Name = "CreateParty"
		event.Parent = remoteFolder
	end

	-- Leave party
	if not remoteFolder:FindFirstChild("LeaveParty") then
		local event = Instance.new("RemoteEvent")
		event.Name = "LeaveParty"
		event.Parent = remoteFolder
	end

	-- Invite to party
	if not remoteFolder:FindFirstChild("InviteToParty") then
		local event = Instance.new("RemoteEvent")
		event.Name = "InviteToParty"
		event.Parent = remoteFolder
	end

	-- Respond to invite
	if not remoteFolder:FindFirstChild("RespondToInvite") then
		local event = Instance.new("RemoteEvent")
		event.Name = "RespondToInvite"
		event.Parent = remoteFolder
	end

	-- Kick from party
	if not remoteFolder:FindFirstChild("KickFromParty") then
		local event = Instance.new("RemoteEvent")
		event.Name = "KickFromParty"
		event.Parent = remoteFolder
	end

	-- Transfer leadership
	if not remoteFolder:FindFirstChild("TransferLeadership") then
		local event = Instance.new("RemoteEvent")
		event.Name = "TransferLeadership"
		event.Parent = remoteFolder
	end

	-- Party sync (server -> client)
	if not remoteFolder:FindFirstChild("PartySync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PartySync"
		event.Parent = remoteFolder
	end

	-- Party invite received
	if not remoteFolder:FindFirstChild("PartyInviteReceived") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PartyInviteReceived"
		event.Parent = remoteFolder
	end

	-- Get party info
	if not remoteFolder:FindFirstChild("GetPartyInfo") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetPartyInfo"
		func.Parent = remoteFolder
	end

	PartyService.Remotes = {
		CreateParty = remoteFolder.CreateParty,
		LeaveParty = remoteFolder.LeaveParty,
		InviteToParty = remoteFolder.InviteToParty,
		RespondToInvite = remoteFolder.RespondToInvite,
		KickFromParty = remoteFolder.KickFromParty,
		TransferLeadership = remoteFolder.TransferLeadership,
		PartySync = remoteFolder.PartySync,
		PartyInviteReceived = remoteFolder.PartyInviteReceived,
		GetPartyInfo = remoteFolder.GetPartyInfo,
	}

	-- Connect handlers
	PartyService.Remotes.CreateParty.OnServerEvent:Connect(function(player)
		PartyService.CreateParty(player)
	end)

	PartyService.Remotes.LeaveParty.OnServerEvent:Connect(function(player)
		PartyService.LeaveParty(player)
	end)

	PartyService.Remotes.InviteToParty.OnServerEvent:Connect(function(player, targetUserId)
		PartyService.InvitePlayer(player, targetUserId)
	end)

	PartyService.Remotes.RespondToInvite.OnServerEvent:Connect(function(player, fromUserId, accept)
		PartyService.RespondToInvite(player, fromUserId, accept)
	end)

	PartyService.Remotes.KickFromParty.OnServerEvent:Connect(function(player, targetUserId)
		PartyService.KickPlayer(player, targetUserId)
	end)

	PartyService.Remotes.TransferLeadership.OnServerEvent:Connect(function(player, targetUserId)
		PartyService.TransferLeadership(player, targetUserId)
	end)

	PartyService.Remotes.GetPartyInfo.OnServerInvoke = function(player)
		return PartyService.GetPartyInfo(player)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function PartyService.OnPlayerJoin(player: Player)
	PartyService.PendingInvites[player.UserId] = {}
end

function PartyService.OnPlayerLeave(player: Player)
	-- Leave any party they're in
	PartyService.LeaveParty(player)

	-- Clear pending invites
	PartyService.PendingInvites[player.UserId] = nil

	-- Cancel any invites they sent
	for partyId, party in pairs(PartyService.Parties) do
		if party.invites then
			for invitedUserId, _ in pairs(party.invites) do
				if party.leader == player.UserId then
					party.invites[invitedUserId] = nil
				end
			end
		end
	end
end

-- ============================================================================
-- PARTY OPERATIONS
-- ============================================================================

function PartyService.CreateParty(player: Player): string?
	-- Already in a party?
	if PartyService.PlayerParties[player.UserId] then
		return nil
	end

	local partyId = tostring(nextPartyId)
	nextPartyId = nextPartyId + 1

	PartyService.Parties[partyId] = {
		id = partyId,
		leader = player.UserId,
		members = { player.UserId },
		invites = {},
		createdAt = os.time(),
	}

	PartyService.PlayerParties[player.UserId] = partyId

	PartyService.SyncParty(partyId)

	print(string.format("[PartyService] %s created party %s", player.Name, partyId))

	return partyId
end

function PartyService.LeaveParty(player: Player)
	local partyId = PartyService.PlayerParties[player.UserId]
	if not partyId then return end

	local party = PartyService.Parties[partyId]
	if not party then return end

	-- Remove from members
	for i, memberId in ipairs(party.members) do
		if memberId == player.UserId then
			table.remove(party.members, i)
			break
		end
	end

	PartyService.PlayerParties[player.UserId] = nil

	-- If party is empty, delete it
	if #party.members == 0 then
		PartyService.Parties[partyId] = nil
		print(string.format("[PartyService] Party %s disbanded", partyId))
		return
	end

	-- If leader left, transfer leadership
	if party.leader == player.UserId then
		party.leader = party.members[1]
		local newLeader = Players:GetPlayerByUserId(party.leader)
		if newLeader then
			print(string.format("[PartyService] Leadership transferred to %s", newLeader.Name))
		end
	end

	PartyService.SyncParty(partyId)

	-- Notify the player who left
	PartyService.Remotes.PartySync:FireClient(player, nil)

	print(string.format("[PartyService] %s left party %s", player.Name, partyId))
end

function PartyService.InvitePlayer(player: Player, targetUserId: number)
	local partyId = PartyService.PlayerParties[player.UserId]

	-- Create party if not in one
	if not partyId then
		partyId = PartyService.CreateParty(player)
	end

	local party = PartyService.Parties[partyId]
	if not party then return end

	-- Must be leader to invite
	if party.leader ~= player.UserId then
		return
	end

	-- Check party size
	if #party.members >= MAX_PARTY_SIZE then
		return
	end

	-- Check if target is already in a party
	if PartyService.PlayerParties[targetUserId] then
		return
	end

	-- Check if target is online
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return
	end

	-- Send invite
	party.invites[targetUserId] = os.time() + INVITE_TIMEOUT

	-- Track pending invite for target
	if not PartyService.PendingInvites[targetUserId] then
		PartyService.PendingInvites[targetUserId] = {}
	end
	PartyService.PendingInvites[targetUserId][player.UserId] = os.time() + INVITE_TIMEOUT

	-- Notify target
	PartyService.Remotes.PartyInviteReceived:FireClient(targetPlayer, {
		fromUserId = player.UserId,
		fromName = player.Name,
		partyId = partyId,
		expiresAt = os.time() + INVITE_TIMEOUT,
	})

	print(string.format("[PartyService] %s invited %s to party", player.Name, targetPlayer.Name))
end

function PartyService.RespondToInvite(player: Player, fromUserId: number, accept: boolean)
	local pendingInvites = PartyService.PendingInvites[player.UserId]
	if not pendingInvites or not pendingInvites[fromUserId] then
		return
	end

	-- Check if invite expired
	if os.time() > pendingInvites[fromUserId] then
		pendingInvites[fromUserId] = nil
		return
	end

	pendingInvites[fromUserId] = nil

	if not accept then
		return
	end

	-- Find the party
	local partyId = PartyService.PlayerParties[fromUserId]
	if not partyId then return end

	local party = PartyService.Parties[partyId]
	if not party then return end

	-- Check party size
	if #party.members >= MAX_PARTY_SIZE then
		return
	end

	-- Already in a party?
	if PartyService.PlayerParties[player.UserId] then
		PartyService.LeaveParty(player)
	end

	-- Join party
	table.insert(party.members, player.UserId)
	PartyService.PlayerParties[player.UserId] = partyId

	-- Remove from invites
	party.invites[player.UserId] = nil

	PartyService.SyncParty(partyId)

	print(string.format("[PartyService] %s joined party %s", player.Name, partyId))
end

function PartyService.KickPlayer(player: Player, targetUserId: number)
	local partyId = PartyService.PlayerParties[player.UserId]
	if not partyId then return end

	local party = PartyService.Parties[partyId]
	if not party then return end

	-- Must be leader
	if party.leader ~= player.UserId then
		return
	end

	-- Can't kick yourself
	if targetUserId == player.UserId then
		return
	end

	-- Find and remove target
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	for i, memberId in ipairs(party.members) do
		if memberId == targetUserId then
			table.remove(party.members, i)
			PartyService.PlayerParties[targetUserId] = nil

			-- Notify kicked player
			if targetPlayer then
				PartyService.Remotes.PartySync:FireClient(targetPlayer, nil)
			end

			break
		end
	end

	PartyService.SyncParty(partyId)

	if targetPlayer then
		print(string.format("[PartyService] %s kicked %s from party", player.Name, targetPlayer.Name))
	end
end

function PartyService.TransferLeadership(player: Player, targetUserId: number)
	local partyId = PartyService.PlayerParties[player.UserId]
	if not partyId then return end

	local party = PartyService.Parties[partyId]
	if not party then return end

	-- Must be leader
	if party.leader ~= player.UserId then
		return
	end

	-- Target must be in party
	local found = false
	for _, memberId in ipairs(party.members) do
		if memberId == targetUserId then
			found = true
			break
		end
	end

	if not found then return end

	party.leader = targetUserId

	PartyService.SyncParty(partyId)

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		print(string.format("[PartyService] Leadership transferred to %s", targetPlayer.Name))
	end
end

-- ============================================================================
-- SYNC
-- ============================================================================

function PartyService.SyncParty(partyId: string)
	local party = PartyService.Parties[partyId]
	if not party then return end

	local syncData = {
		id = partyId,
		leader = party.leader,
		members = {},
	}

	-- Build member list with names
	for _, memberId in ipairs(party.members) do
		local memberPlayer = Players:GetPlayerByUserId(memberId)
		table.insert(syncData.members, {
			userId = memberId,
			name = memberPlayer and memberPlayer.Name or "Unknown",
			isLeader = memberId == party.leader,
		})
	end

	-- Send to all party members
	for _, memberId in ipairs(party.members) do
		local memberPlayer = Players:GetPlayerByUserId(memberId)
		if memberPlayer then
			PartyService.Remotes.PartySync:FireClient(memberPlayer, syncData)
		end
	end
end

function PartyService.CleanupExpiredInvites()
	local now = os.time()

	-- Clean pending invites
	for userId, invites in pairs(PartyService.PendingInvites) do
		for fromUserId, expireTime in pairs(invites) do
			if now > expireTime then
				invites[fromUserId] = nil
			end
		end
	end

	-- Clean party invites
	for partyId, party in pairs(PartyService.Parties) do
		if party.invites then
			for invitedUserId, expireTime in pairs(party.invites) do
				if now > expireTime then
					party.invites[invitedUserId] = nil
				end
			end
		end
	end
end

-- ============================================================================
-- API
-- ============================================================================

function PartyService.GetPartyInfo(player: Player): table?
	local partyId = PartyService.PlayerParties[player.UserId]
	if not partyId then return nil end

	local party = PartyService.Parties[partyId]
	if not party then return nil end

	local info = {
		id = partyId,
		leader = party.leader,
		members = {},
		size = #party.members,
		maxSize = MAX_PARTY_SIZE,
	}

	for _, memberId in ipairs(party.members) do
		local memberPlayer = Players:GetPlayerByUserId(memberId)
		table.insert(info.members, {
			userId = memberId,
			name = memberPlayer and memberPlayer.Name or "Unknown",
			isLeader = memberId == party.leader,
		})
	end

	return info
end

function PartyService.IsInParty(player: Player): boolean
	return PartyService.PlayerParties[player.UserId] ~= nil
end

function PartyService.GetPartyMembers(player: Player): {Player}
	local partyId = PartyService.PlayerParties[player.UserId]
	if not partyId then return { player } end

	local party = PartyService.Parties[partyId]
	if not party then return { player } end

	local members = {}
	for _, memberId in ipairs(party.members) do
		local memberPlayer = Players:GetPlayerByUserId(memberId)
		if memberPlayer then
			table.insert(members, memberPlayer)
		end
	end

	return members
end

function PartyService.IsPartyLeader(player: Player): boolean
	local partyId = PartyService.PlayerParties[player.UserId]
	if not partyId then return false end

	local party = PartyService.Parties[partyId]
	if not party then return false end

	return party.leader == player.UserId
end

function PartyService.GetPartyId(player: Player): string?
	return PartyService.PlayerParties[player.UserId]
end

return PartyService
