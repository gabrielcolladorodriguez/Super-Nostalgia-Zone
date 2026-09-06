--!nocheck
--[[
	Ui -- la interfaz de Bygone Studios.

	Dos reglas que vienen de fallos reales, no de gusto:

	1. La esquina superior izquierda es del boton de Roblox, del chat y del
	   microfono. Nada nuestro se ancla ahi. La barra va CENTRADA arriba, y en
	   tactil baja al pie, que es donde llega el pulgar.

	2. Ningun panel tiene la altura escrita a mano. Todos crecen con su
	   contenido (ver Ventanas.lua). Antes se escribia "este panel mide 60" y en
	   cuanto una rejilla ganaba una fila, los botones se salian por debajo y se
	   comian la seccion siguiente. Ahora anadir materiales o formas no puede
	   volver a romper nada.

	Las ventanas se arrastran por su barra, se pliegan y se cierran. El menu
	`Windows` de la barra las vuelve a abrir.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Ventanas = require(script.Parent:WaitForChild("Ventanas"))
local Piezas = require(script.Parent:WaitForChild("Piezas"))

local Ui = {}

local function new(clase, props, padre)
	local i = Instance.new(clase)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = padre
	return i
end

function Ui.Crear(api)
	local UI = api.Palette.UI
	local Palette = api.Palette
	local estado = api.estado
	local TACTIL = api.TACTIL
	local player = Players.LocalPlayer

	local pantalla = new("ScreenGui", {
		Name = "BygoneStudios", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 4000,
	}, player:WaitForChild("PlayerGui"))

	local raiz = new("Frame", {
		Name = "Raiz", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, pantalla)

	local escala = new("UIScale", { Scale = 1 }, raiz)

	local function ajustar()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		if not vp or vp.X == 0 then return end
		escala.Scale = math.clamp(math.min(vp.X / 1180, vp.Y / 740), 0.58, 1)
	end

	----------------------------------------------------------------------------
	-- Piezas de interfaz
	----------------------------------------------------------------------------

	local function bisel(marco)
		new("Frame", { BackgroundColor3 = UI.LUZ, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1) }, marco)
		new("Frame", { BackgroundColor3 = UI.OSCURO, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1) }, marco)
	end

	local function boton(texto, ancho, alto, padre, alPulsar)
		local b = new("TextButton", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = TACTIL and 14 or 13, TextColor3 = UI.TEXTO,
			Text = texto, AutoButtonColor = true,
			Size = UDim2.fromOffset(ancho, alto or (TACTIL and 32 or 25)),
		}, padre)
		bisel(b)
		if alPulsar then b.Activated:Connect(alPulsar) end
		return b
	end

	--- Rejilla que crece hacia abajo sola.
	local function rejilla(padre, anchoCelda, altoCelda)
		local r = new("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, padre)
		new("UIGridLayout", {
			CellSize = UDim2.fromOffset(anchoCelda, altoCelda),
			CellPadding = UDim2.fromOffset(3, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, r)
		return r
	end

	local function celda(texto, padre, alPulsar, orden)
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 12, TextColor3 = UI.TEXTO, Text = texto,
			AutoButtonColor = true, LayoutOrder = orden or 0,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, padre)
		if alPulsar then b.Activated:Connect(alPulsar) end
		return b
	end

	----------------------------------------------------------------------------
	-- Aviso
	----------------------------------------------------------------------------

	local aviso = new("TextLabel", {
		BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO, Text = "",
		AnchorPoint = Vector2.new(0.5, 1), Visible = false,
		Position = UDim2.new(0.5, 0, 1, TACTIL and -74 or -40),
		Size = UDim2.fromOffset(540, 28),
	}, raiz)

	local token = 0
	local function decir(texto, malo)
		token += 1
		local mio = token
		aviso.Text = texto
		aviso.TextColor3 = malo and UI.PELIGRO or UI.TEXTO
		aviso.Visible = true
		task.delay(4.5, function ()
			if token == mio then aviso.Visible = false end
		end)
	end

	----------------------------------------------------------------------------
	-- Dialogos
	----------------------------------------------------------------------------

	local function dialogo(titulo, ancho, alto)
		local fondo = new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55,
			BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 60,
			Visible = false,
		}, raiz)

		local caja = new("Frame", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			ZIndex = 61, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(ancho, alto),
		}, fondo)
		bisel(caja)

		local cabecera = new("Frame", {
			BackgroundColor3 = UI.TITULO, BorderSizePixel = 0, ZIndex = 62,
			Size = UDim2.new(1, -2, 0, 24), Position = UDim2.fromOffset(1, 1),
		}, caja)

		new("TextLabel", {
			BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 15, ZIndex = 63,
			TextColor3 = UI.BLANCO, TextXAlignment = Enum.TextXAlignment.Left,
			Text = "  " .. titulo, Size = UDim2.new(1, -30, 1, 0),
		}, cabecera)

		local cerrar = new("TextButton", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 0, ZIndex = 63,
			Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO, Text = "x",
			Size = UDim2.fromOffset(22, 18), Position = UDim2.new(1, -25, 0, 3),
		}, cabecera)
		cerrar.Activated:Connect(function () fondo.Visible = false end)

		return fondo, caja
	end

	local function campo(marcador, ancho, alto, padre, x, y, multi)
		local c = new("TextBox", {
			BackgroundColor3 = Color3.fromRGB(246, 246, 246), BorderSizePixel = 1,
			BorderColor3 = UI.OSCURO, ZIndex = 62, Font = UI.FUENTE, TextSize = 14,
			TextColor3 = UI.TEXTO, PlaceholderText = marcador, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = multi and Enum.TextYAlignment.Top
				or Enum.TextYAlignment.Center,
			MultiLine = multi or false, ClearTextOnFocus = false,
			Size = UDim2.fromOffset(ancho, alto), Position = UDim2.fromOffset(x, y),
		}, padre)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 3) }, c)
		return c
	end

	----------------------------------------------------------------------------
	-- Guardar y publicar
	----------------------------------------------------------------------------

	local fondoGuardar, cajaGuardar = dialogo("Save creation", 480, 286)
	local campoNombre = campo("Name", 450, 28, cajaGuardar, 14, 40)
	local campoDesc = campo("Description", 450, 74, cajaGuardar, 14, 76, true)

	local publicar = false
	local btnPublicar = boton("PRIVATE  -  only you can open it", 300, 30, cajaGuardar)
	btnPublicar.Position = UDim2.fromOffset(14, 160)
	btnPublicar.ZIndex = 62
	btnPublicar.Activated:Connect(function ()
		publicar = not publicar
		btnPublicar.Text = publicar and "PUBLIC  -  anyone can play it"
			or "PRIVATE  -  only you can open it"
		btnPublicar.BackgroundColor3 = publicar and UI.SELECCION or UI.FONDO
		btnPublicar.TextColor3 = publicar and UI.BLANCO or UI.TEXTO
	end)

	new("TextLabel", {
		BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 12, ZIndex = 62,
		TextColor3 = UI.TENUE, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = "You can switch this any time by saving again.",
		Size = UDim2.fromOffset(450, 16), Position = UDim2.fromOffset(14, 194),
	}, cajaGuardar)

	local guardando = false
	local btnGuardar = boton("Save", 140, 34, cajaGuardar)
	btnGuardar.Position = UDim2.fromOffset(14, 220)
	btnGuardar.ZIndex = 62

	btnGuardar.Activated:Connect(function ()
		if guardando then return end
		if api.contarPartes() == 0 then
			decir("There is nothing to save yet.", true)
			return
		end

		guardando = true
		btnGuardar.Text = "Saving..."

		local ok, r = pcall(function ()
			return api.canal.Guardar:InvokeServer({
				id = estado.id, nombre = campoNombre.Text,
				descripcion = campoDesc.Text, datos = api.instantanea(),
				publicar = publicar,
			})
		end)

		guardando = false
		btnGuardar.Text = "Save"

		if not ok then
			decir("The server did not answer. Try again.", true)
		elseif r and r.ok then
			estado.id = r.id
			estado.nombre = campoNombre.Text
			estado.descripcion = campoDesc.Text
			estado.sucio = false
			fondoGuardar.Visible = false
			decir(("Saved: %s (%d parts, %s)"):format(campoNombre.Text, r.partes,
				publicar and "public" or "private"))
		else
			decir((r and r.error) or "Could not save.", true)
		end
	end)

	local function abrirGuardar()
		campoNombre.Text = estado.nombre ~= "Untitled" and estado.nombre or ""
		campoDesc.Text = estado.descripcion or ""
		fondoGuardar.Visible = true
	end

	----------------------------------------------------------------------------
	-- Abrir
	----------------------------------------------------------------------------

	local fondoAbrir, cajaAbrir = dialogo("My creations", 500, 360)

	local lista = new("ScrollingFrame", {
		BackgroundColor3 = UI.HUECO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		ZIndex = 62, Size = UDim2.new(1, -28, 1, -46),
		Position = UDim2.fromOffset(14, 32), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 10,
	}, cajaAbrir)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, lista)

	local function pintarLista(fichas, vacio)
		for _, h in ipairs(lista:GetChildren()) do
			if not h:IsA("UIListLayout") then h:Destroy() end
		end

		if #fichas == 0 then
			new("TextLabel", { BackgroundTransparency = 1, Font = UI.FUENTE,
				TextSize = 14, TextColor3 = UI.TENUE, ZIndex = 63,
				Text = "  " .. vacio, TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 30) }, lista)
			return
		end

		for i, ficha in ipairs(fichas) do
			local fila = new("TextButton", {
				BackgroundColor3 = UI.SELECCION, BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 63, LayoutOrder = i, Font = UI.FUENTE,
				TextSize = 15, TextColor3 = UI.TEXTO, AutoButtonColor = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "  " .. (ficha.nombre or "Untitled"),
				Size = UDim2.new(1, -6, 0, TACTIL and 34 or 26),
			}, lista)

			new("TextLabel", { BackgroundTransparency = 1, Font = UI.FUENTE,
				TextSize = 13, TextColor3 = UI.TENUE, ZIndex = 63,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = ("%d parts  %s  "):format(ficha.partes or 0,
					ficha.publicada and "public" or "private"),
				Size = UDim2.new(0, 190, 1, 0), Position = UDim2.new(1, -190, 0, 0),
			}, fila)

			fila.MouseEnter:Connect(function () fila.BackgroundTransparency = 0.72 end)
			fila.MouseLeave:Connect(function () fila.BackgroundTransparency = 1 end)

			fila.Activated:Connect(function ()
				local ok, r = pcall(function ()
					return api.canal.Cargar:InvokeServer(ficha.id)
				end)
				if ok and r and r.ok then
					api.apuntar()
					api.restaurar(r.datos)
					estado.id = r.meta.id
					estado.nombre = r.meta.nombre
					estado.descripcion = r.meta.descripcion or ""
					fondoAbrir.Visible = false
					decir("Opened: " .. r.meta.nombre)
				else
					decir((r and r.error) or "Could not open it.", true)
				end
			end)
		end
	end

	local function abrirAbrir()
		fondoAbrir.Visible = true
		pintarLista({}, "Loading...")
		task.spawn(function ()
			local ok, r = pcall(function ()
				return api.canal.MisCreaciones:InvokeServer()
			end)
			if ok and r and r.ok then
				pintarLista(r.fichas, "You have not saved anything yet.")
			else
				pintarLista({}, (r and r.error) or "Could not read the list.")
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Asset por ID
	----------------------------------------------------------------------------

	local fondoAsset, cajaAsset = dialogo("Insert from an asset ID", 480, 250)

	new("TextLabel", { BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 12,
		ZIndex = 62, TextColor3 = UI.TENUE, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Paste a Roblox mesh, image or decal ID. Only public assets load;"
			.. " Roblox blocks anything private to another account.",
		Size = UDim2.fromOffset(450, 32), Position = UDim2.fromOffset(14, 32) },
		cajaAsset)

	local campoAsset = campo("rbxassetid://... or just the number", 450, 28,
	                         cajaAsset, 14, 70)
	local campoTextura = campo("Texture ID (optional, for meshes)", 450, 28,
	                           cajaAsset, 14, 104)

	local function normalizarId(texto)
		local n = tostring(texto):match("%d+")
		return n and ("rbxassetid://" .. n) or nil
	end

	local function aplicarAsset(tipo)
		local id = normalizarId(campoAsset.Text)
		if not id then
			decir("That does not look like an asset ID.", true) return
		end
		if #estado.seleccion == 0 then
			decir("Select a part first.", true) return
		end

		if tipo == "malla" then
			local t = normalizarId(campoTextura.Text) or ""
			api.aplicar(function (p) api.Extras.Malla(p, id, t) end)
		else
			api.aplicar(function (p) api.Extras.Calcomania(p, id) end)
		end
		fondoAsset.Visible = false
		decir("Applied to " .. #estado.seleccion .. " part(s).")
	end

	local bMalla = boton("Apply as mesh", 170, 32, cajaAsset,
		function () aplicarAsset("malla") end)
	bMalla.Position = UDim2.fromOffset(14, 150); bMalla.ZIndex = 62
	local bCalco = boton("Apply as decal", 170, 32, cajaAsset,
		function () aplicarAsset("calco") end)
	bCalco.Position = UDim2.fromOffset(192, 150); bCalco.ZIndex = 62

	----------------------------------------------------------------------------
	-- Cartel
	----------------------------------------------------------------------------

	local fondoCartel, cajaCartel = dialogo("Put a sign on it", 480, 200)
	local campoCartel = campo("Sign text", 450, 28, cajaCartel, 14, 44)

	local caraElegida = Enum.NormalId.Front
	local filaCaras = new("Frame", { BackgroundTransparency = 1, ZIndex = 62,
		Position = UDim2.fromOffset(14, 82), Size = UDim2.fromOffset(450, 28) },
		cajaCartel)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4) }, filaCaras)

	local botonesCara = {}
	for _, cara in ipairs({ "Front", "Back", "Top", "Left", "Right" }) do
		local b = boton(cara, 86, 26, filaCaras)
		b.ZIndex = 62
		botonesCara[cara] = b
		b.Activated:Connect(function ()
			caraElegida = Enum.NormalId[cara]
			for nombre, otro in pairs(botonesCara) do
				otro.BackgroundColor3 = (nombre == cara) and UI.SELECCION or UI.FONDO
				otro.TextColor3 = (nombre == cara) and UI.BLANCO or UI.TEXTO
			end
		end)
	end
	botonesCara.Front.BackgroundColor3 = UI.SELECCION
	botonesCara.Front.TextColor3 = UI.BLANCO

	local function abrirCartel()
		local p = estado.seleccion[1]
		local texto, cara = nil, nil
		if p then
			texto, cara = api.Extras.LeerCartel(p)
		end
		campoCartel.Text = texto or ""
		if cara then
			for nombre, b in pairs(botonesCara) do
				local activo = (Enum.NormalId[nombre] == cara)
				b.BackgroundColor3 = activo and UI.SELECCION or UI.FONDO
				b.TextColor3 = activo and UI.BLANCO or UI.TEXTO
				if activo then caraElegida = cara end
			end
		end
		fondoCartel.Visible = true
	end

	local bCartel = boton(#estado.seleccion > 0 and "Apply text" or "Add sign",
	                      160, 32, cajaCartel, function ()
		if #estado.seleccion == 0 then decir("Select a part first.", true) return end
		if #campoCartel.Text == 0 then decir("Write something first.", true) return end
		api.aplicar(function (p) api.Extras.Cartel(p, campoCartel.Text, caraElegida) end)
		fondoCartel.Visible = false
		decir("Sign added.")
	end)
	bCartel.Position = UDim2.fromOffset(14, 124); bCartel.ZIndex = 62

	----------------------------------------------------------------------------
	-- Las ventanas
	----------------------------------------------------------------------------

	local ANCHO = 258
	local X = UDim2.new(1, -(ANCHO + 12), 0, 0)

	local vParts = Ventanas.new(UI, raiz, "Parts", ANCHO,
		UDim2.new(1, -(ANCHO + 12), 0, UI.MARGEN_SUPERIOR), TACTIL)
	local vBuild = Ventanas.new(UI, raiz, "Build", ANCHO,
		UDim2.new(1, -(ANCHO + 12), 0, UI.MARGEN_SUPERIOR + 230), TACTIL)
	local vLook = Ventanas.new(UI, raiz, "Appearance", ANCHO,
		UDim2.new(1, -(ANCHO + 12), 0, UI.MARGEN_SUPERIOR + 470), TACTIL)
	local vSel = Ventanas.new(UI, raiz, "Selection", 216,
		UDim2.new(0, 12, 0, UI.MARGEN_SUPERIOR + 210), TACTIL)
	local vXform = Ventanas.new(UI, raiz, "Transform", 216,
		UDim2.new(0, 12, 0, UI.MARGEN_SUPERIOR), TACTIL)

	local ventanas = { vParts, vBuild, vLook, vSel, vXform }

	-- Parts ------------------------------------------------------------------
	do
		local r = vParts:Seccion("Shapes", 1)
		local rej = rejilla(r, 78, 24)
		local botones = {}

		for i, forma in ipairs(Piezas.FORMAS) do
			local b = celda(forma.nombre, rej, nil, i)
			botones[i] = b
			b.Activated:Connect(function ()
				estado.forma = i
				for j, otro in ipairs(botones) do
					otro.BackgroundColor3 = (j == i) and UI.SELECCION or UI.PANEL
					otro.TextColor3 = (j == i) and UI.BLANCO or UI.TEXTO
				end
				local _, err = api.colocar()
				if err then decir(err, true) end
			end)
		end
		botones[1].BackgroundColor3 = UI.SELECCION
		botones[1].TextColor3 = UI.BLANCO
	end

	-- Build (prefabs) --------------------------------------------------------
	do
		local r = vBuild:Seccion("Ready-made pieces", 1)
		local rej = rejilla(r, 120, 24)

		for i, prefab in ipairs(Piezas.PREFABS) do
			local b = celda(prefab.nombre, rej, function ()
				local _, err = api.colocarPrefab(prefab)
				decir(err or (prefab.nombre .. ": " .. prefab.descripcion), err ~= nil)
			end, i)
		end

		local nota = vBuild:Seccion("", 2)
		new("TextLabel", { BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 11,
			TextColor3 = UI.TENUE, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Each piece drops in as ordinary parts. Move, resize or delete"
				.. " any of them afterwards.",
			Size = UDim2.new(1, 0, 0, 30) }, nota)
	end

	-- Appearance -------------------------------------------------------------
	do
		local rc = vLook:Seccion("Colour", 1)
		local rej = rejilla(rc, 28, 14)
		for i, numero in ipairs(Palette.COLORES) do
			local bc = BrickColor.new(numero)
			local c = new("TextButton", {
				BackgroundColor3 = bc.Color, BorderSizePixel = 1,
				BorderColor3 = UI.OSCURO, Text = "", AutoButtonColor = true,
				LayoutOrder = i,
			}, rej)
			c.Activated:Connect(function ()
				estado.color = numero
				api.aplicar(function (p) p.BrickColor = bc end)
				decir(bc.Name)
			end)
		end

		local rm = vLook:Seccion("Material", 2)
		local rejM = rejilla(rm, 60, 20)
		for _, mat in ipairs(Palette.MATERIALES) do
			celda(mat.nombre, rejM, function ()
				estado.material = mat.indice
				local enum = api.Serializer.MATERIALES[mat.indice]
				api.aplicar(function (p) p.Material = enum end)
			end)
		end

		local rs = vLook:Seccion("Surface (top)", 3)
		local rejS = rejilla(rs, 80, 20)
		for _, sup in ipairs(Palette.SUPERFICIES) do
			celda(sup.nombre, rejS, function ()
				estado.superficieArriba = sup.enum
				api.aplicar(function (p) p.TopSurface = sup.enum end)
			end)
		end

		local re = vLook:Seccion("Add to selection", 4)
		local rejE = rejilla(re, 80, 22)
		celda("Light", rejE, function ()
			if not api.aplicar(function (p) api.Extras.Luz(p, "Point") end) then
				decir("Select a part first.", true)
			end
		end)
		celda("Spotlight", rejE, function ()
			if not api.aplicar(function (p) api.Extras.Luz(p, "Spot") end) then
				decir("Select a part first.", true)
			end
		end)
		celda("Sign / text", rejE, abrirCartel)
		celda("Asset ID", rejE, function () fondoAsset.Visible = true end)
		celda("Clear", rejE, function ()
			if not api.aplicar(api.Extras.Limpiar) then
				decir("Select a part first.", true)
			end
		end)
		celda("Baseplate", rejE, function ()
			api.seleccionar({ api.suelo }, false)
			decir("Baseplate selected. Change its colour, surface or size.")
		end)
	end

	-- Selection --------------------------------------------------------------
	do
		local r = vSel:Seccion("Actions", 1)
		local rej = rejilla(r, 66, 24)

		local acciones = {
			{ "Copy", function () api.duplicar() end },
			{ "Delete", function () api.borrar() end },
			{ "Anchor", function () api.aplicar(function (p) p.Anchored = true end) end },
			{ "Free", function () api.aplicar(function (p) p.Anchored = false end) end },
			{ "Solid", function () api.aplicar(function (p) p.CanCollide = true end) end },
			{ "Pass", function () api.aplicar(function (p) p.CanCollide = false end) end },
			{ "Ghost", function ()
				api.aplicar(function (p)
					p.Transparency = p.Transparency > 0 and 0 or 0.5
				end)
			end },
			{ "Shine", function ()
				api.aplicar(function (p)
					p.Reflectance = p.Reflectance > 0 and 0 or 0.4
				end)
			end },
			{ "Focus", function () api.centrar() end },
			{ "All", function () api.seleccionarTodo() end },
			{ "None", function () api.limpiarSeleccion() end },
			{ "Grid", function ()
				estado.rejilla = estado.rejilla > 0 and 0 or 1
				decir(estado.rejilla > 0 and "Grid: on" or "Grid: off")
			end },
		}

		for _, a in ipairs(acciones) do
			celda(a[1], rej, a[2])
		end
	end

	-- Transform (numeros exactos) --------------------------------------------
	local camposXform = {}
	do
		local function fila(etiqueta, clave, orden)
			local r = vXform:Seccion(etiqueta, orden)
			local caja = new("Frame", { BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22) }, r)
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 3) }, caja)

			camposXform[clave] = {}
			for i, eje in ipairs({ "X", "Y", "Z" }) do
				local c = new("TextBox", {
					BackgroundColor3 = Color3.fromRGB(246, 246, 246),
					BorderSizePixel = 1, BorderColor3 = UI.OSCURO, Font = UI.FUENTE,
					TextSize = 12, TextColor3 = UI.TEXTO, Text = "",
					PlaceholderText = eje, ClearTextOnFocus = false,
					Size = UDim2.fromOffset(64, 22), LayoutOrder = i,
				}, caja)
				camposXform[clave][i] = c

				c.FocusLost:Connect(function (enter)
					if enter then api.aplicarTransform(clave, camposXform[clave]) end
				end)
			end
		end

		fila("Position", "pos", 1)
		fila("Size", "tam", 2)
		fila("Rotation", "rot", 3)

		local nota = vXform:Seccion("", 4)
		new("TextLabel", { BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 11,
			TextColor3 = UI.TENUE, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Type a number and press Enter. Leave a box empty to keep it.",
			Size = UDim2.new(1, 0, 0, 26) }, nota)
	end

	----------------------------------------------------------------------------
	-- Barra principal
	----------------------------------------------------------------------------

	local barra = new("Frame", {
		Name = "Barra", BackgroundColor3 = UI.FONDO, BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(TACTIL and 700 or 776, TACTIL and 44 or 36),
	}, raiz)
	bisel(barra)

	if TACTIL then
		barra.AnchorPoint = Vector2.new(0.5, 1)
		barra.Position = UDim2.new(0.5, 0, 1, -10)
	end

	local fila = new("Frame", { BackgroundTransparency = 1,
		Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 1, -10) }, barra)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 3),
		VerticalAlignment = Enum.VerticalAlignment.Center }, fila)

	local orden = 0
	local function enBarra(texto, ancho, fn)
		orden += 1
		local b = boton(texto, ancho, nil, fila, fn)
		b.LayoutOrder = orden
		return b
	end

	local botonesModo = {}
	local function refrescarModo()
		for modo, b in pairs(botonesModo) do
			local activo = (estado.modo == modo)
			b.BackgroundColor3 = activo and UI.SELECCION or UI.FONDO
			b.TextColor3 = activo and UI.BLANCO or UI.TEXTO
		end
	end

	for _, par in ipairs({ { "Move", "mover" }, { "Rotate", "girar" },
	                       { "Scale", "escalar" } }) do
		botonesModo[par[2]] = enBarra(par[1], 60, function ()
			api.modo(par[2]); refrescarModo()
		end)
	end

	enBarra("New", 50, function ()
		api.vaciar(); estado.id = nil
		estado.nombre = "Untitled"; estado.descripcion = ""
		decir("New creation.")
	end)
	enBarra("Open", 54, abrirAbrir)
	enBarra("Save", 54, abrirGuardar)
	enBarra("Undo", 54, api.deshacer)
	enBarra("Redo", 54, api.rehacer)

	-- Menu de ventanas -------------------------------------------------------
	local menuVentanas = new("Frame", {
		BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		Visible = false, ZIndex = 30, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 190, 0, TACTIL and -170 or 48),
		Size = UDim2.fromOffset(150, 5 * 26 + 10),
	}, raiz)
	new("UIListLayout", { Padding = UDim.new(0, 2) }, menuVentanas)
	new("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5) },
		menuVentanas)

	if TACTIL then
		menuVentanas.AnchorPoint = Vector2.new(0.5, 1)
		menuVentanas.Position = UDim2.new(0.5, 190, 1, -60)
	end

	for _, v in ipairs(ventanas) do
		local b = boton(v.titulo, 140, 24, menuVentanas)
		b.ZIndex = 31
		b.Activated:Connect(function ()
			v:Mostrar(not v:Visible())
			b.BackgroundColor3 = v:Visible() and UI.SELECCION or UI.FONDO
			b.TextColor3 = v:Visible() and UI.BLANCO or UI.TEXTO
		end)
		b.BackgroundColor3 = UI.SELECCION
		b.TextColor3 = UI.BLANCO
	end

	enBarra("Windows", 82, function ()
		menuVentanas.Visible = not menuVentanas.Visible
	end)

	enBarra("Exit", 50, function ()
		local hub = game:GetService("ReplicatedStorage"):FindFirstChild("HubPlaceId")
		if hub and hub.Value > 0 then
			pcall(function ()
				game:GetService("TeleportService"):Teleport(hub.Value, player)
			end)
		end
	end)

	----------------------------------------------------------------------------
	-- Contador
	----------------------------------------------------------------------------

	local contador = new("TextLabel", {
		BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		Font = UI.FUENTE, TextSize = 13, TextColor3 = UI.TEXTO, Text = "",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, TACTIL and -60 or -10),
		Size = UDim2.fromOffset(330, 22),
	}, raiz)
	bisel(contador)

	local ultimo, ultimaSel, ultimoModo = -1, -1, ""

	local function refrescarContador()
		local n = api.contarPartes()
		local sel = #estado.seleccion

		if n ~= ultimo or sel ~= ultimaSel or estado.modo ~= ultimoModo then
			ultimo, ultimaSel, ultimoModo = n, sel, estado.modo
			contador.Text = ("%d / %d parts    %d selected    %s    grid %s")
				:format(n, api.Serializer.MAX_PARTES, sel, estado.modo,
					estado.rejilla > 0 and "on" or "off")
			contador.TextColor3 = (n > api.Serializer.MAX_PARTES * 0.9)
				and UI.PELIGRO or UI.TEXTO

			-- Los campos numericos siguen a la seleccion.
			local p = estado.seleccion[1]
			if p then
				local rx, ry, rz = p.CFrame:ToOrientation()
				local valores = {
					pos = { p.Position.X, p.Position.Y, p.Position.Z },
					tam = { p.Size.X, p.Size.Y, p.Size.Z },
					rot = { math.deg(rx), math.deg(ry), math.deg(rz) },
				}
				for clave, cajas in pairs(camposXform) do
					for i, caja in ipairs(cajas) do
						if not caja:IsFocused() then
							caja.Text = ("%.2f"):format(valores[clave][i])
						end
					end
				end
			end
		end
	end

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	end
	ajustar()
	refrescarModo()

	if TACTIL then
		for _, v in ipairs(ventanas) do
			v:Mostrar(false)
		end
	end

	return {
		pantalla = pantalla,
		decir = decir,
		abrirGuardar = abrirGuardar,
		abrirAbrir = abrirAbrir,
		refrescarContador = refrescarContador,
		refrescarModo = refrescarModo,
		refrescarEstado = refrescarContador,
	}
end

return Ui
