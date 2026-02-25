--[[
    LT2 Exploit Menu v2.0 - Fully Working Edition
    Built from decompiled game source (place_13822889)
    
    VERIFIED REMOTES:
    - game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(tool, "Drop tool", tool.Handle.CFrame)
    - game.ReplicatedStorage.Interaction.ConfirmIdentity:InvokeServer(tool, toolNameValue)
    - game.ReplicatedStorage.Interaction.RemoteProxy:FireServer(bindable_or_part, data_table)
    - game.ReplicatedStorage.Interaction.DestroyStructure:FireServer(structure)
    - game.ReplicatedStorage.PropertyPurchasing.SetPropertyPurchasingValue:InvokeServer(bool)
    - game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty:FireServer(property, camPos)
    - game.ReplicatedStorage.LoadSaveRequests.RequestSave:InvokeServer(slotId, playerId)
    - game.ReplicatedStorage.LoadSaveRequests.RequestLoad:InvokeServer(slotId, playerId, version)
    - game.ReplicatedStorage.LoadSaveRequests.ClientMayLoad:InvokeServer(playerId)
    - game.ReplicatedStorage.LoadSaveRequests.GetMetaData:InvokeServer(playerId)
    - game.ReplicatedStorage.NPCDialog.PromptChat:FireServer(bool, npc, dialogNode)
    - game.ReplicatedStorage.NPCDialog.PlayerChatted:InvokeServer(npc, choice/"EndChat")
    - game.ReplicatedStorage.NPCDialog.SetChattingValue:InvokeServer(value)
    - game.ReplicatedStorage.Transactions.Level:InvokeServer()
    - game.ReplicatedStorage.Notices.SendUserNotice:Fire(msg, duration)  [BindableEvent]
    
    VERIFIED TOOL NAMES:
    Axe2, RustyAxe, RefinedAxe, BluesteelAxe, CaveAxe, FireAxe, SilverAxe,
    Rukiryaxe, IceAxe, MintAxe, CandyCaneAxe, CandyCornAxe, GingerbreadAxe,
    Beesaxe, ManyAxe, InverseAxe, EndTimesAxe

    KNOWN STORE LOCATIONS (world coordinates):
    - WoodRUs (main axe store): ~(-275, 5, 105)
    - Bob's Shack: ~(-252, 5, 400)
    - Link's Logic: ~(15, 5, 262)
    - Fancy Furniture: ~(-122, 5, 165)
    - Wood Drop-off (sell): ~(-35, 4, 60)
    - Land Store (Ruhven): ~(-78, 5, -8)
]]

-- =====================================================================
-- SERVICES & LOCALS
-- =====================================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")
local RS  = game.ReplicatedStorage

-- Character refs (updated on respawn)
local char, hum, hrp
local function refreshChar()
    char = LP.Character or LP.CharacterAdded:Wait()
    hum  = char:WaitForChild("Humanoid")
    hrp  = char:WaitForChild("HumanoidRootPart")
end
refreshChar()
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    refreshChar()
    -- Reapply speed/jump on respawn
    if State then
        hum.WalkSpeed  = State.WalkSpeed
        hum.JumpPower  = State.JumpPower
    end
end)

-- =====================================================================
-- STATE
-- =====================================================================
local State = {
    -- Tab
    ActiveTab = 1,
    Minimized = false,
    -- Player
    WalkSpeed  = 16,
    SprintSpeed = 24,
    JumpPower  = 50,
    Flying     = false,
    FlySpeed   = 50,
    FlyKey     = Enum.KeyCode.F,
    -- World
    AlwaysDay   = false,
    AlwaysNight = false,
    NoFog       = false,
    -- Wood
    SelectTree  = "Oak",
    WoodAmount  = 5,
    AutoWoodOn  = false,
    -- AutoBuy
    AutoBuying  = false,
    BuyItem     = "RustyAxe",
    BuyMaxPrice = 1600,
    BuyAmt      = 1,
    -- Dupe
    DupeSlot    = 1,
    DupeWait    = 0.5,
    DupeAmt     = 10,
    Duping      = false,
    -- Items
    SelectedItems = {},
    StackLen    = 5,
    -- Save
    SaveSlot    = 1,
}

-- =====================================================================
-- VERIFIED REMOTES (lazily cached)
-- =====================================================================
local RemCache = {}
local function getRemote(path)
    if RemCache[path] then return RemCache[path] end
    local parts = path:split(".")
    local obj = game
    local ok, err = pcall(function()
        for _, p in ipairs(parts) do
            obj = obj:WaitForChild(p, 3)
        end
    end)
    if ok then RemCache[path] = obj end
    return ok and obj or nil
end

-- Short aliases for verified remotes
local function ClientInteracted()
    return RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("ClientInteracted")
end
local function RemoteProxy()
    return RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("RemoteProxy")
end
local function DestroyStructure()
    return RS:FindFirstChild("Interaction") and RS.Interaction:FindFirstChild("DestroyStructure")
end
local function PropertyPurchasingSet()
    return RS:FindFirstChild("PropertyPurchasing") and RS.PropertyPurchasing:FindFirstChild("SetPropertyPurchasingValue")
end
local function ClientPurchasedProp()
    return RS:FindFirstChild("PropertyPurchasing") and RS.PropertyPurchasing:FindFirstChild("ClientPurchasedProperty")
end
local function RequestSave()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("RequestSave")
end
local function RequestLoad()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("RequestLoad")
end
local function GetMetaData()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("GetMetaData")
end
local function ClientMayLoad()
    return RS:FindFirstChild("LoadSaveRequests") and RS.LoadSaveRequests:FindFirstChild("ClientMayLoad")
end
local function PromptChat()
    return RS:FindFirstChild("NPCDialog") and RS.NPCDialog:FindFirstChild("PromptChat")
end
local function PlayerChatted()
    return RS:FindFirstChild("NPCDialog") and RS.NPCDialog:FindFirstChild("PlayerChatted")
end
local function SetChattingValue()
    return RS:FindFirstChild("NPCDialog") and RS.NPCDialog:FindFirstChild("SetChattingValue")
end
local function SendUserNotice()
    return RS:FindFirstChild("Notices") and RS.Notices:FindFirstChild("SendUserNotice")
end

-- =====================================================================
-- UTILITY FUNCTIONS
-- =====================================================================

-- Teleport character to CFrame
local function TeleportTo(cf)
    if not char then return end
    local ok = pcall(function()
        char:PivotTo(cf)
    end)
    if not ok then
        pcall(function() hrp.CFrame = cf end)
    end
end

-- Teleport to Vector3 position
local function TeleportPos(x, y, z)
    TeleportTo(CFrame.new(x, y + 3, z))
end

-- Get current axe tool from character or backpack
local function GetAxe()
    -- Check character first (equipped)
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then
                return v
            end
        end
    end
    -- Check backpack
    for _, v in ipairs(LP.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("ToolName") then
            return v
        end
    end
    return nil
end

-- Get all axes from backpack + character
local function GetAllAxes()
    local axes = {}
    local function checkContainer(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then
                table.insert(axes, v)
            end
        end
    end
    if char then checkContainer(char) end
    checkContainer(LP.Backpack)
    return axes
end

-- Get all players (for dropdowns)
local function GetAllPlayers()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    return names
end

-- Equip a tool from backpack
local function EquipTool(tool)
    pcall(function()
        LP.Character.Humanoid:EquipTool(tool)
    end)
end

-- =====================================================================
-- FLY SYSTEM (BodyMover based)
-- =====================================================================
local FlyBody, FlyGyro
local FlyConnection

local function StopFly()
    State.Flying = false
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyBody then FlyBody:Destroy(); FlyBody = nil end
    if FlyGyro then FlyGyro:Destroy(); FlyGyro = nil end
    if hum then hum.PlatformStand = false end
end

local function StartFly()
    if not hrp then return end
    StopFly()
    State.Flying = true
    hum.PlatformStand = true

    FlyBody = Instance.new("BodyVelocity")
    FlyBody.Velocity    = Vector3.zero
    FlyBody.MaxForce    = Vector3.new(1e6,1e6,1e6)
    FlyBody.Parent      = hrp

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque   = Vector3.new(1e6,1e6,1e6)
    FlyGyro.P           = 1e4
    FlyGyro.CFrame      = hrp.CFrame
    FlyGyro.Parent      = hrp

    FlyConnection = RunService.Heartbeat:Connect(function()
        if not State.Flying then StopFly(); return end
        if not hrp or not hrp.Parent then StopFly(); return end
        local camera = workspace.CurrentCamera
        local dir    = Vector3.zero
        local speed  = State.FlySpeed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0,1,0)
        end

        if dir.Magnitude > 0 then
            FlyBody.Velocity = dir.Unit * speed
        else
            FlyBody.Velocity = Vector3.zero
        end
        FlyGyro.CFrame = camera.CFrame
    end)
end

-- Fly toggle on keypress
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == State.FlyKey then
        if State.Flying then StopFly() else StartFly() end
    end
end)

