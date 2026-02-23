-- =========================================================
-- Butter Hub - Lumber Tycoon 2 Script
-- Reconstructed from MoonSec V3 bytecode analysis
-- Credits: Applebox, silentben8x, tip
-- Discord: https://discord.gg/butterhub
-- =========================================================
-- "Lumber Tycoon came out 15 years ago"
-- =========================================================

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace       = game:GetService("Workspace")

local LocalPlayer  = Players.LocalPlayer
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid     = Character:WaitForChild("Humanoid")
local RootPart     = Character:WaitForChild("HumanoidRootPart")
local Camera       = Workspace.CurrentCamera

-- =========================================================
-- EXECUTOR DETECTION
-- =========================================================

local executor = "Unknown"
local isSolara = false

if identifyexecutor then
    executor = identifyexecutor()
    isSolara = executor:lower():find("solara") ~= nil
elseif getexecutorname then
    executor = getexecutorname()
end

-- =========================================================
-- FILE / SETTINGS HELPERS
-- =========================================================

local SETTINGS_FILE  = "ButterSSlotNames.cfg"
local EXECUTOR_FILE  = "expthingy.txt"
local SLOT_COUNT     = 6

local SaveSlotNames  = {"Slot 1","Slot 2","Slot 3","Slot 4","Slot 5","Slot 6"}
local SSlot1, SSlot2, SSlot3, SSlot4, SSlot5, SSlot6 = nil,nil,nil,nil,nil,nil
local Slot2, Slot4Val, Slot5, Slot6 = nil,nil,nil,nil
local Slot4 = nil

local function saveSettings()
    if isfile and writefile then
        local data = HttpService:JSONEncode({
            SlotNames = SaveSlotNames,
            Walkspeed = Humanoid.WalkSpeed,
            JumpPower = Humanoid.JumpPower,
        })
        writefile(SETTINGS_FILE, data)
        print("Configuration loaded successfully.")
    end
end

local function loadSettings()
    if isfile and isfile(SETTINGS_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(SETTINGS_FILE))
        end)
        if ok and data then
            SaveSlotNames = data.SlotNames or SaveSlotNames
        else
            print("Configuration file error. Fixing...")
            saveSettings()
        end
    end
end

local function setSlotTo(slot, name)
    SaveSlotNames[slot] = name
    saveSettings()
end

local function loadSlot(slot)
    return SaveSlotNames[slot]
end

loadSettings()

-- =========================================================
-- UTILITY
-- =========================================================

local function notify(msg, dur)
    game:GetService("StarterGui"):SetCore("SendNotification",{
        Title = "Butter Hub",
        Text  = msg,
        Duration = dur or 3,
    })
end

local function sendUserNotice(msg)
    pcall(function()
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg,"All")
    end)
end

local function clampVector3(v, min, max)
    return Vector3.new(
        math.clamp(v.X, min, max),
        math.clamp(v.Y, min, max),
        math.clamp(v.Z, min, max)
    )
end

local function getPosition(obj)
    if obj:IsA("Model") then
        return obj:GetModelCFrame()
    end
    return obj.CFrame
end

local function getCFrame(obj)
    return obj.CFrame
end

local function countitems(parent)
    local n = 0
    for _,v in pairs(parent:GetChildren()) do n = n + 1 end
    return n
end

local function getCounter()
    return #Players:GetPlayers()
end

local function getPing()
    return math.floor(LocalPlayer:GetNetworkPing() * 1000)
end

-- =========================================================
-- FEATURE STATE
-- =========================================================

local Flags = {
    NoClip         = false,
    InfiniteJump   = false,
    GodMode        = false,
    FLYING         = false,
    BetterFly      = false,
    ClickToTP      = false,
    AutoBuild      = false,
    AutoBuild2     = false,
    AutoBuild4     = false,
    AutoBuyg       = false,
    SellAllLogs    = false,
    GrabShopItems  = false,
    LogModels      = false,
    NoFog          = false,
    BetterGraphics = false,
    Night          = false,
    AutoFill       = false,
    VehicleSpawner = false,
    FreeLand       = false,
    Sorter         = false,
    InfiniteHrp    = false,
    QEfly          = false,
    SelectionTp    = false,
    carTP          = false,
    orbitFunc      = false,
}

local Settings = {
    Walkspeed      = 16,
    JumpPower      = 50,
    FlySpeed       = 50,
    FOV            = 70,
    SSpeed         = 1,
    OrbitSpeed     = 1,
    FlyKey         = Enum.KeyCode.E,
    LeftShift      = false,
    RightShift     = false,
    Y_Sensitivity  = 1,
    theme          = "Default",
    distanceSlider = 50,
    Infeaxerange   = 10,
}

-- =========================================================
-- MOVEMENT
-- =========================================================

