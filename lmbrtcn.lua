-- ═══════════════════════════════════════════════════════
--  Delta Hub  |  LT2  |  Mobile-First
-- ═══════════════════════════════════════════════════════
if getgenv().DeltaHub_Loaded then return print('[Delta] Already loaded.') end
getgenv().DeltaHub_Loaded = true

repeat task.wait()
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChild('PlayerGui')
    and game.Players.LocalPlayer.PlayerGui:FindFirstChild('OnboardingGUI')
    and game.Players.LocalPlayer.PlayerGui.OnboardingGUI.DoOnboarding.Loaded.Value

local Players           = game:GetService('Players')
local RunService        = game:GetService('RunService')
local UIS               = game:GetService('UserInputService')
local TweenService      = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Player            = Players.LocalPlayer

-- ── REMOTES ───────────────────────────────────────────
local ClientInteracted        = ReplicatedStorage.Interaction.ClientInteracted
local ClientIsDragging        = ReplicatedStorage.Interaction.ClientIsDragging
local RemoteProxy             = ReplicatedStorage.Interaction.RemoteProxy
local SendUserNotice          = ReplicatedStorage.Notices.SendUserNotice
local AxeFolder               = ReplicatedStorage.AxeClasses
local RequestLoad             = ReplicatedStorage.LoadSaveRequests.RequestLoad
local RequestSave             = ReplicatedStorage.LoadSaveRequests.RequestSave
local ClientMayLoad           = ReplicatedStorage.LoadSaveRequests.ClientMayLoad
local SelectLoadPlot          = ReplicatedStorage.PropertyPurchasing.SelectLoadPlot
local ClientPurchasedProperty = ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty
local ClientExpandedProperty  = ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty

-- ── HELPERS ───────────────────────────────────────────
local function char()  return Player.Character end
local function hum()   local c=char(); return c and c:FindFirstChild('Humanoid') end
local function root()  local c=char(); return c and c:FindFirstChild('HumanoidRootPart') end

local function notify(msg)
    pcall(function() SendUserNotice:Fire(msg) end)
end

