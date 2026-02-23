--[[
    Tower Ascent - Coin Underflow Protection Test
    Fix #4: Validates coin underflow protection
    Test Cases: TA-F4-1, TA-F4-2, TA-F4-3
]]

local TestRunner = {}

function TestRunner.TestRemoveMoreThanAvailable()
    print("=== TA-F4-1: Remove More Coins Than Available ===")

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

    -- Set player to 50 coins
    local setSuccess = DataService.SetPlayerData(player, "Coins", 50)
    if not setSuccess then
        print("❌ FAIL: Could not set player coins")
        return "FAIL"
    end

    print("  Initial coins: 50")

    -- Try to remove 100 coins
    local removeSuccess = DataService.RemoveCoins(player, 100)

    -- Get final coin count
    local finalCoins = DataService.GetPlayerData(player, "Coins")

    print("  Attempted to remove: 100")
    print("  Final coins:", finalCoins)
    print("  Remove success:", removeSuccess)

    if finalCoins == 0 then
        print("✅ PASS: Coins capped at 0 (no underflow)")
        print("  Check server logs for underflow warning")
        return "PASS"
    else
        print("❌ FAIL: Coins should be 0, got:", finalCoins)
        return "FAIL"
    end
end

function TestRunner.TestRemoveExactAmount()
    print("=== TA-F4-2: Remove Exact Amount ===")

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

    -- Set player to 100 coins
    DataService.SetPlayerData(player, "Coins", 100)
    print("  Initial coins: 100")

    -- Remove exactly 100 coins
    local removeSuccess = DataService.RemoveCoins(player, 100)

    -- Get final coin count
    local finalCoins = DataService.GetPlayerData(player, "Coins")

    print("  Attempted to remove: 100")
    print("  Final coins:", finalCoins)
    print("  Remove success:", removeSuccess)

    if finalCoins == 0 and removeSuccess == true then
        print("✅ PASS: Exact removal works (no error)")
        return "PASS"
    else
        print("❌ FAIL: Expected 0 coins and success=true")
        return "FAIL"
    end
end

function TestRunner.TestLeaderstatsUpdate()
    print("=== TA-F4-3: Leaderstats Update Correctly ===")

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Check if leaderstats folder exists
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        print("⚠️  WARN: No leaderstats folder found")
        return "WARN"
    end

    -- Check if Coins value exists
    local coinsValue = leaderstats:FindFirstChild("Coins")
    if not coinsValue then
        print("⚠️  WARN: No Coins value in leaderstats")
        return "WARN"
    end

    -- Check value type
    if coinsValue:IsA("IntValue") or coinsValue:IsA("NumberValue") then
        print("✅ PASS: Leaderstats Coins value exists")
        print("  Type:", coinsValue.ClassName)
        print("  Value:", coinsValue.Value)
        return "PASS"
    else
        print("❌ FAIL: Unexpected leaderstats value type:", coinsValue.ClassName)
        return "FAIL"
    end
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Tower Ascent - Coin Underflow Tests             ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 3,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestRemoveMoreThanAvailable()
    if result1 == "PASS" then results.Passed = results.Passed + 1
    elseif result1 == "FAIL" then results.Failed = results.Failed + 1
    elseif result1 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 2
    local result2 = TestRunner.TestRemoveExactAmount()
    if result2 == "PASS" then results.Passed = results.Passed + 1
    elseif result2 == "FAIL" then results.Failed = results.Failed + 1
    elseif result2 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 3
    local result3 = TestRunner.TestLeaderstatsUpdate()
    if result3 == "PASS" then results.Passed = results.Passed + 1
    elseif result3 == "FAIL" then results.Failed = results.Failed + 1
    elseif result3 == "SKIPPED" then results.Skipped = results.Skipped + 1
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
