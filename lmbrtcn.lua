--[[
═══════════════════════════════════════════════════════════════
  DUPE AXE — BUG ANALYSIS & FIXED LOGIC
  For: Lumber Tycoon 2 exploit script (delta_lt2_v7)
═══════════════════════════════════════════════════════════════

HOW THE DUPE IS SUPPOSED TO WORK (the real exploit):
  The server's "RequestLoad" flow works like this:
    1. Server auto-saves your current inventory (axes included)
    2. Server kicks you off your land (character sent to spawn)
    3. Server fires SelectLoadPlot → client confirms plot placement
    4. Server reloads your save → axes are re-given from save
    RESULT: axes that were in inventory at step 1 STAY in your
    backpack through respawn, AND get re-given from the save = doubled.

═══════════════════════════════════════════════════════════════
  ROOT CAUSE OF THE BUG — Why it's NOT duping:
═══════════════════════════════════════════════════════════════

BUG #1 — ORDER OF OPERATIONS (the main killer):
  The current code does:
    1. Sets up SelectLoadPlot hook  ✅
    2. Teleports char to void       ✅
    3. BreakJoints (force death)    ✅
    4. THEN fires RequestLoad       ❌ TOO LATE

  When BreakJoints() is called, Roblox resets the character immediately.
  Character reset CLEARS the backpack — axes are GONE before RequestLoad
  even runs. So the server saves an EMPTY inventory in step 1 of its flow.
  Loading that empty save just gives you 0 axes. Nothing doubles.

BUG #2 — BreakJoints is the wrong kill method:
  BreakJoints causes instant local death but the server sees it differently.
  The character respawn from BreakJoints wipes the backpack client-side
  before the server has even processed RequestLoad. The desync window is
  basically zero.

BUG #3 — The hook fires SetPropertyPurchValue BEFORE returning:
  The current hook does:
    SetPropertyPurchValue:InvokeServer(true)  ← blocks until server responds
    task.spawn(...)                           ← then async TP logic
    return plotCF, 0
  
  The InvokeServer inside the hook is correct but the timing can cause
  the hook to hang if the server doesn't respond immediately, which can
  cause SelectLoadPlot to timeout and the load to fail.

BUG #4 — plotCF is snapshotted BEFORE RequestLoad resets the land:
  This is actually fine, but the TP after is 1.5s flat. If the server
  takes longer to load the land the TP lands on empty air and the char
  falls, potentially dying again and breaking the dupe state.

═══════════════════════════════════════════════════════════════
  THE CORRECT ORDER FOR THE EXPLOIT TO WORK:
═══════════════════════════════════════════════════════════════

  1. Verify cooldown (ClientMayLoad)
  2. Call GetMetaData (primes the server)
  3. Fire RequestLoad — server begins save+reload sequence
     At this moment axes are in inventory → server saves them ✅
  4. Server fires SelectLoadPlot mid-flow → our hook auto-confirms
  5. Character is eventually reset by the SERVER (not by us killing it)
     Because the server does the kick, backpack clear happens server-side
     after the save is already done → axes survive in the pending save
  6. Server reloads save → axes re-added
  7. We TP character to base after land loads
  RESULT: axes doubled ✅

  KEY INSIGHT: We must NOT manually kill the character before RequestLoad.
  The server kills the character itself as part of the load sequence.
  We just need to fire RequestLoad and handle the hook.

  The "teleport to void" step is what OTHER scripts do to trigger the
  server-side reset in a specific way — but the kill must come AFTER
  RequestLoad is already being processed, not before.
]]

-- ═══════════════════════════════════════════════════════
--  FIXED DUPE AXE FUNCTION
--  Drop this in to replace the existing dupeAxe function
-- ═══════════════════════════════════════════════════════

local dupeRunning = false
local dupeSlots   = { save = 1, load = 1 }

