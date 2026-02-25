--[[
     ██╗ ██████╗ ███████╗███████╗███████╗██████╗     ██╗  ██╗██╗   ██╗██████╗ 
     ██║██╔═══██╗██╔════╝██╔════╝██╔════╝██╔══██╗    ██║  ██║██║   ██║██╔══██╗
     ██║██║   ██║█████╗  █████╗  █████╗  ██████╔╝    ███████║██║   ██║██████╔╝
██   ██║██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗    ██╔══██║██║   ██║██╔══██╗
╚█████╔╝╚██████╔╝██║     ██║     ███████╗██║  ██║    ██║  ██║╚██████╔╝██████╔╝
 ╚════╝  ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
    Lumber Tycoon 2  |  Toggle: RightCtrl  |  Mobile: tap floating icon
    v2.0  |  Logic rebuilt from game source (rbxlx decompile)
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
-- DRAG HELPER
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
-- FLOATING ICON
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

-- Title Bar
local TBar = New("Frame", {
    Size             = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.SidebarBG,
    BorderSizePixel  = 0,
    ZIndex           = 6,
    Parent           = Main,
})
New("Frame", {
    Size             = UDim2.new(1,0,0,1),
    Position         = UDim2.new(0,0,1,-1),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.55,
    BorderSizePixel  = 0,
    ZIndex           = 7,
    Parent           = TBar,
})

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

MakeDraggable(TBar, Main)

local CloseBtn = New("TextButton", {
    Text="✕", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-34,0.5,-14),
    BackgroundColor3=Color3.fromRGB(185,55,55), BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextPri,
    BorderSizePixel=0, ZIndex=8, Parent=TBar,
})
Corner(CloseBtn, UDim.new(0, 5))

local MinBtn = New("TextButton", {
    Text="─", Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-66,0.5,-14),
    BackgroundColor3=T.ElementBG, BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextSec,
    BorderSizePixel=0, ZIndex=8, Parent=TBar,
})
Corner(MinBtn, UDim.new(0, 5))

-- Body
local Body = New("Frame", {
    Size=UDim2.new(1,0,1,-40), Position=UDim2.new(0,0,0,40),
    BackgroundTransparency=1, BorderSizePixel=0, Parent=Main,
})

-- Sidebar
local Sidebar = New("Frame", {
    Size=UDim2.new(0,T.SidebarW,1,0),
    BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Parent=Body,
})
New("Frame", {
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

-- Content
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
    minimized    = false
    Icon.Visible = false
    Main.Visible = true
    Main.Size    = UDim2.new(0, 0, 0, 0)
    TwS(Main, {Size = UDim2.new(0, T.WinW, 0, T.WinH)})
end

local function ShowIcon()
    minimized = true
    local abs = MinBtn.AbsolutePosition
    Icon.Position = UDim2.new(0, abs.X, 0, abs.Y)
    TwF(Main, {Size = UDim2.new(0, 0, 0, 0)})
    task.delay(0.22, function()
        Main.Visible = false
        Icon.Visible = true
        Icon.Size    = UDim2.new(0, 0, 0, 0)
        Icon.Position= UDim2.new(0, 18, 0.5, -28)
        TwS(Icon, {Size = UDim2.new(0, 56, 0, 56)})
    end)
end

MinBtn.MouseButton1Click:Connect(ShowIcon)
MinBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then ShowIcon() end
end)

IconBtn.MouseButton1Click:Connect(function() if minimized then ShowMain() end end)
IconBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch and minimized then ShowMain() end
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
CloseBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then ScreenGui:Destroy() end
end)

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
-- GAME LOGIC  ─  Lumber Tycoon 2
-- Source-accurate remotes from game rbxlx decompile:
--   • ClientInteracted  → RS.Interaction.ClientInteracted:FireServer(part, type, cf)
--   • RemoteProxy       → RS.Interaction.RemoteProxy:FireServer(buttonPart)
--   • ConfirmIdentity   → RS.Interaction.ConfirmIdentity:InvokeServer(tool, name)
--   • PlayerChatted     → RS.NPCDialog.PlayerChatted:InvokeServer(npc, choice)
--   • SetChattingValue  → RS.NPCDialog.SetChattingValue:InvokeServer(n)
-- ═══════════════════════════════════════════════════════════════════
local Flags = {
    Fly=false, Noclip=false, AutoChop=false, AutoSell=false,
    InfJump=false, SpeedVal=16, JumpVal=50, FlySpeed=50,
    SelWood="Oak", ChopRadius=60,
}

