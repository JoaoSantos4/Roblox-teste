-- ModuleScript RNGDaily: catálogo, progresso e transações de missões.
local Missions = {}
Missions.Scopes = { "daily", "weekly", "monthly" }
Missions.Names = { daily = "Diárias", weekly = "Semanais", monthly = "Mensais" }
-- Não reutilize IDs de missões para objetivos diferentes.
Missions.Catalog = {
	daily = {
		{
			Id = "login",
			Title = "Presença premiada",
			Description = "Entre no jogo hoje",
			Metric = "Login",
			Goal = 1,
			Reward = 200,
		},
		{
			Id = "rolls",
			Title = "Aquecimento",
			Description = "Complete 100 rodadas",
			Metric = "Rolls",
			Goal = 100,
			Reward = 500,
		},
		{
			Id = "rare2",
			Title = "Caçador azul",
			Description = "Obtenha Raro 2 vezes",
			Metric = "Item",
			Item = "rare",
			Goal = 2,
			Reward = 400,
		},
		{
			Id = "found2",
			Title = "Pequena coleção",
			Description = "Obtenha 2 auras diferentes hoje",
			Metric = "Found",
			Goal = 2,
			Reward = 300,
		},
		{
			Id = "style1",
			Title = "Mostre seu estilo",
			Description = "Equipe uma aura",
			Metric = "Equipped",
			Goal = 1,
			Reward = 150,
		},
		{
			Id = "time10",
			Title = "Uma pausa para jogar",
			Description = "Passe 10 minutos no jogo",
			Metric = "Seconds",
			Goal = 600,
			Reward = 250,
		},
	},
	weekly = {
		{
			Id = "rolls1500",
			Title = "Ritmo da semana",
			Description = "Complete 1.500 rodadas",
			Metric = "Rolls",
			Goal = 1500,
			Reward = 2500,
		},
		{
			Id = "rare20",
			Title = "Maré azul",
			Description = "Obtenha Raro 20 vezes",
			Metric = "Item",
			Item = "rare",
			Goal = 20,
			Reward = 2000,
		},
		{
			Id = "epic3",
			Title = "Trio épico",
			Description = "Obtenha Épico 3 vezes",
			Metric = "Item",
			Item = "epic",
			Goal = 3,
			Reward = 2500,
		},
		{
			Id = "found4",
			Title = "Explorador de raridades",
			Description = "Obtenha 4 auras diferentes nesta semana",
			Metric = "Found",
			Goal = 4,
			Reward = 1200,
		},
		{
			Id = "style3",
			Title = "Desfile de auras",
			Description = "Equipe 3 auras diferentes",
			Metric = "Equipped",
			Goal = 3,
			Reward = 800,
		},
		{
			Id = "time60",
			Title = "Hora da sorte",
			Description = "Acumule 60 minutos no jogo",
			Metric = "Seconds",
			Goal = 3600,
			Reward = 1800,
		},
	},
	monthly = {
		{
			Id = "rolls5000",
			Title = "Lenda em construção",
			Description = "Complete 5.000 rodadas",
			Metric = "Rolls",
			Goal = 5000,
			Reward = 8000,
		},
		{
			Id = "rare100",
			Title = "Centena azul",
			Description = "Obtenha Raro 100 vezes",
			Metric = "Item",
			Item = "rare",
			Goal = 100,
			Reward = 6000,
		},
		{
			Id = "epic15",
			Title = "Constelação épica",
			Description = "Obtenha Épico 15 vezes",
			Metric = "Item",
			Item = "epic",
			Goal = 15,
			Reward = 7000,
		},
		{
			Id = "legendary1",
			Title = "Primeiro raio de sol",
			Description = "Obtenha Lendário neste mês",
			Metric = "Item",
			Item = "legendary",
			Goal = 1,
			Reward = 15000,
		},
		{
			Id = "found5",
			Title = "Álbum de raridades",
			Description = "Obtenha 5 auras diferentes neste mês",
			Metric = "Found",
			Goal = 5,
			Reward = 10000,
		},
		{
			Id = "time180",
			Title = "Habitante do RNG",
			Description = "Acumule 3 horas no jogo",
			Metric = "Seconds",
			Goal = 10800,
			Reward = 5000,
		},
	},
}
local byId, caps = {}, {}
for _, scope in ipairs(Missions.Scopes) do
	byId[scope], caps[scope] = {}, { Rolls = 0, Seconds = 0, Items = {} }
	for _, quest in ipairs(Missions.Catalog[scope]) do
		assert(not byId[scope][quest.Id], "Missão duplicada")
		byId[scope][quest.Id] = quest
		if quest.Metric == "Rolls" or quest.Metric == "Seconds" then
			caps[scope][quest.Metric] = math.max(caps[scope][quest.Metric], quest.Goal)
		elseif quest.Metric == "Item" then
			caps[scope].Items[quest.Item] =
				math.max(caps[scope].Items[quest.Item] or 0, quest.Goal)
		end
	end
