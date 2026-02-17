--[[
	CosmeticsService.lua - Speed Run Universe
	Manages trails, win effects, purchasing, equipping, and visual display.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local CosmeticsService = {}
CosmeticsService.DataService = nil
CosmeticsService.SecurityManager = nil

-- ============================================================================
-- ACTIVE TRAILS (visual trail instances per player)
-- ============================================================================
local ActiveTrails = {} -- userId -> Trail instance

-- ============================================================================
-- INIT
-- ============================================================================
function CosmeticsService.Init()
	CosmeticsService.DataService = require(ServerScriptService.Services.DataService)
	CosmeticsService.SecurityManager = require(ServerScriptService.Security.SecurityManager)

	local re = ReplicatedStorage:WaitForChild("RemoteEvents")

	-- Buy trail
	re:WaitForChild("BuyTrail").OnServerEvent:Connect(function(player, data)
		CosmeticsService.BuyTrail(player, data)
	end)

	-- Equip trail
	re:WaitForChild("EquipTrail").OnServerEvent:Connect(function(player, data)
		CosmeticsService.EquipTrail(player, data)
	end)

	-- Buy win effect
	re:WaitForChild("BuyWinEffect").OnServerEvent:Connect(function(player, data)
		CosmeticsService.BuyWinEffect(player, data)
	end)

	-- Equip win effect
	re:WaitForChild("EquipWinEffect").OnServerEvent:Connect(function(player, data)
		CosmeticsService.EquipWinEffect(player, data)
	end)

	-- Apply trail when character spawns
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5) -- Wait for character to fully load
			CosmeticsService._ApplyTrailToCharacter(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CosmeticsService._RemoveTrail(player)
	end)

	print("[CosmeticsService] Initialized")
end

-- ============================================================================
-- BUY TRAIL
-- ============================================================================
function CosmeticsService.BuyTrail(player, data)
	if not CosmeticsService.SecurityManager.CheckRateLimit(player, "BuyTrail") then return end
	if not data or not data.TrailId then return end

	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	local trailId = data.TrailId

	-- Check if already owned
	if playerData.OwnedTrails[trailId] then
		CosmeticsService._Notify(player, "Trail already owned!")
		return
	end

	-- Find trail config
	local trailCfg = GameConfig.TrailById[trailId]
	if not trailCfg then
		CosmeticsService._Notify(player, "Trail not found!")
		return
	end

	-- Check cost
	if not CosmeticsService.DataService.SpendCoins(player, trailCfg.Cost) then
		CosmeticsService._Notify(player, "Not enough coins! Need " .. trailCfg.Cost)
		return
	end

	-- Grant trail
	playerData.OwnedTrails[trailId] = true

	-- Auto-equip if no trail equipped
	if playerData.EquippedTrail == "" then
		playerData.EquippedTrail = trailId
		CosmeticsService._ApplyTrailToCharacter(player, player.Character)
	end

	CosmeticsService._SyncCosmetics(player)
	CosmeticsService._Notify(player, "Purchased " .. trailCfg.Name .. "!")
	print("[CosmeticsService]", player.Name, "bought trail:", trailCfg.Name)
end

-- ============================================================================
-- EQUIP TRAIL
-- ============================================================================
function CosmeticsService.EquipTrail(player, data)
	if not CosmeticsService.SecurityManager.CheckRateLimit(player, "EquipTrail") then return end
	if not data then return end

	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	local trailId = data.TrailId or ""

	-- Unequip
	if trailId == "" then
		playerData.EquippedTrail = ""
		CosmeticsService._RemoveTrail(player)
		CosmeticsService._SyncCosmetics(player)
		return
	end

	-- Check ownership
	if not playerData.OwnedTrails[trailId] then
		-- Check exclusive trails from game passes
		local isExclusive = false
		if playerData.GamePasses and playerData.GamePasses.ExclusiveTrails then
			for _, excTrail in ipairs(GameConfig.ExclusiveTrails) do
				if excTrail.Id == trailId then isExclusive = true; break end
			end
		end
		if not isExclusive then
			CosmeticsService._Notify(player, "You don't own this trail!")
			return
		end
	end

	playerData.EquippedTrail = trailId
	CosmeticsService._ApplyTrailToCharacter(player, player.Character)
	CosmeticsService._SyncCosmetics(player)
end

-- ============================================================================
-- BUY WIN EFFECT
-- ============================================================================
function CosmeticsService.BuyWinEffect(player, data)
	if not CosmeticsService.SecurityManager.CheckRateLimit(player, "BuyWinEffect") then return end
	if not data or not data.EffectId then return end

	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	local effectId = data.EffectId

	-- Check if already owned
	if playerData.OwnedWinEffects[effectId] then
		CosmeticsService._Notify(player, "Effect already owned!")
		return
	end

	-- Find effect config
	local effectCfg = GameConfig.WinEffectById[effectId]
	if not effectCfg then
		CosmeticsService._Notify(player, "Effect not found!")
		return
	end

	-- Check cost
	if not CosmeticsService.DataService.SpendCoins(player, effectCfg.Cost) then
		CosmeticsService._Notify(player, "Not enough coins! Need " .. effectCfg.Cost)
		return
	end

	-- Grant effect
	playerData.OwnedWinEffects[effectId] = true

	-- Auto-equip if none equipped
	if playerData.EquippedWinEffect == "" then
		playerData.EquippedWinEffect = effectId
	end

	CosmeticsService._SyncCosmetics(player)
	CosmeticsService._Notify(player, "Purchased " .. effectCfg.Name .. "!")
	print("[CosmeticsService]", player.Name, "bought win effect:", effectCfg.Name)
end

-- ============================================================================
-- EQUIP WIN EFFECT
-- ============================================================================
function CosmeticsService.EquipWinEffect(player, data)
	if not CosmeticsService.SecurityManager.CheckRateLimit(player, "EquipWinEffect") then return end
	if not data then return end

	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	local effectId = data.EffectId or ""

	-- Unequip
	if effectId == "" then
		playerData.EquippedWinEffect = ""
		CosmeticsService._SyncCosmetics(player)
		return
	end

	-- Check ownership
	if not playerData.OwnedWinEffects[effectId] then
		CosmeticsService._Notify(player, "You don't own this effect!")
		return
	end

	playerData.EquippedWinEffect = effectId
	CosmeticsService._SyncCosmetics(player)
end

-- ============================================================================
-- TRAIL VISUAL APPLICATION
-- ============================================================================
function CosmeticsService._ApplyTrailToCharacter(player, character)
	if not character then return end

	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	-- Remove existing trail
	CosmeticsService._RemoveTrail(player)

	local trailId = playerData.EquippedTrail
	if trailId == "" then return end

	-- Find trail config (check both normal and exclusive)
	local trailCfg = GameConfig.TrailById[trailId]
	if not trailCfg then
		for _, excTrail in ipairs(GameConfig.ExclusiveTrails) do
			if excTrail.Id == trailId then
				trailCfg = excTrail
				break
			end
		end
	end
	if not trailCfg then return end

	-- Create trail attachment points
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not hrp or not head then return end

	-- Attachment on upper torso
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailAttach0"
	attachment0.Position = Vector3.new(0, 0.5, 0)
	attachment0.Parent = hrp

	-- Attachment on lower torso
	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailAttach1"
	attachment1.Position = Vector3.new(0, -0.5, 0)
	attachment1.Parent = hrp

	-- Create the trail
	local trail = Instance.new("Trail")
	trail.Name = "CosmeticTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = trailCfg.Lifetime or 0.8
	trail.MinLength = 0.1
	trail.MaxLength = 0
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Color = ColorSequence.new(trailCfg.Color1, trailCfg.Color2)
	trail.LightEmission = 0.5
	trail.LightInfluence = 0.3

	if trailCfg.Texture and trailCfg.Texture ~= "" then
		trail.Texture = trailCfg.Texture
	end

	trail.Parent = hrp

	ActiveTrails[player.UserId] = { Trail = trail, Attach0 = attachment0, Attach1 = attachment1 }
end

function CosmeticsService._RemoveTrail(player)
	local trailData = ActiveTrails[player.UserId]
	if trailData then
		if trailData.Trail and trailData.Trail.Parent then trailData.Trail:Destroy() end
		if trailData.Attach0 and trailData.Attach0.Parent then trailData.Attach0:Destroy() end
		if trailData.Attach1 and trailData.Attach1.Parent then trailData.Attach1:Destroy() end
		ActiveTrails[player.UserId] = nil
	end
end

-- ============================================================================
-- WIN EFFECT PLAYBACK
-- ============================================================================
function CosmeticsService.PlayWinEffect(player)
	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	local effectId = playerData.EquippedWinEffect
	if effectId == "" then return end

	local effectCfg = GameConfig.WinEffectById[effectId]
	if not effectCfg then return end

	-- Fire to ALL clients so everyone sees the effect
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local playEffect = re:FindFirstChild("PlayWinEffect")
		if playEffect then
			-- Get player position
			local character = player.Character
			local position = Vector3.new(0, 0, 0)
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then position = hrp.Position end
			end

			playEffect:FireAllClients({
				PlayerName = player.Name,
				EffectId = effectId,
				Position = position,
			})
		end
	end
end

-- ============================================================================
-- SYNC COSMETICS TO CLIENT
-- ============================================================================
function CosmeticsService._SyncCosmetics(player)
	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end

	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local sync = re:FindFirstChild("CosmeticSync")
		if sync then
			-- Build list of exclusive trails if they own the pass
			local availableExclusiveTrails = {}
			if playerData.GamePasses and playerData.GamePasses.ExclusiveTrails then
				for _, excTrail in ipairs(GameConfig.ExclusiveTrails) do
					table.insert(availableExclusiveTrails, excTrail.Id)
				end
			end

			sync:FireClient(player, {
				OwnedTrails = playerData.OwnedTrails,
				OwnedWinEffects = playerData.OwnedWinEffects,
				EquippedTrail = playerData.EquippedTrail,
				EquippedWinEffect = playerData.EquippedWinEffect,
				ExclusiveTrails = availableExclusiveTrails,
			})
		end
	end
end

-- ============================================================================
-- GRANT COSMETIC (used by other services, e.g., daily rewards)
-- ============================================================================
function CosmeticsService.GrantTrail(player, trailId)
	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end
	playerData.OwnedTrails[trailId] = true
	CosmeticsService._SyncCosmetics(player)
end

function CosmeticsService.GrantWinEffect(player, effectId)
	local playerData = CosmeticsService.DataService.GetFullData(player)
	if not playerData then return end
	playerData.OwnedWinEffects[effectId] = true
	CosmeticsService._SyncCosmetics(player)
end

-- ============================================================================
-- UTILITY
-- ============================================================================
function CosmeticsService._Notify(player, message)
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if re then
		local notif = re:FindFirstChild("Notification")
		if notif then
			notif:FireClient(player, { Message = message })
		end
	end
end

return CosmeticsService
