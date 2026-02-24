-- ═══════════════════════════════════════════════════════
--  Delta Hub  |  LT2  |  Mobile-First  |  Dupe Focus
-- ═══════════════════════════════════════════════════════

if getgenv().DeltaHub_Loaded then
    return print('[Delta] Already running.')
end
getgenv().DeltaHub_Loaded = true

-- Wait for full game load
repeat task.wait()
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChild('PlayerGui')
    and game.Players.LocalPlayer.PlayerGui:FindFirstChild('OnboardingGUI')
    and game.Players.LocalPlayer.PlayerGui.OnboardingGUI.DoOnboarding.Loaded.Value

-- ───────────────────────────────────────────────────────
--  SERVICES
-- ───────────────────────────────────────────────────────
local Players           = game:GetService('Players')
local RunService        = game:GetService('RunService')
local UIS               = game:GetService('UserInputService')
local TweenService      = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Player  = Players.LocalPlayer
local Camera  = workspace.CurrentCamera

-- ───────────────────────────────────────────────────────
--  GAME REMOTES  (from LT2 source)
-- ───────────────────────────────────────────────────────
local ClientInteracted = ReplicatedStorage.Interaction.ClientInteracted
local ClientIsDragging = ReplicatedStorage.Interaction.ClientIsDragging
local RemoteProxy      = ReplicatedStorage.Interaction.RemoteProxy
local SendUserNotice   = ReplicatedStorage.Notices.SendUserNotice
local AxeFolder        = ReplicatedStorage.AxeClasses
local RequestSave      = ReplicatedStorage.LoadSaveRequests.RequestSave

-- ───────────────────────────────────────────────────────
--  HELPERS
-- ───────────────────────────────────────────────────────
local function char()    return Player.Character end
local function hum()     local c=char(); return c and c:FindFirstChild('Humanoid') end
local function root()    local c=char(); return c and c:FindFirstChild('HumanoidRootPart') end
local function head()    local c=char(); return c and c:FindFirstChild('Head') end

local function notify(msg)
    pcall(function() SendUserNotice:Fire(msg) end)
end

