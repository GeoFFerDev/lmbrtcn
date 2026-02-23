local Executor = identifyexecutor()

getgenv().Ancestor_Loaded = false

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer:FindFirstChild('PlayerGui') and game.Players.LocalPlayer.PlayerGui:FindFirstChild('OnboardingGUI') and game.Players.LocalPlayer.PlayerGui.OnboardingGUI.DoOnboarding.Loaded.Value

local Maid, Ancestor, GUISettings, Connections = loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/KhayneGleave/Ancestor/main/Maid.txt'))(), {

    SelectedTreeType             = 'Generic',
    BringTreeAmount              = 1,
    AutobuyAmount                = 1,
    AutobuySelectedItem          = 'Basic Hatchet',
    BringTreeSelectedPosition    = 'Current Position',
    RotatingObject               = false,
    Sprinting                    = false,
    ModerationType               = 'Vehicle',
    ModerationAction             = 'Kill',
    InventoryDuplicationAmount   = 1,
    PropertyToDuplicate          = 1,
    PlayerToDuplicatePropertyTo  = game.Players:GetPlayers()[1],
    ModWoodSawmill               = nil,
    AutofarmTrees                = false,
    CharacterGodMode             = 'FirstTimeExecutionProtection',
    IsClientFlying               = false,
    TreeToDismember              = false,
    SelectedVehicleColourToSpawn = 'Dark red',
    CurrentlySavingOrLoading     = nil,
    DonatingProperty             = false,
    SpawnItemsAmount             = 1,
    SpawnItemName                = 'BasicHatchet',
    ModdingWood                  = false

}, {
    
    WalkSpeed                          = 16,
    JumpPower                          = 50,
    HipHeight                          = 0,
    SprintSpeed                        = 20,
    FOV                                = 70,
    InfiniteJump                       = false,
    SelectedDropType                   = 'Both',
    Light                              = false,
    SprintKey                          = 'LeftShift',
    NoclipKey                          = 'LeftControl',
    KeyTP                              = 'G',
    FastCheckout                       = false,
    FixCashierRange                    = false,
    HardDragger                        = false,
    AxeRangeActive                     = false,
    AxeSwingActive                     = false,
    FlyKey                             = 'F',
    WaterWalk                          = false,
    WaterFloat                         = true,
    FlySprintSpeed                     = 10,
    AlwaysDay                          = false,
    AlwaysNight                        = false,
    NoFog                              = false,
    AxeSwing                           = 0,
    AxeRange                           = 0,
    FlySpeed                           = 200,
    CarSpeed                           = 1,
    CarPitch                           = 1,
    AntiAFK                            = (Executor ~= 'Krnl' and true) or false,
    TreesEnabled                       = true,
    StopPlayersLoading                 = false,
    SignDuplicationAmount              = 1,
    TeleportBackAfterBringTree         = true,
    FastRotate                         = false,
    XRotate                            = 1,
    YRotate                            = 1,
    SelectedTreeTypeSize               = 'Largest',
    ActivateVehicleModifications       = true,
    AutoSaveGUIConfiguration           = true,
    Brightness                         = 1,
    GlobalShadows                      = true,
    RejoinExecute                      = false,
    UnboxItems                         = false,
    FreeCamera                         = false,
    WaterGodMode                       = false,
    BetterGraphics                     = false,
    DropToolsAfterInventoryDuplication = false,
    InstantDropAxes                    = false,
    ClickDelete                        = false,
    SellPlankAfterMilling              = false,
    AutoStopOnPinkVehicle              = false,
    DeleteSpawnPadAfterVehicleSpawn    = false,
    AutoChopTrees                      = false,
    SitInAnyVehicle                    = false,
    ClickToSell                        = false

}, {}

local Players, TeleportService, UIS, CoreGui, StarterGui, Lighting, RunService, ReplicatedStorage, HttpService, PerformanceStats, UserInputService, Terrain = game:GetService('Players'), game:GetService('TeleportService'), game:GetService('UserInputService'), game:GetService('CoreGui'), game:GetService('StarterGui'), game:GetService('Lighting'), game:GetService('RunService'), game:GetService('ReplicatedStorage'), game:GetService('HttpService'), game:GetService('Stats').PerformanceStats, game:GetService('UserInputService'), workspace.Terrain

local Player = Players.LocalPlayer

local Mouse = Player:GetMouse()

getgenv().Character = Player.Character or Player.CharacterAdded:Wait()

local PlayerGui, Camera = Player.PlayerGui, workspace.CurrentCamera

local Properties, Stores, PlayerModels = Workspace.Properties:GetChildren(), Workspace.Stores:GetChildren(), Workspace.PlayerModels

local NPCChattingClient, CharacterFloat, PropertyPurchasingClient, LoadSaveClient, UserInput, SettingsClient, InteractionPermission = getsenv(PlayerGui.ChatGUI.NPCChattingClient), getsenv(PlayerGui.Scripts.CharacterFloat), getsenv(PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient), getsenv(PlayerGui.LoadSaveGUI.LoadSaveClient), getsenv(PlayerGui.Scripts.UserInput), getsenv(PlayerGui.SettingsGUI.SettingsClient), require(ReplicatedStorage.Interaction.InteractionPermission)

local RequestLoad, RequestSave, GetMetaData, ClientMayLoad, SendUserNotice, ClientGetUserPermissions, ClientExpandedProperty, ClientPurchasedProperty, ClientInteracted, ClientIsDragging, RemoteProxy, PromptChat, PlayerChatted, SetChattingValue, TestPing, UpdateUserSettings, ClientPlacedStructure, SelectLoadPlot, ClientPlacedBlueprint, DestroyStructure = ReplicatedStorage.LoadSaveRequests.RequestLoad, ReplicatedStorage.LoadSaveRequests.RequestSave, ReplicatedStorage.LoadSaveRequests.GetMetaData, ReplicatedStorage.LoadSaveRequests.ClientMayLoad, ReplicatedStorage.Notices.SendUserNotice, ReplicatedStorage.Interaction.ClientGetUserPermissions, ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty, ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty, ReplicatedStorage.Interaction.ClientInteracted, ReplicatedStorage.Interaction.ClientIsDragging, ReplicatedStorage.Interaction.RemoteProxy, ReplicatedStorage.NPCDialog.PromptChat, ReplicatedStorage.NPCDialog.PlayerChatted, ReplicatedStorage.NPCDialog.SetChattingValue, ReplicatedStorage.TestPing, ReplicatedStorage.Interaction.UpdateUserSettings, ReplicatedStorage.PlaceStructure.ClientPlacedStructure, ReplicatedStorage.PropertyPurchasing.SelectLoadPlot,  ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint, ReplicatedStorage.Interaction.DestroyStructure

local LoadPass = getupvalue(LoadSaveClient.saveSlot, 12)

local AxeFolder, LogModels, ClientItemInfo, Util = ReplicatedStorage.AxeClasses, workspace.LogModels, ReplicatedStorage.ClientItemInfo, ReplicatedStorage:WaitForChild('Util', 10) 

local TransientFunctionCache = require(Util:WaitForChild('TransientFunctionCache', 10))

local VehicleColours = {'Dark red','Sand red','Sand yellow metalic','Lemon metalic','Gun metalic','Earth orange','Earth yellow','Brick yellow','Rust','Really black','Faded green','Sand green','Black metalic','Dark grey metallic','Dark grey','Silver','Medium stone grey','Mid grey', 'Hot pink'}

local ConfigurationIsIntact = pcall(function()

    HttpService:JSONDecode(readfile('AncestorV2Configuration.cfg'))

end)

if not getgenv().UserCanInteract then

    getgenv().CharacterFloatOld = CharacterFloat.isInWater
    getgenv().UserCanInteract = InteractionPermission.UserCanInteract
    getgenv().BetterGraphicsEnabled = false

end

getgenv().LoadedTrees = {

    ['Update'] = function(_, Tree)

    LoadedTrees[#LoadedTrees + 1] = {

        Parent = Tree.Parent,
        Model  = Tree

    }

    Tree.Parent = (GUISettings.TreesEnabled and Tree.Parent) or Lighting
    
end}

if not isfile('AncestorSlotNames.cfg') then

    local DefaultSlotNames = {}

    DefaultSlotNames[tostring(Player)] = {

        Slot1 = 'Slot 1',
        Slot2 = 'Slot 2',
        Slot3 = 'Slot 3',
        Slot4 = 'Slot 4',
        Slot5 = 'Slot 5',
        Slot6 = 'Slot 6'

    }

    writefile('AncestorSlotNames.cfg', HttpService:JSONEncode(DefaultSlotNames))

end

local CashiersAutobuy = {}

local CashierIDConnection = PromptChat.OnClientEvent:Connect(function(_, Cashier)

    if CashiersAutobuy[Cashier.Name] == nil then

        CashiersAutobuy[Cashier.Name] = Cashier.ID

    end

end)

Maid.Threads:Create(function()  

    SetChattingValue:InvokeServer(1)

    repeat Maid.Timer:Wait() until CashiersAutobuy['Hoover'] ~= nil

    CashierIDConnection:Disconnect()
    CashierIDConnection = nil
    SetChattingValue:InvokeServer(0)

end)


local AncestorSlotNames = HttpService:JSONDecode(readfile('AncestorSlotNames.cfg'))
local DoesPlayerExist = AncestorSlotNames[tostring(Player)] ~= nil

if not DoesPlayerExist then

    local DefaultSlotNames = {}

    DefaultSlotNames = {

        Slot1 = 'Slot 1',
        Slot2 = 'Slot 2',
        Slot3 = 'Slot 3',
        Slot4 = 'Slot 4',
        Slot5 = 'Slot 5',
        Slot6 = 'Slot 6'

    }

    local SlotNamesOld = HttpService:JSONDecode(readfile('AncestorSlotNames.cfg'))
    SlotNamesOld[tostring(Player)] = DefaultSlotNames
    writefile('AncestorSlotNames.cfg', HttpService:JSONEncode(SlotNamesOld))

end

if not isfile('AncestorV2Configuration.cfg') then

    writefile('AncestorV2Configuration.cfg', HttpService:JSONEncode(GUISettings))

end

local DefaultSettings = GUISettings

GUISettings = HttpService:JSONDecode(readfile('AncestorV2Configuration.cfg'))

if not ConfigurationIsIntact then

    delfile('AncestorV2Configuration.cfg')
    writefile('AncestorV2Configuration.cfg', HttpService:JSONEncode(GUISettings))

    SendUserNotice:Fire('Configuration File Was Corrupted, Probably Due To Power Loss. Reverted To Default Settings.')

end

PlayerDropType = GUISettings.SelectedDropType

for Index, Value in next, DefaultSettings do 

    if GUISettings[Index] == nil then 

        GUISettings[Index] = Value 

        writefile('AncestorV2Configuration.cfg', HttpService:JSONEncode(GUISettings))

        SendUserNotice:Fire('Updated Configuration For Latest Ancestor Version.')
        
    end

end

local Slots = HttpService:JSONDecode(readfile('AncestorSlotNames.cfg'))
local SlotNames = Slots[tostring(Player)]

function Ancestor:GetModelByName(Name)

    local PlayerModels = workspace.PlayerModels:GetChildren()

    for i = 1, #PlayerModels do

        local Model = PlayerModels[i]

        if Model:FindFirstChild('Owner') and Model.Owner.Value == Player then

            local ItemType = Model:FindFirstChild('ItemName')

            if ItemType and tostring(ItemType.Value):match(Name) then

                return Model

            end

        end

    end

    return false

end

function Ancestor:DropTool(Axe)

    ClientInteracted:FireServer(Axe, 'Drop tool',Player.Character.PrimaryPart.CFrame)

end

function Ancestor:DropTools()

    Player.Character.Humanoid:UnequipTools()

    local Axes = self:GetAxes()

    -- Step 1: Drop ALL axes into the world first so the server registers them
    for i = 1, #Axes do

        local Axe = Axes[i]

        self:DropTool(Axe)

        -- Small gap so the server processes each drop remote before the next
        Maid.Timer:Wait(0.1)

    end

    -- Step 2: If either dupe flag is active, die shortly after dropping
    -- This is the trick: axes are already in the world when we die,
    -- so they stay there AND we respawn with copies still in our inventory save
    if GUISettings.InstantDropAxes or GUISettings.DropToolsAfterInventoryDuplication then

        -- Brief buffer so the last drop remote is processed server-side
        Maid.Timer:Wait(0.15)

        self:SafeSuicide()

    end

end

function Ancestor:FastRotate(State)

    setconstant(UserInput.getSteerFromKeys, 1, (State and GUISettings.FastRotate and GUISettings.XRotate) or 1)
    setconstant(UserInput.getThrottleFromKeys, 1, (State and GUISettings.FastRotate and GUISettings.YRotate) or 1)

end

function Ancestor:SellSigns()

    self:BringAll('PropertySoldSign', CFrame.new(315, 3, 85))

end

Connections.RotateStarted = {Function = UserInputService.InputBegan:Connect(function(Key, Processed)

    if Key.KeyCode == Enum.KeyCode.LeftShift and not Processed then

        Ancestor.RotatingObject = true

    end

end)}

Connections.RotateEnded = {Function = UserInputService.InputEnded:Connect(function(Key, Processed)

    if Key.KeyCode == Enum.KeyCode.LeftShift and not Processed then

        Ancestor.RotatingObject = false

    end

end)}

function Ancestor:SaveSlotNames()

    local SlotNamesOld = HttpService:JSONDecode(readfile('AncestorSlotNames.cfg'))
    SlotNamesOld[tostring(Player)] = nil
    SlotNamesOld[tostring(Player)] = SlotNames
    writefile('AncestorSlotNames.cfg', HttpService:JSONEncode(SlotNamesOld))
    SendUserNotice:Fire('Saved Slot Names.')

end

function Ancestor:SaveConfigurationFile(Bypass)

    writefile('AncestorV2Configuration.cfg', HttpService:JSONEncode(GUISettings))

    if not Bypass then
    
        SendUserNotice:Fire('Saved Configuration File!')

    end

end

function Ancestor:DeleteConfigurationFile()

    GUISettings.AutoSaveGUIConfiguration = false
    delfile('AncestorV2Configuration.cfg')
    SendUserNotice:Fire('Deleted Configuration File!')

end

function Ancestor:CheckClientPrivilege(Player, Privilege)

    return TransientFunctionCache:New(function(...)
            
        return ClientGetUserPermissions:InvokeServer(...)

    end, 1, {
        
        ReturnOldResultInsteadOfYielding = true
    
    }).Callback(Player, Privilege)

end

function Ancestor:CheckPrivilege(Player, Privilege)

    return ClientGetUserPermissions:InvokeServer(Player.UserId, Privilege)

end

Connections.DeathFix = {Function = Player.CharacterAdded:Connect(function()

    repeat Maid.Timer:Wait() 

    until Player.Character:FindFirstChild('Humanoid')

    Ancestor:ApplyLight()
    Ancestor:Fly()

    if Ancestor.CharacterGodMode then 

        Ancestor:GodMode()

    end

    Connections.AxeModifier ={Function = Player.Character.ChildAdded:Connect(function(Tool)

        if Tool:IsA('Tool') then

            repeat Maid.Timer:Wait()until getconnections(Tool.Activated)[1]

            if GUISettings.AxeRangeActive then 

                Ancestor:SetAxeRange(true, GUISettings.AxeRange)

            end

            if GUISettings.AxeSwingActive then 

                Ancestor:SetSwingCooldown(true,GUISettings.AxeSwing)
            end

        end

    end)}

    Connections.CharacterDied = {Function = Player.Character.Humanoid:GetPropertyChangedSignal('Health'):Connect(function()

        if Player.Character.Humanoid.Health <= 0 then
        
            self:GetConnection('AxeModifier', true)

        end

    end)}

end)}

--// ANCESTOR API

function Ancestor:GetAllTrees()
    
    LoadedTrees = {

        ['Update'] = function(_, Tree)
    
        LoadedTrees[#LoadedTrees + 1] = {
    
            Parent = Tree.Parent,
            Model  = Tree
    
        }
    
        Tree.Parent = (GUISettings.TreesEnabled and Tree.Parent) or Lighting
    
    end}

    local Children = workspace:GetChildren()

    for i = 1, #Children do

        local TreeRegion = Children[i]

        if tostring(TreeRegion):match('TreeRegion') then

            local Trees = TreeRegion:GetChildren()

            for i = 1, #Trees do

                local Tree = Trees[i]

                if Tree:FindFirstChild('TreeClass') and #Tree:GetChildren() >= 4 then

                    LoadedTrees[#LoadedTrees + 1] = {

                        Parent = Tree.Parent,
                        Model  = Tree

                    }

                end
        
            end

        end

    end

    return LoadedTrees

end

function Ancestor:GetLava()
    
    local Lava = workspace['Region_Volcano']:GetChildren()
    
    for i = 1, #Lava do 
        
        local Lava = Lava[i]
        
        if Lava:FindFirstChild('Lava') and Lava.Lava.CFrame == CFrame.new(-1675.2002, 255.002533, 1284.19983, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268) then 
            
            return Lava
            
        end
        
    end
    
end

local LavaPart = Ancestor:GetLava()

function Ancestor:SetAxeRange(Active, Value)

    local Tool =Player.Character:FindFirstChildOfClass('Tool')

    if not Tool or not AxeRangeLabel then

        return

    end

    local AttemptChop = getconnections(Tool.Activated)[1].Function
    local OldStats = getupvalues(AttemptChop)
    local NewStats = OldStats[1]

    NewStats.Range = (Active and Value) or require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Tool.ToolName.Value))).new().Range

    AxeRangeLabel:UpdateText('Range: ' .. tostring(NewStats.Range))
    setupvalue(AttemptChop, 1, NewStats)

end

function Ancestor:UpdateAxeInfo()

    if not AxeNameLabel or not AxeRangeLabel or not AxeCooldownLabel then

        return

    end

    if Player.Character:FindFirstChild('Tool') then

        local Tool =Player.Character:FindFirstChild('Tool')
        repeat Maid.Timer:Wait()

        until getconnections(Tool.Activated)[1] ~= nil

        local AttemptChop = getconnections(Tool.Activated)[1].Function
        local Stats = getupvalues(AttemptChop)[1]

        AxeNameLabel:UpdateText('Name: ' ..Player.Character.Tool.ToolName.Value)
        AxeRangeLabel:UpdateText('Range: ' .. tostring(Stats.Range))
        AxeCooldownLabel:UpdateText('Cooldown: ' .. tostring(Stats.SwingCooldown))

    else

        AxeNameLabel:UpdateText('Current Axe Not Found')
        AxeRangeLabel:UpdateText('Range: Not Currently Available')
        AxeCooldownLabel:UpdateText('Cooldown: Not Currently Available')

    end

end

Connections.UpdateAxeEquip = {Function = RunService.Stepped:Connect(function(Tool)

    pcall(function()

        Ancestor:UpdateAxeInfo()

    end)

end)}

function Ancestor:Rejoin()

    if GUISettings.RejoinExecute then

        if not syn then

            RejoinToggle:Toggle()
            return SendUserNotice:Fire('Re-Execution Is Only Supported On Synapse X.')

        end
        
        syn.queue_on_teleport([[

            repeat task.Wait() until game:IsLoaded()
            loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/KhayneGleave/Ancestor/main/AncestorV2'))()


        ]])

    end

    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)

end

function Ancestor:SetThreadContext(Level)

    if Executor == 'Krnl' then 

        return SendUserNotice:Fire('Use Fluxus or a paid executor to use')

    end

    if syn then 

        syn.set_thread_identity(Level)

    else

        setthreadcontext(Level)

    end
    
end

function Ancestor:SetSwingCooldown(Active)

    local Tool = Player.Character:FindFirstChildOfClass('Tool')

    if not Tool or not AxeCooldownLabel then

        return

    end

    local AttemptChop = getconnections(Tool.Activated)[1].Function

    local OldStats = getupvalues(AttemptChop)
    local NewStats = OldStats[1]

    local Cooldown = require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Tool.ToolName.Value))).new().SwingCooldown

    NewStats.SwingCooldown = (Active and Cooldown / 2) or Cooldown

    AxeCooldownLabel:UpdateText(string.format('Cooldown : %s', tostring(NewStats.SwingCooldown)))

    setupvalue(AttemptChop, 1, NewStats)

end

function Ancestor:ToggleTrees(State)

    Maid.Threads:Create(function()

        for i = 1, #LoadedTrees do 

            pcall(function()
            
                local Tree = LoadedTrees[i]

                if not Tree.Model:FindFirstChild('WoodSection') then 

                    Tree.Model:Destroy()

                    LoadedTrees[i] = nil

                end

                Tree.Model.Parent = (State and Tree.Parent) or Lighting

            end)
                
        end

    end)

end

function Ancestor:GetConnection(Name, DisconnectConnection)

    for Connection, Data in next, Connections do

        if tostring(Connection) == tostring(Name) then

            if DisconnectConnection then

                Data.Function:Disconnect()
                Connections[Name] = nil

                return false

            end

            return Data.Function

        end
        
    end

    return false

end

function Ancestor:FastCheckout(Value)

    setconstant(NPCChattingClient.advanceChat, 19, Value)

end

