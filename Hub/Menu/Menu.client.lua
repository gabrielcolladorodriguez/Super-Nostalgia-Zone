--!nocheck
--[[
	Bygone -- el menu del vestibulo.

	Es la unica via para construir y para jugar: ya no hay portales en el mapa.
	Eso obliga a que aqui este todo y se entienda de un vistazo, asi que la
	pantalla se reparte en tres columnas:

	  izquierda   que quieres hacer: BUILD, que lista mirar, y el buscador
	  centro      rejilla de fichas con la foto de quien la hizo
	  derecha     la ficha elegida en grande, con el boton de jugar

	Las miniaturas se piden en segundo plano. GetUserThumbnailAsync espera
	respuesta de Roblox, y con veinte fichas serian veinte esperas seguidas
	antes de ver nada en pantalla.

	Todo se dibuja en offset dentro de un UIScale, asi que en movil y tablet
	encoge de golpe sin recolocar nada.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

--[[
	Cargando es HERMANO de este script, no hijo: rojo mete los dos dentro de la
	misma ScreenGui. Buscarlo con script:WaitForChild lo dejaba esperando para
	siempre y el menu no llegaba a construirse.

	Y va con tiempo limite a proposito: la pantalla de teletransporte es un
	adorno, y un adorno no puede impedir que se vea el menu.
]]
local anunciarDestino = function () end

do
	local modulo = script.Parent:WaitForChild("Cargando", 5)
	if modulo then
		local ok, resultado = pcall(function ()
			return require(modulo).Preparar()
		end)
		if ok and type(resultado) == "function" then
			anunciarDestino = resultado
		else
			warn("[Menu] La pantalla de carga fallo: " .. tostring(resultado))
		end
	end
end

local player = Players.LocalPlayer
local screen = script.Parent

local TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local canal = ReplicatedStorage:WaitForChild("Constructor", 20)
if not canal then
	warn("[Menu] No aparecio ReplicatedStorage.Constructor; la galeria no funcionara.")
end
local studioId = ReplicatedStorage:WaitForChild("StudioPlaceId", 10)
local playId = ReplicatedStorage:WaitForChild("PlayPlaceId", 10)

--------------------------------------------------------------------------------
-- Paleta
--------------------------------------------------------------------------------

local FONDO  = Color3.fromRGB(196, 196, 196)
local PANEL  = Color3.fromRGB(212, 212, 212)
local HUECO  = Color3.fromRGB(172, 172, 172)
local OSCURO = Color3.fromRGB(120, 120, 120)
local LUZ    = Color3.fromRGB(236, 236, 236)
local TITULO = Color3.fromRGB(92, 102, 118)
local TEXTO  = Color3.fromRGB(36, 36, 36)
local TENUE  = Color3.fromRGB(106, 106, 106)
local SEL    = Color3.fromRGB(74, 128, 190)
local ACENTO = Color3.fromRGB(176, 132, 40)
local BLANCO = Color3.fromRGB(252, 252, 252)
local ROJO   = Color3.fromRGB(148, 52, 52)

local FONT = Enum.Font.Cartoon
local ANCHO, ALTO = 860, 540

local function new(clase, props, padre)
	local i = Instance.new(clase)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = padre
	return i
end

local function bisel(marco, z)
	new("Frame", { BackgroundColor3 = LUZ, BorderSizePixel = 0, ZIndex = z or 1,
		Size = UDim2.new(1, 0, 0, 1) }, marco)
	new("Frame", { BackgroundColor3 = OSCURO, BorderSizePixel = 0, ZIndex = z or 1,
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1) }, marco)
end

--------------------------------------------------------------------------------
-- Ventana
--------------------------------------------------------------------------------

local dim = new("Frame", {
	Name = "Dim", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55,
	BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 10,
}, screen)

local window = new("Frame", {
	Name = "Window", BackgroundColor3 = FONDO, BorderSizePixel = 1,
	BorderColor3 = OSCURO, ZIndex = 11, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(ANCHO, ALTO),
}, dim)
bisel(window, 11)

local scaler = new("UIScale", { Scale = 1 }, window)

local function ajustar()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	if not vp or vp.X == 0 then return end
	local margen = TOUCH and 0.97 or 0.92
	scaler.Scale = math.clamp(
		math.min((vp.X * margen) / ANCHO, (vp.Y * margen) / ALTO), 0.4, 1.15)
end

local titleBar = new("Frame", {
	BackgroundColor3 = TITULO, BorderSizePixel = 0, ZIndex = 12,
	Size = UDim2.new(1, -2, 0, 28), Position = UDim2.fromOffset(1, 1),
}, window)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 18, ZIndex = 13,
	TextColor3 = BLANCO, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "  Bygone", Size = UDim2.new(1, -180, 1, 0),
}, titleBar)

