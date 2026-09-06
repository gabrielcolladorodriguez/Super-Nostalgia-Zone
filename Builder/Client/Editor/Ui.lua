--!nocheck
--[[
	Ui -- la interfaz del editor, con la pinta del Studio de 2008.

	Vive aparte del editor a proposito: init.client.lua se ocupa de que hace el
	raton con el mundo, y esto de los paneles. Se hablan por la tabla `api`, que
	init pasa al crear la interfaz.

	Cuatro zonas:
	  arriba      barra de menu: nuevo, abrir, guardar, publicar, salir
	  izquierda   formas que insertar
	  derecha     propiedades de lo seleccionado
	  abajo       contador de partes y avisos
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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
	local player = Players.LocalPlayer

	local pantalla = new("ScreenGui", {
		Name = "BygoneStudio", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5000,
	}, player:WaitForChild("PlayerGui"))

	local function boton(texto, ancho, padre, alLlamar)
		local b = new("TextButton", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO, Text = texto,
			AutoButtonColor = true, Size = UDim2.fromOffset(ancho, 26),
		}, padre)
		if alLlamar then
			b.Activated:Connect(alLlamar)
		end
		return b
	end

	----------------------------------------------------------------------------
	-- Aviso de abajo
	----------------------------------------------------------------------------

	local aviso = new("TextLabel", {
		BackgroundColor3 = UI.FONDO, BackgroundTransparency = 1, BorderSizePixel = 0,
		Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO, Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -42), Size = UDim2.fromOffset(560, 26),
	}, pantalla)

	local avisoToken = 0

	local function decir(texto, malo)
		avisoToken += 1
		local mio = avisoToken

		aviso.Text = texto
		aviso.TextColor3 = malo and Color3.fromRGB(150, 40, 40) or UI.TEXTO
		aviso.BackgroundTransparency = 0.15

		task.delay(4, function ()
			if avisoToken == mio then
				aviso.Text = ""
				aviso.BackgroundTransparency = 1
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Barra superior
	----------------------------------------------------------------------------

	local barra = new("Frame", {
		Name = "Barra", BackgroundColor3 = UI.TITULO, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 32),
	}, pantalla)

	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, barra)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, barra)

	local titulo = new("TextLabel", {
		BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 16,
		TextColor3 = Color3.fromRGB(245, 245, 245),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "  Bygone Studio", Size = UDim2.fromOffset(190, 26), LayoutOrder = 0,
	}, barra)

	----------------------------------------------------------------------------
	-- Dialogos
	----------------------------------------------------------------------------

	local function dialogo(tituloTexto, alto)
		local fondo = new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
			BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 50,
			Visible = false,
		}, pantalla)

		local caja = new("Frame", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 0, ZIndex = 51,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(460, alto),
		}, fondo)

		local cabecera = new("Frame", {
			BackgroundColor3 = UI.TITULO, BorderSizePixel = 0, ZIndex = 52,
			Size = UDim2.new(1, -2, 0, 26), Position = UDim2.fromOffset(1, 1),
		}, caja)

		new("TextLabel", {
			BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 16, ZIndex = 53,
			TextColor3 = Color3.fromRGB(245, 245, 245),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "  " .. tituloTexto, Size = UDim2.new(1, -30, 1, 0),
		}, cabecera)

		local cerrar = new("TextButton", {
			BackgroundColor3 = UI.FONDO, BorderSizePixel = 0, ZIndex = 53,
			Font = UI.FUENTE, TextSize = 16, TextColor3 = UI.TEXTO, Text = "X",
			Size = UDim2.fromOffset(24, 20), Position = UDim2.new(1, -27, 0, 3),
		}, cabecera)
		cerrar.Activated:Connect(function () fondo.Visible = false end)

		return fondo, caja
	end

	----------------------------------------------------------------------------
	-- Guardar y publicar
	----------------------------------------------------------------------------

	local fondoGuardar, cajaGuardar = dialogo("Save creation", 250)

	local campoNombre = new("TextBox", {
		BackgroundColor3 = Color3.fromRGB(240, 240, 240), BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO, ZIndex = 52, Font = UI.FUENTE, TextSize = 15,
		TextColor3 = UI.TEXTO, PlaceholderText = "Name", Text = "",
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 46),
	}, cajaGuardar)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, campoNombre)

	local campoDesc = new("TextBox", {
		BackgroundColor3 = Color3.fromRGB(240, 240, 240), BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO, ZIndex = 52, Font = UI.FUENTE, TextSize = 14,
		TextColor3 = UI.TEXTO, PlaceholderText = "Description (optional)", Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, MultiLine = true,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -24, 0, 70), Position = UDim2.fromOffset(12, 82),
	}, cajaGuardar)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) },
		campoDesc)

	local publicarMarcado = false
	local btnPublicar = boton("[ ] Publish to the gallery", 240, cajaGuardar)
	btnPublicar.Position = UDim2.fromOffset(12, 162)
	btnPublicar.ZIndex = 52
	btnPublicar.TextXAlignment = Enum.TextXAlignment.Left
	btnPublicar.Activated:Connect(function ()
		publicarMarcado = not publicarMarcado
		btnPublicar.Text = (publicarMarcado and "[x]" or "[ ]")
			.. " Publish to the gallery"
	end)

	local guardando = false

	local btnConfirmar = boton("Save", 120, cajaGuardar)
	btnConfirmar.Position = UDim2.fromOffset(12, 200)
	btnConfirmar.ZIndex = 52

	btnConfirmar.Activated:Connect(function ()
		if guardando then
			return
		end

		local partes = api.contarPartes()
		if partes == 0 then
			decir("There is nothing to save yet.", true)
			return
		end

		guardando = true
		btnConfirmar.Text = "Saving..."

		local datos = api.instantanea()
		local peticion = {
			id = estado.id,
			nombre = campoNombre.Text,
			descripcion = campoDesc.Text,
			datos = datos,
			publicar = publicarMarcado,
		}

		local ok, respuesta = pcall(function ()
			return api.canal.Guardar:InvokeServer(peticion)
		end)

		guardando = false
		btnConfirmar.Text = "Save"

		if not ok then
			decir("The server did not answer. Try again.", true)
			return
		end

		if respuesta and respuesta.ok then
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

	local fondoAbrir, cajaAbrir = dialogo("My creations", 340)

	local lista = new("ScrollingFrame", {
		BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		ZIndex = 52, Size = UDim2.new(1, -24, 1, -80),
		Position = UDim2.fromOffset(12, 40),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 10,
	}, cajaAbrir)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, lista)

	local function pintarLista(fichas)
		for _, hijo in ipairs(lista:GetChildren()) do
			if hijo:IsA("TextButton") then hijo:Destroy() end
		end

		if #fichas == 0 then
			local vacio = new("TextLabel", {
				BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 15,
				TextColor3 = UI.TENUE, ZIndex = 53,
				Text = "  You have not saved anything yet.",
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 28),
			}, lista)
			vacio.Name = "Vacio"
			return
		end

		for i, ficha in ipairs(fichas) do
			local fila = new("TextButton", {
				BackgroundColor3 = UI.SELECCION, BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 53, LayoutOrder = i,
				Font = UI.FUENTE, TextSize = 15, TextColor3 = UI.TEXTO,
				TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
				Text = ("  %s"):format(ficha.nombre),
				Size = UDim2.new(1, -6, 0, 28),
			}, lista)

			new("TextLabel", {
				BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 13,
				TextColor3 = UI.TENUE, ZIndex = 53,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = ("%d parts%s  "):format(ficha.partes or 0,
					ficha.publicada and "  ·  published" or ""),
				Size = UDim2.new(0, 180, 1, 0), Position = UDim2.new(1, -180, 0, 0),
			}, fila)

			fila.MouseEnter:Connect(function () fila.BackgroundTransparency = 0.7 end)
			fila.MouseLeave:Connect(function () fila.BackgroundTransparency = 1 end)

			fila.Activated:Connect(function ()
				local ok, respuesta = pcall(function ()
					return api.canal.Cargar:InvokeServer(ficha.id)
				end)

				if ok and respuesta and respuesta.ok then
					api.apuntar()
					api.restaurar(respuesta.datos)
					estado.id = respuesta.meta.id
					estado.nombre = respuesta.meta.nombre
					estado.descripcion = respuesta.meta.descripcion or ""
					estado.sucio = false
					fondoAbrir.Visible = false
					decir(("Opened: %s"):format(respuesta.meta.nombre))
				else
					decir((respuesta and respuesta.error) or "Could not open it.", true)
				end
			end)
		end
	end

	local function abrirAbrir()
		fondoAbrir.Visible = true
		pintarLista({})

		task.spawn(function ()
			local ok, respuesta = pcall(function ()
				return api.canal.MisCreaciones:InvokeServer()
			end)

			if ok and respuesta and respuesta.ok then
				pintarLista(respuesta.fichas)
			else
				decir((respuesta and respuesta.error) or "Could not read the list.", true)
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Botones de la barra
	----------------------------------------------------------------------------

	boton("New", 60, barra, function ()
		api.vaciar()
		estado.id = nil
		estado.nombre = "Untitled"
		estado.descripcion = ""
		decir("New creation.")
	end).LayoutOrder = 1

	boton("Open", 60, barra, abrirAbrir).LayoutOrder = 2
	boton("Save", 60, barra, abrirGuardar).LayoutOrder = 3
	boton("Undo", 60, barra, api.deshacer).LayoutOrder = 4
	boton("Redo", 60, barra, api.rehacer).LayoutOrder = 5

	boton("Exit", 60, barra, function ()
		local hub = game:GetService("ReplicatedStorage"):FindFirstChild("HubPlaceId")
		if hub and hub.Value > 0 then
			pcall(function ()
				game:GetService("TeleportService"):Teleport(hub.Value, player)
			end)
		end
	end).LayoutOrder = 6

	----------------------------------------------------------------------------
	-- Panel de formas
	----------------------------------------------------------------------------

	local panelFormas = new("Frame", {
		Name = "Formas", BackgroundColor3 = UI.FONDO, BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO,
		Position = UDim2.fromOffset(8, 42), Size = UDim2.fromOffset(104, 300),
	}, pantalla)

	new("TextLabel", {
		BackgroundColor3 = UI.TITULO, BorderSizePixel = 0, Font = UI.FUENTE,
		TextSize = 14, TextColor3 = Color3.fromRGB(245, 245, 245), Text = "Insert",
		Size = UDim2.new(1, 0, 0, 22),
	}, panelFormas)

	local listaFormas = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 26),
		Size = UDim2.new(1, -8, 1, -30),
	}, panelFormas)
	new("UIListLayout", { Padding = UDim.new(0, 3) }, listaFormas)

	local botonesForma = {}

	for i, forma in ipairs(Palette.FORMAS) do
		local b = boton(forma.nombre, 96, listaFormas)
		b.LayoutOrder = i
		botonesForma[i] = b

		b.Activated:Connect(function ()
			estado.forma = i
			for j, otro in ipairs(botonesForma) do
				otro.BackgroundColor3 = (j == i) and UI.SELECCION or UI.FONDO
				otro.TextColor3 = (j == i) and UI.BLANCO or UI.TEXTO
			end
			api.colocar()
		end)
	end

	botonesForma[1].BackgroundColor3 = UI.SELECCION
	botonesForma[1].TextColor3 = UI.BLANCO

	----------------------------------------------------------------------------
	-- Panel de propiedades
	----------------------------------------------------------------------------

	local props = new("Frame", {
		Name = "Propiedades", BackgroundColor3 = UI.FONDO, BorderSizePixel = 1,
		BorderColor3 = UI.OSCURO, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 42), Size = UDim2.fromOffset(232, 430),
	}, pantalla)

	new("TextLabel", {
		BackgroundColor3 = UI.TITULO, BorderSizePixel = 0, Font = UI.FUENTE,
		TextSize = 14, TextColor3 = Color3.fromRGB(245, 245, 245),
		Text = "Properties", Size = UDim2.new(1, 0, 0, 22),
	}, props)

	-- Paleta de colores clasica
	local rejillaColor = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 28),
		Size = UDim2.fromOffset(220, 128),
	}, props)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(26, 14), CellPadding = UDim2.fromOffset(1, 1),
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
			api.aplicar(function (parte) parte.BrickColor = bc end)
			decir(bc.Name)
		end)
	end

	local function seccion(texto, y)
		return new("TextLabel", {
			BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 13,
			TextColor3 = UI.TENUE, Text = texto,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(8, y), Size = UDim2.fromOffset(200, 16),
		}, props)
	end

	seccion("Material", 162)
	local filaMaterial = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 180),
		Size = UDim2.fromOffset(220, 60),
	}, props)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(52, 18), CellPadding = UDim2.fromOffset(2, 2),
	}, filaMaterial)

	for _, mat in ipairs(Palette.MATERIALES) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 12, TextColor3 = UI.TEXTO,
			Text = mat.nombre, AutoButtonColor = true,
		}, filaMaterial)

		b.Activated:Connect(function ()
			estado.material = mat.indice
			local enum = api.Serializer.MATERIALES[mat.indice]
			api.aplicar(function (parte) parte.Material = enum end)
		end)
	end

	seccion("Top surface", 246)
	local filaSup = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 264),
		Size = UDim2.fromOffset(220, 42),
	}, props)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(70, 18), CellPadding = UDim2.fromOffset(2, 2),
	}, filaSup)

	for _, sup in ipairs(Palette.SUPERFICIES) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 12, TextColor3 = UI.TEXTO,
			Text = sup.nombre, AutoButtonColor = true,
		}, filaSup)

		b.Activated:Connect(function ()
			estado.superficieArriba = sup.enum
			api.aplicar(function (parte) parte.TopSurface = sup.enum end)
		end)
	end

	seccion("Selection", 312)
	local filaAcciones = new("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 330),
		Size = UDim2.fromOffset(220, 90),
	}, props)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(70, 24), CellPadding = UDim2.fromOffset(3, 3),
	}, filaAcciones)

	local acciones = {
		{ "Duplicate", function () api.duplicar() end },
		{ "Delete", function () api.borrar() end },
		{ "Rotate Y", function () api.girar(Vector3.yAxis) end },
		{ "Rotate X", function () api.girar(Vector3.xAxis) end },
		{ "Anchor", function ()
			api.aplicar(function (p) p.Anchored = true end)
			decir("Anchored")
		end },
		{ "Unanchor", function ()
			api.aplicar(function (p) p.Anchored = false end)
			decir("Free to fall")
		end },
		{ "Ghost", function ()
			api.aplicar(function (p)
				p.Transparency = p.Transparency > 0 and 0 or 0.5
			end)
		end },
		{ "Grid on/off", function ()
			estado.rejilla = estado.rejilla > 0 and 0 or 1
			decir(estado.rejilla > 0 and "Grid: on" or "Grid: off")
		end },
	}

	for _, accion in ipairs(acciones) do
		local b = new("TextButton", {
			BackgroundColor3 = UI.PANEL, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
			Font = UI.FUENTE, TextSize = 12, TextColor3 = UI.TEXTO,
			Text = accion[1], AutoButtonColor = true,
		}, filaAcciones)
		b.Activated:Connect(accion[2])
	end

	----------------------------------------------------------------------------
	-- Contador
	----------------------------------------------------------------------------

	local contador = new("TextLabel", {
		BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		Font = UI.FUENTE, TextSize = 14, TextColor3 = UI.TEXTO, Text = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8), Size = UDim2.fromOffset(300, 24),
	}, pantalla)

	local ultimoConteo, ultimaSeleccion = -1, -1

	local function refrescarContador()
		local n = api.contarPartes()
		local sel = #estado.seleccion

		if n ~= ultimoConteo or sel ~= ultimaSeleccion then
			ultimoConteo, ultimaSeleccion = n, sel
			contador.Text = ("  %d / %d parts    %d selected    grid %s")
				:format(n, api.Serializer.MAX_PARTES, sel,
					estado.rejilla > 0 and "on" or "off")
			contador.TextColor3 = (n > api.Serializer.MAX_PARTES * 0.9)
				and Color3.fromRGB(150, 40, 40) or UI.TEXTO
		end
	end

	return {
		pantalla = pantalla,
		decir = decir,
		abrirGuardar = abrirGuardar,
		abrirAbrir = abrirAbrir,
		refrescarContador = refrescarContador,
		refrescarEstado = refrescarContador,
	}
end

return Ui
