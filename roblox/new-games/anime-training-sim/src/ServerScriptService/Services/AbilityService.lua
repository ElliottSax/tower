--[[
	AbilityService.lua - Anime Training Simulator
	Unlock and equip combat abilities
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AbilityService = {}
AbilityService.DataService = nil

function AbilityService.Init()
	print("[AbilityService] Initializing...")

	AbilityService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("BuyAbility").OnServerEvent:Connect(function(player, abilityName)
		AbilityService.BuyAbility(player, abilityName)
	end)

	remoteEvents:WaitForChild("EquipAbility").OnServerEvent:Connect(function(player, abilityName, slot)
		AbilityService.EquipAbility(player, abilityName, slot)
	end)

	remoteEvents:WaitForChild("GetAbilities").OnServerEvent:Connect(function(player)
		AbilityService.SendAbilityList(player)
	end)

	print("[AbilityService] Initialized")
end

function AbilityService.BuyAbility(player, abilityName)
	if type(abilityName) ~= "string" then return end

	local data = AbilityService.DataService.GetFullData(player)
	if not data then return end

	-- Find ability
	local abilityConfig = nil
	for _, ab in ipairs(GameConfig.Abilities) do
		if ab.Name == abilityName then
			abilityConfig = ab
			break
		end
	end
	if not abilityConfig then return end

	-- Check if already owned
	for _, owned in ipairs(data.UnlockedAbilities) do
		if owned == abilityName then return end
	end

	-- Check stat requirements
	if abilityConfig.RequiredStrength and (data.Strength or 0) < abilityConfig.RequiredStrength then return end
	if abilityConfig.RequiredDefense and (data.Defense or 0) < abilityConfig.RequiredDefense then return end
	if abilityConfig.RequiredSpeed and (data.Speed or 0) < abilityConfig.RequiredSpeed then return end
	if abilityConfig.RequiredSpirit and (data.Spirit or 0) < abilityConfig.RequiredSpirit then return end

	-- Check cost
	if not AbilityService.DataService.SpendCoins(player, abilityConfig.Cost) then return end

	table.insert(data.UnlockedAbilities, abilityName)

	-- Notify
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local abilityResult = remoteEvents:FindFirstChild("AbilityUnlocked")
		if abilityResult then
			abilityResult:FireClient(player, { Name = abilityName, Type = abilityConfig.Type })
		end
	end

	print("[AbilityService]", player.Name, "unlocked", abilityName)
end

function AbilityService.EquipAbility(player, abilityName, slot)
	if type(abilityName) ~= "string" then return end
	if type(slot) ~= "number" or slot < 1 or slot > 4 then return end

	local data = AbilityService.DataService.GetFullData(player)
	if not data then return end

	-- Check owned
	local owned = false
	for _, ab in ipairs(data.UnlockedAbilities) do
		if ab == abilityName then
			owned = true
			break
		end
	end
	if not owned then return end

	data.EquippedAbilities[slot] = abilityName

	AbilityService.SyncAbilities(player)
end

function AbilityService.SendAbilityList(player)
	local data = AbilityService.DataService.GetFullData(player)
	if not data then return end

	local abilities = {}
	for _, ab in ipairs(GameConfig.Abilities) do
		local owned = false
		for _, ownedAb in ipairs(data.UnlockedAbilities) do
			if ownedAb == ab.Name then
				owned = true
				break
			end
		end

		local canBuy = true
		if ab.RequiredStrength and (data.Strength or 0) < ab.RequiredStrength then canBuy = false end
		if ab.RequiredDefense and (data.Defense or 0) < ab.RequiredDefense then canBuy = false end
		if ab.RequiredSpeed and (data.Speed or 0) < ab.RequiredSpeed then canBuy = false end
		if ab.RequiredSpirit and (data.Spirit or 0) < ab.RequiredSpirit then canBuy = false end

		table.insert(abilities, {
			Name = ab.Name,
			Type = ab.Type,
			Damage = ab.Damage,
			Cooldown = ab.Cooldown,
			Cost = ab.Cost,
			Owned = owned,
			CanBuy = canBuy and not owned,
		})
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local abilityList = remoteEvents:FindFirstChild("AbilityList")
		if abilityList then
			abilityList:FireClient(player, abilities)
		end
	end
end

function AbilityService.SyncAbilities(player)
	local data = AbilityService.DataService.GetFullData(player)
	if not data then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local abilitySync = remoteEvents:FindFirstChild("AbilitySync")
		if abilitySync then
			abilitySync:FireClient(player, {
				Unlocked = data.UnlockedAbilities,
				Equipped = data.EquippedAbilities,
			})
		end
	end
end

return AbilityService
