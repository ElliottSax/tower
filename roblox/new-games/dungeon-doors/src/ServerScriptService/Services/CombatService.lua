--[[
	CombatService.lua - Dungeon Doors
	Monster combat, boss fights, damage calculation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local CombatService = {}

function CombatService.Init() print("[CombatService] Initialized") end

function CombatService.StartCombat(player, run, isMimic)
	local floorConfig = require(ServerScriptService.Services.DungeonService).GetFloorConfig(run.Floor)
	local diffMult = floorConfig.DifficultyMult

	-- Pick monster based on floor difficulty
	local validMonsters = {}
	for _, m in ipairs(GameConfig.Monsters) do table.insert(validMonsters, m) end
	local monster = validMonsters[math.random(#validMonsters)]

	local monsterHP = math.floor(monster.HP * diffMult)
	local monsterDmg = math.floor(monster.Damage * diffMult)

	if isMimic then monsterHP = monsterHP * 1.5; monsterDmg = monsterDmg * 1.5 end

	-- Auto-resolve combat
	local playerDmg = (run.EquippedWeapon and run.EquippedWeapon.Damage or 5) + run.BonusDamage
	playerDmg = math.floor(playerDmg * run.ClassConfig.BaseDamage)
	local playerDef = run.BonusDefense * run.ClassConfig.BaseDefense

	while monsterHP > 0 and run.CurrentHP > 0 do
		monsterHP = monsterHP - playerDmg
		if monsterHP > 0 then
			local dmgTaken = math.max(1, monsterDmg - playerDef)
			run.CurrentHP = run.CurrentHP - dmgTaken
		end
	end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")

	if run.CurrentHP <= 0 then
		local DungeonService = require(ServerScriptService.Services.DungeonService)
		DungeonService.EndRun(player, false)
		return
	end

	-- Victory
	run.KillCount = run.KillCount + 1
	run.SoulsEarned = run.SoulsEarned + math.floor(monster.Souls * diffMult)

	if re then
		local cr = re:FindFirstChild("CombatResult")
		if cr then cr:FireClient(player, { Won = true, Monster = monster.Name, SoulsGained = monster.Souls, HPRemaining = run.CurrentHP }) end
	end

	local DungeonService = require(ServerScriptService.Services.DungeonService)
	DungeonService.GenerateDoors(player)
	DungeonService.SyncRunState(player)
end

function CombatService.StartBossFight(player, run)
	local bossConfig = nil
	for _, b in ipairs(GameConfig.Bosses) do
		if b.Floor == run.Floor or (run.Floor % 5 == 0 and not bossConfig) then bossConfig = b end
	end
	if not bossConfig then bossConfig = GameConfig.Bosses[1] end

	local floorConfig = require(ServerScriptService.Services.DungeonService).GetFloorConfig(run.Floor)
	local bossHP = math.floor(bossConfig.HP * (run.Floor / bossConfig.Floor))
	local bossDmg = math.floor(bossConfig.Damage * (run.Floor / bossConfig.Floor))

	local playerDmg = (run.EquippedWeapon and run.EquippedWeapon.Damage or 5) + run.BonusDamage
	playerDmg = math.floor(playerDmg * run.ClassConfig.BaseDamage)
	local playerDef = run.BonusDefense * run.ClassConfig.BaseDefense

	while bossHP > 0 and run.CurrentHP > 0 do
		bossHP = bossHP - playerDmg
		if bossHP > 0 then
			local dmgTaken = math.max(1, bossDmg - playerDef)
			run.CurrentHP = run.CurrentHP - dmgTaken
		end
	end

	if run.CurrentHP <= 0 then
		local DungeonService = require(ServerScriptService.Services.DungeonService)
		DungeonService.EndRun(player, false)
		return
	end

	run.KillCount = run.KillCount + 1
	run.SoulsEarned = run.SoulsEarned + bossConfig.Souls

	local data = require(ServerScriptService.Services.DataService).GetFullData(player)
	if data then data.BossesDefeated = data.BossesDefeated + 1 end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local br = re:FindFirstChild("BossDefeated")
		if br then br:FireClient(player, { Boss = bossConfig.Name, Souls = bossConfig.Souls }) end
	end

	local DungeonService = require(ServerScriptService.Services.DungeonService)
	DungeonService.AdvanceFloor(player)
end

return CombatService
