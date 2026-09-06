--!nocheck
--[[
	Bygone -- game menu, styled like a 2008 ROBLOX dialog.

	Where the games come from:
	  1. AssetService:GetGamePlacesAsync() lists the real places in the published
	     universe (id + name). Same source Shared/PlaceData.lua uses upstream.
	  2. ReplicatedStorage.CatalogoJuegos supplies what that API does not return:
	     creator, category, year and provenance. Matched by name.

	In Studio there is no universe, so the static catalogue is shown and the
	play button explains itself instead of erroring.

	Layout notes: everything is sized in scale, not pixels, and the whole window
	is driven by a UIScale that shrinks on small screens, so it works on phones
	and tablets as well as desktop.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local screen = script.Parent

local TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

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

local FONT = Enum.Font.Cartoon

local BADGE = {
	oficial      = { text = "OFFICIAL ROBLOX",  color = Color3.fromRGB( 41, 112,  41) },
	uncopylocked = { text = "UNCOPYLOCKED",     color = Color3.fromRGB( 41,  82, 143) },
	comunitario  = { text = "COMMUNITY ARCHIVE", color = Color3.fromRGB(120,  92,  20) },
	dudosa       = { text = "UNVERIFIED SOURCE", color = Color3.fromRGB(140,  45,  45) },
}

local CATEGORY_EN = {
	["Obbies y parkour"]      = "Obbies & Parkour",
	["Brickbattle y combate"] = "Brickbattle & Combat",
	["Desastres y fisica"]    = "Disasters & Physics",
	["Zombis y terror"]       = "Zombies & Horror",
	["Vehiculos y tycoons"]   = "Vehicles & Tycoons",
	["Rol y ciudades"]        = "Roleplay & Towns",
	["Clasicos varios"]       = "Assorted Classics",
}

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

local catalogue = {}
do
	local module = ReplicatedStorage:FindFirstChild("CatalogoJuegos")
	if module then
		local ok, data = pcall(require, module)
		if ok and type(data) == "table" then
			catalogue = data
		end
	end
end

local byName = {}
for _, entry in ipairs(catalogue) do
	byName[entry.titulo:lower()] = entry
end

local function iterPageItems(pages)
	return coroutine.wrap(function ()
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(item)
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
end

local function buildList()
	local games, seen = {}, {}

	-- Live lookup, only as a supplement. It is not the source of truth: if the
	-- call fails or comes back empty in a live server, every game would show up
	-- as unpublished and nothing would be playable.
	local live = {}
	local ok, pages = pcall(function ()
		return game:GetService("AssetService"):GetGamePlacesAsync()
	end)

	if ok then
		for place in iterPageItems(pages) do
			if place.PlaceId ~= game.PlaceId then
				live[place.Name:lower()] = { name = place.Name, id = place.PlaceId }
			end
		end
	end

	-- The catalogue is authoritative: it ships the place ids baked in.
	for _, entry in ipairs(catalogue) do
		local key = entry.titulo:lower()
		seen[key] = true

		table.insert(games, {
			title = entry.titulo,
			placeId = entry.placeId or (live[key] and live[key].id),
			creator = entry.creador,
			category = CATEGORY_EN[entry.categoria] or entry.categoria,
			source = entry.procedencia,
			year = entry.anio,
		})
	end

	-- Anything in the universe that the catalogue does not know about.
	for key, place in pairs(live) do
		if not seen[key] then
			table.insert(games, {
				title = place.name,
				placeId = place.id,
				creator = "ROBLOX",
				category = "Assorted Classics",
				source = "comunitario",
			})
		end
	end

	table.sort(games, function (a, b)
		if a.category ~= b.category then
			return a.category < b.category
		end
		return a.title:lower() < b.title:lower()
	end)

	return games
end

local games = buildList()

local categories = { "All" }
do
	local seen = {}
	for _, g in ipairs(games) do
		if not seen[g.category] then
			seen[g.category] = true
			table.insert(categories, g.category)
		end
	end
	table.sort(categories, function (a, b)
		if a == "All" then return true end
		if b == "All" then return false end
		return a < b
	end)
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
	Size = UDim2.fromOffset(680, 440),
}, dim)

-- Fits the dialog to whatever screen it lands on: phones shrink it, tablets
-- and desktops cap it so it never turns into a wall of stretched grey.
local scaler = new("UIScale", { Scale = 1 }, window)

local function fitToScreen()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	if not vp or vp.X == 0 then
		return
	end

	local margin = TOUCH and 0.96 or 0.9
	local scale = math.min((vp.X * margin) / 680, (vp.Y * margin) / 440)
	scaler.Scale = math.clamp(scale, 0.42, 1.25)
end

new("Frame", {
	Name = "BevelLight", BorderSizePixel = 0, ZIndex = 11,
	BackgroundColor3 = Color3.fromRGB(222, 222, 222), Size = UDim2.new(1, 0, 0, 1),
}, window)
new("Frame", {
	Name = "BevelDark", BorderSizePixel = 0, ZIndex = 11,
	BackgroundColor3 = GREY_DARK, Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
}, window)

local titleBar = new("Frame", {
	Name = "TitleBar", BackgroundColor3 = GREY_TITLE, BorderSizePixel = 0, ZIndex = 12,
	Size = UDim2.new(1, -2, 0, 26), Position = UDim2.fromOffset(1, 1),
}, window)

new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 17, ZIndex = 13,
	TextColor3 = Color3.fromRGB(245, 245, 245), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "  Bygone  -  choose a game", Size = UDim2.new(1, -60, 1, 0),
}, titleBar)

