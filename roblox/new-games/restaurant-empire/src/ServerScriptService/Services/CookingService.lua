--[[
	CookingService.lua - Restaurant Empire
	Recipe cooking, quality, timing mini-game
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local CookingService = {}

function CookingService.Init()
	local DS = require(SSS.Services.DataService)
	local re = RS:WaitForChild("RemoteEvents")

	re:WaitForChild("CookDish").OnServerEvent:Connect(function(player, recipeName, timing)
		if type(recipeName) ~= "string" then return end
		local data = DS.GetFullData(player); if not data then return end

		-- Check recipe unlocked
		local unlocked = false
		for _, r in ipairs(data.UnlockedRecipes) do if r == recipeName then unlocked = true; break end end
		if not unlocked then return end

		local recipe = nil
		for _, r in ipairs(GC.Recipes) do if r.Name == recipeName then recipe = r; break end end
		if not recipe then return end

		-- Quality based on timing (0-1, 1 = perfect)
		local quality = 1
		if type(timing) == "number" then quality = math.clamp(timing, 0.3, 1) end

		-- Staff skill bonus
		local skillBonus = 1
		for _, staff in ipairs(data.Staff) do
			if staff.Type == "cook" then skillBonus = skillBonus + staff.Skill * 0.1 end
		end

		local finalQuality = math.floor(recipe.Quality * quality * skillBonus * 100) / 100
		local earnings = math.floor(recipe.Price * quality * skillBonus)

		DS.AddCoins(player, earnings)
		DS.AddXP(player, math.floor(recipe.Quality * 10))
		data.CustomersServed = data.CustomersServed + 1

		-- Update satisfaction
		data.Satisfaction = math.floor((data.Satisfaction * 0.95 + finalQuality * 20 * 0.05))
		data.StarRating = math.clamp(math.floor(data.Satisfaction / GC.StarRating.ThresholdPerStar), 1, 5)

		local ls = player:FindFirstChild("leaderstats")
		if ls then local s = ls:FindFirstChild("Stars"); if s then s.Value = data.StarRating end end

		local reEvents = RS:FindFirstChild("RemoteEvents")
		if reEvents then
			local cr = reEvents:FindFirstChild("CookResult")
			if cr then cr:FireClient(player, { Recipe = recipeName, Quality = finalQuality, Earnings = earnings }) end
		end
	end)
end

return CookingService
