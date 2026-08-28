-- ZABOTA Bootstrap
-- Устойчивая загрузка zabota_loader.lua: несколько зеркал + повторные
-- попытки + явные проверки на nil/пустой ответ перед loadstring, чтобы
-- никогда не долетать до "invalid argument #1 to 'loadstring' (string
-- expected, got nil)" из-за молчаливого сбоя одного HttpGet-запроса.

local timestamp = tostring(os.time())
local urls = {
    "https://raw.githubusercontent.com/dagpker-glitch/ZABOTA/main/zabota_loader.lua?t=" .. timestamp,
    "https://cdn.jsdelivr.net/gh/dagpker-glitch/ZABOTA@main/zabota_loader.lua",
    "https://fastly.jsdelivr.net/gh/dagpker-glitch/ZABOTA@main/zabota_loader.lua",
    "https://raw.githack.com/dagpker-glitch/ZABOTA/main/zabota_loader.lua"
}

local MAX_ATTEMPTS_PER_URL = 2
local RETRY_DELAY = 0.6

local function fetch(url)
    local ok, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(response) == "string" and response ~= "" and not response:find("404: Not Found") and not response:find("Cannot find") then
        return response
    end
    return nil, ok and "empty/invalid response" or tostring(response)
end

local content, lastError

for _, url in ipairs(urls) do
    for attempt = 1, MAX_ATTEMPTS_PER_URL do
        local result, err = fetch(url)
        if result then
            content = result
            break
        end
        lastError = err or "unknown error"
        if attempt < MAX_ATTEMPTS_PER_URL then
            task.wait(RETRY_DELAY)
        end
    end
    if content then break end
end

if not content or content == "" then
    warn("[ZABOTA Bootstrap Error] Не удалось загрузить zabota_loader.lua ни с одного зеркала.")
    warn("Последняя ошибка: " .. tostring(lastError))
    warn("Проверь:")
    warn("1. Разрешён ли HttpGet к raw.githubusercontent.com / jsdelivr.net в твоём экзекьюторе.")
    warn("2. Репозиторий dagpker-glitch/ZABOTA публичный (Settings -> Change repository visibility).")
    warn("3. Интернет-соединение / попробуй запустить скрипт ещё раз через несколько секунд.")
    return
end

local chunk, compileErr = loadstring(content)
if not chunk then
    warn("[ZABOTA Bootstrap Error] Скрипт загрузился, но не скомпилировался: " .. tostring(compileErr))
    return
end

local ok, runErr = pcall(chunk)
if not ok then
    warn("[ZABOTA Bootstrap Error] Ошибка при выполнении zabota_loader.lua: " .. tostring(runErr))
end
