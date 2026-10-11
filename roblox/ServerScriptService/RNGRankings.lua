-- ModuleScript RNGRankings: espelho global de perfis já salvos.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent:WaitForChild("RNGConfig"))
local bestStore = DataStoreService:GetOrderedDataStore("RNG_GlobalBest_v1")
local rollsStore = DataStoreService:GetOrderedDataStore("RNG_GlobalRolls_v1")
local Rankings = {}
local pending, names = {}, {}
local started, closing, refreshing = false, false, false
local cache = { Best = {}, Rolls = {}, UpdatedAt = 0, Ready = false }
local event
local nextRequests = {}
local auraNames = {}
for _, item in ipairs(Config.Items) do
	auraNames[item.Odds] = item.Name
end
local function integer(value)
	return type(value) == "number"
		and value >= 0
		and value < 9007199254740991
		and value == math.floor(value)
end
function Rankings.Publish(userId, best, rolls)
	if not integer(userId) or userId == 0 or not integer(best) or not integer(rolls) then
		return
	end
	local old = pending[userId]
	pending[userId] = {
		Best = math.max(best, old and old.Best or 0),
		Rolls = math.max(rolls, old and old.Rolls or 0),
	}
end
local function write(store, userId, value)
	if value == 0 then
		return true
	end
	local ok, problem = pcall(function()
		store:UpdateAsync(tostring(userId), function(old)
			return math.max(old or 0, value)
		end)
	end)
	if not ok then
		warn("RNG ranking: " .. tostring(problem))
	end
	return ok
end
local function flush()
	for userId, snapshot in pairs(pending) do
		local bestOK = write(bestStore, userId, snapshot.Best)
		local rollsOK = write(rollsStore, userId, snapshot.Rolls)
		if bestOK and rollsOK and pending[userId] == snapshot then
			pending[userId] = nil
		end
	end
end
local function username(userId)
	local entry = names[userId]
	if entry then
		return entry
	end
	local online = Players:GetPlayerByUserId(userId)
	if online then
		names[userId] = online.Name
		return online.Name
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok then
		names[userId] = name
		return name
	end
	return "Jogador " .. userId
end
local function read(store, isBest)
	local pages = store:GetSortedAsync(false, 20, 1)
	local rows = {}
	for rank, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key)
		if userId and integer(userId) then
			table.insert(
				rows,
				{
					Rank = rank,
					UserId = userId,
					Name = username(userId),
					Value = entry.value,
					Aura = isBest and (auraNames[entry.value] or "Aura antiga") or nil,
				}
			)
		end
	end
	return rows
end
local function refresh()
	if refreshing then
		return
	end
	refreshing = true
	-- Cache de nomes limitado a uma atualização; não acumula todas as contas.
	names = {}
	local ok, best, rolls = pcall(function()
		return read(bestStore, true), read(rollsStore, false)
	end)
	if ok then
		cache = {
			Best = best,
			Rolls = rolls,
			UpdatedAt = DateTime.now().UnixTimestamp,
			Ready = true,
		}
		if event then
			event:FireAllClients(cache)
		end
	else
		warn("RNG leitura de ranking: " .. tostring(best))
	end
	refreshing = false
end
function Rankings.Start()
	if started then
		return
	end
	started = true
	event = Instance.new("RemoteEvent")
	event.Name = "RNGRankings"
	event.Parent = ReplicatedStorage
	event.OnServerEvent:Connect(function(player)
		if closing or player.Parent ~= Players then
			return
		end
		if os.clock() < (nextRequests[player] or 0) then
			return
		end
		nextRequests[player] = os.clock() + 2
		event:FireClient(player, cache) -- Pedidos do cliente não consultam DataStore.
	end)
	Players.PlayerRemoving:Connect(function(player)
		nextRequests[player] = nil
	end)
	task.spawn(refresh)
	task.spawn(function()
		while not closing do
			task.wait(60)
			if closing then
				break
			end
			flush()
			refresh()
		end
	end)
	game:BindToClose(function()
		closing = true
		-- RNGServer salva os perfis em paralelo durante o encerramento.
		local deadline = os.clock() + 27
		repeat
			flush()
			task.wait(0.5)
		until os.clock() >= deadline
		if next(pending) then
			warn("RNG ranking: envios pendentes; serão refeitos ao entrar novamente.")
		end
	end)
end
return Rankings
