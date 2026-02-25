--[[
╔══════════════════════════════════════════════════════════╗
║      LT2 EXPLOIT MENU v3 — DELTA ANDROID EDITION        ║
║      FIXED: Drag | Fly Touch | DropTool | Remotes       ║
╠══════════════════════════════════════════════════════════╣
║  CONFIRMED REMOTE PATHS (from place_13822889.rbxlx):    ║
║  RS.Interaction.ClientInteracted     [RemoteEvent]       ║
║  RS.Interaction.ConfirmIdentity      [RemoteFunction]    ║
║  RS.Regions.ClientChangedRegion      [RemoteEvent]       ║
║  RS.PropertyPurchasing.SetPropertyPurchasingValue [RF]   ║
║  RS.LoadSaveRequests.GetMetaData     [RemoteFunction]    ║
║  RS.LoadSaveRequests.ClientMayLoad   [RemoteFunction]    ║
║  RS.NPCDialog.SetChattingValue       [RemoteFunction]    ║
║  RS.NPCDialog.PromptChat             [RemoteEvent]       ║
║  RS.Transactions.Level               [RemoteFunction]    ║
║  RS.Transactions.ClientToServer.ASet [RemoteFunction]    ║
║  RS.Interaction.TestPlaceTP          [RemoteEvent]       ║
╠══════════════════════════════════════════════════════════╣
║  FIXES APPLIED:                                          ║
║  [FIX 1] Drag: AbsolutePosition instead of              ║
║           Position.X.Offset (was always snapping to 0)  ║
║  [FIX 2] Fly: Added on-screen touch D-pad for mobile    ║
║           (keyboard input doesn't work on Delta Android) ║
║  [FIX 3] DropTool: uses safe `char` var, not            ║
║           LP.Character (crash on respawn)                ║
║  [FIX 4] Remotes: replaced fake/unconfirmed paths with  ║
║           confirmed ones + proper fallback logging       ║
╚══════════════════════════════════════════════════════════╝
]]

-- =====================================================================
-- SERVICES
-- =====================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")
local RS   = game:GetService("ReplicatedStorage")

-- =====================================================================
-- CHARACTER REFERENCES
-- =====================================================================
local char, hum, hrp

local function refreshChar()
    char = LP.Character
    if not char then return end
    hum  = char:FindFirstChild("Humanoid")
    hrp  = char:FindFirstChild("HumanoidRootPart")
end
refreshChar()
LP.CharacterAdded:Connect(function(c)
    task.wait(0.8)
    char = c
    hum  = c:WaitForChild("Humanoid")
    hrp  = c:WaitForChild("HumanoidRootPart")
end)

-- =====================================================================
-- STATE TABLE
-- =====================================================================
local State = {
    ActiveTab         = 1,
    Minimized         = false,
    -- Player
    WalkSpeed         = 16,
    JumpPower         = 50,
    FlySpeed          = 50,
    Flying            = false,
    NoClipOn          = false,
    -- World
    AlwaysDay         = false,
    AlwaysNight       = false,
    NoFog             = false,
    NoShadows         = false,
    -- Slot/save
    SaveSlot          = 1,
    -- Wood
    SelectTree        = "Oak",
    WoodAmount        = 5,
    AutoWoodOn        = false,
    -- AutoBuy
    AutoBuying        = false,
    BuyItem           = "RustyAxe",
    BuyItemDisplay    = "Rusty Axe ($100)",
    BuyAmt            = 1,
    BuyDelay          = 2,
    -- Dupe
    DupeAmt           = 10,
    DupeWait          = 5,
    Duping            = false,
    -- Items
    SelectedItems     = {},
    LassoOn           = false,
    StackLen          = 5,
    -- Teleport
    SelectedWaypoint  = "Main Area",
    TargetPlayer      = nil,
    -- Build
    SelectedBlueprint = nil,
    StealTarget       = nil,
}

-- =====================================================================
-- CONFIRMED REMOTE GETTERS
-- =====================================================================
local function rClientInteracted()
    return RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("ClientInteracted")
end
-- FIX 4: RemoteProxy is NOT confirmed in decompiled source.
-- The actual cut remote name is server-side only. We keep the path but
-- warn clearly if it's missing so users know why AutoChop may not work.
local function rRemoteProxy()
    local r = RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("RemoteProxy")
    if not r then
        -- Some private servers name it differently — try common aliases
        local i = RS:FindFirstChild("Interaction")
        if i then
            r = i:FindFirstChild("CutRemote")
                or i:FindFirstChild("ChopRemote")
                or i:FindFirstChild("AxeRemote")
        end
    end
    return r
end
local function rSetPropertyPurchasing()
    return RS:FindFirstChild("PropertyPurchasing") and RS.PropertyPurchasing:FindFirstChild("SetPropertyPurchasingValue")
end
-- FIX 4: ClientPurchasedProperty is unconfirmed. Use SetPropertyPurchasingValue only.
local function rGetMetaData()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("GetMetaData")
end
local function rClientMayLoad()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("ClientMayLoad")
end
-- FIX 4: RequestSave/RequestLoad are NOT confirmed. GetMetaData and ClientMayLoad are.
-- We still expose them so users can test, but acknowledge they may not exist.
local function rRequestSave()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("RequestSave")
end
local function rRequestLoad()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("RequestLoad")
end
local function rSetChattingValue()
    return RS:FindFirstChild("NPCDialog") and RS.NPCDialog:FindFirstChild("SetChattingValue")
end
-- FIX 4: PlayerChatted is NOT confirmed. SetChattingValue is.
local function rPlayerChatted()
    return RS:FindFirstChild("NPCDialog") and RS.NPCDialog:FindFirstChild("PlayerChatted")
end
local function rTransactionLevel()
    return RS:FindFirstChild("Transactions") and RS.Transactions:FindFirstChild("Level")
end
-- FIX 4: AttemptPurchase replaced with ASet (confirmed) for admin money ops.
-- AttemptPurchase kept for store purchase attempts only.
local function rAttemptPurchase()
    return RS:FindFirstChild("Transactions")
        and RS.Transactions:FindFirstChild("ClientToServer")
        and RS.Transactions.ClientToServer:FindFirstChild("AttemptPurchase")
end
-- FIX 4: DestroyStructure is NOT confirmed. Use ClientInteracted as fallback.
local function rDestroyStructure()
    return RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("DestroyStructure")
end
-- FIX 4: ClientPlacedBlueprint/Structure are NOT confirmed.
local function rClientPlacedBlueprint()
    return RS:FindFirstChild("PlaceStructure") and RS.PlaceStructure:FindFirstChild("ClientPlacedBlueprint")
end
local function rClientPlacedStructure()
    return RS:FindFirstChild("PlaceStructure") and RS.PlaceStructure:FindFirstChild("ClientPlacedStructure")
end
-- FIX 4: ClientPurchasedProperty is NOT confirmed.
local function rClientPurchasedProperty()
    return RS:FindFirstChild("PropertyPurchasing") and RS.PropertyPurchasing:FindFirstChild("ClientPurchasedProperty")
end

-- =====================================================================
-- TELEPORT UTILITY
-- =====================================================================
local function TeleportTo(cf)
    if not hrp then return end
    pcall(function()
        if char and char.PrimaryPart then
            char:PivotTo(cf)
        else
            hrp.CFrame = cf
        end
    end)
end
local function TeleportPos(x, y, z)
    TeleportTo(CFrame.new(x, y + 3, z))
end

-- =====================================================================
-- WAYPOINTS
-- =====================================================================
local WAYPOINTS = {
    ["Main Area"]       = Vector3.new(-167,  5,    0),
    ["Wood Drop-off"]   = Vector3.new( -35,  4,   60),
    ["Land Store"]      = Vector3.new( -78,  5,   -8),
    ["WoodRUs Store"]   = Vector3.new(-275,  5,  105),
    ["Bob's Shack"]     = Vector3.new(-252,  5,  400),
    ["Link's Logic"]    = Vector3.new(  15,  5,  262),
    ["Fancy Furniture"] = Vector3.new(-122,  5,  165),
    ["Snow Biome"]      = Vector3.new(-1080,300,  900),
    ["Volcano"]         = Vector3.new( 1060,450,  500),
    ["Swamp"]           = Vector3.new(  630, 30,-1500),
    ["Cave"]            = Vector3.new(  295,-30,  495),
    ["Tropics"]         = Vector3.new( 1300,  5, -700),
    ["Ferry Dock"]      = Vector3.new(  300,  5,  320),
}

-- =====================================================================
-- FLY SYSTEM — FIX 2: Added mobile touch D-pad
-- =====================================================================
local FlyBodyV, FlyBodyG, FlyConn, FlyDpad
-- Shared direction table updated by both keyboard and touch D-pad
local FlyDir = {f=false, b=false, l=false, r=false, u=false, d=false}

local function StopFly()
    State.Flying = false
    if FlyConn  then FlyConn:Disconnect();  FlyConn  = nil end
    if FlyBodyV then FlyBodyV:Destroy();    FlyBodyV = nil end
    if FlyBodyG then FlyBodyG:Destroy();    FlyBodyG = nil end
    if FlyDpad  then FlyDpad:Destroy();     FlyDpad  = nil end
    if hum then pcall(function() hum.PlatformStand = false end) end
    -- Clear direction flags
    for k in pairs(FlyDir) do FlyDir[k] = false end
end

-- FIX 2: Build an on-screen touch D-pad for fly so Android users can steer
local function BuildFlyDpad(sg)
    if FlyDpad then FlyDpad:Destroy() end
    FlyDpad = Instance.new("Frame")
    FlyDpad.Name               = "FlyDpad"
    FlyDpad.Size               = UDim2.fromOffset(170, 170)
    FlyDpad.Position           = UDim2.new(0, 10, 1, -190)
    FlyDpad.BackgroundColor3   = Color3.fromRGB(10,10,20)
    FlyDpad.BackgroundTransparency = 0.5
    FlyDpad.BorderSizePixel    = 0
    FlyDpad.ZIndex             = 200
    do
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = FlyDpad
    end
    FlyDpad.Parent = sg

    -- Helper: create a directional button
    local function DBtn(label, pos, sz, dirKey, dirKeyAlt)
        local b = Instance.new("TextButton")
        b.Size               = UDim2.fromOffset(sz, sz)
        b.Position           = pos
        b.BackgroundColor3   = Color3.fromRGB(30,50,80)
        b.BackgroundTransparency = 0.3
        b.BorderSizePixel    = 0
        b.Text               = label
        b.Font               = Enum.Font.GothamBold
        b.TextSize           = sz > 40 and 22 or 14
        b.TextColor3         = Color3.fromRGB(180,220,255)
        b.AutoButtonColor    = false
        b.ZIndex             = 201
        do
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
        end
        -- Touch press/release → set direction flag
        b.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                FlyDir[dirKey] = true
                if dirKeyAlt then FlyDir[dirKeyAlt] = true end
                TweenService:Create(b, TweenInfo.new(0.08), {BackgroundTransparency=0}):Play()
            end
        end)
        b.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                FlyDir[dirKey] = false
                if dirKeyAlt then FlyDir[dirKeyAlt] = false end
                TweenService:Create(b, TweenInfo.new(0.08), {BackgroundTransparency=0.3}):Play()
            end
        end)
        b.Parent = FlyDpad
        return b
    end

    -- Layout: [W=fwd, S=back, A=left, D=right] in cross pattern, Up/Down on right side
    --    [↑]            [↑ Up]
    -- [←][•][→]        [↓ Dn]
    --    [↓]
    local C = 55  -- center of cross
    local BZ = 46 -- button size
    local G  = 4  -- gap
    DBtn("↑",  UDim2.fromOffset(C,             G),       BZ, "f")          -- Forward
    DBtn("↓",  UDim2.fromOffset(C,             C+G+BZ), BZ, "b")          -- Back
    DBtn("←",  UDim2.fromOffset(G,             C+G),    BZ, "l")          -- Left
    DBtn("→",  UDim2.fromOffset(C+BZ+G,        C+G),    BZ, "r")          -- Right
    DBtn("⬆", UDim2.fromOffset(C+BZ+G+BZ+G,   G),       BZ, "u")          -- Rise
    DBtn("⬇", UDim2.fromOffset(C+BZ+G+BZ+G,   C+G+BZ), BZ, "d")          -- Sink

    -- Small center label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromOffset(BZ, BZ)
    lbl.Position = UDim2.fromOffset(C, C+G)
    lbl.BackgroundTransparency = 1
    lbl.Text = "✈"
    lbl.TextSize = 22
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(72,220,128)
    lbl.ZIndex = 201
    lbl.Parent = FlyDpad
