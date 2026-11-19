--[[
  TIN BLOX HUB - Aimbot / Movimiento / Macro / ESP / Misc para Blox Fruits
  Tabs: MAIN, MOVIMIENTO, MACRO, ESP, MISC
  GUI verde/negro, semitransparente, arrastrable, minimizable.
  Compatible con Xeno (Luau estandar).
]]

local Players      = game:GetService("Players")
local RS           = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local HRS          = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- CONFIGURACION (guardable desde MISC)
--------------------------------------------------
local Config = {
	Aimbot       = false,
	ShowFOV      = true,
	FOV          = 140,
	AutoM1       = false,
	AttackSpeed  = 12,
	WalkEnabled  = false,
	WalkSpeed    = 16,
	JumpPower    = 60,
	AutoJump     = false,
	JumpInterval = 1.0,
	ESPNames     = false,
	ESPHealth    = false,
	ESPPvP       = false,
	ESPSize      = 14,
	MacroLoop    = true,
}

local COLORS = {
	bg     = Color3.fromRGB(8, 14, 10),
	top    = Color3.fromRGB(12, 24, 16),
	side   = Color3.fromRGB(10, 20, 14),
	panel  = Color3.fromRGB(14, 28, 18),
	btn    = Color3.fromRGB(20, 46, 28),
	green  = Color3.fromRGB(45, 220, 110),
	green2 = Color3.fromRGB(30, 160, 80),
	red    = Color3.fromRGB(210, 60, 70),
	text   = Color3.fromRGB(232, 255, 238),
	muted  = Color3.fromRGB(130, 175, 145),
	stroke = Color3.fromRGB(40, 90, 55),
	track  = Color3.fromRGB(10, 20, 14),
}

local ui = {}
local sliders = {}
local currentTarget = nil

--------------------------------------------------
-- AYUDAS DE UI
--------------------------------------------------
local function mkCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function mkStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.stroke
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function mkLabel(parent, text, size, pos, textSize, color, font)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.Text = text
	l.TextColor3 = color or COLORS.text
	l.BackgroundTransparency = 1
	l.Font = font or Enum.Font.Gotham
	l.TextSize = textSize or 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function mkBtn(parent, text, size, pos, color, onClick)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.Text = text
	b.TextColor3 = COLORS.text
	b.BackgroundColor3 = color or COLORS.btn
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.BorderSizePixel = 0
	b.Parent = parent
	mkCorner(b, 8)
	mkStroke(b, COLORS.stroke, 1)
	if onClick then b.MouseButton1Click:Connect(onClick) end
	return b
end

local function mkToggle(parent, text, size, pos, value, onChange)
	local b = mkBtn(parent, text .. ": " .. (value and "ON" or "OFF"), size, pos, value and COLORS.green2 or COLORS.red, nil)
	b.MouseButton1Click:Connect(function()
		value = not value
		b.Text = text .. ": " .. (value and "ON" or "OFF")
		b.BackgroundColor3 = value and COLORS.green2 or COLORS.red
		onChange(value)
	end)
	return b
end

