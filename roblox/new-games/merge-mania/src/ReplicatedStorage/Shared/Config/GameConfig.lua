--[[
	GameConfig.lua - Merge Mania
	Complete merge/idle game configuration

	Core Loop: Generators spawn items -> Merge same-tier items -> Earn passive coins
	           -> Buy better generators -> Prestige for permanent multipliers

	4 Merge Paths: Weapons, Pets, Food, Gems (each with 20 tiers)
]]

local GameConfig = {}

-- ============================================================================
-- GRID SETTINGS
-- ============================================================================
GameConfig.Grid = {
	DefaultRows = 6,
	DefaultCols = 6,
	ExpandedRows = 8, -- With grid expansion pass
	ExpandedCols = 8,
	MaxItems = 36, -- Default 6x6
	ExpandedMaxItems = 64, -- Expanded 8x8
}

-- ============================================================================
-- MERGE PATHS (4 unique paths, each with 20 tiers)
-- ============================================================================
GameConfig.MergePaths = {
	Weapons = {
		Order = 1,
		UnlockCost = 0,
		Color = Color3.fromRGB(220, 50, 50),
		Icon = "rbxassetid://0",
		BonusType = "CriticalMerge", -- Chance to skip a tier on merge
		BonusAmount = 0.05, -- 5% chance per collection completion
		Tiers = {
			{ Name = "Wooden Stick",     Tier = 1,  CoinPerSec = 1,        MergeValue = 5,        Color = Color3.fromRGB(139, 90, 43) },
			{ Name = "Stone Knife",      Tier = 2,  CoinPerSec = 3,        MergeValue = 15,       Color = Color3.fromRGB(150, 150, 150) },
			{ Name = "Copper Dagger",    Tier = 3,  CoinPerSec = 8,        MergeValue = 40,       Color = Color3.fromRGB(184, 115, 51) },
			{ Name = "Iron Sword",       Tier = 4,  CoinPerSec = 20,       MergeValue = 100,      Color = Color3.fromRGB(180, 180, 190) },
			{ Name = "Steel Blade",      Tier = 5,  CoinPerSec = 50,       MergeValue = 250,      Color = Color3.fromRGB(200, 200, 210) },
			{ Name = "Silver Rapier",    Tier = 6,  CoinPerSec = 120,      MergeValue = 600,      Color = Color3.fromRGB(192, 192, 192) },
			{ Name = "Gold Scimitar",    Tier = 7,  CoinPerSec = 300,      MergeValue = 1500,     Color = Color3.fromRGB(255, 215, 0) },
			{ Name = "Platinum Axe",     Tier = 8,  CoinPerSec = 750,      MergeValue = 3750,     Color = Color3.fromRGB(229, 228, 226) },
			{ Name = "Mithril Lance",    Tier = 9,  CoinPerSec = 1800,     MergeValue = 9000,     Color = Color3.fromRGB(100, 149, 237) },
			{ Name = "Adamant Halberd",  Tier = 10, CoinPerSec = 4500,     MergeValue = 22500,    Color = Color3.fromRGB(0, 128, 0) },
			{ Name = "Dragon Katana",    Tier = 11, CoinPerSec = 11000,    MergeValue = 55000,    Color = Color3.fromRGB(255, 69, 0) },
			{ Name = "Phoenix Blade",    Tier = 12, CoinPerSec = 28000,    MergeValue = 140000,   Color = Color3.fromRGB(255, 140, 0) },
			{ Name = "Thunder Hammer",   Tier = 13, CoinPerSec = 70000,    MergeValue = 350000,   Color = Color3.fromRGB(70, 130, 180) },
			{ Name = "Frost Greatsword", Tier = 14, CoinPerSec = 175000,   MergeValue = 875000,   Color = Color3.fromRGB(135, 206, 250) },
			{ Name = "Shadow Scythe",    Tier = 15, CoinPerSec = 440000,   MergeValue = 2200000,  Color = Color3.fromRGB(48, 25, 52) },
			{ Name = "Celestial Staff",  Tier = 16, CoinPerSec = 1100000,  MergeValue = 5500000,  Color = Color3.fromRGB(255, 223, 186) },
			{ Name = "Void Cleaver",     Tier = 17, CoinPerSec = 2750000,  MergeValue = 13750000, Color = Color3.fromRGB(75, 0, 130) },
			{ Name = "Cosmic Trident",   Tier = 18, CoinPerSec = 7000000,  MergeValue = 35000000, Color = Color3.fromRGB(138, 43, 226) },
			{ Name = "Eternal Excalibur",Tier = 19, CoinPerSec = 17500000, MergeValue = 87500000, Color = Color3.fromRGB(255, 215, 0) },
			{ Name = "Universe Blade",   Tier = 20, CoinPerSec = 50000000, MergeValue = 250000000,Color = Color3.fromRGB(255, 255, 255) },
		},
	},

	Pets = {
		Order = 2,
		UnlockCost = 5000,
		Color = Color3.fromRGB(50, 180, 50),
		Icon = "rbxassetid://0",
		BonusType = "PassiveBoost", -- Percentage boost to all passive earnings
		BonusAmount = 0.10, -- 10% per collection completion
		Tiers = {
			{ Name = "Ant",              Tier = 1,  CoinPerSec = 1,        MergeValue = 5,        Color = Color3.fromRGB(101, 67, 33) },
			{ Name = "Snail",            Tier = 2,  CoinPerSec = 3,        MergeValue = 15,       Color = Color3.fromRGB(150, 130, 100) },
			{ Name = "Frog",             Tier = 3,  CoinPerSec = 8,        MergeValue = 40,       Color = Color3.fromRGB(34, 139, 34) },
			{ Name = "Rabbit",           Tier = 4,  CoinPerSec = 20,       MergeValue = 100,      Color = Color3.fromRGB(200, 200, 200) },
			{ Name = "Cat",              Tier = 5,  CoinPerSec = 50,       MergeValue = 250,      Color = Color3.fromRGB(255, 165, 0) },
			{ Name = "Dog",              Tier = 6,  CoinPerSec = 120,      MergeValue = 600,      Color = Color3.fromRGB(139, 90, 43) },
			{ Name = "Wolf",             Tier = 7,  CoinPerSec = 300,      MergeValue = 1500,     Color = Color3.fromRGB(105, 105, 105) },
			{ Name = "Eagle",            Tier = 8,  CoinPerSec = 750,      MergeValue = 3750,     Color = Color3.fromRGB(139, 69, 19) },
			{ Name = "Horse",            Tier = 9,  CoinPerSec = 1800,     MergeValue = 9000,     Color = Color3.fromRGB(160, 82, 45) },
			{ Name = "Bear",             Tier = 10, CoinPerSec = 4500,     MergeValue = 22500,    Color = Color3.fromRGB(101, 67, 33) },
			{ Name = "Tiger",            Tier = 11, CoinPerSec = 11000,    MergeValue = 55000,    Color = Color3.fromRGB(255, 140, 0) },
			{ Name = "Elephant",         Tier = 12, CoinPerSec = 28000,    MergeValue = 140000,   Color = Color3.fromRGB(128, 128, 128) },
			{ Name = "Griffin",          Tier = 13, CoinPerSec = 70000,    MergeValue = 350000,   Color = Color3.fromRGB(218, 165, 32) },
			{ Name = "Unicorn",          Tier = 14, CoinPerSec = 175000,   MergeValue = 875000,   Color = Color3.fromRGB(255, 182, 193) },
			{ Name = "Phoenix",          Tier = 15, CoinPerSec = 440000,   MergeValue = 2200000,  Color = Color3.fromRGB(255, 69, 0) },
			{ Name = "Dragon",           Tier = 16, CoinPerSec = 1100000,  MergeValue = 5500000,  Color = Color3.fromRGB(178, 34, 34) },
			{ Name = "Hydra",            Tier = 17, CoinPerSec = 2750000,  MergeValue = 13750000, Color = Color3.fromRGB(0, 100, 0) },
			{ Name = "Leviathan",        Tier = 18, CoinPerSec = 7000000,  MergeValue = 35000000, Color = Color3.fromRGB(0, 105, 148) },
			{ Name = "Celestial Beast",  Tier = 19, CoinPerSec = 17500000, MergeValue = 87500000, Color = Color3.fromRGB(255, 223, 186) },
			{ Name = "Universe Dragon",  Tier = 20, CoinPerSec = 50000000, MergeValue = 250000000,Color = Color3.fromRGB(255, 255, 255) },
		},
	},

	Food = {
		Order = 3,
		UnlockCost = 50000,
		Color = Color3.fromRGB(255, 165, 0),
		Icon = "rbxassetid://0",
		BonusType = "GeneratorSpeed", -- Faster generator spawn rate
		BonusAmount = 0.08, -- 8% faster per collection completion
		Tiers = {
			{ Name = "Crumb",            Tier = 1,  CoinPerSec = 1,        MergeValue = 5,        Color = Color3.fromRGB(210, 180, 140) },
			{ Name = "Bread Slice",      Tier = 2,  CoinPerSec = 3,        MergeValue = 15,       Color = Color3.fromRGB(222, 184, 135) },
			{ Name = "Apple",            Tier = 3,  CoinPerSec = 8,        MergeValue = 40,       Color = Color3.fromRGB(255, 0, 0) },
			{ Name = "Sandwich",         Tier = 4,  CoinPerSec = 20,       MergeValue = 100,      Color = Color3.fromRGB(194, 178, 128) },
			{ Name = "Pizza Slice",      Tier = 5,  CoinPerSec = 50,       MergeValue = 250,      Color = Color3.fromRGB(255, 200, 50) },
			{ Name = "Burger",           Tier = 6,  CoinPerSec = 120,      MergeValue = 600,      Color = Color3.fromRGB(139, 90, 43) },
			{ Name = "Steak",            Tier = 7,  CoinPerSec = 300,      MergeValue = 1500,     Color = Color3.fromRGB(128, 0, 0) },
			{ Name = "Sushi Platter",    Tier = 8,  CoinPerSec = 750,      MergeValue = 3750,     Color = Color3.fromRGB(255, 127, 80) },
			{ Name = "Lobster",          Tier = 9,  CoinPerSec = 1800,     MergeValue = 9000,     Color = Color3.fromRGB(220, 20, 60) },
			{ Name = "Truffle Feast",    Tier = 10, CoinPerSec = 4500,     MergeValue = 22500,    Color = Color3.fromRGB(75, 0, 130) },
			{ Name = "Golden Cake",      Tier = 11, CoinPerSec = 11000,    MergeValue = 55000,    Color = Color3.fromRGB(255, 215, 0) },
			{ Name = "Diamond Pie",      Tier = 12, CoinPerSec = 28000,    MergeValue = 140000,   Color = Color3.fromRGB(185, 242, 255) },
			{ Name = "Enchanted Soup",   Tier = 13, CoinPerSec = 70000,    MergeValue = 350000,   Color = Color3.fromRGB(147, 112, 219) },
			{ Name = "Phoenix Roast",    Tier = 14, CoinPerSec = 175000,   MergeValue = 875000,   Color = Color3.fromRGB(255, 69, 0) },
			{ Name = "Dragon Fruit",     Tier = 15, CoinPerSec = 440000,   MergeValue = 2200000,  Color = Color3.fromRGB(255, 20, 147) },
			{ Name = "Stellar Chocolate",Tier = 16, CoinPerSec = 1100000,  MergeValue = 5500000,  Color = Color3.fromRGB(101, 67, 33) },
			{ Name = "Nebula Nectar",    Tier = 17, CoinPerSec = 2750000,  MergeValue = 13750000, Color = Color3.fromRGB(138, 43, 226) },
			{ Name = "Cosmic Ambrosia",  Tier = 18, CoinPerSec = 7000000,  MergeValue = 35000000, Color = Color3.fromRGB(0, 0, 139) },
			{ Name = "Eternal Feast",    Tier = 19, CoinPerSec = 17500000, MergeValue = 87500000, Color = Color3.fromRGB(255, 223, 186) },
			{ Name = "Universe Banquet", Tier = 20, CoinPerSec = 50000000, MergeValue = 250000000,Color = Color3.fromRGB(255, 255, 255) },
		},
	},

	Gems = {
		Order = 4,
		UnlockCost = 500000,
		Color = Color3.fromRGB(100, 100, 255),
		Icon = "rbxassetid://0",
		BonusType = "LuckyMerge", -- Increased golden merge chance
		BonusAmount = 0.02, -- +2% golden chance per collection completion
		Tiers = {
			{ Name = "Pebble",           Tier = 1,  CoinPerSec = 1,        MergeValue = 5,        Color = Color3.fromRGB(150, 150, 150) },
			{ Name = "Quartz",           Tier = 2,  CoinPerSec = 3,        MergeValue = 15,       Color = Color3.fromRGB(200, 200, 200) },
			{ Name = "Agate",            Tier = 3,  CoinPerSec = 8,        MergeValue = 40,       Color = Color3.fromRGB(205, 92, 92) },
			{ Name = "Jade",             Tier = 4,  CoinPerSec = 20,       MergeValue = 100,      Color = Color3.fromRGB(0, 168, 107) },
			{ Name = "Topaz",            Tier = 5,  CoinPerSec = 50,       MergeValue = 250,      Color = Color3.fromRGB(255, 191, 0) },
			{ Name = "Garnet",           Tier = 6,  CoinPerSec = 120,      MergeValue = 600,      Color = Color3.fromRGB(178, 34, 34) },
			{ Name = "Amethyst",         Tier = 7,  CoinPerSec = 300,      MergeValue = 1500,     Color = Color3.fromRGB(153, 102, 204) },
			{ Name = "Sapphire",         Tier = 8,  CoinPerSec = 750,      MergeValue = 3750,     Color = Color3.fromRGB(15, 82, 186) },
			{ Name = "Emerald",          Tier = 9,  CoinPerSec = 1800,     MergeValue = 9000,     Color = Color3.fromRGB(80, 200, 120) },
			{ Name = "Ruby",             Tier = 10, CoinPerSec = 4500,     MergeValue = 22500,    Color = Color3.fromRGB(224, 17, 95) },
			{ Name = "Diamond",          Tier = 11, CoinPerSec = 11000,    MergeValue = 55000,    Color = Color3.fromRGB(185, 242, 255) },
			{ Name = "Black Opal",       Tier = 12, CoinPerSec = 28000,    MergeValue = 140000,   Color = Color3.fromRGB(20, 20, 20) },
			{ Name = "Star Sapphire",    Tier = 13, CoinPerSec = 70000,    MergeValue = 350000,   Color = Color3.fromRGB(100, 149, 237) },
			{ Name = "Blood Ruby",       Tier = 14, CoinPerSec = 175000,   MergeValue = 875000,   Color = Color3.fromRGB(139, 0, 0) },
			{ Name = "Void Crystal",     Tier = 15, CoinPerSec = 440000,   MergeValue = 2200000,  Color = Color3.fromRGB(48, 25, 52) },
			{ Name = "Celestial Gem",    Tier = 16, CoinPerSec = 1100000,  MergeValue = 5500000,  Color = Color3.fromRGB(255, 223, 186) },
			{ Name = "Nebula Stone",     Tier = 17, CoinPerSec = 2750000,  MergeValue = 13750000, Color = Color3.fromRGB(138, 43, 226) },
			{ Name = "Galaxy Core",      Tier = 18, CoinPerSec = 7000000,  MergeValue = 35000000, Color = Color3.fromRGB(25, 25, 112) },
			{ Name = "Eternal Crystal",  Tier = 19, CoinPerSec = 17500000, MergeValue = 87500000, Color = Color3.fromRGB(255, 215, 0) },
			{ Name = "Universe Gem",     Tier = 20, CoinPerSec = 50000000, MergeValue = 250000000,Color = Color3.fromRGB(255, 255, 255) },
		},
	},
}