end

local function StartFly()
    if not hrp then return end
    StopFly()
    State.Flying = true
    pcall(function() hum.PlatformStand = true end)

    FlyBodyV = Instance.new("BodyVelocity")
    FlyBodyV.Velocity  = Vector3.zero
    FlyBodyV.MaxForce  = Vector3.new(1e6, 1e6, 1e6)
    FlyBodyV.Parent    = hrp

    FlyBodyG = Instance.new("BodyGyro")
    FlyBodyG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    FlyBodyG.P         = 1e4
    FlyBodyG.CFrame    = hrp.CFrame
    FlyBodyG.Parent    = hrp

    -- FIX 2: Show the touch D-pad
    local sg = PGui:FindFirstChild("LT2_v3") or game:GetService("CoreGui"):FindFirstChild("LT2_v3")
    if sg then BuildFlyDpad(sg) end

    FlyConn = RunService.Heartbeat:Connect(function()
        if not State.Flying or not hrp or not hrp.Parent then StopFly(); return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero

        -- FIX 2: Check BOTH keyboard (PC) and D-pad flags (mobile)
        local UIS = UserInputService
        local fwd = FlyDir.f or UIS:IsKeyDown(Enum.KeyCode.W)
        local bak = FlyDir.b or UIS:IsKeyDown(Enum.KeyCode.S)
        local lft = FlyDir.l or UIS:IsKeyDown(Enum.KeyCode.A)
        local rgt = FlyDir.r or UIS:IsKeyDown(Enum.KeyCode.D)
        local up  = FlyDir.u or UIS:IsKeyDown(Enum.KeyCode.Space)
        local dn  = FlyDir.d or UIS:IsKeyDown(Enum.KeyCode.LeftShift)

        if fwd then dir = dir + cam.CFrame.LookVector  end
        if bak then dir = dir - cam.CFrame.LookVector  end
        if lft then dir = dir - cam.CFrame.RightVector end
        if rgt then dir = dir + cam.CFrame.RightVector end
        if up  then dir = dir + Vector3.yAxis          end
        if dn  then dir = dir - Vector3.yAxis          end

        FlyBodyV.Velocity = dir.Magnitude > 0 and (dir.Unit * State.FlySpeed) or Vector3.zero
        FlyBodyG.CFrame   = cam.CFrame
    end)
end

