--[[
	GameConfig.lua
	Central configuration for Dimension Hopper

	All game constants, dimension settings, and tuning values
	Shared between server and client
--]]

local GameConfig = {}

-- ============================================================================
-- DIMENSIONS
-- ============================================================================

GameConfig.Dimensions = {
	Gravity = {
		Id = 1,
		Name = "Gravity Dimension",
		DisplayName = "GRAVITY",
		Description = "Where up becomes down and walls become floors",
		Icon = "🌀",

		-- Visual Theme
		Theme = {
			PrimaryColor = Color3.fromRGB(138, 43, 226), -- Purple
			SecondaryColor = Color3.fromRGB(75, 0, 130), -- Indigo
			AccentColor = Color3.fromRGB(0, 255, 255), -- Cyan glow
			SkyboxId = "rbxassetid://0", -- Space skybox
			Ambient = Color3.fromRGB(40, 20, 60),
			FogColor = Color3.fromRGB(20, 10, 40),
			FogEnd = 500,
		},

		-- Gameplay Settings
		Settings = {
			SectionCount = 20,
			GravityStrength = 196.2, -- Standard Roblox gravity
			FlipTransitionTime = 0.3, -- Seconds to rotate player
			AllowMomentumPreservation = true,
		},

		-- Difficulty Scaling
		Difficulty = {
			Easy = { Sections = {1, 5}, FlipsPerSection = 1 },
			Medium = { Sections = {6, 12}, FlipsPerSection = 2 },
			Hard = { Sections = {13, 17}, FlipsPerSection = 3 },
			Expert = { Sections = {18, 20}, FlipsPerSection = 4 },
		},

		-- Mastery XP Requirements
		Mastery = {
			Bronze = 0,
			Silver = 500,
			Gold = 1500,
			Diamond = 4000,
			Master = 10000,
		},
	},

	Tiny = {
		Id = 2,
		Name = "Tiny Dimension",
		DisplayName = "TINY",
		Description = "Shrink down and explore a giant world",
		Icon = "🐜",

		Theme = {
			PrimaryColor = Color3.fromRGB(34, 139, 34), -- Forest Green
			SecondaryColor = Color3.fromRGB(139, 69, 19), -- Brown
			AccentColor = Color3.fromRGB(255, 215, 0), -- Gold sunlight
			SkyboxId = "rbxassetid://0", -- Sunny sky
			Ambient = Color3.fromRGB(100, 120, 80),
			FogColor = Color3.fromRGB(200, 220, 180),
			FogEnd = 1000,
		},

		Settings = {
			SectionCount = 20,
			ScaleLevels = {1, 0.5, 0.25, 0.1, 0.05}, -- Player scale per zone
			ScaleTransitionTime = 0.5,
			CameraDistanceMultiplier = 1.5, -- Zoom out when tiny
		},

		Difficulty = {
			Easy = { Sections = {1, 5}, Scale = 1 },
			Medium = { Sections = {6, 10}, Scale = 0.5 },
			Hard = { Sections = {11, 15}, Scale = 0.25 },
			Expert = { Sections = {16, 20}, Scale = 0.1 },
		},

		Mastery = {
			Bronze = 0,
			Silver = 500,
			Gold = 1500,
			Diamond = 4000,
			Master = 10000,
		},
	},

	Void = {
		Id = 3,
		Name = "Void Dimension",
		DisplayName = "VOID",
		Description = "Run or be consumed by the darkness",
		Icon = "👁️",

		Theme = {
			PrimaryColor = Color3.fromRGB(20, 0, 0), -- Near black
			SecondaryColor = Color3.fromRGB(139, 0, 0), -- Dark red
			AccentColor = Color3.fromRGB(255, 0, 0), -- Red glow
			SkyboxId = "rbxassetid://0", -- Dark void
			Ambient = Color3.fromRGB(10, 0, 0),
			FogColor = Color3.fromRGB(0, 0, 0),
			FogEnd = 150,
		},

		Settings = {
			SectionCount = 20,
			VoidBaseSpeed = 15, -- Studs per second
			VoidAcceleration = 0.5, -- Speed increase per section
			PlatformCrumbleDelay = 2.5, -- Seconds after touch
			PlatformCrumbleDuration = 0.5, -- Seconds to fully crumble
			SafeZoneDuration = 5, -- Seconds of safety at checkpoint
		},

		Difficulty = {
			Easy = { Sections = {1, 5}, VoidSpeed = 12, CrumbleDelay = 3 },
			Medium = { Sections = {6, 12}, VoidSpeed = 18, CrumbleDelay = 2.5 },
			Hard = { Sections = {13, 17}, VoidSpeed = 25, CrumbleDelay = 2 },
			Expert = { Sections = {18, 20}, VoidSpeed = 35, CrumbleDelay = 1.5 },
		},

		Mastery = {
			Bronze = 0,
			Silver = 500,
			Gold = 1500,
			Diamond = 4000,
			Master = 10000,
		},
	},

	Sky = {
		Id = 4,
		Name = "Sky Dimension",
		DisplayName = "SKY",
		Description = "Soar through floating islands in the clouds",
		Icon = "🦅",

		Theme = {
			PrimaryColor = Color3.fromRGB(135, 206, 235), -- Sky blue
			SecondaryColor = Color3.fromRGB(255, 255, 255), -- White clouds
			AccentColor = Color3.fromRGB(255, 215, 0), -- Golden sun
			SkyboxId = "rbxassetid://0", -- Beautiful sky
			Ambient = Color3.fromRGB(180, 200, 255),
			FogColor = Color3.fromRGB(200, 220, 255),
			FogEnd = 2000,
		},

		Settings = {
			SectionCount = 20,
			GliderSpeed = 50, -- Studs per second while gliding
			GliderFallSpeed = 20, -- Descent rate
			BoostMeterMax = 100,
			BoostRechargeRate = 10, -- Per second in updraft
			BoostDrainRate = 25, -- Per second while boosting
			WindCurrentStrength = 40, -- Force applied by wind
		},

		Difficulty = {
			Easy = { Sections = {1, 5}, GapDistance = 50, WindStrength = 20 },
			Medium = { Sections = {6, 12}, GapDistance = 80, WindStrength = 35 },
			Hard = { Sections = {13, 17}, GapDistance = 120, WindStrength = 50 },
			Expert = { Sections = {18, 20}, GapDistance = 180, WindStrength = 70 },
		},

		Mastery = {
			Bronze = 0,
			Silver = 500,
			Gold = 1500,
			Diamond = 4000,
			Master = 10000,
		},
	},
}