-- ============================================================================
-- GENERATORS (Auto-spawn tier 1 items on the grid)
-- ============================================================================
GameConfig.Generators = {
	-- Basic generators (always available)
	{
		Name = "Rusty Spawner",
		Path = "Weapons",
		SpawnTier = 1,
		IntervalSec = 10,
		Cost = 100,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(139, 90, 43),
	},
	{
		Name = "Pet Egg Dropper",
		Path = "Pets",
		SpawnTier = 1,
		IntervalSec = 10,
		Cost = 100,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(144, 238, 144),
	},
	{
		Name = "Bread Oven",
		Path = "Food",
		SpawnTier = 1,
		IntervalSec = 10,
		Cost = 100,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(222, 184, 135),
	},
	{
		Name = "Rock Tumbler",
		Path = "Gems",
		SpawnTier = 1,
		IntervalSec = 10,
		Cost = 100,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(180, 180, 180),
	},

	-- Upgraded generators (faster, cost more)
	{
		Name = "Iron Forge",
		Path = "Weapons",
		SpawnTier = 1,
		IntervalSec = 6,
		Cost = 2500,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(180, 180, 190),
	},
	{
		Name = "Pet Nursery",
		Path = "Pets",
		SpawnTier = 1,
		IntervalSec = 6,
		Cost = 2500,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(50, 180, 50),
	},
	{
		Name = "Kitchen Pro",
		Path = "Food",
		SpawnTier = 1,
		IntervalSec = 6,
		Cost = 2500,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(255, 165, 0),
	},
	{
		Name = "Gem Mine",
		Path = "Gems",
		SpawnTier = 1,
		IntervalSec = 6,
		Cost = 2500,
		UnlockPrestige = 0,
		Color = Color3.fromRGB(100, 149, 237),
	},

	-- Tier 2 generators (spawn tier 2 items directly)
	{
		Name = "Steel Forge",
		Path = "Weapons",
		SpawnTier = 2,
		IntervalSec = 12,
		Cost = 15000,
		UnlockPrestige = 1,
		Color = Color3.fromRGB(200, 200, 210),
	},
	{
		Name = "Exotic Breeder",
		Path = "Pets",
		SpawnTier = 2,
		IntervalSec = 12,
		Cost = 15000,
		UnlockPrestige = 1,
		Color = Color3.fromRGB(34, 139, 34),
	},
	{
		Name = "Gourmet Kitchen",
		Path = "Food",
		SpawnTier = 2,
		IntervalSec = 12,
		Cost = 15000,
		UnlockPrestige = 1,
		Color = Color3.fromRGB(255, 200, 50),
	},
	{
		Name = "Deep Mine",
		Path = "Gems",
		SpawnTier = 2,
		IntervalSec = 12,
		Cost = 15000,
		UnlockPrestige = 1,
		Color = Color3.fromRGB(15, 82, 186),
	},

	-- Tier 3 generators (prestige 3+)
	{
		Name = "Mythril Foundry",
		Path = "Weapons",
		SpawnTier = 3,
		IntervalSec = 15,
		Cost = 100000,
		UnlockPrestige = 3,
		Color = Color3.fromRGB(100, 149, 237),
	},
	{
		Name = "Mythic Hatchery",
		Path = "Pets",
		SpawnTier = 3,
		IntervalSec = 15,
		Cost = 100000,
		UnlockPrestige = 3,
		Color = Color3.fromRGB(255, 182, 193),
	},
	{
		Name = "Enchanted Bakery",
		Path = "Food",
		SpawnTier = 3,
		IntervalSec = 15,
		Cost = 100000,
		UnlockPrestige = 3,
		Color = Color3.fromRGB(147, 112, 219),
	},
	{
		Name = "Crystal Cavern",
		Path = "Gems",
		SpawnTier = 3,
		IntervalSec = 15,
		Cost = 100000,
		UnlockPrestige = 3,
		Color = Color3.fromRGB(80, 200, 120),
	},

	-- Premium generators (prestige 5+, spawn tier 4)
	{
		Name = "Dragon Forge",
		Path = "Weapons",
		SpawnTier = 4,
		IntervalSec = 18,
		Cost = 1000000,
		UnlockPrestige = 5,
		Color = Color3.fromRGB(255, 69, 0),
	},
	{
		Name = "Celestial Sanctum",
		Path = "Pets",
		SpawnTier = 4,
		IntervalSec = 18,
		Cost = 1000000,
		UnlockPrestige = 5,
		Color = Color3.fromRGB(255, 223, 186),
	},
	{
		Name = "Cosmic Kitchen",
		Path = "Food",
		SpawnTier = 4,
		IntervalSec = 18,
		Cost = 1000000,
		UnlockPrestige = 5,
		Color = Color3.fromRGB(138, 43, 226),
	},
	{
		Name = "Universe Excavator",
		Path = "Gems",
		SpawnTier = 4,
		IntervalSec = 18,
		Cost = 1000000,
		UnlockPrestige = 5,
		Color = Color3.fromRGB(255, 215, 0),
	},
}

