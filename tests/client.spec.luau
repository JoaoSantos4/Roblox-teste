-- Simula relógio, agendamentos e respostas para testar o Auto Roll.
local now, queue = 0, {}
local function schedule(co, at) table.insert(queue, { co = co, at = at }) end
local function launch(fn, ...) local co = coroutine.create(fn); schedule(co, now); return co end
local task = {}
function task.delay(seconds, fn) schedule(coroutine.create(fn), now + seconds) end
function task.wait(seconds) return coroutine.yield(seconds or 0.01) end
local function advance(target)
    while true do
        local first, at
        for index, job in ipairs(queue) do
            if not at or job.at < at then first, at = index, job.at end
        end
        if not first or at > target then now = target; return end
        local job = table.remove(queue, first)
        now = job.at
        local ok, delay = coroutine.resume(job.co)
        assert(ok, delay)
        if coroutine.status(job.co) ~= "dead" then schedule(job.co, now + delay) end
    end
end
local os = { clock = function() return now end }
local function signal()
    return { Connect = function(self, fn) self.fn = fn end }
end
local objects = {}
local Instance = { new = function(class, parent)
    local value = { ClassName = class, Parent = parent, Activated = signal() }
    function value:Stop() end
    table.insert(objects, value)
    return value
end }
local UDim = { new = function(...) return {...} end }
local UDim2 = { new = function(...) return {...} end, fromScale = function(...) return {...} end, fromOffset = function(...) return {...} end }
local Vector2 = { new = function(...) return {...} end }
local Color3 = { new = function(...) return {...} end, fromRGB = function(...) return {...} end }
local Enum = { Font = { GothamBold = "Bold" }, EasingStyle = { Back = "Back" } }
local TweenInfo = { new = function(...) return {...} end }
local Random = { new = function() return { NextInteger = function() return 1 end } end }
local player = { ready = true, changed = signal() }
function player:GetAttribute(key) if key == "RNGRollAudio" then return self.rollAudio end; return self.ready end
function player:GetAttributeChangedSignal() return self.changed end
function player:WaitForChild() return {} end
local roll = { OnClientEvent = signal(), requests = {} }
local muted, special, cooldownReply = false, false, false
function roll:FireServer(fast, id)
    table.insert(self.requests, { Fast = fast, Id = id, Time = now })
    if muted then return end
    task.delay(0.01, function()
        if cooldownReply then
            cooldownReply = false
            roll.OnClientEvent.fn({ Status = "Cooldown", RetryAfter = 0.4, RequestId = id })
        else
            roll.OnClientEvent.fn({ Status = "Result", Fast = fast, RequestId = id,
                Name = special and "Lendário" or "Comum", Odds = special and 5000 or 2,
                Color = {}, Cooldown = fast and 0.6 or 1.5 })
        end
    end)
end
local remotes = { WaitForChild = function(_, name)
    return name == "Roll" and roll or { OnClientEvent = signal() }
end }
local soundPlays = 0
local services = {
    Players = { LocalPlayer = player },
    ReplicatedStorage = { WaitForChild = function() return remotes end },
    TweenService = { Create = function() return { Play = function() end, Cancel = function() end } end },
    TextChatService = {}, SoundService = { PlayLocalSound = function() soundPlays += 1 end },
}
local game = { GetService = function(_, name) return services[name] end }

-- CLIENT_SOURCE

local function find(text)
    for _, value in ipairs(objects) do if value.Text == text then return value end end
    error("Missing " .. text)
end
local auto, fast, manual = find("AUTO: DESLIGADO"), find("RÁPIDO: DESLIGADO"), find("ROLL")
local function click(value) launch(value.Activated.fn); advance(now) end
local count = 0
local function check(value) assert(value); count += 1 end
click(fast)
click(auto)
check(#roll.requests == 1 and roll.requests[1].Fast)
click(manual); click(manual)
check(#roll.requests == 1)
advance(2.5)
check(#roll.requests >= 3)
for index = 2, #roll.requests do
    check(roll.requests[index].Time - roll.requests[index-1].Time >= 0.6)
end
click(auto)
local stopped = #roll.requests
advance(5)
check(#roll.requests == stopped)
-- Troca rápida de AUTO durante uma rodada não cria loops duplicados.
click(auto); click(auto); click(auto)
check(#roll.requests == stopped + 1)
advance(6.5)
click(auto)
stopped = #roll.requests
advance(9)
check(#roll.requests == stopped)
-- Resposta de outro pedido não conclui o atual.
muted = true
click(auto)
local currentId = roll.requests[#roll.requests].Id
launch(function() roll.OnClientEvent.fn({ RequestId = currentId - 1 }) end)
advance(now)
check(manual.Text == "Aguarde...")
advance(18)
check(auto.Text == "AUTO: DESLIGADO" and manual.Text == "ROLL")
check(#roll.requests == stopped + 1)
-- Volta após o timeout e trata a resposta de cooldown sem rolar em paralelo.
muted, cooldownReply = false, true
click(auto)
local requests = #roll.requests
advance(18.3)
check(#roll.requests == requests)
advance(19.5)
check(#roll.requests > requests)
click(auto)
advance(21)
-- Uma conquista especial mantém a revelação longa mesmo em rápido.
special = true
click(manual)
advance(21.1)
check(manual.Text == "Aguarde...")
advance(23)
check(manual.Text == "Aguarde...")
advance(24.5)
check(manual.Text == "ROLL")
player.rollAudio = false
local beforeAudio = soundPlays
click(manual)
advance(28)
check(soundPlays == beforeAudio and manual.Text == "ROLL")
player.rollAudio = true
click(manual)
advance(32)
check(soundPlays > beforeAudio and manual.Text == "ROLL")
print("Client: " .. count .. " verificações passaram (relógio e serviços simulados)")
