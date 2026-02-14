# Tower Ascent - Premium Features Architecture (Weeks 25-36)

**Date:** January 28, 2026
**Phase:** Premium Features (Post-Launch Enhancement)
**Timeline:** Weeks 25-36 (12 weeks)
**Expected Revenue:** +$44K-109K/year
**Target:** Enhanced creator economy and competitive features

---

## EXECUTIVE SUMMARY

This document outlines the technical architecture for 6 premium features that will be implemented in Weeks 25-36, building upon the Standard Edition MVP (Weeks 1-24). These features target creator engagement, streamer partnerships, competitive play, and social systems to significantly enhance player retention and revenue.

### Features Overview:

1. **UGC Marketplace** - User-generated content trading platform (+$10K-30K/year)
2. **Streamer Creator Codes** - Attribution system for content creators (+$13K-52K/year)
3. **Live Events Calendar** - Seasonal and limited-time events (+$16K-20K/year)
4. **In-Game Section Creator** - Player-built tower sections (time savings, engagement)
5. **Ranked Competitive** - MMR-based competitive ladder (+$6K/year)
6. **Guild System** - Social guilds with progression (+$1.5K-2.5K/year)

**Total Revenue Projection:** $44K-109K/year additional revenue
**Implementation Priority:** Post-MVP launch (stable player base required)
**Technical Complexity:** High (requires robust infrastructure)

---

## 1. UGC MARKETPLACE

### 1.1 Overview

**Purpose:** Allow players to create, submit, and trade custom cosmetic items (trails, skins, emotes)
**Revenue Model:** 40% platform fee, 30% creator share, 30% DevEx/Roblox tax
**Target:** 5-10% of active players become creators

### 1.2 Technical Architecture

**Services Required:**
- `/src/ServerScriptService/Services/UGC/UGCMarketplaceService.lua`
- `/src/ServerScriptService/Services/UGC/UGCModerationService.lua`
- `/src/ServerScriptService/Services/UGC/UGCTransactionService.lua`
- `/src/ServerScriptService/Services/UGC/UGCCreatorService.lua`

**Data Models:**

```lua
-- UGC Item definition
UGCItemStore:
    Key: "Item_" .. ItemId
    Value: {
        Id = string,
        CreatorUserId = number,
        Type = "Trail" | "Skin" | "Emote" | "Title",
        Name = string,
        Description = string,
        Price = number, -- In Robux
        Status = "Pending" | "Approved" | "Rejected",
        CreatedAt = number,
        ApprovedAt = number?,
        Sales = number,
        Revenue = number,
        AssetIds = {
            Icon = rbxassetid,
            Model = rbxassetid?, -- For trails/skins
            Animation = rbxassetid?, -- For emotes
        },
    }

-- Player UGC data
PlayerData.UGCData = {
    CreatedItems = {ItemId, ...},
    PurchasedItems = {ItemId, ...},
    TotalRevenue = 0,
    TotalSales = 0,
}

-- UGC creator leaderboard
UGCCreatorLeaderboard:
    Key: CreatorUserId
    Value: TotalRevenue
```

**Marketplace Logic:**

```lua
function UGCMarketplaceService.SubmitItem(player, itemData)
    -- Validate item data
    if not UGCMarketplaceService.ValidateItem(itemData) then
        return false, "Invalid item data"
    end

    -- Text filtering
    local filteredName = TextService:FilterStringAsync(itemData.Name, player.UserId)
    local filteredDesc = TextService:FilterStringAsync(itemData.Description, player.UserId)

    -- Check asset ownership (prevent stolen assets)
    if not UGCMarketplaceService.VerifyAssetOwnership(player.UserId, itemData.AssetIds) then
        return false, "You don't own these assets"
    end

    -- Create item record
    local itemId = HttpService:GenerateGUID(false)
    local item = {
        Id = itemId,
        CreatorUserId = player.UserId,
        Type = itemData.Type,
        Name = filteredName:GetNonChatStringForBroadcastAsync(),
        Description = filteredDesc:GetNonChatStringForBroadcastAsync(),
        Price = itemData.Price,
        Status = "Pending",
        CreatedAt = os.time(),
        Sales = 0,
        Revenue = 0,
        AssetIds = itemData.AssetIds,
    }

    UGCItemStore:SetAsync("Item_" .. itemId, item)

    -- Queue for moderation
    UGCModerationService.QueueForReview(itemId)

    return true, itemId
end

function UGCTransactionService.PurchaseItem(player, itemId)
    local item = UGCItemStore:GetAsync("Item_" .. itemId)
    if not item or item.Status ~= "Approved" then
        return false, "Item not available"
    end

    -- Check if already purchased
    local profile = DataService.GetProfile(player)
    if table.find(profile.Data.UGCData.PurchasedItems, itemId) then
        return false, "You already own this item"
    end

    -- Prompt Robux purchase
    MarketplaceService:PromptProductPurchase(player, item.Price)

    -- On purchase success (handled in DevProductService):
    -- 1. Add to player's purchased items
    -- 2. Calculate revenue split (40% platform, 30% creator)
    -- 3. Update creator's total revenue
    -- 4. Increment item sales count
end

function UGCTransactionService.OnPurchaseSuccess(player, itemId, price)
    local item = UGCItemStore:GetAsync("Item_" .. itemId)

    -- Revenue split
    local platformShare = math.floor(price * 0.40)
    local creatorShare = math.floor(price * 0.30)
    local robloxTax = price - platformShare - creatorShare

    -- Update item stats
    item.Sales = item.Sales + 1
    item.Revenue = item.Revenue + price
    UGCItemStore:UpdateAsync("Item_" .. itemId, function() return item end)

    -- Update creator revenue
    local creatorProfile = DataService.GetProfileByUserId(item.CreatorUserId)
    if creatorProfile then
        creatorProfile.Data.UGCData.TotalRevenue = creatorProfile.Data.UGCData.TotalRevenue + creatorShare
        creatorProfile.Data.UGCData.TotalSales = creatorProfile.Data.UGCData.TotalSales + 1
    end

    -- Update player inventory
    local profile = DataService.GetProfile(player)
    table.insert(profile.Data.UGCData.PurchasedItems, itemId)

    -- Log transaction
    WebhookLogger.LogEvent("UGC_PURCHASE", {
        Buyer = player.UserId,
        Item = itemId,
        Price = price,
        Creator = item.CreatorUserId,
        PlatformShare = platformShare,
        CreatorShare = creatorShare,
    })
end
```

