--[[
	BattlePassService.lua
	Seasonal Battle Pass progression system for Tower Ascent

	Features:
	- 50 tier progression system
	- Free and Premium reward tracks
	- Daily/Weekly challenges for XP
	- Seasonal resets
	- Cosmetic rewards (trails, titles, emotes)

	Progression:
	- XP earned from gameplay (sections reached, tower completed, challenges)
	- Each tier requires increasing XP
	- Premium pass unlocks additional rewards per tier

	Week 13: Battle Pass implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local BattlePassService = {}
BattlePassService.PlayerProgress = {} -- [UserId] = {Tier, XP, Premium, ClaimedRewards}
BattlePassService.IsInitialized = false

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Battle Pass Product ID (set after creating on Roblox)
	PremiumPassId = 0, -- PLACEHOLDER: Replace with actual Game Pass ID

	-- Season Info
	SeasonNumber = 1,
	SeasonName = "Tower Legends",
	SeasonEndDate = os.time() + (30 * 24 * 60 * 60), -- 30 days from now

	-- Progression
	MaxTier = 50,
	BaseXPPerTier = 100, -- First tier needs 100 XP
	XPScaling = 1.1, -- Each tier needs 10% more XP than previous

	-- XP Sources
	XPPerSection = 5, -- XP per section reached
	XPPerTowerComplete = 100, -- Bonus for completing tower
	XPPerDailyChallenge = 50,
	XPPerWeeklyChallenge = 150,

	-- Rate Limiting
	PurchasePromptCooldown = 5, -- seconds
}

-- ============================================================================
-- REWARD DEFINITIONS
-- ============================================================================

-- Rewards for each tier (Free and Premium tracks)
local TIER_REWARDS = {
	-- Tier 1-10: Early rewards (easy to obtain)
	[1] = { free = { type = "Coins", amount = 50 }, premium = { type = "Title", id = "Rookie" } },
	[2] = { free = { type = "XPBoost", duration = 300 }, premium = { type = "Coins", amount = 100 } },
	[3] = { free = { type = "Coins", amount = 75 }, premium = { type = "Trail", id = "Sparkle" } },
	[4] = { free = nil, premium = { type = "Coins", amount = 150 } },
	[5] = { free = { type = "Title", id = "Climber" }, premium = { type = "Emote", id = "Wave" } },
	[6] = { free = { type = "Coins", amount = 100 }, premium = { type = "Coins", amount = 200 } },
	[7] = { free = nil, premium = { type = "Trail", id = "Fire" } },
	[8] = { free = { type = "XPBoost", duration = 600 }, premium = { type = "Coins", amount = 250 } },
	[9] = { free = { type = "Coins", amount = 125 }, premium = { type = "Title", id = "Adventurer" } },
	[10] = { free = { type = "Trail", id = "Basic" }, premium = { type = "Emote", id = "Dance" } },

	-- Tier 11-20: Mid-early rewards
	[11] = { free = { type = "Coins", amount = 150 }, premium = { type = "Coins", amount = 300 } },
	[12] = { free = nil, premium = { type = "Trail", id = "Ice" } },
	[13] = { free = { type = "XPBoost", duration = 900 }, premium = { type = "Coins", amount = 350 } },
	[14] = { free = { type = "Coins", amount = 175 }, premium = { type = "Title", id = "Explorer" } },
	[15] = { free = { type = "Title", id = "Veteran" }, premium = { type = "Emote", id = "Cheer" } },
	[16] = { free = { type = "Coins", amount = 200 }, premium = { type = "Coins", amount = 400 } },
	[17] = { free = nil, premium = { type = "Trail", id = "Electric" } },
	[18] = { free = { type = "XPBoost", duration = 1200 }, premium = { type = "Coins", amount = 450 } },
	[19] = { free = { type = "Coins", amount = 225 }, premium = { type = "Title", id = "Pathfinder" } },
	[20] = { free = { type = "Trail", id = "Rainbow" }, premium = { type = "Emote", id = "Victory" } },

	-- Tier 21-30: Mid rewards
	[21] = { free = { type = "Coins", amount = 250 }, premium = { type = "Coins", amount = 500 } },
	[22] = { free = nil, premium = { type = "Trail", id = "Shadow" } },
	[23] = { free = { type = "XPBoost", duration = 1500 }, premium = { type = "Coins", amount = 550 } },
	[24] = { free = { type = "Coins", amount = 275 }, premium = { type = "Title", id = "Tower Master" } },
	[25] = { free = { type = "Title", id = "Elite" }, premium = { type = "Emote", id = "Backflip" } },
	[26] = { free = { type = "Coins", amount = 300 }, premium = { type = "Coins", amount = 600 } },
	[27] = { free = nil, premium = { type = "Trail", id = "Galaxy" } },
	[28] = { free = { type = "XPBoost", duration = 1800 }, premium = { type = "Coins", amount = 650 } },
	[29] = { free = { type = "Coins", amount = 325 }, premium = { type = "Title", id = "Sky Walker" } },
	[30] = { free = { type = "Trail", id = "Gold" }, premium = { type = "Emote", id = "Dab" } },

	-- Tier 31-40: Late rewards
	[31] = { free = { type = "Coins", amount = 350 }, premium = { type = "Coins", amount = 700 } },
	[32] = { free = nil, premium = { type = "Trail", id = "Neon" } },
	[33] = { free = { type = "XPBoost", duration = 2100 }, premium = { type = "Coins", amount = 750 } },
	[34] = { free = { type = "Coins", amount = 375 }, premium = { type = "Title", id = "Legend" } },
	[35] = { free = { type = "Title", id = "Champion" }, premium = { type = "Emote", id = "Spin" } },
	[36] = { free = { type = "Coins", amount = 400 }, premium = { type = "Coins", amount = 800 } },
	[37] = { free = nil, premium = { type = "Trail", id = "Plasma" } },
	[38] = { free = { type = "XPBoost", duration = 2400 }, premium = { type = "Coins", amount = 850 } },
	[39] = { free = { type = "Coins", amount = 425 }, premium = { type = "Title", id = "Immortal" } },
	[40] = { free = { type = "Trail", id = "Diamond" }, premium = { type = "Emote", id = "Fireworks" } },

	-- Tier 41-50: Final rewards (most valuable)
	[41] = { free = { type = "Coins", amount = 450 }, premium = { type = "Coins", amount = 900 } },
	[42] = { free = nil, premium = { type = "Trail", id = "Aurora" } },
	[43] = { free = { type = "XPBoost", duration = 2700 }, premium = { type = "Coins", amount = 950 } },
	[44] = { free = { type = "Coins", amount = 475 }, premium = { type = "Title", id = "Ascended" } },
	[45] = { free = { type = "Title", id = "Master" }, premium = { type = "Emote", id = "Throne" } },
	[46] = { free = { type = "Coins", amount = 500 }, premium = { type = "Coins", amount = 1000 } },
	[47] = { free = nil, premium = { type = "Trail", id = "Cosmic" } },
	[48] = { free = { type = "XPBoost", duration = 3000 }, premium = { type = "Coins", amount = 1100 } },
	[49] = { free = { type = "Coins", amount = 550 }, premium = { type = "Title", id = "Godlike" } },
	[50] = { free = { type = "Trail", id = "Legendary" }, premium = { type = "Emote", id = "Aura" } },
}

-- ============================================================================
-- CHALLENGE DEFINITIONS
-- ============================================================================

local DAILY_CHALLENGES = {
	{ id = "reach_10", description = "Reach section 10", target = 10, xp = 50 },
	{ id = "reach_25", description = "Reach section 25", target = 25, xp = 75 },
	{ id = "collect_100", description = "Collect 100 coins", target = 100, xp = 50 },
	{ id = "play_3_rounds", description = "Play 3 rounds", target = 3, xp = 60 },
	{ id = "complete_tower", description = "Complete the tower", target = 1, xp = 100 },
}

local WEEKLY_CHALLENGES = {
	{ id = "reach_50_3x", description = "Reach section 50 three times", target = 3, xp = 200 },
	{ id = "collect_1000", description = "Collect 1000 coins total", target = 1000, xp = 150 },
	{ id = "play_20_rounds", description = "Play 20 rounds", target = 20, xp = 175 },
	{ id = "complete_5_towers", description = "Complete 5 towers", target = 5, xp = 250 },
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function BattlePassService.Init()
	print("[BattlePassService] Initializing...")

	-- Create RemoteEvents
	BattlePassService.CreateRemoteEvents()

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		BattlePassService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		BattlePassService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(BattlePassService.OnPlayerJoin, player)
	end

	BattlePassService.IsInitialized = true
	print("[BattlePassService] Initialized - Season " .. CONFIG.SeasonNumber .. ": " .. CONFIG.SeasonName)
end

function BattlePassService.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Battle Pass Progress Update
	if not remoteFolder:FindFirstChild("BattlePassUpdate") then
		local updateEvent = Instance.new("RemoteEvent")
		updateEvent.Name = "BattlePassUpdate"
		updateEvent.Parent = remoteFolder
	end

	-- Claim Reward
	if not remoteFolder:FindFirstChild("ClaimBattlePassReward") then
		local claimEvent = Instance.new("RemoteEvent")
		claimEvent.Name = "ClaimBattlePassReward"
		claimEvent.Parent = remoteFolder

		claimEvent.OnServerEvent:Connect(function(player, tier, isPremium)
			BattlePassService.ClaimReward(player, tier, isPremium)
		end)
	end

	-- Prompt Premium Purchase
	if not remoteFolder:FindFirstChild("PromptBattlePassPurchase") then
		local purchaseEvent = Instance.new("RemoteEvent")
		purchaseEvent.Name = "PromptBattlePassPurchase"
		purchaseEvent.Parent = remoteFolder

		purchaseEvent.OnServerEvent:Connect(function(player)
			BattlePassService.PromptPurchase(player)
		end)
	end

	-- Get Battle Pass Data (RemoteFunction)
	if not remoteFolder:FindFirstChild("GetBattlePassData") then
		local dataFunction = Instance.new("RemoteFunction")
		dataFunction.Name = "GetBattlePassData"
		dataFunction.Parent = remoteFolder

		dataFunction.OnServerInvoke = function(player)
			return BattlePassService.GetPlayerData(player)
		end
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function BattlePassService.OnPlayerJoin(player: Player)
	-- Initialize player progress
	local progress = {
		Tier = 1,
		XP = 0,
		TotalXP = 0,
		Premium = false,
		ClaimedFree = {},
		ClaimedPremium = {},
		DailyChallenges = BattlePassService.GenerateDailyChallenges(),
		WeeklyChallenges = BattlePassService.GenerateWeeklyChallenges(),
		LastDailyReset = os.time(),
		LastWeeklyReset = os.time(),

		-- OPTIMIZATION: Challenge index for O(1) lookup by event type
		ChallengeIndex = {},
	}

	BattlePassService.PlayerProgress[player.UserId] = progress

	-- Build challenge index for fast lookups
	BattlePassService.RebuildChallengeIndex(player)

	-- Check premium status
	task.spawn(function()
		BattlePassService.CheckPremiumStatus(player)
	end)

	-- Load saved progress from DataService
	task.spawn(function()
		BattlePassService.LoadProgress(player)
	end)

	print(string.format("[BattlePassService] Initialized progress for %s", player.Name))
end

function BattlePassService.OnPlayerLeave(player: Player)
	-- Save progress before cleanup
	BattlePassService.SaveProgress(player)

	-- Cleanup
	BattlePassService.PlayerProgress[player.UserId] = nil
end

function BattlePassService.CheckPremiumStatus(player: Player)
	if CONFIG.PremiumPassId == 0 then
		return -- Premium pass not configured
	end

	local success, hasPremium = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, CONFIG.PremiumPassId)
	end)

	if success then
		local progress = BattlePassService.PlayerProgress[player.UserId]
		if progress then
			progress.Premium = hasPremium
			if hasPremium then
				print(string.format("[BattlePassService] %s has Premium Battle Pass", player.Name))
			end
		end
	end
