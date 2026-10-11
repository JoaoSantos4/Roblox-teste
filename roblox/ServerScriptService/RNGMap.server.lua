-- Script RNGMap em ServerScriptService. Constrói o cenário ao iniciar Play.
-- Não exige modelos, texturas externas ou alterações nos scripts do RNG.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Settings = {
	MapName = "RNGTropicalMap",
	ClockTime = 16,
	OceanSize = 1400,
	PalmCount = 16,
	Seed = 2401,
	ReturnFromOcean = true,
}
if Workspace:FindFirstChild(Settings.MapName) then
	warn("RNGMap: cenário já existe; não será criado novamente.")
	return
end
local map = Instance.new("Folder")
map.Name = Settings.MapName
map:SetAttribute("RNGGeneratedMap", true)
map.Parent = Workspace
local random = Random.new(Settings.Seed)
local colors = {
	sand = Color3.fromRGB(236, 211, 149),
	grass = Color3.fromRGB(83, 158, 89),
	water = Color3.fromRGB(49, 169, 190),
	wood = Color3.fromRGB(139, 100, 62),
	stone = Color3.fromRGB(166, 160, 139),
	leaves = Color3.fromRGB(52, 132, 73),
	gold = Color3.fromRGB(255, 207, 83),
	violet = Color3.fromRGB(184, 115, 255),
}
local function area(name)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = map
	return model
end
local function part(parent, name, size, frame, color, material, collide)
	local value = Instance.new("Part")
	value.Name = name
	value.Size = size
	value.CFrame = frame
	value.Color = color
	value.Material = material or Enum.Material.SmoothPlastic
	value.Anchored = true
	value.CanCollide = collide ~= false
	value.CanTouch = false
	value.CanQuery = value.CanCollide
	value.TopSurface = Enum.SurfaceType.Smooth
	value.BottomSurface = Enum.SurfaceType.Smooth
	value.Parent = parent
	return value
end
local function disc(parent, name, center, radius, height, color, material)
	local value = part(
		parent,
		name,
		Vector3.new(height, radius * 2, radius * 2),
		CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material
	)
	value.Shape = Enum.PartType.Cylinder
	return value
end
local function island(parent, center, radius)
	disc(
		parent,
		"Ilha de areia",
		Vector3.new(center.X, 6, center.Z),
		radius,
		12,
		colors.sand,
		Enum.Material.Sand
	)
	disc(
		parent,
		"Vegetação",
		Vector3.new(center.X, 12.35, center.Z),
		radius * 0.81,
		0.7,
		colors.grass,
		Enum.Material.Grass
	)
end
local function sign(parent, title, subtitle, position, color)
	local board = part(
		parent,
		"Placa " .. title,
		Vector3.new(34, 8, 0.7),
		CFrame.lookAt(position, Vector3.new(0, position.Y, 0)),
		colors.wood,
		Enum.Material.Wood,
		false
	)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "MapSign"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.Parent = board
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = title .. "\n" .. subtitle
	text.TextColor3 = color or Color3.new(1, 1, 1)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextWrapped = true
	text.Parent = gui
	local post = position - Vector3.new(0, 6, 0)
	part(
		parent,
		"Suporte da placa",
		Vector3.new(1, 12, 1),
		CFrame.new(post),
		colors.wood,
		Enum.Material.Wood
	)
end
local function palm(parent, x, z, height)
	local model = Instance.new("Model")
	model.Name = "Coqueiro"
	model.Parent = parent
	local trunk = part(
		model,
		"Tronco",
		Vector3.new(height, 2.5, 2.5),
		CFrame.new(x, 13 + height / 2, z) * CFrame.Angles(0, 0, math.pi / 2),
		colors.wood,
		Enum.Material.Wood
	)
	trunk.Shape = Enum.PartType.Cylinder
	local crown = Vector3.new(x, 13 + height, z)
	for index = 1, 6 do
		local angle = index * math.pi / 3
		local frame = CFrame.new(crown)
			* CFrame.Angles(0, angle, 0)
			* CFrame.new(0, -0.8, -5)
		part(
			model,
			"Folha",
			Vector3.new(3, 0.5, 12),
			frame * CFrame.Angles(math.rad(-12), 0, 0),
			colors.leaves,
			Enum.Material.Grass,
			false
		)
	end
	for index = 1, 3 do
		local coconut = part(
			model,
			"Coco",
			Vector3.new(1.4, 1.4, 1.4),
			CFrame.new(crown + Vector3.new(index - 2, -1.7, 0)),
			colors.wood,
			Enum.Material.Wood,
			false
		)
		coconut.Shape = Enum.PartType.Ball
	end
