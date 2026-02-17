--[[
	CompanionService.lua - Escape the Factory
	Companion pets that help during factory runs
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local CompanionService = {}

function CompanionService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("BuyCompanion").OnServerEvent:Connect(function(player, companionName)
		if type(companionName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		local compCfg = nil
		for _, c in ipairs(GC.Companions) do if c.Name == companionName then compCfg = c; break end end
		if not compCfg then return end

		-- Check not already owned
		for _, owned in ipairs(data.OwnedCompanions) do
			if owned == companionName then return end
		end

		if not DS.SpendCoins(player, compCfg.Cost) then return end
		table.insert(data.OwnedCompanions, companionName)

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local cu = reEvents:FindFirstChild("CompanionUpdate")
			if cu then cu:FireClient(player, { Type = "Purchased", Companion = companionName, Coins = data.Coins }) end
		end
	end)

	re:WaitForChild("EquipCompanion").OnServerEvent:Connect(function(player, companionName)
		if type(companionName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		if companionName == "" then
			data.EquippedCompanion = ""
			return
		end

		local owned = false
		for _, c in ipairs(data.OwnedCompanions) do
			if c == companionName then owned = true; break end
		end
		if not owned then return end

		data.EquippedCompanion = companionName

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local cu = reEvents:FindFirstChild("CompanionUpdate")
			if cu then cu:FireClient(player, { Type = "Equipped", Companion = companionName }) end
		end
	end)

	re:WaitForChild("GetCompanions").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local cu = reEvents:FindFirstChild("CompanionUpdate")
			if cu then cu:FireClient(player, {
				Type = "CompanionList",
				All = GC.Companions,
				Owned = data.OwnedCompanions,
				Equipped = data.EquippedCompanion,
				Coins = data.Coins,
			}) end
		end
	end)
end

return CompanionService
