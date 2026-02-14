--[[
	GameConfig.lua
	Pet Collector Simulator - Game Configuration

	Monetization-focused configuration for maximum revenue potential
]]

local GameConfig = {}

-- ============================================================================
-- GAME PASSES (Premium Features)
-- ============================================================================

GameConfig.GamePasses = {
	VIP = {
		Id = 0, -- Replace with your game pass ID
		Price = 350, -- Robux
		Benefits = {
			"2x Coin Multiplier",
			"Exclusive VIP pets",
			"VIP-only worlds",
			"No hatch cooldown",
			"Priority trading",
		}
	},

	LuckyBoost = {
		Id = 0,
		Price = 250,
		Benefits = {
			"3x chance for Legendary pets",
			"2x chance for Mythic pets",
			"Guaranteed rare or better",
		}
	},

	AutoHatch = {
		Id = 0,
		Price = 400,
		Benefits = {
			"Auto-hatch eggs every 5 seconds",
			"Hatch up to 3 eggs at once",
			"No clicking required",
		}
	},

	SpeedBoost = {
		Id = 0,
		Price = 150,
		Benefits = {
			"2x walk speed",
			"Faster pet collection",
			"Jump boost",
		}
	},

	ExtraSlots = {
		Id = 0,
		Price = 300,
		Benefits = {
			"+10 pet inventory slots",
			"Equip 3 pets at once (instead of 1)",
		}
	},
}

-- ============================================================================
-- DEVELOPER PRODUCTS (Consumables)
-- ============================================================================

GameConfig.DeveloperProducts = {
	-- Coins
	Coins_1000 = {
		Id = 0,
		Price = 50,
		Amount = 1000,
	},
	Coins_5000 = {
		Id = 0,
		Price = 200,
		Amount = 5000,
	},
	Coins_25000 = {
		Id = 0,
		Price = 800,
		Amount = 25000,
	},
	Coins_100000 = {
		Id = 0,
		Price = 2500,
		Amount = 100000,
	},

	-- Eggs
	BasicEgg_10Pack = {
		Id = 0,
		Price = 100,
		EggType = "Basic",
		Amount = 10,
	},
	RareEgg_5Pack = {
		Id = 0,
		Price = 250,
		EggType = "Rare",
		Amount = 5,
	},
	LegendaryEgg_Single = {
		Id = 0,
		Price = 400,
		EggType = "Legendary",
		Amount = 1,
	},

	-- Boosts (Temporary)
	LuckBoost_1Hour = {
		Id = 0,
		Price = 100,
		Duration = 3600, -- seconds
		Multiplier = 2,
	},
	CoinBoost_1Hour = {
		Id = 0,
		Price = 150,
		Duration = 3600,
		Multiplier = 3,
	},
}

-- ============================================================================
-- WORLDS (Progression System)
-- ============================================================================

GameConfig.Worlds = {
	{
		Id = 1,
		Name = "Starter Island",
		UnlockCost = 0,
		Description = "Your journey begins here!",
		CoinMultiplier = 1,
		EggTypes = {"Basic"},
		RequiredPets = 0,
	},
	{
		Id = 2,
		Name = "Mystic Forest",
		UnlockCost = 5000,
		Description = "Discover rare forest creatures",
		CoinMultiplier = 1.5,
		EggTypes = {"Basic", "Forest"},
		RequiredPets = 5,
	},
	{
		Id = 3,
		Name = "Crystal Caves",
		UnlockCost = 25000,
		Description = "Glowing crystals hold powerful pets",
		CoinMultiplier = 2,
		EggTypes = {"Forest", "Crystal"},
		RequiredPets = 15,
	},
	{
		Id = 4,
		Name = "Volcano Peak",
		UnlockCost = 100000,
		Description = "Legendary fire pets await",
		CoinMultiplier = 3,
		EggTypes = {"Crystal", "Fire"},
		RequiredPets = 30,
	},
	{
		Id = 5,
		Name = "VIP Paradise",
		UnlockCost = 0,
		Description = "Exclusive VIP-only world",
		CoinMultiplier = 5,
		EggTypes = {"VIP", "Exclusive"},
		RequiredPets = 0,
		RequiresVIP = true,
	},
}

-- ============================================================================
-- EGGS (Loot Boxes)
-- ============================================================================

