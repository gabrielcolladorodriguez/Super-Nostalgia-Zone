--!nocheck
--[[
	Palette -- colores, materiales, superficies, formas y estilo de la interfaz.

	La paleta de color es la de BrickColor clasica del Studio de 2008: 64
	colores, no los mil y pico de hoy. Limitarla no es una carencia, es lo que
	hace que dos construcciones de gente distinta se parezcan a lo mismo.
]]

local Palette = {}

Palette.COLORES = {
	1,    9,   11,   18,   21,   23,   24,   26,
	28,   29,   36,   37,   38,   39,   40,   41,
	42,   43,   45,   47,   100,  101,  102,  103,
	104,  105,  106,  107,  110,  111,  112,  113,
	119,  125,  126,  127,  135,  138,  140,  141,
	151,  153,  190,  191,  192,  193,  194,  195,
	196,  198,  199,  208,  217,  226,  1001, 1002,
	1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010,
}

Palette.MATERIALES = {
	{ nombre = "Plastic",  indice = 0 },
	{ nombre = "Smooth",   indice = 1 },
	{ nombre = "Wood",     indice = 2 },
	{ nombre = "Slate",    indice = 3 },
	{ nombre = "Concrete", indice = 4 },
	{ nombre = "Corroded", indice = 5 },
	{ nombre = "Diamond",  indice = 6 },
	{ nombre = "Foil",     indice = 7 },
	{ nombre = "Grass",    indice = 8 },
	{ nombre = "Ice",      indice = 9 },
	{ nombre = "Brick",    indice = 10 },
	{ nombre = "Sand",     indice = 11 },
	{ nombre = "Neon",     indice = 12 },
}

Palette.SUPERFICIES = {
	{ nombre = "Smooth",    enum = Enum.SurfaceType.Smooth },
	{ nombre = "Studs",     enum = Enum.SurfaceType.Studs },
	{ nombre = "Inlet",     enum = Enum.SurfaceType.Inlet },
	{ nombre = "Universal", enum = Enum.SurfaceType.Universal },
	{ nombre = "Weld",      enum = Enum.SurfaceType.Weld },
	{ nombre = "Glue",      enum = Enum.SurfaceType.Glue },
}

Palette.FORMAS = {
	{ nombre = "Block",    indice = 0, tam = Vector3.new(4, 1.2, 2) },
	{ nombre = "Ball",     indice = 1, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Cylinder", indice = 2, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Wedge",    indice = 3, tam = Vector3.new(4, 2.4, 4) },
	{ nombre = "Corner",   indice = 4, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Truss",    indice = 5, tam = Vector3.new(2, 8, 2) },
	{ nombre = "Spawn",    indice = 6, tam = Vector3.new(12, 1, 12) },
	{ nombre = "Seat",     indice = 7, tam = Vector3.new(4, 1.2, 4) },
}

-- Piezas ya montadas: la parte mas lo que le cuelga.
Palette.EXTRAS = {
	{ nombre = "Light",  clave = "l" },
	{ nombre = "Sign",   clave = "c" },
	{ nombre = "Decal",  clave = "d" },
	{ nombre = "Mesh",   clave = "m" },
}

Palette.REJILLAS = { 0, 0.2, 1, 2, 4 }
Palette.GIROS = { 15, 45, 90 }

--[[
	Estetica de dialogo de 2008.

	La interfaz NUNCA se ancla arriba a la izquierda: ahi vive el boton de
	Roblox y la taparia. Todo va centrado, a la derecha o abajo.
]]
Palette.UI = {
	FONDO     = Color3.fromRGB(191, 191, 191),
	PANEL     = Color3.fromRGB(208, 208, 208),
	HUECO     = Color3.fromRGB(168, 168, 168),
	OSCURO    = Color3.fromRGB(122, 122, 122),
	LUZ       = Color3.fromRGB(232, 232, 232),
	TITULO    = Color3.fromRGB(96, 106, 122),
	TEXTO     = Color3.fromRGB(38, 38, 38),
	TENUE     = Color3.fromRGB(104, 104, 104),
	SELECCION = Color3.fromRGB(74, 128, 190),
	ACENTO    = Color3.fromRGB(212, 160, 42),
	PELIGRO   = Color3.fromRGB(150, 48, 48),
	BLANCO    = Color3.fromRGB(252, 252, 252),
	FUENTE    = Enum.Font.Cartoon,
	MARGEN_SUPERIOR = 56,   -- deja libre la esquina del boton de Roblox
}

return Palette