function Ancestor:MergeTables(Tbl, NewTbl)

    for Index, Value in next, Tbl do 

        NewTbl[#NewTbl + 1] = Value 

    end

    return NewTbl

end

function Ancestor:GetAxes()

    local Axes = {}
    local Tools = self:MergeTables(Player.Backpack:GetChildren(), Player.Character:GetChildren())

    for i = 1, #Tools do

        local Axe = Tools[i]

        if Axe:FindFirstChild('CuttingTool') then

            Axes[#Axes + 1] = Axe

        end

    end

    return Axes

end

function Ancestor:GetPlayersSlotInfo(Client)

    local Data = GetMetaData:InvokeServer(Players[tostring(Client)])

    local Info = {}

    for i = 1, #Data do

        if Data[i].SaveMeta[#Data[i].SaveMeta] then

            local Datasize = Data[i].SaveMeta[#Data[i].SaveMeta].NumKeys

            Info[#Info + 1] = Datasize

        end

    end

    return Info

end

function Ancestor:DoesAxeExist()

    return Ancestor:GetAxes()[1] ~= nil

end

function Ancestor:GetLoadedSlot()

    return Player.CurrentSaveSlot.Value

end

function Ancestor:SaveSlot()

    if self.CurrentlySavingOrLoading or self.DonatingProperty then 

        return SendUserNotice:Fire((self.CurrentlySavingOrLoading and 'You Are Currently Saving/Loading') or 'Cannot Perform This Action During Property Duplication.')

    end

    self.CurrentlySavingOrLoading = true
    RequestSave:InvokeServer(self:GetLoadedSlot(), Player)
    self.CurrentlySavingOrLoading = false

end

function Ancestor:DeleteSlot(SlotNumber)

    if self.CurrentlySavingOrLoading or self.DonatingProperty then 

        return SendUserNotice:Fire((self.CurrentlySavingOrLoading and 'You Are Currently Saving/Loading') or 'Cannot Perform This Action During Property Duplication.')

    end

    if Ancestor:GetLoadedSlot() ~= -1 then

        SendUserNotice:Fire('Unloading Current Slot... Please Wait.')

    end

    self.CurrentlySavingOrLoading = true
    RequestLoad:InvokeServer(math.huge, Player)
    Ancestor:Set(-1)
    RequestSave:InvokeServer(SlotNumber, Player)
    SendUserNotice:Fire(string.format('Deleted Slot %s.', tostring(SlotNumber)))
    self.CurrentlySavingOrLoading = false 

end

function Ancestor:GetSignClosestToPlayer()

    local Max, PlayerModels, ClosestSign = 9e9, PlayerModels:GetChildren(), nil

    for i = 1, #PlayerModels do

        local Sign = PlayerModels[i]

        if Sign:FindFirstChild('ItemName') and tostring(Sign.ItemName.Value) == 'PropertySoldSign' and Sign:FindFirstChild('Owner') and tostring(Sign.Owner.Value) == tostring(Player) then 
            
            if (Player.Character.PrimaryPart.CFrame.p - Sign.PrimaryPart.CFrame.p).Magnitude <= Max then 

                ClosestSign = Sign 
                Max = (Player.Character.PrimaryPart.CFrame.p - Sign.PrimaryPart.CFrame.p).Magnitude

            end

        end

    end

    return ClosestSign

end

function Ancestor:GetFreeLand()

    local Max, NearestProperty = 9e9

    for i = 1, #Properties do

        local Property = Properties[i]

        if Property.Owner.Value == nil and (Property.OriginSquare.CFrame.p - Player.Character.Head.CFrame.p).Magnitude < Max then

            NearestProperty = Property
            Max = (Property.OriginSquare.CFrame.p - Player.Character.Head.CFrame.p).Magnitude

        end

    end

    return NearestProperty

end

function Ancestor:GetOrphanedHillProperty()

    local Properties, HillProperties = workspace.Properties:GetChildren(), {
    
        ['-240, 19, 204, 1, 0, 0, 0, 1, 0, 0, 0, 1'] = true,
        ['-61, 19, 526, 1, 0, 0, 0, 1, 0, 0, 0, 1']  = true
        
    }
    
    for i = 1, #Properties do 
    
        local Property = Properties[i]
    
        if rawget(HillProperties, tostring(Property.OriginSquare.CFrame)) and Property.Owner.Value == nil then 
    
            return Property
            
        end
    
    end

    return false

end

--[[

    0, 0, 0 = Left
    0,-90,0 = front
    0,90,0  = back
    0,180,0 = right

]]

function Ancestor:ModSawmill()

    self.ModWoodSawmill = nil

    self:SelectSawmill('To Mod')

    repeat Maid.Timer:Wait() until self.ModWoodSawmill

    local Conveyor, Conveyors = nil, self.ModWoodSawmill.Conveyor.Model:GetChildren()

    local Orientation = self.ModWoodSawmill.Main.Orientation.Y

    for i = (self.ModWoodSawmill.ItemName.Value:match('Sawmill4L') and  #Conveyors - 1) or #Conveyors, #Conveyors do 
        
        Conveyor = Conveyors[i]

        break
        
    end

    local Offset = .4

    for i = 1, 4 do
        
        Offset += .2

        ClientPlacedBlueprint:FireServer('Floor2', CFrame.new(Conveyor.CFrame.p + Vector3.new((Orientation == 0 and -Offset) or (Orientation == 180 and Offset) or 0, 1.5, (Orientation == -90 and -Offset) or (Orientation == 90 and Offset))) * CFrame.Angles(math.rad(((Orientation == 180 or Orientation == 0) and 90) or 45), math.rad(((Orientation == 180 or Orientation == 0) and 0) or 90), math.rad(((Orientation == 180 or Orientation == 0) and 90) or 45)), Player)
        Maid.Timer:Wait(1.5)

    end

    SendUserNotice:Fire('Fill Blueprint To Complete Mod. \n\nThis Will Be Automated In The Future.')

end

function Ancestor:FreeLand(IgnoreTeleport, ForceHillLoad)

    -- if Ancestor:GetPlayersBase(Player) then

    --     return SendUserNotice:Fire('You already have a Property!')

    -- end

    local Property = ForceHillLoad and self:GetOrphanedHillProperty() or Ancestor:GetFreeLand()

    if ForceHillLoad and not Property then

        return SendUserNotice:Fire('Please Make Sure At Least One Property On The Hill Is Free.')

    end

    if not Property then 

        repeat Maid.Timer:Wait()

            Property = Ancestor:GetFreeLand()

        until Property 

    end

    ClientPurchasedProperty:FireServer(Property, Property.OriginSquare.CFrame.p)

    if not IgnoreTeleport then

        SendUserNotice:Fire('Free Land Acquired.')
        
    end

    if not ForceHillLoad then

        self:Teleport(CFrame.new(Property.OriginSquare.CFrame.p) + Vector3.new(0, 5, 0))

    end

    repeat Maid.Timer:Wait() until workspace.Effects:FindFirstChild('Particles') and (Player.Character.PrimaryPart.CFrame.p - Property.OriginSquare.CFrame.p).Magnitude < 15

    local Sign = self:GetSignClosestToPlayer()

    if not Sign then 

        repeat Maid.Timer:Wait()

            Sign = self:GetSignClosestToPlayer()

        until Sign

    end

    return Property

end

local enterPurchaseMode = PropertyPurchasingClient.enterPurchaseMode

local PlayerObjects = {
    
    ['Tool']         = {},
    ['Structure']    = {},
    ['Loose Item']   = {},
    ['Furniture']    = {},
    ['Vehicle']      = {},
    ['Vehicle Spot'] = {},
    ['Wire']         = {},
    ['Gift']         = {}
    
}

function GetType(SelectedObject)
    
    local Objects = ClientItemInfo:GetChildren()

    for i = 1, #Objects do 
    
        local Object = Objects[i]

        if tostring(Object) == SelectedObject then 
            
            return Object.Type.Value
            
        end
        
    end
    
    return false
    
end

SelectLoadPlot.OnClientInvoke = function(StructureModel)
    
    local PreviewModel = StructureModel
    
    local StructureModel = StructureModel:GetChildren()
    
    for i = 1, #StructureModel do 
        
        local Object = StructureModel[i]
    
        if not tostring(Object):match('Square') and not tostring(Object):match('PropertySoldSign') and not tostring(Object):match('Plank') then

            local Type = GetType(tostring(Object))

            if Type then    

                PlayerObjects[Type][#PlayerObjects[Type] + 1] = Object

            end
            
        end
        
    end
    
    for Index, DataType in next, PlayerObjects do
        
        warn(string.format('[%s]: Count: %s', string.upper(Index), tostring(#DataType)))
        
    end
    
    Ancestor:SetThreadContext(2)
        
    enterPurchaseMode(0, false, PreviewModel)

    Maid.Threads:Create(function()

        if Ancestor.DonatingProperty then

            Ancestor:SetThreadContext(8)

            Ancestor.DonatingProperty = false
            Maid.Timer:Wait(End / 1.5)
            game:shutdown()

        end
    
    end)
        
    return getupvalue(PropertyPurchasingClient.enterPurchaseMode, 10), 0
    
end

Connections.ClearPlayerObjects = {Function = Player.CurrentSaveSlot:GetPropertyChangedSignal('Value'):Connect(function()

    PlayerObjects =  {
    
        ['Tool']         = {},
        ['Structure']    = {},
        ['Loose Item']   = {},
        ['Furniture']    = {},
        ['Vehicle']      = {},
        ['Vehicle Spot'] = {},
        ['Wire']         = {},
        ['Gift']         = {}

    }

end)}

function Ancestor:MaxLand(Property, IgnoreLimit)

    if not Ancestor:GetPlayersBase(Player) then

        Ancestor:FreeLand()
        
        repeat Maid.Timer:Wait() 
        
        until Ancestor:GetPlayersBase(Player)

    end

    if not Property then

        Property = Ancestor:GetPlayersBase(Player)

    end

    local OriginSquare = Property.OriginSquare
    local Squares = #Property:GetChildren()

    if Squares >= 26 then

        return SendUserNotice:Fire('Already Max-Landed.')

    end

    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 40, OriginSquare.Position.Y, OriginSquare.Position.Z))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 40, OriginSquare.Position.Y, OriginSquare.Position.Z))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X, OriginSquare.Position.Y, OriginSquare.Position.Z + 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X, OriginSquare.Position.Y, OriginSquare.Position.Z - 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 40, OriginSquare.Position.Y, OriginSquare.Position.Z + 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 40, OriginSquare.Position.Y, OriginSquare.Position.Z - 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 40, OriginSquare.Position.Y, OriginSquare.Position.Z + 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 40, OriginSquare.Position.Y, OriginSquare.Position.Z - 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 80, OriginSquare.Position.Y, OriginSquare.Position.Z))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 80, OriginSquare.Position.Y, OriginSquare.Position.Z))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X, OriginSquare.Position.Y, OriginSquare.Position.Z + 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X, OriginSquare.Position.Y, OriginSquare.Position.Z - 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 80, OriginSquare.Position.Y, OriginSquare.Position.Z + 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 80, OriginSquare.Position.Y, OriginSquare.Position.Z - 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 80, OriginSquare.Position.Y, OriginSquare.Position.Z + 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 80, OriginSquare.Position.Y, OriginSquare.Position.Z - 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 40, OriginSquare.Position.Y, OriginSquare.Position.Z + 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 40, OriginSquare.Position.Y, OriginSquare.Position.Z + 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 80, OriginSquare.Position.Y, OriginSquare.Position.Z + 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 80, OriginSquare.Position.Y, OriginSquare.Position.Z - 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 80, OriginSquare.Position.Y, OriginSquare.Position.Z + 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 80, OriginSquare.Position.Y, OriginSquare.Position.Z - 40))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X + 40, OriginSquare.Position.Y, OriginSquare.Position.Z - 80))
    ClientExpandedProperty:FireServer(Property, CFrame.new(OriginSquare.Position.X - 40, OriginSquare.Position.Y, OriginSquare.Position.Z - 80))
    
    if not IgnoreLimit then
        
        Ancestor:Teleport(CFrame.new(Property.OriginSquare.CFrame.p) + Vector3.new(0, 5, 0))
        
    end
    
end

function Ancestor:BuyItem(Details)

    local Cashier, CashierID = Details.Model, CashiersAutobuy[tostring(Details.Model)]

    if Cashier and CashierID then

        PlayerChatted:InvokeServer({Character = Cashier, Name = Cashier, ID = CashierID}, 'ConfirmPurchase')

    end

end

function Ancestor:GetClientMoney()

    return Player.leaderstats.Money.Value

end

