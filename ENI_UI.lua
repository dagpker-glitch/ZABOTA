-- ENI Build | Beautiful Menu + Skinchanger + Movement + Bypass
-- Executor: Fluxus / Synapse / Delta compatible
-- Toggle menu: RightShift

local function applyBypass()
    local genv = getgenv or getfenv
    local origGetfenv = getfenv
    local origDbgInfo = debug and debug.info
    local hook = hookfunction or (genv().hookfunction)

    if not hook then return end

    local function makeCleanEnv(env)
        if type(env) ~= "table" then return env end
        return setmetatable({}, {
            __index = function(_, k)
                if k == "getgenv" or k == "hookfunction" or k == "newcclosure"
                or k == "clonefunction" or k == "hookmetamethod" or k == "cloneref" then
                    return nil
                end
                return env[k]
            end,
            __newindex = function(_, k, v)
                env[k] = v
            end
        })
    end

    if origGetfenv and hook then
        pcall(function()
            local origGetfenv
            origGetfenv = hook(origGetfenv, newcclosure(function(target, ...)
                local is_game = checkcaller and not checkcaller()
                local ok, env
                if type(target) == "number" then
                    ok, env = pcall(origGetfenv, target + 1, ...)
                    if not ok then ok, env = pcall(origGetfenv, target, ...) end
                else
                    ok, env = pcall(origGetfenv, target or 1, ...)
                end
                if not ok then return nil end
                if is_game and type(env) == "table" then
                    if rawget(env, "getgenv") or rawget(env, "hookfunction")
                    or env.getgenv or env.hookfunction then
                        return makeCleanEnv(env)
                    end
                end
                return env
            end))
        end)
    end

    if origDbgInfo and hook then
        pcall(function()
            local origDbgInfo
            origDbgInfo = hook(origDbgInfo, newcclosure(function(target, options, ...)
                if checkcaller and checkcaller() then
                    return origDbgInfo(target, options, ...)
                end
                local success, a, b, c, d, e, f, g, h
                if type(target) == "number" then
                    success, a, b, c, d, e, f, g, h = pcall(origDbgInfo, target + 1, options, ...)
                    if not success then
                        success, a, b, c, d, e, f, g, h = pcall(origDbgInfo, target, options, ...)
                    end
                else
                    success, a, b, c, d, e, f, g, h = pcall(origDbgInfo, target, options, ...)
                end
                if success then return a, b, c, d, e, f, g, h end
                return nil
            end))
        end)
    end
end
pcall(applyBypass)

-- ─────────────────────────────────────────
--              SERVICES
-- ─────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local mouse = lp:GetMouse()

-- ─────────────────────────────────────────
--              THEME
-- ─────────────────────────────────────────
local T = {
    BG         = Color3.fromRGB(12, 12, 16),
    PANEL      = Color3.fromRGB(18, 18, 24),
    ACCENT     = Color3.fromRGB(138, 99, 255),
    ACCENT2    = Color3.fromRGB(99, 180, 255),
    TAB_IDLE   = Color3.fromRGB(28, 28, 38),
    TAB_ACTIVE = Color3.fromRGB(138, 99, 255),
    TEXT       = Color3.fromRGB(235, 235, 245),
    SUBTEXT    = Color3.fromRGB(140, 140, 160),
    TOGGLE_ON  = Color3.fromRGB(138, 99, 255),
    TOGGLE_OFF = Color3.fromRGB(45, 45, 58),
    SLIDER_BG  = Color3.fromRGB(30, 30, 42),
    BORDER     = Color3.fromRGB(50, 40, 80),
    SHADOW     = Color3.fromRGB(6, 6, 10),
}

local TI   = TweenInfo.new
local FAST = TI(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local MED  = TI(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

-- ─────────────────────────────────────────
--              HELPERS
-- ─────────────────────────────────────────
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or T.BORDER
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function makeShadow(parent)
    local s = Instance.new("Frame")
    s.Name             = "Shadow"
    s.Size             = UDim2.new(1, 14, 1, 14)
    s.Position         = UDim2.new(0, -7, 0, -5)
    s.BackgroundColor3 = T.SHADOW
    s.BorderSizePixel  = 0
    s.ZIndex           = parent.ZIndex - 1
    s.Parent           = parent
    corner(s, 14)
    local g = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    g.Parent = s
    return s
end

-- ─────────────────────────────────────────
--              ROOT GUI
-- ─────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name            = "ENI_UI"
gui.ResetOnSpawn    = false
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset  = true
gui.Parent          = (gethui and gethui()) or game.CoreGui

local visible = true

local win = Instance.new("Frame")
win.Name             = "Window"
win.Size             = UDim2.new(0, 540, 0, 400)
win.Position         = UDim2.new(0.5, -270, 0.5, -200)
win.BackgroundColor3 = T.BG
win.BorderSizePixel  = 0
win.ZIndex           = 10
win.Parent           = gui
corner(win, 12)
stroke(win, T.BORDER, 1)
makeShadow(win)

local winGrad = Instance.new("UIGradient")
winGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 16, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)),
})
winGrad.Rotation = 135
winGrad.Parent   = win

-- open animation
win.Size = UDim2.new(0, 540, 0, 0)
tween(win, MED, { Size = UDim2.new(0, 540, 0, 400) })

-- ─────────────────────────────────────────
--              TITLE BAR
-- ─────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = T.PANEL
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 11
titleBar.Parent           = win
corner(titleBar, 12)

