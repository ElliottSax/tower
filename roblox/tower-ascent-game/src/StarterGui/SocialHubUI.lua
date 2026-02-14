--[[
	SocialHubUI.lua
	Social features interface - friends, challenges, invites, sharing

	Features:
	- Friends Leaderboard tab (see friends' progress)
	- Challenges tab (active friend challenges)
	- Invite tab (invite friends, earn rewards)
	- Share tab (share achievements)
	- Activity Feed (what friends are doing)

	Controls:
	- 'F' key to toggle Social Hub
	- Tab navigation
	- Share buttons for achievements
	- Invite link generation

	Week 16: Social & Viral Features
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[SocialHubUI] RemoteEvents folder not found!")
	return
end

local getFriendsLeaderboard = remoteFolder:WaitForChild("GetFriendsLeaderboard", 10)
local shareAchievement = remoteFolder:WaitForChild("ShareAchievement", 10)
local inviteFriend = remoteFolder:WaitForChild("InviteFriend", 10)
local checkInviteCode = remoteFolder:WaitForChild("CheckInviteCode", 10)
local friendChallengeUpdate = remoteFolder:WaitForChild("FriendChallengeUpdate", 10)
local inviteCodeGenerated = remoteFolder:FindFirstChild("InviteCodeGenerated")

-- ============================================================================
-- STATE
-- ============================================================================

local isHubOpen = false
local currentTab = "Friends" -- Friends, Challenges, Invite, Share
local friendsLeaderboard = {}
local activeChallenges = {}
local inviteCode = nil
local shareableAchievements = {
	{Id = "FirstClimb", Name = "First Steps", Icon = "🏔️"},
	{Id = "Climber10", Name = "Dedicated Climber", Icon = "⛰️"},
	{Id = "Climber50", Name = "Tower Master", Icon = "🏆"},
	{Id = "SpeedRunner", Name = "Speed Runner", Icon = "⚡"},
	{Id = "ReachedSection25", Name = "Halfway There", Icon = "🎯"},
	{Id = "ReachedSection50", Name = "Summit Conquered", Icon = "🗻"},
}

-- ============================================================================
-- CREATE UI STRUCTURE
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SocialHubUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background overlay
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.6
background.BorderSizePixel = 0
background.Visible = false
background.ZIndex = 10
background.Parent = screenGui

-- Main hub frame
local hubFrame = Instance.new("Frame")
hubFrame.Name = "HubFrame"
hubFrame.AnchorPoint = Vector2.new(0.5, 0.5)
hubFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
hubFrame.Size = UDim2.new(0, 700, 0, 550)
hubFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
hubFrame.BorderSizePixel = 0
hubFrame.Visible = false
hubFrame.ZIndex = 11
hubFrame.Parent = screenGui

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(0, 20)
hubCorner.Parent = hubFrame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
header.BorderSizePixel = 0
header.ZIndex = 12
header.Parent = hubFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 300, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "👥 SOCIAL HUB"
title.TextColor3 = Color3.fromRGB(100, 200, 255) -- Light blue
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.ZIndex = 13
title.Parent = header

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -20, 0.5, 0)
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 24
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 13
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Position = UDim2.new(0, 0, 0, 60)
tabBar.Size = UDim2.new(1, 0, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 12
tabBar.Parent = hubFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 0)
tabLayout.Parent = tabBar

-- Content area
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Position = UDim2.new(0, 0, 0, 110)
contentFrame.Size = UDim2.new(1, 0, 1, -110)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 8
contentFrame.ZIndex = 12
contentFrame.Parent = hubFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 10)
contentLayout.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 20)
contentPadding.PaddingRight = UDim.new(0, 20)
contentPadding.Parent = contentFrame

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function CreateTab(name, icon, order)
	local tab = Instance.new("TextButton")
	tab.Name = name .. "Tab"
	tab.Size = UDim2.new(0.25, 0, 1, 0)
	tab.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	tab.BorderSizePixel = 0
	tab.Text = icon .. " " .. name
	tab.TextColor3 = Color3.fromRGB(180, 180, 180)
	tab.TextSize = 16
	tab.Font = Enum.Font.GothamSemibold
	tab.LayoutOrder = order
	tab.ZIndex = 13
	tab.Parent = tabBar

	return tab
end

local function UpdateTabStyles()
	for _, tab in ipairs(tabBar:GetChildren()) do
		if tab:IsA("TextButton") then
			local tabName = tab.Name:gsub("Tab", "")
			if tabName == currentTab then
				tab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
				tab.TextColor3 = Color3.fromRGB(100, 200, 255)
			else
				tab.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
				tab.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
		end
	end
end

local function ClearContent()
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

-- ============================================================================
-- FRIENDS LEADERBOARD TAB
-- ============================================================================

