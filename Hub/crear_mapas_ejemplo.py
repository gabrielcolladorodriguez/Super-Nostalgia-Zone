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

def obby_clasico():
    partes = [p((60, 2, 60), (0, 1, -70), "verde oscuro")]

    # Escalones que suben girando, con lava debajo
    x, y, z = 0, 4, -30
    for i in range(18):
        color = ["azul", "verde", "amarillo", "naranja", "rojo"][i % 5]
        ancho = 8 if i % 4 else 14
        partes.append(p((ancho, 1.6, 8), (x, y, z), color))

        if i % 5 == 4:
            partes.append(p((26, 1, 26), (x, y - 8, z), "rojo", sup=LISO,
                            material=12, extras=luz(1.4, 20, (255, 90, 70))))

        ang = i * 0.42
        x += math.cos(ang) * 16
        z += math.sin(ang) * 12 + 10
        y += 3.2

    # Meta
    partes.append(p((24, 2, 24), (x, y, z), "blanco"))
    partes.append(p((6, 6, 6), (x, y + 5, z), "amarillo", forma=1, sup=LISO,
                    material=12, extras=luz(4, 34)))
    partes.append(p((20, 6, 1), (x, y + 12, z), "blanco", sup=LISO,
                    extras=cartel("FINISH")))

    return {
        "nombre": "Classic Obby",
        "descripcion": "Eighteen jumps over lava, the way obbies were in 2008.",
        "partes": partes,
    }


def arena_brickbattle():
    partes = [p((120, 2, 120), (0, 1, 0), "gris")]

    # Muro perimetral
    for dx, dz, sx, sz in [(0, 60, 120, 3), (0, -60, 120, 3),
                           (60, 0, 3, 120), (-60, 0, 3, 120)]:
        partes.append(p((sx, 14, sz), (dx, 8, dz), "gris oscuro"))

    # Dos torres enfrentadas
    for lado, color in ((1, "azul"), (-1, "rojo")):
        z = 38 * lado
        partes.append(p((28, 3, 28), (0, 3, z), color))
        for i in range(3):
            w = 22 - i * 5
            partes.append(p((w, 8, w), (0, 8 + i * 8, z), color))
        partes.append(p((12, 1, 12), (0, 33, z), "blanco", forma=6, sup=LISO))
        partes.append(p((2, 14, 2), (0, 40, z), "negro", sup=LISO))
        partes.append(p((1, 8, 12), (0, 44, z + 6), color, sup=LISO))

    # Cobertura repartida
    for i in range(12):
        a = (i / 12) * math.tau
        x, z = math.cos(a) * 34, math.sin(a) * 24
        partes.append(p((10, 7, 4), (x, 5.5, z),
                        ["amarillo", "naranja", "verde", "morado"][i % 4],
                        rot=(0, math.degrees(a), 0)))

    # Puente central
    partes.append(p((14, 2, 60), (0, 14, 0), "marron"))
    for lado in (-1, 1):
        partes.append(p((1, 5, 60), (6.5 * lado, 17, 0), "amarillo", sup=LISO))
    for i in range(4):
        partes.append(p((4, 12, 4), (0, 7, -22 + i * 15), "marron"))

    return {
        "nombre": "Brickbattle Arena",
        "descripcion": "Two towers, a bridge and plenty of cover. Bring a sword.",
        "partes": partes,
    }


def torre_de_studs():
    partes = [p((70, 2, 70), (0, 1, 0), "verde oscuro")]

    colores = ["azul", "verde", "amarillo", "naranja", "rojo", "morado"]
    for piso in range(14):
        color = colores[piso % len(colores)]
        w = 46 - piso * 2.6
        y = 4 + piso * 9

        partes.append(p((w, 2, w), (0, y, 0), color))
        # Cuatro pilares por piso
        for sx in (-1, 1):
            for sz in (-1, 1):
                partes.append(p((3, 7, 3), (sx * (w / 2 - 3), y + 4.5,
                                            sz * (w / 2 - 3)), "blanco"))
        # Rampa al siguiente
        partes.append(p((7, 1.4, 14), (w / 4, y + 4, -w / 4), color,
                        rot=(-18, piso * 26, 0)))

    cima = 4 + 14 * 9
    partes.append(p((10, 10, 10), (0, cima + 6, 0), "amarillo", forma=1,
                    sup=LISO, material=12, extras=luz(5, 50)))
    partes.append(p((22, 6, 1), (0, cima + 14, 0), "blanco", sup=LISO,
                    extras=cartel("TOP OF THE TOWER")))

    return {
        "nombre": "Tower of Studs",
        "descripcion": "Fourteen floors up a ramp tower. No lava, just height.",
        "partes": partes,
    }


def plaza_del_pueblo():
    partes = [p((160, 2, 160), (0, 1, 0), "verde oscuro")]

    # Calle empedrada
    for i in range(-4, 5):
        for j in range(-4, 5):
            col = "gris" if (i + j) % 2 == 0 else "gris oscuro"
            partes.append(p((16, 1, 16), (i * 16, 2.5, j * 16), col))

    # Cuatro casas alrededor
    casas = [(-52, -52, "crema", "burdeos"), (52, -52, "amarillo", "marron"),
             (-52, 52, "azul", "gris oscuro"), (52, 52, "verde", "marron")]

    for k, (cx, cz, muro, techo) in enumerate(casas):
        partes.append(p((30, 18, 26), (cx, 12, cz), muro, sup=LISO))
        partes.append(p((34, 3, 30), (cx, 22, cz), techo, sup=LISO))
        partes.append(p((36, 2, 8), (cx, 24, cz), techo, rot=(30, 0, 0), sup=LISO))
        # Puerta y ventanas
        partes.append(p((7, 11, 1), (cx, 8.5, cz - 13.2), "marron", sup=LISO))
        for sx in (-1, 1):
            partes.append(p((6, 6, 1), (cx + sx * 10, 14, cz - 13.2), "crema",
                            sup=LISO, transp=45))
        partes.append(p((26, 5, 1), (cx, 26, cz - 15), "blanco", sup=LISO,
                        extras=cartel(["Bakery", "Post Office",
                                       "Town Hall", "Toy Shop"][k])))

    # Fuente central
    partes.append(p((26, 3, 26), (0, 3.5, 0), "gris oscuro"))
    partes.append(p((20, 2, 20), (0, 5, 0), "azul", sup=LISO, transp=35))
    partes.append(p((5, 12, 5), (0, 10, 0), "blanco", forma=2, sup=LISO))
    partes.append(p((9, 9, 9), (0, 18, 0), "azul", forma=1, sup=LISO,
                    transp=30, extras=luz(2.5, 26, (150, 200, 255))))

    # Farolas
    for i in range(8):
        a = (i / 8) * math.tau
        x, z = math.cos(a) * 42, math.sin(a) * 42
        partes.append(p((3, 2, 3), (x, 3.5, z), "negro"))
        partes.append(p((1.4, 16, 1.4), (x, 11, z), "negro", sup=LISO))
        partes.append(p((3.4, 3.4, 3.4), (x, 20, z), "amarillo", sup=LISO,
                        material=12, extras=luz(2.2, 26)))

    return {
        "nombre": "Town Square",
        "descripcion": "Four shops, a fountain and cobbles. A place to hang around.",
        "partes": partes,
    }


MAPAS = [obby_clasico, arena_brickbattle, torre_de_studs, plaza_del_pueblo]


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
