--!nocheck
--[[
	Serializer -- convierte una construccion en una tabla y al reves.

	Vive en ReplicatedStorage porque lo usan los tres sitios: el editor para
	guardar, el servidor para validar y el lugar de juego para reconstruir.

	El formato usa arrays numerados en vez de claves con nombre. Es feo de leer
	pero cada parte ocupa la tercera parte, y eso importa: un DataStore admite
	4 MB por clave y una construccion grande se acerca rapido. Tambien se
	redondea todo a dos decimales por la misma razon.

	Nada de lo que llega del cliente se cree sin comprobar: el servidor pasa
	todo por Sanear() antes de guardarlo. Un cliente manipulado podria mandar
	tamanos absurdos, miles de partes o valores que revienten el lugar.
]]

local Serializer = {}

Serializer.VERSION = 2
Serializer.MAX_PARTES = 2500
Serializer.MAX_TAMANO = 2048        -- studs por eje
Serializer.MAX_DISTANCIA = 4096     -- del origen

-- Formas admitidas. El indice es lo que se guarda.
local FORMAS = {
	[0] = { clase = "Part", shape = Enum.PartType.Block },
	[1] = { clase = "Part", shape = Enum.PartType.Ball },
	[2] = { clase = "Part", shape = Enum.PartType.Cylinder },
	[3] = { clase = "WedgePart" },
	[4] = { clase = "CornerWedgePart" },
	[5] = { clase = "TrussPart" },
	[6] = { clase = "SpawnLocation" },
	[7] = { clase = "Seat" },
}
Serializer.FORMAS = FORMAS

-- Solo los materiales que existian en la epoca, para no romper la estetica.
local MATERIALES = {
	[0] = Enum.Material.Plastic,
	[1] = Enum.Material.SmoothPlastic,
	[2] = Enum.Material.Wood,
	[3] = Enum.Material.Slate,
	[4] = Enum.Material.Concrete,
	[5] = Enum.Material.CorrodedMetal,
	[6] = Enum.Material.DiamondPlate,
	[7] = Enum.Material.Foil,
	[8] = Enum.Material.Grass,
	[9] = Enum.Material.Ice,
	[10] = Enum.Material.Brick,
	[11] = Enum.Material.Sand,
	[12] = Enum.Material.Neon,
}
Serializer.MATERIALES = MATERIALES

local MATERIAL_INDICE = {}
for i, m in pairs(MATERIALES) do
	MATERIAL_INDICE[m] = i
end

local SUPERFICIES = {
	[0] = Enum.SurfaceType.Smooth,
	[1] = Enum.SurfaceType.Studs,
	[2] = Enum.SurfaceType.Inlet,
	[3] = Enum.SurfaceType.Universal,
	[4] = Enum.SurfaceType.Weld,
	[5] = Enum.SurfaceType.Glue,
	[6] = Enum.SurfaceType.SmoothNoOutlines,
}
Serializer.SUPERFICIES = SUPERFICIES

local SUPERFICIE_INDICE = {}
for i, s in pairs(SUPERFICIES) do
	SUPERFICIE_INDICE[s] = i
end

local CARAS = { "TopSurface", "BottomSurface", "FrontSurface",
                "BackSurface", "LeftSurface", "RightSurface" }

-- Los seis lados por los que se puede pegar un cartel o una calcomania.
local NORMALES = {
	[0] = Enum.NormalId.Front, [1] = Enum.NormalId.Back,
	[2] = Enum.NormalId.Top,   [3] = Enum.NormalId.Bottom,
	[4] = Enum.NormalId.Left,  [5] = Enum.NormalId.Right,
}
Serializer.NORMALES = NORMALES

local NORMAL_INDICE = {}
for i, n in pairs(NORMALES) do
	NORMAL_INDICE[n] = i
end

Serializer.MAX_TEXTO = 200
Serializer.MAX_ASSET = 9999999999999

--------------------------------------------------------------------------------

local function r2(n)
	return math.floor(n * 100 + 0.5) / 100
end

