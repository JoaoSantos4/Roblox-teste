-- LocalScript RNGSettingsClient em StarterPlayer > StarterPlayerScripts.
-- Preferências locais: não mudam equipamento, dados, chat de voz ou escolhas de outros jogadores.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local options = {
	{ Id = "OwnAura", Label = "Mostrar minha aura equipada" },
	{ Id = "OthersAura", Label = "Mostrar auras dos outros" },
	{ Id = "Interface", Label = "Mostrar interface do jogo" },
	{ Id = "RobloxAudio", Label = "Áudio do Roblox (passos e efeitos)" },
	{ Id = "GameMusic", Label = "Música ambiente do jogo" },
	{ Id = "AuraMusic", Label = "Música da aura equipada" },
	{ Id = "RollAudio", Label = "Sons das rolagens" },
}
local enabled = {}
for _, option in ipairs(options) do
	local saved = player:GetAttribute("RNG" .. option.Id)
	enabled[option.Id] = saved ~= false
	player:SetAttribute("RNG" .. option.Id, enabled[option.Id])
end
local gui = Instance.new("ScreenGui")
gui.Name = "RNGSettingsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui
local function button(parent, title, position, size)
	local value = Instance.new("TextButton")
	value.Text = title
	value.Position = position
	value.Size = size
	value.Font = Enum.Font.GothamBold
	value.TextSize = 16
	value.TextColor3 = Color3.new(1, 1, 1)
	value.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
	value.Parent = parent
	Instance.new("UICorner", value).CornerRadius = UDim.new(0, 12)
	return value
end
local gear = button(gui, "⚙", UDim2.fromOffset(208, 12), UDim2.fromOffset(44, 44))
gear.Name = "SettingsGear"
gear.TextSize = 28
local function positionGear()
	-- TopbarInset informa a área livre após os controles do Roblox, incluindo voz.
	local ok, area = pcall(function()
		return GuiService.TopbarInset
	end)
	if ok and area and area.Width >= 44 then
		gear.Position = UDim2.fromOffset(
			area.Min.X + 8,
			area.Min.Y + math.max(0, (area.Height - 44) / 2)
		)
	end
end
positionGear()
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(positionGear)
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.92, 0.8)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
Instance.new("UISizeConstraint", panel).MaxSize = Vector2.new(560, 540)
local function label(parent, title, position, size, fontSize)
	local value = Instance.new("TextLabel")
	value.Text = title
	value.Position = position
	value.Size = size
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextSize = fontSize
	value.TextColor3 = Color3.new(1, 1, 1)
	value.TextWrapped = true
	value.Parent = parent
	return value
end
label(panel, "OPÇÕES", UDim2.fromOffset(12, 8), UDim2.new(1, -70, 0, 40), 22)
local close = button(panel, "X", UDim2.new(1, -48, 0, 10), UDim2.fromOffset(36, 36))
local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 60)
list.Size = UDim2.new(1, -24, 1, -130)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
label(
	panel,
	"Opções apenas para você • A engrenagem continua visível.\nÁudio do Roblox não controla o microfone nem o chat de voz.",
	UDim2.new(0, 12, 1, -65),
	UDim2.new(1, -24, 0, 55),
	12
)
local originalEnabled = setmetatable({}, { __mode = "k" })
local function auraObject(object, character)
	local current = object
	while current and current ~= character do
		if
			current:GetAttribute("RNGAuraEffect") == true
			or current.Name == "RNGAuraTitle"
		then
			return true
		end
		current = current.Parent
	end
	return false
end
local function showAuraObject(object, character, visible)
	if
		not (
			object:IsA("Beam")
			or object:IsA("Trail")
			or object:IsA("ParticleEmitter")
			or object:IsA("Light")
			or object:IsA("BillboardGui")
		)
	then
		return
	end
	if not auraObject(object, character) then
		return
	end
	if originalEnabled[object] == nil then
		originalEnabled[object] = object.Enabled
	end
	object.Enabled = visible and originalEnabled[object] or false
	if not visible and object:IsA("ParticleEmitter") then
		object:Clear()
	end
end
local function group(name)
	local value = Instance.new("SoundGroup")
	value.Name = name
	value.Parent = SoundService
	return value
