--[[
	CosmeticsService.lua
	Handles visual cosmetics for players

	Features:
	- Trail effects behind players
	- Wing attachments
	- Aura effects
	- Title display above head
	- Emote system
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local CosmeticsService = {}

-- ============================================================================
-- COSMETIC DEFINITIONS
-- ============================================================================

local TRAILS = {
	Default = {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 0.5,
		WidthScale = NumberSequence.new(1),
	},
	Spark = {
		Color = ColorSequence.new(Color3.fromRGB(255, 200, 50)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 0.8,
		WidthScale = NumberSequence.new(1.2),
		LightEmission = 0.5,
	},
	Flame = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 0)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 1,
		WidthScale = NumberSequence.new(1.5),
		LightEmission = 0.8,
	},
	Ice = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 240, 255)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 0.6,
		WidthScale = NumberSequence.new(1),
		LightEmission = 0.3,
	},
	Electric = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 0.4,
		WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1.5),
		}),
		LightEmission = 1,
	},
	Rainbow = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 127, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 1.2,
		WidthScale = NumberSequence.new(1.3),
		LightEmission = 0.6,
	},
	Galaxy = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 150)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 100, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 50, 100)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = 1.5,
		WidthScale = NumberSequence.new(1.8),
		LightEmission = 0.7,
	},
	Void = {
		Color = ColorSequence.new(Color3.fromRGB(20, 0, 30)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.8),
		}),
		Lifetime = 2,
		WidthScale = NumberSequence.new(2),
		LightEmission = 0,
	},
}

local WINGS = {
	["Starter Wings"] = {
		MeshId = "rbxassetid://0", -- Replace with actual wing mesh
		TextureId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Offset = Vector3.new(0, 0.5, 0.5),
		Color = Color3.fromRGB(255, 255, 255),
	},
	["Angel Wings"] = {
		MeshId = "rbxassetid://0",
		TextureId = "rbxassetid://0",
		Scale = Vector3.new(1.2, 1.2, 1.2),
		Offset = Vector3.new(0, 0.5, 0.5),
		Color = Color3.fromRGB(255, 255, 255),
		Glow = true,
	},
	["Demon Wings"] = {
		MeshId = "rbxassetid://0",
		TextureId = "rbxassetid://0",
		Scale = Vector3.new(1.3, 1.3, 1.3),
		Offset = Vector3.new(0, 0.5, 0.5),
		Color = Color3.fromRGB(50, 0, 0),
	},
	["Crystal Wings"] = {
		MeshId = "rbxassetid://0",
		TextureId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Offset = Vector3.new(0, 0.5, 0.5),
		Color = Color3.fromRGB(150, 200, 255),
		Transparency = 0.3,
		Glow = true,
	},
	["Void Wings"] = {
		MeshId = "rbxassetid://0",
		TextureId = "rbxassetid://0",
		Scale = Vector3.new(1.5, 1.5, 1.5),
		Offset = Vector3.new(0, 0.5, 0.5),
		Color = Color3.fromRGB(30, 0, 50),
		Particles = true,
	},
}

local AURAS = {
	Shimmer = {
		ParticleSettings = {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 200)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rate = 20,
			Lifetime = NumberRange.new(1, 2),
			Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180),
			LightEmission = 0.5,
		},
	},
	["Dimensional Rift"] = {
		ParticleSettings = {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 0, 150)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 150)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rate = 30,
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(180, 180),
			LightEmission = 0.8,
			RotSpeed = NumberRange.new(-180, 180),
		},
	},
	["Reality Breaker"] = {
		ParticleSettings = {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0)),
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2),
				NumberSequenceKeypoint.new(0.5, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rate = 50,
			Lifetime = NumberRange.new(2, 3),
			Speed = NumberRange.new(3, 8),
			SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1,
			RotSpeed = NumberRange.new(-360, 360),
		},
		PointLight = {
			Color = Color3.fromRGB(255, 200, 100),
			Brightness = 1,
			Range = 8,
		},
	},
}