local function indiceDeForma(part)
	if part:IsA("SpawnLocation") then return 6 end
	if part:IsA("Seat") then return 7 end
	if part:IsA("TrussPart") then return 5 end
	if part:IsA("CornerWedgePart") then return 4 end
	if part:IsA("WedgePart") then return 3 end

	if part:IsA("Part") then
		if part.Shape == Enum.PartType.Ball then return 1 end
		if part.Shape == Enum.PartType.Cylinder then return 2 end
	end

	return 0
end

--------------------------------------------------------------------------------
-- Guardar
--------------------------------------------------------------------------------

function Serializer.Serializar(contenedor)
	local partes = {}

	for _, obj in ipairs(contenedor:GetDescendants()) do
		if obj:IsA("BasePart") then
			if #partes >= Serializer.MAX_PARTES then
				break
			end

			local pos = obj.Position
			local rx, ry, rz = obj.CFrame:ToOrientation()

			local superficies = 0
			for i, cara in ipairs(CARAS) do
				local idx = SUPERFICIE_INDICE[obj[cara]] or 0
				-- Seis caras de 3 bits cada una en un solo numero.
				superficies += idx * (8 ^ (i - 1))
			end

			local banderas = 0
			if obj.Anchored then banderas += 1 end
			if obj.CanCollide then banderas += 2 end

			-- Lo que cuelga de la parte: luz, cartel, calcomania, malla. Va en
			-- una tabla con claves cortas y solo si existe, porque la inmensa
			-- mayoria de las partes no lleva nada y no debe pagar por ello.
			local extras = nil

			local function anotar(clave, valor)
				extras = extras or {}
				extras[clave] = valor
			end

			for _, hijo in ipairs(obj:GetChildren()) do
				if hijo:IsA("PointLight") or hijo:IsA("SpotLight")
					or hijo:IsA("SurfaceLight") then
					local tipo = hijo:IsA("SpotLight") and 1
						or hijo:IsA("SurfaceLight") and 2 or 0
					anotar("l", {
						tipo, r2(hijo.Brightness), r2(hijo.Range),
						math.floor(hijo.Color.R * 255),
						math.floor(hijo.Color.G * 255),
						math.floor(hijo.Color.B * 255),
					})

				elseif hijo:IsA("SurfaceGui") then
					local etiqueta = hijo:FindFirstChildWhichIsA("TextLabel")
					if etiqueta then
						anotar("c", {
							NORMAL_INDICE[hijo.Face] or 0,
							tostring(etiqueta.Text):sub(1, Serializer.MAX_TEXTO),
							math.floor(etiqueta.TextColor3.R * 255),
							math.floor(etiqueta.TextColor3.G * 255),
							math.floor(etiqueta.TextColor3.B * 255),
						})
					end

				elseif hijo:IsA("Decal") then
					anotar("d", {
						NORMAL_INDICE[hijo.Face] or 0,
						tostring(hijo.Texture),
					})

				elseif hijo:IsA("SpecialMesh") then
					anotar("m", { tostring(hijo.MeshId), tostring(hijo.TextureId),
						r2(hijo.Scale.X), r2(hijo.Scale.Y), r2(hijo.Scale.Z) })
				end
			end

			table.insert(partes, {
				indiceDeForma(obj),
				{ r2(obj.Size.X), r2(obj.Size.Y), r2(obj.Size.Z) },
				{ r2(pos.X), r2(pos.Y), r2(pos.Z) },
				{ r2(math.deg(rx)), r2(math.deg(ry)), r2(math.deg(rz)) },
				obj.BrickColor.Number,
				MATERIAL_INDICE[obj.Material] or 0,
				math.floor(obj.Transparency * 100),
				math.floor(obj.Reflectance * 100),
				banderas,
				superficies,
				extras,
			})
		end
	end

	return { v = Serializer.VERSION, partes = partes }
end

--------------------------------------------------------------------------------
-- Comprobar lo que llega del cliente
--------------------------------------------------------------------------------

local function numeroSano(n, limite)
	return type(n) == "number" and n == n            -- descarta NaN
		and n ~= math.huge and n ~= -math.huge
		and math.abs(n) <= limite
