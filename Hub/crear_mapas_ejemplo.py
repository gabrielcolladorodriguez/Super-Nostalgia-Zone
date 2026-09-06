# -*- coding: utf-8 -*-
"""
Crea unas creaciones de ejemplo a nombre de @PollocrudoCompany.

No se suben como lugares: se escriben directamente en el DataStore del juego,
igual que si las hubiera guardado el editor. Asi aparecen en la galeria del
vestibulo, se pueden abrir en Bygone Studios y editarlas, y sirven de punto de
partida en vez de una galeria vacia.

Van en el formato v2 del Serializer, el mismo que usa el editor. Si ese formato
cambia, este generador tiene que cambiar con el.

Uso:
    python crear_mapas_ejemplo.py --universo 10765392576 --place <studios>
"""

import argparse
import json
import math
import os
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = "https://apis.roblox.com/cloud/v2"

USUARIO_ID = 10885165459
USUARIO = "PollocrudoCompany"

# Numeros de BrickColor clasicos.
C = {
    "rojo": 21, "azul": 23, "amarillo": 24, "verde": 37, "naranja": 106,
    "verde oscuro": 28, "gris": 194, "gris oscuro": 199, "marron": 192,
    "blanco": 1001, "negro": 26, "burdeos": 1003, "crema": 1002, "morado": 104,
}

# Superficies empaquetadas: seis caras de 3 bits, en orden
# Top, Bottom, Front, Back, Left, Right.
STUDS = 1 + 2 * 8          # Top=Studs, Bottom=Inlet, resto liso
LISO = 0

ANCLADO_SOLIDO = 3         # anclado + con colision


def p(size, pos, color="gris", rot=(0, 0, 0), forma=0, sup=STUDS,
      material=0, transp=0, extras=None):
    """Una parte en el formato que guarda el Serializer."""
    return [forma, list(size), list(pos), list(rot), C.get(color, color),
            material, transp, 0, ANCLADO_SOLIDO, sup, extras]


def luz(brillo=2.0, alcance=22, rgb=(255, 240, 200)):
    return {"l": [0, brillo, alcance, rgb[0], rgb[1], rgb[2]]}


def cartel(texto, cara=0, rgb=(30, 30, 30)):
    return {"c": [cara, texto, rgb[0], rgb[1], rgb[2]]}


# ---------------------------------------------------------------------------
# Los mapas
# ---------------------------------------------------------------------------

def spawn(pos, color="blanco"):
    """Punto de aparicion. Todo mapa debe traer uno o apareces flotando."""
    return [6, [14, 1, 14], list(pos), [0, 0, 0], C[color], 0, 0, 0,
            ANCLADO_SOLIDO, LISO, None]


# ---------------------------------------------------------------------------
# Un obby recto y legible: desde cada plataforma se ve la siguiente.
# ---------------------------------------------------------------------------

def obby():
    partes = [p((30, 2, 30), (0, 1, -20), "blanco"), spawn((0, 3, -20))]

    z, y = 6, 2
    colores = ["azul", "verde", "amarillo", "naranja", "rojo", "morado"]

    for tramo in range(6):
        color = colores[tramo]

        for k in range(4):
            # Cada salto sube 3 y avanza 14: alcanzable de sobra con R6.
            y += 3
            z += 14
            ancho = 10 if k % 2 == 0 else 7
            desvio = 0 if k % 2 == 0 else (6 if tramo % 2 == 0 else -6)
            partes.append(p((ancho, 1.6, 8), (desvio, y, z), color))

        # Lava debajo del tramo, para que se vea lo que hay en juego.
        partes.append(p((44, 1, 62), (0, y - 14, z - 22), "rojo", sup=LISO,
                        material=12, extras=luz(1.2, 26, (255, 90, 70))))

        # Descanso con punto de aparicion propio.
        z += 16
        y += 2
        partes.append(p((20, 2, 20), (0, y, z), "verde"))
        partes.append(spawn((0, y + 1.5, z), "verde"))
        partes.append(p((1.4, 12, 1.4), (-8, y + 7, z), "verde", sup=LISO))
        partes.append(p((1.4, 12, 1.4), (8, y + 7, z), "verde", sup=LISO))
        partes.append(p((18, 1.4, 1.4), (0, y + 13, z), "verde", sup=LISO,
                        material=12, extras=luz(1.6, 18, (140, 255, 140))))

    z += 20
    partes.append(p((28, 2, 28), (0, y + 2, z), "blanco"))
    partes.append(p((7, 7, 7), (0, y + 7, z), "amarillo", forma=1, sup=LISO,
                    material=12, extras=luz(4, 40)))
    partes.append(p((24, 6, 1), (0, y + 15, z), "blanco", sup=LISO,
                    extras=cartel("FINISH")))

    return {
        "nombre": "Obby Course",
        "descripcion": "Six sections with a checkpoint after each, lava below. "
                       "Every jump is 3 up and 14 across, so R6 always reaches.",
        "partes": partes,
    }


