-- ZABOTA Loader
-- Список рабочих зеркал для raw GitHub
local timestamp = tostring(os.time())
local urls = {
    "https://raw.githubusercontent.com/dagpker-glitch/ZABOTA/main/ZabotaLib.lua?t=" .. timestamp,
    "https://cdn.jsdelivr.net/gh/dagpker-glitch/ZABOTA@main/ZabotaLib.lua",
    "https://fastly.jsdelivr.net/gh/dagpker-glitch/ZABOTA@main/ZabotaLib.lua",
    "https://raw.githack.com/dagpker-glitch/ZABOTA/main/ZabotaLib.lua"
}

local content = nil
local lastError = ""
local MAX_ATTEMPTS_PER_URL = 2

for _, url in ipairs(urls) do
    for attempt = 1, MAX_ATTEMPTS_PER_URL do
        local success, response = pcall(function()
            return game:HttpGet(url, true)
        end)

        if success and type(response) == "string" and response ~= "" and not string.find(response, "404: Not Found") and not string.find(response, "Cannot find") then
            content = response
            break
        else
            lastError = success and "empty/invalid response" or tostring(response)
            if attempt < MAX_ATTEMPTS_PER_URL then
                task.wait(0.5)
            end
        end
    end
    if content then break end
end

if not content or content == "" then
    warn("[ZABOTA Error] Не удалось получить исходный код ни с одного зеркала. Последняя ошибка: " .. lastError)
    warn("Решения:")
    warn("1. Открой репозиторий dagpker-glitch/ZABOTA -> Settings -> в самом низу проверь 'Change repository visibility' (должно быть PUBLIC).")
    warn("2. Проверь регистр букв в названии файла (ZabotaLib.lua, а не zabotalib.lua или ZabotaLib.LUA).")
    warn("3. Проверь, разрешён ли HttpGet к внешним доменам в твоём экзекьюторе.")
    return
end

-- Инициализация библиотеки
local libChunk, libCompileErr = loadstring(content)
if not libChunk then
    warn("[ZABOTA Error] ZabotaLib.lua загрузился, но не скомпилировался: " .. tostring(libCompileErr))
    return
end

local libOk, ZabotaLib = pcall(libChunk)
if not libOk or not ZabotaLib then
    warn("[ZABOTA Error] Ошибка при выполнении ZabotaLib.lua: " .. tostring(ZabotaLib))
    return
end

----------------------------------------------------------------
-- Игровые сервисы и ссылки (реальная логика фич для San Diego
-- Border RP — та же логика, что в zabota_menu.lua, но управляется
-- через красивый интерфейс ZabotaLib вместо голых TextButton)
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local DropsFolder = Workspace:FindFirstChild("Drops")

local LoaderConnections = {}
local function track(conn)
    table.insert(LoaderConnections, conn)
    return conn
end

local Config = {
    SpeedEnabled = false,
    SpeedValue = 300,
    FlyEnabled = false,
    FlySpeed = 200,
    SilentAimEnabled = false,
    TriggerbotEnabled = false,
    ProjectileSpeed = 350,
    FOV = 250,
    MaxDistance = 400,
    EspEnabled = false,
    PoliceWantedEsp = false,
    MagnetEnabled = false,
    VehicleShootFix = false,
    HitboxEnabled = false,
    HitboxSize = 8,
    HardStickEnabled = false,
}

----------------------------------------------------------------
-- Faction / target helpers
----------------------------------------------------------------
local function isPoliceTeam(player)
    if not player then return false end
    local team = player.Team
    local teamName = team and string.lower(team.Name) or ""

    return string.find(teamName, "police") ~= nil or
           string.find(teamName, "polic") ~= nil or
           string.find(teamName, "полиц") ~= nil or
           string.find(teamName, "border") ~= nil or
           string.find(teamName, "patrol") ~= nil or
           string.find(teamName, "патрул") ~= nil or
           string.find(teamName, "guard") ~= nil or
           string.find(teamName, "army") ~= nil or
           string.find(teamName, "fbi") ~= nil or
           string.find(teamName, "swat") ~= nil or
           string.find(teamName, "bortac") ~= nil or
           string.find(teamName, "coast") ~= nil
end

local function isTargetValid(player, amICop)
    if not player or player == LocalPlayer then return false end
    local targetIsCop = isPoliceTeam(player)
    local wanted = player:GetAttribute("WantedLevel") or 0

    if amICop then
        return (wanted > 0) and not targetIsCop
    else
        return targetIsCop
    end
end