-- ============================================================================
-- LUCKY MERGE (Golden items)
-- ============================================================================
GameConfig.LuckyMerge = {
	BaseChance = 0.05, -- 5% base chance
	GoldenMultiplier = 5, -- Golden items worth 5x
	GoldenCoinPerSecMultiplier = 5,
	MaxChance = 0.50, -- Cap at 50% with all bonuses
}

-- ============================================================================
-- COLLECTIONS (Complete sets for permanent boosts)
-- ============================================================================
GameConfig.Collections = {
	-- Collecting all 20 tiers in a path grants a huge bonus
	WeaponMaster = {
		Path = "Weapons",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
		Reward = "2x Weapon Earnings",
		Multiplier = 2.0,
		Description = "Merge all 20 weapon tiers to unlock 2x weapon earnings forever",
	},
	PetCollector = {
		Path = "Pets",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
		Reward = "2x Pet Earnings",
		Multiplier = 2.0,
		Description = "Merge all 20 pet tiers to unlock 2x pet earnings forever",
	},
	FoodGourmet = {
		Path = "Food",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
		Reward = "2x Food Earnings",
		Multiplier = 2.0,
		Description = "Merge all 20 food tiers to unlock 2x food earnings forever",
	},
	GemConnoisseur = {
		Path = "Gems",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
		Reward = "2x Gem Earnings",
		Multiplier = 2.0,
		Description = "Merge all 20 gem tiers to unlock 2x gem earnings forever",
	},

	-- Partial collections (milestone rewards)
	WeaponNovice = {
		Path = "Weapons",
		RequiredTiers = {1,2,3,4,5},
		Reward = "+10% Weapon Earnings",
		Multiplier = 1.1,
		Description = "Merge weapon tiers 1-5",
	},
	WeaponWarrior = {
		Path = "Weapons",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10},
		Reward = "+25% Weapon Earnings",
		Multiplier = 1.25,
		Description = "Merge weapon tiers 1-10",
	},
	PetFriend = {
		Path = "Pets",
		RequiredTiers = {1,2,3,4,5},
		Reward = "+10% Pet Earnings",
		Multiplier = 1.1,
		Description = "Merge pet tiers 1-5",
	},
	PetWhisperer = {
		Path = "Pets",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10},
		Reward = "+25% Pet Earnings",
		Multiplier = 1.25,
		Description = "Merge pet tiers 1-10",
	},
	FoodApprentice = {
		Path = "Food",
		RequiredTiers = {1,2,3,4,5},
		Reward = "+10% Food Earnings",
		Multiplier = 1.1,
		Description = "Merge food tiers 1-5",
	},
	FoodChef = {
		Path = "Food",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10},
		Reward = "+25% Food Earnings",
		Multiplier = 1.25,
		Description = "Merge food tiers 1-10",
	},
	GemHunter = {
		Path = "Gems",
		RequiredTiers = {1,2,3,4,5},
		Reward = "+10% Gem Earnings",
		Multiplier = 1.1,
		Description = "Merge gem tiers 1-5",
	},
	GemExpert = {
		Path = "Gems",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10},
		Reward = "+25% Gem Earnings",
		Multiplier = 1.25,
		Description = "Merge gem tiers 1-10",
	},

	-- Cross-path collections
	JackOfAllTrades = {
		Path = "ALL",
		RequiredTiers = {1,2,3,4,5}, -- tier 5 in all 4 paths
		Reward = "+15% All Earnings",
		Multiplier = 1.15,
		Description = "Reach tier 5 in all four merge paths",
	},
	MasterMerger = {
		Path = "ALL",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10},
		Reward = "+50% All Earnings",
		Multiplier = 1.5,
		Description = "Reach tier 10 in all four merge paths",
	},
	UniverseMerger = {
		Path = "ALL",
		RequiredTiers = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
		Reward = "3x All Earnings",
		Multiplier = 3.0,
		Description = "Complete all 20 tiers in all four paths",
	},
}