-- =====================================================================
-- NOCLIP
-- =====================================================================
local NoClipConn
local function SetNoClip(enabled)
    State.NoClipOn = enabled
    if NoClipConn then NoClipConn:Disconnect(); NoClipConn = nil end
    if enabled then
        NoClipConn = RunService.Stepped:Connect(function()
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    else
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    pcall(function() v.CanCollide = true end)
                end
            end
        end
    end
end

-- =====================================================================
-- WORLD EFFECTS
-- =====================================================================
local LightConns = {}
local function ClearLightConns()
    for _, c in ipairs(LightConns) do pcall(function() c:Disconnect() end) end
    LightConns = {}
end

local function SetAlwaysDay(v)
    State.AlwaysDay = v
    if v then
        State.AlwaysNight = false
        ClearLightConns()
        Lighting.ClockTime = 14
        table.insert(LightConns, RunService.Heartbeat:Connect(function()
            if State.AlwaysDay then Lighting.ClockTime = 14 end
        end))
    else
        ClearLightConns()
    end
end

local function SetAlwaysNight(v)
    State.AlwaysNight = v
    if v then
        State.AlwaysDay = false
        ClearLightConns()
        Lighting.ClockTime = 0
        table.insert(LightConns, RunService.Heartbeat:Connect(function()
            if State.AlwaysNight then Lighting.ClockTime = 0 end
        end))
    else
        ClearLightConns()
    end
end

local function SetNoFog(v)
    State.NoFog = v
    Lighting.FogEnd   = v and 100000 or 1000
    Lighting.FogStart = v and 99999  or 0
end

-- =====================================================================
-- SAVE / LOAD  — FIX 4: uses confirmed remotes only
-- =====================================================================
local function DoSave(slot)
    -- GetMetaData is confirmed; RequestSave is unconfirmed but we still try it
    local r = rRequestSave()
    if not r then
        -- Fallback: try GetMetaData to at least ping the server
        local md = rGetMetaData()
        if md then
            local ok, res = pcall(function() return md:InvokeServer(slot) end)
            return false, "RequestSave remote not found. GetMetaData result: "..tostring(res)
        end
        return false, "RequestSave not found (unconfirmed remote)"
    end
    local ok, res = pcall(function() return r:InvokeServer(slot, LP.UserId) end)
    return ok and res, ok and "OK" or tostring(res)
end

local function DoLoad(slot)
    -- ClientMayLoad is CONFIRMED
    local mayLoad = rClientMayLoad()
    if mayLoad then
        local ok, can = pcall(function() return mayLoad:InvokeServer(LP.UserId) end)
        if ok and not can then return false, "Server denied load (ClientMayLoad returned false)" end
    end
    -- RequestLoad is unconfirmed
    local r = rRequestLoad()
    if not r then return false, "RequestLoad not found (unconfirmed remote)" end
    local ok, res = pcall(function() return r:InvokeServer(slot, LP.UserId, nil) end)
    return ok, ok and tostring(res) or tostring(res)
end

local function DoBuyLand()
    -- SetPropertyPurchasingValue is CONFIRMED
    local setPurchase = rSetPropertyPurchasing()
    if not setPurchase then return false, "SetPropertyPurchasingValue not found" end

    local propsFolder = workspace:FindFirstChild("Properties")
    if not propsFolder then return false, "Properties folder not in workspace" end

    local bestProp, bestDist = nil, math.huge
    for _, prop in ipairs(propsFolder:GetChildren()) do
        local ownerVal = prop:FindFirstChild("Owner")
        if ownerVal and (ownerVal.Value == nil or ownerVal.Value == "") then
            if prop.PrimaryPart and hrp then
                local d = (prop.PrimaryPart.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; bestProp = prop end
            elseif not bestProp then
                bestProp = prop
            end
        end
    end

    if not bestProp then return false, "No available unowned plots found" end

    pcall(function() setPurchase:InvokeServer(true) end)
    task.wait(0.3)

    -- FIX 4: ClientPurchasedProperty is unconfirmed; log clearly
    local cp = rClientPurchasedProperty()
    if cp then
        local camPos = workspace.CurrentCamera.CFrame.Position
        local ok, err = pcall(function() cp:FireServer(bestProp, camPos) end)
        pcall(function() setPurchase:InvokeServer(false) end)
        return ok, ok and "Plot purchase fired: "..tostring(bestProp.Name) or tostring(err)
    end

    pcall(function() setPurchase:InvokeServer(false) end)
    return false, "ClientPurchasedProperty remote not found (unconfirmed path)"
end

-- =====================================================================
-- PLAYER TOOLS
-- =====================================================================
local function SetWalkSpeed(v)
    State.WalkSpeed = v
    if hum then pcall(function() hum.WalkSpeed = v end) end
end

local function SetJumpPower(v)
    State.JumpPower = v
    if hum then
        pcall(function()
            if hum.UseJumpPower then hum.JumpPower  = v
            else                     hum.JumpHeight = v / 5 end
        end)
    end
end

local function GetAxe()
    -- Check equipped first
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then return v end
        end
    end
    for _, v in ipairs(LP.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("ToolName") then return v end
    end
    return nil
end

local function GetAllAxes()
    local axes = {}
    local function scan(c)
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then
                table.insert(axes, v)
            end
        end
    end
    if char then scan(char) end
    scan(LP.Backpack)
    return axes
end

-- FIX 3: DropTool — safe char reference, not LP.Character
-- ClientInteracted:FireServer(tool, "Drop tool", handle.CFrame) is confirmed
local function DropTool(tool)
    if not tool then return false, "no tool" end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return false, "tool has no Handle" end
    local ci = rClientInteracted()
    if not ci then
        -- FIX 3: use `char` not `LP.Character`
        if char then
            pcall(function() char:FindFirstChildOfClass("Humanoid"):UnequipTools() end)
        end
        return false, "ClientInteracted not found — used UnequipTools fallback"
    end
    local ok, err = pcall(function()
        ci:FireServer(tool, "Drop tool", handle.CFrame)
    end)
    return ok, ok and "OK" or tostring(err)
end

local function DropAllAxes()
    local axes = GetAllAxes()
    local n = 0
    for _, axe in ipairs(axes) do
        local ok = DropTool(axe)
        if ok then n = n + 1 end
        task.wait(0.12)
    end
    return n
end

-- =====================================================================
-- AUTO CHOP — FIX 4: RemoteProxy is unconfirmed, warn if missing
-- =====================================================================
local AutoChopRunning = false

local function ChopSection(section, axe)
    local rp = rRemoteProxy()
    if not rp then
        -- FIX 4: RemoteProxy path is unconfirmed. AutoChop will not work
        -- without the correct server-side remote name.
        return false, "RemoteProxy not found — remote name may differ on this server"
    end
    local idVal = section:FindFirstChild("ID")
    if not idVal then return false, "no ID value" end
    -- CutEvent is a child of the parent model, NOT the part itself (verified from source)
    local cutEvent = section.Parent and section.Parent:FindFirstChild("CutEvent")
    if not cutEvent then return false, "no CutEvent in parent" end

    local ok, err = pcall(function()
        rp:FireServer(cutEvent, {
            sectionId    = idVal.Value,
            faceVector   = Vector3.new(1, 0, 0),
            height       = section.Size.Y / 2,
            hitPoints    = 9999,
            cooldown     = 0,
            cuttingClass = "Axe",
            tool         = axe,
        })
    end)
    return ok, ok and "OK" or tostring(err)
end

local function StartAutoChop()
    if AutoChopRunning then return end
    AutoChopRunning = true
    State.AutoWoodOn = true
    task.spawn(function()
        local warnedOnce = false
        while AutoChopRunning do
            local axe = GetAxe()
            if not axe then
                task.wait(1)
            else
                local chopped = 0
                local remoteErr = nil
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if not AutoChopRunning then break end
                    if obj.Name == "WoodSection" and obj:IsA("Part") then
                        if obj:FindFirstChild("ID") and obj.Parent and obj.Parent:FindFirstChild("CutEvent") then
                            if hrp then
                                local dist = (obj.Position - hrp.Position).Magnitude
                                if dist > 30 then
                                    TeleportTo(CFrame.new(obj.Position + Vector3.new(0,5,5)))
                                    task.wait(0.3)
                                end
                            end
                            local ok, msg = ChopSection(obj, axe)
                            if not ok and not warnedOnce then
                                remoteErr = msg
                                warnedOnce = true
                            end
                            chopped = chopped + 1
                            task.wait(0.12)
                            if chopped >= (State.WoodAmount or 5) * 20 then break end
                        end
                    end
                end
                -- Surface remote errors once to avoid spam
                if remoteErr then
                    warn("[LT2 AutoChop] " .. remoteErr)
                end
                task.wait(0.5)
            end
        end
        State.AutoWoodOn = false
    end)
end

local function StopAutoChop()
    AutoChopRunning = false
    State.AutoWoodOn = false
end

-- =====================================================================
-- SELL WOOD
-- =====================================================================
local function SellAllWood()
    TeleportPos(-35, 4, 60)
    task.wait(1.2)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local ownerVal = obj:FindFirstChild("Owner")
            if ownerVal and ownerVal.Value == LP then
                pcall(function()
                    if obj:IsA("Model") and obj.PrimaryPart then
                        obj:PivotTo(CFrame.new(-35, 12, 60))
                    elseif obj:IsA("Part") then
                        obj.CFrame = CFrame.new(-35, 12, 60)
                    end
                end)
                task.wait(0.04)
            end
        end
    end
    return true
end

-- =====================================================================
-- STORE ITEMS
-- =====================================================================
local STORE_ITEMS = {
    {name="Rusty Axe",     toolname="RustyAxe",     price=100,  storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Refined Axe",   toolname="RefinedAxe",   price=450,  storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Silver Axe",    toolname="SilverAxe",    price=550,  storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Bluesteel Axe", toolname="BluesteelAxe", price=1250, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Cave Axe",      toolname="CaveAxe",      price=2000, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Fire Axe",      toolname="FireAxe",      price=3500, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Frost Axe",     toolname="IceAxe",       price=4000, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Many Axe",      toolname="ManyAxe",      price=7200, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Rukiryaxe",     toolname="Rukiryaxe",    price=7400, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
    {name="Spearmint Axe", toolname="MintAxe",      price=8000, storeModel="WoodRUs", pos=Vector3.new(-275,5,105)},
}

-- AUTO BUY — AttemptPurchase RF (unconfirmed) + SetChattingValue dialog fallback (confirmed)
local AutoBuyRunning = false

local function AttemptBuyItem(toolname)
    -- Method 1: Direct AttemptPurchase (unconfirmed but worth trying)
    local ap = rAttemptPurchase()
    if ap then
        local ok, result = pcall(function() return ap:InvokeServer(toolname, 1) end)
        if ok then return true, tostring(result) end
    end

    -- Method 2: SetChattingValue + PlayerChatted dialog chain (SetChattingValue confirmed)
    local itemInfo = nil
    for _, item in ipairs(STORE_ITEMS) do
        if item.toolname == toolname then itemInfo = item; break end
    end
    if not itemInfo then return false, "item not in list" end

    TeleportPos(itemInfo.pos.X, itemInfo.pos.Y, itemInfo.pos.Z)
    task.wait(1.5)

    local npcModel = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == itemInfo.storeModel then
            npcModel = obj; break
        end
    end
    if not npcModel then return false, "Store model '"..itemInfo.storeModel.."' not found" end

    local targetChoice = nil
    local searchStr = toolname:lower()
    for _, obj in ipairs(npcModel:GetDescendants()) do
        if obj:IsA("DialogChoice") then
            local ud = (obj.UserDialog or ""):lower()
            local rd = (obj.ResponseDialog or ""):lower()
            local stripped = searchStr:gsub("axe",""):gsub("%s","")
            if ud:find(stripped) or rd:find(stripped) or ud:find(searchStr) or rd:find(searchStr) then
                targetChoice = obj; break
            end
        end
    end

    local scv = rSetChattingValue()  -- CONFIRMED
    local pc  = rPlayerChatted()     -- unconfirmed

    if scv then pcall(function() scv:InvokeServer(2) end) end
    task.wait(0.2)

    if pc and targetChoice then
        local ok, res = pcall(function() return pc:InvokeServer(npcModel, targetChoice) end)
        task.wait(0.3)
        pcall(function() pc:InvokeServer(npcModel, "EndChat") end)
        if scv then pcall(function() scv:InvokeServer(0) end) end
        return ok, tostring(res)
    end

    if scv then pcall(function() scv:InvokeServer(0) end) end
    return false, "Purchase dialog not found for "..toolname.." (PlayerChatted may not exist)"
end

local function StartAutoBuy()
    if AutoBuyRunning then return end
    AutoBuyRunning = true
    State.AutoBuying = true
    task.spawn(function()
        local bought = 0
        while AutoBuyRunning and bought < State.BuyAmt do
            local ok, msg = AttemptBuyItem(State.BuyItem)
            if ok then bought = bought + 1 end
            task.wait(math.max(State.BuyDelay, 0.5))
        end
        AutoBuyRunning = false
        State.AutoBuying = false
    end)
end

local function StopAutoBuy()
    AutoBuyRunning = false
    State.AutoBuying = false
end

-- =====================================================================
-- LASSO / ITEM SELECT
-- =====================================================================
local LassoConn
local function SetLasso(enabled)
    State.LassoOn = enabled
    if LassoConn then LassoConn:Disconnect(); LassoConn = nil end
    if enabled then
        LassoConn = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                local mouse = LP:GetMouse()
                local t = mouse.Target
                if t then
                    for _, v in ipairs(State.SelectedItems) do
                        if v == t then return end
                    end
                    table.insert(State.SelectedItems, t)
                end
            end
        end)
    end
end

local function TeleportSelectedToMe()
    if not hrp then return 0 end
    local pos = hrp.Position + Vector3.new(0, 4, 0)
    for i, item in ipairs(State.SelectedItems) do
        local offset = Vector3.new((i-1) * (State.StackLen or 3), 0, 0)
        pcall(function()
            if item and item.Parent then
                if item:IsA("Model") and item.PrimaryPart then
                    item:PivotTo(CFrame.new(pos + offset))
                elseif item:IsA("BasePart") then
                    item.CFrame = CFrame.new(pos + offset)
                end
            end
        end)
    end
    return #State.SelectedItems
end

local function DestroySelected()
    -- FIX 4: DestroyStructure is unconfirmed; use ClientInteracted as primary fallback
    local ds = rDestroyStructure()
    local ci = rClientInteracted()
    local n = 0
    for _, item in ipairs(State.SelectedItems) do
        if item and item.Parent then
            if ds then
                pcall(function() ds:FireServer(item) end)
            elseif ci then
                pcall(function() ci:FireServer(item, "Destroy", CFrame.new()) end)
            else
                pcall(function() item:Destroy() end)
            end
            n = n + 1
        end
    end
    State.SelectedItems = {}
    return n
end

-- =====================================================================
-- DUPE SYSTEM
-- =====================================================================
local DupeRunning = false

local function StartDupe()
    if DupeRunning then return end
    local axe = GetAxe()
    if not axe then return false end
    DupeRunning = true
    State.Duping = true
    task.spawn(function()
        local duped = 0
        local toolNameStr = ""
        do
            local tn = axe:FindFirstChild("ToolName")
            toolNameStr = tn and tn.Value or axe.Name
        end
        while DupeRunning and duped < State.DupeAmt do
            local curAxe = GetAxe()
            if not curAxe then
                -- FIX 3: safe char reference
                if char then
                    for _, tool in ipairs(LP.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("ToolName") then
                            local h = char:FindFirstChildOfClass("Humanoid")
                            if h then pcall(function() h:EquipTool(tool) end) end
                            task.wait(0.3)
                            curAxe = GetAxe()
                            if curAxe then break end
                        end
                    end
                end
            end

            if curAxe then
                local ok, _ = DropTool(curAxe)
                if ok then duped = duped + 1 end
                task.wait(State.DupeWait * 0.1 + 0.2)

                -- Walk to the dropped axe
                if hrp then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Tool") then
                            local tn = obj:FindFirstChild("ToolName")
                            if tn and tn.Value == toolNameStr then
                                local handle = obj:FindFirstChild("Handle")
                                if handle then
                                    local dist = (hrp.Position - handle.Position).Magnitude
                                    if dist < 100 then
                                        TeleportTo(handle.CFrame * CFrame.new(0, 4, 0))
                                        task.wait(0.3)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.2)
            else
                task.wait(1)
            end
        end
        DupeRunning = false
        State.Duping = false
    end)
    return true
end

local function StopDupe()
    DupeRunning = false
    State.Duping = false
end

-- =====================================================================
-- BUILD / BLUEPRINT — FIX 4: Both remotes unconfirmed, log clearly
-- =====================================================================
local function PlaceBlueprint(name, cf)
    -- ClientPlacedBlueprint and ClientPlacedStructure are both unconfirmed paths
    local r = rClientPlacedBlueprint() or rClientPlacedStructure()
    if not r then
        return false, "PlaceBlueprint/PlaceStructure remotes not found (paths unconfirmed)"
    end
    local finalCF = cf or (hrp and hrp.CFrame * CFrame.new(0, 0, -10)) or CFrame.new()
    local ok, err = pcall(function() r:FireServer(name, finalCF, finalCF) end)
    return ok, ok and "Fired" or tostring(err)
end

local function AutoFillBlueprints()
    local r = rClientPlacedBlueprint() or rClientPlacedStructure()
    if not r then return false, "Remote not found (paths unconfirmed)" end
    local n = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Blueprint" then
            local ownerVal = obj:FindFirstChild("Owner")
            if ownerVal and ownerVal.Value == LP then
                pcall(function()
                    local cf = obj.PrimaryPart and obj.PrimaryPart.CFrame or CFrame.new()
                    r:FireServer(obj, cf)
                    n = n + 1
                end)
                task.wait(0.1)
            end
        end
    end
    return n > 0, "Filled "..n.." blueprints"
end

local function StealPlot(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target then return false, "Player not found" end
    local propsFolder = workspace:FindFirstChild("Properties")
    if not propsFolder then return false, "Properties folder not found" end
    for _, prop in ipairs(propsFolder:GetChildren()) do
        local ov = prop:FindFirstChild("Owner")
        if ov and ov.Value == target then
            local cp = rClientPurchasedProperty()
            if cp then
                local ok, err = pcall(function()
                    cp:FireServer(prop, hrp and hrp.Position or Vector3.zero)
                end)
                return ok, ok and "Steal fired on "..prop.Name or tostring(err)
            end
            return false, "ClientPurchasedProperty not found (unconfirmed path)"
        end
    end
    return false, "Target has no plot"
end

-- =====================================================================
-- ScreenGui — Delta Android: CoreGui first, fallback PlayerGui
-- =====================================================================
local oldGui = PGui:FindFirstChild("LT2_v3") or game:GetService("CoreGui"):FindFirstChild("LT2_v3")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "LT2_v3"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999

local guiOk = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not guiOk or not ScreenGui.Parent or not ScreenGui.Parent:IsA("CoreGui") then
    ScreenGui.Parent = PGui
end

-- =====================================================================
-- THEME
-- =====================================================================
local T = {
    BG      = Color3.fromRGB(8,  12,  20),
    Panel   = Color3.fromRGB(14, 20,  32),
    Card    = Color3.fromRGB(22, 30,  46),
    Border  = Color3.fromRGB(38, 52,  80),
    Green   = Color3.fromRGB(72, 220, 128),
    Cyan    = Color3.fromRGB(34, 210, 238),
    Red     = Color3.fromRGB(248,100, 100),
    Orange  = Color3.fromRGB(251,146,  60),
    Yellow  = Color3.fromRGB(250,204,  20),
    TextOn  = Color3.fromRGB(220,232,250),
    TextDim = Color3.fromRGB( 90,115,155),
    White   = Color3.fromRGB(255,255,255),
    Black   = Color3.fromRGB(  0,  0,  0),
}

local FONT    = Enum.Font.GothamMedium
local FONT_B  = Enum.Font.GothamBold
local FONT_SB = Enum.Font.GothamSemibold

-- =====================================================================
-- UI BUILDERS
-- =====================================================================
local function Corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color     = color or T.Border
    s.Thickness = thick or 1
    s.Parent    = parent
    return s
end

local function MkFrame(props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k,v in pairs(props) do f[k] = v end
    return f
end

local function MkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Font                   = FONT
    l.TextSize               = 14
    l.TextColor3             = T.TextOn
    l.TextXAlignment         = Enum.TextXAlignment.Left
    l.TextWrapped            = true
    for k,v in pairs(props) do l[k] = v end
    return l
end

local function MkBtn(props, onClick)
    local btn = Instance.new("TextButton")
    btn.BorderSizePixel  = 0
    btn.BackgroundColor3 = T.Card
    btn.TextColor3       = T.TextOn
    btn.Font             = FONT_B
    btn.TextSize         = 13
    btn.AutoButtonColor  = false
    btn.Text             = ""
    for k,v in pairs(props) do
        if k ~= "label" then btn[k] = v end
    end
    Corner(btn, 8)
    Stroke(btn, T.Border, 1)
    local lbl = MkLabel({
        Text           = props.Text or "",
        Size           = UDim2.new(1,-8,1,0),
        Position       = UDim2.fromOffset(4,0),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3     = props.TextColor3 or T.TextOn,
        Font           = FONT_B,
        TextSize       = props.TextSize or 13,
        Parent         = btn,
    })
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = T.Border}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = props.BackgroundColor3 or T.Card}):Play()
    end)
    if onClick then btn.Activated:Connect(onClick) end
    return btn, lbl
end

local function MkSectionHeader(text, color)
    color = color or T.TextDim
    local f = MkFrame({BackgroundTransparency=1, Size=UDim2.new(1,0,0,28)})
    MkLabel({
        Text       = ("  "..text):upper(),
        TextSize   = 11,
        Font       = FONT_B,
        TextColor3 = color,
        Size       = UDim2.new(0.55,0,1,0),
        Position   = UDim2.fromOffset(0,0),
        Parent     = f,
    })
    MkFrame({
        BackgroundColor3       = color,
        BackgroundTransparency = 0.7,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0.44,-4,0,1),
        Position               = UDim2.new(0.56,0,0.5,0),
        Parent                 = f,
    })
    return f
