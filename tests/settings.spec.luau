-- Simula opções, restauração visual, topbar e faixas locais.
local function signal() return { Connect = function(self,fn) self.fn = fn; return { Disconnect = function() end } end } end
local objects = {}
local function new(class,parent)
 local object = { ClassName = class, Enabled = true, attributes = {}, Activated = signal(), DescendantAdded = signal(), ChildAdded = signal(), Parent = parent }
 function object:IsA(name) return self.ClassName == name or (name == "Light" and self.ClassName == "PointLight") end
 function object:GetAttribute(name) return self.attributes[name] end
 function object:SetAttribute(name,value) self.attributes[name] = value end
 function object:GetChildren()
  local result = {}
  for _,v in ipairs(objects) do if v.Parent == self then table.insert(result,v) end end
  return result
 end
 function object:GetDescendants()
  local result = {}
  for _,v in ipairs(self:GetChildren()) do
   table.insert(result,v)
   for _,child in ipairs(v:GetDescendants()) do table.insert(result,child) end
  end
  return result
 end
 function object:Clear() self.cleared = true end
 function object:Stop() self.IsPlaying = false; self.stopped = true end
 function object:Play() self.IsPlaying = true; self.plays = (self.plays or 0)+1 end
 table.insert(objects,object)
 return object
end
local Instance = { new = new }
local UDim = { new = function(...) return {...} end }
local UDim2 = { new = function(...) return {...} end, fromScale = function(...) return {...} end, fromOffset = function(...) return {...} end }
local Vector2 = { new = function(...) return {...} end }
local Color3 = { new = function(...) return {...} end, fromRGB = function(...) return {...} end }
local Enum = { Font = { GothamBold = "Bold" }, SortOrder = { LayoutOrder = 1 }, AutomaticSize = { Y = 1 } }
local playerGui = new("PlayerGui")
local player = { attributes = { RNGReady = true }, CharacterAdded = signal(), attrSignal = signal() }
function player:GetAttribute(id) return self.attributes[id] end
function player:SetAttribute(id,value) self.attributes[id] = value end
function player:GetAttributeChangedSignal() return self.attrSignal end
function player:WaitForChild() return playerGui end
local other = { CharacterAdded = signal() }
player.Character = new("Model")
other.Character = new("Model")
local function aura(character)
 local attachment = new("Attachment",character)
 attachment:SetAttribute("RNGAuraEffect",true)
 local beam = new("Beam",attachment)
 local particles = new("ParticleEmitter",attachment)
 local disabled = new("Beam",attachment); disabled.Enabled = false
 local title = new("BillboardGui",character); title.Name = "RNGAuraTitle"
 local unrelated = new("Beam",character)
 local sound = new("Sound",character); sound.Name = "Running"
 return beam,particles,disabled,title,unrelated,sound
end
local ownBeam,ownParticles,disabled,ownTitle,unrelated,running = aura(player.Character)
local otherBeam = aura(other.Character)
local rollGui = new("ScreenGui",playerGui); rollGui.Name = "RNGGui"
local rollSound = new("Sound",rollGui); rollSound.Name = "RNGRollSound"
local nonGameGui = new("ScreenGui",playerGui); nonGameGui.Name = "ExternalGui"
local Players = { LocalPlayer = player, PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function() return {player,other} end }
local topbar = signal()
local GuiService = { TopbarInset = { Min = { X = 250, Y = 0 }, Width = 700, Height = 58 }, GetPropertyChangedSignal = function() return topbar end }
local inventory = { OnClientEvent = signal(), FireServer = function() end }
local remotes = { WaitForChild = function() return inventory end }
local SoundService = new("SoundService")
local services = { Players = Players, SoundService = SoundService, GuiService = GuiService, ReplicatedStorage = { WaitForChild = function() return remotes end } }
local game = { GetService = function(_,name) return services[name] end }
local tasks = {}
local task = { spawn = function(fn) table.insert(tasks,fn) end, wait = function() coroutine.yield() end }
-- SETTINGS_SOURCE
local count = 0
local function check(value) assert(value); count += 1 end
local function find(text)
 for _,object in ipairs(objects) do if object.Text == text then return object end end
end
local function named(name)
 for _,object in ipairs(objects) do if object.Name == name then return object end end
end
local function toggle(label,on) find(label .. "\n" .. (on and "LIGADO" or "DESLIGADO")).Activated.fn() end
check(named("SettingsGear").Position[1] == 258)
check(ownBeam.Enabled and otherBeam.Enabled and not disabled.Enabled)
toggle("Mostrar minha aura equipada",true)
check(not ownBeam.Enabled and not ownTitle.Enabled and otherBeam.Enabled)
check(ownParticles.cleared and unrelated.Enabled)
toggle("Mostrar minha aura equipada",false)
check(ownBeam.Enabled and ownTitle.Enabled and not disabled.Enabled)
toggle("Mostrar auras dos outros",true)
check(not otherBeam.Enabled and ownBeam.Enabled)
local newBeam = new("Beam",otherBeam.Parent)
other.Character.DescendantAdded.fn(newBeam)
check(not newBeam.Enabled)
toggle("Mostrar interface do jogo",true)
check(not rollGui.Enabled and named("RNGSettingsGui").Enabled and nonGameGui.Enabled)
local lateGui = new("ScreenGui",playerGui); lateGui.Name = "RNGStatusGui"; playerGui.ChildAdded.fn(lateGui)
check(not lateGui.Enabled)
toggle("Mostrar interface do jogo",false)
check(rollGui.Enabled and lateGui.Enabled)
toggle("Áudio do Roblox (passos e efeitos)",true)
check(running.SoundGroup.Volume == 0)
toggle("Áudio do Roblox (passos e efeitos)",false)
check(running.SoundGroup.Volume == 1)
toggle("Sons das rolagens",true)
check(player.attributes.RNGRollAudio == false and rollSound.stopped)
local ambient = coroutine.create(tasks[1]); assert(coroutine.resume(ambient))
check(named("RNGEnvironmentNote1").IsPlaying)
toggle("Música ambiente do jogo",true)
check(not named("RNGEnvironmentNote1").IsPlaying and named("RNGGameMusic").Volume == 0)
tasks[3]() -- recebe equipamento confirmado pelo servidor
inventory.OnClientEvent.fn({ Equipped = "rare" })
local auraMusic = coroutine.create(tasks[2]); assert(coroutine.resume(auraMusic))
check(named("RNGAuraNote1").IsPlaying)
toggle("Música da aura equipada",true)
check(not named("RNGAuraNote1").IsPlaying and named("RNGAuraMusic").Volume == 0)
inventory.OnClientEvent.fn({ Equipped = nil })
check(not named("RNGAuraNote1").IsPlaying)
print("Settings: " .. count .. " verificações passaram (interface e áudio simulados)")
