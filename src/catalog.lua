----------------------------------------------------
-- Grow a Garden 2 - Crop, Gear & Mutation Catalog Data
----------------------------------------------------
local Catalog = {}

Catalog.CropCatalog = {
	Common = {"Carrot", "Blueberry", "Strawberry"},
	Uncommon = {"Apple", "Tomato", "Tulip"},
	Rare = {"Baby Cactus", "Bamboo", "Cactus", "Corn", "Horned Melon", "Pineapple"},
	Epic = {"Banana", "Coconut", "Glow Mushroom", "Grape", "Green Bean", "Mango", "Mushroom"},
	Legendary = {"Acorn", "Cherry", "Dragon Fruit", "Fire Fern", "Poison Ivy", "Sunflower", "Rocket Pop"},
	Mythic = {"Ghost Pepper", "Poison Apple", "Pomegranate", "Venom Spitter", "Venus Fly Trap"},
	Super = {"Dragon's Breath", "Hypno Bloom", "Moon Bloom", "Sun Bloom", "Star Fruit"},
	Secret = {"Eclipse Bloom"}
}

Catalog.CropCatalogNames = {
	"Acorn", "Apple", "Baby Cactus", "Bamboo", "Banana", "Blueberry", "Cactus",
	"Carrot", "Cherry", "Coconut", "Corn", "Dragon Fruit", "Dragon's Breath",
	"Eclipse Bloom", "Fire Fern", "Ghost Pepper", "Glow Mushroom", "Grape",
	"Green Bean", "Horned Melon", "Hypno Bloom", "Mango", "Moon Bloom", "Mushroom",
	"Pineapple", "Poison Apple", "Poison Ivy", "Pomegranate", "Rocket Pop",
	"Star Fruit", "Strawberry", "Sun Bloom", "Sunflower", "Tomato", "Tulip",
	"Venom Spitter", "Venus Fly Trap"
}

Catalog.CropRarityMap = {}
for rarity, cropList in pairs(Catalog.CropCatalog) do
	for _, cName in ipairs(cropList) do
		Catalog.CropRarityMap[cName] = rarity
	end
end

function Catalog.getCropDisplayName(cropName)
	local rarity = Catalog.CropRarityMap[cropName]
	if rarity then
		return cropName .. " (" .. rarity .. ")"
	end
	return cropName
end

Catalog.SprinklerCatalogNames = {
	"Common Sprinkler",
	"Advanced Sprinkler",
	"Uncommon Sprinkler",
	"Rare Sprinkler",
	"Master Sprinkler",
	"Godly Sprinkler"
}

Catalog.WateringCanCatalogNames = {
	"Common Watering Can",
	"Super Watering Can"
}

Catalog.OfficialGearCatalog = {
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

Catalog.RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Super", "Secret"}

Catalog.MUTATION_DATA = {
	{ Name = "Gold",       Multiplier = "10x", Icon = "🪙", ExactNames = { "goldvfx", "gold", "golden", "greenbeangold" } },
	{ Name = "Rainbow",    Multiplier = "30x", Icon = "🌈", ExactNames = { "rainbowvfx", "rainbow", "strawberryrainbow" } },
	{ Name = "Bloodlit",   Multiplier = "70x", Icon = "🩸", ExactNames = { "bloodlitvfx", "bloodlit", "bamboobloodlit" } },
	{ Name = "Electric",   Multiplier = "25x", Icon = "⚡", ExactNames = { "electricvfx", "electric", "bambooelectric", "lightning", "shocked" } },
	{ Name = "Starstruck", Multiplier = "50x", Icon = "⭐", ExactNames = { "starstruckvfx", "starstruck", "blueberrystarstruck", "starfall" } },
	{ Name = "Frozen",     Multiplier = "20x", Icon = "❄️", ExactNames = { "frozenvfx", "frozen", "frost", "gag" } },
	{ Name = "Aurora",     Multiplier = "40x", Icon = "🌌", ExactNames = { "aurorav2", "auroravfx", "aurora" } },
	{ Name = "Eclipsed",   Multiplier = "80x", Icon = "🌒", ExactNames = { "eclipsedvfx", "eclipsed", "eclipse" } },
	{ Name = "Glow",       Multiplier = "80x", Icon = "💡", ExactNames = { "glowmutation", "glowvfx", "glow" } },
	{ Name = "Secret",     Multiplier = "TBA", Icon = "❓", ExactNames = { "secretvfx", "secret" } },
	{ Name = "Solarflare", Multiplier = "5x",  Icon = "☀️", ExactNames = { "solarflarevfx", "solarflare" } },
	{ Name = "Pizza",      Multiplier = "5x",  Icon = "🍕", ExactNames = { "pizzavfx", "pizza" } },
	{ Name = "Chained",    Multiplier = "8x",  Icon = "⛓️", ExactNames = { "chainedvfx", "chained" } },
	{ Name = "Ignited",    Multiplier = "60x", Icon = "🔥", ExactNames = { "ignitedvfx", "ignited" } }
}

Catalog.SUB_PARTICLE_EXCLUSIONS = {
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

Catalog.ReleasedMutations = {
	"Gold", "Rainbow", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow"
}

Catalog.UnreleasedMutations = {
	"Solarflare", "Pizza", "Chained", "Ignited"
}

Catalog.OfficialMutationList = {
	"Normal", "Gold", "Rainbow", "Bloodlit", "Electric", "Starstruck", "Frozen", "Aurora", "Eclipsed", "Glow", "Solarflare", "Pizza", "Chained", "Ignited"
}

Catalog.MutationColors = {
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

function Catalog.getCropRarity(cropName)
	for rarity, items in pairs(Catalog.CropCatalog) do
		for _, name in ipairs(items) do
			if string.lower(name) == string.lower(cropName) or string.find(string.lower(cropName), string.lower(name)) then
				return rarity
			end
		end
	end
	return "Common"
end

Catalog.RarityColors = {
	Super = Color3.fromRGB(231, 76, 60),
	Secret = Color3.fromRGB(230, 126, 34),
	Mythic = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(241, 196, 15),
	Epic = Color3.fromRGB(142, 68, 173),
	Rare = Color3.fromRGB(52, 152, 219),
	Uncommon = Color3.fromRGB(46, 204, 113),
	Common = Color3.fromRGB(180, 190, 205)
}

return Catalog