end
local robloxGroup = group("RNGRobloxAudio")
local gameGroup = group("RNGGameMusic")
local auraGroup = group("RNGAuraMusic")
local characterSounds = {
	Running = true,
	Died = true,
	GettingUp = true,
	Jumping = true,
	Landing = true,
	Splash = true,
	Swimming = true,
	FreeFalling = true,
	Climbing = true,
}
local tracked = {}
local function watchCharacter(other, character)
	local record = tracked[other]
	if record.characterConnection then
		record.characterConnection:Disconnect()
	end
	record.character = character
	local function apply(object)
		local visible = other == player and enabled.OwnAura
			or (other ~= player and enabled.OthersAura)
		showAuraObject(object, character, visible)
		if object:IsA("Sound") and characterSounds[object.Name] then
			object.SoundGroup = robloxGroup
		end
	end
	for _, object in ipairs(character:GetDescendants()) do
		apply(object)
	end
	record.characterConnection = character.DescendantAdded:Connect(apply)
end
local function watchPlayer(other)
	if tracked[other] then
		return
	end
	local record = {}
	tracked[other] = record
	record.spawnConnection = other.CharacterAdded:Connect(function(character)
		watchCharacter(other, character)
	end)
	if other.Character then
		watchCharacter(other, other.Character)
	end
end
local function refreshAuras()
	for other, record in pairs(tracked) do
		if record.character then
			local visible = other == player and enabled.OwnAura
				or (other ~= player and enabled.OthersAura)
			for _, object in ipairs(record.character:GetDescendants()) do
				showAuraObject(object, record.character, visible)
			end
		end
	end
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(other)
	local record = tracked[other]
	if not record then
		return
	end
	if record.characterConnection then
		record.characterConnection:Disconnect()
	end
	record.spawnConnection:Disconnect()
	tracked[other] = nil
end)
for _, other in ipairs(Players:GetPlayers()) do
	watchPlayer(other)
end
local function applyGui(object)
	if object == gui or not object:IsA("ScreenGui") or object.Name:sub(1, 3) ~= "RNG" then
		return
	end
	-- O botão controla todas as interfaces RNG, inclusive as criadas enquanto ocultas.
	-- Não memorize Enabled=false: esse valor pode ter sido imposto por esta opção.
	object.Enabled = enabled.Interface
end
playerGui.ChildAdded:Connect(applyGui)
local function refreshGui()
	for _, object in ipairs(playerGui:GetChildren()) do
		applyGui(object)
	end