# ---------------------------------------------------------------------------
# Arena simetrica: cuatro bases iguales, nadie sale ganando de salida.
# ---------------------------------------------------------------------------

def arena():
    partes = [p((160, 2, 160), (0, 1, 0), "gris")]

    for dx, dz, sx, sz in [(0, 80, 164, 4), (0, -80, 164, 4),
                           (80, 0, 4, 164), (-80, 0, 4, 164)]:
        partes.append(p((sx, 18, sz), (dx, 11, dz), "gris oscuro"))

    for i in range(-4, 5):
        for dz in (80, -80):
            partes.append(p((8, 4, 5), (i * 18, 22, dz), "gris"))
        for dx in (80, -80):
            partes.append(p((5, 4, 8), (dx, 22, i * 18), "gris"))

    esquinas = [(-1, -1, "azul"), (1, -1, "rojo"),
                (-1, 1, "verde"), (1, 1, "amarillo")]

    for sx, sz, color in esquinas:
        bx, bz = sx * 52, sz * 52
        partes.append(p((36, 4, 36), (bx, 4, bz), color))
        partes.append(p((14, 1, 14), (bx, 6.5, bz), color, forma=6, sup=LISO))
        partes.append(p((14, 20, 14), (bx, 16, bz - sz * 12), color))
        partes.append(p((18, 2, 18), (bx, 27, bz - sz * 12), "blanco"))
        partes.append(p((22, 6, 3), (bx, 9, bz - sz * 16), color))
        partes.append(p((3, 6, 22), (bx - sx * 16, 9, bz), color))

    # Centro elevado con una rampa por cada lado.
    partes.append(p((36, 4, 36), (0, 12, 0), "marron"))
    partes.append(p((6, 14, 6), (0, 7, 0), "marron"))
    for sx, sz in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
        partes.append(p((14 if sz else 26, 1.4, 26 if sz else 14),
                        (sx * 26, 7.5, sz * 26), "marron",
                        rot=(18 * sz, 0, -18 * sx)))
    partes.append(p((5, 5, 5), (0, 17, 0), "amarillo", forma=1, sup=LISO,
                    material=12, extras=luz(3, 34)))

    return {
        "nombre": "Four Corners Arena",
        "descripcion": "Four identical bases, a raised centre with a ramp from "
                       "every side, and battlements to hide behind.",
        "partes": partes,
    }


# ---------------------------------------------------------------------------
# Una casa en la que se entra de verdad: puerta, ventanas y dos cuartos.
# ---------------------------------------------------------------------------

