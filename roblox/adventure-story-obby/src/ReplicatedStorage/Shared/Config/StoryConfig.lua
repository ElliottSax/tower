--[[
	StoryConfig.lua
	Configuration for Adventure Story Obby

	Defines:
	- World structure and progression
	- NPC settings
	- Quest parameters
	- Collectible settings
	- Story parameters
--]]

local StoryConfig = {}

-- ============================================================================
-- WORLD STRUCTURE
-- ============================================================================

StoryConfig.Worlds = {
	{
		Id = 1,
		Name = "Mystic Forest",
		Description = "A cursed forest shrouded in ancient magic",
		LevelCount = 5,
		UnlockRequirement = nil, -- Always unlocked
		Theme = {
			Ambient = Color3.fromRGB(100, 150, 100),
			Fog = Color3.fromRGB(180, 200, 180),
			FogEnd = 500,
		}
	},
	-- Future worlds can be added here
	-- {
	-- 	Id = 2,
	-- 	Name = "Crystal Caves",
	-- 	Description = "Glimmering caverns filled with precious gems",
	-- 	LevelCount = 5,
	-- 	UnlockRequirement = "World1_Complete",
	-- }
}

-- ============================================================================
-- NPC SETTINGS
-- ============================================================================

StoryConfig.NPCs = {
	Guide = {
		Name = "Elder Moss",
		Description = "A wise forest guardian",
		SpawnLocation = "Hub_Guide",
		InteractionRange = 10,
		RelationshipLevels = {
			[0] = "Stranger",
			[5] = "Acquaintance",
			[10] = "Friend",
			[20] = "Trusted Ally",
		}
	},

	Merchant = {
		Name = "Trader Tom",
		Description = "A wandering merchant",
		SpawnLocation = "Hub_Merchant",
		InteractionRange = 10,
		RelationshipLevels = {
			[0] = "Customer",
			[10] = "Regular",
			[20] = "VIP",
		}
	},

	Elder = {
		Name = "Ancient One",
		Description = "Keeper of ancient lore",
		SpawnLocation = "Hub_Elder",
		InteractionRange = 10,
		RelationshipLevels = {
			[0] = "Listener",
			[15] = "Student",
			[30] = "Scholar",
		}
	}
}

-- ============================================================================
-- QUEST SETTINGS
-- ============================================================================

StoryConfig.Quest = {
	-- Max active quests
	MaxActiveQuests = 5,

	-- Daily quest reset time (hours from midnight UTC)
	DailyResetHour = 0,

	-- Rewards multipliers
	RewardMultipliers = {
		Story = 1.0,
		Daily = 0.8,
		Bonus = 1.5,
	},

	-- Quest difficulty scaling
	DifficultyScaling = {
		Easy = 0.8,
		Normal = 1.0,
		Hard = 1.5,
		Expert = 2.0,
	}
}

-- ============================================================================
-- COLLECTIBLE SETTINGS
-- ============================================================================

StoryConfig.Collectibles = {
	-- Collectible types
	Types = {
		Fragment = {
			Name = "Ancient Fragment",
			Description = "A piece of the ancient curse",
			CoinReward = 50,
			ParticleColor = Color3.fromRGB(100, 200, 255),
		},
		Coin = {
			Name = "Coin",
			Description = "Standard currency",
			CoinReward = 10,
			ParticleColor = Color3.fromRGB(255, 215, 0),
		},
		Bonus = {
			Name = "Bonus Crystal",
			Description = "A rare bonus item",
			CoinReward = 100,
			ParticleColor = Color3.fromRGB(255, 100, 255),
		}
	},

	-- Collection settings
	RespawnTime = 0, -- 0 = never respawn (permanent collection)
	CollectionRange = 8,

	-- Anti-cheat
	MaxCollectionsPerSecond = 5, -- Prevent spam collection exploits
	MinTimeBetweenCollections = 0.1, -- seconds
}

-- ============================================================================
-- DIALOGUE SETTINGS
-- ============================================================================

StoryConfig.Dialogue = {
	-- Typewriter effect
	TypewriterSpeed = 0.03, -- seconds per character
	AllowSkip = true,

	-- UI settings
	MaxChoices = 4,
	DialogueTimeout = 300, -- seconds before auto-close

	-- Relationship changes
	RelationshipGain = {
		PositiveChoice = 2,
		NeutralChoice = 1,
		NegativeChoice = 0,
		QuestComplete = 5,
	}
}

-- ============================================================================
-- PROGRESSION SETTINGS
-- ============================================================================

StoryConfig.Progression = {
	-- Level completion rewards
	LevelRewards = {
		Coins = {
			[1] = 50,  -- Level 1
			[2] = 75,  -- Level 2
			[3] = 100, -- Level 3
			[4] = 125, -- Level 4
			[5] = 200, -- Level 5 (Boss)
		}
	},

	-- World completion rewards
	WorldRewards = {
		[1] = {
			Coins = 500,
			Title = "Forest Guardian",
		}
	},

	-- Unlock requirements
	LevelUnlockRequirements = {
		-- Level 1 always unlocked
		[2] = "World1_Level1",
		[3] = "World1_Level2",
		[4] = "World1_Level3",
		[5] = "World1_Level4",
	}
}

-- ============================================================================
-- WORLD STREAMING
-- ============================================================================

StoryConfig.Streaming = {
	-- Level streaming settings
	LoadDistance = 512,
	UnloadDistance = 768,

	-- Hub always loaded
	AlwaysLoadedAreas = {"Hub"},

	-- Preload next level
	PreloadNextLevel = true,
}

-- ============================================================================
-- MONETIZATION HOOKS
-- ============================================================================

StoryConfig.Monetization = {
	-- VIP benefits
	VIP = {
		CoinMultiplier = 2.0,
		SpeedBoost = 1.2,
		ExclusiveAreas = true,
	},

	-- Game passes
	GamePasses = {
		EarlyAccess = {
			Id = nil, -- Set in production
			Benefit = "Access to new worlds 1 week early",
		},
		CosmeticPack = {
			Id = nil,
			Benefit = "Exclusive trails and effects",
		}
	}
}

return StoryConfig
