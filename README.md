# ZABOTA

Roblox Lua UI-библиотека и загрузчик меню (`ZabotaLib.lua`, `zabota_loader.lua`, `zabota_bootstrap.lua`).

## Как запустить меню

**Важно:** нельзя просто вставлять `loadstring(game:HttpGet(url))()` одной строкой.
Если этот самый первый `HttpGet`-запрос по какой-то причине (временный сбой сети,
рейт-лимит GitHub, экзекьютор режет конкретный домен и т.п.) вернёт `nil` —
`loadstring(nil)` крашится ещё **до** того, как успеет выполниться любая защита,
написанная внутри загружаемого файла. Защита внутри файла не помогает, если сам
файл не смог загрузиться.

Поэтому единственный надёжный способ — оборачивать именно этот самый первый
`HttpGet`-вызов в `pcall`, проверять тип результата и повторять попытку
**на стороне того скрипта, который ты вставляешь в executor**, а не только
внутри удалённого файла.

Вставляй в executor вот этот безопасный стартовый сниппет (не однострочник).
Он перебирает **несколько разных доменов-зеркал**, а не только один —
если у тебя заблокирован/недоступен именно `raw.githubusercontent.com`
(бывает из-за сети/провайдера/настроек экзекьютора), скрипт автоматически
попробует `jsdelivr`, `fastly.jsdelivr` и `githack`:

```lua
local ZABOTA_MIRRORS = {
    "https://raw.githubusercontent.com/dagpker-glitch/ZABOTA/main/zabota_bootstrap.lua?t=" .. tostring(os.time()),
    "https://cdn.jsdelivr.net/gh/dagpker-glitch/ZABOTA@main/zabota_bootstrap.lua",
    "https://fastly.jsdelivr.net/gh/dagpker-glitch/ZABOTA@main/zabota_bootstrap.lua",
    "https://raw.githack.com/dagpker-glitch/ZABOTA/main/zabota_bootstrap.lua",
}

local function ZABOTA_safeFetch(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(res) == "string" and res ~= "" then
        return res
    end
    return nil, ok and "empty response" or tostring(res)
end

local ZABOTA_content
local ZABOTA_lastErr = "unknown"

for _, url in ipairs(ZABOTA_MIRRORS) do
    for attempt = 1, 2 do
        local result, err = ZABOTA_safeFetch(url)
        if result then
            ZABOTA_content = result
            break
        end
        ZABOTA_lastErr = err or ZABOTA_lastErr
        task.wait(1)
    end
    if ZABOTA_content then break end
end

if not ZABOTA_content then
    warn("[ZABOTA] Не удалось загрузить скрипт ни с одного из " .. #ZABOTA_MIRRORS .. " зеркал. Последняя ошибка: " .. tostring(ZABOTA_lastErr))
    warn("[ZABOTA] Проверь: 1) включён ли HttpService/HttpGet в твоём экзекьюторе; 2) не блокирует ли антивирус/провайдер github.com и jsdelivr.net; 3) попробуй запустить скрипт снова через 10-15 секунд.")
    return
end

local ZABOTA_chunk, ZABOTA_compileErr = loadstring(ZABOTA_content)
if not ZABOTA_chunk then
    warn("[ZABOTA] Файл загрузился, но не скомпилировался: " .. tostring(ZABOTA_compileErr))
    return
end

local ZABOTA_ok, ZABOTA_runErr = pcall(ZABOTA_chunk)
if not ZABOTA_ok then
    warn("[ZABOTA] Ошибка при выполнении: " .. tostring(ZABOTA_runErr))
end
```

Этот сниппет:
1. Оборачивает **самый первый** `HttpGet` в `pcall`, а не только те, что вложены глубже.
2. Проверяет `type(res) == "string"`, а не просто truthy (пустая строка тоже truthy в Lua).
3. Перебирает **4 разных домена-зеркала** (по 2 попытки на каждый) вместо retry на
   одном и том же домене — если блокировка/сбой специфичны для одного домена,
   остальные три всё равно сработают.
4. Делает `loadstring` и его выполнение отдельными защищёнными шагами, чтобы при
   ошибке ты видел понятное сообщение в консоли, а не голый краш движка.

### Если ошибка всё равно повторяется на всех 4 зеркалах

Это значит, что `game:HttpGet` в принципе не может выйти в интернет в твоём
случае (не сбой конкретного зеркала). Обычные причины:
- В экзекьюторе выключена настройка типа "Enable HttpGet" / "Allow HTTP requests".
- Антивирус, файрвол или DNS-фильтр провайдера блокирует `github.com`/`githubusercontent.com`
  и `jsdelivr.net` целиком (например, некоторые корпоративные/учебные сети или
  антивирусы блокируют "подозрительные" домены, связанные с исполнением кода).
- Слишком много запросов подряд — GitHub временно режет rate-limit по IP
  (тогда достаточно подождать 1-2 минуты и запустить скрипт заново).

## Структура файлов

- `ZabotaLib.lua` — сама UI-библиотека (окна, вкладки, карточки, чекбоксы, слайдеры,
  ESP-превью, список оружия и т.д.).
- `zabota_loader.lua` — сборка конкретного меню (вкладки AimBot / Visual / Config)
  на основе `ZabotaLib.lua`. Тянет `ZabotaLib.lua` с несколькими зеркалами и retry.
- `zabota_bootstrap.lua` — точка входа, которую тянет стартовый сниппет выше.
  Тянет `zabota_loader.lua` с несколькими зеркалами и retry.