end
local function integer(value)
	return type(value) == "number"
		and value >= 0
		and value < 9007199254740991
		and value == math.floor(value)
end
local function validId(value)
	return type(value) == "string" and #value > 0 and #value <= 128
end
local function setCopy(raw)
	assert(type(raw) == "table", "Coleção de missões inválida")
	local result, count = {}, 0
	for key, value in pairs(raw) do
		assert(validId(key) and value == true, "ID de missão/aura inválido")
		count += 1
		assert(count <= 1000, "Coleção excede limite")
		result[key] = true
	end
	return result
end
local function newPeriod(key)
	return {
		Key = key,
		Rolls = 0,
		Seconds = 0,
		Counts = {},
		Found = {},
		Equipped = {},
		Claimed = {},
	}
end
function Missions.Decode(raw, context)
	local result = {
		Version = 2,
		Coins = 0,
		Spent = 0,
		Shop = { Revision = 0, Level = 0, LuckUntil = 0, SpeedUntil = 0, Receipt = "" },
		Periods = {},
	}
	for _, scope in ipairs(Missions.Scopes) do
		result.Periods[scope] = newPeriod(context.Keys[scope])
	end
	if raw == nil then
		return result
	end
	assert(
		type(raw) == "table"
			and (raw.Version == 1 or raw.Version == 2)
			and integer(raw.Coins),
		"Dados de missões inválidos"
	)
	result.Coins = raw.Coins
	result.Spent = raw.Spent or 0
	assert(integer(result.Spent), "Gastos inválidos")
	if raw.Shop then
		local shop = raw.Shop
		assert(
			type(shop) == "table"
				and integer(shop.Revision)
				and integer(shop.Level)
				and shop.Level <= 5
				and integer(shop.LuckUntil)
				and integer(shop.SpeedUntil)
				and type(shop.Receipt) == "string"
				and #shop.Receipt <= 128,
			"Loja inválida"
		)
		result.Shop = table.clone(shop)
	end
	if raw.Version == 1 then
		assert(
			integer(raw.Day)
				and raw.Day <= context.Keys.daily
				and integer(raw.Rolls)
				and type(raw.LoginClaimed) == "boolean"
				and type(raw.RollClaimed) == "boolean",
			"Dados diários antigos inválidos"
		)
		if raw.Day == context.Keys.daily then
			local period = result.Periods.daily
			period.Rolls = raw.Rolls
			if raw.LoginClaimed then
				period.Claimed.login = true
			end
			if raw.RollClaimed then
				period.Claimed.rolls = true
			end
		end
		return result
	end
	assert(type(raw.Periods) == "table", "Períodos inválidos")
	for _, scope in ipairs(Missions.Scopes) do
		local old = raw.Periods[scope]
		assert(
			type(old) == "table" and integer(old.Key) and old.Key <= context.Keys[scope],
			"Período futuro ou inválido"
		)
		assert(
			integer(old.Rolls) and integer(old.Seconds) and type(old.Counts) == "table",
			"Contadores inválidos"
		)
		local counts, count = {}, 0
		for key, value in pairs(old.Counts) do
			assert(validId(key) and integer(value), "Contador de aura inválido")
			count += 1
			assert(count <= 1000, "Contadores excedem limite")
			counts[key] = value
		end
		local found, equipped, claimed =
			setCopy(old.Found), setCopy(old.Equipped), setCopy(old.Claimed)
		if old.Key == context.Keys[scope] then
			result.Periods[scope] = {
				Key = old.Key,
				Rolls = old.Rolls,
				Seconds = old.Seconds,
				Counts = counts,
				Found = found,
				Equipped = equipped,
				Claimed = claimed,
			}
		end
	end
	return result
end
local function union(a, b)
	for key in pairs(b) do
		a[key] = true
	end
end
function Missions.Merge(new, old, context, additive)
	local incoming, result = Missions.Decode(new, context), Missions.Decode(old, context)
	local earned = math.max(result.Coins + result.Spent, incoming.Coins + incoming.Spent)
	result.Spent = math.max(result.Spent, incoming.Spent)
	result.Coins = earned - result.Spent
	if incoming.Shop.Revision > result.Shop.Revision then
		result.Shop = table.clone(incoming.Shop)
	end
	for _, scope in ipairs(Missions.Scopes) do
		local a, b = result.Periods[scope], incoming.Periods[scope]
		a.Rolls = additive and math.min(caps[scope].Rolls, a.Rolls + b.Rolls)
			or math.max(a.Rolls, b.Rolls)
		a.Seconds = additive and math.min(caps[scope].Seconds, a.Seconds + b.Seconds)
			or math.max(a.Seconds, b.Seconds)
		for key, value in pairs(b.Counts) do
			a.Counts[key] = additive
					and math.min(
						caps[scope].Items[key] or 0,
						(a.Counts[key] or 0) + value
					)
				or math.max(a.Counts[key] or 0, value)
		end
		union(a.Found, b.Found)
		union(a.Equipped, b.Equipped)
		union(a.Claimed, b.Claimed)
	end
	return result