end
local function bridge(parent, startPoint, endPoint)
	local distance = (endPoint - startPoint).Magnitude
	local midpoint = (startPoint + endPoint) / 2
	local frame = CFrame.lookAt(midpoint, endPoint)
	part(
		parent,
		"Ponte",
		Vector3.new(12, 1, distance + 2),
		frame,
		colors.wood,
		Enum.Material.WoodPlanks
	)
	for _, side in ipairs({ -1, 1 }) do
		part(
			parent,
			"Corrimão",
			Vector3.new(0.6, 0.6, distance),
			frame * CFrame.new(side * 5.7, 3, 0),
			colors.wood,
			Enum.Material.Wood
		)
		for step = 0, math.floor(distance / 12) do
			part(
				parent,
				"Poste",
				Vector3.new(0.7, 3.5, 0.7),
				frame * CFrame.new(side * 5.7, 1.75, -distance / 2 + step * 12),
				colors.wood,
				Enum.Material.Wood
			)
		end
	end
end
local ocean = part(
	map,
	"Oceano decorativo",
	Vector3.new(Settings.OceanSize, 2, Settings.OceanSize),
	CFrame.new(0, 1, 0),
	colors.water,
	Enum.Material.SmoothPlastic,
	false
)
ocean.Transparency = 0.12
ocean.Reflectance = 0.12
ocean.CanTouch = Settings.ReturnFromOcean
local lobby = area("Lobby Tropical")
island(lobby, Vector3.new(0, 0, 0), 130)
part(
	lobby,
	"Praça",
	Vector3.new(62, 1, 62),
	CFrame.new(0, 13.2, 0),
	colors.stone,
	Enum.Material.Cobblestone
)
for _, direction in ipairs({ 0, math.pi / 2, math.pi, math.pi * 1.5 }) do
	part(
		lobby,
		"Caminho",
		Vector3.new(14, 0.4, 110),
		CFrame.new(0, 13.5, 0) * CFrame.Angles(0, direction, 0) * CFrame.new(0, 0, -58),
		colors.sand,
		Enum.Material.Sand
	)
end
sign(
	lobby,
	"RNG • ILHAS DA SORTE",
	"Role, descubra auras e explore!",
	Vector3.new(0, 23, -32),
	colors.gold
)
for index = 1, Settings.PalmCount do
	local angle = index * math.pi * 2 / Settings.PalmCount
	local radius = random:NextNumber(85, 114)
	palm(
		lobby,
		math.cos(angle) * radius,
		math.sin(angle) * radius,
		random:NextNumber(15, 23)
	)
end
-- Um píer, guarda-sóis e bancos na praia do lobby.
part(
	lobby,
	"Píer",
	Vector3.new(16, 1, 42),
	CFrame.new(0, 13.5, 127),
	colors.wood,
	Enum.Material.WoodPlanks
)
for _, x in ipairs({ -52, 52 }) do
	part(
		lobby,
		"Banco",
		Vector3.new(14, 1, 4),
		CFrame.new(x, 15, 35),
		colors.wood,
		Enum.Material.Wood
	)
	part(
		lobby,
		"Encosto",
		Vector3.new(14, 4, 0.7),
		CFrame.new(x, 17, 37),
		colors.wood,
		Enum.Material.Wood
	)
	for _, leg in ipairs({ -5, 5 }) do
		part(
			lobby,
			"Pé do banco",
			Vector3.new(1, 2, 3),
			CFrame.new(x + leg, 13.7, 35),
			colors.wood,
			Enum.Material.Wood
		)
	end
	local pole = Vector3.new(x, 18, 65)
	part(
		lobby,
		"Haste do guarda-sol",
		Vector3.new(0.5, 11, 0.5),
		CFrame.new(pole),
		colors.wood,
		Enum.Material.Wood
	)
	disc(
		lobby,
		"Guarda-sol",
		pole + Vector3.new(0, 5.5, 0),
		9,
		0.6,
		x < 0 and colors.gold or colors.violet,
		Enum.Material.SmoothPlastic
	).CanCollide =
		false
end
local forest = area("Bosque Natural")
local forestCenter = Vector3.new(190, 0, 20)
island(forest, forestCenter, 62)
bridge(forest, Vector3.new(109, 13.5, 12), Vector3.new(190, 13.5, 20))
for index = 1, 9 do
	local angle = index * math.pi * 2 / 9
	palm(
		forest,
		190 + math.cos(angle) * 42,
		20 + math.sin(angle) * 42,
		random:NextNumber(20, 28)
	)
end
sign(
	forest,
	"BOSQUE NATURAL",
	"Um refúgio entre os coqueiros",
	Vector3.new(190, 22, -15),
	Color3.fromRGB(130, 255, 150)
)
local solar = area("Mirante Solar")
local solarCenter = Vector3.new(-185, 0, -25)
island(solar, solarCenter, 62)
bridge(solar, Vector3.new(-109, 13.5, -12), Vector3.new(-185, 13.5, -25))
-- Escadaria com degraus baixos até o mirante.
for index = 1, 12 do
	part(
		solar,
		"Degrau do mirante",
		Vector3.new(20, index, 3),
		CFrame.new(-185, 12.7 + index / 2, -25 - index * 3),
		colors.stone,
		Enum.Material.Slate
	)
