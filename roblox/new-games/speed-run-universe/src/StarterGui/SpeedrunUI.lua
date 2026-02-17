--[[
	SpeedrunUI.lua - Speed Run Universe
	Main HUD: speedrun timer, checkpoint display, ability bar, coin counter,
	death counter, split times, notifications, and world info.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local SpeedrunUI = {}
local screenGui
local playerData = nil

-- UI Element references
local timerFrame, timerLabel, stageTimerLabel, splitContainer
local coinDisplay, stageDisplay, deathDisplay
local abilityBar
local notificationQueue = {}
local isShowingNotification = false

-- ============================================================================
-- COLOR PALETTE
-- ============================================================================
local Colors = {
	Background = Color3.fromRGB(15, 15, 25),
	BackgroundLight = Color3.fromRGB(25, 25, 40),
	Accent = Color3.fromRGB(0, 200, 255),
	AccentGold = Color3.fromRGB(255, 200, 0),
	AccentGreen = Color3.fromRGB(0, 255, 120),
	AccentRed = Color3.fromRGB(255, 60, 60),
	AccentPurple = Color3.fromRGB(180, 80, 255),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	TextMuted = Color3.fromRGB(120, 120, 140),
}

-- ============================================================================
-- INIT
-- ============================================================================
function SpeedrunUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpeedrunUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = player.PlayerGui

	-- Fetch initial data
	task.spawn(function()
		task.wait(2)
		playerData = remoteFunctions:WaitForChild("GetPlayerData"):InvokeServer()
	end)

	-- Create all UI elements
	SpeedrunUI.CreateTimerHUD()
	SpeedrunUI.CreateCoinDisplay()
	SpeedrunUI.CreateStageDisplay()
	SpeedrunUI.CreateDeathCounter()
	SpeedrunUI.CreateAbilityBar()
	SpeedrunUI.CreateSplitTimesPanel()
	SpeedrunUI.CreateNotificationArea()
	SpeedrunUI.CreateWorldInfoBar()

	-- Connect events
	SpeedrunUI._ConnectEvents()
end

-- ============================================================================
-- TIMER HUD (center-top)
-- ============================================================================
function SpeedrunUI.CreateTimerHUD()
	timerFrame = Instance.new("Frame")
	timerFrame.Name = "TimerHUD"
	timerFrame.Size = UDim2.new(0, 320, 0, 90)
	timerFrame.Position = UDim2.new(0.5, -160, 0, 8)
	timerFrame.BackgroundColor3 = Colors.Background
	timerFrame.BackgroundTransparency = 0.2
	timerFrame.BorderSizePixel = 0
	timerFrame.Visible = false
	timerFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = timerFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Accent
	stroke.Thickness = 1.5
	stroke.Transparency = 0.5
	stroke.Parent = timerFrame

	-- World timer (total)
	local totalLabel = Instance.new("TextLabel")
	totalLabel.Name = "TotalLabel"
	totalLabel.Size = UDim2.new(1, 0, 0, 14)
	totalLabel.Position = UDim2.new(0, 0, 0, 4)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "TOTAL TIME"
	totalLabel.TextColor3 = Colors.TextMuted
	totalLabel.TextSize = 10
	totalLabel.Font = Enum.Font.GothamBold
	totalLabel.Parent = timerFrame

	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerValue"
	timerLabel.Size = UDim2.new(1, 0, 0, 36)
	timerLabel.Position = UDim2.new(0, 0, 0, 16)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "00:00.000"
	timerLabel.TextColor3 = Colors.AccentGreen
	timerLabel.TextSize = 30
	timerLabel.Font = Enum.Font.Code
	timerLabel.Parent = timerFrame

	-- Stage timer
	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(1, 0, 0, 14)
	stageLabel.Position = UDim2.new(0, 0, 0, 52)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = "STAGE TIME"
	stageLabel.TextColor3 = Colors.TextMuted
	stageLabel.TextSize = 9
	stageLabel.Font = Enum.Font.GothamBold
	stageLabel.Parent = timerFrame

	stageTimerLabel = Instance.new("TextLabel")
	stageTimerLabel.Name = "StageTimerValue"
	stageTimerLabel.Size = UDim2.new(1, 0, 0, 24)
	stageTimerLabel.Position = UDim2.new(0, 0, 0, 64)
	stageTimerLabel.BackgroundTransparency = 1
	stageTimerLabel.Text = "00:00.000"
	stageTimerLabel.TextColor3 = Colors.Accent
	stageTimerLabel.TextSize = 18
	stageTimerLabel.Font = Enum.Font.Code
	stageTimerLabel.Parent = timerFrame
end

-- ============================================================================
-- COIN DISPLAY (top-right)
-- ============================================================================
function SpeedrunUI.CreateCoinDisplay()
	coinDisplay = Instance.new("Frame")
	coinDisplay.Name = "CoinDisplay"
	coinDisplay.Size = UDim2.new(0, 160, 0, 40)
	coinDisplay.Position = UDim2.new(1, -170, 0, 8)
	coinDisplay.BackgroundColor3 = Colors.Background
	coinDisplay.BackgroundTransparency = 0.3
	coinDisplay.BorderSizePixel = 0
	coinDisplay.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = coinDisplay

	-- Coin icon (circle)
	local icon = Instance.new("Frame")
	icon.Name = "CoinIcon"
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.Position = UDim2.new(0, 10, 0.5, -12)
	icon.BackgroundColor3 = Colors.AccentGold
	icon.BorderSizePixel = 0
	icon.Parent = coinDisplay

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = icon

	local iconText = Instance.new("TextLabel")
	iconText.Size = UDim2.new(1, 0, 1, 0)
	iconText.BackgroundTransparency = 1
	iconText.Text = "$"
	iconText.TextColor3 = Colors.Background
	iconText.TextSize = 14
	iconText.Font = Enum.Font.GothamBold
	iconText.Parent = icon

	local value = Instance.new("TextLabel")
	value.Name = "CoinValue"
	value.Size = UDim2.new(1, -45, 1, 0)
	value.Position = UDim2.new(0, 40, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = "0"
	value.TextColor3 = Colors.AccentGold
	value.TextSize = 20
	value.Font = Enum.Font.GothamBold
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Parent = coinDisplay
end

-- ============================================================================
-- STAGE DISPLAY (top-left)
-- ============================================================================
function SpeedrunUI.CreateStageDisplay()
	stageDisplay = Instance.new("Frame")
	stageDisplay.Name = "StageDisplay"
	stageDisplay.Size = UDim2.new(0, 200, 0, 50)
	stageDisplay.Position = UDim2.new(0, 10, 0, 8)
	stageDisplay.BackgroundColor3 = Colors.Background
	stageDisplay.BackgroundTransparency = 0.3
	stageDisplay.BorderSizePixel = 0
	stageDisplay.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = stageDisplay

	local worldLabel = Instance.new("TextLabel")
	worldLabel.Name = "WorldName"
	worldLabel.Size = UDim2.new(1, -10, 0, 20)
	worldLabel.Position = UDim2.new(0, 10, 0, 4)
	worldLabel.BackgroundTransparency = 1
	worldLabel.Text = "Grasslands"
	worldLabel.TextColor3 = Colors.TextPrimary
	worldLabel.TextSize = 14
	worldLabel.Font = Enum.Font.GothamBold
	worldLabel.TextXAlignment = Enum.TextXAlignment.Left
	worldLabel.Parent = stageDisplay

	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(1, -10, 0, 18)
	stageLabel.Position = UDim2.new(0, 10, 0, 26)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = "Stage 1 / 10"
	stageLabel.TextColor3 = Colors.TextSecondary
	stageLabel.TextSize = 12
	stageLabel.Font = Enum.Font.GothamMedium
	stageLabel.TextXAlignment = Enum.TextXAlignment.Left
	stageLabel.Parent = stageDisplay

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -20, 0, 3)
	progressBg.Position = UDim2.new(0, 10, 1, -6)
	progressBg.BackgroundColor3 = Colors.BackgroundLight
	progressBg.BorderSizePixel = 0
	progressBg.Parent = stageDisplay

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0.1, 0, 1, 0)
	progressFill.BackgroundColor3 = Colors.AccentGreen
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill
end

-- ============================================================================
-- DEATH COUNTER (below coin display)
-- ============================================================================
function SpeedrunUI.CreateDeathCounter()
	deathDisplay = Instance.new("Frame")
	deathDisplay.Name = "DeathDisplay"
	deathDisplay.Size = UDim2.new(0, 100, 0, 30)
	deathDisplay.Position = UDim2.new(1, -170, 0, 54)
	deathDisplay.BackgroundColor3 = Colors.Background
	deathDisplay.BackgroundTransparency = 0.4
	deathDisplay.BorderSizePixel = 0
	deathDisplay.Visible = false
	deathDisplay.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = deathDisplay

	local skull = Instance.new("TextLabel")
	skull.Size = UDim2.new(0, 24, 1, 0)
	skull.Position = UDim2.new(0, 6, 0, 0)
	skull.BackgroundTransparency = 1
	skull.Text = "X"
	skull.TextColor3 = Colors.AccentRed
	skull.TextSize = 16
	skull.Font = Enum.Font.GothamBold
	skull.Parent = deathDisplay

	local deathCount = Instance.new("TextLabel")
	deathCount.Name = "DeathCount"
	deathCount.Size = UDim2.new(1, -35, 1, 0)
	deathCount.Position = UDim2.new(0, 30, 0, 0)
	deathCount.BackgroundTransparency = 1
	deathCount.Text = "0"
	deathCount.TextColor3 = Colors.AccentRed
	deathCount.TextSize = 16
	deathCount.Font = Enum.Font.GothamBold
	deathCount.TextXAlignment = Enum.TextXAlignment.Left
	deathCount.Parent = deathDisplay
end

-- ============================================================================
-- ABILITY BAR (bottom-center)
-- ============================================================================
function SpeedrunUI.CreateAbilityBar()
	abilityBar = Instance.new("Frame")
	abilityBar.Name = "AbilityBar"
	abilityBar.Size = UDim2.new(0, 340, 0, 60)
	abilityBar.Position = UDim2.new(0.5, -170, 1, -70)
	abilityBar.BackgroundColor3 = Colors.Background
	abilityBar.BackgroundTransparency = 0.3
	abilityBar.BorderSizePixel = 0
	abilityBar.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = abilityBar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = abilityBar

	-- Create ability slots (empty initially, populated when abilities sync)
	for i = 1, 3 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.Size = UDim2.new(0, 50, 0, 50)
		slot.BackgroundColor3 = Colors.BackgroundLight
		slot.BackgroundTransparency = 0.3
		slot.BorderSizePixel = 0
		slot.Parent = abilityBar

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 10)
		slotCorner.Parent = slot

		local slotStroke = Instance.new("UIStroke")
		slotStroke.Name = "SlotStroke"
		slotStroke.Color = Colors.TextMuted
		slotStroke.Thickness = 1
		slotStroke.Transparency = 0.5
		slotStroke.Parent = slot

		-- Ability name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "AbilityName"
		nameLabel.Size = UDim2.new(1, 0, 0, 12)
		nameLabel.Position = UDim2.new(0, 0, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = ""
		nameLabel.TextColor3 = Colors.TextSecondary
		nameLabel.TextSize = 8
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Parent = slot

		-- Keybind label
		local keybindLabel = Instance.new("TextLabel")
		keybindLabel.Name = "Keybind"
		keybindLabel.Size = UDim2.new(1, 0, 0, 20)
		keybindLabel.Position = UDim2.new(0, 0, 0.5, -10)
		keybindLabel.BackgroundTransparency = 1
		keybindLabel.Text = ""
		keybindLabel.TextColor3 = Colors.TextPrimary
		keybindLabel.TextSize = 16
		keybindLabel.Font = Enum.Font.GothamBold
		keybindLabel.Parent = slot

		-- Cooldown overlay
		local cooldownOverlay = Instance.new("Frame")
		cooldownOverlay.Name = "CooldownOverlay"
		cooldownOverlay.Size = UDim2.new(1, 0, 0, 0) -- Height animated
		cooldownOverlay.Position = UDim2.new(0, 0, 1, 0)
		cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
		cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		cooldownOverlay.BackgroundTransparency = 0.5
		cooldownOverlay.BorderSizePixel = 0
		cooldownOverlay.ZIndex = 2
		cooldownOverlay.Parent = slot

		local cdCorner = Instance.new("UICorner")
		cdCorner.CornerRadius = UDim.new(0, 10)
		cdCorner.Parent = cooldownOverlay

		-- Cooldown text
		local cdLabel = Instance.new("TextLabel")
		cdLabel.Name = "CooldownLabel"
		cdLabel.Size = UDim2.new(1, 0, 0, 12)
		cdLabel.Position = UDim2.new(0, 0, 1, -14)
		cdLabel.BackgroundTransparency = 1
		cdLabel.Text = ""
		cdLabel.TextColor3 = Colors.AccentRed
		cdLabel.TextSize = 10
		cdLabel.Font = Enum.Font.GothamBold
		cdLabel.ZIndex = 3
		cdLabel.Parent = slot
	end
end

-- ============================================================================
-- SPLIT TIMES PANEL (right side)
-- ============================================================================
function SpeedrunUI.CreateSplitTimesPanel()
	splitContainer = Instance.new("Frame")
	splitContainer.Name = "SplitTimes"
	splitContainer.Size = UDim2.new(0, 180, 0, 300)
	splitContainer.Position = UDim2.new(1, -190, 0.5, -150)
	splitContainer.BackgroundColor3 = Colors.Background
	splitContainer.BackgroundTransparency = 0.3
	splitContainer.BorderSizePixel = 0
	splitContainer.Visible = false
	splitContainer.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = splitContainer

	local title = Instance.new("TextLabel")
	title.Name = "SplitTitle"
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.Text = "SPLIT TIMES"
	title.TextColor3 = Colors.TextMuted
	title.TextSize = 10
	title.Font = Enum.Font.GothamBold
	title.Parent = splitContainer

	-- Split entries will be added dynamically
	local splitList = Instance.new("Frame")
	splitList.Name = "SplitList"
	splitList.Size = UDim2.new(1, -10, 1, -30)
	splitList.Position = UDim2.new(0, 5, 0, 26)
	splitList.BackgroundTransparency = 1
	splitList.Parent = splitContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = splitList
end

-- ============================================================================
-- NOTIFICATION AREA (center-bottom)
-- ============================================================================
function SpeedrunUI.CreateNotificationArea()
	local notifArea = Instance.new("Frame")
	notifArea.Name = "NotificationArea"
	notifArea.Size = UDim2.new(0, 400, 0, 50)
	notifArea.Position = UDim2.new(0.5, -200, 0.75, 0)
	notifArea.BackgroundTransparency = 1
	notifArea.Parent = screenGui
end

-- ============================================================================
-- WORLD INFO BAR (top, below stage display)
-- ============================================================================
function SpeedrunUI.CreateWorldInfoBar()
	local infoBar = Instance.new("Frame")
	infoBar.Name = "WorldInfoBar"
	infoBar.Size = UDim2.new(0, 200, 0, 24)
	infoBar.Position = UDim2.new(0, 10, 0, 64)
	infoBar.BackgroundColor3 = Colors.Background
	infoBar.BackgroundTransparency = 0.5
	infoBar.BorderSizePixel = 0
	infoBar.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = infoBar

	local pbLabel = Instance.new("TextLabel")
	pbLabel.Name = "PBLabel"
	pbLabel.Size = UDim2.new(1, -10, 1, 0)
	pbLabel.Position = UDim2.new(0, 5, 0, 0)
	pbLabel.BackgroundTransparency = 1
	pbLabel.Text = "PB: --:--:---"
	pbLabel.TextColor3 = Colors.AccentGold
	pbLabel.TextSize = 11
	pbLabel.Font = Enum.Font.GothamMedium
	pbLabel.TextXAlignment = Enum.TextXAlignment.Left
	pbLabel.Parent = infoBar
end

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================
function SpeedrunUI._ConnectEvents()
	-- Timer updates
	remoteEvents:WaitForChild("SpeedrunUpdate").OnClientEvent:Connect(function(data)
		if data.Action == "Started" then
			timerFrame.Visible = true
			deathDisplay.Visible = true
			splitContainer.Visible = data.IsWorldRun
			SpeedrunUI._UpdateStageDisplay(data.WorldId, data.Stage)
		elseif data.Action == "Tick" then
			SpeedrunUI._UpdateTimer(data.TotalTime, data.StageTime)
			SpeedrunUI._UpdateDeathCount(data.DeathCount)
			SpeedrunUI._UpdateStageDisplay(data.WorldId, data.Stage)
		elseif data.Action == "StageSplit" then
			SpeedrunUI._AddSplit(data.Stage, data.StageTime, data.IsPB)
			SpeedrunUI._UpdateStageDisplay(data.WorldId, data.NextStage)
		end
	end)

	-- Run complete
	remoteEvents:WaitForChild("SpeedrunComplete").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowCompletionScreen(data)
		task.wait(5)
		timerFrame.Visible = false
		deathDisplay.Visible = false
		splitContainer.Visible = false
	end)

	-- Coin sync
	remoteEvents:WaitForChild("CoinSync").OnClientEvent:Connect(function(data)
		SpeedrunUI._UpdateCoins(data.Coins, data.Added)
	end)

	-- Stage complete flash
	remoteEvents:WaitForChild("StageComplete").OnClientEvent:Connect(function(data)
		if data.FirstCompletion then
			SpeedrunUI._ShowNotification("Stage " .. data.StageNum .. " Complete!", Colors.AccentGreen)
		end
	end)

	-- World complete
	remoteEvents:WaitForChild("WorldComplete").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowNotification("WORLD COMPLETE: " .. data.WorldId .. "!", Colors.AccentGold)
	end)

	-- New personal best
	remoteEvents:WaitForChild("NewPersonalBest").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowNotification("NEW PERSONAL BEST! " .. SpeedrunUI._FormatTime(data.Time), Colors.AccentGold)
	end)

	-- Ability sync
	remoteEvents:WaitForChild("AbilitySync").OnClientEvent:Connect(function(data)
		SpeedrunUI._UpdateAbilityBar(data)
	end)

	-- Ability unlock
	remoteEvents:WaitForChild("UnlockAbility").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowNotification("ABILITY UNLOCKED: " .. data.AbilityName, Colors.AccentPurple)
	end)

	-- Notifications
	remoteEvents:WaitForChild("Notification").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowNotification(data.Message, Colors.TextPrimary)
	end)

	-- Daily reward
	remoteEvents:WaitForChild("DailyReward").OnClientEvent:Connect(function(data)
		local reward = data.Reward
		local msg = "Daily Reward (Day " .. data.Day .. "): "
		if reward.Reward == "Coins" then
			msg = msg .. "+" .. reward.Amount .. " coins!"
		elseif reward.Reward == "Trail" then
			msg = msg .. "Trail: " .. (reward.TrailId or "?")
		elseif reward.Reward == "WinEffect" then
			msg = msg .. "Win Effect: " .. (reward.EffectId or "?")
		end
		SpeedrunUI._ShowNotification(msg, Colors.AccentGold)
	end)

	-- Death
	remoteEvents:WaitForChild("PlayerDied").OnClientEvent:Connect(function(data)
		SpeedrunUI._UpdateDeathCount(data.DeathCount)
		SpeedrunUI._FlashScreen(Colors.AccentRed, 0.3)
	end)

	-- Challenge complete
	remoteEvents:WaitForChild("ChallengeComplete").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowNotification("Challenge Complete! +" .. data.CoinReward .. " coins!", Colors.AccentGreen)
	end)

	-- World unlock
	remoteEvents:WaitForChild("WorldUnlocked").OnClientEvent:Connect(function(data)
		SpeedrunUI._ShowNotification("WORLD UNLOCKED: " .. data.WorldName, Colors.AccentGold)
	end)
