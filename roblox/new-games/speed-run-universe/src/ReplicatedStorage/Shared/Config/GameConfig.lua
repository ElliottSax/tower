--[[
	GameConfig.lua - Speed Run Universe
	Master configuration: worlds, stages, abilities, trails, challenges, passes, monetization
]]

local GameConfig = {}

-- ============================================================================
-- WORLDS (10 themed worlds, each with 10 stages)
-- ============================================================================
GameConfig.Worlds = {
	{
		Id = "Grass",
		Name = "Grasslands",
		Theme = "green",
		UnlockCost = 0,
		StageCount = 10,
		Description = "Rolling hills and gentle platforms. Perfect for beginners.",
		ParTimeSeconds = 120,
		CoinReward = 50,
		CompletionReward = 100,
		BackgroundColor = Color3.fromRGB(120, 200, 80),
		Difficulty = 1,
	},
	{
		Id = "Lava",
		Name = "Lava Caverns",
		Theme = "red",
		UnlockCost = 500,
		StageCount = 10,
		Description = "Molten rock and erupting geysers. Watch your step!",
		ParTimeSeconds = 150,
		CoinReward = 100,
		CompletionReward = 250,
		BackgroundColor = Color3.fromRGB(200, 50, 20),
		Difficulty = 2,
	},
	{
		Id = "Ice",
		Name = "Frozen Peaks",
		Theme = "cyan",
		UnlockCost = 1500,
		StageCount = 10,
		Description = "Slippery ice platforms and freezing winds.",
		ParTimeSeconds = 180,
		CoinReward = 150,
		CompletionReward = 400,
		BackgroundColor = Color3.fromRGB(150, 220, 255),
		Difficulty = 3,
	},
	{
		Id = "Space",
		Name = "Outer Space",
		Theme = "dark_blue",
		UnlockCost = 3500,
		StageCount = 10,
		Description = "Low gravity asteroids and floating platforms.",
		ParTimeSeconds = 200,
		CoinReward = 200,
		CompletionReward = 600,
		BackgroundColor = Color3.fromRGB(10, 10, 50),
		Difficulty = 4,
	},
	{
		Id = "Underwater",
		Name = "Deep Ocean",
		Theme = "blue",
		UnlockCost = 7000,
		StageCount = 10,
		Description = "Coral reefs and underwater currents. Swim or sink!",
		ParTimeSeconds = 220,
		CoinReward = 300,
		CompletionReward = 800,
		BackgroundColor = Color3.fromRGB(20, 80, 160),
		Difficulty = 5,
	},
	{
		Id = "Neon",
		Name = "Neon City",
		Theme = "pink",
		UnlockCost = 15000,
		StageCount = 10,
		Description = "Glowing platforms and laser obstacles in a cyberpunk cityscape.",
		ParTimeSeconds = 240,
		CoinReward = 400,
		CompletionReward = 1200,
		BackgroundColor = Color3.fromRGB(200, 50, 200),
		Difficulty = 6,
	},
	{
		Id = "Candy",
		Name = "Candy Kingdom",
		Theme = "magenta",
		UnlockCost = 30000,
		StageCount = 10,
		Description = "Bouncy gummy platforms, chocolate rivers, and candy cane rails.",
		ParTimeSeconds = 260,
		CoinReward = 500,
		CompletionReward = 1800,
		BackgroundColor = Color3.fromRGB(255, 150, 200),
		Difficulty = 7,
	},
	{
		Id = "Haunted",
		Name = "Haunted Manor",
		Theme = "purple",
		UnlockCost = 60000,
		StageCount = 10,
		Description = "Disappearing floors, ghost chasers, and creaky platforms.",
		ParTimeSeconds = 280,
		CoinReward = 700,
		CompletionReward = 2500,
		BackgroundColor = Color3.fromRGB(60, 20, 80),
		Difficulty = 8,
	},
	{
		Id = "Clockwork",
		Name = "Clockwork Factory",
		Theme = "bronze",
		UnlockCost = 120000,
		StageCount = 10,
		Description = "Spinning gears, conveyor belts, and precision timing puzzles.",
		ParTimeSeconds = 300,
		CoinReward = 1000,
		CompletionReward = 4000,
		BackgroundColor = Color3.fromRGB(180, 140, 60),
		Difficulty = 9,
	},
	{
		Id = "Void",
		Name = "The Void",
		Theme = "black",
		UnlockCost = 250000,
		StageCount = 10,
		Description = "The ultimate challenge. Platforms appear and vanish. No room for error.",
		ParTimeSeconds = 360,
		CoinReward = 2000,
		CompletionReward = 10000,
		BackgroundColor = Color3.fromRGB(5, 5, 15),
		Difficulty = 10,
	},
}

