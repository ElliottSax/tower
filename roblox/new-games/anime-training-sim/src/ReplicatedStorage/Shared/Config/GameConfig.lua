--[[
	GameConfig.lua - Anime Training Simulator
	Master configuration - stats, zones, transformations, pets, clans, quests
]]

local GameConfig = {}

-- ============================================================================
-- TRAINING ZONES (unlock sequentially, each boosts training speed)
-- ============================================================================
GameConfig.TrainingZones = {
	{ Name = "Beginner Dojo", RequiredPower = 0, Multiplier = 1, UnlockCost = 0 },
	{ Name = "Forest Temple", RequiredPower = 500, Multiplier = 2, UnlockCost = 1000 },
	{ Name = "Mountain Peak", RequiredPower = 5000, Multiplier = 5, UnlockCost = 10000 },
	{ Name = "Volcanic Crater", RequiredPower = 50000, Multiplier = 12, UnlockCost = 100000 },
	{ Name = "Underwater Shrine", RequiredPower = 500000, Multiplier = 30, UnlockCost = 500000 },
	{ Name = "Sky Palace", RequiredPower = 5000000, Multiplier = 75, UnlockCost = 2500000 },
	{ Name = "Shadow Realm", RequiredPower = 50000000, Multiplier = 200, UnlockCost = 15000000 },
	{ Name = "Celestial Domain", RequiredPower = 500000000, Multiplier = 500, UnlockCost = 100000000 },
	{ Name = "Void Dimension", RequiredPower = 5000000000, Multiplier = 1500, UnlockCost = 750000000 },
	{ Name = "Creator's Realm", RequiredPower = 100000000000, Multiplier = 5000, UnlockCost = 5000000000 },
}

-- ============================================================================
-- TRAINING TYPES
-- ============================================================================
GameConfig.TrainingTypes = {
	{
		Name = "Strength",
		Description = "Raw physical power",
		BaseGain = 1,
		Color = Color3.fromRGB(244, 67, 54),
	},
	{
		Name = "Defense",
		Description = "Damage resistance",
		BaseGain = 0.8,
		Color = Color3.fromRGB(33, 150, 243),
	},
	{
		Name = "Speed",
		Description = "Movement and attack speed",
		BaseGain = 0.6,
		Color = Color3.fromRGB(76, 175, 80),
	},
	{
		Name = "Spirit",
		Description = "Special ability power",
		BaseGain = 0.5,
		Color = Color3.fromRGB(156, 39, 176),
	},
}

-- ============================================================================
-- TRANSFORMATIONS (tiered power boosts, unlocked by total power)
-- ============================================================================
GameConfig.Transformations = {
	{
		Name = "Base Form",
		RequiredPower = 0,
		Multiplier = 1,
		Color = Color3.fromRGB(255, 255, 255),
		Aura = false,
	},
	{
		Name = "Awakened",
		RequiredPower = 10000,
		Multiplier = 2,
		Color = Color3.fromRGB(255, 215, 0),
		Aura = true,
		AuraColor = Color3.fromRGB(255, 215, 0),
	},
	{
		Name = "Ultra Instinct",
		RequiredPower = 500000,
		Multiplier = 5,
		Color = Color3.fromRGB(200, 200, 255),
		Aura = true,
		AuraColor = Color3.fromRGB(150, 150, 255),
	},
	{
		Name = "Demon King",
		RequiredPower = 10000000,
		Multiplier = 15,
		Color = Color3.fromRGB(180, 0, 0),
		Aura = true,
		AuraColor = Color3.fromRGB(200, 0, 50),
	},
	{
		Name = "Sage Mode",
		RequiredPower = 250000000,
		Multiplier = 50,
		Color = Color3.fromRGB(255, 140, 0),
		Aura = true,
		AuraColor = Color3.fromRGB(255, 100, 0),
	},
	{
		Name = "Infinite Void",
		RequiredPower = 5000000000,
		Multiplier = 200,
		Color = Color3.fromRGB(100, 0, 200),
		Aura = true,
		AuraColor = Color3.fromRGB(80, 0, 180),
	},
	{
		Name = "Supreme Deity",
		RequiredPower = 100000000000,
		Multiplier = 1000,
		Color = Color3.fromRGB(255, 255, 255),
		Aura = true,
		AuraColor = Color3.fromRGB(255, 200, 255),
	},
}

