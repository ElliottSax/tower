--[[
	DialogueService.lua
	Manages NPC dialogues and player choices

	Handles:
	- Dialogue progression
	- Choice validation
	- Dialogue history tracking
	- Relationship changes
	- Quest triggers from dialogues
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NPCDialogues = require(ReplicatedStorage.Shared.Data.NPCDialogues)
local StoryConfig = require(ReplicatedStorage.Shared.Config.StoryConfig)

local DialogueService = {}
local DataService = nil -- Lazy loaded
local StoryService = nil
local QuestService = nil

-- Active dialogue sessions
-- Format: [Player] = {NPC = "NPCName", CurrentDialogueId = "DialogueId"}
local ActiveDialogues = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function DialogueService.Init()
	print("[DialogueService] Initializing...")

	-- Lazy load services
	DataService = require(ServerScriptService.Services.DataService)
	StoryService = require(ServerScriptService.Services.StoryService)

	-- Setup remote handlers
	DialogueService.SetupRemoteHandlers()

	print("[DialogueService] Initialized")
end

-- ============================================================================
-- DIALOGUE MANAGEMENT
-- ============================================================================

function DialogueService.StartDialogue(player: Player, npcName: string)
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[DialogueService] Invalid player in StartDialogue")
		return nil
	end

	-- Validate NPC
	if not NPCDialogues[npcName] then
		warn("[DialogueService] Invalid NPC:", npcName)
		return nil
	end

	-- Get player data
	local profile = DataService.GetProfile(player)
	if not profile then
		warn("[DialogueService] No profile found for player:", player.Name)
		return nil
	end

	-- Determine starting dialogue
	local startDialogueId = DialogueService.GetStartingDialogue(player, npcName)

	-- Create dialogue session
	ActiveDialogues[player] = {
		NPC = npcName,
		CurrentDialogueId = startDialogueId,
	}

	-- Track dialogue history
	profile.Data.Story.DialogueHistory[npcName] = (profile.Data.Story.DialogueHistory[npcName] or 0) + 1

	-- Increase relationship
	StoryService.IncreaseRelationship(player, npcName, StoryConfig.Dialogue.RelationshipGain.NeutralChoice)

	-- Get dialogue data
	local dialogueData = NPCDialogues[npcName][startDialogueId]

	print(string.format("[DialogueService] %s started dialogue with %s (%s)",
		player.Name, npcName, startDialogueId))

	return {
		NPC = npcName,
		DialogueId = startDialogueId,
		Text = dialogueData.Text,
		Choices = dialogueData.Choices,
	}
end

function DialogueService.GetStartingDialogue(player: Player, npcName: string): string
	local profile = DataService.GetProfile(player)
	if not profile then return "Welcome" end

	-- Check dialogue history
	local timesSpoken = profile.Data.Story.DialogueHistory[npcName] or 0

	-- First time speaking
	if timesSpoken == 0 then
		return "Welcome"
	end

	-- Check for quest completion dialogues
	-- (Could be extended to check quest states)

	-- Default to repeat dialogue
	return "Repeat"
end

function DialogueService.MakeChoice(player: Player, choiceIndex: number)
	-- Validate player
	if not player or not player:IsA("Player") then
		warn("[DialogueService] Invalid player in MakeChoice")
		return nil
	end

	-- Get active dialogue
	local session = ActiveDialogues[player]
	if not session then
		warn("[DialogueService] No active dialogue for player:", player.Name)
		return nil
	end

	-- Get current dialogue
	local dialogueData = NPCDialogues[session.NPC][session.CurrentDialogueId]
	if not dialogueData then
		warn("[DialogueService] Invalid dialogue data:", session.CurrentDialogueId)
		return nil
	end

	-- Validate choice
	if not dialogueData.Choices or choiceIndex < 1 or choiceIndex > #dialogueData.Choices then
		warn("[DialogueService] Invalid choice index:", choiceIndex)
		return nil
	end

	local choice = dialogueData.Choices[choiceIndex]

	-- Execute OnComplete callback if exists
	if dialogueData.OnComplete then
		local result = dialogueData.OnComplete(player)

		-- Handle quest triggers
		if result == "CollectFragments" then
			-- Quest will be handled by QuestService
			QuestService = QuestService or require(ServerScriptService.Services.QuestService)
			QuestService.StartQuest(player, "CollectFragments")
		elseif result == "OpenShop" then
			-- Shop opening handled client-side
		end
	end

	-- Get next dialogue
	local nextDialogueId = choice.NextId

	-- If nil, end dialogue
	if not nextDialogueId then
		ActiveDialogues[player] = nil
		print(string.format("[DialogueService] %s ended dialogue with %s",
			player.Name, session.NPC))
		return {
			DialogueId = nil,
			Text = nil,
			Choices = nil,
			Ended = true,
		}
	end

	-- Update session
	session.CurrentDialogueId = nextDialogueId

	-- Get next dialogue data
	local nextDialogueData = NPCDialogues[session.NPC][nextDialogueId]

	return {
		NPC = session.NPC,
		DialogueId = nextDialogueId,
		Text = nextDialogueData.Text,
		Choices = nextDialogueData.Choices,
		Ended = false,
	}
end

function DialogueService.EndDialogue(player: Player)
	ActiveDialogues[player] = nil
	print(string.format("[DialogueService] Dialogue ended for %s", player.Name))
end

-- ============================================================================
-- DIALOGUE STATE
-- ============================================================================

function DialogueService.GetActiveDialogue(player: Player)
	return ActiveDialogues[player]
end

function DialogueService.HasActiveDialogue(player: Player): boolean
	return ActiveDialogues[player] ~= nil
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

function DialogueService.SetupRemoteHandlers()
	local RemoteEventsInit = require(ServerScriptService.Utilities.RemoteEventsInit)

	-- StartDialogue
	local startDialogueRemote = RemoteEventsInit.GetRemote("StartDialogue")
	if startDialogueRemote and startDialogueRemote.Remote then
		startDialogueRemote.Remote.OnServerInvoke = function(player, npcName)
			return DialogueService.StartDialogue(player, npcName)
		end
	end

	-- MakeChoice
	local makeChoiceRemote = RemoteEventsInit.GetRemote("MakeChoice")
	if makeChoiceRemote and makeChoiceRemote.Remote then
		makeChoiceRemote.Remote.OnServerInvoke = function(player, choiceIndex)
			return DialogueService.MakeChoice(player, choiceIndex)
		end
	end

	-- EndDialogue
	local endDialogueRemote = RemoteEventsInit.GetRemote("EndDialogue")
	if endDialogueRemote and endDialogueRemote.Remote then
		endDialogueRemote.Remote.OnServerEvent:Connect(function(player)
			DialogueService.EndDialogue(player)
		end)
	end

	print("[DialogueService] Remote handlers setup complete")
end

return DialogueService
