--[[
	TransformationService.lua - Anime Training Simulator
	Power-gated transformations with visual aura effects
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TransformationService = {}
TransformationService.DataService = nil

function TransformationService.Init()
	print("[TransformationService] Initializing...")

	TransformationService.DataService = require(ServerScriptService.Services.DataService)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

	remoteEvents:WaitForChild("Transform").OnServerEvent:Connect(function(player, transformName)
		TransformationService.Transform(player, transformName)
	end)

	remoteEvents:WaitForChild("GetTransformations").OnServerEvent:Connect(function(player)
		TransformationService.SendTransformationList(player)
	end)

	print("[TransformationService] Initialized")
end

function TransformationService.Transform(player, transformName)
	if type(transformName) ~= "string" then return end

	local data = TransformationService.DataService.GetFullData(player)
	if not data then return end

	-- Find transformation
	local tfConfig = nil
	for _, tf in ipairs(GameConfig.Transformations) do
		if tf.Name == transformName then
			tfConfig = tf
			break
		end
	end
	if not tfConfig then return end

	-- Check power requirement
	local totalPower = TransformationService.DataService.GetTotalPower(player)
	if totalPower < tfConfig.RequiredPower then return end

	data.CurrentTransformation = transformName

	-- Notify all clients for visual effect
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local transformResult = remoteEvents:FindFirstChild("TransformResult")
		if transformResult then
			transformResult:FireAllClients(player.UserId, {
				Name = tfConfig.Name,
				Color = { tfConfig.Color.R, tfConfig.Color.G, tfConfig.Color.B },
				Aura = tfConfig.Aura,
				AuraColor = tfConfig.AuraColor and { tfConfig.AuraColor.R, tfConfig.AuraColor.G, tfConfig.AuraColor.B },
				Multiplier = tfConfig.Multiplier,
			})
		end
	end

	-- Quest progress
	local QuestService = require(ServerScriptService.Services.QuestService)
	QuestService.UpdateProgress(player, "Transform", nil, 1)

	print("[TransformationService]", player.Name, "transformed to", transformName)
end

function TransformationService.SendTransformationList(player)
	local data = TransformationService.DataService.GetFullData(player)
	if not data then return end

	local totalPower = TransformationService.DataService.GetTotalPower(player)
	local transformations = {}

	for _, tf in ipairs(GameConfig.Transformations) do
		table.insert(transformations, {
			Name = tf.Name,
			RequiredPower = tf.RequiredPower,
			Multiplier = tf.Multiplier,
			Unlocked = totalPower >= tf.RequiredPower,
			Active = data.CurrentTransformation == tf.Name,
		})
	end

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local tfList = remoteEvents:FindFirstChild("TransformationList")
		if tfList then
			tfList:FireClient(player, transformations)
		end
	end
end

function TransformationService.GetCurrentMultiplier(player)
	local data = TransformationService.DataService.GetFullData(player)
	if not data then return 1 end

	for _, tf in ipairs(GameConfig.Transformations) do
		if tf.Name == data.CurrentTransformation then
			return tf.Multiplier
		end
	end

	return 1
end

return TransformationService
