--[[
	GameConfig.lua - Pet Kingdom Tycoon
	Master config: pets, worlds, eggs, breeding, kingdom structures, evolution
]]

local GameConfig = {}

-- ============================================================================
-- WORLDS (8 themed worlds with unique pets)
-- ============================================================================
GameConfig.Worlds = {
	{ Name = "Forest", UnlockCost = 0, EggTypes = {"Forest Egg"}, Theme = "green", Pets = 12 },
	{ Name = "Ocean", UnlockCost = 5000, EggTypes = {"Ocean Egg"}, Theme = "blue", Pets = 12 },
	{ Name = "Sky", UnlockCost = 25000, EggTypes = {"Sky Egg"}, Theme = "cyan", Pets = 12 },
	{ Name = "Lava", UnlockCost = 100000, EggTypes = {"Lava Egg"}, Theme = "red", Pets = 12 },
	{ Name = "Ice", UnlockCost = 500000, EggTypes = {"Ice Egg"}, Theme = "white", Pets = 12 },
	{ Name = "Shadow", UnlockCost = 2000000, EggTypes = {"Shadow Egg"}, Theme = "purple", Pets = 12 },
	{ Name = "Crystal", UnlockCost = 10000000, EggTypes = {"Crystal Egg"}, Theme = "pink", Pets = 12 },
	{ Name = "Cosmic", UnlockCost = 50000000, EggTypes = {"Cosmic Egg"}, Theme = "gold", Pets = 16 },
}

