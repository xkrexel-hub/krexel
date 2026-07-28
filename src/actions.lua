----------------------------------------------------
-- Grow a Garden 2 - Auto Farming Actions & Shop Module
----------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local Actions = {}

local Packets = nil
pcall(function()
	Packets = loadstring(readfile("e:/Roblox/Script Grow a Garden 2/src/packets.lua") or readfile("src/packets.lua"))()
end)
if not Packets then Packets = require(script.Parent.packets) end

local Scanners = nil
pcall(function()
	Scanners = loadstring(readfile("e:/Roblox/Script Grow a Garden 2/src/scanners.lua") or readfile("src/scanners.lua"))()
end)
if not Scanners then Scanners = require(script.Parent.scanners) end

function Actions.harvestAllGardenFruits(Settings)
	local harvestedCount = 0
	local packetRemote = Packets.getPacketRemote()
	local PacketModule = Packets.getPacketModule()

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
					if Scanners.isMyGardenPlot(plot) then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Crops") or plot
						if plantsFolder then
							for _, plantModel in ipairs(plantsFolder:GetChildren()) do
								local realName, mutation, variant = Scanners.resolvePlantDetails(plantModel)
								local shouldHarvestPlant = true

								-- Crop Filter check
								if Settings.HarvestCropMode == "Selected" then
									if not Settings.SelectedHarvestCrops[realName] then
										shouldHarvestPlant = false
									end
								end

								-- Mutation Filter check
								if shouldHarvestPlant and Settings.HarvestMutationFilter ~= "All" then
									if Settings.HarvestMutationFilter == "Normal" then
										if mutation ~= "Normal" and mutation ~= "" then shouldHarvestPlant = false end
									else
										if mutation ~= Settings.HarvestMutationFilter then shouldHarvestPlant = false end
									end
								end

								-- Plant-level Weight Filter check
								if shouldHarvestPlant and Settings.HarvestWeightFilter ~= "Disabled" then
									local plantMaxW = 0
									for _, desc in ipairs(plantModel:GetDescendants()) do
										local descW = Scanners.extractItemWeight(desc)
										if descW > plantMaxW then plantMaxW = descW end
									end
									local thresh = Settings.HarvestWeightThreshold or 0.0

									if Settings.HarvestWeightFilter == "Below" then
										if plantMaxW >= thresh then
											shouldHarvestPlant = false
										end
									elseif Settings.HarvestWeightFilter == "Above" then
										if plantMaxW <= thresh then
											shouldHarvestPlant = false
										end
									end
								end

								if shouldHarvestPlant then
									local promptsToFire = {}
									for _, desc in ipairs(plantModel:GetDescendants()) do
										if desc:IsA("ProximityPrompt") then
											local actionName = string.lower(tostring(desc.ActionText) .. " " .. tostring(desc.ObjectText))
											if string.find(actionName, "harvest") or string.find(actionName, "pick") or #actionName == 0 or actionName == " " then
												table.insert(promptsToFire, desc)
											end
										end
									end

									if #promptsToFire > 0 then
										for _, prompt in ipairs(promptsToFire) do
											if fireproximityprompt then
												fireproximityprompt(prompt)
												harvestedCount = harvestedCount + 1
											end
										end
										if packetRemote or PacketModule then
											pcall(function()
												local uuid = plantModel:GetAttribute("UUID") or plantModel:GetAttribute("ID") or plantModel.Name
												if packetRemote then
													local payloadStr = "\215\000$" .. tostring(uuid)
													packetRemote:FireServer(buffer.fromstring(payloadStr))
												end
												if PacketModule then
													local harvestPkt = PacketModule("HarvestPlant") or PacketModule("Harvest")
													if harvestPkt then harvestPkt:Fire(plantModel) end
												end
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
	end)

	return harvestedCount
end

function Actions.executeAutoShovel(Settings)
	local shoveledCount = 0
	local packetRemote = Packets.getPacketRemote()
	local PacketModule = Packets.getPacketModule()

	pcall(function()
		local plantList = Scanners.fetchGardenPlants()
		for _, pData in ipairs(plantList) do
			local pModel = pData.Model
			local cName = pData.Name
			if pModel and pModel.Parent then
				local isTargeted = false
				if Settings.AutoShovelMode == "All" then
					isTargeted = true
				elseif Settings.AutoShovelMode == "Selected" then
					isTargeted = (Settings.SelectedShovelCrops[cName] == true)
				end

				if isTargeted then
					pcall(function()
						local uuid = pModel:GetAttribute("UUID") or pModel:GetAttribute("ID") or pModel.Name
						if packetRemote then
							local payloadStr = "\218\000$" .. tostring(uuid)
							packetRemote:FireServer(buffer.fromstring(payloadStr))
							shoveledCount = shoveledCount + 1
						end
						if PacketModule then
							local shovelPkt = PacketModule("ShovelPlant") or PacketModule("RemovePlant") or PacketModule("Shovel")
							if shovelPkt then
								shovelPkt:Fire(pModel)
								shoveledCount = shoveledCount + 1
							end
						end
					end)
				end
			end
		end
	end)

	return shoveledCount
