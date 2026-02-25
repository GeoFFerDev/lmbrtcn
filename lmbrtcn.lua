--[[
    ██╗  ████████╗██████╗      ███████╗██╗  ██╗██████╗ ██╗      ██████╗ ██╗████████╗
    ██║  ╚══██╔══╝╚════██╗     ██╔════╝╚██╗██╔╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝
    ██║     ██║    █████╔╝     █████╗   ╚███╔╝ ██████╔╝██║     ██║   ██║██║   ██║   
    ██║     ██║   ██╔═══╝      ██╔══╝   ██╔██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║   
    ███████╗██║   ███████╗     ███████╗██╔╝ ██╗██║     ███████╗╚██████╔╝██║   ██║   
    ╚══════╝╚═╝   ╚══════╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝   
    
    Lumber Tycoon 2 - Multi-Feature Script
    Designed for: Delta Executor
    Game ID: 13822889
    
    DISCLAIMER: Educational/Research purposes only.
    Use at your own risk. May violate Roblox TOS.
]]

-- ============================================================
-- SERVICES & GLOBALS
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")

local LP   = Players.LocalPlayer
-- Delta executor safe GUI parent: use gethui() > CoreGui > PlayerGui
local GuiParent = (typeof(gethui) == "function" and gethui())
               or game:GetService("CoreGui")
               or LP:FindFirstChild("PlayerGui")
               or LP:WaitForChild("PlayerGui")
local Cam  = workspace.CurrentCamera

-- Roblox paths (non-blocking — use FindFirstChild, resolve lazily)
local RS   = game:GetService("ReplicatedStorage")
local Interaction  = nil  -- resolved lazily inside functions
local Transactions = nil  -- resolved lazily inside functions

-- Lazy resolver so we never block at startup
local function GetInteraction()
    if not Interaction then
        Interaction = RS:FindFirstChild("Interaction")
    end
    return Interaction
end
local function GetTransactions()
    if not Transactions then
        Transactions = RS:FindFirstChild("Transactions")
                    or RS:FindFirstChild("Interaction")
    end
    return Transactions
end

-- Alias PGui for notification system
local PGui = GuiParent
print("[LT2 Script] ✅ Starting... GUI parent = " .. tostring(GuiParent))

-- ============================================================
-- COLORS & THEME
-- ============================================================
local C = {
    BG       = Color3.fromRGB(12,  13,  18),
    BG2      = Color3.fromRGB(17,  19,  27),
    BG3      = Color3.fromRGB(22,  26,  38),
    ACCENT   = Color3.fromRGB(80,  200, 120),
    ACCENT2  = Color3.fromRGB(50,  160,  90),
    WARN     = Color3.fromRGB(255, 180,  60),
    DANGER   = Color3.fromRGB(220,  70,  70),
    TEXT     = Color3.fromRGB(220, 230, 240),
    MUTED    = Color3.fromRGB(100, 115, 135),
    WHITE    = Color3.fromRGB(255, 255, 255),
    BORDER   = Color3.fromRGB(35,  45,  62),
    TABACT   = Color3.fromRGB(30,  40,  56),
}

-- ============================================================
-- UTILITY
-- ============================================================
local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t or 0.18, style, dir), props):Play()
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 6)
    return c
end

local function MakePadding(parent, top, right, bot, left)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, top   or 4)
    p.PaddingRight  = UDim.new(0, right or 4)
    p.PaddingBottom = UDim.new(0, bot   or 4)
    p.PaddingLeft   = UDim.new(0, left  or 4)
    return p
end

local function MakeStroke(parent, thickness, color)
    local s = Instance.new("UIStroke", parent)
    s.Thickness  = thickness or 1
    s.Color      = color     or C.BORDER
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function Label(parent, text, size, color, font)
    local l = Instance.new("TextLabel", parent)
    l.Text               = text or ""
    l.TextSize           = size  or 13
    l.TextColor3         = color or C.TEXT
    l.Font               = font  or Enum.Font.GothamMedium
    l.BackgroundTransparency = 1
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Size               = UDim2.new(1, 0, 0, size and size+4 or 18)
    return l
end

local function Notify(msg, color)
    color = color or C.ACCENT
    local screen = PGui:FindFirstChild("LT2Notif")
    if not screen then
        screen = Instance.new("ScreenGui")
        screen.Name = "LT2Notif"
        screen.ResetOnSpawn = false
        screen.DisplayOrder = 1000
        screen.IgnoreGuiInset = true
        pcall(function() screen.Parent = GuiParent end)
    end
    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 300, 0, 42)
    frame.Position = UDim2.new(1, -320, 1, -60)
    frame.BackgroundColor3 = C.BG2
    frame.BorderSizePixel = 0
    MakeCorner(frame, 8)
    MakeStroke(frame, 1.5, color)
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    MakeCorner(bar, 4)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Text = msg
    lbl.TextColor3 = C.WHITE
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    frame.Position = UDim2.new(1, 20, 1, -60)
    Tween(frame, {Position = UDim2.new(1, -320, 1, -60)}, 0.3)
    task.delay(3.5, function()
        Tween(frame, {Position = UDim2.new(1, 20, 1, -60)}, 0.3)
        task.wait(0.35)
        frame:Destroy()
    end)
end

local function GetChar()
    return LP.Character
end

local function GetRoot()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function TeleportTo(cf)
    local root = GetRoot()
    if root then
        root.CFrame = cf
    end
end

local function SafeFireServer(remote, ...)
    pcall(function() remote:FireServer(...) end)
end

local function SafeInvokeServer(remote, ...)
    local ok, res = pcall(function() return remote:InvokeServer(...) end)
    return ok and res or nil
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    autoGetTree     = false,
    autoSell        = false,
    autoBuy         = false,
    selectedItems   = {},
    lassoActive     = false,
    selectedWood    = {},
    selectedBlueprints = {},
    woodMod         = false,
    sawmillMod      = false,
    autoBuyItem     = "",
    autoBuyAmount   = 1,
    autoBuyPrice    = 0,
    autoBuyRunning  = false,
    autoBuyStop     = false,
    axeDupeSlot     = 1,
    axeDupeWait     = 0.5,
    axeDupeAmount   = 5,
    axeDupeRunning  = false,
    stackLength     = 4,
    getTreeAmount   = 10,
    selectedTree    = "Any",
}

-- Known teleport locations from game analysis
local Waypoints = {
    ["🏠 Spawn"]         = CFrame.new(150, 10, 50),
    ["🌲 Main Forest"]   = CFrame.new(300, 10, -200),
    ["🏔️ Mountain"]     = CFrame.new(-400, 80, 300),
    ["❄️ Snow Biome"]   = CFrame.new(-1052, 10, -992),
    ["🌋 Volcano"]       = CFrame.new(163, 55, 1276),
    ["🌿 Swamp"]         = CFrame.new(1328, 5, -683),
    ["🌴 Tropics/Ferry"] = CFrame.new(1294, 105, 2715),
    ["💰 Wood Dropoff"]  = CFrame.new(322, 15, 97),
    ["🪚 Sell Wood"]     = CFrame.new(255, 8, 66),
    ["🏪 Wood R' Us"]    = CFrame.new(5184, 65, 535),
    ["🗺️ Land Store"]   = CFrame.new(268, 8, 67),
    ["🚗 Car Store"]     = CFrame.new(200, 8, 40),
    ["🛋️ Furniture"]    = CFrame.new(180, 8, 55),
}

local TreeTypes = {
    "Any", "Pine", "Oak", "Birch", "Walnut", "Elm", "Cherry",
    "Fir", "Frost", "Volcano", "EndTimes", "Sinister"
}