-- ============================================================================
-- PETS (100+ pets across all worlds, 3 evolution stages each)
-- ============================================================================
GameConfig.Pets = {
	-- Forest (12)
	{ Name = "Leafling", Rarity = "Common", World = "Forest", CoinGen = 1, Egg = "Forest Egg", Evolutions = {"Leafling", "Treant", "Ancient Oak"} },
	{ Name = "Bunny", Rarity = "Common", World = "Forest", CoinGen = 1, Egg = "Forest Egg", Evolutions = {"Bunny", "Hare Knight", "Rabbit King"} },
	{ Name = "Mushroom Sprite", Rarity = "Common", World = "Forest", CoinGen = 2, Egg = "Forest Egg", Evolutions = {"Mushroom Sprite", "Fungi Warrior", "Spore Lord"} },
	{ Name = "Fox Cub", Rarity = "Uncommon", World = "Forest", CoinGen = 3, Egg = "Forest Egg", Evolutions = {"Fox Cub", "Mystic Fox", "Nine-Tail"} },
	{ Name = "Deer Spirit", Rarity = "Uncommon", World = "Forest", CoinGen = 4, Egg = "Forest Egg", Evolutions = {"Deer Spirit", "Stag Guardian", "Forest Deity"} },
	{ Name = "Wolf Pup", Rarity = "Rare", World = "Forest", CoinGen = 8, Egg = "Forest Egg", Evolutions = {"Wolf Pup", "Alpha Wolf", "Storm Wolf"} },
	{ Name = "Bear Cub", Rarity = "Rare", World = "Forest", CoinGen = 10, Egg = "Forest Egg", Evolutions = {"Bear Cub", "Grizzly", "Ursa Major"} },
	{ Name = "Owl Sage", Rarity = "Epic", World = "Forest", CoinGen = 25, Egg = "Forest Egg", Evolutions = {"Owl Sage", "Wise Owl", "Athena Owl"} },
	{ Name = "Unicorn Foal", Rarity = "Epic", World = "Forest", CoinGen = 30, Egg = "Forest Egg", Evolutions = {"Unicorn Foal", "Unicorn", "Alicorn"} },
	{ Name = "Phoenix Chick", Rarity = "Legendary", World = "Forest", CoinGen = 100, Egg = "Forest Egg", Evolutions = {"Phoenix Chick", "Phoenix", "Eternal Phoenix"} },
	{ Name = "Dragon Hatchling", Rarity = "Legendary", World = "Forest", CoinGen = 150, Egg = "Forest Egg", Evolutions = {"Dragon Hatchling", "Drake", "Elder Dragon"} },
	{ Name = "World Tree Sprite", Rarity = "Mythical", World = "Forest", CoinGen = 500, Egg = "Forest Egg", Evolutions = {"World Tree Sprite", "Yggdrasil Keeper", "World Tree God"} },
	-- Ocean (12)
	{ Name = "Starfish", Rarity = "Common", World = "Ocean", CoinGen = 2, Egg = "Ocean Egg", Evolutions = {"Starfish", "Sea Star", "Constellation Star"} },
	{ Name = "Seahorse", Rarity = "Common", World = "Ocean", CoinGen = 2, Egg = "Ocean Egg", Evolutions = {"Seahorse", "Royal Seahorse", "Sea Dragon"} },
	{ Name = "Clownfish", Rarity = "Common", World = "Ocean", CoinGen = 3, Egg = "Ocean Egg", Evolutions = {"Clownfish", "Reef Guardian", "Coral King"} },
	{ Name = "Jellyfish", Rarity = "Uncommon", World = "Ocean", CoinGen = 6, Egg = "Ocean Egg", Evolutions = {"Jellyfish", "Neon Jelly", "Void Jelly"} },
	{ Name = "Octopus", Rarity = "Uncommon", World = "Ocean", CoinGen = 8, Egg = "Ocean Egg", Evolutions = {"Octopus", "Kraken Junior", "Leviathan"} },
	{ Name = "Shark Pup", Rarity = "Rare", World = "Ocean", CoinGen = 20, Egg = "Ocean Egg", Evolutions = {"Shark Pup", "Great White", "Megalodon"} },
	{ Name = "Sea Turtle", Rarity = "Rare", World = "Ocean", CoinGen = 18, Egg = "Ocean Egg", Evolutions = {"Sea Turtle", "Elder Turtle", "World Turtle"} },
	{ Name = "Dolphin", Rarity = "Epic", World = "Ocean", CoinGen = 50, Egg = "Ocean Egg", Evolutions = {"Dolphin", "Sky Dolphin", "Celestial Dolphin"} },
	{ Name = "Mermaid Cat", Rarity = "Epic", World = "Ocean", CoinGen = 60, Egg = "Ocean Egg", Evolutions = {"Mermaid Cat", "Siren Cat", "Ocean Empress Cat"} },
	{ Name = "Whale", Rarity = "Legendary", World = "Ocean", CoinGen = 200, Egg = "Ocean Egg", Evolutions = {"Whale", "Mystic Whale", "Cosmos Whale"} },
	{ Name = "Trident Fish", Rarity = "Legendary", World = "Ocean", CoinGen = 250, Egg = "Ocean Egg", Evolutions = {"Trident Fish", "Poseidon Fish", "Ocean God"} },
	{ Name = "Abyssal Serpent", Rarity = "Mythical", World = "Ocean", CoinGen = 1000, Egg = "Ocean Egg", Evolutions = {"Abyssal Serpent", "Deep One", "Abyss Lord"} },
	-- Sky (condensed)
	{ Name = "Cloud Bunny", Rarity = "Common", World = "Sky", CoinGen = 4, Egg = "Sky Egg", Evolutions = {"Cloud Bunny", "Storm Hare", "Thunder Rabbit"} },
	{ Name = "Wind Fairy", Rarity = "Uncommon", World = "Sky", CoinGen = 10, Egg = "Sky Egg", Evolutions = {"Wind Fairy", "Gale Spirit", "Tempest Queen"} },
	{ Name = "Lightning Hawk", Rarity = "Rare", World = "Sky", CoinGen = 30, Egg = "Sky Egg", Evolutions = {"Lightning Hawk", "Thunder Eagle", "Storm Roc"} },
	{ Name = "Pegasus Foal", Rarity = "Epic", World = "Sky", CoinGen = 80, Egg = "Sky Egg", Evolutions = {"Pegasus Foal", "Pegasus", "Divine Pegasus"} },
	{ Name = "Thunder Dragon", Rarity = "Legendary", World = "Sky", CoinGen = 400, Egg = "Sky Egg", Evolutions = {"Thunder Dragon", "Storm Dragon", "Sky Emperor"} },
	{ Name = "Celestial Phoenix", Rarity = "Mythical", World = "Sky", CoinGen = 2000, Egg = "Sky Egg", Evolutions = {"Celestial Phoenix", "Solar Phoenix", "Galaxy Phoenix"} },
	-- Lava
	{ Name = "Magma Slime", Rarity = "Common", World = "Lava", CoinGen = 8, Egg = "Lava Egg", Evolutions = {"Magma Slime", "Lava Golem", "Volcanic Titan"} },
	{ Name = "Fire Imp", Rarity = "Uncommon", World = "Lava", CoinGen = 20, Egg = "Lava Egg", Evolutions = {"Fire Imp", "Inferno Demon", "Blaze Archon"} },
	{ Name = "Lava Serpent", Rarity = "Rare", World = "Lava", CoinGen = 60, Egg = "Lava Egg", Evolutions = {"Lava Serpent", "Magma Wyrm", "Volcano Dragon"} },
	{ Name = "Phoenix Lord", Rarity = "Epic", World = "Lava", CoinGen = 150, Egg = "Lava Egg", Evolutions = {"Phoenix Lord", "Infernal Phoenix", "Supernova Phoenix"} },
	{ Name = "Obsidian Dragon", Rarity = "Legendary", World = "Lava", CoinGen = 800, Egg = "Lava Egg", Evolutions = {"Obsidian Dragon", "Molten Dragon", "Core Dragon"} },
	{ Name = "Hellfire Titan", Rarity = "Mythical", World = "Lava", CoinGen = 5000, Egg = "Lava Egg", Evolutions = {"Hellfire Titan", "Infernal God", "Apocalypse Beast"} },
	-- Ice, Shadow, Crystal, Cosmic (abbreviated - same pattern)
	{ Name = "Frost Kitten", Rarity = "Common", World = "Ice", CoinGen = 15, Egg = "Ice Egg", Evolutions = {"Frost Kitten", "Blizzard Cat", "Arctic Emperor"} },
	{ Name = "Ice Phoenix", Rarity = "Legendary", World = "Ice", CoinGen = 1500, Egg = "Ice Egg", Evolutions = {"Ice Phoenix", "Glacial Phoenix", "Absolute Zero"} },
	{ Name = "Shadow Wisp", Rarity = "Common", World = "Shadow", CoinGen = 30, Egg = "Shadow Egg", Evolutions = {"Shadow Wisp", "Dark Phantom", "Void Walker"} },
	{ Name = "Nightmare", Rarity = "Legendary", World = "Shadow", CoinGen = 3000, Egg = "Shadow Egg", Evolutions = {"Nightmare", "Dread Knight", "Shadow King"} },
	{ Name = "Crystal Pup", Rarity = "Common", World = "Crystal", CoinGen = 60, Egg = "Crystal Egg", Evolutions = {"Crystal Pup", "Gem Hound", "Diamond Wolf"} },
	{ Name = "Prismatic Dragon", Rarity = "Legendary", World = "Crystal", CoinGen = 6000, Egg = "Crystal Egg", Evolutions = {"Prismatic Dragon", "Rainbow Dragon", "Spectrum God"} },
	{ Name = "Star Sprite", Rarity = "Common", World = "Cosmic", CoinGen = 120, Egg = "Cosmic Egg", Evolutions = {"Star Sprite", "Nova Spirit", "Galaxy Being"} },
	{ Name = "Cosmic Deity", Rarity = "Mythical", World = "Cosmic", CoinGen = 50000, Egg = "Cosmic Egg", Evolutions = {"Cosmic Deity", "Universe Creator", "Omni-God"} },
}