local TITLES = {
	Newcomer = { Color = Color3.fromRGB(200, 200, 200) },
	["Dimension Jumper"] = { Color = Color3.fromRGB(100, 200, 255) },
	["Reality Bender"] = { Color = Color3.fromRGB(200, 100, 255) },
	["Void Walker"] = { Color = Color3.fromRGB(255, 50, 50) },
	["Sky Dancer"] = { Color = Color3.fromRGB(135, 206, 235) },
	["Dimension Walker"] = { Color = Color3.fromRGB(255, 215, 0) },
	["Multiverse Traveler"] = { Color = Color3.fromRGB(255, 100, 200) },
	["Reality Weaver"] = { Color = Color3.fromRGB(150, 255, 150) },
	["Early Hopper"] = { Color = Color3.fromRGB(255, 200, 100) },
	["Dimension Traveler"] = { Color = Color3.fromRGB(100, 255, 200) },
	["Dimension Expert"] = { Color = Color3.fromRGB(255, 150, 50) },
	["Reality Shifter"] = { Color = Color3.fromRGB(200, 100, 255) },
}

-- ============================================================================
-- STATE
-- ============================================================================

CosmeticsService.PlayerCosmetics = {} -- [UserId] = { trail, wings, aura, title }

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function CosmeticsService.Init()
	print("[CosmeticsService] Initializing...")

	-- Create remotes
	CosmeticsService.CreateRemotes()

	-- Setup player connections
	Players.PlayerAdded:Connect(function(player)
		CosmeticsService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CosmeticsService.OnPlayerLeave(player)
	end)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		CosmeticsService.OnPlayerJoin(player)
	end

	print("[CosmeticsService] Initialized")
end

function CosmeticsService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Cosmetics sync
	if not remoteFolder:FindFirstChild("CosmeticsSync") then
		local event = Instance.new("RemoteEvent")
		event.Name = "CosmeticsSync"
		event.Parent = remoteFolder
	end

	-- Play emote
	if not remoteFolder:FindFirstChild("PlayEmote") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PlayEmote"
		event.Parent = remoteFolder
	end

	CosmeticsService.Remotes = {
		CosmeticsSync = remoteFolder.CosmeticsSync,
		PlayEmote = remoteFolder.PlayEmote,
	}

	-- Handle emote requests
	CosmeticsService.Remotes.PlayEmote.OnServerEvent:Connect(function(player, emoteName)
		CosmeticsService.PlayEmote(player, emoteName)
	end)
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function CosmeticsService.OnPlayerJoin(player: Player)
	CosmeticsService.PlayerCosmetics[player.UserId] = {
		Trail = nil,
		Wings = nil,
		Aura = nil,
		Title = nil,
	}

	player.CharacterAdded:Connect(function(character)
		CosmeticsService.OnCharacterAdded(player, character)
	end)

	if player.Character then
		CosmeticsService.OnCharacterAdded(player, player.Character)
	end
end

function CosmeticsService.OnPlayerLeave(player: Player)
	CosmeticsService.PlayerCosmetics[player.UserId] = nil
end

function CosmeticsService.OnCharacterAdded(player: Player, character: Model)
	-- Wait for character to load
	task.wait(0.5)

	-- Load equipped cosmetics from data
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if DataService then
		local data = DataService.GetData(player)
		if data and data.Equipped then
			if data.Equipped.Trail then
				CosmeticsService.ApplyTrail(player, data.Equipped.Trail)
			end
			if data.Equipped.Wings then
				CosmeticsService.ApplyWings(player, data.Equipped.Wings)
			end
			if data.Equipped.Aura then
				CosmeticsService.ApplyAura(player, data.Equipped.Aura)
			end
			if data.Equipped.Title then
				CosmeticsService.ApplyTitle(player, data.Equipped.Title)
			end
		end
	end
end

-- ============================================================================
-- TRAIL SYSTEM
-- ============================================================================

