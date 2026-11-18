--[[
  TIN WORD WRITER - Survive Your Ideas
  Escribe automaticamente UNA palabra permitida solo cuando el juego muestra
  el campo de texto del Writer (es tu turno). No escribe en otros momentos.

  Palabras: desastres naturales, astronomia, clima, animales y memes en ingles (US).
  No incluye insultos, ideologias, paises ni palabras raciales.
  Compatible con Xeno (Luau estandar).
]]

local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local VIM     = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ENABLED  = true
local COOLDOWN = 2.0

-- Solo palabras reconocidas por el juego (fuente: wiki/guias de Survive Your Ideas)
local WORDS = {
	-- Desastres
	"Tsunami", "Tornado", "Supernova", "Black Hole", "Flood", "Volcano",
	"Earthquake", "Meteor", "Acid", "Sharknado", "Avalanche", "Lava",
	"Apocalypse", "Satellite", "Antimatter", "Flash Flood", "Fire",
	"Quicksand", "Destruction", "Rumbling",
	-- Clima / astronomia
	"Rain", "Snow", "Storm", "Fog", "Lightning", "Sandstorm", "Hail",
	"Ice", "Wind", "Heat", "Night", "Space", "Gravity",
	-- Animales / monstruos
	"Monkey", "Dinosaur", "Godzilla", "King Kong", "Shark", "Capybara",
	"Cat", "Goose", "Bees", "Octopus", "Dragon", "Alien",
	-- Memes / poderes
	"Skibidi", "Doge", "Fart", "MrBeast", "Tralalero", "Goku", "Naruto",
	"Pikachu", "Troll", "Aura", "Dance", "Upside Down", "67",
	"Tung Tung Sahur", "Sneeze", "Cry", "Sleep",
}

local lastSubmit  = 0
local submittedBox = nil

local function pickWord()
	return WORDS[math.random(1, #WORDS)]
end

local function isReallyVisible(obj)
	local cur = obj
	while cur and cur ~= playerGui do
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		cur = cur.Parent
	end
	return true
end

local function isChatBox(box)
	local cur = box
	while cur and cur ~= playerGui do
		local n = cur.Name:lower()
		if n:find("chat") or n:find("console") or n:find("executor") then
			return true
		end
		cur = cur.Parent
	end
	return false
end

-- Busca el TextBox del Writer: visible, editable y que no sea el chat
local function findWriterBox()
	for _, box in ipairs(playerGui:GetDescendants()) do
		if box:IsA("TextBox") and isReallyVisible(box) and not isChatBox(box) then
			if box.TextEditable ~= false then
				return box
			end
		end
	end
	return nil
end

-- Envia la palabra por el remote del juego si existe (metodo alternativo)
local function fireWordRemote(word)
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			local n = obj.Name:lower()
			if n:find("word") or n:find("submit") or n:find("type") or n:find("write") then
				pcall(function()
					if obj:IsA("RemoteFunction") then
						obj:InvokeServer(word)
					else
						obj:FireServer(word)
					end
				end)
				return true
			end
		end
	end
	return false
end

local function submitWord(box, word)
	-- Metodo principal: escribir en el TextBox y simular Enter
	pcall(function()
		box:CaptureFocus()
		box.Text = word
		box.FocusLost:Fire(true)
	end)
	pcall(function()
		VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
		VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
	end)
	-- Metodo alternativo por remote
	fireWordRemote(word)
	print("[TIN WRITER] Palabra enviada: " .. word)
end

RS.Heartbeat:Connect(function()
	if not ENABLED then return end

	local box = findWriterBox()
	if not box then
		submittedBox = nil
		return
	end

	local now = tick()
	if now - lastSubmit < COOLDOWN then return end

	-- Si ya escribimos en este campo, esperar a que aparezca uno nuevo
	if box == submittedBox and box.Text ~= "" then return end

	local word = pickWord()
	submitWord(box, word)

	lastSubmit = now
	submittedBox = box
end)

print("[TIN WRITER] Cargado. Escribe solo cuando aparece el campo del Writer.")
