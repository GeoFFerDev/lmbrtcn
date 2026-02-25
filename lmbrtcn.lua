-- ═══════════════════════════════════════════════════════
--  Delta Hub  |  LT2  |  Mobile-First  |  v10
--
--  ROOT CAUSE FIX (why v7, v8, v9 ALL failed):
--
--  WRONG REMOTE PATH (v7/v8/v9):
--    ReplicatedStorage.PropertyPurchasing.RequestLoad   ← DOES NOT EXIST
--    ReplicatedStorage.PropertyPurchasing.RequestSave   ← DOES NOT EXIST
--
--  CORRECT PATHS (v10):
--    ReplicatedStorage.LoadSaveRequests.RequestSave:InvokeServer(slot)
--    ReplicatedStorage.LoadSaveRequests.RequestLoad:InvokeServer(slot)
--    ReplicatedStorage.LoadSaveRequests.GetMetaData:InvokeServer(player)
--    ReplicatedStorage.PropertyPurchasing.SelectLoadPlot  ← still correct
--
--  MISSING STEP (v7/v8/v9): Never called RequestSave before RequestLoad.
--  Without saving first, the slot has no axe data → nothing to double.
--
--  CORRECT DUPE FLOW (v10):
--    1. Validate: land loaded, axe in backpack, slot matches CurrentSaveSlot
--    2. Unequip axe into backpack (so it survives the death clean)
--    3. Hook SelectLoadPlot.OnClientInvoke (auto-confirm land placement)
--    4. RequestSave:InvokeServer(slot) → saves current state WITH the axe
--    5. RequestLoad:InvokeServer(slot) → server TPs char out of map + kills it
--    6. Char dies → axes stay in Backpack (server void-kills, no drop)
--    7. Char respawns at spawn → axe still in Backpack
--    8. Server calls SelectLoadPlot → our hook returns property → land loads
--    9. Load restores axes from save → NOW DOUBLED
--   10. TP back to base
--
--  Player values used (confirmed from game):
--    Player.CurrentSaveSlot     (IntValue, -1 = no slot loaded)
--    Player.CurrentlySavingOrLoading  (BoolValue)
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

-- ── REMOTES (CORRECTED) ────────────────────────────────
-- ✅ CORRECT: LoadSaveRequests folder (NOT PropertyPurchasing)
local LoadSaveRequests  = ReplicatedStorage:WaitForChild('LoadSaveRequests')
local RequestSave       = LoadSaveRequests:WaitForChild('RequestSave')   -- InvokeServer(slot) → true/false
local RequestLoad       = LoadSaveRequests:WaitForChild('RequestLoad')   -- InvokeServer(slot) → true/false
local GetMetaData       = LoadSaveRequests:WaitForChild('GetMetaData')   -- InvokeServer(player) → table

-- ✅ CORRECT: SelectLoadPlot is in PropertyPurchasing
local PropPurch             = ReplicatedStorage:WaitForChild('PropertyPurchasing')
local SelectLoadPlot        = PropPurch:WaitForChild('SelectLoadPlot')
local SetPropertyPurchValue = PropPurch:FindFirstChild('SetPropertyPurchasingValue')
local ClientPurchasedProperty = PropPurch:FindFirstChild('ClientPurchasedProperty')
local ClientExpandedProperty  = PropPurch:FindFirstChild('ClientExpandedProperty')

local ClientInteracted  = ReplicatedStorage.Interaction.ClientInteracted
local ClientIsDragging  = ReplicatedStorage.Interaction.ClientIsDragging
local RemoteProxy       = ReplicatedStorage.Interaction.RemoteProxy
local SendUserNotice    = ReplicatedStorage.Notices.SendUserNotice
local AxeFolder         = ReplicatedStorage.AxeClasses

-- ── PLAYER SAVE VALUES ─────────────────────────────────
-- CurrentSaveSlot: which slot is currently loaded (-1 = none)
-- CurrentlySavingOrLoading: true while server is processing save/load
local CurrentSaveSlot           = Player:WaitForChild('CurrentSaveSlot')
local CurrentlySavingOrLoading  = Player:WaitForChild('CurrentlySavingOrLoading')

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