-- NoClip
RunService.Stepped:Connect(function()
    if Flags.NoClip then
        for _,part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Flags.InfiniteJump then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- God Mode
local function setGodMode(enabled)
    Flags.GodMode = enabled
    if enabled then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health    = math.huge
    end
end

-- Walkspeed
local function setWalkspeed(val)
    Settings.Walkspeed = val
    Humanoid.WalkSpeed = val
end

-- Jump Power
local function setJumpPower(val)
    Settings.JumpPower = val
    Humanoid.JumpPower = val
end

-- =========================================================
-- FLY SYSTEM (QEfly / BetterFly)
-- =========================================================

local flyConnection
local flyBodyVelocity
local flyBodyGyro

local function startFly()
    if Flags.FLYING then return end
    Flags.FLYING = true

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity    = Vector3.new(0,0,0)
    flyBodyVelocity.MaxForce    = Vector3.new(1e9,1e9,1e9)
    flyBodyVelocity.Parent      = RootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque       = Vector3.new(1e9,1e9,1e9)
    flyBodyGyro.CFrame          = RootPart.CFrame
    flyBodyGyro.Parent          = RootPart

    flyConnection = RunService.Heartbeat:Connect(function()
        if not Flags.FLYING then
            flyBodyVelocity:Destroy()
            flyBodyGyro:Destroy()
            flyConnection:Disconnect()
            return
        end
        local dir = Vector3.new(0,0,0)
        local spd = Settings.FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            dir = dir + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            dir = dir - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            dir = dir - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            dir = dir + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0,1,0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            dir = dir - Vector3.new(0,1,0)
        end
        flyBodyVelocity.Velocity = dir.Magnitude > 0
            and dir.Unit * spd
            or  Vector3.new(0,0,0)
        flyBodyGyro.CFrame = Camera.CFrame
    end)
end

local function stopFly()
    Flags.FLYING = false
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.FlyKey then
        if Flags.FLYING then stopFly() else startFly() end
    end
end)

-- =========================================================
-- TELEPORTS
-- =========================================================

local LOCATIONS = {
    ["Free Land"]       = CFrame.new(230, 10, 170),
    ["Wood Dropoff"]    = CFrame.new(-68, 4, -137),
    ["The Swamp"]       = CFrame.new(-1300, 26, 830),
    ["Cherry Meadow"]   = CFrame.new(820, 8, 920),
    ["Snow Biome"]      = CFrame.new(-1083, 115, -1274),
    ["EndTimes Cave"]   = CFrame.new(490, -188, 1430),
    ["LoneCave"]        = CFrame.new(-1070, 65, -210),
    ["The Den"]         = CFrame.new(-570, 30, -1200),
    ["Bob's Shack"]     = CFrame.new(-5, 5, 700),
    ["Fancy Furnishings"] = CFrame.new(-300, 3, -118),
    ["WoodRUs"]         = CFrame.new(316, 3, -143),
    ["CarStore"]        = CFrame.new(380, 3, 70),
    ["Bridge"]          = CFrame.new(-85, 10, 430),
    ["Toll Bridge"]     = CFrame.new(-85, 8, 380),
    ["Ferry Ticket"]    = CFrame.new(-200, 7, 420),
    ["Strange Man"]     = CFrame.new(230, 65, -1170),
    ["Cave"]            = CFrame.new(170, -10, 880),
    ["Admin Teleport"]  = CFrame.new(500, 50, -500),
}

local function teleportTo(cf)
    RootPart.CFrame = cf
end

local function teleportToPlayer(target)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        RootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(3,0,0)
    end
end

local function teleportToBase(plr)
    plr = plr or LocalPlayer
    local plot = Workspace:FindFirstChild("PlayerPlots")
    if plot then
        local base = plot:FindFirstChild(plr.Name)
        if base then
            RootPart.CFrame = base:GetModelCFrame() + Vector3.new(0,5,0)
        end
    end
end

local function teleportVehicleToPlayer(target)
    if not target then return end
    local vehicle = Workspace:FindFirstChild("Vehicles")
    if vehicle then
        local myVehicle = vehicle:FindFirstChild(LocalPlayer.Name)
        if myVehicle and target.Character then
            myVehicle:SetPrimaryPartCFrame(
                target.Character.HumanoidRootPart.CFrame + Vector3.new(5,0,0)
            )
        end
    end
end

-- =========================================================
-- PLAYER ACTIONS
-- =========================================================

local function killPlayer(target)
    if target and target.Character then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end

local function sitInAnyVehicle()
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") then
            v:Sit(Humanoid)
            break
        end
    end
end

