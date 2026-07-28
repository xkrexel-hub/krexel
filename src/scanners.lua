----------------------------------------------------
-- Grow a Garden 2 - Plot, Plant & Mutation Scanner Module
----------------------------------------------------
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Scanners = {}

local Catalog = nil
pcall(function()
	Catalog = loadstring(readfile("e:/Roblox/Script Grow a Garden 2/src/catalog.lua") or readfile("src/catalog.lua"))()
end)
if not Catalog then Catalog = require(script.Parent.catalog) end

local CropCatalogNames = Catalog.CropCatalogNames
local CropCatalog = Catalog.CropCatalog
local getCropRarity = Catalog.getCropRarity
local MUTATION_DATA = Catalog.MUTATION_DATA
local SUB_PARTICLE_EXCLUSIONS = Catalog.SUB_PARTICLE_EXCLUSIONS

function Scanners.resolvePlantDetails(plantModel)
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
			end
			if detectedMutation == "Normal" then
				for _, desc in ipairs(plantModel:GetDescendants()) do
					for attrName, attrVal in pairs(desc:GetAttributes()) do
						local aLower = string.lower(tostring(attrName))
						local vStr = tostring(attrVal)
						if string.find(aLower, "mutation") or string.find(aLower, "variant") or string.find(aLower, "variation") or string.find(aLower, "mut") then
							local vLower = string.lower(vStr)
							for _, officialMut in ipairs({"Solarflare", "Pizza", "Chained", "Ignited", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow"}) do
								if string.lower(officialMut) == vLower or string.find(vLower, string.lower(officialMut)) then
									detectedMutation = officialMut
									break
								end
							end
							if detectedMutation ~= "Normal" then break end
							if string.find(vLower, "gold") then
								resolvedVariant = "Gold"
							elseif string.find(vLower, "rainbow") then
								resolvedVariant = "Rainbow"
							end
						end
					end
					if detectedMutation ~= "Normal" then break end
				end
			end
		end

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

	return resolvedName, detectedMutation, resolvedVariant
end

function Scanners.extractItemWeight(item)
	if not item then return 0 end
	local maxW = 0

	local function parseWeightFromText(txt)
		if not txt or type(txt) ~= "string" or #txt == 0 then return 0 end
		local cleanTxt = string.gsub(txt, "<[^>]+>", "")
		
		for numStr in string.gmatch(cleanTxt, "(%d+%.?%d*)%s*[kK][gG]") do
			local n = tonumber(numStr)
			if n and n > 0.001 and n < 10000 then return n end
		end
		for numStr in string.gmatch(cleanTxt, "⚖%s*(%d+%.?%d*)") do
			local n = tonumber(numStr)
			if n and n > 0.001 and n < 10000 then return n end
		end
		local numStr2 = string.match(cleanTxt, "[wW][eE][iI][gG][hH][tT]%s*:%s*(%d+%.?%d*)")
			or string.match(cleanTxt, "_([%d%.]+)kg")
		if numStr2 then
			local n = tonumber(numStr2)
			if n and n > 0.001 and n < 10000 then return n end
		end
		return 0
	end

	pcall(function()
		if item:IsA("TextLabel") or item:IsA("TextButton") then
			local w = parseWeightFromText(item.Text)
			if w > maxW then maxW = w end
		elseif item:IsA("ProximityPrompt") then
			local w1 = parseWeightFromText(item.ObjectText)
			local w2 = parseWeightFromText(item.ActionText)
			if w1 > maxW then maxW = w1 end
			if w2 > maxW then maxW = w2 end
		end

		local validKeys = {"weight", "kg", "mass", "fruitweight", "cropweight", "weightkg", "masskg", "size", "scale"}
		for attrKey, attrVal in pairs(item:GetAttributes()) do
			local kLower = string.lower(tostring(attrKey))
			for _, vKey in ipairs(validKeys) do
				if string.find(kLower, vKey) then
					local num = tonumber(attrVal) or parseWeightFromText(tostring(attrVal))
					if num and num > maxW and num < 10000 then
						maxW = num
					end
					break
				end
			end
		end

		for _, desc in ipairs(item:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextButton") then
				local w = parseWeightFromText(desc.Text)
				if w > maxW then maxW = w end
			elseif desc:IsA("ProximityPrompt") then
				local w1 = parseWeightFromText(desc.ObjectText)
				local w2 = parseWeightFromText(desc.ActionText)
				if w1 > maxW then maxW = w1 end
				if w2 > maxW then maxW = w2 end
			elseif desc:IsA("ValueObject") and desc.Value then
				local cName = string.lower(desc.Name)
				for _, vKey in ipairs(validKeys) do
					if string.find(cName, vKey) then
						local num = tonumber(desc.Value) or parseWeightFromText(tostring(desc.Value))
						if num and num > maxW and num < 10000 then
							maxW = num
						end
						break
					end
				end
			end

			for attrKey, attrVal in pairs(desc:GetAttributes()) do
				local kLower = string.lower(tostring(attrKey))
				for _, vKey in ipairs(validKeys) do
					if string.find(kLower, vKey) then
						local num = tonumber(attrVal) or parseWeightFromText(tostring(attrVal))
						if num and num > maxW and num < 10000 then
							maxW = num
						end
						break
					end
				end
			end
		end

		local nameW = parseWeightFromText(item.Name)
		if nameW > maxW then maxW = nameW end
	end)

	return maxW
end

function Scanners.resolveFruitName(instance, fallbackPlantName)
	if not instance then return fallbackPlantName end
	local matchedName = nil

	pcall(function()
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

		if instance:IsA("ProximityPrompt") then
			local txt = string.lower(tostring(instance.ObjectText) .. " " .. tostring(instance.ActionText))
			for _, cName in ipairs(CropCatalogNames) do
				if string.find(txt, string.lower(cName)) then
					matchedName = cName
					return
				end
			end
		end

		if instance:IsA("TextLabel") then
			local txt = string.lower(tostring(instance.Text))
			for _, cName in ipairs(CropCatalogNames) do
				if string.find(txt, string.lower(cName)) then
					matchedName = cName
					return
				end
			end
		end

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

function Scanners.isMyGardenPlot(plot)
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

local function isInvalidString(str)
	if not str or type(str) ~= "string" then return true end
	local s = str:lower():gsub("%s+", "")
	if #s == 0 then return true end
	if s:match("^%d+$") then return true end
	if s:find("%x%x%x%x%x%x%x%x%-%x%x%x%x") then return true end
	if s:match("^%d+_") then return true end
	return false
end

function Scanners.getPureCropName(plant, fruit)
	local prompt = (fruit and fruit:FindFirstChildWhichIsA("ProximityPrompt", true))
		or (plant and plant:FindFirstChildWhichIsA("ProximityPrompt", true))

	if prompt and prompt.ObjectText and prompt.ObjectText ~= "" and prompt.ObjectText:lower() ~= "harvest" then
		local txt = prompt.ObjectText:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		if not isInvalidString(txt) then
			return txt
		end
	end

	local attrs = { "CropName", "PlantName", "DisplayName", "Species", "Crop", "SeedName", "Name" }
	for _, attr in ipairs(attrs) do
		local val = (fruit and fruit:GetAttribute(attr)) or (plant and plant:GetAttribute(attr))
		if val and type(val) == "string" and val ~= "" and not isInvalidString(val) then
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
					return txt
				end
			end
		end
	end

	return (plant and plant.Name) or "Crop Plant"
end

function Scanners.getOfficialMutations(fruit)
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

	return detectedMutations
end

Scanners.ScanCache = {
	LastScanTime = 0,
	CacheDuration = 3.0,
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

function Scanners.invalidateScanCache()
	Scanners.ScanCache.LastScanTime = 0
end

function Scanners.scanFarmMutations(forceRefresh)
	local now = tick()
	local cache = Scanners.ScanCache
	if not forceRefresh and (now - cache.LastScanTime < cache.CacheDuration) and cache.TotalFruitsScanned > 0 then
		return cache.TotalMutatedFruits, cache.TotalFruitsScanned, cache.MutationSummary, cache.FruitDetails
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
					if Scanners.isMyGardenPlot(plot) or folder ~= Workspace then
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
									local cropName = Scanners.getPureCropName(plant, fruit)
									local muts = Scanners.getOfficialMutations(fruit)

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

	cache.LastScanTime = now
	cache.TotalMutatedFruits = totalMutatedFruits
	cache.TotalFruitsScanned = totalFruitsScanned
	cache.MutationSummary = mutationSummary
	cache.FruitDetails = fruitDetails

	return totalMutatedFruits, totalFruitsScanned, mutationSummary, fruitDetails
end

function Scanners.fetchGardenPlants(forceRefresh)
	local now = tick()
	local cache = Scanners.ScanCache
	if not forceRefresh and cache.PlantList and #cache.PlantList > 0 and (now - cache.LastScanTime < cache.CacheDuration) then
		return cache.PlantList, cache.TotalPlants, cache.TotalReadyFruits, cache.TotalUnreadyFruits, cache.TotalFruits, cache.MutationCounts, cache.CropGroups
	end

	local plantList = {}
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
					if Scanners.isMyGardenPlot(plot) then
						local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Crops") or plot
						if plantsFolder then
							for _, plantModel in ipairs(plantsFolder:GetChildren()) do
								if plantModel:IsA("Model") or plantModel:IsA("Folder") or plantModel:IsA("BasePart") then
									totalPlants = totalPlants + 1
									local realName, mutation, variant = Scanners.resolvePlantDetails(plantModel)
									if variant and variant ~= "Normal" and (mutation == "Normal" or mutation == "") then
										mutation = variant
									end

									if realName and realName ~= "Crop Plant" and realName ~= "Model" and not activeCropSet[realName] then
										activeCropSet[realName] = true
										table.insert(activeCrops, realName)
									end

									local readyCount = 0
									local heaviestSingleFruit = 0

									for _, desc in ipairs(plantModel:GetDescendants()) do
										if desc:IsA("ProximityPrompt") then
											readyCount = readyCount + 1
										end

										local descW = Scanners.extractItemWeight(desc)
										if descW > heaviestSingleFruit then
											heaviestSingleFruit = descW
										end

										local subName = Scanners.resolveFruitName(desc, nil)
										if subName and subName ~= "Crop Plant" then
											realName = subName
											if not activeCropSet[realName] then
												activeCropSet[realName] = true
												table.insert(activeCrops, realName)
											end
										end
									end

									if heaviestSingleFruit <= 0 then
										for _, desc in ipairs(plantModel:GetDescendants()) do
											local txt = ""
											if desc:IsA("TextLabel") or desc:IsA("TextButton") then
												txt = tostring(desc.Text)
											elseif desc:IsA("ProximityPrompt") then
												txt = tostring(desc.ObjectText) .. " " .. tostring(desc.ActionText)
											end
											if #txt > 0 then
												local kgNum = string.match(txt, "(%d+%.?%d*)%s*[kK][gG]")
												if kgNum then
													local n = tonumber(kgNum)
													if n and n > heaviestSingleFruit and n < 50 then heaviestSingleFruit = n end
												else
													for numStr in string.gmatch(txt, "(%d+%.%d+)") do
														local n = tonumber(numStr)
														if n and n > heaviestSingleFruit and n > 0.01 and n < 50 then
															heaviestSingleFruit = n
														end
													end
												end
											end
										end
									end

									mutation = (mutation and mutation ~= "" and mutation ~= "None") and mutation or "Normal"
									mutationCounts[mutation] = (mutationCounts[mutation] or 0) + 1

									local fruitsFolder = plantModel:FindFirstChild("Fruits") or plantModel:FindFirstChild("Produce")
									local totalFruitParts = fruitsFolder and #fruitsFolder:GetChildren() or readyCount

									if readyCount == 0 and totalFruitParts > 0 then
										readyCount = totalFruitParts
									end

									totalReadyFruits = totalReadyFruits + readyCount

									local unreadyCount = 0
									if fruitsFolder then
										for _, fChild in ipairs(fruitsFolder:GetChildren()) do
											if not fChild:FindFirstChildWhichIsA("ProximityPrompt", true) then
												unreadyCount = unreadyCount + 1
											end
										end
									end
									totalUnreadyFruits = totalUnreadyFruits + unreadyCount
									totalFruits = totalFruits + readyCount + unreadyCount

									local cropRarity = getCropRarity(realName)
									if not cropGroups[realName] then
										cropGroups[realName] = {
											Name = realName,
											Count = 1,
											ReadyFruits = readyCount,
											MaxWeight = heaviestSingleFruit,
											Rarity = cropRarity,
											Mutation = mutation,
											Model = plantModel
										}
									else
										cropGroups[realName].Count = cropGroups[realName].Count + 1
										cropGroups[realName].ReadyFruits = cropGroups[realName].ReadyFruits + readyCount
										if heaviestSingleFruit > cropGroups[realName].MaxWeight then
											cropGroups[realName].MaxWeight = heaviestSingleFruit
										end
									end

									table.insert(plantList, {
										Plot = plot.Name,
										Name = realName,
										Mutation = mutation,
										Fruits = readyCount,
										UnreadyFruits = unreadyCount,
										MaxWeight = heaviestSingleFruit,
										Rarity = cropRarity,
										UUID = string.match(plantModel.Name, "_([%w%-]+)$") or plantModel.Name,
										Model = plantModel
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

	cache.LastScanTime = now
	cache.PlantList = plantList
	cache.TotalPlants = totalPlants
	cache.TotalReadyFruits = totalReadyFruits
	cache.TotalUnreadyFruits = totalUnreadyFruits
	cache.TotalFruits = totalFruits
	cache.MutationCounts = mutationCounts
	cache.CropGroups = cropGroups
	cache.ActiveCrops = activeCrops

	return plantList, totalPlants, totalReadyFruits, totalUnreadyFruits, totalFruits, mutationCounts, cropGroups
end

function Scanners.fetchActiveGardenCropNames()
	local activeCrops = {}
	local cropSet = {}

	pcall(function()
		local plantList, _, _, _, _, _, cropGroups = Scanners.fetchGardenPlants()
		if cropGroups then
			for realName, _ in pairs(cropGroups) do
				if realName and realName ~= "Crop Plant" and realName ~= "Model" and not cropSet[realName] then
					cropSet[realName] = true
					table.insert(activeCrops, realName)
				end
			end
		end
	end)

	table.sort(activeCrops)
	return activeCrops
end

return Scanners
