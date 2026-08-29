-- ENI Universal Loader
-- Paste this in your executor, not the full script

local url = "https://raw.githubusercontent.com/dagpker-glitch/ZABOTA/main/ENI_UI.lua"

local function fetch(u)
    -- method 1: syn/fluxus request
    if syn and syn.request then
        local r = syn.request({ Url = u, Method = "GET" })
        if r and r.Body and #r.Body > 10 then return r.Body end
    end
    -- method 2: http.request (Delta/Krnl)
    if http and http.request then
        local r = http.request({ Url = u, Method = "GET" })
        if r and r.Body and #r.Body > 10 then return r.Body end
    end
    -- method 3: request() global
    if request then
        local ok, r = pcall(request, { Url = u, Method = "GET" })
        if ok and r and r.Body and #r.Body > 10 then return r.Body end
    end
    -- method 4: HttpService
    local ok, r = pcall(function()
        return game:GetService("HttpService"):GetAsync(u)
    end)
    if ok and r and #r > 10 then return r end
    -- method 5: game:HttpGet
    local ok2, r2 = pcall(function() return game:HttpGet(u) end)
    if ok2 and r2 and #r2 > 10 then return r2 end
    return nil
end

local src = fetch(url)
if src then
    local fn, err = loadstring(src)
    if fn then
        fn()
    else
        warn("[ENI] Parse error: " .. tostring(err))
    end
else
    warn("[ENI] Failed to fetch — try pasting ENI_UI.lua directly into executor")
end
