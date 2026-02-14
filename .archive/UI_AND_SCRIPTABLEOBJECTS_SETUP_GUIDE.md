# 🎨 UI & ScriptableObjects Setup Guide

**Created:** 2026-01-26
**Status:** ✅ COMPLETE
**New Files:** 7 scripts (~3,200 lines)

---

## 📦 What Was Created

### **Treasure Chase UI** (3 scripts, ~1,500 lines)
1. **EndlessHUD.cs** - In-game HUD (score, distance, multiplier, coins)
2. **GameOverUI.cs** - Results screen with stats and rewards
3. **WorldThemeTemplate.cs** - ScriptableObject for creating themes

### **Block Blast Evolved UI** (3 scripts, ~1,700 lines)
1. **BlockBlastHUD.cs** - In-game HUD (score, moves, hero, combos)
2. **HeroCollectionUI.cs** - Hero management screen
3. **HeroTemplate.cs** - ScriptableObject for creating heroes

---

## 🚀 SETUP GUIDE: Treasure Chase

### **Step 1: Copy Scripts to Unity**

1. Open your Unity project (Treasure Chase)
2. Copy these scripts to your project:
   ```
   Assets/
   ├── Scripts/
   │   ├── UI/
   │   │   ├── EndlessHUD.cs
   │   │   └── GameOverUI.cs
   │   └── ScriptableObjects/
   │       └── WorldThemeTemplate.cs
   ```

3. Wait for Unity to compile (check bottom-right progress bar)

### **Step 2: Create EndlessHUD UI**

#### A. Create Canvas
1. Right-click in Hierarchy
2. Create → UI → Canvas
3. Rename to "GameplayCanvas"
4. Set Canvas Scaler:
   - UI Scale Mode: **Scale With Screen Size**
   - Reference Resolution: **1920 x 1080**
   - Match: **0.5** (balance width/height)

#### B. Create HUD Elements
```
GameplayCanvas/
├── ScorePanel (Top Center)
│   ├── ScoreText (TextMeshProUGUI) - "0"
│   └── HighScoreText - "Best: 0"
├── DistancePanel (Top Left)
│   └── DistanceText - "0m"
├── MultiplierPanel (Top Right)
│   ├── MultiplierText - "x1.0"
│   └── MultiplierGlow (Image)
├── CoinsPanel (Bottom Right)
│   ├── CoinIcon (Image)
│   └── CoinsText - "0"
├── PowerUpPanel (Bottom Left)
│   ├── PowerUpIcon (Image)
│   ├── PowerUpDurationBar (Image - Fill)
│   └── PowerUpDurationText - "0s"
└── ComboPanel (Center)
    └── ComboText - "Combo x0!"
```

#### C. Assign Components to EndlessHUD Script
1. Create empty GameObject in scene: "EndlessHUDManager"
2. Add Component → **EndlessHUD** script
3. Drag UI elements to inspector fields:
   - Score Text → ScoreText
   - High Score Text → HighScoreText
   - Distance Text → DistanceText
   - Multiplier Text → MultiplierText
   - Coins Text → CoinsText
   - Combo Text → ComboText
   - (etc. for all fields)

#### D. Configure Settings
- Score Count Speed: **100** (smooth counting)
- Flash Duration: **0.3** seconds
- Low Moves Threshold: **3** moves

✅ **Test:** Press Play - HUD should show 0 for all values

### **Step 3: Create GameOverUI**

#### A. Create Game Over Panel
```
GameplayCanvas/
├── GameOverPanel (Full Screen, initially disabled)
    ├── BackgroundDim (Image - Black, Alpha 0.8)
    ├── ResultsPanel (Center)
    │   ├── TitleText - "Game Over"
    │   ├── FinalScoreText - "0"
    │   ├── HighScoreText - "Best: 0"
    │   ├── ScoreDifferenceText - "+0"
    │   ├── StatsPanel
    │   │   ├── DistanceText - "0m"
    │   │   ├── CoinsCollectedText - "0"
    │   │   ├── TreasuresCollectedText - "0"
    │   │   └── MaxMultiplierText - "x1.0"
    │   └── ButtonsPanel
    │       ├── RetryButton - "Retry"
    │       ├── MainMenuButton - "Main Menu"
    │       ├── WatchAdButton - "Watch Ad for 2x Coins"
    │       └── ShareButton - "Share"
    ├── NewRecordPanel (Hidden by default)
    │   └── NewRecordText - "NEW RECORD!"
    └── TournamentPanel (Hidden by default)
        └── TournamentRankText - "Rank: #0"
```

#### B. Assign Components
1. Create empty GameObject: "GameOverUIManager"
2. Add Component → **GameOverUI** script
3. Assign all panel references
4. **Important:** Set GameOverPanel.SetActive(false) in inspector

