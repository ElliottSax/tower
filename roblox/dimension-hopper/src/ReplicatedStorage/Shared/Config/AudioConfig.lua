--[[
	AudioConfig.lua
	Centralized audio asset configuration for Dimension Hopper

	HOW TO REPLACE PLACEHOLDER IDs:
	1. Upload your audio files to Roblox Creator Hub
	2. Get the asset IDs (numbers after rbxassetid://)
	3. Replace the 0 values below with your asset IDs
	4. Test in Studio to verify all sounds play correctly

	RECOMMENDED AUDIO STYLES:
	- Gravity: Electronic, space ambient, synthwave
	- Tiny: Whimsical, orchestral, nature sounds
	- Void: Dark ambient, horror, industrial
	- Sky: Uplifting orchestral, wind instruments, ethereal

	LICENSING NOTES:
	- Use royalty-free music or music you have rights to
	- Popular sources: Epidemic Sound, Artlist, AudioJungle
	- Free options: FreePD, Incompetech (Kevin MacLeod)
]]

local AudioConfig = {}

-- ============================================================================
-- MUSIC TRACKS
-- ============================================================================

AudioConfig.Music = {
	-- Main Menu / Lobby
	Lobby = {
		AssetId = "rbxassetid://0", -- TODO: Upload menu music
		Volume = 0.5,
		Looped = true,
		FadeTime = 2,
		Description = "Ambient, inviting track for the main menu",
	},

	-- Gravity Dimension
	Gravity = {
		AssetId = "rbxassetid://0", -- TODO: Upload gravity dimension music
		Volume = 0.4,
		Looped = true,
		FadeTime = 1.5,
		Description = "Electronic/synthwave with space vibes",
		-- Suggested: 120-140 BPM, minor key, pulsing bass
	},

	-- Tiny Dimension
	Tiny = {
		AssetId = "rbxassetid://0", -- TODO: Upload tiny dimension music
		Volume = 0.5,
		Looped = true,
		FadeTime = 1.5,
		Description = "Whimsical, playful orchestral with nature elements",
		-- Suggested: 100-120 BPM, major key, pizzicato strings
	},

	-- Void Dimension
	Void = {
		AssetId = "rbxassetid://0", -- TODO: Upload void dimension music
		Volume = 0.35,
		Looped = true,
		FadeTime = 1,
		Description = "Dark ambient, tension-building horror",
		-- Suggested: 80-100 BPM, dissonant, heavy reverb
	},

	-- Sky Dimension
	Sky = {
		AssetId = "rbxassetid://0", -- TODO: Upload sky dimension music
		Volume = 0.5,
		Looped = true,
		FadeTime = 1.5,
		Description = "Uplifting orchestral, soaring melodies",
		-- Suggested: 130-150 BPM, major key, brass/strings
	},

	-- Victory / Results
	Victory = {
		AssetId = "rbxassetid://0", -- TODO: Upload victory fanfare
		Volume = 0.6,
		Looped = false,
		FadeTime = 0,
		Description = "Short celebratory fanfare (10-15 seconds)",
	},

	-- Race Countdown
	CountdownLoop = {
		AssetId = "rbxassetid://0", -- TODO: Upload countdown tension music
		Volume = 0.4,
		Looped = true,
		FadeTime = 0.5,
		Description = "Building tension during countdown",
	},
}

-- ============================================================================
-- SOUND EFFECTS - UI
-- ============================================================================

AudioConfig.UI = {
	ButtonClick = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Generic button click",
	},

	ButtonHover = {
		AssetId = "rbxassetid://0",
		Volume = 0.3,
		Description = "Button hover/focus",
	},

	MenuOpen = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Menu/panel opening whoosh",
	},

	MenuClose = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Description = "Menu/panel closing",
	},

	Purchase = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Successful purchase sound",
	},

	Error = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Error/denied action",
	},

	Notification = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Description = "Achievement/notification popup",
	},

	LevelUp = {
		AssetId = "rbxassetid://0",
		Volume = 0.7,
		Description = "Level up celebration",
	},

	TierUp = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Pass tier progression",
	},
}

-- ============================================================================
-- SOUND EFFECTS - GAMEPLAY
-- ============================================================================

AudioConfig.Gameplay = {
	-- Race
	Countdown3 = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Countdown beep (3, 2, 1)",
	},

	CountdownGo = {
		AssetId = "rbxassetid://0",
		Volume = 0.7,
		Description = "'GO!' sound for race start",
	},

	RaceStart = {
		AssetId = "rbxassetid://0",
		Volume = 0.7,
		Description = "Race start horn/signal",
	},

	RaceFinish = {
		AssetId = "rbxassetid://0",
		Volume = 0.8,
		Description = "Crossing finish line",
	},

	-- Checkpoints
	Checkpoint = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Checkpoint reached chime",
	},

	-- Player Actions
	Jump = {
		AssetId = "rbxassetid://0",
		Volume = 0.3,
		Description = "Basic jump",
	},

	Land = {
		AssetId = "rbxassetid://0",
		Volume = 0.25,
		Description = "Landing on platform",
	},

	Death = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Player death/respawn",
	},

	Respawn = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Description = "Respawn teleport effect",
	},
}

-- ============================================================================
-- SOUND EFFECTS - GRAVITY DIMENSION
-- ============================================================================