-- ============================================================================
-- ABILITIES (unlockable combat moves)
-- ============================================================================
GameConfig.Abilities = {
	{ Name = "Power Punch", Type = "Melee", Damage = 10, Cooldown = 1, RequiredStrength = 100, Cost = 500 },
	{ Name = "Energy Blast", Type = "Ranged", Damage = 15, Cooldown = 2, RequiredSpirit = 200, Cost = 2000 },
	{ Name = "Shield Wall", Type = "Defense", Duration = 3, Cooldown = 8, RequiredDefense = 300, Cost = 3000 },
	{ Name = "Flash Step", Type = "Movement", Distance = 50, Cooldown = 3, RequiredSpeed = 250, Cost = 2500 },
	{ Name = "Dragon Fist", Type = "Melee", Damage = 50, Cooldown = 5, RequiredStrength = 5000, Cost = 25000 },
	{ Name = "Spirit Bomb", Type = "Ranged", Damage = 100, Cooldown = 10, RequiredSpirit = 10000, Cost = 100000 },
	{ Name = "Ultimate Defense", Type = "Defense", Duration = 5, Cooldown = 15, RequiredDefense = 15000, Cost = 150000 },
	{ Name = "Infinity Rush", Type = "Melee", Damage = 500, Cooldown = 8, RequiredStrength = 500000, Cost = 1000000 },
	{ Name = "Void Cannon", Type = "Ranged", Damage = 1000, Cooldown = 12, RequiredSpirit = 1000000, Cost = 5000000 },
	{ Name = "Celestial Barrage", Type = "Ultimate", Damage = 5000, Cooldown = 30, RequiredStrength = 10000000, Cost = 25000000 },
}

-- ============================================================================
-- PETS (gacha-style collection, boost training)
-- ============================================================================
GameConfig.Pets = {
	-- Common (60%)
	{ Name = "Spirit Fox", Rarity = "Common", Boost = 1.1, Egg = "Basic" },
	{ Name = "Training Dummy", Rarity = "Common", Boost = 1.1, Egg = "Basic" },
	{ Name = "Mini Dragon", Rarity = "Common", Boost = 1.15, Egg = "Basic" },
	{ Name = "Shadow Cat", Rarity = "Common", Boost = 1.15, Egg = "Basic" },
	-- Uncommon (25%)
	{ Name = "Thunder Wolf", Rarity = "Uncommon", Boost = 1.3, Egg = "Basic" },
	{ Name = "Flame Bird", Rarity = "Uncommon", Boost = 1.35, Egg = "Basic" },
	{ Name = "Ice Bear", Rarity = "Uncommon", Boost = 1.4, Egg = "Elemental" },
	-- Rare (10%)
	{ Name = "Golden Dragon", Rarity = "Rare", Boost = 1.75, Egg = "Elemental" },
	{ Name = "Dark Phoenix", Rarity = "Rare", Boost = 2.0, Egg = "Elemental" },
	{ Name = "Crystal Tiger", Rarity = "Rare", Boost = 2.0, Egg = "Mythic" },
	-- Epic (4%)
	{ Name = "Void Serpent", Rarity = "Epic", Boost = 3.0, Egg = "Mythic" },
	{ Name = "Celestial Eagle", Rarity = "Epic", Boost = 3.5, Egg = "Mythic" },
	-- Legendary (0.9%)
	{ Name = "Supreme Dragon", Rarity = "Legendary", Boost = 5.0, Egg = "Legendary" },
	{ Name = "Eternal Phoenix", Rarity = "Legendary", Boost = 6.0, Egg = "Legendary" },
	-- Mythical (0.1%)
	{ Name = "Infinity Beast", Rarity = "Mythical", Boost = 15.0, Egg = "Legendary" },
}

