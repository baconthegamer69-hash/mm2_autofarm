local plr = game.Players.LocalPlayer

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local UserInputService = game:GetService("UserInputService")

local VirtualUser = game:GetService('VirtualUser')

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local invis_on = false

local defaultSpeed = 23

local boostedSpeed = 69

local isSpeedBoosted = false

-- TP KILL

local tpActive = false

local lastTpTime = 0

local TP_INTERVAL = 0.2

local TP_DISTANCE = 0.6

local lastTargetPlayer = nil

-- Farm (ZETA)

local Zeta = {Speed = 23, CollectionRange = 0.2}

local character, humanoid, root

local connections = {}

local currentTarget = nil

local farmActive = false

-- МОНЕТЫ

local coinCount = 0

local maxCoinsReached = false

local MAX_COINS_ON_MAP = 40

local lastPrintedCoinCount = -1

local grabItemActive = false

-- ФАЗЫ

local PHASE = "WAITING"

local lastMapName = ""

local invizEnabledForKill = false

-- АВТОКЛИК

local autoClickActive = true

-- 🔍 ДЕТЕКТОР ИНВИЗА

local RESET_IMAGE_OLD = "http://www.roblox.com/asset/?id=189761558"

local RESET_IMAGE_NEW = "http://www.roblox.com/asset/?id=304416585"

local lastImageState = RESET_IMAGE_OLD

-- ============== ФИКСИРОВАННЫЙ НАКЛОН 90° ==============

local TILT_ANGLE_X = math.rad(90)

local Y_OFFSET = -2

local function lockTiltTo90(bodyGyro, root)
    if not bodyGyro or not root then return end
    
    local lockedCFrame = CFrame.new(root.Position) * CFrame.Angles(TILT_ANGLE_X, 0, 0)
    
    bodyGyro.CFrame = lockedCFrame
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 40000
    bodyGyro.D = 500
end

-- Sound

local sound = Instance.new("Sound", plr:WaitForChild("PlayerGui"))

sound.Volume = 1

-- ============== TRANSPARENCY ==============

local function setTransparency(character, transparency)

for _, part in pairs(character:GetDescendants()) do

if part:IsA("BasePart") or part:IsA("Decal") then

part.Transparency = transparency

end

end

end

local function enableInvis(char)

if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

local savedpos = char.HumanoidRootPart.CFrame

char:MoveTo(Vector3.new(-25.95, 84, 3537.55))

task.wait(0.15)

local Seat = Instance.new('Seat', workspace)

Seat.Anchored = false

Seat.CanCollide = false

Seat.Name = 'invischair_' .. math.random(1, 10000)

Seat.Transparency = 1

Seat.Position = Vector3.new(-25.95, 84, 3537.55)

local Weld = Instance.new("Weld", Seat)

Weld.Part0 = Seat

Weld.Part1 = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")

task.wait(0.1)

Seat.CFrame = savedpos

setTransparency(char, 0.5)

invis_on = true

return true

end

local function disableInvis(char)

if not char then return false end

for _, seat in ipairs(workspace:GetChildren()) do

if seat.Name:match("invischair_") then seat:Destroy() end

end

setTransparency(char, 0)

invis_on = false

return true

end

-- ============== АВТО-ИНВИЗ ПРИ СМЕНЕ UI ==============

task.spawn(function()

while true do

task.wait(0.3)

pcall(function()

local waitingUI = plr.PlayerGui:FindFirstChild("MainGUI")

if waitingUI then

waitingUI = waitingUI:FindFirstChild("Game")

if waitingUI then

waitingUI = waitingUI:FindFirstChild("Waiting")

if waitingUI and waitingUI:IsA("ImageLabel") then

local currentImage = waitingUI.Image

if currentImage == RESET_IMAGE_NEW and lastImageState ~= RESET_IMAGE_NEW then

print("⚠️ ОБНАРУЖЕНА СМЕНА UI! ВКЛЮЧАЮ ИНВИЗ!")

lastImageState = RESET_IMAGE_NEW

if plr.Character then

enableInvis(plr.Character)

print("👻 ИНВИЗ АКТИВИРОВАН!")

sound:Play()

end

elseif currentImage == RESET_IMAGE_OLD then

lastImageState = RESET_IMAGE_OLD

end

end

end

end

end)

end

end)

-- ============== АВТО-ЭКИП ==============

local function autoEquip()

pcall(function()

local backpack = plr.Backpack

if backpack then

local items = backpack:GetChildren()

if #items > 0 then

local firstItem = items[1]

firstItem.Parent = plr.Character

task.wait(0.05)

end

end

end)

