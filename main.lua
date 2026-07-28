--[[
    🌱 Grow a Garden 2 - Ultra Landscape Multi-Tab Hub (Geist Dark Modern Theme)
    
    Modular Master Entry Point & Background Worker Orchestrator
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Robust Module Loader
local function loadModule(modulePath)
	local result = nil
	pcall(function()
		local content = readfile("e:/Roblox/Script Grow a Garden 2/" .. modulePath) or readfile(modulePath)
		if content then
			result = loadstring(content, modulePath)()
		end
	end)
	if not result then
		pcall(function()
			local modName = string.match(modulePath, "([^/]+)%.lua$")
			result = require(script.Parent.src[modName])
		end)
	end
	return result
end

local Settings = loadModule("src/config.lua")
local Catalog  = loadModule("src/catalog.lua")
local Packets  = loadModule("src/packets.lua")
local Scanners = loadModule("src/scanners.lua")
local Actions  = loadModule("src/actions.lua")
local UI       = loadModule("src/ui.lua")

----------------------------------------------------
-- SCRIPT CLEANUP HANDLER
----------------------------------------------------
local function cleanupScript()
	Settings.IsRunning = false
	Settings.AutoHarvest = false
	Settings.AutoWatering = false
	Settings.AutoShovel = false
	Settings.AutoPlaceSprinkler = false
	Settings.AutoSell = false
	Settings.AutoBuySeeds = false
	Settings.AutoBuyGears = false

	if UI.scriptConnections then
		for _, conn in ipairs(UI.scriptConnections) do
			pcall(function() conn:Disconnect() end)
		end
		UI.scriptConnections = {}
	end

	pcall(function()
		if UI.screenGui and UI.screenGui.Parent then
			UI.screenGui:Destroy()
		end
	end)
	print("[Grow a Garden 2] Script successfully unloaded and destroyed.")
end

----------------------------------------------------
-- GUI INITIALIZATION
----------------------------------------------------
UI.initGui(cleanupScript)

----------------------------------------------------
-- BACKGROUND WORKER LOOPS
----------------------------------------------------

-- Auto Harvest Loop
task.spawn(function()
	local lastUiUpdate = 0
	while Settings.IsRunning do
		if Settings.AutoHarvest and Settings.IsRunning then
			local count = Actions.harvestAllGardenFruits(Settings)
			if count > 0 then
				Settings.TotalHarvested = Settings.TotalHarvested + count
				local now = tick()
				if now - lastUiUpdate >= 1.5 then
					lastUiUpdate = now
					Scanners.invalidateScanCache()
				end
			end
			task.wait()
		else
			task.wait(0.1)
		end
	end
end)

-- Auto Shovel Loop
task.spawn(function()
	while Settings.IsRunning do
		task.wait(0.5)
		if Settings.AutoShovel and Settings.IsRunning then
			local count = Actions.executeAutoShovel(Settings)
			if count > 0 then
				Scanners.invalidateScanCache()
			end
		end
	end
end)

-- Auto Trowel Loop
task.spawn(function()
	while Settings.IsRunning do
		task.wait(0.5)
		if Settings.AutoTrowel and Settings.IsRunning then
			local count = Actions.executeAutoTrowelCrops(Settings)
			if count > 0 then
				Scanners.invalidateScanCache()
			end
		end
	end
end)

-- Auto Sprinkler Loop
task.spawn(function()
	while Settings.IsRunning do
		if Settings.AutoPlaceSprinkler and Settings.IsRunning then
			Actions.executeAutoPlaceSprinkler(Settings)
			local dTime = math.max(0.1, Settings.SprinklerDelay or 1.0)
			task.wait(dTime)
		else
			task.wait(0.1)
		end
	end
end)

-- Auto Watering Loop
task.spawn(function()
	while Settings.IsRunning do
		if Settings.AutoWatering and Settings.IsRunning then
			Actions.executeAutoWatering(Settings)
			local dTime = math.max(0.05, Settings.WateringDelay or 0.5)
			task.wait(dTime)
		else
			task.wait(0.1)
		end
	end
end)

-- Auto Sell Loop
task.spawn(function()
	while Settings.IsRunning do
		task.wait(Settings.SellInterval)
		if Settings.AutoSell and Settings.IsRunning then
			local ok = Packets.executeWorkspaceSell(Settings)
			if ok then
				Settings.TotalSoldBatches = Settings.TotalSoldBatches + 1
			end
		end
	end
end)

-- Auto Buy Seeds Loop
local lastSeedBuyTime = {}
local lastSeedShopSignature = ""

task.spawn(function()
	while Settings.IsRunning do
		task.wait(1.5)
		if Settings.AutoBuySeeds and Settings.IsRunning then
			local activeSeeds = Actions.fetchActiveSeedShop()
			local now = tick()

			local restockText = Actions.detectShopRestockTime()
			local currentSig = restockText .. "_"
			for _, seed in ipairs(activeSeeds) do
				currentSig = currentSig .. seed.Name .. "|"
			end

			if currentSig ~= lastSeedShopSignature then
				lastSeedShopSignature = currentSig
				lastSeedBuyTime = {}
			end

			local boughtAny = false
			for _, seedData in ipairs(activeSeeds) do
				local sName = seedData.Name
				local isTargeted = false

				if Settings.AutoBuyModeSeeds == "All" then
					isTargeted = true
				elseif Settings.AutoBuyModeSeeds == "Selected" then
					isTargeted = (Settings.SelectedSeeds[sName] == true)
				end

				if isTargeted then
					local lastTime = lastSeedBuyTime[sName] or 0
					if now - lastTime >= 10.0 then
						local ok = Packets.fireBuySeedPacket(sName, 5)
						if ok then
							lastSeedBuyTime[sName] = now
							boughtAny = true
						end
					end
				end
			end

			if boughtAny then
				task.wait(0.5)
			end
		end
	end
end)

-- Auto Buy Gears Loop
local lastGearBuyTime = {}
local lastGearShopSignature = ""

task.spawn(function()
	while Settings.IsRunning do
		task.wait(1.5)
		if Settings.AutoBuyGears and Settings.IsRunning then
			local activeGears = Actions.fetchActiveGearShop()
			local now = tick()

			local restockText = Actions.detectShopRestockTime()
			local currentSig = restockText .. "_"
			for _, g in ipairs(activeGears) do
				currentSig = currentSig .. g.Name .. "|"
			end

			if currentSig ~= lastGearShopSignature then
				lastGearShopSignature = currentSig
				lastGearBuyTime = {}
			end

			local boughtAny = false
			for _, gData in ipairs(activeGears) do
				local gName = gData.Name
				local isTargeted = false

				if Settings.AutoBuyModeGears == "All" then
					isTargeted = true
				elseif Settings.AutoBuyModeGears == "Selected" then
					isTargeted = (Settings.SelectedGears[gName] == true)
				end

				if isTargeted then
					local lastTime = lastGearBuyTime[gName] or 0
					if now - lastTime >= 10.0 then
						local ok = Packets.fireBuyGearPacket(gName, 5)
						if ok then
							lastGearBuyTime[gName] = now
							boughtAny = true
						end
					end
				end
			end

			if boughtAny then
				task.wait(0.5)
			end
		end
	end
end)

print("[Grow a Garden 2 Hub] All feature modules successfully initialized.")