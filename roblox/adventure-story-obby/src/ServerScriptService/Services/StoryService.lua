--[[
	StoryService.lua
	Manages story progression and world state

	Handles:
	- Level completion tracking
	- World unlocking
	- Story progression validation
	- Level rewards
	- Integration with DataService
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StoryChapters = require(ReplicatedStorage.Shared.Data.StoryChapters)
local StoryConfig = require(ReplicatedStorage.Shared.Config.StoryConfig)

local StoryService = {}
local DataService = nil -- Lazy loaded

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function StoryService.Init()
	print("[StoryService] Initializing...")

	-- Lazy load DataService to avoid circular dependencies
	DataService = require(ServerScriptService.Services.DataService)

	-- Setup remote handlers
	StoryService.SetupRemoteHandlers()

	print("[StoryService] Initialized")
end

-- ============================================================================
-- LEVEL PROGRESSION
-- ============================================================================

function StoryService.CompleteLevel(player: Player, worldId: number, levelId: number): boolean
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[StoryService] Invalid player in CompleteLevel")
		return false
	end

	-- Validate level exists
	local levelData = StoryChapters.GetLevel(worldId, levelId)
	if not levelData then
		warn(string.format("[StoryService] Invalid level: World%d_Level%d", worldId, levelId))
		return false
	end

	-- Get player data
	local profile = DataService.GetProfile(player)
	if not profile then
		warn("[StoryService] No profile found for player:", player.Name)
		return false
	end

	local levelKey = string.format("World%d_Level%d", worldId, levelId)

	-- Check if already completed
	if profile.Data.Story.CompletedLevels[levelKey] then
		-- Already completed, but allow replaying (no rewards)
		print(string.format("[StoryService] %s replayed %s", player.Name, levelKey))
		return true
	end

	-- Mark level as completed
	profile.Data.Story.CompletedLevels[levelKey] = true

	-- Update current level
	if worldId == profile.Data.Story.CurrentWorld then
		if levelId >= profile.Data.Story.CurrentLevel then
			profile.Data.Story.CurrentLevel = levelId + 1
		end
	end

	-- Award rewards
	if levelData.Rewards then
		if levelData.Rewards.Coins then
			DataService.AddCoins(player, levelData.Rewards.Coins)
		end
	end

	-- Check if world is complete
	local totalLevels = StoryChapters.GetTotalLevels(worldId)
	if levelId == totalLevels then
		StoryService.CompleteWorld(player, worldId)
	end

	print(string.format("[StoryService] %s completed %s (Rewards: %d coins)",
		player.Name, levelKey, levelData.Rewards.Coins or 0))

	return true
end

function StoryService.CompleteWorld(player: Player, worldId: number)
	local profile = DataService.GetProfile(player)
	if not profile then return end

	-- Unlock next world
	local nextWorldId = worldId + 1
	if not table.find(profile.Data.Story.UnlockedWorlds, nextWorldId) then
		table.insert(profile.Data.Story.UnlockedWorlds, nextWorldId)
		print(string.format("[StoryService] %s unlocked World %d", player.Name, nextWorldId))
	end

	-- World completion rewards
	local worldRewards = StoryConfig.Progression.WorldRewards[worldId]
	if worldRewards then
		if worldRewards.Coins then
			DataService.AddCoins(player, worldRewards.Coins)
		end
		print(string.format("[StoryService] %s completed World %d (Bonus: %d coins)",
			player.Name, worldId, worldRewards.Coins or 0))
	end
end

-- ============================================================================
-- LEVEL ACCESS
-- ============================================================================

function StoryService.IsLevelUnlocked(player: Player, worldId: number, levelId: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	-- Check if world is unlocked
	if not table.find(profile.Data.Story.UnlockedWorlds, worldId) then
		return false
	end

	-- Level 1 always unlocked if world is unlocked
	if levelId == 1 then
		return true
	end

	-- Check if previous level is complete
	local previousLevelKey = string.format("World%d_Level%d", worldId, levelId - 1)
	return profile.Data.Story.CompletedLevels[previousLevelKey] == true
end

function StoryService.IsWorldUnlocked(player: Player, worldId: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	return table.find(profile.Data.Story.UnlockedWorlds, worldId) ~= nil
end

-- ============================================================================
-- STORY DATA
-- ============================================================================

function StoryService.GetStoryData(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then return nil end

	return {
		CurrentWorld = profile.Data.Story.CurrentWorld,
		CurrentLevel = profile.Data.Story.CurrentLevel,
		CompletedLevels = profile.Data.Story.CompletedLevels,
		UnlockedWorlds = profile.Data.Story.UnlockedWorlds,
		CollectedFragments = profile.Data.Story.CollectedFragments,
	}
end

function StoryService.GetLevelInfo(player: Player, worldId: number, levelId: number)
	local levelData = StoryChapters.GetLevel(worldId, levelId)
	if not levelData then return nil end

	local isUnlocked = StoryService.IsLevelUnlocked(player, worldId, levelId)
	local profile = DataService.GetProfile(player)
	local levelKey = string.format("World%d_Level%d", worldId, levelId)
	local isCompleted = profile and profile.Data.Story.CompletedLevels[levelKey] or false

	return {
		Name = levelData.Name,
		Description = levelData.Description,
		Difficulty = levelData.Difficulty,
		EstimatedTime = levelData.EstimatedTime,
		Rewards = levelData.Rewards,
		IsUnlocked = isUnlocked,
		IsCompleted = isCompleted,
	}
end

-- ============================================================================
-- FRAGMENTS (Collectibles)
-- ============================================================================

function StoryService.CollectFragment(player: Player, fragmentId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	-- Check if already collected
	if profile.Data.Story.CollectedFragments[fragmentId] then
		warn(string.format("[StoryService] %s already collected %s", player.Name, fragmentId))
		return false
	end

	-- Mark as collected
	profile.Data.Story.CollectedFragments[fragmentId] = true

	-- Award coins
	local coinReward = StoryConfig.Collectibles.Types.Fragment.CoinReward
	DataService.AddCoins(player, coinReward)

	print(string.format("[StoryService] %s collected %s (+%d coins)",
		player.Name, fragmentId, coinReward))

	return true
end

function StoryService.HasFragment(player: Player, fragmentId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then return false end

	return profile.Data.Story.CollectedFragments[fragmentId] == true
end

-- ============================================================================
-- NPC RELATIONSHIPS
-- ============================================================================

function StoryService.IncreaseRelationship(player: Player, npcName: string, amount: number)
	local profile = DataService.GetProfile(player)
	if not profile then return end

	local current = profile.Data.Story.NPCRelationships[npcName] or 0
	profile.Data.Story.NPCRelationships[npcName] = current + amount

	print(string.format("[StoryService] %s relationship with %s increased to %d",
		player.Name, npcName, current + amount))
end

function StoryService.GetRelationship(player: Player, npcName: string): number
	local profile = DataService.GetProfile(player)
	if not profile then return 0 end

	return profile.Data.Story.NPCRelationships[npcName] or 0
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

function StoryService.SetupRemoteHandlers()
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

	-- CompleteLevel
	local completeLevelRemote = RemoteEventsInit.GetRemote("CompleteLevel")
	if completeLevelRemote and completeLevelRemote.Remote then
		completeLevelRemote.Remote.OnServerInvoke = function(player, worldId, levelId)
			return StoryService.CompleteLevel(player, worldId, levelId)
		end
	end

	-- GetStoryData
	local getStoryDataRemote = RemoteEventsInit.GetRemote("GetStoryData")
	if getStoryDataRemote and getStoryDataRemote.Remote then
		getStoryDataRemote.Remote.OnServerInvoke = function(player)
			return StoryService.GetStoryData(player)
		end
	end

	-- GetLevelInfo
	local getLevelInfoRemote = RemoteEventsInit.GetRemote("GetLevelInfo")
	if getLevelInfoRemote and getLevelInfoRemote.Remote then
		getLevelInfoRemote.Remote.OnServerInvoke = function(player, worldId, levelId)
			return StoryService.GetLevelInfo(player, worldId, levelId)
		end
	end

	-- IsLevelUnlocked
	local isLevelUnlockedRemote = RemoteEventsInit.GetRemote("IsLevelUnlocked")
	if isLevelUnlockedRemote and isLevelUnlockedRemote.Remote then
		isLevelUnlockedRemote.Remote.OnServerInvoke = function(player, worldId, levelId)
			return StoryService.IsLevelUnlocked(player, worldId, levelId)
		end
	end

	print("[StoryService] Remote handlers setup complete")
end

return StoryService
