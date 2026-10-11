local Missions = require("../roblox/ServerScriptService/RNGDaily")
local clock, timestamp = 0, 1767268800 -- 01/01/2026 12:00 UTC
local os = { clock = function() return clock end }
local starts = { [2026] = { [1] = 1767225600, [2] = 1769904000, [3] = 1772323200, [12] = 1796083200 },
    [2027] = { [1] = 1798761600, [2] = 1801440000 } }
local DateTime = { fromUniversalTime = function(year, month) return { UnixTimestamp = starts[year][month] } end }
function DateTime.now()
    return { UnixTimestamp = timestamp, ToUniversalTime = function()
        if timestamp >= starts[2027][1] then return { Year = 2027, Month = 1 } end
        if timestamp >= starts[2026][12] then return { Year = 2026, Month = 12 } end
        return { Year = 2026, Month = timestamp < starts[2026][2] and 1 or 2 }
    end }
end
local task = { wait = function() end, spawn = function() end }
local warn = function() end
local function signal() return { Connect = function(self, fn) self.fn = fn end } end
local objects = {}
local Instance = { new = function()
    local object = { OnServerEvent = signal() }
    function object:FireClient(player, value) self.last = value end
    table.insert(objects, object)
    return object
end }
local Players = { PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function() return {} end }
local records = {}
local failedLoad, failedSave = false, false
local writes = 0
local Store = {}
function Store:GetAsync(key) if failedLoad then error("load failed") end; return records[key] end
function Store:UpdateAsync(key, fn)
    if failedSave then error("save failed") end
    writes += 1; records[key] = fn(records[key]); return records[key]
end
local guid = 0
local services = { HttpService = { GenerateGUID = function() guid += 1; return "purchase_" .. guid end }, Players = Players, ReplicatedStorage = {}, DataStoreService = { GetDataStore = function() return Store end } }
local game = { GetService = function(_, name) return services[name] end, BindToClose = function() end }
local script = { Parent = { WaitForChild = function() return "RNGDaily" end } }
local require = function() return Missions end
local Quests = (function()
-- QUEST_SOURCE
end)()
Quests.Start()
local event
for _, object in ipairs(objects) do if object.Name == "Daily" then event = object end end
local player = { UserId = 1, Parent = Players, attributes = {} }
function player:SetAttribute(key, value) self.attributes[key] = value end
local count = 0
local function check(value) assert(value); count += 1 end
local function request(action, scope, id, key)
    clock += 1; timestamp += 1
    event.OnServerEvent.fn(player, action, scope, id, key)
end
local function claim(scope, id) request("claim", scope, id, event.last.Periods[scope].Key) end
Players.PlayerAdded.fn(player)
check(player.attributes.RNGQuestsReady and event.last.Coins == 0)
check(#event.last.Periods.daily.Missions == 6 and #event.last.Periods.weekly.Missions == 6 and #event.last.Periods.monthly.Missions == 6)
check(event.last.Periods.weekly.ResetAt == 1767571200) -- segunda-feira 05/01
check(event.last.Periods.monthly.ResetAt == 1769904000) -- primeiro dia de fevereiro
claim("daily", "rolls")
check(records.player_1 == nil)
claim("daily", "login")
check(records.player_1.Coins == 200)
claim("daily", "login")
check(records.player_1.Coins == 200)
for _ = 1, 100 do Quests.RecordRoll(player, nil) end
claim("daily", "rolls")
check(records.player_1.Coins == 800)
Quests.RecordRoll(player, { Id = "rare" })
Quests.RecordRoll(player, { Id = "rare" })
claim("daily", "rare2")
check(records.player_1.Coins == 1202)
for _ = 1, 3 do Quests.RecordRoll(player, { Id = "epic" }) end
claim("weekly", "epic3")
check(records.player_1.Coins == 3705)
Quests.RecordRoll(player, { Id = "legendary" })
claim("monthly", "legendary1")
check(records.player_1.Coins == 18706)
Quests.RecordEquip(player, "common"); Quests.RecordEquip(player, "common")
claim("daily", "style1")
check(records.player_1.Coins == 18856)
claim("weekly", "style3")
check(records.player_1.Coins == 18856)
Quests.RecordEquip(player, "rare"); Quests.RecordEquip(player, "epic")
claim("weekly", "style3")
check(records.player_1.Coins == 19656)
request("claim", "monthly", "legendary1", -1)
check(records.player_1.Coins == 19656)
Players.PlayerRemoving.fn(player)
Players.PlayerAdded.fn(player)
check(event.last.Coins == 19656)
local seconds = event.last.Periods.daily.Missions[6].Progress
timestamp += 601
claim("daily", "time10")
check(records.player_1.Coins == 19906)
timestamp += 86400
request("sync")
check(event.last.Periods.daily.Missions[3].Progress == 0 and event.last.Periods.weekly.Missions[3].Claimed)
failedSave = true
claim("daily", "login")
check(event.last.Coins == 19906 and not event.last.Periods.daily.Missions[1].Claimed)
failedSave = false
claim("daily", "login")
check(event.last.Coins == 20106)
timestamp = 1798718400 -- 31/12/2026 12:00 UTC
request("sync")
check(event.last.Periods.monthly.ResetAt == 1798761600)
timestamp = 1798761600
request("sync")
check(event.last.Periods.monthly.ResetAt == 1801440000 and not event.last.Periods.monthly.Missions[4].Claimed)
local shopEvent
for _, object in ipairs(objects) do if object.Name == "Shop" then shopEvent = object end end
local function purchase(id)
 clock += 2
 shopEvent.OnServerEvent.fn(player, "buy", id)
end
local before = event.last.Coins
purchase("luck")
check(event.last.Coins == before - 750)
local luck, speed = Quests.Bonuses(player)
check(luck == 2 and speed == 1)
purchase("speed")
luck, speed = Quests.Bonuses(player)
check(luck == 2 and speed == 0.75)
purchase("income")
local current = event.last.Coins
Quests.RecordRoll(player, nil)
check(event.last.Coins == current + 2)
failedSave = true
purchase("income")
check(event.last.Coins == current + 2)
failedSave = false
Players.PlayerRemoving.fn(player)
check(records.player_1.Shop.Level == 1)
records.player_3 = { Version = 1, Day = math.floor(timestamp / 86400), Coins = 700,
    Rolls = 100, LoginClaimed = true, RollClaimed = true }
local legacy = { UserId = 3, Parent = Players, SetAttribute = function() end }
Players.PlayerAdded.fn(legacy)
check(event.last.Coins == 700 and event.last.Periods.daily.Missions[1].Claimed and event.last.Periods.daily.Missions[2].Claimed)
check(event.last.Periods.weekly.Missions[1].Progress == 0)
Players.PlayerRemoving.fn(legacy)
check(records.player_3.Version == 2 and records.player_3.Coins == 700)
local previousWrites = writes
failedLoad = true
local broken = { UserId = 2, Parent = Players, SetAttribute = function() end }
Players.PlayerAdded.fn(broken)
Quests.RecordRoll(broken, { Id = "rare" })
clock += 1; event.OnServerEvent.fn(broken, "sync")
check(event.last.Ready == false)
Players.PlayerRemoving.fn(broken)
check(writes == previousWrites and records.player_2 == nil)
print("Quests: " .. count .. " verificações passaram (serviços simulados)")