end

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================
function SpeedrunUI._UpdateTimer(totalTime, stageTime)
	timerLabel.Text = SpeedrunUI._FormatTime(totalTime)
	stageTimerLabel.Text = SpeedrunUI._FormatTime(stageTime)
end

function SpeedrunUI._UpdateCoins(coins, added)
	local coinValue = coinDisplay:FindFirstChild("CoinValue")
	if coinValue then
		coinValue.Text = SpeedrunUI._FormatNumber(coins)

		-- Flash animation for coin gain
		if added and added > 0 then
			local tween = TweenService:Create(coinValue, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
				TextSize = 26,
			})
			tween:Play()
			tween.Completed:Connect(function()
				TweenService:Create(coinValue, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					TextSize = 20,
				}):Play()
			end)
		end
	end
end

function SpeedrunUI._UpdateStageDisplay(worldId, stageNum)
	local worldConfig = GameConfig.WorldById[worldId]
	if not worldConfig then return end

	local worldName = stageDisplay:FindFirstChild("WorldName")
	local stageLabel = stageDisplay:FindFirstChild("StageLabel")
	local progressBg = stageDisplay:FindFirstChild("ProgressBg")

	if worldName then worldName.Text = worldConfig.Name end
	if stageLabel then stageLabel.Text = "Stage " .. stageNum .. " / " .. worldConfig.StageCount end
	if progressBg then
		local fill = progressBg:FindFirstChild("ProgressFill")
		if fill then
			local progress = stageNum / worldConfig.StageCount
			TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(progress, 0, 1, 0),
			}):Play()
		end
	end

	-- Update PB display
	local infoBar = screenGui:FindFirstChild("WorldInfoBar")
	if infoBar then
		local pbLabel = infoBar:FindFirstChild("PBLabel")
		if pbLabel and playerData then
			local stageKey = worldId .. "_" .. tostring(stageNum)
			local pb = playerData.PersonalBests and playerData.PersonalBests[stageKey]
			if pb then
				pbLabel.Text = "Stage PB: " .. SpeedrunUI._FormatTime(pb)
			else
				pbLabel.Text = "Stage PB: --:--.---"
			end
		end
	end
