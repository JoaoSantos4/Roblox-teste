-- ModuleScript RNGAuraEffect em ServerScriptService.
-- Partículas replicadas pelo servidor, sem loops, peças físicas ou sons novos.
local Effects = {}
local TAG = "RNGAuraEffect"
local TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

function Effects.Clear(character)
    for _, object in ipairs(character:GetDescendants()) do
        if object:GetAttribute(TAG) == true then object:Destroy() end
    end
end

function Effects.Apply(character, item)
    Effects.Clear(character)
    if not item then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local function point(name, position)
        local value = Instance.new("Attachment")
        value.Name = name
        value.Position = position
        value:SetAttribute(TAG, true)
        value.Parent = root
        return value
    end

    -- DIVINO: órbitas violetas/douradas e energia no torso.
    if item.Id == "divine" then
        local violet = Color3.fromRGB(190, 100, 255)
        local pink = Color3.fromRGB(245, 175, 255)
        local gold = Color3.fromRGB(255, 225, 135)
        local function ribbon(a, b, width, transparency, color)
            local value = Instance.new("Beam")
            value.Name = "DivineLight"
            value.Attachment0, value.Attachment1 = a, b
            value.Width0, value.Width1 = width, width
            value.Color = ColorSequence.new(color)
            value.Transparency = NumberSequence.new(transparency)
            value.LightEmission = 1
            value.LightInfluence = 0
            value.FaceCamera = true
            value.Segments = 1
            value.Parent = a
        end
        local orbits = {
            { Radius = 2.65, Tilt = 0.2, Yaw = 0, Color = pink },
            { Radius = 2.9, Tilt = 0.85, Yaw = 1.2, Color = violet },
            { Radius = 2.8, Tilt = -0.55, Yaw = 2.4, Color = gold },
        }
        for orbitIndex, orbit in ipairs(orbits) do
            local points = {}
            for index = 1, 24 do
                local angle = (index - 1) * math.pi * 2 / 24
                local u, v = math.cos(angle) * orbit.Radius, math.sin(angle) * orbit.Radius
                local depth = v * math.sin(orbit.Tilt)
                points[index] = point("DivineOrbit" .. orbitIndex .. "_" .. index, Vector3.new(
                    u * math.cos(orbit.Yaw) + depth * math.sin(orbit.Yaw),
                    v * math.cos(orbit.Tilt) + 0.2,
                    -u * math.sin(orbit.Yaw) + depth * math.cos(orbit.Yaw)
                ))
            end
            for index = 1, #points do
                ribbon(points[index], points[index % #points + 1],
                    orbitIndex == 3 and 0.045 or 0.065, 0.25, orbit.Color)
            end
        end

        local corners = {
            point("DivineFrame1", Vector3.new(-1.15, 1.05, -0.85)),
            point("DivineFrame2", Vector3.new(1.15, 1.05, -0.85)),
            point("DivineFrame3", Vector3.new(1.15, -1.05, -0.85)),
            point("DivineFrame4", Vector3.new(-1.15, -1.05, -0.85)),
        }
        for index = 1, #corners do
            ribbon(corners[index], corners[index % #corners + 1], 0.04, 0.35, pink)
        end

        local center = point("DivineCore", Vector3.new(0, 0.2, -0.85))
        local star = Instance.new("ParticleEmitter")
        star.Name = "DivineGoldenStar"
        star.Texture = TEXTURE
        star.Color = ColorSequence.new(gold)
        star.Rate = 3
        star.Lifetime = NumberRange.new(0.65, 0.9)
        star.Speed = NumberRange.new(0)
        star.LockedToPart = true
        star.LightEmission = 1
        star.LightInfluence = 0
        star.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.35, 1.2),
            NumberSequenceKeypoint.new(1, 0),
        })
        star.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.05),
            NumberSequenceKeypoint.new(1, 1),
        })
        star.Parent = center

        local mist = Instance.new("ParticleEmitter")
        mist.Name = "DivineMist"
        mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
        mist.Color = ColorSequence.new(violet)
        mist.Rate = 6
        mist.Lifetime = NumberRange.new(1, 1.5)
        mist.Speed = NumberRange.new(0.2, 0.5)
        mist.SpreadAngle = Vector2.new(180, 180)
        mist.LockedToPart = true
        mist.LightEmission = 0.8
        mist.LightInfluence = 0
        mist.RotSpeed = NumberRange.new(-15, 15)
        mist.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2.5),
            NumberSequenceKeypoint.new(1, 4.5),
        })
        mist.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.93),
            NumberSequenceKeypoint.new(1, 1),
        })
        mist.Parent = center

        local motes = Instance.new("ParticleEmitter")
        motes.Name = "DivineStars"
        motes.Texture = TEXTURE
        motes.Color = ColorSequence.new(pink)
        motes.Rate = 10
        motes.Lifetime = NumberRange.new(1, 1.8)
        motes.Speed = NumberRange.new(0.7, 1.8)
        motes.SpreadAngle = Vector2.new(180, 180)
        motes.LockedToPart = true
        motes.LightEmission = 1
        motes.LightInfluence = 0
        motes.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 0),
        })
        motes.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        motes.Parent = center
        local light = Instance.new("PointLight")
        light.Color = violet
        light.Brightness = 1.5
        light.Range = 10
        light.Shadows = false
        light.Parent = center
        return
    end

    -- RARO: energia azul, halo e triângulos luminosos.
    if item.Id == "rare" then
        local cyan = Color3.fromRGB(65, 215, 255)
        local pale = Color3.fromRGB(170, 250, 255)
        local humanoid = character:FindFirstChild("Humanoid")
        local floorY = -3
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            floorY = -(humanoid.HipHeight + root.Size.Y / 2)
        end
        floorY += 0.1
        local head = character:FindFirstChild("Head")
        local haloY = 3.2
        if head then haloY = root.CFrame:PointToObjectSpace(head.Position).Y + head.Size.Y / 2 + 0.65 end

        local function ribbon(a, b, width, transparency, color)
            local value = Instance.new("Beam")
            value.Name = "RareLight"
            value.Attachment0 = a
            value.Attachment1 = b
            value.Width0, value.Width1 = width, width
            value.Color = ColorSequence.new(color)
            value.Transparency = NumberSequence.new(transparency)
            value.LightEmission = 1
            value.LightInfluence = 0
            value.FaceCamera = true
            value.Segments = 1
            value.Parent = a
            return value
        end

        local function ring(name, radius, y, segments, width)
            local points = {}
            for index = 1, segments do
                local angle = (index - 1) * math.pi * 2 / segments
                points[index] = point(name .. index, Vector3.new(
                    math.cos(angle) * radius, y, math.sin(angle) * radius))
            end
            for index = 1, segments do
                local nextPoint = points[index % segments + 1]
                ribbon(points[index], nextPoint, width, 0.2, cyan)
                ribbon(points[index], nextPoint, width * 3, 0.85, pale)
            end
        end
        ring("RareFloor", 2.05, floorY, 20, 0.12)
        ring("RareHalo", 0.9, haloY, 16, 0.055)

        -- Beams afunilados criam triângulos sem exigir textura externa.
        for index = 1, 10 do
            local angle = index * math.pi * 2 / 10
            local radius = index % 2 == 0 and 2 or 2.55
            local x, z = math.cos(angle) * radius, math.sin(angle) * radius
            local y = -1.8 + ((index * 3) % 7) * 0.65
            local base = point("RareTriangleBase" .. index, Vector3.new(x, y, z))
            local top = point("RareTriangleTip" .. index, Vector3.new(x + 0.08, y + 0.26, z))
            local triangle = ribbon(base, top, 0.24, 0.1, pale)
            triangle.Name = "RareTriangle"
            triangle.Width1 = 0
        end

        local center = point("RareEnergy", Vector3.new(0, -0.4, 0))
        local mist = Instance.new("ParticleEmitter")
        mist.Name = "RareMist"
        mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
        mist.Color = ColorSequence.new(cyan)
        mist.Rate = 5
        mist.Lifetime = NumberRange.new(0.9, 1.4)
        mist.Speed = NumberRange.new(0.1, 0.4)
        mist.SpreadAngle = Vector2.new(180, 180)
        mist.LockedToPart = true
        mist.LightEmission = 0.8
        mist.LightInfluence = 0
        mist.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 2.8),
            NumberSequenceKeypoint.new(1, 5),
        })
        mist.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.94),
            NumberSequenceKeypoint.new(1, 1),
        })
        mist.Parent = center

        local sparks = Instance.new("ParticleEmitter")
        sparks.Name = "RareMotes"
        sparks.Texture = TEXTURE
        sparks.Color = ColorSequence.new(pale)
        sparks.Rate = 10
        sparks.Lifetime = NumberRange.new(0.8, 1.5)
        sparks.Speed = NumberRange.new(0.8, 2)
        sparks.SpreadAngle = Vector2.new(180, 180)
        sparks.LockedToPart = true
        sparks.LightEmission = 1
        sparks.LightInfluence = 0
        sparks.Size = NumberSequence.new(0.08)
        sparks.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        sparks.Parent = center

        local light = Instance.new("PointLight")
        light.Color = cyan
        light.Brightness = 1.2
        light.Range = 9
        light.Shadows = false
        light.Parent = center
        return
    end

    -- INCOMUM: arcos verdes inclinados, estilo Natural.
    if item.Id == "uncommon" then
        local green = Color3.fromRGB(145, 240, 145)
        local darkGreen = Color3.fromRGB(40, 135, 95)
        local arcs = {
            { Radius = 2.2, Tilt = 0.2, Yaw = 0, Phase = 0 },
            { Radius = 2.6, Tilt = 0.65, Yaw = 1.1, Phase = 1.7 },
            { Radius = 2.9, Tilt = -0.5, Yaw = 2.2, Phase = 3.1 },
        }
        for arcIndex, arc in ipairs(arcs) do
            local previous
            local segments = 24
            for index = 0, segments do
                local t = index / segments
                local angle = arc.Phase + t * math.pi * 1.65
                local u = math.cos(angle) * arc.Radius
                local v = math.sin(angle) * arc.Radius * 1.1
                local depth = v * math.sin(arc.Tilt)
                local current = point("NaturalArc" .. arcIndex .. "_" .. index, Vector3.new(
                    u * math.cos(arc.Yaw) + depth * math.sin(arc.Yaw),
                    v * math.cos(arc.Tilt) + 0.15,
                    -u * math.sin(arc.Yaw) + depth * math.cos(arc.Yaw)
                ))
                if previous then
                    local beam = Instance.new("Beam")
                    beam.Name = "NaturalRibbon"
                    beam.Attachment0 = previous
                    beam.Attachment1 = current
                    beam.Width0 = arcIndex == 1 and 0.045 or 0.025
                    beam.Width1 = beam.Width0
                    beam.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, darkGreen),
                        ColorSequenceKeypoint.new(0.5, green),
                        ColorSequenceKeypoint.new(1, darkGreen),
                    })
                    local fade = 0.88 - math.sin((index - 0.5) / segments * math.pi) * 0.6
                    beam.Transparency = NumberSequence.new(fade)
                    beam.LightEmission = 0.7
                    beam.LightInfluence = 0
                    beam.FaceCamera = true
                    beam.Segments = 1
                    beam.Parent = previous
                end
                previous = current
            end
        end
        local center = point("NaturalMotes", Vector3.new(0, 0, 0))
        local motes = Instance.new("ParticleEmitter")
        motes.Name = "NaturalParticles"
        motes.Texture = TEXTURE
        motes.Color = ColorSequence.new(green)
        motes.Rate = 8
        motes.Lifetime = NumberRange.new(1.2, 2)
        motes.Speed = NumberRange.new(0.3, 1.2)
        motes.SpreadAngle = Vector2.new(180, 180)
        motes.LockedToPart = true
        motes.LightEmission = 0.6
        motes.LightInfluence = 0
        motes.Size = NumberSequence.new(0.07)
        motes.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        motes.Parent = center
        return
    end

    if item.Id == "legendary" then
        local gold = Color3.fromRGB(255, 195, 35)
        local pale = Color3.fromRGB(255, 245, 165)
        local colors = ColorSequence.new({
            ColorSequenceKeypoint.new(0, gold),
            ColorSequenceKeypoint.new(0.5, pale),
            ColorSequenceKeypoint.new(1, gold),
        })
        local humanoid = character:FindFirstChild("Humanoid")
        local floorY = -3
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            floorY = -(humanoid.HipHeight + root.Size.Y / 2)
        end
        floorY += 0.12
        local radius = 2.3

        local function beam(a, b, width, transparency)
            local value = Instance.new("Beam")
            value.Name = "SolarLight"
            value.Attachment0 = a
            value.Attachment1 = b
            value.Color = colors
            value.Width0 = width
            value.Width1 = width
            value.Transparency = NumberSequence.new(transparency)
            value.LightEmission = 1
            value.LightInfluence = 0
            value.FaceCamera = true
            value.Segments = 1
            value.Parent = a
            return value
        end

        -- Anel luminoso fixo, sem peças físicas ou loops por frame.
        local ring = {}
        for index = 1, 20 do
            local angle = (index - 1) * math.pi * 2 / 20
            ring[index] = point("SolarRing" .. index,
                Vector3.new(math.cos(angle) * radius, floorY, math.sin(angle) * radius))
        end
        for index = 1, #ring do
            local nextPoint = ring[index % #ring + 1]
            beam(ring[index], nextPoint, 0.18, 0.05)
            beam(ring[index], nextPoint, 0.5, 0.78)
        end

        -- Quatro pilares dourados, com estrelas brilhantes nas pontas.
        for index = 1, 4 do
            local angle = math.pi / 4 + (index - 1) * math.pi / 2
            local x, z = math.cos(angle) * radius, math.sin(angle) * radius
            local height = index % 2 == 0 and 3.6 or 2.9
            local base = point("SolarBase" .. index, Vector3.new(x, floorY, z))
            local top = point("SolarStar" .. index, Vector3.new(x, floorY + height, z))
            local core = beam(base, top, 0.13, 0.12)
            core.Width1 = 0.035
            beam(base, top, 0.35, 0.82)

            local trail = Instance.new("ParticleEmitter")
            trail.Name = "SolarEmbers"
            trail.Texture = TEXTURE
            trail.Color = colors
            trail.Rate = 8
            trail.Lifetime = NumberRange.new(0.8, 1.1)
            trail.Speed = NumberRange.new(2.5, 3.5)
            trail.SpreadAngle = Vector2.new(8, 8)
            trail.LightEmission = 1
            trail.LightInfluence = 0
            trail.LockedToPart = true
            trail.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.22),
                NumberSequenceKeypoint.new(0.5, 0.16),
                NumberSequenceKeypoint.new(1, 0),
            })
            trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(1, 1),
            })
            trail.Parent = base

            local star = Instance.new("ParticleEmitter")
            star.Name = "SolarStarGlow"
            star.Texture = TEXTURE
            star.Color = ColorSequence.new(pale)
            star.Rate = 3
            star.Speed = NumberRange.new(0)
            star.Lifetime = NumberRange.new(0.6, 0.8)
            star.LockedToPart = true
            star.LightEmission = 1
            star.LightInfluence = 0
            star.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.3, 0.85),
                NumberSequenceKeypoint.new(1, 0),
            })
            star.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.3, 0.1),
                NumberSequenceKeypoint.new(1, 1),
            })
            star.Parent = top
        end
        local center = point("SolarCenter", Vector3.new(0, floorY + 0.5, 0))
        local light = Instance.new("PointLight")
        light.Color = gold
        light.Range = 10
        light.Brightness = 1.8
        light.Shadows = false
        light.Parent = center
        return
    end

    local tier = item.Odds >= 50000 and 4
        or item.Odds >= 5000 and 3
        or item.Odds >= 500 and 2
        or 1
    local color = ColorSequence.new(item.Color)
    local radius = 1.7 + tier * 0.2

    -- Oito pontos formam um círculo de partículas subindo ao redor do corpo.
    for index = 1, 8 do
        local angle = index * math.pi / 4
        local anchor = point("RNGAuraRing" .. index,
            Vector3.new(math.cos(angle) * radius, -2, math.sin(angle) * radius))
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "AuraSparkles"
        particles.Texture = TEXTURE
        particles.Color = color
        particles.Rate = 2 + tier * 2
        particles.Lifetime = NumberRange.new(0.9, 1.5)
        particles.Speed = NumberRange.new(1.5, 2.8)
        particles.SpreadAngle = Vector2.new(15, 15)
        particles.EmissionDirection = Enum.NormalId.Top
        particles.Acceleration = Vector3.new(0, 0.4, 0)
        particles.Rotation = NumberRange.new(0, 360)
        particles.RotSpeed = NumberRange.new(-40, 40)
        particles.LightEmission = 0.8
        particles.LightInfluence = 0
        particles.LockedToPart = true
        particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.4, 0.25 + tier * 0.06),
            NumberSequenceKeypoint.new(1, 0),
        })
        particles.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0.2),
            NumberSequenceKeypoint.new(0.75, 0.35),
            NumberSequenceKeypoint.new(1, 1),
        })
        particles.Parent = anchor
    end

    local center = point("RNGAuraCenter", Vector3.new(0, 0, 0))
    local light = Instance.new("PointLight")
    light.Name = "AuraLight"
    light.Color = item.Color
    light.Brightness = 0.3 + tier * 0.2
    light.Range = 5 + tier
    light.Shadows = false
    light.Parent = center
end

return Effects