local function getAxes()
    local t={}; local c=char(); if not c then return t end
    for _,v in ipairs(Player.Backpack:GetChildren()) do
        if v:FindFirstChild('CuttingTool') then t[#t+1]=v end
    end
    for _,v in ipairs(c:GetChildren()) do
        if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then t[#t+1]=v end
    end
    return t
end

local function safeSuicide()
    pcall(function() char().Head:Destroy() end)
end

local function getMyProp()
    for _,p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild('Owner') and p.Owner.Value==Player then return p end
    end
end

local function getFreeProp()
    local best,dist=nil,math.huge; local r=root(); if not r then return end
    for _,p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild('Owner') and p.Owner.Value==nil and p:FindFirstChild('OriginSquare') then
            local d=(p.OriginSquare.CFrame.p-r.CFrame.p).Magnitude
            if d<dist then dist=d; best=p end
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════════
--  DUPE AXE
--  Correct order:
--  1. RequestSave NOW  → save file has axe
--  2. Drop axe         → axe in world, save unchanged
--  3. safeSuicide      → character resets (matches working-script behavior)
--  4. Wait respawn + cooldown
--  5. Hook SelectLoadPlot → return plotCF directly (NO getsenv/PClient needed)
--  6. RequestLoad      → save restores axe to inventory
--  7. Pick up world axe = 2 axes
-- ═══════════════════════════════════════════════════════
local dupeRunning = false

local function dupeAxe()
    if dupeRunning then
        -- Second press = force reset if stuck
        dupeRunning = false
        return notify('Dupe reset! Press again to start fresh.')
    end

    local slot = Player.CurrentSaveSlot.Value
    if not slot or slot <= 0 then return notify('Load a slot from in-game menu first!') end

    local c = char(); local h = hum(); local r = root()
    if not c or not h or not r then return notify('No character!') end

    local axe = nil
    for _, v in ipairs(Player.Backpack:GetChildren()) do
        if v:FindFirstChild('CuttingTool') then axe = v; break end
    end
    if not axe then
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then axe = v; break end
        end
    end
    if not axe then return notify('No axe found!') end

    local prop = getMyProp()
    if not prop or not prop:FindFirstChild('OriginSquare') then
        return notify('Load your land first!')
    end
    local plotCF = prop.OriginSquare.CFrame

    dupeRunning = true

    -- 1) Save slot so save file records the axe in inventory
    notify('[1/5] Saving slot '..slot..'...')
    pcall(function() RequestSave:InvokeServer(slot, Player) end)
    task.wait(2)

    -- 2) Unequip + drop axe into world
    notify('[2/5] Dropping axe...')
    h:UnequipTools()
    task.wait(0.3)
    -- Re-grab references after unequip
    local r2 = root()
    if r2 then ClientInteracted:FireServer(axe, 'Drop tool', r2.CFrame) end
    task.wait(0.5)

    -- 3) Kill character — resets state, matches working-script behavior
    notify('[3/5] Resetting character...')
    safeSuicide()

    -- Wait for character to fully respawn before continuing
    local respawnTimer = 0
    repeat
        task.wait(0.2)
        respawnTimer += 0.2
    until (char() and hum() and root()) or respawnTimer >= 12
    task.wait(1.5) -- extra settle time after spawn

    -- 4) Wait out the 60s load cooldown
    --    We count from 0 because suicide already used ~2-3s
    notify('[4/5] Waiting cooldown...')
    for i = 62, 1, -1 do
        task.wait(1)
        if i == 45 or i == 30 or i == 15 or i <= 5 then
            notify('[4/5] ~'..i..'s remaining...')
        end
    end

    -- 5) Hook SelectLoadPlot + invoke RequestLoad
    --    THE FIX: just return plotCF directly — no getsenv / PClient / getupvalue needed.
    --    SelectLoadPlot:InvokeClient only needs a CFrame back; we already have it.
    notify('[5/5] Reloading slot '..slot..'...')

    local origHook = SelectLoadPlot.OnClientInvoke
    SelectLoadPlot.OnClientInvoke = function(_model)
        -- Simply confirm the same land position. Done.
        return plotCF, 0
    end

    local done = false
    task.spawn(function()
        pcall(function() RequestLoad:InvokeServer(slot, Player) end)
        done = true
    end)

    -- Wait up to 25s for the invoke round-trip
    local t = 0
    repeat task.wait(0.5); t += 0.5 until done or t >= 25

    pcall(function() SelectLoadPlot.OnClientInvoke = origHook end)
    dupeRunning = false

    if done then
        notify('✅ Done! Walk back and pick up the dropped axe = 2 axes!')
    else
        notify('⚠ Reload timed out — try manually reloading your slot.')
    end
end

-- ═══════════════════════════════════════════════════════
--  FREE LAND & MAX LAND
-- ═══════════════════════════════════════════════════════
local function freeLand()
    local prop = getFreeProp()
    if not prop then return notify('No free land nearby!') end
    ClientPurchasedProperty:FireServer(prop, prop.OriginSquare.CFrame.p)
    notify('Free land acquired!')
    task.wait(0.5)
    local c=char()
    if c then c:PivotTo(CFrame.new(prop.OriginSquare.CFrame.p+Vector3.new(0,6,0))) end
end

local function maxLand()
    local prop=getMyProp()
    if not prop then
        notify('Getting free land first...')
        freeLand(); task.wait(2)
        prop=getMyProp()
    end
    if not prop then return notify('No land found!') end
    local s=prop.OriginSquare
    local x,y,z=s.Position.X,s.Position.Y,s.Position.Z
    local offs={
        {40,0},{-40,0},{0,40},{0,-40},
        {40,40},{40,-40},{-40,40},{-40,-40},
        {80,0},{-80,0},{0,80},{0,-80},
        {80,80},{80,-80},{-80,80},{-80,-80},
        {40,80},{-40,80},{80,40},{80,-40},
        {-80,40},{-80,-40},{40,-80},{-40,-80},
    }
    for _,o in ipairs(offs) do
        ClientExpandedProperty:FireServer(prop, CFrame.new(x+o[1],y,z+o[2]))
        task.wait(0.05)
    end
    notify('Land maxed!')
end

-- ═══════════════════════════════════════════════════════
--  AXE MODS
-- ═══════════════════════════════════════════════════════
local axeMods={rangeOn=false,rangeVal=50,noCdOn=false}

