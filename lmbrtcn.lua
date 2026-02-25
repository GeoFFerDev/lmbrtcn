--[[
    LT2 Axe Dupe v4 - Correct Order
    
    REAL SEQUENCE (from log analysis + user description):
    1. Hook SelectLoadPlot so it returns immediately (prevents UI freeze)
    2. Teleport character to void → dies "accidentally" (outside map)
    3. Wait for CharacterAdded (respawn at default spawn)
    4. Fire SetPropertyPurchasingValue bypass + RequestLoad while respawning
    5. Server gives saved axes WITHOUT clearing backpack 
       (char just respawned, CurrentlySavingOrLoading guards the wipe)
    6. SelectLoadPlot fires → our hook returns nil → load finishes
    7. Plot selection UI briefly appears then closes
    8. Axes are doubled in backpack
    
    REQUIREMENTS:
    - At least 1 axe saved in your slot
    - Level 7+ executor
    
    CONFIG:
    - SLOT: your save slot (1-6)
    - AUTO_SAVE: save automatically after each cycle
    - CYCLES: how many times to double (each doubles axes count)
]]

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

local ClientMayLoad         = RS.LoadSaveRequests.ClientMayLoad
local RequestLoad           = RS.LoadSaveRequests.RequestLoad
local RequestSave           = RS.LoadSaveRequests.RequestSave
local SetPropertyPurchasing = RS.PropertyPurchasing.SetPropertyPurchasingValue
local SelectLoadPlot        = RS.PropertyPurchasing.SelectLoadPlot

local SLOT      = 1
local AUTO_SAVE = false
local CYCLES    = 1

local function log(msg)
    print("[AxeDupe v4] " .. tostring(msg))
end

local function countAxes()
    local n = 0
    for _, v in ipairs(lp.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("ToolName") then n += 1 end
    end
    local char = lp.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") then n += 1 end
        end
    end
    return n
end

local function dupeOnce()
    local before = countAxes()
    log("Axes before: " .. before)

    -- Step 1: Hook SelectLoadPlot BEFORE everything
    -- Server calls this on client mid-load expecting a plot selection
    -- We return nil, 0 immediately so it doesn't block and no UI pops up
    local origCallback = getcallbackvalue(SelectLoadPlot, "OnClientInvoke")
    SelectLoadPlot.OnClientInvoke = function(...)
        log("SelectLoadPlot intercepted — returning nil to skip plot selection")
        -- Restore original so future normal loads still work
        task.delay(0.5, function()
            SelectLoadPlot.OnClientInvoke = origCallback
        end)
        return nil, 0
    end

    -- Step 2: Verify load is allowed
    local mayLoad = ClientMayLoad:InvokeServer(lp)
    if not mayLoad then
        log("ERROR: ClientMayLoad denied")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    -- Step 3: Teleport character outside the map → "accidental" death
    local char = lp.Character
    if not char then
        log("ERROR: No character found")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        log("ERROR: No HumanoidRootPart")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    log("Sending character outside map...")
    -- Teleport far below the map — looks like a fall death to the server
    hrp.CFrame = CFrame.new(hrp.Position.X, -1000, hrp.Position.Z)

    -- Step 4: Wait for death and respawn
    log("Waiting for death...")
    local newChar = lp.CharacterAdded:Wait()
    newChar:WaitForChild("HumanoidRootPart")
    newChar:WaitForChild("Humanoid")
    log("Respawned! Firing load sequence...")

    -- Small wait to let respawn fully settle server-side
    task.wait(0.3)

    -- Step 5: SetPropertyPurchasingValue bypass then RequestLoad
    -- This runs while character just respawned — server skips backpack clear
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.1)
    SetPropertyPurchasing:InvokeServer(true)
    task.wait(0.1)
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.1)

    -- Fire RequestLoad in a separate thread so we don't block
    log("Firing RequestLoad on slot " .. SLOT .. "...")
    local done = false
    task.spawn(function()
        local ok, err = RequestLoad:InvokeServer(SLOT, lp)
        done = true
        log("RequestLoad result: " .. tostring(ok) .. " / " .. tostring(err))
    end)

    -- Wait for it to finish (SelectLoadPlot hook resolves it instantly)
    local t = 0
    while not done and t < 20 do
        task.wait(0.5)
        t += 0.5
    end

    if not done then
        log("WARNING: RequestLoad timed out")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    -- Let ConfirmIdentity calls finish initializing all axes
    task.wait(2)

    local after = countAxes()
    log("Axes after: " .. after)

    if after > before then
        log("SUCCESS! " .. before .. " → " .. after)
        return true
    else
        log("No change. Make sure your slot actually has axes saved in it.")
        return false
    end
end

-- Main
log("=== LT2 Axe Dupe v4 ===")
log("Slot: " .. SLOT .. " | AutoSave: " .. tostring(AUTO_SAVE) .. " | Cycles: " .. CYCLES)
task.wait(1)

for i = 1, CYCLES do
    log("--- Cycle " .. i .. "/" .. CYCLES .. " ---")
    local ok = dupeOnce()

    if ok and AUTO_SAVE then
        task.wait(1.5)
        log("Auto-saving to slot " .. SLOT .. "...")
        local saveOk, saveErr = RequestSave:InvokeServer(SLOT, lp)
        log(saveOk and "Save OK!" or "Save failed: " .. tostring(saveErr))
    end

    if i < CYCLES then
        task.wait(3)
    end
end

log("=== Done! Axe count: " .. countAxes() .. " ===")
if not AUTO_SAVE then
    log("Save manually before running again to chain dupes!")
end