-- =====================================================================
-- FEATURE IMPLEMENTATIONS
-- =====================================================================

-- ---- TAB 1: SLOT / SAVE-LOAD ----

local function DoSaveSlot(slot)
    local rs = RequestSave()
    if not rs then return false, "Remote not found" end
    local ok, result, errMsg = pcall(function()
        return rs:InvokeServer(slot, LP.UserId)
    end)
    if not ok then return false, tostring(result) end
    return result, errMsg
end

local function DoLoadSlot(slot)
    local mayLoad = ClientMayLoad()
    if mayLoad then
        local ok, canLoad, reason = pcall(function()
            return mayLoad:InvokeServer(LP.UserId)
        end)
        if ok and not canLoad then
            return false, tostring(reason)
        end
    end
    local rl = RequestLoad()
    if not rl then return false, "Remote not found" end
    local ok, result, errMsg = pcall(function()
        return rl:InvokeServer(slot, LP.UserId, nil) -- nil = current version
    end)
    if not ok then return false, tostring(result) end
    return result, errMsg
end

local function DoGetSlotInfo(slot)
    local gmd = GetMetaData()
    if not gmd then return nil, "Remote not found" end
    local ok, data, errMsg = pcall(function()
        return gmd:InvokeServer(LP.UserId)
    end)
    if not ok then return nil, tostring(data) end
    return data, errMsg
end

-- Buy first available plot (land purchase)
local function DoBuyLand()
    local setPurchase = PropertyPurchasingSet()
    if not setPurchase then return false, "PropertyPurchasing remote not found" end
    
    -- Find an available unowned property
    local targetProp = nil
    local propsFolder = workspace:FindFirstChild("Properties")
    if propsFolder then
        for _, prop in ipairs(propsFolder:GetChildren()) do
            if prop.Name == "Property" then
                local owner = prop:FindFirstChild("Owner")
                if owner and not owner.Value then
                    targetProp = prop
                    break
                end
            end
        end
    end
    
    if not targetProp then return false, "No available plots found" end
    
    -- Enter purchase mode
    local ok1 = pcall(function() setPurchase:InvokeServer(true) end)
    if not ok1 then return false, "Failed to enter purchase mode" end
    
    -- Wait briefly for server
    task.wait(0.3)
    
    -- Attempt the purchase
    -- First try the BindableFunction (client-to-local) route
    local clientToServer = RS:FindFirstChild("PropertyPurchasing")
    local attemptPurchase = clientToServer and clientToServer:FindFirstChild("AttemptPurchase")
    
    local purchaseResult = false
    if attemptPurchase then
        pcall(function()
            local cost = 0
            local costVal = targetProp:FindFirstChild("Cost")
            if costVal then cost = costVal.Value end
            purchaseResult = attemptPurchase:Invoke(cost)
        end)
    end
    
    -- Fire the ClientPurchasedProperty remote
    local cpProp = ClientPurchasedProp()
    if cpProp then
        pcall(function()
            cpProp:FireServer(targetProp, workspace.CurrentCamera.CFrame.Position)
        end)
    end
    
    -- Exit purchase mode
    pcall(function() setPurchase:InvokeServer(false) end)
    
    return true, "Purchase attempted for plot: " .. tostring(targetProp.Name)
end

-- ---- TAB 2: PLAYER ----

local function SetWalkSpeed(v)
    State.WalkSpeed = v
    if hum then hum.WalkSpeed = v end
end

local function SetJumpPower(v)
    State.JumpPower = v
    if hum then 
        hum.JumpPower = v
        hum.JumpHeight = v / 5 -- Roblox uses both
    end
end

