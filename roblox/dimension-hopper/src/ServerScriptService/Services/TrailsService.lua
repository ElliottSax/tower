--[[
	TrailsService.lua
	Manages player trails and visual effects during racing

	Features:
	- Multiple trail styles
	- Unlockable trails
	- Dimension-specific trail effects
	- Trail customization
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrailsService = {}

-- ============================================================================
-- TRAIL DEFINITIONS
-- ============================================================================

TrailsService.Trails = {
	-- Default trails (free)
	default = {
		id = "default",
		name = "Basic Trail",
		description = "A simple trail",
		color = Color3.fromRGB(255, 255, 255),
		color2 = Color3.fromRGB(200, 200, 200),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 0.5,
		minLength = 0.1,
		widthScale = NumberSequence.new(1),
		unlocked = true,
		icon = "trail",
	},

	-- Color trails
	fire = {
		id = "fire",
		name = "Fire Trail",
		description = "Leave flames in your wake",
		color = Color3.fromRGB(255, 100, 0),
		color2 = Color3.fromRGB(255, 200, 0),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 0.8,
		minLength = 0.1,
		widthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		unlocked = false,
		unlockMethod = "level",
		unlockRequirement = 5,
		icon = "fire",
	},

	ice = {
		id = "ice",
		name = "Ice Trail",
		description = "Leave a frosty path",
		color = Color3.fromRGB(100, 200, 255),
		color2 = Color3.fromRGB(200, 240, 255),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0.8),
		}),
		lifetime = 1.0,
		minLength = 0.1,
		widthScale = NumberSequence.new(0.8),
		unlocked = false,
		unlockMethod = "level",
		unlockRequirement = 10,
		icon = "snowflake",
	},

	rainbow = {
		id = "rainbow",
		name = "Rainbow Trail",
		description = "All the colors!",
		color = Color3.fromRGB(255, 0, 0),
		color2 = Color3.fromRGB(0, 0, 255),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 1.2,
		minLength = 0.1,
		widthScale = NumberSequence.new(1.2),
		unlocked = false,
		unlockMethod = "level",
		unlockRequirement = 25,
		icon = "rainbow",
		special = "rainbow", -- Special animation
	},

	-- Dimension trails
	gravity = {
		id = "gravity",
		name = "Gravity Trail",
		description = "Warped space follows you",
		color = Color3.fromRGB(150, 50, 255),
		color2 = Color3.fromRGB(100, 0, 200),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 0.6,
		minLength = 0.1,
		widthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 1.5),
			NumberSequenceKeypoint.new(1, 0.3),
		}),
		unlocked = false,
		unlockMethod = "dimension",
		unlockRequirement = "Gravity",
		icon = "arrow_up",
	},

	tiny = {
		id = "tiny",
		name = "Tiny Trail",
		description = "Microscopic particles",
		color = Color3.fromRGB(255, 200, 100),
		color2 = Color3.fromRGB(200, 150, 50),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 0.4,
		minLength = 0.05,
		widthScale = NumberSequence.new(0.5),
		unlocked = false,
		unlockMethod = "dimension",
		unlockRequirement = "Tiny",
		icon = "minimize",
	},

	void = {
		id = "void",
		name = "Void Trail",
		description = "Darkness seeps from you",
		color = Color3.fromRGB(30, 0, 50),
		color2 = Color3.fromRGB(80, 0, 120),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 1.5,
		minLength = 0.1,
		widthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 1.2),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		unlocked = false,
		unlockMethod = "dimension",
		unlockRequirement = "Void",
		icon = "circle",
	},

	sky = {
		id = "sky",
		name = "Sky Trail",
		description = "Cloud wisps follow you",
		color = Color3.fromRGB(255, 255, 255),
		color2 = Color3.fromRGB(200, 230, 255),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 1.0,
		minLength = 0.1,
		widthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 2),
		}),
		unlocked = false,
		unlockMethod = "dimension",
		unlockRequirement = "Sky",
		icon = "cloud",
	},

	-- Achievement trails
	champion = {
		id = "champion",
		name = "Champion Trail",
		description = "For true champions",
		color = Color3.fromRGB(255, 215, 0),
		color2 = Color3.fromRGB(255, 180, 0),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 0.8,
		minLength = 0.1,
		widthScale = NumberSequence.new(1.5),
		unlocked = false,
		unlockMethod = "achievement",
		unlockRequirement = "champion",
		icon = "crown",
	},

	speedster = {
		id = "speedster",
		name = "Speedster Trail",
		description = "Blazing fast!",
		color = Color3.fromRGB(0, 255, 100),
		color2 = Color3.fromRGB(0, 200, 255),
		transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		lifetime = 0.3,
		minLength = 0.2,
		widthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
		unlocked = false,
		unlockMethod = "achievement",
		unlockRequirement = "speedster",
		icon = "zap",
	},
}

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { unlockedTrails, equippedTrail, trailInstance }
TrailsService.PlayerData = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function TrailsService.Init()
	print("[TrailsService] Initializing...")

	TrailsService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		TrailsService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		TrailsService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		TrailsService.OnPlayerJoin(player)
	end

	print("[TrailsService] Initialized with", TrailsService.GetTrailCount(), "trails")