GameConfig.Eggs = {
	{ Name = "Basic", Cost = 500, Weights = { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 0.9, Mythical = 0.1 } },
	{ Name = "Elemental", Cost = 5000, Weights = { Common = 30, Uncommon = 35, Rare = 25, Epic = 8, Legendary = 1.8, Mythical = 0.2 } },
	{ Name = "Mythic", Cost = 50000, Weights = { Common = 10, Uncommon = 20, Rare = 35, Epic = 25, Legendary = 9, Mythical = 1 } },
	{ Name = "Legendary", Cost = 500000, Weights = { Common = 0, Uncommon = 5, Rare = 20, Epic = 40, Legendary = 30, Mythical = 5 } },
}

-- ============================================================================
-- QUESTS
-- ============================================================================
GameConfig.Quests = {
	{ Name = "First Steps", Description = "Train Strength 100 times", Type = "Train", Stat = "Strength", Target = 100, Reward = { Coins = 500 } },
	{ Name = "Getting Stronger", Description = "Reach 1,000 Total Power", Type = "Power", Target = 1000, Reward = { Coins = 2000 } },
	{ Name = "Pet Collector", Description = "Hatch 5 eggs", Type = "Hatch", Target = 5, Reward = { Coins = 3000 } },
	{ Name = "Zone Explorer", Description = "Unlock 3 training zones", Type = "Zones", Target = 3, Reward = { Coins = 10000 } },
	{ Name = "PvP Warrior", Description = "Win 10 PvP battles", Type = "PvPWins", Target = 10, Reward = { Coins = 15000 } },
	{ Name = "Transformation", Description = "Unlock your first transformation", Type = "Transform", Target = 1, Reward = { Coins = 5000 } },
	{ Name = "Ultimate Power", Description = "Reach 1 Billion Total Power", Type = "Power", Target = 1000000000, Reward = { Coins = 50000000 } },
}

-- ============================================================================
-- REBIRTH / PRESTIGE
-- ============================================================================
GameConfig.Rebirth = {
	BaseCost = 100000, -- First rebirth cost
	CostMultiplier = 2.5,
	BoostPerLevel = 0.5, -- +50% per rebirth
	MaxLevel = 50,
	Milestones = {
		{ Level = 5, Reward = "Exclusive Pet: Rebirth Dragon" },
		{ Level = 10, Reward = "2x Egg Luck" },
		{ Level = 20, Reward = "Auto-Train Unlock" },
		{ Level = 30, Reward = "Exclusive Aura: Rainbow" },
		{ Level = 50, Reward = "Title: Supreme Master" },
	},
}

-- ============================================================================
-- GAME PASSES (Robux)
-- ============================================================================
GameConfig.GamePasses = {
	VIP = { Id = 0, Name = "VIP", Price = 399, Description = "2x all training, VIP zone, gold name" },
	AutoTrain = { Id = 0, Name = "Auto Train", Price = 199, Description = "Automatically train while AFK" },
	DoublePets = { Id = 0, Name = "2x Pet Luck", Price = 249, Description = "Double chance for rare pets" },
	ExtraEquip = { Id = 0, Name = "+3 Pet Slots", Price = 149, Description = "Equip 3 extra pets at once" },
	InstantTeleport = { Id = 0, Name = "Instant Teleport", Price = 99, Description = "Teleport to any unlocked zone instantly" },
	DoubleCoins = { Id = 0, Name = "2x Coins", Price = 299, Description = "Double coin rewards from everything" },
}