-- Build a lookup by world Id
GameConfig.WorldById = {}
for i, world in ipairs(GameConfig.Worlds) do
	world.Index = i
	GameConfig.WorldById[world.Id] = world
end

-- ============================================================================
-- STAGES (per-stage config template; actual geometry is in workspace)
-- ============================================================================
-- Each stage has: coins to collect, hazards, par time modifier
GameConfig.StageTemplate = {
	-- Stage number within a world (1-10)
	CoinsPerStage = { 5, 6, 7, 8, 9, 10, 12, 14, 16, 20 },
	ParTimeMultiplier = { 0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2, 1.4 },
	DifficultyScale = { 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.7, 1.9, 2.1, 2.5 },
}

-- ============================================================================
-- ABILITIES (movement abilities unlocked through progression)
-- ============================================================================
GameConfig.Abilities = {
	{
		Id = "DoubleJump",
		Name = "Double Jump",
		Description = "Jump again while airborne.",
		Icon = "rbxassetid://0",
		UnlockWorld = "Grass",
		UnlockStage = 5,
		Cooldown = 0,
		Duration = 0,
		JumpPower = 50,
		MaxCharges = 1,
		KeyBind = Enum.KeyCode.Space,
	},
	{
		Id = "Dash",
		Name = "Dash",
		Description = "Burst forward in a short dash. Press Q to activate.",
		Icon = "rbxassetid://0",
		UnlockWorld = "Lava",
		UnlockStage = 3,
		Cooldown = 3,
		Duration = 0.25,
		DashForce = 80,
		KeyBind = Enum.KeyCode.Q,
	},
	{
		Id = "WallRun",
		Name = "Wall Run",
		Description = "Run along walls for a short time. Sprint into a wall to activate.",
		Icon = "rbxassetid://0",
		UnlockWorld = "Ice",
		UnlockStage = 5,
		Cooldown = 1,
		Duration = 2,
		WallRunSpeed = 30,
		KeyBind = Enum.KeyCode.E,
	},
	{
		Id = "Grapple",
		Name = "Grapple Hook",
		Description = "Launch a grapple to swing across gaps. Press R to fire.",
		Icon = "rbxassetid://0",
		UnlockWorld = "Space",
		UnlockStage = 5,
		Cooldown = 5,
		Duration = 3,
		GrappleRange = 100,
		GrappleSpeed = 60,
		KeyBind = Enum.KeyCode.R,
	},
	{
		Id = "Glide",
		Name = "Glider",
		Description = "Deploy a glider to float gently downward. Hold F while airborne.",
		Icon = "rbxassetid://0",
		UnlockWorld = "Underwater",
		UnlockStage = 8,
		Cooldown = 0,
		Duration = 10,
		GlideGravity = 10,
		GlideSpeed = 40,
		KeyBind = Enum.KeyCode.F,
	},
	{
		Id = "Teleport",
		Name = "Teleport",
		Description = "Blink forward a short distance. Press T to teleport.",
		Icon = "rbxassetid://0",
		UnlockWorld = "Haunted",
		UnlockStage = 10,
		Cooldown = 8,
		Duration = 0,
		TeleportDistance = 40,
		KeyBind = Enum.KeyCode.T,
	},
}

-- Build ability lookup
GameConfig.AbilityById = {}
for _, ability in ipairs(GameConfig.Abilities) do
	GameConfig.AbilityById[ability.Id] = ability
end

