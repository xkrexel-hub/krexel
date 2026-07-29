--[[
    🌱 Grow a Garden 2 - Ultra Landscape Multi-Tab Hub (With Real-Time Gear Shop & Auto Buy Gears)
    
    Features:
      - ⚙️ Real-Time Gear Shop Inspector & Auto Buy Gears: Scans server Gear Shop for Sheckle items (Watering Cans, Sprinklers, Fertilizers, Scythes, Shovels) with Auto Buy toggle!
      - 💰 Exact Packet Remote Event Sell: Direct zero-movement inventory sell via decompiled packet buffers!
      - 🌾 Continuous Auto Harvest: Ultra-fast background loop auto harvest!
      - 🌾 Draggable Floating Icon: Floating (🌾) icon draggable anywhere on PC Mouse & Mobile Touch!
      - 🗖 Maximize / Restore Button (🗖): Toggles between Normal Landscape & Fullscreen Maximize size!
      - 🗕 Minimize Button (-): Hides main window into draggable floating icon!
      - ❌ Close Button (X): Completely unloads script and removes GUI.
      - 🏠 MAIN   : Split-Screen View (Player Profile + Detailed Plot & Plant Mutation Detector)
      - 🌾 GARDEN : Split-Screen View (Auto Harvest Controls + Garden Plants Grid)
      - 💰 SELL   : Split-Screen View (Exact Remote Sell Controls + Backpack Items Grid)
      - 🛒 BUY    : Wide Dual-Shop View (Real-Time Seeds & Real-Time Sheckle Gear Shop)
      - 🎨 High-End Modern Glassmorphism GUI (Hotkey: 'K')
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

----------------------------------------------------
-- CONFIGURATION & TOGGLE STATES
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
	HarvestWeightThreshold = 0.0,
	MainGardenViewMode = "Grouped" -- "Grouped" or "Detailed"
}

----------------------------------------------------
-- CROP & GEAR CATALOG DATA
----------------------------------------------------
local CropCatalog = {
	Common = {"Carrot", "Blueberry", "Strawberry"},
	Uncommon = {"Apple", "Tomato", "Tulip"},
	Rare = {"Baby Cactus", "Bamboo", "Cactus", "Corn", "Horned Melon", "Pineapple"},
	Epic = {"Banana", "Coconut", "Glow Mushroom", "Grape", "Green Bean", "Mango", "Mushroom"},
	Legendary = {"Acorn", "Cherry", "Dragon Fruit", "Fire Fern", "Poison Ivy", "Sunflower", "Rocket Pop"},
	Mythic = {"Ghost Pepper", "Poison Apple", "Pomegranate", "Venom Spitter", "Venus Fly Trap"},
	Super = {"Dragon's Breath", "Hypno Bloom", "Moon Bloom", "Sun Bloom", "Star Fruit"},
	Secret = {"Eclipse Bloom"}
}

local CropCatalogNames = {
	"Acorn", "Apple", "Baby Cactus", "Bamboo", "Banana", "Blueberry", "Cactus",
	"Carrot", "Cherry", "Coconut", "Corn", "Dragon Fruit", "Dragon's Breath",
	"Eclipse Bloom", "Fire Fern", "Ghost Pepper", "Glow Mushroom", "Grape",
	"Green Bean", "Horned Melon", "Hypno Bloom", "Mango", "Moon Bloom", "Mushroom",
	"Pineapple", "Poison Apple", "Poison Ivy", "Pomegranate", "Rocket Pop",
	"Star Fruit", "Strawberry", "Sun Bloom", "Sunflower", "Tomato", "Tulip",
	"Venom Spitter", "Venus Fly Trap"
}

local CropRarityMap = {}
for rarity, cropList in pairs(CropCatalog) do
	for _, cName in ipairs(cropList) do
		CropRarityMap[cName] = rarity
	end
end

local function getCropDisplayName(cropName)
	local rarity = CropRarityMap[cropName]
	if rarity then
		return cropName .. " (" .. rarity .. ")"
	end
	return cropName
end

local SprinklerCatalogNames = {
	"Common Sprinkler",
	"Advanced Sprinkler",
	"Uncommon Sprinkler",
	"Rare Sprinkler",
	"Master Sprinkler",
	"Godly Sprinkler"
}

local WateringCanCatalogNames = {
	"Common Watering Can",
	"Super Watering Can"
}

local OfficialGearCatalog = {
	{Name = "Common Sprinkler", Price = "3,000 Sheckles"},
	{Name = "Common Watering Can", Price = "2,000 Sheckles"},
	{Name = "Sign", Price = "4,000 Sheckles"},
	{Name = "Uncommon Sprinkler", Price = "10,000 Sheckles"},
	{Name = "Rare Sprinkler", Price = "80,000 Sheckles"},
	{Name = "Trowel", Price = "1,000 Sheckles"},
	{Name = "Jump Mushroom", Price = "1,800 Sheckles"},
	{Name = "Speed Mushroom", Price = "1,500 Sheckles"},
	{Name = "Megaphone", Price = "8,000 Sheckles"},
	{Name = "Shrink Mushroom", Price = "10,000 Sheckles"},
	{Name = "Supersize Mushroom", Price = "20,000 Sheckles"},
	{Name = "Gnome", Price = "100,000 Sheckles"},
	{Name = "Flashbang", Price = "20,000 Sheckles"},
	{Name = "Basic Pot", Price = "300,000 Sheckles"},
	{Name = "Legendary Sprinkler", Price = "1,200,000 Sheckles"},
	{Name = "Invisibility Mushroom", Price = "30,000 Sheckles"},
	{Name = "Wheelbarrow", Price = "500,000 Sheckles"},
	{Name = "Player Magnet", Price = "7,000,000 Sheckles"},
	{Name = "Strawberry Sniper", Price = "13,000,000 Sheckles"},
	{Name = "Super Watering Can", Price = "1,000,000 Sheckles"},
	{Name = "Super Sprinkler", Price = "3,000,000 Sheckles"}
}

local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Super", "Secret"}

----------------------------------------------------
-- PACKET REMOTE FINDER
----------------------------------------------------
local packetRemote = nil
pcall(function()
	local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
	if sharedModules and sharedModules:FindFirstChild("Packet") then
		packetRemote = sharedModules.Packet:FindFirstChild("RemoteEvent")
	end
end)

local PacketModule = nil
pcall(function()
	local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
	if sharedModules and sharedModules:FindFirstChild("Packet") then
		PacketModule = require(sharedModules.Packet)
	end
end)

----------------------------------------------------
-- PLANT REAL NAME & MUTATION DETECTOR
----------------------------------------------------
local plantDetailsCache = setmetatable({}, { __mode = "k" })

local function resolvePlantDetails(plantModel)
	if not plantModel then return "Crop Plant", "Normal", "Normal" end
	local cached = plantDetailsCache[plantModel]
	if cached then
		return cached.Name, cached.Mutation, cached.Variant
	end

	local resolvedName = nil

	pcall(function()
		for attrName, attrVal in pairs(plantModel:GetAttributes()) do
			if type(attrVal) == "string" and #attrVal > 1 then
				for _, cropName in ipairs(CropCatalogNames) do
					if string.lower(cropName) == string.lower(attrVal) or string.find(string.lower(attrVal), string.lower(cropName)) then
						resolvedName = cropName
						return
					end
				end
			end
		end
	end)

	if not resolvedName then
		pcall(function()
			for _, desc in ipairs(plantModel:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					local text = (desc.ObjectText ~= "" and desc.ObjectText) or desc.ActionText
					for _, cropName in ipairs(CropCatalogNames) do
						if string.find(string.lower(text), string.lower(cropName)) then
							resolvedName = cropName
							return
						end
					end
				end
			end
		end)
	end

	if not resolvedName then
		pcall(function()
			for _, desc in ipairs(plantModel:GetDescendants()) do
				local lowerName = string.lower(desc.Name)
				for _, cropName in ipairs(CropCatalogNames) do
					if string.find(lowerName, string.lower(cropName)) then
						resolvedName = cropName
						return
					end
				end
			end
		end)
	end

	if not resolvedName then
		local rawName = plantModel.Name
		local cleaned = string.gsub(rawName, "^%d+_", "")
		cleaned = string.gsub(cleaned, "_[%w%-]+$", "")
		resolvedName = (#cleaned > 1 and not string.find(cleaned, "%-")) and cleaned or "Crop Plant"
	end

	local detectedMutation = "Normal"
	local resolvedVariant = "Normal"

	pcall(function()
		-- 1. Check Root Attributes for Environmental Mutation & Variant
		local rootMut = plantModel:GetAttribute("Mutation") or plantModel:GetAttribute("MutationType") or plantModel:GetAttribute("Mut")
		if rootMut and tostring(rootMut) ~= "" and tostring(rootMut) ~= "None" then
			local rmStr = tostring(rootMut)
			local matched = false
			for _, officialMut in ipairs({"Solarflare", "Pizza", "Chained", "Ignited", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow"}) do
				if string.lower(rmStr) == string.lower(officialMut) or string.find(string.lower(rmStr), string.lower(officialMut)) then
					detectedMutation = officialMut
					matched = true
					break
				end
			end
			-- If root mutation value is not an environmental one, it might be Gold/Rainbow variant
			if not matched then
				if string.lower(rmStr) == "gold" or string.find(string.lower(rmStr), "gold") then
					resolvedVariant = "Gold"
				elseif string.lower(rmStr) == "rainbow" or string.find(string.lower(rmStr), "rainbow") then
					resolvedVariant = "Rainbow"
				end
			end
		end

		local rootVar = plantModel:GetAttribute("Variant") or plantModel:GetAttribute("VariantType") or plantModel:GetAttribute("Variation")
		if rootVar then
			local rvStr = tostring(rootVar)
			if string.lower(rvStr) == "gold" or string.find(string.lower(rvStr), "gold") then
				resolvedVariant = "Gold"
			elseif string.lower(rvStr) == "rainbow" or string.find(string.lower(rvStr), "rainbow") then
				resolvedVariant = "Rainbow"
			else
				resolvedVariant = rvStr
			end
		end

		-- 2. If no root mutation, scan descendants for FIRST explicit environmental mutation tag
		if detectedMutation == "Normal" then
			for _, desc in ipairs(plantModel:GetDescendants()) do
				local dName = string.lower(desc.Name)

				if string.find(dName, "solarflare_mut") or string.find(dName, "solarflare") then
					detectedMutation = "Solarflare"; break
				elseif string.find(dName, "pizzamutation") or string.find(dName, "pizza_mut") then
					detectedMutation = "Pizza"; break
				elseif string.find(dName, "chainedmutation") or string.find(dName, "chained_mut") then
					detectedMutation = "Chained"; break
				elseif string.find(dName, "ignitedmutation") or string.find(dName, "ignited_mut") then
					detectedMutation = "Ignited"; break
				elseif string.find(dName, "bloodlit_mut") or string.find(dName, "bloodlit") or string.find(dName, "bloodmoon_mut") then
					detectedMutation = "Bloodlit"; break
				elseif string.find(dName, "electric_mut") or string.find(dName, "electricmutation") or string.find(dName, "lightning_mut") then
					detectedMutation = "Electric"; break
				elseif string.find(dName, "starstruck_mut") or string.find(dName, "starstruck") or string.find(dName, "starfall_mut") then
					detectedMutation = "Starstruck"; break
				elseif string.find(dName, "frozen_mut") or string.find(dName, "frozenmutation") or string.find(dName, "frost_mut") then
					detectedMutation = "Frozen"; break
				elseif string.find(dName, "aurora_mut") or string.find(dName, "aurorav2") or string.find(dName, "auroramutation") then
					detectedMutation = "Aurora"; break
				elseif string.find(dName, "eclipsed_mut") or string.find(dName, "eclipsed") or string.find(dName, "eclipse_mut") then
					detectedMutation = "Eclipsed"; break
				elseif string.find(dName, "glowmutation") or string.find(dName, "glow_mut") then
					detectedMutation = "Glow"; break
				end

				-- Check descendant attributes
				for aKey, aVal in pairs(desc:GetAttributes()) do
					local vLower = tostring(aVal):lower()
					for _, officialMut in ipairs({"Solarflare", "Pizza", "Chained", "Ignited", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow"}) do
						if vLower == officialMut:lower() or vLower:find(officialMut:lower()) then
							detectedMutation = officialMut; break
						end
					end
					if detectedMutation ~= "Normal" then break end
					if string.find(vLower, "gold") then
						resolvedVariant = "Gold"
					elseif string.find(vLower, "rainbow") then
						resolvedVariant = "Rainbow"
					end
				end
				if detectedMutation ~= "Normal" then break end
			end
		end

		-- Also check for Gold/Rainbow variants (for variant display, NOT environmental mutation)
		if resolvedVariant == "Normal" then
			for _, desc in ipairs(plantModel:GetDescendants()) do
				local dName = string.lower(desc.Name)
				if string.find(dName, "rainbow_variant") or string.find(dName, "rainbowmutation") then
					resolvedVariant = "Rainbow"; break
				elseif string.find(dName, "gold_variant") or string.find(dName, "goldmutation") then
					resolvedVariant = "Gold"; break
				end
			end
		end
	end)

	plantDetailsCache[plantModel] = { Name = resolvedName, Mutation = detectedMutation, Variant = resolvedVariant }
	return resolvedName, detectedMutation, resolvedVariant
end

----------------------------------------------------
-- MUTATION CATALOG & COLOR SYSTEM
----------------------------------------------------
local MUTATION_DATA = {
	{ Name = "Gold",       Multiplier = "10x", Icon = "🪙", ExactNames = { "goldvfx", "gold", "golden", "greenbeangold" } },
	{ Name = "Rainbow",    Multiplier = "30x", Icon = "🌈", ExactNames = { "rainbowvfx", "rainbow", "strawberryrainbow" } },
	{ Name = "Bloodlit",   Multiplier = "70x", Icon = "🩸", ExactNames = { "bloodlitvfx", "bloodlit", "bamboobloodlit" } },
	{ Name = "Electric",   Multiplier = "25x", Icon = "⚡", ExactNames = { "electricvfx", "electric", "bambooelectric", "lightning", "shocked" } },
	{ Name = "Starstruck", Multiplier = "50x", Icon = "⭐", ExactNames = { "starstruckvfx", "starstruck", "blueberrystarstruck", "starfall" } },
	{ Name = "Frozen",     Multiplier = "20x", Icon = "❄️", ExactNames = { "frozenvfx", "frozen", "frost", "gag" } },
	{ Name = "Aurora",     Multiplier = "40x", Icon = "🌌", ExactNames = { "aurorav2", "auroravfx", "aurora" } },
	{ Name = "Eclipsed",   Multiplier = "80x", Icon = "🌒", ExactNames = { "eclipsedvfx", "eclipsed", "eclipse" } },
	{ Name = "Glow",       Multiplier = "80x", Icon = "💡", ExactNames = { "glowmutation", "glowvfx", "glow" } },
	
	-- Mutasi Unreleased / Upcoming
	{ Name = "Secret",     Multiplier = "TBA", Icon = "❓", ExactNames = { "secretvfx", "secret" } },
	{ Name = "Solarflare", Multiplier = "5x",  Icon = "☀️", ExactNames = { "solarflarevfx", "solarflare" } },
	{ Name = "Pizza",      Multiplier = "5x",  Icon = "🍕", ExactNames = { "pizzavfx", "pizza" } },
	{ Name = "Chained",    Multiplier = "8x",  Icon = "⛓️", ExactNames = { "chainedvfx", "chained" } },
	{ Name = "Ignited",    Multiplier = "60x", Icon = "🔥", ExactNames = { "ignitedvfx", "ignited" } }
}

local SUB_PARTICLE_EXCLUSIONS = {
	["glowring"] = true,
	["glowring2"] = true,
	["pixelated fire"] = true,
	["pixelatedfire"] = true,
	["pulse"] = true,
	["shards"] = true,
	["spec19"] = true,
	["square"] = true,
	["particleemitter"] = true
}

local ReleasedMutations = {
	"Gold", "Rainbow", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow"
}

local UnreleasedMutations = {
	"Solarflare", "Pizza", "Chained", "Ignited"
}

local OfficialMutationList = {
	"Normal", "Gold", "Rainbow", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow", "Solarflare", "Pizza", "Chained", "Ignited"
}

local MutationColors = {
	Gold = Color3.fromRGB(241, 196, 15),
	Rainbow = Color3.fromRGB(255, 105, 180),
	Bloodlit = Color3.fromRGB(231, 76, 60),
	Electric = Color3.fromRGB(243, 156, 18),
	Starstruck = Color3.fromRGB(155, 89, 182),
	Frozen = Color3.fromRGB(52, 152, 219),
	Aurora = Color3.fromRGB(26, 188, 156),
	Eclipsed = Color3.fromRGB(142, 68, 173),
	Glow = Color3.fromRGB(46, 204, 113),
	Solarflare = Color3.fromRGB(230, 126, 34),
	Pizza = Color3.fromRGB(211, 84, 0),
	Chained = Color3.fromRGB(127, 140, 141),
	Ignited = Color3.fromRGB(192, 57, 43),
	Normal = Color3.fromRGB(180, 190, 205)
}

----------------------------------------------------
-- CROP RARITY EVALUATOR
----------------------------------------------------
local function getCropRarity(cropName)
	for rarity, items in pairs(CropCatalog) do
		for _, name in ipairs(items) do
			if string.lower(name) == string.lower(cropName) or string.find(string.lower(cropName), string.lower(name)) then
				return rarity
			end
		end
	end
	return "Common"
end

local RarityColors = {
	Super = Color3.fromRGB(231, 76, 60),
	Secret = Color3.fromRGB(230, 126, 34),
	Mythic = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(241, 196, 15),
	Epic = Color3.fromRGB(142, 68, 173),
	Rare = Color3.fromRGB(52, 152, 219),
	Uncommon = Color3.fromRGB(46, 204, 113),
	Common = Color3.fromRGB(180, 190, 205)
}

----------------------------------------------------
-- AUTHORITATIVE LIVE SERVER FRUIT WEIGHT SCANNER
----------------------------------------------------
local persistentWeightCache = setmetatable({}, { __mode = "k" })

local function extractItemWeight(item)
	if not item then return 0 end
	if persistentWeightCache[item] and persistentWeightCache[item] > 0 then
		return persistentWeightCache[item]
	end

	local maxW = 0

	local function parseWeightFromText(txt)
		if not txt or type(txt) ~= "string" or #txt == 0 then return 0 end
		local cleanTxt = string.gsub(txt, "<[^>]+>", "")

		-- 1. Match "1.65kg", "1.65 kg", "1.65KG", "1.65 kg"
		local w1 = string.match(cleanTxt, "(%d+%.?%d*)%s*[kK][gG]")
		if w1 then
			local n = tonumber(w1)
			if n and n > 0.001 and n < 10000 then return n end
		end

		-- 2. Match "⚖ 1.65", "⚖1.65"
		local w2 = string.match(cleanTxt, "⚖%s*(%d+%.?%d*)")
		if w2 then
			local n = tonumber(w2)
			if n and n > 0.001 and n < 10000 then return n end
		end

		-- 3. Match "Weight: 1.65", "Weight 1.65", "weight: 1.65", "Weight=1.65"
		local w3 = string.match(cleanTxt, "[wW][eE][iI][gG][hH][tT]%s*[:=]?%s*(%d+%.?%d*)")
		if w3 then
			local n = tonumber(w3)
			if n and n > 0.001 and n < 10000 then return n end
		end

		-- 4. Match "_1.65kg", "_1.65KG" (MUST end with kg)
		local w4 = string.match(cleanTxt, "_([%d%.]+)%s*[kK][gG]")
		if w4 then
			local n = tonumber(w4)
			if n and n > 0.001 and n < 10000 then return n end
		end

		-- 5. Standalone number in parentheses / brackets with kg: "(1.65kg)" or "[1.65kg]"
		local w5 = string.match(cleanTxt, "%((%d+%.?%d*)%s*[kK][gG]%)") or string.match(cleanTxt, "%[(%d+%.?%d*)%s*[kK][gG]%]")
		if w5 then
			local n = tonumber(w5)
			if n and n > 0.001 and n < 10000 then return n end
		end

		return 0
	end

	local function isExplicitWeightKey(kStr)
		local k = string.lower(tostring(kStr))
		return k == "weight" or k == "fruitweight" or k == "cropweight" or k == "weightkg" or k == "kg" or k == "mass" or k == "masskg" or string.find(k, "weight") ~= nil
	end

	pcall(function()
		-- Priority 1: ValueObjects explicitly named Weight / FruitWeight / WeightKg / kg (FOUND IN WORKSPACE.TXT!)
		for _, child in ipairs(item:GetChildren()) do
			if isExplicitWeightKey(child.Name) then
				if child:IsA("NumberValue") or child:IsA("IntValue") then
					local cv = child.Value
					if cv and cv > 0.001 and cv < 10000 then
						if cv > maxW then maxW = cv end
					end
				elseif child:IsA("StringValue") then
					local w = parseWeightFromText(child.Value)
					if w > maxW then maxW = w end
				end
			end
		end

		-- Priority 2: Direct Attributes explicitly named Weight / FruitWeight / WeightKg / kg / Mass
		if maxW <= 0 then
			for attrKey, attrVal in pairs(item:GetAttributes()) do
				if isExplicitWeightKey(attrKey) then
					if type(attrVal) == "number" and attrVal > 0.001 and attrVal < 10000 then
						if attrVal > maxW then maxW = attrVal end
					elseif type(attrVal) == "string" then
						local w = parseWeightFromText(attrVal)
						if w > maxW then maxW = w end
					end
				end
			end
		end

		-- Priority 3: Check TextLabels (BillboardGui / DebugGui) (e.g. "Apple 2.22kg")
		if maxW <= 0 then
			for _, desc in ipairs(item:GetDescendants()) do
				if desc:IsA("TextLabel") or desc:IsA("TextButton") then
					local w = parseWeightFromText(desc.Text)
					if w > maxW then maxW = w end
				end
			end
		end

		-- Priority 4: ProximityPrompt (ObjectText & ActionText) SILENTLY without modifying properties
		if maxW <= 0 then
			local prompt = item:IsA("ProximityPrompt") and item or item:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				local w1 = parseWeightFromText(prompt.ObjectText)
				local w2 = parseWeightFromText(prompt.ActionText)
				if w1 > maxW then maxW = w1 end
				if w2 > maxW then maxW = w2 end
			end
		end

		-- Priority 5: Item Name string parsing (e.g. "Banana_1.65kg", "1.65kg")
		if maxW <= 0 then
			local nameW = parseWeightFromText(item.Name)
			if nameW > maxW then maxW = nameW end
		end

		-- Priority 6: Descendants Weight ValueObjects, Attributes & ProximityPrompts SILENTLY
		if maxW <= 0 then
			for _, desc in ipairs(item:GetDescendants()) do
				if (desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("StringValue")) and isExplicitWeightKey(desc.Name) then
					if desc:IsA("StringValue") then
						local w = parseWeightFromText(desc.Value)
						if w > maxW then maxW = w end
					else
						local cv = desc.Value
						if cv and cv > 0.001 and cv < 10000 then
							if cv > maxW then maxW = cv end
						end
					end
				elseif desc:IsA("ProximityPrompt") then
					local w1 = parseWeightFromText(desc.ObjectText)
					local w2 = parseWeightFromText(desc.ActionText)
					if w1 > maxW then maxW = w1 end
					if w2 > maxW then maxW = w2 end
				end

				for attrKey, attrVal in pairs(desc:GetAttributes()) do
					if isExplicitWeightKey(attrKey) then
						if type(attrVal) == "number" and attrVal > 0.001 and attrVal < 10000 then
							if attrVal > maxW then maxW = attrVal end
						elseif type(attrVal) == "string" then
							local w = parseWeightFromText(attrVal)
							if w > maxW then maxW = w end
						end
					end
				end
			end
		end
	end)

	if maxW > 0 then
		persistentWeightCache[item] = maxW
	end
	return maxW
end

----------------------------------------------------
-- FRUIT-LEVEL SPECIFIC NAME RESOLVER
----------------------------------------------------
local function resolveFruitName(instance, fallbackPlantName)
	if not instance then return fallbackPlantName end
	local matchedName = nil

	pcall(function()
		-- 1. Check direct attributes
		for _, attr in ipairs({"FruitName", "CropName", "Crop", "PlantName", "ItemName", "Name"}) do
			local val = instance:GetAttribute(attr)
			if val and type(val) == "string" and #val > 1 then
				for _, cName in ipairs(CropCatalogNames) do
					if string.lower(cName) == string.lower(val) or string.find(string.lower(val), string.lower(cName)) then
						matchedName = cName
						return
					end
				end
			end
		end

		-- 2. Check ProximityPrompt text
		if instance:IsA("ProximityPrompt") then
			local txt = string.lower(tostring(instance.ObjectText) .. " " .. tostring(instance.ActionText))
			for _, cName in ipairs(CropCatalogNames) do
				if string.find(txt, string.lower(cName)) then
					matchedName = cName
					return
				end
			end
		end

		-- 3. Check TextLabel text inside BillboardGui
		if instance:IsA("TextLabel") then
			local txt = string.lower(tostring(instance.Text))
			for _, cName in ipairs(CropCatalogNames) do
				if string.find(txt, string.lower(cName)) then
					matchedName = cName
					return
				end
			end
		end

		-- 4. Check instance name
		local iName = string.lower(instance.Name)
		for _, cName in ipairs(CropCatalogNames) do
			if string.find(iName, string.lower(cName)) then
				matchedName = cName
				return
			end
		end
	end)

	return matchedName or fallbackPlantName
end

----------------------------------------------------
-- LOCAL PLAYER EXCLUSIVE PLOT DETECTOR
----------------------------------------------------
local function isMyGardenPlot(plot)
	if not plot then return false end

	local isMine = false
	pcall(function()
		local ownerAttr = plot:GetAttribute("Owner") or plot:GetAttribute("OwnerName") or plot:GetAttribute("Player") or plot:GetAttribute("UserId")
		local ownerValObj = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Player")
		local ownerStr = tostring(ownerAttr or (ownerValObj and ownerValObj.Value) or "")

		if ownerStr == player.Name or ownerStr == tostring(player.UserId) or (ownerStr ~= "" and string.find(string.lower(plot.Name), string.lower(player.Name))) or string.find(plot.Name, tostring(player.UserId)) then
			isMine = true
			return
		end

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local primary = plot:IsA("Model") and (plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")) or plot:FindFirstChildWhichIsA("BasePart", true)

		if root and primary then
			local dist = (root.Position - primary.Position).Magnitude
			if dist < 500 then
				isMine = true
			end
		else
			isMine = true
		end
	end)

	return isMine
end

----------------------------------------------------
-- PURE FARM FRUIT MUTATION SCANNER ENGINE
----------------------------------------------------
local function isInvalidString(str)
	if not str or type(str) ~= "string" then return true end
	local s = str:lower():gsub("%s+", "")
	if #s == 0 then return true end
	if s:match("^%d+$") then return true end
	if s:find("%x%x%x%x%x%x%x%x%-%x%x%x%x") then return true end
	if s:match("^%d+_") then return true end
	return false
end

local pureCropNameCache = setmetatable({}, { __mode = "k" })

local function getPureCropName(plant, fruit)
	local targetKey = fruit or plant
	if not targetKey then return "Crop Plant" end
	if pureCropNameCache[targetKey] then
		return pureCropNameCache[targetKey]
	end

	local prompt = (fruit and fruit:FindFirstChildWhichIsA("ProximityPrompt", true))
		or (plant and plant:FindFirstChildWhichIsA("ProximityPrompt", true))

	if prompt and prompt.ObjectText and prompt.ObjectText ~= "" and prompt.ObjectText:lower() ~= "harvest" then
		local txt = prompt.ObjectText:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		if not isInvalidString(txt) then
			pureCropNameCache[targetKey] = txt
			return txt
		end
	end

	local attrs = { "CropName", "PlantName", "DisplayName", "Species", "Crop", "SeedName", "Name" }
	for _, attr in ipairs(attrs) do
		local val = (fruit and fruit:GetAttribute(attr)) or (plant and plant:GetAttribute(attr))
		if val and type(val) == "string" and val ~= "" and not isInvalidString(val) then
			pureCropNameCache[targetKey] = val
			return val
		end
	end

	local checkObjs = {}
	if fruit then table.insert(checkObjs, fruit) end
	if plant then table.insert(checkObjs, plant) end

	for _, obj in ipairs(checkObjs) do
		for _, desc in ipairs(obj:GetDescendants()) do
			if desc:IsA("TextLabel") and desc.Text and desc.Text ~= "" then
				local txt = desc.Text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
				if #txt > 1 and not txt:lower():find("harvest") and not isInvalidString(txt) then
					pureCropNameCache[targetKey] = txt
					return txt
				end
			end
		end
	end

	local result = (plant and plant.Name) or "Crop Plant"
	pureCropNameCache[targetKey] = result
	return result
end

local officialMutationsCache = setmetatable({}, { __mode = "k" })

local function getOfficialMutations(fruit)
	if not fruit then return {} end
	if officialMutationsCache[fruit] then
		return officialMutationsCache[fruit]
	end

	local detectedMutations = {}
	local addedSet = {}

	for _, child in ipairs(fruit:GetChildren()) do
		local cName = child.Name:lower():gsub("%s+", "")
		if not SUB_PARTICLE_EXCLUSIONS[cName] then
			for _, mut in ipairs(MUTATION_DATA) do
				if not addedSet[mut.Name] then
					for _, exact in ipairs(mut.ExactNames) do
						if cName == exact or cName == exact .. "vfx" then
							addedSet[mut.Name] = true
							table.insert(detectedMutations, mut)
							break
						end
					end
				end
			end
		end
	end

	local mutAttr = fruit:GetAttribute("Mutation") or fruit:GetAttribute("Variant") or fruit:GetAttribute("Mutations") or fruit:GetAttribute("Effect")
	if mutAttr then
		local attrStr = tostring(mutAttr):lower():gsub("%s+", "")
		for _, mut in ipairs(MUTATION_DATA) do
			if not addedSet[mut.Name] then
				for _, exact in ipairs(mut.ExactNames) do
					if attrStr == exact or attrStr:find(exact) then
						addedSet[mut.Name] = true
						table.insert(detectedMutations, mut)
						break
					end
				end
			end
		end
	end

	officialMutationsCache[fruit] = detectedMutations
	return detectedMutations
end

----------------------------------------------------
-- OPTIMIZED SCAN CACHE ENGINE (PREVENTS FPS DROPS)
----------------------------------------------------
local ScanCache = {
	LastScanTime = 0,
	CacheDuration = 1.5, -- seconds (Fast periodic auto-refresh)
	TotalMutatedFruits = 0,
	TotalFruitsScanned = 0,
	MutationSummary = {},
	FruitDetails = {},
	PlantList = {},
	TotalPlants = 0,
	TotalReadyFruits = 0,
	TotalUnreadyFruits = 0,
	TotalFruits = 0,
	MutationCounts = {},
	CropGroups = {},
	ActiveCrops = {}
}

local function invalidateScanCache()
	ScanCache.LastScanTime = 0
	table.clear(itemWeightCache)
	table.clear(officialMutationsCache)
	table.clear(plantDetailsCache)
	table.clear(pureCropNameCache)
end

local function scanFarmMutations(forceRefresh)
	local now = tick()
	if not forceRefresh and (now - ScanCache.LastScanTime < ScanCache.CacheDuration) and ScanCache.TotalFruitsScanned > 0 then
		return ScanCache.TotalMutatedFruits, ScanCache.TotalFruitsScanned, ScanCache.MutationSummary, ScanCache.FruitDetails
	end

	local totalFruitsScanned = 0
	local totalMutatedFruits = 0
	local mutationSummary = {}
	local fruitDetails = {}

	pcall(function()
		local gardenContainers = {
			Workspace:FindFirstChild("Gardens"),
			Workspace:FindFirstChild("Plots"),
			Workspace:FindFirstChild("_Gardens"),
			Workspace:FindFirstChild("Farm"),
			Workspace:FindFirstChild("GardenPlots"),
			Workspace:FindFirstChild("Garden"),
			Workspace:FindFirstChild("MyPlot")
		}

		for _, folder in ipairs(gardenContainers) do
			if folder then
				for _, plot in ipairs(folder:GetChildren()) do
					if isMyGardenPlot(plot) or folder ~= Workspace then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("CropFolder") or plot:FindFirstChild("Crops") or plot
						if plantsFolder and plantsFolder ~= plot then
							for _, plant in ipairs(plantsFolder:GetChildren()) do
								local fruitsFolder = plant:FindFirstChild("Fruits") or plant:FindFirstChild("Produce")
								local fruitsToScan = {}
								if fruitsFolder then
									fruitsToScan = fruitsFolder:GetChildren()
								else
									fruitsToScan = { plant }
								end

								for _, fruit in ipairs(fruitsToScan) do
									totalFruitsScanned = totalFruitsScanned + 1
									local cropName = getPureCropName(plant, fruit)
									local muts = getOfficialMutations(fruit)

									if #muts > 0 then
										totalMutatedFruits = totalMutatedFruits + 1
										for _, m in ipairs(muts) do
											if not mutationSummary[m.Name] then
												mutationSummary[m.Name] = { Count = 0, Info = m }
											end
											mutationSummary[m.Name].Count = mutationSummary[m.Name].Count + 1
										end

										table.insert(fruitDetails, {
											Plot = plot.Name,
											CropName = cropName,
											Mutations = muts
										})
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	ScanCache.LastScanTime = now
	ScanCache.TotalMutatedFruits = totalMutatedFruits
	ScanCache.TotalFruitsScanned = totalFruitsScanned
	ScanCache.MutationSummary = mutationSummary
	ScanCache.FruitDetails = fruitDetails

	return totalMutatedFruits, totalFruitsScanned, mutationSummary, fruitDetails
end

----------------------------------------------------
----------------------------------------------------
-- INDIVIDUAL FRUIT FINDER & POSITION RESOLVER
----------------------------------------------------
local function getAllFruitInstancesFromPlant(plantModel)
	local fruitsFolder = plantModel:FindFirstChild("Fruits") 
		or plantModel:FindFirstChild("Produce") 
		or plantModel:FindFirstChild("Crops")
		or plantModel:FindFirstChild("Fruit")

	if fruitsFolder then
		return fruitsFolder:GetChildren()
	end

	local spawnLocs = plantModel:FindFirstChild("FruitSpawnLocations")
	if spawnLocs then
		local locChildren = spawnLocs:GetChildren()
		if #locChildren > 0 then return locChildren end
	end

	local fruits = {}
	local foundSet = {}

	for _, child in ipairs(plantModel:GetChildren()) do
		if child:FindFirstChildWhichIsA("ProximityPrompt", false) then
			foundSet[child] = true
			table.insert(fruits, child)
		end
	end

	if #fruits == 0 then
		for _, desc in ipairs(plantModel:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				local targetObj = desc.Parent
				if targetObj and targetObj:IsA("BasePart") then
					if targetObj.Parent and targetObj.Parent ~= plantModel and targetObj.Parent:IsA("Model") then
						targetObj = targetObj.Parent
					end
				end
				if targetObj and not foundSet[targetObj] and targetObj ~= plantModel then
					foundSet[targetObj] = true
					table.insert(fruits, targetObj)
				end
			end
		end
	end

	if #fruits == 0 then
		table.insert(fruits, plantModel)
	end

	return fruits
end

local function getFruitWorldPosition(fruitInstance, plantModel)
	if fruitInstance then
		if fruitInstance:IsA("Model") then
			local primary = fruitInstance.PrimaryPart 
				or fruitInstance:FindFirstChild("HarvestPart") 
				or fruitInstance:FindFirstChild("Base") 
				or fruitInstance:FindFirstChildWhichIsA("BasePart", true)
			if primary then
				return primary.Position, primary
			end
			local pivot = fruitInstance:GetPivot()
			return pivot.Position, fruitInstance
		elseif fruitInstance:IsA("BasePart") then
			return fruitInstance.Position, fruitInstance
		end
	end

	if plantModel then
		if plantModel:IsA("Model") then
			local primary = plantModel.PrimaryPart or plantModel:FindFirstChildWhichIsA("BasePart", true)
			if primary then return primary.Position, primary end
			return plantModel:GetPivot().Position, plantModel
		elseif plantModel:IsA("BasePart") then
			return plantModel.Position, plantModel
		end
	end

	return nil, nil
end

----------------------------------------------------
-- DETAILED GARDEN PLANT & FRUIT SCANNER
----------------------------------------------------
local function fetchGardenPlants(forceRefresh)
	local now = tick()
	if not forceRefresh and ScanCache.PlantList and #ScanCache.PlantList > 0 and (now - ScanCache.LastScanTime < ScanCache.CacheDuration) then
		return ScanCache.PlantList, ScanCache.TotalPlants, ScanCache.TotalReadyFruits, ScanCache.TotalUnreadyFruits, ScanCache.TotalFruits, ScanCache.MutationCounts, ScanCache.CropGroups, ScanCache.FruitList
	end

	local plantList = {}
	local fruitList = {}
	local totalPlants = 0
	local totalReadyFruits = 0
	local totalUnreadyFruits = 0
	local totalFruits = 0
	local mutationCounts = {}
	local cropGroups = {}
	local activeCropSet = {}
	local activeCrops = {}

	pcall(function()
		local gardenContainers = {
			Workspace:FindFirstChild("Gardens"),
			Workspace:FindFirstChild("Plots"),
			Workspace:FindFirstChild("Farm"),
			Workspace:FindFirstChild("GardenPlots"),
			Workspace:FindFirstChild("Garden"),
			Workspace:FindFirstChild("MyPlot")
		}

		for _, folder in ipairs(gardenContainers) do
			if folder then
				for _, plot in ipairs(folder:GetChildren()) do
					if isMyGardenPlot(plot) then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Crops") or plot
						if plantsFolder then
							for _, plantModel in ipairs(plantsFolder:GetChildren()) do
								if plantModel:IsA("Model") or plantModel:IsA("Folder") or plantModel:IsA("BasePart") then
									totalPlants = totalPlants + 1
									local realName, mutation, variant = resolvePlantDetails(plantModel)
									if variant and variant ~= "Normal" and (mutation == "Normal" or mutation == "") then
										mutation = variant
									end

									if realName and realName ~= "Crop Plant" and realName ~= "Model" and not activeCropSet[realName] then
										activeCropSet[realName] = true
										table.insert(activeCrops, realName)
									end

									local plantWeight = extractItemWeight(plantModel)
									local fruitsOnPlant = getAllFruitInstancesFromPlant(plantModel)
									local totalOnPlant = #fruitsOnPlant

									local plantReadyCount = 0
									local plantUnreadyCount = 0
									local heaviestInPlant = plantWeight

									local plantWeightsList = {}
									for fIdx, fruitObj in ipairs(fruitsOnPlant) do
										local fCropName = getPureCropName(plantModel, fruitObj)
										if fCropName == "Crop Plant" or fCropName == "Model" then fCropName = realName end

										local fw = extractItemWeight(fruitObj)
										if fw <= 0 then fw = plantWeight end
										if fw > heaviestInPlant then heaviestInPlant = fw end
										if fw > 0 then
											table.insert(plantWeightsList, fw)
										end

										local muts = getOfficialMutations(fruitObj)
										local fMutName = "Normal"
										if #muts > 0 then
											fMutName = muts[1].Name
										elseif mutation and mutation ~= "Normal" then
											fMutName = mutation
										end

										mutationCounts[fMutName] = (mutationCounts[fMutName] or 0) + 1

										local isReady = (fruitObj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil)
										if not isReady and fruitObj == plantModel then
											isReady = (plantModel:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil)
										end

										if isReady then
											plantReadyCount = plantReadyCount + 1
										else
											plantUnreadyCount = plantUnreadyCount + 1
										end

										local fPos, fAdornee = getFruitWorldPosition(fruitObj, plantModel)
										local cropRarity = getCropRarity(fCropName)

										table.insert(fruitList, {
											Plot = plot.Name,
											PlantName = realName,
											CropName = fCropName,
											FruitIndex = fIdx,
											TotalOnPlant = totalOnPlant,
											Position = fPos,
											Adornee = fAdornee,
											Weight = fw,
											Mutations = muts,
											MutationName = fMutName,
											IsReady = isReady,
											Rarity = cropRarity,
											FruitInstance = fruitObj,
											PlantModel = plantModel
										})
									end

									if #fruitsOnPlant == 0 and plantWeight > 0 then
										table.insert(plantWeightsList, plantWeight)
									end

									totalReadyFruits = totalReadyFruits + plantReadyCount
									totalUnreadyFruits = totalUnreadyFruits + plantUnreadyCount
									totalFruits = totalFruits + totalOnPlant

									local cropRarity = getCropRarity(realName)
									if not cropGroups[realName] then
										cropGroups[realName] = {
											Name = realName,
											Count = 1,
											ReadyFruits = plantReadyCount,
											UnreadyFruits = plantUnreadyCount,
											TotalFruits = totalOnPlant,
											Weights = plantWeightsList,
											MaxWeight = heaviestInPlant,
											Rarity = cropRarity,
											Mutations = {}
										}
										if mutation and mutation ~= "Normal" and mutation ~= "" then
											cropGroups[realName].Mutations[mutation] = true
										end
									else
										cropGroups[realName].Count = cropGroups[realName].Count + 1
										cropGroups[realName].ReadyFruits = cropGroups[realName].ReadyFruits + plantReadyCount
										cropGroups[realName].UnreadyFruits = cropGroups[realName].UnreadyFruits + plantUnreadyCount
										cropGroups[realName].TotalFruits = cropGroups[realName].TotalFruits + totalOnPlant
										for _, w in ipairs(plantWeightsList) do
											table.insert(cropGroups[realName].Weights, w)
										end
										if heaviestInPlant > cropGroups[realName].MaxWeight then
											cropGroups[realName].MaxWeight = heaviestInPlant
										end
										if mutation and mutation ~= "Normal" and mutation ~= "" then
											cropGroups[realName].Mutations[mutation] = true
										end
									end

									table.insert(plantList, {
										Plot = plot.Name,
										Name = realName,
										Mutation = mutation,
										Fruits = plantReadyCount,
										UnreadyFruits = plantUnreadyCount,
										MaxWeight = heaviestInPlant,
										Rarity = cropRarity,
										UUID = string.match(plantModel.Name, "_([%w%-]+)$") or plantModel.Name,
										Position = plantModel:IsA("Model") and plantModel:GetPivot().Position or (plantModel:IsA("BasePart") and plantModel.Position) or nil
									})
								end
							end
						end
					end
				end
			end
		end
	end)

	table.sort(activeCrops)

	ScanCache.LastScanTime = now
	ScanCache.PlantList = plantList
	ScanCache.FruitList = fruitList
	ScanCache.TotalPlants = totalPlants
	ScanCache.TotalReadyFruits = totalReadyFruits
	ScanCache.TotalUnreadyFruits = totalUnreadyFruits
	ScanCache.TotalFruits = totalFruits
	ScanCache.MutationCounts = mutationCounts
	ScanCache.CropGroups = cropGroups
	ScanCache.ActiveCrops = activeCrops

	return plantList, totalPlants, totalReadyFruits, totalUnreadyFruits, totalFruits, mutationCounts, cropGroups, fruitList
end

----------------------------------------------------
-- DYNAMIC ACTIVE GARDEN CROP SCANNER FOR UI FILTERS
----------------------------------------------------
local function fetchActiveGardenCropNames()
	local activeCrops = {}
	local cropSet = {}

	pcall(function()
		local plantList, _, _, _, _, _, cropGroups = fetchGardenPlants()
		if cropGroups then
			for realName, _ in pairs(cropGroups) do
				if realName and realName ~= "Crop Plant" and realName ~= "Model" and not cropSet[realName] then
					cropSet[realName] = true
					table.insert(activeCrops, realName)
				end
			end
		end

		if #activeCrops == 0 and plantList then
			for _, item in ipairs(plantList) do
				if item.Name and item.Name ~= "Crop Plant" and item.Name ~= "Model" and not cropSet[item.Name] then
					cropSet[item.Name] = true
					table.insert(activeCrops, item.Name)
				end
			end
		end
	end)

	table.sort(activeCrops)

	if #activeCrops == 0 then
		return CropCatalogNames
	end

	return activeCrops
end

----------------------------------------------------
-- BACKPACK & BAG CROP FETCHER
----------------------------------------------------
local function fetchBackpackCrops()
	local cropCounts = {}
	local totalItems = 0

	pcall(function()
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") then
					totalItems = totalItems + 1
					local name = item.Name
					cropCounts[name] = (cropCounts[name] or 0) + 1
				end
			end
		end
	end)

	pcall(function()
		local char = player.Character
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") then
					totalItems = totalItems + 1
					local name = item.Name
					cropCounts[name] = (cropCounts[name] or 0) + 1
				end
			end
		end
	end)

	return cropCounts, totalItems
end

----------------------------------------------------
-- ITEM STOCK DETECTOR HELPER
----------------------------------------------------
local function detectItemStock(instance)
	if not instance then return 5 end
	local foundStock = nil

	pcall(function()
		local attrs = {"Stock", "Amount", "Quantity", "Count", "Remaining", "MaxStock"}
		for _, a in ipairs(attrs) do
			local val = instance:GetAttribute(a)
			if type(val) == "number" and val > 0 then
				foundStock = val
				return
			end
		end

		for _, child in ipairs(instance:GetChildren()) do
			if child:IsA("ValueObject") or child:IsA("IntValue") or child:IsA("NumberValue") then
				local cName = string.lower(child.Name)
				if string.find(cName, "stock") or string.find(cName, "amount") or string.find(cName, "count") then
					if type(child.Value) == "number" and child.Value > 0 then
						foundStock = child.Value
						return
					end
				end
			end
		end

		for _, desc in ipairs(instance:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextBox") then
				local text = desc.Text
				if text and #text > 0 then
					local sNum = string.match(text, "Stock:%s*(%d+)")
						or string.match(text, "Stok:%s*(%d+)")
						or string.match(text, "(%d+)%s*left")
						or string.match(text, "x(%d+)")
						or string.match(text, "(%d+)/(%d+)")
					if sNum then
						local n = tonumber(sNum)
						if n and n > 0 then
							foundStock = n
							return
						end
					end
				end
			end
		end
	end)

	return foundStock or 5
end

----------------------------------------------------
-- SHOP RESTOCK TIMER DETECTOR HELPER
----------------------------------------------------
local function detectShopRestockTime()
	local restockSig = ""
	pcall(function()
		local shopFolder = ReplicatedStorage:FindFirstChild("Shop") or ReplicatedStorage:FindFirstChild("SeedShop") or Workspace:FindFirstChild("Shop") or Workspace:FindFirstChild("Merchant")
		if shopFolder then
			local timer = shopFolder:FindFirstChild("RestockTimer") or shopFolder:FindFirstChild("Timer") or shopFolder:FindFirstChild("RestockTime")
			if timer then
				restockSig = restockSig .. tostring(timer.Value or timer:GetAttribute("Time") or "")
			end
		end

		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and (string.find(string.lower(gui.Name), "shop") or string.find(string.lower(gui.Name), "seed") or string.find(string.lower(gui.Name), "gear") or string.find(string.lower(gui.Name), "merchant")) then
					for _, desc in ipairs(gui:GetDescendants()) do
						if desc:IsA("TextLabel") then
							local txt = string.lower(desc.Text or "")
							if string.find(txt, "restock") or string.find(txt, "next in") or string.find(txt, "refresh") then
								 restockSig = restockSig .. desc.Text .. ";"
							end
						end
					end
				end
			end
		end
	end)
	return restockSig
end

----------------------------------------------------
-- STRICT REAL-TIME SERVER SEED SHOP FETCHER (NON-BLOCKING ULTRA FAST)
----------------------------------------------------
local seedShopCache = nil
local lastSeedShopScan = 0

local function fetchActiveSeedShop()
	local now = tick()
	if seedShopCache and (now - lastSeedShopScan < 1.0) then
		return seedShopCache
	end

	local shopSeeds = {}
	local seedSet = {}

	local function processCandidate(rawName, instance)
		if not rawName or type(rawName) ~= "string" or #rawName == 0 then return end
		for _, cropName in ipairs(CropCatalogNames) do
			if string.lower(cropName) == string.lower(rawName) or string.find(string.lower(rawName), string.lower(cropName)) then
				if not seedSet[cropName] then
					seedSet[cropName] = true
					local resolvedTier = "Common"
					for tierName, tList in pairs(CropCatalog) do
						for _, s in ipairs(tList) do
							if s == cropName then resolvedTier = tierName break end
						end
					end
					local stockVal = detectItemStock(instance)
					table.insert(shopSeeds, { Name = cropName, Tier = resolvedTier, Stock = stockVal })
				end
				break
			end
		end
	end

	-- Fast non-blocking UI check
	pcall(function()
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and (string.find(string.lower(gui.Name), "shop") or string.find(string.lower(gui.Name), "seed") or string.find(string.lower(gui.Name), "main")) then
					for _, child in ipairs(gui:GetDescendants()) do
						local sAttr = child:GetAttribute("SeedName") or child:GetAttribute("Crop") or child:GetAttribute("Seed") or child.Name
						if sAttr then processCandidate(tostring(sAttr), child) end
					end
				end
			end
		end
	end)

	-- Fallback catalog fill if UI is closed
	if #shopSeeds == 0 then
		for tierName, tList in pairs(CropCatalog) do
			for _, sName in ipairs(tList) do
				table.insert(shopSeeds, { Name = sName, Tier = tierName, Stock = 5 })
			end
		end
	end

	seedShopCache = shopSeeds
	lastSeedShopScan = now
	return shopSeeds
end

----------------------------------------------------
-- DUAL REAL-TIME GEAR SHOP FETCHER (ZERO-LAG NON-BLOCKING)
----------------------------------------------------
local gearShopCache = nil
local lastGearShopScan = 0

local function fetchActiveGearShop()
	local now = tick()
	if gearShopCache and (now - lastGearShopScan < 1.0) then
		return gearShopCache
	end

	local result = {}
	local gearSet = {}

	pcall(function()
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and (string.find(string.lower(gui.Name), "gear") or string.find(string.lower(gui.Name), "tool") or string.find(string.lower(gui.Name), "shop")) then
					for _, child in ipairs(gui:GetDescendants()) do
						local gAttr = child:GetAttribute("GearName") or child:GetAttribute("ToolName") or child:GetAttribute("Item")
						if gAttr then
							local gName = tostring(gAttr)
							if not gearSet[gName] then
								gearSet[gName] = true
								local stockVal = detectItemStock(child)
								table.insert(result, {
									Name = gName,
									Price = "Shop Price",
									IsActive = true,
									Stock = stockVal
								})
							end
						end
					end
				end
			end
		end
	end)

	if #result == 0 then
		for _, gData in ipairs(OfficialGearCatalog) do
			table.insert(result, {
				Name = gData.Name,
				Price = gData.Price,
				IsActive = true,
				Stock = 5
			})
		end
	end

	gearShopCache = result
	lastGearShopScan = now
	return result
end

----------------------------------------------------
-- DYNAMIC GARDEN DISTANCE CALCULATOR
----------------------------------------------------
local function getDistanceToNearestGarden()
	local minDistance = 99999
	pcall(function()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local gardenContainers = {
			Workspace:FindFirstChild("Gardens"),
			Workspace:FindFirstChild("Plots"),
			Workspace:FindFirstChild("Farm"),
			Workspace:FindFirstChild("GardenPlots"),
			Workspace:FindFirstChild("Garden"),
			Workspace:FindFirstChild("MyPlot")
		}

		for _, folder in ipairs(gardenContainers) do
			if folder then
				for _, plot in ipairs(folder:GetChildren()) do
					local primary = plot:IsA("Model") and (plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")) or plot:FindFirstChildWhichIsA("BasePart", true)
					if primary then
						local dist = (root.Position - primary.Position).Magnitude
						if dist < minDistance then
							minDistance = dist
						end
					end
				end
			end
		end
	end)

	return minDistance
end

----------------------------------------------------
-- STRICT FRUIT PROMPT FILTER HELPER
----------------------------------------------------
local function isFruitHarvestPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return false end

	-- Always true if located inside any Garden, Plot, Farm container or under a Plant/Fruit model
	local current = prompt.Parent
	while current and current ~= Workspace do
		local cName = string.lower(current.Name)
		if cName == "plants" or cName == "crops" or cName == "fruits" or cName == "gardens" or cName == "plots" or cName == "farm" or cName == "gardenplots" or cName == "garden" or cName == "myplot" or string.find(cName, "plot") or string.find(cName, "plant") or string.find(cName, "fruit") or string.find(cName, "crop") or string.find(cName, "tree") then
			return true
		end
		current = current.Parent
	end

	return true
end

----------------------------------------------------
-- REAL CONTINUOUS HOLD E KEY PRESS CONTROLLER (TRUE HOLDING STATE)
----------------------------------------------------
local isHoldingE = false
local VirtualInputManager = nil
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)

local function startHoldingE()
	if isHoldingE then return end
	isHoldingE = true

	pcall(function()
		if VirtualInputManager then
			-- Send real key down event (Holds E key down continuously without releasing)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		end
	end)
end

local function stopHoldingE()
	if not isHoldingE then return end
	isHoldingE = false

	pcall(function()
		if VirtualInputManager then
			-- Send key up event (Releases E key)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end
	end)
end

----------------------------------------------------
-- FUNGSI CLEAN CROP NAME
----------------------------------------------------
local function cleanCropName(str)
	if not str then return "" end
	local s = string.lower(tostring(str))
	s = string.gsub(s, "%s*%b()", "")
	s = string.gsub(s, "%s*%b[]", "")
	return string.match(s, "^%s*(.-)%s*$") or s
end

----------------------------------------------------
-- FUNGSI GET PLANT UUID
----------------------------------------------------
local function getPlantUUID(plantModel)
	if not plantModel then return nil end

	for _, attr in ipairs({"UUID", "PlantUUID", "PlantId", "PlotId", "Id", "GUID", "UniqueId"}) do
		local val = plantModel:GetAttribute(attr)
		if val and type(val) == "string" and #val >= 10 then
			return val
		end
	end

	local pName = plantModel.Name
	local hexUuid = string.match(pName, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x")
	if hexUuid then
		return hexUuid
	end

	local matchEnd = string.match(pName, "_([%w%-]+)$")
	if matchEnd and #matchEnd >= 10 then
		return matchEnd
	end

	return pName
end

----------------------------------------------------
-- FUNGSI GET PACKET REMOTE
----------------------------------------------------
local function getPacketRemote()
	if packetRemote and packetRemote.Parent ~= nil then return packetRemote end
	pcall(function()
		local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules") or ReplicatedStorage:WaitForChild("SharedModules", 2)
		if sharedModules then
			local packetFolder = sharedModules:FindFirstChild("Packet") or sharedModules:WaitForChild("Packet", 2)
			if packetFolder then
				packetRemote = packetFolder:FindFirstChild("RemoteEvent") or packetFolder:WaitForChild("RemoteEvent", 2)
			end
		end
	end)
	return packetRemote
end

----------------------------------------------------
-- FUNGSI GET BEST PATH (langsung $UUID)
----------------------------------------------------
local function getBestPath(plantModel)
	-- Priority 1: attribute UUID langsung pake $
	local uuid = getPlantUUID(plantModel)
	if uuid and #uuid >= 10 then
		return "$" .. uuid
	end
	-- Priority 2: plant name
	local name = plantModel.Name
	if name and #name > 0 then
		return "$" .. name
	end
	return "$plant"
end

----------------------------------------------------
-- FUNGSI HARVEST - PAKET LENGTH-PREFIX (kaya contoh: \215\000$UUID\00220)
----------------------------------------------------
local function harvestAllGardenFruits()
	if not Settings.IsRunning then return 0 end
	local harvestedCount = 0

	local remote = nil
	pcall(function() remote = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent") end)
	if not remote then remote = getPacketRemote() end
	if not remote then print("[Harvest] RemoteEvent gak ketemu"); return 0 end

	pcall(function()
		local gardenContainers = {
			Workspace:FindFirstChild("Gardens"), Workspace:FindFirstChild("Plots"),
			Workspace:FindFirstChild("Farm"), Workspace:FindFirstChild("GardenPlots"),
			Workspace:FindFirstChild("Garden"), Workspace:FindFirstChild("MyPlot"), Workspace
		}

		for _, folder in ipairs(gardenContainers) do
			if folder then
				for _, plot in ipairs(folder:GetChildren()) do
					if isMyGardenPlot(plot) or folder ~= Workspace then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Crops") or plot:FindFirstChild("Fruits") or plot
						if plantsFolder then
							for _, plantModel in ipairs(plantsFolder:GetChildren()) do
								if plantModel:IsA("Model") or plantModel:IsA("Folder") or plantModel:IsA("BasePart") then
									local plantName = plantModel.Name
									local rawName, mutation, variant = resolvePlantDetails(plantModel)
									if variant and variant ~= "Normal" and (mutation == "Normal" or mutation == "") then
										mutation = variant
									end
									local cropDetails = rawName or plantName

									-- CROP FILTER (multi-select)
									local shouldHarvest = false
									if Settings.HarvestCropMode == "All" then
										shouldHarvest = true
									else
										for cName, isSel in pairs(Settings.SelectedHarvestCrops) do
											if isSel then
												local cClean = cleanCropName(cName)
												local pClean = cleanCropName(plantName)
												local dClean = cleanCropName(cropDetails)
												if #cClean > 0 and (pClean == cClean or dClean == cClean or string.find(pClean, cClean) or string.find(dClean, cClean) or string.find(cClean, pClean) or string.find(cClean, dClean)) then
													shouldHarvest = true
													break
												end
											end
										end
									end

									-- MUTATION FILTER
									if shouldHarvest and Settings.HarvestMutationFilter ~= "All" then
										local plantMut = mutation or "Normal"
										if Settings.HarvestMutationFilter ~= plantMut then
											shouldHarvest = false
										end
									end

									if shouldHarvest then
										local path = getBestPath(plantModel)

										-- Collect individual fruits and extract weight for each fruit instance
										local itemsToHarvest = {}
										local seen = {}

										local fruitsFolder = plantModel:FindFirstChild("Fruits") or plantModel:FindFirstChild("Produce")
										if fruitsFolder then
											for _, fChild in ipairs(fruitsFolder:GetChildren()) do
												local numId = fChild:GetAttribute("Id") or fChild:GetAttribute("FruitId") or string.match(fChild.Name, "(%d+)$") or fChild.Name
												local sid = tostring(numId)
												if not seen[sid] then
													seen[sid] = true
													local fw = extractItemWeight(fChild)
													if fw <= 0 then
														for _, desc in ipairs(fChild:GetDescendants()) do
															local w = extractItemWeight(desc)
															if w > fw then fw = w end
														end
													end
													table.insert(itemsToHarvest, { ID = sid, Weight = fw })
												end
											end
										end

										-- Check ProximityPrompts if no fruitsFolder items were found
										if #itemsToHarvest == 0 then
											local pIndex = 0
											for _, desc in ipairs(plantModel:GetDescendants()) do
												if desc:IsA("ProximityPrompt") then
													pIndex = pIndex + 1
													local numId = desc:GetAttribute("Id") or desc:GetAttribute("FruitId") or (desc.Parent and (desc.Parent:GetAttribute("Id") or string.match(desc.Parent.Name, "(%d+)$"))) or tostring(pIndex)
													local sid = tostring(numId)
													if not seen[sid] then
														seen[sid] = true
														local fw = extractItemWeight(desc)
														if fw <= 0 and desc.Parent then
															fw = extractItemWeight(desc.Parent)
														end
														table.insert(itemsToHarvest, { ID = sid, Weight = fw })
													end
												end
											end
										end

										-- Fallback if no specific fruits/prompts detected
										if #itemsToHarvest == 0 then
											local plantW = extractItemWeight(plantModel)
											table.insert(itemsToHarvest, { ID = "1", Weight = plantW })
										end

										-- Evaluate plant-level weights: Since Roblox server executes HarvestPlant(plantModel) when remote $UUID packet is received,
										-- we MUST ensure NO fruit on this plant model violates the weight filter threshold!
										local maxPlantWeight = 0
										local minPlantWeight = 99999
										local hasValidWeight = false

										for _, fItem in ipairs(itemsToHarvest) do
											local fw = fItem.Weight
											if fw > 0 then
												hasValidWeight = true
												if fw > maxPlantWeight then maxPlantWeight = fw end
												if fw < minPlantWeight then minPlantWeight = fw end
											end
										end

										local passWeight = true

										if Settings.HarvestWeightFilter ~= "Disabled" then
											local threshold = tonumber(Settings.HarvestWeightThreshold) or 0
											if Settings.HarvestWeightFilter == "Below" then
												-- BELOW mode: ONLY harvest if we have verified weight data AND the HIGHEST weight on this plant is strictly LESS THAN threshold (< threshold).
												-- If ANY fruit on this plant model is >= threshold (e.g. 2.35kg >= 2.0kg), OR weight is unverified (0), BLOCK THE ENTIRE PLANT!
												if not hasValidWeight or maxPlantWeight >= threshold or maxPlantWeight <= 0 then
													passWeight = false
												end
											elseif Settings.HarvestWeightFilter == "Above" then
												-- ABOVE mode: ONLY harvest if LOWEST weight > threshold
												if not hasValidWeight or minPlantWeight <= threshold then
													passWeight = false
												end
											end
										end

										if passWeight then
											for _, fItem in ipairs(itemsToHarvest) do
												local fid = fItem.ID
												pcall(function()
													local payload = "\215\000" .. path .. string.char(#fid) .. fid
													remote:FireServer(buffer.fromstring(payload))
													harvestedCount = harvestedCount + 1
												end)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	if harvestedCount > 0 then
		print("[Harvest] Total: " .. harvestedCount .. " fruits!")
		invalidateScanCache()
		if Settings.SelectedTab == "Main" and screenGui and screenGui.Parent then
			task.defer(function()
				renderMainPageGarden(true)
			end)
		end
	end
	return harvestedCount
end

----------------------------------------------------
-- AUTO SHOVEL EXECUTOR (EXACT DECOMPILED TOOL PACKET)
----------------------------------------------------
local function findShovelTool()
	local char = player.Character or player.CharacterAdded:Wait()
	
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and string.find(string.lower(item.Name), "shovel") then
				return item
			end
		end
	end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and string.find(string.lower(item.Name), "shovel") then
				pcall(function()
					item.Parent = char
				end)
				task.wait(0.05)
				return item
			end
		end
	end

	return nil
end

local function autoAcceptShovelConfirmation()
	pcall(function()
		local userGen = ReplicatedStorage:FindFirstChild("UserGenerated")
		if userGen then
			local analytics = userGen:FindFirstChild("Analytics")
			if analytics then
				local clientKit = analytics:FindFirstChild("ClientKit")
				if clientKit then
					local acceptRemote = clientKit:FindFirstChild("Accept")
					if acceptRemote then
						if acceptRemote:IsA("RemoteEvent") then
							acceptRemote:FireServer()
						elseif acceptRemote:IsA("RemoteFunction") then
							acceptRemote:InvokeServer()
						end
					end
				end
			end
		end
	end)
end

local function executeAutoShovel()
	if not Settings.IsRunning then return 0 end

	local char = player.Character
	if not char then return 0 end
	local humanoid = char:FindFirstChild("Humanoid")

	local shovelTool = findShovelTool()
	local remote = getPacketRemote()
	if not shovelTool or not remote then return 0 end

	autoAcceptShovelConfirmation()

	if humanoid then
		if shovelTool.Parent ~= char then
			pcall(function()
				humanoid:EquipTool(shovelTool)
			end)
			task.wait(0.12)
		end
	end

	local activeTool = (shovelTool.Parent == char and shovelTool) or char:FindFirstChildOfClass("Tool") or shovelTool
	local shoveledCount = 0
	local playerUserId = tostring(player.UserId)
	local toolName = activeTool.Name

	pcall(function()
		activeTool:Activate()
	end)

	pcall(function()
		local gardenContainers = {
			Workspace:FindFirstChild("Gardens"),
			Workspace:FindFirstChild("Plots"),
			Workspace:FindFirstChild("Farm"),
			Workspace:FindFirstChild("GardenPlots"),
			Workspace:FindFirstChild("Garden"),
			Workspace:FindFirstChild("MyPlot"),
			Workspace
		}

		for _, folder in ipairs(gardenContainers) do
			if folder then
				for _, plot in ipairs(folder:GetChildren()) do
					if isMyGardenPlot(plot) or folder ~= Workspace then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Crops") or plot:FindFirstChild("Fruits") or plot
						if plantsFolder then
							for _, plantModel in ipairs(plantsFolder:GetChildren()) do
								if plantModel:IsA("Model") or plantModel:IsA("Folder") or plantModel:IsA("BasePart") then
									local plantName = plantModel.Name
									local cropDetails = resolvePlantDetails(plantModel) or plantName

									local shouldShovel = false
									if Settings.AutoShovelMode == "All" then
										shouldShovel = true
									elseif Settings.AutoShovelMode == "Selected" then
										for cName, isSel in pairs(Settings.SelectedShovelCrops) do
											if isSel then
												local cClean = cleanCropName(cName)
												local pClean = cleanCropName(plantName)
												local dClean = cleanCropName(cropDetails)

												if #cClean > 0 and (pClean == cClean or dClean == cClean or string.find(pClean, cClean) or string.find(dClean, cClean) or string.find(cClean, pClean) or string.find(cClean, dClean)) then
													shouldShovel = true
													break
												end
											end
										end
									end

									if shouldShovel then
										local candidatePaths = {}
										local seenPaths = {}
										local function addP(p)
											if p and type(p) == "string" and #p > 0 then
												if not seenPaths[p] then
													seenPaths[p] = true
													table.insert(candidatePaths, p)
												end

												local firstChar = string.sub(p, 1, 1)
												if firstChar ~= "$" and firstChar ~= "/" then
													local pDollar = "$" .. p
													if not seenPaths[pDollar] then
														seenPaths[pDollar] = true
														table.insert(candidatePaths, pDollar)
													end

													local pSlash = "/" .. p
													if not seenPaths[pSlash] then
														seenPaths[pSlash] = true
														table.insert(candidatePaths, pSlash)
													end

													local pUser = "/" .. playerUserId .. "_" .. p
													if not seenPaths[pUser] then
														seenPaths[pUser] = true
														table.insert(candidatePaths, pUser)
													end
												end
											end
										end

										for _, attr in ipairs({"Path", "PlantPath", "UUID", "PlantUUID", "PlantId", "PlotId", "Id", "GUID", "UniqueId", "Key", "Target"}) do
											local val = plantModel:GetAttribute(attr)
											if val and type(val) == "string" and #val > 1 then
												addP(val)
											end
										end

										for _, child in ipairs(plantModel:GetChildren()) do
											if child:IsA("StringValue") and child.Value and #child.Value > 1 then
												addP(child.Value)
											end
										end

										local uuidStr = getPlantUUID(plantModel)
										if uuidStr then
											addP(uuidStr)
										end

										if plantName ~= uuidStr then
											addP(plantName)
										end

										for _, targetPath in ipairs(candidatePaths) do
											pcall(function()
												local payloadStrB = "a\000" .. targetPath .. "\000" .. string.char(#toolName) .. toolName
												remote:FireServer(buffer.fromstring(payloadStrB), { activeTool })
											end)

											pcall(function()
												local payloadStrA = "a\000" .. targetPath .. "\000" .. string.char(#toolName) .. toolName .. "c\000"
												remote:FireServer(buffer.fromstring(payloadStrA), { activeTool })
											end)

											pcall(function()
												autoAcceptShovelConfirmation()
											end)

											pcall(function()
												activeTool:Activate()
											end)

											shoveledCount = shoveledCount + 1
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	return shoveledCount
end

----------------------------------------------------
-- ROBUST GARDEN PLANT TARGET POSITION FINDER
----------------------------------------------------
local function getGardenPlantTargets(cropMode, selectedCrops)
	local targetPositions = {}
	local addedSet = {}

	pcall(function()
		local gardenContainers = {
			Workspace:FindFirstChild("Gardens"),
			Workspace:FindFirstChild("Plots"),
			Workspace:FindFirstChild("Farm"),
			Workspace:FindFirstChild("GardenPlots"),
			Workspace:FindFirstChild("Garden"),
			Workspace:FindFirstChild("MyPlot"),
			Workspace
		}

		for _, folder in ipairs(gardenContainers) do
			if folder then
				for _, plot in ipairs(folder:GetChildren()) do
					if isMyGardenPlot(plot) or folder ~= Workspace then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Crops") or plot:FindFirstChild("Fruits") or plot
						if plantsFolder then
							for _, plantModel in ipairs(plantsFolder:GetChildren()) do
								if plantModel:IsA("Model") or plantModel:IsA("Folder") or plantModel:IsA("BasePart") then
									local realName = resolvePlantDetails(plantModel) or plantModel.Name
									local isMatch = false

									if cropMode == "All" or not cropMode then
										isMatch = true
									else
										if selectedCrops[realName] == true then
											isMatch = true
										else
											for cName, isSel in pairs(selectedCrops) do
												if isSel and (string.lower(realName) == string.lower(cName) or string.find(string.lower(realName), string.lower(cName)) or string.find(string.lower(plantModel.Name), string.lower(cName))) then
													isMatch = true
													break
												end
											end
										end
									end

									if isMatch then
										local pos = nil
										if plantModel:IsA("Model") then
											pos = plantModel:GetPivot().Position
										elseif plantModel:IsA("BasePart") then
											pos = plantModel.Position
										elseif plantModel:IsA("Folder") then
											local pPart = plantModel:FindFirstChildWhichIsA("BasePart", true)
											if pPart then pos = pPart.Position end
										end

										if pos and not addedSet[plantModel] then
											addedSet[plantModel] = true
											table.insert(targetPositions, pos)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	if #targetPositions == 0 then
		pcall(function()
			for _, desc in ipairs(Workspace:GetChildren()) do
				if desc:IsA("Model") and (desc:FindFirstChild("Plants") or desc:FindFirstChild("Fruits") or desc:FindFirstChild("Produce") or string.find(string.lower(desc.Name), "plot") or string.find(string.lower(desc.Name), "plant")) then
					for _, pItem in ipairs(desc:GetChildren()) do
						local realName = resolvePlantDetails(pItem) or pItem.Name
						local isMatch = false

						if cropMode == "All" or not cropMode then
							isMatch = true
						else
							if selectedCrops[realName] == true then
								isMatch = true
							else
								for cName, isSel in pairs(selectedCrops) do
									if isSel and (string.lower(realName) == string.lower(cName) or string.find(string.lower(realName), string.lower(cName))) then
										isMatch = true
										break
									end
								end
							end
						end

						if isMatch then
							local pos = pItem:IsA("Model") and pItem:GetPivot().Position or pItem:FindFirstChildWhichIsA("BasePart", true) and pItem:FindFirstChildWhichIsA("BasePart", true).Position
							if pos and not addedSet[pItem] then
								addedSet[pItem] = true
								table.insert(targetPositions, pos)
							end
						end
					end
				end
			end
		end)
	end

	return targetPositions
end

----------------------------------------------------
-- AUTO PLACE SPRINKLER EXECUTOR
----------------------------------------------------
local function buildPlaceSprinklerBuffer(pos, sprinklerName)
	sprinklerName = sprinklerName or "Common Sprinkler"
	local nameLen = #sprinklerName
	local totalLen = 2 + 12 + 1 + nameLen + 1
	local buf = buffer.create(totalLen)
	buffer.writeu16(buf, 0, 26)
	buffer.writef32(buf, 2, pos.X)
	buffer.writef32(buf, 6, pos.Y)
	buffer.writef32(buf, 10, pos.Z)
	buffer.writeu8(buf, 14, nameLen)
	buffer.writestring(buf, 15, sprinklerName, nameLen)
	buffer.writeu8(buf, 15 + nameLen, 1)
	return buf
end

local function executeAutoPlaceSprinkler()
	local placedCount = 0
	local char = player.Character
	if not char then return 0 end
	local backpack = player:FindFirstChild("Backpack")
	local humanoid = char:FindFirstChild("Humanoid")

	local sprinklerTools = {}
	local toolMode = Settings.SprinklerToolMode or "All"

	local function checkSprinklerTool(item)
		if item:IsA("Tool") and string.find(string.lower(item.Name), "sprinkler") then
			if toolMode == "All" then
				table.insert(sprinklerTools, item)
			else
				for tName, isSel in pairs(Settings.SelectedSprinklerTools) do
					if isSel and string.lower(item.Name) == string.lower(tName) then
						table.insert(sprinklerTools, item)
						break
					end
				end
			end
		end
	end

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do checkSprinklerTool(item) end
	end
	for _, item in ipairs(char:GetChildren()) do checkSprinklerTool(item) end

	if #sprinklerTools == 0 then return 0 end

	local targetPositions = {}
	local mode = Settings.SprinklerTargetMode or "Plant"

	if mode == "Player" then
		if char:FindFirstChild("HumanoidRootPart") then
			table.insert(targetPositions, char.HumanoidRootPart.Position)
		end
	elseif mode == "Custom" then
		local cPos = Settings.SprinklerCustomPos or {X = 0, Y = 0, Z = 0}
		table.insert(targetPositions, Vector3.new(cPos.X or 0, cPos.Y or 0, cPos.Z or 0))
	else
		targetPositions = getGardenPlantTargets(Settings.SprinklerCropMode, Settings.SelectedSprinklerCrops)
		-- Nearest 1 plant only
		if #targetPositions > 0 and char:FindFirstChild("HumanoidRootPart") then
			local cp = char.HumanoidRootPart.Position
			local nearest, nd = nil, math.huge
			for _, p in ipairs(targetPositions) do
				local d = (p - cp).Magnitude
				if d < nd then nd = d; nearest = p end
			end
			targetPositions = nearest and {nearest} or {}
		elseif #targetPositions == 0 and char:FindFirstChild("HumanoidRootPart") then
			table.insert(targetPositions, char.HumanoidRootPart.Position)
		end
	end

	if #targetPositions == 0 then return 0 end

	local remote = getPacketRemote()
	if remote then
		for _, tool in ipairs(sprinklerTools) do
			if humanoid then
				if tool.Parent ~= char then
					pcall(function() humanoid:EquipTool(tool) end)
					task.wait(0.12)
				end
			end

			local activeTool = (tool.Parent == char and tool) or char:FindFirstChildOfClass("Tool") or tool

			for _, pos in ipairs(targetPositions) do
				pcall(function()
					local buf = buildPlaceSprinklerBuffer(pos, activeTool.Name)
					remote:FireServer(buf, { activeTool })
					placedCount = placedCount + 1
				end)
				task.wait(0.03)
			end
		end
	end

	if humanoid then
		pcall(function() humanoid:UnequipTools() end)
	end

	return placedCount
end

----------------------------------------------------
-- AUTO WATERING EXECUTOR
----------------------------------------------------
local function buildWateringCanBuffer(pos, wateringCanName)
	wateringCanName = wateringCanName or "Common Watering Can"
	local nameLen = #wateringCanName
	local totalLen = 2 + 12 + 1 + nameLen
	local buf = buffer.create(totalLen)
	buffer.writeu16(buf, 0, 73)
	buffer.writef32(buf, 2, pos.X)
	buffer.writef32(buf, 6, pos.Y)
	buffer.writef32(buf, 10, pos.Z)
	buffer.writeu8(buf, 14, nameLen)
	buffer.writestring(buf, 15, wateringCanName, nameLen)
	return buf
end

local function executeAutoWatering()
	local wateredCount = 0
	local char = player.Character
	if not char then return 0 end
	local backpack = player:FindFirstChild("Backpack")
	local humanoid = char:FindFirstChild("Humanoid")

	local wateringTools = {}
	local toolMode = Settings.WateringToolMode or "All"

	local function checkWateringTool(item)
		if item:IsA("Tool") and (string.find(string.lower(item.Name), "watering can") or string.find(string.lower(item.Name), "wateringcan") or string.find(string.lower(item.Name), "water")) then
			if toolMode == "All" then
				table.insert(wateringTools, item)
			else
				for tName, isSel in pairs(Settings.SelectedWateringTools) do
					if isSel and string.lower(item.Name) == string.lower(tName) then
						table.insert(wateringTools, item)
						break
					end
				end
			end
		end
	end

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do checkWateringTool(item) end
	end
	for _, item in ipairs(char:GetChildren()) do checkWateringTool(item) end

	if #wateringTools == 0 then return 0 end

	local plantPositions = {}
	local mode = Settings.WateringTargetMode or "Plant"

	if mode == "Player" then
		if char:FindFirstChild("HumanoidRootPart") then
			table.insert(plantPositions, char.HumanoidRootPart.Position)
		end
	elseif mode == "Custom" then
		local cPos = Settings.WateringCustomPos or {X = 0, Y = 0, Z = 0}
		table.insert(plantPositions, Vector3.new(cPos.X or 0, cPos.Y or 0, cPos.Z or 0))
	else
		plantPositions = getGardenPlantTargets(Settings.WateringCropMode, Settings.SelectedWateringCrops)
		-- Nearest 1 plant only
		if #plantPositions > 0 and char:FindFirstChild("HumanoidRootPart") then
			local cp = char.HumanoidRootPart.Position
			local nearest, nd = nil, math.huge
			for _, p in ipairs(plantPositions) do
				local d = (p - cp).Magnitude
				if d < nd then nd = d; nearest = p end
			end
			plantPositions = nearest and {nearest} or {}
		elseif #plantPositions == 0 and char:FindFirstChild("HumanoidRootPart") then
			table.insert(plantPositions, char.HumanoidRootPart.Position)
		end
	end

	if #plantPositions == 0 then return 0 end

	local remote = getPacketRemote()
	if remote then
		for _, tool in ipairs(wateringTools) do
			if humanoid then
				if tool.Parent ~= char then
					pcall(function() humanoid:EquipTool(tool) end)
					task.wait(0.12)
				end
			end

			local activeTool = (tool.Parent == char and tool) or char:FindFirstChildOfClass("Tool") or tool

			for _, pos in ipairs(plantPositions) do
				pcall(function()
					local buf = buildWateringCanBuffer(pos, activeTool.Name)
					remote:FireServer(buf, { activeTool })
					wateredCount = wateredCount + 1
				end)
				task.wait(0.03)
			end
		end
	end

	if humanoid then
		pcall(function() humanoid:UnequipTools() end)
	end

	return wateredCount
end

----------------------------------------------------
-- EXACT DECOMPILED REMOTE EVENT SELL EXECUTOR
----------------------------------------------------
local function executeWorkspaceSell()
	if not Settings.IsRunning then return false end
	local sold = false

	if packetRemote then
		pcall(function()
			local exactBuffers = {
				"\190\000\021",
				"\189\000\022",
				"\134\000",
				"\135\000",
				"\136\000",
				"\137\000",
				"\216\000",
				"\217\000"
			}
			for _, bufStr in ipairs(exactBuffers) do
				packetRemote:FireServer(buffer.fromstring(bufStr))
				sold = true
			end
		end)
	end

	if PacketModule then
		pcall(function()
			local pktNames = {"SellAll", "SellProduce", "SellInventory", "MerchantSell", "Sell"}
			for _, name in ipairs(pktNames) do
				local pkt = PacketModule(name)
				if pkt then
					pkt:Fire()
					sold = true
				end
			end
		end)
	end

	pcall(function()
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				local text = string.lower(desc.ObjectText .. " " .. desc.ActionText)
				if string.find(text, "sell") or string.find(text, "merchant") then
					if fireproximityprompt then
						fireproximityprompt(desc)
						sold = true
					end
				end
			end
		end
	end)

	return sold
end

----------------------------------------------------
-- BUY SEEDS & BUY GEARS PACKET EXECUTORS
----------------------------------------------------
local function fireBuySeedPacket(seedName, quantity)
	if not seedName or #seedName == 0 then return false end
	quantity = quantity or 5
	local success = false

	if PacketModule then
		pcall(function()
			local buyPkt = PacketModule("BuySeed") or PacketModule("PurchaseSeed")
			if buyPkt then
				for i = 1, quantity do
					buyPkt:Fire(seedName)
					success = true
					if quantity > 1 then task.wait(0.03) end
				end
			end
		end)
	end

	if packetRemote then
		pcall(function()
			local payloadStr = "\133\000" .. string.char(#seedName) .. tostring(seedName)
			local buf = buffer.fromstring(payloadStr)
			for i = 1, quantity do
				packetRemote:FireServer(buf)
				success = true
				if quantity > 1 then task.wait(0.03) end
			end
		end)
	end

	return success
end

local function fireBuyGearPacket(gearName, quantity)
	if not gearName or #gearName == 0 then return false end
	quantity = quantity or 5
	local success = false

	local nameVariants = { gearName }
	local noSpace = string.gsub(gearName, "%s+", "")
	if not table.find(nameVariants, noSpace) then table.insert(nameVariants, noSpace) end

	if string.find(gearName, "Watering Can") then
		local vars = {"Watering Can", "WateringCan", "Common Watering Can", "CommonWateringCan", "Basic Watering Can"}
		for _, v in ipairs(vars) do
			if not table.find(nameVariants, v) then table.insert(nameVariants, v) end
		end
	end
	if string.find(gearName, "Sprinkler") then
		local vars = {"Sprinkler", "Common Sprinkler", "CommonSprinkler", "Basic Sprinkler"}
		for _, v in ipairs(vars) do
			if not table.find(nameVariants, v) then table.insert(nameVariants, v) end
		end
	end

	if packetRemote then
		pcall(function()
			for _, variant in ipairs(nameVariants) do
				local payloadStr = "\137\000" .. string.char(#variant) .. tostring(variant)
				local buf = buffer.fromstring(payloadStr)
				for i = 1, quantity do
					packetRemote:FireServer(buf)
					success = true
					if quantity > 1 then task.wait(0.03) end
				end
			end
		end)
	end

	if PacketModule then
		pcall(function()
			local buyPkt = PacketModule("BuyGear") or PacketModule("PurchaseGear") or PacketModule("BuyTool")
			if buyPkt then
				for _, variant in ipairs(nameVariants) do
					for i = 1, quantity do
						buyPkt:Fire(variant)
						success = true
						if quantity > 1 then task.wait(0.03) end
					end
				end
			end
		end)
	end

	return success
end

----------------------------------------------------
-- WIDE LANDSCAPE GUI WITH DRAGGABLE FLOATING ICON (GEIST DARK MODERN THEME)
----------------------------------------------------
local targetParent = nil
pcall(function() if gethui then targetParent = gethui() end end)
if not targetParent then pcall(function() targetParent = game:GetService("CoreGui") end) end
if not targetParent then targetParent = player:WaitForChild("PlayerGui") end

if targetParent:FindFirstChild("LandscapeGardenGui") then
	targetParent.LandscapeGardenGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LandscapeGardenGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = targetParent

local scriptConnections = {}

-- Wrap everything after this in an IIFE to avoid Luau 200 local limit
(function()

local function cleanupScript()
	pcall(function() if type(clearEspHighlights) == "function" then clearEspHighlights() end end)
	pcall(function() if type(stopHoldingE) == "function" then stopHoldingE() end end)
	Settings.IsRunning = false
	Settings.AutoHarvest = false
	Settings.AutoWatering = false
	Settings.AutoShovel = false
	Settings.AutoShovelMode = "Selected"
	table.clear(Settings.SelectedShovelCrops)
	Settings.AutoPlaceSprinkler = false
	Settings.AutoSell = false
	Settings.AutoSellPets = false
	Settings.AutoBuySeeds = false
	Settings.AutoBuyGears = false

	for _, conn in ipairs(scriptConnections) do
		pcall(function() conn:Disconnect() end)
	end
	scriptConnections = {}

	pcall(function()
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end
	end)
	print("[Grow a Garden 2] Script successfully unloaded and destroyed.")
end

-- Color Tokens (Geist Dark Modern Theme)
local GeistColors = {
	Background   = Color3.fromRGB(10, 11, 15),      -- #0a0b0f (Geist Midnight)
	HeaderBg     = Color3.fromRGB(15, 16, 23),      -- #0f1017 (Geist Header)
	SidebarBg    = Color3.fromRGB(8, 9, 13),        -- #08090d (Geist Sidebar)
	CardBg       = Color3.fromRGB(18, 20, 29),      -- #12141d (Geist Slate Card)
	CardHover    = Color3.fromRGB(25, 28, 40),      -- #191c28
	Primary      = Color3.fromRGB(129, 140, 248),   -- #818cf8 (Geist Electric Indigo)
	PrimaryDark  = Color3.fromRGB(79, 70, 229),     -- #4f46e5
	Emerald      = Color3.fromRGB(34, 197, 94),     -- #22c55e (Geist Cyber Emerald)
	TextMain     = Color3.fromRGB(243, 244, 246),   -- #f3f4f6 (Geist Crisp White)
	TextMuted    = Color3.fromRGB(156, 163, 175),   -- #9ca3af (Geist Silver Muted)
	BorderStroke = Color3.fromRGB(129, 140, 248),   -- Geist Subtle Border
	ErrorRed     = Color3.fromRGB(244, 63, 94)      -- #f43f5e
}

-- Modern Floating Widget Open Icon (Geist Dark Theme)
local openIcon = Instance.new("TextButton")
openIcon.Name = "OpenWorkspaceGuiButton"
openIcon.Size = UDim2.new(0, 52, 0, 52)
openIcon.Position = UDim2.new(0, 20, 0.5, -26)
openIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 25)
openIcon.Text = "🌱"
openIcon.TextColor3 = GeistColors.TextMain
openIcon.Font = Enum.Font.GothamBold
openIcon.TextSize = 22
openIcon.Visible = false
openIcon.Parent = screenGui

local openIconCorner = Instance.new("UICorner")
openIconCorner.CornerRadius = UDim.new(0, 26)
openIconCorner.Parent = openIcon

local openIconStroke = Instance.new("UIStroke")
openIconStroke.Color = GeistColors.Primary
openIconStroke.Thickness = 2
openIconStroke.Parent = openIcon

-- Green Cyber Pulse Status Dot on floating icon
local openStatusDot = Instance.new("Frame")
openStatusDot.Size = UDim2.new(0, 10, 0, 10)
openStatusDot.Position = UDim2.new(1, -12, 0, 4)
openStatusDot.BackgroundColor3 = GeistColors.Emerald
openStatusDot.BorderSizePixel = 0
openStatusDot.Parent = openIcon

local osdCorner = Instance.new("UICorner")
osdCorner.CornerRadius = UDim.new(0, 5)
osdCorner.Parent = openStatusDot

local osdStroke = Instance.new("UIStroke")
osdStroke.Color = Color3.fromRGB(15, 16, 25)
osdStroke.Thickness = 1.5
osdStroke.Parent = openStatusDot

openIcon.MouseEnter:Connect(function()
	openIcon.BackgroundColor3 = Color3.fromRGB(25, 28, 42)
	openIconStroke.Color = Color3.fromRGB(165, 180, 252)
end)

openIcon.MouseLeave:Connect(function()
	openIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 25)
	openIconStroke.Color = GeistColors.Primary
end)

local function toggleGuiFromIcon()
	if mainFrame then
		mainFrame.Visible = true
		openIcon.Visible = false
	end
end
openIcon.MouseButton1Click:Connect(toggleGuiFromIcon)
openIcon.Activated:Connect(toggleGuiFromIcon)

-- Landscape Wide Frame (Smooth Rounded Edges)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0.68, 0, 0.62, 0)
mainFrame.BackgroundColor3 = GeistColors.Background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(540, 360)
sizeConstraint.MaxSize = Vector2.new(900, 620)
sizeConstraint.Parent = mainFrame

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = GeistColors.BorderStroke
frameStroke.Transparency = 0.70
frameStroke.Thickness = 1.5
frameStroke.Parent = mainFrame

-- Title Bar (Rounded Corners)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = GeistColors.HeaderBg
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -135, 1, 0)
titleText.Position = UDim2.new(0, 14, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🌱 GROW A GARDEN 2 HUB <font color=\"#9ca3af\">| Geist Dark</font>"
titleText.RichText = true
titleText.TextColor3 = GeistColors.Primary
titleText.TextSize = 13
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Control Buttons (Minimize, Maximize, Close) with Clean ASCII Icons & Hover Effects
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeButton"
minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
minimizeBtn.Position = UDim2.new(1, -94, 0.5, -13)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = GeistColors.TextMuted
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

local minStroke = Instance.new("UIStroke")
minStroke.Color = GeistColors.BorderStroke
minStroke.Transparency = 0.90
minStroke.Parent = minimizeBtn

minimizeBtn.MouseEnter:Connect(function()
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 58)
	minimizeBtn.TextColor3 = GeistColors.TextMain
end)
minimizeBtn.MouseLeave:Connect(function()
	minimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
	minimizeBtn.TextColor3 = GeistColors.TextMuted
end)

local function minimizeGui()
	mainFrame.Visible = false
	openIcon.Visible = true
end
minimizeBtn.MouseButton1Click:Connect(minimizeGui)
minimizeBtn.Activated:Connect(minimizeGui)

local maximizeBtn = Instance.new("TextButton")
maximizeBtn.Name = "MaximizeButton"
maximizeBtn.Size = UDim2.new(0, 26, 0, 26)
maximizeBtn.Position = UDim2.new(1, -62, 0.5, -13)
maximizeBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
maximizeBtn.Text = "+"
maximizeBtn.TextColor3 = GeistColors.TextMuted
maximizeBtn.Font = Enum.Font.GothamBold
maximizeBtn.TextSize = 14
maximizeBtn.Parent = titleBar

local maxCorner = Instance.new("UICorner")
maxCorner.CornerRadius = UDim.new(0, 6)
maxCorner.Parent = maximizeBtn

local maxStroke = Instance.new("UIStroke")
maxStroke.Color = GeistColors.BorderStroke
maxStroke.Transparency = 0.90
maxStroke.Parent = maximizeBtn

maximizeBtn.MouseEnter:Connect(function()
	maximizeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 58)
	maximizeBtn.TextColor3 = GeistColors.TextMain
end)
maximizeBtn.MouseLeave:Connect(function()
	maximizeBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
	maximizeBtn.TextColor3 = GeistColors.TextMuted
end)

local function toggleMaximizeGui()
	Settings.IsMaximized = not Settings.IsMaximized
	if Settings.IsMaximized then
		mainFrame.Size = UDim2.new(0.96, 0, 0.92, 0)
		maximizeBtn.Text = "🗖"
	else
		mainFrame.Size = UDim2.new(0.68, 0, 0.62, 0)
		maximizeBtn.Text = "+"
	end
end
maximizeBtn.MouseButton1Click:Connect(toggleMaximizeGui)
maximizeBtn.Activated:Connect(toggleMaximizeGui)

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 28)
closeBtn.Text = "X"
closeBtn.TextColor3 = GeistColors.ErrorRed
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = GeistColors.ErrorRed
closeStroke.Transparency = 0.80
closeStroke.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	closeBtn.BackgroundColor3 = GeistColors.ErrorRed
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
closeBtn.MouseLeave:Connect(function()
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 28)
	closeBtn.TextColor3 = GeistColors.ErrorRed
end)

local confirmModal = nil

local function handleCloseClick()
	if confirmModal then
		confirmModal.Visible = true
	else
		cleanupScript()
	end
end
closeBtn.MouseButton1Click:Connect(handleCloseClick)
closeBtn.Activated:Connect(handleCloseClick)

-- Close Confirmation Modal Popup
confirmModal = Instance.new("Frame")
confirmModal.Name = "ConfirmCloseModal"
confirmModal.Size = UDim2.new(1, 0, 1, 0)
confirmModal.Position = UDim2.new(0, 0, 0, 0)
confirmModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
confirmModal.BackgroundTransparency = 0.50
confirmModal.Visible = false
confirmModal.ZIndex = 999
confirmModal.Parent = screenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 16)
modalCorner.Parent = confirmModal

local modalCard = Instance.new("Frame")
modalCard.Name = "ModalCard"
modalCard.AnchorPoint = Vector2.new(0.5, 0.5)
modalCard.Position = UDim2.new(0.5, 0, 0.5, 0)
modalCard.Size = UDim2.new(0, 360, 0, 180)
modalCard.BackgroundColor3 = GeistColors.CardBg
modalCard.ZIndex = 1000
modalCard.Parent = confirmModal

local mcCorner = Instance.new("UICorner")
mcCorner.CornerRadius = UDim.new(0, 14)
mcCorner.Parent = modalCard

local mcStroke = Instance.new("UIStroke")
mcStroke.Color = GeistColors.BorderStroke
mcStroke.Transparency = 0.70
mcStroke.Thickness = 1.5
mcStroke.Parent = modalCard

local mcTitle = Instance.new("TextLabel")
mcTitle.Size = UDim2.new(1, -32, 0, 24)
mcTitle.Position = UDim2.new(0, 16, 0, 18)
mcTitle.BackgroundTransparency = 1
mcTitle.Text = "⚠️  Exit & Unload Script?"
mcTitle.TextColor3 = GeistColors.ErrorRed
mcTitle.Font = Enum.Font.GothamBold
mcTitle.TextSize = 13
mcTitle.TextXAlignment = Enum.TextXAlignment.Left
mcTitle.ZIndex = 1001
mcTitle.Parent = modalCard

local mcDesc = Instance.new("TextLabel")
mcDesc.Size = UDim2.new(1, -32, 0, 48)
mcDesc.Position = UDim2.new(0, 16, 0, 46)
mcDesc.BackgroundTransparency = 1
mcDesc.Text = "Apakah Anda yakin ingin menutup script ini?\nSemua fitur auto farm & auto harvest akan dihentikan."
mcDesc.TextColor3 = GeistColors.TextMuted
mcDesc.Font = Enum.Font.Gotham
mcDesc.TextSize = 10
mcDesc.TextWrapped = true
mcDesc.TextXAlignment = Enum.TextXAlignment.Left
mcDesc.TextYAlignment = Enum.TextYAlignment.Top
mcDesc.ZIndex = 1001
mcDesc.Parent = modalCard

-- Cancel Button
local cancelExitBtn = Instance.new("TextButton")
cancelExitBtn.Size = UDim2.new(0, 154, 0, 34)
cancelExitBtn.Position = UDim2.new(0, 16, 1, -48)
cancelExitBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
cancelExitBtn.Text = "Batal (Cancel)"
cancelExitBtn.TextColor3 = GeistColors.TextMain
cancelExitBtn.Font = Enum.Font.GothamBold
cancelExitBtn.TextSize = 10
cancelExitBtn.ZIndex = 1001
cancelExitBtn.Parent = modalCard

local cebCorner = Instance.new("UICorner")
cebCorner.CornerRadius = UDim.new(0, 8)
cebCorner.Parent = cancelExitBtn

local function hideConfirmModal()
	confirmModal.Visible = false
end
cancelExitBtn.MouseButton1Click:Connect(hideConfirmModal)
cancelExitBtn.Activated:Connect(hideConfirmModal)

-- Confirm Exit Button
local confirmExitBtn = Instance.new("TextButton")
confirmExitBtn.Size = UDim2.new(0, 154, 0, 34)
confirmExitBtn.Position = UDim2.new(1, -170, 1, -48)
confirmExitBtn.BackgroundColor3 = GeistColors.ErrorRed
confirmExitBtn.Text = "Tutup (Unload)"
confirmExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmExitBtn.Font = Enum.Font.GothamBold
confirmExitBtn.TextSize = 10
confirmExitBtn.ZIndex = 1001
confirmExitBtn.Parent = modalCard

local cfeCorner = Instance.new("UICorner")
cfeCorner.CornerRadius = UDim.new(0, 8)
cfeCorner.Parent = confirmExitBtn

local function executeUnload()
	cleanupScript()
end
confirmExitBtn.MouseButton1Click:Connect(executeUnload)
confirmExitBtn.Activated:Connect(executeUnload)

-- Left Vertical Sidebar Navigation Container
local navContainer = Instance.new("Frame")
navContainer.Name = "NavContainer"
navContainer.Size = UDim2.new(0, 130, 1, -54)
navContainer.Position = UDim2.new(0, 10, 0, 48)
navContainer.BackgroundTransparency = 1
navContainer.Parent = mainFrame

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Vertical
navLayout.Padding = UDim.new(0, 6)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = navContainer

local tabButtons = {}
local tabFrames = {}

-- Right Body Container for Pages
local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "BodyFrame"
bodyFrame.Size = UDim2.new(1, -152, 1, -54)
bodyFrame.Position = UDim2.new(0, 144, 0, 48)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

local function createTabPage(tabName)
	local page = Instance.new("Frame")
	page.Name = "Page_" .. tabName
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Position = UDim2.new(0, 0, 0, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = bodyFrame

	tabFrames[tabName] = page
	return page
end

local function switchTab(selectedTab)
	Settings.SelectedTab = selectedTab
	for tName, btn in pairs(tabButtons) do
		local isSel = (tName == selectedTab)
		btn.BackgroundColor3 = isSel and GeistColors.PrimaryDark or GeistColors.CardBg
		btn.TextColor3 = isSel and GeistColors.TextMain or GeistColors.TextMuted
	end
	for tName, page in pairs(tabFrames) do
		page.Visible = (tName == selectedTab)
	end
end

local function createTabButton(tabName, displayText)
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. tabName
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = GeistColors.CardBg
	btn.Text = "   " .. displayText
	btn.TextColor3 = GeistColors.TextMuted
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = navContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = GeistColors.BorderStroke
	btnStroke.Transparency = 0.90
	btnStroke.Parent = btn

	tabButtons[tabName] = btn
	btn.MouseButton1Click:Connect(function()
		switchTab(tabName)
	end)
end

createTabButton("Main", "🏠 MAIN")
createTabButton("Garden", "🌾 GARDEN")
createTabButton("Sell", "💰 SELL")
createTabButton("Buy", "🛒 BUY")
createTabButton("Esp", "👁️ ESP")

----------------------------------------------------
-- TAB 1: MAIN PAGE
----------------------------------------------------
local mainPage = createTabPage("Main")

local mainLeftPanel = Instance.new("Frame")
mainLeftPanel.Size = UDim2.new(0.40, 0, 1, 0)
mainLeftPanel.Position = UDim2.new(0, 0, 0, 0)
mainLeftPanel.BackgroundColor3 = GeistColors.CardBg
mainLeftPanel.BorderSizePixel = 0
mainLeftPanel.Parent = mainPage

local mlCorner = Instance.new("UICorner")
mlCorner.CornerRadius = UDim.new(0, 12)
mlCorner.Parent = mainLeftPanel

local mlStroke = Instance.new("UIStroke")
mlStroke.Color = GeistColors.BorderStroke
mlStroke.Transparency = 0.90
mlStroke.Parent = mainLeftPanel

local accountCard = Instance.new("Frame")
accountCard.Size = UDim2.new(1, -16, 0, 36)
accountCard.Position = UDim2.new(0, 8, 0, 6)
accountCard.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
accountCard.Parent = mainLeftPanel

local acCorner = Instance.new("UICorner")
acCorner.CornerRadius = UDim.new(0, 10)
acCorner.Parent = accountCard

local pAvatarImg = Instance.new("ImageLabel")
pAvatarImg.Size = UDim2.new(0, 28, 0, 28)
pAvatarImg.Position = UDim2.new(0, 4, 0.5, -14)
pAvatarImg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
pAvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
pAvatarImg.Parent = accountCard

local pAvCorner = Instance.new("UICorner")
pAvCorner.CornerRadius = UDim.new(0, 14)
pAvCorner.Parent = pAvatarImg

local pNameLabel = Instance.new("TextLabel")
pNameLabel.Size = UDim2.new(1, -38, 0, 16)
pNameLabel.Position = UDim2.new(0, 38, 0, 2)
pNameLabel.BackgroundTransparency = 1
pNameLabel.Text = player.DisplayName
pNameLabel.TextColor3 = GeistColors.TextMain
pNameLabel.Font = Enum.Font.GothamBold
pNameLabel.TextSize = 10
pNameLabel.TextXAlignment = Enum.TextXAlignment.Left
pNameLabel.Parent = accountCard

local pUserLabel = Instance.new("TextLabel")
pUserLabel.Size = UDim2.new(1, -38, 0, 14)
pUserLabel.Position = UDim2.new(0, 38, 0, 18)
pUserLabel.BackgroundTransparency = 1
pUserLabel.Text = "@" .. player.Name .. "  •  ID: " .. player.UserId
pUserLabel.TextColor3 = GeistColors.Emerald
pUserLabel.Font = Enum.Font.GothamMedium
pUserLabel.TextSize = 9
pUserLabel.TextXAlignment = Enum.TextXAlignment.Left
pUserLabel.Parent = accountCard

local refreshDetailsBtn = Instance.new("TextButton")
refreshDetailsBtn.Size = UDim2.new(1, -16, 0, 26)
refreshDetailsBtn.Position = UDim2.new(0, 8, 0, 46)
refreshDetailsBtn.BackgroundColor3 = GeistColors.PrimaryDark
refreshDetailsBtn.Text = "🔄 Refresh Farm Details"
refreshDetailsBtn.TextColor3 = GeistColors.TextMain
refreshDetailsBtn.Font = Enum.Font.GothamBold
refreshDetailsBtn.TextSize = 10
refreshDetailsBtn.Parent = mainLeftPanel

local rdCorner = Instance.new("UICorner")
rdCorner.CornerRadius = UDim.new(0, 8)
rdCorner.Parent = refreshDetailsBtn

local metricGridFrame = Instance.new("Frame")
metricGridFrame.Size = UDim2.new(1, -16, 0, 94)
metricGridFrame.Position = UDim2.new(0, 8, 0, 76)
metricGridFrame.BackgroundTransparency = 1
metricGridFrame.Parent = mainLeftPanel

local mgLayout = Instance.new("UIGridLayout")
mgLayout.CellSize = UDim2.new(0.48, -2, 0, 44)
mgLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)
mgLayout.Parent = metricGridFrame

local function createMetricCard(titleText, defaultVal, titleColor)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(25, 28, 40)

	local cCorn = Instance.new("UICorner")
	cCorn.CornerRadius = UDim.new(0, 10)
	cCorn.Parent = card

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.new(1, -8, 0, 16)
	tLbl.Position = UDim2.new(0, 6, 0, 3)
	tLbl.BackgroundTransparency = 1
	tLbl.Text = titleText
	tLbl.TextColor3 = titleColor
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 9
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Parent = card

	local vLbl = Instance.new("TextLabel")
	vLbl.Size = UDim2.new(1, -8, 0, 20)
	vLbl.Position = UDim2.new(0, 6, 0, 19)
	vLbl.BackgroundTransparency = 1
	vLbl.Text = defaultVal
	vLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	vLbl.Font = Enum.Font.GothamBold
	vLbl.TextSize = 11
	vLbl.TextXAlignment = Enum.TextXAlignment.Left
	vLbl.Parent = card

	return card, vLbl
end

local _, kpiTotalPlantsLbl = createMetricCard("Total Plants", "x0", Color3.fromRGB(46, 204, 113))
local _, kpiTotalFruitsLbl = createMetricCard("Total Fruits", "x0", Color3.fromRGB(52, 152, 219))
local _, kpiReadyFruitsLbl = createMetricCard("Ready / Unready", "x0 / x0", Color3.fromRGB(241, 196, 15))
local _, kpiMutatedLbl = createMetricCard("Mutations Count", "x0", Color3.fromRGB(155, 89, 182))

kpiTotalPlantsLbl.Parent.Parent = metricGridFrame
kpiTotalFruitsLbl.Parent.Parent = metricGridFrame
kpiReadyFruitsLbl.Parent.Parent = metricGridFrame
kpiMutatedLbl.Parent.Parent = metricGridFrame

local mutBreakdownHeader = Instance.new("TextLabel")
mutBreakdownHeader.Size = UDim2.new(1, -16, 0, 18)
mutBreakdownHeader.Position = UDim2.new(0, 8, 0, 176)
mutBreakdownHeader.BackgroundTransparency = 1
mutBreakdownHeader.Text = "🧬 Mutations In Farm:"
mutBreakdownHeader.TextColor3 = Color3.fromRGB(231, 76, 60)
mutBreakdownHeader.Font = Enum.Font.GothamBold
mutBreakdownHeader.TextSize = 10
mutBreakdownHeader.TextXAlignment = Enum.TextXAlignment.Left
mutBreakdownHeader.Parent = mainLeftPanel

local mutationBreakdownScroller = Instance.new("ScrollingFrame")
mutationBreakdownScroller.Size = UDim2.new(1, -16, 1, -202)
mutationBreakdownScroller.Position = UDim2.new(0, 8, 0, 198)
mutationBreakdownScroller.BackgroundTransparency = 1
mutationBreakdownScroller.ScrollBarThickness = 3
mutationBreakdownScroller.Parent = mainLeftPanel

local mainRightPanel = Instance.new("Frame")
mainRightPanel.Size = UDim2.new(0.58, 0, 1, 0)
mainRightPanel.Position = UDim2.new(0.42, 0, 0, 0)
mainRightPanel.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
mainRightPanel.BorderSizePixel = 0
mainRightPanel.Parent = mainPage

local mrCorner = Instance.new("UICorner")
mrCorner.CornerRadius = UDim.new(0, 10)
mrCorner.Parent = mainRightPanel

local gardenHeaderLabel = Instance.new("TextLabel")
gardenHeaderLabel.Size = UDim2.new(1, -165, 0, 26)
gardenHeaderLabel.Position = UDim2.new(0, 10, 0, 6)
gardenHeaderLabel.BackgroundTransparency = 1
gardenHeaderLabel.Text = (Settings.MainGardenViewMode == "Grouped") and "🌿 Crops Grouped by Rarity:" or "🍎 Per-Fruit Detailed Inspector:"
gardenHeaderLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
gardenHeaderLabel.Font = Enum.Font.GothamBold
gardenHeaderLabel.TextSize = 10
gardenHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
gardenHeaderLabel.Parent = mainRightPanel

local mainGardenViewModeBtn = Instance.new("TextButton")
mainGardenViewModeBtn.Size = UDim2.new(0, 150, 0, 22)
mainGardenViewModeBtn.Position = UDim2.new(1, -158, 0, 8)
mainGardenViewModeBtn.BackgroundColor3 = Color3.fromRGB(34, 42, 56)
mainGardenViewModeBtn.Text = (Settings.MainGardenViewMode == "Grouped") and "🌿 Mode: Grouped ▼" or "🍎 Mode: Detailed ▼"
mainGardenViewModeBtn.TextColor3 = Color3.fromRGB(241, 196, 15)
mainGardenViewModeBtn.Font = Enum.Font.GothamBold
mainGardenViewModeBtn.TextSize = 9
mainGardenViewModeBtn.Parent = mainRightPanel

local vmCorner = Instance.new("UICorner")
vmCorner.CornerRadius = UDim.new(0, 6)
vmCorner.Parent = mainGardenViewModeBtn

local vmStroke = Instance.new("UIStroke")
vmStroke.Color = GeistColors.BorderStroke
vmStroke.Transparency = 0.90
vmStroke.Parent = mainGardenViewModeBtn

local mainGardenScroller = Instance.new("ScrollingFrame")
mainGardenScroller.Size = UDim2.new(1, -16, 1, -38)
mainGardenScroller.Position = UDim2.new(0, 8, 0, 32)
mainGardenScroller.BackgroundTransparency = 1
mainGardenScroller.ScrollBarThickness = 4
mainGardenScroller.Parent = mainRightPanel

local function renderMainPageGarden(forceRefresh)
	for _, child in ipairs(mainGardenScroller:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("UIListLayout") then child:Destroy() end
	end

	for _, child in ipairs(mutationBreakdownScroller:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("UIListLayout") then child:Destroy() end
	end

	local plantList, totalPlants, totalReadyFruits, totalUnreadyFruits, totalFruits, mutationCounts, cropGroups, fruitList = fetchGardenPlants(forceRefresh)
	local totalMutatedFruits, totalFruitsScanned, mutationSummary, fruitDetails = scanFarmMutations(forceRefresh)

	kpiTotalPlantsLbl.Text = "x" .. totalPlants
	kpiTotalFruitsLbl.Text = "x" .. totalFruits
	kpiReadyFruitsLbl.Text = "x" .. totalReadyFruits .. " / x" .. totalUnreadyFruits
	kpiMutatedLbl.Text = "x" .. totalMutatedFruits
	mutBreakdownHeader.Text = string.format("🧬 Mutations In Farm (x%d):", totalMutatedFruits)

	local mutListLayout = Instance.new("UIListLayout")
	mutListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mutListLayout.Padding = UDim.new(0, 4)
	mutListLayout.Parent = mutationBreakdownScroller

	local totalCanvasHeight = 0
	local summaryRowsCount = 0

	for mutName, data in pairs(mutationSummary) do
		if data.Count > 0 then
			summaryRowsCount = summaryRowsCount + 1
			local mutRow = Instance.new("Frame")
			mutRow.Size = UDim2.new(1, 0, 0, 24)
			mutRow.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
			mutRow.Parent = mutationBreakdownScroller

			local mrCorn = Instance.new("UICorner")
			mrCorn.CornerRadius = UDim.new(0, 8)
			mrCorn.Parent = mutRow

			local mrStroke = Instance.new("UIStroke")
			mrStroke.Color = GeistColors.BorderStroke
			mrStroke.Transparency = 0.92
			mrStroke.Parent = mutRow

			local mutText = Instance.new("TextLabel")
			mutText.Size = UDim2.new(1, -8, 1, 0)
			mutText.Position = UDim2.new(0, 8, 0, 0)
			mutText.BackgroundTransparency = 1
			mutText.Text = mutName .. ": x" .. data.Count
			mutText.TextColor3 = MutationColors[mutName] or Color3.fromRGB(255, 230, 130)
			mutText.Font = Enum.Font.GothamBold
			mutText.TextSize = 10
			mutText.TextXAlignment = Enum.TextXAlignment.Left
			mutText.Parent = mutRow

			totalCanvasHeight = totalCanvasHeight + 28
		end
	end

	if summaryRowsCount == 0 then
		local noMutLbl = Instance.new("TextLabel")
		noMutLbl.Size = UDim2.new(1, 0, 0, 22)
		noMutLbl.BackgroundTransparency = 1
		noMutLbl.Text = "Tidak ada mutasi terdeteksi di farm saat ini."
		noMutLbl.TextColor3 = GeistColors.TextMuted
		noMutLbl.Font = Enum.Font.GothamMedium
		noMutLbl.TextSize = 9
		noMutLbl.TextXAlignment = Enum.TextXAlignment.Left
		noMutLbl.Parent = mutationBreakdownScroller

		totalCanvasHeight = totalCanvasHeight + 26
	end

	mutationBreakdownScroller.CanvasSize = UDim2.new(0, 0, 0, totalCanvasHeight + 10)

	local mainListLayout = Instance.new("UIListLayout")
	mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainListLayout.Padding = UDim.new(0, 4)
	mainListLayout.Parent = mainGardenScroller

	local totalHeight = 0

	if Settings.MainGardenViewMode == "Grouped" then
		gardenHeaderLabel.Text = "🌿 Crops Grouped by Rarity:"

		local RarityOrder = {"Secret", "Super", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
		local groupedByRarity = {}
		for _, rarity in ipairs(RarityOrder) do
			groupedByRarity[rarity] = {}
		end

		if cropGroups then
			for cropName, cData in pairs(cropGroups) do
				local rarity = cData.Rarity or getCropRarity(cropName) or "Common"
				if not groupedByRarity[rarity] then
					groupedByRarity[rarity] = {}
				end
				table.insert(groupedByRarity[rarity], cData)
			end
		end

		local hasAnyCrop = false

		for _, rarity in ipairs(RarityOrder) do
			local cList = groupedByRarity[rarity]
			if #cList > 0 then
				hasAnyCrop = true
				table.sort(cList, function(a, b) return a.Name < b.Name end)

				local rHeader = Instance.new("Frame")
				rHeader.Size = UDim2.new(1, 0, 0, 24)
				rHeader.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
				rHeader.Parent = mainGardenScroller

				local rhCorner = Instance.new("UICorner")
				rhCorner.CornerRadius = UDim.new(0, 6)
				rhCorner.Parent = rHeader

				local rhStroke = Instance.new("UIStroke")
				rhStroke.Color = RarityColors[rarity] or GeistColors.BorderStroke
				rhStroke.Transparency = 0.70
				rhStroke.Parent = rHeader

				local rhLbl = Instance.new("TextLabel")
				rhLbl.Size = UDim2.new(1, -12, 1, 0)
				rhLbl.Position = UDim2.new(0, 8, 0, 0)
				rhLbl.BackgroundTransparency = 1
				rhLbl.Text = string.format("✨ %s CROPS (%d)", string.upper(rarity), #cList)
				rhLbl.TextColor3 = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
				rhLbl.Font = Enum.Font.GothamBold
				rhLbl.TextSize = 10
				rhLbl.TextXAlignment = Enum.TextXAlignment.Left
				rhLbl.Parent = rHeader

				totalHeight = totalHeight + 28

				for _, cData in ipairs(cList) do
					local card = Instance.new("Frame")
					local mutList = {}
					if cData.Mutations then
						for mName, _ in pairs(cData.Mutations) do
							table.insert(mutList, mName)
						end
						table.sort(mutList)
					end
					local hasMut = (#mutList > 0)
					local cardH = hasMut and 54 or 40

					card.Size = UDim2.new(1, 0, 0, cardH)
					card.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
					card.Parent = mainGardenScroller

					local ccCorner = Instance.new("UICorner")
					ccCorner.CornerRadius = UDim.new(0, 8)
					ccCorner.Parent = card

					local ccStroke = Instance.new("UIStroke")
					ccStroke.Color = GeistColors.BorderStroke
					ccStroke.Transparency = 0.92
					ccStroke.Parent = card

					local nameLbl = Instance.new("TextLabel")
					nameLbl.Size = UDim2.new(0.48, -8, 0, 16)
					nameLbl.Position = UDim2.new(0, 8, 0, 2)
					nameLbl.BackgroundTransparency = 1
					nameLbl.Text = "🌱 " .. cData.Name
					nameLbl.TextColor3 = GeistColors.TextMain
					nameLbl.Font = Enum.Font.GothamBold
					nameLbl.TextSize = 10
					nameLbl.TextXAlignment = Enum.TextXAlignment.Left
					nameLbl.Parent = card

					local detailStr = string.format("x%d Plants | 🍎 x%d Fruits (🟢 %d Ready)", cData.Count, cData.TotalFruits or cData.ReadyFruits or 0, cData.ReadyFruits or 0)
					local detailLbl = Instance.new("TextLabel")
					detailLbl.Size = UDim2.new(0.52, -8, 0, 16)
					detailLbl.Position = UDim2.new(0.48, 0, 0, 2)
					detailLbl.BackgroundTransparency = 1
					detailLbl.Text = detailStr
					detailLbl.TextColor3 = Color3.fromRGB(160, 175, 195)
					detailLbl.Font = Enum.Font.GothamMedium
					detailLbl.TextSize = 9
					detailLbl.TextXAlignment = Enum.TextXAlignment.Right
					detailLbl.Parent = card

					-- Gather and sort all fruit weights for this crop type
					local sortedWeights = {}
					if cData.Weights then
						for _, w in ipairs(cData.Weights) do
							if w and w > 0 then table.insert(sortedWeights, w) end
						end
						table.sort(sortedWeights, function(a, b) return a > b end)
					end

					local weightCounts = {}
					local uniqueWeights = {}
					for _, w in ipairs(sortedWeights) do
						local wKey = string.format("%.2f", w)
						if not weightCounts[wKey] then
							weightCounts[wKey] = 1
							table.insert(uniqueWeights, wKey)
						else
							weightCounts[wKey] = weightCounts[wKey] + 1
						end
					end

					local formattedWeights = {}
					for _, wKey in ipairs(uniqueWeights) do
						local count = weightCounts[wKey]
						if count > 1 then
							table.insert(formattedWeights, string.format("%skg (x%d)", wKey, count))
						else
							table.insert(formattedWeights, string.format("%skg", wKey))
						end
					end

					local weightStr = (#formattedWeights > 0) and ("⚖ Weights: " .. table.concat(formattedWeights, ", ")) or "⚖ Weights: ?kg"
					local weightLbl = Instance.new("TextLabel")
					weightLbl.Size = UDim2.new(1, -16, 0, 16)
					weightLbl.Position = UDim2.new(0, 8, 0, 18)
					weightLbl.BackgroundTransparency = 1
					weightLbl.Text = weightStr
					weightLbl.TextColor3 = Color3.fromRGB(243, 156, 18)
					weightLbl.Font = Enum.Font.GothamMedium
					weightLbl.TextSize = 9
					weightLbl.TextXAlignment = Enum.TextXAlignment.Left
					weightLbl.Parent = card

					if hasMut then
						local mutStr = "✨ Mutations: " .. table.concat(mutList, ", ")
						local mutLbl = Instance.new("TextLabel")
						mutLbl.Size = UDim2.new(1, -16, 0, 14)
						mutLbl.Position = UDim2.new(0, 8, 0, 36)
						mutLbl.BackgroundTransparency = 1
						mutLbl.Text = mutStr
						mutLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
						mutLbl.Font = Enum.Font.GothamMedium
						mutLbl.TextSize = 8
						mutLbl.TextXAlignment = Enum.TextXAlignment.Left
						mutLbl.Parent = card
					end

					totalHeight = totalHeight + cardH + 4
				end
			end
		end

		if not hasAnyCrop then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 1, 0)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No Crops Found in Garden Plots"
			emptyLbl.TextColor3 = Color3.fromRGB(150, 160, 175)
			emptyLbl.Font = Enum.Font.Gotham
			emptyLbl.TextSize = 11
			emptyLbl.Parent = mainGardenScroller
			totalHeight = 60
		end
	else
		gardenHeaderLabel.Text = "🍎 Per-Fruit Detailed Inspector:"
		local displayList = (fruitList and #fruitList > 0) and fruitList or {}

		table.sort(displayList, function(a, b)
			if a.Plot ~= b.Plot then return a.Plot < b.Plot end
			if a.PlantName ~= b.PlantName then return a.PlantName < b.PlantName end
			return (a.FruitIndex or 0) < (b.FruitIndex or 0)
		end)

		for _, fData in ipairs(displayList) do
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 36)
			card.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
			card.Parent = mainGardenScroller

			local ccCorner = Instance.new("UICorner")
			ccCorner.CornerRadius = UDim.new(0, 8)
			ccCorner.Parent = card

			local ccStroke = Instance.new("UIStroke")
			ccStroke.Color = GeistColors.BorderStroke
			ccStroke.Transparency = 0.92
			ccStroke.Parent = card

			local titleText = fData.CropName
			if fData.TotalOnPlant and fData.TotalOnPlant > 1 then
				titleText = string.format("%s (#%d/%d)", fData.CropName, fData.FruitIndex, fData.TotalOnPlant)
			end
			if fData.MutationName and fData.MutationName ~= "Normal" then
				titleText = titleText .. " ✨" .. fData.MutationName
			end

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(0.45, -8, 0.5, 0)
			nameLbl.Position = UDim2.new(0, 8, 0, 2)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = titleText
			nameLbl.TextColor3 = (fData.MutationName and fData.MutationName ~= "Normal") and (MutationColors[fData.MutationName] or Color3.fromRGB(255, 215, 0)) or GeistColors.TextMain
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 10
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Parent = card

			local pos = fData.Position
			local posStr = pos and string.format("📍 %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z) or "📍 ?"
			local posLbl = Instance.new("TextLabel")
			posLbl.Size = UDim2.new(0.45, -8, 0.5, 0)
			posLbl.Position = UDim2.new(0, 8, 0, 16)
			posLbl.BackgroundTransparency = 1
			posLbl.Text = posStr
			posLbl.TextColor3 = Color3.fromRGB(100, 180, 255)
			posLbl.Font = Enum.Font.GothamMedium
			posLbl.TextSize = 9
			posLbl.TextXAlignment = Enum.TextXAlignment.Left
			posLbl.Parent = card

			local weightLbl = Instance.new("TextLabel")
			weightLbl.Size = UDim2.new(0.30, -8, 1, 0)
			weightLbl.Position = UDim2.new(0.70, 0, 0, 0)
			weightLbl.BackgroundTransparency = 1
			weightLbl.Text = (fData.Weight and fData.Weight > 0) and string.format("⚖ %.2fkg", fData.Weight) or "⚖ ?kg"
			weightLbl.TextColor3 = Color3.fromRGB(243, 156, 18)
			weightLbl.Font = Enum.Font.GothamBold
			weightLbl.TextSize = 10
			weightLbl.TextXAlignment = Enum.TextXAlignment.Right
			weightLbl.Parent = card

			local statusText = fData.IsReady and "🟢 Ready" or "🟡 Growing"
			local statusLbl = Instance.new("TextLabel")
			statusLbl.Size = UDim2.new(0.25, -8, 1, 0)
			statusLbl.Position = UDim2.new(0.45, 0, 0, 0)
			statusLbl.BackgroundTransparency = 1
			statusLbl.Text = statusText
			statusLbl.TextColor3 = fData.IsReady and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(241, 196, 15)
			statusLbl.Font = Enum.Font.GothamBold
			statusLbl.TextSize = 9
			statusLbl.TextXAlignment = Enum.TextXAlignment.Center
			statusLbl.Parent = card

			totalHeight = totalHeight + 40
		end

		if #displayList == 0 then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 1, 0)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No Fruits Growing in Garden Plots"
			emptyLbl.TextColor3 = Color3.fromRGB(150, 160, 175)
			emptyLbl.Font = Enum.Font.Gotham
			emptyLbl.TextSize = 11
			emptyLbl.Parent = mainGardenScroller
			totalHeight = 60
		end
	end

	mainGardenScroller.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
end

mainGardenViewModeBtn.MouseButton1Click:Connect(function()
	if Settings.MainGardenViewMode == "Grouped" then
		Settings.MainGardenViewMode = "Detailed"
		mainGardenViewModeBtn.Text = "🍎 Mode: Detailed ▼"
		gardenHeaderLabel.Text = "🍎 Per-Fruit Detailed Inspector:"
	else
		Settings.MainGardenViewMode = "Grouped"
		mainGardenViewModeBtn.Text = "🌿 Mode: Grouped ▼"
		gardenHeaderLabel.Text = "🌿 Crops Grouped by Rarity:"
	end
	renderMainPageGarden(false)
end)

refreshDetailsBtn.MouseButton1Click:Connect(function()
	invalidateScanCache()
	renderMainPageGarden(true)
end)

----------------------------------------------------
-- REAL-TIME LIVE FARM SCANNER & WORKSPACE EVENT LISTENERS
----------------------------------------------------
local isGardenRefreshQueued = false
local lastGardenAutoRefresh = 0

local function queueGardenRefresh()
	if isGardenRefreshQueued then return end
	isGardenRefreshQueued = true
	task.delay(2.5, function()
		isGardenRefreshQueued = false
		local now = tick()
		if (now - lastGardenAutoRefresh >= 3.0) and Settings.SelectedTab == "Main" and screenGui and screenGui.Parent then
			lastGardenAutoRefresh = now
			invalidateScanCache()
			renderMainPageGarden(true)
		end
	end)
end

pcall(function()
	local gardenContainers = {
		Workspace:FindFirstChild("Gardens"),
		Workspace:FindFirstChild("Plots"),
		Workspace:FindFirstChild("_Gardens"),
		Workspace:FindFirstChild("Farm"),
		Workspace:FindFirstChild("GardenPlots"),
		Workspace:FindFirstChild("Garden"),
		Workspace:FindFirstChild("MyPlot")
	}

	for _, folder in ipairs(gardenContainers) do
		if folder then
			folder.DescendantRemoving:Connect(queueGardenRefresh)
			folder.ChildAdded:Connect(queueGardenRefresh)
		end
	end
end)

-- Real-time live auto-refresh loop (updates every 4s live using cache when Main tab is open)
task.spawn(function()
	while Settings.IsRunning do
		task.wait(4.0)
		if Settings.SelectedTab == "Main" and screenGui and screenGui.Parent then
			renderMainPageGarden(false)
		end
	end
end)

----------------------------------------------------
-- TAB 2: GARDEN PAGE
----------------------------------------------------
local gardenPage = createTabPage("Garden")

local gLeftPanel = Instance.new("Frame")
gLeftPanel.Size = UDim2.new(0.30, 0, 1, 0)
gLeftPanel.Position = UDim2.new(0, 0, 0, 0)
gLeftPanel.BackgroundTransparency = 1
gLeftPanel.Parent = gardenPage

local gRightPanel = Instance.new("Frame")
gRightPanel.Size = UDim2.new(0.68, 0, 1, 0)
gRightPanel.Position = UDim2.new(0.32, 0, 0, 0)
gRightPanel.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
gRightPanel.BorderSizePixel = 0
gRightPanel.Parent = gardenPage

local grCorner = Instance.new("UICorner")
grCorner.CornerRadius = UDim.new(0, 10)
grCorner.Parent = gRightPanel

local selectedGardenSubTab = "Harvest"
local gardenSubNavButtons = {}

local gardenSubTabs = {
	{Key = "Harvest", Title = "🌾 HARVEST", Color = Color3.fromRGB(241, 196, 15)},
	{Key = "Shovel", Title = "🧹 SHOVEL", Color = Color3.fromRGB(231, 76, 60)},
	{Key = "Sprinkler", Title = "💧 SPRINKLER", Color = Color3.fromRGB(52, 152, 219)},
	{Key = "Watering", Title = "🚿 WATERING", Color = Color3.fromRGB(41, 128, 185)},
	{Key = "Plants", Title = "🌱 GARDEN PLANTS", Color = Color3.fromRGB(46, 204, 113)}
}

local function renderGardenTabList()
	if selectedGardenSubTab == "Plants" then
		renderGardenSubPage("Plants")
	end
end

local function renderGardenSubPage(subTabName)
	selectedGardenSubTab = subTabName or selectedGardenSubTab or "Harvest"

	for name, btn in pairs(gardenSubNavButtons) do
		local isSel = (name == selectedGardenSubTab)
		btn.BackgroundColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		btn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 200, 215)
	end

	for _, child in ipairs(gRightPanel:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	if selectedGardenSubTab == "Harvest" then
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, -16, 0, 26)
		header.Position = UDim2.new(0, 10, 0, 6)
		header.BackgroundTransparency = 1
		header.Text = "🌾 Auto Harvest Controls & Crop Filter"
		header.TextColor3 = Color3.fromRGB(46, 204, 113)
		header.Font = Enum.Font.GothamBold
		header.TextSize = 12
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = gRightPanel

		local harvestToggleBtn = Instance.new("TextButton")
		harvestToggleBtn.Size = UDim2.new(1, -20, 0, 36)
		harvestToggleBtn.Position = UDim2.new(0, 10, 0, 36)
		harvestToggleBtn.BackgroundColor3 = Settings.AutoHarvest and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		harvestToggleBtn.Text = Settings.AutoHarvest and "🌾 Auto Harvest: ON" or "🌾 Auto Harvest: OFF"
		harvestToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		harvestToggleBtn.Font = Enum.Font.GothamBold
		harvestToggleBtn.TextSize = 11
		harvestToggleBtn.Parent = gRightPanel

		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = UDim.new(0, 8)
		hCorner.Parent = harvestToggleBtn

		harvestToggleBtn.MouseButton1Click:Connect(function()
			Settings.AutoHarvest = not Settings.AutoHarvest
			if Settings.AutoHarvest then
				harvestToggleBtn.Text = "🌾 Auto Harvest: ON"
				harvestToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			else
				harvestToggleBtn.Text = "🌾 Auto Harvest: OFF"
				harvestToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
			end
		end)

		-- === MULTI-SELECT CROP DROPDOWN ===
		local cropDropdown = Instance.new("TextButton")
		cropDropdown.Size = UDim2.new(1, -20, 0, 24)
		cropDropdown.Position = UDim2.new(0, 10, 0, 78)
		cropDropdown.BackgroundColor3 = (Settings.HarvestCropMode == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)
		cropDropdown.Text = (Settings.HarvestCropMode == "All") and "  🎯 Crop Filter: ALL Crops ▼" or "  🎯 Crop Filter: Selected Crops ▼"
		cropDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
		cropDropdown.Font = Enum.Font.GothamBold
		cropDropdown.TextSize = 10
		cropDropdown.TextXAlignment = Enum.TextXAlignment.Left
		cropDropdown.Parent = gRightPanel

		local cdCorner = Instance.new("UICorner")
		cdCorner.CornerRadius = UDim.new(0, 6)
		cdCorner.Parent = cropDropdown

		local cropDropFrame = Instance.new("ScrollingFrame")
		cropDropFrame.Size = UDim2.new(1, -20, 0, 140)
		cropDropFrame.Position = UDim2.new(0, 10, 0, 104)
		cropDropFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
		cropDropFrame.BorderSizePixel = 1
		cropDropFrame.BorderColor3 = Color3.fromRGB(142, 68, 173)
		cropDropFrame.Visible = false
		cropDropFrame.ZIndex = 15
		cropDropFrame.ScrollBarThickness = 4
		cropDropFrame.Parent = gRightPanel

		local cropDropCorner = Instance.new("UICorner")
		cropDropCorner.CornerRadius = UDim.new(0, 6)
		cropDropCorner.Parent = cropDropFrame

		local cDropList = Instance.new("UIListLayout")
		cDropList.SortOrder = Enum.SortOrder.LayoutOrder
		cDropList.Padding = UDim.new(0, 1)
		cDropList.Parent = cropDropFrame

		local function renderHarvestCropDropdown()
			for _, child in ipairs(cropDropFrame:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
			end

			local modeRow = Instance.new("Frame")
			modeRow.Size = UDim2.new(1, 0, 0, 24)
			modeRow.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
			modeRow.ZIndex = 16
			modeRow.Parent = cropDropFrame

			local mAllBtn = Instance.new("TextButton")
			mAllBtn.Size = UDim2.new(0.32, 0, 1, -2)
			mAllBtn.Position = UDim2.new(0, 2, 0, 1)
			mAllBtn.BackgroundColor3 = (Settings.HarvestCropMode == "All") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(40, 48, 60)
			mAllBtn.Text = "Mode: ALL"
			mAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			mAllBtn.Font = Enum.Font.GothamBold
			mAllBtn.TextSize = 8
			mAllBtn.ZIndex = 17
			mAllBtn.Parent = modeRow

			local maCorner = Instance.new("UICorner")
			maCorner.CornerRadius = UDim.new(0, 4)
			maCorner.Parent = mAllBtn

			local cSelBtn = Instance.new("TextButton")
			cSelBtn.Size = UDim2.new(0.32, 0, 1, -2)
			cSelBtn.Position = UDim2.new(0.34, 0, 0, 1)
			cSelBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			cSelBtn.Text = "✓ Select All"
			cSelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			cSelBtn.Font = Enum.Font.GothamBold
			cSelBtn.TextSize = 8
			cSelBtn.ZIndex = 17
			cSelBtn.Parent = modeRow

			local csCorner = Instance.new("UICorner")
			csCorner.CornerRadius = UDim.new(0, 4)
			csCorner.Parent = cSelBtn

			local cClrBtn = Instance.new("TextButton")
			cClrBtn.Size = UDim2.new(0.32, 0, 1, -2)
			cClrBtn.Position = UDim2.new(0.66, 0, 0, 1)
			cClrBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
			cClrBtn.Text = "✗ Clear All"
			cClrBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			cClrBtn.Font = Enum.Font.GothamBold
			cClrBtn.TextSize = 8
			cClrBtn.ZIndex = 17
			cClrBtn.Parent = modeRow

			local ccCorner = Instance.new("UICorner")
			ccCorner.CornerRadius = UDim.new(0, 4)
			ccCorner.Parent = cClrBtn

			mAllBtn.MouseButton1Click:Connect(function()
				Settings.HarvestCropMode = "All"
				cropDropdown.Text = "  🎯 Crop Filter: ALL Crops ▼"
				cropDropdown.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
				renderHarvestCropDropdown()
			end)

			cSelBtn.MouseButton1Click:Connect(function()
				for _, cName in ipairs(fetchActiveGardenCropNames()) do Settings.SelectedHarvestCrops[cName] = true end
				Settings.HarvestCropMode = "Selected"
				cropDropdown.Text = "  🎯 Crop Filter: Selected Crops ▼"
				cropDropdown.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
				renderHarvestCropDropdown()
			end)

			cClrBtn.MouseButton1Click:Connect(function()
				table.clear(Settings.SelectedHarvestCrops)
				Settings.HarvestCropMode = "Selected"
				cropDropdown.Text = "  🎯 Crop Filter: Selected Crops ▼"
				cropDropdown.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
				renderHarvestCropDropdown()
			end)

			local activeCrops = fetchActiveGardenCropNames()
			for _, cropName in ipairs(activeCrops) do
				local isSel = (Settings.SelectedHarvestCrops[cropName] == true)
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 22)
				btn.BackgroundColor3 = isSel and Color3.fromRGB(30, 60, 45) or Color3.fromRGB(28, 34, 44)
				btn.Text = "  " .. (isSel and "☑ " or "☐ ") .. cropName
				btn.TextColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 200, 215)
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 9
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.ZIndex = 16
				btn.Parent = cropDropFrame

				btn.MouseButton1Click:Connect(function()
					Settings.SelectedHarvestCrops[cropName] = not isSel
					Settings.HarvestCropMode = "Selected"
					cropDropdown.Text = "  🎯 Crop Filter: Selected Crops ▼"
					cropDropdown.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
					renderHarvestCropDropdown()
				end)
			end

			cropDropFrame.CanvasSize = UDim2.new(0, 0, 0, 28 + (#activeCrops * 23))
		end

		cropDropdown.MouseButton1Click:Connect(function()
			cropDropFrame.Visible = not cropDropFrame.Visible
			if cropDropFrame.Visible then
				local mFrame = gRightPanel:FindFirstChild("MutDropFrame")
				if mFrame then mFrame.Visible = false end
			end
		end)

		local cdPadding = Instance.new("UIPadding")
		cdPadding.PaddingLeft = UDim.new(0, 10)
		cdPadding.PaddingRight = UDim.new(0, 10)
		cdPadding.Parent = cropDropdown

		renderHarvestCropDropdown()

		-- === MUTATION FILTER ===
		local mutHeader = Instance.new("TextLabel")
		mutHeader.Size = UDim2.new(1, -20, 0, 16)
		mutHeader.Position = UDim2.new(0, 10, 0, 112)
		mutHeader.BackgroundTransparency = 1
		mutHeader.Text = "🧬 Mutation Filter (drop to toggle):"
		mutHeader.TextColor3 = Color3.fromRGB(231, 76, 60)
		mutHeader.Font = Enum.Font.GothamBold
		mutHeader.TextSize = 9
		mutHeader.TextXAlignment = Enum.TextXAlignment.Left
		mutHeader.Parent = gRightPanel

		local mutDropdown = Instance.new("TextButton")
		mutDropdown.Size = UDim2.new(1, -20, 0, 24)
		mutDropdown.Position = UDim2.new(0, 10, 0, 130)
		mutDropdown.BackgroundColor3 = Color3.fromRGB(34, 42, 54)
		mutDropdown.Text = "🧬 Mutation: " .. Settings.HarvestMutationFilter .. " ▼"
		mutDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
		mutDropdown.Font = Enum.Font.GothamBold
		mutDropdown.TextSize = 10
		mutDropdown.TextXAlignment = Enum.TextXAlignment.Left
		mutDropdown.Parent = gRightPanel

		local mdCorner = Instance.new("UICorner")
		mdCorner.CornerRadius = UDim.new(0, 6)
		mdCorner.Parent = mutDropdown

		local mdPadding = Instance.new("UIPadding")
		mdPadding.PaddingLeft = UDim.new(0, 10)
		mdPadding.PaddingRight = UDim.new(0, 10)
		mdPadding.Parent = mutDropdown

		local mutDropFrame = Instance.new("ScrollingFrame")
		mutDropFrame.Name = "MutDropFrame"
		mutDropFrame.Size = UDim2.new(1, -20, 0, 140)
		mutDropFrame.Position = UDim2.new(0, 10, 0, 156)
		mutDropFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
		mutDropFrame.BorderSizePixel = 1
		mutDropFrame.BorderColor3 = Color3.fromRGB(231, 76, 60)
		mutDropFrame.Visible = false
		mutDropFrame.ZIndex = 20
		mutDropFrame.ScrollBarThickness = 4
		mutDropFrame.Parent = gRightPanel

		local mutDropCorner = Instance.new("UICorner")
		mutDropCorner.CornerRadius = UDim.new(0, 6)
		mutDropCorner.Parent = mutDropFrame

		local mutList = Instance.new("UIListLayout")
		mutList.SortOrder = Enum.SortOrder.LayoutOrder
		mutList.Padding = UDim.new(0, 1)
		mutList.Parent = mutDropFrame

		local _, _, activeMutSummary = scanFarmMutations()
		local activeMutNames = {}
		for mutName, data in pairs(activeMutSummary) do
			if data.Count > 0 and mutName ~= "Normal" then
				table.insert(activeMutNames, mutName)
			end
		end
		table.sort(activeMutNames)

		local allMutations = {"All", "Normal"}
		for _, mName in ipairs(activeMutNames) do
			table.insert(allMutations, mName)
		end

		for _, mName in ipairs(allMutations) do
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 22)
			item.BackgroundColor3 = (Settings.HarvestMutationFilter == mName) and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(28, 34, 44)
			item.Text = "  " .. mName
			item.TextColor3 = Color3.fromRGB(255, 255, 255)
			item.Font = Enum.Font.GothamMedium
			item.TextSize = 9
			item.TextXAlignment = Enum.TextXAlignment.Left
			item.ZIndex = 21
			item.Parent = mutDropFrame
			item.MouseButton1Click:Connect(function()
				Settings.HarvestMutationFilter = mName
				mutDropdown.Text = "  🧬 Mutation: " .. mName .. " ▼"
				mutDropFrame.Visible = false
			end)
		end
		mutDropFrame.CanvasSize = UDim2.new(0, 0, 0, #allMutations * 23)

		mutDropdown.MouseButton1Click:Connect(function()
			mutDropFrame.Visible = not mutDropFrame.Visible
			if mutDropFrame.Visible then cropDropFrame.Visible = false end
		end)

		-- === WEIGHT FILTER ===
		local wtHeader = Instance.new("TextLabel")
		wtHeader.Size = UDim2.new(1, -20, 0, 16)
		wtHeader.Position = UDim2.new(0, 10, 0, 166)
		wtHeader.BackgroundTransparency = 1
		wtHeader.Text = "⚖️ Weight Filter (kg):"
		wtHeader.TextColor3 = Color3.fromRGB(241, 196, 15)
		wtHeader.Font = Enum.Font.GothamBold
		wtHeader.TextSize = 9
		wtHeader.TextXAlignment = Enum.TextXAlignment.Left
		wtHeader.Parent = gRightPanel

		local wtDropdown = Instance.new("TextButton")
		wtDropdown.Size = UDim2.new(0, 100, 0, 22)
		wtDropdown.Position = UDim2.new(0, 10, 0, 184)
		wtDropdown.BackgroundColor3 = Color3.fromRGB(34, 42, 54)
		wtDropdown.Text = Settings.HarvestWeightFilter
		wtDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
		wtDropdown.Font = Enum.Font.GothamBold
		wtDropdown.TextSize = 9
		wtDropdown.Parent = gRightPanel

		local wdCorner = Instance.new("UICorner")
		wdCorner.CornerRadius = UDim.new(0, 6)
		wdCorner.Parent = wtDropdown

		local wdPadding = Instance.new("UIPadding")
		wdPadding.PaddingLeft = UDim.new(0, 8)
		wdPadding.PaddingRight = UDim.new(0, 8)
		wdPadding.Parent = wtDropdown

		local wtDropFrame = Instance.new("Frame")
		wtDropFrame.Size = UDim2.new(0, 100, 0, 66)
		wtDropFrame.Position = UDim2.new(0, 10, 0, 208)
		wtDropFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
		wtDropFrame.BorderSizePixel = 1
		wtDropFrame.BorderColor3 = Color3.fromRGB(241, 196, 15)
		wtDropFrame.Visible = false
		wtDropFrame.ZIndex = 25
		wtDropFrame.Parent = gRightPanel

		local wdlCorner = Instance.new("UICorner")
		wdlCorner.CornerRadius = UDim.new(0, 6)
		wdlCorner.Parent = wtDropFrame

		local wtList = Instance.new("UIListLayout")
		wtList.SortOrder = Enum.SortOrder.LayoutOrder
		wtList.Padding = UDim.new(0, 1)
		wtList.Parent = wtDropFrame

		for _, wMode in ipairs({"Disabled", "Below", "Above"}) do
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 20)
			item.BackgroundColor3 = (Settings.HarvestWeightFilter == wMode) and Color3.fromRGB(241, 196, 15) or Color3.fromRGB(28, 34, 44)
			item.Text = "  " .. wMode
			item.TextColor3 = Color3.fromRGB(255, 255, 255)
			item.Font = Enum.Font.GothamMedium
			item.TextSize = 9
			item.ZIndex = 26
			item.Parent = wtDropFrame
			item.MouseButton1Click:Connect(function()
				Settings.HarvestWeightFilter = wMode
				wtDropdown.Text = "  " .. wMode
				wtDropFrame.Visible = false
			end)
		end

		wtDropdown.MouseButton1Click:Connect(function()
			wtDropFrame.Visible = not wtDropFrame.Visible
			if wtDropFrame.Visible then cropDropFrame.Visible = false; mutDropFrame.Visible = false end
		end)

		local wtBox = Instance.new("TextBox")
		wtBox.Size = UDim2.new(0, 70, 0, 22)
		wtBox.Position = UDim2.new(0, 120, 0, 184)
		wtBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		wtBox.Text = tostring(Settings.HarvestWeightThreshold)
		wtBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		wtBox.Font = Enum.Font.Gotham
		wtBox.TextSize = 9
		wtBox.Parent = gRightPanel

		local wtBoxCorner = Instance.new("UICorner")
		wtBoxCorner.CornerRadius = UDim.new(0, 4)
		wtBoxCorner.Parent = wtBox

		local wtLbl = Instance.new("TextLabel")
		wtLbl.Size = UDim2.new(0, 30, 0, 22)
		wtLbl.Position = UDim2.new(0, 196, 0, 184)
		wtLbl.BackgroundTransparency = 1
		wtLbl.Text = "kg"
		wtLbl.TextColor3 = Color3.fromRGB(180, 190, 205)
		wtLbl.Font = Enum.Font.Gotham
		wtLbl.TextSize = 9
		wtLbl.TextXAlignment = Enum.TextXAlignment.Left
		wtLbl.Parent = gRightPanel

		wtBox:GetPropertyChangedSignal("Text"):Connect(function()
			local n = tonumber(wtBox.Text)
			if n then Settings.HarvestWeightThreshold = math.max(0, n) end
		end)

		wtBox.FocusLost:Connect(function()
			local n = tonumber(wtBox.Text)
			if n then Settings.HarvestWeightThreshold = math.max(0, n) else wtBox.Text = tostring(Settings.HarvestWeightThreshold) end
		end)

	elseif selectedGardenSubTab == "Shovel" then
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, -16, 0, 26)
		header.Position = UDim2.new(0, 10, 0, 6)
		header.BackgroundTransparency = 1
		header.Text = "🧹 Auto Shovel Controls & Crop Filters"
		header.TextColor3 = Color3.fromRGB(231, 76, 60)
		header.Font = Enum.Font.GothamBold
		header.TextSize = 12
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = gRightPanel

		local shovelToggleBtn = Instance.new("TextButton")
		shovelToggleBtn.Size = UDim2.new(1, -20, 0, 34)
		shovelToggleBtn.Position = UDim2.new(0, 10, 0, 34)
		shovelToggleBtn.BackgroundColor3 = Settings.AutoShovel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		shovelToggleBtn.Text = Settings.AutoShovel and "🧹 Auto Shovel: ON" or "🧹 Auto Shovel: OFF"
		shovelToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		shovelToggleBtn.Font = Enum.Font.GothamBold
		shovelToggleBtn.TextSize = 11
		shovelToggleBtn.Parent = gRightPanel

		local sCorner = Instance.new("UICorner")
		sCorner.CornerRadius = UDim.new(0, 8)
		sCorner.Parent = shovelToggleBtn

		shovelToggleBtn.MouseButton1Click:Connect(function()
			Settings.AutoShovel = not Settings.AutoShovel
			if Settings.AutoShovel then
				shovelToggleBtn.Text = "🧹 Auto Shovel: ON"
				shovelToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			else
				shovelToggleBtn.Text = "🧹 Auto Shovel: OFF"
				shovelToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
			end
		end)

		local shovelModeBtn = Instance.new("TextButton")
		shovelModeBtn.Size = UDim2.new(1, -20, 0, 26)
		shovelModeBtn.Position = UDim2.new(0, 10, 0, 72)
		shovelModeBtn.BackgroundColor3 = (Settings.AutoShovelMode == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)
		shovelModeBtn.Text = (Settings.AutoShovelMode == "All") and "🎯 Mode: Shovel ALL Crops" or "🎯 Mode: Selected Crops Only"
		shovelModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		shovelModeBtn.Font = Enum.Font.GothamBold
		shovelModeBtn.TextSize = 10
		shovelModeBtn.Parent = gRightPanel

		local smCorner = Instance.new("UICorner")
		smCorner.CornerRadius = UDim.new(0, 6)
		smCorner.Parent = shovelModeBtn

		shovelModeBtn.MouseButton1Click:Connect(function()
			if Settings.AutoShovelMode == "All" then
				Settings.AutoShovelMode = "Selected"
				shovelModeBtn.Text = "🎯 Mode: Selected Crops Only"
				shovelModeBtn.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			else
				Settings.AutoShovelMode = "All"
				shovelModeBtn.Text = "🎯 Mode: Shovel ALL Crops"
				shovelModeBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
			end
		end)

		local listTitle = Instance.new("TextLabel")
		listTitle.Size = UDim2.new(1, -20, 0, 18)
		listTitle.Position = UDim2.new(0, 10, 0, 102)
		listTitle.BackgroundTransparency = 1
		listTitle.Text = "⚙️ Select Crops to Auto Shovel:"
		listTitle.TextColor3 = Color3.fromRGB(200, 210, 225)
		listTitle.Font = Enum.Font.GothamMedium
		listTitle.TextSize = 9
		listTitle.TextXAlignment = Enum.TextXAlignment.Left
		listTitle.Parent = gRightPanel

		local selAllBtn = Instance.new("TextButton")
		selAllBtn.Size = UDim2.new(0, 75, 0, 18)
		selAllBtn.Position = UDim2.new(1, -165, 0, 102)
		selAllBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		selAllBtn.Text = "✓ All"
		selAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selAllBtn.Font = Enum.Font.GothamBold
		selAllBtn.TextSize = 9
		selAllBtn.Parent = gRightPanel

		local clrAllBtn = Instance.new("TextButton")
		clrAllBtn.Size = UDim2.new(0, 75, 0, 18)
		clrAllBtn.Position = UDim2.new(1, -85, 0, 102)
		clrAllBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		clrAllBtn.Text = "✗ Clear"
		clrAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		clrAllBtn.Font = Enum.Font.GothamBold
		clrAllBtn.TextSize = 9
		clrAllBtn.Parent = gRightPanel

		local scroller = Instance.new("ScrollingFrame")
		scroller.Size = UDim2.new(1, -20, 1, -162)
		scroller.Position = UDim2.new(0, 10, 0, 124)
		scroller.BackgroundTransparency = 1
		scroller.ScrollBarThickness = 4
		scroller.Parent = gRightPanel

		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.48, 0, 0, 26)
		grid.CellPadding = UDim2.new(0.03, 0, 0, 4)
		grid.Parent = scroller

		local function renderShovelGrid()
			for _, child in ipairs(scroller:GetChildren()) do
				if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
			end

			local activeCrops = fetchActiveGardenCropNames()
			for _, cropName in ipairs(activeCrops) do
				local isSel = (Settings.SelectedShovelCrops[cropName] == true)

				local itemBtn = Instance.new("TextButton")
				itemBtn.BackgroundColor3 = isSel and Color3.fromRGB(30, 60, 45) or Color3.fromRGB(32, 38, 48)
				itemBtn.Text = (isSel and "☑ " or "☐ ") .. getCropDisplayName(cropName)
				itemBtn.TextColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 200, 215)
				itemBtn.Font = Enum.Font.GothamMedium
				itemBtn.TextSize = 10
				itemBtn.TextXAlignment = Enum.TextXAlignment.Left
				itemBtn.Parent = scroller

				local iCorner = Instance.new("UICorner")
				iCorner.CornerRadius = UDim.new(0, 4)
				iCorner.Parent = itemBtn

				itemBtn.MouseButton1Click:Connect(function()
					Settings.SelectedShovelCrops[cropName] = not isSel
					renderShovelGrid()
				end)
			end

			scroller.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
		end

		selAllBtn.MouseButton1Click:Connect(function()
			for _, cName in ipairs(fetchActiveGardenCropNames()) do Settings.SelectedShovelCrops[cName] = true end
			renderShovelGrid()
		end)

		clrAllBtn.MouseButton1Click:Connect(function()
			table.clear(Settings.SelectedShovelCrops)
			renderShovelGrid()
		end)

		renderShovelGrid()

	elseif selectedGardenSubTab == "Sprinkler" then
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, -16, 0, 24)
		header.Position = UDim2.new(0, 10, 0, 4)
		header.BackgroundTransparency = 1
		header.Text = "💧 Auto Place Sprinkler Settings & Filters"
		header.TextColor3 = Color3.fromRGB(52, 152, 219)
		header.Font = Enum.Font.GothamBold
		header.TextSize = 12
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = gRightPanel

		local sprinklerToggleBtn = Instance.new("TextButton")
		sprinklerToggleBtn.Size = UDim2.new(1, -20, 0, 30)
		sprinklerToggleBtn.Position = UDim2.new(0, 10, 0, 28)
		sprinklerToggleBtn.BackgroundColor3 = Settings.AutoPlaceSprinkler and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		sprinklerToggleBtn.Text = Settings.AutoPlaceSprinkler and "💧 Auto Place Sprinkler: ON" or "💧 Auto Place Sprinkler: OFF"
		sprinklerToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		sprinklerToggleBtn.Font = Enum.Font.GothamBold
		sprinklerToggleBtn.TextSize = 11
		sprinklerToggleBtn.Parent = gRightPanel

		sprinklerToggleBtn.MouseButton1Click:Connect(function()
			Settings.AutoPlaceSprinkler = not Settings.AutoPlaceSprinkler
			if Settings.AutoPlaceSprinkler then
				sprinklerToggleBtn.Text = "💧 Auto Place Sprinkler: ON"
				sprinklerToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				task.spawn(executeAutoPlaceSprinkler)
			else
				sprinklerToggleBtn.Text = "💧 Auto Place Sprinkler: OFF"
				sprinklerToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
			end
		end)

local posLbl = Instance.new("TextLabel")
		posLbl.Size = UDim2.new(1, -20, 0, 16)
		posLbl.Position = UDim2.new(0, 10, 0, 62)
		posLbl.BackgroundTransparency = 1
		posLbl.Text = "📌 Location Target Mode:"
		posLbl.TextColor3 = Color3.fromRGB(52, 152, 219)
		posLbl.Font = Enum.Font.GothamBold
		posLbl.TextSize = 9
		posLbl.TextXAlignment = Enum.TextXAlignment.Left
		posLbl.Parent = gRightPanel

		local mPlant = Instance.new("TextButton")
		mPlant.Size = UDim2.new(0.31, 0, 0, 22)
		mPlant.Position = UDim2.new(0, 10, 0, 80)
		mPlant.Parent = gRightPanel

		local mPlayer = Instance.new("TextButton")
		mPlayer.Size = UDim2.new(0.31, 0, 0, 22)
		mPlayer.Position = UDim2.new(0.34, 0, 0, 80)
		mPlayer.Parent = gRightPanel

		local mCustom = Instance.new("TextButton")
		mCustom.Size = UDim2.new(0.31, 0, 0, 22)
		mCustom.Position = UDim2.new(0.68, 0, 0, 80)
		mCustom.Parent = gRightPanel

		local function updateModes()
			local cur = Settings.SprinklerTargetMode or "Plant"
			mPlant.Text = (cur == "Plant" and "☑ 🌱 Plants" or "☐ 🌱 Plants")
			mPlant.BackgroundColor3 = (cur == "Plant") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 42, 54)
			mPlant.TextColor3 = (cur == "Plant") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 205)

			mPlayer.Text = (cur == "Player" and "☑ 👤 Player" or "☐ 👤 Player")
			mPlayer.BackgroundColor3 = (cur == "Player") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 42, 54)
			mPlayer.TextColor3 = (cur == "Player") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 205)

			mCustom.Text = (cur == "Custom" and "☑ 📍 Custom" or "☐ 📍 Custom")
			mCustom.BackgroundColor3 = (cur == "Custom") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 42, 54)
			mCustom.TextColor3 = (cur == "Custom") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 205)
		end
		mPlant.MouseButton1Click:Connect(function() Settings.SprinklerTargetMode = "Plant"; updateModes() end)
		mPlayer.MouseButton1Click:Connect(function() Settings.SprinklerTargetMode = "Player"; updateModes() end)
		mCustom.MouseButton1Click:Connect(function() Settings.SprinklerTargetMode = "Custom"; updateModes() end)
		updateModes()

		local xBox = Instance.new("TextBox")
		xBox.Size = UDim2.new(0, 55, 0, 20)
		xBox.Position = UDim2.new(0, 10, 0, 106)
		xBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		xBox.Text = tostring(math.floor(Settings.SprinklerCustomPos.X or 0))
		xBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		xBox.Font = Enum.Font.Gotham
		xBox.TextSize = 9
		xBox.Parent = gRightPanel

		local yBox = Instance.new("TextBox")
		yBox.Size = UDim2.new(0, 55, 0, 20)
		yBox.Position = UDim2.new(0, 70, 0, 106)
		yBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		yBox.Text = tostring(math.floor(Settings.SprinklerCustomPos.Y or 0))
		yBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		yBox.Font = Enum.Font.Gotham
		yBox.TextSize = 9
		yBox.Parent = gRightPanel

		local zBox = Instance.new("TextBox")
		zBox.Size = UDim2.new(0, 55, 0, 20)
		zBox.Position = UDim2.new(0, 130, 0, 106)
		zBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		zBox.Text = tostring(math.floor(Settings.SprinklerCustomPos.Z or 0))
		zBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		zBox.Font = Enum.Font.Gotham
		zBox.TextSize = 9
		zBox.Parent = gRightPanel

		local grabBtn = Instance.new("TextButton")
		grabBtn.Size = UDim2.new(0, 95, 0, 20)
		grabBtn.Position = UDim2.new(0, 190, 0, 106)
		grabBtn.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
		grabBtn.Text = "📍 Grab Pos"
		grabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		grabBtn.Font = Enum.Font.GothamBold
		grabBtn.TextSize = 9
		grabBtn.Parent = gRightPanel

		local function saveSpPos()
			Settings.SprinklerCustomPos.X = tonumber(xBox.Text) or 0
			Settings.SprinklerCustomPos.Y = tonumber(yBox.Text) or 0
			Settings.SprinklerCustomPos.Z = tonumber(zBox.Text) or 0
		end
		xBox.FocusLost:Connect(saveSpPos)
		yBox.FocusLost:Connect(saveSpPos)
		zBox.FocusLost:Connect(saveSpPos)

		grabBtn.MouseButton1Click:Connect(function()
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local p = char.HumanoidRootPart.Position
				Settings.SprinklerCustomPos.X = p.X
				Settings.SprinklerCustomPos.Y = p.Y
				Settings.SprinklerCustomPos.Z = p.Z
				xBox.Text = string.format("%.1f", p.X)
				yBox.Text = string.format("%.1f", p.Y)
				zBox.Text = string.format("%.1f", p.Z)
			end
		end)

		local delayBox = Instance.new("TextBox")
		delayBox.Size = UDim2.new(0, 50, 0, 20)
		delayBox.Position = UDim2.new(0, 10, 0, 130)
		delayBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		delayBox.Text = tostring(Settings.SprinklerDelay or 1.0)
		delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		delayBox.Font = Enum.Font.Gotham
		delayBox.TextSize = 9
		delayBox.Parent = gRightPanel

		local delayLbl = Instance.new("TextLabel")
		delayLbl.Size = UDim2.new(0, 60, 0, 20)
		delayLbl.Position = UDim2.new(0, 65, 0, 130)
		delayLbl.BackgroundTransparency = 1
		delayLbl.Text = "sec delay"
		delayLbl.TextColor3 = Color3.fromRGB(180, 190, 205)
		delayLbl.Font = Enum.Font.Gotham
		delayLbl.TextSize = 9
		delayLbl.TextXAlignment = Enum.TextXAlignment.Left
		delayLbl.Parent = gRightPanel

		delayBox.FocusLost:Connect(function()
			local n = tonumber(delayBox.Text)
			if n then Settings.SprinklerDelay = math.max(0.1, n) else delayBox.Text = tostring(Settings.SprinklerDelay) end
		end)

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0, 135, 0, 20)
		equipBtn.Position = UDim2.new(0, 150, 0, 130)
		equipBtn.BackgroundColor3 = Settings.SprinklerAutoEquip and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		equipBtn.Text = Settings.SprinklerAutoEquip and "⚔️ Auto Equip: ON" or "⚔️ Auto Equip: OFF"
		equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 9
		equipBtn.Parent = gRightPanel

		equipBtn.MouseButton1Click:Connect(function()
			Settings.SprinklerAutoEquip = not Settings.SprinklerAutoEquip
			equipBtn.Text = Settings.SprinklerAutoEquip and "⚔️ Auto Equip: ON" or "⚔️ Auto Equip: OFF"
			equipBtn.BackgroundColor3 = Settings.SprinklerAutoEquip and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		end)

		local subScroller = Instance.new("ScrollingFrame")
		subScroller.Size = UDim2.new(1, -20, 1, -190)
		subScroller.Position = UDim2.new(0, 10, 0, 156)
		subScroller.BackgroundTransparency = 1
		subScroller.ScrollBarThickness = 4
		subScroller.BorderSizePixel = 0
		subScroller.Parent = gRightPanel

		-- 1. TOOL FILTER SECTION FOR SPRINKLERS
		local toolHeader = Instance.new("TextButton")
		toolHeader.Size = UDim2.new(1, -10, 0, 22)
		toolHeader.Position = UDim2.new(0, 0, 0, 0)
		toolHeader.BackgroundColor3 = (Settings.SprinklerToolMode == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)
		toolHeader.Text = (Settings.SprinklerToolMode == "All") and "🛠️ Sprinkler Tool Filter: ALL Tools" or "🛠️ Sprinkler Tool Filter: Selected Tools Only"
		toolHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		toolHeader.Font = Enum.Font.GothamBold
		toolHeader.TextSize = 9
		toolHeader.Parent = subScroller

		toolHeader.MouseButton1Click:Connect(function()
			if Settings.SprinklerToolMode == "All" then
				Settings.SprinklerToolMode = "Selected"
				toolHeader.Text = "🛠️ Sprinkler Tool Filter: Selected Tools Only"
				toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			else
				Settings.SprinklerToolMode = "All"
				toolHeader.Text = "🛠️ Sprinkler Tool Filter: ALL Tools"
				toolHeader.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
			end
		end)

		local tSelAll = Instance.new("TextButton")
		tSelAll.Size = UDim2.new(0, 75, 0, 18)
		tSelAll.Position = UDim2.new(1, -160, 0, 26)
		tSelAll.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		tSelAll.Text = "✓ All Tools"
		tSelAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		tSelAll.Font = Enum.Font.GothamBold
		tSelAll.TextSize = 8
		tSelAll.Parent = subScroller

		local tClrAll = Instance.new("TextButton")
		tClrAll.Size = UDim2.new(0, 75, 0, 18)
		tClrAll.Position = UDim2.new(1, -80, 0, 26)
		tClrAll.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		tClrAll.Text = "✗ Clear Tools"
		tClrAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		tClrAll.Font = Enum.Font.GothamBold
		tClrAll.TextSize = 8
		tClrAll.Parent = subScroller

		local toolGridFrame = Instance.new("Frame")
		toolGridFrame.Size = UDim2.new(1, -10, 0, 70)
		toolGridFrame.Position = UDim2.new(0, 0, 0, 46)
		toolGridFrame.BackgroundTransparency = 1
		toolGridFrame.Parent = subScroller

		local tGrid = Instance.new("UIGridLayout")
		tGrid.CellSize = UDim2.new(0.48, 0, 0, 26)
		tGrid.CellPadding = UDim2.new(0.03, 0, 0, 4)
		tGrid.Parent = toolGridFrame

		local function renderSprinklerToolGrid()
			for _, child in ipairs(toolGridFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			-- Dynamic list combining catalog + backpack tools
			local availableTools = {}
			for _, name in ipairs(SprinklerCatalogNames) do table.insert(availableTools, name) end
			local backpack = player:FindFirstChild("Backpack")
			local char = player.Character
			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and string.find(item.Name, "Sprinkler") and not table.find(availableTools, item.Name) then
						table.insert(availableTools, item.Name)
					end
				end
			end
			if char then
				for _, item in ipairs(char:GetChildren()) do
					if item:IsA("Tool") and string.find(item.Name, "Sprinkler") and not table.find(availableTools, item.Name) then
						table.insert(availableTools, item.Name)
					end
				end
			end

			for _, tName in ipairs(availableTools) do
				local isSel = (Settings.SelectedSprinklerTools[tName] == true)
				local btn = Instance.new("TextButton")
				btn.BackgroundColor3 = isSel and Color3.fromRGB(30, 60, 45) or Color3.fromRGB(32, 38, 48)
				btn.Text = (isSel and "☑ " or "☐ ") .. tName
				btn.TextColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 200, 215)
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 10
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = toolGridFrame

				local bCorner = Instance.new("UICorner")
				bCorner.CornerRadius = UDim.new(0, 4)
				bCorner.Parent = btn

				btn.MouseButton1Click:Connect(function()
					Settings.SelectedSprinklerTools[tName] = not isSel
					Settings.SprinklerToolMode = "Selected"
					toolHeader.Text = "🛠️ Sprinkler Tool Filter: Selected Tools Only"
					toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
					renderSprinklerToolGrid()
				end)
			end
			local rows = math.ceil(#availableTools / 2)
			toolGridFrame.Size = UDim2.new(1, -10, 0, rows * 30)
		end

		tSelAll.MouseButton1Click:Connect(function()
			for _, tName in ipairs(SprinklerCatalogNames) do Settings.SelectedSprinklerTools[tName] = true end
			Settings.SprinklerToolMode = "Selected"
			toolHeader.Text = "🛠️ Sprinkler Tool Filter: Selected Tools Only"
			toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderSprinklerToolGrid()
		end)
		tClrAll.MouseButton1Click:Connect(function()
			table.clear(Settings.SelectedSprinklerTools)
			Settings.SprinklerToolMode = "Selected"
			toolHeader.Text = "🛠️ Sprinkler Tool Filter: Selected Tools Only"
			toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderSprinklerToolGrid()
		end)
		renderSprinklerToolGrid()

		-- 2. CROP FILTER SECTION FOR SPRINKLERS
		local cropHeader = Instance.new("TextButton")
		cropHeader.Size = UDim2.new(1, -10, 0, 22)
		cropHeader.Position = UDim2.new(0, 0, 0, 130)
		cropHeader.BackgroundColor3 = (Settings.SprinklerCropMode == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)
		cropHeader.Text = (Settings.SprinklerCropMode == "All") and "🎯 Crop Filter: ALL Plants" or "🎯 Crop Filter: Selected Plants Only"
		cropHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		cropHeader.Font = Enum.Font.GothamBold
		cropHeader.TextSize = 9
		cropHeader.Parent = subScroller

		cropHeader.MouseButton1Click:Connect(function()
			if Settings.SprinklerCropMode == "All" then
				Settings.SprinklerCropMode = "Selected"
				cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
				cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			else
				Settings.SprinklerCropMode = "All"
				cropHeader.Text = "🎯 Crop Filter: ALL Plants"
				cropHeader.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
			end
		end)

		local cSelAll = Instance.new("TextButton")
		cSelAll.Size = UDim2.new(0, 75, 0, 18)
		cSelAll.Position = UDim2.new(1, -160, 0, 156)
		cSelAll.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		cSelAll.Text = "✓ All Crops"
		cSelAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		cSelAll.Font = Enum.Font.GothamBold
		cSelAll.TextSize = 8
		cSelAll.Parent = subScroller

		local cClrAll = Instance.new("TextButton")
		cClrAll.Size = UDim2.new(0, 75, 0, 18)
		cClrAll.Position = UDim2.new(1, -80, 0, 156)
		cClrAll.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		cClrAll.Text = "✗ Clear Crops"
		cClrAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		cClrAll.Font = Enum.Font.GothamBold
		cClrAll.TextSize = 8
		cClrAll.Parent = subScroller

		local cropGridFrame = Instance.new("Frame")
		cropGridFrame.Size = UDim2.new(1, -10, 0, 200)
		cropGridFrame.Position = UDim2.new(0, 0, 0, 176)
		cropGridFrame.BackgroundTransparency = 1
		cropGridFrame.Parent = subScroller

		local cGrid = Instance.new("UIGridLayout")
		cGrid.CellSize = UDim2.new(0.48, 0, 0, 26)
		cGrid.CellPadding = UDim2.new(0.03, 0, 0, 4)
		cGrid.Parent = cropGridFrame

		local function renderSprinklerCropGrid()
			for _, child in ipairs(cropGridFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			local activeCrops = fetchActiveGardenCropNames()
			for _, cropName in ipairs(activeCrops) do
				local isSel = (Settings.SelectedSprinklerCrops[cropName] == true)
				local btn = Instance.new("TextButton")
				btn.BackgroundColor3 = isSel and Color3.fromRGB(30, 60, 45) or Color3.fromRGB(32, 38, 48)
				btn.Text = (isSel and "☑ " or "☐ ") .. getCropDisplayName(cropName)
				btn.TextColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 200, 215)
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 10
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = cropGridFrame

				local bCorner = Instance.new("UICorner")
				bCorner.CornerRadius = UDim.new(0, 4)
				bCorner.Parent = btn

				btn.MouseButton1Click:Connect(function()
					Settings.SelectedSprinklerCrops[cropName] = not isSel
					Settings.SprinklerCropMode = "Selected"
					cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
					cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
					renderSprinklerCropGrid()
				end)
			end
			local rows = math.ceil(#activeCrops / 2)
			cropGridFrame.Size = UDim2.new(1, -10, 0, rows * 30)
			subScroller.CanvasSize = UDim2.new(0, 0, 0, 180 + (rows * 30))
		end

		cSelAll.MouseButton1Click:Connect(function()
			for _, cName in ipairs(fetchActiveGardenCropNames()) do Settings.SelectedSprinklerCrops[cName] = true end
			Settings.SprinklerCropMode = "Selected"
			cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
			cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderSprinklerCropGrid()
		end)
		cClrAll.MouseButton1Click:Connect(function()
			table.clear(Settings.SelectedSprinklerCrops)
			Settings.SprinklerCropMode = "Selected"
			cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
			cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderSprinklerCropGrid()
		end)
		renderSprinklerCropGrid()

	elseif selectedGardenSubTab == "Watering" then
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, -16, 0, 24)
		header.Position = UDim2.new(0, 10, 0, 4)
		header.BackgroundTransparency = 1
		header.Text = "🚿 Auto Water Plants Settings & Filters"
		header.TextColor3 = Color3.fromRGB(41, 128, 185)
		header.Font = Enum.Font.GothamBold
		header.TextSize = 12
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = gRightPanel

		local wateringToggleBtn = Instance.new("TextButton")
		wateringToggleBtn.Size = UDim2.new(1, -20, 0, 30)
		wateringToggleBtn.Position = UDim2.new(0, 10, 0, 28)
		wateringToggleBtn.BackgroundColor3 = Settings.AutoWatering and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		wateringToggleBtn.Text = Settings.AutoWatering and "🚿 Auto Water Plants: ON" or "🚿 Auto Water Plants: OFF"
		wateringToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		wateringToggleBtn.Font = Enum.Font.GothamBold
		wateringToggleBtn.TextSize = 11
		wateringToggleBtn.Parent = gRightPanel

		wateringToggleBtn.MouseButton1Click:Connect(function()
			Settings.AutoWatering = not Settings.AutoWatering
			if Settings.AutoWatering then
				wateringToggleBtn.Text = "🚿 Auto Water Plants: ON"
				wateringToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				task.spawn(executeAutoWatering)
			else
				wateringToggleBtn.Text = "🚿 Auto Water Plants: OFF"
				wateringToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
			end
		end)

		local posLbl = Instance.new("TextLabel")
		posLbl.Size = UDim2.new(1, -20, 0, 16)
		posLbl.Position = UDim2.new(0, 10, 0, 62)
		posLbl.BackgroundTransparency = 1
		posLbl.Text = "📌 Location Target Mode:"
		posLbl.TextColor3 = Color3.fromRGB(41, 128, 185)
		posLbl.Font = Enum.Font.GothamBold
		posLbl.TextSize = 9
		posLbl.TextXAlignment = Enum.TextXAlignment.Left
		posLbl.Parent = gRightPanel

		local mPlant = Instance.new("TextButton")
		mPlant.Size = UDim2.new(0.31, 0, 0, 22)
		mPlant.Position = UDim2.new(0, 10, 0, 80)
		mPlant.Parent = gRightPanel

		local mPlayer = Instance.new("TextButton")
		mPlayer.Size = UDim2.new(0.31, 0, 0, 22)
		mPlayer.Position = UDim2.new(0.34, 0, 0, 80)
		mPlayer.Parent = gRightPanel

		local mCustom = Instance.new("TextButton")
		mCustom.Size = UDim2.new(0.31, 0, 0, 22)
		mCustom.Position = UDim2.new(0.68, 0, 0, 80)
		mCustom.Parent = gRightPanel

		local function updateModes()
			local cur = Settings.WateringTargetMode or "Plant"
			mPlant.Text = (cur == "Plant" and "☑ 🌱 Plants" or "☐ 🌱 Plants")
			mPlant.BackgroundColor3 = (cur == "Plant") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 42, 54)
			mPlant.TextColor3 = (cur == "Plant") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 205)

			mPlayer.Text = (cur == "Player" and "☑ 👤 Player" or "☐ 👤 Player")
			mPlayer.BackgroundColor3 = (cur == "Player") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 42, 54)
			mPlayer.TextColor3 = (cur == "Player") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 205)

			mCustom.Text = (cur == "Custom" and "☑ 📍 Custom" or "☐ 📍 Custom")
			mCustom.BackgroundColor3 = (cur == "Custom") and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 42, 54)
			mCustom.TextColor3 = (cur == "Custom") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 205)
		end
		mPlant.MouseButton1Click:Connect(function() Settings.WateringTargetMode = "Plant"; updateModes() end)
		mPlayer.MouseButton1Click:Connect(function() Settings.WateringTargetMode = "Player"; updateModes() end)
		mCustom.MouseButton1Click:Connect(function() Settings.WateringTargetMode = "Custom"; updateModes() end)
		updateModes()

		local xBox = Instance.new("TextBox")
		xBox.Size = UDim2.new(0, 55, 0, 20)
		xBox.Position = UDim2.new(0, 10, 0, 106)
		xBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		xBox.Text = tostring(math.floor(Settings.WateringCustomPos.X or 0))
		xBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		xBox.Font = Enum.Font.Gotham
		xBox.TextSize = 9
		xBox.Parent = gRightPanel

		local yBox = Instance.new("TextBox")
		yBox.Size = UDim2.new(0, 55, 0, 20)
		yBox.Position = UDim2.new(0, 70, 0, 106)
		yBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		yBox.Text = tostring(math.floor(Settings.WateringCustomPos.Y or 0))
		yBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		yBox.Font = Enum.Font.Gotham
		yBox.TextSize = 9
		yBox.Parent = gRightPanel

		local zBox = Instance.new("TextBox")
		zBox.Size = UDim2.new(0, 55, 0, 20)
		zBox.Position = UDim2.new(0, 130, 0, 106)
		zBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		zBox.Text = tostring(math.floor(Settings.WateringCustomPos.Z or 0))
		zBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		zBox.Font = Enum.Font.Gotham
		zBox.TextSize = 9
		zBox.Parent = gRightPanel

		local grabBtn = Instance.new("TextButton")
		grabBtn.Size = UDim2.new(0, 95, 0, 20)
		grabBtn.Position = UDim2.new(0, 190, 0, 106)
		grabBtn.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
		grabBtn.Text = "📍 Grab Pos"
		grabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		grabBtn.Font = Enum.Font.GothamBold
		grabBtn.TextSize = 9
		grabBtn.Parent = gRightPanel

		local function saveWPos()
			Settings.WateringCustomPos.X = tonumber(xBox.Text) or 0
			Settings.WateringCustomPos.Y = tonumber(yBox.Text) or 0
			Settings.WateringCustomPos.Z = tonumber(zBox.Text) or 0
		end
		xBox.FocusLost:Connect(saveWPos)
		yBox.FocusLost:Connect(saveWPos)
		zBox.FocusLost:Connect(saveWPos)

		grabBtn.MouseButton1Click:Connect(function()
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local p = char.HumanoidRootPart.Position
				Settings.WateringCustomPos.X = p.X
				Settings.WateringCustomPos.Y = p.Y
				Settings.WateringCustomPos.Z = p.Z
				xBox.Text = string.format("%.1f", p.X)
				yBox.Text = string.format("%.1f", p.Y)
				zBox.Text = string.format("%.1f", p.Z)
			end
		end)

		local delayBox = Instance.new("TextBox")
		delayBox.Size = UDim2.new(0, 50, 0, 20)
		delayBox.Position = UDim2.new(0, 10, 0, 130)
		delayBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
		delayBox.Text = tostring(Settings.WateringDelay or 0.5)
		delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		delayBox.Font = Enum.Font.Gotham
		delayBox.TextSize = 9
		delayBox.Parent = gRightPanel

		local delayLbl = Instance.new("TextLabel")
		delayLbl.Size = UDim2.new(0, 60, 0, 20)
		delayLbl.Position = UDim2.new(0, 65, 0, 130)
		delayLbl.BackgroundTransparency = 1
		delayLbl.Text = "sec delay"
		delayLbl.TextColor3 = Color3.fromRGB(180, 190, 205)
		delayLbl.Font = Enum.Font.Gotham
		delayLbl.TextSize = 9
		delayLbl.TextXAlignment = Enum.TextXAlignment.Left
		delayLbl.Parent = gRightPanel

		delayBox.FocusLost:Connect(function()
			local n = tonumber(delayBox.Text)
			if n then Settings.WateringDelay = math.max(0.05, n) else delayBox.Text = tostring(Settings.WateringDelay) end
		end)

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0, 135, 0, 20)
		equipBtn.Position = UDim2.new(0, 150, 0, 130)
		equipBtn.BackgroundColor3 = Settings.WateringAutoEquip and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		equipBtn.Text = Settings.WateringAutoEquip and "⚔️ Auto Equip: ON" or "⚔️ Auto Equip: OFF"
		equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 9
		equipBtn.Parent = gRightPanel

		equipBtn.MouseButton1Click:Connect(function()
			Settings.WateringAutoEquip = not Settings.WateringAutoEquip
			equipBtn.Text = Settings.WateringAutoEquip and "⚔️ Auto Equip: ON" or "⚔️ Auto Equip: OFF"
			equipBtn.BackgroundColor3 = Settings.WateringAutoEquip and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)
		end)

		local subScroller = Instance.new("ScrollingFrame")
		subScroller.Size = UDim2.new(1, -20, 1, -190)
		subScroller.Position = UDim2.new(0, 10, 0, 156)
		subScroller.BackgroundTransparency = 1
		subScroller.ScrollBarThickness = 4
		subScroller.BorderSizePixel = 0
		subScroller.Parent = gRightPanel

		-- 1. TOOL FILTER SECTION FOR WATERING CANS
		local toolHeader = Instance.new("TextButton")
		toolHeader.Size = UDim2.new(1, -10, 0, 22)
		toolHeader.Position = UDim2.new(0, 0, 0, 0)
		toolHeader.BackgroundColor3 = (Settings.WateringToolMode == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)
		toolHeader.Text = (Settings.WateringToolMode == "All") and "🛠️ Watering Can Tool Filter: ALL Cans" or "🛠️ Watering Can Tool Filter: Selected Cans Only"
		toolHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		toolHeader.Font = Enum.Font.GothamBold
		toolHeader.TextSize = 9
		toolHeader.Parent = subScroller

		toolHeader.MouseButton1Click:Connect(function()
			if Settings.WateringToolMode == "All" then
				Settings.WateringToolMode = "Selected"
				toolHeader.Text = "🛠️ Watering Can Tool Filter: Selected Cans Only"
				toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			else
				Settings.WateringToolMode = "All"
				toolHeader.Text = "🛠️ Watering Can Tool Filter: ALL Cans"
				toolHeader.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
			end
		end)

		local tSelAll = Instance.new("TextButton")
		tSelAll.Size = UDim2.new(0, 75, 0, 18)
		tSelAll.Position = UDim2.new(1, -160, 0, 26)
		tSelAll.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		tSelAll.Text = "✓ All Tools"
		tSelAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		tSelAll.Font = Enum.Font.GothamBold
		tSelAll.TextSize = 8
		tSelAll.Parent = subScroller

		local tClrAll = Instance.new("TextButton")
		tClrAll.Size = UDim2.new(0, 75, 0, 18)
		tClrAll.Position = UDim2.new(1, -80, 0, 26)
		tClrAll.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		tClrAll.Text = "✗ Clear Tools"
		tClrAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		tClrAll.Font = Enum.Font.GothamBold
		tClrAll.TextSize = 8
		tClrAll.Parent = subScroller

		local toolGridFrame = Instance.new("Frame")
		toolGridFrame.Size = UDim2.new(1, -10, 0, 70)
		toolGridFrame.Position = UDim2.new(0, 0, 0, 46)
		toolGridFrame.BackgroundTransparency = 1
		toolGridFrame.Parent = subScroller

		local tGrid = Instance.new("UIGridLayout")
		tGrid.CellSize = UDim2.new(0.48, 0, 0, 26)
		tGrid.CellPadding = UDim2.new(0.03, 0, 0, 4)
		tGrid.Parent = toolGridFrame

		local function renderWateringToolGrid()
			for _, child in ipairs(toolGridFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			-- Dynamic list combining catalog + backpack tools
			local availableTools = {}
			for _, name in ipairs(WateringCanCatalogNames) do table.insert(availableTools, name) end
			local backpack = player:FindFirstChild("Backpack")
			local char = player.Character
			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and (string.find(item.Name, "Watering Can") or string.find(item.Name, "WateringCan") or string.find(string.lower(item.Name), "water")) and not table.find(availableTools, item.Name) then
						table.insert(availableTools, item.Name)
					end
				end
			end
			if char then
				for _, item in ipairs(char:GetChildren()) do
					if item:IsA("Tool") and (string.find(item.Name, "Watering Can") or string.find(item.Name, "WateringCan") or string.find(string.lower(item.Name), "water")) and not table.find(availableTools, item.Name) then
						table.insert(availableTools, item.Name)
					end
				end
			end

			for _, tName in ipairs(availableTools) do
				local isSel = (Settings.SelectedWateringTools[tName] == true)
				local btn = Instance.new("TextButton")
				btn.BackgroundColor3 = isSel and Color3.fromRGB(30, 60, 45) or Color3.fromRGB(32, 38, 48)
				btn.Text = (isSel and "☑ " or "☐ ") .. tName
				btn.TextColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 200, 215)
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 10
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = toolGridFrame

				local bCorner = Instance.new("UICorner")
				bCorner.CornerRadius = UDim.new(0, 4)
				bCorner.Parent = btn

				btn.MouseButton1Click:Connect(function()
					Settings.SelectedWateringTools[tName] = not isSel
					Settings.WateringToolMode = "Selected"
					toolHeader.Text = "🛠️ Watering Can Tool Filter: Selected Cans Only"
					toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
					renderWateringToolGrid()
				end)
			end
			local rows = math.ceil(#availableTools / 2)
			toolGridFrame.Size = UDim2.new(1, -10, 0, rows * 30)
		end

		tSelAll.MouseButton1Click:Connect(function()
			for _, tName in ipairs(WateringCanCatalogNames) do Settings.SelectedWateringTools[tName] = true end
			Settings.WateringToolMode = "Selected"
			toolHeader.Text = "🛠️ Watering Can Tool Filter: Selected Cans Only"
			toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderWateringToolGrid()
		end)
		tClrAll.MouseButton1Click:Connect(function()
			table.clear(Settings.SelectedWateringTools)
			Settings.WateringToolMode = "Selected"
			toolHeader.Text = "🛠️ Watering Can Tool Filter: Selected Cans Only"
			toolHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderWateringToolGrid()
		end)
		renderWateringToolGrid()

		-- 2. CROP FILTER SECTION FOR WATERING CANS
		local cropHeader = Instance.new("TextButton")
		cropHeader.Size = UDim2.new(1, -10, 0, 22)
		cropHeader.Position = UDim2.new(0, 0, 0, 130)
		cropHeader.BackgroundColor3 = (Settings.WateringCropMode == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)
		cropHeader.Text = (Settings.WateringCropMode == "All") and "🎯 Crop Filter: ALL Plants" or "🎯 Crop Filter: Selected Plants Only"
		cropHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
		cropHeader.Font = Enum.Font.GothamBold
		cropHeader.TextSize = 9
		cropHeader.Parent = subScroller

		cropHeader.MouseButton1Click:Connect(function()
			if Settings.WateringCropMode == "All" then
				Settings.WateringCropMode = "Selected"
				cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
				cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			else
				Settings.WateringCropMode = "All"
				cropHeader.Text = "🎯 Crop Filter: ALL Plants"
				cropHeader.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
			end
		end)

		local cSelAll = Instance.new("TextButton")
		cSelAll.Size = UDim2.new(0, 75, 0, 18)
		cSelAll.Position = UDim2.new(1, -160, 0, 156)
		cSelAll.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		cSelAll.Text = "✓ All Crops"
		cSelAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		cSelAll.Font = Enum.Font.GothamBold
		cSelAll.TextSize = 8
		cSelAll.Parent = subScroller

		local cClrAll = Instance.new("TextButton")
		cClrAll.Size = UDim2.new(0, 75, 0, 18)
		cClrAll.Position = UDim2.new(1, -80, 0, 156)
		cClrAll.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
		cClrAll.Text = "✗ Clear Crops"
		cClrAll.TextColor3 = Color3.fromRGB(255, 255, 255)
		cClrAll.Font = Enum.Font.GothamBold
		cClrAll.TextSize = 8
		cClrAll.Parent = subScroller

		local cropGridFrame = Instance.new("Frame")
		cropGridFrame.Size = UDim2.new(1, -10, 0, 200)
		cropGridFrame.Position = UDim2.new(0, 0, 0, 176)
		cropGridFrame.BackgroundTransparency = 1
		cropGridFrame.Parent = subScroller

		local cGrid = Instance.new("UIGridLayout")
		cGrid.CellSize = UDim2.new(0.48, 0, 0, 26)
		cGrid.CellPadding = UDim2.new(0.03, 0, 0, 4)
		cGrid.Parent = cropGridFrame

		local function renderWateringCropGrid()
			for _, child in ipairs(cropGridFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			local activeCrops = fetchActiveGardenCropNames()
			for _, cropName in ipairs(activeCrops) do
				local isSel = (Settings.SelectedWateringCrops[cropName] == true)
				local btn = Instance.new("TextButton")
				btn.BackgroundColor3 = isSel and Color3.fromRGB(30, 60, 45) or Color3.fromRGB(32, 38, 48)
				btn.Text = (isSel and "☑ " or "☐ ") .. getCropDisplayName(cropName)
				btn.TextColor3 = isSel and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(190, 200, 215)
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 10
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = cropGridFrame

				local bCorner = Instance.new("UICorner")
				bCorner.CornerRadius = UDim.new(0, 4)
				bCorner.Parent = btn

				btn.MouseButton1Click:Connect(function()
					Settings.SelectedWateringCrops[cropName] = not isSel
					Settings.WateringCropMode = "Selected"
					cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
					cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
					renderWateringCropGrid()
				end)
			end
			local rows = math.ceil(#activeCrops / 2)
			cropGridFrame.Size = UDim2.new(1, -10, 0, rows * 30)
			subScroller.CanvasSize = UDim2.new(0, 0, 0, 180 + (rows * 30))
		end

		cSelAll.MouseButton1Click:Connect(function()
			for _, cName in ipairs(fetchActiveGardenCropNames()) do Settings.SelectedWateringCrops[cName] = true end
			Settings.WateringCropMode = "Selected"
			cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
			cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderWateringCropGrid()
		end)
		cClrAll.MouseButton1Click:Connect(function()
			table.clear(Settings.SelectedWateringCrops)
			Settings.WateringCropMode = "Selected"
			cropHeader.Text = "🎯 Crop Filter: Selected Plants Only"
			cropHeader.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
			renderWateringCropGrid()
		end)
		renderWateringCropGrid()

	elseif selectedGardenSubTab == "Plants" then
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, -16, 0, 26)
		header.Position = UDim2.new(0, 10, 0, 6)
		header.BackgroundTransparency = 1
		header.Text = "🌱 Live Garden Plants Grid Inspector:"
		header.TextColor3 = Color3.fromRGB(46, 204, 113)
		header.Font = Enum.Font.GothamBold
		header.TextSize = 11
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = gRightPanel

		local scroller = Instance.new("ScrollingFrame")
		scroller.Size = UDim2.new(1, -16, 1, -38)
		scroller.Position = UDim2.new(0, 8, 0, 32)
		scroller.BackgroundTransparency = 1
		scroller.ScrollBarThickness = 4
		scroller.Parent = gRightPanel

		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0.488, 0, 0, 32)
		grid.CellPadding = UDim2.new(0.024, 0, 0, 6)
		grid.Parent = scroller

		local plantsList, totalPlants = fetchGardenPlants()
		for _, pData in ipairs(plantsList) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(34, 42, 54)
			card.Parent = scroller

			local cCorner = Instance.new("UICorner")
			cCorner.CornerRadius = UDim.new(0, 6)
			cCorner.Parent = card

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, -6, 1, 0)
			lbl.Position = UDim2.new(0, 4, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = "🌱 " .. pData.Name .. " (" .. pData.Fruits .. " Fruits)"
			lbl.TextColor3 = pData.Fruits > 0 and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(180, 190, 200)
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = 10
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = card
		end

		local rows = math.ceil(totalPlants / 2)
		scroller.CanvasSize = UDim2.new(0, 0, 0, rows * 38)
	end
end

-- Render Left Sub-Nav Category Buttons
local subY = 0
for _, tabInfo in ipairs(gardenSubTabs) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -6, 0, 38)
	btn.Position = UDim2.new(0, 0, 0, subY)
	btn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
	btn.Text = tabInfo.Title
	btn.TextColor3 = Color3.fromRGB(190, 200, 215)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.Parent = gLeftPanel

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = btn

	gardenSubNavButtons[tabInfo.Key] = btn

	btn.MouseButton1Click:Connect(function()
		renderGardenSubPage(tabInfo.Key)
	end)

	subY = subY + 44
end

renderGardenSubPage("Harvest")

----------------------------------------------------
-- TAB 3: SELL PAGE
----------------------------------------------------
local sellPage = createTabPage("Sell")

local sellCard = Instance.new("Frame")
sellCard.Size = UDim2.new(1, 0, 1, 0)
sellCard.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
sellCard.BorderSizePixel = 0
sellCard.Parent = sellPage

local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 10)
scCorner.Parent = sellCard

