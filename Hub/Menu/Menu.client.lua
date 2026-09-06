--!nocheck
--[[
	Bygone -- lobby menu, styled like a 2008 ROBLOX dialog.

	This is no longer a catalogue of archived places. Bygone is a builder now:
	people make their own classic-style places inside Bygone Studio, publish
	them, and this menu is where everyone else finds them.

	Three tabs:
	  Recent     what has just been published
	  Popular    ordered by visits
	  Mine       your own creations, published or not

	The gallery comes from the server (ReplicatedStorage.Constructor.Galeria),
	never from the client, so a tampered client cannot list private work.

	Scales for phones and tablets: everything is laid out in scale and the
	window is driven by a UIScale that shrinks on small screens.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local screen = script.Parent

local TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local canal = ReplicatedStorage:WaitForChild("Constructor", 20)
local studioId = ReplicatedStorage:WaitForChild("StudioPlaceId", 10)
local playId = ReplicatedStorage:WaitForChild("PlayPlaceId", 10)

--------------------------------------------------------------------------------
-- Period palette
--------------------------------------------------------------------------------

local GREY_BG    = Color3.fromRGB(177, 177, 177)
local GREY_PANEL = Color3.fromRGB(199, 199, 199)
local GREY_DARK  = Color3.fromRGB(128, 128, 128)
local GREY_TITLE = Color3.fromRGB(151, 151, 151)
local TEXT_MAIN  = Color3.fromRGB( 51,  51,  51)
local TEXT_DIM   = Color3.fromRGB(102, 102, 102)
local SEL_BG     = Color3.fromRGB(102, 153, 204)
local WHITE      = Color3.fromRGB(255, 255, 255)
local RED        = Color3.fromRGB(140, 45, 45)

local FONT = Enum.Font.Cartoon

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local dim = new("Frame", {
	Name = "Dim", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
	BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 10,
}, screen)

local window = new("Frame", {
	Name = "Window", BackgroundColor3 = GREY_BG, BorderSizePixel = 0, ZIndex = 11,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(680, 450),
}, dim)

local scaler = new("UIScale", { Scale = 1 }, window)

local function fitToScreen()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	if not vp or vp.X == 0 then
		return
	end
	local margin = TOUCH and 0.96 or 0.9
	scaler.Scale = math.clamp(
		math.min((vp.X * margin) / 680, (vp.Y * margin) / 450), 0.42, 1.25)
end

new("Frame", {
	BorderSizePixel = 0, ZIndex = 11, BackgroundColor3 = Color3.fromRGB(222, 222, 222),
	Size = UDim2.new(1, 0, 0, 1),
}, window)
new("Frame", {
	BorderSizePixel = 0, ZIndex = 11, BackgroundColor3 = GREY_DARK,
	Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
}, window)

local titleBar = new("Frame", {
	BackgroundColor3 = GREY_TITLE, BorderSizePixel = 0, ZIndex = 12,
	Size = UDim2.new(1, -2, 0, 26), Position = UDim2.fromOffset(1, 1),
}, window)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 17, ZIndex = 13,
	TextColor3 = Color3.fromRGB(245, 245, 245),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "  Bygone  -  community creations", Size = UDim2.new(1, -170, 1, 0),
}, titleBar)

local creditsBtn = new("TextButton", {
	BackgroundColor3 = GREY_BG, BorderSizePixel = 0, ZIndex = 13, Font = FONT,
	TextSize = 14, TextColor3 = TEXT_MAIN, Text = "Credits", AutoButtonColor = true,
	Size = UDim2.fromOffset(66, 20), Position = UDim2.new(1, -99, 0, 3),
}, titleBar)

local closeBtn = new("TextButton", {
	BackgroundColor3 = GREY_BG, BorderSizePixel = 0, ZIndex = 13, Font = FONT,
	TextSize = 17, TextColor3 = TEXT_MAIN, Text = "X", AutoButtonColor = true,
	Size = UDim2.fromOffset(26, 20), Position = UDim2.new(1, -29, 0, 3),
}, titleBar)

--------------------------------------------------------------------------------
-- Tabs and list
--------------------------------------------------------------------------------

local tabBar = new("Frame", {
	BackgroundTransparency = 1, ZIndex = 12,
	Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -20, 0, 28),
}, window)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
}, tabBar)

local listPanel = new("Frame", {
	BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
	ZIndex = 12, Position = UDim2.fromOffset(10, 64), Size = UDim2.new(1, -20, 1, -160),
}, window)

