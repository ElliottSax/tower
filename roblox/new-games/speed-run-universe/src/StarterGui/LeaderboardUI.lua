--[[
	LeaderboardUI.lua - Speed Run Universe
	Leaderboard panel showing global rankings, personal bests, challenge progress,
	and tournament standings. Toggle with L key.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local LeaderboardUI = {}
local screenGui
local mainFrame
local isOpen = false
local currentTab = "Times"

-- ============================================================================
-- COLORS
-- ============================================================================
local Colors = {
	Background = Color3.fromRGB(15, 15, 25),
	Panel = Color3.fromRGB(22, 22, 36),
	Row = Color3.fromRGB(28, 28, 45),
	RowAlt = Color3.fromRGB(22, 22, 36),
	RowHighlight = Color3.fromRGB(35, 35, 55),
	Accent = Color3.fromRGB(0, 200, 255),
	Gold = Color3.fromRGB(255, 200, 0),
	Silver = Color3.fromRGB(200, 200, 210),
	Bronze = Color3.fromRGB(205, 127, 50),
	Green = Color3.fromRGB(0, 255, 120),
	Red = Color3.fromRGB(255, 60, 60),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	TextMuted = Color3.fromRGB(100, 100, 120),
	PlayerHighlight = Color3.fromRGB(0, 100, 180),
}

-- ============================================================================
-- INIT
-- ============================================================================
function LeaderboardUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeaderboardUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	LeaderboardUI._CreateToggleButton()
	LeaderboardUI._CreateMainFrame()

	-- Key binding: L to toggle
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.L then
			LeaderboardUI.Toggle()
		end
	end)

	-- Listen for leaderboard data
	remoteEvents:WaitForChild("LeaderboardData").OnClientEvent:Connect(function(data)
		LeaderboardUI._PopulateLeaderboard(data)
	end)

	-- Listen for challenge sync
	remoteEvents:WaitForChild("ChallengeSync").OnClientEvent:Connect(function(data)
		if currentTab == "Challenges" and isOpen then
			LeaderboardUI._PopulateChallenges(data)
		end
	end)

	-- Listen for tournament sync
	remoteEvents:WaitForChild("TournamentSync").OnClientEvent:Connect(function(data)
		if currentTab == "Tournament" and isOpen then
			LeaderboardUI._PopulateTournament(data)
		end
	end)
end

-- ============================================================================
-- TOGGLE BUTTON
-- ============================================================================
function LeaderboardUI._CreateToggleButton()
	local btn = Instance.new("TextButton")
	btn.Name = "LeaderboardToggle"
	btn.Size = UDim2.new(0, 100, 0, 32)
	btn.Position = UDim2.new(1, -370, 0, 8)
	btn.BackgroundColor3 = Colors.Accent
	btn.BackgroundTransparency = 0.3
	btn.BorderSizePixel = 0
	btn.Text = "RANKS [L]"
	btn.TextColor3 = Colors.TextPrimary
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		LeaderboardUI.Toggle()
	end)
end

