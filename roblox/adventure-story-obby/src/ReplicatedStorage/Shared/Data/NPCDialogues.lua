--[[
	NPCDialogues.lua
	Dialogue trees for all NPCs

	Format:
	{
		DialogueId = {
			Text = "Dialogue text",
			Choices = {
				{Text = "Choice text", NextId = "NextDialogueId"},
				{Text = "Another choice", NextId = "AnotherDialogueId"},
			},
			OnComplete = function(player) -- Optional callback
		}
	}
--]]

local NPCDialogues = {}

-- ============================================================================
-- GUIDE (Elder Moss) - Main quest giver
-- ============================================================================

NPCDialogues.Guide = {
	-- First meeting
	Welcome = {
		Text = "Greetings, traveler. I am Elder Moss, guardian of this forest. It seems you've arrived at a troubled time...",
		Choices = {
			{Text = "What's happening here?", NextId = "ExplainCurse"},
			{Text = "I'm ready to help!", NextId = "Eager"},
		}
	},

	ExplainCurse = {
		Text = "An ancient curse has sealed the portals to other realms. Dark energy corrupts the forest, and only the bravest souls can navigate its challenges.",
		Choices = {
			{Text = "How can I help?", NextId = "HowToHelp"},
			{Text = "That sounds dangerous...", NextId = "Dangerous"},
		}
	},

	Dangerous = {
		Text = "Indeed it is. But I sense great courage within you. The forest needs heroes like you.",
		Choices = {
			{Text = "Tell me what to do.", NextId = "HowToHelp"},
		}
	},

	Eager = {
		Text = "Such enthusiasm! The forest could use more souls like yours. Let me explain what needs to be done.",
		Choices = {
			{Text = "I'm listening.", NextId = "HowToHelp"},
		}
	},

	HowToHelp = {
		Text = "Throughout the forest, there are Ancient Fragments scattered across five treacherous paths. Collect these fragments, and we may be able to break the curse.",
		Choices = {
			{Text = "I'll find them!", NextId = "StartQuest"},
			{Text = "What are these fragments?", NextId = "AboutFragments"},
		}
	},

	AboutFragments = {
		Text = "Long ago, a powerful artifact was shattered. Its pieces hold immense magical energy. Three fragments lie hidden in the forest, waiting to be discovered.",
		Choices = {
			{Text = "I'll retrieve them.", NextId = "StartQuest"},
		}
	},

	StartQuest = {
		Text = "Excellent! Begin with the Tutorial Path to familiarize yourself with the challenges ahead. The fragments await in the deeper parts of the forest. May the ancient spirits guide your steps.",
		Choices = {
			{Text = "I won't let you down!", NextId = "QuestActive"},
		},
		OnComplete = function(player)
			-- Quest started by QuestService
			return "CollectFragments"
		end
	},

	QuestActive = {
		Text = "The path ahead is dangerous, but I have faith in you. Return when you've collected the fragments.",
		Choices = {
			{Text = "I'll be back soon.", NextId = nil}, -- nil = close dialogue
		}
	},

	-- After completing quest
	QuestComplete = {
		Text = "You've done it! The fragments you've gathered pulse with ancient power. The first step toward breaking the curse is complete.",
		Choices = {
			{Text = "What happens now?", NextId = "NextSteps"},
		},
		OnComplete = function(player)
			return "FragmentsDelivered"
		end
	},

	NextSteps = {
		Text = "There is much more to be done, brave one. But for now, rest and prepare. Greater challenges lie ahead in realms beyond this forest.",
		Choices = {
			{Text = "I'm ready for anything.", NextId = "Farewell"},
		}
	},

	Farewell = {
		Text = "Your courage honors the forest. Return anytime you need guidance.",
		Choices = {
			{Text = "Thank you, Elder Moss.", NextId = nil},
		}
	},

	-- Repeat dialogue
	Repeat = {
		Text = "Welcome back, friend. How can I assist you today?",
		Choices = {
			{Text = "Tell me about the forest.", NextId = "AboutForest"},
			{Text = "Just passing by.", NextId = nil},
		}
	},

	AboutForest = {
		Text = "The Mystic Forest has stood for millennia, guarded by ancient spirits. Though cursed now, it remains a place of wonder and mystery.",
		Choices = {
			{Text = "Interesting. Thank you.", NextId = nil},
		}
	},
}

