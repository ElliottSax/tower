--[[
	BattlePassUI.lua
	Client-side Battle Pass interface for Tower Ascent

	Features:
	- Toggle button to open/close Battle Pass menu
	- Current tier and XP progress display
	- Scrolling tier rewards (50 tiers)
	- Free and Premium reward tracks
	- Claim reward buttons
	- Daily/Weekly challenges panel
	- Premium purchase button

	Week 13: Battle Pass UI implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Colors
	BackgroundColor = Color3.fromRGB(20, 20, 30),
	PanelColor = Color3.fromRGB(35, 35, 50),
	AccentColor = Color3.fromRGB(255, 200, 50), -- Gold
	PremiumColor = Color3.fromRGB(180, 130, 255), -- Purple
	FreeColor = Color3.fromRGB(100, 200, 100), -- Green
	LockedColor = Color3.fromRGB(80, 80, 80),
	TextColor = Color3.fromRGB(255, 255, 255),
	SubTextColor = Color3.fromRGB(180, 180, 180),

	-- Sizes
	TierCardWidth = 120,
	TierCardHeight = 200,
	TierCardSpacing = 10,

	-- Animation
	TweenSpeed = 0.3,
}

-- ============================================================================
-- UI CREATION
-- ============================================================================

local BattlePassUI = {}
BattlePassUI.IsOpen = false
BattlePassUI.Data = nil

-- Remote events
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local BattlePassUpdate = remoteFolder and remoteFolder:FindFirstChild("BattlePassUpdate")
local ClaimReward = remoteFolder and remoteFolder:FindFirstChild("ClaimBattlePassReward")
local PromptPurchase = remoteFolder and remoteFolder:FindFirstChild("PromptBattlePassPurchase")
local GetBattlePassData = remoteFolder and remoteFolder:FindFirstChild("GetBattlePassData")

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function createInstance(className, properties)
	local instance = Instance.new(className)
	for prop, value in pairs(properties) do
		instance[prop] = value
	end
	return instance
end

local function formatNumber(num)
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

local function getRewardIcon(rewardType)
	local icons = {
		Coins = "💰",
		XPBoost = "⚡",
		Title = "🏷️",
		Trail = "✨",
		Emote = "💃",
	}
	return icons[rewardType] or "🎁"
end

local function getRewardText(reward)
	if not reward then return "---" end

	if reward.type == "Coins" then
		return getRewardIcon("Coins") .. " " .. formatNumber(reward.amount)
	elseif reward.type == "XPBoost" then
		return getRewardIcon("XPBoost") .. " " .. math.floor(reward.duration / 60) .. "m Boost"
	elseif reward.type == "Title" then
		return getRewardIcon("Title") .. " " .. reward.id
	elseif reward.type == "Trail" then
		return getRewardIcon("Trail") .. " " .. reward.id
	elseif reward.type == "Emote" then
		return getRewardIcon("Emote") .. " " .. reward.id
	end

	return "🎁 Reward"
end

-- ============================================================================
-- MAIN UI STRUCTURE
-- ============================================================================

function BattlePassUI.Create()
	-- Main ScreenGui
	local screenGui = createInstance("ScreenGui", {
		Name = "BattlePassUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	-- Toggle Button (bottom right)
	local toggleButton = createInstance("TextButton", {
		Name = "ToggleButton",
		Size = UDim2.new(0, 60, 0, 60),
		Position = UDim2.new(1, -80, 1, -80),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = CONFIG.AccentColor,
		Text = "BP",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		Parent = screenGui,
	})

	local toggleCorner = createInstance("UICorner", {
		CornerRadius = UDim.new(0.5, 0),
		Parent = toggleButton,
	})

	local toggleStroke = createInstance("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 2,
		Parent = toggleButton,
	})

	-- Notification badge
	local notifBadge = createInstance("TextLabel", {
		Name = "NotifBadge",
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -5, 0, -5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 50, 50),
		Text = "!",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Visible = false,
		Parent = toggleButton,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0.5, 0),
		Parent = notifBadge,
	})

	-- Main Panel (hidden by default)
	local mainPanel = createInstance("Frame", {
		Name = "MainPanel",
		Size = UDim2.new(0.9, 0, 0.85, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = CONFIG.BackgroundColor,
		Visible = false,
		Parent = screenGui,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 16),
		Parent = mainPanel,
	})

	createInstance("UIStroke", {
		Color = CONFIG.AccentColor,
		Thickness = 2,
		Parent = mainPanel,
	})

	-- Header
	local header = BattlePassUI.CreateHeader(mainPanel)

	-- Progress Bar Section
	local progressSection = BattlePassUI.CreateProgressSection(mainPanel)

	-- Rewards Track (scrolling)
	local rewardsTrack = BattlePassUI.CreateRewardsTrack(mainPanel)

	-- Challenges Panel
	local challengesPanel = BattlePassUI.CreateChallengesPanel(mainPanel)

	-- Close Button
	local closeButton = createInstance("TextButton", {
		Name = "CloseButton",
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -10, 0, 10),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		Parent = mainPanel,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0.5, 0),
		Parent = closeButton,
	})

	-- Store references
	BattlePassUI.ScreenGui = screenGui
	BattlePassUI.ToggleButton = toggleButton
	BattlePassUI.MainPanel = mainPanel
	BattlePassUI.NotifBadge = notifBadge

	-- Connect events
	toggleButton.MouseButton1Click:Connect(function()
		BattlePassUI.Toggle()
	end)

	closeButton.MouseButton1Click:Connect(function()
		BattlePassUI.Close()
	end)

	-- Keyboard shortcut (B key)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.B then
			BattlePassUI.Toggle()
		end
	end)

	return screenGui
