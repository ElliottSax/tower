--[[
	CustomerService.lua - Restaurant Empire
	NPC customer spawning, AI behavior, ordering
]]
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local GC = require(RS.Shared.Config.GameConfig)
local CustomerService = {}

function CustomerService.Init()
	print("[CustomerService] Initialized")
end

function CustomerService.StartCustomerLoop(player)
	task.spawn(function()
		while player.Parent do
			task.wait(10) -- Customer arrives every 10 seconds
			local DS = require(SSS.Services.DataService)
			local data = DS.GetFullData(player); if not data then continue end

			local RestaurantService = require(SSS.Services.RestaurantService)
			local tables = RestaurantService.GetTableCount(player)
			if tables < 1 then continue end

			-- Higher star rating = more customers
			local customerChance = 0.3 + data.StarRating * 0.15
			if math.random() > customerChance then continue end

			-- Pick random unlocked recipe for order
			if #data.UnlockedRecipes == 0 then continue end
			local recipeName = data.UnlockedRecipes[math.random(#data.UnlockedRecipes)]

			local recipe = nil
			for _, r in ipairs(GC.Recipes) do if r.Name == recipeName then recipe = r; break end end
			if not recipe then continue end

			-- Notify client of customer order
			local re = RS:FindFirstChild("RemoteEvents")
			if re then
				local co = re:FindFirstChild("CustomerOrder")
				if co then co:FireClient(player, {
					Recipe = recipeName,
					Patience = 30 + data.StarRating * 5,
					Tip = math.floor(recipe.Price * 0.2 * data.StarRating),
				}) end
			end

			-- Auto-cook if pass owned and staff available
			if data.GamePasses and data.GamePasses.AutoCook then
				local hasChef = false
				for _, s in ipairs(data.Staff) do if s.Type == "cook" then hasChef = true; break end end
				if hasChef then
					task.wait(recipe.CookTime * 0.5) -- Staff cooks faster
					DS.AddCoins(player, math.floor(recipe.Price * 0.8))
					DS.AddXP(player, recipe.Quality * 5)
					data.CustomersServed = data.CustomersServed + 1
				end
			end
		end
	end)
end

return CustomerService
