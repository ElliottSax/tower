--[[
	SoundHandler.client.lua
	Client-side audio handler for Dimension Hopper

	Handles:
	- Music playback with crossfade
	- Sound effect playback
	- Volume control
	- 3D positional audio
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundServiceGame = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
	warn("[SoundHandler] RemoteEvents not found!")
	return
end

-- ============================================================================
-- STATE
-- ============================================================================

local MusicVolume = 0.5
local SFXVolume = 0.7

local CurrentMusic = nil
local CurrentMusicName = nil
local SoundPool = {} -- Reusable sound instances

-- ============================================================================
-- SETUP
-- ============================================================================

local function CreateSoundGroup(name: string): SoundGroup
	local existing = SoundServiceGame:FindFirstChild(name)
	if existing then return existing end

	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = 1
	group.Parent = SoundServiceGame

	return group
end

local MusicGroup = CreateSoundGroup("Music")
local SFXGroup = CreateSoundGroup("SFX")

-- ============================================================================
-- MUSIC
-- ============================================================================

local function PlayMusic(data)
	local soundId = data.SoundId
	local fadeIn = data.FadeIn
	local fadeDuration = data.FadeDuration or 1

	-- Stop current music if playing
	if CurrentMusic then
		local oldMusic = CurrentMusic

		if fadeIn then
			-- Fade out current
			local fadeOut = TweenService:Create(oldMusic, TweenInfo.new(fadeDuration), {
				Volume = 0
			})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				oldMusic:Stop()
				oldMusic:Destroy()
			end)
		else
			oldMusic:Stop()
			oldMusic:Destroy()
		end
	end

	-- Skip if no valid sound ID
	if not soundId or soundId == "rbxassetid://0" then
		CurrentMusic = nil
		CurrentMusicName = nil
		return
	end

	-- Create new music sound
	local music = Instance.new("Sound")
	music.Name = data.TrackName or "Music"
	music.SoundId = soundId
	music.Looped = true
	music.Volume = fadeIn and 0 or MusicVolume
	music.SoundGroup = MusicGroup
	music.Parent = SoundServiceGame

	music:Play()

	-- Fade in
	if fadeIn then
		TweenService:Create(music, TweenInfo.new(fadeDuration), {
			Volume = MusicVolume
		}):Play()
	end

	CurrentMusic = music
	CurrentMusicName = data.TrackName

	print(string.format("[SoundHandler] Playing music: %s", data.TrackName or "Unknown"))
end

local function StopMusic(data)
	if not CurrentMusic then return end

	local fadeOut = data.FadeOut
	local fadeDuration = data.FadeDuration or 1

	local music = CurrentMusic
	CurrentMusic = nil
	CurrentMusicName = nil

	if fadeOut then
		local tween = TweenService:Create(music, TweenInfo.new(fadeDuration), {
			Volume = 0
		})
		tween:Play()
		tween.Completed:Connect(function()
			music:Stop()
			music:Destroy()
		end)
	else
		music:Stop()
		music:Destroy()
	end
end

-- ============================================================================
-- SOUND EFFECTS
-- ============================================================================

local function GetPooledSound(soundId: string): Sound
	-- Try to reuse a stopped sound
	for i, sound in ipairs(SoundPool) do
		if not sound.IsPlaying and sound.SoundId == soundId then
			return sound
		end
	end

	-- Create new sound if pool isn't too large
	if #SoundPool < 20 then
		local sound = Instance.new("Sound")
		sound.SoundGroup = SFXGroup
		sound.Parent = SoundServiceGame
		table.insert(SoundPool, sound)
		return sound
	end

	-- Reuse oldest stopped sound
	for _, sound in ipairs(SoundPool) do
		if not sound.IsPlaying then
			return sound
		end
	end

	-- All sounds are playing, create temporary one
	local sound = Instance.new("Sound")
	sound.SoundGroup = SFXGroup
	sound.Parent = SoundServiceGame

	-- Auto-cleanup
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	return sound
end

local function PlaySound(data)
	local soundId = data.SoundId

	-- Skip if no valid sound ID
	if not soundId or soundId == "rbxassetid://0" then
		return
	end

	local sound = GetPooledSound(soundId)

	sound.SoundId = soundId
	sound.Volume = (data.Volume or 1) * SFXVolume
	sound.PlaybackSpeed = data.Pitch or 1
	sound.Looped = data.Loop or false

	-- 3D positional audio
	if data.Position then
		-- Create or update attachment for 3D sound
		local attachment = sound:FindFirstChild("SoundAttachment")
		if not attachment then
			attachment = Instance.new("Attachment")
			attachment.Name = "SoundAttachment"
			attachment.Parent = workspace.Terrain
		end
		attachment.WorldPosition = data.Position

		-- Make sound play from attachment position
		sound.RollOffMode = Enum.RollOffMode.Linear
		sound.RollOffMinDistance = 10
		sound.RollOffMaxDistance = 100
	else
		sound.RollOffMode = Enum.RollOffMode.Inverse
	end

	sound:Play()
end

-- ============================================================================
-- VOLUME CONTROL
-- ============================================================================

local function UpdateVolume(data)
	if data.Music ~= nil then
		MusicVolume = data.Music
		MusicGroup.Volume = MusicVolume

		-- Update current music if playing
		if CurrentMusic then
			CurrentMusic.Volume = MusicVolume
		end
	end

	if data.SFX ~= nil then
		SFXVolume = data.SFX
		SFXGroup.Volume = SFXVolume
	end
end

-- ============================================================================
-- CONNECT REMOTES
-- ============================================================================

if RemoteEvents:FindFirstChild("PlayMusic") then
	RemoteEvents.PlayMusic.OnClientEvent:Connect(PlayMusic)
end

if RemoteEvents:FindFirstChild("StopMusic") then
	RemoteEvents.StopMusic.OnClientEvent:Connect(StopMusic)
end

if RemoteEvents:FindFirstChild("PlaySound") then
	RemoteEvents.PlaySound.OnClientEvent:Connect(PlaySound)
end

if RemoteEvents:FindFirstChild("UpdateVolume") then
	RemoteEvents.UpdateVolume.OnClientEvent:Connect(UpdateVolume)
end

-- ============================================================================
-- LOCAL SOUND HELPERS
-- ============================================================================

-- Expose for other client scripts
_G.PlayLocalSound = function(soundId: string, options: table?)
	options = options or {}
	PlaySound({
		SoundId = soundId,
		Volume = options.Volume or 1,
		Pitch = options.Pitch or 1,
		Position = options.Position,
		Loop = options.Loop,
	})
end

_G.StopLocalMusic = function()
	StopMusic({ FadeOut = true, FadeDuration = 0.5 })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

print("[SoundHandler] Sound handler initialized")