-- Dimension order for marathon mode
GameConfig.DimensionOrder = {"Gravity", "Tiny", "Void", "Sky"}

-- ============================================================================
-- RACE SETTINGS
-- ============================================================================

GameConfig.Race = {
	-- Lobby
	LobbyWaitTime = 30, -- Seconds to wait for players
	MinPlayers = 1, -- Minimum to start (1 for testing, 2+ for production)
	MaxPlayers = 16,

	-- Countdown
	CountdownTime = 5,

	-- Race
	MaxRaceTime = 480, -- 8 minutes max per dimension
	DNFTime = 600, -- Did Not Finish after 10 minutes

	-- Results
	ResultsDisplayTime = 15,

	-- Rewards
	PlacementXP = {
		[1] = 200, -- 1st place
		[2] = 150, -- 2nd place
		[3] = 100, -- 3rd place
	},
	CompletionXP = 50, -- Base XP for finishing
	PerSectionXP = 5, -- XP per section reached

	-- Matchmaking
	EnableELO = false, -- Future feature
	ELORange = 200, -- Match players within this ELO range
}

-- ============================================================================
-- GAME MODES
-- ============================================================================

GameConfig.GameModes = {
	DimensionRace = {
		Name = "Dimension Race",
		Description = "Race through a single dimension",
		MinPlayers = 1,
		MaxPlayers = 16,
		SingleDimension = true,
	},

	Marathon = {
		Name = "Dimension Marathon",
		Description = "Race through ALL four dimensions",
		MinPlayers = 1,
		MaxPlayers = 8,
		SingleDimension = false,
		XPMultiplier = 2.5,
	},

	Practice = {
		Name = "Practice Mode",
		Description = "No timer, no pressure - just practice",
		MinPlayers = 1,
		MaxPlayers = 1,
		SingleDimension = true,
		NoTimer = true,
		UnlimitedRespawns = true,
	},

	DailyChallenge = {
		Name = "Daily Challenge",
		Description = "Special modifiers, bonus rewards",
		MinPlayers = 1,
		MaxPlayers = 16,
		SingleDimension = true,
		BonusXPMultiplier = 1.5,
	},
}

-- ============================================================================
-- PROGRESSION
-- ============================================================================

GameConfig.Progression = {
	-- Level System
	MaxLevel = 100,
	BaseXPPerLevel = 100,
	XPScaling = 1.08, -- Each level needs 8% more XP

	-- XP Sources
	XPSources = {
		RaceCompletion = 50,
		RaceWin = 200,
		SecondPlace = 150,
		ThirdPlace = 100,
		SectionReached = 5,
		CollectibleFound = 25,
		DailyChallenge = 150,
		FirstWinOfDay = 200,
		MarathonCompletion = 500,
	},

	-- Level Rewards (every 5/10 levels)
	LevelRewards = {
		[5] = { Type = "Trail", Id = "Spark" },
		[10] = { Type = "Title", Id = "Dimension Jumper" },
		[15] = { Type = "Trail", Id = "Flame" },
		[20] = { Type = "Title", Id = "Reality Bender" },
		[25] = { Type = "Trail", Id = "Frost" },
		[30] = { Type = "Title", Id = "Void Walker" },
		[35] = { Type = "Trail", Id = "Electric" },
		[40] = { Type = "Title", Id = "Sky Dancer" },
		[45] = { Type = "Trail", Id = "Rainbow" },
		[50] = { Type = "Title", Id = "Dimension Walker" },
		[60] = { Type = "Trail", Id = "Galaxy" },
		[70] = { Type = "Title", Id = "Multiverse Traveler" },
		[80] = { Type = "Trail", Id = "Void" },
		[90] = { Type = "Title", Id = "Reality Weaver" },
		[100] = { Type = "Aura", Id = "Reality Breaker" },
	},
}