-- Cached remotes (confirmed via game source)
local RS = ReplicatedStorage
local Interaction    = RS:WaitForChild("Interaction", 5)
local ClientInteracted  = Interaction and Interaction:FindFirstChild("ClientInteracted")
local RemoteProxy       = Interaction and Interaction:FindFirstChild("RemoteProxy")
local NPCDialog         = RS:FindFirstChild("NPCDialog")

local function GetChar() return LP.Character end
local function GetHRP()  local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum()  local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function GetAxe()
    local c = GetChar()
    if not c then return nil end
    -- Check character first (equipped), then backpack
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("ToolName") then return v end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then return v end
        end
    end
    return nil
end

LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=Flags.SpeedVal; h.JumpPower=Flags.JumpVal end
end)

-- ─── FLY ──────────────────────────────────────────────────────────
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

-- ─── NOCLIP ───────────────────────────────────────────────────────
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

-- ─── INFINITE JUMP ────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if Flags.InfJump then
        local h=GetHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ─── AUTO CHOP ────────────────────────────────────────────────────
-- Uses RS.Interaction.ClientInteracted:FireServer(part, "Axe chop", CFrame)
-- This is the actual remote the axe tool fires on tree section hits.
-- Server validates tool ownership via ConfirmIdentity – axe must be equipped.
local autoChopConn
local chopCooldown = 0

local function FindNearestWoodSection()
    local hrp = GetHRP()
    if not hrp then return nil end
    local nearest, best = nil, Flags.ChopRadius
    -- WoodSection is the part name used on all tree sections in LT2
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "WoodSection" then
            -- Filter by selected wood type if parent model name matches
            local mdl = v:FindFirstAncestorOfClass("Model")
            if mdl then
                local nameMatch = (Flags.SelWood == "Any") or 
                                  (mdl.Name:lower():find(Flags.SelWood:lower()) ~= nil)
                if nameMatch then
                    local d = (hrp.Position - v.Position).Magnitude
                    if d < best then best=d; nearest=v end
                end
            end
        end
    end
    return nearest
end

local function StartAutoChop()
    autoChopConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoChop then return end
        local now = tick()
        if now - chopCooldown < 0.25 then return end
        chopCooldown = now

        local hrp = GetHRP()
        if not hrp then return end

        local target = FindNearestWoodSection()
        if not target then return end

        -- Equip an axe if available but not yet equipped
        local axe = GetAxe()
        local equipped = GetChar() and GetChar():FindFirstChildOfClass("Tool")
        if axe and (not equipped or not equipped:FindFirstChild("ToolName")) then
            pcall(function()
                local hum = GetHum()
                if hum then hum:EquipTool(axe) end
            end)
            task.wait(0.1)
        end

        -- Teleport close to the target
        local dir = (hrp.Position - target.Position)
        if dir.Magnitude > 0 then
            dir = dir.Unit
        else
            dir = Vector3.new(1,0,0)
        end
        hrp.CFrame = CFrame.new(target.Position + dir * 5 + Vector3.new(0, 3, 0))

        -- Fire the ClientInteracted remote exactly as the axe does
        if ClientInteracted then
            pcall(function()
                ClientInteracted:FireServer(target, "Axe chop", target.CFrame)
            end)
        else
            -- Fallback: activate the equipped tool
            local tool = GetChar() and GetChar():FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end)
end

local function StopAutoChop()
    if autoChopConn then autoChopConn:Disconnect(); autoChopConn=nil end
end

-- ─── MOVE WOOD TO DROPOFF ─────────────────────────────────────────
-- Wood Dropoff zone in LT2 is near the bridge at approximately (316, 10, -77).
-- Planks/logs that enter this zone are automatically sold by the server.
local DROPOFF_POS = Vector3.new(316, 10, -77)

local function MoveWoodToDropoff()
    local sold = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "WoodSection" then
            -- Only move wood that belongs to us (check Owner stringvalue)
            local ownerVal = v:FindFirstChild("Owner") or
                             (v.Parent and v.Parent:FindFirstChild("Owner"))
            local isOurs = false
            if ownerVal and ownerVal:IsA("StringValue") then
                isOurs = (ownerVal.Value == LP.Name)
            elseif ownerVal and ownerVal:IsA("ObjectValue") then
                isOurs = (ownerVal.Value == LP)
            else
                -- Try checking model owner
                local mdl = v:FindFirstAncestorOfClass("Model")
                if mdl then
                    local mo = mdl:FindFirstChild("Owner")
                    if mo then
                        isOurs = (mo.Value == LP.Name or mo.Value == LP)
                    end
                end
            end
            if isOurs then
                pcall(function()
                    v.CFrame = CFrame.new(DROPOFF_POS + Vector3.new(math.random(-2,2), 1, math.random(-2,2)))
                end)
                sold = sold + 1
            end
        end
    end
    return sold