local sellTitleHeader = Instance.new("TextLabel")
sellTitleHeader.Size = UDim2.new(1, -24, 0, 32)
sellTitleHeader.Position = UDim2.new(0, 12, 0, 10)
sellTitleHeader.BackgroundTransparency = 1
sellTitleHeader.Text = "💰 EXACT PACKET ZERO-MOVEMENT INSTANT SELL"
sellTitleHeader.TextColor3 = Color3.fromRGB(46, 204, 113)
sellTitleHeader.Font = Enum.Font.GothamBold
sellTitleHeader.TextSize = 13
sellTitleHeader.TextXAlignment = Enum.TextXAlignment.Left
sellTitleHeader.Parent = sellCard

local sellFruitBtn = Instance.new("TextButton")
sellFruitBtn.Size = UDim2.new(1, -24, 0, 46)
sellFruitBtn.Position = UDim2.new(0, 12, 0, 52)
sellFruitBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
sellFruitBtn.Text = "💰 Auto Sell All Fruit: OFF"
sellFruitBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
sellFruitBtn.Font = Enum.Font.GothamBold
sellFruitBtn.TextSize = 13
sellFruitBtn.Parent = sellCard

local sFCorner = Instance.new("UICorner")
sFCorner.CornerRadius = UDim.new(0, 8)
sFCorner.Parent = sellFruitBtn

