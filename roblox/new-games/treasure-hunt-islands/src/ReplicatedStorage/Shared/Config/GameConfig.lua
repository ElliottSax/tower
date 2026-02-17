--[[
	GameConfig.lua - Treasure Hunt Islands
	Exploration/adventure - islands, treasure digging, ships, pirates
]]

local GameConfig = {}

GameConfig.Islands = {
	{ Name = "Starter Beach", UnlockCost = 0, Biome = "tropical", TreasureCount = 20, Difficulty = 1 },
	{ Name = "Palm Cove", UnlockCost = 1000, Biome = "tropical", TreasureCount = 25, Difficulty = 2 },
	{ Name = "Misty Marsh", UnlockCost = 5000, Biome = "swamp", TreasureCount = 30, Difficulty = 3 },
	{ Name = "Rocky Ridge", UnlockCost = 15000, Biome = "mountain", TreasureCount = 30, Difficulty = 4 },
	{ Name = "Frozen Fjord", UnlockCost = 50000, Biome = "ice", TreasureCount = 35, Difficulty = 5 },
	{ Name = "Volcanic Isle", UnlockCost = 150000, Biome = "lava", TreasureCount = 35, Difficulty = 7 },
	{ Name = "Sunken Ruins", UnlockCost = 500000, Biome = "underwater", TreasureCount = 40, Difficulty = 9 },
	{ Name = "Ghost Ship Graveyard", UnlockCost = 1500000, Biome = "haunted", TreasureCount = 40, Difficulty = 11 },
	{ Name = "Crystal Caverns", UnlockCost = 5000000, Biome = "crystal", TreasureCount = 45, Difficulty = 14 },
	{ Name = "Dragon's Hoard", UnlockCost = 20000000, Biome = "dragon", TreasureCount = 50, Difficulty = 18 },
	{ Name = "Celestial Atoll", UnlockCost = 75000000, Biome = "sky", TreasureCount = 50, Difficulty = 22 },
	{ Name = "Void Archipelago", UnlockCost = 250000000, Biome = "void", TreasureCount = 60, Difficulty = 30 },
}

GameConfig.Treasures = {
	{ Name = "Copper Coin", Rarity = "Common", Value = 5 },
	{ Name = "Silver Ring", Rarity = "Common", Value = 10 },
	{ Name = "Old Bottle", Rarity = "Common", Value = 3 },
	{ Name = "Pearl Necklace", Rarity = "Uncommon", Value = 25 },
	{ Name = "Gold Doubloon", Rarity = "Uncommon", Value = 50 },
	{ Name = "Ruby Pendant", Rarity = "Rare", Value = 150 },
	{ Name = "Emerald Crown", Rarity = "Rare", Value = 200 },
	{ Name = "Diamond Scepter", Rarity = "Epic", Value = 500 },
	{ Name = "Ancient Artifact", Rarity = "Epic", Value = 750 },
	{ Name = "Pirate King's Gold", Rarity = "Legendary", Value = 2000 },
	{ Name = "Cursed Idol", Rarity = "Legendary", Value = 3000 },
	{ Name = "Heart of the Ocean", Rarity = "Mythical", Value = 10000 },
}

GameConfig.Tools = {
	{ Name = "Wooden Shovel", DigSpeed = 1, Cost = 0 },
	{ Name = "Iron Shovel", DigSpeed = 1.5, Cost = 500 },
	{ Name = "Golden Shovel", DigSpeed = 2.5, Cost = 5000 },
	{ Name = "Diamond Shovel", DigSpeed = 4, Cost = 25000 },
	{ Name = "Enchanted Shovel", DigSpeed = 7, Cost = 100000 },
	{ Name = "Legendary Spade", DigSpeed = 12, Cost = 500000 },
}

GameConfig.Ships = {
	{ Name = "Rowboat", Speed = 1, Cargo = 10, Cost = 0 },
	{ Name = "Sailboat", Speed = 2, Cargo = 25, Cost = 5000 },
	{ Name = "Schooner", Speed = 3, Cargo = 50, Cost = 25000 },
	{ Name = "Galleon", Speed = 4, Cargo = 100, Cost = 100000 },
	{ Name = "Man-of-War", Speed = 5, Cargo = 200, Cost = 500000 },
	{ Name = "Ghost Ship", Speed = 7, Cargo = 500, Cost = 2500000 },
}

GameConfig.Pirates = {
	{ Name = "Deck Hand", HP = 50, Damage = 5, Coins = 20 },
	{ Name = "Pirate", HP = 80, Damage = 10, Coins = 50 },
	{ Name = "Captain", HP = 150, Damage = 20, Coins = 150 },
	{ Name = "Pirate Lord", HP = 300, Damage = 35, Coins = 500 },
	{ Name = "Kraken", HP = 1000, Damage = 60, Coins = 2000 },
	{ Name = "Ghost Captain", HP = 2000, Damage = 100, Coins = 5000 },
}

GameConfig.Crew = {
	{ Name = "Lookout", Ability = "treasure_radar", Bonus = 1.2, Cost = 5000 },
	{ Name = "Navigator", Ability = "sail_speed", Bonus = 1.3, Cost = 10000 },
	{ Name = "Digger", Ability = "dig_speed", Bonus = 1.5, Cost = 15000 },
	{ Name = "Fighter", Ability = "combat", Bonus = 1.4, Cost = 20000 },
	{ Name = "Merchant", Ability = "sell_price", Bonus = 1.25, Cost = 25000 },
}

GameConfig.GamePasses = {
	DoubleTreasure = { Id = 0, Name = "2x Treasure Luck", Price = 249, Description = "Double rare treasure chance" },
	PremiumShip = { Id = 0, Name = "Premium Ship", Price = 399, Description = "Exclusive fast ship with 1000 cargo" },
	TreasureRadar = { Id = 0, Name = "Treasure Radar", Price = 149, Description = "See treasure locations on map" },
	AutoDig = { Id = 0, Name = "Auto Dig", Price = 199, Description = "Automatically dig nearby treasures" },
}

GameConfig.DevProducts = {
	Coins5000 = { Id = 0, Name = "5,000 Coins", Price = 49, Amount = 5000 },
	Coins50000 = { Id = 0, Name = "50,000 Coins", Price = 99, Amount = 50000 },
	Coins500000 = { Id = 0, Name = "500,000 Coins", Price = 199, Amount = 500000 },
	TreasureMap = { Id = 0, Name = "Legendary Treasure Map", Price = 149, Description = "Reveals a legendary treasure" },
}

GameConfig.DefaultData = {
	Coins = 0, TotalCoinsEarned = 0,
	UnlockedIslands = { "Starter Beach" }, CurrentIsland = "Starter Beach",
	CurrentTool = "Wooden Shovel", CurrentShip = "Rowboat",
	Treasures = {}, TreasureCollection = {}, TreasuresDug = 0,
	Crew = {}, PiratesDefeated = 0, PrestigeLevel = 0,
	LastLoginDate = "", LoginStreak = 0, GamePasses = {},
}

return GameConfig
