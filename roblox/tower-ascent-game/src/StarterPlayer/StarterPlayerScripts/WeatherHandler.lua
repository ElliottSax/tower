--[[
	WeatherHandler.lua
	Client-side weather effect handler for Tower Ascent

	Features:
	- Creates visual effects (particles, fog, lighting)
	- Plays ambient weather sounds
	- Responds to weather events from server
	- Performance-friendly (respects graphics settings)
	- Smooth transitions between weather types

	Weather Effects:
	- Clear: Ambient birds, gentle breeze
	- Sandstorm: Blowing sand particles, reduced visibility, wind audio
	- Blizzard: Heavy snowfall, wind gusts, screen frost
	- VolcanicAsh: Falling ash, dark atmosphere, rumbling sounds

	Week 10 Implementation
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WeatherHandler = {}
WeatherHandler.ActiveWeather = "Clear"
WeatherHandler.IntensityLevel = 0
WeatherHandler.ParticleEmitters = {}
WeatherHandler.AmbientSounds = {}
WeatherHandler.IsInitialized = false

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Performance
	MaxParticles = 200, -- Maximum particles at once
	ParticleRange = 100, -- Distance particles spawn from camera

	-- Transitions
	FogTransitionTime = 2, -- Seconds for fog transitions
	LightingTransitionTime = 3, -- Seconds for lighting transitions

	-- Graphics quality scaling
	UseHighQuality = true, -- Set based on user settings
}

-- ============================================================================
-- WEATHER EFFECT DEFINITIONS
-- ============================================================================

local WEATHER_EFFECTS = {
	Clear = {
		-- Lighting
		Brightness = 2,
		Ambient = Color3.fromRGB(150, 150, 150),
		OutdoorAmbient = Color3.fromRGB(140, 140, 140),
		ClockTime = 14, -- 2 PM
		FogColor = Color3.fromRGB(191, 226, 255),
		FogStart = 0,
		FogEnd = 500,

		-- Particles
		Particles = {},

		-- Audio
		AmbientSound = {
			SoundId = "rbxassetid://9113760943", -- Peaceful nature
			Volume = 0.2,
			Looped = true,
		},
	},

	Sandstorm = {
		-- Lighting (sandy haze)
		Brightness = 1.5,
		Ambient = Color3.fromRGB(180, 150, 120),
		OutdoorAmbient = Color3.fromRGB(200, 170, 130),
		ClockTime = 13,
		FogColor = Color3.fromRGB(210, 180, 140),
		FogStart = 0,
		FogEnd = 200, -- Reduced visibility

		-- Particles
		Particles = {
			{
				Name = "Sand",
				Texture = "rbxasset://textures/particles/smoke_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(210, 180, 140)),
				Size = NumberSequence.new(2, 4),
				Transparency = NumberSequence.new(0.5, 1),
				Lifetime = NumberRange.new(3, 5),
				Rate = 50,
				Speed = NumberRange.new(20, 40),
				SpreadAngle = Vector2.new(30, 30),
				VelocityInheritance = 0.2,
			},
		},

		-- Audio
		AmbientSound = {
			SoundId = "rbxassetid://9113646183", -- Wind howling
			Volume = 0.3,
			Looped = true,
		},
	},

	Blizzard = {
		-- Lighting (cold, overcast)
		Brightness = 1,
		Ambient = Color3.fromRGB(160, 180, 200),
		OutdoorAmbient = Color3.fromRGB(170, 190, 210),
		ClockTime = 16, -- Overcast afternoon
		FogColor = Color3.fromRGB(220, 230, 240),
		FogStart = 0,
		FogEnd = 150, -- Heavy snow reduces visibility

		-- Particles
		Particles = {
			{
				Name = "Snow",
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
				Size = NumberSequence.new(0.3, 0.1),
				Transparency = NumberSequence.new(0.2, 0.8),
				Lifetime = NumberRange.new(5, 8),
				Rate = 100,
				Speed = NumberRange.new(5, 15),
				SpreadAngle = Vector2.new(10, 10),
				Acceleration = Vector3.new(0, -2, 0),
			},
		},

		-- Audio
		AmbientSound = {
			SoundId = "rbxassetid://9113646183", -- Wind
			Volume = 0.4,
			Looped = true,
		},
	},

	VolcanicAsh = {
		-- Lighting (dark, ominous)
		Brightness = 0.8,
		Ambient = Color3.fromRGB(120, 100, 90),
		OutdoorAmbient = Color3.fromRGB(140, 110, 95),
		ClockTime = 18, -- Evening/dusk
		FogColor = Color3.fromRGB(100, 90, 85),
		FogStart = 0,
		FogEnd = 180,

		-- Particles
		Particles = {
			{
				Name = "Ash",
				Texture = "rbxasset://textures/particles/smoke_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(80, 70, 65)),
				Size = NumberSequence.new(1, 2),
				Transparency = NumberSequence.new(0.3, 1),
				Lifetime = NumberRange.new(4, 7),
				Rate = 60,
				Speed = NumberRange.new(3, 8),
				SpreadAngle = Vector2.new(20, 20),
				Acceleration = Vector3.new(0, -1, 0),
			},
			{
				Name = "Embers",
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = ColorSequence.new(Color3.fromRGB(255, 150, 50)),
				Size = NumberSequence.new(0.2, 0.05),
				Transparency = NumberSequence.new(0, 1),
				Lifetime = NumberRange.new(2, 4),
				Rate = 20,
				Speed = NumberRange.new(2, 5),
				SpreadAngle = Vector2.new(15, 15),
				Acceleration = Vector3.new(0, 3, 0), -- Float upward
				LightEmission = 1,
			},
		},

		-- Audio
		AmbientSound = {
			SoundId = "rbxassetid://9114221327", -- Low rumbling
			Volume = 0.25,
			Looped = true,
		},
	},
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function WeatherHandler.Init()
	if WeatherHandler.IsInitialized then
		return
	end

	print("[WeatherHandler] Initializing client-side weather...")

	-- Wait for RemoteEvents
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteFolder then
		warn("[WeatherHandler] RemoteEvents folder not found!")
		return
	end

	-- Connect to server events
	local setWeatherEvent = remoteFolder:WaitForChild("SetWeather", 5)
	local weatherEvent = remoteFolder:WaitForChild("WeatherEvent", 5)
	local updateIntensity = remoteFolder:WaitForChild("UpdateIntensity", 5)

	if setWeatherEvent then
		setWeatherEvent.OnClientEvent:Connect(function(weatherType)
			WeatherHandler.SetWeather(weatherType)
		end)
	end

	if weatherEvent then
		weatherEvent.OnClientEvent:Connect(function(weatherType)
			WeatherHandler.OnWeatherEvent(weatherType)
		end)
	end

	if updateIntensity then
		updateIntensity.OnClientEvent:Connect(function(intensity)
			WeatherHandler.UpdateIntensity(intensity)
		end)
	end

	-- Set initial weather
	WeatherHandler.SetWeather("Clear")

	WeatherHandler.IsInitialized = true
	print("[WeatherHandler] Initialized")
end

-- ============================================================================
-- WEATHER CONTROL
-- ============================================================================

--[[
	Set the active weather type
	@param weatherType string - Weather type name
]]
function WeatherHandler.SetWeather(weatherType: string)
	local weatherDef = WEATHER_EFFECTS[weatherType]
	if not weatherDef then
		warn("[WeatherHandler] Unknown weather type:", weatherType)
		return
	end

	print("[WeatherHandler] Changing weather to:", weatherType)

	WeatherHandler.ActiveWeather = weatherType

	-- Clear existing effects
	WeatherHandler.ClearEffects()

	-- Apply new lighting
	WeatherHandler.ApplyLighting(weatherDef)

	-- Create particles
	WeatherHandler.CreateParticles(weatherDef)

	-- Play ambient sound
	WeatherHandler.PlayAmbientSound(weatherDef)
end

--[[
	Handle weather event (intensity spike)
	@param weatherType string - Weather type
]]
function WeatherHandler.OnWeatherEvent(weatherType: string)
	print("[WeatherHandler] Weather event triggered:", weatherType)

	-- Increase particle emission temporarily
	for _, emitter in pairs(WeatherHandler.ParticleEmitters) do
		local originalRate = emitter:GetAttribute("OriginalRate") or emitter.Rate
		emitter:SetAttribute("OriginalRate", originalRate)
		emitter.Rate = originalRate * 2

		-- Reset after event
		task.delay(8, function()
			if emitter and emitter.Parent then
				emitter.Rate = originalRate
			end
		end)
	end

	-- Increase sound volume temporarily
	for _, sound in pairs(WeatherHandler.AmbientSounds) do
		local originalVolume = sound:GetAttribute("OriginalVolume") or sound.Volume
		sound:SetAttribute("OriginalVolume", originalVolume)
		sound.Volume = originalVolume * 1.5

		-- Reset after event
		task.delay(8, function()
			if sound and sound.Parent then
				sound.Volume = originalVolume
			end
		end)
	end
end

--[[
	Update weather intensity (smooth transitions)
	@param intensity number - 0-1 intensity level
]]
function WeatherHandler.UpdateIntensity(intensity: number)
	WeatherHandler.IntensityLevel = intensity

	-- Could use this for fine-grained particle/sound adjustments
	-- For now, handled by OnWeatherEvent
end

-- ============================================================================
-- EFFECT CREATION
-- ============================================================================

function WeatherHandler.ApplyLighting(weatherDef)
	-- Tween lighting properties for smooth transition
	local tweenInfo = TweenInfo.new(
		CONFIG.LightingTransitionTime,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)

	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Brightness = weatherDef.Brightness,
		Ambient = weatherDef.Ambient,
		OutdoorAmbient = weatherDef.OutdoorAmbient,
		ClockTime = weatherDef.ClockTime,
		FogColor = weatherDef.FogColor,
		FogStart = weatherDef.FogStart,
		FogEnd = weatherDef.FogEnd,
	})

	lightingTween:Play()
