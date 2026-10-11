-- LocalScript RNGCollection em StarterPlayer > StarterPlayerScripts.
-- Usa o inventário confirmado pelo servidor; não desbloqueia nem equipa auras.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local inventory = ReplicatedStorage:WaitForChild("RNGRemotes"):WaitForChild("Inventory")
local gui = Instance.new("ScreenGui")
gui.Name = "RNGCollectionGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = player:WaitForChild("PlayerGui")
local function rounded(object)
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 12)
end
local function label(parent, position, size, fontSize)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Position = position
	object.Size = size
	object.Text = ""
	object.TextWrapped = true
	object.TextColor3 = Color3.new(1, 1, 1)
	object.Font = Enum.Font.GothamBold
	object.TextSize = fontSize
	object.Parent = parent
	return object
end
local function button(parent, text, position, size)
	local object = Instance.new("TextButton")
	object.Text = text
	object.Position = position
	object.Size = size
	object.Font = Enum.Font.GothamBold
	object.TextSize = 16
	object.TextColor3 = Color3.new(1, 1, 1)
	object.BackgroundColor3 = Color3.fromRGB(55, 65, 110)
	object.Parent = parent
	rounded(object)
	return object
end
local toggle =
	button(gui, "COLEÇÃO", UDim2.new(0, 15, 0.5, 40), UDim2.fromOffset(145, 50))
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.92, 0.82)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
rounded(panel)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(540, 540)
local heading = label(panel, UDim2.fromOffset(12, 8), UDim2.new(1, -70, 0, 40), 22)
heading.Text = "Coleção de auras"
local close = button(panel, "X", UDim2.new(1, -48, 0, 10), UDim2.fromOffset(36, 36))
local progress = label(panel, UDim2.fromOffset(12, 52), UDim2.new(1, -24, 0, 28), 16)
progress.Text = "Carregando coleção..."
local track = Instance.new("Frame")
track.Position = UDim2.fromOffset(12, 86)
track.Size = UDim2.new(1, -24, 0, 10)
track.BackgroundColor3 = Color3.fromRGB(45, 50, 75)
track.BorderSizePixel = 0
track.Parent = panel
rounded(track)
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(100, 200, 150)
fill.BorderSizePixel = 0
fill.Parent = track
rounded(fill)
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 108)
list.Size = UDim2.new(1, -24, 1, -162)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local footer = label(panel, UDim2.new(0, 12, 1, -44), UDim2.new(1, -24, 0, 36), 13)
footer.Text = "Chances base • Equipe suas descobertas pelo INVENTÁRIO."
local rows = {}
local cached
local nextSync = 0
local function formatNumber(number)
	local value = tostring(number)
	while true do
		local changed
		value, changed = value:gsub("^(%d+)(%d%d%d)", "%1.%2")
		if changed == 0 then
			return value
		end
	end
end
local function render(data)
	cached = data
	local discovered = 0
	local present = {}
	for index, item in ipairs(data.Catalog) do
		present[item.Id] = true
		local owned = data.Owned[item.Id] == true
		if owned then
			discovered += 1
		end
		local row = rows[item.Id]
		if not row then
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, -8, 0, 82)
			frame.Parent = list
			rounded(frame)
			local text =
				label(frame, UDim2.fromOffset(12, 4), UDim2.new(1, -24, 1, -8), 15)
			text.TextXAlignment = Enum.TextXAlignment.Left
			row = { Frame = frame, Text = text }
			rows[item.Id] = row
		end
		row.Frame.LayoutOrder = index
		row.Frame.BackgroundColor3 = owned and Color3.fromRGB(35, 65, 55)
			or Color3.fromRGB(35, 40, 60)
		local name = item.Secret and not owned and "??? — Aura secreta" or item.Name
		local status = owned and "DESCOBERTA" or "AINDA NÃO DESCOBERTA"
		if owned and data.Equipped == item.Id then
			status ..= " • EQUIPADA"
		end
		row.Text.Text = name .. "\n1 em " .. formatNumber(item.Odds) .. "\n" .. status
		row.Text.TextColor3 = owned and item.Color or Color3.fromRGB(160, 165, 185)
	end
	for id, row in pairs(rows) do
		if not present[id] then
			row.Frame:Destroy()
			rows[id] = nil
		end
	end
	local total = #data.Catalog
	local percent = total > 0 and math.floor(discovered / total * 100) or 0
	progress.Text = discovered
		.. "/"
		.. total
		.. " descobertas • "
		.. percent
		.. "% • Faltam "
		.. (total - discovered)
	fill.Size = UDim2.fromScale(total > 0 and discovered / total or 0, 1)
end
local function sync()
	if player:GetAttribute("RNGReady") ~= true or os.clock() < nextSync then
		return
	end
	nextSync = os.clock() + 1.1
	inventory:FireServer()
end
inventory.OnClientEvent:Connect(render)
close.Activated:Connect(function()
	panel.Visible = false
end)
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		if cached then
			render(cached)
		end
		sync()
	end
end)
player:GetAttributeChangedSignal("RNGReady"):Connect(sync)
sync()