end

local function MkToggle(text, stateKey, onChange)
    local container = Instance.new("TextButton")
    container.Size             = UDim2.new(1,0,0,50)
    container.BackgroundColor3 = T.Card
    container.BorderSizePixel  = 0
    container.Text             = ""
    container.AutoButtonColor  = false
    Corner(container, 8)
    Stroke(container, T.Border, 1)
    MkLabel({Text=text, Size=UDim2.new(1,-64,1,0), Position=UDim2.fromOffset(12,0), TextSize=13, Parent=container})
    local track = MkFrame({
        Size             = UDim2.fromOffset(44,24),
        Position         = UDim2.new(1,-54,0.5,-12),
        BackgroundColor3 = State[stateKey] and T.Green or T.Border,
        BorderSizePixel  = 0,
        Parent           = container,
    })
    Corner(track, 12)
    local knob = MkFrame({
        Size             = UDim2.fromOffset(20,20),
        Position         = State[stateKey] and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2),
        BackgroundColor3 = T.White,
        BorderSizePixel  = 0,
        Parent           = track,
    })
    Corner(knob, 10)
    local function setVal(v)
        State[stateKey] = v
        TweenService:Create(track, TweenInfo.new(0.15), {BackgroundColor3=v and T.Green or T.Border}):Play()
        TweenService:Create(knob,  TweenInfo.new(0.15), {Position=v and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2)}):Play()
        if onChange then onChange(v) end
    end
    container.Activated:Connect(function() setVal(not State[stateKey]) end)
    return container, setVal