end

-- ============================================================================
-- XP & PROGRESSION
-- ============================================================================

function BattlePassService.AddXP(player: Player, amount: number, source: string)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return end

	-- Validate input
	if type(amount) ~= "number" or amount <= 0 then return end

	progress.XP = progress.XP + amount
	progress.TotalXP = progress.TotalXP + amount

	print(string.format(
		"[BattlePassService] %s earned %d XP (Source: %s, Total: %d)",
		player.Name, amount, source or "Unknown", progress.TotalXP
	))

	-- Check for tier ups
	BattlePassService.CheckTierUp(player)

	-- Notify client
	BattlePassService.NotifyProgress(player)
end

function BattlePassService.GetXPForTier(tier: number): number
	-- Progressive XP requirements
	return math.floor(CONFIG.BaseXPPerTier * (CONFIG.XPScaling ^ (tier - 1)))
end

function BattlePassService.CheckTierUp(player: Player)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return end

	while progress.Tier < CONFIG.MaxTier do
		local xpNeeded = BattlePassService.GetXPForTier(progress.Tier)

		if progress.XP >= xpNeeded then
			-- Tier up!
			progress.XP = progress.XP - xpNeeded
			progress.Tier = progress.Tier + 1

			print(string.format(
				"[BattlePassService] %s reached Tier %d!",
				player.Name, progress.Tier
			))

			-- Notify client of tier up
			BattlePassService.NotifyTierUp(player, progress.Tier)
		else
			break
		end
	end