local closeBtn = new("TextButton", {
	Name = "Close", BackgroundColor3 = GREY_BG, BorderSizePixel = 0, ZIndex = 13,
	Font = FONT, TextSize = 17, TextColor3 = TEXT_MAIN, Text = "X", AutoButtonColor = true,
	Size = UDim2.fromOffset(26, 20), Position = UDim2.new(1, -29, 0, 3),
}, titleBar)

local countLbl = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 12,
	TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	Size = UDim2.fromOffset(200, 20), Position = UDim2.fromOffset(10, 32),
}, window)

local searchBox = new("TextBox", {
	Name = "Search", BackgroundColor3 = Color3.fromRGB(240, 240, 240), BorderSizePixel = 1,
	BorderColor3 = GREY_DARK, ZIndex = 12, Font = FONT, TextSize = 15,
	TextColor3 = TEXT_MAIN, PlaceholderText = "Search...", Text = "",
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	Size = UDim2.fromOffset(250, 24), Position = UDim2.new(1, -260, 0, 30),
}, window)
new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, searchBox)

local catPanel = new("Frame", {
	Name = "Categories", BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1,
	BorderColor3 = GREY_DARK, ZIndex = 12,
	Size = UDim2.new(0, 178, 1, -152), Position = UDim2.fromOffset(10, 60),
}, window)
local catList = new("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12,
	Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = TOUCH and 14 or 8,
}, catPanel)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, catList)

local gamePanel = new("Frame", {
	Name = "Games", BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1,
	BorderColor3 = GREY_DARK, ZIndex = 12,
	Size = UDim2.new(1, -208, 1, -152), Position = UDim2.fromOffset(198, 60),
}, window)
local gameList = new("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12,
	Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = TOUCH and 14 or 8,
}, gamePanel)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, gameList)

local info = new("Frame", {
	Name = "Info", BackgroundColor3 = GREY_PANEL, BorderSizePixel = 1,
	BorderColor3 = GREY_DARK, ZIndex = 12,
	Size = UDim2.new(1, -20, 0, 78), Position = UDim2.new(0, 10, 1, -88),
}, window)

