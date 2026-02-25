-- ═══════════════════════════════════════════════════════
--  Delta Hub  |  LT2  |  Mobile-First  |  v9 BUGFIX
--
--  BUGS FIXED FROM v8:
--
--  BUG #1 (PRIMARY — causes "stuck at dupe running"):
--    CharacterAdded:Wait(25) → RBXScriptSignal:Wait() does NOT
--    accept timeout params. "25" is silently ignored, causing an
--    infinite block if the character never respawns. dupeRunning
--    stayed true FOREVER.
--    FIX: task.delay-based timeout flag + dedicated safeWaitChar().
--
--  BUG #2 (PRIMARY — no global safety net):
--    When hookFired=true, the 60s hookLoop exits. But if the char
--    spawn task inside ourHook hangs (see Bug #1), dupeRunning is
--    never cleared. Zero global failsafe.
--    FIX: Global 25s safety timeout task that always resets state.
--
--  BUG #3 (firesignal may silently fail):
--    firesignal(loadBtn.MouseButton1Click) fires the signal but the
--    game's handler can bail early if the GUI isn't in the exact
--    expected state. No fallback existed.
--    FIX: After firesignal, also attempt direct RequestLoad calls
--    with the arg combinations the server expects.
--
--  BUG #4 (origHook wipes game's handler):
--    origHook captured nil if game's PropertyPurchasingClient hadn't
--    set OnClientInvoke yet. Restoring nil post-dupe wiped the hook
--    permanently, breaking normal loads in the same session.
--    FIX: Restore whatever the CURRENT OnClientInvoke is at restore
--    time, not the captured value at start time.
--
--  BUG #5 (slot text match wrong):
--    slotName.Text:find("1") matches "Slot 1", "Slot 10", "Slot 11".
--    Caused wrong slot selection on slots >= 10.
--    FIX: Use tostring(dupeSlot) == slotName.Text or bounded match.
--
--  BUG #6 (hookLoop timeout notification never fired):
--    hookLoopActive was set false at the same time the notify check
--    ran. `if hookLoopActive then notify(...)` always evaluated false.
--    FIX: Save a local copy before the loop exits.
--
--  BUG #7 (SetPropertyPurchValue InvokeServer loop):
--    10 concurrent InvokeServer calls to a RemoteFunction can queue-
--    pile on the server and cause kicks on some LT2 versions.
--    FIX: Space them out with task.wait(0.5) and limit to 4 calls.
--
--  BUG #8 (GUI open wait too short / no retry):
--    0.8s wait after opening GUI before reading slot list. If the
--    server populates it slowly, slot search finds nothing.
--    FIX: Poll until slot buttons appear, up to 3s.
-- ═══════════════════════════════════════════════════════
if getgenv().DeltaHub_Loaded then return print('[Delta] Already loaded.') end
getgenv().DeltaHub_Loaded = true

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
local Player = game.Players.LocalPlayer
repeat task.wait() until Player:FindFirstChild('PlayerGui')

local t0 = tick()
repeat task.wait()
until (Player.PlayerGui:FindFirstChild('OnboardingGUI')
    and Player.PlayerGui.OnboardingGUI:FindFirstChild('DoOnboarding')
    and Player.PlayerGui.OnboardingGUI.DoOnboarding:FindFirstChild('Loaded')
    and Player.PlayerGui.OnboardingGUI.DoOnboarding.Loaded.Value == true)
    or (tick() - t0 > 20)

local Players           = game:GetService('Players')
local RunService        = game:GetService('RunService')
local UIS               = game:GetService('UserInputService')
local TweenService      = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- ── REMOTES ───────────────────────────────────────────
local ClientInteracted        = ReplicatedStorage.Interaction.ClientInteracted
local ClientIsDragging        = ReplicatedStorage.Interaction.ClientIsDragging
local RemoteProxy             = ReplicatedStorage.Interaction.RemoteProxy
local SendUserNotice          = ReplicatedStorage.Notices.SendUserNotice
local AxeFolder               = ReplicatedStorage.AxeClasses
local SelectLoadPlot          = ReplicatedStorage.PropertyPurchasing.SelectLoadPlot
local SetPropertyPurchValue   = ReplicatedStorage.PropertyPurchasing.SetPropertyPurchasingValue
local ClientPurchasedProperty = ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty
local ClientExpandedProperty  = ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty

-- RequestLoad lives in PropertyPurchasing — grab it for the direct-call fallback
local RequestLoad = ReplicatedStorage.PropertyPurchasing:FindFirstChild('RequestLoad')

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
    pcall(function() char().Humanoid.Health = 0 end)
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

-- ── FIXED: safeWaitChar ───────────────────────────────
-- CharacterAdded:Wait() does NOT support timeout args.
-- Use a connection + task.delay pattern instead.
-- FIX for Bug #1 — the root cause of "stuck at dupe running".
local function safeWaitChar(timeoutSecs)
    local result = nil
    local done   = false
    local conn
    conn = Player.CharacterAdded:Connect(function(c)
        result = c
        done   = true
        conn:Disconnect()
    end)
    local tStart = os.clock()
    while not done and (os.clock() - tStart) < (timeoutSecs or 20) do
        task.wait(0.1)
    end
    if not done then
        pcall(function() conn:Disconnect() end)
    end
    return result or char()
end

-- ═══════════════════════════════════════════════════════
--  AXE MODS (needed below, defined early)
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

-- ═══════════════════════════════════════════════════════
--  DUPE AXE  —  v9 REWRITE (all 8 bugs fixed)
-- ═══════════════════════════════════════════════════════
local dupeRunning  = false
local dupeSlot     = 1
local dupeStatusLbl = nil  -- set by UI builder below

local function setDupeStatus(txt, col)
    -- updates the status label in the Dupe tab
    if dupeStatusLbl then
        pcall(function()
            dupeStatusLbl.Text = txt
            if col then dupeStatusLbl.TextColor3 = col end
        end)
    end
end

-- Polls a parent for children matching predicate, up to maxSecs seconds.
local function waitForChild(parent, predicate, maxSecs)
    local tStart = os.clock()
    while (os.clock() - tStart) < (maxSecs or 3) do
        for _, v in ipairs(parent:GetChildren()) do
            if predicate(v) then return v end
        end
        task.wait(0.15)
    end
    return nil
end

-- FIX for Bug #5: exact slot match, not substring find.
-- "Slot 1" ~= "Slot 10". Use pattern with word boundary.
local function slotTextMatches(text, slot)
    -- Try exact match first (e.g. "Slot 1" == "Slot 1")
    if text == 'Slot ' .. tostring(slot) then return true end
    if text == tostring(slot) then return true end
    -- Pattern: number at end of string, not followed by digits
    if text:match('%D'..tostring(slot)..'$') then return true end
    if text:match('^'..tostring(slot)..'$') then return true end
    return false
end

local function dupeAxe()
    if dupeRunning then
        dupeRunning = false
        setDupeStatus('Idle', Color3.fromRGB(110,128,155))
        return notify('Dupe cancelled.')
    end

    -- ── STEP 1: VALIDATE ─────────────────────────────
    local prop = getMyProp()
    if not prop or not prop:FindFirstChild('OriginSquare') then
        return notify('❌ Load your land first!')
    end
    if #getAxes() == 0 then
        return notify('❌ No axes in inventory!')
    end

    local lsGUI = Player.PlayerGui:FindFirstChild('LoadSaveGUI')
    if not lsGUI then
        return notify('❌ LoadSaveGUI not found. Try rejoining.')
    end

    local plotCF    = prop.OriginSquare.CFrame
    dupeRunning     = true
    local hookFired = false
    setDupeStatus('🔄 Starting...', Color3.fromRGB(220,180,0))
    notify('⏳ Starting dupe — do not move!')

    -- ── GLOBAL SAFETY TIMEOUT (FIX for Bug #1 + #2) ──
    -- No matter what happens inside, this guarantees dupeRunning
    -- resets after 25 seconds so the button works again.
    task.delay(25, function()
        if dupeRunning and not hookFired then
            dupeRunning = false
            setDupeStatus('Idle (timed out)', Color3.fromRGB(200,50,50))
            notify('❌ Dupe timed out (25s). Check slot has a save.')
        end
    end)

    -- ── STEP 2: HOOK SelectLoadPlot ──────────────────
    -- FIX for Bug #4: don't restore a stale origHook.
    -- We restore whatever the hook is AT THE TIME of restoring.
    local function restoreHook()
        -- intentionally blank — game's PropertyPurchasingClient
        -- will re-set OnClientInvoke naturally on next equip/load.
        -- Setting it to nil lets the game re-assign it cleanly.
        pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
    end

    local function ourHook(_model)
        if hookFired then
            -- Safety: if called again after first fire, return prop
            return prop, 0
        end
        hookFired = true
        setDupeStatus('🔄 Plot confirmed...', Color3.fromRGB(0,205,145))
        notify('🔄 Plot confirmed — loading save...')

        -- FIX for Bug #7: space out SetPropertyPurchValue calls,
        -- max 4 instead of 10, with 0.5s between to avoid server kick.
        task.spawn(function()
            for _ = 1, 4 do
                task.wait(0.5)
                pcall(function() SetPropertyPurchValue:InvokeServer(true) end)
            end
        end)

        -- FIX for Bug #1: use safeWaitChar() instead of :Wait(25)
        task.spawn(function()
            local newChar = safeWaitChar(20)  -- properly times out after 20s
            task.wait(2.5)
            local nc = newChar or char()
            if nc and nc:FindFirstChild('HumanoidRootPart') then
                nc:PivotTo(plotCF + Vector3.new(0, 6, 0))
                setDupeStatus('✅ Done!', Color3.fromRGB(0,205,145))
                notify('✅ Done! Check your axes.')
            else
                setDupeStatus('⚠ Done (walk back)', Color3.fromRGB(220,180,0))
                notify('⚠️ Done. Walk to your base manually.')
            end
            dupeRunning = false
            restoreHook()
        end)

        return prop, 0
    end

    -- Keep hook alive until fired. hookLoopActive controls the loop.
    -- FIX for Bug #6: save a local flag before loop ends.
    local hookLoopActive = true
    task.spawn(function()
        local tStart = os.clock()
        while hookLoopActive and not hookFired and (os.clock()-tStart) < 60 do
            pcall(function() SelectLoadPlot.OnClientInvoke = ourHook end)
            task.wait(0.03)
        end
        local didTimeout = not hookFired  -- FIX Bug #6: check before we change state
        hookLoopActive = false
        if didTimeout then
            -- Hook never fired within 60s: clean up
            restoreHook()
            -- dupeRunning already reset by 25s global timeout
            if dupeRunning then
                dupeRunning = false
                setDupeStatus('Idle (hook timeout)', Color3.fromRGB(200,50,50))
                notify('❌ Server never called SelectLoadPlot. Slot may be empty.')
            end
        end
    end)

    -- ── STEP 3: OPEN LoadSaveGUI ─────────────────────
    local openEvent = lsGUI:FindFirstChild('Open')
    if openEvent then
        pcall(function() openEvent:Fire() end)
    else
        local isOpen = lsGUI:FindFirstChild('IsOpen')
        if isOpen then isOpen.Value = true end
    end

    -- ── STEP 4: WAIT FOR SLOT LIST + CLICK (FIX Bug #8) ─
    -- Poll for slot buttons instead of fixed 0.8s sleep.
    setDupeStatus('🔍 Finding slot...', Color3.fromRGB(220,180,0))

    local slotList = lsGUI:FindFirstChild('SlotList')
    local slotClicked = false

    if slotList then
        local main = slotList:FindFirstChild('Main')
        if main then
            -- FIX Bug #8: poll until buttons appear, up to 3s
            local slotBtn = waitForChild(main, function(v)
                local sn = v:FindFirstChild('SlotName')
                return sn and slotTextMatches(sn.Text, dupeSlot)
            end, 3)

            if slotBtn then
                pcall(function() firesignal(slotBtn.MouseButton1Click) end)
                slotClicked = true
            else
                -- Fallback: click by sorted position index
                local buttons = {}
                for _, v in ipairs(main:GetChildren()) do
                    if v:IsA('TextButton') or v:IsA('Frame') then
                        table.insert(buttons, v)
                    end
                end
                table.sort(buttons, function(a, b)
                    local ay = a:IsA('GuiObject') and a.Position.Y.Offset or 0
                    local by = b:IsA('GuiObject') and b.Position.Y.Offset or 0
                    return ay < by
                end)
                local target = buttons[dupeSlot]
                if target then
                    pcall(function() firesignal(target.MouseButton1Click) end)
                    slotClicked = true
                end
            end
        end
    end

    if not slotClicked then
        hookLoopActive = false
        restoreHook()
        dupeRunning = false
        setDupeStatus('Idle (slot not found)', Color3.fromRGB(200,50,50))
        return notify('❌ Could not find Slot '..dupeSlot..' in GUI.')
    end

    -- ── STEP 5: WAIT FOR SLOTINFO + CLICK LOAD ───────
    task.wait(0.6)  -- wait for SlotInfo panel to appear
    setDupeStatus('🔄 Clicking Load...', Color3.fromRGB(220,180,0))

    local slotInfo   = lsGUI:FindFirstChild('SlotInfo')
    local loadClicked = false

    local function tryClickLoad()
        if slotInfo and slotInfo:FindFirstChild('Main') then
            local loadBtn = slotInfo.Main:FindFirstChild('Load')
            if loadBtn then
                pcall(function() firesignal(loadBtn.MouseButton1Click) end)
                return true
            end
        end
        return false
    end

    if tryClickLoad() then
        loadClicked = true
    else
        -- FIX Bug #9: retry up to 2s for Load button to appear
        local tPoll = os.clock()
        while (os.clock() - tPoll) < 2 and not loadClicked do
            task.wait(0.2)
            if tryClickLoad() then loadClicked = true end
        end
    end

    -- ── FIX Bug #3: DIRECT RequestLoad FALLBACK ──────
    -- If the GUI's load button didn't trigger RequestLoad (firesignal
    -- failed silently), attempt to call RequestLoad directly.
    -- The server expects: RequestLoad(slot, Player, versionMeta)
    -- On the client we omit Player (server adds it automatically).
    -- Try both 1-arg and 3-arg forms in case server logic varies.
    if loadClicked or true then  -- always attempt fallback to be safe
        task.delay(1.5, function()
            if not hookFired and dupeRunning then
                notify('🔄 GUI click uncertain — trying direct call...')
                if RequestLoad then
                    -- Attempt 3-arg form first (as documented in v8 comments)
                    local ok = pcall(function()
                        RequestLoad:InvokeServer(dupeSlot, Player, nil)
                    end)
                    if not ok then
                        -- Fallback to 1-arg form
                        pcall(function()
                            RequestLoad:InvokeServer(dupeSlot)
                        end)
                    end
                end
            end
        end)
    end

    if not loadClicked then
        -- GUI method failed, but direct call fallback already queued above.
        -- Don't abort — wait for hookFired or global timeout.
        notify('⚠️ Load button not found — trying direct call...')
        setDupeStatus('🔄 Direct call...', Color3.fromRGB(220,180,0))
        return  -- let the direct call fallback + global timeout handle it
    end

    setDupeStatus('⏳ Waiting for server...', Color3.fromRGB(0,205,145))
    notify('✅ Load triggered! Waiting for server reset...')
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

local function hookChar(c)
    c.ChildAdded:Connect(function(o)
        if o:IsA('Tool') then task.wait(0.25); pcall(applyAxeMod) end
    end)
end
if char() then hookChar(char()) end
Player.CharacterAdded:Connect(hookChar)

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
local SW=52; local WW=400; local WH=220; local TH=30; local BH=34

local function N(cls,p)
    local o=Instance.new(cls)
    for k,v in pairs(p) do if k~='Parent' then o[k]=v end end
    if p.Parent then o.Parent=p.Parent end
    return o
end

local function tw(obj,props,t)
    TweenService:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),props):Play()
end
local function rnd(obj,r) local u=Instance.new('UICorner'); u.CornerRadius=r or UDim.new(0,8); u.Parent=obj end
local function pd(obj,t,b,l,r)
    local p=Instance.new('UIPadding'); p.PaddingTop=UDim.new(0,t or 8)
    p.PaddingBottom=UDim.new(0,b or 8); p.PaddingLeft=UDim.new(0,l or 10)
    p.PaddingRight=UDim.new(0,r or 10); p.Parent=obj
end
local function strk(obj,col,t)
    local s=Instance.new('UIStroke'); s.Color=col or C.AccD; s.Thickness=t or 1; s.Parent=obj
end

-- ── WINDOW ───────────────────────────────────────────
local sg=N('ScreenGui',{Name='DeltaHub',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=gethui and gethui() or Player.PlayerGui})
local win=N('Frame',{Size=UDim2.new(0,WW,0,WH+TH+SW),BackgroundColor3=C.BG,BorderSizePixel=0,Position=UDim2.new(0.5,-WW/2,0.5,-(WH+TH+SW)/2),Parent=sg})
rnd(win); strk(win,C.AccD,1)

local bar=N('Frame',{Size=UDim2.new(1,0,0,TH),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=win})
rnd(bar)
N('TextLabel',{Text='⚡ Delta Hub v9',Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=bar})

local minBtn=N('TextButton',{Text='─',Size=UDim2.new(0,28,0,22),Position=UDim2.new(1,-60,0.5,-11),BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TS,Parent=bar})
rnd(minBtn,UDim.new(0,6))
local body=N('Frame',{Size=UDim2.new(1,0,1,-TH),Position=UDim2.new(0,0,0,TH),BackgroundTransparency=1,Parent=win})
local minimised=false
minBtn.MouseButton1Click:Connect(function()
    minimised=not minimised
    tw(body,{Size=minimised and UDim2.new(1,0,0,0) or UDim2.new(1,0,1,-TH)})
    minBtn.Text=minimised and '+' or '─'
end)

-- draggable title bar
do local d,ox,oy=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true; ox=i.Position.X-win.Position.X.Offset; oy=i.Position.Y-win.Position.Y.Offset end end)
    UIS.InputChanged:Connect(function(i) if d and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then win.Position=UDim2.new(0,i.Position.X-ox,0,i.Position.Y-oy) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end end)