local list = new("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12,
	Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = TOUCH and 14 or 8,
}, listPanel)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

local info = new("Frame", {
	BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
	ZIndex = 12, Size = UDim2.new(1, -20, 0, 78), Position = UDim2.new(0, 10, 1, -88),
}, window)

local infoTitle = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 19, ZIndex = 13,
	TextColor3 = TEXT_MAIN, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Select a creation", Size = UDim2.new(1, -300, 0, 24),
	Position = UDim2.fromOffset(10, 6),
}, info)

local infoSub = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 15, ZIndex = 13,
	TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	Size = UDim2.new(1, -300, 0, 18), Position = UDim2.fromOffset(10, 31),
}, info)

local infoDesc = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 13, ZIndex = 13,
	TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
	Size = UDim2.new(1, -300, 0, 18), Position = UDim2.fromOffset(10, 51),
}, info)

local playBtn = new("TextButton", {
	BackgroundColor3 = GREY_BG, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
	ZIndex = 13, Font = FONT, TextSize = 20, TextColor3 = TEXT_DIM, Text = "Play",
	AutoButtonColor = true, Active = false,
	Size = UDim2.fromOffset(132, 40), Position = UDim2.new(1, -144, 0.5, -20),
}, info)

local buildBtn = new("TextButton", {
	BackgroundColor3 = GREY_BG, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
	ZIndex = 13, Font = FONT, TextSize = 20, TextColor3 = TEXT_MAIN,
	Text = "Build", AutoButtonColor = true,
	Size = UDim2.fromOffset(132, 40), Position = UDim2.new(1, -286, 0.5, -20),
}, info)

local status = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 13,
	TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right, Text = "",
	Size = UDim2.fromOffset(360, 18), Position = UDim2.new(1, -372, 1, -20),
}, window)

--------------------------------------------------------------------------------
-- Credits
--------------------------------------------------------------------------------

local CREDITS = [[
BYGONE

Build and share classic-style ROBLOX places, the way they
looked in 2008.


ENGINE

  Super Nostalgia Zone, by MaximumADHD (CloneTrooper1019)
  github.com/MaximumADHD/Super-Nostalgia-Zone
  Licensed MPL-2.0.

  The classic camera, mouse, chat, GUI, stud and inlet
  surfaces, old heads and faces, and the rewritten classic
  tools are his work.

  Our changes are public, as the licence requires:
  github.com/gabrielcolladorodriguez/Super-Nostalgia-Zone


THE CREATIONS

  Everything in the gallery was built by the players of
  Bygone, inside Bygone Studio. Each one belongs to whoever
  made it, and their name is on it.

  Nothing here is copied from anyone else's game.
]]

local creditsPanel = new("Frame", {
	BackgroundColor3 = GREY_BG, BorderSizePixel = 0, ZIndex = 20, Visible = false,
	Size = UDim2.new(1, -2, 1, -28), Position = UDim2.fromOffset(1, 27),
}, window)

local creditsScroll = new("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 20,
	Size = UDim2.new(1, -16, 1, -50), Position = UDim2.fromOffset(8, 6),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = TOUCH and 14 or 8,
}, creditsPanel)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 15, ZIndex = 20,
	TextColor3 = TEXT_MAIN, TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top, Text = CREDITS,
	Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
}, creditsScroll)

local creditsBack = new("TextButton", {
	BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
	ZIndex = 21, Font = FONT, TextSize = 16, TextColor3 = TEXT_MAIN, Text = "Back",
	AutoButtonColor = true,
	Size = UDim2.fromOffset(110, 32), Position = UDim2.new(0.5, -55, 1, -40),
}, creditsPanel)

creditsBtn.Activated:Connect(function () creditsPanel.Visible = true end)
creditsBack.Activated:Connect(function () creditsPanel.Visible = false end)

--------------------------------------------------------------------------------
-- Behaviour
--------------------------------------------------------------------------------

local selected = nil
local activeTab = "Recent"
local rows = {}

local function paintInfo()
	if not selected then
		infoTitle.Text = "Select a creation"
		infoSub.Text = ""
		infoDesc.Text = ""
		playBtn.Active = false
		playBtn.TextColor3 = TEXT_DIM
		return
	end

	infoTitle.Text = selected.nombre or "Untitled"
	infoSub.Text = ("by %s  -  %d parts%s"):format(
		selected.dueno or "?", selected.partes or 0,
		selected.visitas and selected.visitas > 0
			and ("  -  %d plays"):format(selected.visitas) or "")
	infoDesc.Text = selected.descripcion or ""

	local jugable = selected.publicada and playId and playId.Value > 0
	playBtn.Active = jugable and true or false
	playBtn.TextColor3 = jugable and TEXT_MAIN or TEXT_DIM
	status.Text = selected.publicada and ""
		or "Not published yet - only you can open it, in Bygone Studio."
