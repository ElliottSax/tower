--[[
	MonetizationService.lua - Pet Kingdom Tycoon
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MonetizationService = {}
MonetizationService.DataService = nil

function MonetizationService.Init()
	MonetizationService.DataService = require(ServerScriptService.Services.DataService)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")
	re:WaitForChild("GetShopData").OnServerEvent:Connect(function(player) MonetizationService.SendShopData(player) end)
	re:WaitForChild("PurchaseGamePass").OnServerEvent:Connect(function(player, name)
		local cfg = GameConfig.GamePasses[name]
		if cfg and cfg.Id > 0 then MarketplaceService:PromptGamePassPurchase(player, cfg.Id) end
	end)
	re:WaitForChild("PurchaseDevProduct").OnServerEvent:Connect(function(player, name)
		local cfg = GameConfig.DevProducts[name]
		if cfg and cfg.Id > 0 then MarketplaceService:PromptProductPurchase(player, cfg.Id) end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.wait(2)
		local data = MonetizationService.DataService.GetFullData(player)
		if not data then return end
		data.GamePasses = data.GamePasses or {}
		for name, cfg in pairs(GameConfig.GamePasses) do
			if cfg.Id > 0 then
				local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, cfg.Id) end)
				if ok and owns then data.GamePasses[name] = true end
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local data = MonetizationService.DataService.GetFullData(player)
		if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
		for name, cfg in pairs(GameConfig.DevProducts) do
			if cfg.Id == info.ProductId then
				if cfg.Amount then MonetizationService.DataService.AddCoins(player, cfg.Amount) end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function MonetizationService.SendShopData(player)
	local data = MonetizationService.DataService.GetFullData(player)
	if not data then return end
	local shop = { GamePasses = {}, DevProducts = {}, OwnedPasses = data.GamePasses or {} }
	for name, cfg in pairs(GameConfig.GamePasses) do
		shop.GamePasses[name] = { Name = cfg.Name, Description = cfg.Description, Price = cfg.Price, Owned = data.GamePasses and data.GamePasses[name] or false }
	end
	for name, cfg in pairs(GameConfig.DevProducts) do
		shop.DevProducts[name] = { Name = cfg.Name, Description = cfg.Description or "", Price = cfg.Price }
	end
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then local sd = re:FindFirstChild("ShopData"); if sd then sd:FireClient(player, shop) end end
end

return MonetizationService
