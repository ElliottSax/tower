--[[
    Tower Ascent - VIP Race Condition Test
    Fix #3: Validates VIP race condition fix
    Test Cases: TA-F3-1, TA-F3-2, TA-F3-3, TA-F3-4
]]

local TestRunner = {}

function TestRunner.TestVIPGets2xCoins()
    print("=== TA-F3-1: VIP Player Gets 2x Coins ===")
    print("⚠️  MANUAL TEST: Requires VIP player account")
    print("  1. Join as VIP player (has VIP Game Pass)")
    print("  2. Note starting coin balance")
    print("  3. Collect 100 coins worth of items")
    print("  4. Check final balance")
    print("  Expected: 200 coins added (2x multiplier)")
    return "MANUAL"
end

function TestRunner.TestNonVIPGets1xCoins()
    print("=== TA-F3-2: Non-VIP Gets 1x Coins ===")
    print("⚠️  MANUAL TEST: Requires non-VIP player account")
    print("  1. Join as non-VIP player (no Game Pass)")
    print("  2. Note starting coin balance")
    print("  3. Collect 100 coins worth of items")
    print("  4. Check final balance")
    print("  Expected: 100 coins added (1x multiplier)")
    return "MANUAL"
end

function TestRunner.TestVIPStatusCached()
    print("=== TA-F3-3: VIP Status Cached ===")

    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]

    if not player then
        print("⏭️  SKIP: No players in server")
        return "SKIPPED"
    end

    -- Check for VIP attribute
    local isVIP = player:GetAttribute("IsVIP")
    local isPending = player:GetAttribute("VIPCheckPending")

    print("  Player:", player.Name)
    print("  IsVIP:", isVIP)
    print("  VIPCheckPending:", isPending)

    if isVIP ~= nil then
        print("✅ PASS: VIP status cached (not nil)")
        return "PASS"
    elseif isPending == true then
        print("⚠️  WARN: VIP check still pending")
        return "WARN"
    else
        print("❌ FAIL: VIP status not set")
        return "FAIL"
    end
end

function TestRunner.TestPendingStatePreventsZeroCoins()
    print("=== TA-F3-4: Pending State Prevents 0 Coins ===")
    print("⚠️  COMPLEX MANUAL TEST: Requires VIP service manipulation")
    print("  1. Join as VIP player")
    print("  2. Temporarily disable VIP service (mock failure)")
    print("  3. Collect coins while VIPCheckPending = true")
    print("  4. Wait for VIP check to complete")
    print("  5. Verify coins accumulated during pending")
    print("  6. Verify 2x multiplier applied retroactively")
    print("  Expected: Coins not lost during pending state")
    return "MANUAL"
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Tower Ascent - VIP Race Condition Tests         ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 4,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestVIPGets2xCoins()
    if result1 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 2
    local result2 = TestRunner.TestNonVIPGets1xCoins()
    if result2 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 3
    local result3 = TestRunner.TestVIPStatusCached()
    if result3 == "PASS" then results.Passed = results.Passed + 1
    elseif result3 == "FAIL" then results.Failed = results.Failed + 1
    elseif result3 == "SKIPPED" then results.Skipped = results.Skipped + 1
    end

    print("")

    -- Test 4
    local result4 = TestRunner.TestPendingStatePreventsZeroCoins()
    if result4 == "MANUAL" then results.Manual = results.Manual + 1 end

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
