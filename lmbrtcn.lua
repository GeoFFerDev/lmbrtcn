-- ═══════════════════════════════════════════════════════
--  Delta Hub  |  LT2  |  v12  |  REBUILT FROM CONFIRMED LOGIC
--
--  Previous versions failed because:
--  1. Tried to automate everything in one click — caused race conditions
--  2. Filtered axes by CuttingTool child — WRONG. LT2 axes are named "Tool"
--  3. SelectLoadPlot hook caused timing issues, overcomplicating the flow
--
--  v12 is built from the ONLY confirmed working dupe logic:
--    Step 1 → RequestSave (save your slot WITH axe)
--    Step 2 → Store Axe (b.Parent = Player, NOT Backpack)
--    Step 3 → RequestLoad (char resets, confirm land manually OR auto)
--    Step 4 → Restore Axe (b.Parent = Backpack)
--    Result → Backpack has original axe + load-restored axe = DOUBLED
--
--  The UI walks you through each step with clear buttons.
--  There is also a "1-Click Dupe" that runs steps 1-3 auto,
--  then you confirm land, then click Restore. Simple.
-- ═══════════════════════════════════════════════════════
if getgenv().DeltaHub_Loaded then return print('[Delta] Already loaded.') end
getgenv().DeltaHub_Loaded = true

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local LP = game.Players.LocalPlayer
repeat task.wait() until LP:FindFirstChild('PlayerGui')

-- Wait for game to fully load
local t0 = tick()
repeat task.wait()
until (LP.PlayerGui:FindFirstChild('OnboardingGUI')
    and LP.PlayerGui.OnboardingGUI:FindFirstChild('DoOnboarding')
    and LP.PlayerGui.OnboardingGUI.DoOnboarding:FindFirstChild('Loaded')
    and LP.PlayerGui.OnboardingGUI.DoOnboarding.Loaded.Value == true)
    or tick() - t0 > 20

local RS     = game:GetService('ReplicatedStorage')
local Run    = game:GetService('RunService')
local UIS    = game:GetService('UserInputService')
local Tween  = game:GetService('TweenService')

-- ── CONFIRMED REMOTES ─────────────────────────────────
local LoadSaveReq  = RS:WaitForChild('LoadSaveRequests')
local RequestSave  = LoadSaveReq:WaitForChild('RequestSave')   -- :InvokeServer(slot)
local RequestLoad  = LoadSaveReq:WaitForChild('RequestLoad')   -- :InvokeServer(slot)
local GetMetaData  = LoadSaveReq:WaitForChild('GetMetaData')   -- :InvokeServer(LP)

local PropPurch    = RS:WaitForChild('PropertyPurchasing')
local SelectLoadPlot = PropPurch:WaitForChild('SelectLoadPlot')

local ClientInteracted = RS.Interaction.ClientInteracted
local ClientIsDragging = RS.Interaction.ClientIsDragging
local RemoteProxy      = RS.Interaction.RemoteProxy
local AxeFolder        = RS.AxeClasses

local ClientPurchasedProp = PropPurch:FindFirstChild('ClientPurchasedProperty')
local ClientExpandedProp  = PropPurch:FindFirstChild('ClientExpandedProperty')

-- ── PLAYER SAVE VALUES ────────────────────────────────
local CurrentSaveSlot          = LP:WaitForChild('CurrentSaveSlot')
local CurrentlySavingOrLoading = LP:WaitForChild('CurrentlySavingOrLoading')

-- ── HELPERS ──────────────────────────────────────────
local function char()  return LP.Character end
local function hum()   local c=char(); return c and c:FindFirstChild('Humanoid') end
local function root()  local c=char(); return c and c:FindFirstChild('HumanoidRootPart') end

local function notify(msg)
    -- Use StarterGui notification (works without SendUserNotice)
    pcall(function()
        game.StarterGui:SetCore('SendNotification', {
            Title = 'Delta Hub';
            Text  = msg;
            Duration = 4;
        })
    end)
    -- Also try SendUserNotice as backup
    pcall(function() RS.Notices.SendUserNotice:Fire(msg) end)
