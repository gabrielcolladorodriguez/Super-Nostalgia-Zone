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
local Piezas = require(script:WaitForChild("Piezas"))
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
	local forma = Piezas.FORMAS[estado.forma]
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

--- Texto del cartel que ya lleve la parte, o nil.
function Extras.LeerCartel(parte)
	local gui = parte:FindFirstChildWhichIsA("SurfaceGui")
	if not gui then
		return nil
	end
	local etiqueta = gui:FindFirstChildWhichIsA("TextLabel")
	return etiqueta and etiqueta.Text or nil, gui.Face
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
-- Prefabricados
--------------------------------------------------------------------------------
-- Se montan como partes normales y corrientes: en cuanto caen, el editor ya no
-- los distingue de nada colocado a mano. Por eso el formato de guardado no
-- necesita saber que existen.

local function colocarPrefab(prefab)
	local cuantas = #prefab.partes
	if not hayHueco(cuantas) then
		return nil, "no caben mas partes"
	end

	-- El punto de apoyo se calcula con la pieza mas baja, para que el conjunto
	-- descanse sobre lo que haya debajo en vez de hundirse.
	local base = puntoBajoElRaton(Vector3.new(1, 0.1, 1))

	apuntar()
	local creadas = {}

	for _, def in ipairs(prefab.partes) do
		local clase = Serializer.FORMAS[def.clase or 0] or Serializer.FORMAS[0]
		local parte = Instance.new(clase.clase)

		parte.Name = def.nombre
		parte.Size = def.tam
		parte.Position = base + def.pos
		parte.Anchored = true
		parte.BrickColor = BrickColor.new(def.color or estado.color)

		if def.neon then
			parte.Material = Enum.Material.Neon
		else
			parte.Material = Serializer.MATERIALES[estado.material]
				or Enum.Material.Plastic
		end

		if def.transparencia then
			parte.Transparency = def.transparencia
		end

		if def.superficie == "Smooth" then
			parte.TopSurface = Enum.SurfaceType.Smooth
			parte.BottomSurface = Enum.SurfaceType.Smooth
		elseif parte:IsA("Part") then
			parte.TopSurface = Enum.SurfaceType.Studs
			parte.BottomSurface = Enum.SurfaceType.Inlet
		end

		if def.luz then
			local luz = Instance.new("PointLight")
			luz.Brightness = def.luz.brillo or 2
			luz.Range = def.luz.alcance or 20
			luz.Color = parte.BrickColor.Color
			luz.Parent = parte
		end

		if def.cartel then
			Extras.Cartel(parte, def.cartel, Enum.NormalId.Front)
		end

		parte.Parent = obra
		table.insert(creadas, parte)
	end

	seleccionar(creadas, false)
	return creadas
end

--------------------------------------------------------------------------------
-- Numeros exactos
--------------------------------------------------------------------------------

--- Aplica lo escrito en los tres campos de una fila. Un campo vacio o con
--- basura se deja como estaba: escribir mal una casilla no debe mover nada.
local function aplicarTransform(clave, cajas)
	if #estado.seleccion == 0 then
		return false
	end

	local valores = {}
	local alguno = false

	for i = 1, 3 do
		local n = tonumber(cajas[i].Text)
		if n and n == n and math.abs(n) < 1e6 then
			valores[i] = n
			alguno = true
		end
	end

	if not alguno then
		return false
	end

	apuntar()

	for _, parte in ipairs(estado.seleccion) do
		if clave == "pos" then
			local p = parte.Position
			parte.Position = Vector3.new(valores[1] or p.X, valores[2] or p.Y,
			                             valores[3] or p.Z)
		elseif clave == "tam" then
			local t = parte.Size
			parte.Size = Vector3.new(
				math.max(0.05, valores[1] or t.X),
				math.max(0.05, valores[2] or t.Y),
				math.max(0.05, valores[3] or t.Z))
		elseif clave == "rot" then
			local rx, ry, rz = parte.CFrame:ToOrientation()
			parte.CFrame = CFrame.new(parte.Position)
				* CFrame.fromOrientation(
					math.rad(valores[1] or math.deg(rx)),
					math.rad(valores[2] or math.deg(ry)),
					math.rad(valores[3] or math.deg(rz)))
		end
	end

	pintarSeleccion()
	return true
end

