--[[
	FactoryService.lua - Escape the Factory
	Manages factory runs, room progression, and completion tracking
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local GC = require(RS.Shared.Config.GameConfig)
local FactoryService = {}

local activeRuns = {}

function FactoryService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	Players.PlayerRemoving:Connect(function(p) activeRuns[p.UserId] = nil end)

	re:WaitForChild("StartRun").OnServerEvent:Connect(function(player, factoryName)
		if type(factoryName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		-- Check factory is unlocked
		local unlocked = false
		for _, f in ipairs(data.UnlockedFactories) do
			if f == factoryName then unlocked = true; break end
		end
		if not unlocked then return end

		local factoryCfg = nil
		for _, f in ipairs(GC.Factories) do if f.Name == factoryName then factoryCfg = f; break end end
		if not factoryCfg then return end

		-- Calculate HP based on upgrades
		local baseHP = 100
		local hpLevel = DS.GetUpgradeLevel(player, "Extra Health")
		local hp = baseHP + (hpLevel * 10)

		-- Check Extra Lives game pass
		local lives = 1
		local MPS = game:GetService("MarketplaceService")
		for _, gp in ipairs(GC.GamePasses) do
			if gp.Name == "Extra Lives" and gp.Id > 0 then
				local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, gp.Id) end)
				if ok and owns then lives = 3 end
				break
			end
		end

		activeRuns[player.UserId] = {
			Factory = factoryName,
			CurrentRoom = 1,
			TotalRooms = factoryCfg.Rooms,
			HP = hp,
			MaxHP = hp,
			Lives = lives,
			StartTime = tick(),
			CoinsCollected = 0,
			GearsCollected = {},
			SkipsUsed = 0,
		}

		re:FindFirstChild("RunUpdate"):FireClient(player, {
			Type = "RunStarted",
			Factory = factoryName,
			Room = 1,
			TotalRooms = factoryCfg.Rooms,
			HP = hp,
			MaxHP = hp,
			Lives = lives,
		})
	end)

	re:WaitForChild("CompleteRoom").OnServerEvent:Connect(function(player)
		local run = activeRuns[player.UserId]; if not run then return end
		run.CurrentRoom = run.CurrentRoom + 1

		if run.CurrentRoom > run.TotalRooms then
			-- Factory completed!
			FactoryService.CompleteRun(player)
			return
		end

		re:FindFirstChild("RunUpdate"):FireClient(player, {
			Type = "NextRoom",
			Room = run.CurrentRoom,
			TotalRooms = run.TotalRooms,
			HP = run.HP,
		})
	end)

	re:WaitForChild("SkipRoom").OnServerEvent:Connect(function(player)
		local run = activeRuns[player.UserId]; if not run then return end

		-- Check Skip Room game pass
		local MPS = game:GetService("MarketplaceService")
		local canSkip = false
		for _, gp in ipairs(GC.GamePasses) do
			if gp.Name == "Skip Room" and gp.Id > 0 then
				local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, gp.Id) end)
				if ok and owns and run.SkipsUsed < 1 then canSkip = true end
				break
			end
		end
		if not canSkip then return end

		run.SkipsUsed = run.SkipsUsed + 1
		run.CurrentRoom = run.CurrentRoom + 1

		if run.CurrentRoom > run.TotalRooms then
			FactoryService.CompleteRun(player)
			return
		end

		re:FindFirstChild("RunUpdate"):FireClient(player, {
			Type = "RoomSkipped",
			Room = run.CurrentRoom,
			TotalRooms = run.TotalRooms,
		})
	end)

	re:WaitForChild("PlayerDied").OnServerEvent:Connect(function(player)
		local run = activeRuns[player.UserId]; if not run then return end
		run.Lives = run.Lives - 1
		local data = DS.GetData(player)
		if data then data.Deaths = data.Deaths + 1 end

		if run.Lives <= 0 then
			-- Run failed
			local coins = run.CoinsCollected
			DS.AddCoins(player, math.floor(coins * 0.5))
			activeRuns[player.UserId] = nil
			re:FindFirstChild("RunUpdate"):FireClient(player, {
				Type = "RunFailed",
				Room = run.CurrentRoom,
				CoinsEarned = math.floor(coins * 0.5),
			})
		else
			-- Respawn with remaining lives
			run.HP = run.MaxHP
			re:FindFirstChild("RunUpdate"):FireClient(player, {
				Type = "Respawn",
				Lives = run.Lives,
				HP = run.HP,
			})
		end
	end)

	re:WaitForChild("UnlockFactory").OnServerEvent:Connect(function(player, factoryName)
		if type(factoryName) ~= "string" then return end
		local data = DS.GetData(player); if not data then return end

		local factoryCfg = nil
		for _, f in ipairs(GC.Factories) do if f.Name == factoryName then factoryCfg = f; break end end
		if not factoryCfg then return end

		-- Check not already unlocked
		for _, f in ipairs(data.UnlockedFactories) do
			if f == factoryName then return end
		end

		if not DS.SpendCoins(player, factoryCfg.UnlockCost) then return end
		table.insert(data.UnlockedFactories, factoryName)

		re:FindFirstChild("RunUpdate"):FireClient(player, {
			Type = "FactoryUnlocked",
			Factory = factoryName,
		})
	end)