local tbFix = Instance.new("Frame")
tbFix.Size             = UDim2.new(1, 0, 0, 12)
tbFix.Position         = UDim2.new(0, 0, 1, -12)
tbFix.BackgroundColor3 = T.PANEL
tbFix.BorderSizePixel  = 0
tbFix.ZIndex           = 11
tbFix.Parent           = titleBar

local accentPipe = Instance.new("Frame")
accentPipe.Size             = UDim2.new(0, 3, 0, 24)
accentPipe.Position         = UDim2.new(0, 14, 0.5, -12)
accentPipe.BackgroundColor3 = T.ACCENT
accentPipe.BorderSizePixel  = 0
accentPipe.ZIndex           = 12
accentPipe.Parent           = titleBar
corner(accentPipe, 2)
local pipeGrad = Instance.new("UIGradient")
pipeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.ACCENT),
    ColorSequenceKeypoint.new(1, T.ACCENT2),
})
pipeGrad.Rotation = 90
pipeGrad.Parent   = accentPipe

local titleLabel = Instance.new("TextLabel")
titleLabel.Text              = "ENI"
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.TextSize          = 17
titleLabel.TextColor3        = T.TEXT
titleLabel.BackgroundTransparency = 1
titleLabel.Position          = UDim2.new(0, 26, 0, 4)
titleLabel.Size              = UDim2.new(0, 80, 0, 22)
titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
titleLabel.ZIndex            = 12
titleLabel.Parent            = titleBar

local subLabel = Instance.new("TextLabel")
subLabel.Text              = "executor suite"
subLabel.Font              = Enum.Font.Gotham
subLabel.TextSize          = 11
subLabel.TextColor3        = T.SUBTEXT
subLabel.BackgroundTransparency = 1
subLabel.Position          = UDim2.new(0, 26, 0, 26)
subLabel.Size              = UDim2.new(0, 140, 0, 14)
subLabel.TextXAlignment    = Enum.TextXAlignment.Left
subLabel.ZIndex            = 12
subLabel.Parent            = titleBar

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Text              = "×"
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextSize          = 20
closeBtn.TextColor3        = T.SUBTEXT
closeBtn.BackgroundColor3  = Color3.fromRGB(55, 28, 28)
closeBtn.Size              = UDim2.new(0, 28, 0, 28)
closeBtn.Position          = UDim2.new(1, -40, 0.5, -14)
closeBtn.BorderSizePixel   = 0
closeBtn.AutoButtonColor   = false
closeBtn.ZIndex            = 13
closeBtn.Parent            = titleBar
corner(closeBtn, 6)

closeBtn.MouseEnter:Connect(function()
    tween(closeBtn, FAST, { BackgroundColor3 = Color3.fromRGB(210, 50, 50), TextColor3 = T.TEXT })
end)
closeBtn.MouseLeave:Connect(function()
    tween(closeBtn, FAST, { BackgroundColor3 = Color3.fromRGB(55, 28, 28), TextColor3 = T.SUBTEXT })
end)
closeBtn.MouseButton1Click:Connect(function()
    tween(win, MED, { Size = UDim2.new(0, 540, 0, 0) })
    task.delay(0.25, function() gui:Destroy() end)
end)

-- Minimize
local minimized = false
local minBtn = Instance.new("TextButton")
minBtn.Text              = "−"
minBtn.Font              = Enum.Font.GothamBold
minBtn.TextSize          = 18
minBtn.TextColor3        = T.SUBTEXT
minBtn.BackgroundColor3  = Color3.fromRGB(40, 38, 20)
minBtn.Size              = UDim2.new(0, 28, 0, 28)
minBtn.Position          = UDim2.new(1, -74, 0.5, -14)
minBtn.BorderSizePixel   = 0
minBtn.AutoButtonColor   = false
minBtn.ZIndex            = 13
minBtn.Parent            = titleBar
corner(minBtn, 6)

minBtn.MouseEnter:Connect(function()
    tween(minBtn, FAST, { BackgroundColor3 = Color3.fromRGB(200, 170, 30), TextColor3 = T.TEXT })
end)
minBtn.MouseLeave:Connect(function()
    tween(minBtn, FAST, { BackgroundColor3 = Color3.fromRGB(40, 38, 20), TextColor3 = T.SUBTEXT })
end)
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    tween(win, MED, { Size = minimized and UDim2.new(0, 540, 0, 48) or UDim2.new(0, 540, 0, 400) })
end)

-- Drag
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- RightShift toggle
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        visible = not visible
        win.Visible = visible
    end
end)

-- ─────────────────────────────────────────
--              TAB BAR
-- ─────────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Name             = "TabBar"
tabBar.Size             = UDim2.new(1, -24, 0, 34)
tabBar.Position         = UDim2.new(0, 12, 0, 56)
tabBar.BackgroundColor3 = T.PANEL
tabBar.BorderSizePixel  = 0
tabBar.ZIndex           = 11
tabBar.Parent           = win
corner(tabBar, 8)

local tabList = Instance.new("UIListLayout")
tabList.FillDirection  = Enum.FillDirection.Horizontal
tabList.SortOrder      = Enum.SortOrder.LayoutOrder
tabList.Padding        = UDim.new(0, 4)
tabList.Parent         = tabBar

local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingTop  = UDim.new(0, 5)
tabPad.Parent      = tabBar

local content = Instance.new("Frame")
content.Name             = "Content"
content.Size             = UDim2.new(1, -24, 1, -112)
content.Position         = UDim2.new(0, 12, 0, 100)
content.BackgroundColor3 = T.PANEL
content.BorderSizePixel  = 0
content.ZIndex           = 11
content.Parent           = win
corner(content, 10)