-- Proper CharacterAdded wait with real timeout (seconds)
local function safeWaitChar(timeoutSecs)
    local result = nil
    local done   = false
    local conn
    conn = Player.CharacterAdded:Connect(function(c)
        result = c; done = true; conn:Disconnect()
    end)
    local tStart = os.clock()
    while not done and (os.clock()-tStart) < (timeoutSecs or 20) do
        task.wait(0.1)
    end
    if not done then pcall(function() conn:Disconnect() end) end
    return result or char()
end

-- Check if a save slot has data (NumSaves > 0)
local function slotHasData(slot)
    local ok, meta = pcall(function()
        return GetMetaData:InvokeServer(Player)
    end)
    if not ok or not meta then return false end
    for a, b in pairs(meta) do
        if a == slot then
            for c, d in pairs(b) do
                if c == 'NumSaves' then return d ~= 0 end
            end
        end
    end
    return false
end

-- Wait until CurrentlySavingOrLoading goes false (with timeout)
local function waitForSaveLoad(maxSecs)
    local tStart = os.clock()
    while CurrentlySavingOrLoading.Value == true and (os.clock()-tStart) < (maxSecs or 10) do
        task.wait(0.2)
    end
end

-- ═══════════════════════════════════════════════════════
--  AXE MODS
-- ═══════════════════════════════════════════════════════
local axeMods = {rangeOn=false, rangeVal=50, noCdOn=false}

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
--  DUPE AXE  —  v10  (correct mechanics, correct remotes)
-- ═══════════════════════════════════════════════════════
local dupeRunning   = false
local dupeSlot      = 1
local dupeStatusLbl = nil  -- assigned by UI builder below

local function setStatus(txt, col)
    if dupeStatusLbl then
        pcall(function()
            dupeStatusLbl.Text = txt
            if col then dupeStatusLbl.TextColor3 = col end
        end)
    end
end

local YELLOW = Color3.fromRGB(220,180,0)
local GREEN  = Color3.fromRGB(0,205,145)
local RED    = Color3.fromRGB(200,60,60)
local GREY   = Color3.fromRGB(110,128,155)

