--[[
	PetDefinitions.lua
	Pet Collector Simulator - Pet Database

	Defines all pets with stats, rarity, and unlock conditions
]]

local PetDefinitions = {}

-- ============================================================================
-- BASIC PETS (Starter Island)
-- ============================================================================

PetDefinitions.Basic = {
	-- Common Pets (60%)
	{
		Id = "dog_basic",
		Name = "Doggo",
		Rarity = "Common",
		CoinMultiplier = 1,
		Model = "rbxassetid://0",
		Description = "A loyal companion",
	},
	{
		Id = "cat_basic",
		Name = "Kitty",
		Rarity = "Common",
		CoinMultiplier = 1,
		Model = "rbxassetid://0",
		Description = "Purrs for coins",
	},
	{
		Id = "bunny_basic",
		Name = "Bunny",
		Rarity = "Common",
		CoinMultiplier = 1,
		Model = "rbxassetid://0",
		Description = "Hops around happily",
	},

	-- Uncommon Pets (25%)
	{
		Id = "dog_golden",
		Name = "Golden Doggo",
		Rarity = "Uncommon",
		CoinMultiplier = 1.5,
		Model = "rbxassetid://0",
		Description = "Shiny golden fur",
	},
	{
		Id = "cat_tuxedo",
		Name = "Tuxedo Cat",
		Rarity = "Uncommon",
		CoinMultiplier = 1.5,
		Model = "rbxassetid://0",
		Description = "Dressed for success",
	},

	-- Rare Pets (10%)
	{
		Id = "dragon_baby",
		Name = "Baby Dragon",
		Rarity = "Rare",
		CoinMultiplier = 2,
		Model = "rbxassetid://0",
		Description = "A tiny fire-breather",
	},

	-- Epic Pets (4%)
	{
		Id = "unicorn_rainbow",
		Name = "Rainbow Unicorn",
		Rarity = "Epic",
		CoinMultiplier = 3,
		Model = "rbxassetid://0",
		Description = "Magical rainbow trail",
	},

	-- Legendary Pets (0.9%)
	{
		Id = "phoenix_basic",
		Name = "Phoenix",
		Rarity = "Legendary",
		CoinMultiplier = 5,
		Model = "rbxassetid://0",
		Description = "Reborn from flames",
	},

	-- Mythic Pets (0.1%)
	{
		Id = "celestial_wolf",
		Name = "Celestial Wolf",
		Rarity = "Mythic",
		CoinMultiplier = 10,
		Model = "rbxassetid://0",
		Description = "Guardian of the stars",
	},
}

-- ============================================================================
-- FOREST PETS (Mystic Forest)
-- ============================================================================

PetDefinitions.Forest = {
	-- Common
	{
		Id = "deer_forest",
		Name = "Forest Deer",
		Rarity = "Common",
		CoinMultiplier = 1.2,
		Model = "rbxassetid://0",
		Description = "Gentle forest dweller",
	},
	{
		Id = "fox_red",
		Name = "Red Fox",
		Rarity = "Common",
		CoinMultiplier = 1.2,
		Model = "rbxassetid://0",
		Description = "Cunning and quick",
	},
	{
		Id = "owl_brown",
		Name = "Brown Owl",
		Rarity = "Common",
		CoinMultiplier = 1.2,
		Model = "rbxassetid://0",
		Description = "Wise night watcher",
	},

	-- Uncommon
	{
		Id = "wolf_grey",
		Name = "Grey Wolf",
		Rarity = "Uncommon",
		CoinMultiplier = 1.8,
		Model = "rbxassetid://0",
		Description = "Alpha of the pack",
	},
	{
		Id = "bear_grizzly",
		Name = "Grizzly Bear",
		Rarity = "Uncommon",
		CoinMultiplier = 1.8,
		Model = "rbxassetid://0",
		Description = "Strong and fearless",
	},

	-- Rare
	{
		Id = "stag_golden",
		Name = "Golden Stag",
		Rarity = "Rare",
		CoinMultiplier = 2.5,
		Model = "rbxassetid://0",
		Description = "Majestic antlers shine",
	},
	{
		Id = "fox_spirit",
		Name = "Spirit Fox",
		Rarity = "Rare",
		CoinMultiplier = 2.5,
		Model = "rbxassetid://0",
		Description = "Ethereal blue glow",
	},

	-- Epic
	{
		Id = "treant_ancient",
		Name = "Ancient Treant",
		Rarity = "Epic",
		CoinMultiplier = 3.5,
		Model = "rbxassetid://0",
		Description = "Living tree guardian",
	},

	-- Legendary
	{
		Id = "phoenix_forest",
		Name = "Forest Phoenix",
		Rarity = "Legendary",
		CoinMultiplier = 6,
		Model = "rbxassetid://0",
		Description = "Green flames of nature",
	},

	-- Mythic
	{
		Id = "dragon_nature",
		Name = "Nature Dragon",
		Rarity = "Mythic",
		CoinMultiplier = 12,
		Model = "rbxassetid://0",
		Description = "Controls all plant life",
	},
}

