--[[
	GameConfig.lua - Restaurant Empire
	Restaurant tycoon - cooking, customers, staff, multi-location
]]
local GameConfig = {}

GameConfig.Recipes = {
	{ Name = "Burger", Cuisine = "American", CookTime = 3, Quality = 1, Price = 10, UnlockLevel = 1 },
	{ Name = "Fries", Cuisine = "American", CookTime = 2, Quality = 1, Price = 5, UnlockLevel = 1 },
	{ Name = "Pizza", Cuisine = "Italian", CookTime = 5, Quality = 2, Price = 20, UnlockLevel = 3 },
	{ Name = "Pasta", Cuisine = "Italian", CookTime = 4, Quality = 2, Price = 18, UnlockLevel = 4 },
	{ Name = "Sushi Roll", Cuisine = "Japanese", CookTime = 6, Quality = 3, Price = 35, UnlockLevel = 8 },
	{ Name = "Ramen", Cuisine = "Japanese", CookTime = 7, Quality = 3, Price = 30, UnlockLevel = 10 },
	{ Name = "Tacos", Cuisine = "Mexican", CookTime = 3, Quality = 2, Price = 15, UnlockLevel = 5 },
	{ Name = "Steak", Cuisine = "French", CookTime = 8, Quality = 4, Price = 50, UnlockLevel = 15 },
	{ Name = "Lobster", Cuisine = "French", CookTime = 10, Quality = 5, Price = 80, UnlockLevel = 20 },
	{ Name = "Peking Duck", Cuisine = "Chinese", CookTime = 12, Quality = 5, Price = 70, UnlockLevel = 18 },
	{ Name = "Pad Thai", Cuisine = "Thai", CookTime = 5, Quality = 3, Price = 25, UnlockLevel = 12 },
	{ Name = "Curry", Cuisine = "Indian", CookTime = 6, Quality = 3, Price = 22, UnlockLevel = 9 },
}

GameConfig.Furniture = {
	{ Name = "Basic Table", Type = "table", Seats = 2, Cost = 100, Satisfaction = 1 },
	{ Name = "Round Table", Type = "table", Seats = 4, Cost = 500, Satisfaction = 1.2 },
	{ Name = "VIP Booth", Type = "table", Seats = 4, Cost = 2000, Satisfaction = 1.5 },
	{ Name = "Grand Table", Type = "table", Seats = 8, Cost = 10000, Satisfaction = 2 },
	{ Name = "Potted Plant", Type = "decor", Cost = 200, Satisfaction = 1.05 },
	{ Name = "Chandelier", Type = "decor", Cost = 5000, Satisfaction = 1.15 },
	{ Name = "Fountain", Type = "decor", Cost = 15000, Satisfaction = 1.25 },
	{ Name = "Basic Kitchen", Type = "kitchen", CookSpeed = 1, Cost = 0, Stations = 1 },
	{ Name = "Pro Kitchen", Type = "kitchen", CookSpeed = 1.5, Cost = 10000, Stations = 2 },
	{ Name = "Master Kitchen", Type = "kitchen", CookSpeed = 2, Cost = 50000, Stations = 3 },
	{ Name = "Ultimate Kitchen", Type = "kitchen", CookSpeed = 3, Cost = 200000, Stations = 4 },
}

GameConfig.Staff = {
	{ Name = "Trainee Cook", Type = "cook", Skill = 1, Salary = 50, Cost = 500 },
	{ Name = "Line Cook", Type = "cook", Skill = 2, Salary = 100, Cost = 2000 },
	{ Name = "Chef", Type = "cook", Skill = 3, Salary = 250, Cost = 10000 },
	{ Name = "Master Chef", Type = "cook", Skill = 5, Salary = 500, Cost = 50000 },
	{ Name = "Waiter", Type = "waiter", Skill = 1, Salary = 30, Cost = 300 },
	{ Name = "Senior Waiter", Type = "waiter", Skill = 2, Salary = 80, Cost = 3000 },
	{ Name = "Cleaner", Type = "cleaner", Skill = 1, Salary = 20, Cost = 200 },
}

GameConfig.Locations = {
	{ Name = "Food Cart", UnlockCost = 0, MaxTables = 3, Theme = "street" },
	{ Name = "Diner", UnlockCost = 50000, MaxTables = 8, Theme = "casual" },
	{ Name = "Italian Restaurant", UnlockCost = 200000, MaxTables = 12, Theme = "italian" },
	{ Name = "Sushi Bar", UnlockCost = 500000, MaxTables = 10, Theme = "japanese" },
	{ Name = "Fine Dining", UnlockCost = 2000000, MaxTables = 15, Theme = "luxury" },
	{ Name = "Hotel Restaurant", UnlockCost = 10000000, MaxTables = 20, Theme = "grand" },
}

GameConfig.StarRating = { ThresholdPerStar = 20 } -- satisfaction score per star

GameConfig.GamePasses = {
	AutoCook = { Id = 0, Name = "Auto Cook", Price = 199, Description = "Staff cook automatically" },
	DoubleTips = { Id = 0, Name = "2x Tips", Price = 249, Description = "Double tips from customers" },
	VIPTheme = { Id = 0, Name = "VIP Restaurant Theme", Price = 399, Description = "Exclusive luxury decor" },
	PremiumRecipes = { Id = 0, Name = "Premium Recipes", Price = 299, Description = "5 exclusive premium recipes" },
}

GameConfig.DevProducts = {
	Coins5000 = { Id = 0, Name = "5,000 Coins", Price = 49, Amount = 5000 },
	Coins50000 = { Id = 0, Name = "50,000 Coins", Price = 99, Amount = 50000 },
	Coins500000 = { Id = 0, Name = "500,000 Coins", Price = 199, Amount = 500000 },
	InstantStaff = { Id = 0, Name = "Instant Staff Training", Price = 79, Description = "Max out staff skill instantly" },
}

GameConfig.DefaultData = {
	Coins = 100, TotalCoinsEarned = 0, Level = 1, XP = 0,
	UnlockedLocations = { "Food Cart" }, CurrentLocation = "Food Cart",
	UnlockedRecipes = { "Burger", "Fries" },
	Furniture = {}, Staff = {}, CustomersServed = 0,
	StarRating = 1, Satisfaction = 50, PrestigeLevel = 0,
	LastLoginDate = "", LoginStreak = 0, GamePasses = {},
}

return GameConfig
