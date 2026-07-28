----------------------------------------------------
-- Grow a Garden 2 - Geist Dark Theme GUI & UI Component Module
----------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local UI = {}

local Settings = nil
pcall(function()
	Settings = loadstring(readfile("e:/Roblox/Script Grow a Garden 2/src/config.lua") or readfile("src/config.lua"))()
end)
if not Settings then Settings = require(script.Parent.config) end

local Catalog = nil
pcall(function()
	Catalog = loadstring(readfile("e:/Roblox/Script Grow a Garden 2/src/catalog.lua") or readfile("src/catalog.lua"))()
end)
if not Catalog then Catalog = require(script.Parent.catalog) end

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

local Actions = nil
pcall(function()
	Actions = loadstring(readfile("e:/Roblox/Script Grow a Garden 2/src/actions.lua") or readfile("src/actions.lua"))()
end)
if not Actions then Actions = require(script.Parent.actions) end

-- Color Tokens (Geist Dark Modern Theme)
UI.GeistColors = {
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

local GeistColors = UI.GeistColors
local CropCatalogNames = Catalog.CropCatalogNames
local RarityColors = Catalog.RarityColors
local MutationColors = Catalog.MutationColors
local OfficialGearCatalog = Catalog.OfficialGearCatalog

function UI.initGui(cleanupScriptCallback)
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
	screenGui.Parent = targetParent

	UI.screenGui = screenGui
	UI.scriptConnections = {}

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

	local openStatusDot = Instance.new("Frame")
	openStatusDot.Size = UDim2.new(0, 10, 0, 10)
	openStatusDot.Position = UDim2.new(1, -12, 0, 4)
	openStatusDot.BackgroundColor3 = GeistColors.Emerald
	openStatusDot.BorderSizePixel = 0
	openStatusDot.Parent = openIcon

	local osdCorner = Instance.new("UICorner")
	osdCorner.CornerRadius = UDim.new(0, 5)
	osdCorner.Parent = openStatusDot

	openIcon.MouseEnter:Connect(function()
		openIcon.BackgroundColor3 = Color3.fromRGB(25, 28, 42)
		openIconStroke.Color = Color3.fromRGB(165, 180, 252)
	end)
	openIcon.MouseLeave:Connect(function()
		openIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 25)
		openIconStroke.Color = GeistColors.Primary
	end)

	UI.openIcon = openIcon

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

	UI.mainFrame = mainFrame

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

	minimizeBtn.MouseEnter:Connect(function()
		minimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 58)
		minimizeBtn.TextColor3 = GeistColors.TextMain
	end)
	minimizeBtn.MouseLeave:Connect(function()
		minimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
		minimizeBtn.TextColor3 = GeistColors.TextMuted
	end)

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

	maximizeBtn.MouseEnter:Connect(function()
		maximizeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 58)
		maximizeBtn.TextColor3 = GeistColors.TextMain
	end)
	maximizeBtn.MouseLeave:Connect(function()
		maximizeBtn.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
		maximizeBtn.TextColor3 = GeistColors.TextMuted
	end)

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

	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = GeistColors.ErrorRed
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 28)
		closeBtn.TextColor3 = GeistColors.ErrorRed
	end)

	-- Close Confirmation Modal Popup
	local confirmModal = Instance.new("Frame")
	confirmModal.Name = "ConfirmCloseModal"
	confirmModal.Size = UDim2.new(1, 0, 1, 0)
	confirmModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	confirmModal.BackgroundTransparency = 0.50
	confirmModal.Visible = false
	confirmModal.ZIndex = 100
	confirmModal.Parent = mainFrame

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 16)
	modalCorner.Parent = confirmModal

	local modalCard = Instance.new("Frame")
	modalCard.Name = "ModalCard"
	modalCard.AnchorPoint = Vector2.new(0.5, 0.5)
	modalCard.Position = UDim2.new(0.5, 0, 0.5, 0)
	modalCard.Size = UDim2.new(0, 360, 0, 180)
	modalCard.BackgroundColor3 = GeistColors.CardBg
	modalCard.ZIndex = 101
	modalCard.Parent = confirmModal

	local mcCorner = Instance.new("UICorner")
	mcCorner.CornerRadius = UDim.new(0, 14)
	mcCorner.Parent = modalCard

	local mcTitle = Instance.new("TextLabel")
	mcTitle.Size = UDim2.new(1, -32, 0, 24)
	mcTitle.Position = UDim2.new(0, 16, 0, 18)
	mcTitle.BackgroundTransparency = 1
	mcTitle.Text = "⚠️  Exit & Unload Script?"
	mcTitle.TextColor3 = GeistColors.ErrorRed
	mcTitle.Font = Enum.Font.GothamBold
	mcTitle.TextSize = 13
	mcTitle.TextXAlignment = Enum.TextXAlignment.Left
	mcTitle.ZIndex = 102
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
	mcDesc.ZIndex = 102
	mcDesc.Parent = modalCard

	local cancelExitBtn = Instance.new("TextButton")
	cancelExitBtn.Size = UDim2.new(0, 154, 0, 34)
	cancelExitBtn.Position = UDim2.new(0, 16, 1, -48)
	cancelExitBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
	cancelExitBtn.Text = "Batal (Cancel)"
	cancelExitBtn.TextColor3 = GeistColors.TextMain
	cancelExitBtn.Font = Enum.Font.GothamBold
	cancelExitBtn.TextSize = 10
	cancelExitBtn.ZIndex = 102
	cancelExitBtn.Parent = modalCard

	local cebCorner = Instance.new("UICorner")
	cebCorner.CornerRadius = UDim.new(0, 8)
	cebCorner.Parent = cancelExitBtn

	cancelExitBtn.MouseButton1Click:Connect(function()
		confirmModal.Visible = false
	end)

	local confirmExitBtn = Instance.new("TextButton")
	confirmExitBtn.Size = UDim2.new(0, 154, 0, 34)
	confirmExitBtn.Position = UDim2.new(1, -170, 1, -48)
	confirmExitBtn.BackgroundColor3 = GeistColors.ErrorRed
	confirmExitBtn.Text = "Tutup (Unload)"
	confirmExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmExitBtn.Font = Enum.Font.GothamBold
	confirmExitBtn.TextSize = 10
	confirmExitBtn.ZIndex = 102
	confirmExitBtn.Parent = modalCard

	local cfeCorner = Instance.new("UICorner")
	cfeCorner.CornerRadius = UDim.new(0, 8)
	cfeCorner.Parent = confirmExitBtn

	confirmExitBtn.MouseButton1Click:Connect(function()
		if cleanupScriptCallback then cleanupScriptCallback() end
	end)

	-- Window Control Listeners
	minimizeBtn.MouseButton1Click:Connect(function()
		Settings.IsMinimized = true
		mainFrame.Visible = false
		openIcon.Visible = true
	end)

	maximizeBtn.MouseButton1Click:Connect(function()
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
	end)

	closeBtn.MouseButton1Click:Connect(function()
		confirmModal.Visible = true
	end)

	openIcon.MouseButton1Click:Connect(function()
		Settings.IsMinimized = false
		mainFrame.Visible = true
		openIcon.Visible = false
	end)

	-- Window Dragging Handler
	local dragging, dragInput, dragStart, startPos
	local function updateInput(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	table.insert(UI.scriptConnections, titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end))

	table.insert(UI.scriptConnections, titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	local iconDragging, iconDragInput, iconDragStart, iconStartPos
	local function updateIconInput(input)
		local delta = input.Position - iconDragStart
		openIcon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
	end

	table.insert(UI.scriptConnections, openIcon.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			iconDragging = true
			iconDragStart = input.Position
			iconStartPos = openIcon.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then iconDragging = false end
			end)
		end
	end))

	table.insert(UI.scriptConnections, openIcon.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			iconDragInput = input
		end
	end))

	table.insert(UI.scriptConnections, UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			updateInput(input)
		elseif input == iconDragInput and iconDragging then
			updateIconInput(input)
		end
	end))

	table.insert(UI.scriptConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
end

return UI