end

-- ============================================================================
-- HEADER
-- ============================================================================

function BattlePassUI.CreateHeader(parent)
	local header = createInstance("Frame", {
		Name = "Header",
		Size = UDim2.new(1, -20, 0, 80),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = CONFIG.PanelColor,
		Parent = parent,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = header,
	})

	-- Season Title
	local seasonTitle = createInstance("TextLabel", {
		Name = "SeasonTitle",
		Size = UDim2.new(0.5, 0, 0, 30),
		Position = UDim2.new(0, 20, 0, 10),
		BackgroundTransparency = 1,
		Text = "BATTLE PASS - SEASON 1",
		TextColor3 = CONFIG.AccentColor,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	-- Season Name
	local seasonName = createInstance("TextLabel", {
		Name = "SeasonName",
		Size = UDim2.new(0.5, 0, 0, 20),
		Position = UDim2.new(0, 20, 0, 42),
		BackgroundTransparency = 1,
		Text = "Tower Legends",
		TextColor3 = CONFIG.SubTextColor,
		TextSize = 16,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	-- Premium Status
	local premiumStatus = createInstance("TextLabel", {
		Name = "PremiumStatus",
		Size = UDim2.new(0, 150, 0, 30),
		Position = UDim2.new(1, -170, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = CONFIG.LockedColor,
		Text = "FREE TRACK",
		TextColor3 = CONFIG.TextColor,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Parent = header,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = premiumStatus,
	})

	BattlePassUI.SeasonTitle = seasonTitle
	BattlePassUI.SeasonName = seasonName
	BattlePassUI.PremiumStatus = premiumStatus

	return header
end

-- ============================================================================
-- PROGRESS SECTION
-- ============================================================================

function BattlePassUI.CreateProgressSection(parent)
	local progressSection = createInstance("Frame", {
		Name = "ProgressSection",
		Size = UDim2.new(1, -20, 0, 100),
		Position = UDim2.new(0, 10, 0, 100),
		BackgroundColor3 = CONFIG.PanelColor,
		Parent = parent,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = progressSection,
	})

	-- Current Tier Display
	local tierDisplay = createInstance("Frame", {
		Name = "TierDisplay",
		Size = UDim2.new(0, 100, 0, 80),
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = CONFIG.AccentColor,
		Parent = progressSection,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 10),
		Parent = tierDisplay,
	})

	local tierLabel = createInstance("TextLabel", {
		Name = "TierLabel",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 5),
		BackgroundTransparency = 1,
		Text = "TIER",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = tierDisplay,
	})

	local tierNumber = createInstance("TextLabel", {
		Name = "TierNumber",
		Size = UDim2.new(1, 0, 0, 45),
		Position = UDim2.new(0, 0, 0, 25),
		BackgroundTransparency = 1,
		Text = "1",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 40,
		Font = Enum.Font.GothamBold,
		Parent = tierDisplay,
	})

	-- XP Progress
	local xpFrame = createInstance("Frame", {
		Name = "XPFrame",
		Size = UDim2.new(1, -180, 0, 60),
		Position = UDim2.new(0, 140, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = progressSection,
	})

	local xpLabel = createInstance("TextLabel", {
		Name = "XPLabel",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = "XP: 0 / 100",
		TextColor3 = CONFIG.TextColor,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = xpFrame,
	})

	local xpBarBg = createInstance("Frame", {
		Name = "XPBarBg",
		Size = UDim2.new(1, -20, 0, 25),
		Position = UDim2.new(0, 0, 0, 25),
		BackgroundColor3 = CONFIG.LockedColor,
		Parent = xpFrame,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = xpBarBg,
	})

	local xpBarFill = createInstance("Frame", {
		Name = "XPBarFill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = CONFIG.AccentColor,
		Parent = xpBarBg,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = xpBarFill,
	})

	local xpPercent = createInstance("TextLabel", {
		Name = "XPPercent",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "0%",
		TextColor3 = CONFIG.TextColor,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Parent = xpBarBg,
	})

	BattlePassUI.TierNumber = tierNumber
	BattlePassUI.XPLabel = xpLabel
	BattlePassUI.XPBarFill = xpBarFill
	BattlePassUI.XPPercent = xpPercent

	return progressSection
end

-- ============================================================================
-- REWARDS TRACK
-- ============================================================================

function BattlePassUI.CreateRewardsTrack(parent)
	local rewardsFrame = createInstance("Frame", {
		Name = "RewardsFrame",
		Size = UDim2.new(1, -20, 0, 280),
		Position = UDim2.new(0, 10, 0, 210),
		BackgroundColor3 = CONFIG.PanelColor,
		ClipsDescendants = true,
		Parent = parent,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = rewardsFrame,
	})

	-- Track Labels
	local freeLabel = createInstance("TextLabel", {
		Name = "FreeLabel",
		Size = UDim2.new(0, 100, 0, 25),
		Position = UDim2.new(0, 10, 0, 5),
		BackgroundTransparency = 1,
		Text = "FREE",
		TextColor3 = CONFIG.FreeColor,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = rewardsFrame,
	})

	local premiumLabel = createInstance("TextLabel", {
		Name = "PremiumLabel",
		Size = UDim2.new(0, 100, 0, 25),
		Position = UDim2.new(0, 10, 0, 140),
		BackgroundTransparency = 1,
		Text = "PREMIUM",
		TextColor3 = CONFIG.PremiumColor,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = rewardsFrame,
	})

	-- Scrolling Frame for Tier Cards
	local scrollFrame = createInstance("ScrollingFrame", {
		Name = "TierScroll",
		Size = UDim2.new(1, -10, 1, -35),
		Position = UDim2.new(0, 5, 0, 30),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = CONFIG.AccentColor,
		CanvasSize = UDim2.new(0, 50 * (CONFIG.TierCardWidth + CONFIG.TierCardSpacing), 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = rewardsFrame,
	})

	-- Create tier cards container
	local tierCardsContainer = createInstance("Frame", {
		Name = "TierCards",
		Size = UDim2.new(0, 50 * (CONFIG.TierCardWidth + CONFIG.TierCardSpacing), 1, 0),
		BackgroundTransparency = 1,
		Parent = scrollFrame,
	})

	BattlePassUI.ScrollFrame = scrollFrame
	BattlePassUI.TierCardsContainer = tierCardsContainer

	return rewardsFrame
end

function BattlePassUI.CreateTierCard(tier, freeReward, premiumReward, isUnlocked, freeClaimed, premiumClaimed, hasPremium)
	local cardWidth = CONFIG.TierCardWidth
	local cardX = (tier - 1) * (cardWidth + CONFIG.TierCardSpacing)

	local tierCard = createInstance("Frame", {
		Name = "Tier" .. tier,
		Size = UDim2.new(0, cardWidth, 1, -10),
		Position = UDim2.new(0, cardX, 0, 5),
		BackgroundColor3 = isUnlocked and CONFIG.PanelColor or CONFIG.LockedColor,
		Parent = BattlePassUI.TierCardsContainer,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = tierCard,
	})

	-- Tier Number
	local tierNum = createInstance("TextLabel", {
		Name = "TierNum",
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = isUnlocked and CONFIG.AccentColor or CONFIG.LockedColor,
		Text = tostring(tier),
		TextColor3 = isUnlocked and Color3.fromRGB(0, 0, 0) or CONFIG.SubTextColor,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		Parent = tierCard,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = tierNum,
	})

	-- Free Reward
	local freeBox = createInstance("Frame", {
		Name = "FreeBox",
		Size = UDim2.new(1, -10, 0, 80),
		Position = UDim2.new(0, 5, 0, 30),
		BackgroundColor3 = freeClaimed and CONFIG.FreeColor or (isUnlocked and CONFIG.PanelColor or CONFIG.LockedColor),
		Parent = tierCard,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = freeBox,
	})

	local freeText = createInstance("TextLabel", {
		Name = "FreeText",
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.new(0, 3, 0, 3),
		BackgroundTransparency = 1,
		Text = freeReward and getRewardText(freeReward) or "---",
		TextColor3 = CONFIG.TextColor,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		Parent = freeBox,
	})

	if freeReward and isUnlocked and not freeClaimed then
		local claimBtn = createInstance("TextButton", {
			Name = "ClaimFree",
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 1, -25),
			BackgroundColor3 = CONFIG.FreeColor,
			Text = "CLAIM",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			Parent = freeBox,
		})

		createInstance("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Parent = claimBtn,
		})

		claimBtn.MouseButton1Click:Connect(function()
			BattlePassUI.ClaimReward(tier, false)
		end)
	end

	-- Premium Reward
	local premiumBox = createInstance("Frame", {
		Name = "PremiumBox",
		Size = UDim2.new(1, -10, 0, 80),
		Position = UDim2.new(0, 5, 0, 115),
		BackgroundColor3 = premiumClaimed and CONFIG.PremiumColor or (isUnlocked and hasPremium and CONFIG.PanelColor or CONFIG.LockedColor),
		Parent = tierCard,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = premiumBox,
	})

	if not hasPremium then
		-- Lock icon for non-premium
		local lockIcon = createInstance("TextLabel", {
			Name = "LockIcon",
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 5),
			BackgroundTransparency = 1,
			Text = "🔒",
			TextSize = 20,
			Parent = premiumBox,
		})
	end

	local premiumText = createInstance("TextLabel", {
		Name = "PremiumText",
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.new(0, 3, 0, 3),
		BackgroundTransparency = 1,
		Text = premiumReward and getRewardText(premiumReward) or "---",
		TextColor3 = hasPremium and CONFIG.TextColor or CONFIG.SubTextColor,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		Parent = premiumBox,
	})

	if premiumReward and isUnlocked and hasPremium and not premiumClaimed then
		local claimBtn = createInstance("TextButton", {
			Name = "ClaimPremium",
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.new(0, 5, 1, -25),
			BackgroundColor3 = CONFIG.PremiumColor,
			Text = "CLAIM",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			Parent = premiumBox,
		})

		createInstance("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Parent = claimBtn,
		})

		claimBtn.MouseButton1Click:Connect(function()
			BattlePassUI.ClaimReward(tier, true)
		end)
	end

	return tierCard
end

-- ============================================================================
-- CHALLENGES PANEL
-- ============================================================================

function BattlePassUI.CreateChallengesPanel(parent)
	local challengesPanel = createInstance("Frame", {
		Name = "ChallengesPanel",
		Size = UDim2.new(1, -20, 0, 150),
		Position = UDim2.new(0, 10, 1, -160),
		BackgroundColor3 = CONFIG.PanelColor,
		Parent = parent,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = challengesPanel,
	})

	-- Title
	local title = createInstance("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 15, 0, 5),
		BackgroundTransparency = 1,
		Text = "CHALLENGES",
		TextColor3 = CONFIG.AccentColor,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = challengesPanel,
	})

	-- Daily Section
	local dailyFrame = createInstance("Frame", {
		Name = "DailyFrame",
		Size = UDim2.new(0.48, 0, 0, 100),
		Position = UDim2.new(0, 10, 0, 40),
		BackgroundColor3 = CONFIG.BackgroundColor,
		Parent = challengesPanel,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = dailyFrame,
	})

	local dailyLabel = createInstance("TextLabel", {
		Name = "DailyLabel",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 5),
		BackgroundTransparency = 1,
		Text = "📅 DAILY",
		TextColor3 = CONFIG.FreeColor,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = dailyFrame,
	})

	local dailyList = createInstance("Frame", {
		Name = "DailyList",
		Size = UDim2.new(1, -10, 1, -30),
		Position = UDim2.new(0, 5, 0, 25),
		BackgroundTransparency = 1,
		Parent = dailyFrame,
	})

	createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = dailyList,
	})

	-- Weekly Section
	local weeklyFrame = createInstance("Frame", {
		Name = "WeeklyFrame",
		Size = UDim2.new(0.48, 0, 0, 100),
		Position = UDim2.new(0.52, 0, 0, 40),
		BackgroundColor3 = CONFIG.BackgroundColor,
		Parent = challengesPanel,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = weeklyFrame,
	})

	local weeklyLabel = createInstance("TextLabel", {
		Name = "WeeklyLabel",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 5),
		BackgroundTransparency = 1,
		Text = "📆 WEEKLY",
		TextColor3 = CONFIG.PremiumColor,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = weeklyFrame,
	})

	local weeklyList = createInstance("Frame", {
		Name = "WeeklyList",
		Size = UDim2.new(1, -10, 1, -30),
		Position = UDim2.new(0, 5, 0, 25),
		BackgroundTransparency = 1,
		Parent = weeklyFrame,
	})

	createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = weeklyList,
	})

	-- Get Premium Button
	local getPremiumBtn = createInstance("TextButton", {
		Name = "GetPremiumBtn",
		Size = UDim2.new(0, 150, 0, 35),
		Position = UDim2.new(1, -160, 0, 5),
		BackgroundColor3 = CONFIG.PremiumColor,
		Text = "GET PREMIUM",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Parent = challengesPanel,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = getPremiumBtn,
	})

	getPremiumBtn.MouseButton1Click:Connect(function()
		BattlePassUI.PromptPremiumPurchase()
	end)

	BattlePassUI.DailyList = dailyList
	BattlePassUI.WeeklyList = weeklyList
	BattlePassUI.GetPremiumBtn = getPremiumBtn

	return challengesPanel
