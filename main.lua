--[[
    ================================================================================
    GAG2 (Grow a Garden 2) - Advanced Auto Harvest & GUI Script (OFFICIAL MUTATIONS FIX)
    ================================================================================
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. CONFIGURATION
-- ==========================================
local Config = {
    AutoHarvest = false,         -- DEFAULT: OFF (User turns ON manually)
    HarvestInterval = 0.15,      -- Seconds between harvest cycles
    HarvestDistance = 999999,    -- Max distance from player (default: unlimited)
    OnlyFullyGrown = false,      -- Default: false (harvest all detected fruits)
    NotifyHarvest = true,        -- Print notification on harvest
    ToggleKey = Enum.KeyCode.RightShift, -- Keybind to hide/show GUI
    
    -- CROPS FILTER
    CropFilterEnabled = false,   -- Enable crop filter dropdown
    CropWhitelist = {},          -- Populate dynamically from GameData.Seeds
    
    -- ADVANCED MUTATION FILTER (Official Mutations)
    MutationFilterEnabled = false, -- Enable mutation filter dropdown
    FilterMutationsOnly = false,   -- If true, harvest only mutated fruits
    MutationWhitelist = {          -- Enable/disable specific mutations
        Gold       = true,
        Rainbow    = true,
        Bloodlit   = true,
        Electric   = true,
        Starstruck = true,
        Frozen     = true,
        Aurora     = true,
        Eclipsed   = true,
        Glow       = true,
        Ignited    = true,
        Chained    = true,
        Solarflare = true,
        Pizza      = true,
        Secret     = true,
        Veil       = true,
        Normal     = true,         -- Non-mutated crops
    },
    
    -- CUSTOM WEIGHT FILTER LOGIC (KG)
    WeightFilterAboveEnabled = false, -- Enable Weight Above filter
    WeightAboveKg = 0.0,              -- Harvest only if Weight >= WeightAboveKg
    WeightFilterBelowEnabled = false, -- Enable Weight Below filter
    WeightBelowKg = 999999.0,         -- Harvest only if Weight <= WeightBelowKg

    -- FRUIT ESP CONFIGURATION
    EspEnabled = false,               -- Master Fruit ESP switch (DEFAULT: OFF)
    EspShowWeight = true,             -- Show crop weight on ESP (Default: ON)
    EspShowMutation = true,           -- Show mutation badge on ESP (Default: ON)
    EspShowDistance = true,           -- Show distance in meters (Default: ON)
    EspMaxDistance = 500,             -- Max ESP render distance in studs
    EspOnlyReady = false,             -- Filter ESP for ready crops only
    EspOnlyMutated = false,           -- Filter ESP for mutated crops only
}

-- ==========================================
-- 2. GAME DATA DATABASE (Plant, Seed, Mutation, Weight)
-- ==========================================
local GameData = {}

-- Official Mutations Database & Multipliers
GameData.Mutations = {
    Gold       = { Multiplier = 10,  Color = Color3.fromRGB(241, 196, 15) },
    Rainbow    = { Multiplier = 30,  Color = Color3.fromRGB(231, 76, 60) },
    Bloodlit   = { Multiplier = 70,  Color = Color3.fromRGB(192, 57, 43) },
    Electric   = { Multiplier = 25,  Color = Color3.fromRGB(52, 152, 219) },
    Starstruck = { Multiplier = 50,  Color = Color3.fromRGB(241, 196, 15) },
    Frozen     = { Multiplier = 20,  Color = Color3.fromRGB(175, 238, 238) },
    Aurora     = { Multiplier = 40,  Color = Color3.fromRGB(155, 89, 182) },
    Eclipsed   = { Multiplier = 80,  Color = Color3.fromRGB(142, 68, 173) },
    Glow       = { Multiplier = 80,  Color = Color3.fromRGB(46, 204, 113) },
    Ignited    = { Multiplier = 60,  Color = Color3.fromRGB(230, 126, 34) },
    Chained    = { Multiplier = 8,   Color = Color3.fromRGB(149, 165, 166) },
    Solarflare = { Multiplier = 5,   Color = Color3.fromRGB(255, 165, 0) },
    Pizza      = { Multiplier = 5,   Color = Color3.fromRGB(220, 120, 50) },
    Secret     = { Multiplier = 100, Color = Color3.fromRGB(200, 200, 200) },
    Veil       = { Multiplier = 50,  Color = Color3.fromRGB(138, 43, 226) },
}

-- Updated Crop Database (List of Non-Exclusive Crops)
GameData.Seeds = {
    -- Common Crops
    ["Carrot"]          = { Rarity = "Common",    SingleHarvest = true,  BasePrice = 5,    BaseWeight = 0.80, YHeight = 2.0 },
    ["Blueberry"]       = { Rarity = "Common",    SingleHarvest = false, BasePrice = 5,    BaseWeight = 1.15, YHeight = 1.0 },
    ["Strawberry"]      = { Rarity = "Common",    SingleHarvest = false, BasePrice = 3,    BaseWeight = 1.00, YHeight = 1.0 },
    
    -- Uncommon Crops
    ["Apple"]           = { Rarity = "Uncommon",  SingleHarvest = false, BasePrice = 12,   BaseWeight = 1.50, YHeight = 1.0 },
    ["Tomato"]          = { Rarity = "Uncommon",  SingleHarvest = false, BasePrice = 9,    BaseWeight = 0.90, YHeight = 1.0 },
    ["Tulip"]           = { Rarity = "Uncommon",  SingleHarvest = true,  BasePrice = 60,   BaseWeight = 0.50, YHeight = 1.0 },
    
    -- Rare Crops
    ["Baby Cactus"]     = { Rarity = "Rare",      SingleHarvest = false, BasePrice = 70,   BaseWeight = 1.50, YHeight = 1.5 },
    ["Bamboo"]          = { Rarity = "Rare",      SingleHarvest = true,  BasePrice = 800,  BaseWeight = 4.00, YHeight = 4.0 },
    ["Cactus"]          = { Rarity = "Rare",      SingleHarvest = false, BasePrice = 40,   BaseWeight = 1.50, YHeight = 2.0 },
    ["Corn"]            = { Rarity = "Rare",      SingleHarvest = false, BasePrice = 34,   BaseWeight = 3.00, YHeight = 3.0 },
    ["Horned Melon"]    = { Rarity = "Rare",      SingleHarvest = false, BasePrice = 200,  BaseWeight = 1.12, YHeight = 1.5 },
    ["Pineapple"]       = { Rarity = "Rare",      SingleHarvest = false, BasePrice = 30,   BaseWeight = 5.00, YHeight = 2.0 },
    
    -- Epic Crops
    ["Banana"]          = { Rarity = "Epic",      SingleHarvest = false, BasePrice = 35,   BaseWeight = 1.50, YHeight = 1.5 },
    ["Coconut"]         = { Rarity = "Epic",      SingleHarvest = false, BasePrice = 60,   BaseWeight = 1.50, YHeight = 2.0 },
    ["Glow Mushroom"]   = { Rarity = "Epic",      SingleHarvest = false, BasePrice = 700,  BaseWeight = 7.00, YHeight = 2.0 },
    ["Grape"]           = { Rarity = "Epic",      SingleHarvest = false, BasePrice = 45,   BaseWeight = 2.00, YHeight = 1.5 },
    ["Green Bean"]      = { Rarity = "Epic",      SingleHarvest = false, BasePrice = 10,   BaseWeight = 0.50, YHeight = 1.0 },
    ["Mango"]           = { Rarity = "Epic",      SingleHarvest = false, BasePrice = 90,   BaseWeight = 3.00, YHeight = 2.0 },
    ["Mushroom"]        = { Rarity = "Epic",      SingleHarvest = true,  BasePrice = 13000,BaseWeight = 5.00, YHeight = 2.0 },
    
    -- Legendary Crops
    ["Acorn"]           = { Rarity = "Legendary", SingleHarvest = false, BasePrice = 200,  BaseWeight = 1.50, YHeight = 1.5 },
    ["Cherry"]          = { Rarity = "Legendary", SingleHarvest = false, BasePrice = 350,  BaseWeight = 1.50, YHeight = 1.5 },
    ["Dragon Fruit"]    = { Rarity = "Legendary", SingleHarvest = false, BasePrice = 150,  BaseWeight = 3.00, YHeight = 2.0 },
    ["Fire Fern"]       = { Rarity = "Legendary", SingleHarvest = false, BasePrice = 900,  BaseWeight = 9.00, YHeight = 2.5 },
    ["Poison Ivy"]      = { Rarity = "Legendary", SingleHarvest = false, BasePrice = 1700, BaseWeight = 2.10, YHeight = 1.5 },
    ["Sunflower"]       = { Rarity = "Legendary", SingleHarvest = false, BasePrice = 1750, BaseWeight = 6.00, YHeight = 3.0 },
    
    -- Mythic Crops
    ["Ghost Pepper"]    = { Rarity = "Mythic",    SingleHarvest = false, BasePrice = 2500, BaseWeight = 7.50, YHeight = 2.0 },
    ["Poison Apple"]    = { Rarity = "Mythic",    SingleHarvest = false, BasePrice = 900,  BaseWeight = 2.25, YHeight = 1.5 },
    ["Pomegranate"]     = { Rarity = "Mythic",    SingleHarvest = false, BasePrice = 900,  BaseWeight = 1.50, YHeight = 1.5 },
    ["Venom Spitter"]   = { Rarity = "Mythic",    SingleHarvest = false, BasePrice = 3800, BaseWeight = 9.00, YHeight = 2.5 },
    ["Venus Fly Trap"]  = { Rarity = "Mythic",    SingleHarvest = false, BasePrice = 3000, BaseWeight = 3.00, YHeight = 2.0 },
    
    -- Super Crops
    ["Dragon's Breath"] = { Rarity = "Super",     SingleHarvest = false, BasePrice = 3400, BaseWeight = 7.50, YHeight = 2.5 },
    ["DragonBreath"]    = { Rarity = "Super",     SingleHarvest = false, BasePrice = 3400, BaseWeight = 7.50, YHeight = 2.5 },
    ["Hypno Bloom"]     = { Rarity = "Super",     SingleHarvest = false, BasePrice = 9500, BaseWeight = 9.00, YHeight = 3.0 },
    ["Moon Bloom"]      = { Rarity = "Super",     SingleHarvest = false, BasePrice = 9000, BaseWeight = 9.00, YHeight = 3.0 },
    ["Sun Bloom"]       = { Rarity = "Super",     SingleHarvest = false, BasePrice = 9000, BaseWeight = 9.00, YHeight = 3.0 },
    ["Star Fruit"]      = { Rarity = "Super",     SingleHarvest = false, BasePrice = 6000, BaseWeight = 9.00, YHeight = 2.0 },
    
    -- Secret Crops
    ["Eclipse Bloom"]   = { Rarity = "Secret",    SingleHarvest = false, BasePrice = 12000,BaseWeight = 9.00, YHeight = 3.0 },
}

-- Populate Crop Whitelist by default (All Enabled = true)
for cropName in pairs(GameData.Seeds) do
    Config.CropWhitelist[cropName] = true
end

-- Weight Formatter Helper
GameData.FormatWeight = function(grams)
    grams = tonumber(grams) or 0
    if grams >= 1000 then
        return string.format("%.2f kg", grams / 1000)
    else
        return string.format("%.2f g", grams)
    end
end

-- Estimated Sell Value Calculator
GameData.CalculateValue = function(fruitName, weightGrams, mutationName)
    local seedInfo = GameData.Seeds[fruitName] or { BasePrice = 10, BaseWeight = 1.0 }
    local basePrice = seedInfo.BasePrice
    local sizeMult = math.pow(math.max(weightGrams, 1) / 10, 1.5)
    local mutMult = 1.0

    if mutationName and GameData.Mutations[mutationName] then
        mutMult = GameData.Mutations[mutationName].Multiplier
    end

    return math.floor(basePrice * sizeMult * mutMult)
end

-- ==========================================
-- 3. NETWORK & PACKET ENCODER
-- ==========================================
local Network = {}

-- Safely locate RemoteEvent from SharedModules.Packet.RemoteEvent
function Network.GetRemoteEvent()
    local sharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
    local packetModule = sharedModules and sharedModules:FindFirstChild("Packet")
    local remote = packetModule and packetModule:FindFirstChild("RemoteEvent")
    
    if not remote then
        for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("RemoteEvent") and item.Name == "RemoteEvent" and item.Parent and item.Parent.Name == "Packet" then
                remote = item
                break
            end
        end
    end
    
    return remote
end

-- Constructs packet buffer matching remote structure:
-- Header: 0xD7 0x00 0x24 (\215\000$) -> Opcode 215 + uint16 string length 36
-- Plant UUID: 36-character string GUID
-- Fruit ID Length: 1 byte string length (#fruitId)
-- Fruit ID: Fruit index string (e.g. "21", "163", "34", "95")
function Network.CreateHarvestBuffer(plantUUID, fruitId)
    plantUUID = tostring(plantUUID)
    fruitId = tostring(fruitId)
    
    local header = "\215\000$"
    local fruitIdLen = string.char(#fruitId)
    local rawString = header .. plantUUID .. fruitIdLen .. fruitId
    
    return buffer.fromstring(rawString)
end

-- Send harvest remote packet
function Network.SendHarvest(plantUUID, fruitId)
    local remote = Network.GetRemoteEvent()
    if not remote then
        warn("[AutoHarvest Error] RemoteEvent (SharedModules.Packet.RemoteEvent) not found!")
        return false
    end
    
    plantUUID = tostring(plantUUID)
    fruitId = tostring(fruitId)
    
    local pktBuffer = Network.CreateHarvestBuffer(plantUUID, fruitId)
    local args = { pktBuffer }
    
    local success, err = pcall(function()
        remote:FireServer(unpack(args))
    end)
    
    if not success then
        warn("[AutoHarvest Error] FireServer failed:", err)
        return false
    end
    
    return true
end

-- ==========================================
-- 4. ENHANCED SCANNER & DATA EXTRACTOR
-- ==========================================
local Scanner = {}

local UUID_PATTERN = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"

local OFFICIAL_MUTATIONS = {
    "Gold", "Rainbow", "Bloodlit", "Electric", "Starstruck",
    "Frozen", "Aurora", "Eclipsed", "Glow", "Ignited",
    "Chained", "Solarflare", "Pizza", "Secret", "Veil"
}

local MUTATION_DATA = {
	{ Name = "Gold",       Multiplier = "10x", Icon = "🪙", ExactNames = { "goldvfx", "gold", "golden", "greenbeangold" } },
	{ Name = "Rainbow",    Multiplier = "30x", Icon = "🌈", ExactNames = { "rainbowvfx", "rainbow", "strawberryrainbow" } },
	{ Name = "Bloodlit",   Multiplier = "70x", Icon = "🩸", ExactNames = { "bloodlitvfx", "bloodlit", "bamboobloodlit" } },
	{ Name = "Electric",   Multiplier = "25x", Icon = "⚡", ExactNames = { "electricvfx", "electric", "bambooelectric", "lightning", "shocked" } },
	{ Name = "Starstruck", Multiplier = "50x", Icon = "⭐", ExactNames = { "starstruckvfx", "starstruck", "blueberrystarstruck", "starfall" } },
	{ Name = "Frozen",     Multiplier = "20x", Icon = "❄️", ExactNames = { "frozenvfx", "frozen", "frost", "gag" } },
	{ Name = "Aurora",     Multiplier = "40x", Icon = "🌌", ExactNames = { "aurorav2", "auroravfx", "aurora" } },
	{ Name = "Eclipsed",   Multiplier = "80x", Icon = "🌒", ExactNames = { "eclipsedvfx", "eclipsed", "eclipse" } },
	{ Name = "Glow",       Multiplier = "💡", Icon = "💡", ExactNames = { "glowmutation", "glowvfx", "glow" } },
	{ Name = "Secret",     Multiplier = "TBA", Icon = "❓", ExactNames = { "secretvfx", "secret" } },
	{ Name = "Solarflare", Multiplier = "5x",  Icon = "☀️", ExactNames = { "solarflarevfx", "solarflare" } },
	{ Name = "Pizza",      Multiplier = "5x",  Icon = "🍕", ExactNames = { "pizzavfx", "pizza" } },
	{ Name = "Chained",    Multiplier = "8x",  Icon = "⛓️", ExactNames = { "chainedvfx", "chained" } },
	{ Name = "Ignited",    Multiplier = "60x", Icon = "🔥", ExactNames = { "ignitedvfx", "ignited" } },
	{ Name = "Veil",       Multiplier = "50x", Icon = "🔮", ExactNames = { "veilvfx", "veil", "veiled" } }
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

-- Exact & Alias Lookup Map
local MUTATION_LOOKUP = {}
for _, mut in ipairs(OFFICIAL_MUTATIONS) do
    MUTATION_LOOKUP[mut:lower()] = mut
end

-- Extensive Aliases Map
MUTATION_LOOKUP["golden"]         = "Gold"
MUTATION_LOOKUP["gilded"]         = "Gold"
MUTATION_LOOKUP["prismatic"]      = "Rainbow"
MUTATION_LOOKUP["iridescent"]     = "Rainbow"
MUTATION_LOOKUP["electrified"]    = "Electric"
MUTATION_LOOKUP["lightning"]      = "Electric"
MUTATION_LOOKUP["thunder"]        = "Electric"
MUTATION_LOOKUP["shock"]          = "Electric"
MUTATION_LOOKUP["shocked"]        = "Electric"
MUTATION_LOOKUP["spark"]          = "Electric"
MUTATION_LOOKUP["sparks"]         = "Electric"
MUTATION_LOOKUP["sparkling"]      = "Electric"
MUTATION_LOOKUP["voltaic"]        = "Electric"
MUTATION_LOOKUP["tesla"]          = "Electric"
MUTATION_LOOKUP["zapped"]         = "Electric"
MUTATION_LOOKUP["zap"]            = "Electric"
MUTATION_LOOKUP["frost"]          = "Frozen"
MUTATION_LOOKUP["frosted"]        = "Frozen"
MUTATION_LOOKUP["ice"]            = "Frozen"
MUTATION_LOOKUP["icy"]            = "Frozen"
MUTATION_LOOKUP["glacial"]        = "Frozen"
MUTATION_LOOKUP["chilled"]        = "Frozen"
MUTATION_LOOKUP["vampiric"]       = "Bloodlit"
MUTATION_LOOKUP["blood"]          = "Bloodlit"
MUTATION_LOOKUP["bloody"]         = "Bloodlit"
MUTATION_LOOKUP["crimson"]        = "Bloodlit"
MUTATION_LOOKUP["starlight"]      = "Starstruck"
MUTATION_LOOKUP["cosmic"]         = "Starstruck"
MUTATION_LOOKUP["astral"]         = "Starstruck"
MUTATION_LOOKUP["boreal"]         = "Aurora"
MUTATION_LOOKUP["eclipse"]        = "Eclipsed"
MUTATION_LOOKUP["shadow"]         = "Eclipsed"
MUTATION_LOOKUP["dark"]           = "Eclipsed"
MUTATION_LOOKUP["glowing"]        = "Glow"
MUTATION_LOOKUP["radiant"]        = "Glow"
MUTATION_LOOKUP["luminous"]       = "Glow"
MUTATION_LOOKUP["bioluminescent"] = "Glow"
MUTATION_LOOKUP["fire"]           = "Ignited"
MUTATION_LOOKUP["flame"]          = "Ignited"
MUTATION_LOOKUP["flaming"]        = "Ignited"
MUTATION_LOOKUP["infernal"]       = "Ignited"
MUTATION_LOOKUP["blazing"]        = "Ignited"
MUTATION_LOOKUP["burned"]         = "Ignited"
MUTATION_LOOKUP["burning"]        = "Ignited"
MUTATION_LOOKUP["chain"]          = "Chained"
MUTATION_LOOKUP["shackled"]       = "Chained"
MUTATION_LOOKUP["solar"]          = "Solarflare"
MUTATION_LOOKUP["sun"]            = "Solarflare"
MUTATION_LOOKUP["veiled"]         = "Veil"

-- Standardizes any mutation string or alias into canonical mutation name
function Scanner.NormalizeMutationName(str)
    if type(str) ~= "string" or #str == 0 then return nil end
    
    local cleanStr = str:lower()
    cleanStr = cleanStr:gsub("^is", ""):gsub("^mutation_", ""):gsub("^mutated_", ""):gsub("^tag_", ""):gsub("^effect_", "")
    cleanStr = cleanStr:gsub("_mutation$", ""):gsub("_fx$", ""):gsub("fx$", ""):gsub("particle$", ""):gsub("particles$", "")
    cleanStr = cleanStr:gsub("%s+", ""):gsub("[%p%c]", "")
    
    if #cleanStr == 0 then return nil end
    
    if MUTATION_LOOKUP[cleanStr] then
        return MUTATION_LOOKUP[cleanStr]
    end
    
    for alias, canonical in pairs(MUTATION_LOOKUP) do
        if #alias >= 3 and cleanStr:find(alias, 1, true) then
            return canonical
        end
    end
    
    return nil
end

-- Checks if a plot belongs to local player
function Scanner.IsMyGardenPlot(plot)
    if not plot then return false end

    local isMine = false
    pcall(function()
        local ownerAttr = plot:GetAttribute("Owner") or plot:GetAttribute("OwnerName") or plot:GetAttribute("Player") or plot:GetAttribute("UserId")
        local ownerValObj = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerName") or plot:FindFirstChild("Player")
        local ownerStr = tostring(ownerAttr or (ownerValObj and ownerValObj.Value) or "")

        if ownerStr == LocalPlayer.Name or ownerStr == tostring(LocalPlayer.UserId) or (ownerStr ~= "" and string.find(string.lower(plot.Name), string.lower(LocalPlayer.Name))) or string.find(plot.Name, tostring(LocalPlayer.UserId)) then
            isMine = true
            return
        end

        local char = LocalPlayer.Character
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

-- Locate local player's plot/farm
function Scanner.GetPlayerPlot()
    local searchLocations = {
        workspace:FindFirstChild("Gardens"),
        workspace:FindFirstChild("Plots"),
        workspace:FindFirstChild("_Gardens"),
        workspace:FindFirstChild("Farms"),
        workspace:FindFirstChild("Farm"),
        workspace:FindFirstChild("GardenPlots"),
        workspace:FindFirstChild("PlayerPlots"),
        workspace:FindFirstChild("MyPlot"),
        workspace
    }
    
    for _, container in ipairs(searchLocations) do
        if container then
            for _, plot in ipairs(container:GetChildren()) do
                if Scanner.IsMyGardenPlot(plot) then
                    return plot
                end
            end
        end
    end
    
    return workspace
end

-- Resolve plant clean name, mutation & variant
local plantDetailsCache = setmetatable({}, { __mode = "k" })

function Scanner.ResolvePlantDetails(plantModel)
    if not plantModel then return "Crop Plant", "Normal", "Normal" end
    local cached = plantDetailsCache[plantModel]
    if cached then
        return cached.Name, cached.Mutation, cached.Variant
    end

    local resolvedName = nil

    pcall(function()
        for attrName, attrVal in pairs(plantModel:GetAttributes()) do
            if type(attrVal) == "string" and #attrVal > 1 then
                for cropName in pairs(GameData.Seeds) do
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
                    for cropName in pairs(GameData.Seeds) do
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
                for cropName in pairs(GameData.Seeds) do
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
            local norm = Scanner.NormalizeMutationName(tostring(rootMut))
            if norm then
                detectedMutation = norm
            end
        end

        local rootVar = plantModel:GetAttribute("Variant") or plantModel:GetAttribute("VariantType") or plantModel:GetAttribute("Variation")
        if rootVar and tostring(rootVar) ~= "" and tostring(rootVar) ~= "None" then
            local norm = Scanner.NormalizeMutationName(tostring(rootVar))
            if norm then
                resolvedVariant = norm
            end
        end

        if detectedMutation == "Normal" then
            for _, desc in ipairs(plantModel:GetChildren()) do
                local dName = string.lower(desc.Name)

                if string.find(dName, "solarflare_mut") or dName == "solarflare" then
                    detectedMutation = "Solarflare"; break
                elseif string.find(dName, "pizzamutation") or dName == "pizza_mut" or dName == "pizza" then
                    detectedMutation = "Pizza"; break
                elseif string.find(dName, "chainedmutation") or dName == "chained_mut" or dName == "chained" then
                    detectedMutation = "Chained"; break
                elseif string.find(dName, "ignitedmutation") or dName == "ignited_mut" or dName == "ignited" then
                    detectedMutation = "Ignited"; break
                elseif string.find(dName, "bloodlit_mut") or dName == "bloodlit" or dName == "bloodmoon_mut" then
                    detectedMutation = "Bloodlit"; break
                elseif string.find(dName, "electric_mut") or string.find(dName, "electricmutation") or dName == "electric" or dName == "lightning" then
                    detectedMutation = "Electric"; break
                elseif string.find(dName, "starstruck_mut") or dName == "starstruck" or dName == "starfall_mut" then
                    detectedMutation = "Starstruck"; break
                elseif string.find(dName, "frozen_mut") or string.find(dName, "frozenmutation") or dName == "frozen" or dName == "frost" then
                    detectedMutation = "Frozen"; break
                elseif string.find(dName, "aurora_mut") or dName == "aurorav2" or dName == "auroramutation" or dName == "aurora" then
                    detectedMutation = "Aurora"; break
                elseif string.find(dName, "eclipsed_mut") or dName == "eclipsed" or dName == "eclipse_mut" or dName == "eclipse" then
                    detectedMutation = "Eclipsed"; break
                elseif string.find(dName, "glowmutation") or dName == "glow_mut" or dName == "glow" then
                    detectedMutation = "Glow"; break
                elseif dName == "gold" or dName == "gold_variant" or dName == "goldmutation" or dName == "goldvfx" then
                    resolvedVariant = "Gold"; break
                elseif dName == "rainbow" or dName == "rainbow_variant" or dName == "rainbowmutation" or dName == "rainbowvfx" then
                    resolvedVariant = "Rainbow"; break
                end
            end
        end
    end)

    plantDetailsCache[plantModel] = { Name = resolvedName, Mutation = detectedMutation, Variant = resolvedVariant }
    return resolvedName, detectedMutation, resolvedVariant
end

-- Authoritative Item Weight Extractor & Calculator (Attributes & Functions ONLY - NO LABELS)
local persistentWeightCache = setmetatable({}, { __mode = "k" })
local PlantSizeModuleCache = nil

task.spawn(function()
    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("SharedModules") or ReplicatedStorage:FindFirstChild("Modules") or ReplicatedStorage:FindFirstChild("UserGenerated")
        if shared then
            local sizeMod = shared:FindFirstChild("PlantSizeMultipliers") or shared:FindFirstChild("WeightCalculator")
            if sizeMod and sizeMod:IsA("ModuleScript") then
                PlantSizeModuleCache = require(sizeMod)
            end
        end
    end)
end)

function Scanner.CalculateItemWeight(item)
    if not item then return 800 end
    if persistentWeightCache[item] and persistentWeightCache[item] > 0 then
        return persistentWeightCache[item]
    end

    local maxW = 0

    local function isExplicitWeightKey(kStr)
        if not kStr then return false end
        local k = string.lower(tostring(kStr))
        return k == "weight" or k == "fruitweight" or k == "cropweight" or k == "weightkg" 
            or k == "weightgrams" or k == "itemweight" or k == "baseweight"
            or k == "kg" or k == "mass" or k == "masskg" or k == "gram" or k == "grams"
            or string.find(k, "weight") ~= nil or string.find(k, "mass") ~= nil
    end

    local function isScaleKey(kStr)
        if not kStr then return false end
        local k = string.lower(tostring(kStr))
        return k == "scale" or k == "size" or k == "sizemultiplier" or k == "weightmultiplier"
            or k == "fruitscale" or k == "plantscale" or k == "growthprogress" or k == "mult"
            or k == "multiplier" or k == "sizemult" or k == "weightmult" or k == "ratio"
            or string.find(k, "scale") ~= nil or string.find(k, "size") ~= nil or string.find(k, "mult") ~= nil
    end

    local function processVal(val, keyName)
        if type(val) == "number" then
            if val > 0.0001 and val < 100000000 then
                local isKgKey = keyName and (string.find(string.lower(tostring(keyName)), "kg") ~= nil)
                if isKgKey or val < 50 then
                    return val * 1000
                else
                    return val
                end
            end
        elseif type(val) == "string" then
            local cleanTxt = string.gsub(val, "<[^>]+>", "")
            cleanTxt = string.gsub(cleanTxt, ",", ".")
            local w1 = string.match(cleanTxt, "(%d+%.?%d*)%s*[kK][gG]")
            if w1 then
                local n = tonumber(w1)
                if n and n > 0 then return n * 1000 end
            end
            local w2 = string.match(cleanTxt, "(%d+%.?%d*)%s*[gG]")
            if w2 then
                local n = tonumber(w2)
                if n and n > 0 then return (n < 50) and (n * 1000) or n end
            end
            local num = tonumber(cleanTxt)
            if num and num > 0 then return (num < 50) and (num * 1000) or num end
        end
        return 0
    end

    pcall(function()
        -- Build chain of search instances up to plot parent
        local searchObjs = {}
        local curr = item
        for _ = 1, 5 do
            if curr then
                table.insert(searchObjs, curr)
                curr = curr.Parent
            end
        end

        -- Method 1: Game Module Functions (Pre-cached)
        local mod = PlantSizeModuleCache
        if mod and type(mod) == "table" then
            if type(mod.getFruitWeight) == "function" then
                local res = mod.getFruitWeight(item)
                if type(res) == "number" and res > 0 then
                    maxW = (res < 50) and (res * 1000) or res
                end
            end
            if maxW <= 0 and type(mod.getPlantWeight) == "function" then
                local res = mod.getPlantWeight(item)
                if type(res) == "number" and res > 0 then
                    maxW = (res < 50) and (res * 1000) or res
                end
            end
            if maxW <= 0 and type(mod.GetPlantWeightAtLuck) == "function" then
                local res = mod.GetPlantWeightAtLuck(item)
                if type(res) == "number" and res > 0 then
                    maxW = (res < 50) and (res * 1000) or res
                end
            end
        end

        -- Method 2: Direct Attributes & Value Objects on item & parent hierarchy
        if maxW <= 0 then
            for _, obj in ipairs(searchObjs) do
                for attrKey, attrVal in pairs(obj:GetAttributes()) do
                    if isExplicitWeightKey(attrKey) then
                        local w = processVal(attrVal, attrKey)
                        if w > maxW then maxW = w end
                    end
                end

                for _, child in ipairs(obj:GetChildren()) do
                    if isExplicitWeightKey(child.Name) and (child:IsA("NumberValue") or child:IsA("IntValue") or child:IsA("StringValue")) then
                        local w = processVal(child.Value, child.Name)
                        if w > maxW then maxW = w end
                    end
                end
            end
        end

        -- Method 3: Model:GetScale() & Scale Attributes
        if maxW <= 0 then
            local cropName = (Scanner.GetPureCropName and Scanner.GetPureCropName(item)) or item.Name
            local seedData = GameData.Seeds[cropName]
            local baseWeightKg = (seedData and seedData.BaseWeight) or 0.80
            local baseWeightGrams = baseWeightKg * 1000

            for _, obj in ipairs(searchObjs) do
                if obj:IsA("Model") then
                    pcall(function()
                        if obj.GetScale then
                            local s = obj:GetScale()
                            if type(s) == "number" and s > 0 and s ~= 1 then
                                local calcW = baseWeightGrams * s
                                if calcW > maxW then maxW = calcW end
                            end
                        end
                    end)
                end

                for attrKey, attrVal in pairs(obj:GetAttributes()) do
                    if isScaleKey(attrKey) and type(attrVal) == "number" and attrVal > 0 then
                        local calcW = baseWeightGrams * attrVal
                        if calcW > maxW then maxW = calcW end
                    end
                end
            end
        end

        -- Method 4: All Descendants Attributes & Value Objects
        if maxW <= 0 then
            for _, desc in ipairs(item:GetDescendants()) do
                for attrKey, attrVal in pairs(desc:GetAttributes()) do
                    if isExplicitWeightKey(attrKey) then
                        local w = processVal(attrVal, attrKey)
                        if w > maxW then maxW = w end
                    elseif isScaleKey(attrKey) and type(attrVal) == "number" and attrVal > 0 then
                        local cropName = (Scanner.GetPureCropName and Scanner.GetPureCropName(item)) or item.Name
                        local seedData = GameData.Seeds[cropName]
                        local baseWeightGrams = ((seedData and seedData.BaseWeight) or 0.80) * 1000
                        local calcW = baseWeightGrams * attrVal
                        if calcW > maxW then maxW = calcW end
                    end
                end

                if (desc:IsA("NumberValue") or desc:IsA("IntValue") or desc:IsA("StringValue")) and isExplicitWeightKey(desc.Name) then
                    local w = processVal(desc.Value, desc.Name)
                    if w > maxW then maxW = w end
                end
            end
        end
    end)

    if maxW <= 0 then
        -- Default to BaseWeight from GameData.Seeds
        local cropName = (Scanner.GetPureCropName and Scanner.GetPureCropName(item)) or item.Name
        local seedData = GameData.Seeds[cropName]
        maxW = (seedData and seedData.BaseWeight and (seedData.BaseWeight * 1000)) or 800
    end

    persistentWeightCache[item] = maxW
    return maxW
end

function Scanner.ExtractItemWeight(item)
    return Scanner.CalculateItemWeight(item)
end


-- Get Pure Crop Name from plant/fruit
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

function Scanner.GetPureCropName(plant, fruit)
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

    local attrs = { "CropName", "PlantName", "DisplayName", "Species", "Crop", "SeedName", "Fruit", "FruitName", "Name" }
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

    local resolvedName = Scanner.ResolvePlantDetails(plant)
    if resolvedName and resolvedName ~= "Crop Plant" then
        pureCropNameCache[targetKey] = resolvedName
        return resolvedName
    end

    local result = (plant and plant.Name) or "Crop Plant"
    pureCropNameCache[targetKey] = result
    return result
end

-- Get Official Mutations of fruit instance
local officialMutationsCache = setmetatable({}, { __mode = "k" })

function Scanner.GetOfficialMutations(fruit)
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
                        if cName == exact or cName == exact .. "vfx" or cName == exact .. "mutation" or cName == exact .. "_mut" then
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
        local norm = Scanner.NormalizeMutationName(tostring(mutAttr))
        if norm and not addedSet[norm] then
            addedSet[norm] = true
            for _, mut in ipairs(MUTATION_DATA) do
                if mut.Name == norm then
                    table.insert(detectedMutations, mut)
                    break
                end
            end
        end
    end

    officialMutationsCache[fruit] = detectedMutations
    return detectedMutations
end

-- Get All Fruit Instances from Plant Model
function Scanner.GetAllFruitInstancesFromPlant(plantModel)
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

-- Extract Plant UUID from instance
function Scanner.ExtractPlantUUID(plantObj)
    if plantObj:GetAttribute("UUID") then return tostring(plantObj:GetAttribute("UUID")) end
    if plantObj:GetAttribute("PlantID") then return tostring(plantObj:GetAttribute("PlantID")) end
    if plantObj:GetAttribute("ID") then return tostring(plantObj:GetAttribute("ID")) end
    
    local match = plantObj.Name:match(UUID_PATTERN)
    if match then return match end
    
    local parent = plantObj.Parent
    while parent and parent ~= workspace do
        if parent:GetAttribute("UUID") then return tostring(parent:GetAttribute("UUID")) end
        local pMatch = parent.Name:match(UUID_PATTERN)
        if pMatch then return pMatch end
        parent = parent.Parent
    end
    
    return plantObj.Name
end

-- Extract TRUE numeric Fruit ID from instance
function Scanner.ExtractFruitId(fruitObj, parentPlantFolder)
    local attrs = { "FruitId", "FruitIndex", "Index", "ID", "Slot", "ProxyId" }
    for _, attrName in ipairs(attrs) do
        local val = fruitObj:GetAttribute(attrName)
        if val ~= nil then
            return tostring(val)
        end
    end
    
    if tonumber(fruitObj.Name) ~= nil or fruitObj.Name:match("^%d+$") then
        return fruitObj.Name
    end
    
    local digitsInName = fruitObj.Name:match("%d+")
    if digitsInName then
        return digitsInName
    end
    
    if parentPlantFolder then
        local children = parentPlantFolder:GetChildren()
        for idx, child in ipairs(children) do
            if child == fruitObj then
                return tostring(idx)
            end
        end
    end
    
    return "1"
end

-- Helper to strip base crop names from string to avoid false positive mutation matches
local function StripCropNames(str)
    if type(str) ~= "string" or #str == 0 then return "" end
    local lowerStr = str:lower()
    
    if GameData and GameData.Seeds then
        for cropName in pairs(GameData.Seeds) do
            local lowerCrop = cropName:lower()
            lowerStr = lowerStr:gsub(lowerCrop:gsub("(%W)", "%%%1"), "")
        end
    end
    
    lowerStr = lowerStr:gsub("fruit", ""):gsub("plant", ""):gsub("crop", ""):gsub("seed", ""):gsub("proxy", "")
    return lowerStr
end

-- ACCURATE FAIL-PROOF MUTATION EXTRACTION (COMBINES MULTI-METHOD SCANNING)
function Scanner.ExtractMutation(fruitObj, plantObj)
    local checkObjects = {}
    local added = {}
    
    local function addObj(obj)
        if obj and not added[obj] then
            added[obj] = true
            table.insert(checkObjects, obj)
        end
    end
    
    addObj(fruitObj)
    addObj(plantObj)
    if fruitObj then addObj(fruitObj.Parent) end
    if plantObj then addObj(plantObj.Parent) end
    
    local curr = fruitObj and fruitObj.Parent
    while curr and curr ~= workspace do
        addObj(curr)
        curr = curr.Parent
    end
    
    curr = plantObj and plantObj.Parent
    while curr and curr ~= workspace do
        addObj(curr)
        curr = curr.Parent
    end
    
    -- Method 1: String & Boolean Roblox Attributes (GetAttributes)
    for _, obj in ipairs(checkObjects) do
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if ok and attrs then
            for attrName, attrVal in pairs(attrs) do
                if type(attrVal) == "string" and #attrVal > 0 then
                    local norm = Scanner.NormalizeMutationName(attrVal)
                    if norm then return norm end
                elseif type(attrVal) == "boolean" and attrVal == true then
                    local norm = Scanner.NormalizeMutationName(attrName)
                    if norm then return norm end
                end
            end
        end
    end
    
    -- Method 2: Child Instances (StringValue, BoolValue, ValueObject, Folder, Model, Configuration, Particles, Effects)
    for _, obj in ipairs(checkObjects) do
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("StringValue") or child:IsA("ValueObject") then
                local val = tostring(child.Value or "")
                if #val > 0 then
                    local norm = Scanner.NormalizeMutationName(val)
                    if norm then return norm end
                end
                local normName = Scanner.NormalizeMutationName(child.Name)
                if normName then return normName end
            elseif child:IsA("BoolValue") and child.Value == true then
                local norm = Scanner.NormalizeMutationName(child.Name)
                if norm then return norm end
            else
                local norm = Scanner.NormalizeMutationName(child.Name)
                if norm then return norm end
                
                if child:IsA("ParticleEmitter") then
                    local tex = tostring(child.Texture):lower()
                    for alias, canonical in pairs(MUTATION_LOOKUP) do
                        if #alias >= 3 and tex:find(alias, 1, true) then
                            return canonical
                        end
                    end
                end
            end
        end
    end
    
    -- Method 3: CollectionService Tags
    for _, obj in ipairs(checkObjects) do
        local success, tags = pcall(function() return CollectionService:GetTags(obj) end)
        if success and tags then
            for _, tag in ipairs(tags) do
                local norm = Scanner.NormalizeMutationName(tag)
                if norm then return norm end
            end
        end
    end
    
    -- Method 4: Instance Names (Brackets, Parentheses, Suffixes, Prefixes)
    for _, obj in ipairs(checkObjects) do
        local name = obj.Name
        if type(name) == "string" and #name > 0 then
            local match = name:match("[%[%({](.-)[%]%)}]")
            if match then
                local norm = Scanner.NormalizeMutationName(match)
                if norm then return norm end
            end
            
            local strippedName = StripCropNames(name)
            local norm = Scanner.NormalizeMutationName(strippedName)
            if norm then return norm end
        end
    end
    
    -- Method 5: Check direct official mutations from child particles
    if fruitObj then
        local muts = Scanner.GetOfficialMutations(fruitObj)
        if #muts > 0 then
            return muts[1].Name
        end
    end
    
    -- Method 6: Fallback to plant model resolution
    if plantObj then
        local pName, pMut, pVar = Scanner.ResolvePlantDetails(plantObj)
        if pMut and pMut ~= "Normal" and pMut ~= "" then
            return pMut
        elseif pVar and pVar ~= "Normal" and pVar ~= "" then
            return pVar
        end
    end
    
    return nil
end

-- Extract Fruit Metadata
function Scanner.ExtractFruitData(plantObj, fruitObj, parentFolder)
    local plantUUID = Scanner.ExtractPlantUUID(plantObj)
    local fruitId = Scanner.ExtractFruitId(fruitObj, parentFolder)
    
    local pureName = Scanner.GetPureCropName(plantObj, fruitObj)
    local fruitName = (pureName ~= "Crop Plant" and pureName ~= "Model") and pureName or (
        fruitObj:GetAttribute("Fruit") 
        or fruitObj:GetAttribute("FruitName")
        or plantObj:GetAttribute("PlantName") 
        or plantObj:GetAttribute("SeedName")
        or plantObj.Name
    )
        
    local seedInfo = GameData.Seeds[fruitName]
    local baseGrams = (seedInfo and seedInfo.BaseWeight and (seedInfo.BaseWeight * 1000)) or 800
    local isSingleHarvest = (seedInfo and seedInfo.SingleHarvest == true) or (fruitObj == plantObj)

    local rawWeight = Scanner.ExtractItemWeight(fruitObj)
    local pWeight = Scanner.ExtractItemWeight(plantObj)
    if isSingleHarvest or rawWeight <= 0 or rawWeight == 100 or (rawWeight == baseGrams and pWeight > rawWeight) then
        if pWeight > 0 then rawWeight = pWeight end
    end
        
    local weightGrams = tonumber(rawWeight) or 100
    local weightKg = (weightGrams >= 50) and (weightGrams / 1000) or weightGrams
    
    local mutation = Scanner.ExtractMutation(fruitObj, plantObj)
    
    local seedInfo = GameData.Seeds[fruitName]
    local rarity = fruitObj:GetAttribute("Rarity")
        or (seedInfo and seedInfo.Rarity)
        or "Common"
        
    local readyAttr = fruitObj:GetAttribute("Ready")
    local readyAttr2 = fruitObj:GetAttribute("FullyGrown")
    local isFullyGrown = true
    if readyAttr ~= nil then isFullyGrown = readyAttr end
    if readyAttr2 ~= nil then isFullyGrown = readyAttr2 end
    if fruitObj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil then isFullyGrown = true end
    
    local estimatedValue = GameData.CalculateValue(fruitName, weightGrams, mutation)
    
    return {
        PlantUUID      = plantUUID,
        FruitId        = fruitId,
        FruitName      = fruitName,
        Weight         = weightGrams,
        WeightKg       = weightKg,
        FormattedWeight= GameData.FormatWeight(weightGrams),
        Mutation       = mutation,
        Rarity         = rarity,
        IsFullyGrown   = isFullyGrown,
        EstimatedValue = estimatedValue,
        PlantInstance  = plantObj,
        FruitInstance  = fruitObj,
    }
end

-- DETAILED GARDEN PLANT & FRUIT SCANNER ENGINE
local ScanCache = {
    LastScanTime = 0,
    CacheDuration = 10.0,
    PlantList = {},
    FruitList = {},
    TotalPlants = 0,
    TotalReadyFruits = 0,
    TotalUnreadyFruits = 0,
    TotalFruits = 0,
    MutationCounts = {},
    CropGroups = {},
    ActiveCrops = {}
}

local MasterGardenCache = {
    LastScanTime = 0,
    CacheDuration = 10.0,
    Crops = {},
}

function Scanner.InvalidateScanCache()
    ScanCache.LastScanTime = 0
    MasterGardenCache.LastScanTime = 0
    table.clear(persistentWeightCache)
    table.clear(officialMutationsCache)
    table.clear(plantDetailsCache)
    table.clear(pureCropNameCache)
end

function Scanner.FetchGardenPlants(forceRefresh)
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
            workspace:FindFirstChild("Gardens"),
            workspace:FindFirstChild("Plots"),
            workspace:FindFirstChild("_Gardens"),
            workspace:FindFirstChild("Farms"),
            workspace:FindFirstChild("Farm"),
            workspace:FindFirstChild("GardenPlots"),
            workspace:FindFirstChild("Garden"),
            workspace:FindFirstChild("MyPlot")
        }

        for _, folder in ipairs(gardenContainers) do
            if folder then
                for _, plot in ipairs(folder:GetChildren()) do
                    if Scanner.IsMyGardenPlot(plot) then
                        local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("CropFolder") or plot:FindFirstChild("Crops") or plot
                        if plantsFolder then
                            for _, plantModel in ipairs(plantsFolder:GetChildren()) do
                                if plantModel:IsA("Model") or plantModel:IsA("Folder") or plantModel:IsA("BasePart") then
                                    totalPlants = totalPlants + 1
                                    local realName, mutation, variant = Scanner.ResolvePlantDetails(plantModel)
                                    if variant and variant ~= "Normal" and (mutation == "Normal" or mutation == "") then
                                        mutation = variant
                                    end

                                    if realName and realName ~= "Crop Plant" and realName ~= "Model" and not activeCropSet[realName] then
                                        activeCropSet[realName] = true
                                        table.insert(activeCrops, realName)
                                    end

                                    local plantWeight = Scanner.ExtractItemWeight(plantModel)
                                    local fruitsOnPlant = Scanner.GetAllFruitInstancesFromPlant(plantModel)
                                    local totalOnPlant = #fruitsOnPlant

                                    local plantReadyCount = 0
                                    local plantUnreadyCount = 0
                                    local heaviestInPlant = plantWeight

                                    local plantWeightsList = {}
                                    for fIdx, fruitObj in ipairs(fruitsOnPlant) do
                                        local fCropName = Scanner.GetPureCropName(plantModel, fruitObj)
                                        if fCropName == "Crop Plant" or fCropName == "Model" then fCropName = realName end

                                        local fw = Scanner.ExtractItemWeight(fruitObj)
                                        local sInfo = GameData.Seeds[fCropName]
                                        local baseGrams = (sInfo and sInfo.BaseWeight and (sInfo.BaseWeight * 1000)) or 800
                                        local isSingleHarvest = (sInfo and sInfo.SingleHarvest == true) or (fruitObj == plantModel)

                                        if isSingleHarvest or fw <= 0 or fw == 100 or (fw == baseGrams and plantWeight > fw) then
                                            if plantWeight > 0 then fw = plantWeight end
                                        end
                                        if fw > heaviestInPlant then heaviestInPlant = fw end
                                        if fw > 0 then
                                            table.insert(plantWeightsList, fw)
                                        end

                                        local muts = Scanner.GetOfficialMutations(fruitObj)
                                        local fMutName = "Normal"
                                        if #muts > 0 then
                                            fMutName = muts[1].Name
                                        elseif mutation and mutation ~= "Normal" then
                                            fMutName = mutation
                                        else
                                            local extMut = Scanner.ExtractMutation(fruitObj, plantModel)
                                            if extMut then fMutName = extMut end
                                        end

                                        if fMutName and fMutName ~= "Normal" then
                                            mutationCounts[fMutName] = (mutationCounts[fMutName] or 0) + 1
                                        end

                                        local isReady = (fruitObj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil)
                                        if not isReady and fruitObj == plantModel then
                                            isReady = (plantModel:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil)
                                        end

                                        if isReady then
                                            plantReadyCount = plantReadyCount + 1
                                        else
                                            plantUnreadyCount = plantUnreadyCount + 1
                                        end

                                        local fruitPos = fruitObj:IsA("BasePart") and fruitObj.Position or (plantModel:IsA("Model") and plantModel:GetPivot().Position)
                                        local seedInfo = GameData.Seeds[fCropName]
                                        local cropRarity = (seedInfo and seedInfo.Rarity) or "Common"

                                        table.insert(fruitList, {
                                            Plot = plot.Name,
                                            PlantName = realName,
                                            CropName = fCropName,
                                            FruitIndex = fIdx,
                                            TotalOnPlant = totalOnPlant,
                                            Position = fruitPos,
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

                                    local seedInfo = GameData.Seeds[realName]
                                    local cropRarity = (seedInfo and seedInfo.Rarity) or "Common"
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

-- MASTER GARDEN CROPS CACHE ENGINE (SINGLE UNIFIED SCANNER)
function Scanner.GetMasterGardenCrops(forceRefresh)
    local now = tick()
    if not forceRefresh and MasterGardenCache.Crops and #MasterGardenCache.Crops > 0 and (now - MasterGardenCache.LastScanTime < MasterGardenCache.CacheDuration) then
        return MasterGardenCache.Crops
    end

    local rawList = {}
    local scannedKeys = {}
    local _, _, _, _, _, _, _, fruitList = Scanner.FetchGardenPlants(true)
    
    for _, fData in ipairs(fruitList) do
        local plantUUID = Scanner.ExtractPlantUUID(fData.PlantModel)
        local fruitId = Scanner.ExtractFruitId(fData.FruitInstance)
        local key = plantUUID .. "_" .. fruitId
        
        if not scannedKeys[key] then
            scannedKeys[key] = true
            local mutName = (fData.MutationName and fData.MutationName ~= "Normal") and fData.MutationName or nil
            local weightGrams = fData.Weight or 100
            local weightKg = weightGrams / 1000
            local estimatedValue = GameData.CalculateValue(fData.CropName, weightGrams, mutName)
            
            table.insert(rawList, {
                PlantUUID       = plantUUID,
                FruitId         = fruitId,
                FruitName       = fData.CropName,
                Weight          = weightGrams,
                WeightKg        = weightKg,
                FormattedWeight = GameData.FormatWeight(weightGrams),
                Mutation        = mutName,
                Rarity          = fData.Rarity,
                IsFullyGrown    = fData.IsReady,
                EstimatedValue  = estimatedValue,
                PlantInstance   = fData.PlantModel,
                FruitInstance   = fData.FruitInstance,
                PlantModel      = fData.PlantModel,
                FruitObj        = fData.FruitInstance,
                Position        = fData.Position or (fData.FruitInstance and fData.FruitInstance:IsA("BasePart") and fData.FruitInstance.Position) or (fData.PlantModel and fData.PlantModel:IsA("Model") and fData.PlantModel:GetPivot().Position) or Vector3.zero,
            })
        end
    end

    MasterGardenCache.Crops = rawList
    MasterGardenCache.LastScanTime = now
    return rawList
end

-- Scan ALL crops in the garden without filters to get true plot state & farm details
function Scanner.GetAllGardenCropsRaw(forceRefresh)
    return Scanner.GetMasterGardenCrops(forceRefresh or false)
end

-- Scan for harvestable fruits reading directly from Master Cache (ZERO LAG)
function Scanner.GetHarvestableFruits(forceRefresh)
    local harvestList = {}
    local rawCrops = Scanner.GetMasterGardenCrops(forceRefresh or false)
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local playerPos = hrp and hrp.Position
    
    for _, fData in ipairs(rawCrops) do
        local fruitPos = fData.Position
        local distance = (playerPos and fruitPos) and (playerPos - fruitPos).Magnitude or 0
        local mutName = fData.Mutation
        local weightKg = fData.WeightKg
        
        local cropData = {
            PlantUUID       = fData.PlantUUID,
            FruitId         = fData.FruitId,
            FruitName       = fData.FruitName,
            Weight          = fData.Weight,
            WeightKg        = weightKg,
            FormattedWeight = fData.FormattedWeight,
            Mutation        = mutName,
            Rarity          = fData.Rarity,
            IsFullyGrown    = fData.IsFullyGrown,
            EstimatedValue  = fData.EstimatedValue,
            PlantInstance   = fData.PlantModel,
            FruitInstance   = fData.FruitObj,
            Distance        = distance,
        }
        
        -- FILTER EVALUATION
        local passFilter = true
        
        -- 1. Distance Filter
        if distance > Config.HarvestDistance then passFilter = false end
        
        -- 2. Fully Grown Filter
        if Config.OnlyFullyGrown and not fData.IsFullyGrown then passFilter = false end
        
        -- 3. Crop Whitelist Filter
        if Config.CropFilterEnabled and Config.CropWhitelist[fData.FruitName] == false then passFilter = false end
        
        -- 4. Mutation Filter
        if Config.FilterMutationsOnly and not mutName then passFilter = false end
        if Config.MutationFilterEnabled then
            local mutKey = mutName or "Normal"
            local isWhitelisted = false
            for whitelistName, enabled in pairs(Config.MutationWhitelist) do
                if enabled then
                    local normW = Scanner.NormalizeMutationName(whitelistName) or whitelistName
                    local normM = Scanner.NormalizeMutationName(mutKey) or mutKey
                    if normW:lower() == normM:lower() or whitelistName:lower() == mutKey:lower() then
                        isWhitelisted = true; break
                    end
                end
            end
            if not isWhitelisted then passFilter = false end
        end
        
        -- 5. Weight Filters
        if Config.WeightFilterAboveEnabled and weightKg < Config.WeightAboveKg then passFilter = false end
        if Config.WeightFilterBelowEnabled and weightKg > Config.WeightBelowKg then passFilter = false end
        
        if passFilter then
            table.insert(harvestList, cropData)
        end
    end
    
    return harvestList
end

-- ==========================================
-- FETCH GARDEN MAIN FUNCTION
-- ==========================================
local function FetchGarden()
    local rawCrops = Scanner.GetAllGardenCropsRaw()
    local filteredFruits = Scanner.GetHarvestableFruits()
    
    print("\n==========================================")
    print("        🌱 GARDEN FETCH RESULTS           ")
    print("==========================================")
    print(string.format("Total Garden Crops in Plot: %d", #rawCrops))
    print(string.format("Total Crops Passing Active Filters: %d", #filteredFruits))
    
    -- Print Mutated Crops Detected
    local mutatedList = {}
    for _, crop in ipairs(rawCrops) do
        if crop.Mutation then
            table.insert(mutatedList, crop)
        end
    end
    
    print(string.format("\n✨ Mutated Crops Detected in Plot: %d crops", #mutatedList))
    if #mutatedList == 0 then
        print("  - None (No mutated crops found in plot)")
    else
        for idx, mCrop in ipairs(mutatedList) do
            print(string.format("  [%d] %s [MUTATION: %s] (%.2f kg) | UUID: %s... | FruitID: %s",
                idx, mCrop.FruitName, mCrop.Mutation, mCrop.WeightKg, string.sub(mCrop.PlantUUID, 1, 8), mCrop.FruitId))
        end
    end
    print("------------------------------------------")
    
    if #filteredFruits == 0 then
        print("⚠️ No crops detected matching active filter criteria.")
        print("Tips: Check filter settings in GUI Settings Tab.")
        print("==========================================\n")
        return filteredFruits
    end
    
    local summary = {}
    local totalEstVal = 0
    local totalWeight = 0
    
    for idx, f in ipairs(filteredFruits) do
        totalEstVal = totalEstVal + (f.EstimatedValue or 0)
        totalWeight = totalWeight + (f.Weight or 0)
        
        local mutStr = f.Mutation and string.format(" [MUTATION: %s]", f.Mutation) or ""
        print(string.format("[%d] %s (%s - %.2f kg)%s | Tier: %s | Est: %d Sheckles | UUID: %s... | FruitID: %s",
            idx, f.FruitName, f.FormattedWeight, f.WeightKg, mutStr, f.Rarity, f.EstimatedValue, string.sub(f.PlantUUID, 1, 8), f.FruitId))
            
        summary[f.FruitName] = (summary[f.FruitName] or 0) + 1
    end
    
    print("------------------------------------------")
    print("Filtered Garden Crops Summary:")
    for cropName, qty in pairs(summary) do
        print(string.format("  - %s: %d crops", cropName, qty))
    end
    print(string.format("Total Weight: %s", GameData.FormatWeight(totalWeight)))
    print(string.format("Total Value: %d Sheckles", totalEstVal))
    print("==========================================\n")
    
    return filteredFruits
end

Scanner.FetchGarden = FetchGarden
_G.FetchGarden = FetchGarden
if getgenv then
    getgenv().FetchGarden = FetchGarden
end

-- ==========================================
-- 5. AUTO HARVEST ENGINE & STATS
-- ==========================================
local Engine = {
    IsRunning = false,
    Stats = {
        TotalHarvested = 0,
        TotalWeightGrams = 0,
        TotalEstimatedValue = 0,
        MutationsCount = 0,
        FruitBreakdown = {},
        RecentLogs = {},
    },
    OnHarvestEvent = Instance.new("BindableEvent")
}

function Engine.RecordHarvest(fruitData)
    Engine.Stats.TotalHarvested = Engine.Stats.TotalHarvested + 1
    Engine.Stats.TotalWeightGrams = Engine.Stats.TotalWeightGrams + (fruitData.Weight or 0)
    Engine.Stats.TotalEstimatedValue = Engine.Stats.TotalEstimatedValue + (fruitData.EstimatedValue or 0)
    
    if fruitData.Mutation then
        Engine.Stats.MutationsCount = Engine.Stats.MutationsCount + 1
    end
    
    local name = fruitData.FruitName
    Engine.Stats.FruitBreakdown[name] = (Engine.Stats.FruitBreakdown[name] or 0) + 1
    
    local timestamp = os.date("%H:%M:%S")
    local mutText = fruitData.Mutation and string.format(" [%s]", fruitData.Mutation) or ""
    local logMsg = string.format("[%s] Harvested %s (%s)%s", timestamp, fruitData.FruitName, fruitData.FormattedWeight, mutText)
    
    table.insert(Engine.Stats.RecentLogs, 1, logMsg)
    if #Engine.Stats.RecentLogs > 30 then
        table.remove(Engine.Stats.RecentLogs)
    end
    
    Engine.OnHarvestEvent:Fire(fruitData, logMsg)
end

function Engine.HarvestSingle(fruitData)
    local success = Network.SendHarvest(fruitData.PlantUUID, fruitData.FruitId)
    if success then
        Engine.RecordHarvest(fruitData)
        if Config.NotifyHarvest then
            print(string.format("[AUTO HARVEST] %s (%s) - UUID: %s | FruitID: %s", fruitData.FruitName, fruitData.FormattedWeight, fruitData.PlantUUID, fruitData.FruitId))
        end
    end
    return success
end

function Engine.HarvestAllNow()
    local fruits = Scanner.GetHarvestableFruits()
    print(string.format("[HarvestAllNow] Found %d crops ready to harvest.", #fruits))
    local count = 0
    for _, fruitData in ipairs(fruits) do
        if Engine.HarvestSingle(fruitData) then
            count = count + 1
        end
    end
    return count
end

function Engine.Start()
    if Engine.IsRunning then return end
    Engine.IsRunning = true
    print("[AutoHarvest Engine] Status: ON (Active)")
    
    task.spawn(function()
        while Engine.IsRunning and Config.AutoHarvest do
            local fruits = Scanner.GetHarvestableFruits()
            for _, fruitData in ipairs(fruits) do
                if not Engine.IsRunning or not Config.AutoHarvest then break end
                Engine.HarvestSingle(fruitData)
                task.wait(0.05)
            end
            task.wait(Config.HarvestInterval)
        end
        Engine.IsRunning = false
        print("[AutoHarvest Engine] Status: OFF (Stopped)")
    end)
end

function Engine.Stop()
    Engine.IsRunning = false
    Config.AutoHarvest = false
    print("[AutoHarvest Engine] Status: OFF (Stopped)")
end

-- ==========================================
-- 6. EVENT-DRIVEN FRUIT ESP ENGINE (ZERO STUTTER, ZERO LOOPS)
-- ==========================================
local ESPManager = {
    ActiveBillboards = {},
    EspFolder = nil,
    Connections = {},
}

function ESPManager.InitFolder()
    if ESPManager.EspFolder and ESPManager.EspFolder.Parent then return end
    local parentObj = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    local existing = parentObj:FindFirstChild("GAG2_FruitESP")
    if existing then existing:Destroy() end
    
    local folder = Instance.new("Folder")
    folder.Name = "GAG2_FruitESP"
    folder.Parent = parentObj
    ESPManager.EspFolder = folder
end

function ESPManager.ClearAll()
    for obj, bb in pairs(ESPManager.ActiveBillboards) do
        if bb then pcall(function() bb:Destroy() end) end
    end
    ESPManager.ActiveBillboards = {}
    for _, conn in ipairs(ESPManager.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    ESPManager.Connections = {}
end

function ESPManager.CreateTagForTarget(targetObj, fData)
    if not targetObj or not targetObj.Parent then return end
    if ESPManager.ActiveBillboards[targetObj] then return end

    -- Filter checks
    local passReady = (not Config.EspOnlyReady) or fData.IsFullyGrown
    local passMut = (not Config.EspOnlyMutated) or (fData.Mutation ~= nil)
    if not (passReady and passMut) then return end

    ESPManager.InitFolder()

    local bb = Instance.new("BillboardGui")
    bb.Name = "FruitESP_" .. (fData.FruitName or "Crop")
    bb.Size = UDim2.new(0, 165, 0, 46)
    bb.AlwaysOnTop = true
    bb.ExtentsOffset = Vector3.new(0, 2.5, 0)

    local adorneeObj = targetObj
    if targetObj:IsA("Model") then
        adorneeObj = targetObj.PrimaryPart or targetObj:FindFirstChildWhichIsA("BasePart", true) or targetObj
    end
    bb.Adornee = adorneeObj

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    card.BackgroundTransparency = 0.3
    card.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Thickness = 1.5
    stroke.Parent = card

    local tTitle = Instance.new("TextLabel")
    tTitle.Name = "Title"
    tTitle.Size = UDim2.new(1, -8, 0, 20)
    tTitle.Position = UDim2.new(0, 4, 0, 3)
    tTitle.BackgroundTransparency = 1
    tTitle.TextSize = 11
    tTitle.Font = Enum.Font.GothamBold
    tTitle.TextXAlignment = Enum.TextXAlignment.Center
    tTitle.Parent = card

    local tSub = Instance.new("TextLabel")
    tSub.Name = "SubTitle"
    tSub.Size = UDim2.new(1, -8, 0, 18)
    tSub.Position = UDim2.new(0, 4, 0, 23)
    tSub.BackgroundTransparency = 1
    tSub.TextColor3 = Color3.fromRGB(220, 225, 235)
    tSub.TextSize = 10
    tSub.Font = Enum.Font.GothamMedium
    tSub.TextXAlignment = Enum.TextXAlignment.Center
    tSub.Parent = card

    local mutInfo = fData.Mutation and GameData.Mutations[fData.Mutation]
    local themeColor = mutInfo and mutInfo.Color or (fData.IsFullyGrown and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(230, 126, 34))

    stroke.Color = themeColor
    tTitle.TextColor3 = themeColor

    if Config.EspShowMutation and fData.Mutation then
        local multVal = mutInfo and mutInfo.Multiplier or 1
        tTitle.Text = string.format("✨ [%s] %s (%dx)", fData.Mutation, fData.FruitName, multVal)
    else
        tTitle.Text = string.format("🌱 %s %s", fData.FruitName, fData.IsFullyGrown and "✓" or "⌛")
    end

    local weightStr = Config.EspShowWeight and ("⚖ " .. fData.FormattedWeight) or ""
    tSub.Text = weightStr

    bb.Parent = ESPManager.EspFolder
    ESPManager.ActiveBillboards[targetObj] = bb
end

function ESPManager.RemoveTagForTarget(targetObj)
    local bb = ESPManager.ActiveBillboards[targetObj]
    if bb then
        pcall(function() bb:Destroy() end)
        ESPManager.ActiveBillboards[targetObj] = nil
    end
end

function ESPManager.RefreshAll()
    ESPManager.ClearAll()
    if not Config.EspEnabled then return end

    -- 1. Initial Pass over current plot crops
    local rawCrops = Scanner.GetMasterGardenCrops(true)
    for _, crop in ipairs(rawCrops) do
        local targetObj = crop.FruitObj or crop.FruitInstance or crop.PlantModel or crop.PlantInstance
        ESPManager.CreateTagForTarget(targetObj, crop)
    end

    -- 2. Event Listener Setup (Zero CPU Polling!)
    local plot = Scanner.GetPlayerPlot()
    if plot then
        local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("CropFolder") or plot:FindFirstChild("Crops") or plot
        
        -- Listen when new crop grows / is planted
        local connAdd = plantsFolder.ChildAdded:Connect(function(child)
            task.wait(0.2) -- Brief pause to allow crop attributes to replicate
            local freshCrops = Scanner.GetMasterGardenCrops(true)
            for _, crop in ipairs(freshCrops) do
                local targetObj = crop.FruitObj or crop.FruitInstance or crop.PlantModel or crop.PlantInstance
                if targetObj == child or (targetObj and targetObj:IsDescendantOf(child)) then
                    ESPManager.CreateTagForTarget(targetObj, crop)
                end
            end
        end)
        table.insert(ESPManager.Connections, connAdd)

        -- Listen when crop is harvested / removed
        local connRem = plantsFolder.ChildRemoved:Connect(function(child)
            ESPManager.RemoveTagForTarget(child)
            for targetObj, _ in pairs(ESPManager.ActiveBillboards) do
                if not targetObj or not targetObj.Parent or targetObj:IsDescendantOf(child) then
                    ESPManager.RemoveTagForTarget(targetObj)
                end
            end
        end)
        table.insert(ESPManager.Connections, connRem)
    end
end

function ESPManager.UpdateESP()
    ESPManager.RefreshAll()
end

function ESPManager.StartLoop()
    -- Event-Driven architecture replaces loops
end

function ESPManager.StopLoop()
    ESPManager.ClearAll()
end

-- ==========================================
-- 7. MODERN GRAPHICAL USER INTERFACE (GUI IN ENGLISH)
-- ==========================================
local GUI = {}

function GUI.Build()
    local guiName = "GAG2_Harvest_GUI"
    local parentObj = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    if parentObj:FindFirstChild(guiName) then
        parentObj[guiName]:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = parentObj
    
    local C_BG = Color3.fromRGB(20, 22, 30)
    local C_SIDEBAR = Color3.fromRGB(26, 28, 38)
    local C_CARD = Color3.fromRGB(32, 36, 50)
    local C_ACCENT = Color3.fromRGB(99, 102, 241)
    local C_GREEN = Color3.fromRGB(46, 204, 113)
    local C_RED = Color3.fromRGB(231, 76, 60)
    local C_TEXT = Color3.fromRGB(240, 242, 250)
    local C_SUBTEXT = Color3.fromRGB(150, 155, 175)
    local C_STROKE = Color3.fromRGB(50, 55, 75)
    
    -- Main Window
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 710, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -355, 0.5, -230)
    MainFrame.BackgroundColor3 = C_BG
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = C_STROKE
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame
    
    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = C_SIDEBAR
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0, 300, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🌱 GAG2 Auto Harvest"
    TitleText.TextColor3 = C_TEXT
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(0, 200, 1, 0)
    SubTitle.Position = UDim2.new(0, 185, 0, 0)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "| Status: Default OFF"
    SubTitle.TextColor3 = C_SUBTEXT
    SubTitle.TextSize = 13
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.Parent = TitleBar
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -38, 0, 7.5)
    CloseBtn.BackgroundColor3 = C_RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = C_TEXT
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        Engine.Stop()
        ScreenGui:Destroy()
    end)
    
    -- Sidebar Navigation
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 160, 1, -45)
    Sidebar.Position = UDim2.new(0, 0, 0, 45)
    Sidebar.BackgroundColor3 = C_SIDEBAR
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    
    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 6)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = Sidebar
    
    local NavPadding = Instance.new("UIPadding")
    NavPadding.PaddingTop = UDim.new(0, 12)
    NavPadding.PaddingLeft = UDim.new(0, 10)
    NavPadding.PaddingRight = UDim.new(0, 10)
    NavPadding.Parent = Sidebar
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -165, 1, -50)
    Container.Position = UDim2.new(0, 165, 0, 50)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame
    
    local tabs = {}
    local tabButtons = {}
    
    local function SwitchTab(tabName)
        for name, page in pairs(tabs) do
            page.Visible = (name == tabName)
        end
        for name, btn in pairs(tabButtons) do
            if name == tabName then
                btn.BackgroundColor3 = C_ACCENT
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = C_CARD
                btn.TextColor3 = C_SUBTEXT
            end
        end
    end
    
    local function CreateNavButton(name, icon, text, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = (order == 1 and C_ACCENT or C_CARD)
        btn.Text = "  " .. icon .. "  " .. text
        btn.TextColor3 = (order == 1 and Color3.fromRGB(255, 255, 255) or C_SUBTEXT)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = order
        btn.Parent = Sidebar
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            SwitchTab(name)
        end)
        
        tabButtons[name] = btn
        return btn
    end
    
    CreateNavButton("Dashboard", "📊", "Dashboard", 1)
    CreateNavButton("FarmDetails", "🏡", "Farm Details", 2)
    CreateNavButton("Settings", "⚙️", "Settings", 3)
    CreateNavButton("Inspector", "🔍", "Crop Inspector", 4)
    CreateNavButton("ESP", "👁️", "Fruit ESP", 5)
    
    -- PAGE 1: DASHBOARD
    local DashboardPage = Instance.new("Frame")
    DashboardPage.Size = UDim2.new(1, -10, 1, 0)
    DashboardPage.BackgroundTransparency = 1
    DashboardPage.Visible = true
    DashboardPage.Parent = Container
    tabs["Dashboard"] = DashboardPage
    
    local function CreateStatCard(title, defaultVal, color, x, y)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0.48, 0, 0, 70)
        card.Position = UDim2.new(x, 0, y, 0)
        card.BackgroundColor3 = C_CARD
        card.Parent = DashboardPage
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = card
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = C_STROKE
        stroke.Parent = card
        
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -15, 0, 20)
        titleLbl.Position = UDim2.new(0, 12, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = C_SUBTEXT
        titleLbl.TextSize = 11
        titleLbl.Font = Enum.Font.Gotham
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = card
        
        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(1, -15, 0, 30)
        valLbl.Position = UDim2.new(0, 12, 0, 28)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = defaultVal
        valLbl.TextColor3 = color
        valLbl.TextSize = 17
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextXAlignment = Enum.TextXAlignment.Left
        valLbl.Parent = card
        
        return valLbl
    end
    
    local StatHarvested = CreateStatCard("Total Harvested", "0 crops", C_TEXT, 0, 0)
    local StatWeight = CreateStatCard("Total Harvest Weight", "0.00 g", C_GREEN, 0.52, 0)
    local StatValue = CreateStatCard("Total Value (Sheckles)", "0", Color3.fromRGB(241, 196, 15), 0, 0.22)
    local StatMutations = CreateStatCard("Mutations Found", "0", Color3.fromRGB(155, 89, 182), 0.52, 0.22)
    
    local ActionFrame = Instance.new("Frame")
    ActionFrame.Size = UDim2.new(1, 0, 0, 36)
    ActionFrame.Position = UDim2.new(0, 0, 0.44, 0)
    ActionFrame.BackgroundTransparency = 1
    ActionFrame.Parent = DashboardPage
    
    local FetchGardenBtn = Instance.new("TextButton")
    FetchGardenBtn.Size = UDim2.new(0.48, 0, 1, 0)
    FetchGardenBtn.Position = UDim2.new(0, 0, 0, 0)
    FetchGardenBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    FetchGardenBtn.Text = "🌱 FETCH MY GARDEN"
    FetchGardenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FetchGardenBtn.TextSize = 12
    FetchGardenBtn.Font = Enum.Font.GothamBold
    FetchGardenBtn.Parent = ActionFrame
    
    local FetchCorner = Instance.new("UICorner")
    FetchCorner.CornerRadius = UDim.new(0, 8)
    FetchCorner.Parent = FetchGardenBtn
    
    local HarvestNowBtn = Instance.new("TextButton")
    HarvestNowBtn.Size = UDim2.new(0.48, 0, 1, 0)
    HarvestNowBtn.Position = UDim2.new(0.52, 0, 0, 0)
    HarvestNowBtn.BackgroundColor3 = C_ACCENT
    HarvestNowBtn.Text = "⚡ HARVEST ALL CROPS NOW"
    HarvestNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    HarvestNowBtn.TextSize = 12
    HarvestNowBtn.Font = Enum.Font.GothamBold
    HarvestNowBtn.Parent = ActionFrame
    
    local HarvestCorner = Instance.new("UICorner")
    HarvestCorner.CornerRadius = UDim.new(0, 8)
    HarvestCorner.Parent = HarvestNowBtn
    
    local LogTitle = Instance.new("TextLabel")
    LogTitle.Size = UDim2.new(1, 0, 0, 20)
    LogTitle.Position = UDim2.new(0, 0, 0.56, 0)
    LogTitle.BackgroundTransparency = 1
    LogTitle.Text = "📜 Harvest & Garden Activity Logs:"
    LogTitle.TextColor3 = C_TEXT
    LogTitle.TextSize = 12
    LogTitle.Font = Enum.Font.GothamMedium
    LogTitle.TextXAlignment = Enum.TextXAlignment.Left
    LogTitle.Parent = DashboardPage
    
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Size = UDim2.new(1, 0, 0.38, 0)
    LogFrame.Position = UDim2.new(0, 0, 0.62, 0)
    LogFrame.BackgroundColor3 = C_CARD
    LogFrame.BorderSizePixel = 0
    LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogFrame.ScrollBarThickness = 4
    LogFrame.Parent = DashboardPage
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 8)
    LogCorner.Parent = LogFrame
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Padding = UDim.new(0, 4)
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Parent = LogFrame
    
    local LogPadding = Instance.new("UIPadding")
    LogPadding.PaddingTop = UDim.new(0, 6)
    LogPadding.PaddingLeft = UDim.new(0, 8)
    LogPadding.PaddingRight = UDim.new(0, 8)
    LogPadding.Parent = LogFrame
    
    local function AddLogItem(text, color)
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(1, 0, 0, 18)
        item.BackgroundTransparency = 1
        item.Text = text
        item.TextColor3 = color or C_SUBTEXT
        item.TextSize = 11
        item.Font = Enum.Font.Code
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Parent = LogFrame
    end
    
    -- PAGE 2: FARM DETAILS TAB
    local FarmDetailsPage = Instance.new("ScrollingFrame")
    FarmDetailsPage.Size = UDim2.new(1, -10, 1, 0)
    FarmDetailsPage.BackgroundTransparency = 1
    FarmDetailsPage.Visible = false
    FarmDetailsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    FarmDetailsPage.ScrollBarThickness = 4
    FarmDetailsPage.Parent = Container
    tabs["FarmDetails"] = FarmDetailsPage
    
    local FarmLayout = Instance.new("UIListLayout")
    FarmLayout.Padding = UDim.new(0, 10)
    FarmLayout.Parent = FarmDetailsPage
    
    local function BuildFarmDetailsPage()
        for _, child in ipairs(FarmDetailsPage:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        
        local rawCrops = Scanner.GetAllGardenCropsRaw()
        
        local plantCounts = {}
        local readyCount = 0
        local notReadyCount = 0
        local mutatedCrops = {}
        local mutCounts = {}
        
        for _, crop in ipairs(rawCrops) do
            plantCounts[crop.FruitName] = (plantCounts[crop.FruitName] or 0) + 1
            
            if crop.IsFullyGrown then
                readyCount = readyCount + 1
            else
                notReadyCount = notReadyCount + 1
            end
            
            if crop.Mutation then
                table.insert(mutatedCrops, crop)
                mutCounts[crop.Mutation] = (mutCounts[crop.Mutation] or 0) + 1
            end
        end
        
        -- SECTION 1: STAT CARDS
        local StatsBox = Instance.new("Frame")
        StatsBox.Size = UDim2.new(1, 0, 0, 68)
        StatsBox.BackgroundTransparency = 1
        StatsBox.Parent = FarmDetailsPage
        
        local function AddMiniCard(title, valText, color, widthScale, xPos)
            local card = Instance.new("Frame")
            card.Size = UDim2.new(widthScale, -5, 1, 0)
            card.Position = UDim2.new(xPos, 0, 0, 0)
            card.BackgroundColor3 = C_CARD
            card.Parent = StatsBox
            
            local cCorn = Instance.new("UICorner")
            cCorn.CornerRadius = UDim.new(0, 8)
            cCorn.Parent = card
            
            local cStr = Instance.new("UIStroke")
            cStr.Color = C_STROKE
            cStr.Parent = card
            
            local tLabel = Instance.new("TextLabel")
            tLabel.Size = UDim2.new(1, -12, 0, 18)
            tLabel.Position = UDim2.new(0, 8, 0, 6)
            tLabel.BackgroundTransparency = 1
            tLabel.Text = title
            tLabel.TextColor3 = C_SUBTEXT
            tLabel.TextSize = 10
            tLabel.Font = Enum.Font.Gotham
            tLabel.TextXAlignment = Enum.TextXAlignment.Left
            tLabel.Parent = card
            
            local vLabel = Instance.new("TextLabel")
            vLabel.Size = UDim2.new(1, -12, 0, 30)
            vLabel.Position = UDim2.new(0, 8, 0, 26)
            vLabel.BackgroundTransparency = 1
            vLabel.Text = valText
            vLabel.TextColor3 = color
            vLabel.TextSize = 16
            vLabel.Font = Enum.Font.GothamBold
            vLabel.TextXAlignment = Enum.TextXAlignment.Left
            vLabel.Parent = card
        end
        
        AddMiniCard("Ready to Harvest", tostring(readyCount) .. " crops", C_GREEN, 0.33, 0)
        AddMiniCard("Not Ready (Growing)", tostring(notReadyCount) .. " crops", Color3.fromRGB(230, 126, 34), 0.33, 0.335)
        AddMiniCard("Mutated Crops", tostring(#mutatedCrops) .. " crops", Color3.fromRGB(155, 89, 182), 0.33, 0.67)
        
        -- SECTION 2: PLANT SUMMARY BREAKDOWN (Crops in Plot)
        local PlantBox = Instance.new("Frame")
        PlantBox.Size = UDim2.new(1, 0, 0, 110)
        PlantBox.BackgroundColor3 = C_CARD
        PlantBox.Parent = FarmDetailsPage
        
        local pbCorner = Instance.new("UICorner")
        pbCorner.CornerRadius = UDim.new(0, 8)
        pbCorner.Parent = PlantBox
        
        local pbStroke = Instance.new("UIStroke")
        pbStroke.Color = C_STROKE
        pbStroke.Parent = PlantBox
        
        local pbTitle = Instance.new("TextLabel")
        pbTitle.Size = UDim2.new(1, -16, 0, 24)
        pbTitle.Position = UDim2.new(0, 10, 0, 6)
        pbTitle.BackgroundTransparency = 1
        pbTitle.Text = "🌱 Garden Plants Breakdown:"
        pbTitle.TextColor3 = C_TEXT
        pbTitle.TextSize = 12
        pbTitle.Font = Enum.Font.GothamBold
        pbTitle.TextXAlignment = Enum.TextXAlignment.Left
        pbTitle.Parent = PlantBox
        
        local pbScroll = Instance.new("ScrollingFrame")
        pbScroll.Size = UDim2.new(1, -20, 0, 68)
        pbScroll.Position = UDim2.new(0, 10, 0, 32)
        pbScroll.BackgroundTransparency = 1
        pbScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        pbScroll.ScrollBarThickness = 4
        pbScroll.Parent = PlantBox
        
        local pbGrid = Instance.new("UIGridLayout")
        pbGrid.CellSize = UDim2.new(0.31, 0, 0, 24)
        pbGrid.CellPadding = UDim2.new(0.02, 0, 0, 4)
        pbGrid.SortOrder = Enum.SortOrder.Name
        pbGrid.Parent = pbScroll
        
        for pName, count in pairs(plantCounts) do
            local pill = Instance.new("Frame")
            pill.Name = pName
            pill.BackgroundColor3 = C_SIDEBAR
            pill.Parent = pbScroll
            
            local pCorn = Instance.new("UICorner")
            pCorn.CornerRadius = UDim.new(0, 4)
            pCorn.Parent = pill
            
            local pText = Instance.new("TextLabel")
            pText.Size = UDim2.new(1, 0, 1, 0)
            pText.BackgroundTransparency = 1
            pText.Text = string.format("  %s: x%d", pName, count)
            pText.TextColor3 = C_TEXT
            pText.TextSize = 11
            pText.Font = Enum.Font.GothamMedium
            pText.TextXAlignment = Enum.TextXAlignment.Left
            pText.Parent = pill
        end
        
        -- SECTION 3: MUTATIONS DETECTED SUMMARY
        local MutBox = Instance.new("Frame")
        MutBox.Size = UDim2.new(1, 0, 0, 80)
        MutBox.BackgroundColor3 = C_CARD
        MutBox.Parent = FarmDetailsPage
        
        local mbCorner = Instance.new("UICorner")
        mbCorner.CornerRadius = UDim.new(0, 8)
        mbCorner.Parent = MutBox
        
        local mbStroke = Instance.new("UIStroke")
        mbStroke.Color = C_STROKE
        mbStroke.Parent = MutBox
        
        local mbTitle = Instance.new("TextLabel")
        mbTitle.Size = UDim2.new(1, -16, 0, 24)
        mbTitle.Position = UDim2.new(0, 10, 0, 6)
        mbTitle.BackgroundTransparency = 1
        mbTitle.Text = string.format("✨ Mutations Summary in Garden (%d Mutated Crops):", #mutatedCrops)
        mbTitle.TextColor3 = Color3.fromRGB(241, 196, 15)
        mbTitle.TextSize = 12
        mbTitle.Font = Enum.Font.GothamBold
        mbTitle.TextXAlignment = Enum.TextXAlignment.Left
        mbTitle.Parent = MutBox
        
        local mbScroll = Instance.new("ScrollingFrame")
        mbScroll.Size = UDim2.new(1, -20, 0, 40)
        mbScroll.Position = UDim2.new(0, 10, 0, 32)
        mbScroll.BackgroundTransparency = 1
        mbScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
        mbScroll.ScrollBarThickness = 2
        mbScroll.Parent = MutBox
        
        local mbLayout = Instance.new("UIListLayout")
        mbLayout.FillDirection = Enum.FillDirection.Horizontal
        mbLayout.Padding = UDim.new(0, 6)
        mbLayout.Parent = mbScroll
        
        if #mutatedCrops == 0 then
            local emptyText = Instance.new("TextLabel")
            emptyText.Size = UDim2.new(1, 0, 1, 0)
            emptyText.BackgroundTransparency = 1
            emptyText.Text = "No mutated crops currently detected in your garden plot."
            emptyText.TextColor3 = C_SUBTEXT
            emptyText.TextSize = 11
            emptyText.Font = Enum.Font.Gotham
            emptyText.TextXAlignment = Enum.TextXAlignment.Left
            emptyText.Parent = mbScroll
        else
            for mName, count in pairs(mutCounts) do
                local mutData = GameData.Mutations[mName]
                local pColor = mutData and mutData.Color or Color3.fromRGB(155, 89, 182)
                local multVal = mutData and mutData.Multiplier or 1
                
                local pill = Instance.new("Frame")
                pill.Size = UDim2.new(0, 0, 0, 28)
                pill.AutomaticSize = Enum.AutomaticSize.X
                pill.BackgroundColor3 = C_SIDEBAR
                pill.Parent = mbScroll
                
                local pCorn = Instance.new("UICorner")
                pCorn.CornerRadius = UDim.new(0, 6)
                pCorn.Parent = pill
                
                local pStr = Instance.new("UIStroke")
                pStr.Color = pColor
                pStr.Thickness = 1
                pStr.Parent = pill
                
                local pText = Instance.new("TextLabel")
                pText.Size = UDim2.new(0, 0, 1, 0)
                pText.AutomaticSize = Enum.AutomaticSize.X
                pText.BackgroundTransparency = 1
                pText.Text = string.format("  %s (%dx): x%d  ", mName, multVal, count)
                pText.TextColor3 = pColor
                pText.TextSize = 11
                pText.Font = Enum.Font.GothamBold
                pText.Parent = pill
            end
        end
        
        -- SECTION 4: MUTATED CROPS DETAIL LIST
        local DetailHeader = Instance.new("TextLabel")
        DetailHeader.Size = UDim2.new(1, 0, 0, 20)
        DetailHeader.BackgroundTransparency = 1
        DetailHeader.Text = "📋 Mutated Crops Detail List:"
        DetailHeader.TextColor3 = C_TEXT
        DetailHeader.TextSize = 12
        DetailHeader.Font = Enum.Font.GothamBold
        DetailHeader.TextXAlignment = Enum.TextXAlignment.Left
        DetailHeader.Parent = FarmDetailsPage
        
        if #mutatedCrops == 0 then
            local emptyCard = Instance.new("Frame")
            emptyCard.Size = UDim2.new(1, 0, 0, 42)
            emptyCard.BackgroundColor3 = C_CARD
            emptyCard.Parent = FarmDetailsPage
            
            local ecCorn = Instance.new("UICorner")
            ecCorn.CornerRadius = UDim.new(0, 6)
            ecCorn.Parent = emptyCard
            
            local ecText = Instance.new("TextLabel")
            ecText.Size = UDim2.new(1, 0, 1, 0)
            ecText.BackgroundTransparency = 1
            ecText.Text = "No mutated crops in garden. Stand in your plot and click 'Fetch My Garden'."
            ecText.TextColor3 = C_SUBTEXT
            ecText.TextSize = 11
            ecText.Font = Enum.Font.Gotham
            ecText.Parent = emptyCard
        else
            for idx, mData in ipairs(mutatedCrops) do
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 52)
                card.BackgroundColor3 = C_CARD
                card.Parent = FarmDetailsPage
                
                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(0, 6)
                cCorner.Parent = card
                
                local mutInfo = GameData.Mutations[mData.Mutation]
                local strokeColor = mutInfo and mutInfo.Color or Color3.fromRGB(241, 196, 15)
                local multVal = mutInfo and mutInfo.Multiplier or 1
                
                local cStroke = Instance.new("UIStroke")
                cStroke.Color = strokeColor
                cStroke.Thickness = 1
                cStroke.Parent = card
                
                local readyStr = mData.IsFullyGrown and "[READY]" or "[GROWING]"
                local infoText = string.format("[%d] %s [MUTATION: %s (%dx)] (%s - %.2f kg) %s",
                    idx, mData.FruitName, mData.Mutation, multVal, mData.FormattedWeight, mData.WeightKg, readyStr)
                local subInfoText = string.format("UUID: %s... | FruitID: %s | Est Value: %d Sheckles",
                    string.sub(mData.PlantUUID, 1, 13), mData.FruitId, mData.EstimatedValue)
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.72, 0, 0, 20)
                label.Position = UDim2.new(0, 10, 0, 6)
                label.BackgroundTransparency = 1
                label.Text = infoText
                label.TextColor3 = strokeColor
                label.TextSize = 12
                label.Font = Enum.Font.GothamBold
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = card
                
                local subLabel = Instance.new("TextLabel")
                subLabel.Size = UDim2.new(0.72, 0, 0, 18)
                subLabel.Position = UDim2.new(0, 10, 0, 26)
                subLabel.BackgroundTransparency = 1
                subLabel.Text = subInfoText
                subLabel.TextColor3 = C_SUBTEXT
                subLabel.TextSize = 10
                subLabel.Font = Enum.Font.Code
                subLabel.TextXAlignment = Enum.TextXAlignment.Left
                subLabel.Parent = card
                
                local hBtn = Instance.new("TextButton")
                hBtn.Size = UDim2.new(0, 80, 0, 28)
                hBtn.Position = UDim2.new(1, -90, 0.5, -14)
                hBtn.BackgroundColor3 = C_GREEN
                hBtn.Text = "Harvest"
                hBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                hBtn.TextSize = 11
                hBtn.Font = Enum.Font.GothamBold
                hBtn.Parent = card
                
                local hCorner = Instance.new("UICorner")
                hCorner.CornerRadius = UDim.new(0, 6)
                hCorner.Parent = hBtn
                
                hBtn.MouseButton1Click:Connect(function()
                    print(string.format("[FarmDetails Direct Harvest] UUID=%s | FruitID=%s", mData.PlantUUID, mData.FruitId))
                    local ok = Engine.HarvestSingle(mData)
                    if ok then
                        hBtn.Text = "DONE ✓"
                        hBtn.BackgroundColor3 = C_ACCENT
                    end
                    task.wait(0.3)
                    BuildFarmDetailsPage()
                end)
            end
        end
    end
    
    tabButtons["FarmDetails"].MouseButton1Click:Connect(BuildFarmDetailsPage)
    
    FetchGardenBtn.MouseButton1Click:Connect(function()
        print("[GUI] Fetching Garden...")
        local fruits = FetchGarden()
        AddLogItem(string.format("🌱 [GARDEN FETCH] Detected %d crops in your garden.", #fruits), Color3.fromRGB(46, 204, 113))
        BuildFarmDetailsPage()
        SwitchTab("FarmDetails")
    end)
    
    HarvestNowBtn.MouseButton1Click:Connect(function()
        print("[GUI] Starting Manual Harvest...")
        local count = Engine.HarvestAllNow()
        AddLogItem(string.format("⚡ [MANUAL HARVEST] Harvested %d crops.", count), C_ACCENT)
        BuildFarmDetailsPage()
    end)
    
    local function UpdateDashboardUI()
        StatHarvested.Text = tostring(Engine.Stats.TotalHarvested) .. " crops"
        StatWeight.Text = GameData.FormatWeight(Engine.Stats.TotalWeightGrams)
        StatValue.Text = string.format("%d", Engine.Stats.TotalEstimatedValue) .. " Sheckles"
        StatMutations.Text = tostring(Engine.Stats.MutationsCount)
        BuildFarmDetailsPage()
    end
    
    Engine.OnHarvestEvent.Event:Connect(function(fruitData, logMsg)
        UpdateDashboardUI()
        AddLogItem(logMsg, fruitData.Mutation and Color3.fromRGB(241, 196, 15) or C_SUBTEXT)
    end)
    
    -- PAGE 3: SETTINGS (ENGLISH WITH MULTI-SELECT SEARCH DROPDOWNS)
    local SettingsPage = Instance.new("ScrollingFrame")
    SettingsPage.Size = UDim2.new(1, -10, 1, 0)
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Visible = false
    SettingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SettingsPage.ScrollBarThickness = 4
    SettingsPage.Parent = Container
    tabs["Settings"] = SettingsPage
    
    local SettingsLayout = Instance.new("UIListLayout")
    SettingsLayout.Padding = UDim.new(0, 10)
    SettingsLayout.Parent = SettingsPage
    
    local function CreateToggleRow(title, desc, initialVal, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 52)
        row.BackgroundColor3 = C_CARD
        row.Parent = SettingsPage
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = row
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = C_STROKE
        stroke.Parent = row
        
        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(0.7, 0, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = C_TEXT
        tLabel.TextSize = 14
        tLabel.Font = Enum.Font.GothamMedium
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = row
        
        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(0.7, 0, 0, 18)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = C_SUBTEXT
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = row
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 60, 0, 28)
        toggleBtn.Position = UDim2.new(1, -72, 0.5, -14)
        toggleBtn.BackgroundColor3 = initialVal and C_GREEN or Color3.fromRGB(60, 65, 80)
        toggleBtn.Text = initialVal and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = row
        
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 14)
        tCorner.Parent = toggleBtn
        
        local state = initialVal
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and C_GREEN or Color3.fromRGB(60, 65, 80)
            toggleBtn.Text = state and "ON" or "OFF"
            SubTitle.Text = "| Status: Auto Harvest " .. (state and "ON" or "OFF")
            callback(state)
        end)
    end
    
    local function CreateWeightInputRow(title, desc, toggleInitVal, inputInitVal, toggleCb, inputCb)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = C_CARD
        row.Parent = SettingsPage
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = row
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = C_STROKE
        stroke.Parent = row
        
        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(0.55, 0, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = C_TEXT
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamMedium
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = row
        
        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(0.55, 0, 0, 18)
        dLabel.Position = UDim2.new(0, 12, 0, 28)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = C_SUBTEXT
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = row
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0, 70, 0, 28)
        input.Position = UDim2.new(1, -145, 0.5, -14)
        input.BackgroundColor3 = C_SIDEBAR
        input.Text = tostring(inputInitVal)
        input.TextColor3 = C_TEXT
        input.TextSize = 12
        input.Font = Enum.Font.Code
        input.Parent = row
        
        local iCorner = Instance.new("UICorner")
        iCorner.CornerRadius = UDim.new(0, 6)
        iCorner.Parent = input
        
        input.FocusLost:Connect(function()
            local num = tonumber(input.Text) or 0
            inputCb(num)
        end)
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 60, 0, 28)
        toggleBtn.Position = UDim2.new(1, -72, 0.5, -14)
        toggleBtn.BackgroundColor3 = toggleInitVal and C_GREEN or Color3.fromRGB(60, 65, 80)
        toggleBtn.Text = toggleInitVal and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = row
        
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 14)
        tCorner.Parent = toggleBtn
        
        local state = toggleInitVal
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and C_GREEN or Color3.fromRGB(60, 65, 80)
            toggleBtn.Text = state and "ON" or "OFF"
            toggleCb(state)
        end)
    end
    
    -- COMPONENT: ADVANCED MULTI-SELECT DROPDOWN WITH SEARCH, SELECT ALL & CLEAR ALL
    local function CreateDropdownFilter(title, desc, enableInitVal, whitelistTable, enableCb)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 56)
        frame.BackgroundColor3 = C_CARD
        frame.ClipsDescendants = true
        frame.Parent = SettingsPage
        
        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(0, 8)
        fCorner.Parent = frame
        
        local fStroke = Instance.new("UIStroke")
        fStroke.Color = C_STROKE
        fStroke.Parent = frame
        
        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(0.5, 0, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = C_TEXT
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamMedium
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = frame
        
        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(0.5, 0, 0, 18)
        dLabel.Position = UDim2.new(0, 12, 0, 28)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = C_SUBTEXT
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = frame
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 55, 0, 26)
        toggleBtn.Position = UDim2.new(1, -65, 0, 15)
        toggleBtn.BackgroundColor3 = enableInitVal and C_GREEN or Color3.fromRGB(60, 65, 80)
        toggleBtn.Text = enableInitVal and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 11
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = frame
        
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 13)
        tCorner.Parent = toggleBtn
        
        local expandBtn = Instance.new("TextButton")
        expandBtn.Size = UDim2.new(0, 95, 0, 26)
        expandBtn.Position = UDim2.new(1, -168, 0, 15)
        expandBtn.BackgroundColor3 = C_ACCENT
        expandBtn.Text = "Select... ▼"
        expandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        expandBtn.TextSize = 11
        expandBtn.Font = Enum.Font.GothamBold
        expandBtn.Parent = frame
        
        local eCorner = Instance.new("UICorner")
        eCorner.CornerRadius = UDim.new(0, 6)
        eCorner.Parent = expandBtn
        
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, -20, 0, 180)
        panel.Position = UDim2.new(0, 10, 0, 52)
        panel.BackgroundColor3 = C_SIDEBAR
        panel.Parent = frame
        
        local pCorner = Instance.new("UICorner")
        pCorner.CornerRadius = UDim.new(0, 6)
        pCorner.Parent = panel
        
        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(0.48, 0, 0, 26)
        searchBox.Position = UDim2.new(0, 6, 0, 6)
        searchBox.BackgroundColor3 = C_CARD
        searchBox.PlaceholderText = "🔍 Search..."
        searchBox.Text = ""
        searchBox.TextColor3 = C_TEXT
        searchBox.PlaceholderColor3 = C_SUBTEXT
        searchBox.TextSize = 11
        searchBox.Font = Enum.Font.Gotham
        searchBox.Parent = panel
        
        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = UDim.new(0, 6)
        sCorner.Parent = searchBox
        
        local selectAllBtn = Instance.new("TextButton")
        selectAllBtn.Size = UDim2.new(0.24, -4, 0, 26)
        selectAllBtn.Position = UDim2.new(0.49, 4, 0, 6)
        selectAllBtn.BackgroundColor3 = C_GREEN
        selectAllBtn.Text = "Select All"
        selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectAllBtn.TextSize = 10
        selectAllBtn.Font = Enum.Font.GothamBold
        selectAllBtn.Parent = panel
        
        local saCorner = Instance.new("UICorner")
        saCorner.CornerRadius = UDim.new(0, 6)
        saCorner.Parent = selectAllBtn
        
        local clearAllBtn = Instance.new("TextButton")
        clearAllBtn.Size = UDim2.new(0.24, -4, 0, 26)
        clearAllBtn.Position = UDim2.new(0.74, 4, 0, 6)
        clearAllBtn.BackgroundColor3 = C_RED
        clearAllBtn.Text = "Clear All"
        clearAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        clearAllBtn.TextSize = 10
        clearAllBtn.Font = Enum.Font.GothamBold
        clearAllBtn.Parent = panel
        
        local caCorner = Instance.new("UICorner")
        caCorner.CornerRadius = UDim.new(0, 6)
        caCorner.Parent = clearAllBtn
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -12, 1, -42)
        scroll.Position = UDim2.new(0, 6, 0, 36)
        scroll.BackgroundTransparency = 1
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 4
        scroll.Parent = panel
        
        local sLayout = Instance.new("UIGridLayout")
        sLayout.CellSize = UDim2.new(0.48, 0, 0, 24)
        sLayout.CellPadding = UDim2.new(0.04, 0, 0, 4)
        sLayout.SortOrder = Enum.SortOrder.Name
        sLayout.Parent = scroll
        
        local isExpanded = false
        expandBtn.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            expandBtn.Text = isExpanded and "Close ▲" or "Select... ▼"
            frame.Size = isExpanded and UDim2.new(1, 0, 0, 240) or UDim2.new(1, 0, 0, 56)
        end)
        
        local state = enableInitVal
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and C_GREEN or Color3.fromRGB(60, 65, 80)
            toggleBtn.Text = state and "ON" or "OFF"
            enableCb(state)
        end)
        
        local itemButtons = {}
        
        local function PopulateItems(filterText)
            filterText = filterText and filterText:lower() or ""
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            table.clear(itemButtons)
            
            local keys = {}
            for name in pairs(whitelistTable) do
                table.insert(keys, name)
            end
            table.sort(keys)
            
            for _, name in ipairs(keys) do
                if filterText == "" or name:lower():find(filterText, 1, true) then
                    local isChecked = whitelistTable[name]
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.Name = name
                    itemBtn.Size = UDim2.new(1, 0, 1, 0)
                    itemBtn.BackgroundColor3 = isChecked and Color3.fromRGB(45, 120, 75) or C_CARD
                    itemBtn.Text = (isChecked and "✓ " or "✗ ") .. name
                    itemBtn.TextColor3 = isChecked and Color3.fromRGB(255, 255, 255) or C_SUBTEXT
                    itemBtn.TextSize = 10
                    itemBtn.Font = Enum.Font.GothamMedium
                    itemBtn.Parent = scroll
                    
                    local iCorn = Instance.new("UICorner")
                    iCorn.CornerRadius = UDim.new(0, 4)
                    iCorn.Parent = itemBtn
                    
                    itemBtn.MouseButton1Click:Connect(function()
                        whitelistTable[name] = not whitelistTable[name]
                        local checked = whitelistTable[name]
                        itemBtn.BackgroundColor3 = checked and Color3.fromRGB(45, 120, 75) or C_CARD
                        itemBtn.Text = (checked and "✓ " or "✗ ") .. name
                        itemBtn.TextColor3 = checked and Color3.fromRGB(255, 255, 255) or C_SUBTEXT
                    end)
                    
                    itemButtons[name] = itemBtn
                end
            end
        end
        
        PopulateItems("")
        
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            PopulateItems(searchBox.Text)
        end)
        
        selectAllBtn.MouseButton1Click:Connect(function()
            for name in pairs(whitelistTable) do
                whitelistTable[name] = true
            end
            PopulateItems(searchBox.Text)
        end)
        
        clearAllBtn.MouseButton1Click:Connect(function()
            for name in pairs(whitelistTable) do
                whitelistTable[name] = false
            end
            PopulateItems(searchBox.Text)
        end)
    end
    
    -- Main Auto Harvest Controls
    CreateToggleRow("Auto Harvest Loop", "Automatically harvest crops when ready", Config.AutoHarvest, function(val)
        Config.AutoHarvest = val
        if val then Engine.Start() else Engine.Stop() end
    end)
    
    -- Dropdown Crop Whitelist Filter
    CreateDropdownFilter("🌾 Filter by Crops", "Select specific crops to harvest", Config.CropFilterEnabled, Config.CropWhitelist, function(state)
        Config.CropFilterEnabled = state
    end)
    
    -- Dropdown Mutation Whitelist Filter
    CreateDropdownFilter("✨ Filter by Mutations", "Select specific mutations to harvest", Config.MutationFilterEnabled, Config.MutationWhitelist, function(state)
        Config.MutationFilterEnabled = state
    end)
    
    CreateToggleRow("Only Mutated Crops", "Ignore normal non-mutated crops", Config.FilterMutationsOnly, function(val)
        Config.FilterMutationsOnly = val
    end)
    
    -- Weight Filters (Above / Below in kg)
    CreateWeightInputRow("⚖️ Min Weight Filter (kg)", "Only harvest if crop weight >= X kg (Above)", Config.WeightFilterAboveEnabled, Config.WeightAboveKg, function(state)
        Config.WeightFilterAboveEnabled = state
    end, function(val)
        Config.WeightAboveKg = val
        print(string.format("[Config] Min Weight set to: %.2f kg", val))
    end)
    
    CreateWeightInputRow("⚖️ Max Weight Filter (kg)", "Only harvest if crop weight <= Y kg (Below)", Config.WeightFilterBelowEnabled, Config.WeightBelowKg, function(state)
        Config.WeightFilterBelowEnabled = state
    end, function(val)
        Config.WeightBelowKg = val
        print(string.format("[Config] Max Weight set to: %.2f kg", val))
    end)
    
    CreateToggleRow("Fully Grown Only", "Harvest crops that are fully grown only", Config.OnlyFullyGrown, function(val)
        Config.OnlyFullyGrown = val
    end)
    
    CreateToggleRow("Console Notifications (F9)", "Print detailed harvest logs to F9 console", Config.NotifyHarvest, function(val)
        Config.NotifyHarvest = val
    end)
    
    -- PAGE 4: INSPECTOR (CROP INSPECTOR) & MANUAL INJECTOR
    local InspectorPage = Instance.new("Frame")
    InspectorPage.Size = UDim2.new(1, -10, 1, 0)
    InspectorPage.BackgroundTransparency = 1
    InspectorPage.Visible = false
    InspectorPage.Parent = Container
    tabs["Inspector"] = InspectorPage
    
    -- Manual Injector Bar (Test Fire Custom UUID + FruitID)
    local InjectorBox = Instance.new("Frame")
    InjectorBox.Size = UDim2.new(1, 0, 0, 42)
    InjectorBox.Position = UDim2.new(0, 0, 0, 0)
    InjectorBox.BackgroundColor3 = C_CARD
    InjectorBox.Parent = InspectorPage
    
    local InjCorner = Instance.new("UICorner")
    InjCorner.CornerRadius = UDim.new(0, 8)
    InjCorner.Parent = InjectorBox
    
    local UuidInput = Instance.new("TextBox")
    UuidInput.Size = UDim2.new(0.5, -10, 0, 28)
    UuidInput.Position = UDim2.new(0, 8, 0, 7)
    UuidInput.BackgroundColor3 = C_SIDEBAR
    UuidInput.PlaceholderText = "Paste Plant UUID..."
    UuidInput.Text = ""
    UuidInput.TextColor3 = C_TEXT
    UuidInput.PlaceholderColor3 = C_SUBTEXT
    UuidInput.TextSize = 11
    UuidInput.Font = Enum.Font.Code
    UuidInput.Parent = InjectorBox
    
    local UuidCorner = Instance.new("UICorner")
    UuidCorner.CornerRadius = UDim.new(0, 6)
    UuidCorner.Parent = UuidInput
    
    local FruitIdInput = Instance.new("TextBox")
    FruitIdInput.Size = UDim2.new(0.2, -5, 0, 28)
    FruitIdInput.Position = UDim2.new(0.5, 3, 0, 7)
    FruitIdInput.BackgroundColor3 = C_SIDEBAR
    FruitIdInput.PlaceholderText = "FruitID (95)"
    FruitIdInput.Text = ""
    FruitIdInput.TextColor3 = C_TEXT
    FruitIdInput.PlaceholderColor3 = C_SUBTEXT
    FruitIdInput.TextSize = 11
    FruitIdInput.Font = Enum.Font.Code
    FruitIdInput.Parent = InjectorBox
    
    local IdCorner = Instance.new("UICorner")
    IdCorner.CornerRadius = UDim.new(0, 6)
    IdCorner.Parent = FruitIdInput
    
    local FireInjBtn = Instance.new("TextButton")
    FireInjBtn.Size = UDim2.new(0.28, -10, 0, 28)
    FireInjBtn.Position = UDim2.new(0.72, 3, 0, 7)
    FireInjBtn.BackgroundColor3 = C_ACCENT
    FireInjBtn.Text = "🔥 Fire Harvest"
    FireInjBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FireInjBtn.TextSize = 11
    FireInjBtn.Font = Enum.Font.GothamBold
    FireInjBtn.Parent = InjectorBox
    
    local FireCorner = Instance.new("UICorner")
    FireCorner.CornerRadius = UDim.new(0, 6)
    FireCorner.Parent = FireInjBtn
    
    FireInjBtn.MouseButton1Click:Connect(function()
        local uuid = UuidInput.Text:gsub("%s+", "")
        local fid = FruitIdInput.Text:gsub("%s+", "")
        if #uuid > 0 and #fid > 0 then
            print(string.format("[Manual Injector] Sending Remote: UUID=%s | FruitID=%s", uuid, fid))
            local ok = Network.SendHarvest(uuid, fid)
            if ok then
                FireInjBtn.Text = "SENT! ✓"
                FireInjBtn.BackgroundColor3 = C_GREEN
                task.delay(1.5, function()
                    FireInjBtn.Text = "🔥 Fire Harvest"
                    FireInjBtn.BackgroundColor3 = C_ACCENT
                end)
            end
        else
            warn("[Manual Injector] Please enter UUID and FruitID first!")
        end
    end)
    
    local InspHeader = Instance.new("TextLabel")
    InspHeader.Size = UDim2.new(0.6, 0, 0, 20)
    InspHeader.Position = UDim2.new(0, 0, 0, 48)
    InspHeader.BackgroundTransparency = 1
    InspHeader.Text = "🌱 Detected Crops in Garden:"
    InspHeader.TextColor3 = C_TEXT
    InspHeader.TextSize = 12
    InspHeader.Font = Enum.Font.GothamMedium
    InspHeader.TextXAlignment = Enum.TextXAlignment.Left
    InspHeader.Parent = InspectorPage
    
    local RefreshBtn = Instance.new("TextButton")
    RefreshBtn.Size = UDim2.new(0, 110, 0, 24)
    RefreshBtn.Position = UDim2.new(1, -110, 0, 46)
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    RefreshBtn.Text = "🌱 Fetch Garden"
    RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshBtn.TextSize = 11
    RefreshBtn.Font = Enum.Font.GothamBold
    RefreshBtn.Parent = InspectorPage
    
    local RefCorner = Instance.new("UICorner")
    RefCorner.CornerRadius = UDim.new(0, 6)
    RefCorner.Parent = RefreshBtn
    
    local InspScroll = Instance.new("ScrollingFrame")
    InspScroll.Size = UDim2.new(1, 0, 1, -78)
    InspScroll.Position = UDim2.new(0, 0, 0, 75)
    InspScroll.BackgroundColor3 = C_CARD
    InspScroll.BorderSizePixel = 0
    InspScroll.ScrollBarThickness = 4
    InspScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    InspScroll.Parent = InspectorPage
    
    local InspCorner = Instance.new("UICorner")
    InspCorner.CornerRadius = UDim.new(0, 8)
    InspCorner.Parent = InspScroll
    
    local InspLayout = Instance.new("UIListLayout")
    InspLayout.Padding = UDim.new(0, 6)
    InspLayout.SortOrder = Enum.SortOrder.LayoutOrder
    InspLayout.Parent = InspScroll
    
    local InspPadding = Instance.new("UIPadding")
    InspPadding.PaddingTop = UDim.new(0, 8)
    InspPadding.PaddingLeft = UDim.new(0, 8)
    InspPadding.PaddingRight = UDim.new(0, 8)
    InspPadding.Parent = InspScroll
    
    local function RefreshInspector()
        for _, child in ipairs(InspScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        local fruits = FetchGarden()
        if #fruits == 0 then
            local emptyMsg = Instance.new("TextLabel")
            emptyMsg.Size = UDim2.new(1, 0, 0, 40)
            emptyMsg.BackgroundTransparency = 1
            emptyMsg.Text = "No crops detected matching active filter criteria."
            emptyMsg.TextColor3 = C_SUBTEXT
            emptyMsg.TextSize = 12
            emptyMsg.Font = Enum.Font.Gotham
            emptyMsg.Parent = InspScroll
            return
        end
        
        for idx, fData in ipairs(fruits) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 48)
            card.BackgroundColor3 = C_SIDEBAR
            card.Parent = InspScroll
            
            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = card
            
            local mutText = fData.Mutation and (" [" .. fData.Mutation .. "]") or ""
            local infoText = string.format("[%d] [%s] %s%s (%.2f kg) - %d Sheckles", idx, fData.Rarity, fData.FruitName, mutText, fData.WeightKg, fData.EstimatedValue)
            local subInfoText = string.format("UUID: %s... | FruitID: %s", string.sub(fData.PlantUUID, 1, 13), fData.FruitId)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 6)
            label.BackgroundTransparency = 1
            label.Text = infoText
            label.TextColor3 = fData.Mutation and Color3.fromRGB(241, 196, 15) or C_TEXT
            label.TextSize = 12
            label.Font = Enum.Font.GothamMedium
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = card
            
            local subLabel = Instance.new("TextLabel")
            subLabel.Size = UDim2.new(0.7, 0, 0, 16)
            subLabel.Position = UDim2.new(0, 10, 0, 26)
            subLabel.BackgroundTransparency = 1
            subLabel.Text = subInfoText
            subLabel.TextColor3 = C_SUBTEXT
            subLabel.TextSize = 10
            subLabel.Font = Enum.Font.Code
            subLabel.TextXAlignment = Enum.TextXAlignment.Left
            subLabel.Parent = card
            
            local hBtn = Instance.new("TextButton")
            hBtn.Size = UDim2.new(0, 80, 0, 28)
            hBtn.Position = UDim2.new(1, -90, 0.5, -14)
            hBtn.BackgroundColor3 = C_GREEN
            hBtn.Text = "Harvest"
            hBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            hBtn.TextSize = 11
            hBtn.Font = Enum.Font.GothamBold
            hBtn.Parent = card
            
            local hCorner = Instance.new("UICorner")
            hCorner.CornerRadius = UDim.new(0, 6)
            hCorner.Parent = hBtn
            
            hBtn.MouseButton1Click:Connect(function()
                print(string.format("[Harvest Direct] Direct harvest attempt: UUID=%s | FruitID=%s", fData.PlantUUID, fData.FruitId))
                local success = Engine.HarvestSingle(fData)
                if success then
                    hBtn.Text = "DONE ✓"
                    hBtn.BackgroundColor3 = C_ACCENT
                end
                task.wait(0.2)
                RefreshInspector()
            end)
        end
    end
    
    RefreshBtn.MouseButton1Click:Connect(RefreshInspector)
    tabButtons["Inspector"].MouseButton1Click:Connect(RefreshInspector)
    
    -- PAGE 5: FRUIT ESP SETTINGS TAB
    local EspPage = Instance.new("ScrollingFrame")
    EspPage.Size = UDim2.new(1, -10, 1, 0)
    EspPage.BackgroundTransparency = 1
    EspPage.Visible = false
    EspPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    EspPage.ScrollBarThickness = 4
    EspPage.Parent = Container
    tabs["ESP"] = EspPage
    
    local EspLayout = Instance.new("UIListLayout")
    EspLayout.Padding = UDim.new(0, 10)
    EspLayout.Parent = EspPage

    local espBanner = Instance.new("Frame")
    espBanner.Size = UDim2.new(1, 0, 0, 50)
    espBanner.BackgroundColor3 = C_CARD
    espBanner.Parent = EspPage

    local ebCorner = Instance.new("UICorner")
    ebCorner.CornerRadius = UDim.new(0, 8)
    ebCorner.Parent = espBanner

    local ebStroke = Instance.new("UIStroke")
    ebStroke.Color = Color3.fromRGB(46, 204, 113)
    ebStroke.Thickness = 1
    ebStroke.Parent = espBanner

    local ebTitle = Instance.new("TextLabel")
    ebTitle.Size = UDim2.new(1, -16, 0, 24)
    ebTitle.Position = UDim2.new(0, 12, 0, 4)
    ebTitle.BackgroundTransparency = 1
    ebTitle.Text = "👁️ 3D Fruit & Weight ESP Settings"
    ebTitle.TextColor3 = C_TEXT
    ebTitle.TextSize = 14
    ebTitle.Font = Enum.Font.GothamBold
    ebTitle.TextXAlignment = Enum.TextXAlignment.Left
    ebTitle.Parent = espBanner

    local ebSub = Instance.new("TextLabel")
    ebSub.Size = UDim2.new(1, -16, 0, 18)
    ebSub.Position = UDim2.new(0, 12, 0, 26)
    ebSub.BackgroundTransparency = 1
    ebSub.Text = "Renders exact 3D location tags for all garden crops with names, weights & mutations."
    ebSub.TextColor3 = C_SUBTEXT
    ebSub.TextSize = 11
    ebSub.Font = Enum.Font.Gotham
    ebSub.TextXAlignment = Enum.TextXAlignment.Left
    ebSub.Parent = espBanner

    local function CreateEspToggleRow(title, desc, initialVal, callback)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 52)
        row.BackgroundColor3 = C_CARD
        row.Parent = EspPage
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = row
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = C_STROKE
        stroke.Parent = row
        
        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(0.7, 0, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = C_TEXT
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamMedium
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = row
        
        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(0.7, 0, 0, 18)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = C_SUBTEXT
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = row
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 60, 0, 28)
        toggleBtn.Position = UDim2.new(1, -72, 0.5, -14)
        toggleBtn.BackgroundColor3 = initialVal and C_GREEN or Color3.fromRGB(60, 65, 80)
        toggleBtn.Text = initialVal and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = row
        
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(0, 14)
        tCorner.Parent = toggleBtn
        
        local state = initialVal
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.BackgroundColor3 = state and C_GREEN or Color3.fromRGB(60, 65, 80)
            toggleBtn.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    CreateEspToggleRow("Master Fruit ESP Switch", "Enable or disable all in-game 3D fruit ESP tags", Config.EspEnabled, function(state)
        Config.EspEnabled = state
        if not state then
            if ESPManager then ESPManager.ClearAll() end
        else
            if ESPManager then task.spawn(ESPManager.RefreshAll) end
        end
    end)

    CreateEspToggleRow("Show Crop Weight (⚖️)", "Displays formatted crop weight (e.g. 1.21 kg) on ESP tags", Config.EspShowWeight, function(state)
        Config.EspShowWeight = state
        if ESPManager and Config.EspEnabled then task.spawn(ESPManager.RefreshAll) end
    end)

    CreateEspToggleRow("Show Mutation Badges (✨)", "Displays mutation names & color glow (e.g. Electric 25x)", Config.EspShowMutation, function(state)
        Config.EspShowMutation = state
        if ESPManager and Config.EspEnabled then task.spawn(ESPManager.RefreshAll) end
    end)

    CreateEspToggleRow("Show Player Distance ([12m])", "Displays distance in meters on the 3D ESP tag", Config.EspShowDistance, function(state)
        Config.EspShowDistance = state
        if ESPManager and Config.EspEnabled then task.spawn(ESPManager.RefreshAll) end
    end)

    CreateEspToggleRow("Only Ready-To-Harvest Crops", "Filter ESP tags to show only fully grown ready crops", Config.EspOnlyReady, function(state)
        Config.EspOnlyReady = state
        if ESPManager and Config.EspEnabled then task.spawn(ESPManager.RefreshAll) end
    end)

    CreateEspToggleRow("Only Mutated Crops", "Filter ESP tags to show only crops with special mutations", Config.EspOnlyMutated, function(state)
        Config.EspOnlyMutated = state
        if ESPManager and Config.EspEnabled then task.spawn(ESPManager.RefreshAll) end
    end)
    
    -- Keybind Listener
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Config.ToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
    
    print("[GAG2 GUI] Interface loaded! (Press RightShift to Toggle UI)")
    return ScreenGui
end

-- Build GUI automatically on execute
GUI.Build()

-- Automatically run initial Garden Fetch on script startup
task.spawn(function()
    task.wait(0.5)
    FetchGarden()
end)

-- ==========================================
-- 7. EXPORT MODULE TABLE
-- ==========================================
local AutoHarvestModule = {
    Config = Config,
    GameData = GameData,
    Network = Network,
    Scanner = Scanner,
    Engine = Engine,
    ESPManager = ESPManager,
    GUI = GUI,
    
    -- Quick Action Methods
    Start = Engine.Start,
    Stop = Engine.Stop,
    HarvestAll = Engine.HarvestAllNow,
    FetchGarden = FetchGarden,
    GetHarvestable = Scanner.GetHarvestableFruits,
    PrintStats = Engine.PrintStats,
    CreateBuffer = Network.CreateHarvestBuffer,
}

-- Default: Auto Harvest is OFF on execute
if Config.AutoHarvest then
    Engine.Start()
end

return AutoHarvestModule