----------------------------------------------------------------
-- Teleports
----------------------------------------------------------------
local function tpToPriorityTarget()
    local targetHRP = nil
    local shortestDist = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local amICop = isPoliceTeam(LocalPlayer)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if isTargetValid(player, amICop) then
                local hrp = player.Character.HumanoidRootPart
                local dist = (hrp.Position - myRoot.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    targetHRP = hrp
                end
            end
        end
    end

    if targetHRP then
        myRoot.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
    end
end

local function tpToNearestMoney()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local targetPart = nil
    local shortestDist = math.huge

    if not DropsFolder or not DropsFolder.Parent then
        DropsFolder = Workspace:FindFirstChild("Drops")
    end

    if DropsFolder then
        for _, drop in ipairs(DropsFolder:GetChildren()) do
            local part = drop:IsA("BasePart") and drop or (drop:IsA("Model") and (drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")))
            if part then
                local dist = (part.Position - myRoot.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    targetPart = part
                end
            end
        end
    end

    if targetPart then
        myRoot.CFrame = targetPart.CFrame + Vector3.new(0, 2.5, 0)
    end
end

local function cursorTeleport()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and Mouse.Hit then
        myRoot.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end

----------------------------------------------------------------
-- Окно
----------------------------------------------------------------
local Window = ZabotaLib:CreateWindow({
    Title = "ZABOTA",
    ToggleKey = Enum.KeyCode.RightShift,
    Version = "v2.0"
})

local HUD = Window:CreateHUD("KEYBINDS")
HUD:AddBind("RShift", "ZABOTA Menu", "TOGGLE")
HUD:AddBind("F1", "Speed", "TOGGLE")
HUD:AddBind("F2", "TP Target", "ACTION")
HUD:AddBind("F4", "Triggerbot", "TOGGLE")
HUD:AddBind("F5", "Fly", "TOGGLE")
HUD:AddBind("F6", "Hitboxes", "TOGGLE")
HUD:AddBind("F7", "Silent Aim", "TOGGLE")
HUD:AddBind("H", "Magnet", "TOGGLE")
HUD:AddBind("J", "TP Cash", "ACTION")
HUD:AddBind("X", "1v1 Stick", "TOGGLE")
HUD:AddBind("G", "TP Cursor", "ACTION")

local movementTab = Window:AddTab("Movement")
local combatTab   = Window:AddTab("Combat")
local visualTab   = Window:AddTab("Visual")
local exploitTab  = Window:AddTab("Exploits")
local configTab   = Window:AddTab("Config")

----------------------------------------------------------------
-- Movement tab
----------------------------------------------------------------
local MoveCard = movementTab:AddCard("Movement", {icon = "🏃", side = "left"})

local FlyHandle = {}

local SpeedCheck = MoveCard:AddCheckbox("Speed [F1]", false, function(state)
    Config.SpeedEnabled = state
end)

MoveCard:AddSlider("Speed Value", 50, 500, Config.SpeedValue, 10, function(v)
    Config.SpeedValue = v
end)

local function setFly(state)
    Config.FlyEnabled = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bv = hrp:FindFirstChild("ZabotaFlyBodyVelocity")
        local bg = hrp:FindFirstChild("ZabotaFlyBodyGyro")
        if state then
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "ZabotaFlyBodyVelocity"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp
            end
            if not bg then
                bg = Instance.new("BodyGyro")
                bg.Name = "ZabotaFlyBodyGyro"
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bg.CFrame = Camera.CFrame
                bg.Parent = hrp
            end
        else
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
    end
end

local FlyCheck = MoveCard:AddCheckbox("Fly [F5]", false, function(state)
    setFly(state)
end)

MoveCard:AddSlider("Fly Speed", 50, 400, Config.FlySpeed, 10, function(v)
    Config.FlySpeed = v
end)

local TPCard = movementTab:AddCard("Teleports", {icon = "📍", side = "right"})
TPCard:AddButton("TP to Priority Target [F2]", tpToPriorityTarget)
TPCard:AddButton("TP to Dropped Cash [J]", tpToNearestMoney)
TPCard:AddButton("TP to Cursor [G]", cursorTeleport)

----------------------------------------------------------------
-- Movement runtime loops
----------------------------------------------------------------
track(RunService.Heartbeat:Connect(function(dt)
    if Config.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local char = LocalPlayer.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (Config.SpeedValue * dt))
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    if not Config.FlyEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bv = hrp:FindFirstChild("ZabotaFlyBodyVelocity")
    local bg = hrp:FindFirstChild("ZabotaFlyBodyGyro")

    if bv and bg then
        bg.CFrame = Camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        bv.Velocity = moveDir.Unit.Magnitude > 0 and (moveDir.Unit * Config.FlySpeed) or Vector3.new(0, 0, 0)
    end
end))

----------------------------------------------------------------
-- Combat tab
----------------------------------------------------------------
local AimCard = combatTab:AddCard("Combat", {icon = "🎯", side = "left"})

local TriggerCheck = AimCard:AddCheckbox("Triggerbot [F4]", false, function(state)
    Config.TriggerbotEnabled = state
end)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 255, 200)
FOVCircle.Filled = false
FOVCircle.Radius = Config.FOV
FOVCircle.Transparency = 0.7

local SilentAimCheck = AimCard:AddCheckbox("Silent Aim [F7]", false, function(state)
    Config.SilentAimEnabled = state
    FOVCircle.Visible = state
end)

AimCard:AddSlider("FOV Radius", 50, 500, Config.FOV, 10, function(v)
    Config.FOV = v
    FOVCircle.Radius = v
end)

AimCard:AddSlider("Max Distance", 100, 800, Config.MaxDistance, 25, function(v)
    Config.MaxDistance = v
end)

AimCard:AddSlider("Projectile Speed", 100, 600, Config.ProjectileSpeed, 10, function(v)
    Config.ProjectileSpeed = v
end)

local StickCard = combatTab:AddCard("1v1 Lock", {icon = "🔒", side = "right"})
local StickCheck = StickCard:AddCheckbox("Hard 1v1 Stick [X]", false, function(state)
    Config.HardStickEnabled = state
end)

----------------------------------------------------------------
-- Combat runtime loops
----------------------------------------------------------------
local isTriggerShooting = false
track(RunService.RenderStepped:Connect(function()
    if not Config.TriggerbotEnabled or isTriggerShooting then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local amICop = isPoliceTeam(LocalPlayer)
    local targetFound = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and isTargetValid(p, amICop) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (hrp.Position - myRoot.Position).Magnitude
                if distance <= 400 then
                    local velocity = Vector3.new(0, 0, 0)
                    local pHumanoid = p.Character:FindFirstChildOfClass("Humanoid")

                    if pHumanoid and pHumanoid.SeatPart and pHumanoid.SeatPart.Parent then
                        local vehicle = pHumanoid.SeatPart.Parent
                        local primary = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                        velocity = primary and primary.AssemblyLinearVelocity or pHumanoid.SeatPart.AssemblyLinearVelocity
                    else
                        velocity = hrp.AssemblyLinearVelocity
                    end

                    local timeToHit = distance / math.max(Config.ProjectileSpeed, 150)
                    local predictedPos = hrp.Position + (velocity * timeToHit) + Vector3.new(0, 1.5, 0)

                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    if onScreen then
                        local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                        local distToCenter = (screenVector - screenCenter).Magnitude

                        if distToCenter <= (Config.HitboxSize * 14) then
                            targetFound = true
                            break
                        end
                    end
                end
            end
        end
    end

    if targetFound then
        isTriggerShooting = true

        local currentTool = myChar:FindFirstChildOfClass("Tool")
        if currentTool then
            pcall(function() currentTool:Activate() end)
        end

        VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 1)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 1)

        task.wait(0.01)
        isTriggerShooting = false
    end
end))

