--[[
    Test Data Initializer - Sets up test accounts with various data states
    Creates realistic test scenarios for comprehensive testing
    Usage: Run in ServerScriptService to initialize test data
]]

local TestDataInitializer = {}

-- Test account configurations
local TEST_ACCOUNTS = {
    {
        Name = "TestUser1",
        Description = "New player - Fresh start",
        Data = {
            Coins = 0,
            Level = 1,
            Experience = 0,
            Checkpoints = {},
            Pets = {},
            UnlockedWorlds = {"World1"},
            VIP = false
        }
    },
    {
        Name = "TestUser2",
        Description = "Mid-game progression",
        Data = {
            Coins = 1000,
            Level = 10,
            Experience = 5000,
            Checkpoints = {["World1"] = 5, ["World2"] = 2},
            Pets = {"BasicPet1", "BasicPet2", "ForestPet1"},
            UnlockedWorlds = {"World1", "World2"},
            VIP = false
        }
    },
    {
        Name = "TestUser3",
        Description = "Near max coins (cap testing)",
        Data = {
            Coins = 999999900,  -- 100 below 1 billion cap
            Level = 50,
            Experience = 100000,
            Checkpoints = {["World1"] = 10, ["World2"] = 10, ["World3"] = 10},
            Pets = {"LegendaryPet1", "LegendaryPet2"},
            UnlockedWorlds = {"World1", "World2", "World3", "World4"},
            VIP = false
        }
    },
    {
        Name = "TestUser4",
        Description = "VIP player - Mid-game",
        Data = {
            Coins = 500,
            Level = 15,
            Experience = 7500,
            Checkpoints = {["World1"] = 10, ["World2"] = 5},
            Pets = {"VIPPet1", "BasicPet1", "BasicPet2"},
            UnlockedWorlds = {"World1", "World2", "VIPWorld"},
            VIP = true
        }
    },
    {
        Name = "TestUser5",
        Description = "VIP player - Late game",
        Data = {
            Coins = 10000,
            Level = 99,
            Experience = 500000,
            Checkpoints = {["World1"] = 10, ["World2"] = 10, ["World3"] = 10, ["World4"] = 10},
            Pets = {"LegendaryPet1", "LegendaryPet2", "VIPPet1", "FirePet1", "CrystalPet1"},
            UnlockedWorlds = {"World1", "World2", "World3", "World4", "VIPWorld"},
            VIP = true
        }
    }
}

--[[
    Initialize test data for a player
]]
function TestDataInitializer.InitializePlayer(player, testConfig)
    print(string.format("[TestDataInit] Initializing %s: %s", player.Name, testConfig.Description))

    local success, DataService = pcall(function()
        return require(game.ServerScriptService.Services.DataService)
    end)

    if not success then
        warn("[TestDataInit] Could not load DataService:", DataService)
        return false
    end

    -- Set each data field
    for key, value in pairs(testConfig.Data) do
        local setSuccess, error = pcall(function()
            DataService.SetPlayerData(player, key, value)
        end)

        if setSuccess then
            print(string.format("  ✓ Set %s: %s", key, tostring(value)))
        else
            warn(string.format("  ✗ Failed to set %s: %s", key, error))
        end
    end

    -- Set VIP attribute
    player:SetAttribute("IsVIP", testConfig.Data.VIP)

    print(string.format("[TestDataInit] ✅ %s initialized successfully", player.Name))
    return true
end

--[[
    Initialize all test accounts when they join
]]
function TestDataInitializer.SetupAutoInitialization()
    local Players = game:GetService("Players")

    Players.PlayerAdded:Connect(function(player)
        wait(1)  -- Wait for profile to load

        -- Check if this is a test account
        for _, testConfig in ipairs(TEST_ACCOUNTS) do
            if player.Name == testConfig.Name then
                TestDataInitializer.InitializePlayer(player, testConfig)
                return
            end
        end
    end)

    print("[TestDataInit] Auto-initialization enabled for test accounts")
end

--[[
    Initialize all currently connected test players
]]
function TestDataInitializer.InitializeAllTestPlayers()
    local Players = game:GetService("Players")

    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║   Test Data Initializer                                       ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print("")

    local initialized = 0
    local failed = 0

    for _, player in ipairs(Players:GetPlayers()) do
        for _, testConfig in ipairs(TEST_ACCOUNTS) do
            if player.Name == testConfig.Name then
                if TestDataInitializer.InitializePlayer(player, testConfig) then
                    initialized = initialized + 1
                else
                    failed = failed + 1
                end
                break
            end
        end
    end

    print("")
    print("╔═══════════════════════════════════════════════════════════════╗")
    print(string.format("║  Initialization Complete: %d success, %d failed", initialized, failed))
    print("╚═══════════════════════════════════════════════════════════════╝")
end

--[[
    Print test account configuration guide
]]
function TestDataInitializer.PrintGuide()
    print("\n╔═══════════════════════════════════════════════════════════════╗")
    print("║   Test Account Configuration Guide                            ║")
    print("╚═══════════════════════════════════════════════════════════════╝\n")

    for i, config in ipairs(TEST_ACCOUNTS) do
        print(string.format("Account %d: %s", i, config.Name))
        print(string.format("  Purpose: %s", config.Description))
        print("  Configuration:")
        for key, value in pairs(config.Data) do
            if type(value) == "table" then
                local count = 0
                for _ in pairs(value) do count = count + 1 end
                print(string.format("    %s: %d items", key, count))
            else
                print(string.format("    %s: %s", key, tostring(value)))
            end
        end
        print("")
    end

    print("To initialize these accounts:")
    print("  1. Create Roblox accounts with these exact names")
    print("  2. Join your test server")
    print("  3. Run: TestDataInitializer.InitializeAllTestPlayers()")
    print("")
    print("Or enable auto-initialization:")
    print("  TestDataInitializer.SetupAutoInitialization()")
    print("")
end

--[[
    Reset test player to baseline
]]
function TestDataInitializer.ResetPlayer(player)
    print(string.format("[TestDataInit] Resetting %s to baseline", player.Name))

    -- Find test config
    local testConfig = nil
    for _, config in ipairs(TEST_ACCOUNTS) do
        if player.Name == config.Name then
            testConfig = config
            break
        end
    end

    if not testConfig then
        warn("[TestDataInit] Not a test account:", player.Name)
        return false
    end

    -- Re-initialize
    return TestDataInitializer.InitializePlayer(player, testConfig)
end

--[[
    Create stress test data (many pets, high values)
]]
function TestDataInitializer.CreateStressTestData(player)
    print(string.format("[TestDataInit] Creating stress test data for %s", player.Name))

    local success, DataService = pcall(function()
        return require(game.ServerScriptService.Services.DataService)
    end)

    if not success then
        warn("[TestDataInit] Could not load DataService")
        return false
    end

    -- Create 100 pets
    local pets = {}
    for i = 1, 100 do
        table.insert(pets, "StressPet" .. i)
    end

    -- Set stress test data
    DataService.SetPlayerData(player, "Coins", 100000)
    DataService.SetPlayerData(player, "Pets", pets)
    DataService.SetPlayerData(player, "Level", 100)

    print(string.format("[TestDataInit] ✅ Stress test data created: 100 pets, 100K coins"))
    return true
end

-- Auto-print guide when module loads
TestDataInitializer.PrintGuide()

return TestDataInitializer