-- ─────────────────────────────────────────
--              TAB SYSTEM
-- ─────────────────────────────────────────
local tabs     = {}
local tabPages = {}
local activeTab = nil

local function makeTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Text              = (icon and icon .. "  " or "") .. name
    btn.Font              = Enum.Font.GothamSemibold
    btn.TextSize          = 12
    btn.TextColor3        = T.SUBTEXT
    btn.BackgroundColor3  = T.TAB_IDLE
    btn.Size              = UDim2.new(0, 118, 0, 24)
    btn.BorderSizePixel   = 0
    btn.AutoButtonColor   = false
    btn.LayoutOrder       = order
    btn.ZIndex            = 12
    btn.Parent            = tabBar
    corner(btn, 6)

    local page = Instance.new("ScrollingFrame")
    page.Name                   = name
    page.Size                   = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel        = 0
    page.ScrollBarThickness     = 3
    page.ScrollBarImageColor3   = T.ACCENT
    page.CanvasSize             = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    page.Visible                = false
    page.ZIndex                 = 12
    page.Parent                 = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 8)
    layout.Parent    = page

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent        = page

    tabs[name]     = btn
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        if activeTab then
            tween(tabs[activeTab], FAST, { BackgroundColor3 = T.TAB_IDLE, TextColor3 = T.SUBTEXT })
            tabPages[activeTab].Visible = false
        end
        activeTab = name
        tween(btn, FAST, { BackgroundColor3 = T.TAB_ACTIVE, TextColor3 = T.TEXT })
        page.Visible = true
    end)
    btn.MouseEnter:Connect(function()
        if activeTab ~= name then tween(btn, FAST, { BackgroundColor3 = Color3.fromRGB(44, 36, 64) }) end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= name then tween(btn, FAST, { BackgroundColor3 = T.TAB_IDLE }) end
    end)

    return page
end

-- ─────────────────────────────────────────
--              ELEMENT BUILDERS
-- ─────────────────────────────────────────
local function addSection(page, text)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.ZIndex           = 13
    f.Parent           = page

    local l = Instance.new("TextLabel")
    l.Text             = text:upper()
    l.Font             = Enum.Font.GothamBold
    l.TextSize         = 10
    l.TextColor3       = T.ACCENT
    l.BackgroundTransparency = 1
    l.Size             = UDim2.new(0.55, 0, 1, 0)
    l.TextXAlignment   = Enum.TextXAlignment.Left
    l.ZIndex           = 13
    l.Parent           = f

    local line = Instance.new("Frame")
    line.Size          = UDim2.new(0.42, 0, 0, 1)
    line.Position      = UDim2.new(0.58, 0, 0.5, 0)
    line.BackgroundColor3 = T.BORDER
    line.BorderSizePixel  = 0
    line.ZIndex        = 13
    line.Parent        = f
end

