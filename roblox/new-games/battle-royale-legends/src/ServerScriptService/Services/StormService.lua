--[[
	StormService.lua - Battle Royale Legends
	Shrinking storm zone that damages players outside the safe area
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local GC = require(RS.Shared.Config.GameConfig)
local StormService = {}

local stormActive = false
local currentPhase = 0

function StormService.Init()
	-- Storm is started by MatchService when a match begins
end

function StormService.StartStorm(match)
	stormActive = true
	currentPhase = 0
	local re = RS:FindFirstChild("RemoteEvents")
	local CombatService = require(SSS.Services.CombatService)

	for _, phase in ipairs(GC.StormPhases) do
		if not stormActive then break end
		if not match or match.State ~= "InProgress" then break end

		currentPhase = currentPhase + 1

		-- Notify all players of upcoming storm phase
		for uid, p in pairs(match.Players) do
			if p.Parent and match.Alive[uid] then
				re:FindFirstChild("StormUpdate"):FireClient(p, {
					Type = "PhaseWarning",
					Phase = currentPhase,
					Delay = phase.Delay,
					ShrinkTime = phase.ShrinkTime,
					Damage = phase.Damage,
					RadiusPct = phase.RadiusPct,
				})
			end
		end

		-- Wait for delay before storm shrinks
		task.wait(phase.Delay)
		if not stormActive then break end

		-- Storm is now shrinking - notify
		for uid, p in pairs(match.Players) do
			if p.Parent and match.Alive[uid] then
				re:FindFirstChild("StormUpdate"):FireClient(p, {
					Type = "Shrinking",
					Phase = currentPhase,
					RadiusPct = phase.RadiusPct,
					ShrinkTime = phase.ShrinkTime,
				})
			end
		end

		-- During shrink, tick damage on players outside zone
		local tickCount = math.floor(phase.ShrinkTime / 2)
		for t = 1, tickCount do
			task.wait(2)
			if not stormActive or not match or match.State ~= "InProgress" then break end

			-- Check each alive player - in real implementation, check position vs zone
			-- For now, simulate with random chance based on phase
			for uid, alive in pairs(match.Alive) do
				if alive then
					local p = match.Players[uid]
					if p and p.Parent then
						-- Storm damage is applied by client checking position
						-- Server broadcasts storm bounds, client reports if outside
					end
				end
			end
		end
	end

	stormActive = false
end

function StormService.StopStorm()
	stormActive = false
	currentPhase = 0
end

function StormService.ApplyDamageToPlayer(player, phase)
	local dmg = GC.StormPhases[phase] and GC.StormPhases[phase].Damage or 5
	-- Check for Storm Shield game pass (50% reduction)
	local MPS = game:GetService("MarketplaceService")
	for _, gp in ipairs(GC.GamePasses) do
		if gp.Name == "Storm Shield" and gp.Id > 0 then
			local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, gp.Id) end)
			if ok and owns then dmg = math.floor(dmg * 0.5) end
			break
		end
	end
	local CombatService = require(SSS.Services.CombatService)
	CombatService.ApplyStormDamage(player, dmg)
end

function StormService.GetPhase() return currentPhase end

return StormService