end
-- Melodias próprias tocadas com o som incluído no Roblox. Não exigem asset de áudio externo.
-- Para trocar por faixas autorizadas, preencha AssetId = "rbxassetid://ID" na entrada correspondente.
-- MP3s completos estão na pasta music do GitHub. Importe-os e preencha os AssetIds.
-- Com AssetId vazio, toca uma versão simples da melodia com sons incluídos no Roblox.
local music = {
	-- Praia_Ambiente.mp3
	ambient = {
		Beat = 0.30000,
		Notes = { 0, 4, 7, 9, 7, 4, 2, 4, 7, 12, 9, 7, 4, 2, 0, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Comum_Conforto.mp3
	common = {
		Beat = 0.26786,
		Notes = { 0, 4, 7, false, 4, 2, 0, false, 7, 4, 2, 4, 0, false, 2, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Incomum_Natureza.mp3
	uncommon = {
		Beat = 0.34884,
		Notes = { 0, 2, 7, 9, 7, false, 2, 0, 5, 9, 12, 9, 7, 5, 2, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Raro_Oceano.mp3
	rare = {
		Beat = 0.32609,
		Notes = { 0, 7, 12, false, 14, 12, 7, 5, 9, 12, 16, 14, 12, 9, 7, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Epico_Sombras.mp3
	epic = {
		Beat = 0.33333,
		Notes = { 0, 3, 7, 10, 7, false, 3, 0, 5, 8, 12, 8, 7, 3, 0, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Lendario_Solar.mp3
	legendary = {
		Beat = 0.25424,
		Notes = { 0, 4, 7, 12, 7, 12, 16, false, 14, 12, 7, 4, 9, 7, 4, 0 },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Divino_Cosmos.mp3
	divine = {
		Beat = 0.40541,
		Notes = { 0, 7, 12, 16, 19, false, 16, 12, 5, 12, 17, 21, 19, 17, 12, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
	-- Segredo_Enigma.mp3
	secret = {
		Beat = 0.38462,
		Notes = { 0, 1, 7, false, 8, 7, 1, 0, 3, 7, 10, 8, 7, 3, 1, false },
		Volume = 0.055,
		AssetVolume = 0.3,
		AssetId = "",
	},
}
local function voices(name, soundGroup)
	local result = {}
	for index = 1, 3 do
		local sound = Instance.new("Sound")
		sound.Name = name .. index
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.SoundGroup = soundGroup
		sound.Parent = SoundService
		table.insert(result, sound)
	end
	return result
end
local ambientVoices = voices("RNGEnvironmentNote", gameGroup)
local auraVoices = voices("RNGAuraNote", auraGroup)
local equipped
local function stop(pool)
	for _, sound in ipairs(pool) do
		sound:Stop()
	end
end
local function play(pool, track, index)
	if track.AssetId ~= "" then
		local sound = pool[1]
		if sound.SoundId ~= track.AssetId then
			sound:Stop()
			sound.SoundId = track.AssetId
		end
		sound.Volume = track.AssetVolume or track.Volume
		sound.PlaybackSpeed = 1
		sound.Looped = true
		if not sound.IsPlaying then
			sound:Play()
		end
	else
		local note = track.Notes[(index - 1) % #track.Notes + 1]
		if note == false then
			return
		end
		local sound = pool[(index - 1) % #pool + 1]
		sound:Stop()
		sound.Looped = false
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = track.Volume
		sound.PlaybackSpeed = 2 ^ (note / 12)
		sound:Play()
	end
end
local function refreshAudio()
	robloxGroup.Volume = enabled.RobloxAudio and 1 or 0
	gameGroup.Volume = enabled.GameMusic and 1 or 0
	auraGroup.Volume = enabled.AuraMusic and 1 or 0
	if not enabled.GameMusic then
		stop(ambientVoices)
	end
	if not enabled.AuraMusic then
		stop(auraVoices)
	end
	if not enabled.RollAudio then
		for _, object in ipairs(playerGui:GetDescendants()) do
			if object:IsA("Sound") and object.Name == "RNGRollSound" then
				object:Stop()
			end
		end
	end
end
local buttons = {}
local function renderOptions()
	for _, option in ipairs(options) do
		local object = buttons[option.Id]
		object.Text = option.Label
			.. "\n"
			.. (enabled[option.Id] and "LIGADO" or "DESLIGADO")
		object.BackgroundColor3 = enabled[option.Id] and Color3.fromRGB(40, 100, 75)
			or Color3.fromRGB(65, 50, 70)
	end
end
for index, option in ipairs(options) do
	local object = button(list, "", UDim2.new(), UDim2.new(1, -8, 0, 64))
	object.LayoutOrder = index
	buttons[option.Id] = object
	local id = option.Id
	object.Activated:Connect(function()
		enabled[id] = not enabled[id]
		player:SetAttribute("RNG" .. id, enabled[id])
		refreshAuras()
		refreshGui()
		refreshAudio()
		renderOptions()
	end)
end
gear.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
close.Activated:Connect(function()
	panel.Visible = false
end)
refreshGui()
refreshAudio()
renderOptions()
task.spawn(function()
	local index = 1
	while gui.Parent do
		if enabled.GameMusic then
			play(ambientVoices, music.ambient, index)
		end
		index += 1
		task.wait(music.ambient.Beat)
	end
	stop(ambientVoices)
end)
task.spawn(function()
	local index, previous = 1, nil
	while gui.Parent do
		if previous ~= equipped then
			index = 1
			stop(auraVoices)
			previous = equipped
		end
		local track = equipped and music[equipped]
		if track and enabled.AuraMusic then
			play(auraVoices, track, index)
		end
		index += 1
		task.wait(track and track.Beat or 0.5)
	end
	stop(auraVoices)
end)
task.spawn(function()
	local inventory = ReplicatedStorage:WaitForChild("RNGRemotes")
		:WaitForChild("Inventory")
	inventory.OnClientEvent:Connect(function(snapshot)
		local nextAura = snapshot.Equipped
		if equipped ~= nextAura then
			stop(auraVoices)
		end
		equipped = nextAura
	end)
	local function sync()
		if player:GetAttribute("RNGReady") == true then
			inventory:FireServer()
		end
	end
	player:GetAttributeChangedSignal("RNGReady"):Connect(sync)
	sync()
end)

-- Regras compartilhadas para computador e celular.
local UIConfig = require(ReplicatedStorage:WaitForChild("RNGUIConfig"))
UIConfig.RegisterPanel("settings", gui, panel, nil, close, 560, 540, 7)