AudioConfig.Gravity = {
	FlipEnter = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Entering gravity flip zone",
	},

	FlipTransition = {
		AssetId = "rbxassetid://0",
		Volume = 0.7,
		Description = "Gravity flip whoosh (rotation)",
	},

	FlipComplete = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Gravity settled in new direction",
	},

	Ambient = {
		AssetId = "rbxassetid://0",
		Volume = 0.2,
		Looped = true,
		Description = "Space ambient hum",
	},
}

-- ============================================================================
-- SOUND EFFECTS - TINY DIMENSION
-- ============================================================================

AudioConfig.Tiny = {
	ShrinkStart = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Beginning to shrink",
	},

	ShrinkLoop = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Looped = true,
		Description = "Shrinking in progress",
	},

	ShrinkComplete = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Finished shrinking",
	},

	GrowStart = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Beginning to grow",
	},

	GrowComplete = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Finished growing",
	},

	Ambient = {
		AssetId = "rbxassetid://0",
		Volume = 0.2,
		Looped = true,
		Description = "Nature sounds, birds, insects",
	},
}

-- ============================================================================
-- SOUND EFFECTS - VOID DIMENSION
-- ============================================================================

AudioConfig.Void = {
	VoidAmbient = {
		AssetId = "rbxassetid://0",
		Volume = 0.3,
		Looped = true,
		Description = "Ominous void presence (constant)",
	},

	VoidNear = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Void getting close warning",
	},

	VoidVeryClose = {
		AssetId = "rbxassetid://0",
		Volume = 0.7,
		Description = "Void almost caught you",
	},

	VoidCatch = {
		AssetId = "rbxassetid://0",
		Volume = 0.8,
		Description = "Caught by the void (death)",
	},

	PlatformWarning = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Platform starting to crumble",
	},

	PlatformCrumble = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Platform crumbling apart",
	},

	PlatformDestroy = {
		AssetId = "rbxassetid://0",
		Volume = 0.7,
		Description = "Platform fully destroyed",
	},

	SafeZoneEnter = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Entering safe zone relief",
	},
}

-- ============================================================================
-- SOUND EFFECTS - SKY DIMENSION
-- ============================================================================

AudioConfig.Sky = {
	GliderDeploy = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Glider opening/deploying",
	},

	GliderRetract = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Glider closing/retracting",
	},

	GliderGlide = {
		AssetId = "rbxassetid://0",
		Volume = 0.3,
		Looped = true,
		Description = "Wind while gliding (constant)",
	},

	GliderBoost = {
		AssetId = "rbxassetid://0",
		Volume = 0.6,
		Description = "Boost activation",
	},

	WindGust = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Strong wind gust hit",
	},

	WindCurrent = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Looped = true,
		Description = "Inside wind current",
	},

	UpdraftEnter = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Entering updraft",
	},

	UpdraftLoop = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Looped = true,
		Description = "Rising in updraft",
	},

	CloudBounce = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Bouncing on cloud platform",
	},

	Ambient = {
		AssetId = "rbxassetid://0",
		Volume = 0.25,
		Looped = true,
		Description = "Wind and birds in the sky",
	},
}

-- ============================================================================
-- COSMETIC SOUNDS
-- ============================================================================

AudioConfig.Cosmetics = {
	TrailActivate = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Description = "Trail effect activated",
	},

	WingsEquip = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Wings equipped",
	},

	AuraActivate = {
		AssetId = "rbxassetid://0",
		Volume = 0.4,
		Description = "Aura effect activated",
	},

	EmotePlay = {
		AssetId = "rbxassetid://0",
		Volume = 0.5,
		Description = "Emote performed",
	},
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function AudioConfig.GetSound(category: string, soundName: string): table?
	local categoryTable = AudioConfig[category]
	if not categoryTable then
		return nil
	end
	return categoryTable[soundName]
end

function AudioConfig.GetAssetId(category: string, soundName: string): string?
	local sound = AudioConfig.GetSound(category, soundName)
	if sound then
		return sound.AssetId
	end
	return nil
end

-- Returns list of all sounds with placeholder IDs (for validation)
function AudioConfig.GetPlaceholderSounds(): table
	local placeholders = {}

	for category, sounds in pairs(AudioConfig) do
		if type(sounds) == "table" and category ~= "Music" then
			for name, config in pairs(sounds) do
				if type(config) == "table" and config.AssetId == "rbxassetid://0" then
					table.insert(placeholders, {
						Category = category,
						Name = name,
						Description = config.Description or "No description",
					})
				end
			end
		end
	end

	-- Check music separately
	for name, config in pairs(AudioConfig.Music) do
		if config.AssetId == "rbxassetid://0" then
			table.insert(placeholders, {
				Category = "Music",
				Name = name,
				Description = config.Description or "No description",
			})
		end
	end

	return placeholders
end

-- Print validation report
function AudioConfig.ValidateAndReport()
	local placeholders = AudioConfig.GetPlaceholderSounds()

	print("========================================")
	print("AUDIO CONFIG VALIDATION REPORT")
	print("========================================")
	print(string.format("Total placeholder sounds: %d", #placeholders))
	print("")

	local byCategory = {}
	for _, p in ipairs(placeholders) do
		byCategory[p.Category] = (byCategory[p.Category] or 0) + 1
	end

	for category, count in pairs(byCategory) do
		print(string.format("  %s: %d placeholder(s)", category, count))
	end

	print("")
	print("Replace 'rbxassetid://0' with actual asset IDs")
	print("See AudioConfig.lua header for instructions")
	print("========================================")
end

return AudioConfig