end

function TrailsService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Equip trail
	if not remoteFolder:FindFirstChild("EquipTrail") then
		local event = Instance.new("RemoteEvent")
		event.Name = "EquipTrail"
		event.Parent = remoteFolder
	end

	-- Get trails
	if not remoteFolder:FindFirstChild("GetTrails") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetTrails"
		func.Parent = remoteFolder
	end

	TrailsService.Remotes = {
		EquipTrail = remoteFolder.EquipTrail,
		GetTrails = remoteFolder.GetTrails,
	}

	TrailsService.Remotes.EquipTrail.OnServerEvent:Connect(function(player, trailId)
		TrailsService.EquipTrail(player, trailId)
	end)

	TrailsService.Remotes.GetTrails.OnServerInvoke = function(player)
		return TrailsService.GetPlayerTrails(player)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function TrailsService.OnPlayerJoin(player: Player)
	TrailsService.PlayerData[player.UserId] = {
		unlockedTrails = {},
		equippedTrail = "default",
		trailInstance = nil,
	}

	-- Unlock default trails
	for trailId, trail in pairs(TrailsService.Trails) do
		if trail.unlocked then
			TrailsService.PlayerData[player.UserId].unlockedTrails[trailId] = true
		end
	end

	TrailsService.LoadPlayerData(player)

	-- Wait for character and apply trail
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		TrailsService.ApplyTrail(player, character)
	end)

	if player.Character then
		task.wait(0.5)
		TrailsService.ApplyTrail(player, player.Character)
	end
end

function TrailsService.OnPlayerLeave(player: Player)
	TrailsService.SavePlayerData(player)
	TrailsService.PlayerData[player.UserId] = nil
end

function TrailsService.LoadPlayerData(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data then
		local playerData = TrailsService.PlayerData[player.UserId]
		if playerData then
			if data.UnlockedTrails then
				for trailId, _ in pairs(data.UnlockedTrails) do
					playerData.unlockedTrails[trailId] = true
				end
			end
			if data.EquippedTrail then
				playerData.equippedTrail = data.EquippedTrail
			end
		end
	end
end

function TrailsService.SavePlayerData(player: Player)
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			UnlockedTrails = playerData.unlockedTrails,
			EquippedTrail = playerData.equippedTrail,
		})
	end
end

-- ============================================================================
-- TRAIL APPLICATION
-- ============================================================================

function TrailsService.ApplyTrail(player: Player, character: Model)
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return end

	-- Remove existing trail
	if playerData.trailInstance then
		playerData.trailInstance:Destroy()
		playerData.trailInstance = nil
	end

	local trailDef = TrailsService.Trails[playerData.equippedTrail]
	if not trailDef then
		trailDef = TrailsService.Trails.default
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Create attachments for trail
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailAttachment0"
	attachment0.Position = Vector3.new(0, 0.5, 0)
	attachment0.Parent = humanoidRootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailAttachment1"
	attachment1.Position = Vector3.new(0, -0.5, 0)
	attachment1.Parent = humanoidRootPart

	-- Create trail
	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(trailDef.color, trailDef.color2)
	trail.Transparency = trailDef.transparency
	trail.Lifetime = trailDef.lifetime
	trail.MinLength = trailDef.minLength
	trail.WidthScale = trailDef.widthScale
	trail.FaceCamera = true
	trail.Parent = humanoidRootPart

	playerData.trailInstance = trail

	-- Special effects
	if trailDef.special == "rainbow" then
		-- Animate rainbow colors
		task.spawn(function()
			local hue = 0
			while trail.Parent do
				hue = (hue + 0.01) % 1
				local color1 = Color3.fromHSV(hue, 1, 1)
				local color2 = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
				trail.Color = ColorSequence.new(color1, color2)
				task.wait(0.05)
			end
		end)
	end
