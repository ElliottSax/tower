--[[
    Speed Run Universe - Speedrun Time Validation Test
    Fix #1: Validates anti-cheat speedrun validation
    Test Cases: SRU-F1-1 through SRU-F1-5
]]

local TestRunner = {}

function TestRunner.TestValidTimeAccepted()
    print("=== SRU-F1-1: Valid Speedrun Time Accepted ===")
    print("⚠️  MANUAL TEST: Requires actual gameplay")
    print("  1. Complete Grass world in 20 seconds")
    print("  2. Ensure checkpoints recorded [5, 10, 15]")
    print("  3. Submit time to leaderboard")
    print("  Expected: Time accepted and saved to leaderboard")
    return "MANUAL"
end

function TestRunner.TestImpossibleTimeRejected()
    print("=== SRU-F1-2: Impossible Time Rejected ===")

    local success, SecurityManager = pcall(function()
        return require(game.ServerScriptService.Security.SecurityManager)
    end)

    if not success then
        print("❌ FAIL: Could not load SecurityManager:", SecurityManager)
        return "FAIL"
    end

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Attempt to submit impossible time (0.1 seconds for Grass world)
    local valid, reason = SecurityManager.ValidateSpeedrunTime(player, "Grass", nil, 0.1, {})

    print("  World: Grass")
    print("  Time: 0.1s")
    print("  Valid:", valid)
    print("  Reason:", reason or "N/A")

    if valid == false and reason and string.find(reason:lower(), "too fast") then
        print("✅ PASS: Impossible time rejected correctly")
        return "PASS"
    else
        print("❌ FAIL: Impossible time should be rejected")
        return "FAIL"
    end
end

function TestRunner.TestNonMonotonicCheckpoints()
    print("=== SRU-F1-3: Non-Monotonic Checkpoints Rejected ===")

    local success, SecurityManager = pcall(function()
        return require(game.ServerScriptService.Security.SecurityManager)
    end)

    if not success then
        print("❌ FAIL: Could not load SecurityManager:", SecurityManager)
        return "FAIL"
    end

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Submit non-monotonic checkpoints [5, 3, 10] (3 < 5 is backwards)
    local valid, reason = SecurityManager.ValidateSpeedrunTime(player, "Grass", nil, 15, {5, 3, 10})

    print("  Checkpoints: [5, 3, 10]")
    print("  Valid:", valid)
    print("  Reason:", reason or "N/A")

    if valid == false and reason and string.find(reason:lower(), "increasing") then
        print("✅ PASS: Non-monotonic checkpoints rejected")
        return "PASS"
    else
        print("❌ FAIL: Non-monotonic checkpoints should be rejected")
        return "FAIL"
    end
end

function TestRunner.TestCompletionLessThanCheckpoint()
    print("=== SRU-F1-4: Completion < Last Checkpoint Rejected ===")

    local success, SecurityManager = pcall(function()
        return require(game.ServerScriptService.Security.SecurityManager)
    end)

    if not success then
        print("❌ FAIL: Could not load SecurityManager:", SecurityManager)
        return "FAIL"
    end

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Submit checkpoints [5, 10, 15] but completion time of 12 (less than last checkpoint 15)
    local valid, reason = SecurityManager.ValidateSpeedrunTime(player, "Grass", nil, 12, {5, 10, 15})

    print("  Checkpoints: [5, 10, 15]")
    print("  Completion: 12s (< 15)")
    print("  Valid:", valid)
    print("  Reason:", reason or "N/A")

    if valid == false and reason and string.find(reason:lower(), "less than") then
        print("✅ PASS: Completion < checkpoint rejected")
        return "PASS"
    else
        print("❌ FAIL: Completion < last checkpoint should be rejected")
        return "FAIL"
    end
end

function TestRunner.TestSuddenImprovementFlagged()
    print("=== SRU-F1-5: Sudden Improvement Flagged ===")
    print("⚠️  MANUAL TEST: Requires existing PB data")
    print("  1. Set personal best of 60 seconds on Grass")
    print("  2. Submit new time of 20 seconds (67% faster)")
    print("  3. Check server logs")
    print("  Expected: Warning logged, time accepted but flagged for review")
    return "MANUAL"
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Speed Run - Speedrun Validation Tests           ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 5,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestValidTimeAccepted()
    if result1 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 2
    local result2 = TestRunner.TestImpossibleTimeRejected()
    if result2 == "PASS" then results.Passed = results.Passed + 1
    elseif result2 == "FAIL" then results.Failed = results.Failed + 1
    elseif result2 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 3
    local result3 = TestRunner.TestNonMonotonicCheckpoints()
    if result3 == "PASS" then results.Passed = results.Passed + 1
    elseif result3 == "FAIL" then results.Failed = results.Failed + 1
    elseif result3 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 4
    local result4 = TestRunner.TestCompletionLessThanCheckpoint()
    if result4 == "PASS" then results.Passed = results.Passed + 1
    elseif result4 == "FAIL" then results.Failed = results.Failed + 1
    elseif result4 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 5
    local result5 = TestRunner.TestSuddenImprovementFlagged()
    if result5 == "MANUAL" then results.Manual = results.Manual + 1 end

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