end

--- Cada creacion se pinta como una ficha con la foto de perfil de quien la
--- hizo. La miniatura se pide aparte y en segundo plano: GetUserThumbnailAsync
--- espera respuesta de Roblox, y con veinte fichas eso serian veinte esperas
--- seguidas antes de ver nada.
local function retrato(imagen, userId)
	task.spawn(function ()
		local ok, url = pcall(function ()
			return Players:GetUserThumbnailAsync(userId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and imagen.Parent then
			imagen.Image = url
		end
	end)
end

local ALTO_FICHA = 68

local function paintRows(fichas, vacio)
	for _, row in ipairs(rows) do
		row:Destroy()
	end
	rows = {}
	selected = nil
	paintInfo()

	if #fichas == 0 then
		local etiqueta = new("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 15, ZIndex = 13,
			TextColor3 = TEXT_DIM, Text = "  " .. vacio,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 30),
		}, list)
		table.insert(rows, etiqueta)
		return
	end

	for i, ficha in ipairs(fichas) do
		local card = new("TextButton", {
			BackgroundColor3 = GREY_BG, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
			ZIndex = 13, LayoutOrder = i, Text = "", AutoButtonColor = false,
			Size = UDim2.new(1, -8, 0, ALTO_FICHA),
		}, list)

		-- Foto de perfil
		local marco = new("Frame", {
			BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1,
			BorderColor3 = GREY_DARK, ZIndex = 14,
			Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(56, 56),
		}, card)

		local foto = new("ImageLabel", {
			BackgroundTransparency = 1, ZIndex = 15, Size = UDim2.fromScale(1, 1),
			Image = "", ScaleType = Enum.ScaleType.Fit,
		}, marco)

		if ficha.duenoId then
			retrato(foto, ficha.duenoId)
		end

		-- Titulo
		new("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 17, ZIndex = 14,
			TextColor3 = TEXT_MAIN, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = ficha.nombre or "Untitled",
			Position = UDim2.fromOffset(70, 6), Size = UDim2.new(1, -240, 0, 20),
		}, card)

		-- Autor
		new("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 14,
			TextColor3 = SEL_BG, TextXAlignment = Enum.TextXAlignment.Left,
			Text = "by @" .. (ficha.dueno or "unknown"),
			Position = UDim2.fromOffset(70, 26), Size = UDim2.new(1, -240, 0, 17),
		}, card)

		-- Descripcion
		new("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 13, ZIndex = 14,
			TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = (ficha.descripcion and #ficha.descripcion > 0)
				and ficha.descripcion or "No description.",
			Position = UDim2.fromOffset(70, 44), Size = UDim2.new(1, -240, 0, 17),
		}, card)

		-- Cifras
		new("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 13, ZIndex = 14,
			TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right,
			Text = ("%d parts
%d plays%s"):format(ficha.partes or 0,
				ficha.visitas or 0, ficha.publicada and "" or "
private"),
			Position = UDim2.new(1, -166, 0, 8), Size = UDim2.fromOffset(160, 52),
		}, card)

		local function resaltar(activo)
			card.BackgroundColor3 = activo and SEL_BG or GREY_BG
			for _, hijo in ipairs(card:GetDescendants()) do
				if hijo:IsA("TextLabel") and hijo.TextColor3 == TEXT_MAIN then
					hijo.TextColor3 = activo and WHITE or TEXT_MAIN
				end
			end
		end

		card.MouseEnter:Connect(function ()
			if selected ~= ficha then card.BackgroundColor3 = GREY_PANEL end
		end)
		card.MouseLeave:Connect(function ()
			if selected ~= ficha then card.BackgroundColor3 = GREY_BG end
		end)

		card.Activated:Connect(function ()
			for _, otra in ipairs(rows) do
				if otra:IsA("TextButton") then otra.BackgroundColor3 = GREY_BG end
			end
			card.BackgroundColor3 = SEL_BG
			selected = ficha
			paintInfo()
		end)

		table.insert(rows, card)
	end
end

local cargando = false

