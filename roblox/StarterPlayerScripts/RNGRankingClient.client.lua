-- LocalScript RNGRankingClient em StarterPlayerScripts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RNGRankings")
local gui = Instance.new("ScreenGui")
gui.Name = "RNGRankingGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")
local function text(parent, value, position, size, fontSize)
	local object = Instance.new("TextLabel")
	object.Text = value
	object.Position = position
	object.Size = size
	object.BackgroundTransparency = 1
	object.TextColor3 = Color3.new(1, 1, 1)
	object.Font = Enum.Font.GothamBold
	object.TextSize = fontSize or 16
	object.TextWrapped = true
	object.Parent = parent
	return object
end
local function button(parent, value, position, size)
	local object = Instance.new("TextButton")
	object.Text = value
	object.Position = position
	object.Size = size
	object.TextColor3 = Color3.new(1, 1, 1)
	object.Font = Enum.Font.GothamBold
	object.TextSize = 14
	object.BackgroundColor3 = Color3.fromRGB(55, 65, 110)
	object.Parent = parent
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 10)
	return object
end
local toggle =
	button(gui, "RANKING", UDim2.new(0, 15, 0.5, 105), UDim2.fromOffset(145, 50))
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.94, 0.84)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(620, 540)
text(
	panel,
	"RANKING GLOBAL • TOP 20",
	UDim2.fromOffset(12, 8),
	UDim2.new(1, -70, 0, 40),
	20
)
local close = button(panel, "X", UDim2.new(1, -48, 0, 10), UDim2.fromOffset(36, 36))
local bestTab =
	button(panel, "MELHORES AURAS", UDim2.new(0.04, 0, 0, 55), UDim2.new(0.45, 0, 0, 40))
local rollsTab =
	button(panel, "TOTAL DE ROLLS", UDim2.new(0.51, 0, 0, 55), UDim2.new(0.45, 0, 0, 40))
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 110)
list.Size = UDim2.new(1, -24, 1, -185)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local footer = text(
	panel,
	"Carregando ranking...",
	UDim2.new(0, 12, 1, -65),
	UDim2.new(1, -24, 0, 55),
	13
)
local rows, data = {}, nil
local selected = "Best"
local nextRequest = 0
local function number(value)
	local result = tostring(value)
	while true do
		local changed
		result, changed = result:gsub("^(%d+)(%d%d%d)", "%1.%2")
		if changed == 0 then
			return result
		end
	end
end
local function render()
	for _, row in ipairs(rows) do
		row:Destroy()
	end
	rows = {}
	bestTab.BackgroundColor3 = selected == "Best" and Color3.fromRGB(110, 75, 170)
		or Color3.fromRGB(55, 65, 110)
	rollsTab.BackgroundColor3 = selected == "Rolls" and Color3.fromRGB(110, 75, 170)
		or Color3.fromRGB(55, 65, 110)
	if not data or not data.Ready then
		footer.Text = "Ranking indisponível ou carregando. Tente reabrir em um minuto."
		return
	end
	local entries = data[selected]
	for index, entry in ipairs(entries) do
		local description = selected == "Best"
				and (entry.Aura .. " • 1 em " .. number(entry.Value))
			or (number(entry.Value) .. " rolagens")
		local row = text(
			list,
			"#" .. entry.Rank .. "  " .. entry.Name .. "\n" .. description,
			UDim2.new(),
			UDim2.new(1, -8, 0, 60),
			16
		)
		row.LayoutOrder = index
		row.BackgroundTransparency = 0
		row.BackgroundColor3 = entry.UserId == player.UserId and Color3.fromRGB(
			45,
			90,
			70
		) or Color3.fromRGB(35, 40, 65)
		if index <= 3 then
			row.TextColor3 = Color3.fromRGB(255, 220, 110)
		end
		table.insert(rows, row)
	end
	local age = math.max(0, DateTime.now().UnixTimestamp - data.UpdatedAt)
	footer.Text = (#entries == 0 and "Nenhum jogador classificado ainda. " or "")
		.. "Atualizado há "
		.. age
		.. "s • Atualização periódica, normalmente em 1–2 minutos."
end
local function request()
	if os.clock() < nextRequest then
		return
	end
	nextRequest = os.clock() + 2.1
	event:FireServer()
end
bestTab.Activated:Connect(function()
	selected = "Best"
	list.CanvasPosition = Vector2.new(0, 0)
	render()
end)
rollsTab.Activated:Connect(function()
	selected = "Rolls"
	list.CanvasPosition = Vector2.new(0, 0)
	render()
end)
close.Activated:Connect(function()
	panel.Visible = false
end)
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		request()
	end
end)
event.OnClientEvent:Connect(function(snapshot)
	data = snapshot
	render()
end)
request()

-- Regras compartilhadas para computador e celular.
local UIConfig = require(ReplicatedStorage:WaitForChild("RNGUIConfig"))
UIConfig.RegisterPanel("ranking", gui, panel, toggle, close, 620, 540, 3)
