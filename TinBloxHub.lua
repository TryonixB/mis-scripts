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
local Workspace    = game:GetService("Workspace")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- CONFIGURACION (guardable desde MISC)
--------------------------------------------------
local Config = {
	-- Main / Aimbot
	Aimbot       = false,
	ShowFOV      = true,
	FOV          = 140,
	Range        = 200,
	AutoM1       = false,
	AttackSpeed  = 12,
	UseMouse     = true,
	AttackTouch  = true,
	FireRemote   = true,
	-- Movimiento
	WalkEnabled  = false,
	WalkSpeed    = 16,
	JumpPower    = 60,
	AutoJump     = false,
	JumpInterval = 1.0,
	-- ESP
	ESPPlayer    = false,
	ESPName      = false,
	ESPDistance  = false,
	ESPBox       = false,
	ESPTracer    = false,
	TeamCheck    = true,
	-- Macro
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
	b.AutoButtonColor = true
	b.Parent = parent
	mkCorner(b, 8)
	mkStroke(b, COLORS.stroke, 1)
	if onClick then b.MouseButton1Click:Connect(onClick) end
	return b
end

local function mkToggle(parent, text, size, pos, value, onChange)
	local b = mkBtn(parent, "", size, pos, value and COLORS.green2 or COLORS.red, nil)
	local function refresh()
		b.Text = text .. ": " .. (value and "ON" or "OFF")
		b.BackgroundColor3 = value and COLORS.green2 or COLORS.red
	end
	refresh()
	b.MouseButton1Click:Connect(function()
		value = not value
		refresh()
		onChange(value)
	end)
	return b, function(v)
		value = v and true or false
		refresh()
	end
end

-- Slider tipo barra de volumen
local function mkSlider(parent, name, min, max, value, step, onChange)
	local W = 390
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
	knob.AutoButtonColor = false
	knob.Parent = track
	mkCorner(knob, 10)
	mkStroke(knob, COLORS.green, 2)

	local obj = { Value = value, Name = name, Set = nil }

	function obj:Set(v)
		v = math.clamp(v, min, max)
		v = math.floor((v / step) + 0.5) * step
		obj.Value = v
		local ratio = (max == min) and 0 or (v - min) / (max - min)
		fill.Size = UDim2.new(0, (W - 10) * ratio, 0, 10)
		knob.Position = UDim2.new(0, (W - 10) * ratio - 10, 0, -5)
		local shown = math.floor(v * 100 + 0.5) / 100
		lbl.Text = name .. ": " .. tostring(shown)
		onChange(v)
	end

	local function setFromX(x)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		obj:Set(min + ratio * (max - min))
	end

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(input.Position.X)
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
-- UTILIDADES DE JUGADOR / TEAM CHECK
--------------------------------------------------
local function isTeammate(p)
	if not Config.TeamCheck then return false end
	if player.Team and p.Team then
		return player.Team == p.Team
	end
	return false
end

local function getCharData(p)
	local char = p.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if not hum or not root or hum.Health <= 0 then return nil end
	return char, hum, root
end

--------------------------------------------------
-- ESP
--------------------------------------------------
local espObjects = {}

local function clearESP(p)
	local o = espObjects[p]
	if not o then return end
	pcall(function() if o.gui then o.gui:Destroy() end end)
	pcall(function() if o.box then o.box:Remove() end end)
	pcall(function() if o.tracer then o.tracer:Remove() end end)
	espObjects[p] = nil
end

local function clearAllESP()
	for p, _ in pairs(espObjects) do
		clearESP(p)
	end
end

local function newDrawing(className)
	local ok, obj = pcall(function() return Drawing.new(className) end)
	if ok then return obj end
	return nil
end

local function ensureESP(p)
	if espObjects[p] then return espObjects[p] end
	local char = p.Character
	if not char then return nil end

	local gui = Instance.new("BillboardGui")
	gui.Name = "TinESP"
	gui.Size = UDim2.new(0, 220, 0, 40)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.green
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextStrokeTransparency = 0.2
	label.Text = ""
	label.Parent = gui

	espObjects[p] = {
		gui = gui,
		label = label,
		box = newDrawing("Square"),
		tracer = newDrawing("Line"),
	}
	local o = espObjects[p]
	if o.box then
		o.box.Thickness = 1
		o.box.Filled = false
		o.box.Color = COLORS.green
		o.box.Visible = false
	end
	if o.tracer then
		o.tracer.Thickness = 1
		o.tracer.Color = COLORS.green
		o.tracer.Visible = false
	end
	return o
end

local function hideESPObject(o)
	if not o then return end
	if o.gui then o.gui.Enabled = false end
	if o.box then o.box.Visible = false end
	if o.tracer then o.tracer.Visible = false end
end

local function updateESP()
	local cam = Workspace.CurrentCamera
	local anyOn = Config.ESPPlayer or Config.ESPName or Config.ESPDistance or Config.ESPBox or Config.ESPTracer
	if not anyOn or not cam then
		for _, o in pairs(espObjects) do hideESPObject(o) end
		return
	end

	local vp = cam.ViewportSize
	local bottom = Vector2.new(vp.X / 2, vp.Y)

	for _, p in ipairs(Players:GetPlayers()) do
		if p == player then
			clearESP(p)
		else
			local char, hum, root = getCharData(p)
			if not char or isTeammate(p) then
				if espObjects[p] then hideESPObject(espObjects[p]) end
			else
				local o = ensureESP(p)
				if o then
					o.gui.Adornee = root
					local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
					local sp, onScreen = cam:WorldToViewportPoint(root.Position)

					-- Texto (Player/Name/Distance)
					local showText = (Config.ESPPlayer or Config.ESPName or Config.ESPDistance) and onScreen and sp.Z > 0
					o.gui.Enabled = showText
					if showText then
						local parts = {}
						if Config.ESPName or Config.ESPPlayer then table.insert(parts, p.Name) end
						if Config.ESPDistance then table.insert(parts, string.format("[%dm]", math.floor(dist))) end
						o.label.Text = table.concat(parts, " ")
					end

					-- Box ESP
					if o.box then
						if Config.ESPBox and onScreen and sp.Z > 0 then
							local head = char:FindFirstChild("Head")
							local topPos = head and head.Position + Vector3.new(0, 0.5, 0) or (root.Position + Vector3.new(0, 2.5, 0))
							local legPos = root.Position - Vector3.new(0, 3, 0)
							local top2d, topOn = cam:WorldToViewportPoint(topPos)
							local leg2d, legOn = cam:WorldToViewportPoint(legPos)
							if topOn or legOn then
								local h = math.abs(top2d.Y - leg2d.Y)
								local w = h * 0.6
								o.box.Size = Vector2.new(w, h)
								o.box.Position = Vector2.new(sp.X - w / 2, sp.Y - h / 2)
								o.box.Visible = true
							else
								o.box.Visible = false
							end
						else
							o.box.Visible = false
						end
					end

					-- Tracer ESP
					if o.tracer then
						if Config.ESPTracer and onScreen and sp.Z > 0 then
							o.tracer.From = bottom
							o.tracer.To = Vector2.new(sp.X, sp.Y)
							o.tracer.Visible = true
						else
							o.tracer.Visible = false
						end
					end
				end
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(p) clearESP(p) end)