-- Slider tipo barra de volumen
local function mkSlider(parent, name, min, max, value, step, onChange)
	local W = 400
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, W, 0, 58)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local lbl = mkLabel(holder, name .. ": " .. tostring(value), UDim2.new(0, W, 0, 22), UDim2.new(0, 0, 0, 0), 14, COLORS.text, Enum.Font.GothamBold)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(0, W - 10, 0, 10)
	track.Position = UDim2.new(0, 5, 0, 32)
	track.BackgroundColor3 = COLORS.track
	track.BorderSizePixel = 0
	track.Parent = holder
	mkCorner(track, 5)
	mkStroke(track, COLORS.stroke, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 0, 10)
	fill.BackgroundColor3 = COLORS.green
	fill.BorderSizePixel = 0
	fill.Parent = track
	mkCorner(fill, 5)

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.BackgroundColor3 = COLORS.text
	knob.Text = ""
	knob.BorderSizePixel = 0
	knob.Parent = track
	mkCorner(knob, 10)
	mkStroke(knob, COLORS.green, 2)

	local obj = { Value = value, Name = name }

	function obj:Set(v)
		v = math.clamp(v, min, max)
		v = math.floor((v / step) + 0.5) * step
		obj.Value = v
		local ratio = (v - min) / (max - min)
		fill.Size = UDim2.new(0, (W - 10) * ratio, 0, 10)
		knob.Position = UDim2.new(0, (W - 10) * ratio - 10, 0, -5)
		lbl.Text = name .. ": " .. tostring(math.floor(v * 100) / 100)
		onChange(v)
	end

	function obj:SetFromX(x)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		self:Set(min + ratio * (max - min))
	end

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			obj:SetFromX(input.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			obj:SetFromX(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	obj:Set(value)
	return obj
end

--------------------------------------------------
-- DETECCION PVP (heuristica: valores/atributos del jugador)
--------------------------------------------------
local function getPvP(p)
	local roots = { p, p.Character, p:FindFirstChildOfClass("Backpack") }
	for _, root in ipairs(roots) do
		if root then
			for _, o in ipairs(root:GetDescendants()) do
				local n = o.Name:lower()
				if (n == "pvp" or n == "pvpmode" or n == "pvpactive" or n == "safe" or n == "combat") then
					local v = o:IsA("ValueBase") and o.Value or nil
					if v ~= nil then
						if n == "safe" then return v and "OFF" or "ON" end
						return v and "ON" or "OFF"
					end
				end
			end
		end
	end
	for _, key in ipairs({ "Pvp", "PvP", "Safe", "Combat" }) do
		local a = p:GetAttribute(key) or (p.Character and p.Character:GetAttribute(key))
		if a ~= nil then
			if key == "Safe" then return a and "OFF" or "ON" end
			return a and "ON" or "OFF"
		end
	end
	return "?"
end

--------------------------------------------------
-- ESP (opciones independientes)
--------------------------------------------------
local esp = {}
local function clearESP(p)
	local e = esp[p]
	if e then
		pcall(function() e.gui:Destroy() end)
		esp[p] = nil
	end
end

local function ensureESP(p)
	if esp[p] then return esp[p] end
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local bg = Instance.new("BillboardGui")
	bg.Name = "TinESP"
	bg.Adornee = root
	bg.Size = UDim2.new(0, 190, 0, 78)
	bg.StudsOffset = Vector3.new(0, 2.6, 0)
	bg.AlwaysOnTop = true
	bg.Parent = char

	local nl = Instance.new("TextLabel")
	nl.Size = UDim2.new(1, 0, 0, 24)
	nl.Position = UDim2.new(0, 0, 0, 0)
	nl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nl.BackgroundTransparency = 0.35
	nl.TextColor3 = COLORS.green
	nl.Font = Enum.Font.GothamBold
	nl.TextSize = Config.ESPSize
	nl.Parent = bg
	mkCorner(nl, 4)

	local hl = nl:Clone()
	hl.Position = UDim2.new(0, 0, 0, 26)
	hl.TextColor3 = Color3.fromRGB(255, 120, 120)
	hl.Parent = bg

	local pl = nl:Clone()
	pl.Position = UDim2.new(0, 0, 0, 52)
	pl.TextColor3 = Color3.fromRGB(255, 220, 90)
	pl.Parent = bg

	esp[p] = { gui = bg, name = nl, health = hl, pvp = pl }
	return esp[p]
end

local function updateESP()
	local anyOn = Config.ESPNames or Config.ESPHealth or Config.ESPPvP
	for _, p in ipairs(Players:GetPlayers()) do
		if p == player or not anyOn or not p.Character then
			clearESP(p)
		else
			local e = ensureESP(p)
			if e then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				e.name.Visible = Config.ESPNames
				e.health.Visible = Config.ESPHealth
				e.pvp.Visible = Config.ESPPvP
				if Config.ESPNames then e.name.Text = p.Name end
				if Config.ESPHealth and hum then
					e.health.Text = "HP: " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
				end
				if Config.ESPPvP then e.pvp.Text = "PVP: " .. getPvP(p) end
				e.name.TextSize = Config.ESPSize
				e.health.TextSize = Config.ESPSize
				e.pvp.TextSize = Config.ESPSize
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(p) clearESP(p) end)

--------------------------------------------------
-- AIMBOT (solo jugadores, solo dentro del circulo FOV)
--------------------------------------------------
local function getTargetInFOV()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	local best, bestDist = nil, math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local root = p.Character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				local sp, onScreen = cam:WorldToScreenPoint(root.Position)
				if onScreen and sp.Z > 0 then
					local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
					if d <= Config.FOV and d < bestDist then
						bestDist = d
						best = { player = p, root = root, hum = hum }
					end
				end
			end
		end
	end
	return best
end

RS.RenderStepped:Connect(function()
	currentTarget = Config.Aimbot and getTargetInFOV() or nil
	if not currentTarget then return end

	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	local tp = currentTarget.root.Position

	-- El personaje mira al objetivo (asi las habilidades salen hacia el)
	if myRoot then
		local flat = Vector3.new(tp.X, myRoot.Position.Y, tp.Z)
		pcall(function()
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, flat)
		end)
	end
	-- La camara tambien apunta al torso del objetivo
	if cam then
		pcall(function()
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tp)
		end)
	end
