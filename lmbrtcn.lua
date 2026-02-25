--[[
    LT2 Axe Dupe — Final
    
    WHY PREVIOUS VERSIONS HUNG:
    ClientMayLoad:InvokeServer() never returns in some executors —
    the script freezes there invisibly. The axe just unequips and nothing else.
    
    FIX: Use firesignal() to click the game's own GUI buttons.
    The game's own LocalScript handles all the remotes.
    We only need to intercept SelectLoadPlot to return our property.
    
    REQUIREMENTS:
    1. Land must be loaded (you own a plot in the game)
    2. Axe in backpack — UNEQUIPPED
    3. Slot SLOT has a save that includes your axe
    4. Executor must support: firesignal, getcallbackvalue (most do)
]]

local SLOT = 1  -- Change this to whichever slot has your save

-- ─────────────────────────────────────────────────────────────────────────────
local lp  = game.Players.LocalPlayer
local RS  = game:GetService("ReplicatedStorage")

-- Big on-screen status label (always visible, no console needed)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DupeStatus"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = lp.PlayerGui

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0, 420, 0, 54)
lbl.Position = UDim2.new(0.5, -210, 0, 12)
lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
lbl.BackgroundTransparency = 0.15
lbl.TextColor3 = Color3.fromRGB(255, 255, 100)
lbl.TextSize = 17
lbl.Font = Enum.Font.GothamBold
lbl.Text = "AxeDupe: starting..."
lbl.TextWrapped = true
lbl.Parent = screenGui

local function status(msg)
    lbl.Text = "AxeDupe: " .. msg
    print("[AxeDupe] " .. msg)
end