--------------------------------------------------
-- AIMBOT (solo jugadores, dentro del circulo FOV y del rango)
--------------------------------------------------
local mousemoverel      = mousemoverel or mousemove or nil
local mousemoveabs      = mousemoveabs or nil
local mouse1click       = mouse1click or nil
local firetouchinterest = firetouchinterest or nil

local function getTarget()
	local cam = Workspace.CurrentCamera
	if not cam then return nil end
	local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local best, bestScore = nil, math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and not isTeammate(p) then
			local char, hum, root = getCharData(p)
			if char and hum and root then
				local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
				if dist <= Config.Range then
					local sp, onScreen = cam:WorldToViewportPoint(root.Position)
					if onScreen and sp.Z > 0 then
						local screen = Vector2.new(sp.X, sp.Y)
						local d = (screen - center).Magnitude
						if d <= Config.FOV and d < bestScore then
							bestScore = d
							best = { player = p, root = root, hum = hum, screen = screen }
						end
					end
				end
			end
		end
	end
	return best
end

--------------------------------------------------
-- FOV CIRCLE
--------------------------------------------------
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
-- ATAQUE M1
--------------------------------------------------
local function fireCombatRemote()
	if not Config.FireRemote or not currentTarget then return end
	local rsvc = game:GetService("ReplicatedStorage")
	for _, obj in ipairs(rsvc:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			local n = obj.Name:lower()
			if n:find("combat") or n:find("attack") or n:find("melee") or n:find("m1") then
				pcall(function() obj:FireServer(currentTarget.root) end)
			end
		end
	end
end

local function m1Click()
	local cam = Workspace.CurrentCamera
	local cx = cam and cam.ViewportSize.X / 2 or 500
	local cy = cam and cam.ViewportSize.Y / 2 or 300

	if mouse1click then pcall(mouse1click) end

	if Config.AttackTouch and firetouchinterest and currentTarget then
		pcall(function()
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if myRoot and currentTarget.root then
				firetouchinterest(myRoot, currentTarget.root, 0)
				firetouchinterest(myRoot, currentTarget.root, 1)
			end
		end)
	end

	fireCombatRemote()

	pcall(function()
		VIM:SendMouseButtonEvent(cx, cy, 0, true, game, false)
		VIM:SendMouseButtonEvent(cx, cy, 0, false, game, false)
	end)
end

--------------------------------------------------
-- LOOPS
--------------------------------------------------
RS.RenderStepped:Connect(function()
	if not Config.Aimbot then
		currentTarget = nil
		refreshFOV()
		return
	end
	currentTarget = getTarget()
	refreshFOV()
	if not currentTarget then return end

	local cam = Workspace.CurrentCamera
	local tp = currentTarget.root.Position
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

	if Config.UseMouse and cam and currentTarget.screen then
		pcall(function()
			if mousemoveabs then
				mousemoveabs(currentTarget.screen.X, currentTarget.screen.Y)
			elseif mousemoverel then
				local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
				local delta = currentTarget.screen - center
				mousemoverel(delta.X, delta.Y)
			end
		end)
	end

	if myRoot then
		pcall(function()
			local flat = Vector3.new(tp.X, myRoot.Position.Y, tp.Z)
			myRoot.CFrame = CFrame.lookAt(myRoot.Position, flat)
		end)
	end

	if (not Config.UseMouse or (not mousemoveabs and not mousemoverel)) and cam then
		pcall(function()
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tp)
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(math.max(0.02, 1 / math.max(1, Config.AttackSpeed)))
		if Config.AutoM1 then
			m1Click()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and Config.WalkEnabled then
			hum.WalkSpeed = Config.WalkSpeed
		end
	end
end)

task.spawn(function()
	while true do
		if Config.AutoJump then
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.JumpPower = Config.JumpPower
				hum.Jump = true
			end
			task.wait(math.max(0.2, Config.JumpInterval))
		else
			task.wait(0.2)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		pcall(updateESP)
	end
end)

--------------------------------------------------
-- MACRO
--------------------------------------------------
local macro = {
	recording = false,
	playing   = false,
	events    = {},
	start     = 0,
	loop      = Config.MacroLoop,
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
			pcall(function() VIM:SendKeyEvent(ev.kind == "down", k, false, game) end)
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
				local waitFor = ev.t - (tick() - cycleStart)
				if waitFor > 0 then task.wait(waitFor) end
				playEvent(ev)
			end
			if not Config.MacroLoop then
				macro.playing = false
				if ui.macroPlay and ui.macroPlay.RefreshPlay then
					ui.macroPlay:RefreshPlay(false)
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
	for _, s in ipairs(sliders) do
		if s.Key and Config[s.Key] ~= nil then s:Set(Config[s.Key]) end
	end
	for _, t in ipairs(ui.toggles or {}) do
		if t.Refresh then t:Refresh() end
	end
	macro.loop = Config.MacroLoop
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
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 580, 0, 500)
main.Position = UDim2.new(0.5, -290, 0.5, -250)
main.BackgroundColor3 = COLORS.bg
main.BackgroundTransparency = 0.18
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
mkCorner(main, 14)
mkStroke(main, COLORS.green2, 2)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 46)
top.BackgroundColor3 = COLORS.top
top.BackgroundTransparency = 0.25
top.BorderSizePixel = 0
top.Active = true
top.Parent = main
mkCorner(top, 14)