end)

-- Circulo visual del FOV
local fovCircle = Instance.new("Frame")
fovCircle.Name = "TinFOV"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundColor3 = Color3.new(0, 0, 0)
fovCircle.BackgroundTransparency = 0.85
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = playerGui
mkCorner(fovCircle, 999)
mkStroke(fovCircle, COLORS.green, 2)

local function refreshFOV()
	fovCircle.Visible = Config.ShowFOV and Config.Aimbot
	fovCircle.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
end

--------------------------------------------------
-- M1 / MOVIMIENTO
--------------------------------------------------
local function m1Click()
	local cam = workspace.CurrentCamera
	local cx = cam and cam.ViewportSize.X / 2 or 500
	local cy = cam and cam.ViewportSize.Y / 2 or 300
	pcall(function()
		VIM:SendMouseButtonEvent(cx, cy, 0, true, game, false)
		VIM:SendMouseButtonEvent(cx, cy, 0, false, game, false)
	end)
end

task.spawn(function()
	while true do
		task.wait(math.max(0.02, 1 / math.max(1, Config.AttackSpeed)))
		if Config.AutoM1 and currentTarget then
			m1Click()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.3)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and Config.WalkEnabled then
			hum.WalkSpeed = Config.WalkSpeed
		end
		if hum and Config.AutoJump then
			hum.JumpPower = Config.JumpPower
			hum.Jump = true
			task.wait(Config.JumpInterval)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		updateESP()
		refreshFOV()
	end
end)

--------------------------------------------------
-- MACRO (grabar y repetir teclas / habilidades / clics)
--------------------------------------------------
local macro = {
	recording = false,
	playing   = false,
	events    = {},
	start     = 0,
}

local function macroLog(text)
	if ui.macroStatus then ui.macroStatus.Text = text end
end

UIS.InputBegan:Connect(function(input, gpe)
	if gpe or not macro.recording then return end
	local t = tick() - macro.start
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		table.insert(macro.events, { t = t, kind = "mouse" })
	elseif input.UserInputType == Enum.UserInputType.Keyboard then
		table.insert(macro.events, { t = t, kind = "down", key = input.KeyCode.Name })
	end
end)

UIS.InputEnded:Connect(function(input)
	if not macro.recording then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		table.insert(macro.events, { t = tick() - macro.start, kind = "up", key = input.KeyCode.Name })
	end
end)

local function playEvent(ev)
	if ev.kind == "mouse" then
		m1Click()
	else
		local k = Enum.KeyCode[ev.key]
		if k then
			pcall(function()
				VIM:SendKeyEvent(ev.kind == "down", k, false, game)
			end)
		end
	end
end

task.spawn(function()
	while true do
		if not macro.playing or #macro.events == 0 then
			task.wait(0.2)
		else
			local cycleStart = tick()
			for _, ev in ipairs(macro.events) do
				if not macro.playing then break end
				local elapsed = tick() - cycleStart
				local waitFor = ev.t - elapsed
				if waitFor > 0 then task.wait(waitFor) end
				playEvent(ev)
			end
			if macro.loop then
				-- continua
			else
				macro.playing = false
				if ui.macroPlay then
					ui.macroPlay.Text = "REPETIR: OFF"
					ui.macroPlay.BackgroundColor3 = COLORS.red
				end
			end
		end
	end
end)

--------------------------------------------------
-- MISC: guardar / cargar
--------------------------------------------------
local CONFIG_FILE = "TinBloxConfig.json"

local function miscLog(text)
	if ui.miscStatus then ui.miscStatus.Text = text end
end

local function saveConfig()
	local ok, err = pcall(function()
		writefile(CONFIG_FILE, HRS:JSONEncode(Config))
	end)
	miscLog(ok and ("Guardado: " .. CONFIG_FILE) or ("Error: " .. tostring(err)))
