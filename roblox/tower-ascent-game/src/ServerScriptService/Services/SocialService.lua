--[[
	SocialService.lua
	Social features for viral growth and player engagement

	Features:
	- Friends leaderboard (compare with Roblox friends)
	- Share achievements (post to social media, game feed)
	- Invite rewards (referral system with coin bonuses)
	- Social statistics (friends playing, friends invited)
	- Friend notifications (when friends beat your record)

	Viral Growth Mechanics:
	- "Beat Your Friend" challenges (automatic, shown in UI)
	- Share milestones (auto-prompt on achievements)
	- Invite incentives (both inviter and invitee get rewards)
	- Friend activity feed (see what friends accomplished)

	Week 16: Social Features for Viral Growth
--]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local SocialFeatures = {}
SocialFeatures.IsInitialized = false

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Invite Rewards
	InviteRewards = {
		Inviter = {
			Coins = 1000, -- Inviter gets 1000 coins per successful invite
			BonusPerFriend = 100, -- +100 coins for each additional friend invited
			MaxBonus = 5000, -- Cap at 5000 bonus coins
		},
		Invitee = {
			Coins = 500, -- New player gets 500 coins when joining via invite
			VIPTrial = 86400, -- 24 hours of VIP trial (in seconds)
		},
	},

	-- Share Rewards
	ShareRewards = {
		FirstShare = 200, -- First share of the day
		PerShare = 50, -- Each subsequent share
		MaxPerDay = 500, -- Max 500 coins from sharing per day
		Cooldown = 300, -- 5 minutes between shares
	},

	-- Friend Challenge Rewards
	ChallengeRewards = {
		BeatFriend = 100, -- Beat a friend's record
		BeatMultipleFriends = 250, -- Beat 3+ friends' records in one climb
		FirstInFriendGroup = 500, -- Be the first of your friends to reach section 50
	},

	-- Leaderboard Settings
	FriendsLeaderboardSize = 50, -- Track top 50 friends
	UpdateInterval = 30, -- Update friends leaderboard every 30 seconds
}

-- ============================================================================
-- DATA STORES
-- ============================================================================

local InviteDataStore
local ShareDataStore
local SocialStatsStore

local success, err = pcall(function()
	InviteDataStore = DataStoreService:GetDataStore("InviteTracking")
	ShareDataStore = DataStoreService:GetDataStore("ShareTracking")
	SocialStatsStore = DataStoreService:GetDataStore("SocialStats")
end)

if not success then
	warn("[SocialService] Failed to get DataStores:", err)
end

-- ============================================================================
-- CACHE
-- ============================================================================

SocialFeatures.PlayerInvites = {} -- [UserId] = {InvitedBy, InvitedPlayers[]}
SocialFeatures.FriendsCache = {} -- [UserId] = {FriendUserIds[], LastUpdate}
SocialFeatures.ShareCooldowns = {} -- [UserId] = LastShareTimestamp
SocialFeatures.DailyShareCount = {} -- [UserId] = ShareCount (resets daily)
SocialFeatures.ActiveChallenges = {} -- [UserId] = {ChallengeType, Target, Progress}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SocialFeatures.Init()
	print("[SocialService] Initializing...")

	-- Create RemoteEvents
	SocialFeatures.CreateRemoteEvents()

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		SocialFeatures.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		SocialFeatures.OnPlayerLeave(player)
	end)

	-- Start friends leaderboard update loop
	task.spawn(function()
		while true do
			task.wait(CONFIG.UpdateInterval)
			SocialFeatures.UpdateAllFriendsLeaderboards()
		end
	end)

	SocialFeatures.IsInitialized = true
	print("[SocialService] Initialized")
end