-- ============================================================================
-- PRESTIGE (Rebirth system)
-- ============================================================================
GameConfig.Prestige = {
	RequiredCoins = 1000000, -- 1M coins to first prestige
	ScalingFactor = 1.5, -- Each prestige costs 1.5x more
	Multiplier = 0.30, -- +30% earnings per prestige level
	MaxLevel = 50,
	Rewards = {
		[1]  = { Type = "Generator", Name = "Steel Forge (all paths)", Description = "Unlock Tier 2 generators" },
		[2]  = { Type = "Feature", Name = "Auto-Merge Hint", Description = "Shows best merge available" },
		[3]  = { Type = "Generator", Name = "Mythril tier generators", Description = "Unlock Tier 3 generators" },
		[5]  = { Type = "Generator", Name = "Dragon tier generators", Description = "Unlock Tier 4 generators" },
		[7]  = { Type = "Feature", Name = "Lucky Aura", Description = "+5% golden merge chance" },
		[10] = { Type = "Feature", Name = "Super Offline", Description = "Offline cap raised to 8 hours" },
		[15] = { Type = "Feature", Name = "Mega Luck", Description = "+10% golden merge chance" },
		[20] = { Type = "Feature", Name = "Ultra Offline", Description = "Offline cap raised to 12 hours" },
		[25] = { Type = "Feature", Name = "Master Merge", Description = "5% chance to triple merge" },
		[30] = { Type = "Feature", Name = "Infinity Luck", Description = "+15% golden merge chance" },
		[40] = { Type = "Feature", Name = "Cosmic Power", Description = "2x all passive earnings" },
		[50] = { Type = "Feature", Name = "Universe Master", Description = "3x all earnings, golden title" },
	},
}

