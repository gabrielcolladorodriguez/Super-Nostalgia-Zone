--!nocheck
--[[
	Gizmos -- las flechas de mover, los arcos de girar y los tiradores de
	escalar que salen alrededor de lo seleccionado.

	Se usan `Handles` y `ArcHandles`, que son instancias del propio motor. Podria
	dibujarse todo a mano con partes y rayos, pero estas ya traen el arrastre
	resuelto, se ven igual en pantalla estes lejos o cerca, y funcionan con el
	dedo en movil sin escribir nada aparte.

	Trabajan sobre una parte invisible (`ancla`) que envuelve la seleccion
	entera. Asi mover cinco piezas a la vez es mover una sola cosa, y cada pieza
	guarda su desplazamiento respecto al ancla.
]]

local RunService = game:GetService("RunService")

local Gizmos = {}
Gizmos.__index = Gizmos

local COLORES = {
	mover   = BrickColor.new("Bright blue"),
	girar   = BrickColor.new("Bright yellow"),
	escalar = BrickColor.new("Bright green"),
}

function Gizmos.new(api)
	local self = setmetatable({}, Gizmos)

	self.api = api
	self.modo = "mover"
	self.offsets = {}
	self.activo = false

	local pantalla = api.pantallaGizmos

	-- El ancla nunca se ve ni estorba: solo existe para que los tiradores
	-- tengan a que agarrarse.
	self.ancla = Instance.new("Part")
	self.ancla.Name = "AnclaDeSeleccion"
	self.ancla.Anchored = true
	self.ancla.CanCollide = false
	self.ancla.CanQuery = false
	self.ancla.CanTouch = false
	self.ancla.Transparency = 1
	self.ancla.Size = Vector3.one
	self.ancla.Parent = workspace

	self.mover = Instance.new("Handles")
	self.mover.Name = "Mover"
	self.mover.Style = Enum.HandlesStyle.Movement
	self.mover.Color3 = COLORES.mover.Color
	self.mover.Adornee = nil
	self.mover.Visible = false
	self.mover.Parent = pantalla

	self.escalar = Instance.new("Handles")
	self.escalar.Name = "Escalar"
	self.escalar.Style = Enum.HandlesStyle.Resize
	self.escalar.Color3 = COLORES.escalar.Color
	self.escalar.Adornee = nil
	self.escalar.Visible = false
	self.escalar.Parent = pantalla

	self.girar = Instance.new("ArcHandles")
	self.girar.Name = "Girar"
	self.girar.Color3 = COLORES.girar.Color
	self.girar.Adornee = nil
	self.girar.Visible = false
	self.girar.Parent = pantalla

	self:_conectar()
	return self
end

--------------------------------------------------------------------------------

function Gizmos:_seleccion()
	return self.api.estado.seleccion
end

--- Caja que envuelve la seleccion entera.
function Gizmos:_caja()
	local sel = self:_seleccion()
	if #sel == 0 then
		return nil
	end

	local min, max = sel[1].Position, sel[1].Position

	for _, parte in ipairs(sel) do
		local mitad = parte.Size / 2
		local p = parte.Position
		min = Vector3.new(math.min(min.X, p.X - mitad.X),
		                  math.min(min.Y, p.Y - mitad.Y),
		                  math.min(min.Z, p.Z - mitad.Z))
		max = Vector3.new(math.max(max.X, p.X + mitad.X),
		                  math.max(max.Y, p.Y + mitad.Y),
		                  math.max(max.Z, p.Z + mitad.Z))
	end

	return (min + max) / 2, (max - min)
end

function Gizmos:_guardarOffsets()
	self.offsets = {}
	local centro = self.ancla.Position

	for _, parte in ipairs(self:_seleccion()) do
		self.offsets[parte] = {
			pos = parte.Position - centro,
			tam = parte.Size,
			cf = self.ancla.CFrame:ToObjectSpace(parte.CFrame),
		}
	end
end

--------------------------------------------------------------------------------

function Gizmos:_conectar()
	-- Mover ------------------------------------------------------------------
	self.mover.MouseButton1Down:Connect(function ()
		self.api.apuntar()
		self.activo = true
		self:_guardarOffsets()
	end)

	self.mover.MouseDrag:Connect(function (cara, distancia)
		local direccion = Vector3.FromNormalId(cara)
		local paso = self.api.encajarEscalar(distancia)
		local destino = self.anclaOrigen + direccion * paso

		self.ancla.Position = destino
		for parte, guardado in pairs(self.offsets) do
			if parte.Parent then
				parte.Position = destino + guardado.pos
			end
		end
	end)

	self.mover.MouseButton1Up:Connect(function ()
		self.activo = false
		self:Refrescar()
	end)

	-- Escalar ----------------------------------------------------------------
	self.escalar.MouseButton1Down:Connect(function ()
		self.api.apuntar()
		self.activo = true
		self:_guardarOffsets()
	end)

	self.escalar.MouseDrag:Connect(function (cara, distancia)
		local paso = self.api.encajarEscalar(distancia)
		local eje = Vector3.FromNormalId(cara)
		local crecimiento = Vector3.new(math.abs(eje.X), math.abs(eje.Y),
		                                math.abs(eje.Z)) * paso

		for parte, guardado in pairs(self.offsets) do
			if parte.Parent then
				local nuevo = guardado.tam + crecimiento
				parte.Size = Vector3.new(
					math.max(0.05, nuevo.X),
					math.max(0.05, nuevo.Y),
					math.max(0.05, nuevo.Z))
				-- Crece hacia el lado que arrastras, no hacia los dos.
				parte.Position = self.anclaOrigen + guardado.pos
					+ eje * paso / 2
			end
		end
	end)

	self.escalar.MouseButton1Up:Connect(function ()
		self.activo = false
		self:Refrescar()
	end)

	-- Girar ------------------------------------------------------------------
	self.girar.MouseButton1Down:Connect(function ()
		self.api.apuntar()
		self.activo = true
		self:_guardarOffsets()
		self.anclaGiro = self.ancla.CFrame
	end)

	self.girar.MouseDrag:Connect(function (eje, angulo)
		local vector = Vector3.FromAxis(eje)
		local giro = CFrame.fromAxisAngle(vector, self.api.encajarGiro(angulo))
		local base = self.anclaGiro * giro

		self.ancla.CFrame = base
		for parte, guardado in pairs(self.offsets) do
			if parte.Parent then
				parte.CFrame = base * guardado.cf
			end
		end
	end)

	self.girar.MouseButton1Up:Connect(function ()
		self.activo = false
		self:Refrescar()
	end)
end

--------------------------------------------------------------------------------

function Gizmos:Modo(modo)
	self.modo = modo
	self:Refrescar()
end

function Gizmos:Refrescar()
	local centro, tam = self:_caja()

	if not centro then
		self.mover.Visible = false
		self.escalar.Visible = false
		self.girar.Visible = false
		self.mover.Adornee = nil
		self.escalar.Adornee = nil
		self.girar.Adornee = nil
		return
	end

	self.ancla.Size = Vector3.new(math.max(tam.X, 0.2), math.max(tam.Y, 0.2),
	                              math.max(tam.Z, 0.2))
	self.ancla.CFrame = CFrame.new(centro)
	self.anclaOrigen = centro

	self.mover.Adornee = self.ancla
	self.escalar.Adornee = self.ancla
	self.girar.Adornee = self.ancla

	self.mover.Visible = (self.modo == "mover")
	self.escalar.Visible = (self.modo == "escalar")
	self.girar.Visible = (self.modo == "girar")
end

function Gizmos:Ocupado()
	return self.activo
end

return Gizmos
