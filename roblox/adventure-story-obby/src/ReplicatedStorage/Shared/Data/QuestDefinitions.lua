--[[
	QuestDefinitions.lua
	Defines all quests (story quests and daily quests)

	Quest Format:
	{
		Id = "UniqueQuestId",
		Type = "Story" | "Daily" | "Weekly",
		Name = "Quest Name",
		Description = "Quest description",
		Objectives = {
			{Type = "Collect", Target = "Fragment_W1_L2", Count = 1},
			{Type = "Complete", Target = "World1_Level1", Count = 1},
		},
		Rewards = {
			Coins = 100,
			Experience = 50,
		},
		RequiredLevel = "World1_Level1", -- Optional prerequisite
	}
--]]

local QuestDefinitions = {}

-- ============================================================================
-- STORY QUESTS (World 1)
-- ============================================================================

QuestDefinitions.Story = {
	-- Main story quest line
	CollectFragments = {
		Id = "CollectFragments",
		Type = "Story",
		Name = "Gather the Ancient Fragments",
		Description = "Collect the three Ancient Fragments hidden throughout the Mystic Forest",
		Objectives = {
			{Type = "Collect", Target = "Fragment_W1_L2", Count = 1, Name = "Forest Fragment"},
			{Type = "Collect", Target = "Fragment_W1_L3", Count = 1, Name = "River Fragment"},
			{Type = "Collect", Target = "Fragment_W1_L4", Count = 1, Name = "Ruins Fragment"},
		},
		Rewards = {
			Coins = 300,
			Experience = 500,
		},
		GivenBy = "Guide",
		TurnInTo = "Guide",
	},

	-- Level-specific story quests
	TutorialComplete = {
		Id = "TutorialComplete",
		Type = "Story",
		Name = "First Steps",
		Description = "Complete the Tutorial Path",
		Objectives = {
			{Type = "Complete", Target = "World1_Level1", Count = 1},
		},
		Rewards = {
			Coins = 50,
			Experience = 100,
		},
		GivenBy = "Guide",
		AutoStart = true, -- Given automatically
	},

	ForestTrailQuest = {
		Id = "ForestTrailQuest",
		Type = "Story",
		Name = "Into the Forest",
		Description = "Navigate the Forest Trail and find the first fragment",
		Objectives = {
			{Type = "Complete", Target = "World1_Level2", Count = 1},
			{Type = "Collect", Target = "Fragment_W1_L2", Count = 1},
		},
		Rewards = {
			Coins = 75,
			Experience = 150,
		},
		RequiredLevel = "World1_Level1",
		GivenBy = "Guide",
	},

	RiverCrossingQuest = {
		Id = "RiverCrossingQuest",
		Type = "Story",
		Name = "Cross the Cursed River",
		Description = "Traverse the mystical river and recover the second fragment",
		Objectives = {
			{Type = "Complete", Target = "World1_Level3", Count = 1},
			{Type = "Collect", Target = "Fragment_W1_L3", Count = 1},
		},
		Rewards = {
			Coins = 100,
			Experience = 200,
		},
		RequiredLevel = "World1_Level2",
		GivenBy = "Guide",
	},

	RuinsQuest = {
		Id = "RuinsQuest",
		Type = "Story",
		Name = "Explore the Ancient Ruins",
		Description = "Venture into the treacherous ruins for the final fragment",
		Objectives = {
			{Type = "Complete", Target = "World1_Level4", Count = 1},
			{Type = "Collect", Target = "Fragment_W1_L4", Count = 1},
		},
		Rewards = {
			Coins = 125,
			Experience = 250,
		},
		RequiredLevel = "World1_Level3",
		GivenBy = "Guide",
	},

	GuardiansGateQuest = {
		Id = "GuardiansGateQuest",
		Type = "Story",
		Name = "Break the Curse",
		Description = "Face the ultimate challenge at the Guardian's Gate",
		Objectives = {
			{Type = "Complete", Target = "World1_Level5", Count = 1},
		},
		Rewards = {
			Coins = 200,
			Experience = 500,
			Title = "Forest Champion",
		},
		RequiredLevel = "World1_Level4",
		GivenBy = "Guide",
	},
}

-- ============================================================================
-- DAILY QUESTS
-- ============================================================================

QuestDefinitions.Daily = {
	-- Pool of daily quests (randomly selected)

	DailyCoins1 = {
		Id = "DailyCoins1",
		Type = "Daily",
		Name = "Coin Collector",
		Description = "Collect 50 coins",
		Objectives = {
			{Type = "CollectCoins", Target = "Any", Count = 50},
		},
		Rewards = {
			Coins = 100,
			Experience = 50,
		},
	},

	DailyComplete1 = {
		Id = "DailyComplete1",
		Type = "Daily",
		Name = "Daily Challenge",
		Description = "Complete any 3 levels",
		Objectives = {
			{Type = "CompleteAnyLevel", Target = "Any", Count = 3},
		},
		Rewards = {
			Coins = 150,
			Experience = 75,
		},
	},

	DailyNPC1 = {
		Id = "DailyNPC1",
		Type = "Daily",
		Name = "Social Butterfly",
		Description = "Talk to all 3 NPCs in the hub",
		Objectives = {
			{Type = "TalkToNPC", Target = "Guide", Count = 1},
			{Type = "TalkToNPC", Target = "Merchant", Count = 1},
			{Type = "TalkToNPC", Target = "Elder", Count = 1},
		},
		Rewards = {
			Coins = 75,
			Experience = 40,
		},
	},

	DailySpeed1 = {
		Id = "DailySpeed1",
		Type = "Daily",
		Name = "Speed Runner",
		Description = "Complete any level in under 2 minutes",
		Objectives = {
			{Type = "CompleteLevelFast", Target = "Any", Count = 1, TimeLimit = 120},
		},
		Rewards = {
			Coins = 200,
			Experience = 100,
		},
	},

	DailyPerfect1 = {
		Id = "DailyPerfect1",
		Type = "Daily",
		Name = "Flawless Victory",
		Description = "Complete a level without dying",
		Objectives = {
			{Type = "CompleteWithoutDeath", Target = "Any", Count = 1},
		},
		Rewards = {
			Coins = 150,
			Experience = 80,
		},
	},

	DailyCollector1 = {
		Id = "DailyCollector1",
		Type = "Daily",
		Name = "Treasure Hunter",
		Description = "Collect all coins in any single level",
		Objectives = {
			{Type = "CollectAllCoinsInLevel", Target = "Any", Count = 1},
		},
		Rewards = {
			Coins = 125,
			Experience = 60,
		},
	},
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function QuestDefinitions.GetQuest(questId)
	-- Search through all quest types
	for questType, quests in pairs(QuestDefinitions) do
		if type(quests) == "table" and quests[questId] then
			return quests[questId]
		end
	end
	return nil
end

function QuestDefinitions.GetQuestsByType(questType)
	return QuestDefinitions[questType] or {}
end

function QuestDefinitions.GetRandomDailyQuests(count)
	-- Get random daily quests for the day
	local dailyQuests = QuestDefinitions.Daily
	local questList = {}

	-- Collect all daily quest IDs
	for questId, quest in pairs(dailyQuests) do
		table.insert(questList, questId)
	end

	-- Shuffle and take first 'count'
	local selected = {}
	local random = Random.new()

	for i = 1, math.min(count, #questList) do
		local randomIndex = random:NextInteger(1, #questList - i + 1)
		table.insert(selected, dailyQuests[questList[randomIndex]])
		-- Remove selected quest from list
		table.remove(questList, randomIndex)
	end

	return selected
end

return QuestDefinitions