end

function SpeedrunUI._UpdateDeathCount(count)
	local deathCount = deathDisplay:FindFirstChild("DeathCount")
	if deathCount then
		deathCount.Text = tostring(count or 0)
	end
end

function SpeedrunUI._UpdateAbilityBar(abilityData)
	if not abilityData then return end

	local equipped = abilityData.EquippedAbilities or {}

	for i = 1, 3 do
		local slot = abilityBar:FindFirstChild("Slot_" .. i)
		if not slot then continue end

		local nameLabel = slot:FindFirstChild("AbilityName")
		local keybindLabel = slot:FindFirstChild("Keybind")
		local cooldownOverlay = slot:FindFirstChild("CooldownOverlay")
		local stroke = slot:FindFirstChild("SlotStroke")

		if i <= #equipped then
			local abilityId = equipped[i]
			local cfg = GameConfig.AbilityById[abilityId]
			if cfg then
				if nameLabel then nameLabel.Text = cfg.Name end
				if keybindLabel then keybindLabel.Text = string.sub(cfg.KeyBind.Name, 1, 1) end
				if stroke then stroke.Color = Colors.Accent; stroke.Transparency = 0 end

				-- Show cooldown if active
				local remaining = abilityData.Cooldowns and abilityData.Cooldowns[abilityId]
				if remaining and remaining > 0 then
					local ratio = remaining / cfg.Cooldown
					if cooldownOverlay then
						cooldownOverlay.Size = UDim2.new(1, 0, ratio, 0)
					end
					local cdLabel = slot:FindFirstChild("CooldownLabel")
					if cdLabel then
						cdLabel.Text = string.format("%.1f", remaining)
					end
				else
					if cooldownOverlay then
						cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
					end
					local cdLabel = slot:FindFirstChild("CooldownLabel")
					if cdLabel then cdLabel.Text = "" end
				end
			end
		else
			-- Empty slot
			if nameLabel then nameLabel.Text = "" end
			if keybindLabel then keybindLabel.Text = "" end
			if stroke then stroke.Color = Colors.TextMuted; stroke.Transparency = 0.5 end
			if cooldownOverlay then cooldownOverlay.Size = UDim2.new(1, 0, 0, 0) end
		end
	end
