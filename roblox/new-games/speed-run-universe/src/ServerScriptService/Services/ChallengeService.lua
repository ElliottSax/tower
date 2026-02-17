--[[
	ChallengeService.lua - Speed Run Universe
	Daily and weekly challenge generation, progress tracking, and reward claiming.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local ChallengeService = {}
ChallengeService.DataService = nil
ChallengeService.SecurityManager = nil

-- Number of daily/weekly challenges to generate
local DAILY_CHALLENGE_COUNT = 3
local WEEKLY_CHALLENGE_COUNT = 2

-- ============================================================================
-- INIT
-- ============================================================================
function ChallengeService.Init()
	ChallengeService.DataService = require(ServerScriptService.Services.DataService)
	ChallengeService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Client requests challenge list
	re:WaitForChild("RequestChallenges").OnServerEvent:Connect(function(player)
		ChallengeService.SendChallenges(player)
	end)

	-- Claim reward
	re:WaitForChild("ClaimChallengeReward").OnServerEvent:Connect(function(player, data)
		ChallengeService.ClaimReward(player, data)
	end)

	print("[ChallengeService] Initialized")
end

-- ============================================================================
-- CHALLENGE GENERATION
-- ============================================================================
function ChallengeService.EnsureDailyChallenges(player)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local today = os.date("%Y-%m-%d")
	if data.LastDailyChallengeDate == today and #data.DailyChallenges > 0 then
		return -- Already generated today
	end

	-- Generate new daily challenges
	data.DailyChallenges = {}
	data.LastDailyChallengeDate = today

	local templates = GameConfig.DailyChallengeTemplates
	local usedTypes = {}

	for i = 1, DAILY_CHALLENGE_COUNT do
		local challenge = ChallengeService._GenerateChallenge(templates, usedTypes, "daily", i)
		if challenge then
			table.insert(data.DailyChallenges, challenge)
		end
	end

	print("[ChallengeService] Generated", #data.DailyChallenges, "daily challenges for", player.Name)
end

function ChallengeService.EnsureWeeklyChallenges(player)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	-- Weekly challenges reset on Monday
	local weekId = os.date("%Y-W%W")
	if data.LastWeeklyChallengeDate == weekId and #data.WeeklyChallenges > 0 then
		return
	end

	data.WeeklyChallenges = {}
	data.LastWeeklyChallengeDate = weekId

	local templates = GameConfig.WeeklyChallengeTemplates
	local usedTypes = {}

	for i = 1, WEEKLY_CHALLENGE_COUNT do
		local challenge = ChallengeService._GenerateChallenge(templates, usedTypes, "weekly", i)
		if challenge then
			table.insert(data.WeeklyChallenges, challenge)
		end
	end

	print("[ChallengeService] Generated", #data.WeeklyChallenges, "weekly challenges for", player.Name)
end

function ChallengeService._GenerateChallenge(templates, usedTypes, period, seed)
	-- Deterministic-ish random based on date + seed for consistency
	local dayNum = os.time() / 86400
	local rng = Random.new(math.floor(dayNum) * 100 + seed)

	-- Pick a template not already used
	local attempts = 0
	local template
	repeat
		local idx = rng:NextInteger(1, #templates)
		template = templates[idx]
		attempts = attempts + 1
	until not usedTypes[template.Type] or attempts > 20

	if not template then return nil end
	usedTypes[template.Type] = true

	local challenge = {
		Type = template.Type,
		Period = period,
		CoinReward = template.CoinReward,
		Progress = 0,
		Target = 1,
		Completed = false,
		Claimed = false,
		Description = template.Description,
	}

	-- Fill in specific parameters based on type
	if template.Type == "CompleteWorldUnderTime" then
		local worldIdx = rng:NextInteger(1, #(template.Worlds or {"Grass"}))
		local worldId = (template.Worlds or {"Grass"})[worldIdx]
		local timeLimit = (template.TimeLimits or {120})[worldIdx] or 120
		challenge.WorldId = worldId
		challenge.Target = 1
		challenge.TimeLimit = timeLimit
		challenge.Description = string.format(template.Description, worldId, timeLimit)

	elseif template.Type == "CollectCoinsInWorld" then
		local range = template.AmountRange or { 50, 150 }
		local amount = rng:NextInteger(range[1], range[2])
		local worlds = {}
		for _, w in ipairs(GameConfig.Worlds) do table.insert(worlds, w.Id) end
		local worldId = worlds[rng:NextInteger(1, #worlds)]
		challenge.WorldId = worldId
		challenge.Target = amount
		challenge.Description = string.format(template.Description, amount, worldId)

	elseif template.Type == "CompleteStagesNoDeaths" then
		local range = template.AmountRange or { 3, 10 }
		local amount = rng:NextInteger(range[1], range[2])
		challenge.Target = amount
		challenge.Description = string.format(template.Description, amount)
		challenge.NoDeathStreak = 0

	elseif template.Type == "UseAbilityCount" then
		local range = template.AmountRange or { 10, 50 }
		local amount = rng:NextInteger(range[1], range[2])
		local abilities = GameConfig.Abilities
		local ability = abilities[rng:NextInteger(1, #abilities)]
		challenge.AbilityId = ability.Id
		challenge.Target = amount
		challenge.Description = string.format(template.Description, ability.Name, amount)

	elseif template.Type == "BeatPersonalBest" then
		challenge.Target = 1
		challenge.Description = template.Description

	elseif template.Type == "CompleteStagesTotal" then
		local range = template.AmountRange or { 10, 30 }
		local amount = rng:NextInteger(range[1], range[2])
		challenge.Target = amount
		challenge.Description = string.format(template.Description, amount)

	elseif template.Type == "CompleteAllStagesInWorld" then
		local worlds = {}
		for _, w in ipairs(GameConfig.Worlds) do table.insert(worlds, w.Id) end
		local worldId = worlds[rng:NextInteger(1, #worlds)]
		challenge.WorldId = worldId
		challenge.Target = 10 -- stages per world
		challenge.Description = string.format(template.Description, worldId)

	elseif template.Type == "TotalSpeedrunTime" then
		challenge.Target = 1
		challenge.TimeTarget = template.TimeTarget or 600
		challenge.Description = template.Description

	elseif template.Type == "CollectTotalCoins" then
		local range = template.AmountRange or { 500, 2000 }
		local amount = rng:NextInteger(range[1], range[2])
		challenge.Target = amount
		challenge.Description = string.format(template.Description, amount)
	end

	return challenge
end

-- ============================================================================
-- PROGRESS TRACKING (called by other services)
-- ============================================================================
function ChallengeService.OnStageComplete(player, worldId, stageNum)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local updated = false

	-- Check all active challenges
	for _, challenge in ipairs(data.DailyChallenges) do
		if challenge.Completed then continue end
		updated = ChallengeService._UpdateChallengeProgress(challenge, "StageComplete", {
			WorldId = worldId, StageNum = stageNum, Player = player,
		}) or updated
	end

	for _, challenge in ipairs(data.WeeklyChallenges) do
		if challenge.Completed then continue end
		updated = ChallengeService._UpdateChallengeProgress(challenge, "StageComplete", {
			WorldId = worldId, StageNum = stageNum, Player = player,
		}) or updated
	end

	if updated then
		ChallengeService._SyncChallenges(player)
	end
end

function ChallengeService.OnCoinCollected(player, worldId, amount)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local updated = false

	for _, challenge in ipairs(data.DailyChallenges) do
		if challenge.Completed then continue end
		updated = ChallengeService._UpdateChallengeProgress(challenge, "CoinCollected", {
			WorldId = worldId, Amount = amount,
		}) or updated
	end

	for _, challenge in ipairs(data.WeeklyChallenges) do
		if challenge.Completed then continue end
		updated = ChallengeService._UpdateChallengeProgress(challenge, "CoinCollected", {
			WorldId = worldId, Amount = amount,
		}) or updated
	end

	if updated then
		ChallengeService._SyncChallenges(player)
	end
end

function ChallengeService.OnAbilityUsed(player, abilityId)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local updated = false

	for _, challenge in ipairs(data.DailyChallenges) do
		if challenge.Completed then continue end
		updated = ChallengeService._UpdateChallengeProgress(challenge, "AbilityUsed", {
			AbilityId = abilityId,
		}) or updated
	end

	for _, challenge in ipairs(data.WeeklyChallenges) do
		if challenge.Completed then continue end
		updated = ChallengeService._UpdateChallengeProgress(challenge, "AbilityUsed", {
			AbilityId = abilityId,
		}) or updated
	end

	if updated then
		ChallengeService._SyncChallenges(player)
	end
end

function ChallengeService.OnPersonalBestBeaten(player)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local updated = false

	for _, challenge in ipairs(data.DailyChallenges) do
		if challenge.Completed then continue end
		if challenge.Type == "BeatPersonalBest" then
			challenge.Progress = 1
			challenge.Completed = true
			updated = true
		end
	end

	for _, challenge in ipairs(data.WeeklyChallenges) do
		if challenge.Completed then continue end
		if challenge.Type == "BeatPersonalBest" then
			challenge.Progress = 1
			challenge.Completed = true
			updated = true
		end
	end

	if updated then
		ChallengeService._SyncChallenges(player)
	end
end

function ChallengeService.OnWorldCompleteUnderTime(player, worldId, totalTime)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local updated = false

	for _, challenge in ipairs(data.DailyChallenges) do
		if challenge.Completed then continue end
		if challenge.Type == "CompleteWorldUnderTime" and challenge.WorldId == worldId then
			if totalTime <= challenge.TimeLimit then
				challenge.Progress = 1
				challenge.Completed = true
				updated = true
			end
		end
	end

	for _, challenge in ipairs(data.WeeklyChallenges) do
		if challenge.Completed then continue end
		if challenge.Type == "CompleteWorldUnderTime" and challenge.WorldId == worldId then
			if totalTime <= challenge.TimeLimit then
				challenge.Progress = 1
				challenge.Completed = true
				updated = true
			end
		end
	end

	if updated then
		ChallengeService._SyncChallenges(player)
	end
end

-- ============================================================================
-- INTERNAL PROGRESS UPDATE
-- ============================================================================
function ChallengeService._UpdateChallengeProgress(challenge, eventType, eventData)
	local updated = false

	if challenge.Type == "CompleteStagesTotal" and eventType == "StageComplete" then
		challenge.Progress = challenge.Progress + 1
		if challenge.Progress >= challenge.Target then
			challenge.Completed = true
		end
		updated = true

	elseif challenge.Type == "CompleteStagesNoDeaths" and eventType == "StageComplete" then
		challenge.NoDeathStreak = (challenge.NoDeathStreak or 0) + 1
		challenge.Progress = challenge.NoDeathStreak
		if challenge.Progress >= challenge.Target then
			challenge.Completed = true
		end
		updated = true

	elseif challenge.Type == "CollectCoinsInWorld" and eventType == "CoinCollected" then
		if not challenge.WorldId or challenge.WorldId == eventData.WorldId then
			challenge.Progress = challenge.Progress + (eventData.Amount or 1)
			if challenge.Progress >= challenge.Target then
				challenge.Completed = true
			end
			updated = true
		end

	elseif challenge.Type == "CollectTotalCoins" and eventType == "CoinCollected" then
		challenge.Progress = challenge.Progress + (eventData.Amount or 1)
		if challenge.Progress >= challenge.Target then
			challenge.Completed = true
		end
		updated = true

	elseif challenge.Type == "UseAbilityCount" and eventType == "AbilityUsed" then
		if challenge.AbilityId == eventData.AbilityId then
			challenge.Progress = challenge.Progress + 1
			if challenge.Progress >= challenge.Target then
				challenge.Completed = true
			end
			updated = true
		end

	elseif challenge.Type == "CompleteAllStagesInWorld" and eventType == "StageComplete" then
		if challenge.WorldId == eventData.WorldId then
			challenge.Progress = challenge.Progress + 1
			if challenge.Progress >= challenge.Target then
				challenge.Completed = true
			end
			updated = true
		end
	end

	return updated
end

-- ============================================================================
-- CLAIM REWARD
-- ============================================================================
function ChallengeService.ClaimReward(player, data)
	if not ChallengeService.SecurityManager.CheckRateLimit(player, "ClaimChallengeReward") then return end
	if not data or not data.ChallengeIndex or not data.Period then return end

	local playerData = ChallengeService.DataService.GetFullData(player)
	if not playerData then return end

	local challengeList
	if data.Period == "daily" then
		challengeList = playerData.DailyChallenges
	elseif data.Period == "weekly" then
		challengeList = playerData.WeeklyChallenges
	else
		return
	end

	local index = tonumber(data.ChallengeIndex)
	if not index or index < 1 or index > #challengeList then return end

	local challenge = challengeList[index]
	if not challenge.Completed or challenge.Claimed then
		ChallengeService._Notify(player, "Challenge not complete or already claimed!")
		return
	end

	-- Grant reward
	challenge.Claimed = true
	ChallengeService.DataService.AddCoins(player, challenge.CoinReward)

	-- Notify
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local completeEvent = re:FindFirstChild("ChallengeComplete")
		if completeEvent then
			completeEvent:FireClient(player, {
				Period = data.Period,
				Index = index,
				CoinReward = challenge.CoinReward,
			})
		end
	end

	ChallengeService._Notify(player, "Challenge reward claimed: +" .. challenge.CoinReward .. " coins!")
	ChallengeService._SyncChallenges(player)
end

-- ============================================================================
-- SEND / SYNC CHALLENGES
-- ============================================================================
function ChallengeService.SendChallenges(player)
	ChallengeService.EnsureDailyChallenges(player)
	ChallengeService.EnsureWeeklyChallenges(player)
	ChallengeService._SyncChallenges(player)
end

function ChallengeService._SyncChallenges(player)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local sync = re:FindFirstChild("ChallengeSync")
		if sync then
			sync:FireClient(player, {
				DailyChallenges = data.DailyChallenges,
				WeeklyChallenges = data.WeeklyChallenges,
			})
		end
	end
end

-- ============================================================================
-- DEATH RESET (for no-death streak challenges)
-- ============================================================================
function ChallengeService.OnPlayerDeath(player)
	local data = ChallengeService.DataService.GetFullData(player)
	if not data then return end

	for _, challenge in ipairs(data.DailyChallenges) do
		if challenge.Type == "CompleteStagesNoDeaths" and not challenge.Completed then
			challenge.NoDeathStreak = 0
			challenge.Progress = 0
		end
	end

	for _, challenge in ipairs(data.WeeklyChallenges) do
		if challenge.Type == "CompleteStagesNoDeaths" and not challenge.Completed then
			challenge.NoDeathStreak = 0
			challenge.Progress = 0
		end
	end
end

-- ============================================================================
-- UTILITY
-- ============================================================================
function ChallengeService._Notify(player, message)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local notif = re:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Message = message })
		end
	end
end

return ChallengeService