end

local function loadConfig()
	local ok, err = pcall(function()
		if isfile(CONFIG_FILE) then
			local data = HRS:JSONDecode(readfile(CONFIG_FILE))
			for k, v in pairs(data) do
				if Config[k] ~= nil then Config[k] = v end
			end
		end
	end)
	if not ok then
		miscLog("Error: " .. tostring(err))
		return
	end
	for _, s in pairs(sliders) do s:Set(Config[s.Key]) end
	if ui.toggles then
		for _, t in ipairs(ui.toggles) do t:Refresh() end
	end
	refreshFOV()
	miscLog("Configuracion cargada")
end

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TinBloxHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local circle = mkBtn(gui, "T", UDim2.new(0, 62, 0, 62), UDim2.new(0, 22, 0.42, 0), COLORS.green2, nil)
circle.TextSize = 26
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = circle
mkStroke(circle, COLORS.green, 2)
circle.Visible = false

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 580, 0, 500)
main.Position = UDim2.new(0.5, -290, 0.5, -250)
main.BackgroundColor3 = COLORS.bg
main.BackgroundTransparency = 0.18
main.BorderSizePixel = 0
main.Parent = gui
mkCorner(main, 14)
mkStroke(main, COLORS.green2, 2)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 46)
top.BackgroundColor3 = COLORS.top
top.BackgroundTransparency = 0.25
top.Parent = main
mkCorner(top, 14)

mkLabel(top, "TIN BLOX HUB", UDim2.new(0, 260, 0, 30), UDim2.new(0, 16, 0, 8), 19, COLORS.green, Enum.Font.GothamBold)
mkLabel(top, "Blox Fruits", UDim2.new(0, 130, 0, 24), UDim2.new(0, 190, 0, 12), 12, COLORS.muted)

local minBtn = mkBtn(top, "-", UDim2.new(0, 32, 0, 30), UDim2.new(1, -76, 0, 8), COLORS.btn, nil)
minBtn.TextSize = 20
local maxBtn = mkBtn(top, "+", UDim2.new(0, 32, 0, 30), UDim2.new(1, -40, 0, 8), COLORS.btn, nil)
maxBtn.TextSize = 20
maxBtn.Visible = false

local side = Instance.new("Frame")
side.Size = UDim2.new(0, 140, 1, -46)
side.Position = UDim2.new(0, 0, 0, 46)
side.BackgroundColor3 = COLORS.side
side.BackgroundTransparency = 0.3
side.Parent = main

local contentHost = Instance.new("Frame")
contentHost.Size = UDim2.new(1, -152, 1, -58)
contentHost.Position = UDim2.new(0, 146, 0, 52)
contentHost.BackgroundTransparency = 1
contentHost.Parent = main

local tabNames = { "MAIN", "MOVIMIENTO", "MACRO", "ESP", "MISC" }
local tabBtns, tabFrames = {}, {}

local function selectTab(idx)
	for i = 1, #tabNames do
		tabFrames[i].Visible = (i == idx)
		tabBtns[i].BackgroundColor3 = (i == idx) and COLORS.green2 or COLORS.btn
	end
end

for i, name in ipairs(tabNames) do
	tabBtns[i] = mkBtn(side, name, UDim2.new(0, 120, 0, 38), UDim2.new(0, 10, 0, 12 + (i - 1) * 48), COLORS.btn, function()
		selectTab(i)
	end)
	tabBtns[i].TextSize = 12

	local f = Instance.new("ScrollingFrame")
	f.Size = UDim2.new(1, 0, 1, 0)
	f.BackgroundColor3 = COLORS.panel
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	f.CanvasSize = UDim2.new(0, 0, 0, 470)
	f.ScrollBarThickness = 6
	f.ScrollBarImageColor3 = COLORS.green2
	f.Visible = (i == 1)
	f.Parent = contentHost
	mkCorner(f, 10)
	tabFrames[i] = f
end
selectTab(1)

ui.toggles = {}
local function addToggle(parent, text, pos, key)
	local b = mkToggle(parent, text, UDim2.new(0, 400, 0, 38), pos, Config[key], function(v)
		Config[key] = v
		refreshFOV()
	end)
	b.Refresh = function()
		Config[key] = Config[key] and true or false
		b.Text = text .. ": " .. (Config[key] and "ON" or "OFF")
		b.BackgroundColor3 = Config[key] and COLORS.green2 or COLORS.red
	end
	table.insert(ui.toggles, b)
	return b
