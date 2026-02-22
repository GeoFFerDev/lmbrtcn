--[[
     ██╗ ██████╗ ███████╗███████╗███████╗██████╗     ██╗  ██╗██╗   ██╗██████╗ 
     ██║██╔═══██╗██╔════╝██╔════╝██╔════╝██╔══██╗    ██║  ██║██║   ██║██╔══██╗
     ██║██║   ██║█████╗  █████╗  █████╗  ██████╔╝    ███████║██║   ██║██████╔╝
██   ██║██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗    ██╔══██║██║   ██║██╔══██╗
╚█████╔╝╚██████╔╝██║     ██║     ███████╗██║  ██║    ██║  ██║╚██████╔╝██████╔╝
 ╚════╝  ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
    Lumber Tycoon 2 — Full Feature Script
    Toggle UI: RightControl
--]]

-- ─────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LP    = Players.LocalPlayer
local Char  = LP.Character or LP.CharacterAdded:Wait()
local Mouse = LP:GetMouse()

-- ─────────────────────────────────────────────────────
-- THEME
-- ─────────────────────────────────────────────────────
local T = {
    WindowBG     = Color3.fromRGB(18,  22,  30),
    SidebarBG    = Color3.fromRGB(13,  16,  24),
    ContentBG    = Color3.fromRGB(22,  28,  38),
    ElementBG    = Color3.fromRGB(28,  35,  50),
    ElementHover = Color3.fromRGB(36,  46,  65),

    Accent       = Color3.fromRGB(0,  200, 180),
    AccentDim    = Color3.fromRGB(0,  140, 125),
    AccentGlow   = Color3.fromRGB(80, 240, 220),

    TextPrimary  = Color3.fromRGB(230, 235, 245),
    TextSecondary= Color3.fromRGB(145, 160, 180),
    TextDisabled = Color3.fromRGB(80,  95,  115),

    ToggleOn     = Color3.fromRGB(0,  200, 180),
    ToggleOff    = Color3.fromRGB(55,  65,  85),
    Thumb        = Color3.fromRGB(235, 240, 255),

    SliderTrack  = Color3.fromRGB(40,  50,  70),
    SliderFill   = Color3.fromRGB(0,  200, 180),

    Separator    = Color3.fromRGB(35,  44,  60),

    Corner       = UDim.new(0, 7),
    SmallCorner  = UDim.new(0, 4),
    SidebarW     = 205,
    RowH         = 38,
}

-- ─────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────
local function New(class, props, children)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then i[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end

local function Corner(p, r)
    return New("UICorner", {CornerRadius = r or T.Corner, Parent = p})
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

local function List(p, dir, pad, align)
    return New("UIListLayout", {
        FillDirection      = dir   or Enum.FillDirection.Vertical,
        Padding            = UDim.new(0, pad or 4),
        SortOrder          = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment= align or Enum.HorizontalAlignment.Left,
        Parent = p
    })
end

local TI  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TIF = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tween(obj, props) TweenService:Create(obj, TI, props):Play() end
local function TweenF(obj, props) TweenService:Create(obj, TIF, props):Play() end

-- ─────────────────────────────────────────────────────
-- DESTROY OLD GUI
-- ─────────────────────────────────────────────────────
pcall(function()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("JofferHub")
        if old then old:Destroy() end
    end
end)

-- ─────────────────────────────────────────────────────
-- BUILD GUI
-- ─────────────────────────────────────────────────────
local guiParent
pcall(function()
    if gethui then guiParent = gethui()
    elseif syn and syn.protect_gui then guiParent = LP.PlayerGui
    else guiParent = LP:WaitForChild("PlayerGui") end
end)
if not guiParent then guiParent = LP:WaitForChild("PlayerGui") end

local ScreenGui = New("ScreenGui", {
    Name             = "JofferHub",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset   = true,
    Parent           = guiParent,
})

-- ── Main window ──────────────────────────────────────
local Main = New("Frame", {
    Name        = "Main",
    Size        = UDim2.new(0, 700, 0, 440),
    Position    = UDim2.new(0.5, -350, 0.5, -220),
    BackgroundColor3 = T.WindowBG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    Parent      = ScreenGui,
})
Corner(Main)
New("UIStroke", {Color = Color3.fromRGB(40,55,75), Thickness = 1, Parent = Main})

-- Drop shadow
local Shadow = New("ImageLabel", {
    Name             = "Shadow",
    Size             = UDim2.new(1, 40, 1, 40),
    Position         = UDim2.new(0, -20, 0, -20),
    BackgroundTransparency = 1,
    Image            = "rbxassetid://6014261993",
    ImageColor3      = Color3.fromRGB(0, 0, 0),
    ImageTransparency= 0.55,
    ScaleType        = Enum.ScaleType.Slice,
    SliceCenter      = Rect.new(49, 49, 450, 450),
    ZIndex           = 0,
    Parent           = Main,
})

-- ── Title bar ────────────────────────────────────────
local TitleBar = New("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = T.SidebarBG,
    BorderSizePixel  = 0,
    ZIndex           = 3,
    Parent           = Main,
})