function SocialFeatures.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Get Friends Leaderboard
	if not remoteFolder:FindFirstChild("GetFriendsLeaderboard") then
		local remote = Instance.new("RemoteFunction")
		remote.Name = "GetFriendsLeaderboard"
		remote.Parent = remoteFolder
		remote.OnServerInvoke = function(player)
			return SocialFeatures.GetFriendsLeaderboard(player)
		end
	end

	-- Share Achievement
	if not remoteFolder:FindFirstChild("ShareAchievement") then
		local remote = Instance.new("RemoteEvent")
		remote.Name = "ShareAchievement"
		remote.Parent = remoteFolder
		remote.OnServerEvent:Connect(function(player, achievementId)
			SocialFeatures.ShareAchievement(player, achievementId)
		end)
	end

	-- Invite Friend
	if not remoteFolder:FindFirstChild("InviteFriend") then
		local remote = Instance.new("RemoteEvent")
		remote.Name = "InviteFriend"
		remote.Parent = remoteFolder
		remote.OnServerEvent:Connect(function(player)
			SocialFeatures.GenerateInviteLink(player)
		end)
	end

	-- Check Invite Code
	if not remoteFolder:FindFirstChild("CheckInviteCode") then
		local remote = Instance.new("RemoteFunction")
		remote.Name = "CheckInviteCode"
		remote.Parent = remoteFolder
		remote.OnServerInvoke = function(player, inviteCode)
			return SocialFeatures.RedeemInviteCode(player, inviteCode)
		end
	end

	-- Friend Challenge Update (notify client)
	if not remoteFolder:FindFirstChild("FriendChallengeUpdate") then
		local remote = Instance.new("RemoteEvent")
		remote.Name = "FriendChallengeUpdate"
		remote.Parent = remoteFolder
	end

	-- Friend Activity Update (notify client)
	if not remoteFolder:FindFirstChild("FriendActivityUpdate") then
		local remote = Instance.new("RemoteEvent")
		remote.Name = "FriendActivityUpdate"
		remote.Parent = remoteFolder
	end
end

-- ============================================================================
-- FRIENDS LEADERBOARD
-- ============================================================================

function SocialFeatures.GetFriendsLeaderboard(player: Player)
	--[[
		Returns leaderboard of player's Roblox friends.
		Includes player's rank among friends.
	--]]

	-- Get player's friends (from Roblox API)
	local friends = SocialFeatures.GetPlayerFriends(player)

	if not friends or #friends == 0 then
		return {
			Friends = {},
			PlayerRank = 0,
			TotalFriends = 0,
		}
	end

	-- Get DataService reference (assumes it's in _G.TowerAscent)
	local TowerAscent = _G.TowerAscent
	if not TowerAscent or not TowerAscent.DataService then
		warn("[SocialService] DataService not found in _G.TowerAscent")
		return {Friends = {}, PlayerRank = 0, TotalFriends = 0}
	end

	local DataService = TowerAscent.DataService

	-- Build leaderboard from friends' data
	local leaderboard = {}

	for _, friendUserId in ipairs(friends) do
		-- Try to get friend's data (may not exist if they never played)
		local friendData = DataService.GetPlayerDataByUserId(friendUserId)

		if friendData then
			table.insert(leaderboard, {
				UserId = friendUserId,
				Username = Players:GetNameFromUserIdAsync(friendUserId) or "Friend",
				HighestSection = friendData.HighestSection or 0,
				TotalCoins = friendData.TotalCoins or 0,
				TotalClimbs = friendData.Stats.TotalClimbs or 0,
			})
		end
	end

	-- Sort by highest section (descending)
	table.sort(leaderboard, function(a, b)
		return a.HighestSection > b.HighestSection
	end)

	-- Find player's rank
	local playerRank = 0
	local playerData = DataService.GetPlayerData(player)

	if playerData then
		for i, entry in ipairs(leaderboard) do
			if entry.HighestSection < playerData.HighestSection then
				playerRank = i
				break
			end
		end

		if playerRank == 0 then
			playerRank = #leaderboard + 1
		end
	end

	return {
		Friends = leaderboard,
		PlayerRank = playerRank,
		TotalFriends = #friends,
	}
end

function SocialFeatures.GetPlayerFriends(player: Player)
	--[[
		Gets list of player's Roblox friends (UserIds).
		Caches for performance.
	--]]

	local now = tick()
	local cached = SocialFeatures.FriendsCache[player.UserId]

	-- Use cache if recent (5 minutes)
	if cached and (now - cached.LastUpdate) < 300 then
		return cached.FriendUserIds
	end

	-- Fetch from Roblox API
	local success, friends = pcall(function()
		return player:GetFriendsOnline(CONFIG.FriendsLeaderboardSize)
	end)

	if not success then
		warn("[SocialService] Failed to get friends for", player.Name)
		return {}
	end

	local friendUserIds = {}
	for _, friend in ipairs(friends) do
		table.insert(friendUserIds, friend.VisitorId)
	end

	-- Cache result
	SocialFeatures.FriendsCache[player.UserId] = {
		FriendUserIds = friendUserIds,
		LastUpdate = now,
	}

	return friendUserIds
end

function SocialFeatures.UpdateAllFriendsLeaderboards()
	--[[
		Periodically updates friends leaderboards for all online players.
		Detects when friends beat player's records (sends notifications).
	--]]

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			SocialFeatures.CheckFriendChallenges(player)
		end)
	end