-- ============================================================================
-- OFFLINE EARNINGS
-- ============================================================================
GameConfig.OfflineEarnings = {
	Enabled = true,
	DefaultCapHours = 4,
	PrestigeCapHours = {
		[10] = 8,
		[20] = 12,
	},
	OfflineEfficiency = 0.5, -- Earn 50% of normal rate while offline
	VIPEfficiency = 0.75, -- VIP earns 75% offline
}

-- ============================================================================
-- SPECIAL EVENTS (Limited-time merge chains)
-- ============================================================================
GameConfig.Events = {
	HolidayMerge = {
		Name = "Holiday Merge Madness",
		Duration = 72, -- hours
		SpecialPath = "Holiday",
		BonusCoinMultiplier = 2.0,
		SpecialTiers = {
			{ Name = "Snowflake", Tier = 1, CoinPerSec = 5, Color = Color3.fromRGB(200, 230, 255) },
			{ Name = "Candy Cane", Tier = 2, CoinPerSec = 15, Color = Color3.fromRGB(255, 0, 0) },
			{ Name = "Gingerbread", Tier = 3, CoinPerSec = 40, Color = Color3.fromRGB(180, 120, 60) },
			{ Name = "Christmas Tree", Tier = 4, CoinPerSec = 100, Color = Color3.fromRGB(0, 128, 0) },
			{ Name = "Santa's Sleigh", Tier = 5, CoinPerSec = 300, Color = Color3.fromRGB(255, 0, 0) },
			{ Name = "Rudolph", Tier = 6, CoinPerSec = 800, Color = Color3.fromRGB(139, 69, 19) },
			{ Name = "North Star", Tier = 7, CoinPerSec = 2500, Color = Color3.fromRGB(255, 255, 200) },
			{ Name = "Holiday Spirit", Tier = 8, CoinPerSec = 8000, Color = Color3.fromRGB(255, 215, 0) },
		},
		ExclusiveReward = { Name = "Holiday Crown", Type = "Cosmetic", Description = "Exclusive holiday crown" },
	},
	LunarNewYear = {
		Name = "Lunar New Year Festival",
		Duration = 48,
		SpecialPath = "Lunar",
		BonusCoinMultiplier = 1.5,
		SpecialTiers = {
			{ Name = "Red Envelope", Tier = 1, CoinPerSec = 5, Color = Color3.fromRGB(255, 0, 0) },
			{ Name = "Firecracker", Tier = 2, CoinPerSec = 15, Color = Color3.fromRGB(255, 165, 0) },
			{ Name = "Lantern", Tier = 3, CoinPerSec = 40, Color = Color3.fromRGB(255, 50, 50) },
			{ Name = "Lucky Cat", Tier = 4, CoinPerSec = 100, Color = Color3.fromRGB(255, 215, 0) },
			{ Name = "Dragon Dance", Tier = 5, CoinPerSec = 300, Color = Color3.fromRGB(220, 20, 60) },
			{ Name = "Jade Emperor", Tier = 6, CoinPerSec = 1000, Color = Color3.fromRGB(0, 168, 107) },
		},
		ExclusiveReward = { Name = "Dragon Aura", Type = "Cosmetic", Description = "Exclusive dragon particle aura" },
	},
}