-- ============================================================================
-- MAIN FRAME
-- ============================================================================
function LeaderboardUI._CreateMainFrame()
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "LeaderboardMain"
	mainFrame.Size = UDim2.new(0, 600, 0, 520)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -260)
	mainFrame.BackgroundColor3 = Colors.Background
	mainFrame.BackgroundTransparency = 0.05
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Accent
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Colors.Panel
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "LEADERBOARDS"
	titleLabel.TextColor3 = Colors.Gold
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Colors.Red
	closeBtn.BackgroundTransparency = 0.5
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Colors.TextPrimary
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		LeaderboardUI.Toggle()
	end)

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 34)
	tabBar.Position = UDim2.new(0, 10, 0, 45)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = mainFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = tabBar

	local tabs = { "Times", "Stats", "Challenges", "Tournament" }
	for _, tabName in ipairs(tabs) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab_" .. tabName
		tab.Size = UDim2.new(0, 130, 0, 30)
		tab.BackgroundColor3 = tabName == currentTab and Colors.Accent or Colors.Row
		tab.BackgroundTransparency = tabName == currentTab and 0.2 or 0.5
		tab.BorderSizePixel = 0
		tab.Text = tabName
		tab.TextColor3 = tabName == currentTab and Colors.TextPrimary or Colors.TextSecondary
		tab.TextSize = 12
		tab.Font = Enum.Font.GothamBold
		tab.Parent = tabBar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tab

		tab.MouseButton1Click:Connect(function()
			LeaderboardUI._SwitchTab(tabName)
		end)
	end

	-- World/category selector (for Times tab)
	local selectorFrame = Instance.new("Frame")
	selectorFrame.Name = "Selector"
	selectorFrame.Size = UDim2.new(1, -20, 0, 30)
	selectorFrame.Position = UDim2.new(0, 10, 0, 82)
	selectorFrame.BackgroundTransparency = 1
	selectorFrame.Parent = mainFrame

	local selectorLayout = Instance.new("UIListLayout")
	selectorLayout.FillDirection = Enum.FillDirection.Horizontal
	selectorLayout.Padding = UDim.new(0, 4)
	selectorLayout.Parent = selectorFrame

	-- Add world buttons for filtering
	for _, world in ipairs(GameConfig.Worlds) do
		local btn = Instance.new("TextButton")
		btn.Name = "World_" .. world.Id
		btn.Size = UDim2.new(0, 52, 0, 24)
		btn.BackgroundColor3 = world.BackgroundColor
		btn.BackgroundTransparency = 0.5
		btn.BorderSizePixel = 0
		btn.Text = world.Id
		btn.TextColor3 = Colors.TextPrimary
		btn.TextSize = 9
		btn.Font = Enum.Font.GothamBold
		btn.Parent = selectorFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			LeaderboardUI._RequestLeaderboard("WorldBestTime", world.Id .. "_World")
		end)
	end

	-- Content area (scrolling)
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -20, 1, -125)
	contentFrame.Position = UDim2.new(0, 10, 0, 115)
	contentFrame.BackgroundColor3 = Colors.Panel
	contentFrame.BackgroundTransparency = 0.5
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 6
	contentFrame.ScrollBarImageColor3 = Colors.Accent
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 10)
	contentCorner.Parent = contentFrame

	-- Header row
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundColor3 = Colors.Panel
	header.BorderSizePixel = 0
	header.Parent = contentFrame

	local cols = { { "Rank", 0.12 }, { "Player", 0.45 }, { "Time / Value", 0.43 } }
	for _, col in ipairs(cols) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(col[2], 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = col[1]
		lbl.TextColor3 = Colors.TextMuted
		lbl.TextSize = 10
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = header
	end

	-- Position columns
	local children = {}
	for _, c in ipairs(header:GetChildren()) do
		if c:IsA("TextLabel") then table.insert(children, c) end
	end
	local xOff = 0
	for i, c in ipairs(children) do
		c.Position = UDim2.new(xOff, 5, 0, 0)
		c.TextXAlignment = Enum.TextXAlignment.Left
		xOff = xOff + cols[i][2]
	end

	-- Entry list
	local entryList = Instance.new("Frame")
	entryList.Name = "EntryList"
	entryList.Size = UDim2.new(1, 0, 1, -30)
	entryList.Position = UDim2.new(0, 0, 0, 30)
	entryList.BackgroundTransparency = 1
	entryList.Parent = contentFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 1)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = entryList

	-- Player rank display at bottom
	local playerRankFrame = Instance.new("Frame")
	playerRankFrame.Name = "PlayerRank"
	playerRankFrame.Size = UDim2.new(1, -20, 0, 30)
	playerRankFrame.Position = UDim2.new(0, 10, 1, -35)
	playerRankFrame.BackgroundColor3 = Colors.PlayerHighlight
	playerRankFrame.BackgroundTransparency = 0.3
	playerRankFrame.BorderSizePixel = 0
	playerRankFrame.Parent = mainFrame

	local prCorner = Instance.new("UICorner")
	prCorner.CornerRadius = UDim.new(0, 8)
	prCorner.Parent = playerRankFrame

	local yourRank = Instance.new("TextLabel")
	yourRank.Name = "YourRankLabel"
	yourRank.Size = UDim2.new(1, -10, 1, 0)
	yourRank.Position = UDim2.new(0, 10, 0, 0)
	yourRank.BackgroundTransparency = 1
	yourRank.Text = "Your Rank: -- | Best: --"
	yourRank.TextColor3 = Colors.Accent
	yourRank.TextSize = 12
	yourRank.Font = Enum.Font.GothamBold
	yourRank.TextXAlignment = Enum.TextXAlignment.Left
	yourRank.Parent = playerRankFrame