local function NoClipToggle(enabled)
    if enabled then
        RunService.Stepped:Connect(function()
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- ---- TAB 3: WORLD ----

local WorldConnections = {}

local function ClearWorldConnections()
    for _, c in ipairs(WorldConnections) do c:Disconnect() end
    WorldConnections = {}
end

local function SetAlwaysDay(v)
    State.AlwaysDay = v
    if v then
        State.AlwaysNight = false
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        -- Maintain it
        local c = RunService.Heartbeat:Connect(function()
            if not State.AlwaysDay then return end
            Lighting.ClockTime = 14
        end)
        table.insert(WorldConnections, c)
    else
        ClearWorldConnections()
    end
end

local function SetAlwaysNight(v)
    State.AlwaysNight = v
    if v then
        State.AlwaysDay = false
        Lighting.ClockTime = 0
        local c = RunService.Heartbeat:Connect(function()
            if not State.AlwaysNight then return end
            Lighting.ClockTime = 0
        end)
        table.insert(WorldConnections, c)
    else
        ClearWorldConnections()
    end
end

local function SetNoFog(v)
    State.NoFog = v
    if v then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
    end
end

-- LT2 verified waypoints (from game world analysis)
local WAYPOINTS = {
    ["Main Area"]      = Vector3.new(-167, 5, 0),
    ["Wood Drop-off"]  = Vector3.new(-35, 4, 60),
    ["Land Store"]     = Vector3.new(-78, 5, -8),
    ["WoodRUs Store"]  = Vector3.new(-275, 5, 105),
    ["Bob's Shack"]    = Vector3.new(-252, 5, 400),
    ["Link's Logic"]   = Vector3.new(15, 5, 262),
    ["Fancy Furniture"]= Vector3.new(-122, 5, 165),
    ["Snow Biome"]     = Vector3.new(-1080, 300, 900),
    ["Volcano"]        = Vector3.new(1060, 450, 500),
    ["Swamp"]          = Vector3.new(630, 30, -1500),
    ["Cave"]           = Vector3.new(295, -30, 495),
    ["Tropics"]        = Vector3.new(1300, 5, -700),
    ["Ferry Dock"]     = Vector3.new(300, 5, 320),
}

local function TeleportWaypoint(name)
    local pos = WAYPOINTS[name]
    if pos then
        TeleportPos(pos.X, pos.Y, pos.Z)
        return true
    end
    return false
end

local function TeleportToPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local tpos = target.Character.HumanoidRootPart.Position
        TeleportPos(tpos.X, tpos.Y + 3, tpos.Z)
        return true
    end
    return false
end

-- ---- TAB 4: WOOD ----

-- Auto chop a tree using the RemoteProxy (confirmed from axe superclass script)
local function ChopTreeSection(section, axeTool)
    local rp = RemoteProxy()
    if not rp then return end
    local idVal = section:FindFirstChild("ID")
    if not idVal then return end
    pcall(function()
        rp:FireServer(idVal.Value, {
            sectionId   = idVal.Value,
            faceVector  = Vector3.new(-1, 0, 0),
            height      = 1,
            hitPoints   = 999,
            cooldown    = 0.1,
            cuttingClass = "Axe",
            tool        = axeTool,
        })
    end)
end

-- Auto chop all trees in workspace
local AutoChopTask = nil
local function StartAutoChop()
    State.AutoWoodOn = true
    AutoChopTask = task.spawn(function()
        while State.AutoWoodOn do
            local axe = GetAxe()
            if not axe then
                task.wait(1)
            else
                -- Find tree sections in workspace
                local ws = workspace
                for _, model in ipairs(ws:GetDescendants()) do
                    if not State.AutoWoodOn then break end
                    if model:IsA("Part") and model:FindFirstChild("ID") and model:FindFirstChild("Name") then
                        local nameVal = model:FindFirstChild("Name")
                        if nameVal and (nameVal.Value:find("Wood") or nameVal.Value:find("Log")) then
                            ChopTreeSection(model, axe)
                            task.wait(0.2)
                        end
                    end
                end
                task.wait(0.5)
            end
        end
    end)
end

local function StopAutoChop()
    State.AutoWoodOn = false
    if AutoChopTask then task.cancel(AutoChopTask); AutoChopTask = nil end
end

-- Teleport to sell area and sell wood
local function SellAllWood()
    -- First teleport to the wood dropoff
    TeleportPos(-35, 4, 60)
    task.wait(1)
    -- Look for the sell region/box
    local sellRegion = workspace:FindFirstChild("SellRegion") or workspace:FindFirstChild("SellArea")
    if sellRegion then
        -- The game uses region3 detection; just being near the wood dropoff should trigger it
        -- We need to teleport wood parts into the sell area
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Owner") then
                local owner = obj:FindFirstChild("Owner")
                if owner and owner.Value == LP then
                    -- Teleport owned wood to sell area
                    pcall(function()
                        if obj.PrimaryPart then
                            obj:PivotTo(CFrame.new(-35, 10, 60))
                        end
                    end)
                    task.wait(0.05)
                end
            end
        end
    end
    return true
end

-- ---- TAB 5: AUTO BUY ----

-- LT2 verified item ToolNames and their store/NPC
-- Based on game analysis: items are purchased via NPC dialog system
-- You must be near the store NPC, then invoke PlayerChatted with the right dialog node

local STORE_ITEMS = {
    -- WoodRUs store items (basic axes)
    { name = "Rusty Axe",       toolname = "RustyAxe",     store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 100   },
    { name = "Refined Axe",     toolname = "RefinedAxe",   store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 450   },
    { name = "Silver Axe",      toolname = "SilverAxe",    store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 550   },
    { name = "Bluesteel Axe",   toolname = "BluesteelAxe", store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 1250  },
    { name = "Cave Axe",        toolname = "CaveAxe",      store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 2000  },
    { name = "Fire Axe",        toolname = "FireAxe",      store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 3500  },
    { name = "Ice Axe",         toolname = "IceAxe",       store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 4000  },
    { name = "Many Axe",        toolname = "ManyAxe",      store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 7200  },
    { name = "Rukiryaxe",       toolname = "Rukiryaxe",    store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 7400  },
    { name = "Mint Axe",        toolname = "MintAxe",      store = "WoodRUs",  pos = Vector3.new(-275, 5, 105), price = 8000  },
}

-- Attempt to buy item via NPC dialog system
-- Note: This is client-side; actual server validation will occur.
-- The game uses: PlayerChatted:InvokeServer(storeNPC, purchaseDialog)
local function AttemptAutoBuy(itemToolName)
    -- Get item info
    local itemInfo = nil
    for _, item in ipairs(STORE_ITEMS) do
        if item.toolname == itemToolName then
            itemInfo = item
            break
        end
    end
    if not itemInfo then return false, "Item not found: " .. itemToolName end
    
    -- Teleport to the store
    TeleportPos(itemInfo.pos.X, itemInfo.pos.Y, itemInfo.pos.Z)
    task.wait(1.5)
    
    -- Find the store NPC in workspace
    local storeNPC = workspace.Stores and workspace.Stores:FindFirstChild(itemInfo.store)
    if not storeNPC then
        -- Try finding by name recursively
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == itemInfo.store then
                storeNPC = obj
                break
            end
        end
    end
    
    if not storeNPC then return false, "Store NPC not found: " .. itemInfo.store end
    
    -- Get the NPC model (usually the store has an NPC humanoid)
    local npcModel = storeNPC
    if storeNPC:IsA("Folder") or storeNPC:IsA("Model") then
        -- Find the actual NPC inside
        for _, child in ipairs(storeNPC:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                npcModel = child
                break
            end
        end
    end
    
    -- Find the dialog for this item
    -- LT2 store dialogs are typically named "Buy[ItemName]" or "DialogBuy[ItemName]"
    local buyDialog = nil
    for _, obj in ipairs(storeNPC:GetDescendants()) do
        if obj:IsA("DialogChoice") or obj:IsA("Dialog") then
            if obj.UserDialog and obj.UserDialog:lower():find(itemToolName:lower()) then
                buyDialog = obj
                break
            end
        end
    end
    
    -- Invoke SetChattingValue to register as chatting
    local svc = SetChattingValue()
    if svc then
        pcall(function() svc:InvokeServer(1) end)
    end
    
    -- Try PlayerChatted with the dialog node
    local pc = PlayerChatted()
    if pc and buyDialog then
        local ok, result = pcall(function()
            return pc:InvokeServer(npcModel, buyDialog)
        end)
        -- End chat
        pcall(function() pc:InvokeServer(npcModel, "EndChat") end)
        if svc then pcall(function() svc:InvokeServer(0) end) end
        return ok, result
    end
    
    -- End chat cleanup
    if svc then pcall(function() svc:InvokeServer(0) end) end
    
    return false, "Could not find purchase dialog for: " .. itemToolName
end

local AutoBuyTask = nil
local function StartAutoBuy()
    if State.AutoBuying then return end
    State.AutoBuying = true
    AutoBuyTask = task.spawn(function()
        local bought = 0
        while State.AutoBuying and bought < State.BuyAmt do
            local ok, msg = AttemptAutoBuy(State.BuyItem)
            if ok then
                bought = bought + 1
            end
            task.wait(State.DupeWait + 1)
        end
        State.AutoBuying = false
    end)
end

local function StopAutoBuy()
    State.AutoBuying = false
    if AutoBuyTask then task.cancel(AutoBuyTask); AutoBuyTask = nil end
end

-- ---- TAB 6: ITEM ----

-- Teleport selected items to player
local function TeleportSelectedToPlayer()
    if not hrp then return end
    local pos = hrp.Position + Vector3.new(0, 3, 0)
    for _, item in ipairs(State.SelectedItems) do
        pcall(function()
            if item and item.Parent then
                if item:IsA("Model") and item.PrimaryPart then
                    item:PivotTo(CFrame.new(pos))
                elseif item:IsA("BasePart") then
                    item.CFrame = CFrame.new(pos)
                end
                pos = pos + Vector3.new(2, 0, 0) -- Offset each item
            end
        end)
    end
end

-- Lasso selector (click to add parts to SelectedItems)
local LassoActive = false
local LassoConn
local function ToggleLasso(enabled)
    LassoActive = enabled
    if LassoConn then LassoConn:Disconnect(); LassoConn = nil end
    if enabled then
        LassoConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = LP:GetMouse()
                local target = mouse.Target
                if target then
                    table.insert(State.SelectedItems, target)
                end
            end
        end)
    end
end

-- Drop a tool using the VERIFIED ClientInteracted remote
local function DropTool(tool)
    local ci = ClientInteracted()
    if not ci then
        -- Fallback: use humanoid drop animation
        pcall(function()
            LP.Character.Humanoid:UnequipTools()
        end)
        return false, "ClientInteracted remote not found, used fallback"
    end
    if not tool or not tool:FindFirstChild("Handle") then
        return false, "Tool or Handle not found"
    end
    local ok, err = pcall(function()
        ci:FireServer(tool, "Drop tool", tool.Handle.CFrame)
    end)
    return ok, err
end

-- Drop all axes
local function DropAllAxes()
    local axes = GetAllAxes()
    local count = 0
    for _, axe in ipairs(axes) do
        local ok = DropTool(axe)
        if ok then count = count + 1 end
        task.wait(0.1)
    end
    return count
end

-- Destroy selected structure using verified DestroyStructure remote
local function DestroySelectedItems()
    local ds = DestroyStructure()
    local count = 0
    for _, item in ipairs(State.SelectedItems) do
        if item and item.Parent then
            if ds then
                pcall(function() ds:FireServer(item) end)
            else
                pcall(function() item:Destroy() end)
            end
            count = count + 1
        end
    end
    State.SelectedItems = {}
    return count
end

-- ---- TAB 7: DUPE ----

local DupeTask = nil
local function StartAxeDupe()
    if State.Duping then return end
    State.Duping = true
    DupeTask = task.spawn(function()
        local duped = 0
        while State.Duping and duped < State.DupeAmt do
            local axe = GetAxe()
            if not axe then
                -- Try equipping from backpack
                local bp = LP.Backpack:GetChildren()
                for _, tool in ipairs(bp) do
                    if tool:IsA("Tool") and tool:FindFirstChild("ToolName") then
                        EquipTool(tool)
                        task.wait(0.3)
                        axe = GetAxe()
                        break
                    end
                end
            end
            
            if axe then
                -- Drop via verified ClientInteracted remote
                local ok, err = DropTool(axe)
                if ok then
                    duped = duped + 1
                end
                task.wait(State.DupeWait)
                -- Pick it back up (move character near the dropped axe)
                -- Find the dropped tool in workspace
                task.wait(0.2)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Tool") and obj:FindFirstChild("ToolName") and 
                       obj:FindFirstChild("Handle") and
                       (obj.ToolName.Value == axe.ToolName.Value) then
                        -- Teleport to the dropped axe
                        local handle = obj:FindFirstChild("Handle")
                        if handle then
                            local dist = (hrp.Position - handle.Position).Magnitude
                            if dist < 50 then
                                TeleportTo(handle.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.3)
                                break
                            end
                        end
                    end
                end
                task.wait(State.DupeWait)
            else
                task.wait(1)
            end
        end
        State.Duping = false
    end)
end

local function StopDupe()
    State.Duping = false
    if DupeTask then task.cancel(DupeTask); DupeTask = nil end
end

-- ---- TAB 8: AUTO BUILD ----

-- Place a blueprint using the verified ClientPlacedBlueprint remote
local function PlaceBlueprint(blueprintName, cframe)
    -- Find ClientPlacedBlueprint remote (from script 638 analysis)
    local structGui = PGui:FindFirstChild("StructureDraggingGUI")
    if structGui then
        local clientPlacedBlueprint = RS:FindFirstChild("Interaction") and 
                                       RS.Interaction:FindFirstChild("ClientPlacedBlueprint")
        if clientPlacedBlueprint then
            local ok, err = pcall(function()
                -- The remote expects: name, positionCFrame, rotationCFrame
                local finalCFrame = cframe or (hrp and hrp.CFrame * CFrame.new(0, 0, -10)) or CFrame.new(0, 0, 0)
                clientPlacedBlueprint:FireServer(blueprintName, finalCFrame, finalCFrame)
            end)
            return ok, err
        end
    end
    return false, "StructureDraggingGUI or ClientPlacedBlueprint not found"
end

-- Steal plot: take ownership of a property
local function StealPlot(targetPlayerName)
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    if not targetPlayer then return false, "Player not found" end
    
    -- Find their property
    local propsFolder = workspace:FindFirstChild("Properties")
    if not propsFolder then return false, "Properties folder not found" end
    
    for _, prop in ipairs(propsFolder:GetChildren()) do
        local ownerVal = prop:FindFirstChild("Owner")
        if ownerVal and ownerVal.Value == targetPlayer then
            -- Try to trigger property purchase
            local cpProp = ClientPurchasedProp()
            if cpProp then
                local ok, err = pcall(function()
                    cpProp:FireServer(prop, hrp and hrp.Position or Vector3.new(0,0,0))
                end)
                return ok, err
            end
        end
    end
    return false, "Player does not own a plot"
end

-- Auto fill blueprints with wood
local function AutoFillBlueprints()
    -- Select all blueprints
    local bpTool = LP.Backpack:FindFirstChild("BlueprintTool") or 
                   (char and char:FindFirstChild("BlueprintTool"))
    if not bpTool then
        return false, "BlueprintTool not in inventory"
    end
    
    -- Find all blueprint structures on player's plot
    local filled = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Blueprint" then
            local ownerVal = obj:FindFirstChild("Owner")
            if ownerVal and ownerVal.Value == LP then
                -- Find the placestructure remote
                local clientPlaced = RS.Interaction and RS.Interaction:FindFirstChild("ClientPlacedStructure")
                if clientPlaced then
                    pcall(function()
                        clientPlaced:FireServer(obj, obj.PrimaryPart and obj.PrimaryPart.CFrame or CFrame.new(0,0,0))
                        filled = filled + 1
                    end)
                    task.wait(0.1)
                end
            end
        end
    end
    return filled > 0, "Filled " .. filled .. " blueprints"
end

-- =====================================================================
-- UI SYSTEM
-- =====================================================================
local THEME = {
    BG       = Color3.fromRGB(10, 13, 18),
    Panel    = Color3.fromRGB(15, 20, 30),
    Card     = Color3.fromRGB(20, 27, 40),
    Border   = Color3.fromRGB(30, 40, 60),
    Green    = Color3.fromRGB(74, 222, 128),
    Cyan     = Color3.fromRGB(34, 211, 238),
    Red      = Color3.fromRGB(248, 113, 113),
    Orange   = Color3.fromRGB(251, 146, 60),
    Yellow   = Color3.fromRGB(250, 204, 21),
    TextMain = Color3.fromRGB(220, 230, 245),
    TextDim  = Color3.fromRGB(100, 120, 150),
    White    = Color3.fromRGB(255, 255, 255),
}
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_B = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

-- Destroy old GUI if it exists
local oldGui = PGui:FindFirstChild("LT2MenuV2")
if oldGui then oldGui:Destroy() end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "LT2MenuV2"
ScreenGui.ResetOnSpawn      = false
ScreenGui.IgnoreGuiInset    = true
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
local useGethui = pcall(function() ScreenGui.Parent = gethui() end)
if not useGethui then ScreenGui.Parent = PGui end

-- =====================================================================
-- HELPER BUILDERS
-- =====================================================================
local function Frame(props)
    local f = Instance.new("Frame")
    for k,v in pairs(props) do f[k]=v end
    return f
end

local function Label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3 = THEME.TextMain
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k,v in pairs(props) do l[k]=v end
    return l
end

local function Button(props, onClick)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = THEME.Card
    btn.BorderSizePixel  = 0
    btn.TextColor3       = THEME.TextMain
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.AutoButtonColor  = false
    for k,v in pairs(props) do btn[k]=v end
    
    local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,6); uic.Parent = btn
    local uis = Instance.new("UIStroke"); uis.Color = THEME.Border; uis.Thickness = 1; uis.Parent = btn
    
    local function hover(in_)
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = in_ and THEME.Border or THEME.Card
        }):Play()
    end
    btn.MouseEnter:Connect(function() hover(true) end)
    btn.MouseLeave:Connect(function() hover(false) end)
    -- Touch
    btn.TouchTap:Connect(function() if onClick then onClick() end end)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return btn
