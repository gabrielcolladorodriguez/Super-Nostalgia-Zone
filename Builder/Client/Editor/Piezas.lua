--!nocheck
--[[
	Piezas -- todo lo que se puede insertar, por familias.

	Hay dos cosas distintas aqui y conviene no mezclarlas:

	  FORMAS       una sola parte con su tamano y superficies. Es lo que el
	               serializador guarda directamente.
	  PREFABS      un monton de partes ya colocadas: una puerta, una escalera,
	               una rampa. Se montan en el sitio y a partir de ese momento
	               son partes normales y corrientes, editables una a una. No
	               son un tipo aparte, asi que el formato de guardado no cambia.

	Que sean prefabs y no piezas especiales es a proposito: quien quiera una
	puerta mas ancha la ensancha, y quien quiera quitarle el marco se lo quita.
]]

local Piezas = {}

--------------------------------------------------------------------------------
-- Formas sueltas
--------------------------------------------------------------------------------

Piezas.FORMAS = {
	{ nombre = "Block",    indice = 0, tam = Vector3.new(4, 1.2, 2) },
	{ nombre = "Brick",    indice = 0, tam = Vector3.new(2, 1.2, 1) },
	{ nombre = "Plate",    indice = 0, tam = Vector3.new(4, 0.4, 4) },
	{ nombre = "Panel",    indice = 0, tam = Vector3.new(8, 8, 0.6) },
	{ nombre = "Beam",     indice = 0, tam = Vector3.new(1.2, 1.2, 12) },
	{ nombre = "Cube",     indice = 0, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Ball",     indice = 1, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Cylinder", indice = 2, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Pillar",   indice = 2, tam = Vector3.new(12, 3, 3),
	  giro = Vector3.new(0, 0, 90) },
	{ nombre = "Wedge",    indice = 3, tam = Vector3.new(4, 2.4, 4) },
	{ nombre = "Ramp",     indice = 3, tam = Vector3.new(8, 4, 16) },
	{ nombre = "Corner",   indice = 4, tam = Vector3.new(4, 4, 4) },
	{ nombre = "Truss",    indice = 5, tam = Vector3.new(2, 16, 2) },
	{ nombre = "Spawn",    indice = 6, tam = Vector3.new(12, 1, 12) },
	{ nombre = "Seat",     indice = 7, tam = Vector3.new(4, 1.2, 4) },
}

--------------------------------------------------------------------------------
-- Prefabricados
--------------------------------------------------------------------------------
-- Cada uno describe sus partes con posiciones RELATIVAS al punto donde lo
-- sueltas. El editor las suma a ese punto y ya esta.

local function pieza(nombre, tam, pos, opciones)
	local p = { nombre = nombre, tam = tam, pos = pos }
	for k, v in pairs(opciones or {}) do
		p[k] = v
	end
	return p
end