end

-- ─── AUTO SELL LOOP ───────────────────────────────────────────────
-- Continuously moves owned WoodSections to the Wood Dropoff zone.
local autoSellConn
local sellCooldown = 0

local function StartAutoSell()
    autoSellConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoSell then return end
        local now = tick()
        if now - sellCooldown < 2.0 then return end
        sellCooldown = now
        MoveWoodToDropoff()
    end)
end
local function StopAutoSell()
    if autoSellConn then autoSellConn:Disconnect(); autoSellConn=nil end
end

-- ─── INTERACT WITH OBJECT ─────────────────────────────────────────
-- Fires RemoteProxy on a ButtonRemote part – used for sawmill, doors, etc.
-- From game source: RemoteProxy proxies BindableEvent ButtonRemote_* children.
local function FireButtonOnPart(part)
    if RemoteProxy then
        pcall(function() RemoteProxy:FireServer(part) end)
    end
end

-- Find a ButtonRemote part by keyword near a position
local function FindButtonNear(keyword, pos, radius)
    pos = pos or (GetHRP() and GetHRP().Position) or Vector3.zero
    radius = radius or 60
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BindableEvent") and v.Name:lower():find(keyword:lower()) then
            local bp = v.Parent
            if bp and bp:IsA("BasePart") then
                if (bp.Position - pos).Magnitude < radius then
                    return bp
                end
            end
        end
    end
    return nil
end

-- ─── TELEPORT ─────────────────────────────────────────────────────
-- Verified from the map layout; these are approximate spawn-safe positions.
local Locations = {
    ["Base"]              = CFrame.new(108,   5,  -79),
    ["Wood R Us"]         = CFrame.new(160,   5, -275),
    ["Link's Logic"]      = CFrame.new(-6,    5, -276),
    ["Fancy Furnishings"] = CFrame.new(183,   5,   66),
    ["Land Store"]        = CFrame.new(94,    5,  -10),
    ["Spawn"]             = CFrame.new(0,     5,    0),
    ["Swamp Biome"]       = CFrame.new(-1250, 90, -520),
    ["Volcano Biome"]     = CFrame.new(1870, 168,-1530),
    ["Snow Biome"]        = CFrame.new(-1200, 60, 1200),
    ["Wood Dropoff"]      = CFrame.new(316,   10,  -77),
    ["Sawmill Area"]      = CFrame.new(200,   5,  -70),
}

local function TeleportTo(name)
    local cf = Locations[name]; if not cf then return end
    local hrp = GetHRP()
    if hrp then
        -- Use PivotTo if character model exists, fallback to CFrame set
        local c = GetChar()
        if c and c.PrimaryPart then
            pcall(function() c:PivotTo(cf) end)
        else
            hrp.CFrame = cf
        end
    end
end

-- ─── SHOP: INTERACT WITH NPC ──────────────────────────────────────
-- LT2 shop purchases go through the NPC dialogue system:
--   1. Walk up to shop NPC → RS.NPCDialog.PromptChat fires OnClientEvent
--   2. Player picks dialogue option → RS.NPCDialog.PlayerChatted:InvokeServer(npc, choice)
-- We simulate by firing ClientInteracted on the NPC's interactive part,
-- which triggers PromptChat serverside.
local function InteractWithNearbyNPC(shopName)
    local hrp = GetHRP()
    if not hrp then return false end
    -- Find an NPC model matching the shop name
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find(shopName:lower()) then
            local root = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart or
                         v:FindFirstChildWhichIsA("BasePart")
            if root then
                -- Teleport close
                hrp.CFrame = CFrame.new(root.Position + Vector3.new(0,0,5))
                task.wait(0.3)
                -- Fire ClientInteracted on the NPC part
                if ClientInteracted then
                    pcall(function()
                        ClientInteracted:FireServer(root, "NPC interact", root.CFrame)
                    end)
                end
                return true
            end
        end
    end
    return false
end

-- ─── DUPE WOOD ────────────────────────────────────────────────────
-- Teleports all loaded WoodSection parts that match our ownership
-- directly to the Wood Dropoff, effectively insta-selling.
local function DupeAndSell()
    local n = MoveWoodToDropoff()
    return n
end

-- ─── GRAB TOOLS ───────────────────────────────────────────────────
local function GrabTools()
    local hrp = GetHRP(); if not hrp then return end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and not v.Parent:IsA("Model") then
            local h = v:FindFirstChild("Handle")
            if h and (hrp.Position - h.Position).Magnitude < 30 then
                pcall(function() v.Parent = LP.Backpack end)
            end
        end
    end