end

-- ============================================================================
-- SPLIT TIMES
-- ============================================================================
function SpeedrunUI._AddSplit(stageNum, stageTime, isPB)
	local splitList = splitContainer:FindFirstChild("SplitList")
	if not splitList then return end

	local entry = Instance.new("Frame")
	entry.Name = "Split_" .. stageNum
	entry.Size = UDim2.new(1, 0, 0, 22)
	entry.BackgroundTransparency = 1
	entry.Parent = splitList

	local stageLbl = Instance.new("TextLabel")
	stageLbl.Size = UDim2.new(0.4, 0, 1, 0)
	stageLbl.BackgroundTransparency = 1
	stageLbl.Text = "Stage " .. stageNum
	stageLbl.TextColor3 = Colors.TextSecondary
	stageLbl.TextSize = 11
	stageLbl.Font = Enum.Font.GothamMedium
	stageLbl.TextXAlignment = Enum.TextXAlignment.Left
	stageLbl.Parent = entry

	local timeLbl = Instance.new("TextLabel")
	timeLbl.Size = UDim2.new(0.4, 0, 1, 0)
	timeLbl.Position = UDim2.new(0.4, 0, 0, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Text = SpeedrunUI._FormatTime(stageTime)
	timeLbl.TextColor3 = isPB and Colors.AccentGold or Colors.TextPrimary
	timeLbl.TextSize = 11
	timeLbl.Font = Enum.Font.Code
	timeLbl.TextXAlignment = Enum.TextXAlignment.Right
	timeLbl.Parent = entry

	if isPB then
		local pbBadge = Instance.new("TextLabel")
		pbBadge.Size = UDim2.new(0.2, 0, 1, 0)
		pbBadge.Position = UDim2.new(0.8, 0, 0, 0)
		pbBadge.BackgroundTransparency = 1
		pbBadge.Text = "PB!"
		pbBadge.TextColor3 = Colors.AccentGold
		pbBadge.TextSize = 10
		pbBadge.Font = Enum.Font.GothamBold
		pbBadge.Parent = entry
	end
end

-- ============================================================================
-- COMPLETION SCREEN
-- ============================================================================
function SpeedrunUI._ShowCompletionScreen(data)
	local overlay = Instance.new("Frame")
	overlay.Name = "CompletionOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Colors.Background
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 10
	overlay.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 400, 0, 350)
	panel.Position = UDim2.new(0.5, -200, 0.5, -175)
	panel.BackgroundColor3 = Colors.Background
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.ZIndex = 11
	panel.Parent = overlay

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 16)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = data.IsPB and Colors.AccentGold or Colors.Accent
	panelStroke.Thickness = 2
	panelStroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = data.IsPB and "NEW PERSONAL BEST!" or "WORLD COMPLETE!"
	title.TextColor3 = data.IsPB and Colors.AccentGold or Colors.AccentGreen
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 12
	title.Parent = panel

	-- World name
	local worldName = Instance.new("TextLabel")
	worldName.Size = UDim2.new(1, 0, 0, 24)
	worldName.Position = UDim2.new(0, 0, 0, 50)
	worldName.BackgroundTransparency = 1
	local worldCfg = GameConfig.WorldById[data.WorldId]
	worldName.Text = worldCfg and worldCfg.Name or data.WorldId
	worldName.TextColor3 = Colors.TextSecondary
	worldName.TextSize = 16
	worldName.Font = Enum.Font.GothamMedium
	worldName.ZIndex = 12
	worldName.Parent = panel

	-- Total time
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, 0, 0, 50)
	timeLabel.Position = UDim2.new(0, 0, 0, 80)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = SpeedrunUI._FormatTime(data.TotalTime)
	timeLabel.TextColor3 = Colors.AccentGreen
	timeLabel.TextSize = 36
	timeLabel.Font = Enum.Font.Code
	timeLabel.ZIndex = 12
	timeLabel.Parent = panel

	-- Stats
	local yOffset = 140
	local stats = {
		{ Label = "Deaths", Value = tostring(data.DeathCount), Color = Colors.AccentRed },
		{ Label = "Coins Earned", Value = "+" .. tostring(data.CoinsEarned), Color = Colors.AccentGold },
		{ Label = "Under Par", Value = data.UnderPar and "YES (2x Coins!)" or "No", Color = data.UnderPar and Colors.AccentGreen or Colors.TextMuted },
	}

	for _, stat in ipairs(stats) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(0.8, 0, 0, 24)
		row.Position = UDim2.new(0.1, 0, 0, yOffset)
		row.BackgroundTransparency = 1
		row.ZIndex = 12
		row.Parent = panel

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.5, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = stat.Label
		lbl.TextColor3 = Colors.TextSecondary
		lbl.TextSize = 14
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 12
		lbl.Parent = row

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(0.5, 0, 1, 0)
		val.Position = UDim2.new(0.5, 0, 0, 0)
		val.BackgroundTransparency = 1
		val.Text = stat.Value
		val.TextColor3 = stat.Color
		val.TextSize = 14
		val.Font = Enum.Font.GothamBold
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.ZIndex = 12
		val.Parent = row

		yOffset = yOffset + 28
	end

	-- Split times summary
	if data.SplitTimes then
		yOffset = yOffset + 10
		local splitTitle = Instance.new("TextLabel")
		splitTitle.Size = UDim2.new(0.8, 0, 0, 18)
		splitTitle.Position = UDim2.new(0.1, 0, 0, yOffset)
		splitTitle.BackgroundTransparency = 1
		splitTitle.Text = "SPLITS"
		splitTitle.TextColor3 = Colors.TextMuted
		splitTitle.TextSize = 10
		splitTitle.Font = Enum.Font.GothamBold
		splitTitle.TextXAlignment = Enum.TextXAlignment.Left
		splitTitle.ZIndex = 12
		splitTitle.Parent = panel

		yOffset = yOffset + 18
		for stageNum, stageTime in pairs(data.SplitTimes) do
			local splitRow = Instance.new("TextLabel")
			splitRow.Size = UDim2.new(0.8, 0, 0, 16)
			splitRow.Position = UDim2.new(0.1, 0, 0, yOffset)
			splitRow.BackgroundTransparency = 1
			splitRow.Text = "S" .. stageNum .. ": " .. SpeedrunUI._FormatTime(stageTime)
			splitRow.TextColor3 = Colors.TextSecondary
			splitRow.TextSize = 11
			splitRow.Font = Enum.Font.Code
			splitRow.TextXAlignment = Enum.TextXAlignment.Left
			splitRow.ZIndex = 12
			splitRow.Parent = panel
			yOffset = yOffset + 16
		end
	end

	-- Auto-dismiss after 5 seconds with fade
	task.delay(4, function()
		if overlay and overlay.Parent then
			local tween = TweenService:Create(overlay, TweenInfo.new(1, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1,
			})
			tween:Play()
			tween.Completed:Connect(function()
				if overlay.Parent then overlay:Destroy() end
			end)
		end
	end)