sellFruitBtn.MouseButton1Click:Connect(function()
	Settings.AutoSell = not Settings.AutoSell
	if Settings.AutoSell then
		sellFruitBtn.Text = "💰 Auto Sell All Fruit: ON"
		sellFruitBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		sellFruitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		sellFruitBtn.Text = "💰 Auto Sell All Fruit: OFF"
		sellFruitBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
		sellFruitBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
	end
end)

local manualSellBtn = Instance.new("TextButton")
manualSellBtn.Size = UDim2.new(1, -24, 0, 44)
manualSellBtn.Position = UDim2.new(0, 12, 0, 110)
manualSellBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
manualSellBtn.Text = "⚡ SELL ALL FRUIT NOW"
manualSellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
manualSellBtn.Font = Enum.Font.GothamBold
manualSellBtn.TextSize = 12
manualSellBtn.Parent = sellCard

local mSCorner = Instance.new("UICorner")
mSCorner.CornerRadius = UDim.new(0, 8)
mSCorner.Parent = manualSellBtn

manualSellBtn.MouseButton1Click:Connect(function()
	executeWorkspaceSell()
	print("[Sell] Exact Remote Event Sold all fruit!")
end)

local function renderSellTabBag()
end

----------------------------------------------------
-- TAB 5: ESP PAGE (WEIGHT OVERLAY)
----------------------------------------------------
local espPage = createTabPage("Esp")