local creditsBtn = new("TextButton", {
	BackgroundColor3 = FONDO, BorderSizePixel = 0, ZIndex = 13, Font = FONT,
	TextSize = 14, TextColor3 = TEXTO, Text = "Credits", AutoButtonColor = true,
	Size = UDim2.fromOffset(70, 20), Position = UDim2.new(1, -104, 0, 4),
}, titleBar)

local closeBtn = new("TextButton", {
	BackgroundColor3 = FONDO, BorderSizePixel = 0, ZIndex = 13, Font = FONT,
	TextSize = 16, TextColor3 = TEXTO, Text = "x", AutoButtonColor = true,
	Size = UDim2.fromOffset(26, 20), Position = UDim2.new(1, -30, 0, 4),
}, titleBar)

--------------------------------------------------------------------------------
-- Columna izquierda
--------------------------------------------------------------------------------

local izq = new("Frame", {
	Name = "Izquierda", BackgroundTransparency = 1, ZIndex = 12,
	Position = UDim2.fromOffset(10, 38), Size = UDim2.fromOffset(178, ALTO - 48),
}, window)

local buildBtn = new("TextButton", {
	Name = "Build", BackgroundColor3 = ACENTO, BorderSizePixel = 1,
	BorderColor3 = OSCURO, ZIndex = 13, Font = FONT, TextSize = 22,
	TextColor3 = BLANCO, Text = "BUILD", AutoButtonColor = true,
	Size = UDim2.fromOffset(178, 52),
}, izq)
bisel(buildBtn, 13)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 12, ZIndex = 13,
	TextColor3 = TENUE, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Open Bygone Studios and make a place of your own.",
	Position = UDim2.fromOffset(2, 56), Size = UDim2.fromOffset(174, 32),
}, izq)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 13, ZIndex = 13,
	TextColor3 = TENUE, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "BROWSE", Position = UDim2.fromOffset(2, 96),
	Size = UDim2.fromOffset(174, 16),
}, izq)

local tabHolder = new("Frame", {
	BackgroundTransparency = 1, ZIndex = 13,
	Position = UDim2.fromOffset(0, 114), Size = UDim2.fromOffset(178, 110),
}, izq)
new("UIListLayout", { Padding = UDim.new(0, 4) }, tabHolder)

local searchBox = new("TextBox", {
	Name = "Search", BackgroundColor3 = Color3.fromRGB(246, 246, 246),
	BorderSizePixel = 1, BorderColor3 = OSCURO, ZIndex = 13, Font = FONT,
	TextSize = 14, TextColor3 = TEXTO, PlaceholderText = "Search...", Text = "",
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	Position = UDim2.fromOffset(0, 232), Size = UDim2.fromOffset(178, 26),
}, izq)
new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, searchBox)

local contadorLbl = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 12, ZIndex = 13,
	TextColor3 = TENUE, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	Position = UDim2.fromOffset(2, 264), Size = UDim2.fromOffset(174, 16),
}, izq)

