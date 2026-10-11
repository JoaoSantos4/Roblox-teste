-- Script RNGServer em ServerScriptService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(script.Parent:WaitForChild("RNGConfig"))
local Profile = require(script.Parent:WaitForChild("RNGProfile"))
local AuraEffects = require(script.Parent:WaitForChild("RNGAuraEffect"))
local Quests = require(script.Parent:WaitForChild("RNGQuests"))
Quests.Start()

-- Mantém o DataStore antigo para recuperar seu recorde.
local Store = DataStoreService:GetDataStore("RNG_Best_v1")

local random = Random.new()
local states = {}
local closing = false

local itemsById = {}
local catalog = {}
local total = 0

for _, item in ipairs(Config.Items) do
	assert(
		type(item.Id) == "string"
			and #item.Id > 0
			and #item.Id <= 128
			and not itemsById[item.Id],
		"ID inválido ou duplicado"
	)

	assert(
		type(item.Odds) == "number"
			and item.Odds >= 1
			and item.Odds < math.huge
			and item.Odds == math.floor(item.Odds),
		"Chance inválida"
	)

	total += 1 / item.Odds
	itemsById[item.Id] = item

	table.insert(catalog, {
		Id = item.Id,
		Name = item.Name,
		Odds = item.Odds,
		Color = item.Color,
	})
end

assert(
	total <= 1 and #catalog <= 1000,
	"Probabilidades ou catálogo inválidos"
)

table.sort(catalog, function(a, b)
	return a.Odds < b.Odds
end)

local folder = Instance.new("Folder")
folder.Name = "RNGRemotes"

local function remote(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

local rollEvent = remote("Roll")
local announcement = remote("Announcement")
local inventoryEvent = remote("Inventory")
local equipEvent = remote("Equip")

folder.Parent = ReplicatedStorage

local function retry(operation)
	for attempt = 1, 3 do
		local ok, result = pcall(operation)

		if ok then
			return true, result
		end

		warn("RNG DataStore: " .. tostring(result))

		if attempt < 3 then
			task.wait(attempt * 2)
		end
	end

	return false, nil
end

local function active(player, state)
	return not closing
		and player.Parent == Players
		and state
		and state.loaded
		and not state.leaving
end

local function sendInventory(player, state)
	if player.Parent ~= Players
		or not state.loaded
		or state.leaving then
		return
	end

	inventoryEvent:FireClient(player, {
		Catalog = catalog,
		Owned = table.clone(state.data.Owned),
		Equipped = state.data.Equipped,
	})
end

local function updateStat(state)
	local item = itemsById[state.data.BestId]

	if state.data.BestOdds > 0 then
		state.stat.Value = (item and item.Name or "Recorde")
			.. " (1 em " .. state.data.BestOdds .. ")"
	else
		state.stat.Value = "Nenhum"
	end
end

local function applyTitle(player, state, character)
	character = character or player.Character

	if not character then
		return
	end

	local item = itemsById[state.data.Equipped]

	if item and not state.data.Owned[item.Id] then
		item = nil
	end

	-- Cria a aura equipada ou remove os efeitos anteriores.
	AuraEffects.Apply(character, item)

	local head = character:FindFirstChild("Head")

	if not head then
		return
	end

	local old = head:FindFirstChild("RNGAuraTitle")

	if old then
		old:Destroy()
	end

	if not item then
		return
	end

	local title = Instance.new("BillboardGui")
	title.Name = "RNGAuraTitle"
	title.Adornee = head
	title.Size = UDim2.fromOffset(220, 60)
	title.StudsOffset = Vector3.new(0, 3, 0)
	title.MaxDistance = 100

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 20
	text.TextStrokeTransparency = 0.3
	text.TextColor3 = item.Color
	text.Text = item.Name .. "\n1 em " .. item.Odds
	text.Parent = title

	title.Parent = head
end

local function changed(state)
	state.revision += 1
	state.dirty = true
end

local function save(player, state)
	if not state.loaded then
		return
	end

	while state.saving do
		task.wait(0.1)
	end

	if not state.dirty then
		return
	end

	state.saving = true

	local revision = state.revision
	local snapshot = Profile.Decode(state.data)

	local ok, saved = retry(function()
		return Store:UpdateAsync(
			"player_" .. player.UserId,
			function(old)
				return Profile.Merge(snapshot, old)
			end
		)
	end)

	if ok then
		-- Preserva alterações feitas durante o salvamento.
		state.data = Profile.Merge(state.data, saved)

		if state.revision == revision then
			state.dirty = false
		end

		updateStat(state)
		applyTitle(player, state)
		sendInventory(player, state)
	end

	state.saving = false
end

local function setupPlayer(player)
	if states[player] then
		return
	end

	local state = {
		loaded = false,
		dirty = false,
		saving = false,
		leaving = false,
		revision = 0,
		nextRoll = 0,
		nextEquip = 0,
		nextInventory = 0,
	}

	states[player] = state
	player:SetAttribute("RNGReady", false)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local best = Instance.new("StringValue")
	best.Name = "RNG Mais Raro"
	best.Value = "Nenhum"
	best.Parent = stats
	state.stat = best

	state.characterConnection =
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)

			if states[player] == state
				and state.loaded
				and player.Character == character then
				applyTitle(player, state, character)
			end
		end)

	local ok, data = retry(function()
		return Profile.Decode(
			Store:GetAsync("player_" .. player.UserId)
		)
	end)

	if states[player] ~= state
		or player.Parent ~= Players
		or closing then
		return
	end

	if not ok then
		player:Kick(
			"Não foi possível carregar seus dados. "
				.. "Tente entrar novamente."
		)
		return
	end

	state.data = data
	state.loaded = true

	-- Salva também a migração dos dados antigos.
	changed(state)

	updateStat(state)
	applyTitle(player, state)

	player:SetAttribute("RNGReady", true)
	sendInventory(player, state)
