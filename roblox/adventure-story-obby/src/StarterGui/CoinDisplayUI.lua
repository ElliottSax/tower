--[[
	CoinDisplayUI.lua
	Displays player's current coin count

	Features:
	- Shows coin count in top-left corner
	- Animated count-up when coins change
	- Green flash on coin gain
	- Red flash on coin spend
	- Listens to CoinUpdate RemoteEvent

	Week 2: Full implementation
	Week 3+: Add coin icon, animations
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- WAIT FOR REMOTE EVENTS (with retry logic)
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[CoinDisplayUI] RemoteEvents folder not found - retrying...")
	remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
	if not remoteFolder then
		warn("[CoinDisplayUI] Failed to find RemoteEvents after retry!")
		return
	end
end

local coinUpdateEvent = remoteFolder:WaitForChild("CoinUpdate", 10)
local getCoinFunction = remoteFolder:WaitForChild("GetCoins", 10)

if not coinUpdateEvent or not getCoinFunction then
	warn("[CoinDisplayUI] Missing coin RemoteEvents - retrying...")
	task.wait(5)
	coinUpdateEvent = coinUpdateEvent or remoteFolder:WaitForChild("CoinUpdate", 10)
	getCoinFunction = getCoinFunction or remoteFolder:WaitForChild("GetCoins", 10)

	if not coinUpdateEvent or not getCoinFunction then
		warn("[CoinDisplayUI] Failed to find coin RemoteEvents after retry!")
		return
	end
end

-- ============================================================================
-- STATE
-- ============================================================================

local currentCoins = 0

-- ============================================================================
-- CREATE UI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinDisplayUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Frame (top-left corner)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.Size = UDim2.new(0, 200, 0, 60)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0) -- Gold
stroke.Thickness = 2
stroke.Transparency = 0.7
stroke.Parent = mainFrame

-- Coin Icon (emoji for now, Week 3+ will add image)
local coinIcon = Instance.new("TextLabel")
coinIcon.Name = "CoinIcon"
coinIcon.Position = UDim2.new(0, 15, 0.5, 0)
coinIcon.AnchorPoint = Vector2.new(0, 0.5)
coinIcon.Size = UDim2.new(0, 30, 0, 30)
coinIcon.BackgroundTransparency = 1
coinIcon.Font = Enum.Font.GothamBold
coinIcon.TextSize = 28
coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
coinIcon.Text = "💰"
coinIcon.Parent = mainFrame

-- Coin Count Label
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Position = UDim2.new(0, 50, 0, 0)
coinLabel.Size = UDim2.new(1, -50, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 24
coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Text = "0"
coinLabel.Parent = mainFrame

-- ============================================================================
-- ANIMATION FUNCTIONS
-- ============================================================================

local function formatNumber(num: number): string
	-- Add commas for thousands
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function animateCountUp(startValue: number, endValue: number, duration: number)
	local elapsed = 0
	local startTime = tick()

	while elapsed < duration do
		elapsed = tick() - startTime
		local alpha = math.min(elapsed / duration, 1)

		-- Ease out quad
		alpha = 1 - (1 - alpha) ^ 2

		local currentValue = math.floor(startValue + (endValue - startValue) * alpha)
		coinLabel.Text = formatNumber(currentValue)

		task.wait()
	end

	-- Ensure final value is exact
	coinLabel.Text = formatNumber(endValue)
end

local function flashFrame(color: Color3)
	-- Flash the stroke color
	local originalColor = stroke.Color
	stroke.Color = color
	stroke.Transparency = 0.3

	-- Tween back to gold
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(stroke, tweenInfo, {
		Color = originalColor,
		Transparency = 0.7,
	})
	tween:Play()
end

-- ============================================================================
-- COIN UPDATE HANDLER
-- ============================================================================

local function onCoinUpdate(newTotal: number, changeAmount: number, changeType: string)
	print(string.format(
		"[CoinDisplayUI] Coin update: %d → %d (%s %d)",
		currentCoins,
		newTotal,
		changeType,
		changeAmount
	))

	-- Animate count-up
	if changeType == "add" then
		-- Green flash for gain
		flashFrame(Color3.fromRGB(46, 204, 113))
		animateCountUp(currentCoins, newTotal, 0.5)
	elseif changeType == "remove" then
		-- Red flash for spend
		flashFrame(Color3.fromRGB(231, 76, 60))
		animateCountUp(currentCoins, newTotal, 0.3)
	elseif changeType == "init" then
		-- Instant set for initial load
		coinLabel.Text = formatNumber(newTotal)
	end

	currentCoins = newTotal
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================

-- Get initial coins from server
local success, initialCoins = pcall(function()
	return getCoinFunction:InvokeServer()
end)

if success and initialCoins then
	currentCoins = initialCoins
	coinLabel.Text = formatNumber(initialCoins)
	print(string.format("[CoinDisplayUI] Initial coins: %d", initialCoins))
else
	warn("[CoinDisplayUI] Failed to get initial coins")
	coinLabel.Text = "0"
end

-- Listen for coin updates
coinUpdateEvent.OnClientEvent:Connect(onCoinUpdate)

-- ============================================================================
-- PERIODIC COIN SYNC
-- ============================================================================

-- Re-sync coins periodically to catch any missed updates
-- This handles edge cases like admin commands, exploits, or network issues
local SYNC_INTERVAL = 30 -- seconds

task.spawn(function()
	while true do
		task.wait(SYNC_INTERVAL)

		-- Only sync if UI still exists
		if not playerGui or not playerGui.Parent then
			break
		end

		local success, serverCoins = pcall(function()
			return getCoinFunction:InvokeServer()
		end)

		if success and serverCoins and type(serverCoins) == "number" then
			-- Only update if different (avoid unnecessary animations)
			if serverCoins ~= currentCoins then
				local changeType = serverCoins > currentCoins and "add" or "remove"
				local changeAmount = math.abs(serverCoins - currentCoins)
				onCoinUpdate(serverCoins, changeAmount, changeType)
			end
		end
	end
end)

print("[CoinDisplayUI] Initialized (with periodic sync every " .. SYNC_INTERVAL .. "s)")