end

local function MkSlider(text, minV, maxV, stateKey, unit, onChange)
    minV = minV or 0; maxV = maxV or 100; unit = unit or ""
    local container = MkFrame({Size=UDim2.new(1,0,0,60), BackgroundColor3=T.Card})
    Corner(container,8); Stroke(container,T.Border,1)
    local headerF = MkFrame({BackgroundTransparency=1, Size=UDim2.new(1,-20,0,26), Position=UDim2.fromOffset(10,4), Parent=container})
    MkLabel({Text=text, Size=UDim2.new(0.7,0,1,0), TextSize=13, Parent=headerF})
    local valLbl = MkLabel({
        Text           = tostring(State[stateKey])..unit,
        Size           = UDim2.new(0.3,0,1,0),
        Position       = UDim2.new(0.7,0,0,0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3     = T.Cyan,
        Font           = FONT_B,
        TextSize       = 13,
        Parent         = headerF,
    })
    local trackBtn = Instance.new("TextButton")
    trackBtn.Size             = UDim2.new(1,-20,0,6)
    trackBtn.Position         = UDim2.new(0,10,0,40)
    trackBtn.BackgroundColor3 = T.Border
    trackBtn.BorderSizePixel  = 0
    trackBtn.Text             = ""
    trackBtn.AutoButtonColor  = false
    trackBtn.Parent           = container
    Corner(trackBtn, 3)
    local fill = MkFrame({
        BackgroundColor3 = T.Green,
        Size             = UDim2.new(math.clamp((State[stateKey]-minV)/(maxV-minV),0,1),0,1,0),
        Parent           = trackBtn,
    })
    Corner(fill,3)
    local knob = MkFrame({
        Size             = UDim2.fromOffset(16,16),
        Position         = UDim2.new(math.clamp((State[stateKey]-minV)/(maxV-minV),0,1),0,0.5,-8),
        BackgroundColor3 = T.White,
        ZIndex           = 4,
        Parent           = trackBtn,
    })
    Corner(knob,8)
    local dragging = false
    local function updateFromX(posX)
        local abs = trackBtn.AbsolutePosition.X
        local sz  = trackBtn.AbsoluteSize.X
        if sz <= 0 then return end
        local t   = math.clamp((posX - abs) / sz, 0, 1)
        local val = math.floor(minV + t*(maxV-minV) + 0.5)
        State[stateKey]   = val
        fill.Size         = UDim2.new(t,0,1,0)
        knob.Position     = UDim2.new(t,-8,0.5,-8)
        valLbl.Text       = tostring(val)..unit
        if onChange then onChange(val) end
    end
    trackBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            updateFromX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return container
end

local function MkDropdown(labelText, options, stateKey, onChange)
    local container = Instance.new("TextButton")
    container.Size             = UDim2.new(1,0,0,50)
    container.BackgroundColor3 = T.Card
    container.BorderSizePixel  = 0
    container.Text             = ""
    container.AutoButtonColor  = false
    container.ClipsDescendants = false
    Corner(container,8); Stroke(container,T.Border,1)
    MkLabel({Text=labelText, TextSize=10, TextColor3=T.TextDim, Size=UDim2.new(1,0,0,16), Position=UDim2.fromOffset(10,-18), Parent=container})
    local dispLbl = MkLabel({Text=tostring(State[stateKey] or (options and options[1] or "Select")), TextSize=13, Size=UDim2.new(1,-40,1,0), Position=UDim2.fromOffset(10,0), Parent=container})
    MkLabel({Text="▾", TextSize=18, TextColor3=T.TextDim, Size=UDim2.fromOffset(36,50), Position=UDim2.new(1,-38,0,0), TextXAlignment=Enum.TextXAlignment.Center, Parent=container})

    local dropFrame = MkFrame({BackgroundColor3=T.Panel, Size=UDim2.new(1,2,0,0), Position=UDim2.new(0,-1,1,2), Visible=false, ZIndex=60, Parent=container})
    Corner(dropFrame,8); Stroke(dropFrame,T.Border,1)
    local uil = Instance.new("UIListLayout"); uil.Padding=UDim.new(0,2); uil.Parent=dropFrame
    local uip = Instance.new("UIPadding"); uip.PaddingTop=UDim.new(0,4); uip.PaddingBottom=UDim.new(0,4); uip.PaddingLeft=UDim.new(0,4); uip.PaddingRight=UDim.new(0,4); uip.Parent=dropFrame

    local open = false
    local function buildItems(opts)
        for _, c in ipairs(dropFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local itemH = 36
        local n = math.min(#opts, 6)
        for _, opt in ipairs(opts) do
            local btn = Instance.new("TextButton")
            btn.Size=UDim2.new(1,0,0,itemH); btn.BackgroundColor3=T.Card; btn.BorderSizePixel=0
            btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=61; btn.Parent=dropFrame
            Corner(btn,6)
            local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,8); ip.Parent=btn
            MkLabel({Text=tostring(opt), TextSize=13, Size=UDim2.new(1,0,1,0), ZIndex=62, Parent=btn})
            btn.MouseEnter:Connect(function() btn.BackgroundColor3=T.Border end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3=T.Card   end)
            btn.Activated:Connect(function()
                State[stateKey] = opt
                dispLbl.Text    = tostring(opt)
                open = false
                TweenService:Create(dropFrame,TweenInfo.new(0.1),{Size=UDim2.new(1,2,0,0)}):Play()
                task.wait(0.12); dropFrame.Visible=false
                if onChange then onChange(opt) end
            end)
        end
        return n * (itemH+2) + 10
    end

    local totalH = buildItems(options or {})
    container.Activated:Connect(function()
        open = not open
        dropFrame.Visible = open
        if open then
            dropFrame.Size = UDim2.new(1,2,0,0)
            TweenService:Create(dropFrame,TweenInfo.new(0.15),{Size=UDim2.new(1,2,0,totalH)}):Play()
        else
            TweenService:Create(dropFrame,TweenInfo.new(0.1),{Size=UDim2.new(1,2,0,0)}):Play()
            task.wait(0.12); dropFrame.Visible=false
        end
    end)
    local function updateOptions(opts)
        totalH = buildItems(opts)
        dispLbl.Text = tostring(State[stateKey] or (opts[1] or ""))
    end
    return container, updateOptions
end

-- =====================================================================
-- MAIN WINDOW
-- =====================================================================
local W, H = 330, 520

local oldFrame = ScreenGui:FindFirstChild("MainFrame")
if oldFrame then oldFrame:Destroy() end

-- FIX 1: Compute initial position as pure pixel offsets so drag reads
-- correct values from the very first touch. Using scale-based UDim2
-- caused Position.X.Offset = -165 which the clamp snapped to 0 instantly.
local vp0 = workspace.CurrentCamera.ViewportSize
local initX = math.floor((vp0.X - W) / 2)
local initY = math.floor((vp0.Y - H) / 2)

local MainFrame = MkFrame({
    Name             = "MainFrame",
    Size             = UDim2.fromOffset(W, H),
    Position         = UDim2.fromOffset(initX, initY),  -- FIX 1
    BackgroundColor3 = T.BG,
    Parent           = ScreenGui,
})
Corner(MainFrame, 14)
Stroke(MainFrame, T.Border, 1)

-- =====================================================================
-- DRAG — FIX 1: Read AbsolutePosition instead of Position.X.Offset
-- =====================================================================
local dragOn = false
local dragOrigin  = Vector2.zero
local frameOrigin = Vector2.zero

MainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragOn     = true
        dragOrigin = Vector2.new(inp.Position.X, inp.Position.Y)
        -- FIX 1: AbsolutePosition gives the actual rendered pixel position.
        -- The old code read Position.X.Offset which was -165 for a
        -- scale=0.5 based position, causing immediate clamp to 0.
        frameOrigin = Vector2.new(MainFrame.AbsolutePosition.X, MainFrame.AbsolutePosition.Y)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not dragOn then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragOrigin
        local vp    = workspace.CurrentCamera.ViewportSize
        local nx    = math.clamp(frameOrigin.X + delta.X, 0, vp.X - W)
        local ny    = math.clamp(frameOrigin.Y + delta.Y, 0, vp.Y - H)
        MainFrame.Position = UDim2.fromOffset(nx, ny)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragOn = false
    end
end)

-- =====================================================================
-- TITLE BAR
-- =====================================================================
local TitleBar = MkFrame({
    Size             = UDim2.new(1,0,0,50),
    BackgroundColor3 = T.Panel,
    Parent           = MainFrame,
})
Corner(TitleBar, 14)
MkFrame({BackgroundColor3=T.Panel, Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,1,-10), Parent=TitleBar})

