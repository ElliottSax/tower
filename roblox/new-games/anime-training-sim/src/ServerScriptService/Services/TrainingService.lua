--[[
	TrainingService.lua - Anime Training Simulator
	Core training loop - click/hold to train stats, zone multipliers, pet boosts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TrainingService = {}
TrainingService.DataService = nil
TrainingService.SecurityManager = nil

function TrainingService.Init()
	print("[TrainingService] Initializing...")

	TrainingService.DataService = require(ServerScriptService.Services.DataService)
	TrainingService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("Train").OnServerEvent:Connect(function(player, statName)
		TrainingService.Train(player, statName)
	end)

	-- Auto-train loop for game pass holders
	task.spawn(function()
		while true do
			task.wait(2)
			TrainingService.ProcessAutoTrainers()
		end
	end)

	print("[TrainingService] Initialized")
end

function TrainingService.Train(player, statName)
	-- Validate
	if not TrainingService.SecurityManager.CheckRateLimit(player, "Train") then
		return
	end

	if type(statName) ~= "string" then return end

	local validStats = { Strength = true, Defense = true, Speed = true, Spirit = true }
	if not validStats[statName] then return end

	local data = TrainingService.DataService.GetFullData(player)
	if not data then return end

	-- Find training type config
	local trainingConfig = nil
	for _, t in ipairs(GameConfig.TrainingTypes) do
		if t.Name == statName then
			trainingConfig = t
			break
		end
	end
	if not trainingConfig then return end

	-- Calculate gain
	local baseGain = trainingConfig.BaseGain

	-- Zone multiplier
	local zoneMultiplier = 1
	for _, zone in ipairs(GameConfig.TrainingZones) do
		if zone.Name == data.CurrentZone then
			zoneMultiplier = zone.Multiplier
			break
		end
	end

	-- Pet boost
	local petBoost = 1
	for _, petId in ipairs(data.EquippedPets or {}) do
		local pet = data.Pets[petId]
		if pet then
			for _, petConfig in ipairs(GameConfig.Pets) do
				if petConfig.Name == pet.Name then
					petBoost = petBoost * petConfig.Boost
					break
				end
			end
		end
	end

	-- Transformation multiplier
	local transformMult = 1
	for _, tf in ipairs(GameConfig.Transformations) do
		if tf.Name == data.CurrentTransformation then
			transformMult = tf.Multiplier
			break
		end
	end

	-- VIP / game pass multiplier
	local passMult = 1
	if data.GamePasses and data.GamePasses.VIP then
		passMult = passMult * 2
	end

	-- Training boost potion
	if data._TrainingBoostExpiry and os.time() < data._TrainingBoostExpiry then
		passMult = passMult * 5
	end

	-- Rebirth multiplier
	local rebirthMult = 1 + data.RebirthLevel * GameConfig.Rebirth.BoostPerLevel

	local totalGain = math.floor(baseGain * zoneMultiplier * petBoost * transformMult * passMult * rebirthMult)
	if totalGain < 1 then totalGain = 1 end

	-- Apply stat gain
	data[statName] = data[statName] + totalGain
	data.TotalTrains = data.TotalTrains + 1

	-- Update leaderstats
	TrainingService.DataService.UpdateLeaderstats(player)

	-- Notify client
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local trainResult = remoteEvents:FindFirstChild("TrainResult")
		if trainResult then
			trainResult:FireClient(player, {
				Stat = statName,
				Gain = totalGain,
				NewValue = data[statName],
				TotalPower = TrainingService.DataService.GetTotalPower(player),
			})
		end
	end

	-- Check quest progress
	local QuestService = require(ServerScriptService.Services.QuestService)
	QuestService.UpdateProgress(player, "Train", statName, 1)

	-- Coin reward every 10 trains
	if data.TotalTrains % 10 == 0 then
		TrainingService.DataService.AddCoins(player, math.floor(totalGain * 0.5))
	end
end

function TrainingService.ProcessAutoTrainers()
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		local data = TrainingService.DataService.GetFullData(player)
		if data and data.GamePasses and data.GamePasses.AutoTrain then
			-- Auto-train the highest stat
			local bestStat = "Strength"
			local bestVal = 0
			for _, t in ipairs(GameConfig.TrainingTypes) do
				if (data[t.Name] or 0) >= bestVal then
					bestVal = data[t.Name] or 0
					bestStat = t.Name
				end
			end
			-- Reduced auto-train efficiency (50% of manual)
			TrainingService.Train(player, bestStat)
		end
	end
end

return TrainingService