function Ancestor:GetBestAxe()

    local Axes, BestAxe, BestDamage, Damage = {}, nil, 0, nil

    local Tools = self:MergeTables(Player.Backpack:GetChildren(),Player.Character:GetChildren())

    for i = 1, #Tools do 

        local Tool = Tools[i]

        if Tool:FindFirstChild('CuttingTool') then

            Axes[#Axes + 1] = Tool

        end

    end

    for i = 1, #Axes do 

        local Axe = Axes[i]

        if Axe:FindFirstChild('ToolName') and AxeFolder:FindFirstChild('AxeClass_'..tostring(Axe.ToolName.Value)) then

            if self.SelectedTreeType == 'LoneCave' and Axe.ToolName.Value == 'EndTimesAxe' then 

                return Axe

            end

            if self.SelectedTreeType == 'Volcano' and Axe.ToolName.Value == 'FireAxe' then 

                return Axe

            end

            if self.SelectedTreeType == 'CaveCrawler' and Axe.ToolName.Value == 'CaveAxe' then 

                return Axe

            end

            if self.SelectedTreeType == 'Frost' and Axe.ToolName.Value == 'IceAxe' then 

                return Axe

            end

            if self.SelectedTreeType == 'GoldSwampy' and Axe.ToolName.Value == 'AxeSwamp' then 

                return Axe

            end

            AxeStats = require(AxeFolder:FindFirstChild('AxeClass_'..tostring(Axe.ToolName.Value))).new()

            if AxeStats.SpecialTrees then

                if AxeStats.SpecialTrees[Ancestor.SelectedTreeType] then

                    return Axe

                end

            end

            Damage = AxeStats.Damage

            Range = AxeStats.Range

            if Damage > BestDamage then

                BestDamage = Damage
                BestAxe = Axe

            end

        end

    end

    return BestAxe

end

function Ancestor:IsNetworkOwnerOfModel(Model)

    if (Executor == 'Krnl' or Executor == 'Fluxus' or 'Valyse') then 

        for i = 1, 4 do 

            TestPing:InvokeServer()

        end

        return true

    end

    local Children = Model:GetChildren()

    for i = 1, #Children do 

        local Child = Children[i]

        if Child:IsA('BasePart') and isnetworkowner(Child) then 

            return true 

        end

    end

end

function Ancestor:GetPlotButtonByID(ID)

    local Amount = -1
    local Buttons = PlayerGui.LoadSaveGUI.SlotList.Main:GetChildren()

    for i = 1, #Buttons do
        local Button = Buttons[i]

        if Button.ClassName == 'TextButton' then

            Amount = Amount + 1

            if Amount == ID then

                return Button.SlotName

            end

        end

    end

end

function Ancestor:SellAllLogs()

    local Logs = workspace.LogModels:GetChildren()

    for i = 1, #Logs do 

        local Log = Logs[i]

        if Log:FindFirstChild('Owner') and (Log.Owner.Value == nil or Log.Owner.Value == Player) then 

        Log.PrimaryPart = Log.PrimaryPart or Log:FindFirstChildOfClass('Part')

            pcall(function()

                repeat Maid.Timer:Wait()

                    if not Log.PrimaryPart then 

                        break

                    end

                    if (Player.Character.Head.CFrame.p - Log.PrimaryPart.CFrame.p).Magnitude >= 8 then

                        self:Teleport(CFrame.new(Log.PrimaryPart.CFrame.p + Vector3.new(0, 5, 0)))
    
                    end

                    ClientIsDragging:FireServer(Log)
                
                until self:IsNetworkOwnerOfModel(Log)

                for i = 1, 35 do 

                    Log:PivotTo(CFrame.new(315, 3, 85))

                end

            end)

        end

    end

end

function Ancestor:GetVehicle()

    return (Player.Character.Humanoid.SeatPart and Player.Character.Humanoid.SeatPart.Parent)

end

function Ancestor:ForcePlayerIntoClientVehicle()

    local Vehicle = self:GetVehicle()

    if Vehicle and Vehicle:FindFirstChild('DriveSeat') then 

        repeat Maid.Timer:Wait()

            self:Teleport(Ancestor.PlayerToModerate.Player.Character.PrimaryPart.CFrame * CFrame.Angles(math.rad(-180), 0, 0) + Vector3.new(-1, 2, 0))

        until Ancestor.PlayerToModerate.Player.Character.Humanoid.SeatPart == Vehicle.Seat

    end

    return Ancestor.PlayerToModerate.Player.Character.Humanoid.SeatPart == Vehicle.Seat

end

function Ancestor:PlaceObject(Model, CF, SelectedPlayer)

    local ItemName = Model:WaitForChild('ItemName', 10) or Model:WaitForChild('PurchasedBoxItemName', 10)

    if not ItemName then 

        self:GetConnection('ObjectPlaced', true)
        return SendUserNotice:Fire(string.format('%s Doesn\'t Support This Teleportation Method', tostring(Model)))

    end

    SelectedPlayer = SelectedPlayer or Player

    Connections.ObjectPlaced = {PlayerModels.ChildAdded:Connect(function(Child)

        local Owner, ItemName = Child:WaitForChild('Owner', 10), Child:WaitForChild('ItemName', 10)

        if Owner and Owner.Value == SelectedPlayer and Child:FindFirstChild('ItemName') and Child.ItemName.Value:match(ItemName.Value) then

            self:GetConnection('ObjectPlaced', true)

            ObjectPlaced = Child

        end
    
    end)}

    ClientPlacedStructure:FireServer(tostring(Model.ItemName.Value), CF, Player, nil, Model, true)

    repeat Maid.Timer:Wait() until typeof(self:GetConnection('ObjectPlaced')) ~= 'RBXScriptConnection'

    return ObjectPlaced

end

function Ancestor:CarKill()

    local Vehicle = self:ForcePlayerIntoClientVehicle()
    local OldPosition = Player.Character.HumanoidRootPart.CFrame

    if Vehicle then 

        self:Teleport(CFrame.new(-1887, 512, 1053))

        repeat Maid.Timer:Wait()

            firetouchinterest(Ancestor.PlayerToModerate.Player.Character.Head, LavaPart.Lava, 0)
            firetouchinterest(Ancestor.PlayerToModerate.Player.Character.Head, LavaPart.Lava, 1)

        until Ancestor.PlayerToModerate.Player.Character.Head:FindFirstChild('LavaFire')

        self:Teleport(OldPosition)

    end

end

function Ancestor:BetterGraphics()

    BetterGraphicsEnabled = (tonumber(string.format('%.2f', Lighting.ExposureCompensation)) == .03 and true) or false

    if BetterGraphicsEnabled and GUISettings.BetterGraphics then

        return

    end

    local LightingObjects = Lighting:GetChildren()

    for i = 1, #LightingObjects do 

        local Object = LightingObjects[i]

        if not (Object.Name == 'Spook' or Object.Name == 'SunPos') then

            Object:Destroy()

        end

    end

    local Water = workspace.Water:GetChildren()
    local WaterBridge = workspace.Bridge.VerticalLiftBridge.WaterModel:GetChildren()
    
    for i = 1, #WaterBridge do
        
        local Water = WaterBridge[i]
        Water.CanCollide = GUISettings.WaterWalk
        Water.Transparency = (GUISettings.BetterGraphics and 1) or 0
        Water.Orientation = Vector3.new(0, 0, 0)

        if Water:FindFirstChild('Mesh') then

            Water:FindFirstChild('Mesh'):Destroy()

        end

        if tostring(Water):match('Water') then

            Water.Size = Vector3.new(Water.Size.X, 48, Water.Size.Z)

            Water.Position = Vector3.new(Water.Position.X, -37.5, Water.Position.Z)

            Terrain:FillBlock(Water.CFrame, (Water.Size.Y == 48 and not GUISettings.BetterGraphics and Water.Size + Vector3.new(0, 90, 0) or Water.Size), (GUISettings.BetterGraphics and Enum.Material.Water) or Enum.Material.Air)
            
        end
    
    end
    
    for i = 1, #Water do
        
        local Water = Water[i]
        Water.CanCollide = GUISettings.WaterWalk
        Water.Transparency = (GUISettings.BetterGraphics and 1) or 0

        Water.Orientation = Vector3.new(0, 0, 0)

        if Water:FindFirstChild('Mesh') then

            Water:FindFirstChild('Mesh'):Destroy()

        end

        if tostring(Water):match('Water') then
        
            Water.Size = Vector3.new(Water.Size.X, 48, Water.Size.Z)

            Water.Position = Vector3.new(Water.Position.X, -37.5, Water.Position.Z)
        
            Terrain:FillBlock(Water.CFrame, (Water.Size.Y == 48 and not GUISettings.BetterGraphics and Water.Size + Vector3.new(0, 90, 0) or Water.Size), (GUISettings.BetterGraphics and Enum.Material.Water) or Enum.Material.Air)
    
        end
        
    end

    Lighting.GlobalShadows = GUISettings.GlobalShadows
    Lighting.GeographicLatitude = 0
    Lighting.ExposureCompensation = (GUISettings.BetterGraphics and .03) or 0
    Terrain.WaterColor = Color3.fromRGB(40, 40, 40)
    Terrain.WaterReflectance = .3
    Terrain.WaterWaveSize = 1
    Terrain.WaterWaveSpeed = 5

    if not GUISettings.BetterGraphics then 

        return 

    end
    
    local Blur = Instance.new('BlurEffect', Lighting)
    local ColorCorrectionEffect = Instance.new('ColorCorrectionEffect', Lighting)
    local SunRaysEffect = Instance.new('SunRaysEffect', Lighting)
    SunRaysEffect.Intensity = 0.1
    SunRaysEffect.Spread = 1
    ColorCorrectionEffect.Brightness = 0.03
    ColorCorrectionEffect.Contrast = 0.3
    ColorCorrectionEffect.Saturation = 0.01
    ColorCorrectionEffect.TintColor = Color3.fromRGB(244,244,244)
    Blur.Size = 3

end

function Ancestor:GetTree()

    local Largest, Smallest, LargestTree, SmallestTree = 0, 9e9
    
    for i = 1, #LoadedTrees do

        if LoadedTrees[i] ~= nil then

            local Tree = LoadedTrees[i].Model

            if Tree and Tree:FindFirstChild('WoodSection') and Tree:FindFirstChild('TreeClass') and Tree.TreeClass.Value == Ancestor.SelectedTreeType then

                local Sections = Tree:GetChildren()

                for i = 1, #Sections do 

                    local WoodSection = Sections[i]

                    if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value == 1 and WoodSection.Size.Y >= .6 then

                        OriginWoodSection = WoodSection

                    else

                        continue

                    end

                end
            
                if GUISettings.SelectedTreeTypeSize == 'Largest' and #Tree:GetChildren() >= Largest then 

                    Largest = #Tree:GetChildren()
                    LargestTree = OriginWoodSection
                    LargestIndex = i

                elseif GUISettings.SelectedTreeTypeSize == 'Smallest' and #Tree:GetChildren() <= Smallest then 

                    Smallest = #Tree:GetChildren()
                    SmallestTree = OriginWoodSection
                    SmallestIndex = i

                end

            end

        end
            
    end

    if not LoadedTrees[(GUISettings.SelectedTreeTypeSize == 'Largest' and LargestIndex) or SmallestIndex] then

        SendUserNotice:Fire('Internal error. \n\n This is often caused by the tree not existing.')

    end

    LoadedTrees[(GUISettings.SelectedTreeTypeSize == 'Largest' and LargestIndex) or SmallestIndex] = nil

    return (GUISettings.SelectedTreeTypeSize == 'Largest' and LargestTree) or SmallestTree

end

function Ancestor:GetHitPoint(Axe)

    local AxeModule = require(AxeFolder['AxeClass_'..tostring(Axe.ToolName.Value)]).new()

    if self.SelectedTreeType == 'LoneCave' and Axe.ToolName.Value == 'EndTimesAxe' then

        return AxeModule.SpecialTrees.LoneCave.Damage

    end

    if self.SelectedTreeType == 'Volcano' and Axe.ToolName.Value == 'FireAxe' then

        return AxeModule.SpecialTrees.Volcano.Damage

    end

    return (AxeModule.SpecialTrees and AxeModule.SpecialTrees[self.SelectedTreeType] and AxeModule.SpecialTrees[self.SelectedTreeType].Damage) or AxeModule.Damage

end

function Ancestor:AttemptChop(Tree, Dismember)

    local Axe = self:GetBestAxe()

    if not Axe then

        return

    end

    if not Tree or not Tree.Parent then

        return

    end

    local Hitpoint, CutEvent = self:GetHitPoint(Axe), Tree.Parent:FindFirstChild('CutEvent') or Tree:FindFirstChild('CutEvent')

    local WoodSections = tostring(Tree):match('WoodSection') and Tree.Parent:GetChildren() or Tree:GetChildren()

    local LowestIndex = 9e9

    for i = 1, #WoodSections do 

        local WoodSection = WoodSections[i]

        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value < LowestIndex then

            LowestIndex = WoodSection.ID.Value

            DismemberHeight = WoodSection.Size.Y

        end

    end

    RemoteProxy:FireServer(CutEvent, {

        ['tool'] = Axe,
        ['faceVector'] = Vector3.new(1, 0, 0),
        ['height'] = (Dismember and DismemberHeight) or .3,
        ['sectionId'] = LowestIndex,
        ['hitPoints'] = Hitpoint,
        ['cooldown'] = .1,
        ['cuttingClass'] = 'Axe'

    })

end

function Ancestor:GetBlueprints()

    local ClientItemInfo, Blueprints = ReplicatedStorage.ClientItemInfo:GetChildren(), {}

    for i = 1, #ClientItemInfo do 
        
        local Object = ClientItemInfo[i]
        
        if Object:FindFirstChild('ItemCategory') and not Player.PlayerBlueprints.Blueprints:FindFirstChild(tostring(Object)) then

            rawset(Blueprints, #Blueprints + 1, Object.ItemName.Value)
            
        end
        
    end

    return Blueprints

end

function Ancestor:PurchaseAllBlueprints()

    local Blueprints = self:GetBlueprints()

    for i = 1, #Blueprints do

        local Blueprint = Blueprints[i]

        if not Player.PlayerBlueprints.Blueprints:FindFirstChild(tostring(Blueprint)) then

            self.AutobuySelectedItem = tostring(Blueprint)

            self:AutobuyItem()

        end

    end

end

function Ancestor:SelectBlueprint()

    SendUserNotice:Fire('Select A Blueprint To Fill.')

    Connections.SelectBlueprint = {Function = Mouse.Button1Down:Connect(function()
        
        local Target = Mouse.Target
        
        if not Target then 
            
            return
            
        end
        
        Target = Target.Parent
        
        local Blueprint = (Target:FindFirstChild('BuildDependentWood') and not Target:FindFirstChild('BlueprintWoodClass') and Target)
        
        if Blueprint then 
            
            self:GetConnection('SelectBlueprint', true)
            Ancestor.SelectedBlueprint = Blueprint
            SendUserNotice:Fire('Blueprint Selected.')
            
        end
    
    end)}

end

function Ancestor:SelectPlank()

    SendUserNotice:Fire('Select A Plank To Fill Blueprint.')

    Connections.SelectPlank = {Function = Mouse.Button1Down:Connect(function()
        
        local Target = Mouse.Target
        
        if not Target then 
            
            return
            
        end
        
        Target = Target.Parent
        
        local Plank = (Target:FindFirstChild('WoodSection') and Target:FindFirstChild('TreeClass') and Target.Owner.Value == Player and Target)
        
        if Plank then 
            
            self:GetConnection('SelectPlank', true)
            Ancestor.SelectedPlank = Plank
            SendUserNotice:Fire('Plank Selected.')
            
        end
    
    end)}

end

function Ancestor:ForceWhitelist()

    InteractionPermission.UserCanInteract = GUISettings.ForceWhitelist and function()

        return true

    end or UserCanInteract

end

function Ancestor:PlayerIsCloseToProperty(Position, RequestedPlayer, PlayerProperty)

    RequestedPlayer = RequestedPlayer or Player
    PlayerProperty = PlayerProperty or self:GetPlayersBase(RequestedPlayer)

    if not PlayerProperty then 

        return false

    end
    
    for _, Property in pairs(PlayerProperty:GetChildren()) do

        if Property:IsA("BasePart") and math.abs(Position.p.X - Property.Position.X) <= 25 and math.abs(Position.p.Z - Property.Position.Z) <= 25 and Position.p.Y > Property.Position.Y - 2 then

            return true

        end

    end
    
    return false

end

function Ancestor:FireAll(Type)

    for _, Object in next, PlayerModels:GetChildren() do 

        if Object:FindFirstChild('ItemName') and tostring(Object.ItemName.Value) == Type then 

            RemoteProxy:FireServer(Object:FindFirstChildOfClass'BindableEvent')

        end

    end

end;

function Ancestor:PlankToBlueprint()

    local PlankToBP = Instance.new('Tool', Player.Backpack)

    PlankToBP.Name = 'Plank To Blueprint'
    PlankToBP.RequiresHandle = false

    PlankToBP.Equipped:Connect(function()
    
        self:SelectBlueprint()

    end)

    PlankToBP.Unequipped:Connect(function()
    
        self:GetConnection('SelectBlueprint', true)
        self:GetConnection('SelectPlank', true)

    end)


    PlankToBP.Activated:Connect(function()

        repeat Maid.Timer:Wait() until self.SelectedBlueprint

        self:SelectPlank()

        repeat Maid.Timer:Wait() until self.SelectedPlank

        repeat Maid.Timer:Wait()
            
            ClientIsDragging:FireServer(self.SelectedPlank)
            
        until self:IsNetworkOwnerOfModel(self.SelectedPlank)

        self.SelectedPlank.WoodSection.CFrame = self.SelectedBlueprint.PrimaryPart.CFrame

        local Weld = Instance.new('Weld', self.SelectedBlueprint.PrimaryPart)
        Weld.Part0 = self.SelectedBlueprint.PrimaryPart
        Weld.Part1 = self.SelectedPlank.WoodSection
        Weld.C0, Weld.C1 = self.SelectedBlueprint.PrimaryPart.CFrame, self.SelectedBlueprint.PrimaryPart.CFrame

        Maid.Timer:Wait(.035)
        self.SelectedPlank.WoodSection.Anchored = false
        Weld:Destroy()

        for i = 1, 50 do 
            
            pcall(function()
                
                self.SelectedPlank.WoodSection.CFrame = self.SelectedBlueprint.PrimaryPart.CFrame
                Weld.C0, Weld.C1 = self.SelectedBlueprint.PrimaryPart.CFrame, self.SelectedBlueprint.PrimaryPart.CFrame
                
            end)
            
            Maid.Timer:Wait()
            
        end

        self.SelectedBlueprint, self.SelectedPlank = nil, nil

        self:SelectBlueprint()
    
    end)

end

function Ancestor:SelectSawmill(Type)

    SendUserNotice:Fire(string.format('Select A Sawmill To %s.', Type))

    Connections.SelectSawmill = {Function = Mouse.Button1Down:Connect(function()
        
        local Target = Mouse.Target
        
        if not Target then 
            
            return
            
        end
        
        Target = Target.Parent
        
        local Sawmill = Target:FindFirstChild('Settings') and Target.Settings:FindFirstChild('DimZ') or Target.Parent:FindFirstChild('Settings') and Target.Parent.Settings:FindFirstChild('DimZ')
        
        if Sawmill then 
            
            self:GetConnection('SelectSawmill', true)
            Ancestor.ModWoodSawmill = Sawmill.Parent.Parent
            SendUserNotice:Fire('Sawmill Selected.')
            
        end
    
    end)}

end

function Ancestor:SpawnVehicle()

    SendUserNotice:Fire('Select Vehicle Spot.')

    Connections.SelectVehicleSpot = {Function = Mouse.Button1Down:Connect(function()
        
        local Target = Mouse.Target
        
        if not Target then 
            
            return
            
        end
        
        Target = Target.Parent
        local VehicleSpot = (Target:FindFirstChild('Type') and Target.Type.Value:match('Vehicle Spot') and tostring(Target.Owner.Value):match(tostring(Player)) and Target)
        
        if VehicleSpot then 
            
            self:GetConnection('SelectVehicleSpot', true)
            self.VehicleSpawnerSpot = Vehicle

            SendUserNotice:Fire('Vehicle Spot Selected.')

            Connections.VehicleSpawner = {Function = PlayerModels.ChildAdded:Connect(function(Vehicle)

                local Owner, Type = Vehicle:WaitForChild('Owner', 10), Vehicle:WaitForChild('Type', 10)

                if Owner.Value == Player and Type and Type.Value == 'Vehicle' then

                    local Settings = Vehicle:WaitForChild('Settings', 10)

                    local Color = Settings:WaitForChild('Color')

                    if Settings and Color and tostring(Color.Value) == (tostring(BrickColor.new((GUISettings.AutoStopOnPinkVehicle and 'Hot pink').Number or self.SelectedVehicleColourToSpawn).Number)) then

                        SendUserNotice:Fire('Spawned %s Vehicle', self.SelectedVehicleColourToSpawn)

                        if GUISettings.DeleteSpawnPadAfterVehicleSpawn then
                            
                            DestroyStructure:FireServer(VehicleSpot)

                        end

                        return self:GetConnection('VehicleSpawner', true)

                    end

                    repeat Maid.Timer:Wait()

                    until VehicleSpot:FindFirstChild('ButtonRemote_SpawnButton')

                    Maid.Timer:Wait(1.5)

                    RemoteProxy:FireServer(VehicleSpot.ButtonRemote_SpawnButton)

                end
            
            end)}
    
            RemoteProxy:FireServer(VehicleSpot.ButtonRemote_SpawnButton)

        end

    end)}

end

function Ancestor:SelectTree(Type)

    Type = Type or 'To Mod'

    SendUserNotice:Fire(string.format('Select A Tree %s.', Type))

    Connections.SelectTree = {Function = Mouse.Button1Down:Connect(function()
        
        local Target = Mouse.Target
        
        if not Target then 
            
            return
            
        end
        
        Target = Target.Parent
        local Tree = (Target:FindFirstChild('WoodSection') and tostring(Target.Parent):match((Type == 'To Mod' and 'LogModels') or 'TreeRegion') and ((tostring(Target.Owner.Value):match(tostring(Player))) or tostring(Target.Owner.Value):match('nil')) and Target)
        
        if Tree then 
            
            self:GetConnection('SelectTree', true)
            self.ModWoodTree = (Type == 'To Mod' and self.ModWoodTree) or Tree
            self.TreeToDismember = (Type ~= 'To Mod' and Tree)
            SendUserNotice:Fire('Tree Selected.')
            
        end
    
    end)}

end

function Ancestor:HighlightObject(Object, Colour)

    local BoxHandleAdornment = Instance.new('BoxHandleAdornment', Object)
    BoxHandleAdornment.Name = 'AncestorSelectedObject'
    BoxHandleAdornment.Adornee = Object
    BoxHandleAdornment.AlwaysOnTop = true
    BoxHandleAdornment.ZIndex = 0;
    BoxHandleAdornment.Size = Object.Size
    BoxHandleAdornment.Transparency = 0;
    BoxHandleAdornment.Color = BrickColor.new(Colour)

end

function Ancestor:ModWood(BruteForce)

    if self.ModdingWood then 

        return SendUserNotice:Fire('You\'re Already Using This Feature.')

    end

    local OldPosition = Player.Character.HumanoidRootPart.CFrame

    if not self:GetBestAxe() then 

        return SendUserNotice:Fire('You Need An Axe To Use This Feature')

    end

    if not BruteForce then
        
        self:SelectSawmill('Mod Wood')

        repeat Maid.Timer:Wait() until self.ModWoodSawmill and not PlayerGui.NoticeGUI.Notice.Visible

        self:SelectTree()

        repeat Maid.Timer:Wait() until self.ModWoodTree

    end

    self.ModdingWood = true

    local Object = self.ModWoodTree

    local WoodSections, SmallestWoodSection, Size, MainSection = Object:GetDescendants(), nil, 9e9

    for i = 1, #WoodSections do 

        local WoodSection = WoodSections[i]

        if (self.ModWoodTree.TreeClass.Value == 'Pine' or self.ModWoodTree.TreeClass.Value == 'Fir') then 

            if tostring(WoodSection):match('WoodSection') and WoodSection.Size.X <= Size and WoodSection.Size.X >= .5 then 

                Size = WoodSection.Size.X
                SmallestWoodSection = WoodSection

            end

        elseif not (self.ModWoodTree.TreeClass.Value == 'Pine' or self.ModWoodTree.TreeClass.Value == 'Fir') and tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value >= 3 and WoodSection:FindFirstChild('ParentID') then  

            Size = WoodSection.Size.X
            SmallestWoodSection = WoodSection

        end

    end

    if not SmallestWoodSection then 

        self.ModWoodSawmill, self.ModWoodTree = (Ancestor.AutofarmTrees and self.ModWoodSawmill) or nil, nil
        return SendUserNotice:Fire('This Tree Is Not Moddable.')

    end

    for i = 1, #WoodSections do 

        local WoodSection = WoodSections[i]

        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value == SmallestWoodSection.ParentID.Value and WoodSection.Parent == SmallestWoodSection.Parent then

            SellPointPiece = WoodSection

        end

    end

    for i = 1, #WoodSections do 

        local WoodSection = WoodSections[i]

        if tostring(WoodSection):match('WoodSection') and WoodSection.ID.Value == 1 then

            MainSection = WoodSection

        end

    end

    -- self:HighlightObject(SmallestWoodSection, 'Really red')
    -- self:HighlightObject(SellPointPiece, 'Lime green')

    local OldFly = Ancestor.IsClientFlying

    if not OldFly then

        Ancestor.IsClientFlying = true

        Maid.Threads:Create(function()

            self:Fly()
        
        end)

    end

    Object.PrimaryPart = SellPointPiece

    if (Player.Character.Head.CFrame.p - MainSection.CFrame.p).Magnitude >= 5 then 

        repeat Maid.Timer:Wait()

            self:Teleport(CFrame.new(MainSection.CFrame.p + Vector3.new(0, 5, 0)))

        until (Player.Character.Head.CFrame.p - MainSection.CFrame.p).Magnitude <= 10

    end

    repeat Maid.Timer:Wait()

        ClientIsDragging:FireServer(Object)

    until self:IsNetworkOwnerOfModel(Object)

    self.IsClientFlying = true

    self:Teleport(MainSection.CFrame)

    repeat Maid.Timer:Wait()

        for i = 1, 25 do 

            ClientIsDragging:FireServer(Object)
            Object:PivotTo(CFrame.new(-1425, 489, 1244))
            Object.PrimaryPart.Velocity = Vector3.new()
            Object.PrimaryPart.RotVelocity = Vector3.new()
            Maid.Timer:Wait()
    
        end

        firetouchinterest(LavaPart.Lava, Object.PrimaryPart, 0)
        firetouchinterest(LavaPart.Lava, Object.PrimaryPart, 1)
    
    until Object.PrimaryPart:FindFirstChild('LavaFire')

    Object.PrimaryPart:FindFirstChild('LavaFire'):Destroy()

    for i = 1, 25 do 

        ClientIsDragging:FireServer(Object)
        Object:PivotTo(CFrame.new(-1055, 291, -458))
        Maid.Timer:Wait()

    end

    self:Teleport(CFrame.new(-1055, 291, -458))

    local SellPieceSold

    SellPointPiece.AncestryChanged:Connect(function()

        SellPieceSold = true

    end)

    Maid.Threads:Create(function()

        repeat Maid.Timer:Wait()

            for i = 1, 25 do
                
                Maid.Timer:Wait()
                SellPointPiece.CFrame = CFrame.new(315, 0, 85)
                ClientIsDragging:FireServer(Object)

            end

        until SellPieceSold

    end)

    repeat Maid.Timer:Wait() until SellPieceSold

    self:Teleport(SmallestWoodSection.CFrame)

    for i = 1, #WoodSections do 

        local WoodSection = WoodSections[i]

        if tostring(WoodSection):match('WoodSection') and WoodSection ~= SmallestWoodSection then 

            Object.PrimaryPart = WoodSection

        end

    end

    Maid.Threads:Create(function()

        repeat Maid.Timer:Wait()

            ClientIsDragging:FireServer(Object)

        until self:IsNetworkOwnerOfModel(Object)

        for i = 1, 25 do

            if not self.ModWoodSawmill:IsDescendantOf(PlayerModels) then

                break

            end
                
            Maid.Timer:Wait()
            -- self:Teleport(SmallestWoodSection.CFrame)
            SmallestWoodSection.CFrame = self.ModWoodSawmill.Particles.CFrame + Vector3.new(0, .5, 0)
            ClientIsDragging:FireServer(Object)

        end

    end)

    if not self.ModWoodSawmill:IsDescendantOf(PlayerModels) then

        return SendUserNotice:Fire('Mod Wood Failed \n\n Did You Reload?')

    end

    self:Teleport(CFrame.new(Object.PrimaryPart.CFrame.p + Vector3.new(0, 5, 4)))

    Connections.WoodModded = {Function = LogModels.ChildAdded:Connect(function(Tree)

        local Owner = Tree:WaitForChild('Owner', 10)

        if Owner.Value == Player then

            self:GetConnection('WoodModded', true)

        end

    end)}

    if GUISettings.SellPlankAfterMilling then

        Connections.PlankAdded = {Function = PlayerModels.ChildAdded:Connect(function(Plank)

            local Owner = Plank:FindFirstChild('Owner', 10)

            repeat Maid.Timer:Wait() until Owner and Owner.Value ~= nil

            if Owner.Value == Player and tostring(Plank):match('Plank') then

                self.ModdingWood = false
                self:GetConnection('PlankAdded', true)

                self:MoveObject(Plank, CFrame.new(315, 3, 85) * CFrame.Angles(math.rad(-90), 0, 0), OldPosition, true, 25)

            end

        end)}

    end

    local Threshold = 0 
    
    repeat Maid.Timer:Wait()
        
        self:Teleport(CFrame.new(Object.WoodSection.CFrame.p + Vector3.new(0, 0, 5)))
        self:AttemptChop(Object)

        for i = 1, 40 do
            
            Maid.Timer:Wait()

            SmallestWoodSection.CFrame = self.ModWoodSawmill.Particles.CFrame
            ClientIsDragging:FireServer(Object)

            if (SmallestWoodSection.CFrame.p - self.ModWoodSawmill.Particles.CFrame.p).Magnitude <= 10 then

                Threshold += 1

                if Threshold >= 45 then

                    break

                end

            end
    
        end

    until typeof(self:GetConnection('WoodModded')) ~= 'RBXScriptConnection'

    self.ModWoodSawmill, self.ModWoodTree = (Ancestor.AutofarmTrees and self.ModWoodSawmill) or nil, nil

    Ancestor.IsClientFlying = OldFly

    self:Teleport(OldPosition)
    self.ModdingWood = false
    Maid.Timer:Wait(.5)

end

function Ancestor:HardDragger(State)

    if not State then

        Ancestor:GetConnection('HardDragger', true)
        return

    end

    Connections.HardDragger = {Function = workspace.ChildAdded:Connect(function(Dragger)

        if tostring(Dragger) == 'Dragger' then

            local BodyGyro = Dragger:WaitForChild('BodyGyro')
            local BodyPosition = Dragger:WaitForChild ('BodyPosition')
            repeat Maid.Timer:Wait() until workspace:FindFirstChild('Dragger')

            repeat Maid.Timer:Wait()

                BodyPosition.P = 10000 * 8
                BodyPosition.D = 1000
                BodyPosition.maxForce = Vector3.new(1, 1, 1) * 1000000
                BodyGyro.maxTorque = Vector3.new(1, 1, 1) * 200
                BodyGyro.P = 1200
                BodyGyro.D = 140

            until not workspace:FindFirstChild('Dragger')

            -->Revert
            BodyPosition.P = 10000
            BodyPosition.D = 800
            BodyPosition.maxForce = Vector3.new(17000, 17000, 17000)
            BodyGyro.maxTorque = Vector3.new(200, 200, 200)
            BodyGyro.P = 1200
            BodyGyro.D = 140

        end
        
    end)}

end

function Ancestor:SitInAnyVehicle()

    Player.PlayerScripts.SitPermissions.Disabled = GUISettings.SitInAnyVehicle

end

function Ancestor:SetSawmillSize(Type)

    self:SelectSawmill('Mod Wood')

    repeat Maid.Timer:Wait() until self.ModWoodSawmill and not PlayerGui.NoticeGUI.Notice.Visible

    local Original = ClientItemInfo:FindFirstChild(self.ModWoodSawmill.ItemName.Value).OtherInfo.MaxOutputSize.Value

    local MaxXSize = tonumber(string.format('%.1f', Original.X))
    local MaxZSize = tonumber(string.format('%.1f', Original.Z))

    local XSize = (Type == 'Maximum' and MaxXSize) or tonumber(string.format('%.1f', .6))
    local ZSize = (Type == 'Maximum' and MaxZSize) or tonumber(string.format('%.1f', .4))

    Maid.Threads:Create(function()

        repeat Maid.Timer:Wait()

            RemoteProxy:FireServer(self.ModWoodSawmill:FindFirstChild((Type == 'Maximum' and 'ButtonRemote_XUp') or 'ButtonRemote_XDown'))

        until tonumber(string.format('%.1f', self.ModWoodSawmill.Settings.DimX.Value)) == XSize

    end)

    Maid.Threads:Create(function()

        repeat Maid.Timer:Wait()

            RemoteProxy:FireServer(self.ModWoodSawmill:FindFirstChild((Type == 'Maximum' and 'ButtonRemote_YUp') or 'ButtonRemote_YDown'))

        until tonumber(string.format('%.1f', self.ModWoodSawmill.Settings.DimZ.Value)) == ZSize

    end)

end

function Ancestor:AutoChop()

    Maid.Threads:Create(function()
    
        while Maid.Timer:Wait(.2) do 

            if not GUISettings.AutoChopTrees or not Ancestor_Loaded then

                break;

            end;

            for i = 1, #LoadedTrees do 

                local PrimaryPart = LoadedTrees[i].Model:FindFirstChild('WoodSection')

                if Player.Character and (Player.Character.HumanoidRootPart.CFrame.p - PrimaryPart.CFrame.p).magnitude <= 20 and Ancestor:GetBestAxe() then 
                    
                    Ancestor:AttemptChop(LoadedTrees[i].Model)

                end

            end
            
        end

    end)

end

function Ancestor:ClickDelete()

    if not GUISettings.ClickDelete then

        pcall(function()
        
            Player.Backpack:FindFirstChild('DeleteTool'):Destroy()

        end)

        return

    end

    local DeleteTool = Instance.new('Tool', Player.Backpack)

    DeleteTool.Name = 'DeleteTool'
    DeleteTool.RequiresHandle = false

    DeleteTool.Activated:Connect(function()

        local Target = Mouse.Target

        if not Target then 

            return

        end

        Target = Target.Parent

        if Target:FindFirstChild('Owner') and Target.Owner.Value == Player and not tostring(Target.Parent):match('Properties') then 

            DestroyStructure:FireServer(Target)

        end
    
    end)

end

function Ancestor:ClickToSell()

    if not GUISettings.ClickToSell then

        pcall(function()
        
            Player.Backpack:FindFirstChild('Click To Sell'):Destroy()

        end)

        return

    end

    local ClickToSell = Instance.new('Tool', Player.Backpack)

    ClickToSell.Name = 'Click To Sell'
    ClickToSell.RequiresHandle = false
    ClickToSell.CanBeDropped = false

    ClickToSell.Activated:Connect(function()

        local Tree = Mouse.Target

        if not Tree then 

            return

        end

        Tree = Tree.Parent

        if Tree:FindFirstChild('Owner') and Tree:FindFirstChild('WoodSection') and ((Tree.Owner.Value == nil or Tree.Owner.Value == Player)) then 

            if (Tree:FindFirstChild('WoodSection').CFrame.p - Player.Character.Head.CFrame.p).Magnitude >= 15 then 

                self:Teleport(CFrame.new(Tree:FindFirstChild('WoodSection').CFrame.p + Vector3.new(0, 0, 4)))

            end

            repeat Maid.Timer:Wait()

                ClientIsDragging:FireServer(Tree)

            until self:IsNetworkOwnerOfModel(Tree)

            for i = 1, 25 do 

                if not Tree then 

                    break

                end

                ClientIsDragging:FireServer(Tree)
                Tree:FindFirstChild('WoodSection').CFrame = CFrame.new(315, 3, 85)

            end

        end
    
    end)

end

function Ancestor:BringTree()

    local Tool = self:GetBestAxe()

    if not Player.Character or Player.Character:FindFirstChild('Humanoid') and Player.Character:FindFirstChild('Humanoid').Health <= 0 then 

        return
        
    end

    if self.Autobuying then 

        return SendUserNotice:Fire('You Cannot Use This Feature While Using Autobuy.')

    end

    if self.BringingTree then 

        return SendUserNotice:Fire('You\'re Already Using This Feature!')

    end

    if self.DupingInventory then 

        return SendUserNotice:Fire('You Cannot Use This Feature While Duping Inventory')

    end

    if not Tool then

        return SendUserNotice:Fire(string.format('You Need An %s Axe To Use This Feature!', (self.SelectedTreeType == 'LoneCave' and 'EndTimes') or ''))

    end

    if self.BringTreeSelectedPosition == 'To Property' and not self:GetPlayersBase() then 

        return SendUserNotice:Fire('You Need A Property For This Feature.')

    end

    local OldPos = (self.BringTreeSelectedPosition == 'Current Position' and Player.Character.HumanoidRootPart.CFrame) or (self.BringTreeSelectedPosition == 'Sell Point' and CFrame.new(315, 3, 85)) or (self.BringTreeSelectedPosition == 'Spawn' and CFrame.new(174, 15, 66)) or (self.BringTreeSelectedPosition == 'To Property' and self:GetPlayersBase().OriginSquare.CFrame + Vector3.new(0, 5, 0))

    for i = 1, self.BringTreeAmount do

        if self.CurrentlySavingOrLoading then

            break
            
        end

        self.BringingTree = true
        local Tree = self:GetTree()

        if not Tree then 

            self.BringingTree = false
            self.AutofarmTrees = false
            return SendUserNotice:Fire(string.format('There Are No %s Trees In This Server At The Moment!', self.SelectedTreeType))

        end

        if self.SelectedTreeType == 'LoneCave' then 

            self:GodMode(true, true)

        end

        Player.Character:SetPrimaryPartCFrame(CFrame.new(Tree.CFrame.p))
        
        Connections.BringTree = {Function = LogModels.ChildAdded:Connect(function(Tree)

            local Owner = Tree:WaitForChild('Owner', 10)

            if Owner.Value == Player then

                Ancestor:GetConnection('BringTree', true)

                if Ancestor.AutofarmTrees then

                    self.ModWoodTree = Tree

                    Maid.Timer:Wait(1)
                    self:ModWood(true)

                end

                Tree.PrimaryPart = Tree:WaitForChild('WoodSection', 10)

                for i = 1, (self.SelectedTreeType == 'LoneCave' and 140) or 25 do

                    ClientIsDragging:FireServer(Tree)
                    Tree:SetPrimaryPartCFrame(OldPos)
                    Maid.Timer:Wait()

                end

                repeat Maid.Timer:Wait()

                until self:IsNetworkOwnerOfModel(Tree)

                for i = 1, (self.SelectedTreeType == 'LoneCave' and 140) or 25 do

                    ClientIsDragging:FireServer(Tree)
                    Tree:SetPrimaryPartCFrame(OldPos)
                    Maid.Timer:Wait()

                end

                SelectedTree = nil

            end

        end)}

        for i = 1, 8 do

            TestPing:InvokeServer()

        end

        repeat Maid.Timer:Wait()
            
            self:AttemptChop(Tree)
            Player.Character.PrimaryPart.Anchored = not Player.Character.PrimaryPart.Anchored
            GUISettings.Noclip = true

            if self.SelectedTreeType == 'LoneCave' or self.AutofarmTrees then 
                
                Player.Character:SetPrimaryPartCFrame(CFrame.new(Tree.CFrame.p + Vector3.new(4, 4, 4)))

            end

        until not self:GetBestAxe() or self.CurrentlySavingOrLoading or self.DonatingProperty or typeof(self:GetConnection('BringTree')) ~= 'RBXScriptConnection'

        self.BringingTree = false
        Player.Character.PrimaryPart.Anchored = false
        GUISettings.Noclip = false

    end

    if GUISettings.TeleportBackAfterBringTree then 

        Player.Character:PivotTo(OldPos)

    end

    self.IsClientFlying = OldFly

    if self.AutofarmTrees then

        repeat Maid.Timer:Wait() until typeof(self:GetConnection('ObjectSold')) == 'RBXScriptConnection'
        repeat Maid.Timer:Wait() until typeof(self:GetConnection('ObjectSold')) ~= 'RBXScriptConnection'

        SendUserNotice:Fire('Modded Tree.')

    end

    if self.SelectedTreeType == 'LoneCave' then 

        self:SafeSuicide()

    end

end

function Ancestor:UpdatePrivilege(Player, Type, Value)

    UpdateUserSettings:FireServer('UserPermission', tostring(Player.UserId), Type, Value)

end

function Ancestor:ModeratePlayer(Option)

    if self.ModerationType == 'Axe' and not self:DoesAxeExist() then

        return SendUserNotice:Fire('You Need An Axe To Use This Feature.')

    end

    if self.ModerationType == 'Vehicle' and not self:GetVehicle() then

        return SendUserNotice:Fire('You Need A Vehicle To Use This Feature.')

    end

    if self.ModerationType == 'Vehicle' then 

        self:UpdatePrivilege(self.PlayerToModerate, 'Sit', true)

    end

    if tostring(self.PlayerToModerate) == tostring(Player) then

        return SendUserNotice:Fire('You Cannot Perform This Action On Yourself!')

    end

    if not Players:FindFirstChild(tostring(self.PlayerToModerate)) then

        return SendUserNotice:Fire('Selected Player Has Left The Game!')

    end

    if Player.Character.Humanoid.SeatPart ~= nil and tostring(Player.Character.Humanoid.SeatPart) ~= 'DriveSeat' then 

        return SendUserNotice:Fire('You Need To Be In The Driver\'s Seat.')

    end

    if Players:FindFirstChild(tostring(self.PlayerToModerate)).Character.Humanoid.SeatPart ~= nil and Player.Character.Humanoid.SeatPart ~= nil and tostring(Player.Character.Humanoid.SeatPart) == 'DriveSeat' and Players:FindFirstChild(tostring(self.PlayerToModerate)).Player.Character.Humanoid.SeatPart.Parent ~= Player.Character.Humanoid.SeatPart.Parent then

        return SendUserNotice:Fire((tostring(Player.Character.Humanoid.SeatPart) == 'DriveSeat' and 'Selected Player Is Seated!') or 'You Need To Be In The Driver\'s Seat.')

    end

    if self.ModerationType == 'Vehicle' and Option == 'Hard Kill' then 

        return self:CarKill()

    end

    local Humanoid = Player.Character.Humanoid
    
    if not Player.Character:FindFirstChild('Tool') then

        local Tools = Ancestor:GetAxes()

        for i = 1, #Tools do 

            Tools[i].Parent = Player.Character

        end

    end

    repeat Maid.Timer:Wait() until Player.Character:FindFirstChild('Tool')

    local Axe = Player.Character:FindFirstChild('Tool')
    local NewHumanoid = Player.Character.Humanoid:Clone()
    Player.Character.Humanoid:Destroy()
    NewHumanoid.Parent = Player.Character

    if Option == 'Hard Kill' then

        Player.Character.HumanoidRootPart.CFrame = CFrame.new(-1675, 740, 1295)
        Maid.Timer:Wait(1)

    end

    repeat Maid.Timer:Wait()  
        
        Ancestor.PlayerToModerate.Character.HumanoidRootPart.CFrame = Axe.Handle.CFrame
        
    
    until not Player.Character:FindFirstChild('Tool')

    if Option == 'Fling' then

        Maid.Threads:Create(function()

            for i = 1, 600 do 

                if not Player.Character:FindFirstChild('HumanoidRootPart') then 

                    break

                end

                Player.Character.HumanoidRootPart.Velocity = Vector3.new(600, 600, 600)
                Player.Character.HumanoidRootPart.RotVelocity = Vector3.new(600, 600, 600)

                Maid.Timer:Wait()

            end

        end)

    end

    Maid.Timer:Wait(1)
    Player.Character:Destroy()

    self:UpdatePrivilege('Sit', false)

end

function Ancestor:FlingObject(Object)

    local Fling = Instance.new('BodyPosition', Object.PrimaryPart)

    Fling.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Fling.P = 65000
    Fling.Position = Vector3.new(9e9, 9e9, 9e9)

end

function Ancestor:GetCashiers()

    getgenv().CashierList = {}

    local Stores = workspace.Stores:GetChildren()

    for i = 1, #Stores do

        local Store = Stores[i]

        local Cashiers = Store:GetChildren()

        for i = 1, #Cashiers do

            local Cashier = Cashiers[i]

            if Cashier:FindFirstChild('Head') then

                CashierList[#CashierList + 1] = {

                    Model   = Cashier,
                    Counter = Cashier.Parent:FindFirstChild('Counter')

                }

            end

        end

    end

end

if not CashierList then 

    Ancestor:GetCashiers()

end

function Ancestor:FixCashierRange(State)

    if State == 'Disable' then

        return Ancestor:GetConnection('FixCashierRange', true)

    end

    Connections.FixCashierRange = {Function = RunService.Stepped:Connect(function()

        if Player.Character and Player.Character:FindFirstChild('Head') then

            local Min, NearestCashier = 9e9, nil

            for i = 1, #CashierList do

                local Cashier = CashierList[i].Model

                if (Player.Character.Head.CFrame.p - Cashier.Head.CFrame.p).Magnitude < Min then

                    NearestCashier = Cashier

                    Min = (Player.Character.Head.CFrame.p - Cashier.Head.CFrame.p).Magnitude

                end

            end

            if (Player.Character.Head.CFrame.p - NearestCashier.Head.CFrame.p).Magnitude <= 10 then

                PlayerGui.ChatGUI.PromptChat.PromptText.Text = string.format('Chat with %s', tostring(NearestCashier))

                NPCChattingClient.setPromptVisibility(true)

            else

                NPCChattingClient.setPromptVisibility(false)

            end

        end

    end)}

end


function Ancestor:GetPlayersBase(Target)

    Target = Target or Player
    
    for i = 1, #Properties do

        local Property = Properties[i]

        if tostring(Property.Owner.Value):match(tostring(Target)) then

            return Property

        end

    end

    return false

end

function Ancestor:Fly()

    local MaxSpeed, WeldOne, WeldTwo = 9e9

    repeat Maid.Timer:Wait() until Player.Character and Player.Character:FindFirstChild('Head')

    local Steer, BackSteer = {Forward = 0, Back = 0, Left = 0, Right = 0}, {Forward = 0, Back = 0, Left = 0, Right = 0}

    Player.Character.Humanoid.PlatformStand = (not Player.Character.Humanoid.SeatPart and true) or false
    
    if Player.Character.Humanoid.SeatPart then

        Car = Player.Character.Humanoid.SeatPart
        WeldOne = Instance.new('Weld', Player.Character.Humanoid.SeatPart)
        WeldTwo = Instance.new('Weld', Player.Character.HumanoidRootPart)
        WeldOne.Part0 = Player.Character.HumanoidRootPart
        WeldOne.Part1 = Player.Character.Humanoid.SeatPart
        WeldTwo.Part0 = Player.Character.HumanoidRootPart
        WeldTwo.Part1 = Player.Character.Humanoid.SeatPart

    end

    function Fly()

        GUISettings.WaterFloat = false
        local Gyro = Instance.new('BodyGyro', Player.Character.HumanoidRootPart)
        Gyro.P = 9e4
        Gyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        Gyro.CFrame = Player.Character.HumanoidRootPart.CFrame
        local Velocity = Instance.new('BodyVelocity', Player.Character.HumanoidRootPart)
        Velocity.Velocity = Vector3.new(0, 0, 0)
        Velocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        GUISettings.Noclip = true

        repeat Maid.Timer:Wait()

            if not (Ancestor.RotatingObject and workspace:FindFirstChild('Dragger')) then 

                local FlySpeed, SteerSpeed = GUISettings.FlySpeed, 50

                if Steer.Left + Steer.Right ~= 0 or Steer.Forward + Steer.Back ~= 0 then

                    SteerSpeed = FlySpeed

                    if SteerSpeed > MaxSpeed then

                        SteerSpeed = MaxSpeed

                    end

                elseif not (Steer.Left + Steer.Right ~= 0 or Steer.Forward + Steer.Back ~= 0) and speed ~= 0 then

                    SteerSpeed = SteerSpeed - 50

                    if SteerSpeed < 0 then

                        FlySpeed = 0
                        
                    end

                end

                if (Steer.Left + Steer.Right) ~= 0 or (Steer.Forward + Steer.Back) ~= 0 then

                    Velocity.Velocity = ((Camera.CoordinateFrame.lookVector * (Steer.Forward + Steer.Back)) + ((Camera.CoordinateFrame * CFrame.new(Steer.Left + Steer.Right, (Steer.Forward + Steer.Back) * .2, 0).p) - Camera.CoordinateFrame.p)) * SteerSpeed
                    BackSteer = {Forward = Steer.Forward, Back = Steer.Back, Left = Steer.Left, Right = Steer.Right}

                elseif (Steer.Left + Steer.Right == 0 or Steer.Forward + Steer.Back == 0) and SteerSpeed ~= 0 then
                    
                    Velocity.Velocity =((Camera.CoordinateFrame.lookVector * (BackSteer.Forward + BackSteer.Back)) + ((Camera.CoordinateFrame * CFrame.new(BackSteer.Left + BackSteer.Right, (BackSteer.Forwardorward + BackSteer.Back) * .2, 0).p) - Camera.CoordinateFrame.p)) * SteerSpeed
                
                else
                    
                    Velocity.Velocity = Vector3.new(0, 0, 0)
                
                end

                Gyro.CFrame = Camera.CoordinateFrame * CFrame.Angles(-math.rad((Steer.Forward + Steer.Back) * 50 * SteerSpeed / MaxSpeed), 0, 0)

            end
        
        until not Ancestor.IsClientFlying

        Gyro:Destroy()

        Velocity:Destroy()

        if WeldOne and WeldTwo then

            WeldOne:Destroy()
            WeldTwo:Destroy()
            Ancestor:Teleport(CFrame.new(Car.CFrame.p))

        end

        GUISettings.Noclip = false
    Player.Character.Humanoid.PlatformStand = false

    end

    Mouse.KeyDown:Connect(
        function(Key)
            if Key:lower() == 'w' then
                isWDown = true
                Steer.Forward = 1
            elseif Key:lower() == 'a' then
                isADown = true
                Steer.Left = -1
            elseif Key:lower() == 's' then
                isSDown = true
                Steer.Back = -1
            elseif Key:lower() == 'd' then
                isSDown = true
                Steer.Right = 1
            end
        end
    )
    Mouse.KeyUp:Connect(
        function(Key)
            if Key:lower() == 'w' then
                isWDown = false
                Steer.Forward = 0
            elseif Key:lower() == 'a' then
                isADown = false
                Steer.Left = 0
            elseif Key:lower() == 's' then
                isSDown = false
                Steer.Back = 0
            elseif Key:lower() == 'd' then
                isDDown = false
                Steer.Right = 0
            end
        end
    )
    Fly()
end

function Ancestor:DoesSaveExist(Slot)

    local Data = GetMetaData:InvokeServer(Player)

    for i = 1, #Data do

        if i == Slot and Data[i].SaveMeta[#Data[i].SaveMeta] then

            local Datasize = Data[i].SaveMeta[#Data[i].SaveMeta].NumKeys

            return Datasize

        end

    end

    SendUserNotice:Fire(string.format('No Data Found For Slot %s.', tostring(Slot)))

end

function Ancestor:CanClientLoad()

    if not ClientMayLoad:InvokeServer(Player) then

        SendUserNotice:Fire('Waiting For Load Timeout. Please Wait...')

        repeat 
            
            Maid.Timer:Wait()

        until ClientMayLoad:InvokeServer(Player)

    end

    return true

end

function Ancestor:Set(SlotNumber)

    Player.CurrentSaveSlot.Set:Invoke(SlotNumber, LoadPass)

end

function Ancestor:LoadSlot(Slot)

    if self.CurrentlySavingOrLoading or self.DonatingProperty then 

        return SendUserNotice:Fire((self.CurrentlySavingOrLoading and 'You Are Currently Saving/Loading') or 'Cannot Perform This Action During Property Duplication.')

    end

    if not Ancestor:DoesSaveExist(Slot)then

        return

    end

    self.CurrentlySavingOrLoading = true
    Ancestor:CanClientLoad()

    if Ancestor:GetLoadedSlot() ~= -1 then

        Ancestor:SaveSlot()

    end

    Maid.Threads:Create(function()
        
        Is_Client_Loaded = RequestLoad:InvokeServer(Slot, Player)

    end)

    Connections.ClientLoaded = {Function = Player.CurrentlySavingOrLoading:GetPropertyChangedSignal('Value'):Connect(function()

        if not Player.CurrentlySavingOrLoading.Value then

            Ancestor:GetConnection('ClientLoaded', true)

        end

    end)}

    repeat Maid.Timer:Wait()

        PropertyPurchasingClient:selectionMade()

    until typeof(Ancestor:GetConnection('ClientLoaded')) ~= 'RBXScriptConnection'

    Ancestor:Set(Slot)
    SendUserNotice:Fire(string.format('Loaded Slot %s', tostring(Ancestor:GetLoadedSlot())))
    self.CurrentlySavingOrLoading = false

end

function Ancestor:UnloadSlot()

    if self.CurrentlySavingOrLoading or self.DonatingProperty then 

        return SendUserNotice:Fire((self.CurrentlySavingOrLoading and 'You Are Currently Saving/Loading') or 'Cannot Perform This Action During Property Duplication.')

    end

    self.CurrentlySavingOrLoading = true
    RequestLoad:InvokeServer(math.huge, Player)
    Ancestor:Set(-1)
    self.CurrentlySavingOrLoading = false

end


function Ancestor:SafeSuicide()

    xpcall(function()
            
        Player.Character.Head:Destroy()

    end,

    function()
        
        SendUserNotice:Fire('Player.Character Is Already Dead.')
    
    end)

end


function Ancestor:ApplyLight()

    if Player.Character.Head:FindFirstChild('PointLight') then

        return Player.Character.Head.PointLight:Destroy()

    end

    if not GUISettings.Light then

        return

    end

    local Light = Instance.new('PointLight', Player.Character.Head)
    Light.Range, Light.Brightness = 150, 1.7

end

function Ancestor:AntiAFK(State)

    if State and Executor == 'Krnl' then 

        return SendUserNotice:Fire('Your Shitty Executor Doesn\'t Support This.')

    end

    local AntiAFK = getconnections(Player.Idled)[1]
    if not AntiAFK then return end
    AntiAFK[(not State and 'Enable') or 'Disable'](AntiAFK)

end

function Ancestor:Teleport(CF)

    repeat Maid.Timer:Wait() until Player.Character:FindFirstChild('HumanoidRootPart')

    xpcall(function()

        Player.Character.Humanoid.SeatPart.Parent:PivotTo(CF * CFrame.Angles(math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.X), math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.Y), math.rad(Player.Character.Humanoid.SeatPart.Parent.PrimaryPart.Orientation.Z)))
        
    end,

    function()

        Player.Character:PivotTo(CF)
        
    end)

end

function Ancestor:BTools()

    if Player.Backpack:FindFirstChildOfClass('HopperBin') then

        return

    end

    for i = 1, 4 do

        Instance.new('HopperBin', Player.Backpack).BinType = i

    end

end

function Ancestor:Autofarm()

    Maid.Threads:Create(function()

        if not self.AutofarmTrees then 

            return

        end

        repeat Maid.Timer:Wait() until AutofarmTreesButton

        local Tool = self:GetBestAxe()

        if not Tool then

            AutofarmTreesButton:Toggle()
            return SendUserNotice:Fire(string.format('You Need An %s Axe To Use This Feature!', (self.SelectedTreeType == 'LoneCave' and 'EndTimes') or ''))

        end

        self:SelectSawmill('Mod Wood')

        repeat Maid.Timer:Wait() until self.ModWoodSawmill and not PlayerGui.NoticeGUI.Notice.Visible

        Maid.Threads:Create(function()

            for i = 1, 9e9 do

                if not self.AutofarmTrees then 
        
                    break
                    
                end
        
                self:BringTree()
                Maid.Timer:Wait(1)
        
            end
        
        end)

    end)
    
end


function Ancestor:TomahawkAxeFling(State)

    if State then

        Connections.TomahawkAxeFling = {Function = Mouse.Button1Down:Connect(function()

            Player.Character.Humanoid:UnequipTools()
            
            local Axe = Ancestor:GetAxes()[1]
        
            Ancestor:DropTool(Axe)

            local ActualPosition = Mouse.Hit.p
        
            Connections.ThrownAxe = {Function = PlayerModels.ChildAdded:Connect(function(ThrownAxe)
        
                local Owner, Main = ThrownAxe:WaitForChild('Owner'), ThrownAxe:WaitForChild('Main', 10)

                if Owner.Value == Player and ThrownAxe:FindFirstChild('ToolName') then

                    self:GetConnection('ThrownAxe', true)
        
                    local AxeFling = Instance.new('BodyPosition', Main)
        
                    AxeFling.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    AxeFling.P = 65000 * 3
                    AxeFling.Position = ActualPosition
                    Main.CanCollide = false
                
                    repeat Maid.Timer:Wait()
                        
                        Main.RotVelocity = Vector3.new(1, 1, 1) * 9e9
                        ClientIsDragging:FireServer(ThrownAxe)
                    
                    until (Main.CFrame.p - AxeFling.Position).Magnitude < 15
                    
                    Maid.Timer:Wait(2.5)
        
                    ClientInteracted:FireServer(ThrownAxe, 'Pick up tool')
        
                end
        
            end)}
        
        end)}

    else

        self:GetConnection('TomahawkAxeFling', true)
        self:GetConnection('ThrownAxe', true)

    end

end

function Ancestor:BurnObject(Object)

    if (Player.Character.Head.CFrame.p - Object.PrimaryPart.CFrame.p).Magnitude >= 15 then 

        repeat Maid.Timer:Wait()

            self:Teleport(CFrame.new(Object.PrimaryPart.CFrame.p + Vector3.new(0, 5, 0)))

        until (Player.Character.Head.CFrame.p - Object.PrimaryPart.CFrame.p).Magnitude <= 10

    end

    repeat Maid.Timer:Wait()

        ClientIsDragging:FireServer(Object)

    until self:IsNetworkOwnerOfModel(Object)

    for i = 1, 20 do 

        Object.PrimaryPart.CFrame = CFrame.new(-1667, 229, 948)
        firetouchinterest(Object.PrimaryPart, LavaPart.Lava, 0)
        firetouchinterest(Object.PrimaryPart, LavaPart.Lava, 1)
        Maid.Timer:Wait()

    end

end

function Ancestor:GetCutProgress(Tree)

    local Cut = Tree:FindFirstChild('Cut')

    if not Cut then 

        return 0

    end

    local OriginWoodSection = Cut.Weld.Part1
    
    return math.floor(OriginWoodSection.Size.Z * ((Cut.Mesh.Scale.Z - math.pi / math.floor(OriginWoodSection.Size.Y - (OriginWoodSection.Size.Z * OriginWoodSection.Size.X))) * 10))

end

function Ancestor:DismemberTree(Tree)

    local Axe = self:GetBestAxe()

    if not Axe then 

        return SendUserNotice:Fire('You Need An Axe To Use This Feature.')

    end

    self.TreeToDismember = Tree or nil

    if not self.TreeToDismember then 

        self:SelectTree('To Dismember')

    end

    repeat Maid.Timer:Wait() until self.TreeToDismember

    local Children = {}

    Connections.WoodDismembered = {Function = LogModels.ChildAdded:Connect(function(Tree)

        local Owner = Tree:WaitForChild('Owner', 10)

        local WoodSections, LowestIndex, RootWoodSection = Tree:GetChildren(), 9e9

        for i = 1, #WoodSections do 

            local WoodSection = WoodSections[i]

            if tostring(WoodSection):match('WoodSection') and WoodSection:WaitForChild('ID', 10).Value <= LowestIndex then 

                LowestIndex = WoodSection.ID.Value
                RootWoodSection = WoodSection

            end

        end

        if Owner.Value == Player and RootWoodSection.ChildIDs.Value ~= 0 then

            self:GetConnection('WoodDismembered', true)

            rawset(Children, #Children + 1, Tree)

        end

    end)}

    repeat Maid.Timer:Wait()
        
        self:AttemptChop(self.TreeToDismember, true)

    until typeof(self:GetConnection('WoodDismembered')) ~= 'RBXScriptConnection'

    SendUserNotice:Fire('Dismembered')

    self.TreeToDismember = nil

    for i = 1, #Children do 

        self.TreeToDismember = Children[i]
        self:DismemberTree(Children[i])

        rawset(Children, i, nil)

    end

end

function Ancestor:GodMode(BruteForce, State)

    if not BruteForce and Ancestor.CharacterGodMode == 'FirstTimeExecutionProtection' then 

        return

    end

    if (BruteForce and not State) or (not Ancestor.CharacterGodMode) then

        return self:SafeSuicide()

    end

    local OriginalHumanoidRootPartClone = Player.Character.HumanoidRootPart.RootJoint:Clone()

    local OriginalHumanoidRootPart = Player.Character.HumanoidRootPart.RootJoint

    OriginalHumanoidRootPartClone.Parent = Player.Character.HumanoidRootPart
    OriginalHumanoidRootPart.Parent = nil 

    OriginalHumanoidRootPartClone:Destroy()

    OriginalHumanoidRootPart.Parent = Player.Character

end

function Ancestor:ClearStores()

    local Stores = workspace.Stores:GetChildren()
    local OldPos = Player.Character.HumanoidRootPart.CFrame
    local OldNoclip = GUISettings.Noclip

    for i = 1, #Stores do 
    
        local Store = Stores[i]
    
        if tostring(Store):match('Items') then 
    
        local Items = Store:GetChildren()
        
            for i = 1, #Items do
                
                local Item = Items[i]
                    
                self:FlingObject(Item)

            end
            
        end

    end

end

function Ancestor:Clock()

    local Colour1 = Color3.fromRGB(15, 15, 15)
    local Colour2 = Color3.fromRGB(255, 255, 255)
    local Stats = Instance.new('ScreenGui')
    local FPSFrame = Instance.new('Frame')
    local UICorner = Instance.new('UICorner')
    local f1 = Instance.new('Frame')
    local f2 = Instance.new('Frame')
    local FPS = Instance.new('TextLabel')
    local TimeFrame = Instance.new('Frame')
    local UICorner_2 = Instance.new('UICorner')
    local f1_2 = Instance.new('Frame')
    local f2_2 = Instance.new('Frame')
    local Time = Instance.new('TextLabel')
    local DateFrame = Instance.new('Frame')
    local Date = Instance.new('TextLabel')
    local f2_3 = Instance.new('Frame')
    local f1_3 = Instance.new('Frame')
    local UICorner_3 = Instance.new('UICorner')
    Stats.Name = 'Stats'
    Stats.Parent = game.CoreGui
    Stats.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FPSFrame.Name = 'FPSFrame'
    FPSFrame.Parent = Stats
    FPSFrame.Size = UDim2.new(0, 40, 0, 20)
    FPSFrame.Position = UDim2.new(1, -40, 1, -60)
    FPSFrame.BorderSizePixel = 0
    FPSFrame.BackgroundColor3 = Colour1
    UICorner.Name = 'UICorner'
    UICorner.Parent = FPSFrame
    UICorner.CornerRadius = UDim.new(0, 6)
    f1.Name = 'f1'
    f1.Parent = FPSFrame
    f1.Size = UDim2.new(1, 0, 0, 6)
    f1.Position = UDim2.new(0, 0, 1, -6)
    f1.BorderSizePixel = 0
    f1.BackgroundColor3 = Colour1
    f2.Name = 'f2'
    f2.Parent = FPSFrame
    f2.Size = UDim2.new(0, 6, 1, 0)
    f2.Position = UDim2.new(1, -6, 0, 0)
    f2.BorderSizePixel = 0
    f2.BackgroundColor3 = Colour1
    FPS.Name = 'FPS'
    FPS.Parent = FPSFrame
    FPS.TextWrapped = true
    FPS.ZIndex = 2
    FPS.BorderSizePixel = 0
    FPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FPS.Size = UDim2.new(1, -2, 1, 0)
    FPS.TextSize = 14.000
    FPS.Text = '222'
    FPS.TextColor3 = Colour2
    FPS.Font = Enum.Font.GothamSemibold
    FPS.Position = UDim2.new(0, 2, 0, 0)
    FPS.BackgroundTransparency = 1.000
    TimeFrame.Name = 'TimeFrame'
    TimeFrame.Parent = Stats
    TimeFrame.Size = UDim2.new(0, 73, 0, 20)
    TimeFrame.Position = UDim2.new(1, -73, 1, -40)
    TimeFrame.BorderSizePixel = 0
    TimeFrame.BackgroundColor3 = Colour1
    UICorner_2.Name = 'UICorner'
    UICorner_2.Parent = TimeFrame
    UICorner_2.CornerRadius = UDim.new(0, 6)
    f1_2.Name = 'f1'
    f1_2.Parent = TimeFrame
    f1_2.Size = UDim2.new(1, 0, 0, 6)
    f1_2.Position = UDim2.new(0, 0, 1, -6)
    f1_2.BorderSizePixel = 0
    f1_2.BackgroundColor3 = Colour1
    f2_2.Name = 'f2'
    f2_2.Parent = TimeFrame
    f2_2.Size = UDim2.new(0, 6, 1, 0)
    f2_2.Position = UDim2.new(1, -6, 0, 0)
    f2_2.BorderSizePixel = 0
    f2_2.BackgroundColor3 = Colour1
    Time.Name = 'Time'
    Time.Parent = TimeFrame
    Time.TextWrapped = true
    Time.ZIndex = 2
    Time.BorderSizePixel = 0
    Time.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Time.Size = UDim2.new(1, -2, 1, 0)
    Time.TextSize = 14.000
    Time.Text = os.date '%I:%M:%S'
    Time.TextColor3 = Colour2
    Time.Font = Enum.Font.GothamSemibold
    Time.Position = UDim2.new(0, 2, 0, 0)
    Time.BackgroundTransparency = 1.000
    DateFrame.Name = 'DateFrame'
    DateFrame.Parent = Stats
    DateFrame.Size = UDim2.new(0, 100, 0, 20)
    DateFrame.Position = UDim2.new(1, -100, 1, -20)
    DateFrame.BorderSizePixel = 0
    DateFrame.BackgroundColor3 = Colour1
    Date.Name = 'Date'
    Date.Parent = DateFrame
    Date.TextWrapped = true
    Date.ZIndex = 2
    Date.BorderSizePixel = 0
    Date.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Date.Size = UDim2.new(1, -2, 1, 0)
    Date.TextSize = 14.000
    Date.Text = 'Tues, March 10th'
    Date.TextColor3 = Colour2
    Date.Font = Enum.Font.GothamSemibold
    Date.Position = UDim2.new(0, 2, 0, 0)
    Date.BackgroundTransparency = 1.000
    f2_3.Name = 'f2'
    f2_3.Parent = DateFrame
    f2_3.Size = UDim2.new(0, 6, 1, 0)
    f2_3.Position = UDim2.new(1, -6, 0, 0)
    f2_3.BorderSizePixel = 0
    f2_3.BackgroundColor3 = Colour1
    f1_3.Name = 'f1'
    f1_3.Parent = DateFrame
    f1_3.Size = UDim2.new(1, 0, 0, 6)
    f1_3.Position = UDim2.new(0, 0, 1, -6)
    f1_3.BorderSizePixel = 0
    f1_3.BackgroundColor3 = Colour1
    UICorner_3.Name = 'UICorner'
    UICorner_3.Parent = DateFrame
    UICorner_3.CornerRadius = UDim.new(0, 6)
    local s, f, m, t, l = tick(), {}, math.fmod, tonumber
    local function o(n)
        return n .. (({'st', 'nd', 'rd'})[m((m((n + 90), 100) - 10), 10)] or 'th')
    end
    Connections.Timer = {Function = RunService.Heartbeat:Connect(function()

        Time.Text = os.date('%I:%M:%S')
        Date.Text = os.date('%a, %b ').. o(t(os.date '%d'))
        l = tick()

        for i = #f, 1, -1 do

            f[i + 1] = (f[i] >= l - 1) and f[i] or nil

        end

        f[1] = l
        FPS.Text = math.floor((tick() - s >= 1 and #f) or (#f / (tick() - s)))
        
    end)}

end

Ancestor:Clock()

function Ancestor:CreateUICorner(Parent)

    if not Parent:FindFirstChild('UICorner') then

        local UICorner = Instance.new('UICorner', Parent)
        UICorner.CornerRadius = UDim.new(0, 5)

    end

end

function Ancestor:FixSettings()

    local Settings = PlayerGui.SettingsGUI

    local OldSettingsOpenWindow, OldSettingsPopulateSettings, OldSettingsExitAll = SettingsClient.openWindow, SettingsClient.populateSettings, SettingsClient.exitAll

    SettingsClient.exitAll = function() 

        OldSettingsExitAll()
        PlayerGui.MenuGUI.Open.Visible = true

    end

    local Objects = Settings:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('Frame') then

            self:CreateUICorner(Object)

            Object.BackgroundColor3 = (tostring(Object):match('DropShadow') and Color3.fromRGB()) or Colour1

        end

        if Object:IsA('TextLabel') or Object:IsA('TextButton') then

            Object.TextColor3 = (tostring(Object):match('DropShadow') and Color3.fromRGB()) or Colour2
            Object.BackgroundColor3 = Colour1
            self:CreateUICorner(Object)

        end

        if Object:IsA 'ScrollingFrame' then

            Object.BackgroundColor3 = Colour1

        end

        if tostring(Object):match('Tick') then 

            if Object.Text ~= '' then 

                Object.Text = '✅'

            end

        end

    end

end

function Ancestor:DarkMode(Mode)

    Colour1 = (Mode == 'Light' and  Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(15, 15, 15)
    Colour2 = (Mode == 'Light' and  Color3.fromRGB(0, 0, 0)) or Color3.fromRGB(255, 255, 255)
    Colour3 = (Mode == 'Light' and  Color3.fromRGB(220, 220, 220)) or Color3.fromRGB(15, 15, 15)

    --Open Menu Button
    local MainMenu = PlayerGui.MenuGUI.Open

    self:CreateUICorner(MainMenu)
    MainMenu.BackgroundColor3 = Colour1
    MainMenu.TextLabel.TextColor3 = Colour2

    self:CreateUICorner(MainMenu.DropShadow)

    --Main Menu
    local MainMenu = PlayerGui.MenuGUI.Menu.Main
    local MainMenuQuitButton = MainMenu.Parent.Quit

    MainMenu.BackgroundColor3 = Colour1

    local Objects = MainMenu:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('TextLabel') or Object:IsA('TextButton') then

            self:CreateUICorner(Object)

            Object.TextColor3 = (tostring(Object):match('Drop') and Object.Text == 'Menu' and Colour1) or Colour2
            Object.BackgroundColor3 = Colour1

        end

    end

    self:CreateUICorner(MainMenu)
    self:CreateUICorner(MainMenuQuitButton)
    MainMenuQuitButton.BackgroundColor3 = Colour1
    MainMenuQuitButton.TextLabel.TextColor3 = Colour2

    self:CreateUICorner(MainMenuQuitButton.DropShadow)
    self:CreateUICorner(MainMenuQuitButton)
    self:CreateUICorner(MainMenu.DropShadow)

    --Load Menu
    local LoadMenu = PlayerGui.LoadSaveGUI
    LoadMenu.SlotList.Main.BackgroundColor3 = Colour1

    local Objects = LoadMenu.SlotList.Main:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('TextLabel') then

            Object.TextStrokeColor3 = (tostring(Object):match('IsCurrentSlot') and Colour1) or Object.TextStrokeColor3

            self:CreateUICorner(Object)
            Object.TextColor3 = (tostring(Object):match('DropShadow') and Colour1) or Colour2

        elseif Object:IsA('TextButton') then

            Object.BackgroundColor3 = Colour1
            self:CreateUICorner(Object)

        end

    end

    PlayerGui.PropertyPurchasingGUI.SelectPurchase.Cost.BackgroundColor3 = Colour1

    --Quit
    self:CreateUICorner(LoadMenu.SlotList.Quit)
    LoadMenu.SlotList.Quit.BackgroundColor3 = Colour1
    LoadMenu.SlotList.Quit.TextLabel.TextColor3 = Colour2
    self:CreateUICorner(LoadMenu.SlotList.Quit.DropShadow)
    self:CreateUICorner(LoadMenu.SlotList.Main)
    self:CreateUICorner(LoadMenu.SlotList.Main.DropShadow)


    --Load Current Slot
    local SlotInfo = LoadMenu.SlotInfo.Main
    local Progress = LoadMenu.Progress

    local Objects = Progress:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('Frame') then

            self:CreateUICorner(Object)

            if not tostring(Object):match('DropShadow') then

                Object.BackgroundColor3 = Colour1

            end

        end

    end

    self:CreateUICorner(Progress.Main.Text)
    Progress.Main.Text.BackgroundColor3 = Colour1
    Progress.Main.Text.TextColor3 = Colour2

    self:CreateUICorner(SlotInfo)
    self:CreateUICorner(SlotInfo.DropShadow)

    local Objects = SlotInfo:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]
        
        if Object:IsA('TextButton') or Object:IsA('TextLabel') then

            Object.BackgroundColor3 = Colour1
            Object.TextColor3 = Colour2
            Object.TextScaled = (tostring(Object):match('SlotName') and true) or false
            self:CreateUICorner(Object)

        end

    end

    SlotInfo.BackgroundColor3 = Colour1

    --Load Quit
    self:CreateUICorner(SlotInfo.Parent.Quit)
    SlotInfo.Parent.Quit.BackgroundColor3 = Colour1
    SlotInfo.Parent.Quit.TextLabel.TextColor3 = Colour2
    self:CreateUICorner(SlotInfo.Parent.Quit.DropShadow)
    self:CreateUICorner(SlotInfo.Parent.Quit)
    self:CreateUICorner(SlotInfo.Parent.Quit.DropShadow)

    --Select Plot
    local SelectPlot = PlayerGui.PropertyPurchasingGUI

    local Objects = SelectPlot:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object.ClassName == 'Frame' then

            self:CreateUICorner(Object)

            Object.BackgroundColor3 = (tostring(Object):match('DropShadow') and Color3.fromRGB(0, 0, 0)) or Colour1

        end

        if Object:IsA('TextLabel') or Object:IsA ('TextButton') then

            Object.TextColor3 = Colour2
            Object.BackgroundColor3 = Colour1
            self:CreateUICorner(Object)

        end

    end

    --Notice
    local NoticeUI = PlayerGui.NoticeGUI.Notice.Main

    self:CreateUICorner(NoticeUI)
    NoticeUI.BackgroundColor3 = Colour1

    local Objects = NoticeUI:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('TextButton') or Object:IsA('TextLabel') then

            Object.TextColor3 = Colour2
            Object.BackgroundColor3 = Colour1
            self:CreateUICorner(Object)

        end

        if Object:IsA('Frame') then

            self:CreateUICorner(Object)

        end


    end

    --Money Gui

    local PurchasingGUI = PlayerGui.BuyMoneyGUI.BuyMoney

    local Objects = PurchasingGUI:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('Frame') then

            Object.BackgroundColor3 = (tostring(Object):match('DropShadow') and Color3.fromRGB(0, 0, 0)) or Colour3

        end

        if Object:IsA('TextLabel') and not Object.Text:match('R') then

            Object.TextColor3 = (tostring(Object):match('DropShadow') and Colour1) or Colour2

            Object.BackgroundColor3 = (tostring(Object):match('DropShadow') and Colour1) or Colour2

        end

        if Object:IsA 'TextButton' then

            Object.BackgroundColor3 = Colour1

        end

        self:CreateUICorner(Object)

    end

    --Send Money

    local SendMoney = PlayerGui.DonateGUI

    local Objects = SendMoney:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('Frame') then

            self:CreateUICorner(Object)
            
            Object.BackgroundColor3 = (tostring(Object):match('DropShadow') and Color3.fromRGB(0, 0, 0)) or Colour3

        end

        if Object:IsA('TextLabel')and not tostring(Object):match('InfoT') or Object:IsA('TextButton') then

            Object.TextColor3 = (tostring(Object):match('DropShadow') and Colour1) or Colour2

            Object.BackgroundColor3 = Colour1
            self:CreateUICorner(Object)

        end

        if Object:IsA('ScrollingFrame') then

            Object.BackgroundColor3 = Colour1

        end

    end

    PlayerGui.DonateGUI.Donate.Main.AmountLabel.BackgroundColor3 = Color3.fromRGB(0, 155, 0)
    self:CreateUICorner(PlayerGui.DonateGUI.Donate.Main.AmountLabel)
    PlayerGui.DonateGUI.Donate.Main.AmountLabel.TextColor3 = Colour2

    --Settings

    local Settings = PlayerGui.SettingsGUI

    local OldSettingsOpenWindow, OldSettingsPopulateSettings, OldSettingsExitAll = SettingsClient.openWindow, SettingsClient.populateSettings, SettingsClient.exitAll

    self:FixSettings()

    SettingsClient.openWindow = function()

        Maid.Threads:Create(function()

            OldSettingsOpenWindow()
        
        end)

        repeat Maid.Timer:Wait()

        until Settings.Settings.Visible

        self:FixSettings()

    end

    SettingsClient.populateSettings = function()

        OldSettingsPopulateSettings()
        
        repeat Maid.Timer:Wait()

        until #Settings.Settings.Main.SettingsList.List:GetChildren() >= 7

        self:FixSettings()

    end

    --Changelog

    local Changelog = PlayerGui.ChangelogGUI

    local Objects = Changelog:GetDescendants()

    for i = 1, #Objects do 

        local Object = Objects[i]

        if Object:IsA('Frame') then

            self:CreateUICorner(Object)
            Object.BackgroundColor3 = (tostring(Object):match('DropShadow') and Color3.fromRGB(0, 0, 0)) or Colour3

        end

        if Object:IsA('TextLabel') or Object:IsA('TextButton') then
        
            Object.TextColor3 = (tostring(Object):match('DropShadow') and Colour1) or Colour2

            Object.BackgroundColor3 = Colour1
            self:CreateUICorner(Object)

        end

    end
    --Credits
    local creditsUI = PlayerGui.CreditsGUI

    for _, v in next, creditsUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end

    local scr = getsenv(PlayerGui.CreditsGUI.CreditsClient)
    local old = scr.openWindow
    local old2 = scr.displayPage
    scr.openWindow = function()
        old()
        local creditsUI = PlayerGui.CreditsGUI
        for _, v in next, creditsUI:GetDescendants() do
            if v:IsA 'Frame' then
                self:CreateUICorner(v)
                if v.Name ~= 'DropShadow' then
                    v.BackgroundColor3 = Colour1
                end
            end
            if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
                if v.Name ~= 'DropShadow' then
                    v.TextColor3 = Colour2
                else
                    v.TextColor3 = Colour1
                end
                v.BackgroundColor3 = Colour1
                self:CreateUICorner(v)
            end
        end
    end
    scr.displayPage = function()
        old2()
        local creditsUI = PlayerGui.CreditsGUI
        for _, v in next, creditsUI:GetDescendants() do
            if v:IsA 'Frame' then
                self:CreateUICorner(v)
                if v.Name ~= 'DropShadow' then
                    v.BackgroundColor3 = Colour1
                end
            end
            if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
                if v.Name ~= 'DropShadow' then
                    v.TextColor3 = Colour2
                else
                    v.TextColor3 = Colour1
                end
                v.BackgroundColor3 = Colour1
                self:CreateUICorner(v)
            end
        end
    end

    --OnBoarding
    local onBoardingGUI = PlayerGui.OnboardingGUI

    for _, v in next, onBoardingGUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    --Chat GUI
    local chat = PlayerGui.ChatGUI
    for _, v in next, chat:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    --ItemDraggerGUI
    local itemDraggingGUI = PlayerGui.ItemDraggingGUI
    for _, v in next, itemDraggingGUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            v.TextColor3 = Colour2
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    --ItemInfo
    local itemInfoGUI = PlayerGui.ItemInfoGUI
    for _, v in next, itemInfoGUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA('ImageLabel') then
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
                v.TextStrokeColor3 = Colour1
            else
                v.TextColor3 = Colour1
                v.TextStrokeColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    --InteractionGUI
    local interactionGUI = PlayerGui.InteractionGUI
    for _, v in next, interactionGUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour2
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    PlayerGui.InteractionGUI.OwnerShow.BackgroundColor3 = Colour1
    --StructureGui
    local structureDraggingGUI = PlayerGui.StructureDraggingGUI
    for _, v in next, structureDraggingGUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    --WireDraggingGUI
    local wireDraggingGUI = PlayerGui.WireDraggingGUI
    for _, v in next, wireDraggingGUI:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    --OverWriteConfirm
    local overWriteConfirm = LoadMenu.OverwriteConfirm
    for _, v in next, overWriteConfirm:GetDescendants() do
        if v:IsA 'Frame' then
            self:CreateUICorner(v)
            if v.Name ~= 'DropShadow' then
                v.BackgroundColor3 = Colour1
            end
        end
        if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
            if v.Name ~= 'DropShadow' then
                v.TextColor3 = Colour2
            else
                v.TextColor3 = Colour1
            end
            v.BackgroundColor3 = Colour1
            self:CreateUICorner(v)
        end
    end
    PlayerGui.ItemDraggingGUI.CanDrag.PlatformButton.KeyLabel.TextSize = 14
    PlayerGui.ItemDraggingGUI.CanRotate.PlatformButton.KeyLabel.TextSize = 14
    PlayerGui.ItemDraggingGUI.CanRotate.PlatformButton.KeyLabel.TextScaled = false
    for _, v in next, PlayerGui:GetDescendants() do
        if v.Name == 'KeyLabel' then
            v.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
    end
    --Blueprints
    local scr = getsenv(PlayerGui.Blueprints.LocalBlueprints)
    local old = scr.populateCategoryList
    scr.populateCategoryList = function()
        old()
        local blueprints = PlayerGui.Blueprints
        for _, v in next, blueprints:GetDescendants() do
            if v:IsA('ImageLabel') then
                v.BackgroundColor3 = Colour1
            end
            if v:IsA 'Frame' then
                self:CreateUICorner(v)
                if v.Name ~= 'DropShadow' then
                    v.BackgroundColor3 = Colour1
                elseif mode == 'Dark' then
                    v.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                elseif mode == 'Light' then
                    v.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                end
            end
            if v:IsA 'TextLabel' and v.Name ~= 'InfoT' or v:IsA 'TextButton' then
                if v.Name == 'DropShadow' then
                    v:remove()
                end
                if v.Text == 'Blueprints' and v.Name ~= 'DropShadow' then
                    v.TextColor3 = Colour2
                else
                    v.TextColor3 = Colour2
                end
                v.BackgroundColor3 = Colour1
                self:CreateUICorner(v)
            end
            if v:IsA 'ScrollingFrame' then
                v.BackgroundColor3 = Colour1
            end
        end
    end
end
Ancestor:DarkMode 'Dark'

function Ancestor:ClientMayLoadGUI()

    local Colour1 = Color3.fromRGB(15, 15, 15)
    local Colour2 = Color3.fromRGB(255, 255, 255)

    local GUI = Instance.new('ScreenGui')
    local GUIFrame = Instance.new('Frame')
    local Text = Instance.new('TextLabel')
    local UICorner = Instance.new('UICorner')
    GUI.Name = 'GUI'
    GUI.Parent = game.CoreGui
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUIFrame.Name = 'FPSFrame'
    GUIFrame.Parent = GUI
    GUIFrame.Size = UDim2.new(0.08, 0, 0.04, 0)
    GUIFrame.AnchorPoint = Vector2.new(.5, .5)
    GUIFrame.Position = UDim2.new(.03, 0, .99, 0)
    GUIFrame.BorderSizePixel = 0
    GUIFrame.BackgroundColor3 = Colour1
    UICorner.Name = 'UICorner'
    UICorner.Parent = GUIFrame
    UICorner.CornerRadius = UDim.new(0, 6)
    Text.Name = 'Text'
    Text.Parent = GUIFrame
    Text.TextWrapped = true
    Text.ZIndex = 2
    Text.BorderSizePixel = 0
    Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text.Size = UDim2.new(1, -2, 1, 0)
    Text.TextSize = 14
    Text.Text = ''
    Text.TextColor3 = Colour2
    Text.AnchorPoint = Vector2.new(.5, .5)
    Text.Font = Enum.Font.GothamSemibold
    Text.Position = UDim2.new(.5, 0, .5, 0)
    Text.BackgroundTransparency = 1

    Connections.ClientMayLoadGUI = {Function = RunService.Heartbeat:Connect(function()

        local Success = ClientMayLoad:InvokeServer(Player)

        Text.Text = (Success and 'You Can Load') or 'You Cannot Load'

    end)}

end

Ancestor:ClientMayLoadGUI()

function Ancestor:OpenObject(Object, Delay)

    task.delay(Delay, function()
    
        ClientInteracted:FireServer(Object, 'Open box')

    end)

end

function Ancestor:GetOrphanedProperty()

    local LowestIndex = 9
    
    for Index, Property in pairs(workspace.Properties:GetChildren()) do 
        
        if Property.Owner.Value == nil and Index < LowestIndex then 
            
            LowestIndex -= 1

            return Property
            
        end
        
    end

end

function Ancestor:GetCurrentDataSize(Slot)

    return self:GetPlayersSlotInfo(Player, Slot)[Slot]

end

function Ancestor:DuplicateProperty()

    if Ancestor.PlayerToDuplicatePropertyTo == Player then 

        -- return SendUserNotice:Fire('You Cannot Duplicate Your Property To Yourself.')

    end

    if self.CurrentlySavingOrLoading then

        return SendUserNotice:Fire('You Cannot Use This Feature Whilst Saving/Loading.')

    end

    if math.floor(PerformanceStats.Ping:GetValue()) >= 500 then 

        return SendUserNotice:Fire('Server Ping Is Too High To Duplicate Reliably.')

    end

    if not self:CheckClientPrivilege(Ancestor.PlayerToDuplicatePropertyTo.UserId, 'Save') then

        return SendUserNotice:Fire('Please Ensure The Other Player Has Whitelisted You.')

    end

    if not self:GetOrphanedHillProperty() then

        return SendUserNotice:Fire('Please Make Sure At Least One Property On The Hill Is Free.')

    end

    self.DonatingProperty = true

    self:UpdatePrivilege(self.PlayerToDuplicatePropertyTo, 'All', true)

    getgenv().Start = DateTime.now().UnixTimestamp

    Maid.Threads:Create(function()

        RequestLoad:InvokeServer(self.PropertyToDuplicate, Player)

    end)

    local OrphanedProperty = self:GetOrphanedHillProperty()

    Maid.Threads:Create(function()

        self:FreeLand(true, true)

    end)

    repeat Maid.Timer:Wait() until Player.PlayerGui.PropertyPurchasingGUI.SelectPurchase.Visible

    getgenv().End = DateTime.now().UnixTimestamp - Start

    workspace.Effects:WaitForChild('StructureModel', 10)
    OrphanedProperty.OriginSquare.Color = Color3.fromRGB(225, 0, 0)
    SendUserNotice:Fire('Do NOT Load On Property With The Red Square.')

end

function Ancestor:GetFlySpeed()

    local Ancestor = CoreGui:FindFirstChild('Ancestor')

    if not Ancestor then 

        return 

    end

    local Frame = Ancestor.MainFrame.Sections['Client Options'].Sections.Frame:GetChildren()

    for i = 1, #Frame do

        local FlySpeed = Frame[i]

        if FlySpeed:FindFirstChild('Title') and FlySpeed.Title.Text:match('Fly Speed') then

            return tonumber(FlySpeed.Input.Text)

        end

    end

end

-->Antikick
loadstring([[

local Args = {...}

local GUISettings, Antikick, Ancestor = Args[1], nil, Args[2]

Antikick = hookmetamethod(game, '__namecall', function(...)

    local NewArgs = {...}

    if Ancestor_Loaded then

        local Method = getnamecallmethod()
        
        if Method == 'Kick' and ... == game:GetService('Players').LocalPlayer then

            return

        end

        if Method:lower():match('httpget') then
        
            if rawget(NewArgs, 2) and rawget(NewArgs, 2):lower():match('butterisgood') then
                
                rawset(NewArgs, 2, 'https://raw.githubusercontent.com/KhayneGleave/Ancestor/main/Ancestor.lua')
                
            end
            
        end

        if Method == 'FireServer' and tostring(...) == 'DamageHumanoid' and GUISettings.WaterGodMode then 

            return

        end

        if Method == 'FireServer' and tostring(...) == 'Ban' then 

            return

        end

        if Method == 'FireServer' and tostring(...) == 'RunSounds' and GUISettings.ActivateVehicleModifications then 

            rawset(NewArgs, 3, GUISettings.CarPitch)

        end

        if Method == 'FireServer' and tostring(...) == 'UpdateUserSettings' then

            task.spawn(function()

                repeat task.Wait()

                until #game.Players.LocalPlayer.PlayerGui.SettingsGUI.Settings.Main.SettingsList.List:GetChildren() >= 7

                Ancestor:FixSettings()

            end)

        end

        setnamecallmethod(Method)

    end

    return Antikick(unpack(NewArgs))

end)

]])(GUISettings, Ancestor)

local Settings = PlayerGui.SettingsGUI.Settings.Main.GlobalSettings:GetChildren()

for i = 1, #Settings do 

    local Setting = Settings[i]

    if tostring(Setting):match('SettingItem') then 

        Connections['GlobalSettings'..tostring(i)] = {Function = Setting.Button.Tick:GetPropertyChangedSignal('Text'):Connect(function()

            Ancestor:FixSettings()
        
        end)}

    end

end

local PlayerList = PlayerGui.SettingsGUI.Settings.Main.PlayerList.List

for _, Button in next, PlayerList:GetChildren() do

    if Button:IsA('TextButton') then 

        Connections['GlobalSettings'..tostring(#PlayerList:GetChildren() - 3)] = {Function = Button.Activated:Connect(function()

            repeat Maid.Timer:Wait()

            until PlayerGui.SettingsGUI.Settings.Settings.Visible

            Ancestor:FixSettings()
        
        end)}

    end

end

PlayerList.ChildAdded:Connect(function(Button)

    Connections['GlobalSettings'..tostring(#PlayerList:GetChildren() - 3)] = {Function = Button.Activated:Connect(function()

        Maid.Timer:Wait(1)
        Ancestor:FixSettings()
    
    end)}

end)

Maid.Threads:Create(function()

    while Maid.Timer:Wait(5) do 

        if not Ancestor_Loaded then 

            break 

        end

        if GUISettings.StopPlayersLoading then 

            local Properties = workspace.Properties:GetChildren()

            for i = 1, #Properties do 

                local Property = Properties[i]

                if Property.Owner.Value == nil then
        
                    ClientPurchasedProperty:FireServer(Property, Property.OriginSquare.CFrame)
                    
                    RequestLoad:InvokeServer(math.huge, Player)

                    Maid.Timer:Wait(.2)

                end

            end

        end

    end

end)

--\\ANCESTOR API

Connections.HumanoidProperties = {Function = UIS.InputBegan:Connect(function(Key, Processed)

    if not Processed and Key.KeyCode == Enum.KeyCode[GUISettings.FlyKey] then

        Ancestor.IsClientFlying = not Ancestor.IsClientFlying

        if Ancestor.IsClientFlying then

            Ancestor:Fly()

        end

        elseif not Processed and Key.KeyCode == Enum.KeyCode[GUISettings.NoclipKey] then

            GUISettings.Noclip = not GUISettings.Noclip -- ?????????????????????????????????????????????????????

        end

    end

)}


-- ═══════════════════════════════════════════════════════════════════
-- JOFFERHUB UI  (shell only — all game logic is Ancestor's)
-- ═══════════════════════════════════════════════════════════════════

local TweenService = game:GetService("TweenService")

-- ─────────────────────────────────────────────────────────────────
-- THEME
-- ─────────────────────────────────────────────────────────────────
local T = {
    WindowBG     = Color3.fromRGB(16,  20,  30),
    SidebarBG    = Color3.fromRGB(11,  14,  22),
    ContentBG    = Color3.fromRGB(20,  26,  36),
    ElementBG    = Color3.fromRGB(26,  33,  48),
    ElementHover = Color3.fromRGB(34,  44,  62),
    Accent       = Color3.fromRGB(0,   200, 175),
    AccentDim    = Color3.fromRGB(0,   130, 115),
    AccentText   = Color3.fromRGB(80,  230, 210),
    TextPri      = Color3.fromRGB(228, 234, 245),
    TextSec      = Color3.fromRGB(138, 155, 178),
    ToggleOn     = Color3.fromRGB(0,   200, 175),
    ToggleOff    = Color3.fromRGB(50,  62,  85),
    Thumb        = Color3.fromRGB(235, 240, 255),
    SliderTrack  = Color3.fromRGB(38,  48,  68),
    Separator    = Color3.fromRGB(30,  40,  58),
    Corner       = UDim.new(0, 7),
    SmallCorner  = UDim.new(0, 5),
    SidebarW     = 122,
    RowH         = 30,
    WinW         = 420,
    WinH         = 360,
}

-- ─────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────
local function New(cls, props, ch)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do if k ~= "Parent" then i[k] = v end end
    for _, c in ipairs(ch or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end
local function UICornerR(p, r)  return New("UICorner",  {CornerRadius=r or T.Corner, Parent=p}) end
local function UIStrokeR(p,c,w) return New("UIStroke",  {Color=c, Thickness=w or 1, Parent=p}) end
local function UIPad(p,t,b,l,r)
    return New("UIPadding", {
        PaddingTop=UDim.new(0,t or 6), PaddingBottom=UDim.new(0,b or 6),
        PaddingLeft=UDim.new(0,l or 10), PaddingRight=UDim.new(0,r or 10), Parent=p,
    })
end
local function UIList(p, dir, gap)
    return New("UIListLayout", {
        FillDirection=dir or Enum.FillDirection.Vertical, Padding=UDim.new(0,gap or 4),
        SortOrder=Enum.SortOrder.LayoutOrder,
        HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=p,
    })
end

local TI  = TweenInfo.new(0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIF = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIS = TweenInfo.new(0.30, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local function Tw (o,p) TweenService:Create(o,TI ,p):Play() end
local function TwF(o,p) TweenService:Create(o,TIF,p):Play() end
local function TwS(o,p) TweenService:Create(o,TIS,p):Play() end

-- ─────────────────────────────────────────────────────────────────
-- DRAG HELPER
-- ─────────────────────────────────────────────────────────────────
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or  input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- DESTROY OLD INSTANCE
-- ─────────────────────────────────────────────────────────────────
pcall(function()
    for _, parent in ipairs({
        (typeof(gethui) == "function" and gethui()) or false,
        CoreGui, PlayerGui,
    }) do
        if parent then
            local old = parent:FindFirstChild("AncestorHub")
            if old then old:Destroy() end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- SCREEN GUI
-- ─────────────────────────────────────────────────────────────────
local guiParent
pcall(function()
    if gethui then guiParent = gethui()
    else guiParent = CoreGui end
end)
if not guiParent then guiParent = PlayerGui end

local ScreenGui = New("ScreenGui", {
    Name="AncestorHub", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset=true, DisplayOrder=999, Parent=guiParent,
})

-- ─────────────────────────────────────────────────────────────────
-- FLOATING ICON  (shown when minimised)
-- ─────────────────────────────────────────────────────────────────
local Icon = New("Frame", {
    Name="FloatIcon", Size=UDim2.new(0,56,0,56),
    Position=UDim2.new(0,18,0.5,-28),
    BackgroundColor3=T.SidebarBG, BorderSizePixel=0,
    Visible=false, ZIndex=20, Parent=ScreenGui,
})
UICornerR(Icon, UDim.new(0,15)); UIStrokeR(Icon, T.Accent, 2)
local IconBtn = New("TextButton", {
    Text="AC", Size=UDim2.new(1,0,0.72,0), BackgroundTransparency=1,
    Font=Enum.Font.GothamBold, TextSize=17, TextColor3=T.Accent,
    ZIndex=21, Parent=Icon,
})
New("TextLabel", {
    Text="Hub", Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-15),
    BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=9,
    TextColor3=T.TextSec, ZIndex=21, Parent=Icon,
})
MakeDraggable(Icon, Icon)

-- ─────────────────────────────────────────────────────────────────
-- MAIN WINDOW
-- ─────────────────────────────────────────────────────────────────
local Main = New("Frame", {
    Name="Main",
    Size=UDim2.new(0,T.WinW,0,T.WinH),
    Position=UDim2.new(0.5,-T.WinW/2,0.05,20),
    BackgroundColor3=T.WindowBG, BorderSizePixel=0,
    ClipsDescendants=true, ZIndex=5, Parent=ScreenGui,
})
UICornerR(Main); UIStrokeR(Main, Color3.fromRGB(38,52,72), 1)

-- Title bar
local TBar = New("Frame", {
    Size=UDim2.new(1,0,0,30),
    BackgroundColor3=T.SidebarBG, BorderSizePixel=0, ZIndex=6, Parent=Main,
})
New("Frame", {
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=T.Accent, BackgroundTransparency=0.55,
    BorderSizePixel=0, ZIndex=7, Parent=TBar,
})
local dot = New("Frame", {
    Size=UDim2.new(0,7,0,7), Position=UDim2.new(0,12,0.5,-3),
    BackgroundColor3=T.Accent, BorderSizePixel=0, ZIndex=7, Parent=TBar,
})
UICornerR(dot, UDim.new(1,0))
New("TextLabel", {
    Text="Ancestor Hub", Size=UDim2.new(0,150,1,0),
    Position=UDim2.new(0,26,0,0), BackgroundTransparency=1,
    Font=Enum.Font.GothamBold, TextSize=14, TextColor3=T.TextPri,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7, Parent=TBar,
})
New("TextLabel", {
    Text="LT2 Exploit  •  Ancestor Core",
    Size=UDim2.new(1,-240,1,0), Position=UDim2.new(0,182,0,0),
    BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=10,
    TextColor3=T.Accent, TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=7, Parent=TBar,
})
MakeDraggable(TBar, Main)

local CloseBtn = New("TextButton", {
    Text="✕", Size=UDim2.new(0,28,0,28),
    Position=UDim2.new(1,-34,0.5,-14),
    BackgroundColor3=Color3.fromRGB(185,55,55), BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextPri,
    BorderSizePixel=0, ZIndex=8, Parent=TBar,
})
UICornerR(CloseBtn, UDim.new(0,5))

local MinBtn = New("TextButton", {
    Text="─", Size=UDim2.new(0,28,0,28),
    Position=UDim2.new(1,-66,0.5,-14),
    BackgroundColor3=T.ElementBG, BackgroundTransparency=0.35,
    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TextSec,
    BorderSizePixel=0, ZIndex=8, Parent=TBar,
})
UICornerR(MinBtn, UDim.new(0,5))

-- Body layout
local Body = New("Frame", {
    Size=UDim2.new(1,0,1,-30), Position=UDim2.new(0,0,0,30),
    BackgroundTransparency=1, BorderSizePixel=0, Parent=Main,
})
local Sidebar = New("Frame", {
    Size=UDim2.new(0,T.SidebarW,1,0),
    BackgroundColor3=T.SidebarBG, BorderSizePixel=0, Parent=Body,
})
New("Frame", {
    Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
    BackgroundColor3=T.Separator, BorderSizePixel=0, Parent=Sidebar,
})
local TabListFrame = New("ScrollingFrame", {
    Size=UDim2.new(1,0,1,-6), Position=UDim2.new(0,0,0,6),
    BackgroundTransparency=1, ScrollBarThickness=2,
    ScrollBarImageColor3=T.Accent,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Sidebar,
})
UIPad(TabListFrame,3,3,4,4); UIList(TabListFrame,nil,2)

local Content = New("Frame", {
    Size=UDim2.new(1,-T.SidebarW,1,0),
    Position=UDim2.new(0,T.SidebarW,0,0),
    BackgroundColor3=T.ContentBG, BorderSizePixel=0, Parent=Body,
})
local PageContainer = New("Frame", {
    Size=UDim2.new(1,0,1,0),
    BackgroundTransparency=1, Parent=Content,
})

-- ─────────────────────────────────────────────────────────────────
-- MINIMISE / RESTORE
-- ─────────────────────────────────────────────────────────────────
local minimized = false
local function ShowMain()
    minimized=false; Icon.Visible=false; Main.Visible=true
    Main.Size=UDim2.new(0,0,0,0)
    TwS(Main, {Size=UDim2.new(0,T.WinW,0,T.WinH)})
end
local function ShowIcon()
    minimized=true
    local abs = MinBtn.AbsolutePosition
    Icon.Position = UDim2.new(0,abs.X,0,abs.Y)
    TwF(Main, {Size=UDim2.new(0,0,0,0)})
    task.delay(0.22, function()
        Main.Visible=false; Icon.Visible=true
        Icon.Size=UDim2.new(0,0,0,0)
        Icon.Position=UDim2.new(0,18,0.5,-28)
        TwS(Icon, {Size=UDim2.new(0,56,0,56)})
    end)
end
MinBtn.MouseButton1Click:Connect(ShowIcon)
MinBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch then ShowIcon() end
end)
IconBtn.MouseButton1Click:Connect(function() if minimized then ShowMain() end end)
IconBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch and minimized then ShowMain() end
end)
CloseBtn.MouseButton1Click:Connect(function()
    Ancestor_Loaded = false
    pcall(function() ScreenGui:Destroy() end)
end)
CloseBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch then
        Ancestor_Loaded = false
        pcall(function() ScreenGui:Destroy() end)
    end
end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode==Enum.KeyCode.RightControl then
        if minimized then ShowMain() else ShowIcon() end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- TAB + COMPONENT FACTORY
-- ─────────────────────────────────────────────────────────────────
local Tabs      = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    local btn = New("TextButton", {
        Name=name, Size=UDim2.new(1,0,0,22),
        BackgroundColor3=T.ElementBG, BackgroundTransparency=1,
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=T.TextSec,
        Text=(icon or "  ").."  "..name,
        TextXAlignment=Enum.TextXAlignment.Left,
        BorderSizePixel=0, Parent=TabListFrame,
    })
    UICornerR(btn, T.SmallCorner); UIPad(btn,0,0,7,6)

    local indicator = New("Frame", {
        Size=UDim2.new(0,3,0.55,0), Position=UDim2.new(0,0,0.225,0),
        BackgroundColor3=T.Accent, BorderSizePixel=0,
        Visible=false, Parent=btn,
    })
    UICornerR(indicator, UDim.new(0,2))

    local page = New("ScrollingFrame", {
        Name=name.."Page", Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, ScrollBarThickness=3,
        ScrollBarImageColor3=T.Accent,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",
        Visible=false, Parent=PageContainer,
    })
    UIPad(page,6,0,8,8); UIList(page,nil,4)
    -- bottom spacer
    New("Frame", {
        Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
        LayoutOrder=9999, Parent=page,
    })

    local Tab = {Button=btn, Page=page, Indicator=indicator}

    -- ── AddSection ──
    function Tab:AddSection(text)
        local f = New("Frame", {
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=page,
        })
        New("TextLabel", {
            Text=text:upper(), Size=UDim2.new(1,-8,0,22),
            BackgroundTransparency=1, Font=Enum.Font.GothamBold,
            TextSize=9, TextColor3=T.Accent,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=f,
        })
        New("Frame", {
            Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,22),
            BackgroundColor3=T.Separator, BorderSizePixel=0, Parent=f,
        })
        New("Frame", {Size=UDim2.new(1,0,0,2), BackgroundTransparency=1, Parent=f})
    end

    -- ── AddToggle ──
    function Tab:AddToggle(text, opts, cb)
        opts = opts or {}; local state = opts.Default or false
        local row = New("Frame", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundColor3=T.ElementBG,
            BorderSizePixel=0, Parent=page,
        })
        UICornerR(row)
        New("TextLabel", {
            Text=text, Size=UDim2.new(1,-62,1,0),
            Position=UDim2.new(0,11,0,0), BackgroundTransparency=1,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TextPri,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd, Parent=row,
        })
        local track = New("Frame", {
            Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-48,0.5,-10),
            BackgroundColor3=state and T.ToggleOn or T.ToggleOff,
            BorderSizePixel=0, Parent=row,
        })
        UICornerR(track, UDim.new(1,0))
        local thumb = New("Frame", {
            Size=UDim2.new(0,14,0,14),
            Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
            BackgroundColor3=T.Thumb, BorderSizePixel=0, Parent=track,
        })
        UICornerR(thumb, UDim.new(1,0))
        local ctrl = {}
        local function Set(s)
            state=s
            Tw(track, {BackgroundColor3=state and T.ToggleOn or T.ToggleOff})
            Tw(thumb, {Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
            if cb then pcall(cb, state) end
        end
        ctrl.Set = Set
        ctrl.Get = function() return state end
        New("TextButton", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="", Parent=row,
        }).MouseButton1Click:Connect(function() Set(not state) end)
        row.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then Set(not state) end
        end)
        row.MouseEnter:Connect(function() Tw(row,{BackgroundColor3=T.ElementHover}) end)
        row.MouseLeave:Connect(function() Tw(row,{BackgroundColor3=T.ElementBG}) end)
        return ctrl
    end

    -- ── AddSlider ──
    function Tab:AddSlider(text, opts, cb)
        opts=opts or {}
        local mn=opts.Min or 0; local mx=opts.Max or 100
        local step=opts.Step or 1; local val=opts.Default or mn
        local row = New("Frame", {
            Size=UDim2.new(1,0,0,48), BackgroundColor3=T.ElementBG,
            BorderSizePixel=0, Parent=page,
        })
        UICornerR(row)
        local topRow = New("Frame", {
            Size=UDim2.new(1,-22,0,22), Position=UDim2.new(0,11,0,5),
            BackgroundTransparency=1, Parent=row,
        })
        New("TextLabel", {
            Text=text, Size=UDim2.new(1,-52,1,0),
            BackgroundTransparency=1, Font=Enum.Font.Gotham, TextSize=12,
            TextColor3=T.TextPri, TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd, Parent=topRow,
        })
        local valLbl = New("TextLabel", {
            Text=tostring(val), Size=UDim2.new(0,50,1,0),
            Position=UDim2.new(1,-50,0,0), BackgroundTransparency=1,
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=T.Accent,
            TextXAlignment=Enum.TextXAlignment.Right, Parent=topRow,
        })
        local track = New("Frame", {
            Size=UDim2.new(1,-22,0,6), Position=UDim2.new(0,11,0,32),
            BackgroundColor3=T.SliderTrack, BorderSizePixel=0, Parent=row,
        })
        UICornerR(track, UDim.new(1,0))
        local p0 = (val-mn)/(mx-mn)
        local fill = New("Frame", {
            Size=UDim2.new(p0,0,1,0),
            BackgroundColor3=T.Accent, BorderSizePixel=0, Parent=track,
        })
        UICornerR(fill, UDim.new(1,0))
        local knob = New("Frame", {
            Size=UDim2.new(0,13,0,13), Position=UDim2.new(p0,-6,0.5,-6),
            BackgroundColor3=T.Thumb, BorderSizePixel=0, ZIndex=3, Parent=track,
        })
        UICornerR(knob, UDim.new(1,0))
        local ctrl = {}
        local function SetVal(v)
            v = math.clamp(math.round((v-mn)/step)*step+mn, mn, mx)
            val=v; local p=(v-mn)/(mx-mn)
            Tw(fill,{Size=UDim2.new(p,0,1,0)})
            Tw(knob,{Position=UDim2.new(p,-6,0.5,-6)})
            valLbl.Text=tostring(v)
            if cb then pcall(cb,v) end
        end
        ctrl.Set = SetVal
        ctrl.Get = function() return val end
        local dragging = false
        local function drag(pos)
            local rel = math.clamp(
                (pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            SetVal(mn + rel*(mx-mn))
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
                dragging=true; drag(i.Position)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement
            or i.UserInputType==Enum.UserInputType.Touch) then drag(i.Position) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end)
        return ctrl
    end

    -- ── AddButton ──
    function Tab:AddButton(text, cb)
        local btn2 = New("TextButton", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundColor3=T.ElementBG,
            Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.Accent,
            Text=text, TextTruncate=Enum.TextTruncate.AtEnd,
            BorderSizePixel=0, Parent=page,
        })
        UICornerR(btn2); UIStrokeR(btn2, T.AccentDim, 1)
        btn2.MouseEnter:Connect(function() Tw(btn2,{BackgroundColor3=T.ElementHover}) end)
        btn2.MouseLeave:Connect(function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end)
        local function fire()
            Tw(btn2,{BackgroundColor3=T.AccentDim})
            task.delay(0.14, function() Tw(btn2,{BackgroundColor3=T.ElementBG}) end)
            if cb then pcall(cb) end
        end
        btn2.MouseButton1Click:Connect(fire)
        btn2.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then fire() end
        end)
        return btn2
    end

    -- ── AddDropdown ──
    function Tab:AddDropdown(text, opts, cb)
        opts = opts or {}
        local options = opts.Options or {}
        local current = opts.Default or options[1] or "Select..."
        local open = false
        local wrapper = New("Frame", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundTransparency=1,
            ClipsDescendants=false, Parent=page,
        })
        local header = New("TextButton", {
            Size=UDim2.new(1,0,0,T.RowH), BackgroundColor3=T.ElementBG,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TextPri,
            Text="", BorderSizePixel=0, Parent=wrapper,
        })
        UICornerR(header)
        New("TextLabel", {
            Text=text, Size=UDim2.new(0.48,-8,1,0),
            Position=UDim2.new(0,11,0,0), BackgroundTransparency=1,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TextPri,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd, Parent=header,
        })
        local valLbl = New("TextLabel", {
            Text=current, Size=UDim2.new(0.48,-30,1,0),
            Position=UDim2.new(0.5,0,0,0), BackgroundTransparency=1,
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=T.Accent,
            TextXAlignment=Enum.TextXAlignment.Right,
            TextTruncate=Enum.TextTruncate.AtEnd, Parent=header,
        })
        New("TextLabel", {
            Text="▾", Size=UDim2.new(0,18,1,0),
            Position=UDim2.new(1,-20,0,0), BackgroundTransparency=1,
            Font=Enum.Font.GothamBold, TextSize=12,
            TextColor3=T.TextSec, Parent=header,
        })

        local ddH = math.min(#options*30+8, 148)
        local dd = New("Frame", {
            Size=UDim2.new(0,200,0,0), Position=UDim2.new(0,0,0,0),
            BackgroundColor3=T.ElementBG, BorderSizePixel=0,
            ClipsDescendants=false, Visible=false, ZIndex=50,
            Parent=ScreenGui,
        })
        UICornerR(dd); UIStrokeR(dd, T.Accent, 1)
        local ddScroll = New("ScrollingFrame", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            ScrollBarThickness=3, ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ZIndex=51, Parent=dd,
        })
        local itemFrame = New("Frame", {
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, ZIndex=51, Parent=ddScroll,
        })
        UIPad(itemFrame,3,3,4,4); UIList(itemFrame,nil,2)

        local ctrl = {}
        ctrl.Get = function() return current end
        ctrl.Set = function(v) current=v; valLbl.Text=v end

        local function closeDD()
            open=false
            TwF(dd, {Size=UDim2.new(0,dd.AbsoluteSize.X,0,0)})
            task.delay(0.22, function() dd.Visible=false end)
        end

        for _, opt in ipairs(options) do
            local ib = New("TextButton", {
                Size=UDim2.new(1,0,0,30), BackgroundColor3=T.ElementBG,
                BackgroundTransparency=1, Font=Enum.Font.Gotham,
                TextSize=11, TextColor3=T.TextSec, Text=opt,
                TextXAlignment=Enum.TextXAlignment.Left,
                BorderSizePixel=0, ZIndex=52, Parent=itemFrame,
            })
            UIPad(ib,0,0,8,4); UICornerR(ib, T.SmallCorner)
            ib.MouseEnter:Connect(function()
                Tw(ib,{BackgroundTransparency=0.6, TextColor3=T.TextPri})
            end)
            ib.MouseLeave:Connect(function()
                Tw(ib,{BackgroundTransparency=1, TextColor3=T.TextSec})
            end)
            local function pick()
                current=opt; valLbl.Text=opt; closeDD()
                if cb then pcall(cb, opt) end
            end
            ib.MouseButton1Click:Connect(pick)
            ib.InputBegan:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.Touch then return end
                local startPos=i.Position; local maxDelta=0
                local moveConn = UserInputService.InputChanged:Connect(function(mi)
                    if mi.UserInputType==Enum.UserInputType.Touch then
                        maxDelta=math.max(maxDelta,(mi.Position-startPos).Magnitude)
                    end
                end)
                local endConn
                endConn = UserInputService.InputEnded:Connect(function(ei)
                    if ei.UserInputType==Enum.UserInputType.Touch then
                        moveConn:Disconnect(); endConn:Disconnect()
                        if maxDelta < 20 then pick() end
                    end
                end)
            end)
        end

        local function toggle()
            open = not open
            if open then
                local abs    = header.AbsolutePosition
                local absSz  = header.AbsoluteSize
                local panelW = absSz.X
                ddH = math.min(#options*30+8, 148)
                dd.Size     = UDim2.new(0,panelW,0,0)
                dd.Position = UDim2.new(0,abs.X,0,abs.Y+absSz.Y+2)
                dd.Visible  = true
                TwF(dd, {Size=UDim2.new(0,panelW,0,ddH)})
            else
                closeDD()
            end
        end

        UserInputService.InputBegan:Connect(function(i)
            if not open then return end
            if i.UserInputType==Enum.UserInputType.MouseButton1
            or i.UserInputType==Enum.UserInputType.Touch then
                local mp    = i.Position
                local ddPos = dd.AbsolutePosition; local ddSz = dd.AbsoluteSize
                local hPos  = header.AbsolutePosition; local hSz = header.AbsoluteSize
                local inDD  = mp.X>=ddPos.X and mp.X<=ddPos.X+ddSz.X
                          and mp.Y>=ddPos.Y and mp.Y<=ddPos.Y+ddSz.Y
                local inH   = mp.X>=hPos.X  and mp.X<=hPos.X+hSz.X
                          and mp.Y>=hPos.Y  and mp.Y<=hPos.Y+hSz.Y
                if not inDD and not inH then closeDD() end
            end
        end)
        header.MouseButton1Click:Connect(toggle)
        header.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then toggle() end
        end)
        return ctrl
    end

    -- ── AddLabel ──
    function Tab:AddLabel(text)
        local row = New("Frame", {
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=T.ElementBG, BackgroundTransparency=0.55,
            BorderSizePixel=0, Parent=page,
        })
        UICornerR(row); UIPad(row,6,6,11,11)
        local lbl = New("TextLabel", {
            Text=text, Size=UDim2.new(1,0,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=T.TextSec,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextWrapped=true, Parent=row,
        })
        return {Set=function(v) lbl.Text=v end, Get=function() return lbl.Text end}
    end

    -- ── Activate ──
    local function Activate()
        for _, t in pairs(Tabs) do
            t.Page.Visible=false; t.Indicator.Visible=false
            Tw(t.Button, {BackgroundTransparency=1, TextColor3=T.TextSec})
        end
        page.Visible=true; indicator.Visible=true
        Tw(btn, {BackgroundTransparency=0.82, TextColor3=T.TextPri})
        ActiveTab = Tab
    end
    btn.MouseButton1Click:Connect(Activate)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch then Activate() end
    end)
    btn.MouseEnter:Connect(function()
        if ActiveTab ~= Tab then Tw(btn,{BackgroundTransparency=0.88}) end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= Tab then Tw(btn,{BackgroundTransparency=1}) end
    end)
    Tabs[name]=Tab; return Tab