function CosmeticsService.ApplyTrail(player: Player, trailName: string)
	local character = player.Character
	if not character then return end

	local trailData = TRAILS[trailName]
	if not trailData then return end

	-- Remove existing trail
	CosmeticsService.RemoveTrail(player)

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create trail attachments
	local att0 = Instance.new("Attachment")
	att0.Name = "TrailAttachment0"
	att0.Position = Vector3.new(0, 0.5, 0)
	att0.Parent = rootPart

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailAttachment1"
	att1.Position = Vector3.new(0, -0.5, 0)
	att1.Parent = rootPart

	-- Create trail
	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = trailData.Color
	trail.Transparency = trailData.Transparency
	trail.Lifetime = trailData.Lifetime
	trail.WidthScale = trailData.WidthScale
	trail.LightEmission = trailData.LightEmission or 0
	trail.FaceCamera = true
	trail.Parent = rootPart

	CosmeticsService.PlayerCosmetics[player.UserId].Trail = trail

	print(string.format("[CosmeticsService] Applied trail '%s' to %s", trailName, player.Name))
end

function CosmeticsService.RemoveTrail(player: Player)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Remove attachments and trail
	for _, child in ipairs(rootPart:GetChildren()) do
		if child.Name == "TrailAttachment0" or child.Name == "TrailAttachment1" or child.Name == "PlayerTrail" then
			child:Destroy()
		end
	end

	if CosmeticsService.PlayerCosmetics[player.UserId] then
		CosmeticsService.PlayerCosmetics[player.UserId].Trail = nil
	end
end

-- ============================================================================
-- WINGS SYSTEM
-- ============================================================================

function CosmeticsService.ApplyWings(player: Player, wingsName: string)
	local character = player.Character
	if not character then return end

	local wingsData = WINGS[wingsName]
	if not wingsData then return end

	-- Remove existing wings
	CosmeticsService.RemoveWings(player)

	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then return end

	-- Create wings part
	local wings = Instance.new("Part")
	wings.Name = "PlayerWings"
	wings.Size = Vector3.new(1, 1, 1)
	wings.CanCollide = false
	wings.Massless = true
	wings.Transparency = wingsData.Transparency or 0

	-- Apply mesh if available
	if wingsData.MeshId and wingsData.MeshId ~= "rbxassetid://0" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = wingsData.MeshId
		mesh.TextureId = wingsData.TextureId or ""
		mesh.Scale = wingsData.Scale or Vector3.new(1, 1, 1)
		mesh.Parent = wings
	else
		-- Placeholder wings (simple parts)
		wings.Size = Vector3.new(4, 3, 0.2)
		wings.Color = wingsData.Color or Color3.fromRGB(255, 255, 255)
		wings.Material = Enum.Material.SmoothPlastic
	end

	-- Weld to torso
	local weld = Instance.new("Weld")
	weld.Part0 = torso
	weld.Part1 = wings
	weld.C0 = CFrame.new(wingsData.Offset or Vector3.new(0, 0.5, 0.5))
	weld.Parent = wings

	-- Add glow if specified
	if wingsData.Glow then
		local light = Instance.new("PointLight")
		light.Color = wingsData.Color or Color3.fromRGB(255, 255, 255)
		light.Brightness = 0.5
		light.Range = 6
		light.Parent = wings
	end

	-- Add particles if specified
	if wingsData.Particles then
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(wingsData.Color or Color3.fromRGB(255, 255, 255))
		particles.Size = NumberSequence.new(0.3)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.Rate = 10
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Speed = NumberRange.new(1, 2)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.Parent = wings
	end

	wings.Parent = character

	CosmeticsService.PlayerCosmetics[player.UserId].Wings = wings

	print(string.format("[CosmeticsService] Applied wings '%s' to %s", wingsName, player.Name))
end

function CosmeticsService.RemoveWings(player: Player)
	local character = player.Character
	if not character then return end

	local wings = character:FindFirstChild("PlayerWings")
	if wings then
		wings:Destroy()
	end

	if CosmeticsService.PlayerCosmetics[player.UserId] then
		CosmeticsService.PlayerCosmetics[player.UserId].Wings = nil
	end
end

-- ============================================================================
-- AURA SYSTEM
-- ============================================================================

