-- ═══════════════════════════════════════════════════════
--  Delta Hub  |  LT2  |  Mobile-First  |  v11
--
--  ROOT CAUSE FIX for "dupe success — 0 axes":
--
--  The dupe cycle WAS working (land reset, money reset confirmed).
--  But axes showed 0 after because of WHERE axes lived during death.
--
--  WRONG (v10): Axes stayed in Player.Backpack during the kill.
--  LT2's server load wipes Backpack during character reset,
--  then restores ONLY what was in the save. So you got:
--    Backpack after load = save contents (1 axe) BUT original lost = 1 axe
--
--  CORRECT (v11): PARK axes on Player object (not Backpack) before kill.
--  Player object persists across character deaths. Server doesn't touch it.
--  THEN after respawn, move them back to Backpack alongside save-restored ones.
--  Result:
--    Player object = your original axe(s)          (survived death)
--    Backpack      = axe(s) restored from save      (from the load)
--    Total         = ORIGINAL + SAVE COPY = DOUBLED ✅
--
--  CORRECT DUPE FLOW (v11):
--    1. Validate: land loaded, slot loaded, axes exist
--    2. Unequip axe into Backpack
--    3. Hook SelectLoadPlot (auto-confirm land placement)
--    4. RequestSave → saves state WITH axes in Backpack
--    5. ★ PARK AXES: move Backpack axes → Player object (survive death)
--    6. RequestLoad → server TPs char out of map and kills it
--    7. Char dies → Backpack cleared by server, Player object untouched
--    8. Char respawns at spawn → axes still sitting on Player object
--    9. SelectLoadPlot fires → our hook returns property → load completes
--   10. Load restores axes INTO Backpack (from the save in step 4)
--   11. ★ UNPARK AXES: move Player object axes → Backpack
--   12. Backpack now has: original axes + save copy = DOUBLED
--   13. TP to base
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
local LoadSaveRequests  = ReplicatedStorage:WaitForChild('LoadSaveRequests')
local RequestSave       = LoadSaveRequests:WaitForChild('RequestSave')
local RequestLoad       = LoadSaveRequests:WaitForChild('RequestLoad')
local GetMetaData       = LoadSaveRequests:WaitForChild('GetMetaData')

local PropPurch               = ReplicatedStorage:WaitForChild('PropertyPurchasing')
local SelectLoadPlot          = PropPurch:WaitForChild('SelectLoadPlot')
local SetPropertyPurchValue   = PropPurch:FindFirstChild('SetPropertyPurchasingValue')
local ClientPurchasedProperty = PropPurch:FindFirstChild('ClientPurchasedProperty')
local ClientExpandedProperty  = PropPurch:FindFirstChild('ClientExpandedProperty')

local ClientInteracted = ReplicatedStorage.Interaction.ClientInteracted
local ClientIsDragging = ReplicatedStorage.Interaction.ClientIsDragging
local RemoteProxy      = ReplicatedStorage.Interaction.RemoteProxy
local SendUserNotice   = ReplicatedStorage.Notices.SendUserNotice
local AxeFolder        = ReplicatedStorage.AxeClasses

-- ── PLAYER VALUES ──────────────────────────────────────
local CurrentSaveSlot          = Player:WaitForChild('CurrentSaveSlot')
local CurrentlySavingOrLoading = Player:WaitForChild('CurrentlySavingOrLoading')

-- ── HELPERS ───────────────────────────────────────────
local function char()  return Player.Character end
local function hum()   local c=char(); return c and c:FindFirstChild('Humanoid') end
local function root()  local c=char(); return c and c:FindFirstChild('HumanoidRootPart') end

local function notify(msg)
    pcall(function() SendUserNotice:Fire(msg) end)
end