end

function WeatherHandler.CreateParticles(weatherDef)
	if not weatherDef.Particles or #weatherDef.Particles == 0 then
		return
	end

	-- Create particle attachment in workspace (follows camera)
	local particleAttachment = Instance.new("Attachment")
	particleAttachment.Name = "WeatherParticles"
	particleAttachment.Parent = camera

	-- Create each particle emitter
	for _, particleDef in ipairs(weatherDef.Particles) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = particleDef.Name
		emitter.Texture = particleDef.Texture
		emitter.Color = particleDef.Color
		emitter.Size = particleDef.Size
		emitter.Transparency = particleDef.Transparency
		emitter.Lifetime = particleDef.Lifetime
		emitter.Rate = particleDef.Rate
		emitter.Speed = particleDef.Speed
		emitter.SpreadAngle = particleDef.SpreadAngle

		if particleDef.Acceleration then
			emitter.Acceleration = particleDef.Acceleration
		end

		if particleDef.VelocityInheritance then
			emitter.VelocityInheritance = particleDef.VelocityInheritance
		end

		if particleDef.LightEmission then
			emitter.LightEmission = particleDef.LightEmission
		end

		emitter.Parent = particleAttachment
		table.insert(WeatherHandler.ParticleEmitters, emitter)
	end
end

function WeatherHandler.PlayAmbientSound(weatherDef)
	if not weatherDef.AmbientSound then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "WeatherAmbient_" .. WeatherHandler.ActiveWeather
	sound.SoundId = weatherDef.AmbientSound.SoundId
	sound.Volume = weatherDef.AmbientSound.Volume
	sound.Looped = weatherDef.AmbientSound.Looped
	sound.Parent = SoundService
	sound:Play()

	table.insert(WeatherHandler.AmbientSounds, sound)
end

function WeatherHandler.ClearEffects()
	-- Remove particles
	for _, emitter in pairs(WeatherHandler.ParticleEmitters) do
		if emitter and emitter.Parent then
			emitter.Parent:Destroy()
		end
	end
	WeatherHandler.ParticleEmitters = {}

	-- Stop sounds
	for _, sound in pairs(WeatherHandler.AmbientSounds) do
		if sound and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	WeatherHandler.AmbientSounds = {}
end

-- ============================================================================
-- INITIALIZATION ON LOAD
-- ============================================================================

-- Auto-initialize when script loads
WeatherHandler.Init()

-- Make globally accessible
_G.WeatherHandler = WeatherHandler

return WeatherHandler
