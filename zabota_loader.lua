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

local Window = ZabotaLib:CreateWindow({
    Title = "META",
    ToggleKey = Enum.KeyCode.RightShift,
    Version = "v1.1"
})

-- Создание оверлея HUD
local HUD = Window:CreateHUD("KEYBINDS")
HUD:AddBind("RShift", "ZABOTA Menu", "TOGGLE")

-- Вкладки
local aimbotTab   = Window:AddTab("AimBot")
local visualTab   = Window:AddTab("Visual")
local movementTab = Window:AddTab("Movement")
local radarTab    = Window:AddTab("Radar")
local miscTab     = Window:AddTab("Misc")
local configTab   = Window:AddTab("Config")

----------------------------------------------------------------
-- AimBot tab — layout modeled after the reference screenshot:
-- left column = "Aimbot" card (Enable, FOV, Smooth, checkboxes,
-- Kill Delay MS, Weapons list); right column = Triggerbot /
-- Semi Rage / RCS Standalone / Humanize cards
----------------------------------------------------------------
local AimCard = aimbotTab:AddCard("Aimbot", {icon = "🎯", side = "left"})

AimCard:AddCheckbox("Enable", true, function(state) end, {tag = true})

AimCard:AddSlider("FOV", 0, 10, 3.0, 0.1, function(v) end)
AimCard:AddSlider("Smooth (ticks)", 0, 15, 6.7, 0.1, function(v) end)

AimCard:AddCheckbox("Multipoints", true)
AimCard:AddCheckbox("Draw FOV", true)
AimCard:AddCheckbox("Kill Delay", true)

AimCard:AddSlider("Kill Delay MS", 0, 1000, 500, 1, function(v) end)

AimCard:AddWeaponList("Weapons", {
    "M4A4",
    "SG 553",
    "AWP",
    "G3SG1",
    "AUG",
    "SSG 08"
}, true, function(state) end)

----------------------------------------------------------------
local TriggerCard = aimbotTab:AddCard("Triggerbot", {icon = "🎯", side = "right"})
TriggerCard:AddCheckbox("Enable", false)

local SemiRageCard = aimbotTab:AddCard("Semi Rage", {icon = "💎", side = "right"})
SemiRageCard:AddSlider("Before shot", 0, 200, 0, 1, function(v) end, {disabled = true})
SemiRageCard:AddSlider("Between Shots", 0, 300, 165, 1, function(v) end)
SemiRageCard:AddSlider("Hit Chance", 0, 100, 60, 1, function(v) end)

local RCSCard = aimbotTab:AddCard("RCS Standalone", {icon = "🎯", side = "right"})
RCSCard:AddCheckbox("Enable", false)

local HumanizeCard = aimbotTab:AddCard("Humanize", {icon = "🧠", side = "right"})
HumanizeCard:AddCheckbox("Enable", false)

----------------------------------------------------------------
-- Visual tab: ESP Preview (left) + Visuals checkbox list (right)
----------------------------------------------------------------
local Preview = visualTab:AddPreviewPanel("ESP Preview", {icon = nil, side = "left"})

local VisualsCard = visualTab:AddCard("Visuals", {side = "right"})

VisualsCard:AddCheckbox("Box", true, function(state)
    Preview:SetBox(state)
end, {colors = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(150, 150, 150)}})

VisualsCard:AddCheckbox("Name", true, function(state)
    Preview:SetName(state)
end)

VisualsCard:AddCheckbox("Healthbar", true, function(state)
    Preview:SetHealthbar(state)
end, {tag = true, colors = {Color3.fromRGB(150, 150, 150)}})

VisualsCard:AddCheckbox("Armor bar", false, nil, {disabled = true})
VisualsCard:AddCheckbox("Weapon", false, nil, {disabled = true})
VisualsCard:AddCheckbox("Weapon Icon", false, nil, {disabled = true})
VisualsCard:AddCheckbox("Distance", false, nil, {disabled = true})

VisualsCard:AddCheckbox("Skeleton", true, function(state)
    Preview:SetSkeleton(state)
end, {colors = {Color3.fromRGB(190, 210, 90), Color3.fromRGB(90, 180, 210)}})

VisualsCard:AddCheckbox("World items", true, nil, {tag = true})
VisualsCard:AddCheckbox("Projectiles", false, nil, {disabled = true, tag = true})
VisualsCard:AddCheckbox("Grenade predict", false, nil, {disabled = true, tag = true})

Preview:SetBox(true)
Preview:SetName(true)
Preview:SetHealthbar(true)
Preview:SetSkeleton(true)
Preview:SetHealth(100)

----------------------------------------------------------------
-- Config tab: Uninject button
----------------------------------------------------------------
local controlCard = configTab:AddCard("Menu Control", {icon = "⚙", side = "left"})
controlCard:AddButton("Uninject / Unload", function()
    Window.Notify("ZABOTA", "Выгрузка интерфейса...", 1)
    task.wait(0.4)
    Window:Uninject()
end)

Window.Notify("ZABOTA", "Библиотека успешно загружена!", 3)
