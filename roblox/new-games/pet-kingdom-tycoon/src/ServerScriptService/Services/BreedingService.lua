--[[
	BreedingService.lua - Pet Kingdom Tycoon
	Pet breeding with timers, special combinations, and rarity upgrades
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local BreedingService = {}
BreedingService.DataService = nil

function BreedingService.Init()
	print("[BreedingService] Initializing...")
	BreedingService.DataService = require(ServerScriptService.Services.DataService)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("StartBreeding").OnServerEvent:Connect(function(player, petId1, petId2)
		BreedingService.StartBreeding(player, petId1, petId2)
	end)

	re:WaitForChild("CollectBreeding").OnServerEvent:Connect(function(player)
		BreedingService.CollectBreeding(player)
	end)

	re:WaitForChild("GetBreedingStatus").OnServerEvent:Connect(function(player)
		BreedingService.SendStatus(player)
	end)

	print("[BreedingService] Initialized")
end

function BreedingService.StartBreeding(player, petId1, petId2)
	if type(petId1) ~= "string" or type(petId2) ~= "string" then return end
	if petId1 == petId2 then return end

	local data = BreedingService.DataService.GetFullData(player)
	if not data then return end
	if data.ActiveBreeding then return end -- Already breeding

	local pet1 = data.Pets[petId1]
	local pet2 = data.Pets[petId2]
	if not pet1 or not pet2 then return end

	local duration = GameConfig.Breeding.BaseDuration
	if data.GamePasses and data.GamePasses.InstantBreed then
		duration = 0
	end

	-- Check for structure bonuses
	for _, struct in ipairs(data.Structures or {}) do
		if struct.Name == "Breeding Center" then
			duration = math.floor(duration / 1.5)
		end
	end

	data.ActiveBreeding = {
		PetId1 = petId1,
		PetId2 = petId2,
		Pet1Name = pet1.Name,
		Pet2Name = pet2.Name,
		Pet1Rarity = pet1.Rarity,
		Pet2Rarity = pet2.Rarity,
		StartTime = os.time(),
		Duration = duration,
	}

	BreedingService.SendStatus(player)
end

function BreedingService.CollectBreeding(player)
	local data = BreedingService.DataService.GetFullData(player)
	if not data or not data.ActiveBreeding then return end

	local breeding = data.ActiveBreeding
	if os.time() - breeding.StartTime < breeding.Duration then return end

	-- Determine offspring rarity
	local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
	local resultRarity = breeding.Pet1Rarity -- Default to parent1 rarity

	-- Check special combinations
	for _, combo in ipairs(GameConfig.Breeding.SpecialCombinations) do
		if (breeding.Pet1Rarity == combo.Parent1Rarity and breeding.Pet2Rarity == combo.Parent2Rarity)
			or (breeding.Pet1Rarity == combo.Parent2Rarity and breeding.Pet2Rarity == combo.Parent1Rarity) then
			if math.random() < combo.Chance then
				resultRarity = combo.ResultRarity
			end
			break
		end
	end

	-- Pick a pet of that rarity
	local validPets = {}
	for _, pet in ipairs(GameConfig.Pets) do
		if pet.Rarity == resultRarity then table.insert(validPets, pet) end
	end
	if #validPets == 0 then data.ActiveBreeding = nil; return end

	local chosen = validPets[math.random(#validPets)]
	local petId = HttpService:GenerateGUID(false)

	data.Pets[petId] = {
		Name = chosen.Name,
		Rarity = chosen.Rarity,
		World = chosen.World,
		CoinGen = chosen.CoinGen,
		Level = 1,
		XP = 0,
		Stage = 1,
		Evolutions = chosen.Evolutions,
		CreatedAt = os.time(),
		Bred = true,
	}

	data.ActiveBreeding = nil

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local br = re:FindFirstChild("BreedingResult")
		if br then br:FireClient(player, { PetId = petId, Pet = data.Pets[petId] }) end
	end

	local PetService = require(ServerScriptService.Services.PetService)
	PetService.SyncPets(player)
end

function BreedingService.SendStatus(player)
	local data = BreedingService.DataService.GetFullData(player)
	if not data then return end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local bs = re:FindFirstChild("BreedingStatus")
		if bs then bs:FireClient(player, data.ActiveBreeding) end
	end
end

return BreedingService
