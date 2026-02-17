--[[
	MonetizationService.lua - Treasure Hunt Islands
]]
local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GameConfig = require(RS.Shared.Config.GameConfig)
local MonetizationService = {}

function MonetizationService.Init()
	local DataService = require(SSS.Services.DataService)
	MPS.ProcessReceipt = function(info)
		local p = Players:GetPlayerByUserId(info.PlayerId); if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
		for _, cfg in pairs(GameConfig.DevProducts) do
			if cfg.Id == info.ProductId then
				if cfg.Amount then DataService.AddCoins(p, cfg.Amount) end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return MonetizationService
