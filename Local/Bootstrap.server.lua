--!nocheck
--[[
	Bootstrap.server.lua  --  Super Nostalgia Zone (fork standalone)

	El repositorio original arranca desde `core.lua`, que se publica como
	MainModule (asset 1011800466) y solo funciona dentro del universo
	original (comprueba `game.GameId ~= 123949867`).

	Este script reemplaza esa fase de arranque para que el lugar funcione
	de forma independiente en tu propia cuenta: aplica exactamente los
	mismos ajustes de entorno que hacia `core.lua`, mas los ajustes que
	el motor moderno necesita (TextChatService, distancias de nombre/vida).

	Basado en core.lua de MaximumADHD/Super-Nostalgia-Zone (MPL-2.0).
]]

local Chat = game:GetService("Chat")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local TextChatService = game:GetService("TextChatService")

local function trySet(inst, prop, value)
	local ok, err = pcall(function ()
		inst[prop] = value
	end)

	if not ok then
		warn(("[Bootstrap] No se pudo asignar %s.%s: %s"):format(inst:GetFullName(), prop, tostring(err)))
	end

	return ok
end

--------------------------------------------------------------------------------
-- 1. Comprobacion critica: el juego asume FilteringEnabled.
--------------------------------------------------------------------------------

if not workspace.FilteringEnabled then
	local msg = Instance.new("Message")
	msg.Text = "FATAL: Workspace.FilteringEnabled DEBE estar en true!!!"
	msg.Parent = workspace
	return
end

--------------------------------------------------------------------------------
-- 2. Desactivar los scripts de jugador por defecto de Roblox.
--    Super Nostalgia Zone trae su propia camara, control y mouse clasicos;
--    si los scripts modernos se cargan, pelean con ellos.
--------------------------------------------------------------------------------

task.spawn(function ()
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local loader = scripts:WaitForChild("PlayerScriptsLoader", 30)

	if loader then
		loader.Disabled = true
	else
		warn("[Bootstrap] No aparecio PlayerScriptsLoader; los scripts modernos podrian seguir activos.")
	end
end)

--------------------------------------------------------------------------------
-- 3. Ajustes forzados de StarterPlayer (identicos a core.lua).
--------------------------------------------------------------------------------

local devProps =
{
	DevComputerMovementMode       = "KeyboardMouse";
	DevComputerCameraMovementMode = "Classic";
	DevTouchMovementMode          = "UserChoice";
	DevTouchCameraMovementMode    = "Classic";

	LoadCharacterAppearance       = false;
	EnableMouseLockOption         = false;

	-- El juego dibuja sus propias barras de vida/nombre (Client/HumanoidLabels).
	HealthDisplayDistance         = 0;
	NameDisplayDistance           = 0;
}

for prop, value in pairs(devProps) do
	trySet(StarterPlayer, prop, value)
end

Players.CharacterAutoLoads = false
trySet(StarterGui, "ShowDevelopmentGui", false)

--------------------------------------------------------------------------------
-- 4. Chat: usamos TextChatService (el codigo del repo ya esta migrado),
--    pero ocultamos toda la interfaz moderna porque UI/Chat dibuja la suya.
--------------------------------------------------------------------------------

trySet(Chat, "LoadDefaultChat", false)

task.spawn(function ()
	local configs =
	{
		"ChatWindowConfiguration",
		"ChatInputBarConfiguration",
		"BubbleChatConfiguration",
		"ChannelTabsConfiguration",
	}

	for _, name in ipairs(configs) do
		local config = TextChatService:FindFirstChildOfClass(name)

		if config then
			trySet(config, "Enabled", false)
		end
	end
end)

--------------------------------------------------------------------------------
-- 5. Iluminacion clasica.
--------------------------------------------------------------------------------

trySet(Lighting, "Outlines", false)
trySet(Lighting, "GlobalShadows", false)

local sky = Lighting:FindFirstChildOfClass("Sky")

if not sky then
	sky = Instance.new("Sky")

	for _, face in ipairs({"Bk", "Dn", "Ft", "Lf", "Rt", "Up"}) do
		sky["Skybox" .. face] = ("rbxasset://Sky/null_plainsky512_%s.jpg"):format(face:lower())
	end

	sky.Parent = Lighting
end

sky.SunAngularSize = 14
sky.MoonAngularSize = 6

--------------------------------------------------------------------------------
-- 6. Limpiar personajes que hayan aparecido antes del arranque.
--------------------------------------------------------------------------------

for _, player in ipairs(Players:GetPlayers()) do
	local char = player.Character

	if char and char:IsDescendantOf(workspace) then
		char:Destroy()
		player.Character = nil
	end
end

print("[Bootstrap] Super Nostalgia Zone (fork local) listo.")