end

function SocialFeatures.CheckFriendChallenges(player: Player)
	--[[
		Checks if any friends have beaten player's records.
		Sends challenge notifications to player.
	--]]

	local leaderboard = SocialFeatures.GetFriendsLeaderboard(player)

	if not leaderboard or #leaderboard.Friends == 0 then return end

	local TowerAscent = _G.TowerAscent
	if not TowerAscent or not TowerAscent.DataService then return end

	local playerData = TowerAscent.DataService.GetPlayerData(player)
	if not playerData then return end

	-- Check if any friends are ahead
	for _, friend in ipairs(leaderboard.Friends) do
		if friend.HighestSection > playerData.HighestSection then
			-- Friend is ahead! Notify player (show challenge)
			SocialFeatures.NotifyFriendChallenge(player, friend)
			break -- Only show one challenge at a time
		end
	end
end

function SocialFeatures.NotifyFriendChallenge(player: Player, friendData)
	--[[
		Notifies player that a friend is ahead.
		Creates "Beat Your Friend" challenge.
	--]]

	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then return end

	local challengeEvent = remoteFolder:FindFirstChild("FriendChallengeUpdate")
	if not challengeEvent then return end

	challengeEvent:FireClient(player, {
		Type = "BeatFriend",
		FriendName = friendData.Username,
		FriendSection = friendData.HighestSection,
		Reward = CONFIG.ChallengeRewards.BeatFriend,
	})

	-- Track active challenge
	SocialFeatures.ActiveChallenges[player.UserId] = {
		Type = "BeatFriend",
		Target = friendData.HighestSection,
		FriendUserId = friendData.UserId,
	}
end

-- ============================================================================
-- SHARE SYSTEM
-- ============================================================================

function SocialFeatures.ShareAchievement(player: Player, achievementId: string)
	--[[
		Shares achievement to game feed / external social.
		Awards coins for sharing (with daily limits).
	--]]

	local now = tick()

	-- Check cooldown (5 minutes between shares)
	local lastShare = SocialFeatures.ShareCooldowns[player.UserId] or 0
	if (now - lastShare) < CONFIG.ShareRewards.Cooldown then
		local remaining = math.ceil(CONFIG.ShareRewards.Cooldown - (now - lastShare))
		warn(string.format("[SocialService] %s is on share cooldown (%ds remaining)", player.Name, remaining))
		return false
	end

	-- Check daily limit
	local dailyCount = SocialFeatures.DailyShareCount[player.UserId] or 0
	if dailyCount >= (CONFIG.ShareRewards.MaxPerDay / CONFIG.ShareRewards.PerShare) then
		warn(string.format("[SocialService] %s has reached daily share limit", player.Name))
		return false
	end

	-- Calculate reward
	local reward = dailyCount == 0 and CONFIG.ShareRewards.FirstShare or CONFIG.ShareRewards.PerShare

	-- Award coins
	local TowerAscent = _G.TowerAscent
	if TowerAscent and TowerAscent.CoinService then
		TowerAscent.CoinService.AddCoins(player, reward, "Share Achievement")
	end

	-- Update cooldown and daily count
	SocialFeatures.ShareCooldowns[player.UserId] = now
	SocialFeatures.DailyShareCount[player.UserId] = dailyCount + 1

	-- Log share event (for analytics)
	SocialFeatures.LogShareEvent(player, achievementId, reward)

	print(string.format("[SocialService] %s shared achievement %s (+%d coins)", player.Name, achievementId, reward))

	return true