-- Accent line on bottom of titlebar
New("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = TitleBar,
})

-- Logo dot
New("Frame", {
    Size             = UDim2.new(0, 8, 0, 8),
    Position         = UDim2.new(0, 14, 0.5, -4),
    BackgroundColor3 = T.Accent,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = TitleBar,
    [New("UICorner", {CornerRadius = UDim.new(1, 0)})] = nil,
}, {New("UICorner", {CornerRadius = UDim.new(1, 0)})})

local TitleLbl = New("TextLabel", {
    Text             = "Joffer Hub",
    Size             = UDim2.new(1, -110, 1, 0),
    Position         = UDim2.new(0, 30, 0, 0),
    BackgroundTransparency = 1,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    TextColor3       = T.TextPrimary,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 4,
    Parent           = TitleBar,
})

-- Sub label
New("TextLabel", {
    Text             = "Lumber Tycoon 2",
    Size             = UDim2.new(0, 130, 1, 0),
    Position         = UDim2.new(0, 105, 0, 0),
    BackgroundTransparency = 1,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextColor3       = T.Accent,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 4,
    Parent           = TitleBar,
})

-- Close button
local CloseBtn = New("TextButton", {
    Text             = "✕",
    Size             = UDim2.new(0, 32, 0, 32),
    Position         = UDim2.new(1, -40, 0.5, -16),
    BackgroundColor3 = Color3.fromRGB(200, 70, 70),
    BackgroundTransparency = 0.5,
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextColor3       = T.TextPrimary,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = TitleBar,
})
Corner(CloseBtn, UDim.new(0, 5))
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Minimize button
local MinBtn = New("TextButton", {
    Text             = "─",
    Size             = UDim2.new(0, 32, 0, 32),
    Position         = UDim2.new(1, -76, 0.5, -16),
    BackgroundColor3 = T.ElementBG,
    BackgroundTransparency = 0.3,
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextColor3       = T.TextSecondary,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = TitleBar,
})
Corner(MinBtn, UDim.new(0, 5))

-- ── Drag ─────────────────────────────────────────────
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Body (below titlebar) ─────────────────────────────
local Body = New("Frame", {
    Name             = "Body",
    Size             = UDim2.new(1, 0, 1, -44),
    Position         = UDim2.new(0, 0, 0, 44),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    Parent           = Main,
})

-- ── Sidebar ───────────────────────────────────────────
local Sidebar = New("Frame", {
    Name             = "Sidebar",
    Size             = UDim2.new(0, T.SidebarW, 1, 0),
    BackgroundColor3 = T.SidebarBG,
    BorderSizePixel  = 0,
    Parent           = Body,
})

-- Sidebar right border
New("Frame", {
    Size             = UDim2.new(0, 1, 1, 0),
    Position         = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = T.Separator,
    BorderSizePixel  = 0,
    Parent           = Sidebar,
})

local TabList = New("ScrollingFrame", {
    Name             = "TabList",
    Size             = UDim2.new(1, 0, 1, -8),
    Position         = UDim2.new(0, 0, 0, 8),
    BackgroundTransparency = 1,
    ScrollBarThickness = 0,
    CanvasSize       = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize= Enum.AutomaticSize.Y,
    Parent           = Sidebar,
})
Pad(TabList, 4, 4, 6, 6)
List(TabList, nil, 2)

-- ── Content ───────────────────────────────────────────
local Content = New("Frame", {
    Name             = "Content",
    Size             = UDim2.new(1, -T.SidebarW, 1, 0),
    Position         = UDim2.new(0, T.SidebarW, 0, 0),
    BackgroundColor3 = T.ContentBG,
    BorderSizePixel  = 0,
    Parent           = Body,
})

local PageContainer = New("Frame", {
    Name             = "Pages",
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Parent           = Content,
})

-- ─────────────────────────────────────────────────────
-- TAB / COMPONENT BUILDER
-- ─────────────────────────────────────────────────────
local Tabs       = {}
local ActiveTab  = nil

