--[[
	SoulsShopService.lua - Dungeon Doors
	Permanent meta-progression upgrades
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SoulsShopService = {}

function SoulsShopService.Init()
	local DataService = require(ServerScriptService.Services.DataService)
	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeName)
		if type(upgradeName) ~= "string" then return end
		local data = DataService.GetFullData(player)
		if not data then return end

		local upgradeConfig = nil
		for _, u in ipairs(GameConfig.SoulsShop) do
			if u.Name == upgradeName then upgradeConfig = u; break end
		end
		if not upgradeConfig then return end

		data.Upgrades = data.Upgrades or {}
		local current = data.Upgrades[upgradeName]
		local currentLevel = current and current.Level or 0

		if currentLevel >= upgradeConfig.MaxLevel then return end

		local cost = upgradeConfig.Cost * (1 + currentLevel * 0.5)
		cost = math.floor(cost)

		if not DataService.SpendSouls(player, cost) then return end

		data.Upgrades[upgradeName] = {
			Effect = upgradeConfig.Effect,
			Amount = upgradeConfig.Amount,
			Level = currentLevel + 1,
		}

		local reEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if reEvents then
			local ur = reEvents:FindFirstChild("UpgradeResult")
			if ur then ur:FireClient(player, { Name = upgradeName, NewLevel = currentLevel + 1 }) end
		end
	end)

	re:WaitForChild("GetSoulsShop").OnServerEvent:Connect(function(player)
		local data = DataService.GetFullData(player)
		if not data then return end
		local shop = {}
		for _, u in ipairs(GameConfig.SoulsShop) do
			local current = data.Upgrades and data.Upgrades[u.Name]
			local level = current and current.Level or 0
			table.insert(shop, {
				Name = u.Name, Effect = u.Effect, Amount = u.Amount,
				MaxLevel = u.MaxLevel, CurrentLevel = level,
				Cost = math.floor(u.Cost * (1 + level * 0.5)),
			})
		end
		local reEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if reEvents then
			local ss = reEvents:FindFirstChild("SoulsShopData")
			if ss then ss:FireClient(player, shop) end
		end
	end)

	print("[SoulsShopService] Initialized")
end

return SoulsShopService
