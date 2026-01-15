--[[
	GameConfig.lua
	Central configuration for Tower Ascent

	All game constants, settings, and tuning values
	Shared between server and client
--]]

local GameConfig = {}

-- ============================================================================
-- TOWER GENERATION
-- ============================================================================

GameConfig.Tower = {
	-- Sections per tower
	SectionsPerTower = 50,

	-- Section length (studs)
	SectionLength = 60,

	-- Starting height
	StartHeight = 20,

	-- Max active stages (for memory management)
	-- Stages beyond this distance are despawned
	MaxActiveStages = 15,

	-- Section despawn distance (studs)
	-- If player is more than this far from a section, despawn it
	DespawnDistance = 500,

	-- Difficulty mode multipliers
	DifficultyModes = {
		Easy = {
			TimeMultiplier = 1.5,      -- 50% more time
			CoinMultiplier = 0.8,      -- 20% fewer coins
			Name = "Easy Mode",
			Color = Color3.fromRGB(100, 255, 100),
		},
		Normal = {
			TimeMultiplier = 1.0,      -- Standard time
			CoinMultiplier = 1.0,      -- Standard coins
			Name = "Normal Mode",
			Color = Color3.fromRGB(100, 200, 255),
		},
		Hard = {
			TimeMultiplier = 0.75,     -- 25% less time
			CoinMultiplier = 1.5,      -- 50% more coins
			Name = "Hard Mode",
			Color = Color3.fromRGB(255, 200, 100),
		},
		Nightmare = {
			TimeMultiplier = 0.5,      -- 50% less time
			CoinMultiplier = 2.0,      -- 100% more coins (double)
			Name = "Nightmare Mode",
			Color = Color3.fromRGB(255, 100, 100),
		},
	},
}

-- ============================================================================
-- ROUND SYSTEM
-- ============================================================================

GameConfig.Round = {
	-- Round duration (seconds)
	RoundTime = 480, -- 8 minutes

	-- Intermission duration (seconds)
	IntermissionTime = 20,

	-- Minimum players to start
	MinPlayers = 1, -- Can play solo (set to 2+ for multiplayer only)

	-- Countdown before round starts
	StartCountdown = 5,

	-- Auto-start enabled
	AutoStart = true,

	-- Placement bonus coins (1st, 2nd, 3rd place)
	PlacementBonuses = {
		[1] = 500, -- First place
		[2] = 300, -- Second place
		[3] = 200, -- Third place
	},
}

-- ============================================================================
-- PLAYER PROGRESSION
-- ============================================================================

GameConfig.Progression = {
	-- Base coins awarded per section reached
	CoinsPerSection = 10,

	-- Bonus coins for completing tower
	CompletionBonus = 500,

	-- Coin multiplier for finishing in top 25% of time
	SpeedBonusMultiplier = 1.5,

	-- Starting coins for new players
	StartingCoins = 0,

	-- Max coins a player can hold
	MaxCoins = 999999,
}

-- ============================================================================
-- UPGRADES
-- ============================================================================

GameConfig.Upgrades = {
	DoubleJump = {
		Name = "Double Jump",
		Description = "Jump again in mid-air",
		Cost = 100,
		Icon = "rbxassetid://0", -- TODO: Replace with real asset
		MaxLevel = 1,
		JumpPowerBoost = 50,
	},

	SpeedBoost = {
		Name = "Speed Boost",
		Description = "Run faster (+2 speed per level)",
		Cost = 150,
		Icon = "rbxassetid://0",
		MaxLevel = 5,
		SpeedPerLevel = 2,
	},

	AirDash = {
		Name = "Air Dash",
		Description = "Dash forward while airborne",
		Cost = 250,
		Icon = "rbxassetid://0",
		MaxLevel = 1,
		DashPower = 80,
		Cooldown = 3, -- seconds
	},

	WallGrip = {
		Name = "Wall Grip",
		Description = "Slide slower on walls",
		Cost = 200,
		Icon = "rbxassetid://0",
		MaxLevel = 3,
		SlideReductionPerLevel = 0.3,
	},
}

-- ============================================================================
-- ANTI-CHEAT
-- ============================================================================