GameConfig.Eggs = {
	Basic = {
		Name = "Basic Egg",
		Cost = 100,
		HatchTime = 3, -- seconds
		Icon = "rbxassetid://0",
		PetPool = "Basic",
	},
	Forest = {
		Name = "Forest Egg",
		Cost = 500,
		HatchTime = 5,
		Icon = "rbxassetid://0",
		PetPool = "Forest",
	},
	Crystal = {
		Name = "Crystal Egg",
		Cost = 2500,
		HatchTime = 8,
		Icon = "rbxassetid://0",
		PetPool = "Crystal",
	},
	Fire = {
		Name = "Fire Egg",
		Cost = 10000,
		HatchTime = 10,
		Icon = "rbxassetid://0",
		PetPool = "Fire",
	},
	VIP = {
		Name = "VIP Egg",
		Cost = 5000,
		HatchTime = 2,
		Icon = "rbxassetid://0",
		PetPool = "VIP",
		RequiresVIP = true,
	},
	Legendary = {
		Name = "Legendary Egg",
		Cost = 50000,
		HatchTime = 15,
		Icon = "rbxassetid://0",
		PetPool = "Legendary",
	},
}

-- ============================================================================
-- RARITY SYSTEM
-- ============================================================================

GameConfig.Rarities = {
	Common = {
		Weight = 60, -- 60% chance
		Color = Color3.fromRGB(200, 200, 200),
		Multiplier = 1,
		Sparkles = false,
	},
	Uncommon = {
		Weight = 25, -- 25% chance
		Color = Color3.fromRGB(100, 255, 100),
		Multiplier = 1.5,
		Sparkles = false,
	},
	Rare = {
		Weight = 10, -- 10% chance
		Color = Color3.fromRGB(100, 100, 255),
		Multiplier = 2,
		Sparkles = true,
	},
	Epic = {
		Weight = 4, -- 4% chance
		Color = Color3.fromRGB(200, 100, 255),
		Multiplier = 3,
		Sparkles = true,
	},
	Legendary = {
		Weight = 0.9, -- 0.9% chance
		Color = Color3.fromRGB(255, 200, 0),
		Multiplier = 5,
		Sparkles = true,
	},
	Mythic = {
		Weight = 0.1, -- 0.1% chance (1 in 1000)
		Color = Color3.fromRGB(255, 50, 50),
		Multiplier = 10,
		Sparkles = true,
	},
}

-- ============================================================================
-- COIN COLLECTION
-- ============================================================================

GameConfig.CoinDrops = {
	SpawnInterval = 5, -- seconds between spawns
	MaxCoins = 50, -- max coins in world
	BaseValue = 10, -- base coin value
	DespawnTime = 30, -- seconds until coin despawns
	ClickRadius = 10, -- studs
}

-- ============================================================================
-- TRADING SYSTEM
-- ============================================================================

GameConfig.Trading = {
	Enabled = true,
	MaxPetsPerTrade = 6,
	MaxCoinsPerTrade = 1000000,
	TradeCooldown = 30, -- seconds between trades
	MinLevel = 5, -- minimum level to trade (anti-scam)
	VIPPriority = true, -- VIP trades process first
}

-- ============================================================================
-- DAILY REWARDS
-- ============================================================================

GameConfig.DailyRewards = {
	Day1 = {Coins = 100, Eggs = {Basic = 1}},
	Day2 = {Coins = 250, Eggs = {Basic = 2}},
	Day3 = {Coins = 500, Eggs = {Basic = 3, Forest = 1}},
	Day4 = {Coins = 1000, Eggs = {Forest = 2}},
	Day5 = {Coins = 2500, Eggs = {Crystal = 1}},
	Day6 = {Coins = 5000, Eggs = {Crystal = 2}},
	Day7 = {Coins = 10000, Eggs = {Legendary = 1}}, -- Big reward on day 7
}

-- ============================================================================
-- QUESTS (Engagement)
-- ============================================================================

GameConfig.Quests = {
	Daily = {
		{Name = "Hatch 5 Eggs", Reward = 500, Type = "Hatch", Target = 5},
		{Name = "Collect 100 Coins", Reward = 300, Type = "Collect", Target = 100},
		{Name = "Equip 3 Pets", Reward = 200, Type = "Equip", Target = 3},
		{Name = "Visit 2 Worlds", Reward = 400, Type = "Visit", Target = 2},
	},
	Weekly = {
		{Name = "Hatch 50 Eggs", Reward = 5000, Type = "Hatch", Target = 50},
		{Name = "Unlock New World", Reward = 10000, Type = "Unlock", Target = 1},
		{Name = "Get Legendary Pet", Reward = 15000, Type = "GetRarity", Target = "Legendary"},
	},
}

-- ============================================================================
-- SETTINGS
-- ============================================================================

GameConfig.Settings = {
	MaxInventorySlots = 50, -- 100 with game pass
	MaxEquippedPets = 1, -- 3 with game pass
	AutosaveInterval = 60, -- seconds
	DefaultWalkSpeed = 16,
	VIPWalkSpeed = 24,
	CoinMagnetRadius = 20, -- studs (auto-collect)
}

return GameConfig