end

function BattlePassUI.CreateChallengeItem(challenge, parent)
	local item = createInstance("Frame", {
		Name = challenge.id,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local checkmark = createInstance("TextLabel", {
		Name = "Check",
		Size = UDim2.new(0, 20, 1, 0),
		BackgroundTransparency = 1,
		Text = challenge.completed and "✅" or "⬜",
		TextSize = 12,
		Parent = item,
	})

	local desc = createInstance("TextLabel", {
		Name = "Desc",
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 22, 0, 0),
		BackgroundTransparency = 1,
		Text = challenge.description,
		TextColor3 = challenge.completed and CONFIG.FreeColor or CONFIG.SubTextColor,
		TextSize = 10,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = item,
	})

	local xpReward = createInstance("TextLabel", {
		Name = "XP",
		Size = UDim2.new(0, 45, 1, 0),
		Position = UDim2.new(1, -45, 0, 0),
		BackgroundTransparency = 1,
		Text = "+" .. challenge.xp .. " XP",
		TextColor3 = CONFIG.AccentColor,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = item,
	})

	return item
end

-- ============================================================================
-- DATA HANDLING
-- ============================================================================

function BattlePassUI.UpdateDisplay(data)
	if not data then return end

	BattlePassUI.Data = data

	-- Update header
	if BattlePassUI.SeasonTitle then
		BattlePassUI.SeasonTitle.Text = "BATTLE PASS - SEASON " .. (data.SeasonNumber or 1)
	end

	if BattlePassUI.SeasonName then
		BattlePassUI.SeasonName.Text = data.SeasonName or "Tower Legends"
	end

	if BattlePassUI.PremiumStatus then
		if data.Premium then
			BattlePassUI.PremiumStatus.Text = "⭐ PREMIUM"
			BattlePassUI.PremiumStatus.BackgroundColor3 = CONFIG.PremiumColor
		else
			BattlePassUI.PremiumStatus.Text = "FREE TRACK"
			BattlePassUI.PremiumStatus.BackgroundColor3 = CONFIG.LockedColor
		end
	end

	-- Update progress
	if BattlePassUI.TierNumber then
		BattlePassUI.TierNumber.Text = tostring(data.Tier or 1)
	end

	local xp = data.XP or 0
	local xpNeeded = data.XPNeeded or 100
	local percent = math.clamp(xp / xpNeeded, 0, 1)

	if BattlePassUI.XPLabel then
		BattlePassUI.XPLabel.Text = string.format("XP: %s / %s", formatNumber(xp), formatNumber(xpNeeded))
	end

	if BattlePassUI.XPBarFill then
		TweenService:Create(BattlePassUI.XPBarFill, TweenInfo.new(0.3), {
			Size = UDim2.new(percent, 0, 1, 0)
		}):Play()
	end

	if BattlePassUI.XPPercent then
		BattlePassUI.XPPercent.Text = math.floor(percent * 100) .. "%"
	end

	-- Update tier cards
	BattlePassUI.UpdateTierCards(data)

	-- Update challenges
	BattlePassUI.UpdateChallenges(data)

	-- Update premium button visibility
	if BattlePassUI.GetPremiumBtn then
		BattlePassUI.GetPremiumBtn.Visible = not data.Premium
	end

	-- Check for claimable rewards (notification badge)
	BattlePassUI.UpdateNotificationBadge(data)
end

function BattlePassUI.UpdateTierCards(data)
	-- Clear existing cards
	for _, child in ipairs(BattlePassUI.TierCardsContainer:GetChildren()) do
		child:Destroy()
	end

	local maxTier = data.MaxTier or 50
	local currentTier = data.Tier or 1
	local rewards = data.Rewards or {}
	local claimedFree = data.ClaimedFree or {}
	local claimedPremium = data.ClaimedPremium or {}
	local hasPremium = data.Premium

	for tier = 1, maxTier do
		local tierRewards = rewards[tier] or {}
		local freeReward = tierRewards.free
		local premiumReward = tierRewards.premium
		local isUnlocked = tier <= currentTier
		local freeClaimed = claimedFree[tier]
		local premiumClaimed = claimedPremium[tier]

		BattlePassUI.CreateTierCard(tier, freeReward, premiumReward, isUnlocked, freeClaimed, premiumClaimed, hasPremium)
	end

	-- Scroll to current tier
	local scrollPos = math.max(0, (currentTier - 3) * (CONFIG.TierCardWidth + CONFIG.TierCardSpacing))
	BattlePassUI.ScrollFrame.CanvasPosition = Vector2.new(scrollPos, 0)
end

function BattlePassUI.UpdateChallenges(data)
	-- Clear existing challenges
	for _, child in ipairs(BattlePassUI.DailyList:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	for _, child in ipairs(BattlePassUI.WeeklyList:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Add daily challenges
	local dailyChallenges = data.DailyChallenges or {}
	for _, challenge in ipairs(dailyChallenges) do
		BattlePassUI.CreateChallengeItem(challenge, BattlePassUI.DailyList)
	end

	-- Add weekly challenges
	local weeklyChallenges = data.WeeklyChallenges or {}
	for _, challenge in ipairs(weeklyChallenges) do
		BattlePassUI.CreateChallengeItem(challenge, BattlePassUI.WeeklyList)
	end
end

function BattlePassUI.UpdateNotificationBadge(data)
	local hasClaimable = false

	local currentTier = data.Tier or 1
	local rewards = data.Rewards or {}
	local claimedFree = data.ClaimedFree or {}
	local claimedPremium = data.ClaimedPremium or {}
	local hasPremium = data.Premium

	for tier = 1, currentTier do
		local tierRewards = rewards[tier]
		if tierRewards then
			if tierRewards.free and not claimedFree[tier] then
				hasClaimable = true
				break
			end
			if tierRewards.premium and hasPremium and not claimedPremium[tier] then
				hasClaimable = true
				break
			end
		end
	end

	if BattlePassUI.NotifBadge then
		BattlePassUI.NotifBadge.Visible = hasClaimable
	end
end

-- ============================================================================
-- ACTIONS
-- ============================================================================

function BattlePassUI.Toggle()
	if BattlePassUI.IsOpen then
		BattlePassUI.Close()
	else
		BattlePassUI.Open()
	end
end

function BattlePassUI.Open()
	BattlePassUI.IsOpen = true

	-- Request fresh data
	if GetBattlePassData then
		local data = GetBattlePassData:InvokeServer()
		BattlePassUI.UpdateDisplay(data)
	end

	-- Show panel with animation
	BattlePassUI.MainPanel.Visible = true
	BattlePassUI.MainPanel.Size = UDim2.new(0, 0, 0, 0)

	TweenService:Create(BattlePassUI.MainPanel, TweenInfo.new(CONFIG.TweenSpeed, Enum.EasingStyle.Back), {
		Size = UDim2.new(0.9, 0, 0.85, 0)
	}):Play()
end

function BattlePassUI.Close()
	BattlePassUI.IsOpen = false

	TweenService:Create(BattlePassUI.MainPanel, TweenInfo.new(CONFIG.TweenSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()

	task.delay(CONFIG.TweenSpeed, function()
		if not BattlePassUI.IsOpen then
			BattlePassUI.MainPanel.Visible = false
		end
	end)
end

function BattlePassUI.ClaimReward(tier, isPremium)
	if ClaimReward then
		ClaimReward:FireServer(tier, isPremium)
	end
end

function BattlePassUI.PromptPremiumPurchase()
	if PromptPurchase then
		PromptPurchase:FireServer()
	end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

function BattlePassUI.SetupEvents()
	if BattlePassUpdate then
		BattlePassUpdate.OnClientEvent:Connect(function(data)
			BattlePassUI.UpdateDisplay(data)

			-- Show tier up notification
			if data.TierUp then
				BattlePassUI.ShowTierUpNotification(data.TierUp)
			end
		end)
	end
end

function BattlePassUI.ShowTierUpNotification(newTier)
	-- Create floating notification
	local notif = createInstance("Frame", {
		Name = "TierUpNotif",
		Size = UDim2.new(0, 200, 0, 60),
		Position = UDim2.new(0.5, 0, 0, -70),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = CONFIG.AccentColor,
		Parent = BattlePassUI.ScreenGui,
	})

	createInstance("UICorner", {
		CornerRadius = UDim.new(0, 10),
		Parent = notif,
	})

	local text = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "⬆️ TIER " .. newTier .. "!",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 24,
		Font = Enum.Font.GothamBold,
		Parent = notif,
	})

	-- Animate in
	TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, 0, 0, 20)
	}):Play()

	-- Animate out after delay
	task.delay(2.5, function()
		TweenService:Create(notif, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, -70)
		}):Play()

		task.delay(0.3, function()
			notif:Destroy()
		end)
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function BattlePassUI.Init()
	print("[BattlePassUI] Initializing...")

	BattlePassUI.Create()
	BattlePassUI.SetupEvents()

	-- Initial data request
	task.delay(1, function()
		if GetBattlePassData then
			local data = GetBattlePassData:InvokeServer()
			BattlePassUI.UpdateDisplay(data)
		end
	end)

	print("[BattlePassUI] Initialized - Press B or click button to open")
end

-- Auto-initialize
BattlePassUI.Init()

return BattlePassUI
