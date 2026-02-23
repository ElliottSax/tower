--[[
    Tower Ascent - SecurityManager Authentication Test
    Fix #2: Validates IsAuthenticated() function
    Test Cases: TA-F2-1, TA-F2-2, TA-F2-3
]]

local TestRunner = {}

function TestRunner.TestNewPlayerAuthenticated()
    print("=== TA-F2-1: New Player Authenticated ===")

    local success, SecurityManager = pcall(function()
        return require(game.ServerScriptService.Security.SecurityManager)
    end)

    if not success then
        print("❌ FAIL: Could not load SecurityManager:", SecurityManager)
        return "FAIL"
    end

    -- Get first player
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Test authentication
    local isAuthed = SecurityManager.IsAuthenticated(player)

    if isAuthed == true then
        print("✅ PASS: Player authenticated successfully")
        print("  Player:", player.Name)
        return "PASS"
    else
        print("❌ FAIL: Valid player not authenticated")
        print("  Player:", player.Name)
        print("  Result:", isAuthed)
        return "FAIL"
    end
end

function TestRunner.TestBannedPlayerRejected()
    print("=== TA-F2-2: Banned Player Rejected ===")
    print("⚠️  MANUAL TEST: Requires banned player account")
    print("  1. Ban a test account (TestUser2)")
    print("  2. Join as banned player")
    print("  3. Trigger secure remote")
    print("  Expected: RemoteEvent rejected, warning logged")
    return "MANUAL"
end

function TestRunner.TestNilPlayerHandled()
    print("=== TA-F2-3: Nil Player Handled ===")

    local success, SecurityManager = pcall(function()
        return require(game.ServerScriptService.Security.SecurityManager)
    end)

    if not success then
        print("❌ FAIL: Could not load SecurityManager:", SecurityManager)
        return "FAIL"
    end

    -- Test with nil player
    local isAuthed = SecurityManager.IsAuthenticated(nil)

    if isAuthed == false then
        print("✅ PASS: nil player returns false (no error)")
        return "PASS"
    else
        print("❌ FAIL: nil player should return false")
        print("  Result:", isAuthed)
        return "FAIL"
    end
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Tower Ascent - Authentication Tests             ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 3,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestNewPlayerAuthenticated()
    if result1 == "PASS" then results.Passed = results.Passed + 1
    elseif result1 == "FAIL" then results.Failed = results.Failed + 1
    elseif result1 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 2
    local result2 = TestRunner.TestBannedPlayerRejected()
    if result2 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 3
    local result3 = TestRunner.TestNilPlayerHandled()
    if result3 == "PASS" then results.Passed = results.Passed + 1
    elseif result3 == "FAIL" then results.Failed = results.Failed + 1
    end

    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Test Results Summary                             ║")
    print("╚═══════════════════════════════════════════════════╝")
    print(string.format("Total:   %d", results.Total))
    print(string.format("✅ Passed: %d", results.Passed))
    print(string.format("❌ Failed: %d", results.Failed))
    print(string.format("⏭️  Skipped: %d", results.Skipped))
    print(string.format("✋ Manual: %d", results.Manual))

    return results
end

-- Auto-run if executed directly
if not _G.TestFramework then
    TestRunner.RunAllTests()
end

return TestRunner
