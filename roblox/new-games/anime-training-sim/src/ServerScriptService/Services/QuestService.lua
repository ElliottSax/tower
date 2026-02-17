--[[
	QuestService.lua - Anime Training Simulator
	Quest tracking and completion rewards
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local QuestService = {}
QuestService.DataService = nil

function QuestService.Init()
	print("[QuestService] Initializing...")

	QuestService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("GetQuests").OnServerEvent:Connect(function(player)
		QuestService.SendQuestList(player)
	end)

	remoteEvents:WaitForChild("ClaimQuest").OnServerEvent:Connect(function(player, questName)
		QuestService.ClaimQuest(player, questName)
	end)

	print("[QuestService] Initialized")
end

function QuestService.UpdateProgress(player, questType, stat, amount)
	local data = QuestService.DataService.GetFullData(player)
	if not data then return end

	data.QuestProgress = data.QuestProgress or {}

	for _, quest in ipairs(GameConfig.Quests) do
		-- Skip completed quests
		if data.CompletedQuests and data.CompletedQuests[quest.Name] then continue end

		local matches = false

		if quest.Type == questType then
			if quest.Type == "Train" then
				matches = (quest.Stat == nil or quest.Stat == stat)
			elseif quest.Type == "Power" then
				-- Power quests check total power, not incremental
				local totalPower = QuestService.DataService.GetTotalPower(player)
				data.QuestProgress[quest.Name] = totalPower
				matches = false -- Handled above
			else
				matches = true
			end
		end

		if matches then
			data.QuestProgress[quest.Name] = (data.QuestProgress[quest.Name] or 0) + amount
		end
	end

	-- Sync to client
	QuestService.SyncQuests(player)
end

function QuestService.ClaimQuest(player, questName)
	if type(questName) ~= "string" then return end

	local data = QuestService.DataService.GetFullData(player)
	if not data then return end

	-- Find quest
	local questConfig = nil
	for _, q in ipairs(GameConfig.Quests) do
		if q.Name == questName then
			questConfig = q
			break
		end
	end
	if not questConfig then return end

	-- Check not already claimed
	data.CompletedQuests = data.CompletedQuests or {}
	if data.CompletedQuests[questName] then return end

	-- Check progress
	local progress = data.QuestProgress[questName] or 0
	if progress < questConfig.Target then return end

	-- Grant rewards
	if questConfig.Reward.Coins then
		QuestService.DataService.AddCoins(player, questConfig.Reward.Coins)
	end

	data.CompletedQuests[questName] = true

	-- Notify
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local questComplete = remoteEvents:FindFirstChild("QuestComplete")
		if questComplete then
			questComplete:FireClient(player, {
				Name = questName,
				Reward = questConfig.Reward,
			})
		end
	end

	print("[QuestService]", player.Name, "completed quest:", questName)
end

function QuestService.SendQuestList(player)
	local data = QuestService.DataService.GetFullData(player)
	if not data then return end

	local quests = {}
	for _, quest in ipairs(GameConfig.Quests) do
		local progress = data.QuestProgress[quest.Name] or 0

		-- For power quests, use current power
		if quest.Type == "Power" then
			progress = QuestService.DataService.GetTotalPower(player)
		end

		-- For zone quests, count unlocked zones
		if quest.Type == "Zones" then
			progress = data.UnlockedZones and #data.UnlockedZones or 1
		end

		table.insert(quests, {
			Name = quest.Name,
			Description = quest.Description,
			Progress = progress,
			Target = quest.Target,
			Completed = data.CompletedQuests and data.CompletedQuests[quest.Name] or false,
			Reward = quest.Reward,
		})
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local questList = remoteEvents:FindFirstChild("QuestList")
		if questList then
			questList:FireClient(player, quests)
		end
	end
end

function QuestService.SyncQuests(player)
	-- Lightweight sync for progress updates
	local data = QuestService.DataService.GetFullData(player)
	if not data then return end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local questSync = remoteEvents:FindFirstChild("QuestSync")
		if questSync then
			questSync:FireClient(player, data.QuestProgress)
		end
	end
end

return QuestService
