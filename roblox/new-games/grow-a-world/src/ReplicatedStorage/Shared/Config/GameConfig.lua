--[[
	GameConfig.lua - Grow a World
	Farming Simulator inspired by Grow a Garden (fastest to 1B visits on Roblox)

	Multi-biome farming with trading, rarity systems, and prestige
]]

local GameConfig = {}

-- ============================================================================
-- BIOMES (Unlockable worlds)
-- ============================================================================
GameConfig.Biomes = {
	Meadow = { Order = 1, UnlockCost = 0, PlotCount = 6, GrowthMultiplier = 1.0, Color = Color3.fromRGB(124, 185, 76) },
	Desert = { Order = 2, UnlockCost = 5000, PlotCount = 8, GrowthMultiplier = 0.8, Color = Color3.fromRGB(237, 201, 120) },
	Tropical = { Order = 3, UnlockCost = 25000, PlotCount = 10, GrowthMultiplier = 1.2, Color = Color3.fromRGB(34, 177, 76) },
	Crystal = { Order = 4, UnlockCost = 100000, PlotCount = 12, GrowthMultiplier = 1.5, Color = Color3.fromRGB(147, 112, 219) },
	Sky = { Order = 5, UnlockCost = 500000, PlotCount = 14, GrowthMultiplier = 2.0, Color = Color3.fromRGB(135, 206, 250) },
	Volcanic = { Order = 6, UnlockCost = 2000000, PlotCount = 16, GrowthMultiplier = 3.0, Color = Color3.fromRGB(255, 69, 0) },
	Underwater = { Order = 7, UnlockCost = 10000000, PlotCount = 20, GrowthMultiplier = 5.0, Color = Color3.fromRGB(0, 105, 148) },
	Void = { Order = 8, UnlockCost = 50000000, PlotCount = 24, GrowthMultiplier = 10.0, Color = Color3.fromRGB(48, 25, 52) },
}

-- ============================================================================
-- SEED RARITIES
-- ============================================================================
GameConfig.Rarities = {
	Common     = { Weight = 500, Color = Color3.fromRGB(200, 200, 200), Multiplier = 1 },
	Uncommon   = { Weight = 300, Color = Color3.fromRGB(76, 175, 80), Multiplier = 2 },
	Rare       = { Weight = 120, Color = Color3.fromRGB(33, 150, 243), Multiplier = 5 },
	Epic       = { Weight = 50,  Color = Color3.fromRGB(156, 39, 176), Multiplier = 15 },
	Legendary  = { Weight = 20,  Color = Color3.fromRGB(255, 193, 7), Multiplier = 50 },
	Mythical   = { Weight = 8,   Color = Color3.fromRGB(255, 87, 34), Multiplier = 200 },
	Divine     = { Weight = 2,   Color = Color3.fromRGB(255, 0, 128), Multiplier = 1000 },
}

