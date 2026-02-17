--[[
	TradingUI.lua - Grow a World
	Player-to-player trading interface
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local TradingUI = {}
local screenGui, tradeFrame, isOpen = nil, nil, false
local currentTrade = nil

function TradingUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TradingUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui

	TradingUI.CreateTradeFrame()
	TradingUI.CreateRequestPopup()

	-- Trade events
	remoteEvents:WaitForChild("TradeRequest").OnClientEvent:Connect(function(fromPlayer)
		TradingUI.ShowTradeRequest(fromPlayer)
	end)

	remoteEvents:WaitForChild("TradeActive").OnClientEvent:Connect(function(tradeData)
		currentTrade = tradeData
		TradingUI.OpenTradeWindow(tradeData)
	end)

	remoteEvents:WaitForChild("TradeSync").OnClientEvent:Connect(function(tradeData)
		currentTrade = tradeData
		TradingUI.UpdateTradeDisplay(tradeData)
	end)

	remoteEvents:WaitForChild("TradeComplete").OnClientEvent:Connect(function()
		TradingUI.Close()
		TradingUI.ShowNotification("Trade completed!", Color3.fromRGB(76, 175, 80))
	end)

	remoteEvents:WaitForChild("TradeCancelled").OnClientEvent:Connect(function()
		TradingUI.Close()
		TradingUI.ShowNotification("Trade cancelled", Color3.fromRGB(200, 50, 50))
	end)
end

function TradingUI.CreateTradeFrame()
	tradeFrame = Instance.new("Frame")
	tradeFrame.Name = "TradeFrame"
	tradeFrame.Size = UDim2.new(0.7, 0, 0.6, 0)
	tradeFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
	tradeFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	tradeFrame.BorderSizePixel = 0
	tradeFrame.Visible = false
	tradeFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = tradeFrame

	-- Title
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 45)
	titleBar.BackgroundColor3 = Color3.fromRGB(255, 152, 0)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = tradeFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 16)
	titleCorner.Parent = titleBar

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Trading"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	-- Two columns: Your offer / Their offer
	local yourSide = Instance.new("Frame")
	yourSide.Name = "YourSide"
	yourSide.Size = UDim2.new(0.48, 0, 1, -100)
	yourSide.Position = UDim2.new(0.01, 0, 0, 50)
	yourSide.BackgroundColor3 = Color3.fromRGB(35, 40, 35)
	yourSide.BorderSizePixel = 0
	yourSide.Parent = tradeFrame

	local yourCorner = Instance.new("UICorner")
	yourCorner.CornerRadius = UDim.new(0, 10)
	yourCorner.Parent = yourSide

	local yourLabel = Instance.new("TextLabel")
	yourLabel.Size = UDim2.new(1, 0, 0, 30)
	yourLabel.BackgroundTransparency = 1
	yourLabel.Text = "Your Offer"
	yourLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
	yourLabel.TextSize = 16
	yourLabel.Font = Enum.Font.GothamBold
	yourLabel.Parent = yourSide

	local yourItems = Instance.new("ScrollingFrame")
	yourItems.Name = "Items"
	yourItems.Size = UDim2.new(1, -10, 1, -35)
	yourItems.Position = UDim2.new(0, 5, 0, 32)
	yourItems.BackgroundTransparency = 1
	yourItems.ScrollBarThickness = 4
	yourItems.Parent = yourSide

	local yourLayout = Instance.new("UIListLayout")
	yourLayout.Padding = UDim.new(0, 4)
	yourLayout.Parent = yourItems

	-- Their side
	local theirSide = Instance.new("Frame")
	theirSide.Name = "TheirSide"
	theirSide.Size = UDim2.new(0.48, 0, 1, -100)
	theirSide.Position = UDim2.new(0.51, 0, 0, 50)
	theirSide.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	theirSide.BorderSizePixel = 0
	theirSide.Parent = tradeFrame

	local theirCorner = Instance.new("UICorner")
	theirCorner.CornerRadius = UDim.new(0, 10)
	theirCorner.Parent = theirSide

	local theirLabel = Instance.new("TextLabel")
	theirLabel.Size = UDim2.new(1, 0, 0, 30)
	theirLabel.BackgroundTransparency = 1
	theirLabel.Text = "Their Offer"
	theirLabel.TextColor3 = Color3.fromRGB(33, 150, 243)
	theirLabel.TextSize = 16
	theirLabel.Font = Enum.Font.GothamBold
	theirLabel.Parent = theirSide

	local theirItems = Instance.new("ScrollingFrame")
	theirItems.Name = "Items"
	theirItems.Size = UDim2.new(1, -10, 1, -35)
	theirItems.Position = UDim2.new(0, 5, 0, 32)
	theirItems.BackgroundTransparency = 1
	theirItems.ScrollBarThickness = 4
	theirItems.Parent = theirSide

	local theirLayout = Instance.new("UIListLayout")
	theirLayout.Padding = UDim.new(0, 4)
	theirLayout.Parent = theirItems

	-- Bottom buttons
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmBtn"
	confirmBtn.Size = UDim2.new(0.3, 0, 0, 40)
	confirmBtn.Position = UDim2.new(0.18, 0, 1, -48)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	confirmBtn.Text = "Confirm Trade"
	confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.TextSize = 16
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.Parent = tradeFrame

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmBtn

	confirmBtn.Activated:Connect(function()
		remoteEvents.ConfirmTrade:FireServer()
	end)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "CancelBtn"
	cancelBtn.Size = UDim2.new(0.3, 0, 0, 40)
	cancelBtn.Position = UDim2.new(0.52, 0, 1, -48)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 16
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.Parent = tradeFrame

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	cancelBtn.Activated:Connect(function()
		remoteEvents.DeclineTrade:FireServer()
	end)