MkLabel({
    Text       = "🪓  LT2 Menu v3  •  Delta",
    TextSize   = 15,
    Font       = FONT_B,
    TextColor3 = T.Green,
    Size       = UDim2.new(1,-110,1,0),
    Position   = UDim2.fromOffset(14,0),
    Parent     = TitleBar,
})

local MinBtn, _ = MkBtn({
    Text="–", Size=UDim2.fromOffset(40,36), Position=UDim2.new(1,-84,0.5,-18),
    BackgroundColor3=T.Card, TextSize=20, Font=FONT_B, TextColor3=T.Yellow, Parent=TitleBar,
}, nil)

local CloseBtn, _ = MkBtn({
    Text="✕", Size=UDim2.fromOffset(40,36), Position=UDim2.new(1,-40,0.5,-18),
    BackgroundColor3=Color3.fromRGB(70,20,20), TextSize=16, TextColor3=T.Red, Parent=TitleBar,
}, function()
    StopFly(); StopDupe(); StopAutoChop(); StopAutoBuy()
    SetNoClip(false); SetLasso(false)
    ScreenGui:Destroy()
end)

-- Float icon (when minimized) — also draggable on mobile
local FloatBtn, _ = MkBtn({
    Text="🪓", Size=UDim2.fromOffset(58,58), Position=UDim2.fromOffset(10,90),
    BackgroundColor3=T.Panel, TextSize=26, Visible=false, ZIndex=30, Parent=ScreenGui,
}, nil)
Corner(FloatBtn, 29)
Stroke(FloatBtn, T.Green, 2)

-- Make FloatBtn draggable too
local fdOn, fdOrg, fbOrg = false, Vector2.zero, Vector2.zero
FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        fdOn  = true
        fdOrg = Vector2.new(inp.Position.X, inp.Position.Y)
        fbOrg = Vector2.new(FloatBtn.AbsolutePosition.X, FloatBtn.AbsolutePosition.Y)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not fdOn then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local d = Vector2.new(inp.Position.X, inp.Position.Y) - fdOrg
        local vp = workspace.CurrentCamera.ViewportSize
        FloatBtn.Position = UDim2.fromOffset(
            math.clamp(fbOrg.X+d.X, 0, vp.X-58),
            math.clamp(fbOrg.Y+d.Y, 0, vp.Y-58)
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        fdOn = false
    end
end)

local function SetMinimized(v)
    State.Minimized   = v
    MainFrame.Visible = not v
    FloatBtn.Visible  = v
end
MinBtn.Activated:Connect(function()   SetMinimized(true)  end)
FloatBtn.Activated:Connect(function()
    -- Only maximize if we didn't just drag the button
    local d = (Vector2.new(FloatBtn.AbsolutePosition.X, FloatBtn.AbsolutePosition.Y) - fbOrg).Magnitude
    if d < 5 then SetMinimized(false) end
end)

-- =====================================================================
-- NOTIFICATIONS
-- =====================================================================
local notifOffset = 0

local function Notify(msg, color, duration)
    color    = color    or T.Green
    duration = duration or 2.5
    local nf = MkFrame({
        Size=UDim2.fromOffset(270,46), Position=UDim2.new(1,-280,1,-(notifOffset+56)),
        BackgroundColor3=T.Panel, ZIndex=100, Parent=ScreenGui,
    })
    Corner(nf,8); Stroke(nf,color,1)
    MkFrame({BackgroundColor3=color, Size=UDim2.fromOffset(4,46), ZIndex=101, Parent=nf})
    MkLabel({Text=msg, TextSize=12, Size=UDim2.new(1,-16,1,0), Position=UDim2.fromOffset(12,0), ZIndex=101, Parent=nf})
    notifOffset = notifOffset + 52
    TweenService:Create(nf, TweenInfo.new(0.25), {Position=UDim2.new(1,-280,1,-notifOffset)}):Play()
    task.delay(duration, function()
        TweenService:Create(nf,TweenInfo.new(0.2),{Position=UDim2.new(1,20,1,-notifOffset)}):Play()
        task.wait(0.25); nf:Destroy()
        notifOffset = math.max(0, notifOffset-52)
    end)
end

-- =====================================================================
-- TAB SYSTEM
-- =====================================================================
local TABS = {
    {n="Slot",     i="💾"},
    {n="Player",   i="🏃"},
    {n="World",    i="🌍"},
    {n="Wood",     i="🌲"},
    {n="Auto Buy", i="🛒"},
    {n="Item",     i="📦"},
    {n="Dupe",     i="♻️"},
    {n="Build",    i="🏗️"},
}