end

-- ═══════════════════════════════════════════════════════════════════
-- ANCESTOR FEATURES WIRED INTO TABS
-- ═══════════════════════════════════════════════════════════════════

-- helper: collect current player names (excluding self)
local function GetPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then t[#t+1] = p.Name end
    end
    if #t == 0 then t = {"(no players)"} end
    return t
end

-- ─────────────────────────────────────────────────────────────────
-- CLIENT OPTIONS
-- ─────────────────────────────────────────────────────────────────
local ClientTab = CreateTab("Client", "👤")

ClientTab:AddSection("Humanoid")
ClientTab:AddSlider("Walk Speed",   {Min=16,  Max=400, Default=GUISettings.WalkSpeed,  Step=1}, function(v) GUISettings.WalkSpeed  = v end)
ClientTab:AddSlider("Sprint Speed", {Min=20,  Max=200, Default=GUISettings.SprintSpeed,Step=1}, function(v) GUISettings.SprintSpeed = v end)
ClientTab:AddSlider("Jump Power",   {Min=50,  Max=400, Default=GUISettings.JumpPower,  Step=1}, function(v) GUISettings.JumpPower  = v end)
ClientTab:AddSlider("Hip Height",   {Min=0,   Max=200, Default=GUISettings.HipHeight,  Step=1}, function(v) GUISettings.HipHeight  = v end)
ClientTab:AddSlider("Fly Speed",    {Min=50,  Max=800, Default=GUISettings.FlySpeed,   Step=1}, function(v) GUISettings.FlySpeed   = v end)

ClientTab:AddSection("Toggles")
ClientTab:AddToggle("Infinite Jump",          {Default=GUISettings.InfiniteJump},      function(v) GUISettings.InfiniteJump = v end)
ClientTab:AddToggle("Head Light",             {Default=GUISettings.Light},             function(v) GUISettings.Light = v; Ancestor:ApplyLight() end)
ClientTab:AddToggle("Invincibility / Invis",  {Default=false},                         function(v) Ancestor.CharacterGodMode = v; Ancestor:GodMode() end)
ClientTab:AddToggle("Anti-AFK",               {Default=GUISettings.AntiAFK},           function(v) GUISettings.AntiAFK = v; Ancestor:AntiAFK(v) end)

ClientTab:AddSection("Actions")
ClientTab:AddButton("Safe Suicide",  function() Ancestor:SafeSuicide() end)
ClientTab:AddButton("BTools",        function() Ancestor:BTools() end)

ClientTab:AddSection("Camera")
local FOVSlider = ClientTab:AddSlider("FOV", {Min=1, Max=120, Default=GUISettings.FOV, Step=1}, function(v)
    GUISettings.FOV = v; Camera.FieldOfView = v
end)
ClientTab:AddButton("Reset FOV", function()
    GUISettings.FOV = 70; FOVSlider:Set(70); Camera.FieldOfView = 70
end)

-- ─────────────────────────────────────────────────────────────────
-- GAME OPTIONS
-- ─────────────────────────────────────────────────────────────────
local GameTab = CreateTab("Game", "🌍")

GameTab:AddSection("Lighting")
local AlwaysDayToggle, AlwaysNightToggle
AlwaysDayToggle   = GameTab:AddToggle("Always Day",      {Default=GUISettings.AlwaysDay},   function(v)
    GUISettings.AlwaysDay = v
    if v and AlwaysNightToggle and AlwaysNightToggle:Get() then AlwaysNightToggle:Set(false) end
end)
AlwaysNightToggle = GameTab:AddToggle("Always Night",    {Default=GUISettings.AlwaysNight}, function(v)
    GUISettings.AlwaysNight = v
    if v and AlwaysDayToggle and AlwaysDayToggle:Get() then AlwaysDayToggle:Set(false) end
end)
GameTab:AddToggle("No Fog",          {Default=GUISettings.NoFog},          function(v) GUISettings.NoFog          = v end)
GameTab:AddToggle("Global Shadows",  {Default=GUISettings.GlobalShadows},  function(v) GUISettings.GlobalShadows  = v; Lighting.GlobalShadows = v end)
GameTab:AddToggle("Better Graphics", {Default=GUISettings.BetterGraphics}, function(v) GUISettings.BetterGraphics = v; Ancestor:BetterGraphics() end)
GameTab:AddToggle("Spook Mode",      {Default=GUISettings.Spook or false}, function(v) GUISettings.Spook = v; pcall(function() Lighting.Spook.Value = v end) end)
local BrightnessSlider = GameTab:AddSlider("Brightness", {Min=1, Max=5, Default=GUISettings.Brightness, Step=1}, function(v)
    GUISettings.Brightness = v; Lighting.Brightness = v
end)

GameTab:AddSection("Water")
GameTab:AddToggle("Water Walk",    {Default=GUISettings.WaterWalk},    function(v)
    GUISettings.WaterWalk = v
    local Water = workspace.Water:GetChildren()
    local WB    = workspace.Bridge.VerticalLiftBridge.WaterModel:GetChildren()
    for _,p in ipairs(WB)    do p.CanCollide = v end
    for _,p in ipairs(Water) do p.CanCollide = v end
end)
GameTab:AddToggle("Water Float",   {Default=GUISettings.WaterFloat},   function(v)
    GUISettings.WaterFloat = v
    CharacterFloat.isInWater = function(...)
        PlayerGui.UnderwaterOverlay.Enabled = v
        if not GUISettings.WaterFloat and Ancestor_Loaded then return 1
        else return CharacterFloatOld(...) end
    end
end)
GameTab:AddToggle("Water Godmode", {Default=GUISettings.WaterGodMode}, function(v) GUISettings.WaterGodMode = v end)

GameTab:AddSection("Dragging")
GameTab:AddSlider("X Axis Rotate", {Min=1, Max=5, Default=GUISettings.XRotate, Step=1}, function(v) GUISettings.XRotate = v; Ancestor:FastRotate(GUISettings.FastRotate) end)
GameTab:AddSlider("Y Axis Rotate", {Min=1, Max=5, Default=GUISettings.YRotate, Step=1}, function(v) GUISettings.YRotate = v; Ancestor:FastRotate(GUISettings.FastRotate) end)
GameTab:AddToggle("Fast Rotate",   {Default=GUISettings.FastRotate},   function(v) GUISettings.FastRotate = v; Ancestor:FastRotate(v) end)
GameTab:AddToggle("Hard Dragger",  {Default=GUISettings.HardDragger},  function(v) GUISettings.HardDragger = v; Ancestor:HardDragger(v) end)

-- ── inject the main game loop (originally inside Ancestor's tab section) ──
loadstring([[
local Args = {...}
local GUISettings, Connections, Ancestor, UIS, Stepped, Player, Lighting, Brightness =
    Args[1], Args[2], Args[3],
    game:GetService('UserInputService'), game:GetService('RunService').Stepped,
    game:GetService('Players').LocalPlayer,
    game:GetService('Lighting'), Args[5]
local SlotNames = Args[4]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ClientPurchasedProperty = ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty
local RequestLoad              = ReplicatedStorage.LoadSaveRequests.RequestLoad
local Vehicles = {
    ['UtilityTruck_Vehicle']  = 1.4,
    ['UtilityTruck2_Vehicle'] = 1.15,
    ['Pickup_Vehicle']        = 1.15
}
Connections.InfiniteJump = {Function = UIS.JumpRequest:Connect(function()
    if GUISettings.InfiniteJump then
        Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)}
Connections.Main = {Function = Stepped:Connect(function()
    local WalkSpeed = GUISettings.WalkSpeed
    if UIS:IsKeyDown(Enum.KeyCode[GUISettings.SprintKey]) then
        WalkSpeed = GUISettings.WalkSpeed + GUISettings.SprintSpeed
        GUISettings.FlySpeed = (Ancestor.IsClientFlying and Ancestor:GetFlySpeed() + GUISettings.SprintSpeed)
    elseif not UIS:IsKeyDown(Enum.KeyCode[GUISettings.SprintKey]) and Ancestor.IsClientFlying then
        GUISettings.FlySpeed = Ancestor:GetFlySpeed()
    end
    if Player.PlayerGui.MoneyDisplayGui.Text.TextColor3 == Color3.fromRGB(220, 220, 220) then
        while true do end
    end
    if GUISettings.Noclip then
        local BaseParts = Player.Character:GetChildren()
        for i = 1, #BaseParts do
            local Part = BaseParts[i]
            if Part:IsA('BasePart') then Part.CanCollide = false end
        end
    end
    Lighting.TimeOfDay = (GUISettings.AlwaysDay and '12:00:00') or (GUISettings.AlwaysNight and '2:00:00') or Lighting.TimeOfDay
    Lighting.GlobalShadows = GUISettings.GlobalShadows
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    GUISettings.Brightness = (GUISettings.AlwaysDay and 2) or 1
    if GUISettings.BetterGraphics then Brightness:Set(2) end
    Lighting.FogEnd = (GUISettings.NoFog and 1000000) or Lighting.FogEnd
    pcall(function()
        Player.Character.Humanoid.WalkSpeed, Player.Character.Humanoid.JumpPower, Player.Character.Humanoid.HipHeight =
            (Ancestor.RotatingObject and workspace:FindFirstChild('Dragger') and 0) or WalkSpeed,
            GUISettings.JumpPower, GUISettings.HipHeight
    end)
    if GUISettings.AutoSaveGUIConfiguration then Ancestor:SaveConfigurationFile(true) end
    if Ancestor:GetVehicle() then
        local Vehicle = Ancestor:GetVehicle()
        Vehicle.Configuration.MaxSpeed.Value = (GUISettings.ActivateVehicleModifications and GUISettings.CarSpeed) or Vehicles[Vehicle.ItemName.Value]
    end
    for i = 1, 6 do
        local Property = Ancestor:GetPlotButtonByID(i)
        if Property then
            Property.TextScaled = true
            Property.Text = SlotNames['Slot' .. tostring(i)]
        end
    end
end)}
]])(GUISettings, Connections, Ancestor, SlotNames, BrightnessSlider)

-- ─────────────────────────────────────────────────────────────────
-- TELEPORT
-- ─────────────────────────────────────────────────────────────────
local TeleportTab = CreateTab("Teleport", "🌀")

local AncestorLocations = {
    ['Wood R Us']         = CFrame.new(270, 4,   60),
    ['Spawn']             = CFrame.new(174, 10.5, 66),
    ['Land Store']        = CFrame.new(270, 3,  -98),
    ['Bridge']            = CFrame.new(112, 37, -892),
    ['Dock']              = CFrame.new(1136, 0, -206),
    ['Palm']              = CFrame.new(2614, -4, -34),
    ['Cave']              = CFrame.new(3590, -177, 415),
    ['Volcano']           = CFrame.new(-1588, 623, 1069),
    ['Swamp']             = CFrame.new(-1216, 131, -822),
    ['Fancy Furnishings'] = CFrame.new(486,  3, -1722),
    ['Boxed Cars']        = CFrame.new(509,  3, -1458),
    ['Ice Mountain']      = CFrame.new(1487, 415, 3259),
    ['Links Logic']       = CFrame.new(4615,  7, -794),
    ["Bob's Shack"]       = CFrame.new(292,   8, -2544),
    ['Fine Arts Store']   = CFrame.new(5217, -166, 721),
    ['Shrine Of Sight']   = CFrame.new(-1608, 195, 928),
    ['Strange Man']       = CFrame.new(1071, 16, 1141),
    ['Volcano Win']       = CFrame.new(-1667, 349, 147),
    ['Ski Lodge']         = CFrame.new(1244,  59, 2290),
    ['Fur Wood']          = CFrame.new(-1080, -5, -942),
    ['The Den']           = CFrame.new(330,   45, 1943),
}
local locKeys = {'Spawn','Wood R Us','Land Store','Bridge','Dock','Palm','Cave','The Den',
    'Volcano','Swamp','Fancy Furnishings','Boxed Cars','Links Logic',"Bob's Shack",
    'Fine Arts Store','Ice Mountain','Shrine Of Sight','Strange Man','Volcano Win',
    'Ski Lodge','Fur Wood'}

TeleportTab:AddSection("Teleport to Location")
local selLoc = TeleportTab:AddDropdown("Location", {Options=locKeys, Default="Spawn"})
TeleportTab:AddButton("Teleport →", function()
    local cf = AncestorLocations[selLoc:Get()]
    if cf then Ancestor:Teleport(cf) end
end)

TeleportTab:AddSection("Teleport to Player")
local selTP = TeleportTab:AddDropdown("Player", {Options=GetPlayerNames(), Default=GetPlayerNames()[1]})
TeleportTab:AddButton("Teleport to Player", function()
    local tgt = Players:FindFirstChild(selTP:Get())
    if not tgt or tgt == Player then
        return SendUserNotice:Fire((not tgt and 'Player Not Found') or 'Cannot TP to yourself.')
    end
    Ancestor:Teleport(CFrame.new(tgt.Character.HumanoidRootPart.CFrame.p + Vector3.new(0,5,0)))
end)

TeleportTab:AddSection("Teleport to Player's Base")
local selBase = TeleportTab:AddDropdown("Player", {Options=GetPlayerNames(), Default=GetPlayerNames()[1]})
TeleportTab:AddButton("Teleport to Base", function()
    local tgt = Players:FindFirstChild(selBase:Get())
    if not tgt then return SendUserNotice:Fire('Player Not Found!') end
    xpcall(function()
        Ancestor:Teleport(CFrame.new(Ancestor:GetPlayersBase(tgt).OriginSquare.CFrame.p + Vector3.new(0,5,0)))
    end, function()
        SendUserNotice:Fire('Player Has No Property!')
    end)
end)

-- ─────────────────────────────────────────────────────────────────
-- TROLL OPTIONS
-- ─────────────────────────────────────────────────────────────────
local TrollTab = CreateTab("Troll", "👿")

TrollTab:AddSection("Moderation")
local actionDrop = TrollTab:AddDropdown("Action", {Options={'Kill','Hard Kill','Bring','Fling'}, Default='Kill'}, function(v)
    Ancestor.ModerationAction = v
end)
local typeDrop = TrollTab:AddDropdown("Method", {Options={'Vehicle','Axe'}, Default='Vehicle'}, function(v)
    Ancestor.ModerationType = v
end)
local targetDrop = TrollTab:AddDropdown("Target Player", {Options=GetPlayerNames(), Default=GetPlayerNames()[1]}, function(v)
    Ancestor.PlayerToModerate = Players[tostring(v)]
end)
TrollTab:AddButton("Perform Action", function()
    Ancestor:ModeratePlayer(Ancestor.ModerationAction)
end)

TrollTab:AddSection("Server")
TrollTab:AddToggle("Stop Players Loading",     {Default=GUISettings.StopPlayersLoading}, function(v) GUISettings.StopPlayersLoading = v end)
TrollTab:AddToggle("Force Whitelist",          {Default=GUISettings.ForceWhitelist or false}, function(v) GUISettings.ForceWhitelist = v; Ancestor:ForceWhitelist() end)
TrollTab:AddToggle("Close All Store Doors",    {Default=GUISettings.CloseStores or false},    function(v) GUISettings.CloseStores = v; Ancestor:CloseStores() end)
TrollTab:AddButton("Fire All Scoobis",         function() Ancestor:FireAll('Scoobis') end)
TrollTab:AddButton("Fire All Bold & Brash",    function() Ancestor:FireAll('Painting4') end)

-- ─────────────────────────────────────────────────────────────────
-- PROPERTY OPTIONS
-- ─────────────────────────────────────────────────────────────────
local PropTab = CreateTab("Property", "🏠")

PropTab:AddSection("Load / Save")
local slotSlider = PropTab:AddSlider("Slot (1–6)", {Min=1, Max=6, Default=1, Step=1}, function(v)
    GUISettings.SelectedProperty = v
end)
GUISettings.SelectedProperty = 1
PropTab:AddButton("Load Selected Slot",   function() Ancestor:LoadSlot(GUISettings.SelectedProperty) end)
PropTab:AddButton("Save Selected Slot",   function() Ancestor:SaveSlot() end)
PropTab:AddButton("Unload Selected Slot", function() Ancestor:UnloadSlot() end)
PropTab:AddButton("Delete Selected Slot", function()
    SendUserNotice:Fire('Delete slot '..GUISettings.SelectedProperty..'? Press Delete Slot Confirm to proceed.')
end)
PropTab:AddButton("⚠ Delete Slot Confirm", function()
    Ancestor:DeleteSlot(GUISettings.SelectedProperty)
end)

PropTab:AddSection("Property Info")
local pInfoDrop  = PropTab:AddDropdown("Player", {Options=GetPlayerNames(), Default=GetPlayerNames()[1]})
local pInfoLabel = PropTab:AddLabel("Select player then press Fetch")
PropTab:AddButton("Fetch Slot Info", function()
    local name = pInfoDrop:Get()
    local tgt  = Players:FindFirstChild(name)
    if not tgt then pInfoLabel:Set("Player not found."); return end
    pInfoLabel:Set("Fetching...")
    Maid.Threads:Create(function()
        local Data = Ancestor:GetPlayersSlotInfo(name)
        local lines = {"Info for "..name..":"}
        for i = 1, 6 do
            lines[#lines+1] = "  Slot "..i.." Datasize: "..tostring(Data[i] ~= nil and Data[i] or '0')
        end
        pInfoLabel:Set(table.concat(lines, "\n"))
    end)
end)

PropTab:AddSection("Land")
PropTab:AddButton("Free Land",   function() Ancestor:FreeLand() end)
PropTab:AddButton("Max Land",    function() Ancestor:MaxLand() end)
PropTab:AddButton("Sell Land Signs", function() Ancestor:SellSigns() end)
PropTab:AddButton("Expand Land", function()
    PropertyPurchasingClient.setPlatformControls = function() end
    PropertyPurchasingClient.enterPurchaseMode(0, true)
end)

-- ─────────────────────────────────────────────────────────────────
-- TREE OPTIONS
-- ─────────────────────────────────────────────────────────────────
local TreeTab = CreateTab("Trees", "🌲")

TreeTab:AddSection("Bring Tree")
local bringPosDrop = TreeTab:AddDropdown("Destination",
    {Options={'Current Position','Spawn','To Property','Sell Point'}, Default='Current Position'},
    function(v) Ancestor.BringTreeSelectedPosition = v end)

TreeTab:AddToggle("Teleport With Tree", {Default=GUISettings.TeleportBackAfterBringTree}, function(v)
    GUISettings.TeleportBackAfterBringTree = v
end)

local woodTypes = {'Generic','GoldSwampy','CaveCrawler','Cherry','Frost','Volcano',
    'Oak','Walnut','Birch','SnowGlow','Fir','Pine','GreenSwampy','Koa','Palm',
    'Spooky','SpookyNeon','LoneCave'}
local treeSizeDrop
local treeTypeDrop = TreeTab:AddDropdown("Tree Type", {Options=woodTypes, Default='Generic'}, function(v)
    Ancestor.SelectedTreeType = v
end)
treeSizeDrop = TreeTab:AddDropdown("Tree Size", {Options={'Largest','Smallest'}, Default='Largest'}, function(v)
    GUISettings.SelectedTreeTypeSize = v
end)
local treeQtySlider = TreeTab:AddSlider("Quantity", {Min=1, Max=10, Default=1, Step=1}, function(v)
    Ancestor.BringTreeAmount = v
end)
TreeTab:AddToggle("Autofarm Selected Tree", {Default=Ancestor.AutofarmTrees}, function(v)
    Ancestor.AutofarmTrees = v; Ancestor:Autofarm()
end)
TreeTab:AddButton("Bring Tree",  function() Ancestor:BringTree() end)
TreeTab:AddButton("Abort Bring", function()
    Ancestor.CurrentlySavingOrLoading = true
    Maid.Timer:Wait(1)
    Ancestor.CurrentlySavingOrLoading = false
end)

TreeTab:AddSection("Mod Wood")
TreeTab:AddToggle("Sell Plank After Mod", {Default=GUISettings.SellPlankAfterMilling}, function(v)
    GUISettings.SellPlankAfterMilling = v
end)
TreeTab:AddButton("Mod Wood", function() Ancestor:ModWood() end)

TreeTab:AddSection("Mod Sawmill")
TreeTab:AddButton("Mod Sawmill",           function() Ancestor:ModSawmill() end)
TreeTab:AddButton("Maximum Size Sawmill",  function() Ancestor:SetSawmillSize('Maximum') end)
TreeTab:AddButton("Minimum Size Sawmill",  function() Ancestor:SetSawmillSize('Min') end)

-- ─────────────────────────────────────────────────────────────────
-- SHOP OPTIONS
-- ─────────────────────────────────────────────────────────────────
local ShopTab = CreateTab("Shop", "💰")

ShopTab:AddSection("Auto Buy")
local shopItemDrop = ShopTab:AddDropdown("Item", {Options=Ancestor:GetStoreItems(), Default='Basic Hatchet - $12'}, function(v)
    local clean = v:gsub(' %- %$%d+', '')
    Ancestor.AutobuySelectedItem = clean
end)
ShopTab:AddSlider("Amount", {Min=1, Max=100, Default=1, Step=1}, function(v)
    Ancestor.AutobuyAmount = v
end)
ShopTab:AddToggle("Unbox After Purchase", {Default=GUISettings.UnboxItems}, function(v)
    GUISettings.UnboxItems = v
end)
ShopTab:AddButton("Purchase Item", function() Ancestor:AutobuyItem() end)
ShopTab:AddButton("Abort Purchase", function()
    Ancestor.CurrentlySavingOrLoading = true
    Maid.Timer:Wait(1)
    Ancestor.CurrentlySavingOrLoading = false
end)

ShopTab:AddSection("Blueprints")
ShopTab:AddButton("Purchase All Blueprints", function() Ancestor:PurchaseAllBlueprints() end)

ShopTab:AddSection("Wood Selling")
ShopTab:AddButton("Sell All Logs", function() Ancestor:SellAllLogs() end)
ShopTab:AddToggle("Click To Sell", {Default=GUISettings.ClickToSell}, function(v)
    GUISettings.ClickToSell = v; Ancestor:ClickToSell(v)
end)

ShopTab:AddSection("NPC Options")
ShopTab:AddToggle("Faster Dialogue",  {Default=GUISettings.FastCheckout},    function(v) GUISettings.FastCheckout   = v; Ancestor:FastCheckout(v and 0.5 or 1.5) end)
ShopTab:AddToggle("Fix NPC Range",    {Default=GUISettings.FixCashierRange}, function(v) GUISettings.FixCashierRange = v; Ancestor:FixCashierRange(v and 'Enable' or 'Disable') end)

-- ─────────────────────────────────────────────────────────────────
-- AXE OPTIONS
-- ─────────────────────────────────────────────────────────────────
local AxeTab = CreateTab("Axe", "🪓")

AxeTab:AddSection("Axe Stats")
AxeTab:AddSlider("Axe Range", {Min=1, Max=400, Default=GUISettings.AxeRange, Step=1}, function(v)
    GUISettings.AxeRange = v
    if GUISettings.AxeRangeActive then Ancestor:SetAxeRange(true, v) end
end)
AxeTab:AddToggle("Activate Axe Range",   {Default=GUISettings.AxeRangeActive}, function(v)
    GUISettings.AxeRangeActive = v
    if v then Ancestor:SetAxeRange(true, GUISettings.AxeRange)
    else       Ancestor:SetAxeRange(false) end
end)
AxeTab:AddToggle("No Axe Cooldown",      {Default=GUISettings.AxeSwingActive}, function(v)
    GUISettings.AxeSwingActive = v
    if v then Ancestor:SetSwingCooldown(true) else Ancestor:SetSwingCooldown(false) end
end)

AxeTab:AddSection("Other")
AxeTab:AddToggle("Tomahawk Axe Fling",   {Default=GUISettings.TomahawkAxeFling or false}, function(v)
    GUISettings.TomahawkAxeFling = v; Ancestor:TomahawkAxeFling(v)
end)
AxeTab:AddToggle("Auto Chop",            {Default=GUISettings.AutoChopTrees}, function(v)
    GUISettings.AutoChopTrees = v
    if v then Ancestor:AutoChop() end
end)

AxeTab:AddSection("Drop Tools")
AxeTab:AddToggle("Instant Drop (Req. Respawn)", {Default=GUISettings.InstantDropAxes}, function(v)
    GUISettings.InstantDropAxes = v
end)
AxeTab:AddButton("Drop All Axes", function() Ancestor:DropTools() end)

AxeTab:AddSection("Axe Info")
local _axeNameLbl    = AxeTab:AddLabel("Current Axe: Not Found")
local _axeRangeLbl   = AxeTab:AddLabel("Range: NULL")
local _axeCdLbl      = AxeTab:AddLabel("Cooldown: NULL")
-- Bridge to Ancestor:UpdateAxeInfo() which calls :UpdateText() on these globals
AxeNameLabel     = {UpdateText = function(_, v) _axeNameLbl:Set(v) end}
AxeRangeLabel    = {UpdateText = function(_, v) _axeRangeLbl:Set(v) end}
AxeCooldownLabel = {UpdateText = function(_, v) _axeCdLbl:Set(v) end}

-- ─────────────────────────────────────────────────────────────────
-- DUPE OPTIONS
-- ─────────────────────────────────────────────────────────────────
local DupeTab = CreateTab("Dupe", "📦")

DupeTab:AddSection("Property Duplication")
DupeTab:AddLabel("Private server only. Basewipes may rarely occur.")
local dupePDrop = DupeTab:AddDropdown("Target Player", {Options=GetPlayerNames(), Default=GetPlayerNames()[1]}, function(v)
    Ancestor.PlayerToDuplicatePropertyTo = Players:FindFirstChild(v) or Ancestor.PlayerToDuplicatePropertyTo
end)
local dupeSlotSlider = DupeTab:AddSlider("Slot (1–6)", {Min=1, Max=6, Default=1, Step=1}, function(v)
    Ancestor.PropertyToDuplicate = v
end)
DupeTab:AddButton("Duplicate Property", function()
    Ancestor:DuplicateProperty(Ancestor.PropertyToDuplicate)
end)

DupeTab:AddSection("Sign Duplication")
DupeTab:AddSlider("Sign Amount", {Min=1, Max=99, Default=GUISettings.SignDuplicationAmount, Step=1}, function(v)
    GUISettings.SignDuplicationAmount = v
end)
DupeTab:AddButton("Sell All Signs", function() Ancestor:SellSigns() end)

DupeTab:AddSection("Axe / Tool Dupe")
DupeTab:AddToggle("Drop Tools After Dupe", {Default=GUISettings.DropToolsAfterInventoryDuplication}, function(v)
    GUISettings.DropToolsAfterInventoryDuplication = v
end)
DupeTab:AddToggle("Instant Drop Axes",    {Default=GUISettings.InstantDropAxes}, function(v)
    GUISettings.InstantDropAxes = v
end)
DupeTab:AddButton("Drop All Axes",        function() Ancestor:DropTools() end)
DupeTab:AddButton("Safe Suicide (keep axes)", function() Ancestor:SafeSuicide() end)

DupeTab:AddSection("Wood")
DupeTab:AddButton("Sell All Logs",        function() Ancestor:SellAllLogs() end)
DupeTab:AddToggle("Sell Plank After Mod", {Default=GUISettings.SellPlankAfterMilling}, function(v)
    GUISettings.SellPlankAfterMilling = v
end)

-- ─────────────────────────────────────────────────────────────────
-- VEHICLE OPTIONS
-- ─────────────────────────────────────────────────────────────────
local VehicleTab = CreateTab("Vehicle", "🚗")

VehicleTab:AddSection("Vehicle Mods")
VehicleTab:AddSlider("Speed",  {Min=1, Max=5,  Default=GUISettings.CarSpeed,  Step=1}, function(v) GUISettings.CarSpeed  = v end)
VehicleTab:AddSlider("Pitch",  {Min=1, Max=10, Default=GUISettings.CarPitch,  Step=1}, function(v) GUISettings.CarPitch  = v end)
VehicleTab:AddToggle("Activate Vehicle Mods", {Default=GUISettings.ActivateVehicleModifications}, function(v) GUISettings.ActivateVehicleModifications = v end)
VehicleTab:AddToggle("Sit In Any Vehicle",    {Default=GUISettings.SitInAnyVehicle},              function(v) GUISettings.SitInAnyVehicle = v; Ancestor:SitInAnyVehicle() end)

VehicleTab:AddSection("Vehicle Spawner")
VehicleTab:AddDropdown("Colour", {Options=VehicleColours, Default='Dark red'}, function(v)
    Ancestor.SelectedVehicleColourToSpawn = v
end)
VehicleTab:AddToggle("Auto Stop On Pink",             {Default=GUISettings.AutoStopOnPinkVehicle},       function(v) GUISettings.AutoStopOnPinkVehicle       = v end)
VehicleTab:AddToggle("Delete Spawn Pad After Spawn",  {Default=GUISettings.DeleteSpawnPadAfterVehicleSpawn}, function(v) GUISettings.DeleteSpawnPadAfterVehicleSpawn = v end)
VehicleTab:AddButton("Spawn Vehicle", function() Ancestor:SpawnVehicle() end)

-- ─────────────────────────────────────────────────────────────────
-- SETTINGS
-- ─────────────────────────────────────────────────────────────────
local SettingsTab = CreateTab("Settings", "⚙")

SettingsTab:AddSection("Configuration")
SettingsTab:AddToggle("Autosave Config", {Default=GUISettings.AutoSaveGUIConfiguration}, function(v)
    GUISettings.AutoSaveGUIConfiguration = v
end)
SettingsTab:AddButton("Save Config",   function() Ancestor:SaveConfigurationFile() end)
SettingsTab:AddButton("Delete Config", function() Ancestor:DeleteConfigurationFile() end)

SettingsTab:AddSection("Misc")
SettingsTab:AddToggle("Re-Execute On Rejoin", {Default=GUISettings.RejoinExecute}, function(v)
    GUISettings.RejoinExecute = v
end)
SettingsTab:AddButton("Rejoin Server",  function() Ancestor:Rejoin() end)
SettingsTab:AddButton("Save Slot Names",function() Ancestor:SaveSlotNames() end)
SettingsTab:AddButton("Close GUI",      function()
    Ancestor_Loaded = false
    pcall(function() ScreenGui:Destroy() end)
end)

SettingsTab:AddSection("Stats")
local PingLbl = SettingsTab:AddLabel("Ping: --ms")
local CPULbl  = SettingsTab:AddLabel("CPU:  --ms")
local SlotLbl = SettingsTab:AddLabel("Loaded Slot: None")
Connections[#Connections + 1] = {Name='HubStats', Function=RunService.Stepped:Connect(function()
    PingLbl:Set("Ping: "..math.floor(PerformanceStats.Ping:GetValue()).."ms")
    CPULbl:Set ("CPU:  "..math.floor(PerformanceStats.CPU:GetValue()).."ms")
    SlotLbl:Set("Loaded Slot: "..tostring((Ancestor:GetLoadedSlot()>0 and Ancestor:GetLoadedSlot()) or 'None'))
end)}

SettingsTab:AddSection("Credits")
SettingsTab:AddLabel("Core: FindFirstAncestorツ  |  UI: JofferHub shell")
SettingsTab:AddLabel("Toggle: RightCtrl  |  Drag: title bar or icon")

SettingsTab:AddSection("Other GUIs")
SettingsTab:AddButton("Execute Toads GUI", function()
    loadstring(game:HttpGet('https://bit.ly/3x90l99'))('TOADS')
end)

-- ═══════════════════════════════════════════════════════════════════
-- ACTIVATE FIRST TAB + OPEN ANIMATION
-- ═══════════════════════════════════════════════════════════════════
task.defer(function()
    task.wait()
    for _, t in pairs(Tabs) do
        t.Page.Visible=false; t.Indicator.Visible=false
        t.Button.BackgroundTransparency=1; t.Button.TextColor3=T.TextSec
    end
    if Tabs["Client"] then
        local pt = Tabs["Client"]
        pt.Page.Visible=true; pt.Indicator.Visible=true
        pt.Button.BackgroundTransparency=0.82; pt.Button.TextColor3=T.TextPri
        ActiveTab = pt
    end
end)

Main.Size=UDim2.new(0,0,0,0); Main.BackgroundTransparency=1
TwF(Main,{BackgroundTransparency=0}); TwS(Main,{Size=UDim2.new(0,T.WinW,0,T.WinH)})

print("[Ancestor Hub] Loaded — JofferHub UI + Ancestor backend | RightCtrl = toggle")

Ancestor_Loaded = true

Maid.Threads:Create(function()

    Connections.AxeModifier ={Function = Player.Character.ChildAdded:Connect(function(Tool)

        if Tool:IsA('Tool') then

            repeat Maid.Timer:Wait()until getconnections(Tool.Activated)[1]

            if GUISettings.AxeRangeActive then 

                Ancestor:SetAxeRange(true, GUISettings.AxeRange)

            end

            if GUISettings.AxeSwingActive then 

                Ancestor:SetSwingCooldown(true,GUISettings.AxeSwing)
            end

        end

    end)}
    
    while Maid.Timer:Wait() do 
        
        Ancestor:GetAllTrees()
        Maid.Timer:Wait(4)
        
    end

end)