-- ============================================================================
-- MONETIZATION
-- ============================================================================
GameConfig.GamePasses = {
	AutoMerge = {
		Id = 0, -- Set real ID in production
		Name = "Auto Merge",
		Price = 499,
		Description = "Automatically merges matching adjacent items every 5 seconds",
		Icon = "rbxassetid://0",
	},
	DoubleEarnings = {
		Id = 0,
		Name = "2x Earnings",
		Price = 399,
		Description = "Permanently double all coin earnings",
		Icon = "rbxassetid://0",
	},
	GridExpansion = {
		Id = 0,
		Name = "Grid Expansion (8x8)",
		Price = 299,
		Description = "Expand your merge grid from 6x6 to 8x8 (64 slots!)",
		Icon = "rbxassetid://0",
	},
	PremiumGenerators = {
		Id = 0,
		Name = "Premium Generators",
		Price = 599,
		Description = "Unlock exclusive fast generators for all paths",
		Icon = "rbxassetid://0",
	},
	LuckyMerger = {
		Id = 0,
		Name = "Lucky Merger",
		Price = 249,
		Description = "Double golden merge chance permanently",
		Icon = "rbxassetid://0",
	},
	VIP = {
		Id = 0,
		Name = "VIP Pass",
		Price = 799,
		Description = "VIP badge, 2x offline earnings, exclusive VIP generators, golden nameplate",
		Icon = "rbxassetid://0",
	},
}

