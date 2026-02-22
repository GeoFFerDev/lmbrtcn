--[[
     ██╗ ██████╗ ███████╗███████╗███████╗██████╗     ██╗  ██╗██╗   ██╗██████╗ 
     ██║██╔═══██╗██╔════╝██╔════╝██╔════╝██╔══██╗    ██║  ██║██║   ██║██╔══██╗
     ██║██║   ██║█████╗  █████╗  █████╗  ██████╔╝    ███████║██║   ██║██████╔╝
██   ██║██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗    ██╔══██║██║   ██║██╔══██╗
╚█████╔╝╚██████╔╝██║     ██║     ███████╗██║  ██║    ██║  ██║╚██████╔╝██████╔╝
 ╚════╝  ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
    Lumber Tycoon 2  |  Toggle: RightCtrl  |  Mobile: tap floating icon
--]]

-- ─────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ─────────────────────────────────────────────────────────────────
-- THEME
-- ─────────────────────────────────────────────────────────────────
local T = {
    WindowBG     = Color3.fromRGB(16,  20,  30),
    SidebarBG    = Color3.fromRGB(11,  14,  22),
    ContentBG    = Color3.fromRGB(20,  26,  36),
    ElementBG    = Color3.fromRGB(26,  33,  48),
    ElementHover = Color3.fromRGB(34,  44,  62),

    Accent       = Color3.fromRGB(0,   200, 175),
    AccentDim    = Color3.fromRGB(0,   130, 115),
    AccentText   = Color3.fromRGB(80,  230, 210),

    TextPri      = Color3.fromRGB(228, 234, 245),
    TextSec      = Color3.fromRGB(138, 155, 178),

    ToggleOn     = Color3.fromRGB(0,   200, 175),
    ToggleOff    = Color3.fromRGB(50,  62,  85),
    Thumb        = Color3.fromRGB(235, 240, 255),

    SliderTrack  = Color3.fromRGB(38,  48,  68),
    Separator    = Color3.fromRGB(30,  40,  58),

    Corner       = UDim.new(0, 7),
    SmallCorner  = UDim.new(0, 5),
    SidebarW     = 170,
    RowH         = 36,
    WinW         = 555,
    WinH         = 375,
}

-- ─────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────
local function New(cls, props, ch)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then i[k] = v end
    end
    for _, c in ipairs(ch or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end

local function Corner(p, r)
    return New("UICorner", {CornerRadius = r or T.Corner, Parent = p})
end
local function Stroke(p, c, w)
    return New("UIStroke", {Color = c, Thickness = w or 1, Parent = p})
end
local function Pad(p, t, b, l, r)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft   = UDim.new(0, l or 10),
        PaddingRight  = UDim.new(0, r or 10),
        Parent = p
    })
end
local function List(p, dir, gap)
    return New("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, gap or 4),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Parent = p
    })
end

local TI  = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TIF = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TIS = TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function Tw(o, p)  TweenService:Create(o, TI,  p):Play() end
local function TwF(o, p) TweenService:Create(o, TIF, p):Play() end
local function TwS(o, p) TweenService:Create(o, TIS, p):Play() end

