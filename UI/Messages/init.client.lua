local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local gui = script.Parent
local player = Players.LocalPlayer

local hintBin = Instance.new("Folder")
local msgNameFmt = "MsgLbl_%s [%s]"

--[[
	[fork] Solo estos textos se consideran pantallas de carga.

	Hace falta hilar fino: comprobando el universo entero salieron cinco juegos
	con un Message permanente que NO es una carga -- "Tornado Inactive",
	"Now Playing: None", el cartel de bienvenida de un mapa, la linea de estado
	de un RPG. Son su HUD. Ocultarlos por llevar mucho rato en pantalla les
	romperia la interfaz, asi que se exige que el texto hable de cargar.
--]]
local PALABRAS_DE_CARGA = {
	"loading", "please wait", "initializing", "initialising",
	"generating", "downloading", "cargando",
}

local function pareceCarga(texto)
	local minus = texto:lower()

	for _, palabra in ipairs(PALABRAS_DE_CARGA) do
		if minus:find(palabra, 1, true) then
			return true
		end
	end

	return false
end

local function addMessage(sourceMsg, msgType)
	local isInPlayer = (sourceMsg.Parent == player)
	local msgType = sourceMsg.ClassName
	
	if msgType == "Message" and isInPlayer then
		msgType = "Player"
	end
	
	local msgTemp = script:WaitForChild(msgType)
	
	local msg = msgTemp:Clone()
	msg.Name = msgNameFmt:format(msgType, sourceMsg:GetFullName())
	
	local textUpdater = sourceMsg:GetPropertyChangedSignal("Text")
	local isUpdating = false
	
	local function updateText()
		if not isUpdating then
			isUpdating = true
			
			msg.Text = sourceMsg.Text
			sourceMsg.Text = ""
			
			if msgType ~= "Hint" then
				msg.Visible = (#msg.Text > 0)
			end
			
			isUpdating = false
		end
	end
	
	local function onAncestryChanged()
		local desiredAncestor
		
		if msgType == "Hint" then
			desiredAncestor = hintBin
		elseif isInPlayer then
			desiredAncestor = player
		else
			desiredAncestor = workspace
		end
		
		if not sourceMsg:IsDescendantOf(desiredAncestor) then
			msg:Destroy()
		end
	end
	
	--[[
		I have to parent the Hint somewhere where it won't render since it
		draws even if the Hint has no text. The server will remove the object
		by it's reference address even if I change the parent, so this isn't a
		problem online. But I can't rely on this in a non-network scenario so 
		regular Hints will still be visible offline if they're in the Workspace :(
	--]]

	if msgType == "Hint" then
		RunService.Heartbeat:Wait()
		sourceMsg.Parent = hintBin
	end
	
	updateText()
	textUpdater:Connect(updateText)
	sourceMsg.AncestryChanged:Connect(onAncestryChanged)

	msg.Parent = gui

	--[[
		[fork] Salvavidas contra los mensajes eternos.

		Muchos lugares de 2008 muestran un Message tipo "Loading models..." y lo
		quitan cuando termina InsertService:LoadAsset. Hoy esa llamada falla o
		no vuelve nunca (Roblox ya no deja cargar modelos de otras cuentas), asi
		que el mensaje se queda tapando la pantalla para siempre y el jugador ni
		siquiera ve el boton de salir.

		Si un mensaje pasa de este tiempo sin cambiar de texto, lo apagamos. El
		Message original se queda donde esta: si el juego lo actualiza mas tarde,
		updateText lo vuelve a encender.
	--]]
	if msgType ~= "Hint" then
		task.spawn(function ()
			local textoAlEmpezar = msg.Text
			local restante = 30

			while msg.Parent do
				task.wait(5)

				if msg.Text ~= textoAlEmpezar then
					-- Ha cambiado: el juego sigue vivo, reiniciamos la cuenta.
					textoAlEmpezar = msg.Text
					restante = 30
				elseif pareceCarga(msg.Text) then
					restante = restante - 5

					if restante <= 0 and msg.Visible then
						warn(("[Messages] '%s' lleva 30s sin avanzar; lo oculto para "
							.. "no bloquear la pantalla."):format(msg.Text:sub(1, 60)))
						msg.Visible = false
						return
					end
				else
					-- No es una carga: se queda. Muchos lugares de 2008 usan
					-- Message como HUD fijo ("Tornado Inactive", "Now Playing:
					-- None"...) y ocultarlos les rompe la interfaz.
					return
				end
			end
		end)
	end
end

local function registerMessage(obj)
	if obj:IsA("Message") then
		addMessage(obj)
	end
end

for _,v in pairs(workspace:GetDescendants()) do
	registerMessage(v)
end

for _,v in pairs(player:GetChildren()) do
	registerMessage(v)
end

player.ChildAdded:Connect(registerMessage)
workspace.DescendantAdded:Connect(registerMessage)