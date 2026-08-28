local Zabota = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Themes = {
    Dark = {
        MainBg = Color3.fromRGB(14, 15, 19),
        MainBg2 = Color3.fromRGB(10, 10, 13),
        CardBg = Color3.fromRGB(21, 22, 28),
        CardBg2 = Color3.fromRGB(17, 18, 23),
        CardItemBg = Color3.fromRGB(27, 29, 37),
        CardItemBg2 = Color3.fromRGB(23, 24, 31),
        Border = Color3.fromRGB(42, 45, 56),
        Accent = Color3.fromRGB(238, 70, 70),
        Accent2 = Color3.fromRGB(255, 140, 70),
        TextPrimary = Color3.fromRGB(242, 244, 250),
        TextSecondary = Color3.fromRGB(140, 145, 162),
        TextTertiary = Color3.fromRGB(95, 99, 115),
        SliderTrack = Color3.fromRGB(33, 36, 46)
    }
}

local CurrentTheme = Themes.Dark
local GlobalTransparency = 0.05
local AnimSpeed = 0.32

----------------------------------------------------------------
-- Core tween helper
----------------------------------------------------------------
local function Tween(instance, properties, duration, style, direction)
    local t = TweenService:Create(instance, TweenInfo.new(duration or AnimSpeed, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or CurrentTheme.Border
    s.Thickness = thickness or 1.2
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function Gradient(parent, colorSeq, rotation, transparencySeq)
    local g = Instance.new("UIGradient")
    g.Color = colorSeq
    g.Rotation = rotation or 90
    if transparencySeq then g.Transparency = transparencySeq end
    g.Parent = parent
    return g
end

----------------------------------------------------------------
-- Hover / press micro-interaction helper
----------------------------------------------------------------
local function ApplyPressFeel(button, hoverScale, connsTable)
    hoverScale = hoverScale or 1.02
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local c1 = button.MouseEnter:Connect(function()
        Tween(scale, {Scale = hoverScale}, 0.16, Enum.EasingStyle.Quad)
    end)
    local c2 = button.MouseLeave:Connect(function()
        Tween(scale, {Scale = 1}, 0.18, Enum.EasingStyle.Quad)
    end)
    local c3 = button.MouseButton1Down:Connect(function()
        Tween(scale, {Scale = 0.965}, 0.08, Enum.EasingStyle.Quad)
    end)
    local c4 = button.MouseButton1Up:Connect(function()
        Tween(scale, {Scale = hoverScale}, 0.12, Enum.EasingStyle.Quad)
    end)

    if connsTable then
        table.insert(connsTable, c1)
        table.insert(connsTable, c2)
        table.insert(connsTable, c3)
        table.insert(connsTable, c4)
    end
    return scale
end

-- Slide-in accent bar that grows on hover (left edge highlight)
local function ApplyAccentHover(button, connsTable)
    local Bar = Instance.new("Frame")
    Bar.Name = "HoverAccent"
    Bar.AnchorPoint = Vector2.new(0, 0.5)
    Bar.Position = UDim2.new(0, 0, 0.5, 0)
    Bar.Size = UDim2.new(0, 3, 0, 0)
    Bar.BackgroundColor3 = CurrentTheme.Accent
    Bar.BorderSizePixel = 0
    Bar.ZIndex = (button.ZIndex or 1) + 2
    Bar.Parent = button
    Corner(Bar, 2)

    local c1 = button.MouseEnter:Connect(function()
        Tween(Bar, {Size = UDim2.new(0, 3, 0.62, 0)}, 0.18, Enum.EasingStyle.Quad)
    end)
    local c2 = button.MouseLeave:Connect(function()
        Tween(Bar, {Size = UDim2.new(0, 3, 0, 0)}, 0.18, Enum.EasingStyle.Quad)
    end)
    if connsTable then
        table.insert(connsTable, c1)
        table.insert(connsTable, c2)
    end
    return Bar
end

----------------------------------------------------------------
-- Soft drop shadow that tracks a target GuiObject
----------------------------------------------------------------
local function AttachShadow(target, screenGui, intensity)
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow_" .. target.Name
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = intensity or 0.45
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.BackgroundTransparency = 1
    Shadow.ZIndex = math.max((target.ZIndex or 1) - 1, 0)
    Shadow.Parent = screenGui

    local function sync()
        local pad = 34
        Shadow.Size = UDim2.fromOffset(target.AbsoluteSize.X + pad * 2, target.AbsoluteSize.Y + pad * 2)
        Shadow.Position = UDim2.fromOffset(target.AbsolutePosition.X - pad, target.AbsolutePosition.Y - pad)
    end

    target:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
    target:GetPropertyChangedSignal("AbsolutePosition"):Connect(sync)
    task.defer(sync)
    return Shadow
end

----------------------------------------------------------------
-- Staggered "fly-in" animation for lists of elements
----------------------------------------------------------------
local function PlayStaggerIn(container)
    local items = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") then
            table.insert(items, child)
        end
    end
    table.sort(items, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

    for i, item in ipairs(items) do
        local originalPos = item.Position
        local originalTransp = item.BackgroundTransparency
        item.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 14, originalPos.Y.Scale, originalPos.Y.Offset)
        item.BackgroundTransparency = 1
        task.delay((i - 1) * 0.045, function()
            if item and item.Parent then
                Tween(item, {Position = originalPos, BackgroundTransparency = originalTransp}, 0.28, Enum.EasingStyle.Quint)
            end
        end)
    end
end

----------------------------------------------------------------
-- Dragging
----------------------------------------------------------------
local function MakeDraggable(frame, handle, connectionsTable)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    local c2 = handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local c3 = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.06, Enum.EasingStyle.Sine)
        end
    end)

    if connectionsTable then
        table.insert(connectionsTable, c1)
        table.insert(connectionsTable, c2)
        table.insert(connectionsTable, c3)
    end
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
function Zabota:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "ZABOTA"
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local Connections = {}

    if PlayerGui:FindFirstChild("ZabotaUI_Screen") then
        PlayerGui.ZabotaUI_Screen:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZabotaUI_Screen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    -- Background blur used while the menu is open (depth-of-field feel)
    local Blur = Lighting:FindFirstChild("ZabotaBlur")
    if not Blur then
        Blur = Instance.new("BlurEffect")
        Blur.Name = "ZabotaBlur"
        Blur.Size = 0
        Blur.Parent = Lighting
    end

    ----------------------------------------------------------------
    -- Toasts
    ----------------------------------------------------------------
    local ToastContainer = Instance.new("Frame")
    ToastContainer.Size = UDim2.new(0, 270, 1, -20)
    ToastContainer.Position = UDim2.new(1, -285, 0, 10)
    ToastContainer.BackgroundTransparency = 1
    ToastContainer.Parent = ScreenGui

    local ToastLayout = Instance.new("UIListLayout")
    ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ToastLayout.Padding = UDim.new(0, 8)
    ToastLayout.Parent = ToastContainer

    local function Notify(title, desc, duration)
        if not ScreenGui or not ScreenGui.Parent then return end
        duration = duration or 3

        local Toast = Instance.new("Frame")
        Toast.Size = UDim2.new(1, 60, 0, 0)
        Toast.Position = UDim2.new(0, 60, 0, 0)
        Toast.BackgroundColor3 = CurrentTheme.CardBg
        Toast.BackgroundTransparency = 1
        Toast.ClipsDescendants = true
        Toast.Parent = ToastContainer
        Corner(Toast, 10)
        Stroke(Toast, CurrentTheme.Border, 1.2)
        AttachShadow(Toast, ScreenGui, 0.6)

        local Bar = Instance.new("Frame", Toast)
        Bar.Size = UDim2.new(0, 4, 1, 0)
        Bar.BackgroundColor3 = CurrentTheme.Accent
        Bar.BorderSizePixel = 0
        Gradient(Bar, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 90)

        local Icon = Instance.new("ImageLabel", Toast)
        Icon.Image = "rbxassetid://6031091004"
        Icon.ImageColor3 = CurrentTheme.Accent
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.Position = UDim2.new(0, 14, 0, 10)
        Icon.BackgroundTransparency = 1

        local t = Instance.new("TextLabel", Toast)
        t.Text = title:upper(); t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextColor3 = CurrentTheme.TextPrimary
        t.Position = UDim2.new(0, 36, 0, 8); t.Size = UDim2.new(1, -46, 0, 16); t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left

        local d = Instance.new("TextLabel", Toast)
        d.Text = desc; d.Font = Enum.Font.Gotham; d.TextSize = 11; d.TextColor3 = CurrentTheme.TextSecondary
        d.Position = UDim2.new(0, 14, 0, 27); d.Size = UDim2.new(1, -24, 0, 22); d.BackgroundTransparency = 1; d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextWrapped = true

        local ProgressTrack = Instance.new("Frame", Toast)
        ProgressTrack.Size = UDim2.new(1, -12, 0, 2)
        ProgressTrack.Position = UDim2.new(0, 6, 1, -6)
        ProgressTrack.BackgroundColor3 = CurrentTheme.SliderTrack
        ProgressTrack.BorderSizePixel = 0
        Corner(ProgressTrack, 2)

        local ProgressFill = Instance.new("Frame", ProgressTrack)
        ProgressFill.Size = UDim2.new(1, 0, 1, 0)
        ProgressFill.BackgroundColor3 = CurrentTheme.Accent
        ProgressFill.BorderSizePixel = 0
        Corner(ProgressFill, 2)

        Tween(Toast, {Size = UDim2.new(1, 0, 0, 58), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = GlobalTransparency}, 0.4, Enum.EasingStyle.Back)
        Tween(ProgressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

        task.delay(duration, function()
            if Toast and Toast.Parent then
                local fade = Tween(Toast, {Size = UDim2.new(1, 60, 0, 0), Position = UDim2.new(0, 60, 0, 0), BackgroundTransparency = 1}, 0.28, Enum.EasingStyle.Quint)
                fade.Completed:Connect(function() if Toast then Toast:Destroy() end end)
            end
        end)
    end

    ----------------------------------------------------------------
    -- Main frame
    ----------------------------------------------------------------
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Size = UDim2.new(0, 720, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -360, 0.5, -220)
    MainFrame.BackgroundColor3 = CurrentTheme.MainBg
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 1
    MainFrame.Parent = ScreenGui

    Corner(MainFrame, 14)
    local MainStroke = Stroke(MainFrame, CurrentTheme.Accent, 1.4, 0.55)
    Gradient(MainFrame, ColorSequence.new(CurrentTheme.MainBg, CurrentTheme.MainBg2), 90)
    AttachShadow(MainFrame, ScreenGui, 0.42)

    -- subtle breathing glow on the border
    do
        local breathe
        local function loopBreathe()
            breathe = Tween(MainStroke, {Transparency = 0.85}, 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            breathe.Completed:Connect(function()
                if MainStroke and MainStroke.Parent then
                    Tween(MainStroke, {Transparency = 0.4}, 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut).Completed:Connect(loopBreathe)
                end
            end)
        end
        loopBreathe()
    end

    MakeDraggable(MainFrame, nil, Connections)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0, 52)
    TopBar.BackgroundColor3 = CurrentTheme.CardBg
    TopBar.BorderSizePixel = 0
    Gradient(TopBar, ColorSequence.new(CurrentTheme.CardBg, CurrentTheme.CardBg2), 90)

    local TopBarDivider = Instance.new("Frame", TopBar)
    TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
    TopBarDivider.Position = UDim2.new(0, 0, 1, -1)
    TopBarDivider.BackgroundColor3 = CurrentTheme.Border
    TopBarDivider.BorderSizePixel = 0
    TopBarDivider.BackgroundTransparency = 0.2

    local LogoDot = Instance.new("Frame", TopBar)
    LogoDot.Size = UDim2.new(0, 7, 0, 7)
    LogoDot.Position = UDim2.new(0, 20, 0.5, -3)
    LogoDot.BackgroundColor3 = CurrentTheme.Accent
    LogoDot.BorderSizePixel = 0
    Corner(LogoDot, 4)
    Gradient(LogoDot, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 45)

    local Logo = Instance.new("TextLabel", TopBar)
    Logo.Text = TitleText
    Logo.Font = Enum.Font.GothamBlack
    Logo.TextSize = 17
    Logo.TextColor3 = CurrentTheme.TextPrimary
    Logo.Position = UDim2.new(0, 34, 0, 0)
    Logo.Size = UDim2.new(0, 110, 1, 0)
    Logo.BackgroundTransparency = 1
    Logo.TextXAlignment = Enum.TextXAlignment.Left
    Gradient(Logo, ColorSequence.new(CurrentTheme.TextPrimary, CurrentTheme.Accent2), 0)

    local TabScroll = Instance.new("ScrollingFrame", TopBar)
    TabScroll.Size = UDim2.new(1, -155, 1, 0)
    TabScroll.Position = UDim2.new(0, 145, 0, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel = 0
    TabScroll.ScrollBarThickness = 0
    TabScroll.CanvasSize = UDim2.new(0, 800, 0, 0)

    -- Sliding indicator behind the active tab
    local TabIndicator = Instance.new("Frame", TabScroll)
    TabIndicator.Name = "TabIndicator"
    TabIndicator.BackgroundColor3 = CurrentTheme.CardItemBg
    TabIndicator.BorderSizePixel = 0
    TabIndicator.ZIndex = 1
    TabIndicator.Size = UDim2.new(0, 0, 0, 32)
    TabIndicator.Position = UDim2.new(0, 0, 0.5, -16)
    Corner(TabIndicator, 8)
    local IndicatorStroke = Stroke(TabIndicator, CurrentTheme.Accent, 1, 0.55)

    local TabListLayout = Instance.new("UIListLayout", TabScroll)
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabListLayout.Padding = UDim.new(0, 6)

    local function MoveIndicatorTo(tabBtn)
        task.spawn(function()
            RunService.Heartbeat:Wait()
            local relX = tabBtn.AbsolutePosition.X - TabScroll.AbsolutePosition.X + TabScroll.CanvasPosition.X
            Tween(TabIndicator, {
                Position = UDim2.new(0, relX, 0.5, -16),
                Size = UDim2.new(0, tabBtn.AbsoluteSize.X, 0, 32)
            }, 0.3, Enum.EasingStyle.Quint)
        end)
    end

    local PagesContainer = Instance.new("Frame", MainFrame)
    PagesContainer.Position = UDim2.new(0, 0, 0, 52)
    PagesContainer.Size = UDim2.new(1, 0, 1, -52)
    PagesContainer.BackgroundTransparency = 1

    ----------------------------------------------------------------
    -- Open / close
    ----------------------------------------------------------------
    local isMenuOpen = false
    local function ToggleMenu()
        if not ScreenGui or not ScreenGui.Parent then return end
        isMenuOpen = not isMenuOpen
        if isMenuOpen then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 690, 0, 420)
            Tween(MainFrame, {Size = UDim2.new(0, 720, 0, 440), GroupTransparency = 0}, 0.4, Enum.EasingStyle.Back)
            Tween(Blur, {Size = 14}, 0.35, Enum.EasingStyle.Quint)
        else
            Tween(MainFrame, {Size = UDim2.new(0, 690, 0, 420), GroupTransparency = 1}, AnimSpeed * 0.85, Enum.EasingStyle.Quint)
            Tween(Blur, {Size = 0}, 0.3, Enum.EasingStyle.Quint)
            task.delay(AnimSpeed * 0.85, function()
                if not isMenuOpen then MainFrame.Visible = false end
            end)
        end
    end

    local keyInputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == ToggleKey then
            ToggleMenu()
        end
    end)
    table.insert(Connections, keyInputConn)

    local Window = {
        Tabs = {},
        FirstTab = nil,
        Notify = Notify,
        Screen = ScreenGui
    }

    -- Intro animation: play the opening the moment the window is created
    task.defer(function()
        ToggleMenu()
    end)

    function Window:Uninject()
        for _, conn in ipairs(Connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        Connections = {}
        if Blur and Blur.Parent then
            Tween(Blur, {Size = 0}, 0.25)
        end
        if ScreenGui then
            local fade = Tween(MainFrame, {GroupTransparency = 1}, 0.2)
            fade.Completed:Connect(function()
                ScreenGui:Destroy()
            end)
        end
    end

    ----------------------------------------------------------------
    -- HUD
    ----------------------------------------------------------------
    function Window:CreateHUD(hudTitle)
        local HUD = Instance.new("Frame", ScreenGui)
        HUD.Size = UDim2.new(0, 200, 0, 36)
        HUD.AutomaticSize = Enum.AutomaticSize.Y
        HUD.Position = UDim2.new(0, 25, 0.5, -70)
        HUD.BackgroundColor3 = CurrentTheme.CardBg
        HUD.BackgroundTransparency = 1
        HUD.BorderSizePixel = 0

        Corner(HUD, 10)
        Stroke(HUD, CurrentTheme.Border, 1.2)
        Gradient(HUD, ColorSequence.new(CurrentTheme.CardBg, CurrentTheme.CardBg2), 90)
        AttachShadow(HUD, ScreenGui, 0.5)
        MakeDraggable(HUD, nil, Connections)

        Tween(HUD, {BackgroundTransparency = GlobalTransparency}, 0.35)

        local topBarAccent = Instance.new("Frame", HUD)
        topBarAccent.Size = UDim2.new(1, 0, 0, 3)
        topBarAccent.BackgroundColor3 = CurrentTheme.Accent
        topBarAccent.BorderSizePixel = 0
        Gradient(topBarAccent, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 0)

        local hTitle = Instance.new("TextLabel", HUD)
        hTitle.Text = (hudTitle or "KEYBINDS"):upper()
        hTitle.Font = Enum.Font.GothamBlack
        hTitle.TextSize = 12
        hTitle.TextColor3 = CurrentTheme.TextPrimary
        hTitle.Position = UDim2.new(0, 12, 0, 6)
        hTitle.Size = UDim2.new(1, -24, 0, 24)
        hTitle.BackgroundTransparency = 1
        hTitle.TextXAlignment = Enum.TextXAlignment.Left

        local hContainer = Instance.new("Frame", HUD)
        hContainer.Position = UDim2.new(0, 12, 0, 34)
        hContainer.Size = UDim2.new(1, -24, 0, 0)
        hContainer.AutomaticSize = Enum.AutomaticSize.Y
        hContainer.BackgroundTransparency = 1

        local hList = Instance.new("UIListLayout", hContainer)
        hList.Padding = UDim.new(0, 5)
        local p = Instance.new("UIPadding", hContainer); p.PaddingBottom = UDim.new(0, 8)

        local HUDHandler = {}
        function HUDHandler:AddBind(keyName, actionName, mode)
            local Row = Instance.new("Frame", hContainer)
            Row.Size = UDim2.new(1, 0, 0, 18)
            Row.BackgroundTransparency = 1

            local k = Instance.new("TextLabel", Row)
            k.Text = "[" .. keyName .. "]"; k.Font = Enum.Font.GothamBold; k.TextSize = 11; k.TextColor3 = CurrentTheme.Accent
            k.Size = UDim2.new(0, 45, 1, 0); k.BackgroundTransparency = 1; k.TextXAlignment = Enum.TextXAlignment.Left

            local a = Instance.new("TextLabel", Row)
            a.Text = actionName; a.Font = Enum.Font.GothamMedium; a.TextSize = 11; a.TextColor3 = CurrentTheme.TextSecondary
            a.Position = UDim2.new(0, 45, 0, 0); a.Size = UDim2.new(1, -95, 1, 0); a.BackgroundTransparency = 1; a.TextXAlignment = Enum.TextXAlignment.Left

            local m = Instance.new("TextLabel", Row)
            m.Text = mode or "TOGGLE"; m.Font = Enum.Font.GothamBold; m.TextSize = 10; m.TextColor3 = CurrentTheme.TextPrimary
            m.Position = UDim2.new(1, -50, 0, 0); m.Size = UDim2.new(0, 50, 1, 0); m.BackgroundTransparency = 1; m.TextXAlignment = Enum.TextXAlignment.Right
        end

        return HUDHandler
    end

    ----------------------------------------------------------------
    -- Tabs
    ----------------------------------------------------------------
    function Window:AddTab(tabName)
        local Page = Instance.new("Frame", PagesContainer)
        Page.Name = "Page_" .. tabName
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false

        local LeftCol = Instance.new("ScrollingFrame", Page)
        LeftCol.Position = UDim2.new(0, 18, 0, 14); LeftCol.Size = UDim2.new(0, 310, 1, -38)
        LeftCol.BackgroundTransparency = 1; LeftCol.BorderSizePixel = 0; LeftCol.ScrollBarThickness = 2
        LeftCol.ScrollBarImageColor3 = CurrentTheme.Accent
        local LeftList = Instance.new("UIListLayout", LeftCol); LeftList.Padding = UDim.new(0, 10)

        local RightCol = Instance.new("ScrollingFrame", Page)
        RightCol.Position = UDim2.new(0, 345, 0, 14); RightCol.Size = UDim2.new(1, -363, 1, -38)
        RightCol.BackgroundTransparency = 1; RightCol.BorderSizePixel = 0; RightCol.ScrollBarThickness = 2
        RightCol.ScrollBarImageColor3 = CurrentTheme.Accent
        local RightList = Instance.new("UIListLayout", RightCol); RightList.Padding = UDim.new(0, 10)

        local TabBtn = Instance.new("TextButton", TabScroll)
        TabBtn.Size = UDim2.new(0, 74, 0, 32)
        TabBtn.BackgroundTransparency = 1
        TabBtn.ZIndex = 2
        TabBtn.Text = tabName
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 12
        TabBtn.TextColor3 = CurrentTheme.TextSecondary
        TabBtn.AutoButtonColor = false

        local tabScaleObj = ApplyPressFeel(TabBtn, 1.0, Connections)

        local tabHoverConn = TabBtn.MouseEnter:Connect(function()
            if TabBtn.TextColor3 ~= CurrentTheme.Accent then
                Tween(TabBtn, {TextColor3 = CurrentTheme.TextPrimary}, 0.15)
            end
        end)
        local tabLeaveConn = TabBtn.MouseLeave:Connect(function()
            if TabBtn.TextColor3 ~= CurrentTheme.Accent then
                Tween(TabBtn, {TextColor3 = CurrentTheme.TextSecondary}, 0.15)
            end
        end)
        table.insert(Connections, tabHoverConn)
        table.insert(Connections, tabLeaveConn)

        local TabObject = {Page = Page, Left = LeftCol, Right = RightCol, Button = TabBtn}

        local btnConn = TabBtn.MouseButton1Click:Connect(function()
            if Page.Visible then return end
            for _, t in pairs(Window.Tabs) do
                if t.Page.Visible then
                    Tween(t.Page, {Position = UDim2.new(0, 0, 0, 6)}, 0.16, Enum.EasingStyle.Quint)
                    local otherFade = Tween(t.Button, {TextColor3 = CurrentTheme.TextSecondary}, 0.18)
                end
                t.Page.Visible = false
            end

            Page.Visible = true
            Page.Position = UDim2.new(0, 0, 0, 10)
            Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quint)
            Tween(TabBtn, {TextColor3 = CurrentTheme.Accent}, 0.2)
            MoveIndicatorTo(TabBtn)
            PlayStaggerIn(LeftCol)
            PlayStaggerIn(RightCol)
        end)
        table.insert(Connections, btnConn)

        if not Window.FirstTab then
            Window.FirstTab = TabObject
            Page.Visible = true
            TabBtn.TextColor3 = CurrentTheme.Accent
            task.defer(function() MoveIndicatorTo(TabBtn) end)
        end

        table.insert(Window.Tabs, TabObject)

        local Elements = {}

        ------------------------------------------------------------
        function Elements:AddLeftButton(text, iconId, callback)
            local Btn = Instance.new("TextButton", LeftCol)
            Btn.Size = UDim2.new(1, -6, 0, 44); Btn.BackgroundColor3 = CurrentTheme.CardBg; Btn.BorderSizePixel = 0; Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.ClipsDescendants = true
            Corner(Btn, 9)
            Stroke(Btn, CurrentTheme.Border, 1)
            Gradient(Btn, ColorSequence.new(CurrentTheme.CardBg, CurrentTheme.CardBg2), 90)
            ApplyAccentHover(Btn, Connections)
            ApplyPressFeel(Btn, 1.015, Connections)

            local hoverConn1 = Btn.MouseEnter:Connect(function()
                Tween(Btn, {BackgroundColor3 = CurrentTheme.CardItemBg}, 0.18)
            end)
            local hoverConn2 = Btn.MouseLeave:Connect(function()
                Tween(Btn, {BackgroundColor3 = CurrentTheme.CardBg}, 0.2)
            end)
            table.insert(Connections, hoverConn1)
            table.insert(Connections, hoverConn2)

            local ic = Instance.new("ImageLabel", Btn)
            ic.Image = iconId or "rbxassetid://6031094678"; ic.Size = UDim2.new(0, 18, 0, 18); ic.Position = UDim2.new(0, 16, 0.5, -9)
            ic.BackgroundTransparency = 1; ic.ImageColor3 = CurrentTheme.TextSecondary

            local lb = Instance.new("TextLabel", Btn)
            lb.Text = text; lb.Font = Enum.Font.GothamBold; lb.TextSize = 13; lb.TextColor3 = CurrentTheme.TextPrimary
            lb.Position = UDim2.new(0, 44, 0, 0); lb.Size = UDim2.new(1, -82, 1, 0); lb.BackgroundTransparency = 1; lb.TextXAlignment = Enum.TextXAlignment.Left

            local bConn = Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            table.insert(Connections, bConn)
        end

        ------------------------------------------------------------
        function Elements:AddCard(cardTitle)
            local Card = Instance.new("Frame", RightCol)
            Card.Size = UDim2.new(1, -6, 0, 40); Card.AutomaticSize = Enum.AutomaticSize.Y; Card.BackgroundColor3 = CurrentTheme.CardBg; Card.BorderSizePixel = 0
            Corner(Card, 9)
            Stroke(Card, CurrentTheme.Border, 1)
            Gradient(Card, ColorSequence.new(CurrentTheme.CardBg, CurrentTheme.CardBg2), 90)

            local AccentCap = Instance.new("Frame", Card)
            AccentCap.Size = UDim2.new(0, 3, 0, 16)
            AccentCap.Position = UDim2.new(0, 0, 0, 12)
            AccentCap.BackgroundColor3 = CurrentTheme.Accent
            AccentCap.BorderSizePixel = 0
            Corner(AccentCap, 2)
            Gradient(AccentCap, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 90)

            local t = Instance.new("TextLabel", Card)
            t.Text = cardTitle; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextColor3 = CurrentTheme.TextPrimary
            t.Position = UDim2.new(0, 16, 0, 8); t.Size = UDim2.new(1, -30, 0, 20); t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left

            local Container = Instance.new("Frame", Card)
            Container.Position = UDim2.new(0, 12, 0, 36); Container.Size = UDim2.new(1, -24, 0, 0); Container.AutomaticSize = Enum.AutomaticSize.Y; Container.BackgroundTransparency = 1
            local list = Instance.new("UIListLayout", Container); list.Padding = UDim.new(0, 10)
            local pad = Instance.new("UIPadding", Container); pad.PaddingBottom = UDim.new(0, 12)

            local CardControls = {}

            function CardControls:AddButton(text, callback)
                local Btn = Instance.new("TextButton", Container)
                Btn.Size = UDim2.new(1, 0, 0, 32); Btn.BackgroundColor3 = CurrentTheme.CardItemBg; Btn.BorderSizePixel = 0
                Btn.Text = text; Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12; Btn.TextColor3 = CurrentTheme.TextPrimary
                Btn.AutoButtonColor = false
                Corner(Btn, 7)
                ApplyPressFeel(Btn, 1.02, Connections)

                local hc1 = Btn.MouseEnter:Connect(function()
                    Tween(Btn, {BackgroundColor3 = CurrentTheme.CardItemBg2}, 0.15)
                end)
                local hc2 = Btn.MouseLeave:Connect(function()
                    Tween(Btn, {BackgroundColor3 = CurrentTheme.CardItemBg}, 0.18)
                end)
                table.insert(Connections, hc1)
                table.insert(Connections, hc2)

                local c = Btn.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
                table.insert(Connections, c)
            end

            function CardControls:AddToggle(name, default, callback)
                local state = default or false
                local Btn = Instance.new("TextButton", Container)
                Btn.Size = UDim2.new(1, 0, 0, 32); Btn.BackgroundTransparency = 1; Btn.Text = ""
                Btn.AutoButtonColor = false

                local lb = Instance.new("TextLabel", Btn)
                lb.Text = name; lb.Font = Enum.Font.GothamMedium; lb.TextSize = 13; lb.TextColor3 = CurrentTheme.TextPrimary
                lb.Size = UDim2.new(1, -60, 1, 0); lb.BackgroundTransparency = 1; lb.TextXAlignment = Enum.TextXAlignment.Left

                local Sw = Instance.new("Frame", Btn)
                Sw.Size = UDim2.new(0, 42, 0, 22); Sw.Position = UDim2.new(1, -42, 0.5, -11)
                Sw.BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SliderTrack; Sw.BorderSizePixel = 0
                Corner(Sw, 11)
                local SwStroke = Stroke(Sw, CurrentTheme.Accent, 1, state and 0.4 or 1)
                if state then
                    Gradient(Sw, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 0)
                end

                local Ind = Instance.new("Frame", Sw)
                Ind.Size = UDim2.new(0, 16, 0, 16); Ind.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                Ind.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Ind.BorderSizePixel = 0
                Corner(Ind, 8)

                local tConn = Btn.MouseButton1Click:Connect(function()
                    state = not state
                    local existingGradient = Sw:FindFirstChildOfClass("UIGradient")
                    if existingGradient then existingGradient:Destroy() end
                    if state then
                        Gradient(Sw, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 0)
                    end
                    Tween(Sw, {BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SliderTrack}, 0.22, Enum.EasingStyle.Quint)
                    Tween(SwStroke, {Transparency = state and 0.4 or 1}, 0.22)
                    Tween(Ind, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Size = UDim2.new(0, 18, 0, 18)}, 0.28, Enum.EasingStyle.Back)
                    task.delay(0.12, function()
                        if Ind and Ind.Parent then
                            Tween(Ind, {Size = UDim2.new(0, 16, 0, 16)}, 0.14, Enum.EasingStyle.Quad)
                        end
                    end)
                    Notify(name, state and "Enabled" or "Disabled", 1.5)
                    if callback then callback(state) end
                end)
                table.insert(Connections, tConn)

                local hc1 = Btn.MouseEnter:Connect(function()
                    Tween(lb, {TextColor3 = CurrentTheme.Accent}, 0.15)
                end)
                local hc2 = Btn.MouseLeave:Connect(function()
                    Tween(lb, {TextColor3 = CurrentTheme.TextPrimary}, 0.18)
                end)
                table.insert(Connections, hc1)
                table.insert(Connections, hc2)
            end

            function CardControls:AddSlider(name, min, max, default, step, callback)
                step = step or 0.1
                local cur = default or min
                local Box = Instance.new("Frame", Container)
                Box.Size = UDim2.new(1, 0, 0, 44); Box.BackgroundTransparency = 1

                local Title = Instance.new("TextLabel", Box)
                Title.Text = name; Title.Font = Enum.Font.GothamMedium; Title.TextSize = 12; Title.TextColor3 = CurrentTheme.TextSecondary
                Title.Size = UDim2.new(1, -60, 0, 16); Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

                local Val = Instance.new("TextLabel", Box)
                Val.Text = string.format("%.1f", cur); Val.Font = Enum.Font.GothamBold; Val.TextSize = 12; Val.TextColor3 = CurrentTheme.Accent
                Val.Position = UDim2.new(1, -60, 0, 0); Val.Size = UDim2.new(0, 60, 0, 16); Val.BackgroundTransparency = 1; Val.TextXAlignment = Enum.TextXAlignment.Right

                local Bar = Instance.new("TextButton", Box)
                Bar.Text = ""; Bar.AutoButtonColor = false; Bar.Size = UDim2.new(1, 0, 0, 6); Bar.Position = UDim2.new(0, 0, 0, 26)
                Bar.BackgroundColor3 = CurrentTheme.SliderTrack; Bar.BorderSizePixel = 0
                Corner(Bar, 3)

                local Fill = Instance.new("Frame", Bar)
                Fill.Size = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 1, 0)
                Fill.BackgroundColor3 = CurrentTheme.Accent; Fill.BorderSizePixel = 0
                Corner(Fill, 3)
                Gradient(Fill, ColorSequence.new(CurrentTheme.Accent, CurrentTheme.Accent2), 0)

                local Thumb = Instance.new("Frame", Bar)
                Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
                Thumb.Size = UDim2.new(0, 12, 0, 12)
                Thumb.Position = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 0.5, 0)
                Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Thumb.BorderSizePixel = 0
                Thumb.ZIndex = 3
                Corner(Thumb, 6)
                Stroke(Thumb, CurrentTheme.Accent, 1.5)

                local dragging = false
                local function update(inputX)
                    local rel = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local v = math.floor((min + (max - min) * rel) / step + 0.5) * step
                    cur = math.clamp(v, min, max)
                    Val.Text = string.format("%.1f", cur)
                    Tween(Fill, {Size = UDim2.new(rel, 0, 1, 0)}, 0.05, Enum.EasingStyle.Sine)
                    Tween(Thumb, {Position = UDim2.new(rel, 0, 0.5, 0)}, 0.05, Enum.EasingStyle.Sine)
                    if callback then callback(cur) end
                end

                local sBeg = Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Tween(Thumb, {Size = UDim2.new(0, 16, 0, 16)}, 0.12, Enum.EasingStyle.Back)
                        update(input.Position.X)
                    end
                end)

                local sEnd = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if dragging then
                            dragging = false
                            Tween(Thumb, {Size = UDim2.new(0, 12, 0, 12)}, 0.15, Enum.EasingStyle.Quad)
                            Notify(name, "Set to " .. string.format("%.1f", cur), 1.5)
                        end
                    end
                end)

                local sChg = UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input.Position.X)
                    end
                end)

                local hc1 = Bar.MouseEnter:Connect(function()
                    if not dragging then Tween(Thumb, {Size = UDim2.new(0, 14, 0, 14)}, 0.12) end
                end)
                local hc2 = Bar.MouseLeave:Connect(function()
                    if not dragging then Tween(Thumb, {Size = UDim2.new(0, 12, 0, 12)}, 0.12) end
                end)

                table.insert(Connections, sBeg)
                table.insert(Connections, sEnd)
                table.insert(Connections, sChg)
                table.insert(Connections, hc1)
                table.insert(Connections, hc2)
            end

            return CardControls
        end

        return Elements
    end

    return Window
end

return Zabota
