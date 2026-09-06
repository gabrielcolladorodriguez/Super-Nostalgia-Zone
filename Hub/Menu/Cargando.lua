--!nocheck
--[[
	Cargando -- la pantalla que se ve mientras Roblox te lleva a otro lugar.

	Un teletransporte de Roblox tarda lo que tarda y no hay forma de acelerarlo.
	Lo que si se puede evitar es que parezca que el juego se ha colgado: por
	defecto la pantalla se queda congelada en el ultimo fotograma varios
	segundos, sin una sola senal de que algo esta pasando.

	`TeleportService:SetTeleportGui` cambia eso. Se registra ANTES de pedir el
	salto, y esta interfaz viaja con el jugador y se muestra durante toda la
	espera. El texto y los puntos que avanzan no aceleran nada, pero convierten
	"se ha bloqueado" en "esta cargando", que es la mitad del problema.
]]

local TeleportService = game:GetService("TeleportService")

local Cargando = {}

local FUENTE = Enum.Font.Cartoon

local function new(clase, props, padre)
	local i = Instance.new(clase)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = padre
	return i
end

--- Construye la pantalla y la registra. Devuelve una funcion para escribir
--- en ella antes de saltar.
function Cargando.Preparar()
	local gui = new("ScreenGui", {
		Name = "BygoneCargando", IgnoreGuiInset = true, ResetOnSpawn = false,
		DisplayOrder = 100000,
	}, nil)

	new("Frame", {
		Name = "Fondo", BackgroundColor3 = Color3.fromRGB(24, 26, 30),
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
	}, gui)

	local titulo = new("TextLabel", {
		Name = "Titulo", BackgroundTransparency = 1, Font = FUENTE, TextSize = 42,
		TextColor3 = Color3.fromRGB(238, 238, 238), Text = "BYGONE",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(600, 54),
	}, gui)

	local destino = new("TextLabel", {
		Name = "Destino", BackgroundTransparency = 1, Font = FUENTE, TextSize = 22,
		TextColor3 = Color3.fromRGB(150, 158, 170), Text = "Loading",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(600, 30),
	}, gui)

	-- Barra a rayas que se mueve: no mide el progreso real, porque Roblox no lo
	-- cuenta, pero deja claro que la cosa sigue viva.
	local carril = new("Frame", {
		Name = "Carril", BackgroundColor3 = Color3.fromRGB(48, 52, 58),
		BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(360, 8),
	}, gui)

	local pastilla = new("Frame", {
		Name = "Pastilla", BackgroundColor3 = Color3.fromRGB(120, 170, 230),
		BorderSizePixel = 0, Size = UDim2.new(0.28, 0, 1, 0),
	}, carril)

	new("TextLabel", {
		BackgroundTransparency = 1, Font = FUENTE, TextSize = 14,
		TextColor3 = Color3.fromRGB(110, 116, 126),
		Text = "the classic ROBLOX places, as they were",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(600, 20),
	}, gui)

	task.spawn(function ()
		local t = 0
		while gui.Parent ~= nil or true do
			t += 0.03
			pastilla.Position = UDim2.fromScale(
				(math.sin(t) * 0.5 + 0.5) * 0.72, 0)
			task.wait(0.03)
		end
	end)

	pcall(function ()
		TeleportService:SetTeleportGui(gui)
	end)

	return function (texto)
		destino.Text = texto or "Loading"
	end
end

return Cargando