def casa():
    partes = [p((120, 2, 120), (0, 1, 0), "verde oscuro"), spawn((0, 3, 44))]

    for i in range(5):
        partes.append(p((12, 1, 10), (0, 2.5, 36 - i * 10), "gris"))

    partes.append(p((72, 2, 56), (0, 3, 0), "gris oscuro"))
    partes.append(p((68, 1, 52), (0, 4.5, 0), "marron", sup=LISO))

    ALTO = 22
    Y = 4 + ALTO / 2

    partes.append(p((22, ALTO, 2), (-23, Y, 26), "crema", sup=LISO))
    partes.append(p((22, ALTO, 2), (23, Y, 26), "crema", sup=LISO))
    partes.append(p((68, 6, 2), (0, 4 + ALTO - 3, 26), "crema", sup=LISO))
    partes.append(p((68, ALTO, 2), (0, Y, -26), "crema", sup=LISO))
    partes.append(p((2, ALTO, 54), (-34, Y, 0), "crema", sup=LISO))
    partes.append(p((2, ALTO, 54), (34, Y, 0), "crema", sup=LISO))

    partes.append(p((2, ALTO, 20), (0, Y, -16), "crema", sup=LISO))
    partes.append(p((2, ALTO, 20), (0, Y, 16), "crema", sup=LISO))

    for x, z in [(-34, -14), (-34, 14), (34, -14), (34, 14)]:
        partes.append(p((0.6, 10, 12), (x, 14, z), "crema", sup=LISO, transp=55))

    partes.append(p((10, 16, 0.8), (0, 12, 26), "marron", sup=LISO))
    partes.append(p((1.4, 1.4, 1.4), (3.5, 12, 25.2), "amarillo", forma=1, sup=LISO))

    for i in range(7):
        w = 74 - i * 9
        partes.append(p((w, 2, 58), (0, 4 + ALTO + 1 + i * 2, 0), "burdeos", sup=LISO))
    partes.append(p((6, 10, 6), (-20, 4 + ALTO + 16, -14), "gris oscuro", sup=LISO))

    partes.append(p((14, 3, 8), (-18, 6, -8), "marron"))
    partes.append(p((10, 1.2, 6), (16, 6, 8), "marron"))
    partes.append(p((3, 3, 3), (0, 4 + ALTO - 4, 0), "amarillo", sup=LISO,
                    material=12, extras=luz(2.6, 34)))
    partes.append(p((20, 5, 1), (0, 4 + ALTO + 2, 27), "blanco", sup=LISO,
                    extras=cartel("HOME")))

    return {
        "nombre": "Cottage",
        "descripcion": "A house you can walk into: door, windows, two rooms "
                       "and a pitched roof.",
        "partes": partes,
    }


# ---------------------------------------------------------------------------
# Circuito ovalado con quitamiedos, meta y gradas.
# ---------------------------------------------------------------------------

def circuito():
    partes = [p((300, 2, 220), (0, 1, 0), "verde oscuro"), spawn((0, 3, 78))]

    RX, RZ, ANCHO, n = 108, 68, 22, 40

    for i in range(n):
        a = (i / n) * math.tau
        b = ((i + 1) / n) * math.tau
        x, z = math.cos(a) * RX, math.sin(a) * RZ
        x2, z2 = math.cos(b) * RX, math.sin(b) * RZ

        largo = math.sqrt((x2 - x) ** 2 + (z2 - z) ** 2) + 3
        giro = math.degrees(math.atan2(x2 - x, z2 - z))
        color = "gris oscuro" if i % 8 < 4 else "gris"

        partes.append(p((ANCHO, 1.4, largo), ((x + x2) / 2, 2.5, (z + z2) / 2),
                        color, rot=(0, giro, 0), sup=LISO))

        for lado in (1, -1):
            ox = math.cos(a) * (ANCHO / 2 + 1.5) * lado
            oz = math.sin(a) * (ANCHO / 2 + 1.5) * lado
            partes.append(p((1.2, 4, largo),
                            ((x + x2) / 2 + ox, 4.5, (z + z2) / 2 + oz),
                            "rojo" if i % 4 < 2 else "blanco",
                            rot=(0, giro, 0), sup=LISO))

    partes.append(p((ANCHO + 6, 1, 4), (RX, 3.4, 0), "blanco", sup=LISO))
    partes.append(p((2, 20, 2), (RX - 14, 12, 0), "blanco", sup=LISO))
    partes.append(p((2, 20, 2), (RX + 14, 12, 0), "blanco", sup=LISO))
    partes.append(p((30, 5, 1), (RX, 22, 0), "blanco", sup=LISO,
                    extras=cartel("START / FINISH")))

    for k in range(4):
        partes.append(p((60, 3, 10), (0, 3 + k * 3, 96 + k * 10), "gris"))

    return {
        "nombre": "Speedway",
        "descripcion": "An oval circuit with kerbs and barriers, a start line "
                       "and a small grandstand.",
        "partes": partes,
    }