end

local function addSlider(parent, name, pos, min, max, value, step, key)
	local s = mkSlider(parent, name, min, max, value, step, function(v)
		Config[key] = v
	end)
	s.Position = pos
	s.Key = key
	table.insert(sliders, s)
	return s
end

--------------------------------------------------
-- TAB 1: MAIN
--------------------------------------------------
local t1 = tabFrames[1]
addToggle(t1, "AIMBOT", UDim2.new(0, 14, 0, 14), "Aimbot")
addToggle(t1, "CIRCULO FOV", UDim2.new(0, 14, 0, 58), "ShowFOV")
addToggle(t1, "AUTO M1", UDim2.new(0, 14, 0, 102), "AutoM1")
addSlider(t1, "FOV (pixeles)", UDim2.new(0, 14, 0, 150), 40, 400, Config.FOV, 5, "FOV")
addSlider(t1, "GOLPES/SEG M1", UDim2.new(0, 14, 0, 218), 2, 50, Config.AttackSpeed, 1, "AttackSpeed")
mkLabel(t1, "Solo jugadores. NPCs ignorados. El objetivo se sigue", UDim2.new(0, 400, 0, 40), UDim2.new(0, 14, 0, 300), 12, COLORS.muted)
mkLabel(t1, "dentro del circulo; si sale, se suelta.", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 324), 12, COLORS.muted)
mkLabel(t1, "Cuerpo/Torso, sin necesidad de la cabeza.", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 350), 12, COLORS.muted)

--------------------------------------------------
-- TAB 2: MOVIMIENTO
--------------------------------------------------
local t2 = tabFrames[2]
addToggle(t2, "WALKSPEED", UDim2.new(0, 14, 0, 14), "WalkEnabled")
addSlider(t2, "VELOCIDAD", UDim2.new(0, 14, 0, 62), 16, 300, Config.WalkSpeed, 1, "WalkSpeed")
addSlider(t2, "FUERZA DE SALTO", UDim2.new(0, 14, 0, 132), 50, 500, Config.JumpPower, 5, "JumpPower")
addToggle(t2, "AUTO SALTO", UDim2.new(0, 14, 0, 202), "AutoJump")
addSlider(t2, "INTERVALO SALTO", UDim2.new(0, 14, 0, 250), 0.2, 5, Config.JumpInterval, 0.1, "JumpInterval")

mkBtn(t2, "SALTAR", UDim2.new(0, 190, 0, 44), UDim2.new(0, 14, 0, 326), COLORS.green2, function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.JumpPower = Config.JumpPower
		hum.Jump = true
	end
end)

mkBtn(t2, "RESET VELOCIDAD", UDim2.new(0, 190, 0, 44), UDim2.new(0, 214, 0, 326), COLORS.btn, function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
end)

--------------------------------------------------
-- TAB 3: MACRO
--------------------------------------------------
local t3 = tabFrames[3]
mkBtn(t3, "GRABAR", UDim2.new(0, 190, 0, 44), UDim2.new(0, 14, 0, 16), COLORS.green2, function()
	macro.events = {}
	macro.recording = true
	macro.start = tick()
	macroLog("Grabando...")
end)

mkBtn(t3, "PARAR", UDim2.new(0, 190, 0, 44), UDim2.new(0, 214, 0, 16), COLORS.red, function()
	macro.recording = false
	macroLog("Grabacion detenida: " .. #macro.events .. " eventos")
end)

ui.macroPlay = mkBtn(t3, "REPETIR: OFF", UDim2.new(0, 190, 0, 44), UDim2.new(0, 14, 0, 74), COLORS.red, nil)
ui.macroPlay.MouseButton1Click:Connect(function()
	macro.playing = not macro.playing
	ui.macroPlay.Text = "REPETIR: " .. (macro.playing and "ON" or "OFF")
	ui.macroPlay.BackgroundColor3 = macro.playing and COLORS.green2 or COLORS.red
end)

ui.macroLoop = mkToggle(t3, "CICLO", UDim2.new(0, 190, 0, 38), UDim2.new(0, 214, 0, 74), Config.MacroLoop, function(v)
	Config.MacroLoop = v
	macro.loop = v
end)
macro.loop = Config.MacroLoop

mkBtn(t3, "LIMPIAR", UDim2.new(0, 190, 0, 44), UDim2.new(0, 14, 0, 132), COLORS.btn, function()
	macro.events = {}
	macro.playing = false
	ui.macroPlay.Text = "REPETIR: OFF"
	ui.macroPlay.BackgroundColor3 = COLORS.red
	macroLog("Macro limpia")
end)

ui.macroStatus = mkLabel(t3, "Sin grabacion", UDim2.new(0, 400, 0, 44), UDim2.new(0, 14, 0, 196), 14, COLORS.green)
mkLabel(t3, "Graba teclas (1-9, Z, X, C...), movimiento W/A/S/D", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 250), 12, COLORS.muted)
mkLabel(t3, "y clics M1; luego REPETIR para ejecutar la secuencia.", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 276), 12, COLORS.muted)

