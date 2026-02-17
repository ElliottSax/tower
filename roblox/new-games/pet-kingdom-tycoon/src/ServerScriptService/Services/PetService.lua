--[[
	PetService.lua - Pet Kingdom Tycoon
	Egg hatching, pet management, evolution, coin generation
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

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("HatchEgg").OnServerEvent:Connect(function(player, eggName)
		PetService.HatchEgg(player, eggName)
	end)

	re:WaitForChild("FeedPet").OnServerEvent:Connect(function(player, petId)
		PetService.FeedPet(player, petId)
	end)

	re:WaitForChild("EvolvePet").OnServerEvent:Connect(function(player, petId)
		PetService.EvolvePet(player, petId)
	end)

	re:WaitForChild("ReleasePet").OnServerEvent:Connect(function(player, petId)
		PetService.ReleasePet(player, petId)
	end)

	re:WaitForChild("GetPets").OnServerEvent:Connect(function(player)
		PetService.SyncPets(player)
	end)

	print("[PetService] Initialized")
end

function PetService.HatchEgg(player, eggName)
	if type(eggName) ~= "string" then return end
	local data = PetService.DataService.GetFullData(player)
	if not data then return end

	-- Find egg config
	local eggConfig = nil
	for _, egg in ipairs(GameConfig.Eggs) do
		if egg.Name == eggName then eggConfig = egg; break end
	end
	if not eggConfig then return end

	-- Check world unlocked
	local worldUnlocked = false
	for _, w in ipairs(data.UnlockedWorlds) do
		if w == eggConfig.World then worldUnlocked = true; break end
	end
	if not worldUnlocked then return end

	-- Check capacity
	local petCount = 0
	for _ in pairs(data.Pets) do petCount = petCount + 1 end
	local maxPets = data.MaxPets
	if data.GamePasses and data.GamePasses.MegaStorage then maxPets = maxPets * 2 end
	if petCount >= maxPets then return end

	-- Check cost
	if not PetService.DataService.SpendCoins(player, eggConfig.Cost) then return end

	-- Roll rarity
	local luckMult = 1
	if data.GamePasses and data.GamePasses.DoublePets then luckMult = 2 end

	local rarity = PetService.RollRarity(eggConfig.Weights, luckMult)

	-- Pick random pet of that rarity from this world
	local validPets = {}
	for _, pet in ipairs(GameConfig.Pets) do
		if pet.Rarity == rarity and pet.World == eggConfig.World then
			table.insert(validPets, pet)
		end
	end
	if #validPets == 0 then
		for _, pet in ipairs(GameConfig.Pets) do
			if pet.Rarity == rarity then table.insert(validPets, pet) end
		end
	end
	if #validPets == 0 then return end

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
	}
	data.TotalEggsHatched = data.TotalEggsHatched + 1

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local hr = re:FindFirstChild("HatchResult")
		if hr then hr:FireClient(player, { PetId = petId, Pet = data.Pets[petId] }) end
	end

	PetService.SyncPets(player)
end

function PetService.RollRarity(weights, luckMult)
	local adjusted = {}
	local total = 0
	for rarity, weight in pairs(weights) do
		local adj = weight
		if rarity ~= "Common" and rarity ~= "Uncommon" then adj = weight * luckMult end
		adjusted[rarity] = adj
		total = total + adj
	end

	local roll = math.random() * total
	local cum = 0
	for _, rarity in ipairs({"Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}) do
		cum = cum + (adjusted[rarity] or 0)
		if roll <= cum then return rarity end
	end
	return "Common"
end

function PetService.FeedPet(player, petId)
	if type(petId) ~= "string" then return end
	local data = PetService.DataService.GetFullData(player)
	if not data or not data.Pets[petId] then return end

	local feedCost = GameConfig.Evolution.FeedCost
	if not PetService.DataService.SpendCoins(player, feedCost) then return end

	local pet = data.Pets[petId]
	if pet.Level >= GameConfig.Evolution.MaxLevel then return end

	pet.XP = pet.XP + GameConfig.Evolution.XPPerFeed

	-- Level up check
	local xpNeeded = pet.Level * 15
	while pet.XP >= xpNeeded and pet.Level < GameConfig.Evolution.MaxLevel do
		pet.XP = pet.XP - xpNeeded
		pet.Level = pet.Level + 1
		xpNeeded = pet.Level * 15
	end

	PetService.SyncPets(player)
end

function PetService.EvolvePet(player, petId)
	if type(petId) ~= "string" then return end
	local data = PetService.DataService.GetFullData(player)
	if not data or not data.Pets[petId] then return end

	local pet = data.Pets[petId]
	if pet.Stage >= 3 then return end

	local requiredLevel = GameConfig.Evolution.EvolutionLevels[pet.Stage + 1]
	if not requiredLevel or pet.Level < requiredLevel then return end

	pet.Stage = pet.Stage + 1
	pet.CoinGen = pet.CoinGen * GameConfig.Evolution.StatMultipliers[pet.Stage]

	if pet.Evolutions and pet.Evolutions[pet.Stage] then
		pet.Name = pet.Evolutions[pet.Stage]
	end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local er = re:FindFirstChild("EvolveResult")
		if er then er:FireClient(player, { PetId = petId, NewStage = pet.Stage, NewName = pet.Name }) end
	end

	PetService.SyncPets(player)
end

function PetService.ReleasePet(player, petId)
	if type(petId) ~= "string" then return end
	local data = PetService.DataService.GetFullData(player)
	if not data or not data.Pets[petId] then return end
	data.Pets[petId] = nil
	PetService.SyncPets(player)
end

function PetService.StartCoinGeneration(player)
	task.spawn(function()
		while player.Parent do
			task.wait(5)
			local data = PetService.DataService.GetFullData(player)
			if data then
				local totalGen = 0
				for _, pet in pairs(data.Pets) do
					totalGen = totalGen + (pet.CoinGen or 0)
				end
				if totalGen > 0 then
					PetService.DataService.AddCoins(player, math.floor(totalGen))
				end
			end
		end
	end)
end

function PetService.SyncPets(player)
	local data = PetService.DataService.GetFullData(player)
	if not data then return end
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local ps = re:FindFirstChild("PetSync")
		if ps then ps:FireClient(player, data.Pets) end
	end
end

return PetService
