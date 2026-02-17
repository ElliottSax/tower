--[[
	GameConfig.lua - Dungeon Doors
	Horror roguelike - procedural dungeons, door voting, permadeath, souls meta-progression
]]

local GameConfig = {}

-- ============================================================================
-- DUNGEON FLOORS
-- ============================================================================
GameConfig.Floors = {
	{ Range = {1, 10}, Name = "Catacombs", RoomsPerFloor = 5, DifficultyMult = 1, Theme = "stone" },
	{ Range = {11, 20}, Name = "Sewers", RoomsPerFloor = 6, DifficultyMult = 2, Theme = "water" },
	{ Range = {21, 35}, Name = "Haunted Manor", RoomsPerFloor = 6, DifficultyMult = 3.5, Theme = "wood" },
	{ Range = {36, 50}, Name = "Crystal Caves", RoomsPerFloor = 7, DifficultyMult = 6, Theme = "crystal" },
	{ Range = {51, 70}, Name = "Infernal Pit", RoomsPerFloor = 7, DifficultyMult = 10, Theme = "lava" },
	{ Range = {71, 85}, Name = "Frozen Abyss", RoomsPerFloor = 8, DifficultyMult = 18, Theme = "ice" },
	{ Range = {86, 100}, Name = "Void Realm", RoomsPerFloor = 8, DifficultyMult = 30, Theme = "void" },
	{ Range = {101, 999}, Name = "Endless Depths", RoomsPerFloor = 10, DifficultyMult = 50, Theme = "chaos" },
}

-- ============================================================================
-- DOOR/ROOM TYPES
-- ============================================================================
GameConfig.RoomTypes = {
	{ Type = "Monster", Weight = 35, Description = "Fight monsters" },
	{ Type = "Treasure", Weight = 15, Description = "Loot chest" },
	{ Type = "Trap", Weight = 15, Description = "Avoid deadly traps" },
	{ Type = "Shop", Weight = 8, Description = "Buy items" },
	{ Type = "Boss", Weight = 0, Description = "Floor boss (forced)" },
	{ Type = "Safe", Weight = 12, Description = "Rest and heal" },
	{ Type = "Puzzle", Weight = 10, Description = "Solve to proceed" },
	{ Type = "Mimic", Weight = 5, Description = "Looks safe, but isn't..." },
}

-- ============================================================================
-- MONSTERS
-- ============================================================================
GameConfig.Monsters = {
	-- Common
	{ Name = "Skeleton", HP = 30, Damage = 5, Speed = 3, Souls = 5, Rarity = "Common" },
	{ Name = "Zombie", HP = 50, Damage = 8, Speed = 1.5, Souls = 8, Rarity = "Common" },
	{ Name = "Giant Spider", HP = 25, Damage = 10, Speed = 5, Souls = 7, Rarity = "Common" },
	{ Name = "Rat Swarm", HP = 20, Damage = 3, Speed = 6, Souls = 4, Rarity = "Common" },
	-- Uncommon
	{ Name = "Shadow Wraith", HP = 60, Damage = 15, Speed = 4, Souls = 15, Rarity = "Uncommon" },
	{ Name = "Bone Knight", HP = 80, Damage = 12, Speed = 2.5, Souls = 18, Rarity = "Uncommon" },
	{ Name = "Acid Slime", HP = 40, Damage = 20, Speed = 1, Souls = 12, Rarity = "Uncommon" },
	-- Rare
	{ Name = "Demon", HP = 120, Damage = 25, Speed = 3.5, Souls = 30, Rarity = "Rare" },
	{ Name = "Banshee", HP = 70, Damage = 35, Speed = 5, Souls = 35, Rarity = "Rare" },
	{ Name = "Golem", HP = 200, Damage = 15, Speed = 1, Souls = 40, Rarity = "Rare" },
	-- Epic
	{ Name = "Lich", HP = 180, Damage = 40, Speed = 3, Souls = 60, Rarity = "Epic" },
	{ Name = "Dragon Spawn", HP = 250, Damage = 45, Speed = 4, Souls = 80, Rarity = "Epic" },
}

-- ============================================================================
-- BOSSES (every 5 floors)
-- ============================================================================
GameConfig.Bosses = {
	{ Name = "Bone King", Floor = 5, HP = 500, Damage = 20, Souls = 100, Phases = 2 },
	{ Name = "Sewer Hydra", Floor = 10, HP = 800, Damage = 30, Souls = 200, Phases = 2 },
	{ Name = "Phantom Lord", Floor = 15, HP = 1200, Damage = 40, Souls = 350, Phases = 3 },
	{ Name = "Crystal Guardian", Floor = 20, HP = 1800, Damage = 55, Souls = 500, Phases = 3 },
	{ Name = "Demon Prince", Floor = 25, HP = 2500, Damage = 70, Souls = 750, Phases = 3 },
	{ Name = "Ice Wyrm", Floor = 30, HP = 3500, Damage = 90, Souls = 1000, Phases = 4 },
	{ Name = "Void Devourer", Floor = 50, HP = 8000, Damage = 150, Souls = 3000, Phases = 4 },
	{ Name = "The Nameless One", Floor = 100, HP = 25000, Damage = 300, Souls = 10000, Phases = 5 },
}