-- Get all axes from backpack + character
local function getAxes()
    local axes = {}
    local c = char()
    if not c then return axes end
    for _, v in ipairs(Player.Backpack:GetChildren()) do
        if v:FindFirstChild('CuttingTool') then axes[#axes+1] = v end
    end
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then axes[#axes+1] = v end
    end
    return axes
end

-- Fire drop remote for one axe
local function dropAxe(axe)
    local r = root()
    if r then ClientInteracted:FireServer(axe, 'Drop tool', r.CFrame) end
end

-- Kill character safely (save is preserved)
local function safeSuicide()
    local h = head()
    if h then pcall(function() h:Destroy() end) end
end

-- ───────────────────────────────────────────────────────
-- ─── REMOTES for dupe ─────────────────────────────────
local RequestLoad    = ReplicatedStorage.LoadSaveRequests.RequestLoad
local RequestSave    = ReplicatedStorage.LoadSaveRequests.RequestSave
local ClientMayLoad  = ReplicatedStorage.LoadSaveRequests.ClientMayLoad
local SelectLoadPlot = ReplicatedStorage.PropertyPurchasing.SelectLoadPlot

-- ───────────────────────────────────────────────────────
--  DUPE AXE — CORRECT LOGIC (confirmed from game files)
--
--  The DROP already works (proven by zip: axes sitting in
--  workspace.PlayerModels from previous attempts).
--
--  Full sequence (NO dying needed):
--  1. Record your property plot CFrame
--  2. Drop axe via ClientInteracted remote
--     → Axe appears in workspace.PlayerModels
--     → Save still has the axe (drop doesn't update save)
--  3. Wait for 60s reload cooldown (ClientMayLoad)
--  4. Hook SelectLoadPlot.OnClientInvoke to auto-place land
--  5. Call RequestLoad:InvokeServer(slot, Player) in thread
--     → Server calls SelectLoadPlot on client
--     → Our hook returns saved plot CFrame immediately
--     → Server restores axe from save to inventory
--  6. Walk back, pick up world axe = 2 axes
-- ───────────────────────────────────────────────────────
local dupeRunning = false

local function dupeAxe()
    if dupeRunning then return notify('Dupe already running!') end

    -- Verify slot is loaded
    local slot = Player.CurrentSaveSlot.Value
    if not slot or slot <= 0 then
        return notify('No slot loaded! Use the in-game menu to load a slot first.')
    end

    local c = char(); local h = hum(); local r = root()
    if not c or not h or not r then return notify('No character found!') end

    -- Find axe
    local axe = nil
    for _, v in ipairs(Player.Backpack:GetChildren()) do
        if v:FindFirstChild('CuttingTool') then axe = v; break end
    end
    if not axe then
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then axe = v; break end
        end
    end
    if not axe then return notify('No axe found! Buy one first.') end

    -- Save property plot CFrame BEFORE anything else
    local plotCF = nil
    for _, prop in ipairs(workspace.Properties:GetChildren()) do
        if prop:FindFirstChild('Owner') and prop.Owner.Value == Player
        and prop:FindFirstChild('OriginSquare') then
            plotCF = prop.OriginSquare.CFrame
            break
        end
    end
    if not plotCF then
        return notify('Could not find your land plot! Make sure land is loaded.')
    end

    dupeRunning = true

    -- STEP 1: Unequip then drop
    notify('[1/4] Dropping axe...')
    h:UnequipTools()
    task.wait(0.25)
    ClientInteracted:FireServer(axe, 'Drop tool', r.CFrame)
    task.wait(0.5)

    -- STEP 2: Wait for reload cooldown
    notify('[2/4] Waiting for reload cooldown (up to 60s)...')
    local waited = 0
    local canLoad = false
    repeat
        task.wait(1)
        waited += 1
        canLoad = pcall(function()
            local res = ClientMayLoad:InvokeServer(Player)
            assert(res == true)
        end)
        if waited % 15 == 0 then
            notify('[2/4] Still waiting... ('..waited..'s)')
        end
    until canLoad or waited >= 90

    if not canLoad then
        dupeRunning = false
        return notify('Cooldown never cleared. Try reloading manually.')
    end

    -- STEP 3: Hook SelectLoadPlot to auto-confirm land at same spot
    notify('[3/4] Reloading slot '..slot..'...')
    local origHook = SelectLoadPlot.OnClientInvoke
    SelectLoadPlot.OnClientInvoke = function(_model)
        -- Return saved plot CFrame so server places land at same position
        return plotCF, 0
    end

    -- STEP 4: Call RequestLoad in separate thread (it blocks waiting for SelectLoadPlot response)
    local loadDone = false
    task.spawn(function()
        pcall(function()
            RequestLoad:InvokeServer(slot, Player)
        end)
        loadDone = true
    end)

    -- Also spam selectionMade as belt-and-suspenders backup
    -- (in case PropertyPurchasingClient:enterPurchaseMode was already running)
    local pClient = nil
    pcall(function()
        pClient = getsenv(Player.PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient)
    end)

    local timeout = 0
    repeat
        task.wait(0.2)
        timeout += 0.2
        if pClient then
            pcall(function() pClient:selectionMade() end)
        end
    until loadDone or timeout >= 25

    -- Restore original hook
    pcall(function()
        SelectLoadPlot.OnClientInvoke = origHook
    end)

    dupeRunning = false

    if loadDone then
        notify('[4/4] Done! Axe restored from save. Walk back and pick up the dropped axe = 2 axes!')
    else
        notify('Reload timed out. Check if your slot is still loaded.')
    end
end

-- ───────────────────────────────────────────────────────
--  AXE MOD  — range + cooldown via upvalue injection
-- ───────────────────────────────────────────────────────
local axeModState = {rangeOn=false, rangeVal=50, noCd=false}

local function applyAxeMod()
    local c = char()
    if not c then return end
    local tool = c:FindFirstChildOfClass('Tool')
    if not tool or not tool:FindFirstChild('ToolName') then return end

    -- Only bother hooking if a mod is actually turned on
    if not axeModState.rangeOn and not axeModState.noCd then return end

    -- Wait up to 3s for connection
    local attempts = 0
    repeat task.wait(0.1); attempts += 1 until getconnections(tool.Activated)[1] or attempts > 30
    local conn = getconnections(tool.Activated)[1]
    if not conn then return end  -- silent — not the user's fault, mods just won't apply

    local fn    = conn.Function
    local stats = getupvalues(fn)[1]
    if not stats then return end

    pcall(function()
        local axeClass = require(AxeFolder['AxeClass_'..tostring(tool.ToolName.Value)]).new()
        stats.Range         = axeModState.rangeOn and axeModState.rangeVal or axeClass.Range
        stats.SwingCooldown = axeModState.noCd    and 0                   or axeClass.SwingCooldown
        setupvalue(fn, 1, stats)
    end)
end

-- Re-apply mod every time an axe is equipped
local function hookEquip(character)
    character.ChildAdded:Connect(function(obj)
        if obj:IsA('Tool') then
            task.wait(0.2)
            pcall(applyAxeMod)
        end
    end)
end

if char() then hookEquip(char()) end
Player.CharacterAdded:Connect(hookEquip)

-- ───────────────────────────────────────────────────────
--  SELL ALL LOGS
-- ───────────────────────────────────────────────────────
local function sellAllLogs()
    local logs = workspace.LogModels:GetChildren()
    local count = 0
    for _, log in ipairs(logs) do
        if log:FindFirstChild('Owner') and
           (log.Owner.Value == nil or log.Owner.Value == Player) then
            count += 1
            task.spawn(function()
                pcall(function()
                    log.PrimaryPart = log.PrimaryPart or log:FindFirstChildOfClass('Part')
                    if not log.PrimaryPart then return end
                    local r = root()
                    if r and (r.CFrame.p - log.PrimaryPart.CFrame.p).Magnitude >= 8 then
                        Player.Character:PivotTo(
                            CFrame.new(log.PrimaryPart.CFrame.p + Vector3.new(0,5,0))
                        )
                    end
                    for i = 1, 25 do
                        ClientIsDragging:FireServer(log)
                        task.wait(0.1)
                    end
                    for _ = 1, 35 do
                        log:PivotTo(CFrame.new(315, 3, 85))
                    end
                end)
            end)
        end
    end
    notify(count > 0 and ('Selling '..count..' log(s)...') or 'No owned logs found.')
end

-- ───────────────────────────────────────────────────────
--  AUTO CHOP  — finds trees in TreeRegions, fires CutEvent
-- ───────────────────────────────────────────────────────
local autoChopActive = false

local function startAutoChop()
    autoChopActive = true
    task.spawn(function()
        while autoChopActive do
            task.wait(0.25)
            pcall(function()
                local r = root()
                if not r then return end
                local axe = getAxes()[1]
                if not axe or not axe:FindFirstChild('ToolName') then return end

                -- Get hitpoints from axe class
                local hp = 5
                pcall(function()
                    hp = require(AxeFolder['AxeClass_'..tostring(axe.ToolName.Value)]).new().Damage
                end)

                for _, region in ipairs(workspace:GetChildren()) do
                    if tostring(region):match('TreeRegion') then
                        for _, tree in ipairs(region:GetChildren()) do
                            if tree:FindFirstChild('TreeClass') and tree:FindFirstChild('CutEvent') then
                                local ws = tree:FindFirstChild('WoodSection')
                                if ws and (r.CFrame.p - ws.CFrame.p).Magnitude <= 22 then
                                    local lowestId, sections = 9e9, tree:GetChildren()
                                    for _, s in ipairs(sections) do
                                        if tostring(s):match('WoodSection') and s:FindFirstChild('ID') then
                                            if s.ID.Value < lowestId then lowestId = s.ID.Value end
                                        end
                                    end
                                    RemoteProxy:FireServer(tree.CutEvent, {
                                        ['tool']         = axe,
                                        ['faceVector']   = Vector3.new(1,0,0),
                                        ['height']       = 0.3,
                                        ['sectionId']    = lowestId,
                                        ['hitPoints']    = hp,
                                        ['cooldown']     = 0.1,
                                        ['cuttingClass'] = 'Axe',
                                    })
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- ───────────────────────────────────────────────────────
--  NOCLIP
-- ───────────────────────────────────────────────────────
local noclipConn
local function setNoclip(on)
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                for _, p in ipairs(char():GetDescendants()) do
                    if p:IsA('BasePart') then p.CanCollide = false end
                end
            end)
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    end
end

-- ───────────────────────────────────────────────────────
--  ANTI-AFK
-- ───────────────────────────────────────────────────────
local function setAntiAFK(on)
    local c = getconnections(Player.Idled)[1]
    if not c then return end
    if on then c:Disable() else c:Enable() end
end
pcall(setAntiAFK, true)  -- default on

-- ═══════════════════════════════════════════════════════
--  UI  — simple, large touch targets, single column
-- ═══════════════════════════════════════════════════════
local ACCENT   = Color3.fromRGB(0, 210, 150)
local ACCDIM   = Color3.fromRGB(0, 145, 105)
local BG       = Color3.fromRGB(12, 15, 24)
local PANEL    = Color3.fromRGB(18, 22, 36)
local EL       = Color3.fromRGB(22, 28, 44)
local ELHOV    = Color3.fromRGB(28, 36, 56)
local TPRI     = Color3.fromRGB(225, 230, 240)
local TSEC     = Color3.fromRGB(120, 135, 158)
local DANGER   = Color3.fromRGB(210, 55, 55)
local TOGON    = Color3.fromRGB(0, 210, 150)
local TOGOFF   = Color3.fromRGB(45, 55, 75)
local THUMB    = Color3.fromRGB(235, 240, 250)
local SEP      = Color3.fromRGB(32, 42, 62)

local TAB_W   = 70   -- sidebar tab width
local WIN_W   = 330
local WIN_H   = 390
local BTN_H   = 46   -- large touch target

local function inst(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= 'Parent' then o[k] = v end
    end
    if props.Parent then o.Parent = props.Parent end
    return o
end
local function rnd(o, r) local c=Instance.new('UICorner'); c.CornerRadius=r or UDim.new(0,8); c.Parent=o end
local function strk(o, col, th) local s=Instance.new('UIStroke'); s.Color=col; s.Thickness=th or 1; s.Parent=o end
local function vlist(o, gap) local l=Instance.new('UIListLayout'); l.Padding=UDim.new(0,gap or 6); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=o; return l end
local function pad(o, t,b,l,r) local p=Instance.new('UIPadding'); p.PaddingTop=UDim.new(0,t or 8); p.PaddingBottom=UDim.new(0,b or 8); p.PaddingLeft=UDim.new(0,l or 10); p.PaddingRight=UDim.new(0,r or 10); p.Parent=o end
local function tw(o, props, t) TweenService:Create(o, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad), props):Play() end

-- ── Screen GUI ──
local gui = inst('ScreenGui', {
    Name='DeltaHub', ResetOnSpawn=false, IgnoreGuiInset=true,
    DisplayOrder=999, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=pcall(function() return game:GetService('CoreGui') end) and game:GetService('CoreGui') or Player.PlayerGui
})

-- ── Main window ──
local Main = inst('Frame', {
    Name='Main', Size=UDim2.new(0,WIN_W,0,WIN_H),
    Position=UDim2.new(0.5,-WIN_W/2, 0.5,-WIN_H/2),
    BackgroundColor3=BG, BorderSizePixel=0, ClipsDescendants=true,
    Parent=gui
})
rnd(Main, UDim.new(0,12))
strk(Main, Color3.fromRGB(36,50,74), 1)

-- ── Title bar ──
local TBar = inst('Frame', {
    Size=UDim2.new(1,0,0,38), BackgroundColor3=PANEL,
    BorderSizePixel=0, ZIndex=6, Parent=Main
})
-- accent dot
local dot = inst('Frame', {
    Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,12,0.5,-3),
    BackgroundColor3=ACCENT, BorderSizePixel=0, ZIndex=7, Parent=TBar
})
rnd(dot, UDim.new(1,0))

inst('TextLabel', {
    Text='Delta Hub', Size=UDim2.new(0,140,1,0), Position=UDim2.new(0,26,0,0),
    BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=TPRI, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar
})
inst('TextLabel', {
    Text='LT2 Exploit', Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,138,0,0),
    BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=10,
    TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar
})

-- separator under titlebar
inst('Frame', {
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=SEP, BorderSizePixel=0, ZIndex=6, Parent=TBar
})

-- close
local CloseBtn = inst('TextButton', {
    Text='✕', Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-36,0.5,-15),
    BackgroundColor3=DANGER, BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=13, TextColor3=TPRI,
    BorderSizePixel=0, ZIndex=8, Parent=TBar
})
rnd(CloseBtn, UDim.new(0,6))
CloseBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    getgenv().DeltaHub_Loaded = false
end)

