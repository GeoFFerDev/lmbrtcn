--[[
    LT2 Axe Dupe v7 - Fixed

    ══════════════════════════════════════════════════════
    THREE BUGS IN v6 EXPLAINED:
    ══════════════════════════════════════════════════════

    BUG 1 (CRITICAL) — SelectLoadPlot returned nil:
      The original game's SelectLoadPlot.OnClientInvoke runs enterPurchaseMode(),
      which spins in a loop: `while Health > 0 do ... end`
      When character dies from OOB void, Health = 0, loop exits immediately,
      v_u_24 (the property) is never set → returns nil.
      v6's hook ALSO returns nil, 0 — same result. Server gets no property,
      load is aborted or loaded to wrong place. Nothing happens.
      FIX: Return the actual property Instance from workspace.Properties.

    BUG 2 (CRITICAL) — RequestLoad wrong arg count:
      Server handler signature: RequestLoad(slot, player, versionMeta)
      v6 called:  RequestLoad:InvokeServer(SLOT, lp)      ← 2 args, server rejects
      FIX:        RequestLoad:InvokeServer(SLOT, lp, nil) ← 3 args

    BUG 3 — exitAll fires SetPropertyPurchasingValue(false):
      The game's PropertyPurchasingClient hooks Humanoid.Died → exitAll().
      exitAll() calls SetPropertyPurchasingValue:InvokeServer(false).
      When character dies from OOB, exitAll fires and signals the server to
      abort any active property purchase/load flow — before load completes.
      FIX: Spam SetPropertyPurchasingValue(true) in a loop after hook fires
           to override the false signal from exitAll.

    ══════════════════════════════════════════════════════
    HOW THE DUPE ACTUALLY WORKS:
    ══════════════════════════════════════════════════════

    When RequestLoad fires, the server:
      1. Auto-saves current state (your axes go into the save)
      2. Calls SelectLoadPlot.OnClientInvoke → we return our property
      3. Resets the character (kills it server-side)
      4. Loads the saved data at your property (gives axes back)

    The OOB death creates a RACE CONDITION:
    - You die from void BEFORE step 3 (server's kill)
    - When you die naturally: equipped tools go to Backpack (Roblox engine)
    - Server was going to clear Backpack as part of step 3, but character
      is already dead — server skips or races past the backpack clear
    - Step 4 then ADDS axes from save to Backpack (which still has original axes)
    - Result: original axes + loaded axes = doubled

    HOW AXES SURVIVE DEATH:
    - Tools in Backpack folder persist across death/respawn (Roblox engine behavior)
    - Tools EQUIPPED in character go TO Backpack automatically on death
    - So death never removes axes, it just moves equipped ones to Backpack
    - The server's load step adds more axes on top = duplication

    ══════════════════════════════════════════════════════
    SETUP REQUIREMENTS:
    ══════════════════════════════════════════════════════
    1. Load your land first (you MUST own a property — script checks this)
    2. Have your axe(s) in backpack (UNEQUIPPED — already there, not in hand)
    3. Make sure slot SLOT has a save with the same axe(s)
    4. Run script
]]

local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp      = Players.LocalPlayer

local ClientMayLoad         = RS.LoadSaveRequests.ClientMayLoad
local RequestLoad           = RS.LoadSaveRequests.RequestLoad
local SetPropertyPurchasing = RS.PropertyPurchasing.SetPropertyPurchasingValue
local SelectLoadPlot        = RS.PropertyPurchasing.SelectLoadPlot

local SLOT   = 1   -- slot number that has your save with axes
local CYCLES = 1   -- how many times to dupe

-- OOB position: just outside map edge at normal height
-- Player falls naturally ~200 studs to void kill zone (Y < -100)
-- Fall takes ~1.4 seconds — enough time for RequestLoad to reach server
-- but fast enough to create the race condition before server resets character
local OOB_POS = CFrame.new(0, 100, 9999)

local function log(msg)
    print("[AxeDupe v7] " .. tostring(msg))
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

-- Returns the property Model owned by this player from workspace.Properties
-- This is what SelectLoadPlot.OnClientInvoke must return (not a CFrame, not nil)
local function getMyProperty()
    for _, p in ipairs(workspace.Properties:GetChildren()) do
        if p:FindFirstChild("Owner") and p.Owner.Value == lp then
            return p
        end
    end
    return nil
end

local function dupeOnce()
    local before = countAxes()
    log("Axes before: " .. before)

    -- ── VALIDATE ─────────────────────────────────────────────────────────────
    local prop = getMyProperty()
    if not prop then
        log("ERROR: You must load your land first! No property found owned by you.")
        return false
    end
    log("Property found: " .. prop:GetFullName())

    local char = lp.Character
    if not char then log("ERROR: No character") return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then log("ERROR: No HumanoidRootPart") return false end

    local hum = char:FindFirstChild("Humanoid")
    if not hum then log("ERROR: No Humanoid") return false end

    -- Unequip any equipped axe so it goes to Backpack
    -- Axes in Backpack survive OOB death automatically (Roblox engine keeps Backpack)
    -- Equipped axes also go to Backpack on death — but unequipping first is cleaner
    hum:UnequipTools()
    task.wait(0.2)

    -- ── HOOK SelectLoadPlot ──────────────────────────────────────────────────
    -- This MUST fire before RequestLoad, because the server calls it
    -- almost immediately after receiving RequestLoad.
    --
    -- FIX 1: Return the actual property INSTANCE (not nil, not CFrame)
    --        The server uses this to know which plot to load your save onto.
    --        Returning nil = server aborts load silently.
    --
    -- FIX 3: Spawn a loop to counter exitAll's SetPropertyPurchasingValue(false)
    --        When character dies, exitAll() fires and sends false to server,
    --        signaling "player cancelled". We override this by sending true.
    local hookFired = false
    local originalHook = SelectLoadPlot.OnClientInvoke

    SelectLoadPlot.OnClientInvoke = function(modelFromServer)
        if hookFired then
            -- If called again (shouldn't happen, but just in case)
            return prop, 0
        end
        hookFired = true
        log("SelectLoadPlot intercepted → returning property: " .. prop.Name)

        -- FIX 3: Counter exitAll's false signal
        -- exitAll fires when character dies (Humanoid.Died connection in game's code)
        -- It sends SetPropertyPurchasingValue(false) which can abort the load
        -- We spam (true) to override it for the duration of the load
        task.spawn(function()
            for i = 1, 12 do
                pcall(function()
                    SetPropertyPurchasing:InvokeServer(true)
                end)
                task.wait(0.4)
            end
        end)

        -- FIX 1: Return property Instance + rotation index 0
        -- DO NOT return nil, DO NOT return prop.OriginSquare.CFrame
        -- The server expects: (propertyModel, rotationIndex)
        return prop, 0
    end

    -- Restore hook after load completes (whether successful or not)
    task.delay(30, function()
        if SelectLoadPlot.OnClientInvoke ~= originalHook then
            SelectLoadPlot.OnClientInvoke = originalHook
        end
    end)

    -- ── FIRE RequestLoad + OOB TELEPORT simultaneously ────────────────────────
    -- Both happen in the same frame burst (no task.wait between them)
    --
    -- RequestLoad is non-blocking here (runs in task.spawn):
    --   - Server receives it, begins auto-save + reset flow
    --   - Server calls SelectLoadPlot → our hook fires, returns property
    --   - Server loads save data at property
    --
    -- OOB teleport:
    --   - Character falls from Y=100 toward void kill zone
    --   - Natural death occurs after ~1.4 seconds
    --   - This is BEFORE the server's own character reset in the load flow
    --   - Server's reset finds character already dead → skips/races backpack clear
    --   - Load then adds axes to Backpack that already has original axes = doubled

    local loadDone   = false
    local loadResult = nil

    -- FIX 2: Must pass 3 args — (slot, player, versionMeta)
    -- v6 only passed 2: RequestLoad:InvokeServer(SLOT, lp)
    -- Server silently rejects wrong arg count
    task.spawn(function()
        log("Firing RequestLoad(slot=" .. SLOT .. ", player, nil)...")
        local ok, err = RequestLoad:InvokeServer(SLOT, lp, nil)
        loadResult = { ok = ok, err = err }
        loadDone = true
        log("RequestLoad returned: ok=" .. tostring(ok) .. " err=" .. tostring(err))
    end)

    -- Teleport OOB immediately in the same burst as RequestLoad
    -- Character is at Y=100, falls to void, dies naturally after ~1.4s
    log("Teleporting to OOB for natural fall death...")
    hrp.CFrame = OOB_POS

    -- ── WAIT FOR NATURAL DEATH THEN RESPAWN ──────────────────────────────────
    log("Waiting for character death and respawn...")

    -- Wait for current character to die (void kill)
    local died = false
    local diedConn
    diedConn = hum.Died:Connect(function()
        died = true
        log("Character died from OOB void (natural death ✓)")
        if diedConn then diedConn:Disconnect() end
    end)

    -- Timeout: if character doesn't die in 10s, something went wrong
    local t = 0
    while not died and t < 10 do
        task.wait(0.1)
        t += 0.1
    end
    if not died then
        log("WARNING: Character didn't die in 10s. OOB_POS may not be past void boundary.")
        log("Try: OOB_POS = CFrame.new(0, 100, 5000) or CFrame.new(9999, 100, 0)")
    end

    -- Wait for NEW character to spawn (Roblox auto-spawns after death)
    log("Waiting for new character...")
    local newChar = lp.CharacterAdded:Wait(20)
    if not newChar then
        log("ERROR: Character never respawned. Server may have kicked you.")
        return false
    end
    newChar:WaitForChild("HumanoidRootPart", 10)
    newChar:WaitForChild("Humanoid", 10)
    log("Respawned!")

    -- ── WAIT FOR RequestLoad TO FINISH ────────────────────────────────────────
    -- The server still needs time to complete the load after character reset
    t = 0
    while not loadDone and t < 25 do
        task.wait(0.5)
        t += 0.5
    end
    if not loadDone then
        log("WARNING: RequestLoad didn't return after 25s. Hook may not have fired.")
    end

    -- Wait for axes to be given to player by server
    task.wait(3)

    -- Restore original hook now that load is done
    SelectLoadPlot.OnClientInvoke = originalHook

    local after = countAxes()
    log("Axes after: " .. after)

    if after > before then
        log("SUCCESS! " .. before .. " → " .. after .. " axes! (+" .. (after - before) .. ")")
        return true
    elseif after == before then
        log("No change. Possible causes:")
        log("  1. Slot " .. SLOT .. " had no save / same number of axes")
        log("  2. OOB death was too slow (server reset backpack before void kill)")
        log("  3. Server rejected load — check if land is loaded")
        return false
    else
        log("Lost axes? That's unexpected. Axes: " .. after)
        return false
    end
end

-- ── MAIN ─────────────────────────────────────────────────────────────────────
log("=== LT2 Axe Dupe v7 (Fixed) ===")
log("Slot: " .. SLOT .. " | OOB: " .. tostring(OOB_POS.Position))
log("Axes at start: " .. countAxes())
task.wait(1)

for i = 1, CYCLES do
    log("--- Cycle " .. i .. "/" .. CYCLES .. " ---")
    local ok = dupeOnce()

    if i < CYCLES then
        if ok then
            log("Waiting 6s before next cycle...")
            task.wait(6)
        else
            log("Last cycle failed, stopping.")
            break
        end
    end
end

log("=== Done! Final count: " .. countAxes() .. " ===")