end

-- ============================================================================
-- TAB SWITCHING
-- ============================================================================
function LeaderboardUI._SwitchTab(tabName)
	currentTab = tabName

	local tabBar = mainFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, tab in ipairs(tabBar:GetChildren()) do
			if tab:IsA("TextButton") then
				local isActive = tab.Name == "Tab_" .. tabName
				tab.BackgroundColor3 = isActive and Colors.Accent or Colors.Row
				tab.BackgroundTransparency = isActive and 0.2 or 0.5
				tab.TextColor3 = isActive and Colors.TextPrimary or Colors.TextSecondary
			end
		end
	end

	-- Show/hide world selector
	local selector = mainFrame:FindFirstChild("Selector")
	if selector then
		selector.Visible = (tabName == "Times")
	end

	if tabName == "Times" then
		LeaderboardUI._RequestLeaderboard("WorldBestTime", "Grass_World")
	elseif tabName == "Stats" then
		LeaderboardUI._RequestLeaderboard("TotalCoins", nil)
	elseif tabName == "Challenges" then
		remoteEvents:WaitForChild("RequestChallenges"):FireServer()
	elseif tabName == "Tournament" then
		remoteEvents:WaitForChild("RequestTournament"):FireServer()
	end
end

-- ============================================================================
-- REQUEST LEADERBOARD
-- ============================================================================
function LeaderboardUI._RequestLeaderboard(category, key)
	remoteEvents:WaitForChild("RequestLeaderboard"):FireServer({
		Category = category,
		Key = key,
		MaxEntries = 50,
	})
end

-- ============================================================================
-- POPULATE LEADERBOARD
-- ============================================================================
function LeaderboardUI._PopulateLeaderboard(data)
	local content = mainFrame:FindFirstChild("Content")
	if not content then return end
	local entryList = content:FindFirstChild("EntryList")
	if not entryList then return end

	-- Clear
	for _, child in ipairs(entryList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local entries = data.Entries or {}
	local isTimeBased = (data.Category == "WorldBestTime" or data.Category == "StageBestTime")

	for i, entry in ipairs(entries) do
		local row = Instance.new("Frame")
		row.Name = "Entry_" .. i
		row.Size = UDim2.new(1, 0, 0, 28)
		row.LayoutOrder = i
		row.BorderSizePixel = 0
		row.Parent = entryList

		-- Highlight player's own row
		local isPlayer = entry.UserId == player.UserId
		row.BackgroundColor3 = isPlayer and Colors.PlayerHighlight or (i % 2 == 0 and Colors.RowAlt or Colors.Row)
		row.BackgroundTransparency = isPlayer and 0.3 or 0.3

		-- Rank
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0.12, 0, 1, 0)
		rankLabel.Position = UDim2.new(0, 5, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. entry.Rank
		rankLabel.TextXAlignment = Enum.TextXAlignment.Left
		rankLabel.TextSize = 13
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.Parent = row

		-- Rank color
		if entry.Rank == 1 then
			rankLabel.TextColor3 = Colors.Gold
		elseif entry.Rank == 2 then
			rankLabel.TextColor3 = Colors.Silver
		elseif entry.Rank == 3 then
			rankLabel.TextColor3 = Colors.Bronze
		else
			rankLabel.TextColor3 = Colors.TextSecondary
		end

		-- Player name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.12, 5, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.PlayerName or "Unknown"
		nameLabel.TextColor3 = isPlayer and Colors.Accent or Colors.TextPrimary
		nameLabel.TextSize = 12
		nameLabel.Font = isPlayer and Enum.Font.GothamBold or Enum.Font.GothamMedium
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = row

		-- Value
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.43, 0, 1, 0)
		valueLabel.Position = UDim2.new(0.57, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.TextSize = 12
		valueLabel.Font = Enum.Font.Code
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = row

		if isTimeBased then
			local seconds = entry.Value / 1000
			valueLabel.Text = LeaderboardUI._FormatTime(seconds)
			valueLabel.TextColor3 = Colors.Green
		else
			valueLabel.Text = LeaderboardUI._FormatNumber(entry.Value)
			valueLabel.TextColor3 = Colors.Gold
		end
	end

	-- Update canvas size
	task.wait()
	local listLayout = entryList:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 40)
	end

	-- Update player rank
	local playerRankFrame = mainFrame:FindFirstChild("PlayerRank")
	if playerRankFrame then
		local label = playerRankFrame:FindFirstChild("YourRankLabel")
		if label then
			local rankText = data.PlayerRank and ("#" .. data.PlayerRank) or "Unranked"
			local valueText = ""
			if data.PlayerValue then
				if isTimeBased then
					valueText = LeaderboardUI._FormatTime(data.PlayerValue / 1000)
				else
					valueText = LeaderboardUI._FormatNumber(data.PlayerValue)
				end
			else
				valueText = "--"
			end
			label.Text = "Your Rank: " .. rankText .. "  |  Best: " .. valueText
		end
	end