local function serverHop()
    local servers = {}
    local ok, result = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
        )
    end)
    if ok and result and result.data then
        for _,srv in pairs(result.data) do
            if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                table.insert(servers, srv.id)
            end
        end
        if #servers > 0 then
            game:GetService("TeleportService"):TeleportToPlaceInstance(
                game.PlaceId, servers[math.random(1,#servers)]
            )
        end
    end
end

local function dropTools()
    for _,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
            tool.Parent = Workspace
        end
    end
end

local function dropOwner()
    local re = ReplicatedStorage:FindFirstChild("DropOwner")
    if re then re:FireServer() end
end

-- =========================================================
-- AUTO BUILD
-- =========================================================

local autoBuildEnabled = false
local autoBuildPlot    = nil

local function makeAutoBuildUI()
    -- placeholder - connects to plotDD dropdown
end

local function buildOnPlot(plot)
    if not plot then return end
    local structures = ReplicatedStorage:FindFirstChild("ClientPlacedStructure")
    if structures then
        for _,s in pairs(structures:GetChildren()) do
            local re = ReplicatedStorage:FindFirstChild("PlaceStructure")
            if re then
                re:FireServer(s, plot)
                wait(0.1)
            end
        end
    end
end

local function buildOntoPlayersPlot(target)
    if target then
        local plot = Workspace.PlayerPlots:FindFirstChild(target.Name)
        buildOnPlot(plot)
    end
end

-- =========================================================
-- WOOD / SAWMILL
-- =========================================================

local WOOD_TYPES = {"Birch","Cherry","Koa","Fir","Walnut","Palm","Spooky"}

local function sawmillTree(woodType)
    local sawmill = Workspace:FindFirstChild("Sawmill")
    if sawmill then
        local re = ReplicatedStorage:FindFirstChild("SawmillLog")
        if re then re:FireServer(woodType) end
    end
end

local function selectSawmill(woodType)
    sawmillTree(woodType)
end

local function modSawmill(speed)
    local sawmill = Workspace:FindFirstChild("Sawmill")
    if sawmill then
        local motor = sawmill:FindFirstChild("MotorSpeed")
        if motor then motor.Value = speed end
    end
end

local function treeCut(tree)
    local re = ReplicatedStorage:FindFirstChild("treeCut")
    if re then re:FireServer(tree) end
end

local function treeCutNoRequire(tree)
    treeCut(tree)
end

local function viewEndTree()
    local trees = Workspace:FindFirstChild("TreeRegion")
    if trees then
        for _,t in pairs(trees:GetChildren()) do
            if t.Name:find("Spooky") or t.Name:find("Zombie") then
                RootPart.CFrame = t:GetModelCFrame() + Vector3.new(0,5,0)
                return
            end
        end
    end
end

-- =========================================================
-- ITEM / SHOP
-- =========================================================

local function grabShopItems()
    local shop = Workspace:FindFirstChild("WoodRUs") or Workspace:FindFirstChild("Fancy Furnishings")
    if shop then
        for _,item in pairs(shop:GetDescendants()) do
            if item:IsA("Tool") or item:IsA("Part") then
                item.Parent = LocalPlayer.Backpack
            end
        end
    end
end

local function purchaseAllBlueprints()
    local re = ReplicatedStorage:FindFirstChild("SelectPurchase")
    if re then
        local shop = Workspace:FindFirstChild("PropertyPurchasingClient")
        if shop then
            for _,bp in pairs(shop:GetChildren()) do
                re:FireServer(bp)
                wait(0.2)
            end
        end
    end
end

local function sellAllLogs()
    local re = ReplicatedStorage:FindFirstChild("SellAllLogs")
    if re then
        re:FireServer()
    end
end

local function getToolStats()
    local tools = LocalPlayer.Backpack:GetChildren()
    for _,tool in pairs(tools) do
        if tool:IsA("Tool") then
            print(tool.Name, tool:GetAttributes())
        end
    end
end

local function getToolsfix()
    -- Re-equips dropped tools back to backpack
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and v:GetAttribute("Owner") == LocalPlayer.UserId then
            v.Parent = LocalPlayer.Backpack
        end
    end
end

local function getBestAxe()
    local best, bestPower = nil, 0
    for _,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("AxePower") then
            local power = tool:GetAttribute("AxePower")
            if power > bestPower then
                best, bestPower = tool, power
            end
        end
    end
    return best
end

local function stealBps()
    local re = ReplicatedStorage:FindFirstChild("GetToolsfix")
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                for _,tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = LocalPlayer.Backpack
                    end
                end
            end
        end
    end
end

-- =========================================================
-- LAND / PROPERTY
-- =========================================================

local function freeLand()
    local re = ReplicatedStorage:FindFirstChild("FreeLand")
    if re then re:FireServer() end
end

local function copyBase(target)
    local plot = Workspace.PlayerPlots:FindFirstChild(target and target.Name or LocalPlayer.Name)
    if plot then
        local copy = plot:Clone()
        copy.Parent = Workspace
    end
end

local function selectLand()
    local re = ReplicatedStorage:FindFirstChild("Select Land")
    if re then re:FireServer() end
end

local function toggleShopDoors()
    local shops = {"WoodRUs","Fancy Furnishings","CarStore"}
    for _,shopName in pairs(shops) do
        local shop = Workspace:FindFirstChild(shopName)
        if shop then
            for _,door in pairs(shop:GetDescendants()) do
                if door.Name == "Door" and door:IsA("Part") then
                    door.Transparency = door.Transparency > 0 and 0 or 1
                    door.CanCollide = not door.CanCollide
                end
            end
        end
    end
end

-- =========================================================
-- DUPE SYSTEM
-- =========================================================

local function dupeInventory()
    for _,tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        local clone = tool:Clone()
        clone.Parent = LocalPlayer.Backpack
    end
end

local function copyFunc(func)
    -- Copies a function reference
    return func
end

-- =========================================================
-- VEHICLE
-- =========================================================

local function startVehicleSpawner()
    local re = ReplicatedStorage:FindFirstChild("VehicleSpawner")
    if re then re:FireServer() end
end

local function sortPlayer(plr)
    if plr and plr.Character then
        RootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
    end
end

-- =========================================================
-- VISUAL
-- =========================================================

local originalFog      = nil
local lightingService  = game:GetService("Lighting")

local function setNoFog(enabled)
    Flags.NoFog = enabled
    if enabled then
        originalFog = lightingService.FogEnd
        lightingService.FogEnd = 1e9
        lightingService.FogStart = 1e9
    elseif originalFog then
        lightingService.FogEnd   = originalFog
        lightingService.FogStart = 0
    end
end

local function setNight(enabled)
    Flags.Night = enabled
    lightingService.ClockTime = enabled and 0 or 14
end

local function betterGraphics(enabled)
    Flags.BetterGraphics = enabled
    if enabled then
        game:GetService("Workspace").StreamingEnabled = false
        settings().Rendering.QualityLevel = 21
    end
end

local function setFOV(val)
    Settings.FOV = val
    Camera.FieldOfView = val
end

-- =========================================================
-- ORBIT SYSTEM
-- =========================================================

local orbitTarget = nil
local orbitConnection = nil

local function updateOrbit()
    if not orbitTarget or not orbitTarget.Character then return end
    local angle = tick() * Settings.OrbitSpeed
    local radius = Settings.distanceSlider
    local targetPos = orbitTarget.Character.HumanoidRootPart.Position
    RootPart.CFrame = CFrame.new(
        targetPos + Vector3.new(math.cos(angle)*radius, 5, math.sin(angle)*radius),
        targetPos
    )
end

local function startOrbit(target)
    orbitTarget = target
    Flags.orbitFunc = true
    orbitConnection = RunService.Heartbeat:Connect(function()
        if Flags.orbitFunc then
            updateOrbit()
        else
            orbitConnection:Disconnect()
        end
    end)
end

-- =========================================================
-- AUTO BUY
-- =========================================================

local autoBuyRunning = false

local function autoBuy(item)
    autoBuyRunning = true
    spawn(function()
        while autoBuyRunning do
            local re = ReplicatedStorage:FindFirstChild("AutoBuyg")
            if re then re:FireServer(item) end
            wait(1)
        end
    end)
end

-- =========================================================
-- SORTER
-- =========================================================

local function sorterTab1()
    local logs = Workspace:FindFirstChild("LogModels")
    if logs then
        local sorted = {}
        for _,log in pairs(logs:GetChildren()) do
            local woodType = log:GetAttribute("WoodType") or "Unknown"
            sorted[woodType] = sorted[woodType] or {}
            table.insert(sorted[woodType], log)
        end
        local x = 0
        for woodType, group in pairs(sorted) do
            for i,log in pairs(group) do
                log:SetPrimaryPartCFrame(CFrame.new(x, 5, i * 8))
            end
            x = x + 12
        end
    end
end

-- =========================================================
-- MISC
-- =========================================================

local function sendNotification(msg)
    notify(msg)
end

local function spawnPart()
    local part = Instance.new("Part")
    part.Size = Vector3.new(4,1,4)
    part.Anchored = true
    part.CFrame = RootPart.CFrame * CFrame.new(0,-3,0)
    part.Parent = Workspace
end

local function logModels()
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:GetAttribute("WoodType") then
            print(v.Name, v:GetAttribute("WoodType"))
        end
    end
end

local function deselect()
    local re = ReplicatedStorage:FindFirstChild("delallselections")
    if re then re:FireServer() end
end

local function abort()
    Flags.AutoBuild  = false
    Flags.AutoBuyg   = false
    autoBuyRunning   = false
end

local function getMikeTp()
    -- Teleport to "Mike" (admin) location
    teleportTo(CFrame.new(500,50,-500))
end

local function infHrp()
    Flags.InfiniteHrp = not Flags.InfiniteHrp
    if Flags.InfiniteHrp then
        spawn(function()
            while Flags.InfiniteHrp do
                RootPart.Anchored = true
                wait(0.1)
                RootPart.Anchored = false
                wait(0.1)
            end
        end)
    end
end

-- =========================================================
-- UI SYSTEM
-- =========================================================

-- Remove existing GUI
if LocalPlayer.PlayerGui:FindFirstChild("ButterHub") then
    LocalPlayer.PlayerGui.ButterHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ButterHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Loading screen
local LoadingScreen = Instance.new("Frame")
LoadingScreen.Name = "LoadingScreen"
LoadingScreen.Size = UDim2.new(1,0,1,0)
LoadingScreen.Position = UDim2.new(0,0,0,0)
LoadingScreen.BackgroundColor3 = Color3.fromRGB(20,20,30)
LoadingScreen.BorderSizePixel = 0
LoadingScreen.Parent = ScreenGui

local loadLabel = Instance.new("TextLabel")
loadLabel.Size = UDim2.new(0,400,0,60)
loadLabel.Position = UDim2.new(0.5,-200,0.5,-30)
loadLabel.BackgroundTransparency = 1
loadLabel.Font = Enum.Font.GothamBold
loadLabel.TextSize = 28
loadLabel.TextColor3 = Color3.fromRGB(255,215,0)
loadLabel.Text = "Butter Hub"
loadLabel.Parent = LoadingScreen

local loadSub = Instance.new("TextLabel")
loadSub.Size = UDim2.new(0,400,0,30)
loadSub.Position = UDim2.new(0.5,-200,0.5,35)
loadSub.BackgroundTransparency = 1
loadSub.Font = Enum.Font.Gotham
loadSub.TextSize = 14
loadSub.TextColor3 = Color3.fromRGB(200,200,200)
loadSub.Text = "Loading sequence..."
loadSub.Parent = LoadingScreen

task.delay(2, function()
    TweenService:Create(LoadingScreen, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    task.delay(0.5, function()
        LoadingScreen:Destroy()
    end)
end)

-- =========================================================
-- MAIN WINDOW
-- =========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0,570,0,420)
Main.Position = UDim2.new(0.5,-285,0.5,-210)
Main.BackgroundColor3 = Color3.fromRGB(25,25,35)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0,8)
UICorner.Parent = Main

-- Drop shadow holder
local DropShadowHolder = Instance.new("Frame")
DropShadowHolder.Name = "DropShadowHolder"
DropShadowHolder.Size = UDim2.new(1,20,1,20)
DropShadowHolder.Position = UDim2.new(0,-10,0,-10)
DropShadowHolder.BackgroundColor3 = Color3.fromRGB(0,0,0)
DropShadowHolder.BackgroundTransparency = 0.7
DropShadowHolder.BorderSizePixel = 0
DropShadowHolder.ZIndex = 0
DropShadowHolder.Parent = Main
local UICorner_2 = Instance.new("UICorner")
UICorner_2.CornerRadius = UDim.new(0,12)
UICorner_2.Parent = DropShadowHolder

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0,8)
UICorner3.Parent = TitleBar

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,215,0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,140,0)),
})
UIGradient.Rotation = 90
UIGradient.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-50,1,0)
Title.Position = UDim2.new(0,10,0,0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "🧈 Butter Hub  •  Lumber Tycoon 2  •  " .. executor
Title.Parent = TitleBar

-- Close / Toggle UI button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0,30,0,30)
ToggleBtn.Position = UDim2.new(1,-35,0,5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Text = "X"
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = TitleBar
Instance.new("UICorner",ToggleBtn).CornerRadius = UDim.new(0,4)
ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Info bar
local InfoBar = Instance.new("TextLabel")
InfoBar.Size = UDim2.new(1,0,0,20)
InfoBar.Position = UDim2.new(0,0,0,40)
InfoBar.BackgroundColor3 = Color3.fromRGB(15,15,20)
InfoBar.BorderSizePixel = 0
InfoBar.Font = Enum.Font.Gotham
InfoBar.TextSize = 11
InfoBar.TextColor3 = Color3.fromRGB(160,160,160)
InfoBar.Text = " Butter hub has a Discord server https://discord.gg/butterhub  |  Credits: Applebox, silentben8x, tip"
InfoBar.TextXAlignment = Enum.TextXAlignment.Left
InfoBar.Parent = Main

-- =========================================================
-- TAB SYSTEM
-- =========================================================

local TAB_NAMES = {
    "World", "Wood", "Item", "Troll", "Dupe", "Sorter", "Settings", "Credits"
}

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0,120,1,-62)
TabBar.Position = UDim2.new(0,0,0,62)
TabBar.BackgroundColor3 = Color3.fromRGB(20,20,30)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0,2)
TabLayout.Parent = TabBar

