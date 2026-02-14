# Adventure Story Obby - Quick Start Guide

Get your game running in **5 simple steps**! 🚀

---

## Prerequisites

- ✅ Roblox Studio installed
- ✅ Rojo installed ([rojo.space](https://rojo.space/))
- ✅ Rojo Studio plugin installed

---

## Step 1: Start Rojo Server

Open a terminal and navigate to the project:

```bash
cd /mnt/e/projects/roblox/adventure-story-obby
rojo serve
```

You should see:
```
Rojo server listening on port 34872
```

---

## Step 2: Connect from Studio

1. Open Roblox Studio
2. Create a new **Baseplate** game
3. Click the **Rojo** plugin button in the toolbar
4. Click **Connect**
5. You should see "Connected to Roblox Studio" in the terminal

All scripts and folders will now sync to Studio automatically! ✅

---

## Step 3: Build the Hub World

In Roblox Studio:

### A. Create Spawn Point
1. Insert a **Part** in Workspace
2. Name it `HubSpawn`
3. Position: `Vector3.new(0, 5, 0)`
4. Make it **Transparent** and **CanCollide = false**

### B. Create NPC Spawn Markers
Create 3 parts for NPC positions:
- `Hub_Guide` at `Vector3.new(-20, 5, 0)`
- `Hub_Merchant` at `Vector3.new(20, 5, 0)`
- `Hub_Elder` at `Vector3.new(0, 5, -20)`

Make all transparent and non-collidable.

### C. Add a Floor
1. Insert a large **Part** for the ground
2. Size: `Vector3.new(100, 1, 100)`
3. Position: `Vector3.new(0, 0, 0)`
4. Anchor it

---

## Step 4: Build Level 1 (Tutorial)

### A. Create Level Folder
1. In Workspace, create a **Folder** named `World1_Level1`
2. Inside it, create a **Part** named `Spawn`
3. Position: `Vector3.new(100, 5, 0)` (away from hub)

### B. Create Simple Path
Build a straight path with 3-4 platforms:
1. Each platform: 10x1x10 studs
2. Space them 10-15 studs apart
3. Make all platforms **Anchored**

### C. Add Checkpoints
Create 3 checkpoint parts:
- Name them `Checkpoint1`, `Checkpoint2`, `Checkpoint3`
- Make them **Transparent** and **CanCollide = false**
- Place them along the path

### D. Add Finish Line
Create a part at the end named `Finish`
- Add a **TouchEnded** script that fires `CompleteLevelEvent`

**Quick Finish Script:**
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local completeLevelEvent = remoteEvents:WaitForChild("CompleteLevelEvent")

script.Parent.Touched:Connect(function(hit)
    local humanoid = hit.Parent:FindFirstChild("Humanoid")
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            completeLevelEvent:FireServer()
        end
    end
end)
```

---

## Step 5: Add Collectibles (Optional)

1. Insert a **Part** in Workspace
2. Make it look like a collectible (bright color, small size)
3. **Set attributes** (right-click → Add Attribute):
   - `CollectibleType` (String): `"Fragment"`
   - `CollectibleId` (String): `"Fragment_W1_L2"`
4. Place it in Level 2 (or create Level 2 first)

---

## 🎮 Test the Game!

1. Click **Play** in Studio
2. You should spawn at `HubSpawn`
3. Walk around and you'll see NPCs spawn (basic models)
4. Press **E** to interact with NPCs
5. Talk to the Guide NPC to start the story
6. Press **M** to open the Story UI
7. Click "START" on Level 1
8. Complete the level and return to hub
9. Check the Quest Tracker (top-right) for progress

---

## 🎯 Verification Checklist

Test these features:

- [ ] **Spawn in hub** - Do you start at the spawn point?
- [ ] **NPCs appear** - Do you see 3 NPCs (basic blocks)?
- [ ] **Interact with NPC** - Press E near Guide, does dialogue open?
- [ ] **Dialogue choices** - Can you select choices?
- [ ] **Quest received** - Check quest tracker (top-right)
- [ ] **Story UI** - Press M, does level selection open?
- [ ] **Teleport to level** - Click START on Level 1
- [ ] **Complete level** - Touch the finish line
- [ ] **Return to hub** - Do you teleport back?
- [ ] **Coins awarded** - Check coin display
- [ ] **Data saves** - Leave and rejoin, is progress saved?

---

## 🐛 Troubleshooting

### "No NPCs spawning"
- Check that spawn markers exist: `Hub_Guide`, `Hub_Merchant`, `Hub_Elder`
- Check Output window for errors

### "Can't teleport to levels"
- Ensure levels have a `Spawn` part
- Check that level folder is named exactly: `World1_Level1`

### "Dialogue not opening"
- Make sure RemoteEvents folder exists in ReplicatedStorage
- Check for errors in Output window

### "Scripts not loading"
- Ensure Rojo is connected (green indicator)
- Try clicking "Sync" in Rojo plugin

### "Data not saving"
- ProfileService requires a published game for full testing
- In Studio, it uses mock data (won't persist between sessions)

---

## 📦 What's Already Working

Even with minimal building, you have:

✅ **Full NPC system** - NPCs spawn and interact
✅ **Complete dialogue system** - 15+ dialogue nodes
✅ **Quest tracking** - Story and daily quests
✅ **Level progression** - Unlock system
✅ **Data persistence** - ProfileService integration
✅ **Coin economy** - Earn and track coins
✅ **UI systems** - Dialogue, quests, story map
✅ **Security** - Anti-cheat and validation

---

## 🔥 Pro Tips

1. **Build iteratively** - Start with Level 1, test, then expand
2. **Use the console** - Output window shows useful debug info
3. **Test data persistence** - Leave/rejoin frequently
4. **Customize NPCs** - Replace basic models with custom characters
5. **Add decorations** - Make the hub and levels visually appealing
6. **Tune difficulty** - Adjust jump distances and hazards

---

## 🚀 Expand Further

Once Level 1 works, build more levels:
- **Level 2**: Add moving platforms
- **Level 3**: Add water hazards (kill parts)
- **Level 4**: Add spikes and traps
- **Level 5**: Combine all mechanics for finale

Follow the level designs in `StoryChapters.lua` for guidance!

---

## 📚 Need Help?

- Check **README.md** for full documentation
- Check **IMPLEMENTATION_SUMMARY.md** for what's implemented
- Read inline comments in the code
- Check the **Output** window in Studio for errors

---

## 🎉 You're Ready!

With just these 5 steps, you have a **fully functional story-driven obby** with:
- NPC interactions
- Quests
- Level progression
- Data persistence
- Professional UI

**Now go build something amazing!** 🌟