local function applyAxeMod()
    if not axeMods.rangeOn and not axeMods.noCdOn then return end
    local c=char(); if not c then return end
    local tool=c:FindFirstChildOfClass('Tool')
    if not tool or not tool:FindFirstChild('ToolName') then return end
    local w=0
    repeat task.wait(0.1); w+=0.1 until getconnections(tool.Activated)[1] or w>3
    local conn=getconnections(tool.Activated)[1]; if not conn then return end
    pcall(function()
        local stats=getupvalues(conn.Function)[1]
        local cls=require(AxeFolder['AxeClass_'..tool.ToolName.Value]).new()
        if axeMods.rangeOn then stats.Range=axeMods.rangeVal end
        stats.SwingCooldown = axeMods.noCdOn and 0 or cls.SwingCooldown
        setupvalue(conn.Function,1,stats)
    end)
end

local function hookChar(c)
    c.ChildAdded:Connect(function(o)
        if o:IsA('Tool') then task.wait(0.25); pcall(applyAxeMod) end
    end)
end
if char() then hookChar(char()) end
Player.CharacterAdded:Connect(hookChar)

-- ═══════════════════════════════════════════════════════
--  NOCLIP / ANTI-AFK / SELL LOGS / AUTO CHOP
-- ═══════════════════════════════════════════════════════
local noclipConn
local function setNoclip(on)
    if on then
        noclipConn=RunService.Stepped:Connect(function()
            pcall(function()
                for _,p in ipairs(char():GetDescendants()) do
                    if p:IsA('BasePart') then p.CanCollide=false end
                end
            end)
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    end
end

local function setAntiAFK(on)
    local c=getconnections(Player.Idled)[1]; if not c then return end
    if on then c:Disable() else c:Enable() end
end
pcall(setAntiAFK,true)

local function sellAllLogs()
    local n=0
    for _,log in ipairs(workspace.LogModels:GetChildren()) do
        if log:FindFirstChild('Owner') and (log.Owner.Value==nil or log.Owner.Value==Player) then
            n+=1
            task.spawn(function()
                pcall(function()
                    log.PrimaryPart=log.PrimaryPart or log:FindFirstChildOfClass('Part')
                    if not log.PrimaryPart then return end
                    local r=root()
                    if r and (r.CFrame.p-log.PrimaryPart.CFrame.p).Magnitude>=8 then
                        Player.Character:PivotTo(CFrame.new(log.PrimaryPart.CFrame.p+Vector3.new(0,5,0)))
                    end
                    for _=1,20 do ClientIsDragging:FireServer(log); task.wait(0.1) end
                    for _=1,35 do log:PivotTo(CFrame.new(315,3,85)) end
                end)
            end)
        end
    end
    notify(n>0 and 'Selling '..n..' log(s)...' or 'No owned logs.')
end

local autoChop=false
local function startAutoChop()
    autoChop=true
    task.spawn(function()
        while autoChop do
            task.wait(0.25)
            pcall(function()
                local r=root(); if not r then return end
                local axe=getAxes()[1]
                if not axe or not axe:FindFirstChild('ToolName') then return end
                local hp=5
                pcall(function() hp=require(AxeFolder['AxeClass_'..axe.ToolName.Value]).new().Damage end)
                for _,region in ipairs(workspace:GetChildren()) do
                    if tostring(region):match('TreeRegion') then
                        for _,tree in ipairs(region:GetChildren()) do
                            if tree:FindFirstChild('CutEvent') then
                                local ws=tree:FindFirstChild('WoodSection')
                                if ws and (r.CFrame.p-ws.CFrame.p).Magnitude<=22 then
                                    local lo=9e9
                                    for _,s in ipairs(tree:GetChildren()) do
                                        if tostring(s):match('WoodSection') and s:FindFirstChild('ID') and s.ID.Value<lo then lo=s.ID.Value end
                                    end
                                    RemoteProxy:FireServer(tree.CutEvent,{
                                        tool=axe,faceVector=Vector3.new(1,0,0),
                                        height=0.3,sectionId=lo,hitPoints=hp,
                                        cooldown=0.1,cuttingClass='Axe',
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

-- ═══════════════════════════════════════════════════════
--  UI THEME
-- ═══════════════════════════════════════════════════════
local C={
    BG=Color3.fromRGB(10,13,22), Panel=Color3.fromRGB(16,20,34),
    El=Color3.fromRGB(21,27,44), ElH=Color3.fromRGB(28,36,58),
    Acc=Color3.fromRGB(0,205,145), AccD=Color3.fromRGB(0,140,98),
    TP=Color3.fromRGB(220,228,242), TS=Color3.fromRGB(110,128,155),
    TOn=Color3.fromRGB(0,205,145), TOff=Color3.fromRGB(40,50,72),
    Th=Color3.fromRGB(235,240,252), Dng=Color3.fromRGB(200,50,50),
    Sep=Color3.fromRGB(28,38,58),
}
local SW=68; local WW=330; local WH=385; local TH=38; local BH=46

local function N(cls,p)
    local o=Instance.new(cls)
    for k,v in pairs(p) do if k~='Parent' then o[k]=v end end
    if p.Parent then o.Parent=p.Parent end
    return o
end
local function rnd(o,r) local x=Instance.new('UICorner');x.CornerRadius=r or UDim.new(0,8);x.Parent=o end
local function strk(o,col,th) local s=Instance.new('UIStroke');s.Color=col;s.Thickness=th or 1;s.Parent=o end
local function vl(o,gap) local l=Instance.new('UIListLayout');l.Padding=UDim.new(0,gap or 6);l.SortOrder=Enum.SortOrder.LayoutOrder;l.Parent=o;return l end
local function pd(o,t,b,l,r) local p=Instance.new('UIPadding');p.PaddingTop=UDim.new(0,t or 8);p.PaddingBottom=UDim.new(0,b or 8);p.PaddingLeft=UDim.new(0,l or 10);p.PaddingRight=UDim.new(0,r or 10);p.Parent=o end
local function tw(o,pr,t) TweenService:Create(o,TweenInfo.new(t or 0.14,Enum.EasingStyle.Quad),pr):Play() end

-- ═══════════════════════════════════════════════════════
--  SCREEN GUI + WINDOW
-- ═══════════════════════════════════════════════════════
local gp = pcall(function() return game:GetService('CoreGui') end)
    and game:GetService('CoreGui') or Player.PlayerGui

local SG = N('ScreenGui',{Name='DeltaHub',ResetOnSpawn=false,IgnoreGuiInset=true,
    DisplayOrder=999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=gp})

-- Minimised pill (shown when window is hidden)
local Pill = N('TextButton',{Text='▲  Delta Hub',Size=UDim2.new(0,110,0,34),
    Position=UDim2.new(0.5,-55,0,14),BackgroundColor3=C.Panel,
    Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.Acc,
    BorderSizePixel=0,Visible=false,ZIndex=50,Parent=SG})
rnd(Pill,UDim.new(0,18)); strk(Pill,C.AccD,1)

-- Main window
local Main = N('Frame',{Name='Main',Size=UDim2.new(0,WW,0,WH),
    Position=UDim2.new(0.5,-WW/2,0.45,-WH/2),
    BackgroundColor3=C.BG,BorderSizePixel=0,ClipsDescendants=true,Parent=SG})
rnd(Main,UDim.new(0,12)); strk(Main,Color3.fromRGB(32,46,70),1)

-- Title bar
local TBar=N('Frame',{Size=UDim2.new(1,0,0,TH),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=6,Parent=Main})
local dot=N('Frame',{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0,12,0.5,-3),BackgroundColor3=C.Acc,BorderSizePixel=0,ZIndex=7,Parent=TBar})
rnd(dot,UDim.new(1,0))
N('TextLabel',{Text='Delta Hub',Size=UDim2.new(0,120,1,0),Position=UDim2.new(0,26,0,0),
    BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=14,
    TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=TBar})
N('TextLabel',{Text='LT2',Size=UDim2.new(0,35,1,0),Position=UDim2.new(0,148,0,0),
    BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,
    TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=TBar})
N('Frame',{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Sep,BorderSizePixel=0,ZIndex=6,Parent=TBar})

-- Close button
local CloseBtn=N('TextButton',{Text='✕',Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-34,0.5,-14),
    BackgroundColor3=C.Dng,BackgroundTransparency=0.3,Font=Enum.Font.GothamBold,
    TextSize=13,TextColor3=C.TP,BorderSizePixel=0,ZIndex=8,Parent=TBar})
rnd(CloseBtn,UDim.new(0,6))

-- Minimise button
local MinBtn=N('TextButton',{Text='─',Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-66,0.5,-14),
    BackgroundColor3=C.El,BackgroundTransparency=0.2,Font=Enum.Font.GothamBold,
    TextSize=16,TextColor3=C.TS,BorderSizePixel=0,ZIndex=8,Parent=TBar})
rnd(MinBtn,UDim.new(0,6))

-- Minimise / Restore logic
local function minimize()
    Main.Visible=false; Pill.Visible=true
end
local function restore()
    Pill.Visible=false; Main.Visible=true
end
MinBtn.MouseButton1Click:Connect(minimize)
MinBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then minimize() end end)
Pill.MouseButton1Click:Connect(restore)
Pill.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then restore() end end)
CloseBtn.MouseButton1Click:Connect(function() SG:Destroy(); getgenv().DeltaHub_Loaded=false end)