end

-- ============== АВТОКЛИК (0.4 СЕКУНДЫ) - ДВОЙНЫЕ КЛИКИ ==============

task.spawn(function()

while true do

if autoClickActive then

pcall(function()

VirtualUser:ClickButton1(Vector2.new(200, 200))

task.wait(0.02)

VirtualUser:ClickButton1(Vector2.new(960, 970))

end)

end

task.wait(0.4)

end

end)

-- ============== АВТО-GRAB ==============

task.spawn(function()

while true do

task.wait(0.3)

if grabItemActive and plr.Character then

local backpack = plr.Backpack

if backpack then

local items = backpack:GetChildren()

if #items > 0 then

local firstItem = items[1]

pcall(function()

firstItem.Parent = plr.Character

end)

task.wait(0.1)

end

end

end

end

end)

-- ============== МОНИТОРИНГ МОНЕТ ==============

local function setupCoinTracking()

print("📊 НАСТРАИВАЮ МОНИТОРИНГ МОНЕТ...")

pcall(function()

local CoinCollectedRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")

if CoinCollectedRemote:IsA("RemoteEvent") then

CoinCollectedRemote.OnClientEvent:Connect(function(...)

coinCount = coinCount + 1

if coinCount == 1 then

print("🎯 ПЕРВАЯ МОНЕТА! ВКЛЮЧАЮ АВТО-GRAB")

grabItemActive = true

end

end)

print("✅ Мониторинг включен!")

end

end)

end

-- ============== ПОИСК КАРТЫ ==============

local function findMap()

for _, obj in pairs(workspace:GetChildren()) do

if obj:IsA("Model") and (obj:FindFirstChild("CoinContainer") or obj:FindFirstChild("Normal") or obj:FindFirstChild("Coins")) then

return obj

end

end

return nil

end

-- ============== ПОИСК РАНДОМНОЙ МОНЕТЫ ==============

local function findRandomCoin()

local map = findMap()

if not map then return nil end

local container = map:FindFirstChild("CoinContainer") or map:FindFirstChild("Normal") or map:FindFirstChild("Coins")

if not container then return nil end

local coins = {}

for _, obj in pairs(container:GetDescendants()) do

if obj:IsA("BasePart") then

local touch = obj:FindFirstChild("TouchInterest") or obj:FindFirstChildOfClass("TouchTransmitter")

if touch then

table.insert(coins, obj)

end

end

end

if #coins > 0 then