-- Creates a tab button in sidebar + a page frame in content
local function CreateTab(name, icon)
    -- Sidebar button
    local btn = New("TextButton", {
        Name             = name,
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = T.ElementBG,
        BackgroundTransparency = 1,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextColor3       = T.TextSecondary,
        Text             = (icon and icon.." " or "  ") .. name,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BorderSizePixel  = 0,
        Parent           = TabList,
    })
    Corner(btn, T.SmallCorner)
    Pad(btn, 0, 0, 10, 8)

    -- Active indicator
    local indicator = New("Frame", {
        Size             = UDim2.new(0, 3, 0.6, 0),
        Position         = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Visible          = false,
        Parent           = btn,
    })
    Corner(indicator, UDim.new(0, 2))

    -- Page
    local page = New("ScrollingFrame", {
        Name             = name.."Page",
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize= Enum.AutomaticSize.Y,
        Visible          = false,
        Parent           = PageContainer,
    })
    Pad(page, 10, 10, 12, 12)
    List(page, nil, 5)

    local Tab = {Button = btn, Page = page, Indicator = indicator}

    -- ── AddSection ──────────────────────────────────
    function Tab:AddSection(text)
        local row = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent           = page,
        })
        New("TextLabel", {
            Text             = text:upper(),
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.GothamBold,
            TextSize         = 10,
            TextColor3       = T.Accent,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = row,
        })
        -- line
        New("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = T.Separator,
            BorderSizePixel  = 0,
            Parent           = row,
        })
    end

    -- ── AddToggle ────────────────────────────────────
    function Tab:AddToggle(text, opts, cb)
        opts = opts or {}
        local state = opts.Default or false
        local row = New("Frame", {
            Size             = UDim2.new(1, 0, 0, T.RowH),
            BackgroundColor3 = T.ElementBG,
            BorderSizePixel  = 0,
            Parent           = page,
        })
        Corner(row)

        New("TextLabel", {
            Text             = text,
            Size             = UDim2.new(1, -58, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextColor3       = T.TextPrimary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = row,
        })

        local track = New("Frame", {
            Size             = UDim2.new(0, 40, 0, 22),
            Position         = UDim2.new(1, -52, 0.5, -11),
            BackgroundColor3 = state and T.ToggleOn or T.ToggleOff,
            BorderSizePixel  = 0,
            Parent           = row,
        })
        Corner(track, UDim.new(1, 0))

        local thumb = New("Frame", {
            Size             = UDim2.new(0, 16, 0, 16),
            Position         = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = T.Thumb,
            BorderSizePixel  = 0,
            Parent           = track,
        })
        Corner(thumb, UDim.new(1, 0))

        local function SetState(s)
            state = s
            Tween(track, {BackgroundColor3 = state and T.ToggleOn or T.ToggleOff})
            Tween(thumb, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
            if cb then pcall(cb, state) end
        end

        local btn = New("TextButton", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text             = "",
            Parent           = row,
        })
        btn.MouseButton1Click:Connect(function() SetState(not state) end)
        btn.MouseEnter:Connect(function() Tween(row, {BackgroundColor3 = T.ElementHover}) end)
        btn.MouseLeave:Connect(function() Tween(row, {BackgroundColor3 = T.ElementBG}) end)

        return { Set = SetState, Get = function() return state end }
    end

    -- ── AddSlider ────────────────────────────────────
    function Tab:AddSlider(text, opts, cb)
        opts = opts or {}
        local min  = opts.Min     or 0
        local max  = opts.Max     or 100
        local step = opts.Step    or 1
        local val  = opts.Default or min

        local row = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = T.ElementBG,
            BorderSizePixel  = 0,
            Parent           = page,
        })
        Corner(row)

        local topRow = New("Frame", {
            Size             = UDim2.new(1, -24, 0, 24),
            Position         = UDim2.new(0, 12, 0, 7),
            BackgroundTransparency = 1,
            Parent           = row,
        })

        New("TextLabel", {
            Text             = text,
            Size             = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextColor3       = T.TextPrimary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = topRow,
        })

        local valLbl = New("TextLabel", {
            Text             = tostring(val),
            Size             = UDim2.new(0, 48, 1, 0),
            Position         = UDim2.new(1, -48, 0, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            TextColor3       = T.Accent,
            TextXAlignment   = Enum.TextXAlignment.Right,
            Parent           = topRow,
        })

        -- Track
        local track = New("Frame", {
            Size             = UDim2.new(1, -24, 0, 6),
            Position         = UDim2.new(0, 12, 0, 36),
            BackgroundColor3 = T.SliderTrack,
            BorderSizePixel  = 0,
            Parent           = row,
        })
        Corner(track, UDim.new(1, 0))

        local pct = (val - min) / (max - min)
        local fill = New("Frame", {
            Size             = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = T.SliderFill,
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Parent           = track,
        })
        Corner(fill, UDim.new(1, 0))

        local knob = New("Frame", {
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new(pct, -7, 0.5, -7),
            BackgroundColor3 = T.Thumb,
            BorderSizePixel  = 0,
            ZIndex           = 3,
            Parent           = track,
        })
        Corner(knob, UDim.new(1, 0))

        local function SetValue(v)
            v = math.clamp(math.round((v - min) / step) * step + min, min, max)
            val = v
            local p = (v - min) / (max - min)
            Tween(fill,  {Size     = UDim2.new(p, 0, 1, 0)})
            Tween(knob,  {Position = UDim2.new(p, -7, 0.5, -7)})
            valLbl.Text = tostring(v)
            if cb then pcall(cb, v) end
        end

        local dragging = false
        local function drag(input)
            local rel  = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            SetValue(min + rel * (max - min))
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; drag(i)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then drag(i) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        return { Set = SetValue, Get = function() return val end }
    end

    -- ── AddButton ────────────────────────────────────
    function Tab:AddButton(text, cb)
        local btn = New("TextButton", {
            Size             = UDim2.new(1, 0, 0, T.RowH),
            BackgroundColor3 = T.ElementBG,
            Font             = Enum.Font.GothamBold,
            TextSize         = 13,
            TextColor3       = T.Accent,
            Text             = text,
            BorderSizePixel  = 0,
            Parent           = page,
        })
        Corner(btn)
        New("UIStroke", {Color = T.AccentDim, Thickness = 1, Transparency = 0.4, Parent = btn})

        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = T.ElementHover}) end)
        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = T.ElementBG}) end)
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {BackgroundColor3 = T.AccentDim})
            task.delay(0.15, function() Tween(btn, {BackgroundColor3 = T.ElementBG}) end)
            if cb then pcall(cb) end
        end)
        return btn
    end

    -- ── AddDropdown ──────────────────────────────────
    function Tab:AddDropdown(text, opts, cb)
        opts = opts or {}
        local options = opts.Options or {}
        local current = opts.Default or options[1] or "Select..."
        local open    = false

        local wrapper = New("Frame", {
            Size             = UDim2.new(1, 0, 0, T.RowH),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            Parent           = page,
        })

        local header = New("TextButton", {
            Size             = UDim2.new(1, 0, 0, T.RowH),
            BackgroundColor3 = T.ElementBG,
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextColor3       = T.TextPrimary,
            Text             = "",
            BorderSizePixel  = 0,
            Parent           = wrapper,
        })
        Corner(header)

        New("TextLabel", {
            Text             = text,
            Size             = UDim2.new(0.5, -10, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextColor3       = T.TextPrimary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = header,
        })

        local valLbl = New("TextLabel", {
            Text             = current,
            Size             = UDim2.new(0.5, -30, 1, 0),
            Position         = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T.Accent,
            TextXAlignment   = Enum.TextXAlignment.Right,
            Parent           = header,
        })

        local arrow = New("TextLabel", {
            Text             = "▾",
            Size             = UDim2.new(0, 20, 1, 0),
            Position         = UDim2.new(1, -22, 0, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.GothamBold,
            TextSize         = 13,
            TextColor3       = T.TextSecondary,
            Parent           = header,
        })

        local dropdown = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            Position         = UDim2.new(0, 0, 0, T.RowH + 2),
            BackgroundColor3 = T.ElementBG,
            BorderSizePixel  = 0,
            ClipsDescendants = true,
            Visible          = false,
            ZIndex           = 10,
            Parent           = wrapper,
        })
        Corner(dropdown)
        New("UIStroke", {Color = T.Accent, Thickness = 1, Transparency = 0.6, Parent = dropdown})

        local itemList = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent           = dropdown,
        })
        Pad(itemList, 4, 4, 4, 4)
        List(itemList, nil, 2)

        for _, opt in ipairs(options) do
            local ib = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = T.ElementBG,
                BackgroundTransparency = 1,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.TextSecondary,
                Text             = opt,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BorderSizePixel  = 0,
                ZIndex           = 11,
                Parent           = itemList,
            })
            Pad(ib, 0, 0, 8, 4)
            Corner(ib, T.SmallCorner)
            ib.MouseEnter:Connect(function() ib.TextColor3 = T.TextPrimary end)
            ib.MouseLeave:Connect(function() ib.TextColor3 = T.TextSecondary end)
            ib.MouseButton1Click:Connect(function()
                current = opt
                valLbl.Text = opt
                open = false
                dropdown.Visible = false
                arrow.Text = "▾"
                wrapper.Size = UDim2.new(1, 0, 0, T.RowH)
                if cb then pcall(cb, opt) end
            end)
        end

        header.MouseButton1Click:Connect(function()
            open = not open
            if open then
                local totalH = #options * 34 + 8
                dropdown.Visible = true
                TweenF(dropdown, {Size = UDim2.new(1, 0, 0, totalH)})
                wrapper.Size = UDim2.new(1, 0, 0, T.RowH + totalH + 4)
                arrow.Text = "▴"
            else
                TweenF(dropdown, {Size = UDim2.new(1, 0, 0, 0)})
                task.delay(0.25, function() dropdown.Visible = false end)
                wrapper.Size = UDim2.new(1, 0, 0, T.RowH)
                arrow.Text = "▾"
            end
        end)

        return { Set = function(v) current = v; valLbl.Text = v end, Get = function() return current end }
    end

    -- ── AddLabel ─────────────────────────────────────
    function Tab:AddLabel(text)
        local row = New("Frame", {
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.ElementBG,
            BackgroundTransparency = 0.5,
            BorderSizePixel  = 0,
            Parent           = page,
        })
        Corner(row)
        local lbl = New("TextLabel", {
            Text             = text,
            Size             = UDim2.new(1, -24, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T.TextSecondary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            Parent           = row,
        })
        return { Set = function(v) lbl.Text = v end }
    end

    -- Sidebar click
    btn.MouseButton1Click:Connect(function()
        -- Deactivate all
        for _, t in pairs(Tabs) do
            t.Page.Visible   = false
            t.Indicator.Visible = false
            Tween(t.Button, {BackgroundTransparency = 1, TextColor3 = T.TextSecondary})
        end
        -- Activate this
        page.Visible        = true
        indicator.Visible   = true
        Tween(btn, {BackgroundTransparency = 0.85, TextColor3 = T.TextPrimary})
        ActiveTab = Tab
    end)

    btn.MouseEnter:Connect(function()
        if ActiveTab ~= Tab then
            Tween(btn, {BackgroundTransparency = 0.9, TextColor3 = T.TextSecondary})
        end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= Tab then
            Tween(btn, {BackgroundTransparency = 1, TextColor3 = T.TextSecondary})
        end
    end)

    Tabs[name] = Tab
    return Tab
end

-- Activate first tab helper
local function ActivateFirst()
    for _, t in pairs(Tabs) do
        t.Button:GetPropertyChangedSignal("Visible"):Wait()
    end
end

-- ─────────────────────────────────────────────────────
-- MINIMIZE
-- ─────────────────────────────────────────────────────
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenF(Main, {Size = UDim2.new(0, 700, 0, 44)})
        MinBtn.Text = "□"
    else
        TweenF(Main, {Size = UDim2.new(0, 700, 0, 440)})
        MinBtn.Text = "─"
    end
end)