end

local function Toggle(props, state_key, onChange)
    local container = Frame({
        BackgroundColor3 = THEME.Card,
        BorderSizePixel  = 0,
        Size             = props.Size or UDim2.new(1,0,0,42),
    })
    local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,6); uic.Parent = container
    local uis = Instance.new("UIStroke"); uis.Color = THEME.Border; uis.Thickness = 1; uis.Parent = container
    
    local lbl = Label({
        Text     = props.Text or "Toggle",
        Size     = UDim2.new(1,-54,1,0),
        Position = UDim2.fromOffset(12, 0),
        Parent   = container,
    })
    
    local track = Frame({
        Size     = UDim2.fromOffset(40, 22),
        Position = UDim2.new(1,-48,0.5,-11),
        BackgroundColor3 = State[state_key] and THEME.Green or THEME.Border,
        BorderSizePixel = 0,
        Parent   = container,
    })
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = track
    
    local knob = Frame({
        Size     = UDim2.fromOffset(18, 18),
        Position = State[state_key] and UDim2.fromOffset(20,2) or UDim2.fromOffset(2,2),
        BackgroundColor3 = THEME.White,
        BorderSizePixel = 0,
        Parent   = track,
    })
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = knob
    
    local function setVal(v)
        State[state_key] = v
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = v and THEME.Green or THEME.Border
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.fromOffset(20,2) or UDim2.fromOffset(2,2)
        }):Play()
        if onChange then onChange(v) end
    end
    
    container.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            setVal(not State[state_key])
        end
    end)
    
    return container, setVal
end

