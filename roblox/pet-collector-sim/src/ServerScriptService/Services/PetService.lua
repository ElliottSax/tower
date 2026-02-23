--[[
	PetService.lua
	Pet Collector Simulator - Pet Management Service

	Handles:
	- Egg hatching with weighted rarity
	- Pet inventory management
	- Pet equipping/unequipping
	- Coin multiplier calculation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PetDefinitions = require(ReplicatedStorage.Shared.Data.PetDefinitions)

local PetService = {}
PetService.DataService = nil -- Lazy load to avoid circular dependency

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function PetService.Init()
	print("[PetService] Initializing...")

	-- Setup remote events
	PetService.SetupRemotes()

	print("[PetService] Initialized")
end

function PetService.SetupRemotes()
	-- CRITICAL FIX: Use SecureRemotes for rate limiting and validation
	local SecureRemotes = require(ServerScriptService.Security.SecureRemotes)
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Hatch egg (rate limited, validated egg types)
	local hatchEggRemote = SecureRemotes.CreateRemoteEvent("HatchEgg", {
		RateLimit = {
			MaxCalls = 20, -- Max 20 hatches per minute
			Window = 60
		},
		Schema = {"string"}, -- eggType must be string
		AllowedValues = {
			{Values = {"Basic", "Forest", "Crystal", "Fire", "VIP", "Legendary"}}
		}
	})
	hatchEggRemote.OnServerEvent:Connect(function(player, eggType)
		PetService.HatchEgg(player, eggType)
	end)

	-- Equip pet (rate limited)
	local equipPetRemote = SecureRemotes.CreateRemoteEvent("EquipPet", {
		RateLimit = {
			MaxCalls = 30, -- Max 30 equips per minute
			Window = 60
		},
		Schema = {"string", "number"} -- petId (string), slot (number)
	})
	equipPetRemote.OnServerEvent:Connect(function(player, petId, slot)
		PetService.EquipPet(player, petId, slot)
	end)

	-- Unequip pet (rate limited)
	local unequipPetRemote = SecureRemotes.CreateRemoteEvent("UnequipPet", {
		RateLimit = {
			MaxCalls = 30, -- Max 30 unequips per minute
			Window = 60
		},
		Schema = {"number"} -- slot (number)
	})
	unequipPetRemote.OnServerEvent:Connect(function(player, slot)
		PetService.UnequipPet(player, slot)
	end)

	-- Delete pet (rate limited to prevent accidental mass deletion)
	local deletePetRemote = SecureRemotes.CreateRemoteEvent("DeletePet", {
		RateLimit = {
			MaxCalls = 10, -- Max 10 deletions per minute
			Window = 60
		},
		Schema = {"string"} -- petInstanceId (string)
	})
	deletePetRemote.OnServerEvent:Connect(function(player, petInstanceId)
		PetService.DeletePet(player, petInstanceId)
	end)

	-- Get equipped pets (RemoteFunction - no rate limit needed for reads)
	local getEquippedPetsRemote = remoteEvents:WaitForChild("GetEquippedPets")
	getEquippedPetsRemote.OnServerInvoke = function(player)
		return PetService.GetEquippedPets(player)
	end
end

-- ============================================================================
-- EGG HATCHING
-- ============================================================================

function PetService.HatchEgg(player: Player, eggType: string)
	-- Get DataService
	if not PetService.DataService then
		PetService.DataService = require(ServerScriptService.Services.DataService)
	end

	-- Validate egg type
	local eggData = GameConfig.Eggs[eggType]
	if not eggData then
		warn(string.format("[PetService] Invalid egg type: %s", eggType))
		return nil
	end

	-- Check if player has VIP pass if required
	if eggData.RequiresVIP then
		local hasVIP = PetService.HasGamePass(player, GameConfig.GamePasses.VIP.Id)
		if not hasVIP then
			warn(string.format("[PetService] %s tried to hatch VIP egg without VIP", player.Name))
			return nil
		end
	end

	-- Check cost
	local playerData = PetService.DataService.GetData(player)
	if not playerData then
		warn(string.format("[PetService] No data for %s", player.Name))
		return nil
	end

	if playerData.Coins < eggData.Cost then
		warn(string.format("[PetService] %s cannot afford %s egg (has %d, needs %d)",
			player.Name, eggType, playerData.Coins, eggData.Cost))
		return nil
	end

	-- Check inventory space
	local maxSlots = GameConfig.Settings.MaxInventorySlots
	if PetService.HasGamePass(player, GameConfig.GamePasses.ExtraSlots.Id) then
		maxSlots = maxSlots + 10
	end

	if #playerData.Pets >= maxSlots then
		warn(string.format("[PetService] %s inventory full", player.Name))
		return nil
	end

	-- CRITICAL FIX: Deduct cost using RemoveCoins instead of AddCoins with negative value
	-- Prevents negative coin exploit
	if not PetService.DataService.RemoveCoins(player, eggData.Cost) then
		warn(string.format("[PetService] Failed to deduct %d coins from %s", eggData.Cost, player.Name))
		return nil
	end

	-- Roll for pet
	local pet = PetService.RollPet(eggData.PetPool, player)
	if not pet then
		warn(string.format("[PetService] Failed to roll pet from %s", eggData.PetPool))
		return nil
	end

	-- Add to inventory
	local petInstance = PetService.CreatePetInstance(pet)
	table.insert(playerData.Pets, petInstance)

	-- Update stats
	playerData.Stats.TotalEggsHatched = (playerData.Stats.TotalEggsHatched or 0) + 1

	print(string.format("[PetService] %s hatched %s (%s) from %s egg",
		player.Name, pet.Name, pet.Rarity, eggType))

	-- Notify client
	local notifyRemote = remoteEvents:FindFirstChild("ShowNotification")
	if notifyRemote then
		notifyRemote:FireClient(player, string.format("Hatched %s!", pet.Name), "Success")
	end

	return petInstance
end

function PetService.RollPet(petPool: string, player: Player)
	-- Get pet pool
	local pets = PetDefinitions[petPool]
	if not pets or #pets == 0 then
		warn(string.format("[PetService] Invalid pet pool: %s", petPool))
		return nil
	end

	-- Check for luck boosts
	local luckMultiplier = 1
	if PetService.HasGamePass(player, GameConfig.GamePasses.LuckyBoost.Id) then
		luckMultiplier = 3 -- 3x chance for better pets
	end

	-- Build weighted list
	local weightedList = {}
	for _, pet in ipairs(pets) do
		local rarity = GameConfig.Rarities[pet.Rarity]
		if rarity then
			local weight = rarity.Weight

			-- Apply luck boost to rare+ pets
			if pet.Rarity == "Legendary" or pet.Rarity == "Mythic" then
				weight = weight * luckMultiplier
			elseif pet.Rarity == "Epic" then
				weight = weight * (luckMultiplier * 0.5)
			end

			table.insert(weightedList, {
				Pet = pet,
				Weight = weight,
			})
		end
	end

	-- Roll
	local totalWeight = 0
	for _, entry in ipairs(weightedList) do
		totalWeight = totalWeight + entry.Weight
	end

	local roll = math.random() * totalWeight
	local currentWeight = 0

	for _, entry in ipairs(weightedList) do
		currentWeight = currentWeight + entry.Weight
		if roll <= currentWeight then
			return entry.Pet
		end
	end

	-- Fallback to first pet
	return pets[1]
end

function PetService.CreatePetInstance(petDefinition)
	return {
		Id = petDefinition.Id,
		InstanceId = game:GetService("HttpService"):GenerateGUID(false),
		Name = petDefinition.Name,
		Rarity = petDefinition.Rarity,
		CoinMultiplier = petDefinition.CoinMultiplier,
		HatchedAt = os.time(),
	}
end

-- ============================================================================
-- PET EQUIPPING
-- ============================================================================

function PetService.EquipPet(player: Player, petInstanceId: string, slot: number)
	if not PetService.DataService then
		PetService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = PetService.DataService.GetData(player)
	if not playerData then return false end

	-- Validate slot
	local maxSlots = GameConfig.Settings.MaxEquippedPets
	if PetService.HasGamePass(player, GameConfig.GamePasses.ExtraSlots.Id) then
		maxSlots = 3
	end

	if slot < 1 or slot > maxSlots then
		warn(string.format("[PetService] Invalid slot %d", slot))
		return false
	end

	-- Find pet
	local pet = nil
	for _, p in ipairs(playerData.Pets) do
		if p.InstanceId == petInstanceId then
			pet = p
			break
		end
	end

	if not pet then
		warn(string.format("[PetService] Pet not found: %s", petInstanceId))
		return false
	end

	-- Equip
	if not playerData.EquippedPets then
		playerData.EquippedPets = {}
	end

	playerData.EquippedPets[slot] = petInstanceId

	print(string.format("[PetService] %s equipped %s in slot %d", player.Name, pet.Name, slot))

	return true
end

function PetService.UnequipPet(player: Player, slot: number)
	if not PetService.DataService then
		PetService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = PetService.DataService.GetData(player)
	if not playerData then return false end

	if playerData.EquippedPets and playerData.EquippedPets[slot] then
		playerData.EquippedPets[slot] = nil
		print(string.format("[PetService] %s unequipped slot %d", player.Name, slot))
		return true
	end

	return false
end

function PetService.GetEquippedPets(player: Player)
	if not PetService.DataService then
		PetService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = PetService.DataService.GetData(player)
	if not playerData then return {} end

	local equipped = {}
	if playerData.EquippedPets then
		for slot, petInstanceId in pairs(playerData.EquippedPets) do
			-- Find pet
			for _, pet in ipairs(playerData.Pets) do
				if pet.InstanceId == petInstanceId then
					equipped[slot] = pet
					break
				end
			end
		end
	end

	return equipped
end

-- ============================================================================
-- PET MANAGEMENT
-- ============================================================================

function PetService.DeletePet(player: Player, petInstanceId: string)
	if not PetService.DataService then
		PetService.DataService = require(ServerScriptService.Services.DataService)
	end

	local playerData = PetService.DataService.GetData(player)
	if not playerData then return false end

	-- Find and remove pet
	for i, pet in ipairs(playerData.Pets) do
		if pet.InstanceId == petInstanceId then
			table.remove(playerData.Pets, i)
			print(string.format("[PetService] %s deleted %s", player.Name, pet.Name))
			return true
		end
	end

	return false
end

function PetService.GetTotalCoinMultiplier(player: Player)
	local equipped = PetService.GetEquippedPets(player)
	local total = 0

	for _, pet in pairs(equipped) do
		total = total + pet.CoinMultiplier
	end

	-- VIP bonus
	if PetService.HasGamePass(player, GameConfig.GamePasses.VIP.Id) then
		total = total * 2
	end

	return math.max(total, 1) -- Minimum 1x
end

-- ============================================================================
-- GAME PASS HELPERS
-- ============================================================================

function PetService.HasGamePass(player: Player, gamePassId: number)
	if gamePassId == 0 then return false end -- Not configured yet

	local MarketplaceService = game:GetService("MarketplaceService")
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)

	return success and hasPass
end

return PetService
