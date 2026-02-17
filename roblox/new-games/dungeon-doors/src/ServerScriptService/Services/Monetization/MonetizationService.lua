--[[
	MonetizationService.lua - Dungeon Doors
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}

function MonetizationService.Init()
	local DataService = require(ServerScriptService.Services.DataService)
	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("GetShopData").OnServerEvent:Connect(function(player)
		local data = DataService.GetFullData(player)
		if not data then return end
		local shop = { GamePasses = {}, DevProducts = {} }
		for name, cfg in pairs(GameConfig.GamePasses) do
			shop.GamePasses[name] = { Name = cfg.Name, Description = cfg.Description, Price = cfg.Price, Owned = data.GamePasses and data.GamePasses[name] or false }
		end
		for name, cfg in pairs(GameConfig.DevProducts) do
			shop.DevProducts[name] = { Name = cfg.Name, Description = cfg.Description or "", Price = cfg.Price }
		end
		local sd = re:FindFirstChild("ShopData")
		if sd then sd:FireClient(player, shop) end
	end)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		for name, cfg in pairs(GameConfig.DevProducts) do
			if cfg.Id == info.ProductId then
				if cfg.Amount then DataService.AddSouls(player, cfg.Amount) end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("[MonetizationService] Initialized")
end

return MonetizationService