-- ── Dragging ──
local _drag, _start, _mpos = false, nil, nil
TBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        _drag = true; _start = Main.Position; _mpos = i.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if _drag and (i.UserInputType == Enum.UserInputType.MouseMovement
               or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - _mpos
        Main.Position = UDim2.new(_start.X.Scale, _start.X.Offset+d.X,
                                   _start.Y.Scale, _start.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then _drag = false end
end)

-- ── Body (sidebar + content) ──
local Body = inst('Frame', {
    Size=UDim2.new(1,0,1,-38), Position=UDim2.new(0,0,0,38),
    BackgroundTransparency=1, Parent=Main
})

-- sidebar
local Sidebar = inst('Frame', {
    Size=UDim2.new(0,TAB_W,1,0), BackgroundColor3=PANEL,
    BorderSizePixel=0, Parent=Body
})
-- sidebar right border
inst('Frame', {
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
    BackgroundColor3=SEP, BorderSizePixel=0, Parent=Sidebar
})

local TabList = inst('ScrollingFrame', {
    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    ScrollBarThickness=0, ScrollingDirection=Enum.ScrollingDirection.Y,
    ElasticBehavior=Enum.ElasticBehavior.Never,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Parent=Sidebar
})
vlist(TabList, 0)

-- content
local Content = inst('ScrollingFrame', {
    Size=UDim2.new(1,-TAB_W,1,0), Position=UDim2.new(0,TAB_W,0,0),
    BackgroundTransparency=1, ScrollBarThickness=3,
    ScrollBarImageColor3=ACCENT,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    ElasticBehavior=Enum.ElasticBehavior.Never,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Parent=Body
})
pad(Content, 10,10,10,10)
vlist(Content, 8)

-- ═══════════════════════════════════════════════════════
--  TAB SYSTEM
-- ═══════════════════════════════════════════════════════
local TABS = {'Dupe','Axe','Player','Wood'}
local ICONS = {Dupe='📦', Axe='🪓', Player='👤', Wood='🌲'}
local pages = {}
local tabBtns = {}
local activeTab = nil

local function switchTab(name)
    for _, pg in pairs(pages)   do pg.Visible = false end
    for n, b  in pairs(tabBtns) do
        b.BackgroundColor3 = PANEL
        b.TextColor3       = TSEC
        if b:FindFirstChild('Line') then b.Line.BackgroundTransparency = 1 end
    end
    if pages[name]   then pages[name].Visible   = true end
    if tabBtns[name] then
        tabBtns[name].BackgroundColor3 = EL
        tabBtns[name].TextColor3       = ACCENT
        if tabBtns[name]:FindFirstChild('Line') then
            tabBtns[name].Line.BackgroundTransparency = 0
        end
    end
    activeTab = name
end

for _, name in ipairs(TABS) do
    -- sidebar button
    local btn = inst('TextButton', {
        Text = ICONS[name]..'\n'..name,
        Size = UDim2.new(1,0,0,60),
        BackgroundColor3 = PANEL, BackgroundTransparency=0,
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = TSEC, TextWrapped = true,
        BorderSizePixel = 0, Parent = TabList
    })
    -- active indicator strip
    local line = inst('Frame', {
        Name='Line', Size=UDim2.new(0,3,0.5,0), Position=UDim2.new(1,-3,0.25,0),
        BackgroundColor3=ACCENT, BackgroundTransparency=1, BorderSizePixel=0, Parent=btn
    })
    rnd(line, UDim.new(0,2))
    tabBtns[name] = btn

    -- content page (placed inside Content, hidden by default)
    local pg = inst('Frame', {
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, Visible=false, Parent=Content
    })
    vlist(pg, 8)
    pages[name] = pg

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then switchTab(name) end
    end)
