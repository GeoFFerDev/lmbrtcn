--[[
    LT2 Axe Dupe v6 - Natural Out-of-Bounds Death
    
    THE CORRECT MECHANISM:
    - Teleport player to coordinates OUTSIDE the map boundary at normal height
    - Player stands in air, falls naturally, hits LT2's void kill zone (~Y < -100)
    - This is a NATURAL death the server treats differently from a script kill
    - RequestLoad fires while player is mid-fall (in-flight on server)
    - Server sees: CurrentlySavingOrLoading=true + natural death = skip backpack wipe
    - Axes from load survive into respawn
    - Player respawns at DEFAULT spawn (not plot) with doubled axes
    
    WHY PREVIOUS VERSIONS FAILED:
    - v3/v4/v5 used hrp.CFrame = Y:-1000/-5000 = instant void = server sees scripted kill
    - Natural fall death from out-of-bounds is what the server allows through
    
    SETUP:
    - Have axe saved in slot SLOT
    - Level 7+ executor
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

-- Out-of-bounds coordinates just past the map edge at normal height
-- Player will stand here in air, fall naturally, die from void boundary
-- LT2 map ends around X/Z ±2000; void kills at ~Y < -100
local OOB_POS = CFrame.new(0, 100, 9999)

local function log(msg)
    print("[AxeDupe v6] " .. tostring(msg))
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

local function dupeOnce()
    local before = countAxes()
    log("Axes before: " .. before)

    -- Step 1: Hook SelectLoadPlot so it doesn't stall
    -- Server calls this expecting plot selection; we return nil immediately
    local origCB = getcallbackvalue(SelectLoadPlot, "OnClientInvoke")
    SelectLoadPlot.OnClientInvoke = function(...)
        log("SelectLoadPlot intercepted, returning nil")
        task.delay(2, function()
            SelectLoadPlot.OnClientInvoke = origCB
        end)
        return nil, 0
    end

    -- Step 2: Check load is allowed
    local mayLoad = ClientMayLoad:InvokeServer(lp)
    if not mayLoad then
        log("ERROR: ClientMayLoad denied")
        SelectLoadPlot.OnClientInvoke = origCB
        return false
    end

    local char = lp.Character
    if not char then
        log("ERROR: No character")
        SelectLoadPlot.OnClientInvoke = origCB
        return false
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        log("ERROR: No HumanoidRootPart")
        SelectLoadPlot.OnClientInvoke = origCB
        return false
    end

    -- Step 3: SetPropertyPurchasingValue bypass
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.1)
    SetPropertyPurchasing:InvokeServer(true)
    task.wait(0.1)
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.05)

    -- Step 4: Fire RequestLoad in background thread (non-blocking)
    local loadDone = false
    task.spawn(function()
        local ok, err = RequestLoad:InvokeServer(SLOT, lp)
        loadDone = true
        log("RequestLoad result: " .. tostring(ok) .. " / " .. tostring(err))
    end)

    -- Step 5: Immediately teleport to out-of-bounds - natural fall death
    -- No delay from RequestLoad spawn - same burst
    -- Player lands just outside map edge at Y=100, falls naturally ~2-3 seconds
    -- hits void kill zone, dies "naturally" while load is in-flight
    log("Teleporting to out-of-bounds for natural fall death...")
    hrp.CFrame = OOB_POS

    -- Step 6: Wait for CharacterAdded (natural respawn at DEFAULT spawn)
    log("Waiting for natural death and respawn...")
    local newChar = lp.CharacterAdded:Wait()
    newChar:WaitForChild("HumanoidRootPart")
    newChar:WaitForChild("Humanoid")
    log("Respawned at default spawn!")

    -- Step 7: Wait for RequestLoad to finish + axes to initialize
    local t = 0
    while not loadDone and t < 20 do
        task.wait(0.5)
        t += 0.5
    end
    task.wait(2.5) -- ConfirmIdentity calls need time

    local after = countAxes()
    log("Axes after: " .. after)

    if after > before then
        log("SUCCESS! " .. before .. " → " .. after .. " axes!")
        return true
    else
        log("No change detected.")
        log("Try adjusting OOB_POS - change Z from 9999 to 5000 or try X=9999")
        log("Or try removing the SetPropertyPurchasing bypass entirely")
        return false
    end
end

-- Main
log("=== LT2 Axe Dupe v6 ===")
log("Slot: " .. SLOT .. " | OOB: " .. tostring(OOB_POS.Position))
task.wait(1)

for i = 1, CYCLES do
    log("--- Cycle " .. i .. "/" .. CYCLES .. " ---")
    local ok = dupeOnce()

    if ok and AUTO_SAVE then
        task.wait(2)
        log("Auto-saving...")
        local saveOk = RequestSave:InvokeServer(SLOT, lp)
        log(saveOk and "Saved!" or "Save failed")
    end

    if i < CYCLES then task.wait(5) end
end

log("=== Done! Final count: " .. countAxes() .. " ===")
