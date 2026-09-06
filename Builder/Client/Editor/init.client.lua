--!nocheck
--[[
	Bygone Studio -- el editor.

	Corre entero en el cliente para que el raton responda al instante; el
	servidor solo interviene al guardar, y no se cree nada de lo que le llega
	(ver BuilderService).

	Como se coloca una pieza: se lanza un rayo desde el raton, se mira que
	superficie toca y la pieza se apoya encima, encajada a la rejilla de studs.
	Es como se construia en 2008 y sigue siendo lo mas predecible: nada de
	arrastrar ejes en el aire.

	Atajos:
	  clic            seleccionar          shift+clic  anadir a la seleccion
	  arrastrar       mover                R / T       girar en Y / en X
	  suprimir        borrar               ctrl+D      duplicar
	  ctrl+Z / ctrl+Y deshacer / rehacer   ctrl+S      guardar
	  G               rejilla on/off       clic dcho   mirar con la camara
	  WASD + Q/E      volar
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Palette = require(script:WaitForChild("Palette"))
local Serializer = require(ReplicatedStorage:WaitForChild("Serializer"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UI = Palette.UI

local canal = ReplicatedStorage:WaitForChild("Constructor")

--------------------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------------------

local obra = workspace:FindFirstChild("Obra") or Instance.new("Folder")
obra.Name = "Obra"
obra.Parent = workspace

local estado = {
	seleccion = {},
	rejilla = 1,             -- studs; 0 = libre
	giro = 45,               -- grados por pulsacion
	forma = 1,               -- indice en Palette.FORMAS
	color = 194,
	material = 0,
	superficieArriba = Enum.SurfaceType.Studs,
	id = nil,                -- id de la creacion abierta
	nombre = "Untitled",
	descripcion = "",
	sucio = false,
}

local historial, futuro = {}, {}
local MAX_HISTORIAL = 40

--------------------------------------------------------------------------------
-- Deshacer
--------------------------------------------------------------------------------
-- Se guarda la obra entera en cada paso. Con el limite de 2.500 partes cuesta
-- poca memoria y evita toda la complejidad de deshacer operacion por operacion,
-- que es donde suelen aparecer los fallos raros.

local function instantanea()
	return Serializer.Serializar(obra)
end

local function restaurar(datos)
	obra:ClearAllChildren()
	estado.seleccion = {}

	local modelo = Serializer.Deserializar(datos, obra)
	for _, parte in ipairs(modelo:GetChildren()) do
		parte.Parent = obra
	end
	modelo:Destroy()
end

local function apuntar()
	table.insert(historial, instantanea())
	if #historial > MAX_HISTORIAL then
		table.remove(historial, 1)
	end
	futuro = {}
	estado.sucio = true
end

--------------------------------------------------------------------------------
-- Seleccion
--------------------------------------------------------------------------------

local cajas = {}

local function pintarSeleccion()
	for parte, caja in pairs(cajas) do
		if not table.find(estado.seleccion, parte) then
			caja:Destroy()
			cajas[parte] = nil
		end
	end

	for _, parte in ipairs(estado.seleccion) do
		if not cajas[parte] and parte.Parent then
			local caja = Instance.new("SelectionBox")
			caja.Adornee = parte
			caja.LineThickness = 0.04
			caja.Color3 = UI.SELECCION
			caja.SurfaceTransparency = 0.85
			caja.Parent = parte
			cajas[parte] = caja
		end
	end
end

local function seleccionar(partes, anadir)
	if not anadir then
		estado.seleccion = {}
	end

	for _, parte in ipairs(partes) do
		if not table.find(estado.seleccion, parte) then
			table.insert(estado.seleccion, parte)
		end
	end

	pintarSeleccion()
end

local function limpiarSeleccion()
	estado.seleccion = {}
	pintarSeleccion()
end

--------------------------------------------------------------------------------
-- Rejilla y colocacion
--------------------------------------------------------------------------------

local function encajar(v)
	if estado.rejilla <= 0 then
		return v
	end
	local g = estado.rejilla
	return Vector3.new(
		math.round(v.X / g) * g,
		math.round(v.Y / g) * g,
		math.round(v.Z / g) * g)
end

local parametros = RaycastParams.new()
parametros.FilterType = Enum.RaycastFilterType.Exclude

local function rayoDelRaton(ignorar)
	local pos = UserInputService:GetMouseLocation()
	local rayo = camera:ViewportPointToRay(pos.X, pos.Y)

	local excluir = { player.Character }
	for _, parte in ipairs(ignorar or {}) do
		table.insert(excluir, parte)
	end
	parametros.FilterDescendantsInstances = excluir

	return workspace:Raycast(rayo.Origin, rayo.Direction * 2000, parametros)
end

--------------------------------------------------------------------------------
-- Crear piezas
--------------------------------------------------------------------------------

local function nuevaParte()
	local forma = Palette.FORMAS[estado.forma]
	local info = Serializer.FORMAS[forma.indice]

	local parte = Instance.new(info.clase)
	parte.Size = forma.tam

	if info.shape and parte:IsA("Part") then
		parte.Shape = info.shape
	end

	parte.BrickColor = BrickColor.new(estado.color)
	parte.Material = Serializer.MATERIALES[estado.material] or Enum.Material.Plastic
	parte.Anchored = true

	if parte:IsA("Part") and forma.indice == 0 then
		parte.TopSurface = estado.superficieArriba
		parte.BottomSurface = Enum.SurfaceType.Inlet
	end

	return parte
end

local function colocar()
	local forma = Palette.FORMAS[estado.forma]
	local golpe = rayoDelRaton()

	local parte = nuevaParte()
	local tam = parte.Size

	local pos
	if golpe then
		local n = golpe.Normal
		pos = encajar(golpe.Position
			+ Vector3.new(n.X * tam.X / 2, n.Y * tam.Y / 2, n.Z * tam.Z / 2))
	else
		local rayo = camera:ViewportPointToRay(
			UserInputService:GetMouseLocation().X,
			UserInputService:GetMouseLocation().Y)
		local p = rayo.Origin + rayo.Direction * 40
		pos = encajar(Vector3.new(p.X, tam.Y / 2, p.Z))
	end

	apuntar()
	parte.Position = pos
	parte.Parent = obra
	seleccionar({ parte }, false)
	return parte
end

--------------------------------------------------------------------------------
-- Operaciones sobre la seleccion
--------------------------------------------------------------------------------

local function contarPartes()
	local n = 0
	for _, d in ipairs(obra:GetDescendants()) do
		if d:IsA("BasePart") then n += 1 end
	end
	return n
end

local function borrarSeleccion()
	if #estado.seleccion == 0 then return end
	apuntar()
	for _, parte in ipairs(estado.seleccion) do
		parte:Destroy()
	end
	limpiarSeleccion()
end

local function duplicarSeleccion()
	if #estado.seleccion == 0 then return end
	if contarPartes() + #estado.seleccion > Serializer.MAX_PARTES then
		return false, "no caben mas partes"
	end

	apuntar()
	local copias = {}
	for _, parte in ipairs(estado.seleccion) do
		local copia = parte:Clone()
		for _, hijo in ipairs(copia:GetChildren()) do
			if hijo:IsA("SelectionBox") then hijo:Destroy() end
		end
		copia.Position = parte.Position + Vector3.new(0, parte.Size.Y, 0)
		copia.Parent = obra
		table.insert(copias, copia)
	end
	seleccionar(copias, false)
	return true
end

local function girarSeleccion(eje)
	if #estado.seleccion == 0 then return end
	apuntar()

	local pivote = estado.seleccion[1].Position
	local giro = CFrame.fromAxisAngle(eje, math.rad(estado.giro))

	for _, parte in ipairs(estado.seleccion) do
		local rel = parte.CFrame.Position - pivote
		parte.CFrame = CFrame.new(pivote + giro:VectorToWorldSpace(rel))
			* (giro * parte.CFrame.Rotation)
	end
end

local function aplicarASeleccion(fn)
	if #estado.seleccion == 0 then return end
	apuntar()
	for _, parte in ipairs(estado.seleccion) do
		pcall(fn, parte)
	end
end

--------------------------------------------------------------------------------
-- Camara libre
--------------------------------------------------------------------------------

local velocidad = 60
local mirando = false
local giroCamara = Vector2.new()

local function moverCamara(dt)
	if not camera then return end

	local mover = Vector3.zero
	local tecla = UserInputService.IsKeyDown

	if tecla(UserInputService, Enum.KeyCode.W) then mover += camera.CFrame.LookVector end
	if tecla(UserInputService, Enum.KeyCode.S) then mover -= camera.CFrame.LookVector end
	if tecla(UserInputService, Enum.KeyCode.A) then mover -= camera.CFrame.RightVector end
	if tecla(UserInputService, Enum.KeyCode.D) then mover += camera.CFrame.RightVector end
	if tecla(UserInputService, Enum.KeyCode.E) then mover += Vector3.yAxis end
	if tecla(UserInputService, Enum.KeyCode.Q) then mover -= Vector3.yAxis end

	local rapido = tecla(UserInputService, Enum.KeyCode.LeftShift) and 3 or 1

	if mover.Magnitude > 0 then
		camera.CFrame = camera.CFrame + mover.Unit * velocidad * rapido * dt
	end
end

--------------------------------------------------------------------------------
-- Arrastrar para mover
--------------------------------------------------------------------------------

local arrastrando = false
local offsets = {}

local function empezarArrastre()
	if #estado.seleccion == 0 then return end

	local golpe = rayoDelRaton(estado.seleccion)
	if not golpe then return end

	arrastrando = true
	offsets = {}
	apuntar()

	local ancla = estado.seleccion[1].Position
	for _, parte in ipairs(estado.seleccion) do
		offsets[parte] = parte.Position - ancla
	end
end

local function seguirArrastre()
	if not arrastrando or #estado.seleccion == 0 then return end

	local principal = estado.seleccion[1]
	local golpe = rayoDelRaton(estado.seleccion)
	if not golpe then return end

	local n = golpe.Normal
	local tam = principal.Size
	local destino = encajar(golpe.Position
		+ Vector3.new(n.X * tam.X / 2, n.Y * tam.Y / 2, n.Z * tam.Z / 2))

	for parte, offset in pairs(offsets) do
		if parte.Parent then
			parte.Position = destino + offset
		end
	end
end

--------------------------------------------------------------------------------
-- La interfaz vive en su propio modulo para no mezclar cosas
--------------------------------------------------------------------------------

local Ui = require(script:WaitForChild("Ui"))

local api = {
	estado = estado,
	obra = obra,
	canal = canal,
	Serializer = Serializer,
	Palette = Palette,

	contarPartes = contarPartes,
	colocar = colocar,
	borrar = borrarSeleccion,
	duplicar = duplicarSeleccion,
	girar = girarSeleccion,
	aplicar = aplicarASeleccion,
	limpiarSeleccion = limpiarSeleccion,
	apuntar = apuntar,
	instantanea = instantanea,
	restaurar = restaurar,

	deshacer = function ()
		if #historial == 0 then return end
		table.insert(futuro, instantanea())
		restaurar(table.remove(historial))
	end,

	rehacer = function ()
		if #futuro == 0 then return end
		table.insert(historial, instantanea())
		restaurar(table.remove(futuro))
	end,

	vaciar = function ()
		apuntar()
		obra:ClearAllChildren()
		limpiarSeleccion()
	end,
}

local ui = Ui.Crear(api)

--------------------------------------------------------------------------------
-- Entrada
--------------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function (input, procesado)
	if procesado then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local golpe = rayoDelRaton()
		local parte = golpe and golpe.Instance

		if parte and parte:IsDescendantOf(obra) then
			local anadir = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			seleccionar({ parte }, anadir)
			empezarArrastre()
		else
			limpiarSeleccion()
		end

	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		mirando = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

	elseif input.KeyCode == Enum.KeyCode.Delete
		or input.KeyCode == Enum.KeyCode.Backspace then
		borrarSeleccion()

	elseif input.KeyCode == Enum.KeyCode.R then
		girarSeleccion(Vector3.yAxis)
	elseif input.KeyCode == Enum.KeyCode.T then
		girarSeleccion(Vector3.xAxis)

	elseif input.KeyCode == Enum.KeyCode.G then
		estado.rejilla = estado.rejilla > 0 and 0 or 1
		ui.refrescarEstado()

	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		if input.KeyCode == Enum.KeyCode.Z then
			api.deshacer()
		elseif input.KeyCode == Enum.KeyCode.Y then
			api.rehacer()
		elseif input.KeyCode == Enum.KeyCode.D then
			duplicarSeleccion()
		elseif input.KeyCode == Enum.KeyCode.S then
			ui.abrirGuardar()
		end
	end
end)

UserInputService.InputEnded:Connect(function (input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		arrastrando = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		mirando = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

UserInputService.InputChanged:Connect(function (input, procesado)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if mirando then
			giroCamara += Vector2.new(-input.Delta.X, -input.Delta.Y) * 0.3
			giroCamara = Vector2.new(giroCamara.X,
				math.clamp(giroCamara.Y, -89, 89))
		elseif arrastrando then
			seguirArrastre()
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel and not procesado then
		velocidad = math.clamp(velocidad + input.Position.Z * 10, 10, 300)
	end
end)

--------------------------------------------------------------------------------
-- Arranque
--------------------------------------------------------------------------------

-- Sin personaje: esto es un editor, no un nivel.
if player.Character then
	player.Character:Destroy()
end

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(40, 30, 40), Vector3.new(0, 4, 0))

do
	local look = camera.CFrame.LookVector
	giroCamara = Vector2.new(math.deg(math.atan2(-look.X, -look.Z)),
	                         math.deg(math.asin(look.Y)))
end

RunService.RenderStepped:Connect(function (dt)
	moverCamara(dt)

	local pos = camera.CFrame.Position
	camera.CFrame = CFrame.new(pos)
		* CFrame.Angles(0, math.rad(giroCamara.X), 0)
		* CFrame.Angles(math.rad(giroCamara.Y), 0, 0)

	ui.refrescarContador()
end)

-- Suelo de trabajo, para tener donde apoyar la primera pieza.
if not workspace:FindFirstChild("SueloDelEditor") then
	local suelo = Instance.new("Part")
	suelo.Name = "SueloDelEditor"
	suelo.Size = Vector3.new(512, 4, 512)
	suelo.Position = Vector3.new(0, -2, 0)
	suelo.Anchored = true
	suelo.Locked = true
	suelo.BrickColor = BrickColor.new(28)
	suelo.TopSurface = Enum.SurfaceType.Studs
	suelo.Material = Enum.Material.Plastic
	suelo.Parent = workspace
end

print("[Bygone Studio] Editor listo.")