-- ─────────────────────────────────────────────────────────────────
-- DRAG HELPER  ─  mouse + touch unified
-- ─────────────────────────────────────────────────────────────────
local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- DESTROY OLD
-- ─────────────────────────────────────────────────────────────────
pcall(function()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("JofferHub")
        if old then old:Destroy() end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- SCREEN GUI
-- ─────────────────────────────────────────────────────────────────
local guiParent
pcall(function()
    if gethui then guiParent = gethui()
    else            guiParent = LP:WaitForChild("PlayerGui") end
end)
if not guiParent then guiParent = LP:WaitForChild("PlayerGui") end

local ScreenGui = New("ScreenGui", {
    Name             = "JofferHub",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset   = true,
    DisplayOrder     = 999,
    Parent           = guiParent,
})

-- ─────────────────────────────────────────────────────────────────
-- FLOATING ICON  (visible when minimized, draggable)
-- ─────────────────────────────────────────────────────────────────
local Icon = New("Frame", {
    Name             = "FloatIcon",
    Size             = UDim2.new(0, 56, 0, 56),
    Position         = UDim2.new(0, 18, 0.5, -28),
    BackgroundColor3 = T.SidebarBG,
    BorderSizePixel  = 0,
    Visible          = false,
    ZIndex           = 20,
    Parent           = ScreenGui,
})
Corner(Icon, UDim.new(0, 15))
Stroke(Icon, T.Accent, 2)

local IconBtn = New("TextButton", {
    Text             = "J",
    Size             = UDim2.new(1, 0, 0.72, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Font             = Enum.Font.GothamBold,
    TextSize         = 24,
    TextColor3       = T.Accent,
    ZIndex           = 21,
    Parent           = Icon,
})
New("TextLabel", {
    Text             = "Hub",
    Size             = UDim2.new(1, 0, 0, 14),
    Position         = UDim2.new(0, 0, 1, -15),
    BackgroundTransparency = 1,
    Font             = Enum.Font.Gotham,
    TextSize         = 9,
    TextColor3       = T.TextSec,
    ZIndex           = 21,
    Parent           = Icon,
})

-- Make icon draggable
MakeDraggable(Icon, Icon)

-- ─────────────────────────────────────────────────────────────────
-- MAIN WINDOW
-- ─────────────────────────────────────────────────────────────────
local Main = New("Frame", {
    Name             = "Main",
    Size             = UDim2.new(0, T.WinW, 0, T.WinH),
    Position         = UDim2.new(0.5, -T.WinW/2, 0.5, -T.WinH/2),
    BackgroundColor3 = T.WindowBG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    ZIndex           = 5,
    Parent           = ScreenGui,
})
Corner(Main)
Stroke(Main, Color3.fromRGB(38, 52, 72), 1)

-- Shadow
New("ImageLabel", {
    Size             = UDim2.new(1, 50, 1, 50),
    Position         = UDim2.new(0, -25, 0, -25),
    BackgroundTransparency = 1,
    Image            = "rbxassetid://6014261993",
    ImageColor3      = Color3.new(0, 0, 0),
    ImageTransparency= 0.5,
    ScaleType        = Enum.ScaleType.Slice,
    SliceCenter      = Rect.new(49, 49, 450, 450),
    ZIndex           = 4,
    Parent           = Main,
})

-- ── Title Bar ────────────────────────────────────────
local TBar = New("Frame", {
    Size             = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.SidebarBG,
    BorderSizePixel  = 0,
    ZIndex           = 6,
    Parent           = Main,
})
-- bottom accent line
New("Frame", {
    Size             = UDim2.new(1,0,0,1),
    Position         = UDim2.new(0,0,1,-1),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.55,
    BorderSizePixel  = 0,
    ZIndex           = 7,
    Parent           = TBar,
})

-- logo dot
local dot = New("Frame", {
    Size             = UDim2.new(0, 7, 0, 7),
    Position         = UDim2.new(0, 12, 0.5, -3),
    BackgroundColor3 = T.Accent,
    BorderSizePixel  = 0,
    ZIndex           = 7,
    Parent           = TBar,
})
Corner(dot, UDim.new(1, 0))

New("TextLabel", {
    Text="Joffer Hub", Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,26,0,0),
    BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7,
    Parent=TBar,
})
New("TextLabel", {
    Text="LT2", Size=UDim2.new(0,36,1,0), Position=UDim2.new(0,130,0,0),
    BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=11,
    TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7,
    Parent=TBar,
})

-- Drag title bar
MakeDraggable(TBar, Main)

-- Close button
local CloseBtn = New("TextButton", {
    Text="✕", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-34,0.5,-14),
    BackgroundColor3=Color3.fromRGB(185,55,55), BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextPri,
    BorderSizePixel=0, ZIndex=8, Parent=TBar,
})
Corner(CloseBtn, UDim.new(0, 5))

-- Minimize button
local MinBtn = New("TextButton", {
    Text="─", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-66,0.5,-14),
    BackgroundColor3=T.ElementBG, BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextSec,
    BorderSizePixel=0, ZIndex=8, Parent=TBar,
})
Corner(MinBtn, UDim.new(0, 5))

-- ── Body ─────────────────────────────────────────────
local Body = New("Frame", {
    Size=UDim2.new(1,0,1,-40), Position=UDim2.new(0,0,0,40),
    BackgroundTransparency=1, BorderSizePixel=0, Parent=Main,
})

