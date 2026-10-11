-- ModuleScript chamado RNGConfig, dentro de ServerScriptService.
local Config = {}
Config.Cooldown = 1.5
Config.FastCooldown = 0.6 -- Modo rápido disponível para todos.
Config.AutosaveSeconds = 60
Config.Items = {
	{ Id = "common", Name = "Comum", Odds = 2, Color = Color3.fromRGB(220, 220, 220) },
	{ Id = "uncommon", Name = "Incomum", Odds = 5, Color = Color3.fromRGB(90, 230, 130) },
	{ Id = "rare", Name = "Raro", Odds = 50, Color = Color3.fromRGB(90, 160, 255) },
	{ Id = "epic", Name = "Épico", Odds = 500, Color = Color3.fromRGB(190, 100, 255) },
	{
		Id = "legendary",
		Name = "Lendário",
		Odds = 5000,
		Color = Color3.fromRGB(255, 200, 50),
		Announce = true,
	},
	{
		Id = "divine",
		Name = "Divino",
		Odds = 50000,
		Color = Color3.fromRGB(255, 120, 220),
		Announce = true,
	},
	{
		Id = "secret",
		Name = "Segredo",
		Odds = 1000000,
		Color = Color3.fromRGB(255, 75, 110),
		Announce = true,
		Secret = true,
	},
}
return Config
