--[[
    LT2 Axe Dupe v3 - Correct Mechanism
    Based on remote spy log analysis.

    HOW IT ACTUALLY WORKS:
    1. SetPropertyPurchasingValue bypass tells the server to ADD axes on top
       of your existing backpack instead of clearing it first
    2. RequestLoad fires → server gives all saved axes (ConfirmIdentity fires
       for each one) then calls SelectLoadPlot.OnClientInvoke on the client
    3. SelectLoadPlot puts the game in property placement mode (camera scriptable,
       character frozen waiting for plot selection)
    4. We kill the character WHILE CurrentlySavingOrLoading is still true on
       the server — this is key, the server skips the normal backpack clear
       on death because a load is in progress
    5. Character respawns at default spawn with ALL axes intact (doubled)
    6. Plot selection UI appears and then closes itself

    REQUIREMENTS:
    - At least 1 axe in backpack
    - A save in SLOT that contains at least 1 axe
    - Level 7+ executor (Synapse X, Solara, etc.)

    USAGE:
    - Set SLOT to whichever slot your save is in (default 1)
    - Run script
    - Wait ~10 seconds for full cycle
    - After first run: save manually, then run again to double again
    - Or set AUTO_SAVE = true
]]

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

-- Remotes
local ClientMayLoad         = RS.LoadSaveRequests.ClientMayLoad
local RequestLoad           = RS.LoadSaveRequests.RequestLoad
local RequestSave           = RS.LoadSaveRequests.RequestSave
local SetPropertyPurchasing = RS.PropertyPurchasing.SetPropertyPurchasingValue
local SelectLoadPlot        = RS.PropertyPurchasing.SelectLoadPlot

-- Config
local SLOT      = 1     -- your save slot number
local AUTO_SAVE = false -- auto-save after dupe so you can chain runs
local CYCLES    = 1     -- number of dupe cycles (each doubles axes)

local function log(msg)
    print("[AxeDupe v3] " .. tostring(msg))
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

local function killChar()
    local char = lp.Character
    if not char then return end
    -- Teleport into the void — same as what the working script does
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(0, -500, 0)
    end
    -- Also zero health as backup
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    end
end

local function waitForRespawn()
    local newChar = lp.CharacterAdded:Wait()
    -- Wait for humanoid to be fully loaded
    newChar:WaitForChild("Humanoid")
    newChar:WaitForChild("HumanoidRootPart")
    task.wait(1.5)
    return newChar
end

local function dupeOnce()
    local before = countAxes()
    log("Axes before: " .. before)

    -- Step 1: Check server is OK to load
    local mayLoad = ClientMayLoad:InvokeServer(lp)
    if not mayLoad then
        log("ERROR: ClientMayLoad denied. Wait a moment and retry.")
        return false
    end

    -- Step 2: Hook SelectLoadPlot BEFORE firing RequestLoad
    -- The server will call this on us mid-load — we intercept it,
    -- kill the character (while CurrentlySavingOrLoading=true so backpack
    -- is preserved), wait for respawn, then return to let the server finish.
    local originalCallback = getcallbackvalue(SelectLoadPlot, "OnClientInvoke")

    SelectLoadPlot.OnClientInvoke = function(structureModel)
        log("SelectLoadPlot fired — axes should now be in backpack. Killing character...")

        -- Kill the character while load is still in progress
        -- Server won't clear backpack because CurrentlySavingOrLoading is true
        task.spawn(killChar)

        -- Wait for respawn at default spawn
        log("Waiting for respawn...")
        waitForRespawn()
        log("Respawned! Axes should be doubled.")

        -- Restore original callback so subsequent runs work correctly
        SelectLoadPlot.OnClientInvoke = originalCallback

        -- Return nil plot (no land placed — that's fine, we just want the axes)
        return nil, 0
    end

    -- Step 3: SetPropertyPurchasingValue bypass
    -- false → true → false tells server to add axes on top rather than clear
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.15)
    SetPropertyPurchasing:InvokeServer(true)
    task.wait(0.15)
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(0.15)

    -- Step 4: Fire RequestLoad in a separate thread
    -- It will block until SelectLoadPlot resolves (which we handle above)
    log("Firing RequestLoad on slot " .. SLOT .. "...")
    local loadDone = false
    task.spawn(function()
        local ok, err = RequestLoad:InvokeServer(SLOT, lp)
        loadDone = true
        if ok then
            log("RequestLoad returned: success")
        else
            log("RequestLoad returned: " .. tostring(err))
        end
    end)

    -- Step 5: Wait for the full cycle to complete
    -- (SelectLoadPlot will handle the kill + respawn internally)
    local timeout = 30
    local elapsed = 0
    while not loadDone and elapsed < timeout do
        task.wait(0.5)
        elapsed += 0.5
    end

    if not loadDone then
        log("WARNING: RequestLoad timed out. SelectLoadPlot may not have fired.")
        -- Restore callback in case something went wrong
        SelectLoadPlot.OnClientInvoke = originalCallback
        return false
    end

    task.wait(2) -- let ConfirmIdentity calls finish initializing axes

    local after = countAxes()
    log("Axes after: " .. after)

    if after > before then
        log("SUCCESS: " .. before .. " → " .. after .. " axes!")
        return true
    else
        log("No increase detected. Check: does your save actually have axes in it?")
        return false
    end
end

-- Main
log("=== LT2 Axe Dupe v3 ===")
log("Slot: " .. SLOT .. " | Cycles: " .. CYCLES .. " | AutoSave: " .. tostring(AUTO_SAVE))
task.wait(1)

for i = 1, CYCLES do
    log("--- Cycle " .. i .. " / " .. CYCLES .. " ---")
    local ok = dupeOnce()

    if ok and AUTO_SAVE then
        task.wait(2)
        log("Auto-saving...")
        local saveOk, saveErr = RequestSave:InvokeServer(SLOT, lp)
        if saveOk then
            log("Saved successfully!")
        else
            log("Save failed: " .. tostring(saveErr))
        end
    end

    if i < CYCLES then
        task.wait(3)
    end
end

local final = countAxes()
log("=== Done! Final axe count: " .. final .. " ===")
if not AUTO_SAVE then
    log("Save your game manually before running again to chain dupes!")
end