local espEnabled = false
local espBillboardCache = {}

local function clearEspHighlights()
	for adornee, billboard in pairs(espBillboardCache) do
		pcall(function() billboard:Destroy() end)
	end
	espBillboardCache = {}
end

local function updateEspOverlay()
	if not espEnabled then
		clearEspHighlights()
		return
	end

	local plantList, totalPlants, totalReady, totalUnready, totalFruits, mutationCounts, cropGroups, fruitList = fetchGardenPlants(false)

	pcall(function()
		local activeAdornees = {}

		for _, fData in ipairs(fruitList or {}) do
			if fData.Position and fData.Adornee then
				local adornee = fData.Adornee
				activeAdornees[adornee] = true

				local billboard = espBillboardCache[adornee]
				local bg, lbl, bgStroke

				if not billboard or not billboard.Parent then
					billboard = Instance.new("BillboardGui")
					billboard.Adornee = adornee
					billboard.Size = UDim2.new(0, 115, 0, 38)
					billboard.StudsOffset = Vector3.new(0, 1.2, 0)
					billboard.AlwaysOnTop = true
					billboard.ClipsDescendants = false
					billboard.Parent = adornee

					bg = Instance.new("Frame")
					bg.Name = "Bg"
					bg.Size = UDim2.new(1, 0, 1, 0)
					bg.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
					bg.BackgroundTransparency = 0.35
					bg.BorderSizePixel = 0
					bg.Parent = billboard

					local bgCorner = Instance.new("UICorner")
					bgCorner.CornerRadius = UDim.new(0, 6)
					bgCorner.Parent = bg

					bgStroke = Instance.new("UIStroke")
					bgStroke.Name = "Stroke"
					bgStroke.Transparency = 0.5
					bgStroke.Thickness = 1
					bgStroke.Parent = bg

					lbl = Instance.new("TextLabel")
					lbl.Name = "Text"
					lbl.Size = UDim2.new(1, -4, 1, -4)
					lbl.Position = UDim2.new(0, 2, 0, 2)
					lbl.BackgroundTransparency = 1
					lbl.Font = Enum.Font.GothamBold
					lbl.TextSize = 10
					lbl.TextWrapped = true
					lbl.TextYAlignment = Enum.TextYAlignment.Center
					lbl.Parent = bg

					espBillboardCache[adornee] = billboard
				else
					bg = billboard:FindFirstChild("Bg")
					if bg then
						lbl = bg:FindFirstChild("Text")
						bgStroke = bg:FindFirstChild("Stroke")
					end
				end

				if lbl then
					local mutStr = ""
					if fData.MutationName and fData.MutationName ~= "Normal" then
						mutStr = " [" .. fData.MutationName .. "]"
					end
					local statusIcon = fData.IsReady and "🟢" or "🟡"

					lbl.Text = string.format("%s %s%s\n%s", 
						statusIcon,
						fData.CropName .. (fData.TotalOnPlant > 1 and (" #" .. fData.FruitIndex) or ""),
						mutStr,
						(fData.Weight and fData.Weight > 0 and string.format("⚖ %.2fkg", fData.Weight) or "⚖ ?kg")
					)
					lbl.TextColor3 = (fData.Weight and fData.Weight > 0) and Color3.fromRGB(243, 156, 18) or Color3.fromRGB(220, 225, 235)
				end

				if bgStroke then
					bgStroke.Color = (fData.Weight and fData.Weight > 0) and Color3.fromRGB(243, 156, 18) or GeistColors.BorderStroke
				end
			end
		end

		-- Clean up billboards for fruits that no longer exist
		for adornee, bb in pairs(espBillboardCache) do
			if not activeAdornees[adornee] or not adornee.Parent then
				pcall(function() bb:Destroy() end)
				espBillboardCache[adornee] = nil
			end
		end
	end)