local function dupeAxe()
    if dupeRunning then
        dupeRunning = false
        setStatus('Idle (cancelled)', GREY)
        return notify('Dupe cancelled.')
    end

    -- ── STEP 1: VALIDATE ─────────────────────────────
    local axes = getAxes()
    if #axes == 0 then
        return notify('❌ No axes in inventory!')
    end

    local prop = getMyProp()
    if not prop or not prop:FindFirstChild('OriginSquare') then
        return notify('❌ Load your land first!')
    end

    -- Must have a slot loaded (CurrentSaveSlot != -1)
    if CurrentSaveSlot.Value == -1 then
        return notify('❌ No save slot loaded! Load a slot in-game first, then dupe.')
    end

    -- Warn if dupe slot doesn't match loaded slot
    if CurrentSaveSlot.Value ~= dupeSlot then
        notify('⚠️ Dupe slot (' .. dupeSlot .. ') ≠ loaded slot (' .. CurrentSaveSlot.Value .. '). Set slider to ' .. CurrentSaveSlot.Value .. '!')
        task.wait(2)
        -- Auto-correct to current loaded slot
        dupeSlot = CurrentSaveSlot.Value
        notify('✅ Auto-corrected to slot ' .. dupeSlot)
        task.wait(0.5)
    end

    -- Don't start if server is already saving/loading
    if CurrentlySavingOrLoading.Value == true then
        return notify('❌ Server is busy saving/loading. Wait a moment.')
    end

    local plotCF   = prop.OriginSquare.CFrame
    local hookFired = false
    dupeRunning     = true
    setStatus('🔄 Starting...', YELLOW)
    notify('⏳ Dupe starting — do not move!')

    -- ── GLOBAL SAFETY TIMEOUT ────────────────────────
    task.delay(40, function()
        if dupeRunning then
            dupeRunning = false
            SelectLoadPlot.OnClientInvoke = nil
            setStatus('Idle (timed out)', RED)
            notify('❌ Dupe timed out after 40s.')
        end
    end)

    -- ── STEP 2: UNEQUIP AXE TO BACKPACK ──────────────
    -- Server void-kills char during load. Tool in Backpack survives.
    -- Equipped tool might not survive depending on server config.
    local h = hum()
    if h then h:UnequipTools() end
    task.wait(0.3)
    setStatus('🔄 Axes unequipped', YELLOW)

    -- ── STEP 3: HOOK SelectLoadPlot ──────────────────
    -- Server calls this after char respawns to ask where to place land.
    -- We return the player's property so land loads automatically.
    local hookLoop = true
    task.spawn(function()
        local tStart = os.clock()
        while hookLoop and not hookFired and (os.clock()-tStart) < 60 do
            pcall(function() SelectLoadPlot.OnClientInvoke = function(_model)
                if hookFired then return prop, 0 end
                hookFired = true
                hookLoop  = false
                setStatus('🏠 Confirming land...', GREEN)
                notify('🔄 Land placement confirmed!')

                -- Keep asserting property purchasing active
                -- (Humanoid.Died in PropertyPurchasingClient fires exitAll → SetPropertyPurchasingValue(false))
                if SetPropertyPurchValue then
                    task.spawn(function()
                        for _ = 1, 6 do
                            task.wait(0.5)
                            pcall(function() SetPropertyPurchValue:InvokeServer(true) end)
                        end
                    end)
                end

                -- Wait for respawn + TP to base
                task.spawn(function()
                    local newChar = safeWaitChar(20)
                    task.wait(3)  -- let the load fully complete
                    local nc = newChar or char()
                    if nc and nc:FindFirstChild('HumanoidRootPart') then
                        nc:PivotTo(plotCF + Vector3.new(0, 6, 0))
                        local axeCount = #getAxes()
                        setStatus('✅ Done! Axes: ' .. axeCount, GREEN)
                        notify('✅ Dupe complete! You have ' .. axeCount .. ' axe(s).')
                    else
                        setStatus('✅ Done! Walk to base.', GREEN)
                        notify('✅ Dupe done — walk to your base.')
                    end
                    dupeRunning = false
                end)

                return prop, 0
            end end)
            task.wait(0.03)
        end
        -- Hook loop ended without firing
        if not hookFired then
            hookLoop = false
            pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
            if dupeRunning then
                dupeRunning = false
                setStatus('Idle (no response)', RED)
                notify('❌ Server never sent SelectLoadPlot. Slot may be empty or cooldown active.')
            end
        end
    end)

    task.wait(0.1)  -- let hook install

    -- ── STEP 4: SAVE SLOT ─────────────────────────────
    -- THIS IS THE CRITICAL STEP that v7/v8/v9 all missed.
    -- Saves current state (including axes in Backpack) to the slot.
    -- Without this, the load would restore an old state with no extra axes.
    setStatus('💾 Saving slot ' .. dupeSlot .. '...', YELLOW)
    notify('💾 Saving slot ' .. dupeSlot .. '...')

    local saveOk = false
    local saveResult = nil
    local saveAttempts = 0
    repeat
        saveAttempts += 1
        local ok, result = pcall(function()
            return RequestSave:InvokeServer(dupeSlot)
        end)
        if ok then
            saveResult = result
            saveOk = true
        else
            task.wait(1)
        end
    until saveOk or saveAttempts >= 3

    if not saveOk then
        hookLoop = false
        dupeRunning = false
        SelectLoadPlot.OnClientInvoke = nil
        setStatus('Idle (save error)', RED)
        return notify('❌ RequestSave call failed. Are you in-game?')
    end

    if saveResult == false then
        -- Server returned false = already saving/loading, wait and retry
        setStatus('⏳ Save busy, waiting...', YELLOW)
        waitForSaveLoad(10)
        task.wait(0.5)
        local ok2, result2 = pcall(function()
            return RequestSave:InvokeServer(dupeSlot)
        end)
        if not ok2 or result2 == false then
            hookLoop = false
            dupeRunning = false
            SelectLoadPlot.OnClientInvoke = nil
            setStatus('Idle (save busy)', RED)
            return notify('❌ Server still busy. Try again in a few seconds.')
        end
    end

    setStatus('✅ Saved! Loading...', GREEN)
    notify('✅ Saved! Now loading slot ' .. dupeSlot .. '...')
    task.wait(0.6)  -- small gap between save and load

    -- ── STEP 5: LOAD SLOT ─────────────────────────────
    -- Server receives this, TPs char outside the map (into the void),
    -- kills the character, respawns at spawn point, then calls
    -- SelectLoadPlot.OnClientInvoke → our hook returns the property.
    -- Axes in Backpack survive the void death → load adds axes from save → DOUBLED.
    setStatus('🔄 Loading slot ' .. dupeSlot .. '...', YELLOW)
    notify('🔄 Loading — character will reset...')

    local loadResult = nil
    local loadOk = false
    local ok3, result3 = pcall(function()
        return RequestLoad:InvokeServer(dupeSlot)
    end)
    if ok3 then
        loadOk = true
        loadResult = result3
    end

    if not loadOk then
        hookLoop = false
        dupeRunning = false
        SelectLoadPlot.OnClientInvoke = nil
        setStatus('Idle (load error)', RED)
        return notify('❌ RequestLoad call failed. Are you in-game?')
    end

    if loadResult == false then
        hookLoop = false
        dupeRunning = false
        SelectLoadPlot.OnClientInvoke = nil
        setStatus('Idle (load cooldown)', RED)
        return notify('❌ Load on cooldown. Wait ~30s and try again.')
    end

    -- loadResult == true means server accepted the request.
    -- Character will get killed by server. Our SelectLoadPlot hook will fire.
    setStatus('⏳ Waiting for server...', GREEN)
    notify('⏳ Server accepted load. Character resetting...')
    -- Hook handles everything from here.
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
N('TextLabel',{Text='⚡ Delta Hub v10',Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=bar})