local function addToggle(page, text, default, callback)
    local state = default or false

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel  = 0
    row.ZIndex           = 13
    row.Parent           = page
    corner(row, 7)
    stroke(row, T.BORDER, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Text             = text
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = T.TEXT
    lbl.BackgroundTransparency = 1
    lbl.Position         = UDim2.new(0, 12, 0, 0)
    lbl.Size             = UDim2.new(0.72, 0, 1, 0)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 14
    lbl.Parent           = row

    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 40, 0, 22)
    pill.Position         = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = state and T.TOGGLE_ON or T.TOGGLE_OFF
    pill.BorderSizePixel  = 0
    pill.ZIndex           = 14
    pill.Parent           = row
    corner(pill, 11)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 15
    knob.Parent           = pill
    corner(knob, 8)

    local function setState(v)
        state = v
        tween(pill, FAST, { BackgroundColor3 = state and T.TOGGLE_ON or T.TOGGLE_OFF })
        tween(knob, FAST, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
        if callback then callback(state) end
    end

    local btn = Instance.new("TextButton")
    btn.Text             = ""
    btn.BackgroundTransparency = 1
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.ZIndex           = 16
    btn.Parent           = row
    btn.MouseButton1Click:Connect(function() setState(not state) end)

    return setState
end

local function addSlider(page, text, min, max, default, callback)
    local val = default or min

    local wrapper = Instance.new("Frame")
    wrapper.Size             = UDim2.new(1, 0, 0, 54)
    wrapper.BackgroundColor3 = T.BG
    wrapper.BorderSizePixel  = 0
    wrapper.ZIndex           = 13
    wrapper.Parent           = page
    corner(wrapper, 7)
    stroke(wrapper, T.BORDER, 1)

    local hRow = Instance.new("Frame")
    hRow.Size             = UDim2.new(1, -24, 0, 20)
    hRow.Position         = UDim2.new(0, 12, 0, 8)
    hRow.BackgroundTransparency = 1
    hRow.ZIndex           = 14
    hRow.Parent           = wrapper

    local lbl = Instance.new("TextLabel")
    lbl.Text             = text
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = T.TEXT
    lbl.BackgroundTransparency = 1
    lbl.Size             = UDim2.new(0.65, 0, 1, 0)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 14
    lbl.Parent           = hRow

    local valLbl = Instance.new("TextLabel")
    valLbl.Text              = tostring(val)
    valLbl.Font              = Enum.Font.GothamBold
    valLbl.TextSize          = 13
    valLbl.TextColor3        = T.ACCENT
    valLbl.BackgroundTransparency = 1
    valLbl.Size              = UDim2.new(0.35, 0, 1, 0)
    valLbl.Position          = UDim2.new(0.65, 0, 0, 0)
    valLbl.TextXAlignment    = Enum.TextXAlignment.Right
    valLbl.ZIndex            = 14
    valLbl.Parent            = hRow

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -24, 0, 6)
    track.Position         = UDim2.new(0, 12, 0, 36)
    track.BackgroundColor3 = T.SLIDER_BG
    track.BorderSizePixel  = 0
    track.ZIndex           = 14
    track.Parent           = wrapper
    corner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = T.ACCENT
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 15
    fill.Parent           = track
    corner(fill, 3)
    local fg = Instance.new("UIGradient")
    fg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.ACCENT), ColorSequenceKeypoint.new(1, T.ACCENT2) })
    fg.Parent = fill

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 14, 0, 14)
    dot.AnchorPoint      = Vector2.new(0.5, 0.5)
    dot.Position         = UDim2.new((val - min) / (max - min), 0, 0.5, 0)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 16
    dot.Parent           = track
    corner(dot, 7)
    stroke(dot, T.ACCENT, 2)

    local dragging = false
    local function setVal(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(min + rel * (max - min))
        valLbl.Text = tostring(val)
        tween(fill, FAST, { Size = UDim2.new(rel, 0, 1, 0) })
        tween(dot, FAST, { Position = UDim2.new(rel, 0, 0.5, 0) })
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setVal(inp.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then setVal(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return function() return val end
end

local function addInput(page, placeholder, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel  = 0
    row.ZIndex           = 13
    row.Parent           = page
    corner(row, 7)
    stroke(row, T.BORDER, 1)

    local box = Instance.new("TextBox")
    box.PlaceholderText   = placeholder or "Enter..."
    box.PlaceholderColor3 = T.SUBTEXT
    box.Text              = ""
    box.Font              = Enum.Font.Gotham
    box.TextSize          = 13
    box.TextColor3        = T.TEXT
    box.BackgroundTransparency = 1
    box.ClearTextOnFocus  = false
    box.Size              = UDim2.new(1, -20, 1, 0)
    box.Position          = UDim2.new(0, 10, 0, 0)
    box.TextXAlignment    = Enum.TextXAlignment.Left
    box.ZIndex            = 14
    box.Parent            = row

    box.FocusLost:Connect(function(enter)
        if enter and callback then callback(box.Text) end
    end)
    return box
end

local function addButton(page, text, callback)
    local btn = Instance.new("TextButton")
    btn.Text              = text
    btn.Font              = Enum.Font.GothamSemibold
    btn.TextSize          = 13
    btn.TextColor3        = T.TEXT
    btn.BackgroundColor3  = T.ACCENT
    btn.Size              = UDim2.new(1, 0, 0, 36)
    btn.BorderSizePixel   = 0
    btn.AutoButtonColor   = false
    btn.ZIndex            = 13
    btn.Parent            = page
    corner(btn, 7)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, T.ACCENT), ColorSequenceKeypoint.new(1, T.ACCENT2) })
    g.Rotation = 45
    g.Parent   = btn

    btn.MouseEnter:Connect(function() tween(btn, FAST, { BackgroundColor3 = Color3.fromRGB(160, 118, 255) }) end)
    btn.MouseLeave:Connect(function() tween(btn, FAST, { BackgroundColor3 = T.ACCENT }) end)
    btn.MouseButton1Click:Connect(function()
        tween(btn, TI(0.07, Enum.EasingStyle.Linear), { Size = UDim2.new(1, -6, 0, 30) })
        task.delay(0.07, function()
            tween(btn, TI(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 36) })
        end)
        if callback then callback() end
    end)
    return btn
end

