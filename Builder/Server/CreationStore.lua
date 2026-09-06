--!nocheck
--[[
	CreationStore -- donde viven las creaciones de la gente.

	Tres almacenes, cada uno con un trabajo:

	  Creaciones      id -> { meta, datos }   el contenido completo
	  DeUsuario       userId -> lista de ids  para "mis creaciones"
	  Recientes       OrderedDataStore        para la galeria del vestibulo

	Se usa un OrderedDataStore para la galeria porque un DataStore normal no
	sabe ordenar ni paginar: habria que leer todas las claves para sacar las
	diez ultimas. El ordenado guarda solo id -> marca de tiempo, y de ahi se
	piden los detalles de las que hagan falta.

	Todas las llamadas a DataStore van en pcall. Roblox las limita y falla mas
	de lo que la gente cree; una peticion perdida no puede tumbar el servidor
	ni hacerle perder el trabajo a un jugador sin avisarle.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local CreationStore = {}

local LIMITE_POR_USUARIO = 40

local ok, err = pcall(function ()
	CreationStore.Creaciones = DataStoreService:GetDataStore("BygoneCreaciones_v1")
	CreationStore.DeUsuario = DataStoreService:GetDataStore("BygoneDeUsuario_v1")
	CreationStore.Recientes = DataStoreService:GetOrderedDataStore("BygoneRecientes_v1")
	CreationStore.Populares = DataStoreService:GetOrderedDataStore("BygonePopulares_v1")
end)

CreationStore.Disponible = ok

if not ok then
	warn("[CreationStore] Sin DataStores: " .. tostring(err))
	warn("[CreationStore] En Studio hace falta Game Settings > Security > "
		.. "Enable Studio Access to API Services.")
end

--------------------------------------------------------------------------------

local function reintentar(descripcion, fn, intentos)
	intentos = intentos or 3
	local ultimoError

	for i = 1, intentos do
		local exito, resultado = pcall(fn)
		if exito then
			return true, resultado
		end
		ultimoError = resultado
		if i < intentos then
			task.wait(2 ^ i)          -- 2s, 4s: Roblox limita por rafagas
		end
	end

	warn(("[CreationStore] %s fallo: %s"):format(descripcion, tostring(ultimoError)))
	return false, ultimoError
end

local function nuevoId()
	return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
end

--------------------------------------------------------------------------------
-- Leer
--------------------------------------------------------------------------------

function CreationStore.Obtener(id)
	if not CreationStore.Disponible or type(id) ~= "string" then
		return nil
	end

	local ok_, datos = reintentar("Obtener " .. id, function ()
		return CreationStore.Creaciones:GetAsync(id)
	end)

	return ok_ and datos or nil
end

function CreationStore.IdsDeUsuario(userId)
	if not CreationStore.Disponible then
		return {}
	end

	local ok_, lista = reintentar("IdsDeUsuario", function ()
		return CreationStore.DeUsuario:GetAsync(tostring(userId))
	end)

	return (ok_ and type(lista) == "table") and lista or {}
end

--- Fichas resumidas (sin las partes) para pintar una lista.
function CreationStore.ResumenDeUsuario(userId)
	local fichas = {}

	for _, id in ipairs(CreationStore.IdsDeUsuario(userId)) do
        local entrada = CreationStore.Obtener(id)
		if entrada and entrada.meta then
			table.insert(fichas, entrada.meta)
		end
	end

	table.sort(fichas, function (a, b)
		return (a.actualizado or 0) > (b.actualizado or 0)
	end)

	return fichas
end

--- Las ultimas publicadas, para la galeria.
function CreationStore.Galeria(cuantas, porPopularidad)
	if not CreationStore.Disponible then
		return {}
	end

	cuantas = math.clamp(cuantas or 24, 1, 60)
	local almacen = porPopularidad and CreationStore.Populares or CreationStore.Recientes

	local ok_, paginas = reintentar("Galeria", function ()
		return almacen:GetSortedAsync(false, cuantas)
	end)

	if not ok_ then
		return {}
	end

	local fichas = {}
	for _, entrada in ipairs(paginas:GetCurrentPage()) do
		local creacion = CreationStore.Obtener(entrada.key)
		if creacion and creacion.meta and creacion.meta.publicada then
			table.insert(fichas, creacion.meta)
		end
	end

	return fichas
end

--------------------------------------------------------------------------------
-- Escribir
--------------------------------------------------------------------------------

--- Devuelve (id, motivoDelFallo).
function CreationStore.Guardar(player, id, nombre, descripcion, datos, publicar)
	if not CreationStore.Disponible then
		return nil, "los DataStores no estan disponibles en este servidor"
	end

	local userId = player.UserId
	local esNueva = (id == nil or id == "")

	if esNueva then
		local mias = CreationStore.IdsDeUsuario(userId)
		if #mias >= LIMITE_POR_USUARIO then
			return nil, ("has llegado al limite de %d creaciones; borra alguna")
				:format(LIMITE_POR_USUARIO)
		end
		id = nuevoId()
	else
		-- Nadie edita lo de otro: se comprueba el dueno guardado, no lo que diga
		-- el cliente.
		local existente = CreationStore.Obtener(id)
		if not existente then
			return nil, "esa creacion ya no existe"
		end
		if existente.meta.duenoId ~= userId then
			return nil, "esa creacion no es tuya"
		end
	end

	local ahora = os.time()
	local meta = {
		id = id,
		nombre = nombre,
		descripcion = descripcion,
		duenoId = userId,
		dueno = player.Name,
		partes = #(datos.partes or {}),
		creado = esNueva and ahora or nil,
		actualizado = ahora,
		publicada = publicar and true or false,
		visitas = 0,
	}

	if not esNueva then
		local previo = CreationStore.Obtener(id)
		if previo and previo.meta then
			meta.creado = previo.meta.creado or ahora
			meta.visitas = previo.meta.visitas or 0
		end
	end

	local guardado, errGuardar = reintentar("Guardar " .. id, function ()
		CreationStore.Creaciones:SetAsync(id, { meta = meta, datos = datos })
		return true
	end)

	if not guardado then
		return nil, "no se pudo guardar: " .. tostring(errGuardar)
	end

	if esNueva then
		reintentar("Indice de usuario", function ()
			CreationStore.DeUsuario:UpdateAsync(tostring(userId), function (lista)
				lista = lista or {}
				table.insert(lista, id)
				return lista
			end)
			return true
		end)
	end

	if publicar then
		reintentar("Indice reciente", function ()
			CreationStore.Recientes:SetAsync(id, ahora)
			return true
		end)
	end

	return id
end

function CreationStore.Borrar(player, id)
	if not CreationStore.Disponible then
		return false, "los DataStores no estan disponibles"
	end

	local existente = CreationStore.Obtener(id)
	if not existente then
		return false, "esa creacion ya no existe"
	end
	if existente.meta.duenoId ~= player.UserId then
		return false, "esa creacion no es tuya"
	end

	reintentar("Borrar " .. id, function ()
		CreationStore.Creaciones:RemoveAsync(id)
		return true
	end)

	reintentar("Quitar del indice", function ()
		CreationStore.DeUsuario:UpdateAsync(tostring(player.UserId), function (lista)
			lista = lista or {}
			for i, otro in ipairs(lista) do
				if otro == id then
					table.remove(lista, i)
					break
				end
			end
			return lista
		end)
		return true
	end)

	pcall(function ()
		CreationStore.Recientes:RemoveAsync(id)
		CreationStore.Populares:RemoveAsync(id)
	end)

	return true
end

--- Una visita mas. Se usa UpdateAsync porque puede haber varios servidores
--- tocando la misma creacion a la vez.
function CreationStore.ContarVisita(id)
	if not CreationStore.Disponible then
		return
	end

	task.spawn(function ()
		local visitas = 0

		reintentar("ContarVisita", function ()
			CreationStore.Creaciones:UpdateAsync(id, function (entrada)
				if not entrada or not entrada.meta then
					return nil
				end
				entrada.meta.visitas = (entrada.meta.visitas or 0) + 1
				visitas = entrada.meta.visitas
				return entrada
			end)
			return true
		end)

		if visitas > 0 then
			pcall(function ()
				CreationStore.Populares:SetAsync(id, visitas)
			end)
		end
	end)
end

return CreationStore
