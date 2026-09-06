# -*- coding: utf-8 -*-
"""Genera Hub/Lobby.model.json: el vestibulo del hub, estilo 2008."""

import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

BC = {
    "Bright red": 21, "Bright blue": 23, "Bright yellow": 24,
    "Bright green": 37, "Bright orange": 106, "Dark green": 28,
    "Medium stone grey": 194, "Dark stone grey": 199,
    "Reddish brown": 192, "Institutional white": 1001,
    "Really black": 26, "White": 1,
}
PALETTE = ["Bright red", "Bright yellow", "Bright green", "Bright blue",
           "Bright orange", "Institutional white"]


def part(name, size, pos, color="Medium stone grey", top="Studs", bottom="Inlet",
         anchored=True, rot_y=0.0, classname="Part", extra=None, children=None):
    a = math.radians(rot_y)
    c, s = math.cos(a), math.sin(a)
    props = {
        "CFrame": [round(v, 6) for v in
                   [pos[0], pos[1], pos[2], c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c]],
        "Size": list(size),
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


world = []

# Suelo
world.append(part("Baseplate", (400, 20, 400), (0, -10, 0), "Dark green",
                  top="Studs", bottom="Smooth", extra={"Locked": True}))

# Plaza circular del vestibulo
plaza = [part("Floor", (160, 2, 160), (0, 1, 0), "Medium stone grey")]
for i, (dx, dz, sx, sz) in enumerate([(0, 81, 162, 4), (0, -81, 162, 4),
                                      (81, 0, 4, 162), (-81, 0, 4, 162)]):
    plaza.append(part("Curb%d" % i, (sx, 3, sz), (dx, 1.5, dz), "Dark stone grey"))
world.append({"Name": "Plaza", "ClassName": "Model", "Children": plaza})

# Cartel grande
sign = []
sign.append(part("Post1", (4, 30, 4), (-26, 16, -60), "Reddish brown"))
sign.append(part("Post2", (4, 30, 4), (26, 16, -60), "Reddish brown"))
# El cartel lleva el nombre por las dos caras: en Roblox la cara "Front" de
# una parte mira hacia -Z, asi que la que da a la plaza es "Back".
def rotulo(face):
    return {
        "Name": "Rotulo" + face, "ClassName": "SurfaceGui",
        "Properties": {"Face": face, "SizingMode": "PixelsPerStud",
                       "PixelsPerStud": 50, "AlwaysOnTop": False},
        "Children": [
            {"Name": "Titulo", "ClassName": "TextLabel", "Properties": {
                "BackgroundTransparency": 1,
                "Size": {"UDim2": [[1, 0], [0.62, 0]]},
                "Position": {"UDim2": [[0, 0], [0.04, 0]]},
                "Font": "Cartoon", "TextScaled": True, "Text": "BYGONE",
                "TextColor3": [0.11, 0.11, 0.11]}},
            {"Name": "Lema", "ClassName": "TextLabel", "Properties": {
                "BackgroundTransparency": 1,
                "Size": {"UDim2": [[1, 0], [0.24, 0]]},
                "Position": {"UDim2": [[0, 0], [0.68, 0]]},
                "Font": "Cartoon", "TextScaled": True,
                "Text": "los clasicos de 2006-2010, tal y como eran",
                "TextColor3": [0.36, 0.36, 0.36]}},
        ],
    }

sign.append(part("Board", (60, 16, 2), (0, 34, -60), "Institutional white",
                 top="Smooth", bottom="Smooth",
                 children=[rotulo("Back"), rotulo("Front")]))
for i, c in enumerate(PALETTE):
    sign.append(part("Stripe%d" % i, (10, 3, 2.4), (-25 + i * 10, 24, -60), c,
                     top="Smooth", bottom="Smooth"))
world.append({"Name": "Cartel", "ClassName": "Model", "Children": sign})

# Kiosco del menu: al acercarse sale el aviso para elegir juego.
kiosk = [
    # El menu localiza este kiosco por su nombre (rojo no escribe atributos
    # desde .model.json).
    part("KioscoDeJuegos", (10, 10, 6), (0, 6, 20), "Bright yellow"),
    part("KioscoBase", (14, 2, 10), (0, 2, 20), "Dark stone grey"),
    part("KioscoTecho", (14, 1, 10), (0, 11.5, 20), "Bright red",
         top="Smooth", bottom="Smooth"),
]
world.append({"Name": "Kiosco", "ClassName": "Model", "Children": kiosk})

# Aparicion
world.append(part("SpawnLocation", (16, 1, 16), (0, 2.5, 0), "Institutional white",
                  classname="SpawnLocation", top="Smooth", bottom="Smooth",
                  extra={"Neutral": True, "Duration": 0}))

# Un anillo de pilares de colores, puro adorno de la epoca
ring = []
for i in range(12):
    ang = (i / 12.0) * math.tau
    x, z = math.cos(ang) * 66, math.sin(ang) * 66
    ring.append(part("Pillar%d" % i, (5, 20, 5), (x, 12, z), PALETTE[i % len(PALETTE)]))
    ring.append(part("Cap%d" % i, (7, 2, 7), (x, 23, z), "Institutional white"))
world.append({"Name": "Pilares", "ClassName": "Model", "Children": ring})

world.append({"Name": "GameMusic", "ClassName": "Sound",
              "Properties": {"SoundId": "", "Looped": True, "Volume": 0.35}})

out = {"ClassName": "Folder", "Properties": {}, "Children": world}
path = os.path.join(HERE, "Lobby.model.json")
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent="\t")
print("OK ->", path)