end

-- ─── MONEY DISPLAY ────────────────────────────────────────────────
local function GetMoney()
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local m = ls:FindFirstChild("Money")
        if m then return m.Value end
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════════════
-- BUILD TABS
-- ═══════════════════════════════════════════════════════════════════

-- ── PLAYER TAB ────────────────────────────────────────────────────
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
do
    local moneyLbl = PlayerTab:AddLabel("💰 Money: loading...")
    LP.leaderstats and LP.leaderstats:WaitForChild("Money",3)
    -- update money display every 2s
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            pcall(function()
                local m = GetMoney()
                moneyLbl:Set(("💰 Money: $%s"):format(tostring(m)))
            end)
            task.wait(2)
        end
    end)
end

-- ── WORLD TAB ─────────────────────────────────────────────────────
local WorldTab = CreateTab("World","🌍")
WorldTab:AddSection("Teleport")
local locOpts = {}
for name in pairs(Locations) do table.insert(locOpts, name) end
local locDrop = WorldTab:AddDropdown("Select Location",{Options=locOpts, Default=locOpts[1]})
WorldTab:AddButton("Teleport ▶", function() TeleportTo(locDrop:Get()) end)
WorldTab:AddSection("Quick Jumps")
WorldTab:AddButton("→ Base",              function() TeleportTo("Base")             end)
WorldTab:AddButton("→ Wood R Us",         function() TeleportTo("Wood R Us")        end)
WorldTab:AddButton("→ Fancy Furnishings", function() TeleportTo("Fancy Furnishings") end)
WorldTab:AddButton("→ Wood Dropoff",      function() TeleportTo("Wood Dropoff")     end)
WorldTab:AddButton("→ Swamp Biome",       function() TeleportTo("Swamp Biome")      end)
WorldTab:AddButton("→ Volcano Biome",     function() TeleportTo("Volcano Biome")    end)
WorldTab:AddButton("→ Snow Biome",        function() TeleportTo("Snow Biome")       end)

-- ── WOOD TAB ──────────────────────────────────────────────────────
local WoodTab = CreateTab("Wood","🪵")
WoodTab:AddSection("Auto Chop")
WoodTab:AddLabel("Equip an axe first. Uses real ClientInteracted remote.")
local woodTypes = {"Any","Oak","Birch","Walnut","Spooky","Elm","SnowGlow","Lava","Palm","Pine","Koa","Fir","Volcano","Sinister","Cherry","CaveCrawler"}
WoodTab:AddDropdown("Target Wood",{Options=woodTypes, Default="Any"},function(v)
    Flags.SelWood = v
end)
WoodTab:AddSlider("Chop Radius",{Min=10,Max=150,Default=60,Step=5},function(v)
    Flags.ChopRadius = v
end)
WoodTab:AddToggle("Auto Chop",{Default=false},function(v)
    Flags.AutoChop=v; if v then StartAutoChop() else StopAutoChop() end
end)
WoodTab:AddSection("Sell Wood")
WoodTab:AddLabel("Teleports owned WoodSections to the Dropoff zone.")
WoodTab:AddToggle("Auto Sell (loop)",{Default=false},function(v)
    Flags.AutoSell=v; if v then StartAutoSell() else StopAutoSell() end
end)
local sellResultLbl = WoodTab:AddLabel("Press button to sell now")
WoodTab:AddButton("Sell Wood Now ▶",function()
    local n = MoveWoodToDropoff()
    sellResultLbl:Set(("Moved %d WoodSections to Dropoff"):format(n))
end)
WoodTab:AddSection("Tree Scanner")
local treeLbl = WoodTab:AddLabel("Press button to scan trees")
WoodTab:AddButton("Count Nearby Trees",function()
    local hrp = GetHRP()
    local n = 0
    local types = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "WoodSection" then
            if not hrp or (hrp.Position - v.Position).Magnitude < Flags.ChopRadius then
                n = n + 1
                local mdl = v:FindFirstAncestorOfClass("Model")
                if mdl then types[mdl.Name] = (types[mdl.Name] or 0) + 1 end
            end
        end
    end
    treeLbl:Set(("Found %d WoodSections in radius"):format(n))
end)