-- Drag main window
local _d,_s,_m=false
TBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        _d=true; _s=Main.Position; _m=i.Position end
end)
UIS.InputChanged:Connect(function(i)
    if _d and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then
        local d=i.Position-_m
        Main.Position=UDim2.new(_s.X.Scale,_s.X.Offset+d.X,_s.Y.Scale,_s.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then _d=false end
end)
-- Drag pill
local _pd,_ps,_pm=false
Pill.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch then _pd=true; _ps=Pill.Position; _pm=i.Position end
end)
UIS.InputChanged:Connect(function(i)
    if _pd and i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-_pm
        Pill.Position=UDim2.new(_ps.X.Scale,_ps.X.Offset+d.X,_ps.Y.Scale,_ps.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch then _pd=false end
end)

-- Body
local Body=N('Frame',{Size=UDim2.new(1,0,1,-TH),Position=UDim2.new(0,0,0,TH),BackgroundTransparency=1,Parent=Main})

-- Sidebar
local Sidebar=N('Frame',{Size=UDim2.new(0,SW,1,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=Body})
N('Frame',{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=Sidebar})
local TabList=N('ScrollingFrame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
    ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,
    ElasticBehavior=Enum.ElasticBehavior.Never,CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=Sidebar})
vl(TabList,0)

-- Content scroll
local Content=N('ScrollingFrame',{Size=UDim2.new(1,-SW,1,0),Position=UDim2.new(0,SW,0,0),
    BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,
    ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.Never,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=Body})
pd(Content,10,14,10,10); vl(Content,8)

-- ─── TABS ────────────────────────────────────────────
local TABS={'Dupe','Land','Axe','Player','Wood'}
local ICONS={Dupe='📦',Land='🏠',Axe='🪓',Player='👤',Wood='🌲'}
local pages,tabBtns,activeTab={},{},nil

local function switchTab(name)
    for _,pg in pairs(pages) do pg.Visible=false end
    for _,b in pairs(tabBtns) do
        b.BackgroundColor3=C.Panel; b.TextColor3=C.TS
        if b:FindFirstChild('Ln') then b.Ln.BackgroundTransparency=1 end
    end
    if pages[name] then pages[name].Visible=true end
    if tabBtns[name] then
        tabBtns[name].BackgroundColor3=C.El; tabBtns[name].TextColor3=C.Acc
        if tabBtns[name]:FindFirstChild('Ln') then tabBtns[name].Ln.BackgroundTransparency=0 end
    end
    activeTab=name
end

for _,name in ipairs(TABS) do
    local btn=N('TextButton',{Text=ICONS[name]..'\n'..name,Size=UDim2.new(1,0,0,56),
        BackgroundColor3=C.Panel,Font=Enum.Font.GothamBold,TextSize=10,
        TextColor3=C.TS,TextWrapped=true,BorderSizePixel=0,Parent=TabList})
    local ln=N('Frame',{Name='Ln',Size=UDim2.new(0,3,0.5,0),Position=UDim2.new(1,-3,0.25,0),
        BackgroundColor3=C.Acc,BackgroundTransparency=1,BorderSizePixel=0,Parent=btn})
    rnd(ln,UDim.new(0,2)); tabBtns[name]=btn
    local pg=N('Frame',{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,Visible=false,Parent=Content})
    vl(pg,8); pages[name]=pg
    local function act() switchTab(name) end
    btn.MouseButton1Click:Connect(act)
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then act() end end)
end

