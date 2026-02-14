--[[
	MusicPlayer.lua
	Client-side music and sound effect player

	Features:
	- Background music playback
	- Crossfading between tracks
	- Volume control
	- Sound effect playback
	- Respects player settings
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local MusicPlayer = {}
MusicPlayer.CurrentTrack = nil
MusicPlayer.MusicVolume = 0.5
MusicPlayer.SFXVolume = 0.7

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function MusicPlayer.Init()
	print("[MusicPlayer] Initializing...")

	-- Create sound container
	MusicPlayer.CreateSoundContainer()

	-- Load settings
	MusicPlayer.LoadSettings()

	-- Connect to remote events
	MusicPlayer.ConnectRemotes()

	print("[MusicPlayer] Initialized")
end

-- ============================================================================
-- SOUND CONTAINER
-- ============================================================================

function MusicPlayer.CreateSoundContainer()
	-- Create folder for sounds
	MusicPlayer.Container = Instance.new("Folder")
	MusicPlayer.Container.Name = "MusicPlayer"
	MusicPlayer.Container.Parent = SoundService

	-- Create music sound
	MusicPlayer.MusicSound = Instance.new("Sound")
	MusicPlayer.MusicSound.Name = "Music"
	MusicPlayer.MusicSound.Volume = MusicPlayer.MusicVolume
	MusicPlayer.MusicSound.Looped = true
	MusicPlayer.MusicSound.Parent = MusicPlayer.Container
end

-- ============================================================================
-- MUSIC CONTROL
-- ============================================================================

function MusicPlayer.PlayMusic(trackName: string, trackData: {})
	-- If same track is playing, do nothing
	if MusicPlayer.CurrentTrack == trackName and MusicPlayer.MusicSound.IsPlaying then
		return
	end

	-- Crossfade out current track
	if MusicPlayer.MusicSound.IsPlaying then
		MusicPlayer.FadeOut(MusicPlayer.MusicSound, function()
			MusicPlayer.MusicSound:Stop()
			MusicPlayer.StartNewTrack(trackName, trackData)
		end)
	else
		MusicPlayer.StartNewTrack(trackName, trackData)
	end
end

function MusicPlayer.StartNewTrack(trackName: string, trackData: {})
	-- Set sound properties
	MusicPlayer.MusicSound.SoundId = trackData.SoundId
	MusicPlayer.MusicSound.Volume = 0 -- Start at 0 for fade in
	MusicPlayer.MusicSound.Looped = trackData.Looped

	-- Play
	MusicPlayer.MusicSound:Play()
	MusicPlayer.CurrentTrack = trackName

	-- Fade in
	MusicPlayer.FadeIn(MusicPlayer.MusicSound, trackData.Volume * MusicPlayer.MusicVolume)

	print(string.format("[MusicPlayer] Now playing: %s", trackData.Name))
end

function MusicPlayer.StopMusic()
	if MusicPlayer.MusicSound.IsPlaying then
		MusicPlayer.FadeOut(MusicPlayer.MusicSound, function()
			MusicPlayer.MusicSound:Stop()
			MusicPlayer.CurrentTrack = nil
		end)
	end
end

function MusicPlayer.SetMusicVolume(volume: number)
	MusicPlayer.MusicVolume = math.clamp(volume, 0, 1)

	-- Update current track volume
	if MusicPlayer.MusicSound.IsPlaying then
		TweenService:Create(
			MusicPlayer.MusicSound,
			TweenInfo.new(0.5),
			{Volume = MusicPlayer.MusicVolume}
		):Play()
	end

	-- Save setting
	MusicPlayer.SaveSettings()
end

-- ============================================================================
-- SOUND EFFECTS
-- ============================================================================

function MusicPlayer.PlaySound(soundId: string, volume: number)
	-- Create temporary sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume * MusicPlayer.SFXVolume
	sound.Parent = MusicPlayer.Container

	-- Play and cleanup
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- ============================================================================
-- FADE EFFECTS
-- ============================================================================

function MusicPlayer.FadeIn(sound: Sound, targetVolume: number)
	TweenService:Create(
		sound,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Volume = targetVolume}
	):Play()
end

function MusicPlayer.FadeOut(sound: Sound, callback)
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Volume = 0}
	)

	if callback then
		tween.Completed:Connect(callback)
	end

	tween:Play()
end

-- ============================================================================
-- SETTINGS
-- ============================================================================

function MusicPlayer.LoadSettings()
	-- Try to load from DataService
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local getSettingRemote = remoteEvents:FindFirstChild("GetSetting")
	if getSettingRemote then
		local success, musicVolume = pcall(function()
			return getSettingRemote:InvokeServer("MusicVolume")
		end)

		if success and musicVolume then
			MusicPlayer.MusicVolume = musicVolume
		end

		local success2, sfxVolume = pcall(function()
			return getSettingRemote:InvokeServer("SFXVolume")
		end)

		if success2 and sfxVolume then
			MusicPlayer.SFXVolume = sfxVolume
		end
	end
end

function MusicPlayer.SaveSettings()
	-- Save to DataService
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then return end

	local setSettingRemote = remoteEvents:FindFirstChild("SetSetting")
	if setSettingRemote then
		pcall(function()
			setSettingRemote:InvokeServer("MusicVolume", MusicPlayer.MusicVolume)
			setSettingRemote:InvokeServer("SFXVolume", MusicPlayer.SFXVolume)
		end)
	end
end

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

function MusicPlayer.ConnectRemotes()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	if not remoteEvents then return end

	-- PlayMusic
	local playMusicRemote = remoteEvents:WaitForChild("PlayMusic", 5)
	if playMusicRemote then
		playMusicRemote.OnClientEvent:Connect(function(trackName, trackData)
			MusicPlayer.PlayMusic(trackName, trackData)
		end)
	end

	-- StopMusic
	local stopMusicRemote = remoteEvents:WaitForChild("StopMusic", 5)
	if stopMusicRemote then
		stopMusicRemote.OnClientEvent:Connect(function()
			MusicPlayer.StopMusic()
		end)
	end

	-- SetMusicVolume
	local setMusicVolumeRemote = remoteEvents:WaitForChild("SetMusicVolume", 5)
	if setMusicVolumeRemote then
		setMusicVolumeRemote.OnClientEvent:Connect(function(volume)
			MusicPlayer.SetMusicVolume(volume)
		end)
	end

	-- PlaySound
	local playSoundRemote = remoteEvents:WaitForChild("PlaySound", 5)
	if playSoundRemote then
		playSoundRemote.OnClientEvent:Connect(function(soundId, volume)
			MusicPlayer.PlaySound(soundId, volume)
		end)
	end

	print("[MusicPlayer] Remotes connected")
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-initialize
MusicPlayer.Init()

-- Expose globally
_G.MusicPlayer = MusicPlayer

return MusicPlayer