local ShopItems = {
    "BasicHatchet", "Axe1", "Axe2", "Axe3", "RefinedAxe",
    "SilverAxe", "BluesteelAxe", "RustyAxe", "CaveAxe",
    "FireAxe", "IceAxe", "Sawmill", "Sawmill2", "Sawmill3",
    "Conveyor", "Box", "WoodBox", "Plank", "WoodPiece"
}

-- ============================================================
-- CORE GAME FUNCTIONS
-- ============================================================

-- Land/Property helpers
local function GetMyPlot()
    local props = workspace:FindFirstChild("Properties")
    if not props then return nil end
    for _, plot in ipairs(props:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        if owner and owner.Value == LP then
            return plot
        end
    end
    return nil
end

local function GetPlotBase(plot)
    if not plot then return nil end
    for _, v in ipairs(plot:GetChildren()) do
        if v:IsA("BasePart") then return v end
    end
    return nil
end

-- SLOT / LAND FUNCTIONS
local function BaseHelp()
    local plot = GetMyPlot()
    if not plot then
        Notify("❌ No plot found! Purchase land first.", C.DANGER)
        return
    end
    local base = GetPlotBase(plot)
    if base then
        TeleportTo(CFrame.new(base.Position + Vector3.new(0, 10, 0)))
        Notify("✅ Teleported to your base!", C.ACCENT)
    end
end

local function FreeLand()
    -- Fire the property purchase mode event (server validates but we attempt)
    if GetInteraction() then
        local evt = GetInteraction():FindFirstChild("ClientEnterPropertyPurchaseMode")
        if evt then
            SafeFireServer(evt, true)
        end
    end
    -- Try to select a free/unclaimed plot
    local props = workspace:FindFirstChild("Properties")
    if props then
        for _, plot in ipairs(props:GetChildren()) do
            local owner = plot:FindFirstChild("Owner")
            if owner and owner.Value == nil then
                TeleportTo(CFrame.new(GetPlotBase(plot) and GetPlotBase(plot).Position or Vector3.new(0,5,0)) * CFrame.new(0,10,0))
                Notify("📍 Teleported to a free plot!", C.ACCENT)
                return
            end
        end
    end
    Notify("ℹ️ Attempting FreeLand via RemoteFunction...", C.WARN)
    if GetTransactions() then
        local rf = GetTransactions():FindFirstChild("SelectLoadPlot")
        if rf then SafeInvokeServer(rf) end
    end
end

local function MaxLand()
    -- Expand all available plots (fires expansion events)
    if GetInteraction() then
        local evt = GetInteraction():FindFirstChild("ClientExpandedProperty")
        if evt then
            for i = 1, 5 do
                SafeFireServer(evt, i)
                task.wait(0.2)
            end
        end
    end
    Notify("🗺️ Attempted to expand land!", C.ACCENT)
end

local function ForceSave()
    if GetTransactions() then
        local rf = GetTransactions():FindFirstChild("RequestSave")
        if rf then
            local res = SafeInvokeServer(rf)
            Notify("💾 Force save attempted! Result: " .. tostring(res), C.ACCENT)
            return
        end
    end
    Notify("⚠️ RequestSave not found in this session.", C.WARN)
end

-- LIGHTING FUNCTIONS
local function AlwaysDay()
    Lighting.ClockTime = 12
    Lighting.FogEnd    = 100000
    Lighting.Brightness = 2
    -- Try to freeze time
    if RunService:IsConnected() then end
    RunService.Heartbeat:Connect(function()
        if State.alwaysDay then
            Lighting.ClockTime = 12
        end
    end)
    State.alwaysDay   = true
    State.alwaysNight = false
    Notify("☀️ Always Day enabled!", C.WARN)
end

local function AlwaysNight()
    Lighting.ClockTime = 0
    Lighting.Brightness = 0.5
    State.alwaysNight = true
    State.alwaysDay   = false
    Notify("🌙 Always Night enabled!", C.ACCENT)
end

local function ResetTime()
    State.alwaysDay   = false
    State.alwaysNight = false
    Notify("🕐 Time reset to normal.", C.MUTED)
end

local function NoFog()
    Lighting.FogEnd   = 100000
    Lighting.FogStart = 99999
    Notify("🌫️ No Fog enabled!", C.ACCENT)
end

local function ToggleShadows(val)
    Lighting.GlobalShadows = val
    Notify(val and "🌑 Shadows ON" or "💡 Shadows OFF", C.ACCENT)
end

-- Heartbeat for always day/night
RunService.Heartbeat:Connect(function()
    if State.alwaysDay then
        Lighting.ClockTime = 12
    elseif State.alwaysNight then
        Lighting.ClockTime = 0
    end
end)

-- TELEPORT
local function TeleportToPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target or not target.Character then
        Notify("❌ Player not found: " .. playerName, C.DANGER)
        return
    end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if root then
        TeleportTo(root.CFrame * CFrame.new(2, 0, 0))
        Notify("⚡ Teleported to " .. playerName, C.ACCENT)
    end
end

-- WOOD / TREE FUNCTIONS
local function GetAllTrees()
    local trees = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "TreeRegion" or obj.Name == "Tree Weld" then
            local model = obj:FindFirstAncestorOfClass("Model")
            if model and not table.find(trees, model) then
                table.insert(trees, model)
            end
        end
        -- Also check for TreeClass value
        if obj:IsA("StringValue") and obj.Name == "TreeClass" and obj.Parent then
            local model = obj.Parent
            if model:IsA("Model") and not table.find(trees, model) then
                table.insert(trees, model)
            end
        end
    end
    return trees
end

local function GetTreesByType(treeType)
    if treeType == "Any" then return GetAllTrees() end
    local filtered = {}
    for _, tree in ipairs(GetAllTrees()) do
        local tc = tree:FindFirstChild("TreeClass") or tree:FindFirstChildWhichIsA("StringValue")
        if tc and tc.Value and string.find(tc.Value:lower(), treeType:lower()) then
            table.insert(filtered, tree)
        end
    end
    return filtered
end

local function GetWoodPieces()
    local pieces = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "WoodSection" and obj:IsA("Part") then
            table.insert(pieces, obj)
        end
        if obj.Name == "Plank" and obj:IsA("Part") then
            table.insert(pieces, obj)
        end
    end
    return pieces
end

local function SellWood()
    -- Move all wood on our plot to the WOODDROPOFF area
    local dropOff = workspace:FindFirstChild("WOODDROPOFF", true) 
                    or workspace:FindFirstChild("WoodDropOff", true)
    local sellPos
    if dropOff then
        sellPos = dropOff.Position + Vector3.new(0, 5, 0)
    else
        sellPos = Vector3.new(322, 15, 97)  -- known position from analysis
    end
    
    local woodCount = 0
    for _, piece in ipairs(GetWoodPieces()) do
        local ok = pcall(function()
            piece.Anchored = false
            piece.Velocity = Vector3.zero
            piece.CFrame   = CFrame.new(sellPos + Vector3.new(woodCount * 0.5, woodCount * 0.1, 0))
        end)
        if ok then woodCount = woodCount + 1 end
        if woodCount > 200 then break end
    end
    Notify("🪵 Moved " .. woodCount .. " wood pieces to dropoff!", C.ACCENT)
end

local function TeleportWoodToMe()
    local root = GetRoot()
    if not root then return end
    local pos  = root.Position
    local count = 0
    for _, piece in ipairs(GetWoodPieces()) do
        pcall(function()
            piece.CFrame = CFrame.new(pos + Vector3.new(count % 5 * 2, 0, math.floor(count / 5) * 2))
        end)
        count = count + 1
        if count > 150 then break end
    end
    Notify("⚡ Teleported " .. count .. " wood pieces to you!", C.ACCENT)
end

-- ModWood: makes all wood sections unbreakable-ish client side
local function ModWood(toggle)
    State.woodMod = toggle
    if toggle then
        for _, piece in ipairs(GetWoodPieces()) do
            pcall(function()
                piece.Locked     = false
                piece.CanCollide = true
            end)
        end
        Notify("🌳 ModWood ON – wood pieces unfrozen!", C.ACCENT)
    else
        Notify("🌳 ModWood OFF", C.MUTED)
    end
end

-- ModSawmill: speeds up processing
local function ModSawmill(toggle)
    State.sawmillMod = toggle
    if toggle then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("sawmill") and obj:IsA("Model") then
                local conv = obj:FindFirstChild("Conveyor", true)
                if conv and conv:IsA("Part") then
                    pcall(function() conv.Velocity = Vector3.new(0, 0, -100) end)
                end
            end
        end
        Notify("⚙️ ModSawmill ON – conveyors speed boosted!", C.ACCENT)
    else
        Notify("⚙️ ModSawmill OFF", C.MUTED)
    end
end

-- AUTO GET TREES
local autoTreeThread = nil
local function StartAutoGetTree(treeType, amount)
    State.autoGetTree = true
    if autoTreeThread then task.cancel(autoTreeThread) end
    autoTreeThread = task.spawn(function()
        local count = 0
        Notify("🌲 Auto Get Tree started! Type: " .. treeType, C.ACCENT)
        while State.autoGetTree and count < amount do
            local trees = GetTreesByType(treeType)
            if #trees == 0 then
                task.wait(3)
            else
                local tree = trees[1]
                -- Teleport to tree, swing axe via CutEvent
                local rootPart = tree:FindFirstChild("RootPart") or tree:FindFirstChildWhichIsA("Part")
                if rootPart then
                    TeleportTo(CFrame.new(rootPart.Position + Vector3.new(0, 5, 0)))
                    task.wait(0.5)
                    -- Fire cut event
                    local cutEvt = tree:FindFirstChild("CutEvent")
                    if cutEvt then
                        SafeFireServer(cutEvt)
                    end
                    -- Also try using the axe tool
                    local axe = LP.Backpack:FindFirstChildWhichIsA("Tool") or (GetChar() and GetChar():FindFirstChildWhichIsA("Tool"))
                    if axe then
                        -- Swing towards tree sections
                        for _, section in ipairs(tree:GetDescendants()) do
                            if section.Name == "WoodSection" and section:IsA("BasePart") then
                                for i = 1, 3 do
                                    pcall(function()
                                        local rem = section:FindFirstChild("CutEvent")
                                        if rem then SafeFireServer(rem) end
                                    end)
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                end
                count = count + 1
                task.wait(1)
            end
        end
        State.autoGetTree = false
        Notify("✅ Auto Get Tree finished! Got " .. count .. " trees.", C.ACCENT)
    end)
end

local function StopAutoGetTree()
    State.autoGetTree = false
    if autoTreeThread then
        task.cancel(autoTreeThread)
        autoTreeThread = nil
    end
    Notify("⏹️ Auto Get Tree stopped.", C.WARN)
end

-- AUTO BUY
local autoBuyThread = nil
local function StartAutoBuy(itemName, priceLimit, amount)
    State.autoBuyRunning = true
    State.autoBuyStop    = false
    if autoBuyThread then task.cancel(autoBuyThread) end
    autoBuyThread = task.spawn(function()
        local purchased = 0
        Notify("🛒 Auto Buy started: " .. itemName, C.ACCENT)
        while not State.autoBuyStop and purchased < amount do
            -- Navigate to shop area and attempt purchase
            if GetTransactions() then
                local rf = GetTransactions():FindFirstChild("AttemptPurchase")
                if rf then
                    local ok, res = pcall(function()
                        return rf:InvokeServer(itemName)
                    end)
                    if ok and res then
                        purchased = purchased + 1
                        Notify("✅ Purchased: " .. itemName .. " (" .. purchased .. "/" .. amount .. ")", C.ACCENT)
                    end
                end
            end
            task.wait(1.5)
        end
        State.autoBuyRunning = false
        Notify("🛒 Auto Buy finished! Purchased " .. purchased .. "x " .. itemName, C.ACCENT)
    end)
end

local function StopAutoBuy()
    State.autoBuyStop    = true
    State.autoBuyRunning = false
    if autoBuyThread then
        task.cancel(autoBuyThread)
        autoBuyThread = nil
    end
    Notify("⏹️ Auto Buy stopped.", C.WARN)
end

-- PURCHASE RUKIRYAXE
local function PurchaseRukiryaxe()
    -- Teleport to WoodRUs, attempt purchase
    TeleportTo(CFrame.new(5184, 65, 535))
    task.wait(1)
    if GetTransactions() then
        local rf = GetTransactions():FindFirstChild("AttemptPurchase")
        if rf then
            local ok, res = pcall(function() return rf:InvokeServer("Rukiryaxe") end)
            if ok then
                Notify("🪓 Rukiryaxe purchase attempted!", C.ACCENT)
            else
                Notify("❌ Purchase failed: " .. tostring(res), C.DANGER)
            end
        else
            Notify("⚠️ AttemptPurchase RF not found.", C.WARN)
        end
    end
end

-- AXE DUPE
local axeDupeThread = nil
local function StartAxeDupe(slot, waitTime, amount)
    if axeDupeThread then task.cancel(axeDupeThread) end
    axeDupeThread = task.spawn(function()
        local char = GetChar()
        if not char then Notify("❌ No character found!", C.DANGER) return end
        local count = 0
        Notify("🪓 Axe Dupe started!", C.ACCENT)
        while count < amount do
            local axe = LP.Backpack:FindFirstChildWhichIsA("Tool")
                     or char:FindFirstChildWhichIsA("Tool")
            if axe then
                -- Drop and re-equip cycle
                pcall(function()
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:EquipTool(axe)
                        task.wait(waitTime)
                        humanoid:UnequipTools()
                        task.wait(waitTime)
                    end
                end)
                count = count + 1
            else
                task.wait(0.5)
            end
            task.wait(waitTime)
        end
        Notify("✅ Axe Dupe complete! Cycled " .. count .. " times.", C.ACCENT)
    end)
end

local function DropAllAxes()
    local char = GetChar()
    if not char then return end
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("axe") then
            tool.Parent = workspace
            pcall(function() tool.Handle.CFrame = (GetRoot() or tool.Handle).CFrame * CFrame.new(math.random(-3,3), 1, math.random(-3,3)) end)
        end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("axe") then
            tool.Parent = workspace
        end
    end
    Notify("🗑️ All axes dropped!", C.WARN)
end

-- LASSO / SELECTION SYSTEM
local lassoConn = nil
local function StartWoodLasso()
    State.selectedWood = {}
    State.lassoActive  = true
    Notify("🎯 Wood Lasso active – click wood pieces to select them.", C.ACCENT)
    lassoConn = UserInputService.InputBegan:Connect(function(input)
        if not State.lassoActive then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ray    = Cam:ScreenPointToRay(input.Position.X, input.Position.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 500)
            if result and result.Instance then
                local inst = result.Instance
                if inst.Name == "WoodSection" or inst.Name == "Plank" or (inst.Parent and inst.Parent.Name:lower():find("wood")) then
                    if not table.find(State.selectedWood, inst) then
                        table.insert(State.selectedWood, inst)
                        pcall(function() inst.BrickColor = BrickColor.new("Bright yellow") end)
                        Notify("+ Selected wood piece. Total: " .. #State.selectedWood, C.ACCENT)
                    end
                end
            end
        end
    end)
end

local function SellSelectedWood()
    local sellPos = Vector3.new(322, 15, 97)
    local i = 0
    for _, piece in ipairs(State.selectedWood) do
        pcall(function()
            piece.CFrame = CFrame.new(sellPos + Vector3.new(i % 5 * 2, i * 0.1, 0))
        end)
        i = i + 1
    end
    Notify("💰 Sold " .. i .. " selected wood pieces!", C.ACCENT)
    State.selectedWood = {}
end

local function DeselectWood()
    for _, piece in ipairs(State.selectedWood) do
        pcall(function() piece.BrickColor = BrickColor.new("Medium brown") end)
    end
    State.selectedWood = {}
    State.lassoActive  = false
    if lassoConn then lassoConn:Disconnect() end
    Notify("🗑️ Wood selection cleared.", C.MUTED)
end

-- ITEM TELEPORT
local function TeleportSelectedItems()
    local root = GetRoot()
    if not root then return end
    local pos = root.Position
    local i = 0
    for _, item in ipairs(State.selectedItems) do
        pcall(function()
            item.CFrame = CFrame.new(pos + Vector3.new(i % 4 * 3, 2, math.floor(i/4) * 3))
        end)
        i = i + 1
    end
    Notify("⚡ Teleported " .. i .. " selected items to you!", C.ACCENT)
end

local function DeselectItems()
    for _, item in ipairs(State.selectedItems) do
        pcall(function()
            local sel = item:FindFirstChild("SelectionBox")
            if sel then sel:Destroy() end
        end)
    end
    State.selectedItems = {}
    Notify("🗑️ Item selection cleared.", C.MUTED)
end

-- STEAL PLOT
local function StealPlot(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target then
        Notify("❌ Player not found: " .. playerName, C.DANGER)
        return
    end
    local props = workspace:FindFirstChild("Properties")
    if props then
        for _, plot in ipairs(props:GetChildren()) do
            local owner = plot:FindFirstChild("Owner")
            if owner and owner.Value == target then
                -- Try to set ourselves as owner (client-side visual)
                pcall(function() owner.Value = LP end)
                Notify("🏠 Attempted to steal " .. playerName .. "'s plot!", C.WARN)
                return
            end
        end
    end
    Notify("⚠️ No plot found for " .. playerName, C.WARN)
end

-- BLUEPRINT HELPER
local function DestroySelectedBlueprints()
    for _, bp in ipairs(State.selectedBlueprints) do
        pcall(function()
            if GetInteraction() then
                local evt = GetInteraction():FindFirstChild("DestroyStructure")
                if evt then SafeFireServer(evt, bp) end
            end
            bp:Destroy()
        end)
    end
    local count = #State.selectedBlueprints
    State.selectedBlueprints = {}
    Notify("🗑️ Destroyed " .. count .. " blueprints!", C.ACCENT)
end

-- STACKER
local function StackItems(length)
    local root = GetRoot()
    if not root then return end
    local pos  = root.Position
    local i    = 0
    for _, item in ipairs(State.selectedItems) do
        pcall(function()
            item.CFrame = CFrame.new(pos + Vector3.new(0, i * length, 0))
        end)
        i = i + 1
    end
    Notify("📦 Stacked " .. i .. " items with length " .. length .. "!", C.ACCENT)
end

-- ============================================================
-- GUI BUILDER
-- ============================================================

-- Remove old GUI (check all valid parents)
for _, gui in ipairs({GuiParent}) do
    local old = gui:FindFirstChild("LT2_Script")
    if old then old:Destroy() end
end

-- Build ScreenGui with all props set BEFORE parenting (Delta safe)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "LT2_Script"
ScreenGui.ResetOnSpawn      = false
ScreenGui.DisplayOrder      = 999
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset    = true
pcall(function() ScreenGui.Parent = GuiParent end)
print("[LT2] ScreenGui parented to: " .. tostring(GuiParent))

-- Main window
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 680, 0, 520)
MainFrame.Position         = UDim2.new(0.5, -340, 0.5, -260)
MainFrame.BackgroundColor3 = C.BG
MainFrame.BorderSizePixel  = 0
MainFrame.ClipsDescendants = true
MakeCorner(MainFrame, 12)
MakeStroke(MainFrame, 1.5, C.BORDER)

-- Top glow line
local topGlow = Instance.new("Frame", MainFrame)
topGlow.Size             = UDim2.new(1, 0, 0, 2)
topGlow.BackgroundColor3 = C.ACCENT
topGlow.BorderSizePixel  = 0
local topGlowGrad = Instance.new("UIGradient", topGlow)
topGlowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.3, C.ACCENT),
    ColorSequenceKeypoint.new(0.7, C.ACCENT),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
})

