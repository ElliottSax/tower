local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local MonetizationService = {}

function MonetizationService.Init()
	local DS = require(SSS.Services.DataService)
	MPS.ProcessReceipt = function(info)
		local p = Players:GetPlayerByUserId(info.PlayerId); if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
		for _, cfg in pairs(GC.DevProducts) do
			if cfg.Id == info.ProductId then
				if cfg.Amount then DS.AddCoins(p, cfg.Amount) end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return MonetizationService