local function CreateFriendEntry(rank, friendData, isPlayer)
	local entry = Instance.new("Frame")
	entry.Name = "FriendEntry"
	entry.Size = UDim2.new(1, -40, 0, 60)
	entry.BackgroundColor3 = isPlayer and Color3.fromRGB(50, 100, 150) or Color3.fromRGB(35, 35, 40)
	entry.BorderSizePixel = 0
	entry.ZIndex = 13

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 10)
	entryCorner.Parent = entry

	-- Rank
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "Rank"
	rankLabel.Position = UDim2.new(0, 15, 0, 0)
	rankLabel.Size = UDim2.new(0, 40, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. rank
	rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	rankLabel.TextSize = 20
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.ZIndex = 14
	rankLabel.Parent = entry

	-- Username
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Username"
	nameLabel.Position = UDim2.new(0, 65, 0, 10)
	nameLabel.Size = UDim2.new(0.5, -75, 0, 25)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = friendData.Username .. (isPlayer and " (You)" or "")
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 14
	nameLabel.Parent = entry

	-- Stats
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "Stats"
	statsLabel.Position = UDim2.new(0, 65, 0, 35)
	statsLabel.Size = UDim2.new(0.5, -75, 0, 20)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = string.format("Section %d • %d Climbs", friendData.HighestSection, friendData.TotalClimbs)
	statsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	statsLabel.TextSize = 14
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.ZIndex = 14
	statsLabel.Parent = entry

	-- Progress indicator
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.AnchorPoint = Vector2.new(1, 0.5)
	progressBar.Position = UDim2.new(1, -15, 0.5, 0)
	progressBar.Size = UDim2.new(0.3, 0, 0, 8)
	progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 14
	progressBar.Parent = entry

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBar

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(friendData.HighestSection / 50, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 15
	progressFill.Parent = progressBar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	return entry
end

local function PopulateFriendsTab()
	ClearContent()

	-- Show loading indicator
	local loading = Instance.new("TextLabel")
	loading.Name = "Loading"
	loading.Size = UDim2.new(1, 0, 0, 50)
	loading.BackgroundTransparency = 1
	loading.Text = "Loading friends..."
	loading.TextColor3 = Color3.fromRGB(180, 180, 180)
	loading.TextSize = 18
	loading.Font = Enum.Font.Gotham
	loading.ZIndex = 13
	loading.Parent = contentFrame

	-- Fetch friends leaderboard
	if not getFriendsLeaderboard then
		loading.Text = "Error: RemoteFunction not found"
		return
	end

	task.spawn(function()
		local success, result = pcall(function()
			return getFriendsLeaderboard:InvokeServer()
		end)

		if not success or not result then
			loading.Text = "Failed to load friends leaderboard"
			return
		end

		loading:Destroy()

		friendsLeaderboard = result

		-- Show no friends message
		if #result.Friends == 0 then
			local noFriends = Instance.new("TextLabel")
			noFriends.Size = UDim2.new(1, 0, 0, 100)
			noFriends.BackgroundTransparency = 1
			noFriends.Text = "No friends playing Tower Ascent yet!\n\nInvite your friends to compete! 🎮"
			noFriends.TextColor3 = Color3.fromRGB(180, 180, 180)
			noFriends.TextSize = 16
			noFriends.Font = Enum.Font.Gotham
			noFriends.ZIndex = 13
			noFriends.Parent = contentFrame
			return
		end

		-- Show friends
		for rank, friend in ipairs(result.Friends) do
			local isPlayer = friend.UserId == player.UserId
			local entry = CreateFriendEntry(rank, friend, isPlayer)
			entry.Parent = contentFrame
		end

		-- Show player's rank if not in top
		if result.PlayerRank > #result.Friends then
			local playerRankLabel = Instance.new("TextLabel")
			playerRankLabel.Size = UDim2.new(1, 0, 0, 40)
			playerRankLabel.BackgroundTransparency = 1
			playerRankLabel.Text = string.format("Your Rank: #%d / %d friends", result.PlayerRank, result.TotalFriends)
			playerRankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			playerRankLabel.TextSize = 16
			playerRankLabel.Font = Enum.Font.GothamBold
			playerRankLabel.ZIndex = 13
			playerRankLabel.Parent = contentFrame
		end
	end)
end

-- ============================================================================
-- CHALLENGES TAB
-- ============================================================================

local function PopulateChallengesTab()
	ClearContent()

	if #activeChallenges == 0 then
		local noChallenges = Instance.new("TextLabel")
		noChallenges.Size = UDim2.new(1, 0, 0, 100)
		noChallenges.BackgroundTransparency = 1
		noChallenges.Text = "No active challenges\n\nBeat your friends to unlock rewards! 🏆"
		noChallenges.TextColor3 = Color3.fromRGB(180, 180, 180)
		noChallenges.TextSize = 16
		noChallenges.Font = Enum.Font.Gotham
		noChallenges.ZIndex = 13
		noChallenges.Parent = contentFrame
		return
	end

	for _, challenge in ipairs(activeChallenges) do
		local challengeCard = Instance.new("Frame")
		challengeCard.Name = "Challenge"
		challengeCard.Size = UDim2.new(1, -40, 0, 120)
		challengeCard.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		challengeCard.BorderSizePixel = 0
		challengeCard.ZIndex = 13
		challengeCard.Parent = contentFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 12)
		cardCorner.Parent = challengeCard

		-- Challenge title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Position = UDim2.new(0, 15, 0, 10)
		titleLabel.Size = UDim2.new(1, -30, 0, 30)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "🎯 " .. challenge.Type
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		titleLabel.TextSize = 20
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.ZIndex = 14
		titleLabel.Parent = challengeCard

		-- Challenge description
		local descLabel = Instance.new("TextLabel")
		descLabel.Position = UDim2.new(0, 15, 0, 45)
		descLabel.Size = UDim2.new(1, -30, 0, 40)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = string.format("Beat %s's record (Section %d)", challenge.FriendName, challenge.FriendSection)
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.TextSize = 16
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Font = Enum.Font.Gotham
		descLabel.ZIndex = 14
		descLabel.Parent = challengeCard

		-- Reward
		local rewardLabel = Instance.new("TextLabel")
		rewardLabel.Position = UDim2.new(0, 15, 1, -35)
		rewardLabel.Size = UDim2.new(1, -30, 0, 25)
		rewardLabel.BackgroundTransparency = 1
		rewardLabel.Text = string.format("💰 Reward: %d coins", challenge.Reward)
		rewardLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
		rewardLabel.TextSize = 14
		rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
		rewardLabel.Font = Enum.Font.GothamBold
		rewardLabel.ZIndex = 14
		rewardLabel.Parent = challengeCard
	end
end

-- ============================================================================
-- INVITE TAB
-- ============================================================================

local function PopulateInviteTab()
	ClearContent()

	-- Invite description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -40, 0, 80)
	desc.BackgroundTransparency = 1
	desc.Text = "Invite your friends to Tower Ascent!\n\nYou get 1,000 coins per invite.\nThey get 500 coins + VIP trial!"
	desc.TextColor3 = Color3.fromRGB(180, 180, 180)
	desc.TextSize = 16
	desc.Font = Enum.Font.Gotham
	desc.TextWrapped = true
	desc.ZIndex = 13
	desc.Parent = contentFrame

	-- Generate invite button
	local generateButton = Instance.new("TextButton")
	generateButton.Size = UDim2.new(1, -40, 0, 50)
	generateButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	generateButton.Text = "🎁 GENERATE INVITE LINK"
	generateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	generateButton.TextSize = 18
	generateButton.Font = Enum.Font.GothamBold
	generateButton.ZIndex = 13
	generateButton.Parent = contentFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = generateButton

	-- Invite code display
	local codeFrame = Instance.new("Frame")
	codeFrame.Size = UDim2.new(1, -40, 0, 100)
	codeFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	codeFrame.BorderSizePixel = 0
	codeFrame.Visible = false
	codeFrame.ZIndex = 13
	codeFrame.Parent = contentFrame

	local codeCorner = Instance.new("UICorner")
	codeCorner.CornerRadius = UDim.new(0, 10)
	codeCorner.Parent = codeFrame

	local codeLabel = Instance.new("TextLabel")
	codeLabel.Size = UDim2.new(1, -20, 0, 40)
	codeLabel.Position = UDim2.new(0, 10, 0, 10)
	codeLabel.BackgroundTransparency = 1
	codeLabel.Text = "Your Invite Code:"
	codeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	codeLabel.TextSize = 14
	codeLabel.Font = Enum.Font.Gotham
	codeLabel.ZIndex = 14
	codeLabel.Parent = codeFrame

	local codeText = Instance.new("TextLabel")
	codeText.Size = UDim2.new(1, -20, 0, 40)
	codeText.Position = UDim2.new(0, 10, 0, 50)
	codeText.BackgroundTransparency = 1
	codeText.Text = inviteCode or "LOADING..."
	codeText.TextColor3 = Color3.fromRGB(255, 215, 0)
	codeText.TextSize = 20
	codeText.Font = Enum.Font.GothamBold
	codeText.ZIndex = 14
	codeText.Parent = codeFrame

	generateButton.MouseButton1Click:Connect(function()
		generateButton.Text = "GENERATING..."
		generateButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)

		if inviteFriend then
			inviteFriend:FireServer()
		end
	end)