✅ **Test:** Call `GameOverUI.Instance.Show()` from code

### **Step 4: Create WorldTheme ScriptableObjects**

#### A. Create First Theme (Desert)
1. Right-click in Project window: Assets/ScriptableObjects/Themes/
2. Create → TreasureChase → World Theme
3. Rename to "Theme_Desert"
4. Configure in Inspector:

```
Theme Identity:
- Theme Name: "Desert"
- Description: "A scorching desert with ancient ruins"
- Unlock Distance: 0 (available from start)

Visual Settings:
- Terrain Material: (Assign sandy material)
- Skybox Material: (Assign desert skybox)
- Ambient Color: RGB(255, 242, 204) - Warm yellow
- Fog Color: RGB(204, 178, 128) - Sandy
- Fog Density: 0.015

Lighting:
- Sun Color: RGB(255, 242, 204)
- Sun Intensity: 1.2
- Sun Rotation: (50, -30, 0)

Audio:
- Music Track: "desert_theme"
- Ambient Sound Loop: "desert_wind"
- Music Volume: 0.7
- Ambient Volume: 0.3

Game Objects:
- Theme Obstacles: [Drag cactus, boulder, scorpion prefabs]
- Theme Treasures: [Drag treasure prefabs]
- Theme Decorations: [Drag sand dunes, palm trees]
- Ambient Particles: (Assign sand particle prefab)

Difficulty Modifiers:
- Speed Multiplier: 1.0 (normal)
- Visibility Modifier: 0.9 (slight sandstorm)
- Obstacle Spawn Multiplier: 1.0
```

#### B. Create More Themes
Repeat for other themes:
- **Theme_Jungle** (unlocks at 1000m)
- **Theme_Snow** (unlocks at 2000m)
- **Theme_Lava** (unlocks at 3000m)
- **Theme_City** (unlocks at 4000m)
- **Theme_Space** (unlocks at 5000m)

See WorldThemeTemplate.cs bottom comments for detailed configs.

#### C. Assign to WorldManager
1. Find WorldManager in scene
2. Inspector → World Themes → Size: **6**
3. Drag all theme ScriptableObjects into array

✅ **Test:** Run game, themes should switch every 1000m

---

## 🎮 SETUP GUIDE: Block Blast Evolved

### **Step 1: Copy Scripts to Unity**

1. Open your Unity project (Block Blast Evolved)
2. Copy these scripts:
   ```
   Assets/
   ├── Scripts/
   │   ├── UI/
   │   │   ├── BlockBlastHUD.cs
   │   │   └── HeroCollectionUI.cs
   │   └── ScriptableObjects/
   │       └── HeroTemplate.cs
   ```

### **Step 2: Create BlockBlastHUD UI**

#### A. Create Canvas
Same as Treasure Chase (Canvas Scaler settings)

#### B. Create HUD Elements
```
GameplayCanvas/
├── ScorePanel (Top Center)
│   ├── ScoreText - "0"
│   ├── TargetScoreText - "Goal: 1000"
│   └── ScoreProgressBar (Image - Fill)
├── LevelPanel (Top Left)
│   ├── LevelText - "Level 1"
│   └── LevelNameText - "Tutorial"
├── MovesPanel (Top Right)
│   ├── MovesBackground (Image)
│   └── MovesText - "30"
├── HeroPanel (Bottom Left)
│   ├── HeroPortrait (Image - Square)
│   ├── HeroNameText - "Knight"
│   ├── HeroLevelText - "Lv.1"
│   └── AbilityButton
│       ├── AbilityIcon (Image)
│       ├── AbilityCooldownOverlay (Image - Fill)
│       └── AbilityCooldownText - "0s"
├── BlockQueuePanel (Bottom Center)
│   ├── BlockSlot1 (BlockPreviewSlot)
│   ├── BlockSlot2
│   └── BlockSlot3
└── ComboPanel (Center, initially hidden)
    └── ComboText - "Combo x0!"
```

#### C. Assign Components
1. Create empty GameObject: "BlockBlastHUDManager"
2. Add Component → **BlockBlastHUD** script
3. Assign all references
4. Set colors:
   - Normal Moves Color: **White**
   - Low Moves Color: **Red**
5. Low Moves Threshold: **3**

✅ **Test:** Press Play - should show initial values

### **Step 3: Create HeroCollectionUI**