end

-- ============================================================================
-- POPULATE CHALLENGES
-- ============================================================================
function LeaderboardUI._PopulateChallenges(data)
	local content = mainFrame:FindFirstChild("Content")
	if not content then return end
	local entryList = content:FindFirstChild("EntryList")
	if not entryList then return end

	-- Clear
	for _, child in ipairs(entryList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Hide header
	local header = content:FindFirstChild("Header")
	if header then header.Visible = false end

	local layoutOrder = 0

	-- Daily challenges
	local dailyTitle = Instance.new("TextLabel")
	dailyTitle.Size = UDim2.new(1, 0, 0, 24)
	dailyTitle.BackgroundTransparency = 1
	dailyTitle.Text = "DAILY CHALLENGES"
	dailyTitle.TextColor3 = Colors.Gold
	dailyTitle.TextSize = 13
	dailyTitle.Font = Enum.Font.GothamBold
	dailyTitle.TextXAlignment = Enum.TextXAlignment.Left
	dailyTitle.LayoutOrder = layoutOrder
	dailyTitle.Parent = entryList
	layoutOrder = layoutOrder + 1

	if data.DailyChallenges then
		for i, challenge in ipairs(data.DailyChallenges) do
			LeaderboardUI._CreateChallengeRow(entryList, challenge, "daily", i, layoutOrder)
			layoutOrder = layoutOrder + 1
		end
	end

	-- Spacer
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 10)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = layoutOrder
	spacer.Parent = entryList
	layoutOrder = layoutOrder + 1

	-- Weekly challenges
	local weeklyTitle = Instance.new("TextLabel")
	weeklyTitle.Size = UDim2.new(1, 0, 0, 24)
	weeklyTitle.BackgroundTransparency = 1
	weeklyTitle.Text = "WEEKLY CHALLENGES"
	weeklyTitle.TextColor3 = Colors.Accent
	weeklyTitle.TextSize = 13
	weeklyTitle.Font = Enum.Font.GothamBold
	weeklyTitle.TextXAlignment = Enum.TextXAlignment.Left
	weeklyTitle.LayoutOrder = layoutOrder
	weeklyTitle.Parent = entryList
	layoutOrder = layoutOrder + 1

	if data.WeeklyChallenges then
		for i, challenge in ipairs(data.WeeklyChallenges) do
			LeaderboardUI._CreateChallengeRow(entryList, challenge, "weekly", i, layoutOrder)
			layoutOrder = layoutOrder + 1
		end
	end

	-- Update canvas
	task.wait()
	local listLayout = entryList:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end
end