--------------------------------------------------------------------------------
-- Rejilla del centro
--------------------------------------------------------------------------------

local centro = new("Frame", {
	Name = "Centro", BackgroundColor3 = HUECO, BorderSizePixel = 1,
	BorderColor3 = OSCURO, ZIndex = 12,
	Position = UDim2.fromOffset(196, 38), Size = UDim2.fromOffset(410, ALTO - 48),
}, window)

local lista = new("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12,
	Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = TOUCH and 12 or 7,
}, centro)
new("UIGridLayout", {
	CellSize = UDim2.fromOffset(190, 78), CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, lista)

--------------------------------------------------------------------------------
-- Columna derecha
--------------------------------------------------------------------------------

local ANCHO_DER = ANCHO - 624

local der = new("Frame", {
	Name = "Detalle", BackgroundColor3 = PANEL, BorderSizePixel = 1,
	BorderColor3 = OSCURO, ZIndex = 12,
	Position = UDim2.fromOffset(614, 38), Size = UDim2.fromOffset(ANCHO_DER, ALTO - 48),
}, window)

local dRetratoMarco = new("Frame", {
	BackgroundColor3 = HUECO, BorderSizePixel = 1, BorderColor3 = OSCURO, ZIndex = 13,
	Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(72, 72),
}, der)
local dRetrato = new("ImageLabel", {
	BackgroundTransparency = 1, ZIndex = 14, Size = UDim2.fromScale(1, 1),
	Image = "", ScaleType = Enum.ScaleType.Fit,
}, dRetratoMarco)

local dTitulo = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 19, ZIndex = 13,
	TextColor3 = TEXTO, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
	Text = "Nothing selected",
	Position = UDim2.fromOffset(92, 12), Size = UDim2.fromOffset(ANCHO_DER - 102, 46),
}, der)

local dAutor = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 13,
	TextColor3 = SEL, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	Position = UDim2.fromOffset(92, 62), Size = UDim2.fromOffset(ANCHO_DER - 102, 18),
}, der)

local dDesc = new("TextLabel", {
	BackgroundColor3 = HUECO, BorderSizePixel = 1, BorderColor3 = OSCURO,
	Font = FONT, TextSize = 13, ZIndex = 13, TextColor3 = TEXTO,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true, Text = "Pick a creation from the list.",
	Position = UDim2.fromOffset(10, 96), Size = UDim2.fromOffset(ANCHO_DER - 20, 108),
}, der)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 5),
	PaddingRight = UDim.new(0, 5) }, dDesc)

local dCifras = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 13,
	TextColor3 = TENUE, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, Text = "",
	Position = UDim2.fromOffset(12, 214), Size = UDim2.fromOffset(ANCHO_DER - 20, 72),
}, der)

local playBtn = new("TextButton", {
	Name = "Play", BackgroundColor3 = FONDO, BorderSizePixel = 1, BorderColor3 = OSCURO,
	ZIndex = 13, Font = FONT, TextSize = 22, TextColor3 = TENUE, Text = "Play",
	AutoButtonColor = true, Active = false, AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 10, 1, -12), Size = UDim2.fromOffset(ANCHO_DER - 20, 46),
}, der)
bisel(playBtn, 13)

local status = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 12, ZIndex = 13,
	TextColor3 = TENUE, TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Bottom, Text = "",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -62), Size = UDim2.fromOffset(ANCHO_DER - 24, 38),
}, der)

--------------------------------------------------------------------------------
-- Creditos
--------------------------------------------------------------------------------

local CREDITS = [[
BYGONE

Build and share classic-style ROBLOX places, the way they looked in 2008.


ENGINE

  Super Nostalgia Zone, by MaximumADHD (CloneTrooper1019)
  github.com/MaximumADHD/Super-Nostalgia-Zone
  Licensed MPL-2.0.

  The classic camera, mouse, chat, GUI, stud and inlet surfaces, the old
  heads and faces, and the rewritten classic tools are his work.

  Our changes are public, as the licence requires:
  github.com/gabrielcolladorodriguez/Super-Nostalgia-Zone


THE CREATIONS

  Everything in the gallery was built by the players of Bygone, inside
  Bygone Studios. Each one belongs to whoever made it, and their name is
  on it.

  Nothing here is copied from anyone else's game.
]]

