# -*- coding: utf-8 -*-
"""
Genera Hub/Lobby.model.json: el vestibulo de Bygone.

La version anterior tenia portales de neon, farolas, bancos, jardineras y un
parkour dando vueltas alrededor, todo a la vez y todo compitiendo por la
atencion. Quedaba abarrotado.

Este parte de una idea sola: una sala noble, simetrica y tranquila. Nada de
portales: para construir o para jugar se usa el menu, que es donde ya esta toda
la informacion. La sala solo tiene que ser un sitio agradable donde caer.

  - planta cuadrada de 220, con una nave central marcada por columnas
  - suelo de damero suave, sin contrastes fuertes
  - una tarima al fondo con el rotulo, como el escenario de un salon
  - iluminacion indirecta desde apliques en las columnas
  - una arcada lateral que da paso al parkour, claramente separada de la sala

Paleta corta a proposito: crema, piedra, madera y un solo acento burdeos. Los
colores saturados se reservan para el parkour, que si tiene que cantar.

Uso:  python generate_lobby.py
"""

import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

BC = {
    "crema": 1002, "piedra": 194, "piedra oscura": 199, "madera": 192,
    "burdeos": 1003, "blanco": 1001, "negro": 26, "cesped": 28,
    "arena": 5, "laton": 24,
    # solo para el parkour
    "azul": 23, "verde": 37, "amarillo": 24, "naranja": 106, "rojo": 21,
    "morado": 104, "turquesa": 1018,
}

RUTA = ["azul", "verde", "amarillo", "naranja", "rojo", "morado", "turquesa"]


