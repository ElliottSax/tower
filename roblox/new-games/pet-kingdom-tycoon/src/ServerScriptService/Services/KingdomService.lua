--[[
	KingdomService.lua - Pet Kingdom Tycoon
	Plot management, structure placement, kingdom upgrades
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local KingdomService = {}
KingdomService.DataService = nil

function KingdomService.Init()
	print("[KingdomService] Initializing...")
	KingdomService.DataService = require(ServerScriptService.Services.DataService)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("BuildStructure").OnServerEvent:Connect(function(player, structureName, position)
		KingdomService.BuildStructure(player, structureName, position)
	end)

	re:WaitForChild("RemoveStructure").OnServerEvent:Connect(function(player, structureIndex)
		KingdomService.RemoveStructure(player, structureIndex)
	end)

	re:WaitForChild("GetKingdom").OnServerEvent:Connect(function(player)
		KingdomService.SendKingdomData(player)
	end)

	print("[KingdomService] Initialized")
end

function KingdomService.BuildStructure(player, structureName, position)
	if type(structureName) ~= "string" then return end

	local data = KingdomService.DataService.GetFullData(player)
	if not data then return end

	local structConfig = nil
	for _, s in ipairs(GameConfig.Structures) do
		if s.Name == structureName then structConfig = s; break end
	end
	if not structConfig then return end

	if not KingdomService.DataService.SpendCoins(player, structConfig.Cost) then return end

	data.Structures = data.Structures or {}
	table.insert(data.Structures, {
		Name = structConfig.Name,
		Bonus = structConfig.Bonus,
		BonusAmount = structConfig.BonusAmount,
		Position = position,
		BuiltAt = os.time(),
	})

	KingdomService.SendKingdomData(player)
end

function KingdomService.RemoveStructure(player, structureIndex)
	if type(structureIndex) ~= "number" then return end

	local data = KingdomService.DataService.GetFullData(player)
	if not data or not data.Structures then return end
	if structureIndex < 1 or structureIndex > #data.Structures then return end

	-- Refund 50%
	local struct = data.Structures[structureIndex]
	for _, s in ipairs(GameConfig.Structures) do
		if s.Name == struct.Name then
			KingdomService.DataService.AddCoins(player, math.floor(s.Cost * 0.5))
			break
		end
	end

	table.remove(data.Structures, structureIndex)
	KingdomService.SendKingdomData(player)
end

function KingdomService.GetBonus(player, bonusType)
	local data = KingdomService.DataService.GetFullData(player)
	if not data or not data.Structures then return 1 end

	local mult = 1
	for _, struct in ipairs(data.Structures) do
		if struct.Bonus == bonusType or struct.Bonus == "all_bonus" then
			mult = mult * struct.BonusAmount
		end
	end
	return mult
end

function KingdomService.SendKingdomData(player)
	local data = KingdomService.DataService.GetFullData(player)
	if not data then return end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local ks = re:FindFirstChild("KingdomSync")
		if ks then
			ks:FireClient(player, {
				Structures = data.Structures or {},
				PlotLevel = data.PlotLevel,
				AvailableStructures = GameConfig.Structures,
			})
		end
	end
end

return KingdomService