-- ─────────────────────────────────────────────────────
-- TOGGLE KEY
-- ─────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        Main.Visible = not Main.Visible
    end
end)

-- ═════════════════════════════════════════════════════
-- ██╗  ████████╗██████╗     ███████╗███████╗ █████╗ ████████╗██╗   ██╗██████╗ ███████╗███████╗
-- ██║  ╚══██╔══╝╚════██╗    ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔════╝██╔════╝
-- ██║     ██║    █████╔╝    █████╗  █████╗  ███████║   ██║   ██║   ██║██████╔╝█████╗  ███████╗
-- ██║     ██║   ██╔═══╝     ██╔══╝  ██╔══╝  ██╔══██║   ██║   ██║   ██║██╔══██╗██╔══╝  ╚════██║
-- ███████╗██║   ███████╗    ██║     ███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗███████║
-- ╚══════╝╚═╝   ╚══════╝    ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
-- ═════════════════════════════════════════════════════
-- LUMBER TYCOON 2 — GAME LOGIC
-- ═════════════════════════════════════════════════════

-- Shared state flags
local Flags = {
    Fly        = false,
    Noclip     = false,
    AutoChop   = false,
    AutoSell   = false,
    InfJump    = false,
    SpeedVal   = 16,
    JumpVal    = 50,
    FlySpeed   = 50,
    SelWood    = "Oak",
}

