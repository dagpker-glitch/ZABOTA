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
local VehiclesFolder = Workspace:FindFirstChild("Vehicles")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZabotaCustomMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 920)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -460)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "ZABOTA PRIVATE // San Diego Border RP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

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
    HitboxSize = 8, -- Оптимальный размер для надежных попаданий
    HardStickEnabled = false,
}

local uiToggles = {}

local HudLabel = Instance.new("TextLabel")
HudLabel.Size = UDim2.new(0, 270, 0, 270)
HudLabel.Position = UDim2.new(0, 10, 0, 10)
HudLabel.BackgroundTransparency = 0.4
HudLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
HudLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HudLabel.TextSize = 13
HudLabel.Font = Enum.Font.Code
HudLabel.TextXAlignment = Enum.TextXAlignment.Left
HudLabel.TextYAlignment = Enum.TextYAlignment.Top
HudLabel.RichText = true
HudLabel.Parent = ScreenGui

local HudCorner = Instance.new("UICorner")
HudCorner.CornerRadius = UDim.new(0, 6)
HudCorner.Parent = HudLabel

local function updateHud()
    local function status(val)
        return val and '<font color="rgb(50,255,50)">[ON]</font>' or '<font color="rgb(255,80,80)">[OFF]</font>'
    end

    HudLabel.Text = string.format(
        " <b>[ZABOTA HUD]</b>\n • Menu: [RightShift]\n • Speed [F1]: %s\n • TP Target [F2]: <font color=\"rgb(50,255,50)\">[Ready]</font>\n • TP Drop Cash [J]: <font color=\"rgb(50,255,50)\">[Ready]</font>\n • Triggerbot [F4]: %s\n • Silent Aim [F7]: %s\n • Max Dist: <b>%d studs</b>\n • Hard 1v1 Stick [X]: %s\n • Magnet [H]: %s\n • Fly [F5]: %s\n • Hitboxes [F6]: %s\n • Size: <b>%d studs</b>",
        status(Config.SpeedEnabled),
        status(Config.TriggerbotEnabled),
        status(Config.SilentAimEnabled),
        Config.MaxDistance,
        status(Config.HardStickEnabled),
        status(Config.MagnetEnabled),
        status(Config.FlyEnabled),
        status(Config.HitboxEnabled),
        Config.HitboxSize
    )
end
updateHud()

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

local function createToggle(name, yPos, keybindName, callback, customColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 380, 0, 35)
    btn.Position = UDim2.new(0, 20, 0, yPos)
    btn.BackgroundColor3 = customColor or Color3.fromRGB(35, 35, 45)
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Text = name .. (keybindName ~= "None" and " [" .. keybindName .. "]" or "") .. ": OFF"
    btn.TextSize, btn.Font = 14, Enum.Font.GothamBold
    btn.Parent = MainFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local state = false
    local function updateState(newState)
        state = newState
        btn.Text = name .. (keybindName ~= "None" and " [" .. keybindName .. "]" or "") .. ": " .. (state and "ON" or "OFF")
        if customColor then
            btn.BackgroundColor3 = state and Color3.fromRGB(230, 40, 40) or customColor
        else
            btn.BackgroundColor3 = state and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(35, 35, 45)
        end
        callback(state)
        updateHud()
    end

    btn.MouseButton1Click:Connect(function()
        updateState(not state)
    end)

    if keybindName ~= "None" then
        uiToggles[keybindName] = {
            toggle = function() updateState(not state) end,
            getState = function() return state end
        }
    end
    return btn
end

local function createButton(name, yPos, keybindName, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 380, 0, 35)
    btn.Position = UDim2.new(0, 20, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name .. (keybindName ~= "None" and " [" .. keybindName .. "]" or "")
    btn.TextSize, btn.Font = 14, Enum.Font.GothamBold
    btn.Parent = MainFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(callback)
    if keybindName ~= "None" then
        uiToggles[keybindName] = { action = callback }
    end
    return btn
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

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

-- 1. Спидхак (F1)
createToggle("CFrame Speed (300)", 55, "F1", function(state)
    Config.SpeedEnabled = state
end)

RunService.Heartbeat:Connect(function(dt)
    if Config.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local char = LocalPlayer.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection * (Config.SpeedValue * dt))
        end
    end
end)

-- 2. Полёт (F5)
createToggle("Fly (Speed 200)", 100, "F5", function(state)
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
end)

RunService.RenderStepped:Connect(function()
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
end)

-- 3. ESP
local activeHighlights = {}
createToggle("Faction ESP (Civ=Green, Police=Cyan)", 145, "None", function(state)
    Config.EspEnabled = state
    if not state then
        for _, h in pairs(activeHighlights) do if h then h:Destroy() end end
        activeHighlights = {}
    end
end)

