--[[
	AdminCommands.lua
	Developer admin commands for testing and debugging

	Access via: _G.TowerAscent.AdminCommands

	Available Commands:
	- Coins: Add/Set/Get player coins
	- VIP: Grant/Revoke VIP status
	- Teleport: Teleport to section/checkpoint
	- Stats: View player/server statistics
	- Memory: Force cleanup, view stats
	- AntiCheat: Clear violations, view stats
	- Tower: Regenerate, validate
	- Tests: Run validation suite

	Usage Examples:
		_G.TowerAscent.AdminCommands.GiveCoins(player, 1000)
		_G.TowerAscent.AdminCommands.TeleportToSection(player, 25)
		_G.TowerAscent.AdminCommands.ViewStats()

	Week 1: Created post-code-review (2025-12-01)
--]]

local Players = game:GetService("Players")

local AdminCommands = {}

-- ============================================================================
-- COIN COMMANDS
-- ============================================================================

function AdminCommands.GiveCoins(player: Player, amount: number)
	--[[
		Gives coins to player
		Usage: AdminCommands.GiveCoins(player, 1000)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then
		warn("[AdminCommands] CoinService not found")
		return false
	end

	local success = CoinService.AdminAddCoins(player, amount)
	if success then
		print(string.format("[AdminCommands] Gave %d coins to %s", amount, player.Name))
	end
	return success
end

function AdminCommands.SetCoins(player: Player, amount: number)
	--[[
		Sets player coins to exact amount
		Usage: AdminCommands.SetCoins(player, 5000)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then
		warn("[AdminCommands] CoinService not found")
		return false
	end

	local success = CoinService.AdminSetCoins(player, amount)
	if success then
		print(string.format("[AdminCommands] Set %s coins to %d", player.Name, amount))
	end
	return success
end

function AdminCommands.GetCoins(player: Player): number
	--[[
		Gets player's current coins
		Usage: AdminCommands.GetCoins(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return 0
	end

	local CoinService = _G.TowerAscent and _G.TowerAscent.CoinService
	if not CoinService then
		warn("[AdminCommands] CoinService not found")
		return 0
	end

	local coins = CoinService.GetCoins(player)
	print(string.format("[AdminCommands] %s has %d coins", player.Name, coins))
	return coins
end

-- ============================================================================
-- VIP COMMANDS
-- ============================================================================

function AdminCommands.GrantVIP(player: Player)
	--[[
		Grants temporary VIP status (testing only)
		Usage: AdminCommands.GrantVIP(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local VIPService = _G.TowerAscent and _G.TowerAscent.VIPService
	if not VIPService then
		warn("[AdminCommands] VIPService not found")
		return false
	end

	VIPService.AdminGrantVIP(player)
	print(string.format("[AdminCommands] Granted VIP to %s", player.Name))
	return true
end

function AdminCommands.RevokeVIP(player: Player)
	--[[
		Revokes VIP status
		Usage: AdminCommands.RevokeVIP(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local VIPService = _G.TowerAscent and _G.TowerAscent.VIPService
	if not VIPService then
		warn("[AdminCommands] VIPService not found")
		return false
	end

	VIPService.AdminRevokeVIP(player)
	print(string.format("[AdminCommands] Revoked VIP from %s", player.Name))
	return true
end

-- ============================================================================
-- TELEPORT COMMANDS
-- ============================================================================

function AdminCommands.TeleportToSection(player: Player, sectionNumber: number)
	--[[
		Teleports player to specific section
		Usage: AdminCommands.TeleportToSection(player, 25)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local character = player.Character
	if not character then
		warn("[AdminCommands] Player has no character")
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("[AdminCommands] Character has no HumanoidRootPart")
		return false
	end

	-- Find section in tower
	local tower = _G.TowerAscent and _G.TowerAscent.Tower
	if not tower then
		warn("[AdminCommands] Tower not found")
		return false
	end

	local sectionName = string.format("Section_%d", sectionNumber)
	local section = tower:FindFirstChild(sectionName, true)

	if not section then
		warn(string.format("[AdminCommands] Section %d not found", sectionNumber))
		return false
	end

	-- Find checkpoint in section
	local checkpoint = section:FindFirstChild("Checkpoint", true)
	if checkpoint and checkpoint:IsA("BasePart") then
		rootPart.CFrame = CFrame.new(checkpoint.Position + Vector3.new(0, 5, 0))
		print(string.format("[AdminCommands] Teleported %s to section %d", player.Name, sectionNumber))
		return true
	else
		warn(string.format("[AdminCommands] No checkpoint found in section %d", sectionNumber))
		return false
	end
end

function AdminCommands.TeleportToStart(player: Player)
	--[[
		Teleports player to start of tower
		Usage: AdminCommands.TeleportToStart(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local character = player.Character
	if not character then
		warn("[AdminCommands] Player has no character")
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("[AdminCommands] Character has no HumanoidRootPart")
		return false
	end

	local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)
	rootPart.CFrame = CFrame.new(Vector3.new(0, GameConfig.Tower.StartHeight + 5, 0))
	print(string.format("[AdminCommands] Teleported %s to start", player.Name))
	return true
end

-- ============================================================================
-- STATS COMMANDS
-- ============================================================================

function AdminCommands.ViewPlayerStats(player: Player)
	--[[
		Displays player statistics
		Usage: AdminCommands.ViewPlayerStats(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return
	end

	print(string.rep("=", 60))
	print(string.format("PLAYER STATS: %s", player.Name))
	print(string.rep("=", 60))

	-- Get data
	local DataService = _G.TowerAscent and _G.TowerAscent.DataService
	if DataService then
		local data = DataService.GetData(player)
		if data then
			print(string.format("Coins: %d", data.Coins))
			print(string.format("Highest Stage: %d", data.Stats.HighestStage))
			print(string.format("Towers Completed: %d", data.Stats.TowersCompleted))
			print(string.format("Deaths: %d", data.Stats.Deaths))
			print(string.format("Total Playtime: %.1f minutes", data.Stats.TotalPlaytime / 60))

			print("\nUpgrades:")
			for name, level in pairs(data.Upgrades) do
				print(string.format("  %s: Level %d", name, level))
			end
		end
	end

	-- Get current section
	local CheckpointService = _G.TowerAscent and _G.TowerAscent.CheckpointService
	if CheckpointService then
		local section = CheckpointService.GetPlayerSection(player)
		print(string.format("\nCurrent Section: %d", section))
	end

	-- Get VIP status
	local VIPService = _G.TowerAscent and _G.TowerAscent.VIPService
	if VIPService then
		local isVIP = VIPService.IsVIP(player)
		print(string.format("VIP Status: %s", isVIP and "YES" or "NO"))
	end

	print(string.rep("=", 60))
end

function AdminCommands.ViewServerStats()
	--[[
		Displays server statistics
		Usage: AdminCommands.ViewServerStats()
	--]]
	print(string.rep("=", 60))
	print("SERVER STATISTICS")
	print(string.rep("=", 60))

	-- Player stats
	local playerCount = #Players:GetPlayers()
	print(string.format("Players: %d", playerCount))

	-- Round stats
	local RoundService = _G.TowerAscent and _G.TowerAscent.RoundService
	if RoundService then
		print(string.format("Round Number: %d", RoundService.GetRoundNumber()))
		print(string.format("Round State: %s", RoundService.GetCurrentState()))
		print(string.format("Time Remaining: %d seconds", RoundService.GetTimeRemaining()))
	end

	-- Memory stats
	local MemoryManager = _G.TowerAscent and _G.TowerAscent.MemoryManager
	if MemoryManager then
		local stats = MemoryManager:GetStats()
		print(string.format("\nMemory Stats:"))
		print(string.format("  Total Stages: %d", stats.TotalStages))
		print(string.format("  Active Stages: %d", stats.ActiveStages))
		print(string.format("  Despawned Stages: %d", stats.DespawnedStages))
		print(string.format("  Parts: %d", stats.CurrentPartCount))
		print(string.format("  Memory: %.1f MB", stats.MemoryUsageMB))
		print(string.format("  Cleanups: %d", stats.CleanupCount))
	end

	-- Anti-cheat stats
	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat
	if AntiCheat then
		local stats = AntiCheat:GetStats()
		print(string.format("\nAnti-Cheat Stats:"))
		print(string.format("  Violations: %d", stats.TotalViolations))
		print(string.format("  Kicks: %d", stats.TotalKicks))
	end

	print(string.rep("=", 60))
end

-- ============================================================================
-- MEMORY COMMANDS
-- ============================================================================

function AdminCommands.ForceMemoryCleanup()
	--[[
		Forces memory cleanup
		Usage: AdminCommands.ForceMemoryCleanup()
	--]]
	local MemoryManager = _G.TowerAscent and _G.TowerAscent.MemoryManager
	if not MemoryManager then
		warn("[AdminCommands] MemoryManager not found")
		return false
	end

	MemoryManager:ForceCleanup()
	print("[AdminCommands] Forced memory cleanup")
	return true
end

function AdminCommands.ViewMemoryStats()
	--[[
		Displays detailed memory statistics
		Usage: AdminCommands.ViewMemoryStats()
	--]]
	local MemoryManager = _G.TowerAscent and _G.TowerAscent.MemoryManager
	if not MemoryManager then
		warn("[AdminCommands] MemoryManager not found")
		return
	end

	MemoryManager:LogMemoryStats()
end

-- ============================================================================
-- ANTI-CHEAT COMMANDS
-- ============================================================================

function AdminCommands.ClearViolations(player: Player)
	--[[
		Clears player's anti-cheat violations
		Usage: AdminCommands.ClearViolations(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return false
	end

	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat
	if not AntiCheat then
		warn("[AdminCommands] AntiCheat not found")
		return false
	end

	AntiCheat:ClearViolations(player)
	print(string.format("[AdminCommands] Cleared violations for %s", player.Name))
	return true
end

function AdminCommands.ViewViolations(player: Player)
	--[[
		Displays player's violations
		Usage: AdminCommands.ViewViolations(player)
	--]]
	if not player or not player:IsA("Player") then
		warn("[AdminCommands] Invalid player")
		return
	end

	local AntiCheat = _G.TowerAscent and _G.TowerAscent.AntiCheat
	if not AntiCheat then
		warn("[AdminCommands] AntiCheat not found")
		return
	end

	local violations = AntiCheat:GetPlayerViolations(player)
	print(string.rep("=", 60))
	print(string.format("VIOLATIONS FOR: %s", player.Name))
	print(string.rep("=", 60))

	if #violations == 0 then
		print("No violations")
	else
		for i, v in ipairs(violations) do
			print(string.format("%d. [%s] %s", i, v.Type, os.date("%X", v.Timestamp)))
		end
	end

	print(string.rep("=", 60))
end

-- ============================================================================
-- TOWER COMMANDS
-- ============================================================================

function AdminCommands.RegenerateTower()
	--[[
		Regenerates the tower
		Usage: AdminCommands.RegenerateTower()
	--]]
	local RoundService = _G.TowerAscent and _G.TowerAscent.RoundService
	if not RoundService then
		warn("[AdminCommands] RoundService not found")
		return false
	end

	RoundService.GenerateNewTower()
	print("[AdminCommands] Tower regenerated")
	return true
end

-- ============================================================================
-- TEST COMMANDS
-- ============================================================================

function AdminCommands.RunTests()
	--[[
		Runs validation test suite
		Usage: AdminCommands.RunTests()
	--]]
	local ValidationTests = _G.TowerAscent and _G.TowerAscent.ValidationTests
	if not ValidationTests then
		warn("[AdminCommands] ValidationTests not found")
		return false
	end

	ValidationTests.RunAll()
	return true
end

-- ============================================================================
-- HELP
-- ============================================================================

function AdminCommands.Help()
	--[[
		Displays available commands
		Usage: AdminCommands.Help()
	--]]
	print(string.rep("=", 60))
	print("ADMIN COMMANDS - QUICK REFERENCE")
	print(string.rep("=", 60))
	print("\nCOINS:")
	print("  GiveCoins(player, amount) - Give coins to player")
	print("  SetCoins(player, amount) - Set player coins")
	print("  GetCoins(player) - View player coins")
	print("\nVIP:")
	print("  GrantVIP(player) - Grant temporary VIP")
	print("  RevokeVIP(player) - Revoke VIP")
	print("\nTELEPORT:")
	print("  TeleportToSection(player, number) - Teleport to section")
	print("  TeleportToStart(player) - Teleport to start")
	print("\nSTATS:")
	print("  ViewPlayerStats(player) - View player stats")
	print("  ViewServerStats() - View server stats")
	print("\nMEMORY:")
	print("  ForceMemoryCleanup() - Force cleanup")
	print("  ViewMemoryStats() - View memory stats")
	print("\nANTI-CHEAT:")
	print("  ClearViolations(player) - Clear violations")
	print("  ViewViolations(player) - View violations")
	print("\nTOWER:")
	print("  RegenerateTower() - Regenerate tower")
	print("\nTESTS:")
	print("  RunTests() - Run validation tests")
	print(string.rep("=", 60))
	print("\nExample: _G.TowerAscent.AdminCommands.GiveCoins(player, 1000)")
	print(string.rep("=", 60))
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return AdminCommands