**Moderation:**

```lua
function UGCModerationService.QueueForReview(itemId)
    -- Automated checks
    local item = UGCItemStore:GetAsync("Item_" .. itemId)

    -- Check for inappropriate content (basic filter)
    if UGCModerationService.ContainsInappropriateContent(item) then
        item.Status = "Rejected"
        UGCItemStore:UpdateAsync("Item_" .. itemId, function() return item end)
        return
    end

    -- Auto-approve if creator has good history (50+ approved items)
    local creator = DataService.GetProfileByUserId(item.CreatorUserId)
    if creator and creator.Data.UGCData.TotalSales >= 50 then
        item.Status = "Approved"
        item.ApprovedAt = os.time()
        UGCItemStore:UpdateAsync("Item_" .. itemId, function() return item end)
        return
    end

    -- Otherwise, queue for manual review or community voting
    UGCModerationService.QueueForCommunityVoting(itemId)
end

function UGCModerationService.QueueForCommunityVoting(itemId)
    -- Implement community voting system
    -- Players with 1000+ stage completion can vote on UGC items
    -- 50+ upvotes = auto-approve
    -- 10+ downvotes = reject
end
```

**Security Measures:**
- Asset ownership verification (CreatorService API)
- Text filtering (TextService)
- Duplicate detection (perceptual hashing)
- Community moderation (voting system)
- Creator reputation tracking
- Rate limiting (5 submissions per day)

**UI Components:**
- `/src/StarterGui/UGCMarketplaceUI.lua` (browse, search, purchase)
- `/src/StarterGui/UGCCreatorStudioUI.lua` (submission, analytics)
- `/src/StarterGui/UGCInventoryUI.lua` (owned items, equip)

**Implementation Timeline:**
- Week 25: Data models + marketplace service
- Week 26: Transaction system + revenue tracking
- Week 27: Moderation system
- Week 28: Creator studio UI
- Week 29: Marketplace browse UI
- Week 30: Testing + polish

**Revenue Projection:**
- Conservative (500 items, 10% purchase rate): $800-1,200/month ($10K-15K/year)
- Realistic (2,000 items, 15% purchase rate): $2,000-2,500/month ($24K-30K/year)
- Platform cut (40%): $400-1,000/month

---

## 2. STREAMER CREATOR CODES

### 2.1 Overview

**Purpose:** Attribute revenue to content creators/streamers for player acquisition
**Revenue Model:** 5% of all player purchases attributed to the creator's code
**Target:** 50-100 active creator codes

### 2.2 Technical Architecture

**Services Required:**
- `/src/ServerScriptService/Services/Creators/CreatorCodeService.lua`
- `/src/ServerScriptService/Services/Creators/CreatorAttributionService.lua`
- `/src/ServerScriptService/Services/Creators/CreatorAnalyticsService.lua`

**Data Models:**

```lua
-- Creator code definition
CreatorCodeStore:
    Key: "Code_" .. CodeString
    Value: {
        Code = string, -- e.g., "STREAMER123"
        CreatorUserId = number,
        CreatorName = string,
        Active = boolean,
        CreatedAt = number,
        ExpiresAt = number?,
        TotalUses = number,
        TotalRevenue = number,
        AttributedPurchases = number,
    }

-- Player creator attribution
PlayerData.CreatorCode = {
    Code = string?,
    AttributedAt = number?,
    AttributionExpires = number?, -- 30 days from first use
}

-- Creator revenue tracking
CreatorRevenueStore:
    Key: "Creator_" .. UserId
    Value: {
        UserId = number,
        TotalRevenue = number,
        TotalAttributedPlayers = number,
        TotalAttributedPurchases = number,
        RevenueByMonth = {[Month] = Amount},
    }

-- Creator leaderboard
CreatorCodeLeaderboard:
    Key: CreatorUserId
    Value: TotalRevenue
```

**Attribution Logic:**

```lua
function CreatorCodeService.ApplyCode(player, code)
    -- Validate code
    local codeData = CreatorCodeStore:GetAsync("Code_" .. string.upper(code))
    if not codeData or not codeData.Active then
        return false, "Invalid or inactive code"
    end

    -- Check if player already has attribution
    local profile = DataService.GetProfile(player)
    if profile.Data.CreatorCode.Code then
        return false, "You already have a creator code applied"
    end

    -- Check if player account is new enough (prevent farming)
    if player.AccountAge < 7 then
        return false, "Account must be at least 7 days old"
    end

    -- Apply attribution
    profile.Data.CreatorCode = {
        Code = code,
        AttributedAt = os.time(),
        AttributionExpires = os.time() + (30 * 24 * 60 * 60), -- 30 days
    }

    -- Update code stats
    codeData.TotalUses = codeData.TotalUses + 1
    CreatorCodeStore:UpdateAsync("Code_" .. string.upper(code), function() return codeData end)

    -- Log event
    WebhookLogger.LogEvent("CREATOR_CODE_USED", {
        Player = player.UserId,
        Code = code,
        Creator = codeData.CreatorUserId,
    })

    return true, codeData.CreatorName
end

function CreatorAttributionService.OnPlayerPurchase(player, purchaseAmount)
    local profile = DataService.GetProfile(player)
    local creatorCode = profile.Data.CreatorCode

    -- Check if attribution is valid
    if not creatorCode or not creatorCode.Code then return end
    if os.time() > creatorCode.AttributionExpires then return end

    -- Calculate creator share (5%)
    local creatorShare = math.floor(purchaseAmount * 0.05)

    -- Update creator revenue
    local codeData = CreatorCodeStore:GetAsync("Code_" .. string.upper(creatorCode.Code))
    if codeData then
        codeData.TotalRevenue = codeData.TotalRevenue + creatorShare
        codeData.AttributedPurchases = codeData.AttributedPurchases + 1
        CreatorCodeStore:UpdateAsync("Code_" .. string.upper(creatorCode.Code), function() return codeData end)

        -- Update creator revenue store
        local creatorRevenue = CreatorRevenueStore:GetAsync("Creator_" .. codeData.CreatorUserId) or {
            UserId = codeData.CreatorUserId,
            TotalRevenue = 0,
            TotalAttributedPlayers = 0,
            TotalAttributedPurchases = 0,
            RevenueByMonth = {},
        }
        creatorRevenue.TotalRevenue = creatorRevenue.TotalRevenue + creatorShare
        creatorRevenue.TotalAttributedPurchases = creatorRevenue.TotalAttributedPurchases + 1
        CreatorRevenueStore:UpdateAsync("Creator_" .. codeData.CreatorUserId, function() return creatorRevenue end)

        -- Log event
        WebhookLogger.LogEvent("CREATOR_CODE_REVENUE", {
            Creator = codeData.CreatorUserId,
            Code = creatorCode.Code,
            Amount = creatorShare,
            PurchaseAmount = purchaseAmount,
        })
    end
end
```

