--!nocheck
--[[
	Ui -- la interfaz de Bygone Studios.

	Regla de colocacion, y no es un capricho: la esquina superior izquierda es
	del boton de Roblox y del menu del movil. Nada nuestro se ancla ahi. La
	barra de herramientas va CENTRADA arriba, los paneles a la DERECHA, y los
	avisos abajo. En tactil la barra baja al pie, que es donde llega el pulgar.

	Todo esta en `offset` dentro de un contenedor con UIScale, asi que la
	interfaz entera encoge de golpe en pantallas pequenas sin recolocar nada.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Ui = {}

local function new(clase, props, padre)
	local inst = Instance.new(clase)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = padre
	return inst
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
		-- Por debajo de 900 px de ancho la interfaz encoge; nunca crece de mas.
		escala.Scale = math.clamp(math.min(vp.X / 1100, vp.Y / 700), 0.62, 1)
	end

	----------------------------------------------------------------------------
	-- Piezas basicas
	----------------------------------------------------------------------------

	local function bisel(marco, hundido)
		new("Frame", { BackgroundColor3 = hundido and UI.OSCURO or UI.LUZ,
			BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), ZIndex = marco.ZIndex,
		}, marco)
		new("Frame", { BackgroundColor3 = hundido and UI.LUZ or UI.OSCURO,
			BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1), ZIndex = marco.ZIndex,
		}, marco)
	end

	local function boton(texto, ancho, alto, padre, alPulsar)
		local b = new("TextButton", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = TACTIL and 15 or 14, TextColor3 = UI.TEXTO,
			Text = texto, AutoButtonColor = true,
			Size = UDim2.fromOffset(ancho, alto or (TACTIL and 34 or 26)),
		}, padre)
		bisel(b)
		if alPulsar then
			b.Activated:Connect(alPulsar)
		end
		return b
	end

	local function panel(nombre, ancho, alto, padre)
		local p = new("Frame", {
			Name = nombre, BackgroundColor3 = UI.FONDO, BorderSizePixel = 1,
			BorderColor3 = UI.OSCURO, Size = UDim2.fromOffset(ancho, alto),
		}, padre)
		bisel(p)

		new("TextLabel", {
			BackgroundColor3 = UI.TITULO, BorderSizePixel = 0, Font = UI.FUENTE,
			TextSize = 13, TextColor3 = UI.BLANCO, Text = " " .. nombre,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -2, 0, 20), Position = UDim2.fromOffset(1, 1),
		}, p)

		local cuerpo = new("Frame", {
			Name = "Cuerpo", BackgroundTransparency = 1,
			Position = UDim2.fromOffset(5, 24), Size = UDim2.new(1, -10, 1, -29),
		}, p)

		return p, cuerpo
	end

	----------------------------------------------------------------------------
	-- Aviso
	----------------------------------------------------------------------------

	local aviso = new("TextLabel", {
		BackgroundColor3 = UI.FONDO, BackgroundTransparency = 1, BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO, Font = UI.FUENTE, TextSize = 15,
		TextColor3 = UI.TEXTO, Text = "", AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -54), Size = UDim2.fromOffset(520, 28),
		Visible = false,
	}, raiz)

	local token = 0
	local function decir(texto, malo)
		token += 1
		local mio = token
		aviso.Text = texto
		aviso.TextColor3 = malo and UI.PELIGRO or UI.TEXTO
		aviso.BackgroundTransparency = 0.05
		aviso.Visible = true
		task.delay(4.5, function ()
			if token == mio then aviso.Visible = false end
		end)
	end

	----------------------------------------------------------------------------
	-- Barra principal: CENTRADA arriba, o abajo en tactil
	----------------------------------------------------------------------------

	local barra = new("Frame", {
		Name = "Barra", BackgroundColor3 = UI.FONDO, BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO, AnchorPoint = Vector2.new(0.5, 0),
		Position = TACTIL and UDim2.new(0.5, 0, 1, -62)
			or UDim2.new(0.5, 0, 0, UI.MARGEN_SUPERIOR - 46),
		Size = UDim2.fromOffset(TACTIL and 660 or 720, TACTIL and 46 or 38),
	}, raiz)
	bisel(barra)

	if TACTIL then
		barra.AnchorPoint = Vector2.new(0.5, 1)
		barra.Position = UDim2.new(0.5, 0, 1, -10)
	end

	local filaBarra = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 5),
		Size = UDim2.new(1, -12, 1, -10),
	}, barra)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, filaBarra)

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
			Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO, Text = "X",
			Size = UDim2.fromOffset(22, 18), Position = UDim2.new(1, -25, 0, 3),
		}, cabecera)
		cerrar.Activated:Connect(function () fondo.Visible = false end)

		return fondo, caja
	end

	local function campo(marcador, ancho, alto, padre, y, multi)
		local c = new("TextBox", {
			BackgroundColor3 = Color3.fromRGB(246, 246, 246), BorderSizePixel = 1,
			BorderColor3 = UI.OSCURO, ZIndex = 62, Font = UI.FUENTE, TextSize = 14,
			TextColor3 = UI.TEXTO, PlaceholderText = marcador, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = multi and Enum.TextYAlignment.Top
				or Enum.TextYAlignment.Center,
			MultiLine = multi or false, ClearTextOnFocus = false,
			Size = UDim2.fromOffset(ancho, alto), Position = UDim2.fromOffset(14, y),
		}, padre)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 3) }, c)
		return c
	end

	----------------------------------------------------------------------------
	-- Guardar
	----------------------------------------------------------------------------

	local fondoGuardar, cajaGuardar = dialogo("Save creation", 470, 262)
	local campoNombre = campo("Name", 440, 28, cajaGuardar, 40)
	local campoDesc = campo("Description (optional)", 440, 74, cajaGuardar, 76, true)

	local publicar = false
	local btnPublicar = boton("[  ]  Publish to the gallery", 250, 28, cajaGuardar)
	btnPublicar.Position = UDim2.fromOffset(14, 160)
	btnPublicar.ZIndex = 62
	btnPublicar.TextXAlignment = Enum.TextXAlignment.Left
	btnPublicar.Activated:Connect(function ()
		publicar = not publicar
		btnPublicar.Text = (publicar and "[X]" or "[  ]") .. "  Publish to the gallery"
		btnPublicar.BackgroundColor3 = publicar and UI.SELECCION or UI.FONDO
		btnPublicar.TextColor3 = publicar and UI.BLANCO or UI.TEXTO
	end)

	local guardando = false
	local btnGuardar = boton("Save", 130, 32, cajaGuardar)
	btnGuardar.Position = UDim2.fromOffset(14, 200)
	btnGuardar.ZIndex = 62

	btnGuardar.Activated:Connect(function ()
		if guardando then return end
		if api.contarPartes() == 0 then
			decir("There is nothing to save yet.", true)
			return
		end

		guardando = true
		btnGuardar.Text = "Saving..."

		local ok, respuesta = pcall(function ()
			return api.canal.Guardar:InvokeServer({
				id = estado.id,
				nombre = campoNombre.Text,
				descripcion = campoDesc.Text,
				datos = api.instantanea(),
				publicar = publicar,
			})
		end)

		guardando = false
		btnGuardar.Text = "Save"

		if not ok then
			decir("The server did not answer. Try again.", true)
		elseif respuesta and respuesta.ok then
			estado.id = respuesta.id
			estado.nombre = campoNombre.Text
			estado.sucio = false
			fondoGuardar.Visible = false
			decir(("Saved: %s (%d parts)"):format(campoNombre.Text, respuesta.partes))
		else
			decir((respuesta and respuesta.error) or "Could not save.", true)
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

	local fondoAbrir, cajaAbrir = dialogo("My creations", 470, 340)

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
			new("TextLabel", {
				BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 14,
				TextColor3 = UI.TENUE, ZIndex = 63, Text = "  " .. vacio,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 30),
			}, lista)
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

			new("TextLabel", {
				BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 13,
				TextColor3 = UI.TENUE, ZIndex = 63,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = ("%d parts%s  "):format(ficha.partes or 0,
					ficha.publicada and "  published" or ""),
				Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -170, 0, 0),
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
					estado.sucio = false
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
	-- Insertar por identificador de asset
	----------------------------------------------------------------------------

	local fondoAsset, cajaAsset = dialogo("Insert from an asset ID", 470, 250)

	new("TextLabel", {
		BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 13, ZIndex = 62,
		TextColor3 = UI.TENUE, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = "Paste a Roblox mesh, image or decal ID. Only public assets load;"
			.. " Roblox blocks anything private to another account.",
		Size = UDim2.fromOffset(440, 34), Position = UDim2.fromOffset(14, 32),
	}, cajaAsset)

	local campoAsset = campo("rbxassetid://... or just the number", 440, 28,
	                         cajaAsset, 72)
	local campoTextura = campo("Texture ID (optional, for meshes)", 440, 28,
	                           cajaAsset, 108)

	local function normalizarId(texto)
		local numero = tostring(texto):match("%d+")
		return numero and ("rbxassetid://" .. numero) or nil
	end

	local function aplicarAsset(tipo)
		local id = normalizarId(campoAsset.Text)
		if not id then
			decir("That does not look like an asset ID.", true)
			return
		end
		if #estado.seleccion == 0 then
			decir("Select a part first.", true)
			return
		end

		if tipo == "malla" then
			local textura = normalizarId(campoTextura.Text) or ""
			api.aplicar(function (p) api.Extras.Malla(p, id, textura) end)
			decir("Mesh applied to " .. #estado.seleccion .. " part(s).")
		else
			api.aplicar(function (p) api.Extras.Calcomania(p, id) end)
			decir("Decal applied to " .. #estado.seleccion .. " part(s).")
		end
		fondoAsset.Visible = false
	end

	boton("Apply as mesh", 160, 30, cajaAsset, function () aplicarAsset("malla") end)
		.Position = UDim2.fromOffset(14, 152)
	boton("Apply as decal", 160, 30, cajaAsset, function () aplicarAsset("calco") end)
		.Position = UDim2.fromOffset(182, 152)

	for _, b in ipairs(cajaAsset:GetChildren()) do
		if b:IsA("TextButton") then b.ZIndex = 62 end
	end

	----------------------------------------------------------------------------
	-- Cartel
	----------------------------------------------------------------------------

	local fondoCartel, cajaCartel = dialogo("Put a sign on it", 470, 200)
	local campoCartel = campo("Sign text", 440, 28, cajaCartel, 44)

	local caraElegida = Enum.NormalId.Front
	local filaCaras = new("Frame", {
		BackgroundTransparency = 1, ZIndex = 62,
		Position = UDim2.fromOffset(14, 82), Size = UDim2.fromOffset(440, 30),
	}, cajaCartel)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4) }, filaCaras)

	local botonesCara = {}
	for _, cara in ipairs({ "Front", "Back", "Top", "Left", "Right" }) do
		local b = boton(cara, 84, 26, filaCaras, nil)
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

	local btnCartel = boton("Add sign", 150, 30, cajaCartel, function ()
		if #estado.seleccion == 0 then
			decir("Select a part first.", true)
			return
		end
		local texto = campoCartel.Text
		if #texto == 0 then
			decir("Write something on it first.", true)
			return
		end
		api.aplicar(function (p) api.Extras.Cartel(p, texto, caraElegida) end)
		fondoCartel.Visible = false
		decir("Sign added.")
	end)
	btnCartel.Position = UDim2.fromOffset(14, 126)
	btnCartel.ZIndex = 62

	----------------------------------------------------------------------------
	-- Botones de la barra
	----------------------------------------------------------------------------

	local orden = 0
	local function enBarra(texto, ancho, fn)
		orden += 1
		local b = boton(texto, ancho, nil, filaBarra, fn)
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
		local b = enBarra(par[1], 64, function ()
			api.modo(par[2])
			refrescarModo()
		end)
		botonesModo[par[2]] = b
	end

	enBarra("|", 8, nil).Active = false

	enBarra("New", 54, function ()
		api.vaciar()
		estado.id = nil
		estado.nombre = "Untitled"
		estado.descripcion = ""
		decir("New creation.")
	end)
	enBarra("Open", 58, abrirAbrir)
	enBarra("Save", 58, abrirGuardar)

	enBarra("|", 8, nil).Active = false

	enBarra("Undo", 58, api.deshacer)
	enBarra("Redo", 58, api.rehacer)

	enBarra("|", 8, nil).Active = false

	enBarra("Exit", 54, function ()
		local hub = game:GetService("ReplicatedStorage"):FindFirstChild("HubPlaceId")
		if hub and hub.Value > 0 then
			pcall(function ()
				game:GetService("TeleportService"):Teleport(hub.Value, player)
			end)
		end
	end)

	----------------------------------------------------------------------------
	-- Panel de insertar (derecha, arriba)
	----------------------------------------------------------------------------

	local ladoDerecho = new("Frame", {
		Name = "LadoDerecho", BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, UI.MARGEN_SUPERIOR),
		Size = UDim2.fromOffset(250, 640), Visible = not TACTIL,
	}, raiz)

	local pInsertar, cInsertar = panel("Insert", 250, 176, ladoDerecho)

	local rejillaFormas = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, cInsertar)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(76, 26), CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, rejillaFormas)

	local botonesForma = {}
	for i, forma in ipairs(Palette.FORMAS) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 13, TextColor3 = UI.TEXTO,
			Text = forma.nombre, AutoButtonColor = true, LayoutOrder = i,
		}, rejillaFormas)
		botonesForma[i] = b

		b.Activated:Connect(function ()
			estado.forma = i
			for j, otro in ipairs(botonesForma) do
				otro.BackgroundColor3 = (j == i) and UI.SELECCION or UI.PANEL
				otro.TextColor3 = (j == i) and UI.BLANCO or UI.TEXTO
			end
			local _, err = api.colocar()
			if err then decir(err, true) end
		end)
	end
	botonesForma[1].BackgroundColor3 = UI.SELECCION
	botonesForma[1].TextColor3 = UI.BLANCO

	-- Extras
	local pExtras, cExtras = panel("Add to selection", 250, 96, ladoDerecho)
	pExtras.Position = UDim2.fromOffset(0, 182)

	local rejillaExtras = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, cExtras)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(76, 26), CellPadding = UDim2.fromOffset(4, 4),
	}, rejillaExtras)

	local function extraBoton(texto, fn)
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 13, TextColor3 = UI.TEXTO, Text = texto,
			AutoButtonColor = true,
		}, rejillaExtras)
		b.Activated:Connect(fn)
		return b
	end

	extraBoton("Light", function ()
		if not api.aplicar(function (p) api.Extras.Luz(p, "Point") end) then
			decir("Select a part first.", true)
		end
	end)
	extraBoton("Spotlight", function ()
		if not api.aplicar(function (p) api.Extras.Luz(p, "Spot") end) then
			decir("Select a part first.", true)
		end
	end)
	extraBoton("Sign", function () fondoCartel.Visible = true end)
	extraBoton("Asset ID", function () fondoAsset.Visible = true end)
	extraBoton("Clear", function ()
		if not api.aplicar(api.Extras.Limpiar) then
			decir("Select a part first.", true)
		end
	end)
	extraBoton("Baseplate", function ()
		api.seleccionar({ api.suelo }, false)
		decir("Baseplate selected: change its colour, surface or size.")
	end)

	-- Propiedades
	local pProps, cProps = panel("Properties", 250, 348, ladoDerecho)
	pProps.Position = UDim2.fromOffset(0, 284)

	local rejillaColor = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(238, 120),
	}, cProps)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(28, 14), CellPadding = UDim2.fromOffset(1, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, rejillaColor)

	for i, numero in ipairs(Palette.COLORES) do
		local bc = BrickColor.new(numero)
		local celda = new("TextButton", {
			BackgroundColor3 = bc.Color, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Text = "", AutoButtonColor = true, LayoutOrder = i,
		}, rejillaColor)
		celda.Activated:Connect(function ()
			estado.color = numero
			api.aplicar(function (p) p.BrickColor = bc end)
			decir(bc.Name)
		end)
	end

	local function seccion(texto, y, padre)
		return new("TextLabel", {
			BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 12,
			TextColor3 = UI.TENUE, Text = texto,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(230, 14),
		}, padre)
	end

	seccion("Material", 124, cProps)
	local filaMat = new("Frame", { BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 140), Size = UDim2.fromOffset(238, 60) }, cProps)
	new("UIGridLayout", { CellSize = UDim2.fromOffset(57, 17),
		CellPadding = UDim2.fromOffset(2, 2) }, filaMat)

	for _, mat in ipairs(Palette.MATERIALES) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 11, TextColor3 = UI.TEXTO,
			Text = mat.nombre, AutoButtonColor = true,
		}, filaMat)
		b.Activated:Connect(function ()
			estado.material = mat.indice
			local enum = api.Serializer.MATERIALES[mat.indice]
			api.aplicar(function (p) p.Material = enum end)
		end)
	end

	seccion("Surface (top)", 204, cProps)
	local filaSup = new("Frame", { BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 220), Size = UDim2.fromOffset(238, 40) }, cProps)
	new("UIGridLayout", { CellSize = UDim2.fromOffset(77, 17),
		CellPadding = UDim2.fromOffset(2, 2) }, filaSup)

	for _, sup in ipairs(Palette.SUPERFICIES) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 11, TextColor3 = UI.TEXTO,
			Text = sup.nombre, AutoButtonColor = true,
		}, filaSup)
		b.Activated:Connect(function ()
			estado.superficieArriba = sup.enum
			api.aplicar(function (p) p.TopSurface = sup.enum end)
		end)
	end

	seccion("Selection", 264, cProps)
	local filaSel = new("Frame", { BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 280), Size = UDim2.fromOffset(238, 60) }, cProps)
	new("UIGridLayout", { CellSize = UDim2.fromOffset(57, 24),
		CellPadding = UDim2.fromOffset(2, 2) }, filaSel)

	local acciones = {
		{ "Copy", function () api.duplicar() end },
		{ "Delete", function () api.borrar() end },
		{ "Anchor", function () api.aplicar(function (p) p.Anchored = true end) end },
		{ "Free", function () api.aplicar(function (p) p.Anchored = false end) end },
		{ "Ghost", function ()
			api.aplicar(function (p)
				p.Transparency = p.Transparency > 0 and 0 or 0.5
			end)
		end },
		{ "Focus", function () api.centrar() end },
		{ "Grid", function ()
			estado.rejilla = estado.rejilla > 0 and 0 or 1
			decir(estado.rejilla > 0 and "Grid: on" or "Grid: off")
		end },
		{ "Snap 45", function ()
			estado.giro = estado.giro == 45 and 15 or (estado.giro == 15 and 90 or 45)
			decir(("Rotation step: %d degrees"):format(estado.giro))
		end },
	}

	for _, accion in ipairs(acciones) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 12, TextColor3 = UI.TEXTO, Text = accion[1],
			AutoButtonColor = true,
		}, filaSel)
		b.Activated:Connect(accion[2])
	end

	----------------------------------------------------------------------------
	-- En tactil los paneles se abren y cierran, no ocupan la pantalla
	----------------------------------------------------------------------------

	if TACTIL then
		local btnPaneles = new("TextButton", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO, Text = "Tools",
			AutoButtonColor = true, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, UI.MARGEN_SUPERIOR),
			Size = UDim2.fromOffset(96, 40),
		}, raiz)
		bisel(btnPaneles)

		btnPaneles.Activated:Connect(function ()
			ladoDerecho.Visible = not ladoDerecho.Visible
			btnPaneles.BackgroundColor3 = ladoDerecho.Visible and UI.SELECCION or UI.FONDO
			btnPaneles.TextColor3 = ladoDerecho.Visible and UI.BLANCO or UI.TEXTO
		end)

		ladoDerecho.Position = UDim2.new(1, -10, 0, UI.MARGEN_SUPERIOR + 48)
	end

	----------------------------------------------------------------------------
	-- Contador, abajo a la derecha
	----------------------------------------------------------------------------

	local contador = new("TextLabel", {
		BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		Font = UI.FUENTE, TextSize = 13, TextColor3 = UI.TEXTO, Text = "",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, TACTIL and -68 or -10),
		Size = UDim2.fromOffset(300, 22),
	}, raiz)
	bisel(contador)

	local ultimo, ultimaSel, ultimoModo = -1, -1, ""

	local function refrescarContador()
		local n = api.contarPartes()
		local sel = #estado.seleccion

		if n ~= ultimo or sel ~= ultimaSel or estado.modo ~= ultimoModo then
			ultimo, ultimaSel, ultimoModo = n, sel, estado.modo
			contador.Text = ("  %d / %d parts   %d selected   %s   grid %s  ")
				:format(n, api.Serializer.MAX_PARTES, sel, estado.modo,
					estado.rejilla > 0 and "on" or "off")
			contador.TextColor3 = (n > api.Serializer.MAX_PARTES * 0.9)
				and UI.PELIGRO or UI.TEXTO
		end
	end

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	end
	ajustar()
	refrescarModo()

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