-- ============================================================================
-- EGGS
-- ============================================================================
GameConfig.Eggs = {
	{ Name = "Forest Egg", World = "Forest", Cost = 200, HatchTime = 5, Weights = { Common = 55, Uncommon = 25, Rare = 12, Epic = 5, Legendary = 2.5, Mythical = 0.5 } },
	{ Name = "Ocean Egg", World = "Ocean", Cost = 1000, HatchTime = 8, Weights = { Common = 50, Uncommon = 25, Rare = 15, Epic = 6, Legendary = 3, Mythical = 1 } },
	{ Name = "Sky Egg", World = "Sky", Cost = 5000, HatchTime = 12, Weights = { Common = 45, Uncommon = 25, Rare = 17, Epic = 8, Legendary = 4, Mythical = 1 } },
	{ Name = "Lava Egg", World = "Lava", Cost = 25000, HatchTime = 15, Weights = { Common = 40, Uncommon = 25, Rare = 18, Epic = 10, Legendary = 5, Mythical = 2 } },
	{ Name = "Ice Egg", World = "Ice", Cost = 100000, HatchTime = 20, Weights = { Common = 35, Uncommon = 25, Rare = 20, Epic = 12, Legendary = 6, Mythical = 2 } },
	{ Name = "Shadow Egg", World = "Shadow", Cost = 500000, HatchTime = 25, Weights = { Common = 30, Uncommon = 25, Rare = 22, Epic = 13, Legendary = 7, Mythical = 3 } },
	{ Name = "Crystal Egg", World = "Crystal", Cost = 2500000, HatchTime = 30, Weights = { Common = 25, Uncommon = 22, Rare = 25, Epic = 15, Legendary = 9, Mythical = 4 } },
	{ Name = "Cosmic Egg", World = "Cosmic", Cost = 10000000, HatchTime = 40, Weights = { Common = 15, Uncommon = 20, Rare = 25, Epic = 20, Legendary = 14, Mythical = 6 } },
}

