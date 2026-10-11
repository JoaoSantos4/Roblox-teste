-- Construção e segurança do cenário; não substitui teste visual/físico no Studio.
local function signal() return { Connect = function(self,fn) self.fn = fn end } end
local methods = {}
local objects = {}
function methods:IsA(class)
 return self.ClassName == class or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "SpawnLocation"))
end
function methods:GetChildren()
 local list = {}
 for _,v in ipairs(objects) do if v.Parent == self then table.insert(list,v) end end
 return list
end
function methods:GetDescendants()
 local list = {}
 for _,v in ipairs(self:GetChildren()) do table.insert(list,v); for _,child in ipairs(v:GetDescendants()) do table.insert(list,child) end end
 return list
end
function methods:FindFirstChild(name)
 for _,v in ipairs(self:GetChildren()) do if v.Name == name then return v end end
end
function methods:FindFirstChildOfClass(class)
 for _,v in ipairs(self:GetChildren()) do if v.ClassName == class then return v end end
end
function methods:SetAttribute(name,value) self.attributes[name] = value end
function methods:FindFirstAncestorOfClass(class)
 local p = self.Parent
 while p do if p.ClassName == class then return p end; p=p.Parent end
end
function methods:PivotTo(frame) self.pivot = frame end
local function new(class)
 local object = setmetatable({ ClassName = class, Name = class, attributes = {}, Enabled = true, Touched = signal() }, { __index = methods })
 table.insert(objects,object)
 return object
end
local Instance = { new = new }
local vectorMeta
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMeta) end
vectorMeta = {
 __div = function(a,b) return vector(a.X/b,a.Y/b,a.Z/b) end,
 __add = function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end,
 __sub = function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end,
 __index = function(a,key) if key == "Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end end,
}
local Vector3 = { new = vector }
local frameMeta
local function frame(v) return setmetatable({ Position = v },frameMeta) end
frameMeta = { __mul = function(a,b) return frame(a.Position+b.Position) end, __add = function(a,b) return frame(a.Position+b) end }
local CFrame = { new = function(x,y,z) return frame(type(x)=="table" and x or vector(x or 0,y or 0,z or 0)) end,
 Angles = function() return frame(vector(0,0,0)) end, lookAt = function(position) return frame(position) end }
local Color3 = { fromRGB = function(...) return {...} end, new = function(...) return {...} end }
local UDim2 = { fromScale = function(...) return {...} end }
local Enum = { Material = { SmoothPlastic=1, Sand=2, Grass=3, Wood=4, WoodPlanks=5, Slate=6, Marble=7, Neon=8, Cobblestone=9 },
 SurfaceType = { Smooth=1 }, PartType = { Cylinder=1, Ball=2 }, NormalId = { Front=1 }, SurfaceGuiSizingMode={PixelsPerStud=1},Font={GothamBold=1} }
local Random = { new = function() return { NextNumber = function(_,low,high) return (low+high)/2 end } end }
local Workspace, Lighting = new("Workspace"),new("Lighting")
local baseplate = new("Part"); baseplate.Name = "Baseplate"; baseplate.Parent = Workspace
local oldSpawn = new("SpawnLocation"); oldSpawn.Name = "SpawnLocation"; oldSpawn.Parent = Workspace
local retained = new("Model"); retained.Name = "MeuModelo"; retained.Parent = Workspace
local player = { Character = new("Model") }
local Players = { PlayerAdded = signal(), PlayerRemoving = signal(), GetPlayers = function() return {player} end,
 GetPlayerFromCharacter = function(_,character) return character == player.Character and player or nil end }
local game = { GetService = function(_,name) return ({Workspace=Workspace,Lighting=Lighting,Players=Players})[name] end }
local now = 0
local os = { clock = function() return now end }
local warn = function() end
local build = function()
-- MAP_SOURCE
end
build()
local count = 0
local function check(value) assert(value); count += 1 end
local map = Workspace:FindFirstChild("RNGTropicalMap")
check(map and map.attributes.RNGGeneratedMap)
for _,name in ipairs({"Lobby Tropical","Bosque Natural","Mirante Solar","Templo Astral"}) do check(map:FindFirstChild(name) ~= nil) end
local spawn = map:FindFirstChild("Lobby Tropical"):FindFirstChild("RNGSpawn")
check(spawn and spawn.Neutral and spawn.Duration == 0 and spawn.Anchored)
check(player.RespawnLocation == spawn and player.Character.pivot ~= nil)
check(not oldSpawn.Enabled and not baseplate.CanCollide and baseplate.Transparency == 1)
check(retained.Parent == Workspace)
local parts,bridges,palms = 0,0,0
for _,object in ipairs(map:GetDescendants()) do
 if object:IsA("BasePart") then check(object.Anchored == true); parts += 1 end
 if object.Name == "Ponte" then bridges += 1 end
 if object.Name == "Coqueiro" then palms += 1 end
end
check(parts < 400 and bridges == 3 and palms == 25)
check(Lighting.ClockTime == 16 and Lighting:FindFirstChild("RNGAtmosphere") ~= nil)
local ocean = map:FindFirstChild("Oceano decorativo")
check(ocean.CanTouch and not ocean.CanCollide)
local hit = new("Part"); hit.Parent = player.Character
local initial = player.Character.pivot
ocean.Touched.fn(hit)
check(player.Character.pivot ~= initial)
local returned = player.Character.pivot
ocean.Touched.fn(hit)
check(player.Character.pivot == returned)
now = 3
ocean.Touched.fn(hit)
check(player.Character.pivot ~= returned)
local before = #objects
build()
check(#objects == before)
print("Map: " .. parts .. " peças ancoradas, 3 pontes, spawn, retorno e construção única passaram (simulados)")
