--[[
    LT2 Axe Dupe v2 - Property Purchasing Mode Bypass
    Reverse engineered from remote spy logs.

    HOW IT WORKS:
    Normally RequestLoad clears your inventory before restoring saved items.
    But if you briefly toggle SetPropertyPurchasingValue (true then false)
    right before calling RequestLoad, the server uses a different load path
    that does NOT clear your backpack first. You keep your current axes AND
    receive the saved ones — doubling your count each run.

    SETUP:
    - Have at least 1 axe in your backpack
    - Must already have a save in slot 1 (or change SLOT below)
    - Run in a level 7+ executor (Synapse X, Solara, etc.)

    USAGE:
    1. Run the script once → you get 2x axes
    2. Walk around / wait 2 seconds for axes to fully initialize
    3. Save your slot manually via in-game save menu
    4. Run again → 4x, then 8x, etc.
    
    Or set AUTO_SAVE = true to have it save automatically each cycle.
    Set CYCLES to run multiple rounds in one go (careful with anti-cheat).
]]

local RS  = game:GetService("ReplicatedStorage")
local lp  = game:GetService("Players").LocalPlayer

-- ── CONFIG ────────────────────────────────────────────────────────────────
local SLOT      = 1     -- save slot number (check GetMetaData output to confirm)
local CYCLES    = 1     -- how many dupe cycles to run (1 = safe, 3+ = risky)
local AUTO_SAVE = false -- auto-save after each cycle so next run doubles again
local DELAY     = 0.1   -- seconds between SetPropertyPurchasingValue calls
-- ─────────────────────────────────────────────────────────────────────────

local ClientMayLoad          = RS.LoadSaveRequests.ClientMayLoad
local GetMetaData            = RS.LoadSaveRequests.GetMetaData
local RequestLoad            = RS.LoadSaveRequests.RequestLoad
local RequestSave            = RS.LoadSaveRequests.RequestSave
local SetPropertyPurchasing  = RS.PropertyPurchasing.SetPropertyPurchasingValue

local function log(msg) print("[AxeDupe] " .. msg) end

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

local function getSlotWithSaves()
    local meta, err = GetMetaData:InvokeServer(lp)
    if not meta then
        log("GetMetaData failed: " .. tostring(err))
        return nil
    end
    -- Return configured slot if it has saves, otherwise find one
    if meta[SLOT] and meta[SLOT].NumSaves > 0 then
        log("Slot " .. SLOT .. " has " .. meta[SLOT].NumSaves .. " saves")
        return SLOT
    end
    for i, slotData in ipairs(meta) do
        if slotData.NumSaves > 0 then
            log("Using slot " .. i .. " (has " .. slotData.NumSaves .. " saves)")
            return i
        end
    end
    return nil
end

local function dupeOnce(slot)
    local before = countAxes()
    log("Axes before: " .. before)

    -- Step 1: Verify load is allowed
    local mayLoad = ClientMayLoad:InvokeServer(lp)
    if not mayLoad then
        log("ERROR: ClientMayLoad denied. Are you currently saving?")
        return false
    end

    -- Step 2: The property purchasing bypass
    -- Toggle false → true → false rapidly to change server-side load behavior
    task.wait(DELAY)
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(DELAY)
    SetPropertyPurchasing:InvokeServer(true)
    task.wait(DELAY)
    SetPropertyPurchasing:InvokeServer(false)
    task.wait(DELAY)

    -- Step 3: Load - server gives saved items WITHOUT clearing current backpack
    log("Firing RequestLoad on slot " .. slot .. "...")
    local ok, err2, _ = RequestLoad:InvokeServer(slot, lp)

    if not ok then
        log("RequestLoad failed: " .. tostring(err2))
        return false
    end

    -- Step 4: Wait for axes to initialize (ConfirmIdentity calls need time)
    task.wait(2)

    local after = countAxes()
    log("Axes after: " .. after)

    if after > before then
        log("SUCCESS: gained " .. (after - before) .. " axe(s)!")
        return true
    else
        log("No change detected - method may need adjustment or save doesn't have axes")
        return false
    end
end

local function saveSlot(slot)
    log("Auto-saving to slot " .. slot .. "...")
    local ok, err = RequestSave:InvokeServer(slot, lp)
    if ok then
        log("Save successful!")
    else
        log("Save failed: " .. tostring(err))
    end
    task.wait(1)
end

-- ── MAIN ─────────────────────────────────────────────────────────────────
log("=== LT2 Axe Dupe v2 Starting ===")

-- Find a valid slot
local slot = getSlotWithSaves()
if not slot then
    log("ERROR: No save slot with saves found. Save your game first!")
    return
end

local totalBefore = countAxes()
if totalBefore == 0 then
    log("WARNING: No axes in backpack. You need at least 1 axe to dupe!")
end

-- Run cycles
for i = 1, CYCLES do
    log("--- Cycle " .. i .. "/" .. CYCLES .. " ---")
    local success = dupeOnce(slot)
    
    if success and AUTO_SAVE then
        task.wait(1)
        saveSlot(slot)
    end

    if i < CYCLES then
        task.wait(2)
    end
end

local totalAfter = countAxes()
log("=== Done! Axes: " .. totalBefore .. " → " .. totalAfter .. " ===")
if totalAfter > totalBefore then
    log("Remember to save manually if AUTO_SAVE is off!")
end
