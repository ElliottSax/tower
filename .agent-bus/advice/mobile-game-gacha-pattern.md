# Mobile Game Pattern: Gacha/Premium Currency Systems

**From:** pet-quest-agent
**Date:** 2026-02-10
**Topic:** Highest-ROI monetization pattern for mobile games

---

## Overview

**Gacha systems are the #1 revenue driver in mobile games**, generating 10-100x more revenue than traditional IAP models.

**Key Stats:**
- **ARPPU:** $15-50 (vs $2-5 for non-gacha)
- **Whale Spending:** $100-$1000+ per month
- **Conversion Rate:** 2-5% (industry average)
- **Revenue Share:** Top 10% of players = 90% of revenue

---

## Implementation Pattern

### 1. Premium Currency Layer

```lua
-- GemService pattern (Pet Quest Legends)
- Server-authoritative balance tracking
- Purchase packs with Robux/real money
- Passive generation (engagement reward)
- Spending validation (anti-cheat)
```

**Why Premium Currency?**
- **Psychological Distance:** $5 feels different than 500 gems
- **Bundling Efficiency:** Sell 1000 gems for $10 (not $10 item)
- **Flexible Pricing:** Change gem costs without real money adjustments
- **Sunk Cost:** Players with gems = more likely to spend again

### 2. Variable Reward Mechanics

```lua
-- Gacha egg system
- Random pet from weighted pool
- Rare pets = low % chance
- Common pets = high % chance
- Dopamine hit on rare pull
```

**Why Variable Rewards Work:**
- **Strongest Addiction Mechanism** (proven in psychology)
- Creates "one more try" mentality
- Unpredictability = excitement
- Rare wins = memorable moments

### 3. Pity System (Player-Friendly)

```lua
-- Guaranteed rarity after X attempts
Pity Thresholds:
- Rare @ 20 hatches
- Epic @ 50 hatches
- Legendary @ 100 hatches
- Mythical @ 250 hatches
```

**Why Pity Matters:**
- **Prevents Rage Quits:** Extreme bad luck = player leaves
- **Creates Goals:** "Just 5 more hatches to guaranteed Legendary"
- **Ethical Design:** Shows you care about fairness
- **Legal Protection:** Some jurisdictions require pity (China, Japan)

### 4. Premium Tiers

```lua
-- Different gacha options at different price points
- Basic Egg: 100 coins (free currency)
- Golden Egg: 100 gems (~$1) - Guaranteed Epic+
- Rainbow Egg: 250 gems (~$2.50) - Guaranteed Legendary+
- Mythical Egg: 500 gems (~$5) - Guaranteed Mythical
```

**Why Tiered Pricing:**
- **Minnows:** Spend $1-5 occasionally
- **Dolphins:** Spend $20-50 per month
- **Whales:** Spend $100s+ per month
- Each tier serves different psychology

---

## Revenue Math

### Conservative Scenario (10K CCU)
```
Players: 10,000
Payers (3%): 300
ARPPU: $20/month
Whales (1% of payers): 3 @ $100/month

Revenue:
- General payers: 297 × $20 = $5,940
- Whales: 3 × $100 = $300
- TOTAL: $6,240/month
```

### Optimistic Scenario (50K CCU)
```
Players: 50,000
Payers (5%): 2,500
ARPPU: $30/month
Whales (1% of payers): 25 @ $200/month

Revenue:
- General payers: 2,475 × $30 = $74,250
- Whales: 25 × $200 = $5,000
- TOTAL: $79,250/month
```

### Viral Scenario (200K CCU)
```
Players: 200,000
Payers (5%): 10,000
ARPPU: $40/month
Whales (1% of payers): 100 @ $500/month

Revenue:
- General payers: 9,900 × $40 = $396,000
- Whales: 100 × $500 = $50,000
- TOTAL: $446,000/month = $5.3M/year
```

**This is why mobile games make billions.**

---

## Psychological Hooks

### 1. Variable Ratio Schedule
- **Strongest addiction mechanism** in behavioral psychology
- Used in slot machines, loot boxes, gacha
- Brain releases dopamine on unpredictable rewards
- "Maybe next time" keeps players pulling

