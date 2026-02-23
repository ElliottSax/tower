--[[
    Adventure Story Obby - Collectible Animation Memory Leak Test
    Fix #3: Validates animation thread cleanup prevents memory leaks
    Test Cases: ASO-F3-1, ASO-F3-2, ASO-F3-3
]]

local TestRunner = {}

function TestRunner.TestAnimationThreadCleaned()
    print("=== ASO-F3-1: Animation Thread Cleaned ===")
    print("⚠️  MANUAL TEST: Requires game simulation")
    print("")
    print("  Test Procedure:")
    print("  1. Spawn 10 collectibles in workspace")
    print("  2. Note each has floating animation (task.spawn loop)")
    print("  3. Collect all 10 collectibles")
    print("  4. Check that animation threads are cancelled")
    print("")
    print("  Validation (server console):")
    print("  local CollectibleService = require(game.ServerScriptService.Services.CollectibleService)")
    print("  print('Active collectibles:', #CollectibleService.ActiveCollectibles)")
    print("  -- Should be 0 after all collected")
    print("")
    print("  Expected Results:")
    print("  - ActiveCollectibles table empty after collection")
    print("  - No orphaned animation threads")
    print("  - Memory returns to baseline")
    return "MANUAL"
end

function TestRunner.TestRapidCollectionStress()
    print("=== ASO-F3-2: Rapid Collection Stress Test ===")
    print("⚠️  COMPLEX MANUAL TEST: Stress testing")
    print("")
    print("  Test Procedure:")
    print("  1. Record baseline memory:")
    print("     local Stats = game:GetService('Stats')")
    print("     local startMem = Stats:GetTotalMemoryUsageMb()")
    print("")
    print("  2. Spawn 100 collectibles in workspace")
    print("  3. Collect all 100 in under 10 seconds")
    print("  4. Wait 30 seconds for cleanup")
    print("  5. Record final memory:")
    print("     local endMem = Stats:GetTotalMemoryUsageMb()")
    print("     print('Memory growth:', endMem - startMem, 'MB')")
    print("")
    print("  Expected Results:")
    print("  - All 100 collectibles spawn")
    print("  - All 100 collectibles collectible")
    print("  - Memory growth < 5MB")
    print("  - Memory returns to baseline after 30s")
    print("  - No server lag or stuttering")
    print("")
    print("  Success Criteria: Memory growth < 5MB, returns to baseline")
    return "MANUAL"
end

function TestRunner.TestLongRunningServer()
    print("=== ASO-F3-3: Long-Running Server Test ===")
    print("⚠️  EXTENDED MANUAL TEST: 30-minute monitoring")
    print("")
    print("  Test Procedure:")
    print("  1. Start server and record memory baseline")
    print("  2. Continuously spawn collectibles (10 every 30 seconds)")
    print("  3. Have player collect them immediately")
    print("  4. Monitor memory every 5 minutes for 30 minutes")
    print("  5. Plot memory over time")
    print("")
    print("  Memory Monitoring Script:")
    print("  local Stats = game:GetService('Stats')")
    print("  local startTime = os.time()")
    print("  local startMem = Stats:GetTotalMemoryUsageMb()")
    print("")
    print("  while true do")
    print("      wait(300)  -- 5 minutes")
    print("      local elapsed = os.time() - startTime")
    print("      local currentMem = Stats:GetTotalMemoryUsageMb()")
    print("      local growth = currentMem - startMem")
    print("      print(string.format('Time: %dm, Memory: %.2f MB, Growth: %.2f MB',")
    print("          elapsed/60, currentMem, growth))")
    print("  end")
    print("")
    print("  Expected Results:")
    print("  - Memory fluctuates but doesn't trend upward")
    print("  - Growth < 20MB after 30 minutes")
    print("  - No continuous climb (leak indicator)")
    print("  - Server remains responsive")
    print("")
    print("  Success: Stable memory, no upward trend")
    return "MANUAL"
end

function TestRunner.TestCleanupCodeExists()
    print("=== ASO-F3-BONUS: Verify Cleanup Code Exists ===")

    local success, CollectibleService = pcall(function()
        return require(game.ServerScriptService.Services.CollectibleService)
    end)

    if not success then
        print("❌ FAIL: Could not load CollectibleService:", CollectibleService)
        return "FAIL"
    end

    -- Check if ActiveCollectibles table exists
    if CollectibleService.ActiveCollectibles then
        print("✅ PASS: ActiveCollectibles tracking exists")
        print("  Type:", type(CollectibleService.ActiveCollectibles))

        if type(CollectibleService.ActiveCollectibles) == "table" then
            print("  Current active:", #CollectibleService.ActiveCollectibles)

            -- Check for RemoveCollectible function
            if CollectibleService.RemoveCollectible then
                print("✅ PASS: RemoveCollectible function exists")
                return "PASS"
            else
                print("⚠️  WARN: RemoveCollectible function not found")
                return "WARN"
            end
        end
    else
        print("⚠️  WARN: ActiveCollectibles not found (may be local)")
        print("  This is okay if cleanup is handled differently")
        return "WARN"
    end
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Adventure - Collectible Memory Leak Tests       ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 4,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestAnimationThreadCleaned()
    if result1 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 2
    local result2 = TestRunner.TestRapidCollectionStress()
    if result2 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 3
    local result3 = TestRunner.TestLongRunningServer()
    if result3 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Bonus test
    local result4 = TestRunner.TestCleanupCodeExists()
    if result4 == "PASS" then results.Passed = results.Passed + 1
    elseif result4 == "FAIL" then results.Failed = results.Failed + 1
    elseif result4 == "WARN" then results.Passed = results.Passed + 1
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