end

-- ═══════════════════════════════════════════════════════
--  UI COMPONENTS
-- ═══════════════════════════════════════════════════════
local function Section(parent, text)
    local f = inst('Frame', {
        Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Parent=parent
    })
    inst('TextLabel', {
        Text=text:upper(), Size=UDim2.new(1,-4,0,14), Position=UDim2.new(0,2,0,6),
        BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=9,
        TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Left, Parent=f
    })
    inst('Frame', {
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=SEP, BorderSizePixel=0, Parent=f
    })
end

local function Hint(parent, text)
    local lbl = inst('TextLabel', {
        Text=text, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=EL, BackgroundTransparency=0.45, BorderSizePixel=0,
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=TSEC,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        Parent=parent
    })
    rnd(lbl, UDim.new(0,6)); pad(lbl, 7,7,10,10)
end

local function Button(parent, text, cb, isDanger)
    local btn = inst('TextButton', {
        Size=UDim2.new(1,0,0,BTN_H), BackgroundColor3=isDanger and DANGER or EL,
        BackgroundTransparency=isDanger and 0.3 or 0,
        Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=isDanger and Color3.fromRGB(255,200,200) or ACCENT,
        Text=text, BorderSizePixel=0, Parent=parent
    })
    rnd(btn); strk(btn, isDanger and Color3.fromRGB(160,40,40) or ACCDIM, 1)
    local function fire()
        tw(btn, {BackgroundColor3=ELHOV}, 0.08)
        task.delay(0.16, function() tw(btn, {BackgroundColor3=isDanger and DANGER or EL}, 0.1) end)
        if cb then task.spawn(pcall, cb) end
    end
    btn.MouseButton1Click:Connect(fire)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then fire() end
    end)
    return btn
