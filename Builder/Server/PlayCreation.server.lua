--!nocheck
--[[
	PlayCreation -- monta la creacion que el jugador venia a jugar.

	El identificador llega en los datos del teletransporte, no como parametro de
	cliente: asi nadie puede pedir que se cargue algo privado escribiendo un id
	a mano. Aun asi el servidor vuelve a comprobar los permisos al leerla.

	Un servidor sirve una sola creacion: el primero que entra decide cual. Los
	que lleguen despues pidiendo otra distinta se reencaminan, porque mezclar
	dos construcciones en el mismo mundo no tiene sentido.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local CreationStore = require(ServerStorage:WaitForChild("CreationStore"))
local Serializer = require(ReplicatedStorage:WaitForChild("Serializer"))

local ALTURA_DE_ENTRADA = 8

local creacionActual = nil
local montada = false

--------------------------------------------------------------------------------

local function mensaje(texto)
	local m = Instance.new("Message")
	m.Text = texto
	m.Parent = workspace
	return m
end

local function suelo()
	if workspace:FindFirstChild("SueloBase") then
		return
	end

	local base = Instance.new("Part")
	base.Name = "SueloBase"
	base.Size = Vector3.new(512, 4, 512)
	base.Position = Vector3.new(0, -2, 0)
	base.Anchored = true
	base.Locked = true
	base.BrickColor = BrickColor.new(28)
	base.TopSurface = Enum.SurfaceType.Studs
	base.Parent = workspace
end

local function ponerSpawn(modelo)
	-- Si la creacion trae su propio punto de aparicion, se respeta.
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("SpawnLocation") then
			return
		end
	end

	local cf, tam = modelo:GetBoundingBox()

	local punto = Instance.new("SpawnLocation")
	punto.Name = "SpawnAutomatico"
	punto.Size = Vector3.new(12, 1, 12)
	punto.Anchored = true
	punto.Neutral = true
	punto.Duration = 0
	punto.BrickColor = BrickColor.new(1001)
	punto.TopSurface = Enum.SurfaceType.Smooth
	punto.BottomSurface = Enum.SurfaceType.Smooth
	punto.CFrame = CFrame.new(cf.X, cf.Y + tam.Y / 2 + ALTURA_DE_ENTRADA, cf.Z)
	punto.Parent = workspace
end

local function montar(id)
	local entrada = CreationStore.Obtener(id)

	if not entrada then
		mensaje("That creation could not be found.")
		return false
	end

	if not entrada.meta.publicada then
		mensaje("That creation is private.")
		return false
	end

	local aviso = mensaje("Loading " .. (entrada.meta.nombre or "creation") .. "...")

	local modelo = Serializer.Deserializar(entrada.datos, workspace)
	modelo.Name = entrada.meta.nombre or "Creacion"

	ponerSpawn(modelo)
	CreationStore.ContarVisita(id)

	creacionActual = entrada.meta
	montada = true

	local ficha = Instance.new("StringValue")
	ficha.Name = "CreacionActual"
	ficha.Value = ("%s|%s|%d"):format(entrada.meta.nombre or "",
		entrada.meta.dueno or "", entrada.meta.partes or 0)
	ficha.Parent = ReplicatedStorage

	aviso:Destroy()
	return true
end

--------------------------------------------------------------------------------

local function alEntrar(player)
	local datos = player:GetJoinData()
	local id = datos and datos.TeleportData and datos.TeleportData.creacion

	if not montada then
		if type(id) ~= "string" then
			mensaje("Come in from the Bygone lobby to play a creation.")
			return
		end

		if not montar(id) then
			return
		end
	end

	-- Este servidor ya sirve otra creacion: lo mandamos a uno nuevo en vez de
	-- mezclar dos construcciones en el mismo mundo.
	if type(id) == "string" and creacionActual and id ~= creacionActual.id then
		local opciones = Instance.new("TeleportOptions")
		opciones.ShouldReserveServer = true
		opciones:SetTeleportData({ creacion = id })

		pcall(function ()
			TeleportService:TeleportAsync(game.PlaceId, { player }, opciones)
		end)
		return
	end

	--[[
		Quien pide el personaje es la pantalla de carga del motor, a traves de
		ReplicatedStorage.RequestCharacter. Si lo cargamos tambien aqui, el
		jugador aparece dos veces y el segundo cuerpo empuja al primero.

		Asi que solo se carga a mano cuando el motor no esta presente.
	]]
	if not ReplicatedStorage:FindFirstChild("RequestCharacter") then
		player:LoadCharacter()
	end
end

suelo()

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(alEntrar, player)
end

Players.PlayerAdded:Connect(alEntrar)