GameConfig.DevProducts = {
	Coins1000 = { Id = 0, Name = "1,000 Coins", Price = 49, Amount = 1000 },
	Coins5000 = { Id = 0, Name = "5,000 Coins", Price = 149, Amount = 5000 },
	Coins25000 = { Id = 0, Name = "25,000 Coins", Price = 499, Amount = 25000 },
	Coins100000 = { Id = 0, Name = "100,000 Coins", Price = 999, Amount = 100000 },
	InstantMerge = { Id = 0, Name = "Instant Merge All", Price = 99, Description = "Merge all matching items on grid instantly" },
	ClearGrid = { Id = 0, Name = "Clear Grid", Price = 49, Description = "Clear all items from grid (collect coin value)" },
	LuckyBoost30 = { Id = 0, Name = "Lucky Boost (30 min)", Price = 149, Description = "3x golden merge chance for 30 minutes" },
	SpeedBoost30 = { Id = 0, Name = "Speed Boost (30 min)", Price = 149, Description = "2x generator speed for 30 minutes" },
	SkipTierMerge = { Id = 0, Name = "Skip Tier Merge", Price = 199, Description = "Next merge jumps 2 tiers instead of 1" },
}

-- ============================================================================
-- DAILY REWARDS
-- ============================================================================
GameConfig.DailyRewards = {
	{ Day = 1,  Reward = "Coins", Amount = 500 },
	{ Day = 2,  Reward = "Coins", Amount = 1000 },
	{ Day = 3,  Reward = "LuckyBoost", Duration = 600, Description = "10 min Lucky Boost" },
	{ Day = 4,  Reward = "Coins", Amount = 2500 },
	{ Day = 5,  Reward = "Generator", GeneratorIndex = 5, Description = "Free Iron Forge" },
	{ Day = 6,  Reward = "Coins", Amount = 5000 },
	{ Day = 7,  Reward = "Coins", Amount = 10000, Bonus = "SpeedBoost", Duration = 1800, Description = "10K coins + 30 min Speed Boost" },
}

