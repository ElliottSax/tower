--[[
	TrapService.lua - Escape the Factory
	Manages trap interactions and damage application
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local TrapService = {}

function TrapService.Init()
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("TrapHit").OnServerEvent:Connect(function(player, trapName)
		if type(trapName) ~= "string" then return end
		local FactoryService = require(SSS.Services.FactoryService)
		local run = FactoryService.GetRun(player); if not run then return end

		local trapCfg = nil
		for _, t in ipairs(GC.TrapTypes) do if t.Name == trapName then trapCfg = t; break end end
		if not trapCfg then return end

		-- Apply difficulty scaling
		local factoryCfg = nil
		for _, f in ipairs(GC.Factories) do if f.Name == run.Factory then factoryCfg = f; break end end
		local diffMult = factoryCfg and (1 + (factoryCfg.Difficulty - 1) * 0.15) or 1.0
		local damage = math.floor(trapCfg.Damage * diffMult)

		local remainingHP = FactoryService.TakeDamage(player, damage)

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local tu = reEvents:FindFirstChild("TrapUpdate")
			if tu then
				tu:FireClient(player, {
					Type = "TrapDamage",
					Trap = trapName,
					Damage = damage,
					HP = remainingHP,
				})
			end
		end

		if remainingHP <= 0 then
			-- Trigger death
			local ru = reEvents and reEvents:FindFirstChild("PlayerDied")
			-- Client should fire PlayerDied event
		end
	end)

	re:WaitForChild("CollectGear").OnServerEvent:Connect(function(player, gearType)
		if type(gearType) ~= "string" then return end
		local DS = require(SSS.Services.DataService)
		local FactoryService = require(SSS.Services.FactoryService)
		local data = DS.GetData(player); if not data then return end
		local run = FactoryService.GetRun(player); if not run then return end

		local collectCfg = nil
		for _, c in ipairs(GC.Collectibles) do if c.Name == gearType then collectCfg = c; break end end
		if not collectCfg then return end

		-- Lucky upgrade increases rare find chance
		local luckyLevel = DS.GetUpgradeLevel(player, "Lucky")
		-- Gear was already spawned client-side with spawn chances, so just collect it
		FactoryService.CollectCoin(player, collectCfg.Value)

		local key = collectCfg.Rarity
		if data.Collectibles[key] then
			data.Collectibles[key] = data.Collectibles[key] + 1
		end

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local tu = reEvents:FindFirstChild("TrapUpdate")
			if tu then tu:FireClient(player, { Type = "GearCollected", Gear = gearType, Value = collectCfg.Value }) end
		end
	end)

	re:WaitForChild("UsePowerup").OnServerEvent:Connect(function(player, powerupName)
		if type(powerupName) ~= "string" then return end
		local powerCfg = nil
		for _, p in ipairs(GC.Powerups) do if p.Name == powerupName then powerCfg = p; break end end
		if not powerCfg then return end

		-- Apply powerup effect - notify client
		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local tu = reEvents:FindFirstChild("TrapUpdate")
			if tu then tu:FireClient(player, {
				Type = "PowerupActivated",
				Powerup = powerupName,
				Effect = powerCfg.Effect,
				Duration = powerCfg.Duration,
				Mult = powerCfg.Mult,
			}) end
		end
	end)
end

return TrapService
