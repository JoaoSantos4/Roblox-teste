-- LocalScript RNGShopClient em StarterPlayerScripts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RNGQuestRemotes"):WaitForChild("Shop")
local gui = Instance.new("ScreenGui")
gui.Name = "RNGShopGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")
local function label(parent, text, y, height)
	local object = Instance.new("TextLabel")
	object.BackgroundTransparency = 1
	object.Size = UDim2.new(1, -24, 0, height)
	object.Position = UDim2.fromOffset(12, y)
	object.Text = text
	object.TextWrapped = true
	object.TextColor3 = Color3.new(1, 1, 1)
	object.Font = Enum.Font.GothamBold
	object.TextSize = 16
	object.Parent = parent
	return object
end
local function button(parent, text, position, size)
	local object = Instance.new("TextButton")
	object.Text = text
	object.Position = position
	object.Size = size
	object.BackgroundColor3 = Color3.fromRGB(65, 85, 150)
	object.TextColor3 = Color3.new(1, 1, 1)
	object.Font = Enum.Font.GothamBold
	object.TextSize = 15
	object.Parent = parent
	Instance.new("UICorner", object).CornerRadius = UDim.new(0, 10)
	return object
end
local toggle = button(gui, "LOJA", UDim2.new(1, -140, 0.5, 40), UDim2.fromOffset(125, 50))
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.92, 0.85)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(520, 480)
local title = label(panel, "LOJA — carregando...", 10, 40)
local close = button(panel, "X", UDim2.new(1, -44, 0, 12), UDim2.fromOffset(32, 32))
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 12, 0, 60)
list.Size = UDim2.new(1, -24, 1, -145)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollBarThickness = 5
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local footer = label(panel, "Compras confirmadas e salvas no servidor.", 0, 70)
footer.Position = UDim2.new(0, 12, 1, -75)
local rows = {}
local snapshot
local pending = false
local generation = 0
local nextRequest = 0
local function request(action, id)
	if os.clock() < nextRequest or (action == "buy" and pending) then
		return
	end
	nextRequest = os.clock() + 1.1
	if action == "buy" then
		pending = true
		generation += 1
		local token = generation
		footer.Text = "Salvando compra..."
		task.delay(15, function()
			if pending and token == generation then
				pending = false
				footer.Text = "Sem confirmação. Reabra a loja para conferir o saldo."
			end
		end)
	end
	event:FireServer(action, id)
end
local function render()
	if not snapshot then
		return
	end
	title.Text = "LOJA • " .. snapshot.Coins .. " moedas"
	local now = DateTime.now().UnixTimestamp
	for index, product in ipairs(snapshot.Products) do
		local row = rows[product.Id]
		if not row then
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, -8, 0, 140)
			frame.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
			frame.LayoutOrder = index
			frame.Parent = list
			local description = label(frame, "", 4, 70)
			local buy = button(
				frame,
				"COMPRAR",
				UDim2.new(0, 12, 0, 85),
				UDim2.new(1, -24, 0, 42)
			)
			local id = product.Id
			buy.Activated:Connect(function()
				if buy.Active then
					request("buy", id)
				end
			end)
			row = { Text = description, Button = buy }
			rows[product.Id] = row
		end
		local expires = product.Id == "luck" and snapshot.Shop.LuckUntil
			or (product.Id == "speed" and snapshot.Shop.SpeedUntil or 0)
		local maxed = product.Id == "income" and snapshot.Shop.Level >= 5
		local active = expires > now
		row.Text.Text = product.Name .. "\n" .. product.Description
		if product.Id == "income" then
			row.Text.Text ..= "\nNível: " .. snapshot.Shop.Level .. "/5"
		end
		row.Button.Active = not pending
			and not maxed
			and not active
			and snapshot.Coins >= product.Price
		row.Button.AutoButtonColor = row.Button.Active
		row.Button.Text = maxed and "NÍVEL MÁXIMO"
			or (
				active and ("ATIVA • " .. (expires - now) .. "s")
				or (
					pending and "AGUARDE..."
					or ("COMPRAR • " .. product.Price .. " moedas")
				)
			)
	end
end
event.OnClientEvent:Connect(function(data)
	snapshot = data
	if data.Message then
		pending = false
		generation += 1
		footer.Text = data.Message
	end
	render()
end)
close.Activated:Connect(function()
	panel.Visible = false
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
request("sync")
task.spawn(function()
	while gui.Parent do
		if panel.Visible then
			render()
		end
		task.wait(1)
	end
end)

-- Regras compartilhadas para computador e celular.
local UIConfig = require(ReplicatedStorage:WaitForChild("RNGUIConfig"))
UIConfig.RegisterPanel("shop", gui, panel, toggle, close, 520, 480, 5)
