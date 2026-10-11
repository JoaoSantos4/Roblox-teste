-- LocalScript RNGClient em StarterPlayer > StarterPlayerScripts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RNGRemotes")
local roll = remotes:WaitForChild("Roll")
local announcement = remotes:WaitForChild("Announcement")
local SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
local PREVIEWS = {
    { Name = "Comum", Color = Color3.fromRGB(220, 220, 220) },
    { Name = "Incomum", Color = Color3.fromRGB(90, 230, 130) },
    { Name = "Raro", Color = Color3.fromRGB(90, 160, 255) },
    { Name = "Épico", Color = Color3.fromRGB(190, 100, 255) },
    { Name = "Lendário", Color = Color3.fromRGB(255, 200, 50) },
    { Name = "Divino", Color = Color3.fromRGB(255, 120, 220) },
}
local visualRandom = Random.new()
local gui = Instance.new("ScreenGui")
gui.Name = "RNGGui"
gui.ResetOnSpawn = false
-- O inventário fica acima desta interface.
gui.Parent = player:WaitForChild("PlayerGui")
local sound = Instance.new("Sound")
sound.Name = "RNGRollSound"
sound.SoundId = SOUND_ID
sound.Parent = gui
local function playSound(volume, speed)
    sound:Stop()
    if player:GetAttribute("RNGRollAudio") == false then return end
    sound.Volume, sound.PlaybackSpeed = volume, speed
    sound.TimePosition = 0
    SoundService:PlayLocalSound(sound)
end
local function corner(object, radius)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, radius)
    value.Parent = object
end
local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.new(0.86, 0, 0, 170)
card.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
card.BackgroundTransparency = 0.15
card.Visible = false
card.Parent = gui
corner(card, 18)
Instance.new("UISizeConstraint", card).MaxSize = Vector2.new(480, 170)
local border = Instance.new("UIStroke", card)
border.Thickness = 2
border.Transparency = 0.3
local caption = Instance.new("TextLabel")
caption.BackgroundTransparency = 1
caption.Position = UDim2.fromOffset(10, 10)
caption.Size = UDim2.new(1, -20, 0, 30)
caption.Font = Enum.Font.GothamBold
caption.TextSize = 14
caption.TextColor3 = Color3.fromRGB(190, 195, 220)
caption.TextWrapped = true
caption.Parent = card
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.6)
label.Size = UDim2.new(0.9, 0, 0, 100)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 32
label.TextWrapped = true
label.TextStrokeTransparency = 0.5
label.Text = ""
label.Parent = card
local scale = Instance.new("UIScale", label)
local controls = Instance.new("Frame")
controls.AnchorPoint = Vector2.new(0.5, 1)
controls.Position = UDim2.fromScale(0.5, 0.95)
controls.Size = UDim2.new(0.9, 0, 0, 110)
controls.BackgroundTransparency = 1
controls.Parent = gui
Instance.new("UISizeConstraint", controls).MaxSize = Vector2.new(380, 110)
local function makeButton(position, size, fontSize)
    local value = Instance.new("TextButton")
    value.Position, value.Size = position, size
    value.Font = Enum.Font.GothamBold
    value.TextSize = fontSize
    value.TextColor3 = Color3.new(1, 1, 1)
    value.BackgroundColor3 = Color3.fromRGB(65, 85, 210)
    value.Parent = controls
    corner(value, 12)
    return value
end
local button = makeButton(UDim2.fromScale(0, 0), UDim2.new(1, 0, 0, 55), 24)
local autoButton = makeButton(UDim2.fromOffset(0, 65), UDim2.new(0.5, -5, 0, 40), 15)
local fastButton = makeButton(UDim2.new(0.5, 5, 0, 65), UDim2.new(0.5, -5, 0, 40), 15)
local busy, awaiting = false, false
local autoEnabled, fastEnabled = false, false
local token = 0
local animations = {}
local function stopAnimations()
    for _, tween in ipairs(animations) do tween:Cancel() end
    table.clear(animations)
