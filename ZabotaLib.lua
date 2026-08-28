local Zabota = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Themes = {
    Dark = {
        MainBg = Color3.fromRGB(15, 16, 20),
        CardBg = Color3.fromRGB(22, 24, 30),
        CardItemBg = Color3.fromRGB(28, 30, 38),
        Border = Color3.fromRGB(45, 48, 60),
        Accent = Color3.fromRGB(235, 75, 75),
        TextPrimary = Color3.fromRGB(240, 242, 248),
        TextSecondary = Color3.fromRGB(140, 145, 160),
        SliderTrack = Color3.fromRGB(35, 38, 48)
    },
    Light = {
        MainBg = Color3.fromRGB(242, 244, 248),
        CardBg = Color3.fromRGB(255, 255, 255),
        CardItemBg = Color3.fromRGB(230, 233, 240),
        Border = Color3.fromRGB(210, 215, 225),
        Accent = Color3.fromRGB(220, 60, 60),
        TextPrimary = Color3.fromRGB(30, 32, 40),
        TextSecondary = Color3.fromRGB(110, 115, 130),
        SliderTrack = Color3.fromRGB(215, 218, 228)
    }
}

local CurrentTheme = Themes.Dark
local GlobalTransparency = 0.05
local AnimSpeed = 0.35

local function Tween(instance, properties, duration, style, direction)
    local t = TweenService:Create(instance, TweenInfo.new(duration or AnimSpeed, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08, Enum.EasingStyle.Sine)
        end
    end)
end

