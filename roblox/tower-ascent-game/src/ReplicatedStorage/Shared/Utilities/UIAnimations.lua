--[[
	UIAnimations.lua
	Reusable UI animation utilities

	Features:
	- Fade in/out animations
	- Slide animations (from any direction)
	- Bounce animations
	- Scale animations (grow/shrink)
	- Rotation animations
	- Screen shake
	- Button hover effects
	- Page transitions
	- Notification pop-ups

	Usage:
	local UIAnimations = require(ReplicatedStorage.Shared.Utilities.UIAnimations)
	UIAnimations.FadeIn(myFrame, 0.5)
	UIAnimations.SlideIn(myFrame, "Left", 0.3)
	UIAnimations.Bounce(myButton)

	Week 5: Full implementation
--]]

local TweenService = game:GetService("TweenService")

local UIAnimations = {}

-- ============================================================================
-- FADE ANIMATIONS
-- ============================================================================

function UIAnimations.FadeIn(guiObject: GuiObject, duration: number?, callback: () -> ()?)
	duration = duration or 0.3
	guiObject.Visible = true

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goals = {}

	-- Determine property to tween based on object type
	if guiObject:IsA("Frame") or guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		guiObject.BackgroundTransparency = 1
		goals.BackgroundTransparency = guiObject:GetAttribute("OriginalTransparency") or 0
	end

	if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
		guiObject.TextTransparency = 1
		goals.TextTransparency = 0
	end

	local tween = TweenService:Create(guiObject, tweenInfo, goals)
	tween:Play()

	if callback then
		tween.Completed:Connect(callback)
	end

	return tween
end

function UIAnimations.FadeOut(guiObject: GuiObject, duration: number?, callback: () -> ()?)
	duration = duration or 0.3

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local goals = {}

	if guiObject:IsA("Frame") or guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		goals.BackgroundTransparency = 1
	end

	if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
		goals.TextTransparency = 1
	end

	local tween = TweenService:Create(guiObject, tweenInfo, goals)
	tween:Play()

	tween.Completed:Connect(function()
		guiObject.Visible = false
		if callback then callback() end
	end)

	return tween
end

-- ============================================================================
-- SLIDE ANIMATIONS
-- ============================================================================

function UIAnimations.SlideIn(guiObject: GuiObject, direction: string, duration: number?, callback: () -> ()?)
	direction = direction or "Bottom"
	duration = duration or 0.5

	local originalPosition = guiObject.Position
	guiObject:SetAttribute("OriginalPosition", originalPosition)

	-- Calculate start position based on direction
	local startPosition
	if direction == "Left" then
		startPosition = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
	elseif direction == "Right" then
		startPosition = UDim2.new(2, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
	elseif direction == "Top" then
		startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0)
	else -- Bottom
		startPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 2, 0)
	end

	guiObject.Position = startPosition
	guiObject.Visible = true

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(guiObject, tweenInfo, {Position = originalPosition})
	tween:Play()

	if callback then
		tween.Completed:Connect(callback)
	end

	return tween
end

function UIAnimations.SlideOut(guiObject: GuiObject, direction: string, duration: number?, callback: () -> ()?)
	direction = direction or "Bottom"
	duration = duration or 0.5

	local originalPosition = guiObject.Position

	-- Calculate end position based on direction
	local endPosition
	if direction == "Left" then
		endPosition = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
	elseif direction == "Right" then
		endPosition = UDim2.new(2, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
	elseif direction == "Top" then
		endPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0)
	else -- Bottom
		endPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 2, 0)
	end

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(guiObject, tweenInfo, {Position = endPosition})
	tween:Play()

	tween.Completed:Connect(function()
		guiObject.Visible = false
		guiObject.Position = originalPosition -- Reset for next use
		if callback then callback() end
	end)

	return tween
end

-- ============================================================================
-- BOUNCE ANIMATION
-- ============================================================================

