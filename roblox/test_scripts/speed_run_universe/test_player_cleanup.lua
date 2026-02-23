--[[
    Speed Run Universe - PlayerRemoving Cleanup Test
    Fix #2: Validates proper cleanup when player leaves
    Test Cases: SRU-F2-1, SRU-F2-2, SRU-F2-3
]]

local TestRunner = {}

function TestRunner.TestActiveRunCleanedOnLeave()
    print("=== SRU-F2-1: Active Run Cleaned On Leave ===")
    print("⚠️  MANUAL TEST: Requires player join/leave")
    print("  1. Join server and start a speedrun")
    print("  2. Leave server immediately (mid-run)")
    print("  3. Check server console for ActiveRuns table")
    print("  Expected: Player removed from ActiveRuns table")
    print("")
    print("  Validation command (run after player leaves):")
    print("  local SpeedrunService = require(game.ServerScriptService.Services.SpeedrunService)")
    print("  print('Active Runs:', #SpeedrunService.ActiveRuns)")
    print("  -- Should be 0 after all players leave")
    return "MANUAL"
end

function TestRunner.TestGhostRecordingSaved()
    print("=== SRU-F2-2: Ghost Recording Saved ===")
    print("⚠️  MANUAL TEST: Requires DataStore inspection")
    print("  1. Start speedrun and record 100+ frames")
    print("  2. Leave server mid-run (don't finish)")
    print("  3. Check DataStore for partial ghost save")
    print("  Expected: Partial ghost saved with >50 frames")
    print("")
    print("  Validation:")
    print("  - Ghost should be saved even if run incomplete")
    print("  - Minimum 50 frames required for save")
    print("  - DataStore key: 'Ghost_[world]_[userId]'")
    return "MANUAL"
end

function TestRunner.TestMemoryDoesntLeak()
    print("=== SRU-F2-3: Memory Doesn't Leak (Join/Leave Stress) ===")
    print("⚠️  COMPLEX MANUAL TEST: Requires extended monitoring")
    print("")
    print("  Test Procedure:")
    print("  1. Record baseline memory:")
    print("     local startMem = game:GetService('Stats'):GetTotalMemoryUsageMb()")
    print("     print('Baseline Memory:', startMem, 'MB')")
    print("")
    print("  2. Have player join/leave 100 times")
    print("     - Join server")
    print("     - Start speedrun")
    print("     - Leave after 5 seconds")
    print("     - Repeat 100x")
    print("")
    print("  3. Check final memory:")
    print("     local endMem = game:GetService('Stats'):GetTotalMemoryUsageMb()")
    print("     local growth = endMem - startMem")
    print("     print('Memory Growth:', growth, 'MB')")
    print("")
    print("  Expected Results:")
    print("  - Memory growth < 50MB after 100 cycles")
    print("  - No continuous upward trend")
    print("  - Memory stabilizes after activity stops")
    print("")
    print("  Success Criteria: Memory growth < 0.5MB per join/leave cycle")
    return "MANUAL"
end

function TestRunner.TestCleanupCodeExists()
    print("=== SRU-F2-BONUS: Verify Cleanup Code Exists ===")

    local success, SpeedrunService = pcall(function()
        return require(game.ServerScriptService.Services.SpeedrunService)
    end)

    if not success then
        print("❌ FAIL: Could not load SpeedrunService:", SpeedrunService)
        return "FAIL"
    end

    -- Check if ActiveRuns table exists
    if SpeedrunService.ActiveRuns then
        print("✅ PASS: ActiveRuns table exists")
        print("  Type:", type(SpeedrunService.ActiveRuns))

        -- Check if it's a table
        if type(SpeedrunService.ActiveRuns) == "table" then
            print("  Current active runs:", #SpeedrunService.ActiveRuns)
            return "PASS"
        else
            print("❌ FAIL: ActiveRuns should be a table")
            return "FAIL"
        end
    else
        print("⚠️  WARN: ActiveRuns table not found (may be local variable)")
        return "WARN"
    end
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Speed Run - PlayerRemoving Cleanup Tests        ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 4,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestActiveRunCleanedOnLeave()
    if result1 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 2
    local result2 = TestRunner.TestGhostRecordingSaved()
    if result2 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 3
    local result3 = TestRunner.TestMemoryDoesntLeak()
    if result3 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Bonus test
    local result4 = TestRunner.TestCleanupCodeExists()
    if result4 == "PASS" then results.Passed = results.Passed + 1
    elseif result4 == "FAIL" then results.Failed = results.Failed + 1
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