-- ============================================================================
-- COLLECTIBLES
-- ============================================================================

GameConfig.Collectibles = {
	-- Dimensional Fragments
	FragmentsPerDimension = 50,
	FragmentXP = 25,

	-- All fragments reward
	AllFragmentsReward = {
		Gravity = { Type = "Wing", Id = "Gravity Wings" },
		Tiny = { Type = "Pet", Id = "Mini Companion" },
		Void = { Type = "Aura", Id = "Void Aura" },
		Sky = { Type = "Wing", Id = "Angel Wings" },
	},
}

-- ============================================================================
-- MONETIZATION
-- ============================================================================

GameConfig.Monetization = {
	-- Dimension Pass (Season Pass)
	DimensionPass = {
		Enabled = true,
		ProductId = 0, -- Set after creating on Roblox
		Price = 99, -- Robux
		TotalTiers = 50,
		SeasonDurationDays = 30,
		BonusXPMultiplier = 1.25,
	},

	-- VIP Membership
	VIP = {
		Enabled = true,
		ProductId = 0,
		Price = 499,
		XPMultiplier = 2,
		QueuePriority = true,
		ExclusiveShop = true,
	},

	-- Game Passes
	GamePasses = {
		WingCollection = { Id = 0, Price = 149, Description = "10 exclusive wing styles" },
		TrailCollection = { Id = 0, Price = 99, Description = "15 trail effects" },
		EmotePack = { Id = 0, Price = 79, Description = "8 emotes" },
		DoubleXP = { Id = 0, Price = 199, Description = "Permanent 2x XP" },
	},

	-- Ads
	Ads = {
		Enabled = true,
		MaxAdsPerDay = 5,
		XPPerAd = 50,
		CooldownSeconds = 300, -- 5 minutes between ads
	},
}

-- ============================================================================
-- AUDIO
-- ============================================================================

GameConfig.Audio = {
	-- Music per dimension
	Music = {
		Lobby = "rbxassetid://0",
		Gravity = "rbxassetid://0", -- Electronic/space
		Tiny = "rbxassetid://0", -- Whimsical/nature
		Void = "rbxassetid://0", -- Dark ambient/horror
		Sky = "rbxassetid://0", -- Orchestral/uplifting
		Victory = "rbxassetid://0",
	},

	-- Sound Effects
	SFX = {
		Checkpoint = "rbxassetid://0",
		GravityFlip = "rbxassetid://0",
		Shrink = "rbxassetid://0",
		VoidNear = "rbxassetid://0",
		VoidCatch = "rbxassetid://0",
		GliderOpen = "rbxassetid://0",
		WindGust = "rbxassetid://0",
		Countdown = "rbxassetid://0",
		RaceStart = "rbxassetid://0",
		RaceFinish = "rbxassetid://0",
	},

	-- Volume defaults
	DefaultMusicVolume = 0.5,
	DefaultSFXVolume = 0.7,
}

-- ============================================================================
-- PLAYER SETTINGS
-- ============================================================================

GameConfig.Player = {
	-- Base stats
	BaseWalkSpeed = 16,
	BaseJumpPower = 50,

	-- Respawn
	RespawnTime = 1,
	SpawnInvulnerability = 2, -- Seconds of invulnerability after spawn

	-- Camera
	DefaultCameraMode = "Classic",
	CameraDistances = {
		Min = 5,
		Default = 15,
		Max = 30,
	},
}

-- ============================================================================
-- ANTI-CHEAT
-- ============================================================================

GameConfig.AntiCheat = {
	Enabled = true,

	-- Speed check
	MaxSpeedMultiplier = 1.5, -- Allow 50% above normal (for boosts)
	SpeedCheckInterval = 0.5,

	-- Teleport detection
	MaxTeleportDistance = 100, -- Studs

	-- Section skip
	MaxSectionSkip = 2,

	-- Actions
	ViolationAction = "Kick", -- "Kick", "Warn", "Log"
	MaxViolations = 3,
}

-- ============================================================================
-- DEBUG
-- ============================================================================

GameConfig.Debug = {
	Enabled = false,
	VerboseLogs = false,
	ShowHitboxes = false,
	GodMode = false,
	UnlimitedBoost = false,
	SkipLobby = false,
}

-- ============================================================================
-- VALIDATION
-- ============================================================================

function GameConfig.Validate()
	-- Basic validation
	assert(#GameConfig.DimensionOrder == 4, "Must have 4 dimensions")
	assert(GameConfig.Race.MinPlayers >= 1, "MinPlayers must be >= 1")
	assert(GameConfig.Progression.MaxLevel > 0, "MaxLevel must be > 0")

	print("[GameConfig] Configuration validated successfully")
end

GameConfig.Validate()

return GameConfig