local function addColorRow(page, text, default, callback)
    local col = default or Color3.fromRGB(255, 255, 255)
    local r, g, b = math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255)

    local wrapper = Instance.new("Frame")
    wrapper.Size             = UDim2.new(1, 0, 0, 136)
    wrapper.BackgroundColor3 = T.BG
    wrapper.BorderSizePixel  = 0
    wrapper.ZIndex           = 13
    wrapper.Parent           = page
    corner(wrapper, 7)
    stroke(wrapper, T.BORDER, 1)

    local headerLbl = Instance.new("TextLabel")
    headerLbl.Text             = text
    headerLbl.Font             = Enum.Font.Gotham
    headerLbl.TextSize         = 13
    headerLbl.TextColor3       = T.TEXT
    headerLbl.BackgroundTransparency = 1
    headerLbl.Position         = UDim2.new(0, 12, 0, 6)
    headerLbl.Size             = UDim2.new(0.65, 0, 0, 18)
    headerLbl.TextXAlignment   = Enum.TextXAlignment.Left
    headerLbl.ZIndex           = 14
    headerLbl.Parent           = wrapper

    local preview = Instance.new("Frame")
    preview.Size             = UDim2.new(0, 26, 0, 18)
    preview.Position         = UDim2.new(1, -38, 0, 6)
    preview.BackgroundColor3 = col
    preview.BorderSizePixel  = 0
    preview.ZIndex           = 14
    preview.Parent           = wrapper
    corner(preview, 4)
    stroke(preview, T.BORDER, 1)

    local function updateColor()
        col = Color3.fromRGB(r, g, b)
        preview.BackgroundColor3 = col
        if callback then callback(col) end
    end

    local function miniSlider(yOff, chan, cName, fillColor)
        local cLbl = Instance.new("TextLabel")
        cLbl.Text             = cName
        cLbl.Font             = Enum.Font.Gotham
        cLbl.TextSize         = 10
        cLbl.TextColor3       = T.SUBTEXT
        cLbl.BackgroundTransparency = 1
        cLbl.Position         = UDim2.new(0, 12, 0, yOff)
        cLbl.Size             = UDim2.new(1, -24, 0, 13)
        cLbl.TextXAlignment   = Enum.TextXAlignment.Left
        cLbl.ZIndex           = 14
        cLbl.Parent           = wrapper

        local tr = Instance.new("Frame")
        tr.Size             = UDim2.new(1, -24, 0, 6)
        tr.Position         = UDim2.new(0, 12, 0, yOff + 14)
        tr.BackgroundColor3 = T.SLIDER_BG
        tr.BorderSizePixel  = 0
        tr.ZIndex           = 14
        tr.Parent           = wrapper
        corner(tr, 3)

        local initV = chan == "r" and r or chan == "g" and g or b
        local fl = Instance.new("Frame")
        fl.Size             = UDim2.new(initV/255, 0, 1, 0)
        fl.BackgroundColor3 = fillColor
        fl.BorderSizePixel  = 0
        fl.ZIndex           = 15
        fl.Parent           = tr
        corner(fl, 3)

        local dragging = false
        local function upd(x)
            local rel = math.clamp((x - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
            if     chan == "r" then r = math.floor(rel*255)
            elseif chan == "g" then g = math.floor(rel*255)
            else                    b = math.floor(rel*255) end
            tween(fl, FAST, { Size = UDim2.new(rel, 0, 1, 0) })
            updateColor()
        end
        tr.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; upd(inp.Position.X) end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then upd(inp.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    miniSlider(28, "r", "R", Color3.fromRGB(220, 60, 80))
    miniSlider(58, "g", "G", Color3.fromRGB(60, 200, 100))
    miniSlider(88, "b", "B", Color3.fromRGB(60, 120, 240))
end

-- ─────────────────────────────────────────
--           ⚡ MOVEMENT TAB
-- ─────────────────────────────────────────
local movPage = makeTab("Movement", "⚡", 1)
addSection(movPage, "Locomotion")

local speedVal = 16
addSlider(movPage, "Walk Speed", 16, 350, 16, function(v)
    speedVal = v
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)

addSlider(movPage, "Jump Power", 7, 200, 50, function(v)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end)

addSection(movPage, "Flight")

-- Fly
local flyActive = false
local flyBodyVel, flyBodyGyro, flyConn

addToggle(movPage, "Fly  [WASD + Space/Ctrl]", false, function(on)
    flyActive = on
    char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if on then
        hum.PlatformStand = true
        flyBodyVel           = Instance.new("BodyVelocity")
        flyBodyVel.Velocity  = Vector3.zero
        flyBodyVel.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
        flyBodyVel.Parent    = hrp

        flyBodyGyro            = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque  = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro.D          = 100
        flyBodyGyro.Parent     = hrp

        local cam = workspace.CurrentCamera
        local SPEED = 60

        flyConn = RunService.Heartbeat:Connect(function()
            if not flyActive then return end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

            local shifted = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            flyBodyVel.Velocity  = move.Magnitude > 0 and move.Unit * SPEED * (shifted and 2.2 or 1) or Vector3.zero
            flyBodyGyro.CFrame   = cam.CFrame
        end)
    else
        hum.PlatformStand = false
        if flyBodyVel  then flyBodyVel:Destroy()  end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyConn     then flyConn:Disconnect()  end
    end
end)

addSlider(movPage, "Fly Speed", 20, 500, 60, function(v)
    -- stored reference, picked up by heartbeat via closure
end)

addSection(movPage, "Utility")

-- Noclip
local noclipActive = false
local noclipConn

addToggle(movPage, "Noclip", false, function(on)
    noclipActive = on
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipActive then return end
            char = lp.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
        char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)

-- Infinite Jump
local ijConn
addToggle(movPage, "Infinite Jump", false, function(on)
    if on then
        ijConn = UserInputService.JumpRequest:Connect(function()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if ijConn then ijConn:Disconnect() end
    end
end)

-- Anti-gravity (Low Gravity)
addToggle(movPage, "Low Gravity", false, function(on)
    workspace.Gravity = on and 20 or 196.2
end)

-- ─────────────────────────────────────────
--           🎨 SKINCHANGER TAB
-- ─────────────────────────────────────────
local skinPage = makeTab("Skinchanger", "🎨", 2)
addSection(skinPage, "Body Colors")

local bodyParts = {
    { name = "Head",       part = "Head" },
    { name = "Torso",      part = "UpperTorso" },
    { name = "Left Arm",   part = "LeftUpperArm" },
    { name = "Right Arm",  part = "RightUpperArm" },
    { name = "Left Leg",   part = "LeftUpperLeg" },
    { name = "Right Leg",  part = "RightUpperLeg" },
}

for _, bp in ipairs(bodyParts) do
    addColorRow(skinPage, bp.name, Color3.fromRGB(255, 220, 177), function(col)
        char = lp.Character
        if not char then return end
        local part = char:FindFirstChild(bp.part)
        if part then part.Color = col end
    end)
end

addSection(skinPage, "Clothing IDs")

local shirtBox = addInput(skinPage, "Shirt Asset ID (e.g. 1234567)")
local pantsBox = addInput(skinPage, "Pants Asset ID (e.g. 9876543)")

addButton(skinPage, "Apply Shirt", function()
    char = lp.Character
    if not char then return end
    local id = tonumber(shirtBox.Text)
    if not id then return end
    local shirt = char:FindFirstChildOfClass("Shirt")
    if not shirt then
        shirt = Instance.new("Shirt")
        shirt.Parent = char
    end
    shirt.ShirtTemplate = "rbxassetid://" .. id
end)

addButton(skinPage, "Apply Pants", function()
    char = lp.Character
    if not char then return end
    local id = tonumber(pantsBox.Text)
    if not id then return end
    local pants = char:FindFirstChildOfClass("Pants")
    if not pants then
        pants = Instance.new("Pants")
        pants.Parent = char
    end
    pants.PantsTemplate = "rbxassetid://" .. id
end)

addSection(skinPage, "Character Size")

addSlider(skinPage, "Body Scale", 70, 200, 100, function(v)
    char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local desc = hum:GetAppliedDescription()
    local scale = v / 100
    desc.HeightScale = scale
    desc.BodyWidthScale  = scale
    desc.BodyDepthScale  = scale
    hum:ApplyDescription(desc)
end)

addSection(skinPage, "Head & Face")

local faceBox = addInput(skinPage, "Face Asset ID (e.g. 86487700)")

addButton(skinPage, "Apply Face", function()
    char = lp.Character
    if not char then return end
    local id = tonumber(faceBox.Text)
    if not id then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local desc = hum:GetAppliedDescription()
    desc.Face = id
    hum:ApplyDescription(desc)
end)

addButton(skinPage, "Reset Character", function()
    lp:LoadCharacter()
end)

-- ─────────────────────────────────────────
--           🎯 AIM TAB  — full rewrite
-- ─────────────────────────────────────────
local aimPage = makeTab("Aim", "🎯", 3)

-- ── helpers ──────────────────────────────
local function makeKeyBind(page, label, default, onChange)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel  = 0
    row.ZIndex           = 13
    row.Parent           = page
    corner(row, 7)
    stroke(row, T.BORDER, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Text             = label
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = T.TEXT
    lbl.BackgroundTransparency = 1
    lbl.Position         = UDim2.new(0, 12, 0, 0)
    lbl.Size             = UDim2.new(0.55, 0, 1, 0)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 14
    lbl.Parent           = row

    local btn = Instance.new("TextButton")
    btn.Text             = "[ " .. default.Name .. " ]"
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.TextColor3       = T.ACCENT
    btn.BackgroundColor3 = T.PANEL
    btn.Size             = UDim2.new(0, 90, 0, 24)
    btn.Position         = UDim2.new(1, -100, 0.5, -12)
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.ZIndex           = 14
    btn.Parent           = row
    corner(btn, 6)
    stroke(btn, T.BORDER, 1)

    local current = default
    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text      = "[ ... ]"
        btn.TextColor3 = T.ACCENT2
        local c
        c = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                current       = inp.KeyCode
                btn.Text      = "[ " .. inp.KeyCode.Name .. " ]"
                btn.TextColor3 = T.ACCENT
                listening     = false
                if onChange then onChange(current) end
                c:Disconnect()
            end
        end)
    end)
    return function() return current end
end

local function addCheckBox(page, text, default, callback)
    local state = default or false

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = T.BG
    row.BorderSizePixel  = 0
    row.ZIndex           = 13
    row.Parent           = page
    corner(row, 7)
    stroke(row, T.BORDER, 1)

    local box = Instance.new("Frame")
    box.Size             = UDim2.new(0, 18, 0, 18)
    box.Position         = UDim2.new(0, 10, 0.5, -9)
    box.BackgroundColor3 = state and T.ACCENT or T.TOGGLE_OFF
    box.BorderSizePixel  = 0
    box.ZIndex           = 14
    box.Parent           = row
    corner(box, 4)
    stroke(box, T.BORDER, 1)

    local check = Instance.new("TextLabel")
    check.Text             = state and "✓" or ""
    check.Font             = Enum.Font.GothamBold
    check.TextSize         = 12
    check.TextColor3       = Color3.fromRGB(255,255,255)
    check.BackgroundTransparency = 1
    check.Size             = UDim2.new(1,0,1,0)
    check.TextXAlignment   = Enum.TextXAlignment.Center
    check.ZIndex           = 15
    check.Parent           = box

    local lbl = Instance.new("TextLabel")
    lbl.Text             = text
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 12
    lbl.TextColor3       = T.TEXT
    lbl.BackgroundTransparency = 1
    lbl.Position         = UDim2.new(0, 36, 0, 0)
    lbl.Size             = UDim2.new(1, -46, 1, 0)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 14
    lbl.Parent           = row

    local function setState(v)
        state = v
        tween(box, FAST, { BackgroundColor3 = state and T.ACCENT or T.TOGGLE_OFF })
        check.Text = state and "✓" or ""
        if callback then callback(state) end
    end

    local clickBtn = Instance.new("TextButton")
    clickBtn.Text             = ""
    clickBtn.BackgroundTransparency = 1
    clickBtn.Size             = UDim2.new(1,0,1,0)
    clickBtn.ZIndex           = 16
    clickBtn.Parent           = row
    clickBtn.MouseButton1Click:Connect(function() setState(not state) end)

    return setState, function() return state end
end

-- ── AIM STATE ────────────────────────────
local aimEnabled      = false
local aimFOVBase      = 150       -- base FOV px
local aimFOVCurrent   = 150       -- live (dynamic)
local aimSmooth       = 6         -- lerp divisor
local aimKey          = Enum.KeyCode.Q
local aimTeamCheck    = false
local aimWallCheck    = true
local aimDynFOV       = true      -- dynamic FOV on/off
local aimDynFOVVelScale  = 0.4    -- how much velocity expands FOV
local aimDynFOVDistScale = 0.15   -- how much distance shrinks FOV
local aimPrediction   = true      -- velocity prediction
local aimPredStrength = 0.12      -- ping factor multiplier
local aimPeekAssist   = true      -- peek detection lock
local aimPeekBurst    = 3         -- how many frames to snap on peek

-- Per-part enabled table  (true = aim at this part)
local PART_DEFS = {
    { key = "Head",          label = "Head",          enabled = true  },
    { key = "UpperTorso",    label = "Upper Torso",   enabled = true  },
    { key = "LowerTorso",    label = "Lower Torso",   enabled = false },
    { key = "HumanoidRootPart", label = "Root (HRP)", enabled = false },
    { key = "LeftUpperArm",  label = "Left Arm",      enabled = false },
    { key = "RightUpperArm", label = "Right Arm",     enabled = false },
    { key = "LeftUpperLeg",  label = "Left Leg",      enabled = false },
    { key = "RightUpperLeg", label = "Right Leg",     enabled = false },
}

-- velocity history per player  { [player] = {pos, pos, pos...} }
local velHistory = {}
local prevOccluded = {}  -- { [player] = bool }  for peek detect
local peekFrames   = {}  -- { [player] = int }   countdown

-- ── FOV DRAWINGS ─────────────────────────
local fovCircleMain, fovCircleDyn
pcall(function()
    fovCircleMain           = Drawing.new("Circle")
    fovCircleMain.Visible   = false
    fovCircleMain.Thickness = 1.2
    fovCircleMain.Color     = Color3.fromRGB(138, 99, 255)
    fovCircleMain.Filled    = false
    fovCircleMain.Transparency = 1
    fovCircleMain.NumSides  = 80
    fovCircleMain.Radius    = aimFOVBase

    fovCircleDyn            = Drawing.new("Circle")
    fovCircleDyn.Visible    = false
    fovCircleDyn.Thickness  = 0.7
    fovCircleDyn.Color      = Color3.fromRGB(99, 180, 255)
    fovCircleDyn.Filled     = false
    fovCircleDyn.Transparency = 1
    fovCircleDyn.NumSides   = 80
    fovCircleDyn.Radius     = aimFOVBase
end)

local function updateDrawings()
    local cam = workspace.CurrentCamera
    local cx  = cam.ViewportSize.X / 2
    local cy  = cam.ViewportSize.Y / 2
    local center = Vector2.new(cx, cy)
    pcall(function()
        fovCircleMain.Position = center
        fovCircleMain.Radius   = aimFOVBase
        fovCircleMain.Visible  = aimEnabled

        fovCircleDyn.Position  = center
        fovCircleDyn.Radius    = aimFOVCurrent
        fovCircleDyn.Visible   = aimEnabled and aimDynFOV and (aimFOVCurrent ~= aimFOVBase)
    end)
end

-- ── CORE LOGIC ───────────────────────────
local function getEnabledParts()
    local list = {}
    for _, def in ipairs(PART_DEFS) do
        if def.enabled then list[#list+1] = def.key end
    end
    return list
end

local function isOccluded(pos, pChar)
    if not aimWallCheck then return false end
    local cam    = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local dir    = pos - origin
    local ray    = Ray.new(origin + dir.Unit * 0.5, dir * 0.98)
    local hit    = workspace:FindPartOnRayWithIgnoreList(ray, { lp.Character })
    return hit and not hit:IsDescendantOf(pChar)
end

local function getPredictedPos(player, part, dt)
    if not aimPrediction then return part.Position end
    local pid = player.UserId
    local history = velHistory[pid]
    if not history then return part.Position end

    -- weighted average of last 3 velocity samples
    local count  = #history
    if count < 2 then return part.Position end

    local samples = math.min(3, count - 1)
    local velSum  = Vector3.zero
    local weightTotal = 0
    for i = count, count - samples + 1, -1 do
        local w   = count - i + 1
        local vel = history[i] - history[i - 1]
        velSum    = velSum + vel * w
        weightTotal = weightTotal + w
    end
    local avgVel = velSum / weightTotal

    -- ping estimate via stats if available
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)

    local lead = (ping * aimPredStrength + dt) * 60
    return part.Position + avgVel * lead
end

local function computeDynFOV(targetPos)
    if not aimDynFOV then
        aimFOVCurrent = aimFOVBase
        return aimFOVBase
    end
    local cam  = workspace.CurrentCamera
    local dist = (targetPos - cam.CFrame.Position).Magnitude

    -- try to get target velocity magnitude from history
    local velMag = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local pChar = player.Character
        if not pChar then continue end
        local hrp = pChar:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - targetPos).Magnitude < 5 then
            local pid = player.UserId
            local h   = velHistory[pid]
            if h and #h >= 2 then
                velMag = (h[#h] - h[#h-1]).Magnitude * 60
            end
            break
        end
    end

    local expanded  = aimFOVBase + velMag   * aimDynFOVVelScale
    local shrunk    = expanded   - dist      * aimDynFOVDistScale
    aimFOVCurrent   = math.clamp(shrunk, aimFOVBase * 0.4, aimFOVBase * 2.5)
    return aimFOVCurrent
end

local function getTarget(dt)
    local cam      = workspace.CurrentCamera
    local vp       = cam.ViewportSize
    local center   = Vector2.new(vp.X / 2, vp.Y / 2)
    local parts    = getEnabledParts()
    local best, bestDist, bestPredPos = nil, math.huge, nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end
        if aimTeamCheck and player.Team == lp.Team then continue end

        local pChar = player.Character
        if not pChar then continue end
        local hum = pChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local pid = player.UserId

        -- update velocity history
        local hrp = pChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not velHistory[pid] then velHistory[pid] = {} end
            local h = velHistory[pid]
            h[#h+1] = hrp.Position
            if #h > 10 then table.remove(h, 1) end
        end

        -- peek assist detection
        local occ = isOccluded(hrp and hrp.Position or Vector3.zero, pChar)
        if aimPeekAssist then
            if prevOccluded[pid] == true and not occ then
                peekFrames[pid] = aimPeekBurst
            end
            prevOccluded[pid] = occ
        end
        local isPeeking = (peekFrames[pid] or 0) > 0

        for _, partName in ipairs(parts) do
            local part = pChar:FindFirstChild(partName)
            if not part then continue end

            local predPos   = getPredictedPos(player, part, dt)
            local proj, vis = cam:WorldToViewportPoint(predPos)
            if not vis then continue end

            local screenPt = Vector2.new(proj.X, proj.Y)
            local fov      = isPeeking and aimFOVBase * 1.6 or computeDynFOV(predPos)
            local dist2d   = (screenPt - center).Magnitude

            if dist2d > fov then continue end

            -- wall check (skip if peeking — we want to snap immediately)
            if not isPeeking and isOccluded(predPos, pChar) then continue end

            -- 3D distance tiebreaker so we prefer closer players
            local dist3d = proj.Z
            local score  = dist2d + dist3d * 0.1

            if score < bestDist then
                bestDist    = score
                best        = part
                bestPredPos = predPos
            end
        end

        if (peekFrames[pid] or 0) > 0 then
            peekFrames[pid] = peekFrames[pid] - 1
        end
    end

    return best, bestPredPos
end

-- ── MAIN LOOP ────────────────────────────
local aimConn

local function startAim()
    if aimConn then aimConn:Disconnect() end
    local cam = workspace.CurrentCamera

    aimConn = RunService.Heartbeat:Connect(function(dt)
        updateDrawings()

        if not UserInputService:IsKeyDown(aimKey) then return end
        if not aimEnabled then return end

        local target, predPos = getTarget(dt)
        if not target or not predPos then return end

        local targetCF  = CFrame.new(cam.CFrame.Position, predPos)
        local lerpAlpha = math.clamp(1 / math.max(aimSmooth, 0.5), 0.01, 1)
        cam.CFrame      = cam.CFrame:Lerp(targetCF, lerpAlpha)
    end)
end

local function stopAim()
    if aimConn then aimConn:Disconnect(); aimConn = nil end
    pcall(function()
        if fovCircleMain then fovCircleMain.Visible = false end
        if fovCircleDyn  then fovCircleDyn.Visible  = false end
    end)
end

-- ── UI ────────────────────────────────────
addSection(aimPage, "Aimbot")

addToggle(aimPage, "Enable Aimbot", false, function(on)
    aimEnabled = on
    if on then startAim() else stopAim() end
end)

makeKeyBind(aimPage, "Activate Key:", Enum.KeyCode.Q, function(k) aimKey = k end)

addSection(aimPage, "Hit Parts  (toggle each)")

-- Per-part checkbox grid
for i, def in ipairs(PART_DEFS) do
    local idx = i
    addCheckBox(aimPage, def.label, def.enabled, function(v)
        PART_DEFS[idx].enabled = v
    end)
end

addSection(aimPage, "FOV")

addSlider(aimPage, "Base FOV (px)", 30, 600, 150, function(v)
    aimFOVBase = v
    if not aimDynFOV then aimFOVCurrent = v end
    updateDrawings()
end)

addToggle(aimPage, "Dynamic FOV  (expands with target velocity)", true, function(on)
    aimDynFOV = on
    if not on then aimFOVCurrent = aimFOVBase end
end)

addSlider(aimPage, "Dyn FOV — Velocity Scale  ×0.01", 0, 200, 40, function(v)
    aimDynFOVVelScale = v * 0.01
end)

addSlider(aimPage, "Dyn FOV — Distance Shrink  ×0.01", 0, 100, 15, function(v)
    aimDynFOVDistScale = v * 0.01
end)

addSection(aimPage, "Smoothness")

addSlider(aimPage, "Smooth  (1=Instant  30=Butter)", 1, 30, 6, function(v)
    aimSmooth = v
end)

addSection(aimPage, "Prediction")

addToggle(aimPage, "Velocity Prediction", true, function(on)
    aimPrediction = on
end)

addSlider(aimPage, "Prediction Strength  ×0.01", 1, 50, 12, function(v)
    aimPredStrength = v * 0.01
end)

addSection(aimPage, "Peek Assist")

addToggle(aimPage, "Peek Assist  (snap on exit cover)", true, function(on)
    aimPeekAssist = on
end)

addSlider(aimPage, "Peek Snap Frames", 1, 12, 3, function(v)
    aimPeekBurst = v
end)

addSection(aimPage, "Filters")

addToggle(aimPage, "Wall Check", true, function(on)
    aimWallCheck = on
end)

addToggle(aimPage, "Team Check  (skip teammates)", false, function(on)
    aimTeamCheck = on
end)

-- ─────────────────────────────────────────
--        ACTIVATE FIRST TAB
-- ─────────────────────────────────────────
task.delay(0.12, function()
    local btn = tabs["Movement"]
    if btn then btn.MouseButton1Click:Fire() end
end)

-- Cleanup on destroy
gui.AncestryChanged:Connect(function()
    pcall(function()
        if fovCircleMain then fovCircleMain:Remove() end
        if fovCircleDyn  then fovCircleDyn:Remove()  end
    end)
    stopAim()
end)

-- Respawn character update
lp.CharacterAdded:Connect(function(c)
    char = c
    velHistory  = {}
    prevOccluded = {}
    peekFrames   = {}
end)