function Zabota:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "ZABOTA"
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    if PlayerGui:FindFirstChild("ZabotaUI_Screen") then
        PlayerGui.ZabotaUI_Screen:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZabotaUI_Screen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    -- Toasts Container
    local ToastContainer = Instance.new("Frame")
    ToastContainer.Size = UDim2.new(0, 260, 1, -20)
    ToastContainer.Position = UDim2.new(1, -275, 0, 10)
    ToastContainer.BackgroundTransparency = 1
    ToastContainer.Parent = ScreenGui

    local ToastLayout = Instance.new("UIListLayout")
    ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ToastLayout.Padding = UDim.new(0, 8)
    ToastLayout.Parent = ToastContainer

    local function Notify(title, desc, duration)
        local Toast = Instance.new("Frame")
        Toast.Size = UDim2.new(1, 0, 0, 0)
        Toast.BackgroundColor3 = CurrentTheme.CardBg
        Toast.ClipsDescendants = true
        Toast.Parent = ToastContainer

        local c = Instance.new("UICorner", Toast); c.CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke", Toast); s.Color = CurrentTheme.Accent; s.Thickness = 1.2
        local b = Instance.new("Frame", Toast); b.Size = UDim2.new(0, 4, 1, 0); b.BackgroundColor3 = CurrentTheme.Accent; b.BorderSizePixel = 0

        local t = Instance.new("TextLabel", Toast)
        t.Text = title:upper(); t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextColor3 = CurrentTheme.TextPrimary
        t.Position = UDim2.new(0, 14, 0, 8); t.Size = UDim2.new(1, -20, 0, 16); t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left

        local d = Instance.new("TextLabel", Toast)
        d.Text = desc; d.Font = Enum.Font.Gotham; d.TextSize = 11; d.TextColor3 = CurrentTheme.TextSecondary
        d.Position = UDim2.new(0, 14, 0, 26); d.Size = UDim2.new(1, -20, 0, 24); d.BackgroundTransparency = 1; d.TextXAlignment = Enum.TextXAlignment.Left

        Tween(Toast, {Size = UDim2.new(1, 0, 0, 58)}, 0.35, Enum.EasingStyle.Back)
        task.delay(duration or 3, function()
            if Toast and Toast.Parent then
                local fade = Tween(Toast, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
                fade.Completed:Connect(function() Toast:Destroy() end)
            end
        end)
    end

    -- Main Window
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Size = UDim2.new(0, 720, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -360, 0.5, -220)
    MainFrame.BackgroundColor3 = CurrentTheme.MainBg
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner", MainFrame); MainCorner.CornerRadius = UDim.new(0, 10)
    local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = CurrentTheme.Border; MainStroke.Thickness = 1.4

    MakeDraggable(MainFrame)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundColor3 = CurrentTheme.CardBg
    TopBar.BorderSizePixel = 0

    local Logo = Instance.new("TextLabel", TopBar)
    Logo.Text = TitleText
    Logo.Font = Enum.Font.GothamBlack
    Logo.TextSize = 17
    Logo.TextColor3 = CurrentTheme.Accent
    Logo.Position = UDim2.new(0, 20, 0, 0)
    Logo.Size = UDim2.new(0, 110, 1, 0)
    Logo.BackgroundTransparency = 1
    Logo.TextXAlignment = Enum.TextXAlignment.Left

    local TabScroll = Instance.new("ScrollingFrame", TopBar)
    TabScroll.Size = UDim2.new(1, -145, 1, 0)
    TabScroll.Position = UDim2.new(0, 135, 0, 0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel = 0
    TabScroll.ScrollBarThickness = 0
    TabScroll.CanvasSize = UDim2.new(0, 800, 0, 0)

    local TabListLayout = Instance.new("UIListLayout", TabScroll)
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabListLayout.Padding = UDim.new(0, 6)

    local PagesContainer = Instance.new("Frame", MainFrame)
    PagesContainer.Position = UDim2.new(0, 0, 0, 50)
    PagesContainer.Size = UDim2.new(1, 0, 1, -50)
    PagesContainer.BackgroundTransparency = 1

    -- Toggle Open/Close
    local isMenuOpen = true
    local function ToggleMenu()
        isMenuOpen = not isMenuOpen
        if isMenuOpen then
            MainFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 680, 0, 415)
            Tween(MainFrame, {Size = UDim2.new(0, 720, 0, 440), GroupTransparency = 0}, AnimSpeed, Enum.EasingStyle.Back)
        else
            local t = Tween(MainFrame, {Size = UDim2.new(0, 680, 0, 415), GroupTransparency = 1}, AnimSpeed * 0.8)
            t.Completed:Connect(function()
                if not isMenuOpen then MainFrame.Visible = false end
            end)
        end
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == ToggleKey then
            ToggleMenu()
        end
    end)

    -- Window Methods
    local Window = {
        Tabs = {},
        FirstTab = nil,
        Notify = Notify
    }

    -- Add HUD System
    function Window:CreateHUD(hudTitle)
        local HUD = Instance.new("Frame", ScreenGui)
        HUD.Size = UDim2.new(0, 200, 0, 36)
        HUD.AutomaticSize = Enum.AutomaticSize.Y
        HUD.Position = UDim2.new(0, 25, 0.5, -70)
        HUD.BackgroundColor3 = CurrentTheme.CardBg
        HUD.BackgroundTransparency = GlobalTransparency
        HUD.BorderSizePixel = 0

        local hCorner = Instance.new("UICorner", HUD); hCorner.CornerRadius = UDim.new(0, 8)
        local hStroke = Instance.new("UIStroke", HUD); hStroke.Color = CurrentTheme.Border; hStroke.Thickness = 1.2
        MakeDraggable(HUD)

        local topBarAccent = Instance.new("Frame", HUD)
        topBarAccent.Size = UDim2.new(1, 0, 0, 3)
        topBarAccent.BackgroundColor3 = CurrentTheme.Accent
        topBarAccent.BorderSizePixel = 0

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
        Instance.new("UIListLayout", LeftCol).Padding = UDim.new(0, 10)

        local RightCol = Instance.new("ScrollingFrame", Page)
        RightCol.Position = UDim2.new(0, 345, 0, 14); RightCol.Size = UDim2.new(1, -363, 1, -38)
        RightCol.BackgroundTransparency = 1; RightCol.BorderSizePixel = 0; RightCol.ScrollBarThickness = 2
        RightCol.ScrollBarImageColor3 = CurrentTheme.Accent
        Instance.new("UIListLayout", RightCol).Padding = UDim.new(0, 10)

        local TabBtn = Instance.new("TextButton", TabScroll)
        TabBtn.Size = UDim2.new(0, 70, 0, 32)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = tabName
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 12
        TabBtn.TextColor3 = CurrentTheme.TextSecondary

        local TabObject = {Page = Page, Left = LeftCol, Right = RightCol, Button = TabBtn}

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, {TextColor3 = CurrentTheme.TextSecondary}, 0.2)
            end
            Page.Visible = true
            Page.Position = UDim2.new(0, 0, 0, 8)
            Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)
            Tween(TabBtn, {TextColor3 = CurrentTheme.Accent}, 0.2)
        end)

        if not Window.FirstTab then
            Window.FirstTab = TabObject
            Page.Visible = true
            TabBtn.TextColor3 = CurrentTheme.Accent
        end

        table.insert(Window.Tabs, TabObject)

        -- Element Factory for Tab
        local Elements = {}

        function Elements:AddLeftButton(text, iconId, callback)
            local Btn = Instance.new("TextButton", LeftCol)
            Btn.Size = UDim2.new(1, -6, 0, 44); Btn.BackgroundColor3 = CurrentTheme.CardBg; Btn.BorderSizePixel = 0; Btn.Text = ""
            local c = Instance.new("UICorner", Btn); c.CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke", Btn); s.Color = CurrentTheme.Border; s.Thickness = 1

            local ic = Instance.new("ImageLabel", Btn)
            ic.Image = iconId or "rbxassetid://6031094678"; ic.Size = UDim2.new(0, 18, 0, 18); ic.Position = UDim2.new(0, 14, 0.5, -9)
            ic.BackgroundTransparency = 1; ic.ImageColor3 = CurrentTheme.TextSecondary

            local lb = Instance.new("TextLabel", Btn)
            lb.Text = text; lb.Font = Enum.Font.GothamBold; lb.TextSize = 13; lb.TextColor3 = CurrentTheme.TextPrimary
            lb.Position = UDim2.new(0, 42, 0, 0); lb.Size = UDim2.new(1, -80, 1, 0); lb.BackgroundTransparency = 1; lb.TextXAlignment = Enum.TextXAlignment.Left

            Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        function Elements:AddCard(cardTitle)
            local Card = Instance.new("Frame", RightCol)
            Card.Size = UDim2.new(1, -6, 0, 40); Card.AutomaticSize = Enum.AutomaticSize.Y; Card.BackgroundColor3 = CurrentTheme.CardBg; Card.BorderSizePixel = 0
            local c = Instance.new("UICorner", Card); c.CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke", Card); s.Color = CurrentTheme.Border; s.Thickness = 1

            local t = Instance.new("TextLabel", Card)
            t.Text = cardTitle; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextColor3 = CurrentTheme.TextPrimary
            t.Position = UDim2.new(0, 14, 0, 8); t.Size = UDim2.new(1, -28, 0, 20); t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left

            local Container = Instance.new("Frame", Card)
            Container.Position = UDim2.new(0, 12, 0, 36); Container.Size = UDim2.new(1, -24, 0, 0); Container.AutomaticSize = Enum.AutomaticSize.Y; Container.BackgroundTransparency = 1
            local list = Instance.new("UIListLayout", Container); list.Padding = UDim.new(0, 10)
            local pad = Instance.new("UIPadding", Container); pad.PaddingBottom = UDim.new(0, 12)

            local CardControls = {}

            function CardControls:AddToggle(name, default, callback)
                local state = default or false
                local Btn = Instance.new("TextButton", Container)
                Btn.Size = UDim2.new(1, 0, 0, 32); Btn.BackgroundTransparency = 1; Btn.Text = ""

                local lb = Instance.new("TextLabel", Btn)
                lb.Text = name; lb.Font = Enum.Font.GothamMedium; lb.TextSize = 13; lb.TextColor3 = CurrentTheme.TextPrimary
                lb.Size = UDim2.new(1, -60, 1, 0); lb.BackgroundTransparency = 1; lb.TextXAlignment = Enum.TextXAlignment.Left

                local Sw = Instance.new("Frame", Btn)
                Sw.Size = UDim2.new(0, 42, 0, 22); Sw.Position = UDim2.new(1, -42, 0.5, -11)
                Sw.BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SliderTrack; Sw.BorderSizePixel = 0
                local sc = Instance.new("UICorner", Sw); sc.CornerRadius = UDim.new(1, 0)

                local Ind = Instance.new("Frame", Sw)
                Ind.Size = UDim2.new(0, 16, 0, 16); Ind.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                Ind.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Ind.BorderSizePixel = 0
                local ic = Instance.new("UICorner", Ind); ic.CornerRadius = UDim.new(1, 0)

                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(Sw, {BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.SliderTrack}, 0.2)
                    Tween(Ind, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2, Enum.EasingStyle.Back)
                    Notify(name, state and "Enabled" or "Disabled", 1.5)
                    if callback then callback(state) end
                end)
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
                Val.Text = string.format("%.1f", cur); Val.Font = Enum.Font.GothamBold; Val.TextSize = 12; Val.TextColor3 = CurrentTheme.TextPrimary
                Val.Position = UDim2.new(1, -60, 0, 0); Val.Size = UDim2.new(0, 60, 0, 16); Val.BackgroundTransparency = 1; Val.TextXAlignment = Enum.TextXAlignment.Right

                local Bar = Instance.new("TextButton", Box)
                Bar.Text = ""; Bar.AutoButtonColor = false; Bar.Size = UDim2.new(1, 0, 0, 6); Bar.Position = UDim2.new(0, 0, 0, 24)
                Bar.BackgroundColor3 = CurrentTheme.SliderTrack; Bar.BorderSizePixel = 0
                local bc = Instance.new("UICorner", Bar); bc.CornerRadius = UDim.new(1, 0)

                local Fill = Instance.new("Frame", Bar)
                Fill.Size = UDim2.new(math.clamp((cur - min) / (max - min), 0, 1), 0, 1, 0)
                Fill.BackgroundColor3 = CurrentTheme.Accent; Fill.BorderSizePixel = 0
                local fc = Instance.new("UICorner", Fill); fc.CornerRadius = UDim.new(1, 0)

                local dragging = false
                local function update(inputX)
                    local rel = math.clamp((inputX - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local v = math.floor((min + (max - min) * rel) / step + 0.5) * step
                    cur = math.clamp(v, min, max)
                    Val.Text = string.format("%.1f", cur)
                    Tween(Fill, {Size = UDim2.new(rel, 0, 1, 0)}, 0.05, Enum.EasingStyle.Sine)
                    if callback then callback(cur) end
                end

                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        update(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false
                        Notify(name, "Set to " .. string.format("%.1f", cur), 1.5)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input.Position.X)
                    end
                end)
            end

            return CardControls
        end

        return Elements
    end

    return Window
end

return Zabota