return coins[math.random(1, #coins)]

end

return nil

end

local function toggleInvisibility()

if not plr.Character then return end

if invis_on then disableInvis(plr.Character)

else enableInvis(plr.Character) end

sound:Play()

end

-- ============== SPEED BOOST ==============

local function toggleSpeedBoost()

isSpeedBoosted = not isSpeedBoosted

sound:Play()

local humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")

if humanoid then

humanoid.WalkSpeed = isSpeedBoosted and boostedSpeed or defaultSpeed

end

end

local function applySpeedToCharacter(character)

local humanoid = character:WaitForChild("Humanoid")

humanoid.WalkSpeed = isSpeedBoosted and boostedSpeed or defaultSpeed

invis_on = false

end

local function setupCharacterEvents(character)

local humanoid = character:WaitForChild("Humanoid")

humanoid.Died:Connect(function()

if character and character:FindFirstChild("HumanoidRootPart") then

enableInvis(character)

end

task.wait(1)

if plr.Character and plr.Character ~= character then

task.wait(0.5)

enableInvis(plr.Character)

end

end)

end

if plr.Character then

applySpeedToCharacter(plr.Character)

setupCharacterEvents(plr.Character)

end

plr.CharacterAdded:Connect(function(character)

applySpeedToCharacter(character)

setupCharacterEvents(character)

end)

-- ============== КЛАВИШИ ==============

UserInputService.InputBegan:Connect(function(input, gameProcessed)

if gameProcessed then return end

if input.KeyCode == Enum.KeyCode.V then toggleInvisibility() end

if input.KeyCode == Enum.KeyCode.B then toggleSpeedBoost() end

end)

-- ============== ESP ==============

local function getTargetFromUI()

local success, targetLabel = pcall(function()

return plr.PlayerGui.MainGUI.Game.Target3.TargetName

end)

if success and targetLabel and targetLabel.Text and targetLabel.Text ~= "" then

return Players:FindFirstChild(targetLabel.Text)

end

return nil

end

RunService.RenderStepped:Connect(function()

if plr.Character then

local old = plr.Character:FindFirstChild("_mm2_target_highlight")

if old then old:Destroy() end

end

local target = getTargetFromUI()

if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then

local hl = target.Character:FindFirstChild("_mm2_target_highlight")

if not hl then

hl = Instance.new("Highlight")

hl.FillColor = Color3.new(1, 0.3, 0.1)

hl.OutlineColor = Color3.fromRGB(255, 220, 40)

hl.Name = "_mm2_target_highlight"

hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

hl.Parent = target.Character

end

end

end)

-- ============== KILL ТП ==============

local function tryTeleportToTarget()

local currentTime = tick()

if currentTime - lastTpTime < TP_INTERVAL then return end

lastTpTime = currentTime

if not tpActive then return end

if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end

local targetPlayer = getTargetFromUI()

if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

if lastTargetPlayer ~= targetPlayer then

print("🎯 НОВЫЙ ТАРГЕТ! ЭКИПАЮ...")

autoEquip()

lastTargetPlayer = targetPlayer

end

local MyRoot = plr.Character.HumanoidRootPart

local TargetRoot = targetPlayer.Character.HumanoidRootPart

local targetPos = TargetRoot.Position

local behindPos = targetPos + (TargetRoot.CFrame.LookVector * -TP_DISTANCE)

local newCFrame = CFrame.new(behindPos, targetPos)

pcall(function()

MyRoot.CFrame = newCFrame

plr.Character:SetPrimaryPartCFrame(newCFrame)

autoEquip()

end)

end

task.spawn(function()

while true do

if tpActive then tryTeleportToTarget() end

task.wait(0.05)

end

end)

-- ============== ZETA FARM (НОВАЯ СИСТЕМА ПОЛЁТА) ==============

local function findNearestCoin()

if not character or not root then return nil end

local map = findMap()

if not map then return nil end

local nearest, nearestDist = nil, math.huge

local container = map:FindFirstChild("CoinContainer") or map:FindFirstChild("Normal") or map:FindFirstChild("Coins")

if container then

for _, obj in pairs(container:GetDescendants()) do

if obj:IsA("BasePart") then

local touch = obj:FindFirstChild("TouchInterest") or obj:FindFirstChildOfClass("TouchTransmitter")

if touch then

local dist = (obj.Position - root.Position).Magnitude

if dist < nearestDist then

nearestDist = dist

nearest = obj

end

end

end

end

end

return nearest, nearestDist

end

local function completeFarmCleanup()

farmActive = false

currentTarget = nil

for name, conn in pairs(connections) do

if conn then conn:Disconnect() end

connections[name] = nil

end

if humanoid and humanoid.Parent then humanoid.PlatformStand = false end

if root and root.Parent then

for _, obj in pairs(root:GetChildren()) do

if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then

obj:Destroy()

end

end

end

character, humanoid, root = nil, nil, nil

end

local function startFarmFromScratch()

print("🚀 START FARM - ТИЛЬТ 90° АВТОМАТИЧЕСКИЙ")

character = plr.Character

if not character then

character = plr.Character or plr.CharacterAdded:Wait()

end

humanoid = character:WaitForChild("Humanoid")

root = character:WaitForChild("HumanoidRootPart")

local map = findMap()

if not map then

print("❌ MAP NOT FOUND")

return false

end

for _, part in pairs(character:GetDescendants()) do

if part:IsA("BasePart") then

part.CanCollide = false

end

end

local bodyVelocity = Instance.new("BodyVelocity")

bodyVelocity.Velocity = Vector3.new(0, 0, 0)

bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

bodyVelocity.Parent = root

local bodyGyro = Instance.new("BodyGyro")

bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

bodyGyro.P = 40000

bodyGyro.D = 500

bodyGyro.Parent = root

-- СРАЗУ ВКЛЮЧАЕМ НАКЛОН 90°

lockTiltTo90(bodyGyro, root)

local speed = 23

local frequency = 0.08

local direction = 1

local lastTime = tick()

connections.fly = RunService.Heartbeat:Connect(function()

if not farmActive or not root then return end

local currentTime = tick()

if currentTime - lastTime >= frequency then

direction = -direction

lastTime = currentTime

end

local moveVector = Vector3.new(0, direction * speed, 0)

local coin = game.Workspace:FindFirstChild("coin_server")

if not coin then

local nearestCoin = findNearestCoin()

if nearestCoin then

coin = nearestCoin

end

end

if coin then

local targetPos = coin.Position + Vector3.new(0, Y_OFFSET, 0)

local direction_to_coin = (targetPos - root.Position).Unit

moveVector = moveVector + direction_to_coin * 23

end

bodyVelocity.Velocity = moveVector

-- ПОСТОЯННАЯ ФИКСАЦИЯ НАКЛОНА 90°

lockTiltTo90(bodyGyro, root)

end)

connections.noclip = RunService.Stepped:Connect(function()

if not farmActive or not character then return end

for _, part in pairs(character:GetDescendants()) do

if part:IsA("BasePart") then

part.CanCollide = false

end

end

end)

farmActive = true

connections.death = humanoid.Died:Connect(function()

completeFarmCleanup()

end)

print("✅ FARM ACTIVE - НАКЛОН 90° ЗАКРЕПЛЁН!")

return true

end

-- ============== ГЛАВНАЯ ЛОГИКА ==============

task.spawn(function()

while true do

task.wait(0.5)

local currentMap = findMap()

local mapName = currentMap and currentMap.Name or ""

if mapName ~= "" and mapName ~= lastMapName then

print("\n🗺️ 🗺️ 🗺️ NEW MAP: " .. mapName .. " 🗺️ 🗺️ 🗺️")

lastMapName = mapName

PHASE = "FARM"

tpActive = false

invizEnabledForKill = false

coinCount = 0

maxCoinsReached = false

lastPrintedCoinCount = -1

grabItemActive = false

lastTargetPlayer = nil

if invis_on and plr.Character then

disableInvis(plr.Character)

end

if farmActive then

completeFarmCleanup()

end

task.wait(1)

if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then

local randomCoin = findRandomCoin()

if randomCoin then

print("📍 ТЕЛЕПОРТИРУЮСЬ К МОНЕТЕ...")

plr.Character.HumanoidRootPart.CFrame = CFrame.new(randomCoin.Position + Vector3.new(0, Y_OFFSET, 0))

task.wait(0.5)

end

end

print("📦 Максимум монет на карте: " .. MAX_COINS_ON_MAP)

startFarmFromScratch()

elseif mapName == "" and lastMapName ~= "" then

print("🗺️ MAP DISAPPEARED")

lastMapName = ""

PHASE = "WAITING"

tpActive = false

invizEnabledForKill = false

grabItemActive = false

lastTargetPlayer = nil

if farmActive then

completeFarmCleanup()

end

end

if PHASE == "FARM" and farmActive then

if coinCount >= MAX_COINS_ON_MAP and not maxCoinsReached then

maxCoinsReached = true

print("✅ ВСЕ МОНЕТЫ СОБРАНЫ! (" .. coinCount .. "/" .. MAX_COINS_ON_MAP .. ")")

print("⚔️ УБИВАЮ ВСЕХ!")

grabItemActive = false

PHASE = "KILL"

farmActive = false

completeFarmCleanup()

if plr.Character and not invis_on then

enableInvis(plr.Character)

invizEnabledForKill = true

end

end

end

if PHASE == "KILL" and not tpActive then

tpActive = true

end

end

end)

plr.Idled:Connect(function()

VirtualUser:CaptureController()

VirtualUser:ClickButton2(Vector2.new())

end)

task.spawn(function()

task.wait(0.8)

setupCoinTracking()

end)

task.wait(1)

enableInvis(plr.Character)

game.StarterGui:SetCore("SendNotification", {

Title = "MM2 ULTRA v5.20 - AUTO TILT 90°",

Text = "Y=-2 + Наклон 90° АВТОМАТИЧЕСКИЙ! Готово!",

Duration = 5

})

print("🛸 MM2 ULTRA v5.20 LOADED!")

print("🎮 V=Invis | B=Speed")

print("⚡ SPEED: 23 (BodyVelocity Flight)")

print("🔒 НАКЛОН: 90° АВТОМАТИЧЕСКИЙ И ПОСТОЯННЫЙ")

print("📍 Y-OFFSET: -2 (летит в точку Y монеты - 2)")

print("🔧 BodyGyro P=40000 + D=500 (напряженное крепление)")

print("🖱️ АВТОКЛИК АКТИВЕН (0.4 сек)")

print("👻 АВТО-ИНВИЗ ПРИ СМЕНЕ UI")

print("🎯 ТАРГЕТИНГ МОНЕТ АКТИВЕН")

-- 🔄 Автоперезаход при превышении лимита памяти (Xeno)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

local MAX_MEMORY = 5000 -- MB

while wait(1) do
    local ClientMemory = Stats:GetTotalMemoryUsageMb()
    print("Client Memory Usage: " .. math.floor(ClientMemory) .. " MB")
    
    if ClientMemory >= MAX_MEMORY then
        print("⚠️ Превышен лимит памяти! Перезаход...")
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
        break
    end
end