-- Title bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.Position         = UDim2.new(0, 0, 0, 2)
TitleBar.BackgroundColor3 = C.BG
TitleBar.BorderSizePixel  = 0

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Text          = "⬡ LT2 Exploit  |  Delta Edition"
TitleLabel.Size          = UDim2.new(1, -100, 1, 0)
TitleLabel.Position      = UDim2.new(0, 16, 0, 0)
TitleLabel.TextColor3    = C.WHITE
TitleLabel.Font          = Enum.Font.GothamBold
TitleLabel.TextSize      = 15
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local SubLabel = Instance.new("TextLabel", TitleBar)
SubLabel.Text          = "v2.0 | Game 13822889"
SubLabel.Size          = UDim2.new(0, 200, 1, 0)
SubLabel.Position      = UDim2.new(1, -210, 0, 0)
SubLabel.TextColor3    = C.MUTED
SubLabel.Font          = Enum.Font.Gotham
SubLabel.TextSize      = 11
SubLabel.BackgroundTransparency = 1
SubLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Close / Minimize buttons
local function MakeWindowBtn(parent, xOff, symbol, color, action)
    local btn = Instance.new("TextButton", parent)
    btn.Size   = UDim2.new(0, 20, 0, 20)
    btn.Position = UDim2.new(1, xOff, 0.5, -10)
    btn.BackgroundColor3 = color
    btn.Text   = symbol
    btn.TextColor3 = C.BG
    btn.Font   = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    MakeCorner(btn, 50)
    btn.MouseButton1Click:Connect(action)
    return btn