local creditos = new("Frame", {
	BackgroundColor3 = FONDO, BorderSizePixel = 0, ZIndex = 40, Visible = false,
	Size = UDim2.new(1, -2, 1, -30), Position = UDim2.fromOffset(1, 29),
}, window)

local creditosScroll = new("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 40,
	Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 1, -54),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = TOUCH and 12 or 7,
}, creditos)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 15, ZIndex = 40,
	TextColor3 = TEXTO, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, Text = CREDITS,
	Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
}, creditosScroll)

local creditosBack = new("TextButton", {
	BackgroundColor3 = PANEL, BorderSizePixel = 1, BorderColor3 = OSCURO,
	ZIndex = 41, Font = FONT, TextSize = 16, TextColor3 = TEXTO, Text = "Back",
	AutoButtonColor = true, AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(120, 32),
}, creditos)

creditsBtn.Activated:Connect(function () creditos.Visible = true end)
creditosBack.Activated:Connect(function () creditos.Visible = false end)

--------------------------------------------------------------------------------
-- Datos
--------------------------------------------------------------------------------

local seleccion = nil
local pestana = "Recent"
local filtro = ""
local fichasActuales = {}
local tarjetas = {}

local function retrato(imagen, userId)
	task.spawn(function ()
		local ok, url = pcall(function ()
			return Players:GetUserThumbnailAsync(userId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and imagen.Parent then
			imagen.Image = url
		end
	end)
end

local function pintarDetalle()
	if not seleccion then
		dRetrato.Image = ""
		dTitulo.Text = "Nothing selected"
		dAutor.Text = ""
		dDesc.Text = "Pick a creation from the list."
		dCifras.Text = ""
		playBtn.Active = false
		playBtn.TextColor3 = TENUE
		status.Text = ""
		return
	end

	dTitulo.Text = seleccion.nombre or "Untitled"
	dAutor.Text = "@" .. (seleccion.dueno or "unknown")
	dDesc.Text = (seleccion.descripcion and #seleccion.descripcion > 0)
		and seleccion.descripcion or "No description."

	dRetrato.Image = ""
	if seleccion.duenoId then
		retrato(dRetrato, seleccion.duenoId)
	end

	dCifras.Text = ("Parts         %d\nPlays         %d\nVisibility    %s")
		:format(seleccion.partes or 0, seleccion.visitas or 0,
			seleccion.publicada and "public" or "private")

	local jugable = seleccion.publicada and playId and playId.Value > 0
	playBtn.Active = jugable and true or false
	playBtn.TextColor3 = jugable and TEXTO or TENUE
	status.TextColor3 = TENUE
	status.Text = seleccion.publicada and ""
		or "Not published. Only you can open it, in Bygone Studios."
end

local function pintarRejilla()
	for _, t in ipairs(tarjetas) do
		t:Destroy()
	end
	tarjetas = {}

	local mostradas = 0

	for i, ficha in ipairs(fichasActuales) do
		local coincide = true
		if filtro ~= "" then
			coincide = (ficha.nombre or ""):lower():find(filtro, 1, true) ~= nil
				or (ficha.dueno or ""):lower():find(filtro, 1, true) ~= nil
		end

		if coincide then
			mostradas += 1

			local card = new("TextButton", {
				BackgroundColor3 = FONDO, BorderSizePixel = 1, BorderColor3 = OSCURO,
				ZIndex = 13, LayoutOrder = i, Text = "", AutoButtonColor = false,
			}, lista)

			local marco = new("Frame", {
				BackgroundColor3 = HUECO, BorderSizePixel = 1, BorderColor3 = OSCURO,
				ZIndex = 14, Position = UDim2.fromOffset(6, 6),
				Size = UDim2.fromOffset(60, 60),
			}, card)
			local foto = new("ImageLabel", {
				BackgroundTransparency = 1, ZIndex = 15, Size = UDim2.fromScale(1, 1),
				Image = "", ScaleType = Enum.ScaleType.Fit,
			}, marco)
			if ficha.duenoId then
				retrato(foto, ficha.duenoId)
			end

			new("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 15, ZIndex = 14,
				TextColor3 = TEXTO, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ficha.nombre or "Untitled",
				Position = UDim2.fromOffset(72, 8), Size = UDim2.fromOffset(110, 18),
			}, card)

			new("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 12, ZIndex = 14,
				TextColor3 = SEL, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "@" .. (ficha.dueno or "unknown"),
				Position = UDim2.fromOffset(72, 27), Size = UDim2.fromOffset(110, 16),
			}, card)

			new("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 12, ZIndex = 14,
				TextColor3 = TENUE, TextXAlignment = Enum.TextXAlignment.Left,
				Text = ("%d parts   %d plays"):format(ficha.partes or 0,
					ficha.visitas or 0),
				Position = UDim2.fromOffset(72, 46), Size = UDim2.fromOffset(110, 16),
			}, card)

			if not ficha.publicada then
				new("TextLabel", {
					BackgroundColor3 = OSCURO, BorderSizePixel = 0, ZIndex = 16,
					Font = FONT, TextSize = 10, TextColor3 = BLANCO, Text = "PRIVATE",
					Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(52, 12),
				}, card)
			end

			card.MouseEnter:Connect(function ()
				if seleccion ~= ficha then card.BackgroundColor3 = PANEL end
			end)
			card.MouseLeave:Connect(function ()
				if seleccion ~= ficha then card.BackgroundColor3 = FONDO end
			end)
			card.Activated:Connect(function ()
				for _, otra in ipairs(tarjetas) do
					if otra:IsA("TextButton") then
						otra.BackgroundColor3 = FONDO
					end
				end
				card.BackgroundColor3 = SEL
				seleccion = ficha
				pintarDetalle()
			end)

			table.insert(tarjetas, card)
		end
	end

	contadorLbl.Text = ("%d creation%s"):format(mostradas, mostradas == 1 and "" or "s")

	if mostradas == 0 then
		local vacio = new("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 14,
			TextColor3 = TENUE, TextWrapped = true, LayoutOrder = 0,
			Text = (pestana == "Mine")
				and "You have not built anything yet. Press BUILD to start."
				or "Nothing here yet. Press BUILD and be the first.",
		}, lista)
		table.insert(tarjetas, vacio)
	end