end

function SocialFeatures.LogShareEvent(player: Player, achievementId: string, reward: number)
	--[[
		Logs share event to DataStore (for analytics).
	--]]

	if not ShareDataStore then return end

	task.spawn(function()
		local success, err = pcall(function()
			local key = "Player_" .. player.UserId
			local existing = ShareDataStore:GetAsync(key) or {}

			table.insert(existing, {
				Achievement = achievementId,
				Timestamp = os.time(),
				Reward = reward,
			})

			ShareDataStore:SetAsync(key, existing)
		end)

		if not success then
			warn("[SocialService] Failed to log share event:", err)
		end
	end)
end

-- ============================================================================
-- INVITE SYSTEM
-- ============================================================================

function SocialFeatures.GenerateInviteLink(player: Player)
	--[[
		Generates invite link/code for player.
		Returns invite code to client for sharing.
	--]]

	local inviteCode = "TOWER_" .. player.UserId

	-- Store invite code mapping
	if InviteDataStore then
		task.spawn(function()
			local success, err = pcall(function()
				InviteDataStore:SetAsync("Code_" .. inviteCode, player.UserId)
			end)

			if not success then
				warn("[SocialService] Failed to store invite code:", err)
			end
		end)
	end

	-- Notify client with invite code
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteFolder then
		local inviteEvent = remoteFolder:FindFirstChild("InviteCodeGenerated")
		if not inviteEvent then
			inviteEvent = Instance.new("RemoteEvent")
			inviteEvent.Name = "InviteCodeGenerated"
			inviteEvent.Parent = remoteFolder
		end

		inviteEvent:FireClient(player, inviteCode)
	end

	print(string.format("[SocialService] Generated invite code for %s: %s", player.Name, inviteCode))

	return inviteCode
end

function SocialFeatures.RedeemInviteCode(player: Player, inviteCode: string)
	--[[
		Redeems invite code for new player.
		Awards rewards to both inviter and invitee.
	--]]

	if not InviteDataStore then
		warn("[SocialService] InviteDataStore not available")
		return false
	end

	-- Check if player already redeemed an invite
	local playerInviteData = SocialFeatures.PlayerInvites[player.UserId]
	if playerInviteData and playerInviteData.InvitedBy then
		warn(string.format("[SocialService] %s already redeemed an invite code", player.Name))
		return false
	end

	-- Get inviter UserId from code
	local success, inviterUserId = pcall(function()
		return InviteDataStore:GetAsync("Code_" .. inviteCode)
	end)

	if not success or not inviterUserId then
		warn(string.format("[SocialService] Invalid invite code: %s", inviteCode))
		return false
	end

	-- Can't invite yourself
	if inviterUserId == player.UserId then
		warn("[SocialService] Cannot redeem your own invite code")
		return false
	end

	-- Award rewards
	SocialFeatures.AwardInviteRewards(player, inviterUserId)

	-- Track invite
	SocialFeatures.PlayerInvites[player.UserId] = {
		InvitedBy = inviterUserId,
		RedeemedAt = os.time(),
	}

	-- Update inviter's invite count
	if not SocialFeatures.PlayerInvites[inviterUserId] then
		SocialFeatures.PlayerInvites[inviterUserId] = {InvitedPlayers = {}}
	end

	table.insert(SocialFeatures.PlayerInvites[inviterUserId].InvitedPlayers, player.UserId)

	print(string.format("[SocialService] %s redeemed invite from user %d", player.Name, inviterUserId))

	return true
end