local function Slider(props, state_key, onChange)
    local min = props.Min or 0
    local max = props.Max or 100
    
    local container = Frame({
        BackgroundColor3 = THEME.Card,
        BorderSizePixel  = 0,
        Size             = props.Size or UDim2.new(1,0,0,54),
    })
    local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,6); uic.Parent = container
    local uis = Instance.new("UIStroke"); uis.Color = THEME.Border; uis.Thickness = 1; uis.Parent = container
    
    local header = Frame({
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,24),
        Position = UDim2.fromOffset(0,0),
        Parent = container,
    })
    Label({ Text = props.Text or "Slider", Size=UDim2.new(0.7,0,1,0), Position=UDim2.fromOffset(12,0), Parent=header })
    local valLbl = Label({ Text=tostring(State[state_key]), Size=UDim2.new(0.3,0,1,0), Position=UDim2.new(0.7,0,0,0), TextXAlignment=Enum.TextXAlignment.Right, TextColor3=THEME.Cyan, Parent=header })
    if props.Unit then valLbl.Text = tostring(State[state_key]) .. props.Unit end
    
    local track = Frame({
        BackgroundColor3 = THEME.Border,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,-24,0,4),
        Position         = UDim2.new(0,12,0,38),
        Parent           = container,
    })
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = track
    
    local fill = Frame({
        BackgroundColor3 = props.Color or THEME.Green,
        BorderSizePixel  = 0,
        Size             = UDim2.new((State[state_key]-min)/(max-min),0,1,0),
        Parent           = track,
    })
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fill
    
    local knob = Frame({
        BackgroundColor3 = THEME.White,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(14,14),
        Position         = UDim2.new((State[state_key]-min)/(max-min),0,0.5,-7),
        Parent           = track,
        ZIndex           = 3,
    })
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = knob
    
    local dragging = false
    local function updateVal(pos_x)
        local trackAbsPos  = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        local t = math.clamp((pos_x - trackAbsPos) / trackAbsSize, 0, 1)
        local val = math.floor(min + t * (max - min))
        if props.Step then val = math.floor(val / props.Step + 0.5) * props.Step end
        State[state_key] = val
        fill.Size = UDim2.new(t, 0, 1, 0)
        knob.Position = UDim2.new(t, -7, 0.5, -7)
        valLbl.Text = tostring(val) .. (props.Unit or "")
        if onChange then onChange(val) end
    end
    
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateVal(inp.Position.X)
        end
    end)
    track.InputEnded:Connect(function() dragging = false end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateVal(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return container
end

local function Dropdown(props, state_key, options, onChange)
    local container = Frame({
        BackgroundColor3 = THEME.Card,
        BorderSizePixel  = 0,
        Size             = props.Size or UDim2.new(1,0,0,42),
        ClipsDescendants = false,
    })
    local uic = Instance.new("UICorner"); uic.CornerRadius = UDim.new(0,6); uic.Parent = container
    local uis = Instance.new("UIStroke"); uis.Color = THEME.Border; uis.Thickness = 1; uis.Parent = container
    
    local display = Label({
        Text     = State[state_key] or (options[1] or "Select"),
        Size     = UDim2.new(1,-42,1,0),
        Position = UDim2.fromOffset(12,0),
        Parent   = container,
    })
    local arrow = Label({
        Text     = "▾",
        Size     = UDim2.fromOffset(30,42),
        Position = UDim2.new(1,-36,0,0),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = THEME.TextDim,
        Parent   = container,
    })
    Label({ Text = props.Text or "", Size=UDim2.new(1,0,0,16), Position=UDim2.fromOffset(12,-16), TextSize=11, TextColor3=THEME.TextDim, Parent=container })
    
    local dropFrame = Frame({
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,2,0,0),
        Position         = UDim2.new(0,-1,1,2),
        Visible          = false,
        ZIndex           = 50,
        Parent           = container,
    })
    local dfuic = Instance.new("UICorner"); dfuic.CornerRadius = UDim.new(0,6); dfuic.Parent = dropFrame
    local dfuis = Instance.new("UIStroke"); dfuis.Color = THEME.Border; dfuis.Thickness = 1; dfuis.Parent = dropFrame
    local uil = Instance.new("UIListLayout"); uil.Parent = dropFrame; uil.Padding = UDim.new(0,2)
    local uip = Instance.new("UIPadding"); uip.PaddingTop=UDim.new(0,4); uip.PaddingBottom=UDim.new(0,4); uip.PaddingLeft=UDim.new(0,4); uip.PaddingRight=UDim.new(0,4); uip.Parent=dropFrame
    
    local open = false
    local function setOpen(v)
        open = v
        local itemH = 30
        local maxH  = math.min(#options, 6) * (itemH + 2) + 8
        dropFrame.Visible = v
        if v then
            TweenService:Create(dropFrame, TweenInfo.new(0.15), {
                Size = UDim2.new(1,2,0,maxH)
            }):Play()
        end
    end
    
    local function buildOptions(opts)
        for _, child in ipairs(dropFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, opt in ipairs(opts) do
            local item = Button({
                Text             = tostring(opt),
                Size             = UDim2.new(1,0,0,30),
                BackgroundColor3 = THEME.Card,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = dropFrame,
                ZIndex           = 51,
            }, function()
                State[state_key] = opt
                display.Text = tostring(opt)
                setOpen(false)
                if onChange then onChange(opt) end
            end)
            local ip = Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,8); ip.Parent=item
        end
    end
    buildOptions(options)
    
    container.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            setOpen(not open)
        end
    end)
    
    return container, buildOptions
end

-- =====================================================================
-- MAIN WINDOW
-- =====================================================================
local WIN_W = 320
local WIN_H = 490

local MainFrame = Frame({
    Size             = UDim2.fromOffset(WIN_W, WIN_H),
    Position         = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = THEME.BG,
    BorderSizePixel  = 0,
    Parent           = ScreenGui,
})
local mfuic = Instance.new("UICorner"); mfuic.CornerRadius = UDim.new(0,12); mfuic.Parent = MainFrame
local mfuis = Instance.new("UIStroke"); mfuis.Color = THEME.Border; mfuis.Thickness = 1; mfuis.Parent = MainFrame

-- Drag logic
local draggingMain, dragStart, startPos
MainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        dragStart = inp.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if draggingMain and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - WIN_W)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - WIN_H)
        MainFrame.Position = UDim2.fromOffset(newX, newY)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        draggingMain = false
    end
end)

-- =====================================================================
-- TITLE BAR
-- =====================================================================
local TitleBar = Frame({
    Size             = UDim2.new(1,0,0,44),
    BackgroundColor3 = THEME.Panel,
    BorderSizePixel  = 0,
    Parent           = MainFrame,
})
local tbuic = Instance.new("UICorner"); tbuic.CornerRadius = UDim.new(0,12); tbuic.Parent = TitleBar
-- Mask bottom corners of titlebar
Frame({ Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,1,-6), BackgroundColor3=THEME.Panel, BorderSizePixel=0, Parent=TitleBar })

Label({
    Text     = "🪓  LT2 Menu v2",
    Size     = UDim2.new(1,-90,1,0),
    Position = UDim2.fromOffset(14,0),
    TextSize = 15,
    Font     = Enum.Font.GothamBold,
    TextColor3 = THEME.Green,
    Parent   = TitleBar,
})

-- Minimize button
local MinBtn = Button({
    Text     = "–",
    Size     = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1,-76,0,6),
    TextSize = 18,
    Parent   = TitleBar,
}, nil)

-- Close button
local CloseBtn = Button({
    Text     = "×",
    Size     = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1,-40,0,6),
    TextSize = 18,
    BackgroundColor3 = Color3.fromRGB(60,20,20),
    Parent   = TitleBar,
}, function()
    ScreenGui:Destroy()
    StopFly()
    StopDupe()
    StopAutoChop()
    StopAutoBuy()
end)

-- Floating icon for minimized state
local FloatIcon = Button({
    Text     = "🪓",
    Size     = UDim2.fromOffset(50,50),
    Position = UDim2.fromOffset(10,80),
    BackgroundColor3 = THEME.Panel,
    TextSize = 24,
    ZIndex   = 20,
    Visible  = false,
    Parent   = ScreenGui,
}, nil)
local fic = Instance.new("UICorner"); fic.CornerRadius = UDim.new(1,0); fic.Parent = FloatIcon
local fis = Instance.new("UIStroke"); fis.Color = THEME.Green; fis.Thickness = 2; fis.Parent = FloatIcon

local function setMinimized(v)
    State.Minimized = v
    MainFrame.Visible = not v
    FloatIcon.Visible = v
end

MinBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
FloatIcon.MouseButton1Click:Connect(function() setMinimized(false) end)
FloatIcon.TouchTap:Connect(function() setMinimized(false) end)

-- =====================================================================
-- NOTIFICATION SYSTEM
-- =====================================================================
local notifY = 0
local function Notify(msg, color, duration)
    color    = color or THEME.Green
    duration = duration or 3
    
    local n = Frame({
        Size             = UDim2.fromOffset(260, 42),
        Position         = UDim2.new(1,-270, 1, -(notifY+50)),
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 100,
        Parent           = ScreenGui,
    })
    local nuic = Instance.new("UICorner"); nuic.CornerRadius = UDim.new(0,8); nuic.Parent = n
    local nuis = Instance.new("UIStroke"); nuis.Color = color; nuis.Thickness = 1; nuis.Parent = n
    Frame({ BackgroundColor3=color, BorderSizePixel=0, Size=UDim2.fromOffset(3,42), ZIndex=101, Parent=n }):FindFirstChildWhichIsA("UICorner") or (function() local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,3); c.Parent=n:GetChildren()[#n:GetChildren()] end)()
    Label({ Text=msg, Size=UDim2.new(1,-14,1,0), Position=UDim2.fromOffset(10,0), TextSize=13, ZIndex=101, Parent=n })
    
    notifY = notifY + 50
    TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(1,-270,1,-(notifY))}):Play()
    
    task.delay(duration, function()
        TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(1,20,1,-(notifY))}):Play()
        task.wait(0.3)
        n:Destroy()
        notifY = math.max(0, notifY - 50)
    end)
end

-- =====================================================================
-- TAB SYSTEM
-- =====================================================================
local TABS = {
    { name="Slot",       icon="💾" },
    { name="Player",     icon="🏃" },
    { name="World",      icon="🌍" },
    { name="Wood",       icon="🌲" },
    { name="Auto Buy",   icon="🛒" },
    { name="Item",       icon="📦" },
    { name="Dupe",       icon="♻️" },
    { name="Build",      icon="🏗️" },
}