local function dupeAxe()
    if dupeRunning then
        dupeRunning = false
        return notify('Dupe cancelled.')
    end

    local loadSlot = dupeSlots.load

    -- Need land loaded so we know where to TP back to after the dupe
    local prop = getMyProp()
    if not prop or not prop:FindFirstChild('OriginSquare') then
        return notify('Load your land first!')
    end
    local plotCF = prop.OriginSquare.CFrame

    -- Need at least one axe in inventory, otherwise nothing to dupe
    if #getAxes() == 0 then
        return notify('No axes in inventory to dupe!')
    end

    dupeRunning = true
    notify('Checking cooldown...')

    -- Step 1: Check if we're allowed to load right now
    local canLoad = ClientMayLoad:InvokeServer(Player)
    if canLoad ~= true then
        dupeRunning = false
        return notify('❌ Cooldown active. Wait ~60s and try again.')
    end

    -- Step 2: Prime the server metadata
    GetMetaData:InvokeServer(Player)
    notify('Starting dupe sequence...')

    -- Step 3: Install the SelectLoadPlot hook BEFORE firing RequestLoad
    -- The server fires this remote mid-way through the load sequence.
    -- We auto-confirm the land placement so it doesn't wait on user input.
    local origHook = SelectLoadPlot.OnClientInvoke
    SelectLoadPlot.OnClientInvoke = function(_model)
        -- Restore hook immediately so future normal loads work
        SelectLoadPlot.OnClientInvoke = origHook

        -- Confirm the property purchase on the server side
        -- (tells the server "yes place the land here")
        pcall(function()
            SetPropertyPurchValue:InvokeServer(true)
        end)

        -- After the server finishes loading the land, TP the character back.
        -- We wait for CharacterAdded because the server resets us as part of
        -- the load — we WANT that reset, we don't cause it ourselves.
        task.spawn(function()
            -- Wait for the character the server respawns us as
            local newChar = Player.CharacterAdded:Wait(10)
            if not newChar then
                -- Fallback: just wait a fixed time
                task.wait(3)
                newChar = char()
            end

            -- Give the land a moment to fully render in
            task.wait(2)

            local c = newChar or char()
            if c and c:FindFirstChild('HumanoidRootPart') then
                c:PivotTo(plotCF + Vector3.new(0, 6, 0))
                notify('✅ Dupe complete! Check your axes.')
            else
                notify('⚠️ Could not TP back — walk to your base manually.')
            end

            dupeRunning = false
        end)

        -- Return the saved plot CFrame to the server so it places land correctly
        return plotCF, 0
    end

    -- Step 4: Fire RequestLoad — THIS is what triggers the server to:
    --   a) auto-save current inventory (axes included) ← the dupe moment
    --   b) reset the character
    --   c) fire SelectLoadPlot (our hook handles it)
    --   d) reload the save (gives axes back again = doubled)
    --
    -- NOTE: We do NOT manually kill the character before this.
    -- The server handles the character reset itself. Killing first
    -- clears the backpack BEFORE the server saves it, which is why
    -- the old code produced no dupe.
    local ok, err = pcall(function()
        RequestLoad:InvokeServer(loadSlot, Player)
    end)

    if not ok then
        -- If RequestLoad errored (server rejected), clean up
        SelectLoadPlot.OnClientInvoke = origHook
        dupeRunning = false
        notify('❌ RequestLoad failed: ' .. tostring(err))
    end
end

--[[
═══════════════════════════════════════════════════════════════
  SUMMARY OF CHANGES vs. ORIGINAL BROKEN CODE:
═══════════════════════════════════════════════════════════════

  REMOVED:
    - c:PivotTo(CFrame.new(0, -1000, 0))  ← Don't void-TP before RequestLoad
    - c:BreakJoints()                      ← Don't manually kill the character
    - The task.wait(0.1) between TP and kill
    - The flat task.wait(1.5) TP timing (replaced with CharacterAdded wait)

  CHANGED:
    - RequestLoad is now the LAST thing called, not called after killing char
    - TP back to base now waits for CharacterAdded event (server-triggered
      respawn) instead of a hardcoded timer, so it works regardless of
      server load speed
    - Added check that axes exist before attempting dupe
    - origHook is restored at top of hook callback (faster, prevents leak
      if the spawn errors)
    - SetPropertyPurchValue wrapped in pcall so a server error doesn't
      break the hook return

  THE CORE FIX IN ONE LINE:
    Fire RequestLoad first. Let the SERVER kill the character.
    Don't kill the character yourself before the server saves the inventory.
]]
