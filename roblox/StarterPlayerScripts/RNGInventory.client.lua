-- NOVO LocalScript RNGInventory em StarterPlayer > StarterPlayerScripts.
-- Mantenha o RNGClient existente para o botão ROLL e a animação.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RNGRemotes")
local inventory = remotes:WaitForChild("Inventory")
local equip = remotes:WaitForChild("Equip")
local gui = Instance.new("ScreenGui")
gui.Name = "RNGInventoryGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")
local function button(text, parent)
    local value = Instance.new("TextButton")
    value.Text = text
    value.Font = Enum.Font.GothamBold
    value.TextSize = 16
    value.TextColor3 = Color3.new(1, 1, 1)
    value.BackgroundColor3 = Color3.fromRGB(55, 65, 110)
    value.Parent = parent
    Instance.new("UICorner", value).CornerRadius = UDim.new(0, 10)
    return value
end
local toggle = button("INVENTÁRIO", gui)
toggle.Position = UDim2.new(0, 15, 0.5, -25)
toggle.Size = UDim2.fromOffset(145, 50)
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.9, 0.75)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(480, 500)
local heading = Instance.new("TextLabel")
heading.BackgroundTransparency = 1
heading.Position = UDim2.fromOffset(12, 8)
heading.Size = UDim2.new(1, -70, 0, 40)
heading.Text = "Suas auras"
heading.TextColor3 = Color3.new(1, 1, 1)
heading.Font = Enum.Font.GothamBold
heading.TextSize = 22
heading.TextWrapped = true
heading.Parent = panel
local close = button("X", panel)
close.Position = UDim2.new(1, -48, 0, 10)
close.Size = UDim2.fromOffset(36, 36)
close.Activated:Connect(function() panel.Visible = false end)
local remove = button("REMOVER AURA EQUIPADA", panel)
remove.Position = UDim2.new(0, 12, 1, -52)
remove.Size = UDim2.new(1, -24, 0, 40)
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 60)
list.Size = UDim2.new(1, -24, 1, -125)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local cached
local nextEquip = 0
local function requestEquip(id)
    if player:GetAttribute("RNGReady") ~= true or os.clock() < nextEquip then return end
    nextEquip = os.clock() + 0.4
    equip:FireServer(id)
end
remove.Activated:Connect(function() requestEquip("") end)
local function render(data)
    cached = data
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local count = 0
    for index, item in ipairs(data.Catalog) do
        if data.Owned[item.Id] then
            count += 1
            local selected = data.Equipped == item.Id
            local row = button(item.Name .. " • 1 em " .. item.Odds
                .. (selected and " • EQUIPADA" or " • EQUIPAR"), list)
            row.Size = UDim2.new(1, -8, 0, 56)
            row.LayoutOrder = index
            row.TextColor3 = item.Color
            row.TextWrapped = true
            row.BackgroundColor3 = selected and Color3.fromRGB(45, 90, 70) or Color3.fromRGB(40, 45, 70)
            row.Activated:Connect(function() requestEquip(item.Id) end)
        end
    end
    heading.Text = count > 0 and ("Suas auras (" .. count .. ")") or "Role para conseguir auras!"
    remove.Active = data.Equipped ~= nil
    remove.AutoButtonColor = remove.Active
end
inventory.OnClientEvent:Connect(render)
toggle.Activated:Connect(function()
    panel.Visible = not panel.Visible
    if panel.Visible then
        if cached then render(cached) else heading.Text = "Carregando inventário..." end
        inventory:FireServer()
    end
end)
local function ready()
    if player:GetAttribute("RNGReady") == true then inventory:FireServer() end
end
player:GetAttributeChangedSignal("RNGReady"):Connect(ready)
ready()

-- Regras compartilhadas para computador e celular.
local UIConfig = require(ReplicatedStorage:WaitForChild("RNGUIConfig"))
UIConfig.RegisterPanel("inventory", gui, panel, toggle, close, 480, 500, 1)
