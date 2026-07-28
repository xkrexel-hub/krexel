----------------------------------------------------
-- Grow a Garden 2 - Configuration & State Module
----------------------------------------------------
local Settings = {
	AutoHarvest = false,
	AutoShovel = false,
	AutoShovelMode = "Selected", -- "Selected" or "All"
	SelectedShovelCrops = {},

	-- Auto Place Sprinkler Advanced Settings
	AutoPlaceSprinkler = false,
	SprinklerTargetMode = "Plant", -- "Plant", "Player", "Custom"
	SprinklerCustomPos = {X = 0, Y = 0, Z = 0},
	SprinklerToolMode = "All", -- "All" or "Selected"
	SelectedSprinklerTools = {},
	SprinklerCropMode = "All", -- "All" or "Selected"
	SelectedSprinklerCrops = {},
	SprinklerDelay = 1.0,
	SprinklerAutoEquip = false,

	-- Auto Water Plants Advanced Settings
	AutoWatering = false,
	WateringTargetMode = "Plant", -- "Plant", "Player", "Custom"
	WateringCustomPos = {X = 0, Y = 0, Z = 0},
	WateringToolMode = "All", -- "All" or "Selected"
	SelectedWateringTools = {},
	WateringCropMode = "All", -- "All" or "Selected"
	SelectedWateringCrops = {},
	WateringDelay = 0.5,
	WateringAutoEquip = false,

	AutoSell = false,
	AutoSellPets = false,
	AutoBuySeeds = false,
	AutoBuyGears = false,
	AutoBuyModeSeeds = "All", -- "All" or "Selected"
	AutoBuyModeGears = "All", -- "All" or "Selected"
	SelectedSeeds = {},
	SelectedGears = {},
	HarvestInterval = 0.1,
	SellInterval = 0.2,
	SelectedTab = "Main",
	SelectedRarity = "Common",
	ShopViewCategory = "Seeds", -- "Seeds" or "Gears"
	TotalHarvested = 0,
	TotalSoldBatches = 0,
	IsMinimized = false,
	IsMaximized = false,
	IsRunning = true,
	ToggleKey = Enum.KeyCode.K,
	HarvestCropMode = "All",
	HarvestCropSelected = "All Plant",
	SelectedHarvestCrops = {},
	HarvestMutationFilter = "All", -- "All", "Normal", "Gold", "Rainbow", etc
	HarvestWeightFilter = "Disabled", -- "Disabled", "Below", "Above"
	HarvestWeightThreshold = 0.0
}

return Settings