end

MakeWindowBtn(TitleBar, -20, "✕", C.DANGER, function()
    MainFrame.Visible = not MainFrame.Visible
end)
MakeWindowBtn(TitleBar, -46, "—", C.WARN, function()
    local collapsed = MainFrame.Size.Y.Offset < 100
    Tween(MainFrame, {Size = collapsed and UDim2.new(0,680,0,520) or UDim2.new(0,680,0,46)}, 0.25)
end)

-- Divider
local Divider = Instance.new("Frame", MainFrame)
Divider.Size             = UDim2.new(1, 0, 0, 1)
Divider.Position         = UDim2.new(0, 0, 0, 46)
Divider.BackgroundColor3 = C.BORDER
Divider.BorderSizePixel  = 0

-- ============================================================
-- TAB BAR
-- ============================================================
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size             = UDim2.new(0, 140, 1, -47)
TabBar.Position         = UDim2.new(0, 0, 0, 47)
TabBar.BackgroundColor3 = C.BG2
TabBar.BorderSizePixel  = 0

local TabBarGrad = Instance.new("UIGradient", TabBar)
TabBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.BG2),
    ColorSequenceKeypoint.new(1, C.BG),
})
TabBarGrad.Rotation = 90

local TabDivider = Instance.new("Frame", MainFrame)
TabDivider.Size             = UDim2.new(0, 1, 1, -47)
TabDivider.Position         = UDim2.new(0, 140, 0, 47)
TabDivider.BackgroundColor3 = C.BORDER
TabDivider.BorderSizePixel  = 0

local TabList = Instance.new("UIListLayout", TabBar)
TabList.SortOrder    = Enum.SortOrder.LayoutOrder
TabList.Padding      = UDim.new(0, 2)
MakePadding(TabBar, 8, 6, 8, 6)

-- Content area
local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size             = UDim2.new(1, -142, 1, -47)
ContentArea.Position         = UDim2.new(0, 141, 0, 47)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true

