-- ModuleScript RNGQuests. Inicializado pelo RNGServer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Missions = require(script.Parent:WaitForChild("RNGDaily"))
local Store = DataStoreService:GetDataStore("RNG_Daily_v1")
local Quests, states = {}, {}
local started, closing = false, false
local event, shopEvent
local HttpService = game:GetService("HttpService")
local function context()
	local now = DateTime.now()
	local utc = now:ToUniversalTime()
	local d = math.floor(now.UnixTimestamp / 86400)
	local week = math.floor((d + 3) / 7)
	local nextYear, nextMonth = utc.Year, utc.Month + 1
	if nextMonth == 13 then
		nextYear, nextMonth = nextYear + 1, 1
	end
	return {
		Now = now.UnixTimestamp,
		Keys = { daily = d, weekly = week, monthly = utc.Year * 12 + utc.Month - 1 },
		Starts = {
			daily = d * 86400,
			weekly = (week * 7 - 3) * 86400,
			monthly = DateTime.fromUniversalTime(utc.Year, utc.Month, 1).UnixTimestamp,
		},
		Resets = {
			daily = (d + 1) * 86400,
			weekly = ((week + 1) * 7 - 3) * 86400,
			monthly = DateTime.fromUniversalTime(nextYear, nextMonth, 1).UnixTimestamp,
		},
	}
end
local function retry(operation)
	for attempt = 1, 3 do
		local ok, value = pcall(operation)
		if ok then
			return true, value
		end
		warn("RNG missões: " .. tostring(value))
		if attempt < 3 then
			task.wait(attempt * 2)
		end
	end
	return false
end
local function normalize(state)
	local ctx = context()
	if Missions.Record(state.data, "refresh", nil, 0, ctx) then
		state.revision += 1
		state.dirty = true
	end
	return ctx
end
local function send(player, state, message)
	if player.Parent ~= Players then
		return
	end
	if not state.loaded then
		event:FireClient(player, {
			Ready = false,
			Message = state.failed and "Missões indisponíveis. Entre novamente."
				or "Carregando missões...",
		})
		return
	end
	local ctx = normalize(state)
	if shopEvent then
		local products = {}
		for _, entry in ipairs(Missions.Products) do
			local product = table.clone(entry)
			if product.Id == "income" then
				product.Price *= state.data.Shop.Level + 1
			end
			table.insert(products, product)
		end
		shopEvent:FireClient(player, {
			Coins = state.data.Coins,
			Shop = table.clone(state.data.Shop),
			Products = products,
			Message = message,
		})
	end
	player:SetAttribute("RNGCoins", state.data.Coins)
	event:FireClient(player, {
		Ready = true,
		Coins = state.data.Coins,
		Periods = Missions.View(state.data, ctx),
		Message = message,
	})
end
local function tick(state)
	local ctx = context()
	local seconds = math.max(0, ctx.Now - state.lastTick)
	state.lastTick = ctx.Now
	local data = state.loaded and state.data or state.pending
	if Missions.Record(data, "time", nil, seconds, ctx) and state.loaded then
		state.revision += 1
		state.dirty = true
	end
end
local function persist(player, state, scope, id, requestedKey, product, receipt)
	if not state.loaded then
		return false
	end
	while state.saving do
		task.wait(0.1)
	end
	tick(state)
	if not state.dirty and not id and not product then
		return true
	end
	local ctx = normalize(state)
	state.saving = true
	local revision = state.revision
	local snapshot = Missions.Decode(state.data, ctx)
	local ok, saved = retry(function()
		return Store:UpdateAsync("player_" .. player.UserId, function(old)
			if product then
				return Missions.Buy(snapshot, old, context(), product, receipt)
			end
			if id then
				return Missions.Claim(snapshot, old, context(), scope, id, requestedKey)
			end
			return Missions.Merge(snapshot, old, context())
		end)
	end)
	if ok then
		state.data = Missions.Merge(state.data, saved, context())
		if state.revision == revision then
			state.dirty = false
		end
		local message
		if id then
			message = state.data.Periods[scope].Key ~= requestedKey
					and "O período mudou. Confira as novas missões."
				or (
					state.data.Periods[scope].Claimed[id]
						and "Recompensa verificada e salva!"
					or "Missão ainda não concluída."
				)
		end
		if product then
			message = state.data.Shop.Receipt == receipt and "Compra salva!"
				or "Saldo insuficiente, poção ativa ou nível máximo."
		end
		send(player, state, message)
	elseif id or product then
		send(player, state, "Não foi possível salvar. Tente resgatar novamente.")
	end
	state.saving = false
	return ok
end
local function setup(player)
	if states[player] then
		return
	end
	local ctx = context()
	local state = {
		loaded = false,
		failed = false,
		saving = false,
		claiming = false,
		dirty = false,
		revision = 0,
		nextRequest = 0,
		lastTick = ctx.Now,
		pending = Missions.Decode(nil, ctx),
	}
	states[player] = state
	player:SetAttribute("RNGQuestsReady", false)
	player:SetAttribute("RNGCoins", 0)
	local ok, data = retry(function()
		return Missions.Decode(Store:GetAsync("player_" .. player.UserId), context())
	end)
	if states[player] ~= state or player.Parent ~= Players or closing then
		return
	end
	if not ok then
		state.failed = true
		send(player, state)
		return
	end
	tick(state)
	state.data = Missions.Merge(state.pending, data, context(), true)
	state.loaded, state.dirty = true, true
	state.revision += 1
	player:SetAttribute("RNGQuestsReady", true)
	send(player, state)