-- ============================================================================
-- MERCHANT (Trader Tom) - Shop keeper
-- ============================================================================

NPCDialogues.Merchant = {
	Welcome = {
		Text = "Well, well! A new face! Welcome to Trader Tom's Traveling Shop. Best deals in all the realms!",
		Choices = {
			{Text = "What do you sell?", NextId = "WhatSell"},
			{Text = "Just browsing.", NextId = "Browsing"},
		}
	},

	WhatSell = {
		Text = "I've got power-ups, cosmetics, and rare items! Coins are the currency of choice. Complete levels and quests to earn more!",
		Choices = {
			{Text = "I'll take a look. [Open Shop]", NextId = nil},
			{Text = "Maybe later.", NextId = "Browsing"},
		},
		OnComplete = function(player)
			return "OpenShop"
		end
	},

	Browsing = {
		Text = "Take your time! My wares aren't going anywhere. Come back when you're ready to make a purchase!",
		Choices = {
			{Text = "Will do!", NextId = nil},
		}
	},

	Repeat = {
		Text = "Back for more? Trader Tom's got exactly what you need!",
		Choices = {
			{Text = "Show me your wares. [Open Shop]", NextId = nil},
			{Text = "Not right now.", NextId = nil},
		},
		OnComplete = function(player)
			return "OpenShop"
		end
	},

	AfterPurchase = {
		Text = "Pleasure doing business! That'll serve you well on your journey!",
		Choices = {
			{Text = "Thanks!", NextId = nil},
		}
	},
}

-- ============================================================================
-- ELDER (Ancient One) - Lore keeper
-- ============================================================================

NPCDialogues.Elder = {
	Welcome = {
		Text = "...*The ancient figure slowly turns toward you*... Ah, a seeker of knowledge. What brings you to the Ancient One?",
		Choices = {
			{Text = "Who are you?", NextId = "WhoAreYou"},
			{Text = "Tell me about this place.", NextId = "AboutPlace"},
		}
	},

	WhoAreYou = {
		Text = "I am the keeper of memories, the chronicler of ages past. I have witnessed the rise and fall of countless heroes.",
		Choices = {
			{Text = "Tell me a story.", NextId = "Story1"},
			{Text = "That's impressive.", NextId = "Impressive"},
		}
	},

	AboutPlace = {
		Text = "This realm exists between worlds, a nexus of ancient power. The curse you see is but a ripple in the fabric of time itself.",
		Choices = {
			{Text = "How do I stop it?", NextId = "StopCurse"},
			{Text = "Fascinating.", NextId = "Impressive"},
		}
	},

	StopCurse = {
		Text = "The path forward requires courage, wisdom, and persistence. Complete the trials, gather the fragments, and the truth shall reveal itself.",
		Choices = {
			{Text = "I will succeed.", NextId = "Farewell"},
		}
	},

	Impressive = {
		Text = "The flow of time brings all things to light. Continue your journey, young seeker.",
		Choices = {
			{Text = "Thank you for your wisdom.", NextId = nil},
		}
	},

	Story1 = {
		Text = "Long ago, a hero much like yourself entered these woods. They faced impossible odds, yet through determination, they prevailed. Perhaps you share their destiny.",
		Choices = {
			{Text = "I hope to be as brave.", NextId = "Farewell"},
		}
	},

	Farewell = {
		Text = "May the ancient spirits watch over you, traveler.",
		Choices = {
			{Text = "Farewell, Ancient One.", NextId = nil},
		}
	},

	Repeat = {
		Text = "You return. What wisdom do you seek today?",
		Choices = {
			{Text = "Tell me about the ancient times.", NextId = "Story1"},
			{Text = "Just visiting.", NextId = nil},
		}
	},
}

return NPCDialogues