end

local espCard = Instance.new("Frame")
espCard.Size = UDim2.new(1, 0, 1, 0)
espCard.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
espCard.BorderSizePixel = 0
espCard.Parent = espPage

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 10)
espCorner.Parent = espCard

local espTitle = Instance.new("TextLabel")
espTitle.Size = UDim2.new(1, -24, 0, 32)
espTitle.Position = UDim2.new(0, 12, 0, 10)
espTitle.BackgroundTransparency = 1
espTitle.Text = "👁️ ESP WEIGHT OVERLAY"
espTitle.TextColor3 = Color3.fromRGB(243, 156, 18)
espTitle.Font = Enum.Font.GothamBold
espTitle.TextSize = 13
espTitle.TextXAlignment = Enum.TextXAlignment.Left
espTitle.Parent = espCard

local espToggleBtn = Instance.new("TextButton")
espToggleBtn.Size = UDim2.new(1, -24, 0, 46)
espToggleBtn.Position = UDim2.new(0, 12, 0, 52)
espToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
espToggleBtn.Text = "👁️ ESP Weight: OFF"
espToggleBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
espToggleBtn.Font = Enum.Font.GothamBold
espToggleBtn.TextSize = 13
espToggleBtn.Parent = espCard

local espBtnCorner = Instance.new("UICorner")
espBtnCorner.CornerRadius = UDim.new(0, 8)
espBtnCorner.Parent = espToggleBtn

espToggleBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	if espEnabled then
		espToggleBtn.Text = "👁️ ESP Weight: ON"
		espToggleBtn.BackgroundColor3 = Color3.fromRGB(243, 156, 18)
		espToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		updateEspOverlay()
	else
		espToggleBtn.Text = "👁️ ESP Weight: OFF"
		espToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
		espToggleBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
		clearEspHighlights()
	end
end)

local espRefreshBtn = Instance.new("TextButton")
espRefreshBtn.Size = UDim2.new(1, -24, 0, 36)
espRefreshBtn.Position = UDim2.new(0, 12, 0, 108)
espRefreshBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
espRefreshBtn.Text = "🔄 Refresh ESP"
espRefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
espRefreshBtn.Font = Enum.Font.GothamBold
espRefreshBtn.TextSize = 11
espRefreshBtn.Parent = espCard

local espRefCorner = Instance.new("UICorner")
espRefCorner.CornerRadius = UDim.new(0, 8)
espRefCorner.Parent = espRefreshBtn

espRefreshBtn.MouseButton1Click:Connect(function()
	if espEnabled then
		updateEspOverlay()
	end
end)

-- Auto-refresh ESP loop
task.spawn(function()
	while Settings.IsRunning do
		task.wait(2.0)
		if espEnabled and screenGui and screenGui.Parent then
			updateEspOverlay()
		end
	end
end)

