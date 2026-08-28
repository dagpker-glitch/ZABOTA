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

Вставляй в executor вот этот безопасный стартовый сниппет (не однострочник):

```lua
local function ZABOTA_safeFetch(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(res) == "string" and res ~= "" then
        return res
    end
    return nil
end

local ZABOTA_url = "https://raw.githubusercontent.com/dagpker-glitch/ZABOTA/main/zabota_bootstrap.lua?t=" .. tostring(os.time())

local ZABOTA_content
for i = 1, 3 do
    ZABOTA_content = ZABOTA_safeFetch(ZABOTA_url)
    if ZABOTA_content then break end
    task.wait(1)
end

if not ZABOTA_content then
    warn("[ZABOTA] Не удалось загрузить zabota_bootstrap.lua после 3 попыток. Проверь интернет / доступ HttpGet к raw.githubusercontent.com в своём экзекьюторе, затем попробуй запустить скрипт ещё раз.")
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
3. Делает до 3 попыток с паузой 1 секунда между ними, прежде чем сдаться.
4. Делает `loadstring` и его выполнение отдельными защищёнными шагами, чтобы при
   ошибке ты видел понятное сообщение в консоли, а не голый краш движка.

## Структура файлов

- `ZabotaLib.lua` — сама UI-библиотека (окна, вкладки, карточки, чекбоксы, слайдеры,
  ESP-превью, список оружия и т.д.).
- `zabota_loader.lua` — сборка конкретного меню (вкладки AimBot / Visual / Config)
  на основе `ZabotaLib.lua`. Тянет `ZabotaLib.lua` с несколькими зеркалами и retry.
- `zabota_bootstrap.lua` — точка входа, которую тянет стартовый сниппет выше.
  Тянет `zabota_loader.lua` с несколькими зеркалами и retry.
