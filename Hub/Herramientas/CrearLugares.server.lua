--!nocheck
--[[
	CrearLugares.server.lua  --  utilidad de un solo uso.

	La API publica de Open Cloud sabe ACTUALIZAR un lugar, pero no sabe CREARLO.
	La unica via oficial para crear lugares dentro de un universo es
	AssetService:CreatePlaceAsync, que solo corre desde dentro del juego.

	Este script crea un lugar vacio por cada juego del catalogo y luego imprime
	la correspondencia nombre -> placeId, que es lo que necesita
	publicar_universo.py para subir cada archivo a su sitio.

	COMO USARLO
	  1. Publica el hub como experiencia nueva en tu cuenta.
	  2. Pon Disabled = false en este script y publica otra vez.
	  3. Entra al juego (o dale a Play en un servidor). Mira la Consola del
	     Desarrollador (F9) o el Output de Studio.
	  4. Copia el bloque JSON que imprime a placeids.json.
	  5. Vuelve a poner Disabled = true y publica.

	Es idempotente: los lugares que ya existen con ese nombre no se recrean,
	asi que puedes ejecutarlo varias veces si se corta a medias.
]]

local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PAUSA_ENTRE_CREACIONES = 2   -- segundos; Roblox limita las creaciones
local MAX_POR_EJECUCION = 0        -- 0 = sin tope

local catalogo = require(ReplicatedStorage:WaitForChild("CatalogoJuegos"))

local function iterPageItems(pages)
	return coroutine.wrap(function ()
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item)
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
end

local existentes = {}
local total = 0

for place in iterPageItems(AssetService:GetGamePlacesAsync()) do
	existentes[place.Name] = place.PlaceId
	total = total + 1
end

print(("[CrearLugares] El universo ya tiene %d lugares."):format(total))
print(("[CrearLugares] El catalogo pide %d juegos."):format(#catalogo))

local creados, fallos, saltados = 0, 0, 0

for _, ficha in ipairs(catalogo) do
	if MAX_POR_EJECUCION > 0 and creados >= MAX_POR_EJECUCION then
		print("[CrearLugares] Alcanzado el tope de esta ejecucion.")
		break
	end

	if existentes[ficha.titulo] then
		saltados = saltados + 1
	else
		local descripcion = ("%s (%s%s) - clasico de 2006-2010 preservado y jugable en Bygone."):format(
			ficha.titulo,
			ficha.creador or "autor desconocido",
			ficha.anio and (", " .. ficha.anio) or "")

		local ok, resultado = pcall(function ()
			return AssetService:CreatePlaceAsync(ficha.titulo, game.PlaceId, descripcion)
		end)

		if ok then
			existentes[ficha.titulo] = resultado
			creados = creados + 1
			print(("[CrearLugares] %3d  %-45s -> %d"):format(creados, ficha.titulo, resultado))
		else
			fallos = fallos + 1
			warn(("[CrearLugares] fallo con %s: %s"):format(ficha.titulo, tostring(resultado)))
		end

		task.wait(PAUSA_ENTRE_CREACIONES)
	end
end

print(("[CrearLugares] Creados %d, ya existian %d, fallidos %d.")
	:format(creados, saltados, fallos))

local mapa = {}
for _, ficha in ipairs(catalogo) do
	if existentes[ficha.titulo] then
		mapa[ficha.titulo] = existentes[ficha.titulo]
	end
end

-- Se imprime de dos formas a proposito. El JSON de una linea es comodo de
-- copiar, pero con 154 juegos ronda los 7 KB y la Consola puede recortarlo;
-- la lista linea a linea siempre sale entera y publicar_universo.py tambien
-- la entiende (guardala como placeids.txt).
print("\n===== LISTA (una linea por juego) -> placeids.txt =====")
for _, ficha in ipairs(catalogo) do
	if mapa[ficha.titulo] then
		print(("%s\t%d"):format(ficha.titulo, mapa[ficha.titulo]))
	end
end
print("===== FIN DE LA LISTA =====")

print("\n===== JSON (si sale entero) -> placeids.json =====")
print(HttpService:JSONEncode(mapa))
print("===== FIN =====")
