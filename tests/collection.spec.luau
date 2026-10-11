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
local folder = { WaitForChild = function(_,name) assert(name == "Inventory"); return inventory end }
local services = { Players = { LocalPlayer = player }, ReplicatedStorage = { WaitForChild = function() return folder end } }
local game = { GetService = function(_,name) return services[name] end }
-- COLLECTION_SOURCE
local count = 0
local function check(value) assert(value); count += 1 end
local function find(text)
 for _,value in ipairs(objects) do if value.Text == text and not value.destroyed then return value end end
end
local catalog = {
 { Id = "common", Name = "Comum", Odds = 2, Color = "white" },
 { Id = "rare", Name = "Raro", Odds = 50, Color = "blue" },
 { Id = "secret", Name = "Segredo", Odds = 1000000, Color = "red", Secret = true },
}
check(inventory.requests == 0)
player.ready = true; player.changed.fn()
check(inventory.requests == 1)
inventory.OnClientEvent.fn({ Catalog = catalog, Owned = { common = true, removed = true }, Equipped = "common" })
check(find("1/3 descobertas • 33% • Faltam 2") ~= nil)
check(find("??? — Aura secreta\n1 em 1.000.000\nAINDA NÃO DESCOBERTA") ~= nil)
check(find("Raro\n1 em 50\nAINDA NÃO DESCOBERTA") ~= nil)
check(find("Comum\n1 em 2\nDESCOBERTA • EQUIPADA") ~= nil)
local initial = #objects
inventory.OnClientEvent.fn({ Catalog = catalog, Owned = { common = true, rare = true, secret = true }, Equipped = "secret" })
check(#objects == initial) -- não recria a lista a cada roll
check(find("3/3 descobertas • 100% • Faltam 0") ~= nil)
check(find("Segredo\n1 em 1.000.000\nDESCOBERTA • EQUIPADA") ~= nil)
find("COLEÇÃO").Activated.fn()
check(inventory.requests == 1) -- sync respeita intervalo
find("COLEÇÃO").Activated.fn(); time = 2; find("COLEÇÃO").Activated.fn()
check(inventory.requests == 2)
inventory.OnClientEvent.fn({ Catalog = {}, Owned = { secret = true } })
check(find("0/0 descobertas • 0% • Faltam 0") ~= nil)
print("Collection: " .. count .. " verificações passaram (interface simulada)")