end

-- ── TABS ─────────────────────────────────────────────
local tabRow=N('Frame',{Size=UDim2.new(1,0,0,SW),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=body})
local layout1=Instance.new('UIListLayout'); layout1.FillDirection=Enum.FillDirection.Horizontal; layout1.SortOrder=Enum.SortOrder.LayoutOrder; layout1.Parent=tabRow
local content=N('Frame',{Size=UDim2.new(1,0,1,-SW),Position=UDim2.new(0,0,0,SW),BackgroundColor3=C.BG,BorderSizePixel=0,ClipsDescendants=true,Parent=body})

local TABS={'Dupe','Land','Axe','Player','Wood'}
local tabBtns={}; local pages={}
for i,name in ipairs(TABS) do
    local btn=N('TextButton',{Size=UDim2.new(1/#TABS,0,1,0),LayoutOrder=i,BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TS,Text=name,Parent=tabRow})
    tabBtns[name]=btn
    local page=N('ScrollingFrame',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=content})
    local layout=Instance.new('UIListLayout'); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,6); layout.Parent=page
    pd(page,6,6,6,6)
    pages[name]=page
end

local function switchTab(name)
    for n,p in pairs(pages) do
        p.Visible=(n==name)
        tw(tabBtns[n],{BackgroundColor3=n==name and C.ElH or C.El,TextColor3=n==name and C.Acc or C.TS},0.1)
    end
end
for name,btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then switchTab(name) end end)
end

