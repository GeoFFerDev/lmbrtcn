--[[
    ██████╗ ██╗   ██╗████████╗████████╗███████╗██████╗     ██╗  ██╗██╗   ██╗██████╗ 
    ██╔══██╗██║   ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗    ██║  ██║██║   ██║██╔══██╗
    ██████╔╝██║   ██║   ██║      ██║   █████╗  ██████╔╝    ███████║██║   ██║██████╔╝
    ██╔══██╗██║   ██║   ██║      ██║   ██╔══╝  ██╔══██╗    ██╔══██║██║   ██║██╔══██╗
    ██████╔╝╚██████╔╝   ██║      ██║   ███████╗██║  ██║    ██║  ██║╚██████╔╝██████╔╝
    ╚═════╝  ╚═════╝    ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
    
    Fluid, responsive UI library.
    No heavy blur/glow effects — lightweight and clean.
    
    USAGE:
        local Hub = loadstring(...)() -- or require / dofile
        
        local Window = Hub:CreateWindow("Butter Hub")
        
        local Tab = Window:AddTab("Player", "rbxassetid://...")
        
        Tab:AddSection("Movement Sliders")
        Tab:AddSlider("Walk speed",   {Min=1, Max=100, Default=16},  function(v) ... end)
        Tab:AddToggle("Fly",          {Default=false},               function(v) ... end)
        Tab:AddButton("Teleport",                                    function()  ... end)
        Tab:AddDropdown("Select Tree",{Options={"Oak","Pine"}},      function(v) ... end)
        Tab:AddKeybind("Fly keybind", {Default=Enum.KeyCode.Q},      function(k) ... end)
        Tab:AddLabel("Price amount: $12")
]]

-- ──────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ──────────────────────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ──────────────────────────────────────────────────────────────────────────────
-- THEME  (edit here to reskin)
-- ──────────────────────────────────────────────────────────────────────────────
local Theme = {
    -- Backgrounds
    WindowBG        = Color3.fromRGB(28,  28,  40),
    SidebarBG       = Color3.fromRGB(22,  22,  32),
    ContentBG       = Color3.fromRGB(34,  34,  48),
    ElementBG       = Color3.fromRGB(40,  40,  56),
    ElementHover    = Color3.fromRGB(50,  50,  68),

    -- Accents
    Accent          = Color3.fromRGB(108, 75,  230),  -- purple
    AccentDim       = Color3.fromRGB(75,  52,  160),
    AccentText      = Color3.fromRGB(148, 115, 255),

    -- Text
    TextPrimary     = Color3.fromRGB(235, 235, 245),
    TextSecondary   = Color3.fromRGB(160, 160, 180),
    TextDisabled    = Color3.fromRGB(100, 100, 120),

    -- Toggle
    ToggleOn        = Color3.fromRGB(108, 75,  230),
    ToggleOff       = Color3.fromRGB(70,  70,  90),
    ToggleThumb     = Color3.fromRGB(240, 240, 255),

    -- Slider
    SliderTrack     = Color3.fromRGB(55,  55,  75),
    SliderFill      = Color3.fromRGB(108, 75,  230),
    SliderThumb     = Color3.fromRGB(230, 230, 255),

    -- Separator
    Separator       = Color3.fromRGB(48,  48,  65),

    -- Sizes
    CornerRadius    = UDim.new(0, 6),
    SmallCorner     = UDim.new(0, 4),
    SidebarWidth    = 210,
    ElementHeight   = 38,
    SectionPadding  = 10,
    SliderHeight    = 52,

    -- Fonts
    Font            = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
    FontSize        = 14,
    TitleSize       = 22,
    SectionSize     = 13,

    -- Tween
    TweenTime       = 0.18,
    TweenStyle      = Enum.EasingStyle.Quad,
}

-- ──────────────────────────────────────────────────────────────────────────────
-- UTILITY
-- ──────────────────────────────────────────────────────────────────────────────
local function Tween(obj, props, t)
    t = t or Theme.TweenTime
    TweenService:Create(obj, TweenInfo.new(t, Theme.TweenStyle), props):Play()
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function AddCorner(parent, radius)
    return Create("UICorner", {CornerRadius = radius or Theme.CornerRadius, Parent = parent})
end