-- ── Sidebar ──────────────────────────────────────────
local Sidebar = New("Frame", {
    Size=UDim2.new(0,T.SidebarW,1,0),
    BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Parent=Body,
})
New("Frame", {  -- right divider
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
    BackgroundColor3=T.Separator, BorderSizePixel=0, Parent=Sidebar,
})

local TabList = New("ScrollingFrame", {
    Size=UDim2.new(1,0,1,-6), Position=UDim2.new(0,0,0,6),
    BackgroundTransparency=1, ScrollBarThickness=0,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Parent=Sidebar,
})
Pad(TabList, 4, 4, 5, 5)
List(TabList, nil, 2)

-- ── Content ──────────────────────────────────────────
local Content = New("Frame", {
    Size=UDim2.new(1,-T.SidebarW,1,0), Position=UDim2.new(0,T.SidebarW,0,0),
    BackgroundColor3=T.ContentBG, BorderSizePixel=0, Parent=Body,
})
local PageContainer = New("Frame", {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=Content,
})

-- ─────────────────────────────────────────────────────────────────
-- MINIMIZE / RESTORE
-- ─────────────────────────────────────────────────────────────────
local minimized = false

local function ShowMain()
    minimized   = false
    Icon.Visible = false
    Main.Visible = true
    Main.Size    = UDim2.new(0, 0, 0, 0)
    TwS(Main, {Size = UDim2.new(0, T.WinW, 0, T.WinH)})
end

local function ShowIcon()
    minimized = true
    -- Snap icon to where minimize button currently is (smooth ux)
    local abs = MinBtn.AbsolutePosition
    Icon.Position = UDim2.new(0, abs.X, 0, abs.Y)
    TwF(Main, {Size = UDim2.new(0, 0, 0, 0)})
    task.delay(0.22, function()
        Main.Visible = false
        Icon.Visible = true
        Icon.Size    = UDim2.new(0, 0, 0, 0)
        Icon.Position= UDim2.new(0, 18, 0.5, -28)  -- reset to left edge
        TwS(Icon, {Size = UDim2.new(0, 56, 0, 56)})
    end)
end

MinBtn.MouseButton1Click:Connect(ShowIcon)
-- Touch support on minimize
MinBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then ShowIcon() end
end)

-- Tap icon to restore
IconBtn.MouseButton1Click:Connect(function() if minimized then ShowMain() end end)
IconBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch and minimized then ShowMain() end
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
CloseBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then ScreenGui:Destroy() end
end)