function LeaderboardUI._CreateChallengeRow(parent, challenge, period, index, layoutOrder)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = challenge.Completed and Colors.Green or Colors.Row
	row.BackgroundTransparency = challenge.Completed and 0.7 or 0.3
	row.BorderSizePixel = 0
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.6, -10, 0, 20)
	desc.Position = UDim2.new(0, 10, 0, 4)
	desc.BackgroundTransparency = 1
	desc.Text = challenge.Description or "Challenge"
	desc.TextColor3 = Colors.TextPrimary
	desc.TextSize = 11
	desc.Font = Enum.Font.GothamMedium
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.Parent = row

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(0.6, -20, 0, 6)
	progressBg.Position = UDim2.new(0, 10, 0, 28)
	progressBg.BackgroundColor3 = Colors.Panel
	progressBg.BorderSizePixel = 0
	progressBg.Parent = row

	local progressFill = Instance.new("Frame")
	local ratio = challenge.Target > 0 and math.min(1, challenge.Progress / challenge.Target) or 0
	progressFill.Size = UDim2.new(ratio, 0, 1, 0)
	progressFill.BackgroundColor3 = challenge.Completed and Colors.Green or Colors.Accent
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	-- Progress text
	local progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(0.6, -20, 0, 12)
	progressText.Position = UDim2.new(0, 10, 0, 35)
	progressText.BackgroundTransparency = 1
	progressText.Text = challenge.Progress .. " / " .. challenge.Target
	progressText.TextColor3 = Colors.TextMuted
	progressText.TextSize = 9
	progressText.Font = Enum.Font.GothamMedium
	progressText.TextXAlignment = Enum.TextXAlignment.Left
	progressText.Parent = row

	-- Reward
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(0.2, 0, 0, 20)
	rewardLabel.Position = UDim2.new(0.6, 0, 0, 4)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "+" .. (challenge.CoinReward or 0) .. " coins"
	rewardLabel.TextColor3 = Colors.Gold
	rewardLabel.TextSize = 11
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Parent = row

	-- Claim button
	if challenge.Completed and not challenge.Claimed then
		local claimBtn = Instance.new("TextButton")
		claimBtn.Size = UDim2.new(0.18, 0, 0, 26)
		claimBtn.Position = UDim2.new(0.8, 0, 0.5, -13)
		claimBtn.BackgroundColor3 = Colors.Green
		claimBtn.BackgroundTransparency = 0.2
		claimBtn.BorderSizePixel = 0
		claimBtn.Text = "CLAIM"
		claimBtn.TextColor3 = Colors.TextPrimary
		claimBtn.TextSize = 11
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.Parent = row

		local claimCorner = Instance.new("UICorner")
		claimCorner.CornerRadius = UDim.new(0, 6)
		claimCorner.Parent = claimBtn

		claimBtn.MouseButton1Click:Connect(function()
			remoteEvents:WaitForChild("ClaimChallengeReward"):FireServer({
				Period = period,
				ChallengeIndex = index,
			})
		end)
	elseif challenge.Claimed then
		local claimedLabel = Instance.new("TextLabel")
		claimedLabel.Size = UDim2.new(0.18, 0, 0, 26)
		claimedLabel.Position = UDim2.new(0.8, 0, 0.5, -13)
		claimedLabel.BackgroundTransparency = 1
		claimedLabel.Text = "CLAIMED"
		claimedLabel.TextColor3 = Colors.TextMuted
		claimedLabel.TextSize = 10
		claimedLabel.Font = Enum.Font.GothamBold
		claimedLabel.Parent = row
	end
end

