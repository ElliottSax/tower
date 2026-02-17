--[[
	UpgradeService.lua - Escape the Factory
	Permanent player upgrades purchased with coins
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local UpgradeService = {}

function UpgradeService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeName)
		if type(upgradeName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		local upgCfg = nil
		for _, u in ipairs(GC.PlayerUpgrades) do if u.Name == upgradeName then upgCfg = u; break end end
		if not upgCfg then return end

		local currentLevel = DS.GetUpgradeLevel(player, upgradeName)
		if currentLevel >= upgCfg.MaxLevel then return end

		local cost = math.floor(upgCfg.BaseCost * (upgCfg.CostMult ^ currentLevel))
		if not DS.SpendCoins(player, cost) then return end

		DS.SetUpgradeLevel(player, upgradeName, currentLevel + 1)

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local uu = reEvents:FindFirstChild("UpgradeUpdate")
			if uu then uu:FireClient(player, {
				Type = "Upgraded",
				Upgrade = upgradeName,
				NewLevel = currentLevel + 1,
				MaxLevel = upgCfg.MaxLevel,
				Coins = data.Coins,
			}) end
		end
	end)

	re:WaitForChild("GetUpgrades").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local upgrades = {}
		for _, u in ipairs(GC.PlayerUpgrades) do
			local level = DS.GetUpgradeLevel(player, u.Name)
			local cost = math.floor(u.BaseCost * (u.CostMult ^ level))
			table.insert(upgrades, {
				Name = u.Name,
				Level = level,
				MaxLevel = u.MaxLevel,
				Cost = cost,
				Effect = u.Effect,
			})
		end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local uu = reEvents:FindFirstChild("UpgradeUpdate")
			if uu then uu:FireClient(player, { Type = "UpgradeList", Upgrades = upgrades, Coins = data.Coins }) end
		end
	end)
end

return UpgradeService