#### A. Create Collection Panel
```
MenuCanvas/
├── HeroCollectionPanel (Full Screen)
    ├── HeroGridPanel (Left 60%)
    │   ├── TitleText - "Heroes"
    │   ├── HeroGridContainer (Grid Layout Group)
    │   │   └── (Hero cards spawn here)
    │   └── ScrollView
    └── HeroDetailPanel (Right 40%)
        ├── HeroPortrait (Large Image)
        ├── HeroNameText
        ├── HeroDescriptionText
        ├── HeroRarityText
        ├── HeroLevelText
        ├── StatsPanel
        │   ├── PowerText
        │   ├── LineBonusText
        │   └── ComboMultiplierText
        ├── AbilityPanel
        │   ├── AbilityIcon
        │   ├── AbilityNameText
        │   ├── AbilityDescriptionText
        │   └── AbilityCooldownText
        ├── UpgradePanel
        │   ├── UpgradeButton
        │   ├── UpgradeCostText
        │   └── MaxLevelIndicator (Hidden)
        ├── LockedOverlay (Full panel, semi-transparent)
        │   └── UnlockButton
        │       └── UnlockCostText
        └── ActionButtons
            ├── EquipButton
            └── CloseButton
```

#### B. Create Hero Card Prefab
1. Create new Prefab: "HeroCard"
2. Structure:
```
HeroCard (Button, Image - colored border)
├── Portrait (Image)
├── NameText (TextMeshProUGUI)
├── LevelText (TextMeshProUGUI - top-right)
└── LockedIcon (Image - initially hidden)
```

3. Save as prefab: Assets/Prefabs/UI/HeroCard.prefab

#### C. Assign Components
1. Create empty GameObject: "HeroCollectionUIManager"
2. Add Component → **HeroCollectionUI** script
3. Assign all references
4. **Hero Card Prefab:** Drag HeroCard prefab
5. Set rarity colors:
   - Common: Gray RGB(128, 128, 128)
   - Rare: Blue RGB(0, 112, 255)
   - Epic: Purple RGB(163, 53, 238)
   - Legendary: Gold RGB(255, 204, 0)

### **Step 4: Create Hero ScriptableObjects**

#### A. Create Starter Hero (Knight)
1. Right-click: Assets/ScriptableObjects/Heroes/
2. Create → BlockBlastEvolved → Hero
3. Rename to "Hero_Knight"
4. Configure:

```
Identity:
- Hero ID: "knight_1"
- Hero Name: "Knight"
- Description: "A brave knight who protects the realm"
- Hero Icon: (Assign knight portrait sprite)
- Rarity: Common

Base Stats:
- Base Power: 100
- Line Bonus: 1.2 (20% bonus)
- Combo Multiplier: 1.5

Ability:
- Ability ID: "knight_slash"
- Ability Name: "Mighty Slash"
- Description: "Clears a random row on the grid"
- Ability Type: ClearRow
- Ability Power: 1
- Ability Cooldown: 30s
- Ability Duration: 0 (instant)

Progression:
- Max Level: 50
- Base Upgrade Cost: 100
- Stat Scaling Per Level: 0.1 (10% per level)

Unlock Requirements:
- Unlock Cost: 0 (starter hero)
- Unlock Currency: Coins
- Required Player Level: 0
- Required Achievement: (empty)

Audio:
- Ability Sound Name: "ability_slash"
- Level Up Sound Name: "hero_levelup"
- Unlock Sound Name: "hero_unlock"
```

#### B. Create More Heroes
Follow examples in HeroTemplate.cs:
- **Hero_Mage** (Rare - 1000 coins, level 5)
- **Hero_Archer** (Rare - 800 coins, level 3)
- **Hero_Merchant** (Epic - 500 gems, level 10)
- **Hero_Engineer** (Epic - 2500 coins, level 15)
- **Hero_Sorcerer** (Legendary - 1000 gems, level 25)
- **Hero_Paladin** (Legendary - 1500 gems, level 30)
- **Hero_Ninja** (Epic - 750 gems, level 20)

#### C. Assign to HeroSystem
1. Find HeroSystem in scene
2. Inspector → All Heroes → Size: **8**
3. Drag all hero ScriptableObjects into array
4. Set Active Hero: **Hero_Knight** (starter)

✅ **Test:** Open HeroCollectionUI, should show all heroes

---

## 🔧 Integration Testing

### **Treasure Chase Tests**

#### Test 1: HUD Updates
```csharp
// In game manager or test script
void TestHUD()
{
    // Score
    EndlessScoreManager.Instance.CollectTreasure(1);
    // Should see score increase, coin flash

    // Distance
    DistanceTracker.Instance.UpdateDistance(100f);
    // Should see distance update

    // Multiplier
    EndlessScoreManager.Instance.PassThroughGate(2);
    // Should see "x2.0" with pulse effect
}
```

#### Test 2: Game Over Flow
```csharp
void TestGameOver()
{
    // Play game for a bit
    // Then trigger:
    GameOverUI.Instance.Show();

    // Should see:
    // - Score count-up animation
    // - Stats displayed
    // - Tournament rank (if applicable)
    // - Buttons functional
}
```