local minBtn=N('TextButton',{Text='─',Size=UDim2.new(0,28,0,22),Position=UDim2.new(1,-60,0.5,-11),BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TS,Parent=bar})
rnd(minBtn,UDim.new(0,6))
local body=N('Frame',{Size=UDim2.new(1,0,1,-TH),Position=UDim2.new(0,0,0,TH),BackgroundTransparency=1,Parent=win})
local minimised=false
minBtn.MouseButton1Click:Connect(function()
    minimised=not minimised
    tw(body,{Size=minimised and UDim2.new(1,0,0,0) or UDim2.new(1,0,1,-TH)})
    minBtn.Text=minimised and '+' or '─'
end)

-- draggable
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

-- ── UI COMPONENTS ────────────────────────────────────
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

local function DynLabel(p, defaultTxt)
    local l=N('TextLabel',{Text=defaultTxt or '',Size=UDim2.new(1,0,0,BH),
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
    Section(Dp,'Live Status')
    dupeStatusLbl = DynLabel(Dp, 'Idle')

    -- Live "Currently Loaded Slot" display — updates every 2s
    local loadedSlotLabel = DynLabel(Dp, 'Loaded Slot: checking...')
    loadedSlotLabel.TextColor3 = Color3.fromRGB(0,180,255)
    task.spawn(function()
        while true do
            task.wait(2)
            pcall(function()
                local v = CurrentSaveSlot.Value
                loadedSlotLabel.Text = v == -1
                    and 'Loaded Slot: NONE (load in-game first!)'
                    or  'Loaded Slot: ' .. v .. '  ← set slider to match'
                loadedSlotLabel.TextColor3 = v == -1
                    and RED
                    or  Color3.fromRGB(0,205,145)
            end)
        end
    end)

    Section(Dp,'How To Use')
    Hint(Dp,'1. Load your land in-game\n2. Put axe in backpack (unequip)\n3. Set slider to match your loaded slot number\n4. Click Dupe Axe\n5. Confirm land placement screen\n6. Your axe will be doubled!')
    Section(Dp,'Slot (must match loaded slot above)')
    Slid(Dp,'Dupe Slot',1,6,1,1,function(v) dupeSlot=v end)
    Section(Dp,'Actions')
    Btn(Dp,'🪓  Dupe Axe  (click again to cancel)',function() task.spawn(dupeAxe) end)
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
    Hint(La,'Claims nearest free property for free.')
    Btn(La,'🏠  Get Free Land',freeLand)
    Section(La,'Expand Land')
    Hint(La,'Fires all 24 expansion remotes to instantly max your land.')
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
    Hint(Ax,'Equip axe first. Values from AxeSuperClass.lua (range ray, cooldown upvalue).')
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
print('[Delta Hub v10] Loaded — correct remotes: LoadSaveRequests.RequestSave/RequestLoad')