end
function Missions.Record(data, kind, id, seconds, context)
	local dirty = false
	for _, scope in ipairs(Missions.Scopes) do
		local p = data.Periods[scope]
		if p.Key ~= context.Keys[scope] then
			p = newPeriod(context.Keys[scope])
			data.Periods[scope] = p
			dirty = true
		end
		if kind == "roll" then
			if p.Rolls < caps[scope].Rolls then
				p.Rolls += 1
				dirty = true
			end
			if id then
				if not p.Found[id] then
					p.Found[id] = true
					dirty = true
				end
				local cap = caps[scope].Items[id] or 0
				if (p.Counts[id] or 0) < cap then
					p.Counts[id] = (p.Counts[id] or 0) + 1
					dirty = true
				end
			end
		elseif kind == "equip" and id and not p.Equipped[id] then
			p.Equipped[id] = true
			dirty = true
		elseif kind == "time" then
			local value =
				math.min(seconds, math.max(0, context.Now - context.Starts[scope]))
			value = math.min(caps[scope].Seconds, p.Seconds + value)
			if value ~= p.Seconds then
				p.Seconds = value
				dirty = true
			end
		end
	end
	return dirty
end
local function count(set)
	local value = 0
	for _ in pairs(set) do
		value += 1
	end
	return value
end
function Missions.Progress(period, quest)
	if quest.Metric == "Login" then
		return 1
	end
	if quest.Metric == "Item" then
		return math.min(quest.Goal, period.Counts[quest.Item] or 0)
	end
	if quest.Metric == "Found" or quest.Metric == "Equipped" then
		return math.min(quest.Goal, count(period[quest.Metric]))
	end
	return math.min(quest.Goal, period[quest.Metric])
end
function Missions.Quest(scope, id)
	return byId[scope] and byId[scope][id]
end
function Missions.Claim(new, old, context, scope, id, requestKey)
	local result = Missions.Merge(new, old, context)
	local quest = Missions.Quest(scope, id)
	if not quest or requestKey ~= context.Keys[scope] then
		return result
	end
	local period = result.Periods[scope]
	if not period.Claimed[id] and Missions.Progress(period, quest) >= quest.Goal then
		period.Claimed[id] = true
		result.Coins += quest.Reward
	end
	return result
end
function Missions.View(data, context)
	local result = {}
	for _, scope in ipairs(Missions.Scopes) do
		local quests = {}
		for _, quest in ipairs(Missions.Catalog[scope]) do
			local progress = Missions.Progress(data.Periods[scope], quest)
			table.insert(quests, {
				Id = quest.Id,
				Title = quest.Title,
				Description = quest.Description,
				Progress = progress,
				Goal = quest.Goal,
				Reward = quest.Reward,
				ProgressLabel = quest.Metric == "Seconds"
						and (math.floor(progress / 60) .. "/" .. math.floor(
							quest.Goal / 60
						) .. " min")
					or (progress .. "/" .. quest.Goal),
				Claimed = data.Periods[scope].Claimed[quest.Id] == true,
			})
		end
		result[scope] = {
			Name = Missions.Names[scope],
			Key = context.Keys[scope],
			ResetAt = context.Resets[scope],
			Missions = quests,
		}
	end
	return result
end
-- Preços e benefícios definidos exclusivamente no servidor.
Missions.Products = {
	{
		Id = "luck",
		Name = "Poção de sorte",
		Description = "2x chance de Raro ou superior por 5 min",
		Price = 750,
	},
	{
		Id = "speed",
		Name = "Poção de velocidade",
		Description = "Intervalo de roll 25% menor por 5 min",
		Price = 500,
	},
	{
		Id = "income",
		Name = "Melhoria de moedas",
		Description = "+1 moeda por roll por nível; máximo 5",
		Price = 1000,
	},
}
function Missions.Buy(new, old, ctx, id, receipt)
	local result = Missions.Merge(new, old, ctx)
	if result.Shop.Receipt == receipt then
		return result
	end
	if result.Shop.Revision ~= (new.Shop and new.Shop.Revision or 0) then
		return result
	end
	local product
	for _, entry in ipairs(Missions.Products) do
		if entry.Id == id then
			product = entry
		end
	end
	if not product then
		return result
	end
	local price = product.Price
	if id == "income" then
		if result.Shop.Level >= 5 then
			return result
		end
		price *= result.Shop.Level + 1
	elseif result.Shop[id == "luck" and "LuckUntil" or "SpeedUntil"] > ctx.Now then
		return result -- Não compra de novo enquanto a poção estiver ativa.
	end
	if result.Coins < price then
		return result
	end
	result.Spent += price
	result.Coins -= price
	result.Shop.Revision += 1
	result.Shop.Receipt = receipt
	if id == "income" then
		result.Shop.Level += 1
	elseif id == "luck" then
		result.Shop.LuckUntil = ctx.Now + 300
	else
		result.Shop.SpeedUntil = ctx.Now + 300
	end
	return result
end
return Missions