#### Test 3: Theme Switching
```csharp
void TestThemes()
{
    // Manually trigger theme change:
    WorldManager.Instance.SetTheme(1, immediate: false);

    // Should see:
    // - Screen fade transition
    // - New theme visuals
    // - Theme music change
    // - Theme obstacles spawning
}
```

### **Block Blast Evolved Tests**

#### Test 1: HUD Updates
```csharp
void TestHUD()
{
    // Score
    BlockBlastHUD.Instance.AddScore(100, Vector3.zero);
    // Should see floating "+100" text

    // Moves
    BlockBlastHUD.Instance.UseMove();
    // Should decrease moves counter

    // Combo
    BlockBlastHUD.Instance.UpdateCombo(5);
    // Should show "Combo x5!" with pulse
}
```

#### Test 2: Hero Collection
```csharp
void TestHeroCollection()
{
    // Open collection
    HeroCollectionUI.Instance.Show();

    // Should see:
    // - All heroes in grid (locked/unlocked)
    // - Rarity border colors
    // - Click hero to see details
    // - Equip/upgrade/unlock buttons work
}
```

#### Test 3: Hero Abilities
```csharp
void TestAbilities()
{
    // Use ability
    HeroSystem.Instance.UseAbility();

    // Should see:
    // - Ability execute (row clear, etc.)
    // - Cooldown start
    // - HUD cooldown overlay update
    // - Visual/audio feedback
}
```

---

## 📊 Complete File Summary

### **Created This Session**

| File | Lines | Purpose |
|------|-------|---------|
| **Treasure Chase** |
| EndlessHUD.cs | 650 | In-game HUD system |
| GameOverUI.cs | 450 | Game over screen |
| WorldThemeTemplate.cs | 400 | Theme configuration |
| **Block Blast Evolved** |
| BlockBlastHUD.cs | 700 | In-game HUD system |
| HeroCollectionUI.cs | 550 | Hero management UI |
| HeroTemplate.cs | 450 | Hero configuration |
| **TOTAL** | **~3,200** | **7 production scripts** |

### **Grand Total (All Sessions)**

| Category | Count | Size |
|----------|-------|------|
| Documentation | 16 files | 95,000+ words |
| C# Scripts | 19 files | 7,900+ lines |
| ScriptableObject Templates | 2 files | 850 lines |
| **TOTAL** | **37 files** | **95,000 words + 8,750 lines** |

---

## 🎯 What You Can Do NOW

### **Treasure Chase**
1. ✅ Copy 3 UI scripts to Unity
2. ✅ Build HUD in 30 minutes following guide
3. ✅ Create 6 WorldTheme ScriptableObjects
4. ✅ Test theme switching at different distances
5. ✅ Test game over screen with stats
6. ✅ Hook up all systems together

### **Block Blast Evolved**
1. ✅ Copy 3 UI scripts to Unity
2. ✅ Build HUD and collection UI
3. ✅ Create 8 Hero ScriptableObjects
4. ✅ Test hero collection, equip, upgrade
5. ✅ Test hero abilities
6. ✅ Connect to grid system

---

## 🚨 Common Issues & Solutions

### Issue: "EndlessHUD.Instance is null"
**Solution:** Make sure EndlessHUD script is attached to GameObject in scene before accessing it.

### Issue: "NullReferenceException in UpdateScore"
**Solution:** Assign all TextMeshProUGUI references in inspector. Check for null before using:
```csharp
if (scoreText != null) {
    scoreText.text = score.ToString();
}
```

### Issue: "Heroes not showing in collection"
**Solution:**
1. Check HeroSystem.allHeroes array is populated
2. Check heroCardPrefab is assigned
3. Check heroGridContainer exists

### Issue: "Ability button not working"
**Solution:**
1. Check HeroSystem has active hero set
2. Check ability is not on cooldown
3. Check button has EventSystem in scene

### Issue: "Theme doesn't change"
**Solution:**
1. Check WorldManager exists in scene
2. Check worldThemes array is populated
3. Check DistanceTracker is working
4. Check themeChangeDistance setting

---

## 💡 Next Steps

### Immediate
1. **Set up UI in Unity** (2-3 hours)
2. **Create ScriptableObjects** (1 hour)
3. **Test all systems** (1 hour)

### Short-Term
1. **Polish animations** (add more juice)
2. **Add sound effects** (for all UI actions)
3. **Create more themes** (8-10 total)
4. **Create more heroes** (15-20 total)

### Medium-Term
1. **Mobile touch controls**
2. **Analytics integration**
3. **Ads integration** (watch ad for 2x coins)
4. **Social sharing** (native plugins)

---

**🎨 YOUR UI IS READY! TIME TO BUILD! 🚀**

---

*Created: 2026-01-26*
*Session: UI & ScriptableObjects Implementation*
*Status: ✅ Complete - Ready for Unity Integration*