-- ============================================================================
-- CRYSTAL PETS (Crystal Caves)
-- ============================================================================

PetDefinitions.Crystal = {
	-- Common
	{
		Id = "bat_crystal",
		Name = "Crystal Bat",
		Rarity = "Common",
		CoinMultiplier = 1.5,
		Model = "rbxassetid://0",
		Description = "Glowing cave dweller",
	},
	{
		Id = "spider_gem",
		Name = "Gem Spider",
		Rarity = "Common",
		CoinMultiplier = 1.5,
		Model = "rbxassetid://0",
		Description = "Webs of crystal",
	},

	-- Uncommon
	{
		Id = "snake_sapphire",
		Name = "Sapphire Snake",
		Rarity = "Uncommon",
		CoinMultiplier = 2.2,
		Model = "rbxassetid://0",
		Description = "Blue scales shimmer",
	},
	{
		Id = "golem_crystal",
		Name = "Crystal Golem",
		Rarity = "Uncommon",
		CoinMultiplier = 2.2,
		Model = "rbxassetid://0",
		Description = "Living crystal formation",
	},

	-- Rare
	{
		Id = "dragon_amethyst",
		Name = "Amethyst Dragon",
		Rarity = "Rare",
		CoinMultiplier = 3,
		Model = "rbxassetid://0",
		Description = "Purple crystal wings",
	},

	-- Epic
	{
		Id = "phoenix_diamond",
		Name = "Diamond Phoenix",
		Rarity = "Epic",
		CoinMultiplier = 4,
		Model = "rbxassetid://0",
		Description = "Priceless beauty",
	},

	-- Legendary
	{
		Id = "leviathan_crystal",
		Name = "Crystal Leviathan",
		Rarity = "Legendary",
		CoinMultiplier = 7,
		Model = "rbxassetid://0",
		Description = "Ancient cave guardian",
	},

	-- Mythic
	{
		Id = "titan_prism",
		Name = "Prism Titan",
		Rarity = "Mythic",
		CoinMultiplier = 15,
		Model = "rbxassetid://0",
		Description = "Bends light itself",
	},
}

-- ============================================================================
-- FIRE PETS (Volcano Peak)
-- ============================================================================

PetDefinitions.Fire = {
	-- Common
	{
		Id = "salamander_fire",
		Name = "Fire Salamander",
		Rarity = "Common",
		CoinMultiplier = 2,
		Model = "rbxassetid://0",
		Description = "Loves the heat",
	},

	-- Uncommon
	{
		Id = "wolf_lava",
		Name = "Lava Wolf",
		Rarity = "Uncommon",
		CoinMultiplier = 2.5,
		Model = "rbxassetid://0",
		Description = "Molten fur burns bright",
	},

	-- Rare
	{
		Id = "drake_inferno",
		Name = "Inferno Drake",
		Rarity = "Rare",
		CoinMultiplier = 3.5,
		Model = "rbxassetid://0",
		Description = "Breathes devastating flames",
	},

	-- Epic
	{
		Id = "phoenix_volcanic",
		Name = "Volcanic Phoenix",
		Rarity = "Epic",
		CoinMultiplier = 5,
		Model = "rbxassetid://0",
		Description = "Born from volcano",
	},

	-- Legendary
	{
		Id = "dragon_magma",
		Name = "Magma Dragon",
		Rarity = "Legendary",
		CoinMultiplier = 8,
		Model = "rbxassetid://0",
		Description = "Lava flows from scales",
	},

	-- Mythic
	{
		Id = "emperor_inferno",
		Name = "Inferno Emperor",
		Rarity = "Mythic",
		CoinMultiplier = 20,
		Model = "rbxassetid://0",
		Description = "Rules all fire",
	},
}