function CosmeticsService.ApplyAura(player: Player, auraName: string)
	local character = player.Character
	if not character then return end

	local auraData = AURAS[auraName]
	if not auraData then return end

	-- Remove existing aura
	CosmeticsService.RemoveAura(player)

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create aura container
	local auraFolder = Instance.new("Folder")
	auraFolder.Name = "PlayerAura"
	auraFolder.Parent = character

	-- Create particle emitter
	if auraData.ParticleSettings then
		local particles = Instance.new("ParticleEmitter")

		for property, value in pairs(auraData.ParticleSettings) do
			pcall(function()
				particles[property] = value
			end)
		end

		particles.Parent = rootPart
		particles.Name = "AuraParticles"
	end

	-- Create point light if specified
	if auraData.PointLight then
		local light = Instance.new("PointLight")
		light.Name = "AuraLight"
		light.Color = auraData.PointLight.Color
		light.Brightness = auraData.PointLight.Brightness
		light.Range = auraData.PointLight.Range
		light.Parent = rootPart
	end

	CosmeticsService.PlayerCosmetics[player.UserId].Aura = auraFolder

	print(string.format("[CosmeticsService] Applied aura '%s' to %s", auraName, player.Name))
end

function CosmeticsService.RemoveAura(player: Player)
	local character = player.Character
	if not character then return end

	-- Remove aura folder
	local auraFolder = character:FindFirstChild("PlayerAura")
	if auraFolder then
		auraFolder:Destroy()
	end

	-- Remove particles from root part
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local particles = rootPart:FindFirstChild("AuraParticles")
		if particles then particles:Destroy() end

		local light = rootPart:FindFirstChild("AuraLight")
		if light then light:Destroy() end
	end

	if CosmeticsService.PlayerCosmetics[player.UserId] then
		CosmeticsService.PlayerCosmetics[player.UserId].Aura = nil
	end
end

-- ============================================================================
-- TITLE SYSTEM
-- ============================================================================

function CosmeticsService.ApplyTitle(player: Player, titleName: string)
	local character = player.Character
	if not character then return end

	local titleData = TITLES[titleName]
	if not titleData then return end

	-- Remove existing title
	CosmeticsService.RemoveTitle(player)

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Create title billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerTitle"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 50
	billboard.Parent = head

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleText"
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = titleName
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = titleData.Color or Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.Parent = billboard

	CosmeticsService.PlayerCosmetics[player.UserId].Title = billboard

	print(string.format("[CosmeticsService] Applied title '%s' to %s", titleName, player.Name))
end

function CosmeticsService.RemoveTitle(player: Player)
	local character = player.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	if head then
		local billboard = head:FindFirstChild("PlayerTitle")
		if billboard then
			billboard:Destroy()
		end
	end

	if CosmeticsService.PlayerCosmetics[player.UserId] then
		CosmeticsService.PlayerCosmetics[player.UserId].Title = nil
	end
end

-- ============================================================================
-- EMOTES
-- ============================================================================

function CosmeticsService.PlayEmote(player: Player, emoteName: string)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Verify player has emote unlocked
	local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
	if DataService then
		if not DataService.HasUnlock(player, "Emote", emoteName) then
			return
		end
	end

	-- Play animation (would load actual emote animations)
	-- For now, just broadcast to other clients
	CosmeticsService.Remotes.PlayEmote:FireAllClients(player, emoteName)

	print(string.format("[CosmeticsService] %s played emote: %s", player.Name, emoteName))
end

-- ============================================================================
-- EQUIPMENT CHANGES
-- ============================================================================

function CosmeticsService.OnCosmeticEquipped(player: Player, category: string, itemId: string?)
	if category == "Trail" then
		if itemId then
			CosmeticsService.ApplyTrail(player, itemId)
		else
			CosmeticsService.RemoveTrail(player)
		end

	elseif category == "Wings" then
		if itemId then
			CosmeticsService.ApplyWings(player, itemId)
		else
			CosmeticsService.RemoveWings(player)
		end

	elseif category == "Aura" then
		if itemId then
			CosmeticsService.ApplyAura(player, itemId)
		else
			CosmeticsService.RemoveAura(player)
		end

	elseif category == "Title" then
		if itemId then
			CosmeticsService.ApplyTitle(player, itemId)
		else
			CosmeticsService.RemoveTitle(player)
		end
	end
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function CosmeticsService.GetAvailableCosmetics(): table
	return {
		Trails = TRAILS,
		Wings = WINGS,
		Auras = AURAS,
		Titles = TITLES,
	}
end

return CosmeticsService