end

local cargando = false

local function cargar(nombre)
	if cargando or not canal then return end

	pestana = nombre
	cargando = true
	fichasActuales = {}
	pintarRejilla()
	contadorLbl.Text = "Loading..."

	task.spawn(function ()
		local ok, r
		if nombre == "Mine" then
			ok, r = pcall(function () return canal.MisCreaciones:InvokeServer() end)
		else
			ok, r = pcall(function ()
				return canal.Galeria:InvokeServer(nombre == "Popular")
			end)
		end

		cargando = false

		if ok and r and r.ok then
			fichasActuales = r.fichas or {}
		else
			fichasActuales = {}
			status.TextColor3 = ROJO
			status.Text = (r and r.error) or "Could not load the list."
		end

		seleccion = nil
		pintarRejilla()
		pintarDetalle()
	end)
end

local botonesTab = {}
for i, nombre in ipairs({ "Recent", "Popular", "Mine" }) do
	local b = new("TextButton", {
		BackgroundColor3 = PANEL, BorderSizePixel = 1, BorderColor3 = OSCURO,
		ZIndex = 14, LayoutOrder = i, Font = FONT, TextSize = 15,
		TextColor3 = TEXTO, Text = nombre, AutoButtonColor = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(178, TOUCH and 32 or 28),
	}, tabHolder)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, b)
	botonesTab[nombre] = b

	b.Activated:Connect(function ()
		for otro, btn in pairs(botonesTab) do
			btn.BackgroundColor3 = (otro == nombre) and SEL or PANEL
			btn.TextColor3 = (otro == nombre) and BLANCO or TEXTO
		end
		cargar(nombre)
	end)