end

-- ============================================================================
-- REWARDS
-- ============================================================================

function BattlePassService.ClaimReward(player: Player, tier: number, isPremium: boolean)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return false end

	-- Validate tier
	if tier < 1 or tier > CONFIG.MaxTier then
		warn(string.format("[BattlePassService] Invalid tier %d for %s", tier, player.Name))
		return false
	end

	-- Check if player has reached this tier
	if progress.Tier < tier then
		warn(string.format("[BattlePassService] %s hasn't reached tier %d", player.Name, tier))
		return false
	end

	-- Check premium requirement
	if isPremium and not progress.Premium then
		warn(string.format("[BattlePassService] %s doesn't have premium pass", player.Name))
		return false
	end

	-- Check if already claimed
	local claimedList = isPremium and progress.ClaimedPremium or progress.ClaimedFree
	if claimedList[tier] then
		warn(string.format("[BattlePassService] %s already claimed tier %d %s reward",
			player.Name, tier, isPremium and "premium" or "free"))
		return false
	end

	-- Get reward
	local tierRewards = TIER_REWARDS[tier]
	if not tierRewards then return false end

	local reward = isPremium and tierRewards.premium or tierRewards.free
	if not reward then
		warn(string.format("[BattlePassService] No %s reward at tier %d",
			isPremium and "premium" or "free", tier))
		return false
	end

	-- Grant reward
	local success = BattlePassService.GrantReward(player, reward)
	if success then
		claimedList[tier] = true
		print(string.format(
			"[BattlePassService] %s claimed tier %d %s reward: %s",
			player.Name, tier, isPremium and "premium" or "free", reward.type
		))

		-- Notify client
		BattlePassService.NotifyProgress(player)
	end

	return success
