-- Testa espelho global, ordem, cache e recuperação de falhas.
local count = 0
local function check(value) assert(value); count += 1 end
local function signal() return { Connect = function(self,fn) self.fn = fn end } end
local now = 0
local os = { clock = function() return now end }
local DateTime = { now = function() return { UnixTimestamp = now } end }
local warn = function() end
local spawned = {}
local task = { spawn = function(fn) table.insert(spawned,fn) end, wait = function() coroutine.yield() end }
local stores, reads, writes = {}, 0, 0
local failedWrite, failedRead = false, false
local function store(name)
 local object = { values = {} }
 function object:UpdateAsync(key,fn)
  if failedWrite then error("write failed") end
  writes += 1
  self.values[key] = fn(self.values[key])
 end
 function object:GetSortedAsync(ascending,limit,minimum)
  if failedRead then error("read failed") end
  check(ascending == false and limit == 20 and minimum == 1)
  reads += 1
  local rows = {}
  for key,value in pairs(self.values) do if value >= minimum then table.insert(rows,{ key = key, value = value }) end end
  table.sort(rows,function(a,b) return a.value > b.value end)
  return { GetCurrentPage = function() return rows end }
 end
 stores[name] = object
 return object
end
local Players = { PlayerRemoving = signal(), GetPlayerByUserId = function() return nil end, GetNameFromUserIdAsync = function(_,id) return "User" .. id end }
local remote
local Instance = { new = function()
 remote = { OnServerEvent = signal() }
 function remote:FireClient(player,value) self.last = value end
 function remote:FireAllClients(value) self.last = value end
 return remote
end }
local game = { GetService = function(_,name)
 if name == "Players" then return Players end
 if name == "DataStoreService" then return { GetOrderedDataStore = function(_,name) return store(name) end } end
 return {}
end, BindToClose = function() end }
local script = { Parent = { WaitForChild = function() return "RNGConfig" end } }
local require = function() return { Items = { { Odds = 50, Name = "Raro" }, { Odds = 5000, Name = "Lendário" } } } end
local Rankings = (function()
-- RANKINGS_SOURCE
end)()
Rankings.Start()
Rankings.Start()
check(#spawned == 2)
spawned[1]()
check(remote.last.Ready and #remote.last.Best == 0)
local worker = coroutine.create(spawned[2])
check(coroutine.resume(worker)) -- espera inicial
Rankings.Publish(1,50,100)
Rankings.Publish(2,5000,200)
Rankings.Publish(1,2,1) -- não reduz o espelho pendente
Rankings.Publish(3,0,0)
Rankings.Publish(-1,100,100)
Rankings.Publish(4,0/0,100)
now = 60
check(coroutine.resume(worker))
check(stores.RNG_GlobalBest_v1.values["1"] == 50)
check(stores.RNG_GlobalRolls_v1.values["1"] == 100)
check(stores.RNG_GlobalRolls_v1.values["3"] == nil)
check(remote.last.Best[1].UserId == 2 and remote.last.Best[1].Aura == "Lendário")
check(remote.last.Rolls[1].Value == 200)
local player = { Parent = Players }
local oldReads = reads
remote.OnServerEvent.fn(player)
remote.OnServerEvent.fn(player)
check(reads == oldReads) -- sync usa somente cache
Rankings.Publish(1,2,2)
now = 120
check(coroutine.resume(worker))
check(stores.RNG_GlobalBest_v1.values["1"] == 50 and stores.RNG_GlobalRolls_v1.values["1"] == 100)
failedWrite = true
Rankings.Publish(1,5000,300)
now = 180
check(coroutine.resume(worker))
check(stores.RNG_GlobalRolls_v1.values["1"] == 100)
failedWrite = false
now = 240
check(coroutine.resume(worker))
check(stores.RNG_GlobalRolls_v1.values["1"] == 300)
local prior = remote.last
failedRead = true
now = 300
check(coroutine.resume(worker))
check(remote.last == prior) -- mantém snapshot válido durante falha
print("Rankings: " .. count .. " verificações passaram (OrderedDataStore simulado)")
