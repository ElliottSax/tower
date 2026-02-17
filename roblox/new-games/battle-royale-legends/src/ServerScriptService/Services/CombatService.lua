--[[
	CombatService.lua - Battle Royale Legends
	Handles weapon attacks, damage, shields, and healing
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local GC = require(RS.Shared.Config.GameConfig)
local CombatService = {}

local playerState = {}

function CombatService.Init()
	local re = RS:WaitForChild("RemoteEvents")
	local Security = require(SSS.Security.SecurityManager)

	Players.PlayerAdded:Connect(function(p)
		playerState[p.UserId] = { HP = 100, Shield = 0, Weapon = nil, Inventory = {} }
	end)
	Players.PlayerRemoving:Connect(function(p) playerState[p.UserId] = nil end)

	re:WaitForChild("Attack").OnServerEvent:Connect(function(player, targetUserId)
		if not Security.CheckRateLimit(player, "Attack") then return end
		if type(targetUserId) ~= "number" then return end

		local attacker = playerState[player.UserId]; if not attacker then return end
		local defender = playerState[targetUserId]; if not defender then return end
		local weapon = attacker.Weapon; if not weapon then return end

		-- Find weapon config
		local weaponCfg = nil
		for _, w in ipairs(GC.Weapons) do if w.Name == weapon then weaponCfg = w; break end end
		if not weaponCfg then return end

		local damage = weaponCfg.Damage
		local rarityMult = GC.Rarities[weaponCfg.Rarity] and GC.Rarities[weaponCfg.Rarity].Mult or 1.0
		damage = math.floor(damage * rarityMult)

		-- Apply damage to shield first, then HP
		if defender.Shield > 0 then
			if damage <= defender.Shield then
				defender.Shield = defender.Shield - damage
				damage = 0
			else
				damage = damage - defender.Shield
				defender.Shield = 0
			end
		end
		defender.HP = math.max(0, defender.HP - damage)

		-- Notify both players
		re:FindFirstChild("CombatUpdate"):FireClient(player, { Type = "DamageDealt", Target = targetUserId, Amount = damage })

		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if targetPlayer then
			re:FindFirstChild("CombatUpdate"):FireClient(targetPlayer, { Type = "DamageTaken", HP = defender.HP, Shield = defender.Shield })
		end

		-- Check for elimination
		if defender.HP <= 0 then
			local MatchService = require(SSS.Services.MatchService)
			if targetPlayer then
				MatchService.EliminatePlayer(targetPlayer, player)
			end
		end
	end)

	re:WaitForChild("UseHeal").OnServerEvent:Connect(function(player, itemName)
		if type(itemName) ~= "string" then return end
		local state = playerState[player.UserId]; if not state then return end

		-- Find item in inventory
		local idx = nil
		for i, item in ipairs(state.Inventory) do
			if item.Name == itemName and item.Type == "Heal" then idx = i; break end
		end
		if not idx then return end

		local healCfg = nil
		for _, h in ipairs(GC.Heals) do if h.Name == itemName then healCfg = h; break end end
		if not healCfg then return end

		table.remove(state.Inventory, idx)
		state.HP = math.min(100, state.HP + healCfg.Amount)
		re:FindFirstChild("CombatUpdate"):FireClient(player, { Type = "Healed", HP = state.HP })
	end)

	re:WaitForChild("UseShield").OnServerEvent:Connect(function(player, itemName)
		if type(itemName) ~= "string" then return end
		local state = playerState[player.UserId]; if not state then return end

		local idx = nil
		for i, item in ipairs(state.Inventory) do
			if item.Name == itemName and item.Type == "Shield" then idx = i; break end
		end
		if not idx then return end

		local shieldCfg = nil
		for _, s in ipairs(GC.Shields) do if s.Name == itemName then shieldCfg = s; break end end
		if not shieldCfg then return end

		table.remove(state.Inventory, idx)
		state.Shield = math.min(100, state.Shield + shieldCfg.Amount)
		re:FindFirstChild("CombatUpdate"):FireClient(player, { Type = "Shielded", Shield = state.Shield })
	end)

	re:WaitForChild("EquipWeapon").OnServerEvent:Connect(function(player, weaponName)
		if type(weaponName) ~= "string" then return end
		local state = playerState[player.UserId]; if not state then return end
		for _, item in ipairs(state.Inventory) do
			if item.Name == weaponName and item.Type == "Weapon" then
				state.Weapon = weaponName; break
			end
		end
	end)
end

function CombatService.GetState(player) return playerState[player.UserId] end

function CombatService.AddToInventory(player, itemName, itemType)
	local state = playerState[player.UserId]; if not state then return end
	table.insert(state.Inventory, { Name = itemName, Type = itemType })
end

function CombatService.ApplyStormDamage(player, damage)
	local state = playerState[player.UserId]; if not state then return end
	state.HP = math.max(0, state.HP - damage)
	if state.HP <= 0 then
		local MatchService = require(SSS.Services.MatchService)
		MatchService.EliminatePlayer(player, nil)
	end
end

function CombatService.ResetState(player)
	playerState[player.UserId] = { HP = 100, Shield = 0, Weapon = nil, Inventory = {} }
end

return CombatService
