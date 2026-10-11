-- Criação/limpeza com instâncias simuladas. Não renderiza partículas.
local Vector3 = { new = function(x, y, z) return { x, y, z } end }
local Vector2 = { new = function(x, y) return { x, y } end }
local ColorSequence = { new = function(color) return color end }
local Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
local ColorSequenceKeypoint = { new = function(time, color) return { time, color } end }
local NumberRange = { new = function(a, b) return { a, b } end }
local NumberSequence = { new = function(points) return points end }
local NumberSequenceKeypoint = { new = function(time, value) return { time, value } end }
local Enum = { NormalId = { Top = "Top" } }
local Instance = {}
function Instance.new(class)
    local object = { ClassName = class, children = {}, attributes = {} }
    function object:SetAttribute(key, value) self.attributes[key] = value end
    function object:GetAttribute(key) return self.attributes[key] end
    function object:Destroy()
        for index, child in ipairs(self.Parent.children) do
            if child == self then table.remove(self.Parent.children, index); break end
        end
    end
    return setmetatable(object, { __newindex = function(self, key, value)
        rawset(self, key, value)
        if key == "Parent" then table.insert(value.children, self) end
    end })
end
local Effects = require("../roblox/ServerScriptService/RNGAuraEffect")
local root = Instance.new("Part")
local character = {}
function character:FindFirstChild(name) if name == "HumanoidRootPart" then return root end end
function character:GetDescendants()
    local result = {}
    local function visit(object)
        table.insert(result, object)
        for _, child in ipairs(object.children) do visit(child) end
    end
    visit(root)
    return result
end
local unrelated = Instance.new("Attachment")
unrelated.Parent = root
Effects.Apply(character, { Odds = 2, Color = "white" })
assert(#root.children == 10)
local total = 0
for _, child in ipairs(root.children) do
    for _, effect in ipairs(child.children) do
        if effect.ClassName == "ParticleEmitter" then
            assert(effect.Color == "white" and effect.LockedToPart)
            total += effect.Rate
        end
    end
end
assert(total == 32)
Effects.Apply(character, { Odds = 50000, Color = "pink" })
assert(#root.children == 10)
total = 0
for _, child in ipairs(root.children) do
    for _, effect in ipairs(child.children) do
        if effect.ClassName == "ParticleEmitter" then
            assert(effect.Color == "pink")
            total += effect.Rate
        end
    end
end
assert(total == 80)
Effects.Apply(character, { Id = "legendary", Odds = 5000, Color = "gold" })
assert(#root.children == 30)
local beams, stars, rate = 0, 0, 0
for _, object in ipairs(character:GetDescendants()) do
    if object.ClassName == "Beam" then
        beams += 1
        assert(object.Attachment0 and object.Attachment1)
    elseif object.ClassName == "ParticleEmitter" then
        rate += object.Rate
        if object.Name == "SolarStarGlow" then stars += 1 end
    end
end
assert(beams == 48 and stars == 4 and rate == 44)
Effects.Apply(character, { Id = "legendary", Odds = 5000, Color = "gold" })
assert(#root.children == 30)
Effects.Apply(character, { Id = "common", Odds = 2, Color = "white" })
assert(#root.children == 10)
for _, object in ipairs(character:GetDescendants()) do assert(object.ClassName ~= "Beam") end
Effects.Apply(character, { Id = "uncommon", Odds = 5, Color = "green" })
assert(#root.children == 77)
local ribbons, motes = 0, 0
for _, object in ipairs(character:GetDescendants()) do
    if object.ClassName == "Beam" then
        assert(object.Name == "NaturalRibbon" and object.Width0 <= 0.045)
        ribbons += 1
    elseif object.ClassName == "ParticleEmitter" then
        assert(object.Name == "NaturalParticles" and object.Rate == 8)
        motes += 1
    end
end
assert(ribbons == 72 and motes == 1)
Effects.Apply(character, { Id = "rare", Odds = 50, Color = "blue" })
assert(#root.children == 58)
Effects.Apply(character, { Id = "divine", Odds = 50000, Color = "violet" })
assert(#root.children == 78)
local divineBeams, divineParticles, goldenStar = 0, 0, false
for _, object in ipairs(character:GetDescendants()) do
    if object.ClassName == "Beam" then
        divineBeams += 1
        assert(object.Name == "DivineLight")
    elseif object.ClassName == "ParticleEmitter" then
        divineParticles += 1
        if object.Name == "DivineGoldenStar" then goldenStar = true end
    end
end
assert(divineBeams == 76 and divineParticles == 3 and goldenStar)
Effects.Apply(character, { Id = "divine", Odds = 50000, Color = "violet" })
assert(#root.children == 78)
Effects.Apply(character, { Id = "rare", Odds = 50, Color = "blue" })
assert(#root.children == 58)
local triangles, lights, emitters = 0, 0, 0
for _, object in ipairs(character:GetDescendants()) do
    if object.ClassName == "Beam" then
        lights += 1
        if object.Name == "RareTriangle" then
            triangles += 1
            assert(object.Width1 == 0)
        end
    elseif object.ClassName == "ParticleEmitter" then emitters += 1 end
end
assert(triangles == 10 and lights == 82 and emitters == 2)
Effects.Apply(character, { Id = "rare", Odds = 50, Color = "blue" })
assert(#root.children == 58)
Effects.Apply(character, { Id = "uncommon", Odds = 5, Color = "green" })
assert(#root.children == 77)
Effects.Apply(character, { Id = "legendary", Odds = 5000, Color = "gold" })
assert(#root.children == 30)
for _, object in ipairs(character:GetDescendants()) do assert(object.Name ~= "NaturalRibbon") end
Effects.Apply(character, nil)
assert(#root.children == 1 and root.children[1] == unrelated)
Effects.Apply({ FindFirstChild = function() end, GetDescendants = function() return {} end }, { Odds = 2, Color = "white" })
print("Effects: Solar, Natural, Raro, Divino, criação, troca, limpeza e ausência de root passaram (simulados)")