track(RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos

    if Config.SilentAimEnabled then
        local targetPredictedPos = nil
        local shortestDist = Config.FOV
        local amICop = isPoliceTeam(LocalPlayer)
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and myRoot then
                if isTargetValid(player, amICop) then
                    local hrp = player.Character.HumanoidRootPart
                    local distance = (hrp.Position - myRoot.Position).Magnitude

                    if distance <= Config.MaxDistance then
                        local velocity = Vector3.new(0, 0, 0)
                        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

                        if humanoid and humanoid.SeatPart and humanoid.SeatPart.Parent then
                            local vehicle = humanoid.SeatPart.Parent
                            local primary = vehicle.PrimaryPart or vehicle:FindFirstChildWhichIsA("BasePart")
                            velocity = primary and primary.AssemblyLinearVelocity or humanoid.SeatPart.AssemblyLinearVelocity
                        else
                            velocity = hrp.AssemblyLinearVelocity
                        end

                        local timeToHit = distance / Config.ProjectileSpeed
                        local predictedPos = hrp.Position + (velocity * timeToHit)

                        local screenPoint, onScreen = Camera:WorldToViewportPoint(predictedPos)
                        if onScreen then
                            local screenVector = Vector2.new(screenPoint.X, screenPoint.Y)
                            local distToMouse = (screenVector - mousePos).Magnitude
                            if distToMouse < shortestDist then
                                shortestDist = distToMouse
                                targetPredictedPos = predictedPos
                            end
                        end
                    end
                end
            end
        end

        if targetPredictedPos and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            pcall(function()
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPredictedPos)
            end)
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    if not Config.HardStickEnabled then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local amICop = isPoliceTeam(LocalPlayer)
    local closestPlayer = nil
    local shortestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if isTargetValid(player, amICop) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - myRoot.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end

    if closestPlayer and closestPlayer.Character then
        local char = closestPlayer.Character
        local targetHRP = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.SeatPart then
            myRoot.CFrame = humanoid.SeatPart.CFrame
            myRoot.AssemblyLinearVelocity = humanoid.SeatPart.AssemblyLinearVelocity
        elseif targetHRP then
            myRoot.CFrame = targetHRP.CFrame
            myRoot.AssemblyLinearVelocity = targetHRP.AssemblyLinearVelocity
        end
    end
