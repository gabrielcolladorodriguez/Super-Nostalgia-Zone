# -*- coding: utf-8 -*-
"""
Genera Hub/Lobby.model.json: el vestibulo de Bygone.

No es un mapa fijo: se construye a partir del catalogo. Cada juego recibe su
propio expositor en la sala, con el titulo, el autor y la etiqueta de
procedencia escritos en el panel. Asi el vestibulo crece o mengua solo cuando
cambia el catalogo, y nunca queda un hueco vacio ni un cartel mintiendo.

Cada expositor lleva una parte llamada "Portal" con un StringValue "Juego"
dentro; el script del hub la usa para saber a que lugar teletransportar.

Uso:  python generate_lobby.py
"""

import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
CATALOGO = os.path.join(os.path.expanduser("~"), "Desktop",
                        "Classic_Roblox_2008_Games", "catalogo_limpio.json")

BC = {
    "rojo": 21, "azul": 23, "amarillo": 24, "verde": 37, "naranja": 106,
    "verde oscuro": 28, "gris": 194, "gris oscuro": 199, "marron": 192,
    "blanco": 1001, "negro": 26, "burdeos": 1003,
}

BADGE = {
    "licencia":     ("MIT / OPEN SOURCE", [0.16, 0.44, 0.16]),
    "uncopylocked": ("UNCOPYLOCKED",      [0.16, 0.32, 0.56]),
    "oficial":      ("OFFICIAL ROBLOX",   [0.16, 0.44, 0.16]),
    "comunitario":  ("COMMUNITY ARCHIVE", [0.47, 0.36, 0.08]),
}

# Un color por categoria, para que la sala se lea de un vistazo.
COLOR_CATEGORIA = {
    "Brickbattle y combate": "rojo",
    "Obbies y parkour": "amarillo",
    "Desastres y fisica": "naranja",
    "Zombis y terror": "verde oscuro",
    "Vehiculos y tycoons": "azul",
    "Rol y ciudades": "verde",
    "Clasicos varios": "burdeos",
}


def part(name, size, pos, color="gris", top="Studs", bottom="Inlet",
         anchored=True, rot_y=0.0, classname="Part", extra=None, children=None):
    a = math.radians(rot_y)
    c, s = math.cos(a), math.sin(a)
    props = {
        "CFrame": [round(v, 5) for v in
                   [pos[0], pos[1], pos[2], c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c]],
        "Size": [round(v, 3) for v in size],
        "Anchored": anchored,
        "BrickColor": {"BrickColor": BC[color]},
        "TopSurface": top, "BottomSurface": bottom,
        "LeftSurface": "Smooth", "RightSurface": "Smooth",
        "FrontSurface": "Smooth", "BackSurface": "Smooth",
    }
    if extra:
        props.update(extra)
    node = {"Name": name, "ClassName": classname, "Properties": props}
    if children:
        node["Children"] = children
    return node


def label(name, texto, color, y, alto):
    return {
        "Name": name, "ClassName": "TextLabel",
        "Properties": {
            "BackgroundTransparency": 1,
            "Size": {"UDim2": [[1, 0], [alto, 0]]},
            "Position": {"UDim2": [[0, 0], [y, 0]]},
            "Font": "Cartoon", "TextScaled": True,
            "Text": texto, "TextColor3": color,
        },
    }


def panel_doble(textos):
    """Misma ficha en las dos caras: en Roblox "Front" mira hacia -Z."""
    return [{
        "Name": "Ficha" + face, "ClassName": "SurfaceGui",
        "Properties": {"Face": face, "SizingMode": "PixelsPerStud",
                       "PixelsPerStud": 50, "AlwaysOnTop": False},
        "Children": textos,
    } for face in ("Back", "Front")]