end

-- ★ CONFIRMED: LT2 axes are named "Tool" (not filtered by CuttingTool)
-- This matches the exact filter from the working reference script.
local function isAxe(item)
    return item.Name == 'Tool' and item:IsA('Tool')
end

local function getBackpackAxes()
    local t = {}
    for _,v in ipairs(LP.Backpack:GetChildren()) do
        if isAxe(v) then t[#t+1] = v end
    end
    -- Also include equipped tool
    local c = char()
    if c then
        for _,v in ipairs(c:GetChildren()) do
            if v:IsA('Tool') and isAxe(v) then t[#t+1] = v end
        end
    end
    return t
end

local function countAllAxes()
    local n = 0
    for _,v in ipairs(LP.Backpack:GetChildren()) do if isAxe(v) then n+=1 end end
    local c = char()
    if c then for _,v in ipairs(c:GetChildren()) do if isAxe(v) then n+=1 end end end
    -- Also count parked on Player
    for _,v in ipairs(LP:GetChildren()) do
        if v:IsA('Tool') and isAxe(v) then n+=1 end
    end
    return n
end

local function getMyProp()
    for _,p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild('Owner') and p.Owner.Value == LP then return p end
    end
end

local function getFreeProp()
    local best, dist = nil, math.huge
    local r = root(); if not r then return end
    for _,p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild('Owner') and p.Owner.Value == nil and p:FindFirstChild('OriginSquare') then
            local d = (p.OriginSquare.CFrame.p - r.CFrame.p).Magnitude
            if d < dist then dist = d; best = p end
        end
    end
    return best
end

local function safeSuicide()
    pcall(function() char().Humanoid.Health = 0 end)
end

local function safeWaitChar(secs)
    local done, result = false, nil
    local conn = LP.CharacterAdded:Connect(function(c) result = c; done = true end)
    local t = os.clock()
    while not done and os.clock()-t < (secs or 20) do task.wait(0.1) end
    pcall(function() conn:Disconnect() end)
    return result or char()
end

-- ─────────────────────────────────────────────────────
--  DUPE CORE FUNCTIONS  (matching confirmed working logic exactly)
-- ─────────────────────────────────────────────────────

-- Step 1: Save current slot (captures axe in Backpack)
local function doSave(slot)
    if CurrentSaveSlot.Value == -1 then
        notify('❌ No slot loaded! Load a slot in-game first.')
        return false
    end
    if CurrentlySavingOrLoading.Value then
        notify('❌ Server busy. Wait and try again.')
        return false
    end
    local ok, res = pcall(function()
        return RequestSave:InvokeServer(slot)
    end)
    if not ok or res == false then
        notify('❌ Save failed or on cooldown. Try again.')
        return false
    end
    notify('✅ Slot ' .. slot .. ' saved!')
    return true
end

-- Step 2: Store axes — move from Backpack → Player object
-- (exact logic from confirmed working script)
local function doStore()
    local h = hum()
    if h then h:UnequipTools() end
    task.wait(0.2)
    local count = 0
    for _,b in ipairs(LP.Backpack:GetChildren()) do
        if isAxe(b) then
            b.Parent = LP   -- ← Key: move to Player, not Backpack
            count += 1
        end
    end
    if count == 0 then
        notify('❌ No axes in backpack to store!')
        return false
    end
    notify('📦 Stored ' .. count .. ' axe(s) safely on Player.')
    return true, count
end

-- Step 3: Load slot (triggers char reset → land confirm screen)
local function doLoad(slot, prop, autoConfirm)
    -- Validate slot has data
    local hasSave = false
    pcall(function()
        local meta = GetMetaData:InvokeServer(LP)
        for a,b in pairs(meta) do
            if a == slot then
                for c,d in pairs(b) do
                    if c == 'NumSaves' and d ~= 0 then hasSave = true end
                end
            end
        end
    end)
    if not hasSave then
        notify('❌ Slot ' .. slot .. ' has no save data! Save first (Step 1).')
        return false
    end

    -- Optionally hook SelectLoadPlot for auto land-confirm
    if autoConfirm and prop then
        local fired = false
        local hookLoop = true
        task.spawn(function()
            local tStart = os.clock()
            while hookLoop and not fired and os.clock()-tStart < 60 do
                pcall(function()
                    SelectLoadPlot.OnClientInvoke = function()
                        if fired then return prop, 0 end
                        fired = true; hookLoop = false
                        notify('🏠 Land auto-confirmed!')
                        return prop, 0
                    end
                end)
                task.wait(0.03)
            end
            hookLoop = false
            pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
        end)
    end

    local ok, res = pcall(function()
        return RequestLoad:InvokeServer(slot)
    end)
    if not ok then
        notify('❌ RequestLoad error. Are you in-game?')
        return false
    end
    if res == false then
        notify('❌ Load cooldown (~30s). Try again shortly.')
        return false
    end
    notify('🔄 Load triggered! Confirm land placement screen.')
    return true
end

-- Step 4: Restore axes — move from Player → Backpack
-- (exact logic from confirmed working script)
local function doRestore()
    local count = 0
    for _,b in ipairs(LP:GetChildren()) do
        if b:IsA('Tool') and isAxe(b) then
            b.Parent = LP.Backpack
            count += 1
        end
    end
    if count == 0 then
        notify('⚠️ No stored axes found on Player to restore.')
    else
        notify('✅ Restored ' .. count .. ' axe(s) to backpack!')
    end
    local total = countAllAxes()
    notify('🪓 Total axes now: ' .. total)
    return count
end

-- ─────────────────────────────────────────────────────
--  AXE MODS
-- ─────────────────────────────────────────────────────
local axeMods = {rangeOn=false, rangeVal=50, noCdOn=false}
local function applyAxeMod()
    if not axeMods.rangeOn and not axeMods.noCdOn then return end
    local c = char(); if not c then return end
    local tool = c:FindFirstChildOfClass('Tool')
    if not tool or not tool:FindFirstChild('ToolName') then return end
    local w = 0
    repeat task.wait(0.1); w+=0.1 until getconnections(tool.Activated)[1] or w > 3
    local conn = getconnections(tool.Activated)[1]; if not conn then return end
    pcall(function()
        local stats = getupvalues(conn.Function)[1]
        local cls = require(AxeFolder['AxeClass_'..tool.ToolName.Value]).new()
        if axeMods.rangeOn then stats.Range = axeMods.rangeVal end
        stats.SwingCooldown = axeMods.noCdOn and 0 or cls.SwingCooldown
        setupvalue(conn.Function, 1, stats)
    end)
end
local function hookChar(c)
    c.ChildAdded:Connect(function(o)
        if o:IsA('Tool') then task.wait(0.25); pcall(applyAxeMod) end
    end)
end
if char() then hookChar(char()) end
LP.CharacterAdded:Connect(hookChar)

-- ─────────────────────────────────────────────────────
--  MISC FEATURES
-- ─────────────────────────────────────────────────────
local function freeLand()
    local prop = getFreeProp()
    if not prop then return notify('No free land nearby!') end
    ClientPurchasedProp:FireServer(prop, prop.OriginSquare.CFrame.p)
    notify('🏠 Free land claimed!')
    task.wait(0.5)
    local c = char()
    if c then c:PivotTo(CFrame.new(prop.OriginSquare.CFrame.p + Vector3.new(0,6,0))) end
end

local function maxLand()
    local prop = getMyProp()
    if not prop then freeLand(); task.wait(2); prop = getMyProp() end
    if not prop then return notify('No land!') end
    local s = prop.OriginSquare
    local x,y,z = s.Position.X, s.Position.Y, s.Position.Z
    for _,o in ipairs({
        {40,0},{-40,0},{0,40},{0,-40},{40,40},{40,-40},{-40,40},{-40,-40},
        {80,0},{-80,0},{0,80},{0,-80},{80,80},{80,-80},{-80,80},{-80,-80},
        {40,80},{-40,80},{80,40},{80,-40},{-80,40},{-80,-40},{40,-80},{-40,-80},
    }) do
        ClientExpandedProp:FireServer(prop, CFrame.new(x+o[1],y,z+o[2]))
        task.wait(0.05)
    end
    notify('📐 Land maxed!')
end

local noclipConn
local function setNoclip(on)
    if on then
        noclipConn = Run.Stepped:Connect(function()
            pcall(function()
                for _,p in ipairs(char():GetDescendants()) do
                    if p:IsA('BasePart') then p.CanCollide = false end
                end
            end)
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    end
end

local function setAntiAFK(on)
    local c = getconnections(LP.Idled)[1]; if not c then return end
    if on then c:Disable() else c:Enable() end
end
pcall(setAntiAFK, true)

local function sellAllLogs()
    local n = 0
    for _,log in ipairs(workspace.LogModels:GetChildren()) do
        if log:FindFirstChild('Owner') and (log.Owner.Value == nil or log.Owner.Value == LP) then
            n += 1
            task.spawn(function()
                pcall(function()
                    log.PrimaryPart = log.PrimaryPart or log:FindFirstChildOfClass('Part')
                    if not log.PrimaryPart then return end
                    local r = root()
                    if r and (r.CFrame.p - log.PrimaryPart.CFrame.p).Magnitude >= 8 then
                        LP.Character:PivotTo(CFrame.new(log.PrimaryPart.CFrame.p + Vector3.new(0,5,0)))
                    end
                    for _ = 1,20 do ClientIsDragging:FireServer(log); task.wait(0.1) end
                    for _ = 1,35 do log:PivotTo(CFrame.new(315,3,85)) end
                end)
            end)
        end
    end
    notify(n > 0 and 'Selling '..n..' logs...' or 'No owned logs.')
end

local autoChop = false
local function startAutoChop()
    autoChop = true
    task.spawn(function()
        while autoChop do
            task.wait(0.25)
            pcall(function()
                local r = root(); if not r then return end
                local axe = getBackpackAxes()[1]
                if not axe or not axe:FindFirstChild('ToolName') then return end
                local hp = 5
                pcall(function() hp = require(AxeFolder['AxeClass_'..axe.ToolName.Value]).new().Damage end)
                for _,region in ipairs(workspace:GetChildren()) do
                    if tostring(region):match('TreeRegion') then
                        for _,tree in ipairs(region:GetChildren()) do
                            if tree:FindFirstChild('CutEvent') then
                                local ws = tree:FindFirstChild('WoodSection')
                                if ws and (r.CFrame.p - ws.CFrame.p).Magnitude <= 22 then
                                    local lo = 9e9
                                    for _,s in ipairs(tree:GetChildren()) do
                                        if tostring(s):match('WoodSection') and s:FindFirstChild('ID') and s.ID.Value < lo then lo = s.ID.Value end
                                    end
                                    RemoteProxy:FireServer(tree.CutEvent, {
                                        tool=axe, faceVector=Vector3.new(1,0,0),
                                        height=0.3, sectionId=lo, hitPoints=hp,
                                        cooldown=0.1, cuttingClass='Axe',
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
--  UI
-- ═══════════════════════════════════════════════════════
local C = {
    BG    = Color3.fromRGB(8,11,20),
    Panel = Color3.fromRGB(14,18,30),
    El    = Color3.fromRGB(20,25,42),
    ElH   = Color3.fromRGB(27,34,55),
    Acc   = Color3.fromRGB(0,210,150),
    AccD  = Color3.fromRGB(0,145,100),
    TP    = Color3.fromRGB(215,225,245),
    TS    = Color3.fromRGB(105,122,150),
    TOn   = Color3.fromRGB(0,210,150),
    TOff  = Color3.fromRGB(38,48,70),
    Th    = Color3.fromRGB(230,238,255),
    Dng   = Color3.fromRGB(195,45,45),
    Sep   = Color3.fromRGB(26,36,55),
    Blue  = Color3.fromRGB(60,150,255),
    Yel   = Color3.fromRGB(230,185,0),
}
local WW=410; local WH=240; local TH=30; local SW=50; local BH=36

local function N(cls,props)
    local o = Instance.new(cls)
    for k,v in pairs(props) do
        if k ~= 'Parent' then o[k] = v end
    end
    if props.Parent then o.Parent = props.Parent end
    return o
end
local function tw(o,p,t) Tween:Create(o,TweenInfo.new(t or 0.14,Enum.EasingStyle.Quad),p):Play() end
local function rnd(o,r) local u=Instance.new('UICorner'); u.CornerRadius=r or UDim.new(0,8); u.Parent=o end
local function strk(o,c,t) local s=Instance.new('UIStroke'); s.Color=c or C.AccD; s.Thickness=t or 1; s.Parent=o end
local function pad(o,t,b,l,r)
    local p=Instance.new('UIPadding')
    p.PaddingTop=UDim.new(0,t or 7); p.PaddingBottom=UDim.new(0,b or 7)
    p.PaddingLeft=UDim.new(0,l or 9); p.PaddingRight=UDim.new(0,r or 9)
    p.Parent=o
end

-- Window
local sg  = N('ScreenGui',{Name='DeltaHub',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=gethui and gethui() or LP.PlayerGui})
local win = N('Frame',{Size=UDim2.new(0,WW,0,WH+TH+SW),BackgroundColor3=C.BG,BorderSizePixel=0,Position=UDim2.new(0.5,-WW/2,0.5,-(WH+TH+SW)/2),Parent=sg})
rnd(win); strk(win,C.AccD,1)

-- Title bar
local bar = N('Frame',{Size=UDim2.new(1,0,0,TH),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=win})
rnd(bar)
N('TextLabel',{Text='⚡ Delta Hub v12',Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=bar})
local minBtn = N('TextButton',{Text='─',Size=UDim2.new(0,28,0,22),Position=UDim2.new(1,-60,0.5,-11),BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TS,Parent=bar})
rnd(minBtn,UDim.new(0,6))
local body = N('Frame',{Size=UDim2.new(1,0,1,-TH),Position=UDim2.new(0,0,0,TH),BackgroundTransparency=1,Parent=win})
local minimised = false
minBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    tw(body,{Size=minimised and UDim2.new(1,0,0,0) or UDim2.new(1,0,1,-TH)})
    minBtn.Text = minimised and '+' or '─'
end)
do local d,ox,oy=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true; ox=i.Position.X-win.Position.X.Offset; oy=i.Position.Y-win.Position.Y.Offset end end)
    UIS.InputChanged:Connect(function(i) if d and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then win.Position=UDim2.new(0,i.Position.X-ox,0,i.Position.Y-oy) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end end)
end

-- Tab system
local tabRow = N('Frame',{Size=UDim2.new(1,0,0,SW),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=body})
N('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Parent=tabRow})
local content = N('Frame',{Size=UDim2.new(1,0,1,-SW),Position=UDim2.new(0,0,0,SW),BackgroundColor3=C.BG,BorderSizePixel=0,ClipsDescendants=true,Parent=body})
local TABS = {'Dupe','Land','Axe','Player','Wood'}
local tabBtns = {}; local pages = {}
for i,name in ipairs(TABS) do
    local btn = N('TextButton',{Size=UDim2.new(1/#TABS,0,1,0),LayoutOrder=i,BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TS,Text=name,Parent=tabRow})
    tabBtns[name] = btn
    local page = N('ScrollingFrame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=content})
    N('UIListLayout',{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=page})
    pad(page,6,6,6,6)
    pages[name] = page
end
local function switchTab(name)
    for n,p in pairs(pages) do
        p.Visible = n==name
        tw(tabBtns[n],{BackgroundColor3=n==name and C.ElH or C.El,TextColor3=n==name and C.Acc or C.TS},0.1)
    end
end
for name,btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then switchTab(name) end end)
end

-- UI components
local function Section(p,txt)
    local f = N('Frame',{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Parent=p})
    N('TextLabel',{Text=txt:upper(),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    N('Frame',{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=f})
end

local function Hint(p,txt)
    local l = N('TextLabel',{Text=txt,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.El,BackgroundTransparency=0.35,BorderSizePixel=0,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=p})
    rnd(l,UDim.new(0,5)); pad(l,5,5,8,8)
end

local function Label(p,txt,col)
    local l = N('TextLabel',{Text=txt,Size=UDim2.new(1,0,0,BH),BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=col or C.TS,TextXAlignment=Enum.TextXAlignment.Center,Parent=p})
    rnd(l); strk(l,C.AccD,1)
    return l
end

local function Btn(p,txt,col,cb,danger)
    local bg = danger and C.Dng or (col or C.El)
    local tc = danger and Color3.fromRGB(255,200,200) or C.Acc
    local b = N('TextButton',{Size=UDim2.new(1,0,0,BH),BackgroundColor3=bg,BackgroundTransparency=danger and 0.25 or 0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=tc,Text=txt,BorderSizePixel=0,Parent=p})
    rnd(b); strk(b,danger and Color3.fromRGB(130,25,25) or C.AccD,1)
    local function fire()
        tw(b,{BackgroundColor3=C.ElH},0.07)
        task.delay(0.15,function() tw(b,{BackgroundColor3=bg},0.1) end)
        if cb then task.spawn(pcall,cb) end
    end
    b.MouseButton1Click:Connect(fire)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then fire() end end)
    return b
end

local function Tog(p,txt,def,cb)
    local st = def or false
    local row = N('Frame',{Size=UDim2.new(1,0,0,BH),BackgroundColor3=C.El,BorderSizePixel=0,Parent=p})
    rnd(row)
    N('TextLabel',{Text=txt,Size=UDim2.new(1,-52,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=row})
    local tr = N('Frame',{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-44,0.5,-10),BackgroundColor3=st and C.TOn or C.TOff,BorderSizePixel=0,Parent=row})
    rnd(tr,UDim.new(1,0))
    local th = N('Frame',{Size=UDim2.new(0,15,0,15),Position=st and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=C.Th,BorderSizePixel=0,Parent=tr})
    rnd(th,UDim.new(1,0))
    local function set(s)
        st=s; tw(tr,{BackgroundColor3=s and C.TOn or C.TOff})
        tw(th,{Position=s and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        if cb then task.spawn(pcall,cb,s) end
    end
    local hit = N('TextButton',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text='',Parent=row})
    hit.MouseButton1Click:Connect(function() set(not st) end)
    hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then set(not st) end end)
    return {Set=set,Get=function() return st end}
end

local function Slid(p,txt,mn,mx,def,step,cb)
    local val = def
    local row = N('Frame',{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.El,BorderSizePixel=0,Parent=p})
    rnd(row)
    local top = N('Frame',{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,5),BackgroundTransparency=1,Parent=row})
    N('TextLabel',{Text=txt,Size=UDim2.new(0.65,0,1,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,Parent=top})
    local vl = N('TextLabel',{Text=tostring(val),Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Right,Parent=top})
    local bg = N('Frame',{Size=UDim2.new(1,-16,0,5),Position=UDim2.new(0,8,0,34),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=row})
    rnd(bg,UDim.new(1,0))
    local p0 = (val-mn)/(mx-mn)
    local fi = N('Frame',{Size=UDim2.new(p0,0,1,0),BackgroundColor3=C.Acc,BorderSizePixel=0,Parent=bg}); rnd(fi,UDim.new(1,0))
    local kn = N('Frame',{Size=UDim2.new(0,14,0,14),Position=UDim2.new(p0,-7,0.5,-7),BackgroundColor3=C.Th,BorderSizePixel=0,ZIndex=3,Parent=bg})
    rnd(kn,UDim.new(1,0)); strk(kn,C.AccD,1.5)
    local function sv(v)
        v = math.clamp(math.round((v-mn)/step)*step+mn,mn,mx); val=v
        local pp = (v-mn)/(mx-mn)
        tw(fi,{Size=UDim2.new(pp,0,1,0)},0.05); tw(kn,{Position=UDim2.new(pp,-7,0.5,-7)},0.05)
        vl.Text = tostring(v); if cb then task.spawn(pcall,cb,v) end
    end
    local sd = false
    local function drag(pos) local rel=math.clamp((pos.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1); sv(mn+rel*(mx-mn)) end
    bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=true; drag(i.Position) end end)
    UIS.InputChanged:Connect(function(i) if sd and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then drag(i.Position) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=false end end)
end

-- ═══════════════════════════════════════════════════════
--  BUILD DUPE TAB
-- ═══════════════════════════════════════════════════════
local dupeSlot = 1
local autoConfirmLand = false

do
    local Dp = pages['Dupe']

    -- Live slot info
    local slotInfoLbl = Label(Dp,'Loaded Slot: checking...', C.TS)
    task.spawn(function()
        while true do task.wait(2)
            pcall(function()
                local v = CurrentSaveSlot.Value
                if v == -1 then
                    slotInfoLbl.Text = '⚠ No slot loaded — load one in-game!'
                    slotInfoLbl.TextColor3 = Color3.fromRGB(220,60,60)
                else
                    slotInfoLbl.Text = 'Currently loaded: Slot ' .. v .. ' ← set slider to ' .. v
                    slotInfoLbl.TextColor3 = C.Acc
                end
            end)
        end
    end)

    -- Axe count display
    local axeCountLbl = Label(Dp,'Axes: ?', C.Blue)
    task.spawn(function()
        while true do task.wait(1)
            pcall(function()
                axeCountLbl.Text = 'Backpack axes: ' .. #getBackpackAxes() .. '  |  Total (incl. stored): ' .. countAllAxes()
            end)
        end
    end)

    Section(Dp,'Slot Settings')
    Hint(Dp,'Set this to match your loaded slot number shown above.')
    Slid(Dp,'Dupe Slot',1,6,1,1,function(v) dupeSlot = v end)
    Tog(Dp,'Auto-confirm land placement',false,function(v) autoConfirmLand = v end)

    -- ── STEP-BY-STEP DUPE ──────────────────────────────
    Section(Dp,'Step-by-Step Dupe (most reliable)')
    Hint(Dp,'Do steps 1→2→3 in order. After Step 3, confirm land on screen. Then click Step 4.')

    Btn(Dp,'① Save Slot  (saves your axe into the slot)', C.El, function()
        doSave(dupeSlot)
    end)

    Btn(Dp,'② Store Axes  (parks axes safely on Player obj)', C.El, function()
        doStore()
    end)

    Btn(Dp,'③ Load Slot  (resets char → confirm land screen)', C.El, function()
        local prop = autoConfirmLand and getMyProp() or nil
        doLoad(dupeSlot, prop, autoConfirmLand)
    end)

    Btn(Dp,'④ Restore Axes  ← click AFTER land confirmed!', C.ElH, function()
        doRestore()
    end)

    -- ── 1-CLICK DUPE ───────────────────────────────────
    Section(Dp,'1-Click Dupe  (auto steps 1→2→3, you do ③→④)')
    Hint(Dp,'Saves, stores axes, then loads. You confirm land screen, then click Restore above.')

    Btn(Dp,'🪓 1-Click: Save + Store + Load', C.El, function()
        if CurrentSaveSlot.Value == -1 then
            return notify('❌ Load a slot in-game first!')
        end
        if dupeSlot ~= CurrentSaveSlot.Value then
            notify('⚠ Auto-correcting slot to ' .. CurrentSaveSlot.Value)
            dupeSlot = CurrentSaveSlot.Value
            task.wait(0.3)
        end
        local axes = getBackpackAxes()
        if #axes == 0 then
            return notify('❌ No axes in backpack! Put axe in backpack first.')
        end
        -- Step 1: Save
        notify('💾 Step 1/3: Saving...')
        if not doSave(dupeSlot) then return end
        task.wait(0.5)
        -- Step 2: Store
        notify('📦 Step 2/3: Storing axes...')
        local ok, count = doStore()
        if not ok then return end
        task.wait(0.3)
        -- Step 3: Load
        notify('🔄 Step 3/3: Loading... confirm land screen when it appears!')
        local prop = autoConfirmLand and getMyProp() or nil
        if not doLoad(dupeSlot, prop, autoConfirmLand) then
            -- Load failed — restore axes back
            doRestore()
            return
        end
        notify('✅ Steps 1-3 done! Now: confirm land screen → click ④ Restore Axes above.')
    end)

    Section(Dp,'Manual Utilities')
    Btn(Dp,'Drop All Axes', C.El, function()
        local h=hum(); if h then h:UnequipTools() end; task.wait(0.25)
        local axes=getBackpackAxes()
        if #axes==0 then return notify('No axes!') end
        for _,a in ipairs(axes) do
            local r=root(); if r then ClientInteracted:FireServer(a,'Drop tool',r.CFrame) end; task.wait(0.1)
        end
        notify('Dropped '..#axes..' axe(s).')
    end)
    Btn(Dp,'Safe Suicide', nil, safeSuicide, true)
end

-- ── LAND TAB ─────────────────────────────────────────
do
    local La = pages['Land']
    Section(La,'Free Land')
    Hint(La,'Claims nearest unclaimed property.')
    Btn(La,'🏠 Get Free Land', C.El, freeLand)
    Section(La,'Expand')
    Btn(La,'📐 Max Land', C.El, maxLand)
    Btn(La,'⚡ Free Land + Max', C.El, function() freeLand(); task.wait(2); maxLand() end)
end

-- ── AXE TAB ──────────────────────────────────────────
do
    local Ax = pages['Axe']
    Section(Ax,'Modifiers')
    Hint(Ax,'Equip axe first. Values read from AxeSuperClass upvalues.')
    Slid(Ax,'Range',10,400,50,5,function(v) axeMods.rangeVal=v; if axeMods.rangeOn then pcall(applyAxeMod) end end)
    Tog(Ax,'Axe Range Mod',false,function(v) axeMods.rangeOn=v; pcall(applyAxeMod) end)
    Tog(Ax,'No Swing Cooldown',false,function(v) axeMods.noCdOn=v; pcall(applyAxeMod) end)
end

-- ── PLAYER TAB ───────────────────────────────────────
do
    local Pl = pages['Player']
    Section(Pl,'Movement')
    Slid(Pl,'Walk Speed',16,100,16,1,function(v) local h=hum(); if h then h.WalkSpeed=v end end)
    Slid(Pl,'Jump Power',50,250,50,5,function(v) local h=hum(); if h then h.JumpPower=v end end)
    Tog(Pl,'Noclip',false,function(v) setNoclip(v) end)
    Section(Pl,'Utility')
    Tog(Pl,'Anti-AFK',true,function(v) pcall(setAntiAFK,v) end)
    Btn(Pl,'Safe Suicide', nil, safeSuicide, true)
end

-- ── WOOD TAB ─────────────────────────────────────────
do
    local Wd = pages['Wood']
    Section(Wd,'Logs')
    Hint(Wd,'TPs owned logs to the sawmill drop-off point.')
    Btn(Wd,'💰 Sell All Logs', C.El, sellAllLogs)
    Section(Wd,'Auto Chop')
    Hint(Wd,'Equip axe and stand near a tree.')
    Tog(Wd,'Auto Chop',false,function(v)
        if v then startAutoChop() else autoChop=false end
    end)
end

switchTab('Dupe')
print('[Delta Hub v12] Loaded — rebuilt from confirmed working dupe logic')