end
local function animate(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    table.insert(animations, tween)
    tween:Play()
end
local function refresh()
    local ready = player:GetAttribute("RNGReady") == true
    button.Active = ready and not busy
    button.AutoButtonColor = button.Active
    button.Text = not ready and "Carregando..." or (busy and "Aguarde..." or "ROLL")
    autoButton.Active, fastButton.Active = ready, ready
    autoButton.Text = autoEnabled and "AUTO: LIGADO" or "AUTO: DESLIGADO"
    fastButton.Text = fastEnabled and "RÁPIDO: LIGADO" or "RÁPIDO: DESLIGADO"
    autoButton.BackgroundColor3 = autoEnabled and Color3.fromRGB(40, 130, 90) or Color3.fromRGB(55, 65, 110)
    fastButton.BackgroundColor3 = fastEnabled and Color3.fromRGB(130, 80, 180) or Color3.fromRGB(55, 65, 110)
end
local requestRoll
local function finish(current)
    if current ~= token then return end
    busy = false
    refresh()
    -- Um único agendamento; desligar AUTO impede a próxima rodada.
    if autoEnabled then
        task.delay(0.08, function()
            if current == token and autoEnabled and not busy then requestRoll() end
        end)
    end
end
requestRoll = function()
    if busy or player:GetAttribute("RNGReady") ~= true then return end
    busy, awaiting = true, true
    token += 1
    local current = token
    stopAnimations()
    card.Visible = true
    caption.Text = "SOLICITANDO RODADA..."
    label.Text = "Aguarde..."
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextTransparency = 0
    scale.Scale = 1
    border.Thickness = 2
    border.Color = Color3.fromRGB(100, 110, 160)
    refresh()
    -- Envia só a preferência de modo; nunca chance ou intervalo.
    roll:FireServer(fastEnabled, current)
    task.delay(8, function()
        if current == token and awaiting then
            awaiting, busy, autoEnabled = false, false, false
            token += 1
            caption.Text = "SEM RESPOSTA"
            label.Text = "Tente novamente"
            refresh()
        end
    end)
end
button.Activated:Connect(requestRoll)
autoButton.Activated:Connect(function()
    if player:GetAttribute("RNGReady") ~= true then return end
    autoEnabled = not autoEnabled
    refresh()
    if autoEnabled and not busy then requestRoll() end
end)
fastButton.Activated:Connect(function()
    if player:GetAttribute("RNGReady") ~= true then return end
    fastEnabled = not fastEnabled
    refresh() -- A mudança vale na próxima solicitação.
end)
player:GetAttributeChangedSignal("RNGReady"):Connect(function()
    if player:GetAttribute("RNGReady") ~= true then autoEnabled = false end
    refresh()
end)
refresh()
roll.OnClientEvent:Connect(function(result)
    if not awaiting or result.RequestId ~= token then return end
    awaiting = false
    token += 1
    local current = token
    local started = os.clock()
    if result.Status == "Cooldown" then
        caption.Text = "AGUARDANDO O SERVIDOR"
        label.Text = "Aguarde..."
        task.wait(math.max(0.05, result.RetryAfter) + 0.08)
        finish(current)
        return
    end
    stopAnimations()
    card.Visible = true
    label.TextTransparency = 0
    border.Thickness = 2
    caption.Text = result.Fast and "ROLAGEM RÁPIDA" or "SORTEANDO • NOMES DE PRÉVIA"
    local previous = 0
    local steps = result.Fast and 0 or 12
    for step = 1, steps do
        if current ~= token then return end
        stopAnimations()
        local index = visualRandom:NextInteger(1, #PREVIEWS - 1)
        if previous > 0 and index >= previous then index += 1 end
        previous = index
        label.Text, label.TextColor3 = PREVIEWS[index].Name, PREVIEWS[index].Color
        scale.Scale = 0.88
        animate(scale, TweenInfo.new(0.1), { Scale = 1 })
        playSound(0.12, 1.6 - step * 0.045)
        task.wait(0.045 + step * step * 0.002)
    end
    if current ~= token then return end
    stopAnimations()
    local special = result.Odds >= 5000 or result.Name == "Lendário" or result.Name == "Divino"
    caption.Text = special and "✦ CONQUISTA EXTRAORDINÁRIA ✦" or "RESULTADO"
    label.Text = result.Name .. (result.Odds > 0 and ("\n1 em " .. result.Odds) or "\nTente novamente!")
    label.TextColor3 = result.Color
    label.TextTransparency = 0
    scale.Scale = 0.65
    border.Color = result.Color
    border.Thickness = special and 6 or 2
    animate(scale, TweenInfo.new(result.Fast and 0.2 or 0.35, Enum.EasingStyle.Back), { Scale = 1 })
    if special then animate(border, TweenInfo.new(1.2), { Thickness = 3 }) end
    playSound(special and 0.5 or 0.3, special and 0.7 or 1)
    -- Até no modo rápido, conquistas especiais ficam visíveis por mais tempo.
    local hold = special and 3 or (result.Fast and 0.45 or 1.2)
    task.wait(math.max(hold, result.Cooldown - (os.clock() - started)) + 0.08)
    if current ~= token then return end
    animate(label, TweenInfo.new(0.3), { TextTransparency = 1 })
    finish(current)
    task.wait(0.3)
    if current == token then card.Visible = false end
end)
announcement.OnClientEvent:Connect(function(message)
    local channels = TextChatService:WaitForChild("TextChannels", 10)
    local general = channels and channels:WaitForChild("RBXGeneral", 10)
    if general then general:DisplaySystemMessage(message) end
end)

local UIConfig = require(ReplicatedStorage:WaitForChild("RNGUIConfig"))
UIConfig.RegisterRoll(gui, controls, card)