end

function FactoryService.CompleteRun(player)
	local DS = require(SSS.Services.DataService)
	local run = activeRuns[player.UserId]; if not run then return end
	local data = DS.GetData(player); if not data then return end
	local re = RS:FindFirstChild("RemoteEvents")

	local elapsed = tick() - run.StartTime
	data.TotalEscapes = data.TotalEscapes + 1

	-- Calculate stars based on time
	local stars = 1
	local bonusMult = 1.0
	for _, tr in ipairs(GC.TimeRewards) do
		if elapsed <= tr.MaxTime then stars = tr.Stars; bonusMult = tr.BonusMult; break end
	end

	-- VIP bonus
	local MPS = game:GetService("MarketplaceService")
	for _, gp in ipairs(GC.GamePasses) do
		if gp.Name == "VIP" and gp.Id > 0 then
			local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, gp.Id) end)
			if ok and owns then bonusMult = bonusMult * 2 end
			break
		end
	end

	local baseCoins = run.CoinsCollected + (run.TotalRooms * 10)
	local totalCoins = math.floor(baseCoins * bonusMult)
	DS.AddCoins(player, totalCoins)

	-- Save best time
	local bestKey = run.Factory
	if not data.BestTimes[bestKey] or elapsed < data.BestTimes[bestKey] then
		data.BestTimes[bestKey] = elapsed
	end

	-- Save stars
	local starKey = run.Factory
	if not data.FactoryStars[starKey] or stars > data.FactoryStars[starKey] then
		data.FactoryStars[starKey] = stars
	end

	activeRuns[player.UserId] = nil

	re:FindFirstChild("RunUpdate"):FireClient(player, {
		Type = "RunComplete",
		Factory = run.Factory,
		Time = elapsed,
		Stars = stars,
		CoinsEarned = totalCoins,
		TotalEscapes = data.TotalEscapes,
	})
end

function FactoryService.GetRun(player) return activeRuns[player.UserId] end

function FactoryService.CollectCoin(player, amount)
	local run = activeRuns[player.UserId]; if not run then return end
	run.CoinsCollected = run.CoinsCollected + amount
end

function FactoryService.TakeDamage(player, damage)
	local run = activeRuns[player.UserId]; if not run then return end
	local DS = require(SSS.Services.DataService)
	local toughLevel = DS.GetUpgradeLevel(player, "Tough Skin")
	local reduction = toughLevel * 0.05
	damage = math.floor(damage * (1 - reduction))
	run.HP = math.max(0, run.HP - damage)
	return run.HP
end

return FactoryService
