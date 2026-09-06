# -*- coding: utf-8 -*-
"""
Genera Local/Map.model.json : un mapa sandbox estilo ROBLOX 2008
compatible con los scripts de Super Nostalgia Zone (Parts.server.lua
convierte superficies/colores al look clasico automaticamente).
"""
import json, os, math

HERE = os.path.dirname(os.path.abspath(__file__))

BC = {
    "Bright red": 21, "Bright blue": 23, "Bright yellow": 24,
    "Bright green": 37, "Bright orange": 106, "Dark green": 28,
    "Medium stone grey": 194, "Dark stone grey": 199,
    "Reddish brown": 192, "Institutional white": 1001,
    "Really black": 26, "White": 1,
}

def bc(name):
    return {"BrickColor": BC[name]}


def part(name, size, pos, color="Medium stone grey", top="Studs", bottom="Inlet",
         left="Smooth", right="Smooth", front="Smooth", back="Smooth",
         anchored=True, transparency=0.0, shape=None, children=None, rot_y=0.0,
         classname="Part", extra=None):
    """rot_y en grados, rotacion sobre el eje Y."""
    a = math.radians(rot_y)
    c, s = math.cos(a), math.sin(a)
    cf = [pos[0], pos[1], pos[2],
          c, 0.0, s,
          0.0, 1.0, 0.0,
          -s, 0.0, c]
    props = {
        "CFrame": [round(v, 6) for v in cf],
        "Size": list(size),
        "Anchored": anchored,
        "BrickColor": bc(color),
        "TopSurface": top,
        "BottomSurface": bottom,
        "LeftSurface": left,
        "RightSurface": right,
        "FrontSurface": front,
        "BackSurface": back,
    }
    if transparency:
        props["Transparency"] = transparency
    if shape:
        props["Shape"] = shape
    if extra:
        props.update(extra)
    node = {"Name": name, "ClassName": classname, "Properties": props}
    if children:
        node["Children"] = children
    return node

def model(name, children):
    return {"Name": name, "ClassName": "Model", "Children": children}

def folder(name, children):
    return {"Name": name, "ClassName": "Folder", "Children": children}

# ----------------------------------------------------------------------------
world = []

# --- Baseplate clasico -------------------------------------------------------
world.append(part("Baseplate", (512, 20, 512), (0, -10, 0), "Dark green",
                  top="Studs", bottom="Smooth",
                  left="Smooth", right="Smooth", front="Smooth", back="Smooth",
                  extra={"Locked": True}))

# --- Plaza central -----------------------------------------------------------
plaza = []
plaza.append(part("Floor", (120, 2, 120), (0, 1, 0), "Medium stone grey"))
# borde
for i, (dx, dz, sx, sz) in enumerate([(0, 61, 122, 4), (0, -61, 122, 4),
                                      (61, 0, 4, 122), (-61, 0, 4, 122)]):
    plaza.append(part("Curb%d" % i, (sx, 3, sz), (dx, 1.5, dz), "Dark stone grey"))
# pilares decorativos
for i, (dx, dz) in enumerate([(50, 50), (-50, 50), (50, -50), (-50, -50)]):
    plaza.append(part("Pillar%d" % i, (6, 24, 6), (dx, 14, dz), "Institutional white"))
    plaza.append(part("PillarCap%d" % i, (8, 2, 8), (dx, 27, dz), "Bright yellow"))
world.append(model("Plaza", plaza))

# --- Bases de equipo ---------------------------------------------------------
def make_base(team, color, z_sign):
    z = 170 * z_sign
    kids = []
    kids.append(part("Platform", (80, 4, 80), (0, 6, z), color))
    kids.append(part("Ramp", (24, 4, 60), (0, 3.4, z - 68 * z_sign), color,
                     extra={"CFrame": None}))
    # rampa inclinada (rotacion en X) -> se define aparte abajo
    kids.pop()
    # muros
    kids.append(part("WallL", (4, 16, 80), (-38, 16, z), "Dark stone grey"))
    kids.append(part("WallR", (4, 16, 80), (38, 16, z), "Dark stone grey"))
    kids.append(part("WallBack", (80, 16, 4), (0, 16, z + 38 * z_sign), "Dark stone grey"))
    # torre
    kids.append(part("Tower", (16, 40, 16), (0, 28, z + 20 * z_sign), color))
    kids.append(part("TowerTop", (22, 3, 22), (0, 49.5, z + 20 * z_sign), "Institutional white"))
    # spawn
    kids.append(part("Spawn", (12, 1, 12), (0, 8.5, z - 20 * z_sign), color,
                     classname="SpawnLocation", top="Smooth", bottom="Smooth",
                     extra={"TeamColor": bc(color), "Neutral": False,
                            "Duration": 0, "AllowTeamChangeOnTouch": True}))
    return model("Base" + team, kids)

