--!nocheck
--[[
	Lugar retirado.

	Open Cloud sabe actualizar un lugar pero no borrarlo, asi que los lugares
	cuyo contenido se retira del universo se sobrescriben con este: un cuarto
	vacio que explica por que y devuelve al jugador al vestibulo.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TEXTO = "This place has been retired.\n\nIt is not part of Bygone any more.\nReturning to the lobby..."

local function alEntrar(player)
	local aviso = Instance.new("Message")
	aviso.Text = TEXTO
	aviso.Parent = player:FindFirstChildOfClass("PlayerGui") or player

	task.delay(5, function ()
		local hub = ReplicatedStorage:FindFirstChild("HubPlaceId")

		if hub and hub.Value > 0 and hub.Value ~= game.PlaceId then
			pcall(function ()
				TeleportService:Teleport(hub.Value, player)
			end)
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	alEntrar(player)
end

Players.PlayerAdded:Connect(alEntrar)