-- Keyboard toggle
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        if minimized then ShowMain() else ShowIcon() end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- TAB + COMPONENT FACTORY
-- ─────────────────────────────────────────────────────────────────
local Tabs      = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    -- Sidebar button
    local btn = New("TextButton", {
        Name             = name,
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = T.ElementBG,
        BackgroundTransparency = 1,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T.TextSec,
        Text             = (icon or "  ") .. "  " .. name,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BorderSizePixel  = 0,
        Parent           = TabList,
    })
    Corner(btn, T.SmallCorner)
    Pad(btn, 0, 0, 9, 6)

    local indicator = New("Frame", {
        Size             = UDim2.new(0, 3, 0.55, 0),
        Position         = UDim2.new(0, 0, 0.225, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Visible          = false,
        Parent           = btn,
    })
    Corner(indicator, UDim.new(0, 2))

    -- Page
    local page = New("ScrollingFrame", {
        Name             = name .. "Page",
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible          = false,
        Parent           = PageContainer,
    })
    Pad(page, 8, 8, 10, 10)
    List(page, nil, 4)

    local Tab = {Button=btn, Page=page, Indicator=indicator}

    -- AddSection
    function Tab:AddSection(text)
        local f = New("Frame", {
            Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Parent=page,
        })
        New("TextLabel", {
            Text=text:upper(), Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Font=Enum.Font.GothamBold, TextSize=9, TextColor3=T.Accent,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=f,
        })
        New("Frame", {
            Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
            BackgroundColor3=T.Separator, BorderSizePixel=0, Parent=f,
        })
    end

    -- AddToggle
    function Tab:AddToggle(text, opts, cb)
        opts = opts or {}
        local state = opts.Default or false
        local row = New("Frame", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundColor3=T.ElementBG,
            BorderSizePixel=0, Parent=page,
        })
        Corner(row)
        New("TextLabel", {
            Text=text, Size=UDim2.new(1,-56,1,0), Position=UDim2.new(0,11,0,0),
            BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12,
            TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
        })
        local track = New("Frame", {
            Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-48,0.5,-10),
            BackgroundColor3=state and T.ToggleOn or T.ToggleOff,
            BorderSizePixel=0, Parent=row,
        })
        Corner(track, UDim.new(1,0))
        local thumb = New("Frame", {
            Size=UDim2.new(0,14,0,14),
            Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
            BackgroundColor3=T.Thumb, BorderSizePixel=0, Parent=track,
        })
        Corner(thumb, UDim.new(1,0))

        local function Set(s)
            state = s
            Tw(track, {BackgroundColor3 = state and T.ToggleOn or T.ToggleOff})
            Tw(thumb, {Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
            if cb then pcall(cb, state) end
        end

        New("TextButton", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=row,
        }).MouseButton1Click:Connect(function() Set(not state) end)
        row.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then Set(not state) end
        end)
        row.MouseEnter:Connect(function() Tw(row,{BackgroundColor3=T.ElementHover}) end)
        row.MouseLeave:Connect(function() Tw(row,{BackgroundColor3=T.ElementBG}) end)
        return {Set=Set, Get=function() return state end}
    end

    -- AddSlider
    function Tab:AddSlider(text, opts, cb)
        opts = opts or {}
        local mn   = opts.Min     or 0
        local mx   = opts.Max     or 100
        local step = opts.Step    or 1
        local val  = opts.Default or mn
        local row = New("Frame", {
            Size=UDim2.new(1,0,0,50), BackgroundColor3=T.ElementBG,
            BorderSizePixel=0, Parent=page,
        })
        Corner(row)
        local topRow = New("Frame", {
            Size=UDim2.new(1,-22,0,22), Position=UDim2.new(0,11,0,6),
            BackgroundTransparency=1, Parent=row,
        })
        New("TextLabel", {
            Text=text, Size=UDim2.new(1,-46,1,0), BackgroundTransparency=1,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TextPri,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=topRow,
        })
        local valLbl = New("TextLabel", {
            Text=tostring(val), Size=UDim2.new(0,44,1,0), Position=UDim2.new(1,-44,0,0),
            BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=11,
            TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Right, Parent=topRow,
        })
        local track = New("Frame", {
            Size=UDim2.new(1,-22,0,5), Position=UDim2.new(0,11,0,34),
            BackgroundColor3=T.SliderTrack, BorderSizePixel=0, Parent=row,
        })
        Corner(track, UDim.new(1,0))
        local p0 = (val-mn)/(mx-mn)
        local fill = New("Frame", {
            Size=UDim2.new(p0,0,1,0), BackgroundColor3=T.Accent,
            BorderSizePixel=0, Parent=track,
        })
        Corner(fill, UDim.new(1,0))
        local knob = New("Frame", {
            Size=UDim2.new(0,13,0,13), Position=UDim2.new(p0,-6,0.5,-6),
            BackgroundColor3=T.Thumb, BorderSizePixel=0, ZIndex=3, Parent=track,
        })
        Corner(knob, UDim.new(1,0))

        local function SetVal(v)
            v = math.clamp(math.round((v-mn)/step)*step+mn, mn, mx)
            val = v
            local p = (v-mn)/(mx-mn)
            Tw(fill,  {Size=UDim2.new(p,0,1,0)})
            Tw(knob,  {Position=UDim2.new(p,-6,0.5,-6)})
            valLbl.Text = tostring(v)
            if cb then pcall(cb, v) end
        end

        local dragging = false
        local function drag(pos)
            local rel = math.clamp((pos.X-track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
            SetVal(mn + rel*(mx-mn))
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
                dragging=true; drag(i.Position)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement
                          or i.UserInputType==Enum.UserInputType.Touch) then
                drag(i.Position)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
                dragging=false
            end
        end)
        return {Set=SetVal, Get=function() return val end}
    end

    -- AddButton
    function Tab:AddButton(text, cb)
        local btn2 = New("TextButton", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundColor3=T.ElementBG,
            Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.Accent,
            Text=text, BorderSizePixel=0, Parent=page,
        })
        Corner(btn2)
        Stroke(btn2, T.AccentDim, 1)
        btn2.MouseEnter:Connect(function()   Tw(btn2,{BackgroundColor3=T.ElementHover}) end)
        btn2.MouseLeave:Connect(function()   Tw(btn2,{BackgroundColor3=T.ElementBG})    end)
        local function fire()
            Tw(btn2,{BackgroundColor3=T.AccentDim})
            task.delay(0.14, function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end)
            if cb then pcall(cb) end
        end
        btn2.MouseButton1Click:Connect(fire)
        btn2.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then fire() end
        end)
        return btn2
    end

    -- AddDropdown
    function Tab:AddDropdown(text, opts, cb)
        opts = opts or {}
        local options = opts.Options or {}
        local current = opts.Default or options[1] or "Select..."
        local open    = false

        local wrapper = New("Frame", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundTransparency=1,
            ClipsDescendants=false, Parent=page,
        })
        local header = New("TextButton", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundColor3=T.ElementBG,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TextPri,
            Text="", BorderSizePixel=0, Parent=wrapper,
        })
        Corner(header)
        New("TextLabel", {
            Text=text, Size=UDim2.new(0.5,-8,1,0), Position=UDim2.new(0,11,0,0),
            BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12,
            TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left, Parent=header,
        })
        local valLbl = New("TextLabel", {
            Text=current, Size=UDim2.new(0.5,-28,1,0), Position=UDim2.new(0.5,0,0,0),
            BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=11,
            TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Right, Parent=header,
        })
        local arrow = New("TextLabel", {
            Text="▾", Size=UDim2.new(0,18,1,0), Position=UDim2.new(1,-20,0,0),
            BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=12,
            TextColor3=T.TextSec, Parent=header,
        })
        local dd = New("Frame", {
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,T.RowH+2),
            BackgroundColor3=T.ElementBG, BorderSizePixel=0, ClipsDescendants=true,
            Visible=false, ZIndex=10, Parent=wrapper,
        })
        Corner(dd)
        Stroke(dd, T.Accent, 1)
        local itemFrame = New("Frame", {
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=dd,
        })
        Pad(itemFrame, 3,3,4,4)
        List(itemFrame, nil, 2)

        for _, opt in ipairs(options) do
            local ib = New("TextButton", {
                Size=UDim2.new(1,0,0,28), BackgroundColor3=T.ElementBG,
                BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=11,
                TextColor3=T.TextSec, Text=opt, TextXAlignment=Enum.TextXAlignment.Left,
                BorderSizePixel=0, ZIndex=11, Parent=itemFrame,
            })
            Pad(ib, 0,0,8,4)
            Corner(ib, T.SmallCorner)
            ib.MouseEnter:Connect(function() ib.TextColor3=T.TextPri end)
            ib.MouseLeave:Connect(function() ib.TextColor3=T.TextSec end)
            local function pick()
                current=opt; valLbl.Text=opt
                open=false; dd.Visible=false; arrow.Text="▾"
                wrapper.Size=UDim2.new(1,0,0,T.RowH)
                if cb then pcall(cb, opt) end
            end
            ib.MouseButton1Click:Connect(pick)
            ib.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.Touch then pick() end
            end)
        end

        local function toggle()
            open = not open
            if open then
                local h = math.min(#options*30+8, 148)
                dd.Visible=true
                TwF(dd, {Size=UDim2.new(1,0,0,h)})
                wrapper.Size=UDim2.new(1,0,0,T.RowH+h+4)
                arrow.Text="▴"
            else
                TwF(dd, {Size=UDim2.new(1,0,0,0)})
                task.delay(0.22, function() dd.Visible=false end)
                wrapper.Size=UDim2.new(1,0,0,T.RowH)
                arrow.Text="▾"
            end
        end
        header.MouseButton1Click:Connect(toggle)
        header.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then toggle() end
        end)
        return {Set=function(v) current=v; valLbl.Text=v end, Get=function() return current end}
    end

    -- AddLabel
    function Tab:AddLabel(text)
        local row = New("Frame", {
            Size=UDim2.new(1,0,0,30), BackgroundColor3=T.ElementBG,
            BackgroundTransparency=0.55, BorderSizePixel=0, Parent=page,
        })
        Corner(row)
        local lbl = New("TextLabel", {
            Text=text, Size=UDim2.new(1,-22,1,0), Position=UDim2.new(0,11,0,0),
            BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=11,
            TextColor3=T.TextSec, TextXAlignment=Enum.TextXAlignment.Left,
            TextWrapped=true, Parent=row,
        })
        return {Set=function(v) lbl.Text=v end}
    end

    -- Sidebar tab click
    local function Activate()
        for _, t in pairs(Tabs) do
            t.Page.Visible=false; t.Indicator.Visible=false
            Tw(t.Button, {BackgroundTransparency=1, TextColor3=T.TextSec})
        end
        page.Visible=true; indicator.Visible=true
        Tw(btn, {BackgroundTransparency=0.82, TextColor3=T.TextPri})
        ActiveTab=Tab
    end
    btn.MouseButton1Click:Connect(Activate)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch then Activate() end
    end)
    btn.MouseEnter:Connect(function()
        if ActiveTab~=Tab then Tw(btn,{BackgroundTransparency=0.88}) end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab~=Tab then Tw(btn,{BackgroundTransparency=1}) end
    end)

    Tabs[name] = Tab
    return Tab