**Creator Dashboard:**

```lua
function CreatorAnalyticsService.GetCreatorDashboard(player)
    local codes = CreatorCodeService.GetPlayerCodes(player.UserId)
    local analytics = {}

    for _, codeData in ipairs(codes) do
        table.insert(analytics, {
            Code = codeData.Code,
            TotalUses = codeData.TotalUses,
            TotalRevenue = codeData.TotalRevenue,
            AttributedPurchases = codeData.AttributedPurchases,
            RevenueThisMonth = CreatorAnalyticsService.GetMonthlyRevenue(codeData, os.date("%Y-%m")),
            Active = codeData.Active,
        })
    end

    return analytics
end
```

**Code Creation:**
- Manual approval process (contact developer via Discord)
- Requires: 100+ followers/subscribers, active content creation
- Code format: 4-12 characters, alphanumeric only
- Unique per creator
- Can be deactivated if Terms of Service violated

**Security:**
- Account age check (7+ days)
- One code per player (permanent)
- 30-day attribution window
- Rate limiting on code application
- Anti-fraud detection (flagging suspicious patterns)

**UI Components:**
- `/src/StarterGui/CreatorCodeInputUI.lua` (enter code on first play)
- `/src/StarterGui/CreatorDashboardUI.lua` (analytics for creators)

**Implementation Timeline:**
- Week 26: Creator code service + attribution
- Week 27: Analytics dashboard
- Week 28: UI for code input
- Week 29: Creator portal (dashboard, analytics)
- Week 30: Testing + anti-fraud

**Revenue Projection:**
- Conservative (50 codes, 500 attributed players each, 5% monetization): $1,100/month ($13K/year)
- Realistic (100 codes, 2,000 attributed players, 8% monetization): $4,300/month ($52K/year)
- Creator share (5%): $55-220/month per creator

---

## 3. LIVE EVENTS CALENDAR

### 3.1 Overview

**Purpose:** Seasonal events, limited-time challenges, themed competitions
**Revenue Model:** Event-exclusive cosmetics, Battle Pass XP boosts, limited-time passes
**Target:** 20-40% event participation rate

### 3.2 Technical Architecture

**Services Required:**
- `/src/ServerScriptService/Services/Events/EventSchedulerService.lua`
- `/src/ServerScriptService/Services/Events/EventInstanceService.lua`
- `/src/ServerScriptService/Services/Events/EventLeaderboardService.lua`
- `/src/ServerScriptService/Services/Events/EventRewardService.lua`

**Data Models:**

```lua
-- Event definition
EventDefinitionStore:
    Key: "Event_" .. EventId
    Value: {
        Id = string,
        Name = string,
        Description = string,
        Type = "TimedChallenge" | "Competition" | "Collection" | "Survival",
        StartTime = number,
        EndTime = number,
        Active = boolean,

        -- Event parameters
        Parameters = {
            TimeLimit = number?,
            TargetScore = number?,
            SpecialRules = {},
        },

        -- Rewards
        Rewards = {
            Top10 = {Coins, Cosmetics, Badges},
            Top100 = {Coins, Cosmetics},
            Participation = {Coins, XP},
        },

        -- Event-exclusive items
        ExclusiveItems = {ItemId, ...},
    }

-- Player event history
PlayerData.EventHistory = {
    [EventId] = {
        Participated = boolean,
        Score = number,
        Rank = number?,
        RewardsClaimed = boolean,
        CompletedAt = number?,
    }
}

-- Event leaderboard
EventLeaderboard_{EventId}:
    Key: "Player_" .. UserId
    Value: Score
```

**Event Types:**

1. **Timed Challenge:** Complete tower in fastest time
2. **Competition:** Most coins collected in event period
3. **Collection:** Find hidden collectibles across tower
4. **Survival:** Last as long as possible with special hazards

**Event Scheduler:**

```lua
function EventSchedulerService.ScheduleEvent(eventDefinition)
    -- Validate event
    if not EventSchedulerService.ValidateEvent(eventDefinition) then
        return false
    end

    -- Store event
    EventDefinitionStore:SetAsync("Event_" .. eventDefinition.Id, eventDefinition)

    -- Schedule start/end
    EventSchedulerService.ScheduleEventStart(eventDefinition.Id, eventDefinition.StartTime)
    EventSchedulerService.ScheduleEventEnd(eventDefinition.Id, eventDefinition.EndTime)

    return true
end

function EventSchedulerService.OnEventStart(eventId)
    local event = EventDefinitionStore:GetAsync("Event_" .. eventId)
    event.Active = true
    EventDefinitionStore:UpdateAsync("Event_" .. eventId, function() return event end)

    -- Create event tower instance
    EventInstanceService.CreateEventTower(eventId)

    -- Notify all players
    for _, player in ipairs(Players:GetPlayers()) do
        EventSchedulerService.NotifyEventStart(player, event)
    end

    -- Log event
    WebhookLogger.LogEvent("EVENT_START", {
        EventId = eventId,
        Name = event.Name,
        PlayerCount = #Players:GetPlayers(),
    })
end

function EventSchedulerService.OnEventEnd(eventId)
    local event = EventDefinitionStore:GetAsync("Event_" .. eventId)
    event.Active = false
    EventDefinitionStore:UpdateAsync("Event_" .. eventId, function() return event end)

    -- Finalize leaderboard
    EventLeaderboardService.FinalizeLeaderboard(eventId)

    -- Distribute rewards
    EventRewardService.DistributeRewards(eventId)

    -- Cleanup event tower
    EventInstanceService.DestroyEventTower(eventId)

    -- Log event
    WebhookLogger.LogEvent("EVENT_END", {
        EventId = eventId,
        Name = event.Name,
        Participants = EventLeaderboardService.GetParticipantCount(eventId),
    })
end
```