end

local function vectorSano(v, limite)
	return type(v) == "table" and #v == 3
		and numeroSano(v[1], limite) and numeroSano(v[2], limite)
		and numeroSano(v[3], limite)
end


--- Los extras vienen del cliente igual que todo lo demas. Un texto sin limite
--- o un id de asset absurdo no revientan el juego, pero si el DataStore, asi
--- que se recortan aqui.
local function sanearExtras(extras)
	if type(extras) ~= "table" then
		return nil
	end

	local limpio = nil

	local function guardar(clave, valor)
		limpio = limpio or {}
		limpio[clave] = valor
	end

	local l = extras.l
	if type(l) == "table" and #l >= 6 then
		guardar("l", {
			math.clamp(math.floor(tonumber(l[1]) or 0), 0, 2),
			math.clamp(tonumber(l[2]) or 1, 0, 10),
			math.clamp(tonumber(l[3]) or 16, 0, 60),
			math.clamp(math.floor(tonumber(l[4]) or 255), 0, 255),
			math.clamp(math.floor(tonumber(l[5]) or 255), 0, 255),
			math.clamp(math.floor(tonumber(l[6]) or 255), 0, 255),
		})
	end

	local c = extras.c
	if type(c) == "table" and type(c[2]) == "string" then
		guardar("c", {
			math.clamp(math.floor(tonumber(c[1]) or 0), 0, 5),
			c[2]:sub(1, Serializer.MAX_TEXTO),
			math.clamp(math.floor(tonumber(c[3]) or 30), 0, 255),
			math.clamp(math.floor(tonumber(c[4]) or 30), 0, 255),
			math.clamp(math.floor(tonumber(c[5]) or 30), 0, 255),
		})
	end

	local d = extras.d
	if type(d) == "table" and type(d[2]) == "string" then
		guardar("d", {
			math.clamp(math.floor(tonumber(d[1]) or 0), 0, 5),
			d[2]:sub(1, 120),
		})
	end

	local m = extras.m
	if type(m) == "table" and type(m[1]) == "string" then
		guardar("m", {
			m[1]:sub(1, 120),
			type(m[2]) == "string" and m[2]:sub(1, 120) or "",
			math.clamp(tonumber(m[3]) or 1, 0.01, 100),
			math.clamp(tonumber(m[4]) or 1, 0.01, 100),
			math.clamp(tonumber(m[5]) or 1, 0.01, 100),
		})
	end

	return limpio
end