-- ─── COMPONENTS ──────────────────────────────────────
local function Section(p,txt)
    local f=N('Frame',{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Parent=p})
    N('TextLabel',{Text=txt:upper(),Size=UDim2.new(1,-4,0,14),Position=UDim2.new(0,2,0,6),
        BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=9,
        TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    N('Frame',{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=f})
end

local function Hint(p,txt)
    local l=N('TextLabel',{Text=txt,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=C.El,BackgroundTransparency=0.4,BorderSizePixel=0,
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TS,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=p})
    rnd(l,UDim.new(0,6)); pd(l,7,7,10,10)
end

local function InfoLbl(p,txt)
    local l=N('TextLabel',{Text=txt,Size=UDim2.new(1,0,0,BH),
        BackgroundColor3=C.El,BackgroundTransparency=0,BorderSizePixel=0,
        Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.TP,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=p})
    rnd(l); pd(l,0,0,12,12)
    return {Set=function(v,col) l.Text=v; if col then l.TextColor3=col end end}
end

local function Btn(p,txt,cb,danger)
    local b=N('TextButton',{Size=UDim2.new(1,0,0,BH),
        BackgroundColor3=danger and C.Dng or C.El,BackgroundTransparency=danger and 0.3 or 0,
        Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=danger and Color3.fromRGB(255,200,200) or C.Acc,
        Text=txt,BorderSizePixel=0,Parent=p})
    rnd(b); strk(b,danger and Color3.fromRGB(140,30,30) or C.AccD,1)
    local function fire()
        tw(b,{BackgroundColor3=C.ElH},0.08)
        task.delay(0.16,function() tw(b,{BackgroundColor3=danger and C.Dng or C.El},0.1) end)
        if cb then task.spawn(pcall,cb) end
    end
    b.MouseButton1Click:Connect(fire)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then fire() end end)
end

local function Tog(p,txt,def,cb)
    local st=def or false
    local row=N('Frame',{Size=UDim2.new(1,0,0,BH),BackgroundColor3=C.El,BorderSizePixel=0,Parent=p})
    rnd(row)
    N('TextLabel',{Text=txt,Size=UDim2.new(1,-58,1,0),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TP,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=row})
    local tr=N('Frame',{Size=UDim2.new(0,44,0,24),Position=UDim2.new(1,-52,0.5,-12),
        BackgroundColor3=st and C.TOn or C.TOff,BorderSizePixel=0,Parent=row})
    rnd(tr,UDim.new(1,0))
    local th=N('Frame',{Size=UDim2.new(0,18,0,18),
        Position=st and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=C.Th,BorderSizePixel=0,Parent=tr})
    rnd(th,UDim.new(1,0))
    local function set(s)
        st=s; tw(tr,{BackgroundColor3=s and C.TOn or C.TOff})
        tw(th,{Position=s and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if cb then task.spawn(pcall,cb,s) end
    end
    local hit=N('TextButton',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text='',Parent=row})
    hit.MouseButton1Click:Connect(function() set(not st) end)
    hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then set(not st) end end)
    return {Set=set,Get=function() return st end}
end

local function Slid(p,txt,mn,mx,def,step,cb)
    local val=def
    local row=N('Frame',{Size=UDim2.new(1,0,0,62),BackgroundColor3=C.El,BorderSizePixel=0,Parent=p})
    rnd(row)
    local top=N('Frame',{Size=UDim2.new(1,-20,0,28),Position=UDim2.new(0,10,0,7),BackgroundTransparency=1,Parent=row})
    N('TextLabel',{Text=txt,Size=UDim2.new(0.65,0,1,0),BackgroundTransparency=1,
        Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,Parent=top})
    local vl2=N('TextLabel',{Text=tostring(val),Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),
        BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Right,Parent=top})
    local bg=N('Frame',{Size=UDim2.new(1,-20,0,6),Position=UDim2.new(0,10,0,44),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=row})
    rnd(bg,UDim.new(1,0))
    local p0=(val-mn)/(mx-mn)
    local fi=N('Frame',{Size=UDim2.new(p0,0,1,0),BackgroundColor3=C.Acc,BorderSizePixel=0,Parent=bg}); rnd(fi,UDim.new(1,0))
    local kn=N('Frame',{Size=UDim2.new(0,18,0,18),Position=UDim2.new(p0,-9,0.5,-9),BackgroundColor3=C.Th,BorderSizePixel=0,ZIndex=3,Parent=bg})
    rnd(kn,UDim.new(1,0)); strk(kn,C.AccD,1.5)
    local function sv(v)
        v=math.clamp(math.round((v-mn)/step)*step+mn,mn,mx); val=v
        local pp=(v-mn)/(mx-mn)
        tw(fi,{Size=UDim2.new(pp,0,1,0)},0.05); tw(kn,{Position=UDim2.new(pp,-9,0.5,-9)},0.05)
        vl2.Text=tostring(v); if cb then task.spawn(pcall,cb,v) end
    end
    local sd=false
    local function drag(pos)
        local rel=math.clamp((pos.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1); sv(mn+rel*(mx-mn))
    end
    bg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=true; drag(i.Position) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sd and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then drag(i.Position) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=false end
    end)