-- Cleanup ESP on script unload
table.insert(scriptConnections, {
	Disconnect = function()
		clearEspHighlights()
	end
})

----------------------------------------------------
-- TAB 4: BUY PAGE
----------------------------------------------------
local buyPage = createTabPage("Buy")

local categorySeedsBtn = Instance.new("TextButton")
categorySeedsBtn.Size = UDim2.new(0.24, 0, 0, 30)
categorySeedsBtn.Position = UDim2.new(0, 0, 0, 0)
categorySeedsBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
categorySeedsBtn.Text = "🌾 SEED SHOP"
categorySeedsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
categorySeedsBtn.Font = Enum.Font.GothamBold
categorySeedsBtn.TextSize = 10
categorySeedsBtn.Parent = buyPage

local cSCorner = Instance.new("UICorner")
cSCorner.CornerRadius = UDim.new(0, 6)
cSCorner.Parent = categorySeedsBtn

local categoryGearsBtn = Instance.new("TextButton")
categoryGearsBtn.Size = UDim2.new(0.24, 0, 0, 30)
categoryGearsBtn.Position = UDim2.new(0.25, 0, 0, 0)
categoryGearsBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
categoryGearsBtn.Text = "⚙️ GEAR SHOP"
categoryGearsBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
categoryGearsBtn.Font = Enum.Font.GothamBold
categoryGearsBtn.TextSize = 10
categoryGearsBtn.Parent = buyPage