end

-- ═══════════════════════════════════════════════════════════════════
-- GAME  LOGIC  ─  Lumber Tycoon 2
-- ═══════════════════════════════════════════════════════════════════
local Flags = {
    Fly=false, Noclip=false, AutoChop=false, AutoSell=false,
    InfJump=false, SpeedVal=16, JumpVal=50, FlySpeed=50, SelWood="Oak",
}

local function GetChar() return LP.Character end
local function GetHRP()  local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end

LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    local h=c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=Flags.SpeedVal; h.JumpPower=Flags.JumpVal end
end)

-- FLY
local flyConn, flyBV, flyBG
local function StartFly()
    local hrp=GetHRP(); if not hrp then return end
    flyBV=Instance.new("BodyVelocity")
    flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.zero; flyBV.Parent=hrp
    flyBG=Instance.new("BodyGyro")
    flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.CFrame=hrp.CFrame; flyBG.Parent=hrp
    flyConn=RunService.Heartbeat:Connect(function()
        if not Flags.Fly then return end
        local h2=GetHRP(); if not h2 then return end
        local cam=Workspace.CurrentCamera; local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*Flags.FlySpeed or Vector3.zero
        flyBG.CFrame=cam.CFrame
    end)
end
local function StopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV   then flyBV:Destroy();      flyBV=nil  end
    if flyBG   then flyBG:Destroy();      flyBG=nil  end