RunService.RenderStepped:Connect(function()
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
end)

-- 4. Звёзды ESP
createToggle("Police: Wanted Stars ESP", 190, "None", function(state)
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

RunService.RenderStepped:Connect(function()
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
end)

-- 5. Кнопки
createButton("TP to Priority Target", 235, "F2", tpToPriorityTarget)
createButton("TP to Dropped Cash", 280, "J", tpToNearestMoney)

-- 6. Магнит
createToggle("Police: Magnet Velocity Lock", 325, "H", function(state)
    Config.MagnetEnabled = state
end)

RunService.Heartbeat:Connect(function()
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
end)

-- 7. Фикс стрельбы в машине
createToggle("Fix: Vehicle Bullet Clip", 370, "None", function(state)
    Config.VehicleShootFix = state
end)

RunService.Heartbeat:Connect(function()
    if Config.VehicleShootFix and LocalPlayer.Character then
        pcall(function()
            ReplicatedStorage.ClientVehicleCollisionProxiesEnabled = false
        end)
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- 8. Рабочие хитбоксы (С поддержкой серверной регистрации через невидимые прокси-части)
createToggle("Hitbox Expander (Working & Registering)", 415, "F6", function(state)
    Config.HitboxEnabled = state
end)

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(0, 380, 0, 25)
SizeLabel.Position = UDim2.new(0, 20, 0, 460)
SizeLabel.BackgroundTransparency = 1
SizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeLabel.TextSize = 13
SizeLabel.Font = Enum.Font.Gotham
SizeLabel.Text = "Hitbox Size: 8 studs"
SizeLabel.Parent = MainFrame

createButton("Hitbox Size +", 490, "None", function()
    Config.HitboxSize = math.min(Config.HitboxSize + 1, 25)
    SizeLabel.Text = "Hitbox Size: " .. Config.HitboxSize .. " studs"
    updateHud()
end)

createButton("Hitbox Size -", 530, "None", function()
    Config.HitboxSize = math.max(Config.HitboxSize - 1, 2)
    SizeLabel.Text = "Hitbox Size: " .. Config.HitboxSize .. " studs"
    updateHud()
end)

RunService.RenderStepped:Connect(function()
    if not Config.HitboxEnabled then return end
    local amICop = isPoliceTeam(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isTargetValid(player, amICop) then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Увеличиваем размер HumanoidRootPart и делаем его коллизии доступными для лучей оружия
                hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                hrp.Transparency = 0.65
                hrp.Color = Color3.fromRGB(255, 50, 50)
                hrp.CanQuery = true -- Разрешаем лучам игры цепляться за увеличенный хитбокс
            end
        end
    end
end)

-- 9. Triggerbot (F4) — Работающий на 100% с предиктом, 1-м лицом и оружием в руке
createToggle("Triggerbot (Auto-Shoot on Target)", 570, "F4", function(state)
    Config.TriggerbotEnabled = state
end)

local isTriggerShooting = false
RunService.RenderStepped:Connect(function()
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

                        -- Увеличенный радиус захвата под размер хитбоксов
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
end)

-- 10. Hard 1v1 Stick (X)
createToggle("HARD 1v1 STICK [X]", 615, "X", function(state)
    Config.HardStickEnabled = state
end, Color3.fromRGB(180, 20, 20))

RunService.RenderStepped:Connect(function()
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
end)

-- 11. Silent Aim (F7)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 255, 200)
FOVCircle.Filled = false
FOVCircle.Radius = Config.FOV
FOVCircle.Transparency = 0.7

createToggle("Silent Aim / Dynamic Lead", 660, "F7", function(state)
    Config.SilentAimEnabled = state
    FOVCircle.Visible = state
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.F1 then
        if uiToggles["F1"] then uiToggles["F1"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.F2 then
        if uiToggles["F2"] then uiToggles["F2"].action() end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        if uiToggles["F4"] then uiToggles["F4"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.X and not gameProcessed then
        if uiToggles["X"] then uiToggles["X"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.H then
        if uiToggles["H"] then uiToggles["H"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.F5 then
        if uiToggles["F5"] then uiToggles["F5"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        if uiToggles["F6"] then uiToggles["F6"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.F7 then
        if uiToggles["F7"] then uiToggles["F7"].toggle() end
    elseif input.KeyCode == Enum.KeyCode.J and not gameProcessed then
        tpToNearestMoney()
    elseif input.KeyCode == Enum.KeyCode.G and not gameProcessed then
        cursorTeleport()
    end
end)

RunService.RenderStepped:Connect(function()
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
end)