Piezas.PREFABS = {
	{
		nombre = "Door",
		descripcion = "Marco y hoja. La hoja se puede borrar o mover.",
		partes = {
			pieza("MarcoI", Vector3.new(1, 14, 2), Vector3.new(-4.5, 7, 0)),
			pieza("MarcoD", Vector3.new(1, 14, 2), Vector3.new(4.5, 7, 0)),
			pieza("Dintel", Vector3.new(10, 1, 2), Vector3.new(0, 14.5, 0)),
			pieza("Hoja", Vector3.new(8, 13, 0.6), Vector3.new(0, 6.5, 0),
			      { color = 192, superficie = "Smooth" }),
		},
	},
	{
		nombre = "Doorway",
		descripcion = "Un hueco de puerta en un muro.",
		partes = {
			pieza("MuroI", Vector3.new(8, 16, 2), Vector3.new(-9, 8, 0)),
			pieza("MuroD", Vector3.new(8, 16, 2), Vector3.new(9, 8, 0)),
			pieza("MuroArriba", Vector3.new(26, 2, 2), Vector3.new(0, 17, 0)),
		},
	},
	{
		nombre = "Window",
		descripcion = "Muro con cristal.",
		partes = {
			pieza("MuroBajo", Vector3.new(16, 4, 2), Vector3.new(0, 2, 0)),
			pieza("MuroAlto", Vector3.new(16, 3, 2), Vector3.new(0, 14.5, 0)),
			pieza("JambaI", Vector3.new(2, 9, 2), Vector3.new(-7, 8.5, 0)),
			pieza("JambaD", Vector3.new(2, 9, 2), Vector3.new(7, 8.5, 0)),
			pieza("Cristal", Vector3.new(12, 9, 0.4), Vector3.new(0, 8.5, 0),
			      { color = 1003, transparencia = 0.6, superficie = "Smooth" }),
		},
	},
	{
		nombre = "Stairs",
		descripcion = "Ocho escalones. Cada uno es una parte suelta.",
		partes = (function ()
			local t = {}
			for i = 1, 8 do
				table.insert(t, pieza("Escalon" .. i, Vector3.new(8, 1.2, 3),
				                      Vector3.new(0, i * 1.2 - 0.6, i * 3 - 1.5)))
			end
			return t
		end)(),
	},
	{
		nombre = "Platform",
		descripcion = "Plataforma con cuatro patas.",
		partes = {
			pieza("Tablero", Vector3.new(20, 1.2, 20), Vector3.new(0, 12, 0)),
			pieza("Pata1", Vector3.new(2, 12, 2), Vector3.new(-8, 6, -8)),
			pieza("Pata2", Vector3.new(2, 12, 2), Vector3.new(8, 6, -8)),
			pieza("Pata3", Vector3.new(2, 12, 2), Vector3.new(-8, 6, 8)),
			pieza("Pata4", Vector3.new(2, 12, 2), Vector3.new(8, 6, 8)),
		},
	},
	{
		nombre = "Lamp post",
		descripcion = "Farola con luz de verdad.",
		partes = {
			pieza("Pie", Vector3.new(4, 2, 4), Vector3.new(0, 1, 0), { color = 26 }),
			pieza("Poste", Vector3.new(1.6, 20, 1.6), Vector3.new(0, 11, 0),
			      { color = 26, superficie = "Smooth" }),
			pieza("Fanal", Vector3.new(4, 4, 4), Vector3.new(0, 22, 0),
			      { color = 24, neon = true, luz = { brillo = 2.4, alcance = 32 },
			        superficie = "Smooth" }),
		},
	},
	{
		nombre = "Sign post",
		descripcion = "Cartel con texto, listo para escribir en el.",
		partes = {
			pieza("Poste", Vector3.new(1.2, 12, 1.2), Vector3.new(0, 6, 0),
			      { color = 192 }),
			pieza("Tabla", Vector3.new(14, 6, 0.6), Vector3.new(0, 14, 0),
			      { color = 1001, superficie = "Smooth",
			        cartel = "Your text here" }),
		},
	},
	{
		nombre = "Checkpoint",
		descripcion = "Punto de aparicion con arco, para parkour.",
		partes = {
			pieza("Base", Vector3.new(12, 1, 12), Vector3.new(0, 0.5, 0),
			      { clase = 6, color = 37, superficie = "Smooth" }),
			pieza("ArcoI", Vector3.new(1.2, 12, 1.2), Vector3.new(-5, 6, 0),
			      { color = 37 }),
			pieza("ArcoD", Vector3.new(1.2, 12, 1.2), Vector3.new(5, 6, 0),
			      { color = 37 }),
			pieza("ArcoTecho", Vector3.new(12, 1.2, 1.2), Vector3.new(0, 12, 0),
			      { color = 37, neon = true, luz = { brillo = 1.6, alcance = 18 } }),
		},
	},
	{
		nombre = "Kill brick",
		descripcion = "Ladrillo rojo de lava, del clasico.",
		partes = {
			pieza("Lava", Vector3.new(16, 1.2, 16), Vector3.new(0, 0.6, 0),
			      { color = 21, neon = true, luz = { brillo = 1.2, alcance = 14 } }),
		},
	},
	{
		nombre = "Tower",
		descripcion = "Torre de cuatro alturas.",
		partes = (function ()
			local t = {}
			for i = 0, 3 do
				local w = 20 - i * 3
				table.insert(t, pieza("Piso" .. i, Vector3.new(w, 8, w),
				                      Vector3.new(0, 4 + i * 8, 0)))
			end
			return t
		end)(),
	},
	{
		nombre = "Bridge",
		descripcion = "Puente con barandillas.",
		partes = {
			pieza("Tablero", Vector3.new(10, 1.2, 40), Vector3.new(0, 0.6, 0),
			      { color = 192 }),
			pieza("BarandaI", Vector3.new(0.8, 4, 40), Vector3.new(-4.6, 3, 0),
			      { color = 24 }),
			pieza("BarandaD", Vector3.new(0.8, 4, 40), Vector3.new(4.6, 3, 0),
			      { color = 24 }),
		},
	},
	{
		nombre = "Arena",
		descripcion = "Suelo cuadrado con muro alrededor.",
		partes = {
			pieza("Suelo", Vector3.new(60, 1.2, 60), Vector3.new(0, 0.6, 0)),
			pieza("MuroN", Vector3.new(60, 8, 2), Vector3.new(0, 4, -29)),
			pieza("MuroS", Vector3.new(60, 8, 2), Vector3.new(0, 4, 29)),
			pieza("MuroE", Vector3.new(2, 8, 60), Vector3.new(29, 4, 0)),
			pieza("MuroO", Vector3.new(2, 8, 60), Vector3.new(-29, 4, 0)),
		},
	},
}

return Piezas