-- ============================================================================
-- WEAPONS
-- ============================================================================
GameConfig.Weapons = {
	{ Name = "Rusty Sword", Type = "Melee", Damage = 8, Speed = 1.0, Rarity = "Common" },
	{ Name = "Wooden Bow", Type = "Ranged", Damage = 6, Speed = 0.8, Rarity = "Common" },
	{ Name = "Iron Sword", Type = "Melee", Damage = 15, Speed = 1.0, Rarity = "Uncommon" },
	{ Name = "Fire Staff", Type = "Magic", Damage = 18, Speed = 0.7, Rarity = "Uncommon" },
	{ Name = "Shadow Dagger", Type = "Melee", Damage = 12, Speed = 1.5, Rarity = "Rare" },
	{ Name = "Thunder Bow", Type = "Ranged", Damage = 22, Speed = 0.9, Rarity = "Rare" },
	{ Name = "Demon Blade", Type = "Melee", Damage = 35, Speed = 1.1, Rarity = "Epic" },
	{ Name = "Void Staff", Type = "Magic", Damage = 40, Speed = 0.6, Rarity = "Epic" },
	{ Name = "Excalibur", Type = "Melee", Damage = 60, Speed = 1.2, Rarity = "Legendary" },
	{ Name = "Death's Scythe", Type = "Melee", Damage = 80, Speed = 0.8, Rarity = "Mythical" },
}

-- ============================================================================
-- CLASSES
-- ============================================================================
GameConfig.Classes = {
	{
		Name = "Warrior", HP = 150, BaseDamage = 1.2, BaseDefense = 1.3, BaseSpeed = 0.9,
		Ability = { Name = "Shield Bash", Damage = 20, Cooldown = 8, Type = "Stun" },
	},
	{
		Name = "Mage", HP = 80, BaseDamage = 1.5, BaseDefense = 0.7, BaseSpeed = 1.0,
		Ability = { Name = "Fireball", Damage = 40, Cooldown = 5, Type = "AoE" },
	},
	{
		Name = "Archer", HP = 100, BaseDamage = 1.3, BaseDefense = 0.8, BaseSpeed = 1.3,
		Ability = { Name = "Rain of Arrows", Damage = 25, Cooldown = 10, Type = "AoE" },
	},
	{
		Name = "Tank", HP = 250, BaseDamage = 0.8, BaseDefense = 1.8, BaseSpeed = 0.6,
		Ability = { Name = "Fortify", Duration = 5, Cooldown = 15, Type = "Shield" },
	},
}

-- ============================================================================
-- SOULS SHOP (permanent upgrades)
-- ============================================================================
GameConfig.SoulsShop = {
	{ Name = "Vitality I", Cost = 50, Effect = "max_hp", Amount = 10, MaxLevel = 20 },
	{ Name = "Vitality II", Cost = 200, Effect = "max_hp", Amount = 25, MaxLevel = 10 },
	{ Name = "Strength I", Cost = 50, Effect = "damage", Amount = 2, MaxLevel = 20 },
	{ Name = "Strength II", Cost = 200, Effect = "damage", Amount = 5, MaxLevel = 10 },
	{ Name = "Fortune I", Cost = 100, Effect = "loot_luck", Amount = 0.05, MaxLevel = 10 },
	{ Name = "Fortune II", Cost = 500, Effect = "loot_luck", Amount = 0.1, MaxLevel = 5 },
	{ Name = "Swift Feet", Cost = 150, Effect = "speed", Amount = 0.1, MaxLevel = 10 },
	{ Name = "Soul Magnet", Cost = 300, Effect = "soul_mult", Amount = 0.1, MaxLevel = 10 },
	{ Name = "Thick Skin", Cost = 100, Effect = "defense", Amount = 3, MaxLevel = 15 },
	{ Name = "Second Wind", Cost = 1000, Effect = "revive_chance", Amount = 0.1, MaxLevel = 3 },
}

-- ============================================================================
-- GAME PASSES
-- ============================================================================
GameConfig.GamePasses = {
	DoubleSouls = { Id = 0, Name = "2x Souls", Price = 299, Description = "Double souls from all sources" },
	ExtraLife = { Id = 0, Name = "Extra Life", Price = 199, Description = "Revive once per run" },
	VIPLobby = { Id = 0, Name = "VIP Lobby", Price = 149, Description = "Exclusive lobby, gold name" },
	ExclusiveClass = { Id = 0, Name = "Necromancer Class", Price = 399, Description = "Summon undead allies" },
}

GameConfig.DevProducts = {
	Revive = { Id = 0, Name = "Revive", Price = 49, Description = "Revive on the spot" },
	Souls500 = { Id = 0, Name = "500 Souls", Price = 99, Amount = 500 },
	Souls2500 = { Id = 0, Name = "2,500 Souls", Price = 199, Amount = 2500 },
	Souls10000 = { Id = 0, Name = "10,000 Souls", Price = 399, Amount = 10000 },
}

-- ============================================================================
-- DEFAULT DATA
-- ============================================================================
GameConfig.DefaultData = {
	Souls = 0,
	TotalSoulsEarned = 0,
	HighestFloor = 0,
	TotalRuns = 0,
	TotalKills = 0,
	BossesDefeated = 0,

	-- Permanent upgrades
	Upgrades = {},

	-- Current run (nil when not in dungeon)
	CurrentRun = nil,

	-- Class
	SelectedClass = "Warrior",
	UnlockedClasses = { "Warrior" },

	-- Game Passes
	GamePasses = {},

	-- Login
	LastLoginDate = "",
	LoginStreak = 0,
}

return GameConfig