mkLabel(top, "TIN BLOX HUB", UDim2.new(0, 260, 0, 30), UDim2.new(0, 16, 0, 8), 19, COLORS.green, Enum.Font.GothamBold)
mkLabel(top, "Blox Fruits", UDim2.new(0, 130, 0, 24), UDim2.new(0, 190, 0, 12), 12, COLORS.muted)

local minBtn = mkBtn(top, "-", UDim2.new(0, 32, 0, 30), UDim2.new(1, -40, 0, 8), COLORS.btn, nil)
minBtn.TextSize = 20

local side = Instance.new("Frame")
side.Size = UDim2.new(0, 140, 1, -46)
side.Position = UDim2.new(0, 0, 0, 46)
side.BackgroundColor3 = COLORS.side
side.BackgroundTransparency = 0.3
side.BorderSizePixel = 0
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
	f.CanvasSize = UDim2.new(0, 0, 0, 620)
	f.ScrollBarThickness = 6
	f.ScrollBarImageColor3 = COLORS.green2
	f.Visible = (i == 1)
	f.Parent = contentHost
	mkCorner(f, 10)
	tabFrames[i] = f
end
selectTab(1)

ui.toggles = {}
local function addToggle(parent, text, pos, key, afterChange)
	local b, setVal = mkToggle(parent, text, UDim2.new(0, 390, 0, 38), pos, Config[key], function(v)
		Config[key] = v
		if afterChange then afterChange(v) end
		refreshFOV()
	end)
	b.Refresh = function()
		setVal(Config[key])
	end
	table.insert(ui.toggles, b)
	return b