local function seleccionarTodo()
	local todas = {}
	for _, d in ipairs(obra:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(todas, d)
		end
	end
	seleccionar(todas, false)
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
-- El suelo
--------------------------------------------------------------------------------
--[[
	Va DENTRO de la obra, no suelto en el Workspace.

	Antes estaba fuera y eso lo dejaba en tierra de nadie: el boton "Baseplate"
	lo seleccionaba, le cambiabas el color o el tamano, guardabas... y no se
	guardaba nada, porque el serializador solo mira dentro de la obra. Y al
	jugar la creacion aparecia otro suelo distinto generado por el Arcade.

	Metido en la obra es una pieza mas: se guarda, viaja con la creacion, y
	quien no lo quiera lo borra.
]]

local function crearSuelo()
	local nuevo = Instance.new("Part")
	nuevo.Name = "Baseplate"
	nuevo.Size = Vector3.new(512, 8, 512)
	nuevo.Position = Vector3.new(0, -4, 0)
	nuevo.Anchored = true
	nuevo.BrickColor = BrickColor.new(28)
	nuevo.Material = Enum.Material.Plastic
	nuevo.TopSurface = Enum.SurfaceType.Studs
	nuevo.BottomSurface = Enum.SurfaceType.Smooth
	nuevo.Parent = obra
	return nuevo
end

local function sueloActual()
	return obra:FindFirstChild("Baseplate")
end

local suelo = sueloActual() or crearSuelo()



--------------------------------------------------------------------------------
-- Plantillas
--------------------------------------------------------------------------------
-- Cada una deja piezas normales sobre el suelo. No son un tipo aparte: en
-- cuanto caen, se editan como cualquier otra cosa.

local function ponerPlantilla(indice)
	if indice == 1 then
		return          -- baseplate a secas
	end

	local function poner(nombre, tam, pos, color, liso)
		local parte = Instance.new("Part")
		parte.Name = nombre
		parte.Size = tam
		parte.Position = pos
		parte.Anchored = true
		parte.BrickColor = BrickColor.new(color)
		if liso then
			parte.TopSurface = Enum.SurfaceType.Smooth
			parte.BottomSurface = Enum.SurfaceType.Smooth
		else
			parte.TopSurface = Enum.SurfaceType.Studs
			parte.BottomSurface = Enum.SurfaceType.Inlet
		end
		parte.Parent = obra
		return parte
	end

	if indice == 2 then          -- cuarto con hueco de puerta
		poner("Suelo", Vector3.new(60, 2, 48), Vector3.new(0, 1, 0), 194)
		poner("MuroN", Vector3.new(60, 22, 2), Vector3.new(0, 13, -24), 1002, true)
		poner("MuroE", Vector3.new(2, 22, 48), Vector3.new(30, 13, 0), 1002, true)
		poner("MuroO", Vector3.new(2, 22, 48), Vector3.new(-30, 13, 0), 1002, true)
		poner("MuroSI", Vector3.new(22, 22, 2), Vector3.new(-19, 13, 24), 1002, true)
		poner("MuroSD", Vector3.new(22, 22, 2), Vector3.new(19, 13, 24), 1002, true)
		poner("Dintel", Vector3.new(60, 6, 2), Vector3.new(0, 21, 24), 1002, true)

	elseif indice == 3 then      -- salida de obby y tres saltos
		poner("Salida", Vector3.new(24, 2, 24), Vector3.new(0, 1, -16), 1001)
		for k = 1, 3 do
			poner("Salto" .. k, Vector3.new(10, 1.6, 8),
			      Vector3.new((k % 2 == 0) and 8 or -8, 1 + k * 3, 4 + k * 14),
			      ({ 23, 37, 24 })[k])
		end

	elseif indice == 4 then      -- arena pequena
		poner("Suelo", Vector3.new(80, 2, 80), Vector3.new(0, 1, 0), 194)
		for _, m in ipairs({
			{ "MuroN", Vector3.new(80, 12, 2), Vector3.new(0, 8, -40) },
			{ "MuroS", Vector3.new(80, 12, 2), Vector3.new(0, 8, 40) },
			{ "MuroE", Vector3.new(2, 12, 80), Vector3.new(40, 8, 0) },
			{ "MuroO", Vector3.new(2, 12, 80), Vector3.new(-40, 8, 0) },
		}) do
			poner(m[1], m[2], m[3], 199)
		end
	end
end

--------------------------------------------------------------------------------
-- Modo prueba
--------------------------------------------------------------------------------
--[[
	Andar por lo que acabas de construir sin guardar ni teletransportarte a
	ningun sitio. Es lo que mas se echa de menos en un constructor: sin esto hay
	que guardar, publicar, ir al Arcade y volver, solo para ver si un salto
	llega.

	Las piezas son del cliente, pero el personaje tambien lo simula el cliente,
	asi que las colisiones salen bien. El servidor solo crea y destruye el
	cuerpo, que es lo unico que no se puede hacer desde aqui.
]]

local probando = false

local function alternarPrueba()
	probando = not probando

	if probando then
		limpiarSeleccion()
		gizmos:Refrescar()

		-- Delante de la camara, a ras de lo que estabas mirando.
		local golpe = rayoDelRaton()
		local punto = golpe and golpe.Position
			or (camera.CFrame.Position + camera.CFrame.LookVector * 30)

		canal.Probar:FireServer(true, punto)

		task.spawn(function ()
			local char = player.Character or player.CharacterAdded:Wait()
			local humanoide = char:WaitForChild("Humanoid", 10)
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoide
		end)
	else
		canal.Probar:FireServer(false)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(camera.CFrame.Position)
			* CFrame.Angles(0, math.rad(giroCamara.X), 0)
			* CFrame.Angles(math.rad(giroCamara.Y), 0, 0)
	end

	return probando
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
	sueloActual = sueloActual,
	crearSuelo = crearSuelo,
	canal = canal,
	Serializer = Serializer,
	Palette = Palette,
	Extras = Extras,
	TACTIL = TACTIL,
	pantallaGizmos = capaGizmos,

	contarPartes = contarPartes,
	colocar = colocar,
	colocarPrefab = colocarPrefab,
	aplicarTransform = aplicarTransform,
	seleccionarTodo = seleccionarTodo,
	alternarPrueba = alternarPrueba,
	plantilla = ponerPlantilla,
	estaProbando = function () return probando end,
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

	vaciar = function (conSuelo)
		apuntar()
		obra:ClearAllChildren()
		limpiarSeleccion()
		if conSuelo ~= false then
			suelo = crearSuelo()
		end
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

	-- Mientras pruebas mandan los controles del juego, no los del editor.
	if probando then
		if input.KeyCode == Enum.KeyCode.P then
			alternarPrueba()
			ui.refrescarModo()
		end
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

	elseif input.KeyCode == Enum.KeyCode.P then
		alternarPrueba()
		ui.refrescarModo()

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
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			-- Con shift, la rueda regula lo rapido que vuelas.
			velocidad = math.clamp(velocidad + input.Position.Z * 12, 12, 320)
			if ui then ui.decir(("Fly speed: %d"):format(velocidad)) end
		else
			-- Sin shift hace lo que espera cualquiera: acercar y alejar. El paso
			-- crece con la distancia a lo que miras, para que desde lejos no
			-- tarde una eternidad y de cerca no se pase de largo.
			local golpe = rayoDelRaton()
			local distancia = golpe and (golpe.Position - camera.CFrame.Position).Magnitude
				or 60
			local paso = math.clamp(distancia * 0.12, 2, 90)
			camera.CFrame = camera.CFrame
				+ camera.CFrame.LookVector * input.Position.Z * paso
		end
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
	if probando then
		ui.refrescarContador()
		return
	end

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

--------------------------------------------------------------------------------
-- Abrir lo que venia en el teletransporte
--------------------------------------------------------------------------------
-- Si has llegado desde el menu pulsando "Edit", el identificador viene en los
-- datos del salto. Se carga solo, sin tener que buscarlo otra vez en Open.

task.spawn(function ()
	local datos = player:GetJoinData()
	local id = datos and datos.TeleportData and datos.TeleportData.abrir

	if type(id) ~= "string" or not canal then
		return
	end

	local ok, r = pcall(function ()
		return canal.Cargar:InvokeServer(id)
	end)

	if ok and r and r.ok then
		restaurar(r.datos)
		estado.id = r.meta.id
		estado.nombre = r.meta.nombre
		estado.descripcion = r.meta.descripcion or ""
		estado.sucio = false
		pintarSeleccion()
		ui.decir("Opened: " .. r.meta.nombre)
	else
		ui.decir((r and r.error) or "Could not open that creation.", true)
	end
end)

print("[Bygone Studios] Editor listo.")
