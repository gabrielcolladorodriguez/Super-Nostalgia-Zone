# -*- coding: utf-8 -*-
"""
Genera Hub/Lobby.model.json: el vestibulo de Bygone.

Tres zonas:

  la plaza     sala cerrada con suelo de damero, muros con columnas, farolas,
               bancos y jardineras. Aqui apareces.
  los portales BUILD y PLAY, grandes y con neon, en la cara norte.
  el parkour   un circuito de 24 obstaculos que sube en espiral alrededor de la
               plaza hasta un mirador. Con puntos de control, lava, saltos de
               fe y escaleras de andamio, como los obbies de 2008.

El punto de aparicion es invisible a proposito: una losa transparente y sin
colision. Apareces de pie sobre el damero, no encima de un cuadrado blanco.

Uso:  python generate_lobby.py
"""

import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

BC = {
    "rojo": 21, "azul": 23, "amarillo": 24, "verde": 37, "naranja": 106,
    "verde oscuro": 28, "gris": 194, "gris oscuro": 199, "marron": 192,
    "blanco": 1001, "negro": 26, "burdeos": 1003, "crema": 1002,
    "morado": 104, "turquesa": 1018, "rosa": 1032,
}

# Los obstaculos van rotando de color para que se lea la progresion.
RUTA = ["azul", "verde", "amarillo", "naranja", "rojo", "morado", "turquesa"]