end

function TradingUI.CreateRequestPopup()
	local popup = Instance.new("Frame")
	popup.Name = "TradeRequestPopup"
	popup.Size = UDim2.new(0, 300, 0, 120)
	popup.Position = UDim2.new(0.5, -150, 0.3, 0)
	popup.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	popup.Visible = false
	popup.Parent = screenGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 12)
	popupCorner.Parent = popup

	local requestText = Instance.new("TextLabel")
	requestText.Name = "RequestText"
	requestText.Size = UDim2.new(1, -10, 0, 50)
	requestText.Position = UDim2.new(0, 5, 0, 10)
	requestText.BackgroundTransparency = 1
	requestText.TextColor3 = Color3.fromRGB(255, 255, 255)
	requestText.TextSize = 14
	requestText.Font = Enum.Font.GothamBold
	requestText.TextWrapped = true
	requestText.Parent = popup

	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Name = "AcceptBtn"
	acceptBtn.Size = UDim2.new(0.4, 0, 0, 35)
	acceptBtn.Position = UDim2.new(0.05, 0, 1, -45)
	acceptBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	acceptBtn.Text = "Accept"
	acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	acceptBtn.TextSize = 14
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.Parent = popup

	local acceptCorner = Instance.new("UICorner")
	acceptCorner.CornerRadius = UDim.new(0, 8)
	acceptCorner.Parent = acceptBtn

	local declineBtn = Instance.new("TextButton")
	declineBtn.Name = "DeclineBtn"
	declineBtn.Size = UDim2.new(0.4, 0, 0, 35)
	declineBtn.Position = UDim2.new(0.55, 0, 1, -45)
	declineBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	declineBtn.Text = "Decline"
	declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	declineBtn.TextSize = 14
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.Parent = popup

	local declineCorner = Instance.new("UICorner")
	declineCorner.CornerRadius = UDim.new(0, 8)
	declineCorner.Parent = declineBtn
end

function TradingUI.ShowTradeRequest(fromPlayerName)
	local popup = screenGui:FindFirstChild("TradeRequestPopup")
	if not popup then return end

	popup:FindFirstChild("RequestText").Text = fromPlayerName .. " wants to trade with you!"
	popup.Visible = true

	popup:FindFirstChild("AcceptBtn").Activated:Connect(function()
		remoteEvents.AcceptTrade:FireServer()
		popup.Visible = false
	end)

	popup:FindFirstChild("DeclineBtn").Activated:Connect(function()
		remoteEvents.DeclineTrade:FireServer()
		popup.Visible = false
	end)

	-- Auto-decline after 30 seconds
	task.delay(30, function()
		if popup.Visible then
			popup.Visible = false
		end
	end)
end

function TradingUI.OpenTradeWindow(tradeData)
	isOpen = true
	tradeFrame.Visible = true
	TradingUI.UpdateTradeDisplay(tradeData)
end

function TradingUI.UpdateTradeDisplay(tradeData)
	if not tradeData then return end

	local yourSide = tradeFrame:FindFirstChild("YourSide")
	local theirSide = tradeFrame:FindFirstChild("TheirSide")
	if not yourSide or not theirSide then return end

	-- Clear and repopulate your items
	local yourItems = yourSide:FindFirstChild("Items")
	if yourItems then
		for _, child in ipairs(yourItems:GetChildren()) do
			if child:IsA("TextLabel") then child:Destroy() end
		end
		local myOffer = tradeData.Offers and tradeData.Offers[tostring(player.UserId)]
		if myOffer then
			for _, item in ipairs(myOffer) do
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 0, 25)
				label.BackgroundTransparency = 1
				label.Text = item.Name .. " x" .. (item.Count or 1)
				label.TextColor3 = Color3.fromRGB(200, 200, 200)
				label.TextSize = 13
				label.Font = Enum.Font.Gotham
				label.Parent = yourItems
			end
		end
	end

	-- Clear and repopulate their items
	local theirItems = theirSide:FindFirstChild("Items")
	if theirItems then
		for _, child in ipairs(theirItems:GetChildren()) do
			if child:IsA("TextLabel") then child:Destroy() end
		end
		for oddsUserId, offer in pairs(tradeData.Offers or {}) do
			if oddsUserId ~= tostring(player.UserId) then
				for _, item in ipairs(offer) do
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 0, 25)
					label.BackgroundTransparency = 1
					label.Text = item.Name .. " x" .. (item.Count or 1)
					label.TextColor3 = Color3.fromRGB(200, 200, 200)
					label.TextSize = 13
					label.Font = Enum.Font.Gotham
					label.Parent = theirItems
				end
			end
		end
	end
end

function TradingUI.Close()
	isOpen = false
	tradeFrame.Visible = false
	currentTrade = nil
end

function TradingUI.ShowNotification(text, color)
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(0.3, 0, 0, 35)
	notif.Position = UDim2.new(0.35, 0, 0.15, 0)
	notif.BackgroundColor3 = color
	notif.BackgroundTransparency = 0.2
	notif.Text = text
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.TextSize = 14
	notif.Font = Enum.Font.GothamBold
	notif.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif

	task.delay(3, function()
		TweenService:Create(notif, TweenInfo.new(0.5), {
			BackgroundTransparency = 1, TextTransparency = 1,
		}):Play()
		task.wait(0.5)
		notif:Destroy()
	end)
end

TradingUI.Init()

return TradingUI
