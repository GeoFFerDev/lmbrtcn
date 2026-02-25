--[[
    LT2 Axe Dupe v5 - Correct Timing
    
    THE ACTUAL MECHANISM (finally correct):
    
    RequestLoad does NOT block on SelectLoadPlot — they run concurrently.
    The character must die WHILE RequestLoad is in-flight (server processing).
    Server detects death, sees CurrentlySavingOrLoading = true → skips backpack
    clear. Axes from the load survive into the respawn.
    
    CORRECT ORDER:
    1. Hook SelectLoadPlot so it returns immediately (no UI freeze)
    2. SetPropertyPurchasingValue bypass  
    3. task.spawn(RequestLoad) — fire and DON'T wait, runs in background
    4. Immediately teleport to void in same burst — char dies with load in-flight
    5. Server skips backpack wipe on death (CurrentlySavingOrLoading = true)
    6. Server gives saved axes (ConfirmIdentity x8)
    7. Character respawns with doubled axes
    8. SelectLoadPlot fires post-respawn, hook handles it
    
    WRONG (what v3/v4 did):
    - Killed char FIRST, waited for full respawn, THEN fired RequestLoad (too late)
    
    REQUIREMENTS:
    - At least 1 axe saved in your slot
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

local function log(msg)
    print("[AxeDupe v5] " .. tostring(msg))
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

    -- Step 1: Hook SelectLoadPlot FIRST
    -- Server calls this on the client mid-load expecting plot selection
    -- We return immediately so it doesn't stall
    local origCallback = getcallbackvalue(SelectLoadPlot, "OnClientInvoke")
    SelectLoadPlot.OnClientInvoke = function(...)
        log("SelectLoadPlot intercepted — returning nil")
        task.delay(1, function()
            SelectLoadPlot.OnClientInvoke = origCallback
        end)
        return nil, 0
    end

    -- Step 2: Check if load is allowed
    local mayLoad = ClientMayLoad:InvokeServer(lp)
    if not mayLoad then
        log("ERROR: ClientMayLoad denied")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    local char = lp.Character
    if not char then
        log("ERROR: No character")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        log("ERROR: No HumanoidRootPart")
        SelectLoadPlot.OnClientInvoke = origCallback
        return false
    end

    -- Step 3: SetPropertyPurchasingValue bypass
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.1)
    SetPropertyPurchasing:InvokeServer(true)
    task.wait(0.1)
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.05)

    -- Step 4: Fire RequestLoad in background AND teleport to void in same burst
    -- These must happen together — char dies WHILE load is in-flight on server
    log("Firing RequestLoad + void teleport simultaneously...")

    local loadDone = false
    task.spawn(function()
        -- RequestLoad runs concurrently, does NOT block main thread
        local ok, err = RequestLoad:InvokeServer(SLOT, lp)
        loadDone = true
        log("RequestLoad result: " .. tostring(ok) .. " / " .. tostring(err))
    end)

    -- Teleport to void immediately after spawning RequestLoad
    -- No wait — same burst so char dies while server is processing load
    hrp.CFrame = CFrame.new(hrp.Position.X, -5000, hrp.Position.Z)

    -- Step 5: Wait for respawn
    log("Waiting for CharacterAdded...")
    local newChar = lp.CharacterAdded:Wait()
    newChar:WaitForChild("HumanoidRootPart")
    newChar:WaitForChild("Humanoid")
    log("Respawned!")

    -- Step 6: Wait for RequestLoad to finish and axes to initialize
    local t = 0
    while not loadDone and t < 15 do
        task.wait(0.5)
        t += 0.5
    end

    -- Give ConfirmIdentity calls time to fully initialize axes
    task.wait(2.5)

    local after = countAxes()
    log("Axes after: " .. after)

    if after > before then
        log("SUCCESS! " .. before .. " → " .. after .. " axes!")
        return true
    else
        log("No change. Try adjusting the wait between SetPropertyPurchasing and the spawn.")
        return false
    end
end

-- Main
log("=== LT2 Axe Dupe v5 ===")
log("Slot: " .. SLOT .. " | AutoSave: " .. tostring(AUTO_SAVE) .. " | Cycles: " .. CYCLES)
task.wait(1)

for i = 1, CYCLES do
    log("--- Cycle " .. i .. "/" .. CYCLES .. " ---")
    local ok = dupeOnce()

    if ok and AUTO_SAVE then
        task.wait(2)
        log("Auto-saving to slot " .. SLOT .. "...")
        local saveOk, saveErr = RequestSave:InvokeServer(SLOT, lp)
        log(saveOk and "Save OK!" or "Save failed: " .. tostring(saveErr))
    end

    if i < CYCLES then
        task.wait(5)
    end
end

log("=== Done! Final axe count: " .. countAxes() .. " ===")
if not AUTO_SAVE then
    log("Save manually before running again to chain!")
end
