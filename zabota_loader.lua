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
    Title = "ZABOTA",
    ToggleKey = Enum.KeyCode.RightShift
})

-- Создание оверлея HUD
local HUD = Window:CreateHUD("KEYBINDS")
HUD:AddBind("RShift", "ZABOTA Menu", "TOGGLE")

-- Вкладки
local legitTab    = Window:AddTab("Legit")
local visualTab   = Window:AddTab("Visual")
local movementTab = Window:AddTab("Movement")
local settingsTab = Window:AddTab("Settings")

-- Кнопка выгрузки (Uninject)
local controlCard = settingsTab:AddCard("Menu Control")
controlCard:AddButton("Uninject / Unload", function()
    Window.Notify("ZABOTA", "Выгрузка интерфейса...", 1)
    task.wait(0.4)
    Window:Uninject()
end)

Window.Notify("ZABOTA", "Библиотека успешно загружена!", 3)