**Event Instance:**

```lua
function EventInstanceService.CreateEventTower(eventId)
    local event = EventDefinitionStore:GetAsync("Event_" .. eventId)

    -- Generate special tower for event
    local tower
    if event.Type == "TimedChallenge" then
        tower = Generator.GenerateTower({
            Seed = eventId,
            Sections = 30,
            Difficulty = "Expert",
            Theme = event.Parameters.Theme or "Volcano",
        })
    elseif event.Type == "Survival" then
        tower = Generator.GenerateSurvivalTower({
            Hazards = "All",
            Difficulty = "Extreme",
        })
    end

    -- Tag tower as event tower
    tower.Name = "EventTower_" .. eventId
    tower.Parent = workspace.Events

    return tower
end

function EventInstanceService.OnPlayerJoinEvent(player, eventId)
    local event = EventDefinitionStore:GetAsync("Event_" .. eventId)
    if not event or not event.Active then
        return false, "Event not active"
    end

    -- Teleport to event tower
    local tower = workspace.Events:FindFirstChild("EventTower_" .. eventId)
    if not tower then
        return false, "Event tower not found"
    end

    player.Character:MoveTo(tower.Start.Position)
    player:SetAttribute("CurrentEvent", eventId)
    player:SetAttribute("EventStartTime", tick())

    -- Track participation
    local profile = DataService.GetProfile(player)
    if not profile.Data.EventHistory[eventId] then
        profile.Data.EventHistory[eventId] = {
            Participated = true,
            Score = 0,
            CompletedAt = nil,
        }
    end

    return true
end

function EventInstanceService.OnPlayerCompleteEvent(player, eventId)
    local event = EventDefinitionStore:GetAsync("Event_" .. eventId)
    local eventTime = tick() - (player:GetAttribute("EventStartTime") or 0)

    -- Calculate score based on event type
    local score
    if event.Type == "TimedChallenge" then
        score = math.floor(10000 / eventTime) -- Lower time = higher score
    elseif event.Type == "Competition" then
        score = player.leaderstats.Coins.Value -- Most coins
    end

    -- Update player event data
    local profile = DataService.GetProfile(player)
    profile.Data.EventHistory[eventId].Score = score
    profile.Data.EventHistory[eventId].CompletedAt = os.time()

    -- Update leaderboard
    EventLeaderboardService.UpdateScore(eventId, player.UserId, score)

    -- Log completion
    WebhookLogger.LogEvent("EVENT_COMPLETE", {
        EventId = eventId,
        Player = player.UserId,
        Score = score,
        Time = eventTime,
    })
end
```

**Event Rewards:**

```lua
function EventRewardService.DistributeRewards(eventId)
    local event = EventDefinitionStore:GetAsync("Event_" .. eventId)
    local leaderboard = EventLeaderboardService.GetFinalLeaderboard(eventId)

    for i, entry in ipairs(leaderboard) do
        local player = Players:GetPlayerByUserId(entry.UserId)
        local rewards

        if i <= 10 then
            rewards = event.Rewards.Top10
        elseif i <= 100 then
            rewards = event.Rewards.Top100
        else
            rewards = event.Rewards.Participation
        end

        if player then
            EventRewardService.GiveRewards(player, rewards)
        else
            -- Store pending rewards
            EventRewardService.StorePendingRewards(entry.UserId, rewards)
        end
    end
end
```

**Security:**
- Server-authoritative timing
- Anti-cheat enabled for all events
- Score validation
- Rate limiting on event attempts

**UI Components:**
- `/src/StarterGui/EventCalendarUI.lua` (upcoming events, schedule)
- `/src/StarterGui/EventLeaderboardUI.lua` (live rankings)
- `/src/StarterGui/EventRewardsUI.lua` (rewards showcase)

**Implementation Timeline:**
- Week 27: Event scheduler + definitions
- Week 28: Event instance generation
- Week 29: Leaderboard system
- Week 30: Reward distribution
- Week 31: Event calendar UI
- Week 32: Testing + first event

**Revenue Projection:**
- Battle Pass XP boost during events: +20% BP sales
- Event-exclusive cosmetics: $500-800/event
- Monthly events (2-3): $1,300-2,100/month ($16K-25K/year)

---

## 4. IN-GAME SECTION CREATOR

### 4.1 Overview

**Purpose:** Allow players to design custom tower sections, submit for approval, earn rewards
**Revenue Model:** Indirect (engagement, retention, time savings for developer)
**Target:** 5-10% of players submit sections

### 4.2 Technical Architecture

**Services Required:**
- `/src/ServerScriptService/Services/SectionCreator/SectionBuilderService.lua`
- `/src/ServerScriptService/Services/SectionCreator/SectionValidationService.lua`
- `/src/ServerScriptService/Services/SectionCreator/SectionSubmissionService.lua`
- `/src/ServerScriptService/Services/SectionCreator/CommunityVotingService.lua`

**Data Models:**