local cGCorner = Instance.new("UICorner")
cGCorner.CornerRadius = UDim.new(0, 6)
cGCorner.Parent = categoryGearsBtn

local autoBuyBtn = Instance.new("TextButton")
autoBuyBtn.Size = UDim2.new(0.49, 0, 0, 30)
autoBuyBtn.Position = UDim2.new(0.51, 0, 0, 0)
autoBuyBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
autoBuyBtn.Text = "🛒 Auto Buy Active Seeds: OFF"
autoBuyBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
autoBuyBtn.Font = Enum.Font.GothamBold
autoBuyBtn.TextSize = 10
autoBuyBtn.Parent = buyPage

local aBCorner = Instance.new("UICorner")
aBCorner.CornerRadius = UDim.new(0, 6)
aBCorner.Parent = autoBuyBtn

local autoBuyModeBtn = Instance.new("TextButton")
autoBuyModeBtn.Size = UDim2.new(0.42, 0, 0, 28)
autoBuyModeBtn.Position = UDim2.new(0, 0, 0, 34)
autoBuyModeBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 64)
autoBuyModeBtn.Text = "🎯 Mode: Buy ALL Seeds"
autoBuyModeBtn.TextColor3 = Color3.fromRGB(230, 240, 255)
autoBuyModeBtn.Font = Enum.Font.GothamBold
autoBuyModeBtn.TextSize = 9
autoBuyModeBtn.Parent = buyPage

local aBMCorner = Instance.new("UICorner")
aBMCorner.CornerRadius = UDim.new(0, 6)
aBMCorner.Parent = autoBuyModeBtn

local selectAllBtn = Instance.new("TextButton")
selectAllBtn.Size = UDim2.new(0.27, 0, 0, 28)
selectAllBtn.Position = UDim2.new(0.43, 0, 0, 34)
selectAllBtn.BackgroundColor3 = Color3.fromRGB(34, 153, 84)
selectAllBtn.Text = "☑ SELECT ALL"
selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectAllBtn.Font = Enum.Font.GothamBold
selectAllBtn.TextSize = 9
selectAllBtn.Parent = buyPage

local sACorner = Instance.new("UICorner")
sACorner.CornerRadius = UDim.new(0, 6)
sACorner.Parent = selectAllBtn

local clearAllBtn = Instance.new("TextButton")
clearAllBtn.Size = UDim2.new(0.28, 0, 0, 28)
clearAllBtn.Position = UDim2.new(0.71, 0, 0, 34)
clearAllBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
clearAllBtn.Text = "☐ CLEAR ALL"
clearAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearAllBtn.Font = Enum.Font.GothamBold
clearAllBtn.TextSize = 9
clearAllBtn.Parent = buyPage

local cACorner = Instance.new("UICorner")
cACorner.CornerRadius = UDim.new(0, 6)
cACorner.Parent = clearAllBtn

local rarityScroller = Instance.new("ScrollingFrame")
rarityScroller.Size = UDim2.new(1, 0, 0, 28)
rarityScroller.Position = UDim2.new(0, 0, 0, 66)
rarityScroller.BackgroundTransparency = 1
rarityScroller.ScrollBarThickness = 2
rarityScroller.CanvasSize = UDim2.new(0, 560, 0, 0)
rarityScroller.Parent = buyPage

local rListLayout = Instance.new("UIListLayout")
rListLayout.FillDirection = Enum.FillDirection.Horizontal
rListLayout.Padding = UDim.new(0, 6)
rListLayout.Parent = rarityScroller

local rarityButtons = {}

local shopListFrame = Instance.new("Frame")
shopListFrame.Size = UDim2.new(1, 0, 1, -98)
shopListFrame.Position = UDim2.new(0, 0, 0, 98)
shopListFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
shopListFrame.BorderSizePixel = 0
shopListFrame.Parent = buyPage

local slCorner = Instance.new("UICorner")
slCorner.CornerRadius = UDim.new(0, 10)
slCorner.Parent = shopListFrame

local shopListScroller = Instance.new("ScrollingFrame")
shopListScroller.Size = UDim2.new(1, -16, 1, -12)
shopListScroller.Position = UDim2.new(0, 8, 0, 6)
shopListScroller.BackgroundTransparency = 1
shopListScroller.ScrollBarThickness = 4
shopListScroller.Parent = shopListFrame

local shopListGrid = Instance.new("UIGridLayout")
shopListGrid.CellSize = UDim2.new(0.32, 0, 0, 36)
shopListGrid.CellPadding = UDim2.new(0.013, 0, 0, 6)
shopListGrid.Parent = shopListScroller

local renderBuyTabShop

renderBuyTabShop = function()
	for _, child in ipairs(shopListScroller:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end

	if Settings.ShopViewCategory == "Seeds" then
		rarityScroller.Visible = true
		shopListFrame.Size = UDim2.new(1, 0, 1, -98)
		shopListFrame.Position = UDim2.new(0, 0, 0, 98)

		autoBuyBtn.Text = Settings.AutoBuySeeds and "🛒 Auto Buy Active Seeds: ON" or "🛒 Auto Buy Active Seeds: OFF"
		autoBuyBtn.BackgroundColor3 = Settings.AutoBuySeeds and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)

		autoBuyModeBtn.Text = (Settings.AutoBuyModeSeeds == "All") and "🎯 Mode: Buy ALL Seeds" or "🎯 Mode: Selected Seeds Only"
		autoBuyModeBtn.BackgroundColor3 = (Settings.AutoBuyModeSeeds == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)

		local activeSeeds = fetchActiveSeedShop()
		local count = 0

		for _, sData in ipairs(activeSeeds) do
			if sData.Tier == Settings.SelectedRarity then
				count = count + 1

				local isChecked = (Settings.SelectedSeeds[sData.Name] == true)

				local card = Instance.new("Frame")
				card.BackgroundColor3 = isChecked and Color3.fromRGB(30, 55, 45) or Color3.fromRGB(34, 42, 54)
				card.Parent = shopListScroller

				local cCorner = Instance.new("UICorner")
				cCorner.CornerRadius = UDim.new(0, 6)
				cCorner.Parent = card

				local cStroke = Instance.new("UIStroke")
				cStroke.Color = isChecked and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 60, 75)
				cStroke.Thickness = isChecked and 1.5 or 1
				cStroke.Parent = card

				local chkBtn = Instance.new("TextButton")
				chkBtn.Size = UDim2.new(0.18, 0, 0.8, 0)
				chkBtn.Position = UDim2.new(0.02, 0, 0.1, 0)
				chkBtn.BackgroundColor3 = isChecked and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 52, 65)
				chkBtn.Text = isChecked and "☑" or "☐"
				chkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				chkBtn.Font = Enum.Font.GothamBold
				chkBtn.TextSize = 11
				chkBtn.Parent = card

				local chkCorner = Instance.new("UICorner")
				chkCorner.CornerRadius = UDim.new(0, 4)
				chkCorner.Parent = chkBtn

				chkBtn.MouseButton1Click:Connect(function()
					Settings.SelectedSeeds[sData.Name] = not isChecked
					renderBuyTabShop()
				end)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.50, 0, 1, 0)
				lbl.Position = UDim2.new(0.22, 0, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = "🌾 " .. sData.Name
				lbl.TextColor3 = Color3.fromRGB(230, 240, 255)
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 9
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = card

				local buyBtn = Instance.new("TextButton")
				buyBtn.Size = UDim2.new(0.25, 0, 0.76, 0)
				buyBtn.Position = UDim2.new(0.73, 0, 0.12, 0)
				buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				buyBtn.Text = "BUY"
				buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				buyBtn.Font = Enum.Font.GothamBold
				buyBtn.TextSize = 8
				buyBtn.Parent = card

				local bCorner = Instance.new("UICorner")
				bCorner.CornerRadius = UDim.new(0, 4)
				bCorner.Parent = buyBtn

				buyBtn.MouseButton1Click:Connect(function()
					local stockQty = sData.Stock or 5
					fireBuySeedPacket(sData.Name, stockQty)
					print("[Buy Tab] Bought All Stock (" .. stockQty .. ") of Seed:", sData.Name)
				end)
			end
		end

		if count == 0 then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 1, 0)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No Active " .. Settings.SelectedRarity .. " Seeds in Server Shop"
			emptyLbl.TextColor3 = Color3.fromRGB(150, 160, 175)
			emptyLbl.Font = Enum.Font.Gotham
			emptyLbl.TextSize = 10
			emptyLbl.Parent = shopListScroller
		end

		local rows = math.ceil(count / 3)
		shopListScroller.CanvasSize = UDim2.new(0, 0, 0, rows * 42)
	else
		rarityScroller.Visible = false
		shopListFrame.Size = UDim2.new(1, 0, 1, -66)
		shopListFrame.Position = UDim2.new(0, 0, 0, 66)

		autoBuyBtn.Text = Settings.AutoBuyGears and "⚙️ Auto Buy Active Gears: ON" or "⚙️ Auto Buy Active Gears: OFF"
		autoBuyBtn.BackgroundColor3 = Settings.AutoBuyGears and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(34, 40, 52)

		autoBuyModeBtn.Text = (Settings.AutoBuyModeGears == "All") and "🎯 Mode: Buy ALL Gears" or "🎯 Mode: Selected Gears Only"
		autoBuyModeBtn.BackgroundColor3 = (Settings.AutoBuyModeGears == "All") and Color3.fromRGB(40, 48, 64) or Color3.fromRGB(142, 68, 173)

		local activeGears = fetchActiveGearShop()
		local count = #activeGears

		for _, gData in ipairs(activeGears) do
			local isChecked = (Settings.SelectedGears[gData.Name] == true)

			local card = Instance.new("Frame")
			card.BackgroundColor3 = isChecked and Color3.fromRGB(30, 55, 45) or Color3.fromRGB(34, 42, 54)
			card.Parent = shopListScroller

			local cCorner = Instance.new("UICorner")
			cCorner.CornerRadius = UDim.new(0, 6)
			cCorner.Parent = card

			local cStroke = Instance.new("UIStroke")
			cStroke.Color = isChecked and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(50, 60, 75)
			cStroke.Thickness = isChecked and 1.5 or 1
			cStroke.Parent = card

			local chkBtn = Instance.new("TextButton")
			chkBtn.Size = UDim2.new(0.18, 0, 0.8, 0)
			chkBtn.Position = UDim2.new(0.02, 0, 0.1, 0)
			chkBtn.BackgroundColor3 = isChecked and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(45, 52, 65)
			chkBtn.Text = isChecked and "☑" or "☐"
			chkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			chkBtn.Font = Enum.Font.GothamBold
			chkBtn.TextSize = 11
			chkBtn.Parent = card

			local chkCorner = Instance.new("UICorner")
			chkCorner.CornerRadius = UDim.new(0, 4)
			chkCorner.Parent = chkBtn

			chkBtn.MouseButton1Click:Connect(function()
				Settings.SelectedGears[gData.Name] = not isChecked
				renderBuyTabShop()
			end)

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.50, 0, 1, 0)
			lbl.Position = UDim2.new(0.22, 0, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = "⚙️ " .. gData.Name
			lbl.TextColor3 = Color3.fromRGB(230, 240, 255)
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = 9
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = card

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(0.25, 0, 0.76, 0)
			buyBtn.Position = UDim2.new(0.73, 0, 0.12, 0)
			buyBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
			buyBtn.Text = "BUY"
			buyBtn.TextColor3 = Color3.fromRGB(20, 24, 30)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 8
			buyBtn.Parent = card

			local bCorner = Instance.new("UICorner")
			bCorner.CornerRadius = UDim.new(0, 4)
			bCorner.Parent = buyBtn

			buyBtn.MouseButton1Click:Connect(function()
				local stockQty = gData.Stock or 5
				fireBuyGearPacket(gData.Name, stockQty)
				print("[Buy Tab] Bought All Stock (" .. stockQty .. ") of Gear Tool:", gData.Name)
			end)
		end

		if count == 0 then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 1, 0)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No Sheckle Gears Available in Server Shop"
			emptyLbl.TextColor3 = Color3.fromRGB(150, 160, 175)
			emptyLbl.Font = Enum.Font.Gotham
			emptyLbl.TextSize = 10
			emptyLbl.Parent = shopListScroller
		end

		local rows = math.ceil(count / 3)
		shopListScroller.CanvasSize = UDim2.new(0, 0, 0, rows * 42)
	end
end

autoBuyModeBtn.MouseButton1Click:Connect(function()
	if Settings.ShopViewCategory == "Seeds" then
		Settings.AutoBuyModeSeeds = (Settings.AutoBuyModeSeeds == "All") and "Selected" or "All"
	else
		Settings.AutoBuyModeGears = (Settings.AutoBuyModeGears == "All") and "Selected" or "All"
	end
	renderBuyTabShop()
end)

selectAllBtn.MouseButton1Click:Connect(function()
	if Settings.ShopViewCategory == "Seeds" then
		for _, sName in ipairs(CropCatalogNames) do
			Settings.SelectedSeeds[sName] = true
		end
	else
		for _, gData in ipairs(OfficialGearCatalog) do
			Settings.SelectedGears[gData.Name] = true
		end
	end
	renderBuyTabShop()
end)

clearAllBtn.MouseButton1Click:Connect(function()
	if Settings.ShopViewCategory == "Seeds" then
		Settings.SelectedSeeds = {}
	else
		Settings.SelectedGears = {}
	end
	renderBuyTabShop()
end)

categorySeedsBtn.MouseButton1Click:Connect(function()
	Settings.ShopViewCategory = "Seeds"
	categorySeedsBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	categorySeedsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	categoryGearsBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
	categoryGearsBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
	renderBuyTabShop()
end)

categoryGearsBtn.MouseButton1Click:Connect(function()
	Settings.ShopViewCategory = "Gears"
	categoryGearsBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	categoryGearsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	categorySeedsBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 52)
	categorySeedsBtn.TextColor3 = Color3.fromRGB(190, 200, 215)
	renderBuyTabShop()
end)

autoBuyBtn.MouseButton1Click:Connect(function()
	if Settings.ShopViewCategory == "Seeds" then
		Settings.AutoBuySeeds = not Settings.AutoBuySeeds
	else
		Settings.AutoBuyGears = not Settings.AutoBuyGears
	end
	renderBuyTabShop()
end)

for _, rName in ipairs(RarityList) do
	local rBtn = Instance.new("TextButton")
	rBtn.Size = UDim2.new(0, 64, 1, 0)
	rBtn.BackgroundColor3 = (Settings.SelectedRarity == rName) and Color3.fromRGB(241, 196, 15) or Color3.fromRGB(36, 42, 54)
	rBtn.Text = rName
	rBtn.TextColor3 = (Settings.SelectedRarity == rName) and Color3.fromRGB(20, 24, 30) or Color3.fromRGB(200, 210, 225)
	rBtn.Font = Enum.Font.GothamBold
	rBtn.TextSize = 9
	rBtn.Parent = rarityScroller

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 6)
	rCorner.Parent = rBtn

	rarityButtons[rName] = rBtn

	rBtn.MouseButton1Click:Connect(function()
		Settings.SelectedRarity = rName
		for name, button in pairs(rarityButtons) do
			button.BackgroundColor3 = (name == rName) and Color3.fromRGB(241, 196, 15) or Color3.fromRGB(36, 42, 54)
			button.TextColor3 = (name == rName) and Color3.fromRGB(20, 24, 30) or Color3.fromRGB(200, 210, 225)
		end
		renderBuyTabShop()
	end)
end

----------------------------------------------------
----------------------------------------------------
-- DRAGGABLE GUI LOGIC
----------------------------------------------------
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

table.insert(scriptConnections, titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end))

table.insert(scriptConnections, titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end))

local iconDragging, iconDragInput, iconDragStart, iconStartPos

local function updateIconInput(input)
	local delta = input.Position - iconDragStart
	openIcon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
end

table.insert(scriptConnections, openIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		iconDragging = true
		iconDragStart = input.Position
		iconStartPos = openIcon.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				iconDragging = false
			end
		end)
	end
end))

table.insert(scriptConnections, openIcon.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		iconDragInput = input
	end
end))

table.insert(scriptConnections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateInput(input)
	elseif input == iconDragInput and iconDragging then
		updateIconInput(input)
	end
end))

local function handleMinimize()
	Settings.IsMinimized = true
	mainFrame.Visible = false
	openIcon.Visible = true
end
minimizeBtn.MouseButton1Click:Connect(handleMinimize)
minimizeBtn.Activated:Connect(handleMinimize)

local function handleMaximize()
	Settings.IsMaximized = not Settings.IsMaximized
	if Settings.IsMaximized then
		sizeConstraint.MaxSize = Vector2.new(1920, 1080)
		mainFrame.Size = UDim2.new(0.92, 0, 0.88, 0)
		maximizeBtn.Text = "-"
	else
		sizeConstraint.MaxSize = Vector2.new(900, 620)
		mainFrame.Size = UDim2.new(0.68, 0, 0.62, 0)
		maximizeBtn.Text = "+"
	end
end
maximizeBtn.MouseButton1Click:Connect(handleMaximize)
maximizeBtn.Activated:Connect(handleMaximize)

local function handleClose()
	if confirmModal then
		confirmModal.Visible = true
	else
		cleanupScript()
	end
end
closeBtn.MouseButton1Click:Connect(handleClose)
closeBtn.Activated:Connect(handleClose)

local function handleOpenIcon()
	Settings.IsMinimized = false
	mainFrame.Visible = true
	openIcon.Visible = false
end
openIcon.MouseButton1Click:Connect(handleOpenIcon)
openIcon.Activated:Connect(handleOpenIcon)

table.insert(scriptConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not Settings.IsRunning then return end
	if input.KeyCode == Settings.ToggleKey then
		if mainFrame.Visible then
			mainFrame.Visible = false
			openIcon.Visible = true
		else
			mainFrame.Visible = true
			openIcon.Visible = false
		end
	end
end))

-- Initial Render
switchTab("Main")
renderMainPageGarden()
renderGardenTabList()
renderSellTabBag()
renderBuyTabShop()
updateEspOverlay()

----------------------------------------------------
-- BACKGROUND LOOPS
----------------------------------------------------

task.spawn(function()
	local lastUiUpdate = 0
	while Settings.IsRunning do
		if Settings.AutoHarvest and Settings.IsRunning then
			local count = harvestAllGardenFruits()
			if count > 0 then
				Settings.TotalHarvested = Settings.TotalHarvested + count
				local now = tick()
				if now - lastUiUpdate >= 1.5 then
					lastUiUpdate = now
					if Settings.SelectedTab == "Main" and mainFrame and mainFrame.Visible then renderMainPageGarden() end
					if Settings.SelectedTab == "Garden" and mainFrame and mainFrame.Visible then renderGardenTabList() end
				end
			end
			task.wait(Settings.HarvestInterval or 0.1)
		else
			task.wait(0.2)
		end
	end
end)

task.spawn(function()
	while Settings.IsRunning do
		task.wait(0.5)
		if Settings.AutoShovel and Settings.IsRunning then
			local count = executeAutoShovel()
			if count > 0 then
				if Settings.SelectedTab == "Main" and mainFrame and mainFrame.Visible then renderMainPageGarden() end
				if Settings.SelectedTab == "Garden" and mainFrame and mainFrame.Visible then renderGardenTabList() end
			end
		end
	end
end)

task.spawn(function()
	while Settings.IsRunning do
		if Settings.AutoPlaceSprinkler and Settings.IsRunning then
			executeAutoPlaceSprinkler()
			local dTime = math.max(0.1, Settings.SprinklerDelay or 1.0)
			task.wait(dTime)
		else
			task.wait(0.1)
		end
	end
end)

task.spawn(function()
	while Settings.IsRunning do
		if Settings.AutoWatering and Settings.IsRunning then
			executeAutoWatering()
			local dTime = math.max(0.05, Settings.WateringDelay or 0.5)
			task.wait(dTime)
		else
			task.wait(0.1)
		end
	end
end)

task.spawn(function()
	while Settings.IsRunning do
		task.wait(Settings.SellInterval)
		if Settings.AutoSell and Settings.IsRunning then
			local ok = executeWorkspaceSell()
			if ok then
				Settings.TotalSoldBatches = Settings.TotalSoldBatches + 1
			end
		end
	end
end)

local lastSeedBuyTime = {}
local lastSeedShopSignature = ""

task.spawn(function()
	while Settings.IsRunning do
		task.wait(1.5)
		if Settings.AutoBuySeeds and Settings.IsRunning then
			local activeSeeds = fetchActiveSeedShop()
			local now = tick()

			local restockText = detectShopRestockTime()
			local currentSig = restockText .. "_"
			for _, s in ipairs(activeSeeds) do
				currentSig = currentSig .. s.Name .. ":" .. tostring(s.Stock) .. ";"
			end

			if currentSig ~= lastSeedShopSignature then
				lastSeedShopSignature = currentSig
				lastSeedBuyTime = {}
			end

			local mode = Settings.AutoBuyModeSeeds or "All"

			for _, sData in ipairs(activeSeeds) do
				local isTargeted = false
				if mode == "All" then
					isTargeted = true
				elseif mode == "Selected" then
					isTargeted = (Settings.SelectedSeeds[sData.Name] == true)
				end

				if isTargeted then
					local lastTime = lastSeedBuyTime[sData.Name] or 0
					if (now - lastTime >= 12.0) or not lastSeedBuyTime[sData.Name] then
						lastSeedBuyTime[sData.Name] = now
						local stockQty = sData.Stock or 5
						fireBuySeedPacket(sData.Name, stockQty)
						print("[Auto Buy] Bought all " .. stockQty .. " stock for seed: " .. sData.Name)
						task.wait(0.2)
					end
				end
			end
		end
	end
end)

local lastGearBuyTime = {}
local lastGearShopSignature = ""

task.spawn(function()
	while Settings.IsRunning do
		task.wait(1.5)
		if Settings.AutoBuyGears and Settings.IsRunning then
			local activeGears = fetchActiveGearShop()
			local now = tick()

			local restockText = detectShopRestockTime()
			local currentSig = restockText .. "_"
			for _, g in ipairs(activeGears) do
				if g.IsActive then
					currentSig = currentSig .. g.Name .. ":" .. tostring(g.Stock) .. ";"
				end
			end

			if currentSig ~= lastGearShopSignature then
				lastGearShopSignature = currentSig
				lastGearBuyTime = {}
			end

			local mode = Settings.AutoBuyModeGears or "All"

			for _, gData in ipairs(activeGears) do
				if gData.IsActive then
					local isTargeted = false
					if mode == "All" then
						isTargeted = true
					elseif mode == "Selected" then
						isTargeted = (Settings.SelectedGears[gData.Name] == true)
					end

					if isTargeted then
						local lastTime = lastGearBuyTime[gData.Name] or 0
						if (now - lastTime >= 12.0) or not lastGearBuyTime[gData.Name] then
							lastGearBuyTime[gData.Name] = now
							local stockQty = gData.Stock or 5
							fireBuyGearPacket(gData.Name, stockQty)
							print("[Auto Buy] Bought all " .. stockQty .. " stock for gear: " .. gData.Name)
							task.wait(0.2)
						end
					end
				end
			end
		end
	end
end)

-- Periodic Auto-Refresh Background Loop (Auto-fetches plant & weight data every 1.5 seconds)
task.spawn(function()
	while Settings.IsRunning do
		task.wait(1.5)
		if Settings.IsRunning then
			pcall(function()
				fetchGardenPlants(true)
			end)
		end
	end
end)

print("[Grow a Garden 2] Script loaded! Press 'K' to toggle GUI.")
end)()
