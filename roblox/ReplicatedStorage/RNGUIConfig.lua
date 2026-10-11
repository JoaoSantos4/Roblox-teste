-- ModuleScript RNGUIConfig em ReplicatedStorage. Usado somente pelos LocalScripts.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Config = {
	CompactWidth = 900,
	RollMaxWidth = 380,
	CardMaxWidth = 480,
	RollHeight = 104,
	PanelSizes = {
		inventory = Vector2.new(480, 500),
		collection = Vector2.new(540, 540),
		ranking = Vector2.new(620, 540),
		quests = Vector2.new(540, 520),
		shop = Vector2.new(520, 480),
		status = Vector2.new(520, 540),
		settings = Vector2.new(560, 540),
	},
	CompactHeight = 520,
	Margin = 12,
	ButtonHeight = 48,
	Font = Enum.Font.GothamBold,
	MinTextSize = 12,
	PanelColor = Color3.fromRGB(20, 24, 40),
	ButtonColor = Color3.fromRGB(55, 65, 110),
	MobileRollBottom = 150,
	DesktopRollBottom = 24,
}
local entries = {}
local rollWidgets
local menuGui, menuButton, drawer, grid
local cameraConnection
local initialized = false
local playerGui
local function rounded(object)
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 12)
end
-- Função separada para testar as regras sem depender de um dispositivo real.
function Config.Layout(width, height, touchOnly, insetX, insetY)
	local usableWidth = math.max(1, width - (insetX or 0))
	local usableHeight = math.max(1, height - (insetY or 0))
	local compact = width < Config.CompactWidth
		or height < Config.CompactHeight
		or touchOnly
	local landscape = usableWidth > usableHeight
	return {
		Width = usableWidth,
		Height = usableHeight,
		Compact = compact,
		RollWidth = math.min(
			Config.RollMaxWidth,
			math.max(
				160,
				usableWidth - (compact and landscape and 320 or Config.Margin * 2)
			)
		),
		RollBottom = compact and (landscape and 72 or Config.MobileRollBottom)
			or Config.DesktopRollBottom,
	}
end
local function viewport()
	local camera = Workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	if size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(1280, 720)
	end
	local topLeft, bottomRight = GuiService:GetGuiInset()
	local touchOnly = UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled
	return Config.Layout(
		size.X,
		size.Y,
		touchOnly,
		topLeft.X + bottomRight.X,
		topLeft.Y + bottomRight.Y
	),
		topLeft
end
local function style(object)
	if not (object:IsA("TextLabel") or object:IsA("TextButton")) then
		return
	end
	object.Font = Config.Font
	object.TextWrapped = true
	if not object:FindFirstChild("RNGTextBounds") then
		local limit = Instance.new("UITextSizeConstraint")
		limit.Name = "RNGTextBounds"
		limit.MinTextSize = math.min(Config.MinTextSize, object.TextSize)
		limit.MaxTextSize = math.max(limit.MinTextSize, object.TextSize)
		limit.Parent = object
	end
	object.TextScaled = true
end
local function styleGui(gui)
	for _, object in ipairs(gui:GetDescendants()) do
		style(object)
	end
	gui.DescendantAdded:Connect(style)
end
local function closeOtherPanels(current)
	for _, entry in ipairs(entries) do
		if entry.Panel ~= current then
			entry.Panel.Visible = false
		end
	end
	if drawer then
		drawer.Visible = false
	end
end
function Config.CloseAll()
	closeOtherPanels(nil)