--------------------------------------------------
-- TAB 4: ESP (opciones separadas)
--------------------------------------------------
local t4 = tabFrames[4]
addToggle(t4, "ESP NOMBRE", UDim2.new(0, 14, 0, 16), "ESPNames")
addToggle(t4, "ESP VIDA", UDim2.new(0, 14, 0, 66), "ESPHealth")
addToggle(t4, "ESP PVP", UDim2.new(0, 14, 0, 116), "ESPPvP")
addSlider(t4, "TAMANO TEXTO", UDim2.new(0, 14, 0, 170), 10, 28, Config.ESPSize, 1, "ESPSize")
mkLabel(t4, "Cada ESP funciona por separado.", UDim2.new(0, 400, 0, 24), UDim2.new(0, 14, 0, 250), 12, COLORS.muted)
mkLabel(t4, "PVP se lee de valores/atributos del jugador;", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 276), 12, COLORS.muted)
mkLabel(t4, "si el juego no lo expone muestra '?'.", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 300), 12, COLORS.muted)

--------------------------------------------------
-- TAB 5: MISC
--------------------------------------------------
local t5 = tabFrames[5]
mkBtn(t5, "GUARDAR CONFIG", UDim2.new(0, 400, 0, 48), UDim2.new(0, 14, 0, 18), COLORS.green2, saveConfig)
mkBtn(t5, "CARGAR CONFIG", UDim2.new(0, 400, 0, 48), UDim2.new(0, 14, 0, 80), COLORS.btn, loadConfig)
mkBtn(t5, "VALORES POR DEFECTO", UDim2.new(0, 400, 0, 48), UDim2.new(0, 14, 0, 142), COLORS.btn, function()
	Config.FOV = 140; Config.AttackSpeed = 12; Config.WalkSpeed = 16
	Config.JumpPower = 60; Config.JumpInterval = 1.0; Config.ESPSize = 14
	for _, s in pairs(sliders) do s:Set(Config[s.Key]) end
	for _, tg in ipairs(ui.toggles) do tg:Refresh() end
	refreshFOV()
	miscLog("Valores por defecto aplicados")
end)
ui.miscStatus = mkLabel(t5, "Sin guardar", UDim2.new(0, 400, 0, 26), UDim2.new(0, 14, 0, 210), 13, COLORS.green)
mkLabel(t5, "Archivo: " .. CONFIG_FILE, UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 244), 12, COLORS.muted)
mkLabel(t5, "Requiere que el executor soporte writefile/readfile.", UDim2.new(0, 400, 0, 22), UDim2.new(0, 14, 0, 270), 12, COLORS.muted)

--------------------------------------------------
-- MINIMIZAR / REABRIR / ARRASTRE
--------------------------------------------------
local FULL_SIZE = UDim2.new(0, 580, 0, 500)
local MIN_SIZE  = UDim2.new(0, 580, 0, 46)
local function setUIVisible(v)
	main.Visible = v
	circle.Visible = not v
end
minBtn.MouseButton1Click:Connect(function()
	main.Size = MIN_SIZE
	contentHost.Visible = false
	side.Visible = false
	minBtn.Visible = false
	maxBtn.Visible = true
end)
maxBtn.MouseButton1Click:Connect(function()
	main.Size = FULL_SIZE
	contentHost.Visible = true
	side.Visible = true
	minBtn.Visible = true
	maxBtn.Visible = false
end)
circle.MouseButton1Click:Connect(function() setUIVisible(true) end)

local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

refreshFOV()
print("TIN BLOX HUB cargado.")
