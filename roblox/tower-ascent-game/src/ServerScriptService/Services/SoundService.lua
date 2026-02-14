--[[
	SoundService.lua
	Centralized sound effect and music management

	Features:
	- Play sound effects at positions
	- Background music system
	- Volume control
	- Sound pooling (reuse sounds for performance)
	- RemoteEvent to trigger sounds on clients
	- Category-based mixing (SFX, Music, Ambient)

	Sounds (Week 3 placeholders, Week 4+ actual audio):
	- Checkpoint reached (chime)
	- Tower completion (victory fanfare)
	- Coin pickup (coin sound)
	- Double jump (whoosh)
	- Air dash (dash sound)
	- Wall grip (slide sound)
	- Upgrade purchased (success sound)
	- Round start countdown (beep)
	- Death (fail sound)
	- Background music (lobby, gameplay)

	Week 3: Basic structure
	Week 4+: Import/create actual sound assets
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local TowerSoundService = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MASTER_VOLUME = 0.5 -- Global volume (0-1)
local SFX_VOLUME = 0.7 -- Sound effects multiplier
local MUSIC_VOLUME = 0.3 -- Background music multiplier

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

TowerSoundService.RemoteEvents = {}

local function setupRemoteEvents()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- PlaySound: Server → Client (play sound on client)
	local playSoundEvent = Instance.new("RemoteEvent")
	playSoundEvent.Name = "PlaySound"
	playSoundEvent.Parent = remoteFolder
	TowerSoundService.RemoteEvents.PlaySound = playSoundEvent

	print("[SoundService] RemoteEvents setup complete")
end

-- ============================================================================
-- SOUND TEMPLATES (WEEK 4 IMPLEMENTATION)
-- ============================================================================

TowerSoundService.Templates = {
	-- Sound Effects
	CheckpointReached = {
		SoundId = "rbxassetid://0", -- Week 4: Replace with actual sound
		Volume = 0.5,
		Category = "SFX",
	},

	TowerCompleted = {
		SoundId = "rbxassetid://0",
		Volume = 0.8,
		Category = "SFX",
	},

	CoinPickup = {
		SoundId = "rbxassetid://0",
		Volume = 0.3,
		Category = "SFX",
	},

	DoubleJump = {
		SoundId = "rbxassetid://0",
		Volume = 0.4,
		Category = "SFX",
	},

	AirDash = {
		SoundId = "rbxassetid://0",
		Volume = 0.5,
		Category = "SFX",
	},

	WallGrip = {
		SoundId = "rbxassetid://0",
		Volume = 0.3,
		Category = "SFX",
	},

	UpgradePurchased = {
		SoundId = "rbxassetid://0",
		Volume = 0.6,
		Category = "SFX",
	},

	CountdownBeep = {
		SoundId = "rbxassetid://0",
		Volume = 0.5,
		Category = "SFX",
	},

	PlayerDeath = {
		SoundId = "rbxassetid://0",
		Volume = 0.4,
		Category = "SFX",
	},

	-- Background Music
	LobbyMusic = {
		SoundId = "rbxassetid://0",
		Volume = 0.3,
		Category = "Music",
		Looped = true,
	},

	GameplayMusic = {
		SoundId = "rbxassetid://0",
		Volume = 0.3,
		Category = "Music",
		Looped = true,
	},
}

-- ============================================================================
-- PLAY SOUND
-- ============================================================================

function TowerSoundService.PlaySound(soundName: string, position: Vector3?, target: Player?)
	-- Week 4: Full implementation with actual Sound objects
	-- For now, just log and send to clients

	local template = TowerSoundService.Templates[soundName]
	if not template then
		warn("[SoundService] Unknown sound:", soundName)
		return
	end

	print(string.format(
		"[SoundService] Playing %s at %s",
		soundName,
		position and tostring(position) or "nil"
	))

	-- Send to clients
	if target then
		-- Send to specific player
		TowerSoundService.RemoteEvents.PlaySound:FireClient(target, soundName, position)
	else
		-- Send to all players
		TowerSoundService.RemoteEvents.PlaySound:FireAllClients(soundName, position)
	end

	-- Week 4: Create actual Sound object
	-- local sound = createSound(template)
	-- sound:Play()
end

-- ============================================================================
-- BACKGROUND MUSIC
-- ============================================================================

function TowerSoundService.PlayBackgroundMusic(musicName: string)
	-- Week 4: Fade in/out between tracks
	print("[SoundService] Playing background music:", musicName)

	-- Send to all clients
	TowerSoundService.RemoteEvents.PlaySound:FireAllClients(musicName, nil)
end

function TowerSoundService.StopBackgroundMusic()
	-- Week 4: Fade out current track
	print("[SoundService] Stopping background music")
end

-- ============================================================================
-- VOLUME CONTROL
-- ============================================================================

function TowerSoundService.SetMasterVolume(volume: number)
	MASTER_VOLUME = math.clamp(volume, 0, 1)
	print("[SoundService] Master volume set to:", MASTER_VOLUME)

	-- Week 4: Update all active sounds
end

function TowerSoundService.SetSFXVolume(volume: number)
	SFX_VOLUME = math.clamp(volume, 0, 1)
	print("[SoundService] SFX volume set to:", SFX_VOLUME)

	-- Week 4: Update SFX sounds
end

function TowerSoundService.SetMusicVolume(volume: number)
	MUSIC_VOLUME = math.clamp(volume, 0, 1)
	print("[SoundService] Music volume set to:", MUSIC_VOLUME)

	-- Week 4: Update music volume
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function TowerSoundService.Init()
	print("[SoundService] Initializing...")

	-- Setup remote events
	setupRemoteEvents()

	-- Week 4: Create sound folders in workspace
	-- local soundsFolder = Instance.new("Folder")
	-- soundsFolder.Name = "Sounds"
	-- soundsFolder.Parent = workspace

	print("[SoundService] Initialized (Week 3 placeholder)")
	print("[SoundService] Full audio coming in Week 4")
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return TowerSoundService