local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Size = UDim2.new(1,-125,1,-62)
ContentArea.Position = UDim2.new(0,122,0,62)
ContentArea.BackgroundColor3 = Color3.fromRGB(22,22,32)
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 4
ContentArea.CanvasSize = UDim2.new(0,0,0,0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = Main
Instance.new("UIListLayout",ContentArea).Padding = UDim.new(0,4)

local tabButtons = {}
local tabContents = {}
local activeTab = nil

local function switchTab(name)
    activeTab = name
    for n,btn in pairs(tabButtons) do
        if n == name then
            btn.BackgroundColor3 = Color3.fromRGB(255,215,0)
            btn.TextColor3 = Color3.fromRGB(20,20,20)
        else
            btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
            btn.TextColor3 = Color3.fromRGB(200,200,200)
        end
    end
    for n,frame in pairs(tabContents) do
        frame.Visible = (n == name)
    end
end

for i,tabName in pairs(TAB_NAMES) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Text = tabName
    btn.BorderSizePixel = 0
    btn.LayoutOrder = i
    btn.Parent = TabBar
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)
    tabButtons[tabName] = btn

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,1,0)
    content.Position = UDim2.new(0,0,0,0)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Name = tabName.."Tab"
    content.Parent = ContentArea
    tabContents[tabName] = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    layout.Parent = content

    btn.MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)
