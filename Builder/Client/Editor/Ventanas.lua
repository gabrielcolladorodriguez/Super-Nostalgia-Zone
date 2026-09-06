--!nocheck
--[[
	Ventanas -- paneles que se pueden mover, plegar y cerrar.

	Nace de un fallo concreto: los paneles tenian la altura escrita a mano y en
	cuanto una rejilla ganaba una fila mas de la prevista, los botones se salian
	por debajo y se comian la seccion siguiente. Aqui el alto NUNCA se escribe:
	cada ventana crece con su contenido (`AutomaticSize`), asi que anadir formas
	o materiales no puede volver a romper la maquetacion.

	Cada ventana trae:
	  - barra de titulo con la que se arrastra
	  - boton de plegar, que la deja en la barra de titulo
	  - boton de cerrar
	  - memoria de donde estaba, para volver a abrirla en su sitio

	Y una regla de colocacion: la esquina superior izquierda es del boton de
	Roblox. Ninguna ventana nace ahi.
]]

local UserInputService = game:GetService("UserInputService")

local Ventanas = {}
Ventanas.__index = Ventanas

local abiertas = {}

local function new(clase, props, padre)
	local i = Instance.new(clase)
	for k, v in pairs(props) do
		i[k] = v
	end
	i.Parent = padre
	return i
end

--------------------------------------------------------------------------------

function Ventanas.new(UI, raiz, titulo, ancho, posicion, tactil)
	local self = setmetatable({}, Ventanas)

	self.UI = UI
	self.titulo = titulo
	self.plegada = false

	local marco = new("Frame", {
		Name = titulo:gsub("%s", ""),
		BackgroundColor3 = UI.FONDO, BorderSizePixel = 1, BorderColor3 = UI.OSCURO,
		Position = posicion, Size = UDim2.fromOffset(ancho, 0),
		AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = false,
	}, raiz)

	new("Frame", { BackgroundColor3 = UI.LUZ, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1) }, marco)

	local barra = new("Frame", {
		Name = "Barra", BackgroundColor3 = UI.TITULO, BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 0, tactil and 26 or 21),
		Position = UDim2.fromOffset(1, 1),
	}, marco)

	new("TextLabel", {
		BackgroundTransparency = 1, Font = UI.FUENTE, TextSize = 13,
		TextColor3 = UI.BLANCO, TextXAlignment = Enum.TextXAlignment.Left,
		Text = " " .. titulo, Size = UDim2.new(1, -46, 1, 0),
	}, barra)

	local btnPlegar = new("TextButton", {
		Name = "Plegar", BackgroundColor3 = UI.FONDO, BorderSizePixel = 0,
		Font = UI.FUENTE, TextSize = 13, TextColor3 = UI.TEXTO, Text = "-",
		AutoButtonColor = true,
		Size = UDim2.fromOffset(19, 15), Position = UDim2.new(1, -43, 0, 3),
	}, barra)

	local btnCerrar = new("TextButton", {
		Name = "Cerrar", BackgroundColor3 = UI.FONDO, BorderSizePixel = 0,
		Font = UI.FUENTE, TextSize = 13, TextColor3 = UI.TEXTO, Text = "x",
		AutoButtonColor = true,
		Size = UDim2.fromOffset(19, 15), Position = UDim2.new(1, -22, 0, 3),
	}, barra)

	-- El cuerpo crece solo: es lo que impide que un boton se salga por abajo.
	local cuerpo = new("Frame", {
		Name = "Cuerpo", BackgroundTransparency = 1,
		Position = UDim2.fromOffset(5, tactil and 30 or 25),
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, marco)

	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5),
	}, cuerpo)

	new("UIPadding", { PaddingBottom = UDim.new(0, 6) }, marco)

	self.marco = marco
	self.barra = barra
	self.cuerpo = cuerpo

	-- Arrastrar por la barra de titulo -------------------------------------
	local arrastrando, inicioRaton, inicioMarco = false, nil, nil

	barra.InputBegan:Connect(function (input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastrando = true
			inicioRaton = UserInputService:GetMouseLocation()
			inicioMarco = marco.Position
		end
	end)

	UserInputService.InputChanged:Connect(function (input)
		if not arrastrando then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local ahora = UserInputService:GetMouseLocation()
		local delta = ahora - inicioRaton

		marco.Position = UDim2.new(
			inicioMarco.X.Scale, inicioMarco.X.Offset + delta.X,
			inicioMarco.Y.Scale, inicioMarco.Y.Offset + delta.Y)
	end)

	UserInputService.InputEnded:Connect(function (input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			arrastrando = false
		end
	end)

	btnPlegar.Activated:Connect(function ()
		self:Plegar(not self.plegada)
	end)

	btnCerrar.Activated:Connect(function ()
		self:Mostrar(false)
	end)

	abiertas[titulo] = self
	return self
end

--------------------------------------------------------------------------------

function Ventanas:Plegar(plegar)
	self.plegada = plegar
	self.cuerpo.Visible = not plegar
	self.marco.AutomaticSize = plegar and Enum.AutomaticSize.None
		or Enum.AutomaticSize.Y

	if plegar then
		self.marco.Size = UDim2.new(0, self.marco.AbsoluteSize.X, 0,
		                            self.barra.AbsoluteSize.Y + 4)
	end

	local btn = self.barra:FindFirstChild("Plegar")
	if btn then
		btn.Text = plegar and "+" or "-"
	end
end

function Ventanas:Mostrar(visible)
	self.marco.Visible = visible
end

function Ventanas:Visible()
	return self.marco.Visible
end

--- Una seccion con su etiqueta dentro de la ventana.
function Ventanas:Seccion(texto, orden)
	local caja = new("Frame", {
		Name = texto, BackgroundTransparency = 1, LayoutOrder = orden or 0,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	}, self.cuerpo)

	if texto and #texto > 0 then
		new("TextLabel", {
			BackgroundTransparency = 1, Font = self.UI.FUENTE, TextSize = 12,
			TextColor3 = self.UI.TENUE, Text = texto,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 15), LayoutOrder = 0,
		}, caja)
	end

	local rejilla = new("Frame", {
		Name = "Rejilla", BackgroundTransparency = 1, LayoutOrder = 1,
		Position = UDim2.fromOffset(0, texto and 16 or 0),
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	}, caja)

	return rejilla, caja
end

function Ventanas.Todas()
	return abiertas
end

return Ventanas