-- Character refresh
LP.CharacterAdded:Connect(function(c)
    Char = c
end)
local function GetChar() return LP.Character end
local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ─────────────────────────────────────────────────────
-- FLY
-- ─────────────────────────────────────────────────────
local flyConn, flyBV, flyBG

local function StartFly()
    local hrp = GetHRP()
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity        = Vector3.zero
    flyBV.MaxForce        = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Parent          = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque       = Vector3.new(9e9, 9e9, 9e9)
    flyBG.CFrame          = hrp.CFrame
    flyBG.Parent          = hrp

    flyConn = RunService.Heartbeat:Connect(function()
        if not Flags.Fly then return end
        local hrp2 = GetHRP()
        if not hrp2 then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Flags.FlySpeed or Vector3.zero
        flyBG.CFrame   = cam.CFrame
    end)
end

local function StopFly()
    if flyConn  then flyConn:Disconnect();  flyConn  = nil end
    if flyBV    then flyBV:Destroy();       flyBV    = nil end
    if flyBG    then flyBG:Destroy();       flyBG    = nil end
end

-- ─────────────────────────────────────────────────────
-- NOCLIP
-- ─────────────────────────────────────────────────────
local noclipConn

local function SetNoclip(state)
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local c = GetChar()
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local c = GetChar()
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────
-- AUTO CHOP
-- ─────────────────────────────────────────────────────
local autoChopConn