local function AddPadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        Parent = parent,
    })
end

local function AddListLayout(parent, dir, padding, align)
    return Create("UIListLayout", {
        FillDirection  = dir    or Enum.FillDirection.Vertical,
        Padding        = UDim.new(0, padding or 4),
        SortOrder      = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        Parent = parent,
    })
end

-- Make a frame draggable
local function MakeDraggable(dragHandle, frame)
    local dragging, dragStart, startPos = false, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- ELEMENT BUILDERS  (internal)
-- ──────────────────────────────────────────────────────────────────────────────

-- Shared element wrapper: dark rounded row
local function NewRow(parent, height)
    local row = Create("Frame", {
        BackgroundColor3 = Theme.ElementBG,
        Size             = UDim2.new(1, 0, 0, height or Theme.ElementHeight),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    AddCorner(row, Theme.SmallCorner)
    return row
end

-- Section header label
local function NewSectionHeader(parent, text)
    local lbl = Create("TextLabel", {
        Text              = text,
        Font              = Theme.FontBold,
        TextSize          = Theme.SectionSize,
        TextColor3        = Theme.TextSecondary,
        TextXAlignment    = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, 0, 0, 20),
        Parent            = parent,
    })
    AddPadding(lbl, 0, 0, 4, 0)
    return lbl
end

-- ──────────────────────────────────────────────────────────────────────────────
-- LIBRARY TABLE
-- ──────────────────────────────────────────────────────────────────────────────
local Library = {}
Library.__index = Library

function Library:CreateWindow(title)
    -- Root ScreenGui
    local gui = Create("ScreenGui", {
        Name            = "ButterHubUI",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        Parent          = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui"),
    })

    -- ── Main Window Frame ──────────────────────────────────────────────────
    local windowW, windowH = 680, 420
    local mainFrame = Create("Frame", {
        Name             = "MainFrame",
        Size             = UDim2.new(0, windowW, 0, windowH),
        Position         = UDim2.new(0.5, -windowW/2, 0.5, -windowH/2),
        BackgroundColor3 = Theme.WindowBG,
        BorderSizePixel  = 0,
        Parent           = gui,
    })
    AddCorner(mainFrame)
    -- Subtle drop shadow (1 frame trick — no blur)
    local shadow = Create("Frame", {
        Size              = UDim2.new(1, 12, 1, 12),
        Position          = UDim2.new(0, -6, 0, 6),
        BackgroundColor3  = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.72,
        ZIndex            = mainFrame.ZIndex - 1,
        BorderSizePixel   = 0,
        Parent            = mainFrame,
    })
    AddCorner(shadow, UDim.new(0, 10))

    -- ── Sidebar ───────────────────────────────────────────────────────────
    local sidebar = Create("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, Theme.SidebarWidth, 1, 0),
        BackgroundColor3 = Theme.SidebarBG,
        BorderSizePixel  = 0,
        Parent           = mainFrame,
    })
    AddCorner(sidebar)
    -- clip right corners flat (overlap trick)
    Create("Frame", {
        Size             = UDim2.new(0, 12, 1, 0),
        Position         = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Theme.SidebarBG,
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })

    -- Logo
    local logoFrame = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        Parent           = sidebar,
    })
    local logoText = Create("TextLabel", {
        Text             = "BUTTER\nHUB",
        Font             = Theme.FontBold,
        TextSize         = Theme.TitleSize,
        TextColor3       = Theme.AccentText,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        TextXAlignment   = Enum.TextXAlignment.Center,
        Parent           = logoFrame,
    })

    -- Drag handle = logo
    MakeDraggable(logoFrame, mainFrame)

    -- Sidebar nav scroll
    local navScroll = Create("ScrollingFrame", {
        Size             = UDim2.new(1, -8, 1, -78),
        Position         = UDim2.new(0, 4, 0, 74),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 0,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = sidebar,
    })
    AddListLayout(navScroll, Enum.FillDirection.Vertical, 2)
    AddPadding(navScroll, 0, 8, 4, 4)

    -- ── Content Area ──────────────────────────────────────────────────────
    local contentArea = Create("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -Theme.SidebarWidth, 1, 0),
        Position         = UDim2.new(0, Theme.SidebarWidth, 0, 0),
        BackgroundColor3 = Theme.ContentBG,
        BorderSizePixel  = 0,
        Parent           = mainFrame,
    })
    AddCorner(contentArea)
    Create("Frame", {
        Size             = UDim2.new(0, 12, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.ContentBG,
        BorderSizePixel  = 0,
        Parent           = contentArea,
    })

    -- Content scroll
    local contentScroll = Create("ScrollingFrame", {
        Size             = UDim2.new(1, -16, 1, -16),
        Position         = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = contentArea,
    })
    local contentList = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent           = contentScroll,
    })
    AddListLayout(contentList, Enum.FillDirection.Vertical, 5)
    AddPadding(contentList, 4, 8, 6, 6)

    -- ── Window object ─────────────────────────────────────────────────────
    local Window = {
        _gui         = gui,
        _main        = mainFrame,
        _navScroll   = navScroll,
        _contentList = contentList,
        _tabs        = {},
        _activeTab   = nil,
        _navButtons  = {},
    }

    -- Search bar at top of sidebar
    local searchRow = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.ElementBG,
        BorderSizePixel  = 0,
        LayoutOrder      = 0,
        Parent           = navScroll,
    })
    AddCorner(searchRow, Theme.SmallCorner)
    Create("TextLabel", {
        Text             = "🔍",
        Font             = Theme.Font,
        TextSize         = 14,
        TextColor3       = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0, 28, 1, 0),
        Position         = UDim2.new(0, 4, 0, 0),
        Parent           = searchRow,
    })
    local searchBox = Create("TextBox", {
        PlaceholderText  = "Search",
        Text             = "",
        Font             = Theme.Font,
        TextSize         = Theme.FontSize,
        TextColor3       = Theme.TextPrimary,
        PlaceholderColor3= Theme.TextDisabled,
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Size             = UDim2.new(1, -32, 1, 0),
        Position         = UDim2.new(0, 30, 0, 0),
        Parent           = searchRow,
    })

    -- Search filter logic
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for tabName, tabData in pairs(Window._tabs) do
            local navBtn = Window._navButtons[tabName]
            if navBtn then
                navBtn.Visible = (query == "" or tabName:lower():find(query, 1, true) ~= nil)
            end
        end
    end)

    -- ── AddTab ────────────────────────────────────────────────────────────
    function Window:AddTab(name, icon)
        -- Nav button
        local order = #self._navButtons + 1
        local btn = Create("TextButton", {
            Text             = "",
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.SidebarBG,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
            AutoButtonColor  = false,
            Parent           = navScroll,
        })
        AddCorner(btn, Theme.SmallCorner)

        -- Icon placeholder (text icon)
        local iconLabel = Create("TextLabel", {
            Text             = icon or "•",
            Font             = Theme.Font,
            TextSize         = 16,
            TextColor3       = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size             = UDim2.new(0, 28, 1, 0),
            Position         = UDim2.new(0, 6, 0, 0),
            Parent           = btn,
        })
        local nameLabel = Create("TextLabel", {
            Text             = name,
            Font             = Theme.Font,
            TextSize         = Theme.FontSize,
            TextColor3       = Theme.TextSecondary,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -36, 1, 0),
            Position         = UDim2.new(0, 34, 0, 0),
            Parent           = btn,
        })

        -- Active indicator strip
        local strip = Create("Frame", {
            Size             = UDim2.new(0, 3, 0.6, 0),
            Position         = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            Visible          = false,
            Parent           = btn,
        })
        AddCorner(strip, UDim.new(0, 2))

        -- Tab content container
        local tabContainer = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Visible          = false,
            Parent           = contentList,
        })
        AddListLayout(tabContainer, Enum.FillDirection.Vertical, 5)

        local tabObj = {
            _name      = name,
            _btn       = btn,
            _strip     = strip,
            _nameLabel = nameLabel,
            _iconLabel = iconLabel,
            _container = tabContainer,
        }
        self._tabs[name]       = tabObj
        self._navButtons[name] = btn

        -- Hover
        btn.MouseEnter:Connect(function()
            if self._activeTab ~= name then
                Tween(btn, {BackgroundColor3 = Theme.ElementHover})
            end
        end)
        btn.MouseLeave:Connect(function()
            if self._activeTab ~= name then
                Tween(btn, {BackgroundColor3 = Theme.SidebarBG})
            end
        end)

        -- Click → activate
        btn.MouseButton1Click:Connect(function()
            self:_SetActive(name)
        end)

        -- Auto-select first tab
        if not self._activeTab then
            self:_SetActive(name)
        end

        -- ── Element API ───────────────────────────────────────────────────
        local Tab = {}

        -- Section header
        function Tab:AddSection(text)
            -- small gap before section
            local spacer = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 6),
                BackgroundTransparency = 1,
                Parent           = tabContainer,
            })
            NewSectionHeader(tabContainer, text)
        end

        -- Button
        function Tab:AddButton(text, callback)
            local row = NewRow(tabContainer, Theme.ElementHeight)
            local btn2 = Create("TextButton", {
                Text             = text,
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 1, 0),
                AutoButtonColor  = false,
                Parent           = row,
            })
            btn2.MouseEnter:Connect(function()
                Tween(row, {BackgroundColor3 = Theme.ElementHover})
            end)
            btn2.MouseLeave:Connect(function()
                Tween(row, {BackgroundColor3 = Theme.ElementBG})
            end)
            btn2.MouseButton1Click:Connect(function()
                Tween(row, {BackgroundColor3 = Theme.AccentDim}, 0.08)
                task.delay(0.12, function()
                    Tween(row, {BackgroundColor3 = Theme.ElementBG})
                end)
                if callback then callback() end
            end)
            return btn2
        end

        -- Toggle
        function Tab:AddToggle(text, options, callback)
            options = options or {}
            local state = options.Default or false

            local row = NewRow(tabContainer, Theme.ElementHeight)
            -- label
            Create("TextLabel", {
                Text             = text,
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextPrimary,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, -56, 1, 0),
                Position         = UDim2.new(0, 10, 0, 0),
                Parent           = row,
            })

            -- Toggle pill
            local pillW, pillH = 40, 22
            local pill = Create("Frame", {
                Size             = UDim2.new(0, pillW, 0, pillH),
                Position         = UDim2.new(1, -(pillW+10), 0.5, -pillH/2),
                BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                BorderSizePixel  = 0,
                Parent           = row,
            })
            AddCorner(pill, UDim.new(0, pillH/2))
            local thumb = Create("Frame", {
                Size             = UDim2.new(0, pillH-6, 0, pillH-6),
                Position         = state and UDim2.new(1, -(pillH-3), 0.5, -(pillH-6)/2)
                                          or UDim2.new(0, 3, 0.5, -(pillH-6)/2),
                BackgroundColor3 = Theme.ToggleThumb,
                BorderSizePixel  = 0,
                Parent           = pill,
            })
            AddCorner(thumb, UDim.new(0, (pillH-6)/2))

            local function SetState(s)
                state = s
                Tween(pill, {BackgroundColor3 = s and Theme.ToggleOn or Theme.ToggleOff})
                Tween(thumb, {Position = s
                    and UDim2.new(1, -(pillH-3), 0.5, -(pillH-6)/2)
                    or  UDim2.new(0, 3, 0.5, -(pillH-6)/2)
                })
                if callback then callback(s) end
            end

            local clickBtn = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                AutoButtonColor  = false,
                Parent           = row,
            })
            clickBtn.MouseButton1Click:Connect(function() SetState(not state) end)

            row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementHover}) end)
            row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementBG}) end)

            return { SetState = SetState, GetState = function() return state end }
        end

        -- Slider
        function Tab:AddSlider(text, options, callback)
            options = options or {}
            local min  = options.Min     or 0
            local max  = options.Max     or 100
            local val  = options.Default or min
            local step = options.Step    or 1

            local row = NewRow(tabContainer, Theme.SliderHeight)
            row.ClipsDescendants = true

            -- Top row: label + value
            Create("TextLabel", {
                Text             = text,
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextPrimary,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, -40, 0, 24),
                Position         = UDim2.new(0, 10, 0, 4),
                Parent           = row,
            })
            local valLabel = Create("TextLabel", {
                Text             = tostring(val),
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextSecondary,
                TextXAlignment   = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1,
                Size             = UDim2.new(0, 36, 0, 24),
                Position         = UDim2.new(1, -42, 0, 4),
                Parent           = row,
            })

            -- Track
            local trackH = 4
            local trackY = 30
            local track = Create("Frame", {
                Size             = UDim2.new(1, -20, 0, trackH),
                Position         = UDim2.new(0, 10, 0, trackY),
                BackgroundColor3 = Theme.SliderTrack,
                BorderSizePixel  = 0,
                Parent           = row,
            })
            AddCorner(track, UDim.new(0, trackH/2))

            -- Fill
            local fillPct = (val - min) / (max - min)
            local fill = Create("Frame", {
                Size             = UDim2.new(fillPct, 0, 1, 0),
                BackgroundColor3 = Theme.SliderFill,
                BorderSizePixel  = 0,
                Parent           = track,
            })
            AddCorner(fill, UDim.new(0, trackH/2))

            -- Thumb
            local thumbSz = 14
            local thumbBtn = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(0, thumbSz, 0, thumbSz),
                Position         = UDim2.new(fillPct, -thumbSz/2, 0.5, -thumbSz/2),
                BackgroundColor3 = Theme.SliderThumb,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ZIndex           = 3,
                Parent           = track,
            })
            AddCorner(thumbBtn, UDim.new(0, thumbSz/2))

            local function SetValue(v)
                v = math.clamp(math.round((v - min) / step) * step + min, min, max)
                val = v
                local pct = (v - min) / (max - min)
                fill.Size     = UDim2.new(pct, 0, 1, 0)
                thumbBtn.Position = UDim2.new(pct, -thumbSz/2, 0.5, -thumbSz/2)
                valLabel.Text = tostring(v)
                if callback then callback(v) end
            end

            -- Drag interaction
            local draggingSlider = false
            thumbBtn.MouseButton1Down:Connect(function() draggingSlider = true end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local abs    = track.AbsolutePosition
                    local width  = track.AbsoluteSize.X
                    local relX   = math.clamp(i.Position.X - abs.X, 0, width)
                    local newVal = min + (relX / width) * (max - min)
                    SetValue(newVal)
                end
            end)
            -- Click on track also works
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local width = track.AbsoluteSize.X
                    local relX  = math.clamp(i.Position.X - track.AbsolutePosition.X, 0, width)
                    SetValue(min + (relX / width) * (max - min))
                    draggingSlider = true
                end
            end)

            row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementHover}) end)
            row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementBG}) end)

            return { SetValue = SetValue, GetValue = function() return val end }
        end

        -- Dropdown
        function Tab:AddDropdown(text, options, callback)
            options = options or {}
            local items   = options.Options or {}
            local current = options.Default or items[1] or "Select"
            local open    = false

            local row = NewRow(tabContainer, Theme.ElementHeight)
            Create("TextLabel", {
                Text             = text,
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextPrimary,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(0.6, 0, 1, 0),
                Position         = UDim2.new(0, 10, 0, 0),
                Parent           = row,
            })
            -- Arrow
            local arrow = Create("TextLabel", {
                Text             = "◄",
                Font             = Theme.Font,
                TextSize         = 12,
                TextColor3       = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -26, 0, 0),
                Parent           = row,
            })

            -- Dropdown list (hidden)
            local listFrame = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, #items * (Theme.ElementHeight - 4) + 8),
                Position         = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = Theme.ElementBG,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 10,
                Parent           = row,
            })
            AddCorner(listFrame, Theme.SmallCorner)
            AddPadding(listFrame, 4, 4, 4, 4)
            AddListLayout(listFrame, Enum.FillDirection.Vertical, 2)

            for _, item in ipairs(items) do
                local itemBtn = Create("TextButton", {
                    Text             = item,
                    Font             = Theme.Font,
                    TextSize         = Theme.FontSize,
                    TextColor3       = Theme.TextPrimary,
                    BackgroundColor3 = Theme.ElementBG,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(1, 0, 0, Theme.ElementHeight - 8),
                    AutoButtonColor  = false,
                    ZIndex           = 11,
                    Parent           = listFrame,
                })
                AddCorner(itemBtn, Theme.SmallCorner)
                itemBtn.MouseEnter:Connect(function()
                    Tween(itemBtn, {BackgroundColor3=Theme.ElementHover})
                end)
                itemBtn.MouseLeave:Connect(function()
                    Tween(itemBtn, {BackgroundColor3=Theme.ElementBG})
                end)
                itemBtn.MouseButton1Click:Connect(function()
                    current = item
                    arrow.Text = "◄"
                    open = false
                    listFrame.Visible = false
                    if callback then callback(item) end
                end)
            end

            local clickBtn = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                AutoButtonColor  = false,
                Parent           = row,
            })
            clickBtn.MouseButton1Click:Connect(function()
                open = not open
                listFrame.Visible = open
                arrow.Text = open and "▾" or "◄"
            end)

            row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementHover}) end)
            row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementBG}) end)

            return { GetValue = function() return current end }
        end

        -- Label (info text / price display)
        function Tab:AddLabel(text)
            local row = NewRow(tabContainer, Theme.ElementHeight)
            Create("TextLabel", {
                Text             = text,
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextSecondary,
                TextXAlignment   = Enum.TextXAlignment.Center,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, -20, 1, 0),
                Position         = UDim2.new(0, 10, 0, 0),
                Parent           = row,
            })
            return row
        end

        -- Keybind display row
        function Tab:AddKeybind(text, options, callback)
            options = options or {}
            local key     = options.Default or Enum.KeyCode.Unknown
            local binding = false

            local row = NewRow(tabContainer, Theme.ElementHeight)
            Create("TextLabel", {
                Text             = text,
                Font             = Theme.Font,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.TextPrimary,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, -60, 1, 0),
                Position         = UDim2.new(0, 10, 0, 0),
                Parent           = row,
            })
            local keyLabel = Create("TextLabel", {
                Text             = key.Name:sub(1,1):upper(),
                Font             = Theme.FontBold,
                TextSize         = Theme.FontSize,
                TextColor3       = Theme.AccentText,
                BackgroundTransparency = 1,
                Size             = UDim2.new(0, 50, 1, 0),
                Position         = UDim2.new(1, -56, 0, 0),
                TextXAlignment   = Enum.TextXAlignment.Right,
                Parent           = row,
            })

            local clickBtn = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                AutoButtonColor  = false,
                Parent           = row,
            })
            clickBtn.MouseButton1Click:Connect(function()
                binding = true
                keyLabel.Text  = "..."
                keyLabel.TextColor3 = Theme.TextDisabled
            end)
            UserInputService.InputBegan:Connect(function(i, gp)
                if binding and not gp and i.UserInputType == Enum.UserInputType.Keyboard then
                    key = i.KeyCode
                    keyLabel.Text = key.Name:sub(1,1):upper()
                    keyLabel.TextColor3 = Theme.AccentText
                    binding = false
                    if callback then callback(key) end
                end
            end)

            row.MouseEnter:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementHover}) end)
            row.MouseLeave:Connect(function() Tween(row, {BackgroundColor3=Theme.ElementBG}) end)

            return { GetKey = function() return key end }
        end

        return Tab
    end

    -- ── _SetActive ────────────────────────────────────────────────────────
    function Window:_SetActive(name)
        -- deactivate old
        if self._activeTab then
            local old = self._tabs[self._activeTab]
            if old then
                old._container.Visible = false
                old._strip.Visible     = false
                Tween(old._btn,       {BackgroundColor3 = Theme.SidebarBG})
                Tween(old._nameLabel, {TextColor3 = Theme.TextSecondary})
                Tween(old._iconLabel, {TextColor3 = Theme.TextSecondary})
            end
        end
        -- activate new
        local new = self._tabs[name]
        if new then
            new._container.Visible = true
            new._strip.Visible     = true
            Tween(new._btn,       {BackgroundColor3 = Theme.ElementBG})
            Tween(new._nameLabel, {TextColor3 = Theme.AccentText})
            Tween(new._iconLabel, {TextColor3 = Theme.Accent})
            self._activeTab = name
        end
    end

    -- ── Toggle visibility with key ────────────────────────────────────────
    local visible = true
    function Window:SetToggleKey(keyCode)
        UserInputService.InputBegan:Connect(function(i, gp)
            if not gp and i.KeyCode == keyCode then
                visible = not visible
                mainFrame.Visible = visible
            end
        end)
    end

    Window:SetToggleKey(Enum.KeyCode.RightControl)
    return Window