end

-- ============================================================================
-- SHARE TAB
-- ============================================================================

local function PopulateShareTab()
	ClearContent()

	-- Share description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -40, 0, 60)
	desc.BackgroundTransparency = 1
	desc.Text = "Share your achievements and earn coins!\n\nFirst share: 200 coins • Each share: 50 coins"
	desc.TextColor3 = Color3.fromRGB(180, 180, 180)
	desc.TextSize = 16
	desc.Font = Enum.Font.Gotham
	desc.TextWrapped = true
	desc.ZIndex = 13
	desc.Parent = contentFrame

	-- Achievement cards
	for _, achievement in ipairs(shareableAchievements) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -40, 0, 80)
		card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		card.BorderSizePixel = 0
		card.ZIndex = 13
		card.Parent = contentFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		-- Achievement name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Position = UDim2.new(0, 15, 0, 10)
		nameLabel.Size = UDim2.new(0.7, -15, 0, 25)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = achievement.Icon .. " " .. achievement.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 18
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.ZIndex = 14
		nameLabel.Parent = card

		-- Share button
		local shareButton = Instance.new("TextButton")
		shareButton.AnchorPoint = Vector2.new(1, 0.5)
		shareButton.Position = UDim2.new(1, -15, 0.5, 0)
		shareButton.Size = UDim2.new(0, 100, 0, 35)
		shareButton.BackgroundColor3 = Color3.fromRGB(0, 150, 250)
		shareButton.Text = "SHARE"
		shareButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		shareButton.TextSize = 16
		shareButton.Font = Enum.Font.GothamBold
		shareButton.ZIndex = 14
		shareButton.Parent = card

		local shareCorner = Instance.new("UICorner")
		shareCorner.CornerRadius = UDim.new(0, 8)
		shareCorner.Parent = shareButton

		shareButton.MouseButton1Click:Connect(function()
			shareButton.Text = "SHARED!"
			shareButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)

			if shareAchievement then
				shareAchievement:FireServer(achievement.Id)
			end

			task.wait(2)
			shareButton.Text = "SHARE"
			shareButton.BackgroundColor3 = Color3.fromRGB(0, 150, 250)
		end)
	end