-- ============================================================================
-- COSMETIC TRAILS
-- ============================================================================
GameConfig.Trails = {
	{ Id = "Fire", Name = "Fire Trail", Color1 = Color3.fromRGB(255, 100, 0), Color2 = Color3.fromRGB(255, 200, 0), Cost = 500, Lifetime = 0.8, Texture = "", Category = "Elemental" },
	{ Id = "Rainbow", Name = "Rainbow Trail", Color1 = Color3.fromRGB(255, 0, 0), Color2 = Color3.fromRGB(0, 0, 255), Cost = 1000, Lifetime = 1.0, Texture = "", Category = "Elemental" },
	{ Id = "Shadow", Name = "Shadow Trail", Color1 = Color3.fromRGB(30, 0, 50), Color2 = Color3.fromRGB(80, 0, 120), Cost = 1500, Lifetime = 0.6, Texture = "", Category = "Dark" },
	{ Id = "Star", Name = "Starlight Trail", Color1 = Color3.fromRGB(255, 255, 150), Color2 = Color3.fromRGB(255, 255, 255), Cost = 2000, Lifetime = 0.9, Texture = "", Category = "Cosmic" },
	{ Id = "Lightning", Name = "Lightning Trail", Color1 = Color3.fromRGB(100, 150, 255), Color2 = Color3.fromRGB(200, 230, 255), Cost = 2500, Lifetime = 0.5, Texture = "", Category = "Elemental" },
	{ Id = "Ice", Name = "Ice Crystal Trail", Color1 = Color3.fromRGB(150, 220, 255), Color2 = Color3.fromRGB(255, 255, 255), Cost = 1800, Lifetime = 0.7, Texture = "", Category = "Elemental" },
	{ Id = "Neon", Name = "Neon Glow Trail", Color1 = Color3.fromRGB(0, 255, 200), Color2 = Color3.fromRGB(200, 0, 255), Cost = 3000, Lifetime = 1.2, Texture = "", Category = "Tech" },
	{ Id = "Galaxy", Name = "Galaxy Trail", Color1 = Color3.fromRGB(50, 0, 100), Color2 = Color3.fromRGB(100, 50, 200), Cost = 5000, Lifetime = 1.5, Texture = "", Category = "Cosmic" },
	{ Id = "Gold", Name = "Golden Trail", Color1 = Color3.fromRGB(255, 200, 0), Color2 = Color3.fromRGB(255, 150, 0), Cost = 8000, Lifetime = 0.8, Texture = "", Category = "Premium" },
	{ Id = "Void", Name = "Void Trail", Color1 = Color3.fromRGB(0, 0, 0), Color2 = Color3.fromRGB(50, 0, 80), Cost = 15000, Lifetime = 0.6, Texture = "", Category = "Dark" },
	{ Id = "Cherry", Name = "Cherry Blossom Trail", Color1 = Color3.fromRGB(255, 180, 200), Color2 = Color3.fromRGB(255, 220, 230), Cost = 3500, Lifetime = 1.0, Texture = "", Category = "Nature" },
	{ Id = "Lava", Name = "Magma Trail", Color1 = Color3.fromRGB(200, 30, 0), Color2 = Color3.fromRGB(255, 150, 0), Cost = 4000, Lifetime = 0.9, Texture = "", Category = "Elemental" },
}

-- Build trail lookup
GameConfig.TrailById = {}
for _, trail in ipairs(GameConfig.Trails) do
	GameConfig.TrailById[trail.Id] = trail
end

-- ============================================================================
-- WIN EFFECTS (particle effects on stage completion)
-- ============================================================================
GameConfig.WinEffects = {
	{ Id = "Confetti", Name = "Confetti Burst", Cost = 300, Description = "Shower of colorful confetti" },
	{ Id = "Fireworks", Name = "Fireworks", Cost = 800, Description = "Brilliant firework explosion" },
	{ Id = "Lightning", Name = "Lightning Strike", Cost = 1200, Description = "A dramatic lightning bolt" },
	{ Id = "Shockwave", Name = "Shockwave", Cost = 2000, Description = "Expanding energy ring" },
	{ Id = "StarBurst", Name = "Star Burst", Cost = 3000, Description = "Exploding stars radiate outward" },
	{ Id = "VoidCollapse", Name = "Void Collapse", Cost = 10000, Description = "Reality warps around you" },
}

GameConfig.WinEffectById = {}
for _, effect in ipairs(GameConfig.WinEffects) do
	GameConfig.WinEffectById[effect.Id] = effect
end

-- ============================================================================
-- DAILY CHALLENGES
-- ============================================================================
GameConfig.DailyChallengeTemplates = {
	{
		Type = "CompleteWorldUnderTime",
		Description = "Complete %s under %d seconds",
		CoinReward = 500,
		Worlds = { "Grass", "Lava", "Ice" },
		TimeLimits = { 90, 120, 150 },
	},
	{
		Type = "CollectCoinsInWorld",
		Description = "Collect %d coins in %s",
		CoinReward = 300,
		AmountRange = { 50, 150 },
	},
	{
		Type = "CompleteStagesNoDeaths",
		Description = "Complete %d stages without dying",
		CoinReward = 400,
		AmountRange = { 3, 10 },
	},
	{
		Type = "UseAbilityCount",
		Description = "Use %s ability %d times",
		CoinReward = 250,
		AmountRange = { 10, 50 },
	},
	{
		Type = "BeatPersonalBest",
		Description = "Beat your personal best in any stage",
		CoinReward = 600,
	},
	{
		Type = "CompleteStagesTotal",
		Description = "Complete %d total stages",
		CoinReward = 350,
		AmountRange = { 10, 30 },
	},
}