end

-- ============================================================================
-- NOTIFICATION SYSTEM
-- ============================================================================
function SpeedrunUI._ShowNotification(message, color)
	table.insert(notificationQueue, { Message = message, Color = color or Colors.TextPrimary })

	if not isShowingNotification then
		SpeedrunUI._ProcessNotificationQueue()
	end
end

function SpeedrunUI._ProcessNotificationQueue()
	if #notificationQueue == 0 then
		isShowingNotification = false
		return
	end

	isShowingNotification = true
	local notif = table.remove(notificationQueue, 1)

	local notifArea = screenGui:FindFirstChild("NotificationArea")
	if not notifArea then return end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 40)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundColor3 = Colors.Background
	label.BackgroundTransparency = 0.3
	label.BorderSizePixel = 0
	label.Text = notif.Message
	label.TextColor3 = notif.Color
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.TextTransparency = 1
	label.Parent = notifArea

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	-- Fade in
	TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	-- Hold then fade out
	task.delay(2, function()
		local fadeOut = TweenService:Create(label, TweenInfo.new(0.5), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			if label.Parent then label:Destroy() end
			SpeedrunUI._ProcessNotificationQueue()
		end)
	end)
end

-- ============================================================================
-- SCREEN FLASH (death, etc.)
-- ============================================================================
function SpeedrunUI._FlashScreen(color, duration)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.7
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = screenGui

	local tween = TweenService:Create(flash, TweenInfo.new(duration or 0.3), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)
end

-- ============================================================================
-- FORMAT HELPERS
-- ============================================================================
function SpeedrunUI._FormatTime(seconds)
	if not seconds or seconds <= 0 then return "00:00.000" end
	local mins = math.floor(seconds / 60)
	local secs = seconds - (mins * 60)
	return string.format("%02d:%06.3f", mins, secs)
end

function SpeedrunUI._FormatNumber(num)
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

-- ============================================================================
-- BOOTSTRAP
-- ============================================================================
SpeedrunUI.Init()

return SpeedrunUI