-- Gets ALL axes from both Backpack and equipped on character
local function getAxes(includeParked)
    local t = {}
    local c = char()
    for _,v in ipairs(Player.Backpack:GetChildren()) do
        if v:FindFirstChild('CuttingTool') then t[#t+1] = v end
    end
    if c then
        for _,v in ipairs(c:GetChildren()) do
            if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then t[#t+1] = v end
        end
    end
    -- Optionally also count parked axes on Player object
    if includeParked then
        for _,v in ipairs(Player:GetChildren()) do
            if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then t[#t+1] = v end
        end
    end
    return t
end

-- ★ PARK: Move all axes from Backpack → Player object
-- Tools on Player object survive character death (server never clears Player)
local function parkAxes()
    local h = hum()
    if h then h:UnequipTools() end
    task.wait(0.2)
    local parked = {}
    for _,v in ipairs(Player.Backpack:GetChildren()) do
        if v:FindFirstChild('CuttingTool') then
            v.Parent = Player   -- ← KEY: Player object, NOT Backpack
            parked[#parked+1] = v
        end
    end
    -- Also park any still on character just in case
    local c = char()
    if c then
        for _,v in ipairs(c:GetChildren()) do
            if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then
                v.Parent = Player
                parked[#parked+1] = v
            end
        end
    end
    return parked
end

-- ★ UNPARK: Move parked axes from Player object → Backpack
local function unParkAxes()
    local restored = 0
    for _,v in ipairs(Player:GetChildren()) do
        if v:IsA('Tool') and v:FindFirstChild('CuttingTool') then
            v.Parent = Player.Backpack
            restored += 1
        end
    end
    return restored
end

local function safeSuicide()
    pcall(function() char().Humanoid.Health = 0 end)
end

local function getMyProp()
    for _,p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild('Owner') and p.Owner.Value == Player then return p end
    end
end

local function getFreeProp()
    local best,dist = nil,math.huge
    local r = root(); if not r then return end
    for _,p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild('Owner') and p.Owner.Value == nil and p:FindFirstChild('OriginSquare') then
            local d = (p.OriginSquare.CFrame.p - r.CFrame.p).Magnitude
            if d < dist then dist = d; best = p end
        end
    end
    return best
end

local function safeWaitChar(timeoutSecs)
    local result = nil
    local done   = false
    local conn
    conn = Player.CharacterAdded:Connect(function(c)
        result = c; done = true; conn:Disconnect()
    end)
    local tStart = os.clock()
    while not done and (os.clock() - tStart) < (timeoutSecs or 20) do
        task.wait(0.1)
    end
    if not done then pcall(function() conn:Disconnect() end) end
    return result or char()
end

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
    local c = char(); if not c then return end
    local tool = c:FindFirstChildOfClass('Tool')
    if not tool or not tool:FindFirstChild('ToolName') then return end
    local w = 0
    repeat task.wait(0.1); w += 0.1 until getconnections(tool.Activated)[1] or w > 3
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
Player.CharacterAdded:Connect(hookChar)

-- ═══════════════════════════════════════════════════════
--  DUPE AXE — v11
-- ═══════════════════════════════════════════════════════
local dupeRunning   = false
local dupeSlot      = 1
local dupeStatusLbl = nil

local YELLOW = Color3.fromRGB(220,180,0)
local GREEN  = Color3.fromRGB(0,205,145)
local RED    = Color3.fromRGB(200,60,60)
local GREY   = Color3.fromRGB(110,128,155)
local BLUE   = Color3.fromRGB(80,160,255)

local function setStatus(txt, col)
    if dupeStatusLbl then
        pcall(function()
            dupeStatusLbl.Text = txt
            if col then dupeStatusLbl.TextColor3 = col end
        end)
    end
end

local function dupeAxe()
    if dupeRunning then
        -- Emergency cancel: also unpark any stranded axes
        dupeRunning = false
        pcall(unParkAxes)
        pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
        setStatus('Idle (cancelled)', GREY)
        return notify('Dupe cancelled — axes restored to backpack.')
    end

    -- ── STEP 1: VALIDATE ──────────────────────────────
    local axes = getAxes()
    if #axes == 0 then
        return notify('❌ No axes found! Put an axe in your backpack.')
    end

    local prop = getMyProp()
    if not prop or not prop:FindFirstChild('OriginSquare') then
        return notify('❌ No land loaded. Load your land in-game first.')
    end

    if CurrentSaveSlot.Value == -1 then
        return notify('❌ No save slot loaded! Load a slot in-game first.')
    end

    if CurrentSaveSlot.Value ~= dupeSlot then
        notify('⚠️ Auto-correcting slot: ' .. dupeSlot .. ' → ' .. CurrentSaveSlot.Value)
        dupeSlot = CurrentSaveSlot.Value
        task.wait(0.5)
    end

    if CurrentlySavingOrLoading.Value then
        return notify('❌ Server busy saving/loading. Wait a moment.')
    end

    local plotCF    = prop.OriginSquare.CFrame
    local hookFired = false
    dupeRunning     = true

    setStatus('🔄 Starting dupe...', YELLOW)
    notify('⏳ Dupe starting! Do NOT click anything.')

    -- Global safety timeout: always resets state after 45s
    task.delay(45, function()
        if dupeRunning then
            dupeRunning = false
            pcall(unParkAxes)
            pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
            setStatus('Idle (timed out)', RED)
            notify('❌ Dupe timed out — axes returned to backpack.')
        end
    end)

    -- ── STEP 2: HOOK SelectLoadPlot ───────────────────
    local hookLoop = true
    task.spawn(function()
        local tStart = os.clock()
        while hookLoop and not hookFired and (os.clock()-tStart) < 60 do
            pcall(function()
                SelectLoadPlot.OnClientInvoke = function(_model)
                    if hookFired then return prop, 0 end
                    hookFired = true
                    hookLoop  = false
                    setStatus('🏠 Land confirmed! Restoring axes...', BLUE)
                    notify('🏠 Land placement confirmed!')

                    -- Keep property purchasing active
                    if SetPropertyPurchValue then
                        task.spawn(function()
                            for _ = 1, 6 do
                                task.wait(0.5)
                                pcall(function() SetPropertyPurchValue:InvokeServer(true) end)
                            end
                        end)
                    end

                    -- After respawn: restore parked axes + TP to base
                    task.spawn(function()
                        local newChar = safeWaitChar(20)
                        -- Wait for load to finish restoring Backpack from save
                        task.wait(3.5)

                        -- ★ STEP 11: UNPARK — move parked axes back to Backpack
                        -- At this point Backpack has the save-restored axes.
                        -- We add the parked (original) axes on top → DOUBLED.
                        local unparkedCount = unParkAxes()
                        task.wait(0.3)

                        local nc = newChar or char()
                        if nc and nc:FindFirstChild('HumanoidRootPart') then
                            nc:PivotTo(plotCF + Vector3.new(0, 6, 0))
                        end

                        task.wait(0.5)
                        local totalAxes = #getAxes(true)
                        setStatus('✅ Done! Axes: ' .. totalAxes, GREEN)
                        notify('✅ Dupe complete! You have ' .. totalAxes .. ' axe(s). ('.. unparkedCount ..' originals + save copy)')
                        dupeRunning = false
                    end)

                    return prop, 0
                end
            end)
            task.wait(0.03)
        end
        if not hookFired then
            hookLoop = false
            pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
            if dupeRunning then
                pcall(unParkAxes)
                dupeRunning = false
                setStatus('Idle (server no response)', RED)
                notify('❌ Server never called SelectLoadPlot. Axes returned to backpack.')
            end
        end
    end)

    task.wait(0.1)

    -- ── STEP 3: UNEQUIP → BACKPACK ────────────────────
    local h = hum()
    if h then h:UnequipTools() end
    task.wait(0.3)
    setStatus('📦 Axes unequipped', YELLOW)

    -- ── STEP 4: REQUEST SAVE ──────────────────────────
    -- Save WITH axes in Backpack so the slot captures them
    setStatus('💾 Saving slot ' .. dupeSlot .. '...', YELLOW)
    notify('💾 Saving...')

    local saveResult
    for attempt = 1, 3 do
        local ok, res = pcall(function()
            return RequestSave:InvokeServer(dupeSlot)
        end)
        if ok then
            saveResult = res
            break
        end
        task.wait(1)
    end

    if saveResult == nil then
        hookLoop = false
        dupeRunning = false
        pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
        setStatus('Idle (save failed)', RED)
        return notify('❌ RequestSave failed. Are you in-game?')
    end

    if saveResult == false then
        setStatus('⏳ Save busy, waiting...', YELLOW)
        waitForSaveLoad(10)
        task.wait(0.5)
        local ok2, res2 = pcall(function() return RequestSave:InvokeServer(dupeSlot) end)
        if not ok2 or res2 == false then
            hookLoop = false
            dupeRunning = false
            pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
            setStatus('Idle (save busy)', RED)
            return notify('❌ Server still busy saving. Wait ~30s and try again.')
        end
    end

    setStatus('✅ Saved!', GREEN)
    notify('✅ Saved!')
    task.wait(0.3)

    -- ── STEP 5: ★ PARK AXES ───────────────────────────
    -- Move axes from Backpack → Player object BEFORE death.
    -- They will survive the server's character kill+reset.
    setStatus('📦 Parking axes...', BLUE)
    local parkedAxes = parkAxes()
    local parkedCount = #parkedAxes
    notify('📦 Parked ' .. parkedCount .. ' axe(s) safely. Loading...')
    task.wait(0.3)

    if parkedCount == 0 then
        hookLoop = false
        dupeRunning = false
        pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
        setStatus('Idle (no axes to park)', RED)
        return notify('❌ Could not park axes — are they in backpack?')
    end

    -- ── STEP 6: REQUEST LOAD ──────────────────────────
    -- Server will: TP char out of map → kill char → respawn → call SelectLoadPlot
    setStatus('🔄 Loading slot ' .. dupeSlot .. '...', YELLOW)
    notify('🔄 Loading — character will reset now!')

    local ok3, loadResult = pcall(function()
        return RequestLoad:InvokeServer(dupeSlot)
    end)

    if not ok3 then
        hookLoop = false
        dupeRunning = false
        pcall(unParkAxes)
        pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
        setStatus('Idle (load error)', RED)
        return notify('❌ RequestLoad failed. Axes returned to backpack.')
    end

    if loadResult == false then
        hookLoop = false
        dupeRunning = false
        pcall(unParkAxes)
        pcall(function() SelectLoadPlot.OnClientInvoke = nil end)
        setStatus('Idle (load cooldown ~30s)', RED)
        return notify('❌ Load on cooldown (~30s). Axes returned. Try again shortly.')
    end

    -- loadResult == true: server accepted the load.
    -- Character will be killed. Our hook handles the rest.
    setStatus('⏳ Char resetting... confirm land!', GREEN)
    notify('⏳ Character resetting — when the land placement screen appears, confirm it!')
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
    local c = char()
    if c then c:PivotTo(CFrame.new(prop.OriginSquare.CFrame.p + Vector3.new(0,6,0))) end
end

local function maxLand()
    local prop = getMyProp()
    if not prop then
        notify('Getting free land first...')
        freeLand(); task.wait(2)
        prop = getMyProp()
    end
    if not prop then return notify('No land found!') end
    local s = prop.OriginSquare
    local x,y,z = s.Position.X, s.Position.Y, s.Position.Z
    local offs = {
        {40,0},{-40,0},{0,40},{0,-40},
        {40,40},{40,-40},{-40,40},{-40,-40},
        {80,0},{-80,0},{0,80},{0,-80},
        {80,80},{80,-80},{-80,80},{-80,-80},
        {40,80},{-40,80},{80,40},{80,-40},
        {-80,40},{-80,-40},{40,-80},{-40,-80},
    }
    for _,o in ipairs(offs) do
        ClientExpandedProperty:FireServer(prop, CFrame.new(x+o[1], y, z+o[2]))
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
        noclipConn = RunService.Stepped:Connect(function()
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
    local c = getconnections(Player.Idled)[1]; if not c then return end
    if on then c:Disable() else c:Enable() end
end
pcall(setAntiAFK, true)

local function sellAllLogs()
    local n = 0
    for _,log in ipairs(workspace.LogModels:GetChildren()) do
        if log:FindFirstChild('Owner') and (log.Owner.Value == nil or log.Owner.Value == Player) then
            n += 1
            task.spawn(function()
                pcall(function()
                    log.PrimaryPart = log.PrimaryPart or log:FindFirstChildOfClass('Part')
                    if not log.PrimaryPart then return end
                    local r = root()
                    if r and (r.CFrame.p - log.PrimaryPart.CFrame.p).Magnitude >= 8 then
                        Player.Character:PivotTo(CFrame.new(log.PrimaryPart.CFrame.p + Vector3.new(0,5,0)))
                    end
                    for _ = 1,20 do ClientIsDragging:FireServer(log); task.wait(0.1) end
                    for _ = 1,35 do log:PivotTo(CFrame.new(315,3,85)) end
                end)
            end)
        end
    end
    notify(n > 0 and 'Selling '..n..' log(s)...' or 'No owned logs.')
end

local autoChop = false
local function startAutoChop()
    autoChop = true
    task.spawn(function()
        while autoChop do
            task.wait(0.25)
            pcall(function()
                local r = root(); if not r then return end
                local axe = getAxes()[1]
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
local function tw(obj,props,t) TweenService:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),props):Play() end
local function rnd(obj,r) local u=Instance.new('UICorner'); u.CornerRadius=r or UDim.new(0,8); u.Parent=obj end
local function pd(obj,t,b,l,r)
    local p=Instance.new('UIPadding'); p.PaddingTop=UDim.new(0,t or 8)
    p.PaddingBottom=UDim.new(0,b or 8); p.PaddingLeft=UDim.new(0,l or 10)
    p.PaddingRight=UDim.new(0,r or 10); p.Parent=obj
end
local function strk(obj,col,t) local s=Instance.new('UIStroke'); s.Color=col or C.AccD; s.Thickness=t or 1; s.Parent=obj end

local sg=N('ScreenGui',{Name='DeltaHub',ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=gethui and gethui() or Player.PlayerGui})
local win=N('Frame',{Size=UDim2.new(0,WW,0,WH+TH+SW),BackgroundColor3=C.BG,BorderSizePixel=0,Position=UDim2.new(0.5,-WW/2,0.5,-(WH+TH+SW)/2),Parent=sg})
rnd(win); strk(win,C.AccD,1)

local bar=N('Frame',{Size=UDim2.new(1,0,0,TH),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=win})
rnd(bar)
N('TextLabel',{Text='⚡ Delta Hub v11',Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=bar})
local minBtn=N('TextButton',{Text='─',Size=UDim2.new(0,28,0,22),Position=UDim2.new(1,-60,0.5,-11),BackgroundColor3=C.El,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TS,Parent=bar})
rnd(minBtn,UDim.new(0,6))
local body=N('Frame',{Size=UDim2.new(1,0,1,-TH),Position=UDim2.new(0,0,0,TH),BackgroundTransparency=1,Parent=win})
local minimised=false
minBtn.MouseButton1Click:Connect(function()
    minimised=not minimised
    tw(body,{Size=minimised and UDim2.new(1,0,0,0) or UDim2.new(1,0,1,-TH)})
    minBtn.Text=minimised and '+' or '─'
end)

do local d,ox,oy=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true; ox=i.Position.X-win.Position.X.Offset; oy=i.Position.Y-win.Position.Y.Offset end end)
    UIS.InputChanged:Connect(function(i) if d and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then win.Position=UDim2.new(0,i.Position.X-ox,0,i.Position.Y-oy) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end end)
end

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

local function Section(p,txt)
    local f=N('Frame',{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Parent=p})
    N('TextLabel',{Text=txt:upper(),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    N('Frame',{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Sep,BorderSizePixel=0,Parent=f})
end
local function Hint(p,txt)
    local l=N('TextLabel',{Text=txt,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.El,BackgroundTransparency=0.4,BorderSizePixel=0,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=p})
    rnd(l,UDim.new(0,5)); pd(l,5,5,8,8)
end
local function DynLabel(p,txt,col)
    local l=N('TextLabel',{Text=txt or '',Size=UDim2.new(1,0,0,BH),BackgroundColor3=C.El,BackgroundTransparency=0,BorderSizePixel=0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=col or C.TS,TextXAlignment=Enum.TextXAlignment.Center,Parent=p})
    rnd(l); strk(l,C.AccD,1)
    return l
end
local function Btn(p,txt,cb,danger)
    local b=N('TextButton',{Size=UDim2.new(1,0,0,BH),BackgroundColor3=danger and C.Dng or C.El,BackgroundTransparency=danger and 0.3 or 0,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=danger and Color3.fromRGB(255,200,200) or C.Acc,Text=txt,BorderSizePixel=0,Parent=p})
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
    N('TextLabel',{Text=txt,Size=UDim2.new(1,-52,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=row})
    local tr=N('Frame',{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-44,0.5,-10),BackgroundColor3=st and C.TOn or C.TOff,BorderSizePixel=0,Parent=row})
    rnd(tr,UDim.new(1,0))
    local th=N('Frame',{Size=UDim2.new(0,15,0,15),Position=st and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=C.Th,BorderSizePixel=0,Parent=tr})
    rnd(th,UDim.new(1,0))
    local function set(s) st=s; tw(tr,{BackgroundColor3=s and C.TOn or C.TOff}); tw(th,{Position=s and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7)}); if cb then task.spawn(pcall,cb,s) end end
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
    N('TextLabel',{Text=txt,Size=UDim2.new(0.65,0,1,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TP,TextXAlignment=Enum.TextXAlignment.Left,Parent=top})
    local vl2=N('TextLabel',{Text=tostring(val),Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.Acc,TextXAlignment=Enum.TextXAlignment.Right,Parent=top})
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
    local function drag(pos) local rel=math.clamp((pos.X-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1); sv(mn+rel*(mx-mn)) end
    bg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=true; drag(i.Position) end end)
    UIS.InputChanged:Connect(function(i) if sd and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then drag(i.Position) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sd=false end end)
end

-- ── BUILD TABS ───────────────────────────────────────
do  -- DUPE
    local Dp=pages['Dupe']
    Section(Dp,'Live Status')
    dupeStatusLbl = DynLabel(Dp,'Idle',GREY)

    local slotLabel = DynLabel(Dp,'Loaded Slot: checking...', GREY)
    task.spawn(function()
        while true do
            task.wait(2)
            pcall(function()
                local v = CurrentSaveSlot.Value
                slotLabel.Text = v == -1
                    and '⚠ No slot loaded! Load a slot in-game first.'
                    or  'Loaded Slot: ' .. v .. ' ← set slider below to ' .. v
                slotLabel.TextColor3 = v == -1 and RED or GREEN
            end)
        end
    end)

    Section(Dp,'Instructions')
    Hint(Dp,'1. Load land in-game\n2. Slot slider must match loaded slot number above\n3. Click Dupe Axe — axes are auto-parked on Player before death\n4. Confirm the land placement screen\n5. Axes doubled automatically!')

    Section(Dp,'Slot (match your loaded slot)')
    Slid(Dp,'Dupe Slot',1,6,1,1,function(v) dupeSlot=v end)

    Section(Dp,'Dupe')
    Btn(Dp,'🪓  Dupe Axe  (click again to cancel)', function() task.spawn(dupeAxe) end)
    Btn(Dp,'🔧  Restore Parked Axes (emergency)',function()
        local n = unParkAxes()
        notify('Restored '..n..' parked axe(s) to backpack.')
    end)
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

do  -- LAND
    local La=pages['Land']
    Section(La,'Free Land')
    Hint(La,'Claims nearest free property for free.')
    Btn(La,'🏠  Get Free Land',freeLand)
    Section(La,'Expand Land')
    Hint(La,'Fires all 24 expansion remotes to instantly max your land.')
    Btn(La,'📐  Max Land',maxLand)
    Section(La,'Combined')
    Btn(La,'⚡  Free Land + Max',function() freeLand(); task.wait(2); maxLand() end)
end

do  -- AXE
    local Ax=pages['Axe']
    Section(Ax,'Modifiers')
    Hint(Ax,'Equip axe first. Hooks Activated upvalue from AxeSuperClass.lua.')
    Slid(Ax,'Range',10,400,50,5,function(v) axeMods.rangeVal=v; if axeMods.rangeOn then pcall(applyAxeMod) end end)
    Tog(Ax,'Activate Axe Range',false,function(v) axeMods.rangeOn=v; pcall(applyAxeMod) end)
    Tog(Ax,'No Swing Cooldown',false,function(v) axeMods.noCdOn=v; pcall(applyAxeMod) end)
end

do  -- PLAYER
    local Pl=pages['Player']
    Section(Pl,'Movement')
    Slid(Pl,'Walk Speed',16,100,16,1,function(v) local h=hum(); if h then h.WalkSpeed=v end end)
    Slid(Pl,'Jump Power',50,250,50,5,function(v) local h=hum(); if h then h.JumpPower=v end end)
    Tog(Pl,'Noclip',false,function(v) setNoclip(v) end)
    Section(Pl,'Utility')
    Tog(Pl,'Anti-AFK',true,function(v) pcall(setAntiAFK,v) end)
    Btn(Pl,'Safe Suicide  ⚠',safeSuicide,true)
end

do  -- WOOD
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
print('[Delta Hub v11] Loaded — axe parking fix applied')