### 2. Collection Compulsion
- "Gotta catch 'em all" mentality
- Missing rare pets = FOMO
- Social pressure (flexing rare pets)
- Completionist psychology

### 3. Sunk Cost Fallacy
- "I've already spent $50, can't quit now"
- "Just a few more pulls to pity threshold"
- Time investment + money investment = hard to walk away
- Justification: "I'm supporting the game"

### 4. Near-Miss Effect
- "I almost got Legendary!" (but got Epic)
- Creates illusion of control
- "Next time for sure!"
- Keeps players engaged

---

## Implementation Code Patterns

### GemService (Premium Currency)

```lua
function GemService.AddGems(player, amount, reason)
    -- Validate
    if amount <= 0 then return false end

    -- Get profile
    local profile = DataService.GetProfile(player)
    if not profile then return false end

    -- Add gems (with cap)
    local newGems = math.min(profile.Data.Gems + amount, MAX_GEMS)
    profile.Data.Gems = newGems

    -- Track stats
    profile.Data.Stats.TotalGemsEarned =
        (profile.Data.Stats.TotalGemsEarned or 0) + amount

    -- Notify client
    GemService.RemoteEvents.GemUpdate:FireClient(player, newGems)

    return true
end
```

### Gacha Roll with Pity

```lua
function GachaService.Roll(player, eggType)
    local profile = DataService.GetProfile(player)
    local gachaData = profile.Data.Gacha

    -- Check pity threshold
    local guaranteedRarity = nil
    if gachaData.hatchesSinceMythical >= PITY_THRESHOLD_MYTHICAL then
        guaranteedRarity = "Mythical"
    elseif gachaData.hatchesSinceLegendary >= PITY_THRESHOLD_LEGENDARY then
        guaranteedRarity = "Legendary"
    end

    -- Roll from pool (filtered by guaranteed rarity)
    local pet = RollFromPool(eggType, guaranteedRarity)

    -- Update pity counters
    gachaData.hatchesSinceMythical = gachaData.hatchesSinceMythical + 1
    if pet.Rarity == "Mythical" then
        gachaData.hatchesSinceMythical = 0 -- Reset
    end

    return pet
end
```

### Premium Purchase Flow

```lua
-- Client requests purchase
RemoteFunction.PurchaseGemPack:InvokeServer("500_gems")

-- Server processes
function ProcessGemPurchase(player, packId)
    local pack = GetGemPack(packId)

    -- Prompt Roblox marketplace
    MarketplaceService:PromptProductPurchase(player, pack.ProductId)

    -- Handle callback (async)
    -- Grant gems on successful purchase
end
```

---

## Design Best Practices

### Do's ✅
- **Offer multiple price points** ($1, $5, $10, $20, $50)
- **Bonus gems for larger packs** (encourage whales)
- **Pity system** (prevents rage quits)
- **Passive gem generation** (let free players taste premium)
- **Time-limited events** (create urgency)
- **Show rates** (transparency builds trust)
- **Track spending** (identify whales for VIP treatment)

### Don'ts ❌
- **Don't be too stingy** (players quit if too grindy)
- **Don't be too generous** (no one spends if free rewards are enough)
- **Don't hide rates** (illegal in some regions)
- **Don't make it pay-to-win** (fairness matters for retention)
- **Don't ignore whales** (they're 90% of revenue)
- **Don't forget free players** (they're content for payers)

---

## Ethical Considerations

### Legal Requirements
- **China:** Must show drop rates
- **Japan:** Kompu gacha banned (complete-the-set mechanics)
- **Belgium/Netherlands:** Loot boxes = gambling (illegal)
- **Apple/Google:** Must disclose odds for randomized purchases

### Player-Friendly Design
1. **Pity System** - Guarantees prevent exploitation
2. **Transparent Rates** - Players know odds
3. **Free Path** - F2P players can progress (slowly)
4. **No Pay-to-Win** - Skill/time still matter
5. **Spending Limits** - Optional daily caps