local function countAxes()
    local n = 0
    for _, v in ipairs(lp.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("ToolName") then n += 1 end
    end
    local c = lp.Character
    if c then
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then n += 1 end
        end
    end
    return n
end

local function getMyProp()
    for _, p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild("Owner") and p.Owner.Value == lp then
            return p
        end
    end
    return nil
end

-- Unequip axe (so it's in Backpack, not character)
local c = lp.Character
if c then
    local hum = c:FindFirstChild("Humanoid")
    if hum then hum:UnequipTools() end
end
task.wait(0.3)

-- ── VALIDATE ────────────────────────────────────────────────────────────────

local prop = getMyProp()
if not prop then
    status("FAIL — No land found. Load your land first!")
    task.wait(6)
    screenGui:Destroy()
    return
end

local before = countAxes()
if before == 0 then
    status("FAIL — No axe in backpack. Unequip your axe first.")
    task.wait(6)
    screenGui:Destroy()
    return
end

status("Axes before: " .. before .. " | Prop: " .. prop.Name)
task.wait(1)

-- ── HOOK SelectLoadPlot ──────────────────────────────────────────────────────
-- Server calls this asking "which property should I load onto?"
-- We intercept it and return the player's own property.
-- Must be set BEFORE anything triggers RequestLoad.

local SelectLoadPlot = RS.PropertyPurchasing.SelectLoadPlot
local SetPropPurch   = RS.PropertyPurchasing.SetPropertyPurchasingValue

local originalHook = getcallbackvalue(SelectLoadPlot, "OnClientInvoke")
local hookFired = false

SelectLoadPlot.OnClientInvoke = function(...)
    hookFired = true
    status("Hook fired! Returning property...")
    -- Keep override alive to counter the game's exitAll() signal
    task.spawn(function()
        for _ = 1, 12 do
            pcall(function() SetPropPurch:InvokeServer(true) end)
            task.wait(0.35)
        end
    end)
    -- Restore after a delay
    task.delay(8, function()
        SelectLoadPlot.OnClientInvoke = originalHook
    end)
    return prop, 0
end

-- ── FIND AND CLICK GAME'S OWN LOAD BUTTON ───────────────────────────────────
-- Use firesignal() to click the game's GUI — this way the game's own
-- LocalScript runs the load, with correct args and state management.
-- We never call ClientMayLoad or RequestLoad ourselves.

status("Opening save menu...")
task.wait(0.3)

-- Try to open the LoadSaveGUI via the MenuGUI
local menuGui = lp.PlayerGui:FindFirstChild("MenuGUI")
local loadSaveGui = lp.PlayerGui:FindFirstChild("LoadSaveGUI")

if not loadSaveGui then
    status("FAIL — LoadSaveGUI not found in PlayerGui")
    SelectLoadPlot.OnClientInvoke = originalHook
    task.wait(5)
    screenGui:Destroy()
    return
end

-- Click the SaveLoad menu item to open the slot list
local saveLoadBtn = menuGui
    and menuGui:FindFirstChild("Menu")
    and menuGui.Menu:FindFirstChild("Main")
    and menuGui.Menu.Main:FindFirstChild("MenuItems")
    and menuGui.Menu.Main.MenuItems:FindFirstChild("SaveLoad")

if saveLoadBtn then
    firesignal(saveLoadBtn.MouseButton1Click)
    task.wait(0.6)
end

-- Find slot list
local slotList = loadSaveGui:FindFirstChild("SlotList")
if not slotList then
    status("FAIL — SlotList GUI not found")
    SelectLoadPlot.OnClientInvoke = originalHook
    task.wait(5)
    screenGui:Destroy()
    return
end

-- Make slot list visible if not already (in case menu click didn't work)
if not slotList.Visible then
    slotList.Visible = true
end

status("Finding slot " .. SLOT .. " button...")
task.wait(0.4)

-- Find the slot button for our slot number
-- Buttons are in SlotList.Main, named or positioned by slot index
-- SlotName.Text is like "Slot 1", "Slot 2", etc.
local slotBtn = nil
local slotMain = slotList:FindFirstChild("Main")

if slotMain then
    -- First pass: find by SlotName text
    for _, child in ipairs(slotMain:GetChildren()) do
        if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") or child:IsA("Frame") then
            local sn = child:FindFirstChild("SlotName")
            if sn and (sn.Text == "Slot " .. SLOT or sn.Text:find(tostring(SLOT))) then
                slotBtn = child
                break
            end
        end
    end
    
    -- Second pass: by index (slot buttons are created in order)
    if not slotBtn then
        local btns = {}
        for _, child in ipairs(slotMain:GetChildren()) do
            if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
                table.insert(btns, child)
            end
        end
        table.sort(btns, function(a, b)
            return a.AbsolutePosition.Y < b.AbsolutePosition.Y
        end)
        slotBtn = btns[SLOT]
    end
end

if not slotBtn then
    -- GUI buttons weren't ready yet, give it a moment
    status("Waiting for slot list to populate...")
    task.wait(1.5)
    if slotMain then
        for _, child in ipairs(slotMain:GetChildren()) do
            local sn = child:FindFirstChild("SlotName")
            if sn and (sn.Text:find(tostring(SLOT))) then
                slotBtn = child
                break
            end
        end
    end
end

if not slotBtn then
    status("FAIL — Slot " .. SLOT .. " button not found. Is the save menu open?")
    status("Try opening the save menu manually first, then run script.")
    SelectLoadPlot.OnClientInvoke = originalHook
    task.wait(6)
    screenGui:Destroy()
    return
end

status("Clicking slot " .. SLOT .. "...")
firesignal(slotBtn.MouseButton1Click)
task.wait(0.8)

-- Now find the SlotInfo panel and click Load
local slotInfo = loadSaveGui:FindFirstChild("SlotInfo")
if slotInfo and not slotInfo.Visible then
    slotInfo.Visible = true  -- force visible if needed
end

-- Find the Load button inside SlotInfo
local loadBtn = nil
if slotInfo then
    local infoMain = slotInfo:FindFirstChild("Main")
    if infoMain then
        loadBtn = infoMain:FindFirstChild("Load")
    end
end

if not loadBtn then
    status("FAIL — Load button not found in SlotInfo")
    SelectLoadPlot.OnClientInvoke = originalHook
    task.wait(5)
    screenGui:Destroy()
    return
end

if not loadBtn.Visible then
    loadBtn.Visible = true  -- make sure it's visible/clickable
end

status("Clicking Load...")
firesignal(loadBtn.MouseButton1Click)
task.wait(0.5)

-- ── WAIT FOR RESULT ──────────────────────────────────────────────────────────
status("Loading... waiting for respawn...")

-- Wait for hook to fire (means RequestLoad reached the server)
local t = 0
while not hookFired and t < 20 do
    task.wait(0.5)
    t += 0.5
end

if not hookFired then
    status("Hook never fired. Load may be on cooldown or slot has no save.")
    SelectLoadPlot.OnClientInvoke = originalHook
    task.wait(5)
    screenGui:Destroy()
    return
end

-- Wait for character to respawn
local newChar = lp.CharacterAdded:Wait(20)
if newChar then
    newChar:WaitForChild("HumanoidRootPart", 10)
end
task.wait(3)

-- Count axes
local after = countAxes()
local diff = after - before

if diff > 0 then
    lbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    status("SUCCESS! " .. before .. " → " .. after .. " axes (+" .. diff .. ")")
elseif diff == 0 then
    lbl.TextColor3 = Color3.fromRGB(255, 180, 50)
    status("No change: still " .. after .. " axes. Slot " .. SLOT .. " may have same count.")
else
    lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    status("Lost axes: " .. before .. " → " .. after .. ". Something went wrong.")
end

task.wait(8)
screenGui:Destroy()