end

local function Toggle(parent, text, default, cb)
    local state = default or false
    local row = inst('Frame', {
        Size=UDim2.new(1,0,0,BTN_H), BackgroundColor3=EL,
        BorderSizePixel=0, Parent=parent
    })
    rnd(row)
    inst('TextLabel', {
        Text=text, Size=UDim2.new(1,-58,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=13,
        TextColor3=TPRI, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=row
    })
    local track = inst('Frame', {
        Size=UDim2.new(0,44,0,24), Position=UDim2.new(1,-52,0.5,-12),
        BackgroundColor3=state and TOGON or TOGOFF,
        BorderSizePixel=0, Parent=row
    })
    rnd(track, UDim.new(1,0))
    local thumb = inst('Frame', {
        Size=UDim2.new(0,18,0,18),
        Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=THUMB, BorderSizePixel=0, Parent=track
    })
    rnd(thumb, UDim.new(1,0))
    local function set(s)
        state = s
        tw(track, {BackgroundColor3=s and TOGON or TOGOFF})
        tw(thumb, {Position=s and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if cb then task.spawn(pcall, cb, s) end
    end
    local hit = inst('TextButton', {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text='', Parent=row})
    hit.MouseButton1Click:Connect(function() set(not state) end)
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then set(not state) end
    end)
    return {Set=set, Get=function() return state end}
end

local function Slider(parent, text, mn, mx, default, step, cb)
    local val = default
    local row = inst('Frame', {
        Size=UDim2.new(1,0,0,62), BackgroundColor3=EL, BorderSizePixel=0, Parent=parent
    })
    rnd(row)
    local top = inst('Frame', {
        Size=UDim2.new(1,-20,0,28), Position=UDim2.new(0,10,0,7),
        BackgroundTransparency=1, Parent=row
    })
    inst('TextLabel', {
        Text=text, Size=UDim2.new(0.65,0,1,0), BackgroundTransparency=1,
        Font=Enum.Font.Gotham, TextSize=13, TextColor3=TPRI,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=top
    })
    local valLbl = inst('TextLabel', {
        Text=tostring(val), Size=UDim2.new(0.35,0,1,0), Position=UDim2.new(0.65,0,0,0),
        BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=ACCENT, TextXAlignment=Enum.TextXAlignment.Right, Parent=top
    })
    local trackBG = inst('Frame', {
        Size=UDim2.new(1,-20,0,6), Position=UDim2.new(0,10,0,44),
        BackgroundColor3=SEP, BorderSizePixel=0, Parent=row
    })
    rnd(trackBG, UDim.new(1,0))
    local p0 = (val-mn)/(mx-mn)
    local fill = inst('Frame', {Size=UDim2.new(p0,0,1,0), BackgroundColor3=ACCENT, BorderSizePixel=0, Parent=trackBG})
    rnd(fill, UDim.new(1,0))
    local knob = inst('Frame', {
        Size=UDim2.new(0,18,0,18), Position=UDim2.new(p0,-9,0.5,-9),
        BackgroundColor3=THUMB, BorderSizePixel=0, ZIndex=3, Parent=trackBG
    })
    rnd(knob, UDim.new(1,0)); strk(knob, ACCDIM, 1.5)

    local function setVal(v)
        v = math.clamp(math.round((v-mn)/step)*step+mn, mn, mx)
        val = v
        local p = (v-mn)/(mx-mn)
        tw(fill, {Size=UDim2.new(p,0,1,0)}, 0.05)
        tw(knob, {Position=UDim2.new(p,-9,0.5,-9)}, 0.05)
        valLbl.Text = tostring(v)
        if cb then task.spawn(pcall, cb, v) end
    end

    local slDrag = false
    local function drag(pos)
        local rel = math.clamp((pos.X - trackBG.AbsolutePosition.X) / trackBG.AbsoluteSize.X, 0, 1)
        setVal(mn + rel*(mx-mn))
    end
    trackBG.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            slDrag = true; drag(i.Position)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if slDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then drag(i.Position) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then slDrag = false end
    end)
    return {Set=setVal, Get=function() return val end}
end

-- ═══════════════════════════════════════════════════════
--  BUILD PAGES
-- ═══════════════════════════════════════════════════════

-- ─── DUPE ───────────────────────────────────────────────
local Dp = pages['Dupe']

Section(Dp, 'Status')

local slotLabel = inst('TextLabel', {
    Text='Loaded Slot:  checking...',
    Size=UDim2.new(1,0,0,40), BackgroundColor3=EL,
    BackgroundTransparency=0, BorderSizePixel=0,
    Font=Enum.Font.GothamBold, TextSize=13, TextColor3=TPRI,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=Dp
})
rnd(slotLabel); pad(slotLabel, 0,0,12,12)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local slot = Player.CurrentSaveSlot.Value
            slotLabel.Text = (slot and slot > 0)
                and ('✅  Loaded Slot:  '..tostring(slot)..'   —   Ready')
                or  '❌  No slot loaded — load one from in-game menu!'
            slotLabel.TextColor3 = (slot and slot > 0)
                and ACCENT or Color3.fromRGB(220,80,80)
        end)
    end