end

-- =========================================================
-- UI HELPERS
-- =========================================================

local function makeButton(parent, text, callback, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-8,0,30)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = text
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.AutoButtonColor = true
    btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function makeToggle(parent, text, flagKey, callback, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-8,0,30)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = "[ ] " .. text
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 0
    btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function()
        Flags[flagKey] = not Flags[flagKey]
        btn.Text = (Flags[flagKey] and "[x] " or "[ ] ") .. text
        btn.BackgroundColor3 = Flags[flagKey]
            and Color3.fromRGB(40,80,40)
            or  Color3.fromRGB(35,35,50)
        if callback then callback(Flags[flagKey]) end
    end)
    return btn
end

local function makeSlider(parent, text, min, max, default, onChange, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,-8,0,50)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order or 0
    holder.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(180,180,180)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text .. ": " .. default
    lbl.Parent = holder

    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(1,0,0,10)
    bar.Position = UDim2.new(0,0,0,24)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,70)
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Instance.new("UICorner",bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(255,215,0)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local slider = Instance.new("TextButton")
    slider.Name = "Slider"
    slider.Size = UDim2.new(0,14,0,14)
    slider.Position = UDim2.new((default-min)/(max-min),0,0.5,-7)
    slider.BackgroundColor3 = Color3.fromRGB(255,255,255)
    slider.Text = ""
    slider.BorderSizePixel = 0
    slider.Parent = bar
    Instance.new("UICorner",slider).CornerRadius = UDim.new(1,0)

    local dragging = false
    slider.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local value = math.floor(min + (max-min)*rel)
            fill.Size = UDim2.new(rel,0,1,0)
            slider.Position = UDim2.new(rel,0,0.5,-7)
            lbl.Text = text .. ": " .. value
            if onChange then onChange(value) end
        end
    end)
    return holder
end

local function makeDropdown(parent, text, options, onChange, order)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,-8,0,30)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = order or 0
    holder.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,50)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Text = text .. ": " .. (options[1] or "None")
    btn.BorderSizePixel = 0
    btn.Parent = holder
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)

    local selected = options[1]
    local idx = 1
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        selected = options[idx]
        btn.Text = text .. ": " .. selected
        if onChange then onChange(selected) end
    end)
    return holder, function() return selected end