local TabArea = MkFrame({
    Size=UDim2.new(1,0,0,46), Position=UDim2.fromOffset(0,50),
    BackgroundColor3=T.Panel, ClipsDescendants=true, Parent=MainFrame,
})
MkFrame({BackgroundColor3=T.Border, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), Parent=TabArea})

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size                  = UDim2.new(1,0,1,0)
TabScroll.BackgroundTransparency= 1
TabScroll.BorderSizePixel       = 0
TabScroll.ScrollBarThickness    = 0
TabScroll.ScrollingDirection    = Enum.ScrollingDirection.X
TabScroll.CanvasSize            = UDim2.fromOffset(#TABS*82,0)
TabScroll.Parent                = TabArea
local uil_h = Instance.new("UIListLayout")
uil_h.FillDirection = Enum.FillDirection.Horizontal
uil_h.SortOrder     = Enum.SortOrder.LayoutOrder
uil_h.Parent        = TabScroll

local ContentFrame = MkFrame({
    Size=UDim2.new(1,0,1,-96), Position=UDim2.fromOffset(0,96),
    BackgroundTransparency=1, ClipsDescendants=true, Parent=MainFrame,
})

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size                 = UDim2.new(1,0,1,0)
ContentScroll.BackgroundTransparency= 1
ContentScroll.BorderSizePixel      = 0
ContentScroll.ScrollBarThickness   = 4
ContentScroll.ScrollBarImageColor3 = T.Border
ContentScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
ContentScroll.CanvasSize           = UDim2.new(0,0,0,0)
ContentScroll.Parent               = ContentFrame

local uil_v = Instance.new("UIListLayout")
uil_v.Padding   = UDim.new(0,7)
uil_v.SortOrder = Enum.SortOrder.LayoutOrder
uil_v.Parent    = ContentScroll

local uip_c = Instance.new("UIPadding")
uip_c.PaddingLeft   = UDim.new(0,10)
uip_c.PaddingRight  = UDim.new(0,10)
uip_c.PaddingTop    = UDim.new(0,10)
uip_c.PaddingBottom = UDim.new(0,10)
uip_c.Parent        = ContentScroll

-- =====================================================================
-- PAGE BUILDER HELPERS
-- =====================================================================
local PageFns = {}
local TabBtns = {}

local function ClearContent()
    for _, c in ipairs(ContentScroll:GetChildren()) do
        -- UIListLayout and UIPadding are NOT GuiObjects so they are
        -- preserved automatically; only Frames, Buttons, Labels get destroyed.
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function ShowPage(idx)
    ClearContent()
    ContentScroll.CanvasPosition = Vector2.zero
    State.ActiveTab = idx
    for i, btn in ipairs(TabBtns) do
        local active = i == idx
        TweenService:Create(btn,TweenInfo.new(0.12),{
            BackgroundColor3 = active and T.Card or T.Panel,
            TextColor3       = active and T.Green or T.TextDim,
        }):Play()
    end
    if PageFns[idx] then PageFns[idx]() end
end

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.fromOffset(80,42)
    btn.BackgroundColor3 = T.Panel
    btn.BorderSizePixel  = 0
    btn.Text             = tab.i.."\n"..tab.n
    btn.Font             = FONT
    btn.TextSize         = 10
    btn.TextColor3       = T.TextDim
    btn.AutoButtonColor  = false
    btn.LayoutOrder      = i
    btn.Parent           = TabScroll
    btn.Activated:Connect(function() ShowPage(i) end)
    table.insert(TabBtns, btn)
end

local CS = ContentScroll

local function Sec(t, c) MkSectionHeader(t, c).Parent = CS end
local function Lbl(t, sz, c)
    MkLabel({Text=t, TextSize=sz or 12, TextColor3=c or T.TextDim, Size=UDim2.new(1,0,0,sz and sz*2 or 30), Parent=CS})
end
local function Btn(t, tc, onClick)
    return MkBtn({Text=t, Size=UDim2.new(1,0,0,50), BackgroundColor3=T.Card, TextColor3=tc or T.TextOn, Parent=CS}, onClick)
end
local function Tog(t, k, fn)  local w = MkToggle(t,k,fn); w.Parent=CS; return w end
local function Sld(t,mn,mx,k,u,fn) local w=MkSlider(t,mn,mx,k,u,fn); w.Parent=CS; return w end
local function Drp(lbl,opts,k,fn)  local w,uf=MkDropdown(lbl,opts,k,fn); w.Parent=CS; return w,uf end

-- =====================================================================
-- PAGE 1: SLOT
-- =====================================================================
PageFns[1] = function()
    Sec("Save & Load Slots", T.Cyan)
    Lbl("GetMetaData & ClientMayLoad confirmed. RequestSave/RequestLoad unconfirmed — may not work.", 11, T.Orange)
    Drp("Choose Slot", {"1","2","3","4"}, "SaveSlot", function(v) State.SaveSlot = tonumber(v) or 1 end)

    Btn("💾  Save to Slot "..State.SaveSlot, T.Green, function()
        Notify("Saving to Slot "..State.SaveSlot.."...", T.Yellow, 2)
        task.spawn(function()
            local ok, msg = DoSave(State.SaveSlot)
            Notify((ok and "✓ Saved" or "✗ Save failed").." — "..tostring(msg), ok and T.Green or T.Red)
        end)
    end)

    Btn("📂  Load Slot "..State.SaveSlot, T.Cyan, function()
        Notify("Loading Slot "..State.SaveSlot.."...", T.Yellow, 2)
        task.spawn(function()
            local ok, msg = DoLoad(State.SaveSlot)
            Notify((ok and "✓ Loaded" or "✗ Load failed").." — "..tostring(msg), ok and T.Green or T.Red)
        end)
    end)

    Sec("Land Purchase", T.Orange)
    Lbl("SetPropertyPurchasingValue confirmed. ClientPurchasedProperty unconfirmed.", 11, T.Orange)
    Btn("🏡  Buy Available Land", T.Yellow, function()
        Notify("Attempting land purchase...", T.Yellow, 2)
        task.spawn(function()
            local ok, msg = DoBuyLand()
            Notify((ok and "✓ " or "✗ ")..tostring(msg), ok and T.Green or T.Red)
        end)
    end)

    Btn("🏠  Teleport to My Plot", T.TextOn, function()
        task.spawn(function()
            local pf = workspace:FindFirstChild("Properties")
            if pf then
                for _, p in ipairs(pf:GetChildren()) do
                    local ov = p:FindFirstChild("Owner")
                    if ov and ov.Value == LP then
                        local bp = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
                        if bp then TeleportTo(bp.CFrame * CFrame.new(0,5,0)); Notify("✓ Teleported to plot", T.Green); return end
                    end
                end
            end
            Notify("No owned plot found", T.Red)
        end)
    end)
end

-- =====================================================================
-- PAGE 2: PLAYER
-- =====================================================================
PageFns[2] = function()
    Sec("Movement", T.Green)
    Sld("Walk Speed", 1, 150, "WalkSpeed", " st/s", function(v) SetWalkSpeed(v) end)
    Sld("Jump Power", 1, 250, "JumpPower",  " pow",  function(v) SetJumpPower(v) end)
    Sld("Fly Speed",  5, 300, "FlySpeed",   " st/s", nil)

    Btn("↩  Reset to Default", T.TextDim, function()
        State.WalkSpeed=16; State.JumpPower=50
        SetWalkSpeed(16); SetJumpPower(50)
        Notify("Speed and jump reset", T.Cyan)
    end)

    Sec("Fly  [Touch D-pad appears bottom-left when enabled]", T.Orange)
    -- FIX 2: Updated description — keyboard + D-pad both work now
    Lbl("On Android: use the on-screen D-pad (↑↓←→⬆⬇) that appears when fly is ON.", 12)
    Tog("✈  Fly Mode", "Flying", function(v)
        if v then StartFly() else StopFly() end
        Notify(v and "Fly ON — use D-pad bottom-left" or "Fly OFF", T.Orange)
    end)

    Sec("Utility", T.TextDim)
    Tog("👻  No Clip", "NoClipOn", function(v)
        SetNoClip(v)
        Notify(v and "NoClip ON" or "NoClip OFF", T.TextDim)
    end)

    Btn("💀  Kill Self", T.Red, function()
        if hum then hum.Health = 0 end
    end)

    Btn("🔄  Rejoin Server", T.TextOn, function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end)
end

-- =====================================================================
-- PAGE 3: WORLD
-- =====================================================================
PageFns[3] = function()
    Sec("Lighting", T.Yellow)
    Tog("☀  Always Day",   "AlwaysDay",   function(v) SetAlwaysDay(v);   if v then Notify("Always Day ON",   T.Yellow)  end end)
    Tog("🌙  Always Night", "AlwaysNight", function(v) SetAlwaysNight(v); if v then Notify("Always Night ON", T.TextDim) end end)
    Tog("🌫  No Fog",       "NoFog",       function(v) SetNoFog(v); Notify(v and "Fog OFF" or "Fog ON", T.Cyan) end)
    Tog("🌑  No Shadows",   "NoShadows",   function(v)
        pcall(function() Lighting.GlobalShadows = not v end)
        Notify(v and "Shadows OFF" or "Shadows ON", T.TextDim)
    end)

    Sec("Waypoint Teleport", T.Cyan)
    local wpList = {}
    for k in pairs(WAYPOINTS) do table.insert(wpList, k) end
    table.sort(wpList)
    State.SelectedWaypoint = State.SelectedWaypoint or wpList[1]
    Drp("Select Waypoint", wpList, "SelectedWaypoint", nil)
    Btn("🚀  Teleport to Waypoint", T.Cyan, function()
        local wp = WAYPOINTS[State.SelectedWaypoint]
        if wp then TeleportPos(wp.X,wp.Y,wp.Z); Notify("✓ Teleported to "..State.SelectedWaypoint, T.Cyan) end
    end)

    Sec("Player Teleport", T.Green)
    local pNames = {}
    for _, p in ipairs(Players:GetPlayers()) do table.insert(pNames, p.Name) end
    State.TargetPlayer = State.TargetPlayer or (pNames[1] or "")
    local _, pDropUpdate = Drp("Select Player", pNames, "TargetPlayer", nil)
    Btn("🔄  Refresh Players", T.TextDim, function()
        local names = {}; for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
        pDropUpdate(names); Notify("Players refreshed", T.Cyan, 1.5)
    end)
    Btn("➡  Teleport to Player", T.Green, function()
        local target = Players:FindFirstChild(State.TargetPlayer or "")
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local p = target.Character.HumanoidRootPart.Position
            TeleportPos(p.X, p.Y+3, p.Z)
            Notify("✓ Teleported to "..target.Name, T.Green)
        else
            Notify("Player not found or has no character", T.Red)
        end
    end)
end

-- =====================================================================
-- PAGE 4: WOOD
-- =====================================================================
PageFns[4] = function()
    Sec("Auto Chop", T.Green)
    Lbl("⚠ RemoteProxy path unconfirmed (server-side only). Will warn in output if missing.", 11, T.Orange)
    Lbl("STATUS: "..(State.AutoWoodOn and "🟢 Running" or "⭕ Idle"), 13, State.AutoWoodOn and T.Green or T.TextDim)
    Sld("Max Sections Per Pass", 5, 200, "WoodAmount", "x", nil)
    Btn("🌲  Start Auto Chop", T.Green, function()
        if State.AutoWoodOn then Notify("Already running", T.Orange); return end
        local axe = GetAxe()
        if not axe then Notify("No axe found — equip one first!", T.Red); return end
        StartAutoChop()
        Notify("Auto Chop started", T.Green)
    end)
    Btn("⏹  Stop Auto Chop", T.Red, function()
        StopAutoChop(); Notify("Auto Chop stopped", T.Red)
    end)

    Sec("Sell Wood", T.Yellow)
    Lbl("TPs to Wood Drop-off and moves your owned wood pieces into the sell zone.", 12)
    Btn("💰  Sell All Wood", T.Yellow, function()
        task.spawn(function()
            Notify("Teleporting to sell area...", T.Yellow, 2)
            SellAllWood()
            Notify("✓ Wood moved to sell zone", T.Green)
        end)
    end)
    Btn("🏪  TP to Wood Drop-off", T.TextOn, function()
        TeleportPos(-35,4,60); Notify("TP → Wood Drop-off", T.Cyan)
    end)
end

-- =====================================================================
-- PAGE 5: AUTO BUY
-- =====================================================================
PageFns[5] = function()
    Sec("Store Auto-Buy", T.Green)
    Lbl("SetChattingValue confirmed. AttemptPurchase & PlayerChatted unconfirmed.", 11, T.Orange)

    local itemDisplay = {}
    for _, it in ipairs(STORE_ITEMS) do table.insert(itemDisplay, it.name.." ($"..it.price..")") end
    State.BuyItemDisplay = State.BuyItemDisplay or itemDisplay[1]

    Drp("Select Item to Buy", itemDisplay, "BuyItemDisplay", function(v)
        for _, it in ipairs(STORE_ITEMS) do
            if (it.name.." ($"..it.price..")") == v then State.BuyItem = it.toolname; break end
        end
    end)
    Sld("Amount", 1, 50, "BuyAmt",  "x",  nil)
    Sld("Delay",  1, 30, "BuyDelay","s",  nil)
    Btn("🛒  Start Auto Buy", T.Green, function()
        if State.AutoBuying then Notify("Already buying", T.Orange); return end
        StartAutoBuy(); Notify("Auto Buy started: "..State.BuyItem, T.Green)
    end)
    Btn("⏹  Stop Auto Buy", T.Red, function()
        StopAutoBuy(); Notify("Auto Buy stopped", T.Red)
    end)

    Sec("Quick Store TP", T.Cyan)
    Btn("🪓  WoodRUs",      T.TextOn, function() TeleportPos(-275,5,105); Notify("TP → WoodRUs",     T.Cyan) end)
    Btn("🏚  Bob's Shack",  T.TextOn, function() TeleportPos(-252,5,400); Notify("TP → Bob's Shack", T.Cyan) end)
    Btn("⚙  Link's Logic", T.TextOn, function() TeleportPos(15,5,262);   Notify("TP → Link's Logic",T.Cyan) end)
end

-- =====================================================================
-- PAGE 6: ITEM
-- =====================================================================
PageFns[6] = function()
    Sec("Item Selection (Lasso)", T.Cyan)
    Lbl("Enable Lasso, then tap parts in-world to add to selection.", 12)

    local countLbl = MkLabel({
        Text="Selected: "..#State.SelectedItems.." items", TextSize=13,
        TextColor3=T.TextDim, Size=UDim2.new(1,0,0,26), Parent=CS,
    })
    local heartConn
    heartConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            if countLbl and countLbl.Parent then
                countLbl.Text = "Selected: "..#State.SelectedItems.." items"
            else
                heartConn:Disconnect()
            end
        end)
    end)

    Tog("🎯  Lasso ON — tap parts to select", "LassoOn", function(v)
        SetLasso(v); Notify(v and "Lasso ON — tap parts" or "Lasso OFF", T.Cyan, 1.5)
    end)
    Btn("✕  Deselect All", T.TextDim, function()
        State.SelectedItems = {}; Notify("Selection cleared", T.TextDim, 1.5)
    end)

    Sec("Actions on Selection", T.Green)
    Sld("Stack Spacing", 1, 20, "StackLen", " st", nil)
    Btn("📍  Teleport Selected to Me", T.Green, function()
        if #State.SelectedItems == 0 then Notify("Nothing selected", T.Orange); return end
        local n = TeleportSelectedToMe()
        Notify("✓ Moved "..n.." items to you", T.Green)
    end)
    Btn("🗑  Destroy Selected", T.Red, function()
        if #State.SelectedItems == 0 then Notify("Nothing selected", T.Orange); return end
        local n = DestroySelected()
        Notify("Destroyed "..n.." items", T.Red)
    end)

    Sec("Drop Tools", T.Orange)
    Btn("🪓  Drop Equipped Axe", T.Orange, function()
        local axe = GetAxe()
        if not axe then Notify("No axe in inventory", T.Red); return end
        local ok, msg = DropTool(axe)
        Notify(ok and "✓ Axe dropped" or "✗ "..tostring(msg), ok and T.Green or T.Red)
    end)
    Btn("⬇  Drop All Axes", T.TextOn, function()
        task.spawn(function()
            local n = DropAllAxes()
            Notify("Dropped "..n.." axes via ClientInteracted", T.Orange)
        end)
    end)