end

-- ═══════════════════════════════════════════════════════
--  BUILD TABS
-- ═══════════════════════════════════════════════════════

-- ── DUPE ────────────────────────────────────────────────
do
    local Dp=pages['Dupe']
    Section(Dp,'Status')
    local slotLbl=InfoLbl(Dp,'Loaded Slot: checking...')
    task.spawn(function()
        while task.wait(1) do pcall(function()
            local s=Player.CurrentSaveSlot.Value
            if s and s>0 then slotLbl.Set('✅  Slot '..s..' loaded',C.Acc)
            else slotLbl.Set('❌  No slot loaded!',Color3.fromRGB(220,70,70)) end
        end) end
    end)
    Section(Dp,'Dupe Axe')
    Hint(Dp,'Saves slot → drops axe → waits 60s cooldown → reloads slot → axe restored. Walk back and pick up dropped axe = 2 axes.')
    Btn(Dp,'🪓  Dupe Axe',function() task.spawn(dupeAxe) end)
    Section(Dp,'Manual')
    Btn(Dp,'Drop All Axes',function()
        local h=hum(); if h then h:UnequipTools() end; task.wait(0.25)
        local axes=getAxes()
        if #axes==0 then return notify('No axes!') end
        for _,a in ipairs(axes) do
            local r=root(); if r then ClientInteracted:FireServer(a,'Drop tool',r.CFrame) end; task.wait(0.1)
        end
        notify('Dropped '..#axes..' axe(s).')
    end)
    Btn(Dp,'Safe Suicide  ⚠',safeSuicide,true)
end

-- ── LAND ────────────────────────────────────────────────
do
    local La=pages['Land']
    Section(La,'Free Land')
    Hint(La,'Claims nearest free property for free by firing the purchase remote directly.')
    Btn(La,'🏠  Get Free Land',freeLand)
    Section(La,'Expand Land')
    Hint(La,'Fires all 24 expansion remotes to instantly max your land size. Auto-gets land if needed.')
    Btn(La,'📐  Max Land',maxLand)
    Section(La,'Combined')
    Btn(La,'⚡  Free Land + Max',function()
        freeLand(); task.wait(2); maxLand()
    end)
end

-- ── AXE ─────────────────────────────────────────────────
do
    local Ax=pages['Axe']
    Section(Ax,'Modifiers')
    Hint(Ax,'Equip axe first. Re-applies on every equip.')
    Slid(Ax,'Range',10,400,50,5,function(v) axeMods.rangeVal=v; if axeMods.rangeOn then pcall(applyAxeMod) end end)
    Tog(Ax,'Activate Axe Range',false,function(v) axeMods.rangeOn=v; pcall(applyAxeMod) end)
    Tog(Ax,'No Swing Cooldown',false,function(v) axeMods.noCdOn=v; pcall(applyAxeMod) end)
end

-- ── PLAYER ──────────────────────────────────────────────
do
    local Pl=pages['Player']
    Section(Pl,'Movement')
    Slid(Pl,'Walk Speed',16,100,16,1,function(v) local h=hum(); if h then h.WalkSpeed=v end end)
    Slid(Pl,'Jump Power',50,250,50,5,function(v) local h=hum(); if h then h.JumpPower=v end end)
    Tog(Pl,'Noclip',false,function(v) setNoclip(v) end)
    Section(Pl,'Utility')
    Tog(Pl,'Anti-AFK',true,function(v) pcall(setAntiAFK,v) end)
    Btn(Pl,'Safe Suicide  ⚠',safeSuicide,true)
end

-- ── WOOD ────────────────────────────────────────────────
do
    local Wd=pages['Wood']
    Section(Wd,'Logs')
    Hint(Wd,'Teleports owned logs to sawmill drop point.')
    Btn(Wd,'Sell All Logs',sellAllLogs)
    Section(Wd,'Auto Chop')
    Hint(Wd,'Stand near a tree with axe equipped.')
    Tog(Wd,'Auto Chop',false,function(v)
        if v then startAutoChop() else autoChop=false end
    end)
end

switchTab('Dupe')
print('[Delta Hub] Loaded | ─ = minimise | drag title bar | 5 tabs')