-- ============================================================================
-- SEEDS (Per-biome seeds with rarity tiers)
-- ============================================================================
GameConfig.Seeds = {
	-- Meadow Seeds
	{ Name = "Daisy", Biome = "Meadow", Rarity = "Common", GrowTime = 10, Value = 5, Description = "A cheerful common flower" },
	{ Name = "Sunflower", Biome = "Meadow", Rarity = "Common", GrowTime = 15, Value = 8, Description = "Tall and bright" },
	{ Name = "Rose", Biome = "Meadow", Rarity = "Uncommon", GrowTime = 25, Value = 20, Description = "Classic beauty" },
	{ Name = "Tulip", Biome = "Meadow", Rarity = "Uncommon", GrowTime = 30, Value = 30, Description = "Spring favorite" },
	{ Name = "Orchid", Biome = "Meadow", Rarity = "Rare", GrowTime = 60, Value = 100, Description = "Elegant and rare" },
	{ Name = "Golden Lily", Biome = "Meadow", Rarity = "Epic", GrowTime = 120, Value = 500, Description = "Glows with golden light" },
	{ Name = "Rainbow Blossom", Biome = "Meadow", Rarity = "Legendary", GrowTime = 300, Value = 2500, Description = "Shimmers with every color" },
	{ Name = "Celestial Bloom", Biome = "Meadow", Rarity = "Mythical", GrowTime = 600, Value = 15000, Description = "Blooms under starlight" },

	-- Desert Seeds
	{ Name = "Cactus", Biome = "Desert", Rarity = "Common", GrowTime = 12, Value = 10, Description = "Prickly but valuable" },
	{ Name = "Aloe Vera", Biome = "Desert", Rarity = "Common", GrowTime = 18, Value = 15, Description = "Healing properties" },
	{ Name = "Desert Rose", Biome = "Desert", Rarity = "Uncommon", GrowTime = 35, Value = 40, Description = "Blooms in harsh conditions" },
	{ Name = "Saguaro", Biome = "Desert", Rarity = "Rare", GrowTime = 90, Value = 200, Description = "Ancient desert guardian" },
	{ Name = "Mirage Flower", Biome = "Desert", Rarity = "Epic", GrowTime = 180, Value = 800, Description = "Is it real? Yes!" },
	{ Name = "Sand Phoenix", Biome = "Desert", Rarity = "Legendary", GrowTime = 360, Value = 5000, Description = "Rises from desert sands" },

	-- Tropical Seeds
	{ Name = "Palm", Biome = "Tropical", Rarity = "Common", GrowTime = 14, Value = 15, Description = "Tropical classic" },
	{ Name = "Hibiscus", Biome = "Tropical", Rarity = "Uncommon", GrowTime = 28, Value = 35, Description = "Vibrant tropical flower" },
	{ Name = "Bird of Paradise", Biome = "Tropical", Rarity = "Rare", GrowTime = 75, Value = 175, Description = "Nature's masterpiece" },
	{ Name = "Jungle Heart", Biome = "Tropical", Rarity = "Epic", GrowTime = 150, Value = 700, Description = "Pulses with jungle energy" },
	{ Name = "Titan Arum", Biome = "Tropical", Rarity = "Legendary", GrowTime = 400, Value = 6000, Description = "The largest flower ever" },

	-- Crystal Seeds
	{ Name = "Crystal Sprout", Biome = "Crystal", Rarity = "Uncommon", GrowTime = 30, Value = 50, Description = "Grows from pure crystal" },
	{ Name = "Amethyst Vine", Biome = "Crystal", Rarity = "Rare", GrowTime = 80, Value = 250, Description = "Purple crystal beauty" },
	{ Name = "Diamond Blossom", Biome = "Crystal", Rarity = "Epic", GrowTime = 200, Value = 1200, Description = "Sparkles like diamonds" },
	{ Name = "Prismatic Tree", Biome = "Crystal", Rarity = "Legendary", GrowTime = 500, Value = 8000, Description = "Refracts all light" },
	{ Name = "Void Crystal", Biome = "Crystal", Rarity = "Mythical", GrowTime = 900, Value = 30000, Description = "From beyond reality" },

	-- Sky Seeds
	{ Name = "Cloud Puff", Biome = "Sky", Rarity = "Uncommon", GrowTime = 25, Value = 60, Description = "Soft as clouds" },
	{ Name = "Star Flower", Biome = "Sky", Rarity = "Rare", GrowTime = 70, Value = 300, Description = "Plucked from the sky" },
	{ Name = "Aurora Bloom", Biome = "Sky", Rarity = "Epic", GrowTime = 180, Value = 1500, Description = "Northern lights in a flower" },
	{ Name = "Constellation Tree", Biome = "Sky", Rarity = "Legendary", GrowTime = 450, Value = 10000, Description = "Maps the heavens" },

	-- Volcanic Seeds
	{ Name = "Lava Lily", Biome = "Volcanic", Rarity = "Rare", GrowTime = 60, Value = 400, Description = "Thrives in extreme heat" },
	{ Name = "Magma Rose", Biome = "Volcanic", Rarity = "Epic", GrowTime = 150, Value = 2000, Description = "Petals of molten rock" },
	{ Name = "Phoenix Flower", Biome = "Volcanic", Rarity = "Legendary", GrowTime = 400, Value = 12000, Description = "Reborn from ashes" },
	{ Name = "Core Blossom", Biome = "Volcanic", Rarity = "Mythical", GrowTime = 800, Value = 50000, Description = "From the planet's core" },

	-- Underwater Seeds
	{ Name = "Sea Anemone", Biome = "Underwater", Rarity = "Rare", GrowTime = 50, Value = 500, Description = "Waves gently in currents" },
	{ Name = "Coral Tree", Biome = "Underwater", Rarity = "Epic", GrowTime = 120, Value = 2500, Description = "Ancient coral formation" },
	{ Name = "Abyssal Bloom", Biome = "Underwater", Rarity = "Legendary", GrowTime = 350, Value = 15000, Description = "Glows in the deep" },
	{ Name = "Leviathan Kelp", Biome = "Underwater", Rarity = "Mythical", GrowTime = 700, Value = 60000, Description = "Stretches to the surface" },

	-- Void Seeds
	{ Name = "Shadow Sprout", Biome = "Void", Rarity = "Epic", GrowTime = 100, Value = 5000, Description = "Absorbs all light" },
	{ Name = "Entropy Rose", Biome = "Void", Rarity = "Legendary", GrowTime = 300, Value = 25000, Description = "Defies natural laws" },
	{ Name = "Infinity Bloom", Biome = "Void", Rarity = "Mythical", GrowTime = 600, Value = 100000, Description = "Never stops growing" },
	{ Name = "Genesis Flower", Biome = "Void", Rarity = "Divine", GrowTime = 1800, Value = 1000000, Description = "The first flower ever" },
}