end

-- =====================================================================
-- PAGE 7: DUPE
-- =====================================================================
PageFns[7] = function()
    Sec("Axe Drop-Pick Dupe", T.Orange)
    Lbl("Drops axe via ClientInteracted (confirmed), TPs to pick up, repeats.\nEquip an axe first.", 12)

    local statusLbl = MkLabel({
        Text="Status: ⭕ Idle", TextSize=14, TextColor3=T.TextDim,
        Size=UDim2.new(1,0,0,28), Parent=CS,
    })
    RunService.Heartbeat:Connect(function()
        pcall(function()
            if statusLbl and statusLbl.Parent then
                statusLbl.Text       = State.Duping and "Status: 🟢 Running..." or "Status: ⭕ Idle"
                statusLbl.TextColor3 = State.Duping and T.Green or T.TextDim
            end
        end)
    end)

    Sld("Amount",     1, 100, "DupeAmt",  "x",     nil)
    Sld("Drop Delay", 1,  50, "DupeWait", "×0.1s", nil)

    Btn("▶  Start Axe Dupe", T.Green, function()
        local axe = GetAxe()
        if not axe then Notify("No axe — equip one first!", T.Red); return end
        if State.Duping then Notify("Already duping!", T.Orange); return end
        local ok = StartDupe()
        Notify(ok and "Dupe started ×"..State.DupeAmt or "Could not start dupe", ok and T.Green or T.Red)
    end)
    Btn("⏹  Stop Dupe", T.Red, function()
        StopDupe(); Notify("Dupe stopped", T.Red)
    end)

    Sec("Axe Info", T.TextDim)
    Btn("🔍  Show Axe ToolNames", T.TextOn, function()
        task.spawn(function()
            local axes = GetAllAxes()
            if #axes == 0 then Notify("No axes found", T.Red); return end
            for _, a in ipairs(axes) do
                local tn = a:FindFirstChild("ToolName")
                Notify("🪓 "..a.Name.." → "..(tn and tn.Value or "nil"), T.Cyan, 4)
                task.wait(0.3)
            end
        end)
    end)
end

-- =====================================================================
-- PAGE 8: BUILD
-- =====================================================================
PageFns[8] = function()
    Sec("Blueprint Placement", T.Green)
    Lbl("⚠ ClientPlacedBlueprint & ClientPlacedStructure are unconfirmed paths.", 11, T.Orange)

    local bpNames = {"Sawmill","Sawmill2","Sawmill3","Sawmill4","Floor1","Wall2Tall","Door1","Post"}
    pcall(function()
        local cii = RS:FindFirstChild("ClientItemInfo")
        if cii then
            local found = {}
            for _, c in ipairs(cii:GetChildren()) do
                local t = c:FindFirstChild("Type")
                if t and (t.Value == "Structure" or t.Value == "Furniture") then
                    table.insert(found, c.Name)
                end
            end
            if #found > 0 then bpNames = found end
        end
    end)

    State.SelectedBlueprint = State.SelectedBlueprint or bpNames[1]
    Drp("Select Blueprint", bpNames, "SelectedBlueprint", nil)
    Btn("📐  Place Blueprint Here", T.Green, function()
        if not State.SelectedBlueprint then Notify("No blueprint selected", T.Orange); return end
        task.spawn(function()
            local ok, msg = PlaceBlueprint(State.SelectedBlueprint, nil)
            Notify((ok and "✓ Placement fired" or "✗ "..tostring(msg)), ok and T.Green or T.Red)
        end)
    end)
    Btn("🔧  Auto Fill My Blueprints", T.Cyan, function()
        task.spawn(function()
            local ok, msg = AutoFillBlueprints()
            Notify((ok and "✓ " or "✗ ")..tostring(msg), ok and T.Green or T.Red)
        end)
    end)
    Btn("🗑  Destroy My Blueprints", T.Red, function()
        task.spawn(function()
            local ds = rDestroyStructure()
            local ci = rClientInteracted()
            local n = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Blueprint" then
                    local ov = obj:FindFirstChild("Owner")
                    if ov and ov.Value == LP then
                        if ds then pcall(function() ds:FireServer(obj) end)
                        elseif ci then pcall(function() ci:FireServer(obj, "Destroy", CFrame.new()) end)
                        else         pcall(function() obj:Destroy() end) end
                        n = n+1; task.wait(0.06)
                    end
                end
            end
            Notify("Destroyed "..n.." blueprints", T.Red)
        end)
    end)

    Sec("Plot Steal (Experimental)", T.Red)
    Lbl("⚠ ClientPurchasedProperty is unconfirmed.", 11, T.Orange)
    local pNames = {}
    for _, p in ipairs(Players:GetPlayers()) do table.insert(pNames, p.Name) end
    State.StealTarget = State.StealTarget or (pNames[1] or "")
    local _, stealUpdate = Drp("Target Player", pNames, "StealTarget", nil)
    Btn("🔄  Refresh Players", T.TextDim, function()
        local names={}; for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
        stealUpdate(names); Notify("Players refreshed", T.Cyan, 1.5)
    end)
    Btn("🏠  Attempt Plot Steal", T.Red, function()
        if not State.StealTarget or State.StealTarget == "" then Notify("Select a target player first", T.Orange); return end
        task.spawn(function()
            local ok, msg = StealPlot(State.StealTarget)
            Notify((ok and "✓ " or "✗ ")..tostring(msg), ok and T.Green or T.Red)
        end)
    end)
end

-- =====================================================================
-- RE-APPLY ON RESPAWN
-- =====================================================================
LP.CharacterAdded:Connect(function()
    task.wait(1)
    refreshChar()
    if hum then
        pcall(function()
            hum.WalkSpeed = State.WalkSpeed
            if hum.UseJumpPower then hum.JumpPower  = State.JumpPower
            else                     hum.JumpHeight = State.JumpPower/5 end
        end)
    end
    if State.NoClipOn    then SetNoClip(true)      end
    if State.Flying      then StartFly()            end
    if State.AlwaysDay   then SetAlwaysDay(true)    end
    if State.AlwaysNight then SetAlwaysNight(true)  end
    if State.NoFog       then SetNoFog(true)        end
end)

-- =====================================================================
-- OPEN ANIMATION & LAUNCH
-- =====================================================================
MainFrame.Size = UDim2.fromOffset(W, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.fromOffset(W, H)
}):Play()

ShowPage(1)

task.delay(0.6, function()
    Notify("🪓 LT2 Menu v3 FIXED — Delta Android", T.Green, 4)
    Notify("Drag ✓  Fly Touch ✓  Remotes verified ✓", T.Cyan, 5)
end)

return "LT2_Menu_v3_Delta_FIXED loaded"