-- ============================================================================
-- UI THEME
-- ============================================================================
GameConfig.Theme = {
	BackgroundColor = Color3.fromRGB(20, 20, 30),
	PanelColor = Color3.fromRGB(35, 35, 50),
	AccentColor = Color3.fromRGB(80, 120, 255),
	TextColor = Color3.fromRGB(240, 240, 240),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	SuccessColor = Color3.fromRGB(50, 200, 80),
	WarningColor = Color3.fromRGB(255, 200, 50),
	ErrorColor = Color3.fromRGB(255, 60, 60),
	GoldenColor = Color3.fromRGB(255, 215, 0),
	TierColors = {
		Color3.fromRGB(200, 200, 200), -- Tier 1-3 (Common)
		Color3.fromRGB(200, 200, 200),
		Color3.fromRGB(200, 200, 200),
		Color3.fromRGB(76, 175, 80),   -- Tier 4-6 (Uncommon)
		Color3.fromRGB(76, 175, 80),
		Color3.fromRGB(76, 175, 80),
		Color3.fromRGB(33, 150, 243),  -- Tier 7-9 (Rare)
		Color3.fromRGB(33, 150, 243),
		Color3.fromRGB(33, 150, 243),
		Color3.fromRGB(156, 39, 176),  -- Tier 10-12 (Epic)
		Color3.fromRGB(156, 39, 176),
		Color3.fromRGB(156, 39, 176),
		Color3.fromRGB(255, 193, 7),   -- Tier 13-15 (Legendary)
		Color3.fromRGB(255, 193, 7),
		Color3.fromRGB(255, 193, 7),
		Color3.fromRGB(255, 87, 34),   -- Tier 16-18 (Mythical)
		Color3.fromRGB(255, 87, 34),
		Color3.fromRGB(255, 87, 34),
		Color3.fromRGB(255, 0, 128),   -- Tier 19-20 (Divine)
		Color3.fromRGB(255, 0, 128),
	},
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function GameConfig.GetTierData(path, tier)
	local pathData = GameConfig.MergePaths[path]
	if not pathData then return nil end
	for _, tierData in ipairs(pathData.Tiers) do
		if tierData.Tier == tier then
			return tierData
		end
	end
	return nil
end

function GameConfig.GetMaxTier()
	return 20
end

function GameConfig.GetTierColor(tier)
	if tier >= 1 and tier <= #GameConfig.Theme.TierColors then
		return GameConfig.Theme.TierColors[tier]
	end
	return Color3.fromRGB(255, 255, 255)
end

function GameConfig.GetGeneratorsByPrestige(prestigeLevel)
	local available = {}
	for _, gen in ipairs(GameConfig.Generators) do
		if gen.UnlockPrestige <= prestigeLevel then
			table.insert(available, gen)
		end
	end
	return available
end

function GameConfig.GetOfflineCap(prestigeLevel)
	local cap = GameConfig.OfflineEarnings.DefaultCapHours
	for reqLevel, hours in pairs(GameConfig.OfflineEarnings.PrestigeCapHours) do
		if prestigeLevel >= reqLevel and hours > cap then
			cap = hours
		end
	end
	return cap * 3600 -- Return in seconds
end

function GameConfig.FormatNumber(num)
	if num >= 1e12 then
		return string.format("%.1fT", num / 1e12)
	elseif num >= 1e9 then
		return string.format("%.1fB", num / 1e9)
	elseif num >= 1e6 then
		return string.format("%.1fM", num / 1e6)
	elseif num >= 1e3 then
		return string.format("%.1fK", num / 1e3)
	else
		return tostring(math.floor(num))
	end
end

return GameConfig
