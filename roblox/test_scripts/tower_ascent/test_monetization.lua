--[[
    Tower Ascent - Monetization Product IDs Test
    Fix #5: Validates product IDs configured correctly
    Test Cases: TA-F5-1, TA-F5-2, TA-F5-3, TA-F5-4
]]

local TestRunner = {}

function TestRunner.TestVIPGamePassPurchase()
    print("=== TA-F5-1: VIP Game Pass Purchase ===")
    print("⚠️  MANUAL TEST: Requires Robux purchase")
    print("  1. Join with test account")
    print("  2. Purchase VIP Game Pass")
    print("  3. Check VIP status (IsVIP attribute)")
    print("  4. Collect coins and verify 2x multiplier")
    print("  Expected: VIP granted, 2x multiplier active")
    return "MANUAL"
end

function TestRunner.TestCoinPackPurchase()
    print("=== TA-F5-2: Coin Pack Purchase ===")
    print("⚠️  MANUAL TEST: Requires Robux purchase")
    print("  1. Note starting coin balance")
    print("  2. Purchase 1000 Coin Pack (Developer Product)")
    print("  3. Check final coin balance")
    print("  Expected: +1000 coins added")
    return "MANUAL"
end

function TestRunner.TestProductIDValidation()
    print("=== TA-F5-3: Product ID Validation ===")

    local success, GameConfig = pcall(function()
        return require(game.ReplicatedStorage.Shared.Config.GameConfig)
    end)

    if not success then
        print("❌ FAIL: Could not load GameConfig:", GameConfig)
        return "FAIL"
    end

    local allValid = true
    local invalidProducts = {}

    -- Check Game Passes
    if GameConfig.Monetization and GameConfig.Monetization.GamePasses then
        print("\n  Checking Game Passes:")
        for name, id in pairs(GameConfig.Monetization.GamePasses) do
            print(string.format("    %s: %d", name, id))
            if id == 0 then
                allValid = false
                table.insert(invalidProducts, "GamePass: " .. name)
            end
        end
    else
        print("⚠️  WARN: No GamePasses config found")
    end

    -- Check Developer Products
    if GameConfig.Monetization and GameConfig.Monetization.Products then
        print("\n  Checking Developer Products:")
        for name, data in pairs(GameConfig.Monetization.Products) do
            local id = data.ProductId or data.Id or 0
            print(string.format("    %s: %d", name, id))
            if id == 0 then
                allValid = false
                table.insert(invalidProducts, "Product: " .. name)
            end
        end
    else
        print("⚠️  WARN: No Products config found")
    end

    if allValid then
        print("\n✅ PASS: All product IDs configured (not 0)")
        return "PASS"
    else
        print("\n❌ FAIL: Some product IDs not configured:")
        for _, product in ipairs(invalidProducts) do
            print("  -", product)
        end
        return "FAIL"
    end
end

function TestRunner.TestPurchaseFailureHandling()
    print("=== TA-F5-4: Purchase Failure Handling ===")
    print("⚠️  COMPLEX MANUAL TEST: Requires purchase simulation")
    print("  1. Attempt purchase with insufficient Robux")
    print("  2. Cancel purchase prompt")
    print("  3. Simulate MarketplaceService error")
    print("  Expected: Graceful error, no crash, user notified")
    return "MANUAL"
end

function TestRunner.RunAllTests()
    print("\n╔═══════════════════════════════════════════════════╗")
    print("║  Tower Ascent - Monetization Tests               ║")
    print("╚═══════════════════════════════════════════════════╝\n")

    local results = {
        Total = 4,
        Passed = 0,
        Failed = 0,
        Skipped = 0,
        Manual = 0
    }

    -- Test 1
    local result1 = TestRunner.TestVIPGamePassPurchase()
    if result1 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 2
    local result2 = TestRunner.TestCoinPackPurchase()
    if result2 == "MANUAL" then results.Manual = results.Manual + 1 end

    print("")

    -- Test 3
    local result3 = TestRunner.TestProductIDValidation()
    if result3 == "PASS" then results.Passed = results.Passed + 1
    elseif result3 == "FAIL" then results.Failed = results.Failed + 1
    end

    print("")

    -- Test 4
    local result4 = TestRunner.TestPurchaseFailureHandling()
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