local infoTitle = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 19, ZIndex = 13,
	TextColor3 = TEXT_MAIN, TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Select a game", Size = UDim2.new(1, -170, 0, 24),
	Position = UDim2.fromOffset(10, 6),
}, info)

local infoSub = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 15, ZIndex = 13,
	TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	Size = UDim2.new(1, -170, 0, 18), Position = UDim2.fromOffset(10, 31),
}, info)

local infoBadge = new("TextLabel", {
	BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0, ZIndex = 13,
	Font = FONT, TextSize = 12, TextColor3 = Color3.fromRGB(240, 240, 240),
	Text = "", Visible = false,
	Size = UDim2.fromOffset(160, 17), Position = UDim2.fromOffset(10, 52),
}, info)

local playBtn = new("TextButton", {
	Name = "Play", BackgroundColor3 = GREY_BG, BorderSizePixel = 1, BorderColor3 = GREY_DARK,
	ZIndex = 13, Font = FONT, TextSize = 20, TextColor3 = TEXT_DIM, Text = "Play",
	AutoButtonColor = true, Active = false,
	Size = UDim2.fromOffset(132, 40), Position = UDim2.new(1, -144, 0.5, -20),
}, info)

local status = new("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 13,
	TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right, Text = "",
	Size = UDim2.fromOffset(320, 18), Position = UDim2.new(1, -332, 1, -20),
}, window)

--------------------------------------------------------------------------------
-- Behaviour
--------------------------------------------------------------------------------

local selected = nil
local activeCategory = "All"
local filter = ""

local function paintInfo()
	if not selected then
		infoTitle.Text = "Select a game"
		infoSub.Text = ""
		infoBadge.Visible = false
		playBtn.Active = false
		playBtn.TextColor3 = TEXT_DIM
		return
	end

	infoTitle.Text = selected.title
	infoSub.Text = ("by %s%s  -  %s"):format(
		selected.creator or "unknown",
		selected.year and (" - " .. selected.year) or "",
		selected.category or "")

	local badge = BADGE[selected.source or "comunitario"]
	if badge then
		infoBadge.Text = " " .. badge.text
		infoBadge.BackgroundColor3 = badge.color
		infoBadge.Visible = true
	else
		infoBadge.Visible = false
	end

	local playable = selected.placeId ~= nil and selected.placeId ~= 0
	playBtn.Active = playable
	playBtn.TextColor3 = playable and TEXT_MAIN or TEXT_DIM
	status.TextColor3 = TEXT_DIM
	status.Text = playable and "" or "This game is not published in the universe yet."
end

local rows = {}

local function refreshList()
	for _, row in ipairs(rows) do
		row:Destroy()
	end
	rows = {}

	local order, shown = 0, 0

	for _, game_ in ipairs(games) do
		local matches = (activeCategory == "All" or game_.category == activeCategory)
		if matches and filter ~= "" then
			matches = game_.title:lower():find(filter, 1, true) ~= nil
				or (game_.creator or ""):lower():find(filter, 1, true) ~= nil
		end

		if matches then
			order = order + 1
			shown = shown + 1

			local row = new("TextButton", {
				BackgroundColor3 = SEL_BG, BackgroundTransparency = 1, BorderSizePixel = 0,
				ZIndex = 13, LayoutOrder = order, Font = FONT, TextSize = 16,
				TextColor3 = TEXT_MAIN, TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false, Text = ("  %s   "):format(game_.title),
				-- Taller rows on touch: 22px is unhittable with a thumb.
				Size = UDim2.new(1, -8, 0, TOUCH and 34 or 23),
			}, gameList)

			new("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 14, ZIndex = 13,
				TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right,
				Text = (game_.creator or "") .. "  ",
				Size = UDim2.new(0, 170, 1, 0), Position = UDim2.new(1, -170, 0, 0),
			}, row)

			row.MouseEnter:Connect(function ()
				if selected ~= game_ then
					row.BackgroundTransparency = 0.6
				end
			end)
			row.MouseLeave:Connect(function ()
				if selected ~= game_ then
					row.BackgroundTransparency = 1
				end
			end)
			row.Activated:Connect(function ()
				for _, other in ipairs(rows) do
					other.BackgroundTransparency = 1
					other.TextColor3 = TEXT_MAIN
				end
				row.BackgroundTransparency = 0
				row.TextColor3 = WHITE
				selected = game_
				paintInfo()
			end)

			table.insert(rows, row)
		end
	end

	countLbl.Text = ("%d games"):format(shown)