function UIAnimations.Bounce(guiObject: GuiObject, scale: number?, duration: number?)
	scale = scale or 1.2
	duration = duration or 0.3

	local originalSize = guiObject.Size

	-- Bounce up
	local tweenInfo1 = TweenInfo.new(duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween1 = TweenService:Create(guiObject, tweenInfo1, {
		Size = UDim2.new(
			originalSize.X.Scale * scale,
			originalSize.X.Offset * scale,
			originalSize.Y.Scale * scale,
			originalSize.Y.Offset * scale
		)
	})

	-- Bounce down
	local tweenInfo2 = TweenInfo.new(duration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween2 = TweenService:Create(guiObject, tweenInfo2, {Size = originalSize})

	tween1:Play()
	tween1.Completed:Connect(function()
		tween2:Play()
	end)

	return tween1, tween2
end

-- ============================================================================
-- SCALE ANIMATIONS
-- ============================================================================

function UIAnimations.ScaleIn(guiObject: GuiObject, duration: number?, callback: () -> ()?)
	duration = duration or 0.3

	local originalSize = guiObject.Size
	guiObject.Size = UDim2.new(0, 0, 0, 0)
	guiObject.Visible = true

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(guiObject, tweenInfo, {Size = originalSize})
	tween:Play()

	if callback then
		tween.Completed:Connect(callback)
	end

	return tween
end

function UIAnimations.ScaleOut(guiObject: GuiObject, duration: number?, callback: () -> ()?)
	duration = duration or 0.3

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local tween = TweenService:Create(guiObject, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
	tween:Play()

	tween.Completed:Connect(function()
		guiObject.Visible = false
		if callback then callback() end
	end)

	return tween
end

-- ============================================================================
-- ROTATION ANIMATION
-- ============================================================================

function UIAnimations.Rotate(guiObject: GuiObject, degrees: number, duration: number?)
	duration = duration or 1

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(guiObject, tweenInfo, {Rotation = degrees})
	tween:Play()

	return tween
end

function UIAnimations.Spin(guiObject: GuiObject, duration: number?, continuous: boolean?)
	duration = duration or 2
	continuous = continuous or false

	local function spin()
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local tween = TweenService:Create(guiObject, tweenInfo, {Rotation = guiObject.Rotation + 360})
		tween:Play()

		if continuous then
			tween.Completed:Connect(spin)
		end

		return tween
	end

	return spin()
end

-- ============================================================================
-- SCREEN SHAKE
-- ============================================================================

function UIAnimations.ScreenShake(camera: Camera, intensity: number?, duration: number?)
	intensity = intensity or 0.5
	duration = duration or 0.3

	local originalCFrame = camera.CFrame
	local shakeCount = 0
	local maxShakes = math.floor(duration * 30) -- 30 shakes per second

	task.spawn(function()
		while shakeCount < maxShakes do
			local randomOffset = Vector3.new(
				math.random(-100, 100) / 100 * intensity,
				math.random(-100, 100) / 100 * intensity,
				math.random(-100, 100) / 100 * intensity
			)

			camera.CFrame = originalCFrame * CFrame.new(randomOffset)
			shakeCount = shakeCount + 1

			task.wait(1 / 30)
		end

		-- Reset camera
		camera.CFrame = originalCFrame
	end)
end

-- ============================================================================
-- BUTTON HOVER EFFECTS
-- ============================================================================

function UIAnimations.SetupButtonHover(button: GuiButton, scaleAmount: number?)
	scaleAmount = scaleAmount or 1.05

	local originalSize = button.Size

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = UDim2.new(
				originalSize.X.Scale * scaleAmount,
				originalSize.X.Offset * scaleAmount,
				originalSize.Y.Scale * scaleAmount,
				originalSize.Y.Offset * scaleAmount
			)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.05), {
			Size = UDim2.new(
				originalSize.X.Scale * 0.95,
				originalSize.X.Offset * 0.95,
				originalSize.Y.Scale * 0.95,
				originalSize.Y.Offset * 0.95
			)
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.05), {Size = originalSize}):Play()
	end)
end

-- ============================================================================
-- NOTIFICATION POP-UP
-- ============================================================================

function UIAnimations.ShowNotification(parent: ScreenGui, message: string, duration: number?, color: Color3?)
	duration = duration or 3
	color = color or Color3.fromRGB(100, 200, 100)

	-- Create notification
	local notification = Instance.new("Frame")
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.Position = UDim2.new(0.5, 0, 0, -100)
	notification.Size = UDim2.new(0, 400, 0, 60)
	notification.BackgroundColor3 = color
	notification.BorderSizePixel = 0
	notification.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notification

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = message
	label.Parent = notification

	-- Slide in from top
	local slideIn = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 20)
	})
	slideIn:Play()

	-- Wait, then slide out
	task.delay(duration, function()
		local slideOut = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -100)
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)

	return notification
end

-- ============================================================================
-- PAGE TRANSITION
-- ============================================================================

function UIAnimations.PageTransition(currentPage: GuiObject, nextPage: GuiObject, direction: string, duration: number?)
	direction = direction or "Left"
	duration = duration or 0.5

	-- Slide out current page
	UIAnimations.SlideOut(currentPage, direction, duration)

	-- Slide in next page (from opposite direction)
	local oppositeDirection
	if direction == "Left" then
		oppositeDirection = "Right"
	elseif direction == "Right" then
		oppositeDirection = "Left"
	elseif direction == "Top" then
		oppositeDirection = "Bottom"
	else
		oppositeDirection = "Top"
	end

	UIAnimations.SlideIn(nextPage, oppositeDirection, duration)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function UIAnimations.Wait(duration: number)
	task.wait(duration)
end

function UIAnimations.Chain(...)
	local animations = {...}

	task.spawn(function()
		for _, anim in ipairs(animations) do
			if type(anim) == "function" then
				anim()
			elseif typeof(anim) == "Instance" and anim:IsA("Tween") then
				anim:Play()
				anim.Completed:Wait()
			end
		end
	end)
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return UIAnimations
