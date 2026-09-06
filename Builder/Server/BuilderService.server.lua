--!nocheck
--[[
	BuilderService -- la parte del constructor en la que se puede confiar.

	El editor entero corre en el cliente, porque tiene que responder al raton
	sin esperar al servidor. Eso significa que nada de lo que llega de el vale
	por si solo: un cliente manipulado puede mandar lo que quiera. Aqui se
	comprueba todo antes de tocar un DataStore.

	Lo que se vigila:
	  - el dueno de una creacion, contra lo guardado, nunca contra lo que diga
	    el cliente
	  - el tamano y la cordura de cada parte (Serializer.Sanear)
	  - el ritmo de peticiones por jugador, para que nadie agote la cuota de
	    DataStore del juego entero
	  - los nombres y descripciones, filtrados por Roblox antes de mostrarse a
	    nadie mas
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local TextService = game:GetService("TextService")

local CreationStore = require(ServerStorage:WaitForChild("CreationStore"))
local Serializer = require(ReplicatedStorage:WaitForChild("Serializer"))

--------------------------------------------------------------------------------
-- Canales con el cliente
--------------------------------------------------------------------------------

local canal = Instance.new("Folder")
canal.Name = "Constructor"
canal.Parent = ReplicatedStorage

local function remoteFunction(nombre)
	local r = Instance.new("RemoteFunction")
	r.Name = nombre
	r.Parent = canal
	return r
end

local Guardar = remoteFunction("Guardar")
local Cargar = remoteFunction("Cargar")
local MisCreaciones = remoteFunction("MisCreaciones")
local Galeria = remoteFunction("Galeria")
local Borrar = remoteFunction("Borrar")

local Jugar = Instance.new("RemoteEvent")
Jugar.Name = "Jugar"
Jugar.Parent = canal

local Editar = Instance.new("RemoteEvent")
Editar.Name = "Editar"
Editar.Parent = canal

--------------------------------------------------------------------------------
-- Ritmo
--------------------------------------------------------------------------------

local ULTIMA = setmetatable({}, { __mode = "k" })

local ESPERA = {
	Guardar = 6,
	Cargar = 1,
	MisCreaciones = 3,
	Galeria = 3,
	Borrar = 4,
	Jugar = 3,
	Editar = 3,
}

local function vaMuyRapido(player, accion)
	local porJugador = ULTIMA[player]
	if not porJugador then
		porJugador = {}
		ULTIMA[player] = porJugador
	end

	local ahora = os.clock()
	local minimo = ESPERA[accion] or 2

	if porJugador[accion] and (ahora - porJugador[accion]) < minimo then
		return true, ("espera %d segundos entre %s")
			:format(minimo, accion:lower())
	end

	porJugador[accion] = ahora
	return false
end

--------------------------------------------------------------------------------
-- Texto
--------------------------------------------------------------------------------

local function textoLimpio(texto, maximo, porDefecto)
	if type(texto) ~= "string" then
		return porDefecto
	end

	texto = texto:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1"):sub(1, maximo)
	return #texto > 0 and texto or porDefecto
end

--- El nombre lo van a ver otros jugadores, asi que pasa por el filtro de
--- Roblox. Si el filtro falla, se rechaza: es preferible no guardar a publicar
--- algo sin filtrar.
local function filtrarParaTodos(texto, autorId)
	local ok, resultado = pcall(function ()
		local filtrado = TextService:FilterStringAsync(texto, autorId)
		return filtrado:GetNonChatStringForBroadcastAsync()
	end)

	if ok then
		return resultado
	end

	warn("[BuilderService] El filtro de texto fallo: " .. tostring(resultado))
	return nil
end

--------------------------------------------------------------------------------
-- Guardar
--------------------------------------------------------------------------------

Guardar.OnServerInvoke = function (player, peticion)
	if type(peticion) ~= "table" then
		return { ok = false, error = "peticion invalida" }
	end

	local rapido, motivo = vaMuyRapido(player, "Guardar")
	if rapido then
		return { ok = false, error = motivo }
	end

	local datos, errDatos = Serializer.Sanear(peticion.datos)
	if not datos then
		return { ok = false, error = errDatos }
	end

	local nombre = textoLimpio(peticion.nombre, 50, "Untitled")
	local descripcion = textoLimpio(peticion.descripcion, 200, "")

	local nombreFiltrado = filtrarParaTodos(nombre, player.UserId)
	if not nombreFiltrado then
		return { ok = false, error = "no se pudo comprobar el nombre, prueba otra vez" }
	end

	local descFiltrada = ""
	if #descripcion > 0 then
		descFiltrada = filtrarParaTodos(descripcion, player.UserId) or ""
	end

	local id, errGuardar = CreationStore.Guardar(
		player,
		type(peticion.id) == "string" and peticion.id or nil,
		nombreFiltrado, descFiltrada, datos,
		peticion.publicar and true or false)

	if not id then
		return { ok = false, error = errGuardar }
	end

	return { ok = true, id = id, partes = #datos.partes }
end

--------------------------------------------------------------------------------
-- Cargar
--------------------------------------------------------------------------------

Cargar.OnServerInvoke = function (player, id)
	local rapido, motivo = vaMuyRapido(player, "Cargar")
	if rapido then
		return { ok = false, error = motivo }
	end

	if type(id) ~= "string" then
		return { ok = false, error = "identificador invalido" }
	end

	local entrada = CreationStore.Obtener(id)
	if not entrada then
		return { ok = false, error = "esa creacion no existe" }
	end

	-- Se puede abrir lo propio, y lo ajeno solo si esta publicado.
	local esMia = entrada.meta.duenoId == player.UserId
	if not esMia and not entrada.meta.publicada then
		return { ok = false, error = "esa creacion es privada" }
	end

	if not esMia then
		CreationStore.ContarVisita(id)
	end

	return { ok = true, meta = entrada.meta, datos = entrada.datos, mia = esMia }
end

--------------------------------------------------------------------------------
-- Listas
--------------------------------------------------------------------------------

MisCreaciones.OnServerInvoke = function (player)
	local rapido, motivo = vaMuyRapido(player, "MisCreaciones")
	if rapido then
		return { ok = false, error = motivo }
	end
	return { ok = true, fichas = CreationStore.ResumenDeUsuario(player.UserId) }
end

Galeria.OnServerInvoke = function (player, porPopularidad)
	local rapido, motivo = vaMuyRapido(player, "Galeria")
	if rapido then
		return { ok = false, error = motivo }
	end
	return { ok = true, fichas = CreationStore.Galeria(24, porPopularidad and true) }
end

Borrar.OnServerInvoke = function (player, id)
	local rapido, motivo = vaMuyRapido(player, "Borrar")
	if rapido then
		return { ok = false, error = motivo }
	end

	local ok, err = CreationStore.Borrar(player, id)
	return { ok = ok, error = err }
end

--------------------------------------------------------------------------------

Players.PlayerRemoving:Connect(function (player)
	ULTIMA[player] = nil
end)

print(("[BuilderService] Listo. DataStores: %s")
	:format(CreationStore.Disponible and "si" or "NO"))


--------------------------------------------------------------------------------
-- Entrar a una creacion
--------------------------------------------------------------------------------
--[[
	El teletransporte se hace aqui y no en el cliente porque TeleportAsync es
	una llamada de servidor: desde un LocalScript devuelve "can only be called
	from the server" y no pasa nada, que es justo lo que ocurria.

	Ademas asi el permiso se comprueba antes de mover a nadie: el cliente manda
	un identificador, no un destino.
]]

local Aviso = Instance.new("RemoteEvent")
Aviso.Name = "Aviso"
Aviso.Parent = canal

local lugarDeJuego = ReplicatedStorage:FindFirstChild("PlayPlaceId")

Jugar.OnServerEvent:Connect(function (player, id)
	local rapido, motivo = vaMuyRapido(player, "Jugar")
	if rapido then
		Aviso:FireClient(player, motivo)
		return
	end

	if type(id) ~= "string" then
		Aviso:FireClient(player, "identificador invalido")
		return
	end

	if not (lugarDeJuego and lugarDeJuego.Value > 0) then
		Aviso:FireClient(player, "Bygone Arcade no esta configurado en este lugar")
		return
	end

	local entrada = CreationStore.Obtener(id)
	if not entrada then
		Aviso:FireClient(player, "esa creacion ya no existe")
		return
	end

	if not entrada.meta.publicada and entrada.meta.duenoId ~= player.UserId then
		Aviso:FireClient(player, "esa creacion es privada")
		return
	end

	local opciones = Instance.new("TeleportOptions")
	opciones:SetTeleportData({ creacion = id })

	local ok, err = pcall(function ()
		TeleportService:TeleportAsync(lugarDeJuego.Value, { player }, opciones)
	end)

	if not ok then
		warn("[BuilderService] Teleport fallo: " .. tostring(err))
		Aviso:FireClient(player, "no se pudo entrar, prueba otra vez")
	end
end)


--------------------------------------------------------------------------------
-- Abrir una creacion propia en el editor
--------------------------------------------------------------------------------
-- Mismo motivo que Jugar: TeleportAsync es de servidor. Y aqui ademas hay que
-- comprobar el dueno, porque abrir en el editor da permiso de escritura.

local lugarDeEditor = ReplicatedStorage:FindFirstChild("StudioPlaceId")

Editar.OnServerEvent:Connect(function (player, id)
	local rapido, motivo = vaMuyRapido(player, "Editar")
	if rapido then
		Aviso:FireClient(player, motivo)
		return
	end

	if not (lugarDeEditor and lugarDeEditor.Value > 0) then
		Aviso:FireClient(player, "Bygone Studios no esta configurado")
		return
	end

	local opciones = Instance.new("TeleportOptions")

	if type(id) == "string" then
		local entrada = CreationStore.Obtener(id)

		if not entrada then
			Aviso:FireClient(player, "esa creacion ya no existe")
			return
		end

		if entrada.meta.duenoId ~= player.UserId then
			Aviso:FireClient(player, "solo puedes editar lo tuyo")
			return
		end

		opciones:SetTeleportData({ abrir = id })
	end

	local ok, err = pcall(function ()
		TeleportService:TeleportAsync(lugarDeEditor.Value, { player }, opciones)
	end)

	if not ok then
		warn("[BuilderService] Teleport al editor fallo: " .. tostring(err))
		Aviso:FireClient(player, "no se pudo abrir el editor, prueba otra vez")
	end
end)