-- ============================================================================
-- KINGDOM STRUCTURES
-- ============================================================================
GameConfig.Structures = {
	{ Name = "Pet Habitat", Cost = 100, Capacity = 5, Description = "Houses pets" },
	{ Name = "Feeding Station", Cost = 500, Bonus = "evolution_speed", BonusAmount = 1.2, Description = "20% faster evolution" },
	{ Name = "Breeding Center", Cost = 2000, Bonus = "breed_speed", BonusAmount = 1.5, Description = "50% faster breeding" },
	{ Name = "Coin Fountain", Cost = 5000, Bonus = "coin_gen", BonusAmount = 1.25, Description = "25% more pet coins" },
	{ Name = "Lucky Shrine", Cost = 15000, Bonus = "egg_luck", BonusAmount = 1.3, Description = "30% better egg luck" },
	{ Name = "Trophy Hall", Cost = 30000, Bonus = "collection_bonus", BonusAmount = 1.5, Description = "Display trophies" },
	{ Name = "Portal Tower", Cost = 100000, Bonus = "world_discount", BonusAmount = 0.8, Description = "20% cheaper world unlocks" },
	{ Name = "Golden Palace", Cost = 500000, Bonus = "all_bonus", BonusAmount = 1.1, Description = "10% all bonuses" },
}

-- ============================================================================
-- BREEDING
-- ============================================================================
GameConfig.Breeding = {
	BaseDuration = 60, -- seconds
	MaxActive = 1,
	SpecialCombinations = {
		{ Parent1Rarity = "Legendary", Parent2Rarity = "Legendary", ResultRarity = "Mythical", Chance = 0.05 },
		{ Parent1Rarity = "Epic", Parent2Rarity = "Epic", ResultRarity = "Legendary", Chance = 0.1 },
		{ Parent1Rarity = "Rare", Parent2Rarity = "Rare", ResultRarity = "Epic", Chance = 0.15 },
	},
}

-- ============================================================================
-- EVOLUTION
-- ============================================================================
GameConfig.Evolution = {
	MaxLevel = 100,
	XPPerFeed = 10,
	FeedCost = 50, -- coins per feed
	EvolutionLevels = { 1, 35, 70 }, -- Stage 1, 2, 3
	StatMultipliers = { 1, 2.5, 6 }, -- Coin gen multiplier per stage
}

-- ============================================================================
-- PRESTIGE
-- ============================================================================
GameConfig.Prestige = {
	BaseCost = 1000000,
	CostMultiplier = 3,
	BoostPerLevel = 0.5,
	MaxLevel = 30,
}

-- ============================================================================
-- GAME PASSES
-- ============================================================================
GameConfig.GamePasses = {
	VIP = { Id = 0, Name = "VIP", Price = 399, Description = "2x coins, VIP area, gold name" },
	AutoHatch = { Id = 0, Name = "Auto Hatch", Price = 249, Description = "Automatically hatch eggs" },
	DoublePets = { Id = 0, Name = "2x Pet Luck", Price = 199, Description = "Double rare pet chance" },
	MegaStorage = { Id = 0, Name = "Mega Storage", Price = 149, Description = "Double pet capacity" },
	InstantBreed = { Id = 0, Name = "Instant Breed", Price = 299, Description = "No breeding wait time" },
}

GameConfig.DevProducts = {
	Coins5000 = { Id = 0, Name = "5,000 Coins", Price = 49, Amount = 5000 },
	Coins50000 = { Id = 0, Name = "50,000 Coins", Price = 99, Amount = 50000 },
	Coins500000 = { Id = 0, Name = "500,000 Coins", Price = 199, Amount = 500000 },
	RareEgg = { Id = 0, Name = "Guaranteed Rare+ Egg", Price = 149, Description = "Hatch a rare or better pet" },
	InstantHatch = { Id = 0, Name = "Instant Hatch x5", Price = 79, Description = "Instantly hatch 5 eggs" },
}

-- ============================================================================
-- DAILY REWARDS
-- ============================================================================
GameConfig.DailyRewards = {
	{ Day = 1, Reward = "Coins", Amount = 500 },
	{ Day = 2, Reward = "Coins", Amount = 1000 },
	{ Day = 3, Reward = "Egg", EggType = "Forest Egg", Amount = 2 },
	{ Day = 4, Reward = "Coins", Amount = 3000 },
	{ Day = 5, Reward = "Egg", EggType = "Ocean Egg", Amount = 1 },
	{ Day = 6, Reward = "Coins", Amount = 8000 },
	{ Day = 7, Reward = "Egg", EggType = "Sky Egg", Amount = 1 },
}

-- ============================================================================
-- DEFAULT PLAYER DATA
-- ============================================================================
GameConfig.DefaultData = {
	Coins = 0,
	TotalCoinsEarned = 0,

	-- Worlds
	UnlockedWorlds = { "Forest" },

	-- Pets
	Pets = {},
	EquippedPets = {},
	MaxPets = 50,
	TotalEggsHatched = 0,

	-- Kingdom
	Structures = {},
	PlotLevel = 1,

	-- Breeding
	ActiveBreeding = nil,

	-- Prestige
	PrestigeLevel = 0,

	-- Trading
	TradesCompleted = 0,

	-- Login
	LastLoginDate = "",
	LoginStreak = 0,

	-- Game Passes
	GamePasses = {},
}

return GameConfig
