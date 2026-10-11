-- Coleção: progresso usa apenas IDs do catálogo; segredo e auras bloqueadas não equipam.
local function signal() return { Connect = function(self,fn) self.fn = fn end } end
local objects = {}
local Instance = { new = function(class,parent)
 local value = { ClassName = class, Parent = parent, Activated = signal() }
 function value:Destroy() self.destroyed = true end
 table.insert(objects,value)
 return value
end }
local UDim = { new = function(...) return {...} end }
local UDim2 = { new = function(...) return {...} end, fromScale = function(...) return {...} end, fromOffset = function(...) return {...} end }
local Vector2 = { new = function(...) return {...} end }
local Color3 = { new = function(...) return {...} end, fromRGB = function(...) return {...} end }
local Enum = { Font = { GothamBold = "Bold" }, SortOrder = { LayoutOrder = 1 }, AutomaticSize = { Y = 1 }, TextXAlignment = { Left = 1 } }
local time = 0
local os = { clock = function() return time end }
local player = { ready = false, changed = signal(), WaitForChild = function() return {} end }
function player:GetAttribute() return self.ready end
function player:GetAttributeChangedSignal() return self.changed end
local inventory = { OnClientEvent = signal(), requests = 0 }
function inventory:FireServer(...) assert(select("#",...) == 0); self.requests += 1 end
local folder = { WaitForChild = function(_,name) assert(name == "Status"); return inventory end }
local services = { Players = { LocalPlayer = player }, ReplicatedStorage = { WaitForChild = function() return folder end } }
local game = { GetService = function(_,name) return services[name] end }
local task = { spawn = function() end }
local DateTime = { now = function() return { UnixTimestamp = 1000 } end }
-- STATUS_SOURCE
local count = 0
local function check(value) assert(value); count += 1 end
local function find(text)
 for _,value in ipairs(objects) do if value.Text == text then return value end end
end
check(inventory.requests == 0)
find("STATUS").Activated.fn()
check(inventory.requests == 0)
player.ready = true; player.changed.fn()
check(inventory.requests == 1)
inventory.OnClientEvent.fn({ Ready = true, PlaySeconds = 3600, SessionSeconds = 60, TotalRolls = 12345,
 SessionRolls = 12, BestName = "Raro", BestOdds = 50, Equipped = "Comum", Discovered = 2, CatalogTotal = 7,
 Economy = { Ready = true, Coins = 2000, Level = 2, LuckUntil = 1100, SpeedUntil = 0 } })
check(find("Tempo total: 0d 01h 00m 00s") ~= nil)
check(find("Rolls totais: 12.345") ~= nil)
check(find("Coleção: 2/7 descobertas") ~= nil)
check(find("Moedas: 2.000") ~= nil)
check(find("Melhoria de moedas: 2/5 • 3 moedas por roll") ~= nil)
check(find("Poção de velocidade: Inativa") ~= nil)
check(find("Poção de sorte: Ativa • 0d 00h 01m 40s") ~= nil)
inventory.OnClientEvent.fn({ Ready = true, PlaySeconds = 0, SessionSeconds = 0, TotalRolls = 0,
 SessionRolls = 0, BestName = "Nenhuma", BestOdds = 0, Equipped = "Nenhuma", Discovered = 0, CatalogTotal = 7,
 Economy = { Ready = false } })
check(find("Moedas: Indisponível") ~= nil)
check(find("Melhor aura: Nenhuma") ~= nil)
find("STATUS").Activated.fn(); time = 1; find("STATUS").Activated.fn()
check(inventory.requests == 1)
print("Status: " .. count .. " verificações passaram (interface simulada)")