end)

Section(Dp, 'Dupe Axe')
Hint(Dp, '1) Load a slot in-game  2) Have axe in inventory  3) Press Dupe Axe  4) Script equips axe, kills you, auto-confirms land at same spot  5) Pick up the dropped axe = 2 axes')
Button(Dp, '🪓  Dupe Axe', function()
    if not dupeRunning then
        task.spawn(dupeAxe)
    else
        notify('Dupe is already running!')
    end
end)

Section(Dp, 'Manual')
Button(Dp, 'Drop All Axes', function()
    local h = hum()
    if h then h:UnequipTools() end
    task.wait(0.2)
    local axes = getAxes()
    if #axes == 0 then return notify('No axes found!') end
    for _, axe in ipairs(axes) do
        local r = root()
        if r then ClientInteracted:FireServer(axe, 'Drop tool', r.CFrame) end
        task.wait(0.1)
    end
    notify('Dropped '..#axes..' axe(s).')
end)
Button(Dp, 'Safe Suicide  ⚠', function()
    safeSuicide()
end, true)

-- ─── AXE ────────────────────────────────────────────────
local Ax = pages['Axe']

Section(Ax, 'Axe Modifiers')
Hint(Ax, 'Equip an axe first. Mods auto-reapply on equip.')

local rangeSlider = Slider(Ax, 'Range', 10, 400, 50, 5, function(v)
    axeModState.rangeVal = v
    if axeModState.rangeOn then pcall(applyAxeMod) end
end)

Toggle(Ax, 'Activate Axe Range', false, function(v)
    axeModState.rangeOn = v
    pcall(applyAxeMod)
end)

Toggle(Ax, 'No Swing Cooldown', false, function(v)
    axeModState.noCd = v
    pcall(applyAxeMod)
end)

-- ─── PLAYER ─────────────────────────────────────────────
local Pl = pages['Player']

Section(Pl, 'Movement')
Slider(Pl, 'Walk Speed', 16, 100, 16, 1, function(v)
    local h = hum(); if h then h.WalkSpeed = v end
end)
Slider(Pl, 'Jump Power', 50, 200, 50, 5, function(v)
    local h = hum(); if h then h.JumpPower = v end
end)
Toggle(Pl, 'Noclip', false, function(v)
    setNoclip(v)
end)

Section(Pl, 'Utility')
Toggle(Pl, 'Anti-AFK', true, function(v)
    pcall(setAntiAFK, v)
end)
Button(Pl, 'Respawn  (Safe Suicide)', function()
    safeSuicide()
end, true)

-- ─── WOOD ───────────────────────────────────────────────
local Wd = pages['Wood']

Section(Wd, 'Logs')
Hint(Wd, 'Teleports all your owned logs to the wood dropper at the sawmill.')
Button(Wd, 'Sell All Logs', function()
    sellAllLogs()
end)

Section(Wd, 'Auto Chop')
Hint(Wd, 'Chops trees within ~22 studs. Stand next to one and equip an axe.')
Toggle(Wd, 'Auto Chop Trees', false, function(v)
    if v then
        startAutoChop()
    else
        autoChopActive = false
    end
end)

-- ═══════════════════════════════════════════════════════
--  OPEN ON DUPE TAB
-- ═══════════════════════════════════════════════════════
switchTab('Dupe')
print('[Delta Hub] Loaded — Dupe tab is active | Drag title bar to move')