def part(name, size, pos, color="piedra", top="Studs", bottom="Inlet", rot_y=0.0,
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


def panel(textos, caras=("Back", "Front")):
    return [{"Name": "Ficha" + f, "ClassName": "SurfaceGui", "Properties": {
        "Face": f, "SizingMode": "PixelsPerStud", "PixelsPerStud": 50,
        "AlwaysOnTop": False}, "Children": textos} for f in caras]


def luz(brillo=1.6, alcance=30, color=(1, 0.95, 0.85)):
    return {"Name": "PointLight", "ClassName": "PointLight", "Properties": {
        "Brightness": brillo, "Range": alcance, "Color": list(color)}}


# ---------------------------------------------------------------------------
# La sala
# ---------------------------------------------------------------------------

LADO = 110          # media anchura de la sala
ALTO_MURO = 34


def sala():
    M = []

    # Suelo: damero suave. Dos grises cercanos, no blanco y negro.
    suelo = []
    paso = 22
    n = int(LADO * 2 / paso)
    for i in range(n):
        for j in range(n):
            x = -LADO + paso / 2 + i * paso
            z = -LADO + paso / 2 + j * paso
            col = "piedra" if (i + j) % 2 == 0 else "piedra oscura"
            suelo.append(part("Baldosa%d_%d" % (i, j), (paso, 2, paso), (x, 1, z), col))
    M.append({"Name": "Suelo", "ClassName": "Model", "Children": suelo})

    # Muros lisos, zocalo de madera y cornisa.
    muros = []
    for i, (dx, dz, sx, sz) in enumerate([
            (0, LADO, LADO * 2 + 6, 4), (0, -LADO, LADO * 2 + 6, 4),
            (LADO, 0, 4, LADO * 2 + 6), (-LADO, 0, 4, LADO * 2 + 6)]):
        muros.append(part("Zocalo%d" % i, (sx, 6, sz + 1), (dx, 3, dz), "madera",
                          top="Smooth", bottom="Smooth"))
        muros.append(part("Muro%d" % i, (sx, ALTO_MURO, sz), (dx, 6 + ALTO_MURO / 2, dz),
                          "crema", top="Smooth", bottom="Smooth"))
        muros.append(part("Cornisa%d" % i, (sx + 5, 4, sz + 5),
                          (dx, 6 + ALTO_MURO + 2, dz), "madera",
                          top="Smooth", bottom="Smooth"))
    M.append({"Name": "Muros", "ClassName": "Model", "Children": muros})

    # Nave central: dos hileras de columnas con aplique de luz.
    columnas = []
    for lado in (-1, 1):
        for k in range(5):
            x = lado * 52
            z = -80 + k * 40
            columnas.append(part("Basa%d_%d" % (lado, k), (11, 3, 11), (x, 3.5, z),
                                 "piedra oscura"))
            columnas.append(part("Fuste%d_%d" % (lado, k), (8, 30, 8), (x, 20, z),
                                 "blanco", top="Smooth", bottom="Smooth"))
            columnas.append(part("Capitel%d_%d" % (lado, k), (12, 3, 12), (x, 36.5, z),
                                 "madera", top="Smooth", bottom="Smooth"))
            # Aplique: la luz nace de la columna, no de una farola en medio.
            columnas.append(part("Aplique%d_%d" % (lado, k), (3, 3, 3),
                                 (x - lado * 6, 28, z), "laton",
                                 top="Smooth", bottom="Smooth", mat="Neon",
                                 children=[luz(1.7, 34)]))
    M.append({"Name": "Columnas", "ClassName": "Model", "Children": columnas})

    # Alfombra que marca el eje de la nave.
    M.append({"Name": "Alfombra", "ClassName": "Model", "Children": [
        part("Borde", (34, 0.3, 180), (0, 2.2, 0), "laton",
             top="Smooth", bottom="Smooth"),
        part("Centro", (28, 0.4, 174), (0, 2.3, 0), "burdeos",
             top="Smooth", bottom="Smooth"),
    ]})

    # Tarima del fondo con el rotulo.
    tarima = [
        part("Escalon1", (72, 2, 10), (0, 3, -74), "piedra oscura"),
        part("Escalon2", (68, 2, 8), (0, 5, -78), "piedra oscura"),
        part("Plataforma", (64, 2, 30), (0, 7, -92), "piedra oscura"),
        part("Muro", (64, 26, 3), (0, 20, -104), "crema",
             top="Smooth", bottom="Smooth"),
        part("Rotulo", (54, 18, 1), (0, 22, -102), "crema",
             top="Smooth", bottom="Smooth",
             children=panel([
                 label("Titulo", "BYGONE", [0.13, 0.13, 0.13], 0.06, 0.44),
                 label("Lema", "build classic ROBLOX places, the way they were",
                       [0.36, 0.36, 0.36], 0.55, 0.14),
                 label("Sub", "press M, or the Creations button, to begin",
                       [0.46, 0.46, 0.46], 0.74, 0.12),
             ], caras=("Front",))),
        part("ApliqueI", (3, 3, 3), (-24, 34, -100), "laton",
             top="Smooth", bottom="Smooth", mat="Neon", children=[luz(2, 26)]),
        part("ApliqueD", (3, 3, 3), (24, 34, -100), "laton",
             top="Smooth", bottom="Smooth", mat="Neon", children=[luz(2, 26)]),
    ]
    M.append({"Name": "Tarima", "ClassName": "Model", "Children": tarima})

    # Bancada discreta contra los muros laterales.
    bancos = []
    for lado in (-1, 1):
        for k in range(3):
            x = lado * 86
            z = -50 + k * 50
            bancos.append(part("Banco%d_%d" % (lado, k), (10, 1.4, 26),
                               (x, 5, z), "madera"))
            bancos.append(part("PataA%d_%d" % (lado, k), (8, 4, 3),
                               (x, 2.6, z - 10), "piedra oscura"))
            bancos.append(part("PataB%d_%d" % (lado, k), (8, 4, 3),
                               (x, 2.6, z + 10), "piedra oscura"))
    M.append({"Name": "Bancos", "ClassName": "Model", "Children": bancos})

    return M


# ---------------------------------------------------------------------------
# La arcada al parkour
# ---------------------------------------------------------------------------

def arcada():
    """Una puerta en el muro sur que separa la sala del circuito."""
    z = LADO
    return {"Name": "Arcada", "ClassName": "Model", "Children": [
        part("Hueco", (26, 26, 8), (0, 19, z), "cesped",
             extra={"Transparency": 1, "CanCollide": False}),
        part("JambaI", (6, 26, 8), (-16, 19, z), "madera",
             top="Smooth", bottom="Smooth"),
        part("JambaD", (6, 26, 8), (16, 19, z), "madera",
             top="Smooth", bottom="Smooth"),
        part("Dintel", (38, 5, 8), (0, 34, z), "madera",
             top="Smooth", bottom="Smooth"),
        part("Rotulo", (30, 6, 1), (0, 34, z + 4.6), "crema",
             top="Smooth", bottom="Smooth",
             children=panel([
                 label("T", "PARKOUR", [0.13, 0.13, 0.13], 0.06, 0.5),
                 label("S", "24 jumps to the top", [0.42, 0.42, 0.42], 0.62, 0.28),
             ], caras=("Back",))),
        part("Sendero", (26, 2, 40), (0, 1, z + 22), "piedra"),
    ]}


# ---------------------------------------------------------------------------
# El parkour, fuera de la sala
# ---------------------------------------------------------------------------

def parkour():
    """Circuito de 24 obstaculos que sube en espiral, al sur de la sala.

    Regla del trazado: como mucho 4 studs de subida y 20 de hueco por salto. Es
    lo que un R6 clasico alcanza justo; pasarse convierte dificil en imposible.
    """
    partes, checkpoints = [], []

    centro_z = LADO + 150
    radio = 92
    n = 24

    def punto(i, r, alt):
        a = (i / n) * math.tau * 1.3 + math.pi / 2
        return (math.cos(a) * r, alt, centro_z + math.sin(a) * r)

    partes.append(part("Rampa", (18, 2, 30), (0, 3, LADO + 56), "blanco"))
    partes.append(part("Inicio", (24, 2, 24), (0, 5, LADO + 82), "blanco"))

    for i in range(n):
        color = RUTA[i % len(RUTA)]
        alt = 5 + i * 3.4
        x, _, z = punto(i, radio, alt)

        if i % 6 == 5:
            checkpoints.append(part("Checkpoint%d" % (i // 6), (14, 1, 14),
                                    (x, alt + 0.5, z), "verde",
                                    classname="SpawnLocation",
                                    top="Smooth", bottom="Smooth",
                                    extra={"Neutral": True, "Duration": 0}))
            partes.append(part("Meseta%d" % i, (22, 2, 22), (x, alt, z), "verde"))
            partes.append(part("ArcoI%d" % i, (1.4, 12, 1.4), (x - 8, alt + 7, z),
                               "verde", top="Smooth", bottom="Smooth"))
            partes.append(part("ArcoD%d" % i, (1.4, 12, 1.4), (x + 8, alt + 7, z),
                               "verde", top="Smooth", bottom="Smooth"))
            partes.append(part("ArcoT%d" % i, (18, 1.4, 1.4), (x, alt + 13, z),
                               "verde", top="Smooth", bottom="Smooth", mat="Neon",
                               children=[luz(1.8, 20, (0.6, 1, 0.6))]))

        elif i % 6 == 2:
            for k in range(3):
                xk, _, zk = punto(i + k * 0.24, radio, alt)
                partes.append(part("Losa%d_%d" % (i, k), (7, 1.2, 7),
                                   (xk, alt, zk), color))
            xl, _, zl = punto(i + 0.45, radio, alt - 5)
            partes.append(part("Lava%d" % i, (26, 1, 26), (xl, alt - 5, zl), "rojo",
                               top="Smooth", bottom="Smooth", mat="Neon",
                               children=[luz(1.4, 22, (1, 0.4, 0.3))]))

        elif i % 6 == 3:
            partes.append(part("Base%d" % i, (12, 2, 12), (x, alt, z), color))
            partes.append(part("Truss%d" % i, (2, 22, 2), (x, alt + 12, z),
                               "piedra oscura", classname="TrussPart"))
            partes.append(part("Alto%d" % i, (10, 2, 10), (x, alt + 23, z), color))

        elif i % 6 == 4:
            partes.append(part("Salto%dA" % i, (6, 1.6, 6), (x, alt, z), color))
            xb, _, zb = punto(i + 0.5, radio + 12, alt + 1)
            partes.append(part("Salto%dB" % i, (6, 1.6, 6), (xb, alt + 1, zb), color))

        else:
            partes.append(part("Plataforma%d" % i, (14, 2, 14), (x, alt, z), color))

    cima = 5 + n * 3.4 + 8
    xc, _, zc = punto(n, radio - 24, cima)
    partes.append(part("Mirador", (36, 2, 36), (xc, cima, zc), "blanco"))
    for nombre, tam, off in (("BarandaN", (36, 4, 1), (0, 3, -17)),
                             ("BarandaS", (36, 4, 1), (0, 3, 17)),
                             ("BarandaE", (1, 4, 36), (17, 3, 0)),
                             ("BarandaO", (1, 4, 36), (-17, 3, 0))):
        partes.append(part(nombre, tam, (xc + off[0], cima + off[1], zc + off[2]),
                           "laton", top="Smooth", bottom="Smooth"))
    partes.append(part("Trofeo", (6, 6, 6), (xc, cima + 5, zc), "laton",
                       top="Smooth", bottom="Smooth", mat="Neon",
                       extra={"Shape": "Ball"}, children=[luz(4, 44)]))
    partes.append(part("CartelCima", (30, 8, 1), (xc, cima + 14, zc), "crema",
                       top="Smooth", bottom="Smooth",
                       children=panel([
                           label("T", "YOU MADE IT", [0.13, 0.13, 0.13], 0.05, 0.5),
                           label("S", "now go build something",
                                 [0.42, 0.42, 0.42], 0.6, 0.3)])))

    return [{"Name": "Parkour", "ClassName": "Model", "Children": partes},
            {"Name": "Checkpoints", "ClassName": "Model", "Children": checkpoints}]


# ---------------------------------------------------------------------------

def construir():
    M = [part("Baseplate", (1400, 20, 1400), (0, -10, 0), "cesped",
              top="Studs", bottom="Smooth", extra={"Locked": True})]

    M.extend(sala())
    M.append(arcada())
    M.extend(parkour())

    # Apareces en la nave, mirando a la tarima. La losa es invisible y sin
    # colision: se ve el damero, no un cuadrado blanco.
    M.append(part("SpawnLocation", (16, 1, 16), (0, 2.6, 30), "blanco",
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
    print("Vestibulo: %d partes, %d apariciones -> %s"
          % (texto.count('"ClassName": "Part"'),
             texto.count('"ClassName": "SpawnLocation"'), ruta))


if __name__ == "__main__":
    main()