```lua
-- Section submission
SectionSubmissionStore:
    Key: "Submission_" .. SubmissionId
    Value: {
        Id = string,
        CreatorUserId = number,
        Name = string,
        Difficulty = "Easy" | "Medium" | "Hard" | "Expert",
        SubmittedAt = number,
        Status = "Pending" | "Approved" | "Rejected",
        ApprovedAt = number?,

        -- Section data
        Parts = {
            {Type = "Part", Size = Vector3, Position = Vector3, Color = Color3},
            {Type = "TrussPart", ...},
            {Type = "WedgePart", ...},
        },

        -- Stats
        Votes = {Upvotes = 0, Downvotes = 0},
        PlayCount = 0,
        CompletionRate = 0,
    }

-- Approved sections
ApprovedSectionStore:
    Key: "Section_" .. SectionId
    Value: {...} -- Same structure as submission

-- Player creator stats
PlayerData.CreatorStats = {
    SubmittedSections = number,
    ApprovedSections = number,
    TotalVotes = number,
    TotalPlays = number,
}
```

**Section Builder:**

```lua
function SectionBuilderService.CreateBuilder(player)
    -- Create a sandboxed build area
    local buildArea = Instance.new("Folder")
    buildArea.Name = "BuildArea_" .. player.UserId
    buildArea.Parent = workspace.BuildAreas

    -- Spawn building tools
    local tools = {
        "PartTool",
        "TrussTool",
        "WedgeTool",
        "RotateTool",
        "DeleteTool",
    }

    for _, toolName in ipairs(tools) do
        local tool = SectionBuilderService.CreateTool(toolName, player)
        tool.Parent = player.Backpack
    end

    -- Set builder mode
    player:SetAttribute("BuilderMode", true)
    player.Character:MoveTo(buildArea.SpawnLocation.Position)

    return buildArea
end

function SectionBuilderService.OnPartPlaced(player, partData)
    -- Validate part
    if not SectionValidationService.ValidatePart(partData) then
        return false, "Invalid part"
    end

    -- Check part limit (100 parts per section)
    local buildArea = workspace.BuildAreas:FindFirstChild("BuildArea_" .. player.UserId)
    if #buildArea:GetChildren() >= 100 then
        return false, "Part limit reached (100)"
    end

    -- Create part
    local part = Instance.new(partData.Type)
    part.Size = partData.Size
    part.Position = partData.Position
    part.Color = partData.Color
    part.Anchored = true
    part.Parent = buildArea

    return true
end
```

**Section Validation:**

```lua
function SectionValidationService.ValidateSection(buildArea)
    local parts = buildArea:GetChildren()

    -- Check part count
    if #parts < 5 then
        return false, "Too few parts (minimum 5)"
    end
    if #parts > 100 then
        return false, "Too many parts (maximum 100)"
    end

    -- Check for banned parts
    for _, part in ipairs(parts) do
        if SectionValidationService.IsBannedPart(part) then
            return false, "Banned part type: " .. part.ClassName
        end
    end

    -- Check bounds
    local bounds = buildArea:GetExtentsSize()
    if bounds.X > 100 or bounds.Y > 50 or bounds.Z > 100 then
        return false, "Section too large"
    end

    -- Check for spawn and endpoint
    if not buildArea:FindFirstChild("Start") or not buildArea:FindFirstChild("End") then
        return false, "Missing Start or End marker"
    end

    -- Pathfinding test (ensure section is completable)
    if not SectionValidationService.TestPathfinding(buildArea) then
        return false, "Section not completable"
    end

    return true
end

function SectionValidationService.TestPathfinding(buildArea)
    -- Spawn test NPC
    local testNPC = SectionValidationService.CreateTestNPC()
    testNPC:MoveTo(buildArea.Start.Position)

    -- Attempt to reach End
    local pathfindingService = game:GetService("PathfindingService")
    local path = pathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
    })

    local success = pcall(function()
        path:ComputeAsync(buildArea.Start.Position, buildArea.End.Position)
    end)

    testNPC:Destroy()

    return success and path.Status == Enum.PathStatus.Success
end
```

**Section Submission:**

```lua
function SectionSubmissionService.SubmitSection(player, sectionData)
    -- Validate section
    local valid, error = SectionValidationService.ValidateSection(sectionData.BuildArea)
    if not valid then
        return false, error
    end

    -- Filter name
    local filteredName = TextService:FilterStringAsync(sectionData.Name, player.UserId)

    -- Serialize section data
    local parts = {}
    for _, part in ipairs(sectionData.BuildArea:GetChildren()) do
        table.insert(parts, {
            Type = part.ClassName,
            Size = {part.Size.X, part.Size.Y, part.Size.Z},
            Position = {part.Position.X, part.Position.Y, part.Position.Z},
            Rotation = {part.Rotation.X, part.Rotation.Y, part.Rotation.Z},
            Color = {part.Color.R, part.Color.G, part.Color.B},
        })
    end

    -- Create submission
    local submissionId = HttpService:GenerateGUID(false)
    local submission = {
        Id = submissionId,
        CreatorUserId = player.UserId,
        Name = filteredName:GetNonChatStringForBroadcastAsync(),
        Difficulty = sectionData.Difficulty,
        SubmittedAt = os.time(),
        Status = "Pending",
        Parts = parts,
        Votes = {Upvotes = 0, Downvotes = 0},
        PlayCount = 0,
        CompletionRate = 0,
    }

    SectionSubmissionStore:SetAsync("Submission_" .. submissionId, submission)

    -- Update player stats
    local profile = DataService.GetProfile(player)
    profile.Data.CreatorStats.SubmittedSections = profile.Data.CreatorStats.SubmittedSections + 1

    -- Queue for community voting
    CommunityVotingService.QueueForVoting(submissionId)

    return true, submissionId
end
```

**Community Voting:**

```lua
function CommunityVotingService.VoteOnSection(player, submissionId, vote)
    -- Validate player can vote (completed 100+ stages)
    local profile = DataService.GetProfile(player)
    if profile.Data.Stats.HighestStage < 100 then
        return false, "You must complete stage 100 to vote"
    end

    -- Update votes
    local submission = SectionSubmissionStore:GetAsync("Submission_" .. submissionId)
    if vote == "Upvote" then
        submission.Votes.Upvotes = submission.Votes.Upvotes + 1
    else
        submission.Votes.Downvotes = submission.Votes.Downvotes + 1
    end
    SectionSubmissionStore:UpdateAsync("Submission_" .. submissionId, function() return submission end)

    -- Auto-approve if 50+ upvotes
    if submission.Votes.Upvotes >= 50 then
        SectionSubmissionService.ApproveSection(submissionId)
    end

    -- Auto-reject if 10+ downvotes
    if submission.Votes.Downvotes >= 10 then
        SectionSubmissionService.RejectSection(submissionId)
    end
end
```