end

-- NOCLIP
local noclipConn
local function SetNoclip(s)
    if s then
        noclipConn=RunService.Stepped:Connect(function()
            local c=GetChar(); if not c then return end
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        local c=GetChar(); if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
end

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if Flags.InfJump then
        local h=GetHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- AUTO CHOP
local autoChopConn
local function StartAutoChop()
    autoChopConn=RunService.Heartbeat:Connect(function()
        if not Flags.AutoChop then return end
        local hrp=GetHRP(); if not hrp then return end
        local nearest, dist=nil, 80
        for _,v in ipairs(Workspace:GetDescendants()) do
            if (v:IsA("MeshPart") or v:IsA("UnionOperation"))
            and (v.Name=="Trunk" or v.Name:lower():find("trunk")) then
                local d=(hrp.Position-v.Position).Magnitude
                if d<dist then nearest=v; dist=d end
            end
        end
        if nearest then
            local r=ReplicatedStorage:FindFirstChild("Chop",true)
                   or ReplicatedStorage:FindFirstChild("ChopTree",true)
            if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer(nearest) end) end
        end
    end)
end
local function StopAutoChop()
    if autoChopConn then autoChopConn:Disconnect(); autoChopConn=nil end
end

-- AUTO SELL
local autoSellConn
local function StartAutoSell()
    autoSellConn=RunService.Heartbeat:Connect(function()
        if not Flags.AutoSell then return end
        local r=ReplicatedStorage:FindFirstChild("SellWood",true)
                or ReplicatedStorage:FindFirstChild("Sell",true)
        if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
    end)
end
local function StopAutoSell()
    if autoSellConn then autoSellConn:Disconnect(); autoSellConn=nil end
end