local function StartAutoChop()
    autoChopConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoChop then return end
        local hrp = GetHRP()
        if not hrp then return end
        -- Find axe in workspace/player
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if not tool then
            -- Check backpack
            tool = LP.Backpack and LP.Backpack:FindFirstChildOfClass("Tool")
            if tool then
                LP.Character.Humanoid:EquipTool(tool)
            end
        end
        -- Find nearest tree trunk
        local nearest, dist = nil, 80
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("MeshPart") and v.Name == "Trunk" or
               v:IsA("UnionOperation") and v.Name:lower():find("trunk") then
                local d = (hrp.Position - v.Position).Magnitude
                if d < dist then
                    nearest = v; dist = d
                end
            end
        end
        if nearest and tool then
            -- Remote fire chop event if exists
            local remote = ReplicatedStorage:FindFirstChild("Chop", true)
                        or ReplicatedStorage:FindFirstChild("ChopTree", true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(nearest)
            end
        end
    end)
end

local function StopAutoChop()
    if autoChopConn then autoChopConn:Disconnect(); autoChopConn = nil end
end

-- ─────────────────────────────────────────────────────
-- AUTO SELL
-- ─────────────────────────────────────────────────────
local autoSellConn

local function StartAutoSell()
    autoSellConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoSell then return end
        -- Try to find the sawmill/sell board remote
        local sellRemote = ReplicatedStorage:FindFirstChild("SellWood", true)
                        or ReplicatedStorage:FindFirstChild("Sell",     true)
        if sellRemote and sellRemote:IsA("RemoteEvent") then
            sellRemote:FireServer()
        end
    end)
end

local function StopAutoSell()
    if autoSellConn then autoSellConn:Disconnect(); autoSellConn = nil end
end

-- ─────────────────────────────────────────────────────
-- TELEPORT LOCATIONS
-- ─────────────────────────────────────────────────────
local Locations = {
    ["Base"]            = CFrame.new(108,  5,  -79),
    ["Wood R Us"]       = CFrame.new(160,  5, -275),
    ["Link's Logic"]    = CFrame.new(-6,   5, -276),
    ["Fancy Furnishings"]= CFrame.new(183, 5,   66),
    ["Spawn"]           = CFrame.new(0,    5,    0),
    ["Swamp Biome"]     = CFrame.new(-1250, 90, -520),
    ["Volcano Biome"]   = CFrame.new(1870, 168, -1530),
    ["Snow Biome"]      = CFrame.new(-1200, 60, 1200),
}

local function TeleportTo(name)
    local cf = Locations[name]
    if not cf then return end
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = cf
    end
end

-- ─────────────────────────────────────────────────────
-- WOOD DUPE (Teleport loaded wood to sawmill)
-- ─────────────────────────────────────────────────────
local function DupeWood()
    local hrp = GetHRP()
    if not hrp then return end
    -- Save original pos
    local orig = hrp.CFrame
    -- Move wood on plot to sawmill area
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("TreeRegion") then
            local p = v:FindFirstChild("PrimaryPart") or v.PrimaryPart
            if p then
                pcall(function()
                    v:SetPrimaryPartCFrame(CFrame.new(160, 5, -275))
                end)
            end
        end
    end
end

-- ─────────────────────────────────────────────────────
-- TOOL GRAB (Pick up items on floor)
-- ─────────────────────────────────────────────────────
local function GrabNearbyTools()
    local hrp = GetHRP()
    if not hrp then return end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and not v.Parent:IsA("Model") then
            local h = v:FindFirstChild("Handle")
            if h and (hrp.Position - h.Position).Magnitude < 30 then
                pcall(function() v.Parent = LP.Backpack end)
            end
        end
    end
