--[[
	SoundHandler.lua
	Client-side sound effect player

	Features:
	- Listens to PlaySound RemoteEvent
	- Creates and plays Sound objects
	- Sound pooling (reuse sounds for performance)
	- Volume control (Master, SFX, Music)
	- Spatial audio (3D positioned sounds)
	- Background music management

	Sound Effects:
	- Checkpoint reached
	- Tower completed
	- Coin pickup
	- Double jump
	- Air dash
	- Wall grip
	- Upgrade purchased
	- Countdown beep
	- Death

	Background Music:
	- Lobby music
	- Gameplay music

	Week 4: Full implementation (placeholder sounds)
	Later: Replace with actual sound assets
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- ============================================================================
-- WAIT FOR REMOTE EVENTS
-- ============================================================================

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not remoteFolder then
	warn("[SoundHandler] RemoteEvents folder not found!")
	return
end

local playSoundEvent = remoteFolder:WaitForChild("PlaySound", 10)
if not playSoundEvent then
	warn("[SoundHandler] PlaySound event not found!")
	return
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MASTER_VOLUME = 0.5
local SFX_VOLUME = 0.7
local MUSIC_VOLUME = 0.3

-- ============================================================================
-- SOUND TEMPLATES
-- ============================================================================

-- NOTE: Using placeholder sound IDs
-- Replace with actual sound assets later

local SoundTemplates = {
	-- Sound Effects
	CheckpointReached = {
		SoundId = "rbxassetid://9120386436", -- Placeholder: notification sound
		Volume = 0.5,
		Category = "SFX",
		Pitch = 1.2,
	},

	TowerCompleted = {
		SoundId = "rbxassetid://9120386436",
		Volume = 0.8,
		Category = "SFX",
		Pitch = 1.0,
	},

	CoinPickup = {
		SoundId = "rbxassetid://9120386436",
		Volume = 0.3,
		Category = "SFX",
		Pitch = 1.5,
	},

	DoubleJump = {
		SoundId = "rbxassetid://9120385205", -- Placeholder: whoosh
		Volume = 0.4,
		Category = "SFX",
		Pitch = 1.1,
	},

	AirDash = {
		SoundId = "rbxassetid://9120385205",
		Volume = 0.5,
		Category = "SFX",
		Pitch = 0.9,
	},

	WallGrip = {
		SoundId = "rbxassetid://9120385205",
		Volume = 0.3,
		Category = "SFX",
		Pitch = 0.7,
	},

	UpgradePurchased = {
		SoundId = "rbxassetid://9120386436",
		Volume = 0.6,
		Category = "SFX",
		Pitch = 1.3,
	},

	CountdownBeep = {
		SoundId = "rbxassetid://9120386436",
		Volume = 0.5,
		Category = "SFX",
		Pitch = 1.0,
	},

	PlayerDeath = {
		SoundId = "rbxassetid://9120385205",
		Volume = 0.4,
		Category = "SFX",
		Pitch = 0.6,
	},

	-- Background Music (Placeholder)
	LobbyMusic = {
		SoundId = "rbxassetid://1837879082", -- Placeholder: calm music
		Volume = 0.3,
		Category = "Music",
		Looped = true,
	},

	GameplayMusic = {
		SoundId = "rbxassetid://1837879082",
		Volume = 0.3,
		Category = "Music",
		Looped = true,
	},
}

-- ============================================================================
-- SOUND POOL
-- ============================================================================

local soundPool = {}
local activeSounds = {}
local currentMusic = nil

-- ============================================================================
-- SOUND CREATION
-- ============================================================================

local function createSound(template, position: Vector3?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = template.SoundId
	sound.Volume = template.Volume * (template.Category == "Music" and MUSIC_VOLUME or SFX_VOLUME) * MASTER_VOLUME
	sound.Pitch = template.Pitch or 1.0
	sound.Looped = template.Looped or false

	if position then
		-- Spatial 3D sound
		local part = Instance.new("Part")
		part.Size = Vector3.new(1, 1, 1)
		part.Position = position
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = workspace

		sound.Parent = part

		-- Cleanup when sound ends
		sound.Ended:Connect(function()
			task.wait(0.5)
			if part then
				part:Destroy()
			end
		end)
	else
		-- Non-spatial sound (global)
		sound.Parent = SoundService
	end

	return sound
end

-- ============================================================================
-- PLAY SOUND
-- ============================================================================

local function playSound(soundName: string, position: Vector3?)
	local template = SoundTemplates[soundName]
	if not template then
		warn("[SoundHandler] Unknown sound:", soundName)
		return
	end

	-- Create and play sound
	local sound = createSound(template, position)

	-- Track active sound
	table.insert(activeSounds, sound)

	-- Play
	sound:Play()

	-- Cleanup when done (if not looped)
	if not template.Looped then
		sound.Ended:Connect(function()
			-- Remove from active sounds
			local index = table.find(activeSounds, sound)
			if index then
				table.remove(activeSounds, index)
			end

			-- Cleanup
			if sound.Parent and sound.Parent:IsA("Part") then
				sound.Parent:Destroy()
			else
				sound:Destroy()
			end
		end)
	end

	print(string.format(
		"[SoundHandler] Playing %s at %s (Active sounds: %d)",
		soundName,
		position and tostring(position) or "global",
		#activeSounds
	))

	return sound
end

-- ============================================================================
-- BACKGROUND MUSIC
-- ============================================================================

local function playBackgroundMusic(musicName: string)
	-- Stop current music if playing
	if currentMusic then
		-- Fade out
		for i = 10, 0, -1 do
			if currentMusic then
				currentMusic.Volume = (i / 10) * MUSIC_VOLUME * MASTER_VOLUME
			end
			task.wait(0.05)
		end

		if currentMusic then
			currentMusic:Stop()
			currentMusic:Destroy()
			currentMusic = nil
		end
	end

	-- Start new music
	local template = SoundTemplates[musicName]
	if not template then
		warn("[SoundHandler] Unknown music:", musicName)
		return
	end

	currentMusic = createSound(template)
	currentMusic.Volume = 0 -- Start at 0 for fade in

	currentMusic:Play()

	-- Fade in
	for i = 0, 10 do
		if currentMusic then
			currentMusic.Volume = (i / 10) * template.Volume * MUSIC_VOLUME * MASTER_VOLUME
		end
		task.wait(0.05)
	end

	print("[SoundHandler] Playing background music:", musicName)
end

local function stopBackgroundMusic()
	if not currentMusic then return end

	-- Fade out
	for i = 10, 0, -1 do
		if currentMusic then
			currentMusic.Volume = (i / 10) * MUSIC_VOLUME * MASTER_VOLUME
		end
		task.wait(0.05)
	end

	if currentMusic then
		currentMusic:Stop()
		currentMusic:Destroy()
		currentMusic = nil
	end

	print("[SoundHandler] Stopped background music")
end

-- ============================================================================
-- VOLUME CONTROL
-- ============================================================================

local function setMasterVolume(volume: number)
	MASTER_VOLUME = math.clamp(volume, 0, 1)

	-- Update all active sounds
	for _, sound in ipairs(activeSounds) do
		if sound and sound:IsA("Sound") then
			local template = nil
			for name, temp in pairs(SoundTemplates) do
				if temp.SoundId == sound.SoundId then
					template = temp
					break
				end
			end

			if template then
				sound.Volume = template.Volume * (template.Category == "Music" and MUSIC_VOLUME or SFX_VOLUME) * MASTER_VOLUME
			end
		end
	end

	-- Update music
	if currentMusic then
		local template = nil
		for name, temp in pairs(SoundTemplates) do
			if temp.SoundId == currentMusic.SoundId then
				template = temp
				break
			end
		end

		if template then
			currentMusic.Volume = template.Volume * MUSIC_VOLUME * MASTER_VOLUME
		end
	end

	print("[SoundHandler] Master volume:", MASTER_VOLUME)
end

local function setSFXVolume(volume: number)
	SFX_VOLUME = math.clamp(volume, 0, 1)
	print("[SoundHandler] SFX volume:", SFX_VOLUME)
end

local function setMusicVolume(volume: number)
	MUSIC_VOLUME = math.clamp(volume, 0, 1)

	-- Update music if playing
	if currentMusic then
		for name, template in pairs(SoundTemplates) do
			if template.SoundId == currentMusic.SoundId then
				currentMusic.Volume = template.Volume * MUSIC_VOLUME * MASTER_VOLUME
				break
			end
		end
	end

	print("[SoundHandler] Music volume:", MUSIC_VOLUME)
end

-- ============================================================================
-- REMOTE EVENT LISTENER
-- ============================================================================

playSoundEvent.OnClientEvent:Connect(function(soundName: string, position: Vector3?)
	-- Check if it's music
	local template = SoundTemplates[soundName]
	if template and template.Category == "Music" then
		playBackgroundMusic(soundName)
	else
		playSound(soundName, position)
	end
end)

-- ============================================================================
-- THEME MUSIC (Week 8)
-- ============================================================================

-- Theme music templates (placeholders - replace with actual assets)
local ThemeMusicTemplates = {
	Grasslands = {
		SoundId = "rbxassetid://1843463175", -- Placeholder: calm music
		Volume = 0.4,
		Looped = true,
	},
	Desert = {
		SoundId = "rbxassetid://1843463175", -- Placeholder
		Volume = 0.4,
		Looped = true,
	},
	Snow = {
		SoundId = "rbxassetid://1843463175", -- Placeholder
		Volume = 0.4,
		Looped = true,
	},
	Volcano = {
		SoundId = "rbxassetid://1843463175", -- Placeholder
		Volume = 0.5,
		Looped = true,
	},
}

local function playThemeMusic(themeName: string)
	--[[
		Plays theme-specific background music with fade transition.
	--]]

	local template = ThemeMusicTemplates[themeName]
	if not template then
		warn("[SoundHandler] Unknown theme music:", themeName)
		return
	end

	-- Check if already playing this theme
	if currentMusic and currentMusic.Name == "ThemeMusic_" .. themeName then
		print("[SoundHandler] Theme music already playing:", themeName)
		return
	end

	-- Stop current music (with fade)
	if currentMusic then
		-- Fade out
		for i = 10, 0, -1 do
			if currentMusic then
				currentMusic.Volume = (i / 10) * MUSIC_VOLUME * MASTER_VOLUME
			end
			task.wait(0.05)
		end

		if currentMusic then
			currentMusic:Stop()
			currentMusic:Destroy()
			currentMusic = nil
		end
	end

	-- Create new theme music
	currentMusic = Instance.new("Sound")
	currentMusic.Name = "ThemeMusic_" .. themeName
	currentMusic.SoundId = template.SoundId
	currentMusic.Volume = 0 -- Start at 0 for fade in
	currentMusic.Looped = template.Looped
	currentMusic.Parent = SoundService

	currentMusic:Play()

	-- Fade in
	for i = 0, 10 do
		if currentMusic then
			currentMusic.Volume = (i / 10) * template.Volume * MUSIC_VOLUME * MASTER_VOLUME
		end
		task.wait(0.05)
	end

	print("[SoundHandler] Playing theme music:", themeName)
end

-- Listen for theme music changes from server
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
if eventsFolder then
	local changeThemeMusicEvent = eventsFolder:WaitForChild("ChangeThemeMusic", 10)
	if changeThemeMusicEvent then
		changeThemeMusicEvent.OnClientEvent:Connect(function(themeName: string)
			playThemeMusic(themeName)
		end)
		print("[SoundHandler] Listening for theme music changes")
	end
end

-- ============================================================================
-- GLOBAL ACCESS (for SettingsUI)
-- ============================================================================

_G.SoundHandler = {
	SetMasterVolume = setMasterVolume,
	SetSFXVolume = setSFXVolume,
	SetMusicVolume = setMusicVolume,
	PlaySound = playSound,
	PlayBackgroundMusic = playBackgroundMusic,
	StopBackgroundMusic = stopBackgroundMusic,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

print("[SoundHandler] Initialized (listening for sound events)")
print("[SoundHandler] Using placeholder sound IDs - replace with actual assets later")