-- TELEPORT
local Locations={
    ["Base"]             = CFrame.new(108,  5,  -79),
    ["Wood R Us"]        = CFrame.new(160,  5, -275),
    ["Link's Logic"]     = CFrame.new(-6,   5, -276),
    ["Fancy Furnishings"]= CFrame.new(183,  5,   66),
    ["Spawn"]            = CFrame.new(0,    5,    0),
    ["Swamp Biome"]      = CFrame.new(-1250,90, -520),
    ["Volcano Biome"]    = CFrame.new(1870,168,-1530),
    ["Snow Biome"]       = CFrame.new(-1200,60, 1200),
}
local function TeleportTo(name)
    local cf=Locations[name]; if not cf then return end
    local hrp=GetHRP(); if hrp then hrp.CFrame=cf end
end

local function DupeWood()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("TreeRegion") then
            pcall(function() v:SetPrimaryPartCFrame(CFrame.new(160,5,-275)) end)
        end
    end
end

local function GrabTools()
    local hrp=GetHRP(); if not hrp then return end
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and not v.Parent:IsA("Model") then
            local h=v:FindFirstChild("Handle")
            if h and (hrp.Position-h.Position).Magnitude<30 then
                pcall(function() v.Parent=LP.Backpack end)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- BUILD TABS
-- ═══════════════════════════════════════════════════════════════════

-- PLAYER
local PlayerTab = CreateTab("Player","👤")
PlayerTab:AddSection("Movement")
PlayerTab:AddSlider("Walk Speed",{Min=1,Max=150,Default=16,Step=1},function(v)
    Flags.SpeedVal=v; local h=GetHum(); if h then h.WalkSpeed=v end
end)
PlayerTab:AddSlider("Jump Power",{Min=0,Max=250,Default=50,Step=1},function(v)
    Flags.JumpVal=v; local h=GetHum(); if h then h.JumpPower=v end
end)
PlayerTab:AddToggle("Infinite Jump",{Default=false},function(v) Flags.InfJump=v end)
PlayerTab:AddToggle("Noclip",{Default=false},function(v) Flags.Noclip=v; SetNoclip(v) end)
PlayerTab:AddSection("Flight")
PlayerTab:AddSlider("Fly Speed",{Min=10,Max=300,Default=50,Step=5},function(v) Flags.FlySpeed=v end)
PlayerTab:AddToggle("Fly",{Default=false},function(v)
    Flags.Fly=v; if v then StartFly() else StopFly() end
end)
PlayerTab:AddSection("Misc")
PlayerTab:AddButton("Reset Character",function()
    local h=GetHum(); if h then h.Health=0 end
end)
PlayerTab:AddButton("Grab Nearby Tools", GrabTools)

-- WORLD
local WorldTab = CreateTab("World","🌍")
WorldTab:AddSection("Teleport")
local locOpts={}
for name in pairs(Locations) do table.insert(locOpts,name) end
local locDrop=WorldTab:AddDropdown("Select Location",{Options=locOpts,Default=locOpts[1]})
WorldTab:AddButton("Teleport ▶",function() TeleportTo(locDrop:Get()) end)
WorldTab:AddSection("Quick")
WorldTab:AddButton("→ Base",             function() TeleportTo("Base")             end)
WorldTab:AddButton("→ Wood R Us",        function() TeleportTo("Wood R Us")        end)
WorldTab:AddButton("→ Fancy Furnishings",function() TeleportTo("Fancy Furnishings")end)
WorldTab:AddButton("→ Swamp Biome",      function() TeleportTo("Swamp Biome")      end)
WorldTab:AddButton("→ Volcano Biome",    function() TeleportTo("Volcano Biome")    end)
WorldTab:AddButton("→ Snow Biome",       function() TeleportTo("Snow Biome")       end)

-- WOOD
local WoodTab = CreateTab("Wood","🪵")
WoodTab:AddSection("Auto Chop")
local woodTypes={"Oak","Birch","Walnut","Spooky","Elm","Snowglow","Lava","Palm","Pine","Koa","Fir","Volcano","Sinister"}
WoodTab:AddDropdown("Target Wood",{Options=woodTypes,Default="Oak"},function(v) Flags.SelWood=v end)
WoodTab:AddToggle("Auto Chop",{Default=false},function(v)
    Flags.AutoChop=v; if v then StartAutoChop() else StopAutoChop() end
end)
WoodTab:AddSection("Actions")
WoodTab:AddButton("Teleport Wood → Sawmill", DupeWood)
local treeLbl=WoodTab:AddLabel("Press button to scan trees")
WoodTab:AddButton("Count Trees",function()
    local n=0
    for _,v in ipairs(Workspace:GetDescendants()) do
        if (v.Name=="Trunk" or v.Name:lower():find("trunk"))
        and (v:IsA("MeshPart") or v:IsA("UnionOperation")) then n=n+1 end
    end
    treeLbl:Set("Trees found: "..n)
end)

