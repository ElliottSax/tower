--[[
    Master Test Runner - Roblox Games Portfolio
    Executes all validation tests across all 5 games
    Total: 60 test cases across 17 critical fixes
]]

local MasterTestRunner = {}

-- Test registry
local TestModules = {
    TowerAscent = {
        "test_debug_mode",
        "test_authentication",
        "test_vip_race",
        "test_coin_underflow",
        "test_monetization"
    },
    SpeedRunUniverse = {
        "test_speedrun_validation",
        "test_player_cleanup",
        "test_ghost_compression",
        "test_leaderboard"
    },
    AdventureStoryObby = {
        "test_checkpoint_validation",
        "test_coin_cap",
        "test_collectible_memory"
    },
    PetCollectorSim = {
        "test_negative_coins",
        "test_trading_disabled",
        "test_secure_remotes"
    },
    DimensionHopper = {
        "test_fragment_memory"
    }
}

function MasterTestRunner.RunAllTests()
    print("\n")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║                                                               ║")
    print("║        Master Test Suite - Roblox Games Portfolio            ║")
    print("║                                                               ║")
    print("║  Testing 17 Critical Fixes Across 5 Games                    ║")
    print("║  Total Test Cases: 60                                        ║")
    print("║                                                               ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print("")

    local overallResults = {
        Games = 0,
        Modules = 0,
        TotalTests = 0,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0,
        StartTime = os.time()
    }

    -- Run Tower Ascent tests
    print("\n" .. string.rep("=", 65))
    print("GAME 1/5: TOWER ASCENT")
    print(string.rep("=", 65))
    local taResults = MasterTestRunner.RunGameTests("TowerAscent", "tower_ascent")
    overallResults.Games = overallResults.Games + 1
    overallResults.Modules = overallResults.Modules + #TestModules.TowerAscent
    MasterTestRunner.MergeResults(overallResults, taResults)

    -- Run Speed Run Universe tests
    print("\n" .. string.rep("=", 65))
    print("GAME 2/5: SPEED RUN UNIVERSE")
    print(string.rep("=", 65))
    local sruResults = MasterTestRunner.RunGameTests("SpeedRunUniverse", "speed_run_universe")
    overallResults.Games = overallResults.Games + 1
    overallResults.Modules = overallResults.Modules + #TestModules.SpeedRunUniverse
    MasterTestRunner.MergeResults(overallResults, sruResults)

    -- Run Adventure Story Obby tests
    print("\n" .. string.rep("=", 65))
    print("GAME 3/5: ADVENTURE STORY OBBY")
    print(string.rep("=", 65))
    local asoResults = MasterTestRunner.RunGameTests("AdventureStoryObby", "adventure_story_obby")
    overallResults.Games = overallResults.Games + 1
    overallResults.Modules = overallResults.Modules + #TestModules.AdventureStoryObby
    MasterTestRunner.MergeResults(overallResults, asoResults)

    -- Run Pet Collector Sim tests
    print("\n" .. string.rep("=", 65))
    print("GAME 4/5: PET COLLECTOR SIM")
    print(string.rep("=", 65))
    local pcsResults = MasterTestRunner.RunGameTests("PetCollectorSim", "pet_collector_sim")
    overallResults.Games = overallResults.Games + 1
    overallResults.Modules = overallResults.Modules + #TestModules.PetCollectorSim
    MasterTestRunner.MergeResults(overallResults, pcsResults)

    -- Run Dimension Hopper tests
    print("\n" .. string.rep("=", 65))
    print("GAME 5/5: DIMENSION HOPPER")
    print(string.rep("=", 65))
    local dhResults = MasterTestRunner.RunGameTests("DimensionHopper", "dimension_hopper")
    overallResults.Games = overallResults.Games + 1
    overallResults.Modules = overallResults.Modules + #TestModules.DimensionHopper
    MasterTestRunner.MergeResults(overallResults, dhResults)

    -- Calculate duration
    local endTime = os.time()
    local duration = endTime - overallResults.StartTime

    -- Print final summary
    MasterTestRunner.PrintFinalSummary(overallResults, duration)

    return overallResults
end

function MasterTestRunner.RunGameTests(gameName, folderName)
    local gameResults = {
        Game = gameName,
        TotalTests = 0,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    local modules = TestModules[gameName]
    if not modules then
        warn("No test modules found for game:", gameName)
        return gameResults
    end

    for _, moduleName in ipairs(modules) do
        local success, testModule = pcall(function()
            return require(script.Parent[folderName][moduleName])
        end)

        if success and testModule.RunAllTests then
            print("\nRunning:", moduleName)
            local results = testModule.RunAllTests()

            if results then
                gameResults.TotalTests = gameResults.TotalTests + (results.Total or 0)
                gameResults.Passed = gameResults.Passed + (results.Passed or 0)
                gameResults.Failed = gameResults.Failed + (results.Failed or 0)
                gameResults.Skipped = gameResults.Skipped + (results.Skipped or 0)
                gameResults.Manual = gameResults.Manual + (results.Manual or 0)
            end
        else
            warn("Failed to load or run test module:", moduleName, testModule)
        end
    end

    return gameResults
end

function MasterTestRunner.MergeResults(overall, game)
    overall.TotalTests = overall.TotalTests + game.TotalTests
    overall.Passed = overall.Passed + game.Passed
    overall.Failed = overall.Failed + game.Failed
    overall.Skipped = overall.Skipped + game.Skipped
    overall.Manual = overall.Manual + game.Manual
end

function MasterTestRunner.PrintFinalSummary(results, duration)
    print("\n\n")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║                                                               ║")
    print("║                  FINAL TEST RESULTS SUMMARY                   ║")
    print("║                                                               ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print("")
    print(string.format("  Games Tested:       %d/5", results.Games))
    print(string.format("  Test Modules Run:   %d", results.Modules))
    print(string.format("  Total Test Cases:   %d", results.TotalTests))
    print("")
    print(string.format("  ✅ Passed:          %d (%.1f%%)", results.Passed, (results.Passed / results.TotalTests) * 100))
    print(string.format("  ❌ Failed:          %d (%.1f%%)", results.Failed, (results.Failed / results.TotalTests) * 100))
    print(string.format("  ⏭️  Skipped:         %d (%.1f%%)", results.Skipped, (results.Skipped / results.TotalTests) * 100))
    print(string.format("  ✋ Manual Required: %d (%.1f%%)", results.Manual, (results.Manual / results.TotalTests) * 100))
    print("")
    print(string.format("  Duration:           %d seconds (%.1f minutes)", duration, duration / 60))
    print("")

    -- Determine overall status
    local status = "PASS"
    local statusEmoji = "✅"

    if results.Failed > 0 then
        status = "FAIL"
        statusEmoji = "❌"
    elseif results.Passed == 0 then
        status = "NO TESTS RUN"
        statusEmoji = "⚠️ "
    end

    print("╔═══════════════════════════════════════════════════════════════╗")
    print(string.format("║  Overall Status: %s %s", statusEmoji, status))
    print("╚═══════════════════════════════════════════════════════════════╝")
    print("")

    -- Recommendations
    if results.Failed > 0 then
        print("⚠️  CRITICAL: Fix all failed tests before proceeding to production")
    end

    if results.Manual > 0 then
        print("ℹ️  INFO: Manual tests require human testing in Roblox Studio/Server")
    end

    if results.Skipped > 0 then
        print("ℹ️  INFO: Skipped tests need proper environment (Studio vs Production)")
    end

    print("")
end

-- Auto-run if executed directly
if not _G.TestFramework then
    MasterTestRunner.RunAllTests()
end

return MasterTestRunner
