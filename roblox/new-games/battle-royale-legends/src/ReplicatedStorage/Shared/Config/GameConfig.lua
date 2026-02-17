--[[
	GameConfig.lua - Battle Royale Legends
	Last player standing with looting, building, and storm mechanics
]]
local GC = {}

GC.MaxPlayers = 50
GC.MinPlayersToStart = 4
GC.LobbyWaitTime = 60
GC.MatchDuration = 600

GC.Weapons = {
	{ Name = "Wooden Sword", Damage = 10, Speed = 1.2, Rarity = "Common", DropWeight = 30 },
	{ Name = "Iron Blade", Damage = 18, Speed = 1.0, Rarity = "Common", DropWeight = 25 },
	{ Name = "Tactical Shotgun", Damage = 35, Speed = 0.6, Rarity = "Uncommon", DropWeight = 20 },
	{ Name = "Burst Rifle", Damage = 15, Speed = 1.5, Rarity = "Uncommon", DropWeight = 18 },
	{ Name = "Sniper Bow", Damage = 50, Speed = 0.4, Rarity = "Rare", DropWeight = 12 },
	{ Name = "Plasma Cannon", Damage = 40, Speed = 0.7, Rarity = "Rare", DropWeight = 10 },
	{ Name = "Dragon Katana", Damage = 55, Speed = 1.1, Rarity = "Epic", DropWeight = 5 },
	{ Name = "Thunder Hammer", Damage = 70, Speed = 0.5, Rarity = "Epic", DropWeight = 4 },
	{ Name = "Void Scythe", Damage = 80, Speed = 0.8, Rarity = "Legendary", DropWeight = 2 },
	{ Name = "Galaxy Blade", Damage = 100, Speed = 1.0, Rarity = "Legendary", DropWeight = 1 },
}

GC.Shields = {
	{ Name = "Small Shield", Amount = 25, Rarity = "Common", DropWeight = 30 },
	{ Name = "Medium Shield", Amount = 50, Rarity = "Uncommon", DropWeight = 20 },
	{ Name = "Large Shield", Amount = 100, Rarity = "Rare", DropWeight = 8 },
}

GC.Heals = {
	{ Name = "Bandage", Amount = 15, Rarity = "Common", DropWeight = 35 },
	{ Name = "Med Kit", Amount = 50, Rarity = "Uncommon", DropWeight = 18 },
	{ Name = "Golden Apple", Amount = 100, Rarity = "Rare", DropWeight = 5 },
}

GC.BuildPieces = {
	{ Name = "Wall", Cost = 10, HP = 150 },
	{ Name = "Ramp", Cost = 10, HP = 150 },
	{ Name = "Floor", Cost = 10, HP = 150 },
	{ Name = "Roof", Cost = 15, HP = 200 },
}

GC.Materials = {
	{ Name = "Wood", MaxStack = 999, DropWeight = 40 },
	{ Name = "Stone", MaxStack = 999, DropWeight = 30 },
	{ Name = "Metal", MaxStack = 999, DropWeight = 15 },
}

GC.StormPhases = {
	{ Delay = 90, ShrinkTime = 60, Damage = 1, RadiusPct = 1.0 },
	{ Delay = 60, ShrinkTime = 45, Damage = 2, RadiusPct = 0.7 },
	{ Delay = 45, ShrinkTime = 30, Damage = 5, RadiusPct = 0.45 },
	{ Delay = 30, ShrinkTime = 20, Damage = 10, RadiusPct = 0.25 },
	{ Delay = 15, ShrinkTime = 15, Damage = 20, RadiusPct = 0.1 },
	{ Delay = 10, ShrinkTime = 10, Damage = 50, RadiusPct = 0.0 },
}

GC.DropLocations = {
	"Tilted Towers", "Pleasant Park", "Dusty Depot", "Loot Lake",
	"Retail Row", "Salty Springs", "Haunted Hills", "Lucky Landing",
}

GC.Rarities = {
	Common = { Color = Color3.fromRGB(180, 180, 180), Mult = 1.0 },
	Uncommon = { Color = Color3.fromRGB(0, 200, 0), Mult = 1.2 },
	Rare = { Color = Color3.fromRGB(0, 100, 255), Mult = 1.5 },
	Epic = { Color = Color3.fromRGB(180, 0, 255), Mult = 2.0 },
	Legendary = { Color = Color3.fromRGB(255, 170, 0), Mult = 3.0 },
}

GC.XPRewards = {
	Kill = 50,
	Top10 = 100,
	Top5 = 200,
	Win = 500,
	DamageDealt = 1, -- per point of damage
}

GC.Ranks = {
	{ Name = "Bronze", MinXP = 0 },
	{ Name = "Silver", MinXP = 1000 },
	{ Name = "Gold", MinXP = 5000 },
	{ Name = "Platinum", MinXP = 15000 },
	{ Name = "Diamond", MinXP = 40000 },
	{ Name = "Champion", MinXP = 100000 },
	{ Name = "Legend", MinXP = 250000 },
}

GC.Skins = {
	{ Name = "Default", Cost = 0 },
	{ Name = "Shadow Warrior", Cost = 500 },
	{ Name = "Neon Knight", Cost = 1000 },
	{ Name = "Frost Titan", Cost = 2000 },
	{ Name = "Phoenix", Cost = 5000 },
	{ Name = "Void Walker", Cost = 10000 },
}

GC.GamePasses = {
	{ Name = "VIP", Id = 0, Price = 499, Benefits = "2x XP, VIP lobby, exclusive skin" },
	{ Name = "Double Loot", Id = 0, Price = 199, Benefits = "2x material drops" },
	{ Name = "Quick Revive", Id = 0, Price = 149, Benefits = "Self-revive once per match" },
	{ Name = "Storm Shield", Id = 0, Price = 99, Benefits = "50% less storm damage" },
}

GC.DevProducts = {
	{ Name = "1000 Coins", Id = 0, Price = 99, Amount = 1000 },
	{ Name = "5000 Coins", Id = 0, Price = 399, Amount = 5000 },
	{ Name = "15000 Coins", Id = 0, Price = 999, Amount = 15000 },
	{ Name = "XP Boost (1hr)", Id = 0, Price = 49, BoostType = "XP", Duration = 3600 },
}

return GC