**Security:**
- Whitelist allowed part types (no scripts, no explosions)
- Part count limits (5-100 parts)
- Bounds checking (100x50x100 studs max)
- Pathfinding validation (section must be completable)
- Community moderation (voting system)
- Creator reputation tracking

**UI Components:**
- `/src/StarterGui/SectionBuilderUI.lua` (build tools, part selection)
- `/src/StarterGui/SectionGalleryUI.lua` (browse submissions, vote)
- `/src/StarterGui/CreatorStatsUI.lua` (creator analytics)

**Implementation Timeline:**
- Week 30: Section builder tools
- Week 31: Validation system
- Week 32: Submission + voting
- Week 33: Integration with Generator
- Week 34-36: UI + testing

**Value Proposition:**
- **For Players:** Creative expression, recognition, rewards
- **For Developer:** Saves ~15 hours/week creating sections
- **For Game:** Infinite content, community engagement

---

## 5. RANKED COMPETITIVE

### 5.1 Overview

**Purpose:** Competitive ladder with MMR-based matchmaking
**Revenue Model:** Ranked-exclusive cosmetics, seasonal rewards
**Target:** 15-25% of active players

### 5.2 Technical Architecture

**Services Required:**
- `/src/ServerScriptService/Services/Ranked/MMRCalculationService.lua`
- `/src/ServerScriptService/Services/Ranked/RankedMatchmakingService.lua`
- `/src/ServerScriptService/Services/Ranked/RankedSeasonService.lua`
- `/src/ServerScriptService/Services/Ranked/RankedRewardService.lua`

**Data Models:**

```lua
-- Player ranked data
PlayerData.Ranked = {
    MMR = 1000, -- Starting MMR (uses OpenSkill)
    Rank = "Bronze_III",
    Division = 3, -- 1 (I) to 5 (V)
    SeasonWins = 0,
    SeasonLosses = 0,
    SeasonMatches = 0,
    BestRank = "Bronze_III",
    PeakMMR = 1000,
    CurrentSeason = 1,
    SeasonRewardsClaimed = false,
    MatchHistory = {...}, -- Last 20 matches
}

-- Rank thresholds
RankThresholds = {
    {MMR = 0, Rank = "Bronze", Division = 5},
    {MMR = 200, Rank = "Bronze", Division = 4},
    {MMR = 400, Rank = "Bronze", Division = 3},
    {MMR = 600, Rank = "Bronze", Division = 2},
    {MMR = 800, Rank = "Bronze", Division = 1},
    {MMR = 1000, Rank = "Silver", Division = 5},
    {MMR = 1250, Rank = "Silver", Division = 4},
    {MMR = 1500, Rank = "Silver", Division = 3},
    {MMR = 1750, Rank = "Silver", Division = 2},
    {MMR = 2000, Rank = "Silver", Division = 1},
    {MMR = 2300, Rank = "Gold", Division = 5},
    {MMR = 2600, Rank = "Gold", Division = 4},
    {MMR = 2900, Rank = "Gold", Division = 3},
    {MMR = 3200, Rank = "Gold", Division = 2},
    {MMR = 3500, Rank = "Gold", Division = 1},
    {MMR = 3800, Rank = "Platinum", Division = 5},
    -- ... up to Grandmaster (4500+)
}
```

**MMR Calculation (OpenSkill):**

```lua
-- Install OpenSkill via Wally
-- wally.toml: openskill = "..."

local OpenSkill = require(ReplicatedStorage.Packages.OpenSkill)

function MMRCalculationService.CalculateMMRChange(player, matchResult)
    local currentMMR = player:GetAttribute("RankedMMR") or 1000
    local currentDeviation = player:GetAttribute("RankedDeviation") or 350

    -- Create rating object
    local rating = OpenSkill.Rating(currentMMR, currentDeviation)

    -- Update based on result
    local newRating
    if matchResult == "Win" then
        newRating = OpenSkill.rating(rating, {}, {{rating}})
    else
        newRating = OpenSkill.rating(rating, {{rating}}, {})
    end

    -- Calculate change
    local mmrChange = newRating.mu - currentMMR

    -- Update player
    player:SetAttribute("RankedMMR", newRating.mu)
    player:SetAttribute("RankedDeviation", newRating.sigma)

    return mmrChange, newRating.mu
end
```

**Matchmaking:**

```lua
function RankedMatchmakingService.FindMatch(player)
    local mmr = player:GetAttribute("RankedMMR") or 1000
    local bracket = MMRCalculationService.GetMMRBracket(mmr) -- e.g., "1000-1500"

    -- Join queue
    local queue = RankedQueueStore:GetAsync("Queue_" .. bracket) or {}
    table.insert(queue, {
        UserId = player.UserId,
        MMR = mmr,
        QueuedAt = tick(),
    })
    RankedQueueStore:UpdateAsync("Queue_" .. bracket, function() return queue end)

    -- Check if enough players for match (1v1 tower race or solo timed challenge)
    if #queue >= 2 then
        -- Match top 2 players
        local p1 = table.remove(queue, 1)
        local p2 = table.remove(queue, 1)
        RankedQueueStore:UpdateAsync("Queue_" .. bracket, function() return queue end)

        -- Create match
        RankedMatchmakingService.CreateMatch({p1, p2})
    end
end
```

**Season Management:**