end

function TrailsService.EquipTrail(player: Player, trailId: string)
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return end

	-- Check if unlocked
	if not playerData.unlockedTrails[trailId] then
		return false
	end

	playerData.equippedTrail = trailId

	-- Re-apply trail
	if player.Character then
		TrailsService.ApplyTrail(player, player.Character)
	end

	print(string.format("[TrailsService] %s equipped trail: %s", player.Name, trailId))
	return true
end

-- ============================================================================
-- UNLOCK SYSTEM
-- ============================================================================

function TrailsService.UnlockTrail(player: Player, trailId: string): boolean
	local trail = TrailsService.Trails[trailId]
	if not trail then return false end

	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return false end

	if playerData.unlockedTrails[trailId] then
		return false -- Already unlocked
	end

	playerData.unlockedTrails[trailId] = true

	-- Notify player
	local DimensionHopper = _G.DimensionHopper
	if DimensionHopper then
		local NotificationService = DimensionHopper.GetService("NotificationService")
		if NotificationService then
			NotificationService.Send(player, "REWARD", "Trail Unlocked!", trail.name)
		end
	end

	print(string.format("[TrailsService] %s unlocked trail: %s", player.Name, trail.name))
	return true
end

function TrailsService.CheckTrailUnlocks(player: Player, event: string, value: any)
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return end

	for trailId, trail in pairs(TrailsService.Trails) do
		if not playerData.unlockedTrails[trailId] then
			if trail.unlockMethod == event then
				local shouldUnlock = false

				if event == "level" and type(value) == "number" then
					shouldUnlock = value >= trail.unlockRequirement
				elseif event == "achievement" and type(value) == "string" then
					shouldUnlock = value == trail.unlockRequirement
				elseif event == "dimension" and type(value) == "string" then
					shouldUnlock = value == trail.unlockRequirement
				end

				if shouldUnlock then
					TrailsService.UnlockTrail(player, trailId)
				end
			end
		end
	end
end

-- ============================================================================
-- API
-- ============================================================================

function TrailsService.GetPlayerTrails(player: Player): table
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return {} end

	local result = {
		unlocked = {},
		locked = {},
		equipped = playerData.equippedTrail,
	}

	for trailId, trail in pairs(TrailsService.Trails) do
		local trailData = {
			id = trailId,
			name = trail.name,
			description = trail.description,
			icon = trail.icon,
			color = trail.color,
			unlocked = playerData.unlockedTrails[trailId] == true,
		}

		if trailData.unlocked then
			table.insert(result.unlocked, trailData)
		else
			trailData.unlockMethod = trail.unlockMethod
			trailData.unlockRequirement = trail.unlockRequirement
			table.insert(result.locked, trailData)
		end
	end

	return result
end

function TrailsService.HasTrail(player: Player, trailId: string): boolean
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return false end
	return playerData.unlockedTrails[trailId] == true
end

function TrailsService.GetEquippedTrail(player: Player): string
	local playerData = TrailsService.PlayerData[player.UserId]
	if not playerData then return "default" end
	return playerData.equippedTrail
end

function TrailsService.GetTrailCount(): number
	local count = 0
	for _ in pairs(TrailsService.Trails) do
		count = count + 1
	end
	return count
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function TrailsService.OnLevelUp(player: Player, newLevel: number)
	TrailsService.CheckTrailUnlocks(player, "level", newLevel)
end

function TrailsService.OnAchievementUnlocked(player: Player, achievementId: string)
	TrailsService.CheckTrailUnlocks(player, "achievement", achievementId)
end

function TrailsService.OnDimensionComplete(player: Player, dimension: string)
	TrailsService.CheckTrailUnlocks(player, "dimension", dimension)
end

return TrailsService