end

-- ──────────────────────────────────────────────────────────────────────────────
-- RETURN
-- ──────────────────────────────────────────────────────────────────────────────
return Library


--[[
══════════════════════════════════════════════════════════════════════════════
QUICK-START EXAMPLE  (paste below Library return, or in a separate script)
══════════════════════════════════════════════════════════════════════════════

local Hub    = Library  -- if in same script; else: local Hub = loadstring(...)()
local Window = Hub:CreateWindow("Butter Hub")

── PLAYER TAB ────────────────────────────────────────────────────────────────
local Player = Window:AddTab("Player", "👤")
Player:AddSection("Movement Sliders")
Player:AddSlider("Walk speed",  {Min=1, Max=100, Default=16},  function(v)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
end)
Player:AddSlider("Sprint speed",{Min=1, Max=150, Default=65},  function(v) end)
Player:AddSlider("Jump power",  {Min=1, Max=200, Default=50},  function(v)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
end)
Player:AddSlider("Fly speed",   {Min=1, Max=300, Default=100}, function(v) end)

Player:AddSection("Movement Toggles")
Player:AddKeybind("Fly keybind", {Default=Enum.KeyCode.Q},     function(k) end)
Player:AddToggle("Fly",          {Default=false},               function(v) end)

── WORLD TAB ─────────────────────────────────────────────────────────────────
local World = Window:AddTab("World", "🌍")
World:AddSection("Lighting")
World:AddToggle("Always day",   {Default=false}, function(v) end)
World:AddToggle("Always night", {Default=false}, function(v) end)
World:AddToggle("No fog",       {Default=false}, function(v) end)
World:AddToggle("Shadows",      {Default=true},  function(v) end)

World:AddSection("Teleports")
World:AddDropdown("Teleport to waypoints", {Options={"Spawn","Shop","Forest"}}, function(v) end)
World:AddDropdown("Teleport to player",    {Options={"Player1","Player2"}},     function(v) end)

── WOOD TAB ──────────────────────────────────────────────────────────────────
local Wood = Window:AddTab("Wood", "🌲")
Wood:AddSection("Get Tree")
Wood:AddDropdown("Select Tree", {Options={"Oak","Palm","Pine","Walnut"}}, function(v) end)
Wood:AddSlider("Amount", {Min=1, Max=50, Default=1, Step=1}, function(v) end)
Wood:AddButton("Get Tree",  function() end)
Wood:AddButton("Stop",      function() end)
Wood:AddToggle("Sell tree", {Default=false}, function(v) end)

Wood:AddSection("Mods")
Wood:AddToggle("ModWood",   {Default=false}, function(v) end)
Wood:AddButton("ModSawmill",function() end)

── AUTO BUY TAB ──────────────────────────────────────────────────────────────
local AutoBuy = Window:AddTab("Auto Buy", "🛒")
AutoBuy:AddSection("Auto Buy")
AutoBuy:AddDropdown("Select Item", {Options={"Wood","Stone","Iron"}}, function(v) end)
AutoBuy:AddLabel("Price amount: $12")
AutoBuy:AddSlider("Amount", {Min=1, Max=99, Default=1, Step=1}, function(v) end)
AutoBuy:AddButton("Purchase",         function() end)
AutoBuy:AddButton("Stop purchasing",  function() end)
AutoBuy:AddSection("Other")
AutoBuy:AddButton("Purchase Rukiry-Axe - $7400", function() end)

── DUPE TAB ──────────────────────────────────────────────────────────────────
local Dupe = Window:AddTab("Dupe", "📋")
Dupe:AddSection("Axe Dupe")
Dupe:AddSlider("Slot",     {Min=1, Max=9,   Default=1, Step=1}, function(v) end)
Dupe:AddSlider("WaitTime", {Min=1, Max=10,  Default=1, Step=1}, function(v) end)
Dupe:AddSlider("Amount",   {Min=1, Max=100, Default=1, Step=1}, function(v) end)
Dupe:AddButton("Axe Dupe",    function() end)
Dupe:AddButton("Drop all axes",function() end)
]]