end))

----------------------------------------------------------------
-- Visual tab
----------------------------------------------------------------
local Preview = visualTab:AddPreviewPanel("ESP Preview", {side = "left"})

local VisualsCard = visualTab:AddCard("Visuals", {icon = "👁", side = "right"})

local activeHighlights = {}

local EspCheck = VisualsCard:AddCheckbox("Faction ESP", false, function(state)
    Config.EspEnabled = state
    Preview:SetBox(state)
    Preview:SetSkeleton(state)
    Preview:SetName(state)
    Preview:SetHealthbar(state)
    if not state then
        for _, h in pairs(activeHighlights) do if h then h:Destroy() end end
        activeHighlights = {}
    end
end)

local WantedCheck = VisualsCard:AddCheckbox("Wanted Stars ESP", false, function(state)
    Config.PoliceWantedEsp = state
    if not state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Head") then
                local tag = player.Character.Head:FindFirstChild("ZabotaWantedTag")
                if tag then tag:Destroy() end
            end
        end
    end
end)

Preview:SetHealth(100)

track(RunService.RenderStepped:Connect(function()
    if not Config.EspEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local highlight = char:FindFirstChild("ZABOTA_ESP_HIGHLIGHT")
            local isCivilian = player.Team and (player.Team.Name == "Civilian" or player.Team.Name == "Civilians")
            local isPolice = isPoliceTeam(player)

            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ZABOTA_ESP_HIGHLIGHT"
                highlight.Adornee = char
                highlight.Parent = char
                table.insert(activeHighlights, highlight)
            end

            if isCivilian then
                highlight.FillColor = Color3.fromRGB(50, 255, 50)
            elseif isPolice then
                highlight.FillColor = Color3.fromRGB(0, 200, 255)
            else
                highlight.FillColor = Color3.fromRGB(255, 50, 50)
            end
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    if not Config.PoliceWantedEsp then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local billboard = head:FindFirstChild("ZabotaWantedTag")
            local wantedLevel = player:GetAttribute("WantedLevel") or 0

            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "ZabotaWantedTag"
                billboard.Size = UDim2.new(0, 150, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.AlwaysOnTop = true

                local textLabel = Instance.new("TextLabel")
                textLabel.Name = "Label"
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                textLabel.TextStrokeTransparency = 0
                textLabel.TextSize = 14
                textLabel.Font = Enum.Font.GothamBold
                textLabel.Parent = billboard
                billboard.Parent = head
            end

            local label = billboard:FindFirstChild("Label")
            if label then
                label.Text = wantedLevel > 0 and ("⭐ Wanted: " .. tostring(wantedLevel)) or "Clean"
                label.TextColor3 = wantedLevel > 0 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
            end
        end
    end
end))

----------------------------------------------------------------
-- Exploits tab
----------------------------------------------------------------
local FixCard = exploitTab:AddCard("Fixes", {icon = "🛠", side = "left"})
FixCard:AddCheckbox("Fix: Vehicle Bullet Clip", false, function(state)
    Config.VehicleShootFix = state
end)

local MagnetCheck = FixCard:AddCheckbox("Magnet [H] (Police Velocity Lock)", false, function(state)
    Config.MagnetEnabled = state
end)

local HitboxCard = exploitTab:AddCard("Hitboxes", {icon = "🎯", side = "right"})
local HitboxCheck = HitboxCard:AddCheckbox("Hitbox Expander [F6]", false, function(state)
    Config.HitboxEnabled = state
    if not state then
        for _, player in ipairs(Players:GetPlayers()) do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:GetAttribute("ZabotaOriginalSize") then
                hrp.Size = hrp:GetAttribute("ZabotaOriginalSize")
                hrp.Transparency = 0
                hrp:SetAttribute("ZabotaOriginalSize", nil)
            end
        end
    end
end)

HitboxCard:AddSlider("Hitbox Size", 2, 25, Config.HitboxSize, 1, function(v)
    Config.HitboxSize = v
end)

track(RunService.RenderStepped:Connect(function()
    if Config.VehicleShootFix and LocalPlayer.Character then
        pcall(function()
            ReplicatedStorage.ClientVehicleCollisionProxiesEnabled = false
        end)
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))

track(RunService.Heartbeat:Connect(function()
    if not Config.MagnetEnabled then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local targetPart = nil
    local shortestDist = math.huge
    local amICop = isPoliceTeam(LocalPlayer)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if isTargetValid(player, amICop) then
                local char = player.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")

                local activeTarget = hrp
                if humanoid and humanoid.SeatPart then
                    local vehicleModel = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
                    activeTarget = vehicleModel and (vehicleModel.PrimaryPart or vehicleModel:FindFirstChildWhichIsA("BasePart")) or humanoid.SeatPart
                elseif hrp then
                    activeTarget = hrp
                end

                if activeTarget then
                    local dist = (activeTarget.Position - myRoot.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        targetPart = activeTarget
                    end
                end
            end
        end
    end

    if targetPart and shortestDist < 180 then
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        local offset = Vector3.new(0, 2.5, 0)
        myRoot.CFrame = targetPart.CFrame + offset
        if targetPart:IsA("BasePart") then
            myRoot.AssemblyLinearVelocity = targetPart.AssemblyLinearVelocity
        end
    end
end))

track(RunService.RenderStepped:Connect(function()
    if not Config.HitboxEnabled then return end
    local amICop = isPoliceTeam(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isTargetValid(player, amICop) then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not hrp:GetAttribute("ZabotaOriginalSize") then
                    hrp:SetAttribute("ZabotaOriginalSize", hrp.Size)
                end
                hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                hrp.Transparency = 0.65
                hrp.Color = Color3.fromRGB(255, 50, 50)
                hrp.CanQuery = true
            end
        end
    end
end))

----------------------------------------------------------------
-- Config tab
----------------------------------------------------------------
local controlCard = configTab:AddCard("Menu Control", {icon = "⚙", side = "left"})
controlCard:AddButton("Uninject / Unload", function()
    for _, conn in ipairs(LoaderConnections) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    LoaderConnections = {}
    Window.Notify("ZABOTA", "Выгрузка интерфейса...", 1)
    task.wait(0.4)
    Window:Uninject()
end)

----------------------------------------------------------------
-- Хоткеи (совпадают с прошлой версией скрипта), синхронизированные
-- с состоянием чекбоксов в UI
----------------------------------------------------------------
track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F1 then
        Config.SpeedEnabled = not Config.SpeedEnabled
        SpeedCheck:SetState(Config.SpeedEnabled)
    elseif input.KeyCode == Enum.KeyCode.F2 then
        tpToPriorityTarget()
    elseif input.KeyCode == Enum.KeyCode.F4 then
        Config.TriggerbotEnabled = not Config.TriggerbotEnabled
        TriggerCheck:SetState(Config.TriggerbotEnabled)
    elseif input.KeyCode == Enum.KeyCode.X then
        Config.HardStickEnabled = not Config.HardStickEnabled
        StickCheck:SetState(Config.HardStickEnabled)
    elseif input.KeyCode == Enum.KeyCode.H then
        Config.MagnetEnabled = not Config.MagnetEnabled
        MagnetCheck:SetState(Config.MagnetEnabled)
    elseif input.KeyCode == Enum.KeyCode.F5 then
        Config.FlyEnabled = not Config.FlyEnabled
        setFly(Config.FlyEnabled)
        FlyCheck:SetState(Config.FlyEnabled)
    elseif input.KeyCode == Enum.KeyCode.F6 then
        Config.HitboxEnabled = not Config.HitboxEnabled
        HitboxCheck:SetState(Config.HitboxEnabled)
    elseif input.KeyCode == Enum.KeyCode.F7 then
        Config.SilentAimEnabled = not Config.SilentAimEnabled
        FOVCircle.Visible = Config.SilentAimEnabled
        SilentAimCheck:SetState(Config.SilentAimEnabled)
    elseif input.KeyCode == Enum.KeyCode.J then
        tpToNearestMoney()
    elseif input.KeyCode == Enum.KeyCode.G then
        cursorTeleport()
    end
end))

Window.Notify("ZABOTA", "Библиотека успешно загружена!", 3)