def part(name, size, pos, color="gris", top="Studs", bottom="Inlet", rot_y=0.0,
         classname="Part", extra=None, children=None, mat=None):
    a = math.radians(rot_y)
    c, s = math.cos(a), math.sin(a)
    props = {
        "CFrame": [round(v, 5) for v in
                   [pos[0], pos[1], pos[2], c, 0., s, 0., 1., 0., -s, 0., c]],
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


def panel(textos):
    """La misma ficha por las dos caras: en Roblox Front mira hacia -Z."""
    return [{"Name": "Ficha" + f, "ClassName": "SurfaceGui", "Properties": {
        "Face": f, "SizingMode": "PixelsPerStud", "PixelsPerStud": 50,
        "AlwaysOnTop": False}, "Children": textos} for f in ("Back", "Front")]


def luz(brillo=2.2, alcance=40, color=(1, 0.94, 0.8)):
    return {"Name": "PointLight", "ClassName": "PointLight", "Properties": {
        "Brightness": brillo, "Range": alcance, "Color": list(color)}}


# ---------------------------------------------------------------------------
# La plaza
# ---------------------------------------------------------------------------

def plaza():
    M = []

    suelo = []
    paso = 20
    for i in range(-5, 5):
        for j in range(-5, 5):
            col = "gris" if (i + j) % 2 == 0 else "gris oscuro"
            suelo.append(part("Baldosa%d_%d" % (i, j), (paso, 2, paso),
                              (i * paso + paso / 2, 1, j * paso + paso / 2), col))
    M.append({"Name": "Suelo", "ClassName": "Model", "Children": suelo})

    muros = []
    L = 100
    for i, (dx, dz, sx, sz) in enumerate([(0, L, 2 * L + 8, 4), (0, -L, 2 * L + 8, 4),
                                          (L, 0, 4, 2 * L + 8), (-L, 0, 4, 2 * L + 8)]):
        muros.append(part("Muro%d" % i, (sx, 26, sz), (dx, 15, dz), "crema",
                          top="Smooth", bottom="Smooth"))
        muros.append(part("Cornisa%d" % i, (sx + 4, 3, sz + 4), (dx, 29, dz),
                          "marron", top="Smooth", bottom="Smooth"))

    for i, (x, z) in enumerate([(L, L), (L, -L), (-L, L), (-L, -L),
                                (0, L), (0, -L), (L, 0), (-L, 0)]):
        muros.append(part("Columna%d" % i, (8, 32, 8), (x, 17, z), "blanco",
                          top="Smooth", bottom="Smooth"))
        muros.append(part("Capitel%d" % i, (11, 3, 11), (x, 34, z), "marron",
                          top="Smooth", bottom="Smooth"))
    M.append({"Name": "Muros", "ClassName": "Model", "Children": muros})

    M.append({"Name": "Alfombra", "ClassName": "Model", "Children": [
        part("Borde", (58, 0.3, 58), (0, 2.2, 0), "amarillo",
             top="Smooth", bottom="Smooth"),
        part("Roja", (52, 0.4, 52), (0, 2.3, 0), "burdeos",
             top="Smooth", bottom="Smooth"),
    ]})

    faroles = []
    for i in range(12):
        a = (i / 12) * math.tau
        x, z = math.cos(a) * 76, math.sin(a) * 76
        faroles.append(part("Pie%d" % i, (4, 2, 4), (x, 3, z), "negro", top="Smooth"))
        faroles.append(part("Poste%d" % i, (1.6, 20, 1.6), (x, 13, z), "negro",
                            top="Smooth", bottom="Smooth"))
        faroles.append(part("Fanal%d" % i, (4, 4, 4), (x, 24, z), "amarillo",
                            top="Smooth", bottom="Smooth", mat="Neon",
                            children=[luz(2.4, 32)]))
    M.append({"Name": "Faroles", "ClassName": "Model", "Children": faroles})

    adornos = []
    for i, (x, z, rot) in enumerate([(-60, 40, 0), (60, 40, 0),
                                     (-60, -60, 90), (60, -60, 90)]):
        adornos.append(part("BancoAsiento%d" % i, (16, 1.2, 5), (x, 5, z),
                            "marron", rot_y=rot))
        adornos.append(part("BancoPataI%d" % i, (1.5, 4, 4), (x - 6, 3, z),
                            "negro", rot_y=rot))
        adornos.append(part("BancoPataD%d" % i, (1.5, 4, 4), (x + 6, 3, z),
                            "negro", rot_y=rot))

    for i, (x, z) in enumerate([(-76, 0), (76, 0)]):
        adornos.append(part("Jardinera%d" % i, (12, 6, 12), (x, 5, z), "marron"))
        adornos.append(part("Tierra%d" % i, (10, 1, 10), (x, 8.5, z), "marron",
                            top="Smooth"))
        adornos.append(part("Arbusto%d" % i, (8, 8, 8), (x, 12, z), "verde",
                            top="Smooth", bottom="Smooth", extra={"Shape": "Ball"}))
    M.append({"Name": "Adornos", "ClassName": "Model", "Children": adornos})

    return M


# ---------------------------------------------------------------------------
# Los portales
# ---------------------------------------------------------------------------

def portal(nombre, x, color, titulo, sub):
    tinte = (0.6, 0.8, 1) if color == "azul" else (0.6, 1, 0.6)
    return {"Name": "Portal_" + nombre, "ClassName": "Model", "Children": [
        part("Peana", (34, 4, 20), (x, 3, -40), "gris oscuro"),
        part("Escalon", (38, 2, 6), (x, 2, -28), "gris oscuro"),
        part(nombre, (22, 26, 3), (x, 18, -40), color, top="Smooth", bottom="Smooth",
             mat="Neon", extra={"Transparency": 0.35},
             children=[luz(3, 26, tinte)]),
        part("JambaI", (4, 32, 6), (x - 13, 19, -40), "blanco",
             top="Smooth", bottom="Smooth"),
        part("JambaD", (4, 32, 6), (x + 13, 19, -40), "blanco",
             top="Smooth", bottom="Smooth"),
        part("Dintel", (34, 4, 7), (x, 36, -40), color, top="Smooth", bottom="Smooth"),
        part("Rotulo", (30, 8, 1), (x, 43, -40), "blanco", top="Smooth", bottom="Smooth",
             children=panel([label("T", titulo, [0.1, 0.1, 0.1], 0.04, 0.52),
                             label("S", sub, [0.36, 0.36, 0.36], 0.6, 0.3)])),
    ]}


# ---------------------------------------------------------------------------
# El parkour
# ---------------------------------------------------------------------------

def parkour():
    """Circuito en espiral alrededor de la plaza, de 24 obstaculos.

    La regla que sigue todo el trazado: cada salto sube como mucho 4 studs y
    salva como mucho 20 de hueco. Un R6 clasico llega a eso justo; mas y deja
    de ser dificil para pasar a ser imposible.
    """
    M = []
    partes = []
    checkpoints = []

    radio = 132
    n = 24
    altura = 6

    def punto(i, r=None, alt=None):
        a = (i / n) * math.tau * 1.35 - math.pi / 2
        rr = r if r is not None else radio
        return (math.cos(a) * rr, alt if alt is not None else altura, math.sin(a) * rr)

    # Arranque: una rampa desde el suelo hasta el primer poyete.
    partes.append(part("Rampa", (16, 2, 26), (0, 4, 118), "blanco"))
    partes.append(part("Inicio", (20, 2, 20), (0, 6, 134), "blanco"))
    partes.append(part("CartelInicio", (18, 6, 1), (0, 13, 143), "blanco",
                       top="Smooth", bottom="Smooth",
                       children=panel([
                           label("T", "PARKOUR", [0.1, 0.1, 0.1], 0.05, 0.5),
                           label("S", "24 jumps to the top",
                                 [0.4, 0.4, 0.4], 0.6, 0.3)])))

    for i in range(n):
        color = RUTA[i % len(RUTA)]
        alt = 6 + i * 3.4
        x, _, z = punto(i, radio, alt)

        if i % 6 == 5:
            # Punto de control: plataforma ancha con arco, y se reaparece ahi.
            checkpoints.append(part("Checkpoint%d" % (i // 6), (14, 1, 14),
                                    (x, alt + 0.5, z), "verde",
                                    classname="SpawnLocation",
                                    top="Smooth", bottom="Smooth",
                                    extra={"Neutral": True, "Duration": 0}))
            partes.append(part("Meseta%d" % i, (20, 2, 20), (x, alt, z), "verde"))
            partes.append(part("ArcoI%d" % i, (1.4, 12, 1.4), (x - 7, alt + 7, z),
                               "verde", top="Smooth", bottom="Smooth"))
            partes.append(part("ArcoD%d" % i, (1.4, 12, 1.4), (x + 7, alt + 7, z),
                               "verde", top="Smooth", bottom="Smooth"))
            partes.append(part("ArcoT%d" % i, (16, 1.4, 1.4), (x, alt + 13, z),
                               "verde", top="Smooth", bottom="Smooth", mat="Neon",
                               children=[luz(1.8, 20, (0.6, 1, 0.6))]))

        elif i % 6 == 2:
            # Tramo de lava: tres losas finas con hueco entre ellas.
            for k in range(3):
                xk, _, zk = punto(i + k * 0.25, radio, alt)
                partes.append(part("Losa%d_%d" % (i, k), (7, 1.2, 7),
                                   (xk, alt, zk), color))
            xl, _, zl = punto(i + 0.5, radio, alt - 5)
            partes.append(part("Lava%d" % i, (26, 1, 26), (xl, alt - 5, zl), "rojo",
                               top="Smooth", bottom="Smooth", mat="Neon",
                               children=[luz(1.4, 22, (1, 0.4, 0.3))]))

        elif i % 6 == 3:
            # Andamio: se sube trepando, como en los obbies clasicos.
            partes.append(part("Base%d" % i, (12, 2, 12), (x, alt, z), color))
            partes.append(part("Truss%d" % i, (2, 22, 2), (x, alt + 12, z),
                               "gris oscuro", classname="TrussPart"))
            partes.append(part("Alto%d" % i, (10, 2, 10), (x, alt + 23, z), color))

        elif i % 6 == 4:
            # Salto de fe: dos plataformas estrechas y separadas.
            partes.append(part("Salto%dA" % i, (6, 1.6, 6), (x, alt, z), color))
            xb, _, zb = punto(i + 0.55, radio + 10, alt + 1)
            partes.append(part("Salto%dB" % i, (6, 1.6, 6), (xb, alt + 1, zb), color))

        else:
            partes.append(part("Plataforma%d" % i, (14, 2, 14), (x, alt, z), color))
            if i % 2 == 0:
                partes.append(part("Poste%d" % i, (1.2, 8, 1.2), (x, alt + 5, z),
                                   "amarillo", top="Smooth", bottom="Smooth",
                                   mat="Neon", children=[luz(1.2, 14)]))

    # El mirador de arriba
    cima = 6 + n * 3.4 + 8
    xc, _, zc = punto(n, radio - 20, cima)
    partes.append(part("Mirador", (36, 2, 36), (xc, cima, zc), "blanco"))
    partes.append(part("BarandaN", (36, 4, 1), (xc, cima + 3, zc - 17), "amarillo"))
    partes.append(part("BarandaS", (36, 4, 1), (xc, cima + 3, zc + 17), "amarillo"))
    partes.append(part("BarandaE", (1, 4, 36), (xc + 17, cima + 3, zc), "amarillo"))
    partes.append(part("BarandaO", (1, 4, 36), (xc - 17, cima + 3, zc), "amarillo"))
    partes.append(part("Trofeo", (6, 6, 6), (xc, cima + 5, zc), "amarillo",
                       top="Smooth", bottom="Smooth", mat="Neon",
                       extra={"Shape": "Ball"}, children=[luz(4, 40)]))
    partes.append(part("CartelCima", (30, 8, 1), (xc, cima + 14, zc), "blanco",
                       top="Smooth", bottom="Smooth",
                       children=panel([
                           label("T", "YOU MADE IT", [0.1, 0.1, 0.1], 0.05, 0.5),
                           label("S", "now go build something",
                                 [0.4, 0.4, 0.4], 0.6, 0.3)])))

    M.append({"Name": "Parkour", "ClassName": "Model", "Children": partes})
    M.append({"Name": "Checkpoints", "ClassName": "Model", "Children": checkpoints})
    return M


# ---------------------------------------------------------------------------

def construir():
    M = [part("Baseplate", (1400, 20, 1400), (0, -10, 0), "verde oscuro",
              top="Studs", bottom="Smooth", extra={"Locked": True})]

    M.extend(plaza())
    M.append(portal("PortalConstruir", -38, "verde", "BUILD", "make your own place"))
    M.append(portal("PortalGaleria", 38, "azul", "PLAY", "what others have built"))

    M.append({"Name": "Cartel", "ClassName": "Model", "Children": [
        part("Poste1", (5, 40, 5), (-40, 22, 86), "marron"),
        part("Poste2", (5, 40, 5), (40, 22, 86), "marron"),
        part("Panel", (84, 22, 2), (0, 44, 86), "blanco", top="Smooth", bottom="Smooth",
             children=panel([
                label("Titulo", "BYGONE", [0.1, 0.1, 0.1], 0.04, 0.46),
                label("Lema", "build classic ROBLOX places, the way they were",
                      [0.34, 0.34, 0.34], 0.56, 0.16),
                label("Sub", "every creation here was made by someone who plays here",
                      [0.44, 0.44, 0.44], 0.76, 0.13)])),
        part("Marquesina", (88, 3, 7), (0, 56, 86), "burdeos",
             top="Smooth", bottom="Smooth"),
    ]})

    M.extend(parkour())

    # Aparicion invisible, en el centro de la plaza.
    M.append(part("SpawnLocation", (14, 1, 14), (0, 2.6, 44), "blanco",
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
    print("Vestibulo: %d partes, %d puntos de aparicion -> %s"
          % (texto.count('"ClassName": "Part"'),
             texto.count('"ClassName": "SpawnLocation"'), ruta))


if __name__ == "__main__":
    main()
