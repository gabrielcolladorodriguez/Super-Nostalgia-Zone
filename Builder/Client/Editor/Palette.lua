--!nocheck
--[[
	Palette -- los colores, materiales y superficies que ofrece el editor.

	Es la paleta de BrickColor clasica, la que tenia el Studio de 2008: 64
	colores, no los 1.000 y pico de hoy. Limitarla no es una carencia, es lo que
	hace que dos construcciones de gente distinta se parezcan a lo mismo.
]]

local Palette = {}

-- Numero de BrickColor. El orden es el de la rejilla del Studio viejo.
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
	{ nombre = "Plastic",   indice = 0 },
	{ nombre = "Smooth",    indice = 1 },
	{ nombre = "Wood",      indice = 2 },
	{ nombre = "Slate",     indice = 3 },
	{ nombre = "Concrete",  indice = 4 },
	{ nombre = "Corroded",  indice = 5 },
	{ nombre = "Diamond",   indice = 6 },
	{ nombre = "Foil",      indice = 7 },
	{ nombre = "Grass",     indice = 8 },
	{ nombre = "Ice",       indice = 9 },
	{ nombre = "Brick",     indice = 10 },
	{ nombre = "Sand",      indice = 11 },
	{ nombre = "Neon",      indice = 12 },
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
	{ nombre = "Block",   indice = 0, tam = Vector3.new(4, 1.2, 2) },
	{ nombre = "Ball",    indice = 1, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Cylinder",indice = 2, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Wedge",   indice = 3, tam = Vector3.new(4, 2.4, 4) },
	{ nombre = "Corner",  indice = 4, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Truss",   indice = 5, tam = Vector3.new(2, 8, 2) },
	{ nombre = "Spawn",   indice = 6, tam = Vector3.new(12, 1, 12) },
	{ nombre = "Seat",    indice = 7, tam = Vector3.new(4, 1.2, 4) },
}

-- Estetica de dialogo de 2008, la misma que usa el menu del vestibulo.
Palette.UI = {
	FONDO     = Color3.fromRGB(177, 177, 177),
	PANEL     = Color3.fromRGB(199, 199, 199),
	OSCURO    = Color3.fromRGB(128, 128, 128),
	TITULO    = Color3.fromRGB(151, 151, 151),
	TEXTO     = Color3.fromRGB(51, 51, 51),
	TENUE     = Color3.fromRGB(102, 102, 102),
	SELECCION = Color3.fromRGB(102, 153, 204),
	BLANCO    = Color3.fromRGB(255, 255, 255),
	FUENTE    = Enum.Font.Cartoon,
}

return Palette