end

local function makeSeparator(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-8,0,20)
    lbl.BackgroundColor3 = Color3.fromRGB(255,215,0)
    lbl.BackgroundTransparency = 0.8
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(255,215,0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. (text or "")
    lbl.BorderSizePixel = 0
    lbl.LayoutOrder = order or 0
    lbl.Parent = parent
    return lbl
end

-- =========================================================
-- WORLD TAB
-- =========================================================
do
    local t = tabContents["World"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"TELEPORTS",ord())
    for name,cf in pairs(LOCATIONS) do
        makeButton(t,"→ " .. name, function()
            teleportTo(cf)
        end, ord())
    end

    makeSeparator(t,"PLAYER TELEPORTS",ord())
    local plrNames = {}
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(plrNames,p.Name) end
    end
    local ddTPTP, getTPTP = makeDropdown(t,"Teleport to Player",#plrNames>0 and plrNames or {"None"},nil,ord())
    makeButton(t,"Teleport to Player", function()
        local plr = Players:FindFirstChild(getTPTP())
        teleportToPlayer(plr)
    end, ord())
    makeButton(t,"Teleport to Player Base", function()
        local plr = Players:FindFirstChild(getTPTP())
        teleportToBase(plr)
    end, ord())
    makeButton(t,"Teleport Vehicle to Player", function()
        local plr = Players:FindFirstChild(getTPTP())
        teleportVehicleToPlayer(plr)
    end, ord())
    makeButton(t,"Truck Teleport Selected (Fast)", function()
        local plr = Players:FindFirstChild(getTPTP())
        if plr and plr.Character then
            local veh = Workspace:FindFirstChild("Vehicles")
            if veh then
                local myVeh = veh:FindFirstChild(LocalPlayer.Name)
                if myVeh then
                    myVeh:SetPrimaryPartCFrame(plr.Character.HumanoidRootPart.CFrame + Vector3.new(10,0,0))
                end
            end
        end
    end, ord())

    makeSeparator(t,"SERVER",ord())
    makeButton(t,"Server Hop",serverHop,ord())
    makeButton(t,"Toggle Shop Doors",toggleShopDoors,ord())
    makeToggle(t,"No Fog","NoFog",setNoFog,ord())
    makeToggle(t,"Night","Night",setNight,ord())
    makeToggle(t,"Better Graphics","BetterGraphics",betterGraphics,ord())
    makeSlider(t,"FOV",30,120,70,setFOV,ord())
end

-- =========================================================
-- WOOD TAB
-- =========================================================
do
    local t = tabContents["Wood"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"AUTO BUILD",ord())
    makeToggle(t,"Auto Build","AutoBuild",nil,ord())
    makeToggle(t,"Auto Build 2 (Plot)","AutoBuild2",nil,ord())
    makeToggle(t,"Auto Build 4","AutoBuild4",nil,ord())
    local ddABP,getABP = makeDropdown(t,"Build Plot",{"My Plot","Player Plot"},nil,ord())
    makeButton(t,"Build Onto Players Plot", function()
        local plr = Players:GetPlayers()[1]
        buildOntoPlayersPlot(plr)
    end, ord())

    makeSeparator(t,"SAWMILL",ord())
    local ddSawmill,getSawmill = makeDropdown(t,"Sawmill Tree",WOOD_TYPES,nil,ord())
    makeButton(t,"Select Sawmill", function()
        selectSawmill(getSawmill())
    end, ord())
    makeButton(t,"Sawmill Log", function()
        sawmillTree(getSawmill())
    end, ord())
    makeButton(t,"Mod Sawmill Speed", function()
        modSawmill(100)
    end, ord())

    makeSeparator(t,"TREES",ord())
    makeButton(t,"View End Tree",viewEndTree,ord())
    makeToggle(t,"Log Models","LogModels",logModels,ord())

    makeSeparator(t,"SELL",ord())
    makeButton(t,"Sell All Logs",sellAllLogs,ord())
    makeButton(t,"Sell Sold Sign", function()
        local re = ReplicatedStorage:FindFirstChild("SellSign")
        if re then re:FireServer() end
    end, ord())

    makeSeparator(t,"LAND",ord())
    makeButton(t,"Free Land",freeLand,ord())
    makeButton(t,"Select Land",selectLand,ord())
    makeButton(t,"Copy Base", function() copyBase(LocalPlayer) end, ord())
    makeButton(t,"Load Base", function()
        local re = ReplicatedStorage:FindFirstChild("LoadSaveGUI")
        if re then re:FireServer() end
    end, ord())
end

-- =========================================================
-- ITEM TAB
-- =========================================================
do
    local t = tabContents["Item"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"SHOP",ord())
    makeButton(t,"Grab Shop Items",grabShopItems,ord())
    makeButton(t,"Purchase All Blueprints",purchaseAllBlueprints,ord())
    makeButton(t,"Get Tools Fix",getToolsfix,ord())
    makeButton(t,"Get Best Axe", function()
        local axe = getBestAxe()
        if axe then notify("Best axe: " .. axe.Name) end
    end, ord())
    makeButton(t,"Get Tool Stats",getToolStats,ord())
    makeButton(t,"Drop Tools",dropTools,ord())
    makeButton(t,"Drop Owner",dropOwner,ord())
    makeButton(t,"Lasso tool", function()
        local lasso = LocalPlayer.Backpack:FindFirstChild("Lasso")
        if lasso then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):EquipTool(lasso)
        end
    end, ord())

    makeSeparator(t,"AUTO BUY",ord())
    makeToggle(t,"Auto Buy","AutoBuyg",function(v)
        if v then autoBuy("item") else autoBuyRunning = false end
    end, ord())

    makeSeparator(t,"ITEM OWNER",ord())
    makeButton(t,"Item Owner", function()
        for _,v in pairs(Workspace:GetDescendants()) do
            if v:GetAttribute("Owner") then
                print(v.Name, "owned by", v:GetAttribute("Owner"))
            end
        end
    end, ord())

    makeSeparator(t,"BLUEPRINT",ord())
    makeButton(t,"Steal Blueprints",stealBps,ord())
    makeButton(t,"Deselect Items",deselect,ord())
    makeButton(t,"Abort",abort,ord())
end

-- =========================================================
-- TROLL TAB
-- =========================================================
do
    local t = tabContents["Troll"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"PLAYER",ord())
    local ddKill,getKill = makeDropdown(t,"Target Player",{"All"},nil,ord())
    makeButton(t,"Kill Player", function()
        local name = getKill()
        if name == "All" then
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then killPlayer(p) end
            end
        else
            killPlayer(Players:FindFirstChild(name))
        end
    end, ord())
    makeButton(t,"Sit In Any Vehicle",sitInAnyVehicle,ord())
    makeButton(t,"Pay", function()
        local re = ReplicatedStorage:FindFirstChild("Pay")
        if re then re:FireServer(Players:GetPlayers()[1], 1) end
    end, ord())
    makeButton(t,"Steal Blueprints",stealBps,ord())

    makeSeparator(t,"ORBIT",ord())
    local ddOrbit,getOrbit = makeDropdown(t,"Orbit Target",{"None"},nil,ord())
    makeButton(t,"Start Orbit", function()
        local plr = Players:FindFirstChild(getOrbit())
        if plr then startOrbit(plr) end
    end, ord())
    makeToggle(t,"Orbit Active","orbitFunc",nil,ord())
    makeSlider(t,"Orbit Speed",1,20,1,function(v) Settings.OrbitSpeed=v end,ord())
    makeSlider(t,"Orbit Distance",5,100,50,function(v) Settings.distanceSlider=v end,ord())

    makeSeparator(t,"MISC",ord())
    makeButton(t,"Spawn Part",spawnPart,ord())
    makeButton(t,"Send Notification", function() sendUserNotice("Butter Hub") end, ord())
    makeButton(t,"Server Hop",serverHop,ord())
end

-- =========================================================
-- DUPE TAB
-- =========================================================
do
    local t = tabContents["Dupe"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"DUPE",ord())
    makeButton(t,"Dupe Inventory",dupeInventory,ord())

    makeSeparator(t,"SLOTS",ord())
    for i=1,SLOT_COUNT do
        local slotFrame = Instance.new("Frame")
        slotFrame.Size = UDim2.new(1,-8,0,60)
        slotFrame.BackgroundColor3 = Color3.fromRGB(30,30,45)
        slotFrame.BorderSizePixel = 0
        slotFrame.LayoutOrder = ord()
        slotFrame.Parent = t
        Instance.new("UICorner",slotFrame).CornerRadius = UDim.new(0,4)
        Instance.new("UIPadding",slotFrame).PaddingLeft = UDim.new(0,6)

        local slotLabel = Instance.new("TextLabel")
        slotLabel.Size = UDim2.new(1,0,0,20)
        slotLabel.BackgroundTransparency = 1
        slotLabel.Font = Enum.Font.GothamBold
        slotLabel.TextSize = 12
        slotLabel.TextColor3 = Color3.fromRGB(255,215,0)
        slotLabel.TextXAlignment = Enum.TextXAlignment.Left
        slotLabel.Text = "Slot " .. i .. " — " .. SaveSlotNames[i]
        slotLabel.Parent = slotFrame

        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0.48,0,0,26)
        loadBtn.Position = UDim2.new(0,0,0,26)
        loadBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
        loadBtn.Font = Enum.Font.Gotham
        loadBtn.TextSize = 12
        loadBtn.TextColor3 = Color3.fromRGB(255,255,255)
        loadBtn.Text = "Load Slot"
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = slotFrame
        Instance.new("UICorner",loadBtn).CornerRadius = UDim.new(0,4)
        loadBtn.MouseButton1Click:Connect(function()
            notify("Loading: " .. SaveSlotNames[i])
        end)

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size = UDim2.new(0.48,0,0,26)
        saveBtn.Position = UDim2.new(0.52,0,0,26)
        saveBtn.BackgroundColor3 = Color3.fromRGB(50,50,90)
        saveBtn.Font = Enum.Font.Gotham
        saveBtn.TextSize = 12
        saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
        saveBtn.Text = "Save Slot"
        saveBtn.BorderSizePixel = 0
        saveBtn.Parent = slotFrame
        Instance.new("UICorner",saveBtn).CornerRadius = UDim.new(0,4)
        saveBtn.MouseButton1Click:Connect(function()
            saveSettings()
            notify("Saved to slot " .. i)
        end)
    end
