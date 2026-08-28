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

for _, url in ipairs(urls) do
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if success and response and response ~= "" and not string.find(response, "404: Not Found") and not string.find(response, "Cannot find") then
        content = response
        break
    else
        lastError = tostring(response)
    end
end

if not content then
    warn("[ZABOTA Error] Не удалось получить исходный код. Ответ сервера: " .. lastError)
    warn("Решения:")
    warn("1. Открой репозиторий dagpker-glitch/ZABOTA -> Settings -> в самом низу проверь 'Change repository visibility' (должно быть PUBLIC).")
    warn("2. Проверь регистр букв в названии файла (ZabotaLib.lua, а не zabotalib.lua или ZabotaLib.LUA).")
    return
end

-- Инициализация библиотеки
local ZabotaLib = loadstring(content)()

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
-- Visual tab: ESP Preview (left) + Visuals checkbox list (right)
-- Layout/behavior modeled after the reference screenshot
----------------------------------------------------------------
local Preview = visualTab:AddPreviewPanel("ESP Preview", {"↗"})

local VisualsCard = visualTab:AddCard("Visuals", {"→"})

local boxCb = VisualsCard:AddCheckbox("Box", true, function(state)
    Preview:SetBox(state)
end, {colors = {Color3.fromRGB(150, 150, 150), Color3.fromRGB(150, 150, 150)}})

local nameCb = VisualsCard:AddCheckbox("Name", true, function(state)
    Preview:SetName(state)
end)

local healthCb = VisualsCard:AddCheckbox("Healthbar", true, function(state)
    Preview:SetHealthbar(state)
end, {tag = true, colors = {Color3.fromRGB(150, 150, 150)}})

VisualsCard:AddCheckbox("Armor bar", false, nil, {disabled = true})
VisualsCard:AddCheckbox("Weapon", false, nil, {disabled = true})
VisualsCard:AddCheckbox("Weapon Icon", false, nil, {disabled = true})
VisualsCard:AddCheckbox("Distance", false, nil, {disabled = true})

local skeletonCb = VisualsCard:AddCheckbox("Skeleton", true, function(state)
    Preview:SetSkeleton(state)
end, {colors = {Color3.fromRGB(190, 210, 90), Color3.fromRGB(90, 180, 210)}})

VisualsCard:AddCheckbox("World items", true, nil, {tag = true})
VisualsCard:AddCheckbox("Projectiles", false, nil, {disabled = true, tag = true})
VisualsCard:AddCheckbox("Grenade predict", false, nil, {disabled = true, tag = true})

-- Apply defaults to the preview immediately
Preview:SetBox(true)
Preview:SetName(true)
Preview:SetHealthbar(true)
Preview:SetSkeleton(true)
Preview:SetHealth(100)

----------------------------------------------------------------
-- Settings / Config tab: Uninject button
----------------------------------------------------------------
local controlCard = configTab:AddCard("Menu Control")
controlCard:AddButton("Uninject / Unload", function()
    Window.Notify("ZABOTA", "Выгрузка интерфейса...", 1)
    task.wait(0.4)
    Window:Uninject()
end)

Window.Notify("ZABOTA", "Библиотека успешно загружена!", 3)