end

local function draw(luck)
 luck = luck or 1
	local value = random:NextNumber()
	local cumulative = 0

	for _, item in ipairs(Config.Items) do
		cumulative += (item.Odds >= 50 and luck or 1) / item.Odds

		if value < cumulative then
			return item
		end
	end

	return nil
end

rollEvent.OnServerEvent:Connect(function(player, fast, requestId)
	local state = states[player]

	if not active(player, state) then
		return
	end

	if fast ~= nil and type(fast) ~= "boolean" then
		return
	end

	if requestId ~= nil and (
		type(requestId) ~= "number"
			or requestId < 1
			or requestId > 2147483647
			or requestId ~= math.floor(requestId)
		) then
		return
	end

	local now = os.clock()

	if now < state.nextRoll then
		if now >= (state.nextFeedback or 0) then
			state.nextFeedback = now + 0.25

			rollEvent:FireClient(player, {
				Status = "Cooldown",
				RetryAfter = state.nextRoll - now,
				RequestId = requestId,
			})
		end

		return
	end

	local luck, speed = Quests.Bonuses(player)
	local cooldown = fast == true
		and Config.FastCooldown
		or Config.Cooldown

	cooldown *= speed
	state.nextRoll = now + cooldown

	-- Um único sorteio: missões e inventário recebem o mesmo resultado.
	local item = draw(luck)
	Quests.RecordRoll(player, item)

	if item then
		if not state.data.Owned[item.Id] then
			state.data.Owned[item.Id] = true
			changed(state)
		end

		if item.Odds > state.data.BestOdds then
			state.data.BestOdds = item.Odds
			state.data.BestId = item.Id
			changed(state)
			updateStat(state)
		end

		sendInventory(player, state)
	end

	rollEvent:FireClient(player, {
		Name = item and item.Name or "Sem aura",
		Odds = item and item.Odds or 0,
		Color = item and item.Color
			or Color3.fromRGB(180, 180, 180),
		Cooldown = cooldown,
		Fast = fast == true,
		Status = "Result",
		RequestId = requestId,
	})

	if item and item.Announce then
		announcement:FireAllClients(
			player.Name .. " conseguiu " .. item.Name
				.. " — 1 em " .. item.Odds .. "!"
		)
	end
end)

inventoryEvent.OnServerEvent:Connect(function(player)
	local state = states[player]

	if not active(player, state)
		or os.clock() < state.nextInventory then
		return
	end

	state.nextInventory = os.clock() + 1
	sendInventory(player, state)
end)

equipEvent.OnServerEvent:Connect(function(player, id)
	local state = states[player]

	if not active(player, state)
		or os.clock() < state.nextEquip then
		return
	end

	state.nextEquip = os.clock() + 0.3

	if type(id) ~= "string" or #id > 128 then
		return
	end

	-- Só permite equipar uma aura que o jogador possui.
	if id ~= ""
		and (not itemsById[id] or not state.data.Owned[id]) then
		return
	end

	local equipped = id ~= "" and id or nil
	if equipped then
		Quests.RecordEquip(player, equipped)
	end

	if state.data.Equipped ~= equipped then
		state.data.Equipped = equipped
		state.data.EquipTime = math.max(
			DateTime.now().UnixTimestampMillis,
			state.data.EquipTime + 1
		)

		changed(state)
		applyTitle(player, state)
	end

	sendInventory(player, state)
end)

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	local state = states[player]

	if not state then
		return
	end

	state.leaving = true
	player:SetAttribute("RNGReady", false)
	state.characterConnection:Disconnect()

	save(player, state)
	states[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

task.spawn(function()
	while not closing do
		task.wait(Config.AutosaveSeconds)

		if closing then
			break
		end

		for player, state in pairs(states) do
			task.spawn(save, player, state)
		end
	end
end)

game:BindToClose(function()
	closing = true
	local pending = 0

	for player, state in pairs(states) do
		pending += 1

		task.spawn(function()
			save(player, state)
			pending -= 1
		end)
	end

	local deadline = os.clock() + 25

	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end

	if pending > 0 then
		warn("RNG: encerramento antes de concluir os salvamentos")
	end
end)