--- Devuelve (datosLimpios, motivo). Si el motivo no es nil, se rechaza.
function Serializer.Sanear(datos)
	if type(datos) ~= "table" or type(datos.partes) ~= "table" then
		return nil, "formato invalido"
	end

	if #datos.partes == 0 then
		return nil, "la construccion esta vacia"
	end

	if #datos.partes > Serializer.MAX_PARTES then
		return nil, ("demasiadas partes (%d, el maximo es %d)")
			:format(#datos.partes, Serializer.MAX_PARTES)
	end

	local limpias = {}

	for i, p in ipairs(datos.partes) do
		if type(p) ~= "table" or #p < 10 then
			return nil, ("la parte %d esta incompleta"):format(i)
		end

		if not vectorSano(p[2], Serializer.MAX_TAMANO) then
			return nil, ("tamano invalido en la parte %d"):format(i)
		end
		if not vectorSano(p[3], Serializer.MAX_DISTANCIA) then
			return nil, ("posicion invalida en la parte %d"):format(i)
		end
		if not vectorSano(p[4], 720) then
			return nil, ("rotacion invalida en la parte %d"):format(i)
		end

		-- Una parte de tamano cero o negativo cuelga el motor de fisica.
		for eje = 1, 3 do
			p[2][eje] = math.clamp(p[2][eje], 0.05, Serializer.MAX_TAMANO)
		end

		local forma = math.floor(tonumber(p[1]) or 0)
		if not FORMAS[forma] then forma = 0 end

		local material = math.floor(tonumber(p[6]) or 0)
		if not MATERIALES[material] then material = 0 end

		local color = math.floor(tonumber(p[5]) or 194)
		if not BrickColor.new(color) then color = 194 end

		table.insert(limpias, {
			forma,
			p[2], p[3], p[4],
			color,
			material,
			math.clamp(math.floor(tonumber(p[7]) or 0), 0, 100),
			math.clamp(math.floor(tonumber(p[8]) or 0), 0, 100),
			math.clamp(math.floor(tonumber(p[9]) or 3), 0, 3),
			math.clamp(math.floor(tonumber(p[10]) or 0), 0, 262143),
			sanearExtras(p[11]),
		})
	end

	return { v = Serializer.VERSION, partes = limpias }
end

--------------------------------------------------------------------------------
-- Reconstruir
--------------------------------------------------------------------------------

function Serializer.Deserializar(datos, padre)
	local modelo = Instance.new("Model")
	modelo.Name = "Creacion"

	for _, p in ipairs(datos.partes or {}) do
		local forma = FORMAS[p[1]] or FORMAS[0]
		local ok, parte = pcall(Instance.new, forma.clase)

		if ok and parte then
			parte.Size = Vector3.new(p[2][1], p[2][2], p[2][3])

			if forma.shape and parte:IsA("Part") then
				parte.Shape = forma.shape
			end

			parte.CFrame = CFrame.new(p[3][1], p[3][2], p[3][3])
				* CFrame.fromOrientation(math.rad(p[4][1]), math.rad(p[4][2]),
				                         math.rad(p[4][3]))

			parte.BrickColor = BrickColor.new(p[5])
			parte.Material = MATERIALES[p[6]] or Enum.Material.Plastic
			parte.Transparency = p[7] / 100
			parte.Reflectance = p[8] / 100
			parte.Anchored = (p[9] % 2) == 1
			parte.CanCollide = math.floor(p[9] / 2) % 2 == 1

			local superficies = p[10]
			for i, cara in ipairs(CARAS) do
				local idx = math.floor(superficies / (8 ^ (i - 1))) % 8
				parte[cara] = SUPERFICIES[idx] or Enum.SurfaceType.Smooth
			end

			local extras = p[11]
			if type(extras) == "table" then
				local l = extras.l
				if l then
					local clases = { [0] = "PointLight", [1] = "SpotLight",
					                 [2] = "SurfaceLight" }
					local luz = Instance.new(clases[l[1]] or "PointLight")
					luz.Brightness = l[2]
					luz.Range = l[3]
					luz.Color = Color3.fromRGB(l[4], l[5], l[6])
					luz.Parent = parte
				end

				local c = extras.c
				if c then
					local gui = Instance.new("SurfaceGui")
					gui.Face = NORMALES[c[1]] or Enum.NormalId.Front
					gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
					gui.PixelsPerStud = 50
					gui.Parent = parte

					local etiqueta = Instance.new("TextLabel")
					etiqueta.BackgroundTransparency = 1
					etiqueta.Size = UDim2.fromScale(1, 1)
					etiqueta.Font = Enum.Font.Cartoon
					etiqueta.TextScaled = true
					etiqueta.Text = c[2]
					etiqueta.TextColor3 = Color3.fromRGB(c[3], c[4], c[5])
					etiqueta.Parent = gui
				end

				local d = extras.d
				if d then
					local calco = Instance.new("Decal")
					calco.Face = NORMALES[d[1]] or Enum.NormalId.Front
					calco.Texture = d[2]
					calco.Parent = parte
				end

				local m = extras.m
				if m and m[1] ~= "" then
					local malla = Instance.new("SpecialMesh")
					malla.MeshType = Enum.MeshType.FileMesh
					malla.MeshId = m[1]
					malla.TextureId = m[2] or ""
					malla.Scale = Vector3.new(m[3] or 1, m[4] or 1, m[5] or 1)
					malla.Parent = parte
				end
			end

			parte.Parent = modelo
		end
	end

	modelo.Parent = padre
	return modelo
end

function Serializer.ContarPartes(datos)
	return datos and datos.partes and #datos.partes or 0
end

return Serializer
