--[[
	TutorialService.lua
	Manages interactive tutorials for each dimension

	Features:
	- First-time player detection
	- Step-by-step guidance for each dimension
	- Progress tracking
	- Skip option for experienced players
	- Rewards for tutorial completion
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local TutorialService = {}

-- ============================================================================
-- TUTORIAL DEFINITIONS
-- ============================================================================

TutorialService.Tutorials = {
	-- General game tutorial
	Basics = {
		Name = "Basics",
		RewardXP = 50,
		Steps = {
			{
				id = "welcome",
				title = "Welcome to Dimension Hopper!",
				description = "Race through mind-bending dimensions to reach the finish line first!",
				highlight = nil,
				action = "continue",
			},
			{
				id = "movement",
				title = "Movement",
				description = "Use WASD to move and SPACE to jump. Master your movement to navigate obstacles!",
				highlight = nil,
				action = "jump", -- Wait for player to jump
			},
			{
				id = "checkpoints",
				title = "Checkpoints",
				description = "Touch glowing platforms to save your progress. You'll respawn here if you fall!",
				highlight = "Checkpoint",
				action = "checkpoint", -- Wait for checkpoint touch
			},
			{
				id = "finish",
				title = "Finish Line",
				description = "Race to the golden finish line to complete the dimension!",
				highlight = "FinishLine",
				action = "continue",
			},
		},
	},

	-- Gravity dimension tutorial
	Gravity = {
		Name = "Gravity Dimension",
		RewardXP = 75,
		Steps = {
			{
				id = "intro",
				title = "Gravity Dimension",
				description = "In this dimension, gravity can flip in any direction! Watch for purple zones.",
				highlight = nil,
				action = "continue",
			},
			{
				id = "flip_zones",
				title = "Gravity Flip Zones",
				description = "Purple zones will flip your gravity. You might walk on walls or ceilings!",
				highlight = "GravityFlip",
				action = "continue",
			},
			{
				id = "try_flip",
				title = "Try It!",
				description = "Enter a gravity flip zone to experience the shift. Stay oriented!",
				highlight = "GravityFlip",
				action = "gravityflip", -- Wait for gravity flip
			},
			{
				id = "orientation",
				title = "Stay Oriented",
				description = "Your camera will adjust, but pay attention to where 'down' is now!",
				highlight = nil,
				action = "continue",
			},
		},
	},

	-- Tiny dimension tutorial
	Tiny = {
		Name = "Tiny Dimension",
		RewardXP = 75,
		Steps = {
			{
				id = "intro",
				title = "Tiny Dimension",
				description = "In this dimension, you'll shrink to navigate giant everyday objects!",
				highlight = nil,
				action = "continue",
			},
			{
				id = "shrink_zones",
				title = "Shrink Zones",
				description = "Green zones will shrink you. Everything around you becomes massive!",
				highlight = "ShrinkZone",
				action = "continue",
			},
			{
				id = "perspective",
				title = "New Perspective",
				description = "When small, gaps become chasms and objects become mountains. Plan your path!",
				highlight = nil,
				action = "continue",
			},
			{
				id = "grow_back",
				title = "Returning to Normal",
				description = "Some zones will grow you back. Watch for the transition!",
				highlight = "GrowZone",
				action = "continue",
			},
		},
	},

	-- Void dimension tutorial
	Void = {
		Name = "Void Dimension",
		RewardXP = 100,
		Steps = {
			{
				id = "intro",
				title = "Void Dimension",
				description = "DANGER! The void is chasing you. Keep moving or be consumed!",
				highlight = nil,
				action = "continue",
			},
			{
				id = "void_chase",
				title = "The Void",
				description = "A wall of darkness follows you. If it catches you, you'll respawn!",
				highlight = nil,
				action = "continue",
			},
			{
				id = "crumbling",
				title = "Crumbling Platforms",
				description = "Platforms here crumble after you stand on them. Don't stay too long!",
				highlight = "CrumblingPlatform",
				action = "continue",
			},
			{
				id = "safe_zones",
				title = "Safe Zones",
				description = "Bright areas slow the void. Use them to catch your breath!",
				highlight = "SafeZone",
				action = "continue",
			},
			{
				id = "speed",
				title = "Keep Moving!",
				description = "Speed is survival. Find the fastest path and don't look back!",
				highlight = nil,
				action = "continue",
			},
		},
	},

	-- Sky dimension tutorial
	Sky = {
		Name = "Sky Dimension",
		RewardXP = 100,
		Steps = {
			{
				id = "intro",
				title = "Sky Dimension",
				description = "Take to the skies! Use your glider to soar between cloud platforms.",
				highlight = nil,
				action = "continue",
			},
			{
				id = "glider",
				title = "Glider Controls",
				description = "Hold SPACE while falling to deploy your glider. Release to retract.",
				highlight = nil,
				action = "glider", -- Wait for glider deploy
			},
			{
				id = "boost",
				title = "Glider Boost",
				description = "Press SHIFT while gliding for a speed boost. Watch your boost meter!",
				highlight = nil,
				action = "continue",
			},
			{
				id = "updrafts",
				title = "Updrafts",
				description = "Fly through updrafts to gain height and refill your boost!",
				highlight = "Updraft",
				action = "continue",
			},
			{
				id = "wind",
				title = "Wind Currents",
				description = "Blue streams are wind currents. They'll push you - use them wisely!",
				highlight = "WindCurrent",
				action = "continue",
			},
			{
				id = "clouds",
				title = "Cloud Platforms",
				description = "Land on clouds to rest. But beware - some are fake and you'll fall through!",
				highlight = nil,
				action = "continue",
			},
		},
	},
}

-- ============================================================================
-- STATE
-- ============================================================================

-- [UserId] = { currentTutorial, currentStep, completedTutorials }
TutorialService.PlayerProgress = {}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function TutorialService.Init()
	print("[TutorialService] Initializing...")

	TutorialService.CreateRemotes()

	Players.PlayerAdded:Connect(function(player)
		TutorialService.OnPlayerJoin(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		TutorialService.OnPlayerLeave(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		TutorialService.OnPlayerJoin(player)
	end

	print("[TutorialService] Initialized")
end

function TutorialService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Tutorial step sync
	if not remoteFolder:FindFirstChild("TutorialStep") then
		local event = Instance.new("RemoteEvent")
		event.Name = "TutorialStep"
		event.Parent = remoteFolder
	end

	-- Tutorial action (client reports completing an action)
	if not remoteFolder:FindFirstChild("TutorialAction") then
		local event = Instance.new("RemoteEvent")
		event.Name = "TutorialAction"
		event.Parent = remoteFolder
	end

	-- Skip tutorial
	if not remoteFolder:FindFirstChild("SkipTutorial") then
		local event = Instance.new("RemoteEvent")
		event.Name = "SkipTutorial"
		event.Parent = remoteFolder
	end

	-- Get tutorial status
	if not remoteFolder:FindFirstChild("GetTutorialStatus") then
		local func = Instance.new("RemoteFunction")
		func.Name = "GetTutorialStatus"
		func.Parent = remoteFolder
	end

	TutorialService.Remotes = {
		TutorialStep = remoteFolder.TutorialStep,
		TutorialAction = remoteFolder.TutorialAction,
		SkipTutorial = remoteFolder.SkipTutorial,
		GetTutorialStatus = remoteFolder.GetTutorialStatus,
	}

	-- Connect handlers
	TutorialService.Remotes.TutorialAction.OnServerEvent:Connect(function(player, action)
		TutorialService.OnPlayerAction(player, action)
	end)

	TutorialService.Remotes.SkipTutorial.OnServerEvent:Connect(function(player, tutorialName)
		TutorialService.SkipTutorial(player, tutorialName)
	end)

	TutorialService.Remotes.GetTutorialStatus.OnServerInvoke = function(player)
		return TutorialService.GetPlayerStatus(player)
	end
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function TutorialService.OnPlayerJoin(player: Player)
	TutorialService.PlayerProgress[player.UserId] = {
		currentTutorial = nil,
		currentStep = 0,
		completedTutorials = {},
	}

	-- Load completed tutorials from DataService
	TutorialService.LoadPlayerProgress(player)
end

function TutorialService.OnPlayerLeave(player: Player)
	-- Save progress before clearing
	TutorialService.SavePlayerProgress(player)
	TutorialService.PlayerProgress[player.UserId] = nil
end

function TutorialService.LoadPlayerProgress(player: Player)
	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if not DataService or not DataService.GetData then return end

	local data = DataService.GetData(player)
	if data and data.CompletedTutorials then
		local progress = TutorialService.PlayerProgress[player.UserId]
		if progress then
			progress.completedTutorials = data.CompletedTutorials
		end
	end
end

function TutorialService.SavePlayerProgress(player: Player)
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress then return end

	local DimensionHopper = _G.DimensionHopper
	if not DimensionHopper then return end

	local DataService = DimensionHopper.GetService("DataService")
	if DataService and DataService.UpdateData then
		DataService.UpdateData(player, {
			CompletedTutorials = progress.completedTutorials,
		})
	end
end

-- ============================================================================
-- TUTORIAL FLOW
-- ============================================================================

function TutorialService.StartTutorial(player: Player, tutorialName: string): boolean
	local tutorial = TutorialService.Tutorials[tutorialName]
	if not tutorial then
		warn("[TutorialService] Unknown tutorial: " .. tutorialName)
		return false
	end

	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress then return false end

	-- Check if already completed
	if progress.completedTutorials[tutorialName] then
		return false -- Already done
	end

	-- Check if already in a tutorial
	if progress.currentTutorial then
		return false
	end

	progress.currentTutorial = tutorialName
	progress.currentStep = 1

	-- Send first step to client
	TutorialService.SendCurrentStep(player)

	print(string.format("[TutorialService] %s started tutorial: %s", player.Name, tutorialName))
	return true
end

function TutorialService.SendCurrentStep(player: Player)
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress or not progress.currentTutorial then return end

	local tutorial = TutorialService.Tutorials[progress.currentTutorial]
	if not tutorial then return end

	local step = tutorial.Steps[progress.currentStep]
	if not step then
		-- Tutorial complete
		TutorialService.CompleteTutorial(player)
		return
	end

	TutorialService.Remotes.TutorialStep:FireClient(player, {
		tutorialName = progress.currentTutorial,
		stepNumber = progress.currentStep,
		totalSteps = #tutorial.Steps,
		step = step,
	})
end

function TutorialService.AdvanceStep(player: Player)
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress or not progress.currentTutorial then return end

	progress.currentStep = progress.currentStep + 1
	TutorialService.SendCurrentStep(player)
end

function TutorialService.OnPlayerAction(player: Player, action: string)
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress or not progress.currentTutorial then return end

	local tutorial = TutorialService.Tutorials[progress.currentTutorial]
	if not tutorial then return end

	local step = tutorial.Steps[progress.currentStep]
	if not step then return end

	-- Check if action matches required action
	if step.action == action or step.action == "continue" then
		TutorialService.AdvanceStep(player)
	end
end

function TutorialService.CompleteTutorial(player: Player)
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress or not progress.currentTutorial then return end

	local tutorialName = progress.currentTutorial
	local tutorial = TutorialService.Tutorials[tutorialName]

	-- Mark as completed
	progress.completedTutorials[tutorialName] = true
	progress.currentTutorial = nil
	progress.currentStep = 0

	-- Award XP
	if tutorial.RewardXP then
		local DimensionHopper = _G.DimensionHopper
		if DimensionHopper then
			local DataService = DimensionHopper.GetService("DataService")
			if DataService and DataService.AddXP then
				DataService.AddXP(player, tutorial.RewardXP)
			end
		end
	end

	-- Notify client
	TutorialService.Remotes.TutorialStep:FireClient(player, {
		tutorialName = tutorialName,
		complete = true,
		rewardXP = tutorial.RewardXP,
	})

	-- Save progress
	TutorialService.SavePlayerProgress(player)

	print(string.format("[TutorialService] %s completed tutorial: %s (+%d XP)",
		player.Name, tutorialName, tutorial.RewardXP or 0))
end

function TutorialService.SkipTutorial(player: Player, tutorialName: string)
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress then return end

	-- If currently in this tutorial, cancel it
	if progress.currentTutorial == tutorialName then
		progress.currentTutorial = nil
		progress.currentStep = 0
	end

	-- Mark as completed (no rewards for skipping)
	progress.completedTutorials[tutorialName] = true

	-- Notify client
	TutorialService.Remotes.TutorialStep:FireClient(player, {
		tutorialName = tutorialName,
		skipped = true,
	})

	TutorialService.SavePlayerProgress(player)

	print(string.format("[TutorialService] %s skipped tutorial: %s", player.Name, tutorialName))
end

-- ============================================================================
-- UTILITIES
-- ============================================================================

function TutorialService.GetPlayerStatus(player: Player): table
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress then return {} end

	return {
		currentTutorial = progress.currentTutorial,
		currentStep = progress.currentStep,
		completedTutorials = progress.completedTutorials,
	}
end

function TutorialService.HasCompletedTutorial(player: Player, tutorialName: string): boolean
	local progress = TutorialService.PlayerProgress[player.UserId]
	if not progress then return false end
	return progress.completedTutorials[tutorialName] == true
end

function TutorialService.NeedsTutorial(player: Player, tutorialName: string): boolean
	return not TutorialService.HasCompletedTutorial(player, tutorialName)
end

function TutorialService.ShouldShowBasicsTutorial(player: Player): boolean
	return TutorialService.NeedsTutorial(player, "Basics")
end

function TutorialService.ShouldShowDimensionTutorial(player: Player, dimension: string): boolean
	-- Must complete basics first
	if TutorialService.NeedsTutorial(player, "Basics") then
		return false
	end
	return TutorialService.NeedsTutorial(player, dimension)
end

-- Auto-start tutorial when player enters dimension for first time
function TutorialService.OnPlayerEnterDimension(player: Player, dimension: string)
	if TutorialService.ShouldShowDimensionTutorial(player, dimension) then
		TutorialService.StartTutorial(player, dimension)
	end
end

return TutorialService