GameConfig.DevProducts = {
	Coins1000 = { Id = 0, Name = "1,000 Coins", Price = 49, Amount = 1000 },
	Coins10000 = { Id = 0, Name = "10,000 Coins", Price = 99, Amount = 10000 },
	Coins100000 = { Id = 0, Name = "100,000 Coins", Price = 199, Amount = 100000 },
	Coins1000000 = { Id = 0, Name = "1,000,000 Coins", Price = 399, Amount = 1000000 },
	InstantRebirth = { Id = 0, Name = "Instant Rebirth", Price = 149, Description = "Rebirth without meeting coin requirement" },
	LuckPotion = { Id = 0, Name = "Luck Potion (30m)", Price = 79, Description = "2x pet luck for 30 minutes" },
	TrainingBoost = { Id = 0, Name = "5x Training (30m)", Price = 99, Description = "5x training gains for 30 minutes" },
}

-- ============================================================================
-- PVP CONFIG
-- ============================================================================
GameConfig.PvP = {
	ArenaCooldown = 30, -- seconds between matches
	MatchDuration = 60, -- seconds per match
	MinPowerToEnter = 1000,
	WinRewardCoins = 500,
	LoseRewardCoins = 50,
	RankedTiers = {
		{ Name = "Bronze", MinRating = 0, Color = Color3.fromRGB(205, 127, 50) },
		{ Name = "Silver", MinRating = 1000, Color = Color3.fromRGB(192, 192, 192) },
		{ Name = "Gold", MinRating = 1500, Color = Color3.fromRGB(255, 215, 0) },
		{ Name = "Diamond", MinRating = 2000, Color = Color3.fromRGB(100, 200, 255) },
		{ Name = "Champion", MinRating = 2500, Color = Color3.fromRGB(255, 50, 50) },
		{ Name = "Legend", MinRating = 3000, Color = Color3.fromRGB(255, 0, 255) },
	},
}

-- ============================================================================
-- CLANS
-- ============================================================================
GameConfig.Clans = {
	CreateCost = 50000,
	MaxMembers = 30,
	MaxNameLength = 20,
	Perks = {
		{ Level = 1, Perk = "Clan Chat" },
		{ Level = 3, Perk = "+5% Training Boost" },
		{ Level = 5, Perk = "Clan Banner" },
		{ Level = 10, Perk = "+10% Training Boost" },
		{ Level = 15, Perk = "Clan War Access" },
		{ Level = 20, Perk = "+20% Training Boost" },
	},
}

-- ============================================================================
-- DAILY REWARDS
-- ============================================================================
GameConfig.DailyRewards = {
	{ Day = 1, Reward = "Coins", Amount = 500 },
	{ Day = 2, Reward = "Coins", Amount = 1000 },
	{ Day = 3, Reward = "Egg", EggType = "Basic", Amount = 1 },
	{ Day = 4, Reward = "Coins", Amount = 2500 },
	{ Day = 5, Reward = "Egg", EggType = "Elemental", Amount = 1 },
	{ Day = 6, Reward = "Coins", Amount = 5000 },
	{ Day = 7, Reward = "Egg", EggType = "Mythic", Amount = 1 },
}

-- ============================================================================
-- DEFAULT PLAYER DATA
-- ============================================================================
GameConfig.DefaultData = {
	Coins = 0,
	TotalCoinsEarned = 0,

	-- Stats
	Strength = 0,
	Defense = 0,
	Speed = 0,
	Spirit = 0,

	-- Training
	TotalTrains = 0,
	CurrentZone = "Beginner Dojo",
	UnlockedZones = { "Beginner Dojo" },

	-- Transformation
	CurrentTransformation = "Base Form",

	-- Pets
	Pets = {},
	EquippedPets = {},
	MaxEquipped = 3,
	TotalEggsHatched = 0,

	-- Abilities
	UnlockedAbilities = {},
	EquippedAbilities = {},

	-- PvP
	PvPRating = 1000,
	PvPWins = 0,
	PvPLosses = 0,

	-- Quests
	QuestProgress = {},
	CompletedQuests = {},

	-- Rebirth
	RebirthLevel = 0,

	-- Clan
	ClanId = nil,

	-- Login
	LastLoginDate = "",
	LoginStreak = 0,

	-- Game Passes
	GamePasses = {},

	-- Temporary boosts
	_LuckExpiry = 0,
	_TrainingBoostExpiry = 0,
}

return GameConfig
