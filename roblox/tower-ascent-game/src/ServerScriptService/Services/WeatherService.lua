--[[
	WeatherService.lua
	Manages dynamic weather effects for Tower Ascent

	Features:
	- Theme-based weather (Grasslands, Desert, Snow, Volcano)
	- Periodic weather events (sandstorm gusts, blizzard intensification)
	- Client-side effect coordination via RemoteEvents
	- Integration with ThemeService for automatic weather changes
	- Atmospheric immersion without gameplay impact

	Weather Types:
	- Clear (Grasslands) - Ambient, peaceful
	- Sandstorm (Desert) - Periodic gusts, reduced visibility
	- Blizzard (Snow) - Heavy snowfall, wind effects
	- Volcanic Ash (Volcano) - Falling ash, ominous atmosphere

	Week 10 Implementation
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeatherService = {}
WeatherService.ActiveWeather = "Clear" -- Current weather type
WeatherService.IntensityLevel = 0 -- 0-1 (calm to intense)
WeatherService.EventCooldown = 0 -- Time until next weather event

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CONFIG = {
	-- Weather event timings (seconds)
	MinEventInterval = 20, -- Minimum time between weather events
	MaxEventInterval = 45, -- Maximum time between weather events
	EventDuration = 8, -- How long an event lasts

	-- Intensity settings
	BaseIntensity = 0.3, -- Ambient weather intensity
	EventIntensity = 0.8, -- Intensity during weather events
	IntensityTransitionSpeed = 0.1, -- How fast intensity changes

	-- Performance
	UpdateInterval = 0.5, -- How often to update weather (seconds)
}

-- ============================================================================
-- WEATHER DEFINITIONS
-- ============================================================================

local WEATHER_TYPES = {
	Clear = {
		Name = "Clear",
		Description = "Peaceful grasslands weather",
		HasEvents = false, -- No periodic events
		AmbientIntensity = 0.1,
		Theme = "Grasslands",
	},

	Sandstorm = {
		Name = "Sandstorm",
		Description = "Desert sandstorm with periodic gusts",
		HasEvents = true,
		EventName = "Sandstorm Gust",
		AmbientIntensity = 0.3,
		EventIntensity = 0.9,
		Theme = "Desert",
	},

	Blizzard = {
		Name = "Blizzard",
		Description = "Heavy snowfall with strong winds",
		HasEvents = true,
		EventName = "Wind Gust",
		AmbientIntensity = 0.5,
		EventIntensity = 0.95,
		Theme = "Snow",
	},

	VolcanicAsh = {
		Name = "VolcanicAsh",
		Description = "Falling volcanic ash and embers",
		HasEvents = true,
		EventName = "Ash Cloud",
		AmbientIntensity = 0.4,
		EventIntensity = 0.85,
		Theme = "Volcano",
	},
}

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local RemoteEvents = {
	SetWeather = nil, -- Client: Change weather type
	WeatherEvent = nil, -- Client: Trigger weather event
	UpdateIntensity = nil, -- Client: Update weather intensity
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function WeatherService.Init()
	print("[WeatherService] Initializing...")

	-- Create remote events
	WeatherService.CreateRemoteEvents()

	-- Set initial weather
	WeatherService.SetWeather("Clear")

	-- Start weather update loop
	WeatherService.StartUpdateLoop()

	print("[WeatherService] Initialized - Active weather:", WeatherService.ActiveWeather)
end

function WeatherService.CreateRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create RemoteEvents if they don't exist
	if not remoteFolder:FindFirstChild("SetWeather") then
		local setWeather = Instance.new("RemoteEvent")
		setWeather.Name = "SetWeather"
		setWeather.Parent = remoteFolder
	end

	if not remoteFolder:FindFirstChild("WeatherEvent") then
		local weatherEvent = Instance.new("RemoteEvent")
		weatherEvent.Name = "WeatherEvent"
		weatherEvent.Parent = remoteFolder
	end

	if not remoteFolder:FindFirstChild("UpdateIntensity") then
		local updateIntensity = Instance.new("RemoteEvent")
		updateIntensity.Name = "UpdateIntensity"
		updateIntensity.Parent = remoteFolder
	end

	RemoteEvents.SetWeather = remoteFolder.SetWeather
	RemoteEvents.WeatherEvent = remoteFolder.WeatherEvent
	RemoteEvents.UpdateIntensity = remoteFolder.UpdateIntensity
end

-- ============================================================================
-- WEATHER CONTROL
-- ============================================================================

--[[
	Set the active weather type
	@param weatherType string - Name of weather type (Clear, Sandstorm, Blizzard, VolcanicAsh)
]]
function WeatherService.SetWeather(weatherType: string)
	local weatherDef = WEATHER_TYPES[weatherType]
	if not weatherDef then
		warn("[WeatherService] Unknown weather type:", weatherType)
		return
	end

	print("[WeatherService] Setting weather to:", weatherType)

	WeatherService.ActiveWeather = weatherType
	WeatherService.IntensityLevel = weatherDef.AmbientIntensity
	WeatherService.EventCooldown = math.random(CONFIG.MinEventInterval, CONFIG.MaxEventInterval)

	-- Notify all clients
	RemoteEvents.SetWeather:FireAllClients(weatherType)
end

--[[
	Trigger a weather event (sandstorm gust, blizzard intensification, etc.)
]]
function WeatherService.TriggerWeatherEvent()
	local weatherDef = WEATHER_TYPES[WeatherService.ActiveWeather]
	if not weatherDef or not weatherDef.HasEvents then
		return
	end

	print("[WeatherService] Triggering weather event:", weatherDef.EventName)

	-- Increase intensity
	WeatherService.IntensityLevel = weatherDef.EventIntensity

	-- Notify all clients
	RemoteEvents.WeatherEvent:FireAllClients(WeatherService.ActiveWeather)

	-- Schedule intensity decrease
	task.delay(CONFIG.EventDuration, function()
		WeatherService.IntensityLevel = weatherDef.AmbientIntensity
	end)

	-- Reset cooldown
	WeatherService.EventCooldown = math.random(CONFIG.MinEventInterval, CONFIG.MaxEventInterval)
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function WeatherService.StartUpdateLoop()
	local lastUpdate = tick()

	RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		local deltaTime = currentTime - lastUpdate

		if deltaTime >= CONFIG.UpdateInterval then
			WeatherService.Update(deltaTime)
			lastUpdate = currentTime
		end
	end)
end

function WeatherService.Update(deltaTime: number)
	local weatherDef = WEATHER_TYPES[WeatherService.ActiveWeather]
	if not weatherDef or not weatherDef.HasEvents then
		return
	end

	-- Update event cooldown
	WeatherService.EventCooldown -= deltaTime

	-- Trigger event if cooldown expired
	if WeatherService.EventCooldown <= 0 then
		WeatherService.TriggerWeatherEvent()
	end

	-- Update clients with current intensity (smooth transitions)
	RemoteEvents.UpdateIntensity:FireAllClients(WeatherService.IntensityLevel)
end

-- ============================================================================
-- THEME INTEGRATION
-- ============================================================================

--[[
	Change weather based on theme
	Called by ThemeService when theme changes
	@param themeName string - Theme name (Grasslands, Desert, Snow, Volcano)
]]
function WeatherService.SetWeatherByTheme(themeName: string)
	-- Map themes to weather types
	local themeToWeather = {
		Grasslands = "Clear",
		Desert = "Sandstorm",
		Snow = "Blizzard",
		Volcano = "VolcanicAsh",
	}

	local weatherType = themeToWeather[themeName]
	if weatherType then
		WeatherService.SetWeather(weatherType)
	else
		warn("[WeatherService] Unknown theme for weather:", themeName)
	end
end

-- ============================================================================
-- ADMIN COMMANDS (for testing)
-- ============================================================================

--[[
	Admin command to force specific weather
	@param weatherType string - Weather type to force
]]
function WeatherService.AdminSetWeather(weatherType: string)
	print("[WeatherService] ADMIN: Setting weather to", weatherType)
	WeatherService.SetWeather(weatherType)
end

--[[
	Admin command to trigger immediate weather event
]]
function WeatherService.AdminTriggerEvent()
	print("[WeatherService] ADMIN: Triggering weather event")
	WeatherService.TriggerWeatherEvent()
end

-- ============================================================================
-- DEBUG
-- ============================================================================

function WeatherService.GetStatus()
	return {
		ActiveWeather = WeatherService.ActiveWeather,
		IntensityLevel = WeatherService.IntensityLevel,
		EventCooldown = WeatherService.EventCooldown,
		HasEvents = WEATHER_TYPES[WeatherService.ActiveWeather].HasEvents,
	}
end

function WeatherService.DebugPrint()
	print("=== WEATHER SERVICE STATUS ===")
	print("Active Weather:", WeatherService.ActiveWeather)
	print("Intensity Level:", WeatherService.IntensityLevel)
	print("Event Cooldown:", math.floor(WeatherService.EventCooldown), "seconds")
	print("==============================")
end

-- ============================================================================
-- GLOBAL ACCESS
-- ============================================================================

-- Make available globally for other services
_G.TowerAscent = _G.TowerAscent or {}
_G.TowerAscent.WeatherService = WeatherService

return WeatherService
