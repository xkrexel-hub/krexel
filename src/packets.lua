----------------------------------------------------
-- Grow a Garden 2 - Packet Remote & Network Module
----------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Packets = {}

function Packets.getPacketRemote()
	local packetRemote = nil
	pcall(function()
		local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
		if sharedModules and sharedModules:FindFirstChild("Packet") then
			packetRemote = sharedModules.Packet:FindFirstChild("RemoteEvent")
		end
	end)
	return packetRemote
end

function Packets.getPacketModule()
	local PacketModule = nil
	pcall(function()
		local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
		if sharedModules and sharedModules:FindFirstChild("Packet") then
			PacketModule = require(sharedModules.Packet)
		end
	end)
	return PacketModule
end

function Packets.fireBuySeedPacket(seedName, quantity)
	if not seedName or #seedName == 0 then return false end
	quantity = quantity or 5
	local success = false
	local PacketModule = Packets.getPacketModule()
	local packetRemote = Packets.getPacketRemote()

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

function Packets.fireBuyGearPacket(gearName, quantity)
	if not gearName or #gearName == 0 then return false end
	quantity = quantity or 5
	local success = false
	local PacketModule = Packets.getPacketModule()
	local packetRemote = Packets.getPacketRemote()

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

function Packets.executeWorkspaceSell(Settings)
	if Settings and not Settings.IsRunning then return false end
	local sold = false
	local packetRemote = Packets.getPacketRemote()
	local PacketModule = Packets.getPacketModule()

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

function Packets.extractPlantUuid(plantModel)
	if not plantModel then return nil end
	local uuid = plantModel:GetAttribute("UUID") or plantModel:GetAttribute("ID") or plantModel:GetAttribute("PlantUUID")
	if not uuid then
		local mName = plantModel.Name
		local matchStr = string.match(mName, "%w+[%-%_]%w+[%-%_]%w+[%-%_]%w+[%-%_]%w+")
		if matchStr then
			uuid = matchStr
		else
			uuid = mName
		end
	end
	return tostring(uuid)
end

function Packets.fireTrowelPlantPacket(plantTarget, rawPayloadOverride)
	local success = false
	local packetRemote = Packets.getPacketRemote()
	local PacketModule = Packets.getPacketModule()

	if rawPayloadOverride and typeof(rawPayloadOverride) == "buffer" then
		pcall(function()
			if packetRemote then
				packetRemote:FireServer(rawPayloadOverride)
				success = true
			end
		end)
		return success
	end

	local plantUuid = nil
	if typeof(plantTarget) == "Instance" then
		plantUuid = Packets.extractPlantUuid(plantTarget)
	elseif typeof(plantTarget) == "string" then
		plantUuid = plantTarget
	end

	if not plantUuid or #plantUuid == 0 then return false end

	if PacketModule then
		pcall(function()
			local trowelPkt = PacketModule("TrowelPlant") or PacketModule("RelocatePlant") or PacketModule("DigPlant") or PacketModule("Trowel")
			if trowelPkt then
				trowelPkt:Fire(plantTarget or plantUuid)
				success = true
			end
		end)
	end

	if packetRemote then
		pcall(function()
			local userIdStr = tostring(player.UserId)
			local targetIdentifier = "/" .. userIdStr .. "_" .. plantUuid
			local posSnippet = "\024\231C\253Z\014CV\253\220\194\155\018(6"
			local payloadStr = "\130\000" .. targetIdentifier .. posSnippet
			local buf = buffer.fromstring(payloadStr)
			packetRemote:FireServer(buf)
			success = true
		end)
	end

	return success
end

return Packets
