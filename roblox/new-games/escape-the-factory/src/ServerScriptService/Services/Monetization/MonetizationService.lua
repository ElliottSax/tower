--[[
	MonetizationService.lua - Escape the Factory
	Game passes and developer product purchases
]]
local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local MonetizationService = {}

function MonetizationService.Init()
	local DS = require(SSS.Services.DataService)

	MPS.ProcessReceipt = function(info)
		local p = Players:GetPlayerByUserId(info.PlayerId)
		if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
		for _, cfg in pairs(GC.DevProducts) do
			if cfg.Id == info.ProductId then
				if cfg.Amount then DS.AddCoins(p, cfg.Amount) end
				if cfg.ReviveType then
					-- Instant revive during a run
					local FactoryService = require(SSS.Services.FactoryService)
					local run = FactoryService.GetRun(p)
					if run then
						run.Lives = run.Lives + 1
						run.HP = run.MaxHP
						local re = RS:FindFirstChild("RemoteEvents")
						if re then
							local ru = re:FindFirstChild("RunUpdate")
							if ru then ru:FireClient(p, { Type = "Respawn", Lives = run.Lives, HP = run.HP }) end
						end
					end
				end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local re = RS:WaitForChild("RemoteEvents")
	re:WaitForChild("PurchaseGamePass").OnServerEvent:Connect(function(player, passName)
		if type(passName) ~= "string" then return end
		for _, gp in ipairs(GC.GamePasses) do
			if gp.Name == passName and gp.Id > 0 then
				MPS:PromptGamePassPurchase(player, gp.Id); break
			end
		end
	end)

	re:WaitForChild("PurchaseDevProduct").OnServerEvent:Connect(function(player, productName)
		if type(productName) ~= "string" then return end
		for _, dp in ipairs(GC.DevProducts) do
			if dp.Name == productName and dp.Id > 0 then
				MPS:PromptProductPurchase(player, dp.Id); break
			end
		end
	end)
end

return MonetizationService
