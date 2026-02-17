--[[
	DungeonService.lua - Dungeon Doors
	Procedural dungeon generation, door voting, room progression
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DungeonService = {}
DungeonService.DataService = nil

local ActiveRuns = {} -- [UserId] = run state

function DungeonService.Init()
	print("[DungeonService] Initializing...")
	DungeonService.DataService = require(ServerScriptService.Services.DataService)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	re:WaitForChild("StartRun").OnServerEvent:Connect(function(player, className)
		DungeonService.StartRun(player, className)
	end)

	re:WaitForChild("VoteDoor").OnServerEvent:Connect(function(player, doorIndex)
		DungeonService.VoteDoor(player, doorIndex)
	end)

	re:WaitForChild("GetRunState").OnServerEvent:Connect(function(player)
		DungeonService.SyncRunState(player)
	end)

	re:WaitForChild("AbandonRun").OnServerEvent:Connect(function(player)
		DungeonService.AbandonRun(player)
	end)

	print("[DungeonService] Initialized")
end

function DungeonService.StartRun(player, className)
	if type(className) ~= "string" then return end
	if ActiveRuns[player.UserId] then return end

	local data = DungeonService.DataService.GetFullData(player)
	if not data then return end

	-- Validate class
	local classConfig = nil
	for _, c in ipairs(GameConfig.Classes) do
		if c.Name == className then classConfig = c; break end
	end
	if not classConfig then return end

	-- Calculate starting stats with permanent upgrades
	local maxHP = classConfig.HP
	local bonusDamage = 0
	local bonusDefense = 0
	local lootLuck = 0

	for upgradeName, upgradeData in pairs(data.Upgrades or {}) do
		if upgradeData.Effect == "max_hp" then maxHP = maxHP + upgradeData.Amount * upgradeData.Level
		elseif upgradeData.Effect == "damage" then bonusDamage = bonusDamage + upgradeData.Amount * upgradeData.Level
		elseif upgradeData.Effect == "defense" then bonusDefense = bonusDefense + upgradeData.Amount * upgradeData.Level
		elseif upgradeData.Effect == "loot_luck" then lootLuck = lootLuck + upgradeData.Amount * upgradeData.Level
		end
	end

	ActiveRuns[player.UserId] = {
		Floor = 1,
		Room = 0,
		MaxHP = maxHP,
		CurrentHP = maxHP,
		BonusDamage = bonusDamage,
		BonusDefense = bonusDefense,
		LootLuck = lootLuck,
		Class = className,
		ClassConfig = classConfig,
		Inventory = {},
		EquippedWeapon = GameConfig.Weapons[1], -- Start with rusty sword
		SoulsEarned = 0,
		KillCount = 0,
		Doors = {},
		UsedExtraLife = false,
	}

	data.TotalRuns = data.TotalRuns + 1

	DungeonService.GenerateDoors(player)
	DungeonService.SyncRunState(player)
end

function DungeonService.GenerateDoors(player)
	local run = ActiveRuns[player.UserId]
	if not run then return end

	run.Room = run.Room + 1

	-- Check if this room is a boss room
	local floorConfig = DungeonService.GetFloorConfig(run.Floor)
	local isBossRoom = run.Room >= floorConfig.RoomsPerFloor

	if isBossRoom then
		run.Doors = {{ Type = "Boss", Revealed = false }}
		return
	end

	-- Generate 2-4 doors
	local numDoors = math.random(2, 4)
	local doors = {}

	-- Calculate total weight
	local totalWeight = 0
	for _, rt in ipairs(GameConfig.RoomTypes) do
		if rt.Type ~= "Boss" then totalWeight = totalWeight + rt.Weight end
	end

	for i = 1, numDoors do
		local roll = math.random() * totalWeight
		local cumulative = 0
		local chosenType = "Monster"

		for _, rt in ipairs(GameConfig.RoomTypes) do
			if rt.Type ~= "Boss" then
				cumulative = cumulative + rt.Weight
				if roll <= cumulative then
					chosenType = rt.Type
					break
				end
			end
		end

		table.insert(doors, {
			Index = i,
			Type = chosenType,
			Revealed = false,
		})
	end

	run.Doors = doors
end

function DungeonService.VoteDoor(player, doorIndex)
	if type(doorIndex) ~= "number" then return end
	local run = ActiveRuns[player.UserId]
	if not run then return end
	if doorIndex < 1 or doorIndex > #run.Doors then return end

	local door = run.Doors[doorIndex]
	door.Revealed = true

	-- Process room
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")

	if door.Type == "Monster" then
		local CombatService = require(ServerScriptService.Services.CombatService)
		CombatService.StartCombat(player, run)
	elseif door.Type == "Treasure" then
		local LootService = require(ServerScriptService.Services.LootService)
		local loot = LootService.GenerateLoot(run.Floor, run.LootLuck)
		if loot then
			table.insert(run.Inventory, loot)
			if re then
				local lr = re:FindFirstChild("LootDrop")
				if lr then lr:FireClient(player, loot) end
			end
		end
		DungeonService.GenerateDoors(player)
	elseif door.Type == "Safe" then
		-- Heal 30% HP
		run.CurrentHP = math.min(run.MaxHP, run.CurrentHP + math.floor(run.MaxHP * 0.3))
		if re then
			local heal = re:FindFirstChild("Healed")
			if heal then heal:FireClient(player, run.CurrentHP, run.MaxHP) end
		end
		DungeonService.GenerateDoors(player)
	elseif door.Type == "Trap" then
		local trapDamage = math.floor(run.MaxHP * 0.15 * DungeonService.GetFloorConfig(run.Floor).DifficultyMult * 0.3)
		run.CurrentHP = run.CurrentHP - trapDamage
		if run.CurrentHP <= 0 then
			DungeonService.EndRun(player, false)
			return
		end
		DungeonService.GenerateDoors(player)
	elseif door.Type == "Shop" then
		if re then
			local shopEvent = re:FindFirstChild("ShopRoom")
			if shopEvent then shopEvent:FireClient(player, DungeonService.GenerateShopItems(run.Floor)) end
		end
	elseif door.Type == "Boss" then
		local CombatService = require(ServerScriptService.Services.CombatService)
		CombatService.StartBossFight(player, run)
	elseif door.Type == "Puzzle" then
		-- Simple puzzle - auto-pass for now, generate next doors
		DungeonService.GenerateDoors(player)
	elseif door.Type == "Mimic" then
		-- Surprise monster!
		local CombatService = require(ServerScriptService.Services.CombatService)
		CombatService.StartCombat(player, run, true) -- isMimic=true
	end

	DungeonService.SyncRunState(player)
end

function DungeonService.AdvanceFloor(player)
	local run = ActiveRuns[player.UserId]
	if not run then return end

	run.Floor = run.Floor + 1
	run.Room = 0

	local data = DungeonService.DataService.GetFullData(player)
	if data and run.Floor > data.HighestFloor then
		data.HighestFloor = run.Floor
		local ls = player:FindFirstChild("leaderstats")
		if ls then local f = ls:FindFirstChild("Best Floor"); if f then f.Value = run.Floor end end
	end

	DungeonService.GenerateDoors(player)
	DungeonService.SyncRunState(player)
end

function DungeonService.EndRun(player, survived)
	local run = ActiveRuns[player.UserId]
	if not run then return end

	-- Check extra life
	if not survived and not run.UsedExtraLife then
		local data = DungeonService.DataService.GetFullData(player)
		if data and data.GamePasses and data.GamePasses.ExtraLife then
			run.UsedExtraLife = true
			run.CurrentHP = math.floor(run.MaxHP * 0.5)
			DungeonService.SyncRunState(player)
			return
		end
	end

	-- Grant souls
	local soulsEarned = run.SoulsEarned
	DungeonService.DataService.AddSouls(player, soulsEarned)

	local data = DungeonService.DataService.GetFullData(player)
	if data then
		data.TotalKills = data.TotalKills + run.KillCount
	end

	ActiveRuns[player.UserId] = nil

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local runEnd = re:FindFirstChild("RunEnd")
		if runEnd then
			runEnd:FireClient(player, {
				Survived = survived,
				FloorsCleared = run.Floor,
				SoulsEarned = soulsEarned,
				KillCount = run.KillCount,
			})
		end
	end
end

function DungeonService.AbandonRun(player)
	DungeonService.EndRun(player, false)
end

function DungeonService.GetFloorConfig(floor)
	for _, fc in ipairs(GameConfig.Floors) do
		if floor >= fc.Range[1] and floor <= fc.Range[2] then
			return fc
		end
	end
	return GameConfig.Floors[#GameConfig.Floors]
end

function DungeonService.GenerateShopItems(floor)
	local items = {}
	for i = 1, 3 do
		local weaponPool = {}
		for _, w in ipairs(GameConfig.Weapons) do table.insert(weaponPool, w) end
		local item = weaponPool[math.random(#weaponPool)]
		table.insert(items, { Weapon = item, Cost = math.floor(item.Damage * 10 * (1 + floor * 0.1)) })
	end
	-- Healing potion
	table.insert(items, { Type = "Potion", Name = "Health Potion", HealPercent = 0.5, Cost = 50 + floor * 5 })
	return items
end

function DungeonService.SyncRunState(player)
	local run = ActiveRuns[player.UserId]
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local rs = re:FindFirstChild("RunState")
		if rs then
			rs:FireClient(player, run and {
				Floor = run.Floor,
				Room = run.Room,
				CurrentHP = run.CurrentHP,
				MaxHP = run.MaxHP,
				Class = run.Class,
				Doors = run.Doors,
				SoulsEarned = run.SoulsEarned,
				KillCount = run.KillCount,
				EquippedWeapon = run.EquippedWeapon and run.EquippedWeapon.Name,
			} or nil)
		end
	end
end

function DungeonService.GetActiveRun(player)
	return ActiveRuns[player.UserId]
end

return DungeonService