end

for i, category in ipairs(categories) do
	local btn = new("TextButton", {
		BackgroundColor3 = SEL_BG, BackgroundTransparency = 1, BorderSizePixel = 0,
		ZIndex = 13, LayoutOrder = i, Font = FONT, TextSize = 16, TextColor3 = TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
		Text = "  " .. category, TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -8, 0, TOUCH and 34 or 25),
	}, catList)

	btn.Activated:Connect(function ()
		for _, other in ipairs(catList:GetChildren()) do
			if other:IsA("TextButton") then
				other.BackgroundTransparency = 1
				other.TextColor3 = TEXT_MAIN
			end
		end
		btn.BackgroundTransparency = 0
		btn.TextColor3 = WHITE
		activeCategory = category
		selected = nil
		refreshList()
		paintInfo()
	end)

	if category == "All" then
		btn.BackgroundTransparency = 0
		btn.TextColor3 = WHITE
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function ()
	filter = searchBox.Text:lower()
	refreshList()
end)

playBtn.Activated:Connect(function ()
	if not (selected and playBtn.Active) then
		return
	end

	status.TextColor3 = TEXT_DIM
	status.Text = "Joining " .. selected.title .. "..."

	local ok, err = pcall(function ()
		TeleportService:Teleport(selected.placeId, player)
	end)

	if not ok then
		status.TextColor3 = Color3.fromRGB(140, 45, 45)
		status.Text = "Teleporting only works in the published game."
		warn("[Menu] Teleport failed:", err)
	end
end)

--------------------------------------------------------------------------------
-- Opening and closing
--------------------------------------------------------------------------------

local function setOpen(open)
	dim.Visible = open
	if open then
		fitToScreen()
	end
end

closeBtn.Activated:Connect(function ()
	setOpen(false)
end)

-- Always-available way in. On phones and tablets there is no keyboard, so the
-- button is the only way; on desktop it doubles as a hint that M works.
local openBtn = new("TextButton", {
	Name = "OpenMenu", BackgroundColor3 = GREY_BG, BorderSizePixel = 1,
	BorderColor3 = GREY_DARK, ZIndex = 9, Font = FONT, TextSize = 16,
	TextColor3 = TEXT_MAIN, Text = "Games", AutoButtonColor = true,
	AnchorPoint = Vector2.new(1, 0),
	Size = UDim2.fromOffset(TOUCH and 108 or 92, TOUCH and 44 or 32),
	Position = UDim2.new(1, -12, 0, 46),
}, screen)

openBtn.Activated:Connect(function ()
	setOpen(not dim.Visible)
end)

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

-- A kiosk in the world opens it too: any BasePart named "KioscoDeJuegos" or
-- carrying the boolean attribute "MenuDeJuegos".
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart")
		and (obj.Name == "KioscoDeJuegos" or obj:GetAttribute("MenuDeJuegos")) then
		local prompt = new("ProximityPrompt", {
			ActionText = "Choose a game", ObjectText = "Bygone",
			HoldDuration = 0, RequiresLineOfSight = false, MaxActivationDistance = 12,
		}, obj)
		prompt.Triggered:Connect(function ()
			setOpen(true)
		end)
	end
end

-- Re-fit on rotation, window resize or a phone folding open.
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)
end
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fitToScreen)

fitToScreen()
refreshList()
paintInfo()

if #games > 0 then
	task.delay(1.5, function ()
		setOpen(true)
	end)
end
