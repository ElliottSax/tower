--[[
	StoryChapters.lua
	Defines the structure and metadata for all worlds and levels

	Format:
	{
		WorldId = {
			LevelId = {
				Name = "Level Name",
				Description = "Description",
				Difficulty = "Easy/Normal/Hard/Expert",
				Checkpoints = 5,
				Collectibles = {...},
				...
			}
		}
	}
--]]

local StoryChapters = {}

-- ============================================================================
-- WORLD 1: MYSTIC FOREST
-- ============================================================================

StoryChapters.World1 = {
	Name = "Mystic Forest",
	Description = "A cursed forest shrouded in ancient magic",

	-- Level 1: Tutorial Path
	Level1 = {
		Id = "World1_Level1",
		Name = "Tutorial Path",
		Description = "Learn the basics of parkour in this gentle introduction",
		Difficulty = "Easy",
		Checkpoints = 3,
		EstimatedTime = 120, -- seconds
		Collectibles = {
			Coins = 5,
			Fragments = 0,
		},
		Hazards = {},
		Mechanics = {"Basic jumping", "Walking"},
		Story = {
			Intro = "Elder Moss guides you to the beginning of your journey...",
			Outro = "Well done! You've mastered the basics. Onward to greater challenges!",
		},
		Rewards = {
			Coins = 50,
			Experience = 100,
		}
	},

	-- Level 2: Forest Trail
	Level2 = {
		Id = "World1_Level2",
		Name = "Forest Trail",
		Description = "Navigate moving platforms through the dense forest",
		Difficulty = "Easy",
		Checkpoints = 4,
		EstimatedTime = 180,
		Collectibles = {
			Coins = 8,
			Fragments = 1, -- First fragment here
		},
		Hazards = {"Moving platforms"},
		Mechanics = {"Timed jumps", "Moving platforms"},
		Story = {
			Intro = "The forest grows thicker. Ancient magic hums in the air...",
			Outro = "You've found the first fragment! Its power resonates through the forest.",
		},
		Rewards = {
			Coins = 75,
			Experience = 150,
		}
	},

	-- Level 3: River Crossing
	Level3 = {
		Id = "World1_Level3",
		Name = "River Crossing",
		Description = "Cross the mystical river with precise timing",
		Difficulty = "Normal",
		Checkpoints = 5,
		EstimatedTime = 240,
		Collectibles = {
			Coins = 10,
			Fragments = 1, -- Second fragment here
		},
		Hazards = {"Water (instant death)", "Moving platforms", "Disappearing platforms"},
		Mechanics = {"Precise timing", "Long jumps", "Disappearing platforms"},
		Story = {
			Intro = "The cursed river blocks your path. Time your jumps carefully...",
			Outro = "Another fragment recovered! The curse weakens with each piece.",
		},
		Rewards = {
			Coins = 100,
			Experience = 200,
		}
	},

	-- Level 4: Ancient Ruins
	Level4 = {
		Id = "World1_Level4",
		Name = "Ancient Ruins",
		Description = "Explore treacherous ruins filled with deadly hazards",
		Difficulty = "Normal",
		Checkpoints = 6,
		EstimatedTime = 300,
		Collectibles = {
			Coins = 12,
			Fragments = 1, -- Third and final fragment
		},
		Hazards = {"Spikes", "Falling platforms", "Moving obstacles"},
		Mechanics = {"Hazard avoidance", "Complex platforming", "Multiple paths"},
		Story = {
			Intro = "The ancient ruins hold the final fragment. Danger lurks in every shadow...",
			Outro = "The final fragment is yours! Now return to Elder Moss.",
		},
		Rewards = {
			Coins = 125,
			Experience = 250,
		}
	},

	-- Level 5: Guardian's Gate
	Level5 = {
		Id = "World1_Level5",
		Name = "Guardian's Gate",
		Description = "Face the ultimate challenge and confront the source of the curse",
		Difficulty = "Hard",
		Checkpoints = 7,
		EstimatedTime = 420,
		Collectibles = {
			Coins = 15,
			Fragments = 0,
		},
		Hazards = {"All previous hazards", "Boss-style finale", "Complex sequences"},
		Mechanics = {"Everything learned so far", "Boss encounter style"},
		Story = {
			Intro = "The heart of the curse lies beyond this gate. Steel your resolve...",
			Outro = "Victory! The curse begins to lift. The Mystic Forest is saved!",
		},
		Rewards = {
			Coins = 200,
			Experience = 500,
			Title = "Forest Champion",
		},
		IsFinalLevel = true,
	},
}

-- ============================================================================
-- FUTURE WORLDS (Architecture support)
-- ============================================================================

-- StoryChapters.World2 = {
-- 	Name = "Crystal Caves",
-- 	Description = "Glimmering caverns filled with precious gems",
-- 	-- Levels here...
-- }

-- StoryChapters.World3 = {
-- 	Name = "Sky Citadel",
-- 	Description = "Ancient fortress floating among the clouds",
-- 	-- Levels here...
-- }

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function StoryChapters.GetLevel(worldId, levelId)
	local world = StoryChapters["World" .. tostring(worldId)]
	if not world then return nil end

	return world["Level" .. tostring(levelId)]
end

function StoryChapters.GetLevelById(levelIdString)
	-- Parse "World1_Level1" format
	local worldNum, levelNum = levelIdString:match("World(%d+)_Level(%d+)")
	if not worldNum or not levelNum then return nil end

	return StoryChapters.GetLevel(tonumber(worldNum), tonumber(levelNum))
end

function StoryChapters.GetWorld(worldId)
	return StoryChapters["World" .. tostring(worldId)]
end

function StoryChapters.GetTotalLevels(worldId)
	local world = StoryChapters["World" .. tostring(worldId)]
	if not world then return 0 end

	local count = 0
	for i = 1, 20 do -- Check up to 20 levels
		if world["Level" .. tostring(i)] then
			count = count + 1
		else
			break
		end
	end

	return count
end

return StoryChapters