end
local function update()
	local layout, topLeft = viewport()
	if menuButton then
		menuButton.Visible = layout.Compact
		if not layout.Compact then
			drawer.Visible = false
		end
		local width = math.min(360, math.max(160, layout.Width - Config.Margin * 2))
		drawer.Size =
			UDim2.fromOffset(width, math.min(350, math.max(100, layout.Height - 90)))
		grid.CellSize = UDim2.new(
			width >= 320 and 0.5 or 1,
			width >= 320 and -5 or 0,
			0,
			Config.ButtonHeight
		)
	end
	for _, entry in ipairs(entries) do
		local panel = entry.Panel
		local maximum = Config.PanelSizes[entry.Id]
			or Vector2.new(entry.Width, entry.Height)
		for _, constraint in ipairs(panel:GetChildren()) do
			if constraint:IsA("UISizeConstraint") then
				constraint.MaxSize = maximum
			end
		end
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		local width = math.min(maximum.X, math.max(160, layout.Width - Config.Margin * 2))
		local height =
			math.min(maximum.Y, math.max(180, layout.Height - Config.Margin * 2))
		panel.Size = UDim2.fromOffset(width, height)
		panel.BackgroundColor3 = Config.PanelColor
		if entry.Gui.IgnoreGuiInset then
			panel.Position = UDim2.fromOffset(
				topLeft.X + layout.Width / 2,
				topLeft.Y + layout.Height / 2
			)
		else
			panel.Position = UDim2.fromScale(0.5, 0.5)
		end
		if entry.Close then
			entry.Close.Position = UDim2.new(1, -48, 0, 8)
			entry.Close.Size = UDim2.fromOffset(40, 40)
			entry.Close.BackgroundColor3 = Config.ButtonColor
		end
		if entry.Toggle then
			entry.Toggle.BackgroundColor3 = Config.ButtonColor
			if layout.Compact then
				entry.Toggle.Parent = drawer
				entry.Toggle.Size = UDim2.fromOffset(150, Config.ButtonHeight)
				entry.Toggle.LayoutOrder = entry.Order
			else
				entry.Toggle.Parent = entry.Parent
				entry.Toggle.Position = entry.Position
				entry.Toggle.Size = entry.Size
			end
		end
	end
	if rollWidgets then
		rollWidgets.Controls.Size = UDim2.fromOffset(layout.RollWidth, Config.RollHeight)
		rollWidgets.Controls.Position = UDim2.new(0.5, 0, 1, -layout.RollBottom)
		rollWidgets.Card.Size = UDim2.fromOffset(
			math.min(Config.CardMaxWidth, layout.Width - Config.Margin * 2),
			math.min(170, layout.Height * 0.38)
		)
		rollWidgets.Card.Position = UDim2.fromScale(0.5, layout.Compact and 0.38 or 0.5)
	end
end
local function createNavigation()
	menuGui = Instance.new("ScreenGui")
	menuGui.Name = "RNGNavigationGui"
	menuGui.ResetOnSpawn = false
	menuGui.DisplayOrder = 40
	menuGui.Parent = playerGui
	menuButton = Instance.new("TextButton")
	menuButton.Name = "MenuButton"
	menuButton.Text = "☰ MENU"
	menuButton.Font = Config.Font
	menuButton.TextSize = 16
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.BackgroundColor3 = Config.ButtonColor
	menuButton.Position = UDim2.fromOffset(Config.Margin, Config.Margin)
	menuButton.Size = UDim2.fromOffset(112, 44)
	menuButton.Parent = menuGui
	rounded(menuButton)
	drawer = Instance.new("ScrollingFrame")
	drawer.Name = "MenuDrawer"
	drawer.Position = UDim2.fromOffset(Config.Margin, 64)
	drawer.Size = UDim2.fromOffset(360, 350)
	drawer.BackgroundColor3 = Config.PanelColor
	drawer.BorderSizePixel = 0
	drawer.ScrollBarThickness = 5
	drawer.CanvasSize = UDim2.new()
	drawer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	drawer.Visible = false
	drawer.Parent = menuGui
	rounded(drawer)
	local padding = Instance.new("UIPadding", drawer)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	grid = Instance.new("UIGridLayout", drawer)
	grid.CellPadding = UDim2.fromOffset(6, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	menuButton.Activated:Connect(function()
		local opening = not drawer.Visible
		if opening then
			Config.CloseAll()
		end
		drawer.Visible = opening
	end)
end
local function bindCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	if Workspace.CurrentCamera then
		cameraConnection = Workspace.CurrentCamera
			:GetPropertyChangedSignal("ViewportSize")
			:Connect(update)
	end
	update()
end
local function init()
	if initialized then
		return
	end
	initialized = true
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	createNavigation()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(update)
	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(update)
	UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(update)
	bindCamera()
end
function Config.RegisterPanel(id, gui, panel, toggle, close, width, height, order)
	init()
	for _, entry in ipairs(entries) do
		assert(entry.Id ~= id, "Menu RNG duplicado: " .. id)
	end
	local entry = {
		Id = id,
		Gui = gui,
		Panel = panel,
		Toggle = toggle,
		Close = close,
		Width = width,
		Height = height,
		Order = order or #entries + 1,
		Parent = toggle and toggle.Parent,
		Position = toggle and toggle.Position,
		Size = toggle and toggle.Size,
	}
	table.insert(entries, entry)
	styleGui(gui)
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible then
			closeOtherPanels(panel)
		end
	end)
	if toggle then
		toggle.Activated:Connect(function()
			drawer.Visible = false
		end)
	end
	update()
end
function Config.RegisterRoll(gui, controls, card)
	init()
	rollWidgets = { Controls = controls, Card = card }
	styleGui(gui)
	update()
end
function Config.Refresh()
	if initialized then
		update()
	end
end
return Config