end

function BattlePassService.GrantReward(player: Player, reward: {}): boolean
	local rewardType = reward.type

	if rewardType == "Coins" then
		-- Add coins via CoinService
		local success, CoinService = pcall(function()
			return require(script.Parent.Parent.CoinService)
		end)
		if success and CoinService then
			CoinService.AddCoins(player, reward.amount, "BattlePass")
		end
		return true

	elseif rewardType == "XPBoost" then
		-- Grant temporary XP boost (stored as attribute)
		local currentBoost = player:GetAttribute("XPBoostEnd") or 0
		local newEnd = math.max(os.time(), currentBoost) + reward.duration
		player:SetAttribute("XPBoostEnd", newEnd)
		return true

	elseif rewardType == "Title" then
		-- Grant title cosmetic (store in data)
		local success = BattlePassService.GrantCosmetic(player, "Title", reward.id)
		return success

	elseif rewardType == "Trail" then
		-- Grant trail cosmetic
		local success = BattlePassService.GrantCosmetic(player, "Trail", reward.id)
		return success

	elseif rewardType == "Emote" then
		-- Grant emote
		local success = BattlePassService.GrantCosmetic(player, "Emote", reward.id)
		return success
	end

	return false
end

function BattlePassService.GrantCosmetic(player: Player, cosmeticType: string, cosmeticId: string): boolean
	-- Store cosmetic ownership in DataService
	local success, DataService = pcall(function()
		return require(script.Parent.Parent.DataService)
	end)

	if success and DataService then
		local profile = DataService.GetProfile(player)
		if profile then
			-- Initialize cosmetics table if needed
			if not profile.Data.Cosmetics then
				profile.Data.Cosmetics = {
					Titles = {},
					Trails = {},
					Emotes = {},
				}
			end

			-- Add cosmetic
			local category = cosmeticType .. "s" -- "Title" -> "Titles"
			if profile.Data.Cosmetics[category] then
				profile.Data.Cosmetics[category][cosmeticId] = true
				print(string.format("[BattlePassService] Granted %s '%s' to %s",
					cosmeticType, cosmeticId, player.Name))
				return true
			end
		end
	end

	return false
