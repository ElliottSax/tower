--[[
	SoundService.lua
	Centralized audio management for Dimension Hopper

	Features:
	- Music management per dimension
	- Sound effect playback
	- Volume control integration
	- 3D positional audio
	- Crossfade between tracks
--]]

local Players = game:GetService("Players")
local SoundServiceGame = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SoundService = {}

-- ============================================================================
-- SOUND LIBRARY
-- ============================================================================

-- Music tracks (use placeholder IDs - replace with actual asset IDs)
local MUSIC = {
	Lobby = "rbxassetid://0", -- Calm, welcoming
	Gravity = "rbxassetid://0", -- Electronic, spacey
	Tiny = "rbxassetid://0", -- Whimsical, nature
	Void = "rbxassetid://0", -- Dark ambient, tension
	Sky = "rbxassetid://0", -- Orchestral, uplifting
	Victory = "rbxassetid://0", -- Triumphant
	Defeat = "rbxassetid://0", -- Somber but encouraging
}

-- Sound effects
local SFX = {
	-- UI
	ButtonClick = "rbxassetid://0",
	ButtonHover = "rbxassetid://0",
	MenuOpen = "rbxassetid://0",
	MenuClose = "rbxassetid://0",

	-- Race
	Countdown3 = "rbxassetid://0",
	Countdown2 = "rbxassetid://0",
	Countdown1 = "rbxassetid://0",
	RaceStart = "rbxassetid://0",
	RaceFinish = "rbxassetid://0",
	Checkpoint = "rbxassetid://0",

	-- Gravity Dimension
	GravityFlip = "rbxassetid://0",
	GravityLand = "rbxassetid://0",

	-- Tiny Dimension
	Shrink = "rbxassetid://0",
	Grow = "rbxassetid://0",
	TinyFootstep = "rbxassetid://0",

	-- Void Dimension
	VoidAmbient = "rbxassetid://0",
	VoidNear = "rbxassetid://0",
	VoidCatch = "rbxassetid://0",
	PlatformCrumble = "rbxassetid://0",
	PlatformFall = "rbxassetid://0",

	-- Sky Dimension
	GliderDeploy = "rbxassetid://0",
	GliderRetract = "rbxassetid://0",
	WindGust = "rbxassetid://0",
	Updraft = "rbxassetid://0",
	BoostActivate = "rbxassetid://0",
	BoostEmpty = "rbxassetid://0",

	-- Collectibles
	FragmentCollect = "rbxassetid://0",
	PowerUp = "rbxassetid://0",

	-- Player
	Jump = "rbxassetid://0",
	Land = "rbxassetid://0",
	Death = "rbxassetid://0",
	Respawn = "rbxassetid://0",

	-- Progression
	XPGain = "rbxassetid://0",
	LevelUp = "rbxassetid://0",
	Unlock = "rbxassetid://0",
	TierUp = "rbxassetid://0",
}

-- ============================================================================
-- STATE
-- ============================================================================

SoundService.CurrentMusic = nil
SoundService.MusicVolume = 0.5
SoundService.SFXVolume = 0.7
SoundService.SoundFolder = nil

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function SoundService.Init()
	print("[SoundService] Initializing...")

	-- Create sound storage folder
	SoundService.CreateSoundFolder()

	-- Pre-load sounds
	SoundService.PreloadSounds()

	-- Create remotes
	SoundService.CreateRemotes()

	-- Setup player volume preferences
	Players.PlayerAdded:Connect(function(player)
		SoundService.OnPlayerJoin(player)
	end)

	print("[SoundService] Initialized")
end

function SoundService.CreateSoundFolder()
	local folder = Instance.new("Folder")
	folder.Name = "GameSounds"
	folder.Parent = SoundServiceGame

	-- Music container
	local musicFolder = Instance.new("Folder")
	musicFolder.Name = "Music"
	musicFolder.Parent = folder

	-- SFX container
	local sfxFolder = Instance.new("Folder")
	sfxFolder.Name = "SFX"
	sfxFolder.Parent = folder

	SoundService.SoundFolder = folder
end

