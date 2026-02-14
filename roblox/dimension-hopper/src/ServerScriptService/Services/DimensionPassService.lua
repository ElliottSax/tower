--[[
	DimensionPassService.lua
	Handles the Dimension Pass (Season Pass) system

	Features:
	- 50 tier progression
	- Free and Premium tracks
	- Daily/Weekly challenges
	- Season rotation
	- Tier rewards (cosmetics, XP boosts)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DimensionPassService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TOTAL_TIERS = 50
local XP_PER_TIER = 1000

-- Season configuration
local CURRENT_SEASON = {
	Id = 1,
	Name = "Season 1: The First Hop",
	StartDate = "2026-01-01",
	EndDate = "2026-01-31",
	Theme = "Launch",
}

-- Tier rewards (Free and Premium tracks)
local TIER_REWARDS = {
	[1] = { Free = { Type = "Coins", Amount = 100 }, Premium = { Type = "Trail", Id = "Spark" } },
	[2] = { Free = { Type = "XP", Amount = 200 }, Premium = { Type = "Coins", Amount = 200 } },
	[3] = { Free = { Type = "Coins", Amount = 150 }, Premium = { Type = "Title", Id = "Early Hopper" } },
	[4] = { Free = { Type = "XP", Amount = 300 }, Premium = { Type = "Coins", Amount = 300 } },
	[5] = { Free = { Type = "Trail", Id = "Basic Glow" }, Premium = { Type = "Wing", Id = "Starter Wings" } },

	[10] = { Free = { Type = "Coins", Amount = 300 }, Premium = { Type = "Trail", Id = "Electric" } },
	[15] = { Free = { Type = "Title", Id = "Dimension Traveler" }, Premium = { Type = "Aura", Id = "Shimmer" } },
	[20] = { Free = { Type = "Coins", Amount = 500 }, Premium = { Type = "Wing", Id = "Crystal Wings" } },
	[25] = { Free = { Type = "Trail", Id = "Flame" }, Premium = { Type = "Emote", Id = "Victory Dance" } },
	[30] = { Free = { Type = "Coins", Amount = 750 }, Premium = { Type = "Title", Id = "Reality Shifter" } },

	[35] = { Free = { Type = "XP", Amount = 1000 }, Premium = { Type = "Trail", Id = "Galaxy" } },
	[40] = { Free = { Type = "Title", Id = "Dimension Expert" }, Premium = { Type = "Wing", Id = "Void Wings" } },
	[45] = { Free = { Type = "Coins", Amount = 1000 }, Premium = { Type = "Aura", Id = "Dimensional Rift" } },
	[50] = { Free = { Type = "Trail", Id = "Rainbow" }, Premium = { Type = "Wing", Id = "Reality Breaker Wings" } },
}

-- Fill in missing tiers with default rewards
for tier = 1, TOTAL_TIERS do
	if not TIER_REWARDS[tier] then
		local coinsAmount = 50 + (tier * 10)
		local xpAmount = 100 + (tier * 20)

		if tier % 2 == 0 then
			TIER_REWARDS[tier] = {
				Free = { Type = "Coins", Amount = coinsAmount },
				Premium = { Type = "XP", Amount = xpAmount * 2 },
			}
		else
			TIER_REWARDS[tier] = {
				Free = { Type = "XP", Amount = xpAmount },
				Premium = { Type = "Coins", Amount = coinsAmount * 2 },
			}
		end
	end
end

-- Daily Challenges
local DAILY_CHALLENGES = {
	{ Id = "race_complete", Description = "Complete 3 races", Goal = 3, XP = 150 },
	{ Id = "sections_10", Description = "Reach 10 sections total", Goal = 10, XP = 100 },
	{ Id = "gravity_flip", Description = "Flip gravity 5 times", Goal = 5, XP = 100 },
	{ Id = "glide_30", Description = "Glide for 30 seconds", Goal = 30, XP = 150 },
	{ Id = "shrink_3", Description = "Shrink 3 times", Goal = 3, XP = 100 },
	{ Id = "escape_void", Description = "Escape the void 2 times", Goal = 2, XP = 200 },
	{ Id = "play_15min", Description = "Play for 15 minutes", Goal = 900, XP = 150 },
}

-- Weekly Challenges
local WEEKLY_CHALLENGES = {
	{ Id = "race_win_5", Description = "Win 5 races", Goal = 5, XP = 500 },
	{ Id = "complete_all_dims", Description = "Complete all 4 dimensions", Goal = 4, XP = 750 },
	{ Id = "marathon", Description = "Complete a Marathon", Goal = 1, XP = 1000 },
	{ Id = "fragments_10", Description = "Collect 10 fragments", Goal = 10, XP = 400 },
	{ Id = "mastery_500", Description = "Earn 500 dimension mastery XP", Goal = 500, XP = 600 },
}

-- ============================================================================
-- STATE
-- ============================================================================

DimensionPassService.PlayerChallenges = {} -- [UserId] = { daily = {}, weekly = {} }

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DimensionPassService.Init()
	print("[DimensionPassService] Initializing...")

	-- Create remotes
	DimensionPassService.CreateRemotes()

	-- Setup marketplace callback for pass purchase
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if wasPurchased then
			DimensionPassService.OnPurchaseComplete(userId, productId)
		end
	end)

	-- Setup player connections
	Players.PlayerAdded:Connect(function(player)
		DimensionPassService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DimensionPassService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		DimensionPassService.OnPlayerJoin(player)
	end

	print("[DimensionPassService] Initialized")
end

function DimensionPassService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Pass data sync
	if not remoteFolder:FindFirstChild("DimensionPassSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "DimensionPassSync"
		event.Parent = remoteFolder
	end

	-- Claim reward
	if not remoteFolder:FindFirstChild("ClaimPassReward") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ClaimPassReward"
		event.Parent = remoteFolder
	end

	-- Challenge progress
	if not remoteFolder:FindFirstChild("ChallengeProgress") then
		local event = Instance.new("RemoteEvent")
		event.Name = "ChallengeProgress"
		event.Parent = remoteFolder
	end

	-- Purchase pass
	if not remoteFolder:FindFirstChild("PurchaseDimensionPass") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PurchaseDimensionPass"
		event.Parent = remoteFolder
	end

	DimensionPassService.Remotes = {
		DimensionPassSync = remoteFolder.DimensionPassSync,
		ClaimPassReward = remoteFolder.ClaimPassReward,
		ChallengeProgress = remoteFolder.ChallengeProgress,
		PurchaseDimensionPass = remoteFolder.PurchaseDimensionPass,
	}

	-- Connect claim reward
	DimensionPassService.Remotes.ClaimPassReward.OnServerEvent:Connect(function(player, tier, track)
		DimensionPassService.ClaimReward(player, tier, track)
	end)

	-- Connect purchase
	DimensionPassService.Remotes.PurchaseDimensionPass.OnServerEvent:Connect(function(player)
		DimensionPassService.PromptPurchase(player)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function DimensionPassService.OnPlayerJoin(player: Player)
	-- Assign daily/weekly challenges
	DimensionPassService.AssignChallenges(player)

	-- Sync pass data to client
	task.delay(1, function()
		DimensionPassService.SyncToClient(player)
	end)
end

function DimensionPassService.OnPlayerLeave(player: Player)
	DimensionPassService.PlayerChallenges[player.UserId] = nil
end

function DimensionPassService.AssignChallenges(player: Player)
	-- Use player's UserId + date as seed for consistent daily challenges
	local today = os.date("%Y%m%d")
	local weekNum = os.date("%W")

	math.randomseed(player.UserId + tonumber(today))

	-- Pick 3 random daily challenges
	local dailyPool = table.clone(DAILY_CHALLENGES)
	local assignedDaily = {}

	for i = 1, 3 do
		if #dailyPool == 0 then break end
		local index = math.random(1, #dailyPool)
		local challenge = table.remove(dailyPool, index)
		challenge.Progress = 0
		challenge.Claimed = false
		table.insert(assignedDaily, challenge)
	end

	-- Pick 3 random weekly challenges
	math.randomseed(player.UserId + tonumber(weekNum))
	local weeklyPool = table.clone(WEEKLY_CHALLENGES)
	local assignedWeekly = {}

	for i = 1, 3 do
		if #weeklyPool == 0 then break end
		local index = math.random(1, #weeklyPool)
		local challenge = table.remove(weeklyPool, index)
		challenge.Progress = 0
		challenge.Claimed = false
		table.insert(assignedWeekly, challenge)
	end

	DimensionPassService.PlayerChallenges[player.UserId] = {
		Daily = assignedDaily,
		Weekly = assignedWeekly,
		LastDailyDate = today,
		LastWeeklyWeek = weekNum,
	}
end

-- ============================================================================
-- XP & PROGRESSION
-- ============================================================================

function DimensionPassService.AddPassXP(player: Player, amount: number)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	local data = DataService.GetData(player)
	if not data then return end

	-- Only add XP if player has the pass or for free track
	data.Purchases.DimensionPassXP = (data.Purchases.DimensionPassXP or 0) + amount

	-- Check for tier up
	local newTier = math.floor(data.Purchases.DimensionPassXP / XP_PER_TIER)
	newTier = math.min(newTier, TOTAL_TIERS)

	if newTier > (data.Purchases.DimensionPassTier or 0) then
		data.Purchases.DimensionPassTier = newTier
		print(string.format("[DimensionPassService] %s reached tier %d", player.Name, newTier))
	end

	-- Sync to client
	DimensionPassService.SyncToClient(player)
end

function DimensionPassService.GetCurrentTier(player: Player): number
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return 0 end

	local data = DataService.GetData(player)
	if not data then return 0 end

	return data.Purchases.DimensionPassTier or 0
end

function DimensionPassService.HasPremiumPass(player: Player): boolean
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return false end

	local data = DataService.GetData(player)
	return data and data.Purchases.DimensionPass or false
end

-- ============================================================================
-- REWARDS
-- ============================================================================

function DimensionPassService.ClaimReward(player: Player, tier: number, track: string)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return false end

	local data = DataService.GetData(player)
	if not data then return false end

	local currentTier = DimensionPassService.GetCurrentTier(player)

	-- Verify tier is reached
	if tier > currentTier then
		warn(string.format("[DimensionPassService] %s tried to claim tier %d but is at %d",
			player.Name, tier, currentTier))
		return false
	end

	-- Verify track access
	if track == "Premium" and not DimensionPassService.HasPremiumPass(player) then
		warn(string.format("[DimensionPassService] %s tried to claim premium without pass", player.Name))
		return false
	end

	-- Initialize claimed rewards tracking if needed
	if not data.Purchases.ClaimedPassRewards then
		data.Purchases.ClaimedPassRewards = {}
	end

	-- Check if already claimed (prevent double-claiming)
	local claimKey = string.format("%d_%s", tier, track)
	if data.Purchases.ClaimedPassRewards[claimKey] then
		warn(string.format("[DimensionPassService] %s already claimed tier %d %s reward",
			player.Name, tier, track))
		return false
	end

	-- Get reward
	local tierRewards = TIER_REWARDS[tier]
	if not tierRewards then return false end

	local reward = tierRewards[track]
	if not reward then return false end

	-- Grant reward
	DimensionPassService.GrantReward(player, reward)

	-- Mark as claimed (store in player data to prevent double claims)
	data.Purchases.ClaimedPassRewards[claimKey] = os.time()

	print(string.format("[DimensionPassService] %s claimed tier %d %s reward",
		player.Name, tier, track))

	return true
end

function DimensionPassService.GrantReward(player: Player, reward: table)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	if reward.Type == "Coins" then
		-- Add coins (if currency system exists)
		print(string.format("[DimensionPassService] Granted %d coins to %s", reward.Amount, player.Name))

	elseif reward.Type == "XP" then
		DataService.AddXP(player, reward.Amount, "Dimension Pass")

	elseif reward.Type == "Trail" or reward.Type == "Wing" or reward.Type == "Title"
		or reward.Type == "Aura" or reward.Type == "Emote" then
		DataService.UnlockItem(player, reward.Type, reward.Id)
	end
end

-- ============================================================================
-- CHALLENGES
-- ============================================================================

function DimensionPassService.UpdateChallengeProgress(player: Player, challengeId: string, amount: number)
	local challenges = DimensionPassService.PlayerChallenges[player.UserId]
	if not challenges then return end

	-- Check daily challenges
	for _, challenge in ipairs(challenges.Daily) do
		if challenge.Id == challengeId and not challenge.Claimed then
			challenge.Progress = math.min(challenge.Progress + amount, challenge.Goal)

			-- Auto-claim if complete
			if challenge.Progress >= challenge.Goal then
				DimensionPassService.ClaimChallenge(player, challenge, "Daily")
			end
		end
	end

	-- Check weekly challenges
	for _, challenge in ipairs(challenges.Weekly) do
		if challenge.Id == challengeId and not challenge.Claimed then
			challenge.Progress = math.min(challenge.Progress + amount, challenge.Goal)

			if challenge.Progress >= challenge.Goal then
				DimensionPassService.ClaimChallenge(player, challenge, "Weekly")
			end
		end
	end

	-- Sync progress
	DimensionPassService.Remotes.ChallengeProgress:FireClient(player, challenges)
end

function DimensionPassService.ClaimChallenge(player: Player, challenge: table, challengeType: string)
	if challenge.Claimed then return end

	challenge.Claimed = true

	-- Award pass XP
	DimensionPassService.AddPassXP(player, challenge.XP)

	print(string.format("[DimensionPassService] %s completed %s challenge: %s (+%d XP)",
		player.Name, challengeType, challenge.Description, challenge.XP))
end

-- Helper functions to call from other services
function DimensionPassService.OnRaceComplete(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "race_complete", 1)
end

function DimensionPassService.OnSectionReached(player: Player, section: number)
	DimensionPassService.UpdateChallengeProgress(player, "sections_10", 1)
end

function DimensionPassService.OnGravityFlip(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "gravity_flip", 1)
end

function DimensionPassService.OnGlide(player: Player, seconds: number)
	DimensionPassService.UpdateChallengeProgress(player, "glide_30", seconds)
end

function DimensionPassService.OnShrink(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "shrink_3", 1)
end

function DimensionPassService.OnVoidEscape(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "escape_void", 1)
end

function DimensionPassService.OnPlayTime(player: Player, seconds: number)
	DimensionPassService.UpdateChallengeProgress(player, "play_15min", seconds)
end

function DimensionPassService.OnRaceWin(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "race_win_5", 1)
end

function DimensionPassService.OnDimensionComplete(player: Player, dimension: string)
	DimensionPassService.UpdateChallengeProgress(player, "complete_all_dims", 1)
end

function DimensionPassService.OnMarathonComplete(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "marathon", 1)
end

function DimensionPassService.OnFragmentCollected(player: Player)
	DimensionPassService.UpdateChallengeProgress(player, "fragments_10", 1)
end

function DimensionPassService.OnMasteryXP(player: Player, amount: number)
	DimensionPassService.UpdateChallengeProgress(player, "mastery_500", amount)
end

-- ============================================================================
-- PURCHASE
-- ============================================================================

function DimensionPassService.PromptPurchase(player: Player)
	local productId = GameConfig.Monetization.DimensionPass.ProductId

	if productId and productId > 0 then
		MarketplaceService:PromptProductPurchase(player, productId)
	else
		warn("[DimensionPassService] No product ID configured for Dimension Pass")
	end
end

function DimensionPassService.OnPurchaseComplete(userId: number, productId: number)
	local passProductId = GameConfig.Monetization.DimensionPass.ProductId

	if productId ~= passProductId then return end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	local data = DataService.GetData(player)
	if data then
		data.Purchases.DimensionPass = true
		print(string.format("[DimensionPassService] %s purchased Dimension Pass!", player.Name))

		-- Sync to client
		DimensionPassService.SyncToClient(player)
	end
end

-- ============================================================================
-- SYNC
-- ============================================================================

function DimensionPassService.SyncToClient(player: Player)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	local data = DataService.GetData(player)
	if not data then return end

	local challenges = DimensionPassService.PlayerChallenges[player.UserId]

	local passData = {
		Season = CURRENT_SEASON,
		HasPremium = data.Purchases.DimensionPass or false,
		CurrentTier = data.Purchases.DimensionPassTier or 0,
		CurrentXP = data.Purchases.DimensionPassXP or 0,
		XPPerTier = XP_PER_TIER,
		TotalTiers = TOTAL_TIERS,
		Rewards = TIER_REWARDS,
		Challenges = challenges,
		ClaimedRewards = data.Purchases.ClaimedPassRewards or {},
	}

	DimensionPassService.Remotes.DimensionPassSync:FireClient(player, passData)
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function DimensionPassService.DebugAddXP(player: Player, amount: number)
	DimensionPassService.AddPassXP(player, amount)
end

function DimensionPassService.DebugSetTier(player: Player, tier: number)
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if not DataService then return end

	local data = DataService.GetData(player)
	if data then
		data.Purchases.DimensionPassTier = tier
		data.Purchases.DimensionPassXP = tier * XP_PER_TIER
		DimensionPassService.SyncToClient(player)
	end
end

return DimensionPassService