```lua
function RankedSeasonService.StartNewSeason()
    local currentSeason = RankedSeasonService.GetCurrentSeason()
    local newSeasonNumber = currentSeason.SeasonNumber + 1

    -- End current season
    RankedSeasonService.EndSeason(currentSeason.SeasonNumber)

    -- Create new season
    local newSeason = {
        SeasonNumber = newSeasonNumber,
        Name = "Season " .. newSeasonNumber,
        StartDate = os.time(),
        EndDate = os.time() + (90 * 24 * 60 * 60), -- 90 days
        Active = true,
        TopPlayers = {},
    }
    SeasonStore:SetAsync("Season_" .. newSeasonNumber, newSeason)

    -- Reset all players' seasonal stats
    RankedSeasonService.ResetAllPlayerSeasonStats(newSeasonNumber)
end
```

**Security:**
- Server-authoritative timing
- Anti-cheat enabled for all ranked matches
- MMR recalculation on suspicious activity
- Match replay system
- Abandoned match penalties (-50 MMR, 30-minute cooldown)

**UI Components:**
- `/src/StarterGui/RankedLobbyUI.lua` (queue, rank display, leaderboard)
- `/src/StarterGui/RankedMatchUI.lua` (in-match overlay, opponent stats)
- `/src/StarterGui/RankedHistoryUI.lua` (match history, MMR graph)

**Implementation Timeline:**
- Week 27-28: MMR system + matchmaking
- Week 29: Match creation + results
- Week 30: Season management
- Week 31: Reward system
- Week 32: UI
- Week 33-36: Balance tuning

**Revenue Projection:**
- Ranked-exclusive cosmetics: $200-300/month
- Seasonal pass upgrades: $300-500/month
- Total: $500/month ($6K/year)

---

## 6. GUILD SYSTEM

### 6.1 Overview

**Purpose:** Social guilds with progression, contributions, guild wars
**Revenue Model:** Guild creation fee (1,000 Robux), guild perks purchases
**Target:** 30-50 active guilds, 15-25 members each

### 6.2 Technical Architecture

**Services Required:**
- `/src/ServerScriptService/Services/Guilds/GuildManagementService.lua`
- `/src/ServerScriptService/Services/Guilds/GuildLeaderboardService.lua`
- `/src/ServerScriptService/Services/Guilds/GuildChatService.lua`
- `/src/ServerScriptService/Services/Guilds/GuildWarsService.lua`

**Data Models:**

```lua
-- Guild data
GuildStore:
    Key: "Guild_" .. GuildId
    Value: {
        Id = string,
        Name = string,
        Tag = string, -- 2-4 character tag
        Description = string,
        FounderId = number,
        CreatedAt = number,

        -- Members
        Members = {
            [UserId] = {
                Role = "Leader" | "Officer" | "Member",
                JoinedAt = number,
                Contributions = number,
            }
        },

        -- Stats
        Stats = {
            TotalCompletions = 0,
            TotalCoins = 0,
            BestTime = math.huge,
            AverageMMR = 0,
            GuildLevel = 1,
            GuildXP = 0,
        },

        -- Settings
        Settings = {
            PublicJoin = false,
            RequiredLevel = 5,
            RequiredMMR = 0,
            MOTD = string,
        },

        -- Perks
        Perks = {
            CoinBonus = 0.05, -- 5% bonus
            XPBonus = 0.05,
            ExclusiveTowers = {},
            CustomCosmetics = {},
        },
    }

-- Player guild affiliation
PlayerData.Guild = {
    GuildId = string?,
    Role = string?,
    JoinedAt = number?,
    Contributions = number,
}
```

**Guild Creation:**

```lua
function GuildManagementService.CreateGuild(player, guildName, guildTag)
    -- Validate inputs
    if #guildName < 3 or #guildName > 30 then
        return false, "Guild name must be 3-30 characters"
    end

    -- Text filtering
    local filteredName = TextService:FilterStringAsync(guildName, player.UserId)
    local filteredTag = TextService:FilterStringAsync(guildTag, player.UserId)

    -- Check uniqueness
    if GuildManagementService.GuildNameExists(filteredName) then
        return false, "Guild name already taken"
    end

    -- Prompt Robux purchase (1,000 Robux guild creation fee)
    MarketplaceService:PromptProductPurchase(player, GUILD_CREATION_PRODUCT_ID)

    -- On purchase success, create guild
end
```

**Guild Contributions:**

```lua
function GuildManagementService.OnPlayerCompletion(player, coins, xp)
    local profile = DataService.GetProfile(player)
    local guildId = profile.Data.Guild.GuildId
    if not guildId then return end

    local guild = GuildStore:GetAsync("Guild_" .. guildId)
    if not guild then return end

    -- Update guild stats
    guild.Stats.TotalCompletions = guild.Stats.TotalCompletions + 1
    guild.Stats.TotalCoins = guild.Stats.TotalCoins + coins
    guild.Stats.GuildXP = guild.Stats.GuildXP + xp

    -- Update member contributions
    if guild.Members[player.UserId] then
        guild.Members[player.UserId].Contributions = guild.Members[player.UserId].Contributions + (coins + xp)
    end

    -- Check for guild level up
    GuildManagementService.CheckGuildLevelUp(guild)

    -- Apply guild coin bonus
    if guild.Perks.CoinBonus > 0 then
        local bonusCoins = math.floor(coins * guild.Perks.CoinBonus)
        DataService.AddCoins(player, bonusCoins, "GuildBonus")
    end

    GuildStore:UpdateAsync("Guild_" .. guildId, function() return guild end)
end
```

**Security:**
- Text filtering on all guild names, tags, MOTD
- Guild creation fee prevents spam (1,000 Robux)
- Role-based permissions
- Rate limiting on guild actions
- Guild dissolution requires unanimous officer vote

**UI Components:**
- `/src/StarterGui/GuildManagementUI.lua` (create, join, leave, settings)
- `/src/StarterGui/GuildRosterUI.lua` (member list, roles, contributions)
- `/src/StarterGui/GuildLeaderboardUI.lua` (guild rankings)
- `/src/StarterGui/GuildWarsUI.lua` (challenge, war stats)

**Implementation Timeline:**
- Week 28-29: GuildManagementService + data models
- Week 30: Guild joining/leaving
- Week 31: Guild contributions + leveling
- Week 32: Guild leaderboards
- Week 33: Guild wars
- Week 34-36: UI

