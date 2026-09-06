# -*- coding: utf-8 -*-
"""
Genera Hub/Lobby.model.json: el vestibulo de Bygone.

Deliberadamente pequeno y sobrio. Las versiones anteriores tenian portales de
neon, farolas, bancos, jardineras y un parkour dando vueltas, todo compitiendo
por la atencion; el resultado era un caos. Y ademas sobraba: el vestibulo no
tiene que entretener a nadie, solo tiene que ser un sitio tranquilo donde caer
mientras se abre el menu, que es donde esta todo.

Asi que aqui hay lo justo:

  - una plataforma cuadrada con borde
  - cuatro columnas que enmarcan el espacio
  - un rotulo con el nombre
  - luz suave desde las columnas

Nada mas. Queda sitio de sobra para construir encima lo que quieras.

Uso:  python generate_lobby.py
"""

import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

BC = {
    "crema": 1002, "piedra": 194, "piedra oscura": 199, "madera": 192,
    "burdeos": 1003, "blanco": 1001, "cesped": 28, "laton": 24,
}


def part(name, size, pos, color="piedra", top="Studs", bottom="Inlet",
         classname="Part", extra=None, children=None, mat=None):
    props = {
        "CFrame": [round(v, 5) for v in
                   [pos[0], pos[1], pos[2], 1., 0., 0., 0., 1., 0., 0., 0., 1.]],
        "Size": [round(v, 3) for v in size],
        "Anchored": True,
        "BrickColor": {"BrickColor": BC[color]},
        "TopSurface": top, "BottomSurface": bottom,
        "LeftSurface": "Smooth", "RightSurface": "Smooth",
        "FrontSurface": "Smooth", "BackSurface": "Smooth",
    }
    if mat:
        props["Material"] = mat
    if extra:
        props.update(extra)
    node = {"Name": name, "ClassName": classname, "Properties": props}
    if children:
        node["Children"] = children
    return node


def label(name, texto, color, y, alto):
    return {"Name": name, "ClassName": "TextLabel", "Properties": {
        "BackgroundTransparency": 1,
        "Size": {"UDim2": [[1, 0], [alto, 0]]},
        "Position": {"UDim2": [[0, 0], [y, 0]]},
        "Font": "Cartoon", "TextScaled": True,
        "Text": texto, "TextColor3": color}}


def panel(textos, caras=("Front", "Back")):
    return [{"Name": "Ficha" + f, "ClassName": "SurfaceGui", "Properties": {
        "Face": f, "SizingMode": "PixelsPerStud", "PixelsPerStud": 50,
        "AlwaysOnTop": False}, "Children": textos} for f in caras]


def luz(brillo=1.6, alcance=34):
    return {"Name": "PointLight", "ClassName": "PointLight", "Properties": {
        "Brightness": brillo, "Range": alcance, "Color": [1, 0.95, 0.85]}}


def construir():
    M = []

    # Terreno amplio: deja sitio si algun dia quieres construir alrededor.
    M.append(part("Baseplate", (1024, 20, 1024), (0, -10, 0), "cesped",
                  top="Studs", bottom="Smooth", extra={"Locked": True}))

    # La plataforma: 88 de lado, con borde de piedra oscura y alfombra al centro.
    M.append({"Name": "Plataforma", "ClassName": "Model", "Children": [
        part("Borde", (96, 3, 96), (0, 1.5, 0), "piedra oscura"),
        part("Suelo", (88, 2, 88), (0, 3, 0), "piedra"),
        part("Alfombra", (34, 0.4, 34), (0, 4.2, 0), "burdeos",
             top="Smooth", bottom="Smooth"),
    ]})

    # Cuatro columnas en las esquinas. Enmarcan sin cerrar.
    columnas = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        x, z = sx * 36, sz * 36
        columnas.append(part("Basa%d" % i, (11, 3, 11), (x, 5.5, z), "piedra oscura"))
        columnas.append(part("Fuste%d" % i, (8, 30, 8), (x, 22, z), "blanco",
                             top="Smooth", bottom="Smooth"))
        columnas.append(part("Capitel%d" % i, (12, 3, 12), (x, 38.5, z), "madera",
                             top="Smooth", bottom="Smooth"))
        columnas.append(part("Aplique%d" % i, (3, 3, 3),
                             (x - sx * 6, 30, z - sz * 6), "laton",
                             top="Smooth", bottom="Smooth", mat="Neon",
                             children=[luz()]))
    M.append({"Name": "Columnas", "ClassName": "Model", "Children": columnas})

    # El rotulo, al fondo.
    M.append({"Name": "Rotulo", "ClassName": "Model", "Children": [
        part("Poste1", (4, 26, 4), (-22, 17, -44), "madera"),
        part("Poste2", (4, 26, 4), (22, 17, -44), "madera"),
        part("Panel", (48, 16, 1.5), (0, 34, -44), "crema",
             top="Smooth", bottom="Smooth",
             children=panel([
                 label("Titulo", "BYGONE", [0.13, 0.13, 0.13], 0.08, 0.44),
                 label("Lema", "build classic ROBLOX places",
                       [0.38, 0.38, 0.38], 0.56, 0.16),
                 label("Sub", "press the MENU button below",
                       [0.48, 0.48, 0.48], 0.76, 0.13),
             ], caras=("Back",))),
    ]})

    # Aparicion invisible, en el centro de la alfombra.
    M.append(part("SpawnLocation", (14, 1, 14), (0, 4.5, 8), "blanco",
                  classname="SpawnLocation", top="Smooth", bottom="Smooth",
                  extra={"Transparency": 1, "CanCollide": False,
                         "Neutral": True, "Duration": 0}))

    M.append({"Name": "GameMusic", "ClassName": "Sound",
              "Properties": {"SoundId": "", "Looped": True, "Volume": 0.3}})

    return M


def main():
    mundo = construir()
    salida = {"ClassName": "Folder", "Properties": {}, "Children": mundo}

    ruta = os.path.join(HERE, "Lobby.model.json")
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(salida, f, indent="\t")

    texto = json.dumps(salida)
    print("Vestibulo sencillo: %d partes -> %s"
          % (texto.count('"ClassName": "Part"'), ruta))


if __name__ == "__main__":
    main()
