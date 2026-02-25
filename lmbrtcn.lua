--[[
    LT2 Axe Dupe - ClientInteracted Race Condition Fuzzer
    
    WHAT THIS TESTS:
    The server handles two separate events on the same remote (ClientInteracted):
      - FireServer(tool, "Drop tool", handle.CFrame)  → server moves tool to workspace
      - FireServer(toolModel, "Pick up tool")          → server moves tool to backpack

    If the server processes these asynchronously (task.spawn / spawn internally),
    there may be a window where both succeed on the same tool instance,
    resulting in the tool existing in both backpack AND workspace.

    HOW TO USE:
    1. Have an axe equipped or in your backpack
    2. Run this in your executor
    3. Watch the output log and your backpack
    4. Try different DELAY values (0, 0.05, 0.1, 0.15) - the sweet spot varies

    WHAT TO LOOK FOR:
    - "DUPE POSSIBLE" in output = server returned success on both calls
    - Two copies of your axe (one in backpack, one in workspace)
    - Axe in backpack with no physical model dropped = silent dupe
]]

local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local lp            = Players.LocalPlayer
local char          = lp.Character or lp.CharacterAdded:Wait()

-- The single remote used for all item interactions
local ClientInteracted = RS.Interaction.ClientInteracted

-- ─── CONFIG ────────────────────────────────────────────────────────────────
local DELAY_BETWEEN_CALLS = 0      -- seconds between Drop and Pickup fire (try 0, 0.05, 0.1)
local ATTEMPTS            = 5      -- how many rapid attempts per run
local LOG_ALL             = true   -- print every server response
-- ───────────────────────────────────────────────────────────────────────────

local function log(msg)
    print("[LT2Fuzz] " .. tostring(msg))
end

-- Find axe in backpack or equipped
local function findAxe()
    for _, v in ipairs(lp.Backpack:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("ToolName") and v:FindFirstChild("Handle") then
            return v, false
        end
    end
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("ToolName") and v:FindFirstChild("Handle") then
                return v, true
            end
        end
    end
    return nil, nil
end

-- Count axes across backpack + workspace
local function countAxes(axeName)
    local count = 0
    local locations = {}

    -- Check backpack
    for _, v in ipairs(lp.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name == axeName then
            count += 1
            table.insert(locations, "Backpack")
        end
    end
    -- Check character (equipped)
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") and v.Name == axeName then
                count += 1
                table.insert(locations, "Character(equipped)")
            end
        end
    end
    -- Check workspace (dropped)
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v.Name == axeName and v:FindFirstChild("ToolName") then
            count += 1
            table.insert(locations, "Workspace")
        end
    end
    -- Check PlayerModels (LT2 sometimes parents dropped tools here)
    local pm = workspace:FindFirstChild("PlayerModels")
    if pm then
        for _, v in ipairs(pm:GetChildren()) do
            if v:IsA("Model") and v.Name == axeName and v:FindFirstChild("ToolName") then
                count += 1
                table.insert(locations, "PlayerModels")
            end
        end
    end

    return count, table.concat(locations, ", ")
end

-- Find a dropped instance of the axe in workspace to feed to "Pick up tool"
local function findDroppedAxe(axeName)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == axeName and v:FindFirstChild("ToolName") then
            return v
        end
    end
    return nil
end

-- ─── CORE FUZZ FUNCTION ──────────────────────────────────────────────────
local function fuzzAttempt(attemptNum)
    local axe, isEquipped = findAxe()
    if not axe then
        log("Attempt " .. attemptNum .. ": No axe found, skipping")
        return false
    end

    -- Unequip first if needed so it's a clean Tool in backpack
    if isEquipped then
        char.Humanoid:UnequipTools()
        task.wait(0.1)
        axe, isEquipped = findAxe()
        if not axe then
            log("Attempt " .. attemptNum .. ": Axe vanished after unequip")
            return false
        end
    end

    local axeName   = axe.Name
    local dropCF    = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -6) -- drop in front
    local beforeCount, beforeLocs = countAxes(axeName)
    log(string.format("Attempt %d | Before: %d axe(s) at [%s]", attemptNum, beforeCount, beforeLocs))

    -- ── PHASE 1: Fire DROP ───────────────────────────────────────────────
    -- Signature from ObjectInteractionClient:
    --   ClientInteracted:FireServer(tool, "Drop tool", handle.CFrame)
    log("Attempt " .. attemptNum .. ": Firing DROP...")
    ClientInteracted:FireServer(axe, "Drop tool", dropCF)

    -- ── PHASE 2: Fire PICKUP with configurable delay ─────────────────────
    -- We need a workspace model to feed as the pickup target.
    -- Strategy A: use the same tool reference (may still be valid pre-server-move)
    -- Strategy B: wait briefly for server to move it, then pick up the workspace copy
    if DELAY_BETWEEN_CALLS > 0 then
        task.wait(DELAY_BETWEEN_CALLS)
    end

    -- Try to find the dropped workspace model (for strategy B)
    local droppedModel = findDroppedAxe(axeName)

    -- Fire PICKUP on the workspace model (if found) AND on the original tool ref
    -- We fire both to maximize the chance of hitting the race window
    if droppedModel then
        log("Attempt " .. attemptNum .. ": Firing PICKUP on workspace model...")
        ClientInteracted:FireServer(droppedModel, "Pick up tool")
    end

    -- Also fire on original ref (in case server hasn't moved it yet)
    log("Attempt " .. attemptNum .. ": Firing PICKUP on original tool ref...")
    ClientInteracted:FireServer(axe, "Pick up tool")

    task.wait(0.3) -- let server respond

    -- ── CHECK RESULT ──────────────────────────────────────────────────────
    local afterCount, afterLocs = countAxes(axeName)
    log(string.format("Attempt %d | After:  %d axe(s) at [%s]", attemptNum, afterCount, afterLocs))

    if afterCount > beforeCount then
        log("!!!!! DUPE POSSIBLE - axe count increased from " .. beforeCount .. " to " .. afterCount .. " !!!!!")
        return true
    elseif afterCount == beforeCount and afterLocs:find("Backpack") then
        log("Attempt " .. attemptNum .. ": Count same, axe returned to backpack (race failed or timing off)")
    else
        log("Attempt " .. attemptNum .. ": Axe dropped and not recovered - adjust delay and retry")
    end

    return false
end

-- ─── MAIN LOOP ───────────────────────────────────────────────────────────
log("=== LT2 Dupe Fuzzer Starting ===")
log(string.format("Delay=%s | Attempts=%d", DELAY_BETWEEN_CALLS, ATTEMPTS))
log("Watching for dupe window on ClientInteracted remote...")
task.wait(1)

local success = false
for i = 1, ATTEMPTS do
    if fuzzAttempt(i) then
        success = true
        log("=== SUCCESS on attempt " .. i .. " ===")
        log("Check your backpack AND workspace for duplicate axes!")
        break
    end
    task.wait(0.5)
end

if not success then
    log("=== No dupe detected across " .. ATTEMPTS .. " attempts ===")
    log("Try adjusting DELAY_BETWEEN_CALLS:")
    log("  0     = pure simultaneous (best for async handlers)")
    log("  0.05  = 50ms gap")
    log("  0.1   = 100ms gap (best for queued/sequential handlers)")
    log("  0.15+ = probably too late, server already committed drop")
    log("")
    log("Also try running while someone else is chopping nearby")
    log("(server load increases the async window)")
end