end

local function addSlider(parent, name, pos, min, max, value, step, key)
	local s = mkSlider(parent, name, min, max, value, step, function(v)
		Config[key] = v
		if key == "FOV" then refreshFOV() end
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
addToggle(t1, "MOUSE REAL", UDim2.new(0, 14, 0, 102), "UseMouse")
addToggle(t1, "AUTO M1", UDim2.new(0, 14, 0, 146), "AutoM1")
addToggle(t1, "GOLPE TOUCH", UDim2.new(0, 14, 0, 190), "AttackTouch")
addToggle(t1, "REMOTO COMBAT", UDim2.new(0, 14, 0, 234), "FireRemote")
addSlider(t1, "FOV (pixeles)", UDim2.new(0, 14, 0, 282), 40, 400, Config.FOV, 5, "FOV")
addSlider(t1, "RANGO (studs)", UDim2.new(0, 14, 0, 350), 20, 500, Config.Range, 10, "Range")
addSlider(t1, "GOLPES/SEG M1", UDim2.new(0, 14, 0, 418), 2, 50, Config.AttackSpeed, 1, "AttackSpeed")
mkLabel(t1, "Solo jugadores. NPCs ignorados. Apunta al torso dentro del FOV.", UDim2.new(0, 390, 0, 20), UDim2.new(0, 14, 0, 500), 12, COLORS.muted)
mkLabel(t1, "Si el aim no mueve camara, prueba MOUSE REAL OFF.", UDim2.new(0, 390, 0, 20), UDim2.new(0, 14, 0, 524), 12, COLORS.muted)

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
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
	end
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
	macroLog("Grabacion detenida: " .. tostring(#macro.events) .. " eventos")
end)

ui.macroPlay = mkBtn(t3, "REPETIR: OFF", UDim2.new(0, 190, 0, 44), UDim2.new(0, 14, 0, 74), COLORS.red, nil)
function ui.macroPlay:RefreshPlay(on)
	self.Text = "REPETIR: " .. (on and "ON" or "OFF")
	self.BackgroundColor3 = on and COLORS.green2 or COLORS.red
end
ui.macroPlay.MouseButton1Click:Connect(function()
	macro.playing = not macro.playing
	ui.macroPlay:RefreshPlay(macro.playing)
end)

addToggle(t3, "CICLO", UDim2.new(0, 190, 0, 38), UDim2.new(0, 214, 0, 74), "MacroLoop", function(v)
	macro.loop = v
end)

mkBtn(t3, "LIMPIAR", UDim2.new(0, 190, 0, 44), UDim2.new(0, 14, 0, 132), COLORS.btn, function()
	macro.events = {}
	macro.playing = false
	ui.macroPlay:RefreshPlay(false)
	macroLog("Macro limpia")
end)

ui.macroStatus = mkLabel(t3, "Sin grabacion", UDim2.new(0, 390, 0, 44), UDim2.new(0, 14, 0, 196), 14, COLORS.green)
mkLabel(t3, "Graba teclas, movimiento y clics M1.", UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 250), 12, COLORS.muted)
mkLabel(t3, "REPETIR ejecuta la secuencia guardada.", UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 276), 12, COLORS.muted)