local function cargarPestana(nombre)
	if cargando or not canal then
		return
	end

	activeTab = nombre
	cargando = true
	paintRows({}, "Loading...")

	task.spawn(function ()
		local ok, respuesta

		if nombre == "Mine" then
			ok, respuesta = pcall(function ()
				return canal.MisCreaciones:InvokeServer()
			end)
		else
			ok, respuesta = pcall(function ()
				return canal.Galeria:InvokeServer(nombre == "Popular")
			end)
		end

		cargando = false

		if ok and respuesta and respuesta.ok then
			paintRows(respuesta.fichas or {},
				nombre == "Mine"
					and "You have not built anything yet. Press Build to start."
					or "Nothing published yet. Be the first: press Build.")
		else
			paintRows({}, (respuesta and respuesta.error) or "Could not load the list.")
		end
	end)
end

local tabButtons = {}

for i, nombre in ipairs({ "Recent", "Popular", "Mine" }) do
	local b = new("TextButton", {
		BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
		ZIndex = 13, LayoutOrder = i, Font = FONT, TextSize = 15,
		TextColor3 = TEXT_MAIN, Text = nombre, AutoButtonColor = false,
		Size = UDim2.fromOffset(110, 26),
	}, tabBar)

	tabButtons[nombre] = b

	b.Activated:Connect(function ()
		for otro, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = (otro == nombre) and SEL_BG or GREY_PANEL
			btn.TextColor3 = (otro == nombre) and WHITE or TEXT_MAIN
		end
		cargarPestana(nombre)
	end)
end

tabButtons.Recent.BackgroundColor3 = SEL_BG
tabButtons.Recent.TextColor3 = WHITE

--------------------------------------------------------------------------------
-- Teleporting
--------------------------------------------------------------------------------

local function irA(placeId, datos)
	if not placeId or placeId <= 0 then
		status.TextColor3 = RED
		status.Text = "That place is not set up yet."
		return
	end

	status.TextColor3 = TEXT_DIM
	status.Text = "Loading..."

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
		status.TextColor3 = RED
		status.Text = "Teleporting only works in the published game."
		warn("[Menu] Teleport failed:", err)
	end
end

playBtn.Activated:Connect(function ()
	if selected and playBtn.Active then
		irA(playId and playId.Value, { creacion = selected.id })
	end
end)

buildBtn.Activated:Connect(function ()
	irA(studioId and studioId.Value)
end)

--------------------------------------------------------------------------------
-- Opening
--------------------------------------------------------------------------------

local function setOpen(open)
	dim.Visible = open
	if open then
		fitToScreen()
		if #rows == 0 then
			cargarPestana(activeTab)
		end
	end
end

closeBtn.Activated:Connect(function () setOpen(false) end)

local openBtn = new("TextButton", {
	Name = "OpenMenu", BackgroundColor3 = GREY_BG, BorderSizePixel = 1,
	BorderColor3 = GREY_DARK, ZIndex = 9, Font = FONT, TextSize = 16,
	TextColor3 = TEXT_MAIN, Text = "Creations", AutoButtonColor = true,
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(TOUCH and 124 or 106, TOUCH and 44 or 32),
	Position = UDim2.new(1, -12, 0, 46),
}, screen)
openBtn.Activated:Connect(function () setOpen(not dim.Visible) end)

UserInputService.InputBegan:Connect(function (input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		setOpen(not dim.Visible)
	elseif input.KeyCode == Enum.KeyCode.Escape and dim.Visible then
		setOpen(false)
	end
end)

-- Los portales del vestibulo: uno lleva al editor, otro abre la galeria.
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		if obj.Name == "PortalConstruir" then
			local prompt = new("ProximityPrompt", {
				ActionText = "Build", ObjectText = "Bygone Studio",
				HoldDuration = 0, RequiresLineOfSight = false,
				MaxActivationDistance = 14,
			}, obj)
			prompt.Triggered:Connect(function ()
				irA(studioId and studioId.Value)
			end)

		elseif obj.Name == "PortalGaleria" then
			local prompt = new("ProximityPrompt", {
				ActionText = "Browse creations", ObjectText = "Bygone",
				HoldDuration = 0, RequiresLineOfSight = false,
				MaxActivationDistance = 14,
			}, obj)
			prompt.Triggered:Connect(function () setOpen(true) end)
		end
	end
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)
end
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fitToScreen)

fitToScreen()
paintInfo()

task.delay(1.5, function () setOpen(true) end)