function SoundService.PreloadSounds()
	local ContentProvider = game:GetService("ContentProvider")
	local assets = {}

	-- Collect all sound assets
	for _, soundId in pairs(MUSIC) do
		if soundId ~= "rbxassetid://0" then
			table.insert(assets, Instance.new("Sound", nil))
			assets[#assets].SoundId = soundId
		end
	end

	for _, soundId in pairs(SFX) do
		if soundId ~= "rbxassetid://0" then
			table.insert(assets, Instance.new("Sound", nil))
			assets[#assets].SoundId = soundId
		end
	end

	-- Preload asynchronously
	if #assets > 0 then
		task.spawn(function()
			ContentProvider:PreloadAsync(assets)
			print(string.format("[SoundService] Preloaded %d sounds", #assets))
		end)
	end
end

function SoundService.CreateRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Play sound on client
	if not remoteFolder:FindFirstChild("PlaySound") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PlaySound"
		event.Parent = remoteFolder
	end

	-- Play music on client
	if not remoteFolder:FindFirstChild("PlayMusic") then
		local event = Instance.new("RemoteEvent")
		event.Name = "PlayMusic"
		event.Parent = remoteFolder
	end

	-- Stop music
	if not remoteFolder:FindFirstChild("StopMusic") then
		local event = Instance.new("RemoteEvent")
		event.Name = "StopMusic"
		event.Parent = remoteFolder
	end

	-- Update volume settings
	if not remoteFolder:FindFirstChild("UpdateVolume") then
		local event = Instance.new("RemoteEvent")
		event.Name = "UpdateVolume"
		event.Parent = remoteFolder
	end

	SoundService.Remotes = {
		PlaySound = remoteFolder.PlaySound,
		PlayMusic = remoteFolder.PlayMusic,
		StopMusic = remoteFolder.StopMusic,
		UpdateVolume = remoteFolder.UpdateVolume,
	}
end

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

function SoundService.OnPlayerJoin(player: Player)
	-- Load player's volume settings
	task.delay(2, function()
		local DataService = _G.DimensionHopper and _G.DimensionHopper.GetService("DataService")
		if DataService then
			local data = DataService.GetData(player)
			if data and data.Settings then
				SoundService.Remotes.UpdateVolume:FireClient(player, {
					Music = data.Settings.MusicVolume,
					SFX = data.Settings.SFXVolume,
				})
			end
		end
	end)
end

-- ============================================================================
-- MUSIC
-- ============================================================================

function SoundService.PlayMusic(trackName: string, fadeIn: boolean?)
	local soundId = MUSIC[trackName]
	if not soundId or soundId == "rbxassetid://0" then
		print(string.format("[SoundService] Music track '%s' not found or not configured", trackName))
		return
	end

	-- Notify all clients to play music
	SoundService.Remotes.PlayMusic:FireAllClients({
		TrackName = trackName,
		SoundId = soundId,
		FadeIn = fadeIn ~= false, -- Default true
		FadeDuration = 1,
	})

	SoundService.CurrentMusic = trackName
	print(string.format("[SoundService] Playing music: %s", trackName))
end

function SoundService.PlayMusicForPlayer(player: Player, trackName: string)
	local soundId = MUSIC[trackName]
	if not soundId or soundId == "rbxassetid://0" then return end

	SoundService.Remotes.PlayMusic:FireClient(player, {
		TrackName = trackName,
		SoundId = soundId,
		FadeIn = true,
		FadeDuration = 1,
	})
end

function SoundService.StopMusic(fadeOut: boolean?)
	SoundService.Remotes.StopMusic:FireAllClients({
		FadeOut = fadeOut ~= false,
		FadeDuration = 1,
	})

	SoundService.CurrentMusic = nil
end

function SoundService.SetDimensionMusic(dimension: string)
	local track = MUSIC[dimension]
	if track then
		SoundService.PlayMusic(dimension, true)
	end
end

-- ============================================================================
-- SOUND EFFECTS
-- ============================================================================

function SoundService.PlaySFX(player: Player, soundName: string, options: table?)
	local soundId = SFX[soundName]
	if not soundId or soundId == "rbxassetid://0" then
		-- Sound not configured - skip silently
		return
	end

	options = options or {}

	SoundService.Remotes.PlaySound:FireClient(player, {
		SoundId = soundId,
		SoundName = soundName,
		Volume = options.Volume or 1,
		Pitch = options.Pitch or 1,
		Position = options.Position, -- For 3D sound
		Loop = options.Loop or false,
	})
end

function SoundService.PlaySFXForAll(soundName: string, options: table?)
	for _, player in ipairs(Players:GetPlayers()) do
		SoundService.PlaySFX(player, soundName, options)
	end
end

function SoundService.PlaySFXAtPosition(position: Vector3, soundName: string, range: number?)
	local soundId = SFX[soundName]
	if not soundId or soundId == "rbxassetid://0" then return end

	range = range or 50

	-- Find players in range
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local distance = (rootPart.Position - position).Magnitude
				if distance <= range then
					-- Volume falloff based on distance
					local volume = math.clamp(1 - (distance / range), 0.1, 1)

					SoundService.PlaySFX(player, soundName, {
						Volume = volume,
						Position = position,
					})
				end
			end
		end
	end
end

-- ============================================================================
-- DIMENSION-SPECIFIC SOUNDS
-- ============================================================================

-- Gravity
function SoundService.PlayGravityFlip(player: Player)
	SoundService.PlaySFX(player, "GravityFlip")
end

-- Tiny
function SoundService.PlayShrink(player: Player)
	SoundService.PlaySFX(player, "Shrink", { Pitch = 1.2 })
end

function SoundService.PlayGrow(player: Player)
	SoundService.PlaySFX(player, "Grow", { Pitch = 0.8 })
end

-- Void
function SoundService.PlayVoidWarning(player: Player, intensity: number)
	SoundService.PlaySFX(player, "VoidNear", { Volume = intensity })
end

function SoundService.PlayVoidCatch(player: Player)
	SoundService.PlaySFX(player, "VoidCatch")
end

function SoundService.PlayPlatformCrumble(position: Vector3)
	SoundService.PlaySFXAtPosition(position, "PlatformCrumble", 100)
end

-- Sky
function SoundService.PlayGliderDeploy(player: Player)
	SoundService.PlaySFX(player, "GliderDeploy")
end

function SoundService.PlayGliderRetract(player: Player)
	SoundService.PlaySFX(player, "GliderRetract")
end

function SoundService.PlayWindGust(player: Player, strength: number)
	SoundService.PlaySFX(player, "WindGust", { Volume = strength })
end

function SoundService.PlayBoostActivate(player: Player)
	SoundService.PlaySFX(player, "BoostActivate")
end

function SoundService.PlayBoostEmpty(player: Player)
	SoundService.PlaySFX(player, "BoostEmpty")
end

-- ============================================================================
-- RACE SOUNDS
-- ============================================================================

function SoundService.PlayCountdown(count: number)
	local soundName = "Countdown" .. count
	if SFX[soundName] then
		SoundService.PlaySFXForAll(soundName)
	end
end

function SoundService.PlayRaceStart()
	SoundService.PlaySFXForAll("RaceStart")
end

function SoundService.PlayCheckpoint(player: Player)
	SoundService.PlaySFX(player, "Checkpoint")
end

function SoundService.PlayRaceFinish(player: Player)
	SoundService.PlaySFX(player, "RaceFinish")
end

-- ============================================================================
-- PROGRESSION SOUNDS
-- ============================================================================

function SoundService.PlayXPGain(player: Player)
	SoundService.PlaySFX(player, "XPGain", { Volume = 0.5 })
end

function SoundService.PlayLevelUp(player: Player)
	SoundService.PlaySFX(player, "LevelUp")
end

function SoundService.PlayUnlock(player: Player)
	SoundService.PlaySFX(player, "Unlock")
end

function SoundService.PlayTierUp(player: Player)
	SoundService.PlaySFX(player, "TierUp")
end

-- ============================================================================
-- UTILITY
-- ============================================================================

function SoundService.GetSoundId(category: string, soundName: string): string?
	if category == "Music" then
		return MUSIC[soundName]
	elseif category == "SFX" then
		return SFX[soundName]
	end
	return nil
end

function SoundService.SetMasterVolume(volumeType: string, volume: number)
	-- Broadcast to all clients
	SoundService.Remotes.UpdateVolume:FireAllClients({
		[volumeType] = volume,
	})
end

return SoundService