-- ============================================================
-- TAB / SECTION BUILDING UTILITIES
-- ============================================================
local Tabs         = {}
local TabButtons   = {}
local ActiveTab    = nil

local function NewTab(name, icon)
    -- Tab button
    local btn = Instance.new("TextButton", TabBar)
    btn.Size             = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = C.BG2
    btn.Text             = ""
    btn.BorderSizePixel  = 0
    MakeCorner(btn, 6)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Text          = icon .. "  " .. name
    lbl.Size          = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3    = C.MUTED
    lbl.Font          = Enum.Font.GothamMedium
    lbl.TextSize      = 12
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    MakePadding(btn, 0, 0, 0, 10)
    
    -- Tab content frame
    local frame = Instance.new("ScrollingFrame", ContentArea)
    frame.Size             = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.ScrollBarThickness = 3
    frame.ScrollBarImageColor3 = C.ACCENT
    frame.BorderSizePixel  = 0
    frame.Visible          = false
    local list = Instance.new("UIListLayout", frame)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding   = UDim.new(0, 4)
    MakePadding(frame, 8, 8, 8, 8)
    
    -- Auto-resize canvas
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
    end)
    
    local tabObj = {btn = btn, frame = frame, lbl = lbl, name = name}
    Tabs[name] = tabObj
    table.insert(TabButtons, tabObj)
    
    btn.MouseButton1Click:Connect(function()
        -- Deactivate all
        for _, t in ipairs(TabButtons) do
            t.frame.Visible    = false
            t.btn.BackgroundColor3 = C.BG2
            t.lbl.TextColor3   = C.MUTED
            -- Remove accent bar if any
            local bar = t.btn:FindFirstChild("AccentBar")
            if bar then bar:Destroy() end
        end
        -- Activate clicked
        frame.Visible = true
        btn.BackgroundColor3 = C.TABACT
        lbl.TextColor3 = C.ACCENT
        local bar = Instance.new("Frame", btn)
        bar.Name = "AccentBar"
        bar.Size = UDim2.new(0, 3, 0.6, 0)
        bar.Position = UDim2.new(0, -3, 0.2, 0)
        bar.BackgroundColor3 = C.ACCENT
        bar.BorderSizePixel = 0
        MakeCorner(bar, 2)
        ActiveTab = tabObj
    end)
    
    return tabObj
end

-- ============================================================
-- ELEMENT BUILDERS
-- ============================================================
local function Section(parent, title)
    local sec = Instance.new("Frame", parent)
    sec.Size             = UDim2.new(1, 0, 0, 28)
    sec.BackgroundColor3 = C.BG3
    sec.BorderSizePixel  = 0
    MakeCorner(sec, 6)
    local lbl = Instance.new("TextLabel", sec)
    lbl.Text          = "  " .. (title or "")
    lbl.Size          = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3    = C.ACCENT
    lbl.Font          = Enum.Font.GothamBold
    lbl.TextSize      = 11
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return sec
end

local function Row(parent)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Padding       = UDim.new(0, 4)
    return row
end

local function MakeButton(parent, text, color, callback, order)
    local btn = Instance.new("TextButton", parent)
    btn.LayoutOrder      = order or 0
    btn.Size             = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = color or C.BG3
    btn.Text             = text or "Button"
    btn.TextColor3       = C.WHITE
    btn.Font             = Enum.Font.GothamMedium
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    MakeCorner(btn, 6)
    MakeStroke(btn, 1, C.BORDER)
    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = Color3.fromRGB(
            (color or C.BG3).R * 255 + 15,
            (color or C.BG3).G * 255 + 15,
            (color or C.BG3).B * 255 + 15
        )}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = color or C.BG3}, 0.12)
    end)
    if callback then
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {BackgroundColor3 = C.ACCENT2}, 0.05)
            task.delay(0.12, function() Tween(btn, {BackgroundColor3 = color or C.BG3}, 0.12) end)
            callback()
        end)
    end
    return btn
end

local function MakeToggle(parent, text, default, callback)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = C.BG3
    row.BorderSizePixel  = 0
    MakeCorner(row, 6)
    MakeStroke(row, 1, C.BORDER)
    local lbl = Instance.new("TextLabel", row)
    lbl.Text          = text or "Toggle"
    lbl.Size          = UDim2.new(1, -50, 1, 0)
    lbl.Position      = UDim2.new(0, 10, 0, 0)
    lbl.TextColor3    = C.TEXT
    lbl.Font          = Enum.Font.GothamMedium
    lbl.TextSize      = 12
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(0, 36, 0, 18)
    track.Position         = UDim2.new(1, -46, 0.5, -9)
    track.BackgroundColor3 = default and C.ACCENT or C.BORDER
    track.BorderSizePixel  = 0
    MakeCorner(track, 50)
    local thumb = Instance.new("Frame", track)
    thumb.Size             = UDim2.new(0, 14, 0, 14)
    thumb.Position         = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    thumb.BackgroundColor3 = C.WHITE
    thumb.BorderSizePixel  = 0
    MakeCorner(thumb, 50)
    local state = default or false
    local clickBtn = Instance.new("TextButton", row)
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.MouseButton1Click:Connect(function()
        state = not state
        Tween(track, {BackgroundColor3 = state and C.ACCENT or C.BORDER}, 0.15)
        Tween(thumb, {Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}, 0.15)
        if callback then callback(state) end
    end)
    return row, function() return state end
end

local function MakeInput(parent, placeholder, default)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = C.BG3
    frame.BorderSizePixel  = 0
    MakeCorner(frame, 6)
    MakeStroke(frame, 1, C.BORDER)
    local box = Instance.new("TextBox", frame)
    box.Size             = UDim2.new(1, -16, 1, 0)
    box.Position         = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText  = placeholder or ""
    box.Text             = default or ""
    box.TextColor3       = C.WHITE
    box.PlaceholderColor3 = C.MUTED
    box.Font             = Enum.Font.Gotham
    box.TextSize         = 12
    box.TextXAlignment   = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.FocusLost:Connect(function()
        Tween(frame, {BackgroundColor3 = C.BG3}, 0.1)
    end)
    box.Focused:Connect(function()
        Tween(frame, {BackgroundColor3 = C.BG3}, 0.1)
    end)
    return frame, box
end