end
botonesTab.Recent.BackgroundColor3 = SEL
botonesTab.Recent.TextColor3 = BLANCO

searchBox:GetPropertyChangedSignal("Text"):Connect(function ()
	filtro = searchBox.Text:lower()
	pintarRejilla()
end)

--------------------------------------------------------------------------------
-- Teletransporte
--------------------------------------------------------------------------------

local function irA(placeId, datos, etiqueta)
	if not placeId or placeId <= 0 then
		status.TextColor3 = ROJO
		status.Text = "That place is not set up yet."
		return
	end

	status.TextColor3 = TENUE
	status.Text = "Loading..."
	anunciarDestino(etiqueta)

	local ok, err = pcall(function ()
		if datos then
			local opciones = Instance.new("TeleportOptions")
			opciones:SetTeleportData(datos)
			TeleportService:TeleportAsync(placeId, { player }, opciones)
		else
			TeleportService:Teleport(placeId, player)
		end
	end)

	if not ok then
		status.TextColor3 = ROJO
		status.Text = "Teleporting only works in the published game."
		warn("[Menu] Teleport failed:", err)
	end
end

playBtn.Activated:Connect(function ()
	if seleccion and playBtn.Active then
		irA(playId and playId.Value, { creacion = seleccion.id },
		    seleccion.nombre or "Loading")
	end
end)

buildBtn.Activated:Connect(function ()
	irA(studioId and studioId.Value, nil, "Bygone Studios")
end)

--------------------------------------------------------------------------------
-- Abrir y cerrar
--------------------------------------------------------------------------------

local function setOpen(abrir)
	dim.Visible = abrir
	if abrir then
		ajustar()
		if #fichasActuales == 0 and not cargando then
			cargar(pestana)
		end
	end
end

closeBtn.Activated:Connect(function () setOpen(false) end)

local openBtn = new("TextButton", {
	Name = "OpenMenu", BackgroundColor3 = ACENTO, BorderSizePixel = 2,
	BorderColor3 = OSCURO, ZIndex = 9, Font = FONT, TextSize = TOUCH and 24 or 22,
	TextColor3 = BLANCO, Text = "MENU", AutoButtonColor = true,
	AnchorPoint = Vector2.new(0.5, 1),
	-- En tactil se sube del borde: abajo del todo compite con la barra del
	-- sistema y con el pulgar que sujeta el telefono.
	Size = UDim2.fromOffset(TOUCH and 190 or 150, TOUCH and 58 or 44),
	Position = UDim2.new(0.5, 0, 1, TOUCH and -84 or -16),
}, screen)
bisel(openBtn, 9)

openBtn.Activated:Connect(function () setOpen(not dim.Visible) end)

UserInputService.InputBegan:Connect(function (input, procesado)
	if procesado then return end
	if input.KeyCode == Enum.KeyCode.M then
		setOpen(not dim.Visible)
	elseif input.KeyCode == Enum.KeyCode.Escape and dim.Visible then
		setOpen(false)
	end
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
end
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(ajustar)

ajustar()
pintarDetalle()

-- El menu se abre solo al entrar: es lo primero que hay que ver, y quien no
-- lo quiera lo cierra. Medio segundo de margen para que la interfaz este ya
-- montada cuando aparezca.
task.delay(0.5, function () setOpen(true) end)