def construir(fichas):
    mundo = []

    # --- Suelo y sala -------------------------------------------------------
    mundo.append(part("Baseplate", (600, 20, 600), (0, -10, 0), "verde oscuro",
                      top="Studs", bottom="Smooth", extra={"Locked": True}))

    sala = [part("Floor", (240, 2, 240), (0, 1, 0), "gris")]
    for i, (dx, dz, sx, sz) in enumerate([(0, 121, 242, 4), (0, -121, 242, 4),
                                          (121, 0, 4, 242), (-121, 0, 4, 242)]):
        sala.append(part("Zocalo%d" % i, (sx, 6, sz), (dx, 3, dz), "gris oscuro"))
    sala.append(part("Alfombra", (64, 0.4, 64), (0, 2.2, 0), "burdeos",
                     top="Smooth", bottom="Smooth"))
    mundo.append({"Name": "Sala", "ClassName": "Model", "Children": sala})

    # --- Cartel de entrada --------------------------------------------------
    rotulo = [
        label("Titulo", "BYGONE", [0.1, 0.1, 0.1], 0.06, 0.48),
        label("Lema", "the classic ROBLOX places, as they were",
              [0.35, 0.35, 0.35], 0.60, 0.17),
        label("Cuenta", "%d games  -  every one open source or uncopylocked"
              % len(fichas), [0.42, 0.42, 0.42], 0.80, 0.13),
    ]
    mundo.append({"Name": "Cartel", "ClassName": "Model", "Children": [
        part("Poste1", (4, 34, 4), (-34, 18, -118), "marron"),
        part("Poste2", (4, 34, 4), (34, 18, -118), "marron"),
        part("Panel", (72, 20, 2), (0, 38, -118), "blanco",
             top="Smooth", bottom="Smooth", children=panel_doble(rotulo)),
    ]})

    # --- Un expositor por juego --------------------------------------------
    expositores = []
    n = max(len(fichas), 1)
    radio = max(56, 9.5 * n / math.pi)

    for i, ficha in enumerate(fichas):
        ang = (i / n) * math.tau - math.pi / 2
        x, z = math.cos(ang) * radio, math.sin(ang) * radio
        mirando = math.degrees(-ang) + 90          # el panel mira al centro

        color = COLOR_CATEGORIA.get(ficha.get("categoria"), "gris")
        etiqueta, tinte = BADGE.get(ficha.get("procedencia"),
                                    ("ARCHIVE", [0.4, 0.4, 0.4]))

        anio = (" - %s" % ficha["anio"]) if ficha.get("anio") else ""
        textos = [
            label("Nombre", ficha["titulo"][:44], [0.1, 0.1, 0.1], 0.04, 0.30),
            label("Autor", "by %s%s" % (ficha.get("creador") or "unknown", anio),
                  [0.35, 0.35, 0.35], 0.40, 0.15),
            label("Categoria", ficha.get("categoria", ""),
                  [0.45, 0.45, 0.45], 0.57, 0.12),
            label("Licencia", etiqueta, tinte, 0.75, 0.14),
        ]

        expositores.append({
            "Name": "Expositor%02d" % (i + 1), "ClassName": "Model",
            "Children": [
                part("Base", (16, 3, 10), (x, 2.5, z), "gris oscuro", rot_y=mirando),
                part("Portal", (12, 12, 2), (x, 10, z), color, rot_y=mirando,
                     children=[{"Name": "Juego", "ClassName": "StringValue",
                                "Properties": {"Value": ficha["titulo"]}}]),
                part("Panel", (16, 9, 1), (x, 21, z), "blanco", rot_y=mirando,
                     top="Smooth", bottom="Smooth", children=panel_doble(textos)),
                part("Techo", (18, 1, 12), (x, 26.5, z), color, rot_y=mirando,
                     top="Smooth", bottom="Smooth"),
            ],
        })

    mundo.append({"Name": "Expositores", "ClassName": "Model",
                  "Children": expositores})

    mundo.append(part("SpawnLocation", (18, 1, 18), (0, 2.7, 0), "blanco",
                      classname="SpawnLocation", top="Smooth", bottom="Smooth",
                      extra={"Neutral": True, "Duration": 0}))

    # --- Faroles, para que la sala no sea un plano gris ---------------------
    faroles = []
    for i in range(8):
        ang = (i / 8) * math.tau
        x, z = math.cos(ang) * 32, math.sin(ang) * 32
        faroles.append(part("Poste%d" % i, (2, 18, 2), (x, 11, z), "gris oscuro"))
        faroles.append(part("Luz%d" % i, (4, 2, 4), (x, 21, z), "amarillo",
                            top="Smooth", bottom="Smooth",
                            extra={"Material": "Neon"},
                            children=[{
                                "Name": "PointLight", "ClassName": "PointLight",
                                "Properties": {"Brightness": 1.4, "Range": 34,
                                               "Color": [1, 0.96, 0.83]},
                            }]))
    mundo.append({"Name": "Faroles", "ClassName": "Model", "Children": faroles})

    mundo.append({"Name": "GameMusic", "ClassName": "Sound",
                  "Properties": {"SoundId": "", "Looped": True, "Volume": 0.35}})

    return mundo


def main():
    with open(CATALOGO, encoding="utf-8") as f:
        fichas = json.load(f)

    salida = {"ClassName": "Folder", "Properties": {},
              "Children": construir(fichas)}

    ruta = os.path.join(HERE, "Lobby.model.json")
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(salida, f, indent="\t")

    print("Vestibulo generado para %d juegos -> %s" % (len(fichas), ruta))


if __name__ == "__main__":
    main()
