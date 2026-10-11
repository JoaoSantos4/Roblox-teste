-- Harness com serviços simulados. Não substitui testes multiplayer no Studio.
local Profile = require("../roblox/ServerScriptService/RNGProfile")
local Config = { Cooldown = 1.5, FastCooldown = 0.6, AutosaveSeconds = 60, Items = {
    { Id = "common", Name = "Comum", Odds = 2, Color = "white" },
    { Id = "rare", Name = "Raro", Odds = 50, Color = "blue" },
    { Id = "secret", Name = "Segredo", Odds = 1000000, Color = "red", Secret = true },
} }
local now = 0
local os = { clock = function() return now end }
local DateTime = { now = function() return { UnixTimestampMillis = 1000 + now * 1000 } end }
local Color3 = { fromRGB = function() return "gray" end }
local Random = { new = function() return { NextNumber = function() return 0.1 end } end }
local task = { spawn = function() end, wait = function() end }
local warn = function() end
local function signal()
    local value = {}
    function value:Connect(fn) self.fn = fn; return { Disconnect = function() end } end
    return value
end
local objects = {}
local Instance = { new = function(class)
    local object = { ClassName = class }
    if class == "RemoteEvent" then
        object.OnServerEvent = signal()
        function object:FireClient(player, payload)
            self.last = payload
            self.calls = (self.calls or 0) + 1
            if payload.Status == "Result" then self.results = (self.results or 0) + 1 end
        end
        function object:FireAllClients(payload) self.last = payload end
    end
    table.insert(objects, object)
    return object
end }
local Players = { PlayerAdded = signal(), PlayerRemoving = signal() }
function Players:GetPlayers() return {} end
local saved = { Version = 1, BestOdds = 50, BestId = "rare" }
local failLoad = false
local writes = 0
local Store = {}
function Store:GetAsync() if failLoad then error("Unavailable") end; return saved end
function Store:UpdateAsync(key, callback) writes += 1; saved = callback(saved); return saved end
local services = { Players = Players, ReplicatedStorage = {},
    DataStoreService = { GetDataStore = function() return Store end } }
local game = { GetService = function(_, name) return services[name] end, BindToClose = function() end }
local script = { Parent = { WaitForChild = function(_, name) return name end } }
local questRolls, questEquips, lastQuestAura = 0, 0, nil
local require = function(name)
    if name == "RNGRankings" then return { Start = function() end, Publish = function() end } end
    if name == "RNGConfig" then return Config end
    if name == "RNGAuraEffect" then return { Apply = function() end } end
    if name == "RNGQuests" then return {
        Start = function() end,
        Bonuses = function() return 1, 1 end,
        RecordRoll = function(_, item) questRolls += 1; lastQuestAura = item and item.Id end,
        RecordEquip = function() questEquips += 1 end,
    } end
    return Profile
end

-- SERVER_SOURCE

local count = 0
local function check(condition) assert(condition); count += 1 end
local function event(name)
    for _, object in ipairs(objects) do if object.Name == name then return object end end
    error("Missing " .. name)
end
local function player(id)
    local value = { UserId = id, Name = "Test", Parent = Players, CharacterAdded = signal(), attributes = {} }
    function value:SetAttribute(key, data) self.attributes[key] = data end
    function value:Kick(message) self.kicked = message end
    return value
end
local p = player(1)
Players.PlayerAdded.fn(p)
local inventory, equip, roll = event("Inventory"), event("Equip"), event("Roll")
check(p.attributes.RNGReady == true and inventory.last.Owned.rare)
equip.OnServerEvent.fn(p, "divine")
check(inventory.last.Equipped == nil)
check(questEquips == 0)
now = 1
equip.OnServerEvent.fn(p, "rare")
check(inventory.last.Equipped == "rare")
check(questEquips == 1)
equip.OnServerEvent.fn(p, "") -- bloqueado pelo cooldown
check(inventory.last.Equipped == "rare")
now = 2
equip.OnServerEvent.fn(p, {})
check(inventory.last.Equipped == "rare")
roll.OnServerEvent.fn(p, "divine", 50000) -- argumentos falsos ignorados
check(roll.last == nil)
check(questRolls == 0)
roll.OnServerEvent.fn(p, false, 1)
check(roll.last.Name == "Comum" and inventory.last.Owned.common)
check(roll.last.Cooldown == 1.5 and not roll.last.Fast and roll.last.RequestId == 1)
check(questRolls == 1 and lastQuestAura == "common")
check(inventory.last.Owned.divine == nil)
local rolls = roll.results
roll.OnServerEvent.fn(p)
check(roll.results == rolls and roll.last.Status == "Cooldown")
check(questRolls == 1)
roll.OnServerEvent.fn(p, true, 2) -- trocar de modo não encurta o intervalo atual
check(roll.results == rolls)
now = 3.6
roll.OnServerEvent.fn(p, true, 3)
check(roll.results == rolls + 1 and roll.last.Fast and roll.last.Cooldown == 0.6)
now = 3.8
roll.OnServerEvent.fn(p, true, 4)
check(roll.results == rolls + 1)
now = 4.25
roll.OnServerEvent.fn(p, 0.001, 5)
check(roll.results == rolls + 1)
roll.OnServerEvent.fn(p, true, -1)
check(roll.results == rolls + 1)
roll.OnServerEvent.fn(p, true, 6)
check(roll.results == rolls + 2)
rolls = roll.results
now = 4
equip.OnServerEvent.fn(p, "")
check(inventory.last.Equipped == nil)
Players.PlayerRemoving.fn(p)
check(saved.Version == 2 and saved.Owned.common and saved.Owned.rare)
check(saved.BestOdds == 50 and saved.Equipped == nil and saved.EquipTime > 0)
check(saved.TotalRolls == 3) -- pedidos falsos e cooldown não contam
local previousWrites = writes
failLoad = true
local broken = player(2)
Players.PlayerAdded.fn(broken)
check(broken.kicked ~= nil and broken.attributes.RNGReady == false)
roll.OnServerEvent.fn(broken)
check(roll.results == rolls)
Players.PlayerRemoving.fn(broken)
check(writes == previousWrites)
check(inventory.last.Catalog[3].Secret == true and inventory.last.Owned.secret == nil)
print("Server: " .. count .. " verificações passaram (serviços simulados)")