end

function Actions.executeAutoTrowelCrops(Settings)
	local troweledCount = 0
	local plantList = Scanners.fetchGardenPlants()

	for _, pData in ipairs(plantList) do
		local pModel = pData.Model
		local cName = pData.Name
		if pModel and pModel.Parent then
			local isTargeted = false
			if Settings.TrowelCropMode == "All" then
				isTargeted = true
			elseif Settings.TrowelCropMode == "Selected" then
				isTargeted = (Settings.SelectedTrowelCrops[cName] == true)
			end

			if isTargeted then
				local ok = Packets.fireTrowelPlantPacket(pModel)
				if ok then
					troweledCount = troweledCount + 1
					task.wait(0.05)
				end
			end
		end
	end

	return troweledCount
end

function Actions.getGardenPlantTargets(cropMode, selectedCropsTable)
	local positions = {}
	pcall(function()
		local plantList = Scanners.fetchGardenPlants()
		for _, pData in ipairs(plantList) do
			local pModel = pData.Model
			local cName = pData.Name
			if pModel and pModel.Parent then
				local isTargeted = (cropMode == "All") or (selectedCropsTable and selectedCropsTable[cName] == true)
				if isTargeted then
					local pos = pModel:IsA("Model") and (pModel.PrimaryPart and pModel.PrimaryPart.Position or pModel:GetPivot().Position) or pModel.Position
					if pos then table.insert(positions, pos) end
				end
			end
		end
	end)
	return positions
end

function Actions.buildPlaceSprinklerBuffer(pos, sprinklerName)
	sprinklerName = sprinklerName or "Common Sprinkler"
	local nameLen = #sprinklerName
	local totalLen = 2 + 12 + 1 + nameLen
	local buf = buffer.create(totalLen)
	buffer.writeu16(buf, 0, 72)
	buffer.writef32(buf, 2, pos.X)
	buffer.writef32(buf, 6, pos.Y)
	buffer.writef32(buf, 10, pos.Z)
	buffer.writeu8(buf, 14, nameLen)
	buffer.writestring(buf, 15, sprinklerName, nameLen)
	return buf
end

function Actions.executeAutoPlaceSprinkler(Settings)
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
		targetPositions = Actions.getGardenPlantTargets(Settings.SprinklerCropMode, Settings.SelectedSprinklerCrops)
		if #targetPositions == 0 and char:FindFirstChild("HumanoidRootPart") then
			table.insert(targetPositions, char.HumanoidRootPart.Position)
		end
	end

	if #targetPositions == 0 then return 0 end

	local remote = Packets.getPacketRemote()
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
					local buf = Actions.buildPlaceSprinklerBuffer(pos, activeTool.Name)
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

function Actions.buildWateringCanBuffer(pos, wateringCanName)
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

function Actions.executeAutoWatering(Settings)
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
		plantPositions = Actions.getGardenPlantTargets(Settings.WateringCropMode, Settings.SelectedWateringCrops)
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

	local remote = Packets.getPacketRemote()
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
					local buf = Actions.buildWateringCanBuffer(pos, activeTool.Name)
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

function Actions.fetchBackpackItems()
	local items = {}
	pcall(function()
		local bp = player:FindFirstChild("Backpack")
		if bp then
			for _, item in ipairs(bp:GetChildren()) do
				if item:IsA("Tool") then
					table.insert(items, { Name = item.Name, Count = 1, Instance = item })
				end
			end
		end
		local char = player.Character
		if char then
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") then
					table.insert(items, { Name = item.Name .. " (Equipped)", Count = 1, Instance = item })
				end
			end
		end
	end)
	return items
end

function Actions.fetchActiveSeedShop()
	local seeds = {}
	pcall(function()
		local shopFolder = Workspace:FindFirstChild("SeedShop") or Workspace:FindFirstChild("Shops") or Workspace:FindFirstChild("SeedMerchant")
		if shopFolder then
			for _, item in ipairs(shopFolder:GetChildren()) do
				table.insert(seeds, { Name = item.Name, Price = "100 Sheckles" })
			end
		end
	end)
	return seeds
end

function Actions.fetchActiveGearShop()
	local gears = {}
	pcall(function()
		local shopFolder = Workspace:FindFirstChild("GearShop") or Workspace:FindFirstChild("Shops")
		if shopFolder then
			for _, item in ipairs(shopFolder:GetChildren()) do
				table.insert(gears, { Name = item.Name, Price = "500 Sheckles" })
			end
		end
	end)
	return gears
end

function Actions.detectShopRestockTime()
	local restockText = "Restock: --:--"
	pcall(function()
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("SurfaceGui") then
				local txt = desc:IsA("TextLabel") and desc.Text or ""
				if string.find(string.lower(txt), "restock") or string.find(string.lower(txt), "next shop") then
					restockText = txt
					break
				end
			end
		end
	end)
	return restockText
end

return Actions