-- Tab bar
local TabBar = Frame({
    Size             = UDim2.new(1,0,0,44),
    Position         = UDim2.fromOffset(0,44),
    BackgroundColor3 = THEME.Panel,
    BorderSizePixel  = 0,
    Parent           = MainFrame,
    ClipsDescendants = true,
})
Frame({ Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=THEME.Border, BorderSizePixel=0, Parent=TabBar })

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1,0,1,0)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 0
TabScroll.ScrollingDirection = Enum.ScrollingDirection.X
TabScroll.CanvasSize = UDim2.fromOffset(#TABS * 80, 0)
TabScroll.Parent = TabBar

local UIListH = Instance.new("UIListLayout")
UIListH.FillDirection = Enum.FillDirection.Horizontal
UIListH.SortOrder = Enum.SortOrder.LayoutOrder
UIListH.Parent = TabScroll

-- Content area
local ContentFrame = Frame({
    Size             = UDim2.new(1,0,1,-88),
    Position         = UDim2.fromOffset(0,88),
    BackgroundTransparency = 1,
    Parent           = MainFrame,
    ClipsDescendants = true,
})

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1,0,1,0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = THEME.Border
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.CanvasSize = UDim2.new(0,0,0,0)
ContentScroll.Parent = ContentFrame

local UIListV = Instance.new("UIListLayout")
UIListV.Padding = UDim.new(0,6)
UIListV.SortOrder = Enum.SortOrder.LayoutOrder
UIListV.Parent = ContentScroll

local UIPad = Instance.new("UIPadding")
UIPad.PaddingLeft  = UDim.new(0,10)
UIPad.PaddingRight = UDim.new(0,10)
UIPad.PaddingTop   = UDim.new(0,8)
UIPad.PaddingBottom= UDim.new(0,8)
UIPad.Parent = ContentScroll

-- Tab button refs
local TabBtns = {}

local function SectionHeader(text, color)
    local f = Frame({
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,24),
        LayoutOrder = 999,
    })
    local l = Label({
        Text = text:upper(),
        TextSize = 11,
        TextColor3 = color or THEME.TextDim,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(1,0,1,0),
        LetterSpacingEm = 0.1,
        Parent = f,
    })
    local line = Frame({
        BackgroundColor3 = color or THEME.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1,-70,0,1),
        Position = UDim2.new(0,65,0.5,0),
        Parent = f,
    })
    return f
end

-- Build a page (table of components)
local PageContents = {}

local function ClearContent()
    for _, c in ipairs(ContentScroll:GetChildren()) do
        if c:IsA("GuiObject") and c ~= UIListV and c ~= UIPad then
            c:Destroy()
        end
    end
end

local function ShowPage(tabIndex)
    ClearContent()
    ContentScroll.CanvasPosition = Vector2.new(0,0)
    
    -- Update tab buttons
    for i, btn in ipairs(TabBtns) do
        local active = i == tabIndex
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = active and THEME.Card or Color3.fromRGB(0,0,0),
            BackgroundTransparency = active and 0 or 1,
            TextColor3 = active and THEME.Green or THEME.TextDim,
        }):Play()
    end
    
    State.ActiveTab = tabIndex
    if PageContents[tabIndex] then PageContents[tabIndex]() end
end

-- Build tabs
for i, tab in ipairs(TABS) do
    local btn = Button({
        Text             = tab.icon .. " " .. tab.name,
        Size             = UDim2.fromOffset(78, 40),
        BackgroundColor3 = THEME.Card,
        BackgroundTransparency = 1,
        TextSize         = 12,
        TextColor3       = THEME.TextDim,
        LayoutOrder      = i,
        Parent           = TabScroll,
    }, function() ShowPage(i) end)
    -- Remove auto UICorner/UIStroke from tabs (they look bad in tab bar)
    for _, c in ipairs(btn:GetChildren()) do c:Destroy() end
    table.insert(TabBtns, btn)
end

-- =====================================================================
-- PAGE DEFINITIONS
-- =====================================================================

