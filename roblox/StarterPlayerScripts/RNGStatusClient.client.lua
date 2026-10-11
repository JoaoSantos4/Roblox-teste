-- LocalScript RNGStatusClient em StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RNGRemotes"):WaitForChild("Status")
local gui = Instance.new("ScreenGui")
gui.Name = "RNGStatusGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 35
gui.Parent = player:WaitForChild("PlayerGui")
local function text(parent, value, position, size, fontSize)
	local label = Instance.new("TextLabel")
	label.Text = value
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = fontSize
	label.TextWrapped = true
	label.Parent = parent
	return label
end
local function button(parent, value, position, size)
	local object = Instance.new("TextButton")
	object.Text = value
	object.Position = position
	object.Size = size
	object.Font = Enum.Font.GothamBold
	object.TextSize = 16
	object.TextColor3 = Color3.new(1, 1, 1)
	object.BackgroundColor3 = Color3.fromRGB(55, 65, 110)
	object.Parent = parent
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 12)
	return object
end
local toggle =
	button(gui, "STATUS", UDim2.new(1, -140, 0.5, 105), UDim2.fromOffset(125, 50))
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.92, 0.84)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(520, 540)
text(panel, "SEUS STATUS", UDim2.fromOffset(12, 8), UDim2.new(1, -70, 0, 40), 22)
local close = button(panel, "X", UDim2.new(1, -48, 0, 10), UDim2.fromOffset(36, 36))
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 60)
list.Size = UDim2.new(1, -24, 1, -115)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local labels = {}
local fields = {
	"Tempo total",
	"Tempo nesta sessão",
	"Rolls totais",
	"Rolls nesta sessão",
	"Melhor aura",
	"Aura equipada",
	"Coleção",
	"Moedas",
	"Melhoria de moedas",
	"Poção de sorte",
	"Poção de velocidade",
}
for index, name in ipairs(fields) do
	local row =
		text(list, name .. ": carregando...", UDim2.new(), UDim2.new(1, -8, 0, 48), 15)
	row.LayoutOrder = index
	row.BackgroundTransparency = 0
	row.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	labels[index] = row
end
local footer = text(
	panel,
	"Dados contabilizados pelo servidor.",
	UDim2.new(0, 12, 1, -45),
	UDim2.new(1, -24, 0, 35),
	12
)
local cached, receivedAt
local nextRequest = 0
local function duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format(
		"%dd %02dh %02dm %02ds",
		math.floor(seconds / 86400),
		math.floor(seconds / 3600) % 24,
		math.floor(seconds / 60) % 60,
		seconds % 60
	)
end
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
local function potion(expires)
	local seconds = math.max(0, expires - DateTime.now().UnixTimestamp)
	return seconds > 0 and ("Ativa • " .. duration(seconds)) or "Inativa"
end
local function render()
	if not cached or not cached.Ready then
		footer.Text = "Carregando status..."
		return
	end
	-- Só antecipa a exibição entre snapshots. O tempo salvo é calculado no servidor.
	local elapsed = math.min(10, math.max(0, os.clock() - receivedAt))
	local economy = cached.Economy
	local values = {
		duration(cached.PlaySeconds + elapsed),
		duration(cached.SessionSeconds + elapsed),
		number(cached.TotalRolls),
		number(cached.SessionRolls),
		cached.BestName
			.. (cached.BestOdds > 0 and (" • 1 em " .. number(cached.BestOdds)) or ""),
		cached.Equipped,
		cached.Discovered .. "/" .. cached.CatalogTotal .. " descobertas",
		economy.Ready and number(economy.Coins) or "Indisponível",
		economy.Ready
				and (economy.Level .. "/5 • " .. (1 + economy.Level) .. " moedas por roll")
			or "Indisponível",
		economy.Ready and potion(economy.LuckUntil) or "Indisponível",
		economy.Ready and potion(economy.SpeedUntil) or "Indisponível",
	}
	for index, value in ipairs(values) do
		labels[index].Text = fields[index] .. ": " .. value
	end
	footer.Text =
		"Tempo total contado desde esta atualização • Atualização a cada 5s."
end
local function request()
	if player:GetAttribute("RNGReady") ~= true or os.clock() < nextRequest then
		return
	end
	nextRequest = os.clock() + 5
	event:FireServer()
end
event.OnClientEvent:Connect(function(snapshot)
	cached = snapshot
	receivedAt = os.clock()
	render()
end)
close.Activated:Connect(function()
	panel.Visible = false
end)
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		render()
		request()
	end
end)
player:GetAttributeChangedSignal("RNGReady"):Connect(function()
	if panel.Visible then
		request()
	end
end)
task.spawn(function()
	while gui.Parent do
		if panel.Visible then
			request()
			render()
		end
		task.wait(1)
	end
end)