world.append(make_base("Red", "Bright red", 1))
world.append(make_base("Blue", "Bright blue", -1))

# --- Rampas de acceso (inclinadas) -------------------------------------------
def ramp(name, size, pos, color, pitch_deg, z_sign=1):
    a = math.radians(pitch_deg * z_sign)
    c, s = math.cos(a), math.sin(a)
    cf = [pos[0], pos[1], pos[2],
          1.0, 0.0, 0.0,
          0.0, c, -s,
          0.0, s, c]
    return {"Name": name, "ClassName": "Part", "Properties": {
        "CFrame": [round(v, 6) for v in cf],
        "Size": list(size), "Anchored": True, "BrickColor": bc(color),
        "TopSurface": "Studs", "BottomSurface": "Inlet",
        "LeftSurface": "Smooth", "RightSurface": "Smooth",
        "FrontSurface": "Smooth", "BackSurface": "Smooth"}}

ramps = []
ramps.append(ramp("RampRed", (28, 2, 60), (0, 4.5, 100), "Bright red", 8, 1))
ramps.append(ramp("RampBlue", (28, 2, 60), (0, 4.5, -100), "Bright blue", 8, -1))
world.append(model("Ramps", ramps))

# --- Puentes laterales -------------------------------------------------------
bridges = []
for i, x in enumerate((-90, 90)):
    bridges.append(part("BridgeDeck%d" % i, (14, 2, 260), (x, 12, 0), "Reddish brown"))
    for j, z in enumerate(range(-120, 121, 60)):
        bridges.append(part("Pier%d_%d" % (i, j), (6, 24, 6), (x, 0, z), "Reddish brown"))
    bridges.append(part("Rail%dA" % i, (1, 4, 260), (x - 6.5, 15, 0), "Bright yellow"))
    bridges.append(part("Rail%dB" % i, (1, 4, 260), (x + 6.5, 15, 0), "Bright yellow"))
world.append(model("Bridges", bridges))

# --- Obstaculos / cobertura --------------------------------------------------
cover = []
palette = ["Bright yellow", "Bright orange", "Bright green", "Institutional white",
           "Bright red", "Bright blue", "Reddish brown", "Dark stone grey"]
spots = [(-40, 30), (40, 30), (-40, -30), (40, -30), (0, 40), (0, -40),
         (-25, 0), (25, 0), (-55, 20), (55, -20)]
for i, (x, z) in enumerate(spots):
    cover.append(part("Cover%d" % i, (10, 8, 4), (x, 6, z), palette[i % len(palette)],
                      rot_y=(i * 37) % 360))
world.append(model("Cover", cover))

# --- Torre central regenerable ----------------------------------------------
tower = []
for i in range(8):
    y = 4 + i * 6
    w = 26 - i * 2
    tower.append(part("Tier%d" % i, (w, 6, w), (0, y, 0), palette[i % len(palette)]))
tower.append(part("Flag", (2, 16, 2), (0, 60, 0), "Really black"))
tower.append(part("Banner", (1, 8, 12), (0, 60, 6.5), "Bright red"))
world.append(model("CentralTower", tower))

# --- Pila de ladrillos sueltos (para Trowel / Dragger) -----------------------
loose = []
for i in range(24):
    ang = i * 0.7
    r = 26 + (i % 5) * 3
    loose.append(part("Brick%d" % i, (4, 2, 8),
                      (math.cos(ang) * r + 100, 3 + (i % 4) * 2.2, math.sin(ang) * r + 100),
                      palette[i % len(palette)], anchored=False, rot_y=(i * 23) % 360))
world.append(model("LooseBricks", loose))

# --- Musica de fondo clasica (opcional, desactivada por defecto) -------------
world.append({"Name": "GameMusic", "ClassName": "Sound", "Properties": {
    "SoundId": "", "Looped": True, "Volume": 0.35}})

# ----------------------------------------------------------------------------
out = {"ClassName": "Folder", "Properties": {}, "Children": world}
path = os.path.join(HERE, "Map.model.json")
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent="\t")
print("OK ->", path, len(json.dumps(out)), "bytes")