end

-- =========================================================
-- SORTER TAB
-- =========================================================
do
    local t = tabContents["Sorter"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"SORTER",ord())
    makeButton(t,"Sort Player Logs",sorterTab1,ord())
    makeButton(t,"Count Items", function()
        local n = countitems(LocalPlayer.Backpack)
        notify("Items in backpack: " .. n)
    end, ord())
    local ddSort,getSort = makeDropdown(t,"Sort Player",{"TimesSort","Amount"},nil,ord())
    makeButton(t,"Sort by "..getSort(),function()
        sorterTab1()
    end,ord())
    makeButton(t,"Select All Logs", function()
        local re = ReplicatedStorage:FindFirstChild("SelectionTp")
        if re then
            for _,log in pairs(Workspace:GetDescendants()) do
                if log:GetAttribute("WoodType") then
                    re:FireServer(log)
                end
            end
        end
    end, ord())
    makeButton(t,"Select Sawmill Tree", function()
        local re = ReplicatedStorage:FindFirstChild("SelectionTpWOOD")
        if re then re:FireServer() end
    end, ord())
end

-- =========================================================
-- SETTINGS TAB
-- =========================================================
do
    local t = tabContents["Settings"]
    local o = 0
    local function ord() o=o+1 return o end

    makeSeparator(t,"MOVEMENT",ord())
    makeSlider(t,"Walkspeed",16,500,16,setWalkspeed,ord())
    makeSlider(t,"Jump Power",50,500,50,setJumpPower,ord())
    makeSlider(t,"Fly Speed",10,500,50,function(v) Settings.FlySpeed=v end,ord())

    makeSeparator(t,"TOGGLES",ord())
    makeToggle(t,"NoClip","NoClip",nil,ord())
    makeToggle(t,"Infinite Jump","InfiniteJump",nil,ord())
    makeToggle(t,"God Mode","GodMode",setGodMode,ord())
    makeToggle(t,"BetterFly","BetterFly",nil,ord())
    makeToggle(t,"Infinite HRP","InfiniteHrp",infHrp,ord())
    makeToggle(t,"Click to TP","ClickToTP",nil,ord())

    makeSeparator(t,"VISUAL",ord())
    makeSlider(t,"FOV",30,120,70,setFOV,ord())
    makeToggle(t,"No Fog","NoFog",setNoFog,ord())
    makeToggle(t,"Night Mode","Night",setNight,ord())
    makeToggle(t,"Better Graphics","BetterGraphics",betterGraphics,ord())

    makeSeparator(t,"KEYBINDS",ord())
    local ddFlyKey,getFlyKey = makeDropdown(t,"Fly Key",{"E","Q","F","G","H"},nil,ord())

    makeSeparator(t,"SAVE / LOAD",ord())
    makeButton(t,"Save Settings",saveSettings,ord())
    makeButton(t,"Load Settings",loadSettings,ord())
    for i=1,SLOT_COUNT do
        makeButton(t,"Load Slot " .. i, function()
            notify("Loaded slot " .. i .. ": " .. SaveSlotNames[i])
        end, ord())
    end

    makeSeparator(t,"INFO",ord())
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1,-8,0,60)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextColor3 = Color3.fromRGB(160,160,160)
    infoLabel.TextWrapped = true
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.LayoutOrder = ord()
    infoLabel.Text = string.format(
        "Executor: %s\nPing: %dms\nPlayers: %d\nloaded in: %.1fs",
        executor, getPing(), getCounter(), tick() % 100
    )
    infoLabel.Parent = t