end

-- ─────────────────────────────────────────────────────
-- BIG MONEY PRINT
-- ─────────────────────────────────────────────────────
local function BigMoneyPrint()
    -- Increase money print output (modifies local print value)
    local remote = ReplicatedStorage:FindFirstChild("MoneyPrint", true)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(9e9)
    end
end

-- ═════════════════════════════════════════════════════
-- BUILD UI TABS
-- ═════════════════════════════════════════════════════

-- ── TAB: PLAYER ──────────────────────────────────────
local PlayerTab = CreateTab("Player", "👤")

PlayerTab:AddSection("Movement")

local speedSlider = PlayerTab:AddSlider("Walk Speed", {Min=1, Max=150, Default=16, Step=1}, function(v)
    Flags.SpeedVal = v
    local hum = GetHum()
    if hum then hum.WalkSpeed = v end
end)

local jumpSlider = PlayerTab:AddSlider("Jump Power", {Min=0, Max=250, Default=50, Step=1}, function(v)
    Flags.JumpVal = v
    local hum = GetHum()
    if hum then hum.JumpPower = v end
end)

PlayerTab:AddToggle("Infinite Jump", {Default=false}, function(v)
    Flags.InfJump = v
end)

PlayerTab:AddToggle("Noclip", {Default=false}, function(v)
    Flags.Noclip = v
    SetNoclip(v)
end)

PlayerTab:AddSection("Flight")

local flySpeedSlider = PlayerTab:AddSlider("Fly Speed", {Min=10, Max=300, Default=50, Step=5}, function(v)
    Flags.FlySpeed = v
end)

PlayerTab:AddToggle("Fly", {Default=false}, function(v)
    Flags.Fly = v
    if v then StartFly() else StopFly() end
end)

PlayerTab:AddSection("Misc")

PlayerTab:AddButton("Reset Character", function()
    local hum = GetHum()
    if hum then hum.Health = 0 end
end)

PlayerTab:AddButton("Grab Nearby Tools", function()
    GrabNearbyTools()
end)

-- Keep speed/jump applied on respawn
LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = Flags.SpeedVal
        hum.JumpPower = Flags.JumpVal
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if Flags.InfJump then
        local hum = GetHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── TAB: WORLD ────────────────────────────────────────
local WorldTab = CreateTab("World", "🌍")

WorldTab:AddSection("Teleport To Location")

local locOpts = {}
for name in pairs(Locations) do table.insert(locOpts, name) end

local locDrop = WorldTab:AddDropdown("Select Location", {Options=locOpts, Default=locOpts[1]})

WorldTab:AddButton("Teleport ▶", function()
    TeleportTo(locDrop:Get())
end)

WorldTab:AddSection("Quick Teleports")

WorldTab:AddButton("→ Base", function() TeleportTo("Base") end)
WorldTab:AddButton("→ Wood R Us (Shop)", function() TeleportTo("Wood R Us") end)
WorldTab:AddButton("→ Fancy Furnishings", function() TeleportTo("Fancy Furnishings") end)
WorldTab:AddButton("→ Swamp Biome", function() TeleportTo("Swamp Biome") end)
WorldTab:AddButton("→ Volcano Biome", function() TeleportTo("Volcano Biome") end)
WorldTab:AddButton("→ Snow Biome", function() TeleportTo("Snow Biome") end)

-- ── TAB: WOOD ─────────────────────────────────────────
local WoodTab = CreateTab("Wood", "🪵")

WoodTab:AddSection("Auto Chop")

local woodTypes = {"Oak","Birch","Walnut","Spooky","Elm","Snowglow","Lava","Palm","Pine","Koa","Fir","Volcano","Sinister"}

local woodDrop = WoodTab:AddDropdown("Target Wood Type", {Options=woodTypes, Default="Oak"}, function(v)
    Flags.SelWood = v
end)

WoodTab:AddToggle("Auto Chop", {Default=false}, function(v)
    Flags.AutoChop = v
    if v then StartAutoChop() else StopAutoChop() end
end)

WoodTab:AddSection("Wood Actions")

WoodTab:AddButton("Collect All Wood (Plot → Sawmill)", function()
    DupeWood()
end)

WoodTab:AddButton("Teleport Wood to Sawmill", function()
    local hrp = GetHRP()
    if not hrp then return end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("tree") then
            pcall(function()
                v:SetPrimaryPartCFrame(CFrame.new(160, 5, -275))
            end)
        end
    end
end)