end

-- ============================================================================
-- CHALLENGES
-- ============================================================================

function BattlePassService.GenerateDailyChallenges(): {}
	-- Pick 3 random daily challenges
	local challenges = {}
	local available = table.clone(DAILY_CHALLENGES)

	for i = 1, math.min(3, #available) do
		local index = math.random(1, #available)
		local challenge = table.remove(available, index)
		table.insert(challenges, {
			id = challenge.id,
			description = challenge.description,
			target = challenge.target,
			xp = challenge.xp,
			progress = 0,
			completed = false,
		})
	end

	return challenges
end

function BattlePassService.GenerateWeeklyChallenges(): {}
	-- Pick 2 random weekly challenges
	local challenges = {}
	local available = table.clone(WEEKLY_CHALLENGES)

	for i = 1, math.min(2, #available) do
		local index = math.random(1, #available)
		local challenge = table.remove(available, index)
		table.insert(challenges, {
			id = challenge.id,
			description = challenge.description,
			target = challenge.target,
			xp = challenge.xp,
			progress = 0,
			completed = false,
		})
	end

	return challenges
end

function BattlePassService.RebuildChallengeIndex(player: Player)
	--[[
		OPTIMIZATION: Builds an index mapping event types to challenges.
		This changes O(n) iteration to O(1) lookup when updating progress.
	--]]
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return end

	-- Clear existing index
	progress.ChallengeIndex = {}

	-- Index daily challenges
	for _, challenge in ipairs(progress.DailyChallenges) do
		if not challenge.completed then
			local eventType = BattlePassService.GetChallengeEventType(challenge.id)
			if eventType then
				if not progress.ChallengeIndex[eventType] then
					progress.ChallengeIndex[eventType] = {}
				end
				table.insert(progress.ChallengeIndex[eventType], {
					challenge = challenge,
					isWeekly = false,
				})
			end
		end
	end

	-- Index weekly challenges
	for _, challenge in ipairs(progress.WeeklyChallenges) do
		if not challenge.completed then
			local eventType = BattlePassService.GetChallengeEventType(challenge.id)
			if eventType then
				if not progress.ChallengeIndex[eventType] then
					progress.ChallengeIndex[eventType] = {}
				end
				table.insert(progress.ChallengeIndex[eventType], {
					challenge = challenge,
					isWeekly = true,
				})
			end
		end
	end
end

function BattlePassService.GetChallengeEventType(challengeId: string): string?
	-- Maps challenge IDs to event types
	local mappings = {
		["reach_10"] = "SectionReached",
		["reach_25"] = "SectionReached",
		["reach_50_3x"] = "TowerCompleted",
		["collect_100"] = "CoinsCollected",
		["collect_1000"] = "CoinsCollected",
		["play_3_rounds"] = "RoundPlayed",
		["play_20_rounds"] = "RoundPlayed",
		["complete_tower"] = "TowerCompleted",
		["complete_5_towers"] = "TowerCompleted",
	}
	return mappings[challengeId]
end

function BattlePassService.UpdateChallengeProgress(player: Player, challengeType: string, amount: number)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return end

	-- OPTIMIZATION: Use indexed lookup instead of iterating all challenges
	local relevantChallenges = progress.ChallengeIndex[challengeType]
	if not relevantChallenges then return end -- No challenges for this event type

	-- Only iterate through challenges that match this event type
	for i = #relevantChallenges, 1, -1 do
		local entry = relevantChallenges[i]
		local challenge = entry.challenge

		challenge.progress = challenge.progress + amount
		if challenge.progress >= challenge.target then
			challenge.completed = true

			-- Award XP
			local challengeSource = entry.isWeekly and "WeeklyChallenge" or "DailyChallenge"
			BattlePassService.AddXP(player, challenge.xp, challengeSource)

			print(string.format("[BattlePassService] %s completed %s: %s",
				player.Name,
				entry.isWeekly and "weekly" or "daily",
				challenge.description
			))

			-- Remove from index (completed challenges don't need checking anymore)
			table.remove(relevantChallenges, i)
		end
	end
end

-- REMOVED: MatchesChallengeType (replaced by GetChallengeEventType + indexed lookup)

-- ============================================================================
-- DATA PERSISTENCE
-- ============================================================================

function BattlePassService.SaveProgress(player: Player)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return end

	local success, DataService = pcall(function()
		return require(script.Parent.Parent.DataService)
	end)

	if success and DataService then
		local profile = DataService.GetProfile(player)
		if profile then
			profile.Data.BattlePass = {
				Season = CONFIG.SeasonNumber,
				Tier = progress.Tier,
				XP = progress.XP,
				TotalXP = progress.TotalXP,
				ClaimedFree = progress.ClaimedFree,
				ClaimedPremium = progress.ClaimedPremium,
				DailyChallenges = progress.DailyChallenges,
				WeeklyChallenges = progress.WeeklyChallenges,
				LastDailyReset = progress.LastDailyReset,
				LastWeeklyReset = progress.LastWeeklyReset,
			}
		end
	end
end

function BattlePassService.LoadProgress(player: Player)
	local success, DataService = pcall(function()
		return require(script.Parent.Parent.DataService)
	end)

	if success and DataService then
		local profile = DataService.GetProfile(player)
		if profile and profile.Data.BattlePass then
			local saved = profile.Data.BattlePass

			-- Check if same season
			if saved.Season == CONFIG.SeasonNumber then
				local progress = BattlePassService.PlayerProgress[player.UserId]
				if progress then
					progress.Tier = saved.Tier or 1
					progress.XP = saved.XP or 0
					progress.TotalXP = saved.TotalXP or 0
					progress.ClaimedFree = saved.ClaimedFree or {}
					progress.ClaimedPremium = saved.ClaimedPremium or {}
					progress.DailyChallenges = saved.DailyChallenges or progress.DailyChallenges
					progress.WeeklyChallenges = saved.WeeklyChallenges or progress.WeeklyChallenges
					progress.LastDailyReset = saved.LastDailyReset or os.time()
					progress.LastWeeklyReset = saved.LastWeeklyReset or os.time()

					-- Check for challenge resets
					BattlePassService.CheckChallengeResets(player)

					-- Rebuild challenge index for loaded data
					BattlePassService.RebuildChallengeIndex(player)

					print(string.format("[BattlePassService] Loaded progress for %s: Tier %d",
						player.Name, progress.Tier))
				end
			else
				-- New season - reset progress
				print(string.format("[BattlePassService] New season for %s - resetting progress", player.Name))
			end
		end
	end
end

function BattlePassService.CheckChallengeResets(player: Player)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then return end

	local now = os.time()
	local oneDaySeconds = 24 * 60 * 60
	local oneWeekSeconds = 7 * oneDaySeconds

	-- Reset daily challenges if 24+ hours since last reset
	if now - progress.LastDailyReset >= oneDaySeconds then
		progress.DailyChallenges = BattlePassService.GenerateDailyChallenges()
		progress.LastDailyReset = now
		BattlePassService.RebuildChallengeIndex(player) -- Rebuild index after reset
		print(string.format("[BattlePassService] Reset daily challenges for %s", player.Name))
	end

	-- Reset weekly challenges if 7+ days since last reset
	if now - progress.LastWeeklyReset >= oneWeekSeconds then
		progress.WeeklyChallenges = BattlePassService.GenerateWeeklyChallenges()
		progress.LastWeeklyReset = now
		BattlePassService.RebuildChallengeIndex(player) -- Rebuild index after reset
		print(string.format("[BattlePassService] Reset weekly challenges for %s", player.Name))
	end
end

-- ============================================================================
-- PURCHASE HANDLING
-- ============================================================================

BattlePassService.PurchaseRateLimits = {}

function BattlePassService.PromptPurchase(player: Player)
	if CONFIG.PremiumPassId == 0 then
		warn("[BattlePassService] Premium pass ID not configured")
		return
	end

	-- Rate limiting
	local now = tick()
	local lastPrompt = BattlePassService.PurchaseRateLimits[player.UserId] or 0
	if now - lastPrompt < CONFIG.PurchasePromptCooldown then
		return
	end
	BattlePassService.PurchaseRateLimits[player.UserId] = now

	-- Check if already has premium
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if progress and progress.Premium then
		print(string.format("[BattlePassService] %s already has premium", player.Name))
		return
	end

	-- Prompt purchase
	task.spawn(function()
		local success, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, CONFIG.PremiumPassId)
		end)
		if not success then
			warn(string.format("[BattlePassService] Purchase prompt failed for %s: %s",
				player.Name, tostring(err)))
		end
	end)
end

-- Listen for premium pass purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if gamePassId == CONFIG.PremiumPassId and wasPurchased then
		local progress = BattlePassService.PlayerProgress[player.UserId]
		if progress then
			progress.Premium = true
			print(string.format("[BattlePassService] %s purchased Premium Battle Pass!", player.Name))
			BattlePassService.NotifyProgress(player)
		end
	end
end)

-- ============================================================================
-- CLIENT COMMUNICATION
-- ============================================================================

function BattlePassService.NotifyProgress(player: Player)
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then return end

	local updateEvent = remoteFolder:FindFirstChild("BattlePassUpdate")
	if updateEvent then
		local data = BattlePassService.GetPlayerData(player)
		updateEvent:FireClient(player, data)
	end
end

function BattlePassService.NotifyTierUp(player: Player, newTier: number)
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then return end

	local updateEvent = remoteFolder:FindFirstChild("BattlePassUpdate")
	if updateEvent then
		local data = BattlePassService.GetPlayerData(player)
		data.TierUp = newTier -- Signal tier up to client
		updateEvent:FireClient(player, data)
	end
end

function BattlePassService.GetPlayerData(player: Player): {}
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if not progress then
		return {
			Tier = 1,
			XP = 0,
			XPNeeded = CONFIG.BaseXPPerTier,
			Premium = false,
			SeasonName = CONFIG.SeasonName,
			SeasonNumber = CONFIG.SeasonNumber,
		}
	end

	return {
		Tier = progress.Tier,
		XP = progress.XP,
		TotalXP = progress.TotalXP,
		XPNeeded = BattlePassService.GetXPForTier(progress.Tier),
		Premium = progress.Premium,
		ClaimedFree = progress.ClaimedFree,
		ClaimedPremium = progress.ClaimedPremium,
		DailyChallenges = progress.DailyChallenges,
		WeeklyChallenges = progress.WeeklyChallenges,
		SeasonName = CONFIG.SeasonName,
		SeasonNumber = CONFIG.SeasonNumber,
		MaxTier = CONFIG.MaxTier,
		Rewards = TIER_REWARDS,
	}
end

-- ============================================================================
-- GAMEPLAY HOOKS (called by other services)
-- ============================================================================

function BattlePassService.OnSectionReached(player: Player, section: number)
	-- Award XP for reaching section
	BattlePassService.AddXP(player, CONFIG.XPPerSection, "SectionReached")

	-- Update challenge progress
	BattlePassService.UpdateChallengeProgress(player, "SectionReached", 1)
end

function BattlePassService.OnTowerCompleted(player: Player)
	-- Award XP for completing tower
	BattlePassService.AddXP(player, CONFIG.XPPerTowerComplete, "TowerCompleted")

	-- Update challenge progress
	BattlePassService.UpdateChallengeProgress(player, "TowerCompleted", 1)
end

function BattlePassService.OnCoinsCollected(player: Player, amount: number)
	-- Update challenge progress (no direct XP, just challenge tracking)
	BattlePassService.UpdateChallengeProgress(player, "CoinsCollected", amount)
end

function BattlePassService.OnRoundPlayed(player: Player)
	-- Update challenge progress
	BattlePassService.UpdateChallengeProgress(player, "RoundPlayed", 1)
end

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

function BattlePassService.AdminAddXP(player: Player, amount: number)
	print(string.format("[BattlePassService] ADMIN: Adding %d XP to %s", amount, player.Name))
	BattlePassService.AddXP(player, amount, "Admin")
end

function BattlePassService.AdminSetTier(player: Player, tier: number)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if progress then
		progress.Tier = math.clamp(tier, 1, CONFIG.MaxTier)
		progress.XP = 0
		print(string.format("[BattlePassService] ADMIN: Set %s to tier %d", player.Name, progress.Tier))
		BattlePassService.NotifyProgress(player)
	end
end

function BattlePassService.AdminGrantPremium(player: Player)
	local progress = BattlePassService.PlayerProgress[player.UserId]
	if progress then
		progress.Premium = true
		print(string.format("[BattlePassService] ADMIN: Granted premium to %s", player.Name))
		BattlePassService.NotifyProgress(player)
	end
end

function BattlePassService.DebugPrint()
	print("=== BATTLE PASS SERVICE STATUS ===")
	print(string.format("Season: %d - %s", CONFIG.SeasonNumber, CONFIG.SeasonName))
	print(string.format("Max Tier: %d", CONFIG.MaxTier))
	print(string.format("Premium Pass ID: %d", CONFIG.PremiumPassId))
	print(string.format("Active Players: %d", #Players:GetPlayers()))

	for userId, progress in pairs(BattlePassService.PlayerProgress) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			print(string.format("  %s: Tier %d, XP %d/%d, Premium: %s",
				player.Name,
				progress.Tier,
				progress.XP,
				BattlePassService.GetXPForTier(progress.Tier),
				progress.Premium and "Yes" or "No"
			))
		end
	end
	print("==================================")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return BattlePassService