-- ============================================================================
-- POPULATE TOURNAMENT
-- ============================================================================
function LeaderboardUI._PopulateTournament(data)
	local content = mainFrame:FindFirstChild("Content")
	if not content then return end
	local entryList = content:FindFirstChild("EntryList")
	if not entryList then return end

	-- Clear
	for _, child in ipairs(entryList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not data then
		local noData = Instance.new("TextLabel")
		noData.Size = UDim2.new(1, 0, 0, 40)
		noData.BackgroundTransparency = 1
		noData.Text = "No active tournament"
		noData.TextColor3 = Colors.TextMuted
		noData.TextSize = 14
		noData.Font = Enum.Font.GothamMedium
		noData.Parent = entryList
		return
	end

	-- Tournament info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 30)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Weekly Tournament - " .. (data.WorldId or "TBD")
	infoLabel.TextColor3 = Colors.Gold
	infoLabel.TextSize = 14
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.LayoutOrder = 0
	infoLabel.Parent = entryList

	-- Entries
	if data.Entries then
		for i, entry in ipairs(data.Entries) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 28)
			row.LayoutOrder = i
			row.BackgroundColor3 = i % 2 == 0 and Colors.RowAlt or Colors.Row
			row.BackgroundTransparency = 0.3
			row.BorderSizePixel = 0
			row.Parent = entryList

			-- Rank + Name + Time (same layout as normal leaderboard)
			local rankLbl = Instance.new("TextLabel")
			rankLbl.Size = UDim2.new(0.15, 0, 1, 0)
			rankLbl.Position = UDim2.new(0, 5, 0, 0)
			rankLbl.BackgroundTransparency = 1
			rankLbl.Text = "#" .. i
			rankLbl.TextSize = 12
			rankLbl.Font = Enum.Font.GothamBold
			rankLbl.TextXAlignment = Enum.TextXAlignment.Left
			rankLbl.Parent = row

			if i <= 3 then
				rankLbl.TextColor3 = i == 1 and Colors.Gold or (i == 2 and Colors.Silver or Colors.Bronze)
			else
				rankLbl.TextColor3 = Colors.TextSecondary
			end

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(0.4, 0, 1, 0)
			nameLbl.Position = UDim2.new(0.15, 0, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = entry.PlayerName or "Unknown"
			nameLbl.TextColor3 = Colors.TextPrimary
			nameLbl.TextSize = 12
			nameLbl.Font = Enum.Font.GothamMedium
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Parent = row

			local timeLbl = Instance.new("TextLabel")
			timeLbl.Size = UDim2.new(0.25, 0, 1, 0)
			timeLbl.Position = UDim2.new(0.55, 0, 0, 0)
			timeLbl.BackgroundTransparency = 1
			timeLbl.Text = LeaderboardUI._FormatTime(entry.Value / 1000)
			timeLbl.TextColor3 = Colors.Green
			timeLbl.TextSize = 12
			timeLbl.Font = Enum.Font.Code
			timeLbl.TextXAlignment = Enum.TextXAlignment.Right
			timeLbl.Parent = row

			-- Prize info
			local prize = GameConfig.Tournaments.Prizes[i]
			if prize then
				local prizeLbl = Instance.new("TextLabel")
				prizeLbl.Size = UDim2.new(0.2, 0, 1, 0)
				prizeLbl.Position = UDim2.new(0.8, 0, 0, 0)
				prizeLbl.BackgroundTransparency = 1
				prizeLbl.Text = prize.Coins .. "c"
				prizeLbl.TextColor3 = Colors.Gold
				prizeLbl.TextSize = 10
				prizeLbl.Font = Enum.Font.GothamBold
				prizeLbl.TextXAlignment = Enum.TextXAlignment.Right
				prizeLbl.Parent = row
			end
		end
	end

	task.wait()
	local listLayout = entryList:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		content.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end
end

-- ============================================================================
-- TOGGLE
-- ============================================================================
function LeaderboardUI.Toggle()
	isOpen = not isOpen
	mainFrame.Visible = isOpen

	if isOpen then
		LeaderboardUI._SwitchTab(currentTab)
	end
end

-- ============================================================================
-- FORMAT HELPERS
-- ============================================================================
function LeaderboardUI._FormatTime(seconds)
	if not seconds or seconds <= 0 then return "00:00.000" end
	local mins = math.floor(seconds / 60)
	local secs = seconds - (mins * 60)
	return string.format("%02d:%06.3f", mins, secs)
end

function LeaderboardUI._FormatNumber(num)
	if not num then return "0" end
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
LeaderboardUI.Init()

return LeaderboardUI