-- AUTO BUY
local AutoBuyTab = CreateTab("Auto Buy","💰")
AutoBuyTab:AddSection("Shop")
AutoBuyTab:AddButton("Buy Basic Sawmill",function()
    local r=ReplicatedStorage:FindFirstChild("Purchase",true)
    if r then pcall(function() r:FireServer("BasicSawmill") end) end
end)
AutoBuyTab:AddButton("Buy Better Axe",function()
    local r=ReplicatedStorage:FindFirstChild("Purchase",true)
    if r then pcall(function() r:FireServer("BetterAxe") end) end
end)
AutoBuyTab:AddButton("Buy End Times Axe",function()
    local r=ReplicatedStorage:FindFirstChild("Purchase",true)
    if r then pcall(function() r:FireServer("EndTimesAxe") end) end
end)
AutoBuyTab:AddSection("Auto Sell")
AutoBuyTab:AddToggle("Auto Sell Wood",{Default=false},function(v)
    Flags.AutoSell=v; if v then StartAutoSell() else StopAutoSell() end
end)
AutoBuyTab:AddLabel("Fires sell remote repeatedly")

-- DUPE
local DupeTab = CreateTab("Dupe","📦")
DupeTab:AddSection("Wood Dupe")
DupeTab:AddLabel("Moves loaded logs to sawmill area")
DupeTab:AddButton("Dupe Wood",DupeWood)
DupeTab:AddButton("Dupe + Instant Sell",function()
    DupeWood(); task.wait(0.5)
    local r=ReplicatedStorage:FindFirstChild("SellWood",true)
    if r then pcall(function() r:FireServer() end) end
end)
DupeTab:AddSection("Item Dupe")
DupeTab:AddButton("Re-grab Dropped Items", GrabTools)
DupeTab:AddButton("Clone Held Tool",function()
    local c=GetChar(); if not c then return end
    local t=c:FindFirstChildOfClass("Tool"); if not t then return end
    pcall(function() t:Clone().Parent=LP.Backpack end)
end)

-- SETTINGS
local SettingsTab = CreateTab("Settings","⚙")
SettingsTab:AddSection("Controls")
SettingsTab:AddLabel("PC:     Right Ctrl = toggle")
SettingsTab:AddLabel("─ button = minimize to icon")
SettingsTab:AddLabel("Mobile: Tap J icon to restore")
SettingsTab:AddLabel("Drag icon or title bar freely")
SettingsTab:AddSection("About")
SettingsTab:AddLabel("Joffer Hub  v1.1")
SettingsTab:AddLabel("Game:  Lumber Tycoon 2")
SettingsTab:AddSection("Danger")
SettingsTab:AddButton("Destroy GUI",function() ScreenGui:Destroy() end)

-- ═══════════════════════════════════════════════════════════════════
-- ACTIVATE FIRST TAB  +  OPEN ANIMATION
-- ═══════════════════════════════════════════════════════════════════
task.defer(function()
    task.wait()
    for _, t in pairs(Tabs) do
        t.Page.Visible=false; t.Indicator.Visible=false
        t.Button.BackgroundTransparency=1; t.Button.TextColor3=T.TextSec
    end
    if Tabs["Player"] then
        local pt=Tabs["Player"]
        pt.Page.Visible=true
        pt.Indicator.Visible=true
        pt.Button.BackgroundTransparency=0.82
        pt.Button.TextColor3=T.TextPri
        ActiveTab=pt
    end
end)

-- Scale-in open animation
Main.Size  = UDim2.new(0, 0, 0, 0)
Main.BackgroundTransparency = 1
TwF(Main, {BackgroundTransparency=0})
TwS(Main, {Size=UDim2.new(0, T.WinW, 0, T.WinH)})