end
local function record(player, kind, id)
	local state = states[player]
	if closing or not state or state.leaving or state.failed then
		return
	end
	tick(state)
	local data = state.loaded and state.data or state.pending
	if Missions.Record(data, kind, id, 0, context()) and state.loaded then
		state.revision += 1
		state.dirty = true
		send(player, state)
	end
end
function Quests.RecordRoll(player, item)
	record(player, "roll", item and item.Id)
	local state = states[player]
	if state and state.loaded and not state.leaving and not closing then
		state.data.Coins += 1 + state.data.Shop.Level
		state.revision += 1
		state.dirty = true
		send(player, state)
	end
end
function Quests.RecordEquip(player, id)
	record(player, "equip", id)
end
function Quests.Status(player)
	local state = states[player]
	if not state or not state.loaded or state.failed then
		return { Ready = false }
	end
	return {
		Ready = true,
		Coins = state.data.Coins,
		Level = state.data.Shop.Level,
		LuckUntil = state.data.Shop.LuckUntil,
		SpeedUntil = state.data.Shop.SpeedUntil,
	}
end
function Quests.Bonuses(player)
	local state = states[player]
	if not state or not state.loaded then
		return 1, 1
	end
	local now = DateTime.now().UnixTimestamp
	return state.data.Shop.LuckUntil > now and 2 or 1,
		state.data.Shop.SpeedUntil > now and 0.75 or 1
end
function Quests.Start()
	if started then
		return
	end
	started = true
	local folder = Instance.new("Folder")
	folder.Name = "RNGQuestRemotes"
	event = Instance.new("RemoteEvent")
	event.Name = "Daily"
	event.Parent = folder
	shopEvent = Instance.new("RemoteEvent")
	shopEvent.Name = "Shop"
	shopEvent.Parent = folder
	folder.Parent = ReplicatedStorage
	shopEvent.OnServerEvent:Connect(function(player, action, id)
		local state = states[player]
		if
			closing
			or not state
			or not state.loaded
			or state.leaving
			or player.Parent ~= Players
		then
			return
		end
		if action ~= "sync" and action ~= "buy" then
			return
		end
		if os.clock() < (state.nextShop or 0) then
			return
		end
		state.nextShop = os.clock() + 1
		if action == "sync" then
			send(player, state)
			return
		end
		if type(id) ~= "string" or #id > 32 or state.claiming then
			return
		end
		local valid = false
		for _, product in ipairs(Missions.Products) do
			if product.Id == id then
				valid = true
			end
		end
		if not valid then
			return
		end
		state.claiming = true
		persist(player, state, nil, nil, nil, id, HttpService:GenerateGUID(false))
		state.claiming = false
	end)
	event.OnServerEvent:Connect(function(player, action, scope, id, key)
		local state = states[player]
		if closing or not state or state.leaving or player.Parent ~= Players then
			return
		end
		if action ~= "sync" and action ~= "claim" then
			return
		end
		if os.clock() < state.nextRequest then
			return
		end
		state.nextRequest = os.clock() + 0.5
		if action == "sync" or not state.loaded then
			send(player, state)
			return
		end
		if
			type(scope) ~= "string"
			or type(id) ~= "string"
			or #id > 128
			or type(key) ~= "number"
		then
			return
		end
		local quest = Missions.Quest(scope, id)
		if not quest then
			return
		end
		tick(state)
		normalize(state)
		local period = state.data.Periods[scope]
		if key ~= period.Key then
			send(player, state, "O período mudou. Confira as novas missões.")
			return
		end
		if period.Claimed[id] then
			send(player, state, "Recompensa já resgatada.")
			return
		end
		if Missions.Progress(period, quest) < quest.Goal then
			send(player, state, "Missão ainda não concluída.")
			return
		end
		if state.claiming then
			return
		end
		state.claiming = true
		persist(player, state, scope, id, key)
		state.claiming = false
	end)
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(player)
		local state = states[player]
		if not state then
			return
		end
		state.leaving = true
		persist(player, state)
		states[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(setup, player)
	end
	task.spawn(function()
		local cycles = 0
		while not closing do
			task.wait(30)
			if closing then
				break
			end
			cycles += 1
			for player, state in pairs(states) do
				if not state.leaving and not state.failed then
					tick(state)
					if state.loaded then
						send(player, state)
					end
					if cycles % 2 == 0 then
						task.spawn(persist, player, state)
					end
				end
			end
		end
	end)
	game:BindToClose(function()
		closing = true
		local pending = 0
		for player, state in pairs(states) do
			pending += 1
			task.spawn(function()
				persist(player, state)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
		if pending > 0 then
			warn("RNG missões: salvamentos pendentes no encerramento")
		end
	end)
end
return Quests