GameConfig.AntiCheat = {
	-- Enable anti-cheat system
	Enabled = true,

	-- Maximum speed (studs/second) before flagged
	MaxSpeed = 100,

	-- Maximum altitude change per second (flying detection)
	MaxVerticalSpeed = 200,

	-- Teleport detection threshold (studs)
	-- If player moves this far in one frame, flag as teleport
	TeleportThreshold = 100,

	-- Stage skip detection
	-- If player skips more than this many stages, flag
	MaxStageSkip = 2,

	-- Check interval (seconds)
	CheckInterval = 0.5,

	-- Action on cheat detected
	-- "Kick", "Warn", "Log"
	Action = "Kick",

	-- Log all violations (even if not kicking)
	LogViolations = true,
}

-- ============================================================================
-- MEMORY MANAGEMENT
-- ============================================================================

GameConfig.Memory = {
	-- Enable memory management
	Enabled = true,

	-- Cleanup interval (seconds)
	CleanupInterval = 5,

	-- Max parts before forced cleanup
	MaxParts = 5000,

	-- Max memory usage (MB) before warning
	MaxMemoryMB = 500,

	-- Log memory stats
	LogStats = true,
}

-- ============================================================================
-- STREAMING
-- ============================================================================

GameConfig.Streaming = {
	-- StreamingEnabled set in default.project.json
	Enabled = true,

	-- Minimum streaming radius (studs)
	MinRadius = 128,

	-- Target streaming radius (studs)
	TargetRadius = 512,

	-- Stream out delay (seconds)
	-- How long before content streams out after leaving radius
	StreamOutDelay = 5,
}

-- ============================================================================
-- MOBILE OPTIMIZATION
-- ============================================================================

GameConfig.Mobile = {
	-- Enable mobile optimizations
	Enabled = true,

	-- Reduce quality on mobile
	ReduceQuality = true,

	-- Target FPS on mobile
	TargetFPS = 60,

	-- Devices to optimize for
	OptimizeDevices = {
		"iPhone 11",
		"iPhone 12",
		"iPad Air",
		"Samsung Galaxy S10",
	},

	-- Graphics quality levels
	QualityLevels = {
		High = 21,    -- Desktop
		Medium = 14,  -- Tablet
		Low = 7,      -- Phone
	},
}

-- ============================================================================
-- ANALYTICS
-- ============================================================================

GameConfig.Analytics = {
	-- Enable analytics
	Enabled = true,

	-- Batch events (don't send immediately)
	BatchEvents = true,

	-- Batch size (number of events before flush)
	BatchSize = 50,

	-- Max batch age (seconds before forced flush)
	MaxBatchAge = 30,

	-- Track these events
	TrackedEvents = {
		"PlayerJoin",
		"PlayerLeave",
		"RoundStart",
		"RoundEnd",
		"SectionReached",
		"TowerCompleted",
		"PlayerDeath",
		"UpgradePurchased",
		"CoinEarned",
	},
}

-- ============================================================================
-- MONETIZATION (Week 12+)
-- ============================================================================

GameConfig.Monetization = {
	-- Battle Pass
	BattlePass = {
		Enabled = false, -- Enable in Week 12
		CostRobux = 499,
		TotalTiers = 50,
		FreeRewards = true,
	},

	-- VIP
	VIP = {
		Enabled = false,
		ProductId = 0, -- Set when created
		CostRobux = 999,
		Benefits = {
			DoubleCoins = true,
			DoubleXP = true,
			ExclusiveCosmetics = true,
		},
	},

	-- Game Passes
	GamePasses = {
		-- Will be populated in Week 12
	},
}

-- ============================================================================
-- DEBUG
-- ============================================================================

GameConfig.Debug = {
	-- Enable debug mode
	Enabled = false, -- ✅ PRODUCTION: Debug mode disabled

	-- Print verbose logs
	VerboseLogs = false, -- ✅ PRODUCTION: Verbose logging disabled

	-- Show performance stats
	ShowStats = false, -- ✅ PRODUCTION: Performance stats hidden

	-- Run automated tests on server start
	RunTests = false, -- Tests disabled for production

	-- God mode (for testing)
	GodMode = false,

	-- Infinite coins (for testing)
	InfiniteCoins = false,

	-- Skip round timer (for testing)
	SkipTimer = false,
}

-- ============================================================================
-- VALIDATION
-- ============================================================================

-- Validate configuration on load
function GameConfig.Validate()
	assert(GameConfig.Tower.SectionsPerTower > 0, "SectionsPerTower must be > 0")
	assert(GameConfig.Round.RoundTime > 0, "RoundTime must be > 0")
	assert(GameConfig.Round.MinPlayers >= 1, "MinPlayers must be >= 1")

	print("[GameConfig] Configuration validated successfully")
end

-- Auto-validate
GameConfig.Validate()

return GameConfig