--------------------------------------------------
-- TAB 4: ESP
--------------------------------------------------
local t4 = tabFrames[4]
addToggle(t4, "PLAYER ESP", UDim2.new(0, 14, 0, 16), "ESPPlayer")
addToggle(t4, "NAME ESP", UDim2.new(0, 14, 0, 66), "ESPName")
addToggle(t4, "DISTANCE ESP", UDim2.new(0, 14, 0, 116), "ESPDistance")
addToggle(t4, "BOX ESP", UDim2.new(0, 14, 0, 166), "ESPBox")
addToggle(t4, "TRACER ESP", UDim2.new(0, 14, 0, 216), "ESPTracer")
addToggle(t4, "TEAM CHECK", UDim2.new(0, 14, 0, 266), "TeamCheck", function()
	clearAllESP()
end)

mkLabel(t4, "Cada opcion es independiente.", UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 320), 12, COLORS.muted)
mkLabel(t4, "Team Check oculta a los de tu mismo equipo.", UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 346), 12, COLORS.muted)
mkLabel(t4, "Box/Tracer requieren Drawing (executor).", UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 372), 12, COLORS.muted)

--------------------------------------------------
-- TAB 5: MISC
--------------------------------------------------
local t5 = tabFrames[5]
mkBtn(t5, "GUARDAR CONFIG", UDim2.new(0, 390, 0, 48), UDim2.new(0, 14, 0, 18), COLORS.green2, saveConfig)
mkBtn(t5, "CARGAR CONFIG", UDim2.new(0, 390, 0, 48), UDim2.new(0, 14, 0, 80), COLORS.btn, loadConfig)
mkBtn(t5, "VALORES POR DEFECTO", UDim2.new(0, 390, 0, 48), UDim2.new(0, 14, 0, 142), COLORS.btn, function()
	Config.Aimbot = false
	Config.ShowFOV = true
	Config.FOV = 140
	Config.Range = 200
	Config.AutoM1 = false
	Config.AttackSpeed = 12
	Config.UseMouse = true
	Config.AttackTouch = true
	Config.FireRemote = true
	Config.WalkEnabled = false
	Config.WalkSpeed = 16
	Config.JumpPower = 60
	Config.AutoJump = false
	Config.JumpInterval = 1.0
	Config.ESPPlayer = false
	Config.ESPName = false
	Config.ESPDistance = false
	Config.ESPBox = false
	Config.ESPTracer = false
	Config.TeamCheck = true
	Config.MacroLoop = true
	for _, s in ipairs(sliders) do if s.Key then s:Set(Config[s.Key]) end end
	for _, t in ipairs(ui.toggles) do if t.Refresh then t:Refresh() end end
	macro.loop = Config.MacroLoop
	refreshFOV()
	miscLog("Valores por defecto aplicados")
end)

mkBtn(t5, "REINICIAR ESP", UDim2.new(0, 390, 0, 48), UDim2.new(0, 14, 0, 204), COLORS.btn, function()
	clearAllESP()
	miscLog("ESP reiniciado")
end)

ui.miscStatus = mkLabel(t5, "Sin guardar", UDim2.new(0, 390, 0, 26), UDim2.new(0, 14, 0, 270), 13, COLORS.green)
mkLabel(t5, "Archivo: " .. CONFIG_FILE, UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 300), 12, COLORS.muted)
mkLabel(t5, "Guardar/Cargar requiere writefile/readfile/isfile.", UDim2.new(0, 390, 0, 22), UDim2.new(0, 14, 0, 326), 12, COLORS.muted)

--------------------------------------------------
-- MINIMIZAR / REABRIR / ARRASTRE
--------------------------------------------------
local circle = mkBtn(gui, "T", UDim2.new(0, 56, 0, 56), UDim2.new(0, 20, 0.45, 0), COLORS.green2, nil)
circle.TextSize = 24
circle.Visible = false
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = circle
mkStroke(circle, COLORS.green, 2)

local function minimizeUI()
	main.Visible = false
	circle.Visible = true
end
local function restoreUI()
	main.Visible = true
	circle.Visible = false
end

minBtn.MouseButton1Click:Connect(minimizeUI)
circle.MouseButton1Click:Connect(restoreUI)

local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

top.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updateDrag(input)
	end
end)

--------------------------------------------------
-- INICIO
--------------------------------------------------
refreshFOV()
print("[TIN BLOX HUB] Cargado. Tabs: MAIN/MOVIMIENTO/MACRO/ESP/MISC")