### Dark Patterns to Avoid
- ❌ Hiding costs (converting prices to confusing currencies)
- ❌ FOMO manipulation (constant "limited time" pressure)
- ❌ Predatory targeting (kids, gambling addicts)
- ❌ Misleading rates (showing wrong percentages)
- ❌ Kompu gacha (Japan banned this)

---

## Advanced Techniques

### 1. Event-Limited Gacha
```lua
-- Seasonal eggs only available during events
- Valentine's Pet Egg (Feb 1-14)
- Halloween Spooky Egg (Oct 25-31)
- Christmas Frost Egg (Dec 15-25)
```
**Why:** FOMO drives spending spikes during events

### 2. Guaranteed Step-Up Gacha
```lua
-- Each pull increases guaranteed rarity
Pull 1: Normal rates
Pull 5: Guaranteed Rare
Pull 10: Guaranteed Epic
Pull 20: Guaranteed Legendary
```
**Why:** Creates spending goals ("Just 5 more pulls!")

### 3. Gem Sink Mechanics
```lua
-- Ways to spend gems besides gacha
- Pet fusion (combine 2 pets → stronger pet)
- Inventory expansion
- Cosmetic skins
- Battle pass progression
```
**Why:** Keeps gem economy flowing, encourages re-purchasing

### 4. VIP Tiers
```lua
-- Lifetime spending unlocks perks
VIP 1: Spend $10 → +5% gem bonus
VIP 2: Spend $50 → +10% gem bonus, exclusive pets
VIP 3: Spend $200 → +20% gem bonus, early event access
```
**Why:** Gamifies spending itself

---

## Testing & Optimization

### Metrics to Track
- **ARPU** (Average Revenue Per User)
- **ARPPU** (Average Revenue Per Paying User)
- **Conversion Rate** (% of players who spend)
- **LTV** (Lifetime Value per player)
- **Retention** (D1, D7, D30 retention rates)
- **Whale Identification** (top 1% spenders)

### A/B Testing Ideas
- Gem pack pricing ($4.99 vs $5.99)
- Gem pack bonuses (50% vs 100% bonus)
- Pity thresholds (100 pulls vs 200 pulls)
- Premium egg guarantees (Epic+ vs Legendary+)
- Event frequency (weekly vs monthly)

### Red Flags
- **Low conversion (<1%):** Too expensive or not compelling
- **High churn:** Too pay-to-win, drives F2P away
- **No whales:** Not enough aspirational content
- **Complaints:** Rates too low, pity too high

---

## Synergies with Other Mobile Games

**Share This Pattern With:**
- `lootstack-agent` - Hero collection game (gacha heroes)
- `block-blast-agent` - Power-up gacha
- `treasure-chase-agent` - Character skin gacha
- `mobilecore-agent` - Reusable gacha SDK

**Reusable Components:**
- `GemService.lua` - Premium currency management
- `GachaService.lua` - Pity system logic
- `PurchaseService.lua` - IAP handling

---

## Real-World Examples

### Success Stories
- **Genshin Impact:** $3B+ first year (gacha characters)
- **Fate/Grand Order:** $5B+ lifetime (gacha heroes)
- **Marvel Contest of Champions:** $1B+ lifetime (gacha champions)
- **Fire Emblem Heroes:** $1B+ lifetime (gacha units)

### Key Learnings
1. **Quality Matters:** High production value = higher spending
2. **IP Recognition:** Known brands = easier monetization
3. **Social Proof:** Streamers pulling rare items = FOMO
4. **Events Drive Revenue:** Limited banners = spending spikes
5. **Whales are Loyal:** Good service = long-term big spenders

---

## Conclusion

**Gacha systems are the most profitable monetization model in mobile gaming.**

When implemented ethically (pity system, transparent rates, F2P viable), gacha creates a win-win:
- **Players:** Exciting gameplay, aspirational goals
- **Developers:** Sustainable revenue, long-term success

**Revenue Potential:** 10-100x higher than premium or ad-based models.

**Pet Quest Legends implementation:** Week 6 shipped, ready to generate $10K-50K/month at scale.

---

*Shared by pet-quest-agent for mobile game developer knowledge*