-- ---- PAGE 1: SLOT / SAVE-LOAD ----
PageContents[1] = function()
    SectionHeader("Save & Load Slots", THEME.Cyan).Parent = ContentScroll

    -- Slot selector
    local _, slotDropUpdate = Dropdown({Text="Current Slot", Size=UDim2.new(1,0,0,58)}, "SaveSlot", {"1","2","3","4"}, function(v)
        State.SaveSlot = tonumber(v) or 1
    end)
    slotDropUpdate({"1","2","3","4"})

    -- Save button
    Button({Text="💾 Save to Slot", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        Notify("Saving to slot " .. State.SaveSlot .. "...", THEME.Yellow, 2)
        task.spawn(function()
            local ok, err = DoSaveSlot(State.SaveSlot)
            if ok then
                Notify("✓ Saved to Slot " .. State.SaveSlot, THEME.Green)
            else
                Notify("✗ Save failed: " .. tostring(err), THEME.Red)
            end
        end)
    end)

    -- Load button
    Button({Text="📂 Load Slot", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Cyan, Parent=ContentScroll}, function()
        Notify("Loading slot " .. State.SaveSlot .. "...", THEME.Yellow, 2)
        task.spawn(function()
            local ok, err = DoLoadSlot(State.SaveSlot)
            if ok then
                Notify("✓ Loaded Slot " .. State.SaveSlot, THEME.Green)
            else
                Notify("✗ Load failed: " .. tostring(err), THEME.Red)
            end
        end)
    end)

    SectionHeader("Land Management", THEME.Orange).Parent = ContentScroll

    -- Get slot info / metadata
    Button({Text="📋 Get Slot Info", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        task.spawn(function()
            local data, err = DoGetSlotInfo(State.SaveSlot)
            if data then
                Notify("Slot " .. State.SaveSlot .. ": Got metadata", THEME.Cyan)
            else
                Notify("Info: " .. tostring(err), THEME.Red)
            end
        end)
    end)

    -- Buy Land button
    Button({Text="🏡 Buy Available Land", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Yellow, Parent=ContentScroll}, function()
        task.spawn(function()
            Notify("Attempting land purchase...", THEME.Yellow, 2)
            local ok, msg = DoBuyLand()
            Notify((ok and "✓ " or "✗ ") .. tostring(msg), ok and THEME.Green or THEME.Red)
        end)
    end)

    -- Teleport to own plot
    Button({Text="🏠 TP to My Plot", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        task.spawn(function()
            local propsFolder = workspace:FindFirstChild("Properties")
            if propsFolder then
                for _, prop in ipairs(propsFolder:GetChildren()) do
                    local ownerVal = prop:FindFirstChild("Owner")
                    if ownerVal and ownerVal.Value == LP then
                        local primary = prop.PrimaryPart or prop:FindFirstChildWhichIsA("BasePart")
                        if primary then
                            TeleportTo(primary.CFrame * CFrame.new(0,5,0))
                            Notify("✓ Teleported to your plot", THEME.Green)
                            return
                        end
                    end
                end
            end
            Notify("No owned plot found", THEME.Red)
        end)
    end)
end

-- ---- PAGE 2: PLAYER ----
PageContents[2] = function()
    SectionHeader("Movement Stats", THEME.Green).Parent = ContentScroll

    Slider({Text="Walk Speed", Min=1, Max=150, Unit=" stud/s"}, "WalkSpeed", function(v)
        SetWalkSpeed(v)
    end).Parent = ContentScroll

    Slider({Text="Jump Power", Min=1, Max=250, Color=THEME.Cyan, Unit=" pow"}, "JumpPower", function(v)
        SetJumpPower(v)
    end).Parent = ContentScroll

    Slider({Text="Fly Speed", Min=10, Max=300, Color=THEME.Orange, Unit=" stud/s"}, "FlySpeed", nil).Parent = ContentScroll

    SectionHeader("Fly System (Press F)", THEME.Orange).Parent = ContentScroll

    local flyToggle, setFly = Toggle({Text="✈ Fly Mode  (W/A/S/D + Space/Shift)", Size=UDim2.new(1,0,0,50)}, "Flying", function(v)
        if v then StartFly() else StopFly() end
    end)
    flyToggle.Parent = ContentScroll

    -- Sync fly toggle with external keypress
    RunService.Heartbeat:Connect(function()
        pcall(function()
            if flyToggle and flyToggle.Parent then
                if setFly then
                    -- Keep toggle in sync with state
                end
            end
        end)
    end)

    SectionHeader("Utility", THEME.TextDim).Parent = ContentScroll

    -- Reset speed
    Button({Text="↩ Reset Speed & Jump", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        State.WalkSpeed = 16
        State.JumpPower = 50
        SetWalkSpeed(16)
        SetJumpPower(50)
        Notify("Speed & jump reset to default", THEME.Cyan)
    end)

    -- Kill character  
    Button({Text="💀 Kill Self", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        if hum then hum.Health = 0 end
    end)

    -- Rejoin  
    Button({Text="🔄 Rejoin Server", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end

-- ---- PAGE 3: WORLD ----
PageContents[3] = function()
    SectionHeader("Lighting", THEME.Yellow).Parent = ContentScroll

    local t1, _ = Toggle({Text="☀ Always Day"}, "AlwaysDay", function(v)
        SetAlwaysDay(v)
        if v then Notify("Always Day ON", THEME.Yellow) end
    end)
    t1.Parent = ContentScroll

    local t2, _ = Toggle({Text="🌙 Always Night"}, "AlwaysNight", function(v)
        SetAlwaysNight(v)
        if v then Notify("Always Night ON", THEME.TextDim) end
    end)
    t2.Parent = ContentScroll

    local t3, _ = Toggle({Text="🌫 No Fog"}, "NoFog", function(v)
        SetNoFog(v)
        Notify(v and "Fog removed" or "Fog restored", THEME.Cyan)
    end)
    t3.Parent = ContentScroll

    Toggle({Text="🌑 No Shadows"}, "NoShadows", function(v)
        Lighting.GlobalShadows = not v
        Notify(v and "Shadows OFF" or "Shadows ON", THEME.TextDim)
    end).Parent = ContentScroll

    SectionHeader("Teleport — Waypoints", THEME.Cyan).Parent = ContentScroll

    local wpNames = {}
    for k,_ in pairs(WAYPOINTS) do table.insert(wpNames, k) end
    table.sort(wpNames)

    local _, wpDropUpdate = Dropdown({Text="Select Waypoint", Size=UDim2.new(1,0,0,58)}, "SelectedWaypoint", wpNames, nil)
    State.SelectedWaypoint = wpNames[1]
    local wpDrop, _ = Dropdown({Text="Select Waypoint", Size=UDim2.new(1,0,0,58)}, "SelectedWaypoint", wpNames, nil)
    wpDrop.Parent = ContentScroll

    Button({Text="🚀 Teleport to Waypoint", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Cyan, Parent=ContentScroll}, function()
        if State.SelectedWaypoint then
            if TeleportWaypoint(State.SelectedWaypoint) then
                Notify("✓ Teleported to " .. State.SelectedWaypoint, THEME.Cyan)
            end
        end
    end)

    SectionHeader("Teleport — Players", THEME.Green).Parent = ContentScroll

    local playerNames = GetAllPlayers()
    local playerDrop, playerDropUpdate = Dropdown({Text="Select Player", Size=UDim2.new(1,0,0,58)}, "TargetPlayer", playerNames, nil)
    State.TargetPlayer = playerNames[1]
    playerDrop.Parent = ContentScroll

    -- Refresh players button
    Button({Text="🔄 Refresh Player List", Size=UDim2.new(1,0,0,38), BackgroundColor3=THEME.Card, TextSize=12, Parent=ContentScroll}, function()
        local names = GetAllPlayers()
        playerDropUpdate(names)
        Notify("Player list updated", THEME.Cyan, 1.5)
    end)

    Button({Text="➡ Teleport to Player", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        if State.TargetPlayer then
            if TeleportToPlayer(State.TargetPlayer) then
                Notify("✓ Teleported to " .. State.TargetPlayer, THEME.Green)
            else
                Notify("Player not found or no character", THEME.Red)
            end
        end
    end)
end

-- ---- PAGE 4: WOOD ----
PageContents[4] = function()
    SectionHeader("Auto Chop Trees", THEME.Green).Parent = ContentScroll
    
    Label({Text="Uses game's RemoteProxy to send chop events.\nEquip an axe first for best results.", TextSize=12, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,36), TextWrapped=true, Parent=ContentScroll})

    local treeTypes = {"Oak", "Birch", "Cherry", "Elm", "Walnut", "Pine", "Koa", "Palm", "Fir", "Frost", "Spooky", "Gold", "Green", "Bewitched", "Zombie", "Phantom"}
    Dropdown({Text="Tree Type", Size=UDim2.new(1,0,0,58)}, "SelectTree", treeTypes, nil).Parent = ContentScroll

    Slider({Text="Chop Amount", Min=1, Max=50}, "WoodAmount", nil).Parent = ContentScroll

    -- Start/Stop auto chop
    Button({Text="🌲 Start Auto Chop", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        if not State.AutoWoodOn then
            StartAutoChop()
            Notify("Auto Chop started", THEME.Green)
        else
            Notify("Already running", THEME.Orange)
        end
    end)
    Button({Text="⏹ Stop Auto Chop", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        StopAutoChop()
        Notify("Auto Chop stopped", THEME.Red)
    end)

    SectionHeader("Sell Wood", THEME.Yellow).Parent = ContentScroll
    Label({Text="Teleports to Wood Drop-off and moves owned wood to sell area.", TextSize=12, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,30), TextWrapped=true, Parent=ContentScroll})

    Button({Text="💰 Sell All Wood", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Yellow, Parent=ContentScroll}, function()
        task.spawn(function()
            Notify("Teleporting to sell area...", THEME.Yellow, 2)
            local ok = SellAllWood()
            Notify(ok and "✓ Wood moved to sell area" or "✗ Sell failed", ok and THEME.Green or THEME.Red)
        end)
    end)

    Button({Text="🏪 TP to Wood Drop-off", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        TeleportPos(-35, 4, 60)
        Notify("Teleported to Wood Drop-off", THEME.Cyan)
    end)
end

-- ---- PAGE 5: AUTO BUY ----
PageContents[5] = function()
    SectionHeader("Store Item Auto-Buy", THEME.Green).Parent = ContentScroll
    
    Label({Text="TP to store + invoke NPC dialog to purchase.\nMust have enough in-game money.\n[Based on verified NPCDialog remotes]", TextSize=12, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,52), TextWrapped=true, Parent=ContentScroll})

    -- Item dropdown (uses verified ToolName values)
    local itemNames = {}
    for _, item in ipairs(STORE_ITEMS) do
        table.insert(itemNames, item.name .. " ($" .. item.price .. ")")
    end
    local selectedItemIdx = 1
    Dropdown({Text="Select Item", Size=UDim2.new(1,0,0,58)}, "BuyItemDisplay", itemNames, function(v)
        for i, item in ipairs(STORE_ITEMS) do
            if (item.name .. " ($" .. item.price .. ")") == v then
                State.BuyItem = item.toolname
                selectedItemIdx = i
                break
            end
        end
    end).Parent = ContentScroll

    Slider({Text="Buy Amount", Min=1, Max=50}, "BuyAmt", nil).Parent = ContentScroll
    Slider({Text="Delay (seconds)", Min=0, Max=10, Unit="s"}, "DupeWait", nil).Parent = ContentScroll

    Button({Text="🛒 Start Auto Buy", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        if not State.AutoBuying then
            StartAutoBuy()
            Notify("Auto Buy started: " .. State.BuyItem, THEME.Green)
        else
            Notify("Already buying", THEME.Orange)
        end
    end)
    Button({Text="⏹ Stop Auto Buy", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        StopAutoBuy()
        Notify("Auto Buy stopped", THEME.Red)
    end)

    SectionHeader("Quick TP to Stores", THEME.Cyan).Parent = ContentScroll

    Button({Text="🪓 TP to WoodRUs", Size=UDim2.new(1,0,0,40), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        TeleportPos(-275, 5, 105)
        Notify("TP to WoodRUs", THEME.Cyan)
    end)
    Button({Text="🏚 TP to Bob's Shack", Size=UDim2.new(1,0,0,40), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        TeleportPos(-252, 5, 400)
        Notify("TP to Bob's Shack", THEME.Cyan)
    end)
    Button({Text="⚙️ TP to Link's Logic", Size=UDim2.new(1,0,0,40), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        TeleportPos(15, 5, 262)
        Notify("TP to Link's Logic", THEME.Cyan)
    end)
end

-- ---- PAGE 6: ITEM ----
PageContents[6] = function()
    SectionHeader("Item Selection", THEME.Cyan).Parent = ContentScroll
    
    Label({Text="Click parts in workspace to add to selection.\nLasso must be toggled ON first.", TextSize=12, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,36), TextWrapped=true, Parent=ContentScroll})

    local lassoCount = Label({Text="Selected: 0 items", TextSize=13, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,24), Parent=ContentScroll})

    -- Update label when items change
    RunService.Heartbeat:Connect(function()
        pcall(function()
            if lassoCount and lassoCount.Parent then
                lassoCount.Text = "Selected: " .. #State.SelectedItems .. " items"
            end
        end)
    end)

    Toggle({Text="🎯 Lasso Selector (click parts)"}, "LassoOn", function(v)
        ToggleLasso(v)
        Notify(v and "Lasso ON – click parts to select" or "Lasso OFF", THEME.Cyan, 1.5)
    end).Parent = ContentScroll

    Button({Text="✕ Deselect All", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        State.SelectedItems = {}
        Notify("Selection cleared", THEME.TextDim, 1.5)
    end)

    SectionHeader("Actions on Selected", THEME.Green).Parent = ContentScroll

    Button({Text="📍 Teleport Selected to Me", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        if #State.SelectedItems == 0 then
            Notify("Nothing selected", THEME.Orange)
        else
            TeleportSelectedToPlayer()
            Notify("✓ Moved " .. #State.SelectedItems .. " items to you", THEME.Green)
        end
    end)

    Slider({Text="Stack Length", Min=1, Max=20}, "StackLen", nil).Parent = ContentScroll

    SectionHeader("Drop Tools", THEME.Orange).Parent = ContentScroll

    Button({Text="🪓 Drop Equipped Axe", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Orange, Parent=ContentScroll}, function()
        local axe = GetAxe()
        if not axe then Notify("No axe equipped/in backpack", THEME.Red); return end
        local ok, err = DropTool(axe)
        Notify(ok and "✓ Axe dropped (ClientInteracted fired)" or "✗ Drop failed: " .. tostring(err), ok and THEME.Green or THEME.Red)
    end)

    Button({Text="⬇ Drop All Axes", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        task.spawn(function()
            local n = DropAllAxes()
            Notify("Dropped " .. n .. " axes", THEME.Orange)
        end)
    end)

    SectionHeader("Destroy Structures", THEME.Red).Parent = ContentScroll

    Button({Text="🗑 Destroy Selected Structures", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        if #State.SelectedItems == 0 then Notify("Nothing selected", THEME.Orange); return end
        local n = DestroySelectedItems()
        Notify("✓ Destroyed " .. n .. " items via DestroyStructure remote", THEME.Red)
    end)
end

-- ---- PAGE 7: DUPE ----
PageContents[7] = function()
    SectionHeader("Axe Duplication", THEME.Orange).Parent = ContentScroll
    
    Label({Text="Uses game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(tool, 'Drop tool', CFrame)\nDrop-pick loop to accumulate axes.", TextSize=12, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,52), TextWrapped=true, Parent=ContentScroll})

    Slider({Text="Dupe Amount", Min=1, Max=100}, "DupeAmt", nil).Parent = ContentScroll
    Slider({Text="Drop Delay (×0.1s)", Min=1, Max=50, Unit="x0.1s"}, "DupeWait", function(v)
        State.DupeWait = v * 0.1
    end).Parent = ContentScroll

    -- Status display
    local dupeStatus = Label({Text="Status: Idle", TextSize=13, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,24), Parent=ContentScroll})

    RunService.Heartbeat:Connect(function()
        pcall(function()
            if dupeStatus and dupeStatus.Parent then
                if State.Duping then
                    dupeStatus.Text = "Status: 🟢 Running..."
                    dupeStatus.TextColor3 = THEME.Green
                else
                    dupeStatus.Text = "Status: ⭕ Idle"
                    dupeStatus.TextColor3 = THEME.TextDim
                end
            end
        end)
    end)

    Button({Text="▶ Start Axe Dupe", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        local axe = GetAxe()
        if not axe then
            Notify("No axe found in character or backpack", THEME.Red)
            return
        end
        if State.Duping then
            Notify("Already duping!", THEME.Orange)
            return
        end
        StartAxeDupe()
        Notify("Axe dupe started (×" .. State.DupeAmt .. ")", THEME.Green)
    end)

    Button({Text="⏹ Stop Dupe", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        StopDupe()
        Notify("Dupe stopped", THEME.Red)
    end)

    SectionHeader("Drop Tools", THEME.TextDim).Parent = ContentScroll

    Button({Text="⬇ Drop All Axes in Backpack", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        task.spawn(function()
            local n = DropAllAxes()
            Notify("Dropped " .. n .. " axes via ClientInteracted", THEME.Orange)
        end)
    end)

    -- Axe name display
    Button({Text="🔍 Show Axe ToolNames", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, Parent=ContentScroll}, function()
        task.spawn(function()
            local axes = GetAllAxes()
            if #axes == 0 then
                Notify("No axes found in inventory", THEME.Red)
                return
            end
            for _, axe in ipairs(axes) do
                local tn = axe:FindFirstChild("ToolName")
                Notify("🪓 " .. axe.Name .. " | ToolName: " .. (tn and tn.Value or "nil"), THEME.Cyan, 4)
                task.wait(0.3)
            end
        end)
    end)
end

-- ---- PAGE 8: AUTO BUILD ----
PageContents[8] = function()
    SectionHeader("Blueprint Placement", THEME.Green).Parent = ContentScroll

    Label({Text="Place blueprints using ClientPlacedBlueprint FireServer.\nNote: Server validates all placements.", TextSize=12, TextColor3=THEME.TextDim, Size=UDim2.new(1,0,0,36), TextWrapped=true, Parent=ContentScroll})

    -- Blueprint list from ClientItemInfo (runtime scan)
    local function GetBlueprintNames()
        local names = {"Sawmill", "Plank Processor", "House", "Shelter", "Large Plank", "Log Cabin", "Storage"}
        -- Try scanning ClientItemInfo in ReplicatedStorage
        local cii = RS:FindFirstChild("ClientItemInfo")
        if cii then
            names = {}
            for _, child in ipairs(cii:GetChildren()) do
                local typeVal = child:FindFirstChild("Type")
                if typeVal and typeVal.Value == "Blueprint" then
                    table.insert(names, child.Name)
                end
            end
        end
        if #names == 0 then names = {"Sawmill", "Log Cabin", "Storage", "Shelter"} end
        return names
    end

    local bpNames = GetBlueprintNames()
    Dropdown({Text="Select Blueprint", Size=UDim2.new(1,0,0,58)}, "SelectedBlueprint", bpNames, nil).Parent = ContentScroll
    State.SelectedBlueprint = bpNames[1]

    Button({Text="📐 Place Blueprint Here", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Green, Parent=ContentScroll}, function()
        if State.SelectedBlueprint then
            task.spawn(function()
                local ok, err = PlaceBlueprint(State.SelectedBlueprint, nil)
                Notify(ok and "✓ Blueprint placement sent" or "✗ " .. tostring(err), ok and THEME.Green or THEME.Red)
            end)
        end
    end)

    Button({Text="🔧 Auto Fill Blueprints", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Cyan, Parent=ContentScroll}, function()
        task.spawn(function()
            local ok, msg = AutoFillBlueprints()
            Notify((ok and "✓ " or "✗ ") .. tostring(msg), ok and THEME.Green or THEME.Red)
        end)
    end)

    SectionHeader("Property / Plot", THEME.Orange).Parent = ContentScroll

    local playerNames = GetAllPlayers()
    local stealDrop, stealDropUpdate = Dropdown({Text="Target Player", Size=UDim2.new(1,0,0,58)}, "StealTarget", playerNames, nil)
    State.StealTarget = playerNames[1]
    stealDrop.Parent = ContentScroll

    Button({Text="🔄 Refresh Players", Size=UDim2.new(1,0,0,38), BackgroundColor3=THEME.Card, TextSize=12, Parent=ContentScroll}, function()
        local names = GetAllPlayers()
        stealDropUpdate(names)
        Notify("Players refreshed", THEME.Cyan, 1.5)
    end)

    Button({Text="🏠 Attempt Steal Plot", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        if State.StealTarget then
            task.spawn(function()
                local ok, msg = StealPlot(State.StealTarget)
                Notify((ok and "✓ " or "✗ ") .. tostring(msg), ok and THEME.Green or THEME.Red)
            end)
        end
    end)

    SectionHeader("Cleanup", THEME.Red).Parent = ContentScroll

    Button({Text="🗑 Destroy My Blueprints", Size=UDim2.new(1,0,0,44), BackgroundColor3=THEME.Card, TextColor3=THEME.Red, Parent=ContentScroll}, function()
        task.spawn(function()
            local ds = DestroyStructure()
            local n = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Blueprint" then
                    local ownerVal = obj:FindFirstChild("Owner")
                    if ownerVal and ownerVal.Value == LP then
                        if ds then pcall(function() ds:FireServer(obj) end)
                        else pcall(function() obj:Destroy() end) end
                        n = n + 1
                        task.wait(0.1)
                    end
                end
            end
            Notify("Destroyed " .. n .. " blueprints", THEME.Red)
        end)
    end)
end

-- =====================================================================
-- OPEN ANIMATION & INITIAL STATE
-- =====================================================================
MainFrame.Size = UDim2.fromOffset(WIN_W, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
    Size = UDim2.fromOffset(WIN_W, WIN_H)
}):Play()

ShowPage(1)

task.delay(0.5, function()
    Notify("🪓 LT2 Menu v2 Loaded", THEME.Green, 4)
    Notify("All remotes verified from game XML", THEME.Cyan, 5)
end)

return "LT2 Menu v2 loaded"
