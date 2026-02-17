--[[
	GameConfig.lua - Escape the Factory
	Obby-style escape rooms with puzzles, traps, and horror elements
]]
local GC = {}

GC.MaxPlayersPerServer = 30

GC.Factories = {
	{ Name = "Toy Factory", Difficulty = 1, Rooms = 10, Theme = "Colorful", UnlockCost = 0 },
	{ Name = "Food Processing", Difficulty = 2, Rooms = 12, Theme = "Industrial", UnlockCost = 500 },
	{ Name = "Chemical Plant", Difficulty = 3, Rooms = 14, Theme = "Toxic", UnlockCost = 2000 },
	{ Name = "Robot Assembly", Difficulty = 4, Rooms = 16, Theme = "Mechanical", UnlockCost = 5000 },
	{ Name = "Nuclear Facility", Difficulty = 5, Rooms = 18, Theme = "Radioactive", UnlockCost = 12000 },
	{ Name = "Shadow Labs", Difficulty = 6, Rooms = 20, Theme = "Dark", UnlockCost = 25000 },
	{ Name = "Alien Mothership", Difficulty = 7, Rooms = 22, Theme = "SciFi", UnlockCost = 50000 },
	{ Name = "The Void", Difficulty = 8, Rooms = 25, Theme = "Void", UnlockCost = 100000 },
}

GC.TrapTypes = {
	{ Name = "Spinning Blades", Damage = 20, Pattern = "Rotation" },
	{ Name = "Laser Grid", Damage = 30, Pattern = "Toggle" },
	{ Name = "Crusher", Damage = 50, Pattern = "Timing" },
	{ Name = "Acid Pool", Damage = 15, Pattern = "Static" },
	{ Name = "Flame Jet", Damage = 25, Pattern = "Burst" },
	{ Name = "Electrified Floor", Damage = 35, Pattern = "Sequence" },
	{ Name = "Falling Ceiling", Damage = 40, Pattern = "Trigger" },
	{ Name = "Conveyor Belt", Damage = 0, Pattern = "Push" },
}

GC.PuzzleTypes = {
	"ButtonSequence", "ColorMatch", "PlatformMemory", "LaserReflect",
	"PipeConnect", "CodeCrack", "MazeRun", "SimonSays",
}

GC.Powerups = {
	{ Name = "Speed Boost", Duration = 10, Effect = "Speed", Mult = 1.5 },
	{ Name = "Shield", Duration = 8, Effect = "Shield", Mult = 1.0 },
	{ Name = "Double Jump", Duration = 15, Effect = "Jump", Mult = 2.0 },
	{ Name = "Ghost Mode", Duration = 5, Effect = "Noclip", Mult = 1.0 },
	{ Name = "Magnet", Duration = 12, Effect = "CoinMagnet", Mult = 1.0 },
}

GC.Collectibles = {
	{ Name = "Bronze Gear", Value = 10, Rarity = "Common", SpawnChance = 0.5 },
	{ Name = "Silver Gear", Value = 25, Rarity = "Uncommon", SpawnChance = 0.3 },
	{ Name = "Gold Gear", Value = 50, Rarity = "Rare", SpawnChance = 0.15 },
	{ Name = "Diamond Gear", Value = 100, Rarity = "Epic", SpawnChance = 0.04 },
	{ Name = "Void Gear", Value = 500, Rarity = "Legendary", SpawnChance = 0.01 },
}

GC.Companions = {
	{ Name = "Helper Bot", Cost = 1000, Ability = "Highlights traps", Rarity = "Common" },
	{ Name = "Scout Drone", Cost = 3000, Ability = "Reveals map ahead", Rarity = "Uncommon" },
	{ Name = "Shield Bot", Cost = 5000, Ability = "Blocks 1 hit per room", Rarity = "Rare" },
	{ Name = "Time Bot", Cost = 10000, Ability = "Slows traps 20%", Rarity = "Epic" },
	{ Name = "Phoenix Pet", Cost = 25000, Ability = "Auto-revive once per run", Rarity = "Legendary" },
}

GC.PlayerUpgrades = {
	{ Name = "Extra Health", MaxLevel = 10, BaseCost = 100, CostMult = 1.5, Effect = "+10 HP per level" },
	{ Name = "Speed", MaxLevel = 10, BaseCost = 150, CostMult = 1.5, Effect = "+5% speed per level" },
	{ Name = "Jump Power", MaxLevel = 10, BaseCost = 150, CostMult = 1.5, Effect = "+5% jump per level" },
	{ Name = "Coin Magnet", MaxLevel = 5, BaseCost = 500, CostMult = 2.0, Effect = "+2 stud range per level" },
	{ Name = "Lucky", MaxLevel = 5, BaseCost = 750, CostMult = 2.0, Effect = "+5% rare collectible chance" },
	{ Name = "Tough Skin", MaxLevel = 10, BaseCost = 200, CostMult = 1.5, Effect = "-5% trap damage" },
}

GC.TimeRewards = {
	{ MaxTime = 60, Stars = 3, BonusMult = 2.0, Label = "Speed Demon" },
	{ MaxTime = 120, Stars = 2, BonusMult = 1.5, Label = "Fast" },
	{ MaxTime = 300, Stars = 1, BonusMult = 1.0, Label = "Completed" },
}

GC.DailyRewards = {
	{ Day = 1, Reward = "Coins", Amount = 100 },
	{ Day = 2, Reward = "Coins", Amount = 200 },
	{ Day = 3, Reward = "Powerup", Amount = 1, Item = "Speed Boost" },
	{ Day = 4, Reward = "Coins", Amount = 400 },
	{ Day = 5, Reward = "Coins", Amount = 600 },
	{ Day = 6, Reward = "Powerup", Amount = 1, Item = "Ghost Mode" },
	{ Day = 7, Reward = "Coins", Amount = 1000 },
}

GC.GamePasses = {
	{ Name = "VIP", Id = 0, Price = 499, Benefits = "2x coins, VIP badge, exclusive companion" },
	{ Name = "Double Speed", Id = 0, Price = 199, Benefits = "Permanent 1.5x speed" },
	{ Name = "Extra Lives", Id = 0, Price = 149, Benefits = "3 lives per run instead of 1" },
	{ Name = "Skip Room", Id = 0, Price = 299, Benefits = "Skip 1 room per factory run" },
}

GC.DevProducts = {
	{ Name = "500 Coins", Id = 0, Price = 49, Amount = 500 },
	{ Name = "2500 Coins", Id = 0, Price = 199, Amount = 2500 },
	{ Name = "10000 Coins", Id = 0, Price = 699, Amount = 10000 },
	{ Name = "Instant Revive", Id = 0, Price = 29, ReviveType = true },
}

return GC
