--[[
	RebirthService.lua - Anime Training Simulator
	Rebirth/prestige system - reset stats for permanent multiplier
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local RebirthService = {}
RebirthService.DataService = nil

function RebirthService.Init()
	print("[RebirthService] Initializing...")
	RebirthService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("Rebirth").OnServerEvent:Connect(function(player)
		RebirthService.Rebirth(player)
	end)

	remoteEvents:WaitForChild("GetRebirthInfo").OnServerEvent:Connect(function(player)
		RebirthService.SendRebirthInfo(player)
	end)

	print("[RebirthService] Initialized")
end

function RebirthService.Rebirth(player)
	local data = RebirthService.DataService.GetFullData(player)
	if not data then return end

	if data.RebirthLevel >= GameConfig.Rebirth.MaxLevel then return end

	local cost = GameConfig.Rebirth.BaseCost * (GameConfig.Rebirth.CostMultiplier ^ data.RebirthLevel)
	cost = math.floor(cost)

	if data.Coins < cost then return end

	-- Increment rebirth level
	data.RebirthLevel = data.RebirthLevel + 1

	-- Reset stats
	data.Coins = 0
	data.Strength = 0
	data.Defense = 0
	data.Speed = 0
	data.Spirit = 0
	data.TotalTrains = 0
	data.CurrentZone = "Beginner Dojo"
	data.UnlockedZones = { "Beginner Dojo" }
	data.CurrentTransformation = "Base Form"

	-- Keep: pets, abilities, game passes, quests, PvP rating

	-- Update leaderstats
	RebirthService.DataService.UpdateLeaderstats(player)

	-- Notify
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local rebirthComplete = remoteEvents:FindFirstChild("RebirthComplete")
		if rebirthComplete then
			rebirthComplete:FireClient(player, {
				NewLevel = data.RebirthLevel,
				Multiplier = 1 + data.RebirthLevel * GameConfig.Rebirth.BoostPerLevel,
			})
		end
	end

	-- Check milestones
	for _, milestone in ipairs(GameConfig.Rebirth.Milestones) do
		if milestone.Level == data.RebirthLevel then
			local notification = remoteEvents and remoteEvents:FindFirstChild("Notification")
			if notification then
				notification:FireClient(player, {
					Title = "Rebirth Milestone!",
					Text = "Level " .. milestone.Level .. ": " .. milestone.Reward,
					Color = { 255, 215, 0 },
				})
			end
		end
	end

	print("[RebirthService]", player.Name, "rebirthed to level", data.RebirthLevel)
end

function RebirthService.SendRebirthInfo(player)
	local data = RebirthService.DataService.GetFullData(player)
	if not data then return end

	local cost = GameConfig.Rebirth.BaseCost * (GameConfig.Rebirth.CostMultiplier ^ data.RebirthLevel)
	cost = math.floor(cost)

	local nextMilestone = nil
	for _, m in ipairs(GameConfig.Rebirth.Milestones) do
		if m.Level > data.RebirthLevel then
			nextMilestone = m
			break
		end
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local rebirthInfo = remoteEvents:FindFirstChild("RebirthInfo")
		if rebirthInfo then
			rebirthInfo:FireClient(player, {
				Level = data.RebirthLevel,
				MaxLevel = GameConfig.Rebirth.MaxLevel,
				Cost = cost,
				CanRebirth = data.Coins >= cost and data.RebirthLevel < GameConfig.Rebirth.MaxLevel,
				CurrentMultiplier = 1 + data.RebirthLevel * GameConfig.Rebirth.BoostPerLevel,
				NextMultiplier = 1 + (data.RebirthLevel + 1) * GameConfig.Rebirth.BoostPerLevel,
				NextMilestone = nextMilestone,
			})
		end
	end
end

return RebirthService