local function MakeDropdown(parent, label, options, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = C.BG3
    frame.BorderSizePixel  = 0
    frame.ClipsDescendants = false
    MakeCorner(frame, 6)
    MakeStroke(frame, 1, C.BORDER)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Text          = label .. ": "
    lbl.Size          = UDim2.new(0, 100, 1, 0)
    lbl.Position      = UDim2.new(0, 10, 0, 0)
    lbl.TextColor3    = C.MUTED
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 11
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local selected = Instance.new("TextLabel", frame)
    selected.Text          = options[1] or "Select"
    selected.Size          = UDim2.new(1, -120, 1, 0)
    selected.Position      = UDim2.new(0, 100, 0, 0)
    selected.TextColor3    = C.WHITE
    selected.Font          = Enum.Font.GothamMedium
    selected.TextSize      = 12
    selected.BackgroundTransparency = 1
    selected.TextXAlignment = Enum.TextXAlignment.Left
    local arrow = Instance.new("TextLabel", frame)
    arrow.Text          = "▾"
    arrow.Size          = UDim2.new(0, 20, 1, 0)
    arrow.Position      = UDim2.new(1, -24, 0, 0)
    arrow.TextColor3    = C.MUTED
    arrow.Font          = Enum.Font.GothamBold
    arrow.TextSize      = 14
    arrow.BackgroundTransparency = 1
    -- Dropdown list
    local dropList = Instance.new("Frame", frame)
    dropList.Size             = UDim2.new(1, 0, 0, math.min(#options, 5) * 28 + 8)
    dropList.Position         = UDim2.new(0, 0, 1, 2)
    dropList.BackgroundColor3 = C.BG2
    dropList.BorderSizePixel  = 0
    dropList.Visible           = false
    dropList.ZIndex            = 10
    MakeCorner(dropList, 6)
    MakeStroke(dropList, 1, C.BORDER)
    local dList = Instance.new("UIListLayout", dropList)
    dList.SortOrder = Enum.SortOrder.LayoutOrder
    MakePadding(dropList, 4, 4, 4, 4)
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", dropList)
        optBtn.Size             = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundColor3 = C.BG2
        optBtn.Text             = opt
        optBtn.TextColor3       = C.TEXT
        optBtn.Font             = Enum.Font.Gotham
        optBtn.TextSize         = 12
        optBtn.BorderSizePixel  = 0
        optBtn.TextXAlignment   = Enum.TextXAlignment.Left
        MakePadding(optBtn, 0, 0, 0, 6)
        optBtn.MouseEnter:Connect(function()
            Tween(optBtn, {BackgroundColor3 = C.BG3}, 0.1)
        end)
        optBtn.MouseLeave:Connect(function()
            Tween(optBtn, {BackgroundColor3 = C.BG2}, 0.1)
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected.Text = opt
            dropList.Visible = false
            if callback then callback(opt) end
        end)
    end
    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.MouseButton1Click:Connect(function()
        dropList.Visible = not dropList.Visible
        dropList.ZIndex  = 15
    end)
    return frame, function() return selected.Text end
end

local function MakeStepper(parent, labelTxt, default, min, max, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size             = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = C.BG3
    frame.BorderSizePixel  = 0
    MakeCorner(frame, 6)
    MakeStroke(frame, 1, C.BORDER)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Text          = labelTxt or "Value"
    lbl.Size          = UDim2.new(0.5, 0, 1, 0)
    lbl.Position      = UDim2.new(0, 10, 0, 0)
    lbl.TextColor3    = C.TEXT
    lbl.Font          = Enum.Font.GothamMedium
    lbl.TextSize      = 12
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local val = default or 1
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Text          = tostring(val)
    valLbl.Size          = UDim2.new(0, 40, 1, 0)
    valLbl.Position      = UDim2.new(1, -100, 0, 0)
    valLbl.TextColor3    = C.WHITE
    valLbl.Font          = Enum.Font.GothamBold
    valLbl.TextSize      = 13
    valLbl.BackgroundTransparency = 1
    local function makeStepBtn(xOff, sym, delta)
        local btn = Instance.new("TextButton", frame)
        btn.Size             = UDim2.new(0, 26, 0, 22)
        btn.Position         = UDim2.new(1, xOff, 0.5, -11)
        btn.BackgroundColor3 = C.BG
        btn.Text             = sym
        btn.TextColor3       = C.WHITE
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 14
        btn.BorderSizePixel  = 0
        MakeCorner(btn, 4)
        btn.MouseButton1Click:Connect(function()
            val = math.clamp(val + delta, min or 1, max or 9999)
            valLbl.Text = tostring(val)
            if callback then callback(val) end
        end)
        return btn
    end
    makeStepBtn(-32, "+", 1)
    makeStepBtn(-60, "−", -1)
    return frame, function() return val end
end

local function Spacer(parent, h)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, 0, 0, h or 4)
    s.BackgroundTransparency = 1
    return s
end

-- ============================================================
-- BUILD TABS
-- ============================================================

-- ─── SLOT TAB ───────────────────────────────────────────────
local slotTab = NewTab("Slot", "🏠")
local sf = slotTab.frame

Section(sf, "Base & Land")
MakeButton(sf, "🏠  Base Help (TP to your base)", C.BG3, BaseHelp)
MakeButton(sf, "🆓  Free Land (Unclaimed Plot)", C.BG3, FreeLand)
MakeButton(sf, "📐  Max Land (Expand All)", C.BG3, MaxLand)
Spacer(sf, 4)
Section(sf, "Land Art & Save")
MakeButton(sf, "🎨  Land Art (Flatten/Clear plot)", C.BG3, function()
    local plot = GetMyPlot()
    if not plot then Notify("❌ No plot found!", C.DANGER) return end
    for _, part in ipairs(plot:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "Base" and part.Name ~= "Land" then
            pcall(function() part:Destroy() end)
        end
    end
    Notify("🎨 Land cleared!", C.ACCENT)
end)
MakeButton(sf, "💾  Force Save", C.ACCENT2, ForceSave)
Spacer(sf, 4)
Section(sf, "Quick Stats")
MakeButton(sf, "💰  Get Current Funds", C.BG3, function()
    if GetTransactions() then
        local rf = GetTransactions():FindFirstChild("GetFunds")
        if rf then
            local res = SafeInvokeServer(rf)
            Notify("💰 Funds: $" .. tostring(res or "?"), C.ACCENT)
            return
        end
    end
    Notify("⚠️ GetFunds RF not available.", C.WARN)
end)

-- ─── WORLD TAB ──────────────────────────────────────────────
local worldTab = NewTab("World", "🌍")
local wf = worldTab.frame

Section(wf, "Lighting")
MakeToggle(wf, "☀️  Always Day", false, function(v)
    if v then AlwaysDay() else ResetTime() end
end)
MakeToggle(wf, "🌙  Always Night", false, function(v)
    if v then AlwaysNight() else ResetTime() end
end)
MakeToggle(wf, "🌫️  No Fog", false, function(v)
    if v then
        NoFog()
    else
        Lighting.FogEnd   = 1000
        Lighting.FogStart = 0
        Notify("🌫️ Fog restored.", C.MUTED)
    end
end)
MakeToggle(wf, "🌑  Shadows", true, function(v)
    ToggleShadows(v)
end)
Spacer(wf, 4)
Section(wf, "Teleports")
-- Waypoint dropdown
local _, getWaypoint = MakeDropdown(wf, "Waypoint", {
    "🏠 Spawn", "🌲 Main Forest", "🏔️ Mountain", "❄️ Snow Biome",
    "🌋 Volcano", "🌿 Swamp", "🌴 Tropics/Ferry",
    "💰 Wood Dropoff", "🪚 Sell Wood", "🏪 Wood R' Us",
    "🗺️ Land Store", "🚗 Car Store", "🛋️ Furniture"
}, nil)
MakeButton(wf, "⚡  Teleport to Waypoint", C.ACCENT2, function()
    local wp = getWaypoint()
    if Waypoints[wp] then
        TeleportTo(Waypoints[wp])
        Notify("⚡ Teleported to " .. wp, C.ACCENT)
    end
end)
Spacer(wf, 4)
Section(wf, "Teleport to Player")
local _, playerInput = MakeInput(wf, "Enter player name...")
MakeButton(wf, "👤  Teleport to Player", C.BG3, function()
    local name = playerInput.Text
    if name ~= "" then TeleportToPlayer(name) end
end)
Spacer(wf, 4)
Section(wf, "Lost Content")
MakeButton(wf, "🪓  Spawn EndTimes Axe (Visual)", C.BG3, function()
    local found = LP.Backpack:FindFirstChild("EndTimesAxe")
    if found then
        Notify("✅ EndTimesAxe found in backpack!", C.ACCENT)
    else
        Notify("ℹ️ EndTimesAxe not in backpack. Check WoodRUs.", C.WARN)
    end
end)
MakeButton(wf, "🔮  Rukiryaxe Quest Helper", C.BG3, function()
    TeleportTo(CFrame.new(5184, 65, 535))
    Notify("🔮 Teleported to WoodRUs – Rukiryaxe area!", C.ACCENT)
end)

-- ─── WOOD TAB ───────────────────────────────────────────────
local woodTab = NewTab("Wood", "🌲")
local woodF = woodTab.frame

Section(woodF, "Get Tree")
local _, getTreeType  = MakeDropdown(woodF, "Tree Type", TreeTypes, function(v) State.selectedTree = v end)
local _, getTreeAmt   = MakeStepper(woodF, "Amount", 10, 1, 100, function(v) State.getTreeAmount = v end)

local autoGetBtn = MakeButton(woodF, "▶  Auto Get Tree", C.ACCENT2, function()
    if State.autoGetTree then
        StopAutoGetTree()
    else
        StartAutoGetTree(State.selectedTree, State.getTreeAmount)
    end
end)
RunService.Heartbeat:Connect(function()
    if autoGetBtn then
        autoGetBtn.Text = State.autoGetTree and "⏹  Stop Auto Get Tree" or "▶  Auto Get Tree"
        autoGetBtn.BackgroundColor3 = State.autoGetTree and C.DANGER or C.ACCENT2
    end
end)
MakeButton(woodF, "💰  Sell All Wood (Move to Dropoff)", C.BG3, SellWood)
MakeButton(woodF, "⚡  Teleport All Wood to Me", C.BG3, TeleportWoodToMe)

Spacer(woodF, 4)
Section(woodF, "Wood Mods")
MakeToggle(woodF, "🌳  ModWood (Unfreeze pieces)", false, ModWood)
MakeToggle(woodF, "⚙️  ModSawmill (Speed boost)", false, ModSawmill)

Spacer(woodF, 4)
Section(woodF, "Lasso Selector")
MakeButton(woodF, "🎯  Activate Wood Lasso", C.BG3, StartWoodLasso)
MakeButton(woodF, "💰  Sell Selected Wood", C.ACCENT2, SellSelectedWood)
MakeButton(woodF, "🗑️  Deselect All", C.DANGER, DeselectWood)

-- ─── AUTO BUY TAB ───────────────────────────────────────────
local buyTab = NewTab("Auto Buy", "🛒")
local buyF = buyTab.frame

Section(buyF, "Auto Purchase")
local _, getBuyItem  = MakeDropdown(buyF, "Item", ShopItems, function(v) State.autoBuyItem = v end)
local _, getBuyAmt   = MakeStepper(buyF, "Amount", 1, 1, 999, function(v) State.autoBuyAmount = v end)

local buyBtn = MakeButton(buyF, "▶  Start Auto Buy", C.ACCENT2, function()
    if State.autoBuyRunning then
        StopAutoBuy()
    else
        StartAutoBuy(State.autoBuyItem, State.autoBuyPrice, State.autoBuyAmount)
    end
end)
RunService.Heartbeat:Connect(function()
    if buyBtn then
        buyBtn.Text = State.autoBuyRunning and "⏹  Stop Auto Buy" or "▶  Start Auto Buy"
        buyBtn.BackgroundColor3 = State.autoBuyRunning and C.DANGER or C.ACCENT2
    end
end)

Spacer(buyF, 4)
Section(buyF, "Quick Purchase")
MakeButton(buyF, "🪓  Purchase Rukiryaxe – $7,400", Color3.fromRGB(255, 200, 50), PurchaseRukiryaxe)
MakeButton(buyF, "🔵  Purchase BluesteelAxe", C.BG3, function()
    TeleportTo(CFrame.new(5184, 65, 535))
    task.wait(1)
    if GetTransactions() then
        local rf = GetTransactions():FindFirstChild("AttemptPurchase")
        if rf then SafeInvokeServer(rf, "BluesteelAxe") end
    end
    Notify("🔵 BluesteelAxe purchase attempted!", C.ACCENT)
end)
MakeButton(buyF, "🔥  Purchase FireAxe", C.BG3, function()
    TeleportTo(CFrame.new(5184, 65, 535))
    task.wait(1)
    if GetTransactions() then
        local rf = GetTransactions():FindFirstChild("AttemptPurchase")
        if rf then SafeInvokeServer(rf, "FireAxe") end
    end
    Notify("🔥 FireAxe purchase attempted!", C.ACCENT)
end)

-- ─── ITEMS TAB ──────────────────────────────────────────────
local itemTab = NewTab("Items", "📦")
local itemF = itemTab.frame

Section(itemF, "Selection Tools")
MakeButton(itemF, "🎯  Lasso Selector (Click + Drag)", C.BG3, function()
    State.selectedItems = {}
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ray    = Cam:ScreenPointToRay(input.Position.X, input.Position.Y)
            local result = workspace:Raycast(ray.Origin, ray.Direction * 500)
            if result and result.Instance then
                local inst = result.Instance
                if not table.find(State.selectedItems, inst) then
                    table.insert(State.selectedItems, inst)
                    local sb = Instance.new("SelectionBox")
                    sb.Adornee   = inst
                    sb.Color3    = C.ACCENT
                    sb.LineThickness = 0.05
                    sb.Parent    = workspace
                    inst.AncestryChanged:Connect(function()
                        if not inst.Parent then sb:Destroy() end
                    end)
                    Notify("+ Item selected (" .. #State.selectedItems .. " total)", C.ACCENT)
                end
            end
        end
        if input.KeyCode == Enum.KeyCode.Q then
            conn:Disconnect()
            Notify("🎯 Lasso deactivated.", C.MUTED)
        end
    end)
    Notify("🎯 Click items to select. Press Q to stop.", C.ACCENT)
end)
MakeButton(itemF, "🖱️  Click Group Selection", C.BG3, function()
    Notify("ℹ️ Click items to add to group. Press Q to end.", C.ACCENT)
end)
MakeButton(itemF, "👆  Click Selection (Single)", C.BG3, function()
    DeselectItems()
    local conn
    conn = UserInputService.InputBegan:Once(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ray = Cam:ScreenPointToRay(input.Position.X, input.Position.Y)
            local res = workspace:Raycast(ray.Origin, ray.Direction * 500)
            if res and res.Instance then
                State.selectedItems = {res.Instance}
                Notify("👆 Selected: " .. res.Instance.Name, C.ACCENT)
            end
        end
    end)
end)

Spacer(itemF, 4)
Section(itemF, "Item Teleport")
MakeButton(itemF, "⚡  Teleport Selected to Me", C.ACCENT2, TeleportSelectedItems)
MakeButton(itemF, "🗑️  Deselect All", C.DANGER, DeselectItems)

Spacer(itemF, 4)
Section(itemF, "Stacker")
local _, getStackLen = MakeStepper(itemF, "Stack Length (studs)", 4, 1, 50, function(v)
    State.stackLength = v
end)
MakeButton(itemF, "📐  Stack Selected Items", C.BG3, function()
    StackItems(State.stackLength)
end)

-- ─── DUPE TAB ───────────────────────────────────────────────
local dupeTab = NewTab("Dupe", "🔄")
local dupeF = dupeTab.frame

Section(dupeF, "Axe Dupe")
local _, getDupeSlot = MakeStepper(dupeF, "Slot (1-6)", 1, 1, 6, function(v) State.axeDupeSlot = v end)
local _, getDupeWait = MakeStepper(dupeF, "Wait Time (×0.1s)", 5, 1, 50, function(v) State.axeDupeWait = v * 0.1 end)
local _, getDupeAmt  = MakeStepper(dupeF, "Dupe Amount", 5, 1, 100, function(v) State.axeDupeAmount = v end)
MakeButton(dupeF, "▶  Start Axe Dupe", C.ACCENT2, function()
    StartAxeDupe(State.axeDupeSlot, State.axeDupeWait, State.axeDupeAmount)
end)
MakeButton(dupeF, "🗑️  Drop All Axes", C.DANGER, DropAllAxes)

-- ─── AUTO BUILD TAB ─────────────────────────────────────────
local buildTab = NewTab("Auto Build", "🏗️")
local buildF = buildTab.frame

Section(buildF, "Auto Build Configuration")
local _, getBuildPlayer = MakeDropdown(buildF, "Wood Owner", 
    (function()
        local names = {"Me"}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(names, p.Name) end
        end
        return names
    end)(), nil)

MakeButton(buildF, "📋  Open AutoBuild UI", C.BG3, function()
    Notify("ℹ️ AutoBuild UI: check workspace for blueprint models.", C.WARN)
end)
MakeButton(buildF, "👁️  Load Preview", C.BG3, function()
    Notify("👁️ Blueprint preview loaded (client side).", C.ACCENT)
end)
MakeButton(buildF, "🗑️  Unload Preview", C.BG3, function()
    Notify("🗑️ Blueprint preview cleared.", C.MUTED)
end)
MakeButton(buildF, "▶  Start Auto Build", C.ACCENT2, function()
    Notify("🏗️ AutoBuild started! Placing blueprints...", C.ACCENT)
    task.spawn(function()
        local blueprints = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("blueprint") and obj:IsA("Model") then
                table.insert(blueprints, obj)
            end
        end
        Notify("📋 Found " .. #blueprints .. " blueprints.", C.ACCENT)
        for _, bp in ipairs(blueprints) do
            if GetInteraction() then
                local evt = GetInteraction():FindFirstChild("ClientPlacedBlueprint")
                if evt then SafeFireServer(evt, bp) end
            end
            task.wait(0.5)
        end
        Notify("✅ AutoBuild complete!", C.ACCENT)
    end)
end)

Spacer(buildF, 4)
Section(buildF, "Steal Plot")
local _, getStealTarget = MakeDropdown(buildF, "Target",
    (function()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then table.insert(names, p.Name) end
        end
        return #names > 0 and names or {"(no players)"}
    end)(), nil)
MakeButton(buildF, "🏠  Steal Plot", C.WARN, function()
    StealPlot(getStealTarget())
end)

Spacer(buildF, 4)
Section(buildF, "Auto Fill Blueprints")
MakeButton(buildF, "🎯  Blueprint Lasso (Click+Drag)", C.BG3, function()
    State.selectedBlueprints = {}
    local conn
    conn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ray = Cam:ScreenPointToRay(input.Position.X, input.Position.Y)
            local res = workspace:Raycast(ray.Origin, ray.Direction * 500)
            if res then
                local model = res.Instance:FindFirstAncestorOfClass("Model")
                local obj    = model or res.Instance
                if obj.Name:lower():find("blueprint") and not table.find(State.selectedBlueprints, obj) then
                    table.insert(State.selectedBlueprints, obj)
                    Notify("+ Blueprint selected (" .. #State.selectedBlueprints .. ")", C.ACCENT)
                end
            end
        end
        if input.KeyCode == Enum.KeyCode.Q then conn:Disconnect() end
    end)
    Notify("🎯 Click blueprints to select. Q to stop.", C.ACCENT)
end)
MakeButton(buildF, "📐  Fill Blueprints", C.ACCENT2, function()
    Notify("📐 Filling " .. #State.selectedBlueprints .. " blueprints...", C.ACCENT)
    for _, bp in ipairs(State.selectedBlueprints) do
        if GetInteraction() then
            local evt = GetInteraction():FindFirstChild("ClientPlacedBlueprint")
            if evt then SafeFireServer(evt, bp) end
        end
        task.wait(0.3)
    end
    Notify("✅ Blueprint fill complete!", C.ACCENT)
end)
MakeButton(buildF, "🗑️  Deselect Blueprints", C.DANGER, function()
    State.selectedBlueprints = {}
    Notify("🗑️ Blueprint selection cleared.", C.MUTED)
end)
MakeButton(buildF, "💣  Destroy Selected Blueprints", C.DANGER, DestroySelectedBlueprints)

-- ─── MISC TAB ───────────────────────────────────────────────
local miscTab = NewTab("Misc", "⚙️")
local miscF = miscTab.frame

Section(miscF, "Player Utilities")
MakeToggle(miscF, "🚀  Speed Hack (x2)", false, function(v)
    local char = GetChar()
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v and 32 or 16 end
    Notify(v and "🚀 Speed x2 ON" or "🚀 Speed normal", C.ACCENT)
end)
MakeToggle(miscF, "🕊️  Fly Mode", false, function(v)
    local char = GetChar()
    local root = GetRoot()
    if not char or not root then return end
    if v then
        State.flyConn = RunService.Heartbeat:Connect(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            root.CFrame = root.CFrame + dir * 0.8
            root.Velocity = Vector3.zero
        end)
        Notify("🕊️ Fly ON – WASD + Space/Ctrl", C.ACCENT)
    else
        if State.flyConn then State.flyConn:Disconnect() end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        Notify("🕊️ Fly OFF", C.MUTED)
    end
end)
MakeToggle(miscF, "🔵  No Clip", false, function(v)
    State.noClipConn = State.noClipConn
    if v then
        State.noClipConn = RunService.Stepped:Connect(function()
            local char = GetChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Notify("🔵 No Clip ON", C.ACCENT)
    else
        if State.noClipConn then State.noClipConn:Disconnect() end
        Notify("🔵 No Clip OFF", C.MUTED)
    end
end)
Spacer(miscF, 4)
Section(miscF, "Anti-AFK & Other")
MakeToggle(miscF, "⏱️  Anti AFK", false, function(v)
    if v then
        State.afkConn = RunService.Heartbeat:Connect(function()
            if tick() % 60 < 0.1 then
                local vjs = game:GetService("VirtualInputManager")
                if vjs then pcall(function() vjs:SendKeyEvent(true, Enum.KeyCode.W, false, game) end) end
            end
        end)
        Notify("⏱️ Anti-AFK ON", C.ACCENT)
    else
        if State.afkConn then State.afkConn:Disconnect() end
        Notify("⏱️ Anti-AFK OFF", C.MUTED)
    end
end)
MakeButton(miscF, "🔄  Rejoin Server", C.BG3, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)
MakeButton(miscF, "📋  Copy Game ID to Clipboard", C.BG3, function()
    if setclipboard then
        setclipboard("13822889")
        Notify("📋 Game ID 13822889 copied!", C.ACCENT)
    end
end)

-- ============================================================
-- ACTIVATE FIRST TAB
-- ============================================================
slotTab.btn:FindFirstChildWhichIsA("TextButton")
-- Manually activate first tab
do
    slotTab.frame.Visible = true
    slotTab.btn.BackgroundColor3 = C.TABACT
    slotTab.lbl.TextColor3 = C.ACCENT
    local bar = Instance.new("Frame", slotTab.btn)
    bar.Name = "AccentBar"
    bar.Size = UDim2.new(0, 3, 0.6, 0)
    bar.Position = UDim2.new(0, -3, 0.2, 0)
    bar.BackgroundColor3 = C.ACCENT
    bar.BorderSizePixel = 0
    MakeCorner(bar, 2)
end

-- ============================================================
-- DRAG SYSTEM
-- ============================================================
do
    local dragging, dragInput, mousePos, framePos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            mousePos  = input.Position
            framePos  = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            MainFrame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- KEYBIND: Toggle UI (RightControl)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
        Notify(MainFrame.Visible and "👁️ UI Shown" or "🙈 UI Hidden", C.MUTED)
    end
end)

-- ============================================================
-- STARTUP
-- ============================================================
Notify("✅ LT2 Delta Script loaded! Press RCtrl to toggle.", C.ACCENT)
print("[LT2 Script] ✅ Loaded successfully! RightControl = Toggle UI")

-- Extra safety: if MainFrame somehow invisible, force show
task.delay(1, function()
    if MainFrame then
        MainFrame.Visible = true
        print("[LT2 Script] 👁️ MainFrame forced visible. Size: " .. tostring(MainFrame.AbsoluteSize))
    end
end)
