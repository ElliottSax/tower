--[[
	ShopService.lua - Battle Royale Legends
	Cosmetic skin shop with coin purchases
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local ShopService = {}

function ShopService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("BuySkin").OnServerEvent:Connect(function(player, skinName)
		if type(skinName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		local skinCfg = nil
		for _, s in ipairs(GC.Skins) do if s.Name == skinName then skinCfg = s; break end end
		if not skinCfg then return end

		-- Check if already owned
		for _, owned in ipairs(data.OwnedSkins) do
			if owned == skinName then return end
		end

		if not DS.SpendCoins(player, skinCfg.Cost) then return end
		table.insert(data.OwnedSkins, skinName)

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local su = reEvents:FindFirstChild("ShopUpdate")
			if su then su:FireClient(player, { Type = "Purchased", Skin = skinName, Coins = data.Coins }) end
		end
	end)

	re:WaitForChild("EquipSkin").OnServerEvent:Connect(function(player, skinName)
		if type(skinName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		local owned = false
		for _, s in ipairs(data.OwnedSkins) do
			if s == skinName then owned = true; break end
		end
		if not owned then return end

		data.EquippedSkin = skinName
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local su = reEvents:FindFirstChild("ShopUpdate")
			if su then su:FireClient(player, { Type = "Equipped", Skin = skinName }) end
		end
	end)

	re:WaitForChild("GetShopData").OnServerEvent:Connect(function(player)
		local data = DS.GetData(player); if not data then return end
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local su = reEvents:FindFirstChild("ShopUpdate")
			if su then su:FireClient(player, {
				Type = "ShopData",
				Skins = GC.Skins,
				OwnedSkins = data.OwnedSkins,
				EquippedSkin = data.EquippedSkin,
				Coins = data.Coins,
			}) end
		end
	end)
end

return ShopService