MAPAS = [obby, arena, casa, circuito]


# ---------------------------------------------------------------------------
# Escritura en el DataStore
# ---------------------------------------------------------------------------

LUAU = """
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local creaciones = DataStoreService:GetDataStore("BygoneCreaciones_v1")
local deUsuario = DataStoreService:GetDataStore("BygoneDeUsuario_v1")
local recientes = DataStoreService:GetOrderedDataStore("BygoneRecientes_v1")

local lote = HttpService:JSONDecode([==[__DATOS__]==])
local ahora = os.time()
local hechos, errores = {}, {}

for _, mapa in ipairs(lote) do
	local id = mapa.id
	local meta = {
		id = id,
		nombre = mapa.nombre,
		descripcion = mapa.descripcion,
		duenoId = __USUARIO_ID__,
		dueno = "__USUARIO__",
		partes = #mapa.datos.partes,
		creado = ahora,
		actualizado = ahora,
		publicada = true,
		visitas = 0,
	}

	local ok, err = pcall(function ()
		creaciones:SetAsync(id, { meta = meta, datos = mapa.datos })
		recientes:SetAsync(id, ahora)
	end)

	if ok then
		table.insert(hechos, mapa.nombre .. " (" .. meta.partes .. " partes)")
	else
		errores[mapa.nombre] = tostring(err)
	end

	task.wait(1)
end

-- El indice del usuario se actualiza de una vez, sin pisar lo que ya tuviera.
pcall(function ()
	deUsuario:UpdateAsync("__USUARIO_ID__", function (lista)
		lista = lista or {}
		local vistos = {}
		for _, id in ipairs(lista) do vistos[id] = true end
		for _, mapa in ipairs(lote) do
			if not vistos[mapa.id] then
				table.insert(lista, mapa.id)
			end
		end
		return lista
	end)
end)

return { hechos = hechos, errores = errores }
"""


def peticion(url, clave, metodo="GET", cuerpo=None):
    d = json.dumps(cuerpo).encode() if cuerpo is not None else None
    req = urllib.request.Request(url, data=d, method=metodo)
    req.add_header("x-api-key", clave)
    if d:
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--universo", required=True)
    ap.add_argument("--place", required=True, help="placeId donde ejecutar (Studios)")
    args = ap.parse_args()

    clave = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not clave:
        ruta = os.path.join(HERE, "clave_open_cloud.txt")
        clave = open(ruta, encoding="utf-8").read().strip()

    lote = []
    for i, hacer in enumerate(MAPAS):
        m = hacer()
        lote.append({
            "id": "ejemplo%02d" % (i + 1),
            "nombre": m["nombre"],
            "descripcion": m["descripcion"],
            "datos": {"v": 2, "partes": m["partes"]},
        })
        print("  %-22s %4d partes" % (m["nombre"], len(m["partes"])))

    payload = json.dumps(lote, ensure_ascii=False).replace("]==]", "] ==]")
    print("\npeso del lote: %.0f KB" % (len(payload) / 1024))

    script = (LUAU.replace("__DATOS__", payload)
                  .replace("__USUARIO_ID__", str(USUARIO_ID))
                  .replace("__USUARIO__", USUARIO))

    url = ("%s/universes/%s/places/%s/luau-execution-session-tasks"
           % (BASE, args.universo, args.place))
    tarea = peticion(url, clave, "POST", {"script": script, "timeout": "180s"})

    ruta = tarea["path"]
    while tarea.get("state") in ("PROCESSING", "QUEUED", None):
        time.sleep(4)
        tarea = peticion("%s/%s" % (BASE, ruta), clave)

    if tarea.get("state") != "COMPLETE":
        print("\nLa tarea acabo en %s: %s"
              % (tarea.get("state"), json.dumps(tarea.get("error"))[:300]))
        return

    res = ((tarea.get("output") or {}).get("results") or [{}])[0]
    print("\nGuardados:")
    for h in res.get("hechos", []):
        print("   ", h)
    if res.get("errores"):
        print("Errores:", res["errores"])


if __name__ == "__main__":
    main()