end

-- =========================================================
-- CREDITS TAB
-- =========================================================
do
    local t = tabContents["Credits"]
    local o = 0
    local function ord() o=o+1 return o end

    local credits = Instance.new("TextLabel")
    credits.Size = UDim2.new(1,-8,0,200)
    credits.BackgroundTransparency = 1
    credits.Font = Enum.Font.Gotham
    credits.TextSize = 13
    credits.TextColor3 = Color3.fromRGB(200,200,200)
    credits.TextWrapped = true
    credits.RichText = true
    credits.TextYAlignment = Enum.TextYAlignment.Top
    credits.LayoutOrder = ord()
    credits.Text = [[
<b><font color="rgb(255,215,0)">Butter Hub</font></b>
Lumber Tycoon came out 15 years ago

<b>Credits:</b>
Applebox, silentben8x, tip

<b>Discord:</b>
discord.gg/butterhub

<b>Executor:</b> ]] .. executor .. [[

<b>"Butter is good"</b>
<b>"Butter is on"</b>
]]
    credits.Parent = t

    makeButton(t,"Copy Discord Link", function()
        if toclipboard then
            toclipboard("discord.gg/butterhub")
            notify("Copied to clipboard!")
        end
    end, ord())

    makeButton(t,"Beta Features", function()
        notify("Beta features are enabled for this session.")
    end, ord())
end

-- =========================================================
-- CLICK TO TP
-- =========================================================

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if Flags.ClickToTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local ray = Camera:ScreenPointToRay(
            UserInputService:GetMouseLocation().X,
            UserInputService:GetMouseLocation().Y
        )
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000)
        if result then
            RootPart.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0))
        end
    end
end)

-- =========================================================
-- CHARACTER RESPAWN HANDLER
-- =========================================================

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")

    -- Re-apply persistent settings
    Humanoid.WalkSpeed = Settings.Walkspeed
    Humanoid.JumpPower = Settings.JumpPower

    if Flags.GodMode then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health    = math.huge
    end
end)

-- =========================================================
-- STARTUP
-- =========================================================

switchTab("World")
notify("Butter Hub loaded! Butter is on 🧈")
print("Butter Hub | Lumber Tycoon 2 | loaded in | " .. executor)
print("Butter hub has a Discord server https://discord.gg/butterhub")
print("Credits: Applebox, silentben8x, tip")
