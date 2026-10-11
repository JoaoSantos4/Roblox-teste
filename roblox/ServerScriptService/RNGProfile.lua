-- ModuleScript RNGProfile em ServerScriptService.
local Profile = {}
local function number(value)
	return type(value) == "number"
		and value >= 0
		and value < math.huge
		and value == math.floor(value)
end
local function id(value)
	return type(value) == "string" and #value > 0 and #value <= 128
end
function Profile.Decode(raw)
	local data = {
		Version = 2,
		BestOdds = 0,
		TotalRolls = 0,
		PlaySeconds = 0,
		Owned = {},
		EquipTime = 0,
	}
	if raw == nil then
		return data
	end
	assert(
		type(raw) == "table" and (raw.Version == 1 or raw.Version == 2),
		"Versão inválida"
	)
	assert(
		number(raw.BestOdds) and (raw.BestId == nil or id(raw.BestId)),
		"Recorde inválido"
	)
	data.BestOdds, data.BestId = raw.BestOdds, raw.BestId
	data.TotalRolls = raw.TotalRolls or 0
	assert(
		number(data.TotalRolls) and data.TotalRolls < 9007199254740991,
		"Total de rolls inválido"
	)
	data.PlaySeconds = raw.PlaySeconds or 0
	assert(
		number(data.PlaySeconds) and data.PlaySeconds < 9007199254740991,
		"Tempo jogado inválido"
	)
	if raw.Version == 1 then
		-- Antes, somente a melhor aura era salva.
		if raw.BestId then
			data.Owned[raw.BestId] = true
		end
		return data
	end
	assert(type(raw.Owned) == "table" and number(raw.EquipTime), "Inventário inválido")
	local count = 0
	for key, owned in pairs(raw.Owned) do
		assert(id(key) and owned == true, "Aura inválida")
		count += 1
		assert(count <= 1000, "Inventário excede limite")
		data.Owned[key] = true
	end
	assert(
		raw.Equipped == nil or (id(raw.Equipped) and data.Owned[raw.Equipped]),
		"Equipamento inválido"
	)
	data.Equipped, data.EquipTime = raw.Equipped, raw.EquipTime
	return data
end
function Profile.Merge(new, old)
	local result, incoming = Profile.Decode(old), Profile.Decode(new)
	result.TotalRolls = math.max(result.TotalRolls, incoming.TotalRolls)
	result.PlaySeconds = math.max(result.PlaySeconds, incoming.PlaySeconds)
	for key in pairs(incoming.Owned) do
		result.Owned[key] = true
	end
	if incoming.BestOdds > result.BestOdds then
		result.BestOdds, result.BestId = incoming.BestOdds, incoming.BestId
	end
	if incoming.EquipTime > result.EquipTime then
		result.Equipped, result.EquipTime = incoming.Equipped, incoming.EquipTime
	end
	return result
end
return Profile