-- ============================================================================
-- VIP PETS (VIP Paradise - Exclusive)
-- ============================================================================

PetDefinitions.VIP = {
	-- All VIP pets are at least Rare
	{
		Id = "lion_golden",
		Name = "Golden Lion",
		Rarity = "Rare",
		CoinMultiplier = 4,
		Model = "rbxassetid://0",
		Description = "VIP Exclusive - Majestic king",
		RequiresVIP = true,
	},
	{
		Id = "tiger_platinum",
		Name = "Platinum Tiger",
		Rarity = "Epic",
		CoinMultiplier = 5,
		Model = "rbxassetid://0",
		Description = "VIP Exclusive - Silver stripes",
		RequiresVIP = true,
	},
	{
		Id = "dragon_rainbow",
		Name = "Rainbow Dragon",
		Rarity = "Legendary",
		CoinMultiplier = 10,
		Model = "rbxassetid://0",
		Description = "VIP Exclusive - All colors",
		RequiresVIP = true,
	},
	{
		Id = "angel_celestial",
		Name = "Celestial Angel",
		Rarity = "Mythic",
		CoinMultiplier = 25,
		Model = "rbxassetid://0",
		Description = "VIP Exclusive - Divine being",
		RequiresVIP = true,
	},
}

-- ============================================================================
-- LEGENDARY POOL (Legendary Egg Only)
-- ============================================================================

PetDefinitions.Legendary = {
	-- Guaranteed Legendary or higher
	{
		Id = "hydra_three_head",
		Name = "Three-Headed Hydra",
		Rarity = "Legendary",
		CoinMultiplier = 9,
		Model = "rbxassetid://0",
		Description = "Triple the power",
	},
	{
		Id = "kraken_deep",
		Name = "Deep Kraken",
		Rarity = "Legendary",
		CoinMultiplier = 9,
		Model = "rbxassetid://0",
		Description = "Terror of the depths",
	},
	{
		Id = "griffin_royal",
		Name = "Royal Griffin",
		Rarity = "Legendary",
		CoinMultiplier = 9,
		Model = "rbxassetid://0",
		Description = "Noble and fierce",
	},
	{
		Id = "demon_shadow",
		Name = "Shadow Demon",
		Rarity = "Mythic",
		CoinMultiplier = 18,
		Model = "rbxassetid://0",
		Description = "Darkness incarnate",
	},
	{
		Id = "god_ancient",
		Name = "Ancient God",
		Rarity = "Mythic",
		CoinMultiplier = 30,
		Model = "rbxassetid://0",
		Description = "Ultimate power",
	},
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function PetDefinitions.GetPetById(petId: string)
	for poolName, pets in pairs(PetDefinitions) do
		if typeof(pets) == "table" and #pets > 0 then
			for _, pet in ipairs(pets) do
				if pet.Id == petId then
					return pet
				end
			end
		end
	end
	return nil
end

function PetDefinitions.GetPetsByRarity(rarity: string)
	local result = {}
	for poolName, pets in pairs(PetDefinitions) do
		if typeof(pets) == "table" and #pets > 0 then
			for _, pet in ipairs(pets) do
				if pet.Rarity == rarity then
					table.insert(result, pet)
				end
			end
		end
	end
	return result
end

function PetDefinitions.GetAllPets()
	local result = {}
	for poolName, pets in pairs(PetDefinitions) do
		if typeof(pets) == "table" and #pets > 0 then
			for _, pet in ipairs(pets) do
				table.insert(result, pet)
			end
		end
	end
	return result
end

return PetDefinitions