**Revenue Projection:**
- Guild creation fees (30 guilds/month @ 1,000 Robux): $100-150/month
- Guild perk purchases: $50-100/month
- Total: $150-250/month ($1.8K-3K/year)

---

## IMPLEMENTATION DEPENDENCIES

**Week-by-Week Breakdown:**

| Week | Focus | Services | Dependencies |
|------|-------|----------|--------------|
| 25 | UGC Marketplace | UGCMarketplaceService, data models | DataService, SecureRemotes |
| 26 | UGC + Creator Codes | UGCCreatorService, CreatorCodeService | VIPService, BattlePassService |
| 27 | Events + Ranked | EventSchedulerService, MMRCalculationService | OpenSkill, SectionLoader |
| 28 | Events + Guilds | EventInstanceService, GuildManagementService | DataService |
| 29 | Ranked + Guilds | RankedMatchmakingService, GuildLeaderboardService | LeaderboardService |
| 30 | Section Creator | SectionBuilderService, ValidationService | SectionLoader |
| 31 | Section Creator | CommunityVotingService, SectionSubmissionService | UGCModerationService |
| 32 | Ranked Rewards | RankedRewardService, RankedSeasonService | BadgeService |
| 33 | Guild Wars | GuildWarsService, GuildChatService | GuildManagementService |
| 34-36 | Polish + UI | All UIs, testing, balancing | All services |

---

## DATABASE SCHEMA SUMMARY

**New DataStores Required:**

1. **UGCItemStore** - UGC marketplace items
2. **UGCCreatorLeaderboard** - Creator rankings
3. **CreatorCodeStore** - Streamer codes
4. **CreatorCodeLeaderboard** - Code performance
5. **EventDefinitionStore** - Event templates
6. **EventLeaderboard_{EventId}** - Per-event rankings
7. **SectionSubmissionStore** - Community sections (pending)
8. **ApprovedSectionStore** - Community sections (approved)
9. **RankedQueueStore** - Matchmaking queues
10. **RankedMatchStore** - Active matches
11. **SeasonStore** - Ranked seasons
12. **GuildStore** - Guild data
13. **GuildApplicationStore** - Join applications
14. **GuildLeaderboard** - Guild rankings
15. **GuildWarStore** - Active guild wars

**Player Data Extensions:**
- UGCData
- CreatorCode
- EventHistory
- CreatorStats
- Ranked
- Guild

---

## TESTING STRATEGY

**Unit Tests (Per Feature):**
- UGC validation, revenue split calculation
- Creator code attribution
- Event scheduling, leaderboard finalization
- Section validation, pathfinding tests
- MMR calculation, matchmaking
- Guild contribution tracking

**Integration Tests:**
- Full UGC flow: Create → Submit → Approve → Purchase
- Creator code flow: Apply → Purchase → Revenue tracking
- Event flow: Schedule → Start → Complete → Rewards
- Ranked flow: Queue → Match → Complete → MMR update
- Guild flow: Create → Join → Contribute → Level up

**Load Tests:**
- 100 concurrent UGC submissions
- 500 concurrent ranked queue joins
- 1000 concurrent event participants
- 50 guilds with 20 members each

---

## RISK ASSESSMENT

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **UGC moderation overwhelm** | High | High | Auto-approval after 50+ votes, community voting |
| **Creator code fraud** | Medium | High | One-time use, 7-day account age limit |
| **Ranked queue times too long** | High | Medium | MMR bracket widening after 60s wait |
| **Event server crashes** | Medium | High | Dedicated event servers, stress testing |
| **Section creator exploits** | High | Critical | Whitelist parts, validation, server-side testing |
| **Guild spam/griefing** | Medium | Medium | 1000 Robux creation fee, moderation tools |

---

## SUCCESS METRICS (KPIs)

**UGC Marketplace:**
- Creator submissions per day: 10-20
- Approval rate: 60-80%
- Purchase conversion: 5-10%
- Platform revenue: $800-2,500/month

**Creator Codes:**
- Active codes: 50-100
- Code usage rate: 10-20% of new players
- Revenue attributed: $1,000-4,000/month

**Live Events:**
- Participation rate: 20-40% of DAU
- Event completion rate: 30-50%
- Battle pass conversion boost: +20%
- Event revenue: $1,300-2,100/month

**Section Creator:**
- Submissions per day: 20-50
- Approval rate: 40-60%
- Creator engagement: 5-10% of playerbase
- Developer time saved: 15+ hours/week

**Ranked:**
- Ranked players: 15-25% of active base
- Average queue time: <60 seconds
- Seasonal completion rate: 70%
- Ranked revenue: $500/month

**Guilds:**
- Active guilds: 30-50
- Average guild size: 15-25 members
- Guild retention boost: +40% D30
- Guild revenue: $100-200/month

**Total Additional Revenue: $3,700-9,100/month = $44K-109K/year**

---

## CRITICAL FILES FOR IMPLEMENTATION

Based on comprehensive codebase analysis, these are the most critical files to work with:

1. **/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Services/DataService.lua**
   - Reason: Core data persistence - ALL premium features store data here. Must extend DEFAULT_DATA with UGCData, Ranked, Guild, etc.

2. **/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Services/Monetization/VIPService.lua**
   - Reason: Pattern reference for revenue tracking, purchase handling, and RemoteEvent structure.

3. **/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Services/Monetization/BattlePassService.lua**
   - Reason: Complex progression system reference - ranked MMR, event XP follow similar patterns.

4. **/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Security/SecureRemotes.lua**
   - Reason: ALL client-server communication must use SecureRemotes for validation, rate limiting, exploit prevention.

5. **/mnt/e/projects/roblox/tower-ascent-game/src/ServerScriptService/Utilities/WebhookLogger.lua**
   - Reason: Revenue tracking and analytics foundation - critical for monitoring UGC sales, creator code attribution.

---

**END OF PREMIUM FEATURES ARCHITECTURE**

This document provides a complete technical blueprint for implementing all 6 premium features across weeks 25-36, including detailed data models, service architectures, security considerations, UI requirements, testing strategies, and revenue projections totaling +$44K-109K/year in additional revenue.