WoodTab:AddSection("Tree Info")
local treeCountLabel = WoodTab:AddLabel("Trees on plot: 0")

WoodTab:AddButton("Count Trees", function()
    local count = 0
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("trunk") then
            count = count + 1
        end
    end
    treeCountLabel:Set("Trees found in Workspace: " .. count)
end)

-- ── TAB: AUTO BUY ─────────────────────────────────────
local AutoBuyTab = CreateTab("Auto Buy", "💰")

AutoBuyTab:AddSection("Sawmill & Tools")

AutoBuyTab:AddButton("Buy Basic Sawmill", function()
    local remote = ReplicatedStorage:FindFirstChild("Purchase", true)
    if remote then remote:FireServer("BasicSawmill") end
end)

AutoBuyTab:AddButton("Buy Better Axe", function()
    local remote = ReplicatedStorage:FindFirstChild("Purchase", true)
    if remote then remote:FireServer("BetterAxe") end
end)

AutoBuyTab:AddButton("Buy End Times Axe", function()
    local remote = ReplicatedStorage:FindFirstChild("Purchase", true)
    if remote then remote:FireServer("EndTimesAxe") end
end)

AutoBuyTab:AddSection("Auto Sell")

AutoBuyTab:AddToggle("Auto Sell Wood", {Default=false}, function(v)
    Flags.AutoSell = v
    if v then StartAutoSell() else StopAutoSell() end
end)

AutoBuyTab:AddLabel("Fires sell remote periodically")

AutoBuyTab:AddSection("Money")

AutoBuyTab:AddButton("Money Print Exploit", function()
    BigMoneyPrint()
end)

-- ── TAB: DUPE ─────────────────────────────────────────
local DupeTab = CreateTab("Dupe", "📦")

DupeTab:AddSection("Wood Dupe")

DupeTab:AddLabel("Teleport loaded logs near sawmill to sell instantly")

DupeTab:AddButton("Dupe Wood (Teleport to Sell)", function()
    DupeWood()
end)

DupeTab:AddButton("Dupe + Sell", function()
    DupeWood()
    task.wait(0.5)
    local sellRemote = ReplicatedStorage:FindFirstChild("SellWood", true)
    if sellRemote then sellRemote:FireServer() end
end)

DupeTab:AddSection("Item Dupe")

DupeTab:AddLabel("Drop item → script picks it back up:")

DupeTab:AddButton("Re-grab Dropped Items", function()
    GrabNearbyTools()
end)

DupeTab:AddButton("Dupe Held Tool", function()
    local char = GetChar()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    -- Clone to backpack = soft dupe
    pcall(function()
        local clone = tool:Clone()
        clone.Parent = LP.Backpack
    end)
end)

-- ── TAB: SETTINGS ─────────────────────────────────────
local SettingsTab = CreateTab("Settings", "⚙")

SettingsTab:AddSection("Interface")

SettingsTab:AddLabel("Toggle UI: Right Ctrl")

SettingsTab:AddButton("Minimize Window", function()
    MinBtn:GetPropertyChangedSignal("Text"):Wait()
end)

SettingsTab:AddSection("Script Info")

SettingsTab:AddLabel("Joffer Hub v1.0")
SettingsTab:AddLabel("Game: Lumber Tycoon 2")
SettingsTab:AddLabel("Author: Joffer")

SettingsTab:AddSection("Danger Zone")

SettingsTab:AddButton("Destroy GUI", function()
    ScreenGui:Destroy()
end)

-- ─────────────────────────────────────────────────────
-- ACTIVATE FIRST TAB
-- ─────────────────────────────────────────────────────
task.defer(function()
    if Tabs["Player"] then
        Tabs["Player"].Button:GetPropertyChangedSignal("Parent"):Wait()
    end
    task.wait(0.05)
    -- Click first tab
    for _, t in pairs(Tabs) do
        t.Page.Visible   = false
        t.Indicator.Visible = false
        Tween(t.Button, {BackgroundTransparency = 1, TextColor3 = T.TextSecondary})
    end
    if Tabs["Player"] then
        Tabs["Player"].Page.Visible       = true
        Tabs["Player"].Indicator.Visible  = true
        Tween(Tabs["Player"].Button, {BackgroundTransparency = 0.85, TextColor3 = T.TextPrimary})
        ActiveTab = Tabs["Player"]
    end
end)

-- Animate in
Main.Size = UDim2.new(0, 0, 0, 0)
Main.BackgroundTransparency = 1
TweenF(Main, {Size = UDim2.new(0, 700, 0, 440), BackgroundTransparency = 0})