end
part(
	solar,
	"Mirante",
	Vector3.new(34, 1, 22),
	CFrame.new(-185, 25.2, -70),
	colors.stone,
	Enum.Material.Slate
)
for _, x in ipairs({ -200, -170 }) do
	part(
		solar,
		"Coluna solar",
		Vector3.new(3, 17, 3),
		CFrame.new(x, 33.2, -77),
		colors.stone,
		Enum.Material.Marble
	)
	disc(
		solar,
		"Luz solar",
		Vector3.new(x, 42, -77),
		2,
		1,
		colors.gold,
		Enum.Material.Neon
	).CanCollide =
		false
end
part(
	solar,
	"Arco solar",
	Vector3.new(35, 3, 4),
	CFrame.new(-185, 42, -77),
	colors.gold,
	Enum.Material.Neon,
	false
)
sign(
	solar,
	"MIRANTE SOLAR",
	"Suba para admirar o horizonte",
	Vector3.new(-156, 22, -33),
	colors.gold
)
local temple = area("Templo Astral")
island(temple, Vector3.new(0, 0, -210), 70)
bridge(temple, Vector3.new(0, 13.5, -108), Vector3.new(0, 13.5, -210))
part(
	temple,
	"Pátio astral",
	Vector3.new(58, 1, 52),
	CFrame.new(0, 13.2, -210),
	Color3.fromRGB(114, 105, 145),
	Enum.Material.Slate
)
for _, x in ipairs({ -23, 23 }) do
	for _, z in ipairs({ -230, -196 }) do
		part(
			temple,
			"Coluna astral",
			Vector3.new(4, 22, 4),
			CFrame.new(x, 24.7, z),
			colors.stone,
			Enum.Material.Marble
		)
		part(
			temple,
			"Topo luminoso",
			Vector3.new(5, 1, 5),
			CFrame.new(x, 36.2, z),
			colors.violet,
			Enum.Material.Neon,
			false
		)
	end
end
part(
	temple,
	"Viga astral",
	Vector3.new(52, 3, 5),
	CFrame.new(0, 37, -230),
	colors.stone,
	Enum.Material.Marble
)
local crystal = part(
	temple,
	"Cristal astral",
	Vector3.new(6, 11, 6),
	CFrame.new(0, 22, -221) * CFrame.Angles(0, math.rad(45), math.rad(12)),
	colors.violet,
	Enum.Material.Neon,
	false
)
local glow = Instance.new("PointLight")
glow.Color = colors.violet
glow.Brightness = 1.2
glow.Range = 24
glow.Parent = crystal
sign(
	temple,
	"TEMPLO ASTRAL",
	"O silêncio guarda seus segredos",
	Vector3.new(30, 22, -177),
	colors.violet
)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "RNGSpawn"
spawn.Size = Vector3.new(10, 0.6, 10)
spawn.CFrame = CFrame.new(0, 14, 10)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Material = Enum.Material.Neon
spawn.Color = colors.gold
spawn.Parent = lobby
-- O cenário padrão fica oculto durante Play, sem apagar objetos do seu projeto.
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Transparency = 1
	baseplate.CanCollide = false
end
local oldSpawn = Workspace:FindFirstChild("SpawnLocation")
if oldSpawn and oldSpawn:IsA("SpawnLocation") then
	oldSpawn.Enabled = false
end
local function useSpawn(player)
	player.RespawnLocation = spawn
	if player.Character then
		player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
	end
end
Players.PlayerAdded:Connect(useSpawn)
for _, player in ipairs(Players:GetPlayers()) do
	useSpawn(player)
end
local lastReturn = {}
if Settings.ReturnFromOcean then
	ocean.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or os.clock() < (lastReturn[player] or 0) then
			return
		end
		lastReturn[player] = os.clock() + 2
		character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
	end)
end
Players.PlayerRemoving:Connect(function(player)
	lastReturn[player] = nil
end)
Lighting.ClockTime = Settings.ClockTime
Lighting.Brightness = 2
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(112, 116, 139)
Lighting.OutdoorAmbient = Color3.fromRGB(151, 153, 164)
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	or Instance.new("Atmosphere")
atmosphere.Name = "RNGAtmosphere"
atmosphere.Density = 0.23
atmosphere.Offset = 0.12
atmosphere.Color = Color3.fromRGB(206, 228, 255)
atmosphere.Decay = Color3.fromRGB(239, 204, 151)
atmosphere.Haze = 1
atmosphere.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Name = "RNGBloom"
bloom.Intensity = 0.18
bloom.Size = 24
bloom.Threshold = 1.5
bloom.Parent = Lighting
print("RNGMap: lobby, Bosque Natural, Mirante Solar e Templo Astral prontos.")
