local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

-----------------------------------------------------------------

local inGuiFocus = false
local inputQueue = {}

local function checkGuiFocus()
	inGuiFocus = (next(inputQueue) ~= nil)
end

local function onInputChanged(input,gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		inputQueue[input] = gameProcessed or nil
		checkGuiFocus()
	end
end

UserInputService.InputChanged:Connect(onInputChanged)

-----------------------------------------------------------------

local activated = false
local player = Players.LocalPlayer
local mouseGui = script.Parent

-- [fork] El cursor vivia dentro de la misma ScreenGui que el resto de la
-- interfaz, asi que cualquier ventana con DisplayOrder mayor lo tapaba. Se
-- muda a su propia capa, siempre la de mas arriba.
do
	local playerGui = player:WaitForChild("PlayerGui")

	local capa = Instance.new("ScreenGui")
	capa.Name = "MouseLayer"
	capa.DisplayOrder = 1000000
	capa.IgnoreGuiInset = true
	capa.ResetOnSpawn = false
	capa.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	capa.Parent = playerGui

	mouseGui.Parent = capa
end

local function onInputBegan(input,gameProcessed)
	if mouseGui then
		if input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then
			wait(.1)
			if input.UserInputState == Enum.UserInputState.End then
				activated = true
			else
				mouseGui.ImageTransparency = 1
			end
		end
	end
end

UserInputService.InputBegan:Connect(onInputBegan)

-----------------------------------------------------------------

local GUN_WAIT_CURSOR = "rbxasset://textures/GunWaitCursor.png"
local GUN_CURSOR = "rbxasset://textures/GunCursor.png"
local IS_TOUCH = UserInputService.TouchEnabled

local hasTool = false
UserInputService.MouseIconEnabled = false
	
local canActivate = true

if UserInputService.TouchEnabled then
	local camera = workspace.CurrentCamera
	local playerGui = player:WaitForChild("PlayerGui")

	local touchGui = playerGui:WaitForChild("TouchGui")
	local touchFrame = touchGui:WaitForChild("TouchControlFrame")

	if camera.ViewportSize.Y < 600 then
		touchFrame.Size = UDim2.new(0.85, 0, 0.8, 0)
	else
		touchFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	end

	touchFrame.Position = UDim2.new(0.05, 0, 0, 0)
end

local function updateMouse()
	local char = player.Character
	local override = false
	local tool

	if char then
		tool = char:FindFirstChildWhichIsA("Tool")
		hasTool = (tool ~= nil)

		if tool then
			if tool:FindFirstChild("IconOverride") then
				if tool.IconOverride.Value ~= "" then
					mouseGui.Image = tool.IconOverride.Value
				else
					mouseGui.Image = "rbxassetid://1000000"
				end
			elseif tool.Enabled then
				mouseGui.Image = GUN_CURSOR

				if IS_TOUCH then
					canActivate = true
					mouseGui.ImageTransparency = 1
				end
			else
				mouseGui.Image = GUN_WAIT_CURSOR
			end
		end
	else
		hasTool = false
	end

	if inGuiFocus then
		-- [fork] El original ponia aqui un id de imagen inexistente, es decir
		-- ocultaba el cursor sobre cualquier interfaz. En el juego original no
		-- se notaba porque casi no hay GUI que sobrevolar; con el menu de
		-- juegos te quedabas sin cursor y sin poder pulsar nada. Ahora sale la
		-- flecha clasica.
		mouseGui.Image = "rbxasset://textures/ArrowCursor.png"
	end
	
	local pos = UserInputService:GetMouseLocation()
	local upos = UDim2.new(0, pos.X, 0, pos.Y)
	
	if IS_TOUCH then
		mouseGui.Visible = hasTool

		if hasTool then
			if activated and mouseGui.Image == GUN_WAIT_CURSOR then
				if canActivate then
					canActivate = false
					mouseGui.Position = upos
					mouseGui.ImageTransparency = -1
				end
				activated = false
			else
				mouseGui.ImageTransparency = math.min(1, mouseGui.ImageTransparency + 0.01)
			end
		end
	else
		mouseGui.Position = upos
	end
	
	if UserInputService.MouseIconEnabled then
		UserInputService.MouseIconEnabled = false
	end
end

RunService:BindToRenderStep("UpdateMouse", 1000, updateMouse)