-- Weekly challenge templates (bigger rewards)
GameConfig.WeeklyChallengeTemplates = {
	{
		Type = "CompleteAllStagesInWorld",
		Description = "Complete every stage in %s",
		CoinReward = 3000,
	},
	{
		Type = "TotalSpeedrunTime",
		Description = "Achieve a combined speedrun time under %d seconds across all Grasslands stages",
		CoinReward = 5000,
		TimeTarget = 600,
	},
	{
		Type = "CollectTotalCoins",
		Description = "Collect %d total coins this week",
		CoinReward = 4000,
		AmountRange = { 500, 2000 },
	},
}

-- ============================================================================
-- GHOST REPLAY SETTINGS
-- ============================================================================
GameConfig.GhostSettings = {
	RecordInterval = 0.1, -- Record position every 100ms
	MaxRecordDuration = 600, -- Max 10 minutes per ghost
	MaxGhostsPerPlayer = 20, -- Store up to 20 ghost recordings
	GhostTransparency = 0.6,
	GhostColor = Color3.fromRGB(100, 200, 255),
	FriendGhostColor = Color3.fromRGB(255, 200, 100),
}

-- ============================================================================
-- TOURNAMENT / COMPETITIVE SETTINGS
-- ============================================================================
GameConfig.Tournaments = {
	WeeklyEnabled = true,
	Duration = 604800, -- 7 days in seconds
	MinPlayers = 10,
	Prizes = {
		{ Place = 1, Coins = 50000, Title = "Speed Champion" },
		{ Place = 2, Coins = 25000, Title = "Speed Runner-Up" },
		{ Place = 3, Coins = 10000, Title = "Speed Contender" },
		{ Place = 4, Coins = 5000, Title = "" },
		{ Place = 5, Coins = 3000, Title = "" },
		{ Place = 6, Coins = 2000, Title = "" },
		{ Place = 7, Coins = 1500, Title = "" },
		{ Place = 8, Coins = 1000, Title = "" },
		{ Place = 9, Coins = 750, Title = "" },
		{ Place = 10, Coins = 500, Title = "" },
	},
	-- Which world the tournament is held in (rotates weekly)
	RotationWorlds = { "Grass", "Lava", "Ice", "Space", "Underwater", "Neon", "Candy", "Haunted", "Clockwork", "Void" },
}

-- ============================================================================
-- GAME PASSES (Monetization)
-- ============================================================================
GameConfig.GamePasses = {
	SkipWorld = {
		Id = 0, -- Set to actual Roblox GamePass ID in production
		Name = "World Skip Pass",
		Price = 299,
		Description = "Instantly unlock any one world of your choice.",
	},
	DoubleCoins = {
		Id = 0,
		Name = "2x Coins",
		Price = 399,
		Description = "Earn double coins from all sources permanently.",
	},
	ExclusiveTrails = {
		Id = 0,
		Name = "Exclusive Trail Pack",
		Price = 499,
		Description = "Unlock 3 exclusive premium trails: Plasma, Aurora, and Cosmic Dust.",
		UnlockedTrails = { "Plasma", "Aurora", "CosmicDust" },
	},
	SpeedBoost = {
		Id = 0,
		Name = "Speed Boost Pass",
		Price = 199,
		Description = "Permanent +10% movement speed in all worlds.",
		SpeedMultiplier = 1.1,
	},
	VIP = {
		Id = 0,
		Name = "VIP",
		Price = 599,
		Description = "VIP badge, gold name color, VIP-only trails, 2x coins, +15% speed.",
		SpeedMultiplier = 1.15,
		CoinMultiplier = 2,
	},
}

-- Exclusive trails from GamePass (not in main shop)
GameConfig.ExclusiveTrails = {
	{ Id = "Plasma", Name = "Plasma Trail", Color1 = Color3.fromRGB(0, 255, 150), Color2 = Color3.fromRGB(0, 100, 255), Lifetime = 0.7, Category = "Exclusive" },
	{ Id = "Aurora", Name = "Aurora Trail", Color1 = Color3.fromRGB(0, 200, 100), Color2 = Color3.fromRGB(100, 0, 200), Lifetime = 1.3, Category = "Exclusive" },
	{ Id = "CosmicDust", Name = "Cosmic Dust Trail", Color1 = Color3.fromRGB(200, 150, 255), Color2 = Color3.fromRGB(255, 200, 100), Lifetime = 1.1, Category = "Exclusive" },
}