end

-- ============================================================================
-- TAB SWITCHING
-- ============================================================================

local function SwitchTab(tabName)
	currentTab = tabName
	UpdateTabStyles()

	if tabName == "Friends" then
		PopulateFriendsTab()
	elseif tabName == "Challenges" then
		PopulateChallengesTab()
	elseif tabName == "Invite" then
		PopulateInviteTab()
	elseif tabName == "Share" then
		PopulateShareTab()
	end
end

-- ============================================================================
-- HUB TOGGLE
-- ============================================================================

local function ToggleHub()
	isHubOpen = not isHubOpen
	background.Visible = isHubOpen
	hubFrame.Visible = isHubOpen

	if isHubOpen then
		SwitchTab(currentTab)
	end
end

-- ============================================================================
-- CREATE TABS
-- ============================================================================

local friendsTab = CreateTab("Friends", "👥", 1)
local challengesTab = CreateTab("Challenges", "🎯", 2)
local inviteTab = CreateTab("Invite", "🎁", 3)
local shareTab = CreateTab("Share", "📱", 4)

friendsTab.MouseButton1Click:Connect(function() SwitchTab("Friends") end)
challengesTab.MouseButton1Click:Connect(function() SwitchTab("Challenges") end)
inviteTab.MouseButton1Click:Connect(function() SwitchTab("Invite") end)
shareTab.MouseButton1Click:Connect(function() SwitchTab("Share") end)

closeButton.MouseButton1Click:Connect(function() ToggleHub() end)
background.MouseButton1Click:Connect(function() ToggleHub() end)

-- ============================================================================
-- KEYBOARD INPUT
-- ============================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		ToggleHub()
	end
end)

-- ============================================================================
-- SERVER EVENTS
-- ============================================================================

-- Friend challenge updates
if friendChallengeUpdate then
	friendChallengeUpdate.OnClientEvent:Connect(function(challengeData)
		table.insert(activeChallenges, challengeData)

		-- Show notification
		print(string.format(
			"[SocialHubUI] New challenge: Beat %s (Section %d) for %d coins!",
			challengeData.FriendName,
			challengeData.FriendSection,
			challengeData.Reward
		))

		-- Update challenges tab if open
		if isHubOpen and currentTab == "Challenges" then
			PopulateChallengesTab()
		end
	end)
end

-- Invite code generated
if inviteCodeGenerated then
	inviteCodeGenerated.OnClientEvent:Connect(function(code)
		inviteCode = code
		print("[SocialHubUI] Invite code generated:", code)

		-- Update invite tab if open
		if isHubOpen and currentTab == "Invite" then
			PopulateInviteTab()
		end
	end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

UpdateTabStyles()
print("[SocialHubUI] Social Hub initialized. Press 'F' to open.")