function SocialFeatures.AwardInviteRewards(invitee: Player, inviterUserId: number)
	--[[
		Awards coins to both inviter and invitee.
	--]]

	local TowerAscent = _G.TowerAscent
	if not TowerAscent or not TowerAscent.CoinService then return end

	local CoinService = TowerAscent.CoinService

	-- Award invitee
	CoinService.AddCoins(invitee, CONFIG.InviteRewards.Invitee.Coins, "Invite Reward")

	-- Award inviter (if online)
	local inviter = Players:GetPlayerByUserId(inviterUserId)
	if inviter then
		local inviteCount = #(SocialFeatures.PlayerInvites[inviterUserId].InvitedPlayers or {})
		local bonus = math.min(inviteCount * CONFIG.InviteRewards.Inviter.BonusPerFriend, CONFIG.InviteRewards.Inviter.MaxBonus)
		local totalReward = CONFIG.InviteRewards.Inviter.Coins + bonus

		CoinService.AddCoins(inviter, totalReward, "Friend Invited")

		print(string.format(
			"[SocialService] %s earned %d coins for inviting %s (bonus: %d)",
			inviter.Name,
			totalReward,
			invitee.Name,
			bonus
		))
	end

	print(string.format(
		"[SocialService] %s received %d coins from invite",
		invitee.Name,
		CONFIG.InviteRewards.Invitee.Coins
	))
end

-- ============================================================================
-- PLAYER EVENTS
-- ============================================================================

function SocialFeatures.OnPlayerJoin(player: Player)
	--[[
		Called when player joins server.
		Checks for invite code, loads social data.
	--]]

	-- Initialize player data
	SocialFeatures.PlayerInvites[player.UserId] = {
		InvitedPlayers = {},
	}

	SocialFeatures.DailyShareCount[player.UserId] = 0

	-- Load invite data from DataStore
	if InviteDataStore then
		task.spawn(function()
			local success, data = pcall(function()
				return InviteDataStore:GetAsync("Player_" .. player.UserId)
			end)

			if success and data then
				SocialFeatures.PlayerInvites[player.UserId] = data
			end
		end)
	end
end

function SocialFeatures.OnPlayerLeave(player: Player)
	--[[
		Called when player leaves server.
		Saves social data.
	--]]

	-- Save invite data
	if InviteDataStore and SocialFeatures.PlayerInvites[player.UserId] then
		task.spawn(function()
			local success, err = pcall(function()
				InviteDataStore:SetAsync("Player_" .. player.UserId, SocialFeatures.PlayerInvites[player.UserId])
			end)

			if not success then
				warn("[SocialService] Failed to save invite data:", err)
			end
		end)
	end

	-- Cleanup
	SocialFeatures.PlayerInvites[player.UserId] = nil
	SocialFeatures.FriendsCache[player.UserId] = nil
	SocialFeatures.ShareCooldowns[player.UserId] = nil
	SocialFeatures.DailyShareCount[player.UserId] = nil
	SocialFeatures.ActiveChallenges[player.UserId] = nil
end

-- ============================================================================
-- ADMIN COMMANDS (for testing)
-- ============================================================================

function SocialFeatures.AdminSimulateInvite(player: Player, inviterUserId: number)
	--[[
		Admin command to simulate invite redemption (for testing).
	--]]

	print(string.format("[SocialService] ADMIN: Simulating invite for %s from user %d", player.Name, inviterUserId))
	SocialFeatures.AwardInviteRewards(player, inviterUserId)
end

function SocialFeatures.AdminGetStats(player: Player)
	--[[
		Returns social stats for player (for debugging).
	--]]

	return {
		InvitedBy = SocialFeatures.PlayerInvites[player.UserId]?.InvitedBy,
		InvitedCount = #(SocialFeatures.PlayerInvites[player.UserId]?.InvitedPlayers or {}),
		SharesToday = SocialFeatures.DailyShareCount[player.UserId] or 0,
		ActiveChallenges = SocialFeatures.ActiveChallenges[player.UserId],
	}
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return SocialFeatures