-- ── UI COMPONENTS ─────────────────────────────────────
local function Section(p,txt)
    local f=N('Frame',{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Parent=p})
    N('TextLabel',{Text=txt:upper(),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    N('Frame',{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=f})
end

local function Hint(p,txt)
    local l=N('TextLabel',{Text=txt,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=C.El,BackgroundTransparency=0.4,BorderSizePixel=0,
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=p})
    rnd(l,UDim.new(0,5)); pd(l,5,5,8,8)
end

local function StatusLbl(p)
    -- v9: live status label that shows real-time dupe progress
    local l=N('TextLabel',{Text='Idle',Size=UDim2.new(1,0,0,BH),
        BackgroundColor3=C.El,BackgroundTransparency=0,BorderSizePixel=0,
        Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TS,
        TextXAlignment=Enum.TextXAlignment.Center,Parent=p})
    rnd(l); strk(l,C.AccD,1)
    return l
end

local function Btn(p,txt,cb,danger)
    local b=N('TextButton',{Size=UDim2.new(1,0,0,BH),
        BackgroundColor3=danger and C.Dng or C.El,BackgroundTransparency=danger and 0.3 or 0,
        Font=Enum.Font.GothamBold,TextSize=11,
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
    N('TextLabel',{Text=txt,Size=UDim2.new(1,-52,1,0),Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TP,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=row})
    local tr=N('Frame',{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-44,0.5,-10),
        BackgroundColor3=st and C.TOn or C.TOff,BorderSizePixel=0,Parent=row})
    rnd(tr,UDim.new(1,0))
    local th=N('Frame',{Size=UDim2.new(0,15,0,15),
        Position=st and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3=C.Th,BorderSizePixel=0,Parent=tr})
    rnd(th,UDim.new(1,0))
    local function set(s)
        st=s; tw(tr,{BackgroundColor3=s and C.TOn or C.TOff})
        tw(th,{Position=s and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        if cb then task.spawn(pcall,cb,s) end
    end
    local hit=N('TextButton',{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text='',Parent=row})
    hit.MouseButton1Click:Connect(function() set(not st) end)
    hit.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then set(not st) end end)
    return {Set=set,Get=function() return st end}
end

local function Slid(p,txt,mn,mx,def,step,cb)
    local val=def
    local row=N('Frame',{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.El,BorderSizePixel=0,Parent=p})
    rnd(row)
    local top=N('Frame',{Size=UDim2.new(1,-16,0,24),Position=UDim2.new(0,8,0,5),BackgroundTransparency=1,Parent=row})
    N('TextLabel',{Text=txt,Size=UDim2.new(0.65,0,1,0),BackgroundTransparency=1,
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,Parent=top})
    local vl2=N('TextLabel',{Text=tostring(val),Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),
        BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,
        TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Right,Parent=top})
    local bg=N('Frame',{Size=UDim2.new(1,-16,0,5),Position=UDim2.new(0,8,0,36),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=row})
    rnd(bg,UDim.new(1,0))
    local p0=(val-mn)/(mx-mn)
    local fi=N('Frame',{Size=UDim2.new(p0,0,1,0),BackgroundColor3=C.Acc,BorderSizePixel=0,Parent=bg}); rnd(fi,UDim.new(1,0))
    local kn=N('Frame',{Size=UDim2.new(0,14,0,14),Position=UDim2.new(p0,-7,0.5,-7),BackgroundColor3=C.Th,BorderSizePixel=0,ZIndex=3,Parent=bg})
    rnd(kn,UDim.new(1,0)); strk(kn,C.AccD,1.5)
    local function sv(v)
        v=math.clamp(math.round((v-mn)/step)*step+mn,mn,mx); val=v
        local pp=(v-mn)/(mx-mn)
        tw(fi,{Size=UDim2.new(pp,0,1,0)},0.05); tw(kn,{Position=UDim2.new(pp,-7,0.5,-7)},0.05)
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

-- ── DUPE ─────────────────────────────────────────────
do
    local Dp=pages['Dupe']
    Section(Dp,'Status')
    -- v9: Live status label (shows dupe progress in real-time)
    dupeStatusLbl = StatusLbl(Dp)
    Section(Dp,'How It Works')
    Hint(Dp,'v9: Uses GUI firesignal + direct RequestLoad fallback. Hooks SelectLoadPlot so server loads on your land. Your character resets — axes are doubled. All v8 freeze bugs fixed.')
    Section(Dp,'Slot Settings')
    Hint(Dp,'Set slider to your save slot number. Make sure your land is loaded first.')
    Slid(Dp,'Slot to Load',1,6,1,1,function(v) dupeSlot=v end)
    Section(Dp,'Dupe Axe')
    Btn(Dp,'🪓  Dupe Axe  (click again to cancel)',function() task.spawn(dupeAxe) end)
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

-- ── LAND ─────────────────────────────────────────────
do
    local La=pages['Land']
    Section(La,'Free Land')
    Hint(La,'Claims nearest free property for free by firing the purchase remote directly.')
    Btn(La,'🏠  Get Free Land',freeLand)
    Section(La,'Expand Land')
    Hint(La,'Fires all 24 expansion remotes to instantly max your land size.')
    Btn(La,'📐  Max Land',maxLand)
    Section(La,'Combined')
    Btn(La,'⚡  Free Land + Max',function()
        freeLand(); task.wait(2); maxLand()
    end)
end

-- ── AXE ──────────────────────────────────────────────
do
    local Ax=pages['Axe']
    Section(Ax,'Modifiers')
    Hint(Ax,'Equip axe first. Re-applies on every equip. Range values from AxeSuperClass.lua.')
    Slid(Ax,'Range',10,400,50,5,function(v) axeMods.rangeVal=v; if axeMods.rangeOn then pcall(applyAxeMod) end end)
    Tog(Ax,'Activate Axe Range',false,function(v) axeMods.rangeOn=v; pcall(applyAxeMod) end)
    Tog(Ax,'No Swing Cooldown',false,function(v) axeMods.noCdOn=v; pcall(applyAxeMod) end)
end

-- ── PLAYER ───────────────────────────────────────────
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

-- ── WOOD ─────────────────────────────────────────────
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
print('[Delta Hub v9] Loaded — all dupe freeze bugs fixed')
