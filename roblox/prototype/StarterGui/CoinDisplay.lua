--[[
	CoinDisplay.lua (LocalScript)
	Place this inside StarterGui

	Features:
	- Displays player's coin count
	- Shows "Buy Double Jump" button (100 coins)
	- Handles purchase requests
	- Updates UI when coins change
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents to be created
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local coinUpdateEvent = remoteFolder:WaitForChild("CoinUpdate")
local purchaseUpgradeEvent = remoteFolder:WaitForChild("PurchaseUpgrade")
local getCoinFunction = remoteFolder:WaitForChild("GetCoins")
local hasUpgradeFunction = remoteFolder:WaitForChild("HasUpgrade")

-- Current coin count
local currentCoins = 0
local hasDoubleJump = false

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Coin display frame
local coinFrame = Instance.new("Frame")
coinFrame.Name = "CoinFrame"
coinFrame.Size = UDim2.new(0, 200, 0, 60)
coinFrame.Position = UDim2.new(0, 10, 0, 10)
coinFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
coinFrame.BorderSizePixel = 2
coinFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
coinFrame.Parent = screenGui

-- Coin label
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, 0, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 24
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.Text = "Coins: 0"
coinLabel.Parent = coinFrame

-- Upgrade shop frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 250, 0, 120)
shopFrame.Position = UDim2.new(0, 10, 0, 80)
shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
shopFrame.BorderSizePixel = 2
shopFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
shopFrame.Parent = screenGui

-- Shop title
local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(1, 0, 0, 30)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 18
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.Text = "Upgrade Shop"
shopTitle.Parent = shopFrame

-- Double Jump button
local doubleJumpButton = Instance.new("TextButton")
doubleJumpButton.Name = "DoubleJumpButton"
doubleJumpButton.Size = UDim2.new(1, -20, 0, 40)
doubleJumpButton.Position = UDim2.new(0, 10, 0, 40)
doubleJumpButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
doubleJumpButton.Font = Enum.Font.GothamBold
doubleJumpButton.TextSize = 16
doubleJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
doubleJumpButton.Text = "Buy Double Jump (100 coins)"
doubleJumpButton.Parent = shopFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, 85)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = ""
statusLabel.Parent = shopFrame

-- Update coin display
local function updateCoinDisplay()
	coinLabel.Text = string.format("Coins: %d", currentCoins)

	-- Update button availability
	if hasDoubleJump then
		doubleJumpButton.Text = "Double Jump (OWNED)"
		doubleJumpButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		doubleJumpButton.Active = false
	elseif currentCoins >= 100 then
		doubleJumpButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		doubleJumpButton.Active = true
	else
		doubleJumpButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		doubleJumpButton.Active = true
	end
end

-- Show status message
local function showStatus(message, isSuccess)
	statusLabel.Text = message
	statusLabel.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)

	-- Clear after 3 seconds
	task.delay(3, function()
		statusLabel.Text = ""
	end)
end

-- Handle purchase button click
doubleJumpButton.MouseButton1Click:Connect(function()
	if hasDoubleJump then
		showStatus("Already owned!", false)
		return
	end

	if currentCoins < 100 then
		showStatus("Not enough coins!", false)
		return
	end

	-- Request purchase from server
	print("[CoinUI] Requesting Double Jump purchase...")
	purchaseUpgradeEvent:FireServer("DoubleJump")
end)

-- Listen for purchase result
purchaseUpgradeEvent.OnClientEvent:Connect(function(success, message, upgradeName)
	if upgradeName == "DoubleJump" then
		if success then
			hasDoubleJump = true
			showStatus("Double Jump unlocked!", true)
			print("[CoinUI] Double Jump purchased successfully!")
		else
			showStatus(message or "Purchase failed", false)
			print("[CoinUI] Purchase failed:", message)
		end
		updateCoinDisplay()
	end
end)

-- Listen for coin updates from server
coinUpdateEvent.OnClientEvent:Connect(function(newCoinAmount)
	currentCoins = newCoinAmount
	updateCoinDisplay()
	print("[CoinUI] Coins updated:", currentCoins)
end)

-- Initialize
local function initialize()
	-- Get initial coin count
	local success, coins = pcall(function()
		return getCoinFunction:InvokeServer()
	end)

	if success and coins then
		currentCoins = coins
	else
		warn("[CoinUI] Failed to get initial coins")
		currentCoins = 0
	end

	-- Check if player already has double jump
	local hasUpgrade = pcall(function()
		return hasUpgradeFunction:InvokeServer("DoubleJump")
	end)

	if hasUpgrade then
		hasDoubleJump = true
	end

	updateCoinDisplay()
	print("[CoinUI] Initialized with", currentCoins, "coins")
end

-- Run initialization
initialize()

print("[CoinUI] UI loaded successfully!")
