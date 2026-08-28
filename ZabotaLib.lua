local Zabota = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- Theme: dark "meta"-style cheat menu — near-black window bg,
-- lightly-tinted rounded card boxes for every section
----------------------------------------------------------------
local Themes = {
    Dark = {
        MainBg = Color3.fromRGB(10, 10, 12),
        TopBarBg = Color3.fromRGB(10, 10, 12),
        CardBg = Color3.fromRGB(23, 24, 28),
        SubBg = Color3.fromRGB(14, 15, 18),
        HeaderText = Color3.fromRGB(118, 122, 134),
        Divider = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(233, 55, 60),
        Accent2 = Color3.fromRGB(255, 120, 70),
        TextPrimary = Color3.fromRGB(225, 227, 234),
        TextSecondary = Color3.fromRGB(150, 154, 166),
        TextDisabled = Color3.fromRGB(74, 76, 84),
        CheckboxOff = Color3.fromRGB(70, 72, 80),
        SliderTrack = Color3.fromRGB(46, 48, 56),
        RowHover = Color3.fromRGB(255, 255, 255)
    }
}

local CurrentTheme = Themes.Dark
local GlobalTransparency = 0.05
local AnimSpeed = 0.3

----------------------------------------------------------------
-- Core helpers
----------------------------------------------------------------
local function Tween(instance, properties, duration, style, direction)
    local t = TweenService:Create(instance, TweenInfo.new(duration or AnimSpeed, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or CurrentTheme.Divider
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.9
    s.Parent = parent
    return s
end

local function Divider(parent, ySize)
    local d = Instance.new("Frame", parent)
    d.Size = UDim2.new(1, 0, 0, ySize or 1)
    d.BackgroundColor3 = CurrentTheme.Divider
    d.BackgroundTransparency = 0.93
    d.BorderSizePixel = 0
    return d
end

----------------------------------------------------------------
-- Hover / press micro-interactions
----------------------------------------------------------------
local function ApplyPressFeel(button, hoverScale, connsTable)
    hoverScale = hoverScale or 1.0
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local c3 = button.MouseButton1Down:Connect(function()
        Tween(scale, {Scale = 0.975}, 0.08, Enum.EasingStyle.Quad)
    end)
    local c4 = button.MouseButton1Up:Connect(function()
        Tween(scale, {Scale = 1}, 0.12, Enum.EasingStyle.Quad)
    end)

    if connsTable then
        table.insert(connsTable, c3)
        table.insert(connsTable, c4)
    end
    return scale
end

-- Subtle full-row background tint on hover
local function ApplyRowHover(row, connsTable, targetTransparency)
    targetTransparency = targetTransparency or 0.94
    row.BackgroundColor3 = CurrentTheme.RowHover
    row.BackgroundTransparency = 1
    local c1 = row.MouseEnter:Connect(function()
        Tween(row, {BackgroundTransparency = targetTransparency}, 0.15)
    end)
    local c2 = row.MouseLeave:Connect(function()
        Tween(row, {BackgroundTransparency = 1}, 0.2)
    end)
    if connsTable then
        table.insert(connsTable, c1)
        table.insert(connsTable, c2)
    end
end

----------------------------------------------------------------
-- Staggered fly-in for lists
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
        item.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 10, originalPos.Y.Scale, originalPos.Y.Offset)
        task.delay((i - 1) * 0.04, function()
            if item and item.Parent then
                Tween(item, {Position = originalPos}, 0.26, Enum.EasingStyle.Quint)
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
-- Card header: [icon] Title ............... [arrow]
----------------------------------------------------------------
local function BuildCardHeader(parent, title, icon, arrowGlyph, arrowCallback, connsTable)
    local HeaderRow = Instance.new("Frame", parent)
    HeaderRow.Name = "Header"
    HeaderRow.Size = UDim2.new(1, 0, 0, 20)
    HeaderRow.BackgroundTransparency = 1
    HeaderRow.LayoutOrder = 1

    local xOffset = 0
    if icon then
        local IconLbl = Instance.new("TextLabel", HeaderRow)
        IconLbl.Text = icon
        IconLbl.Font = Enum.Font.GothamBold
        IconLbl.TextSize = 14
        IconLbl.TextColor3 = CurrentTheme.TextSecondary
        IconLbl.BackgroundTransparency = 1
        IconLbl.Position = UDim2.new(0, 0, 0, 0)
        IconLbl.Size = UDim2.new(0, 20, 1, 0)
        IconLbl.TextXAlignment = Enum.TextXAlignment.Left
        xOffset = 22
    end

    local TitleLbl = Instance.new("TextLabel", HeaderRow)
    TitleLbl.Text = title
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13
    TitleLbl.TextColor3 = CurrentTheme.TextPrimary
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, xOffset, 0, 0)
    TitleLbl.Size = UDim2.new(1, -xOffset - 26, 1, 0)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    if arrowGlyph then
        if arrowCallback then
            local ArrowBtn = Instance.new("TextButton", HeaderRow)
            ArrowBtn.Text = arrowGlyph
            ArrowBtn.Font = Enum.Font.GothamBold
            ArrowBtn.TextSize = 13
            ArrowBtn.TextColor3 = CurrentTheme.TextDisabled
            ArrowBtn.BackgroundTransparency = 1
            ArrowBtn.AutoButtonColor = false
            ArrowBtn.AnchorPoint = Vector2.new(1, 0)
            ArrowBtn.Position = UDim2.new(1, 0, 0, 0)
            ArrowBtn.Size = UDim2.new(0, 20, 1, 0)
            ArrowBtn.TextXAlignment = Enum.TextXAlignment.Right

            local c1 = ArrowBtn.MouseEnter:Connect(function()
                Tween(ArrowBtn, {TextColor3 = CurrentTheme.TextPrimary}, 0.14)
            end)
            local c2 = ArrowBtn.MouseLeave:Connect(function()
                Tween(ArrowBtn, {TextColor3 = CurrentTheme.TextDisabled}, 0.16)
            end)
            local c3 = ArrowBtn.MouseButton1Click:Connect(arrowCallback)
            if connsTable then
                table.insert(connsTable, c1)
                table.insert(connsTable, c2)
                table.insert(connsTable, c3)
            end
        else
            local ArrowLbl = Instance.new("TextLabel", HeaderRow)
            ArrowLbl.Text = arrowGlyph
            ArrowLbl.Font = Enum.Font.GothamBold
            ArrowLbl.TextSize = 13
            ArrowLbl.TextColor3 = CurrentTheme.TextDisabled
            ArrowLbl.BackgroundTransparency = 1
            ArrowLbl.AnchorPoint = Vector2.new(1, 0)
            ArrowLbl.Position = UDim2.new(1, 0, 0, 0)
            ArrowLbl.Size = UDim2.new(0, 20, 1, 0)
            ArrowLbl.TextXAlignment = Enum.TextXAlignment.Right
        end
    end

    return HeaderRow
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
function Zabota:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "ZABOTA"
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local VersionText = config.Version or "v1.0"
    local Connections = {}

    if PlayerGui:FindFirstChild("ZabotaUI_Screen") then
        PlayerGui.ZabotaUI_Screen:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZabotaUI_Screen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    -- Subtle background blur while menu is open
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
    ToastContainer.Size = UDim2.new(0, 260, 1, -20)
    ToastContainer.Position = UDim2.new(1, -275, 0, 10)
    ToastContainer.BackgroundTransparency = 1
    ToastContainer.Parent = ScreenGui

    local ToastLayout = Instance.new("UIListLayout")
    ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ToastLayout.Padding = UDim.new(0, 6)
    ToastLayout.Parent = ToastContainer

    local function Notify(title, desc, duration)
        if not ScreenGui or not ScreenGui.Parent then return end
        duration = duration or 3

        local Toast = Instance.new("Frame")
        Toast.Size = UDim2.new(1, 40, 0, 0)
        Toast.Position = UDim2.new(0, 40, 0, 0)
        Toast.BackgroundColor3 = CurrentTheme.CardBg
        Toast.BackgroundTransparency = 1
        Toast.ClipsDescendants = true
        Toast.Parent = ToastContainer
        Corner(Toast, 8)

        local Bar = Instance.new("Frame", Toast)
        Bar.Size = UDim2.new(0, 3, 1, 0)
        Bar.BackgroundColor3 = CurrentTheme.Accent
        Bar.BorderSizePixel = 0

        local t = Instance.new("TextLabel", Toast)
        t.Text = title:upper(); t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextColor3 = CurrentTheme.TextPrimary
        t.Position = UDim2.new(0, 14, 0, 8); t.Size = UDim2.new(1, -24, 0, 16); t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left

        local d = Instance.new("TextLabel", Toast)
        d.Text = desc; d.Font = Enum.Font.Gotham; d.TextSize = 11; d.TextColor3 = CurrentTheme.TextSecondary
        d.Position = UDim2.new(0, 14, 0, 26); d.Size = UDim2.new(1, -24, 0, 20); d.BackgroundTransparency = 1; d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextWrapped = true

        local ProgressTrack = Instance.new("Frame", Toast)
        ProgressTrack.Size = UDim2.new(1, -12, 0, 2)
        ProgressTrack.Position = UDim2.new(0, 6, 1, -5)
        ProgressTrack.BackgroundColor3 = CurrentTheme.SliderTrack
        ProgressTrack.BorderSizePixel = 0
        Corner(ProgressTrack, 1)

        local ProgressFill = Instance.new("Frame", ProgressTrack)
        ProgressFill.Size = UDim2.new(1, 0, 1, 0)
        ProgressFill.BackgroundColor3 = CurrentTheme.Accent
        ProgressFill.BorderSizePixel = 0
        Corner(ProgressFill, 1)

        Tween(Toast, {Size = UDim2.new(1, 0, 0, 52), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = GlobalTransparency}, 0.35, Enum.EasingStyle.Quint)
        Tween(ProgressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

        task.delay(duration, function()
            if Toast and Toast.Parent then
                local fade = Tween(Toast, {Size = UDim2.new(1, 40, 0, 0), Position = UDim2.new(0, 40, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
                fade.Completed:Connect(function() if Toast then Toast:Destroy() end end)
            end
        end)
    end

    ----------------------------------------------------------------
    -- Main frame
    ----------------------------------------------------------------
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Size = UDim2.new(0, 720, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -360, 0.5, -230)
    MainFrame.BackgroundColor3 = CurrentTheme.MainBg
    MainFrame.BorderSizePixel = 0
    MainFrame.GroupTransparency = 1
    MainFrame.Parent = ScreenGui

    Corner(MainFrame, 8)
    Stroke(MainFrame, CurrentTheme.Divider, 1, 0.9)

    MakeDraggable(MainFrame, nil, Connections)

    local VersionLabel = Instance.new("TextLabel", MainFrame)
    VersionLabel.Text = VersionText
    VersionLabel.Font = Enum.Font.GothamBold
    VersionLabel.TextSize = 11
    VersionLabel.TextColor3 = CurrentTheme.Accent
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Position = UDim2.new(1, -60, 1, -22)
    VersionLabel.Size = UDim2.new(0, 50, 0, 16)
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
    VersionLabel.ZIndex = 5

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0, 46)
    TopBar.BackgroundColor3 = CurrentTheme.TopBarBg
    TopBar.BorderSizePixel = 0

    Divider(TopBar, 1).Position = UDim2.new(0, 0, 1, -1)

    local Logo = Instance.new("TextLabel", TopBar)
    Logo.Text = TitleText
    Logo.Font = Enum.Font.GothamBlack
    Logo.TextSize = 16
    Logo.TextColor3 = CurrentTheme.TextPrimary
    Logo.Position = UDim2.new(0, 20, 0, 0)
    Logo.Size = UDim2.new(0, 130, 1, 0)
    Logo.BackgroundTransparency = 1
    Logo.TextXAlignment = Enum.TextXAlignment.Left

    local TabScroll = Instance.new("ScrollingFrame", TopBar)
    TabScroll.Size = UDim2.new(1, -170, 1, 0)
    TabScroll.Position = UDim2.new(0, 150, 0, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel = 0
    TabScroll.ScrollBarThickness = 0
    TabScroll.CanvasSize = UDim2.new(0, 800, 0, 0)

    -- Thin sliding underline beneath the active tab
    local TabIndicator = Instance.new("Frame", TabScroll)
    TabIndicator.Name = "TabIndicator"
    TabIndicator.BackgroundColor3 = CurrentTheme.Accent
    TabIndicator.BorderSizePixel = 0
    TabIndicator.ZIndex = 1
    TabIndicator.AnchorPoint = Vector2.new(0, 0)
    TabIndicator.Size = UDim2.new(0, 0, 0, 2)
    TabIndicator.Position = UDim2.new(0, 0, 1, -2)
    Corner(TabIndicator, 1)

    local TabListLayout = Instance.new("UIListLayout", TabScroll)
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabListLayout.Padding = UDim.new(0, 18)

    local function MoveIndicatorTo(tabBtn)
        task.spawn(function()
            RunService.Heartbeat:Wait()
            local relX = tabBtn.AbsolutePosition.X - TabScroll.AbsolutePosition.X + TabScroll.CanvasPosition.X
            Tween(TabIndicator, {
                Position = UDim2.new(0, relX, 1, -2),
                Size = UDim2.new(0, tabBtn.AbsoluteSize.X, 0, 2)
            }, 0.28, Enum.EasingStyle.Quint)
        end)
    end

    local PagesContainer = Instance.new("Frame", MainFrame)
    PagesContainer.Position = UDim2.new(0, 0, 0, 46)
    PagesContainer.Size = UDim2.new(1, 0, 1, -46)
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
            MainFrame.Size = UDim2.new(0, 695, 0, 445)
            Tween(MainFrame, {Size = UDim2.new(0, 720, 0, 460), GroupTransparency = 0}, 0.35, Enum.EasingStyle.Quint)
            Tween(Blur, {Size = 12}, 0.3, Enum.EasingStyle.Quint)
        else
            Tween(MainFrame, {Size = UDim2.new(0, 695, 0, 445), GroupTransparency = 1}, AnimSpeed * 0.85, Enum.EasingStyle.Quint)
            Tween(Blur, {Size = 0}, 0.25, Enum.EasingStyle.Quint)
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
        HUD.Size = UDim2.new(0, 190, 0, 34)
        HUD.AutomaticSize = Enum.AutomaticSize.Y
        HUD.Position = UDim2.new(0, 25, 0.5, -70)
        HUD.BackgroundColor3 = CurrentTheme.CardBg
        HUD.BackgroundTransparency = 1
        HUD.BorderSizePixel = 0

        Corner(HUD, 8)
        MakeDraggable(HUD, nil, Connections)

        Tween(HUD, {BackgroundTransparency = 0}, 0.3)

        local topBarAccent = Instance.new("Frame", HUD)
        topBarAccent.Size = UDim2.new(1, 0, 0, 2)
        topBarAccent.BackgroundColor3 = CurrentTheme.Accent
        topBarAccent.BorderSizePixel = 0

        local hTitle = Instance.new("TextLabel", HUD)
        hTitle.Text = (hudTitle or "KEYBINDS"):upper()
        hTitle.Font = Enum.Font.GothamBold
        hTitle.TextSize = 11
        hTitle.TextColor3 = CurrentTheme.HeaderText
        hTitle.Position = UDim2.new(0, 12, 0, 6)
        hTitle.Size = UDim2.new(1, -24, 0, 20)
        hTitle.BackgroundTransparency = 1
        hTitle.TextXAlignment = Enum.TextXAlignment.Left

        local hContainer = Instance.new("Frame", HUD)
        hContainer.Position = UDim2.new(0, 12, 0, 30)
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
    -- Checkbox row renderer — shared by AddToggle and AddCheckbox
    ----------------------------------------------------------------
    local function CreateCheckRow(container, text, default, callback, opts)
        opts = opts or {}
        local disabled = opts.disabled or false
        local colors = opts.colors
        local tag = opts.tag

        local state = (not disabled) and (default or false) or false

        local Row = Instance.new("TextButton", container)
        Row.Size = UDim2.new(1, 0, 0, 24)
        Row.BackgroundTransparency = 1
        Row.Text = ""
        Row.AutoButtonColor = false
        Row.Selectable = not disabled
        Corner(Row, 5)

        if not disabled then
            ApplyRowHover(Row, Connections)
        end

        local Box = Instance.new("Frame", Row)
        Box.Size = UDim2.new(0, 15, 0, 15)
        Box.Position = UDim2.new(0, 0, 0.5, -7)
        Box.BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SubBg
        Box.BackgroundTransparency = 0
        Box.BorderSizePixel = 0
        Corner(Box, 3)
        local BoxStroke = Stroke(Box, disabled and CurrentTheme.TextDisabled or (state and CurrentTheme.Accent or CurrentTheme.CheckboxOff), 1.2, disabled and 0.5 or 0)

        local Check = Instance.new("TextLabel", Box)
        Check.Text = "✓"
        Check.Font = Enum.Font.GothamBold
        Check.TextSize = 11
        Check.TextColor3 = Color3.fromRGB(255, 255, 255)
        Check.BackgroundTransparency = 1
        Check.Size = UDim2.new(1, 0, 1, 0)
        Check.TextTransparency = state and 0 or 1
        local CheckScale = Instance.new("UIScale", Check)
        CheckScale.Scale = state and 1 or 0.4

        local Label = Instance.new("TextLabel", Row)
        Label.Text = text
        Label.Font = Enum.Font.GothamMedium
        Label.TextSize = 13
        Label.TextColor3 = disabled and CurrentTheme.TextDisabled or CurrentTheme.TextPrimary
        Label.Position = UDim2.new(0, 25, 0, 0)
        Label.Size = UDim2.new(1, -140, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left

        if tag then
            local TagLbl = Instance.new("TextLabel", Row)
            TagLbl.Text = "↗"
            TagLbl.Font = Enum.Font.GothamBold
            TagLbl.TextSize = 11
            TagLbl.TextColor3 = CurrentTheme.TextDisabled
            TagLbl.BackgroundTransparency = 1
            TagLbl.Position = UDim2.new(0, 25 + Label.TextBounds.X + 4, 0, 0)
            TagLbl.Size = UDim2.new(0, 16, 1, 0)
            TagLbl.TextXAlignment = Enum.TextXAlignment.Left
        end

        local swatchRefs = {}
        if colors and #colors > 0 then
            local swW, swH, gap = 26, 13, 4
            local totalW = (#colors * swW) + ((#colors - 1) * gap)
            local startX = -totalW
            for i, col in ipairs(colors) do
                local Sw = Instance.new("Frame", Row)
                Sw.Size = UDim2.new(0, swW, 0, swH)
                Sw.Position = UDim2.new(1, startX + (i - 1) * (swW + gap), 0.5, -swH / 2)
                Sw.BackgroundColor3 = col
                Sw.BackgroundTransparency = disabled and 0.7 or 0
                Sw.BorderSizePixel = 0
                Corner(Sw, 3)
                table.insert(swatchRefs, Sw)
            end
        end

        local function refresh(animated)
            local dur = animated and 0.18 or 0
            if state then
                Tween(Box, {BackgroundColor3 = CurrentTheme.Accent}, dur)
                Tween(BoxStroke, {Color = CurrentTheme.Accent, Transparency = 0}, dur)
                Tween(Check, {TextTransparency = 0}, dur)
                Tween(CheckScale, {Scale = 1}, animated and 0.22 or 0, Enum.EasingStyle.Back)
            else
                Tween(Box, {BackgroundColor3 = CurrentTheme.SubBg}, dur)
                Tween(BoxStroke, {Color = CurrentTheme.CheckboxOff, Transparency = 0}, dur)
                Tween(Check, {TextTransparency = 1}, dur)
                Tween(CheckScale, {Scale = 0.4}, dur)
            end
        end

        if not disabled then
            local conn = Row.MouseButton1Click:Connect(function()
                state = not state
                refresh(true)
                Notify(text, state and "Enabled" or "Disabled", 1.4)
                if callback then callback(state) end
            end)
            table.insert(Connections, conn)
            ApplyPressFeel(Row, 1, Connections)
        end

        return {
            Row = Row,
            SetState = function(_, v)
                state = v and true or false
                refresh(true)
            end,
            GetState = function() return state end
        }
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
        LeftCol.Position = UDim2.new(0, 16, 0, 14); LeftCol.Size = UDim2.new(0, 320, 1, -28)
        LeftCol.BackgroundTransparency = 1; LeftCol.BorderSizePixel = 0; LeftCol.ScrollBarThickness = 2
        LeftCol.ScrollBarImageColor3 = CurrentTheme.Accent
        LeftCol.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        LeftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        local leftList = Instance.new("UIListLayout", LeftCol); leftList.Padding = UDim.new(0, 12)

        local RightCol = Instance.new("ScrollingFrame", Page)
        RightCol.Position = UDim2.new(0, 350, 0, 14); RightCol.Size = UDim2.new(1, -366, 1, -28)
        RightCol.BackgroundTransparency = 1; RightCol.BorderSizePixel = 0; RightCol.ScrollBarThickness = 2
        RightCol.ScrollBarImageColor3 = CurrentTheme.Accent
        RightCol.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        RightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
        local rightList = Instance.new("UIListLayout", RightCol); rightList.Padding = UDim.new(0, 12)

        local TabBtn = Instance.new("TextButton", TabScroll)
        TabBtn.Size = UDim2.new(0, 0, 0, 46)
        TabBtn.AutomaticSize = Enum.AutomaticSize.X
        TabBtn.BackgroundTransparency = 1
        TabBtn.ZIndex = 2
        TabBtn.Text = tabName
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 13
        TabBtn.TextColor3 = CurrentTheme.TextSecondary
        TabBtn.AutoButtonColor = false

        ApplyPressFeel(TabBtn, 1, Connections)

        local tabHoverConn = TabBtn.MouseEnter:Connect(function()
            if TabBtn.TextColor3 ~= CurrentTheme.Accent then
                Tween(TabBtn, {TextColor3 = CurrentTheme.TextPrimary}, 0.14)
            end
        end)
        local tabLeaveConn = TabBtn.MouseLeave:Connect(function()
            if TabBtn.TextColor3 ~= CurrentTheme.Accent then
                Tween(TabBtn, {TextColor3 = CurrentTheme.TextSecondary}, 0.16)
            end
        end)
        table.insert(Connections, tabHoverConn)
        table.insert(Connections, tabLeaveConn)

        local TabObject = {Page = Page, Left = LeftCol, Right = RightCol, Button = TabBtn}

        local btnConn = TabBtn.MouseButton1Click:Connect(function()
            if Page.Visible then return end
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, {TextColor3 = CurrentTheme.TextSecondary}, 0.16)
            end

            Page.Visible = true
            Page.Position = UDim2.new(0, 0, 0, 8)
            Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quint)
            Tween(TabBtn, {TextColor3 = CurrentTheme.Accent}, 0.18)
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
        -- Flat nav-row button (icon + text) — kept for back-compat
        ------------------------------------------------------------
        function Elements:AddLeftButton(text, iconId, callback)
            local Btn = Instance.new("TextButton", LeftCol)
            Btn.Size = UDim2.new(1, 0, 0, 34); Btn.BackgroundTransparency = 1; Btn.Text = ""
            Btn.AutoButtonColor = false
            Corner(Btn, 5)
            ApplyRowHover(Btn, Connections)
            ApplyPressFeel(Btn, 1, Connections)

            local ic = Instance.new("ImageLabel", Btn)
            ic.Image = iconId or "rbxassetid://6031094678"; ic.Size = UDim2.new(0, 16, 0, 16); ic.Position = UDim2.new(0, 4, 0.5, -8)
            ic.BackgroundTransparency = 1; ic.ImageColor3 = CurrentTheme.TextSecondary

            local lb = Instance.new("TextLabel", Btn)
            lb.Text = text; lb.Font = Enum.Font.GothamMedium; lb.TextSize = 13; lb.TextColor3 = CurrentTheme.TextPrimary
            lb.Position = UDim2.new(0, 30, 0, 0); lb.Size = UDim2.new(1, -40, 1, 0); lb.BackgroundTransparency = 1; lb.TextXAlignment = Enum.TextXAlignment.Left

            local bConn = Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            table.insert(Connections, bConn)
        end

        ------------------------------------------------------------
        -- Boxed card: icon + title + arrow header, rounded card bg
        -- opts = { icon = "🎯", arrow = true|false|"glyph", onArrow = fn, side = "left"|"right" }
        ------------------------------------------------------------
        function Elements:AddCard(cardTitle, opts)
            opts = opts or {}
            local targetCol = (opts.side == "left") and LeftCol or RightCol

            local Card = Instance.new("Frame", targetCol)
            Card.Size = UDim2.new(1, 0, 0, 10)
            Card.AutomaticSize = Enum.AutomaticSize.Y
            Card.BackgroundColor3 = CurrentTheme.CardBg
            Card.BorderSizePixel = 0
            Corner(Card, 10)

            local CardLayout = Instance.new("UIListLayout", Card)
            CardLayout.Padding = UDim.new(0, 10)

            local CardPad = Instance.new("UIPadding", Card)
            CardPad.PaddingLeft = UDim.new(0, 14)
            CardPad.PaddingRight = UDim.new(0, 14)
            CardPad.PaddingTop = UDim.new(0, 12)
            CardPad.PaddingBottom = UDim.new(0, 12)

            local arrowGlyph
            if opts.arrow == nil or opts.arrow == true then
                arrowGlyph = "→"
            elseif type(opts.arrow) == "string" then
                arrowGlyph = opts.arrow
            end

            BuildCardHeader(Card, cardTitle, opts.icon, arrowGlyph, opts.onArrow, Connections)

            local Container = Instance.new("Frame", Card)
            Container.Name = "Body"
            Container.LayoutOrder = 2
            Container.Size = UDim2.new(1, 0, 0, 0)
            Container.AutomaticSize = Enum.AutomaticSize.Y
            Container.BackgroundTransparency = 1
            local list = Instance.new("UIListLayout", Container); list.Padding = UDim.new(0, 10)

            local CardControls = {}

            function CardControls:AddButton(text, callback)
                local Btn = Instance.new("TextButton", Container)
                Btn.Size = UDim2.new(1, 0, 0, 30); Btn.BackgroundColor3 = CurrentTheme.SubBg; Btn.BorderSizePixel = 0
                Btn.Text = ""
                Btn.AutoButtonColor = false
                Corner(Btn, 6)
                ApplyPressFeel(Btn, 1, Connections)

                local lb = Instance.new("TextLabel", Btn)
                lb.Text = text; lb.Font = Enum.Font.GothamBold; lb.TextSize = 12; lb.TextColor3 = CurrentTheme.TextPrimary
                lb.Size = UDim2.new(1, -16, 1, 0); lb.Position = UDim2.new(0, 12, 0, 0)
                lb.BackgroundTransparency = 1; lb.TextXAlignment = Enum.TextXAlignment.Left

                local hc1 = Btn.MouseEnter:Connect(function()
                    Tween(lb, {TextColor3 = CurrentTheme.Accent}, 0.14)
                end)
                local hc2 = Btn.MouseLeave:Connect(function()
                    Tween(lb, {TextColor3 = CurrentTheme.TextPrimary}, 0.16)
                end)
                table.insert(Connections, hc1)
                table.insert(Connections, hc2)

                local c = Btn.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
                table.insert(Connections, c)
            end

            -- Legacy switch-style toggle now rendered as a flat checkbox row
            function CardControls:AddToggle(name, default, callback)
                return CreateCheckRow(Container, name, default, callback, nil)
            end

            -- Full-featured checkbox row (disabled state, color swatches, tag icon)
            -- opts = { disabled = bool, colors = {Color3, ...}, tag = bool }
            function CardControls:AddCheckbox(name, default, callback, checkOpts)
                return CreateCheckRow(Container, name, default, callback, checkOpts)
            end

            function CardControls:AddSlider(name, min, max, default, step, callback, sliderOpts)
                sliderOpts = sliderOpts or {}
                local disabled = sliderOpts.disabled or false
                step = step or 0.1
                local cur = disabled and (sliderOpts.displayValue or 0) or (default or min)

                local Box = Instance.new("Frame", Container)
                Box.Size = UDim2.new(1, 0, 0, disabled and 18 or 34); Box.BackgroundTransparency = 1

                local Title = Instance.new("TextLabel", Box)
                Title.Text = name; Title.Font = Enum.Font.GothamMedium; Title.TextSize = 12
                Title.TextColor3 = disabled and CurrentTheme.TextDisabled or CurrentTheme.TextSecondary
                Title.Size = UDim2.new(1, -60, 0, 16); Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

                local Val = Instance.new("TextLabel", Box)
                Val.Text = (step >= 1) and tostring(math.floor(cur)) or string.format("%.1f", cur)
                Val.Font = Enum.Font.GothamBold; Val.TextSize = 12
                Val.TextColor3 = disabled and CurrentTheme.TextDisabled or CurrentTheme.Accent
                Val.Position = UDim2.new(1, -60, 0, 0); Val.Size = UDim2.new(0, 60, 0, 16); Val.BackgroundTransparency = 1; Val.TextXAlignment = Enum.TextXAlignment.Right

                if disabled then
                    return {
                        SetValue = function(_, v)
                            cur = v
                            Val.Text = (step >= 1) and tostring(math.floor(cur)) or string.format("%.1f", cur)
                        end
                    }
                end

                local Bar = Instance.new("TextButton", Box)
                Bar.Text = ""; Bar.AutoButtonColor = false; Bar.BackgroundTransparency = 1
                Bar.Size = UDim2.new(1, 0, 0, 14); Bar.Position = UDim2.new(0, 0, 0, 20)

                local Track = Instance.new("Frame", Bar)
                Track.Size = UDim2.new(1, 0, 0, 3)
                Track.Position = UDim2.new(0, 0, 0.5, -1)
                Track.BackgroundColor3 = CurrentTheme.SliderTrack
                Track.BorderSizePixel = 0
                Corner(Track, 2)

                local Fill = Instance.new("Frame", Track)
                Fill.Size = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 1, 0)
                Fill.BackgroundColor3 = CurrentTheme.Accent; Fill.BorderSizePixel = 0
                Corner(Fill, 2)

                local Thumb = Instance.new("Frame", Track)
                Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
                Thumb.Size = UDim2.new(0, 0, 0, 0)
                Thumb.Position = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 0.5, 0)
                Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Thumb.BorderSizePixel = 0
                Thumb.ZIndex = 3
                Corner(Thumb, 5)

                local dragging = false
                local function update(inputX)
                    local rel = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local v = math.floor((min + (max - min) * rel) / step + 0.5) * step
                    cur = math.clamp(v, min, max)
                    Val.Text = (step >= 1) and tostring(math.floor(cur)) or string.format("%.1f", cur)
                    Tween(Fill, {Size = UDim2.new(rel, 0, 1, 0)}, 0.05, Enum.EasingStyle.Sine)
                    Tween(Thumb, {Position = UDim2.new(rel, 0, 0.5, 0)}, 0.05, Enum.EasingStyle.Sine)
                    if callback then callback(cur) end
                end

                local sBeg = Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Tween(Thumb, {Size = UDim2.new(0, 10, 0, 10)}, 0.1)
                        update(input.Position.X)
                    end
                end)

                local sEnd = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if dragging then
                            dragging = false
                            Tween(Thumb, {Size = UDim2.new(0, 0, 0, 0)}, 0.12)
                            Notify(name, "Set to " .. Val.Text, 1.4)
                        end
                    end
                end)

                local sChg = UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input.Position.X)
                    end
                end)

                local hc1 = Bar.MouseEnter:Connect(function()
                    if not dragging then Tween(Thumb, {Size = UDim2.new(0, 8, 0, 8)}, 0.12) end
                end)
                local hc2 = Bar.MouseLeave:Connect(function()
                    if not dragging then Tween(Thumb, {Size = UDim2.new(0, 0, 0, 0)}, 0.12) end
                end)

                table.insert(Connections, sBeg)
                table.insert(Connections, sEnd)
                table.insert(Connections, sChg)
                table.insert(Connections, hc1)
                table.insert(Connections, hc2)

                return {
                    SetValue = function(_, v)
                        cur = math.clamp(v, min, max)
                        local rel = (cur - min) / (max - min)
                        Val.Text = (step >= 1) and tostring(math.floor(cur)) or string.format("%.1f", cur)
                        Tween(Fill, {Size = UDim2.new(rel, 0, 1, 0)}, 0.1)
                        Tween(Thumb, {Position = UDim2.new(rel, 0, 0.5, 0)}, 0.1)
                    end
                }
            end

            -- Weapon list block: "Weapons" header + inline checkbox on the
            -- right ("Automatic selection"), followed by a scrollable list
            function CardControls:AddWeaponList(listTitle, weapons, defaultAuto, callback)
                weapons = weapons or {}

                local HeaderRow = Instance.new("Frame", Container)
                HeaderRow.Size = UDim2.new(1, 0, 0, 20)
                HeaderRow.BackgroundTransparency = 1

                local TitleLbl = Instance.new("TextLabel", HeaderRow)
                TitleLbl.Text = listTitle or "Weapons"
                TitleLbl.Font = Enum.Font.GothamMedium
                TitleLbl.TextSize = 13
                TitleLbl.TextColor3 = CurrentTheme.TextPrimary
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Size = UDim2.new(0, 120, 1, 0)
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

                local state = defaultAuto or false
                local InlineWrap = Instance.new("TextButton", HeaderRow)
                InlineWrap.Text = ""
                InlineWrap.AutoButtonColor = false
                InlineWrap.AnchorPoint = Vector2.new(1, 0.5)
                InlineWrap.Position = UDim2.new(1, 0, 0.5, 0)
                InlineWrap.Size = UDim2.new(0, 0, 0, 18)
                InlineWrap.AutomaticSize = Enum.AutomaticSize.X
                InlineWrap.BackgroundTransparency = 1

                local wrapList = Instance.new("UIListLayout", InlineWrap)
                wrapList.FillDirection = Enum.FillDirection.Horizontal
                wrapList.VerticalAlignment = Enum.VerticalAlignment.Center
                wrapList.Padding = UDim.new(0, 6)

                local Box = Instance.new("Frame", InlineWrap)
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SubBg
                Box.BorderSizePixel = 0
                Corner(Box, 3)
                local BoxStroke = Stroke(Box, state and CurrentTheme.Accent or CurrentTheme.CheckboxOff, 1.2, 0)

                local Check = Instance.new("TextLabel", Box)
                Check.Text = "✓"; Check.Font = Enum.Font.GothamBold; Check.TextSize = 11
                Check.TextColor3 = Color3.fromRGB(255, 255, 255); Check.BackgroundTransparency = 1
                Check.Size = UDim2.new(1, 0, 1, 0); Check.TextTransparency = state and 0 or 1

                local InlineLbl = Instance.new("TextLabel", InlineWrap)
                InlineLbl.Text = "Automatic selection"
                InlineLbl.Font = Enum.Font.GothamMedium
                InlineLbl.TextSize = 12
                InlineLbl.TextColor3 = CurrentTheme.TextSecondary
                InlineLbl.BackgroundTransparency = 1
                InlineLbl.Size = UDim2.new(0, 130, 1, 0)
                InlineLbl.TextXAlignment = Enum.TextXAlignment.Left

                local wConn = InlineWrap.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(Box, {BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SubBg}, 0.16)
                    Tween(BoxStroke, {Color = state and CurrentTheme.Accent or CurrentTheme.CheckboxOff}, 0.16)
                    Tween(Check, {TextTransparency = state and 0 or 1}, 0.16)
                    if callback then callback(state) end
                end)
                table.insert(Connections, wConn)
                ApplyPressFeel(InlineWrap, 1, Connections)

                local ListBox = Instance.new("Frame", Container)
                ListBox.Size = UDim2.new(1, 0, 0, 108)
                ListBox.BackgroundColor3 = CurrentTheme.SubBg
                ListBox.BorderSizePixel = 0
                Corner(ListBox, 6)

                local Scroll = Instance.new("ScrollingFrame", ListBox)
                Scroll.Size = UDim2.new(1, -16, 1, -12)
                Scroll.Position = UDim2.new(0, 8, 0, 6)
                Scroll.BackgroundTransparency = 1
                Scroll.BorderSizePixel = 0
                Scroll.ScrollBarThickness = 2
                Scroll.ScrollBarImageColor3 = CurrentTheme.Accent
                Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                Scroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y

                local listLayout = Instance.new("UIListLayout", Scroll)
                listLayout.Padding = UDim.new(0, 4)

                local weaponLabels = {}
                for _, wname in ipairs(weapons) do
                    local Item = Instance.new("TextLabel", Scroll)
                    Item.Text = wname
                    Item.Font = Enum.Font.Gotham
                    Item.TextSize = 12
                    Item.TextColor3 = CurrentTheme.TextSecondary
                    Item.BackgroundTransparency = 1
                    Item.Size = UDim2.new(1, 0, 0, 16)
                    Item.TextXAlignment = Enum.TextXAlignment.Left
                    table.insert(weaponLabels, Item)
                end

                return {
                    SetAuto = function(_, v)
                        state = v and true or false
                        Tween(Box, {BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SubBg}, 0.16)
                        Tween(BoxStroke, {Color = state and CurrentTheme.Accent or CurrentTheme.CheckboxOff}, 0.16)
                        Tween(Check, {TextTransparency = state and 0 or 1}, 0.16)
                    end,
                    GetAuto = function() return state end
                }
            end

            return CardControls
        end

        ------------------------------------------------------------
        -- ESP-style live preview panel (box/skeleton/name/health)
        -- Rendered as a boxed card too, consistent with AddCard
        ------------------------------------------------------------
        function Elements:AddPreviewPanel(title, opts)
            opts = opts or {}
            local targetCol = (opts.side == "right") and RightCol or LeftCol

            local Panel = Instance.new("Frame", targetCol)
            Panel.Size = UDim2.new(1, 0, 0, 270)
            Panel.BackgroundColor3 = CurrentTheme.CardBg
            Panel.BorderSizePixel = 0
            Corner(Panel, 10)

            local PanelPad = Instance.new("UIPadding", Panel)
            PanelPad.PaddingLeft = UDim.new(0, 14)
            PanelPad.PaddingRight = UDim.new(0, 14)
            PanelPad.PaddingTop = UDim.new(0, 12)
            PanelPad.PaddingBottom = UDim.new(0, 12)

            local arrowGlyph
            if opts.arrow == nil or opts.arrow == true then
                arrowGlyph = "→"
            elseif type(opts.arrow) == "string" then
                arrowGlyph = opts.arrow
            end
            BuildCardHeader(Panel, title or "PREVIEW", opts.icon, arrowGlyph, opts.onArrow, Connections)

            local Stage = Instance.new("Frame", Panel)
            Stage.Position = UDim2.new(0, 0, 0, 32)
            Stage.Size = UDim2.new(1, 0, 1, -32)
            Stage.BackgroundTransparency = 1

            local centerX = 0.5
            local boxTop, boxBottom = 30, 190
            local boxHalfW = 38

            local NameLbl = Instance.new("TextLabel", Stage)
            NameLbl.Text = "player"
            NameLbl.Font = Enum.Font.Gotham
            NameLbl.TextSize = 12
            NameLbl.TextColor3 = CurrentTheme.TextPrimary
            NameLbl.BackgroundTransparency = 1
            NameLbl.AnchorPoint = Vector2.new(0.5, 1)
            NameLbl.Position = UDim2.new(centerX, 0, 0, boxTop - 6)
            NameLbl.Size = UDim2.new(0, 100, 0, 14)

            local HealthLbl = Instance.new("TextLabel", Stage)
            HealthLbl.Text = "100"
            HealthLbl.Font = Enum.Font.Gotham
            HealthLbl.TextSize = 11
            HealthLbl.TextColor3 = CurrentTheme.TextSecondary
            HealthLbl.BackgroundTransparency = 1
            HealthLbl.AnchorPoint = Vector2.new(1, 0.5)
            HealthLbl.Position = UDim2.new(centerX, -boxHalfW - 6, 0, boxTop + 4)
            HealthLbl.Size = UDim2.new(0, 30, 0, 14)

            local function makeVerticalBracket(xOffset)
                local V = Instance.new("Frame", Stage)
                V.BackgroundColor3 = CurrentTheme.TextPrimary
                V.BorderSizePixel = 0
                V.AnchorPoint = Vector2.new(0.5, 0)
                V.Position = UDim2.new(centerX, xOffset, 0, boxTop)
                V.Size = UDim2.new(0, 1, 0, boxBottom - boxTop)

                local TopTick = Instance.new("Frame", Stage)
                TopTick.BackgroundColor3 = CurrentTheme.TextPrimary
                TopTick.BorderSizePixel = 0
                TopTick.AnchorPoint = Vector2.new(0.5, 0)
                TopTick.Position = UDim2.new(centerX, xOffset, 0, boxTop)
                TopTick.Size = UDim2.new(0, 8, 0, 1)

                local BotTick = Instance.new("Frame", Stage)
                BotTick.BackgroundColor3 = CurrentTheme.TextPrimary
                BotTick.BorderSizePixel = 0
                BotTick.AnchorPoint = Vector2.new(0.5, 1)
                BotTick.Position = UDim2.new(centerX, xOffset, 0, boxBottom)
                BotTick.Size = UDim2.new(0, 8, 0, 1)

                return {V, TopTick, BotTick}
            end

            local leftBracket = makeVerticalBracket(-boxHalfW)
            local rightBracket = makeVerticalBracket(boxHalfW)
            local boxParts = {}
            for _, p in ipairs(leftBracket) do table.insert(boxParts, p) end
            for _, p in ipairs(rightBracket) do table.insert(boxParts, p) end

            local skeletonParts = {}
            local function line(fromX, fromY, toX, toY)
                local dx, dy = toX - fromX, toY - fromY
                local len = math.sqrt(dx * dx + dy * dy)
                local angle = math.atan2(dy, dx) * (180 / math.pi)
                local L = Instance.new("Frame", Stage)
                L.BackgroundColor3 = CurrentTheme.TextPrimary
                L.BorderSizePixel = 0
                L.AnchorPoint = Vector2.new(0, 0.5)
                L.Position = UDim2.new(centerX, fromX, 0, fromY)
                L.Size = UDim2.new(0, len, 0, 1)
                L.Rotation = angle
                table.insert(skeletonParts, L)
                return L
            end

            local Head = Instance.new("Frame", Stage)
            Head.BackgroundTransparency = 1
            Head.AnchorPoint = Vector2.new(0.5, 0.5)
            Head.Position = UDim2.new(centerX, 0, 0, 44)
            Head.Size = UDim2.new(0, 14, 0, 14)
            Corner(Head, 7)
            local HeadStroke = Stroke(Head, CurrentTheme.TextPrimary, 1, 0)
            table.insert(skeletonParts, Head)

            line(0, 51, 0, 100)
            line(0, 60, -16, 82)
            line(0, 60, 16, 82)
            line(0, 100, -14, 140)
            line(0, 100, 14, 140)

            local Handler = {}

            function Handler:SetBox(visible)
                for _, p in ipairs(boxParts) do
                    p.Visible = visible
                end
            end

            function Handler:SetSkeleton(visible)
                for _, p in ipairs(skeletonParts) do
                    p.Visible = visible
                end
                HeadStroke.Enabled = visible
            end

            function Handler:SetName(visible)
                NameLbl.Visible = visible
            end

            function Handler:SetHealthbar(visible)
                HealthLbl.Visible = visible
            end

            function Handler:SetHealth(value)
                HealthLbl.Text = tostring(value)
            end

            return Handler
        end

        return Elements
    end

    return Window
end

return Zabota