-- ── AUTO BUY TAB ──────────────────────────────────────────────────
local AutoBuyTab = CreateTab("Auto Buy","💰")
AutoBuyTab:AddSection("Shop NPC Interaction")
AutoBuyTab:AddLabel("Teleports you to NPC & opens dialogue via ClientInteracted.")
AutoBuyTab:AddButton("Go to Wood R Us",function()
    TeleportTo("Wood R Us")
    task.wait(0.8)
    -- Try to interact with the shop NPC (Bob)
    InteractWithNearbyNPC("Bob")
end)
AutoBuyTab:AddButton("Go to Fancy Furnishings",function()
    TeleportTo("Fancy Furnishings")
    task.wait(0.8)
    InteractWithNearbyNPC("Thom")
end)
AutoBuyTab:AddButton("Go to Link's Logic",function()
    TeleportTo("Link's Logic")
    task.wait(0.8)
    InteractWithNearbyNPC("Link")
end)
AutoBuyTab:AddSection("Auto Sell Wood")
AutoBuyTab:AddToggle("Auto Sell Wood (loop)",{Default=false},function(v)
    Flags.AutoSell=v; if v then StartAutoSell() else StopAutoSell() end
end)
AutoBuyTab:AddLabel("Moves owned logs to Dropoff zone ($)")
AutoBuyTab:AddSection("Quick Actions")
AutoBuyTab:AddButton("Instant Sell All Wood",function()
    local n = DupeAndSell()
    -- Also try walking to dropoff to trigger the server zone
    if n > 0 then
        TeleportTo("Wood Dropoff")
    end
end)

-- ── DUPE TAB ──────────────────────────────────────────────────────
local DupeTab = CreateTab("Dupe","📦")
DupeTab:AddSection("Wood Teleport")
DupeTab:AddLabel("Moves your owned WoodSections to the Dropoff area.")
DupeTab:AddButton("Dupe Wood → Dropoff", function()
    local n = MoveWoodToDropoff()
    if n > 0 then
        task.wait(0.3)
        TeleportTo("Wood Dropoff")
    end
end)
DupeTab:AddButton("Dupe + Walk to Dropoff",function()
    MoveWoodToDropoff()
    task.wait(0.5)
    TeleportTo("Wood Dropoff")
    task.wait(0.5)
    -- Fire button on nearby sell zone if found
    local btn = FindButtonNear("Button", GetHRP() and GetHRP().Position, 40)
    if btn then FireButtonOnPart(btn) end
end)
DupeTab:AddSection("Item Recovery")
DupeTab:AddButton("Re-grab Dropped Items", GrabTools)
DupeTab:AddButton("Clone Held Tool",function()
    local c = GetChar(); if not c then return end
    local t = c:FindFirstChildOfClass("Tool"); if not t then return end
    pcall(function() t:Clone().Parent = LP.Backpack end)
end)
DupeTab:AddSection("RemoteProxy Interact")
DupeTab:AddLabel("Fires RemoteProxy on ButtonRemote part at cursor target.")
DupeTab:AddButton("Interact Mouse Target",function()
    local target = Mouse.Target
    if target then
        -- Look for ButtonRemote BindableEvent on or near the target
        local function findBtn(part)
            for _, c in ipairs(part:GetChildren()) do
                if c:IsA("BindableEvent") and c.Name:find("ButtonRemote_") then
                    return part
                end
            end
            if part.Parent and part.Parent ~= Workspace then
                return findBtn(part.Parent)
            end
            return nil
        end
        local btnPart = findBtn(target)
        if btnPart then
            FireButtonOnPart(btnPart)
        end
    end
end)

-- ── SETTINGS TAB ──────────────────────────────────────────────────
local SettingsTab = CreateTab("Settings","⚙")
SettingsTab:AddSection("Controls")
SettingsTab:AddLabel("PC:     Right Ctrl = toggle GUI")
SettingsTab:AddLabel("─ button = minimize to icon")
SettingsTab:AddLabel("Mobile: Tap J icon to restore")
SettingsTab:AddLabel("Drag icon or title bar freely")
SettingsTab:AddSection("About")
SettingsTab:AddLabel("Joffer Hub  v2.0  |  LT2")
SettingsTab:AddLabel("Logic: rebuilt from game source")
SettingsTab:AddLabel("Remotes: ClientInteracted / Proxy")
SettingsTab:AddSection("Danger Zone")
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
    local pt = Tabs["Player"]
    if pt then
        pt.Page.Visible=true
        pt.Indicator.Visible=true
        pt.Button.BackgroundTransparency=0.82
        pt.Button.TextColor3=T.TextPri
        ActiveTab=pt
    end
end)

Main.Size  = UDim2.new(0, 0, 0, 0)
Main.BackgroundTransparency = 1
TwF(Main, {BackgroundTransparency=0})
TwS(Main, {Size=UDim2.new(0, T.WinW, 0, T.WinH)})
