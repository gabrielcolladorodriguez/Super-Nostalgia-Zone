--!nocheck
--[[
	Bygone Studios -- el editor.

	Corre entero en el cliente para que el raton responda al instante; el
	servidor solo interviene al guardar, y no se cree nada de lo que le llega
	(ver BuilderService).

	Dos formas de mover, a proposito:

	  los tiradores   flechas, arcos y asas alrededor de la seleccion, para
	                  ajustar con precision en un eje
	  arrastrar       coges la pieza y la apoyas sobre lo que haya debajo,
	                  encajada a la rejilla. Es como se construia en 2008 y
	                  sigue siendo lo mas rapido para levantar algo de cero

	Atajos:
	  1 / 2 / 3       mover / girar / escalar     G       rejilla
	  clic            seleccionar                 shift   anadir a la seleccion
	  suprimir        borrar                      ctrl+D  duplicar
	  ctrl+Z / ctrl+Y deshacer / rehacer          ctrl+S  guardar
	  F               centrar la camara           clic dcho  mirar
	  WASD + Q/E      volar                       shift   volar rapido
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Palette = require(script:WaitForChild("Palette"))
local Gizmos = require(script:WaitForChild("Gizmos"))
local Serializer = require(ReplicatedStorage:WaitForChild("Serializer"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local UI = Palette.UI

local canal = ReplicatedStorage:WaitForChild("Constructor", 30)

local TACTIL = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

--------------------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------------------

local obra = workspace:FindFirstChild("Obra") or Instance.new("Folder")
obra.Name = "Obra"
obra.Parent = workspace

local estado = {
	seleccion = {},
	rejilla = 1,
	giro = 45,
	forma = 1,
	color = 194,
	material = 0,
	superficieArriba = Enum.SurfaceType.Studs,
	modo = "mover",
	id = nil,
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
-- poca memoria y evita la clase de fallo donde deshacer y rehacer se
-- desincronizan por una operacion inversa mal escrita.

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
local gizmos

local function pintarSeleccion()
	for parte, caja in pairs(cajas) do
		if not table.find(estado.seleccion, parte) or not parte.Parent then
			caja:Destroy()
			cajas[parte] = nil
		end
	end

	for _, parte in ipairs(estado.seleccion) do
		if not cajas[parte] and parte.Parent then
			local caja = Instance.new("SelectionBox")
			caja.Adornee = parte
			caja.LineThickness = 0.05
			caja.Color3 = UI.SELECCION
			caja.SurfaceColor3 = UI.SELECCION
			caja.SurfaceTransparency = 0.88
			caja.Parent = parte
			cajas[parte] = caja
		end
	end

	if gizmos then
		gizmos:Refrescar()
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
-- Rejilla
--------------------------------------------------------------------------------

local function encajar(v)
	if estado.rejilla <= 0 then
		return v
	end
	local g = estado.rejilla
	return Vector3.new(math.round(v.X / g) * g,
	                   math.round(v.Y / g) * g,
	                   math.round(v.Z / g) * g)
end

local function encajarEscalar(n)
	if estado.rejilla <= 0 then
		return n
	end
	return math.round(n / estado.rejilla) * estado.rejilla
end

local function encajarGiro(radianes)
	local paso = math.rad(estado.giro)
	if paso <= 0 then
		return radianes
	end
	return math.round(radianes / paso) * paso
end

--------------------------------------------------------------------------------
-- Rayos
--------------------------------------------------------------------------------

local parametros = RaycastParams.new()
parametros.FilterType = Enum.RaycastFilterType.Exclude

local function rayoDelRaton(ignorar)
	local pos = UserInputService:GetMouseLocation()
	local rayo = camera:ViewportPointToRay(pos.X, pos.Y)

	local excluir = { player.Character }
	for _, parte in ipairs(ignorar or {}) do
		table.insert(excluir, parte)
	end
	if gizmos then
		table.insert(excluir, gizmos.ancla)
	end
	parametros.FilterDescendantsInstances = excluir

	return workspace:Raycast(rayo.Origin, rayo.Direction * 3000, parametros)
end

--------------------------------------------------------------------------------
-- Crear
--------------------------------------------------------------------------------

local function contarPartes()
	local n = 0
	for _, d in ipairs(obra:GetDescendants()) do
		if d:IsA("BasePart") then n += 1 end
	end
	return n
end

local function hayHueco(cuantas)
	return contarPartes() + (cuantas or 1) <= Serializer.MAX_PARTES
end

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

--- Donde cae una pieza de este tamano segun lo que haya bajo el raton.
local function puntoBajoElRaton(tam, ignorar)
	local golpe = rayoDelRaton(ignorar)

	if golpe then
		local n = golpe.Normal
		return encajar(golpe.Position
			+ Vector3.new(n.X * tam.X / 2, n.Y * tam.Y / 2, n.Z * tam.Z / 2))
	end

	local pos = UserInputService:GetMouseLocation()
	local rayo = camera:ViewportPointToRay(pos.X, pos.Y)
	local p = rayo.Origin + rayo.Direction * 45
	return encajar(Vector3.new(p.X, tam.Y / 2, p.Z))
end

local function colocar()
	if not hayHueco() then
		return nil, "no caben mas partes"
	end

	local parte = nuevaParte()
	apuntar()
	parte.Position = puntoBajoElRaton(parte.Size)
	parte.Parent = obra
	seleccionar({ parte }, false)
	return parte
end

--------------------------------------------------------------------------------
-- Extras sobre la seleccion
--------------------------------------------------------------------------------

local function quitarDeTipo(parte, clases)
	for _, hijo in ipairs(parte:GetChildren()) do
		for _, clase in ipairs(clases) do
			if hijo:IsA(clase) then
				hijo:Destroy()
				break
			end
		end
	end
end

local Extras = {}

function Extras.Luz(parte, tipo)
	quitarDeTipo(parte, { "PointLight", "SpotLight", "SurfaceLight" })
	local clases = { Point = "PointLight", Spot = "SpotLight",
	                 Surface = "SurfaceLight" }
	local luz = Instance.new(clases[tipo] or "PointLight")
	luz.Brightness = 2
	luz.Range = 24
	luz.Color = BrickColor.new(estado.color).Color
	luz.Parent = parte
end

function Extras.Cartel(parte, texto, cara)
	quitarDeTipo(parte, { "SurfaceGui" })

	local gui = Instance.new("SurfaceGui")
	gui.Face = cara or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = parte

	local etiqueta = Instance.new("TextLabel")
	etiqueta.BackgroundTransparency = 1
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.Font = Enum.Font.Cartoon
	etiqueta.TextScaled = true
	etiqueta.Text = texto
	etiqueta.TextColor3 = Color3.fromRGB(30, 30, 30)
	etiqueta.Parent = gui
end

function Extras.Calcomania(parte, id, cara)
	quitarDeTipo(parte, { "Decal" })
	local calco = Instance.new("Decal")
	calco.Face = cara or Enum.NormalId.Front
	calco.Texture = id
	calco.Parent = parte
end

function Extras.Malla(parte, meshId, textureId)
	quitarDeTipo(parte, { "SpecialMesh" })
	local malla = Instance.new("SpecialMesh")
	malla.MeshType = Enum.MeshType.FileMesh
	malla.MeshId = meshId
	malla.TextureId = textureId or ""
	malla.Parent = parte
end

function Extras.Limpiar(parte)
	quitarDeTipo(parte, { "PointLight", "SpotLight", "SurfaceLight",
	                      "SurfaceGui", "Decal", "SpecialMesh" })
end

--------------------------------------------------------------------------------
-- Operaciones
--------------------------------------------------------------------------------

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
	if not hayHueco(#estado.seleccion) then
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

local function aplicarASeleccion(fn)
	if #estado.seleccion == 0 then return false end
	apuntar()
	for _, parte in ipairs(estado.seleccion) do
		pcall(fn, parte)
	end
	pintarSeleccion()
	return true
end

--------------------------------------------------------------------------------
-- Camara
--------------------------------------------------------------------------------

local velocidad = 70
local mirando = false
local giroCamara = Vector2.new()

local function centrarEnSeleccion()
	if #estado.seleccion == 0 then return end

	local centro = Vector3.zero
	for _, parte in ipairs(estado.seleccion) do
		centro += parte.Position
	end
	centro /= #estado.seleccion

	camera.CFrame = CFrame.new(centro + Vector3.new(24, 18, 24), centro)
	local look = camera.CFrame.LookVector
	giroCamara = Vector2.new(math.deg(math.atan2(-look.X, -look.Z)),
	                         math.deg(math.asin(look.Y)))
end

--------------------------------------------------------------------------------
-- Arrastrar sobre la superficie
--------------------------------------------------------------------------------

local arrastrando = false
local offsets = {}

local function empezarArrastre()
	if #estado.seleccion == 0 then return end
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
	local destino = puntoBajoElRaton(principal.Size, estado.seleccion)

	for parte, offset in pairs(offsets) do
		if parte.Parent then
			parte.Position = destino + offset
		end
	end

	if gizmos then
		gizmos:Refrescar()
	end
end

--------------------------------------------------------------------------------
-- El suelo, editable como todo lo demas
--------------------------------------------------------------------------------

local suelo = workspace:FindFirstChild("Baseplate")

if not suelo then
	suelo = Instance.new("Part")
	suelo.Name = "Baseplate"
	suelo.Size = Vector3.new(512, 8, 512)
	suelo.Position = Vector3.new(0, -4, 0)
	suelo.Anchored = true
	suelo.Locked = true
	suelo.BrickColor = BrickColor.new(28)
	suelo.Material = Enum.Material.Plastic
	suelo.TopSurface = Enum.SurfaceType.Studs
	suelo.BottomSurface = Enum.SurfaceType.Smooth
	suelo.Parent = workspace
end

--------------------------------------------------------------------------------
-- La interfaz, en su modulo
--------------------------------------------------------------------------------

local capaGizmos = Instance.new("ScreenGui")
capaGizmos.Name = "Gizmos"
capaGizmos.ResetOnSpawn = false
capaGizmos.Parent = playerGui

local api = {
	estado = estado,
	obra = obra,
	suelo = suelo,
	canal = canal,
	Serializer = Serializer,
	Palette = Palette,
	Extras = Extras,
	TACTIL = TACTIL,
	pantallaGizmos = capaGizmos,

	contarPartes = contarPartes,
	colocar = colocar,
	borrar = borrarSeleccion,
	duplicar = duplicarSeleccion,
	aplicar = aplicarASeleccion,
	seleccionar = seleccionar,
	limpiarSeleccion = limpiarSeleccion,
	pintarSeleccion = pintarSeleccion,
	centrar = centrarEnSeleccion,
	apuntar = apuntar,
	instantanea = instantanea,
	restaurar = restaurar,
	encajarEscalar = encajarEscalar,
	encajarGiro = encajarGiro,

	deshacer = function ()
		if #historial == 0 then return end
		table.insert(futuro, instantanea())
		restaurar(table.remove(historial))
		pintarSeleccion()
	end,

	rehacer = function ()
		if #futuro == 0 then return end
		table.insert(historial, instantanea())
		restaurar(table.remove(futuro))
		pintarSeleccion()
	end,

	vaciar = function ()
		apuntar()
		obra:ClearAllChildren()
		limpiarSeleccion()
	end,
}

gizmos = Gizmos.new(api)
api.gizmos = gizmos

api.modo = function (modo)
	estado.modo = modo
	gizmos:Modo(modo)
end

local Ui = require(script:WaitForChild("Ui"))
local ui = Ui.Crear(api)
api.ui = ui

--------------------------------------------------------------------------------
-- Entrada
--------------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function (input, procesado)
	if procesado or gizmos:Ocupado() then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		local golpe = rayoDelRaton()
		local parte = golpe and golpe.Instance

		if parte and (parte:IsDescendantOf(obra) or parte == suelo) then
			local anadir = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			seleccionar({ parte }, anadir)
			if not TACTIL then
				empezarArrastre()
			end
		else
			limpiarSeleccion()
		end

	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		mirando = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

	elseif input.KeyCode == Enum.KeyCode.One then
		api.modo("mover"); ui.refrescarModo()
	elseif input.KeyCode == Enum.KeyCode.Two then
		api.modo("girar"); ui.refrescarModo()
	elseif input.KeyCode == Enum.KeyCode.Three then
		api.modo("escalar"); ui.refrescarModo()

	elseif input.KeyCode == Enum.KeyCode.Delete
		or input.KeyCode == Enum.KeyCode.Backspace then
		borrarSeleccion()

	elseif input.KeyCode == Enum.KeyCode.F then
		centrarEnSeleccion()

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
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		arrastrando = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		mirando = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

UserInputService.InputChanged:Connect(function (input, procesado)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if mirando then
			giroCamara += Vector2.new(-input.Delta.X, -input.Delta.Y) * 0.32
			giroCamara = Vector2.new(giroCamara.X, math.clamp(giroCamara.Y, -89, 89))
		elseif arrastrando then
			seguirArrastre()
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel and not procesado then
		velocidad = math.clamp(velocidad + input.Position.Z * 12, 12, 320)
	end
end)

--------------------------------------------------------------------------------
-- Camara en tactil: dos dedos giran, uno arrastra la pieza
--------------------------------------------------------------------------------

if TACTIL then
	UserInputService.TouchRotate:Connect(function (_, rotacion)
		giroCamara += Vector2.new(-rotacion.X, 0) * 40
	end)

	UserInputService.TouchPan:Connect(function (toques, delta, _, estadoToque)
		if #toques >= 2 then
			giroCamara += Vector2.new(-delta.X, -delta.Y) * 0.28
			giroCamara = Vector2.new(giroCamara.X, math.clamp(giroCamara.Y, -89, 89))
		end
	end)

	UserInputService.TouchPinch:Connect(function (_, escala)
		camera.CFrame = camera.CFrame + camera.CFrame.LookVector * (escala - 1) * 30
	end)
end

--------------------------------------------------------------------------------
-- Arranque
--------------------------------------------------------------------------------

if player.Character then
	player.Character:Destroy()
end

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(48, 34, 48), Vector3.new(0, 4, 0))

do
	local look = camera.CFrame.LookVector
	giroCamara = Vector2.new(math.deg(math.atan2(-look.X, -look.Z)),
	                         math.deg(math.asin(look.Y)))
end

RunService.RenderStepped:Connect(function (dt)
	local mover = Vector3.zero
	local abajo = UserInputService.IsKeyDown

	if abajo(UserInputService, Enum.KeyCode.W) then mover += camera.CFrame.LookVector end
	if abajo(UserInputService, Enum.KeyCode.S) then mover -= camera.CFrame.LookVector end
	if abajo(UserInputService, Enum.KeyCode.A) then mover -= camera.CFrame.RightVector end
	if abajo(UserInputService, Enum.KeyCode.D) then mover += camera.CFrame.RightVector end
	if abajo(UserInputService, Enum.KeyCode.E) then mover += Vector3.yAxis end
	if abajo(UserInputService, Enum.KeyCode.Q) then mover -= Vector3.yAxis end

	local rapido = abajo(UserInputService, Enum.KeyCode.LeftShift) and 3 or 1
	local pos = camera.CFrame.Position

	if mover.Magnitude > 0 then
		pos += mover.Unit * velocidad * rapido * dt
	end

	camera.CFrame = CFrame.new(pos)
		* CFrame.Angles(0, math.rad(giroCamara.X), 0)
		* CFrame.Angles(math.rad(giroCamara.Y), 0, 0)

	ui.refrescarContador()
end)

api.modo("mover")
print("[Bygone Studios] Editor listo.")