GameConfig.DevProducts = {
	Coins1000 = { Id = 0, Name = "1,000 Coins", Price = 49, Amount = 1000 },
	Coins5000 = { Id = 0, Name = "5,000 Coins", Price = 99, Amount = 5000 },
	Coins25000 = { Id = 0, Name = "25,000 Coins", Price = 199, Amount = 25000 },
	Coins100000 = { Id = 0, Name = "100,000 Coins", Price = 499, Amount = 100000 },
	SkipWorldUnlock = { Id = 0, Name = "Skip World Unlock", Price = 149, Description = "Instantly unlock the next locked world" },
	ReviveBoost = { Id = 0, Name = "Instant Revive + Speed Boost", Price = 29, Description = "Revive instantly with 5 seconds of speed boost", BoostDuration = 5, SpeedMultiplier = 1.3 },
}

-- ============================================================================
-- DAILY REWARDS (login streak)
-- ============================================================================
GameConfig.DailyRewards = {
	{ Day = 1, Reward = "Coins", Amount = 100 },
	{ Day = 2, Reward = "Coins", Amount = 200 },
	{ Day = 3, Reward = "Trail", TrailId = "Fire", Amount = 1 },
	{ Day = 4, Reward = "Coins", Amount = 500 },
	{ Day = 5, Reward = "Coins", Amount = 800 },
	{ Day = 6, Reward = "WinEffect", EffectId = "Confetti", Amount = 1 },
	{ Day = 7, Reward = "Coins", Amount = 2000 },
}

-- ============================================================================
-- SPEED BOOST ZONES / MODIFIERS
-- ============================================================================
GameConfig.SpeedModifiers = {
	Default = 16, -- Default walk speed
	SprintMultiplier = 1.5,
	IceSlipFactor = 0.3, -- Reduced friction on ice
	UnderwaterFactor = 0.7, -- Slower underwater
	SpaceGravity = 50, -- Reduced gravity in space (default 196.2)
	LavaSpeedBoost = 1.2, -- Lava world has speed boost pads
}

-- ============================================================================
-- LEADERBOARD SETTINGS
-- ============================================================================
GameConfig.Leaderboards = {
	MaxEntries = 100,
	UpdateInterval = 30, -- Seconds between leaderboard refreshes
	Categories = {
		"WorldBestTime", -- Best total time for a world
		"StageBestTime", -- Best time for a single stage
		"TotalCoins", -- Most coins collected all-time
		"StagesCompleted", -- Total stages completed
		"TournamentWins", -- Tournament victories
	},
}

-- ============================================================================
-- DEFAULT PLAYER DATA
-- ============================================================================
GameConfig.DefaultData = {
	-- Currency
	Coins = 0,
	TotalCoinsEarned = 0,

	-- Progression
	UnlockedWorlds = { "Grass" },
	CompletedStages = {}, -- { ["Grass_1"] = true, ["Grass_2"] = true, ... }
	CurrentWorld = "Grass",
	CurrentStage = 1,
	FurthestWorld = "Grass",
	FurthestStage = 1,

	-- Speedrun Times
	PersonalBests = {}, -- { ["Grass_1"] = 12.5, ["Grass_World"] = 95.3, ... }
	TotalStagesCompleted = 0,

	-- Abilities
	UnlockedAbilities = {}, -- { "DoubleJump", "Dash", ... }
	EquippedAbilities = {}, -- Active ability loadout (max 3)

	-- Cosmetics
	OwnedTrails = {},
	OwnedWinEffects = {},
	EquippedTrail = "",
	EquippedWinEffect = "",

	-- Ghost data keys (actual data stored in separate datastore)
	GhostKeys = {}, -- { ["Grass_1"] = "ghost_key_123", ... }

	-- Challenges
	DailyChallenges = {},
	WeeklyChallenges = {},
	LastDailyChallengeDate = "",
	LastWeeklyChallengeDate = "",

	-- Tournament
	TournamentBestTime = 0,
	TournamentWins = 0,

	-- Statistics
	TotalDeaths = 0,
	TotalPlayTime = 0,
	TotalCoinsCollected = 0,

	-- Daily reward
	LastLoginDate = "",
	LoginStreak = 0,

	-- Monetization
	GamePasses = {},

	-- Settings
	ShowGhosts = true,
	ShowTrails = true,
	MusicVolume = 0.5,
	SFXVolume = 0.8,
}

return GameConfig
