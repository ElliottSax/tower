--[[
	NPCService.lua
	Manages NPC spawning and interactions

	Handles:
	- NPC spawning in worlds
	- ProximityPrompt setup
	- Interaction detection
	- NPC state management
--]]

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local StoryConfig = require(ReplicatedStorage.Shared.Config.StoryConfig)

local NPCService = {}
local DialogueService = nil -- Lazy loaded

-- Active NPCs
-- Format: [NPCName] = NPCModel
local ActiveNPCs = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function NPCService.Init()
	print("[NPCService] Initializing...")

	-- Lazy load DialogueService
	DialogueService = require(ServerScriptService.Services.DialogueService)

	-- Spawn hub NPCs
	NPCService.SpawnHubNPCs()

	print("[NPCService] Initialized")
end

-- ============================================================================
-- NPC SPAWNING
-- ============================================================================

function NPCService.SpawnHubNPCs()
	-- Spawn NPCs in the hub world
	for npcName, npcConfig in pairs(StoryConfig.NPCs) do
		NPCService.SpawnNPC(npcName, npcConfig)
	end
end

function NPCService.SpawnNPC(npcName: string, npcConfig: {})
	-- Find spawn location
	local spawnLocation = Workspace:FindFirstChild(npcConfig.SpawnLocation, true)
	if not spawnLocation then
		warn(string.format("[NPCService] Spawn location not found for %s: %s",
			npcName, npcConfig.SpawnLocation))
		return
	end

	-- Try to find NPC model in ServerStorage
	local npcTemplate = ServerStorage.NPCs:FindFirstChild(npcName)
	if not npcTemplate then
		-- Create basic NPC model if not found
		npcTemplate = NPCService.CreateBasicNPC(npcName, npcConfig)
	end

	-- Clone and position NPC
	local npc = npcTemplate:Clone()
	npc.Name = npcName
	npc:SetPrimaryPartCFrame(spawnLocation.CFrame)
	npc.Parent = Workspace

	-- Setup interaction
	NPCService.SetupNPCInteraction(npc, npcName, npcConfig)

	-- Store reference
	ActiveNPCs[npcName] = npc

	print(string.format("[NPCService] Spawned NPC: %s at %s", npcName, npcConfig.SpawnLocation))
end

function NPCService.CreateBasicNPC(npcName: string, npcConfig: {}): Model
	-- Create a basic NPC model (fallback if no model exists)
	local npc = Instance.new("Model")
	npc.Name = npcName

	-- Create humanoid root part
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Transparency = 0.5
	rootPart.BrickColor = BrickColor.new("Bright blue")
	rootPart.Parent = npc

	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Anchored = true
	head.BrickColor = BrickColor.new("Light orange")
	head.Position = rootPart.Position + Vector3.new(0, 1.5, 0)
	head.Parent = npc

	-- Add face
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	-- Add name tag
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcConfig.Name or npcName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = billboard

	npc.PrimaryPart = rootPart

	return npc
end

-- ============================================================================
-- INTERACTION
-- ============================================================================

function NPCService.SetupNPCInteraction(npc: Model, npcName: string, npcConfig: {})
	-- Find or create interaction part
	local interactionPart = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
	if not interactionPart then
		warn("[NPCService] No interaction part found for NPC:", npcName)
		return
	end

	-- Create ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk to " .. (npcConfig.Name or npcName)
	prompt.ObjectText = npcConfig.Description or ""
	prompt.MaxActivationDistance = npcConfig.InteractionRange or 10
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = interactionPart

	-- Connect interaction
	prompt.Triggered:Connect(function(player)
		NPCService.OnNPCInteract(player, npcName)
	end)

	print(string.format("[NPCService] Setup interaction for %s", npcName))
end

function NPCService.OnNPCInteract(player: Player, npcName: string)
	print(string.format("[NPCService] %s interacted with %s", player.Name, npcName))

	-- Start dialogue
	DialogueService.StartDialogue(player, npcName)

	-- Fire remote to open dialogue UI
	local remoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)
	local npcInteractRemote = remoteEventsInit.GetRemote("NPCInteract")
	if npcInteractRemote and npcInteractRemote.Remote then
		npcInteractRemote.Remote:FireClient(player, npcName)
	end
end

-- ============================================================================
-- NPC MANAGEMENT
-- ============================================================================

function NPCService.GetNPC(npcName: string): Model?
	return ActiveNPCs[npcName]
end

function NPCService.DespawnNPC(npcName: string)
	local npc = ActiveNPCs[npcName]
	if npc then
		npc:Destroy()
		ActiveNPCs[npcName] = nil
		print(string.format("[NPCService] Despawned NPC: %s", npcName))
	end
end

return NPCService
