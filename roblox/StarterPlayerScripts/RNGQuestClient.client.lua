-- LocalScript RNGQuestClient em StarterPlayerScripts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RNGQuestRemotes"):WaitForChild("Daily")
local gui = Instance.new("ScreenGui")
gui.Name = "RNGQuestsGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")
local function rounded(object)
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 10)
end
local function text(parent, position, size, fontSize)
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Position, value.Size = position, size
	value.Font = Enum.Font.GothamBold
	value.TextSize = fontSize
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextWrapped = true
	value.Text = ""
	value.Parent = parent
	return value
end
local function button(parent, label, position, size)
	local value = Instance.new("TextButton")
	value.Position, value.Size = position, size
	value.Text = label
	value.Font = Enum.Font.GothamBold
	value.TextSize = 14
	value.TextColor3 = Color3.new(1, 1, 1)
	value.BackgroundColor3 = Color3.fromRGB(65, 85, 150)
	value.Parent = parent
	rounded(value)
	return value
end
local coins = text(gui, UDim2.new(0.5, -120, 0, 12), UDim2.fromOffset(240, 36), 22)
coins.Text = "Moedas: carregando..."
coins.TextColor3 = Color3.fromRGB(255, 220, 100)
local toggle =
	button(gui, "MISSÕES", UDim2.new(1, -140, 0.5, -25), UDim2.fromOffset(125, 50))
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.94, 0.86)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
rounded(panel)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(540, 520)
text(panel, UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.78, 0.1), 22).Text =
	"Missões e recompensas"
local close =
	button(panel, "X", UDim2.fromScale(0.88, 0.025), UDim2.fromScale(0.08, 0.08))
close.Activated:Connect(function()
	panel.Visible = false
end)
local tabs = {}
for index, entry in ipairs({
	{ "daily", "Diárias" },
	{ "weekly", "Semanais" },
	{ "monthly", "Mensais" },
}) do
	tabs[entry[1]] = button(
		panel,
		entry[2],
		UDim2.fromScale(0.04 + (index - 1) * 0.31, 0.13),
		UDim2.fromScale(0.29, 0.08)
	)
end
local reset = text(panel, UDim2.fromScale(0.04, 0.22), UDim2.fromScale(0.92, 0.07), 13)
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromScale(0.04, 0.31)
list.Size = UDim2.fromScale(0.92, 0.55)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local message = text(panel, UDim2.fromScale(0.04, 0.89), UDim2.fromScale(0.92, 0.09), 13)
local data, request
local selected = "daily"
local pending, generation, nextRequest = false, 0, 0
local rows = {}
local function clearRows()
	for _, row in pairs(rows) do
		row.Frame:Destroy()
	end
	table.clear(rows)
	list.CanvasPosition = Vector2.new(0, 0)
end
local function render()
	for scope, tab in pairs(tabs) do
		tab.BackgroundColor3 = scope == selected and Color3.fromRGB(110, 75, 170)
			or Color3.fromRGB(55, 65, 110)
	end
	if not data or not data.Ready then
		return
	end
	coins.Text = "Moedas: " .. data.Coins
	local period = data.Periods[selected]
	for index, quest in ipairs(period.Missions) do
		local row = rows[quest.Id]
		if not row then
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, -8, 0, 105)
			frame.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
			frame.Parent = list
			rounded(frame)
			local label =
				text(frame, UDim2.fromScale(0.025, 0.04), UDim2.fromScale(0.67, 0.92), 13)
			label.TextXAlignment = Enum.TextXAlignment.Left
			local claim = button(
				frame,
				"RESGATAR",
				UDim2.fromScale(0.72, 0.3),
				UDim2.fromScale(0.25, 0.4)
			)
			claim.TextSize = 12
			local scope, id = selected, quest.Id
			claim.Activated:Connect(function()
				if claim.Active and data and data.Ready then
					request("claim", scope, id, data.Periods[scope].Key)
				end
			end)
			row = { Frame = frame, Label = label, Button = claim }
			rows[quest.Id] = row
		end
		row.Frame.LayoutOrder = index
		row.Label.Text = quest.Title
			.. "\n"
			.. quest.Description
			.. "\n"
			.. quest.ProgressLabel
			.. " • +"
			.. quest.Reward
			.. " moedas"
		row.Button.Active = not pending
			and not quest.Claimed
			and quest.Progress >= quest.Goal
		row.Button.AutoButtonColor = row.Button.Active
		row.Button.Text = quest.Claimed and "RESGATADO"
			or (
				pending and "SALVANDO..."
				or (quest.Progress >= quest.Goal and "RESGATAR" or "EM CURSO")
			)
		row.Button.BackgroundColor3 = row.Button.Active and Color3.fromRGB(40, 130, 90)
			or Color3.fromRGB(55, 65, 110)
	end
end
request = function(action, scope, id, key)
	if os.clock() < nextRequest then
		return
	end
	if action == "claim" and (pending or not data or not data.Ready) then
		return
	end
	nextRequest = os.clock() + 0.6
	if action == "claim" then
		pending = true
		generation += 1
		local current = generation
		message.Text = "Salvando recompensa..."
		render()
		task.delay(12, function()
			if current == generation and pending then
				pending = false
				message.Text = "Sem confirmação. Reabra o menu e tente novamente."
				render()
			end
		end)
	end
	event:FireServer(action, scope, id, key)
end
for scope, tab in pairs(tabs) do
	local tabScope = scope
	tab.Activated:Connect(function()
		if selected ~= tabScope then
			selected = tabScope
			clearRows()
			render()
		end
	end)
end
event.OnClientEvent:Connect(function(snapshot)
	data = snapshot
	if snapshot.Message then
		message.Text = snapshot.Message
		pending = false
		generation += 1
	end
	render()
end)
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		request("sync")
	end
end)
player:GetAttributeChangedSignal("RNGQuestsReady"):Connect(function()
	request("sync")
end)
render()
request("sync")
task.spawn(function()
	while gui.Parent do
		if data and data.Ready then
			local remaining =
				math.max(0, data.Periods[selected].ResetAt - DateTime.now().UnixTimestamp)
			reset.Text = string.format(
				"Renova em %dd %02d:%02d:%02d",
				math.floor(remaining / 86400),
				math.floor(remaining / 3600) % 24,
				math.floor(remaining / 60) % 60,
				remaining % 60
			)
			if remaining == 0 and panel.Visible then
				request("sync")
			end
		end
		task.wait(1)
	end
end)