-- ============================================================================
-- TOOLS
-- ============================================================================
GameConfig.Tools = {
	WateringCan = {
		Levels = {
			{ Name = "Rusty Can", Cost = 0, SpeedBoost = 1.0 },
			{ Name = "Copper Can", Cost = 500, SpeedBoost = 1.25 },
			{ Name = "Silver Can", Cost = 2500, SpeedBoost = 1.5 },
			{ Name = "Gold Can", Cost = 15000, SpeedBoost = 2.0 },
			{ Name = "Diamond Can", Cost = 100000, SpeedBoost = 3.0 },
			{ Name = "Crystal Can", Cost = 500000, SpeedBoost = 5.0 },
			{ Name = "Void Can", Cost = 5000000, SpeedBoost = 10.0 },
		},
	},
	Fertilizer = {
		Levels = {
			{ Name = "Basic Fertilizer", Cost = 0, ValueBoost = 1.0 },
			{ Name = "Enhanced Fertilizer", Cost = 1000, ValueBoost = 1.5 },
			{ Name = "Premium Fertilizer", Cost = 10000, ValueBoost = 2.0 },
			{ Name = "Golden Fertilizer", Cost = 75000, ValueBoost = 3.0 },
			{ Name = "Crystal Fertilizer", Cost = 500000, ValueBoost = 5.0 },
			{ Name = "Divine Fertilizer", Cost = 5000000, ValueBoost = 10.0 },
		},
	},
}

-- ============================================================================
-- PRESTIGE (Rebirth System)
-- ============================================================================
GameConfig.Prestige = {
	RequiredCoins = 1000000, -- 1M coins to prestige
	Multiplier = 0.25, -- +25% per prestige level
	MaxLevel = 100,
	Rewards = {
		[1] = "Exclusive Meadow Seed",
		[5] = "Auto-Harvest Ability",
		[10] = "Lucky Seed Finder",
		[25] = "Golden Garden Theme",
		[50] = "Mythical Seed Guaranteed",
		[100] = "Divine Garden Master Title",
	},
}

-- ============================================================================
-- MONETIZATION
-- ============================================================================
GameConfig.GamePasses = {
	AutoHarvest = { Id = 0, Name = "Auto Harvest", Price = 399, Description = "Automatically harvest mature plants" },
	LuckBoost = { Id = 0, Name = "2x Luck", Price = 299, Description = "Double chance for rare seeds" },
	ExtraPlots = { Id = 0, Name = "Extra Plots", Price = 199, Description = "+4 garden plots in every biome" },
	SpeedGrow = { Id = 0, Name = "Speed Grow", Price = 499, Description = "Plants grow 50% faster" },
	VIP = { Id = 0, Name = "VIP", Price = 799, Description = "VIP badge, 2x coins, exclusive seeds, VIP area" },
	RainbowTrail = { Id = 0, Name = "Rainbow Trail", Price = 149, Description = "Beautiful rainbow trail effect" },
	MusicPlayer = { Id = 0, Name = "Music Player", Price = 99, Description = "Custom music player in garden" },
}

GameConfig.DevProducts = {
	Coins1000 = { Id = 0, Name = "1,000 Coins", Price = 49, Amount = 1000 },
	Coins5000 = { Id = 0, Name = "5,000 Coins", Price = 149, Amount = 5000 },
	Coins25000 = { Id = 0, Name = "25,000 Coins", Price = 499, Amount = 25000 },
	RareSeedPack = { Id = 0, Name = "Rare Seed Pack", Price = 199, Description = "3 guaranteed rare+ seeds" },
	InstantGrow = { Id = 0, Name = "Instant Grow", Price = 99, Description = "Instantly grow all current plants" },
	LuckPotion = { Id = 0, Name = "Luck Potion (30min)", Price = 149, Description = "3x luck for 30 minutes" },
}

-- ============================================================================
-- DAILY REWARDS
-- ============================================================================
GameConfig.DailyRewards = {
	{ Day = 1, Reward = "Coins", Amount = 100 },
	{ Day = 2, Reward = "Seeds", Amount = 3, Rarity = "Uncommon" },
	{ Day = 3, Reward = "Coins", Amount = 250 },
	{ Day = 4, Reward = "Seeds", Amount = 2, Rarity = "Rare" },
	{ Day = 5, Reward = "Coins", Amount = 500 },
	{ Day = 6, Reward = "Seeds", Amount = 1, Rarity = "Epic" },
	{ Day = 7, Reward = "Seeds", Amount = 1, Rarity = "Legendary" },
}

-- ============================================================================
-- TRADING
-- ============================================================================
GameConfig.Trading = {
	Enabled = true,
	MaxItemsPerTrade = 8,
	MinAccountAge = 3, -- days
	CooldownSeconds = 30,
}

-- ============================================================================
-- LEADERBOARDS
-- ============================================================================
GameConfig.Leaderboards = {
	"TotalCoinsEarned",
	"PlantsHarvested",
	"RarestPlant",
	"PrestigeLevel",
	"BiomesUnlocked",
}

return GameConfig
