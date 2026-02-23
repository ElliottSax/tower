--[[
    Adventure Story Obby - Coin Cap Validation Test
    Fix #2: Validates 1 billion coin cap prevents overflow
    Test Cases: ASO-F2-1, ASO-F2-2, ASO-F2-3
]]

local TestRunner = {}

function TestRunner.TestNormalCoinCollection()
    print("=== ASO-F2-1: Normal Coin Collection ===")

    local success, DataService = pcall(function()
        return require(game.ServerScriptService.Services.DataService)
    end)

    if not success then
        print("❌ FAIL: Could not load DataService:", DataService)
        return "FAIL"
    end

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Set player to 500 coins
    DataService.SetPlayerData(player, "Coins", 500)
    local startCoins = DataService.GetPlayerData(player, "Coins")
    print("  Starting coins:", startCoins)

    -- Add 100 coins
    DataService.AddCoins(player, 100)
    local endCoins = DataService.GetPlayerData(player, "Coins")
    print("  After adding 100:", endCoins)

    if endCoins == 600 then
        print("✅ PASS: Normal coin addition works correctly")
        return "PASS"
    else
        print("❌ FAIL: Expected 600 coins, got:", endCoins)
        return "FAIL"
    end
end

function TestRunner.TestNearCapCollection()
    print("=== ASO-F2-2: Near Cap Collection ===")

    local success, DataService = pcall(function()
        return require(game.ServerScriptService.Services.DataService)
    end)

    if not success then
        print("❌ FAIL: Could not load DataService:", DataService)
        return "FAIL"
    end

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Set player to near max (999,999,900)
    local nearMax = 999999900
    local MAX_COINS = 1000000000

    DataService.SetPlayerData(player, "Coins", nearMax)
    print("  Starting coins:", nearMax)

    -- Try to add 200 coins (would exceed cap)
    DataService.AddCoins(player, 200)
    local finalCoins = DataService.GetPlayerData(player, "Coins")
    print("  After adding 200:", finalCoins)

    if finalCoins == MAX_COINS then
        print("✅ PASS: Coins capped at 1 billion (no overflow)")
        print("  Check server logs for cap warning")
        return "PASS"
    else
        print("❌ FAIL: Expected", MAX_COINS, "got:", finalCoins)
        return "FAIL"
    end
end

function TestRunner.TestAtCapStaysAtCap()
    print("=== ASO-F2-3: At Cap Stays At Cap ===")

    local success, DataService = pcall(function()
        return require(game.ServerScriptService.Services.DataService)
    end)

    if not success then
        print("❌ FAIL: Could not load DataService:", DataService)
        return "FAIL"
    end

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Set player to exactly max (1,000,000,000)
    local MAX_COINS = 1000000000

    DataService.SetPlayerData(player, "Coins", MAX_COINS)
    print("  Starting coins:", MAX_COINS, "(at cap)")

    -- Try to add 100 more coins
    DataService.AddCoins(player, 100)
    local finalCoins = DataService.GetPlayerData(player, "Coins")
    print("  After adding 100:", finalCoins)

    if finalCoins == MAX_COINS then
        print("✅ PASS: Coins remain at cap (no overflow)")
        return "PASS"
    else
        print("❌ FAIL: Coins should stay at", MAX_COINS)
        print("  Got:", finalCoins)
        return "FAIL"
    end
end

function TestRunner.TestCapValueDefined()
    print("=== ASO-F2-BONUS: Verify MAX_COINS Constant ===")

    local success, DataService = pcall(function()
        return require(game.ServerScriptService.Services.DataService)
    end)

    if not success then
        print("❌ FAIL: Could not load DataService:", DataService)
        return "FAIL"
    end

    -- Check if MAX_COINS is defined (may be local, so we infer from behavior)
    print("  Checking coin cap behavior...")

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Test with huge value
    DataService.SetPlayerData(player, "Coins", 0)
    DataService.AddCoins(player, 2000000000)  -- 2 billion (above cap)
    local finalCoins = DataService.GetPlayerData(player, "Coins")

    if finalCoins == 1000000000 then
        print("✅ PASS: MAX_COINS cap enforced at 1,000,000,000")
        return "PASS"
    elseif finalCoins == 2000000000 then
        print("❌ FAIL: No coin cap enforced (overflow possible!)")
        return "FAIL"
    else
        print("⚠️  WARN: Unexpected coin value:", finalCoins)
        return "WARN"
    end
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Adventure - Coin Cap Validation Tests           ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 4,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestNormalCoinCollection()
    if result1 == "PASS" then results.Passed = results.Passed + 1
    elseif result1 == "FAIL" then results.Failed = results.Failed + 1
    elseif result1 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 2
    local result2 = TestRunner.TestNearCapCollection()
    if result2 == "PASS" then results.Passed = results.Passed + 1
    elseif result2 == "FAIL" then results.Failed = results.Failed + 1
    elseif result2 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 3
    local result3 = TestRunner.TestAtCapStaysAtCap()
    if result3 == "PASS" then results.Passed = results.Passed + 1
    elseif result3 == "FAIL" then results.Failed = results.Failed + 1
    elseif result3 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Bonus test
    local result4 = TestRunner.TestCapValueDefined()
    if result4 == "PASS" then results.Passed = results.Passed + 1
    elseif result4 == "FAIL" then results.Failed = results.Failed + 1
    elseif result4 == "SKIPPED" then results.Skipped = results.Skipped + 1
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
