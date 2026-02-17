--[[
	PetService.lua - Anime Training Simulator
	Egg hatching, pet collection, equip/unequip, fusing
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PetService = {}
PetService.DataService = nil

function PetService.Init()
	print("[PetService] Initializing...")

	PetService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("HatchEgg").OnServerEvent:Connect(function(player, eggName)
		PetService.HatchEgg(player, eggName)
	end)

	remoteEvents:WaitForChild("EquipPet").OnServerEvent:Connect(function(player, petId)
		PetService.EquipPet(player, petId)
	end)

	remoteEvents:WaitForChild("UnequipPet").OnServerEvent:Connect(function(player, petId)
		PetService.UnequipPet(player, petId)
	end)

	remoteEvents:WaitForChild("FusePets").OnServerEvent:Connect(function(player, petId1, petId2, petId3)
		PetService.FusePets(player, petId1, petId2, petId3)
	end)

	remoteEvents:WaitForChild("DeletePet").OnServerEvent:Connect(function(player, petId)
		PetService.DeletePet(player, petId)
	end)

	print("[PetService] Initialized")
end

function PetService.HatchEgg(player, eggName)
	local SecurityManager = require(ServerScriptService.Security.SecurityManager)
	if not SecurityManager.CheckRateLimit(player, "HatchEgg") then return end

	if type(eggName) ~= "string" then return end

	local data = PetService.DataService.GetFullData(player)
	if not data then return end

	-- Find egg config
	local eggConfig = nil
	for _, egg in ipairs(GameConfig.Eggs) do
		if egg.Name == eggName then
			eggConfig = egg
			break
		end
	end
	if not eggConfig then return end

	-- Check cost
	if not PetService.DataService.SpendCoins(player, eggConfig.Cost) then
		return
	end

	-- Roll rarity based on weights
	local luckMult = 1
	if data.GamePasses and data.GamePasses.DoublePets then
		luckMult = 2
	end
	if data._LuckExpiry and os.time() < data._LuckExpiry then
		luckMult = luckMult * 2
	end

	local rarity = PetService.RollRarity(eggConfig.Weights, luckMult)

	-- Pick random pet of that rarity from this egg
	local validPets = {}
	for _, pet in ipairs(GameConfig.Pets) do
		if pet.Rarity == rarity and pet.Egg == eggName then
			table.insert(validPets, pet)
		end
	end

	-- Fallback: any pet of that rarity
	if #validPets == 0 then
		for _, pet in ipairs(GameConfig.Pets) do
			if pet.Rarity == rarity then
				table.insert(validPets, pet)
			end
		end
	end

	if #validPets == 0 then return end

	local chosenPet = validPets[math.random(#validPets)]

	-- Create pet instance
	local petId = HttpService:GenerateGUID(false)
	data.Pets[petId] = {
		Name = chosenPet.Name,
		Rarity = chosenPet.Rarity,
		Boost = chosenPet.Boost,
		Level = 1,
		CreatedAt = os.time(),
	}

	data.TotalEggsHatched = data.TotalEggsHatched + 1

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local hatchResult = remoteEvents:FindFirstChild("HatchResult")
		if hatchResult then
			hatchResult:FireClient(player, {
				PetId = petId,
				Name = chosenPet.Name,
				Rarity = chosenPet.Rarity,
				Boost = chosenPet.Boost,
			})
		end
	end

	-- Quest progress
	local QuestService = require(ServerScriptService.Services.QuestService)
	QuestService.UpdateProgress(player, "Hatch", nil, 1)

	print("[PetService]", player.Name, "hatched", chosenPet.Name, "(", chosenPet.Rarity, ")")
end

function PetService.RollRarity(weights, luckMult)
	-- Apply luck to rare+ tiers
	local adjustedWeights = {}
	local totalWeight = 0

	for rarity, weight in pairs(weights) do
		local adjusted = weight
		if rarity ~= "Common" and rarity ~= "Uncommon" then
			adjusted = weight * luckMult
		end
		adjustedWeights[rarity] = adjusted
		totalWeight = totalWeight + adjusted
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	-- Roll from rarest to most common
	local order = { "Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
	for _, rarity in ipairs(order) do
		cumulative = cumulative + (adjustedWeights[rarity] or 0)
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common"
end

function PetService.EquipPet(player, petId)
	if type(petId) ~= "string" then return end

	local data = PetService.DataService.GetFullData(player)
	if not data or not data.Pets[petId] then return end

	local maxEquipped = data.MaxEquipped or 3
	if data.GamePasses and data.GamePasses.ExtraEquip then
		maxEquipped = maxEquipped + 3
	end

	-- Check if already equipped
	for _, id in ipairs(data.EquippedPets) do
		if id == petId then return end
	end

	if #data.EquippedPets >= maxEquipped then
		-- Remove first equipped pet
		table.remove(data.EquippedPets, 1)
	end

	table.insert(data.EquippedPets, petId)

	-- Sync to client
	PetService.SyncPets(player)
end

function PetService.UnequipPet(player, petId)
	if type(petId) ~= "string" then return end

	local data = PetService.DataService.GetFullData(player)
	if not data then return end

	for i, id in ipairs(data.EquippedPets) do
		if id == petId then
			table.remove(data.EquippedPets, i)
			break
		end
	end

	PetService.SyncPets(player)
end

function PetService.DeletePet(player, petId)
	if type(petId) ~= "string" then return end

	local data = PetService.DataService.GetFullData(player)
	if not data or not data.Pets[petId] then return end

	-- Remove from equipped if needed
	PetService.UnequipPet(player, petId)

	-- Delete
	data.Pets[petId] = nil
	PetService.SyncPets(player)
end

function PetService.FusePets(player, petId1, petId2, petId3)
	if type(petId1) ~= "string" or type(petId2) ~= "string" or type(petId3) ~= "string" then return end

	local data = PetService.DataService.GetFullData(player)
	if not data then return end

	local pet1 = data.Pets[petId1]
	local pet2 = data.Pets[petId2]
	local pet3 = data.Pets[petId3]

	if not pet1 or not pet2 or not pet3 then return end

	-- All three must be the same rarity
	if pet1.Rarity ~= pet2.Rarity or pet2.Rarity ~= pet3.Rarity then return end

	-- Determine upgraded rarity
	local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
	local currentIndex = 0
	for i, r in ipairs(rarityOrder) do
		if r == pet1.Rarity then
			currentIndex = i
			break
		end
	end

	if currentIndex >= #rarityOrder then return end -- Can't fuse Mythicals

	local newRarity = rarityOrder[currentIndex + 1]

	-- Find a pet of the new rarity
	local validPets = {}
	for _, petConfig in ipairs(GameConfig.Pets) do
		if petConfig.Rarity == newRarity then
			table.insert(validPets, petConfig)
		end
	end

	if #validPets == 0 then return end

	local newPetConfig = validPets[math.random(#validPets)]

	-- Remove old pets
	for _, id in ipairs({ petId1, petId2, petId3 }) do
		PetService.UnequipPet(player, id)
		data.Pets[id] = nil
	end

	-- Create new pet
	local newId = HttpService:GenerateGUID(false)
	data.Pets[newId] = {
		Name = newPetConfig.Name,
		Rarity = newPetConfig.Rarity,
		Boost = newPetConfig.Boost,
		Level = 1,
		CreatedAt = os.time(),
		Fused = true,
	}

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local fuseResult = remoteEvents:FindFirstChild("FuseResult")
		if fuseResult then
			fuseResult:FireClient(player, {
				PetId = newId,
				Name = newPetConfig.Name,
				Rarity = newPetConfig.Rarity,
				Boost = newPetConfig.Boost,
			})
		end
	end

	PetService.SyncPets(player)
	print("[PetService]", player.Name, "fused 3", pet1.Rarity, "pets into", newPetConfig.Name, "(", newPetConfig.Rarity, ")")
end

function PetService.SyncPets(player)
	local data = PetService.DataService.GetFullData(player)
	if not data then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local petSync = remoteEvents:FindFirstChild("PetSync")
		if petSync then
			petSync:FireClient(player, {
				Pets = data.Pets,
				EquippedPets = data.EquippedPets,
			})
		end
	end
end

return PetService
