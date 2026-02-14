--[[
	TutorialService.lua
	Interactive tutorial system for new players

	Features:
	- Step-by-step onboarding
	- Interactive prompts
	- Progress tracking
	- Rewards for completion
	- Skipable (with confirmation)

	Created: Week 15 - Enhanced Onboarding
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TutorialService = {}
TutorialService.Enabled = true

-- Configuration
local CONFIG = {
	TutorialSteps = {
		{
			Id = "Welcome",
			Title = "Welcome to Tower Ascent!",
			Description = "Learn the basics in just 2 minutes",
			Action = "ShowWelcomeUI",
			Reward = {Coins = 100},
		},
		{
			Id = "Movement",
			Title = "Basic Movement",
			Description = "Use WASD to move and SPACE to jump",
			Action = "WaitForJump",
			Reward = {Coins = 50},
		},
		{
			Id = "FirstCheckpoint",
			Title = "Reach Your First Checkpoint",
			Description = "Checkpoints save your progress!",
			Action = "WaitForCheckpoint",
			Reward = {Coins = 100},
		},
		{
			Id = "Coins",
			Title = "Collect Coins",
			Description = "Coins unlock upgrades!",
			Action = "WaitForCoinCollection",
			Reward = {Coins = 50},
		},
		{
			Id = "Upgrades",
			Title = "Visit the Upgrade Shop",
			Description = "Upgrade your abilities to climb faster",
			Action = "WaitForShopVisit",
			Reward = {Coins = 200},
		},
		{
			Id = "Complete",
			Title = "Tutorial Complete!",
			Description = "You're ready to climb!",
			Action = "ShowCompletionUI",
			Reward = {Coins = 500, Pet = "TutorialPet"},
		},
	},

	TotalReward = {
		Coins = 1000,
		Pet = "TutorialPet",
	},

	SkipConfirmation = true,
}

-- Active tutorials
local activeTutorials = {} -- [userId] = {CurrentStep, Completed}

-- Remote events
local Events = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function TutorialService.Init()
	print("[TutorialService] Initializing...")

	-- Create remote events
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end

	local tutorialEvent = eventsFolder:FindFirstChild("TutorialEvent")
	if not tutorialEvent then
		tutorialEvent = Instance.new("RemoteEvent")
		tutorialEvent.Name = "TutorialEvent"
		tutorialEvent.Parent = eventsFolder
	end

	Events = {
		Tutorial = tutorialEvent,
	}

	-- Connect player events
	Players.PlayerAdded:Connect(function(player)
		TutorialService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		TutorialService.OnPlayerLeave(player)
	end)

	-- Connect remote events
	Events.Tutorial.OnServerEvent:Connect(function(player, action, ...)
		-- SECURITY: Validate action is a string
		if type(action) ~= "string" then return end

		if action == "SkipTutorial" then
			TutorialService.SkipTutorial(player)
		elseif action == "NextStep" then
			TutorialService.NextStep(player)
		end
	end)

	print("[TutorialService] Initialized successfully")
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function TutorialService.OnPlayerJoin(player: Player)
	if not TutorialService.Enabled then return end

	-- Check if player has completed tutorial
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if not DataService then
		warn("[TutorialService] DataService not available")
		return
	end

	local profile = DataService.GetProfile(player)
	if not profile or not profile.Data then return end

	-- Skip tutorial if already completed
	if profile.Data.TutorialCompleted then
		return
	end

	-- Start tutorial
	task.delay(2, function()
		TutorialService.StartTutorial(player)
	end)
end

function TutorialService.OnPlayerLeave(player: Player)
	-- Cleanup
	activeTutorials[player.UserId] = nil
end

-- ============================================================================
-- TUTORIAL FLOW
-- ============================================================================

function TutorialService.StartTutorial(player: Player)
	if not TutorialService.Enabled then return end

	-- Initialize tutorial state
	activeTutorials[player.UserId] = {
		CurrentStep = 1,
		Completed = false,
		StartTime = tick(),
	}

	print(string.format("[TutorialService] Starting tutorial for %s", player.Name))

	-- Show first step
	TutorialService.ShowStep(player, 1)
end

function TutorialService.ShowStep(player: Player, stepIndex: number)
	local step = CONFIG.TutorialSteps[stepIndex]
	if not step then return end

	-- Send to client
	Events.Tutorial:FireClient(player, "ShowStep", {
		StepIndex = stepIndex,
		TotalSteps = #CONFIG.TutorialSteps,
		Step = step,
	})

	-- Execute step action
	if step.Action == "ShowWelcomeUI" then
		-- Client handles UI
	elseif step.Action == "WaitForJump" then
		TutorialService.WaitForPlayerJump(player)
	elseif step.Action == "WaitForCheckpoint" then
		TutorialService.WaitForCheckpoint(player)
	elseif step.Action == "WaitForCoinCollection" then
		TutorialService.WaitForCoinCollection(player)
	elseif step.Action == "WaitForShopVisit" then
		TutorialService.WaitForShopVisit(player)
	elseif step.Action == "ShowCompletionUI" then
		TutorialService.CompleteTutorial(player)
	end
end

function TutorialService.NextStep(player: Player)
	local tutorial = activeTutorials[player.UserId]
	if not tutorial then return end

	local currentStep = CONFIG.TutorialSteps[tutorial.CurrentStep]
	if not currentStep then return end

	-- Award reward for completing step
	TutorialService.GiveStepReward(player, currentStep)

	-- Move to next step
	tutorial.CurrentStep = tutorial.CurrentStep + 1

	if tutorial.CurrentStep > #CONFIG.TutorialSteps then
		-- Tutorial complete
		TutorialService.CompleteTutorial(player)
	else
		-- Show next step
		TutorialService.ShowStep(player, tutorial.CurrentStep)
	end
end

function TutorialService.SkipTutorial(player: Player)
	local tutorial = activeTutorials[player.UserId]
	if not tutorial then return end

	print(string.format("[TutorialService] %s skipped tutorial", player.Name))

	-- Mark as completed (no rewards)
	activeTutorials[player.UserId] = nil

	-- Update data
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService then
		local profile = DataService.GetProfile(player)
		if profile and profile.Data then
			profile.Data.TutorialCompleted = true
			profile.Data.TutorialSkipped = true
		end
	end

	-- Notify client
	Events.Tutorial:FireClient(player, "TutorialSkipped")
end

function TutorialService.CompleteTutorial(player: Player)
	local tutorial = activeTutorials[player.UserId]
	if not tutorial then return end

	tutorial.Completed = true

	print(string.format("[TutorialService] %s completed tutorial", player.Name))

	-- Award completion rewards
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService

	if DataService then
		local profile = DataService.GetProfile(player)
		if profile and profile.Data then
			profile.Data.TutorialCompleted = true
			profile.Data.TutorialCompletedAt = tick()
			profile.Data.TutorialDuration = tick() - tutorial.StartTime
		end
	end

	if CoinService then
		CoinService.AddCoins(player, CONFIG.TotalReward.Coins)
	end

	-- Notify client
	Events.Tutorial:FireClient(player, "TutorialComplete", {
		Rewards = CONFIG.TotalReward,
		Duration = tick() - tutorial.StartTime,
	})

	-- Cleanup
	activeTutorials[player.UserId] = nil
end

-- ============================================================================
-- STEP ACTIONS
-- ============================================================================

function TutorialService.WaitForPlayerJump(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	local jumpConnection
	jumpConnection = humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			jumpConnection:Disconnect()
			task.wait(0.5)
			TutorialService.NextStep(player)
		end
	end)
end

function TutorialService.WaitForCheckpoint(player: Player)
	-- CheckpointService will trigger this
	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if not CheckpointService then return end

	-- Create temporary listener
	local tutorial = activeTutorials[player.UserId]
	if not tutorial then return end

	tutorial.CheckpointListener = function(plr)
		if plr == player then
			task.wait(1)
			TutorialService.NextStep(player)
		end
	end

	-- Hook into checkpoint event (would need CheckpointService.OnCheckpointReached signal)
end

function TutorialService.WaitForCoinCollection(player: Player)
	-- CoinService will trigger this
	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then return end

	local tutorial = activeTutorials[player.UserId]
	if not tutorial then return end

	tutorial.CoinListener = function(plr)
		if plr == player then
			task.wait(1)
			TutorialService.NextStep(player)
		end
	end
end

function TutorialService.WaitForShopVisit(player: Player)
	-- UpgradeService will trigger this when shop is opened
	local UpgradeService = _G.TowerAscent and _G.TowerAscent.UpgradeService
	if not UpgradeService then return end

	local tutorial = activeTutorials[player.UserId]
	if not tutorial then return end

	tutorial.ShopListener = function(plr)
		if plr == player then
			task.wait(1)
			TutorialService.NextStep(player)
		end
	end
end

-- ============================================================================
-- REWARDS
-- ============================================================================

function TutorialService.GiveStepReward(player: Player, step)
	if not step.Reward then return end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService

	if step.Reward.Coins and CoinService then
		CoinService.AddCoins(player, step.Reward.Coins)
	end

	-- Other rewards (pets, cosmetics, etc.) can be added here
end

-- ============================================================================
-- ADMIN/DEBUG
-- ============================================================================

function TutorialService.RestartTutorial(player: Player)
	-- Reset tutorial progress
	activeTutorials[player.UserId] = nil

	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService then
		local profile = DataService.GetProfile(player)
		if profile and profile.Data then
			profile.Data.TutorialCompleted = false
		end
	end

	TutorialService.StartTutorial(player)
end

function TutorialService.GetTutorialProgress(player: Player)
	return activeTutorials[player.UserId]
end

-- ============================================================================
-- GLOBAL ACCESS
-- ============================================================================

return TutorialService
